extends DecoItem
## Star Projector — a pierced navy globe on a little tripod that turns slowly and throws sparks of
## starlight into the air.

const SHELL := Color("#2a2f45")
const DEEP := Color("#1a2333")
const METAL := Color("#8fa3bf")
const SPARK := Color("#a0bee6")

var _globe: Node3D


func _init() -> void:
	footprint = 0.5
	collide_radius = 0.28
	collide_height = 0.8


func _build() -> void:
	var kit := DecoKit.new()
	kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.3, 0.0), Vector2(0.26, 0.09), Vector2(0.1, 0.13), Vector2(0.0, 0.13)]), 18, Transform3D.IDENTITY, METAL)
	kit.torus(Vector3(0.0, 0.1, 0.0), 0.26, 0.03, Color("#d9822f"))
	for i in 3:
		var a := TAU * float(i) / 3.0 + 0.5
		kit.tube(Vector3(cos(a) * 0.16, 0.11, sin(a) * 0.16), Vector3(cos(a) * 0.09, 0.4, sin(a) * 0.09), 0.035, METAL, 7)
	add_body(kit.commit())

	_globe = pivot("Globe", Vector3(0.0, 0.58, 0.0))
	var shell := DecoKit.new()
	shell.sphere(Vector3.ZERO, 0.25, SHELL, Vector3.ONE, 15)
	shell.torus(Vector3.ZERO, 0.255, 0.022, DEEP, Basis(Vector3.RIGHT, deg_to_rad(90.0)), 14, 4)
	shell.torus(Vector3.ZERO, 0.255, 0.022, DEEP, Basis.IDENTITY, 14, 4)
	add_body(shell.commit(), "Shell", _globe)

	var glow := DecoKit.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260905
	for i in 11:
		var d := Vector3(rng.randf_range(-1.0, 1.0), rng.randf_range(-0.6, 1.0), rng.randf_range(-1.0, 1.0)).normalized()
		glow.sphere(d * 0.245, rng.randf_range(0.026, 0.045), SPARK, Vector3.ONE, 6)
	glow.extrude(DecoKit.star_poly(0.1, 0.042, 5), 0.05, Color("#d9bf61"), Transform3D(Basis.IDENTITY, Vector3(0.0, 0.3, 0.0)))
	add_glow(glow.commit(), 3.0, "Stars", 2.2, 0.35, 0.0, _globe)

	add_particles(20, 2.4, Vector3(0.0, 0.62, 0.0), Color("#a0bee6"), 0.1, 0.42, 60.0, -0.12, 0.22)
	add_light(Vector3(0.0, 0.6, 0.0), Color("#799cd9"), 1.3, 5.0)
	animate()


func _animate(t: float, _delta: float) -> void:
	_globe.rotation.y = t * 0.42
	_globe.rotation.x = sin(t * 0.3) * 0.12
