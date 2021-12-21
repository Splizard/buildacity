minetest.register_node("city:tree_a", {
    description = "Tree",
    tiles = city.load_material("city", "city_tree_a.mtl"),
    drawtype = "mesh",
    paramtype = "light",
    mesh = "city_tree_a.obj",
    groups = {replaceable=1},
    pointable = false,
})