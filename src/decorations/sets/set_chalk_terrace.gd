extends RefCounted
## Chalk Terrace - Grig's set (docs/SETS_SPEC.md 2-3). Same columns as set_tinker.gd.
const SET := {"id": "chalk_terrace", "name": "Chalk Terrace", "neighbour": "grig",
	"blurb": "Stacked stone and carved steps, cut from Grig's chalk stairs.",
	"outfit": ["suit_chalk_terrace", "hat_chalk_headlamp"]}
const PIECES: Array = [
	["chalk_terrace_step_stool", "Step Stool", "furniture", "common", 260, 0.45, "#e3d8bc",
		"Three little chalk steps. Sit on any of them."],
	["chalk_terrace_planter", "Terrace Planter", "plants", "common", 350, 0.55, "#9fb08a",
		"A stepped stone box with tough little scrub plants."],
	["chalk_terrace_pillar_lamp", "Pillar Lamp", "lights", "uncommon", 1050, 0.45, "#e8dcb8",
		"A carved chalk pillar with a warm light in its top."],
	["chalk_terrace_stair_shelf", "Stair Shelf", "furniture", "uncommon", 1250, 0.65, "#d8cba4",
		"A shelf shaped like a staircase. Things go up, one step at a time."],
	["chalk_terrace_table", "Carved Stone Table", "furniture", "uncommon", 1550, 0.85, "#d8cba4",
		"A heavy stone table with grooves carved round its edge."],
	["chalk_terrace_basin", "Rock Basin Fountain", "fun", "rare", 3200, 0.9, "#a8c4c0",
		"Water steps down three stone bowls, very slowly."],
]
const BONUS: Array = ["chalk_terrace_arch", "Terrace Arch", "signs", "legendary", 0, 1.1, "#e3d8bc",
	"A carved stone arch. Grig says every good place needs a door with no wall."]
