extends DecoItem
## Satellite Dish — a chunky white dish on an orange mount that slowly scans the sky.

const DISH := Color("#cfcfdf")
const DISH_BACK := Color("#b1b7cf")
const MOUNT := Color("#d9822f")
const METAL := Color("#6f819c")

var _yaw: Node3D
var _tilt: Node3D


func _init() -> void:
	footprint = 0.85
	collide_radius = 0.5
	collide_height = 1.3


func _build() -> void:
	var kit := DecoKit.new()
	kit.rbox(Vector3(0.0, 0.11, 0.0), Vector3(0.86, 0.22, 0.86), 0.08, METAL)
	for s in [-1.0, 1.0]:
		for z in [-1.0, 1.0]:
			kit.sphere(Vector3(0.32 * s, 0.05, 0.32 * z), 0.08, Color("#4a4655"), Vector3(1.0, 0.6, 1.0), 10)
	kit.cone(Vector3(0.0, 0.2, 0.0), 0.16, 0.13, 0.44, MOUNT, Basis.IDENTITY, 14)
	add_body(kit.commit())

	var base_glow := DecoKit.new()
	base_glow.sphere(Vector3(0.3, 0.24, 0.3), 0.05, Color("#d94646"), Vector3.ONE, 10)
	add_glow(base_glow.commit(), 2.6, "Beacon", 3.2, 0.8, 1.0)

	_yaw = pivot("Yaw", Vector3(0.0, 0.64, 0.0))
	var neck := DecoKit.new()
	neck.sphere(Vector3.ZERO, 0.15, METAL, Vector3(1.0, 0.85, 1.0), 14)
	for s2 in [-1.0, 1.0]:
		neck.rbox(Vector3(0.19 * s2, 0.14, 0.0), Vector3(0.09, 0.34, 0.16), 0.04, MOUNT, Basis.IDENTITY, 0)
	add_metal(neck.commit(), "Neck", _yaw)

	_tilt = pivot("Tilt", Vector3(0.0, 0.28, 0.0), _yaw)
	var d := DecoKit.new()
	var prof := PackedVector2Array()
	for i in 9:
		var f := float(i) / 8.0
		prof.append(Vector2(f * 0.72, f * f * 0.34))
	prof.append(Vector2(0.76, 0.4))
	prof.append(Vector2(0.74, 0.44))
	for i in range(8, -1, -1):
		var f2 := float(i) / 8.0
		prof.append(Vector2(f2 * 0.7, f2 * f2 * 0.34 + 0.06))
	d.lathe(prof, 22, Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-30.0)), Vector3.ZERO), DISH)
	d.torus(Vector3(0.0, 0.0, 0.0), 0.75, 0.045, MOUNT, Basis(Vector3.RIGHT, deg_to_rad(-30.0)) * Basis(Vector3.RIGHT, deg_to_rad(0.0)), 22)
	add_body(d.commit(), "Dish", _tilt)
	# feed horn on three struts
	var horn := DecoKit.new()
	var up := Basis(Vector3.RIGHT, deg_to_rad(-30.0))
	var focus: Vector3 = up * Vector3(0.0, 0.62, 0.0)
	for i in 3:
		var a := TAU * float(i) / 3.0
		horn.tube(up * Vector3(cos(a) * 0.42, 0.1, sin(a) * 0.42), focus, 0.022, DISH_BACK)
	horn.cone(focus, 0.06, 0.11, 0.14, METAL, up, 12)
	add_metal(horn.commit(), "Horn", _tilt)
	var hg := DecoKit.new()
	hg.sphere(focus + up * Vector3(0.0, 0.16, 0.0), 0.05, Color("#65c5d9"), Vector3.ONE, 10)
	add_glow(hg.commit(), 2.4, "Feed", 1.6, 0.4, 0.0, _tilt)
	animate()


func _animate(t: float, _delta: float) -> void:
	_yaw.rotation.y = sin(t * 0.18) * 1.5 + t * 0.05
	_tilt.rotation.x = sin(t * 0.31) * 0.16 - 0.1
