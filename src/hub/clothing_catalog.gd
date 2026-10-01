extends RefCounted
## Clothing catalog for Suit-Up. `Catalog` (src/autoload/catalog.gd) instantiates this at boot and
## registers every dictionary returned by `get_items()`. Format documented at the top of catalog.gd.
##
## 23 items: 18 suits, 3 hats, 2 backpack cowls. The starter `suit_white` and the cave's `suit_prism`
## (found once in the cave's treasure chest, src/cave/) are priced 0 ("not sold"), so the store stocks
## 21, priced in the same four tiers as decoration_catalog.gd (everyday 300-400: 4 items; most
## 800-1500: 8; rare 2400-3600: 5; showpiece 5600-7000: the crown, the twin-jet cowl and the two
## legendary suits - docs/ECONOMY_REPORT.md "Rulings", 2026-09-29). Nothing here changes what the astronaut can
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
	["suit_moon_milk", "Moon Milk Suit", "suit", "common", 300, "#f1ece0", "#6f9fe0", "#8fd8ff",
		"Soft as the inside of a cloud, with cornflower cuffs and boots."],
	["suit_comet", "Comet Suit", "suit", "common", 380, "#e6e9f0", "#f4633c", "#7fd8ff",
		"Ice-white with a burning orange tail. Goes fast standing still."],
	["suit_lunar_ranger", "Lunar Ranger Suit", "suit", "common", 400, "#c8d1de", "#e0642f", "#a8e0ff",
		"Standard issue for moon patrol. The orange half is so they can find you."],
	["suit_peach_fizz", "Peach Fizz Suit", "suit", "common", 800, "#f2b295", "#3f77ad", "#bfe8ff",
		"Sunset peach with deep harbour-blue boots. Smells faintly of soda."],
	["suit_meadow", "Meadow Suit", "suit", "common", 900, "#68b56c", "#f3e2a4", "#c8f0d8",
		"Homesick green with buttercup trim. Grass stains not included."],
	["suit_cocoa", "Cosmic Cocoa Suit", "suit", "uncommon", 1000, "#8a5f47", "#ffd28a", "#ffd9a8",
		"Warm cocoa brown, whipped-cream collar. Best worn at 3 a.m."],
	["suit_mint_cadet", "Mint Cadet Suit", "suit", "uncommon", 1100, "#6fcfb2", "#33436f", "#a8ffe8",
		"Cadet mint over navy boots. Very academy, very tidy."],
	["suit_bubblegum", "Bubblegum Suit", "suit", "uncommon", 1200, "#e88bab", "#3fb8bd", "#ffd6f2",
		"Pink with teal mittens. Pops when you jump. Not literally."],
	["suit_rust_rover", "Rust Rover Suit", "suit", "uncommon", 1300, "#b0603c", "#7fd8d0", "#ffcfa0",
		"Rover red-brown with cool mint plating. Built for dusty places."],
	["suit_nebula", "Nebula Suit", "suit", "uncommon", 1500, "#5f52b8", "#f58fca", "#c2a8ff",
		"Deep violet clouded with pink. People stop and stare. Enjoy it."],
	["suit_solar_flare", "Solar Flare Suit", "suit", "rare", 2400, "#eda63f", "#a83628", "#ffd07a",
		"Molten gold with ember boots. Runs about two degrees too warm."],
	["suit_aurora", "Aurora Suit", "suit", "rare", 2700, "#4fbcca", "#a45fd0", "#9ff0ff",
		"Ribbons of polar green-blue with a violet hem. Shimmers when you turn."],
	["suit_deep_space", "Deep Space Suit", "suit", "rare", 3200, "#2e3760", "#ffc94d", "#ffe9a8",
		"Midnight navy, gold everything. The suit for very serious astronomy."],
	["suit_gearworks", "Gearworks Suit", "suit", "rare", 3600, "#5a6472", "#e08a3a", "#cfe4ff",
		"Bolt helped design this one. It has eleven pockets. He counted."],
	["suit_starlight_gala", "Starlight Gala Suit", "suit", "legendary", 6400, "#463a6e", "#f0dfab",
		"#ffd6f2", "Midnight velvet with champagne cuffs. Strictly for big nights."],
	["suit_void_runner", "Void Runner Suit", "suit", "legendary", 7000, "#232a3f", "#4fe0bd", "#7cffd0",
		"Black as between-the-stars, lit by a single mint seam. Very cool. Slightly smug."],
	["suit_prism", "Prism Suit", "suit", "legendary", 0, "#e9e6f2", "#7d5fcf", "#b8f2ff",
		"Found in a chest deep in the cave. Pearl white, violet boots, and it catches rainbows."],
]

## Columns: id, name, category, rarity, price, style key, style value, icon colour, description.
const GEAR: Array = [
	["hat_cap", "Depot Cap", "hat", "common", 340, "hat_id", "hat_cap", "#ff7a59",
		"Pip and Pop hand these out. Pop insists the brim is 'aerodynamic'."],
	["hat_antenna", "Antenna Bobble", "hat", "uncommon", 950, "hat_id", "hat_antenna", "#7fffd4",
		"A springy antenna with a glowing bobble. Zorp approves loudly."],
	["hat_crown", "Star Crown", "hat", "legendary", 5600, "hat_id", "hat_crown", "#ffe27a",
		"Professor Comet says it is ceremonial. He wears his to watch the stars."],
	# BACKPACKS ARE COSMETIC SHELLS, and their names and copy have to say so. Every astronaut flies
	# with a working thruster pack from minute one (docs/STYLE_GUIDE.md R2.8), so a store selling a
	# "Jet Pack" with "twin thrusters that puff blue when you hop" was selling the player something
	# they already had - and implying the pack on their back was decoration (integration critic).
	# These clip OVER that pack: same lift, different silhouette.
	["pack_rocket", "Booster Cowl", "backpack", "rare", 3000, "backpack_id", "pack_rocket", "#ff9f43",
		"A stubby retro cowling for your thruster pack. Flies the same. Looks louder."],
	["pack_jet", "Twin-Jet Cowl", "backpack", "legendary", 6000, "backpack_id", "pack_jet", "#7fe9ff",
		"Splits your pack's nozzle in two. Same lift, twice the swagger."],
]


## Moss's jungle-only suits (builder J3), sold only at the stall on The Tangle. Same columns as SUITS;
## the price column is the stall price (everyday 360, most 1200, rare 2800). Colour blocking as above:
## every accent differs from its suit in both hue and value.
const JUNGLE_SUITS: Array = [
	["suit_lily_pad", "Lily Pad Suit", "suit", "common", 360, "#6aa58a", "#e6c7cf", "#c8f0dc",
		"Pond green with petal-pink cuffs. Smells a bit like rain."],
	["suit_bog_moss", "Bog Moss Suit", "suit", "uncommon", 1200, "#6b8448", "#dcb462", "#e8e0a8",
		"Soft moss green with amber boots. Moss says it's lucky."],
	["suit_swamp_night", "Swamp Night Suit", "suit", "rare", 2800, "#3f4a5e", "#b8d86a", "#d8f0a0",
		"Deep pond blue with glow-vine trim. Best after dark."],
]


## Norm's Totally Normal Collection (docs/DAILY_STAMPS_SPEC.md 3): the four stamp-card outfits. Norm
## hands one out for a week with 5 stamps, never a shop: each def carries "price": 0 (so Suit-Up never
## stocks it) and "source": "stamps" (the same shape as Moss's "moss"). Same columns as SUITS. The joke
## is Norm's idea of what a human wears, so the names are clothes and the colours are theirs: office
## khaki with a red tie, blue jeans, lilac pyjamas, a loud holiday shirt. Only the three SUITS keys
## are set (no trouser_color / panel_color): the wear code MERGES style keys, so an extra key here
## would stay on the player after they change into any other suit. Colour
## blocking as above: every accent differs from its suit in both hue and value.
const STAMP_SUITS: Array = [
	["suit_regular_human", "Regular Human Suit", "suit", "rare", 0, "#b9a58a", "#b5483c", "#bfe0f0",
		"Office khaki with a red tie stripe. Norm sleeps in his."],
	["suit_casual_human", "Casual Human Suit", "suit", "rare", 0, "#5f7fae", "#d9a55c", "#bfe8ff",
		"Blue jeans, all over. For a human's day off."],
	["suit_sleepy_human", "Sleepy Human Suit", "suit", "rare", 0, "#a99ae0", "#e6cf7a", "#d8d8ff",
		"Soft pyjamas with moon-yellow cuffs. Humans sleep flat!"],
	["suit_holiday_human", "Holiday Human Suit", "suit", "rare", 0, "#e08f6f", "#2f8f86", "#c8f0e8",
		"A loud holiday shirt. Norm has read about beaches."],
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
	# THE TANGLE (docs/JUNGLE_PLANET_SPEC.md 3, builder J3): Moss's suits. Column 4 is the STALL price;
	# the def carries "price": 0 so Suit-Up never stocks them, and "source": "moss" (moss_stock.gd).
	for row: Array in JUNGLE_SUITS:
		out.append({
			"id": row[0],
			"name": row[1],
			"kind": "clothing",
			"category": row[2],
			"rarity": row[3],
			"price": 0,
			"stall_price": int(row[4]),
			"source": "moss",
			"desc": row[8],
			"icon_color": row[5],
			"style": {
				"suit_color": row[5],
				"accent_color": row[6],
				"visor_tint": row[7],
			},
		})
	# NORM'S STAMP CARD (docs/DAILY_STAMPS_SPEC.md 2-3): weekly prizes, given in this order after the
	# stamp decorations. "price": 0 keeps them out of Suit-Up, "source": "stamps" marks the giver.
	for row: Array in STAMP_SUITS:
		out.append({
			"id": row[0],
			"name": row[1],
			"kind": "clothing",
			"category": row[2],
			"rarity": row[3],
			"price": 0,
			"source": "stamps",
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
