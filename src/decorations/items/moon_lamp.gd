extends DecoItem
## Moon Lamp — a fat crescent moon on a lamp post with a warm night glow and a tiny companion star.
##
## SHAPE: the first version was a 0.2 m extruded crescent on a pancake base — flat, and with nothing
## between the ground and the moon. Against the ACNH lantern pole it now has the same countable
## stages: a flared foot with three toe pads, a stepped plinth, a tapering post with an accent collar,
## a lamp housing where the crescent is mounted, and a finial. The crescent itself is half again as
## thick with a darker back plate, so it reads as a solid object from the side, not a sticker.

const POST := Color("#cfcfdf")
const POST_DARK := Color("#8fa3bf")
const METAL := Color("#5f7089")
const ACCENT := Color("#d96143")
const MOON := Color("#d9bf61")
const MOON_BACK := Color("#a8956c")
const STAR := Color("#e6d99c")
const MOON_THICK := 0.3


func _init() -> void:
	footprint = 0.55
	collide_radius = 0.34
	collide_height = 1.1


func _build() -> void:
	var kit := DecoKit.new()
	# --- flared foot + stepped plinth -------------------------------------------------------
	kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.38, 0.0), Vector2(0.36, 0.06),
		Vector2(0.24, 0.1), Vector2(0.23, 0.17), Vector2(0.13, 0.21), Vector2(0.0, 0.22)]),
		18, Transform3D.IDENTITY, METAL)
	kit.torus(Vector3(0.0, 0.06, 0.0), 0.36, 0.04, ACCENT, Basis.IDENTITY, 18, 4)
	for i in 3:
		var a := TAU * float(i) / 3.0
		kit.sphere(Vector3(cos(a) * 0.3, 0.03, sin(a) * 0.3), 0.055, POST_DARK, Vector3(1.0, 0.6, 1.0), 8)
	# --- post with a mid collar ---------------------------------------------------------------
	kit.cone(Vector3(0.0, 0.2, 0.0), 0.082, 0.058, 1.28, POST, Basis.IDENTITY, 12)
	kit.torus(Vector3(0.0, 0.56, 0.0), 0.086, 0.032, ACCENT, Basis.IDENTITY, 14, 4)
	kit.torus(Vector3(0.0, 1.2, 0.0), 0.07, 0.026, POST_DARK, Basis.IDENTITY, 14, 4)
	# --- lamp housing the crescent is bolted to ------------------------------------------------
	kit.rbox(Vector3(0.0, 1.52, 0.0), Vector3(0.17, 0.2, 0.17), 0.05, POST_DARK, Basis.IDENTITY, 0)
	kit.rbox(Vector3(0.0, 1.66, 0.0), Vector3(0.22, 0.05, 0.22), 0.02, ACCENT, Basis.IDENTITY, 0)
	# --- finial --------------------------------------------------------------------------------
	kit.sphere(Vector3(0.0, 2.16, 0.0), 0.05, POST_DARK, Vector3(1.0, 0.9, 1.0), 8)
	add_body(kit.commit())

	# Crescent head, tilted so the horns read from the gameplay camera. A darker plate sits just
	# behind it so the moon has a visible back and a crisp edge instead of a flat cutout.
	var xf := Transform3D(Basis(Vector3.UP, deg_to_rad(-18.0)) * Basis(Vector3.FORWARD, deg_to_rad(-24.0)), Vector3(0.0, 1.72, 0.0))
	var back := DecoKit.new()
	back.extrude(DecoKit.crescent_poly(0.44, 0.35, 0.26), 0.1, MOON_BACK, xf)
	add_body(back.commit(), "MoonBack")

	var glow := DecoKit.new()
	glow.extrude(DecoKit.crescent_poly(0.42, 0.34, 0.26), MOON_THICK, MOON, xf)
	glow.extrude(DecoKit.star_poly(0.11, 0.05, 5), 0.07, STAR, Transform3D(Basis(Vector3.UP, deg_to_rad(-18.0)), Vector3(0.34, 2.06, 0.08)))
	add_glow(glow.commit(), 2.6, "Glow", 0.9, 0.12)

	add_light(Vector3(0.0, 1.74, 0.0), Color("#d9bd79"), 2.4, 6.5)
	add_ground_glow(1.5, Color("#d9b569"), 0.26)
