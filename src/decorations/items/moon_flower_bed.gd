extends DecoItem
## Moon Flower Bed — a ring of pale stones around dark soil, full of moon flowers that glow at night.
## Non-blocking: you can step through the flowers.

const STONE := Color("#d2be99")
const STONE_DARK := Color("#c9b892")
const SOIL := Color("#4a3f35")
const STEM := Color("#7ed957")
const PETAL := Color("#a0bee6")
const CENTER := Color("#d9bf61")


func _init() -> void:
	footprint = 0.75
	blocking = false
	collide_radius = 0.7
	collide_height = 0.4


func _build() -> void:
	var kit := DecoKit.new()
	kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.72, 0.0), Vector2(0.7, 0.08), Vector2(0.0, 0.09)]), 20, Transform3D.IDENTITY, SOIL)
	for i in 7:
		var a := TAU * float(i) / 7.0
		kit.sphere(Vector3(cos(a) * 0.71, 0.05, sin(a) * 0.71), 0.14 + float(i % 3) * 0.015, STONE if i % 2 == 0 else STONE_DARK, Vector3(1.0, 0.62, 1.0), 9)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7311
	var spots: Array[Vector3] = []
	for i in 5:
		var a2 := TAU * float(i) / 5.0 + 0.35
		var r := 0.2 + float(i % 2) * 0.19
		var base := Vector3(cos(a2) * r, 0.08, sin(a2) * r)
		var top := base + Vector3(rng.randf_range(-0.05, 0.05), rng.randf_range(0.26, 0.36), rng.randf_range(-0.05, 0.05))
		kit.tube(base, top, 0.022, STEM, 6)
		kit.sphere(base + Vector3(0.06, 0.03, 0.02), 0.09, STEM, Vector3(1.2, 0.35, 0.8), 7)
		spots.append(top)
	add_body(kit.commit())

	var glow := DecoKit.new()
	for i in spots.size():
		var p: Vector3 = spots[i]
		glow.extrude(DecoKit.star_poly(0.13, 0.055, 6), 0.035, PETAL, Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-72.0)) * Basis(Vector3.FORWARD, float(i) * 1.3), p))
		glow.sphere(p + Vector3(0.0, 0.03, 0.0), 0.042, CENTER, Vector3.ONE, 7)
	add_glow(glow.commit(), 2.2, "Blooms", 0.9, 0.3)
	add_ground_glow(1.1, Color("#799cd9"), 0.16)
