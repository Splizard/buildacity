
minetest.register_biome({
    name = "grassland",
    node_top = "default:dirt_with_grass",
    depth_top = 1,
    node_filler = "default:dirt_with_grass",
    depth_filler = 1,
    node_riverbed = "default:dirt_with_grass",
    depth_riverbed = 2,
    node_dungeon = "default:dirt_with_grass",
    node_dungeon_alt = "default:dirt_with_grass",
    node_dungeon_stair = "stairs:stair_cobble",
    y_max = 31000,
    y_min = 0,
    heat_point = 50,
    humidity_point = 35,
})