extends Node
## Single source of truth for all persistent game data.
## Everything in here is plain Dictionaries/Arrays/primitives so SaveManager can dump it to JSON.
## Never store Nodes or Resources here.

const PLANET_IDS := ["home", "zorp", "bolt", "hub", "fen", "grig"]
const STARTING_STARDUST := 120

var current_planet_id: String = "home"
var previous_planet_id: String = ""

var stardust: int = STARTING_STARDUST

## item_id -> count. Items are decorations, clothing, collectibles, favor items.
var inventory: Dictionary = {}

## planet_id -> Array of {"id": String, "item": String, "pos": [x,y,z], "basis": [9 floats]}
## pos/basis are LOCAL to the planet node.
var placed_decorations: Dictionary = {"home": [], "zorp": [], "bolt": [], "hub": [], "fen": [], "grig": []}

## Player look. Astronaut model reads these. Clothing store writes them.
var player_style: Dictionary = {
	"name": "Astro",
	"suit_color": "#f4f4f8",
	## Trousers: the large dark value block every Animal Crossing outfit has (AC player = indigo).
	"trouser_color": "#42419c",
	## Jacket panel / collar / placket: the mid value between the suit and the trousers.
	"panel_color": "#5f92cc",
	"accent_color": "#ff7a59",
	## Tints the OPAQUE navy visor pane (docs/STYLE_GUIDE.md R2.2) — it is no longer glass.
	"visor_tint": "#6fc3ff",
	## UNUSED by AstronautModel since REVISION 2 deleted the face inside the helmet. Kept because
	## save files and the clothing catalog carry them; do not read them for the astronaut.
	"skin_tone": "#ffd9b8",
	"hair_color": "#5a3b2e",
	"backpack_id": "pack_basic",
	"hat_id": "",
	"pattern_id": "",
}

## npc_id -> {"friendship": int, "talked_today": bool, "favors_done": int}
var npcs: Dictionary = {}

## favor_id -> {"npc": String, "type": String, "target_item": String, "count": int, "progress": int, "state": "offered|active|done", "reward_item": String, "reward_stardust": int, "deliver_to": String}
var favors: Dictionary = {}

## Time of day in hours (0..24). Day cycle length in real minutes lives in day_night.gd.
var time_of_day: float = 9.5
var day_count: int = 1

## Planet display name chosen at Town Hall.
var home_planet_name: String = "Little Orbit"

## How big the player's own world is, as an INDEX into PlanetData.HOME_RADII (0 = the starting
## planet). STYLE_GUIDE R2.11: the starting planets shrank so more of your own world fits on screen,
## and "expand your planet" is a later upgrade — shipping the size as persisted data now means that
## upgrade is `GameState.home_planet_size += 1` and nothing else. Only the home planet reads this;
## Zorp, Bolt and the hub keep the radius in their own .tres. Resolved by PlanetData.resolve_size().
var home_planet_size: int = 0

## Arbitrary flags: "intro_done", "tutorial_decorate_seen", etc.
var flags: Dictionary = {}

## Collectibles picked this day, per planet: planet_id -> Array[String] (spawn ids)
var picked_collectibles: Dictionary = {}

## Purchased clothing ids (owned wardrobe).
var wardrobe: Array = ["suit_white"]

## Space trash sitting on the home planet, waiting to be cleaned up.
## Array of {"id": String, "dir": [x,y,z] (unit vector, LOCAL to the planet), "kind": String}.
var trash_home: Array = []
## Unix timestamp (Time.get_unix_time_from_system()) of the last time TrashSystem checked how much
## real time has passed since anyone looked at the home planet. Drives "it piled up while you were
## away" — see src/planet/trash_system.gd. Defaults to "now", not 0: a fresh boot with no save yet
## loaded (dev/test runs that open world.tscn directly, or the instant before a real save/new-game
## sets this properly) must not read as decades of elapsed time and dump a maxed-out trash pile.
var trash_last_check_unix: float = Time.get_unix_time_from_system()

## Settings.
## `mouse_sensitivity` is a multiplier on CameraRig.MOUSE_*_DEG_PER_PX (clamped 0.1..4.0 there);
## `camera_invert_y` is the vertical twin of the existing `camera_invert_x`. Both were added with
## mouse look (see src/player/camera_rig.gd) and are surfaced on the pause menu's Settings page.
var settings: Dictionary = {"music_volume": 0.8, "sfx_volume": 1.0, "camera_invert_x": false, "camera_invert_y": false, "mouse_sensitivity": 1.0}

# ----------------------------------------------------------------------------- economy
func add_stardust(amount: int) -> void:
	stardust = max(0, stardust + amount)
	EventBus.stardust_changed.emit(stardust, amount)

func can_afford(amount: int) -> bool:
	return stardust >= amount

func spend_stardust(amount: int) -> bool:
	if not can_afford(amount):
		return false
	add_stardust(-amount)
	return true

# ----------------------------------------------------------------------------- inventory
func add_item(item_id: String, count: int = 1) -> void:
	inventory[item_id] = int(inventory.get(item_id, 0)) + count
	EventBus.item_added.emit(item_id, count)

func remove_item(item_id: String, count: int = 1) -> bool:
	var have: int = int(inventory.get(item_id, 0))
	if have < count:
		return false
	have -= count
	if have <= 0:
		inventory.erase(item_id)
	else:
		inventory[item_id] = have
	EventBus.item_removed.emit(item_id, count)
	return true

func item_count(item_id: String) -> int:
	return int(inventory.get(item_id, 0))

func has_item(item_id: String, count: int = 1) -> bool:
	return item_count(item_id) >= count

# ----------------------------------------------------------------------------- decorations
func add_placed_decoration(planet_id: String, instance_id: String, item_id: String, local_pos: Vector3, local_basis: Basis) -> void:
	if not placed_decorations.has(planet_id):
		placed_decorations[planet_id] = []
	placed_decorations[planet_id].append({
		"id": instance_id,
		"item": item_id,
		"pos": [local_pos.x, local_pos.y, local_pos.z],
		"basis": [local_basis.x.x, local_basis.x.y, local_basis.x.z,
				  local_basis.y.x, local_basis.y.y, local_basis.y.z,
				  local_basis.z.x, local_basis.z.y, local_basis.z.z],
	})
	EventBus.decoration_placed.emit(planet_id, instance_id, item_id)

func remove_placed_decoration(planet_id: String, instance_id: String) -> Dictionary:
	var arr: Array = placed_decorations.get(planet_id, [])
	for i in arr.size():
		if arr[i]["id"] == instance_id:
			var entry: Dictionary = arr[i]
			arr.remove_at(i)
			EventBus.decoration_removed.emit(planet_id, instance_id)
			return entry
	return {}

static func basis_from_array(a: Array) -> Basis:
	return Basis(Vector3(a[0], a[1], a[2]), Vector3(a[3], a[4], a[5]), Vector3(a[6], a[7], a[8]))

static func vec3_from_array(a: Array) -> Vector3:
	return Vector3(a[0], a[1], a[2])

# ----------------------------------------------------------------------------- trash
func add_trash(id: String, dir: Vector3, kind: String) -> void:
	trash_home.append({"id": id, "dir": [dir.x, dir.y, dir.z], "kind": kind})
	EventBus.trash_changed.emit(trash_home.size())

func remove_trash(id: String) -> bool:
	for i in trash_home.size():
		if str(trash_home[i].get("id", "")) == id:
			trash_home.remove_at(i)
			EventBus.trash_changed.emit(trash_home.size())
			return true
	return false

# ----------------------------------------------------------------------------- npcs
func npc_data(npc_id: String) -> Dictionary:
	if not npcs.has(npc_id):
		npcs[npc_id] = {"friendship": 0, "talked_today": false, "favors_done": 0, "last_favor_day": 0}
	return npcs[npc_id]

func add_friendship(npc_id: String, amount: int) -> void:
	var d := npc_data(npc_id)
	d["friendship"] = clamp(int(d["friendship"]) + amount, 0, 100)
	EventBus.friendship_changed.emit(npc_id, d["friendship"])

# ----------------------------------------------------------------------------- flags
func set_flag(key: String, value: bool = true) -> void:
	flags[key] = value

func flag(key: String) -> bool:
	return bool(flags.get(key, false))

# ----------------------------------------------------------------------------- serialization
func to_dict() -> Dictionary:
	return {
		"version": 1,
		"current_planet_id": current_planet_id,
		"previous_planet_id": previous_planet_id,
		"stardust": stardust,
		"inventory": inventory,
		"placed_decorations": placed_decorations,
		"player_style": player_style,
		"npcs": npcs,
		"favors": favors,
		"time_of_day": time_of_day,
		"day_count": day_count,
		"home_planet_name": home_planet_name,
		"home_planet_size": home_planet_size,
		"flags": flags,
		"picked_collectibles": picked_collectibles,
		"wardrobe": wardrobe,
		"settings": settings,
		"trash_home": trash_home,
		"trash_last_check_unix": trash_last_check_unix,
	}

func from_dict(d: Dictionary) -> void:
	current_planet_id = str(d.get("current_planet_id", "home"))
	previous_planet_id = str(d.get("previous_planet_id", ""))
	stardust = int(d.get("stardust", STARTING_STARDUST))
	inventory = _ints(d.get("inventory", {}))
	placed_decorations = d.get("placed_decorations", {"home": [], "zorp": [], "bolt": [], "hub": [], "fen": [], "grig": []})
	for pid in PLANET_IDS:
		if not placed_decorations.has(pid):
			placed_decorations[pid] = []
	player_style = d.get("player_style", player_style)
	npcs = _deep_ints(d.get("npcs", {}))
	favors = _deep_ints(d.get("favors", {}))
	time_of_day = float(d.get("time_of_day", 9.5))
	day_count = int(d.get("day_count", 1))
	home_planet_name = str(d.get("home_planet_name", "Little Orbit"))
	# Saves written before R2.11 have no key here: they are level 0, the starting size.
	home_planet_size = int(d.get("home_planet_size", 0))
	flags = d.get("flags", {})
	picked_collectibles = d.get("picked_collectibles", {})
	wardrobe = d.get("wardrobe", ["suit_white"])
	settings = d.get("settings", settings)
	trash_home = d.get("trash_home", [])
	# Old saves have no key here. Defaulting to "now" (not 0) means an existing save does not
	# instantly dump a maxed-out trash pile the first time it loads under the new system.
	trash_last_check_unix = float(d.get("trash_last_check_unix", Time.get_unix_time_from_system()))

## JSON has no integer type - every whole number round-trips through the save file as a float,
## so a reloaded inventory reads {"deco_moon_lamp": 2.0}. Every consumer currently casts with
## int(), which hides it, but the dictionaries stay dirty until the next write and any code that
## compares or stringifies a count sees "2.0". These two helpers coerce on load instead.
static func _ints(d: Variant) -> Dictionary:
	var out: Dictionary = {}
	if typeof(d) != TYPE_DICTIONARY:
		return out
	for k in (d as Dictionary):
		var v: Variant = d[k]
		out[str(k)] = int(v) if typeof(v) == TYPE_FLOAT else v
	return out


## Same, but recurses into nested dictionaries and arrays (favors and npcs hold counts inside
## per-entry dictionaries). Floats that are not whole numbers are left alone.
static func _deep_ints(v: Variant) -> Variant:
	match typeof(v):
		TYPE_DICTIONARY:
			var out_d: Dictionary = {}
			for k in (v as Dictionary):
				out_d[str(k)] = _deep_ints((v as Dictionary)[k])
			return out_d
		TYPE_ARRAY:
			var out_a: Array = []
			for item in (v as Array):
				out_a.append(_deep_ints(item))
			return out_a
		TYPE_FLOAT:
			var f: float = v
			return int(f) if is_equal_approx(f, roundf(f)) else f
	return v


func reset_new_game() -> void:
	from_dict({})
	stardust = STARTING_STARDUST
	# Starter kit so the first minute of play already has something to place.
	inventory = {"deco_moon_lamp": 1, "deco_star_flag": 1, "deco_crater_bench": 1}
