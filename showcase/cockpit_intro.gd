extends Node
## SHOWCASE + PROBE for the cockpit opening (src/onboarding/cockpit_intro.gd, docs/INTRO_SPEC.md).
## Builds the REAL world (res://src/world/world.tscn as /root/World, a new game at home) and adds a
## CockpitIntro under it exactly as IntroDirector will, then drives it with SYNTHESISED input
## (Input.parse_input_event - the path a mouse takes into _input, but no real hardware, and never a
## real finger). Prints "PROBE ..." lines; --shots=<abs dir> saves PNGs of the moments that matter.
##
##   godot --path <copy> --rendering-method gl_compatibility --resolution 1560x720 \
##     --always-on-top --position 100,100 --max-fps 30 --quit-after 9000 \
##     res://showcase/cockpit_intro.tscn -- --no-intro --mode=play --shots=/abs/dir
##
## Modes (after "--"; always pass --no-intro so the world's own IntroDirector stays out of it):
##   play      look at the four things in turn (drags), then the meteor, the cut and today's full
##             CrashIntro after it (B2's start-at-the-hit is not in this copy); prints the neighbour
##             worlds' screen positions in the hand-off frame at the end ("SKY ..." lines)
##   baseline  today's CrashIntro alone at scene start (no cockpit), the same "SKY ..." print
##   idle      no input at all: when the nudge and the meteor come
##   clamp     drags far past every limit; prints where the head stopped
##   skip      a tap -> one SkipConfirm -> "Skip": checks finished(true) and the state left behind
##   keep      a drag (must not ask), a tap -> "Keep watching" (clock frozen while open), then plays on
##   lines     prints every line box with its length and fails any over 60 characters
##   timing    frame times looking at the window and the photo wall (run alone, no taskpolicy)
## --cockpit-no-stage (passed through to CockpitIntro): the unstaged A/B for the sky lock.

const WORLD := "res://src/world/world.tscn"

var _mode := "play"
var _shots := ""
var _world: Node
var _cockpit: CockpitIntro
var _crash: CrashIntro
var _t := 0.0
var _step := 0
var _wait := 0.0
var _finished: Array = []
var _shot_done: Dictionary = {}
var _aim := Vector2.ZERO
var _aiming := false
var _dragging := false
var _target_order: Array = ["camera", "plant", "letter", "photos"]
var _target_i := 0
var _frames: Array[float] = []
var _gpu: Array[float] = []
var _cpu: Array[float] = []
var _timing_view := 0
var _confirm_t := -1.0
var _t_at_confirm := 0.0
var _crash_done_t := -1.0
var _wall_ms := 0
var _last_us := 0
var _pending_release: InputEventMouseButton


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--mode="):
			_mode = a.substr(7)
		elif a.begins_with("--shots="):
			_shots = a.substr(8)
	if _mode == "lines":
		_check_lines()
		return
	if _shots != "":
		DirAccess.make_dir_recursive_absolute(_shots)
	GameState.reset_new_game()
	GameState.current_planet_id = "home"
	_world = load(WORLD).instantiate()
	_world.name = "World"
	get_tree().root.add_child.call_deferred(_world)
	call_deferred("_after_world")


func _after_world() -> void:
	get_tree().current_scene = _world
	await get_tree().process_frame
	print("PROBE mode=%s renderer=%s size=%s" % [_mode, RenderingServer.get_current_rendering_method(),
		str(get_viewport().get_visible_rect().size)])
	if _mode == "baseline":
		# --crash-only: today's full crash shot from its navy card, no cockpit.
		_start_crash()
		return
	# IntroDirector._start_crash's frame-1 order (B2, 2026-10-18): a waiting CrashIntro FIRST (it
	# freezes and hides the astronaut at the landing spot, snaps the rig there and holds the
	# "cutscene" modal), then the cockpit.
	var probe := CrashIntro.new()
	if "wait_for_go" in probe:
		_crash = probe
		_crash.name = "CrashIntro"
		_crash.finished.connect(_on_crash_finished)
		_crash.set("start_t", CrashIntro.HIT_T)
		_crash.set("wait_for_go", true)
		_world.add_child(_crash)
	else:
		probe.free()
		print("PROBE WARNING: this copy's CrashIntro has no wait_for_go (B2's crash_intro.gd not merged): the cockpit runs alone and today's full crash plays after the cut")
	_cockpit = CockpitIntro.new()
	_cockpit.name = "CockpitIntro"
	_cockpit.finished.connect(_on_cockpit_finished)
	_world.add_child(_cockpit)
	if _mode in ["timing", "play"]:
		RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)


func _on_cockpit_finished(skipped: bool) -> void:
	_finished.append(skipped)
	var cam := get_viewport().get_camera_3d()
	var rig := _world.get_node_or_null("CameraRig") as CameraRig
	var player := get_tree().get_first_node_in_group("player") as Player
	var env := _world.get_node_or_null("Environment")
	print("PROBE finished(skipped=%s) count=%d t=%.2f cam_is_rig=%s modal_total=%d player_visible=%s input=%s process=%s physics=%s space_blend=%.2f time_scale=%s fade_a=%.2f" % [
		str(skipped), _finished.size(), _t, str(rig != null and cam == rig.get_camera()), EventBus.modal_total(),
		str(player.visible), str(player.input_enabled), str(player.is_processing()), str(player.is_physics_processing()),
		float(env.call("get_space_blend")), str(env.get("time_scale")), _fade_alpha()])
	_shot("handoff_white")
	if _crash == null and not skipped and _mode == "play":
		_start_crash()
	elif _crash != null and is_instance_valid(_crash) and _crash.has_method("go"):
		if skipped:
			_crash.call("finish_skipped")
		else:
			_crash.call("go")
		print("PROBE after %s: current camera=%s" % ["finish_skipped" if skipped else "go",
			str(get_viewport().get_camera_3d().get_path())])


func _start_crash() -> void:
	_crash = CrashIntro.new()
	_crash.name = "CrashIntro"
	_crash.finished.connect(_on_crash_finished)
	_world.add_child(_crash)


func _on_crash_finished(s: bool) -> void:
	_crash_done_t = _t
	print("PROBE crash finished skipped=%s t=%.2f clock=%s (time_of_day %.3f h)" % [str(s), _t,
		"%02d:%02d" % [int(GameState.time_of_day), int(fmod(GameState.time_of_day, 1.0) * 60.0)], GameState.time_of_day])


func _fade_alpha() -> float:
	var fade: Variant = SceneRouter.get("_fade")
	return (fade as ColorRect).color.a if fade is ColorRect else -1.0


# ============================================================================= per frame
func _process(delta: float) -> void:
	if _world == null:
		return
	_t += delta
	if _crash_done_t >= 0.0:
		if _mode == "skip" and _once("skip_report"):
			_report_after_skip()
		if _t >= _crash_done_t + 1.5 and _once("sky"):
			_print_sky()
			_shot("after_crash_handoff")
		if _t >= _crash_done_t + 2.0:
			get_tree().quit()
		return
	if _cockpit == null or not is_instance_valid(_cockpit):
		return
	var s := _cockpit.debug_state()
	match _mode:
		"play":
			_drive_play(s, delta)
		"idle":
			_drive_idle(s)
		"clamp":
			_drive_clamp(s)
		"skip", "keep":
			_drive_skip(s)
		"timing":
			_drive_timing(s, delta)
		"touch":
			_drive_touch(s)


func _drive_play(s: Dictionary, _delta: float) -> void:
	if not bool(s["cam_current"]) or str(s["phase"]) == "CARD":
		return
	if str(s["phase"]) == "LOOK" and float(s["look_t"]) < 2.3:
		_shot_at(s, "reveal", float(s["look_t"]) >= 2.0)
		return
	if str(s["phase"]) == "LOOK":
		if _target_i < _target_order.size():
			var id: String = _target_order[_target_i]
			var b: Vector2 = _cockpit.debug_target_bearings()[id]
			if not (s["triggered"] as Array).has(id):
				_steer(s, b)
			else:
				_release()
				if str(s["item"]) != "" and not bool(s["item_typing"]):
					_shot("look_%s" % id)
				if (s["seen"] as Array).has(id):
					_target_i += 1
					print("PROBE seen %s at t=%.2f (yaw %.1f pitch %.1f)" % [id, float(s["t"]), float(s["yaw"]), float(s["pitch"])])
		else:
			# Back to the window while waiting for the meteor (one drag; lifting it after it moved).
			if absf(float(s["player_yaw"])) > 1.0 or _dragging:
				_steer(s, Vector2(0.0, 2.0))
				if absf(float(s["player_yaw"])) <= 1.0:
					_release()
	elif str(s["phase"]) == "METEOR":
		_release()
		var tau := float(s["tau"])
		# Frame time through the meteor beat (wall clock; meaningless under --max-fps or with --shots).
		var now := Time.get_ticks_usec()
		if _last_us > 0:
			var ms := float(now - _last_us) / 1000.0
			if ms > 40.0:
				print("PROBE METEOR HITCH %.1f ms at tau %.2f" % [ms, tau])
			_frames.append(ms)
			_cpu.append(RenderingServer.viewport_get_measured_render_time_cpu(get_viewport().get_viewport_rid()))
		_last_us = now
		if tau >= 7.1 and _once("meteor_timing"):
			print("PROBE METEOR TIMING n=%d frame_ms mean=%.2f p95=%.2f max=%.2f cpu_render mean=%.2f" % [
				_frames.size(), _mean(_frames), _pct(_frames, 0.95), _pct(_frames, 1.0), _mean(_cpu)])
		_shot_at(s, "meteor_t1_2", tau >= 1.2)
		_shot_at(s, "meteor_t2_6", tau >= 2.6)
		_shot_at(s, "meteor_t4_2", tau >= 4.2)
		_shot_at(s, "meteor_t5_8", tau >= 5.8)
		_shot_at(s, "meteor_t6_4", tau >= 6.4)
		_shot_at(s, "meteor_t6_6_contact", tau >= 6.62)
		_shot_at(s, "meteor_t6_8", tau >= 6.8)
		_shot_at(s, "meteor_flash", tau >= 7.02)


## Drags the mouse (left button held) toward a head bearing, at most 18 px a frame.
func _steer(s: Dictionary, bearing: Vector2) -> void:
	var rows := get_viewport().get_visible_rect().size.y
	var k := CockpitIntro.DRAG_DEG_PER_SCREEN / rows
	var d := Vector2(bearing.x - float(s["player_yaw"]), bearing.y - float(s["player_pitch"]))
	if d.length() < 0.6:
		return
	if not _dragging:
		if _mode == "touch":
			var st := InputEventScreenTouch.new()
			st.index = 0
			st.pressed = true
			st.position = get_viewport().get_visible_rect().size * 0.5
			Input.parse_input_event(st)
			_dragging = true
			return
		var mb := InputEventMouseButton.new()
		mb.button_index = MOUSE_BUTTON_LEFT
		mb.pressed = true
		mb.position = get_viewport().get_visible_rect().size * 0.5
		Input.parse_input_event(mb)
		_dragging = true
		return
	var px := Vector2(-d.x, -d.y) / k
	px = px.limit_length(18.0)
	if _mode == "touch":
		var sd := InputEventScreenDrag.new()
		sd.index = 0
		sd.relative = px
		sd.position = get_viewport().get_visible_rect().size * 0.5
		Input.parse_input_event(sd)
		return
	var mm := InputEventMouseMotion.new()
	mm.relative = px
	mm.button_mask = MOUSE_BUTTON_MASK_LEFT
	mm.position = get_viewport().get_visible_rect().size * 0.5
	Input.parse_input_event(mm)


func _release() -> void:
	if not _dragging:
		return
	if _mode == "touch":
		var st := InputEventScreenTouch.new()
		st.index = 0
		st.pressed = false
		st.position = get_viewport().get_visible_rect().size * 0.5
		Input.parse_input_event(st)
		_dragging = false
		return
	var mb := InputEventMouseButton.new()
	mb.button_index = MOUSE_BUTTON_LEFT
	mb.pressed = false
	mb.position = get_viewport().get_visible_rect().size * 0.5
	Input.parse_input_event(mb)
	_dragging = false


func _drive_idle(s: Dictionary) -> void:
	if bool(s["nudged"]) and _once("nudge"):
		print("PROBE nudge at look_t=%.2f idle=%.2f" % [float(s["look_t"]), float(s["idle"])])
	if str(s["phase"]) == "METEOR" and _once("meteor"):
		print("PROBE meteor at look_t=%.2f forced=%s seen=%s" % [float(s["look_t"]), str(s["forced"]), str(s["seen"])])
	# --late: short looks (the camera_left action, polled) at look t 20 and 40, so 30 s of idle only comes
	# at 70 - too close to the forced meteor at 75 for the nudge (NUDGE_MIN_LEFT).
	if OS.get_cmdline_user_args().has("--late"):
		var lt := float(s["look_t"])
		var tap := (lt >= 20.0 and lt < 20.3) or (lt >= 40.0 and lt < 40.3)
		if tap and not Input.is_action_pressed("camera_left"):
			Input.action_press("camera_left")
		elif not tap and Input.is_action_pressed("camera_left"):
			Input.action_release("camera_left")


const CLAMP_STEPS := [Vector2(-400.0, 0.0), Vector2(400.0, 0.0), Vector2(0.0, -400.0), Vector2(0.0, 400.0),
	Vector2(-400.0, -400.0), Vector2(400.0, 400.0)]

func _drive_clamp(s: Dictionary) -> void:
	if str(s["phase"]) != "LOOK":
		return
	if _step >= CLAMP_STEPS.size():
		if _once("clamp_done"):
			_release()
			get_tree().quit()
		return
	var goal: Vector2 = CLAMP_STEPS[_step]
	if _wait <= 0.0:
		_wait = _t
		_aim = Vector2(-goal.x, -goal.y)
	if _t - _wait < 1.6:
		if not _dragging:
			var mb := InputEventMouseButton.new()
			mb.button_index = MOUSE_BUTTON_LEFT
			mb.pressed = true
			Input.parse_input_event(mb)
			_dragging = true
		var mm := InputEventMouseMotion.new()
		mm.relative = _aim.normalized() * 25.0 * signf(_aim.length())
		mm.button_mask = MOUSE_BUTTON_MASK_LEFT
		Input.parse_input_event(mm)
	elif _t - _wait >= 2.0:
		print("PROBE clamp drag dir %s -> yaw %.2f pitch %.2f (targets %.2f %.2f)" % [str(goal.normalized()),
			float(s["yaw"]), float(s["pitch"]), float(s["player_yaw"]), float(s["player_pitch"])])
		_shot("clamp_%d" % _step)
		_release()
		_step += 1
		_wait = 0.0


func _drive_skip(s: Dictionary) -> void:
	if str(s["phase"]) != "LOOK":
		return
	var t := float(s["t"])
	if _mode == "keep" and _step == 0 and t >= 2.0:
		# A drag of 300 px must never ask.
		_steer(s, Vector2(30.0, 0.0))
		if absf(float(s["player_yaw"]) - 30.0) < 1.0:
			_release()
			_step = 1
			_wait = _t
			print("PROBE drag done yaw=%.1f confirm_open=%s" % [float(s["player_yaw"]), str(SkipConfirm.is_open())])
		return
	if (_step == 0 and _mode == "skip" and t >= 2.5) or (_step == 1 and _t > _wait + 0.6):
		# A TAP ON THE PLANT (finger and mouse): must open nothing.
		var at := _cockpit.debug_target_screen("plant")
		print("PROBE tap on the plant at %s: confirm_open before=%s" % [str(at), str(SkipConfirm.is_open())])
		var st := InputEventScreenTouch.new()
		st.index = 0
		st.pressed = true
		st.position = at
		Input.parse_input_event(st)
		var st2 := st.duplicate() as InputEventScreenTouch
		st2.pressed = false
		Input.parse_input_event(st2)
		var mb := InputEventMouseButton.new()
		mb.button_index = MOUSE_BUTTON_LEFT
		mb.pressed = true
		mb.position = at
		Input.parse_input_event(mb)
		var up := mb.duplicate() as InputEventMouseButton
		up.pressed = false
		Input.parse_input_event(up)
		_step = 10
		_wait = _t
		return
	if _step == 10 and _t > _wait + 0.8:
		print("PROBE after plant taps: confirm_open=%s popups=%d confirming=%s" % [str(SkipConfirm.is_open()), _count_popups(), str(s["confirming"])])
		# THE SKIP BUTTON: one real-path click at its centre (after a wall-clock quiet gap).
		var r: Rect2 = _cockpit.debug_skip_rect()
		print("PROBE skip button rect=%s (height %.0f canvas px)" % [str(r), r.size.y])
		_shot("skip_button")
		var mb := InputEventMouseButton.new()
		mb.button_index = MOUSE_BUTTON_LEFT
		mb.pressed = true
		mb.position = r.get_center()
		mb.global_position = mb.position
		Input.parse_input_event(mb)
		_pending_release = mb
		_step = 11
		return
	if _step == 11:
		if _pending_release != null:
			var up := _pending_release.duplicate() as InputEventMouseButton
			up.pressed = false
			Input.parse_input_event(up)
			_pending_release = null
		_step = 2
		_wait = _t
		return
	if _step == 2 and _t > _wait + 0.5:
		var n := _count_popups()
		print("PROBE after tap: confirm_open=%s popups=%d confirming=%s t=%.2f" % [str(SkipConfirm.is_open()), n, str(s["confirming"]), t])
		_shot("skip_popup")
		_t_at_confirm = t
		_step = 3
		_wait = _t
		_wall_ms = Time.get_ticks_msec()
		return
	if _step == 3 and _t > _wait + 1.0 and Time.get_ticks_msec() - _wall_ms >= 1500:
		print("PROBE clock while open: t moved %.3f s over %.2f s of game time" % [t - _t_at_confirm, _t - _wait])
		var label := "Skip" if _mode == "skip" else "Keep watching"
		var b := _find_button(get_tree().root, label)
		print("PROBE clicking '%s' (synthesised InputEventMouseButton at its centre, after a 1.5 s wall-clock quiet gap) found=%s" % [label, str(b != null)])
		if b != null:
			var mb := InputEventMouseButton.new()
			mb.button_index = MOUSE_BUTTON_LEFT
			mb.pressed = true
			mb.position = b.get_global_rect().get_center()
			mb.global_position = mb.position
			Input.parse_input_event(mb)
			_pending_release = mb
		_step = 4
		_wait = _t
		return
	if _step == 4 and _pending_release != null:
		var up := _pending_release.duplicate() as InputEventMouseButton
		up.pressed = false
		Input.parse_input_event(up)
		_pending_release = null
		return
	if _step == 4 and _mode == "keep" and _t > _wait + 1.0:
		print("PROBE after keep: confirm_open=%s phase=%s t=%.2f confirming=%s" % [str(SkipConfirm.is_open()), str(s["phase"]), t, str(s["confirming"])])
		_mode = "play"


## --ui=mobile: the HUD and touch controls must be hidden (by CrashIntro's modal), and a one-finger
## ScreenDrag must turn the head (SYNTHESISED ScreenTouch/ScreenDrag - not a real finger).
func _drive_touch(s: Dictionary) -> void:
	if str(s["phase"]) != "LOOK":
		return
	if _once("touch_state"):
		var tc := get_tree().root.find_children("*", "TouchControls", true, false)
		var hud := _world.get_node_or_null("HUD")
		print("PROBE touch: mobile=%s touch_controls=%d visible=%s hud=%s modal_total=%d" % [str(MobileUI.is_mobile()), tc.size(),
			str((tc[0] as CanvasItem).is_visible_in_tree()) if tc.size() > 0 else "-", str(hud != null), EventBus.modal_total()])
		_shot("touch_start")
	var b: Vector2 = _cockpit.debug_target_bearings()["camera"]
	if not (s["triggered"] as Array).has("camera"):
		_steer(s, b)
	elif _once("touch_done"):
		_release()
		print("PROBE touch: camera triggered by a one-finger drag, yaw %.1f pitch %.1f confirm_open=%s" % [
			float(s["yaw"]), float(s["pitch"]), str(SkipConfirm.is_open())])
		get_tree().quit()


func _count_popups() -> int:
	var n := 0
	for c in get_tree().root.find_children("SkipConfirmLayer", "", true, false):
		n += 1
	return n


func _find_button(n: Node, text: String) -> Button:
	if n is Button and (n as Button).text == text and (n as Button).is_visible_in_tree():
		return n
	for c in n.get_children():
		var b := _find_button(c, text)
		if b != null:
			return b
	return null


func _report_after_skip() -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	print("PROBE after skip: finished=%s cockpit_freed=%s modal_total=%d fade_a=%.2f player_visible=%s input=%s cam=%s finish=%s" % [
		str(_finished), str(_cockpit == null or not is_instance_valid(_cockpit)), EventBus.modal_total(),
		_fade_alpha(), str(player.visible), str(player.input_enabled), str(get_viewport().get_camera_3d().get_path()),
		str((_world.get_node("Rocket").get("rocket") as RocketModel).finish_stage())])


## TIMING: hold three views (window, photo wall, dash) for 6 s each after a 3 s settle; report the
## frame delta and the measured CPU/GPU render time per view.
func _drive_timing(s: Dictionary, delta: float) -> void:
	if str(s["phase"]) != "LOOK":
		return
	var views := [Vector2(0.0, 2.0), Vector2(60.0, 8.0), Vector2(-25.0, -20.0)]
	var lt := float(s["look_t"])
	if lt < 3.0:
		return
	var idx := int((lt - 3.0) / 7.0)
	if idx >= views.size():
		if _once("timing_done"):
			_release()
			get_tree().quit()
		return
	if idx != _timing_view:
		_report_timing(_timing_view)
		_timing_view = idx
		_last_us = 0
		_frames.clear()
		_gpu.clear()
		_cpu.clear()
	var b: Vector2 = views[idx]
	var into := lt - 3.0 - float(idx) * 7.0
	if into < 1.0:
		_steer(s, b)
		return
	_release()
	var vp := get_viewport().get_viewport_rid()
	# Wall-clock frame time: `delta` is smoothed by the engine (it read a flat 16.67 under vsync).
	var now := Time.get_ticks_usec()
	if _last_us > 0:
		_frames.append(float(now - _last_us) / 1000.0)
	_last_us = now
	_cpu.append(RenderingServer.viewport_get_measured_render_time_cpu(vp))
	_gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(vp))
	if into >= 6.9 and idx == views.size() - 1 and _once("last_view"):
		_report_timing(idx)


func _report_timing(idx: int) -> void:
	if _frames.is_empty():
		return
	var names := ["window", "photo_wall", "dash"]
	print("PROBE TIMING view=%s n=%d frame_ms mean=%.2f p50=%.2f p95=%.2f max=%.2f | cpu_render mean=%.2f | gpu_render mean=%.2f p95=%.2f max=%.2f" % [
		names[idx], _frames.size(), _mean(_frames), _pct(_frames, 0.5), _pct(_frames, 0.95), _pct(_frames, 1.0),
		_mean(_cpu), _mean(_gpu), _pct(_gpu, 0.95), _pct(_gpu, 1.0)])


static func _mean(a: Array[float]) -> float:
	var s := 0.0
	for v in a:
		s += v
	return s / maxf(float(a.size()), 1.0)


static func _pct(a: Array[float], p: float) -> float:
	var b := a.duplicate()
	b.sort()
	return b[clampi(int(round(p * float(b.size() - 1))), 0, b.size() - 1)]


# ============================================================================= checks
func _check_lines() -> void:
	var boxes: Array[String] = []
	for id: String in CockpitIntro.ITEM_LINES:
		for line: String in CockpitIntro.ITEM_LINES[id]:
			boxes.append(line)
	for l: String in [CockpitIntro.RADIO_HELLO, CockpitIntro.RADIO_NEIGHBOURS, CockpitIntro.RADIO_QUIET,
			CockpitIntro.RADIO_NUDGE, CockpitIntro.RADIO_LATE, CockpitIntro.RADIO_ALARM]:
		boxes.append(l)
	var bad := 0
	for b in boxes:
		var ok := b.length() <= 60
		if not ok:
			bad += 1
		print("PROBE LINE %2d %s \"%s\"" % [b.length(), "ok  " if ok else "OVER", b])
	print("PROBE LINES %d boxes, %d over 60: %s" % [boxes.size(), bad, "PASS" if bad == 0 else "FAIL"])
	get_tree().quit(0 if bad == 0 else 1)


func _print_sky() -> void:
	var env := _world.get_node_or_null("Environment")
	var cam := get_viewport().get_camera_3d()
	var player := get_tree().get_first_node_in_group("player") as Node3D
	print("PROBE SKY cam=%s player=%s" % [str(cam.global_position.snapped(Vector3.ONE * 0.01)), str(player.global_position.snapped(Vector3.ONE * 0.01))])
	for id: String in env.call("get_sky_body_ids"):
		var dir: Vector3 = env.call("get_sky_body_direction", id)
		var p := cam.global_position + dir * 140.0
		var on := not cam.is_position_behind(p)
		var sp := cam.unproject_position(p) / get_viewport().get_visible_rect().size if on else Vector2(-9, -9)
		print("PROBE SKY %s dir=%s screen=(%.3f, %.3f)" % [id, str(dir.snapped(Vector3.ONE * 0.001)), sp.x, sp.y])


# ============================================================================= shots
func _shot_at(_s: Dictionary, name: String, cond: bool) -> void:
	if cond:
		_shot(name)


func _shot(name: String) -> void:
	if _shots == "" or _shot_done.has(name):
		return
	_shot_done[name] = true
	var img := get_viewport().get_texture().get_image()
	img.save_png(_shots.path_join("%s.png" % name))
	var extra := ""
	if _cockpit != null and is_instance_valid(_cockpit):
		var st := _cockpit.debug_state()
		extra = " tau=%.2f yaw=%.1f pitch=%.1f meteor_bearing=%s meteor_dist=%.1f" % [float(st["tau"]), float(st["yaw"]),
			float(st["pitch"]), str(st["meteor_bearing"]), float(st["meteor_dist"])]
	print("PROBE shot %s t=%.2f%s" % [name, _t, extra])


func _once(key: String) -> bool:
	if _shot_done.has("once_" + key):
		return false
	_shot_done["once_" + key] = true
	return true
