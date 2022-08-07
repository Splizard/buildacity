local S = minetest.get_translator("city")

local update_road_lighting = function(pos)
    local top = minetest.get_node({x=pos.x, y=pos.y, z=pos.z+1})
    local bot = minetest.get_node({x=pos.x, y=pos.y, z=pos.z-1})
    local left = minetest.get_node({x=pos.x-1, y=pos.y, z=pos.z})
    local right = minetest.get_node({x=pos.x+1, y=pos.y, z=pos.z})

    top.lit = string.match(top.name, "_lit")
    bot.lit = string.match(bot.name, "_lit")
    left.lit = string.match(left.name, "_lit")
    right.lit = string.match(right.name, "_lit")

    return not (top.lit or bot.lit or left.lit or right.lit)
end

--city.disable disables the energy_source at position 'pos' and
--returns true. if the node at this pos is not an energy_source,
--this function has no effect and returns false.
function city.disable(pos) 
    local node = minetest.get_node(pos)
    if minetest.get_item_group(node.name, "energy_source") and not string.match(node.name, "city:.*_disabled") then
        minetest.set_node(pos, {name = node.name.."_disabled", param2 = node.param2})
        return true
    end
    return false
end

--city.enable enables the 'disabled' energy_source at position 'pos'
--(ie, an energy source that was disabled by city.disable) and returns true.
--if the node at this pos is not a 'disabled' energy_source, this function
--has no effect and returns false.
function city.enable(pos) 
    local node = minetest.get_node(pos)
    if string.match(node.name, "city:.*_disabled") then
        minetest.set_node(pos, {name = string.gsub(node.name, "_disabled", ""), param2 = node.param2})
        return true
    end
    return false
end

local off_suffix_len = #"_off"

function city.power(pos) 
    local node = minetest.get_node(pos)
    if string.match(node.name, "city:.*_off") then

        -- add streetlights if the node is a street.
        local suffix = ""
        if minetest.get_item_group(node.name, "street") > 0 and update_road_lighting(pos) then
            suffix = "_lit"
        end

        minetest.set_node(pos, {name = string.sub(node.name, 0, #node.name-off_suffix_len)..suffix, param2 = node.param2})
        --city.add(city.at(pos), "power_consumption")

        return true
    end
    return false
end

--[[
    Wind turbines are a bit awkward, they consist of two parts, the base and the
    blades (that spin). We need to make sure that the two nodes stay in sync.
    This means that when either nodes break, both need to break and vice-versa.
]]--

minetest.register_node("city:wind_turbine", {
    description = S("Wind Turbine"),
	inventory_image = "city_white.png",
    drawtype = "mesh",
    mesh = "city_wind_turbine.obj",
    selection_box = {
        type = "fixed",
        fixed = {-1/3, -1/2, -1/3, 1/3, 3, 1/3},
    },
    collision_box = {
        type = "fixed",
        fixed = {-1/3, -1/2, -1/3, 1/3, 3, 1/3},
    },
    paramtype = "light",
    paramtype2 = "facedir",
    groups = {flammable = 1, energy_source = 7},
    tiles = {"city_white.png"},

    on_construct = function(pos, placer, itemstack, pointed_thing)
        local dir = minetest.facedir_to_dir(minetest.get_node(pos).param2)
        local blade_pos = vector.subtract(vector.new(), dir)
        blade_pos.y = blade_pos.y + 2
        local pos = vector.add(pos, blade_pos)
        if minetest.get_node(pos).name ~= "city:wind_turbine_blade" then
            minetest.set_node(pos, {name="city:wind_turbine_blade", param2 = minetest.dir_to_wallmounted(dir)})
        end
    end
})

minetest.register_node("city:wind_turbine_blade", {
    drawtype = "signlike",
    inventory_image = "city_white.png",
    paramtype = "light",
    paramtype2 = "wallmounted",
    selection_box = {
		type = "wallmounted",
    },
    pointable = false,
    visual_scale = 2,
    sunlight_propagates = true,
    tiles = {"city_wind_turbine_blade.png"},
})


minetest.register_node("city:wind_turbine_disabled", {
    description = S("Wind Turbine"),
	inventory_image = "city_white.png",
    drawtype = "mesh",
    mesh = "city_wind_turbine.obj",
    selection_box = {
        type = "fixed",
        fixed = {-1/3, -1/2, -1/3, 1/3, 3, 1/3},
    },
    collision_box = {
        type = "fixed",
        fixed = {-1/3, -1/2, -1/3, 1/3, 3, 1/3},
    },
    paramtype = "light",
    paramtype2 = "facedir",
    groups = {flammable = 1},
    tiles = {"city_white.png"},

    on_construct = function(pos, placer, itemstack, pointed_thing)
        local dir = minetest.facedir_to_dir(minetest.get_node(pos).param2)
        local blade_pos = vector.subtract(vector.new(), dir)
        blade_pos.y = blade_pos.y + 2
        local pos = vector.add(pos, blade_pos)
        if minetest.get_node(pos).name ~= "city:wind_turbine_blade_disabled" then
            minetest.set_node(pos, {name="city:wind_turbine_blade_disabled", param2 = minetest.dir_to_wallmounted(dir)})
        end
    end
})

minetest.register_node("city:wind_turbine_blade_disabled", {
    drawtype = "signlike",
    inventory_image = "city_white.png",
    paramtype = "light",
    paramtype2 = "wallmounted",
    selection_box = {
		type = "wallmounted",
    },
    pointable = false,
    visual_scale = 2,
    sunlight_propagates = true,
    tiles = {{
        name = "city_wind_turbine_blade_spinning.png",
        animation = {
            type = "vertical_frames",
            aspect_w = 64,
            aspect_h = 64,
            length = 4,
        },
    }},
})