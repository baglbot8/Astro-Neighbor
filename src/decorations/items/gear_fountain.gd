extends DecoItem
## Gear Fountain — brass cogs turning above a chrome basin, spilling a fizzy blue arc of water.

const BASIN := Color("#b8c4d6")
const BASIN_DARK := Color("#8fa3bf")
const BRASS := Color("#d99246")
const BRASS_DARK := Color("#d98c33")
const WATER := Color("#65c5d9")

var _gears: Array[Node3D] = []
var _speeds: Array[float] = []


func _init() -> void:
	footprint = 1.1
	collide_radius = 0.9
	collide_height = 1.2


func _build() -> void:
	var kit := DecoKit.new()
	kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(1.0, 0.0), Vector2(1.02, 0.34), Vector2(0.92, 0.42), Vector2(0.86, 0.36), Vector2(0.86, 0.08), Vector2(0.0, 0.08)]), 30, Transform3D.IDENTITY, BASIN)
	kit.torus(Vector3(0.0, 0.4, 0.0), 0.94, 0.07, BASIN_DARK, Basis.IDENTITY, 30, 4)
	kit.lathe(PackedVector2Array([Vector2(0.0, 0.08), Vector2(0.34, 0.1), Vector2(0.26, 0.34), Vector2(0.2, 0.62), Vector2(0.17, 0.9), Vector2(0.0, 0.94)]), 14, Transform3D.IDENTITY, BASIN_DARK)
	kit.torus(Vector3(0.0, 0.62, 0.0), 0.22, 0.05, BASIN, Basis.IDENTITY, 14, 4)
	add_body(kit.commit())

	var glass := DecoKit.new()
	glass.disc(Vector3(0.0, 0.3, 0.0), 0.85, WATER, Basis.IDENTITY, 30)
	add_glass(glass.commit(), Color("#65c5d9"), 0.5, "Water")

	var specs := [
		[Vector3(-0.24, 0.98, 0.0), 0.44, 0.75, Vector3(0.0, 0.0, 1.0), BRASS],
		[Vector3(0.36, 0.72, 0.02), 0.28, -1.2, Vector3(0.0, 0.0, 1.0), BRASS_DARK],
	]
	for i in specs.size():
		var s: Array = specs[i]
		var node := pivot("Gear%d" % i, s[0])
		node.basis = DecoKit.axis_basis(s[3])
		_gears.append(node)
		_speeds.append(s[2])
		var g := DecoKit.new()
		var r: float = s[1]
		g.extrude(DecoKit.gear_poly(r * 0.86, r * 0.3, 8), r * 0.34, s[4], Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-90.0)), Vector3.ZERO))
		g.torus(Vector3.ZERO, r * 0.52, r * 0.1, BRASS_DARK if i % 2 == 0 else BRASS, Basis(Vector3.RIGHT, deg_to_rad(-90.0)), 12, 4)
		g.lathe(PackedVector2Array([Vector2(0.0, -r * 0.26), Vector2(r * 0.22, -r * 0.26), Vector2(r * 0.22, r * 0.26), Vector2(0.0, r * 0.26)]), 12, Transform3D.IDENTITY, Color("#6f819c"))
		add_metal(g.commit(), "Cog", node)

	var glow := DecoKit.new()
	glow.sphere(Vector3(0.0, 1.02, 0.0), 0.1, WATER, Vector3(1.0, 1.3, 1.0), 12)
	for i in 6:
		var a := TAU * float(i) / 6.0
		glow.sphere(Vector3(cos(a) * 0.62, 0.44 - float(i % 3) * 0.04, sin(a) * 0.62), 0.05, WATER, Vector3.ONE, 7)
	add_glow(glow.commit(), 2.4, "Spray", 2.0, 0.35)

	add_particles(22, 1.5, Vector3(0.0, 1.06, 0.0), Color("#6ac0d9"), 0.1, 0.9, 42.0, -1.6, 0.1)
	add_ground_glow(1.6, Color("#65c5d9"), 0.2)
	add_light(Vector3(0.0, 0.9, 0.0), Color("#5db2d9"), 1.4, 5.0)
	animate()


func _animate(_t: float, delta: float) -> void:
	for i in _gears.size():
		_gears[i].rotate_object_local(Vector3.UP, _speeds[i] * delta)
