extends DecoItem
## Oil-Can Lamp (Tinker Workshop, Bolt's set) - a big old orange oil can on a brass cog plinth. Where the
## spout used to be, a steel neck bends forward into a riveted wire cage holding one warm bulb. Steel
## bands with bolt heads, a carry handle, and a little brass cog badge on the front.

const BRASS := Color("#c9a35e")
const BRASS_DARK := Color("#a5824a")
const RIVET := Color("#dcc48e")
const STEEL := Color("#9aa3b0")
const STEEL_DARK := Color("#6d7686")
const ORANGE := Color("#c79469")
## The bulb's baked colour is a dim amber: the glow shader scales a lit core up to its fixed cap whatever the
## colour's own brightness (cap_display), so at night it lights the same warm hue at full strength, while by day
## (20% emission) the unlit glass reads darker than the night bulb - not a pale bulb that sunlight outshines.
const BULB := Color("#c0a16c")
const BULB_AT := Vector3(0.0, 1.0, -0.14)
## The wire cage round the bulb: big bulb, thin wires, so the lit glass - not the wire - is what reads at night.
const CAGE_R := 0.115


func _init() -> void:
	footprint = 0.45
	collide_radius = 0.22
	collide_height = 1.05


func _build() -> void:
	var kit := DecoKit.new()
	var metal := DecoKit.new()
	# --- the cog plinth --------------------------------------------------------------------------
	metal.extrude(_cog_poly(0.2, 0.035, 9), 0.06,
		BRASS, Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-90.0)), Vector3(0.0, 0.03, 0.0)))
	for i in 6:
		var a := TAU * float(i) / 6.0
		_rivet(kit, Vector3(cos(a) * 0.19, 0.062, sin(a) * 0.19), Vector3.UP, 0.014)
	# --- the can: a painted body with a domed shoulder and two riveted steel bands -------------------
	kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.06), Vector2(0.165, 0.06), Vector2(0.175, 0.08), Vector2(0.175, 0.47), Vector2(0.16, 0.52),
		Vector2(0.1, 0.6), Vector2(0.06, 0.63), Vector2(0.0, 0.63)]), 18, Transform3D.IDENTITY, ORANGE)
	for y in [0.11, 0.44]:
		metal.torus(Vector3(0.0, y, 0.0), 0.177, 0.016, STEEL_DARK, Basis.IDENTITY, 18, 4)
		for i in 5:
			var a2 := TAU * float(i) / 5.0 + 0.3
			var o := Vector3(cos(a2), 0.0, sin(a2))
			_rivet(kit, o * 0.19 + Vector3(0.0, y, 0.0), o, 0.013)
	# brass cog badge on the front of the can
	metal.extrude(_cog_poly(0.055, 0.016, 7), 0.02, BRASS_DARK,
		Transform3D(Basis.IDENTITY, Vector3(0.0, 0.28, -0.178)))
	_rivet(kit, Vector3(0.0, 0.28, -0.192), Vector3.FORWARD, 0.016)
	# --- carry handle arching over the back ---------------------------------------------------------
	JungleMeshes.tube(metal, PackedVector3Array([Vector3(-0.12, 0.54, 0.06), Vector3(-0.1, 0.7, 0.1),
		Vector3(0.0, 0.76, 0.12), Vector3(0.1, 0.7, 0.1), Vector3(0.12, 0.54, 0.06)]),
		PackedFloat32Array([0.016]), PackedColorArray([STEEL]), 6, false)
	# --- the neck where the spout was, bending forward to the cage ---------------------------------
	metal.lathe(PackedVector2Array([Vector2(0.0, 0.62), Vector2(0.06, 0.62), Vector2(0.05, 0.68),
		Vector2(0.0, 0.68)]), 12, Transform3D.IDENTITY, BRASS_DARK)
	JungleMeshes.tube(metal, PackedVector3Array([Vector3(0.0, 0.66, 0.0), Vector3(0.0, 0.8, -0.02),
		Vector3(0.0, 0.875, -0.08), Vector3(0.0, 0.9, -0.14)]), PackedFloat32Array([0.03, 0.028, 0.026, 0.026]),
		PackedColorArray([STEEL]), 8, false)
	# socket under the bulb
	metal.lathe(PackedVector2Array([Vector2(0.0, -0.02), Vector2(0.05, -0.02), Vector2(0.055, 0.04),
		Vector2(0.0, 0.04)]), 12, Transform3D(Basis.IDENTITY, BULB_AT + Vector3(0.0, -0.1, 0.0)), BRASS)
	# wire cage: four ribs and a hoop round the bulb, a bolt head on top
	for i in 4:
		var a3 := TAU * float(i) / 4.0 + PI / 4.0
		var pts := PackedVector3Array()
		for k in 5:
			var t := float(k) / 4.0
			var ang := lerpf(-1.25, 1.35, t)
			pts.append(BULB_AT + Vector3(cos(a3) * cos(ang) * CAGE_R, sin(ang) * CAGE_R + 0.005, sin(a3) * cos(ang) * CAGE_R))
		JungleMeshes.tube(metal, pts, PackedFloat32Array([0.0055]), PackedColorArray([STEEL_DARK]), 4, false)
	metal.torus(BULB_AT, CAGE_R, 0.0065, STEEL_DARK, Basis.IDENTITY, 14, 3)
	_rivet(kit, BULB_AT + Vector3(0.0, CAGE_R + 0.005, 0.0), Vector3.UP, 0.02, BRASS)
	add_body(kit.commit())
	add_metal(metal.commit())

	var glow := DecoKit.new()
	glow.sphere(BULB_AT, 0.095, BULB, Vector3(1.0, 1.08, 1.0), 12)
	add_glow(glow.commit(), 3.6, "Bulb", 0.0, 0.0)
	# No OmniLight on purpose: at night a lamp light turns nearby crochet (toon) surfaces black in stitch-row
	# stripes - measured 2026-10-21 on the existing Reading Lamp and Cosmic Mushrooms too, both renderers, and
	# gone the moment the light is removed. Instead the lit part is driven to the glow shader's core cap (so it is
	# brighter at night than by day), a camera-facing halo sits round it and a strong pool lights the ground.
	_halo(BULB_AT, 0.62, Color("#f2a24a"), 0.6, 0.16)
	add_ground_glow(1.9, Color("#e8bd7c"), 0.55)


## A round bolt head (the set's rivet motif) at `p`, domed along `n`.
func _rivet(kit: DecoKit, p: Vector3, n: Vector3, r: float, col: Color = RIVET) -> void:
	kit.rbox(p, Vector3(r * 2.0, r * 0.9, r * 2.0), r, col, DecoKit.axis_basis(n), 0)


## The set's cog outline: square-shouldered trapezoid teeth, four points a tooth (a third cheaper than
## DecoKit.gear_poly, and a crisper, machined read).
static func _cog_poly(r: float, tooth: float, teeth: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	var step := TAU / float(teeth)
	for i in teeth:
		var a0 := step * float(i)
		for f in [[0.0, r], [0.16, r + tooth], [0.44, r + tooth], [0.6, r]]:
			var a: float = a0 + step * float(f[0])
			out.append(Vector2(cos(a), sin(a)) * float(f[1]))
	return out


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
