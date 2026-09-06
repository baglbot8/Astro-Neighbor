extends DecoItem
## UFO Planter — a little flying saucer parked on three legs, glowing underneath, with a curious
## alien sprout under its glass canopy.

const HULL := Color("#7fd8d0")
const HULL_DARK := Color("#4fa79f")
const METAL := Color("#8fa3bf")
const LEAF := Color("#7ed957")
const BLOOM := Color("#d95d7c")

var _saucer: Node3D


func _init() -> void:
	footprint = 0.8
	collide_radius = 0.55
	collide_height = 1.05


func _build() -> void:
	var kit := DecoKit.new()
	for i in 3:
		var a := TAU * float(i) / 3.0 + 0.5
		kit.tube(Vector3(cos(a) * 0.42, 0.02, sin(a) * 0.42), Vector3(cos(a) * 0.3, 0.4, sin(a) * 0.3), 0.05, METAL, 7)
		kit.sphere(Vector3(cos(a) * 0.43, 0.05, sin(a) * 0.43), 0.09, HULL_DARK, Vector3(1.0, 0.6, 1.0), 9)
	add_body(kit.commit())

	_saucer = pivot("Saucer", Vector3(0.0, 0.62, 0.0))
	var hull := DecoKit.new()
	hull.lathe(PackedVector2Array([Vector2(0.0, -0.2), Vector2(0.3, -0.14), Vector2(0.66, 0.0), Vector2(0.62, 0.08), Vector2(0.3, 0.13), Vector2(0.0, 0.14)]), 19, Transform3D.IDENTITY, HULL)
	hull.torus(Vector3(0.0, 0.0, 0.0), 0.64, 0.05, HULL_DARK, Basis.IDENTITY, 19, 4)
	hull.lathe(PackedVector2Array([Vector2(0.3, 0.13), Vector2(0.29, 0.19)]), 16, Transform3D.IDENTITY, METAL, false)
	add_body(hull.commit(), "Hull", _saucer)

	var glow := DecoKit.new()
	glow.disc(Vector3(0.0, -0.21, 0.0), 0.3, Color("#65c5d9"), Basis(Vector3.RIGHT, PI), 14)
	for i in 6:
		var a2 := TAU * float(i) / 6.0
		glow.sphere(Vector3(cos(a2) * 0.55, -0.02, sin(a2) * 0.55), 0.052, Color("#d9bf61"), Vector3.ONE, 7)
	add_glow(glow.commit(), 2.6, "Lights", 2.4, 0.5, 1.0, _saucer)

	# the plant under the canopy
	var plant := DecoKit.new()
	plant.disc(Vector3(0.0, 0.2, 0.0), 0.26, Color("#4a3f35"), Basis.IDENTITY, 12)
	plant.tube(Vector3(0.0, 0.2, 0.0), Vector3(0.03, 0.44, 0.02), 0.035, LEAF)
	plant.sphere(Vector3(0.1, 0.4, 0.06), 0.13, LEAF, Vector3(1.0, 0.7, 1.0), 10)
	plant.sphere(Vector3(-0.12, 0.36, -0.05), 0.11, Color("#5cc44a"), Vector3(1.0, 0.7, 1.0), 10)
	plant.sphere(Vector3(0.02, 0.52, 0.0), 0.1, BLOOM, Vector3(1.0, 0.85, 1.0), 10)
	add_body(plant.commit(), "Plant", _saucer)

	var canopy := DecoKit.new()
	canopy.dome(Vector3(0.0, 0.15, 0.0), 0.32, Color.WHITE, 1.25, Basis.IDENTITY, 13)
	add_glass(canopy.commit(), Color("#a0bee6"), 0.22, "Canopy", _saucer)

	add_ground_glow(1.3, Color("#65c5d9"), 0.28)
	add_light(Vector3(0.0, 0.4, 0.0), Color("#5db2d9"), 1.4, 4.5)
	animate()


func _animate(t: float, _delta: float) -> void:
	_saucer.position.y = 0.62 + sin(t * 1.2) * 0.04
	_saucer.rotation.y = t * 0.3
	_saucer.rotation.z = sin(t * 0.8) * 0.035
