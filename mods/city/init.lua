local S = minetest.get_translator("city")

city = {}

local RegisterBuilding = function(name, def)
    def.collision_box = def.selection_box
    def.drawtype = "mesh"
    def.paramtype = "light"
    def.paramtype2 = "facedir"
    def.groups = {flammable = 1, cost = 1}
    def.node_placement_prediction = ""

    local full = table.copy(def)

    --replace full windows with lit windows
    for i,v in ipairs(full.tiles) do
        if v == "city_window.png" then
            def.tiles[i] = "city_window_lit.png"
        end
    end

    def.on_timer = function(pos, elapsed)
        minetest.set_node(pos, {name = "city:skyscraper_decayed", param2 = minetest.get_node(pos).param2})
    end
    --setup a node timer that will decay the building
    --after a random amount of time.
    def.on_construct = function(pos, placer, itemstack, pointed_thing)
        minetest.get_node_timer(pos):start(math.random(1, 60))
    end

    minetest.register_node(name, def)
    minetest.register_node(name.."_decayed", full)
end


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

minetest.register_node("city:light", {
    drawtype = "airlike",
    paramtype = "light",
    sunlight_propagates = true,
    light_source = 14,
    pointable = false,
})


local modpath = minetest.get_modpath("city")

dofile(modpath.."/roads.lua")
dofile(modpath.."/energy.lua")
dofile(modpath.."/buildings.lua")