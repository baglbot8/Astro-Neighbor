extends RefCounted
## Decoration catalog. `Catalog` (src/autoload/catalog.gd) instantiates this at boot and registers
## every dictionary returned by get_items(). Format is documented at the top of catalog.gd.
##
## 37 items across six categories. The five legendaries are priced 0, which means "not sold" — you
## only get them from neighbour favors (Catalog.random_reward_decoration).
##
## PRICE TIERS (docs/ECONOMY_REPORT.md "Rulings", 2026-09-29; the user: "most things should take a
## couple days of saving"). D = a mixed player's typical game day, target ~800 stardust, re-measured by
## the ECON day simulator. Each item was put in a tier by its old rank and rarity, then priced inside it:
##   everyday   0.3-0.5 D   240-400      the 8 cheapest (Cosmo Depot always stocks the 3 cheapest)
##   most       1-2 D       800-1600     16 items, "a couple of days"
##   rare       3-5 D       2400-4000    6 items
##   showpiece  7+ D        5600-6400    the telescope, the gear fountain, the robot statue
## `footprint` must match the item scene's DecoItem.footprint, since DecorationManager reads the scene's
## metadata at placement time and the store/inventory read this table.
##
## 2026-10-01 (docs/DAILY_STAMPS_SPEC.md 3) added two blocks below the main table, so the counts above
## are the ORIGINAL set: COZY (12 more shop items for Pip & Pop, priced by the same tiers) and STAMPS
## (the 8 prizes of Norm's stamp card, price 0, "source": "stamps", never sold and never a favour gift).

const SCENE_DIR := "res://src/decorations/items/"


## Every decoration definition, in display order (category, then price).
func get_items() -> Array:
	var raw: Array = [
		# ---------------------------------------------------------------- lights
		["moon_lamp", "Moon Lamp", "lights", "common", 400, 0.55, "#ffe27a",
			"A fat crescent moon on a post, humming softly at bedtime."],
		["string_lights", "String-Lights Pole", "lights", "common", 900, 0.55, "#ffb3c1",
			"Party bulbs on a droopy wire. Instantly festive."],
		["orb_light", "Floating Orb Light", "lights", "uncommon", 1250, 0.5, "#7fe9ff",
			"A bubble of light that refuses to touch its own stand."],
		["crystal_lamp", "Crystal Cluster Lamp", "lights", "uncommon", 1350, 0.6, "#b28dff",
			"Moon rock sprouting crystals that breathe when you are not looking."],
		["plasma_campfire", "Plasma Campfire", "lights", "rare", 2400, 0.7, "#8fdcff",
			"A cold blue flame. Wonderful for stories, useless for marshmallows."],
		["star_projector", "Star Projector", "lights", "rare", 2800, 0.5, "#cfe4ff",
			"Turns any evening into a planetarium."],
		["beacon_tower", "Beacon Tower", "lights", "rare", 3800, 0.75, "#ff5c5c",
			"Sweeps the sky so your friends can always find the way home."],
		# ---------------------------------------------------------------- furniture
		["supply_crate", "Supply Crate", "furniture", "common", 260, 0.55, "#ff9f43",
			"Contents: unknown. Vibes: excellent."],
		["crater_bench", "Crater Bench", "furniture", "common", 300, 0.95, "#efe0b5",
			"Carved from one big moon rock. The dents were free."],
		["nebula_rug", "Nebula Rug", "furniture", "common", 340, 1.0, "#8a5cf0",
			"A soft slice of deep space you can wipe your boots on."],
		["picnic_table", "Picnic Table", "furniture", "common", 1000, 1.1, "#efe0b5",
			"Six seats, one lantern and absolutely no ants."],
		["hover_chair", "Hover Chair", "furniture", "uncommon", 1300, 0.7, "#ff8fab",
			"Sitting down has never involved so little sitting."],
		["dome_tent", "Space Dome Tent", "furniture", "rare", 3000, 1.3, "#ffc94d",
			"A sunny little habitat for guests who forgot to book a hotel."],
		# ---------------------------------------------------------------- plants
		["moon_flower_bed", "Moon Flower Bed", "plants", "common", 320, 0.75, "#cfe4ff",
			"Pale blooms that only open once the sun clocks off."],
		["moon_rock_garden", "Moon Rock Garden", "plants", "common", 360, 0.9, "#efe0b5",
			"Rake it, sit near it, feel mysteriously calm."],
		["oxygen_planter", "Oxygen Tank Planter", "plants", "common", 850, 0.6, "#6fc3ff",
			"A retired air tank, now growing air the old-fashioned way."],
		["alien_plant_pot", "Alien Plant Pot", "plants", "common", 950, 0.55, "#b28dff",
			"Three curious tendrils. They lean toward you. That is normal."],
		["cosmic_mushrooms", "Cosmic Mushroom Cluster", "plants", "uncommon", 1150, 0.7, "#b28dff",
			"Their gills glow. Please do not put them in soup."],
		["ufo_planter", "UFO Planter", "plants", "uncommon", 1450, 0.8, "#7fd8d0",
			"Abducted a houseplant, decided to keep it."],
		["antenna_tree", "Antenna Tree", "plants", "uncommon", 1550, 0.85, "#7fd8d0",
			"Grows three dishes a year and excellent reception."],
		# ---------------------------------------------------------------- tech
		["control_console", "Control Console", "tech", "uncommon", 1500, 0.9, "#6f819c",
			"Every button blinks. Nobody knows what any of them do."],
		["satellite_dish", "Satellite Dish", "tech", "uncommon", 1600, 0.85, "#f4f4f8",
			"Listens patiently to the whole sky, one slow sweep at a time."],
		["vending_machine", "Robot Vending Machine", "tech", "rare", 3400, 0.75, "#ff5c5c",
			"Dispenses snacks and mild, encouraging beeping."],
		["space_telescope", "Space Telescope", "tech", "rare", 5600, 0.8, "#f4f4f8",
			"Points itself at whatever looks most interesting tonight."],
		["gear_fountain", "Gear Fountain", "tech", "rare", 6000, 1.1, "#ffb05c",
			"Brass cogs, cold water and a very satisfying clunk."],
		["ring_globe", "Ring-Planet Globe", "tech", "legendary", 0, 0.7, "#b28dff",
			"A whole ringed world, spinning politely on your lawn."],
		["gravity_fountain", "Gravity Well Fountain", "tech", "legendary", 0, 1.0, "#7fe9ff",
			"Water spirals upward here. The physicists have stopped asking."],
		# Vela's signature gift. The fifth price-0 legendary, added because the other four were
		# already spoken for (Zorp, Bolt, Fen, Grig) and FavorSystem.SIGNATURE_REWARD silently skips
		# any neighbour with no entry — Vela's "thanks" line promised a gift nothing could grant.
		["whisper_array", "Whisper Array", "tech", "legendary", 0, 0.62, "#cfd9e4",
			"Three little dishes, all listening to the same quiet sky."],
		# ---------------------------------------------------------------- signs
		["star_flag", "Star Flag", "signs", "common", 280, 0.5, "#ff7a59",
			"Plant it and the place is officially yours."],
		["signpost", "Wayfinder Signpost", "signs", "common", 800, 0.5, "#ff7a59",
			"Points two ways at once, which is twice as helpful."],
		["rocket_mailbox", "Rocket Mailbox", "signs", "common", 1050, 0.5, "#f4f4f8",
			"Letters go up. Somehow they always arrive."],
		["holo_sign", "Holo Sign", "signs", "uncommon", 1400, 0.6, "#7fe9ff",
			"Floating cyan letters that scroll a message only you understand."],
		# ---------------------------------------------------------------- fun
		["meteor_rock", "Meteor Rock", "fun", "common", 240, 0.55, "#7a7488",
			"Landed here first. You are technically the guest."],
		["alien_egg", "Alien Egg", "fun", "uncommon", 1200, 0.5, "#7fffd4",
			"It pulses. Bolt insists that is just the wind."],
		["space_swing", "Space Swing", "fun", "rare", 2600, 1.2, "#7fd8d0",
			"Low gravity makes every push last twice as long."],
		["robot_statue", "Robot Buddy Statue", "fun", "rare", 6400, 0.7, "#7fd8d0",
			"Waves at everyone who walks past. Never gets tired."],
		["robot_dog", "Robot Dog", "fun", "legendary", 0, 0.55, "#ff9f43",
			"Wags at 7 Hz. Loyal, rechargeable, extremely good boy."],
		["wish_star", "Wishing Star", "fun", "legendary", 0, 0.7, "#ffe27a",
			"It fell, you caught it, and now it never stops turning."],
	]
	var out: Array = []
	for r in raw + COZY:
		out.append({
			"id": "deco_" + str(r[0]),
			"name": str(r[1]),
			"kind": "decoration",
			"category": str(r[2]),
			"rarity": str(r[3]),
			"price": int(r[4]),
			"footprint": float(r[5]),
			"icon_color": str(r[6]),
			"desc": str(r[7]),
			"scene": SCENE_DIR + str(r[0]) + ".tscn",
		})
	# THE TANGLE (docs/JUNGLE_PLANET_SPEC.md 3, builder J3): Moss's stall goods. Same columns as above,
	# but column 4 is the STALL price: the def carries "price": 0 (so Cosmo Depot never stocks it) and
	# "source": "moss" (so no favour hands one out) - src/tangle/moss_stock.gd explains both.
	for r in JUNGLE:
		out.append({
			"id": "deco_" + str(r[0]),
			"name": str(r[1]),
			"kind": "decoration",
			"category": str(r[2]),
			"rarity": str(r[3]),
			"price": 0,
			"stall_price": int(r[4]),
			"source": "moss",
			"footprint": float(r[5]),
			"icon_color": str(r[6]),
			"desc": str(r[7]),
			"scene": SCENE_DIR + str(r[0]) + ".tscn",
		})
	# NORM'S STAMP CARD (docs/DAILY_STAMPS_SPEC.md 2-3): the weekly prizes. Column 4 is unused (0): the
	# def carries "price": 0 (Catalog.store_items skips it, so no shop stocks it) and "source": "stamps"
	# (Catalog.random_reward_decoration skips any def with a source, so no favour hands one out) - the
	# same two keys Norm's trophies and Moss's stall goods already use. Norm gives them in THIS order.
	for r in STAMPS:
		out.append({
			"id": "deco_" + str(r[0]),
			"name": str(r[1]),
			"kind": "decoration",
			"category": str(r[2]),
			"rarity": str(r[3]),
			"price": 0,
			"source": "stamps",
			"footprint": float(r[5]),
			"icon_color": str(r[6]),
			"desc": str(r[7]),
			"scene": SCENE_DIR + str(r[0]) + ".tscn",
		})
	return out


## THE COZY HOME SET (builder FURNSHOP, 2026-10-01, docs/DAILY_STAMPS_SPEC.md 3: "12 new shop decorations
## for Pip & Pop, spread over the economy tiers"). Ordinary shop stock: same columns and same handling as
## the main table (a real price, no source), kept apart only so the set reads as a set. By tier:
##   everyday   290 / 330 / 380             fence, pots, rug   (all above the 3 always-stocked cheapest:
##                                          240 / 260 / 280, so that shelf does not change)
##   most       880 / 980 / 1100 / 1280 / 1480   chime, tea table, armchair, lamp, bookshelf
##   rare       2500 / 2900 / 3300          star mobile, hammock, campfire ring
##   showpiece  5800                        the hot tub
## `footprint` matches each scene's DecoItem.footprint.
const COZY: Array = [
	["picket_fence", "Picket Fence", "furniture", "common", 290, 0.8, "#e3d7bc",
		"Keeps nothing in and nothing out. Looks lovely."],
	["potted_trio", "Potted Plant Trio", "plants", "common", 330, 0.6, "#7fb07a",
		"Three little pots. They like to be kept together."],
	["patchwork_rug", "Patchwork Rug", "furniture", "common", 380, 1.0, "#cf8f86",
		"Six soft squares sewn into one. Boots off, please."],
	["wind_chime", "Wind Chime", "fun", "common", 880, 0.5, "#8fa3bf",
		"Five little pipes that sing when a breeze comes by."],
	["tea_table", "Tea Table", "furniture", "common", 980, 1.0, "#7fb5ad",
		"A pot, two cups and a cushion each. Tea for two."],
	["cozy_armchair", "Cozy Armchair", "furniture", "uncommon", 1100, 0.75, "#cf8f86",
		"Sink in. Getting back out is tomorrow's problem."],
	["reading_lamp", "Reading Lamp", "lights", "uncommon", 1280, 0.55, "#e6d6a8",
		"A warm shade, a tray, a mug. One more chapter."],
	["leaning_bookshelf", "Leaning Bookshelf", "furniture", "uncommon", 1480, 0.75, "#b89a74",
		"Every shelf is full. It still found room for a plant."],
	["star_mobile", "Star Mobile", "fun", "rare", 2500, 0.7, "#e3c877",
		"A slow parade of stars, a moon and one small planet."],
	["hammock", "Hammock", "furniture", "rare", 2900, 1.3, "#c9805e",
		"Two posts and a long nap, swaying between them."],
	["campfire_ring", "Campfire Ring", "lights", "rare", 3300, 1.15, "#dd9a5c",
		"A real warm fire. At last, a place for marshmallows."],
	["hot_tub", "Stargazer Hot Tub", "fun", "rare", 5800, 1.3, "#7fc4c9",
		"Warm water, cold stars and a duck doing laps."],
]


## NORM'S TOTALLY NORMAL COLLECTION (docs/DAILY_STAMPS_SPEC.md 3): the 8 stamp-only decorations, in the
## order Norm hands them out. Builder FURNSTAMP owns the eight scenes (items/normal_*.tscn); this block
## only registers them. Column 4 (price) is ignored. FOOTPRINTS HERE ARE PLACEHOLDERS until they are
## matched to each scene's DecoItem.footprint (the rule at the top of this file).
const STAMPS: Array = [
	["normal_sofa", "Totally Normal Sofa", "furniture", "rare", 0, 1.0, "#cf8f86",
		"For sitting, as humans do. I sit on it all the time."],
	["normal_tv", "Totally Normal TV", "tech", "rare", 0, 0.7, "#6f819c",
		"It shows pictures. I watch it with both of my eyes."],
	["normal_houseplant", "Totally Normal Houseplant", "plants", "rare", 0, 0.6, "#7fb07a",
		"A normal plant. I water it with water, like a human."],
	["normal_fridge", "Totally Normal Fridge", "tech", "rare", 0, 0.7, "#cfd9e4",
		"It keeps food cold. I put all of my human food in it."],
	["normal_lamp", "Totally Normal Lamp", "lights", "rare", 0, 0.55, "#e6d6a8",
		"It makes light when it is dark. Humans love seeing."],
	["normal_bookshelf", "Totally Normal Bookshelf", "furniture", "rare", 0, 0.8, "#b89a74",
		"Full of books. I have read every one with my eyes."],
	["normal_rug", "Totally Normal Rug", "furniture", "rare", 0, 1.0, "#a595cf",
		"A blanket for the floor. Humans stand on these."],
	["normal_clock", "Totally Normal Clock", "fun", "rare", 0, 0.55, "#d9c27a",
		"It tells the time. It is always a very normal time."],
]


## Moss's jungle-only decorations (builder J3). Stall prices by the tiers above: everyday 320 / 380,
## most 1000 / 1400, rare 3200. `footprint` matches each scene's DecoItem.footprint.
const JUNGLE: Array = [
	["spiral_fern", "Spiral Fern", "plants", "common", 320, 0.5, "#6fae8c",
		"A fern from the Tangle. It grows in one slow spiral."],
	["lilypad_lamp", "Lily-Pad Lamp", "lights", "common", 380, 0.5, "#8fc49a",
		"A lily pad on a reed, with a little light that wakes at night."],
	["moss_stump_seat", "Mossy Stump Seat", "furniture", "uncommon", 1000, 0.55, "#8a7a5c",
		"An old stump with a soft moss cushion. Very comfy."],
	["glow_pod", "Glow Pod", "plants", "uncommon", 1400, 0.55, "#b8a3cf",
		"A big swamp seed pod. Its seams glow after dark."],
	["glowvine_arch", "Glow-Vine Arch", "plants", "rare", 3200, 1.2, "#7fc4a8",
		"Two old roots twist into an arch hung with glowing vines."],
]
