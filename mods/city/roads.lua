--[[
    Roads are an important part of any city, acting as the glue that 
    hold a city together. With multiple cities, they serve as the 
    connections that facilitate their trade and travel.

    There are two kinds of roads:

       1. Streets, these define the boundary of a city and 
          enable the placement of buildings around them.
       2. Highways, these are the roads that connect a city
          to its neighbors and serve as the primary arterial
          routes for trade and travel. They may also have
          small rural road-networks attached to them. 

    Streets are powered (because of streetlights) and require 
    energy to construct additionally, every street is associated 
    to the city it is extending. This is achieved by storing the 
    city's ID in the params of the node directly below the street.

    Each highway has it's own number and is stored in mod storage.
    This mod storage stores information about which cities are
    connected to the highway. Like streets, the ID of the highway 
    is stored in the params of the node directly below the highway. 

    Roads must never be partioned (split), as this would cause
    the city simulation state to become inconsistent with the world.
    Therefore, roads may only be deconstructed node-by-node from their
    end nodes, determined by the fact that they have a single neighbour,
    to resolve loops, neighbours can be marked as excluded from 
    consideration when making this decision. Essentially, this
    means roads loops can only be deconstructed and/or unwound 
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

    All roads are interchangeable and are treated as if they were
    'raillike' however a custom raillike implementation is used 
    by Builda City in order to support meshes. FIXME should Minetest
    support raillike meshes?
]]

local S = minetest.get_translator("city")

local set_road = function(pos, node, lit)
    --check if lit
    if minetest.get_node(pos).name:find("_lit") then
        if lit then
            node.name = node.name .. "_lit"
        end
    elseif minetest.get_node(pos).name:find("_off") then
        node.name = node.name .. "_off"
    else
        if lit then
            node.name = node.name .. "_lit"
        end
    end
    minetest.set_node(pos, node)
end

local update_road_lighting = function(top, bot, left, right)
    top.lit = string.match(top.name, "_lit")
    bot.lit = string.match(bot.name, "_lit")
    left.lit = string.match(left.name, "_lit")
    right.lit = string.match(right.name, "_lit")

    return not (top.lit or bot.lit or left.lit or right.lit)
end

local is_road = function(name)
    return minetest.get_item_group(name, "road") > 0
end

--update_road checks the neighbours of the road and updates the road if needed.
--emulates the behaviour of rail-like but with meshes.
local update_road = function(pos, setter, update_neighbours)
    local center = minetest.get_node(pos)
    
    local top = minetest.get_node({x=pos.x, y=pos.y, z=pos.z+1})
    local bot = minetest.get_node({x=pos.x, y=pos.y, z=pos.z-1})
    local left = minetest.get_node({x=pos.x-1, y=pos.y, z=pos.z})
    local right = minetest.get_node({x=pos.x+1, y=pos.y, z=pos.z})

    center.road = is_road(center.name)
    if not center.road then
        return
    end

    top.road = is_road(top.name)
    bot.road = is_road(bot.name)
    left.road = is_road(left.name)
    right.road = is_road(right.name)

    -- we will encode the deletion condition into param2
    -- this is based on the known neighbours when the
    -- road was placed and is hopefully robust.
    local neighbours = math.floor(center.param2 / 32)*32
    if update_neighbours then
        if (top.road ~= bot.road) and (left.road ~= right.road) then
            neighbours = 0
        elseif (left.road ~= right.road) and not (top.road or bot.road) then
            neighbours = 1
        elseif not (left.road or right.road) and (top.road ~= bot.road) then
            neighbours = 2
        elseif (top.road and bot.road) and (left.road and right.road) then
            neighbours = 3
        elseif (top.road ~= bot.road) and (left.road and right.road) then
            neighbours = 4
        elseif not (top.road or bot.road) and (left.road and right.road) then
            neighbours = 5
        elseif (top.road and bot.road) and not (left.road or right.road) then
            neighbours = 6
        elseif (top.road and bot.road) and (left.road ~= right.road) then
            neighbours = 7
        else
            assert(false, "impossible road configuration") --can only happen if there are no neighbours (I think).
        end
        neighbours = neighbours*32 --shift into the colorfacedir color bits
    end

    local lit = update_road_lighting(top, bot, left, right)

    local count = 0
    if top.road then count = count + 1 end
    if bot.road then count = count + 1 end
    if left.road then count = count + 1 end
    if right.road then count = count + 1 end

    if count == 4 then
        setter(pos, {name="city:street_crossing", param2=neighbours}, lit)
    elseif count == 3 then
        if not top.road then
            setter(pos, {name="city:street_junction", param2=2+neighbours}, lit)
        elseif not left.road then
            setter(pos, {name="city:street_junction", param2=1+neighbours}, lit)
        elseif not bot.road then
            setter(pos, {name="city:street_junction", param2=0+neighbours}, lit)
        elseif not right.road then
            setter(pos, {name="city:street_junction", param2=3+neighbours}, lit)
        end
    elseif count == 2 then
        -- straight roads.
        if top.road and bot.road then
            setter(pos, {name="city:street", param2=3+neighbours}, lit)
        elseif left.road and right.road then
            setter(pos, {name="city:street", param2=2+neighbours}, lit)
        end

        --curved roads.
        if top.road and left.road then
            setter(pos, {name="city:street_corner", param2=3+neighbours}, lit)
        elseif top.road and right.road then
            setter(pos, {name="city:street_corner", param2=0+neighbours}, lit)
        elseif bot.road and left.road then
            setter(pos, {name="city:street_corner", param2=2+neighbours}, lit)
        elseif bot.road and right.road then
            setter(pos, {name="city:street_corner", param2=1+neighbours}, lit)
        end
    elseif count == 1 then
        if top.road or bot.road then
            setter(pos, {name="city:street", param2=3+neighbours}, lit)
        elseif left.road or right.road then
            setter(pos, {name="city:street", param2=2+neighbours}, lit)
        end
    end
end

-- city.remove_road returns true if the road at pos
-- can be removed without causing a partition and
-- removes it, otherwise returns false (and the 
-- road is not removed).
function city.remove_road(pos) 
    local node = minetest.get_node(pos)
    local neighbours = math.floor(node.param2 / 32)

    local top = minetest.get_node({x=pos.x, y=pos.y, z=pos.z+1})
    local bot = minetest.get_node({x=pos.x, y=pos.y, z=pos.z-1})
    local left = minetest.get_node({x=pos.x-1, y=pos.y, z=pos.z})
    local right = minetest.get_node({x=pos.x+1, y=pos.y, z=pos.z})
    top.road = is_road(top.name)
    bot.road = is_road(bot.name)
    left.road = is_road(left.name)
    right.road = is_road(right.name)

    local can_remove = false

    if neighbours == 0 then
        if (top.road ~= bot.road) and (left.road ~= right.road) then
            can_remove = true
        end
    elseif neighbours == 1 then
        if (left.road ~= right.road) and not top.road and not bot.road then
            can_remove = true
        end
    elseif neighbours == 2 then
        if not left.road and not right.road and (top.road ~= bot.road) then
            can_remove = true
        end
    elseif neighbours == 3 then
        if (top.road and bot.road) and (left.road and right.road) then
            can_remove = true
        end
    elseif neighbours == 4 then
        if (top.road ~= bot.road) and (left.road and right.road) then
            can_remove = true
        end
    elseif neighbours == 5 then
        if not (top.road or bot.road) and (left.road and right.road) then
            can_remove = true
        end
    elseif neighbours == 6 then
        if (top.road and bot.road) and not (left.road or right.road) then
            can_remove = true
        end
    elseif neighbours == 7 then
        if (top.road and bot.road) and (left.road ~= right.road) then
            can_remove = true
        end
    end

    if can_remove then
        minetest.remove_node(pos)
        city.update_roads(pos)
        return true
    end
    return false
end

--update roads depending on the sourounding roads.
--set update_neighbours to true when you are placing 
--a new road.
function city.update_roads(pos, update_neighbours)
    update_road(pos, set_road, update_neighbours)
    update_road({x=pos.x, y=pos.y, z=pos.z+1}, set_road)
    update_road({x=pos.x, y=pos.y, z=pos.z-1}, set_road)
    update_road({x=pos.x-1, y=pos.y, z=pos.z}, set_road)
    update_road({x=pos.x+1, y=pos.y, z=pos.z}, set_road)
end

--city.get_road_near returns the most relevant road near position pos.
--if facing position is provided and there are multiple relevant roads, 
--it will return the one that is closer to the facing_pos.
function city.get_street_near(pos, facing_pos)
    local top = {x=pos.x, y=pos.y, z=pos.z+1}
    local bot = {x=pos.x, y=pos.y, z=pos.z-1}
    local left = {x=pos.x-1, y=pos.y, z=pos.z}
    local right = {x=pos.x+1, y=pos.y, z=pos.z}

    local relevant_roads = {}

    if string.match(minetest.get_node(top).name, "city:street.*") then
        table.insert(relevant_roads, top)
    end
    if string.match(minetest.get_node(bot).name, "city:street.*") then
        table.insert(relevant_roads, bot)
    end
    if string.match(minetest.get_node(left).name, "city:street.*") then
        table.insert(relevant_roads, left)
    end
    if string.match(minetest.get_node(right).name, "city:street.*") then
        table.insert(relevant_roads, right)
    end

    local result
   
    if facing_pos then
        local min_dist = math.huge
        local min_road = nil
        for _, road in pairs(relevant_roads) do
            local dist = vector.distance(road, facing_pos)
            if dist < min_dist then
                min_dist = dist
                min_road = road
            end
        end
        result = min_road
    else
         --pick one at random 
        result = relevant_roads[math.random(#relevant_roads)]
    end

    if result then
        result.city = city.at(result)  --connect to existing city.
        if result.city == 0 then
            result.city = city.new(result) --create a new city.
            result.new_city = true
            city.set(result, result.city)
        end
    end
   
    return result
end

local register_street = function(name, mesh)
    local def = {
        description = S("Street"),
        paramtype = "light",
        sunlight_propagates = false,
        is_ground_content = false,
        walkable = false,
        selection_box = {
            type = "fixed",
            fixed = {-1/2, -1/2, -1/2, 1/2, -1/2+1/16, 1/2},
        },
        collision_box = {
            type = "fixed",
            fixed = {-1/2, -1/2, -1/2, 1/2, -1/2+1/16, 1/2},
        },
        paramtype2 = "colorfacedir",
        drawtype = "mesh",
        mesh = mesh..".obj",
        tiles = city.load_material("city", mesh..".mtl"),
        groups = {
            flammable = 1, 
            road = 1, --1 is street
        },
        node_placement_prediction = "",

        after_place_node = function(pos)
            city.update_roads(pos)
        end,
    }
    
    local def_lit = table.copy(def)
    def_lit.on_construct = function (pos, placer, itemstack, pointed_thing)
        minetest.set_node({x=pos.x, y=pos.y+1, z=pos.z}, {name="city:road_light"})
    end
    def_lit.mesh = mesh.."_lit.obj"
    def_lit.tiles = city.load_material("city", mesh.."_lit.mtl")
    def_lit.groups["consumer"] = 1

    local def_gap = table.copy(def)
    def_gap.on_construct = function (pos, placer, itemstack, pointed_thing)
        minetest.set_node({x=pos.x, y=pos.y+1, z=pos.z}, {name="city:road_light"})
    end
    def_gap.mesh = mesh..".obj"
    def_gap.tiles = city.load_material("city", mesh..".mtl")
    def_gap.groups["consumer"] = 1

    --make unlit road a bit more obvious.
    for i,v in ipairs(def.tiles) do
        if v.color.road_line  then
            def.tiles[i].color = def.tiles.asphalt
        end
    end

    minetest.register_node(name.."_off", def)
    minetest.register_node(name.."_lit", def_lit)
    minetest.register_node(name, def_gap)
end

minetest.register_node("city:streetlight", {
    drawtype = "airlike",
    paramtype = "light",
    sunlight_propagates = true,
    light_source = 10,
    pointable = false,
    walkable = false,
})

--backwards compatibility with 0.3.0
minetest.register_alias("city:road", "city:street")
minetest.register_alias("city:road_light", "city:streetlight")
minetest.register_alias("city:road_corner", "city:street_corner")
minetest.register_alias("city:road_junction", "city:street_junction")
minetest.register_alias("city:road_crossing", "city:street_crossing")
minetest.register_alias("city:road_lit", "city:street_lit")
minetest.register_alias("city:road_corner_lit", "city:street_corner_lit")
minetest.register_alias("city:road_junction_lit", "city:street_junction_lit")
minetest.register_alias("city:road_crossing_lit", "city:street_crossing_lit")
minetest.register_alias("city:road_off", "city:street_off")
minetest.register_alias("city:road_corner_off", "city:street_corner_off")
minetest.register_alias("city:road_junction_off", "city:street_junction_off")
minetest.register_alias("city:road_crossing_off", "city:street_crossing_off")

register_street("city:street", "city_road")
register_street("city:street_corner", "city_road_corner")
register_street("city:street_junction", "city_road_junction")
register_street("city:street_crossing", "city_road_crossing")

