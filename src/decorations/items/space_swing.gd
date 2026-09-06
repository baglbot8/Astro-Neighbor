extends DecoItem
## Space Swing — a chrome A-frame with a padded seat that keeps swinging on its own.

const FRAME := Color("#8fa3bf")
const FRAME_DARK := Color("#6f819c")
const CAP := Color("#d96143")
const SEAT := Color("#7fd8d0")
const ROPE := Color("#4a4655")
const TOP_Y := 2.05
const HALF := 0.78

var _swing: Node3D


func _init() -> void:
	footprint = 1.2
	collide_radius = 0.42
	collide_height = 1.9


func _build() -> void:
	var kit := DecoKit.new()
	for s in [-1.0, 1.0]:
		var top := Vector3(HALF * s, TOP_Y, 0.0)
		for z in [-0.62, 0.62]:
			kit.tube(Vector3(HALF * s + 0.1 * s, 0.03, z), top, 0.055, FRAME)
			kit.sphere(Vector3(HALF * s + 0.1 * s, 0.05, z), 0.1, FRAME_DARK, Vector3(1.2, 0.55, 1.2), 12)
		kit.tube(Vector3(HALF * s + 0.05 * s, 0.75, -0.42), Vector3(HALF * s + 0.05 * s, 0.75, 0.42), 0.03, FRAME_DARK)
		kit.sphere(top, 0.1, CAP, Vector3.ONE, 12)
	kit.bar(Vector3(-HALF, TOP_Y, 0.0), Vector3(HALF, TOP_Y, 0.0), 0.05, FRAME, 10)
	kit.torus(Vector3(0.0, TOP_Y, 0.0), 0.08, 0.03, CAP, Basis(Vector3.RIGHT, deg_to_rad(90.0)), 14)
	add_body(kit.commit())

	_swing = pivot("Swing", Vector3(0.0, TOP_Y, 0.0))
	var s2 := DecoKit.new()
	for x in [-0.34, 0.34]:
		s2.bar(Vector3(x, 0.0, 0.0), Vector3(x, -0.92, 0.0), 0.022, ROPE, 6)
	s2.rbox(Vector3(0.0, -1.0, 0.0), Vector3(0.86, 0.14, 0.4), 0.06, SEAT)
	s2.rbox(Vector3(0.0, -0.93, 0.0), Vector3(0.7, 0.05, 0.28), 0.02, Color("#4fa79f"), Basis.IDENTITY, 0)
	add_body(s2.commit(), "Seat", _swing)

	var glow := DecoKit.new()
	for x2 in [-HALF, HALF]:
		glow.sphere(Vector3(x2, TOP_Y + 0.13, 0.0), 0.05, Color("#d9bf61"), Vector3.ONE, 10)
	add_glow(glow.commit(), 2.4, "Caps", 1.3, 0.3)
	animate()


func _animate(t: float, _delta: float) -> void:
	_swing.rotation.x = sin(t * 1.25) * deg_to_rad(15.0)
