minetest.register_node("city:coal_mine", {
    drawtype = "mesh",
    mesh = "city_coal_mine.obj",
    tiles = city.load_material("city", "city_coal_mine.mtl"),
    paramtype = "light",
    paramtype2 = "colorfacedir",
})