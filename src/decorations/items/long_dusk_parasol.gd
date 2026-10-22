extends DecoItem
## Sunset Parasol (Long Dusk set, Fen) - a wide parasol striped in dusk orange and sand, its rim hung
## with the set's woven band, over a little round clay table (the band again round its apron) laid
## with a clay jug and two cups. You can stand under it; only the table blocks.

const CLAY := Color("#ba8d76")
const CLAY_DARK := Color("#9c7a68")
const CLAY_LIGHT := Color("#d2a88e")
const SAND := Color("#e2c6a0")
const SLATE := Color("#7889a3")
const SUNSET := Color("#d99d78")
const RIM_R := 1.0
const APEX_Y := 2.12
const MID_Y := 2.02
const RIM_Y := 1.82
const WEDGES := 12
const TABLE_Y := 0.5


func _init() -> void:
	footprint = 1.0
	collide_radius = 0.42
	collide_height = 0.55


func _build() -> void:
	var kit := DecoKit.new()
	# --- the table: a flared clay pedestal and a round top with a woven apron ----------------------------
	kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.24, 0.0), Vector2(0.23, 0.05), Vector2(0.12, 0.12), Vector2(0.085, 0.28),
		Vector2(0.11, 0.38), Vector2(0.35, 0.43), Vector2(0.385, 0.47), Vector2(0.375, TABLE_Y), Vector2(0.0, TABLE_Y)]),
		18, Transform3D.IDENTITY, CLAY)
	_weave_ring(kit, Vector3(0.0, 0.452, 0.0), 0.385, 0.055, 12)
	kit.disc(Vector3(0.0, TABLE_Y + 0.002, 0.0), 0.3, SAND, Basis.IDENTITY, 18)
	# a jug and two cups
	var jug := Vector3(0.14, TABLE_Y, -0.08)
	kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.06, 0.0), Vector2(0.085, 0.07), Vector2(0.07, 0.15), Vector2(0.04, 0.19),
		Vector2(0.05, 0.22), Vector2(0.0, 0.215)]), 12, Transform3D(Basis.IDENTITY, jug), CLAY_LIGHT)
	kit.torus(jug + Vector3(0.0, 0.07, 0.0), 0.087, 0.008, SLATE, Basis.IDENTITY, 12, 3)
	kit.torus(jug + Vector3(0.085, 0.12, 0.0), 0.04, 0.011, CLAY_LIGHT, Basis(Vector3.RIGHT, deg_to_rad(90.0)), 8, 3)
	for cp in [Vector3(-0.15, TABLE_Y, -0.1), Vector3(-0.04, TABLE_Y, 0.17)]:
		kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.03, 0.0), Vector2(0.045, 0.065), Vector2(0.036, 0.065),
			Vector2(0.0, 0.055)]), 10, Transform3D(Basis.IDENTITY, cp), CLAY_DARK)
	# --- the pole, a collar, the ribs and a finial ------------------------------------------------------
	kit.bar(Vector3(0.0, TABLE_Y, 0.0), Vector3(0.0, APEX_Y + 0.03, 0.0), 0.026, CLAY_DARK, 8)
	kit.torus(Vector3(0.0, 1.62, 0.0), 0.035, 0.016, CLAY_DARK, Basis.IDENTITY, 10, 3)
	for i in 6:
		var a := TAU * (float(i) + 0.5) / 6.0
		kit.bar(Vector3(0.0, 1.62, 0.0), Vector3(cos(a) * 0.92, RIM_Y - 0.0, sin(a) * 0.92), 0.011, CLAY_DARK, 6)
	kit.cone(Vector3(0.0, APEX_Y - 0.01, 0.0), 0.05, 0.0, 0.11, CLAY, Basis.IDENTITY, 8)
	# --- the canopy: twelve stripes, a lighter top and a shaded underside ---------------------------------
	for w in WEDGES:
		var col: Color = SUNSET if w % 2 == 0 else SAND
		for s in 2:
			var a0 := TAU * (float(w) + float(s) * 0.5) / float(WEDGES)
			var a1 := TAU * (float(w) + float(s + 1) * 0.5) / float(WEDGES)
			var apex := Vector3(0.0, APEX_Y, 0.0)
			var m0 := _ring(0.5, MID_Y, a0)
			var m1 := _ring(0.5, MID_Y, a1)
			var r0 := _ring(RIM_R, RIM_Y, a0)
			var r1 := _ring(RIM_R, RIM_Y, a1)
			for side in 2:
				var c: Color = col if side == 0 else col.darkened(0.28)
				var want := Vector3.UP if side == 0 else Vector3.DOWN
				_tri(kit, apex, m0, m1, c, want)
				_tri(kit, m0, r0, r1, c, want)
				_tri(kit, m0, r1, m1, c, want)
	# --- the woven band hung round the rim ----------------------------------------------------------
	kit.torus(Vector3(0.0, RIM_Y, 0.0), RIM_R, 0.014, CLAY_DARK, Basis.IDENTITY, 24, 3)
	var tabs := 20
	for i in tabs:
		var a2 := TAU * (float(i) + 0.5) / float(tabs)
		var o := Vector3(cos(a2), 0.0, sin(a2))
		var lift := 0.012 * (1.0 if i % 2 == 0 else -1.0)
		var tc: Color = SLATE if i % 2 == 0 else SAND
		kit.rbox(o * (RIM_R * cos(PI / float(tabs))) + Vector3(0.0, RIM_Y - 0.05 + lift, 0.0),
			Vector3(TAU * RIM_R / float(tabs) * 1.02, 0.085, 0.024), 0.01, tc, Basis(Vector3.UP, -a2 - PI * 0.5), 0)
	add_body(kit.commit())


func _ring(r: float, y: float, a: float) -> Vector3:
	return Vector3(cos(a) * r, y, sin(a) * r)


## One single-sided triangle whose lit face points along `want` (the canopy top up, its underside down).
func _tri(kit: DecoKit, a: Vector3, b: Vector3, c: Vector3, col: Color, want: Vector3) -> void:
	if (c - a).cross(b - a).dot(want) < 0.0:
		kit.triangle(a, c, b, col, false)
	else:
		kit.triangle(a, b, c, col, false)


## LONG DUSK MOTIF - the woven band: over-under tabs in slate and sand round a clay curve, held between
## two dark clay cords. Every piece in the set wears one.
func _weave_ring(kit: DecoKit, c: Vector3, r: float, h: float, n: int) -> void:
	kit.torus(c - Vector3(0.0, h * 0.5, 0.0), r, h * 0.13, CLAY_DARK, Basis.IDENTITY, int(float(n) * 1.5), 3)
	kit.torus(c + Vector3(0.0, h * 0.5, 0.0), r, h * 0.13, CLAY_DARK, Basis.IDENTITY, int(float(n) * 1.5), 3)
	for i in n:
		var a := TAU * (float(i) + 0.5) / float(n)
		var o := Vector3(cos(a), 0.0, sin(a))
		var lift := h * 0.14 * (1.0 if i % 2 == 0 else -1.0)
		var col: Color = SLATE if i % 2 == 0 else SAND
		kit.rbox(c + o * r + Vector3(0.0, lift, 0.0), Vector3(TAU * r / float(n) * 1.02, h * 0.62, h * 0.3), h * 0.1,
			col, Basis(Vector3.UP, -a - PI * 0.5), 0)
