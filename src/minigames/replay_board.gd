extends Node
## THE COMMONS GAME BOARD: replay any mini-game the story has unlocked.
## docs/CORE_LOOP.md "Replays from the Commons" (decided 2026-09-13); docs/BUILD_PLAN.md Phase 3a.
##
## The user: "let people play those mini games if they want optionally so they're not just 1 time use
## and never seen again", and "in the commons you can pick which game you want and it temporarily
## takes you to the world where the game was originally done".
##
## ============================================================================== WHERE IT LIVES
## ONE NODE PER WORLD, made by the single guarded hook at the end of world.gd `_ready`:
##
##     if ResourceLoader.exists(REPLAY_BOARD_PATH):
##         load(REPLAY_BOARD_PATH).attach(self)
##
## It is /root/World/ReplayBoard and it dies with the world. That is the whole of "flying away ends a
## replay": the MinigameSystem that runs the game is a child of the same world, so leaving frees both.
##   * On the Commons ("hub") it stands the board (replay_board_prop.gd) and opens the list
##     (replay_board_panel.gd) when the player uses it.
##   * On EVERY world it reads and immediately CLEARS the pending-trip flag that Play wrote, waits for
##     the landing to settle, and starts the game.
##   * When a replay is finished it pays, toasts, and offers the flight back to the Commons.
##
## ============================================================================== THE TRIP
## Play closes the panel, writes GameState.flags[FLAG_PENDING] and calls /root/World/Rocket
## `launch_to(planet)` - the ordinary pad, walk, climb, cruise and landing. The flag is a plain
## Dictionary {key, npc, step, planet, session}: JSON-safe, and "npc" + "step" are enough to look the
## entry up again (ProjectSystem.played_minigames()). GameState.set_flag() only takes a bool, so the
## flag is written straight into GameState.flags, the same way hint_channel.gd writes its own keys.
##
## A STALE FLAG CAN NEVER START A GAME, on any path:
##   * every world load clears it in `_ready`, whether or not this load is the arrival it was for;
##   * it is honoured only if this load really is a rocket arrival (the pad has `rocket_arriving`
##     up), onto the planet the flag names, and the flag carries THIS app session's token - so a save
##     that somehow held one, loaded later or after a restart, starts nothing;
##   * if `launch_to` refuses (the pad busy, a journey already switching) Play clears it at once.
## Nothing can save while it is set: the launch opens the "cutscene" modal before the first frame, and
## the pause menu, the only save button away from the house, is closed to modals the whole flight.
##
## ============================================================================== ARRIVAL: WHEN TO START
## CHOSEN: the modal gate lifting after the landing - EventBus.ui_modal_closed, re-checked with the
## whole settled state (no modal open, player thawed and processing physics, no `rocket_arriving`,
## no scene switch). NOT `player.input_enabled` turning true, because:
##   1. rocket_pad.gd `_finish_arrival` thaws the player (input_enabled = true) and only THEN drops
##      the flight camera and closes the "cutscene" modal. Starting on the input flip would run the
##      game's setup a line before the gameplay camera and the touch controls are back.
##   2. input_enabled has no signal (it would need polling every frame), and it is also written by the
##      dialogue runner and by every modal close, so "it turned true" does not mean "the landing ended".
##   3. The modal gate is what the HUD, the touch controls and the pause menu key off, so the game
##      starts on the same frame the player gets their controls back - never under a dialogue a
##      landing might open, because any modal still open keeps waiting for ITS close.
## The check runs deferred, after the rest of `_finish_arrival` has run.
##
## If a PROJECT mini-game is already running there when it settles, the replay does not start and a
## toast says why (the story step comes first). Owners are "replay:<npc>:<step>" - never "project:" -
## so ProjectSystem._sync_minigames can never cancel a replay, and its progress/finish handlers ignore
## it (they only parse "project:" owners). A replay writes nothing to GameState.projects.
##
## ============================================================================== FINISH
## First success of each board entry on each game day pays REPLAY_STARDUST and toasts
## "Nice! +10 stardust"; later ones that day toast "Nice!". The day is remembered per entry in
## GameState.flags["replay_paid_day:<key>"] (saved, on purpose: a reload must not pay twice). Then
## ConfirmPopup asks "Nice! +10 stardust." / "Fly back to The Commons?" (`fly_back_text`) - Yes
## flies there with `launch_to("hub")`, Stay leaves an ordinary world with nothing running.
##   * THE REWARD IS IN THE QUESTION (fix round 1). The popup is a full-screen modal, so the HUD
##     slides every live toast away when it opens (hud.gd `_apply_toast_spot`, TOAST_HIDE_FAST): the
##     reward toast was covered 1.4-1.7 s after it appeared (lead, round 2). Its own first line says
##     it again, so the reward is on screen until the player answers.
##   * THE COMMONS BY ITS SHOWN NAME. The player never reads "the Commons": the HUD, the arrival
##     banner and the rocket's picker all name the hub by its PlanetData display_name (hub.tres,
##     "The Commons"), read here through Hud.planet_display_name, so a rename changes this too.
##
## ============================================================================== DEPENDENCIES
## ProjectSystem and MinigameSystem are reached by PATH only (docs/OPEN_ISSUES.md 46 and 49-50: a file
## that can ship without its dependency must never name that class statically). Everything else used
## here (GameState, EventBus, Planet, Player, ConfirmPopup, UIStyle, MobileUI, Hud, NpcData,
## CampaignData, RocketJourney, SceneRouter) has shipped in every build since Phase 1.

const NODE_NAME := "ReplayBoard"
const HUB_ID := "hub"

const PROJECT_SYSTEM_PATH := "res://src/projects/project_system.gd"
const MINIGAME_SYSTEM_PATH := "res://src/minigames/minigame_system.gd"
const CATCH_GAME_PATH := "res://src/minigames/catch_game.gd"
const DEV_MENU_PATH := "res://src/ui/pause/dev_menu.gd"
## Read by path only (see "DEPENDENCIES" above): FinaleState ships from Phase 5 on, but this file
## must still parse and run in a build that predates it.
const FINALE_STATE_PATH := "res://src/campaign/finale_state.gd"
const PROP_SCRIPT := preload("res://src/minigames/replay_board_prop.gd")
const PANEL_SCRIPT := preload("res://src/minigames/replay_board_panel.gd")

## Stardust for the first finish of each board entry on each game day. A PHASE 6 PACING NUMBER
## (docs/BUILD_PLAN.md "Phase 6: Pacing pass"): a first guess, small on purpose next to a project
## step, to be tuned from a timed play-through. CORE_LOOP: "a little stardust ... not a promise".
const REPLAY_STARDUST := 10

const FLAG_PENDING := "replay_pending"
const FLAG_PAID_PREFIX := "replay_paid_day:"
const OWNER_PREFIX := "replay:"
## Session token for the pending flag, kept on Engine (not saved, survives scene swaps).
const SESSION_META := "astro_replay_session"
## The dev menu's "board shows every game" runtime switch. On Engine for the same reason: a static
## var would be lost whenever this script is unloaded between two scenes, and GameState.flags is saved.
const DEV_SHOW_ALL_META := "astro_replay_dev_show_all"

## Seconds between the finish and the fly-back question, so the last catch and the toast read first.
const FLY_BACK_DELAY := 1.4

## What each game is, in words that say what you do and whose it is. {npc} is the neighbour's name,
## {things} the game's plural noun (see `_things`). docs/STYLE_GUIDE.md "Writing": <= 60 characters.
const TITLES := {
	"catch": "Catch {npc}'s runaway {things}",
	"rings": "Fly {npc}'s ring run",
	"guide": "Guide {npc}'s {things} home",
	"hunt": "Find {npc}'s hidden {things}",
	"call": "Call and response with {npc}",
}
const DEFAULT_THINGS := {"catch": "things", "guide": "strays", "hunt": "signals"}
const TITLE_MAX := 60
## docs/STYLE_GUIDE.md "Writing": at most 60 characters on a line.
const LINE_MAX := 60

const TEXT_LOCKED := "More games unlock as you help your neighbours"
## %s is the hub's display name (see "THE COMMONS BY ITS SHOWN NAME").
const TEXT_FLY_BACK := "Fly back to %s?"
## Only if a renamed hub made the line above longer than LINE_MAX: true whatever the hub is called.
const TEXT_FLY_BACK_SHORT := "Fly back to the game board?"

var _planet: Planet
var _prop: Node3D
var _ui_root: Control
var _panel: Control
var _confirm: ConfirmPopup

## The board entry waiting for the landing to settle ({} when none).
var _pending: Dictionary = {}
## The replay running now: its owner string and entry ({} / "" when none).
var _owner := ""
var _running: Dictionary = {}
var _asking := false
var _launching := false
## The reward words of the replay just finished ("Nice! +10 stardust"), for the fly-back question.
var _reward := ""


# ============================================================================= entry point
## Called once per world by world.gd. Returns the host (also for a test rig).
static func attach(world: Node) -> Node:
	if world == null or not world.is_inside_tree():
		return null
	var existing := world.get_node_or_null(NODE_NAME)
	if existing != null:
		return existing
	var host: Node = (load("res://src/minigames/replay_board.gd") as GDScript).new()
	host.name = NODE_NAME
	world.add_child(host)
	return host


func _ready() -> void:
	_planet = get_tree().get_first_node_in_group("planet") as Planet
	_read_pending_flag()
	if GameState.current_planet_id == HUB_ID and _planet != null:
		_spawn_board()
	EventBus.ui_modal_closed.connect(_on_modal_closed)
	MobileUI.on_mode_changed(_on_platform_mode_changed)
	if not _pending.is_empty():
		call_deferred("_try_start_pending")


# ============================================================================= static: the list
## Every game the board lists right now, in the story's neighbour order. One Dictionary each:
##   key     "<npc>:<step>" for a story step, "dev:<kind>" for a dev stand-in (see set_dev_show_all)
##   npc, step, game, planet, count, config   as ProjectSystem.played_minigames() gives them
##   title   "Catch Bolt's runaway bolts"     world   "Bolt's Chrome Yard"
## Only games whose script is in this build (MinigameSystem.has_game) are listed.
static func entries() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var keys := {}
	if ResourceLoader.exists(PROJECT_SYSTEM_PATH):
		var played: Variant = load(PROJECT_SYSTEM_PATH).call("played_minigames")
		if played is Array:
			for raw: Variant in played:
				if raw is Dictionary:
					_add_entry(out, keys, raw as Dictionary)
	if dev_show_all():
		_add_dev_entries(out, keys)
	return out


## True while the story still has games to unlock (drives the one quiet line under the list). The
## story is five neighbours and each has one mini-game (CORE_LOOP "More mini-games, one per
## neighbour"), so it is "gates on and fewer than five games unlocked". It counts what the STORY has
## unlocked (ProjectSystem.played_minigames), never what the dev switch lists. Once the story is over
## the gates are off, every game is unlocked, and there is no line.
static func has_locked_games() -> bool:
	if not CampaignData.gates_on():
		return false
	var unlocked := 0
	if ResourceLoader.exists(PROJECT_SYSTEM_PATH):
		var played: Variant = load(PROJECT_SYSTEM_PATH).call("played_minigames")
		if played is Array:
			unlocked = (played as Array).size()
	return unlocked < CampaignData.PARTS.size()


static func find_entry(key: String) -> Dictionary:
	for e: Dictionary in entries():
		if str(e["key"]) == key:
			return e
	return {}


static func owner_for(key: String) -> String:
	return OWNER_PREFIX + key


## The dev menu's runtime switch: list every game with a script, locked or not, for testing. NOT
## saved. A game that has a project step anywhere is listed as that step; a game no project uses yet
## gets a stand-in on the world its neighbour will use (dev_menu.gd MINIGAME_HOMES).
static func set_dev_show_all(on: bool) -> void:
	Engine.set_meta(DEV_SHOW_ALL_META, on)


static func dev_show_all() -> bool:
	return Engine.has_meta(DEV_SHOW_ALL_META) and bool(Engine.get_meta(DEV_SHOW_ALL_META))


static func _add_entry(out: Array[Dictionary], keys: Dictionary, raw: Dictionary) -> void:
	var game := str(raw.get("game", ""))
	if not _has_game(game):
		return
	var npc := str(raw.get("npc", ""))
	var step := int(raw.get("step", 0))
	var key := "%s:%d" % [npc, step]
	if keys.has(key):
		return
	keys[key] = true
	out.append(_finish_entry(key, npc, step, game, str(raw.get("planet", "")),
		maxi(1, int(raw.get("count", 1))), raw.get("config", {}) as Dictionary))


static func _add_dev_entries(out: Array[Dictionary], keys: Dictionary) -> void:
	# Every project step of type minigame, locked or not.
	var kinds_with_step := {}
	if ResourceLoader.exists(PROJECT_SYSTEM_PATH):
		var defs: Variant = load(PROJECT_SYSTEM_PATH).call("all_definitions")
		if defs is Array:
			for d: Variant in defs:
				if not (d is Dictionary):
					continue
				var npc := str((d as Dictionary).get("npc", ""))
				var steps: Array = (d as Dictionary).get("steps", [])
				for i in steps.size():
					var step: Dictionary = steps[i]
					if str(step.get("type", "")) != "minigame":
						continue
					var game := str(step.get("game", ""))
					kinds_with_step[game] = true
					var planet := str(step.get("planet", NpcData.get_data(npc).get("planet", npc)))
					_add_entry(out, keys, {"npc": npc, "step": i, "game": game, "planet": planet,
						"count": maxi(1, int(step.get("count", 1))),
						"config": (step.get("config", {}) as Dictionary).duplicate(true)})
	# A stand-in for every other game that has a script.
	var dev := _dev_menu_consts()
	var homes: Dictionary = dev.get("MINIGAME_HOMES", {})
	# The world -> look table lives in catch_game.gd since 2026-09-13 (dev_menu.gd's copy was deleted).
	var flavours: Dictionary = {}
	if ResourceLoader.exists(CATCH_GAME_PATH):
		var catch_script := load(CATCH_GAME_PATH) as GDScript
		if catch_script != null:
			flavours = catch_script.get_script_constant_map().get("PLANET_DEFAULT_FLAVOUR", {})
	var counts: Dictionary = dev.get("MINIGAME_DEV_COUNTS", {})
	for kind: String in _game_kinds():
		if kinds_with_step.has(kind) or not _has_game(kind):
			continue
		var key := "dev:" + kind
		if keys.has(key):
			continue
		keys[key] = true
		var world := str(homes.get(kind, "bolt"))
		var npc := _neighbour_of(world)
		var cfg := {"flavour": str(flavours.get(world, "bolt"))}
		out.append(_finish_entry(key, npc, -1, kind, world, maxi(1, int(counts.get(kind, 5))), cfg))


static func _finish_entry(key: String, npc: String, step: int, game: String, planet: String,
		count: int, config: Dictionary) -> Dictionary:
	if planet == "":
		planet = str(NpcData.get_data(npc).get("planet", npc))
	return {
		"key": key, "npc": npc, "step": step, "game": game, "planet": planet, "count": count,
		"config": config.duplicate(true),
		"title": entry_title(game, npc, config),
		"world": Hud.planet_display_name(planet),
	}


## "Catch Bolt's runaway bolts". Never longer than TITLE_MAX.
static func entry_title(game: String, npc: String, config: Dictionary) -> String:
	var who := str(NpcData.get_data(npc).get("display_name", npc.capitalize()))
	var pattern := str(TITLES.get(game, "Play {npc}'s %s" % game.capitalize()))
	var t := pattern.replace("{npc}", who).replace("{things}", _things(game, config))
	if t.length() > TITLE_MAX:
		t = "Play %s's game" % who
	return t


## The game's plural noun: the step's own "label_plural" first, then (for the two games that share
## catch_game.gd's FLAVOURS table) the flavour's plural, then a plain default.
static func _things(game: String, config: Dictionary) -> String:
	var own := str(config.get("label_plural", ""))
	if own != "":
		return own
	if game == "catch" or game == "guide":
		var flavour := str(config.get("flavour", ""))
		if flavour != "" and ResourceLoader.exists(CATCH_GAME_PATH):
			var script := load(CATCH_GAME_PATH) as GDScript
			var table: Variant = script.get_script_constant_map().get("FLAVOURS", {}) if script != null else {}
			if table is Dictionary and (table as Dictionary).has(flavour):
				var plural := str(((table as Dictionary)[flavour] as Dictionary).get("plural", ""))
				if plural != "":
					return plural
	return str(DEFAULT_THINGS.get(game, "things"))


static func _has_game(kind: String) -> bool:
	if kind == "" or not ResourceLoader.exists(MINIGAME_SYSTEM_PATH):
		return false
	return bool(load(MINIGAME_SYSTEM_PATH).call("has_game", kind))


static func _game_kinds() -> Array:
	if not ResourceLoader.exists(MINIGAME_SYSTEM_PATH):
		return []
	var script := load(MINIGAME_SYSTEM_PATH) as GDScript
	var games: Variant = script.get_script_constant_map().get("GAMES", {}) if script != null else {}
	return (games as Dictionary).keys() if games is Dictionary else []


static func _dev_menu_consts() -> Dictionary:
	if not ResourceLoader.exists(DEV_MENU_PATH):
		return {}
	var script := load(DEV_MENU_PATH) as GDScript
	return script.get_script_constant_map() if script != null else {}


static func _neighbour_of(world: String) -> String:
	for p: Dictionary in CampaignData.PARTS:
		var npc := str(p.get("npc", ""))
		if str(NpcData.get_data(npc).get("planet", "")) == world:
			return npc
	return world


static func _session_token() -> String:
	if not Engine.has_meta(SESSION_META):
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		Engine.set_meta(SESSION_META, "%d-%d" % [int(Time.get_unix_time_from_system()), rng.randi()])
	return str(Engine.get_meta(SESSION_META))


# ============================================================================= the board (hub only)
func _spawn_board() -> void:
	_prop = PROP_SCRIPT.new() as Node3D
	_prop.name = "Board"
	add_child(_prop)
	var deco := get_tree().root.get_node_or_null("World/Decorations")
	var tokens: Array[Dictionary] = []
	for e: Dictionary in entries():
		tokens.append({"game": str(e["game"]), "flavour": str((e["config"] as Dictionary).get("flavour", ""))})
	_prop.call("setup", _planet, deco, tokens)
	if not bool(_prop.call("is_built")):
		# No legal ground on the whole world (the prop has said so). Arrivals still work from here.
		_prop.queue_free()
		_prop = null
		return
	_prop.connect("used", _on_board_used)


func _on_board_used(_player: Node3D) -> void:
	open_panel()


## Opens the list. Refused while anything else is modal, a trip is being set up, or the landing that
## brought the player here has not finished.
func open_panel() -> void:
	if _panel != null and bool(_panel.get("is_open")):
		return
	if EventBus.is_modal_open() or _launching or not _world_calm():
		return
	_ensure_ui()
	if _panel == null:
		return
	# With the dev "show every game" switch on the list already holds every game there is, so a line
	# saying more will unlock would be wrong there.
	_panel.call("open", entries(), TEXT_LOCKED if has_locked_games() and not dev_show_all() else "",
		_has_ship())


func _ensure_ui() -> void:
	if _ui_root != null and is_instance_valid(_ui_root):
		return
	var hud := get_tree().root.get_node_or_null("World/HUD")
	if hud == null:
		return
	_ui_root = Control.new()
	_ui_root.name = "ReplayBoardUI"
	_ui_root.theme = UIStyle.theme()
	MobileUI.apply_theme(_ui_root)
	_ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(_ui_root)
	_panel = PANEL_SCRIPT.new() as Control
	_panel.name = "Panel"
	_ui_root.add_child(_panel)
	_panel.connect("play_requested", _on_play_requested)


func _ensure_confirm() -> ConfirmPopup:
	_ensure_ui()
	if _ui_root == null:
		return null
	if _confirm == null or not is_instance_valid(_confirm):
		_confirm = ConfirmPopup.new()
		_confirm.name = "FlyBack"
		_ui_root.add_child(_confirm)
		_confirm.answered.connect(_on_fly_back_answered)
	return _confirm


func _on_platform_mode_changed(_mobile: bool) -> void:
	if _ui_root != null and is_instance_valid(_ui_root):
		MobileUI.apply_theme(_ui_root)


# ============================================================================= Play: the trip
func _on_play_requested(key: String) -> void:
	if _panel != null:
		_panel.call("close")
	play(key)


## Starts the trip for board entry `key`. Every refusal says why in a toast and leaves no flag.
func play(key: String) -> bool:
	var e := find_entry(key)
	if e.is_empty():
		_toast("That game isn't on the board any more.")
		return false
	if not _has_game(str(e["game"])):
		_toast("That game isn't in this build yet.")
		return false
	if _launching or EventBus.is_modal_open() or not _world_calm():
		_toast("Not right now. Try again in a moment.")
		return false
	var planet := str(e["planet"])
	if not CampaignData.planet_in_range(planet):
		_toast("Your %s can't reach %s yet." % [_rocket_word(), str(e["world"])])
		return false
	if planet == GameState.current_planet_id:
		# A game on this very world needs no flight.
		_pending = e
		call_deferred("_try_start_pending")
		return true
	var pad := get_tree().root.get_node_or_null("World/Rocket")
	var p := get_tree().get_first_node_in_group("player") as Player
	if pad == null or not pad.has_method("launch_to") or p == null:
		_toast("The %s isn't ready. Try again in a moment." % _rocket_word())
		return false
	GameState.flags[FLAG_PENDING] = {
		"key": key, "npc": str(e["npc"]), "step": int(e["step"]), "planet": planet,
		"session": _session_token(),
	}
	_launching = true
	pad.call("launch_to", planet, p)
	_launching = false
	# launch_to opens the "cutscene" modal synchronously when it takes off; no modal means it refused
	# (the pad already busy, a journey switching), and then nothing may be left behind.
	if not EventBus.modal_counts().has("cutscene"):
		GameState.flags.erase(FLAG_PENDING)
		_toast("The %s isn't ready. Try again in a moment." % _rocket_word())
		return false
	return true


## True when nothing is mid-flight or mid-landing on this world and the player is really in control.
func _world_calm() -> bool:
	if SceneRouter.is_busy() or RocketJourney.switching or GameState.flag("rocket_arriving"):
		return false
	var p := get_tree().get_first_node_in_group("player") as Player
	return p != null and p.is_inside_tree() and p.is_physics_processing() and p.input_enabled


# ============================================================================= arrival
## Reads and CLEARS the pending flag on every world load (see the header's "stale flag" rules).
func _read_pending_flag() -> void:
	if not GameState.flags.has(FLAG_PENDING):
		return
	var raw: Variant = GameState.flags.get(FLAG_PENDING)
	GameState.flags.erase(FLAG_PENDING)
	if not (raw is Dictionary):
		return
	var rec: Dictionary = raw
	var planet := str(rec.get("planet", ""))
	var arriving := GameState.flag("rocket_arriving") or EventBus.modal_counts().has("cutscene")
	if str(rec.get("session", "")) != _session_token() or planet != GameState.current_planet_id or not arriving:
		print("ReplayBoard: dropped a stale replay flag for %s (planet %s, arriving %s)" % [
			str(rec.get("key", "?")), GameState.current_planet_id, str(arriving)])
		return
	var e := find_entry(str(rec.get("key", "")))
	if e.is_empty() or str(e["planet"]) != planet:
		return
	_pending = e


func _on_modal_closed(_name: String) -> void:
	if not _pending.is_empty():
		call_deferred("_try_start_pending")


func _try_start_pending() -> void:
	if _pending.is_empty() or not is_inside_tree():
		return
	if EventBus.is_modal_open() or not _world_calm():
		return   # the next modal close checks again
	var e := _pending
	_pending = {}
	_start_replay(e)


func _start_replay(e: Dictionary) -> void:
	if not ResourceLoader.exists(MINIGAME_SYSTEM_PATH):
		return
	var ms: Node = load(MINIGAME_SYSTEM_PATH).call("get_or_create")
	if ms == null:
		return
	var npc := str(e["npc"])
	if bool(ms.call("is_running")) and str(ms.call("running_owner")).begins_with("project:"):
		var running_npc := str(ms.call("running_owner")).get_slice(":", 1)
		_toast("%s's game is already on here. Play that one!" % _npc_name(running_npc if running_npc != "" else npc))
		return
	var cfg: Dictionary = (e["config"] as Dictionary).duplicate(true)
	cfg["count"] = int(e["count"])
	cfg["done"] = 0
	cfg["owner"] = owner_for(str(e["key"]))
	cfg["npc"] = npc
	if not ms.is_connected("finished", _on_game_finished):
		ms.connect("finished", _on_game_finished)
	_owner = str(cfg["owner"])
	_running = e
	if not bool(ms.call("start", str(e["game"]), cfg)):
		_owner = ""
		_running = {}
		_toast("That game couldn't start here.")


# ============================================================================= finish
func _on_game_finished(_kind: String, success: bool, config: Dictionary) -> void:
	if _owner == "" or str(config.get("owner", "")) != _owner:
		return
	var e := _running
	_owner = ""
	_running = {}
	if not success:
		return   # cancelled (another owner took over): nothing to pay, nothing to ask
	var key := FLAG_PAID_PREFIX + str(e["key"])
	var reward := "Nice!"
	if not GameState.flags.has(key) or int(GameState.flags[key]) != GameState.day_count:
		GameState.flags[key] = GameState.day_count
		GameState.add_stardust(REPLAY_STARDUST)
		reward = "Nice! +%d stardust" % REPLAY_STARDUST
	_toast(reward, "star")
	if GameState.current_planet_id == HUB_ID:
		return
	_reward = reward
	get_tree().create_timer(FLY_BACK_DELAY).timeout.connect(_offer_fly_back)


func _offer_fly_back() -> void:
	if not is_inside_tree() or _asking:
		return
	if EventBus.is_modal_open():
		# Something else is up (a talk, the bag). Ask as soon as it closes.
		if not EventBus.ui_modal_closed.is_connected(_retry_fly_back):
			EventBus.ui_modal_closed.connect(_retry_fly_back, CONNECT_ONE_SHOT)
		return
	var popup := _ensure_confirm()
	if popup == null:
		return
	_asking = true
	popup.ask(fly_back_text(_reward), "Yes", "Stay")


## "Nice! +10 stardust." then "Fly back to The Commons?" on a line of its own (see "THE REWARD IS
## IN THE QUESTION"). Each line stays within LINE_MAX.
static func fly_back_text(reward: String) -> String:
	var ask := TEXT_FLY_BACK % Hud.planet_display_name(HUB_ID)
	if ask.length() > LINE_MAX:
		ask = TEXT_FLY_BACK_SHORT
	if reward == "":
		return ask
	var first := reward if reward.ends_with("!") or reward.ends_with(".") else reward + "."
	return "%s\n%s" % [first, ask]


func _retry_fly_back(_name: String) -> void:
	call_deferred("_offer_fly_back")


func _on_fly_back_answered(yes: bool) -> void:
	_asking = false
	if not yes:
		return
	var pad := get_tree().root.get_node_or_null("World/Rocket")
	var p := get_tree().get_first_node_in_group("player") as Player
	if pad == null or p == null or EventBus.is_modal_open() or not _world_calm():
		_toast("The %s isn't ready. Try again in a moment." % _rocket_word())
		return
	pad.call("launch_to", HUB_ID, p)


# ============================================================================= helpers
func _toast(text: String, icon: String = "") -> void:
	EventBus.toast_requested.emit(text, icon)


static func _npc_name(npc: String) -> String:
	return str(NpcData.get_data(npc).get("display_name", npc.capitalize()))


## FinaleState.has_ship() through a guarded load (see FINALE_STATE_PATH's doc comment) — false while
## the file or the method does not exist, same as RocketModel's own guard.
static func _has_ship() -> bool:
	if not ResourceLoader.exists(FINALE_STATE_PATH):
		return false
	var script := load(FINALE_STATE_PATH) as Script
	if script == null:
		return false
	for m: Dictionary in script.get_script_method_list():
		if m.get("name", "") == "has_ship":
			return bool(script.call("has_ship"))
	return false


## "rocket" or "ship" (docs/PHASE5_SPEC.md §6: "the pad compass and board string say 'ship'").
static func _rocket_word() -> String:
	return "ship" if _has_ship() else "rocket"


func _exit_tree() -> void:
	if EventBus.ui_modal_closed.is_connected(_retry_fly_back):
		EventBus.ui_modal_closed.disconnect(_retry_fly_back)


# ============================================================================= QA
## One line a probe or a critic can assert against. Prints only.
func debug_report(tag: String = "") -> void:
	var spot := "none"
	if _prop != null and _planet != null:
		spot = str(_prop.call("debug_spot"))
	var list := PackedStringArray()
	for e: Dictionary in entries():
		list.append("%s=%s@%s" % [e["key"], e["title"], e["planet"]])
	print("REPLAY %s planet=%s pending=%s owner=%s asking=%s flag=%s locked=%s dev_all=%s board=%s entries=[%s]" % [
		tag, GameState.current_planet_id, str(_pending.get("key", "")), _owner, str(_asking),
		str(GameState.flags.get(FLAG_PENDING, null)), str(has_locked_games()), str(dev_show_all()),
		spot, "; ".join(list)])


func debug_panel() -> Control:
	return _panel


func debug_confirm() -> ConfirmPopup:
	return _confirm
