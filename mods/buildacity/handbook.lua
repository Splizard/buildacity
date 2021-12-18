--Load the employee handbook from the file.
local handbook = io.open(minetest.get_modpath("buildacity").."/handbook.txt", "r"):read("a")

minetest.register_on_joinplayer(function(player)    
    local name = player:get_player_name()
    if name == "singleplayer" then
        name = "player"
    end

    --replace [name] with the player's name
    handbook = handbook:gsub("%[name%]", name)

    player:set_inventory_formspec(
        "size[8,7.2,false]"..
        "hypertext[0.5,0;4.75,8.5;handbook;"..handbook.."]"..
        "image[4.5,0.2;4,8;buildacity_handbook.png]"..
        "button_exit[1.3,6.2;1.5,0.8;close;OK]"
    )
end)