class_name NightLife
extends Node3D
## Night-only life: fireflies drifting near the ground around the player, and occasional shooting
## stars streaking across the visible sky. Driven by environment.gd via update_state().

const STAR_SHADER := preload("res://src/shaders/star.gdshader")
const STREAK_SHADER := preload("res://src/shaders/streak.gdshader")
const FIREFLY_COLOR := Color("#e4ff7a")
const FIREFLY_COUNT := 24
const FIREFLY_AREA := 5.5
## Quad edge length in metres. The reference fireflies are fat soft glows, not pinpricks.
const FIREFLY_SIZE := 0.26
const SHOOTING_STAR_MIN_WAIT := 6.0
const SHOOTING_STAR_MAX_WAIT := 15.0
const SHOOTING_STAR_DISTANCE := 58.0

var planet_radius: float = 16.0

var _fireflies: GPUParticles3D
var _firefly_mat: ShaderMaterial
var _night := 0.0
var _anchor := Vector3.UP * 16.0
var _up := Vector3.UP
var _east := Vector3.RIGHT
var _star_timer := 4.0
var _rng := RandomNumberGenerator.new()
var _active_stars: Array[ShootingStar] = []

func _ready() -> void:
	_rng.randomize()
	_build_fireflies()

func _build_fireflies() -> void:
	_fireflies = GPUParticles3D.new()
	_fireflies.name = "Fireflies"
	_fireflies.amount = FIREFLY_COUNT
	_fireflies.lifetime = 7.0
	_fireflies.preprocess = 4.0
	_fireflies.randomness = 1.0
	_fireflies.local_coords = false
	_fireflies.fixed_fps = 30
	_fireflies.interpolate = true
	_fireflies.emitting = false
	_fireflies.visibility_aabb = AABB(Vector3(-40, -40, -40), Vector3(80, 80, 80))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(FIREFLY_AREA, 0.5, FIREFLY_AREA)
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 180.0
	pm.initial_velocity_min = 0.12
	pm.initial_velocity_max = 0.4
	pm.gravity = Vector3.ZERO
	pm.damping_min = 0.0
	pm.damping_max = 0.05
	pm.scale_min = 0.7
	pm.scale_max = 1.3
	pm.anim_offset_min = 0.0
	pm.anim_offset_max = 1.0
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 0.9
	pm.turbulence_noise_scale = 3.0
	pm.turbulence_noise_speed = Vector3(0.2, 0.15, 0.2)
	pm.turbulence_noise_speed_random = 0.3
	pm.turbulence_influence_min = 0.06
	pm.turbulence_influence_max = 0.14
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.18, 0.8, 1.0])
	ramp.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	var ramp_tex := GradientTexture1D.new()
	ramp_tex.gradient = ramp
	pm.color_ramp = ramp_tex
	_fireflies.process_material = pm
	var quad := QuadMesh.new()
	quad.size = Vector2(FIREFLY_SIZE, FIREFLY_SIZE)
	_firefly_mat = ShaderMaterial.new()
	_firefly_mat.shader = STAR_SHADER
	_firefly_mat.set_shader_parameter("tint", FIREFLY_COLOR)
	_firefly_mat.set_shader_parameter("intensity", 2.2)
	_firefly_mat.set_shader_parameter("softness", 0.12)
	_firefly_mat.set_shader_parameter("core", 0.2)
	_firefly_mat.set_shader_parameter("blink_speed", 2.6)
	_firefly_mat.set_shader_parameter("blink_amount", 0.75)
	_firefly_mat.set_shader_parameter("fade", 0.0)
	quad.material = _firefly_mat
	_fireflies.draw_pass_1 = quad
	add_child(_fireflies)

## Called every frame by the environment with the current night factor and player frame.
func update_state(night: float, anchor: Vector3, up: Vector3, east: Vector3, radius: float) -> void:
	_night = night
	_anchor = anchor
	_up = up
	_east = east
	planet_radius = radius
	var want := night > 0.35
	if _fireflies.emitting != want:
		_fireflies.emitting = want
	_firefly_mat.set_shader_parameter("fade", clampf((night - 0.3) / 0.5, 0.0, 1.0))
	var basis := _frame_basis(up, east)
	_fireflies.global_transform = Transform3D(basis, anchor + up * 0.9)

func _process(delta: float) -> void:
	if _night < 0.6:
		_star_timer = minf(_star_timer, 3.0)
		return
	_star_timer -= delta
	if _star_timer <= 0.0:
		_star_timer = _rng.randf_range(SHOOTING_STAR_MIN_WAIT, SHOOTING_STAR_MAX_WAIT)
		_spawn_shooting_star()

func _spawn_shooting_star() -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var up := _up
	var fwd := -cam.global_transform.basis.z
	fwd = (fwd - up * fwd.dot(up))
	if fwd.length_squared() < 0.001:
		fwd = _east
	fwd = fwd.normalized()
	var right := fwd.cross(up).normalized()
	# somewhere in the visible sky band: slightly below the local horizontal, in front of the camera
	var yaw := deg_to_rad(_rng.randf_range(-32.0, 32.0))
	var pitch := deg_to_rad(_rng.randf_range(-16.0, 2.0))
	var dir := (fwd * cos(yaw) + right * sin(yaw)) * cos(pitch) + up * sin(pitch)
	var start := cam.global_position + dir.normalized() * SHOOTING_STAR_DISTANCE
	var travel := (right * (1.0 if _rng.randf() < 0.5 else -1.0) * 0.9 - up * 0.35 + fwd * 0.1).normalized()
	var star := ShootingStar.new()
	star.setup(start, travel, _rng.randf_range(16.0, 24.0), _rng.randf_range(1.1, 1.6))
	add_child(star)

static func _frame_basis(up: Vector3, east: Vector3) -> Basis:
	var e := (east - up * up.dot(east)).normalized()
	var n := up.cross(e).normalized()
	return Basis(e, up, -n)
