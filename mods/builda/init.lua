--builda implements the gameplay logic of Builda City.
--In this gamemode, players have energy and are required to build
--cities so that they can collect coins and profit from the global
--energy supply infrastructure.

local S = minetest.get_translator("builda")

local coins_count = 1;
local energy_count = 2;

local AddPlayerEnergy = function(player, energy)
    player:get_meta():set_float("energy", player:get_meta():get_float("energy")+energy)
    player:hud_change(energy_count, "text", math.floor(0.5+player:get_meta():get_float("energy")))
    if player:get_meta():get_float("energy") < 0 then
        player:set_hp(0, "out of energy")
    end
end

--returns true if the player can afford.
local AddPlayerCoins = function(player, coins)
    player:get_meta():set_int("coins", player:get_meta():get_int("coins") + coins);
    if player:get_meta():get_int("coins") < 0 then
        player:get_meta():set_int("coins", player:get_meta():get_int("coins")-coins)
        return false
    end
    player:hud_change(coins_count, "text", player:get_meta():get_int("coins"))
    return true
end

local PlayerCanAfford = function(player, coins)
    return player:get_meta():get_int("coins") >= coins
end

local decayed_suffix_len = #"_decayed"
local broken_suffix_len = #"_broken"


minetest.register_on_punchnode(function(pos, node, puncher, pointed_thing)
    if string.match(node.name, "city:.*_decayed") then
        local income = 1
        if string.match(node.name,"house") then
            income = 2
        end
        if string.match(node.name,"skyscraper") then
            income = 10
        end
        local height = minetest.get_item_group(node.name, "height")
        if height == 0 then
            height = 1
        end
        AddPlayerCoins(puncher, income)
        minetest.set_node(pos, {name = string.sub(node.name, 0, #node.name-decayed_suffix_len), param2 = node.param2})
        minetest.sound_play("builda_income", {pos = pos, max_hear_distance = 20})
        minetest.add_particle({
            pos={x=pos.x, y=pos.y-(2.9-height), z=pos.z},
            velocity={x=0, y=16, z=0},
            acceleration={x=0,y=-42,z=0},
            texture = "builda_coin.png",
            size = 8,
            playername = puncher:get_player_name(),
        })
        AddPlayerEnergy(puncher, -1)
    end
    local energy = minetest.get_item_group(node.name, "energy_source")
    if energy > 0 then
        if node.name == "city:wind_turbine" then 
            energy = energy * (pos.y-8) --energy is proportional to height (wind)
        end
        minetest.after(1, function(energy)
            if city.disable(pos) then
                AddPlayerEnergy(puncher, energy)
            end
        end, energy)
        minetest.sound_play("builda_charge", {pos = pos, max_hear_distance = 20})
    end
    if string.match(node.name, "city:.*_disabled") then
        minetest.sound_play("builda_broken", {pos = pos, max_hear_distance = 20})
        minetest.add_particlespawner({
            amount = 20,
            time = 0.3,
            minpos={x=pos.x-0.5, y=pos.y-0.5, z=pos.z-0.5},
            maxpos={x=pos.x+0.5, y=pos.y-0.5, z=pos.z+0.5},
            minvel={x=-4, y=2, z=-4},
            maxvel={x=4, y=4, z=4},
            texture = "builda_energy.png",
            minsize = 1,
            maxsize = 1,
            minexptime = 0.2,
            maxexptime = 0.2,
        })
    end
end)

minetest.hud_replace_builtin("health", nil)

minetest.register_globalstep(function(dt)
    for _, player in ipairs(minetest.get_connected_players()) do
        if player:get_hp() > 0 then
            local controls = player:get_player_control() 
            if controls.aux1 and player:get_meta():get_float("energy") > 0 then --Speed boost costs energy.
                player:set_physics_override({
                    speed = 4,
                })
                AddPlayerEnergy(player,  - dt * 1)
            else 
                player:set_physics_override({
                    speed = 1,
                })
            end
        end
    end
end)

minetest.item_drop = function() end

minetest.is_protected = function(pos, name)

    --Nodes can only be placed next to existing roads.
    local top = minetest.get_node({x=pos.x, y=pos.y, z=pos.z+1})
    local bot = minetest.get_node({x=pos.x, y=pos.y, z=pos.z-1})
    local left = minetest.get_node({x=pos.x-1, y=pos.y, z=pos.z})
    local right = minetest.get_node({x=pos.x+1, y=pos.y, z=pos.z})

    if string.match(top.name, "city:road.*") then 
        return false
    end
    if string.match(bot.name, "city:road.*") then 
        return false
    end
    if string.match(left.name, "city:road.*") then 
        return false
    end
    if string.match(right.name, "city:road.*") then 
        return false
    end

    return true
end

minetest.register_on_placenode(function(pos, newnode, placer, oldnode, itemstack, pointed_thing)
    if string.match(newnode.name, "city:road.*") then
        AddPlayerEnergy(placer, -2)
    end
    return true -- we don't have an inventory in this game, so we never remove items from the hotbar.
end)

minetest.register_item(":", {
    type = "none",
    range = 10,
})

minetest.register_on_respawnplayer(function(player)
    player:get_meta():set_int("coins", 0);
    player:hud_change(coins_count, "text", 0)
    AddPlayerEnergy(player, (-player:get_meta():get_int("energy"))+5)
end)

--We need to attach the Energy and Humans HUD counts.
--Humans is top left, Energy is top right.
minetest.register_on_joinplayer(function(player)    
    --Give the player a reasonable amount of starting energy.
    if player:get_meta():contains("energy") == false then
        player:get_meta():set_float("energy", 100)
    end

    local list = {
        "city:road 1",
        "builda:house 1",
        "builda:skyscraper 1",
        "builda:coins 1",
        "builda:destroyer 1", 
    }

    --Initialise the buildbar (hotbar).
    player:get_inventory():set_list("main", list)
    player:hud_set_hotbar_itemcount(#list)

    --Remove default HUD elements.
    player:hud_set_flags({healthbar=false, breathbar=false, wielditem=false})
    player:hud_set_hotbar_image("builda_empty.png")

    --Brain Icon.
    player:hud_add({
        hud_elem_type = "statbar",
        position = {x=1, y=0},
        text = "builda_coin.png",
        number = 2,
        size = {x=64, y=64},
        offset = {x=-64-10, y=0},
    })
    --Brain Count
    player:hud_add({
        name = "coins",
        hud_elem_type = "text",
        position = {x=1, y=0},
        text = player:get_meta():get_int("coins"),
        number = 0xffffff,
        size = {x=3, y=3},
        offset = {x=-90, y=5},
        alignment = {x=-1, y=1},
    })
    --Energy Count
    player:hud_add({
        name = "energy",
        hud_elem_type = "text",
        position = {x=1, y=0},
        text = math.floor(player:get_meta():get_float("energy")+0.5),
        number = 0xffffff,
        size = {x=3, y=3},
        offset = {x=-80, y=64+5},
        alignment = {x=-1, y=1},
    })
    --Energy Icon
    player:hud_add({
        hud_elem_type = "statbar",
        position = {x=1, y=0},
        text = "builda_energy.png",
        number = 2,
        size = {x=48, y=48},
        offset = {x=-64, y=64+7},
    })
    

    --Setup camera, the player is inside an energy distrubution craft
    --and is able to fly through single-node spaces.
    player:set_properties({
        eye_height = 0.2,
        collisionbox = {-0.3, 0.0, -0.3, 0.3, 0.3, 0.3},
        visual = "mesh",
        mesh = "builda_craft_default.obj",
        textures = {"builda_craft_default.png", "builda_craft_default_highlight.png"},
    })
    player:set_eye_offset(nil, {x=0,y=0,z=10})
    local name = player:get_player_name()
    local privs = minetest.get_player_privs(name)
    privs.fly = true
    minetest.set_player_privs(name, privs)
    
end)

--micromap.
minetest.register_on_mapgen_init(function()
    minetest.set_mapgen_setting("mg_name", "flat", true)
    minetest.set_mapgen_setting("mg_flags", "noores,nocaves,nodungeons,light,decorations,biomes", true)
    minetest.set_mapgen_setting("mgflat_spflags", "hills,lakes,nocaverns", true)
    minetest.set_mapgen_setting("water_level", "8", true)

    local seed = math.random(0, 2^32-1)
    local existing = minetest.get_mapgen_setting_noiseparams("mgflat_np_terrain")
    if existing then
        seed = existing.seed
    end

    minetest.set_mapgen_setting_noiseparams("mgflat_np_terrain", {
        flags = "defaults",
        lacunarity = 2,
        persistence = 0.6,
        seed = seed,
        spread = {x=120,y=120,z=120},
        scale = 1,
        octaves = 5,
        offset = 0,
    }, true)

    minetest.set_mapgen_setting("mgflat_hill_threshold", "0.3", true)
    minetest.set_mapgen_setting("mgflat_hill_steepness", "10", true)
    minetest.set_mapgen_setting("mgflat_lake_threshold", "0", true)
end)

--Wind turbines provided by BigPowerCorp.
--They only spawn on hills (we assume flat mapgen from polymap).
minetest.register_decoration({
    name = "builda:wind_turbine",
    deco_type = "schematic",
    place_on = {"polymap:grass"},
    sidelen = 2,
    noise_params = {
        offset = 0,
        scale = 0.005,
        spread = {x = 50, y = 50, z = 50},
        seed = 354,
        octaves = 3,
        persist = 0.5
    },
    biomes = {"grassland"},
    y_max = 31000,
    y_min = 9,
    height = 4,
    schematic = {
        size = {x = 1, y = 4, z = 2},
        data = {
            {name ="ignore"}, {name = "city:wind_turbine", param2 = 2},
            {name ="ignore"}, {name ="ignore"}, 
            {name ="ignore"}, {name ="ignore"},
            {name = "ignore"}, {name ="city:wind_turbine_blade", param2 = 5},
        },
    },
    flags = "force_placement",
})

--Roads are starting points, where a player can start building from.
minetest.register_decoration({
    name = "builda:road",
    deco_type = "simple",
    place_on = {"polymap:grass"},
    fill_ratio = 0.0005,
    biomes = {"grassland"},
    y_max = 8,
    y_min = 0,
    decoration = "city:road",
})

--Spanner is used to fix broken power sources.
minetest.register_item("builda:coins", {
    description = S("Spanner"),
    inventory_image = "builda_coin.png",
    type = "tool",
    on_place = function(itemstack, user, pointed_thing)
        if pointed_thing.type == "node" then
            local pos = pointed_thing.under
            local node = minetest.get_node(pos)
            if PlayerCanAfford(user, 5) and city.enable(pos) then
                    minetest.sound_play("builda_pay", {pos = pos, max_hear_distance = 20})
                    AddPlayerCoins(user, -5)
            else
                minetest.sound_play("builda_error", {pos = pos, max_hear_distance = 20})
            end
        end
    end
})

minetest.register_item("builda:house", {
    description = S("House"),
    inventory_image = "builda_house.png",
    type = "tool",
    on_place = function(itemstack, user, pointed_thing)
        if pointed_thing.type == "node" then
            if city.build("house", pointed_thing.above, user) then
                AddPlayerEnergy(user, -5)
            end
        end
    end
})

minetest.register_item("builda:skyscraper", {
    description = S("Skyscraper"),
    inventory_image = "builda_skyscraper.png",
    type = "tool",
    on_place = function(itemstack, user, pointed_thing)
        if pointed_thing.type == "node" then
            if city.build("skyscraper", pointed_thing.above, user) then
                AddPlayerEnergy(user, -100)
            end
        end
    end
})


--Destroyer is used to destroy built nodes such as roads and buildings.
minetest.register_item("builda:destroyer", {
    description = S("Destroyer"),
    inventory_image = "builda_destroyer.png",
    type = "tool",
    on_place = function(itemstack, user, pointed_thing)
        if pointed_thing.type == "node" then
            local pos = pointed_thing.under

            if minetest.is_protected(pos, user:get_player_name()) then
                minetest.record_protection_violation(pos, user:get_player_name())
                minetest.sound_play("builda_error", {pos = pointed_thing.below, max_hear_distance = 20})
                return
            end

            local node = minetest.get_node(pos)
            if minetest.get_item_group(node.name, "flammable") > 0 and PlayerCanAfford(user, 1) then
                AddPlayerEnergy(user, -5)
                AddPlayerCoins(user, -1)

                --'explode' the node.
                minetest.set_node(pos, {name = "air"})
                minetest.add_particlespawner({
                    amount = 10,
                    time = 0.2,
                    minpos={x=pos.x-0.5, y=pos.y-0.5, z=pos.z-0.5},
                    maxpos={x=pos.x+0.5, y=pos.y-0.5, z=pos.z+0.5},
                    minvel={x=-4, y=2, z=-4},
                    maxvel={x=4, y=4, z=4},
                    texture = "builda_craft_default.png",
                    minsize = 1,
                    maxsize = 1,
                    minexptime = 0.2,
                    maxexptime = 0.2,
                })
                minetest.sound_play("builda_explode", {pos = pos, max_hear_distance = 20})
                city.update_roads(pos)
            else
                minetest.sound_play("builda_error", {pos = pointed_thing.below, max_hear_distance = 20})
            end
        end
    end
})


local modpath = minetest.get_modpath("builda")
dofile(modpath.."/guide.lua")