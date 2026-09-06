extends DecoItem
## Cosmic Mushroom Cluster — four fat mushrooms with glowing gills and freckles of starlight.

const STEM := Color("#cfcfdf")
const STEM_DARK := Color("#b1b7cf")
const CAP_A := Color("#845bd9")
const CAP_B := Color("#d95d7c")
const MOSS := Color("#5cc44a")


func _init() -> void:
	footprint = 0.7
	collide_radius = 0.46
	collide_height = 0.85


func _build() -> void:
	var kit := DecoKit.new()
	var glow := DecoKit.new()
	kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.5, 0.0), Vector2(0.44, 0.06), Vector2(0.0, 0.08)]), 16, Transform3D.IDENTITY, MOSS)
	var specs := [
		[Vector3(0.0, 0.05, 0.0), 0.6, 0.34, CAP_A],
		[Vector3(0.3, 0.05, 0.16), 0.4, 0.24, CAP_B],
		[Vector3(-0.26, 0.05, 0.2), 0.32, 0.2, CAP_A],
		[Vector3(-0.06, 0.05, -0.3), 0.24, 0.17, CAP_B],
	]
	for s in specs:
		var base: Vector3 = s[0]
		var h: float = s[1]
		var cr: float = s[2]
		var col: Color = s[3]
		kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(cr * 0.42, 0.0), Vector2(cr * 0.3, h * 0.5), Vector2(cr * 0.33, h)]), 11, Transform3D(Basis.IDENTITY, base), STEM)
		kit.lathe(PackedVector2Array([Vector2(0.0, h + cr * 0.62), Vector2(cr * 0.62, h + cr * 0.44), Vector2(cr, h + cr * 0.06), Vector2(cr * 0.96, h - cr * 0.04)]), 15, Transform3D(Basis.IDENTITY, base), col)
		glow.lathe(PackedVector2Array([Vector2(cr * 0.94, h - cr * 0.04), Vector2(cr * 0.5, h - cr * 0.02), Vector2(cr * 0.3, h)]), 13, Transform3D(Basis.IDENTITY, base), Color("#65d9b2"))
		for k in 3:
			var a := TAU * float(k) / 4.0 + cr
			var rr := cr * 0.55
			glow.sphere(base + Vector3(cos(a) * rr, h + cr * 0.4, sin(a) * rr), cr * 0.11, Color("#e6d99c"), Vector3(1.0, 0.5, 1.0), 7)
	add_body(kit.commit())
	add_glow(glow.commit(), 2.2, "Glow", 0.8, 0.3)
	add_ground_glow(1.0, Color("#6fb6d9"), 0.2)
	add_light(Vector3(0.0, 0.6, 0.0), Color("#845bd9"), 1.0, 4.0)
