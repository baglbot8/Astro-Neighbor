extends RefCounted
## Long Dusk - Fen's set (docs/SETS_SPEC.md 2-3). Same columns as set_tinker.gd.
const SET := {"id": "long_dusk", "name": "Long Dusk", "neighbour": "fen",
	"blurb": "Warm clay and woven bands, for a sun that never climbs high.",
	"outfit": ["suit_long_dusk", "hat_dusk_sunhat"]}
const PIECES: Array = [
	["long_dusk_clay_pots", "Clay Pot Pair", "plants", "common", 320, 0.5, "#c8754e",
		"Two round clay pots. One tall, one short, both happy."],
	["long_dusk_woven_mat", "Woven Mat", "furniture", "common", 340, 1.0, "#d9a067",
		"A long mat woven in sunset stripes. Good for lying in the low sun."],
	["long_dusk_lantern", "Dusk Lantern", "lights", "uncommon", 900, 0.45, "#e8a85c",
		"A clay lantern full of little holes. It spills dots of light."],
	["long_dusk_bench", "Terracotta Bench", "furniture", "uncommon", 1100, 0.85, "#c8754e",
		"A low curved bench of warm clay, with a woven seat."],
	["long_dusk_lounger", "Sun Lounger", "furniture", "uncommon", 1450, 0.9, "#6f86a8",
		"Lean back and watch the sun not move. Fen does this for hours."],
	["long_dusk_parasol", "Sunset Parasol", "furniture", "rare", 2600, 1.0, "#e0885c",
		"A wide striped parasol over a little clay table."],
]
const BONUS: Array = ["long_dusk_sundial", "Long-Shadow Sundial", "fun", "legendary", 0, 0.6, "#d9a067",
	"Its shadow always points to dusk. Fen says that is the right time."]
