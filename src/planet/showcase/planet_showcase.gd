class_name PlanetShowcase
extends Node3D
## Review scene for the planet builder. Builds planets from res://src/planet/data/<id>.tres under the
## REAL gameplay lighting rig — it instantiates res://src/world/environment.tscn, exactly what
## src/world/world.tscn uses — and drives a camera:
##
## It used to build its own warm sun + ProceduralSkyMaterial with tonemap_white 1.0 (gameplay uses
## 6.0), ambient energy 0.2 and adjustment_saturation 1.12. That is the "showcase lit by a lie" trap
## in docs/AGENT_WORKFLOW.md: every colour judged in it was judged against the wrong tone curve.
##  - cycle mode: every planet in turn, gameplay-like camera (6.5 m from the surface, 28 deg elevation)
##    slowly panning around the spawn point;
##  - orbit mode: one planet; starts at the gameplay view, then pulls out and orbits so the whole
##    planet can be judged close and far.
## Public: set_planet(id), next_planet() (also callable from Director timelines).

const CAM_DISTANCE := 6.5
const CAM_ELEVATION_DEG := 28.0
## Gameplay camera FOV (src/player/camera_rig.gd). Must match or the framing lies too.
const CAM_FOV := 45.0
const ENV_SCENE := "res://src/world/environment.tscn"

@export var planet_ids: PackedStringArray = PackedStringArray(["home", "zorp", "bolt", "hub", "fen", "grig", "vela"])
@export var cycle_seconds: float = 3.0
@export var orbit_mode: bool = false
@export var orbit_seconds: float = 8.0
## Orbit mode: never pull out (stay at the gameplay camera, slowly yawing around the focus).
@export var hold_close: bool = false
## Camera distance from the focus point. Defaults to the gameplay 6.5 m; set it shorter only to
## inspect one small object (a collectible, a canopy tier) and say so when you report the frame.
@export var cam_distance: float = CAM_DISTANCE
## Lower the camera's aim by this many metres (0.9 = chest height). Small props sit near the ground.
@export var look_height: float = 0.9
## Where the gameplay camera looks: "spawn", "pad", or a building id.
@export var focus: String = "spawn"
## Hour of day. Passed straight to Environment.set_time(); the clock is frozen so a capture is
## reproducible (13 = the daytime frame the palette gates are measured on).
@export var hour: float = 13.0
## Debug: 0 = normal, 1 = flat toon ground material, 2 = StandardMaterial3D ground (isolates shader issues).
@export var debug_ground_mode: int = 0
## Debug: drop a 1.4 m tall toon capsule at the focus point (scale + shadow reference).
@export var debug_marker: bool = false
## Debug: disable sun shadows.
@export var debug_no_shadows: bool = false

var _planet: Planet
var _cam: Camera3D
var _env: Node3D
var _label: Label
var _t := 0.0
var _index := 0
var _cycle_t := 0.0
var _perf_t := 0.0
var _perf_frames := 0

func _ready() -> void:
	_cam = Camera3D.new()
	_cam.name = "Camera"
	_cam.fov = CAM_FOV
	_cam.near = 0.1
	_cam.far = 400.0
	_cam.current = true
	add_child(_cam)
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
	var layer := CanvasLayer.new()
	add_child(layer)
	_label = Label.new()
	_label.position = Vector2(24.0, 16.0)
	_label.add_theme_font_size_override("font_size", 26)
	_label.add_theme_color_override("font_color", Color("#fff8e1"))
	_label.add_theme_color_override("font_outline_color", Color("#6b5232"))
	_label.add_theme_constant_override("outline_size", 6)
	layer.add_child(_label)
	if planet_ids.is_empty():
		planet_ids = PackedStringArray(["home"])
	set_planet(planet_ids[0])

## Rebuilds the scene for planet `id`.
func set_planet(id: String) -> void:
	if _planet:
		_planet.queue_free()
		_planet = null
	var path := "res://src/planet/data/%s.tres" % id
	var data: PlanetData = load(path) if ResourceLoader.exists(path) else PlanetData.new()
	var t0 := Time.get_ticks_msec()
	_planet = load("res://src/planet/planet.tscn").instantiate()
	_planet.name = "Planet"
	_planet.data = data
	add_child(_planet)
	if debug_ground_mode == 1:
		_planet.surface_mesh.material_override = MaterialLib.toon(data.ground_color_a)
	elif debug_ground_mode == 2:
		var sm := StandardMaterial3D.new()
		sm.albedo_color = data.ground_color_a
		_planet.surface_mesh.material_override = sm
	if debug_marker:
		var mk := MeshInstance3D.new()
		var cm := CapsuleMesh.new()
		cm.radius = 0.35
		cm.height = 1.4
		mk.mesh = cm
		mk.material_override = MaterialLib.toon(Color("#ff7a59"))
		mk.transform = _planet.surface_transform(_focus_dir())
		mk.transform.origin += mk.transform.basis.y * 0.7
		add_child(mk)
	var ms := Time.get_ticks_msec() - t0
	var kinds: Dictionary = {}
	for c in _planet.props_root.get_children():
		var k := c.name.rstrip("0123456789")
		if c is MultiMeshInstance3D:
			k = "multimesh(%d)" % (c as MultiMeshInstance3D).multimesh.instance_count
		elif c is GPUParticles3D:
			k = "particles"
		elif k == "" or k == "@StaticBody3D@" or k.begins_with("@"):
			k = "prop"
		kinds[k] = int(kinds.get(k, 0)) + 1
	print("PlanetShowcase: built '%s' in %d ms (%d props, %d collectibles) %s" % [id, ms, _planet.props_root.get_child_count(), _planet.collectibles_root.get_child_count(), str(kinds)])
	_label.text = "%s  (%s)" % [data.display_name, data.biome]
	_setup_environment(data)
	_cycle_t = 0.0
	_update_camera(0.0)

## Advances to the next planet in planet_ids.
func next_planet() -> void:
	_index = (_index + 1) % planet_ids.size()
	set_planet(planet_ids[_index])

## Rebuilds the REAL gameplay environment (src/world/environment.tscn) for the current planet and
## freezes its clock at `hour`. Same sky shader, sun rig, ACES tonemap_white, colour grade, glow and
## vignette as src/world/world.tscn, so a palette measurement taken here matches a gameplay frame.
func _setup_environment(_data: PlanetData) -> void:
	if is_instance_valid(_env):
		remove_child(_env)
		_env.queue_free()
		_env = null
	if not ResourceLoader.exists(ENV_SCENE):
		return
	var packed := load(ENV_SCENE) as PackedScene
	if packed == null:
		return
	_env = packed.instantiate() as Node3D
	if _env == null:
		return
	_env.name = "Environment"
	# Frozen clock: a showcase capture must be reproducible, and the palette gates are measured at 13.
	_env.set("time_scale", 0.0)
	add_child(_env)
	if _env.has_method("set_time"):
		_env.call("set_time", hour)
	if debug_no_shadows:
		for c in _env.find_children("*", "DirectionalLight3D", true, false):
			(c as DirectionalLight3D).shadow_enabled = false

func _focus_dir() -> Vector3:
	var d: PlanetData = _planet.data
	match focus:
		"pad":
			return d.pad_dir.normalized()
		"spawn":
			return d.spawn_dir.normalized()
		"crater":
			return _planet._crater_dirs[0] if _planet._crater_dirs.size() > 0 else d.spawn_dir.normalized()
		_ when focus.begins_with("prop:"):
			var n := _planet.props_root.get_node_or_null(focus.substr(5))
			return _planet.dir_of(n.global_position) if n is Node3D else d.spawn_dir.normalized()
		_ when focus.begins_with("collectible:"):
			var idx := int(focus.substr(12))
			var kids := _planet.collectibles_root.get_children()
			return _planet.dir_of((kids[idx] as Node3D).global_position) if idx < kids.size() else d.spawn_dir.normalized()
		_:
			var bd := _planet.building_dir(focus)
			return bd if bd != Vector3.ZERO else d.spawn_dir.normalized()

func _process(delta: float) -> void:
	if _planet == null:
		return
	_t += delta
	_cycle_t += delta
	_perf_t += delta
	_perf_frames += 1
	if _perf_t >= 2.0:
		var vp := get_viewport().get_viewport_rid()
		print("PERF %s: cpu %.2f ms  gpu %.2f ms  process %.2f ms  fps %.0f  draw_calls %d  primitives %dk" % [
			_planet.data.id,
			RenderingServer.viewport_get_measured_render_time_cpu(vp),
			RenderingServer.viewport_get_measured_render_time_gpu(vp),
			Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
			_perf_frames / _perf_t,
			int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
			int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME) / 1000.0)])
		_perf_t = 0.0
		_perf_frames = 0
	if not orbit_mode and _cycle_t >= cycle_seconds and planet_ids.size() > 1:
		next_planet()
		return
	_update_camera(_cycle_t)

func _update_camera(t: float) -> void:
	var up := _focus_dir()
	var xf := _planet.surface_transform(up, Vector3.FORWARD)
	var target := xf.origin
	var r: float = _planet.radius
	var cam_d: float = maxf(cam_distance, 0.4)
	if orbit_mode:
		var k := clampf(t / maxf(orbit_seconds, 0.01), 0.0, 1.0)
		var close_phase := 1.0 if hold_close else 1.0 - smoothstep(0.32, 0.72, k)
		var yaw := t * 0.55
		var elev := deg_to_rad(lerpf(CAM_ELEVATION_DEG, 34.0, 1.0 - close_phase))
		var fwd := (xf.basis.x * sin(yaw) + (-xf.basis.z) * cos(yaw)).normalized()
		var eye_close := target + up * (cam_d * sin(elev)) - fwd * (cam_d * cos(elev))
		var eye_far := (up * cos(elev) - fwd * sin(elev)).normalized() * (r * 2.55)
		var far_t := smoothstep(0.0, 1.0, 1.0 - close_phase)
		var eye := eye_close.lerp(eye_far, far_t)
		var look := (target + up * look_height).lerp(Vector3.ZERO, far_t)
		_cam.look_at_from_position(eye, look, up)
	else:
		# "Walk" the focus point from the spawn toward the pad so the frames show real surroundings.
		var walk_m := minf(t * 2.2, 10.0)
		var wdir := _planet.step_dir(up, -_planet.data.pad_dir.normalized(), walk_m)
		var wxf := _planet.surface_transform(wdir, Vector3.FORWARD)
		up = wdir
		target = wxf.origin
		var yaw := 0.35 + t * 0.22
		var elev := deg_to_rad(CAM_ELEVATION_DEG)
		var fwd := (wxf.basis.x * sin(yaw) + (-wxf.basis.z) * cos(yaw)).normalized()
		var eye := target + up * (cam_d * sin(elev)) - fwd * (cam_d * cos(elev))
		_cam.look_at_from_position(eye, target + up * look_height, up)
