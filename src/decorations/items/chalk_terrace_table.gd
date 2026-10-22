extends DecoItem
## Carved Stone Table (Chalk Terrace set, Grig) - a heavy chalk table: a thick top with a groove carved
## all the way round its edge, on two stepped stone trestles, each three tiers of block narrowing as it
## climbs. On top, a shallow stone bowl of sage sprigs and three smooth pebbles.

const CHALK := Color("#dcd0b2")
const CHALK_WARM := Color("#cdbe98")
const CHALK_SHADE := Color("#b8aa86")
const GROOVE := Color("#7f735d")
const SAGE := Color("#9fb08a")
const SAGE_DARK := Color("#7d8f6c")
const PEBBLE := Color("#b9b29c")
const PEBBLE_B := Color("#a8b0a8")
const TOP := Vector3(1.24, 0.13, 0.78)
const TOP_Y := 0.52


func _init() -> void:
	footprint = 0.85
	collide_radius = 0.62
	collide_height = 0.56


func _build() -> void:
	var kit := DecoKit.new()
	# --- two stepped trestles ------------------------------------------------------------------------
	for sx in [-1.0, 1.0]:
		var x: float = sx * 0.4
		var y := _tier(kit, Vector3(x, 0.0, 0.0), Vector3(0.3, 0.1, 0.62), CHALK_SHADE)
		y = _tier(kit, Vector3(x, y, 0.0), Vector3(0.22, 0.2, 0.5), CHALK_WARM)
		_tier(kit, Vector3(x, y, 0.0), Vector3(0.18, TOP_Y - TOP.y - y, 0.42), CHALK_WARM)
	# --- the top: lower slab, a groove carved all round, upper slab ----------------------------------
	var lo := TOP_Y - TOP.y
	kit.rbox(Vector3(0.0, lo + 0.03, 0.0), Vector3(TOP.x, 0.06, TOP.z), 0.025, CHALK, Basis.IDENTITY, 1)
	kit.rbox(Vector3(0.0, lo + 0.07, 0.0), Vector3(TOP.x - 0.035, 0.03, TOP.z - 0.035), 0.006, GROOVE, Basis.IDENTITY, 0)
	kit.rbox(Vector3(0.0, TOP_Y - 0.025, 0.0), Vector3(TOP.x + 0.01, 0.05, TOP.z + 0.01), 0.02, CHALK, Basis.IDENTITY, 1)
	# --- a stone bowl of sage, and pebbles -------------------------------------------------------------
	var bowl := Vector3(0.18, TOP_Y, 0.06)
	kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.09, 0.0), Vector2(0.13, 0.05), Vector2(0.14, 0.075),
		Vector2(0.125, 0.08), Vector2(0.0, 0.06)]), 14, Transform3D(Basis.IDENTITY, bowl), CHALK_SHADE)
	kit.torus(bowl + Vector3(0.0, 0.04, 0.0), 0.12, 0.008, GROOVE, Basis.IDENTITY, 14, 3)
	kit.lobed_dome(bowl + Vector3(0.0, 0.055, 0.0), 0.1, 0.09, SAGE, SAGE_DARK, 6, 0.16, 0.8, 0.3, 12, 3, 0.0)
	for i in 4:
		var a := TAU * float(i) / 4.0 + 0.4
		var dir := Vector3(cos(a) * 0.45, 1.0, sin(a) * 0.45).normalized()
		kit.cone(bowl + Vector3(cos(a) * 0.04, 0.07, sin(a) * 0.04), 0.012, 0.0, 0.17, SAGE_DARK, DecoKit.axis_basis(dir), 6)
	kit.faceted_blob(Vector3(-0.28, TOP_Y + 0.025, -0.12), 0.045, PEBBLE, Vector3(1.0, 0.6, 0.85), 0, 0.12, 1.0)
	kit.faceted_blob(Vector3(-0.19, TOP_Y + 0.02, -0.17), 0.035, PEBBLE_B, Vector3(1.0, 0.6, 0.9), 0, 0.12, 2.0)
	kit.faceted_blob(Vector3(-0.33, TOP_Y + 0.016, -0.03), 0.028, PEBBLE, Vector3(1.0, 0.6, 1.0), 0, 0.12, 3.0)
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
