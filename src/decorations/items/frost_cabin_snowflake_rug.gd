extends DecoItem
## Snowflake Rug (Frost Cabin set) - a big round navy rug with one six-armed snowflake knitted in snow-white
## across its middle, edged with the set's cranberry knit band laid flat, and a fringe of little ice-blue
## drips round the rim (the set's icicles, lying down). A knitted snow pom sits in the very centre.
## Non-blocking: you walk right over it.

## FLAT ON PURPOSE (measured 2026-10-22): a 1.9 m flat disc on the 12 m home planet stands up to 6.3-6.7 cm proud
## at its rim on real placements (the shipped Nebula Rug: 6.9-7.5 cm, Patchwork Rug 4.8-7.5 cm). Laying it on the
## sphere (every vertex dropped by r^2 / 2R) cut that to +-2.5 cm through DecorationManager.place(), but on the
## gallery's seating a terrain bump then swallowed a bite of the near rim, which reads as broken; a rug hovering
## a few cm reads as a rug on lumpy ground. So it stays flat, like the shipped rugs.

const FC := preload("res://src/decorations/sets/set_frost_cabin.gd")
const R := 0.95
const TOP := 0.03


func _init() -> void:
	footprint = 1.0
	blocking = false
	collide_radius = 0.95
	collide_height = 0.06


func _build() -> void:
	var kit := DecoKit.new()
	# --- the rug: navy field with a soft rolled edge -------------------------------------------------
	kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(R, 0.0), Vector2(R + 0.012, TOP * 0.6), Vector2(R - 0.01, TOP),
		Vector2(0.0, TOP)]), 30, Transform3D.IDENTITY, FC.NAVY)
	# --- the border: the set's knit band laid flat (cranberry ribs, white stripe) ----------------------
	_ring(kit, R - 0.05, 0.05, FC.KNIT, 0.012)
	_ring(kit, R - 0.13, 0.03, FC.SNOW, 0.008)
	_ring(kit, R - 0.19, 0.035, FC.KNIT, 0.012)
	# --- the snowflake: six arms, each with two pairs of side branches and a diamond tip -------------
	var y := TOP + 0.006
	for i in 6:
		var a := TAU * float(i) / 6.0
		var o := Vector3(cos(a), 0.0, sin(a))
		var side := Vector3(-o.z, 0.0, o.x)
		_flat_bar(kit, o * 0.06, o * 0.6, 0.035, y, FC.SNOW)
		for b in [0.26, 0.42]:
			var root: Vector3 = o * float(b)
			var ln: float = 0.17 if b < 0.3 else 0.12
			for s in [-1.0, 1.0]:
				var tip: Vector3 = root + (o * 0.5 + side * float(s) * 0.866) * ln
				_flat_bar(kit, root, tip, 0.024, y + 0.002, FC.SNOW)
		kit.extrude(_diamond(0.06), 0.012, FC.ICE, Transform3D(Basis(Vector3.RIGHT, -PI * 0.5) * Basis(Vector3.BACK, -a - PI * 0.5),
			o * 0.64 + Vector3(0.0, y, 0.0)))
	kit.extrude(_hexagon(0.1), 0.014, FC.ICE, Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), Vector3(0.0, y, 0.0)))
	FC.snow_lump(kit, Vector3(0.0, y + 0.006, 0.0), 0.07, Basis.IDENTITY, 1)
	# --- the ice-drip fringe, pointing out from the rim like tassels -----------------------------------
	for i in 20:
		var a2 := TAU * (float(i) + 0.5) / 20.0
		var k := FC.icicle_hand(i)
		var ln2 := lerpf(0.06, 0.12, k)
		var tri := PackedVector2Array([Vector2(-0.032, 0.0), Vector2(0.032, 0.0), Vector2(0.0, -ln2)])
		kit.extrude(tri, 0.012, FC.ICE, Transform3D(
			Basis(Vector3.UP, PI * 0.5 - a2) * Basis(Vector3.RIGHT, -PI * 0.5),
			Vector3(cos(a2) * (R - 0.005), 0.01, sin(a2) * (R - 0.005))))
	add_body(kit.commit())


## A flat rounded ring on the rug face, centre radius `rr`, half-width `hw`, standing `h` proud.
func _ring(kit: DecoKit, rr: float, hw: float, col: Color, h: float) -> void:
	kit.lathe(PackedVector2Array([
		Vector2(rr - hw, TOP - 0.002), Vector2(rr - hw * 0.8, TOP + h), Vector2(rr + hw * 0.8, TOP + h),
		Vector2(rr + hw, TOP - 0.002)]), 30, Transform3D.IDENTITY, col)


## A flat stitched bar lying on the rug from `a` to `b` (XZ), `w` wide.
func _flat_bar(kit: DecoKit, a: Vector3, b: Vector3, w: float, y: float, col: Color) -> void:
	var mid := (a + b) * 0.5
	var d := b - a
	var yaw := atan2(d.x, d.z)
	kit.rbox(Vector3(mid.x, y + 0.006, mid.z), Vector3(w, 0.014, d.length() + w * 0.5), 0.006, col, Basis(Vector3.UP, yaw), 0)


func _diamond(r: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(0.0, r), Vector2(r * 0.6, 0.0), Vector2(0.0, -r), Vector2(-r * 0.6, 0.0)])


func _hexagon(r: float) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in 6:
		var a := TAU * float(i) / 6.0
		p.append(Vector2(cos(a), sin(a)) * r)
	return p
