class_name MinigameSystem
extends Node
## MINI-GAMES: a short thing you PLAY on a neighbour's own world, instead of flying a fetch errand
## back and forth (docs/CORE_LOOP.md "Mini-games instead of fetch trips", decided 2026-09-12 after
## the user played on her phone: fetch trips "will get old fast and heats up the phone").
##
## One instance per world, created lazily as a child of /root/World - the same pattern as
## FavorSystem and ProjectSystem:
##
##     var games := MinigameSystem.get_or_create()        # null outside a world
##     games.start("catch", {"count": 5, "flavour": "bolt", "owner": "project:bolt:1"})
##     if games.is_running(): ...
##     games.finished.connect(func(kind, ok, cfg): ...)
##
## ============================================================================== THE PUBLIC CONTRACT
## start(kind, config) -> bool   starts `kind` on the CURRENT world. False (with a push_warning) when
##                               the kind is unknown, there is no planet or player yet, or the game's
##                               own `setup` refused the config. Starting while a game with the SAME
##                               "owner" is already running is a no-op that returns true, so a host
##                               may call it again on every refresh without respawning anything.
##                               Starting a DIFFERENT owner cancels the running one first.
## stop(reason)                  cancels the running game. No success, no signal beyond `finished`
##                               with success=false. Progress already reported is already saved.
## stop_owner(owner, reason)     stop(), but only if the running game carries that owner.
## sync_owners(prefix, owners)   cancels the running game when its owner starts with `prefix` and is
##                               NOT in `owners`. For a host that rebuilds its live objectives (a
##                               planet load, a state reload) - see ProjectSystem._sync_minigames.
## is_running() / running_kind() / running_owner() / running_config() / progress()
##
## Two config keys belong to THIS system rather than to a game, and every game gets them for free:
##   "owner"   the string above. Anything unique; a host should prefix it (see sync_owners).
##   "accent"  colour of the pill's pointer, as a Color or an html string. Default: the HUD yellow.
##
## signal started(kind, config)
## signal progress_changed(kind, done, total)    every time one more is collected
## signal finished(kind, success, config)        success=true only when the game was completed
##
## ============================================================================== WHO OWNS WHAT STATE
## THIS SYSTEM IS NOT SAVED AND HAS NO SAVE FIELDS OF ITS OWN, on purpose (the brief: "do NOT add new
## GameState fields"). It dies with the world and rebuilds from the config it is handed.
##
## The HOST owns the persistence. `progress_changed` fires the moment something is collected, and the
## host writes it wherever its own state lives; `start` then takes "done" back in the config to
## resume a half-finished game. For a project step that is GameState.projects[npc]["found"], the same
## array a "find" step's markers use, so a half-played mini-game survives a save, a reload and a trip
## to another planet with no new save field anywhere (ProjectSystem's SAVED STATE header).
##
## THE STEP IS MET BY THE PERSISTED COUNT, NOT BY THE `finished` SIGNAL. `finished` is the moment for
## a toast, a sound and cleanup; it can be missed (the player walks to the rocket during the catch
## animation, the app is closed). The last `progress_changed` has already been written by then, so on
## the next load the host sees done == total and the step is met anyway. Never make completion depend
## on `finished` alone.
##
## ============================================================================== ADDING A SECOND GAME
## Add one line to GAMES below and write the script. A game is a plain Node3D (loaded by path, so it
## needs no class_name) with:
##
##   func setup(system: MinigameSystem, config: Dictionary) -> String
##       Called once, AFTER the node is added to the tree (so `get_tree()` and the planet are there).
##       Build the world objects. Return "" when it started, or a short plain-English reason it could
##       not ("no planet here") - the reason is pushed as a warning and shown to nobody.
##   func title() -> String                (optional) the line on the progress pill. Default: the
##                                         config's "title", else the kind.
##   func hint_direction() -> Vector3      (optional) a WORLD position to point the pill's chevron at,
##                                         or Vector3.INF for none. Sampled at POINTER_HZ, not per
##                                         frame.
##   func outro() -> void                  (optional) called just before the node is freed.
##
## and it calls back into the system:
##
##   system.report_progress(done, total)   after each collection. Emits progress_changed and repaints
##                                         the pill. Call it BEFORE any celebration animation.
##   system.report_finished(true)          when the game is complete. The system emits `finished`,
##                                         frees the game and takes the pill down.
##
## Nothing else is required, and a game must never: open a modal (EventBus.ui_modal_opened), write
## `player.input_enabled`, pause the tree, or add nodes outside itself. Those are the three ways this
## project has frozen the player before (docs/OPEN_ISSUES.md 39 and 42); a mini-game is played with
## the ordinary controls, so it needs none of them.
##
## ============================================================================== PHONE AND HEAT
## docs/OPEN_ISSUES.md 44: the phone runs hot and a whole round went into cheaper frames. A game gets
## a small budget - keep node and draw counts in single digits per object, prefer one shared material
## per look, and do not use GPUParticles3D for a per-item idle effect. `catch_game.gd` is the
## reference: 3 draw calls per runaway, one terrain sample per frame for the whole set, no particles.

const NODE_NAME := "MinigameSystem"

## kind -> script. One line per game; nothing else needs editing.
const GAMES := {
	"catch": "res://src/minigames/catch_game.gd",
	"rings": "res://src/minigames/ring_game.gd",
}

## The progress pill sits UNDER the HUD (hud.tscn is layer 10), so toasts, the dialogue box and every
## modal still draw over it.
const UI_LAYER := 9
## Where the pill hangs below the safe-area top. Desktop 24 is the HUD's own EDGE. MOBILE IS 68
## BECAUSE THE INTERACT PROMPT LIVES AT THE TOP CENTRE THERE (hud.gd MOBILE_PROMPT_TOP): the first
## play-through capture on Bolt has the rocket's "Fly" prompt printed straight across "Catch the
## bolts 1 of 5". 68 clears the prompt's own box with a gap, and still sits above the mobile HUD
## button row on the left (centre y 192) and the toast stack on the right (top 56).
const UI_EDGE_DESKTOP := 24.0
const UI_EDGE_MOBILE := 68.0
## The chevron that points at the nearest thing left. Recomputed at this rate, not per frame - it is
## one `unproject_position` and it only has to be roughly right.
const POINTER_HZ := 10.0
const POINTER_SPAN := 9.0

signal started(kind: String, config: Dictionary)
signal progress_changed(kind: String, done: int, total: int)
signal finished(kind: String, success: bool, config: Dictionary)

var _game: Node3D
var _kind: String = ""
var _config: Dictionary = {}
var _done: int = 0
var _total: int = 0
## Guards the one re-entrancy that matters: a game calling report_finished from inside its own
## `setup`, or twice from a tween that fires again while the node is being freed.
var _ending := false

var _ui: CanvasLayer
var _pill: PanelContainer
var _title_label: Label
var _count_label: Label
var _pointer: Control
var _pointer_angle: float = 0.0
var _pointer_on := false
var _pointer_timer := 0.0
var _accent := Color("#f0a64a")


## Finds the world's MinigameSystem WITHOUT creating one. For a caller that only wants to tidy up
## (ProjectSystem's refresh) and must not add a node to every world that has no mini-game in it.
static func find() -> MinigameSystem:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var host: Node = tree.root.get_node_or_null("World")
	if host == null:
		return null
	return host.get_node_or_null(NODE_NAME) as MinigameSystem


## Finds the world's MinigameSystem, creating it under /root/World the first time. Null outside a
## world (a showcase scene has no /root/World), exactly like ProjectSystem.get_or_create().
static func get_or_create() -> MinigameSystem:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var host: Node = tree.root.get_node_or_null("World")
	if host == null:
		return null
	var existing := host.get_node_or_null(NODE_NAME)
	if existing is MinigameSystem:
		return existing as MinigameSystem
	var ms := MinigameSystem.new()
	ms.name = NODE_NAME
	host.add_child(ms)
	return ms


func _ready() -> void:
	set_process(false)
	# A modal (the bag, the pause menu, a conversation) covers the frame; the pill goes with the rest
	# of the chrome rather than sitting on top of a panel.
	EventBus.ui_modal_opened.connect(_on_modal_changed.unbind(1))
	EventBus.ui_modal_closed.connect(_on_modal_changed.unbind(1))


## Everything this system owns is a child of this node, so leaving the world frees all of it. The one
## thing that could outlive it is a game's own audio loop, which is why `outro()` exists.
func _exit_tree() -> void:
	if _game != null and is_instance_valid(_game) and _game.has_method("outro"):
		_game.call("outro")


# ============================================================================= queries
static func has_game(kind: String) -> bool:
	var path := str(GAMES.get(kind, ""))
	return path != "" and ResourceLoader.exists(path)


## Every kind this build can actually start, in GAMES order. For a menu that lists them.
static func available_kinds() -> PackedStringArray:
	var out := PackedStringArray()
	for k: String in GAMES:
		if has_game(k):
			out.append(k)
	return out


func is_running() -> bool:
	return _game != null and is_instance_valid(_game)


func running_kind() -> String:
	return _kind if is_running() else ""


func running_owner() -> String:
	return str(_config.get("owner", "")) if is_running() else ""


func running_config() -> Dictionary:
	return _config.duplicate(true) if is_running() else {}


## (done, total) of the running game, or (0, 0).
func progress() -> Vector2i:
	return Vector2i(_done, _total) if is_running() else Vector2i.ZERO


## WORLD position of the thing the player should head for next, or Vector3.INF when the game has no
## opinion (or none is running). The progress pill's chevron is drawn from it; a HUD or a test rig
## can point at the same thing without knowing which game is running.
func hint_position() -> Vector3:
	if is_running() and _game.has_method("hint_direction"):
		return _game.call("hint_direction")
	return Vector3.INF


# ============================================================================= start / stop
## Starts `kind` with `config`. See the header for the contract; the per-game keys are documented at
## the top of that game's own script.
func start(kind: String, config: Dictionary) -> bool:
	if not has_game(kind):
		push_warning("MinigameSystem: no game '%s' in this build" % kind)
		return false
	var owner_id := str(config.get("owner", ""))
	if is_running():
		if owner_id != "" and owner_id == running_owner():
			return true          # already playing this one; never respawn it under the player
		stop("replaced")
	var script: Variant = load(str(GAMES[kind]))
	if not (script is GDScript):
		push_warning("MinigameSystem: '%s' did not load as a script" % kind)
		return false
	var node: Variant = (script as GDScript).new()
	if not (node is Node3D) or not (node as Node).has_method("setup"):
		push_warning("MinigameSystem: '%s' is not a Node3D with setup()" % kind)
		if node is Node:
			(node as Node).free()
		return false
	_kind = kind
	_config = config.duplicate(true)
	_done = maxi(0, int(_config.get("done", 0)))
	_total = 0
	_ending = false
	_game = node as Node3D
	_game.name = "Game_" + kind
	add_child(_game)
	var why := str(_game.call("setup", self, _config))
	if why != "":
		push_warning("MinigameSystem: '%s' refused to start: %s" % [kind, why])
		_game.queue_free()
		_game = null
		_kind = ""
		_config = {}
		return false
	_accent = _color_of(_config.get("accent", ""), _accent)
	_show_ui()
	set_process(true)
	started.emit(_kind, _config.duplicate(true))
	return true


## Cancels the running game. Nothing is lost: whatever was collected was already persisted by the
## host through `progress_changed`, and a cancelled game restarts from there.
func stop(reason: String = "") -> void:
	if not is_running():
		return
	_end(false, reason)


func stop_owner(owner_id: String, reason: String = "") -> void:
	if is_running() and running_owner() == owner_id:
		stop(reason)


## Cancels the running game when its owner begins with `prefix` and is not one of `owners`. A host
## rebuilding its live objectives calls this with its own prefix, so it can never cancel somebody
## else's game (the dev menu's "dev:" games are untouched by the project system's "project:" sync).
func sync_owners(prefix: String, owners: PackedStringArray) -> void:
	if not is_running():
		return
	var owner_id := running_owner()
	if prefix != "" and not owner_id.begins_with(prefix):
		return
	if owners.has(owner_id):
		return
	stop("not live any more")


# ============================================================================= called by the game
## The game reports one more collected. Emitted straight through and drawn on the pill; the host is
## expected to SAVE `done` here (see "WHO OWNS WHAT STATE").
func report_progress(done: int, total: int) -> void:
	if not is_running():
		return
	_done = maxi(0, done)
	_total = maxi(0, total)
	_update_ui()
	if _pill != null:
		UIStyle.bump(_pill, 1.12, 0.32)
	progress_changed.emit(_kind, _done, _total)


## The game reports it is over. `success` false is a cancel, not a failure - nothing in a mini-game
## can be failed (docs/CORE_LOOP.md: no timers that punish, no game-over).
func report_finished(success: bool) -> void:
	if not is_running():
		return
	_end(success, "")


func _end(success: bool, _reason: String) -> void:
	if _ending:
		return
	_ending = true
	var kind := _kind
	var cfg := _config.duplicate(true)
	var game := _game
	_game = null
	_kind = ""
	_config = {}
	set_process(false)
	_hide_ui()
	if game != null and is_instance_valid(game):
		if game.has_method("outro"):
			game.call("outro")
		game.queue_free()
	_ending = false
	finished.emit(kind, success, cfg)


# ============================================================================= progress pill
func _show_ui() -> void:
	if _ui == null:
		_build_ui()
	_ui.visible = not EventBus.is_modal_open()
	_update_ui()
	UIStyle.pop_in(_pill, 0.22, 0.86)


func _hide_ui() -> void:
	if _ui == null:
		return
	# Hidden before it is freed: `queue_free` lands at idle, and a `finished` handler that starts the
	# next game in the same frame would otherwise draw its new pill over this dying one.
	_ui.visible = false
	_ui.queue_free()
	_ui = null
	_pill = null
	_title_label = null
	_count_label = null
	_pointer = null


func _build_ui() -> void:
	_ui = CanvasLayer.new()
	_ui.name = "MinigameHud"
	_ui.layer = UI_LAYER
	add_child(_ui)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(root)

	_pill = PanelContainer.new()
	_pill.name = "Progress"
	_pill.theme_type_variation = "HudPill"
	_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pill.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_pill.grow_horizontal = Control.GROW_DIRECTION_BOTH
	var sa := MobileUI.safe_area()
	_pill.offset_top = sa.y + MobileUI.pick(UI_EDGE_DESKTOP, UI_EDGE_MOBILE)
	root.add_child(_pill)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pill.add_child(row)

	# The chevron points at whatever the game says is nearest. On these little worlds things go over
	# the horizon in a few seconds, which is the point - but with no cue at all "where did it go?"
	# is a search rather than a flight.
	_pointer = Control.new()
	_pointer.custom_minimum_size = Vector2(POINTER_SPAN * 2.6, POINTER_SPAN * 2.6)
	_pointer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pointer.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_pointer.draw.connect(_draw_pointer)
	row.add_child(_pointer)

	_title_label = UIStyle.make_label("", "Small")
	_title_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_title_label)
	_count_label = UIStyle.make_label("", "Header")
	_count_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_count_label)
	# The pill is built before its first layout pass and it grows with the text it holds, so the
	# pivot has to follow the size rather than be set once - otherwise the bump on each catch scales
	# it off centre. `resized` is the only place that always knows the real size.
	_pill.resized.connect(func() -> void:
		if _pill != null:
			UIStyle.center_pivot(_pill))
	UIStyle.center_pivot(_pill)


func _update_ui() -> void:
	if _count_label == null:
		return
	_count_label.text = "%d of %d" % [_done, maxi(_total, 1)]
	_title_label.text = _title()
	if _pointer != null:
		_pointer.queue_redraw()


func _title() -> String:
	if is_running() and _game.has_method("title"):
		var t := str(_game.call("title"))
		if t != "":
			return t
	var t2 := str(_config.get("title", ""))
	return t2 if t2 != "" else _kind.capitalize()


func _on_modal_changed() -> void:
	if _ui != null:
		_ui.visible = not EventBus.is_modal_open()


## A FILLED triangle, not MobileUI.draw_chevron: at this size (9 px) the open chevron read as a
## bracket rather than an arrow in the first capture. Same language as the touch buttons' chevrons,
## solid so the direction is unmistakable at a glance on a phone.
func _draw_pointer() -> void:
	if _pointer == null or not _pointer_on:
		return
	var c := _pointer.size * 0.5
	var pts := PackedVector2Array([
		Vector2(0.0, -POINTER_SPAN), Vector2(POINTER_SPAN * 0.82, POINTER_SPAN * 0.72),
		Vector2(0.0, POINTER_SPAN * 0.30), Vector2(-POINTER_SPAN * 0.82, POINTER_SPAN * 0.72)])
	for i in pts.size():
		pts[i] = c + pts[i].rotated(_pointer_angle)
	_pointer.draw_colored_polygon(pts, _accent)


## The only per-frame work this system does, and it is one `unproject_position` ten times a second.
func _process(delta: float) -> void:
	if not is_running():
		set_process(false)
		return
	_pointer_timer -= delta
	if _pointer_timer > 0.0:
		return
	_pointer_timer = 1.0 / POINTER_HZ
	var target := hint_position()
	var was_on := _pointer_on
	var was_angle := _pointer_angle
	_pointer_on = false
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	if cam != null and target.is_finite():
		var behind := cam.is_position_behind(target)
		var p := cam.unproject_position(target)
		var v := p - get_viewport().get_visible_rect().size * 0.5
		if behind:
			v = -v
		if v.length_squared() > 1.0:
			# draw_chevron points UP at angle 0, so the screen-space bearing is measured from -Y.
			_pointer_angle = atan2(v.x, -v.y)
			_pointer_on = true
	if _pointer != null and (_pointer_on != was_on or absf(_pointer_angle - was_angle) > 0.02):
		_pointer.queue_redraw()


# ============================================================================= helpers
static func _color_of(v: Variant, fallback: Color) -> Color:
	if v is Color:
		return v as Color
	var s := str(v)
	return Color(s) if s != "" and Color.html_is_valid(s) else fallback


# ============================================================================= QA
## One line a Director timeline or a critic can assert against. Prints only.
##   {"t": 8, "call": {"node": "/root/World/MinigameSystem", "method": "debug_report", "args": ["mid"]}}
func debug_report(tag: String = "") -> void:
	print("MINIGAME %s running=%s kind=%s owner=%s done=%d total=%d ui=%s pointer=%s children=%d nodes=%d orphans=%d modal=%s" % [
		tag, str(is_running()), _kind, running_owner(), _done, _total,
		str(_ui != null and _ui.visible), str(_pointer_on), get_child_count(),
		int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)),
		str(EventBus.is_modal_open())])
	if is_running() and _game.has_method("debug_report"):
		_game.call("debug_report", tag)
