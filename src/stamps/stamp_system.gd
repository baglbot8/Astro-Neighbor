extends Node
## NORM'S STAMP CARD, in the world (docs/DAILY_STAMPS_SPEC.md 2). The rules and the saved state are
## in stamp_card.gd; this node is the part that watches the game, stands Norm on the Commons, talks,
## and puts the chip on the HUD.
##
## ============================================================================== WHERE IT LIVES
## ONE NODE PER WORLD, /root/World/StampSystem, made by NormSystem.attach (src/campaign/
## norm_system.gd, which world.gd already calls for every world) and dying with the world. Nothing
## names this file statically. The Stamps view (stamp_panel.gd) and the chip (stamp_chip.gd) are
## loaded by path.
##
## ============================================================================== WHAT TICKS A TASK
## Existing signals only - no other system was edited to report to the card:
##   deco       EventBus.decoration_placed, or EventBus.item_added of a decoration in the same frame
##              as a stardust spend (a purchase at any shop or stall)
##   talk3      EventBus.dialogue_finished, three different speakers
##   visit2     EventBus.travel_started then EventBus.planet_loaded of that world, two different worlds
##   outfit     EventBus.player_style_changed
##   scrap      EventBus.scrap_changed, the positive deltas
##   materials  EventBus.collectible_picked (not scrap, not the stardust pickup)
##   favour     EventBus.favor_completed
##   tidy       EventBus.trash_changed going down
##   minigame   MinigameSystem.finished(success = true)        (connected when the node appears)
##   safari     PlanetSafari.session_finished                   (connected when a safari starts)
##   fine_photo PlanetSafari.photo_taken with grade Fine or Gallery
##   new_photo  PlanetSafari.photo_taken of a subject the scrapbook has never held
##   album      GameState.flags["home_album_seq"] going up      (polled; HomeAlbumStore has no signal)
##   prints     GameState.flags["gloop_table"] growing          (polled; PrintBag has no signal)
##   quiz       GameState.flags["norm_wins"] going up           (polled; NormRewards has no signal)
## The polls and the new-day check run POLL_HZ times a second, never per frame.
##
## ============================================================================== NORM ON THE COMMONS
## On the hub, whenever `booth_reason()` is "", Norm stands at a fixed spot near the landing pad
## (`_pick_spot`: the first ground near the pad that passes VisitorSystem's ground rules, the rules
## NormSystem uses for his quiz spot). He is this node's NPC (`visit_host`), so conversation.gd hands
## every talk to `handle_conversation` below: the first card, any prize owed, the line of the day,
## "Want to look at your card?". His quiz stays NormSystem's, on the OTHER worlds: while the stamp
## spot is on, NormSystem leaves the hub out of his quiz worlds (two one-line guards there), so there
## are never two Norms on one world.

signal changed

const NODE_NAME := "StampSystem"
const SCRIPT_PATH := "res://src/stamps/stamp_system.gd"
const StampCard := preload("res://src/stamps/stamp_card.gd")
const PANEL_PATH := "res://src/stamps/stamp_panel.gd"
const CHIP_PATH := "res://src/stamps/stamp_chip.gd"
const LINES_PATH := "res://src/campaign/norm_lines.gd"
const NORM_SCENE := "res://src/characters/npcs/norm.tscn"
const NPC_ID := "norm"
const HUB := "hub"
const K_MET := "norm_met"
const POLL_HZ := 4.0
## Norm's spot: rings round the pad, nearest first, this many bearings each.
const SPOT_RINGS_M: Array[float] = [7.0, 9.0, 11.0, 13.0, 16.0, 20.0, 26.0]
const SPOT_BEARINGS := 16
const NPC_CLEAR_M := 3.0
## The spot needs clear ground this far round it, tested at this many points (`_open_round`).
const OPEN_M := 1.8
const OPEN_POINTS := 8
const WANDER_M := 0.9
## The repeat-prize choice shows this many items per page (ask() takes 2-4 pills; one is "More...").
const REPEAT_PAGE := 3

## The world a rocket is flying to; set by travel_started in the old world, read by planet_loaded in
## the new one (this node does not survive the swap).
static var _flight_to := ""
## One "Norm is waving a card" toast per session.
static var _hinted := false

var planet: Planet
var norm: NPC
var spot_note := ""

var _poll_t := 0.0
var _spend_frame := -1
var _trash_last := 0
var _album_last := 0
var _table_last := 0
var _wins_last := 0
var _safari: Node
var _minigames: Node
var _chip: Control
var _open_after_talk := false
var _new_card_toast := false


# ============================================================================= entry points
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


static func find() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("World/" + NODE_NAME)


## "" when Norm may stand at his stamp spot (and the chip may show), otherwise why not. A Director
## run sees neither unless it passes "--campaign" (the opt-in every campaign gate uses) or "--stamps",
## so no existing timeline or capture gains a stranger or a pill.
static func booth_reason() -> String:
	var stage := int(GameState.flags.get("finale_stage", 0))
	if stage == 1 or stage == 2 or stage == 3:
		return "the ending is playing (finale stage %d)" % stage
	if Director.is_active() and not Director.campaign_opt_in() and not OS.get_cmdline_user_args().has("--stamps"):
		return "a Director run without --campaign or --stamps"
	if not CampaignData.planet_in_range(HUB):
		return "the Commons is out of range"
	var tree := Engine.get_main_loop() as SceneTree
	var ob: Node = tree.root.get_node_or_null("World/Onboarding") if tree != null and tree.root != null else null
	if ob != null:
		if ob.get("_crashing") == true or ob.get("_greeting") == true:
			return "onboarding owns the screen"
		var allowed := not ob.has_method("_intro_allowed") or bool(ob.call("_intro_allowed"))
		if allowed and not GameState.flag("intro_greeted") and not GameState.flag("intro_done"):
			return "onboarding owns the screen"
	return ""


## True while Norm's stamp spot owns the hub (NormSystem reads this to keep his quiz off the hub).
static func booth_on() -> bool:
	return booth_reason() == ""


func _ready() -> void:
	planet = get_tree().get_first_node_in_group("planet") as Planet
	EventBus.decoration_placed.connect(func(_p: String, _i: String, _t: String) -> void: _apply(StampCard.progress("deco")))
	EventBus.stardust_changed.connect(_on_stardust)
	EventBus.item_added.connect(_on_item_added)
	EventBus.dialogue_finished.connect(_on_dialogue_finished)
	EventBus.travel_started.connect(func(_f: String, to: String) -> void: _flight_to = to)
	EventBus.planet_loaded.connect(_on_planet_loaded)
	EventBus.player_style_changed.connect(func() -> void: _apply(StampCard.progress("outfit")))
	EventBus.scrap_changed.connect(func(_n: int, d: int) -> void:
		if d > 0:
			_apply(StampCard.progress("scrap", d)))
	EventBus.collectible_picked.connect(func(kind: String, _pos: Vector3) -> void:
		if kind != "scrap" and kind != "stardust_pickup":
			_apply(StampCard.progress("materials")))
	EventBus.favor_completed.connect(func(_f: String, _r: String, _s: int) -> void: _apply(StampCard.progress("favour")))
	EventBus.trash_changed.connect(_on_trash)
	EventBus.game_loaded.connect(_on_state_swapped)
	EventBus.campaign_changed.connect(_on_state_swapped)
	_baseline()
	_new_card_toast = StampCard.roll()
	_stage()
	_add_chip.call_deferred()


# ============================================================================= watching the game
func _baseline() -> void:
	_trash_last = GameState.trash_home.size()
	_album_last = int(GameState.flags.get("home_album_seq", 0))
	_table_last = _table_size()
	_wins_last = int(GameState.flags.get("norm_wins", 0))


static func _table_size() -> int:
	var t: Variant = GameState.flags.get("gloop_table", [])
	return (t as Array).size() if t is Array else 0


## A save was loaded or a new game began under this node: nothing that moved was the player playing.
func _on_state_swapped() -> void:
	_baseline()
	StampCard.roll()
	changed.emit()
	if _chip != null and is_instance_valid(_chip):
		_chip.call("refresh")
		_chip.visible = _chip_wanted()


func _on_stardust(_amount: int, delta: int) -> void:
	if delta < 0:
		_spend_frame = Engine.get_process_frames()


func _on_item_added(item_id: String, _count: int) -> void:
	if _spend_frame == Engine.get_process_frames() and str(Catalog.get_item(item_id).get("kind", "")) == "decoration":
		_apply(StampCard.progress("deco"))


func _on_dialogue_finished(speaker_id: String) -> void:
	if speaker_id != "":
		_apply(StampCard.mark("talk3", speaker_id))


func _on_planet_loaded(planet_id: String) -> void:
	if _flight_to != "" and planet_id == _flight_to:
		_apply(StampCard.mark("visit2", planet_id))
	_flight_to = ""
	if _new_card_toast:
		_new_card_toast = false
		_toast(_any("STAMP_TOAST_NEW", "A new stamp card from Norm!"), "star")
	if norm != null and is_instance_valid(norm) and not StampCard.is_on() and not _hinted:
		_hinted = true
		_toast(str(_const("STAMP_HINT", "Norm is waving a little card at you.")), "star")


func _on_trash(count: int) -> void:
	if count < _trash_last:
		_apply(StampCard.progress("tidy", _trash_last - count))
	_trash_last = count


func _on_photo(photo: Dictionary) -> void:
	if int(photo.get("grade_idx", 0)) >= 2:
		_apply(StampCard.progress("fine_photo"))
	var key := str(photo.get("subject_key", ""))
	if key != "" and not StampCard.photographed(key):
		_apply(StampCard.progress("new_photo"))


func _on_safari_finished(_session: Dictionary) -> void:
	_apply(StampCard.progress("safari"))


func _on_minigame_finished(_kind: String, success: bool, _config: Dictionary) -> void:
	if success:
		_apply(StampCard.progress("minigame"))


func _process(delta: float) -> void:
	_poll_t += delta
	if _poll_t < 1.0 / POLL_HZ:
		return
	_poll_t = 0.0
	# A new real day while the game is open.
	if StampCard.roll():
		changed.emit()
		_refresh_chip()
		_toast(_any("STAMP_TOAST_NEW", "A new stamp card from Norm!"), "star")
	# The three systems with no signal.
	var album := int(GameState.flags.get("home_album_seq", 0))
	if album > _album_last:
		_apply(StampCard.progress("album"))
	_album_last = album
	var table := _table_size()
	if table > _table_last:
		_apply(StampCard.progress("prints"))
	_table_last = table
	var wins := int(GameState.flags.get("norm_wins", 0))
	if wins > _wins_last:
		_apply(StampCard.progress("quiz"))
	_wins_last = wins
	# The two nodes that come and go.
	var s: Variant = PlanetSafari.current
	if s != null and is_instance_valid(s) and s != _safari:
		_safari = s
		(s as Node).connect("photo_taken", _on_photo)
		(s as Node).connect("session_finished", _on_safari_finished)
	var mg: Node = get_parent().get_node_or_null("MinigameSystem") if get_parent() != null else null
	if mg != null and mg != _minigames and mg.has_signal("finished"):
		_minigames = mg
		mg.connect("finished", _on_minigame_finished)
	if _open_after_talk and not EventBus.is_modal_open():
		_open_after_talk = false
		open_view()
	if _chip != null and is_instance_valid(_chip):
		_chip.visible = _chip_wanted()


## What a tick did, said out loud: one toast for the biggest thing that happened.
func _apply(res: Dictionary) -> void:
	if res.is_empty():
		return
	changed.emit()
	_refresh_chip()
	if res.get("prize", false):
		_toast(str(_const("STAMP_TOAST_STAMP", "Stamp! %d of 5 this week.")) % StampCard.week_stamps().size(), "check")
		_toast(str(_const("STAMP_TOAST_PRIZE", "5 stamps! Norm has your prize on the Commons.")), "star")
		UIStyle.play_sfx("ui_confirm", -4.0)
	elif res.get("stamp", false):
		_toast(str(_const("STAMP_TOAST_STAMP", "Stamp! %d of 5 this week.")) % StampCard.week_stamps().size(), "check")
		UIStyle.play_sfx("ui_confirm", -4.0)
	elif res.get("task", false):
		_toast(str(_const("STAMP_TOAST_TICK", "Stamp card: %d of 3 done")) % mini(StampCard.done_count(), StampCard.NEED), "check")


func _toast(text: String, icon: String) -> void:
	EventBus.toast_requested.emit(text, icon)


## Opens the Stamps view; while a dialogue or another menu is up it waits for that to close.
func open_view() -> void:
	if EventBus.is_modal_open():
		_open_after_talk = true
		return
	if ResourceLoader.exists(PANEL_PATH):
		load(PANEL_PATH).call("open_over", self)


# ============================================================================= the HUD chip
func _chip_wanted() -> bool:
	return StampCard.is_on() or booth_on()


func _add_chip() -> void:
	if not ResourceLoader.exists(CHIP_PATH) or not is_inside_tree():
		return
	var hud := get_tree().root.get_node_or_null("World/HUD")
	if hud == null:
		return
	var parent: Variant = hud.get("_world_chrome")
	if not (parent is Control) or (parent as Control).get_node_or_null("StampChip") != null:
		return
	_chip = (load(CHIP_PATH) as GDScript).new()
	_chip.visible = _chip_wanted()
	(parent as Control).add_child(_chip)
	_chip.call("bind", hud)


func _refresh_chip() -> void:
	if _chip != null and is_instance_valid(_chip):
		_chip.call("refresh")


# ============================================================================= Norm on the Commons
func _stage() -> void:
	if planet == null or planet.data == null or GameState.current_planet_id != HUB:
		return
	var why := booth_reason()
	if why != "":
		print("StampSystem: no Norm on the Commons (%s)" % why)
		return
	if not ResourceLoader.exists(NORM_SCENE):
		return
	var vs := get_tree().root.get_node_or_null("World/VisitorSystem")
	if vs == null or not vs.has_method("ground_problem"):
		push_warning("StampSystem: no VisitorSystem on this world; Norm stays away")
		return
	vs.call("ground_problem", planet.data.pad_dir.normalized())   # warms its caches for this world
	var spot := _pick_spot(vs)
	if spot == Vector3.ZERO:
		push_warning("StampSystem: no ground near the pad passes the rules; Norm stays away")
		return
	var root := get_tree().root.get_node_or_null("World/NPCs")
	if root == null or root.get_node_or_null(NPC_ID) != null:
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
	print("StampSystem: Norm at his stamp spot on the Commons, %s" % spot_note)


func _spot_problem(vs: Node, dir: Vector3) -> String:
	var why := str(vs.call("_ground_problem", dir)) if vs.has_method("_ground_problem") else str(vs.call("ground_problem", dir))
	if why != "":
		return why
	var npcs := get_tree().root.get_node_or_null("World/NPCs")
	if npcs != null:
		for c: Node in npcs.get_children():
			var other := c as NPC
			if other == null or other == norm or other.npc_id == NPC_ID:
				continue
			if planet.surface_distance(dir.normalized(), other.home_dir) < NPC_CLEAR_M:
				return "neighbour:" + other.npc_id
	return ""


## The first clear ground on rings round the pad, nearest ring first. Fixed order, so he stands in
## the same place every day unless something has been built there.
func _pick_spot(vs: Node) -> Vector3:
	var pad := planet.data.pad_dir.normalized()
	var t1 := pad.cross(Vector3.UP)
	if t1.length_squared() < 1e-6:
		t1 = pad.cross(Vector3.RIGHT)
	t1 = t1.normalized()
	var t2 := pad.cross(t1).normalized()
	var tested := 0
	for ring: float in SPOT_RINGS_M:
		var a := ring / planet.radius
		for k in SPOT_BEARINGS:
			var th := TAU * float(k) / float(SPOT_BEARINGS)
			var d := (pad * cos(a) + (t1 * cos(th) + t2 * sin(th)) * sin(a)).normalized()
			tested += 1
			if _spot_problem(vs, d) == "" and _open_round(vs, d):
				spot_note = "%.0f m from the pad (tested %d)" % [ring, tested]
				return d
	return Vector3.ZERO


## True when the ground OPEN_M round `dir` passes the rules too: he stands in the open, with room to
## shuffle about and for the player to walk up, not wedged between a planter and a sign.
func _open_round(vs: Node, dir: Vector3) -> bool:
	var t1 := dir.cross(Vector3.UP)
	if t1.length_squared() < 1e-6:
		t1 = dir.cross(Vector3.RIGHT)
	t1 = t1.normalized()
	var t2 := dir.cross(t1).normalized()
	var a := OPEN_M / planet.radius
	for k in OPEN_POINTS:
		var th := TAU * float(k) / float(OPEN_POINTS)
		if _spot_problem(vs, (dir * cos(a) + (t1 * cos(th) + t2 * sin(th)) * sin(a)).normalized()) != "":
			return false
	return true


## npc.gd asks this for every wander target.
func wander_ok(dir: Vector3) -> bool:
	var vs := get_tree().root.get_node_or_null("World/VisitorSystem")
	return vs != null and _spot_problem(vs, dir) == ""


## npc.gd's marker: shown while he has something new for the player - the first card, a prize, or
## today's line not yet heard.
func wants_marker(npc_id: String) -> int:
	if npc_id != NPC_ID:
		return 0
	if not StampCard.is_on() or StampCard.owed() > 0:
		return 1
	return 1 if str(StampCard.peek().get("chat", "")) != StampCard.today() else 0


# ============================================================================= talk
## conversation.gd hands every talk with the Commons' Norm here. Awaits until said.
func handle_conversation(runner: DialogueRunner, npc: NPC) -> void:
	var day := StampCard.day_number(StampCard.today())
	if not GameState.flag(K_MET):
		# Committed before the lines, as NormSystem does: the intro plays once ever.
		GameState.flags[K_MET] = true
		var intro := _list("INTRO")
		if intro.is_empty():
			intro = ["Greetings, fellow Earth person. I am Norm. A normal human."]
		await runner.say(npc, intro)
	if not StampCard.is_on():
		var first := _list("STAMP_INTRO")
		if first.is_empty():
			first = ["I made you a card! Do any 3 things on it for a stamp."]
		StampCard.start()
		(StampCard._s())["chat"] = StampCard.today()
		changed.emit()
		_refresh_chip()
		await runner.say(npc, first)
		_toast(str(_const("STAMP_TOAST_CARD", "You got Norm's stamp card!")), "star")
		_open_after_talk = true
		return
	StampCard.roll()
	# ---- prizes first: every one owed, oldest first
	while StampCard.owed() > 0:
		var choice := ""
		if StampCard.next_prize() == "":
			choice = await _ask_repeat(runner, npc)
			if choice == "":
				break
		await runner.say(npc, [_pick("STAMP_PRIZE", "5 stamps! Here is your prize.", day + StampCard.given().size())])
		var id := StampCard.claim(choice)
		if id == "":
			break
		npc.play_emote("happy")
		var def := Catalog.get_item(id)
		_toast("You got: %s" % str(def.get("name", id)), id)
		print("StampSystem: prize %s handed over (owed now %d)" % [id, StampCard.owed()])
		changed.emit()
		await runner.say(npc, ["%s!" % str(def.get("name", "A prize")), _pick("STAMP_PRIZE_AFTER", "Put it somewhere nice.", day + StampCard.given().size())])
	# ---- the line of the day, once a day; then where the card stands
	var s := StampCard._s()
	var lines: Variant = _lines()
	var said: Array = []
	if str(s.get("chat", "")) != StampCard.today():
		s["chat"] = StampCard.today()
		if lines is GDScript and (lines as GDScript).has_method("stamp_daily"):
			said.append(str((lines as GDScript).call("stamp_daily", day)))
	said.append(_status_line(day))
	await runner.say(npc, said)
	var pick := await runner.ask(npc, str(_const("STAMP_CARD_ASK", "Want to look at your card?")), _options())
	if pick == 0:
		_open_after_talk = true
	else:
		await runner.say(npc, [_pick("STAMP_BYE", "Goodbye, fellow human.", day + StampCard.done_count())])


func _options() -> Array:
	var o := _list("STAMP_CARD_OPTIONS")
	return o if o.size() >= 2 else ["Show me", "Bye, Norm"]


func _status_line(day: int) -> String:
	var done := StampCard.done_count()
	var week := StampCard.week_stamps().size()
	if StampCard.stamped_today():
		if week >= StampCard.WEEK_NEED:
			return _pick("STAMP_WEEK_DONE", "5 stamps this week! The week is won.", day)
		return _pick("STAMP_STAMPED", "Stamped! Today is done.", day) if week <= 1 \
			else str(_pick("STAMP_WEEK", "That makes %d of 5 stamps this week.", day)) % week
	if done <= 0:
		return _pick("STAMP_NONE", "No ticks yet. Any 3 things.", day)
	return str(_pick("STAMP_SOME", "%d more and I stamp it.", day)) % (StampCard.NEED - done)


## Every new prize is given: any stamp decoration again, REPEAT_PAGE names a page. "" = walked away.
func _ask_repeat(runner: DialogueRunner, npc: NPC) -> String:
	var all := StampCard.repeat_choices()
	if all.is_empty():
		return ""
	var prompt := str(_const("STAMP_REPEAT_ASK", "I ran out of new prizes. Pick an old favourite!"))
	var page := 0
	var pages := int(ceil(float(all.size()) / float(REPEAT_PAGE)))
	while true:
		var ids: Array[String] = all.slice(page * REPEAT_PAGE, page * REPEAT_PAGE + REPEAT_PAGE)
		var opts: Array = []
		for id: String in ids:
			opts.append(str(Catalog.get_item(id).get("name", id)))
		if pages > 1:
			opts.append(str(_const("STAMP_MORE", "More...")))
		if opts.size() < 2:
			opts.append("Not now")
		var pick := await runner.ask(npc, prompt, opts)
		if pick < 0:
			return ""
		if pick < ids.size():
			return ids[pick]
		if pages > 1:
			page = (page + 1) % pages
		else:
			return ""
	return ""


# ============================================================================= NormLines by path
func _lines() -> Variant:
	return load(LINES_PATH) if ResourceLoader.exists(LINES_PATH) else null


func _const(key: String, fallback: Variant) -> Variant:
	var lines: Variant = _lines()
	if lines is GDScript:
		var m: Dictionary = (lines as GDScript).get_script_constant_map()
		if m.has(key):
			return m[key]
	return fallback


func _list(key: String) -> Array:
	var v: Variant = _const(key, [])
	return (v as Array).duplicate() if v is Array else []


## A line from list `key`, walked by `n` (the date, mostly) so the same day gives the same line and
## the next day the next one.
func _pick(key: String, fallback: String, n: int) -> String:
	var a := _list(key)
	if a.is_empty():
		return fallback
	return str(a[posmod(n, a.size())])


func _any(key: String, fallback: String) -> String:
	var a := _list(key)
	return str(a[randi() % a.size()]) if not a.is_empty() else fallback


# ============================================================================= dev menu rows
# Static, each returns one line to show: the shape dev_menu.gd's `_hook_row` calls (as it does
# NormSystem's debug_today / debug_reset). Nothing here saves.
static func _after_dev() -> void:
	var host := find()
	if host != null:
		host.emit_signal("changed")
		host.call("_refresh_chip")


static func dev_status() -> String:
	if not StampCard.is_on():
		return "No card yet (date %s). Norm hands it over on the Commons." % StampCard.today()
	return "%s: %d of %d tasks, %d stamps this week, %d prize(s) owed, next prize %s." % [StampCard.today(),
		StampCard.done_count(), StampCard.NEED, StampCard.week_stamps().size(), StampCard.owed(),
		StampCard.week_prize() if StampCard.week_prize() != "" else "a choice"]


static func dev_start() -> String:
	StampCard.start()
	_after_dev()
	return "Card handed over. " + dev_status()


## Ticks tasks until today's stamp is earned, through the real progress path (toasts and all).
static func dev_stamp_today() -> String:
	if not StampCard.is_on():
		return "No card yet."
	var res := StampCard.debug_tick(StampCard.NEED - mini(StampCard.done_count(), StampCard.NEED))
	var host := find()
	if host != null:
		host.call("_apply", res)
	return dev_status()


static func dev_next_day() -> String:
	StampCard.debug_advance(1)
	return "Now %s (set by hand). The new card arrives in a moment." % StampCard.today()


static func dev_real_date() -> String:
	return StampCard.debug_set_date("")


static func dev_reset() -> String:
	StampCard.debug_set_date("")
	var out := StampCard.debug_reset()
	_after_dev()
	return out


# ============================================================================= dev / test
## Director: {"call": {"node": "/root/World/StampSystem", "method": "debug_date", "args": ["2026-10-05"]}}
func debug_date(date: String) -> void:
	print("StampSystem: " + StampCard.debug_set_date(date))


func debug_advance(days: int = 1) -> void:
	print("StampSystem: " + StampCard.debug_advance(days))


## Norm hands over the card without the talk.
func debug_start() -> void:
	StampCard.start()
	changed.emit()
	_refresh_chip()


## Ticks `n` unfinished tasks through the real progress path (stamps, prizes and toasts follow).
func debug_tick(n: int = 3) -> void:
	_apply(StampCard.debug_tick(n))


## A REAL InputEventScreenTouch on the middle of the HUD chip (TouchControls.debug_touch_real sends
## it through Input.parse_input_event), down then up a moment later. Needs --ui=mobile.
func debug_tap_chip() -> void:
	var tc := get_tree().root.find_child("TouchControls", true, false)
	if _chip == null or not is_instance_valid(_chip) or tc == null or not tc.has_method("debug_touch_real"):
		print("StampSystem: no chip or no TouchControls to tap")
		return
	var c: Vector2 = _chip.get_global_transform() * (_chip.size * 0.5)
	print("StampSystem: tapping the chip at %s (chip rect %s, visible %s)" % [str(c), str(_chip.get_global_rect()), str(_chip.is_visible_in_tree())])
	tc.call("debug_touch_real", 7, c.x, c.y, true)
	await get_tree().create_timer(0.12).timeout
	tc.call("debug_touch_real", 7, c.x, c.y, false)


## Stands the player `dist_m` from Norm, on the pad side, facing him (a talk can start from there).
func debug_go_to_norm(dist_m: float = 1.7) -> void:
	var p := get_tree().get_first_node_in_group("player") as Node3D
	if norm == null or not is_instance_valid(norm) or p == null:
		print("StampSystem: no Norm here to walk to")
		return
	var nd := planet.dir_of(norm.global_position)
	var pad := planet.data.pad_dir.normalized()
	var toward := (pad - nd * pad.dot(nd)).normalized()
	var a := dist_m / planet.radius
	p.call("teleport_to_dir", (nd * cos(a) + toward * sin(a)).normalized())
	p.call("face_toward", norm.global_position)


## Stamps `n` days running from this week's Monday (3 tasks each), leaving the date on the day after
## the last one. `debug_fill_week(5)` leaves one prize owed.
func debug_fill_week(n: int = 5) -> void:
	if not StampCard.is_on():
		StampCard.start()
	StampCard.debug_set_date(StampCard.week_start(StampCard.today()))
	for i in n:
		StampCard.roll()
		StampCard.debug_tick(StampCard.NEED)
		StampCard.debug_advance(1)
	StampCard.roll()
	changed.emit()
	_refresh_chip()
	print(StampCard.debug_line())


func debug_report(tag: String = "") -> void:
	var at := "none"
	if norm != null and is_instance_valid(norm) and planet != null:
		at = "pad_m=%.1f marker=%d" % [planet.surface_distance(planet.dir_of(norm.global_position), planet.data.pad_dir.normalized()), wants_marker(NPC_ID)]
	print("%s %s planet=%s booth=%s norm=[%s] chip=%s" % [StampCard.debug_line(), tag, GameState.current_planet_id,
		booth_reason() if booth_reason() != "" else "on", at,
		str(_chip.visible) if _chip != null and is_instance_valid(_chip) else "none"])
