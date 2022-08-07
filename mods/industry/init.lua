--[[
    Industry mod provides industrial resouces and
    related buildings that generate resources for
    a logistics network.
]]
local S = minetest.get_translator("industry")

minetest.register_node("industry:ore", {
    description = S("Ore"),
    drawtype = "mesh",
    mesh = "industry_ore.obj",
    palette = "industry_ore.png",

    paramtype = "light",
    paramtype2 = "colorfacedir",
    tiles = {"city_white.png"},

    on_punch = function(pos, node, puncher, pointed_thing)
        local node = minetest.get_node(pos)
        local param2 = node.param2%32 + math.random(0,7)*32
        minetest.set_node(pos, {name="industry:ore", param2 = param2})
    end
})