extends DecoItem
## Picnic Table — a fat cream slab on orange X-legs with two benches and a little lantern in the middle.

const TOP := Color("#cbbb8b")
const TOP_DARK := Color("#d9c9a0")
const LEG := Color("#d96143")
const METAL := Color("#8fa3bf")


func _init() -> void:
	footprint = 1.1
	collide_radius = 0.9
	collide_height = 0.78


func _build() -> void:
	var kit := DecoKit.new()
	kit.rbox(Vector3(0.0, 0.74, 0.0), Vector3(1.8, 0.15, 0.92), 0.07, TOP)
	for z in [-0.28, 0.0, 0.28]:
		kit.rbox(Vector3(0.0, 0.815, z), Vector3(1.7, 0.02, 0.02), 0.008, TOP_DARK, Basis.IDENTITY, 0)
	for s in [-1.0, 1.0]:
		# X legs
		kit.bar(Vector3(0.62 * s, 0.0, -0.62), Vector3(0.62 * s, 0.72, 0.42), 0.055, LEG, 8)
		kit.bar(Vector3(0.62 * s, 0.0, 0.62), Vector3(0.62 * s, 0.72, -0.42), 0.055, LEG, 8)
		kit.rbox(Vector3(0.62 * s, 0.42, 0.0), Vector3(0.14, 0.06, 1.7), 0.03, METAL, Basis.IDENTITY, 0)
		# benches
		kit.rbox(Vector3(0.0, 0.44, 0.78 * s), Vector3(1.7, 0.13, 0.36), 0.06, TOP)
		kit.rbox(Vector3(0.0, 0.36, 0.78 * s), Vector3(1.4, 0.05, 0.24), 0.02, TOP_DARK, Basis.IDENTITY, 0)
	add_body(kit.commit())

	var lamp := DecoKit.new()
	lamp.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.11, 0.0), Vector2(0.1, 0.04), Vector2(0.05, 0.05)]), 12, Transform3D(Basis.IDENTITY, Vector3(0.0, 0.82, 0.0)), METAL)
	lamp.tube(Vector3(0.0, 0.86, 0.0), Vector3(0.0, 0.96, 0.0), 0.018, METAL)
	add_body(lamp.commit(), "Lamp")

	var glow := DecoKit.new()
	glow.sphere(Vector3(0.0, 0.98, 0.0), 0.09, Color("#d9bf61"), Vector3(1.0, 1.2, 1.0), 12)
	add_glow(glow.commit(), 2.6, "Lantern", 1.0, 0.18)
	add_light(Vector3(0.0, 1.0, 0.0), Color("#d9af70"), 1.2, 4.5)
