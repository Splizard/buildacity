local cars = {}

minetest.register_on_punchnode(function (pos, node, puncher)
    table.insert(cars, {pos = pos, last_update=0})
end)

minetest.register_globalstep(function (dtime)
    for i, car in ipairs(cars) do
        local pos = car.pos

        if cars[i].last_update > 0.1 then
            --Damn, no mesh support. GG for now.
            minetest.add_particle({
                pos = pos,
                velocity = {x = 1, y = 0, z = 0},
                acceleration = {x = 0, y = 0, z = 0},
                expirationtime = 0.1,
                size = 1,
                collisiondetection = false,
                vertical = false,
                texture = "city_white.png",
            })
            pos.x = pos.x + 1*0.1
            cars[i].last_update = 0
        end

        cars[i].last_update = cars[i].last_update + dtime
       
    end
end)