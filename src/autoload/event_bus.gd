extends Node
## Global signal bus. All cross-system communication goes through here.
## Systems emit; systems listen. Never hold direct references across domains
## when a signal will do.

# --- World / travel ---
signal planet_loaded(planet_id: String)          # world.tscn finished building a planet
signal planet_leave_requested(planet_id: String) # player boarded rocket
signal travel_started(from_id: String, to_id: String)
signal travel_finished(to_id: String)

# --- Player ---
signal player_spawned(player: Node3D)
signal player_style_changed()                    # suit/helmet/etc changed (astronaut model re-reads GameState.player_style)

# --- Economy / inventory ---
signal stardust_changed(new_amount: int, delta: int)
signal item_added(item_id: String, count: int)
signal item_removed(item_id: String, count: int)
signal collectible_picked(kind: String, world_pos: Vector3)

# --- Decoration ---
signal decoration_placed(planet_id: String, instance_id: String, item_id: String)
signal decoration_removed(planet_id: String, instance_id: String)
signal placement_mode_changed(active: bool)

# --- Dialogue / NPC / favors ---
signal dialogue_started(speaker_id: String)
signal dialogue_finished(speaker_id: String)
signal favor_offered(favor_id: String, npc_id: String)
signal favor_accepted(favor_id: String)
signal favor_completed(favor_id: String, reward_item_id: String, reward_stardust: int)
signal favor_progress(favor_id: String, current: int, target: int)
signal friendship_changed(npc_id: String, level: int)

# --- Planet score / trash ---
signal trash_changed(count: int)          # a piece landed on the home planet, or was cleaned up

# --- UI ---
signal ui_modal_opened(name: String)   # inventory/shop/pause etc. Player should freeze while any modal is open.
signal ui_modal_closed(name: String)
signal toast_requested(text: String, icon: String) # small notification ("You got a Moon Lamp!")
signal interact_prompt_changed(text: String)       # "" hides the prompt

# --- Time ---
signal time_of_day_changed(hour_float: float)       # 0..24, emitted every ~0.05h
signal day_phase_changed(phase: String)              # "dawn" "day" "dusk" "night"

# --- Save ---
signal game_saved()
signal game_loaded()

var _modal_count: int = 0
var _modal_names: Dictionary = {}
## `--reset-any-node`: put the pre-fix node-added detection back (see `_on_node_added`).
var _reset_any_node := false

func _ready() -> void:
	_reset_any_node = OS.get_cmdline_user_args().has("--reset-any-node")
	ui_modal_opened.connect(_on_modal_opened)
	ui_modal_closed.connect(_on_modal_closed)
	# A scene change frees whatever UI was open without it ever emitting ui_modal_closed.
	# Without this reset the modal count stays above zero forever and every gameplay input
	# in the next scene is ignored - an unrecoverable soft-lock. Found by the rocket critic:
	# opening the bag during the launch cutscene left the space map permanently input-dead.
	get_tree().node_added.connect(_on_node_added)

func _on_modal_opened(n: String) -> void:
	_modal_count += 1
	_modal_names[n] = int(_modal_names.get(n, 0)) + 1

## SAFE AGAINST THE REPLAY IN `reset_modals()`, and that is a requirement, not a happy accident:
## the reset zeroes the counter and then re-emits `ui_modal_closed` once per name it cleared, so
## this handler is re-entered with the counter already at 0 and the name already gone. Both lines
## below therefore have to be no-ops in that state — `max(0, ...)` keeps the counter from going
## negative and `left <= 0` erases a key that is not there, which `Dictionary.erase` ignores. Do
## not "tidy" either of those into an unclamped decrement.
func _on_modal_closed(n: String) -> void:
	_modal_count = max(0, _modal_count - 1)
	var left: int = int(_modal_names.get(n, 0)) - 1
	if left <= 0:
		_modal_names.erase(n)
	else:
		_modal_names[n] = left

## A NEW SCENE ROOT, and nothing else. This used to fire for ANY node parented straight to
## `/root`, which is not the same thing at all, and it is how a scene-change reset came to fire in
## the middle of a rocket CRUISE:
##
##   `Planet.prebuild()` (src/planet/planet.gd:542, called during the cruise so the arrival does not
##   hitch) parents a throwaway Planet to `loop.root` for a few milliseconds to bake geometry, and
##   the launch cutscene's `ui_modal_opened("cutscene")` gate is open at the time. MEASURED in a
##   scripted home -> zorp landing, `--ui=mobile`, Compatibility: that scratch planet is the ONLY
##   thing that cleared a live modal in the whole 42 s journey — one clear of `["cutscene"]` at
##   t=3.4 s, 1.2 s after the launch. `JourneyProbe.persist()` (src/rocket/journey_probe.gd:55)
##   reparents itself to `/root` for its own reasons and tripped it too.
##
## HOW A REAL SCENE INSTALL IS TOLD APART, and it is NOT the obvious comparison. Every one of these
## four `node_added` calls has `get_parent() == root`; the printed `current_scene` is measured, not
## assumed (temporary print in this function, same landing run):
##
##   node                  current_scene at the callback   what it is
##   World                 World (itself)                  boot, `SceneTree::add_current_scene`
##   @StaticBody3D@283     World (the OLD scene)           `Planet.prebuild()`'s scratch planet
##   SpaceTravel           <null>                          `change_scene_to_file` swap
##   World                 <null>                          `change_scene_to_file` swap
##
## So `node == current_scene` alone would have been WRONG: `SceneTree::_change_scene` frees the old
## scene, leaves `current_scene` null, adds the new root, and only then assigns it — every swap this
## game makes goes through `SceneRouter._transition_to` -> `change_scene_to_file`, so every swap
## would have been missed and the soft-lock this reset exists for (bag open during the launch
## cutscene -> input-dead space map, found by the rocket critic) would be back. The null IS the
## signal: a scene change is in flight. The boot case is the other half, where the assignment
## happens first. A node added while some other scene is current — a prebuild, a probe, an
## autoload — is neither, which is exactly the case being excluded.
##
## `--reset-any-node` (after the `--` separator) restores the old wide behaviour, so the fault this
## round measured stays reproducible from one timeline after the cause is gone — same purpose as
## `TouchControls`' `--no-adopt`. See `reset_modals` for what the reset itself now does.
func _on_node_added(node: Node) -> void:
	if node.get_parent() != get_tree().root:
		return
	var cur := get_tree().current_scene
	if _reset_any_node or node == cur or cur == null:
		reset_modals()

## STUCK-PLAYER WATCHDOG. `RocketPad._freeze_player` disables the player's physics AND process
## for the landing cutscene, and `_thaw_player` puts them back. If anything interrupts that
## sequence the astronaut can look around but never walk again, which strands the player on
## the planet — reported twice from a real iPhone as "coming out of the spaceship on a new
## planet doesn't let me move".
##
## The pad has its own watchdog, but it runs in the PAD's `_process`, so it cannot help if the
## pad is gone or not processing. The player cannot watch itself either: the freeze is exactly
## what stops its `_physics_process` running. So the last line of defence lives here, in an
## autoload that always processes.
##
## Triggers ONLY on physics being disabled, never on `input_enabled` alone — dialogue clears
## `input_enabled` for as long as the player reads, and that is legitimate.
const STUCK_GRACE := 12.0
var _stuck_timer := 0.0


func _process(delta: float) -> void:
	_watch_tick(delta)
	var p := get_tree().get_first_node_in_group("player") if get_tree() != null else null
	if p == null or not is_instance_valid(p) or not p.is_inside_tree():
		_stuck_timer = 0.0
		return
	if p.is_physics_processing() or get_tree().paused:
		_stuck_timer = 0.0
		return
	_stuck_timer += delta
	if _stuck_timer < STUCK_GRACE:
		return
	_stuck_timer = 0.0
	push_warning("EventBus: player frozen for %.0f s with no cutscene running — restoring control." % STUCK_GRACE)
	p.set_physics_process(true)
	p.set_process(true)
	p.set("input_enabled", true)
	p.visible = true


## SILENT-CLEAR BOOKKEEPING, for the touch-diag readout (src/ui/mobile/touch_diag.gd). TEMPORARY —
## remove with the rest of that instrumentation. The counters stay useful after the fix below: they
## now count resets that had something to clear AT ALL, which is the "a real close was lost" signal
## `_on_node_added` is judged by.
var _resets := 0
var _last_reset_ms := -1
var _last_reset_names := ""
## True only inside the close replay in `reset_modals`, so a listener that adds a node to `/root`
## from its own close handler cannot recurse back in. See `reset_modals`.
var _resetting := false


## Clears all modal state, then TELLS THE LISTENERS, which is the whole of this round's fix.
##
## THE BUG THIS CLOSES, reported five times and missed by four fixes: *"when I landed on the first
## planet, I couldnt move anymore, the move joystick just moved the camera"* / *"I can move again by
## hitting pause and resume."* This function used to zero the gate SILENTLY, and the two listeners
## that decide whether the player can move are EDGE-driven from `ui_modal_closed` and from nothing
## else:
##   * `Player._on_modal_changed` (src/player/player.gd:216) is the only writer of `input_enabled`,
##   * `TouchControls._on_modal_changed` (src/ui/mobile/touch_controls.gd:280) is the only
##     modal-side writer of `visible`.
## So a reset that actually cleared something left BOTH stale — astronaut frozen, joystick hidden —
## while `is_modal_open()` reported false, and the only thing that could put them back was another
## open/close PAIR. Opening and closing the pause menu is exactly such a pair. That is the player's
## own workaround, and it is why it worked.
##
## MEASURED, scripted home -> zorp landing, `--ui=mobile`, Compatibility, one WATCH line per frame
## (`debug_watch` below). Before: from t=3.4 s to t=13.3 s — 10 s, ~600 frames — the readout was
## `modal=0 names=[] vis=N`, i.e. the gate clear with the joystick off screen and nothing open to
## explain it. With the replay and the old wide `_on_node_added` (`--reset-any-node`), the same
## frames read `vis=Y`. Read `en` in that window carefully and do not credit the fix with it: the
## astronaut is `en=N phys=N` there in BOTH arms because `RocketPad._freeze_player` is holding them
## for the launch, which is legitimate and is not modal-driven.
##
## The `en` half is proved by injection instead, where the modal gate is the only writer: two
## `ui_modal_opened("shop")` then `reset_modals()` left `en=N modal=0 vis=N` for the whole 16 s run
## and a 1.0 s forward push travelled dist=0.00; with the replay the next frame reads `en=Y vis=Y`
## and the same push travels dist=4.04, along_facing=+3.80.
##
## HOW IT NOTIFIES, and what was rejected. It RE-EMITS `ui_modal_closed` once per outstanding open,
## because every listener's close handler already IS a "recompute from `is_modal_open()`" function —
## that is the path the pause menu's close takes, and it is the one path known to clear this fault.
## Seven systems listen (this file included); replaying the closes is the only option that repairs
## all of them:
##   * `hud.gd` keeps its OWN name->count table and drives toast placement off it
##     (`_wanted_toast_spot`), so a silent reset parked toasts wrongly for the rest of the session.
##     A replayed close repairs that table; a private "state changed" signal would not have, unless
##     hud.gd were edited too, and it belongs to another builder.
##   * `audio_manager.gd` holds `_dialogue_modal` and ducks the music off it — same shape.
##   * `player.gd`, `touch_controls.gd`, `camera_rig.gd`, `hint_channel.gd` all recompute.
## A separate signal was rejected for that reason (it fixes only the listeners that opt in, and two
## of the stale ones are not ours to edit); calling the listeners' methods directly from here was
## rejected because an autoload signal bus reaching into `Player` and `TouchControls` by node path
## is precisely what the bus exists to prevent. A timer, a deferred call or a per-frame re-apply of
## `input_enabled` were rejected outright: they hide the divergence instead of removing it, and a
## per-frame writer of `input_enabled` would fight the dialogue runner, which clears it legitimately
## for as long as the player reads.
##
## WHY IT IS SAFE TO RE-ENTER `_on_modal_closed`. The state is zeroed FIRST and the replay happens
## after, so every listener — including our own handler, which decrements the same counter — sees
## the final state (`modal=0`) rather than a half-unwound one. `_on_modal_closed` clamps at zero and
## erases a missing key, so it is a no-op on all of them (there is a comment there saying so).
##
## IDEMPOTENT, both ways round: with nothing open this returns before it emits anything, so two
## resets in a row emit exactly the same closes as one, and a reset on a quiet frame is free. Once
## per outstanding OPEN, not once per name, so a name opened twice ("cutscene" during a launch that
## also opened the bag) leaves no residue in the listeners' own count tables.
##
## THE REPLAY IS HONEST, not a lie to the listeners: `reset_modals` has just declared those modals
## closed. Anything that polls `is_modal_open()` (space_travel.gd, placement_controller.gd,
## journal_hotkey.gd, the HUD's own prompt gate) already behaved that way from the frame the counter
## was zeroed. All this does is stop the edge-driven listeners from disagreeing with the pollers.
func reset_modals() -> void:
	# Nothing open: a no-op, and it must stay one — `_on_node_added` calls this on every scene load.
	if _modal_count == 0 and _modal_names.is_empty():
		return
	# A listener's close handler that parents a node to /root would come back through
	# `_on_node_added`. The state is already zero by then, so skipping is not losing anything.
	if _resetting:
		return
	push_warning("EventBus: clearing %d stale modal(s) on scene change: %s" % [_modal_count, str(_modal_names.keys())])
	_resets += 1
	_last_reset_ms = Time.get_ticks_msec()
	_last_reset_names = ",".join(PackedStringArray(_modal_names.keys()))
	var stale: Dictionary = _modal_names.duplicate()
	_modal_count = 0
	_modal_names.clear()
	_resetting = true
	for n: String in stale:
		for _i in maxi(1, int(stale[n])):
			ui_modal_closed.emit(n)
	# THE DRIFTED CASE: counter above zero with an empty name table. It takes a close emitted for a
	# name that was never opened to get there (`modal_total()` disagreeing with `modal_counts()` is
	# what `TouchDiag.verdict` calls out first), and it would leave the loop above with nothing to
	# emit and every listener still stale — the exact fault, by another route. One nameless close
	# recomputes them; the two listeners that key on the name (`hud.gd`'s count table,
	# `audio_manager.gd`'s dialogue duck) treat an unknown name as nothing to do.
	if stale.is_empty():
		ui_modal_closed.emit("")
	_resetting = false


## PER-FRAME WATCH, and it lives on the autoload for one reason: it is the only node that survives
## a scene swap, and the swap is exactly the seam this bug lives in. A probe under `/root/World`
## dies at the pad -> space -> planet handover, and `TouchDiag` (src/ui/mobile/touch_diag.gd) draws
## only inside the scene that owns it, so neither can show the cruise frames where `reset_modals()`
## actually fires. TEMPORARY — remove with the rest of the touch-diag instrumentation.
##
## One line per frame, every field a different candidate cause, same vocabulary as the on-screen
## overlay so a scripted run and the player's screenshot read the same:
##   modal / names   the gate itself
##   vis / procin    TouchControls.visible and is_processing_input() (found by node name, because
##                   the node is rebuilt by every planet load and any cached reference goes stale)
##   en / phys / pproc / paused   the four gameplay gates, `en` being `Player.input_enabled`
##   rst             the silent-reset counter, so a fault line and its cause are on the same row
var _watch_tag := ""
var _watch_left := 0.0
var _watch_t := 0.0


## Prints the state line every frame for `seconds`. Called from a Director timeline:
##   {"call": {"node": "/root/EventBus", "method": "debug_watch", "args": ["landing", 8.0]}}
func debug_watch(tag: String, seconds: float) -> void:
	_watch_tag = tag
	_watch_left = seconds
	_watch_t = 0.0


func _watch_tick(delta: float) -> void:
	if _watch_left <= 0.0:
		return
	_watch_left -= delta
	_watch_t += delta
	var tree := get_tree()
	var p: Node = tree.get_first_node_in_group("player") if tree != null else null
	var tc: Node = tree.root.find_child("TouchControls", true, false) if tree != null else null
	var speed := 0.0
	if p != null and p.has_method("get_tangent_velocity"):
		speed = (p.call("get_tangent_velocity") as Vector3).length()
	var mv := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	print("WATCH %s t=%.2f modal=%d names=%s vis=%s procin=%s en=%s phys=%s pproc=%s paused=%s rst=%d(%s) vec=%.2f spd=%.2f" % [
		_watch_tag, _watch_t, _modal_count, str(_modal_names.keys()),
		"-" if tc == null else ("Y" if bool(tc.get("visible")) else "N"),
		"-" if tc == null else ("Y" if bool(tc.call("is_processing_input")) else "N"),
		"-" if p == null else ("Y" if bool(p.get("input_enabled")) else "N"),
		"-" if p == null else ("Y" if p.is_physics_processing() else "N"),
		"-" if p == null else ("Y" if p.is_processing() else "N"),
		"Y" if tree != null and tree.paused else "N",
		_resets, _last_reset_names, mv.length(), speed])


## How many times the modal gate has been zeroed while something was still open, what was open the
## last time, and how long ago in seconds (-1 = never). TEMPORARY, see the note above.
func modal_reset_info() -> Dictionary:
	return {
		"count": _resets,
		"names": _last_reset_names,
		"age": -1.0 if _last_reset_ms < 0 else float(Time.get_ticks_msec() - _last_reset_ms) * 0.001,
	}

## True while any menu / dialogue / shop is open. Gameplay input should be ignored.
func is_modal_open() -> bool:
	return _modal_count > 0

## Names of the currently-open modals, for debugging and for systems that care which one.
func open_modals() -> Array:
	return _modal_names.keys()

## Open modal NAME -> how many unclosed opens it has. Added for the touch-diag readout
## (src/ui/mobile/touch_diag.gd): the gate below is `_modal_count`, a counter, so an unbalanced
## open/close pins it above zero forever and the touch controls stay hidden for the rest of the
## session. `open_modals()` cannot show that — a name with a count of 3 looks like a name with a
## count of 1 — and the count is exactly what the player's screenshot has to be able to show.
func modal_counts() -> Dictionary:
	return _modal_names.duplicate()

## The gate itself, as a number. If this ever disagrees with the sum of `modal_counts()` the two
## halves of the bookkeeping have drifted (a close emitted for a name that was never opened will do
## it), and the names will look innocent while the counter keeps the controls off screen.
func modal_total() -> int:
	return _modal_count
