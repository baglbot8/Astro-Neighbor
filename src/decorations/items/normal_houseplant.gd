extends DecoItem
## Plant, Labelled (Norm's Totally Normal Collection, docs/DAILY_STAMPS_SPEC.md 3) — a leafy
## houseplant in a square planter. Norm read that humans keep plants indoors, and wrote PLANT on it
## in big letters so nobody gets confused.

const Letters := preload("res://src/decorations/items/normal_letters.gd")

const POT := Color("#ca9c8a")
const POT_RIM := Color("#b68979")
const SOIL := Color("#4a3f35")
const LEAF := Color("#6f9c78")
const LEAF_LIGHT := Color("#8fb48a")
const STEM := Color("#88a07c")
const RIB := Color("#c1d0b5")
const CARD := Color("#e6dcc0")
const INK := Color("#3a3550")
const PIN := Color("#d6a977")
const SOIL_Y := 0.56
## azimuth (deg), stem reach, stem height, leaf tilt from upright (deg), leaf length
const LEAVES: Array = [
	[20.0, 0.16, 0.42, 58.0, 0.5],
	[95.0, 0.14, 0.56, 46.0, 0.46],
	[160.0, 0.17, 0.4, 62.0, 0.5],
	[215.0, 0.13, 0.62, 40.0, 0.44],
	[285.0, 0.17, 0.44, 56.0, 0.5],
	[330.0, 0.1, 0.72, 30.0, 0.42],
	[130.0, 0.03, 0.86, 10.0, 0.4],
]


func _init() -> void:
	footprint = 0.6
	collide_radius = 0.42
	collide_height = 1.2


func _build() -> void:
	var kit := DecoKit.new()
	# --- square planter -----------------------------------------------------------------------
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			kit.rbox(Vector3(0.32 * sx, 0.03, 0.22 * sz), Vector3(0.14, 0.08, 0.14), 0.03, POT_RIM, Basis.IDENTITY, 0)
	kit.rbox(Vector3(0.0, 0.29, 0.0), Vector3(0.84, 0.48, 0.62), 0.08, POT)
	kit.rbox(Vector3(0.0, 0.51, 0.0), Vector3(0.92, 0.12, 0.7), 0.045, POT_RIM)
	kit.rbox(Vector3(0.0, SOIL_Y, 0.0), Vector3(0.78, 0.04, 0.56), 0.015, SOIL, Basis.IDENTITY, 0)
	# --- the label: one big card, pinned on a little crooked -----------------------------------
	var tilt := Basis(Vector3(0.0, 0.0, 1.0), deg_to_rad(-3.0))
	var card_at := Vector3(0.0, 0.27, -0.325)
	kit.extrude(DecoKit.round_rect_poly(0.8, 0.3, 0.035, 2), 0.022, CARD, Transform3D(tilt, card_at))
	Letters.draw(kit, "PLANT", Transform3D(tilt * Letters.FRONT, card_at + Vector3(0.0, 0.0, -0.015)), 0.034, INK)
	for s in [-1.0, 1.0]:
		kit.sphere(Transform3D(tilt, card_at) * Vector3(0.35 * s, 0.11, -0.012), 0.022, PIN, Vector3(1.0, 1.0, 0.6), 8)
	# --- the plant: seven broad leaves on bendy stems -------------------------------------------
	for i in LEAVES.size():
		var row: Array = LEAVES[i]
		var spin := Basis(Vector3.UP, deg_to_rad(float(row[0])))
		var root := spin * Vector3(0.0, SOIL_Y, 0.05)
		var tip := spin * Vector3(0.0, SOIL_Y + float(row[2]), float(row[1]))
		var knee := root.lerp(tip, 0.55) + spin * Vector3(0.0, 0.03, -0.035)
		kit.tube(root, knee, 0.026, STEM, 6, 1)
		kit.tube(knee, tip, 0.022, STEM, 6, 1)
		var lb := spin * Basis(Vector3.RIGHT, deg_to_rad(float(row[3])))
		_leaf(kit, Transform3D(lb, tip - lb * Vector3(0.0, 0.03, 0.0)), float(row[4]), LEAF if i % 2 == 0 else LEAF_LIGHT)
	add_body(kit.commit())


## A broad pointed leaf growing along the transform's +Y, with a pale midrib on both faces.
func _leaf(kit: DecoKit, xf: Transform3D, length: float, color: Color) -> void:
	var w := length * 0.72
	var poly := PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(w * 0.36, length * 0.12), Vector2(w * 0.5, length * 0.4),
		Vector2(w * 0.34, length * 0.74), Vector2(0.0, length),
		Vector2(-w * 0.34, length * 0.74), Vector2(-w * 0.5, length * 0.4), Vector2(-w * 0.36, length * 0.12)])
	kit.extrude(poly, 0.028, color, xf)
	for z in [0.016, -0.016]:
		kit.quad(xf * Vector3(-0.012, 0.03, z), xf * Vector3(-0.004, length * 0.9, z),
			xf * Vector3(0.004, length * 0.9, z), xf * Vector3(0.012, 0.03, z), RIB, true)
