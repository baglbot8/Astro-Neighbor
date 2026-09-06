class_name JetPuffs
extends Node3D
## The jetpack's exhaust: a fixed ring buffer of MESH puffs, spawned at the backpack nozzles and
## left behind in world space (docs/STYLE_GUIDE.md R2.8).
##
## Why meshes and not a GPUParticles3D: R2.8 asks for *"soft cartoon puffs from the pack's nozzles
## — the same painted-puff language as the rocket's exhaust, not a particle soup"*, and
## docs/QUALITY_BAR.md fails the jetpack "if the backpack puffs are a particle soup rather than
## painted cartoon puffs". A small pool of quads that the script places, grows and fades by hand is
## the most direct way to guarantee that: every puff's size curve, drift and lifetime is authored
## rather than emergent, the plume looks identical in a capture as it does live (particles are
## simulated on the GPU and are not frame-deterministic under --write-movie), and PUFF_COUNT quads
## cost less than a particle system's dispatch.
##
## The node is `top_level`, so the puffs stay where they were born while the astronaut flies on —
## that trailing arc is most of the charm. It is a child of AstronautModel so it dies with the
## model and so NPC mannequins get one for free.
##
##     puffs.emit(nozzle.global_transform, player_velocity)   # one puff
##     puffs.tick(delta)                                      # every frame

const PUFF_SHADER := preload("res://src/player/jet_puff.gdshader")

## Pool size. At AstronautModel.PUFF_RATE * 2 nozzles * PUFF_LIFE = 16 * 2 * 0.62 = 20 live puffs,
## 22 leaves a margin for the ignition burst without ever recycling one that is still bright.
const PUFF_COUNT := 22
## Deliberately SHORT. The gameplay camera sits 6.5 m directly behind the astronaut and the plume is
## laid down along the flight path, so every puff drifts straight at the lens: at 0.75 s a landing
## approach ended with the last second of exhaust filling the frame and hiding the character.
const PUFF_LIFE := 0.62
## Metres. A puff leaves the nozzle about the size of the throat and swells to a soft ball.
## SCALE MATTERS: the first pass topped out at 0.30 m against a 0.79 m helmet, and from the gameplay
## camera the plume read as a dotted line of little white balls trailing the boots — the exact
## "bunch of balls" failure the style guide keeps calling out. At 0.56 m consecutive puffs overlap
## into one soft painted mass, which is the rocket-exhaust language R2.8 asks for, without any single
## puff being large enough to swallow the character when it drifts past the camera.
const PUFF_R0 := 0.15
const PUFF_R1 := 0.56
## Exhaust is a hint of a thing, not a wall. Below 1 the plume stays translucent enough to read the
## ground and the character's own shadow through it.
const PUFF_OPACITY := 0.80
## Speed out of the nozzle, and how fast that decays (soft exponential, so the plume is dense near
## the pack and diffuse behind it).
const PUFF_SPEED := 3.0
const PUFF_DAMP := 4.2
## Fraction of the astronaut's own velocity a puff inherits. Below 1 the plume drifts backwards
## relative to the player, which is what sells the sense of travelling forward.
const PUFF_INHERIT := 0.45
## Sideways scatter at birth, so the two nozzle plumes are not two straight lines.
const PUFF_SCATTER := 0.42
## Puffs keep drifting along the local "up" they were born with, so exhaust rises slightly instead
## of hanging in a dead line (the same fix the rocket needed for its landing smoke).
const PUFF_BUOYANCY := 0.55

var _mesh: QuadMesh
var _pool: Array[MeshInstance3D] = []
var _mats: Array[ShaderMaterial] = []
var _vel: PackedVector3Array
var _up: PackedVector3Array
var _age: PackedFloat32Array
var _spin: PackedFloat32Array
var _next: int = 0
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	name = "JetPuffs"
	top_level = true
	_vel = PackedVector3Array()
	_vel.resize(PUFF_COUNT)
	_up = PackedVector3Array()
	_up.resize(PUFF_COUNT)
	_age = PackedFloat32Array()
	_age.resize(PUFF_COUNT)
	_spin = PackedFloat32Array()
	_spin.resize(PUFF_COUNT)
	for i in PUFF_COUNT:
		_age[i] = 2.0        # > 1 means "dead"; nothing is visible until the first emit


func _ready() -> void:
	_mesh = QuadMesh.new()
	_mesh.size = Vector2(1.0, 1.0)
	for i in PUFF_COUNT:
		var mat := ShaderMaterial.new()
		mat.shader = PUFF_SHADER
		mat.set_shader_parameter("opacity", PUFF_OPACITY)
		var mi := MeshInstance3D.new()
		mi.name = "Puff%d" % i
		mi.mesh = _mesh
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.visible = false
		add_child(mi)
		_pool.append(mi)
		_mats.append(mat)


## Spawns one puff at a nozzle. `nozzle` is the nozzle marker's global transform (its -Y is the
## exhaust direction); `carrier_vel` is the astronaut's world velocity.
func emit(nozzle: Transform3D, carrier_vel: Vector3) -> void:
	if _pool.is_empty():
		return
	var i := _next
	_next = (_next + 1) % PUFF_COUNT
	var dir := -nozzle.basis.y.normalized()
	var side := nozzle.basis.x.normalized()
	var fwd := nozzle.basis.z.normalized()
	var scatter := side * _rng.randf_range(-PUFF_SCATTER, PUFF_SCATTER) + fwd * _rng.randf_range(-PUFF_SCATTER, PUFF_SCATTER)
	_vel[i] = (dir + scatter).normalized() * PUFF_SPEED * _rng.randf_range(0.82, 1.18) + carrier_vel * PUFF_INHERIT
	_up[i] = nozzle.basis.y.normalized()
	_age[i] = 0.0
	_spin[i] = _rng.randf_range(0.0, TAU)
	var mi := _pool[i]
	mi.global_position = nozzle.origin + dir * 0.045
	mi.visible = true


## Advances every live puff. Cheap: PUFF_COUNT transform writes and one uniform each.
func tick(delta: float) -> void:
	var damp := exp(-PUFF_DAMP * delta)
	for i in PUFF_COUNT:
		if _age[i] >= 1.0:
			if _pool[i].visible:
				_pool[i].visible = false
			continue
		_age[i] += delta / PUFF_LIFE
		var v := _vel[i] * damp + _up[i] * (PUFF_BUOYANCY * delta)
		_vel[i] = v
		var mi := _pool[i]
		mi.global_position += v * delta
		var a := clampf(_age[i], 0.0, 1.0)
		# Swell fast, then ease: a puff is mostly at full size for the second half of its life,
		# which is what makes overlapping puffs merge into one painted mass.
		var s: float = lerpf(PUFF_R0, PUFF_R1, 1.0 - pow(1.0 - a, 2.2))
		mi.scale = Vector3(s, s, s)
		mi.rotation.z = _spin[i]
		_mats[i].set_shader_parameter("age", a)
		if a >= 1.0:
			mi.visible = false


## True while any puff is still on screen (so the emitter can be idled without popping the plume).
func is_active() -> bool:
	for i in PUFF_COUNT:
		if _age[i] < 1.0:
			return true
	return false


## Hides every puff at once (planet change, teleport, style rebuild).
func clear_all() -> void:
	for i in PUFF_COUNT:
		_age[i] = 2.0
		if i < _pool.size():
			_pool[i].visible = false
