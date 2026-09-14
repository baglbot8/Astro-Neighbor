extends Node
## FRIENDS VISIT YOUR CRASH SITE (docs/CORE_LOOP.md "Visits and favours", decided 2026-09-13;
## docs/BUILD_PLAN.md Phase 4 builder H). The user: "No mayor. Neighbours visit your crash site and ask
## you for things themselves."
##
## Some game days, one neighbour is standing near the crash site when you are at home. They ask for ONE
## thing that needs no flight: play their mini-game on your planet, or place a gift they brought. Flying
## away ends the visit, so a neighbour is always at home when you fly to their world.
##
## ============================================================================== WHERE IT LIVES
## ONE NODE PER WORLD, made by the single guarded hook at the end of world.gd `_ready`:
##
##     if ResourceLoader.exists(VISITOR_SYSTEM_PATH):
##         load(VISITOR_SYSTEM_PATH).attach(self)
##
## It is /root/World/VisitorSystem and it dies with the world, and so does the visitor (an ordinary
## neighbour scene, res://src/characters/npcs/<id>.tscn, added under /root/World/NPCs). On home it
## decides today's visit and stands the visitor; on every OTHER world it only marks today's visit as
## ended ("flying away ends the visit"). Nothing else in the game names this file statically:
## conversation.gd and npc.gd reach it through the NPC's `visit_host` field, and dev_menu.gd by path.
##
## ============================================================================== WHO AND WHEN
##   * Only the five story neighbours (CampaignData.PARTS: zorp, bolt, fen, grig, vela), and only once
##     their project has started (GameState.projects has them). The Commons crowd never visits.
##   * Only on home, and only while the campaign is on or the story is over (`visits_on`). A Director
##     timeline sees no visits unless it passes "--campaign", the same opt-in as every campaign gate.
##   * AT MOST ONE VISIT PER GAME DAY, chosen by rolls SEEDED BY THE DAY, never by the clock or a live
##     position (`is_visit_day`, `roll_visitor`):
##       - the days are cut into blocks of VISIT_EVERY_DAYS; one day in each block, picked by a roll
##         seeded by the block, is a visit day. With 2 that is exactly one visit day in every two, on
##         average every other day, never more than three days apart;
##       - on a visit day a second roll, seeded by the day, picks one eligible neighbour, leaving out
##         yesterday's visitor, so nobody comes two days running.
##     The result is written the first time you are at home that day (`ensure_today`), and a written day
##     is never rolled again, so a reload can never reroll it and a finished visit stays finished.
##   * Never while the crash intro or Professor Comet's radio call owns the screen (`_onboarding_busy`):
##     a home load before the call has happened gets no visit that stay, and writes nothing.
##   * THE VISITOR STAYS FOR THE WHOLE STAY AT HOME. A day that turns over while you are home does not
##     send them away or bring someone new; the next landing at home rolls the day it is by then.
##   * FLYING AWAY ENDS IT: EventBus.travel_started from home, and any load of another world, set "left".
##     A visit that has left never comes back that day, done or not.
##
## ============================================================================== THE REQUEST
## One per visit, planned when the day is written (`_plan_request`, seeded by day and neighbour):
##   PLAY  only when that neighbour's mini-game is unlocked (ProjectSystem.played_minigames()), about
##         PLAY_CHANCE of the time. It runs on home with the story step's own config, minus the keys that
##         only fit their world ("home_dir", "near", "center_dir", "dirs"), with "npc" set to the visitor
##         (the caller of "call"), a count of min(story count, VISIT_COUNT_MAX[kind]), and the owner
##         "visit:<npc>:<day>". Rings and hunt get "near" = the visitor's spot, so the course and the
##         search start by the visitor rather than on the far side of the planet. The game starts when
##         the request is asked, restarts on a reload or after being cancelled (on the next talk), and
##         its progress is written to the visit flag on every `progress_changed`, the same rule the
##         project system follows: the count is the truth, never the finish signal.
##   GIFT  otherwise. The visitor hands over one decoration from visitor_lines.gd GIFTS (existing shop
##         items; the file says which and why). The visit is met once an instance of that item stands
##         on home that was not standing there when it was handed over. A dropped gift is replaced.
## Talking again once it is met hands it in: friendship +VISIT_FRIENDSHIP and +VISIT_STARDUST stardust.
## Later talks that day get a goodbye line.
##
## TALK: conversation.gd sends every talk with the visitor here (`handle_conversation`) - never to their
## project, a light link, a favour or small talk. Lines live in visitor_lines.gd, in each neighbour's
## own voice, <= 60 characters, 1-3 per list. THE "!": npc.gd asks `wants_marker` - shown while the
## request waits to be asked, and again once it is met and waits to be handed in.
##
## ============================================================================== SAVED STATE
## ONE JSON-safe flag, GameState.flags["visit_today"], and no new GameState field. It holds the most
## recently written day (JSON gives ints back as floats; `record` normalises every read):
##   {"day": int, "npc": id or "" (no visit that day), "kind": "play"|"gift"|"",
##    "game": kind, "step": story step index, "count": int, "progress": int,
##    "item": catalog id, "before": [instance ids of that item already on home when it was handed over],
##    "asked": bool, "done": bool, "left": bool, "forced": bool (dev menu),
##    "spot": [x,y,z] planet-local direction the visitor stands at, or []}
## The spot is saved so a reload stands the visitor in the same place; it is re-checked against the
## ground rules on every load and picked again only if something (a decoration) now stands on it.
##
## ============================================================================== WHERE THEY STAND
## `_pick_spot`, run once per home load (and never when the saved spot still passes):
##   1. "framed": a SEARCH_STEP_M lattice in front of the rocket-landing spot (world.gd puts the
##      astronaut LANDING_SIDE_M off the pad, facing away from it), nearest IDEAL_AHEAD_M ahead and
##      IDEAL_SIDE_M toward the spawn first.
##      A spot passes when the ground rules pass AND both landing cameras (phone and desktop, rebuilt from
##      camera_rig.gd's own numbers, as replay_board_prop.gd does) have the visitor - where they stand and
##      at WANDER_RING points round the rim of their wander patch - inside the safe part of the frame, with
##      every sight line clear of the real triangles of props, decorations, the house, the pad, the rocket
##      at rest, the bench, space trash and the landed astronaut (glow sprites hide nothing: `_is_glow`).
##   2. "framed-spot": the same lattice, when a crowded yard leaves nothing for pass 1: the whole wander
##      patch still inside the frame, but only the sight lines to where they stand have to be clear.
##   3. "near": the ground rules alone on a wider lattice round the landing spot.
##   4. "anywhere": the ground rules alone over the whole planet, nearest the landing spot first.
## THE GROUND RULES (`_ground_problem`): dry, not at the shore; PAD_CLEAR_M from the pad centre (the pad
## disc and its paving); SPAWN_CLEAR_M from the spawn; LANDING_CLEAR_M from the landing spot; off the
## stepping stones (TRAIL_CLEAR_M from their line, over the stretch they cover); HOUSE_CLEAR_M from the
## house; out of every prompt's reach (the bench, the mailbox, the door, the pad) by PROMPT_GAP_M; clear
## of props, decorations, pickups and space trash; level enough to stand on.
## WANDERING A LITTLE: the visitor's wander radius is WANDER_M (npc.gd samples 1.4-1.6 m out), and npc.gd
## asks `wander_ok` for every wander target and every path sample, so they never walk onto anything the
## ground rules keep them off either.
##
## ============================================================================== DEPENDENCIES
## ProjectSystem and MinigameSystem are reached by PATH only (a file that can ship without its dependency
## never names that class statically). Everything else used here ships in every build since Phase 1.

const NODE_NAME := "VisitorSystem"
const SCRIPT_PATH := "res://src/campaign/visitor_system.gd"
const DATA := preload("res://src/campaign/visitor_lines.gd")
const PROJECT_SYSTEM_PATH := "res://src/projects/project_system.gd"
const MINIGAME_SYSTEM_PATH := "res://src/minigames/minigame_system.gd"
const CAMERA_RIG_PATH := "res://src/player/camera_rig.gd"
const NPC_DIR := "res://src/characters/npcs/"
const HOME_ID := "home"
const FLAG_KEY := "visit_today"
const OWNER_PREFIX := "visit:"

## ---- PHASE 6 PACING NUMBERS (docs/BUILD_PLAN.md "Phase 6: Pacing pass"): first guesses, to be tuned
## from a timed play-through. None of them is a promise to the player.
## One visit day in every this many game days ("about every other day").
const VISIT_EVERY_DAYS := 2
## How often a visitor whose game is unlocked asks for the game rather than a gift.
const PLAY_CHANCE := 0.5
## Friendship for a visit handed in. A project step gives 5 (ProjectSystem.FRIENDSHIP_PER_STEP), a favour 2.
const VISIT_FRIENDSHIP := 3
## Stardust for a visit handed in. A replay pays 10 (replay_board.gd), a favour 60-140 (being reworked).
const VISIT_STARDUST := 15
## A visit's game is never longer than the story's, and shorter where the story's is long. The ring run
## cannot go under 4 (ring_game.gd COUNT_RANGE).
const VISIT_COUNT_MAX := {"catch": 3, "rings": 4, "guide": 3, "hunt": 2, "call": 2}

## ---- placement (see "WHERE THEY STAND")
## world.gd `_spawn_player`: a rocket arrival stands the astronaut this far off the pad centre.
const LANDING_SIDE_M := 3.2
const WANDER_M := 1.6
const SEARCH_STEP_M := 0.4
const AHEAD_MIN_M := 3.2
const AHEAD_MAX_M := 9.0
const SIDE_MAX_M := 5.0
const IDEAL_AHEAD_M := 4.0
## ...and this far to the side the spawn is on, so the visitor is not straight behind the astronaut's
## helmet in the landing frame and is nearer where a loaded save stands the player.
const IDEAL_SIDE_M := 2.4
const NEAR_MAX_M := 12.0
## rocket_pad.gd PAD_R 2.55 m of disc + its paving (planet.gd PAD_FLAT_RADIUS 4.0) + a body.
const PAD_CLEAR_M := 4.6
## A loaded save stands the player at the spawn; planet.gd SPAWN_FLAT_RADIUS 3.0 + the 0.6 m it reserves.
const SPAWN_CLEAR_M := 3.6
## Out of the landed astronaut's face: NPC.TALK_REACH 2.2 + a body + a step, so the landing prompt is Fly.
const LANDING_CLEAR_M := 3.2
## The stones: 0.5 m stone radius + a 0.34 m body + 0.46 m to walk past (replay_board_prop.gd keeps 2.05
## for a 0.95 m board).
const TRAIL_CLEAR_M := 1.3
## planet.gd reserves HOME_BUILDING_FLAT_RADIUS 5.0 + 1.0 round the house.
const HOUSE_CLEAR_M := 6.0
const PROMPT_GAP_M := 0.8
const PROP_CLEAR_M := 0.6
const DECO_GAP_M := 0.6
const PICKUP_CLEAR_M := 0.9
const TRASH_CLEAR_M := 1.1
const MAX_SLOPE_DEG := 14.0
const MAX_RIM_DH_M := 0.2
const RIM_M := 0.5
## ---- the landing frame (the same numbers replay_board_prop.gd was measured against)
const LANDING_FOV_DEG := 45.0
const VIEW_ASPECTS := {"mobile": 1560.0 / 720.0, "desktop": 1280.0 / 720.0}
const VIEW_SAFE := {"mobile": Rect2(-0.6, -0.5, 1.2, 1.3), "desktop": Rect2(-0.85, -0.55, 1.7, 1.35)}
const VIEW_KEEP_OUT := {"mobile": Rect2(-0.14, 0.6, 0.28, 0.4)}
## Visitor column: sight lines to these heights at these side offsets; the frame test uses the column's
## corners. The tallest visitor (Grig's eye stalk) reaches 1.77 m.
const SIGHT_HEIGHTS: Array[float] = [0.5, 0.95, 1.35]
const SIGHT_SIDES: Array[float] = [-0.22, 0.0, 0.22]
const COLUMN_TOP_M := 1.8
## Points round the rim of the wander patch that the frame rule also checks.
const WANDER_RING := 8
const COLUMN_HALF_M := 0.4
const LOW_MESH_M := 0.4
const ASTRONAUT_RADIUS_M := 0.45
const ASTRONAUT_HEIGHT_M := 1.6
const PAD_DECK_Y := 0.10

var planet: Planet
## The visitor standing on this world now, or null.
var visitor: NPC
## Which pass of `_pick_spot` stood the visitor ("saved" when the saved spot still passed), and a note.
var spot_pass := ""
var spot_note := ""
var search_usec := 0

var _owner := ""
var _game_pending := false
var _views: Array[Dictionary] = []
var _landing_dir := Vector3.ZERO
var _away := Vector3.ZERO
var _astronaut_xf := Transform3D.IDENTITY
var _deco_cache: Array[Dictionary] = []
var _prompts: Array[Dictionary] = []
var _space := RID()
var _sight_bodies: Array[RID] = []
var _sight_shapes: Array = []
## Sight body RID -> the node it was built from, for `debug_spot_report` ("what hides them").
var _sight_names: Dictionary = {}


# ============================================================================= entry points
## Called once per world by world.gd. Returns the host (also for a test rig).
static func attach(world: Node) -> Node:
	if world == null or not world.is_inside_tree():
		return null
	var existing := world.get_node_or_null(NODE_NAME)
	if existing != null:
		return existing
	var host: Node = (load(SCRIPT_PATH) as GDScript).new()
	host.name = NODE_NAME
	world.add_child(host)
	return host


## The world's VisitorSystem, or null (no world, or a build without the hook).
static func find() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("World/" + NODE_NAME)


func _ready() -> void:
	planet = get_tree().get_first_node_in_group("planet") as Planet
	EventBus.travel_started.connect(_on_travel_started)
	EventBus.ui_modal_closed.connect(_on_modal_closed)
	EventBus.decoration_placed.connect(_on_decoration_placed)
	EventBus.decoration_removed.connect(_on_decoration_removed)
	if GameState.current_planet_id != HOME_ID:
		mark_left("landed on " + GameState.current_planet_id)
		return
	if planet == null:
		return
	if _onboarding_busy():
		print("VisitorSystem: the intro owns the screen; no visit this stay")
		return
	var rec := ensure_today()
	if rec.is_empty() or str(rec["npc"]) == "" or bool(rec["left"]):
		return
	_bring_in(rec)


func _exit_tree() -> void:
	_close_sight_space()


# ============================================================================= the day
## True when visits can happen at all: the campaign is on, or the story is over (a Director timeline only
## with "--campaign").
static func visits_on() -> bool:
	if CampaignData.gates_on():
		return true
	return GameState.story_done and (not Director.is_active() or Director.campaign_opt_in())


## The story neighbours who may visit: their project has started. In CampaignData.PARTS order.
static func eligible_neighbours() -> PackedStringArray:
	var out := PackedStringArray()
	for p: Dictionary in CampaignData.PARTS:
		var npc := str(p.get("npc", ""))
		if npc == "" or not GameState.projects.has(npc):
			continue
		if not ResourceLoader.exists(NPC_DIR + npc + ".tscn"):
			continue
		if ResourceLoader.exists(PROJECT_SYSTEM_PATH):
			var d: Variant = load(PROJECT_SYSTEM_PATH).call("definition_for", npc)
			if not (d is Dictionary) or (d as Dictionary).is_empty():
				continue
		out.append(npc)
	return out


## True when `day` is its block's visit day (see "WHO AND WHEN"). Pure: depends on the day alone.
static func is_visit_day(day: int) -> bool:
	var d0 := maxi(day, 1) - 1
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(["astro_visit_day", d0 / VISIT_EVERY_DAYS])
	return d0 % VISIT_EVERY_DAYS == rng.randi_range(0, VISIT_EVERY_DAYS - 1)


## Who visits on `day` ("" for nobody). Pure: the day, who may come, and yesterday's visitor.
static func roll_visitor(day: int, eligible: PackedStringArray, yesterday: String) -> String:
	if not is_visit_day(day):
		return ""
	var pool: Array[String] = []
	for n: String in eligible:
		if n != yesterday:
			pool.append(n)
	if pool.is_empty():
		return ""
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(["astro_visit_who", day])
	return pool[rng.randi_range(0, pool.size() - 1)]


## Today's visit record, rolled and written the first time it is asked for on this game day. {} when
## visits are off (nothing is written then).
static func ensure_today() -> Dictionary:
	var rec := record()
	var day := GameState.day_count
	if not rec.is_empty() and int(rec["day"]) == day:
		return rec
	if not visits_on():
		return {}
	var yesterday := str(rec["npc"]) if not rec.is_empty() and int(rec["day"]) == day - 1 else ""
	var fresh := _blank(day, roll_visitor(day, eligible_neighbours(), yesterday))
	if str(fresh["npc"]) != "":
		_plan_request(fresh, "")
	_write(fresh)
	return fresh


## Plans the one request of a visit (see "THE REQUEST"). `force_kind` "play"/"gift" is the dev menu's.
static func _plan_request(rec: Dictionary, force_kind: String) -> void:
	var npc := str(rec["npc"])
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(["astro_visit_request", int(rec["day"]), npc])
	var wants_play := rng.randf() < PLAY_CHANCE
	var game := _game_for(npc, force_kind == "play")
	var kind := force_kind if force_kind != "" else ("play" if wants_play else "gift")
	if kind == "play" and game.is_empty():
		kind = "gift"
	rec["kind"] = kind
	if kind == "play":
		var g := str(game["game"])
		rec["game"] = g
		rec["step"] = int(game["step"])
		rec["count"] = maxi(1, mini(int(game["count"]), int(VISIT_COUNT_MAX.get(g, int(game["count"])))))
		rec["progress"] = 0
	else:
		rec["item"] = _pick_gift(npc, rng)
		rec["count"] = 1


## This neighbour's mini-game step {game, step, count, config}, or {}. Unlocked ones only, unless `any`
## (the dev menu may force a game the story has not unlocked yet). Only kinds this build can start.
static func _game_for(npc: String, any: bool) -> Dictionary:
	if not ResourceLoader.exists(PROJECT_SYSTEM_PATH) or not ResourceLoader.exists(MINIGAME_SYSTEM_PATH):
		return {}
	var ms: Variant = load(MINIGAME_SYSTEM_PATH)
	var played: Variant = load(PROJECT_SYSTEM_PATH).call("played_minigames")
	if played is Array:
		for e: Variant in played:
			if e is Dictionary and str((e as Dictionary).get("npc", "")) == npc \
					and bool(ms.call("has_game", str((e as Dictionary).get("game", "")))):
				return e
	if not any:
		return {}
	var d: Variant = load(PROJECT_SYSTEM_PATH).call("definition_for", npc)
	if d is Dictionary and not (d as Dictionary).is_empty():
		var steps: Array = (d as Dictionary).get("steps", [])
		for i in steps.size():
			var step: Dictionary = steps[i]
			if str(step.get("type", "")) == "minigame" and bool(ms.call("has_game", str(step.get("game", "")))):
				return {"npc": npc, "step": i, "game": str(step.get("game", "")),
					"count": maxi(1, int(step.get("count", 1))),
					"config": (step.get("config", {}) as Dictionary).duplicate(true)}
	return {}


## One gift from the neighbour's list, preferring one not already standing on home.
static func _pick_gift(npc: String, rng: RandomNumberGenerator) -> String:
	var all: Array = []
	for id: Variant in DATA.GIFTS.get(npc, []):
		if Catalog.has_item(str(id)):
			all.append(str(id))
	if all.is_empty():
		return ""
	var standing := {}
	for e: Variant in GameState.placed_decorations.get(HOME_ID, []):
		if e is Dictionary:
			standing[str((e as Dictionary).get("item", ""))] = true
	var fresh: Array = all.filter(func(id: String) -> bool: return not standing.has(id))
	var pool: Array = fresh if not fresh.is_empty() else all
	return str(pool[rng.randi_range(0, pool.size() - 1)])


# ============================================================================= the saved record
## Today's record, normalised (a copy: write it back with `_write`). {} when there is none.
static func record() -> Dictionary:
	var raw: Variant = GameState.flags.get(FLAG_KEY)
	if not (raw is Dictionary):
		return {}
	var r: Dictionary = raw
	var spot: Array = []
	var raw_spot: Variant = r.get("spot", [])
	if raw_spot is Array and (raw_spot as Array).size() == 3:
		spot = [float(raw_spot[0]), float(raw_spot[1]), float(raw_spot[2])]
	var before: Array = []
	var raw_before: Variant = r.get("before", [])
	if raw_before is Array:
		for x: Variant in raw_before:
			before.append(str(x))
	return {
		"day": int(r.get("day", 0)), "npc": str(r.get("npc", "")), "kind": str(r.get("kind", "")),
		"game": str(r.get("game", "")), "step": int(r.get("step", -1)), "count": int(r.get("count", 1)),
		"progress": int(r.get("progress", 0)), "item": str(r.get("item", "")), "before": before,
		"asked": bool(r.get("asked", false)), "done": bool(r.get("done", false)),
		"left": bool(r.get("left", false)), "forced": bool(r.get("forced", false)), "spot": spot,
	}


static func _blank(day: int, npc: String) -> Dictionary:
	return {"day": day, "npc": npc, "kind": "", "game": "", "step": -1, "count": 1, "progress": 0,
		"item": "", "before": [], "asked": false, "done": false, "left": false, "forced": false, "spot": []}


static func _write(rec: Dictionary) -> void:
	GameState.flags[FLAG_KEY] = rec.duplicate(true)


## Ends the recorded visit for good: flying away, or any other world loading.
static func mark_left(why: String = "") -> void:
	var rec := record()
	if rec.is_empty() or str(rec["npc"]) == "" or bool(rec["left"]):
		return
	rec["left"] = true
	_write(rec)
	print("VisitorSystem: %s's visit on day %d ended (%s)" % [rec["npc"], rec["day"], why])


## True when the request is met and waits to be handed in (or was).
static func request_met(rec: Dictionary) -> bool:
	if rec.is_empty():
		return false
	if str(rec["kind"]) == "play":
		return int(rec["progress"]) >= int(rec["count"])
	if str(rec["kind"]) == "gift":
		for e: Variant in GameState.placed_decorations.get(HOME_ID, []):
			if e is Dictionary and str((e as Dictionary).get("item", "")) == str(rec["item"]) \
					and not (rec["before"] as Array).has(str((e as Dictionary).get("id", ""))):
				return true
	return false


static func _placed_ids(item_id: String) -> Array:
	var out: Array = []
	for e: Variant in GameState.placed_decorations.get(HOME_ID, []):
		if e is Dictionary and str((e as Dictionary).get("item", "")) == item_id:
			out.append(str((e as Dictionary).get("id", "")))
	return out


# ============================================================================= the visitor
func is_visitor(npc: Node) -> bool:
	return npc != null and npc == visitor and is_instance_valid(visitor)


## For npc.gd's "!": 1 show, 0 hide.
func wants_marker(npc_id: String) -> int:
	var rec := record()
	if rec.is_empty() or str(rec["npc"]) != npc_id or bool(rec["left"]) or bool(rec["done"]):
		return 0
	if not bool(rec["asked"]):
		return 1
	return 1 if request_met(rec) else 0


## npc.gd asks this for every wander target and path sample of the visitor.
func wander_ok(dir: Vector3) -> bool:
	return _ground_problem(dir) == ""


func _bring_in(rec: Dictionary) -> void:
	var t0 := Time.get_ticks_usec()
	_rebuild_caches()
	var spot := _vec(rec["spot"] as Array)
	if spot != Vector3.ZERO and _ground_problem(spot) == "":
		spot_pass = "saved"
		spot_note = ""
	else:
		spot = _pick_spot()
		if spot == Vector3.ZERO:
			push_warning("VisitorSystem: no ground on home passes the visitor's rules; %s stays away" % rec["npc"])
			return
		rec["spot"] = [spot.x, spot.y, spot.z]
		_write(rec)
	search_usec = Time.get_ticks_usec() - t0
	_spawn_visitor(str(rec["npc"]), spot)
	print("VisitorSystem: %s visits (day %d, %s%s), stood by the '%s' pass %s in %.1f ms" % [rec["npc"], rec["day"],
		rec["kind"], (" " + str(rec["game"]) if str(rec["kind"]) == "play" else " " + str(rec["item"])),
		spot_pass, spot_note, search_usec / 1000.0])
	if str(rec["kind"]) == "play" and bool(rec["asked"]) and not bool(rec["done"]) and not request_met(rec):
		_queue_game()


func _spawn_visitor(npc_id: String, spot: Vector3) -> void:
	var root := get_tree().root.get_node_or_null("World/NPCs")
	var path := NPC_DIR + npc_id + ".tscn"
	if root == null or not ResourceLoader.exists(path):
		return
	if root.has_node(npc_id):
		push_warning("VisitorSystem: %s is already on this world; no second one" % npc_id)
		return
	var n := (load(path) as PackedScene).instantiate()
	var npc := n as NPC
	if npc == null:
		n.free()
		return
	npc.name = npc_id
	npc.visit_host = self
	npc.visit_home = spot
	npc.visit_wander_m = WANDER_M
	root.add_child(npc)
	npc.planet = planet
	visitor = npc


func _despawn_visitor() -> void:
	if visitor != null and is_instance_valid(visitor):
		var p := visitor.get_parent()
		if p != null:
			p.remove_child(visitor)
		visitor.queue_free()
	visitor = null


## The dev menu changed today's visit while this world is up: stand the new one (or nobody) now.
func restage() -> void:
	_stop_game("restaged")
	_despawn_visitor()
	if GameState.current_planet_id != HOME_ID or planet == null:
		return
	var rec := record()
	if rec.is_empty() or int(rec["day"]) != GameState.day_count or str(rec["npc"]) == "" or bool(rec["left"]):
		return
	_bring_in(rec)


func _on_travel_started(from_id: String, _to_id: String) -> void:
	# Only a flight FROM home ends the visit: a dev-forced visit set on another world must survive the
	# flight home that it is waiting for (that world's own load already ended any earlier visit).
	if from_id != HOME_ID:
		return
	_stop_game("flew away")
	mark_left("flew away")


# ============================================================================= talk
## conversation.gd hands every talk with the visitor here. Awaits until the lines are said.
func handle_conversation(runner: DialogueRunner, npc: NPC) -> void:
	var rec := record()
	var id := npc.npc_id
	if rec.is_empty() or str(rec["npc"]) != id or bool(rec["done"]) or bool(rec["left"]):
		await runner.say(npc, DATA.lines(id, "bye"))
		return
	var kind := str(rec["kind"])
	if not bool(rec["asked"]):
		rec["asked"] = true
		if kind == "play":
			_write(rec)
			await runner.say(npc, DATA.lines(id, "ask_play"))
			_queue_game()
		else:
			rec["before"] = _placed_ids(str(rec["item"]))
			_write(rec)
			_give_gift(str(rec["item"]))
			await runner.say(npc, DATA.lines(id, "ask_gift") + [_gift_status()])
			_toast_gift(str(rec["item"]))
		return
	if request_met(rec):
		# Committed before the lines, so a talk cut short can never pay twice or lose the reward.
		rec["done"] = true
		_write(rec)
		GameState.add_friendship(id, VISIT_FRIENDSHIP)
		GameState.add_stardust(VISIT_STARDUST)
		AudioManager.play_sfx("friendship_up", -8.0)
		npc.play_emote("happy")
		await runner.say(npc, DATA.lines(id, "done_" + kind) + ["(You got %d Stardust!)" % VISIT_STARDUST])
		return
	if kind == "play":
		await runner.say(npc, DATA.lines(id, "progress_play") + [_play_status(rec)])
		_queue_game()
	elif GameState.item_count(str(rec["item"])) <= 0:
		_give_gift(str(rec["item"]))
		await runner.say(npc, DATA.lines(id, "again_gift") + [_gift_status()])
		_toast_gift(str(rec["item"]))
	else:
		await runner.say(npc, DATA.lines(id, "progress_gift") + [_gift_status()])


static func _give_gift(item_id: String) -> void:
	if item_id != "":
		GameState.add_item(item_id, 1)


static func _toast_gift(item_id: String) -> void:
	AudioManager.play_sfx("pickup_item")
	var nm := str(Catalog.get_item(item_id).get("name", item_id))
	EventBus.toast_requested.emit("You got a %s!" % nm, item_id)


static func _gift_status() -> String:
	return "(%s, then place it.)" % MobileUI.bag_hint(true)


static func _play_status(rec: Dictionary) -> String:
	return "(%d of %d %s.)" % [mini(int(rec["progress"]), int(rec["count"])), int(rec["count"]),
		str(DATA.STATUS_VERBS.get(str(rec["game"]), "done"))]


func _on_decoration_placed(planet_id: String, _instance_id: String, item_id: String) -> void:
	_on_decorations_changed()
	if planet_id != HOME_ID or visitor == null:
		return
	var rec := record()
	if str(rec.get("kind", "")) == "gift" and str(rec["item"]) == item_id and bool(rec["asked"]) \
			and not bool(rec["done"]) and request_met(rec):
		EventBus.toast_requested.emit("Placed! Go and show %s." % _npc_name(str(rec["npc"])), "heart")


func _on_decoration_removed(_planet_id: String, _instance_id: String) -> void:
	_on_decorations_changed()


func _on_decorations_changed() -> void:
	if visitor != null:
		_rebuild_deco_cache()


# ============================================================================= the game
func _queue_game() -> void:
	_game_pending = true
	call_deferred("_try_start_game")


func _on_modal_closed(_name: String) -> void:
	if _game_pending:
		call_deferred("_try_start_game")


func _try_start_game() -> void:
	if not _game_pending or not is_inside_tree():
		return
	var rec := record()
	if rec.is_empty() or str(rec["kind"]) != "play" or not bool(rec["asked"]) or bool(rec["done"]) \
			or bool(rec["left"]) or request_met(rec) or visitor == null or GameState.current_planet_id != HOME_ID:
		_game_pending = false
		return
	if EventBus.is_modal_open() or not _world_calm():
		return   # the next modal close checks again
	_game_pending = false
	_start_game(rec)


func _start_game(rec: Dictionary) -> void:
	if not ResourceLoader.exists(MINIGAME_SYSTEM_PATH):
		return
	var ms: Node = load(MINIGAME_SYSTEM_PATH).call("get_or_create")
	if ms == null:
		return
	var owner_id := owner_for(rec)
	if bool(ms.call("is_running")):
		var running := str(ms.call("running_owner"))
		if running == owner_id:
			_owner = owner_id
			return
		if running.begins_with("project:"):
			EventBus.toast_requested.emit("Finish the game that is already on first.", "")
			return
	if not ms.is_connected("progress_changed", _on_game_progress):
		ms.connect("progress_changed", _on_game_progress)
	if not ms.is_connected("finished", _on_game_finished):
		ms.connect("finished", _on_game_finished)
	_owner = owner_id
	if not bool(ms.call("start", str(rec["game"]), game_config(rec))):
		_owner = ""
		EventBus.toast_requested.emit("That game couldn't start here.", "")


static func owner_for(rec: Dictionary) -> String:
	return "%s%s:%d" % [OWNER_PREFIX, rec["npc"], rec["day"]]


## The config a visit game starts with (see "THE REQUEST").
static func game_config(rec: Dictionary) -> Dictionary:
	var cfg: Dictionary = {}
	var npc := str(rec["npc"])
	if ResourceLoader.exists(PROJECT_SYSTEM_PATH):
		var d: Variant = load(PROJECT_SYSTEM_PATH).call("definition_for", npc)
		if d is Dictionary:
			var steps: Array = (d as Dictionary).get("steps", [])
			var i := int(rec["step"])
			if i >= 0 and i < steps.size():
				cfg = ((steps[i] as Dictionary).get("config", {}) as Dictionary).duplicate(true)
	# Keys that only fit the neighbour's own world.
	for k: String in ["home_dir", "near", "center_dir", "dirs", "seed"]:
		cfg.erase(k)
	var spot: Array = rec["spot"]
	if spot.size() == 3 and str(rec["game"]) in ["rings", "hunt"]:
		cfg["near"] = spot.duplicate()
	cfg["npc"] = npc
	cfg["count"] = int(rec["count"])
	cfg["done"] = clampi(int(rec["progress"]), 0, int(rec["count"]))
	cfg["owner"] = owner_for(rec)
	return cfg


func _on_game_progress(_kind: String, done: int, total: int) -> void:
	var ms := _minigames()
	if ms == null or _owner == "" or str(ms.call("running_owner")) != _owner:
		return
	var rec := record()
	if rec.is_empty() or owner_for(rec) != _owner or bool(rec["done"]):
		return
	if total > 0:
		rec["count"] = total
	rec["progress"] = clampi(maxi(int(rec["progress"]), done), 0, int(rec["count"]))
	_write(rec)


func _on_game_finished(_kind: String, success: bool, config: Dictionary) -> void:
	if _owner == "" or str(config.get("owner", "")) != _owner:
		return
	_owner = ""
	if not success:
		return
	var rec := record()
	if rec.is_empty() or owner_for(rec) != str(config.get("owner", "")) or bool(rec["done"]):
		return
	rec["progress"] = int(rec["count"])
	_write(rec)
	EventBus.toast_requested.emit("That's all of them! Go and tell %s." % _npc_name(str(rec["npc"])), "")


func _stop_game(reason: String) -> void:
	_game_pending = false
	if _owner == "":
		return
	var ms := _minigames()
	if ms != null:
		ms.call("stop_owner", _owner, reason)
	_owner = ""


func _minigames() -> Node:
	if not ResourceLoader.exists(MINIGAME_SYSTEM_PATH):
		return null
	return load(MINIGAME_SYSTEM_PATH).call("find")


## Same rule as replay_board.gd: nothing mid-flight or mid-landing, and the player really in control.
func _world_calm() -> bool:
	if SceneRouter.is_busy() or RocketJourney.switching or GameState.flag("rocket_arriving"):
		return false
	var p := get_tree().get_first_node_in_group("player") as Player
	return p != null and p.is_inside_tree() and p.is_physics_processing() and p.input_enabled


func _onboarding_busy() -> bool:
	var ob := get_tree().root.get_node_or_null("World/Onboarding")
	if ob == null:
		return false
	if ob.get("_crashing") == true or ob.get("_greeting") == true:
		return true
	if ob.has_method("_intro_allowed") and not bool(ob.call("_intro_allowed")):
		return false
	# The crash and the radio call both come before "intro_greeted" (intro_director.gd), at home.
	return not GameState.flag("intro_greeted") and not GameState.flag("intro_done")


# ============================================================================= where they stand
func _rebuild_caches() -> void:
	_build_views()
	_rebuild_deco_cache()
	_prompts.clear()
	var root := get_tree().root
	var deco := root.get_node_or_null("World/Decorations")
	var npcs := root.get_node_or_null("World/NPCs")
	for n: Node in get_tree().get_nodes_in_group("interactables"):
		var it := n as Interactable
		if it == null or not it.is_inside_tree():
			continue
		if (deco != null and deco.is_ancestor_of(it)) or (npcs != null and npcs.is_ancestor_of(it)):
			continue
		if planet.collectibles_root != null and planet.collectibles_root.is_ancestor_of(it):
			continue
		var trash := root.get_node_or_null("World/TrashField")
		if trash != null and trash.is_ancestor_of(it):
			continue
		_prompts.append({"pos": it.global_position, "reach": it.reach, "name": str(it.name)})


func _rebuild_deco_cache() -> void:
	_deco_cache.clear()
	var deco := get_tree().root.get_node_or_null("World/Decorations")
	if deco != null and deco.has_method("get_instances"):
		for r: Dictionary in deco.call("get_instances"):
			_deco_cache.append({"dir": r["dir"], "footprint": float(r["footprint"])})


## "" when the visitor may stand at `d`, otherwise the first rule it breaks (see "THE GROUND RULES").
func _ground_problem(dir: Vector3) -> String:
	if planet == null or planet.data == null:
		return "no planet"
	var d := dir.normalized()
	if planet.is_underwater(d):
		return "water"
	var wr := planet.water_radius()
	if wr > 0.0 and planet.height_at(d) < wr + 0.3:
		return "shore"
	var pad := planet.data.pad_dir.normalized()
	var spawn := planet.data.spawn_dir.normalized()
	if planet.surface_distance(d, pad) < PAD_CLEAR_M:
		return "pad"
	if planet.surface_distance(d, spawn) < SPAWN_CLEAR_M:
		return "spawn"
	if _landing_dir != Vector3.ZERO and planet.surface_distance(d, _landing_dir) < LANDING_CLEAR_M:
		return "landing"
	var n := pad.cross(spawn)
	if n.length_squared() > 1e-8:
		var off_line := absf(asin(clampf(d.dot(n.normalized()), -1.0, 1.0))) * planet.radius
		var total := planet.surface_distance(pad, spawn)
		if off_line < TRAIL_CLEAR_M and planet.surface_distance(d, spawn) < total and planet.surface_distance(d, pad) < total:
			return "stones"
	for bid: String in planet.data.buildings:
		var bd := planet.building_dir(bid)
		if bd != Vector3.ZERO and planet.surface_distance(d, bd) < HOUSE_CLEAR_M:
			return "house"
	var here := planet.surface_point(d)
	for p: Dictionary in _prompts:
		if here.distance_to(p["pos"] as Vector3) < float(p["reach"]) + PROMPT_GAP_M:
			return "prompt:" + str(p["name"])
	if planet.nearest_prop_distance(d) < PROP_CLEAR_M:
		return "prop"
	for r: Dictionary in _deco_cache:
		if planet.surface_distance(d, r["dir"] as Vector3) < float(r["footprint"]) + DECO_GAP_M:
			return "decoration"
	if planet.collectibles_root != null:
		for c: Node in planet.collectibles_root.get_children():
			if c is Node3D and here.distance_to((c as Node3D).global_position) < PICKUP_CLEAR_M:
				return "pickup"
	var trash := get_tree().root.get_node_or_null("World/TrashField") if is_inside_tree() else null
	if trash != null:
		for c: Node in trash.get_children():
			if c is Node3D and here.distance_to((c as Node3D).global_position) < TRASH_CLEAR_M:
				return "trash"
	var ground := planet.ground_normal(d, RIM_M)
	if rad_to_deg(acos(clampf(ground.dot(d), -1.0, 1.0))) > MAX_SLOPE_DEG:
		return "slope"
	var h0 := planet.height_at(d)
	var xf := planet.surface_transform(d)
	for k in 8:
		var ang := TAU * float(k) / 8.0
		var tangent := xf.basis.x * cos(ang) + xf.basis.z * sin(ang)
		if absf(planet.height_at((d + tangent * (RIM_M / planet.radius)).normalized()) - h0) > MAX_RIM_DH_M:
			return "uneven"
	return ""


## The four passes of "WHERE THEY STAND". Vector3.ZERO when no ground on the planet passes.
func _pick_spot() -> Vector3:
	var first_problem := ""
	if _landing_dir != Vector3.ZERO:
		var lat := _landing_dir.cross(_away).normalized()
		# +side is the side the spawn is on.
		if lat.dot(planet.data.spawn_dir.normalized()) < 0.0:
			lat = -lat
		var near: Array[Vector2] = []
		for ix in range(int(round(AHEAD_MIN_M / SEARCH_STEP_M)), int(round(AHEAD_MAX_M / SEARCH_STEP_M)) + 1):
			for iy in range(-int(round(SIDE_MAX_M / SEARCH_STEP_M)), int(round(SIDE_MAX_M / SEARCH_STEP_M)) + 1):
				near.append(Vector2(ix, iy) * SEARCH_STEP_M)
		var ideal := Vector2(IDEAL_AHEAD_M, IDEAL_SIDE_M)
		near.sort_custom(func(a: Vector2, b: Vector2) -> bool:
			var da := a.distance_squared_to(ideal)
			var db := b.distance_squared_to(ideal)
			return da < db or (is_equal_approx(da, db) and (a.x < b.x or (is_equal_approx(a.x, b.x) and a.y < b.y))))
		# Pass 1 needs every sight line clear, round the whole wander patch too; pass 2 only where they
		# stand (the patch still in frame) - a crowded yard can hide some of the patch.
		for pass_name: String in ["framed", "framed-spot"]:
			for c: Vector2 in near:
				var d := _lattice_dir(_landing_dir, _away, lat, c.x, c.y)
				var why := _ground_problem(d)
				if why == "":
					why = _view_problem(d, pass_name == "framed")
				if why == "":
					_close_sight_space()
					return _chosen(pass_name, d, "ahead=%.1f side=%.1f%s" % [c.x, c.y,
						"" if pass_name == "framed" else " (framed pass first met: %s)" % first_problem])
				if first_problem == "":
					first_problem = why
		_close_sight_space()
		# The ground rules alone, nearest the landing spot first.
		var wide: Array[Vector2] = []
		var r := int(round(NEAR_MAX_M / SEARCH_STEP_M))
		for ix in range(-r, r + 1):
			for iy in range(-r, r + 1):
				var v := Vector2(ix, iy) * SEARCH_STEP_M
				if v.length() <= NEAR_MAX_M:
					wide.append(v)
		wide.sort_custom(func(a: Vector2, b: Vector2) -> bool:
			var la := a.length_squared()
			var lb := b.length_squared()
			return la < lb or (is_equal_approx(la, lb) and (a.x < b.x or (is_equal_approx(a.x, b.x) and a.y < b.y))))
		for c: Vector2 in wide:
			var d := _lattice_dir(_landing_dir, _away, lat, c.x, c.y)
			if _ground_problem(d) == "":
				return _chosen("near", d, "ahead=%.1f side=%.1f (framed pass first met: %s)" % [c.x, c.y, first_problem])
	# Anywhere: a Fibonacci sphere, nearest the landing spot (or the pad) first.
	var from := _landing_dir if _landing_dir != Vector3.ZERO else planet.data.pad_dir.normalized()
	var pts: Array[Vector3] = []
	var count := 1500
	for i in count:
		var y := 1.0 - 2.0 * (float(i) + 0.5) / float(count)
		var rr := sqrt(maxf(0.0, 1.0 - y * y))
		var th := PI * (3.0 - sqrt(5.0)) * float(i)
		pts.append(Vector3(cos(th) * rr, y, sin(th) * rr))
	pts.sort_custom(func(a: Vector3, b: Vector3) -> bool: return a.dot(from) > b.dot(from))
	for d: Vector3 in pts:
		if _ground_problem(d) == "":
			return _chosen("anywhere", d, "(framed pass first met: %s)" % first_problem)
	spot_pass = ""
	spot_note = "no legal ground (framed pass first met: %s)" % first_problem
	return Vector3.ZERO


func _chosen(pass_name: String, d: Vector3, note: String) -> Vector3:
	spot_pass = pass_name
	spot_note = note
	return d


## The point `x` metres along `t1` and `y` metres along `t2` from `a`, walked on the ground.
func _lattice_dir(a: Vector3, t1: Vector3, t2: Vector3, x: float, y: float) -> Vector3:
	var r := sqrt(x * x + y * y)
	if r < 1e-6:
		return a
	var ang := r / planet.radius
	return (a * cos(ang) + (t1 * x + t2 * y) / r * sin(ang)).normalized()


## Rebuilds the two cameras a rocket landing on home hands the player (replay_board_prop.gd
## `_build_views`, same numbers: world.gd's landing spot, rocket_pad.gd's facing, camera_rig.gd's rig).
func _build_views() -> void:
	_views.clear()
	_landing_dir = Vector3.ZERO
	var pad := planet.data.pad_dir.normalized()
	var side := pad.cross(Vector3.UP)
	if side.length_squared() < 0.01:
		side = Vector3.RIGHT
	var land := (pad + side.normalized() * (LANDING_SIDE_M / planet.data.radius)).normalized()
	var feet := planet.surface_point(land)
	var up := planet.up_at(feet)
	var away := feet - planet.pad_transform().origin
	away -= up * away.dot(up)
	if away.length_squared() < 1e-6:
		return
	away = away.normalized()
	_landing_dir = land
	# `away` as a tangent at the landing DIRECTION (a unit vector), for the lattice.
	_away = (away - land * away.dot(land)).normalized()
	var rig := {}
	if ResourceLoader.exists(CAMERA_RIG_PATH):
		var script := load(CAMERA_RIG_PATH) as GDScript
		if script != null:
			rig = script.get_script_constant_map()
	var pivot := feet + up * float(rig.get("PIVOT_HEIGHT", 1.0))
	var tan_y := tan(deg_to_rad(LANDING_FOV_DEG) * 0.5)
	for mode: String in VIEW_ASPECTS:
		var mobile := mode == "mobile"
		var dist := float(rig.get("MOBILE_DIST_DEFAULT" if mobile else "DIST_DEFAULT", 8.6 if mobile else 7.4))
		var pitch := deg_to_rad(float(rig.get("MOBILE_PITCH_DEFAULT_DEG" if mobile else "PITCH_DEFAULT_DEG",
			34.0 if mobile else 28.0)))
		var eye := pivot - away * cos(pitch) * dist + up * sin(pitch) * dist
		_views.append({"name": mode, "eye": eye, "basis": Basis.looking_at((pivot - eye).normalized(), up),
			"tan_x": tan_y * float(VIEW_ASPECTS[mode]), "tan_y": tan_y})
	_astronaut_xf = Transform3D(planet.surface_transform(land, away).basis, feet)


## "" when both landing cameras see the whole visitor at `d`, in the safe part of the frame, past
## everything; otherwise which rule failed and for which camera.
func _view_problem(d: Vector3, ring_sight: bool = true) -> String:
	return str(view_report(d, true, ring_sight)["problem"])


## The frame rule's numbers for a visitor at `d`: {problem, views: [{name, rect, blocked, lines, by}]}.
## Judged where they stand AND round the whole little patch they wander (WANDER_RING points WANDER_M +
## a step out): every column inside the safe part of the frame, and every sight line clear.
func view_report(d: Vector3, first_only: bool, ring_sight: bool = true) -> Dictionary:
	var out := {"problem": "", "views": []}
	if _views.is_empty():
		return out
	var xf := planet.surface_transform(d)
	# Where they may stand: the spot (full column of lines) and the rim of their wander patch.
	var stands: Array[Transform3D] = [xf]
	var r := WANDER_M + 0.2
	for k in WANDER_RING:
		var ang := TAU * float(k) / float(WANDER_RING)
		stands.append(planet.surface_transform(_lattice_dir(d.normalized(), xf.basis.x, xf.basis.z, cos(ang) * r, sin(ang) * r)))
	for v: Dictionary in _views:
		var name_v := str(v["name"])
		var eye: Vector3 = v["eye"]
		var basis: Basis = v["basis"]
		var rep := {"name": name_v, "rect": Rect2(), "blocked": 0, "lines": 0, "by": ""}
		(out["views"] as Array).append(rep)
		var rect := Rect2()
		var behind := false
		var first := true
		for sx: Transform3D in stands:
			var up := sx.basis.y
			var side := basis.x - up * basis.x.dot(up)
			side = side.normalized() if side.length_squared() > 1e-6 else sx.basis.x
			for c: Vector3 in [sx.origin - side * COLUMN_HALF_M, sx.origin + side * COLUMN_HALF_M,
					sx.origin - side * COLUMN_HALF_M + up * COLUMN_TOP_M, sx.origin + side * COLUMN_HALF_M + up * COLUMN_TOP_M]:
				var rel: Vector3 = c - eye
				var depth := -basis.z.dot(rel)
				if depth < 0.5:
					behind = true
					break
				var sp := Vector2(basis.x.dot(rel) / depth / float(v["tan_x"]), basis.y.dot(rel) / depth / float(v["tan_y"]))
				rect = Rect2(sp, Vector2.ZERO) if first else rect.expand(sp)
				first = false
		rep["rect"] = rect
		if behind or not (VIEW_SAFE[name_v] as Rect2).encloses(rect) \
				or (VIEW_KEEP_OUT.has(name_v) and (VIEW_KEEP_OUT[name_v] as Rect2).intersects(rect)):
			if out["problem"] == "":
				out["problem"] = "offscreen:" + name_v
			if first_only:
				return out
			continue
		_open_sight_space()
		for i in stands.size():
			var sx: Transform3D = stands[i]
			var up := sx.basis.y
			var side := basis.x - up * basis.x.dot(up)
			side = side.normalized() if side.length_squared() > 1e-6 else sx.basis.x
			for h: float in SIGHT_HEIGHTS:
				if i > 0 and not ring_sight:
					break
				for sd: float in (SIGHT_SIDES if i == 0 else [0.0]):
					rep["lines"] = int(rep["lines"]) + 1
					var hit := _ray_hit(eye, sx.origin + up * h + side * sd)
					if hit != "":
						rep["blocked"] = int(rep["blocked"]) + 1
						rep["by"] = hit
						if out["problem"] == "":
							out["problem"] = ("hidden:" if i == 0 else "wander_hidden:") + name_v
						if first_only:
							return out
	return out


## THE OCCLUDERS as their real triangles, in a private physics space that lives only while a spot is
## searched: a body added to a private PhysicsServer3D space answers a query in the same frame
## (measured for replay_board_prop.gd, 2026-09-13), where the world's own space would need a physics step.
func _open_sight_space() -> void:
	if _space.is_valid():
		return
	_space = PhysicsServer3D.space_create()
	PhysicsServer3D.space_set_active(_space, true)
	var root := get_tree().root
	var roots: Array[Node] = []
	if planet.props_root != null:
		roots.append(planet.props_root)
	for path: String in ["World/Decorations", "World/Buildings", "World/BuildBench", "World/TrashField"]:
		var n := root.get_node_or_null(path)
		if n != null:
			roots.append(n)
	var pad_node := root.get_node_or_null("World/Rocket")
	if pad_node != null:
		roots.append(pad_node)
	var rocket: Node3D = pad_node.get("rocket") as Node3D if pad_node != null else null
	var centre := _astronaut_xf.origin
	var reach := 0.0
	for v: Dictionary in _views:
		reach = maxf(reach, (v["eye"] as Vector3).distance_to(centre))
	reach = maxf(reach, Vector2(AHEAD_MAX_M, SIDE_MAX_M).length()) + 2.0
	var shapes := {}
	var stack: Array[Node] = roots.duplicate()
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		# The pad's waypoint gem only shows to a player far from the pad, never at a landing.
		if n == rocket or str(n.name) == "Waypoint":
			continue
		var mi := n as MeshInstance3D
		if mi != null and mi.mesh != null and mi.is_visible_in_tree() and _near(mi.global_transform, mi.get_aabb(), centre, reach) \
				and _stands_up(mi.global_transform, mi.get_aabb()) and not _is_glow(mi):
			_add_sight_body(mi.global_transform, _trimesh(mi.mesh, shapes), str(mi.get_path()))
		for c: Node in n.get_children():
			stack.append(c)
	if rocket != null:
		var pad_root := pad_node.get_node_or_null("Pad") as Node3D
		var rest: Variant = pad_node.get("_rest_xf")
		var rest_local: Transform3D = rest if rest is Transform3D else Transform3D(Basis.IDENTITY, Vector3(0.0, PAD_DECK_Y, 0.0))
		var rest_root := (pad_root.global_transform if pad_root != null else planet.pad_transform()) * rest_local
		var to_rocket := rocket.global_transform.affine_inverse()
		for m: Node in rocket.find_children("*", "MeshInstance3D", true, false):
			var rm := m as MeshInstance3D
			if rm.mesh != null and rm.visible:
				_add_sight_body(rest_root * (to_rocket * rm.global_transform), _trimesh(rm.mesh, shapes), "rocket at rest:" + str(rm.name))
	var body := CapsuleShape3D.new()
	body.radius = ASTRONAUT_RADIUS_M
	body.height = ASTRONAUT_HEIGHT_M
	shapes["astronaut"] = body
	_add_sight_body(_astronaut_xf * Transform3D(Basis.IDENTITY, Vector3(0.0, ASTRONAUT_HEIGHT_M * 0.5, 0.0)), body, "astronaut")
	_sight_shapes = shapes.values()


## A glow sprite (additive, never writes depth: MaterialLib.glow_sprite's star.gdshader, the pad beacon's
## halo) or a billboard hides nothing, and its quad as authored is not where it is drawn. MEASURED: the
## pad's BeaconHalo quad turned down 187 of the framed pass's spots at world load on 2026-09-13.
static func _is_glow(mi: MeshInstance3D) -> bool:
	var mat: Material = mi.material_override
	if mat == null and mi.mesh.get_surface_count() > 0:
		mat = mi.get_active_material(0)
	if mat is ShaderMaterial and (mat as ShaderMaterial).shader != null:
		var code := (mat as ShaderMaterial).shader.code
		return code.contains("blend_add") or code.contains("depth_draw_never")
	if mat is BaseMaterial3D:
		var bm := mat as BaseMaterial3D
		return bm.blend_mode == BaseMaterial3D.BLEND_MODE_ADD or bm.billboard_mode != BaseMaterial3D.BILLBOARD_DISABLED
	return false


func _close_sight_space() -> void:
	for b: RID in _sight_bodies:
		PhysicsServer3D.free_rid(b)
	_sight_bodies.clear()
	_sight_names.clear()
	if _space.is_valid():
		PhysicsServer3D.free_rid(_space)
	_space = RID()
	_sight_shapes.clear()


func _near(xf: Transform3D, box: AABB, centre: Vector3, reach: float) -> bool:
	var world := AABB(xf * box.position, Vector3.ZERO)
	for i in 8:
		world = world.expand(xf * box.get_endpoint(i))
	return centre.clamp(world.position, world.end).distance_to(centre) < reach


func _stands_up(xf: Transform3D, box: AABB) -> bool:
	var c := xf * box.get_center()
	var ground := planet.surface_point(planet.dir_of(c))
	var up := planet.up_at(c)
	for i in 8:
		if (xf * box.get_endpoint(i) - ground).dot(up) >= LOW_MESH_M:
			return true
	return false


static func _trimesh(mesh: Mesh, cache: Dictionary) -> Shape3D:
	var key := mesh.get_instance_id()
	if cache.has(key):
		return cache[key]
	var shape: Shape3D = null
	var faces := mesh.get_faces()
	for i in range(0, faces.size() - 2, 3):
		if (faces[i + 1] - faces[i]).cross(faces[i + 2] - faces[i]).length_squared() > 1e-10:
			var concave := ConcavePolygonShape3D.new()
			concave.set_faces(faces)
			concave.backface_collision = true
			shape = concave
			break
	cache[key] = shape
	return shape


func _add_sight_body(xf: Transform3D, shape: Shape3D, label: String) -> void:
	if shape == null:
		return
	var b := PhysicsServer3D.body_create()
	PhysicsServer3D.body_set_mode(b, PhysicsServer3D.BODY_MODE_STATIC)
	PhysicsServer3D.body_set_space(b, _space)
	PhysicsServer3D.body_add_shape(b, shape.get_rid())
	PhysicsServer3D.body_set_state(b, PhysicsServer3D.BODY_STATE_TRANSFORM, xf)
	PhysicsServer3D.body_set_collision_layer(b, 1)
	PhysicsServer3D.body_set_collision_mask(b, 0)
	_sight_bodies.append(b)
	_sight_names[b] = label


## The label of the first sight body on the line from a to b, or "".
func _ray_hit(a: Vector3, b: Vector3) -> String:
	var state := PhysicsServer3D.space_get_direct_state(_space)
	if state == null:
		return ""
	var q := PhysicsRayQueryParameters3D.create(a, b, 1)
	q.hit_back_faces = true
	var hit := state.intersect_ray(q)
	if hit.is_empty():
		return ""
	return str(_sight_names.get(hit.get("rid", RID()), "?"))


# ============================================================================= helpers
static func _vec(a: Array) -> Vector3:
	if a.size() != 3:
		return Vector3.ZERO
	var v := Vector3(float(a[0]), float(a[1]), float(a[2]))
	return v.normalized() if v.length_squared() > 1e-6 else Vector3.ZERO


static func _npc_name(npc_id: String) -> String:
	return str(NpcData.get_data(npc_id).get("display_name", npc_id.capitalize()))


# ============================================================================= dev menu
## "Visitor today: <Name>": today's visit becomes this neighbour's, at once if you are at home. The first
## tap asks for their game (any game of theirs in this build, unlocked or not - a test row), the next tap
## on the same neighbour the same day switches it to a gift, and so on. Returns the toast text.
static func dev_force_visit(npc_id: String) -> String:
	var rec := record()
	var day := GameState.day_count
	var kind := "play"
	if not rec.is_empty() and int(rec["day"]) == day and str(rec["npc"]) == npc_id and bool(rec["forced"]) \
			and str(rec["kind"]) == "play":
		kind = "gift"
	var fresh := _blank(day, npc_id)
	fresh["forced"] = true
	_plan_request(fresh, kind)
	_write(fresh)
	var host := find()
	if host != null:
		host.call("restage")
	var what := ("game, %s" % fresh["game"]) if str(fresh["kind"]) == "play" \
		else ("gift, %s" % Catalog.get_item(str(fresh["item"])).get("name", fresh["item"]))
	var where := "" if GameState.current_planet_id == HOME_ID else " (at home)"
	return "Visitor: %s, %s%s" % [_npc_name(npc_id), what, where]


## "Clear today's visit": nobody visits today; the one standing here goes.
static func dev_clear_today() -> String:
	var fresh := _blank(GameState.day_count, "")
	fresh["forced"] = true
	_write(fresh)
	var host := find()
	if host != null:
		host.call("restage")
	return "No visitor today (day %d)." % GameState.day_count


# ============================================================================= QA
## One line a probe or a critic can assert against. Prints only.
func debug_report(tag: String = "") -> void:
	var rec := record()
	var vis := "none"
	if visitor != null and is_instance_valid(visitor):
		var home := visitor.home_dir
		vis = "%s at=%s home=%s wander_m=%.2f ground=%s marker=%d" % [visitor.npc_id,
			str(planet.dir_of(visitor.global_position)).replace(" ", ""), str(home).replace(" ", ""),
			planet.surface_distance(planet.dir_of(visitor.global_position), home),
			_ground_problem(planet.dir_of(visitor.global_position)) if not _views.is_empty() else "?",
			wants_marker(visitor.npc_id)]
	var ms := _minigames()
	var game := "none"
	if ms != null and bool(ms.call("is_running")):
		game = "%s owner=%s progress=%s" % [ms.call("running_kind"), ms.call("running_owner"), str(ms.call("progress"))]
	print("VISIT %s planet=%s day=%d rec=%s visitor=[%s] pass=%s note=%s owner=%s pending=%s game=[%s] met=%s" % [
		tag, GameState.current_planet_id, GameState.day_count, JSON.stringify(rec), vis, spot_pass, spot_note,
		_owner, str(_game_pending), game, str(request_met(rec))])


## The spot's measured distances, for a critic: pad, spawn, landing, stones line, bench, house, nearest
## decoration and prop, and the frame report from both landing cameras.
func debug_spot_report(tag: String = "") -> void:
	var rec := record()
	var d := _vec(rec.get("spot", []) as Array)
	if d == Vector3.ZERO or planet == null:
		print("VISITSPOT %s none" % tag)
		return
	_rebuild_caches()
	var pad := planet.data.pad_dir.normalized()
	var spawn := planet.data.spawn_dir.normalized()
	var n := pad.cross(spawn).normalized()
	var bench := get_tree().root.get_node_or_null("World/BuildBench") as Node3D
	var nearest_deco := INF
	for r: Dictionary in _deco_cache:
		nearest_deco = minf(nearest_deco, planet.surface_distance(d, r["dir"] as Vector3) - float(r["footprint"]))
	var rep := view_report(d, false)
	_close_sight_space()
	var views := PackedStringArray()
	for v: Dictionary in rep["views"]:
		views.append("%s rect=%s blocked=%d/%d by=%s" % [v["name"], str(v["rect"]), v["blocked"], v["lines"], v.get("by", "")])
	print("VISITSPOT %s pad=%.2f spawn=%.2f landing=%.2f stones_line=%.2f bench=%.2f house=%.2f deco_edge=%.2f prop=%.2f ground=%s view=%s [%s]" % [
		tag, planet.surface_distance(d, pad), planet.surface_distance(d, spawn),
		planet.surface_distance(d, _landing_dir), absf(asin(clampf(d.dot(n), -1.0, 1.0))) * planet.radius,
		(planet.surface_point(d).distance_to(bench.global_position) if bench != null else -1.0),
		planet.surface_distance(d, planet.building_dir("player_home")), nearest_deco,
		planet.nearest_prop_distance(d), _ground_problem(d), rep["problem"], "; ".join(views)])


## QA: re-runs the framed pass over its whole lattice and prints how many spots each rule turned down.
func debug_search_tally(tag: String = "") -> void:
	if planet == null:
		return
	_rebuild_caches()
	var lat := _landing_dir.cross(_away).normalized()
	if lat.dot(planet.data.spawn_dir.normalized()) < 0.0:
		lat = -lat
	var tally := {}
	var passed := PackedStringArray()
	for ix in range(int(round(AHEAD_MIN_M / SEARCH_STEP_M)), int(round(AHEAD_MAX_M / SEARCH_STEP_M)) + 1):
		for iy in range(-int(round(SIDE_MAX_M / SEARCH_STEP_M)), int(round(SIDE_MAX_M / SEARCH_STEP_M)) + 1):
			var c := Vector2(ix, iy) * SEARCH_STEP_M
			var d := _lattice_dir(_landing_dir, _away, lat, c.x, c.y)
			var why := _ground_problem(d)
			if why == "":
				why = _view_problem(d)
			if why == "":
				passed.append("%.1f/%.1f" % [c.x, c.y])
			var key := why.get_slice(":", 0) + (":" + why.get_slice(":", 1) if why.begins_with("prompt") or why.contains("hidden") or why.begins_with("offscreen") else "")
			tally[key] = int(tally.get(key, 0)) + 1
	_close_sight_space()
	print("VISITTALLY %s %s passed=[%s]" % [tag, JSON.stringify(tally), ",".join(passed)])


## SYNTHETIC SCHEDULE PROBE: writes GameState.day_count for each of `days` days from `from_day`, runs
## the same `ensure_today` a home load runs, marks the visit left (as flying away would), and prints one
## line per day. Restores the day and the flag afterwards. Director runs only.
static func debug_schedule(from_day: int, days: int) -> void:
	if not Director.is_active():
		return
	var keep_day := GameState.day_count
	var keep_flag: Variant = GameState.flags.get(FLAG_KEY)
	GameState.flags.erase(FLAG_KEY)
	var visits := 0
	var prev := ""
	var repeats := 0
	for i in days:
		GameState.day_count = from_day + i
		var rec := ensure_today()
		var again := ensure_today()
		var npc := str(rec.get("npc", ""))
		if npc != "":
			visits += 1
			if npc == prev:
				repeats += 1
		print("VISITDAY day=%d visit_day=%s npc=%s kind=%s game=%s item=%s count=%d stable=%s eligible=%s" % [
			GameState.day_count, str(is_visit_day(GameState.day_count)), npc, rec.get("kind", ""), rec.get("game", ""),
			rec.get("item", ""), int(rec.get("count", 0)), str(JSON.stringify(rec) == JSON.stringify(again)),
			",".join(eligible_neighbours())])
		prev = npc
		mark_left("schedule probe")
	print("VISITDAYS from=%d days=%d visits=%d same_npc_two_days_running=%d" % [from_day, days, visits, repeats])
	GameState.day_count = keep_day
	if keep_flag == null:
		GameState.flags.erase(FLAG_KEY)
	else:
		GameState.flags[FLAG_KEY] = keep_flag
