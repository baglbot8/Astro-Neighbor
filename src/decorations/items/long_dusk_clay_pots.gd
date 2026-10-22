extends DecoItem
## Clay Pot Pair (Long Dusk set, Fen) - two round terracotta pots standing together: a tall bellied one
## holding a spray of dry dusk grasses with seed heads, and a short wide bowl with a fat succulent
## rosette. Each wears the set's woven band (slate and sand tabs, over and under) round its belly.

const CLAY := Color("#ba8d76")
const CLAY_DARK := Color("#9c7a68")
const CLAY_LIGHT := Color("#d2a88e")
const SAND := Color("#e2c6a0")
const SLATE := Color("#7889a3")
const SOIL := Color("#7d6650")
const GRASS := Color("#a7a27a")
const GRASS_DARK := Color("#8a8a68")
const SEED := Color("#d2a77a")
const LEAF := Color("#8fa38a")
const LEAF_DARK := Color("#74897a")
const BUD := Color("#cf8f86")

const TALL := Vector3(-0.13, 0.0, 0.05)
const SHORT := Vector3(0.18, 0.0, -0.09)


func _init() -> void:
	footprint = 0.5
	collide_radius = 0.3
	collide_height = 0.75


func _build() -> void:
	var kit := DecoKit.new()
	# --- the tall pot: a round belly, a pinched neck and a rolled lip --------------------------------
	kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.1, 0.0), Vector2(0.16, 0.08), Vector2(0.19, 0.2), Vector2(0.175, 0.33),
		Vector2(0.12, 0.43), Vector2(0.095, 0.49), Vector2(0.115, 0.53), Vector2(0.105, 0.555), Vector2(0.085, 0.55)]),
		18, Transform3D(Basis.IDENTITY, TALL), CLAY)
	kit.disc(TALL + Vector3(0.0, 0.525, 0.0), 0.09, SOIL, Basis.IDENTITY, 10)
	_weave_ring(kit, TALL + Vector3(0.0, 0.2, 0.0), 0.19, 0.075, 12)
	# dry grasses fanning out of the neck, each with a seed head
	for i in 6:
		var a := TAU * float(i) / 6.0 + 0.3
		var tilt := 0.22 + 0.12 * float(i % 3)
		var dir := Vector3(cos(a) * sin(tilt), cos(tilt), sin(a) * sin(tilt)).normalized()
		var length := 0.34 + 0.06 * float((i * 5) % 3)
		var base := TALL + Vector3(0.0, 0.5, 0.0)
		kit.cone(base, 0.012, 0.004, length, GRASS if i % 2 == 0 else GRASS_DARK, DecoKit.axis_basis(dir), 6)
		kit.cone(base + dir * (length - 0.015), 0.022, 0.0, 0.08, SEED, DecoKit.axis_basis(dir), 6)
	# --- the short pot: a wide low bowl with a rosette ---------------------------------------------
	kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.12, 0.0), Vector2(0.18, 0.06), Vector2(0.2, 0.13), Vector2(0.185, 0.2),
		Vector2(0.2, 0.225), Vector2(0.185, 0.24), Vector2(0.165, 0.232)]), 18, Transform3D(Basis.IDENTITY, SHORT), CLAY_LIGHT)
	kit.disc(SHORT + Vector3(0.0, 0.21, 0.0), 0.17, SOIL, Basis.IDENTITY, 12)
	_weave_ring(kit, SHORT + Vector3(0.0, 0.12, 0.0), 0.2, 0.065, 12)
	for ring in 2:
		var count := 6 if ring == 0 else 4
		for i in count:
			var a2 := TAU * float(i) / float(count) + 0.4 * float(ring)
			var out := Vector3(cos(a2), 0.0, sin(a2))
			var reach := 0.1 if ring == 0 else 0.05
			var lean := deg_to_rad(62.0 if ring == 0 else 35.0)
			var b := Basis(Vector3.UP, -a2) * Basis(Vector3.BACK, -lean)
			# a fat pointed leaf: a cone flattened across its face
			kit.cone(SHORT + out * reach * 0.4 + Vector3(0.0, 0.215 + 0.03 * float(ring), 0.0), 0.05, 0.0, 0.13,
				LEAF if ring == 0 else LEAF_DARK, b * Basis.from_scale(Vector3(0.45, 1.0, 1.0)), 6)
	kit.sphere(SHORT + Vector3(0.0, 0.31, 0.0), 0.035, BUD, Vector3(1.0, 0.8, 1.0), 8)
	add_body(kit.commit())


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
