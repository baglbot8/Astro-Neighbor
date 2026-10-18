class_name CockpitProps
extends RefCounted
## The survey ship's cockpit, built from primitives (docs/INTRO_SPEC.md section 4). Static builders,
## no state: `CockpitIntro` owns every node these return and drives them on its own clock.
##
## THE ROOM. Local space of the returned root: the pilot's eye is the origin, -Z is out of the front
## window, +Y is up, +X is the pilot's right. A small capsule cabin, 2 m wide and 1.8 m tall, its
## upper walls leaning in to a narrower ceiling: the pilot sits a little back from a wide front window
## over a sloped teal dash, quilted cream panels all round, a teal stripe at elbow height. The user's
## words for the old safari cockpit: "the white side panels of the ship but from the inside ... just a
## couple big buttons and knobs ... nothing too busy". So: two knobs, one big button, one slider, a
## radar, and nothing else on the dash but your camera and your plant.
##
## THE FOUR THINGS TO LOOK AT, each at a fixed bearing inside the look clamp so the centre dot can
## reach it (CockpitIntro YAW_LIMIT 75, PITCH_LIMIT 35; yaw positive = left):
##   photos   the cork board set into the left wall, six pinned photos on two strings; ONE is the
##            parents (two astronauts holding hands). Bearing yaw +54, pitch +8.
##   camera   on the left of the dash, brass, a dent and a scuff on its top corner. yaw +30, pitch -13.
##   letter   tucked into the right side of the window frame. yaw -36, pitch +12.
##   plant    a tiny sprout in a pot taped to the right of the dash. yaw -31, pitch -11.
##
## ONE DRAW FOR THE ROOM. Every opaque piece that is a plain colour goes into one PlanetMeshKit
## (vertex colours) drawn with the shared vertex-colour toon material (`room_material()`), so the
## cockpit is yarn like the rest of the game (STYLE_GUIDE "Crochet look") - in a FINE yarn
## (ROOM_YARN_SCALE): the game's stitch is sized for props seen from 6 m, and at arm's length it read
## as giant cable knit (round 1 frames). The photos and the letter are small runtime-painted images
## (procedural, no files) on matte lit quads; the screen, lamp and indicator lights are
## MaterialLib.glow kept smooth (YarnLite.keep_glossy, like the game's screens). Nothing casts a
## shadow: the world's sun lights the room the same way on Forward+ and on Compatibility (which has
## no cast shadows at all), so both renderers show the same cockpit.

## Colours (sRGB). Pastel and matte (STYLE_GUIDE R2.6): no swatch above S 0.60.
const PANEL := Color("#d8cab3")
const PANEL_LOW := Color("#c9baa5")
const SEAM := Color("#827870")
const FRAME := Color("#ece4d4")
const FRAME_SHADE := Color("#b3a996")
const STRIPE := Color("#6f9f9c")
const DASH := Color("#688f91")
const DASH_TOP := Color("#7aaba6")
const DASH_DARK := Color("#4f6a70")
const FLOOR := Color("#4a4f69")
const NAVY := Color("#353b58")
const KNOB := Color("#d68a72")
const KNOB_CAP := Color("#ecd9c4")
const MUSTARD := Color("#dcae55")
const SEAT := Color("#d27f63")
const SUIT := Color("#ece7dc")
const SUIT_BAND := Color("#d3957c")
## The smooth sleeve, a step darker than the mitten so the smooth white never clips.
const SUIT_SLEEVE := Color("#ddd6c9")
const BRASS := Color("#b39a6a")
const BRASS_DARK := Color("#7a6648")
const LENS := Color("#262a3c")
const POT := Color("#c58367")
const POT_RIM := Color("#d79c7f")
const SOIL := Color("#5d4636")
const LEAF := Color("#78b061")
const LEAF_DARK := Color("#4f8a4a")
const TAPE := Color("#e9dca0")
const STRING := Color("#8a7a68")
const BOARD := Color("#c9a77f")
const BOARD_EDGE := Color("#8f7254")
const PIN_COLORS: Array[Color] = [Color("#d9775f"), Color("#dcae55"), Color("#6fa0c8"), Color("#8fbf6a"),
	Color("#b48ac9"), Color("#d9775f")]
const LAMP := Color("#ffd9a8")
const ALARM := Color("#ff7a55")

## Stitch size of the room's yarn, as a fraction of the game's (toon_soft `yarn_scale`).
const ROOM_YARN_SCALE := 0.4

## The room's extents (metres, eye at the origin).
const X_HALF := 1.0
const Y_FLOOR := -0.95
const Y_CEIL := 0.82
## Where the side walls stop and lean in, and how wide the ceiling is.
const Y_SHOULDER := 0.50
const X_CEIL := 0.70
const Z_FRONT := -1.12
const Z_BACK := 0.75
const WALL := 0.12
## The front window opening, on the front wall.
const WIN_X := 0.80
const WIN_Y0 := -0.20
const WIN_Y1 := 0.66
## The window's corner radius: 35% of its 0.86 m height (the user: "rounded corners"; at a quarter of
## the height the radio box and the letter covered the corners and it read only as softened).
const WIN_CORNER_R := 0.30
## Points round the window outline (plus the cabin outline's own corners).
const WIN_SAMPLES := 160
## Height of the alarm beacon above the window's top edge (above the bezel's roll).
const BEACON_UP := 0.125
const RIVET_R := 0.012
## The dash: its top slopes from (y DASH_Y0 at the window) down to (y DASH_Y1 at DASH_Z1).
const DASH_Y0 := -0.22
const DASH_Y1 := -0.33
const DASH_Z1 := -0.62

## Target points (cockpit-local); `CockpitIntro` reads them through `targets()`.
const PHOTOS_AT := Vector3(-0.955, 0.17, -0.79)
const CAMERA_AT := Vector3(-0.47, -0.213, -0.84)
const LETTER_AT := Vector3(0.82, 0.30, -0.96)
const PLANT_AT := Vector3(0.55, -0.20, -0.92)
## Angular radius (deg) of each target as the centre dot sees it.
const PHOTOS_R := 14.0
const CAMERA_R := 8.5
const LETTER_R := 9.0
const PLANT_R := 7.5

const BOARD_SIZE := Vector2(0.54, 0.58)
const PHOTO_W := 0.155
const PHOTO_H := 0.13
const PHOTO_PX := Vector2i(128, 106)
const LETTER_SIZE := Vector2(0.23, 0.31)
## The parents' photo is the one you are meant to find: a size up from the others.
const PARENTS_SCALE := 1.3


## The four targets: id -> {"at": Vector3 (local), "r": angular radius in degrees}.
static func targets() -> Dictionary:
	return {
		"photos": {"at": PHOTOS_AT, "r": PHOTOS_R},
		"camera": {"at": CAMERA_AT, "r": CAMERA_R},
		"letter": {"at": LETTER_AT, "r": LETTER_R},
		"plant": {"at": PLANT_AT, "r": PLANT_R},
	}


## The cabin's SHELL: smooth matte toon panels (the user, 2026-10-18: "the crochet of the interior
## cockpit is very hard to look at ... can we make it like panels"). The game's own toon material with
## its per-material `yarn_skip` flag set - the same switch YarnLite flips for eyes and screens - so it
## draws the plain game look whatever the crochet global says.
static var _room_mat: ShaderMaterial
static func room_material() -> ShaderMaterial:
	if _room_mat == null:
		_room_mat = (MaterialLib.toon_vertex_color({"rim": 0.08, "spec": 0.05, "spec_size": 120.0,
			"roughness": 0.95}) as ShaderMaterial).duplicate() as ShaderMaterial
		_room_mat.set_shader_parameter("yarn_skip", true)
	return _room_mat


## The SOFT accents that stay crochet: the gloves, the dash's hand cushion, the camera strap, the
## plant and its pot, the photo board's border and the seat - things you could squeeze. In the finer
## room yarn (ROOM_YARN_SCALE), all in one mesh, which is large, so YarnLite never mistakes it for a
## "tiny part" and smooths it.
static func soft_material() -> ShaderMaterial:
	return MaterialLib.toon_vertex_color({"rim": 0.08, "spec": 0.04, "spec_size": 120.0, "roughness": 0.95,
		"yarn_scale": ROOM_YARN_SCALE})


## Builds the whole room under `root`. Returns the nodes the intro animates:
##   "lamp" OmniLight3D, "alarm" OmniLight3D, "alarm_mat" ShaderMaterial (the beacon's glow),
##   "pulses" Dictionary id -> MeshInstance3D (the soft "look at me" glow on each target),
##   "spark_at" Vector3 (local; where the graze throws sparks, the upper-right window corner).
static func build(root: Node3D) -> Dictionary:
	var kit := PlanetMeshKit.new()
	var soft := PlanetMeshKit.new()
	_shell(kit, soft)
	_front_wall(kit)
	_dash(kit, soft)
	_hands(kit, soft)
	_camera_prop(kit, soft)
	_plant(soft)
	_photo_board(kit, soft)
	_letter_clip(kit)
	var room := MeshInstance3D.new()
	room.name = "Room"
	room.mesh = kit.commit()
	room.material_override = room_material()
	room.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(room)
	var soft_mi := MeshInstance3D.new()
	soft_mi.name = "Soft"
	soft_mi.mesh = soft.commit()
	soft_mi.material_override = soft_material()
	soft_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(soft_mi)

	_glows(root)
	_photos(root)
	_letter(root)

	var out := {}
	# Warm reading lamp in the ceiling: the room's own light, so it is cosy whatever the sun does.
	var lamp := OmniLight3D.new()
	lamp.name = "Lamp"
	lamp.light_color = LAMP
	lamp.light_energy = 0.9
	lamp.omni_range = 3.2
	lamp.omni_attenuation = 0.8
	lamp.shadow_enabled = false
	lamp.light_specular = 0.0
	lamp.position = Vector3(0.0, Y_CEIL - 0.12, -0.2)
	root.add_child(lamp)
	out["lamp"] = lamp

	var alarm := OmniLight3D.new()
	alarm.name = "AlarmLight"
	alarm.light_color = ALARM
	alarm.light_energy = 0.0
	alarm.omni_range = 3.0
	alarm.omni_attenuation = 1.0
	alarm.shadow_enabled = false
	alarm.light_specular = 0.0
	alarm.position = Vector3(0.0, WIN_Y1 + 0.02, Z_FRONT + 0.35)
	alarm.visible = false
	root.add_child(alarm)
	out["alarm"] = alarm
	var beacon := MeshInstance3D.new()
	beacon.name = "AlarmBeacon"
	var bm := SphereMesh.new()
	bm.radius = 0.04
	bm.height = 0.05
	bm.radial_segments = 16
	bm.rings = 6
	beacon.mesh = bm
	var amat := (MaterialLib.glow(ALARM, 0.0, Color("#b0614e")) as ShaderMaterial).duplicate() as ShaderMaterial
	beacon.material_override = amat
	beacon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	beacon.position = Vector3(0.0, WIN_Y1 + BEACON_UP, Z_FRONT + 0.1)
	YarnLite.keep_glossy(beacon)
	root.add_child(beacon)
	out["alarm_mat"] = amat

	var pulses := {}
	var t := targets()
	for id: String in t:
		var p := MeshInstance3D.new()
		p.name = "Pulse_%s" % id
		var q := QuadMesh.new()
		var size := 0.30 if id == "photos" else 0.15
		q.size = Vector2(size, size)
		var m := (MaterialLib.glow_sprite(Color("#ffe6b0"), 0.5, {"softness": 0.75, "core": 0.12}) as ShaderMaterial).duplicate() as ShaderMaterial
		q.material = m
		p.mesh = q
		p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# A touch in front of the thing, toward the eye, so the wall does not cut the glow in half.
		var at: Vector3 = (t[id] as Dictionary)["at"]
		p.position = at - at.normalized() * 0.07
		root.add_child(p)
		pulses[id] = p
	out["pulses"] = pulses
	# Out past the right of the window, where the rock scrapes the hull: the streaks fly left across
	# the window 3-6 m out, not past the pilot's nose.
	out["spark_at"] = Vector3(3.0, 0.4, -5.0)
	return out


# ============================================================================= the shell
static func _shell(kit: PlanetMeshKit, soft: PlanetMeshKit) -> void:
	var depth := Z_BACK - Z_FRONT
	var zc := (Z_BACK + Z_FRONT) * 0.5
	# Floor and ceiling.
	kit.rounded_box(Vector3(0.0, Y_FLOOR - WALL * 0.5, zc), Vector3(X_HALF * 2.0 + WALL * 2.0, WALL, depth + WALL * 2.0), 0.04, FLOOR)
	kit.rounded_box(Vector3(0.0, Y_CEIL + WALL * 0.5, zc), Vector3(X_CEIL * 2.0 + WALL * 2.0, WALL, depth + WALL * 2.0), 0.04, SEAM)
	for i in 3:
		var z := Z_FRONT + 0.33 + 0.62 * float(i)
		kit.rounded_box(Vector3(0.0, Y_CEIL - 0.03, z), Vector3(X_CEIL * 2.0 - 0.06, 0.06, 0.56), 0.03, PANEL)
	# The lamp housing in the middle of the ceiling.
	kit.rounded_box(Vector3(0.0, Y_CEIL - 0.07, -0.2), Vector3(0.56, 0.05, 0.12), 0.025, FRAME_SHADE)
	# Side walls: a dark seam slab behind, quilted panels on it; then the shoulder panels leaning in.
	var lean_len := Vector2(X_HALF - X_CEIL, Y_CEIL - Y_SHOULDER).length()
	var lean_ang := atan2(Y_CEIL - Y_SHOULDER, X_HALF - X_CEIL)
	for sgn: float in [-1.0, 1.0]:
		kit.rounded_box(Vector3(sgn * (X_HALF + WALL * 0.5), (Y_FLOOR + Y_SHOULDER) * 0.5, zc),
			Vector3(WALL, Y_SHOULDER - Y_FLOOR, depth + WALL * 2.0), 0.03, SEAM)
		var lean_c := Vector3(sgn * (X_HALF + X_CEIL) * 0.5, (Y_SHOULDER + Y_CEIL) * 0.5, zc)
		var lean_b := Basis(Vector3.BACK, sgn * (PI * 0.5 - lean_ang))
		kit.rounded_box(lean_c + lean_b * Vector3(sgn * WALL * 0.5, 0.0, 0.0), Vector3(WALL, lean_len + 0.08, depth + WALL * 2.0), 0.03, SEAM, lean_b)
		for i in 3:
			var z := Z_FRONT + 0.33 + 0.62 * float(i)
			kit.rounded_box(Vector3(lean_c.x, lean_c.y, z), Vector3(0.06, lean_len - 0.05, 0.56), 0.03, PANEL, lean_b)
		_quilted_wall(kit, sgn)
	# Back wall and the seat.
	kit.rounded_box(Vector3(0.0, (Y_FLOOR + Y_CEIL) * 0.5, Z_BACK + WALL * 0.5),
		Vector3(X_HALF * 2.0 + WALL * 2.0, Y_CEIL - Y_FLOOR, WALL), 0.03, SEAM)
	for i in 3:
		var x := -0.64 + 0.64 * float(i)
		kit.rounded_box(Vector3(x, 0.20, Z_BACK - 0.03), Vector3(0.58, 0.56, 0.07), 0.06, PANEL)
		kit.rounded_box(Vector3(x, -0.24, Z_BACK - 0.03), Vector3(0.58, 0.09, 0.07), 0.04, STRIPE)
		kit.rounded_box(Vector3(x, -0.62, Z_BACK - 0.03), Vector3(0.58, 0.60, 0.07), 0.06, PANEL_LOW)
	soft.rounded_box(Vector3(0.0, -0.32, 0.40), Vector3(0.66, 0.78, 0.16), 0.08, SEAT)
	soft.rounded_box(Vector3(0.0, 0.14, 0.38), Vector3(0.42, 0.22, 0.14), 0.07, SEAT.lightened(0.08))
	# Rivets at the corners of the back panels (the front wall is `_front_wall`).
	for i in 3:
		var x := -0.64 + 0.64 * float(i)
		for c: Vector2 in [Vector2(-0.25, 0.44), Vector2(0.25, 0.44), Vector2(-0.25, -0.04), Vector2(0.25, -0.04)]:
			kit.sphere(Vector3(x + c.x, c.y, Z_BACK - 0.07), RIVET_R, FRAME_SHADE, Vector3(1.0, 1.0, 0.5), 8)
	# Floor: a darker footwell and two rails.
	kit.rounded_box(Vector3(0.0, Y_FLOOR + 0.01, -0.5), Vector3(1.2, 0.03, 0.8), 0.015, NAVY)
	for sgn: float in [-1.0, 1.0]:
		kit.rounded_box(Vector3(sgn * 0.68, Y_FLOOR + 0.02, -0.1), Vector3(0.06, 0.04, 1.5), 0.02, FRAME_SHADE)


## Quilted panels on one side wall: three columns, a teal stripe at elbow height between an upper and
## a lower row. The left wall's front upper panel is the photo board instead.
static func _quilted_wall(kit: PlanetMeshKit, sgn: float) -> void:
	var x := sgn * (X_HALF - 0.035)
	for i in 3:
		var z := Z_FRONT + 0.33 + 0.62 * float(i)
		var is_board := sgn < 0.0 and i == 0
		if not is_board:
			kit.rounded_box(Vector3(x, 0.17, z), Vector3(0.07, 0.62, 0.56), 0.04, PANEL)
			# A rivet in each corner of the upper panel: a ship's panel, not a cushion.
			for c: Vector2 in [Vector2(-0.24, 0.43), Vector2(0.24, 0.43), Vector2(-0.24, -0.09), Vector2(0.24, -0.09)]:
				kit.sphere(Vector3(x - sgn * 0.04, c.y, z + c.x), RIVET_R, FRAME_SHADE, Vector3(0.5, 1.0, 1.0), 8)
		kit.rounded_box(Vector3(x, -0.24, z), Vector3(0.07, 0.09, 0.56), 0.03, STRIPE)
		kit.rounded_box(Vector3(x, -0.62, z), Vector3(0.07, 0.60, 0.56), 0.04, PANEL_LOW)


# ============================================================================= window and dash
## THE FRONT WALL AND THE ROUNDED WINDOW (the user, 2026-10-18: "it feels very rectangular, can we
## add some rounded corners to the window?"). One plate across the whole front of the cabin, cut by a
## rounded-rectangle opening (corner radius WIN_CORNER_R, a quarter of the window's height), and a
## rolled bezel swept along that same curve. Built from two closed outlines sampled at the same
## angles round the window's centre - the cabin's cross-section outside, the rounded opening inside -
## so the plate is one ring of quads, and every corner of the cabin outline is sampled exactly.
## Nothing at all is drawn inside the opening.
static func _front_wall(kit: PlanetMeshKit) -> void:
	var c := Vector2(0.0, (WIN_Y0 + WIN_Y1) * 0.5)
	var outer := PackedVector2Array([Vector2(-X_HALF - 0.02, DASH_Y1 - 0.02), Vector2(X_HALF + 0.02, DASH_Y1 - 0.02),
		Vector2(X_HALF + 0.02, Y_SHOULDER), Vector2(X_CEIL + 0.02, Y_CEIL + 0.02), Vector2(-X_CEIL - 0.02, Y_CEIL + 0.02),
		Vector2(-X_HALF - 0.02, Y_SHOULDER)])
	# Sample angles: an even sweep plus the exact angle of every outline corner.
	var angles: Array[float] = []
	for k in WIN_SAMPLES:
		angles.append(TAU * float(k) / float(WIN_SAMPLES))
	for v in outer:
		angles.append(fposmod(atan2(v.y - c.y, v.x - c.x), TAU))
	angles.sort()
	var inner := PackedVector2Array()
	var outp := PackedVector2Array()
	for a in angles:
		var d := Vector2(cos(a), sin(a))
		inner.append(c + d * _ray_to_rounded_rect(d))
		outp.append(c + d * _ray_to_polygon(c, d, outer))
	var n := inner.size()
	var z := Z_FRONT
	var fwd := Vector3(0.0, 0.0, 1.0)
	for k in n:
		var k2 := (k + 1) % n
		var a := Vector3(inner[k].x, inner[k].y, z)
		var b := Vector3(inner[k2].x, inner[k2].y, z)
		var cc := Vector3(outp[k2].x, outp[k2].y, z)
		var dd := Vector3(outp[k].x, outp[k].y, z)
		_tri(kit, a, b, cc, fwd, fwd, fwd, PANEL)
		_tri(kit, a, cc, dd, fwd, fwd, fwd, PANEL)
	# The bezel: a rolled lip swept along the opening. Profile = (outward from the opening, toward
	# the pilot): it rises from the glass edge, rolls over and settles onto the plate.
	var prof := [Vector2(0.0, 0.0), Vector2(-0.004, 0.03), Vector2(0.012, 0.052), Vector2(0.04, 0.062),
		Vector2(0.075, 0.056), Vector2(0.10, 0.034), Vector2(0.115, 0.0)]
	var outward: Array[Vector2] = []
	for k in n:
		var t := (inner[(k + 1) % n] - inner[(k - 1 + n) % n]).normalized()
		outward.append(Vector2(t.y, -t.x))
	var pn: Array[Vector2] = []
	for m in prof.size():
		var t2: Vector2 = (prof[mini(m + 1, prof.size() - 1)] as Vector2) - (prof[maxi(m - 1, 0)] as Vector2)
		pn.append(Vector2(t2.y, -t2.x).normalized() * -1.0)
	for k in n:
		var k2 := (k + 1) % n
		for m in prof.size() - 1:
			var corners: Array[Vector3] = []
			var norms: Array[Vector3] = []
			for e: Array in [[k, m], [k2, m], [k2, m + 1], [k, m + 1]]:
				var ki: int = e[0]
				var mi: int = e[1]
				var pr: Vector2 = prof[mi]
				var o: Vector2 = outward[ki]
				var p2 := inner[ki] + o * pr.x
				corners.append(Vector3(p2.x, p2.y, z + pr.y))
				var nn: Vector2 = pn[mi]
				norms.append((Vector3(o.x, o.y, 0.0) * nn.x + fwd * nn.y).normalized())
			_tri(kit, corners[0], corners[1], corners[2], norms[0], norms[1], norms[2], FRAME)
			_tri(kit, corners[0], corners[2], corners[3], norms[0], norms[2], norms[3], FRAME)
	# Rivets round the bezel, on the plate.
	var step := maxi(n / 14, 1)
	for k in range(0, n, step):
		var p3 := inner[k] + outward[k] * 0.155
		if p3.y > DASH_Y0 + 0.03:
			kit.sphere(Vector3(p3.x, p3.y, z + 0.006), RIVET_R, FRAME_SHADE, Vector3(1.0, 1.0, 0.5), 8)
	# The alarm beacon's cup, centred over the window (the glowing dome is its own node).
	kit.cylinder(Vector3(0.0, WIN_Y1 + BEACON_UP, z + 0.07), 0.05, 0.045, 0.03, FRAME_SHADE, Basis(Vector3.RIGHT, PI * 0.5), 16)


## Distance from the window's centre to the rounded opening's edge along unit direction `d`
## (bisection on the rounded rectangle's signed distance; the shape is convex, so it is monotonic).
static func _ray_to_rounded_rect(d: Vector2) -> float:
	var h := Vector2(WIN_X, (WIN_Y1 - WIN_Y0) * 0.5)
	var lo := 0.0
	var hi := 2.0
	for _i in 32:
		var mid := (lo + hi) * 0.5
		var q := (d * mid).abs() - (h - Vector2(WIN_CORNER_R, WIN_CORNER_R))
		var sd := Vector2(maxf(q.x, 0.0), maxf(q.y, 0.0)).length() + minf(maxf(q.x, q.y), 0.0) - WIN_CORNER_R
		if sd < 0.0:
			lo = mid
		else:
			hi = mid
	return lo


## Distance from `c` to convex polygon `poly`'s edge along unit direction `d`.
static func _ray_to_polygon(c: Vector2, d: Vector2, poly: PackedVector2Array) -> float:
	var lo := 0.0
	var hi := 4.0
	for _i in 32:
		var mid := (lo + hi) * 0.5
		if Geometry2D.is_point_in_polygon(c + d * mid, poly):
			lo = mid
		else:
			hi = mid
	return lo


## One triangle straight into the kit's arrays with the given (smooth) normals, wound so its front
## face is the side its normals point to (PlanetMeshKit.triangle's own convention).
static func _tri(kit: PlanetMeshKit, a: Vector3, b: Vector3, c: Vector3, na: Vector3, nb: Vector3, nc: Vector3, col: Color) -> void:
	var face := (c - a).cross(b - a)
	if face.dot(na + nb + nc) < 0.0:
		var t := b
		b = c
		c = t
		var tn := nb
		nb = nc
		nc = tn
	var base := kit._verts.size()
	var lc := PlanetMeshKit._lin(col)
	for e: Array in [[a, na], [b, nb], [c, nc]]:
		kit._verts.append(e[0] as Vector3)
		kit._norms.append(e[1] as Vector3)
		kit._cols.append(lc)
		kit._uvs.append(Vector2.ZERO)
	kit._idx.append_array(PackedInt32Array([base, base + 1, base + 2]))


static func _dash_basis() -> Basis:
	var zf := Z_FRONT + 0.05
	var depth := DASH_Z1 - zf
	var drop := DASH_Y1 - DASH_Y0
	return Basis(Vector3.RIGHT, -atan2(drop, absf(depth)))


static func _dash_top_centre() -> Vector3:
	var zf := Z_FRONT + 0.05
	return Vector3(0.0, (DASH_Y0 + DASH_Y1) * 0.5 - 0.03, (zf + DASH_Z1) * 0.5)


static func _dash(kit: PlanetMeshKit, soft: PlanetMeshKit) -> void:
	var zf := Z_FRONT + 0.05
	var depth := DASH_Z1 - zf
	var zc := (zf + DASH_Z1) * 0.5
	var drop := DASH_Y1 - DASH_Y0
	var b := _dash_basis()
	var top_c := _dash_top_centre()
	var top_len := sqrt(depth * depth + drop * drop)
	var wide := X_HALF * 2.0 - 0.06
	# The sloped top panel and the body under it down to the floor.
	kit.rounded_box(top_c, Vector3(wide, 0.07, top_len + 0.06), 0.03, DASH_TOP, b)
	kit.rounded_box(Vector3(0.0, (Y_FLOOR + DASH_Y1) * 0.5 - 0.04, zc + 0.02),
		Vector3(wide, DASH_Y1 - Y_FLOOR - 0.04, absf(depth) * 0.9), 0.04, DASH)
	# A crocheted cushion along the pilot's edge, where the hands rest (one of the soft accents).
	soft.rounded_box(Vector3(0.0, DASH_Y1 - 0.045, DASH_Z1 + 0.01), Vector3(wide - 0.04, 0.07, 0.09), 0.035, FRAME)
	# The face under the lip (seen when looking down): darker teal with two vents.
	kit.rounded_box(Vector3(0.0, -0.60, DASH_Z1 - 0.02), Vector3(wide - 0.08, 0.40, 0.04), 0.02, DASH_DARK)
	for sgn: float in [-1.0, 1.0]:
		for k in 3:
			kit.rounded_box(Vector3(sgn * 0.5, -0.54 - 0.06 * float(k), DASH_Z1 + 0.005), Vector3(0.30, 0.025, 0.02), 0.01, NAVY)

	var up := b * Vector3.UP
	var on_top := func(x: float, along: float) -> Vector3:
		return top_c + b * Vector3(x, 0.035, along)
	# Two panel seams across the dash top, outboard of the controls, and a rivet at each end.
	for sx: float in [-0.62, 0.62]:
		kit.rounded_box(on_top.call(sx, 0.0) - up * 0.031, Vector3(0.012, 0.012, top_len + 0.02), 0.005, DASH_DARK, b)
		for along: float in [-0.18, 0.18]:
			kit.sphere(on_top.call(sx + signf(sx) * 0.05, along) - up * 0.03, RIVET_R, FRAME_SHADE, Vector3(1.0, 0.5, 1.0), 8, b)
	# Radar: a cream bezel ring round the glow screen (the screen is a separate node, see _glows).
	kit.torus(on_top.call(0.0, -0.02) + up * 0.005, 0.10, 0.02, FRAME, b)
	kit.cylinder(on_top.call(0.0, -0.02) - up * 0.01, 0.095, 0.095, 0.018, NAVY, b, 24)
	# Two big coral knobs left of centre.
	for i in 2:
		var p: Vector3 = on_top.call(-0.20 - 0.15 * float(i), 0.06)
		kit.cylinder(p, 0.05, 0.046, 0.045, KNOB, b, 18)
		kit.cylinder(p + up * 0.045, 0.046, 0.032, 0.016, KNOB_CAP, b, 18)
		kit.rounded_box(p + up * 0.056 + b * Vector3(0.0, 0.0, -0.022), Vector3(0.012, 0.012, 0.036), 0.005, NAVY, b)
	# A big mustard push button right of centre, on a cream collar.
	var bp: Vector3 = on_top.call(0.22, 0.05)
	kit.cylinder(bp, 0.068, 0.068, 0.02, FRAME, b, 20)
	kit.sphere(bp + up * 0.028, 0.052, MUSTARD, Vector3(1.0, 0.55, 1.0), 18, b)
	# A slider: navy track and a cream handle.
	var sp: Vector3 = on_top.call(0.37, 0.03)
	kit.rounded_box(sp, Vector3(0.045, 0.02, 0.2), 0.01, NAVY, b)
	kit.rounded_box(sp + up * 0.025 + b * Vector3(0.0, 0.0, -0.035), Vector3(0.065, 0.035, 0.045), 0.015, FRAME, b)


## The pilot's gloved hands resting on the dash: chunky mittens with the suit's accent cuff, and the
## sleeves running back out of view.
static func _hands(kit: PlanetMeshKit, soft: PlanetMeshKit) -> void:
	var b := _dash_basis()
	var top_c := _dash_top_centre()
	for sgn: float in [-1.0, 1.0]:
		var c := top_c + b * Vector3(sgn * 0.22, 0.09, 0.17)
		var yaw := b * Basis(Vector3.UP, -sgn * 0.3)
		soft.sphere(c, 0.07, SUIT, Vector3(1.0, 0.62, 1.2), 16, yaw)
		# The thumb, on the inside.
		soft.sphere(c + yaw * Vector3(-sgn * 0.062, 0.006, 0.01), 0.03, SUIT, Vector3(1.0, 0.8, 1.3), 10, yaw)
		# Cuff band (crochet, with the mitten) and the suit sleeve (smooth: round 4 frames had the sleeves
		# as the biggest knitted area on screen), back toward the pilot and down out of view.
		var back := yaw * Basis(Vector3.RIGHT, PI * 0.5 + 0.35)
		soft.cylinder(c + yaw * Vector3(0.0, -0.006, 0.065), 0.058, 0.062, 0.045, SUIT_BAND, back, 16)
		kit.cylinder(c + yaw * Vector3(0.0, -0.02, 0.105), 0.064, 0.08, 0.32, SUIT_SLEEVE, back, 16)


# ============================================================================= the four things
## Your camera: a brass box camera with a big lens, a dent in the top corner and a worn strap.
static func _camera_prop(kit: PlanetMeshKit, soft: PlanetMeshKit) -> void:
	var c := CAMERA_AT
	var yaw := Basis(Vector3.UP, 0.5)
	kit.rounded_box(c, Vector3(0.19, 0.115, 0.095), 0.028, BRASS, yaw)
	# Dark leatherette band round the middle.
	kit.rounded_box(c + yaw * Vector3(0.0, -0.005, 0.0), Vector3(0.195, 0.048, 0.1), 0.02, BRASS_DARK, yaw)
	# The lens, facing the pilot a little to the right.
	var lens_basis := yaw * Basis(Vector3.RIGHT, PI * 0.5)
	var front := c + yaw * Vector3(0.02, 0.0, 0.047)
	kit.cylinder(front, 0.043, 0.04, 0.042, BRASS_DARK, lens_basis, 20)
	kit.cylinder(front + yaw * Vector3(0.0, 0.0, 0.042), 0.038, 0.038, 0.01, LENS, lens_basis, 20)
	kit.torus(front + yaw * Vector3(0.0, 0.0, 0.047), 0.038, 0.008, BRASS, lens_basis, 20)
	# Viewfinder and shutter button on top.
	kit.rounded_box(c + yaw * Vector3(-0.052, 0.072, 0.0), Vector3(0.048, 0.034, 0.048), 0.012, BRASS_DARK, yaw)
	kit.cylinder(c + yaw * Vector3(0.056, 0.057, -0.01), 0.013, 0.013, 0.02, KNOB, yaw, 10)
	# THE DENT: a pushed-in dark dish on the top right corner, and a scuff of bare metal next to it.
	kit.sphere(c + yaw * Vector3(0.07, 0.053, 0.033), 0.03, BRASS_DARK.darkened(0.25), Vector3(1.2, 0.45, 1.0), 10, yaw)
	kit.sphere(c + yaw * Vector3(0.045, 0.06, 0.043), 0.016, Color("#d8c08c"), Vector3(1.4, 0.3, 0.8), 8, yaw)
	# Strap loop lying on the dash.
	soft.torus(c + Vector3(0.0, -0.053, 0.10), 0.07, 0.011, NAVY, Basis.IDENTITY, 18)


## A tiny sprout in a pot, stuck to the dash with two strips of tape.
static func _plant(soft: PlanetMeshKit) -> void:
	var base := PLANT_AT + Vector3(0.0, -0.05, 0.0)
	soft.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.032, 0.0), Vector2(0.042, 0.055),
		Vector2(0.048, 0.06), Vector2(0.048, 0.072), Vector2(0.0, 0.072)]), 16,
		Transform3D(Basis.IDENTITY, base), POT, false)
	soft.torus(base + Vector3(0.0, 0.066, 0.0), 0.046, 0.008, POT_RIM, Basis.IDENTITY, 16)
	soft.cylinder(base + Vector3(0.0, 0.06, 0.0), 0.04, 0.04, 0.008, SOIL, Basis.IDENTITY, 16)
	var stem_top := base + Vector3(0.0, 0.13, 0.0)
	soft.cylinder(base + Vector3(0.0, 0.065, 0.0), 0.006, 0.005, 0.07, LEAF_DARK, Basis.IDENTITY, 8)
	# Three leaves, flattened spheres, tilted out.
	for i in 3:
		var a := TAU * float(i) / 3.0 + 0.4
		var tilt := Basis(Vector3.UP, a) * Basis(Vector3.FORWARD, 0.75)
		var col := LEAF if i != 1 else LEAF.lightened(0.08)
		soft.sphere(stem_top + Basis(Vector3.UP, a) * Vector3(0.028, -0.008, 0.0), 0.03, col, Vector3(1.3, 0.28, 0.75), 12, tilt)
	soft.sphere(stem_top + Vector3(0.0, 0.012, 0.0), 0.013, LEAF.lightened(0.12), Vector3(1.0, 0.7, 1.0), 8)
	# Tape strips over the pot's foot onto the dash.
	for sgn: float in [-1.0, 1.0]:
		soft.rounded_box(base + Vector3(sgn * 0.045, 0.012, 0.0), Vector3(0.05, 0.006, 0.026), 0.003, TAPE,
			Basis(Vector3.FORWARD, sgn * 0.5))


## The cork board set into the left wall in place of a panel, and the two strings across it.
static func _photo_board(kit: PlanetMeshKit, soft: PlanetMeshKit) -> void:
	var b := _board_basis()
	var c := PHOTOS_AT + b * Vector3(0.0, 0.0, -0.025)
	# The border is a crocheted frame (a soft accent); the cork inside it is smooth.
	soft.rounded_box(c + b * Vector3(0.0, 0.0, -0.012), Vector3(BOARD_SIZE.x + 0.05, BOARD_SIZE.y + 0.05, 0.03), 0.02, BOARD_EDGE, b)
	kit.rounded_box(c, Vector3(BOARD_SIZE.x, BOARD_SIZE.y, 0.03), 0.015, BOARD, b)
	for row in 2:
		var prev := Vector3.ZERO
		for i in 9:
			var x := lerpf(-BOARD_SIZE.x * 0.47, BOARD_SIZE.x * 0.47, float(i) / 8.0)
			var p := PHOTOS_AT + b * Vector3(x, _string_y(row, x), -0.006)
			if i > 0:
				var seg := p - prev
				var mid := (p + prev) * 0.5
				var ls := b.inverse() * seg
				kit.rounded_box(mid, Vector3(seg.length() + 0.004, 0.005, 0.005), 0.002, STRING, b * Basis(Vector3.BACK, atan2(ls.y, ls.x)))
			prev = p
	var lay := photo_layout()
	for i in lay.size():
		var at: Vector3 = (lay[i] as Dictionary)["pin"]
		kit.sphere(at, 0.011, PIN_COLORS[i % PIN_COLORS.size()], Vector3.ONE, 8)


## Flat on the left wall, facing into the room (+X); its right (as you look at it) is toward the window.
static func _board_basis() -> Basis:
	return Basis(Vector3(0.0, 0.0, -1.0), Vector3.UP, Vector3(1.0, 0.0, 0.0))


## Height of photo string `row` at board-local `x`: tied at the board's edges, sagging in the middle.
static func _string_y(row: int, x: float) -> float:
	var y0 := 0.25 - 0.25 * float(row)
	var u := x / (BOARD_SIZE.x * 0.94) + 0.5
	return y0 - 0.03 * (1.0 - 4.0 * (u - 0.5) * (u - 0.5))


## Where each photo hangs: centre, a small tilt, and its pin. Six photos on two strings; index 0 is
## the parents, top row, in the middle (where the eye lands first).
static func photo_layout() -> Array:
	var b := _board_basis()
	# [x on the board, string row, tilt]
	var spots := [
		[0.0, 0, -0.05], [-0.185, 0, 0.06], [0.185, 0, 0.04],
		[-0.165, 1, -0.05], [0.005, 1, 0.06], [0.17, 1, -0.04],
	]
	var out := []
	for s: Array in spots:
		var x: float = s[0]
		var y := _string_y(int(s[1]), x)
		var tilt: float = s[2]
		var basis := b * Basis(Vector3.BACK, tilt)
		var h := PHOTO_H * (PARENTS_SCALE if out.is_empty() else 1.0)
		var centre := PHOTOS_AT + b * Vector3(x, y - h * 0.5 + 0.012, 0.004)
		var pin := centre + basis * Vector3(0.0, h * 0.5 - 0.014, 0.006)
		out.append({"centre": centre, "basis": basis, "pin": pin})
	return out


static func _letter_clip(kit: PlanetMeshKit) -> void:
	var b := _letter_basis()
	# A chunky clip on the window frame holding the letter's top corner.
	kit.rounded_box(LETTER_AT + b * Vector3(0.05, LETTER_SIZE.y * 0.5 - 0.01, 0.012), Vector3(0.07, 0.04, 0.025), 0.01, NAVY, b)
	kit.rounded_box(LETTER_AT + b * Vector3(0.05, LETTER_SIZE.y * 0.5 + 0.015, 0.0), Vector3(0.05, 0.02, 0.03), 0.008, FRAME_SHADE, b)


static func _letter_basis() -> Basis:
	var z := (-LETTER_AT).normalized()
	var x := Vector3.UP.cross(z).normalized()
	var y := z.cross(x).normalized()
	return Basis(x, y, z) * Basis(Vector3.BACK, -0.07)


# ============================================================================= glows, photos, glass
static func _glows(root: Node3D) -> void:
	var strip := MeshInstance3D.new()
	strip.name = "LampStrip"
	var sm := BoxMesh.new()
	sm.size = Vector3(0.5, 0.012, 0.07)
	strip.mesh = sm
	strip.material_override = MaterialLib.glow(LAMP, 0.9, Color("#e8c9a0"))
	strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	strip.position = Vector3(0.0, Y_CEIL - 0.1, -0.2)
	YarnLite.keep_glossy(strip)
	root.add_child(strip)
	# The radar screen: a dim teal disc.
	var b := _dash_basis()
	var top_c := _dash_top_centre()
	var screen := MeshInstance3D.new()
	screen.name = "Radar"
	var cm := CylinderMesh.new()
	cm.top_radius = 0.09
	cm.bottom_radius = 0.09
	cm.height = 0.004
	cm.radial_segments = 28
	screen.mesh = cm
	screen.material_override = MaterialLib.glow(Color("#9cc4bc"), 0.3, Color("#55686a"))
	screen.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	screen.transform = Transform3D(b, top_c + b * Vector3(0.0, 0.047, -0.02))
	YarnLite.keep_glossy(screen)
	root.add_child(screen)
	# A sweep line and two blips on the radar, slightly above the screen.
	var marks := [[Vector3(0.025, 0.05, -0.05), 0.012, Color("#bff0e2")], [Vector3(-0.04, 0.05, 0.0), 0.009, Color("#ffd79a")]]
	for mk: Array in marks:
		var d := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = float(mk[1])
		s.height = float(mk[1]) * 0.6
		s.radial_segments = 10
		s.rings = 4
		d.mesh = s
		d.material_override = MaterialLib.glow(mk[2] as Color, 0.9)
		d.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		d.transform = Transform3D(b, top_c + b * (mk[0] as Vector3))
		YarnLite.keep_glossy(d)
		root.add_child(d)
	# Small indicator lights near the ends of the dash: amber and teal, a few percent of the frame.
	var lights := [[-0.72, Color("#ffc46b")], [-0.64, Color("#7fe0c8")], [0.64, Color("#7fe0c8")], [0.72, Color("#ffc46b")]]
	for l: Array in lights:
		var d := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = 0.016
		s.height = 0.02
		s.radial_segments = 10
		s.rings = 4
		d.mesh = s
		d.material_override = MaterialLib.glow(l[1] as Color, 0.8)
		d.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		d.transform = Transform3D(b, top_c + b * Vector3(float(l[0]), 0.04, -0.10))
		YarnLite.keep_glossy(d)
		root.add_child(d)


static func _photos(root: Node3D) -> void:
	var lay := photo_layout()
	for i in lay.size():
		var spot: Dictionary = lay[i]
		var mi := MeshInstance3D.new()
		mi.name = "Photo%d" % i
		var q := QuadMesh.new()
		q.size = Vector2(PHOTO_W, PHOTO_H) * (PARENTS_SCALE if i == 0 else 1.0)
		mi.mesh = q
		mi.material_override = _paper_material(paint_photo(i))
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.transform = Transform3D(spot["basis"] as Basis, spot["centre"] as Vector3)
		root.add_child(mi)


static func _letter(root: Node3D) -> void:
	var mi := MeshInstance3D.new()
	mi.name = "JobLetter"
	var q := QuadMesh.new()
	q.size = LETTER_SIZE
	mi.mesh = q
	mi.material_override = _paper_material(paint_letter())
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.transform = Transform3D(_letter_basis(), LETTER_AT)
	root.add_child(mi)


## Lit, matte paper. Not the toon/crochet material: a stitch pattern over a photo would hide what is
## in it (STYLE_GUIDE "Crochet look" keeps screens, overlays and pictures plain).
static func _paper_material(tex: Texture2D) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.roughness = 0.95
	m.metallic_specular = 0.1
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


# ============================================================================= painted images
## A photo, painted into a small image at runtime (procedural: no files). A white border all round
## and a deeper one at the bottom, like an instant photo. 0 = the parents.
static func paint_photo(i: int) -> ImageTexture:
	var w := PHOTO_PX.x
	var h := PHOTO_PX.y
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color("#f1ece2"))
	var pic := Rect2i(5, 5, w - 10, h - 18)
	match i:
		0: # The parents: two astronauts, one taller, standing hand in hand on a green hill. Outlined in
			# navy on a mid-blue sky: round 2 painted white suits on a pale sky, and at 1.2 m all that
			# survived were the two dark visors and a coral belt - which read as a face.
			_vgrad(img, pic, Color("#4f7f9c"), Color("#9dbcc2"))
			_ellipse(img, Vector2(pic.position.x + pic.size.x * 0.5, pic.end.y + 26.0), Vector2(92.0, 42.0), Color("#6f9f5c"))
			var ground := float(pic.end.y) - 10.0
			var suit := Color("#f4f1ea")
			var line := Color("#2b3358")
			for k in 2:
				var s := 1.0 if k == 0 else 0.93
				var cx := pic.position.x + pic.size.x * (0.36 + 0.29 * float(k))
				var body := Vector2(cx, ground - 19.0 * s)
				var head := Vector2(cx, ground - 41.0 * s)
				var outer := -1.0 if k == 0 else 1.0
				var arm_o := Vector2(cx + outer * 12.5 * s, ground - 19.0 * s)
				var arm_i := Vector2(cx - outer * 13.0 * s, ground - 16.0 * s)
				# Navy outline first, then the suit over it.
				for coat in 2:
					var o := 1.8 if coat == 0 else 0.0
					var c := line if coat == 0 else suit
					_ellipse(img, Vector2(cx - 5.0 * s, ground - 5.0 * s), Vector2(3.5 * s + o, 6.0 * s + o), c)
					_ellipse(img, Vector2(cx + 5.0 * s, ground - 5.0 * s), Vector2(3.5 * s + o, 6.0 * s + o), c)
					_ellipse(img, body, Vector2(11.0 * s + o, 13.0 * s + o), c)
					_ellipse(img, arm_o, Vector2(3.5 * s + o, 8.0 * s + o), c)
					_ellipse(img, arm_i, Vector2(7.5 * s + o, 3.2 * s + o), c)
					_disc(img, head, 12.5 * s + o, c)
				_rect(img, Rect2i(int(cx - 10.0 * s), int(ground - 15.0 * s), int(20.0 * s), 3),
					Color("#e0805f") if k == 0 else Color("#5f9a9c"))
				_ellipse(img, head + Vector2(1.0, 1.0) * s, Vector2(8.5, 5.5) * s, line)
				_ellipse(img, head + Vector2(3.5, -1.5) * s, Vector2(2.4, 1.3) * s, Color("#e6ecf7"))
		1: # Home from orbit: a green planet in the dark.
			_vgrad(img, pic, Color("#1d2140"), Color("#2c2f55"))
			_disc(img, Vector2(pic.position.x + pic.size.x * 0.55, pic.position.y + pic.size.y * 0.55), 20.0, Color("#7fb86a"))
			_disc(img, Vector2(pic.position.x + pic.size.x * 0.55 - 5.0, pic.position.y + pic.size.y * 0.55 - 6.0), 9.0, Color("#9fcd84"))
			for k in 9:
				var sx := pic.position.x + fposmod(float(k) * 37.7, float(pic.size.x))
				var sy := pic.position.y + fposmod(float(k) * 23.3, float(pic.size.y))
				_disc(img, Vector2(sx, sy), 1.0, Color("#e9e6f5"))
		2: # A sunset over flat ground.
			_vgrad(img, pic, Color("#e9a07f"), Color("#f2d3a6"))
			_disc(img, Vector2(pic.position.x + pic.size.x * 0.4, pic.end.y - 16.0), 11.0, Color("#f7e6b8"))
			_rect(img, Rect2i(pic.position.x, pic.end.y - 14, pic.size.x, 14), Color("#7d6a8c"))
		3: # Your first rocket, on its pad.
			_vgrad(img, pic, Color("#2c3156"), Color("#46507a"))
			var rx := pic.position.x + pic.size.x * 0.5
			_ellipse(img, Vector2(rx, pic.position.y + pic.size.y * 0.5), Vector2(8.0, 20.0), Color("#ece7dc"))
			_disc(img, Vector2(rx, pic.position.y + pic.size.y * 0.42), 4.0, Color("#5f9a9c"))
			_rect(img, Rect2i(int(rx) - 10, pic.end.y - 14, 20, 5), Color("#e0805f"))
			_rect(img, Rect2i(pic.position.x, pic.end.y - 9, pic.size.x, 9), Color("#8d8aa0"))
		4: # A friend: a round purple alien waving.
			_vgrad(img, pic, Color("#d6e6cf"), Color("#eef0e2"))
			var ax := pic.position.x + pic.size.x * 0.5
			var ay := pic.position.y + pic.size.y * 0.58
			_disc(img, Vector2(ax, ay), 17.0, Color("#a98bcf"))
			_disc(img, Vector2(ax - 6.0, ay - 3.0), 3.0, Color("#262038"))
			_disc(img, Vector2(ax + 6.0, ay - 3.0), 3.0, Color("#262038"))
			_ellipse(img, Vector2(ax + 19.0, ay - 12.0), Vector2(4.0, 7.0), Color("#a98bcf"))
			_disc(img, Vector2(ax, ay - 23.0), 3.0, Color("#86d0b8"))
		_: # A puff tree on a cream plaza.
			_vgrad(img, pic, Color("#cfd9e6"), Color("#ede4d2"))
			var tx := pic.position.x + pic.size.x * 0.5
			_rect(img, Rect2i(int(tx) - 3, pic.end.y - 20, 6, 16), Color("#8a6a52"))
			_ellipse(img, Vector2(tx, pic.end.y - 27.0), Vector2(18.0, 11.0), Color("#78b061"))
			_ellipse(img, Vector2(tx, pic.end.y - 36.0), Vector2(12.0, 8.0), Color("#8cc070"))
			_rect(img, Rect2i(pic.position.x, pic.end.y - 5, pic.size.x, 5), Color("#e3d6bd"))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


## The job letter: a header band with the station's star, lines of writing, a signature and a stamp.
static func paint_letter() -> ImageTexture:
	var w := 120
	var h := 160
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color("#f3eee2"))
	_rect(img, Rect2i(0, 0, w, 26), Color("#4c5b8c"))
	_disc(img, Vector2(16.0, 13.0), 8.0, Color("#f0c66a"))
	_rect(img, Rect2i(30, 9, 70, 4), Color("#dfe3f0"))
	_rect(img, Rect2i(30, 16, 46, 3), Color("#b9c1dc"))
	for k in 9:
		var lw := 92 - (k * 17) % 34
		_rect(img, Rect2i(12, 38 + k * 10, lw, 3), Color("#9a98a8"))
	# The big "1" of "day one", circled.
	_ring(img, Vector2(96.0, 128.0), 13.0, 2.5, Color("#e0805f"))
	_rect(img, Rect2i(95, 120, 3, 16), Color("#e0805f"))
	# Signature squiggle.
	for k in 30:
		var x := 14.0 + float(k) * 1.6
		_disc(img, Vector2(x, 136.0 + 4.0 * sin(float(k) * 0.7)), 1.0, Color("#3b4160"))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


static func _rect(img: Image, r: Rect2i, c: Color) -> void:
	var rr := r.intersection(Rect2i(Vector2i.ZERO, img.get_size()))
	if rr.size.x > 0 and rr.size.y > 0:
		img.fill_rect(rr, c)


static func _vgrad(img: Image, r: Rect2i, top: Color, bottom: Color) -> void:
	for y in r.size.y:
		var k := float(y) / float(maxi(r.size.y - 1, 1))
		_rect(img, Rect2i(r.position.x, r.position.y + y, r.size.x, 1), top.lerp(bottom, k))


## Filled, softly anti-aliased disc clipped to the picture (border pixels stay paper).
static func _disc(img: Image, c: Vector2, rad: float, col: Color) -> void:
	_ellipse(img, c, Vector2(rad, rad), col)


static func _ellipse(img: Image, c: Vector2, r: Vector2, col: Color) -> void:
	var sz := img.get_size()
	var x0 := maxi(int(c.x - r.x - 1.0), 5)
	var x1 := mini(int(c.x + r.x + 1.0), sz.x - 6)
	var y0 := maxi(int(c.y - r.y - 1.0), 5)
	var y1 := mini(int(c.y + r.y + 1.0), sz.y - 6)
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			var dx := (float(x) + 0.5 - c.x) / maxf(r.x, 0.01)
			var dy := (float(y) + 0.5 - c.y) / maxf(r.y, 0.01)
			var d := sqrt(dx * dx + dy * dy)
			var a := clampf((1.0 - d) * minf(r.x, r.y) + 0.5, 0.0, 1.0)
			if a <= 0.0:
				continue
			img.set_pixel(x, y, img.get_pixel(x, y).lerp(col, a))


static func _ring(img: Image, c: Vector2, rad: float, width: float, col: Color) -> void:
	var sz := img.get_size()
	for y in range(maxi(int(c.y - rad - width), 0), mini(int(c.y + rad + width) + 1, sz.y)):
		for x in range(maxi(int(c.x - rad - width), 0), mini(int(c.x + rad + width) + 1, sz.x)):
			var d := Vector2(float(x) + 0.5, float(y) + 0.5).distance_to(c)
			var a := clampf(width * 0.5 - absf(d - rad) + 0.5, 0.0, 1.0)
			if a > 0.0:
				img.set_pixel(x, y, img.get_pixel(x, y).lerp(col, a))


# ============================================================================= the meteor
## THE METEOR OF THE STORY (INTRO_SPEC 2), and it must read GIANT (lead ruling, 2026-10-18 critic):
## round 2 used the finale rock's own size (9.85 m x 1.14 squash = 11 m, smaller than home) in lilac
## knit, and among the neighbour worlds it read as one more medium rock - a cushion at the graze.
## So: the finale rock's recipe (CrashAsteroid's lumpy potato: a squashed faceted body, a sunk
## shoulder lobe, a knuckle, pressed-in craters) built at METEOR_RADIUS (~2.5x home's 16 m), with
## finer facets so its edge reads as a curved limb when it fills the window, in a dark cool
## grey-brown with a lit rim instead of lilac, and the game's own small stitch (yarn_scale 1.0 -
## 5.6 cm stitches on a 40 m body), so stitch density says "huge" the way it does on the planets.
const METEOR_RADIUS := 36.0
const METEOR_BODY := Color("#82786d")
const METEOR_LIGHT := Color("#9a8e80")
const METEOR_DARK := Color("#544d47")
## The visual layer its rim light lights (CrashAsteroid.FILL_LAYER: nothing else in the cockpit is on
## it, and the crash's own fill does not exist until after the cut).
const METEOR_RIM_LAYER := CrashAsteroid.FILL_LAYER
const METEOR_YARN_SCALE := 1.0

static func meteor() -> Node3D:
	var root := Node3D.new()
	root.name = "Meteor"
	var r := METEOR_RADIUS
	var sq := CrashAsteroid.SQUASH
	var kit := PlanetMeshKit.new()
	kit.faceted_blob(Vector3.ZERO, r, METEOR_BODY, sq, 4, 0.07, 3.7)
	kit.faceted_blob(Vector3(0.40, -0.16, 0.20) * r / 0.72, r * 0.50, METEOR_BODY.lerp(METEOR_DARK, 0.35),
		Vector3(1.0, 0.82, 0.92), 3, 0.08, 9.1)
	kit.faceted_blob(Vector3(-0.34, 0.20, -0.26) * r / 0.72, r * 0.38, METEOR_LIGHT, Vector3.ONE, 3, 0.08, 17.3)
	var craters := [
		[Vector3(-0.18, 0.78, 0.60), 0.20], [Vector3(0.66, 0.40, -0.52), 0.15], [Vector3(0.30, 0.10, 0.95), 0.17],
		[Vector3(-0.70, -0.20, 0.55), 0.12], [Vector3(0.10, -0.60, -0.75), 0.14],
	]
	for c: Array in craters:
		var d: Vector3 = (c[0] as Vector3).normalized()
		var cr: float = float(c[1]) * r
		var p := d * r * sq * 0.94
		var bs := CrashAsteroid.axis_basis(d)
		kit.lathe(PackedVector2Array([Vector2(0.0, -cr * 0.35), Vector2(cr * 0.66, -cr * 0.20),
			Vector2(cr, 0.05)]), 16, Transform3D(bs, p), METEOR_DARK)
		kit.lathe(PackedVector2Array([Vector2(cr, 0.05), Vector2(cr * 1.22, 0.10),
			Vector2(cr * 1.30, 0.0)]), 16, Transform3D(bs, p), METEOR_LIGHT)
	var mi := MeshInstance3D.new()
	mi.name = "Rock"
	mi.mesh = kit.commit()
	# A strong rim (toon rim_strength, sun-side only) so the dark body has a lit edge against space.
	mi.material_override = MaterialLib.toon_vertex_color({"rim": 0.7, "spec": 0.04, "spec_size": 120.0,
		"roughness": 0.95, "surface": "rock", "surface_strength": 3.2, "surface_near": 8.0, "surface_far": 80.0,
		"yarn_scale": METEOR_YARN_SCALE})
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.layers = 1 | (1 << (METEOR_RIM_LAYER - 1))
	root.add_child(mi)
	# A cool-white light from above and a little behind it, on its own layer: a bright crescent along
	# its top limb, so the dark body has a lit edge against space (and reads round, like a planet).
	var rim := DirectionalLight3D.new()
	rim.name = "RimLight"
	rim.light_cull_mask = 1 << (METEOR_RIM_LAYER - 1)
	rim.light_color = Color("#e8eef8")
	rim.light_energy = 1.4
	rim.light_specular = 0.0
	rim.shadow_enabled = false
	root.add_child(rim)
	return root


## Nominal radius (the squashed body's widest axis); its lumps reach ~1.1x this.
static func meteor_radius() -> float:
	return METEOR_RADIUS * CrashAsteroid.SQUASH.x


## The graze's sparks: warm orange STREAKS (thin glowing capsules stretched along their own
## velocity), not round glints - round ones read as stars against space (critic).
static func spark_streaks() -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.name = "SparkStreaks"
	p.amount = 40
	p.lifetime = 0.7
	p.one_shot = true
	p.explosiveness = 0.85
	p.local_coords = false
	p.emitting = false
	p.visibility_aabb = AABB(Vector3(-12.0, -12.0, -12.0), Vector3(24.0, 24.0, 24.0))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.3
	pm.direction = Vector3(-1.0, 0.15, 0.35)
	pm.spread = 22.0
	pm.initial_velocity_min = 9.0
	pm.initial_velocity_max = 18.0
	pm.gravity = Vector3.ZERO
	pm.damping_min = 2.0
	pm.damping_max = 4.0
	pm.particle_flag_align_y = true
	pm.scale_min = 0.7
	pm.scale_max = 1.3
	var shrink := Curve.new()
	shrink.add_point(Vector2(0.0, 1.0))
	shrink.add_point(Vector2(0.7, 0.8))
	shrink.add_point(Vector2(1.0, 0.0))
	var st := CurveTexture.new()
	st.curve = shrink
	pm.scale_curve = st
	p.process_material = pm
	var cap := CapsuleMesh.new()
	cap.radius = 0.012
	cap.height = 0.5
	cap.radial_segments = 6
	cap.rings = 1
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(1.0, 0.52, 0.18, 0.85)
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.disable_receive_shadows = true
	cap.material = m
	p.draw_pass_1 = cap
	return p
