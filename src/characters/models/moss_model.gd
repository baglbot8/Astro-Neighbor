class_name MossModel
extends ChibiModel
## MOSS - the swamp-folk shopkeeper of The Tangle (docs/JUNGLE_PLANET_SPEC.md 3, builder J3).
##
## THE SILHOUETTE, which is the whole brief ("round and mossy, a reed or lily-pad hat, maybe a little
## lantern or a staff of reed"), in the order it reads at 8 m:
##   * A LILY-PAD HAT, much wider than the body (1.04 m across a 0.66 m cloak), with its notch and a
##     lilac water-lily on top. Nobody else in the cast wears a hat at all.
##   * A MOSS CLOAK: a bell that is widest at the HEM, with a ragged fringe of hanging moss tassels.
##     Every other biped is a bean (widest mid-body); Gloop is a dome with no legs. The bell plus the
##     hat make a "mushroom under an umbrella" outline nothing else has.
##   * A TALL REED STAFF, taller than Moss, with a cattail head and a glowing lantern hanging off a
##     crook. The only held prop in the cast, and the lantern is what finds Moss at night.
##   * Wide webbed frog feet peeking out under the hem.
##
## THE ALIEN PARTS (MOSS2, 2026-09-30 - the user: "Moss looks pretty plain features wise besides the
## outfit, can we update that a bit to make him more alien like?"). Three, all on the face, where the
## talk camera and the shop portrait look, and none of them a slot another character holds:
##   * A THIRD EYE, small and high in the middle of the forehead - the retired field photographer's
##     "eye for the rare shot". It is a real `_add_face` eye, so it blinks and smiles with the other two.
##     Nobody else in the cast has three eyes since Fen gave up his three stalks (CAST_VARIETY table).
##   * FRILLED GILLS: three scalloped rose fronds fanning out of each side of the head under the hat
##     brim, the axolotl look - they widen the head's outline at 8 m and sway slowly as he breathes.
##     Flat, double-sided fans (32 triangles each) instead of tubes, to stay inside the 6,000 budget.
##   * GLOWING FRECKLES: three soft pond-glow dots over each cheek, the same cool glow as his stall's
##     jars. Geometry, not a surface pattern, so "no surface at all" below still holds.
##
## CAST_VARIETY (docs/CAST_VARIETY.md) - what Moss takes and what it does not:
##   no eyestalks, no toothy grin, no `sd_skin` / `sd_scales` / `sd_foliage`, no lashes, and NONE of
##   the capped hard vocabulary (`brows` off, no lid, no horns, tusks, fangs or yoke). No surface
##   pattern at all. The closed mouth is a KIND nobody holds (ruling 6): a small "w" - two tiny bowls
##   meeting in the middle, the cat/frog mouth - not an arc, a bar, a slot, an under-bite or a strip.
##   Eyes: two plain dark ovals set WIDE and LOW on a wide face (yaw 21 against the cast's ~17), which
##   with the hat brim over them is the "peeking out" look. Manner: slow (anim 0.7), long blinks
##   (blink_hold 1.4), and a reed-like side-to-side sway instead of the cast's breathing bob.
##
## PALETTE (every swatch S <= 0.55, STYLE_GUIDE "no dominant swatch above S 0.60"):
##   skin teal-sage H 158 · cloak olive moss H 88 · hat leaf green H 116 · lily lilac H 325 · staff straw
##   H 42. Measured on a frame in the J3 report, not only here.

# ---------------------------------------------------------------------------------- the palette
## Face, hands and feet: a soft pond teal. S 0.24, V 0.70.
const SKIN := Color("#88b3a4")
const SKIN_DARK := Color("#6f9a8a")
## The moss cloak. S 0.30, V 0.58 as albedo. Round 1 was #6b8448 (S 0.46) and RENDERED at S 0.76 in
## the jungle's light (measured on a Compatibility talk frame). At S 0.30 the hat still rendered at S p90
## 0.65, so every green here is ~0.22 as albedo; the scene's light roughly doubles it.
const MOSS := Color("#839474")
const MOSS_DARK := Color("#6b7b5e")
const MOSS_LIGHT := Color("#95a883")
## The lily-pad hat: top, underside/rim, and the veins.
const PAD := Color("#7b9878")
const PAD_UNDER := Color("#627e61")
const PAD_VEIN := Color("#9ab596")
const PETAL := Color("#d9a6c4")
const PETAL_TIP := Color("#e8c4d6")
const LILY_HEART := Color("#e0bf62")
## The reed staff and the cattail.
const REED := Color("#b8a06a")
const REED_DARK := Color("#8f7a4f")
const CATTAIL := Color("#7a5a3c")
const CAGE := Color("#5b4e42")
const LANTERN := Color("#ffd489")
const EYE := Color("#1f2a26")
const MOUTH := Color("#2c3a33")
const MOUTH_INNER := Color("#7a4250")
const BLUSH := Color("#d49a95")
## The gills: a dusty rose, S 0.24 as albedo (the lily's family, so the hat and the gills belong together).
const GILL := Color("#d19db4")
const GILL_DEEP := Color("#b48aa0")
## The freckles: the stall jars' cool glow (moss_stall.gd GLOW_COOL).
const FRECKLE := Color("#b8ecd2")
## Gills per side: [pitch on the head (deg), elevation of the frond (deg), length (m)].
const GILLS := [[9.0, 22.0, 0.200], [-4.0, 0.0, 0.235], [-17.0, -24.0, 0.185]]
## Freckles per cheek: [yaw, pitch, radius].
const FRECKLES := [[33.0, -2.5, 0.0115], [38.5, -6.5, 0.0095], [34.0, -8.0, 0.0080]]

# ------------------------------------------------------------------------------- the body, metres
## The cloak's lathe profile (radius, y): widest at the hem, narrowing to the neck. Torso-local, feet
## at y 0 - the hem stops at 0.13 so the frog feet show under it.
static var CLOAK_PROFILE := PackedVector2Array([
	Vector2(0.000, 0.135),
	Vector2(0.270, 0.130),
	Vector2(0.330, 0.160),
	Vector2(0.338, 0.230),
	Vector2(0.318, 0.340),
	Vector2(0.280, 0.450),
	Vector2(0.232, 0.545),
	Vector2(0.170, 0.620),
	Vector2(0.080, 0.668),
	Vector2(0.000, 0.680),
])
const HAT_R := 0.58
## Where the staff stands, in root space (the right side, a little forward).
const STAFF_AT := Vector3(0.405, 0.0, -0.075)
const STAFF_H := 1.62
## Highest point of the head + hat at rest, for the "!" marker (Moss shows none, but the base asks).
const CROWN := 1.34

var _tassels: Array[Node3D] = []
var _hat: Node3D
var _hat_strands: Array[Node3D] = []
var _lantern: Node3D
var _lantern_vel: float = 0.0
var _lantern_ang: float = 0.0
var _w_mouth: Node3D
var _open_mouth: Node3D
var _gills: Array[Node3D] = []


func _init() -> void:
	super()
	# A wide, soft, slightly flattened head: a frog's, not a skull. n 2.2 is the softest in the cast
	# after Gloop's dome (2.3) and it sits on a cloak, not a puddle.
	head_semi = Vector3(0.335, 0.272, 0.300)
	head_n = 2.2
	head_y = 0.905
	head_segs = Vector2i(30, 16)
	anim_time_scale = 0.70
	blink_hold = 1.4
	eye_w = 0.043
	eye_h = 0.051
	eye_d = 0.019
	mouth_w = 0.050
	mouth_h = 0.040
	mouth_d = 0.012


func marker_clearance() -> float:
	return CROWN * body_scale


# ==================================================================================== geometry
func _build_geometry() -> void:
	var m_skin := _toon(SKIN, _matte({"rim": 0.05}))
	var m_skin_dark := _toon(SKIN_DARK, _matte({}))
	var m_moss := _toon(MOSS, _matte({"rim": 0.04}))
	var m_moss_dark := _toon(MOSS_DARK, _matte({}))
	var m_moss_light := _toon(MOSS_LIGHT, _matte({"rim": 0.05}))

	_build_feet(m_skin, m_skin_dark)
	# ---- the cloak bell
	_mi(DJFloatModel.lathe(CLOAK_PROFILE, 18), m_moss, _torso, Vector3.ZERO, "Cloak")
	_build_tassels(m_moss, m_moss_dark, m_moss_light)
	_build_clumps(m_moss_light, m_moss_dark)
	_build_ruff(m_moss_light, m_moss)
	# ---- the head (no crown seam: the hat covers the crown, and it would be 300 hidden triangles)
	_add_head_shell(SKIN, {"crown_seam": false, "rim": 0.05})
	_build_face()
	_build_gills()
	_build_freckles()
	_build_hat()
	# ---- arms: moss sleeves out of the cloak, teal mitts
	_build_arms(m_moss, m_skin)
	_build_staff()


## Wide webbed frog feet: a flat pad and three round toes at the front edge, on stub legs that are
## almost entirely hidden by the cloak.
func _build_feet(m_skin: Material, m_dark: Material) -> void:
	for leg: Node3D in [_leg_l, _leg_r]:
		var sx := -1.0 if leg == _leg_l else 1.0
		_mi(cylinder(0.048, 0.050, 0.14, 7), m_dark, leg, Vector3(0.0, -0.07, 0.0), "Leg")
		var foot := _node("Foot", leg, Vector3(0.018 * sx, -HIP_Y + 0.030, -0.030))
		foot.rotation.y = -0.22 * sx
		_mi(superellipsoid(Vector3(0.095, 0.030, 0.105), 2.6, 12, 7), m_skin, foot, Vector3.ZERO, "Pad")
		for k in 3:
			var a := deg_to_rad(-34.0 + 34.0 * float(k))
			_mi(superellipsoid(Vector3(0.030, 0.024, 0.032), 2.2, 8, 5), m_skin, foot,
				Vector3(sin(a) * 0.080, 0.004, -cos(a) * 0.098), "Toe")


## The ragged hem: thirteen moss tassels hanging from the lower cloak, leaning out a little so the
## outline is shaggy. Each is its own node so `_animate_extras` can sway them.
func _build_tassels(m_moss: Material, m_dark: Material, m_light: Material) -> void:
	var n := 12
	for i in n:
		var a := TAU * float(i) / float(n) + 0.12
		var len_m := 0.15 + 0.05 * float((i * 7) % 3)
		var r := 0.322
		var tassel := _node("Tassel", _torso, Vector3(sin(a) * r, 0.285, -cos(a) * r))
		# point DOWN and a little OUT: taper_tube runs along +Y, so flip it and lean it outward
		var out := Vector3(sin(a), 0.0, -cos(a))
		var down := (Vector3.DOWN + out * 0.28).normalized()
		tassel.basis = _basis_from_up(down)
		# two tones of moss, never the dark one: dark tassels read as HOLES cut in the hem (round 1)
		var mat: Material = m_light if i % 2 == 0 else m_moss
		_mi(taper_tube(len_m, 0.048, 0.016, 0.25, 4, 6), mat, tassel, Vector3.ZERO, "Strand")
		tassel.set_meta("phase", float(i) * 1.37)
		tassel.set_meta("rest", tassel.basis)
		_tassels.append(tassel)


## Arms: a moss clump at the shoulder, a short tapering moss sleeve and a round teal mitt. Built here
## instead of `_add_arms`, whose capsule + cuff + shoulder cap cost 700 triangles and put Moss over
## the 6,000 budget (measured 6,834 with them); a cuff also reads as tailoring on a creature of moss.
func _build_arms(m_sleeve: Material, m_hand: Material) -> void:
	for side: Array in [[-1.0, _arm_l], [1.0, _arm_r]]:
		var sx: float = side[0]
		var arm: Node3D = side[1]
		_mi(superellipsoid(Vector3(0.072, 0.064, 0.068), 2.4, 10, 6), m_sleeve, arm, Vector3.ZERO, "Shoulder")
		var sleeve := _node("Sleeve", arm, Vector3(0.0, 0.01, 0.0))
		sleeve.basis = _basis_from_up(Vector3.DOWN)
		_mi(taper_tube(ARM_LEN, 0.058, 0.050, 0.0, 3, 8), m_sleeve, sleeve, Vector3.ZERO, "Upper")
		var hand := _node("Hand", arm, Vector3(0.0, -ARM_LEN - 0.030, 0.0))
		_mi(superellipsoid(Vector3(HAND_R, HAND_R * 1.04, HAND_R * 0.92), HAND_N, 12, 7), m_hand, hand, Vector3.ZERO, "Mitten")
		if sx < 0.0:
			_hand_l = hand
		else:
			_hand_r = hand


## Soft moss clumps growing ON the cloak, so it reads as moss and not as a green dress (round 1's
## portrait: a plain bell read as fabric). Seated on the lathe's own surface at each height.
func _build_clumps(_m_light: Material, m_dark: Material) -> void:
	var spots := [[0.55, 0.30], [2.1, 0.40], [3.4, 0.27], [4.6, 0.46], [5.6, 0.33], [1.3, 0.50], [2.9, 0.52], [0.1, 0.44]]
	for k in spots.size():
		var a: float = spots[k][0]
		var y: float = spots[k][1]
		var r := _cloak_r(y) - 0.012
		var sz := 0.050 + 0.012 * float(k % 3)
		# DARKER than the cloak: pale clumps (round 2) read as polka dots on a dress, not as moss
		var clump := _mi(superellipsoid(Vector3(sz, sz * 0.62, sz * 0.9), 2.3, 9, 5), m_dark,
			_torso, Vector3(sin(a) * r, y, -cos(a) * r), "Clump")
		clump.rotation.y = -a


## The cloak's radius at height `y`, read off CLOAK_PROFILE.
static func _cloak_r(y: float) -> float:
	for i in range(1, CLOAK_PROFILE.size()):
		var a := CLOAK_PROFILE[i - 1]
		var b := CLOAK_PROFILE[i]
		if y >= minf(a.y, b.y) and y <= maxf(a.y, b.y) and absf(b.y - a.y) > 0.0001:
			return lerpf(a.x, b.x, (y - a.y) / (b.y - a.y))
	return 0.3


## A ring of soft moss clumps round the neck, so the head sits IN the cloak instead of on a stick.
func _build_ruff(m_light: Material, m_moss: Material) -> void:
	for i in 8:
		var a := TAU * float(i) / 8.0 + 0.2
		var r := 0.170
		_mi(superellipsoid(Vector3(0.085, 0.058, 0.080), 2.3, 10, 6), m_light if i % 2 == 0 else m_moss, _torso,
			Vector3(sin(a) * r, 0.640, -cos(a) * r), "Ruff")


## Two plain dark eyes set wide and low, soft blush, no brows and no nose; the "w" mouth is built by
## hand below (see the header: `_add_mouth` builds the cast's arc, which this character does not take).
func _build_face() -> void:
	_add_face(EYE, MOUTH, BLUSH, {
		"nose": false, "mouth": false, "brows": false,
		"eyes": [
			{"yaw": -21.0, "pitch": -3.0},
			{"yaw": 21.0, "pitch": -3.0},
			# the third eye: smaller, high and central, under the hat brim
			{"yaw": 0.0, "pitch": 13.5, "w": 0.029, "h": 0.034, "sx": 1.0},
		],
	})
	var mouth := _node("Mouth", _face, Vector3.ZERO)
	_orient_on_head(mouth, 0.0, -21.0, 0.002)
	var m_mouth := _toon(MOUTH, {"spec": 0.0, "rim": 0.0, "shade": 0.06})
	# THE "w": two small bowls, each a 150-degree sweep of a tiny ring, touching at the middle.
	_w_mouth = _node("W", mouth, Vector3(0.0, 0.0, -0.003))
	var ring := 0.0185
	var tube := 0.0062
	var a0 := deg_to_rad(195.0)
	var a1 := deg_to_rad(345.0)
	for sx: float in [-1.0, 1.0]:
		var bowl := _mi(arc_tube(ring, tube, a0, a1, 10, 5), m_mouth, _w_mouth,
			Vector3(sx * ring * cos(deg_to_rad(15.0)), ring * sin(deg_to_rad(15.0)), 0.0), "Bowl")
		bowl.scale = Vector3.ONE
	# the open mouth for talking: a dark oval with a warm inside, grown by MOUTH_OPEN in _animate_extras
	_open_mouth = _node("Open", mouth, Vector3(0.0, -0.010, -0.003))
	_mi(sphere(1.0, 12, 7), m_mouth, _open_mouth, Vector3.ZERO, "Lip")
	var m_inner := _toon(MOUTH_INNER, {"spec": 0.0, "rim": 0.0, "shade": 0.10})
	_mi(sphere(1.0, 10, 6), m_inner, _open_mouth, Vector3(0.0, -0.05, -0.55), "Inner").scale = Vector3(0.70, 0.62, 0.5)
	_open_mouth.scale = Vector3(mouth_w, 0.001, mouth_d)
	_open_mouth.visible = false


## FRILLED GILLS: three flat scalloped fronds per side, rooted just inside the shell at the side of
## the head and fanning out and a little back, under the brim. Each hangs off its own node so
## `_animate_extras` can sway it.
func _build_gills() -> void:
	var m_gill := _toon(GILL, _matte({"rim": 0.06, "shade": 0.20}))
	var m_deep := _toon(GILL_DEEP, _matte({"rim": 0.05, "shade": 0.20}))
	for sx: float in [-1.0, 1.0]:
		for k in GILLS.size():
			var g: Array = GILLS[k]
			var pitch := deg_to_rad(float(g[0]))
			var yaw := deg_to_rad(80.0 * sx)
			var d := Vector3(sin(yaw) * cos(pitch), sin(pitch), -cos(yaw) * cos(pitch))
			var root := se_point(d, head_semi, head_n) * 0.93
			var node := _node("Gill", _head, root)
			# out to the side, raised by the frond's elevation, swept 12 degrees back
			var elev := deg_to_rad(float(g[1]))
			var sweep := deg_to_rad(12.0)
			var out := Vector3(sx * cos(elev) * cos(sweep), sin(elev), cos(elev) * sin(sweep)).normalized()
			# the fan's flat face looks forward (-Z), so the front view sees the whole frill
			var face := Vector3(0.0, 0.0, -1.0 if sx > 0.0 else 1.0)
			var zv := (face - out * face.dot(out)).normalized()
			node.basis = Basis(out.cross(zv).normalized(), out, zv)
			_mi(_gill_mesh(float(g[2]), 0.050), m_gill if k != 1 else m_deep, node, Vector3.ZERO, "Frond")
			node.set_meta("phase", float(k) * 1.1 + (0.0 if sx > 0.0 else 0.5))
			node.set_meta("rest", node.basis)
			node.set_meta("side", sx)
			_gills.append(node)


## One gill frond: a flat fan along +Y in the XY plane, curling toward +X. The upper (+X) edge carries
## three round lobes - the frill - and the lower edge is a plain narrow taper, the axolotl-gill read.
## Double-sided, 12 stations, 48 triangles.
static func _gill_mesh(length: float, width: float) -> ArrayMesh:
	var key := "moss_gill|%.4f|%.4f" % [length, width]
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var kit := PlanetMeshKit.new()
	var n := 12
	var pts_l: Array[Vector3] = []
	var pts_r: Array[Vector3] = []
	for i in n + 1:
		var t := float(i) / float(n)
		var c := Vector3(0.20 * length * t * t, length * t, 0.0)
		var tg := Vector3(0.40 * length * t, length, 0.0).normalized()
		var nrm := Vector3(tg.y, -tg.x, 0.0)
		var taper := sqrt(maxf(0.0, sin(PI * clampf(0.5 + 0.5 * t, 0.5, 1.0)))) * (1.0 - 0.35 * t * t)
		var up := width * taper * (0.45 + 0.55 * absf(sin(3.0 * PI * t)))
		var dn := width * 0.35 * taper
		if i == 0:
			up = width * 0.30
			dn = width * 0.30
		pts_l.append(c - nrm * dn)
		pts_r.append(c + nrm * up)
	for i in n:
		kit.triangle(pts_l[i], pts_r[i], pts_r[i + 1], Color.WHITE, true)
		kit.triangle(pts_l[i], pts_r[i + 1], pts_l[i + 1], Color.WHITE, true)
	var mesh := kit.commit()
	_mesh_cache[key] = mesh
	return mesh


## GLOWING FRECKLES: three small flat hexagon dots over each cheek, lit so they read in the long
## Tangle night as well as by day.
func _build_freckles() -> void:
	var m_glow := lit_material(FRECKLE, 1.5, Color("#9fe6c4"))
	var disc := _freckle_mesh()
	for sx: float in [-1.0, 1.0]:
		for f: Array in FRECKLES:
			var node := _node("Freckle", _face, Vector3.ZERO)
			_orient_on_head(node, float(f[0]) * sx, float(f[1]), 0.001)
			var mi := _mi(disc, m_glow, node, Vector3(0.0, 0.0, -0.0015), "Dot")
			mi.scale = Vector3.ONE * float(f[2]) * face_scale
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## A unit hexagon in XY facing -Z (the way `_orient_on_head` points a node's -Z outward). 6 triangles.
static func _freckle_mesh() -> ArrayMesh:
	var key := "moss_freckle"
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var kit := PlanetMeshKit.new()
	for i in 6:
		var a0 := TAU * float(i) / 6.0
		var a1 := TAU * float(i + 1) / 6.0
		kit.triangle(Vector3.ZERO, Vector3(cos(a0), sin(a0), 0.0), Vector3(cos(a1), sin(a1), 0.0), Color.WHITE, false)
	var mesh := kit.commit()
	_mesh_cache[key] = mesh
	return mesh


## THE HAT: a lily pad with its notch, drooping a little at the rim, tipped back so the face shows,
## a lilac water-lily on top and a few strands of moss hanging from its back edge.
func _build_hat() -> void:
	_hat = _node("Hat", _head, Vector3(0.0, head_semi.y - 0.030, 0.020))
	# Tipped back a little and jaunty to one side. Round 1 tipped the front edge UP
	# (0.16 rad) to clear the face; from the talk camera that was fine, but at eye level the pad
	# became a thin line; level (round 2), a high talk camera lost the eyes under the brim. 0.11 keeps both.
	_hat.rotation = Vector3(0.11, 0.0, -0.08)
	var m_pad := _toon(PAD, _matte({"rim": 0.05, "spec": 0.04, "spec_size": 90.0}))
	var m_under := _toon(PAD_UNDER, _matte({}))
	var m_vein := _toon(PAD_VEIN, _matte({}))
	var meshes := _lily_pad_meshes(HAT_R, 0.52, deg_to_rad(-62.0))
	_mi(meshes[0], m_pad, _hat, Vector3.ZERO, "PadTop")
	_mi(meshes[1], m_under, _hat, Vector3.ZERO, "PadUnder")
	_mi(meshes[2], m_vein, _hat, Vector3.ZERO, "PadVeins")
	# a little crown bump in the middle where the pad sits on the head
	_mi(superellipsoid(Vector3(0.10, 0.045, 0.10), 2.4, 10, 5), m_pad, _hat, Vector3(0.0, 0.028, 0.0), "Knot")
	_build_lily(Vector3(0.17, 0.030, -0.12))
	# moss strands off the back half of the rim
	var m_moss := _toon(MOSS, _matte({}))
	var m_dark := _toon(MOSS_DARK, _matte({}))
	for k in 5:
		var a := deg_to_rad(40.0 + 25.0 * float(k))   # angles measured from +Z (the back), both sides
		var sx := -1.0 if k % 2 == 0 else 1.0
		var ang := a * sx
		var p := Vector3(sin(ang) * HAT_R * 0.96, _droop_y(0.96) - 0.012, cos(ang) * HAT_R * 0.96)
		var strand := _node("HatMoss", _hat, p)
		strand.basis = _basis_from_up(Vector3.DOWN)
		_mi(taper_tube(0.10 + 0.04 * float(k % 3), 0.026, 0.010, 0.2, 4, 5), m_moss if k % 2 == 0 else m_dark,
			strand, Vector3.ZERO, "Strand")
		strand.set_meta("phase", float(k) * 2.1)
		strand.set_meta("rest", strand.basis)
		_hat_strands.append(strand)


## Height of the pad's surface at `f` (0 centre .. 1 rim): a shallow umbrella that droops at the edge.
static func _droop_y(f: float) -> float:
	return 0.030 - 0.085 * f * f


## The pad as three meshes: [top, underside + rim, veins]. A notched disc built by hand, because a
## lathe cannot leave a notch and the notch is what says "lily pad" and not "plate". Winding follows
## PlanetMeshKit.triangle: front = a, b, c clockwise, normal (c - a) x (b - a).
static func _lily_pad_meshes(r: float, notch: float, notch_at: float) -> Array:
	var top := PlanetMeshKit.new()
	var under := PlanetMeshKit.new()
	var veins := PlanetMeshKit.new()
	var segs := 22
	var rings: Array[float] = [0.0, 0.34, 0.68, 1.0]
	var thick := 0.022
	var pts: Array = []   # pts[ring][seg]
	for ri in rings.size():
		var row: Array = []
		for i in segs + 1:
			var a := notch_at + notch * 0.5 + (TAU - notch) * float(i) / float(segs)
			var f: float = rings[ri]
			row.append(Vector3(sin(a) * r * f, _droop_y(f), -cos(a) * r * f))
		pts.append(row)
	for ri in rings.size() - 1:
		for i in segs:
			var a: Vector3 = pts[ri][i]
			var b: Vector3 = pts[ri][i + 1]
			var c: Vector3 = pts[ri + 1][i + 1]
			var d: Vector3 = pts[ri + 1][i]
			_tri_facing(top, a, b, c, Vector3.UP, Color.WHITE)
			_tri_facing(top, a, c, d, Vector3.UP, Color.WHITE)
			var dn := Vector3(0.0, -thick, 0.0)
			_tri_facing(under, a + dn, b + dn, c + dn, Vector3.DOWN, Color.WHITE)
			_tri_facing(under, a + dn, c + dn, d + dn, Vector3.DOWN, Color.WHITE)
	# the rim band all the way round, and the two cut faces of the notch
	var last: Array = pts[rings.size() - 1]
	for i in segs:
		var a: Vector3 = last[i]
		var b: Vector3 = last[i + 1]
		var out := Vector3(a.x + b.x, 0.0, a.z + b.z).normalized()
		_tri_facing(under, a, b, b + Vector3(0.0, -thick, 0.0), out, Color.WHITE)
		_tri_facing(under, a, b + Vector3(0.0, -thick, 0.0), a + Vector3(0.0, -thick, 0.0), out, Color.WHITE)
	for edge: int in [0, segs]:
		for ri in rings.size() - 1:
			var a: Vector3 = pts[ri][edge]
			var b: Vector3 = pts[ri + 1][edge]
			var side := Vector3(b.z, 0.0, -b.x).normalized() * (1.0 if edge == 0 else -1.0)
			var dn := Vector3(0.0, -thick, 0.0)
			_tri_facing(under, a, b, b + dn, side, Color.WHITE)
			_tri_facing(under, a, b + dn, a + dn, side, Color.WHITE)
	# veins: seven raised radial ribs from the centre, the way a real pad's veins fan out
	for k in 7:
		var i := int(round(float(segs) * (float(k) + 0.5) / 7.0))
		var tip: Vector3 = last[i]
		var dir := Vector3(tip.x, 0.0, tip.z).normalized()
		var side := Vector3(-dir.z, 0.0, dir.x) * 0.010
		var prev := Vector3(0.0, _droop_y(0.0) + 0.004, 0.0)
		for s in range(1, 5):
			var f := 0.18 + 0.78 * float(s) / 4.0
			var p := Vector3(dir.x * r * f, _droop_y(f) + 0.004, dir.z * r * f)
			var w := 1.0 - 0.6 * f
			_tri_facing(veins, prev - side * w, prev + side * w, p + side * w, Vector3.UP, Color.WHITE)
			_tri_facing(veins, prev - side * w, p + side * w, p - side * w, Vector3.UP, Color.WHITE)
			prev = p
	return [top.commit(), under.commit(), veins.commit()]


## One single-sided triangle whose front faces `want`.
static func _tri_facing(kit: PlanetMeshKit, a: Vector3, b: Vector3, c: Vector3, want: Vector3, col: Color) -> void:
	var nrm := (c - a).cross(b - a)
	if nrm.dot(want) < 0.0:
		kit.triangle(a, c, b, col, false)
	else:
		kit.triangle(a, b, c, col, false)


## The water-lily: six pointed petals in two tiers round a gold heart.
func _build_lily(at: Vector3) -> void:
	var lily := _node("Lily", _hat, at)
	var m_petal := _toon(PETAL, _matte({"rim": 0.06}))
	var m_tip := _toon(PETAL_TIP, _matte({"rim": 0.06}))
	for tier in 2:
		var n := 5 if tier == 0 else 3
		for k in n:
			var a := TAU * float(k) / float(n) + (0.0 if tier == 0 else 0.6)
			var petal := _node("Petal", lily, Vector3.ZERO)
			petal.rotation = Vector3(0.0, a, 0.0)
			var lean := _node("Lean", petal, Vector3(0.0, 0.0, -0.050 if tier == 0 else -0.026))
			lean.rotation.x = -0.55 if tier == 0 else -0.95
			var sz := Vector3(0.046, 0.016, 0.092) * (1.0 if tier == 0 else 0.72)
			_mi(superellipsoid(sz, 1.8, 8, 5), m_petal if tier == 0 else m_tip, lean, Vector3(0.0, 0.0, -sz.z * 0.8), "Blade")
	_mi(sphere(0.042, 10, 6), _toon(LILY_HEART, _matte({"rim": 0.04})), lily, Vector3(0.0, 0.034, 0.0), "Heart")


## The reed staff, standing on the ground at the right hand, with a cattail head, a crook, and a
## lantern hanging off it that swings.
func _build_staff() -> void:
	var staff := _node("Staff", _body, STAFF_AT)
	var m_reed := _toon(REED, _matte({"rim": 0.04}))
	var m_reed_dark := _toon(REED_DARK, _matte({}))
	_mi(taper_tube(STAFF_H, 0.026, 0.019, 0.0, 8, 7), m_reed, staff, Vector3.ZERO, "Reed")
	# reed joints
	for y: float in [0.46, 0.92, 1.34]:
		_mi(torus(0.018, 0.034, 10, 4), m_reed_dark, staff, Vector3(0.0, y, 0.0), "Joint")
	# the cattail head, and a thin spike above it
	_mi(capsule(0.040, 0.20, 8, 1), _toon(CATTAIL, _matte({})), staff, Vector3(0.0, STAFF_H + 0.08, 0.0), "Cattail")
	_mi(taper_tube(0.12, 0.010, 0.004, 0.0, 3, 4), m_reed_dark, staff, Vector3(0.0, STAFF_H + 0.17, 0.0), "Spike")
	# the crook: a short arm curling outward and down, from which the lantern hangs
	var crook := _node("Crook", staff, Vector3(0.0, 1.40, 0.0))
	crook.basis = _basis_from_up(Vector3(1.0, 0.35, 0.0).normalized())
	_mi(taper_tube(0.20, 0.014, 0.011, -1.9, 6, 5), m_reed_dark, crook, Vector3.ZERO, "Hook")
	var hook_end := crook.basis * taper_tube_end(0.20, -1.9, 6)
	_lantern = _node("Lantern", staff, Vector3(0.0, 1.40, 0.0) + hook_end)
	var m_cage := _toon(CAGE, _matte({"spec": 0.10, "spec_size": 80.0}))
	var cage := _node("Cage", _lantern, Vector3(0.0, -0.14, 0.0))
	# a string, the cap, two rings and four ribs round a glowing bulb
	_mi(cylinder(0.004, 0.004, 0.07, 4), m_cage, _lantern, Vector3(0.0, -0.035, 0.0), "String")
	_mi(cylinder(0.020, 0.052, 0.035, 10), m_cage, cage, Vector3(0.0, 0.070, 0.0), "Cap")
	for y: float in [0.050, -0.070]:
		_mi(torus(0.046, 0.058, 12, 3), m_cage, cage, Vector3(0.0, y, 0.0), "Ring")
	for k in 4:
		var a := TAU * float(k) / 4.0 + PI * 0.25
		_mi(cylinder(0.005, 0.005, 0.12, 4), m_cage, cage, Vector3(cos(a) * 0.052, -0.010, sin(a) * 0.052), "Rib")
	_mi(cylinder(0.030, 0.050, 0.020, 10), m_cage, cage, Vector3(0.0, -0.080, 0.0), "Base")
	var bulb := _mi(sphere(1.0, 12, 7), lit_material(LANTERN, 2.6, Color("#ffcf7a")), cage, Vector3(0.0, -0.010, 0.0), "Bulb")
	bulb.scale = Vector3(0.040, 0.052, 0.040)
	bulb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


# =================================================================================== animation
## The right hand holds the staff in every state (the staff stands on the ground, the arm reaches to
## it), so the base poses' right-arm channels are overwritten after they run.
const HOLD_ROLL := 0.86
const HOLD_PITCH := 0.50


func _hold_staff(p: PackedFloat32Array) -> void:
	p[P.ARM_R_ROLL] = HOLD_ROLL
	p[P.ARM_R_PITCH] = HOLD_PITCH
	p[P.ARM_R_YAW] = 0.0


## Idle: a slow reed-like sway from side to side, the head following a beat late. No bounce.
func _pose_idle(p: PackedFloat32Array) -> void:
	var s := sin(TAU * _time * 0.22)
	p[P.TORSO_ROLL] = 0.040 * s
	p[P.BODY_Y] = -0.006 * absf(s)
	p[P.SQUASH] = 1.0 + 0.012 * sin(TAU * _time * 0.44)
	p[P.HEAD_ROLL] = 0.050 * sin(TAU * _time * 0.22 - 0.9)
	p[P.HEAD_YAW] = _look_yaw * 0.8
	p[P.HEAD_PITCH] = _look_pitch * 0.8
	p[P.ARM_L_ROLL] = 0.26 + 0.03 * s
	p[P.ARM_L_PITCH] = 0.05
	_hold_staff(p)


func _pose_walk(p: PackedFloat32Array) -> void:
	super._pose_walk(p)
	_hold_staff(p)


## Talk: the free hand explains, the head nods slowly, the body keeps its sway.
func _pose_talk(p: PackedFloat32Array, t: float) -> void:
	_pose_idle(p)
	p[P.HEAD_PITCH] += 0.05 * sin(TAU * t * 0.9)
	p[P.HEAD_ROLL] += 0.04 * sin(TAU * t * 0.55)
	p[P.MOUTH_OPEN] = 0.35 + 0.55 * maxf(0.0, sin(TAU * t * 3.0))
	p[P.ARM_L_ROLL] = 0.55 + 0.20 * sin(TAU * t * 0.8)
	p[P.ARM_L_PITCH] = 0.55 + 0.18 * sin(TAU * t * 1.3)
	_hold_staff(p)


## Wave with the LEFT hand - the right one is holding the staff.
func _pose_wave(p: PackedFloat32Array, t: float) -> void:
	_pose_idle(p)
	var w := sin(TAU * t * 2.2)
	p[P.ARM_L_ROLL] = 1.95 + 0.28 * w
	p[P.ARM_L_PITCH] = -0.10
	p[P.ARM_L_YAW] = 0.18 * w
	p[P.HEAD_ROLL] = 0.10
	p[P.EYE_HAPPY] = 1.0
	p[P.MOUTH_OPEN] = 0.2
	_hold_staff(p)


func _pose_happy(p: PackedFloat32Array, t: float) -> void:
	_pose_idle(p)
	var b := sin(TAU * t * 1.2)
	p[P.BODY_Y] = 0.035 * maxf(0.0, b)
	p[P.SQUASH] = 1.0 + 0.05 * b
	p[P.ARM_L_ROLL] = 1.4 + 0.2 * b
	p[P.EYE_HAPPY] = 1.0
	p[P.MOUTH_OPEN] = 0.45
	_hold_staff(p)


func _pose_think(p: PackedFloat32Array, t: float) -> void:
	_pose_idle(p)
	var u := clampf(t / 0.5, 0.0, 1.0)
	p[P.ARM_L_ROLL] = lerpf(0.26, -0.15, u)
	p[P.ARM_L_PITCH] = 1.25 * u
	p[P.HEAD_ROLL] = -0.18 * u
	p[P.HEAD_PITCH] = 0.10 * u
	_hold_staff(p)


func _pose_surprised(p: PackedFloat32Array, t: float) -> void:
	super._pose_surprised(p, t)
	_hold_staff(p)


func _pose_dance(p: PackedFloat32Array, t: float) -> void:
	super._pose_dance(p, t)
	_hold_staff(p)


func _animate_extras(delta: float) -> void:
	var sway := pose(P.TORSO_ROLL)
	# tassels: each on its own slow phase, plus a lag against the body's sway
	for tassel: Node3D in _tassels:
		var ph: float = tassel.get_meta("phase", 0.0)
		var rest: Basis = tassel.get_meta("rest", tassel.basis)
		var wob := 0.10 * sin(TAU * _time * 0.35 + ph) - sway * 1.6
		tassel.basis = Basis(Vector3.FORWARD, wob) * rest
	for strand: Node3D in _hat_strands:
		var ph2: float = strand.get_meta("phase", 0.0)
		var rest2: Basis = strand.get_meta("rest", strand.basis)
		strand.basis = Basis(Vector3.RIGHT, 0.14 * sin(TAU * _time * 0.3 + ph2)) * rest2
	# the gills: a slow breathing flutter, each frond on its own phase, a little livelier when talking
	var talk := clampf(pose(P.MOUTH_OPEN), 0.0, 1.0)
	for gill: Node3D in _gills:
		var ph3: float = gill.get_meta("phase", 0.0)
		var rest3: Basis = gill.get_meta("rest", gill.basis)
		var amp := 0.10 + 0.08 * talk
		gill.basis = rest3 * Basis(Vector3.FORWARD, amp * sin(TAU * _time * 0.38 + ph3))
	# the lantern: a damped pendulum driven by the body's sway, so it lags and swings
	if _lantern:
		var drive := -sway * 3.0
		_lantern_vel += (drive - _lantern_ang) * 18.0 * delta
		_lantern_vel *= exp(-2.2 * delta)
		_lantern_ang += _lantern_vel * delta
		_lantern.rotation = Vector3(0.05 * sin(TAU * _time * 0.27), 0.0, clampf(_lantern_ang, -0.5, 0.5))
	# the "w" closes into the open mouth while talking
	if _w_mouth and _open_mouth:
		var mo := clampf(pose(P.MOUTH_OPEN), 0.0, 1.0)
		_open_mouth.visible = mo > 0.05
		if _open_mouth.visible:
			_open_mouth.scale = Vector3(mouth_w * (0.7 + 0.3 * mo), maxf(0.001, mouth_h * mo), mouth_d)
		_w_mouth.visible = mo < 0.30
