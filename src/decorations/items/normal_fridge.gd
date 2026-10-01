extends DecoItem
## Cold Food Closet (Norm's Totally Normal Collection, docs/DAILY_STAMPS_SPEC.md 3) — a rounded
## two-door fridge. Norm noticed it is always cold, so he gave it a bobble hat and a scarf.

const SHELL := Color("#bcd3ca")
const DOOR := Color("#cfe0d8")
const FOOT := Color("#4a4655")
const METAL := Color("#8fa3bf")
const WOOL := Color("#cd8b95")
const WOOL_DARK := Color("#b87a85")
const CREAM := Color("#e6dcc0")
const PAPER := Color("#e6dcc0")
const MAGNETS := [Color("#d6c28f"), Color("#7da09e"), Color("#d6a977")]
const TOP := 1.9


func _init() -> void:
	footprint = 0.7
	collide_radius = 0.5
	collide_height = 1.9


func _build() -> void:
	var kit := DecoKit.new()
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			kit.rbox(Vector3(0.34 * sx, 0.04, 0.27 * sz), Vector3(0.14, 0.1, 0.14), 0.03, FOOT, Basis.IDENTITY, 0)
	# --- body and its two doors ---------------------------------------------------------------
	kit.rbox(Vector3(0.0, 0.99, 0.02), Vector3(0.92, TOP - 0.08, 0.74), 0.1, SHELL)
	kit.rbox(Vector3(0.0, 1.61, -0.34), Vector3(0.86, 0.5, 0.1), 0.05, DOOR)
	kit.rbox(Vector3(0.0, 0.72, -0.34), Vector3(0.86, 1.16, 0.1), 0.05, DOOR)
	for h in [[1.48, 1.76], [0.86, 1.2]]:
		kit.tube(Vector3(-0.31, h[0], -0.44), Vector3(-0.31, h[1], -0.44), 0.03, METAL, 8)
		for y in h:
			kit.rbox(Vector3(-0.31, y + (0.04 if y == h[0] else -0.04), -0.41), Vector3(0.05, 0.05, 0.06), 0.02, METAL, Basis.IDENTITY, 0)
	# magnets, one of them holding a note
	kit.rbox(Vector3(0.12, 0.74, -0.395), Vector3(0.24, 0.3, 0.012), 0.005, PAPER, Basis(Vector3(0.0, 0.0, 1.0), deg_to_rad(-6.0)), 0)
	var spots := [Vector3(0.12, 0.86, -0.405), Vector3(0.28, 0.48, -0.4), Vector3(-0.05, 0.42, -0.4)]
	for i in spots.size():
		kit.rbox(spots[i], Vector3(0.09, 0.09, 0.03), 0.03, MAGNETS[i], Basis.IDENTITY, 0)
	# --- scarf: wrapped where the two doors meet, ends hanging down the front --------------------
	kit.rbox(Vector3(0.0, 1.31, 0.0), Vector3(1.02, 0.2, 0.9), 0.09, WOOL)
	for x in [-0.34, 0.0, 0.34]:
		kit.rbox(Vector3(x, 1.31, 0.0), Vector3(0.08, 0.206, 0.91), 0.03, CREAM, Basis.IDENTITY, 0)
	kit.rbox(Vector3(0.24, 1.3, -0.46), Vector3(0.24, 0.22, 0.12), 0.06, WOOL_DARK)
	_scarf_end(kit, Vector3(0.31, 1.22, -0.47), 0.56, -7.0)
	_scarf_end(kit, Vector3(0.17, 1.22, -0.49), 0.4, 6.0)
	# --- bobble hat ---------------------------------------------------------------------------
	kit.dome(Vector3(0.0, TOP, 0.0), 0.37, WOOL, 0.86, Basis.IDENTITY, 16)
	kit.torus(Vector3(0.0, TOP + 0.04, 0.0), 0.36, 0.075, CREAM, Basis.IDENTITY, 16, 5)
	kit.sphere(Vector3(0.0, TOP + 0.36, 0.0), 0.12, CREAM, Vector3.ONE, 10)
	add_body(kit.commit())

	# the little temperature display on the freezer door
	var glow := DecoKit.new()
	glow.rbox(Vector3(0.2, 1.68, -0.39), Vector3(0.2, 0.1, 0.02), 0.01, Color("#7fc4d9"), Basis.IDENTITY, 0)
	add_glow(glow.commit(), 1.8, "Display", 0.8, 0.2)


## One hanging scarf end: a flat strip from `top` down `length`, swung `deg` degrees, with a cream
## band and a row of tassels at the bottom.
func _scarf_end(kit: DecoKit, top: Vector3, length: float, deg: float) -> void:
	var b := Basis(Vector3(0.0, 0.0, 1.0), deg_to_rad(deg))
	kit.rbox(top + b * Vector3(0.0, -length * 0.5, 0.0), Vector3(0.17, length, 0.045), 0.02, WOOL, b, 0)
	kit.rbox(top + b * Vector3(0.0, -length + 0.1, 0.0), Vector3(0.175, 0.06, 0.05), 0.015, CREAM, b, 0)
	for i in 3:
		kit.rbox(top + b * Vector3(-0.055 + float(i) * 0.055, -length - 0.03, 0.0), Vector3(0.035, 0.08, 0.03), 0.012, CREAM, b, 0)
