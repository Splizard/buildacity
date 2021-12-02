--Harvesting implements the gameplay logic of Harvest the Humans.
--In this gamemode, players have energy and are required to build
--cities so that they can harvest the humans from them.

local brains_count = 1;
local energy_count = 2;

minetest.register_on_punchnode(function(pos, node, puncher, pointed_thing)
    if node.name == "city:building_full" then
        puncher:get_meta():set_int("brains", puncher:get_meta():get_int("brains") + 1);
        puncher:hud_change(brains_count, "text", puncher:get_meta():get_int("brains"))
        minetest.set_node(pos, {name = "city:building"})
        minetest.sound_play("harvesting_sound", {pos = pos, max_hear_distance = 20})
    end
end)

minetest.hud_replace_builtin("health", nil)

minetest.register_globalstep(function(dt)
    for _, player in ipairs(minetest.get_connected_players()) do
        local controls = player:get_player_control() 
        if controls.aux1 then
            player:set_physics_override({
                speed = 4,
            })
            player:get_meta():set_float("energy", player:get_meta():get_float("energy") - dt * 1)
            player:hud_change(energy_count, "text", math.floor(0.5+player:get_meta():get_float("energy")))
        else 
            player:set_physics_override({
                speed = 1,
            })
        end
    end
end)

--We need to attach the Energy and Humans HUD counts.
--Humans is top left, Energy is top right.
minetest.register_on_joinplayer(function(player)    
    --Give the player a reasonable amount of starting energy.
    if player:get_meta():contains("energy") == false then
        player:get_meta():set_float("energy", 100)
    end

    --Remove default HUD elements.
    player:hud_set_flags({healthbar=false, breathbar=false, wielditem=false})

    --Brain Icon.
    player:hud_add({
        hud_elem_type = "statbar",
        position = {x=0, y=0},
        text = "harvesting_brain.png",
        number = 2,
        size = {x=64, y=64},
        offset = {x=10, y=0},
    })
    --Brain Count
    player:hud_add({
        name = "brains",
        hud_elem_type = "text",
        position = {x=0, y=0},
        text = player:get_meta():get_int("brains"),
        number = 0xffffff,
        size = {x=3, y=3},
        offset = {x=90, y=5},
        alignment = {x=1, y=1},
    })
    --Energy Count
    player:hud_add({
        name = "energy",
        hud_elem_type = "text",
        position = {x=1, y=0},
        text = math.floor(player:get_meta():get_float("energy")+0.5),
        number = 0xffffff,
        size = {x=3, y=3},
        offset = {x=-80, y=5},
        alignment = {x=-1, y=1},
    })
    --Energy Icon
    player:hud_add({
        hud_elem_type = "statbar",
        position = {x=1, y=0},
        text = "harvesting_energy.png",
        number = 2,
        size = {x=48, y=48},
        offset = {x=-64, y=7},
    })
    

    --Setup camera, the player is a spaceship
    --and is able to fly through single-node spaces.
    player:set_properties({
        eye_height = 0.2,
        collisionbox = {-0.3, 0.0, -0.3, 0.3, 0.3, 0.3},
        visual = "mesh",
        mesh = "harvesting_ship_default.obj",
        textures = {"harvesting_ship_default.png", "harvesting_ship_default_highlight.png"},
    })
    player:set_eye_offset(nil, {x=0,y=0,z=10})
    minetest.set_player_privs(player:get_player_name(), {fly=true})


    
end)