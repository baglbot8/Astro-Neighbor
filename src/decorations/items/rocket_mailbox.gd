extends DecoItem
## Rocket Mailbox — a tiny red-nosed rocket on a post, with a porthole, fins and a little signal flag.

const HULL := Color("#cfcfdf")
const NOSE := Color("#d94646")
const METAL := Color("#8fa3bf")
const FLAG := Color("#d9af4f")


func _init() -> void:
	footprint = 0.5
	collide_radius = 0.3
	collide_height = 1.4


func _build() -> void:
	var kit := DecoKit.new()
	kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.3, 0.0), Vector2(0.27, 0.09), Vector2(0.12, 0.14), Vector2(0.0, 0.15)]), 18, Transform3D.IDENTITY, METAL)
	kit.cone(Vector3(0.0, 0.12, 0.0), 0.075, 0.06, 0.62, METAL, Basis.IDENTITY, 12)
	kit.lathe(PackedVector2Array([Vector2(0.0, 0.74), Vector2(0.26, 0.76), Vector2(0.28, 1.14), Vector2(0.24, 1.24), Vector2(0.0, 1.26)]), 20, Transform3D.IDENTITY, HULL)
	kit.torus(Vector3(0.0, 0.86, 0.0), 0.27, 0.035, NOSE, Basis.IDENTITY, 18)
	kit.lathe(PackedVector2Array([Vector2(0.24, 1.24), Vector2(0.2, 1.36), Vector2(0.1, 1.46), Vector2(0.0, 1.5)]), 20, Transform3D.IDENTITY, NOSE)
	# three fins
	for i in 3:
		var a := TAU * float(i) / 3.0 + 0.5
		var b := Basis(Vector3.UP, -a)
		kit.extrude(PackedVector2Array([Vector2(0.2, 0.76), Vector2(0.46, 0.72), Vector2(0.5, 0.78), Vector2(0.26, 0.98)]), 0.05, NOSE, Transform3D(b, Vector3.ZERO))
	# letter slot
	kit.rbox(Vector3(0.0, 0.82, -0.25), Vector3(0.28, 0.07, 0.08), 0.025, Color("#2a2f45"), Basis.IDENTITY, 0)
	# signal flag on the side
	kit.tube(Vector3(0.28, 0.92, 0.06), Vector3(0.42, 1.24, 0.06), 0.022, METAL)
	kit.extrude(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.24, 0.06), Vector2(0.0, 0.14)]), 0.03, FLAG, Transform3D(Basis(Vector3.UP, deg_to_rad(90.0)), Vector3(0.42, 1.12, 0.06)))
	add_body(kit.commit())

	add_glass(_port_glass(), Color("#5db2d9"), 0.3, "Port")

	var glow := DecoKit.new()
	glow.disc(Vector3(0.0, 1.05, -0.262), 0.11, Color("#65c5d9"), Basis(Vector3.RIGHT, deg_to_rad(-90.0)), 14)
	glow.sphere(Vector3(0.0, 1.53, 0.0), 0.05, Color("#d9bf61"), Vector3.ONE, 10)
	add_glow(glow.commit(), 2.2, "Glow", 1.8, 0.4, 1.0)


func _port_glass() -> ArrayMesh:
	var g := DecoKit.new()
	g.sphere(Vector3(0.0, 1.05, -0.245), 0.12, Color.WHITE, Vector3(1.0, 1.0, 0.5), 14)
	return g.commit()
