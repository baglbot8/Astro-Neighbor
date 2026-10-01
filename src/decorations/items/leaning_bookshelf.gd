extends DecoItem
## Leaning Bookshelf (cozy home set) - an A-frame ladder shelf: three shelves that get deeper toward the
## ground, crammed with books (one fallen over, one stack lying flat), a storage basket, a framed
## picture, a trailing plant on top and a little night-light jar that glows after dark. Faces -Z.

const WOOD := Color("#b89a74")
const WOOD_DARK := Color("#93775a")
const BOOKS := [Color("#cf8f86"), Color("#7fb5ad"), Color("#d9c27a"), Color("#a595cf"), Color("#c9805e"), Color("#8fa3bf")]
const PAGES := Color("#e6dcc6")
const BASKET := Color("#cdb88a")
const BASKET_DARK := Color("#a8946c")
const POT := Color("#e3d7bc")
const LEAF := Color("#7fb07a")
const LEAF_LIGHT := Color("#9cc68a")
const FRAME := Color("#6f6a80")
const PICTURE := Color("#9cbfd0")
const JAR := Color("#e3c877")
const HALF_W := 0.46
const TOP_Y := 1.55
const FRONT_Z := -0.34
const REAR_Z := 0.3
const SHELF_Y := [0.3, 0.72, 1.12]


func _init() -> void:
	footprint = 0.75
	collide_radius = 0.5
	collide_height = 1.5


func _build() -> void:
	var kit := DecoKit.new()
	# --- the frame: two A's and a top bar -------------------------------------------------------------
	for s in [-1.0, 1.0]:
		var px: float = HALF_W * s
		kit.tube(Vector3(px, 0.03, FRONT_Z), Vector3(px, TOP_Y, 0.0), 0.036, WOOD_DARK, 8)
		kit.tube(Vector3(px, 0.03, REAR_Z), Vector3(px, TOP_Y, 0.0), 0.036, WOOD_DARK, 8)
		kit.sphere(Vector3(px, TOP_Y + 0.02, 0.0), 0.055, WOOD, Vector3.ONE, 8)
	kit.bar(Vector3(-HALF_W, TOP_Y, 0.0), Vector3(HALF_W, TOP_Y, 0.0), 0.03, WOOD_DARK, 8)
	# --- three shelves, each as deep as the A is wide at that height ------------------------------------
	for y in SHELF_Y:
		var zf := _front(y)
		var zr := _rear(y)
		kit.rbox(Vector3(0.0, y, (zf + zr) * 0.5), Vector3(HALF_W * 2.0 + 0.1, 0.05, (zr - zf) + 0.08), 0.02, WOOD, Basis.IDENTITY, 0)
	# --- bottom shelf: a row of six books (the last one leaning), then a basket -----------------------
	var y0: float = SHELF_Y[0] + 0.025
	var x := -0.44
	for i in 6:
		var w := 0.06 + 0.012 * float((i * 3) % 4)
		var h := 0.25 + 0.035 * float((i * 5) % 3)
		var lean := Basis.IDENTITY if i < 5 else Basis(Vector3.BACK, 0.28)
		var bx := x + w * 0.5 + (0.03 if i == 5 else 0.0)
		_book(kit, Vector3(bx, y0 + h * 0.5, -0.02), Vector3(w, h, 0.26), BOOKS[i], lean)
		x += w + 0.006
	kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.11, 0.0), Vector2(0.15, 0.19), Vector2(0.125, 0.19), Vector2(0.125, 0.15),
		Vector2(0.0, 0.15)]), 14, Transform3D(Basis.IDENTITY, Vector3(0.28, y0, -0.02)), BASKET)
	kit.torus(Vector3(0.28, y0 + 0.1, -0.02), 0.132, 0.012, BASKET_DARK, Basis.IDENTITY, 14, 3)
	kit.sphere(Vector3(0.28, y0 + 0.17, -0.02), 0.11, BOOKS[1], Vector3(1.0, 0.45, 1.0), 10)
	# --- middle shelf: four books, a flat stack, the night-light jar's stand ------------------------------
	var y1: float = SHELF_Y[1] + 0.025
	x = -0.43
	for i in 4:
		var w2 := 0.065 + 0.012 * float((i * 2) % 3)
		var h2 := 0.21 + 0.03 * float((i * 4) % 3)
		_book(kit, Vector3(x + w2 * 0.5, y1 + h2 * 0.5, 0.0), Vector3(w2, h2, 0.2), BOOKS[(i + 2) % 6], Basis.IDENTITY)
		x += w2 + 0.006
	for i in 3:
		_book(kit, Vector3(0.0, y1 + 0.025 + 0.05 * float(i), 0.0), Vector3(0.2 - 0.02 * float(i), 0.045, 0.16),
			BOOKS[(i * 2 + 1) % 6], Basis(Vector3.UP, 0.25 - 0.3 * float(i)))
	var jar := Vector3(0.29, y1, 0.0)
	kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.075, 0.0), Vector2(0.075, 0.02), Vector2(0.0, 0.02)]),
		12, Transform3D(Basis.IDENTITY, jar), WOOD_DARK)
	kit.lathe(PackedVector2Array([Vector2(0.0, 0.17), Vector2(0.05, 0.17), Vector2(0.05, 0.195), Vector2(0.0, 0.2)]),
		12, Transform3D(Basis.IDENTITY, jar), WOOD_DARK)
	# --- top shelf: a framed picture and a trailing plant ------------------------------------------------
	var y2: float = SHELF_Y[2] + 0.025
	var tilt := Basis(Vector3.RIGHT, 0.2)
	kit.rbox(Vector3(-0.2, y2 + 0.12, 0.02), Vector3(0.26, 0.22, 0.03), 0.012, FRAME, tilt, 0)
	kit.rbox(Vector3(-0.2, y2 + 0.12, 0.002), Vector3(0.2, 0.16, 0.02), 0.006, PICTURE, tilt, 0)
	kit.sphere(Vector3(-0.16, y2 + 0.14, -0.012), 0.035, JAR, Vector3(1.0, 1.0, 0.3), 6, tilt)
	var pot := Vector3(0.2, y2, 0.0)
	kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.06, 0.0), Vector2(0.085, 0.12), Vector2(0.07, 0.12), Vector2(0.0, 0.11)]),
		12, Transform3D(Basis.IDENTITY, pot), POT)
	for i in 3:
		var a := TAU * float(i) / 3.0 + 0.5
		kit.sphere(pot + Vector3(cos(a) * 0.055, 0.15 + 0.03 * float(i % 2), sin(a) * 0.055), 0.075,
			LEAF_LIGHT if i % 2 == 0 else LEAF, Vector3(1.0, 0.7, 1.0), 6)
	# two vines trailing over the shelf edge
	for k in 2:
		var sx := 0.07 - 0.16 * float(k)
		var top := pot + Vector3(sx, 0.13, -0.07)
		var l := 0.3 + 0.12 * float(k)
		JungleMeshes.tube(kit, PackedVector3Array([top, top + Vector3(0.0, -0.06, -0.06), top + Vector3(0.01, -l * 0.6, -0.07),
			top + Vector3(0.0, -l, -0.065)]), PackedFloat32Array([0.012, 0.011, 0.01, 0.008]), PackedColorArray([LEAF]), 5, true)
		for j in 3:
			var side := 1.0 if j % 2 == 0 else -1.0
			var p := top + Vector3(0.0, -0.1 - (l - 0.1) * float(j) / 2.0, -0.078)
			kit.triangle(p, p + Vector3(0.075 * side, 0.035, 0.0), p + Vector3(0.06 * side, -0.045, 0.0), LEAF_LIGHT)
	add_body(kit.commit())

	var glow := DecoKit.new()
	glow.sphere(jar + Vector3(0.0, 0.095, 0.0), 0.07, JAR, Vector3(1.0, 1.1, 1.0), 10)
	# No OmniLight on purpose: the jar sits 10 cm from the books, and toon_soft.gdshader's light() goes
	# NEGATIVE (renders navy-black) on any surface facing an omni closer than ~0.56 m (ATTENUATION is
	# 1/d^2 and is used unclamped as a mix factor). Measured in the lineup frames; the emissive jar reads
	# as a night-light on its own.
	add_glow(glow.commit(), 2.2, "Jar", 0.6, 0.25)


## A book: a crisp flat-sided block (an extruded rounded rectangle, spine toward -Z) with a pale label
## band across the spine. NOT a level-0 rbox: 20 triangles on a slab this thin shade as diamonds.
func _book(kit: DecoKit, c: Vector3, size: Vector3, col: Color, basis: Basis) -> void:
	kit.extrude(DecoKit.round_rect_poly(size.x, size.y, 0.012, 1), size.z, col, Transform3D(basis, c))
	if size.y > 0.1:
		kit.extrude(DecoKit.round_rect_poly(size.x * 0.7, 0.04, 0.004, 1), 0.012, PAGES,
			Transform3D(basis, c + basis * Vector3(0.0, size.y * 0.22, -size.z * 0.5)))


static func _front(y: float) -> float:
	return FRONT_Z * (1.0 - y / TOP_Y)


static func _rear(y: float) -> float:
	return REAR_Z * (1.0 - y / TOP_Y)
