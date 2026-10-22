extends DecoItem
## Rock Basin Fountain (Chalk Terrace set, Grig) - water steps down three chalk bowls, very slowly. The
## smallest bowl sits high at the back on a two-tier stone column, the middle one lower on a single
## tier, and both pour into a wide stepped basin on the ground. Every bowl is terraced underneath like
## Grig's stairs, and the big basin has a groove carved round its wall. Sage scrub grows at its foot.

const CHALK := Color("#dcd0b2")
const CHALK_WARM := Color("#cdbe98")
const CHALK_SHADE := Color("#b8aa86")
const GROOVE := Color("#7f735d")
const SAGE := Color("#9fb08a")
const SAGE_DARK := Color("#7d8f6c")
const WATER := Color("#9cc4c4")
const SHINE := Color("#b8dcd8")
## Centres of the three bowls (ground level) - high at the back, low at the front.
const BASIN_C := Vector3(0.0, 0.0, -0.08)
const BOWL_B := Vector3(0.05, 0.0, 0.18)
const BOWL_A := Vector3(0.3, 0.0, 0.6)
const BASIN_R := 0.62
const B_Y := 0.5
const A_Y := 0.86


func _init() -> void:
	footprint = 0.9
	collide_radius = 0.72
	collide_height = 1.0


func _build() -> void:
	var kit := DecoKit.new()
	# --- the wide basin: a stepped wall with a carved groove, a floor, a lip ----------------------------
	kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(BASIN_R, 0.0), Vector2(BASIN_R, 0.1), Vector2(0.585, 0.1), Vector2(0.585, 0.125),
		Vector2(0.6, 0.125), Vector2(0.6, 0.27), Vector2(0.53, 0.27), Vector2(0.53, 0.15), Vector2(0.0, 0.15)]),
		22, Transform3D(Basis.IDENTITY, BASIN_C), CHALK_WARM, false)
	kit.lathe(PackedVector2Array([Vector2(0.587, 0.098), Vector2(0.587, 0.127)]), 22, Transform3D(Basis.IDENTITY, BASIN_C), GROOVE, false)
	# --- the columns ---------------------------------------------------------------------------------
	_tier(kit, Vector3(BOWL_B.x, 0.14, BOWL_B.z), Vector3(0.2, B_Y - 0.14, 0.2), CHALK)
	var ay := _tier(kit, BOWL_A, Vector3(0.22, 0.5, 0.22), CHALK_WARM)
	_tier(kit, Vector3(BOWL_A.x, ay, BOWL_A.z), Vector3(0.16, A_Y - ay, 0.16), CHALK)
	# --- the two terraced bowls ----------------------------------------------------------------------
	_bowl(kit, Vector3(BOWL_B.x, B_Y, BOWL_B.z), 0.3, 0.14, 18)
	_bowl(kit, Vector3(BOWL_A.x, A_Y, BOWL_A.z), 0.2, 0.12, 14)
	# spout lips where the water leaves each bowl
	var ab := Vector3(BOWL_B.x - BOWL_A.x, 0.0, BOWL_B.z - BOWL_A.z).normalized()
	var bc := Vector3(BASIN_C.x - BOWL_B.x, 0.0, BASIN_C.z - BOWL_B.z).normalized()
	var spout_a := Vector3(BOWL_A.x, A_Y + 0.11, BOWL_A.z) + ab * 0.2
	var spout_b := Vector3(BOWL_B.x, B_Y + 0.13, BOWL_B.z) + bc * 0.3
	kit.rbox(spout_a + ab * 0.02, Vector3(0.07, 0.03, 0.08), 0.01, CHALK, Basis(Vector3.UP, atan2(ab.x, ab.z)), 0)
	kit.rbox(spout_b + bc * 0.02, Vector3(0.08, 0.03, 0.09), 0.01, CHALK, Basis(Vector3.UP, atan2(bc.x, bc.z)), 0)
	# sage scrub at the foot
	kit.lobed_dome(Vector3(-0.55, 0.0, 0.3), 0.12, 0.12, SAGE, SAGE_DARK, 6, 0.14, 0.8, 0.4, 12, 3, 0.0)
	kit.lobed_dome(Vector3(0.62, 0.0, 0.2), 0.08, 0.08, SAGE_DARK, SAGE_DARK.darkened(0.15), 5, 0.14, 0.8, 1.3, 10, 3, 0.0)
	add_body(kit.commit())

	# --- water: three still pools and two thin falls ----------------------------------------------------
	var water := DecoKit.new()
	water.disc(BASIN_C + Vector3(0.0, 0.23, 0.0), 0.53, WATER, Basis.IDENTITY, 22)
	water.disc(Vector3(BOWL_B.x, B_Y + 0.115, BOWL_B.z), 0.27, WATER, Basis.IDENTITY, 16)
	water.disc(Vector3(BOWL_A.x, A_Y + 0.095, BOWL_A.z), 0.17, WATER, Basis.IDENTITY, 12)
	var fall_a_end := Vector3(BOWL_B.x, B_Y + 0.115, BOWL_B.z) - ab * 0.2
	var fall_b_end := spout_b + bc * 0.12 + Vector3(0.0, 0.23 - spout_b.y, 0.0)
	_fall(water, spout_a + ab * 0.04, fall_a_end, ab)
	_fall(water, spout_b + bc * 0.04, fall_b_end, bc)
	add_glass(water.commit(), WATER, 0.55, "Water")
	var glint := DecoKit.new()
	for p in [spout_a + ab * 0.06 + Vector3(0.0, -0.06, 0.0), fall_a_end + Vector3(0.0, 0.01, 0.0),
			spout_b + bc * 0.07 + Vector3(0.0, -0.1, 0.0), fall_b_end + Vector3(0.0, 0.01, 0.0)]:
		glint.disc(p, 0.035, SHINE, Basis.IDENTITY, 8)
	add_glow(glint.commit(), 1.4, "Glints", 0.8, 0.4)
	add_particles(8, 2.2, fall_b_end + Vector3(0.0, 0.03, 0.0), SHINE, 0.06, 0.25, 50.0, -0.6, 0.05)
	add_light(Vector3(0.0, 0.6, 0.1), WATER, 1.0, 4.0)
	add_ground_glow(1.3, WATER, 0.16)


## A bowl terraced underneath: three steps out from a narrow foot to the rim, hollow on top.
func _bowl(kit: DecoKit, c: Vector3, r: float, h: float, segs: int) -> void:
	kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(r * 0.45, 0.0), Vector2(r * 0.45, h * 0.35), Vector2(r * 0.75, h * 0.35),
		Vector2(r * 0.75, h * 0.7), Vector2(r, h * 0.7), Vector2(r, h), Vector2(r - 0.03, h), Vector2(r - 0.03, h * 0.45),
		Vector2(0.0, h * 0.45)]), segs, Transform3D(Basis.IDENTITY, c), CHALK_SHADE, false)


## A thin bending fall of water from `from` (leaving along `dir`) down to `to`.
func _fall(kit: DecoKit, from: Vector3, to: Vector3, dir: Vector3) -> void:
	var mid := from + dir * 0.05 + Vector3(0.0, -0.05, 0.0)
	kit.bar(from, mid, 0.022, WATER, 8)
	kit.bar(mid, to, 0.02, WATER, 8)


## CHALK TERRACE MOTIF - one stone tier standing on `base`: a blocky body, a groove carved round it (a
## recessed darker band) and a crisp cap slab that overhangs a little. Stacked tiers are the set's
## terraces; every piece is built from them.
func _tier(kit: DecoKit, base: Vector3, size: Vector3, col: Color, basis: Basis = Basis.IDENTITY) -> float:
	var h := size.y
	var gh := minf(0.042, h * 0.22)
	var cap_h := minf(0.06, h * 0.3)
	var body_h := h - gh - cap_h
	kit.rbox(base + basis * Vector3(0.0, body_h * 0.5, 0.0), Vector3(size.x, body_h + 0.01, size.z), 0.02, col.darkened(0.06),
		basis, 1)
	kit.rbox(base + basis * Vector3(0.0, body_h + gh * 0.5, 0.0), Vector3(size.x - 0.045, gh + 0.012, size.z - 0.045), 0.004,
		GROOVE, basis, 0)
	kit.rbox(base + basis * Vector3(0.0, h - cap_h * 0.5, 0.0), Vector3(size.x + 0.016, cap_h, size.z + 0.016), 0.012,
		col, basis, 1)
	return base.y + h
