extends DecoItem
## Nebula Rug — a soft violet disc printed with swirling nebula rings and scattered stars.
## Non-blocking: you walk right over it.

const RUG := Color("#8a5cf0")
const RING_A := Color("#845bd9")
const RING_B := Color("#d95d7c")
const EDGE := Color("#5c3bb0")


func _init() -> void:
	footprint = 1.0
	blocking = false
	collide_radius = 1.0
	collide_height = 0.06


func _build() -> void:
	var kit := DecoKit.new()
	kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(1.02, 0.0), Vector2(1.05, 0.03), Vector2(1.02, 0.055), Vector2(0.0, 0.055)]), 44, Transform3D.IDENTITY, RUG)
	kit.torus(Vector3(0.0, 0.05, 0.0), 0.99, 0.028, EDGE, Basis.IDENTITY, 44, 4)
	kit.torus(Vector3(0.0, 0.057, 0.0), 0.74, 0.05, RING_A, Basis.IDENTITY, 36, 4)
	kit.torus(Vector3(0.0, 0.057, 0.0), 0.46, 0.045, RING_B, Basis.IDENTITY, 30, 4)
	kit.disc(Vector3(0.0, 0.058, 0.0), 0.2, RING_A, Basis.IDENTITY, 26)
	add_body(kit.commit())

	var glow := DecoKit.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 991
	for i in 9:
		var a := rng.randf() * TAU
		var r := sqrt(rng.randf()) * 0.9
		glow.extrude(DecoKit.star_poly(0.075, 0.032, 4), 0.012, Color("#d9bf61"), Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-90.0)) * Basis(Vector3.FORWARD, rng.randf() * TAU), Vector3(cos(a) * r, 0.062, sin(a) * r)))
	add_glow(glow.commit(), 1.6, "Stars", 1.3, 0.4)
