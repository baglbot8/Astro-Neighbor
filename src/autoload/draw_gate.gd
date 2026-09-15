extends Node
## Web/heat item 4: skips draws to save GPU work, without ever touching `Engine.max_fps`.
##
## NO `class_name` HERE ON PURPOSE (docs/OPEN_ISSUES.md 45): naming a class inside an autoload
## forces the whole script to resolve at parse time for every scene in the project, and it once
## leaked hundreds of ObjectDB instances into an unrelated showcase scene. Call this singleton by
## its autoload name, `DrawGate`, or by path (`load("res://src/autoload/draw_gate.gd")`) — never
## by a `class_name`.
##
## WHY NOT `Engine.max_fps`: heat-web-1 measured a runtime cap of 30 on the single-threaded web
## export busy-waiting inside the engine's own frame limiter — WebContent CPU rose from ~25% to
## 69-78% instead of falling, and a positive OS.delay_usec(8000) control proved the mechanism (it
## burns a core rather than sleeping). heat-web-4 also found that CHANGING max_fps at runtime is
## itself risky: a fixed shipped value does not spin, but switching it produced a bimodal spin in
## one run. So `run/max_fps.web` is set to 0 statically in project.godot and this script never
## writes `Engine.max_fps`, at any point, for any reason.
##
## THE SAFE MECHANISM INSTEAD (heat-web-2, confirmed): drop frames by turning
## `RenderingServer.render_loop_enabled` off for a span, then back on. Script and physics keep
## running every tick throughout (measured: 60 Hz process/physics while only 30 fps drew); the
## browser just keeps showing the last composited frame, so WebKit's GPU process does no new GL
## work. Gated on ELAPSED TIME, not frame parity (`frame_count % 2`) — a parity gate ties the drop
## pattern to the display's own refresh rate, which is meaningless on a 120 Hz panel and was flagged
## by the round-1 safety pass as the reason a parity version would draw 60 fps, not 30, on one.
##
## THE "SUMMED DELTA" FIX FOR TIME SHADERS AND GPU PARTICLES: withholding a draw does not withhold
## the clock — but if the engine's own automatic draw call is what finally fires after a gap, it
## only carries THAT ONE FRAME's delta (~16 ms), not the real elapsed time since the last picture,
## so a `TIME`-driven shader or a `GPUParticles3D` system would advance by one frame's worth of
## simulation while several frames' worth of wall-clock time passed underneath it — i.e. it runs
## slow, by roughly the skipped fraction. So the actual draw during a throttled span is never left
## to the automatic loop: this script accumulates real `delta` every tick it withholds, then fires
## that whole sum into `RenderingServer.force_draw(true, accumulated_step)` for the one frame that
## does draw, immediately setting `render_loop_enabled` back to false first so the engine's own
## end-of-iteration draw does not ALSO fire and double up. See `saver_drift_probe.gd` for the
## measurement this depends on — it is not asserted here without a number.
##
## WATCHDOG: no matter what the interval math above concludes, a real draw always happens within
## `WATCHDOG_MS`. This is not normal operation (both real intervals below are well under it) — it
## is the answer to a named round-1 safety concern: `Platform` and most autoloads have no
## `process_mode` override, so if the SceneTree pauses on a frame where the gate had just withheld
## a draw, nothing would ever ask for another one and the screen would freeze with the pause menu
## itself unpainted. This node runs with `PROCESS_MODE_ALWAYS`, so its own `_process` still ticks
## through a pause, and the watchdog is the hard ceiling that guarantees it eventually draws
## regardless of any bug in the mode logic above it.

## One draw every 50-66 ms while a tree-pausing menu sits open and idle (about 15-20 Hz). Menus are
## static pictures once open, so heat-web-3 found the 3D view drawing every frame behind them pure
## waste; this is the safe slice of that finding — slower drawing, not the riskier disable_3d/
## snapshot swap, which is not this item's job.
##
## ROUND-2 FIX (critic): the `_process` check below only fires the tick AFTER `since_draw` has
## already passed the interval, so the real gap is the interval plus up to one process tick's worth
## of overshoot — measured 67-72 ms out of a raw 58 ms target. Set the constant low enough that the
## interval plus that quantization overshoot still lands inside the target band, instead of AT its
## edge: 45 ms measured landing at 50-61 ms across runs.
const MENU_INTERVAL_MS := 45

## Opt-in "battery saver": ~30 Hz, matching heat-web-2's own measured configuration
## (`render_loop_enabled` alternated so exactly 30 frames drew against a 60 Hz process loop).
## Off by default — this changes what movement and flights look like, and only the player, on
## their own phone, gets to decide that trade-off is worth it (round-1 safety note).
##
## ROUND-2 FIX (critic): same frame-edge quantization as MENU_INTERVAL_MS above — a raw 33 ms target
## measured 25.6-27.1 draws/s with uneven 33/50 ms gaps, not the ~30/s heat_ranked asks for. Lowering
## the raw interval to 25 ms lets the same overshoot land the real average back near 30 Hz.
const SAVER_INTERVAL_MS := 25

## Hard ceiling: never withhold a draw longer than this, whatever the mode logic above decides.
const WATCHDOG_MS := 100

## After any input activity, or a caller-reported one via `notify_activity()`, draw every frame for
## this long before a tree-pausing menu is allowed to drop back to `MENU_INTERVAL_MS`. A phone-style
## drag-scroll or a focus change is a run of many small events, not one, so this is a rolling window
## re-armed by each new one, not a one-shot timer.
const ACTIVITY_WINDOW_MS := 500

var _active := false
var _saver := false
var _last_draw_ms := 0
var _accum_step := 0.0
var _last_activity_ms := -ACTIVITY_WINDOW_MS - 1000
var _drawn_in_window := 0
var _window_start_ms := 0
var _last_dps := 0.0


func _ready() -> void:
	# PROCESS_MODE_ALWAYS: this node must keep ticking through `get_tree().paused` — that is the
	# one case (a tree-pausing menu) this gate is explicitly asked to throttle, and it is also the
	# watchdog's own precondition (see the class doc above).
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)
	_active = OS.has_feature("web") or OS.get_cmdline_user_args().has("--draw-saver")
	var now := Time.get_ticks_msec()
	_last_draw_ms = now
	_window_start_ms = now
	print("[DrawGate] active: ", _active, " (web: ", OS.has_feature("web"), ")")
	if _active:
		# Baseline: drawing is on until the first frame decides otherwise. On desktop without
		# --draw-saver this function returns above and NOTHING here ever runs (item 4's checklist
		# #4: the gate stays inactive and frame pacing is unchanged).
		RenderingServer.render_loop_enabled = true
		# ROUND-2 FIX (critic): a menu's own Control can consume a nav key (or a click that moves
		# focus) before it ever reaches this node's `_input` — Godot stops `_input` propagation once
		# something marks the event handled, and arrow-key focus navigation does exactly that. Focus
		# changes are the one activity signal that survives regardless of who consumed the raw event.
		get_viewport().gui_focus_changed.connect(func(_c: Control) -> void: notify_activity())


## Any real InputEvent counts as activity — touch, drag, key, wheel or a gamepad all arrive as one
## of these. NOTE (round-2): this alone is not reliable — a Control ahead of this node in `_input`
## propagation order can consume the event first (nav-key focus movement does), so a menu key press
## can reach here as nothing at all. `_process`'s `Input.is_anything_pressed()` poll below and the
## `gui_focus_changed` connection in `_ready` are the fallbacks that catch what this handler misses;
## keep all three.
func _input(event: InputEvent) -> void:
	if not _active:
		return
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventMouseMotion \
			or event is InputEventScreenTouch or event is InputEventScreenDrag \
			or event is InputEventPanGesture or event is InputEventMagnifyGesture \
			or event is InputEventJoypadButton or event is InputEventJoypadMotion:
		notify_activity()


## Other builders call this for activity this node cannot see as a raw InputEvent — a
## ScrollContainer's `scroll_ended`/`value_changed` mid-animation, a Control gaining focus by code,
## a programmatic drag. Re-arms the same 0.5 s responsive window `_input` does.
func notify_activity() -> void:
	_last_activity_ms = Time.get_ticks_msec()


## DEV's saver toggle (Perf tab). Never persisted — heat_ranked.md's toggles are re-applied on
## `planet_loaded` and are never saved, and this is not the exception (unlike HEAT-LOAD's warm-up
## setting, this is deliberately session-only so the player is re-asked, not stuck on a forgotten
## trade-off).
func set_saver(on: bool) -> void:
	_saver = on


func saver_on() -> bool:
	return _saver


## "off" (desktop, no --draw-saver: this whole script is a no-op), "normal" (full rate), "menu"
## (a tree-pausing menu, idle past the activity window), or "saver" (the opt-in throttle, idle past
## the activity window). Read by DEV's Perf tab and by this item's own probes.
func mode() -> String:
	if not _active:
		return "off"
	if not _recent_activity():
		if get_tree().paused:
			return "menu"
		if _saver:
			return "saver"
	return "normal"


## Measured, not assumed — a rolling count over the last completed ~1 s window of ACTUAL draws
## (RenderingServer.render_loop_enabled left on, or a manual force_draw), whatever the current mode.
func drawn_per_second() -> float:
	return _last_dps


func _recent_activity() -> bool:
	return Time.get_ticks_msec() - _last_activity_ms < ACTIVITY_WINDOW_MS


func _process(delta: float) -> void:
	if not _active:
		return
	# ROUND-2 FIX (critic): a held or just-tapped key/button/joypad control counts as activity even
	# when a Control ahead of us swallowed the InputEvent in `_input` (see the note there) — polled
	# every tick, so a press-then-release within one frame (the KEY_DOWN nav-key case) is still seen
	# because release happens on the NEXT frame's input flush, after this poll already ran.
	if Input.is_anything_pressed():
		notify_activity()
	var now := Time.get_ticks_msec()
	_accum_step += delta
	var interval := 0
	if not _recent_activity():
		if get_tree().paused:
			interval = MENU_INTERVAL_MS
		elif _saver:
			interval = SAVER_INTERVAL_MS
	var since_draw := now - _last_draw_ms
	if interval <= 0:
		_draw_full(now)
	elif since_draw >= WATCHDOG_MS or since_draw >= interval:
		_draw_throttled(now)
	elif not RenderingServer.render_loop_enabled:
		pass # already withheld; nothing to do this tick
	else:
		RenderingServer.render_loop_enabled = false


## Full rate: let the engine's own end-of-iteration draw fire normally, with its own normal
## per-frame delta. No `force_draw` needed here — nothing was skipped, so there is nothing to sum.
func _draw_full(now: int) -> void:
	if not RenderingServer.render_loop_enabled:
		RenderingServer.render_loop_enabled = true
	_last_draw_ms = now
	_accum_step = 0.0
	_record_draw(now)


## Throttled: draw exactly once, carrying the FULL accumulated step so TIME-driven shaders and
## GPUParticles3D land where the real clock says they should (see the class doc's "summed delta"
## section) — then withhold again immediately so the engine's own automatic draw this same
## iteration does not also fire and double the frame.
func _draw_throttled(now: int) -> void:
	RenderingServer.render_loop_enabled = false
	RenderingServer.force_draw(true, _accum_step)
	_last_draw_ms = now
	_accum_step = 0.0
	_record_draw(now)


func _record_draw(now: int) -> void:
	_drawn_in_window += 1
	var span := now - _window_start_ms
	if span >= 1000:
		_last_dps = _drawn_in_window * 1000.0 / float(span)
		_drawn_in_window = 0
		_window_start_ms = now
