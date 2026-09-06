class_name PlanetBody
extends CharacterBody3D
## Base class for anything that walks on a Planet (player, NPCs).
## Handles radial gravity, keeps the body upright on the sphere, and offers movement helpers.
## Subclasses set `planet`, then each physics tick call:
##     apply_planet_gravity(delta) ; move_on_surface(tangent_velocity) ; move_and_slide()
## (see Player / NPC for the full pattern).

var planet: Planet
var gravity_strength: float = 30.0
var up: Vector3 = Vector3.UP
var jump_velocity: float = 9.0
var floor_snap: float = 0.6

func _ready() -> void:
	floor_max_angle = deg_to_rad(62.0)
	floor_snap_length = floor_snap
	floor_stop_on_slope = true
	floor_constant_speed = true
	slide_on_ceiling = false
	up_direction = Vector3.UP
	safe_margin = 0.02

func has_planet() -> bool:
	return planet != null

## Recomputes `up` and rotates the body so its local Y matches the planet normal. Call every physics tick before moving.
func align_to_planet() -> void:
	if planet == null:
		return
	up = planet.up_at(global_position)
	up_direction = up
	var b := global_transform.basis
	var cur_up := b.y.normalized()
	var d := cur_up.dot(up)
	if d < 0.99999:
		var axis := cur_up.cross(up)
		if axis.length_squared() > 0.000001:
			var rot := Basis(axis.normalized(), acos(clampf(d, -1.0, 1.0)))
			b = rot * b
	global_transform.basis = b.orthonormalized()

## Adds radial gravity to velocity (only the radial component, so tangential motion is untouched).
func apply_planet_gravity(delta: float) -> void:
	if planet == null:
		return
	if not is_on_floor():
		velocity += -up * gravity_strength * delta
	else:
		# Keep a small downward bias so is_on_floor stays reliable on the curved ground.
		var radial := velocity.dot(up)
		if radial < 0.0:
			velocity -= up * radial
		velocity += -up * 2.0 * delta

## Sets the tangential part of velocity (keeps the radial/vertical part for jumps & falls).
func set_tangent_velocity(tangent_vel: Vector3) -> void:
	var radial := velocity.dot(up)
	var t := tangent_vel - up * tangent_vel.dot(up)
	velocity = t + up * radial

func get_tangent_velocity() -> Vector3:
	return velocity - up * velocity.dot(up)

## Smoothly turns the body to face `dir` (tangent to the surface). model faces -Z.
func face_direction(dir: Vector3, turn_speed: float, delta: float) -> void:
	var fwd := dir - up * dir.dot(up)
	if fwd.length_squared() < 0.0001:
		return
	fwd = fwd.normalized()
	var target := Basis.looking_at(fwd, up)
	var cur := global_transform.basis.orthonormalized()
	var q := cur.get_rotation_quaternion().slerp(target.get_rotation_quaternion(), clampf(turn_speed * delta, 0.0, 1.0))
	global_transform.basis = Basis(q)

func do_jump(strength: float = -1.0) -> void:
	var s := jump_velocity if strength < 0.0 else strength
	velocity = get_tangent_velocity() + up * s

## Snaps the body onto the surface at dir (used for spawning and teleporting).
func place_on_planet(dir: Vector3, forward_hint: Vector3 = Vector3.FORWARD, height_offset: float = 0.05) -> void:
	if planet == null:
		return
	var xf := planet.surface_transform(dir, forward_hint)
	xf.origin += xf.basis.y * height_offset
	global_transform = xf
	up = xf.basis.y
	up_direction = up
	velocity = Vector3.ZERO

func teleport_to_dir(dir: Vector3) -> void:
	place_on_planet(dir, global_transform.basis.z * -1.0)

func current_dir() -> Vector3:
	return planet.dir_of(global_position) if planet else Vector3.UP

## Forward (-Z) projected on the tangent plane.
func surface_forward() -> Vector3:
	var f := -global_transform.basis.z
	f -= up * f.dot(up)
	return f.normalized() if f.length_squared() > 0.0001 else Vector3.FORWARD
