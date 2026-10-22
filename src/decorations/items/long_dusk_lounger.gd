extends DecoItem
## Sun Lounger (Long Dusk set, Fen) - a long low clay lounger on four little pot feet, with a raked
## clay back and a woven slate cushion (over-under tabs with sand bands) running its whole length. A
## clay bolster at the head wears the set's woven band. Lean back and watch the sun not move.

const CLAY := Color("#ba8d76")
const CLAY_DARK := Color("#9c7a68")
const CLAY_LIGHT := Color("#d2a88e")
const SAND := Color("#e2c6a0")
const SLATE := Color("#7889a3")
const SLATE_DARK := Color("#64738c")
## Where the back hinges up, and how far it is raked.
const HINGE := Vector3(0.2, 0.2, 0.0)
const RAKE_DEG := 38.0
const SEAT_TILES := [SLATE, SLATE, SAND, SLATE, SLATE, SAND]
const BACK_TILES := [SLATE, SAND, SLATE, SLATE]


func _init() -> void:
	footprint = 0.9
	collide_radius = 0.6
	collide_height = 0.6


func _build() -> void:
	var kit := DecoKit.new()
	# --- the clay frame on four pot feet -------------------------------------------------------------
	kit.rbox(Vector3(0.0, 0.125, 0.0), Vector3(1.62, 0.13, 0.62), 0.05, CLAY)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.07, 0.0), Vector2(0.055, 0.035), Vector2(0.075, 0.07),
				Vector2(0.0, 0.07)]), 10, Transform3D(Basis.IDENTITY, Vector3(sx * 0.66, 0.0, sz * 0.22)), CLAY_DARK)
	# the raked back: a crisp clay wedge
	kit.extrude(PackedVector2Array([Vector2(0.17, 0.17), Vector2(0.74, 0.17), Vector2(0.74, 0.61)]), 0.56, CLAY_DARK)
	# --- the cushion: a slate underlay, then woven tabs, seat and back -------------------------------
	var flat := Basis(Vector3.RIGHT, deg_to_rad(-90.0))
	kit.rbox(Vector3(-0.29, 0.215, 0.0), Vector3(0.99, 0.05, 0.56), 0.025, SLATE_DARK)
	for i in SEAT_TILES.size():
		for k in 2:
			var over := (i + k) % 2 == 0
			var col: Color = SEAT_TILES[i]
			var c := Vector3(-0.7 + 0.16 * float(i), 0.25 + (0.006 if over else 0.0), (float(k) - 0.5) * 0.27)
			kit.extrude(_rect(0.155, 0.26), 0.03, col if over else col.darkened(0.1),
				Transform3D(flat, c))
	var rake := Basis(Vector3.BACK, deg_to_rad(RAKE_DEG))
	var along := rake * Vector3.RIGHT
	var up := rake * Vector3.UP
	kit.rbox(HINGE + along * 0.32 + up * 0.03, Vector3(0.64, 0.05, 0.56), 0.025, SLATE_DARK, rake)
	for j in BACK_TILES.size():
		for k in 2:
			var over := (j + k) % 2 == 1
			var col: Color = BACK_TILES[j]
			var c := HINGE + along * (0.09 + 0.15 * float(j)) + up * (0.065 + (0.006 if over else 0.0)) + Vector3(0.0, 0.0, (float(k) - 0.5) * 0.27)
			kit.extrude(_rect(0.145, 0.26), 0.03, col if over else col.darkened(0.1),
				Transform3D(rake * flat, c))
	# --- the bolster at the head, wearing the woven band ---------------------------------------------
	var bp := HINGE + along * 0.6 + up * 0.13
	kit.tube(bp + Vector3(0.0, 0.0, -0.25), bp + Vector3(0.0, 0.0, 0.25), 0.07, CLAY_LIGHT, 12, 2)
	for zz in [-0.14, 0.14]:
		_weave_ring(kit, bp + Vector3(0.0, 0.0, zz), 0.07, 0.05, 8, Basis(Vector3.RIGHT, deg_to_rad(90.0)))
	add_body(kit.commit())


## LONG DUSK MOTIF - the woven band: over-under tabs in slate and sand round a clay curve, held between
## two dark clay cords. Every piece in the set wears one. `axis` turns the ring off the vertical.
func _weave_ring(kit: DecoKit, c: Vector3, r: float, h: float, n: int, axis: Basis = Basis.IDENTITY) -> void:
	kit.torus(c + axis * Vector3(0.0, -h * 0.5, 0.0), r, h * 0.13, CLAY_DARK, axis, int(float(n) * 1.5), 3)
	kit.torus(c + axis * Vector3(0.0, h * 0.5, 0.0), r, h * 0.13, CLAY_DARK, axis, int(float(n) * 1.5), 3)
	for i in n:
		var a := TAU * (float(i) + 0.5) / float(n)
		var o := Vector3(cos(a), 0.0, sin(a))
		var lift := h * 0.14 * (1.0 if i % 2 == 0 else -1.0)
		var col: Color = SLATE if i % 2 == 0 else SAND
		kit.rbox(c + axis * (o * r + Vector3(0.0, lift, 0.0)), Vector3(TAU * r / float(n) * 1.02, h * 0.62, h * 0.3), h * 0.1,
			col, axis * Basis(Vector3.UP, -a - PI * 0.5), 0)


## A plain rectangle polygon, w x d, for the flat woven tabs (12 triangles extruded, a third of a
## rounded one, and the weave reads as strips anyway).
static func _rect(w: float, d: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(-w * 0.5, -d * 0.5), Vector2(w * 0.5, -d * 0.5), Vector2(w * 0.5, d * 0.5),
		Vector2(-w * 0.5, d * 0.5)])
