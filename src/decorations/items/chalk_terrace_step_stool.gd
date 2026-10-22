extends DecoItem
## Step Stool (Chalk Terrace set, Grig) - three little chalk steps in a row, low, middle and high, each
## a stone tier with a groove carved round it under a crisp cap. A sage felt pad on the top step, and a
## tuft of sage scrub growing at the foot of the lowest one, the way it does on Grig's stairs.

const CHALK := Color("#dcd0b2")
const CHALK_WARM := Color("#cdbe98")
const CHALK_SHADE := Color("#b8aa86")
const GROOVE := Color("#7f735d")
const SAGE := Color("#9fb08a")
const SAGE_DARK := Color("#7d8f6c")
const STEP_W := 0.2
const STEP_D := 0.34
const HEIGHTS := [0.11, 0.22, 0.33]


func _init() -> void:
	footprint = 0.45
	collide_radius = 0.3
	collide_height = 0.38


func _build() -> void:
	var kit := DecoKit.new()
	var cols: Array[Color] = [CHALK_WARM, CHALK, CHALK_WARM]
	for i in HEIGHTS.size():
		var x := (float(i) - 1.0) * STEP_W
		_tier(kit, Vector3(x, 0.0, 0.0), Vector3(STEP_W, float(HEIGHTS[i]), STEP_D), cols[i])
	# a sage felt pad on the top step
	var top: float = HEIGHTS[2]
	kit.rbox(Vector3(STEP_W, top + 0.015, 0.0), Vector3(STEP_W * 0.82, 0.03, STEP_D * 0.78), 0.012, SAGE)
	# sage scrub at the foot of the low step
	kit.lobed_dome(Vector3(-STEP_W - 0.06, 0.0, -STEP_D * 0.5 - 0.02), 0.08, 0.09, SAGE, SAGE_DARK, 6, 0.14, 0.8, 0.3, 12, 3, 0.0)
	kit.lobed_dome(Vector3(-STEP_W + 0.04, 0.0, -STEP_D * 0.5 - 0.05), 0.055, 0.06, SAGE_DARK, SAGE_DARK.darkened(0.15), 5, 0.14, 0.8, 1.0, 10, 3, 0.0)
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
