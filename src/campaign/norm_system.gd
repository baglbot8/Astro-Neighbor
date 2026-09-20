extends Node
## NORM, THE MYSTERY NEIGHBOUR: his days, his spot, the landing hint and his talk (docs/NORM_SPEC.md §2-§4,
## §7; docs/CORE_LOOP.md "The mystery neighbour"). Modelled on visitor_system.gd.
##
## ============================================================================== WHERE IT LIVES
## ONE NODE PER WORLD, made by the guarded hook in world.gd `_ready`, right after VisitorSystem's:
##
##     if ResourceLoader.exists("res://src/campaign/norm_system.gd"):
##         load("res://src/campaign/norm_system.gd").attach(self)
##
## It is /root/World/NormSystem and it dies with the world, and so does Norm (res://src/characters/npcs/
## norm.tscn, added under /root/World/NPCs). Nothing names this file statically: npc.gd and conversation.gd
## reach it through Norm's `visit_host` (the same duck-typed hooks a visitor uses: `handle_conversation`,
## `wants_marker`, `wander_ok`), dev_menu.gd by path. NormQuiz, NormRewards and NormLines are loaded by path
## too, so this file parses and the game plays without them.
##
## ============================================================================== WHEN
##   * ON (`norm_on`): 3+ rocket parts fitted or the story done; never at finale_stage 1, 2 or 3; never
##     while onboarding owns the screen (VisitorSystem's `_onboarding_busy` rule). A Director run sees him
##     only with "--campaign", the same opt-in as every campaign gate and as visits (so no existing
##     timeline or capture gains a stranger).
##   * WHICH DAY (`is_norm_day`): day d's raw roll, seeded by hash(["astro_norm", d]), hits with RAW_CHANCE;
##     a hit is VOID when day d-1 was itself a Norm day. That rule alone makes a hit on d-1 and d impossible,
##     and a stationary rate P = p (1 - P), so p = 1/3 gives exactly 1 day in 4 (the spec's "1 day in 4").
##     Pure: a function of the day number alone, never of the save, the clock or where anyone stands.
##   * WHICH WORLD (`world_for_day`): a seeded pick (hash(["astro_norm_world", d])) from WORLDS that pass
##     CampaignData.planet_in_range, and, before the story is done, whose neighbour this save has met
##     (`met_<npc>`; the Commons counts once the Professor, `met_mayor_orbit`, is met). Never home.
##     Pure for a given save: the same save on the same day always gives the same world. FIXED 2026-09-19
##     (docs/NORM_SPEC.md §2, norm_today): `plan_today(true)` (used by `here_today`, the real gameplay
##     path) locks the world into GameState.flags[K_TODAY] the first time a Norm day is resolved, and
##     reads it back for the rest of that day, so meeting a new neighbour mid-day can no longer move him
##     (or spawn him from nowhere on a day that first had no eligible world). `plan_today()` with no
##     argument stays the old pure re-roll, for previews (`debug_today`) and the schedule probe, which
##     must never touch the save.
##   * ONE VISIT PER APPEARANCE: the quiz's end (won or lost) writes norm_done_day = today. He waves, walks
##     a few steps and goes (out of the camera's view, or LEAVE_MAX_S later); a load that day finds nobody.
##     "Not now" writes nothing, so he stays.
##
## ============================================================================== WHERE HE STANDS
## `_pick_spot`: a SPOT_POINTS Fibonacci sphere in an order shuffled by hash(["astro_norm_spot", day, world]);
## the first point at least FAR_DEG round the planet from the pad that passes THE VISITOR GROUND RULES
## (VisitorSystem's own `_ground_problem`, run by the world's VisitorSystem node: water, shore, pad, spawn,
## landing spot, stones, houses, prompts, props, decorations, pickups, trash, slope) plus NPC_CLEAR_M from
## every other neighbour's home spot. When no point that far passes, the passing point farthest round from
## the pad. Seeded by the day and world, so a reload that day stands him in the same place.
## He wanders WANDER_M, and every wander target is vetoed by the same rules (`wander_ok`).
##
## ============================================================================== THE LANDING HINT
## On EventBus.planet_loaded for the world he stands on, once the arrival has handed control back (no scene
## fade, no journey swap, no `rocket_arriving`, the pad's flight camera gone and its Interactable back, no
## modal, the player's input on) and has stayed that way HINT_CALM_S: one toast, NormLines.HINTS rotated by
## the day. Never under the fade, never after his quiz ended that day (he is not here then).
##
## ============================================================================== SAVED STATE (GameState.flags)
## norm_last_day (int, the day he last appeared), norm_done_day (int, the day his quiz ended), norm_met
## (bool, the intro has played), norm_today (Dictionary {day, planet}: the current day's WORLD roll,
## written once by `plan_today(true)` the first time a Norm day is resolved that day and read back after
## - docs/NORM_SPEC.md §2). norm_wins / norm_statues belong to NormRewards and norm_seen_q to NormQuiz;
## this file only reads them (and the dev menu's reset clears them, norm_today included). Nothing here
## ever calls a save.

const NODE_NAME := "NormSystem"
const SCRIPT_PATH := "res://src/campaign/norm_system.gd"
const VISITOR_NODE := "World/VisitorSystem"
const QUIZ_PATH := "res://src/campaign/norm_quiz.gd"
const REWARDS_PATH := "res://src/campaign/norm_rewards.gd"
const LINES_PATH := "res://src/campaign/norm_lines.gd"
const NORM_SCENE := "res://src/characters/npcs/norm.tscn"
const PLANET_DATA_DIR := "res://src/planet/data/"
const NPC_ID := "norm"
const HOME_ID := "home"

## Every world he may visit, in a fixed order (the seeded pick indexes this order), and whose meeting
## opens it before the story is done.
const WORLDS: Array[String] = ["hub", "zorp", "bolt", "fen", "grig", "vela"]
const WORLD_NEIGHBOUR := {"hub": "mayor_orbit", "zorp": "zorp", "bolt": "bolt", "fen": "fen", "grig": "grig",
	"vela": "vela"}
const PARTS_NEEDED := 3

const K_LAST_DAY := "norm_last_day"
const K_DONE_DAY := "norm_done_day"
const K_WINS := "norm_wins"
const K_STATUES := "norm_statues"
const K_SEEN_Q := "norm_seen_q"
const K_MET := "norm_met"
## {day, planet}: today's WORLD roll, locked in once (docs/NORM_SPEC.md §2). See `plan_today`.
const K_TODAY := "norm_today"
const ALL_KEYS: Array[String] = [K_LAST_DAY, K_DONE_DAY, K_WINS, K_STATUES, K_SEEN_Q, K_MET, K_TODAY]

## The raw per-day hit chance. With the "void after a Norm day" rule the rate is p / (1 + p) = 1/4.
const RAW_CHANCE := 1.0 / 3.0
## Spot search (see "WHERE HE STANDS").
const SPOT_POINTS := 2000
const FAR_DEG := 90.0
const NPC_CLEAR_M := 3.0
## "He does not wander far": npc.gd samples 0.9-1.0 of this.
const WANDER_M := 1.2
## The leave: a few steps away from the player, then gone once off camera or this many seconds later.
const LEAVE_STEP_M := 3.5
const LEAVE_MAX_S := 8.0
## The hint waits this long of continuous calm after the arrival hand-back.
const HINT_CALM_S := 0.8
## Arrivals that never report calm (a stuck flag) give up on the hint after this long.
const HINT_GIVE_UP_S := 40.0
const OFFER_FALLBACK := "Care for some normal human questions? Three of them."

## Dev menu state, never saved (docs/NORM_SPEC.md §7: nothing there saves).
static var _forced_day := -1
static var _forced_world := ""
static var _sent_away_day := -1

var planet: Planet
## Norm, standing on this world now, or null.
var norm: NPC
var spot_note := ""
var spot_angle_deg := -1.0
var search_usec := 0

var _leaving := false
var _leave_t := 0.0
var _in_quiz := false
var _hint_pending := false
var _hint_calm := 0.0
var _hint_wait := 0.0
var _hint_saw_arrival := false
var _hint_shown := false
var _hint_text := ""


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


## The world's NormSystem, or null.
static func find() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("World/" + NODE_NAME)


func _ready() -> void:
	planet = get_tree().get_first_node_in_group("planet") as Planet
	EventBus.planet_loaded.connect(_on_planet_loaded)
	set_process(false)
	_stage()


func _stage() -> void:
	var here := GameState.current_planet_id
	if planet == null or planet.data == null:
		return
	if here_today() != here:
		return
	_bring_in()


# ============================================================================= the day (pure)
## Day `day`'s raw roll (before the "never two days running" rule).
static func raw_roll(day: int) -> bool:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(["astro_norm", day])
	return rng.randf() < RAW_CHANCE


## True when `day` is a Norm day: its raw roll hits and day-1 was not a Norm day. Pure. Walks back over
## the run of consecutive hits ending at `day`: hits alternate Norm day / void from the run's first day.
static func is_norm_day(day: int) -> bool:
	var d := day
	var run := 0
	while d >= 1 and raw_roll(d):
		run += 1
		d -= 1
	return run % 2 == 1


## The worlds he may visit on this save now, in WORLDS order.
static func candidate_worlds() -> PackedStringArray:
	var out := PackedStringArray()
	for w: String in WORLDS:
		if not ResourceLoader.exists(PLANET_DATA_DIR + w + ".tres"):
			continue
		if not CampaignData.planet_in_range(w):
			continue
		if not GameState.story_done and not GameState.flag("met_" + str(WORLD_NEIGHBOUR.get(w, w))):
			continue
		out.append(w)
	return out


## The seeded world pick for `day` among `worlds` ("" when there is none). Pure.
static func world_for_day(day: int, worlds: PackedStringArray) -> String:
	if worlds.is_empty():
		return ""
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(["astro_norm_world", day])
	return worlds[rng.randi_range(0, worlds.size() - 1)]


## "" when Norm may come at all now, otherwise why not.
static func off_reason() -> String:
	var stage := int(GameState.flags.get("finale_stage", 0))
	if stage == 1 or stage == 2 or stage == 3:
		return "the ending is playing (finale stage %d)" % stage
	if Director.is_active() and not Director.campaign_opt_in():
		return "a Director run without --campaign"
	if not GameState.story_done and GameState.rocket_part_count() < PARTS_NEEDED:
		return "only %d of %d parts fitted" % [GameState.rocket_part_count(), PARTS_NEEDED]
	if onboarding_busy():
		return "onboarding owns the screen"
	return ""


static func norm_on() -> bool:
	return off_reason() == ""


## Today's plan: {"day", "world" ("" for none), "why"} - the natural roll, or the dev menu's forcing.
## Does not look at norm_done_day (see `here_today`).
##
## `cache` false (the default): a pure re-roll every time, touching no save state - for previews
## (`debug_today`) and the schedule probe, which must never write. `cache` true (real gameplay, via
## `here_today`): once today is known to be a Norm day, the WORLD is read from GameState.flags[K_TODAY]
## when it already holds an entry for today, or rolled fresh and written there otherwise - written once
## per day, before any later `met_<npc>` change can move it (docs/NORM_SPEC.md §2, norm_today; a save
## with no norm_today, or one from an older day, rolls fresh here exactly as the pure path would, and
## that becomes the cached entry). The dev menu's forcing (`_forced_day`/`_forced_world`) and the "not a
## Norm day" / off-reason cases never touch the cache, forced or not.
static func plan_today(cache: bool = false) -> Dictionary:
	var day := GameState.day_count
	if _forced_day == day and _forced_world != "":
		return {"day": day, "world": _forced_world, "why": "brought by the dev menu"}
	var off := off_reason()
	if off != "":
		return {"day": day, "world": "", "why": off}
	if not is_norm_day(day):
		return {"day": day, "world": "", "why": "not a Norm day"}
	if cache:
		var cached: Variant = GameState.flags.get(K_TODAY, null)
		if cached is Dictionary and int((cached as Dictionary).get("day", -1)) == day:
			return {"day": day, "world": str((cached as Dictionary).get("planet", "")), "why": "rolled (cached)"}
	var worlds := candidate_worlds()
	var world := "" if worlds.is_empty() else world_for_day(day, worlds)
	if cache:
		GameState.flags[K_TODAY] = {"day": day, "planet": world}
	if world == "":
		return {"day": day, "world": "", "why": "no world in range and met"}
	return {"day": day, "world": world, "why": "rolled"}


## The world he stands on right now ("" for none): today's plan, unless his quiz already ended today or
## the dev menu sent him away. Uses the cached, locked-in roll (`plan_today(true)`), so a neighbour met
## mid-day cannot move which world he is on (docs/NORM_SPEC.md §2).
static func here_today() -> String:
	var day := GameState.day_count
	if quiz_ended_today() or _sent_away_day == day:
		return ""
	return str(plan_today(true)["world"])


static func quiz_ended_today() -> bool:
	return _int_flag(K_DONE_DAY, -1) == GameState.day_count


## VisitorSystem's `_onboarding_busy`, as a static: the crash and the radio call come before
## "intro_greeted", and a world whose Onboarding says the intro is not allowed (a Director run) is never busy.
static func onboarding_busy() -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	var ob: Node = tree.root.get_node_or_null("World/Onboarding") if tree != null and tree.root != null else null
	if ob == null:
		return false
	if ob.get("_crashing") == true or ob.get("_greeting") == true:
		return true
	if ob.has_method("_intro_allowed") and not bool(ob.call("_intro_allowed")):
		return false
	return not GameState.flag("intro_greeted") and not GameState.flag("intro_done")


static func _int_flag(key: String, fallback: int) -> int:
	var v: Variant = GameState.flags.get(key, fallback)
	if v is int or v is float:
		return int(v)
	return fallback


# ============================================================================= Norm on this world
func _visitor_system() -> Node:
	return get_tree().root.get_node_or_null(VISITOR_NODE)


## "" when Norm may stand at `dir`, otherwise the first rule it breaks. Needs `_bring_in`'s cache warm-up.
func spot_problem(dir: Vector3) -> String:
	var vs := _visitor_system()
	if vs == null or not vs.has_method("_ground_problem"):
		return "no visitor rules"
	var why := str(vs.call("_ground_problem", dir))
	if why != "":
		return why
	var npcs := get_tree().root.get_node_or_null("World/NPCs")
	if npcs != null:
		for n: Node in npcs.get_children():
			var other := n as NPC
			if other == null or other == norm or other.npc_id == NPC_ID:
				continue
			if planet.surface_distance(dir.normalized(), other.home_dir) < NPC_CLEAR_M:
				return "neighbour:" + other.npc_id
	return ""


## npc.gd asks this for every wander target and path sample.
func wander_ok(dir: Vector3) -> bool:
	return spot_problem(dir) == ""


## For npc.gd's marker ("?" on Norm): 1 show, 0 hide. Shown until his quiz ends.
func wants_marker(npc_id: String) -> int:
	if npc_id != NPC_ID or _leaving or _in_quiz or quiz_ended_today():
		return 0
	return 1


func _warm_rules() -> bool:
	var vs := _visitor_system()
	if vs == null or not vs.has_method("ground_problem"):
		return false
	# Builds VisitorSystem's caches (prompts, decorations, the landing spot) for this world.
	vs.call("ground_problem", planet.data.pad_dir.normalized())
	return true


## The seeded spot for (day, world). Vector3.ZERO when no ground passes.
func _pick_spot(day: int, world: String) -> Vector3:
	spot_note = ""
	spot_angle_deg = -1.0
	var pad := planet.data.pad_dir.normalized()
	var pts: Array[Vector3] = []
	for i in SPOT_POINTS:
		var y := 1.0 - 2.0 * (float(i) + 0.5) / float(SPOT_POINTS)
		var rr := sqrt(maxf(0.0, 1.0 - y * y))
		var th := PI * (3.0 - sqrt(5.0)) * float(i)
		pts.append(Vector3(cos(th) * rr, y, sin(th) * rr))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(["astro_norm_spot", day, world])
	for i in range(pts.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t := pts[i]
		pts[i] = pts[j]
		pts[j] = t
	var tested := 0
	var first_why := {}
	for d: Vector3 in pts:
		if rad_to_deg(d.angle_to(pad)) < FAR_DEG:
			continue
		tested += 1
		var why := spot_problem(d)
		if why == "":
			spot_angle_deg = rad_to_deg(d.angle_to(pad))
			spot_note = "far (tested %d)" % tested
			return d
		first_why[why.get_slice(":", 0)] = int(first_why.get(why.get_slice(":", 0), 0)) + 1
	# Nothing that far round passes: the passing point farthest round from the pad.
	var best := Vector3.ZERO
	var best_ang := -1.0
	for d: Vector3 in pts:
		var ang := rad_to_deg(d.angle_to(pad))
		if ang >= FAR_DEG or ang <= best_ang:
			continue
		if spot_problem(d) == "":
			best = d
			best_ang = ang
	spot_angle_deg = best_ang
	spot_note = "near fallback (no far spot: %s)" % JSON.stringify(first_why)
	return best


func _bring_in() -> void:
	if norm != null and is_instance_valid(norm):
		return
	if not ResourceLoader.exists(NORM_SCENE):
		push_warning("NormSystem: no %s; Norm stays away" % NORM_SCENE)
		return
	var t0 := Time.get_ticks_usec()
	if not _warm_rules():
		push_warning("NormSystem: no VisitorSystem on this world; Norm stays away")
		return
	var day := GameState.day_count
	var spot := _pick_spot(day, GameState.current_planet_id)
	search_usec = Time.get_ticks_usec() - t0
	if spot == Vector3.ZERO:
		push_warning("NormSystem: no ground on %s passes the rules; Norm stays away" % GameState.current_planet_id)
		return
	var root := get_tree().root.get_node_or_null("World/NPCs")
	if root == null:
		return
	var n := (load(NORM_SCENE) as PackedScene).instantiate()
	var npc := n as NPC
	if npc == null:
		n.free()
		return
	npc.name = NPC_ID
	npc.visit_host = self
	npc.visit_home = spot
	npc.visit_wander_m = WANDER_M
	root.add_child(npc)
	npc.planet = planet
	norm = npc
	_leaving = false
	GameState.flags[K_LAST_DAY] = day
	print("NormSystem: Norm on %s (day %d), spot %.1f deg from the pad, %s, in %.1f ms" % [
		GameState.current_planet_id, day, spot_angle_deg, spot_note, search_usec / 1000.0])


func _despawn() -> void:
	if norm != null and is_instance_valid(norm):
		var p := norm.get_parent()
		if p != null:
			p.remove_child(norm)
		norm.queue_free()
	norm = null
	_leaving = false
	_in_quiz = false


## The dev menu changed today while this world is up: stand him (or nobody) now.
func restage() -> void:
	_despawn()
	_stage()


# ============================================================================= talk
## conversation.gd hands every talk with Norm here (Norm is a `visit_host` NPC). Awaits until said.
func handle_conversation(runner: DialogueRunner, npc: NPC) -> void:
	var lines: Variant = _lines()
	if npc != norm or _leaving or quiz_ended_today():
		await runner.say(npc, [_pick(lines, "BYE", "Farewell, fellow human. I must go do... human errands.")])
		return
	if not GameState.flag(K_MET):
		# Committed before the lines: the intro plays once ever, even if this talk is cut short.
		GameState.flags[K_MET] = true
		var intro: Array = _list(lines, "INTRO")
		if intro.is_empty():
			intro = ["Greetings, fellow Earth person. I am Norm. A normal human."]
		await runner.say(npc, intro)
	var offer := str(_const(lines, "OFFER", OFFER_FALLBACK))
	var options: Array = _list(lines, "OFFER_OPTIONS")
	if options.size() < 2:
		options = ["Sure!", "Not now"]
	var pick := await runner.ask(npc, offer, options)
	if pick != 0:
		await runner.say(npc, [_pick(lines, "NOT_NOW", "Of course. Humans are very busy. I will wait here. Normally.")])
		return
	if not ResourceLoader.exists(QUIZ_PATH):
		await runner.say(npc, ["Hmm. I seem to have forgotten my questions. Very human of me."])
		return
	_in_quiz = true
	var quiz: Variant = load(QUIZ_PATH)
	var won := bool(await quiz.run(runner, npc))
	# Committed the moment the quiz ends, BEFORE any reward: a save taken during the reward box can
	# never replay the quiz that day (so never pays twice). NormRewards.grant adds the item and bumps
	# norm_wins before its own lines.
	GameState.flags[K_DONE_DAY] = GameState.day_count
	_in_quiz = false
	_leaving = true
	if won:
		await runner.say(npc, [_pick(lines, "WIN", "Three for three! A perfectly normal human score.")])
		if ResourceLoader.exists(REWARDS_PATH):
			var rewards: Variant = load(REWARDS_PATH)
			await rewards.grant(runner, npc)
	await runner.say(npc, [_pick(lines, "BYE", "Farewell, fellow human.")])
	_start_leave.call_deferred()


func _start_leave() -> void:
	if norm == null or not is_instance_valid(norm):
		return
	_leaving = true
	_leave_t = 0.0
	set_process(true)


func _leave_tick(delta: float) -> void:
	if norm == null or not is_instance_valid(norm):
		return
	# Wait for the conversation to close (runner.finish) before walking off.
	if bool(norm.get("_conversation_running")):
		return
	if _leave_t == 0.0:
		norm.wander_enabled(false)
		norm.play_emote("wave")
		var here := planet.dir_of(norm.global_position)
		var p := get_tree().get_first_node_in_group("player") as Node3D
		var away := Vector3.ZERO
		if p != null:
			away = here - planet.dir_of(p.global_position)
			away -= here * away.dot(here)
		if away.length_squared() < 1e-8:
			away = planet.surface_transform(here).basis.z
		var to := (here * cos(LEAVE_STEP_M / planet.radius) + away.normalized() * sin(LEAVE_STEP_M / planet.radius)).normalized()
		norm.stroll_to(to)
	_leave_t += delta
	var gone := _leave_t >= LEAVE_MAX_S
	if not gone and _leave_t > 1.2:
		var cam := get_viewport().get_camera_3d()
		gone = cam != null and not cam.is_position_in_frustum(norm.global_position + planet.up_at(norm.global_position) * 0.8)
	if gone:
		print("NormSystem: Norm left after %.1f s" % _leave_t)
		_despawn()


# ============================================================================= the landing hint
func _on_planet_loaded(planet_id: String) -> void:
	if planet_id != GameState.current_planet_id or norm == null or not is_instance_valid(norm):
		return
	var lines: Variant = _lines()
	var hints: Array = _list(lines, "HINTS")
	if hints.is_empty():
		hints = ["Something feels a little off here..."]
	_hint_text = str(hints[posmod(GameState.day_count, hints.size())])
	_hint_pending = true
	_hint_calm = 0.0
	_hint_wait = 0.0
	_hint_saw_arrival = false
	set_process(true)


## Control is back: no fade, no journey swap, no arrival, the pad's flight camera gone and (after an
## arrival) its Interactable back on, no modal, and the player really in control.
func arrival_handed_back() -> bool:
	if SceneRouter.is_busy() or RocketJourney.switching or GameState.flag("rocket_arriving"):
		_hint_saw_arrival = true
		return false
	var pad := get_tree().root.get_node_or_null("World/Rocket")
	if pad != null:
		for c in pad.find_children("*", "Camera3D", true, false):
			if not c.is_queued_for_deletion():
				_hint_saw_arrival = true
				return false
		var it := pad.find_child("Interactable", true, false)
		if _hint_saw_arrival and it != null and not bool(it.get("enabled")):
			return false
	if EventBus.is_modal_open():
		return false
	var p := get_tree().get_first_node_in_group("player") as Player
	return p != null and p.is_inside_tree() and p.is_physics_processing() and p.input_enabled


func _hint_tick(delta: float) -> void:
	_hint_wait += delta
	if norm == null or not is_instance_valid(norm) or _leaving or quiz_ended_today() or _hint_wait > HINT_GIVE_UP_S:
		_hint_pending = false
		return
	if not arrival_handed_back():
		_hint_calm = 0.0
		return
	_hint_calm += delta
	if _hint_calm < HINT_CALM_S:
		return
	_hint_pending = false
	_hint_shown = true
	print("NormSystem: hint toast after %.2f s: %s" % [_hint_wait, _hint_text])
	EventBus.toast_requested.emit(_hint_text, "star")


func _process(delta: float) -> void:
	if _hint_pending:
		_hint_tick(delta)
	if _leaving and _leave_t >= 0.0 and norm != null and not _in_quiz:
		_leave_tick(delta)
	if not _hint_pending and not _leaving:
		set_process(false)


# ============================================================================= NormLines by path
func _lines() -> Variant:
	return load(LINES_PATH) if ResourceLoader.exists(LINES_PATH) else null


static func _const(lines: Variant, key: String, fallback: Variant) -> Variant:
	if lines is GDScript:
		var m: Dictionary = (lines as GDScript).get_script_constant_map()
		if m.has(key):
			return m[key]
	return fallback


static func _list(lines: Variant, key: String) -> Array:
	var v: Variant = _const(lines, key, [])
	return (v as Array).duplicate() if v is Array else []


static func _pick(lines: Variant, key: String, fallback: String) -> String:
	var a := _list(lines, key)
	if a.is_empty():
		return fallback
	return str(a[randi() % a.size()])


# ============================================================================= dev menu (docs/NORM_SPEC.md §7)
## A note row: "Today: Norm on <world>" or "no Norm today" and why.
static func debug_today() -> String:
	var plan := plan_today()
	var day := int(plan["day"])
	if str(plan["world"]) == "":
		return "Day %d: no Norm today (%s)." % [day, plan["why"]]
	var extra := ""
	if quiz_ended_today():
		extra = ", his quiz already ended today"
	elif _sent_away_day == day:
		extra = ", sent away by the dev menu"
	return "Today (day %d): Norm on %s (%s%s)." % [day, _world_name(str(plan["world"])), plan["why"], extra]


## Norm appears on the current world now (any world, even without a roll; nothing is saved).
static func debug_bring_here() -> String:
	var day := GameState.day_count
	_forced_day = day
	_forced_world = GameState.current_planet_id
	if _sent_away_day == day:
		_sent_away_day = -1
	if quiz_ended_today():
		GameState.flags.erase(K_DONE_DAY)
	var host := find()
	if host == null:
		return "No world is up."
	host.call("restage")
	var n: Variant = host.get("norm")
	if n == null:
		return "Norm could not stand anywhere here."
	return "Norm is on %s now (%.0f deg from the pad)." % [_world_name(_forced_world), float(host.get("spot_angle_deg"))]


static func debug_send_away() -> String:
	_sent_away_day = GameState.day_count
	if _forced_day == GameState.day_count:
		_forced_day = -1
		_forced_world = ""
	var host := find()
	if host != null:
		host.call("_despawn")
	return "Norm is gone for today."


## Sets norm_wins (0-3) and says what the next reward is.
static func debug_set_wins(n: int) -> String:
	GameState.flags[K_WINS] = clampi(n, 0, 3)
	var next := ""
	if ResourceLoader.exists(REWARDS_PATH):
		var rewards: Variant = load(REWARDS_PATH)
		next = str(rewards.next_reward_id())
	return "Norm wins = %d; next reward: %s." % [clampi(n, 0, 3), next if next != "" else "?"]


## One of each reward into the inventory.
static func debug_give_rewards() -> String:
	if not ResourceLoader.exists(REWARDS_PATH):
		return "NormRewards is not in this build."
	var r: Variant = load(REWARDS_PATH)
	r.ensure_items_registered()
	var ids: Array[String] = ["norm_trophy_bronze", "norm_trophy_silver", "norm_trophy_gold", "norm_statue"]
	for id: String in ids:
		GameState.add_item(id, 1)
	return "Added one of each Norm reward to the bag."


## Clears every norm_ key (and the dev menu's own forcing).
static func debug_reset() -> String:
	for k: String in GameState.flags.keys():
		if str(k).begins_with("norm_"):
			GameState.flags.erase(k)
	_forced_day = -1
	_forced_world = ""
	_sent_away_day = -1
	var host := find()
	if host != null:
		host.call("restage")
	return "Norm reset: every norm_ key cleared."


static func _world_name(id: String) -> String:
	var path := PLANET_DATA_DIR + id + ".tres"
	if ResourceLoader.exists(path):
		var data: Resource = load(path)
		if data != null and data.get("display_name") != null:
			return str(data.get("display_name"))
	return id.capitalize()


# ============================================================================= QA (prints only)
## One line a probe or a critic can assert against.
func debug_report(tag: String = "") -> void:
	var at := "none"
	if norm != null and is_instance_valid(norm) and planet != null:
		var d := planet.dir_of(norm.global_position)
		at = "at=%s home=%s from_home_m=%.2f pad_deg=%.1f rules=%s marker=%d marker_visible=%s glyph=%s" % [
			str(d).replace(" ", ""), str(norm.home_dir).replace(" ", ""), planet.surface_distance(d, norm.home_dir),
			rad_to_deg(d.angle_to(planet.data.pad_dir.normalized())), spot_problem(norm.home_dir),
			wants_marker(NPC_ID), str(norm.get_node_or_null("FavorMarker").visible if norm.get_node_or_null("FavorMarker") != null else false),
			str(norm.get("marker_glyph"))]
	var flags := {}
	for k: String in GameState.flags.keys():
		if str(k).begins_with("norm_"):
			flags[k] = GameState.flags[k]
	print("NORM %s planet=%s day=%d plan=%s here=%s norm=[%s] spot_deg=%.1f note=%s leaving=%s in_quiz=%s hint_pending=%s hint_shown=%s flags=%s" % [
		tag, GameState.current_planet_id, GameState.day_count, JSON.stringify(plan_today()), here_today(), at,
		spot_angle_deg, spot_note, str(_leaving), str(_in_quiz), str(_hint_pending), str(_hint_shown), JSON.stringify(flags)])


## SYNTHETIC SCHEDULE PROBE: for each of `days` days from `from_day`, the Norm-day answer and today's
## world, twice (purity), with the current save's gates. Restores the day. Prints only.
static func debug_schedule(from_day: int, days: int) -> void:
	var keep := GameState.day_count
	var hits := 0
	var runs := 0
	var prev := false
	var impure := 0
	var worlds := {}
	for i in days:
		GameState.day_count = from_day + i
		var a := plan_today()
		var b := plan_today()
		if JSON.stringify(a) != JSON.stringify(b) or is_norm_day(GameState.day_count) != is_norm_day(GameState.day_count):
			impure += 1
		var hit := str(a["world"]) != ""
		if hit:
			hits += 1
			worlds[a["world"]] = int(worlds.get(a["world"], 0)) + 1
			if prev:
				runs += 1
		prev = hit
		print("NORMDAY day=%d raw=%s norm_day=%s world=%s why=%s" % [GameState.day_count, str(raw_roll(GameState.day_count)),
			str(is_norm_day(GameState.day_count)), a["world"], a["why"]])
	GameState.day_count = keep
	print("NORMDAYS from=%d days=%d norm_days=%d rate=%.3f two_running=%d impure=%d worlds=%s candidates=%s" % [
		from_day, days, hits, float(hits) / maxf(1.0, float(days)), runs, impure, JSON.stringify(worlds),
		",".join(candidate_worlds())])
