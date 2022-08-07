
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

local nodes = {
    air = minetest.get_content_id("air"),
    water = minetest.get_content_id("polymap:water"),
    grass = minetest.get_content_id("polymap:grass"),
    coast = minetest.get_content_id("polymap:coast"),
    slope = minetest.get_content_id("polymap:slope"),
    convex = minetest.get_content_id("polymap:convex"),
    concave = minetest.get_content_id("polymap:concave"),
    lonvex = minetest.get_content_id("polymap:lonvex"),
    cap = minetest.get_content_id("polymap:cap"),
    fold = minetest.get_content_id("polymap:fold"),
    hole = minetest.get_content_id("polymap:hole"),
    corn = minetest.get_content_id("polymap:corn"),
    junction = minetest.get_content_id("polymap:junction"),
    spike = minetest.get_content_id("polymap:spike"),

    tree = minetest.get_content_id("air"),
}

local isEmpty = function(id)
    return id == nodes.air or id == nodes.tree
end


-- Smoothen out the coastlines.
-- TODO replace slopeslib.
minetest.register_on_generated(function(minp, maxp, blockseed) 
    nodes.tree = minetest.get_content_id("city:tree_a")

    local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
    local data = vm:get_data(buffer)
    local param2 = vm:get_param2_data(buffer_param2)
    local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}

    local x, y, z
    for z = minp.z, maxp.z do
    for x = minp.x, maxp.x do

          --we know that water will only be at water_level 
        if emin.y < water_level then
            local center = area:index(x, 8, z)

            if data[center] == nodes.grass then
                local top = data[area:index(x, 8, z+1)] == nodes.water
                local bot = data[area:index(x, 8, z-1)] == nodes.water
                local left = data[area:index(x-1, 8, z)] == nodes.water
                local right = data[area:index(x+1, 8, z)] == nodes.water

                if left and bot then
                    data[center] = nodes.coast
                    param2[center] = 0 
                elseif left and top then
                    data[center] = nodes.coast
                    param2[center] = 1
                elseif top and right then
                    data[center] = nodes.coast
                    param2[center] = 2
                elseif right and bot then
                    data[center] = nodes.coast
                    param2[center] = 3
                end
            end
        end
        
    for y = minp.y, maxp.y do
    
        local center = area:index(x, y, z)

        if data[center] == nodes.grass then
            local top = isEmpty(data[area:index(x, y, z+1)])
            local bot = isEmpty(data[area:index(x, y, z-1)])
            local left = isEmpty(data[area:index(x-1, y, z)])
            local right = isEmpty(data[area:index(x+1, y, z)])

            local tr = isEmpty(data[area:index(x+1, y, z+1)])
            local tl = isEmpty(data[area:index(x-1, y, z+1)])
            local br = isEmpty(data[area:index(x+1, y, z-1)])
            local bl = isEmpty(data[area:index(x-1, y, z-1)])

            local count = 0
            local dcount = 0
            if top then count = count + 1 end
            if bot then count = count + 1 end
            if left then count = count + 1 end
            if right then count = count + 1 end
            if tr then dcount = dcount + 1 end
            if tl then dcount = dcount + 1 end
            if br then dcount = dcount + 1 end
            if bl then dcount = dcount + 1 end

            if count == 0 then
                if dcount == 1 then
                    if tr then
                        if data[area:index(x+1, y-1, z+1)] == nodes.grass then
                            data[center] = nodes.lonvex
                        else 
                            data[center] = nodes.concave
                        end
                        param2[center] = 0
                    elseif tl then
                        if data[area:index(x-1, y-1, z+1)] == nodes.grass then
                            data[center] = nodes.lonvex
                        else 
                            data[center] = nodes.concave
                        end
                        param2[center] = 3
                    elseif br then
                        if data[area:index(x+1, y-1, z-1)] == nodes.grass then
                            data[center] = nodes.lonvex
                        else 
                            data[center] = nodes.concave
                        end
                        param2[center] = 1
                    elseif bl then
                        if data[area:index(x-1, y-1, z-1)] == nodes.grass then
                            data[center] = nodes.lonvex
                        else 
                            data[center] = nodes.concave
                        end
                        param2[center] = 2
                    end
                elseif dcount == 2 then
                    if tr and bl then
                        data[center] = nodes.hole
                        param2[center] = 1
                    elseif br and tl then
                        data[center] = nodes.hole
                        param2[center] = 0
                    elseif (tr and tl) then
                        data[center] = nodes.junction
                        param2[center] = 0
                    elseif (br and bl) then
                        data[center] = nodes.junction
                        param2[center] = 2
                    elseif (tr and br) then
                        data[center] = nodes.junction
                        param2[center] = 1
                    elseif (tl and bl) then
                        data[center] = nodes.junction
                        param2[center] = 3
                    end
                end
            end

            if count == 1 then
                if top then
                    if dcount == 4 then
                        data[center] = nodes.junction
                        param2[center] = 0
                    else
                        if br then
                            data[center] = nodes.corn
                            param2[center] = 1
                        elseif bl then
                            data[center] = nodes.corn
                            param2[center] = 0 
                        else
                            data[center] = nodes.slope
                            param2[center] = 0 
                        end
                    end
                end
                if bot then
                    data[center] = nodes.slope
                    param2[center] = 2 
                end
                if left then
                    data[center] = nodes.slope
                    param2[center] = 3
                end
                if right then
                    data[center] = nodes.slope
                    param2[center] = 1
                end
            elseif count == 2 then
                if top and bot then
                    data[center] = nodes.fold
                    param2[center] = 0
                end
                if left and right then
                    data[center] = nodes.fold
                    param2[center] = 1
                end

                if top and left then
                    data[center] = nodes.convex
                    param2[center] = 3 
                elseif top and right then
                    data[center] = nodes.convex
                    param2[center] = 0 
                elseif bot and left then
                    data[center] = nodes.convex
                    param2[center] = 2
                elseif bot and right then
                    data[center] = nodes.convex
                    param2[center] = 1
                end
            elseif count == 3 then
                if not bot then
                    if dcount > 0 then
                        data[center] = nodes.spike
                        param2[center] = 0
                    else
                        data[center] = nodes.slope
                        param2[center] = 0 
                    end
                end
                if not top then
                    if dcount > 0 then
                        data[center] = nodes.spike
                        param2[center] = 2
                    else
                        data[center] = nodes.slope
                        param2[center] = 2 
                    end
                end
                if not right then
                    if dcount > 0 then
                        data[center] = nodes.spike
                        param2[center] = 3
                    else
                        data[center] = nodes.slope
                        param2[center] = 3
                    end
                end
                if not left then
                    if dcount > 0 then
                        data[center] = nodes.spike
                        param2[center] = 1
                    else
                        data[center] = nodes.slope
                        param2[center] = 1
                    end
                end
            elseif count == 4 then
                data[center] = nodes.cap
                param2[center] = 0
            end
        end

        -- Decorations.
        if data[center] == nodes.grass and data[area:index(x, y+1, z)] == nodes.air then
            if math.random(1, 100) <= 5 then
                data[area:index(x, y+1, z)] = nodes.tree
                param2[center] = 0
            end
        end
    end
    end
    end
   

    local x, z
    for z = minp.z, maxp.z do
    for x = minp.x, maxp.x do
        
    end
    end

    vm:set_data(data)
    vm:set_param2_data(param2)
    vm:set_lighting({day=0, night=0})
	vm:calc_lighting()
	vm:write_to_map()
end)