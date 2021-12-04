local S = minetest.get_translator("city")

RegisterBuilding = function(name, def)
    def.collision_box = def.selection_box
    def.drawtype = "mesh"
    def.paramtype = "light"
    def.paramtype2 = "facedir"
    def.groups = {flammable = 1}

    local full = table.copy(def)

    --replace full windows with lit windows
    for i,v in ipairs(full.tiles) do
        if v == "city_window.png" then
            full.tiles[i] = "city_window_lit.png"
        end
    end

    def.on_timer = function(pos, elapsed)
        minetest.set_node(pos, {name = "city:skyscraper_full", param2 = minetest.get_node(pos).param2})
    end
    --setup a node timer that will turn the building into a full building
    --after a random amount of time.
    def.on_construct = function(pos, placer, itemstack, pointed_thing)
        minetest.get_node_timer(pos):start(math.random(1, 60))
    end

    minetest.register_node(name, def)
    minetest.register_node(name.."_full", full)
end

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
    light_source = 8,
    wield_image = "city_road.png",
    inventory_image = "city_road.png",
    tiles = {
        "city_road.png",
        "city_road_corner.png",
        "city_road_junction.png",
        "city_road_crossing.png",
    },
})

RegisterBuilding("city:skyscraper", {
    description = S("Skyscraper"),
	inventory_image = "city_building.png",
    drawtype = "mesh",
    mesh = "skyscraperA.obj",
    selection_box = {
        type = "fixed",
        fixed = {-1/2, -1/2, -1/2, 1/2, 1.8, 1/2},
    },
    tiles = {"city_grey.png", "city_grey.png", "city_light_grey.png",  "city_window.png", "city_white.png"},
})

minetest.register_node("city:wind_turbine", {
    description = S("Wind Turbine"),
	inventory_image = "city_white.png",
    drawtype = "mesh",
    mesh = "city_wind_turbine.obj",
    selection_box = {
        type = "fixed",
        fixed = {-1/2, -1/2, -1/2, 1/2, 2.2, 1/2},
    },
    collision_box = {
        type = "fixed",
        fixed = {-1/2, -1/2, -1/2, 1/2, 2.2, 1/2},
    },
    paramtype = "light",
    paramtype2 = "facedir",
    groups = {flammable = 1, energy_source = 7},
    tiles = {"city_white.png"},
})