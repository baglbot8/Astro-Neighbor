class_name CrashAsteroid
extends Node3D
## The rock that knocks your ship off course (docs/CORE_LOOP.md, "Knocked off course"). Procedural,
## built once, driven entirely by `CrashIntro`.
##
## CUTE, NOT SCARY. A lumpy space potato a little under half the rocket's height (1.3 m across
## against the 3.2 m hull), not a flaming doom rock: no fire, no glowing cracks, no spikes. It bonks
## the nose, spins away and is never seen again.
##
## SHAPE follows the shipped rocks (docs/STYLE_GUIDE.md "Bushes/rocks: faceted, not perfect spheres"
## and "Shape language corrections"): `PlanetMeshKit.faceted_blob` - flat facets, darker down-facing
## faces - squashed into an ellipsoid, one sunk shoulder lump so the outline is not a ball, and two
## pressed-in craters (a dark dish inside a lighter rim), the same recipe as
## src/decorations/items/meteor_rock.gd. Surface: the shared R2.9 rock microsurface
## (`PlanetPropMeshes.rock_material`), so it reads as stone rather than plastic at 6-14 m.
##
## COLOUR is the meteor rock's lavender-grey family (#9c94b4), pulled darker: in full space sun the
## lit face of #9c94b4 clipped past the blown-highlight line on a first look, and a grey with S ~0.15
## can never trip the saturation gates.

## 1.6 m across with the squash. Round 1's 0.62 read well AT the bonk but was a small dark fleck
## for the second before it, in the top corner of a 1280x720 frame - smaller still on a phone.
const RADIUS := 0.72
## Squash of the main mass: wider than tall, so it tumbles like a potato and not a marble.
const SQUASH := Vector3(1.14, 0.84, 1.0)
const BODY := Color("#8a839b")
const BODY_LIGHT := Color("#a29ab1")
const BODY_DARK := Color("#5b556d")
## The trailing dust: a few painted puffs, not a particle soup (the rocket's own puff language).
const DUST_LIT := Color("#a39cb0")
const DUST_SHADE := Color("#57516a")
## A visual layer nothing else in the project uses (planet.gd puts water on layer 6). CrashIntro's
## camera-mounted fill light is culled to it, so the fill lights this rock and nothing else.
const FILL_LAYER := 20

var _body: MeshInstance3D
var _dust: GPUParticles3D


func _ready() -> void:
	_build_body()
	_build_dust()


## Dust trail on/off. It emits in WORLD space, so the puffs hang where the rock has been.
func set_trail(on: bool) -> void:
	if _dust != null:
		_dust.emitting = on


## Makes the trail's puffs travel at `v` (world space) - the velocity of whatever frame the camera is
## riding in - so on screen they hang where the rock has been. With the camera tracking the ship, a
## puff left still in the world slides past the rock the way the ship is flying: the round 2 redo's
## first pass had the trail LEADING the rock in as a scatter of white dots across its face.
func set_trail_drift(v: Vector3) -> void:
	if _dust == null:
		return
	var pm := _dust.process_material as ParticleProcessMaterial
	var s := v.length()
	if s < 0.01:
		pm.direction = Vector3.UP
		pm.spread = 180.0
		pm.initial_velocity_min = 0.15
		pm.initial_velocity_max = 0.45
		pm.damping_min = 0.4
		pm.damping_max = 0.8
		return
	pm.direction = v / s
	# 4 deg of spread at the ship's 6 m/s is ~0.4 m/s of sideways scatter - about round 1's drift.
	pm.spread = 4.0
	pm.initial_velocity_min = s - 0.3
	pm.initial_velocity_max = s + 0.3
	pm.damping_min = 0.0
	pm.damping_max = 0.0


func _build_body() -> void:
	var kit := PlanetMeshKit.new()
	# Main mass: subdivision 2 = 320 facets, enough to read as carved stone at 1.3 m and still cheap.
	kit.faceted_blob(Vector3.ZERO, RADIUS, BODY, SQUASH, 2, 0.26, 3.7)
	# One sunk shoulder and a knuckle on the far side break the outline without making it a cluster.
	kit.faceted_blob(Vector3(0.40, -0.16, 0.20), RADIUS * 0.50, BODY.lerp(BODY_DARK, 0.35),
		Vector3(1.0, 0.82, 0.92), 1, 0.22, 9.1)
	kit.faceted_blob(Vector3(-0.34, 0.20, -0.26), RADIUS * 0.38, BODY_LIGHT, Vector3.ONE, 1, 0.24, 17.3)
	# Two craters pressed into the upper faces: a light raised rim round a dark sunken dish, sunk far
	# enough that the faceted shell never pokes back through the rim.
	var craters := [
		[Vector3(-0.18, 0.78, 0.60), 0.20],
		[Vector3(0.66, 0.40, -0.52), 0.15],
	]
	for c: Array in craters:
		var d: Vector3 = (c[0] as Vector3).normalized()
		var r: float = c[1]
		var p := d * RADIUS * SQUASH * 0.90
		var b := axis_basis(d)
		kit.lathe(PackedVector2Array([Vector2(0.0, -r * 0.35), Vector2(r * 0.66, -r * 0.20),
			Vector2(r, 0.05)]), 10, Transform3D(b, p), BODY_DARK)
		kit.lathe(PackedVector2Array([Vector2(r, 0.05), Vector2(r * 1.22, 0.10),
			Vector2(r * 1.30, 0.0)]), 10, Transform3D(b, p), BODY_LIGHT)
	_body = MeshInstance3D.new()
	_body.name = "Body"
	_body.mesh = kit.commit()
	_body.material_override = PlanetPropMeshes.rock_material()
	# Also on FILL_LAYER, which only CrashIntro's camera-mounted fill light lights (see there).
	_body.layers = 1 | (1 << (FILL_LAYER - 1))
	add_child(_body)


## The trail emitter is top-level and kept unrotated on the rock's centre: a GPUParticles3D sends its
## puffs out along its OWN basis even in world coordinates, and as a plain child it spun with the
## rock, scattering the drift `set_trail_drift` asks for in every direction.
func _process(_delta: float) -> void:
	if _dust != null and visible:
		_dust.global_transform = Transform3D(Basis.IDENTITY, global_position)


func _build_dust() -> void:
	_dust = GPUParticles3D.new()
	_dust.name = "DustTrail"
	_dust.top_level = true
	_dust.amount = 14
	_dust.lifetime = 1.1
	_dust.local_coords = false
	_dust.emitting = false
	_dust.visibility_aabb = AABB(Vector3(-12.0, -12.0, -12.0), Vector3(24.0, 24.0, 24.0))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = RADIUS * 0.7
	pm.spread = 180.0
	pm.initial_velocity_min = 0.15
	pm.initial_velocity_max = 0.45
	pm.gravity = Vector3.ZERO
	pm.damping_min = 0.4
	pm.damping_max = 0.8
	pm.scale_min = 0.7
	pm.scale_max = 1.15
	var grow := Curve.new()
	grow.add_point(Vector2(0.0, 0.35))
	grow.add_point(Vector2(0.35, 1.0))
	grow.add_point(Vector2(1.0, 0.0))
	var grow_t := CurveTexture.new()
	grow_t.curve = grow
	pm.scale_curve = grow_t
	_dust.process_material = pm
	var puff := QuadMesh.new()
	puff.size = Vector2(0.55, 0.55)
	puff.material = RocketModel.make_puff_material(DUST_LIT, DUST_SHADE, 0.8, 0.8)
	_dust.draw_pass_1 = puff
	add_child(_dust)


## A basis whose +Y points along `d` (lathe profiles revolve about local Y).
static func axis_basis(d: Vector3) -> Basis:
	var y := d.normalized()
	var ref := Vector3.UP if absf(y.dot(Vector3.UP)) < 0.95 else Vector3.RIGHT
	var x := ref.cross(y).normalized()
	var z := x.cross(y).normalized()
	return Basis(x, y, z)
