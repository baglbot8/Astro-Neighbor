extends DecoItem
## Pillar Lamp (Chalk Terrace set, Grig) - a carved chalk pillar on a two-step base: a square shaft in
## two stacked tiers, each with a groove cut round it and a fluted line down every face, a stepped-out
## capital, and an open stone lantern on top where a warm light sits between four corner posts under a
## stepped roof.

const CHALK := Color("#dcd0b2")
const CHALK_WARM := Color("#cdbe98")
const GROOVE := Color("#7f735d")
const CORE := Color("#f2d49c")
const LIGHT := Color("#ecc98e")
const SHAFT := 0.22
const CAP_Y := 1.07


func _init() -> void:
	footprint = 0.45
	collide_radius = 0.28
	collide_height = 1.5


func _build() -> void:
	var kit := DecoKit.new()
	# --- a two-step base, a two-tier shaft, a capital ------------------------------------------------
	var y := _tier(kit, Vector3.ZERO, Vector3(0.44, 0.1, 0.44), CHALK_WARM)
	y = _tier(kit, Vector3(0.0, y, 0.0), Vector3(0.36, 0.09, 0.36), CHALK)
	var shaft_lo := y
	y = _tier(kit, Vector3(0.0, y, 0.0), Vector3(SHAFT, 0.42, SHAFT), CHALK_WARM)
	var shaft_mid := y
	y = _tier(kit, Vector3(0.0, y, 0.0), Vector3(SHAFT, 0.39, SHAFT), CHALK_WARM)
	var shaft_hi := y
	y = _tier(kit, Vector3(0.0, y, 0.0), Vector3(0.31, 0.07, 0.31), CHALK)
	# fluted line down each face of both shaft tiers
	for span in [[shaft_lo + 0.03, shaft_mid - 0.1], [shaft_mid + 0.03, shaft_hi - 0.1]]:
		var y0: float = span[0]
		var y1: float = span[1]
		for f in 4:
			var o := Vector3(cos(PI * 0.5 * float(f)), 0.0, sin(PI * 0.5 * float(f)))
			kit.rbox(o * (SHAFT * 0.5) + Vector3(0.0, (y0 + y1) * 0.5, 0.0), Vector3(0.022, y1 - y0, 0.022), 0.006, GROOVE,
				Basis.IDENTITY, 0)
	# --- the open lantern: four corner posts, a stepped roof, a finial --------------------------------
	var post_h := 0.26
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			kit.rbox(Vector3(sx * 0.115, y + post_h * 0.5, sz * 0.115), Vector3(0.055, post_h + 0.01, 0.055), 0.012, CHALK, Basis.IDENTITY, 0)
	var roof := _tier(kit, Vector3(0.0, y + post_h, 0.0), Vector3(0.33, 0.07, 0.33), CHALK_WARM)
	roof = _tier(kit, Vector3(0.0, roof, 0.0), Vector3(0.22, 0.06, 0.22), CHALK)
	kit.rbox(Vector3(0.0, roof + 0.04, 0.0), Vector3(0.09, 0.08, 0.09), 0.02, CHALK_WARM, Basis(Vector3.UP, PI * 0.25), 0)
	add_body(kit.commit())

	var glow := DecoKit.new()
	glow.rbox(Vector3(0.0, y + post_h * 0.5, 0.0), Vector3(0.15, 0.19, 0.15), 0.04, CORE, Basis.IDENTITY, 1)
	add_glow(glow.commit(), 2.4, "Light", 0.0, 0.0)
	add_light(Vector3(0.0, y + post_h * 0.5, 0.0), LIGHT, 2.2, 6.0)
	add_ground_glow(1.4, LIGHT, 0.26)


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
