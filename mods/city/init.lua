local S = minetest.get_translator("city")

minetest.register_node("city:road", {
    drawtype = "raillike",
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
    tiles = {
        "city_road.png",
        "city_road_corner.png",
        "city_road_junction.png",
        "city_road_crossing.png",
    },
})

--City building, eventually changes into an occupied/full building.
minetest.register_node("city:building", {
    description = S("Building"),
	texture = "city_building.png",
	inventory_image = "city_building.png",
	wield_image = "city_building.png",
	groups = {flammable = 1},
    tiles = {"city_building_top.png", "city_building_top.png", "city_building.png", "city_building.png", "city_building.png", "city_building.png"},
    on_timer = function(pos, elapsed)
        minetest.set_node(pos, {name = "city:building_full"})
    end,

    --setup a node timer that will turn the building into a full building
    --after a random amount of time.
    on_construct = function(pos, placer, itemstack, pointed_thing)
        print("on_construct ")
        minetest.get_node_timer(pos):start(math.random(1, 60))
    end
})
minetest.register_node("city:building_full", {
    description = S("Building"),
    texture = "city_building_full.png",
    inventory_image = "city_building_full.png",
    wield_image = "city_building_full.png",
    groups = {flammable = 1},
    light_source = 12,
    tiles = {"city_building_top.png", "city_building_top.png", "city_building_full.png", "city_building_full.png", "city_building_full.png", "city_building_full.png"},
})