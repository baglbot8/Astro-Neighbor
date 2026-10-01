extends DecoItem
## Stargazer Hot Tub (cozy home set, the showpiece) - a round wooden barrel tub bound with two metal
## hoops, full of warm teal water that glows after dark and steams all day. Two steps up the front, a
## towel over the rim, a lantern on a post behind it, and a rubber duck doing slow laps. Steps face -Z.

const WOOD := Color("#b89a74")
const WOOD_DARK := Color("#93775a")
const WOOD_LIGHT := Color("#cdb68c")
const HOOP := Color("#8fa3bf")
const WATER := Color("#7fc4c9")
const TOWEL := Color("#cf8f86")
const TOWEL_STRIPE := Color("#e3d7bc")
const DUCK := Color("#e3c877")
const BEAK := Color("#d07a55")
const EYE := Color("#3a3550")
const LANTERN := Color("#6f6a80")
const LIGHT := Color("#e3c877")
const R := 0.8
const H := 0.64
const WATER_Y := 0.54

var _lap: Node3D
var _duck: Node3D


func _init() -> void:
	footprint = 1.3
	collide_radius = 0.85
	collide_height = 0.7


func _build() -> void:
	var kit := DecoKit.new()
	# --- the barrel: a slight belly, a thick wall, the inside floor just under the water -----------------
	kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(R - 0.07, 0.0), Vector2(R, H * 0.45), Vector2(R - 0.03, H), Vector2(R - 0.12, H),
		Vector2(R - 0.12, WATER_Y - 0.08), Vector2(0.0, WATER_Y - 0.08)]), 28, Transform3D.IDENTITY, WOOD)
	kit.torus(Vector3(0.0, H, 0.0), R - 0.075, 0.055, WOOD_LIGHT, Basis.IDENTITY, 28, 4)
	# stave lines: fourteen thin dark strips down the outside
	for i in 14:
		var a := TAU * float(i) / 14.0 + 0.1
		var o := Vector3(cos(a), 0.0, sin(a))
		kit.rbox(o * (R - 0.02) + Vector3(0.0, H * 0.5, 0.0), Vector3(0.05, H - 0.1, 0.022), 0.008, WOOD_DARK,
			Basis(Vector3.UP, PI * 0.5 - a), 0)
	add_body(kit.commit())

	var metal := DecoKit.new()
	metal.torus(Vector3(0.0, 0.14, 0.0), R - 0.035, 0.026, HOOP, Basis.IDENTITY, 28, 3)
	metal.torus(Vector3(0.0, 0.47, 0.0), R, 0.026, HOOP, Basis.IDENTITY, 28, 3)
	add_metal(metal.commit(), "Hoops")

	var extra := DecoKit.new()
	# --- two steps up the front ----------------------------------------------------------------------
	# one extruded stair profile (x = distance out from the tub's centre along -Z, y = up), 0.56 m wide:
	# crisp flat treads for 20 triangles, where two rounded boxes cost 160 and shaded as facets
	extra.extrude(PackedVector2Array([Vector2(0.76, 0.0), Vector2(1.27, 0.0), Vector2(1.27, 0.2), Vector2(1.04, 0.2),
		Vector2(1.04, 0.4), Vector2(0.76, 0.4)]), 0.56, WOOD_LIGHT, Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3.ZERO))
	for sx in [-1.0, 1.0]:
		extra.extrude(PackedVector2Array([Vector2(0.76, 0.0), Vector2(1.3, 0.0), Vector2(1.3, 0.16), Vector2(0.76, 0.36)]),
			0.04, WOOD_DARK, Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(0.3 * sx, 0.0, 0.0)))
	# --- a towel over the rim on the right: over the top, down the outside, striped, fringed ----------------
	var ta := -0.5
	var tb := Basis(Vector3.UP, -ta)
	var tdir := Vector3(cos(ta), 0.0, sin(ta))
	extra.rbox(tdir * (R - 0.07) + Vector3(0.0, H + 0.05, 0.0), Vector3(0.3, 0.05, 0.34), 0.024, TOWEL, tb, 0)
	extra.rbox(tdir * (R + 0.06) + Vector3(0.0, H - 0.14, 0.0), Vector3(0.05, 0.42, 0.34), 0.022, TOWEL, tb, 0)
	for k in 2:
		extra.rbox(tdir * (R + 0.09) + Vector3(0.0, H - 0.2 - 0.08 * float(k), 0.0), Vector3(0.012, 0.035, 0.345), 0.005, TOWEL_STRIPE, tb, 0)
	# --- the lantern post behind the tub, with an arm reaching over the water ------------------------------
	var pa := 2.2
	var po := Vector3(cos(pa), 0.0, sin(pa))
	var foot := po * (R + 0.16)
	extra.cone(foot, 0.1, 0.07, 0.08, WOOD_DARK, Basis.IDENTITY, 10)
	extra.tube(foot + Vector3(0.0, 0.05, 0.0), foot + Vector3(0.0, 1.5, 0.0), 0.045, WOOD, 8)
	var hang := foot + Vector3(0.0, 1.5, 0.0) - po * 0.3
	JungleMeshes.tube(extra, PackedVector3Array([foot + Vector3(0.0, 1.38, 0.0), foot + Vector3(0.0, 1.56, 0.0) - po * 0.1,
		hang + Vector3(0.0, 0.03, 0.0), hang - po * 0.03 - Vector3(0.0, 0.03, 0.0)]),
		PackedFloat32Array([0.03, 0.026, 0.022, 0.018]), PackedColorArray([WOOD_DARK]), 6, true)
	extra.sphere(foot + Vector3(0.0, 1.53, 0.0), 0.065, HOOP, Vector3.ONE, 8)
	var lp := hang - po * 0.03 - Vector3(0.0, 0.2, 0.0)
	extra.bar(lp + Vector3(0.0, 0.17, 0.0), lp + Vector3(0.0, 0.1, 0.0), 0.008, LANTERN, 6)
	extra.cone(lp + Vector3(0.0, 0.07, 0.0), 0.095, 0.025, 0.06, LANTERN, Basis.IDENTITY, 8)
	extra.lathe(PackedVector2Array([Vector2(0.0, -0.11), Vector2(0.075, -0.11), Vector2(0.075, -0.085), Vector2(0.0, -0.085)]),
		8, Transform3D(Basis.IDENTITY, lp), LANTERN)
	for k in 4:
		var ka := TAU * float(k) / 4.0
		var kp := lp + Vector3(cos(ka) * 0.07, 0.0, sin(ka) * 0.07)
		JungleMeshes.tube(extra, PackedVector3Array([kp - Vector3(0.0, 0.09, 0.0), kp + Vector3(0.0, 0.075, 0.0)]),
			PackedFloat32Array([0.007]), PackedColorArray([LANTERN]), 3, false)
	add_body(extra.commit(), "Extras")

	# --- water: a lit sheet under a glassy surface ------------------------------------------------------
	var wg := DecoKit.new()
	wg.disc(Vector3(0.0, WATER_Y - 0.03, 0.0), R - 0.12, WATER, Basis.IDENTITY, 28)
	add_glow(wg.commit(), 1.2, "WaterGlow", 0.5, 0.15)
	var glass := DecoKit.new()
	glass.disc(Vector3(0.0, WATER_Y, 0.0), R - 0.12, WATER, Basis.IDENTITY, 28)
	add_glass(glass.commit(), WATER, 0.45, "Water")

	# --- the duck, doing laps ----------------------------------------------------------------------------
	_lap = pivot("Lap", Vector3(0.0, WATER_Y, 0.0))
	_duck = pivot("Duck", Vector3(0.36, 0.0, 0.0), _lap)
	var dk := DecoKit.new()
	dk.sphere(Vector3(0.0, 0.045, 0.0), 0.1, DUCK, Vector3(0.9, 0.7, 1.25), 10)
	dk.sphere(Vector3(0.0, 0.085, 0.12), 0.04, DUCK, Vector3(0.8, 0.6, 1.2), 6, Basis(Vector3.RIGHT, -0.6))
	dk.sphere(Vector3(0.0, 0.15, -0.07), 0.068, DUCK, Vector3.ONE, 10)
	dk.sphere(Vector3(0.0, 0.14, -0.14), 0.034, BEAK, Vector3(1.1, 0.5, 1.2), 6)
	for sx in [-1.0, 1.0]:
		dk.rbox(Vector3(0.04 * sx, 0.17, -0.118), Vector3(0.024, 0.024, 0.024), 0.012, EYE, Basis.IDENTITY, 0)
	add_body(dk.commit(), "DuckBody", _duck)

	var glow := DecoKit.new()
	glow.sphere(lp + Vector3(0.0, -0.01, 0.0), 0.06, LIGHT, Vector3(1.0, 1.2, 1.0), 8)
	add_glow(glow.commit(), 2.6, "Lantern", 0.8, 0.2)
	add_light(lp, Color("#e0c487"), 2.0, 6.0)
	# the water's light hangs 0.9 m up, not at the surface: the duck and the rim are then far enough
	# from it for toon_soft's light() to stay positive (it goes navy-black inside ~0.56 m of an omni)
	add_light(Vector3(0.0, WATER_Y + 0.9, 0.0), Color("#8fd0d4"), 1.4, 4.5)
	add_ground_glow(2.0, Color("#8fd0d4"), 0.2)
	add_particles(10, 2.4, Vector3(0.0, WATER_Y + 0.1, 0.0), Color(0.85, 0.92, 0.92, 0.4), 0.2, 0.32, 30.0, 0.12, 0.45)
	animate()


func _animate(t: float, _delta: float) -> void:
	_lap.rotation.y = -t * 0.35
	_duck.position.y = sin(t * 2.3) * 0.012
	_duck.rotation.z = sin(t * 1.7) * 0.08
