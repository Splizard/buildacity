local S = minetest.get_translator("polymap")

minetest.register_alias("mapgen_stone", "polymap:ground")
minetest.register_alias("mapgen_water_source", "polymap:water")
minetest.register_alias("mapgen_river_water_source", "polymap:water")

minetest.register_node("polymap:ground", {
    description = "Grass",
    tiles = {"polymap_grass.png"},
    groups = {ground=1},
    is_ground_content = true,
})

minetest.register_node("polymap:grass", {
    description = "Grass",
    tiles = {"polymap_grass.png"},
    groups = {ground=1},
    is_ground_content = true,
})

minetest.register_node("polymap:slope", {
    description = "Grass",
    drawtype = "mesh",
    paramtype = "light",
    paramtype2 = "facedir",
    mesh = "polymap_slope.obj",
    tiles = {"polymap_grass.png"},
    groups = {ground=1},
    is_ground_content = true,
    pointable = false,
})

minetest.register_node("polymap:convex", {
    description = "Grass",
    drawtype = "mesh",
    paramtype = "light",
    paramtype2 = "facedir",
    mesh = "polymap_convex.obj",
    tiles = {"polymap_grass.png"},
    groups = {ground=1},
    is_ground_content = true,
    pointable = false,
})

minetest.register_node("polymap:lonvex", {
    description = "Grass",
    drawtype = "mesh",
    paramtype = "light",
    paramtype2 = "facedir",
    mesh = "polymap_lonvex.obj",
    tiles = {"polymap_grass.png"},
    sunlight_propagates = true,
    groups = {ground=1},
    is_ground_content = true,
    pointable = false,
})

minetest.register_node("polymap:cap", {
    description = "Grass",
    drawtype = "mesh",
    paramtype = "light",
    paramtype2 = "facedir",
    mesh = "polymap_cap.obj",
    tiles = {"polymap_grass.png"},
    sunlight_propagates = true,
    groups = {ground=1},
    is_ground_content = true,
    pointable = false,
})

minetest.register_node("polymap:fold", {
    description = "Grass",
    drawtype = "mesh",
    paramtype = "light",
    paramtype2 = "facedir",
    mesh = "polymap_fold.obj",
    tiles = {"polymap_grass.png"},
    groups = {ground=1},
    is_ground_content = true,
    pointable = false,
})

minetest.register_node("polymap:hole", {
    description = "Grass",
    drawtype = "mesh",
    paramtype = "light",
    paramtype2 = "facedir",
    mesh = "polymap_hole.obj",
    tiles = {"polymap_grass.png"},
    groups = {ground=1},
    is_ground_content = true,
    pointable = false,
})

minetest.register_node("polymap:corn", {
    description = "Grass",
    drawtype = "mesh",
    paramtype = "light",
    paramtype2 = "facedir",
    mesh = "polymap_corn.obj",
    sunlight_propagates = true,
    tiles = {"polymap_grass.png"},
    groups = {ground=1},
    is_ground_content = true,
    pointable = false,
})

minetest.register_node("polymap:spike", {
    description = "Grass",
    drawtype = "mesh",
    paramtype = "light",
    paramtype2 = "facedir",
    sunlight_propagates = true,
    mesh = "polymap_spike.obj",
    tiles = {"polymap_grass.png"},
    groups = {ground=1},
    is_ground_content = true,
    pointable = false,
})


minetest.register_node("polymap:concave", {
    description = "Grass",
    drawtype = "mesh",
    paramtype = "light",
    paramtype2 = "facedir",
    mesh = "polymap_concave.obj",
    tiles = {"polymap_grass.png"},
    groups = {ground=1},
    is_ground_content = true,
    pointable = false,
})

minetest.register_node("polymap:junction", {
    description = "Grass",
    drawtype = "mesh",
    paramtype = "light",
    paramtype2 = "facedir",
    mesh = "polymap_junction.obj",
    tiles = {"polymap_grass.png"},
    groups = {ground=1},
    is_ground_content = true,
    pointable = false,
})

minetest.register_node("polymap:stone", {
    description = "Stone",
    tiles = {"polymap_stone.png"},
    is_ground_content = true,
})

minetest.register_node("polymap:water", {
    description = "Water",
    tiles = {"polymap_water.png"},
    pointable = false,
    is_ground_content = true,
})

minetest.register_node("polymap:coast", {
    description = "Coast",
    drawtype = "mesh",
    mesh = "polymap_coast.obj",
    tiles = {"polymap_grass.png", "polymap_water.png"},
    paramtype2 = "facedir",
    is_ground_content = true,
    pointable = false,
})

minetest.register_biome({
    name = "grassland",
    node_top = "polymap:grass",
    depth_top = 1,
    node_filler = "polymap:grass",
    depth_filler = 0,
    node_riverbed = "air",
    depth_riverbed = 2,
    node_dungeon = "air",
    node_dungeon_alt = "air",
    node_dungeon_stair = "air",
    y_max = 31000,
    y_min = 0,
    heat_point = 50,
    humidity_point = 35,
})

dofile(minetest.get_modpath("polymap").."/mapgen.lua")