extends Node3D
## Hub buildings showcase: the real Starport Plaza planet, the real Environment, and all four hub
## buildings attached exactly as src/world/world.gd attaches them. A camera orbits the plaza axis
## looking outward, so each building swings through the frame at roughly gameplay distance.
##
##   godot --path . res://showcase/hub_buildings.tscn -- --skip-title --quit-at=8
##   tools/capture.sh showcase/hub_buildings.tscn hub_buildings 240
##   tools/capture.sh showcase/hub_buildings.tscn hub_night 120 "" --night
##
## Flags: `--night` freezes the clock at 21:30 · `--noon` at 12:00 · `--hour=<h>` any hour ·
## `--home` shows the player's habitat on the home planet · `--focus=<id>` parks the camera on one
## building instead of orbiting, with `--dist=<m>` for the R2.9 review distances (5 m close to the
## wall, 8 m at the door, 22 m from across the plaza) and `--yaw=<deg>` to step around a blocked
## sightline · `--orbit=<seconds>` slows the orbit; `--orbit=240` is the shimmer test, because the
## content barely moves between frames so any frame-to-frame sparkle is aliasing, not the camera.
##
##   tools/snap.sh showcase/hub_buildings.tscn th_door 1.5 --focus=town_hall --dist=8
##   tools/capture.sh showcase/hub_buildings.tscn hub_shimmer 60 "" --orbit=240

const PLANET_SCENE := "res://src/planet/planet.tscn"
const ENV_SCENE := "res://src/world/environment.tscn"
const BUILDING_DIR := "res://src/hub/buildings/"

## Camera framing, matched to the gameplay rig (45 deg fov, ~28 deg elevation).
const CAM_M := -4.0            # surface metres from the plaza centre (negative = behind it)
const CAM_HEIGHT := 7.6
const TARGET_M := 16.5         # surface metres out, where the buildings stand
const TARGET_UP := 1.9
const ORBIT_SECONDS := 24.0

@export var planet_id: String = "hub"
@export var start_azimuth_deg: float = -60.0

var planet: Planet
var camera: Camera3D
var _env: Node3D
var _t: float = 0.0
var _spin: bool = true
var _s: Vector3 = Vector3.UP
var _t1: Vector3 = Vector3.RIGHT
var _t2: Vector3 = Vector3.FORWARD
var _cam_m: float = CAM_M
var _cam_height: float = CAM_HEIGHT
var _target_m: float = TARGET_M
var _target_up: float = TARGET_UP
var _focus_dir: Vector3 = Vector3.ZERO
var _orbit_seconds: float = ORBIT_SECONDS
var _stats: bool = false
var _stat_timer: float = 0.0


func _ready() -> void:
	name = "World"
	var hour := 10.5
	var focus := ""
	var dist := -1.0
	var azimuth_offset := 0.0
	for a in OS.get_cmdline_user_args():
		if a == "--night":
			hour = 21.5
		elif a == "--noon":
			hour = 12.0
		elif a == "--home":
			planet_id = "home"
		elif a.begins_with("--focus="):
			focus = a.substr(8)
		elif a.begins_with("--dist="):
			# R2.9 review distances: 2.5 m (close), 5 m (at the door), 15-25 m (across the plaza).
			dist = float(a.substr(7))
		elif a.begins_with("--yaw="):
			# degrees of azimuth added to the focused building, for a 3/4 view of the same wall
			azimuth_offset = float(a.substr(6))
		elif a.begins_with("--hour="):
			hour = float(a.substr(7))
		elif a == "--stats":
			# prints draw calls / GPU ms once a second, for the R2.9 frame-time budget
			_stats = true
		elif a.begins_with("--orbit="):
			# Seconds for a full orbit. A very slow orbit (e.g. 240) is the shimmer test: the
			# content barely changes between frames, so any frame-to-frame sparkle in a capture is
			# a fine pattern beating against the pixel grid rather than the camera moving.
			_orbit_seconds = maxf(float(a.substr(8)), 1.0)
	GameState.current_planet_id = planet_id
	GameState.time_of_day = hour

	var data: PlanetData = load("res://src/planet/data/%s.tres" % planet_id)
	planet = load(PLANET_SCENE).instantiate()
	planet.name = "Planet"
	planet.data = data
	add_child(planet)

	_env = load(ENV_SCENE).instantiate()
	_env.name = "Environment"
	_env.time_scale = 0.0
	add_child(_env)
	_env.set_time(hour)

	var root := Node3D.new()
	root.name = "Buildings"
	add_child(root)
	for bid in data.buildings:
		var p := BUILDING_DIR + bid + ".tscn"
		if not ResourceLoader.exists(p):
			push_warning("hub_buildings: missing %s" % p)
			continue
		var n: Node = load(p).instantiate()
		n.name = bid
		root.add_child(n)
		if n.has_method("attach_to_planet"):
			n.attach_to_planet(planet)

	_build_frame()
	camera = Camera3D.new()
	camera.name = "Camera"
	camera.fov = 45.0
	camera.near = 0.1
	camera.far = 400.0
	camera.current = true
	add_child(camera)

	if focus != "":
		# focus mode frames one building at a chosen review distance (R2.9 asks for 2-3 m, 5 m at
		# the door, and 15-25 m across the plaza). The camera is placed `d` metres from the
		# BUILDING along the surface, not `d` metres from the plaza centre, so the distance in the
		# frame is the distance you asked for on every planet.
		_spin = false
		var d: float = 9.6 if dist <= 0.0 else dist
		# Eye height and aim point track the review distance: close range looks at the door, plaza
		# range looks at the whole facade. Matches the gameplay rig's ~28 deg downward pitch.
		_cam_height = clampf(1.35 + d * 0.30, 1.6, 9.0)
		_target_up = clampf(1.20 + d * 0.06, 1.2, 3.0)
		_focus_dir = planet.building_dir(focus)
		if _focus_dir == Vector3.ZERO:
			_focus_dir = _s
		_place_focus(d, deg_to_rad(azimuth_offset))
	else:
		_place_camera(deg_to_rad(start_azimuth_deg))
	if _stats:
		RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
	EventBus.planet_loaded.emit(planet_id)


## Parks the camera `d` metres from the focused building, standing on the plaza side of it.
## `yaw` swings the camera around the building without moving what it looks at, so a blocked
## sightline (a tree in front of the home habitat) can be stepped around.
func _place_focus(d: float, yaw: float) -> void:
	var bd := _focus_dir.normalized()
	var toward := _s - bd * _s.dot(bd)
	if toward.length_squared() < 0.0001:
		toward = _t1
	toward = toward.normalized().rotated(bd, yaw)
	var ang := d / planet.radius
	var cam_dir := (bd * cos(ang) + toward * sin(ang)).normalized()
	var pos := planet.surface_point(cam_dir) + cam_dir * _cam_height
	var target := planet.surface_point(bd) + bd * _target_up
	camera.look_at_from_position(pos, target, cam_dir)


## Orthonormal tangent frame around the spawn direction; every azimuth below is measured in it.
func _build_frame() -> void:
	_s = planet.data.spawn_dir.normalized()
	var ref := Vector3.UP if absf(_s.dot(Vector3.UP)) < 0.9 else Vector3.RIGHT
	_t1 = _s.cross(ref).normalized()
	_t2 = _s.cross(_t1).normalized()


func _azimuth_of(dir: Vector3) -> float:
	if dir == Vector3.ZERO:
		return 0.0
	var tangential := dir - _s * dir.dot(_s)
	if tangential.length_squared() < 0.0001:
		return 0.0
	return atan2(tangential.dot(_t1), tangential.dot(_t2))


## Unit direction `metres` along the surface from the plaza centre, at azimuth `theta`.
func _surf_dir(metres: float, theta: float) -> Vector3:
	var ang := metres / planet.radius
	var tangent := _t2 * cos(theta) + _t1 * sin(theta)
	return (_s * cos(ang) + tangent * sin(ang)).normalized()


func _place_camera(theta: float) -> void:
	var cam_dir := _surf_dir(_cam_m, theta)
	var tgt_dir := _surf_dir(_target_m, theta)
	var pos := planet.surface_point(cam_dir) + cam_dir * _cam_height
	var target := planet.surface_point(tgt_dir) + tgt_dir * _target_up
	camera.look_at_from_position(pos, target, cam_dir)


func _process(delta: float) -> void:
	if _stats:
		_stat_timer += delta
		if _stat_timer >= 1.0:
			_stat_timer = 0.0
			# Draw calls and GPU frame time for the R2.9 budget check. A movie-mode capture reports
			# GPU 0.00 ms, so this is the only place the added shader cost actually shows up.
			var rid := get_viewport().get_viewport_rid()
			print("HUBSTATS draw_calls=%d prims=%d fps=%d gpu_ms=%.3f cpu_ms=%.3f" % [
				Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
				Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
				Engine.get_frames_per_second(),
				RenderingServer.viewport_get_measured_render_time_gpu(rid),
				RenderingServer.viewport_get_measured_render_time_cpu(rid)])
	if not _spin:
		return
	_t += delta
	_place_camera(deg_to_rad(start_azimuth_deg) + _t / _orbit_seconds * TAU)
