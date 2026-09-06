extends DecoItem
## Space Telescope — a cream tube with orange bands on a tripod, sweeping slowly across the sky.

const TUBE := Color("#cfcfdf")
const BAND := Color("#d96143")
const METAL := Color("#8fa3bf")
const DARK := Color("#4a4655")

var _yaw: Node3D
var _tube: Node3D


func _init() -> void:
	footprint = 0.8
	collide_radius = 0.42
	collide_height = 1.35


func _build() -> void:
	var kit := DecoKit.new()
	for i in 3:
		var a := TAU * float(i) / 3.0 + 0.5
		var foot := Vector3(cos(a) * 0.52, 0.0, sin(a) * 0.52)
		kit.tube(foot + Vector3(0.0, 0.04, 0.0), Vector3(cos(a) * 0.09, 0.86, sin(a) * 0.09), 0.045, METAL)
		kit.sphere(foot + Vector3(0.0, 0.05, 0.0), 0.09, DARK, Vector3(1.2, 0.5, 1.2), 10)
	for i in 3:
		var a2 := TAU * float(i) / 3.0 + 0.5
		var b := TAU * float((i + 1) % 3) / 3.0 + 0.5
		kit.bar(Vector3(cos(a2) * 0.3, 0.36, sin(a2) * 0.3), Vector3(cos(b) * 0.3, 0.36, sin(b) * 0.3), 0.022, METAL, 6)
	kit.sphere(Vector3(0.0, 0.9, 0.0), 0.13, METAL, Vector3(1.0, 0.9, 1.0), 14)
	add_body(kit.commit())

	_yaw = pivot("Yaw", Vector3(0.0, 0.92, 0.0))
	_tube = pivot("Tube", Vector3.ZERO, _yaw)
	var t := DecoKit.new()
	var lean := Basis(Vector3.RIGHT, deg_to_rad(52.0))
	t.cone(lean * Vector3(0.0, -0.42, 0.0), 0.155, 0.185, 1.0, TUBE, lean, 16)
	t.lathe(PackedVector2Array([Vector2(0.19, 0.0), Vector2(0.19, 0.1)]), 16, Transform3D(lean, lean * Vector3(0.0, 0.2, 0.0)), BAND, false)
	t.lathe(PackedVector2Array([Vector2(0.165, 0.0), Vector2(0.165, 0.1)]), 16, Transform3D(lean, lean * Vector3(0.0, -0.24, 0.0)), BAND, false)
	t.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.2, 0.0), Vector2(0.19, 0.04), Vector2(0.0, 0.04)]), 16, Transform3D(lean, lean * Vector3(0.0, 0.58, 0.0)), DARK)
	# eyepiece sticking out the back
	t.cone(lean * Vector3(0.0, -0.4, 0.0), 0.06, 0.05, 0.22, DARK, lean * Basis(Vector3.RIGHT, deg_to_rad(90.0)), 12)
	t.rbox(lean * Vector3(0.0, 0.0, 0.0) + Vector3(0.0, -0.02, 0.0), Vector3(0.36, 0.1, 0.12), 0.04, BAND, lean, 0)
	add_body(t.commit(), "Barrel", _tube)

	var g := DecoKit.new()
	g.disc(lean * Vector3(0.0, 0.6, 0.0), 0.17, Color("#65c5d9"), lean, 16)
	add_glow(g.commit(), 1.8, "Lens", 0.7, 0.25, 0.0, _tube)
	animate()


func _animate(t: float, _delta: float) -> void:
	_yaw.rotation.y = sin(t * 0.22) * 0.9
	_tube.rotation.x = sin(t * 0.16 + 1.0) * 0.12
