extends DecoItem
## Terrace Planter (Chalk Terrace set, Grig) - a stepped stone box: a long low tier with a smaller one
## stacked on it, set back and to one side, each with a groove carved round it under its cap and filled
## with dry earth. Tough little sage scrub, spiky grass and a few rust-coloured flowers grow in it.

const CHALK := Color("#dcd0b2")
const CHALK_WARM := Color("#cdbe98")
const GROOVE := Color("#7f735d")
const EARTH := Color("#8c7d63")
const SAGE := Color("#9fb08a")
const SAGE_DARK := Color("#7d8f6c")
const GRASS := Color("#b2b38a")
const FLOWER := Color("#c98f7a")
const LOW := Vector3(0.8, 0.22, 0.48)
const HIGH := Vector3(0.44, 0.2, 0.3)
const HIGH_AT := Vector3(0.14, 0.0, 0.06)


func _init() -> void:
	footprint = 0.55
	collide_radius = 0.42
	collide_height = 0.5


func _build() -> void:
	var kit := DecoKit.new()
	var low_top := _tier(kit, Vector3.ZERO, LOW, CHALK_WARM)
	kit.rbox(Vector3(0.0, low_top + 0.004, 0.0), Vector3(LOW.x - 0.1, 0.02, LOW.z - 0.1), 0.008, EARTH)
	var high_base := Vector3(HIGH_AT.x, low_top, HIGH_AT.z)
	var high_top := _tier(kit, high_base, HIGH, CHALK)
	kit.rbox(Vector3(HIGH_AT.x, high_top + 0.004, HIGH_AT.z), Vector3(HIGH.x - 0.09, 0.02, HIGH.z - 0.09), 0.008, EARTH)
	# --- scrub: sage domes, a clump of spiky grass, rust flowers -------------------------------------
	var soil_lo := low_top + 0.012
	var soil_hi := high_top + 0.012
	kit.lobed_dome(Vector3(-0.25, soil_lo, -0.04), 0.12, 0.13, SAGE, SAGE_DARK, 7, 0.14, 0.8, 0.2, 12, 3, 0.0)
	kit.lobed_dome(Vector3(0.24, soil_lo, -0.15), 0.07, 0.07, SAGE_DARK, SAGE_DARK.darkened(0.15), 5, 0.14, 0.8, 1.1, 10, 3, 0.0)
	kit.lobed_dome(Vector3(HIGH_AT.x + 0.06, soil_hi, HIGH_AT.z + 0.02), 0.12, 0.12, SAGE, SAGE_DARK, 7, 0.14, 0.8, 0.7, 12, 3, 0.0)
	for i in 6:
		var a := TAU * float(i) / 6.0
		var dir := Vector3(cos(a) * 0.35, 1.0, sin(a) * 0.35).normalized()
		var root := Vector3(HIGH_AT.x - 0.1, soil_hi, HIGH_AT.z - 0.03) + Vector3(cos(a), 0.0, sin(a)) * 0.02
		kit.cone(root, 0.014, 0.0, 0.16 + 0.05 * float(i % 2), GRASS, DecoKit.axis_basis(dir), 6)
	for p in [Vector3(-0.28, soil_lo + 0.12, -0.08), Vector3(-0.2, soil_lo + 0.11, 0.02),
			Vector3(HIGH_AT.x + 0.1, soil_hi + 0.11, HIGH_AT.z - 0.03), Vector3(HIGH_AT.x + 0.02, soil_hi + 0.12, HIGH_AT.z + 0.06)]:
		kit.sphere(p, 0.022, FLOWER, Vector3(1.0, 0.7, 1.0), 6)
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
