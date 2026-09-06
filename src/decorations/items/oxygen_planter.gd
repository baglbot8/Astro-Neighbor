extends DecoItem
## Oxygen Tank Planter — a retired air tank repurposed as a flower pot, straps and valve included.

const TANK := Color("#57a3d9")
const TANK_DARK := Color("#3f8fd6")
const STRAP := Color("#4a4655")
const METAL := Color("#b8c4d6")
const LEAF := Color("#7ed957")
const PETAL := Color("#e6d19c")


func _init() -> void:
	footprint = 0.6
	collide_radius = 0.34
	collide_height = 1.0


func _build() -> void:
	var kit := DecoKit.new()
	kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.36, 0.0), Vector2(0.39, 0.06), Vector2(0.4, 0.05)]), 14, Transform3D.IDENTITY, METAL)
	kit.lathe(PackedVector2Array([Vector2(0.0, 0.04), Vector2(0.3, 0.06), Vector2(0.32, 0.5), Vector2(0.3, 0.78), Vector2(0.22, 0.86), Vector2(0.0, 0.86)]), 17, Transform3D.IDENTITY, TANK)
	for y in [0.24, 0.56]:
		kit.torus(Vector3(0.0, y, 0.0), 0.315, 0.038, STRAP, Basis.IDENTITY, 17, 4)
	kit.torus(Vector3(0.0, 0.84, 0.0), 0.24, 0.05, TANK_DARK, Basis.IDENTITY, 17, 4)
	kit.disc(Vector3(0.0, 0.85, 0.0), 0.23, Color("#4a3f35"), Basis.IDENTITY, 14)
	# side valve
	kit.tube(Vector3(0.3, 0.62, 0.0), Vector3(0.46, 0.62, 0.0), 0.05, METAL)
	kit.torus(Vector3(0.48, 0.62, 0.0), 0.1, 0.028, Color("#d94646"), Basis(Vector3.FORWARD, deg_to_rad(90.0)), 12, 4)
	add_body(kit.commit())

	var plant := DecoKit.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	for i in 5:
		var a := TAU * float(i) / 5.0 + 0.3
		var lean := DecoKit.tilt_basis(deg_to_rad(rng.randf_range(14.0, 30.0)), a)
		var top := Vector3(cos(a) * 0.08, 0.86, sin(a) * 0.08) + lean * Vector3(0.0, rng.randf_range(0.22, 0.38), 0.0)
		plant.tube(Vector3(cos(a) * 0.08, 0.86, sin(a) * 0.08), top, 0.026, LEAF, 6)
		plant.sphere(top + Vector3(0.0, 0.02, 0.0), 0.11, LEAF, Vector3(1.3, 0.5, 0.9), 8, Basis(Vector3.UP, -a))
	for i in 3:
		var a3 := TAU * float(i) / 3.0 + 1.1
		plant.tube(Vector3(cos(a3) * 0.06, 0.86, sin(a3) * 0.06), Vector3(cos(a3) * 0.13, 1.06 + float(i % 2) * 0.06, sin(a3) * 0.13), 0.022, Color("#5cc44a"), 6)
	add_body(plant.commit(), "Leaves")

	var glow := DecoKit.new()
	for i in 3:
		var a2 := TAU * float(i) / 3.0 + 1.1
		var p := Vector3(cos(a2) * 0.13, 1.06 + float(i % 2) * 0.06, sin(a2) * 0.13)
		glow.extrude(DecoKit.star_poly(0.11, 0.05, 6), 0.035, PETAL, Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-70.0)) * Basis(Vector3.FORWARD, a2), p))
		glow.sphere(p + Vector3(0.0, 0.02, 0.0), 0.032, Color("#d9bf61"), Vector3.ONE, 7)
	add_glow(glow.commit(), 2.0, "Blooms", 1.1, 0.28)
