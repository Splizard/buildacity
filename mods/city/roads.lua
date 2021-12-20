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

--update_road checks the neighbours of the road and updates the road if needed.
local update_road = function(pos, setter)
    local center = minetest.get_node(pos)
    
    local top = minetest.get_node({x=pos.x, y=pos.y, z=pos.z+1})
    local bot = minetest.get_node({x=pos.x, y=pos.y, z=pos.z-1})
    local left = minetest.get_node({x=pos.x-1, y=pos.y, z=pos.z})
    local right = minetest.get_node({x=pos.x+1, y=pos.y, z=pos.z})

    center.road = string.match(center.name, "city:road.*")
    if not center.road then
        return
    end

    top.road = string.match(top.name, "city:road.*")
    bot.road = string.match(bot.name, "city:road.*")
    left.road = string.match(left.name, "city:road.*")
    right.road = string.match(right.name, "city:road.*")

    local lit = update_road_lighting(top, bot, left, right)

    local count = 0
    if top.road then count = count + 1 end
    if bot.road then count = count + 1 end
    if left.road then count = count + 1 end
    if right.road then count = count + 1 end

    if count == 4 then
        setter(pos, {name="city:road_crossing"}, lit)
    elseif count == 3 then
        if not top.road then
            setter(pos, {name="city:road_junction", param2=2}, lit)
        elseif not left.road then
            setter(pos, {name="city:road_junction", param2=1}, lit)
        elseif not bot.road then
            setter(pos, {name="city:road_junction", param2=0}, lit)
        elseif not right.road then
            setter(pos, {name="city:road_junction", param2=3}, lit)
        end
    elseif count == 2 then
        -- straight roads.
        if top.road and bot.road then
            setter(pos, {name="city:road", param2=3}, lit)
        elseif left.road and right.road then
            setter(pos, {name="city:road", param2=2}, lit)
        end

        --curved roads.
        if top.road and left.road then
            setter(pos, {name="city:road_corner", param2=3}, lit)
        elseif top.road and right.road then
            setter(pos, {name="city:road_corner", param2=0}, lit)
        elseif bot.road and left.road then
            setter(pos, {name="city:road_corner", param2=2}, lit)
        elseif bot.road and right.road then
            setter(pos, {name="city:road_corner", param2=1}, lit)
        end
    elseif count == 1 then
        if top.road or bot.road then
            setter(pos, {name="city:road", param2=3}, lit)
        elseif left.road or right.road then
            setter(pos, {name="city:road", param2=2}, lit)
        end
    end
end

--update roads depending on the sorrounding roads.
function city.update_roads(pos)
    update_road(pos, set_road)
    update_road({x=pos.x, y=pos.y, z=pos.z+1}, set_road)
    update_road({x=pos.x, y=pos.y, z=pos.z-1}, set_road)
    update_road({x=pos.x-1, y=pos.y, z=pos.z}, set_road)
    update_road({x=pos.x+1, y=pos.y, z=pos.z}, set_road)
end

--city.get_road_near returns the most relevant road near position pos.
--if facing position is provided and there are multiple relevant roads, 
--it will return the one that is closer to the facing_pos.
function city.get_road_near(pos, facing_pos)
    local top = {x=pos.x, y=pos.y, z=pos.z+1}
    local bot = {x=pos.x, y=pos.y, z=pos.z-1}
    local left = {x=pos.x-1, y=pos.y, z=pos.z}
    local right = {x=pos.x+1, y=pos.y, z=pos.z}

    local relevant_roads = {}

    if string.match(minetest.get_node(top).name, "city:road.*") then
        table.insert(relevant_roads, top)
    end
    if string.match(minetest.get_node(bot).name, "city:road.*") then
        table.insert(relevant_roads, bot)
    end
    if string.match(minetest.get_node(left).name, "city:road.*") then
        table.insert(relevant_roads, left)
    end
    if string.match(minetest.get_node(right).name, "city:road.*") then
        table.insert(relevant_roads, right)
    end
   
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
        return min_road
    end

    --pick one at random 
    return relevant_roads[math.random(#relevant_roads)]
end

local register_road = function(name, mesh, tiles)
    local def = {
        description = S("Road"),
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
        wield_image = "city_road.png",
        inventory_image = "city_road.png",
        paramtype2 = "colorfacedir",
        drawtype = "mesh",
        mesh = mesh..".obj",
        tiles = city.load_material("city", mesh..".mtl"),
        groups = {flammable = 1},
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

minetest.register_node("city:road_light", {
    drawtype = "airlike",
    paramtype = "light",
    sunlight_propagates = true,
    light_source = 10,
    pointable = false,
    walkable = false,
})

register_road("city:road", "city_road")
register_road("city:road_corner", "city_road_corner")
register_road("city:road_junction", "city_road_junction")
register_road("city:road_crossing", "city_road_crossing")

