local S = minetest.get_translator("city")

local models_path = minetest.get_modpath("city") .. "/models/"

city = {}

function city.load_material(mtl)
    --open the mtl file and load the colors
    --read the Kd lines and place the colors into the tiles.
    --this works with models exported from AssetForge.
    local mtl_file = io.open(models_path..mtl, "r")
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
            table.insert(tiles, {name="city_white.png", color=color})
        end
    end
    return tiles
end

minetest.register_node("city:light", {
    drawtype = "airlike",
    paramtype = "light",
    sunlight_propagates = true,
    light_source = 14,
    pointable = false,
    walkable = false,
})


local modpath = minetest.get_modpath("city")

dofile(modpath.."/roads.lua")
dofile(modpath.."/energy.lua")
dofile(modpath.."/buildings.lua")