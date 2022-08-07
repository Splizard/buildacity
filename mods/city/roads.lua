--[[
    Roads are an important part of any city, acting as the glue that 
    hold a city together. With multiple cities, they serve as the 
    connections that facilitate their trade and travel.

    There are two kinds of roads:

       1. Streets, these define the boundary of a city and 
          enable the placement of buildings around them.
       2. Highways, these are the roads that connect a city
          to its neighbors and serve as the primary arterial
          routes for trade and travel. They may also have
          small rural road-networks attached to them. 

    Streets are powered (because of streetlights) and require 
    energy to construct additionally, every street is associated 
    to the city it is extending. This is achieved by storing the 
    city's ID in the params of the node directly below the street.

    Each highway has it's own number and is stored in mod storage.
    This mod storage stores information about which cities are
    connected to the highway. Like streets, the ID of the highway 
    is stored in the params of the node directly below the highway. 

    All roads are interchangeable and are treated as if they were
    'raillike' however a custom raillike implementation is used 
    by Builda City in order to support meshes. FIXME should Minetest
    support raillike meshes?
]]

local S = minetest.get_translator("city")

local register_street = function(name, mesh)
    local def = {
        description = S("Street"),
        paramtype = "light",
        sunlight_propagates = false,
        is_ground_content = false,
        walkable = false,
        selection_box = {
            type = "fixed",
            fixed = {-1/2, -1/2, -1/2, 1/2, -1/2+1/16, 1/2},
        },
        collision_box = {
            type = "fixed",
            fixed = {-1/2, -1/2, -1/2, 1/2, -1/2+1/16, 1/2},
        },
        paramtype2 = "colorfacedir",
        drawtype = "mesh",
        mesh = mesh..".obj",
        tiles = city.load_material("city", mesh..".mtl"),
        connects_to = "group:street",
        groups = {
            flammable = 1, 
            street = 1,
        },
        logistics = {
            network = "city",
        },
        node_placement_prediction = "",
    }
    
    local def_lit = table.copy(def)
    def_lit.on_construct = function (pos, placer, itemstack, pointed_thing)
        minetest.set_node({x=pos.x, y=pos.y+1, z=pos.z}, {name="city:streetlight"})
    end
    def_lit.mesh = mesh.."_lit.obj"
    def_lit.tiles = city.load_material("city", mesh.."_lit.mtl")
    def_lit.groups["consumer"] = 1

    local def_gap = table.copy(def)
    def_gap.on_construct = function (pos, placer, itemstack, pointed_thing)
        minetest.set_node({x=pos.x, y=pos.y+1, z=pos.z}, {name="city:streetlight"})
    end
    def_gap.mesh = mesh..".obj"
    def_gap.tiles = city.load_material("city", mesh..".mtl")
    def_gap.groups["consumer"] = 1

    --make unlit road a bit more obvious.
    for i,v in ipairs(def.tiles) do
        if v.color.road_line  then
            def.tiles[i].color = def.tiles.asphalt
        end
    end

    minetest.register_node(name.."_off", def)
    minetest.register_node(name.."_lit", def_lit)
    minetest.register_node(name, def_gap)
end

minetest.register_node("city:streetlight", {
    drawtype = "airlike",
    paramtype = "light",
    sunlight_propagates = true,
    light_source = 10,
    pointable = false,
    walkable = false,
})

register_street("city:street", "city_road")
register_street("city:street_corner", "city_road_corner")
register_street("city:street_junction", "city_road_junction")
register_street("city:street_crossing", "city_road_crossing")

logistics.register_rail("city:street", "city:street_corner", "city:street_junction", "city:street_crossing")
logistics.register_rail("city:street_off", "city:street_corner_off", "city:street_junction_off", "city:street_crossing_off")