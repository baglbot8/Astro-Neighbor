extends Node
## COOL MODE probe (2026-10-18): what DrawGate actually draws, and what script/physics actually tick,
## with the player's "Cool mode" setting OFF and ON, in the REAL world scene. Not shipped
## (showcase/cool_mode_*).
##
## DESKTOP STAND-IN: DrawGate is only active on the web build or with the `--draw-saver` user arg.
## This probe needs that arg to measure anything; the web path (render_loop_enabled on WebGL in a
## phone browser) is NOT exercised here.
##
## Usage (one Godot at a time, windowed, not covered):
##   godot --rendering-method gl_compatibility --max-fps 60 --always-on-top --position 100,100 \
##     --path <copy> --quit-after 4000 res://showcase/cool_mode_rates.tscn -- --draw-saver [--phase-secs=3]
##
## Every number is counted here, independently of DrawGate's own bookkeeping:
## - drawn/s: RenderingServer.frame_post_draw signals per second (fires for the engine's own draw AND
##   for DrawGate's force_draw), next to DrawGate.drawn_per_second() for comparison.
## - gap_max: the longest wall-clock gap between two draws in the phase (the 100 ms watchdog bound).
## - always proc/phys: ticks of this node (PROCESS_MODE_ALWAYS) - the engine's own loop rate.
## - game proc/phys: ticks of a PROCESS_MODE_PAUSABLE child - gameplay rate (0 while a tree-pausing
##   menu is open, by design).
## Works against the pre-change DrawGate too (no set_cool_mode: falls back to set_saver), so the same
## probe gives the before/after numbers.

const PAUSE_PATH := "/root/World/HUD/PauseMenu"

var _phase_secs := 3.0
var _always_proc := 0
var _always_phys := 0
var _game_proc := 0
var _game_phys := 0
var _draws := 0
var _last_draw_us := 0
var _gap_max_us := 0
var _first_draw_after_us := -1
var _watch_from_us := -1
var _ticker: Node


class Ticker extends Node:
	var proc := 0
	var phys := 0
	func _process(_d: float) -> void:
		proc += 1
	func _physics_process(_d: float) -> void:
		phys += 1


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		print("COOLRATES_SKIP headless has no real draw loop; this probe needs a window")
		get_tree().quit.call_deferred()
		return
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--phase-secs="):
			_phase_secs = float(a.substr(13))
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ticker = Ticker.new()
	_ticker.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_ticker)
	RenderingServer.frame_post_draw.connect(_on_post_draw)
	print("[Platform] renderer (probe): ", RenderingServer.get_current_rendering_method())
	_run.call_deferred()


func _process(_d: float) -> void:
	_always_proc += 1


func _physics_process(_d: float) -> void:
	_always_phys += 1


func _on_post_draw() -> void:
	var now := Time.get_ticks_usec()
	_draws += 1
	if _last_draw_us > 0:
		_gap_max_us = maxi(_gap_max_us, now - _last_draw_us)
	_last_draw_us = now
	if _watch_from_us >= 0 and _first_draw_after_us < 0 and now >= _watch_from_us:
		_first_draw_after_us = now - _watch_from_us


func _gate() -> Node:
	return get_tree().root.get_node_or_null("DrawGate")


func _pause() -> Node:
	return get_tree().root.get_node_or_null(PAUSE_PATH)


func _set_cool(on: bool) -> void:
	var g := _gate()
	if g.has_method("set_cool_mode"):
		g.call("set_cool_mode", on)
	else:
		g.call("set_saver", on) # pre-change DrawGate: the old dev-only saver switch


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec, true, false, true).timeout


func _run() -> void:
	# Skip the first-run intro modal (same two flags tests/director/ui_mode_switch.json sets).
	GameState.set_flag("intro_done")
	GameState.set_flag("intro_greeted")
	var world: Node = load("res://src/world/world.tscn").instantiate()
	get_tree().root.add_child(world)
	get_tree().current_scene = world
	var g := _gate()
	print("COOLRATES start gate=%s api=%s" % [str(g != null),
		"setting" if g != null and g.has_method("set_cool_mode") else "set_saver(old)"])
	if g == null or str(g.call("mode")) == "off":
		print("COOLRATES_SKIP DrawGate inactive - pass --draw-saver after the --")
		get_tree().quit()
		return
	await _wait(3.0) # world load, shader warm-up, first-run hitches
	_set_cool(false)
	await _measure("off_a")
	await _measure("off_b")
	_set_cool(true)
	await _measure("on_a")
	await _measure("on_b")
	# Menu open, programmatically (no InputEvent): the menu's own focus grab re-arms DrawGate's activity
	# window, so the first 0.5 s are full rate; time-to-first-draw is measured from the call.
	var pm := _pause()
	_watch_from_us = Time.get_ticks_usec()
	_first_draw_after_us = -1
	pm.call("open")
	await _wait(0.25)
	print("COOLRATES open_paint first_draw_after_open_ms=%.1f (cool on)" % [_first_draw_after_us / 1000.0])
	_watch_from_us = -1
	await _wait(0.6)
	await _measure("on_menu")
	_set_cool(false)
	await _wait(0.1)
	await _measure("off_menu")
	# Toggle spam with the menu open on its Settings page: 40 flips, one every 50 ms, through the
	# switch itself when the new row exists (debug_set_cool_mode), else straight to DrawGate.
	if pm.has_method("_open_settings"):
		pm.call("_open_settings")
	await _wait(0.6)
	_reset_counters()
	var t0 := Time.get_ticks_usec()
	var on := false
	for i in 40:
		on = not on
		if pm.has_method("debug_set_cool_mode"):
			pm.call("debug_set_cool_mode", on)
		else:
			_set_cool(on)
		await _wait(0.05)
	_report("spam_40x", t0)
	print("COOLRATES spam_end want=%s setting=%s saver_on=%s mode=%s" % [str(on),
		str(GameState.settings.get("cool_mode", "n/a")), str(g.call("saver_on")), str(g.call("mode"))])
	await _wait(0.6)
	await _measure("spam_settle_menu")
	pm.call("close")
	await _wait(0.8)
	_set_cool(true)
	await _measure("on_after_menu")
	_set_cool(false)
	await _measure("off_end")
	print("COOLRATES done")
	get_tree().quit()


func _reset_counters() -> void:
	_always_proc = 0
	_always_phys = 0
	_ticker.proc = 0
	_ticker.phys = 0
	_draws = 0
	_gap_max_us = 0
	_last_draw_us = 0


func _measure(tag: String) -> void:
	await _wait(0.6) # past DrawGate's 0.5 s activity window after any change
	_reset_counters()
	var t0 := Time.get_ticks_usec()
	var modes := {}
	var steps := int(_phase_secs / 0.1)
	for i in steps:
		await _wait(0.1)
		var m := str(_gate().call("mode"))
		modes[m] = int(modes.get(m, 0)) + 1
	_report(tag, t0, modes)


func _report(tag: String, t0: int, modes: Dictionary = {}) -> void:
	var el := (Time.get_ticks_usec() - t0) / 1000000.0
	var g := _gate()
	print("COOLRATES %-16s drawn/s=%5.1f gate_dps=%5.1f gap_max_ms=%6.1f always_proc/s=%5.1f always_phys/s=%5.1f game_proc/s=%5.1f game_phys/s=%5.1f paused=%s modes=%s secs=%.2f" % [
		tag, _draws / el, float(g.call("drawn_per_second")), _gap_max_us / 1000.0,
		_always_proc / el, _always_phys / el, _ticker.proc / el, _ticker.phys / el,
		str(get_tree().paused), str(modes), el])
