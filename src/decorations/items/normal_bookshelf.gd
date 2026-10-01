extends DecoItem
## Book Storage Shelf (Norm's Totally Normal Collection, docs/DAILY_STAMPS_SPEC.md 3) — a sturdy
## wooden bookshelf. Norm knows things go on shelves. He filed a boot, a loaf of bread and a fish in
## with the books.

const WOOD := Color("#c4ab8c")
const WOOD_DARK := Color("#a08a72")
const BOOKS := [Color("#7da09e"), Color("#c88b96"), Color("#d6c28f"), Color("#7885a0"), Color("#9f8fb4"), Color("#8baa83"), Color("#d6a977")]
const PAGE := Color("#e6dcc0")
const BREAD := Color("#dac7a5")
const CRUST := Color("#b89d7a")
const BOOT := Color("#b2866f")
const SOLE := Color("#4a4655")
const FISH := Color("#91b1c0")
const FISH_FIN := Color("#7596a8")
const W := 1.24
const DEPTH := 0.42
## Floor of each bay, bottom to top.
const BAYS := [0.19, 0.69, 1.17]
const BAY_Z := -0.03


func _init() -> void:
	footprint = 0.8
	collide_radius = 0.55
	collide_height = 1.66


func _build() -> void:
	var kit := DecoKit.new()
	# --- carcass ------------------------------------------------------------------------------
	kit.rbox(Vector3(0.0, 0.08, 0.0), Vector3(W + 0.04, 0.16, DEPTH + 0.04), 0.04, WOOD_DARK, Basis.IDENTITY, 0)
	for s in [-1.0, 1.0]:
		kit.rbox(Vector3((W * 0.5 - 0.045) * s, 0.87, 0.0), Vector3(0.09, 1.5, DEPTH), 0.03, WOOD, Basis.IDENTITY, 0)
	kit.rbox(Vector3(0.0, 0.87, DEPTH * 0.5 - 0.03), Vector3(W - 0.1, 1.46, 0.04), 0.01, WOOD_DARK, Basis.IDENTITY, 0)
	for y in [0.165, 0.665, 1.145]:
		kit.rbox(Vector3(0.0, y, -0.01), Vector3(W - 0.12, 0.05, DEPTH - 0.04), 0.015, WOOD, Basis.IDENTITY, 0)
	kit.rbox(Vector3(0.0, 1.64, 0.0), Vector3(W + 0.06, 0.09, DEPTH + 0.06), 0.035, WOOD)

	# --- top bay: books, the way books go. The last one has slid over. ---------------------------
	var x := -0.5
	var sizes := [[0.09, 0.34], [0.07, 0.3], [0.11, 0.38], [0.08, 0.33], [0.1, 0.29], [0.07, 0.36], [0.09, 0.31]]
	for i in sizes.size():
		var bw: float = sizes[i][0]
		var bh: float = sizes[i][1]
		_book(kit, Vector3(x + bw * 0.5, BAYS[2] + bh * 0.5, BAY_Z), Vector3(bw, bh, 0.26), BOOKS[i % BOOKS.size()], Basis.IDENTITY)
		x += bw + 0.008
	_book(kit, Vector3(x + 0.1, BAYS[2] + 0.173, BAY_Z), Vector3(0.09, 0.34, 0.26), BOOKS[3], Basis(Vector3(0.0, 0.0, 1.0), deg_to_rad(24.0)))

	# --- middle bay: three books, a loaf of bread, and a boot -----------------------------------
	x = -0.5
	for i in 3:
		var bw2: float = [0.1, 0.08, 0.09][i]
		var bh2: float = [0.36, 0.3, 0.34][i]
		_book(kit, Vector3(x + bw2 * 0.5, BAYS[1] + bh2 * 0.5, BAY_Z), Vector3(bw2, bh2, 0.26), BOOKS[(i + 4) % BOOKS.size()], Basis.IDENTITY)
		x += bw2 + 0.008
	kit.rbox(Vector3(-0.02, BAYS[1] + 0.12, BAY_Z), Vector3(0.36, 0.24, 0.24), 0.11, BREAD)
	for i in 3:
		kit.rbox(Vector3(-0.12 + float(i) * 0.1, BAYS[1] + 0.235, BAY_Z), Vector3(0.03, 0.03, 0.17), 0.012, CRUST, Basis(Vector3.UP, deg_to_rad(20.0)), 0)
	kit.rbox(Vector3(0.36, BAYS[1] + 0.025, BAY_Z), Vector3(0.32, 0.05, 0.17), 0.02, SOLE, Basis.IDENTITY, 0)
	kit.rbox(Vector3(0.35, BAYS[1] + 0.11, BAY_Z), Vector3(0.3, 0.14, 0.16), 0.06, BOOT)
	kit.rbox(Vector3(0.43, BAYS[1] + 0.25, BAY_Z), Vector3(0.15, 0.26, 0.15), 0.05, BOOT)
	kit.rbox(Vector3(0.43, BAYS[1] + 0.375, BAY_Z), Vector3(0.17, 0.05, 0.17), 0.02, PAGE, Basis.IDENTITY, 0)

	# --- bottom bay: a flat stack with a fish filed on top, and three more books -----------------
	for i in 3:
		_book(kit, Vector3(-0.27, BAYS[0] + 0.03 + float(i) * 0.06, BAY_Z), Vector3(0.4 - float(i) * 0.03, 0.058, 0.27), BOOKS[(i * 2 + 1) % BOOKS.size()], Basis(Vector3.UP, deg_to_rad(float(i) * 7.0 - 6.0)))
	_fish(kit, Transform3D(Basis.IDENTITY, Vector3(-0.27, BAYS[0] + 0.277, BAY_Z - 0.03)))
	x = 0.1
	for i in 4:
		var bw3: float = [0.09, 0.11, 0.08, 0.1][i]
		var bh3: float = [0.32, 0.37, 0.28, 0.34][i]
		_book(kit, Vector3(x + bw3 * 0.5, BAYS[0] + bh3 * 0.5, BAY_Z), Vector3(bw3, bh3, 0.26), BOOKS[(i + 2) % BOOKS.size()], Basis.IDENTITY)
		x += bw3 + 0.008
	add_body(kit.commit())


## A book: a coloured cover with a paler block of pages showing at the top.
func _book(kit: DecoKit, at: Vector3, size: Vector3, color: Color, basis: Basis) -> void:
	kit.rbox(at, size, 0.012, color, basis, 0)
	var long_y := size.y >= size.x
	var page := Vector3(size.x * 0.62, 0.012, size.z * 0.9) if long_y else Vector3(0.012, size.y * 0.62, size.z * 0.9)
	var off := Vector3(0.0, size.y * 0.5, 0.0) if long_y else Vector3(size.x * 0.5, 0.0, 0.0)
	kit.rbox(at + basis * off, page, 0.004, PAGE, basis, 0)


## A whole fish, side on. Extruded, so it has a fat belly edge and reads from the gameplay camera.
func _fish(kit: DecoKit, xf: Transform3D) -> void:
	var body := PackedVector2Array([
		Vector2(-0.2, 0.0), Vector2(-0.13, 0.07), Vector2(-0.02, 0.095), Vector2(0.09, 0.06),
		Vector2(0.14, 0.02), Vector2(0.21, 0.09), Vector2(0.21, -0.09), Vector2(0.14, -0.02),
		Vector2(0.09, -0.06), Vector2(-0.02, -0.095), Vector2(-0.13, -0.07)])
	kit.extrude(body, 0.08, FISH, xf)
	kit.extrude(PackedVector2Array([Vector2(-0.06, 0.08), Vector2(0.0, 0.15), Vector2(0.06, 0.07)]), 0.03, FISH_FIN, xf)
	for z in [-0.045, 0.045]:
		kit.sphere(xf * Vector3(-0.13, 0.02, z), 0.02, SOLE, Vector3(1.0, 1.0, 0.5), 6)
