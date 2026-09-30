class_name CameraGoods
extends RefCounted
## CAMERA GOODS (ECON, 2026-09-29; docs/ECONOMY_REPORT.md "Rulings", the user's "option 3"): the camera
## upgrade and spare film, sold for STARDUST, so both reach the planet safari. Before ECON they were only
## sold on the retired space safari's loadout card, so on the planet safari you had 10 shots forever.
##
## WHO SELLS WHAT (MOSS2, 2026-09-30, docs/JUNGLE_PLANET_SPEC.md 6 - the user: "Moss narratively could be
## a field photographer who retired ... he acts as the 'camera upgrade' shop"):
##   * Pip & Pop (Cosmo Depot)  -> SPARE FILM only, so nobody is stuck early (depot_stock).
##   * Moss (The Tangle)        -> the LENSES and the HOVER LESSON (moss_stock). The Tangle opens
##                                 mid-game, so lenses are now a mid-game buy.
##
## Nothing here holds state. The numbers are SafariScoring's (FILM_UPGRADE_COSTS, FILM_BUY_PRICE) and
## the store is GameState's (film_upgrades, film_spares, flags[HOVER_FLAG]); PlanetSafari loads the film
## at the start of a trip (`film_capacity() + take_film_spares()`). These defs are built fresh each time
## a shop opens and are NOT registered in the Catalog - they are never bag items, so they can never be
## placed, sold back, or drawn as a favour reward.
##
##   CameraGoods.depot_stock()    -> the entries at the front of Cosmo Depot's buy list (spare film)
##   CameraGoods.moss_stock()     -> the entries at the front of Moss's shelf (lens, Hover lesson, and
##                                   GOODS' photo goods: Field Notes, filters, Tripod, Steady Grip)
##   CameraGoods.is_camera_good(def)
##   CameraGoods.buy(def)         -> true when paid for and applied
##   CameraGoods.restock(stock)   -> the same stock with each camera entry re-read after a purchase
##                                   (same shop, same kinds - it never adds a kind that was not there)

const KIND_LENS := "camera_upgrade"
const KIND_FILM := "camera_film"
const KIND_LESSON := "camera_lesson"
const LENS_NAMES := ["Zoom Lens Kit", "Pro Lens Kit"]
## The Hover lesson (JUNGLE_PLANET_SPEC 6): once bought, GameState.flags[HOVER_FLAG] is true and the
## first-person safaris let you hold a button to rise and hover (built by the hover builder, who reads
## only this flag). Rare tier (ECONOMY_REPORT Rulings: 3-5 D = 2400-4000): 3000, about four days.
const HOVER_FLAG := "hover_learned"
const HOVER_PRICE := 3000
const HOVER_ID := "moss_hover_lesson"

## MOSS'S NEW PHOTO GOODS (GOODS, 2026-09-30; docs/JUNGLE_PLANET_SPEC.md 6.1 - the user: "i like steady grip,
## moss's field notes (but cheaper), tripod and photo filters"). The FLAG NAMES are fixed by the spec; the
## tripod's self-timer and the filters' looks are another builder's, who reads only these flags.
## Prices by the ECONOMY_REPORT Rulings tiers (D ~ 800): everyday 0.3-0.5 D, most 1-2 D; the spec's own
## numbers ("~1,200", "~150", "~1,000", "~300 each") are used as written.
const KIND_GRIP := "camera_grip"
const KIND_NOTES := "camera_notes"
const KIND_TRIPOD := "camera_tripod"
const KIND_FILTER := "camera_filter"
## Steady Grip: walk slowly with the camera raised, in the safaris and the meteor survey (one-time buy).
const GRIP_FLAG := "steady_grip"
const GRIP_ID := "moss_steady_grip"
const GRIP_PRICE := 1200
## Moss's Field Notes: `flags.field_notes_day` = the game day they were last bought. Bought again each day;
## gone from the shelf for the rest of the day once bought (the talk itself is src/tangle/field_notes.gd).
const NOTES_FLAG := "field_notes_day"
const NOTES_ID := "moss_field_notes"
const NOTES_PRICE := 150
## Tripod: the home album camera's self-timer (one-time buy).
const TRIPOD_FLAG := "tripod_owned"
const TRIPOD_ID := "moss_tripod"
const TRIPOD_PRICE := 1000
## Photo filters: `flags.filters_owned` is an Array of the filter ids below, one added per purchase.
## THE FILTER IDS ARE THE CONTRACT with the filters builder: read them from here (CameraGoods.FILTERS).
const FILTERS_FLAG := "filters_owned"
const FILTER_PRICE := 300
const FILTER_ID_PREFIX := "moss_filter_"
const FILTERS := [
	{"id": "warm", "name": "Warm Filter", "desc": "A warm, golden look for your home album photos.", "color": "#f2b27a"},
	{"id": "old_film", "name": "Old Film Filter", "desc": "Faded colours, like a very old photo. For your home album.", "color": "#c7ad86"},
	{"id": "dreamy", "name": "Dreamy Filter", "desc": "A soft, glowing blur for your home album photos.", "color": "#d6c3e8"},
	{"id": "night_glow", "name": "Night Glow Filter", "desc": "Cool blues and bright lights for your home album photos.", "color": "#8fb4e6"},
]


## Pip & Pop's camera shelf: spare film only.
static func depot_stock() -> Array:
	var out: Array = []
	var film := film_def()
	if not film.is_empty():
		out.append(film)
	return out


## Moss's camera shelf, cheapest first like every shelf: today's Field Notes, each filter not yet owned,
## the Tripod, the Steady Grip, the next lens tier and the Hover lesson (each gone once owned / bought today).
static func moss_stock() -> Array:
	var out: Array = []
	for d: Dictionary in [notes_def()] + filter_defs() + [tripod_def(), grip_def(), lens_def(), lesson_def()]:
		if not d.is_empty():
			out.append(d)
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("price", 0)) < int(b.get("price", 0)))
	return out


## The Steady Grip, or {} once owned.
static func grip_def() -> Dictionary:
	if GameState.flag(GRIP_FLAG):
		return {}
	return {
		"id": GRIP_ID,
		"name": "Steady Grip",
		"kind": KIND_GRIP,
		"category": "tech",
		"rarity": "uncommon",
		"price": GRIP_PRICE,
		"desc": "Walk slowly with your camera up, on photo trips and the meteor survey. For good.",
		"icon_color": "#a9c79a",
	}


## Today's Field Notes, or {} when already bought today.
static func notes_def() -> Dictionary:
	if notes_today():
		return {}
	return {
		"id": NOTES_ID,
		"name": "Moss's Field Notes",
		"kind": KIND_NOTES,
		# "signs" only picks the card's glyph (a little board with writing); never a Catalog item.
		"category": "signs",
		"rarity": "common",
		"price": NOTES_PRICE,
		"desc": "Moss tells you which rare sight is likely today on a world you pick, and roughly where. Today only.",
		"icon_color": "#c7ad86",
	}


## The Tripod, or {} once owned.
static func tripod_def() -> Dictionary:
	if GameState.flag(TRIPOD_FLAG):
		return {}
	return {
		"id": TRIPOD_ID,
		"name": "Tripod",
		"kind": KIND_TRIPOD,
		"category": "tech",
		"rarity": "uncommon",
		"price": TRIPOD_PRICE,
		"desc": "Set your album camera down at home, start the timer, and jump into the photo yourself. For good.",
		"icon_color": "#b8a06a",
	}


## One card per filter not yet owned (each purchase buys ONE filter).
static func filter_defs() -> Array:
	var out: Array = []
	var owned := filters_owned()
	for f: Dictionary in FILTERS:
		if not owned.has(str(f["id"])):
			out.append(filter_def(str(f["id"])))
	return out


## The shop def of filter `fid` (a FILTERS id), or {} when unknown or owned.
static func filter_def(fid: String) -> Dictionary:
	if filters_owned().has(fid):
		return {}
	for f: Dictionary in FILTERS:
		if str(f["id"]) == fid:
			return {
				"id": FILTER_ID_PREFIX + fid,
				"name": str(f["name"]),
				"kind": KIND_FILTER,
				"filter": fid,
				"category": "fun",
				"rarity": "common",
				"price": FILTER_PRICE,
				"desc": str(f["desc"]) + " Looks only.",
				"icon_color": str(f["color"]),
			}
	return {}


## `flags.filters_owned` as an Array of filter id Strings (a save round-trips it through JSON).
static func filters_owned() -> Array:
	var raw: Variant = GameState.flags.get(FILTERS_FLAG, [])
	var out: Array = []
	if raw is Array:
		for v: Variant in raw:
			out.append(str(v))
	return out


## True when the Field Notes were bought on the current game day.
static func notes_today() -> bool:
	return GameState.flags.has(NOTES_FLAG) and int(GameState.flags[NOTES_FLAG]) == GameState.day_count


## The next camera upgrade tier, or {} once the camera is maxed.
static func lens_def() -> Dictionary:
	if not GameState.film_upgrade_available():
		return {}
	var tier := GameState.film_upgrades
	var now := GameState.film_capacity()
	return {
		"id": "camera_lens_%d" % (tier + 1),
		"name": str(LENS_NAMES[clampi(tier, 0, LENS_NAMES.size() - 1)]),
		"kind": KIND_LENS,
		"category": "tech",
		"rarity": "rare",
		"price": SafariScoring.film_upgrade_cost(tier),
		"desc": "Your camera holds %d more shots on every safari, for good. %d shots now." % [
			SafariScoring.FILM_UPGRADE_STEP, now],
		"icon_color": "#8fc4ef",
	}


## One spare plate for the next safari, or {} when the spares already fill a trip (or the camera is
## maxed, which leaves no room for spares at all - GameState.film_spare_max).
static func film_def() -> Dictionary:
	var cap := GameState.film_spare_max()
	if cap <= 0 or GameState.film_spares >= cap:
		return {}
	return {
		"id": "camera_film",
		"name": "Spare Film",
		"kind": KIND_FILM,
		"category": "material",
		"rarity": "common",
		"price": SafariScoring.FILM_BUY_PRICE,
		"desc": "One extra shot on your next safari. You have %d of %d." % [GameState.film_spares, cap],
		"icon_color": "#ffd166",
	}


## The Hover lesson, or {} once learned.
static func lesson_def() -> Dictionary:
	if hover_learned():
		return {}
	return {
		"id": HOVER_ID,
		"name": "Hover Lesson",
		"kind": KIND_LESSON,
		# "backpack" only picks the shop card's glyph (ItemGlyph: a pack - the jetpack); the def is never
		# a Catalog item, so nothing treats it as clothing.
		"category": "backpack",
		"rarity": "rare",
		"price": HOVER_PRICE,
		"desc": "Moss teaches you to hover with your jetpack on safaris, to look around and spot rare sights. For good.",
		"icon_color": "#9fe6c4",
	}


static func hover_learned() -> bool:
	return GameState.flag(HOVER_FLAG)


static func is_camera_good(def: Dictionary) -> bool:
	var k := str(def.get("kind", ""))
	return k in [KIND_LENS, KIND_FILM, KIND_LESSON, KIND_GRIP, KIND_NOTES, KIND_TRIPOD, KIND_FILTER]


static func buy(def: Dictionary) -> bool:
	match str(def.get("kind", "")):
		KIND_LENS:
			return GameState.buy_film_upgrade()
		KIND_FILM:
			return GameState.buy_film_spare()
		KIND_LESSON:
			return buy_hover_lesson()
		KIND_GRIP:
			return _buy_once(GRIP_FLAG, GRIP_PRICE)
		KIND_TRIPOD:
			return _buy_once(TRIPOD_FLAG, TRIPOD_PRICE)
		KIND_NOTES:
			return buy_notes()
		KIND_FILTER:
			return buy_filter(str(def.get("filter", "")))
	return false


## Pays for a one-time good and sets its flag. False (nothing spent) when owned or short.
static func _buy_once(flag_key: String, price: int) -> bool:
	if GameState.flag(flag_key):
		return false
	if not GameState.spend_stardust(price):
		return false
	GameState.set_flag(flag_key, true)
	return true


## Today's Field Notes. False (nothing spent) when already bought today or short.
static func buy_notes() -> bool:
	if notes_today():
		return false
	if not GameState.spend_stardust(NOTES_PRICE):
		return false
	GameState.flags[NOTES_FLAG] = GameState.day_count
	return true


## One filter. False (nothing spent) when unknown, owned or short.
static func buy_filter(fid: String) -> bool:
	if filter_def(fid).is_empty():
		return false
	if not GameState.spend_stardust(FILTER_PRICE):
		return false
	var owned := filters_owned()
	owned.append(fid)
	GameState.flags[FILTERS_FLAG] = owned
	return true


## Pays for and sets the Hover lesson. False (and nothing spent) when already learned or short.
static func buy_hover_lesson() -> bool:
	if hover_learned():
		return false
	if not GameState.spend_stardust(HOVER_PRICE):
		return false
	GameState.set_flag(HOVER_FLAG, true)
	return true


## Toast after a purchase.
static func bought_line(def: Dictionary) -> String:
	match str(def.get("kind", "")):
		KIND_LENS:
			return "New lens! %d shots every safari." % GameState.film_capacity()
		KIND_LESSON:
			return "You can hover now! Try it on a safari."
		KIND_GRIP:
			return "Steady Grip! Walk slowly with the camera up."
		KIND_TRIPOD:
			return "Tripod! Try the self-timer on your home camera."
		KIND_NOTES:
			return "Field Notes for today. Moss will tell you more."
		KIND_FILTER:
			return "New filter: %s! Try it on your home album." % str(def.get("name", "Filter"))
	return "Spare film: %d ready for your next safari." % GameState.film_spares


## `stock_in` with each camera entry re-read in place (the next lens tier, the film count, the lesson
## gone once learned) and dropped when there is nothing left to sell. Kinds that were not on this
## shelf are never added, so Pip & Pop's shelf can never grow a lens and Moss's never grows film.
static func restock(stock_in: Array) -> Array:
	var out: Array = []
	for d: Variant in stock_in:
		if not (d is Dictionary):
			continue
		var def := d as Dictionary
		if not is_camera_good(def):
			out.append(def)
			continue
		var fresh: Dictionary = {}
		match str(def.get("kind", "")):
			KIND_LENS:
				fresh = lens_def()
			KIND_FILM:
				fresh = film_def()
			KIND_LESSON:
				fresh = lesson_def()
			KIND_GRIP:
				fresh = grip_def()
			KIND_TRIPOD:
				fresh = tripod_def()
			KIND_NOTES:
				fresh = notes_def()
			KIND_FILTER:
				fresh = filter_def(str(def.get("filter", "")))
		if not fresh.is_empty():
			out.append(fresh)
	return out
