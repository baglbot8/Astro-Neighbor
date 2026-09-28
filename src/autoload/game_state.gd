extends Node
## Single source of truth for all persistent game data.
## Everything in here is plain Dictionaries/Arrays/primitives so SaveManager can dump it to JSON.
## Never store Nodes or Resources here.

const PLANET_IDS := ["home", "zorp", "bolt", "hub", "fen", "grig", "vela"]
## CORE_LOOP.md "Scrap and stardust": measured 2026-09-10, today's 120 is "too common" - a single
## favor alone pays 60-140. FIRST GUESS for the campaign's rare stardust, about a third of that;
## BUILD_PLAN Phase 6 tunes it from a timed play-through. An old save (no campaign fields) never
## reads this - it keeps whatever amount it already saved (see `from_dict`).
const STARTING_STARDUST := 40
## CORE_LOOP.md "Scrap and stardust": scrap, not stardust, is the new game's early currency, and it
## is meant to come from picking it up (every world, including home) rather than a starting stash.
## FIRST GUESS, small on purpose; BUILD_PLAN Phase 6 tunes it from a timed play-through.
const STARTING_SCRAP := 5
## DAY round (2026-09-21, scratch only). PLATES ARE PER TRIP, AND THIS CONSTANT IS LIVE AGAIN.
##
## THE LEAD'S RULING, from the user's own words ("You should have limited film for each trip"):
## film is per TRIP, not per day. Every "Photo time!" flight loads a full magazine; what a flight
## did not shoot does not carry forward and what it did shoot is not deducted from anything. The
## limit on how much safari a day holds is the CLOCK (src/sky/safari_transit.gd PHOTO_TRIP_HOURS),
## not the film box. The WIRE round's day box (`film_day` / `film_used`) is DELETED, not disabled.
##
## WHY FIVE, MEASURED THAT ROUND (kept for the history; superseded below, 2026-09-22): the FILM
## round justified 5 with a re-run of ten auto-piloted flights over five lanes - four plates lost a
## fully-held sight to the magazine on grig->vela, five never did, six and seven were never touched.
##
## THE OLD DUPLICATE, AND WHY IT IS GONE (SAFARI_FLIGHT_SPEC.md item 5, 2026-09-22, G4). This
## constant used to live HERE, live at 5, while `SafariScoring.FILM_BASE` sat dead at 4 in another
## builder's file - a known papercut the lead flagged rather than silently picking one. There is
## now ONE constant: `SafariScoring.FILM_BASE`, re-measured and re-sized for the R4 rebuild's
## 14-18 sight casts (see that file's own FILM section for the derivation). This name is KEPT, as
## an alias, only because `showcase/rev_film_probe.gd` still reads `GameState.FILM_BASE` directly -
## the value can never again drift from SafariScoring's, because it is not a second number, it is
## the same number under two names.
const FILM_BASE := SafariScoring.FILM_BASE
## THE UPGRADE (point 4). The one real way to carry more than FILM_BASE: a one-time camera upgrade,
## bought with stardust, that raises capacity for every trip after.
##
## ROUND 2 CORRECTION: the "60-200 stardust a flight" this comment used to cite was never measured
## and CORE_LOOP.md has no safari, film or stardust figure at all - the round-1 critic caught both.
## The real number, measured this round (`showcase/film_price_probe.gd`, a real auto-piloted
## home_zorp flight through the actual `SafariHaul` sale path, PrintBag's own pricing, no fitted
## constant): a clean flight sells its catch for 292 dust at film=5 (this round's default) and 255
## at film=4 (one fewer plate, one fewer sight landed) - both printed as "SAFARI LANDED: ... worth
## N dust". FILM_UPGRADE_COST is priced against THAT range: more than the best single haul (292)
## but less than two of the worst (2 * 255 = 510) - a save-up goal across a couple of flights, not
## a toll on every one. Capped at FILM_UPGRADE_MAX buys so the choice point 3 is built around never
## goes away entirely.
const FILM_UPGRADE_COST := 340
const FILM_UPGRADE_ADD := 2
const FILM_UPGRADE_MAX := 2

var current_planet_id: String = "home"
var previous_planet_id: String = ""

var stardust: int = STARTING_STARDUST
## Asteroid rubble and bits of the broken ship (CORE_LOOP.md "Scrap and stardust"). The campaign's
## building currency: fitting a rocket part and building world-problem fixes both cost scrap.
var scrap: int = STARTING_SCRAP

## item_id -> count. Items are decorations, clothing, collectibles, favor items.
var inventory: Dictionary = {}

## planet_id -> Array of {"id": String, "item": String, "pos": [x,y,z], "basis": [9 floats]}
## pos/basis are LOCAL to the planet node.
var placed_decorations: Dictionary = {"home": [], "zorp": [], "bolt": [], "hub": [], "fen": [], "grig": [],
	"vela": []}

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

## Part id Strings (CampaignData.PARTS), in the order fitted. Parts are internal to the rocket
## (BUILD_PLAN.md "Revised the same day") - this array drives both `CampaignData.finish_stage()`
## (the rocket's rusty-to-gold look) and `CampaignData.planet_in_range()` (the range gate).
var rocket_parts: Array = []
## True only for a new game played as the "Stranded" campaign. False for every old save (see
## `from_dict`), which is how an old save gets today's open world with no gates.
var campaign_active: bool = false
## True once the campaign's ending has played, AND true by default for any save that predates the
## campaign fields (see `from_dict`) - both mean "no gates, every planet open, today's rocket".
var story_done: bool = false
## npc_id -> in-game day index (GameState.day_count) of that neighbour's last project step.
## CORE_LOOP.md "Pacing": one project step per neighbour per in-game day. Phase 2 reads this to
## tell whether a neighbour's next step is available yet or "come back tomorrow".
var project_step_day: Dictionary = {}
## Phase 2 project state (docs/BUILD_PLAN.md builder E): npc_id -> whatever src/projects/project_system.gd
## needs to resume a neighbour's multi-step project (current step, found markers, ...). The shape is
## owned by project_system.gd; GameState only stores and saves it. Added by the lead before Phase 2 so
## builder E owns only its own files. A save without it (every save before Phase 2) loads as {}.
var projects: Dictionary = {}

## favor_id -> {"npc": String, "type": String, "target_item": String, "count": int, "progress": int, "state": "offered|active|done", "reward_item": String, "reward_stardust": int, "deliver_to": String}
var favors: Dictionary = {}

## Time of day in hours (0..24). Day cycle length in real minutes lives in day_night.gd.
var time_of_day: float = 9.5
var day_count: int = 1

## FILM builder pass: how many camera upgrades have been bought. WIRE round: the cap and the cost
## are SafariScoring's (FILM_UPGRADE_MAX_TIER 2, FILM_UPGRADE_COSTS [400, 850] scrap), not the FILM
## round's own 2 x 340 stardust - "film numbers come from SafariScoring".
var film_upgrades: int = 0
## DAY round: `film_day` / `film_used` (the WIRE round's day box) ARE GONE. There is no per-day
## film state left to persist, because there is no per-day film. A save that still carries those
## two keys just ignores them (see `from_dict`), and a save written now does not write them.

## Planet display name chosen at Town Hall.
var home_planet_name: String = "Little Orbit"

## How big the player's own world is, as an INDEX into PlanetData.HOME_RADII (0 = the starting
## planet). STYLE_GUIDE R2.11: the starting planets shrank so more of your own world fits on screen,
## and "expand your planet" is a later upgrade — shipping the size as persisted data now means that
## upgrade is `GameState.home_planet_size += 1` and nothing else. Only the home planet reads this;
## Zorp, Bolt and the hub keep the radius in their own .tres. Resolved by PlanetData.resolve_size().
var home_planet_size: int = 0

## SCRAP PRICE of each step up PlanetData.HOME_RADII: [0]->[1], [1]->[2], [2]->[3]. Scrap, because
## past the five rocket parts (40 scrap) the campaign's building currency has no sink at all while
## the worlds keep dropping it (docs/OPEN_ISSUES.md 66).
##
## MEASURED 2026-09-20 in the engine, `godot --headless res://src/world/world.tscn --
## --planet=home --director=res://tests/director/grow_income.json` (grow_probe.gd `income` builds
## all seven worlds and counts the scrap the scatter ACTUALLY places — the .tres files understate
## it, because planet_props appends 5 stardust pickups per world on top of `collectible_count`):
##   home 8 + hub 8 + zorp/bolt/fen/grig/vela 2 each = 26 scrap pickups a game day
##   x 4.5 (mean of Collectible's randi_range(3, 6))  = 117 scrap a game day
##   environment.gd DAY_LENGTH_SEC 1500 s             = 2.40 game days a real hour
##                                                    = 281 scrap/real hour from a full sweep
##   + home's trash, one piece per 900 s x 7.0 mean   =  28 scrap/real hour
##   TOTAL 309 scrap a real hour.
## (117/day matches the 78-156 a day docs/OPEN_ISSUES.md 66 measured, which is the same full-sweep
## player: 26 pickups x 3 to 26 x 6.)
## Priced at 1.5 / 4.5 / 10 hours CUMULATIVE against that 309/hour — round(hours x 309), no fitted
## constant and no free parameter:
##   level 1   450 scrap    1.5 h            (the brief's 1-2 h)
##   level 2   950 scrap    4.5 h cumulative
##   level 3  1700 scrap   10.0 h cumulative (the brief's 8-12 h to the top)
## A player who only works home and the hub earns 201/hour (16 pickups + trash), which stretches
## those to 2.2 h and 15.4 h. Re-measure with `income` before moving these: the day length and the
## collectible mix have both moved this month.
const HOME_SIZE_COSTS: Array[int] = [450, 950, 1700]

## Highest index `home_planet_size` can reach.
func home_size_max() -> int:
	return PlanetData.HOME_RADII.size() - 1

func home_size_at_max() -> bool:
	return home_planet_size >= home_size_max()

## Scrap price of the NEXT step up, or 0 when the planet is already as big as it gets.
func home_size_cost() -> int:
	if home_size_at_max() or home_planet_size >= HOME_SIZE_COSTS.size():
		return 0
	return HOME_SIZE_COSTS[home_planet_size]

func can_grow_home() -> bool:
	return not home_size_at_max() and can_afford_scrap(home_size_cost())

## Pays for one step up and takes it. Data only — the world is grown by `Planet.regrow()`, which the
## caller runs next so the player watches the ground move; nothing here touches the scene.
## Returns false, having changed nothing, when the planet is at its biggest or the scrap is short.
func grow_home() -> bool:
	if not can_grow_home():
		return false
	if not spend_scrap(home_size_cost()):
		return false
	home_planet_size += 1
	return true

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

# ----------------------------------------------------------------------------- scrap (campaign)
## Mirrors `add_stardust` - same clamp-at-zero, same "signal carries the delta" shape.
func add_scrap(amount: int) -> void:
	scrap = max(0, scrap + amount)
	EventBus.scrap_changed.emit(scrap, amount)

func can_afford_scrap(amount: int) -> bool:
	return scrap >= amount

func spend_scrap(amount: int) -> bool:
	if not can_afford_scrap(amount):
		return false
	add_scrap(-amount)
	return true

# ----------------------------------------------------------------------------- rocket parts (campaign)
## Appends `part_id` if it is not already fitted. Returns false, with no signal, for a part already
## fitted - fitting is a one-way, idempotent action, not something to re-trigger the celebration or
## the finish-stage change for.
func fit_rocket_part(part_id: String) -> bool:
	if rocket_parts.has(part_id):
		return false
	rocket_parts.append(part_id)
	EventBus.rocket_parts_changed.emit(rocket_parts.size())
	return true

func rocket_part_count() -> int:
	return rocket_parts.size()

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

# ----------------------------------------------------------------------------- safari film
## DAY round (2026-09-21): FILM IS PER TRIP. The store holds exactly one number - how many
## permanent camera upgrades have been bought - and every flight loads `film_capacity()` plates,
## always, however many flights the day has already held.
##
## WHERE THE NUMBERS COME FROM, ONE PLACE NOW (SAFARI_FLIGHT_SPEC.md item 5, 2026-09-22, G4): all
## of it is `SafariScoring` - `FILM_BASE` (10), `FILM_UPGRADE_COSTS`/`FILM_UPGRADE_MAX_TIER`/
## `FILM_UPGRADE_STEP` (400 then 850 scrap, 2 tiers, +3 plates a tier) and `FILM_BUY_PRICE`/
## `FILM_BUY_MAX` (23 dust, up to 4). This file used to carry its own live `FILM_BASE` (5) beside
## SafariScoring's dead one (4) - the papercut the lead flagged rather than silently pick a side on.
## `FILM_BASE` here is now an alias (see its own comment, above `film_upgrades`), so there is one
## number, not two that can drift apart again.

## THE CEILING ON ONE TRIP'S MAGAZINE. RE-SIZED FOR THE R4 REBUILD (SAFARI_FLIGHT_SPEC.md #6.3,
## 2026-09-22, G4): 16, so it lands exactly where a full upgrade tops out (FILM_BASE 10 +
## FILM_UPGRADE_MAX_TIER(2) * FILM_UPGRADE_STEP(3) = 16) - the same relationship this constant had
## before (7 == old FILM_BASE(5) + old MAX_TIER(2), each tier +1), just at the new scale. That
## keeps `film_spare_max()`'s "a fully upgraded camera is offered no spares" true without a second
## number to keep in sync.
##
## WHAT IS NOT RE-VERIFIED: the OLD 7 was sized to the cockpit's own pixel budget (measured
## `--ui=mobile` capture, `dayshop/shop_cabin.png`: a 191 px band, 21.4 px a plate, 7 fits at 178 px
## and 8 already trips the "too tight" fallback). 16 plates is far past that budget on the same
## math (16 plates + toast is well over 300 px) - but the plate stack is DRAWN in `safari_run.gd`
## (SAFARI_FLIGHT_SPEC.md #7.3 moved that deliverable to whoever owns that file, not this one), so
## whether 16 plates actually fits the hull is UNPROVEN by this file and belongs in needs_from_others.
const PLATES_MAX := 16

## Plates loaded for a trip - EVERY trip, with no day box in front of it. Upgrades raise this for
## every flight after, which is what "buying or upgrading raises the plates PER TRIP" means.
## Each tier now adds SafariScoring.FILM_UPGRADE_STEP (3) plates, not 1 - see FILM_BASE's comment.
func film_capacity() -> int:
	return mini(PLATES_MAX,
		FILM_BASE + clampi(film_upgrades, 0, SafariScoring.FILM_UPGRADE_MAX_TIER)
			* SafariScoring.FILM_UPGRADE_STEP)


## How many spare plates this trip may still be sold, on top of `film_capacity()`. SafariScoring
## prices them (FILM_BUY_PRICE) and caps them (FILM_BUY_MAX 4); PLATES_MAX caps them again, so a
## fully upgraded camera (16) is offered none - the scrap ladder has already bought, for ever, what
## the dust was renting one flight at a time. At 0 upgrades the offer is the full FILM_BUY_MAX (4),
## since PLATES_MAX(16) - film_capacity()(10) = 6 is already past it; only after the first upgrade
## tier does PLATES_MAX itself start pinching the offer below FILM_BUY_MAX.
func film_spare_max() -> int:
	return clampi(PLATES_MAX - film_capacity(), 0, SafariScoring.FILM_BUY_MAX)


## DEPRECATED NAME, KEPT SO NOTHING ELSE HAD TO CHANGE. There is no "today" any more: this returns
## the same full magazine `film_capacity()` does, so a caller that shows "film N of M" (the pad's
## `[PadTime]` line, the run's startup print, the reload probes) now always reads "10 of 10" (0
## upgrades) - which is the truth, not a rounding of it.
func film_left_today() -> int:
	return film_capacity()


## DEPRECATED, AND DELIBERATELY A NO-OP. Plates do not carry over, so a landed flight has nothing
## to book against tomorrow. Left callable because showcase probes still call it; the fact that it
## changes nothing IS the "plates never carry over" rule, and a test can check it that way.
func spend_film(_n: int) -> void:
	pass


func film_upgrade_available() -> bool:
	return film_upgrades < SafariScoring.FILM_UPGRADE_MAX_TIER


## Spends the next tier's SCRAP (SafariScoring.film_upgrade_cost) to raise `film_capacity()` by
## FILM_UPGRADE_STEP plates ON EVERY TRIP, permanently: 10 -> 13 -> 16. Returns false, spending
## nothing, if maxed or unaffordable. DAY round: it used to read "one plate a day"; the plates it
## buys are per trip now.
func buy_film_upgrade() -> bool:
	if not film_upgrade_available():
		return false
	var cost := SafariScoring.film_upgrade_cost(film_upgrades)
	if cost < 0 or not spend_scrap(cost):
		return false
	film_upgrades += 1
	return true

# ----------------------------------------------------------------------------- the day clock
## DAY round (2026-09-21): ADVANCE THE CLOCK FROM OUTSIDE A WORLD SCENE.
##
## `src/world/environment.gd` owns the clock while you are standing on a planet, and it already
## bills the day for the real seconds a rocket hop took (`_charge_absence`). But a photo safari is
## not a hop: the flight IS the game, so it costs the day more than the seconds it took (the whole
## of `src/sky/safari_transit.gd`'s PHOTO_TRIP_HOURS). That extra has to be added while no
## Environment exists at all, and `time_of_day` / `day_count` live here, so the wrap and the day
## rollover live here too instead of being copied into the flight scene.
##
## Same arithmetic environment.gd `_advance` does: wrap at 24 and carry the whole days.
func advance_clock(hours: float) -> void:
	if hours <= 0.0:
		return
	var h := time_of_day + hours
	if h >= 24.0:
		day_count += int(floor(h / 24.0))
	time_of_day = fposmod(h, 24.0)


# ----------------------------------------------------------------------------- serialization
func to_dict() -> Dictionary:
	return {
		"version": 1,
		"current_planet_id": current_planet_id,
		"previous_planet_id": previous_planet_id,
		"stardust": stardust,
		"scrap": scrap,
		"inventory": inventory,
		"placed_decorations": placed_decorations,
		"player_style": player_style,
		"npcs": npcs,
		"favors": favors,
		"rocket_parts": rocket_parts,
		"campaign_active": campaign_active,
		"story_done": story_done,
		"project_step_day": project_step_day,
		"projects": projects,
		"time_of_day": time_of_day,
		"day_count": day_count,
		"film_upgrades": film_upgrades,
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
	scrap = int(d.get("scrap", 0))
	inventory = _ints(d.get("inventory", {}))
	placed_decorations = d.get("placed_decorations",
		{"home": [], "zorp": [], "bolt": [], "hub": [], "fen": [], "grig": [], "vela": []})
	for pid in PLANET_IDS:
		if not placed_decorations.has(pid):
			placed_decorations[pid] = []
	player_style = d.get("player_style", player_style)
	npcs = _deep_ints(d.get("npcs", {}))
	favors = _deep_ints(d.get("favors", {}))
	rocket_parts = d.get("rocket_parts", [])
	# Missing key means one of two things, both correctly "story finished": a save written
	# before the campaign fields existed, or `reset_new_game()`'s own `from_dict({})` call
	# before it overrides these for a real new game (see `reset_new_game`).
	campaign_active = bool(d.get("campaign_active", false))
	story_done = bool(d.get("story_done", true))
	project_step_day = _ints(d.get("project_step_day", {}))
	var _pj = d.get("projects", {})
	projects = _pj if _pj is Dictionary else {}
	time_of_day = float(d.get("time_of_day", 9.5))
	day_count = int(d.get("day_count", 1))
	# A save from before this round, or from the old per-day box, has no key here: 0 upgrades bought,
	# the honest default - it does not owe anyone a free upgrade they never paid for.
	film_upgrades = clampi(int(d.get("film_upgrades", 0)), 0, SafariScoring.FILM_UPGRADE_MAX_TIER)
	# DAY round: a save written by the WIRE round still has "film_day"/"film_used" in it. They are
	# read by nobody now - film is per trip - so they are dropped on the floor here and not written
	# back out. A player mid-day in an old save gets a full magazine on their next flight, which is
	# the new rule applied honestly rather than a debt carried across a rule change.
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
	# So the range picker and the rocket's finish re-read after ANY load, not just a fresh new
	# game: SaveManager.load_game() calls this directly and owns no signal of its own. This also
	# fires once, with the "story finished" defaults above, from `reset_new_game()`'s own
	# `from_dict({})` call - harmless, since that function emits both again once it has overridden
	# campaign_active/story_done/rocket_parts to the real new-game values (see `reset_new_game`).
	EventBus.campaign_changed.emit()
	EventBus.rocket_parts_changed.emit(rocket_parts.size())

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
	# THE TRAP: `from_dict({})` reads every campaign field as missing, which by design (see the
	# comment in `from_dict`) loads as "story finished" - campaign_active false, story_done true,
	# gates off. That is correct for an old save; it is backwards for a brand new one. Every
	# campaign field this function cares about MUST be set again below, AFTER this call, or a new
	# game would boot with the gates already off.
	from_dict({})
	stardust = STARTING_STARDUST
	# Starter kit so the first minute of play already has something to place.
	inventory = {"deco_moon_lamp": 1, "deco_star_flag": 1, "deco_crater_bench": 1}
	# Turn the trap's defaults back around: a new game plays the campaign from a clean slate.
	campaign_active = true
	story_done = false
	scrap = STARTING_SCRAP
	rocket_parts = []
	project_step_day = {}
	projects = {}
	# `from_dict({})` already emitted both signals once, above, with the (wrong, pre-override)
	# "story finished" state - re-emit now that campaign_active/story_done/scrap/rocket_parts hold
	# the real new-game values, so anything listening (the range picker, the rocket's finish) ends
	# up showing gates ON, not the momentary off state from the `from_dict({})` call.
	EventBus.campaign_changed.emit()
	EventBus.rocket_parts_changed.emit(rocket_parts.size())
