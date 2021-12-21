local S = minetest.get_translator("city")

city = {
    changed = true,
}

local storage = minetest.get_mod_storage()

function city.load_material(mod, mtl)
    local models_path = minetest.get_modpath(mod) .. "/models/"

    --open the mtl file and load the colors
    --read the Kd lines and place the colors into the tiles.
    --this works with models exported from AssetForge.
    local mtl_file = io.open(models_path..mtl, "r")
    if not mtl_file then
        print(mtl)
    end
    local tiles = {}
    for line in mtl_file:lines() do
        if line:sub(1,3) == "Kd " then
            local rgb = line:sub(4)
            local r, g, b = rgb:match("(%S+) (%S+) (%S+)")
            local color = {
                r=255*r, g=255*g, b=255*b, a=255,
            }
            if rgb == "0.737 0.886 1" or rgb == "0.7372549 0.8862744 1" then
                color.window = true
            end
            if rgb == "0.5490196 0.5764706 0.6784315" then 
                color.road_line = true
            end
            if rgb == "0.4313726 0.454902 0.5294118" then
                tiles.asphalt = color
            end
            table.insert(tiles, {name="city_white.png", color=color})
        end
    end
    return tiles
end

function city.get_string(id, key) 
    city.changed = true
    return storage:get_string("city_"..tostring(id).."_"..key)
end

function city.set_string(id, key, val)
    city.changed = true
    return storage:set_string("city_"..tostring(id).."_"..key, val)
end

function city.get_int(id, key) 
    city.changed = true
    return storage:get_int("city_"..tostring(id).."_"..key)
end

function city.set_int(id, key, val)
    city.changed = true
    return storage:set_int("city_"..tostring(id).."_"..key, val)
end

function city.add(id, key, amount) 
    if not amount then
        amount = 1
    end
    city.changed = true
    return city.set_int(id, key, city.get_int(id, key) + amount)
end

local mapnlock

--city.get returns the ID of the city
--at pos, or nil, if there is no city.
function city.at(pos)
    local mapblock = {x=math.floor(pos.x/16), y=math.floor(pos.y/16), z=math.floor(pos.z/16)}
    local blockpos = {x=mapblock.x*16, y=mapblock.y*16, z=mapblock.z*16}
    local node = minetest.get_node(blockpos)
    if node.name == "city:pointer" then
        return node.param1*255 + node.param2
    end 
    return nil
end

function city.new(pos)
    local mapblock = {x=math.floor(pos.x/16), y=math.floor(pos.y/16), z=math.floor(pos.z/16)}
    local blockpos = {x=mapblock.x*16, y=mapblock.y*16, z=mapblock.z*16}
    local id = storage:get_int("cities")
    id = id + 1
    minetest.set_node(blockpos, {name="city:pointer", param1=math.floor(id/255), param2=id%255})
    storage:set_int("cities", id)
    local name = city.names[math.random(1, #city.names-1)]
    city.set_string(id, "name", name)
    city.changed = true
    return id
end

function city.set(pos, id) 
    local mapblock = {x=math.floor(pos.x/16), y=math.floor(pos.y/16), z=math.floor(pos.z/16)}
    local blockpos = {x=mapblock.x*16, y=mapblock.y*16, z=mapblock.z*16}
    if minetest.get_node(pos).name ~= "city:pointer" then
        minetest.set_node(blockpos, {name="city:pointer", param1=math.floor(id/255), param2=id%255})
        city.changed = true
    end
end

function city.destroy(pos)
    minetest.set_node(pos, {name = "air"})
    city.update_roads(pos)
end

--City pointer associates a map block with a city ID (stored in the params).
minetest.register_node ("city:pointer", {
    description = S("City Pointer"),
    drawtype = "airlike",
    paramtype = "none",
    paramtype2 = "none",
    sunlight_propagates = true,
})

local modpath = minetest.get_modpath("city")

dofile(modpath.."/roads.lua")
dofile(modpath.."/energy.lua")
dofile(modpath.."/buildings.lua")
dofile(modpath.."/nature.lua")
dofile(modpath.."/names.lua")