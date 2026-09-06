extends DecoItem
## Moon Rock Garden — a raked circle of pale dust with three balanced rocks and two little crystals.
## Non-blocking: it is ankle height.

const RIM := Color("#b8c4d6")
const SAND := Color("#cbbb8b")
const SAND_DARK := Color("#dccfa8")
const ROCK := Color("#8fa3bf")
const ROCK_DARK := Color("#6f819c")


func _init() -> void:
	footprint = 0.9
	blocking = false
	collide_radius = 0.85
	collide_height = 0.4


func _build() -> void:
	var kit := DecoKit.new()
	kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.88, 0.0), Vector2(0.9, 0.09), Vector2(0.84, 0.12), Vector2(0.8, 0.07), Vector2(0.0, 0.07)]), 26, Transform3D.IDENTITY, SAND)
	kit.torus(Vector3(0.0, 0.09, 0.0), 0.86, 0.05, RIM, Basis.IDENTITY, 26)
	for r in [0.32, 0.5, 0.68]:
		kit.torus(Vector3(0.0, 0.075, 0.0), r, 0.022, SAND_DARK, Basis.IDENTITY, 24)
	kit.sphere(Vector3(-0.12, 0.1, -0.1), 0.27, ROCK, Vector3(1.0, 0.82, 0.9), 14)
	kit.sphere(Vector3(-0.16, 0.34, -0.06), 0.15, ROCK_DARK, Vector3(1.0, 0.9, 1.0), 12)
	kit.sphere(Vector3(0.34, 0.09, 0.26), 0.2, ROCK_DARK, Vector3(1.0, 0.72, 1.0), 12)
	kit.sphere(Vector3(0.36, 0.08, -0.36), 0.13, ROCK, Vector3(1.0, 0.8, 1.0), 10)
	add_body(kit.commit())

	var glow := DecoKit.new()
	glow.cone(Vector3(-0.42, 0.07, 0.34), 0.07, 0.012, 0.3, Color("#65c5d9"), DecoKit.tilt_basis(0.22, 1.2), 7)
	glow.cone(Vector3(-0.3, 0.07, 0.44), 0.05, 0.01, 0.2, Color("#845bd9"), DecoKit.tilt_basis(0.3, 3.4), 7)
	add_glow(glow.commit(), 2.2, "Crystals", 1.0, 0.3)
