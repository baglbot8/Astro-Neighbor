extends DecoItem
## Alien Egg — a speckled mint egg in a twiggy nest. Something inside is definitely breathing.

const NEST := Color("#b39c78")
const NEST_DARK := Color("#8a7757")
const EGG := Color("#65d9b2")
const EGG_DARK := Color("#4fc9a3")

var _egg: Node3D


func _init() -> void:
	footprint = 0.5
	collide_radius = 0.34
	collide_height = 0.65


func _build() -> void:
	var kit := DecoKit.new()
	kit.lathe(PackedVector2Array([Vector2(0.0, 0.02), Vector2(0.42, 0.0), Vector2(0.46, 0.14), Vector2(0.36, 0.2), Vector2(0.3, 0.12), Vector2(0.0, 0.1)]), 20, Transform3D.IDENTITY, NEST_DARK)
	for i in 9:
		var a := TAU * float(i) / 11.0
		var r := 0.4 + float(i % 3) * 0.02
		var y := 0.13 + float(i % 4) * 0.035
		var lead := a + 0.85
		var trail := a - 0.85
		kit.tube(Vector3(cos(trail) * r, y - 0.03, sin(trail) * r), Vector3(cos(lead) * r, y + 0.02, sin(lead) * r), 0.045, NEST if i % 2 == 0 else NEST_DARK, 6)
	add_body(kit.commit())

	_egg = pivot("Egg", Vector3(0.0, 0.24, 0.0))
	var e := DecoKit.new()
	e.lathe(_egg_profile(), 16, Transform3D.IDENTITY, EGG)
	var rng := RandomNumberGenerator.new()
	rng.seed = 3121
	for i in 7:
		var d := Vector3(rng.randf_range(-1.0, 1.0), rng.randf_range(-0.4, 0.9), rng.randf_range(-1.0, 1.0)).normalized()
		e.sphere(Vector3(d.x * 0.2, 0.22 + d.y * 0.16, d.z * 0.2), rng.randf_range(0.045, 0.075), EGG_DARK, Vector3(1.0, 0.55, 1.0), 7)
	add_body(e.commit(), "Shell", _egg)

	var glow := DecoKit.new()
	glow.sphere(Vector3(0.0, 0.2, 0.0), 0.19, Color("#9ce6d0"), Vector3(1.0, 1.35, 1.0), 12)
	add_glow(glow.commit(), 1.6, "Inner", 1.9, 0.6, 0.0, _egg)
	add_ground_glow(0.9, Color("#65d9b2"), 0.2)
	animate()


static func _egg_profile() -> PackedVector2Array:
	var out := PackedVector2Array()
	var steps := 12
	for i in steps + 1:
		var t := float(i) / float(steps)
		var y := t * 0.46
		var r := 0.24 * sin(t * PI) * (1.0 + 0.28 * (1.0 - t))
		out.append(Vector2(maxf(r, 0.001), y))
	return out


func _animate(t: float, _delta: float) -> void:
	var s := 1.0 + sin(t * 1.7) * 0.05
	_egg.scale = Vector3(s, 1.0 / (s * 0.6 + 0.4), s)
	_egg.rotation.z = sin(t * 0.9) * 0.05
