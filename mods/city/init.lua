local S = minetest.get_translator("city")

city = {
    changed = true,
}

local storage = minetest.get_mod_storage()
local db = storage

--[[
    city {
        name = "New York",
        founder = "singleplayer",
        quests = {},
    }
]]
logistics.register_network("city", {
    on_create = function(pos, player)
        local index = logistics.index(pos)

        local name = city.names[math.random(1, #city.names-1)]
        db:set_string("city/"..index.."/name", name)

        local founder = player:get_player_name()
        db:set_string("city/"..index.."/founder", founder)
    end,

    on_update = function(pos, player)

    end,
})

function city.at(pos) 
    return logistics.index(pos)
end

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
    return storage:get_string("city/"..tostring(id).."/"..key)
end

function city.set_string(id, key, val)
    city.changed = true
    return storage:set_string("city/"..tostring(id).."/"..key, val)
end

function city.get_int(id, key) 
    city.changed = true
    return storage:get_int("city/"..tostring(id).."/"..key)
end

function city.set_int(id, key, val)
    city.changed = true
    return storage:set_int("city/"..tostring(id).."/"..key, val)
end

function city.add_int(id, key, val)
    city.changed = true
    city.set_int(id, key, city.get_int(id, key) + val)
end

local modpath = minetest.get_modpath("city")

dofile(modpath.."/roads.lua")
dofile(modpath.."/energy.lua")
dofile(modpath.."/buildings.lua")
dofile(modpath.."/nature.lua")
dofile(modpath.."/names.lua")
dofile(modpath.."/industry.lua")