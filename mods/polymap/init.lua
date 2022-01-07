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

slopeslib.register_slope("polymap:grass", {
        description = S("Grass Slope"),
        pointable = false, --because selection box is ugly.
    },
    200,
    {mapgen = 0.33, place = 0.5}
)

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

local water_level = 8

--micromap.
minetest.register_on_mapgen_init(function()
    minetest.set_mapgen_setting("mg_name", "flat", true)
    minetest.set_mapgen_setting("mg_flags", "noores,nocaves,nodungeons,light,decorations,biomes", true)
    minetest.set_mapgen_setting("mgflat_spflags", "hills,lakes,nocaverns", true)
    minetest.set_mapgen_setting("water_level", water_level, true)

    local seed = math.random(0, 2^28-1)
    local existing = minetest.get_mapgen_setting_noiseparams("mgflat_np_terrain")
    if existing then
        seed = existing.seed
    end

    minetest.set_mapgen_setting_noiseparams("mgflat_np_terrain", {
        flags = "defaults",
        lacunarity = 2,
        persistence = 0.6,
        seed = seed,
        spread = {x=120,y=120,z=120},
        scale = 1,
        octaves = 5,
        offset = 0,
    }, true)

    minetest.set_mapgen_setting("mgflat_hill_threshold", "0.3", true)
    minetest.set_mapgen_setting("mgflat_hill_steepness", "10", true)
    minetest.set_mapgen_setting("mgflat_lake_threshold", "0", true)
end)

local buffer = {}
local buffer_param2 = {}



local nodes

function define_nodes() 
    nodes = {
        water = minetest.get_content_id("polymap:water"),
        grass = minetest.get_content_id("polymap:grass"),
        coast = minetest.get_content_id("polymap:coast"),
    }
end


-- Smoothen out the coastlines.
-- TODO replace slopeslib.
minetest.register_on_generated(function(minp, maxp, blockseed) 
    local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
    local data = vm:get_data(buffer)
    local param2 = vm:get_param2_data(buffer_param2)
    local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}

    --we know that water will only be at water_level 
    if emin.y > water_level then
        return
    end
    if not nodes then
        define_nodes()
    end

    local x, z
    for z = minp.z, maxp.z do
    for x = minp.x, maxp.x do
        local center = area:index(x, 8, z)

        if data[center] == nodes.grass then
            local top = data[area:index(x, 8, z+1)] == nodes.water
            local bot = data[area:index(x, 8, z-1)] == nodes.water
            local left = data[area:index(x-1, 8, z)] == nodes.water
            local right = data[area:index(x+1, 8, z)] == nodes.water

            if left and bot then
                data[center] = nodes.coast
                param2[area:index(x, 8, z)] = 0 
            elseif left and top then
                data[center] = nodes.coast
                param2[area:index(x, 8, z)] = 1
            elseif top and right then
                data[center] = nodes.coast
                param2[area:index(x, 8, z)] = 2
            elseif right and bot then
                data[center] = nodes.coast
                param2[area:index(x, 8, z)] = 3
            end
        end
    end
    end

    vm:set_data(data)
    vm:set_param2_data(param2)
    vm:set_lighting({day=0, night=0})
	vm:calc_lighting()
	vm:write_to_map()
end)