extends DecoItem
## Spore Lantern (Glowshroom Hollow, Zorp's set) - a glass jar of glowing blue spores on a short flared
## mushroom stem, with a spotted violet cap for a lid and a loop to carry it by. The spores drift up, then
## drift back down. Lights the ground blue at night.

const CAP := Color("#9a82cc")
const CAP_DARK := Color("#7a66ad")
const STEM := Color("#dcd3e3")
const STEM_DARK := Color("#bdb2cc")
const SPOT := Color("#ece4f2")
const GILL := Color("#7fc8f0")
const SPORE := Color("#8fd4f5")
const JAR_Y := 0.38
const JAR_TOP := 0.66

var _drift: Array[Node3D] = []


func _init() -> void:
	footprint = 0.4
	collide_radius = 0.2
	collide_height = 0.85


func _build() -> void:
	var kit := DecoKit.new()
	var glow := DecoKit.new()
	# --- the stem: a flared foot with four root nubs, a collar to hold the jar -------------------------
	kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.17, 0.0), Vector2(0.16, 0.035), Vector2(0.09, 0.09),
		Vector2(0.055, 0.2), Vector2(0.05, 0.31), Vector2(0.075, 0.35), Vector2(0.13, JAR_Y - 0.01), Vector2(0.0, JAR_Y)]),
		16, Transform3D.IDENTITY, STEM)
	for i in 4:
		var a := TAU * float(i) / 4.0 + 0.4
		kit.sphere(Vector3(cos(a) * 0.15, 0.02, sin(a) * 0.15), 0.045, STEM_DARK, Vector3(1.4, 0.6, 1.0), 8,
			Basis(Vector3.UP, -a))
	kit.torus(Vector3(0.0, JAR_Y + 0.005, 0.0), 0.13, 0.016, CAP_DARK, Basis.IDENTITY, 16, 4)
	kit.torus(Vector3(0.0, JAR_TOP - 0.01, 0.0), 0.12, 0.016, CAP_DARK, Basis.IDENTITY, 16, 4)
	# --- the lid: a spotted cap with glowing gills, and a carry loop -------------------------------------
	_cap(kit, glow, Vector3(0.0, JAR_TOP + 0.02, 0.0), 0.17, 0.11, CAP, 6, 0.7, 18)
	kit.torus(Vector3(0.0, JAR_TOP + 0.17, 0.0), 0.045, 0.013, STEM_DARK, Basis(Vector3.RIGHT, deg_to_rad(90.0)), 12, 4)
	add_body(kit.commit())
	add_glow(glow.commit(), 2.8, "Gills", 0.5, 0.25)

	# --- the jar ---------------------------------------------------------------------------------------
	var jar := DecoKit.new()
	jar.lathe(PackedVector2Array([Vector2(0.0, JAR_Y), Vector2(0.11, JAR_Y), Vector2(0.13, JAR_Y + 0.04), Vector2(0.13, JAR_TOP - 0.05),
		Vector2(0.11, JAR_TOP - 0.015), Vector2(0.0, JAR_TOP - 0.01)]), 18, Transform3D.IDENTITY, Color("#a9dcf2"))
	add_glass(jar.commit(), Color("#a9dcf2"), 0.28, "Jar")

	# --- spores: two little clouds drifting out of step ------------------------------------------------
	for c in 2:
		var p := pivot("Spores%d" % c, Vector3(0.0, JAR_Y + 0.12, 0.0))
		var sk := DecoKit.new()
		for k in 4:
			var a2 := TAU * float(k) / 4.0 + float(c) * 0.8
			var rr := 0.05 + 0.025 * float((k + c) % 2)
			sk.sphere(Vector3(cos(a2) * rr, 0.035 * float(k % 3) + 0.03 * float(c), sin(a2) * rr), 0.02 + 0.008 * float(k % 2),
				SPORE, Vector3.ONE, 8)
		add_glow(sk.commit(), 3.4, "Spore", 0.0, 0.0, 0.0, p)
		_drift.append(p)
	# No OmniLight on purpose: at night a lamp light turns nearby crochet (toon) surfaces black in stitch-row
	# stripes - measured 2026-10-21 on the existing Reading Lamp and Cosmic Mushrooms too, both renderers, and
	# gone the moment the light is removed. Instead the lit part is driven to the glow shader's core cap (so it is
	# brighter at night than by day), a camera-facing halo sits round it and a strong pool lights the ground.
	_halo(Vector3(0.0, (JAR_Y + JAR_TOP) * 0.5, 0.0), 0.55, Color("#8fd4f5"), 0.55, 0.18)
	add_ground_glow(1.7, Color("#7fc8f0"), 0.5)
	animate()


func _animate(time: float, _delta: float) -> void:
	for i in _drift.size():
		var t := time * 0.45 + float(i) * PI
		_drift[i].position.y = JAR_Y + 0.12 + sin(t) * 0.05
		_drift[i].rotation.y = time * (0.25 if i == 0 else -0.2)


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
