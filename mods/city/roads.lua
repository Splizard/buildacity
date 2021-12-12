local S = minetest.get_translator("city")

--update_road checks the neighbours of the road and updates the road if needed.
local update_road = function(pos)
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

    local count = 0
    if top.road then count = count + 1 end
    if bot.road then count = count + 1 end
    if left.road then count = count + 1 end
    if right.road then count = count + 1 end

    if count == 4 then
        minetest.set_node(pos, {name="city:road_crossing"})
    elseif count == 3 then
        if not top.road then
            minetest.set_node(pos, {name="city:road_junction", param2=2})
        elseif not left.road then
            minetest.set_node(pos, {name="city:road_junction", param2=1})
        elseif not bot.road then
            minetest.set_node(pos, {name="city:road_junction", param2=0})
        elseif not right.road then
            minetest.set_node(pos, {name="city:road_junction", param2=3})
        end
    elseif count == 2 then
        -- straight roads.
        if top.road and bot.road then
            minetest.set_node(pos, {name="city:road", param2=3})
        elseif left.road and right.road then
            minetest.set_node(pos, {name="city:road", param2=2})
        end

        --curved roads.
        if top.road and left.road then
            minetest.set_node(pos, {name="city:road_corner", param2=3})
        elseif top.road and right.road then
            minetest.set_node(pos, {name="city:road_corner", param2=0})
        elseif bot.road and left.road then
            minetest.set_node(pos, {name="city:road_corner", param2=2})
        elseif bot.road and right.road then
            minetest.set_node(pos, {name="city:road_corner", param2=1})
        end
    elseif count == 1 then
        if top.road or bot.road then
            minetest.set_node(pos, {name="city:road", param2=3})
        elseif left.road or right.road then
            minetest.set_node(pos, {name="city:road", param2=2})
        end
    end
end

--update roads depending on the sorrounding roads.
function city.update_roads(pos)
    update_road(pos)
    update_road({x=pos.x, y=pos.y, z=pos.z+1})
    update_road({x=pos.x, y=pos.y, z=pos.z-1})
    update_road({x=pos.x-1, y=pos.y, z=pos.z})
    update_road({x=pos.x+1, y=pos.y, z=pos.z})
end

local register_road = function(name, mesh, tiles)
    minetest.register_node(name, {
        description = S("Road"),
        paramtype = "light",
        sunlight_propagates = false,
        is_ground_content = false,
        walkable = false,
        selection_box = {
            type = "fixed",
            fixed = {-1/2, -1/2, -1/2, 1/2, -1/2+1/16, 1/2},
        },
        wield_image = "city_road.png",
        inventory_image = "city_road.png",
        paramtype2 = "facedir",
        drawtype = "mesh",
        mesh = mesh,
        tiles = tiles,
        groups = {cost = 1},
        node_placement_prediction = "",

        after_place_node = function(pos)
            city.update_roads(pos)
            minetest.set_node({x=pos.x, y=pos.y+1, z=pos.z}, {name="city:light"})
        end,
    })
end

register_road("city:road", "city_road.obj", {
    "city_hex_C1C1CC.png", "city_light_grey.png", "city_grey.png", "city_hex_C1C1CC.png"
})
register_road("city:road_corner", "city_road_corner.obj", {
    "city_hex_C1C1CC.png", "city_light_grey.png", "city_grey.png", "city_hex_C1C1CC.png"
})
register_road("city:road_junction", "city_road_junction.obj", {
    "city_light_grey.png", "city_hex_C1C1CC.png", "city_grey.png", "city_hex_C1C1CC.png"
})
register_road("city:road_crossing", "city_road_crossing.obj", {
    "city_hex_C1C1CC.png", "city_light_grey.png", "city_grey.png", "city_hex_C1C1CC.png"
})

