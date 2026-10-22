extends RefCounted
## Glowshroom Hollow - Zorp's set (docs/SETS_SPEC.md 2-3). Same columns as set_tinker.gd.
const SET := {"id": "glowshroom", "name": "Glowshroom Hollow", "neighbour": "zorp",
	"blurb": "Soft caps and blue glow, straight from Zorp's hollow.",
	"outfit": ["suit_glowshroom", "hat_toadstool"]}
const PIECES: Array = [
	["glowshroom_puff_pouf", "Puffball Pouf", "furniture", "common", 280, 0.45, "#b8a3e0",
		"A puffball mushroom, just right for sitting. It sighs a little."],
	["glowshroom_spore_lantern", "Spore Lantern", "lights", "common", 380, 0.4, "#7fd0ff",
		"A jar of glowing spores. They drift up, then drift back down."],
	["glowshroom_river_table", "River-Stone Table", "furniture", "uncommon", 1000, 0.8, "#8f8ac0",
		"A flat river stone with a thin blue stream painted through it."],
	["glowshroom_crystal_shelf", "Crystal Shelf", "furniture", "uncommon", 1300, 0.6, "#a58fe0",
		"Mushroom-cap shelves holding little glowing crystals."],
	["glowshroom_toadstool_lamp", "Toadstool Floor Lamp", "lights", "uncommon", 1500, 0.5, "#9f7fe0",
		"A tall spotted toadstool. Its cap lights up after dark."],
	["glowshroom_glow_pool", "Glow Pool", "fun", "rare", 3000, 1.0, "#6fc3ff",
		"A small round pool of glowing blue water, ringed with caps."],
]
const BONUS: Array = ["glowshroom_daybed", "Glowshroom Daybed", "furniture", "legendary", 0, 1.1, "#b8a3e0",
	"A bed under a giant glowing cap. Zorp says it is the best nap in the system."]
