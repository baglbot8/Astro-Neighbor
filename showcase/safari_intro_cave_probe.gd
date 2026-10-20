extends "res://showcase/safari_intro_probe.gd"
## THE CAVE'S START-CUTSCENE PROBE (builder CAVE-INTRO, 2026-10-19; a test harness, not gameplay). Inert unless
## `--sip` is passed. The shared probe (safari_intro_probe.gd) with the REAL CaveVisit started by its real entry
## (`CaveVisit.request_enter`, the entrance's "Go in"), not the stub host, plus cave-only measurements:
##
##   godot --path <copy> --rendering-method gl_compatibility --resolution 2556x1179 --always-on-top \
##     --position 100,100 --max-fps 30 --quit-after 3000 res://showcase/safari_intro_cave_probe.tscn -- \
##     --sip --ui=mobile --safari-tips=off --sip-mode=c|off [--sip-seen] [shared --sip-* flags] [cave flags]
##
##   --cave-clear        every frame: the camera's clearance to the stone (rays in 26 directions against the cave's
##                       collision, layer 1), the worst per scene, and the camera's angular speed (deg/s) per scene
##   --cave-double-log   every frame: the double's feet in the start frame (metres) - its walk measured
##   --cave-refuse-first before the visit: marks today visited, asks to enter (must be refused with the kind line),
##                       then clears the mark and enters for real
##   --cave-end-at=S     S seconds after control: ends the visit as "Leave" does (synthetic: `_go_to_sleep()`), then
##                       reports the review
##   --cave-views=<file> EXPLORE: after control, renders each line "name x y z lx ly lz [fov]" (start-frame metres:
##                       x right, y up, z back; the lens at xyz looking at lxyz) to --sip-shots, with its clearance
##
## EVERY INPUT IS SYNTHESISED (see the shared probe). Nothing here proves a real finger.

var _clear_on := false
var _dbl_log := false
var _clear_min := {1: [INF, 0.0], 2: [INF, 0.0]}
var _ang := {1: [0.0, 0.0], 2: [0.0, 0.0]}
var _prev_ang_t := -1.0
var _prev_ang_fwd := Vector3.ZERO
var _end_at := -1.0
var _end_sent := false
var _views_file := ""
var _views_done := false
var _cut := 3.9


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.has("--sip") and not persistent:
		GameState.current_planet_id = "home"
		var p: Node = load("res://showcase/safari_intro_cave_probe.gd").new()
		p.persistent = true
		p.name = "SafariIntroProbe"
		get_tree().root.add_child.call_deferred(p)
		get_tree().change_scene_to_file.call_deferred("res://src/world/world.tscn")
		return
	super._ready()
	if not persistent:
		return
	_clear_on = _args.has("--cave-clear")
	_dbl_log = _args.has("--cave-double-log")
	_end_at = float(_arg_val("--cave-end-at=", "-1"))
	_views_file = _arg_val("--cave-views=", "")
	if _views_file != "":
		_after = 600.0


func _start() -> void:
	_started = true
	if _mode != "none":
		GameState.settings["safari_intro"] = _mode
	if _args.has("--sip-seen"):
		for k in ["a", "b", "c"]:
			GameState.flags["safari_intro_seen_" + k] = true
	GameState.story_done = true
	_req_ms = Time.get_ticks_msec()
	print("SIP texmem before %.1f MB" % (Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0))
	print("SIP cave: settings=%s seen_c=%s day=%d" % [str(GameState.settings.get("safari_intro", "<unset>")),
		str(GameState.flags.get("safari_intro_seen_c", false)), GameState.day_count])
	if _args.has("--cave-refuse-first"):
		CaveStore.mark_visit()
		var r := CaveVisit.request_enter(get_tree())
		print("SIP cave refuse test: request_enter with today spent -> %s" % ("REFUSED (null)" if r == null else "ENTERED (bad)"))
	GameState.flags.erase(CaveStore.F_VISIT_DAY)
	print("SIP cave: visited_today before entering=%s" % str(CaveStore.visited_today()))
	print("SIP modals before the outing starts: %s" % str(EventBus.open_modals()))
	var cv := CaveVisit.request_enter(get_tree())
	print("SIP outing: cave (REAL CaveVisit via request_enter) -> %s" % str(cv != null))
	if cv != null:
		_watch_day.call_deferred(cv)


## The day flag must be spent at the start (behind the first black), not at control.
func _watch_day(cv: CaveVisit) -> void:
	for i in 3:
		await get_tree().process_frame
	print("SIP cave: 3 frames after entering: visited_today=%s phase=%d" % [str(CaveStore.visited_today()), cv.phase])


func _frame(s: PlanetSafari, delta: float) -> void:
	super._frame(s, delta)
	var t := _t_lift
	var in_intro := _t_awake < 0.0
	var intro := s.get_node_or_null("SafariIntro")
	if intro != null:
		_cut = float(intro.get("_c_cut"))
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	# The scene by the INTRO's own clock (the probe's lift clock can be a frame off).
	var it := float((intro.call("debug_state") as Dictionary).get("t", t)) if intro != null else t
	var scene := 1 if it < _cut else 2
	if _clear_on and in_intro:
		var c := _clearance(s, cam.global_position)
		if c < float(_clear_min[scene][0]):
			_clear_min[scene] = [c, t]
		var fwd := -cam.global_transform.basis.z
		if _prev_ang_t >= 0.0 and t > _prev_ang_t:
			var w := rad_to_deg(_prev_ang_fwd.angle_to(fwd)) / (t - _prev_ang_t)
			# Not across the cut's dip (a deliberate cut), nor in the hand-back's last frame.
			var near_cut := absf(t - _cut) < 0.2
			if not near_cut and w > float(_ang[scene][0]):
				_ang[scene] = [w, t]
			if _args.has("--cave-ang-log"):
				print("SIP ang t=%.3f %.2f deg/s clear=%.2f m scene=%d" % [t, w, c, scene])
		_prev_ang_t = t
		_prev_ang_fwd = fwd
	if _dbl_log and in_intro and intro != null:
		var dbl := intro.get("_double") as Node3D
		if dbl != null and is_instance_valid(dbl) and dbl.visible:
			var sx: Transform3D = intro.get("_start_xf")
			var lp := sx.affine_inverse() * dbl.global_position
			print("SIP dbl t=%.3f local=(%.3f,%.3f,%.3f)" % [t, lp.x, lp.y, lp.z])
	if not in_intro and _end_at >= 0.0 and not _end_sent and t >= _t_awake + _end_at:
		_end_sent = true
		print("SIP cave: ending the visit (synthetic _go_to_sleep) at elapsed=%.2f" % s.elapsed)
		_after = 600.0
		s.call("_go_to_sleep")
		_watch_review(s)
	if not in_intro and _args.has("--cave-grid") and not _views_done and t >= _t_awake + 0.6:
		_views_done = true
		var sx := s.player.global_transform
		for hy in [0.8, 1.3]:
			print("SIP grid h=%.1f (rows z from -1.5 to 1.5 step 0.3; cols x from -1.8 to 1.8 step 0.3)" % hy)
			for zi in 11:
				var z := -1.5 + 0.3 * zi
				var row := "SIP grid z=%+.1f:" % z
				for xi in 13:
					var x := -1.8 + 0.3 * xi
					row += " %4.2f" % _clearance(s, sx * Vector3(x, hy, z))
				print(row)
		print("SIP DONE")
		get_tree().quit()
	if not in_intro and _views_file != "" and not _views_done and t >= _t_awake + 0.6:
		_views_done = true
		_explore(s)


func _watch_review(s: PlanetSafari) -> void:
	var t0 := Time.get_ticks_msec()
	while is_instance_valid(s) and Time.get_ticks_msec() - t0 < 8000:
		await get_tree().process_frame
		if _count_named(get_tree().root, "CaveReview") > 0:
			print("SIP cave: review on screen (CaveReview node present) phase=%d" % s.phase)
			if _shots_dir != "":
				for i in 20:
					await get_tree().process_frame
				_capture("review")
			break
	print("SIP cave: review check done; visited_today=%s" % str(CaveStore.visited_today()))
	print("SIP DONE")
	get_tree().quit()


## The nearest stone (cave collision, layer 1) within 4 m, over 26 directions.
func _clearance(s: PlanetSafari, p: Vector3) -> float:
	var space := s.get_world_3d().direct_space_state
	var best := 4.0
	for x in [-1, 0, 1]:
		for y in [-1, 0, 1]:
			for z in [-1, 0, 1]:
				if x == 0 and y == 0 and z == 0:
					continue
				var d := Vector3(x, y, z).normalized()
				# The stone (layer 1) and the props' bodies (layer 4: crystal clusters, the pool rim, the chest).
				var q := PhysicsRayQueryParameters3D.create(p, p + d * 4.0, 1 | 8)
				var hit := space.intersect_ray(q)
				if not hit.is_empty():
					best = minf(best, p.distance_to(hit["position"]))
	return best


func _explore(s: PlanetSafari) -> void:
	var f := FileAccess.open(_views_file, FileAccess.READ)
	if f == null:
		print("SIP views: cannot read %s" % _views_file)
		get_tree().quit()
		return
	var sx := s.player.global_transform
	var cam := Camera3D.new()
	var rc := s.rig.get_view_camera()
	cam.environment = rc.environment
	cam.attributes = rc.attributes
	cam.near = rc.near
	cam.far = rc.far
	cam.cull_mask = rc.cull_mask
	s.add_child(cam)
	cam.current = true
	s.layer.visible = false
	for nm in ["GlowCrystals", "WayOut"]:
		var n := s.find_child(nm, true, false) as Node3D
		if n != null:
			print("SIP place %s at %s (start frame)" % [nm, str(sx.affine_inverse() * n.global_position)])
	var cw := s.get("_content") as Node
	if cw != null:
		var cxf := (cw.get("cave") as Node3D).global_transform
		var arr: Array = cw.get("_crystals")
		for c: Dictionary in arr:
			var lp: Vector3 = sx.affine_inverse() * cxf * CaveWorld.W(c["p"])
			if lp.length() < 14.0 or (bool(c["rainbow"]) and lp.length() < 45.0):
				print("SIP wall crystal at %s rainbow=%s tube=%s s=%.1f" % [str(lp.snapped(Vector3.ONE * 0.01)),
					str(c["rainbow"]), (c["t"] as Object).get("id"), float(c["s"])])
		var trunk: Object = cw.get("trunk")
		var mk: Dictionary = cw.get("_mk")
		for k: String in mk:
			var tb: Object = cw.get(k.get_slice(":", 0)) if k.get_slice(":", 0) != "upway" else cw.get("upway")
			if tb == null:
				continue
			var a: Dictionary = tb.call("at", tb.call("s_of", int(mk[k])))
			var lp2: Vector3 = sx.affine_inverse() * cxf * CaveWorld.W(a["p"])
			print("SIP mark %s at %s w=%.1f h=%.1f" % [k, str(lp2.snapped(Vector3.ONE * 0.1)), float(a["w"]), float(a["h"])])
		var cc: Vector3 = cw.get("_chamber_c")
		print("SIP chamber centre %s" % str((sx.affine_inverse() * cxf * CaveWorld.W(cc)).snapped(Vector3.ONE * 0.1)))
	var ui := s.layer.get_node_or_null("Root") as CanvasItem
	if ui != null:
		ui.visible = false
	while not f.eof_reached():
		var ln := f.get_line().strip_edges()
		if ln == "" or ln.begins_with("#"):
			continue
		var a := ln.split(" ", false)
		var p := sx * Vector3(float(a[1]), float(a[2]), float(a[3]))
		var l := sx * Vector3(float(a[4]), float(a[5]), float(a[6]))
		cam.fov = float(a[7]) if a.size() > 7 else 50.0
		cam.global_transform = Transform3D(Basis.looking_at(l - p, s.planet.up_at(p)), p)
		for i in 4:
			await get_tree().process_frame
		print("SIP view %s clearance=%.2f m" % [a[0], _clearance(s, p)])
		_capture("view_" + a[0])
	print("SIP DONE")
	get_tree().quit()


func _finish(s: PlanetSafari) -> void:
	if _clear_on:
		print("SIP CAVE clearance min: scene1 %.2f m (t=%.2f), scene2 %.2f m (t=%.2f)" % [float(_clear_min[1][0]),
			float(_clear_min[1][1]), float(_clear_min[2][0]), float(_clear_min[2][1])])
		print("SIP CAVE angular speed max: scene1 %.1f deg/s (t=%.2f), scene2 %.1f deg/s (t=%.2f)" % [float(_ang[1][0]),
			float(_ang[1][1]), float(_ang[2][0]), float(_ang[2][1])])
	print("SIP cave: at the end visited_today=%s" % str(CaveStore.visited_today()))
	super._finish(s)
