--[[
    "Rails" must never be partioned (split), as this would cause
    the logistic state to become inconsistent with the world.
    Therefore, "rails" may only be deconstructed node-by-node from their
    end nodes, determined by the fact that they have a single neighbour,
    to resolve loops, neighbours can be marked as excluded from 
    consideration when making this decision. Essentially, this
    means "rail" loops can only be deconstructed and/or unwound 
    in the order they were placed. Existing neighbours at the time
    of construction are stored in the color bits of the nodes's param.

    Neighbour Bits (describes the condition required for deletion)
          +zx
        0|0b000: xz  (1 on x axis, 1 on z axis)
        1|0b001: x   (1 on x axis, 0 on z axis)
        2|0b010: z   (0 on x axis, 1 on z axis)
        3|0b011: xz+ (2 on x axis, 2 on z axis)
        4|0b100: xxz (2 on x axis, 1 on z axis)
        5|0b101: x+  (2 on x axis, 0 on z axis)
        6|0b110: z+  (0 on x axis, 2 on z axis)
        7|0b111: xzz (1 on x axis, 2 on z axis)
]]

-- logistics.registered_rails is a list of registered rails.
logistics.registered_rails = {}


-- logistics.register_rails registers a set of rail-likes for the given
-- node names. future calls to update will recognize these nodes. nodes
-- must have paramtype2 set to "colorfacedir" and must not use the palette.
-- must have connects_to set to a "group:name" string.
logistics.register_rail = function(straight, corner, junction, crossing)
    local rails = {
        straight = straight,
        corner = corner,
        junction = junction,
        crossing = crossing,
    }
    for _, name in pairs(rails) do
        local def = minetest.registered_nodes[name]
        if def.paramtype2 ~= "colorfacedir" then
            error("rail-like node "..name.." must have paramtype2 set to 'colorfacedir'")
        end
        if def.palette then
            error("rail-like node "..name.." must not use the palette")
        end
        if not def.connects_to or string.match(def.connects_to, "group:") == nil then
            error("rail-like node "..name.." must have connects_to set to a group name")
        end
    end
    logistics.registered_rails[straight] = rails
    logistics.registered_rails[corner] = rails
    logistics.registered_rails[junction] = rails
    logistics.registered_rails[crossing] = rails
end

-- returns true if removing the road at pos
-- would cause a partition of a logistics node.
local old_is_protected = minetest.is_protected
function minetest.is_protected(pos, name)
    local node = minetest.get_node_or_nil(pos)
    if node then
        if logistics.registered_rails[node.name] then
            local group = string.match(minetest.registered_nodes[node.name].connects_to, "group:(.*)")
            local neighbours = math.floor(node.param2 / 32)

            local dir = function(v)
                local node = minetest.get_node(vector.add(pos, v))
                return minetest.get_item_group(node.name, group) > 0
            end
        
            local top = dir({x=0, y=0, z=1})
            local bot = dir({x=0, y=0, z=-1})
            local left = dir({x=-1, y=0, z=0})
            local right = dir({x=1, y=0, z=0})

            local partition = true

            if neighbours == 0 then
                if (top ~= bot) and (left ~= right) then
                    partition = false
                end
            elseif neighbours == 1 then
                if (left ~= right) and not top and not bot then
                    partition = false
                end
            elseif neighbours == 2 then
                if not left and not right and (top ~= bot) then
                    partition = false
                end
            elseif neighbours == 3 then
                if (top and bot) and (left and right) then
                    partition = false
                end
            elseif neighbours == 4 then
                if (top ~= bot) and (left and right) then
                    partition = false
                end
            elseif neighbours == 5 then
                if not (top or bot) and (left and right) then
                    partition = false
                end
            elseif neighbours == 6 then
                if (top and bot) and not (left or right) then
                    partition = false
                end
            elseif neighbours == 7 then
                if (top and bot) and (left ~= right) then
                    partition = false
                end
            end

            if partition then
                return true
            end
        end
    end
    return old_is_protected(pos, name)
end

local update = function(pos, init)
    local center = minetest.get_node(pos)
    local rails = logistics.registered_rails[center.name]
    if not rails then
        return
    end
    local group = string.match(minetest.registered_nodes[center.name].connects_to, "group:(.*)")

    local dir = function(v)
        local node = minetest.get_node(vector.add(pos, v))
        return minetest.get_item_group(node.name, group) > 0
    end

    local set_node = function(pos, node)
        if init or minetest.get_node(pos).name ~= node.name then
            minetest.set_node(pos, node)
        end
    end

    local top = dir({x=0, y=0, z=1})
    local bot = dir({x=0, y=0, z=-1})
    local left = dir({x=-1, y=0, z=0})
    local right = dir({x=1, y=0, z=0})

    -- we will encode the deletion condition into param2
    -- this is based on the known neighbours when the
    -- road was placed and is hopefully robust.
    local neighbours = math.floor(center.param2 / 32)*32
    if init then
        if (top ~= bot) and (left ~= right) then
            neighbours = 0
        elseif (left ~= right) and not (top or bot) then
            neighbours = 1
        elseif not (left or right) and (top ~= bot) then
            neighbours = 2
        elseif (top and bot) and (left and right) then
            neighbours = 3
        elseif (top ~= bot) and (left and right) then
            neighbours = 4
        elseif not (top or bot) and (left and right) then
            neighbours = 5
        elseif (top and bot) and not (left or right) then
            neighbours = 6
        elseif (top and bot) and (left ~= right) then
            neighbours = 7
        else
            assert(false, "impossible condition") --can only happen if there are no neighbours (I think).
        end
        neighbours = neighbours*32 --shift into the colorfacedir color bits
    end

    local count = 0
    if top then count = count + 1 end
    if bot then count = count + 1 end
    if left then count = count + 1 end
    if right then count = count + 1 end

    if count == 4 then
        set_node(pos, {name=rails.crossing, param2=neighbours})
    elseif count == 3 then
        if not top then
            set_node(pos, {name=rails.junction, param2=2+neighbours})
        elseif not left then
            set_node(pos, {name=rails.junction, param2=1+neighbours})
        elseif not bot then
            set_node(pos, {name=rails.junction, param2=0+neighbours})
        elseif not right then
            set_node(pos, {name=rails.junction, param2=3+neighbours})
        end
    elseif count == 2 then
        if top and bot then
            set_node(pos, {name=rails.straight, param2=3+neighbours})
        elseif left and right then
            set_node(pos, {name=rails.straight, param2=2+neighbours})
        end

        if top and left then
            set_node(pos, {name=rails.corner, param2=3+neighbours})
        elseif top and right then
            set_node(pos, {name=rails.corner, param2=0+neighbours})
        elseif bot and left then
            set_node(pos, {name=rails.corner, param2=2+neighbours})
        elseif bot and right then
            set_node(pos, {name=rails.corner, param2=1+neighbours})
        end
    elseif count == 1 then
        if top or bot then
            set_node(pos, {name=rails.straight, param2=3+neighbours})
        elseif left or right then
            set_node(pos, {name=rails.straight, param2=2+neighbours})
        end
    end
end

-- logistics.update updates any rail-like nodes at 'pos' that have 
-- been registered with this mod. if 'init' is true, then the rail
-- like node is treated as if it were just created and is 
-- appropriately initialized.
logistics.update = function (pos, init)
    update(pos, init)
    update({x=pos.x, y=pos.y, z=pos.z+1})
    update({x=pos.x, y=pos.y, z=pos.z-1})
    update({x=pos.x-1, y=pos.y, z=pos.z})
    update({x=pos.x+1, y=pos.y, z=pos.z})
end