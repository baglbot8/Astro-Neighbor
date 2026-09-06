extends DecoItem
## Crater Bench — a chunky moon-rock bench with cratered seat dimples and a warm orange trim.

const ROCK := Color("#cbbb8b")
const ROCK_DARK := Color("#d9c9a0")
const LEG := Color("#8fa3bf")
const TRIM := Color("#d96143")


func _init() -> void:
	footprint = 0.95
	collide_radius = 0.78
	collide_height = 0.7


func _build() -> void:
	var kit := DecoKit.new()
	for s in [-1.0, 1.0]:
		kit.rbox(Vector3(0.66 * s, 0.21, 0.0), Vector3(0.26, 0.42, 0.66), 0.1, LEG)
		kit.rbox(Vector3(0.66 * s, 0.04, 0.0), Vector3(0.36, 0.08, 0.78), 0.04, ROCK_DARK, Basis.IDENTITY, 0)
	kit.rbox(Vector3(0.0, 0.52, 0.0), Vector3(1.76, 0.2, 0.74), 0.09, ROCK)
	kit.rbox(Vector3(0.0, 0.4, 0.0), Vector3(1.5, 0.08, 0.5), 0.04, TRIM, Basis.IDENTITY, 0)
	# crater dimples pressed into the seat
	for d in [-0.52, 0.0, 0.58]:
		kit.torus(Vector3(d, 0.615, -0.06), 0.15, 0.03, Color("#c8b78e"), Basis.IDENTITY, 14)
		kit.lathe(PackedVector2Array([Vector2(0.15, 0.02), Vector2(0.1, -0.02), Vector2(0.0, -0.035)]), 14, Transform3D(Basis.IDENTITY, Vector3(d, 0.6, -0.06)), Color("#a8956c"))
	# backrest, leaning back a touch
	var back := Basis(Vector3.RIGHT, deg_to_rad(-9.0))
	kit.rbox(Vector3(0.0, 0.92, 0.33), Vector3(1.7, 0.52, 0.17), 0.08, ROCK, back)
	kit.rbox(Vector3(0.0, 1.17, 0.35), Vector3(1.72, 0.1, 0.21), 0.045, TRIM, back, 0)
	for s2 in [-1.0, 1.0]:
		kit.tube(Vector3(0.72 * s2, 0.56, 0.3), Vector3(0.76 * s2, 1.02, 0.36), 0.05, LEG)
	add_body(kit.commit())

	var glow := DecoKit.new()
	for s3 in [-1.0, 1.0]:
		glow.sphere(Vector3(0.83 * s3, 0.53, 0.0), 0.05, Color("#65c5d9"), Vector3.ONE, 10)
	add_glow(glow.commit(), 2.0, "Studs", 1.2, 0.3)
