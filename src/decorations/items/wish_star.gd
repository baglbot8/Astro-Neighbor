extends DecoItem
## Wishing Star — a fat golden star turning above a moon-rock cairn, trailing sparkles.
## A favor-only legendary.

const ROCK := Color("#8fa3bf")
const ROCK_DARK := Color("#6f819c")
const GOLD := Color("#d9bf61")
const HALO := Color("#e6d99c")

var _star: Node3D


func _init() -> void:
	footprint = 0.7
	collide_radius = 0.42
	collide_height = 0.9


func _build() -> void:
	var kit := DecoKit.new()
	kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.5, 0.0), Vector2(0.44, 0.1), Vector2(0.0, 0.12)]), 20, Transform3D.IDENTITY, ROCK_DARK)
	kit.sphere(Vector3(0.0, 0.14, 0.0), 0.34, ROCK, Vector3(1.0, 0.72, 1.0), 14)
	kit.sphere(Vector3(0.2, 0.22, 0.14), 0.19, ROCK_DARK, Vector3(1.0, 0.8, 1.0), 12)
	kit.sphere(Vector3(-0.18, 0.2, -0.12), 0.16, ROCK_DARK, Vector3(1.0, 0.85, 1.0), 12)
	kit.sphere(Vector3(0.02, 0.42, 0.0), 0.16, ROCK, Vector3(1.0, 0.8, 1.0), 12)
	add_body(kit.commit())

	_star = pivot("Star", Vector3(0.0, 1.16, 0.0))
	var glow := DecoKit.new()
	glow.extrude(DecoKit.star_poly(0.44, 0.19, 5), 0.22, GOLD, Transform3D.IDENTITY)
	glow.torus(Vector3.ZERO, 0.56, 0.03, HALO, Basis(Vector3.RIGHT, deg_to_rad(74.0)), 24)
	add_glow(glow.commit(), 3.2, "Star", 1.1, 0.16, 0.0, _star)

	add_particles(22, 2.0, Vector3(0.0, 1.16, 0.0), Color("#e6d49c"), 0.12, 0.35, 70.0, -0.15, 0.45)
	add_light(Vector3(0.0, 1.16, 0.0), Color("#d9bd79"), 2.4, 7.0)
	add_ground_glow(1.7, Color("#d9b569"), 0.3)
	animate()


func _animate(t: float, _delta: float) -> void:
	_star.rotation.y = t * 0.7
	_star.rotation.z = sin(t * 0.8) * 0.14
	_star.position.y = 1.16 + sin(t * 1.1) * 0.06
