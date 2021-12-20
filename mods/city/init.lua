local S = minetest.get_translator("city")



city = {}

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

local modpath = minetest.get_modpath("city")

dofile(modpath.."/roads.lua")
dofile(modpath.."/energy.lua")
dofile(modpath.."/buildings.lua")