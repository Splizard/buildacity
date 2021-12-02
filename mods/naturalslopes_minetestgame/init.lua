--[[
Add natural slopes to Minetest Game
--]]
naturalslopeslib.propagate_overrides()

local path = minetest.get_modpath(minetest.get_current_modname())
dofile(path .."/functions.lua")

naturalslopeslib.default_definition.drop_source = true
naturalslopeslib.default_definition.tiles = {{align_style = "world"}}
naturalslopeslib.default_definition.groups = {not_in_creative_inventory = 1}
naturalslopeslib.default_definition.use_texture_alpha = "clip"

dofile(path .."/nodes.lua")

naturalslopeslib.reset_defaults()

dofile(path .."/tools.lua")
