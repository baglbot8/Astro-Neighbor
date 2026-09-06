extends DecoItem
## Floating Orb Light — a glass bubble hovering in a three-pronged cradle, bobbing and turning.

const METAL := Color("#8fa3bf")
const DARK := Color("#6f819c")
const CORE := Color("#65c5d9")

var _orb: Node3D


func _init() -> void:
	footprint = 0.5
	collide_radius = 0.3
	collide_height = 0.95


func _build() -> void:
	var kit := DecoKit.new()
	kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.34, 0.0), Vector2(0.3, 0.08), Vector2(0.14, 0.14), Vector2(0.0, 0.14)]), 20, Transform3D.IDENTITY, DARK)
	for i in 3:
		var a := TAU * float(i) / 3.0 + 0.4
		var foot := Vector3(cos(a) * 0.22, 0.12, sin(a) * 0.22)
		var tip := Vector3(cos(a) * 0.3, 0.66, sin(a) * 0.3)
		kit.tube(foot, tip, 0.045, METAL)
		kit.sphere(tip, 0.06, Color("#d9822f"))
	kit.torus(Vector3(0.0, 0.12, 0.0), 0.3, 0.035, Color("#d9822f"))
	add_body(kit.commit())

	_orb = pivot("Orb", Vector3(0.0, 0.92, 0.0))
	var core := DecoKit.new()
	core.sphere(Vector3.ZERO, 0.19, CORE, Vector3.ONE, 18)
	core.torus(Vector3.ZERO, 0.26, 0.022, Color("#a0bee6"), Basis(Vector3.FORWARD, deg_to_rad(24.0)))
	add_glow(core.commit(), 2.8, "Core", 1.4, 0.2, 0.0, _orb)
	var shell := DecoKit.new()
	shell.sphere(Vector3.ZERO, 0.27, Color.WHITE, Vector3.ONE, 18)
	add_glass(shell.commit(), Color("#79c4d9"), 0.2, "Shell", _orb)

	add_light(Vector3(0.0, 0.95, 0.0), Color("#6ac0d9"), 2.0, 6.0)
	add_ground_glow(1.3, Color("#65c5d9"), 0.25)
	animate()


func _animate(t: float, _delta: float) -> void:
	_orb.position.y = 0.92 + sin(t * 1.5) * 0.055
	_orb.rotation.y = t * 0.55
