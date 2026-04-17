--Load the guide from the file.
local guide_file = io.open(minetest.get_modpath("builda").."/guide.txt", "r")
local guide = ""
if guide_file then
    guide = guide_file:read("*a")
    guide_file:close()
else
    minetest.log("error", "[builda] could not load guide.txt")
end

city.guide = function(player)
    local name = player:get_player_name()
    if name == "singleplayer" then
        name = "builda"
    end

    --replace [name] with the player's name
    local text = guide:gsub("%[name%]", name)

    return "size[8,7.2,false]"..
        "hypertext[0.5,0;4.75,8.5;guide;"..text.."]"..
        "image[4.5,0.2;4,8;builda_guide.png]"..
        "button_exit[1.3,6.2;1.5,0.8;close;OK]"
end

minetest.register_on_joinplayer(function(player)
    local name = player:get_player_name()
    minetest.after(1, function(player_name)
        local player = minetest.get_player_by_name(player_name)
        if player then
            minetest.show_formspec(player_name, "builda:guide", city.guide(player))
        end
    end, name)
end)
