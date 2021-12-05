local S = minetest.get_translator("city")

RegisterBuilding = function(name, def)
    def.collision_box = def.selection_box
    def.drawtype = "mesh"
    def.paramtype = "light"
    def.paramtype2 = "facedir"
    def.groups = {flammable = 1}
    def.node_placement_prediction = ""

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
    mesh = "city_road.obj",
    tiles = {
        "city_hex_C1C1CC.png", "city_light_grey.png",  "city_grey.png",  "city_hex_C1C1CC.png"
    },
    groups = {cost = 1},
    node_placement_prediction = "",
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
    groups = {cost = 10},
    tiles = {"city_grey.png", "city_grey.png", "city_light_grey.png",  "city_window.png", "city_white.png"},
})

minetest.register_node("city:wind_turbine", {
    description = S("Wind Turbine"),
	inventory_image = "city_white.png",
    drawtype = "mesh",
    mesh = "city_wind_turbine.obj",
    selection_box = {
        type = "fixed",
        fixed = {-1/3, -1/2, -1/3, 1/3, 3, 1/3},
    },
    collision_box = {
        type = "fixed",
        fixed = {-1/3, -1/2, -1/3, 1/3, 3, 1/3},
    },
    paramtype = "light",
    paramtype2 = "facedir",
    groups = {flammable = 1, energy_source = 7},
    tiles = {"city_white.png"},

    on_construct = function(pos, placer, itemstack, pointed_thing)
        local dir = minetest.facedir_to_dir(minetest.get_node(pos).param2)
        local blade_pos = vector.subtract(vector.new(), dir)
        blade_pos.y = blade_pos.y + 2
        minetest.set_node(vector.add(pos, blade_pos), {name="city:wind_turbine_blade", param2 = minetest.dir_to_wallmounted(dir)})
    end
})

minetest.register_node("city:wind_turbine_blade", {
    drawtype = "signlike",
    inventory_image = "city_white.png",
    paramtype = "light",
    paramtype2 = "wallmounted",
    selection_box = {
		type = "wallmounted",
    },
    visual_scale = 2,
    sunlight_propagates = true,
    groups = {flammable = 1, energy_source = 7},
    use_texture_alpha = false,
    tiles = {{
        name = "city_wind_turbine_blade_spinning.png",
        animation = {
            type = "vertical_frames",
            aspect_w = 64,
            aspect_h = 64,
            length = 4,
        },
    }},
})