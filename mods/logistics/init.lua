--[[
    Logistics mod is a helper for creating and managing 
    solid-state logistic networks.   
    
    There are two concepts here, logistics nodes and logistics networks.
    A logistics node is a series of connected nodes with a shared ID.
    They must not be partioned, however they may connect to neighboring nodes
    and one or more connected nodes are considered to be a logistics network.

    A logistics network has a shared resource-pool between all of its 
    nodes. However logistics networks may be partioned when nodes are
    disconnected from one another.

    This mod offers a starting point for creating rail-like connectivity 
    nodes that can be used as the basis for creating logistics networks.

    A node needs the following properties in order to be considered a 
    logistics node:

        logistics {
            network = "name" 
            -- name of the logistics node/network.
        }

        resources = function(node, pos) 
            return {
                coal = 1,
            }
        end,
        -- returns the node's available resources. must always
        -- return the same result for the same node and pos.
]]
local db = minetest.get_mod_storage()

logistics = {}

-- logistics.registered_resources is a list of registered resources.
logistics.registered_resources = {}

-- logistics.registered_networks is a list of registered networks.
logistics.registered_networks = {}

-- logistics.register_network registers a network with the given
-- on_create and on_update handlers that take the form (pos, player)
logistics.register_network = function(name, def)
    logistics.registered_networks[name] = def
end

-- logistics.register_resource registers the given 'resource' name
-- as a known resource.
logistics.register_resource = function(resource)
    table.insert(logistics.registered_resources, resource)
end

-- logistics.at returns a table of all of the resources available to
-- 'player' at 'pos'. Returns nil, if pos is not a logistics node.
logistics.at = function(pos, player, nearby)
    local node = minetest.get_node(pos)
    local def = minetest.registered_nodes[node.name]
    if not def.logistics then
        return nil
    end

    local index = logistics.index(pos)
    local resources = {}

    local keys = db:get_string(def.logistics.network.."/"..index.."_keys")
    if not keys then
        return nil
    end

    for key in keys:gmatch("([^,]+)") do
        resources[key] = db:get_int(def.logistics.network.."/"..index.."/"..key)
    end

    return resources
end

-- logistics.get returns the number of 'resource' available to 'player' 
-- at 'pos'. if 'nearby' is true, then the number of resources available
-- is local to the logistics network at 'pos' and does not include 
-- any shared/networked resources.
logistics.get = function(pos, player, resource, nearby) 

end

-- logistics.node_near returns the position of the
-- nearest logistics node to 'pos' of the given 'group'
-- taking into account the position of the player to
-- break ties.
logistics.node_near = function(pos, player, group)
    local top = {x=pos.x, y=pos.y, z=pos.z+1}
    local bot = {x=pos.x, y=pos.y, z=pos.z-1}
    local left = {x=pos.x-1, y=pos.y, z=pos.z}
    local right = {x=pos.x+1, y=pos.y, z=pos.z}

    local dir = function(pos) 
        return minetest.get_item_group(minetest.get_node(pos).name, group) > 0
    end
    local candidates = {}

    if dir(top) then table.insert(candidates, top) end
    if dir(bot) then table.insert(candidates, bot) end
    if dir(left) then table.insert(candidates, left) end
    if dir(right) then table.insert(candidates, right) end

    local result

    if player then
        local player_pos = player:get_pos()
        local min_dist = math.huge
        local min_road = nil
        for _, road in pairs(candidates) do
            local dist = vector.distance(road, player_pos)
            if dist < min_dist then
                min_dist = dist
                min_road = road
            end
        end
        result = min_road
    else
        result = candidates[math.random(#candidates)]
    end
   
    return result
end

-- logistics.index returns the ID of the logistics node at 'pos'.
-- this is a low-level function and should only be used for 
-- debugging purposes.
logistics.index = function(pos) 
    local node = minetest.get_node({x=pos.x, y=pos.y-1, z=pos.z})
    local def = minetest.registered_nodes[node.name]
    if def.paramtype ~= "none" or def.paramtype2 ~= "none" then
        error("node below logistics node must not use paramtype2")
    end
    return node.param1*255 + node.param2
end

local logistics_set_index = function(pos, index)
    local under = {x=pos.x, y=pos.y-1, z=pos.z}
    minetest.set_node(under, {
        name=minetest.get_node(under).name,  
        param1=math.floor(index/255), 
        param2=index%255,
    })
end

-- logistics.place places the (logistics) 'name' node at 'pos', if 
-- resources are available there, they are added to the resulting 
-- logistics network. panics if the node at 'pos' is already a 
-- logistics node. the node below 'pos' must not use paramtype or
-- paramtype2. 'player' is the player who is adding the logistics node.
-- returns false if the node cannot be placed. placement requires
-- an adjacent logistics node to be present.
logistics.place = function(name, pos, player)
    local def = minetest.registered_nodes[name]
    if not def.logistics then
        error("node must be registered as a logistics node with a logistics.network string")
    end
    if not def.connects_to then
        error("node must be registered with a connects_to string")
    end

    local group = string.match(def.connects_to, "group:(.*)")
    local network = def.logistics.network

    local adjacent = logistics.node_near(pos, player, group)
    if not adjacent then
        return false
    end

    -- either fetch the index, or create a new one.
    local index = logistics.index(adjacent)
    if index == 0 then
        local count = db:get_int(network.."_count")
        count = count + 1
        index = count
        db:set_int(network.."_count", count)
        logistics_set_index(adjacent, index)

        local def = logistics.registered_networks[network]
        if def.on_create then
            def.on_create(adjacent, player)
        end
    end

    -- accumulate/add resources.
    if def.resources then
        local resources = def.resources()
        for resource, amount in pairs(resources) do
            local total = db:get_int(network.."/"..index.."/"..resource)
            if total == 0 then
                local keys = db:get_string(network.."/"..index.."_keys")
                keys = keys..","..resource
                db:set_string(network.."/"..index.."_keys", keys)
            end
            total = total + amount
            db:set_int(network.."/"..index.."/"..resource, total)
        end
    end

    local dir = vector.subtract(pos, adjacent)
    local param2 = minetest.dir_to_facedir(dir)

    minetest.set_node(pos, {name=name, param2=param2})
    logistics_set_index(pos, index)

    if logistics.registered_rails[name] then
        logistics.update(pos, true)
    end

    return true
end

-- logistics.remove removes the (logistics) node at 'pos'. If
-- resources are available from 'pos', they are removed from the 
-- resulting logistics network(s). The resources passed
-- to this function should match the resources passed to
-- when this 'pos' was passed to logistics.add. panics
-- if the node at 'pos' hasn't been added.
-- player is the player who is removing the logistics node.
logistics.remove = function(pos, player) 
    local node = minetest.get_node(pos)
    local def = minetest.registered_nodes[node.name]
    if def then
        
        local group = string.match(def.connects_to, "group:(.*)")
        local network = def.logistics.network

        local adjacent = logistics.node_near(pos, player, group)
        if not adjacent then
            return false
        end

        -- either fetch the index, or create a new one.
        local index = logistics.index(adjacent)
        if index == 0 then
            local count = db:get_int(network.."_count")
            count = count + 1
            index = count
            db:set_int(network.."_count", count)
            logistics_set_index(adjacent, index)

            local def = logistics.registered_networks[network]
            if def.on_create then
                def.on_create(adjacent, player)
            end
        end

        -- accumulate/add resources.
        if def.resources then
            local resources = def.resources()
            for resource, amount in pairs(resources) do
                local total = db:get_int(network.."/"..index.."/"..resource)
                if total == 0 then
                    local keys = db:get_string(network.."/"..index.."_keys")
                    keys = keys..","..resource
                    db:set_string(network.."/"..index.."_keys", keys)
                end
                total = total - amount
                db:set_int(network.."/"..index.."/"..resource, total)
            end
        end
    end

    minetest.remove_node(pos)
    logistics.update(pos)

    
    return true
end

dofile(minetest.get_modpath("logistics").."/rails.lua")