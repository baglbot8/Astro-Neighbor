class_name ShootingStar
extends Node3D
## One shooting star: a bright sparkling head, an additive streak oriented along the motion and a
## short-lived trail of twinkles. Frees itself when done.

const STAR_SHADER := preload("res://src/shaders/star.gdshader")
const STREAK_SHADER := preload("res://src/shaders/streak.gdshader")
const STREAK_LENGTH := 9.0
const STREAK_WIDTH := 0.9

var _velocity := Vector3.RIGHT
var _duration := 1.3
var _t := 0.0
var _streak: MeshInstance3D
var _streak_mat: ShaderMaterial
var _head: MeshInstance3D
var _head_mat: ShaderMaterial
var _trail: GPUParticles3D
var _trail_mat: ShaderMaterial

func setup(start: Vector3, travel_dir: Vector3, speed: float, duration: float) -> void:
	position = start
	_velocity = travel_dir.normalized() * speed
	_duration = duration

func _ready() -> void:
	_streak = MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(STREAK_LENGTH, STREAK_WIDTH)
	q.center_offset = Vector3(-STREAK_LENGTH * 0.5, 0.0, 0.0)
	_streak.mesh = q
	_streak_mat = ShaderMaterial.new()
	_streak_mat.shader = STREAK_SHADER
	_streak.material_override = _streak_mat
	_streak.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_streak.extra_cull_margin = STREAK_LENGTH
	add_child(_streak)

	_head = MeshInstance3D.new()
	var hq := QuadMesh.new()
	hq.size = Vector2(1.6, 1.6)
	_head.mesh = hq
	_head_mat = ShaderMaterial.new()
	_head_mat.shader = STAR_SHADER
	_head_mat.set_shader_parameter("tint", Color("#fff6d0"))
	_head_mat.set_shader_parameter("intensity", 3.5)
	_head_mat.set_shader_parameter("softness", 0.45)
	_head_mat.set_shader_parameter("core", 0.22)
	_head_mat.set_shader_parameter("points", 0.9)
	_head_mat.set_shader_parameter("blink_amount", 0.25)
	_head_mat.set_shader_parameter("blink_speed", 18.0)
	_head.material_override = _head_mat
	_head.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_head)

	_trail = GPUParticles3D.new()
	_trail.amount = 40
	_trail.lifetime = 0.9
	_trail.local_coords = false
	_trail.explosiveness = 0.0
	_trail.randomness = 0.6
	_trail.visibility_aabb = AABB(Vector3(-60, -60, -60), Vector3(120, 120, 120))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.25
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 180.0
	pm.initial_velocity_min = 0.2
	pm.initial_velocity_max = 0.9
	pm.gravity = Vector3.ZERO
	pm.scale_min = 0.35
	pm.scale_max = 0.9
	pm.anim_offset_max = 1.0
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.7, 1.0])
	ramp.colors = PackedColorArray([Color(1, 1, 1, 1), Color(0.8, 0.9, 1.0, 0.6), Color(0.6, 0.8, 1.0, 0.0)])
	var rt := GradientTexture1D.new()
	rt.gradient = ramp
	pm.color_ramp = rt
	_trail.process_material = pm
	var tq := QuadMesh.new()
	tq.size = Vector2(0.55, 0.55)
	_trail_mat = ShaderMaterial.new()
	_trail_mat.shader = STAR_SHADER
	_trail_mat.set_shader_parameter("tint", Color("#cfe8ff"))
	_trail_mat.set_shader_parameter("intensity", 2.4)
	_trail_mat.set_shader_parameter("points", 0.6)
	_trail_mat.set_shader_parameter("blink_amount", 0.6)
	_trail_mat.set_shader_parameter("blink_speed", 12.0)
	tq.material = _trail_mat
	_trail.draw_pass_1 = tq
	add_child(_trail)
	_trail.emitting = true
	_orient()

func _process(delta: float) -> void:
	_t += delta
	global_position += _velocity * delta
	var life := _t / _duration
	var fade := smoothstep(0.0, 0.15, life) * (1.0 - smoothstep(0.7, 1.0, life))
	_streak_mat.set_shader_parameter("fade", fade)
	_streak_mat.set_shader_parameter("scroll", _t * 6.0)
	_head_mat.set_shader_parameter("fade", fade)
	_orient()
	if life >= 1.0:
		_trail.emitting = false
	if life >= 1.0 + 1.0 / _duration:
		queue_free()

func _orient() -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var x := _velocity.normalized()
	var to_cam := (cam.global_position - global_position).normalized()
	var z := (to_cam - x * to_cam.dot(x))
	if z.length_squared() < 0.0001:
		z = Vector3.UP
	z = z.normalized()
	var y := z.cross(x).normalized()
	_streak.global_transform = Transform3D(Basis(x, y, z), global_position)
