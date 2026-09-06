extends DecoItem
## Alien Plant Pot — a bubblegum pot of curious violet tentacles that sway and blink their tips.

const POT := Color("#d95d7c")
const POT_DARK := Color("#e0708f")
const SOIL := Color("#4a3f35")
const STALK := Color("#845bd9")
const STALK_DARK := Color("#8a5cf0")
const SEGMENTS := 5

var _arms: Array[Node3D] = []
var _phases: Array[float] = []


func _init() -> void:
	footprint = 0.55
	collide_radius = 0.34
	collide_height = 0.95


func _build() -> void:
	var kit := DecoKit.new()
	kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.26, 0.0), Vector2(0.33, 0.34), Vector2(0.36, 0.42), Vector2(0.32, 0.44), Vector2(0.0, 0.44)]), 15, Transform3D.IDENTITY, POT)
	kit.torus(Vector3(0.0, 0.42, 0.0), 0.34, 0.045, POT_DARK, Basis.IDENTITY, 15, 4)
	kit.torus(Vector3(0.0, 0.2, 0.0), 0.3, 0.03, POT_DARK, Basis.IDENTITY, 15, 4)
	kit.disc(Vector3(0.0, 0.43, 0.0), 0.31, SOIL, Basis.IDENTITY, 14)
	add_body(kit.commit())

	for i in 3:
		var a := TAU * float(i) / 3.0 + 0.7
		var arm := pivot("Arm%d" % i, Vector3(cos(a) * 0.13, 0.44, sin(a) * 0.13))
		arm.rotation.y = -a
		_arms.append(arm)
		_phases.append(float(i) * 2.1)
		var stalk := DecoKit.new()
		var h := 0.46 + float(i % 2) * 0.12
		var prev := Vector3.ZERO
		for s in SEGMENTS:
			var f := float(s + 1) / float(SEGMENTS)
			var p := Vector3(sin(f * 1.6) * 0.2, h * f, 0.0)
			stalk.tube(prev, p, lerpf(0.1, 0.055, f), STALK if s % 2 == 0 else STALK_DARK, 7)
			prev = p
		stalk.sphere(prev, 0.1, STALK, Vector3(1.0, 1.15, 1.0), 9)
		add_body(stalk.commit(), "Stalk%d" % i, arm)
		var g := DecoKit.new()
		g.sphere(prev + Vector3(0.0, 0.075, 0.0), 0.07, Color("#65d9b2"), Vector3.ONE, 8)
		add_glow(g.commit(), 2.4, "Tip%d" % i, 1.4 + float(i) * 0.3, 0.4, 0.0, arm)
	animate()


func _animate(t: float, _delta: float) -> void:
	for i in _arms.size():
		var p: float = _phases[i]
		_arms[i].rotation.z = sin(t * 1.5 + p) * 0.16
		_arms[i].rotation.x = sin(t * 1.1 + p * 0.7) * 0.1
