extends DecoItem
## Glowshroom Daybed (Glowshroom Hollow BONUS, from Zorp) - a soft lilac daybed on a spotted mushroom
## plinth, with a cream pillow and a blue blanket, under a giant spotted cap on a curving stem. Blue gills
## glow under the cap and three little glowing spores dangle from its rim on threads. The whole canopy
## sways, very slowly. Zorp says it is the best nap in the system.

const CAP := Color("#9a82cc")
const CAP_DARK := Color("#7a66ad")
const STEM := Color("#dcd3e3")
const STEM_DARK := Color("#bdb2cc")
const SPOT := Color("#ece4f2")
const GILL := Color("#7fc8f0")
const MATTRESS := Color("#b3a0d6")
const BLANKET := Color("#6f86c0")
const PILLOW := Color("#e2d9cf")
const ROOT := Vector3(-0.93, 0.0, 0.34)
const CAP_AT := Vector3(-0.22, 1.86, 0.06)
const CAP_R := 0.86
const CAP_H := 0.4

var _canopy: Node3D


func _init() -> void:
	footprint = 1.1
	collide_radius = 0.82
	collide_height = 0.55


func _build() -> void:
	var kit := DecoKit.new()
	# --- plinth, mattress, pillow, blanket ---------------------------------------------------------------
	kit.rbox(Vector3(0.0, 0.11, 0.0), Vector3(1.72, 0.22, 0.94), 0.09, CAP_DARK)
	for k in 7:
		var x := lerpf(-0.7, 0.7, float(k) / 6.0)
		var s := 0.03 + 0.012 * float(k % 3)
		var yy := 0.1 + 0.04 * float((k * 2) % 3) * 0.5
		kit.rbox(Vector3(x, yy, -0.472), Vector3(s * 2.0, s * 2.0, s * 0.5), s, SPOT, Basis.IDENTITY, 0)
	kit.rbox(Vector3(0.0, 0.29, 0.0), Vector3(1.62, 0.17, 0.84), 0.075, MATTRESS)
	kit.rbox(Vector3(-0.6, 0.41, 0.0), Vector3(0.34, 0.12, 0.58), 0.06, PILLOW, Basis(Vector3.FORWARD, 0.12))
	kit.rbox(Vector3(0.24, 0.385, 0.0), Vector3(1.08, 0.045, 0.88), 0.022, BLANKET)
	kit.rbox(Vector3(-0.3, 0.405, 0.0), Vector3(0.1, 0.05, 0.89), 0.025, BLANKET.lightened(0.12))
	for k2 in 4:
		kit.rbox(Vector3(0.0 + 0.24 * float(k2), 0.41, -0.2 + 0.13 * float(k2 % 3)), Vector3(0.06, 0.012, 0.06), 0.03, GILL.lightened(0.2),
			Basis.IDENTITY, 0)
	# --- the stem foot stays put; everything above sways --------------------------------------------------
	kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.2, 0.0), Vector2(0.18, 0.04), Vector2(0.12, 0.1), Vector2(0.1, 0.2),
		Vector2(0.0, 0.22)]), 14, Transform3D(Basis.IDENTITY, ROOT), STEM)
	add_body(kit.commit())

	_canopy = pivot("Canopy", ROOT + Vector3(0.0, 0.12, 0.0))
	var ck := DecoKit.new()
	var glow := DecoKit.new()
	var loc := func(p: Vector3) -> Vector3: return p - (ROOT + Vector3(0.0, 0.12, 0.0))
	JungleMeshes.tube(ck, PackedVector3Array([loc.call(ROOT + Vector3(0.0, 0.05, 0.0)), loc.call(Vector3(-0.95, 0.7, 0.36)),
		loc.call(Vector3(-0.86, 1.25, 0.3)), loc.call(Vector3(-0.62, 1.66, 0.18)), loc.call(CAP_AT + Vector3(-0.08, -0.02, 0.0))]),
		PackedFloat32Array([0.1, 0.085, 0.078, 0.072, 0.07]), PackedColorArray([STEM]), 10, false)
	var c := loc.call(CAP_AT) as Vector3
	var prof := PackedVector2Array([Vector2(CAP_R * 0.95, -CAP_H * 0.1)])
	for i in 8:
		var a := PI * 0.5 * float(i) / 7.0
		prof.append(Vector2(cos(a) * CAP_R, sin(a) * CAP_H))
	ck.lathe(prof, 30, Transform3D(Basis.IDENTITY, c), CAP)
	glow.lathe(PackedVector2Array([Vector2(0.12, 0.0), Vector2(CAP_R * 0.55, -CAP_H * 0.06), Vector2(CAP_R * 0.93, -CAP_H * 0.1)]), 26,
		Transform3D(Basis.IDENTITY, c), GILL)
	for k3 in 10:
		var th := lerpf(0.25, 1.2, fmod(float(k3) * 0.618 + 0.15, 1.0))
		var ph := 0.5 + float(k3) * 2.39996
		var n := Vector3(sin(th) * cos(ph) / CAP_R, cos(th) / CAP_H, sin(th) * sin(ph) / CAP_R).normalized()
		var p := c + Vector3(CAP_R * sin(th) * cos(ph), CAP_H * cos(th), CAP_R * sin(th) * sin(ph))
		var s2 := 0.06 + 0.03 * fmod(float(k3) * 0.37, 1.0)
		ck.rbox(p, Vector3(s2 * 2.0, s2 * 0.5, s2 * 2.0), s2, SPOT, DecoKit.axis_basis(n), 0)
	# three spores dangling from the rim on threads
	for d in [[-0.5, 0.38], [0.35, 0.3], [1.9, 0.44]]:
		var a2: float = d[0]
		var drop: float = d[1]
		var top := c + Vector3(cos(a2) * CAP_R * 0.82, -CAP_H * 0.08, sin(a2) * CAP_R * 0.82 * -1.0)
		ck.bar(top + Vector3(0.0, -drop, 0.0), top, 0.006, STEM_DARK, 6)
		glow.sphere(top + Vector3(0.0, -drop - 0.03, 0.0), 0.04, GILL.lightened(0.15), Vector3.ONE, 8)
	add_body(ck.commit(), "Cap", _canopy)
	add_glow(glow.commit(), 2.3, "Gills", 0.5, 0.25, 0.0, _canopy)
	# No OmniLight on purpose: at night a lamp light turns nearby crochet (toon) surfaces black in stitch-row
	# stripes - measured 2026-10-21 on the existing Reading Lamp and Cosmic Mushrooms too, both renderers, and
	# gone the moment the light is removed. The emissive parts and the ground pool carry the night glow.
	add_ground_glow(1.8, Color("#7fc8f0"), 0.22)
	animate()


func _animate(time: float, _delta: float) -> void:
	_canopy.rotation = Vector3(sin(time * 0.37) * 0.012, 0.0, sin(time * 0.29 + 1.0) * 0.018)
