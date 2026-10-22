extends DecoItem
## Terrace Arch (Chalk Terrace set bonus, Grig) - a carved stone doorway with no wall: two chalk pillars
## on stepped bases, each shaft cut by a groove, under a two-tier stepped lintel with a keystone. A
## little staircase sign glows softly on the keystone, a carved plaque swings from the lintel, and sage
## scrub grows on top, its tassels swaying. "Every good place needs a door with no wall."

const CHALK := Color("#dcd0b2")
const CHALK_WARM := Color("#cdbe98")
const CHALK_SHADE := Color("#b8aa86")
const GROOVE := Color("#7f735d")
const SAGE := Color("#9fb08a")
const SAGE_DARK := Color("#7d8f6c")
const SIGIL := Color("#f0d49a")
const PILLAR_X := 0.62
const SHAFT := 0.26
const SHAFT_TOP := 1.5
const LINTEL := Vector3(1.66, 0.18, 0.34)

var _plaque: Node3D
var _tassels: Array[Node3D] = []


func _init() -> void:
	footprint = 1.1
	collide_radius = 0.9
	collide_height = 2.1


func _build() -> void:
	var kit := DecoKit.new()
	# --- two pillars: a stepped base, a shaft cut by a groove, a capital block --------------------------
	for sx in [-1.0, 1.0]:
		var x: float = sx * PILLAR_X
		var y := _tier(kit, Vector3(x, 0.0, 0.0), Vector3(0.38, 0.16, 0.38), CHALK_SHADE)
		var cut := lerpf(y, SHAFT_TOP, 0.55)
		kit.rbox(Vector3(x, (y + cut) * 0.5, 0.0), Vector3(SHAFT, cut - y - 0.015, SHAFT), 0.025, CHALK_WARM, Basis.IDENTITY, 1)
		kit.rbox(Vector3(x, cut, 0.0), Vector3(SHAFT - 0.035, 0.05, SHAFT - 0.035), 0.006, GROOVE, Basis.IDENTITY, 0)
		kit.rbox(Vector3(x, (cut + SHAFT_TOP) * 0.5, 0.0), Vector3(SHAFT, SHAFT_TOP - cut - 0.015, SHAFT), 0.025, CHALK_WARM,
			Basis.IDENTITY, 1)
		kit.rbox(Vector3(x, SHAFT_TOP + 0.04, 0.0), Vector3(0.34, 0.08, 0.34), 0.02, CHALK, Basis.IDENTITY, 1)
	# --- the stepped lintel and keystone ---------------------------------------------------------------
	var ly := _tier(kit, Vector3(0.0, SHAFT_TOP + 0.08, 0.0), LINTEL, CHALK_WARM)
	ly = _tier(kit, Vector3(0.0, ly, 0.0), Vector3(1.24, 0.14, 0.3), CHALK)
	kit.rbox(Vector3(0.0, ly + 0.07, 0.0), Vector3(0.3, 0.14, 0.27), 0.025, CHALK_WARM, Basis.IDENTITY, 1)
	var key_y := ly + 0.07
	# --- sage scrub on top of the lintel ----------------------------------------------------------------
	var lt := SHAFT_TOP + 0.08 + LINTEL.y
	kit.lobed_dome(Vector3(-0.72, lt, 0.02), 0.11, 0.11, SAGE, SAGE_DARK, 6, 0.14, 0.8, 0.2, 10, 3, 0.0)
	kit.lobed_dome(Vector3(0.48, ly, -0.02), 0.09, 0.09, SAGE, SAGE_DARK, 5, 0.14, 0.8, 0.9, 10, 3, 0.0)
	add_body(kit.commit())

	# --- the glowing staircase sign on the keystone's face ------------------------------------------------
	var g := DecoKit.new()
	var steps := PackedVector2Array([Vector2(-0.09, -0.05), Vector2(0.09, -0.05), Vector2(0.09, 0.06), Vector2(0.03, 0.06),
		Vector2(0.03, 0.02), Vector2(-0.03, 0.02), Vector2(-0.03, -0.015), Vector2(-0.09, -0.015)])
	g.extrude(steps, 0.012, SIGIL, Transform3D(Basis.IDENTITY, Vector3(0.0, key_y, -0.137)))
	add_glow(g.commit(), 1.8, "Sigil", 0.6, 0.35)

	# --- a carved plaque on two cords, swinging gently ------------------------------------------------
	var lintel_bottom := SHAFT_TOP + 0.08
	_plaque = pivot("Plaque", Vector3(0.0, lintel_bottom, -0.04))
	var pk := DecoKit.new()
	pk.bar(Vector3(-0.12, 0.0, 0.0), Vector3(-0.12, -0.13, 0.0), 0.008, GROOVE, 6)
	pk.bar(Vector3(0.12, 0.0, 0.0), Vector3(0.12, -0.13, 0.0), 0.008, GROOVE, 6)
	pk.rbox(Vector3(0.0, -0.22, 0.0), Vector3(0.36, 0.19, 0.035), 0.02, CHALK, Basis.IDENTITY, 1)
	pk.extrude(PackedVector2Array([Vector2(-0.11, -0.05), Vector2(0.11, -0.05), Vector2(0.11, 0.05), Vector2(0.04, 0.05),
		Vector2(0.04, 0.015), Vector2(-0.035, 0.015), Vector2(-0.035, -0.018), Vector2(-0.11, -0.018)]), 0.008, GROOVE,
		Transform3D(Basis.IDENTITY, Vector3(0.0, -0.22, -0.019)))
	add_body(pk.commit(), "PlaqueBody", _plaque)
	# --- sage tassels hanging from both lintel ends -----------------------------------------------------
	for sx in [-1.0, 1.0]:
		var t := pivot("Tassel", Vector3(sx * (LINTEL.x * 0.5 - 0.06), lintel_bottom + 0.06, -0.2))
		var tk := DecoKit.new()
		tk.bar(Vector3.ZERO, Vector3(0.0, -0.16, 0.0), 0.012, SAGE_DARK, 6)
		tk.cone(Vector3(0.0, -0.13, 0.0), 0.05, 0.0, 0.14, SAGE, Basis(Vector3.RIGHT, PI), 8)
		add_body(tk.commit(), "TasselBody", t)
		_tassels.append(t)
	animate()


func _animate(t: float, _delta: float) -> void:
	_plaque.rotation.x = sin(t * 1.1) * 0.09
	for i in _tassels.size():
		_tassels[i].rotation.z = sin(t * 1.4 + float(i) * 1.7) * 0.12


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
