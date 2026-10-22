extends DecoItem
## Aurora Lamp (Frost Cabin set bonus) - a slow ribbon of light Vela caught on a still night. A round snow
## mound on a navy drum (with the set's cranberry knit band and a fringe of icicles round its rim) holds up
## a slim navy wand; at the top, inside an open ice hoop, one long ribbon of aurora - green fading up into
## violet - spirals round the wand, sways and slowly turns. A little snow star crowns the wand. Lit softly by day,
## the curtains glow and throw a green-violet light at night.

const FC := preload("res://src/decorations/sets/set_frost_cabin.gd")
const AUR_GREEN := Color("#62d6ae")
const AUR_VIOLET := Color("#9b80e0")
const WAND_TOP := 1.62
const RIB_Y := 1.08
const TURN_SPEED := 0.22
const SWAY := 0.06

var _curtains: Array[Node3D] = []


func _init() -> void:
	footprint = 0.55
	collide_radius = 0.3
	collide_height = 1.75


func _build() -> void:
	var kit := DecoKit.new()
	# --- the drum base, its knit band, icicles round the rim and a snow mound on top ------------------------
	kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.28, 0.0), Vector2(0.3, 0.03), Vector2(0.28, 0.2), Vector2(0.29, 0.22),
		Vector2(0.0, 0.22)]), 20, Transform3D.IDENTITY, FC.NAVY)
	FC.knit_band(kit, Vector3(0.0, 0.05, 0.0), 0.285, 0.11, 20)
	FC.icicle_fringe(kit, Vector3(0.0, 0.215, 0.0), 0.3, 10, 0.03, 0.08, 0.018, FC.ICE)
	kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.215), Vector2(0.285, 0.225), Vector2(0.22, 0.26), Vector2(0.12, 0.31), Vector2(0.0, 0.33)]),
		20, Transform3D.IDENTITY, FC.SNOW)
	# --- the wand, an ice hoop on three fine arms, and a snow star on top ---------------------------------
	kit.cone(Vector3(0.0, 0.3, 0.0), 0.03, 0.02, WAND_TOP - 0.3, FC.NAVY_DARK, Basis.IDENTITY, 8)
	kit.torus(Vector3(0.0, 0.34, 0.0), 0.045, 0.02, FC.NAVY, Basis.IDENTITY, 12, 3)
	kit.torus(Vector3(0.0, RIB_Y - 0.06, 0.0), 0.03, 0.016, FC.NAVY, Basis.IDENTITY, 10, 3)
	for i in 3:
		var a := TAU * float(i) / 3.0
		kit.tube(Vector3(0.0, RIB_Y - 0.06, 0.0), Vector3(cos(a) * 0.33, RIB_Y, sin(a) * 0.33), 0.009, FC.NAVY_DARK, 6, 1)
	kit.torus(Vector3(0.0, RIB_Y, 0.0), 0.34, 0.018, FC.ICE, Basis.IDENTITY, 24, 4)
	FC.icicle_fringe(kit, Vector3(0.0, RIB_Y - 0.01, 0.0), 0.34, 7, 0.035, 0.085, 0.016, FC.ICE)
	kit.extrude(DecoKit.star_poly(0.085, 0.04, 6), 0.03, FC.SNOW, Transform3D(Basis.IDENTITY, Vector3(0.0, WAND_TOP + 0.06, 0.0)))
	add_body(kit.commit())

	# --- the aurora: one long ribbon spiralling up round the wand, green at its lower edge, violet at its
	# upper edge, its radius and width breathing along its length; it turns slowly on its own pivot ------
	var pv := pivot("Aurora", Vector3(0.0, RIB_Y - 0.1, 0.0))
	var g := DecoKit.new()
	var path := PackedVector3Array()
	var widths := PackedFloat32Array()
	var n := 30
	for i in n:
		var f := float(i) / float(n - 1)
		var a2 := f * TAU * 1.4
		var rr := 0.23 + sin(f * TAU * 2.0) * 0.06
		path.append(Vector3(cos(a2) * rr, f * 0.4, sin(a2) * rr))
		widths.append(0.05 + 0.15 * sin(f * PI))
	FC.ribbon(g, path, widths, Vector3.UP, AUR_GREEN, AUR_VIOLET)
	add_glow(g.commit(), 2.4, "Aurora", 0.5, 0.3, 0.0, pv)
	_curtains.append(pv)
	add_light(Vector3(0.0, RIB_Y + 0.2, 0.0), Color("#8fd8c4"), 1.8, 5.5)
	add_ground_glow(1.4, Color("#8fcfc0"), 0.22)
	animate()


func _animate(time: float, _delta: float) -> void:
	for c in _curtains.size():
		var dir := 1.0 if c == 0 else -1.3
		var pv := _curtains[c]
		pv.rotation = Vector3(sin(time * 0.7 + float(c) * 2.0) * SWAY, time * TURN_SPEED * dir,
			cos(time * 0.55 + float(c)) * SWAY)
