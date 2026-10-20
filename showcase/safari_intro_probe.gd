extends Node
## SAFARI INTRO PROBE (builder SINTRO, 2026-10-19). A test harness, not gameplay: inert unless `--sip` is
## passed (tools/check.sh runs every showcase scene; it does nothing there).
##
## Starts a planet safari directly (PlanetSafari.request_start - the talk with the host is skipped, the day
## flag is cleared first) and measures the start sequence: when the fade to black begins (phase FADE_IN),
## when the black starts to lift, when control returns (phase AWAKE, elapsed 0). Optional: frames, a
## per-frame camera trace, CPU render time, a synthetic skip / tap / input attack, a scene change mid-intro.
##
##   godot --path <scratch copy> --rendering-method gl_compatibility --resolution 2556x1179 \
##     --always-on-top --position 100,100 [--fixed-fps 30] [--max-fps 30] --quit-after 3000 \
##     res://showcase/safari_intro_probe.tscn -- --sip --planet=zorp --ui=mobile --safari-tips=off \
##     --sip-mode=a|b|off|none [--sip-seen] [--sip-shots=<abs dir>] [--sip-trace] [--sip-perf] \
##     [--sip-skip-at=T] [--sip-keep-at=T] [--sip-tap-at=T] [--sip-input] [--sip-change-at=T] \
##     [--sip-free-at=T] [--sip-after=S] [--sip-hover]
##
##   --sip-mode     writes GameState.settings["safari_intro"] before the start ("none" leaves it unset)
##   --sip-seen     marks both prototypes seen (a later safari: the Skip button shows)
##   --sip-shots    saves the frame every 0.4 s from the lift, plus one 0.5 s after control
##   --sip-trace    one line per frame: the current camera's position, forward, fov and name
##   --sip-perf     per-frame CPU render time (RenderingServer measured) and frame delta, intro vs normal
##   --sip-skip-at  T s after the lift: taps the Skip button, then 0.7 s later the pop-up's "Skip"
##   --sip-keep-at  the same, but answers "Keep watching"
##   --sip-tap-at   T s after the lift: taps the middle of the screen (should do nothing)
##   --sip-input    holds move_forward, presses F / Q / right-click and taps the shutter spot all intro long
##   --sip-change-at  T s after the lift: reloads world.tscn (a scene change mid-intro), then reports state
##   --sip-free-at  T s after the lift: frees PlanetSafari in place, then reports state
##   --sip-after    seconds to keep running after control (default 3) - 25 shows the first events' log
##   --sip-hover    sets the hover flag (the hover hint is due at elapsed 6)
##
## EVERY INPUT HERE IS SYNTHESISED: taps are MobileUI.synth_tap (InputEventMouseButton through
## Input.parse_input_event), keys are InputEventKey through parse_input_event, move_forward is
## Input.action_press (no InputEvent). None of it proves a real finger.

var persistent := false
var _args: PackedStringArray
var _mode := "none"
var _shots_dir := ""
var _trace := false
var _perf := false
var _skip_at := -1.0
var _keep_at := -1.0
var _tap_at := -1.0
var _input_attack := false
var _change_at := -1.0
var _free_at := -1.0
var _after := 3.0

var _started := false
var _wait := 0.0
var _req_ms := -1
var _fade_ms := -1
var _lift_ms := -1
var _awake_ms := -1
var _seen_black := false
var _last_phase := -1
var _t_lift := -1.0        # seconds since the lift, by frame delta (deterministic under --fixed-fps)
var _t_awake := -1.0
var _next_shot := 0.0
var _shot_n := 0
var _after_shot_done := false
var _prev_pos := Vector3.ZERO
var _prev_fwd := Vector3.ZERO
var _have_prev := false
var _jumps: Array = []      # [t, metres, degrees, cam name]
var _perf_intro := PackedFloat64Array()
var _perf_normal := PackedFloat64Array()
var _delta_intro := PackedFloat64Array()
var _delta_normal := PackedFloat64Array()
var _skip_stage := 0
var _skip_tap_t := -1.0
var _tap_done := false
var _player_pos0 := Vector3.ZERO
var _attack_log: Array = []
var _changed := false
var _change_report_t := -1.0
var _freed := false
var _free_report_t := -1.0
var _done := false
var _banner_early := false
var _ui_early := false


func _ready() -> void:
	_args = OS.get_cmdline_user_args()
	if not _args.has("--sip"):
		return
	if not persistent:
		# --planet=meteor|cave: those outings run on the home world (their hosts are added in `_start`).
		for a in _args:
			if a == "--planet=meteor" or a == "--planet=cave":
				GameState.current_planet_id = "home"
		var p: Node = load("res://showcase/safari_intro_probe.gd").new()
		p.persistent = true
		p.name = "SafariIntroProbe"
		get_tree().root.add_child.call_deferred(p)
		get_tree().change_scene_to_file.call_deferred("res://src/world/world.tscn")
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = 100
	for a in _args:
		if a.begins_with("--sip-mode="):
			_mode = a.substr(11)
		elif a.begins_with("--sip-shots="):
			_shots_dir = a.substr(12)
		elif a.begins_with("--sip-skip-at="):
			_skip_at = float(a.substr(14))
		elif a.begins_with("--sip-keep-at="):
			_keep_at = float(a.substr(14))
		elif a.begins_with("--sip-tap-at="):
			_tap_at = float(a.substr(13))
		elif a.begins_with("--sip-change-at="):
			_change_at = float(a.substr(16))
		elif a.begins_with("--sip-free-at="):
			_free_at = float(a.substr(14))
		elif a.begins_with("--sip-after="):
			_after = float(a.substr(12))
	_trace = _args.has("--sip-trace")
	_perf = _args.has("--sip-perf")
	_input_attack = _args.has("--sip-input")
	if _shots_dir != "":
		DirAccess.make_dir_recursive_absolute(_shots_dir)
	for a in _args:
		if a.begins_with("--sip-shot-times="):
			for v in a.substr(17).split(","):
				_shot_times.append(float(v))
	print("SIP armed mode=%s renderer=%s window=%s" % [_mode, RenderingServer.get_current_rendering_method(),
		str(DisplayServer.window_get_size())])
	get_tree().create_timer(120.0, true, false, true).timeout.connect(func() -> void:
		print("SIP WATCHDOG quit")
		get_tree().quit(2))


## The dev menu's new row, tapped like a finger would (DevMenu._tap_point: a synthesised mouse tap at the
## segment's centre), then the setting read back.
func _devmenu_check() -> void:
	_done = true
	var before := str(GameState.settings.get("safari_intro", "<unset>"))
	var menu := DevMenu.open_over(get_tree().root.get_node("World/HUD"))
	await get_tree().process_frame
	var tab_ok: bool = await menu.debug_tap_tab("World")
	var seg0: SegmentedControl = menu.get("_safari_intro_seg")
	var sec_ok := true
	if not seg0.is_visible_in_tree():
		sec_ok = await menu.debug_tap_section("Space photo flights (retired)")
	if not seg0.is_visible_in_tree():
		# The header's real tap missed (see the report); open the section by its own pressed signal instead.
		for c in ((menu.get("_tab_lists") as Dictionary).get("World") as VBoxContainer).get_children():
			if c is Button and (c as Button).text.findn("Space photo flights") >= 0:
				(c as Button).pressed.emit()
				print("SIP devmenu section opened by pressed.emit() (synthetic)")
	await get_tree().process_frame
	await get_tree().process_frame
	print("SIP devmenu tab_ok=%s section_tap=%s menu_visible=%s cur_tab=%s" % [str(tab_ok), str(sec_ok), str(menu.visible), str(menu.get("_current_tab"))])
	var lst: VBoxContainer = (menu.get("_tab_lists") as Dictionary).get("World")
	for c in lst.get_children():
		if c is Button:
			print("SIP   header '%s' vis=%s" % [(c as Button).text, str((c as Button).is_visible_in_tree())])
	var p2 := seg0.get_parent()
	while p2 != null and not (p2 is ScrollContainer):
		print("SIP   up %s %s vis=%s" % [p2.name, p2.get_class(), str((p2 as CanvasItem).visible) if p2 is CanvasItem else "-"])
		p2 = p2.get_parent()
	var seg: SegmentedControl = menu.get("_safari_intro_seg")
	print("SIP devmenu row: seg=%s visible=%s index=%d options=%s setting_before=%s" % [str(seg != null),
		str(seg.is_visible_in_tree()), seg.index, str(seg.options), before])
	for i in [1, 2, 0]:
		var ok: bool = await menu.call("_tap_point", seg, seg.call("_segment_rect", i).get_center())
		await get_tree().process_frame
		print("SIP devmenu tap segment %d ok=%s -> setting=%s index=%d" % [i, str(ok),
			str(GameState.settings.get("safari_intro", "<unset>")), seg.index])
	print("SIP DONE")
	get_tree().quit()


## A title with characters that have no glyph ("Q", "!") must fall back to Baloo 2 with a warning, never crash.
func _glyph_test() -> void:
	_done = true
	var tl := TitleLettering.new()
	get_tree().root.add_child(tl)
	var zw: Node = load("res://src/planet_safari/worlds/zorp.gd").new()
	var st: Dictionary = zw.call("intro_title_style")
	zw.free()
	tl.build(PackedStringArray(["ZORP Q!"]), st)
	tl.bake_start(100.0)
	await get_tree().process_frame
	await get_tree().process_frame
	tl.bake_finish()
	print("SIP glyph test: fallbacks=%d atlas=%s sprites=%d" % [tl.fallback_count(), str(tl.atlas_size),
		tl.get_node("Bodies").get_child_count()])
	tl.queue_free()
	await get_tree().process_frame
	print("SIP DONE")
	get_tree().quit()


func _arg_val(prefix: String, dflt: String) -> String:
	for a in _args:
		if a.begins_with(prefix):
			return a.substr(prefix.length())
	return dflt


func _world() -> Node:
	return get_tree().root.get_node_or_null("World")


func _process(delta: float) -> void:
	if not persistent or _done:
		return
	var w := _world()
	if not _started:
		if w == null or w.get_node_or_null("Player") == null or w.get_node_or_null("CameraRig") == null:
			return
		_wait += delta
		if _wait < 1.5:
			return
		_start()
		return
	if _changed:
		_after_change(delta)
		return
	if _freed:
		_after_free(delta)
		return
	var s := PlanetSafari.current
	if s == null:
		return
	if _args.has("--sip-firstseen"):
		_first_seen_step(s)
	var now := Time.get_ticks_msec()
	if s.phase != _last_phase:
		print("SIP phase %d -> %d at %d ms (elapsed=%.3f)" % [_last_phase, s.phase, now - _req_ms, s.elapsed])
		_last_phase = s.phase
		if s.phase == PlanetSafari.Phase.FADE_IN and _fade_ms < 0:
			_fade_ms = now
		if s.phase == PlanetSafari.Phase.AWAKE and _awake_ms < 0:
			_awake_ms = now
			_t_awake = _t_lift
			_on_control(s)
	var fade_a := _fade_alpha(s)
	if fade_a >= 0.999:
		_seen_black = true
	# The lift: the old path's own fade dropping below 1, or the intro's own black (SafariIntro.black_alpha).
	var lifting := false
	if _seen_black and _lift_ms < 0:
		var intro := s.get_node_or_null("SafariIntro")
		if intro != null and intro.has_method("debug_state"):
			lifting = bool((intro.call("debug_state") as Dictionary).get("lifting", false))
		elif fade_a < 0.999:
			lifting = true
		if lifting:
			_lift_ms = now
			_t_lift = 0.0
			print("SIP lift at %d ms after fade start" % (now - _fade_ms))
			_player_pos0 = s.player.global_position
	if _lift_ms >= 0:
		if _t_awake < 0.0 or _t_lift < _t_awake + _after:
			_t_lift += delta if _last_t_was_set else 0.0
		_last_t_was_set = true
		_frame(s, delta)
	if _awake_ms >= 0 and _t_lift >= _t_awake + _after:
		_finish(s)


var _last_t_was_set := false
var _banner_was := false
var _banner_txt := ""
var _q_sent := false
var _twice_n := 0
var _prev_us := 0
var _tex_peak := 0.0
var _box_done := false
var _stalled := false
var _tex_marks: Array[float] = []
var _mask_env: Environment
## --sip-shot-times=1.4,1.5,... : frames at these times instead of every 0.4 s.
var _shot_times := PackedFloat32Array()


func _start() -> void:
	_started = true
	if _args.has("--sip-devmenu"):
		_devmenu_check()
		return
	if _args.has("--sip-glyph-test"):
		_glyph_test()
		return
	var pid := GameState.current_planet_id
	if _mode != "none":
		GameState.settings["safari_intro"] = _mode
	if _args.has("--sip-seen"):
		GameState.flags["safari_intro_seen_a"] = true
		GameState.flags["safari_intro_seen_b"] = true
		GameState.flags["safari_intro_seen_c"] = true
	if _args.has("--sip-hover"):
		GameState.flags["hover_learned"] = true
	GameState.flags.erase(PlanetSafari.FLAG_DAY_PREFIX + pid)
	_req_ms = Time.get_ticks_msec()
	print("SIP texmem before %.1f MB" % (Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0))
	print("SIP request_start planet=%s mode=%s settings=%s seen_a=%s seen_b=%s" % [pid, _mode,
		str(GameState.settings.get("safari_intro", "<unset>")), str(GameState.flags.get("safari_intro_seen_a", false)),
		str(GameState.flags.get("safari_intro_seen_b", false))])
	print("SIP modals before the outing starts: %s" % str(EventBus.open_modals()))
	var case_n := int(_arg_val("--sip-case=", "0"))
	if case_n > 0:
		var d := _break_case(case_n)
		Engine.set_meta("sip_case_data", d)
		print("SIP data case %d: %s" % [case_n, str(d).left(160)])
	var hosts := load("res://showcase/safari_intro_probe_hosts.gd")
	if _args.has("--planet=meteor"):
		var lvl: Node = hosts.ProbeMeteor.new()
		lvl.name = "MeteorSurvey"
		_world().add_child(lvl)
		print("SIP outing: meteor (probe host, stub data)")
	elif _args.has("--planet=cave"):
		var cv: Node = hosts.ProbeCave.new()
		cv.name = "CaveVisit"
		_world().add_child(cv)
		print("SIP outing: cave (probe host, stub data)")
	else:
		PlanetSafari.request_start(get_tree())


func _fade_alpha(s: PlanetSafari) -> float:
	if s.layer == null:
		return -1.0
	var r: Variant = s.layer.get("_fade")
	return (r as ColorRect).color.a if r is ColorRect else -1.0


func _frame(s: PlanetSafari, delta: float) -> void:
	var t := _t_lift
	var in_intro := _t_awake < 0.0
	var cam := get_viewport().get_camera_3d()
	if cam != null:
		var pos := cam.global_position
		var fwd := -cam.global_transform.basis.z
		if _have_prev:
			var dm := pos.distance_to(_prev_pos)
			var dd := rad_to_deg(_prev_fwd.angle_to(fwd))
			_jumps.append([t, dm, dd, str(cam.name), in_intro])
		_prev_pos = pos
		_prev_fwd = fwd
		_have_prev = true
		if _trace:
			print("SIP cam t=%.4f %s pos=(%.5f,%.5f,%.5f) fwd=(%.6f,%.6f,%.6f) fov=%.3f phase=%d el=%.3f" % [t,
				str(cam.name), pos.x, pos.y, pos.z, fwd.x, fwd.y, fwd.z, cam.fov, s.phase, s.elapsed])
	# A SYNTHETIC slow frame (the main thread sleeps 150 ms once at this intro time): the clock clamp's test.
	if _arg_val("--sip-stall-at=", "") != "" and in_intro and not _stalled and t >= float(_arg_val("--sip-stall-at=", "0")):
		_stalled = true
		print("SIP synthetic 150 ms stall at t=%.3f" % t)
		OS.delay_msec(150)
	if _args.has("--sip-pad") and cam != null:
		_pad_step(s, cam, t, in_intro)
	var now_us := Time.get_ticks_usec()
	var real_ms := float(now_us - _prev_us) / 1000.0 if _prev_us > 0 else delta * 1000.0
	_prev_us = now_us
	if real_ms > float(_arg_val("--sip-long-ms=", "50")):
		print("SIP LONG REAL FRAME t=%.3f %.1f ms (wall, ticks_usec)" % [t, real_ms])
	if delta > 0.05:
		print("SIP LONG FRAME t=%.3f %.1f ms in_intro=%s intro=%s" % [t, delta * 1000.0, str(in_intro),
			str(s.get_node("SafariIntro").call("debug_state")) if s.get_node_or_null("SafariIntro") else "-"])
	if _perf:
		var vp_rid := get_viewport().get_viewport_rid()
		RenderingServer.viewport_set_measure_render_time(vp_rid, true)
		var cpu := RenderingServer.viewport_get_measured_render_time_cpu(vp_rid) + RenderingServer.get_frame_setup_time_cpu()
		if in_intro and t > 0.2:
			_perf_intro.append(cpu)
			_delta_intro.append(real_ms)
		elif not in_intro and t > _t_awake + 1.0 and t < _t_awake + 5.5:
			_perf_normal.append(cpu)
			_delta_normal.append(real_ms)
	if not in_intro:
		var bn: Variant = s.layer.get("_banner")
		var vis := bn is Control and (bn as Control).visible
		var txt := str(s.layer.get("_banner_label").text) if vis else ""
		if vis != _banner_was or txt != _banner_txt:
			_banner_was = vis
			_banner_txt = txt
			if vis:
				print("SIP banner shows at elapsed=%.2f: %s" % [s.elapsed, txt])
		if _args.has("--sip-q-after") and not _q_sent and t >= _t_awake + 1.0:
			_q_sent = true
			_key(KEY_Q, true)
			_key(KEY_Q, false)
			print("SIP sent Q at elapsed=%.2f (raise the camera: the first-safari tip should come now)" % s.elapsed)
	if in_intro and (bool(s.get("tip_up")) or bool(s.get("_tip_pending"))):
		print("SIP !!! a tip card is up or pending DURING the intro at t=%.2f" % t)
	if in_intro:
		# Nothing of the safari's own UI may show or arm before control (the opening line is the banner).
		var ban: Variant = s.layer.get("_banner")
		if ban is Control and (ban as Control).visible:
			_banner_early = true
		var root := s.layer.get_node_or_null("Root") as Control
		if root != null and root.visible and root.modulate.a > 0.01 and t < 3.9:
			_ui_early = true
	for mark: float in [1.0, 2.5]:
		if _tex_marks.find(mark) < 0 and in_intro and t >= mark:
			_tex_marks.append(mark)
			print("SIP texmem intro t=%.1f %.1f MB" % [mark, Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0])
	if in_intro:
		_tex_peak = maxf(_tex_peak, Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0)
	if not in_intro and _tex_marks.find(-1.0) < 0 and t >= _t_awake + 1.0:
		_tex_marks.append(-1.0)
		print("SIP texmem after control+1s %.1f MB" % (Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0))
		print("SIP texmem intro peak %.1f MB" % _tex_peak)
	var intro0 := s.get_node_or_null("SafariIntro")
	if _args.has("--sip-helmet-log") and intro0 != null and in_intro:
		_helmet_log(intro0, t)
	if _args.has("--sip-clearance") and intro0 != null and in_intro:
		_clearance_step(intro0, t)
	if _arg_val("--sip-mockup=", "") != "" and intro0 != null and in_intro:
		_mockup_step(intro0, t)
	if _args.has("--sip-mask") and intro0 != null and in_intro:
		# DIAGNOSTIC ONLY: the intro lens draws the double alone on black, so its silhouette can be measured.
		var icam := intro0.get("_cam") as Camera3D
		if icam != null and is_instance_valid(icam):
			icam.cull_mask = SafariIntro.DOUBLE_BIT
			if _mask_env == null:
				_mask_env = Environment.new()
				_mask_env.background_mode = Environment.BG_COLOR
				_mask_env.background_color = Color.BLACK
				_mask_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
				_mask_env.ambient_light_color = Color(0.6, 0.6, 0.6)
			icam.environment = _mask_env
	# The visor dim, every frame of scene 2's push: the dome's share of the frame (SafariIntro._helmet_share; 0 for a
	# runner without it), the black's strength, and the dome's UNDIMMED share = share x (1 - black).
	if _args.has("--sip-dim-log") and intro0 != null and in_intro and t >= 6.5:
		var blk := intro0.get("_black") as ColorRect
		var ba := blk.color.a if blk != null else 0.0
		var sh: Variant = intro0.get("_helmet_share")
		var shv := float(sh) if sh != null else -1.0
		var dlv: Variant = intro0.get("_dl")
		print("SIP dim t=%.3f share=%.3f black=%.3f undimmed=%.3f hidden=%s light=%s" % [t, shv, ba, maxf(shv, 0.0) * (1.0 - ba),
			str(intro0.get("_double_hidden")), ("%.3f" % (dlv as OmniLight3D).light_energy) if dlv is OmniLight3D else "-"])
	# The title's box at its LARGEST (grown by TITLE_GROW), once at t = 1: the letter block and the planet backdrop
	# (its "size" meta), as shares of the card's width/height from each edge (negative = past the edge).
	if _args.has("--sip-title-box") and intro0 != null and in_intro and t >= 1.0 and not _box_done:
		_box_done = true
		var let := intro0.find_child("TitleLettering", true, false) as Node2D
		var root := intro0.get("_card_root") as Control
		if let != null and root != null:
			var vp: Vector2 = root.size
			var fit := float(intro0.get("_title_fit")) * (1.0 + SafariIntro.TITLE_GROW)
			var bs: Vector2 = let.get("block_size")
			var bk: Vector2 = let.get("_back_size")
			for item: Array in [["block", bs], ["backdrop", bk]]:
				var e: Vector2 = item[1]
				if e == Vector2.ZERO:
					continue
				var c: Vector2 = let.position
				print("SIP title box %s: top %.3f bottom %.3f left %.3f right %.3f (of the card %s; fit %.3f)" % [item[0],
					(c.y - e.y * fit * 0.5) / vp.y, (c.y + e.y * fit * 0.5) / vp.y, (c.x - e.x * fit * 0.5) / vp.x,
					1.0 - (c.x + e.x * fit * 0.5) / vp.x, str(vp), fit])
	if _args.has("--sip-title-log"):
		var dsx: Dictionary = intro0.call("debug_state") if intro0 != null else {}
		print("SIP title t=%.3f alpha=%.3f drawn=%s in_intro=%s" % [t, float(dsx.get("title_alpha", 0.0)),
			str(dsx.get("title_drawn", false)), str(in_intro)])
	# Draw calls with the title shown vs hidden on neighbouring frames (the 3D view barely moves in 3 frames).
	if _args.has("--sip-title-cost") and in_intro and intro0 != null:
		var let := intro0.find_child("TitleLettering", true, false) as CanvasItem
		var dc := int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		var ob := int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))
		if let != null and t > 0.9 and t < 1.4:
			var phase := int(t * 30.0) % 6
			print("SIP cost t=%.3f title_visible=%s draw_calls=%d objects=%d" % [t, str(let.visible), dc, ob])
			let.visible = phase < 3
	# Frames.
	if _shots_dir != "":
		if not _shot_times.is_empty():
			if in_intro and _shot_n < _shot_times.size() and t >= _shot_times[_shot_n] - 0.0001:
				_capture("c%02d_t%.3f" % [_shot_n, t])
				_shot_n += 1
		elif in_intro and t >= _next_shot - 0.0001:
			_capture("f%02d_t%.1f" % [_shot_n, _next_shot])
			_shot_n += 1
			_next_shot += 0.4
		elif not in_intro and not _after_shot_done and t >= _t_awake + 0.5:
			_after_shot_done = true
			_capture("f%02d_control_plus0.5" % _shot_n)
	# Synthetic input attack.
	if _input_attack and in_intro:
		Input.action_press("move_forward")
		if absf(t - 1.0) < delta * 0.6 or absf(t - 2.5) < delta * 0.6:
			_key(KEY_F, true)
			_key(KEY_F, false)
			_key(KEY_Q, true)
			_key(KEY_Q, false)
			MobileUI.synth_tap(s.layer.main_c)
			var rc := InputEventMouseButton.new()
			rc.button_index = MOUSE_BUTTON_RIGHT
			rc.pressed = true
			rc.position = s.layer.main_c
			Input.parse_input_event(rc)
			_attack_log.append("t=%.2f F/Q/tap(shutter)/right-click sent camera_up=%s photos=%d" % [t,
				str(s.camera_up), int(s.debug_state()["photos"])])
	# Skip / keep / tap.
	var intro := s.get_node_or_null("SafariIntro")
	var at := _skip_at if _skip_at >= 0.0 else _keep_at
	if at >= 0.0 and in_intro and intro != null:
		if _skip_stage == 0 and t >= at:
			var r: Rect2 = intro.call("debug_skip_rect")
			print("SIP skip button rect=%s visible=%s" % [str(r), str(r.size != Vector2.ZERO)])
			if _args.has("--sip-via-key"):
				_key(KEY_E, true)
				_key(KEY_E, false)
				print("SIP sent key E (instead of the button)")
			elif r.size != Vector2.ZERO:
				MobileUI.synth_tap(r.get_center())
				# A second tap on the same spot straight after: must not open a second pop-up.
				MobileUI.synth_tap(r.get_center())
			_skip_stage = 1
			_skip_tap_t = t
		elif _skip_stage == 1 and t >= _skip_tap_t + 0.7:
			var popups := _find_buttons(get_tree().root, "Skip", [])
			var layers := _count_named(get_tree().root, "SkipConfirmLayer")
			var want := "Skip" if _skip_at >= 0.0 else "Keep watching"
			var btns := _find_buttons(get_tree().root, want, [])
			print("SIP confirm layers=%d buttons(%s)=%d intro=%s" % [layers, want, btns.size(), str(intro.call("debug_state"))])
			if not btns.is_empty():
				MobileUI.synth_tap((btns[0] as Button).get_global_rect().get_center())
			_skip_stage = 2
			_skip_tap_t = t
			popups.clear()
		elif _skip_stage == 2 and t >= _skip_tap_t + 0.3:
			print("SIP after answer intro=%s" % (str(intro.call("debug_state")) if is_instance_valid(intro) else "<gone>"))
			_skip_stage = 3
	if _tap_at >= 0.0 and not _tap_done and in_intro and t >= _tap_at:
		_tap_done = true
		var vp := get_viewport().get_visible_rect().size
		MobileUI.synth_tap(vp * 0.5)
		print("SIP tapped the middle at t=%.2f; confirm layers=%d intro=%s" % [t, _count_named(get_tree().root,
			"SkipConfirmLayer"), str(intro.call("debug_state")) if intro != null else "-"])
	if _tap_done and in_intro and t >= _tap_at + 0.5 and _tap_at >= 0.0:
		print("SIP 0.5 s after the middle tap: confirm layers=%d" % _count_named(get_tree().root, "SkipConfirmLayer"))
		_tap_at = -1.0
	# Scene change / free mid-intro.
	if _change_at >= 0.0 and in_intro and t >= _change_at and not _changed:
		_changed = true
		print("SIP changing scene at t=%.2f intro=%s" % [t, str(intro.call("debug_state")) if intro != null else "-"])
		get_tree().change_scene_to_file("res://src/world/world.tscn")
	if _free_at >= 0.0 and in_intro and t >= _free_at and not _freed:
		_freed = true
		print("SIP freeing PlanetSafari at t=%.2f" % t)
		s.queue_free()


## Option A's double: lens-to-dome distance, FOV, the dome's world scale (root squash), the neck's rotation, the
## dome centre on screen and its analytic projected radius (vertical px) - one line a frame.
func _helmet_log(intro: Node, t: float) -> void:
	var dbl := intro.get("_double") as Node3D
	var cam := get_viewport().get_camera_3d()
	if dbl == null or not is_instance_valid(dbl) or cam == null:
		return
	var helm := dbl.find_child("Helmet", true, false) as Node3D
	var neck := dbl.find_child("Neck", true, false) as Node3D
	if helm == null:
		return
	var c := helm.global_position
	var d := cam.global_position.distance_to(c)
	var b := helm.global_transform.basis
	var sx := b.x.length()
	var sy := b.y.length()
	var r_world := AstronautModel.HELMET_R.y * AstronautModel.HELMET_SCALE * sy
	var vp_h := get_viewport().get_visible_rect().size.y * get_tree().root.get_final_transform().get_scale().y
	var focal := (vp_h * 0.5) / tan(deg_to_rad(cam.fov) * 0.5)
	var r_px := focal * r_world / sqrt(maxf(d * d - r_world * r_world, 1e-6))
	var sp := cam.unproject_position(c) * get_tree().root.get_final_transform().get_scale().y
	var behind := cam.is_position_behind(c)
	print("SIP helm t=%.4f d=%.4f fov=%.2f sx=%.4f sy=%.4f r_world=%.4f r_px=%.1f rpx_x_d=%.2f neck=(%.3f,%.3f,%.3f) scr=(%.0f,%.0f) behind=%s state=%s" % [
		t, d, cam.fov, sx, sy, r_world, r_px, r_px * d, neck.rotation.x if neck else 0.0, neck.rotation.y if neck else 0.0,
		neck.rotation.z if neck else 0.0, sp.x, sp.y, str(behind), str((dbl as AstronautModel).get_state())])


## STILLS for the title choice: at --sip-mockup-at the live title is swapped for TitleMockups' M1/M2/M3; from
## --sip-mockup-faint-at it is drawn at strength 0.3.
var _mock: CanvasGroup
func _mockup_step(intro: Node, t: float) -> void:
	var at := float(_arg_val("--sip-mockup-at=", "1.5"))
	var faint := float(_arg_val("--sip-mockup-faint-at=", "99"))
	if _mock == null and t >= at:
		var let := intro.get("_lettering") as Node
		if let != null:
			let.queue_free()
			intro.set("_lettering", null)
		var sub := intro.get("_sub") as Control
		if sub != null:
			sub.visible = false
		var lines := PackedStringArray(["ZORP'S VIOLET", "HOLLOW"])
		match _arg_val("--sip-mockup=", "M1"):
			"M1": _mock = TitleMockups.crest(lines, "The Glowing Garden")
			"M2": _mock = TitleMockups.mushroom_t(lines, "The Glowing Garden")
			_: _mock = TitleMockups.plaque(lines, "The Glowing Garden")
		var root := intro.get("_card_root") as Control
		root.add_child(_mock)
		root.move_child(_mock, 1)
		var vp := root.size
		var bs: Vector2 = _mock.get_meta("block_size")
		var k := minf(vp.x * 0.74 / bs.x, vp.y * 0.56 / bs.y)
		_mock.scale = Vector2.ONE * k
		_mock.position = Vector2(vp.x * 0.5, vp.y * SafariIntro.C_TITLE_CENTER_Y)
		print("SIP mockup %s scale %.3f block %s on %s" % [_arg_val("--sip-mockup=", ""), k, str(bs * k), str(vp)])
	if _mock != null and t >= faint:
		_mock.self_modulate.a = 0.3


## DIAGNOSTIC: the first moment (ms since the intro node appeared) each mesh in the world enters the current
## camera's frustum (AABB vs the six planes) on a layer that camera draws - warm-up frames included. Printed at the
## end for everything first seen after the lift.
var _fs_list: Array = []
var _fs_first: Dictionary = {}
var _fs_t0 := -1
func _first_seen_step(s: PlanetSafari) -> void:
	var intro := s.get_node_or_null("SafariIntro")
	if intro == null and _fs_t0 < 0:
		return
	if _fs_t0 < 0:
		_fs_t0 = Time.get_ticks_msec()
		for g in _world().find_children("*", "GeometryInstance3D", true, false):
			_fs_list.append(g)
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var planes := cam.get_frustum()
	var tms := Time.get_ticks_msec() - _fs_t0
	for gv in _fs_list:
		if not is_instance_valid(gv):
			continue
		var g := gv as GeometryInstance3D
		if _fs_first.has(g.get_instance_id()):
			continue
		if not g.is_visible_in_tree() or (g.layers & cam.cull_mask) == 0:
			continue
		var box := g.global_transform * g.get_aabb()
		var inside := true
		for pl: Plane in planes:
			var out := true
			for i in 8:
				if not pl.is_point_over(box.get_endpoint(i)):
					out = false
					break
			if out:
				inside = false
				break
		if inside:
			_fs_first[g.get_instance_id()] = [tms, str(g.get_path()), g.get_class(),
				str((g as MeshInstance3D).mesh.resource_name if g is MeshInstance3D and (g as MeshInstance3D).mesh else ""),
				str(g.material_override.resource_path if g.material_override else "-")]


func _first_seen_report() -> void:
	var rows: Array = _fs_first.values()
	rows.sort_custom(func(a: Array, b: Array) -> bool: return int(a[0]) < int(b[0]))
	var lift_ms := (_lift_ms - _fs_t0) if _lift_ms >= 0 else 0
	print("SIP firstseen: %d meshes tracked, %d ever in view, lift at %d ms" % [_fs_list.size(), rows.size(), lift_ms])
	for r: Array in rows:
		if int(r[0]) > lift_ms:
			print("SIP firstseen t=%.3f %s %s mesh=%s mat=%s" % [float(int(r[0]) - lift_ms) / 1000.0, r[1], r[2], r[3], r[4]])


## THE DATA-VALIDATION CASES (the critic's list, and more): each must end in today's start with ZERO script errors.
## 1-16 broken data; 17-19 title files returning the wrong thing; 20 a local_path point underground (raised, plays).
func _break_case(n: int) -> Dictionary:
	var hosts := load("res://showcase/safari_intro_probe_hosts.gd")
	var d: Dictionary = (hosts.STUB_METEOR as Dictionary).duplicate(true)
	var sc: Dictionary = d["scene1"]
	match n:
		1: d["scene1"] = {}
		2: d["scene1"] = "x"
		3: d["scene1"] = {"path": [], "height": Vector2(1, 1)}
		4: d["scene1"] = {"path": [Vector2(10, 0)], "height": Vector2(1, 1)}
		5: d["scene1"] = {"path": [Vector3(1, 2, 3), Vector3(2, 3, 4)], "height": Vector2(1, 1)}
		6: d["scene1"] = {"path": [Vector2(10, 0), Vector2(20, 0)]}
		7: d["scene1"] = {"path": [Vector2(10, 0), Vector2(20, 0)], "height": 1.5}
		8: sc["local_path"] = [Vector3(1, 1, 1)]
		9: d["swoop"] = {"r": [Vector3(0, 1, 0)]}
		10: d["swoop"] = {"phi": "abc"}
		11: d["total"] = "abc"
		12: d["cut"] = []
		13: d["title_style"] = "red"
		14: d["title_lines"] = 5
		15: sc["look_from"] = Vector2(1, 2)
		16: d["double_light"] = 3
		17: d["title_style"] = {"title_file": "res://showcase/safari_intro_badtitle.gd"}
		18: d["title_style"] = {"title_file": "res://showcase/no_such_title.gd"}
		19: d["title_style"] = {"title_file": "res://showcase/safari_intro_badtitle2.gd"}
		20: sc["local_path"] = [Vector3(6.0, -3.0, 2.0), Vector3(3.0, 3.0, 5.5)]
		21: d["subtitle"] = ""
		22: sc["local_spores_at"] = Vector2(1, 2)
	return d


## Item 1 (the cave builder): where the double starts relative to the real start, and the lens's clearance - a ray
## from the double's helmet to the lens; a hit before the lens = the lens is behind rock (negative clearance).
var _clr_min := INF
var _clr_logged := false
func _clearance_step(intro: Node, t: float) -> void:
	var dbl := intro.get("_double") as Node3D
	var cam := get_viewport().get_camera_3d()
	if dbl == null or not is_instance_valid(dbl) or cam == null or not dbl.visible:
		return
	var s := PlanetSafari.current
	if not _clr_logged:
		_clr_logged = true
		var d := dbl.global_position.distance_to(s.player.global_position)
		var along := (dbl.global_position - s.player.global_position).dot(s.start_fwd.normalized())
		print("SIP double at scene-2 start: %.3f m from the real start, %.3f m along the heading (negative = behind)" % [d, along])
	var helm := dbl.global_position + s.planet.up_at(dbl.global_position) * AstronautModel.HELMET_CY
	var space := get_viewport().world_3d.direct_space_state
	var q := PhysicsRayQueryParameters3D.create(helm, cam.global_position)
	q.exclude = [s.player.get_rid()]
	var hit := space.intersect_ray(q)
	var lens_d := helm.distance_to(cam.global_position)
	var clr := lens_d if hit.is_empty() else (helm.distance_to(hit["position"]) - lens_d)
	if hit.is_empty():
		clr = 9.9
	_clr_min = minf(_clr_min, clr)
	if not hit.is_empty():
		print("SIP lens BLOCKED t=%.2f: rock %.2f m from the helmet, lens at %.2f m" % [t, helm.distance_to(hit["position"]), lens_d])


func _key(code: Key, pressed: bool) -> void:
	var k := InputEventKey.new()
	k.physical_keycode = code
	k.keycode = code
	k.pressed = pressed
	Input.parse_input_event(k)


func _on_control(s: PlanetSafari) -> void:
	if _input_attack:
		Input.action_release("move_forward")
	var lift_to_ctrl := float(_awake_ms - _lift_ms) / 1000.0 if _lift_ms >= 0 else -1.0
	print("SIP CONTROL fade_start->control=%.3f s (wall)  lift->control=%.3f s (wall)  lift->control=%.3f s (frames)  request->fade=%d ms" % [
		float(_awake_ms - _fade_ms) / 1000.0, lift_to_ctrl, _t_lift, _fade_ms - _req_ms])
	var cam := get_viewport().get_camera_3d()
	var rig := s.rig
	var p := s.player
	print("SIP STATE at control: cam=%s rig_cam_current=%s fp=%s pitch=%.2f fov=%.2f move_locked=%s input_enabled=%s modal=%s names=%s photo_mode=%s ui_visible=%s ui_alpha=%.2f carry=%s player_moved=%.4f m camera_up=%s photos=%d skip_open=%s" % [
		str(cam.name) if cam else "-", str(rig.get_view_camera().current), str(rig.is_first_person()),
		rig.get_view_pitch_deg(), rig.get_fov_deg(), str(p.is_move_locked()), str(p.input_enabled),
		str(EventBus.is_modal_open()), str(EventBus.open_modals()), str(PhotoMode.active),
		str((s.layer.get_node("Root") as Control).visible), (s.layer.get_node("Root") as Control).modulate.a,
		str(p.get_model().is_carrying()), p.global_position.distance_to(_player_pos0), str(s.camera_up),
		int(s.debug_state()["photos"]), str(SkipConfirm.is_open())])
	print("SIP early-UI: banner_during_intro=%s ui_visible_before_3.9s=%s" % [str(_banner_early), str(_ui_early)])
	for line in _attack_log:
		print("SIP attack " + str(line))
	if _args.has("--sip-layout"):
		var props := s.planet.get_node_or_null("Props")
		if props != null:
			for c in props.get_children():
				if c is Node3D:
					var d := s.planet.dir_of((c as Node3D).global_position)
					var around := rad_to_deg(d.angle_to(s.start_dir))
					var tan := (d - s.start_dir * d.dot(s.start_dir))
					var bearing := 0.0
					if tan.length() > 1e-5:
						bearing = rad_to_deg(s.start_fwd.signed_angle_to(tan.normalized(), -s.start_dir))
					var aabb := _aabb_of(c as Node3D)
					print("SIP prop %s around=%.1f bearing=%.1f size=%s" % [c.name, around, bearing, str(aabb.size.snapped(Vector3.ONE * 0.1))])
	print("SIP title nodes at control=%d" % _count_named(get_tree().root, "TitleLettering"))
	var cams := _count_cameras(get_tree().root)
	print("SIP cameras current=%d total=%d intro_node=%s" % [cams.x, cams.y, str(s.get_node_or_null("SafariIntro") != null)])


func _finish(s: PlanetSafari) -> void:
	var runs := int(_arg_val("--sip-runs=", "2"))
	if _args.has("--sip-twice") and _twice_n < runs - 1:
		_twice_n += 1
		_report_mem("after safari %d control+%.0fs" % [_twice_n, _after])
		s.queue_free()
		await get_tree().create_timer(1.0).timeout
		_report_mem("safari %d freed" % _twice_n)
		GameState.flags.erase(PlanetSafari.FLAG_DAY_PREFIX + GameState.current_planet_id)
		_last_phase = -1
		_fade_ms = -1
		_lift_ms = -1
		_awake_ms = -1
		_seen_black = false
		_t_lift = -1.0
		_t_awake = -1.0
		_last_t_was_set = false
		_have_prev = false
		_jumps.clear()
		_req_ms = Time.get_ticks_msec()
		PlanetSafari.request_start(get_tree())
		return
	if _args.has("--sip-twice"):
		_report_mem("after safari %d control+%.0fs" % [_twice_n + 1, _after])
	_done = true
	# The hand-back window: the last 1.0 s of the intro and 0.3 s after.
	var max_m := 0.0
	var max_d := 0.0
	var max_m_t := 0.0
	var max_d_t := 0.0
	var all_m := 0.0
	var all_d := 0.0
	for j: Array in _jumps:
		var t: float = j[0]
		if t >= _t_awake - 1.0 and t <= _t_awake + 0.3:
			if float(j[1]) > max_m:
				max_m = j[1]
				max_m_t = t
			if float(j[2]) > max_d:
				max_d = j[2]
				max_d_t = t
		if bool(j[4]):
			all_m = maxf(all_m, j[1])
			all_d = maxf(all_d, j[2])
	print("SIP HANDBACK largest single-frame step in [control-1.0, control+0.3]: %.4f m (t=%.3f), %.3f deg (t=%.3f); whole intro max %.4f m, %.3f deg" % [
		max_m, max_m_t, max_d, max_d_t, all_m, all_d])
	# The frames right around control.
	for j: Array in _jumps:
		var t: float = j[0]
		if t >= _t_awake - 0.25 and t <= _t_awake + 0.15:
			print("SIP step t=%.3f %.4f m %.3f deg cam=%s" % [t, j[1], j[2], j[3]])
	if _perf:
		print("SIP PERF cpu_ms intro %s | normal %s" % [_stats(_perf_intro), _stats(_perf_normal)])
		print("SIP PERF frame_ms intro %s | normal %s" % [_stats(_delta_intro), _stats(_delta_normal)])
	if _args.has("--sip-firstseen"):
		_first_seen_report()
	if _args.has("--sip-clearance"):
		print("SIP clearance min over scene 2: %s" % ("clear (no rock between helmet and lens)" if _clr_min >= 9.0 else "%.2f m" % _clr_min))
	if _args.has("--sip-pad"):
		_pad_report()
	print("SIP modals at the end: %s" % str(EventBus.open_modals()))
	print("SIP DONE")
	get_tree().quit()


func _report_mem(tag: String) -> void:
	print("SIP MEM %s: texmem=%.2f MB nodes=%d objects=%d subviewports=%d intro_nodes=%d title_nodes=%d" % [tag,
		Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0,
		int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), int(Performance.get_monitor(Performance.OBJECT_COUNT)),
		_count_class(get_tree().root, "SubViewport"), _count_named(get_tree().root, "SafariIntro"),
		_count_named(get_tree().root, "TitleLettering")])


func _count_class(n: Node, cls: String) -> int:
	var k := 0
	for c in n.get_children():
		if c.is_class(cls):
			k += 1
		k += _count_class(c, cls)
	return k


func _stats(a: PackedFloat64Array) -> String:
	if a.is_empty():
		return "n=0"
	var b := a.duplicate()
	b.sort()
	var sum := 0.0
	for v in b:
		sum += v
	return "n=%d mean=%.2f median=%.2f p90=%.2f max=%.2f min=%.2f" % [b.size(), sum / b.size(), b[b.size() / 2],
		b[int(b.size() * 0.9)], b[b.size() - 1], b[0]]


func _after_change(delta: float) -> void:
	_change_report_t += delta if _change_report_t >= 0.0 else 0.0
	if _change_report_t < 0.0:
		_change_report_t = 0.0
		return
	if _change_report_t < 3.0:
		return
	_report_world_state("after scene change")
	_done = true
	get_tree().quit()


func _after_free(delta: float) -> void:
	_free_report_t += delta if _free_report_t >= 0.0 else 0.0
	if _free_report_t < 0.0:
		_free_report_t = 0.0
		return
	if _free_report_t < 1.0:
		return
	_report_world_state("after freeing PlanetSafari")
	_done = true
	get_tree().quit()


func _report_world_state(tag: String) -> void:
	var w := _world()
	var p := w.get_node_or_null("Player") as Player if w else null
	var rig := w.get_node_or_null("CameraRig") as CameraRig if w else null
	var cam := get_viewport().get_camera_3d()
	var cams := _count_cameras(get_tree().root)
	var hidden := -1
	if p != null:
		hidden = 0
		for gi in _geoms(p, []):
			if ((gi as GeometryInstance3D).layers & CameraRig.FP_HIDDEN_BIT) != 0:
				hidden += 1
	print("SIP %s: safari=%s intro_nodes=%d cam=%s rig_cam_current=%s cameras current=%d total=%d fp=%s move_locked=%s input_enabled=%s modal=%s names=%s photo_mode=%s carry=%s fp_hidden_geoms=%d skip_open=%s zorp_phys=%s" % [
		tag, str(PlanetSafari.current != null), _count_named(get_tree().root, "SafariIntro"),
		str(cam.get_path()) if cam else "-", str(rig.get_view_camera().current) if rig else "-", cams.x, cams.y,
		str(rig.is_first_person()) if rig else "-", str(p.is_move_locked()) if p else "-",
		str(p.input_enabled) if p else "-", str(EventBus.is_modal_open()), str(EventBus.open_modals()),
		str(PhotoMode.active), str(p.get_model().is_carrying()) if p else "-", hidden, str(SkipConfirm.is_open()),
		str((w.get_node_or_null("NPCs/zorp") as Node).is_physics_processing()) if w and w.get_node_or_null("NPCs/zorp") else "-"])


func _aabb_of(n: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for g in _geoms(n, []):
		var gi := g as GeometryInstance3D
		var b := gi.global_transform * gi.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box


func _geoms(n: Node, out: Array) -> Array:
	for c in n.get_children():
		if c is GeometryInstance3D:
			out.append(c)
		_geoms(c, out)
	return out


func _count_cameras(n: Node) -> Vector2i:
	var cur := 0
	var tot := 0
	for c in n.get_children():
		if c is Camera3D:
			tot += 1
			if (c as Camera3D).current:
				cur += 1
		var sub := _count_cameras(c)
		cur += sub.x
		tot += sub.y
	return Vector2i(cur, tot)


func _count_named(n: Node, nm: String) -> int:
	var k := 0
	for c in n.get_children():
		if str(c.name) == nm:
			k += 1
		k += _count_named(c, nm)
	return k


func _find_buttons(n: Node, text: String, out: Array) -> Array:
	for c in n.get_children():
		if c is Button and (c as Button).text == text and (c as Button).is_visible_in_tree():
			out.append(c)
		_find_buttons(c, text, out)
	return out


func _capture(name_: String) -> void:
	var img := get_viewport().get_texture().get_image()
	var path := _shots_dir.path_join(name_ + ".png")
	img.save_png(path)
	print("SIP shot %s %dx%d" % [path, img.get_width(), img.get_height()])


# ---------------------------------------------------------------------------------------------- --sip-pad
## THE PAD FIXTURES in the intro's view (scene 2): each fixture's sample points (foot, middle, top of a post) in
## the start frame once, then every scene-2 frame whether any is inside the current camera's frustum and how far
## inside the frame's edge (0 = the edge, 0.5 = the centre). Report: the scene-2 seconds each is on screen.
const PAD_FIX := {"ControlPost": [0.0, 0.6, 1.2], "Post-1": [-1.4, 0.0, 1.4], "Post1": [-1.4, 0.0, 1.4],
	"FuelHose": [0.0], "BeaconMast": [0.0, 1.5, 3.0], "Rocket": [0.0, 1.5, 3.0]}
var _pad_nodes := {}
var _pad_on := {}
var _pad_logged := false
var _pad_last_hidden := {}
var _pad_restore_logged := false

## Drawn by no camera (SafariIntro hides a fixture with layers = 0).
func _pad_hidden(n: Node3D) -> bool:
	var parts: Array[Node] = [n]
	parts.append_array(n.find_children("*", "GeometryInstance3D", true, false))
	for g: Node in parts:
		if g is GeometryInstance3D and (g as GeometryInstance3D).layers != 0:
			return false
	return true

func _pad_points(n: Node3D, key: String) -> PackedVector3Array:
	var out := PackedVector3Array()
	for h: float in PAD_FIX[key]:
		out.append(n.global_transform * Vector3(0.0, h, 0.0) if key != "ControlPost" and key != "BeaconMast" and key != "Rocket" else n.global_position + n.global_transform.basis.y.normalized() * h)
	return out

func _pad_step(s: Node, cam: Camera3D, t: float, in_intro: bool) -> void:
	if _pad_nodes.is_empty():
		for key: String in PAD_FIX:
			var n := get_tree().root.find_child(key, true, false) as Node3D
			if n != null:
				_pad_nodes[key] = n
				_pad_on[key] = []
	if not in_intro:
		# The first first-person frames after control: is a fixture in view (it must not have been hidden then).
		if not _pad_restore_logged:
			_pad_restore_logged = true
			var still: Array = []
			for key: String in _pad_nodes:
				if _pad_hidden(_pad_nodes[key] as Node3D) and key != "Rocket":
					still.append(key)
			print("SIP pad after control: still hidden %s (layers/shadow restored on the rest)" % str(still))
		if t < _t_awake + 0.2:
			for key: String in _pad_nodes:
				for q in _pad_points(_pad_nodes[key] as Node3D, key):
					if not cam.is_position_behind(q) and cam.is_position_in_frustum(q):
						print("SIP pad %s IN the first-person view at control+%.2f (hidden on the intro's last frame: %s)" % [
							key, t - _t_awake, str(_pad_last_hidden.get(key, false))])
						break
		return
	for key: String in _pad_nodes:
		_pad_last_hidden[key] = _pad_hidden(_pad_nodes[key] as Node3D)
	if t < 3.9:
		return
	var sxf: Transform3D = (s.get("player") as Node3D).global_transform
	if not _pad_logged:
		_pad_logged = true
		var sf: Vector3 = s.get("start_fwd")
		var sd: Vector3 = s.get("start_dir")
		print("SIP pad frame check: start_fwd . -basis.z = %.3f, start_fwd . basis.x = %.3f, start_dir . basis.y = %.3f" % [
			sf.dot(-sxf.basis.z.normalized()), sf.dot(sxf.basis.x.normalized()), sd.dot(sxf.basis.y.normalized())])
		# The HEADING frame (start_fwd, start_dir): the player's body basis is not aligned with the heading (above).
		var up := sd.normalized()
		var fw := (sf - up * sf.dot(up)).normalized()
		var rt := fw.cross(up)
		for key: String in _pad_nodes:
			var dv: Vector3 = (_pad_nodes[key] as Node3D).global_position - sxf.origin
			print("SIP pad %s at the start, heading frame (x right, y up, z back) (%.2f, %.2f, %.2f)" % [key, dv.dot(rt),
				dv.dot(up), -dv.dot(fw)])
	var vp := get_viewport().get_visible_rect().size
	for key: String in _pad_nodes:
		var n := _pad_nodes[key] as Node3D
		var inside := -1.0
		for q in _pad_points(n, key):
			if cam.is_position_behind(q) or not cam.is_position_in_frustum(q):
				continue
			var sp := cam.unproject_position(q)
			inside = maxf(inside, minf(minf(sp.x, vp.x - sp.x) / vp.x, minf(sp.y, vp.y - sp.y) / vp.y))
		if inside >= 0.0 and not _pad_hidden(n):
			(_pad_on[key] as Array).append([t, inside])

func _pad_report() -> void:
	for key: String in _pad_on:
		var arr: Array = _pad_on[key]
		if arr.is_empty():
			print("SIP pad %s: never seen in scene 2 (out of view or hidden)" % key)
			continue
		var deepest := 0.0
		for e: Array in arr:
			deepest = maxf(deepest, float(e[1]))
		print("SIP pad %s: in view %d frames, t=%.2f..%.2f, deepest %.2f of the frame in from the edge" % [key,
			arr.size(), float(arr[0][0]), float(arr[arr.size() - 1][0]), deepest])
