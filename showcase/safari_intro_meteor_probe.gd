extends "res://showcase/safari_intro_probe.gd"
## THE REAL METEOR SURVEY under SafariIntroProbe (builder JUNGLE+METEOR intro, 2026-10-20). A test harness: inert
## unless `--sip` is passed. The base probe runs the meteor through a STUB host (safari_intro_probe_hosts.gd ProbeMeteor,
## a copy of `_start` with stub data); this runs the REAL MeteorSurveyLevel - its own `_start` with the one hook line and
## its own `intro_data()` - on the Commons (the hub, where the finale really starts the survey; `--mp-home` for the home
## world), and adds the survey's own checks:
##   * at control: the survey's clock (`survey_t`, the HUD clock text), attempt, the HUD shown, the phase;
##   * the hub: every Node3D child of /root/World (visible, process_mode) snapshotted before the survey and compared
##     after a mid-intro free (`--sip-free-at`) or a scene change (`--sip-change-at`);
##   * the double's walk: its feet at scene 2's first frame vs its last walking frame, along the rock (arc metres),
##     against the commanded `walk_m`;
##   * `--mp-retry-at=S`: S seconds after control, forces the out-of-time retry (survey_t = TIME_LIMIT) and logs whether
##     a SafariIntro node appears during the retry (it must not) and the retry's lift-to-control.
## Same arguments as the base probe; run it with --planet=meteor.

var _hub_before: Dictionary = {}
var _dbl_first := Vector3.INF
var _dbl_last := Vector3.INF
var _walk_m := -1.0
var _retry_at := -1.0
var _retry_sent := false
var _retry_intro_seen := false
var _retry_t0 := -1
var _retry_logged := false


func _ready() -> void:
	_args = OS.get_cmdline_user_args()
	if not _args.has("--sip"):
		return
	if not persistent:
		if _args.has("--planet=meteor"):
			GameState.current_planet_id = "home" if _args.has("--mp-home") else "hub"
		var p: Node = load("res://showcase/safari_intro_meteor_probe.gd").new()
		p.persistent = true
		p.name = "SafariIntroProbe"
		get_tree().root.add_child.call_deferred(p)
		get_tree().change_scene_to_file.call_deferred("res://src/world/world.tscn")
		return
	super._ready()
	_retry_at = float(_arg_val("--mp-retry-at=", "-1"))


func _start() -> void:
	if not _args.has("--planet=meteor"):
		super._start()
		return
	_started = true
	if _mode != "none":
		GameState.settings["safari_intro"] = _mode
	if _args.has("--sip-seen"):
		GameState.flags["safari_intro_seen_a"] = true
		GameState.flags["safari_intro_seen_b"] = true
		GameState.flags["safari_intro_seen_c"] = true
	_req_ms = Time.get_ticks_msec()
	_hub_before = _hub_snapshot()
	print("SIP texmem before %.1f MB" % (Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0))
	print("MP world=%s hub Node3D children=%d settings=%s seen_c=%s modals=%s" % [GameState.current_planet_id,
		_hub_before.size(), str(GameState.settings.get("safari_intro", "<unset>")),
		str(GameState.flags.get("safari_intro_seen_c", false)), str(EventBus.open_modals())])
	var lvl := MeteorSurveyLevel.new()
	lvl.name = "MeteorSurvey"
	_world().add_child(lvl)
	print("SIP outing: meteor (the REAL MeteorSurveyLevel)")


## --mp-cull-diag: every frame the intro's lens is current (warm-up included), the render instances inside its frustum
## (RenderingServer.instances_cull_convex); each instance's first frame is kept, and at control the ones first seen
## inside [--mp-cull-from, --mp-cull-to] of the intro clock are printed - what a stall there drew for the first time.
var _cull_seen: Dictionary = {}
var _cull_log: Array = []


func _cull_step() -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null or str(cam.name) != "IntroCamera":
		return
	var intro := cam.get_parent()
	var t := float(intro.get("_t")) if bool(intro.get("_running")) else -1.0
	var ids := RenderingServer.instances_cull_convex(cam.get_frustum(), get_viewport().world_3d.scenario)
	for id in ids:
		if _cull_seen.has(id):
			continue
		_cull_seen[id] = t
		var obj := instance_from_id(id)
		var desc := "?"
		if obj is Node:
			var n := obj as Node
			desc = str(n.get_path()).right(90)
			if n is GeometryInstance3D:
				var g := n as GeometryInstance3D
				var mat: Material = g.material_override
				if mat == null and n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
					mat = (n as MeshInstance3D).mesh.surface_get_material(0)
				desc += " mat=%s" % (mat.resource_path if mat != null and mat.resource_path != "" else (mat.get_class() if mat else "-"))
				if mat is ShaderMaterial and (mat as ShaderMaterial).shader != null:
					desc += " shader=%s" % (mat as ShaderMaterial).shader.resource_path
		_cull_log.append([t, desc])


func _process(delta: float) -> void:
	if _args.has("--mp-cull-diag") and persistent and _started:
		_cull_step()
		if _t_awake >= 0.0 and not _cull_log.is_empty():
			var a := float(_arg_val("--mp-cull-from=", "0.2"))
			var b := float(_arg_val("--mp-cull-to=", "0.7"))
			var warm := 0
			for e: Array in _cull_log:
				if float(e[0]) < 0.0:
					warm += 1
			print("MP CULL %d instances first seen in warm-up/black, %d in all" % [warm, _cull_log.size()])
			for e: Array in _cull_log:
				if float(e[0]) >= a and float(e[0]) <= b:
					print("MP CULL first t=%.3f %s" % [float(e[0]), str(e[1])])
			_cull_log.clear()
	super._process(delta)
	if not persistent or not _started:
		return
	var s := PlanetSafari.current
	if s == null or not is_instance_valid(s):
		return
	var intro := s.get_node_or_null("SafariIntro")
	if intro != null:
		var dbl := intro.get("_double") as Node3D
		var path: Object = intro.get("_path")
		if path != null:
			_walk_m = float(path.get("walk_m"))
		if dbl != null and is_instance_valid(dbl) and dbl.visible and not bool(intro.get("_double_hidden")):
			var t := float(intro.get("_t"))
			if t >= float(intro.get("_c_cut")) and t <= float(intro.get("_c_cut")) + float(path.get("walk_stop")) + 0.05:
				if _dbl_first == Vector3.INF:
					_dbl_first = dbl.global_position
				_dbl_last = dbl.global_position
	# The forced retry: no SafariIntro may appear from here on.
	if _retry_at >= 0.0 and _t_awake >= 0.0 and not _retry_sent and _t_lift >= _t_awake + _retry_at:
		_retry_sent = true
		_retry_t0 = Time.get_ticks_msec()
		s.set("survey_t", MeteorSurveyLevel.TIME_LIMIT)
		print("MP forcing the out-of-time retry at control+%.1f s" % _retry_at)
	if _retry_sent and not _retry_logged:
		if intro != null:
			_retry_intro_seen = true
		var st: Dictionary = s.call("survey_state")
		if bool(st.get("retry_card", false)):
			# The card is up: press its button the way a finger would (synthesised tap at the button's centre).
			var hud: Node = s.get("hud")
			var b := hud.get("_card_button") as Button
			if b != null and b.is_visible_in_tree():
				MobileUI.synth_tap(b.get_global_rect().get_center())
		if int(st["attempt"]) == 2 and int(st["phase"]) == PlanetSafari.Phase.AWAKE:
			_retry_logged = true
			print("MP RETRY attempt=2 awake after %d ms from the forced timeout; intro_node_seen_during_retry=%s survey_t=%.3f clock=%s" % [
				Time.get_ticks_msec() - _retry_t0, str(_retry_intro_seen), float(st["survey_t"]), _clock_text(s)])


func _on_control(s: PlanetSafari) -> void:
	super._on_control(s)
	if not (s is MeteorSurveyLevel):
		return
	var st: Dictionary = s.call("survey_state")
	var hud: Node = s.get("hud")
	var root := hud.get("_root") as Control
	print("MP AT CONTROL survey_t=%.4f elapsed=%.4f attempt=%d phase=%d clock=%s hud_visible=%s marked=%d film=%d" % [
		float(st["survey_t"]), s.elapsed, int(st["attempt"]), int(st["phase"]), _clock_text(s), str(root.visible),
		int(st["marked"]), int(st["film_left"])])
	# The hub at control: during the survey every listed node is hidden and disabled by the level (whatever the intro
	# did, a skip included); printed as one line so an intro run, a skipped run and an "off" run can be compared.
	var now := _hub_snapshot()
	var keys := now.keys()
	keys.sort()
	var parts: Array = []
	for k: String in keys:
		parts.append("%s=%s/%d" % [k, "v" if bool(now[k][0]) else "h", int(now[k][1])])
	print("MP HUB AT CONTROL %d nodes: %s" % [keys.size(), ", ".join(PackedStringArray(parts))])
	if _dbl_first != Vector3.INF:
		var c := s.planet.global_position
		var ang := (_dbl_first - c).angle_to(_dbl_last - c)
		var r := ((_dbl_first - c).length() + (_dbl_last - c).length()) * 0.5
		print("MP DOUBLE walk: commanded %.3f m, measured %.3f m along the rock (chord %.3f m, at radius %.2f m)" % [
			_walk_m, ang * r, _dbl_first.distance_to(_dbl_last), r])


func _clock_text(s: Node) -> String:
	var hud: Node = s.get("hud")
	var l := hud.get("_clock") as Label
	return l.text if l != null else "-"


func _report_world_state(tag: String) -> void:
	super._report_world_state(tag)
	var now := _hub_snapshot()
	var diffs: Array = []
	for k: String in _hub_before:
		if not now.has(k):
			diffs.append("%s missing" % k)
		elif str(now[k]) != str(_hub_before[k]):
			diffs.append("%s %s -> %s" % [k, str(_hub_before[k]), str(now[k])])
	print("MP HUB %s: %d Node3D children before, %d now, %d differ %s" % [tag, _hub_before.size(), now.size(),
		diffs.size(), str(diffs.slice(0, 8))])


func _hub_snapshot() -> Dictionary:
	var out := {}
	var w := _world()
	if w == null:
		return out
	for c: Node in w.get_children():
		if c is Node3D and not (c is PlanetSafari):
			out[str(c.name)] = [(c as Node3D).visible, c.process_mode]
	var env := w.get_node_or_null("Environment")
	if env != null:
		for sky_name: String in ["SkyBodies", "MeteorStreak", "Ring"]:
			var sky := env.get_node_or_null(sky_name) as Node3D
			if sky != null:
				out["Environment/" + sky_name] = [sky.visible, sky.process_mode]
	return out
