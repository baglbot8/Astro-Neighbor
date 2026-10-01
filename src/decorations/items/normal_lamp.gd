extends DecoItem
## Bright Idea Lamp (Norm's Totally Normal Collection, docs/DAILY_STAMPS_SPEC.md 3) — a floor lamp
## with a pleated shade, put together by Norm. He screwed the bulb in on the OUTSIDE, on top of the
## shade, where it is brighter. The plug lies in the grass and reaches nothing. It lights up anyway.

const SHADE := Color("#c9a39a")
const SHADE_DARK := Color("#b88e86")
const TRIM := Color("#e0d4b4")
const BRASS := Color("#cdbb8c")
const BASE := Color("#8a8fa3")
const CORD := Color("#4a4655")
const PLUG := Color("#e0d4b4")
const BULB := Color("#e6c98a")
const SHADE_Y0 := 1.12
const SHADE_Y1 := 1.52
const PLEATS := 10


func _init() -> void:
	footprint = 0.55
	collide_radius = 0.38
	collide_height = 1.9


func _build() -> void:
	var kit := DecoKit.new()
	# --- weighted base and pole ---------------------------------------------------------------
	kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.3, 0.0), Vector2(0.31, 0.04), Vector2(0.27, 0.08),
		Vector2(0.08, 0.13), Vector2(0.04, 0.2), Vector2(0.0, 0.2)]), 18, Transform3D.IDENTITY, BASE)
	kit.cone(Vector3(0.0, 0.18, 0.0), 0.034, 0.034, SHADE_Y1 - 0.18, BRASS, Basis.IDENTITY, 8)
	kit.torus(Vector3(0.0, 0.66, 0.0), 0.04, 0.02, TRIM, Basis.IDENTITY, 10, 4)
	# --- shade, the usual way up, with pleats and a pale trim top and bottom ----------------------
	kit.lathe(PackedVector2Array([Vector2(0.4, SHADE_Y0), Vector2(0.22, SHADE_Y1), Vector2(0.0, SHADE_Y1)]), 20, Transform3D.IDENTITY, SHADE, false)
	kit.disc(Vector3(0.0, SHADE_Y0 + 0.03, 0.0), 0.37, SHADE_DARK, Basis(Vector3.RIGHT, PI), 16)
	for i in PLEATS:
		var a := TAU * float(i) / float(PLEATS)
		var d := Vector3(cos(a), 0.0, sin(a))
		kit.bar(d * 0.405 + Vector3(0.0, SHADE_Y0 + 0.02, 0.0), d * 0.225 + Vector3(0.0, SHADE_Y1 - 0.01, 0.0), 0.016, SHADE_DARK, 6)
	kit.torus(Vector3(0.0, SHADE_Y0, 0.0), 0.4, 0.028, TRIM, Basis.IDENTITY, 18, 4)
	kit.torus(Vector3(0.0, SHADE_Y1, 0.0), 0.22, 0.025, TRIM, Basis.IDENTITY, 14, 4)
	# --- the bulb's screw socket, on the outside ------------------------------------------------
	kit.cone(Vector3(0.0, SHADE_Y1, 0.0), 0.085, 0.075, 0.12, BRASS, Basis.IDENTITY, 10)
	for y in [0.03, 0.07]:
		kit.torus(Vector3(0.0, SHADE_Y1 + y, 0.0), 0.082, 0.012, BASE, Basis.IDENTITY, 10, 4)
	# --- the cord: out of the base, across the grass, to a plug that reaches nothing --------------
	var pts := [Vector3(0.26, 0.05, -0.1), Vector3(0.42, 0.02, -0.2), Vector3(0.5, 0.02, -0.36), Vector3(0.4, 0.02, -0.46)]
	for i in pts.size() - 1:
		kit.tube(pts[i], pts[i + 1], 0.018, CORD, 6, 1)
	var turn := Basis(Vector3.UP, deg_to_rad(40.0))
	kit.rbox(pts[3] + turn * Vector3(-0.05, 0.02, 0.0), Vector3(0.13, 0.07, 0.1), 0.03, PLUG, turn, 0)
	for s in [-1.0, 1.0]:
		kit.rbox(pts[3] + turn * Vector3(-0.15, 0.02, 0.028 * s), Vector3(0.08, 0.03, 0.018), 0.006, BRASS, turn, 0)
	add_body(kit.commit())

	# the bulb: a fat pear shape, lit, sitting on top like a cherry
	var glow := DecoKit.new()
	var y0 := SHADE_Y1 + 0.1
	glow.lathe(PackedVector2Array([
		Vector2(0.0, y0), Vector2(0.07, y0), Vector2(0.09, y0 + 0.06), Vector2(0.16, y0 + 0.15),
		Vector2(0.185, y0 + 0.24), Vector2(0.16, y0 + 0.33), Vector2(0.09, y0 + 0.4), Vector2(0.0, y0 + 0.42)]),
		14, Transform3D.IDENTITY, BULB)
	add_glow(glow.commit(), 2.6, "Bulb")
	# The light sits ABOVE the bulb, 0.78 m from the shade's top ring: inside about 0.6 m a lamp
	# light blackens the toon surfaces facing it (see normal_tv.gd; at 0.41 m the ring went black).
	add_light(Vector3(0.0, SHADE_Y1 + 0.75, 0.0), Color("#e6c48a"), 2.2, 6.0)
	add_ground_glow(1.3, Color("#e6c48a"), 0.22)
