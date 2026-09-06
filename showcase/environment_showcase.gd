extends Node3D
## Environment showcase: a 16 m toon planet with chunky toon props, a gameplay-angle camera and the
## real Environment scene. Cycles a full day in `cycle_seconds` (frame 0 = 00:00) or freezes at
## `start_hour`. Run: godot --path . res://showcase/environment.tscn -- --skip-title --quit-at=12

## Camera matches the real gameplay rig exactly (src/player/camera_rig.gd: DIST_DEFAULT 6.5,
## PITCH_DEFAULT_DEG 28, PIVOT_HEIGHT 1.0, fov 45) so what the showcase shows is what the game shows.
const ENV_SCENE := preload("res://src/world/environment.tscn")
const PLANET_RADIUS := 16.0
const CAMERA_DISTANCE := 6.5
const CAMERA_ELEVATION_DEG := 28.0
const CAMERA_FOV := 45.0
const CAMERA_PIVOT_HEIGHT := 1.0
## Meadow green. home.tres `ground_color_a` (#6fa871) pushed a little further toward pastel,
## because this stand-in planet is a plain toon sphere while the real ground runs through
## grass_planet.gdshader, which mixes in a muted ground_shadow_color; feeding the raw albedo here
## measured saturation p90 0.72 against the real game's 0.57. Calibrated by measurement so the
## showcase lands in the same band as a gameplay frame (docs/AGENT_WORKFLOW), not by eye.
const GRASS_COLOR := Color("#7ba081")

@export var start_hour: float = 0.0
@export var cycle: bool = true
@export var cycle_seconds: float = 12.0
## Camera yaw around the local up. 0 looks north (-Z), 90 looks west (-X).
@export var camera_yaw_deg: float = 75.0
@export var moon_count: int = 1
@export var has_ring: bool = false
@export var cloud_density: float = 0.55

var _env: Node3D
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.seed = 7
	_build_planet()
	_build_props()
	_build_camera()
	var data := PlanetData.new()
	data.moon_count = moon_count
	data.has_ring = has_ring
	data.cloud_density = cloud_density
	_env = ENV_SCENE.instantiate()
	_env.name = "Environment"
	_env.data_override = data
	_env.time_scale = 0.0
	GameState.time_of_day = start_hour
	add_child(_env)
	_env.set_time(start_hour)
	if cycle:
		_env.time_scale = _env.DAY_LENGTH_SEC / cycle_seconds

# ----------------------------------------------------------------------------- planet
func _build_planet() -> void:
	var mi := MeshInstance3D.new()
	mi.name = "Planet"
	var sm := SphereMesh.new()
	sm.radius = PLANET_RADIUS
	sm.height = PLANET_RADIUS * 2.0
	sm.radial_segments = 128
	sm.rings = 64
	mi.mesh = sm
	# Matte, with a desaturated shadow tint. The default violet shade tint on a full-sphere
	# terminator drove the stand-in planet to saturation p90 0.75 while the real ground shader
	# (which mixes an explicit muted ground_shadow_color) measures 0.55.
	mi.material_override = MaterialLib.toon(GRASS_COLOR, {"texture": _grass_texture(),
		"uv_scale": Vector2(28.0, 14.0), "spec": 0.0, "rim": 0.10, "shade": 0.30,
		"shade_tint": Color("#7d9a90"), "softness": 0.45})
	# poles on the X axis so the camera (at +Y) never looks at the UV pinch
	mi.rotation = Vector3(0.0, 0.0, deg_to_rad(90.0))
	mi.add_to_group("planet")
	add_child(mi)

## ACNH-style triangle grass mosaic (two greens) baked into a small repeating texture.
func _grass_texture() -> ImageTexture:
	var size := 128
	var img := Image.create(size, size, false, Image.FORMAT_RGB8)
	var a := Color("#ffffff")
	var b := Color("#dcecd2")
	var cell := 16
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var dark: Dictionary = {}
	for y in size:
		for x in size:
			var cx: int = x / cell
			var cy: int = y / cell
			var fx := float(x % cell) / float(cell)
			var fy := float(y % cell) / float(cell)
			var tri := 0 if fx + fy < 1.0 else 1
			var key := cx * 1000 + cy * 10 + tri
			if not dark.has(key):
				dark[key] = rng.randf() < 0.32
			img.set_pixel(x, y, b if dark[key] else a)
	return ImageTexture.create_from_image(img)

# ----------------------------------------------------------------------------- props
func _surface_xform(offset: Vector2, yaw_deg: float = 0.0) -> Transform3D:
	var dir := (Vector3.UP * PLANET_RADIUS + Vector3(offset.x, 0.0, offset.y)).normalized()
	var fwd := Vector3.FORWARD - dir * dir.dot(Vector3.FORWARD)
	var basis := Basis.looking_at(fwd.normalized(), dir).rotated(dir, deg_to_rad(yaw_deg))
	return Transform3D(basis, dir * PLANET_RADIUS)

func _add_mesh(parent: Node3D, mesh: Mesh, mat: Material, local_pos: Vector3, local_scale: Vector3 = Vector3.ONE, local_rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.transform = Transform3D(Basis.from_euler(local_rot_deg * (PI / 180.0)) * Basis.from_scale(local_scale), local_pos)
	parent.add_child(mi)
	return mi

func _sphere(r: float = 1.0) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	m.radial_segments = 32
	m.rings = 16
	return m

func _capsule(r: float, h: float) -> CapsuleMesh:
	var m := CapsuleMesh.new()
	m.radius = r
	m.height = h
	m.radial_segments = 32
	m.rings = 8
	return m

func _cylinder(r_top: float, r_bottom: float, h: float) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = r_top
	m.bottom_radius = r_bottom
	m.height = h
	m.radial_segments = 32
	return m

func _prop(offset: Vector2, yaw_deg: float = 0.0) -> Node3D:
	var n := Node3D.new()
	n.transform = _surface_xform(offset, yaw_deg)
	add_child(n)
	return n

func _build_props() -> void:
	# Prop colours come straight from home.tres, not from the old bright showcase palette. A
	# showcase that measures saturation p90 0.73 while the game measures 0.57 is a lie you then
	# tune the sky against (docs/AGENT_WORKFLOW, R2.6).
	var trunk := MaterialLib.toon(Color("#9c6b47"), {"spec": 0.05})
	var leaf_a := MaterialLib.toon(Color("#4f8560"), {"spec": 0.05})
	var leaf_b := MaterialLib.toon(Color("#649c72"), {"spec": 0.05})
	var leaf_c := MaterialLib.toon(Color("#3b6450"), {"spec": 0.05})
	# chunky trees
	for tree in [[Vector2(-4.4, -0.8), 1.0, 20.0], [Vector2(3.6, -3.4), 0.8, 140.0], [Vector2(-5.4, 3.4), 0.9, 300.0], [Vector2(5.2, 0.8), 0.75, 60.0]]:
		var s: float = tree[1]
		var t := _prop(tree[0], tree[2])
		_add_mesh(t, _cylinder(0.24 * s, 0.34 * s, 1.5 * s), trunk, Vector3(0.0, 0.75 * s, 0.0))
		_add_mesh(t, _sphere(1.35 * s), leaf_a, Vector3(0.0, 2.45 * s, 0.0), Vector3(1.0, 0.85, 1.0))
		_add_mesh(t, _sphere(1.0 * s), leaf_b, Vector3(0.8 * s, 2.0 * s, 0.35 * s), Vector3(1.0, 0.8, 1.0))
		_add_mesh(t, _sphere(0.95 * s), leaf_c, Vector3(-0.8 * s, 2.1 * s, -0.25 * s), Vector3(1.0, 0.85, 1.0))
		_add_mesh(t, _sphere(0.8 * s), leaf_b, Vector3(0.1 * s, 3.2 * s, 0.1 * s))
	# astronaut stand-in: white capsule, big helmet with visor, orange boots
	var suit := MaterialLib.toon(Color("#e9e8ee"), {"spec": 0.05})
	var accent := MaterialLib.toon(Color("#c88370"), {"spec": 0.05})
	var astro := _prop(Vector2(0.0, -0.3), 0.0)
	_add_mesh(astro, _capsule(0.32, 0.95), suit, Vector3(0.0, 0.55, 0.0))
	_add_mesh(astro, _sphere(0.44), suit, Vector3(0.0, 1.12, 0.0))
	_add_mesh(astro, _sphere(0.36), MaterialLib.visor(Color("#6fc3ff"), 0.55), Vector3(0.0, 1.12, -0.16), Vector3(1.0, 0.85, 0.7))
	_add_mesh(astro, _sphere(0.16), accent, Vector3(-0.18, 0.12, 0.0), Vector3(1.0, 0.7, 1.3))
	_add_mesh(astro, _sphere(0.16), accent, Vector3(0.18, 0.12, 0.0), Vector3(1.0, 0.7, 1.3))
	_add_mesh(astro, _sphere(0.2), accent, Vector3(0.0, 0.75, 0.3), Vector3(1.3, 1.0, 0.6))
	# primitives for the toon ramp
	_add_mesh(_prop(Vector2(1.5, -1.7)), _sphere(0.6), MaterialLib.toon(Color("#c88370"), {"spec": 0.05}), Vector3(0.0, 0.6, 0.0))
	_add_mesh(_prop(Vector2(-1.3, -1.2)), _capsule(0.36, 1.4), MaterialLib.toon(Color("#7fb0d0"), {"spec": 0.05}), Vector3(0.0, 0.7, 0.0))
	_add_mesh(_prop(Vector2(2.4, 0.9)), _cylinder(0.45, 0.45, 0.9), MaterialLib.toon(Color("#e0be74"), {"spec": 0.05}), Vector3(0.0, 0.45, 0.0))
	_add_mesh(_prop(Vector2(-2.2, 0.6)), _sphere(0.5), MaterialLib.toon(Color("#a68cc4"), {"spec": 0.05}), Vector3(0.0, 0.5, 0.0), Vector3(1.4, 0.7, 1.4))
	# bench
	var bench := _prop(Vector2(1.2, 1.8), 25.0)
	_add_mesh(bench, _sphere(1.0), trunk, Vector3(0.0, 0.42, 0.0), Vector3(1.2, 0.18, 0.45))
	_add_mesh(bench, _cylinder(0.08, 0.1, 0.4), trunk, Vector3(-0.8, 0.2, 0.0))
	_add_mesh(bench, _cylinder(0.08, 0.1, 0.4), trunk, Vector3(0.8, 0.2, 0.0))
	# lamp post (bloom test)
	var lamp := _prop(Vector2(-2.6, 2.1))
	_add_mesh(lamp, _cylinder(0.07, 0.11, 1.9), MaterialLib.metal(Color("#8fa3bf")), Vector3(0.0, 0.95, 0.0))
	_add_mesh(lamp, _sphere(0.3), MaterialLib.glow(Color("#ffe27a"), 3.2), Vector3(0.0, 2.05, 0.0))
	_add_mesh(lamp, _cylinder(0.2, 0.36, 0.25), MaterialLib.metal(Color("#6f819c")), Vector3(0.0, 2.35, 0.0))
	# crystal cluster (bloom test, cool)
	var crystal := _prop(Vector2(3.3, -1.0), 30.0)
	var cm := MaterialLib.glow(Color("#3fb8ff"), 2.2, Color("#6fc8ff"))
	_add_mesh(crystal, _cylinder(0.02, 0.32, 1.2), cm, Vector3(0.0, 0.55, 0.0), Vector3.ONE, Vector3(0.0, 0.0, 8.0))
	_add_mesh(crystal, _cylinder(0.02, 0.22, 0.8), cm, Vector3(0.35, 0.35, 0.1), Vector3.ONE, Vector3(0.0, 0.0, -25.0))
	_add_mesh(crystal, _cylinder(0.02, 0.18, 0.6), cm, Vector3(-0.3, 0.28, -0.1), Vector3.ONE, Vector3(12.0, 0.0, 22.0))
	# rocks
	var rock := MaterialLib.toon(Color("#d8d3c6"), {"spec": 0.05})
	for r in [[Vector2(-3.6, -0.4), 0.55], [Vector2(4.4, 1.9), 0.45], [Vector2(-1.0, -3.9), 0.4], [Vector2(0.8, 3.2), 0.5]]:
		var s2: float = r[1]
		_add_mesh(_prop(r[0], _rng.randf_range(0.0, 360.0)), _sphere(s2), rock, Vector3(0.0, s2 * 0.55, 0.0), Vector3(1.3, 0.7, 1.0))
	# flowers
	var stem := MaterialLib.toon(Color("#57964a"), {"spec": 0.05})
	var petals := [MaterialLib.toon(Color("#dc7f9a"), {"spec": 0.05}), MaterialLib.toon(Color("#e0be74"), {"spec": 0.05}),
		MaterialLib.toon(Color("#e8e4d8"), {"spec": 0.05})]
	for i in 26:
		var off := Vector2(_rng.randf_range(-5.5, 5.5), _rng.randf_range(-5.0, 3.5))
		if off.length() < 1.2:
			continue
		var f := _prop(off)
		_add_mesh(f, _cylinder(0.03, 0.03, 0.32), stem, Vector3(0.0, 0.16, 0.0))
		_add_mesh(f, _sphere(0.11), petals[i % 3], Vector3(0.0, 0.36, 0.0), Vector3(1.0, 0.75, 1.0))

# ----------------------------------------------------------------------------- camera
func _build_camera() -> void:
	var cam := Camera3D.new()
	cam.name = "Camera"
	var up := Vector3.UP
	var target := up * PLANET_RADIUS
	var fwd := Vector3.FORWARD.rotated(up, deg_to_rad(camera_yaw_deg))
	var el := deg_to_rad(CAMERA_ELEVATION_DEG)
	cam.fov = CAMERA_FOV
	cam.near = 0.1
	cam.far = 300.0
	add_child(cam)
	var pivot := target + up * CAMERA_PIVOT_HEIGHT
	cam.look_at_from_position(pivot + up * CAMERA_DISTANCE * sin(el) - fwd * CAMERA_DISTANCE * cos(el), pivot, up)
	cam.current = true
