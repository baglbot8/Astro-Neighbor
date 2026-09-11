extends RefCounted
## Clothing catalog for Suit-Up. `Catalog` (src/autoload/catalog.gd) instantiates this at boot and
## registers every dictionary returned by `get_items()`. Format documented at the top of catalog.gd.
##
## 22 items: 17 suits, 3 hats, 2 backpack cowls. The starter `suit_white` is priced 0 ("not sold" —
## the player already owns it), so the store stocks 21. Nothing here changes what the astronaut can
## DO: the backpacks are cosmetic shells over the thruster pack every astronaut already wears
## (docs/STYLE_GUIDE.md R2.8), and their copy says so.
##
## COLOUR BLOCKING (docs/STYLE_GUIDE.md "Character rules"): every suit pairs a `suit_color` with an
## `accent_color` that differs in BOTH hue and value. On the astronaut model the accent paints the
## boots, the mittens, the collar ring, the chest placket and the helmet rim — that is a genuine
## second colour zone covering roughly a third of the silhouette, not piping. A near-white suit with
## only thin trim reads as a blank blob at gameplay distance, so no suit here is monochrome.

## `style` keys are merged into GameState.player_style by the shop flow (src/hub/buildings/clothes_store.gd).
## Columns: id, name, category, rarity, price, suit_color, accent_color, visor_tint, description.
const SUITS: Array = [
	["suit_white", "Astro Standard", "suit", "common", 0, "#f4f4f8", "#ff7a59", "#6fc3ff",
		"The suit you launched in. Comfy, slightly scuffed, entirely yours."],
	["suit_moon_milk", "Moon Milk Suit", "suit", "common", 220, "#f1ece0", "#6f9fe0", "#8fd8ff",
		"Soft as the inside of a cloud, with cornflower cuffs and boots."],
	["suit_comet", "Comet Suit", "suit", "common", 300, "#e6e9f0", "#f4633c", "#7fd8ff",
		"Ice-white with a burning orange tail. Goes fast standing still."],
	["suit_lunar_ranger", "Lunar Ranger Suit", "suit", "common", 340, "#c8d1de", "#e0642f", "#a8e0ff",
		"Standard issue for moon patrol. The orange half is so they can find you."],
	["suit_peach_fizz", "Peach Fizz Suit", "suit", "common", 380, "#f2b295", "#3f77ad", "#bfe8ff",
		"Sunset peach with deep harbour-blue boots. Smells faintly of soda."],
	["suit_meadow", "Meadow Suit", "suit", "common", 420, "#68b56c", "#f3e2a4", "#c8f0d8",
		"Homesick green with buttercup trim. Grass stains not included."],
	["suit_cocoa", "Cosmic Cocoa Suit", "suit", "uncommon", 470, "#8a5f47", "#ffd28a", "#ffd9a8",
		"Warm cocoa brown, whipped-cream collar. Best worn at 3 a.m."],
	["suit_mint_cadet", "Mint Cadet Suit", "suit", "uncommon", 510, "#6fcfb2", "#33436f", "#a8ffe8",
		"Cadet mint over navy boots. Very academy, very tidy."],
	["suit_bubblegum", "Bubblegum Suit", "suit", "uncommon", 540, "#e88bab", "#3fb8bd", "#ffd6f2",
		"Pink with teal mittens. Pops when you jump. Not literally."],
	["suit_rust_rover", "Rust Rover Suit", "suit", "uncommon", 580, "#b0603c", "#7fd8d0", "#ffcfa0",
		"Rover red-brown with cool mint plating. Built for dusty places."],
	["suit_nebula", "Nebula Suit", "suit", "uncommon", 640, "#5f52b8", "#f58fca", "#c2a8ff",
		"Deep violet clouded with pink. People stop and stare. Enjoy it."],
	["suit_solar_flare", "Solar Flare Suit", "suit", "rare", 720, "#eda63f", "#a83628", "#ffd07a",
		"Molten gold with ember boots. Runs about two degrees too warm."],
	["suit_aurora", "Aurora Suit", "suit", "rare", 790, "#4fbcca", "#a45fd0", "#9ff0ff",
		"Ribbons of polar green-blue with a violet hem. Shimmers when you turn."],
	["suit_deep_space", "Deep Space Suit", "suit", "rare", 880, "#2e3760", "#ffc94d", "#ffe9a8",
		"Midnight navy, gold everything. The suit for very serious astronomy."],
	["suit_gearworks", "Gearworks Suit", "suit", "rare", 960, "#5a6472", "#e08a3a", "#cfe4ff",
		"Bolt helped design this one. It has eleven pockets. He counted."],
	["suit_starlight_gala", "Starlight Gala Suit", "suit", "legendary", 1320, "#463a6e", "#f0dfab",
		"#ffd6f2", "Midnight velvet with champagne cuffs. Strictly for big nights."],
	["suit_void_runner", "Void Runner Suit", "suit", "legendary", 1500, "#232a3f", "#4fe0bd", "#7cffd0",
		"Black as between-the-stars, lit by a single mint seam. Very cool. Slightly smug."],
]

## Columns: id, name, category, rarity, price, style key, style value, icon colour, description.
const GEAR: Array = [
	["hat_cap", "Depot Cap", "hat", "common", 260, "hat_id", "hat_cap", "#ff7a59",
		"Pip and Pop hand these out. Pop insists the brim is 'aerodynamic'."],
	["hat_antenna", "Antenna Bobble", "hat", "uncommon", 380, "hat_id", "hat_antenna", "#7fffd4",
		"A springy antenna with a glowing bobble. Zorp approves loudly."],
	["hat_crown", "Star Crown", "hat", "legendary", 1150, "hat_id", "hat_crown", "#ffe27a",
		"Professor Comet says it is ceremonial. He wears his to watch the stars."],
	# BACKPACKS ARE COSMETIC SHELLS, and their names and copy have to say so. Every astronaut flies
	# with a working thruster pack from minute one (docs/STYLE_GUIDE.md R2.8), so a store selling a
	# "Jet Pack" with "twin thrusters that puff blue when you hop" was selling the player something
	# they already had - and implying the pack on their back was decoration (integration critic).
	# These clip OVER that pack: same lift, different silhouette.
	["pack_rocket", "Booster Cowl", "backpack", "rare", 860, "backpack_id", "pack_rocket", "#ff9f43",
		"A stubby retro cowling for your thruster pack. Flies the same. Looks louder."],
	["pack_jet", "Twin-Jet Cowl", "backpack", "legendary", 1240, "backpack_id", "pack_jet", "#7fe9ff",
		"Splits your pack's nozzle in two. Same lift, twice the swagger."],
]


## Every clothing definition, suits first (cheapest to most expensive), then hats and backpacks.
func get_items() -> Array:
	var out: Array = []
	for row: Array in SUITS:
		out.append({
			"id": row[0],
			"name": row[1],
			"kind": "clothing",
			"category": row[2],
			"rarity": row[3],
			"price": int(row[4]),
			"desc": row[8],
			"icon_color": row[5],
			"style": {
				"suit_color": row[5],
				"accent_color": row[6],
				"visor_tint": row[7],
			},
		})
	for row: Array in GEAR:
		out.append({
			"id": row[0],
			"name": row[1],
			"kind": "clothing",
			"category": row[2],
			"rarity": row[3],
			"price": int(row[4]),
			"desc": row[8],
			"icon_color": row[7],
			"style": {row[5]: row[6]},
		})
	return out
