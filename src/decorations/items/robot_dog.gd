extends DecoItem
## Robot Dog — a stubby orange pup with a screen face, perky ears and a tail that never stops wagging.
## A favor-only legendary.

const SHELL := Color("#d9822f")
const SHELL_DARK := Color("#e07f26")
const METAL := Color("#b8c4d6")
const SCREEN := Color("#1a2333")
const EYE := Color("#65c5d9")

var _tail: Node3D
var _head: Node3D


func _init() -> void:
	footprint = 0.55
	collide_radius = 0.36
	collide_height = 0.62


func _build() -> void:
	var kit := DecoKit.new()
	kit.rbox(Vector3(0.0, 0.36, 0.03), Vector3(0.42, 0.34, 0.62), 0.15, SHELL)
	kit.rbox(Vector3(0.0, 0.34, 0.06), Vector3(0.3, 0.16, 0.46), 0.07, SHELL_DARK, Basis.IDENTITY, 0)
	for s in [-1.0, 1.0]:
		for z in [-0.2, 0.24]:
			kit.tube(Vector3(0.17 * s, 0.24, z), Vector3(0.19 * s, 0.09, z), 0.06, METAL)
			kit.sphere(Vector3(0.19 * s, 0.07, z), 0.085, SHELL_DARK, Vector3(1.0, 0.75, 1.15), 10)
	add_body(kit.commit())

	_head = pivot("Head", Vector3(0.0, 0.5, -0.28))
	var head := DecoKit.new()
	head.rbox(Vector3(0.0, 0.02, -0.04), Vector3(0.38, 0.34, 0.36), 0.13, SHELL)
	head.rbox(Vector3(0.0, 0.0, -0.2), Vector3(0.26, 0.24, 0.05), 0.08, SCREEN)
	head.rbox(Vector3(0.0, -0.09, -0.24), Vector3(0.16, 0.1, 0.1), 0.045, SHELL_DARK)
	for s2 in [-1.0, 1.0]:
		head.cone(Vector3(0.13 * s2, 0.14, 0.0), 0.07, 0.01, 0.18, METAL, DecoKit.tilt_basis(deg_to_rad(20.0), 0.0 if s2 > 0.0 else PI), 8)
	add_body(head.commit(), "Skull", _head)

	var face := DecoKit.new()
	for s3 in [-1.0, 1.0]:
		face.rbox(Vector3(0.07 * s3, 0.03, -0.225), Vector3(0.06, 0.09, 0.02), 0.018, EYE, Basis.IDENTITY, 0)
	face.rbox(Vector3(0.0, -0.05, -0.225), Vector3(0.09, 0.028, 0.02), 0.012, EYE, Basis.IDENTITY, 0)
	add_glow(face.commit(), 2.2, "Face", 1.2, 0.15, 0.0, _head)

	_tail = pivot("Tail", Vector3(0.0, 0.46, 0.32))
	var tail := DecoKit.new()
	tail.tube(Vector3.ZERO, Vector3(0.0, 0.2, 0.12), 0.04, METAL)
	add_body(tail.commit(), "Rod", _tail)
	var tg := DecoKit.new()
	tg.sphere(Vector3(0.0, 0.24, 0.14), 0.06, Color("#65d9b2"), Vector3.ONE, 10)
	add_glow(tg.commit(), 2.6, "TailTip", 0.0, 0.0, 0.0, _tail)
	animate()


func _animate(t: float, _delta: float) -> void:
	_tail.rotation.z = sin(t * 7.0) * 0.5
	_tail.rotation.x = sin(t * 3.5) * 0.1
	_head.rotation.y = sin(t * 0.9) * 0.2
	_head.rotation.z = sin(t * 1.7) * 0.07
	_head.position.y = 0.5 + sin(t * 2.4) * 0.012
