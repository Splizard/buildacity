-- Default color index conversion: match values for 0-7 and set to 0 for other values.
local function default_color_convert(color_index, to_slope)
	if to_slope then
		if color_index > 7 then
			return 0
		else
			return color_index
		end
	else
		return color_index
	end
end

-- Table of replacement from solid block to slopes.
-- Populated on slope node registration with add_replacement
-- @param colored_source (boolean) true when paramtype2 is color for the source node
-- color_convert is a function(int, int, bool) to convert the color palette values,
-- it is ignored when colored_source is false.
local replacements = {}
local replacement_ids = {}
local function add_replacement(source_name, update_chance, chance_factors, fixed_replacements, colored_source, color_to_slope, color_convert)
	if not colored_source then
		color_convert = nil
	elseif color_convert == nil then
		color_convert = default_color_convert
	end
	local subname = string.sub(source_name, string.find(source_name, ':') + 1)
	local straight_name = nil
	local ic_name = nil
	local oc_name = nil
	local pike_name = nil
	if fixed_replacements then
		straight_name = fixed_replacements[1]
		ic_name = fixed_replacements[2]
		oc_name = fixed_replacements[3]
		pike_name = fixed_replacements[4]
	else
		straight_name = slopeslib.get_straight_slope_name(subname)
		ic_name = slopeslib.get_inner_corner_slope_name(subname)
		oc_name = slopeslib.get_outer_corner_slope_name(subname)
		pike_name = slopeslib.get_pike_slope_name(subname)
	end
	local source_id = minetest.get_content_id(source_name)
	local straight_id = minetest.get_content_id(straight_name)
	local ic_id = minetest.get_content_id(ic_name)
	local oc_id = minetest.get_content_id(oc_name)
	local pike_id = minetest.get_content_id(pike_name)
	-- Full to slopes
	local dest_data = {
		source = source_name,
		straight = straight_name,
		inner = ic_name,
		outer = oc_name,
		pike = pike_name,
		chance = update_chance,
		chance_factors = chance_factors,
		_colored_source = colored_source,
		_color_convert = color_convert
	}
	local dest_data_id = {
		source = source_id,
		straight = straight_id,
		inner = ic_id,
		outer = oc_id,
		pike = pike_id,
		chance = update_chance,
		chance_factors = chance_factors,
		_colored_source = colored_source,
		_color_convert = color_convert
	}
	-- Block
	replacements[source_name] = dest_data
	replacement_ids[source_id] = dest_data_id
	-- Straight
	replacements[straight_name] = dest_data
	replacement_ids[straight_id] = dest_data_id
	-- Inner
	replacements[ic_name] = dest_data
	replacement_ids[ic_id] = dest_data_id
	-- Outer
	replacements[oc_name] = dest_data
	replacement_ids[oc_id] = dest_data_id
	-- Pike
	replacements[pike_name] = dest_data
	replacement_ids[pike_id] = dest_data_id
end

--- Get replacement description of a node.
-- Contains replacement names in either source or (straight, inner, outer)
-- and chance.
function slopeslib.get_replacement(source_node_name)
	return replacements[source_node_name]
end
--- Get replacement description of a node by content id for VoxelManip.
-- Contains replacement ids in either source or (straight, inner, outer)
-- and chance.
function slopeslib.get_replacement_id(source_id)
	return replacement_ids[source_id]
end

function slopeslib.get_all_shapes(source_node_name)
	if replacements[source_node_name] then
		local rp = replacements[source_node_name]
		return {rp.source, rp.straight, rp.inner, rp.outer, rp.pike}
	else
		return {source_node_name}
	end
end

--[[ Bounding boxes
--]]

local slope_straight_box = {
	type = "fixed",
	fixed = {
		{-0.5, -0.5, -0.5, 0.5, 0, 0.5},
		{-0.5, 0, 0, 0.5, 0.5, 0.5},
	},
}
local slope_inner_corner_box = {
	type = "fixed",
	fixed = {
		{-0.5, -0.5, -0.5, 0.5, 0, 0.5},
		{-0.5, 0, 0, 0.5, 0.5, 0.5},
		{-0.5, 0, -0.5, 0, 0.5, 0},
	},
}
local slope_outer_corner_box = {
	type = "fixed",
	fixed = {
		{-0.5, -0.5, -0.5, 0.5, 0, 0.5},
		{-0.5, 0, 0, 0, 0.5, 0.5},
	},
}
local slope_pike_box = {
	type = "fixed",
	fixed = {
		{-0.5, -0.5, -0.5, 0.5, 0, 0.5},
	},
}

local function apply_default_slope_def(base_node_name, node_def, slope_group_value)
	node_def.paramtype = 'light'
	if node_def.paramtype2 == 'color' or node_def.paramtype2 == 'colorfacedir' then
		node_def.paramtype2 = 'colorfacedir'
	else
		node_def.paramtype2 = 'facedir'
	end
	if not node_def.groups then node_def.groups = {} end
	node_def.groups.natural_slope = slope_group_value
	if not node_def.groups["family:" .. base_node_name] then
		node_def.groups["family:" .. base_node_name] = 1
	end
	return node_def
end

--- {Private} Update the node definition for a straight slope
local function get_straight_def(base_node_name, node_def)
	node_def = apply_default_slope_def(base_node_name, node_def, 1)
	if slopeslib.setting_smooth_rendering() then
		node_def.drawtype = 'mesh'
		node_def.mesh = 'slopeslib_straight.obj'
	else
		node_def.drawtype = 'nodebox'
		node_def.node_box = slope_straight_box
	end
	node_def.selection_box = slope_straight_box
	node_def.collision_box = slope_straight_box
	return node_def
end

--- {Private} Update the node definition for an inner corner
local function get_inner_def(base_node_name, node_def)
	node_def = apply_default_slope_def(base_node_name, node_def, 2)
	if slopeslib.setting_smooth_rendering() then
		node_def.drawtype = 'mesh'
		node_def.mesh = 'slopeslib_inner.obj'
	else
		node_def.drawtype = 'nodebox'
		node_def.node_box = slope_inner_corner_box
	end
	node_def.selection_box = slope_inner_corner_box
	node_def.collision_box = slope_inner_corner_box
	return node_def
end

--- {Private} Update the node definition for an outer corner
local function get_outer_def(base_node_name, node_def)
	node_def = apply_default_slope_def(base_node_name, node_def, 3)
	if slopeslib.setting_smooth_rendering() then
		node_def.drawtype = 'mesh'
		node_def.mesh = 'slopeslib_outer.obj'
	else
		node_def.drawtype = 'nodebox'
		node_def.node_box = slope_outer_corner_box
	end
	node_def.selection_box = slope_outer_corner_box
	node_def.collision_box = slope_outer_corner_box
	return node_def
end

--- {Private} Update the node definition for a pike
local function get_pike_def(base_node_name, node_def, update_chance)
	node_def = apply_default_slope_def(base_node_name, node_def, 4)
	if slopeslib.setting_smooth_rendering() then
		node_def.drawtype = 'mesh'
		node_def.mesh = 'slopeslib_pike.obj'
	else
		node_def.drawtype = 'nodebox'
		node_def.node_box = slope_pike_box
	end
	node_def.selection_box = slope_pike_box
	node_def.collision_box = slope_pike_box
	return node_def
end

-- Expand `tiles` to use the {name = "image"} format for each tile
local function convert_to_expanded_tiles_def(tiles)
	if tiles then
		for i, tile_def in ipairs(tiles) do
			if type(tile_def) == "string" then
				tiles[i] = {name = tile_def}
			end
		end
	end
end

function slopeslib.get_slope_defs(base_node_name, def_changes)
	local base_node_def = minetest.registered_nodes[base_node_name]
	if not base_node_def then
		minetest.log("error", "Trying to get slopes for an unknown node " .. (base_node_name or "nil"))
		return
	end
	local full_copy = table.copy(base_node_def)
	local changes_copy = table.copy(def_changes)
	for key, value in pairs(def_changes) do
		if value == "nil" then
			full_copy[key] = nil
		else
			full_copy[key] = value
		end
	end
	-- Handle default drop overrides
	if not base_node_def.drop and not def_changes.drop and slopeslib.default_definition.drop_source then
		-- If drop is not set and was not reseted
		full_copy.drop = base_node_name
	end
	-- Convert all tile definition to the list format to be able to override properties
	if not full_copy.tiles or #full_copy.tiles == 0 then
		full_copy.tiles = {{}}
	end
	convert_to_expanded_tiles_def(full_copy.tiles)
	if not changes_copy.tiles or #changes_copy.tiles == 0 then
		changes_copy.tiles = {{}}
	end
	convert_to_expanded_tiles_def(changes_copy.tiles)
	local default_tile_changes = table.copy(slopeslib.default_definition.tiles)
	if not default_tile_changes or #default_tile_changes == 0 then
		default_tile_changes = {{}}
	end
	convert_to_expanded_tiles_def(default_tile_changes)	
	-- Make tile changes and default changes the same size
	local desired_size = math.max(#full_copy.tiles, #changes_copy.tiles, #default_tile_changes)
	while #changes_copy.tiles < desired_size do
		table.insert(changes_copy.tiles, table.copy(changes_copy.tiles[#changes_copy.tiles]))
	end
	while #default_tile_changes < desired_size do
		-- no need to copy because defaults won't be alterated
		table.insert(default_tile_changes, default_tile_changes[#default_tile_changes])
	end
	while #full_copy.tiles < desired_size do
		table.insert(full_copy.tiles, table.copy(full_copy.tiles[#full_copy.tiles]))
	end
	-- Apply default tile changes
	for i = 1, desired_size, 1 do
		if default_tile_changes[i].align_style ~= nil and changes_copy.tiles[i].align_style == nil then
			full_copy.tiles[i].align_style = default_tile_changes[i].align_style
		end
		if default_tile_changes[i].backface_culling ~= nil and changes_copy.tiles[i].backface_culling == nil then
			full_copy.tiles[i].backface_culling = default_tile_changes[i].backface_culling
		end
		if default_tile_changes[i].scale and changes_copy.tiles[i].scale == nil then
			full_copy.tiles[i].scale = default_tile_changes[i].scale
		end
	end
	-- Handle default groups
	for group, value in pairs(slopeslib.default_definition.groups) do
		if not def_changes.groups or def_changes.groups[group] == nil then
			full_copy.groups[group] = value
		end
	end
	-- Handle other values
	for key, value in pairs(slopeslib.default_definition) do
		if key ~= "groups" and key ~= "drop_source" and key ~= "tiles" then
			if changes_copy[key] == nil then
				if type(value) == "table" then
					full_copy[key] = table.copy(value)
				else
					full_copy[key] = value
				end
			end
		end
	end
	-- Use a copy because tables are passed by reference. Otherwise the node
	-- description is shared and updated after each call
	return {
		get_straight_def(base_node_name, table.copy(full_copy)),
		get_inner_def(base_node_name, table.copy(full_copy)),
		get_outer_def(base_node_name, table.copy(full_copy)),
		get_pike_def(base_node_name, table.copy(full_copy))
	}
end

local function default_factors(factors)
	local f = {}
	if factors == nil then factors = {} end
	for _, name in ipairs({"mapgen", "time", "stomp", "place"}) do
		if factors[name] ~= nil then
			f[name] = factors[name]
		else
			f[name] = 1
		end
	end
	return f
end

--- Register slopes from a full block node.
-- @param base_node_name: The full block node name.
-- @param node_desc: base for slope node descriptions.
-- @param update_chance: inverted chance for the node to be updated.
-- @param factors (optional): chance factor for each type.
-- @param color_convert (optional): the function to convert color palettes
-- @return Table of slope names: [straight, inner, outer, pike] or nil on error.
function slopeslib.register_slope(base_node_name, def_changes, update_chance, factors, color_convert)
	if not update_chance then
		minetest.log('error', 'Natural slopes: chance is not set for node ' .. base_node_name)
		return
	end
	local base_node_def = minetest.registered_nodes[base_node_name]
	if not base_node_def then
		minetest.log("error", "Trying to register slopes for an unknown node " .. (base_node_name or "nil"))
		return
	end
	local chance_factors = default_factors(factors)
	-- Get new definitions
	local subname = string.sub(base_node_name, string.find(base_node_name, ':') + 1)
	local slope_names = {
		slopeslib.get_straight_slope_name(subname),
		slopeslib.get_inner_corner_slope_name(subname),
		slopeslib.get_outer_corner_slope_name(subname),
		slopeslib.get_pike_slope_name(subname)
	}
	local slope_defs = slopeslib.get_slope_defs(base_node_name, def_changes)
	-- Register all slopes
	local stomp_factor = slopeslib.setting_stomp_factor()
	for i, name in ipairs(slope_names) do
		minetest.register_node(name, slope_defs[i])
		-- Register walk listener
		if slopeslib.setting_enable_shape_on_walk() then
			poschangelib.register_stomp(name,
				slopeslib.update_shape_on_walk,
				{name = name .. '_upd_shape',
				chance = update_chance * chance_factors.stomp * stomp_factor, priority = 500})
		end
	end
	-- Register replacements
	local colored = base_node_def.paramtype2 == "color"
	add_replacement(base_node_name, update_chance, chance_factors, slope_names, colored, color_convert)
	-- Enable on walk update for base node
	if slopeslib.setting_enable_shape_on_walk() then
		poschangelib.register_stomp(base_node_name,
			slopeslib.update_shape_on_walk,
			{name = base_node_name .. '_upd_shape',
			chance = update_chance * chance_factors.stomp * stomp_factor, priority = 500})
	end
	-- Enable surface update
	local time_factor = slopeslib.setting_time_factor()
	if slopeslib.setting_enable_surface_update() then
		twmlib.register_twm({
			nodenames = {base_node_name, slope_defs[1], slope_defs[2], slope_defs[3], slope_defs[4]},
			chance = update_chance * chance_factors.time * time_factor,
			action = slopeslib.update_shape
		})
	end
	return slopeslib.get_replacement(base_node_name)
end

--- Add a slopping behaviour to existing nodes.
function slopeslib.set_slopes(base_node_name, straight_name, inner_name, outer_name, pike_name, update_chance, factors, color_convert)
	-- Defensive checks
	if not minetest.registered_nodes[base_node_name] then
		if not base_node_name then
			minetest.log('error', 'slopeslib.set_slopes failed: base node_name is nil.')
		else
			minetest.log('error', 'slopeslib.set_slopes failed: ' .. base_node_name .. ' is not registered.')
		end
		return
	end
	if not minetest.registered_nodes[straight_name]
	or not minetest.registered_nodes[inner_name]
	or not minetest.registered_nodes[outer_name]
	or not minetest.registered_nodes[pike_name] then
		minetest.log('error', 'slopeslib.set_slopes failed: one of the slopes for ' .. base_node_name .. ' is not registered.')
		return
	end
	if not update_chance then
		minetest.log('error', 'Natural slopes: chance is not set for node ' .. base_node_name)
		return
	end
	local chance_factors = default_factors(factors)
	-- Set shape update data
	local slope_names = {straight_name, inner_name, outer_name, pike_name}
	local colored = minetest.registered_nodes[base_node_name].paramtype2 == "color"
	add_replacement(base_node_name, update_chance, chance_factors, slope_names, colored, color_convert)
	-- Set surface update
	if slopeslib.setting_enable_surface_update() then
		local time_factor = slopeslib.setting_time_factor()
		twmlib.register_twm({
			nodenames = {base_node_name, straight_name, inner_name, outer_name, pike_name},
			chance = update_chance * chance_factors.time * time_factor,
			action = slopeslib.update_shape
		})
	end
	-- Set walk listener for the 5 nodes
	if slopeslib.setting_enable_shape_on_walk() then
		local stomp_factor = slopeslib.setting_stomp_factor()
		local stomp_desc = {name = base_node_name .. '_upd_shape',
			chance = update_chance * chance_factors.stomp * stomp_factor, priority = 500}
		poschangelib.register_stomp(base_node_name, slopeslib.update_shape_on_walk, stomp_desc)
		for i, name in pairs(slope_names) do
			poschangelib.register_stomp(name, slopeslib.update_shape_on_walk, stomp_desc)
		end
	end
	return slopeslib.get_replacement(base_node_name)
end

