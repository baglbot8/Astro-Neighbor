extends DecoItem
## Toadstool Floor Lamp (Glowshroom Hollow, Zorp's set) - a tall pale toadstool, taller than the
## astronaut, with a bulb at its foot, a drooping skirt round the stem and a broad spotted violet cap. The
## cap itself lights up after dark, with blue gills glowing underneath and a pool of light on the ground.

const CAP := Color("#a08ad0")
## The big cap's baked glow colour: CAP's hue a shade darker. The glow shader scales a lit core up to its fixed cap
## whatever the colour's own brightness, so after dark the cap lights up full, while by day (20% emission) it reads
## as a plain violet cap, darker than at night.
const CAP_LIT := Color("#8875b1")
const STEM := Color("#dcd3e3")
const STEM_DARK := Color("#bdb2cc")
const SPOT := Color("#ece4f2")
const GILL := Color("#7fc8f0")
const MOSS := Color("#6a7fa8")
const CAP_Y := 1.42
const CAP_R := 0.44
const CAP_H := 0.27


func _init() -> void:
	footprint = 0.5
	collide_radius = 0.24
	collide_height = 1.7


func _build() -> void:
	var kit := DecoKit.new()
	var glow := DecoKit.new()
	# --- a mossy footing and the bulbous foot of the stem ----------------------------------------------
	kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.27, 0.0), Vector2(0.25, 0.025), Vector2(0.0, 0.03)]), 16,
		Transform3D.IDENTITY, MOSS)
	kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.15, 0.0), Vector2(0.17, 0.05), Vector2(0.15, 0.12), Vector2(0.09, 0.2),
		Vector2(0.07, 0.5), Vector2(0.06, 1.0), Vector2(0.065, CAP_Y - 0.05), Vector2(0.1, CAP_Y - 0.02), Vector2(0.0, CAP_Y - 0.01)]),
		16, Transform3D.IDENTITY, STEM)
	# the skirt (ring) part way up, drooping
	kit.lathe(PackedVector2Array([Vector2(0.065, 1.08), Vector2(0.13, 1.03), Vector2(0.15, 1.0), Vector2(0.14, 1.02),
		Vector2(0.065, 1.12)]), 16, Transform3D.IDENTITY, STEM_DARK)
	# two baby toadstools at the foot
	for m in [[Vector3(0.2, 0.0, -0.12), 0.07, 0.12, 0.4], [Vector3(-0.17, 0.0, -0.16), 0.055, 0.09, 1.9]]:
		var b: Vector3 = m[0]
		var r: float = m[1]
		var h: float = m[2]
		kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(r * 0.45, 0.0), Vector2(r * 0.32, h * 0.6), Vector2(r * 0.3, h),
			Vector2(0.0, h)]), 8, Transform3D(Basis.IDENTITY, b), STEM)
		_cap(kit, glow, b + Vector3(0.0, h, 0.0), r, r * 0.7, CAP, 3, m[3], 12)
	# spots on the big cap (the cap itself is part of the glow below)
	for k in 11:
		var th := lerpf(0.22, 1.2, fmod(float(k) * 0.618 + 0.1, 1.0))
		var ph := 0.3 + float(k) * 2.39996
		var n := Vector3(sin(th) * cos(ph) / CAP_R, cos(th) / CAP_H, sin(th) * sin(ph) / CAP_R).normalized()
		var p := Vector3(CAP_R * sin(th) * cos(ph), CAP_Y + CAP_H * cos(th), CAP_R * sin(th) * sin(ph))
		var s := 0.04 + 0.02 * fmod(float(k) * 0.37, 1.0)
		kit.rbox(p, Vector3(s * 2.0, s * 0.5, s * 2.0), s, SPOT, DecoKit.axis_basis(n), 0)
	add_body(kit.commit())
	add_glow(glow.commit(), 2.0, "Gills", 0.5, 0.25)

	# --- the big cap: it is the lamp, so its whole shell glows, with blue gills under it ----------------------
	var shade := DecoKit.new()
	var prof := PackedVector2Array([Vector2(CAP_R * 0.95, -CAP_H * 0.1)])
	for i in 9:
		var a := PI * 0.5 * float(i) / 8.0
		prof.append(Vector2(cos(a) * CAP_R, sin(a) * CAP_H))
	shade.lathe(prof, 26, Transform3D(Basis.IDENTITY, Vector3(0.0, CAP_Y, 0.0)), CAP_LIT)
	add_glow(shade.commit(), 3.8, "Cap", 0.0, 0.0)
	var gills := DecoKit.new()
	gills.lathe(PackedVector2Array([Vector2(0.09, 0.0), Vector2(CAP_R * 0.55, -CAP_H * 0.06), Vector2(CAP_R * 0.94, -CAP_H * 0.1)]), 24,
		Transform3D(Basis.IDENTITY, Vector3(0.0, CAP_Y, 0.0)), GILL)
	add_glow(gills.commit(), 3.2, "CapGills", 0.0, 0.0)
	# No OmniLight on purpose: at night a lamp light turns nearby crochet (toon) surfaces black in stitch-row
	# stripes - measured 2026-10-21 on the existing Reading Lamp and Cosmic Mushrooms too, both renderers, and
	# gone the moment the light is removed. Instead the lit part is driven to the glow shader's core cap (so it is
	# brighter at night than by day), a camera-facing halo sits round it and a strong pool lights the ground.
	_halo(Vector3(0.0, CAP_Y + 0.09, 0.0), 0.95, Color("#b4a2ee"), 0.55, 0.5)
	add_ground_glow(2.3, Color("#8fb0ec"), 0.55)


## A spotted mushroom cap (the set's motif) whose rim sits at `base`, with glowing blue gills under it.
func _cap(kit: DecoKit, glow: DecoKit, base: Vector3, r: float, h: float, col: Color, spots: int, seed_a: float, segs: int) -> void:
	var prof := PackedVector2Array([Vector2(r * 0.96, -h * 0.08)])
	for i in 7:
		var a := PI * 0.5 * float(i) / 6.0
		prof.append(Vector2(cos(a) * r, sin(a) * h))
	kit.lathe(prof, segs, Transform3D(Basis.IDENTITY, base), col)
	glow.lathe(PackedVector2Array([Vector2(r * 0.22, 0.0), Vector2(r * 0.6, -h * 0.05), Vector2(r * 0.95, -h * 0.08)]), segs,
		Transform3D(Basis.IDENTITY, base), GILL)
	for k in spots:
		var th := lerpf(0.3, 1.1, fmod(float(k) * 0.618 + 0.2, 1.0))
		var ph := seed_a + float(k) * 2.39996
		var n := Vector3(sin(th) * cos(ph) / r, cos(th) / h, sin(th) * sin(ph) / r).normalized()
		var p := base + Vector3(r * sin(th) * cos(ph), h * cos(th), r * sin(th) * sin(ph))
		var s := r * 0.16
		kit.rbox(p, Vector3(s * 2.0, s * 0.55, s * 2.0), s, SPOT, DecoKit.axis_basis(n), 0)


## A soft additive glow disc that always faces the camera, round the lit part. It rides the ground-glow list,
## so DecoItem fades it in with the night and set_ghost_mode hides it on the placement hologram. It is the
## halo on Compatibility and the phone, where the environment's bloom is off (environment.gd _low_power).
## Measured 2026-10-22 (Compatibility, 22:30): the glow shader's lit core alone stops near V0.83-0.87 at gameplay
## distance whatever the strength, barely above a sunlit cap, so this additive disc is what makes the lamp read as lit.
func _halo(pos: Vector3, radius: float, col: Color, alpha: float, lift: float) -> void:
	var h := add_ground_glow(radius, col, alpha)
	h.name = "GlowHalo"
	(h.mesh as QuadMesh).orientation = PlaneMesh.FACE_Z
	var m := h.material_override as StandardMaterial3D
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	# Pushed `lift` metres toward the camera (grow moves the quad along its normal, which the billboard turns to
	# face the camera), so it lies over the lit part as bloom would. A disc through the middle of the lamp would be
	# hidden exactly where the light is brightest; switching the depth test off instead would shine it through
	# the planet from a lamp on the far side.
	m.grow = true
	m.grow_amount = lift
	h.position = pos
