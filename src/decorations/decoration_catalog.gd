extends RefCounted
## Decoration catalog. `Catalog` (src/autoload/catalog.gd) instantiates this at boot and registers
## every dictionary returned by get_items(). Format is documented at the top of catalog.gd.
##
## 37 items across six categories. Prices run 120 - 1500 stardust; the four legendaries are priced 0,
## which means "not sold" — you only get them from neighbour favors (Catalog.random_reward_decoration).
## `footprint` must match the item scene's DecoItem.footprint, since DecorationManager reads the scene's
## metadata at placement time and the store/inventory read this table.

const SCENE_DIR := "res://src/decorations/items/"


## Every decoration definition, in display order (category, then price).
func get_items() -> Array:
	var raw: Array = [
		# ---------------------------------------------------------------- lights
		["moon_lamp", "Moon Lamp", "lights", "common", 240, 0.55, "#ffe27a",
			"A fat crescent moon on a post, humming softly at bedtime."],
		["string_lights", "String-Lights Pole", "lights", "common", 300, 0.55, "#ffb3c1",
			"Party bulbs on a droopy wire. Instantly festive."],
		["orb_light", "Floating Orb Light", "lights", "uncommon", 460, 0.5, "#7fe9ff",
			"A bubble of light that refuses to touch its own stand."],
		["crystal_lamp", "Crystal Cluster Lamp", "lights", "uncommon", 520, 0.6, "#b28dff",
			"Moon rock sprouting crystals that breathe when you are not looking."],
		["plasma_campfire", "Plasma Campfire", "lights", "rare", 780, 0.7, "#8fdcff",
			"A cold blue flame. Wonderful for stories, useless for marshmallows."],
		["star_projector", "Star Projector", "lights", "rare", 900, 0.5, "#cfe4ff",
			"Turns any evening into a planetarium."],
		["beacon_tower", "Beacon Tower", "lights", "rare", 1200, 0.75, "#ff5c5c",
			"Sweeps the sky so your friends can always find the way home."],
		# ---------------------------------------------------------------- furniture
		["supply_crate", "Supply Crate", "furniture", "common", 150, 0.55, "#ff9f43",
			"Contents: unknown. Vibes: excellent."],
		["crater_bench", "Crater Bench", "furniture", "common", 180, 0.95, "#efe0b5",
			"Carved from one big moon rock. The dents were free."],
		["nebula_rug", "Nebula Rug", "furniture", "common", 220, 1.0, "#8a5cf0",
			"A soft slice of deep space you can wipe your boots on."],
		["picnic_table", "Picnic Table", "furniture", "common", 340, 1.1, "#efe0b5",
			"Six seats, one lantern and absolutely no ants."],
		["hover_chair", "Hover Chair", "furniture", "uncommon", 480, 0.7, "#ff8fab",
			"Sitting down has never involved so little sitting."],
		["dome_tent", "Space Dome Tent", "furniture", "rare", 980, 1.3, "#ffc94d",
			"A sunny little habitat for guests who forgot to book a hotel."],
		# ---------------------------------------------------------------- plants
		["moon_flower_bed", "Moon Flower Bed", "plants", "common", 190, 0.75, "#cfe4ff",
			"Pale blooms that only open once the sun clocks off."],
		["moon_rock_garden", "Moon Rock Garden", "plants", "common", 230, 0.9, "#efe0b5",
			"Rake it, sit near it, feel mysteriously calm."],
		["oxygen_planter", "Oxygen Tank Planter", "plants", "common", 280, 0.6, "#6fc3ff",
			"A retired air tank, now growing air the old-fashioned way."],
		["alien_plant_pot", "Alien Plant Pot", "plants", "common", 310, 0.55, "#b28dff",
			"Three curious tendrils. They lean toward you. That is normal."],
		["cosmic_mushrooms", "Cosmic Mushroom Cluster", "plants", "uncommon", 420, 0.7, "#b28dff",
			"Their gills glow. Please do not put them in soup."],
		["ufo_planter", "UFO Planter", "plants", "uncommon", 560, 0.8, "#7fd8d0",
			"Abducted a houseplant, decided to keep it."],
		["antenna_tree", "Antenna Tree", "plants", "uncommon", 660, 0.85, "#7fd8d0",
			"Grows three dishes a year and excellent reception."],
		# ---------------------------------------------------------------- tech
		["control_console", "Control Console", "tech", "uncommon", 580, 0.9, "#6f819c",
			"Every button blinks. Nobody knows what any of them do."],
		["satellite_dish", "Satellite Dish", "tech", "uncommon", 680, 0.85, "#f4f4f8",
			"Listens patiently to the whole sky, one slow sweep at a time."],
		["vending_machine", "Robot Vending Machine", "tech", "rare", 1100, 0.75, "#ff5c5c",
			"Dispenses snacks and mild, encouraging beeping."],
		["space_telescope", "Space Telescope", "tech", "rare", 1250, 0.8, "#f4f4f8",
			"Points itself at whatever looks most interesting tonight."],
		["gear_fountain", "Gear Fountain", "tech", "rare", 1450, 1.1, "#ffb05c",
			"Brass cogs, cold water and a very satisfying clunk."],
		["ring_globe", "Ring-Planet Globe", "tech", "legendary", 0, 0.7, "#b28dff",
			"A whole ringed world, spinning politely on your lawn."],
		["gravity_fountain", "Gravity Well Fountain", "tech", "legendary", 0, 1.0, "#7fe9ff",
			"Water spirals upward here. The physicists have stopped asking."],
		# ---------------------------------------------------------------- signs
		["star_flag", "Star Flag", "signs", "common", 160, 0.5, "#ff7a59",
			"Plant it and the place is officially yours."],
		["signpost", "Wayfinder Signpost", "signs", "common", 250, 0.5, "#ff7a59",
			"Points two ways at once, which is twice as helpful."],
		["rocket_mailbox", "Rocket Mailbox", "signs", "common", 360, 0.5, "#f4f4f8",
			"Letters go up. Somehow they always arrive."],
		["holo_sign", "Holo Sign", "signs", "uncommon", 540, 0.6, "#7fe9ff",
			"Floating cyan letters that scroll a message only you understand."],
		# ---------------------------------------------------------------- fun
		["meteor_rock", "Meteor Rock", "fun", "common", 120, 0.55, "#7a7488",
			"Landed here first. You are technically the guest."],
		["alien_egg", "Alien Egg", "fun", "uncommon", 430, 0.5, "#7fffd4",
			"It pulses. Bolt insists that is just the wind."],
		["space_swing", "Space Swing", "fun", "rare", 890, 1.2, "#7fd8d0",
			"Low gravity makes every push last twice as long."],
		["robot_statue", "Robot Buddy Statue", "fun", "rare", 1500, 0.7, "#7fd8d0",
			"Waves at everyone who walks past. Never gets tired."],
		["robot_dog", "Robot Dog", "fun", "legendary", 0, 0.55, "#ff9f43",
			"Wags at 7 Hz. Loyal, rechargeable, extremely good boy."],
		["wish_star", "Wishing Star", "fun", "legendary", 0, 0.7, "#ffe27a",
			"It fell, you caught it, and now it never stops turning."],
	]
	var out: Array = []
	for r in raw:
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
	return out
