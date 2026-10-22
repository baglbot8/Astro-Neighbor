extends RefCounted
## Tinker Workshop - Bolt's set (docs/SETS_SPEC.md 2-3). Columns: id, name, category, rarity, price, footprint,
## icon_color, desc. Footprints must equal each scene's DecoItem.footprint.
const SET := {"id": "tinker", "name": "Tinker Workshop", "neighbour": "bolt",
	"blurb": "Brass, bolts and a place to fix things. Bolt's favourite kind of mess.",
	"outfit": ["suit_gearworks", "hat_tinker_goggles"]}
const PIECES: Array = [
	["tinker_gear_stool", "Gear Stool", "furniture", "common", 300, 0.45, "#d9a24a",
		"A big brass cog with a cushion on top. It turns a little when you sit."],
	["tinker_oilcan_lamp", "Oil-Can Lamp", "lights", "common", 360, 0.45, "#e08a3a",
		"An old oil can with a warm bulb where the spout was."],
	["tinker_tool_rack", "Tool Rack", "furniture", "uncommon", 950, 0.6, "#8f9aa8",
		"Every spanner has its own hook. Bolt checks."],
	["tinker_workbench", "Tinker Workbench", "furniture", "uncommon", 1200, 0.9, "#b8875a",
		"A sturdy bench with a vice, a lamp and one bolt that never gets used."],
	["tinker_cog_clock", "Cog Clock", "fun", "uncommon", 1400, 0.5, "#d9a24a",
		"All its gears show. Watching it tick is the whole point."],
	["tinker_spring_sofa", "Spring Sofa", "furniture", "rare", 2800, 0.95, "#c9805e",
		"Sits on four big springs. Every sit is a small bounce."],
]
const BONUS: Array = ["tinker_helper_arm", "Helper Arm", "tech", "legendary", 0, 0.55, "#e08a3a",
	"A little robot arm that sorts bolts all day. Bolt built it just for you."]
