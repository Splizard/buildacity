local function use_shape(itemstack, user, pointed_thing)
	local tool_def = itemstack:get_definition()
	local node_pos = minetest.get_pointed_thing_position(pointed_thing, false)
	local node = minetest.get_node(node_pos)
	local node_def = minetest.registered_nodes[node.name]
	local dig_params = minetest.get_dig_params(node_def.groups, tool_def.tool_capabilities)
	if not dig_params.diggable then
		return itemstack
	end
	local chance = 1.0 / (dig_params.time * 2.0)
	local success = (chance >= 1.0 or math.random() < chance)
	if success then
		local changed = naturalslopeslib.update_shape(node_pos, node)
		if node_def.sounds.dug then
			minetest.sound_play(node_def.sounds.dug, {pos = node_pos}, true)
		end
		if changed then
			itemstack:add_wear(math.ceil(dig_params.wear / 4.0))
		end
	else
		if node_def.sounds.dig then
			minetest.sound_play(node_def.sounds.dig, {to_player = user:get_player_name()}, true)
		elseif node_def.sounds.dug then
			minetest.sound_play(node_def.sounds.dug, {to_player = user:get_player_name()}, true)
		end
	end
	return itemstack
end

local shaper_tools = {"default:pick_wood", "default:pick_stone", "default:pick_bronze",
"default:pick_steel", "default:pick_mese", "default:pick_diamond",
"default:shovel_wood", "default:shovel_stone", "default:shovel_bronze", "default:shovel_steel",
"default:shovel_mese", "default:shovel_diamond",
"default:axe_wood", "default:axe_stone", "default:axe_bronze", "default:axe_steel", "default:axe_mese",
"default:axe_diamond",
"default:sword_wood", "default:sword_stone", "default:sword_bronze", "default:sword_steel",
 "default:sword_mese", "default:sword_diamond"}

for _, tool in ipairs(shaper_tools) do
	minetest.override_item(tool, {
		on_place = use_shape
	})
end
