local S = minetest.get_translator("naturalslopes_minetest_game")

---
--- Stone slopes
---

naturalslopeslib.register_slope("default:stone", {
	description = S("Stone Slope"),
	},
	200,
	{mapgen = 0.33, place = 0.5}
)

naturalslopeslib.register_slope("default:cobble", {
	description = S("Cobblestone Slope"),
	},
	10,
	{time = 3}
)

naturalslopeslib.register_slope("default:mossycobble", {
	description = S("Mossy Cobblestone Slope"),
	},
	15,
	{time = 3}
)

naturalslopeslib.register_slope("default:desert_stone", {
	description = S("Desert Stone Slope"),
	},
	150,
	{mapgen = 0.33, place = 0.5}
)

naturalslopeslib.register_slope("default:desert_cobble", {
	description = S("Desert Cobblestone Slope"),
	},
	10,
	{time = 3}
)

naturalslopeslib.register_slope("default:sandstone", {
	description = S("Sandstone Slope"),
	},
	120,
	{mapgen = 0.33, place = 0.5}
)

naturalslopeslib.register_slope("default:desert_sandstone", {
	description = S("Desert Sandstone Slope"),
	},
	120,
	{mapgen = 0.33, place = 0.5}
)

naturalslopeslib.register_slope("default:silver_sandstone", {
	description = S("Desert Sandstone Slope"),
	},
	120,
	{mapgen = 0.33, place = 0.5}
)

naturalslopeslib.register_slope("default:obsidian", {
	description = S("Obsidian"),
	},
	500,
	{mapgen = 0.33, place = 0.5}
)

---
--- Soft / Non-Stone slopes
---

naturalslopeslib.register_slope("default:dirt", {
	description = S("Dirt Slope"),
	},
	10,
	{place = 0.5, time = 0.75}
)

naturalslopeslib.register_slope("default:dirt_with_grass", {
	description = S("Dirt with Grass Slope"),
	tiles = {"default_grass.png", "default_dirt.png",
		{name = "default_dirt.png^default_grass_side.png"}}
	},
	25
)

naturalslopeslib.register_slope("default:dirt_with_dry_grass", {
	description = S("Dirt with Dry Grass Slope"),
	tiles = {"default_grass.png", "default_dirt.png",
		{name = "default_dirt.png^default_grass_side.png"}}
	},
	20
)

naturalslopeslib.register_slope("default:dirt_with_snow", {
	description = S("Dirt with Snow Slope"),
	tiles = {"default_snow.png", "default_dirt.png",
		{name = "default_dirt.png^default_snow_side.png"}}
	},
	25
)

naturalslopeslib.register_slope("default:dirt_with_rainforest_litter", {
	description = S("Dirt with Rainforest Litter Slope"),
	tiles = {
		"default_rainforest_litter.png",
		"default_dirt.png",
		{name = "default_dirt.png^default_rainforest_litter_side.png"}}
	},
	15
)

naturalslopeslib.register_slope("default:dirt_with_coniferous_litter", {
	description = S("Dirt with Coniferous Litter Slope"),
	tiles = {
		"default_coniferous_litter.png",
		"default_dirt.png",
		{name = "default_dirt.png^default_coniferous_litter_side.png"}}
	},
	15
)

naturalslopeslib.register_slope("default:dry_dirt", {
	description = S("Savanna Dirt Slope"),
	},
	6,
	{place = 0.5, time = 0.5}
)

naturalslopeslib.register_slope("default:dry_dirt_with_dry_grass", {
	description = S("Savanna Dirt with Savanna Grass Slope"),
	tiles = {"default_dry_grass.png", "default_dry_dirt.png",
		{name = "default_dry_dirt.png^default_dry_grass_side.png"}}
	},
	20
)

naturalslopeslib.register_slope("default:permafrost", {
	description = S("Permafrost Slope"),
	},
	30
)

naturalslopeslib.register_slope("default:permafrost_with_stones", {
	description = S("Permafrost with Stones Slope"),
	},
	30
)

naturalslopeslib.register_slope("default:permafrost_with_moss", {
	description = S("Permafrost with Moss Slope"),
	tiles = {"default_moss.png", "default_permafrost.png",
		{name = "default_permafrost.png^default_moss_side.png"}},
	},
	30
)

naturalslopeslib.register_slope("default:sand", {
	description = S("Sand Slope"),
	},
	5,
	{mapgen = 0, place = 0, time = 0}
)
naturalslopeslib.register_slope("default:desert_sand", {
	description = S("Desert Sand Slope"),
	},
	5,
	{mapgen = 0, place = 0, time = 0}
)
naturalslopeslib.register_slope("default:silver_sand", {
	description = S("Silver Sand Slope"),
	},
	5,
	{mapgen = 0, place = 0, time = 0}
)

naturalslopeslib.register_slope("default:gravel", {
	description = S("Gravel Slope"),
	},
	7,
	{stomp = 0.5, time = 2}
)

naturalslopeslib.register_slope("default:clay", {
	description = S("Clay Slope"),
	},
	15
)

naturalslopeslib.register_slope("default:snowblock", {
	description = S("Snow Block Slope"),
	},
	4,
	{stomp = 0}
)

naturalslopeslib.register_slope("default:ice", {
	description = S("Ice Slope"),
	},
	60,
	{mapgen = 0.25}
)

naturalslopeslib.register_slope("default:cave_ice", {
	description = S("Cave Ice Slope"),
	},
	60,
	{mapgen = 0.25}
)

---
--- Trees
---

naturalslopeslib.register_slope("default:leaves", {
	description = S("Apple Tree Leaves Slope"),
	},
	2,
	{stomp = 6}
)

naturalslopeslib.register_slope("default:jungleleaves", {
	description = S("Jungle Tree Leaves Slope"),
	},
	2,
	{stomp = 6}
)

naturalslopeslib.register_slope("default:pine_needles", {
	description = S("Pine Needles Slope"),
	},
	2,
	{stomp = 6}
)

naturalslopeslib.register_slope("default:acacia_leaves", {
	description = S("Acacia Tree Leaves Slope"),
	},
	2,
	{stomp = 6}
)

naturalslopeslib.register_slope("default:aspen_leaves", {
	description = S("Aspen Tree Leaves Slope"),
	},
	2,
	{stomp = 6}
)


---
--- Plantlife
---

naturalslopeslib.register_slope("default:bush_leaves", {
	description = S("Bush Leaves Slope"),
	},
	2,
	{stomp = 6}
)

naturalslopeslib.register_slope("default:blueberry_bush_leaves_with_berries", {
	description = S("Blueberry Bush Leaves with Berries Slope"),
	},
	2,
	{stomp = 6}
)

naturalslopeslib.register_slope("default:blueberry_bush_leaves", {
	description = S("Blueberry Bush Leaves Slope"),
	},
	2,
	{stomp = 6}
)

naturalslopeslib.register_slope("default:acacia_bush_leaves", {
	description = S("Acacia Bush Leaves Slope"),
	},
	2,
	{stomp = 6}
)

naturalslopeslib.register_slope("default:pine_bush_needles", {
	description = S("Pine Bush Needles Slope"),
	},
	2,
	{stomp = 6}
)
