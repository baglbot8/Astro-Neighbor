extends DecoItem
## Plasma Campfire — a ring of moon stones around a cold blue flame that flickers and throws light.

const STONE := Color("#8fa3bf")
const STONE_DARK := Color("#6f819c")
const ROD := Color("#4a4655")
const FLAME := Color("#65c5d9")
const FLAME_HOT := Color("#a0bee6")

var _flame: Node3D


func _init() -> void:
	footprint = 0.7
	collide_radius = 0.5
	collide_height = 0.35


func _build() -> void:
	var kit := DecoKit.new()
	for i in 7:
		var a := TAU * float(i) / 7.0
		var r := 0.56
		var c: Color = STONE if i % 2 == 0 else STONE_DARK
		kit.sphere(Vector3(cos(a) * r, 0.09, sin(a) * r), 0.19 + float(i % 3) * 0.02, c, Vector3(1.0, 0.72, 1.0), 12)
	kit.disc(Vector3(0.0, 0.03, 0.0), 0.48, Color("#3a3550"), Basis.IDENTITY, 18)
	for i in 3:
		var a2 := PI * float(i) / 3.0
		kit.tube(Vector3(cos(a2) * 0.3, 0.06, sin(a2) * 0.3), Vector3(-cos(a2) * 0.3, 0.22, -sin(a2) * 0.3), 0.045, ROD)
	add_body(kit.commit())

	_flame = pivot("Flame", Vector3(0.0, 0.16, 0.0))
	var glow := DecoKit.new()
	glow.cone(Vector3.ZERO, 0.26, 0.0, 0.62, FLAME, Basis.IDENTITY, 10)
	glow.cone(Vector3(0.0, 0.04, 0.0), 0.15, 0.0, 0.44, FLAME_HOT, Basis.IDENTITY, 10)
	glow.sphere(Vector3(0.0, 0.06, 0.0), 0.2, FLAME, Vector3(1.0, 0.6, 1.0), 12)
	add_glow(glow.commit(), 3.2, "Plasma", 5.5, 0.3, 0.0, _flame)

	add_particles(18, 1.4, Vector3(0.0, 0.3, 0.0), Color("#6ac0d9"), 0.11, 0.75, 18.0, 0.35, 0.12)
	add_light(Vector3(0.0, 0.45, 0.0), Color("#5db2d9"), 2.6, 7.0)
	add_ground_glow(1.8, Color("#65c5d9"), 0.3)
	animate()


func _animate(t: float, _delta: float) -> void:
	var s := 1.0 + sin(t * 7.3) * 0.09 + sin(t * 11.7) * 0.05
	_flame.scale = Vector3(1.0 / sqrt(s), s, 1.0 / sqrt(s))
	_flame.rotation.y = sin(t * 2.1) * 0.25
