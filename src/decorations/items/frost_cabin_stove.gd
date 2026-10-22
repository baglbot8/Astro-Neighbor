extends DecoItem
## Pot-Belly Stove (Frost Cabin set) - a round little navy cast-iron stove on three bowed legs, its belly-front
## door a round window of warm ember glow behind a grille, a kettle on the hot plate, and a stove pipe rising
## to a little pointed chimney hat. The pipe wears the set's cranberry knit band (a pipe cosy), the chimney
## hat has snow on top and icicles round its brim - out of reach of the warmth - and soft wool puffs of
## smoke drift up from it. Glows ember-orange at night and lights the snow around it.

const FC := preload("res://src/decorations/sets/set_frost_cabin.gd")
const BELLY_Y := 0.2
const PLATE_Y := 0.82
const PIPE_TOP := 1.5
const PUFFS := 3
const PUFF_RISE := 0.5
const PUFF_PERIOD := 4.5

var _puffs: Array[Node3D] = []


func _init() -> void:
	footprint = 0.6
	collide_radius = 0.36
	collide_height = 1.6


func _build() -> void:
	var kit := DecoKit.new()
	# --- three bowed legs and a foot plate ------------------------------------------------------------
	for i in 3:
		var a := TAU * float(i) / 3.0 + PI / 6.0
		var o := Vector3(cos(a), 0.0, sin(a))
		JungleMeshes.tube(kit, PackedVector3Array([o * 0.18 + Vector3(0.0, BELLY_Y + 0.04, 0.0),
			o * 0.27 + Vector3(0.0, 0.1, 0.0), o * 0.29 + Vector3(0.0, 0.025, 0.0)]),
			PackedFloat32Array([0.035, 0.03, 0.028]), PackedColorArray([FC.NAVY_DARK]), 7, true)
	# --- the pot belly: a fat round body between a skirt and a shoulder -----------------------------------
	kit.lathe(PackedVector2Array([
		Vector2(0.0, BELLY_Y), Vector2(0.21, BELLY_Y), Vector2(0.2, BELLY_Y + 0.05),
		Vector2(0.28, BELLY_Y + 0.16), Vector2(0.31, BELLY_Y + 0.3), Vector2(0.29, BELLY_Y + 0.44),
		Vector2(0.2, PLATE_Y - 0.05), Vector2(0.25, PLATE_Y - 0.02), Vector2(0.0, PLATE_Y)]), 22, Transform3D.IDENTITY, FC.NAVY)
	# --- the door: a round frame and a grille over the ember window, facing -Z -------------------------
	var dz := -0.305
	var door_c := Vector3(0.0, BELLY_Y + 0.3, dz)
	var face := Basis(Vector3.RIGHT, PI * 0.5)  # torus/disc plane -> XY, facing -Z
	kit.torus(door_c, 0.13, 0.024, FC.NAVY_DARK, face, 16, 3)
	for k in 3:
		var gx := (float(k) - 1.0) * 0.065
		kit.bar(door_c + Vector3(gx, -0.1, -0.025), door_c + Vector3(gx, 0.1, -0.025), 0.011, FC.NAVY_DARK, 6)
	kit.sphere(door_c + Vector3(0.14, 0.0, -0.03), 0.028, FC.WOOD, Vector3.ONE, 8)
	# --- the kettle on the hot plate ---------------------------------------------------------------------
	var kt := Vector3(0.1, PLATE_Y, -0.08)
	kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.08, 0.0), Vector2(0.1, 0.05), Vector2(0.085, 0.11), Vector2(0.03, 0.13),
		Vector2(0.0, 0.135)]), 14, Transform3D(Basis.IDENTITY, kt), FC.ICE_DEEP)
	kit.sphere(kt + Vector3(0.0, 0.145, 0.0), 0.022, FC.KNIT, Vector3.ONE, 6)
	kit.tube(kt + Vector3(-0.08, 0.05, 0.0), kt + Vector3(-0.15, 0.12, 0.0), 0.016, FC.ICE_DEEP, 6, 1)
	kit.torus(kt + Vector3(0.0, 0.14, 0.0), 0.07, 0.01, FC.NAVY_DARK, Basis(Vector3.RIGHT, PI * 0.5), 10, 3)
	# --- the stove pipe with its knitted cosy, and the chimney hat with snow and icicles -----------------
	var pipe_x := -0.1
	kit.cone(Vector3(pipe_x, PLATE_Y - 0.01, 0.05), 0.065, 0.06, PIPE_TOP - PLATE_Y, FC.NAVY_DARK, Basis.IDENTITY, 12)
	FC.knit_band(kit, Vector3(pipe_x, 1.05, 0.05), 0.062, 0.2, 12)
	var hat := Vector3(pipe_x, PIPE_TOP, 0.05)
	kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.17, 0.0), Vector2(0.15, 0.025), Vector2(0.06, 0.1), Vector2(0.0, 0.12)]),
		14, Transform3D(Basis.IDENTITY, hat + Vector3(0.0, 0.03, 0.0)), FC.NAVY)
	for j in 3:
		var a2 := TAU * float(j) / 3.0
		kit.bar(hat + Vector3(cos(a2) * 0.05, -0.02, sin(a2) * 0.05), hat + Vector3(cos(a2) * 0.08, 0.035, sin(a2) * 0.08),
			0.01, FC.NAVY_DARK, 6)
	kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.085), Vector2(0.09, 0.07), Vector2(0.13, 0.04), Vector2(0.11, 0.075), Vector2(0.05, 0.125),
		Vector2(0.0, 0.14)]), 14, Transform3D(Basis.IDENTITY, hat + Vector3(0.0, 0.03, 0.0)), FC.SNOW)
	FC.icicle_fringe(kit, hat + Vector3(0.0, 0.03, 0.0), 0.15, 6, 0.05, 0.11, 0.019, FC.ICE)
	add_body(kit.commit())

	# --- the ember window glows ---------------------------------------------------------------------------
	var glow := DecoKit.new()
	glow.disc(door_c + Vector3(0.0, 0.0, -0.004), 0.12, FC.EMBER, face * Basis(Vector3.RIGHT, PI), 16)
	glow.sphere(door_c + Vector3(0.0, -0.04, 0.02), 0.08, Color("#e48e55"), Vector3(1.0, 0.6, 0.4), 10)
	add_glow(glow.commit(), 2.6, "Embers", 3.2, 0.22)
	add_light(door_c + Vector3(0.0, 0.0, -0.25), Color("#e8a46a"), 2.4, 6.5)
	add_ground_glow(1.6, Color("#e8a46a"), 0.28)

	# --- wool puffs of smoke drifting up out of the chimney --------------------------------------------
	for i in PUFFS:
		var pv := pivot("Puff%d" % i, hat + Vector3(0.0, 0.16, 0.0))
		var pk := DecoKit.new()
		pk.sphere(Vector3.ZERO, 0.06, FC.SNOW_SHADE, Vector3.ONE, 8)
		add_body(pk.commit(), "Smoke", pv)
		pv.get_child(0).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_puffs.append(pv)
	animate()


func _animate(time: float, _delta: float) -> void:
	for i in _puffs.size():
		var f := fposmod(time / PUFF_PERIOD + float(i) / float(PUFFS), 1.0)
		var p := _puffs[i]
		p.position = Vector3(-0.1 + sin(f * 5.0 + float(i)) * 0.05 + f * 0.12, PIPE_TOP + 0.19 + f * PUFF_RISE, 0.05)
		var s := sin(f * PI) * (0.6 + f * 0.8)
		p.scale = Vector3.ONE * maxf(s, 0.01)
