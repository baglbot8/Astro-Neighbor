extends Node3D
## Gallery of every decoration in the catalog, laid out as a parade around the REAL home planet.
## The camera rides the parade at the gameplay framing, so a single 300-frame capture walks past the
## whole collection with the lighting, sky, tonemapping and grass the game actually uses.
##
##   godot --path . res://showcase/decorations_gallery.tscn -- --skip-title
##   godot --path . res://showcase/decorations_gallery.tscn -- --skip-title --night
##   tools/capture.sh showcase/decorations_gallery.tscn deco_gallery 300
##
## Flags: `--night` sets the clock to 22:30 (emissives take over), `--still` stops the dolly,
## `--row=N` starts the camera at item N, `--perf` uncaps the frame rate and prints render timings,
## `--tris` prints the triangle budget of every item and quits.
##
## WHY THERE IS A WHOLE PLANET IN HERE (docs/AGENT_WORKFLOW.md "showcase MUST match gameplay lighting")
## The first version lit itself with two hand-placed DirectionalLights over a flat green plane, so
## every emissive in the set was tuned against lighting the game does not have and `astro_night` sat
## at its 1.0 default (day frames glowed like midnight). Swapping in `src/world/environment.tscn`
## fixed the lights but not the frame: with no planet under it the sky shader has no limb, paints
## black, and `tools/palette.py` measured 31% of the frame below luma 0.15 against 2% in the real
## game. The only honest way to match gameplay lighting is to stand on gameplay ground.

const PLANET_SCENE := "res://src/planet/planet.tscn"
const PLANET_DATA := "res://src/planet/data/home.tres"
const ENV_SCENE := "res://src/world/environment.tscn"
## Surface metres between neighbouring items along the parade.
const SPACING_M := 4.2
## Surface metres between the parade's two rows.
const ROW_GAP_M := 6.0
## Axis the parade circles around, and where slot 0 sits (chosen clear of the spawn and the pad).
const PARADE_AXIS := Vector3(0.3270885, 0.9345386, 0.1401808)
const PARADE_START := Vector3(0.9403762, 0.0, -0.3401361)
## Gameplay camera rig numbers (src/player/camera_rig.gd): distance, pitch and FOV.
const CAM_DIST := 6.5
const CAM_PITCH_DEG := 28.0
const CAM_FOV := 45.0
## Items per second the camera walks past.
const DOLLY_SPEED := 0.42

var planet: Planet
var _camera: Camera3D
var _anchor: Node3D
var _dirs: Array[Vector3] = []
var _u := 0.0
var _still := false
var _night := false
var _perf := false
var _tris := false
var _perf_t := 0.0
var _perf_frames := 0
var _perf_sum := 0.0
var _perf_worst := 0.0
var _perf_cpu := 0.0
var _perf_gpu := 0.0


func _ready() -> void:
	name = "DecorationsGallery"
	for a in OS.get_cmdline_user_args():
		if a == "--night":
			_night = true
		elif a == "--still":
			_still = true
		elif a.begins_with("--row="):
			_u = float(a.substr(6))
		elif a == "--perf":
			_perf = true
		elif a == "--tris":
			_tris = true
	GameState.time_of_day = 22.5 if _night else 12.0
	_build_planet()
	_build_environment()
	_build_items()
	_build_camera()
	if _perf:
		Engine.max_fps = 0
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
	if _tris:
		_report_tris.call_deferred()


func _build_planet() -> void:
	GameState.current_planet_id = "home"
	planet = load(PLANET_SCENE).instantiate()
	planet.name = "Planet"
	planet.data = load(PLANET_DATA)
	add_child(planet)


## Uses the REAL gameplay environment: sky, sun, moons, fog, tonemap, glow, colour grade and the
## `astro_night` global that every emissive shader reads.
func _build_environment() -> void:
	# The environment orients the sun in the player's local frame. There is no player here, so a
	# stand-in anchor rides the parade with the camera and keeps "up" pointing out of the ground.
	_anchor = Node3D.new()
	_anchor.name = "SunAnchor"
	_anchor.add_to_group("player")
	add_child(_anchor)

	var env: Node3D = load(ENV_SCENE).instantiate()
	env.name = "Environment"
	add_child(env)
	if env.has_method("set_time"):
		env.call("set_time", GameState.time_of_day)
	env.set("time_scale", 0.0)


## Lays every catalog decoration out along one great circle, sorted by category then price, each one
## seated on the real terrain with the real ground normal (the same call the placement system uses).
func _build_items() -> void:
	var items: Array = Catalog.items_of_kind("decoration")
	items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if str(a["category"]) == str(b["category"]):
			return int(a.get("price", 0)) < int(b.get("price", 0))
		return str(a["category"]) < str(b["category"]))
	for i in items.size():
		var def: Dictionary = items[i]
		var d := _parade_dir(float(i))
		_dirs.append(d)
		var path := str(def.get("scene", ""))
		if not ResourceLoader.exists(path):
			continue
		var node: Node3D = load(path).instantiate()
		node.name = str(def["id"])
		add_child(node)
		node.global_transform = _seat(d)
		var label := Label3D.new()
		label.text = str(def.get("name", def["id"]))
		label.font_size = 46
		label.pixel_size = 0.0024
		label.modulate = Color("#3a3550")
		label.outline_size = 18
		label.outline_modulate = Color(1.0, 1.0, 1.0, 0.9)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.shaded = false
		label.no_depth_test = false
		add_child(label)
		label.global_position = planet.surface_point(d) + d * 0.2 + _parade_tangent(d).cross(d) * 1.15


## Direction of parade slot `i`. The parade walks a great circle tilted away from the spawn and the
## rocket pad; a 16 m planet only holds ~23 items at this spacing, so slot 23 onward steps sideways
## onto a second, parallel row instead of walking back over the first one.
func _parade_dir(i: float) -> Vector3:
	var per_lap := maxf(floorf(TAU * planet.radius / SPACING_M), 1.0)
	var lap := floorf(i / per_lap)
	var slot := i - lap * per_lap
	var start := (PARADE_START - PARADE_AXIS * PARADE_START.dot(PARADE_AXIS)).normalized()
	var side := PARADE_AXIS.cross(start).normalized()
	var ang := slot * SPACING_M / planet.radius
	var d := (start * cos(ang) + side * sin(ang)).normalized()
	if lap > 0.0:
		d = d.rotated(PARADE_AXIS.cross(d).normalized(), lap * ROW_GAP_M / planet.radius)
	return d.normalized()


## Unit vector along the parade at `d` (the direction the row runs).
func _parade_tangent(d: Vector3) -> Vector3:
	return PARADE_AXIS.cross(d).normalized()


## Surface transform with the ground normal as up — the same seating the placement system gives a
## decoration, so what you judge here is what you get in game. Items face the camera side of the
## parade (models face -Z), otherwise half the set is seen edge-on as the camera walks the circle.
func _seat(d: Vector3) -> Transform3D:
	var xf := planet.surface_transform(d, _parade_tangent(d).cross(d).normalized())
	var n := planet.ground_normal(d, 0.35)
	var ax := xf.basis.y.cross(n)
	if ax.length_squared() > 0.000001:
		xf.basis = Basis(ax.normalized(), acos(clampf(xf.basis.y.dot(n), -1.0, 1.0))) * xf.basis
	xf.basis = xf.basis.orthonormalized()
	return xf


func _build_camera() -> void:
	_camera = Camera3D.new()
	_camera.name = "Camera"
	_camera.fov = CAM_FOV
	_camera.current = true
	add_child(_camera)
	_place_camera()


## Gameplay framing: 6.5 m back, 28 degrees up, looking at the item's mid height. The camera stands
## BESIDE the parade, not along it, so the row spreads left-to-right instead of stacking front-to-back.
func _place_camera() -> void:
	var d := _parade_dir(_u)
	var focus := planet.surface_point(d) + d * 0.7
	var back := _parade_tangent(d).cross(d).normalized()
	var pitch := deg_to_rad(CAM_PITCH_DEG)
	var offset := (back * cos(pitch) + d * sin(pitch)) * CAM_DIST
	_camera.global_position = focus + offset
	_camera.look_at(focus, d)
	_anchor.global_position = planet.surface_point(d)


func _process(delta: float) -> void:
	if _perf:
		_sample_perf(delta)
	if not _still:
		_u = fposmod(_u + delta * DOLLY_SPEED, float(maxi(_dirs.size(), 1)))
	_place_camera()


## `--perf`: uncaps the frame rate and prints CPU/GPU frame cost for the whole gallery.
func _sample_perf(delta: float) -> void:
	_perf_t += delta
	if _perf_t < 2.0:
		return  # warm-up: shader compiles and the first shadow pass
	_perf_frames += 1
	_perf_sum += delta
	_perf_worst = maxf(_perf_worst, delta)
	var vp := get_viewport().get_viewport_rid()
	_perf_cpu += RenderingServer.viewport_get_measured_render_time_cpu(vp)
	_perf_gpu += RenderingServer.viewport_get_measured_render_time_gpu(vp)
	if _perf_t > 8.0:
		var items: int = Catalog.items_of_kind("decoration").size()
		var ticking := 0
		for c in get_children():
			if c is DecoItem and (c as DecoItem).is_processing():
				ticking += 1
		var n := float(_perf_frames)
		print("PERF items=%d ticking_process=%d frames=%d wall_avg=%.2f ms wall_worst=%.2f ms render_cpu=%.2f ms render_gpu=%.2f ms script_process=%.2f ms draw_calls=%d tris=%d" % [
			items, ticking, _perf_frames, _perf_sum / n * 1000.0, _perf_worst * 1000.0, _perf_cpu / n, _perf_gpu / n,
			Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
			int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
			int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))])
		get_tree().quit()


## `--tris`: prints the triangle count of every item scene, worst first.
func _report_tris() -> void:
	var rows: Array = []
	var total := 0
	for c in get_children():
		if not (c is DecoItem):
			continue
		var n := 0
		for mi in _meshes_of(c):
			var m: Mesh = mi.mesh
			if m == null:
				continue
			for si in m.get_surface_count():
				var arrays: Array = m.surface_get_arrays(si)
				var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
				n += (idx.size() / 3) if idx.size() > 0 else int((arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3)
		rows.append([n, str(c.name)])
		total += n
	rows.sort_custom(func(a, b): return int(a[0]) > int(b[0]))
	for r in rows:
		print("TRIS %6d  %s" % [r[0], r[1]])
	print("TRIS TOTAL %d over %d items (avg %d)" % [total, rows.size(), total / maxi(rows.size(), 1)])
	get_tree().quit()


func _meshes_of(n: Node) -> Array:
	var out: Array = []
	for c in n.get_children():
		if c is MeshInstance3D:
			out.append(c)
		out.append_array(_meshes_of(c))
	return out
