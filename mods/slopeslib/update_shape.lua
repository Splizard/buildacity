--[[
Describes the falling/eroding effect for slopes
--]]

--[[
Pick replacement, node and area
--]]

-- Manage color for param2
-- @param replacement the replacement table
-- @param source the name or id of the node being transformed
-- @param dest the name or id of the new shape
-- @param param2_source the param2 value before transformation
-- @param param2_dest the param2 value for facedir (if any) after transformation
-- @return a new param2 value for dest node with color if necessary
local function manage_param2_color(replacement, source, dest, param2_source, param2_dest)
	if not replacement._colored_source then
		return param2_dest
	end
	if dest == replacement.source then
		-- param2_source will hold a 'color' value
		if source == replacement.source then
			-- from 'color' to 'color'
			return param2_source
		else
			-- from 'color' to 'colorfacedir'
			local new_color_index = replacement._color_convert(param2_source, true) % 8
			return param2_dest + (new_color_index * 32)
		end
	else
		-- param2_source will hold a 'colorfacedir' value
		if dest == replacement.source then
			-- from 'colorfacedir' to 'color'
			local old_color = math.floor(param2_source / 32)
			return replacement._color_convert(old_color, false) % 256
		else
			-- from 'colorfacedir' to an other 'colorfacedir'
			local color = math.floor(param2_source / 32)
			return param2_dest + (color * 32)
		end
	end
end

--- {Private} Pick a replacement node.
-- @param type The replacement shape. Either 'block', 'straight', 'ic' or 'oc'
-- @param name The name (or id for area) of the node to replace.
-- @param old_param2 The current value of param2 for the node to replace
-- @param param2 Facedir value to orient the new node.
-- @param for_area True when picking for an area, changes the parameter types
-- @return node {name=new_name, param2=new_param2} or area data {id=new_id, param2_data=new_param2}
-- or nil if dest node is not found.
local function pick_replacement(slope_type, name, old_param2, param2, for_area)
	local replacement
	if for_area then
		replacement = slopeslib.get_replacement_id(name)
	else
		replacement = slopeslib.get_replacement(name)
	end
	if not replacement then return nil end
	local dest_node_name = nil
	if slope_type == 'block' and replacement.source then
		dest_node_name = replacement.source
	elseif slope_type == 'pike' and replacement.pike then
		dest_node_name = replacement.pike
	elseif slope_type == 'straight' and replacement.straight then
		dest_node_name = replacement.straight
	elseif slope_type == 'ic' and replacement.inner then
		dest_node_name = replacement.inner
	elseif slope_type == 'oc' and replacement.outer then
		dest_node_name = replacement.outer
	end
	if dest_node_name then
		if param2 == nil then param2 = 0 end
		local color_param2 = manage_param2_color(replacement, name, dest_node_name, old_param2, param2)
		if for_area then
			return {id = dest_node_name, param2_data = color_param2}
		else
			return {name = dest_node_name, param2 = color_param2}
		end
	end
	return nil
end


--[[
Surrounding checks and get replacement
--]]

--- Check if a node is considered empty to switch shape.
-- @param pos The position to check
function slopeslib.is_free_for_shape_update(pos)
	if not pos then return nil end
	local node = minetest.get_node_or_nil(pos)
	if node == nil then
		return nil
	end
	return node.name == 'air'
end

local air_id = minetest.get_content_id('air')
function slopeslib.area_is_free_for_shape_update(area, data, index)
	if not area:containsi(index) then
		return nil
	end
	return data[index] == air_id
end
-- Deprecated name
slopeslib.area_is_free_for_erosion = slopeslib.area_is_free_for_shape_update

--- Get the replacement node according to it's surroundings.
-- @param pos The position of the node or index with VoxelArea.
-- @param node The node at that position or content id with VoxelArea.
-- @param area The VoxelArea, nil for single position update.
-- @param data Data from VoxelManip, nil for single position update.
-- @param param2_data Param2 data from VoxelManip, nil for single position update.
-- @return A node to use with minetest.set_node
-- or a table with id and param2_data if called with an area.
-- Nil if no replacement is found or a neighbour cannot be read.
function slopeslib.get_replacement_node(pos, node, area, data, param2_data)
	-- Set functions and data according to update mode: single or VoxelManip
	local is_free = nil
	local new_pos = nil
	local replacement = nil
	local node_name = nil -- Either name or id
	local for_area = false
	local old_param2 = 0
	if area then
		for_area = true
		is_free = function (at_index) -- always use with new_pos
			return slopeslib.area_is_free_for_shape_update(area, data, at_index)
		end
		new_pos = function(add) -- Get new index from current with add position
			local area_pos = area:position(pos)
			return area:indexp(vector.add(area_pos, add))
		end
		node_name = node
		old_param2 = param2_data[pos]
	else
		is_free = slopeslib.is_free_for_shape_update
		new_pos = function(add) return vector.add(pos, add) end
		node_name = node.name
		old_param2 = node.param2
	end
	local is_ground -- ground or ceiling node
	local pointing_y = -1
	-- If there's something above and below, get back to full block
	local above_free = is_free(new_pos({x=0, y=1, z=0}))
	local below_free = is_free(new_pos({x=0, y=-1, z=0}))
	if above_free == nil or below_free == nil then
		return nil
	end
	if above_free and not below_free then
		is_ground = true
		pointing_y = 1
	elseif below_free and not above_free then
		is_ground = false
		pointing_y = 5
	else -- nothing below and above
		return pick_replacement("block", node_name, old_param2, 0, for_area)
	end
	-- Check blocks around
	local airXP = is_free(new_pos({x=1, y=0, z=0}))
	if airXP == nil then return nil end
	local airXM = is_free(new_pos({x=-1, y=0, z=0}))
	if airXM == nil then return nil end
	local airZP = is_free(new_pos({x=0, y=0, z=1}))
	if airZP == nil then return nil end
	local airZM = is_free(new_pos({x=0, y=0, z=-1}))
	if airZM == nil then return nil end
	local free_neighbors = 0
	for index, free in next, {airXP, airXM, airZP, airZM} do
		if free then free_neighbors = free_neighbors + 1 end
	end
	-- For four or three free neighbors, pike (slab)
	if free_neighbors == 4 or free_neighbors == 3 then
		local param2 = 0
		if is_ground == false then param2 = 20 end
		return pick_replacement("pike", node_name, old_param2, param2, for_area)
	-- For two free neighbors
	elseif free_neighbors == 2 then
		-- at opposite sides, block
		local param2
		if (airXP and airXM) or (airZP and airZM) then
			return pick_replacement('block', node_name, old_param2, 0, for_area)
		-- side by side, outer corner
		elseif (airXP and airZP) then
			if is_ground then param2 = 3 else param2 = 22 end
			return pick_replacement("oc", node_name, old_param2, param2, for_area)
		elseif (airXP and airZM) then
			if is_ground then param2 = 0 else param2 = 21 end
			return pick_replacement("oc", node_name, old_param2, param2, for_area)
		elseif (airXM and airZP) then
			if is_ground then param2 = 2 else param2 = 23 end
			return pick_replacement("oc", node_name, old_param2, param2, for_area)
		elseif (airXM and airZM) then
			if is_ground then param2 = 1 else param2 = 20 end
			return pick_replacement("oc", node_name, old_param2, param2, for_area)
		end
	-- For one free neighbor, straight slope
	elseif free_neighbors == 1 then
		local param2 = 0
		if airXP then if is_ground then param2 = 3 else param2 = 15 end
		elseif airXM then if is_ground then param2 = 1 else param2 = 17 end
		elseif airZP then if is_ground then param2 = 2 else param2 = 6 end
		elseif airZM then if is_ground then param2 = 0 else param2 = 8 end
		end
		return pick_replacement("straight", node_name, old_param2, param2, for_area)
	-- For no free neighbor check for a free diagonal for an inner corner
	-- or fully surrounded for a rebuild
	else
		local airXPZP = is_free(new_pos({x=1, y=0, z=1}))
		local airXPZM = is_free(new_pos({x=1, y=0, z=-1}))
		local airXMZP = is_free(new_pos({x=-1, y=0, z=1}))
		local airXMZM = is_free(new_pos({x=-1, y=0, z=-1}))
		local param2
		if airXPZP and not airXPZM and not airXMZP and not airXMZM then
			if is_ground then param2 = 3 else param2 = 15 end
			return pick_replacement("ic", node_name, old_param2, param2, for_area)
		elseif not airXPZP and airXPZM and not airXMZP and not airXMZM then
			if is_ground then param2 = 0 else param2 = 8 end
			return pick_replacement("ic", node_name, old_param2, param2, for_area)
		elseif not airXPZP and not airXPZM and airXMZP and not airXMZM then
			if is_ground then param2 = 2 else param2 = 23 end
			return pick_replacement("ic", node_name, old_param2, param2, for_area)
		elseif not airXPZP and not airXPZM and not airXMZP and airXMZM then
			if is_ground then param2 = 1 else param2 = 17 end
			return pick_replacement("ic", node_name, old_param2, param2, for_area)
		else
			return pick_replacement('block', node_name, old_param2, 0, for_area)
		end
	end
end


--[[
Do the replacement
--]]

-- Do shape update when random roll passes on a single node.
function slopeslib.chance_update_shape(pos, node, factor, type)
	if factor == nil then factor = 1 end
	local replacement = slopeslib.get_replacement(node.name)
	if not replacement then return false end
	local chance_factor = 1
	if type == "mapgen" or type == "stomp" or type == "place" or type == "time" then
		chance_factor = replacement.chance_factors[type]
	end
	if (math.random() * (replacement.chance * factor * chance_factor)) < 1.0 then
		return slopeslib.update_shape(pos, node)
	end
	return false
end

--- Try to update the shape of a node according to it's surroundings.
-- @param pos The position of the node.
-- @param node The node at that position.
-- @return True if the node was updated, false otherwise.
function slopeslib.update_shape(pos, node)
	local replacement = slopeslib.get_replacement_node(pos, node)
	if replacement and (replacement.name ~= node.name or node.param2 ~= replacement.param2) then
		minetest.set_node(pos, replacement)
		return true
	else
		return false
	end
end

local function get_edges(minp, maxp)
	-- corner000 = minp
	local corner001 = {x = minp.x, y = minp.y, z = maxp.z}
	local corner010 = {x = minp.x, y = maxp.y, z = minp.z}
	local corner011 = {x = minp.x, y = maxp.y, z = maxp.z}
	local corner100 = {x = maxp.x, y = minp.y, z = minp.z}
	local corner101 = {x = maxp.x, y = minp.y, z = maxp.z}
	local corner110 = {x = maxp.x, y = maxp.y, z = minp.z}
	-- corner111 = maxp
	return { -- min pos, max pos, normal[x, y ,z]
		-- The 8 corners
		{minp,      minp,      {-1, -1, -1}},
		{corner001, corner001, {-1, -1,  1}},
		{corner010, corner010, {-1,  1, -1}},
		{corner011, corner011, {-1,  1,  1}},
		{corner100, corner100, { 1, -1, -1}},
		{corner101, corner101, { 1, -1,  1}},
		{corner110, corner110, { 1,  1, -1}},
		{maxp,      maxp,      { 1,  1,  1}},
		-- The 8 segments
		{{x = minp.x + 1, y = minp.y, z = minp.z}, {x = maxp.x - 1, y = minp.y, z = minp.z}, { 0, -1, -1}},
		{{x = minp.x + 1, y = maxp.y, z = minp.z}, {x = maxp.x - 1, y = maxp.y, z = minp.z}, { 0,  1, -1}},
		{{x = minp.x, y = minp.y + 1, z = minp.z}, {x = minp.x, y = maxp.y - 1, z = minp.z}, {-1,  0, -1}},
		{{x = maxp.x, y = minp.y + 1, z = minp.z}, {x = maxp.x, y = maxp.y - 1, z = minp.z}, { 1,  0, -1}},
		{{x = minp.x + 1, y = minp.y, z = maxp.z}, {x = maxp.x - 1, y = minp.y, z = maxp.z}, { 0, -1, 1}},
		{{x = minp.x + 1, y = maxp.y, z = maxp.z}, {x = maxp.x - 1, y = maxp.y, z = maxp.z}, { 0,  1, 1}},
		{{x = minp.x, y = minp.y + 1, z = maxp.z}, {x = minp.x, y = maxp.y - 1, z = maxp.z}, { -1, 0, 1}},
		{{x = maxp.x, y = minp.y + 1, z = maxp.z}, {x = maxp.x, y = maxp.y - 1, z = maxp.z}, {  1, 0, 1}},
		-- The 6 faces
		{{x = minp.x + 1, y = minp.y, z = minp.z + 1}, {x = maxp.x - 1, y = minp.y, z = maxp.z - 1}, {  0, -1,  0}},
		{{x = minp.x + 1, y = maxp.y, z = minp.z + 1}, {x = maxp.x - 1, y = maxp.y, z = maxp.z - 1}, {  0,  1,  0}},
		{{x = minp.x, y = minp.y + 1, z = minp.z + 1}, {x = minp.x, y = maxp.y - 1, z = maxp.z - 1}, { -1,  0,  0}},
		{{x = maxp.x, y = minp.y + 1, z = minp.z + 1}, {x = maxp.x, y = maxp.y - 1, z = maxp.z - 1}, {  1,  0,  0}},
		{{x = minp.x + 1, y = minp.y + 1, z = minp.z}, {x = maxp.x - 1, y = maxp.y - 1, z = minp.z}, {  0,  0, -1}},
		{{x = minp.x + 1, y = minp.y + 1, z = maxp.z}, {x = maxp.x - 1, y = maxp.y - 1, z = maxp.z}, {  0,  0,  1}}
	}
end

local buffer = {}
local buffer_param = {}

--- Massive shape update with VoxelManip.
-- @param minp Lower boundary of area.
-- @param mapx Higher boundary of area.
-- @param factor Factor for chance (0.1 means 10 times more likely to update)
-- @param skip (optional) Don't parse all nodes, skip randomly skip/2 to skip nodes
-- @param progressive_edges (optional) When true, edges are generated progressively (default)
-- @param type (optional) Transformation type for chance factor.
-- at every loop.
function slopeslib.area_chance_update_shape(minp, maxp, factor, skip, progressive_edges, type)
	if not skip then skip = 0 end
	if progressive_edges == nil then progressive_edges = true end
	-- Run on every block
	local vm, emin, emax = minetest.get_voxel_manip()
	local e1, e2 = vm:read_from_map(minp, maxp)
	local area = VoxelArea:new{MinEdge = e1, MaxEdge = e2}
	local data = vm:get_data(buffer)
	local param2_data = vm:get_param2_data(buffer_param)
	local i = area:indexp(e1)
	local imax = area:indexp(e2)
	if progressive_edges then
		local edges = get_edges(minp, maxp)
		for _, edge in ipairs(edges) do
			slopeslib.register_progressive_area_update(edge[1], edge[2], factor, skip, type, {x = edge[3][1], y = edge[3][2], z = edge[3][3]})
		end
	end
	while i <= imax do
		local x = (i-1) % area.ystride
		local y = (i-1) % area.zstride
		if x == 0 or x == area.ystride - 1
		or y == 0 or y == area.zstride - 1 then
			-- Skip edges
		else
			local replacement = slopeslib.get_replacement_id(data[i])
			if replacement ~= nil then
				local chance_factor = 1
				if type == "mapgen" or type == "stomp" or type == "place" or type == "time" then
					chance_factor = replacement.chance_factors[type]
				end
				if math.random() * (replacement.chance * factor * chance_factor) < 1.0 then
					local new_data = slopeslib.get_replacement_node(i, data[i], area, data, param2_data)
					if new_data then
						data[i] = new_data.id
						if new_data.param2_data then
							param2_data[i] = new_data.param2_data
						end
					end
				end
			end
		end
		i = i + 1
	end
	vm:set_data(data)
	vm:set_param2_data(param2_data)
	vm:write_to_map()
end

slopeslib.progressive_area_updates = {}

function slopeslib.register_progressive_area_update(minp, maxp, factor, skip, type, edge_normal)
	if edge_normal ~= nil or minp.x == maxp.x or minp.y == maxp.y or minp.z == maxp.z then
		-- Explicit edge or ignored
		table.insert(slopeslib.progressive_area_updates, {minp = minp, maxp = maxp,
				factor = factor, skip = skip, i = 1, edge_normal = edge_normal})
		return
	end
	-- else register the inner cube and all edges
	-- The inner cube
	table.insert(slopeslib.progressive_area_updates, {
			minp = vector.add(minp, 1),
			maxp = vector.add(maxp, -1),
			factor = factor, skip = skip, i = 1, edge_normal = nil})
	local edges = get_edges(minp, maxp)
	-- Register
	for _, edge in ipairs(edges) do
		table.insert(slopeslib.progressive_area_updates, {
				minp = edge[1], maxp = edge[2],
				factor = factor, type = type, skip = skip, i = 1,
				edge_normal = {x = edge[3][1], y = edge[3][2], z = edge[3][3]}
		})
	end
end


local function check_area_edges(area)
	if area.edge_normal == nil then
		return true
	end
	local edge = area.edge_normal
	local pos = area.minp
	local requirements = math.abs(edge.x) + math.abs(edge.y) + math.abs(edge.z)
	local found = 0
	if edge.x ~= 0 then
		if minetest.get_node_or_nil(vector.add(pos, {x = edge.x, y = 0, z = 0})) ~= nil then
			found = found + 1
		end
	end
	if edge.y ~= 0 then
		if minetest.get_node_or_nil(vector.add(pos, {x = 0, y = edge.y, z = 0})) ~= nil then
			found = found + 1
		end
	end
	if edge.z ~= 0 then
		if minetest.get_node_or_nil(vector.add(pos, {x = 0, y = 0, z = edge.z})) ~= nil then
			found = found + 1
		end
	end
	return found == requirements
end

local function progressive_area_update(start_time)
	if #slopeslib.progressive_area_updates == 0 then
		return true
	end
	if start_time == nil then
		start_time = os.clock()
	end
	-- pick an area around a player at random and process it
	local players = minetest.get_connected_players()
	local processed_area_index = nil
	local alt_processed_area_index = nil
	for area_index, area in ipairs(slopeslib.progressive_area_updates) do
		for _, p in ipairs(players) do
			local minp = area.minp
			local maxp = area.maxp
			local ppos = p:get_pos()
			if ppos.x >= minp.x and ppos.x <= maxp.x and ppos.y >= minp.y and ppos.y <= maxp.y and ppos.z >= minp.z and ppos.z <= maxp.z then
				-- Prefer an area in which a player is
				if (check_area_edges(area)) then
					processed_area_index = area_index
					break
				end
			elseif alt_processed_area_index == nil and ppos.x + 16 >= minp.x and ppos.x - 16 <= maxp.x and ppos.y + 16 >= minp.y and ppos.y - 16 <= maxp.y and ppos.z + 16 >= minp.z and ppos.z - 16 <= maxp.z then
				-- Else pick an area near a player
				if (check_area_edges(area)) then
					alt_processed_area_index = area_index
				end
			end
		end
		if processed_area_index ~= nil then
			local area = slopeslib.progressive_area_updates[processed_area_index]
		end
	end
	if processed_area_index == nil then
		if alt_processed_area_index ~= nil then
			processed_area_index = alt_processed_area_index
		else
			processed_area_index = 1 -- try to reduce the queue as fast as possible
		end
	end
	local area = slopeslib.progressive_area_updates[processed_area_index]
	local i = area.i
	local y_size = area.maxp.y - area.minp.y + 1
	local z_size = area.maxp.z - area.minp.z + 1
	local imax = y_size * z_size * (area.maxp.x - area.minp.x + 1)
	while i <= imax do
		local x = math.floor((i - 1) / (y_size * z_size))
		local y = math.floor((i - 1) / z_size) % y_size
		local z = (i - 1) % (z_size)
		local pos = {x = area.minp.x + x, y = area.minp.y + y, z = area.minp.z + z}
		local node = minetest.get_node(pos)
		slopeslib.chance_update_shape(pos, node, area.factor, area.type)
		i = i + 1 + math.random(area.skip / 2, area.skip)
		if (os.clock() - start_time) > 0.1 and i <= imax then
			area.i = i
			return false
		end
	end
	table.remove(slopeslib.progressive_area_updates, processed_area_index)
	if os.clock() - start_time < 0.1 then
		progressive_area_update(start_time)
	end
	return true
end

local generation_dtime = 0
local function generation_globalstep(dtime)
	generation_dtime = generation_dtime + dtime
	if generation_dtime > 0.1 then
		progressive_area_update()
		generation_dtime = 0
	end
end
minetest.register_globalstep(generation_globalstep)

minetest.register_on_shutdown(function()
	if #slopeslib.progressive_area_updates > 0 then
		minetest.log("info", "Processing slope generation for queued areas")
		for i, area in ipairs(slopeslib.progressive_area_updates) do
			minetest.log("info", (#slopeslib.progressive_area_updates - i + 1) .. " remaining area(s)")
			slopeslib.area_chance_update_shape(area.minp, area.maxp, area.factor, area.skip, false, area.type)
		end
	end
end)

--[[
Triggers registration
--]]

-- Stomp function to get the replacement node name
function slopeslib.update_shape_on_walk(player, pos, node, desc, trigger_meta)
	return slopeslib.get_replacement_node(pos, node)
end

-- Chat command
minetest.register_chatcommand('updshape', {
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		if not player then return false, 'Player not found' end
		if not minetest.check_player_privs(player, {server=true}) then return false, 'Update shape requires server privileges' end
		local pos = player:get_pos()
		local node_pos = {['x'] = pos.x, ['y'] = pos.y - 1, ['z'] = pos.z}
		local node = minetest.get_node(node_pos)
		if slopeslib.update_shape(node_pos, node) then
			return true, 'Shape updated.'
		end
		return false, node.name .. " cannot have it's shape updated."
	end,
})

-- On generation big update
local function register_on_generation()
	if not slopeslib._register_on_generated then
		return
	end
	if slopeslib.setting_enable_shape_on_generation() then
		if slopeslib.setting_generation_method() == "Progressive" then
			minetest.register_on_generated(function(minp, maxp, seed)
				slopeslib.register_progressive_area_update(minp, maxp, slopeslib.setting_generation_factor(), slopeslib.setting_generation_skip(), "mapgen")
			end)
		else
			minetest.register_on_generated(function(minp, maxp, seed)
				slopeslib.area_chance_update_shape(minp, maxp, slopeslib.setting_generation_factor(), slopeslib.setting_generation_skip(), true, "mapgen")
			end)
		end
	end
end
minetest.register_on_mods_loaded(register_on_generation)

--- On place neighbor update
local function on_place_or_dig(pos, force_below)
	local function update(pos, x, y, z, factor)
		local new_pos = vector.add(pos, vector.new(x, y, z))
		slopeslib.chance_update_shape(new_pos, minetest.get_node(new_pos), factor, "place")
	end
	-- Update 8 neighbors plus above and below
	local place_factor = slopeslib.setting_dig_place_factor()
	update(pos, 0, 0, 0, place_factor)
	update(pos, 1, 0, 0, place_factor)
	update(pos, 0, 0, 1, place_factor)
	update(pos, -1, 0, 0, place_factor)
	update(pos, 0, 0, -1, place_factor)
	update(pos, 1, 0, 1, place_factor)
	update(pos, 1, 0, -1, place_factor)
	update(pos, -1, 0, 1, place_factor)
	update(pos, -1, 0, -1, place_factor)
	if force_below then update(pos, 0, -1, 0, 0)
	else update(pos, 0, -1, 0, place_factor)
	end
	update(pos, 0, 1, 0, place_factor)
end

if slopeslib.setting_enable_shape_on_dig_place() then
	minetest.register_on_placenode(function(pos, new_node, placer, old_node, item_stack, pointed_thing)
		on_place_or_dig(pos, true)
	end)
	minetest.register_on_dignode(function(pos, old_node, digger)
		on_place_or_dig(pos)
	end)
end

