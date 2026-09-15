class_name SkiffMeshLib
extends RefCounted
## Meshes for the skiff, the small ship the friends build in the finale (docs/PHASE5_SPEC.md §4
## "Skiff"). RocketModel owns the nodes, materials and API; this file only makes geometry.
##
## The shape, bottom to top: three splayed knee-jointed legs on round pads (within Ø2.4 m), a flat
## chamfered cream base ring, a ten-sided slate barrel (Ø1.7 m at the corners) with panel lines, a
## chamfered cream collar, and a low eight-sided navy canopy with one crisp streak. An upright squat
## lander, 2.3 m to the top of the antenna bulb: not the rocket, not a bubble, not a saucer, no nose
## cone, fins or wings. STYLE_GUIDE "Shape language corrections": flat base, tiered silhouette,
## crisp facet edges and chamfers, never a soap bubble - so every surface here is flat-shaded.
##
## The friends' five pieces: Bolt's gold hatch plate (door), Zorp's antenna with a muted aqua bulb
## (bulb), Fen's hooded lamp over the hatch (lamp_lens + the hood in the trim), Grig's chalk ladder with
## eleven numbered rungs (ladder + ladder_digits), Vela's dish on the right shoulder (in cream).
##
## Conventions (the rocket's, so the pad and the flight code need no special case): origin at the
## ground contact point, +Y up (thrust), the hatch on -Z. Angles are "degrees from -Z toward +X", the
## RocketModel curved_panel convention. Winding is Godot's clockwise front face; every triangle goes
## through Soup.tri, which orients it to an outward hint so no caller has to think about winding.
##
## Ground fit: the legs and the ladder take the ground as a height field (a Callable, see
## sphere_ground). The pad's deck is not flat - it follows the planet (rocket_pad.gd `_deck_y`) - so a
## flat foot at 0.97 m would float 5 cm on Grig's 9.5 m world. RocketModel samples the pad's real
## Deck mesh when it stands on one and falls back to the ideal sphere cap otherwise.

const HEIGHT := 2.30
## Barrel: ten facets, the corners on Ø1.7 m.
const SIDES := 10
const DRUM_R := 0.85
const APOTHEM := DRUM_R * cos(PI / SIDES)
const BASE_Y0 := 0.60
const DRUM_Y0 := 0.74
const DRUM_Y1 := 1.56
const COLLAR_Y1 := 1.72
## Canopy: its height is 0.35 m, 0.21 of the drum width (the spec caps the dome at 0.35 x).
const CANOPY_SIDES := 8
const CANOPY_R := 0.60
const CANOPY_Y0 := 1.715
const CANOPY_TOP := 2.065
## Hatch opening on the -Z facet (the door plate is a little bigger than the hole).
const HATCH_Y0 := 0.78
const HATCH_Y1 := 1.40
const HATCH_HALF_W := 0.20
const DOOR_HALF_W := 0.215
const DOOR_PROUD := 0.014
const WELL_DEPTH := 0.12
const NOZZLE_MOUTH_Y := 0.38
## Legs: one astern and two at +/-60 deg from the hatch, so the ladder hangs between the front pair.
## Each leaves the barrel's side (hip), splays out and down to a knee, then drops to its pad.
const LEG_ANGLES_DEG: Array[float] = [60.0, 180.0, 300.0]
const HIP_R := 0.84
const HIP_Y := 0.98
const KNEE_R := 1.06
const KNEE_Y := 0.70
const KNEE_BALL_R := 0.072
const FOOT_R := 0.97
const PAD_R := 0.17
const PAD_H := 0.065
const ANKLE_UP := 0.055
const UPPER_LEG_R := 0.040
const LOWER_LEG_R := 0.050
## Fen's lamp, centred over the hatch.
const LAMP_Y := 1.475
## Zorp's antenna (rear left) and Vela's dish (right shoulder).
const ANTENNA_DEG := 140.0
const ANTENNA_BASE_R := 0.68
const BULB_R := 0.075
const BULB_Y := HEIGHT - BULB_R
const DISH_DEG := -100.0
const DISH_TILT_DEG := 42.0
## Grig's ladder: eleven rungs, numbered 1 (bottom) to 11 on the viewer's-left rail.
const RUNGS := 11
const LADDER_HALF_W := 0.16
const LADDER_TOP_Y := 0.76
const LADDER_FOOT_R := 1.02
const RAIL_HALF := Vector2(0.026, 0.014)
const DIGIT_H := 0.034
const DIGIT_W := 0.016
const DIGIT_T := 0.0055
const DIGIT_GAP := 0.005


## Unindexed triangle soup with flat normals.
class Soup:
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()

	## One flat triangle, wound so its front face points along `hint`. Zero-area triangles are dropped.
	func tri(a: Vector3, b: Vector3, c: Vector3, hint: Vector3) -> void:
		var fn := (c - a).cross(b - a)
		if fn.length_squared() < 1e-14:
			return
		if fn.dot(hint) < 0.0:
			var t := b
			b = c
			c = t
			fn = -fn
		fn = fn.normalized()
		verts.append(a)
		verts.append(b)
		verts.append(c)
		norms.append(fn)
		norms.append(fn)
		norms.append(fn)

	func quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, hint: Vector3) -> void:
		tri(a, b, c, hint)
		tri(a, c, d, hint)

	func commit() -> ArrayMesh:
		return RocketMeshLib.commit_raw(verts, norms)


## A point at radius r, angle theta (from -Z toward +X), height y.
static func polar(r: float, theta: float, y: float) -> Vector3:
	return Vector3(r * sin(theta), y, -r * cos(theta))


static func sag(r: float, ground_r: float) -> float:
	if is_inf(ground_r) or ground_r <= r:
		return 0.0
	return RocketMeshLib.sag(r, ground_r)


## Flat-shaded surface of revolution with `sides` facets, facet k centred on `phase + k * step`.
## `profile` is (radius, y) from the bottom, outward, up and back in - the RocketMeshLib.lathe order,
## which is what makes the outward hint right. `skip` lists facets left open.
static func faceted_lathe(s: Soup, profile: PackedVector2Array, sides: int, phase: float = 0.0,
		xf: Transform3D = Transform3D.IDENTITY, cap_bottom: bool = false, skip: Array[int] = []) -> void:
	var step := TAU / float(sides)
	var n := profile.size()
	for i in n - 1:
		var p0 := profile[i]
		var p1 := profile[i + 1]
		var t := p1 - p0
		if t.length_squared() < 1e-12:
			continue
		var n2 := Vector2(t.y, -t.x)
		for k in sides:
			if skip.has(k):
				continue
			var a0 := phase + (float(k) - 0.5) * step
			var a1 := a0 + step
			var mid := phase + float(k) * step
			var hint := xf.basis * (Vector3(sin(mid), 0.0, -cos(mid)) * n2.x + Vector3.UP * n2.y)
			s.quad(xf * polar(p0.x, a0, p0.y), xf * polar(p0.x, a1, p0.y), xf * polar(p1.x, a1, p1.y),
				xf * polar(p1.x, a0, p1.y), hint)
	if cap_bottom and profile[0].x > 0.0:
		var c := xf * Vector3(0.0, profile[0].y, 0.0)
		for k in sides:
			var a0 := phase + (float(k) - 0.5) * step
			s.tri(c, xf * polar(profile[0].x, a0, profile[0].y), xf * polar(profile[0].x, a0 + step, profile[0].y),
				xf.basis * Vector3.DOWN)


## A basis whose +Y is `up` (normalised), with X kept as close to `hint_x` as it can be.
static func basis_up(up: Vector3, hint_x: Vector3 = Vector3.RIGHT) -> Basis:
	var y := up.normalized()
	var x := hint_x - y * hint_x.dot(y)
	if x.length_squared() < 1e-6:
		x = Vector3.FORWARD - y * Vector3.FORWARD.dot(y)
	x = x.normalized()
	var z := x.cross(y)
	return Basis(x, y, z)


## A straight faceted rod from `a` to `b`, flat ends.
static func rod(s: Soup, a: Vector3, b: Vector3, r: float, sides: int = 6) -> void:
	var axis := b - a
	var length_m := axis.length()
	if length_m < 1e-5:
		return
	var xf := Transform3D(basis_up(axis), a)
	faceted_lathe(s, PackedVector2Array([Vector2(0.0, 0.0), Vector2(r, 0.0), Vector2(r, length_m), Vector2(0.0, length_m)]),
		sides, 0.0, xf)


## A box: `xf` places its centre and axes, `half` is the half extents.
static func box(s: Soup, xf: Transform3D, half: Vector3) -> void:
	var c: Array[Vector3] = []
	for i in 8:
		c.append(xf * Vector3(half.x * (1.0 if i & 1 else -1.0), half.y * (1.0 if i & 2 else -1.0),
			half.z * (1.0 if i & 4 else -1.0)))
	var b := xf.basis
	s.quad(c[1], c[3], c[7], c[5], b.x)
	s.quad(c[0], c[4], c[6], c[2], -b.x)
	s.quad(c[2], c[6], c[7], c[3], b.y)
	s.quad(c[0], c[1], c[5], c[4], -b.y)
	s.quad(c[4], c[5], c[7], c[6], b.z)
	s.quad(c[0], c[2], c[3], c[1], -b.z)


## A low-poly faceted ball.
static func ball(s: Soup, centre: Vector3, r: float, sides: int = 6) -> void:
	var prof := PackedVector2Array()
	for i in 5:
		var a := -PI * 0.5 + PI * float(i) / 4.0
		prof.append(Vector2(r * cos(a), r * sin(a)))
	faceted_lathe(s, prof, sides, 0.0, Transform3D(Basis.IDENTITY, centre))


## Appends an ArrayMesh's triangles, moved by `xf`.
static func append_mesh(s: Soup, mesh: ArrayMesh, xf: Transform3D) -> void:
	for si in mesh.get_surface_count():
		var arr := mesh.surface_get_arrays(si)
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var nn: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
		var idx: Variant = arr[Mesh.ARRAY_INDEX]
		var order := PackedInt32Array()
		if idx is PackedInt32Array and (idx as PackedInt32Array).size() > 0:
			order = idx
		else:
			for i in v.size():
				order.append(i)
		for t in range(0, order.size() - 2, 3):
			var hint := xf.basis * (nn[order[t]] + nn[order[t + 1]] + nn[order[t + 2]])
			s.tri(xf * v[order[t]], xf * v[order[t + 1]], xf * v[order[t + 2]], hint)


# ============================================================================= parts
## The slate barrel: ten flat facets, the -Z facet framing the hatch hole.
static func barrel() -> ArrayMesh:
	var s := Soup.new()
	var prof := PackedVector2Array([Vector2(DRUM_R, DRUM_Y0), Vector2(DRUM_R, DRUM_Y1)])
	faceted_lathe(s, prof, SIDES, 0.0, Transform3D.IDENTITY, false, [0])
	var ex := DRUM_R * sin(PI / SIDES)
	var z := -APOTHEM
	var f := Vector3.FORWARD
	s.quad(Vector3(-ex, DRUM_Y0, z), Vector3(-HATCH_HALF_W, DRUM_Y0, z), Vector3(-HATCH_HALF_W, DRUM_Y1, z),
		Vector3(-ex, DRUM_Y1, z), f)
	s.quad(Vector3(HATCH_HALF_W, DRUM_Y0, z), Vector3(ex, DRUM_Y0, z), Vector3(ex, DRUM_Y1, z),
		Vector3(HATCH_HALF_W, DRUM_Y1, z), f)
	s.quad(Vector3(-HATCH_HALF_W, DRUM_Y0, z), Vector3(HATCH_HALF_W, DRUM_Y0, z),
		Vector3(HATCH_HALF_W, HATCH_Y0, z), Vector3(-HATCH_HALF_W, HATCH_Y0, z), f)
	s.quad(Vector3(-HATCH_HALF_W, HATCH_Y1, z), Vector3(HATCH_HALF_W, HATCH_Y1, z),
		Vector3(HATCH_HALF_W, DRUM_Y1, z), Vector3(-HATCH_HALF_W, DRUM_Y1, z), f)
	return s.commit()


## Everything cream: the chamfered base ring, the collar, the three knee joints and Vela's dish.
static func cream_parts() -> ArrayMesh:
	var s := Soup.new()
	faceted_lathe(s, PackedVector2Array([
		Vector2(0.46, BASE_Y0), Vector2(0.81, BASE_Y0), Vector2(0.87, BASE_Y0 + 0.045),
		Vector2(0.87, DRUM_Y0 - 0.035), Vector2(DRUM_R - 0.005, DRUM_Y0 + 0.004),
	]), SIDES, 0.0, Transform3D.IDENTITY, true)
	faceted_lathe(s, PackedVector2Array([
		Vector2(DRUM_R + 0.012, DRUM_Y1 - 0.01), Vector2(DRUM_R + 0.012, DRUM_Y1 + 0.04),
		Vector2(0.73, COLLAR_Y1 - 0.02), Vector2(0.62, COLLAR_Y1), Vector2(0.0, COLLAR_Y1),
	]), SIDES)
	for deg in LEG_ANGLES_DEG:
		ball(s, polar(KNEE_R, deg_to_rad(deg), KNEE_Y), KNEE_BALL_R, 6)
	_dish_bowl(s)
	return s.commit()


static func _lamp_hood(s: Soup) -> void:
	# A thick half-round hood over the lens, sticking out of the front facet.
	var c := Vector3(0.0, LAMP_Y, -APOTHEM)
	var r_in := 0.078
	var r_out := 0.094
	var depth := 0.14
	var segs := 5
	for i in segs:
		var a0 := PI * float(i) / float(segs)
		var a1 := PI * float(i + 1) / float(segs)
		var o0 := Vector3(cos(a0), sin(a0), 0.0)
		var o1 := Vector3(cos(a1), sin(a1), 0.0)
		var back := c
		var front := c + Vector3(0.0, 0.0, -depth)
		var mid_dir := (o0 + o1).normalized()
		s.quad(back + o0 * r_out, back + o1 * r_out, front + o1 * r_out, front + o0 * r_out, mid_dir)
		s.quad(back + o0 * r_in, back + o1 * r_in, front + o1 * r_in, front + o0 * r_in, -mid_dir)
		s.quad(front + o0 * r_in, front + o1 * r_in, front + o1 * r_out, front + o0 * r_out, Vector3.FORWARD)
	for side: float in [1.0, -1.0]:
		var o := Vector3(side, 0.0, 0.0)
		s.quad(c + o * r_in, c + o * r_out, c + o * r_out + Vector3(0.0, 0.0, -depth),
			c + o * r_in + Vector3(0.0, 0.0, -depth), Vector3.DOWN)


static func _dish_frame() -> Transform3D:
	var th := deg_to_rad(DISH_DEG)
	var out := Vector3(sin(th), 0.0, -cos(th))
	var up := (Vector3.UP * cos(deg_to_rad(DISH_TILT_DEG)) + out * sin(deg_to_rad(DISH_TILT_DEG)))
	return Transform3D(basis_up(up, Vector3(cos(th), 0.0, sin(th))), polar(0.80, th, 1.80))


static func _dish_bowl(s: Soup) -> void:
	faceted_lathe(s, PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.10, 0.018), Vector2(0.19, 0.068), Vector2(0.205, 0.086),
		Vector2(0.175, 0.080), Vector2(0.085, 0.042), Vector2(0.0, 0.030),
	]), 10, 0.0, _dish_frame())


## The dark near-neutral trim: panel lines, the hatch well, the engine bell, Fen's lamp hood and body,
## Zorp's antenna mast and base, Vela's dish post and feed.
static func dark_trim() -> ArrayMesh:
	var s := Soup.new()
	var step := TAU / float(SIDES)
	var lift := 0.004
	for k in SIDES:
		var mid := float(k) * step
		var a0 := mid - 0.5 * step
		var a1 := mid + 0.5 * step
		var n := Vector3(sin(mid), 0.0, -cos(mid))
		var bands: Array[Vector2] = [Vector2(1.13, 1.152), Vector2(1.47, 1.49)]
		if k == 0:
			bands = []
		for band in bands:
			s.quad(polar(DRUM_R, a0, band.x) + n * lift, polar(DRUM_R, a1, band.x) + n * lift,
				polar(DRUM_R, a1, band.y) + n * lift, polar(DRUM_R, a0, band.y) + n * lift, n)
		if k % 2 == 1 and k != 0:
			var t := Vector3(cos(mid), 0.0, sin(mid))
			var c0 := n * (APOTHEM + lift)
			s.quad(c0 + t * 0.011 + Vector3.UP * DRUM_Y0, c0 - t * 0.011 + Vector3.UP * DRUM_Y0,
				c0 - t * 0.011 + Vector3.UP * 1.13, c0 + t * 0.011 + Vector3.UP * 1.13, n)
	# Hatch well: a dark recess behind the door.
	var z0 := -APOTHEM
	var z1 := -APOTHEM + WELL_DEPTH
	var hw := HATCH_HALF_W
	s.quad(Vector3(-hw, HATCH_Y0, z1), Vector3(hw, HATCH_Y0, z1), Vector3(hw, HATCH_Y1, z1),
		Vector3(-hw, HATCH_Y1, z1), Vector3.FORWARD)
	s.quad(Vector3(-hw, HATCH_Y0, z0), Vector3(-hw, HATCH_Y0, z1), Vector3(-hw, HATCH_Y1, z1),
		Vector3(-hw, HATCH_Y1, z0), Vector3.RIGHT)
	s.quad(Vector3(hw, HATCH_Y0, z0), Vector3(hw, HATCH_Y0, z1), Vector3(hw, HATCH_Y1, z1),
		Vector3(hw, HATCH_Y1, z0), Vector3.LEFT)
	s.quad(Vector3(-hw, HATCH_Y0, z0), Vector3(hw, HATCH_Y0, z0), Vector3(hw, HATCH_Y0, z1),
		Vector3(-hw, HATCH_Y0, z1), Vector3.UP)
	s.quad(Vector3(-hw, HATCH_Y1, z0), Vector3(hw, HATCH_Y1, z0), Vector3(hw, HATCH_Y1, z1),
		Vector3(-hw, HATCH_Y1, z1), Vector3.DOWN)
	# Engine bell under the base ring: stubby, flared, open at the mouth.
	faceted_lathe(s, PackedVector2Array([
		Vector2(0.30, NOZZLE_MOUTH_Y - 0.012), Vector2(0.31, NOZZLE_MOUTH_Y), Vector2(0.26, NOZZLE_MOUTH_Y + 0.09),
		Vector2(0.21, NOZZLE_MOUTH_Y + 0.16), Vector2(0.20, BASE_Y0 + 0.001),
	]), 10)
	# Fen's lamp: hood and body.
	_lamp_hood(s)
	box(s, Transform3D(Basis.IDENTITY, Vector3(0.0, LAMP_Y - 0.005, -APOTHEM - 0.035)), Vector3(0.07, 0.07, 0.035))
	# Antenna base boss and mast.
	var th := deg_to_rad(ANTENNA_DEG)
	var base := polar(ANTENNA_BASE_R, th, COLLAR_Y1 - 0.035)
	faceted_lathe(s, PackedVector2Array([Vector2(0.055, 0.0), Vector2(0.05, 0.05), Vector2(0.03, 0.065),
		Vector2(0.0, 0.065)]), 6, 0.0, Transform3D(Basis.IDENTITY, base))
	rod(s, base + Vector3.UP * 0.06, Vector3(base.x, BULB_Y - BULB_R * 0.6, base.z), 0.017, 5)
	faceted_lathe(s, PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.03, 0.0), Vector2(0.03, 0.03),
		Vector2(0.0, 0.03)]), 6, 0.0, Transform3D(Basis.IDENTITY, Vector3(base.x, BULB_Y - BULB_R - 0.02, base.z)))
	# Dish post and feed.
	var dish := _dish_frame()
	var dt := deg_to_rad(DISH_DEG)
	rod(s, polar(0.70, dt, COLLAR_Y1 - 0.06), dish.origin + dish.basis.y * 0.01, 0.022, 5)
	rod(s, dish.origin + dish.basis.y * 0.03, dish.origin + dish.basis.y * 0.17, 0.010, 4)
	ball(s, dish.origin + dish.basis.y * 0.18, 0.024, 5)
	return s.commit()


## The navy canopy: eight facets, low.
static func canopy() -> ArrayMesh:
	var s := Soup.new()
	faceted_lathe(s, _canopy_profile(), CANOPY_SIDES)
	return s.commit()


static func _canopy_profile() -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(CANOPY_R, CANOPY_Y0), Vector2(CANOPY_R, 1.77), Vector2(0.52, 1.905),
		Vector2(0.34, 2.015), Vector2(0.0, CANOPY_TOP),
	])


## The canopy's one crisp streak: a tapering strip on the facet upper-left of the hatch as you face
## it (+X is the viewer's left), lying just proud of the navy.
static func streak() -> ArrayMesh:
	var s := Soup.new()
	var prof := _canopy_profile()
	var th := deg_to_rad(45.0)
	var cosf := cos(PI / CANOPY_SIDES)
	var dir := Vector3(sin(th), 0.0, -cos(th))
	var side_t := Vector3(cos(th), 0.0, sin(th))
	var widths: Array[float] = [0.045, 0.085, 0.030]
	var shift: Array[float] = [-0.05, -0.02, 0.03]
	var rows: Array[Vector3] = []
	var rows_n: Array[Vector3] = []
	var ks: Array[float] = []
	# Points along profile segments 1->2->3, a quarter of the way into the first and out of the last.
	var p1 := prof[1].lerp(prof[2], 0.25)
	var p3 := prof[2].lerp(prof[3], 0.80)
	var pts: Array[Vector2] = [p1, prof[2], p3]
	for j in 3:
		var seg_a := prof[1] if j < 2 else prof[2]
		var seg_b := prof[2] if j < 2 else prof[3]
		var t := seg_b - seg_a
		var n := (dir * t.y + Vector3.UP * -t.x).normalized()
		rows.append(dir * (pts[j].x * cosf) + Vector3.UP * pts[j].y + n * 0.006 + side_t * shift[j])
		rows_n.append(n)
		ks.append(widths[j])
	for j in 2:
		var hint := (rows_n[j] + rows_n[j + 1]).normalized()
		s.quad(rows[j] - side_t * ks[j] * 0.5, rows[j] + side_t * ks[j] * 0.5,
			rows[j + 1] + side_t * ks[j + 1] * 0.5, rows[j + 1] - side_t * ks[j + 1] * 0.5, hint)
	return s.commit()


## The three legs with their round pads, standing on `ground` (see sphere_ground / RocketModel).
static func legs(ground: Callable) -> ArrayMesh:
	var s := Soup.new()
	for deg in LEG_ANGLES_DEG:
		var th := deg_to_rad(deg)
		var hip := polar(HIP_R, th, HIP_Y)
		var knee := polar(KNEE_R, th, KNEE_Y)
		var pad := foot_frame(th, ground)
		var ankle := pad.origin + pad.basis.y * ANKLE_UP
		rod(s, hip, knee, UPPER_LEG_R, 6)
		rod(s, knee, ankle, LOWER_LEG_R, 6)
		# A sleeve on the lower leg: the shock absorber, so the leg reads as built.
		rod(s, knee.lerp(ankle, 0.22), knee.lerp(ankle, 0.52), LOWER_LEG_R + 0.016, 6)
		faceted_lathe(s, PackedVector2Array([
			Vector2(PAD_R, 0.0), Vector2(PAD_R, 0.028), Vector2(PAD_R - 0.045, PAD_H - 0.008),
			Vector2(0.05, PAD_H), Vector2(0.0, PAD_H),
		]), 8, 0.0, pad, true)
	return s.commit()


## Ground as a height field: a Callable (x: float, z: float) -> float, the ground's model-space height
## under that point. This one is the pad deck's ideal sphere cap, centre `ground_r` below the origin
## (INF = flat).
static func sphere_ground(ground_r: float) -> Callable:
	return func(x: float, z: float) -> float: return -sag(Vector2(x, z).length(), ground_r)


## Model-space frame of the pad for the leg at `theta`: origin at the centre of its flat underside,
## +Y the normal of the plane through the ground under its rim (four samples, one pad radius out
## along the leg and across it), so the whole underside lies on the ground, not just its centre.
static func foot_frame(theta: float, ground: Callable) -> Transform3D:
	var c := polar(FOOT_R, theta, 0.0)
	var radial := Vector3(sin(theta), 0.0, -cos(theta)) * PAD_R
	var across := Vector3(cos(theta), 0.0, sin(theta)) * PAD_R
	var pts: Array[Vector3] = []
	for off: Vector3 in [radial, -radial, across, -across]:
		var q := c + off
		pts.append(Vector3(q.x, float(ground.call(q.x, q.z)), q.z))
	var n := (pts[0] - pts[1]).cross(pts[2] - pts[3])
	if n.y < 0.0:
		n = -n
	var centre_y := (pts[0].y + pts[1].y + pts[2].y + pts[3].y) * 0.25
	return Transform3D(basis_up(n, across), Vector3(c.x, centre_y, c.z))


## Model-space centre of the pad's flat underside for the leg at `theta`.
static func foot_contact(theta: float, ground: Callable) -> Vector3:
	return foot_frame(theta, ground).origin


## Grig's chalk ladder: two rails and eleven rungs from the sill down to the deck.
static func ladder(ground: Callable) -> ArrayMesh:
	var s := Soup.new()
	var fr := _ladder_frame(ground)
	var top: Vector3 = fr["top"]
	var bottom: Vector3 = fr["bottom"]
	var along: Vector3 = fr["along"]
	var outward: Vector3 = fr["out"]
	var length_m := (top - bottom).length()
	for side: float in [-1.0, 1.0]:
		var c := (top + bottom) * 0.5 + Vector3.RIGHT * side * LADDER_HALF_W + along * 0.02
		box(s, Transform3D(Basis(Vector3.RIGHT, along, -outward), c), Vector3(RAIL_HALF.x, length_m * 0.5 + 0.02, RAIL_HALF.y))
	for i in RUNGS:
		var p := bottom.lerp(top, _rung_t(i))
		box(s, Transform3D(Basis(Vector3.RIGHT, along, -outward), p), Vector3(LADDER_HALF_W, 0.011, 0.011))
	return s.commit()


## The rung numbers, 1 at the bottom, drawn as seven-segment digits in dark chalk on the front of
## the rail on the viewer's left (+X), just above each rung.
static func ladder_digits(ground: Callable) -> ArrayMesh:
	var s := Soup.new()
	var fr := _ladder_frame(ground)
	var top: Vector3 = fr["top"]
	var bottom: Vector3 = fr["bottom"]
	var along: Vector3 = fr["along"]
	var outward: Vector3 = fr["out"]
	var spacing := _rung_t(1) - _rung_t(0)
	for i in RUNGS:
		var p := bottom.lerp(top, _rung_t(i) + spacing * 0.5) + Vector3.RIGHT * LADDER_HALF_W \
			+ outward * (RAIL_HALF.y + 0.002) - along * DIGIT_H * 0.5
		# Seen from the hatch side the viewer's right is -X.
		number(s, i + 1, p, Vector3.LEFT, along, outward)
	return s.commit()


static func _rung_t(i: int) -> float:
	return 0.075 + 0.85 * float(i) / float(RUNGS - 1)


static func _ladder_frame(ground: Callable) -> Dictionary:
	var top := Vector3(0.0, LADDER_TOP_Y, -APOTHEM - 0.03)
	# The rails' feet stand on the ground at x = +/-LADDER_HALF_W (the ground is symmetric there).
	var bottom := Vector3(0.0, float(ground.call(LADDER_HALF_W, -LADDER_FOOT_R)) + RAIL_HALF.y, -LADDER_FOOT_R)
	var along := (top - bottom).normalized()
	var outward := along.cross(Vector3.RIGHT).normalized()
	if outward.z > 0.0:
		outward = -outward
	return {"top": top, "bottom": bottom, "along": along, "out": outward}


## Draws `value` centred on `bottom_centre`, digits DIGIT_H tall, facing `normal`.
static func number(s: Soup, value: int, bottom_centre: Vector3, right: Vector3, up: Vector3, normal: Vector3) -> void:
	var text := str(value)
	var total := float(text.length()) * DIGIT_W + float(text.length() - 1) * DIGIT_GAP
	for i in text.length():
		var x0 := -total * 0.5 + float(i) * (DIGIT_W + DIGIT_GAP)
		digit(s, int(text[i]), bottom_centre + right * x0, right, up, normal)


## Seven-segment segments per digit: a top, b upper right, c lower right, d bottom, e lower left,
## f upper left, g middle.
const _SEGMENTS: Array[String] = ["abcdef", "bc", "abged", "abgcd", "fgbc", "afgcd", "afgedc", "abc",
	"abcdefg", "abcdfg"]


static func digit(s: Soup, d: int, origin: Vector3, right: Vector3, up: Vector3, normal: Vector3) -> void:
	var w := DIGIT_W
	var h := DIGIT_H
	var t := DIGIT_T
	var rects := {
		"a": Rect2(0.0, h - t, w, t), "d": Rect2(0.0, 0.0, w, t), "g": Rect2(0.0, h * 0.5 - t * 0.5, w, t),
		"f": Rect2(0.0, h * 0.5, t, h * 0.5), "b": Rect2(w - t, h * 0.5, t, h * 0.5),
		"e": Rect2(0.0, 0.0, t, h * 0.5), "c": Rect2(w - t, 0.0, t, h * 0.5),
	}
	for ch in _SEGMENTS[clampi(d, 0, 9)]:
		var r: Rect2 = rects[ch]
		var p := func(u: float, v: float) -> Vector3: return origin + right * u + up * v
		s.quad(p.call(r.position.x, r.position.y), p.call(r.end.x, r.position.y), p.call(r.end.x, r.end.y),
			p.call(r.position.x, r.end.y), normal)


## Bolt's gold hatch plate, in the hatch pivot's frame (vertices already moved by -hinge): a chamfered
## plate, four bolt heads and a bar handle.
static func door(hinge: Vector3) -> ArrayMesh:
	var s := Soup.new()
	var off := Transform3D(Basis.IDENTITY, -hinge)
	var plate := RocketMeshLib.prism(RocketMeshLib.rounded_rect(DOOR_HALF_W * 2.0, HATCH_Y1 - HATCH_Y0 + 0.03, 0.05, 2),
		0.012, 0.010)
	var yc := (HATCH_Y0 + HATCH_Y1) * 0.5
	append_mesh(s, plate, off * Transform3D(Basis.IDENTITY, Vector3(0.0, yc, -APOTHEM - DOOR_PROUD)))
	for bx: float in [-1.0, 1.0]:
		for by: float in [-1.0, 1.0]:
			box(s, off * Transform3D(Basis.IDENTITY, Vector3(bx * (DOOR_HALF_W - 0.045), yc + by * 0.25,
				-APOTHEM - DOOR_PROUD - 0.016)), Vector3(0.012, 0.012, 0.005))
	var hx := -DOOR_HALF_W + 0.07
	box(s, off * Transform3D(Basis.IDENTITY, Vector3(hx, yc, -APOTHEM - DOOR_PROUD - 0.04)), Vector3(0.013, 0.075, 0.010))
	for hy: float in [-1.0, 1.0]:
		box(s, off * Transform3D(Basis.IDENTITY, Vector3(hx, yc + hy * 0.06, -APOTHEM - DOOR_PROUD - 0.024)),
			Vector3(0.010, 0.010, 0.014))
	return s.commit()


## Door hinge, on the +X edge of the hatch facet (the rocket's side).
static func hatch_hinge() -> Vector3:
	return Vector3(DOOR_HALF_W, 0.0, -APOTHEM - DOOR_PROUD)


## Fen's lamp lens: a faceted disc facing -Z, tipped down.
static func lamp_lens() -> ArrayMesh:
	var s := Soup.new()
	var xf := Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-90.0 + 12.0)), Vector3(0.0, LAMP_Y - 0.004, -APOTHEM - 0.07))
	faceted_lathe(s, PackedVector2Array([Vector2(0.066, 0.0), Vector2(0.054, 0.014), Vector2(0.0, 0.020)]), 8, 0.0, xf)
	return s.commit()


static func lamp_light_pos() -> Vector3:
	return Vector3(0.0, LAMP_Y - 0.05, -APOTHEM - 0.40)


## Zorp's antenna bulb.
static func bulb() -> ArrayMesh:
	var s := Soup.new()
	var base := polar(ANTENNA_BASE_R, deg_to_rad(ANTENNA_DEG), 0.0)
	ball(s, Vector3(base.x, BULB_Y, base.z), BULB_R, 8)
	return s.commit()


static func bulb_pos() -> Vector3:
	var base := polar(ANTENNA_BASE_R, deg_to_rad(ANTENNA_DEG), 0.0)
	return Vector3(base.x, BULB_Y, base.z)


## The glowing throat inside the engine bell.
static func throat() -> ArrayMesh:
	var s := Soup.new()
	faceted_lathe(s, PackedVector2Array([Vector2(0.0, NOZZLE_MOUTH_Y + 0.03), Vector2(0.17, NOZZLE_MOUTH_Y + 0.04),
		Vector2(0.25, NOZZLE_MOUTH_Y + 0.07)]), 10)
	return s.commit()
