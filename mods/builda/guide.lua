--Load the guide from the file.
local guide = io.open(minetest.get_modpath("builda").."/guide.txt", "r"):read("a")

city.guide = function(player)
    local name = player:get_player_name()
    if name == "singleplayer" then
        name = "builda"
    end

    --replace [name] with the player's name
    guide = guide:gsub("%[name%]", name)

    player:set_inventory_formspec(
        "size[8,7.2,false]"..
        "hypertext[0.5,0;4.75,8.5;guide;"..guide.."]"..
        "image[4.5,0.2;4,8;builda_guide.png]"..
        "button_exit[1.3,6.2;1.5,0.8;close;OK]"
    )
end

minetest.register_on_joinplayer(city.guide)