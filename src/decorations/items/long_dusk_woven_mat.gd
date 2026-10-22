extends DecoItem
## Woven Mat (Long Dusk set, Fen) - a long low mat woven in sunset bands (slate, sand, dusk orange,
## clay), every band an over-under basket weave, with sand tassels on both short ends and a rolled
## slate bolster at the head, bound with the set's woven band. Non-blocking: you walk right over it.

const CLAY := Color("#ba8d76")
const CLAY_DARK := Color("#9c7a68")
const SAND := Color("#e2c6a0")
const SLATE := Color("#7889a3")
const SUNSET := Color("#d99d78")
const W := 1.66
const D := 0.8
## The sunset bands from foot to head, each woven over-under across the mat.
const BANDS := [SLATE, SAND, SUNSET, SAND, CLAY, SAND, SUNSET, SAND, SLATE]


func _init() -> void:
	footprint = 1.0
	blocking = false
	collide_radius = 0.9
	collide_height = 0.06


func _build() -> void:
	var kit := DecoKit.new()
	kit.rbox(Vector3(0.0, 0.016, 0.0), Vector3(W, 0.032, D), 0.016, CLAY_DARK)
	# --- the weave: nine bands across the mat, five tabs per band, alternately over and under ------------
	var bw := (W - 0.08) / float(BANDS.size())
	var tabs := 5
	var td := (D - 0.08) / float(tabs)
	var flat := Basis(Vector3.RIGHT, deg_to_rad(-90.0))
	for b in BANDS.size():
		var col: Color = BANDS[b]
		for t in tabs:
			var over := (b + t) % 2 == 0
			var c := Vector3((float(b) - (float(BANDS.size()) - 1.0) * 0.5) * bw, 0.04 + (0.006 if over else 0.0),
				(float(t) - (float(tabs) - 1.0) * 0.5) * td)
			kit.extrude(_rect(bw * (0.98 if over else 0.9), td * (0.9 if over else 0.98)), 0.02,
				col if over else col.darkened(0.12), Transform3D(flat, c))
	# --- tassels on both short ends ------------------------------------------------------------------
	for s in [-1.0, 1.0]:
		for i in 6:
			var z := (float(i) - 2.5) * (D - 0.12) / 5.0
			var root := Vector3(s * (W * 0.5 - 0.01), 0.026, z)
			kit.cone(root, 0.016, 0.0, 0.09, SAND, Basis(Vector3.BACK, -s * deg_to_rad(84.0)), 6)
	# --- the bolster at the head, wearing the woven band -------------------------------------------------
	var bx := W * 0.5 - 0.2
	var by := 0.115
	kit.tube(Vector3(bx, by, -D * 0.5 + 0.06), Vector3(bx, by, D * 0.5 - 0.06), 0.075, SLATE, 12, 2)
	for zz in [-0.17, 0.17]:
		_weave_ring(kit, Vector3(bx, by, zz), 0.075, 0.05, 8, Basis(Vector3.RIGHT, deg_to_rad(90.0)))
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
		var col: Color = SAND if i % 2 == 0 else CLAY
		kit.rbox(c + axis * (o * r + Vector3(0.0, lift, 0.0)), Vector3(TAU * r / float(n) * 1.02, h * 0.62, h * 0.3), h * 0.1,
			col, axis * Basis(Vector3.UP, -a - PI * 0.5), 0)


## A plain rectangle polygon, w x d, for the flat woven tabs (12 triangles extruded, a third of a
## rounded one, and the weave reads as strips anyway).
static func _rect(w: float, d: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(-w * 0.5, -d * 0.5), Vector2(w * 0.5, -d * 0.5), Vector2(w * 0.5, d * 0.5),
		Vector2(-w * 0.5, d * 0.5)])
