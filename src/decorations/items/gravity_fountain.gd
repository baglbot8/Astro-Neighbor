extends DecoItem
## Gravity Well Fountain — water forgets which way is down here and spirals up around a dark core.
## A favor-only legendary.

const RIM := Color("#c2ccde")
const RIM_DARK := Color("#b8c4d6")
const VOID := Color("#1a2333")
const WATER := Color("#65c5d9")
const WATER_DEEP := Color("#3f8fd6")

var _spiral: Node3D
var _blobs: Array[Node3D] = []


func _init() -> void:
	footprint = 1.0
	collide_radius = 0.8
	collide_height = 1.4


func _build() -> void:
	var kit := DecoKit.new()
	kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.92, 0.0), Vector2(0.95, 0.24), Vector2(0.86, 0.34), Vector2(0.8, 0.26), Vector2(0.78, 0.1), Vector2(0.0, 0.08)]), 30, Transform3D.IDENTITY, RIM)
	kit.torus(Vector3(0.0, 0.32, 0.0), 0.88, 0.06, RIM_DARK, Basis.IDENTITY, 30, 4)
	for i in 6:
		var a := TAU * float(i) / 6.0
		kit.rbox(Vector3(cos(a) * 0.88, 0.14, sin(a) * 0.88), Vector3(0.1, 0.28, 0.2), 0.04, RIM_DARK, Basis(Vector3.UP, -a), 0)
	kit.lathe(PackedVector2Array([Vector2(0.0, 0.08), Vector2(0.44, 0.08), Vector2(0.36, 0.02), Vector2(0.0, 0.0)]), 18, Transform3D.IDENTITY, VOID)
	add_body(kit.commit())

	var core := DecoKit.new()
	core.sphere(Vector3(0.0, 0.3, 0.0), 0.3, VOID, Vector3(1.0, 0.86, 1.0), 16)
	core.torus(Vector3(0.0, 0.3, 0.0), 0.34, 0.05, Color("#2a2f45"), Basis(Vector3.FORWARD, deg_to_rad(16.0)), 18, 4)
	add_body(core.commit(), "Core")

	var glow := DecoKit.new()
	glow.cone(Vector3(0.0, 0.52, 0.0), 0.09, 0.03, 0.86, WATER, Basis.IDENTITY, 12)
	glow.sphere(Vector3(0.0, 1.42, 0.0), 0.11, Color("#a0bee6"), Vector3(1.0, 1.3, 1.0), 12)
	glow.torus(Vector3(0.0, 0.16, 0.0), 0.56, 0.06, WATER_DEEP, Basis.IDENTITY, 22, 4)
	add_glow(glow.commit(), 2.6, "Column", 1.6, 0.3)

	_spiral = pivot("Spiral", Vector3(0.0, 0.0, 0.0))
	for i in 7:
		var f := float(i) / 7.0
		var node := pivot("Blob%d" % i, Vector3.ZERO, _spiral)
		node.rotation.y = f * TAU * 1.5
		_blobs.append(node)
		var b := DecoKit.new()
		var r: float = lerpf(0.78, 0.2, f)
		b.sphere(Vector3(r, 0.24 + f * 1.16, 0.0), lerpf(0.17, 0.075, f), WATER, Vector3(1.0, 0.88, 1.0), 12)
		add_glow(b.commit(), 2.4, "Drop", 2.2, 0.28, 0.0, node)

	add_particles(26, 2.0, Vector3(0.0, 0.6, 0.0), Color("#6ac0d9"), 0.1, 0.5, 12.0, 0.5, 0.5)
	add_ground_glow(1.8, Color("#65c5d9"), 0.26)
	add_light(Vector3(0.0, 0.8, 0.0), Color("#5db2d9"), 2.0, 6.5)
	animate()


func _animate(t: float, _delta: float) -> void:
	_spiral.rotation.y = t * 0.9
	for i in _blobs.size():
		_blobs[i].position.y = sin(t * 1.4 + float(i) * 0.8) * 0.05
