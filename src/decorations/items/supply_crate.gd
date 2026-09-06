extends DecoItem
## Supply Crate — a stout cargo box with a lipped lid, steel corner braces, latches and a glowing
## manifest label.
##
## SHAPE: next to the ACNH market stall the first version was one plain box with one decal on it and
## nothing to catch the light. A real AC prop is a frame plus panels plus hardware. So: the lid is a
## separate slab with an overhanging lip and two latches, each side face is broken into two recessed
## panels by a vertical batten, the corner posts read as separate steel uprights with rivet heads, and
## there is a pull handle on one end.

const BOX := Color("#d9822f")
const BOX_DARK := Color("#b3671f")
const PANEL := Color("#c4761f")
const STEEL := Color("#5f7089")
const STEEL_LIGHT := Color("#8fa3bf")
const HALF := 0.42


func _init() -> void:
	footprint = 0.55
	collide_radius = 0.44
	collide_height = 0.78


func _build() -> void:
	var kit := DecoKit.new()
	# --- body + skid ----------------------------------------------------------------------------
	kit.rbox(Vector3(0.0, 0.38, 0.0), Vector3(0.84, 0.66, 0.84), 0.07, BOX)
	kit.rbox(Vector3(0.0, 0.05, 0.0), Vector3(0.9, 0.1, 0.9), 0.04, STEEL, Basis.IDENTITY, 0)
	# --- recessed panels: two per side, split by a vertical batten ------------------------------
	for i in 4:
		var a := PI * 0.5 * float(i)
		var n := Vector3(sin(a), 0.0, cos(a))
		var t := Vector3(cos(a), 0.0, -sin(a))
		var b := Basis(Vector3.UP, a)
		for s in [-1.0, 1.0]:
			kit.rbox(Vector3(0.0, 0.4, 0.0) + n * (HALF - 0.005) + t * (0.19 * s),
				Vector3(0.28, 0.4, 0.03), 0.012, PANEL, b, 0)
		kit.rbox(Vector3(0.0, 0.4, 0.0) + n * (HALF + 0.005), Vector3(0.07, 0.56, 0.03), 0.015, BOX_DARK, b, 0)
	# --- corner posts with rivet heads ----------------------------------------------------------
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			kit.rbox(Vector3(0.4 * sx, 0.38, 0.4 * sz), Vector3(0.1, 0.72, 0.1), 0.03, STEEL, Basis.IDENTITY, 0)
			for y in [0.16, 0.6]:
				kit.sphere(Vector3(0.415 * sx, y, 0.415 * sz), 0.026, STEEL_LIGHT, Vector3.ONE, 6)
	# --- lid: a separate slab with an overhanging lip and two latches ---------------------------
	kit.rbox(Vector3(0.0, 0.735, 0.0), Vector3(0.9, 0.09, 0.9), 0.03, BOX_DARK, Basis.IDENTITY, 0)
	kit.rbox(Vector3(0.0, 0.78, 0.0), Vector3(0.78, 0.05, 0.78), 0.02, BOX, Basis.IDENTITY, 0)
	for s in [-1.0, 1.0]:
		kit.rbox(Vector3(0.2 * s, 0.7, -0.44), Vector3(0.11, 0.13, 0.05), 0.025, STEEL_LIGHT, Basis.IDENTITY, 0)
		kit.rbox(Vector3(0.2 * s, 0.66, -0.455), Vector3(0.06, 0.05, 0.03), 0.014, STEEL, Basis.IDENTITY, 0)
	# --- pull handle on the far end -------------------------------------------------------------
	kit.torus(Vector3(0.0, 0.42, 0.44), 0.12, 0.022, STEEL, Basis(Vector3.RIGHT, deg_to_rad(90.0)), 12, 4)
	kit.rbox(Vector3(0.0, 0.55, 0.435), Vector3(0.24, 0.05, 0.04), 0.018, STEEL_LIGHT, Basis.IDENTITY, 0)
	add_body(kit.commit())

	var glow := DecoKit.new()
	glow.extrude(DecoKit.round_rect_poly(0.4, 0.22, 0.05), 0.02, Color("#65c5d9"), Transform3D(Basis.IDENTITY, Vector3(0.0, 0.5, -0.43)))
	for i in 3:
		glow.extrude(DecoKit.round_rect_poly(0.26 - float(i) * 0.06, 0.03, 0.012), 0.02, Color("#bcdfe6"), Transform3D(Basis.IDENTITY, Vector3(-0.03, 0.54 - float(i) * 0.05, -0.445)))
	add_glow(glow.commit(), 1.9, "Label", 0.0, 0.0)
