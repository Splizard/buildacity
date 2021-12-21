-- Global namespace for functions
slopeslib = {
	_register_on_generated = true,
	_propagate_overrides = false,
	default_definition = {} -- initialized below
}

local poschangelib_available = false
local twmlib_available = false
for _, name in ipairs(minetest.get_modnames()) do
	if name == "poschangelib" then
		poschangelib_available = true
	elseif name == "twmlib" then
		twmlib_available = true
	end
end

function slopeslib.reset_defaults()
	slopeslib.default_definition = {
		drop_source = false,
		tiles = {},
		groups = {}
	}
end
slopeslib.reset_defaults()

--- Get the name of the regular node from a slope, or nil.
function slopeslib.get_regular_node_name(node_name)
	if string.find(node_name, ":slope_") == nil then
		return nil
	end
	for _, regex in ipairs({"^(.-:)slope_inner_(.*)$", "^(.-:)slope_outer_(.*)$", "^(.-:)slope_pike_(.*)$", "^(.-:)slope_(.*)$"}) do
		local match, match2 = string.match(node_name, regex)
		if match and minetest.registered_nodes[match .. match2] ~= nil then
			return match .. match2
		end
	end
	return nil
end
--- {Private} Get the default node name for slopes from a subname.
-- For example 'dirt' will be named 'slopeslib:slope_dirt'
-- See slopeslib.get_all_shapes to get the actual node names.
function slopeslib.get_straight_slope_name(subname)
	return minetest.get_current_modname() .. ':slope_' .. subname
end
function slopeslib.get_inner_corner_slope_name(subname)
	return minetest.get_current_modname() .. ':slope_inner_' .. subname
end
function slopeslib.get_outer_corner_slope_name(subname)
	return minetest.get_current_modname() .. ':slope_outer_' .. subname
end
function slopeslib.get_pike_slope_name(subname)
	return minetest.get_current_modname() .. ':slope_pike_' .. subname
end

-- Set functions to get configuration and default values
function slopeslib.setting_enable_surface_update()
	if not twmlib_available then return false end
	local value = minetest.settings:get_bool('slopeslib_enable_surface_update')
	if value == nil then return true end
	return value
end
function slopeslib.setting_enable_shape_on_walk()
	if not poschangelib_available then return false end
	local value = minetest.settings:get_bool('slopeslib_enable_shape_on_walk')
	if value == nil then return true end
	return value
end
function slopeslib.setting_enable_shape_on_generation()
	local value = minetest.settings:get_bool('slopeslib_register_default_slopes')
	if value == nil then value = true end
	return value
end
function slopeslib.setting_generation_method()
	local value = minetest.settings:get('slopeslib_generation_method')
	if value == nil then value = 'VoxelManip' end
	return value
end
function slopeslib.setting_generation_factor()
	return tonumber(minetest.settings:get('slopeslib_update_shape_generate_factor')) or 0
end
function slopeslib.setting_stomp_factor()
	return tonumber(minetest.settings:get('slopeslib_update_shape_stomp_factor')) or 1.0
end
function slopeslib.setting_dig_place_factor()
	return tonumber(minetest.settings:get('slopeslib_update_shape_dig_place_factor')) or 1.0
end
function slopeslib.setting_time_factor()
	return tonumber(minetest.settings:get('slopeslib_update_shape_time_factor')) or 1.0
end
function slopeslib.setting_generation_skip()
	return tonumber(minetest.settings:get('slopeslib_update_shape_generate_skip')) or 0
end
function slopeslib.setting_enable_shape_on_dig_place()
	local value = minetest.settings:get_bool('slopeslib_enable_shape_on_dig_place')
	if value == nil then value = true end
	return value
end
function slopeslib.setting_smooth_rendering()
	local value = minetest.settings:get_bool('slopeslib_smooth_rendering')
	if value == nil then value = false end
	return true
end

function slopeslib.set_manual_map_generation()
	slopeslib._register_on_generated = false
end

function slopeslib.propagate_overrides()
	if slopeslib._propagate_overrides then
		return
	end
	slopeslib._propagate_overrides = true
	local old_override = minetest.override_item
	minetest.override_item = function(name, redefinition)
		local shapes = slopeslib.get_all_shapes(name)
		if #shapes == 1 then
			old_override(name, redefinition)
			return
		end
		local slope_redef = table.copy(redefinition)
		-- Prevent slopes fixed attribute override
		slope_redef.drawtype = nil
		slope_redef.nodebox = nil
		slope_redef.mesh = nil
		slope_redef.selection_box = nil
		slope_redef.collision_box = nil
		slope_redef.paramtype = nil
		if slope_redef.paramtype2 ~= nil then
			if slope_redef.paramtype2 == "color" or slope_redef.paramtype2 == "colorfacedir" then
				slope_redef.paramtype2 = "colorfacedir"
			else
				slope_redef.paramtype2 = "facedir"
			end
		end
		old_override(name, redefinition)
		for i=2, #shapes, 1 do
			old_override(shapes[i], slope_redef)
		end
	end
end

dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/update_shape.lua")
-- Include registration methods
dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/register_slopes.lua")
dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/sloped_stomp.lua")
