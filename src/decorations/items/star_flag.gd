extends DecoItem
## Star Flag — a two-tone pennant rippling on a chrome mast, with a glowing star finial.

const POLE := Color("#c2ccde")
const METAL := Color("#8fa3bf")
const TOP_BAND := Color("#d96143")
const LOW_BAND := Color("#d9af4f")
const POLE_H := 2.25


func _init() -> void:
	footprint = 0.5
	collide_radius = 0.28
	collide_height = 1.8


func _build() -> void:
	var kit := DecoKit.new()
	kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.34, 0.0), Vector2(0.31, 0.1), Vector2(0.16, 0.17), Vector2(0.0, 0.18)]), 20, Transform3D.IDENTITY, METAL)
	kit.torus(Vector3(0.0, 0.1, 0.0), 0.31, 0.04, TOP_BAND, Basis.IDENTITY, 20)
	for i in 4:
		var a := TAU * float(i) / 4.0 + 0.4
		kit.sphere(Vector3(cos(a) * 0.23, 0.16, sin(a) * 0.23), 0.04, POLE)
	kit.cone(Vector3(0.0, 0.14, 0.0), 0.07, 0.05, POLE_H - 0.14, POLE, Basis.IDENTITY, 12)
	kit.sphere(Vector3(0.0, POLE_H, 0.0), 0.075, METAL, Vector3(1.0, 0.8, 1.0), 12)
	add_body(kit.commit())

	var cloth := DecoKit.new()
	cloth.flag_panel(Vector3(0.07, 1.86, 0.0), 1.16, 0.34, TOP_BAND, 12, 2)
	cloth.flag_panel(Vector3(0.07, 1.52, 0.0), 1.16, 0.34, LOW_BAND, 12, 2)
	add_flag(cloth.commit(), "Cloth", 0.13, 2.6)

	var glow := DecoKit.new()
	glow.extrude(DecoKit.star_poly(0.15, 0.065, 5), 0.06, Color("#d9bf61"), Transform3D(Basis.IDENTITY, Vector3(0.0, POLE_H + 0.18, 0.0)))
	# emblem on the cloth, near the pole where the wave barely displaces it
	glow.extrude(DecoKit.star_poly(0.17, 0.075, 5), 0.03, Color("#e6d99c"), Transform3D(Basis.IDENTITY, Vector3(0.36, 1.86, -0.025)))
	glow.extrude(DecoKit.star_poly(0.11, 0.048, 5), 0.03, Color("#e6d99c"), Transform3D(Basis.IDENTITY, Vector3(0.36, 1.52, -0.025)))
	add_glow(glow.commit(), 2.8, "Finial", 1.0, 0.2)
	add_light(Vector3(0.0, POLE_H + 0.18, 0.0), Color("#d9bd79"), 1.0, 4.0)
