extends DecoItem
## Robot Buddy Statue — a chibi mint robot on a plinth who waves hello forever.

const SHELL := Color("#7fd8d0")
const SHELL_DARK := Color("#4fa79f")
const ACCENT := Color("#d9822f")
const SCREEN := Color("#1a2333")
const PLINTH := Color("#cbbb8b")
const PLINTH_DARK := Color("#d9c9a0")
const EYE := Color("#65c5d9")

var _arm: Node3D
var _head: Node3D


func _init() -> void:
	footprint = 0.7
	collide_radius = 0.5
	collide_height = 1.35


func _build() -> void:
	var kit := DecoKit.new()
	kit.rbox(Vector3(0.0, 0.13, 0.0), Vector3(0.96, 0.26, 0.96), 0.08, PLINTH)
	kit.rbox(Vector3(0.0, 0.31, 0.0), Vector3(0.78, 0.14, 0.78), 0.06, PLINTH_DARK)
	kit.rbox(Vector3(0.0, 0.16, -0.47), Vector3(0.5, 0.16, 0.05), 0.03, ACCENT, Basis.IDENTITY, 0)
	# body: a short rounded bean
	kit.rbox(Vector3(0.0, 0.62, 0.0), Vector3(0.5, 0.44, 0.42), 0.16, SHELL)
	kit.rbox(Vector3(0.0, 0.55, -0.2), Vector3(0.28, 0.2, 0.06), 0.03, SHELL_DARK, Basis.IDENTITY, 0)
	for s in [-1.0, 1.0]:
		kit.sphere(Vector3(0.17 * s, 0.44, 0.0), 0.11, SHELL_DARK, Vector3(1.0, 0.8, 1.0), 12)
		kit.rbox(Vector3(0.16 * s, 0.42, 0.02), Vector3(0.18, 0.14, 0.28), 0.07, ACCENT)
	add_body(kit.commit())

	# left arm is static, right arm waves
	var still := DecoKit.new()
	still.tube(Vector3(-0.27, 0.72, 0.0), Vector3(-0.33, 0.5, 0.02), 0.06, SHELL_DARK)
	still.sphere(Vector3(-0.34, 0.46, 0.02), 0.095, SHELL, Vector3.ONE, 12)
	add_body(still.commit(), "ArmL")

	_arm = pivot("ArmR", Vector3(0.27, 0.76, 0.0))
	var arm := DecoKit.new()
	arm.tube(Vector3.ZERO, Vector3(0.12, 0.26, 0.0), 0.06, SHELL_DARK)
	arm.sphere(Vector3(0.14, 0.31, 0.0), 0.1, SHELL, Vector3.ONE, 12)
	add_body(arm.commit(), "Limb", _arm)

	_head = pivot("Head", Vector3(0.0, 0.9, 0.0))
	var head := DecoKit.new()
	head.rbox(Vector3(0.0, 0.16, 0.0), Vector3(0.56, 0.44, 0.46), 0.17, SHELL)
	head.rbox(Vector3(0.0, 0.16, -0.22), Vector3(0.4, 0.3, 0.06), 0.09, SCREEN)
	head.tube(Vector3(0.0, 0.36, 0.0), Vector3(0.05, 0.54, 0.0), 0.022, SHELL_DARK)
	for s2 in [-1.0, 1.0]:
		head.sphere(Vector3(0.3 * s2, 0.14, 0.0), 0.07, ACCENT, Vector3(0.7, 1.0, 1.0), 10)
	add_body(head.commit(), "Skull", _head)

	var face := DecoKit.new()
	for s3 in [-1.0, 1.0]:
		face.rbox(Vector3(0.1 * s3, 0.19, -0.25), Vector3(0.07, 0.11, 0.03), 0.02, EYE, Basis.IDENTITY, 0)
	face.rbox(Vector3(0.0, 0.08, -0.25), Vector3(0.14, 0.035, 0.03), 0.014, EYE, Basis.IDENTITY, 0)
	for s4 in [-1.0, 1.0]:
		face.rbox(Vector3(0.19 * s4, 0.1, -0.25), Vector3(0.06, 0.03, 0.03), 0.012, Color("#d95d7c"), Basis.IDENTITY, 0)
	face.sphere(Vector3(0.06, 0.57, 0.0), 0.055, Color("#d9bf61"), Vector3.ONE, 10)
	add_glow(face.commit(), 2.4, "Face", 1.4, 0.2, 0.0, _head)
	animate()


func _animate(t: float, _delta: float) -> void:
	_arm.rotation.z = deg_to_rad(-52.0) + sin(t * 3.4) * 0.42
	_arm.rotation.x = sin(t * 3.4 + 1.0) * 0.08
	_head.rotation.y = sin(t * 1.1) * 0.14
	_head.position.y = 0.9 + sin(t * 2.2) * 0.012
