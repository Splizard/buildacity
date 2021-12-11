local S = minetest.get_translator("polymap")

minetest.register_alias("mapgen_stone", "polymap:stone")
minetest.register_alias("mapgen_water_source", "polymap:water")
minetest.register_alias("mapgen_river_water_source", "polymap:water")

minetest.register_node("polymap:grass", {
    description = "Grass",
    tiles = {"polymap_grass.png"},
    is_ground_content = true,
})

minetest.register_node("polymap:stone", {
    description = "Stone",
    tiles = {"polymap_stone.png"},
    is_ground_content = true,
})

minetest.register_node("polymap:water", {
    description = "Water",
    tiles = {"polymap_water.png"},
    is_ground_content = true,
})

naturalslopeslib.register_slope("polymap:grass", {
        description = S("Grass Slope"),
    },
    200,
    {mapgen = 0.33, place = 0.5}
)

minetest.register_biome({
    name = "grassland",
    node_top = "polymap:grass",
    depth_top = 1,
    node_filler = "polymap:grass",
    depth_filler = 1,
    node_riverbed = "polymap:grass",
    depth_riverbed = 2,
    node_dungeon = "air",
    node_dungeon_alt = "air",
    node_dungeon_stair = "air",
    y_max = 31000,
    y_min = 0,
    heat_point = 50,
    humidity_point = 35,
})