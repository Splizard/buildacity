--[[
    Build a City
    Copyright (C) 2021 Quentin Quaadgras

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
]]

local S = minetest.get_translator("city")

local models_path = minetest.get_modpath("city") .. "/models/"

city.buildings = {}
city.buildings_by_width = {}

minetest.register_node("city:space", {
    drawtype = "airlike",
    paramtype = "light",
    sunlight_propagates = true,
})

--city.build builds a random kind building at position pos
--if builder is provided, acts like place_node.
function city.build(kind, pos, builder) 
    if minetest.get_item_group(minetest.get_node({x=pos.x, y=pos.y-1, z=pos.z}).name, "ground") == 0 then
        return false
    end
    if minetest.get_node(pos).name ~= "air" then
        return false
    end

    local building = city.buildings[kind][math.random(1, #city.buildings[kind])]

    if builder then
        if minetest.is_protected(pos, builder:get_player_name()) then
            minetest.record_protection_violation(pos, builder:get_player_name())
            return false
        end
    end

    local param2 = 0
    local road = city.get_road_near(pos, builder:get_pos())
    local dir = vector.subtract(pos, road)
    if road then
        param2 = minetest.dir_to_facedir(dir)
    end

    --If the building has a width greater than one, we need to check
    --that the nodes to the right (taking into account param2) 
    --are empty so that this building will fit. If it doesn't fit,  
    --we need to select a different building.
    local width = minetest.get_item_group(building, "width")
    while width and width > 1 do
        local left = vector.add(pos, {x=-dir.z, y=dir.y, z=dir.x})
        local node_right = minetest.get_node(vector.subtract(pos, {x=-dir.z, y=dir.y, z=dir.x}))
        local node_left = minetest.get_node(left)

        if node_right.name ~= "air" then
            if node_left.name == "air" then 
                pos = left --move left
                break
            else
                --change the building to a random width 1 building.
                building = city.buildings_by_width[kind][width-1][math.random(1, #city.buildings_by_width[kind][width-1])]
                width = minetest.get_item_group(building, "width")
            end
        else
            break
        end
    end

    minetest.set_node(pos, {name = building, param2 = param2})
    return true
end

--[[
    city.register_building registers a new building 
    {
        mesh = "meshname.obj",
        cost = 1,                -- construction cost.
        width = 1,               -- width of the building in blocks.
        kind = "house",          -- house/office/factory/store/etc.
        self_sufficient = false, -- if true, the building does not require energy.
    }
]]--
function city.register_building(name, def)
    local kind = def.kind or ""
    local width = def.width or 1
    if not city.buildings[kind] then
        city.buildings[kind] = {}
    end
    if not city.buildings_by_width[kind] then
        city.buildings_by_width[kind] = {}
    end
    if not city.buildings_by_width[kind][width] then
        city.buildings_by_width[kind][width] = {}
    end
    table.insert(city.buildings[kind], name)
    table.insert(city.buildings_by_width[kind][width], name)

    local node_def = {
        mesh = def.mesh..".obj",
        drawtype = "mesh",
        paramtype = "light",
        paramtype2 = "facedir",
        groups = {
            flammable = 1,
            cost = def.cost or 1,
            width = def.width,
        },
        node_placement_prediction = "",
    }

    --open the mtl file and load the colors
    --read the Kd lines and place the colors into the tiles.
    --this works with models exported from AssetForge.
    local mtl_file = io.open(models_path..def.mesh..".mtl", "r")
    local tiles = {}
    for line in mtl_file:lines() do
        if line:sub(1,3) == "Kd " then
            local r, g, b = line:sub(4):match("(%S+) (%S+) (%S+)")
            local color = {
                r=255*r, g=255*g, b=255*b, a=255,
            }
            if line:sub(4) == "0.737 0.886 1" then
                color.window = true
            end
            table.insert(tiles, {name="city_white.png", color=color})
        end
    end
    node_def.tiles = tiles

    if def.length and def.length > 1 then
        node_def.selection_box = {
            type = "fixed",
            fixed = {
                {-0.5, -0.5, -0.5, -0.5+1*def.length, 0.5, 0.5},
            },
        }
        node_def.collision_box = {
            type = "fixed",
            fixed = {
                {-0.5, -0.5, -0.5, -0.5+1*def.length, 0.5, 0.5},
            },
        }
    end

    if not def.self_sufficient then
        local decayed_node_def = table.copy(node_def)

        --replace lit windows with dark windows
        for i,v in ipairs(decayed_node_def.tiles) do
            if v.color.window then
                decayed_node_def.tiles[i].color = 0xFF1D2222
            end
        end

        node_def.on_timer = function(pos, elapsed)
            minetest.set_node(pos, {name = name.."_decayed", param2 = minetest.get_node(pos).param2})
        end

        minetest.register_node(name.."_decayed", decayed_node_def)
    end

    --setup a node timer that will decay the building
    --after a random amount of time.
    node_def.on_construct = function(pos, placer, itemstack, pointed_thing)
        minetest.get_node_timer(pos):start(math.random(1, 60))

        if width > 1 then
            local dir = minetest.facedir_to_dir(minetest.get_node(pos).param2)
            minetest.set_node(vector.subtract(pos, {x=-dir.z, y=dir.y, z=dir.x}), {name = "city:space"})
        end
    end

    node_def.on_destruct = function(pos)
        if width > 1 then
            local dir = minetest.facedir_to_dir(minetest.get_node(pos).param2)
            minetest.set_node(vector.subtract(pos, {x=-dir.z, y=dir.y, z=dir.x}), {name = "air"})
        end
    end

    minetest.register_node(name, node_def)
end

city.register_building("city:house_long_a", {
    mesh = "city_house_long_a",
    width = 2,
    self_sufficient = true,
    kind = "house",
})
city.register_building("city:house_a", {mesh = "city_house_a", kind = "house"})
city.register_building("city:house_b", {mesh = "city_house_b", kind = "house"})
city.register_building("city:house_c", {mesh = "city_house_c", kind = "house"})