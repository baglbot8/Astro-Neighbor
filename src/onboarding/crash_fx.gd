class_name CrashFx
extends RefCounted
## Builders for the crash shot's effects. Static, node-returning, no state: `CrashIntro` owns every
## node these return and drives them on its own clock.
##
##   sparks()        one-shot burst at the bonk: short-lived warm glints, no gravity (it is space)
##   flash()         a small four-point star at the contact point, scaled in and out by the caller
##   chip(i)         a flat faceted flake of hull, in the rocket's own colour blocks
##   damage_smoke()  a trail of grey painted puffs from the engine skirt while the ship tumbles
##   wisp()          the thin "it's broken" smoke that rises off the rocket after it lands
##   dust_ring()     the touchdown ring, the same recipe as the pad's own (rocket_pad.gd _build_dust)
##
## CUTE, NOT SCARY (the brief): nothing here is fire. The sparks are a handful of warm glints that
## are gone in half a second; the smoke is soft painted puffs in the rocket's puff language
## (RocketModel.make_puff_material), the same material the exhaust and the pad dust use.
##
## BLOWN-HIGHLIGHT BUDGET. Additive sprites stack toward white against a dark starfield
## (rocket_pad.gd SPACE_FLAME_INTENSITY says the same about the plume), so the flash and sparks run
## at glow intensity 1.3-1.6, not the 2.0-2.6 the planet-side sparkles use.

const SPARK_COLOR := Color("#ffbf66")
const FLASH_COLOR := Color("#ffe0a0")
## Hull flakes in the crashed ship's own tones: its cream, rust and bare metal (CampaignData
## finish_stage 0 is the rusty, dirty rocket). Round 2 used the clean rocket's blocks, and its TEAL
## flake, lit side-on in the space sun, read as a flat blue polygon beside the hull (critic, f290).
const CHIP_COLORS: Array[Color] = [Color("#d8ccb2"), Color("#8e5b43"), Color("#8d97a6"), Color("#a8795c")]
const SMOKE_LIT := Color("#9d968d")
const SMOKE_SHADE := Color("#4b4744")
const WISP_LIT := Color("#b3ada4")
const WISP_SHADE := Color("#5d5853")


static func sparks() -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.name = "Sparks"
	p.amount = 34
	p.lifetime = 0.55
	p.one_shot = true
	p.explosiveness = 1.0
	p.local_coords = false
	p.emitting = false
	p.visibility_aabb = AABB(Vector3(-8.0, -8.0, -8.0), Vector3(16.0, 16.0, 16.0))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.12
	pm.direction = Vector3(0.0, 0.0, 1.0)
	pm.spread = 75.0
	pm.initial_velocity_min = 4.0
	pm.initial_velocity_max = 9.5
	pm.gravity = Vector3.ZERO
	pm.damping_min = 5.0
	pm.damping_max = 8.0
	pm.scale_min = 0.55
	pm.scale_max = 1.0
	var shrink := Curve.new()
	shrink.add_point(Vector2(0.0, 1.0))
	shrink.add_point(Vector2(0.6, 0.7))
	shrink.add_point(Vector2(1.0, 0.0))
	var shrink_t := CurveTexture.new()
	shrink_t.curve = shrink
	pm.scale_curve = shrink_t
	p.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(0.16, 0.16)
	q.material = MaterialLib.glow_sprite(SPARK_COLOR, 1.5, {"softness": 0.35, "core": 0.30})
	p.draw_pass_1 = q
	return p


## Aims the next burst: the sparks fly out along `normal` (world space).
static func aim_sparks(p: GPUParticles3D, normal: Vector3) -> void:
	var pm := p.process_material as ParticleProcessMaterial
	if pm != null and normal.length_squared() > 0.0001:
		pm.direction = normal.normalized()


static func flash() -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = "Flash"
	var q := QuadMesh.new()
	q.size = Vector2(1.5, 1.5)
	q.material = MaterialLib.glow_sprite(FLASH_COLOR, 1.3, {"points": 1.0, "softness": 0.28, "core": 0.22})
	mi.mesh = q
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visible = false
	return mi


## A chunky faceted flake of hull about 20 cm across. Half as flat as round 2's (0.32 -> 0.55 of its
## width deep), so it tumbles as a lump with a lit and a shaded side instead of flashing a flat face.
static func chip(i: int) -> MeshInstance3D:
	var kit := PlanetMeshKit.new()
	var col: Color = CHIP_COLORS[i % CHIP_COLORS.size()]
	kit.faceted_blob(Vector3.ZERO, 0.10, col, Vector3(1.25, 0.55, 1.0), 0, 0.38, 5.3 * float(i + 1))
	var mi := MeshInstance3D.new()
	mi.name = "Chip%d" % i
	mi.mesh = kit.commit()
	mi.material_override = PlanetPropMeshes.prop_material()
	mi.visible = false
	return mi


## A short cough of smoke thrown clear of the hull: few, small and quick, so it reads as "poof,
## poof" and is gone before the trailing camera could reach it. Round 2 threw 12 puffs of 0.48 m
## sideways and one drifted to within a few metres of the trailing camera - at T 8.1 a big soft grey
## disc in the corner that read as an out-of-focus blob (critic, f300). Now 7 of 0.34 m, a shorter
## life, and `CrashIntro` throws them AWAY from the camera, so they only ever shrink on screen.
static func damage_smoke() -> GPUParticles3D:
	var p := _puffs("DamageSmoke", 7, 0.75, SMOKE_LIT, SMOKE_SHADE, 0.34, 0.8)
	var pm := p.process_material as ParticleProcessMaterial
	pm.emission_sphere_radius = 0.18
	pm.spread = 24.0
	pm.initial_velocity_min = 2.0
	pm.initial_velocity_max = 3.2
	return p


static func wisp() -> GPUParticles3D:
	var p := _puffs("Wisp", 9, 2.6, WISP_LIT, WISP_SHADE, 0.46, 0.7)
	var pm := p.process_material as ParticleProcessMaterial
	pm.emission_sphere_radius = 0.18
	pm.spread = 14.0
	pm.initial_velocity_min = 0.45
	pm.initial_velocity_max = 0.8
	return p


## Points the smoke's drift (world space): backwards off the tumbling hull, or up off the landed one.
static func aim_puffs(p: GPUParticles3D, dir: Vector3) -> void:
	var pm := p.process_material as ParticleProcessMaterial
	if pm != null and dir.length_squared() > 0.0001:
		pm.direction = dir.normalized()


static func _puffs(node_name: String, amount: int, life: float, lit: Color, shade: Color,
		size: float, opacity: float) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.name = node_name
	p.amount = amount
	p.lifetime = life
	p.local_coords = false
	p.emitting = false
	p.visibility_aabb = AABB(Vector3(-20.0, -20.0, -20.0), Vector3(40.0, 40.0, 40.0))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.direction = Vector3.UP
	pm.gravity = Vector3.ZERO
	pm.damping_min = 0.3
	pm.damping_max = 0.6
	pm.scale_min = 0.75
	pm.scale_max = 1.25
	var grow := Curve.new()
	grow.add_point(Vector2(0.0, 0.3))
	grow.add_point(Vector2(0.3, 0.95))
	grow.add_point(Vector2(1.0, 1.4))
	var grow_t := CurveTexture.new()
	grow_t.curve = grow
	pm.scale_curve = grow_t
	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 1.0, 1.0, 0.0))
	grad.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	grad.add_point(0.10, Color(1.0, 1.0, 1.0, 1.0))
	grad.add_point(0.62, Color(1.0, 1.0, 1.0, 0.7))
	var grad_t := GradientTexture1D.new()
	grad_t.gradient = grad
	pm.color_ramp = grad_t
	p.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	q.material = RocketModel.make_puff_material(lit, shade, 0.78, opacity)
	p.draw_pass_1 = q
	return p


## The touchdown dust ring: the pad's own ring (rocket_pad.gd `_build_dust`, private to that file)
## at roughly half strength. At full strength, filmed from the crash's landing vantage (~10 m out,
## near the rig's height) rather than the pad arrival's high side camera, it rose into a brown cloud
## over the rocket's nose for 1.5 s (round 2, T 16.3-17.2) - a dirt explosion, not a bump.
## Place it at the deck with the pad's basis: the ring axis is local +Y.
static func dust_ring() -> GPUParticles3D:
	var d := GPUParticles3D.new()
	d.name = "TouchdownDust"
	d.amount = 30
	d.lifetime = 1.5
	d.one_shot = true
	d.explosiveness = 0.8
	d.local_coords = false
	d.emitting = false
	d.visibility_aabb = AABB(Vector3(-9.0, -3.0, -9.0), Vector3(18.0, 8.0, 18.0))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	pm.emission_ring_axis = Vector3.UP
	pm.emission_ring_radius = 1.35
	pm.emission_ring_inner_radius = 0.5
	pm.emission_ring_height = 0.05
	pm.direction = Vector3(0.0, 0.34, 0.0)
	pm.spread = 82.0
	pm.flatness = 0.82
	pm.initial_velocity_min = 2.4
	pm.initial_velocity_max = 4.4
	pm.gravity = Vector3.ZERO
	pm.damping_min = 1.6
	pm.damping_max = 2.8
	pm.scale_min = 0.7
	pm.scale_max = 1.25
	var grow := Curve.new()
	grow.add_point(Vector2(0.0, 0.4))
	grow.add_point(Vector2(0.4, 1.05))
	grow.add_point(Vector2(1.0, 1.35))
	var grow_t := CurveTexture.new()
	grow_t.curve = grow
	pm.scale_curve = grow_t
	var grad := Gradient.new()
	grad.set_color(0, Color(0.72, 0.66, 0.56, 0.0))
	grad.set_color(1, Color(0.50, 0.46, 0.42, 0.0))
	grad.add_point(0.07, Color(0.78, 0.72, 0.62, 1.0))
	grad.add_point(0.60, Color(0.60, 0.56, 0.50, 0.72))
	var grad_t := GradientTexture1D.new()
	grad_t.gradient = grad
	pm.color_ramp = grad_t
	d.process_material = pm
	var puff := QuadMesh.new()
	puff.size = Vector2(1.35, 1.35)
	puff.material = RocketModel.make_puff_material(Color("#a9997c"), Color("#5f5748"), 0.82, 0.95)
	d.draw_pass_1 = puff
	return d
