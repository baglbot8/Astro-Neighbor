extends DecoItem
## Stair Shelf (Chalk Terrace set, Grig) - a chalk shelf shaped like a staircase: four open cubbies
## rising left to right, each step topped by a stone tier with a groove carved round it. The cubbies
## hold a stone pot of scrub, a stack of books, a chalk ball and a cup, a rolled map and a tiny potted
## plant; one round pebble sits on every step, each a little bigger than the last.

const CHALK := Color("#dcd0b2")
const CHALK_WARM := Color("#cdbe98")
const CHALK_SHADE := Color("#b8aa86")
const GROOVE := Color("#7f735d")
const SAGE := Color("#9fb08a")
const SAGE_DARK := Color("#7d8f6c")
const BOOK_A := Color("#8fa3ad")
const BOOK_B := Color("#c98f7a")
const PAGES := Color("#e6dcc6")
const CUP := Color("#a8c4c0")
const PEBBLE := Color("#b9b29c")
const COL_W := 0.28
const DEPTH := 0.36
const HEIGHTS := [0.3, 0.54, 0.78, 1.02]
const PLINTH := 0.08
const TOP_H := 0.1


func _init() -> void:
	footprint = 0.65
	collide_radius = 0.48
	collide_height = 1.05


func _x(i: int) -> float:
	return -0.42 + COL_W * float(i)


func _build() -> void:
	var kit := DecoKit.new()
	_tier(kit, Vector3.ZERO, Vector3(COL_W * 4.0 + 0.04, PLINTH, DEPTH + 0.02), CHALK_SHADE)
	# --- back panels, dividers, the stepped tops -------------------------------------------------------
	for i in 4:
		var h: float = HEIGHTS[i]
		kit.rbox(Vector3(_x(i), PLINTH + (h - PLINTH) * 0.5, DEPTH * 0.5 - 0.025), Vector3(COL_W, h - PLINTH, 0.05), 0.01,
			CHALK_WARM, Basis.IDENTITY, 0)
		_tier(kit, Vector3(_x(i), h - TOP_H, 0.0), Vector3(COL_W + 0.02, TOP_H, DEPTH + 0.02), CHALK)
	for j in 5:
		var hd: float = HEIGHTS[mini(j, 3)]
		kit.rbox(Vector3(-0.56 + COL_W * float(j), PLINTH + (hd - TOP_H - PLINTH) * 0.5, 0.0),
			Vector3(0.05, hd - TOP_H - PLINTH + 0.01, DEPTH), 0.012, CHALK, Basis.IDENTITY, 0)
	# mid shelves in the two tall cubbies
	var mids: Array[float] = []
	for i in [2, 3]:
		var hm: float = HEIGHTS[i]
		var my := PLINTH + (hm - TOP_H - PLINTH) * 0.5
		mids.append(my)
		kit.rbox(Vector3(_x(i), my, 0.0), Vector3(COL_W - 0.03, 0.035, DEPTH - 0.03), 0.01, CHALK, Basis.IDENTITY, 1)
	var fz := -0.04
	# cubby 0: a stone pot of scrub
	var pot := Vector3(_x(0), PLINTH, fz)
	kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.06, 0.0), Vector2(0.075, 0.07), Vector2(0.07, 0.085),
		Vector2(0.0, 0.08)]), 10, Transform3D(Basis.IDENTITY, pot), CHALK_SHADE)
	kit.lobed_dome(pot + Vector3(0.0, 0.08, 0.0), 0.07, 0.07, SAGE, SAGE_DARK, 5, 0.14, 0.8, 0.0, 10, 3, 0.0)
	# cubby 1: books, two lying and one leaning
	var bp := Vector3(_x(1), PLINTH, fz)
	kit.rbox(bp + Vector3(-0.02, 0.022, 0.0), Vector3(0.17, 0.04, 0.13), 0.01, BOOK_A, Basis(Vector3.UP, 0.15), 0)
	kit.rbox(bp + Vector3(-0.02, 0.06, 0.0), Vector3(0.15, 0.035, 0.12), 0.01, BOOK_B, Basis(Vector3.UP, -0.1), 0)
	kit.rbox(bp + Vector3(0.09, 0.09, 0.02), Vector3(0.035, 0.17, 0.12), 0.01, BOOK_A.darkened(0.12), Basis(Vector3.BACK, 0.2), 0)
	# cubby 2: a chalk ball below, a cup above
	kit.sphere(Vector3(_x(2), PLINTH + 0.07, fz), 0.07, CHALK_WARM, Vector3.ONE, 10)
	var cup := Vector3(_x(2), mids[0] + 0.018, fz)
	kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.035, 0.0), Vector2(0.048, 0.08), Vector2(0.04, 0.08),
		Vector2(0.0, 0.07)]), 10, Transform3D(Basis.IDENTITY, cup), CUP)
	# cubby 3: a rolled map below, a tiny potted plant above
	kit.tube(Vector3(_x(3) - 0.1, PLINTH + 0.04, fz), Vector3(_x(3) + 0.1, PLINTH + 0.04, fz), 0.04, PAGES, 10, 2)
	kit.torus(Vector3(_x(3), PLINTH + 0.04, fz), 0.041, 0.008, BOOK_B, Basis(Vector3.BACK, PI * 0.5), 10, 3)
	var pot2 := Vector3(_x(3), mids[1] + 0.018, fz)
	kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.045, 0.0), Vector2(0.055, 0.06), Vector2(0.0, 0.055)]),
		10, Transform3D(Basis.IDENTITY, pot2), BOOK_B)
	kit.lobed_dome(pot2 + Vector3(0.0, 0.055, 0.0), 0.06, 0.08, SAGE, SAGE_DARK, 5, 0.14, 0.8, 0.5, 10, 3, 0.0)
	# --- one pebble per step, growing as the stairs climb ---------------------------------------------
	for i in 4:
		var r := 0.03 + 0.01 * float(i)
		kit.faceted_blob(Vector3(_x(i) - 0.04, float(HEIGHTS[i]) + r * 0.6, -0.04), r, PEBBLE, Vector3(1.0, 0.75, 1.0), 0, 0.12, float(i))
	add_body(kit.commit())


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
