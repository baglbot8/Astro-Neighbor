class_name MayorModel
extends ChibiModel
## Professor Comet (npc id "mayor_orbit", kept so saves and voice routing never move) — the elder brass
## robot who watches the sky from the Commons. Same chibi silhouette and face grammar as the rest of
## the cast: two small dark eyes, a calm smile, no nose, no blush, muted bone brow ridges and a bone
## chin beard, a panelled head (chin plate, side plates with bolts). Everything he does is slow and
## gentle (anim_time_scale 0.62).
##
## 2026-09-14, THE SCIENTIST PASS. The user, looking at him: "he looks more like a graduate than a
## professor. Can you make him look more like a professor / scientist like the pokemon professors",
## and earlier "(e.g. with the cane)". The top hat, the gold-buttoned waistcoat and the placket read
## as a mayor; they are gone. What replaces them is the kindly lab-coat scientist archetype, built
## from this cast's own parts rather than copied from anyone:
##   * a long pale-grey LAB COAT worn OPEN (`_coat_meshes`), hem at boot-top, with a slate shirt and a
##     burgundy tie showing down the front, lapels, a breast pocket with two pens, and a half-belt so
##     the back reads as a coat too. Grey, not white: #b8bcbc rendered V 0.78-0.81 on
##     the Commons on both renderers, 0 % of coat pixels at V >= 0.95.
##   * ROUND WIRE SPECTACLES on his eyes, his stargazing GOGGLES pushed up on his forehead ("My
##     goggles are for stargazing" still holds), and puffs of bone-white HAIR at the temples.
##   * a PENCIL tucked behind his right side plate ("I lost my pencil. It's behind my ear.").
##   * a real crook-handled WALKING CANE in warm dark wood, held in his right hand in every state.
## The horns are gone: a hat no longer hides the dome, and the hair puffs break up its outline.
## This leaves him ONE item of CAST_VARIETY's hard vocabulary (the brow ridges), down from two.
##
## Two variants were rendered side by side (the builder's scratch sheet): A kept today's face
## (goggles on the eyes, horns, bow tie) on a knee-length coat; B, this file, won. At gameplay
## distance A read as "a robot in a white jacket" — the goggles over the eyes are the same shape as
## before and say "pilot" as much as "scientist" — while B's dark round spectacles, the goggles up on
## the brow and the white hair puffs are three silhouette-level scholar cues that survive at 11.7 m.

## R2.6 (aged brass, measured on a real noon frame): brass #c09449 S0.62 -> #b7a179 S0.34, gold
## #d9ae4e S0.64 -> #bfa87d S0.35, lens #f7f0dd V0.97 -> #c2b59b V0.76.
const BRASS := Color("#b7a179")
const BRASS_DARK := Color("#8d7f66")
const BRONZE := Color("#75634c")
## Smoked amber goggle glass (now on the forehead).
const LENS := Color("#c2b59b")
const EYE := Color("#241a12")
## Elder trim (brow ridges, beard, hair). A muted bone, never pure cream.
const WHITE := Color("#bcb29c")
const MOUTH := Color("#4e3020")
const GOLD := Color("#bfa87d")
## The lab coat: a pale neutral grey. Never pure white — see the header for the rendered values.
const COAT := Color("#b8bcbc")
const COAT_EDGE := Color("#979c9f")
const SHIRT := Color("#475269")
const TIE := Color("#7f4552")
const TIE_DARK := Color("#663542")
## The cane: warm dark wood, the darkest long shape on him, so it reads against the pale coat, his
## brass legs and the cream Commons plaza alike.
const WOOD := Color("#5a4538")
## Spectacle wire: dark enough to ring the eyes at gameplay distance.
const WIRE := Color("#4e4236")
const PENCIL := Color("#c9ad62")

## Cane geometry, in the model's own frame (feet at y 0, facing -Z, right hand on +X).
const CANE_R := 0.024
const CANE_TIP_MIN_Y := 0.015     ## the tip never goes below this: no ground clipping
const CANE_TILT_OUT := 0.10       ## radians, tip leaning away from the body
const CANE_TILT_FWD := 0.08       ## radians, tip a little ahead of the hand
## The fist wraps the inboard-rear of the stick, so the shaft rises past the mitten to the crook.
const CANE_GRIP_OFFSET := Vector3(0.060, 0.0, -0.036)
const CANE_ABOVE := 0.080         ## shaft above the grip, up to the crook
const CANE_HOOK_R := 0.048
## How far the hand may rise off its resting grip before it lifts the stick (breathing, bob).
const CANE_PRESS := 0.020
const CANE_STEP_LIFT := 0.035     ## tip lift at the top of each forward swing while walking
## The cane arm's resting pose: rolled out so the stick stands clear of the coat.
const CANE_ARM_ROLL := 0.60
const CANE_ARM_PITCH := 0.10

## The coat's exponent in plan: the torso bean's own, so it reads as the same body in a coat.
const COAT_N := 2.4
## The recessed shirt panel inside the open front sits at this fraction of the coat's radius.
const PANEL_K := 0.93
## Coat hem height. Measured, not tuned: with the open front widening to 30 deg at the hem, no leg or
## boot vertex crosses the cloth or the panel in idle, walk, talk, wave, happy or think.
const HEM_Y := 0.170
## The free left arm hangs this much further out in idle, walk and talk, so the mitten is not buried
## in the coat (measured: at most 48 % of its vertices inside the cloth in idle at the base rest roll,
## 16 % with this; tests/director/prof-art_coatclip.gd in the builder's scratch copy).
const LEFT_ARM_CLEAR := 0.20

var _cane: Node3D
var _cane_basis: Basis
var _cane_up := Vector3.UP
var _rest_grip_y := 0.0
## Shaft length from the grip down to the tip, derived in `_build_cane` from the rest pose.
var _cane_len := 0.34

static var _coat_cache: Array = []


func _init() -> void:
	super()
	# His own head: wider, notably shallower, flatter across the front (R3.2).
	head_semi = Vector3(0.3520, 0.2780, 0.3250)
	head_n = 3.2
	# 40 x 20 instead of the default 44 x 22: -128 triangles, which keeps him inside the 6 k budget
	# with the coat, and the n 3.2 shell shows no new facets at conversation distance.
	head_segs = Vector2i(40, 20)
	head_y = 0.8972
	anim_time_scale = 0.62
	eye_w = 0.0371
	eye_h = 0.0462
	eye_d = 0.0170
	mouth_w = 0.0540
	mouth_h = 0.0450
	mouth_d = 0.0160
	# start both arms in their resting places, so a freshly spawned model never blends the cane up
	# through his body or the free hand out of the coat over its first frames
	_pose[P.ARM_R_ROLL] = CANE_ARM_ROLL
	_pose[P.ARM_R_PITCH] = CANE_ARM_PITCH
	_pose[P.ARM_L_ROLL] = ARM_REST_ROLL + LEFT_ARM_CLEAR


# ------------------------------------------------------------------------------------------ coat
## Coat profile rows [y, rx, rz], collar to hem, in torso space (feet-relative). Every row clears the
## torso bean's own cross-section, and the hem flares slightly into an A-line.
const COAT_ROWS := [
	[0.645, 0.100, 0.090],
	[0.605, 0.178, 0.152],
	[0.525, 0.236, 0.200],
	[0.430, 0.256, 0.216],
	[0.335, 0.264, 0.224],
	[0.260, 0.274, 0.232],
	[HEM_Y, 0.300, 0.252],
]


## Half-angle of the open front, in radians, at height y: a lapel V at the chest, straight below,
## opening a little toward the hem so a stepping boot passes through the gap instead of the cloth.
static func open_half(y: float) -> float:
	var d: float
	if y >= 0.565:
		d = 40.0
	elif y >= 0.465:
		d = lerpf(22.0, 40.0, (y - 0.465) / 0.10)
	else:
		d = lerpf(30.0, 22.0, clampf((y - HEM_Y) / (0.465 - HEM_Y), 0.0, 1.0))
	return deg_to_rad(d)


## The profile at param t (0 collar .. 1 hem) as Vector3(y, rx, rz), Catmull-Rom through COAT_ROWS.
static func row_at(t: float) -> Vector3:
	var last := COAT_ROWS.size() - 1
	var f := clampf(t, 0.0, 1.0) * float(last)
	var i := mini(int(floor(f)), last - 1)
	var u := f - float(i)
	var out := Vector3.ZERO
	for c in 3:
		var p0: float = COAT_ROWS[maxi(i - 1, 0)][c]
		var p1: float = COAT_ROWS[i][c]
		var p2: float = COAT_ROWS[i + 1][c]
		var p3: float = COAT_ROWS[mini(i + 2, last)][c]
		out[c] = 0.5 * ((2.0 * p1) + (-p0 + p2) * u + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * u * u
			+ (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * u * u * u)
	return out


## The profile param whose height is y (the rows fall monotonically, so bisection is exact).
static func coat_t(y: float) -> float:
	var lo := 0.0
	var hi := 1.0
	for _i in 30:
		var mid := (lo + hi) * 0.5
		if row_at(mid).x > y:
			lo = mid
		else:
			hi = mid
	return (lo + hi) * 0.5


## A point on the coat at angle phi (0 = straight ahead, toward +X positive), param t, radius scale k.
static func coat_point(phi: float, t: float, k: float) -> Vector3:
	var r := row_at(t)
	var s := sin(phi)
	var c := cos(phi)
	var e := 2.0 / COAT_N
	return Vector3(r.y * k * signf(s) * pow(absf(s), e), r.x, -r.z * k * signf(c) * pow(absf(c), e))


static func coat_normal(phi: float, t: float, k: float) -> Vector3:
	var h := 0.002
	var dp := coat_point(phi + h, t, k) - coat_point(phi - h, t, k)
	var dt := coat_point(phi, t + h, k) - coat_point(phi, t - h, k)
	var n := dp.cross(dt).normalized()
	var p := coat_point(phi, t, k)
	if n.dot(Vector3(p.x, 0.0, p.z)) < 0.0:
		n = -n
	return n


## A grid of the coat surface between two edge functions of height, emitted as triangles.
static func _strip(st: SurfaceTool, phi0: Callable, phi1: Callable, k: float, t0: float, t1: float,
		cols: int, rings: int) -> void:
	var grid: Array = []
	for i in rings + 1:
		var t := lerpf(t0, t1, float(i) / rings)
		var y := row_at(t).x
		var a0: float = phi0.call(y)
		var a1: float = phi1.call(y)
		var row: Array = []
		for j in cols + 1:
			var phi := lerpf(a0, a1, float(j) / cols)
			row.append([coat_point(phi, t, k), coat_normal(phi, t, k)])
		grid.append(row)
	for i in rings:
		for j in cols:
			_tri(st, grid[i][j], grid[i][j + 1], grid[i + 1][j + 1])
			_tri(st, grid[i][j], grid[i + 1][j + 1], grid[i + 1][j])


## One triangle of [position, normal] pairs, wound Godot's way: front faces are clockwise seen from
## outside, i.e. (v1-v0) x (v2-v0) points INTO the solid (see ChibiModel's winding note).
static func _tri(st: SurfaceTool, a: Array, b: Array, c: Array) -> void:
	var pa: Vector3 = a[0]
	var pb: Vector3 = b[0]
	var pc: Vector3 = c[0]
	var nsum: Vector3 = a[1] + b[1] + c[1]
	var order := [a, b, c]
	if (pb - pa).cross(pc - pa).dot(nsum) > 0.0:
		order = [a, c, b]
	for v: Array in order:
		st.set_normal(v[1])
		st.add_vertex(v[0])


## The open lab coat as three meshes: the cloth, the shirt panel and the trouser panel. The cloth is
## an outer shell whose front sector is left open down to a panel recessed to PANEL_K, joined by a
## radial wall along each cut edge and capped at collar and hem, so under `cull_back` no angle looks
## through a hole. Built once and shared (every Professor is the same coat).
static func _coat_meshes() -> Array:
	if not _coat_cache.is_empty():
		return _coat_cache
	var rings := 11
	var cols := 18
	var waist_t := coat_t(0.300)
	var right_edge := func(y: float) -> float: return open_half(y)
	var left_edge := func(y: float) -> float: return TAU - open_half(y)
	var neg_edge := func(y: float) -> float: return -open_half(y)

	var cloth := SurfaceTool.new()
	cloth.begin(Mesh.PRIMITIVE_TRIANGLES)
	_strip(cloth, right_edge, left_edge, 1.0, 0.0, 1.0, cols, rings)
	for side: float in [1.0, -1.0]:
		for i in rings:
			var ta := float(i) / rings
			var tb := float(i + 1) / rings
			var pa := open_half(row_at(ta).x) * side
			var pb := open_half(row_at(tb).x) * side
			var o_a := coat_point(pa, ta, 1.0)
			var o_b := coat_point(pb, tb, 1.0)
			var i_a := coat_point(pa, ta, PANEL_K)
			var i_b := coat_point(pb, tb, PANEL_K)
			var n := (o_b - o_a).cross(i_a - o_a).normalized()
			# the wall faces the opening (toward phi = 0)
			if n.dot(Vector3(-side, 0.0, 0.0)) < 0.0:
				n = -n
			_tri(cloth, [o_a, n], [o_b, n], [i_b, n])
			_tri(cloth, [o_a, n], [i_b, n], [i_a, n])
	var n_cap := 20
	var hem := [Vector3(0.0, HEM_Y, 0.0), Vector3.DOWN]
	var collar := [Vector3(0.0, row_at(0.0).x, 0.0), Vector3.UP]
	var hem_pts: Array = []
	var collar_pts: Array = []
	for j in n_cap:
		var phi := TAU * float(j) / n_cap
		var k := PANEL_K if absf(wrapf(phi, -PI, PI)) < open_half(HEM_Y) else 1.0
		hem_pts.append([coat_point(phi, 1.0, k), Vector3.DOWN])
		collar_pts.append([coat_point(phi, 0.0, PANEL_K), Vector3.UP])
	for j in n_cap:
		_tri(cloth, hem, hem_pts[j], hem_pts[(j + 1) % n_cap])
		_tri(cloth, collar, collar_pts[j], collar_pts[(j + 1) % n_cap])

	var shirt := SurfaceTool.new()
	shirt.begin(Mesh.PRIMITIVE_TRIANGLES)
	_strip(shirt, neg_edge, right_edge, PANEL_K, 0.0, waist_t, 4, 8)
	var trousers := SurfaceTool.new()
	trousers.begin(Mesh.PRIMITIVE_TRIANGLES)
	_strip(trousers, neg_edge, right_edge, PANEL_K, waist_t, 1.0, 4, 3)
	_coat_cache = [cloth.commit(), shirt.commit(), trousers.commit()]
	return _coat_cache


## Seats `node` on the coat surface at (phi, y), its +Z pointing out of the cloth.
func _on_coat(node: Node3D, phi: float, y: float, k: float = 1.0, lift: float = 0.0) -> void:
	var t := coat_t(y)
	var n := coat_normal(phi, t, k)
	node.position = coat_point(phi, t, k) + n * lift
	node.basis = Basis.looking_at(-n, Vector3.UP)


# -------------------------------------------------------------------------------------- geometry
func _build_geometry() -> void:
	# painted/patinated brass is matte (R2.6); only the gold trim keeps a little sheen
	var m_dark := _toon(BRASS_DARK, _matte({"spec": 0.05}))
	var m_bronze := _toon(BRONZE, _matte({"spec": 0.05}))
	var m_gold := _toon(GOLD, {"spec": 0.22, "spec_size": 150.0, "metallic": 0.25, "rim": 0.16, "roughness": 0.55})
	var m_edge := _toon(COAT_EDGE, _matte({}))

	# ---- the coat. It encloses the torso completely, so there is no torso bean under it.
	var meshes := _coat_meshes()
	_mi(meshes[0], _toon(COAT, _matte({"spec": 0.03, "rim": 0.02})), _torso, Vector3.ZERO, "Coat")
	_mi(meshes[1], _toon(SHIRT, _matte({"spec": 0.03})), _torso, Vector3.ZERO, "Shirt")
	_mi(meshes[2], m_dark, _torso, Vector3.ZERO, "Trousers")
	# lapels: a folded-back flap along each edge of the V, one tone down so the fold reads
	var m_lapel := _toon(COAT.darkened(0.08), _matte({"spec": 0.03, "rim": 0.02}))
	for sx: float in [-1.0, 1.0]:
		var y_top := 0.598
		var y_bot := 0.470
		var p_top := coat_point(open_half(y_top) * sx, coat_t(y_top), 1.0)
		var p_bot := coat_point(open_half(y_bot) * sx, coat_t(y_bot), 1.0)
		var y_mid := (y_top + y_bot) * 0.5
		var n := coat_normal(open_half(y_mid) * sx, coat_t(y_mid), 1.0)
		var up := (p_top - p_bot).normalized()
		var side := up.cross(n).normalized()
		if side.x * sx < 0.0:
			side = -side
		var lap := _node("Lapel", _torso, (p_top + p_bot) * 0.5 + n * 0.006 + side * 0.020)
		var x := up.cross(n).normalized()
		lap.basis = Basis(x, n.cross(x).normalized(), n)
		_mi(superellipsoid(Vector3(0.024, p_top.distance_to(p_bot) * 0.5, 0.007), 3.0, 6, 4), m_lapel, lap, Vector3.ZERO, "Flap")
	# breast pocket on his left, with two pens
	var pocket := _node("Pocket", _torso, Vector3.ZERO)
	_on_coat(pocket, deg_to_rad(-52.0), 0.445, 1.0, 0.003)
	_mi(rounded_box(Vector3(0.075, 0.068, 0.012), 0.008, 6), m_edge, pocket, Vector3.ZERO, "Patch")
	# one mesh and one material for both pens: Forward+ batches identical pairs into one draw
	for px: float in [-0.016, 0.014]:
		_mi(cylinder(0.009, 0.009, 0.056, 6), m_gold, pocket, Vector3(px, 0.042, -0.006), "Pen")
	# a plain long tie on the shirt
	var knot := _node("TieKnot", _torso, Vector3.ZERO)
	_on_coat(knot, 0.0, 0.565, PANEL_K, 0.010)
	_mi(superellipsoid(Vector3(0.026, 0.024, 0.016), 2.6, 8, 5), _toon(TIE_DARK, _matte({})), knot, Vector3.ZERO, "Knot")
	var blade := _node("TieBlade", _torso, Vector3.ZERO)
	_on_coat(blade, 0.0, 0.440, PANEL_K, 0.008)
	var m_tie := _toon(TIE, _matte({}))
	_mi(rounded_box(Vector3(0.050, 0.200, 0.014), 0.010, 6), m_tie, blade, Vector3.ZERO, "Blade")
	# back: a half-belt so the back reads as a coat, and his wind-up key through it
	var belt := _node("HalfBelt", _torso, Vector3.ZERO)
	_on_coat(belt, PI, 0.330, 1.0, 0.004)
	_mi(rounded_box(Vector3(0.170, 0.036, 0.012), 0.008, 6), m_edge, belt, Vector3.ZERO, "Belt")
	var key := _node("WindUpKey", _torso, Vector3.ZERO)
	_on_coat(key, PI, 0.450, 1.0, 0.012)
	_mi(cylinder(0.026, 0.026, 0.050, 10), m_bronze, key, Vector3.ZERO, "Boss").rotation.x = PI * 0.5
	_mi(superellipsoid(Vector3(0.070, 0.036, 0.012), 2.2, 10, 5), m_gold, key, Vector3(0.0, 0.0, 0.034), "Bow")

	_add_arms(COAT, BRASS_DARK, 0)
	_add_legs(BRASS_DARK, BRONZE)

	# ---- the head: panelled like the automaton he is
	_add_head_shell(BRASS, {"spec": 0.05, "spec_size": 90.0, "seam_color": BRASS_DARK})
	var chin := _node("ChinPlate", _face, Vector3.ZERO)
	_orient_on_head(chin, 0.0, -46.0, 0.008)
	_mi(rounded_box(Vector3(0.290, 0.088, 0.030), 0.020, 14), m_dark, chin, Vector3(0.0, 0.0, -0.006), "Plate")
	for sx2: float in [-1.0, 1.0]:
		var cap := _mi(cylinder(0.062, 0.062, 0.042, 14), m_dark, _head, Vector3((head_semi.x - 0.006) * sx2, -0.03, 0.02), "SidePlate")
		cap.rotation.z = PI * 0.5
		var bolt := _mi(cylinder(0.024, 0.024, 0.050, 8), m_bronze, _head, Vector3(0.348 * sx2, -0.03, 0.02), "Bolt")
		bolt.rotation.z = PI * 0.5
	_mi(rounded_box(Vector3(0.230, 0.030, 0.026), 0.012, 8), m_dark, _head, Vector3(0.0, -0.02, head_semi.z - 0.008), "BackSeam")

	_build_face(m_gold)
	_build_pencil()
	_build_cane(m_gold)


## The face: goggles pushed up on the forehead, round wire spectacles over the eyes, bone brow ridges,
## bone hair puffs at the temples and the bone chin beard.
func _build_face(m_gold: Material) -> void:
	# goggles up on the forehead: smoked lenses in brass rims, a bridge bar, a strap round the crown
	var m_lens := _toon(LENS, {"spec": 0.20, "spec_size": 150.0, "rim": 0.04, "shade": 0.14})
	for sx: float in [-1.0, 1.0]:
		var lens := _node("Lens", _face, Vector3.ZERO)
		_orient_on_head(lens, 15.5 * sx, EYE_PITCH + 36.0, 0.0)
		_mi(superellipsoid(Vector3(0.070, 0.075, 0.011), 2.5, 10, 5), m_lens, lens, Vector3.ZERO, "Glass")
		var rim := _mi(torus(0.069, 0.086, 16, 4), m_gold, lens, Vector3(0.0, 0.0, -0.009), "Rim")
		rim.rotation.x = PI * 0.5
	var bridge := _node("Bridge", _face, Vector3.ZERO)
	_orient_on_head(bridge, 0.0, EYE_PITCH + 36.0, 0.005)
	_mi(rounded_box(Vector3(0.120, 0.018, 0.020), 0.007, 10), m_gold, bridge, Vector3(0.0, 0.006, -0.010), "Bar")
	var strap_y := 0.150
	# the head's own half-depth at the strap's height, so the strap hugs the shell
	var zr := head_semi.z * pow(1.0 - pow(strap_y / head_semi.y, head_n), 1.0 / head_n)
	for sx2: float in [-1.0, 1.0]:
		var strap := _node("Strap", _head, Vector3(0.0, strap_y, 0.0))
		strap.rotation.y = 1.15 * sx2
		var seg := _mi(rounded_box(Vector3(0.170, 0.046, 0.030), 0.010, 8), _toon(BRONZE, _matte({})), strap,
			Vector3(0.0, 0.0, -(zr + 0.030)), "Seg")
		seg.rotation.y = 0.20 * sx2

	# R2.3: no blush on the robots, and no nose
	_add_face(EYE, MOUTH, Color.TRANSPARENT, {
		"nose": false, "blush": false, "mouth_inner": Color("#6f3529"),
		"brow_color": WHITE.darkened(0.10),
	})
	# round wire spectacles, standing just proud of the face so the eyes sit inside the rims
	var m_wire := _toon(WIRE, _matte({"spec": 0.10}))
	for sx: float in [-1.0, 1.0]:
		var sp := _node("Spectacle", _face, Vector3.ZERO)
		_orient_on_head(sp, EYE_YAW * sx, EYE_PITCH, -0.012)
		var ring := _mi(torus(0.064, 0.076, 16, 4), m_wire, sp, Vector3.ZERO, "Rim")
		ring.rotation.x = PI * 0.5
	var spec_bridge := _node("SpecBridge", _face, Vector3.ZERO)
	_orient_on_head(spec_bridge, 0.0, EYE_PITCH + 2.0, -0.010)
	_mi(arc_tube(0.030, 0.007, deg_to_rad(20.0), deg_to_rad(160.0), 6, 4), m_wire, spec_bridge, Vector3(0.0, -0.012, 0.0), "Arc")

	# elder hair: two soft bone puffs per temple, above and behind the side plates, wide enough to
	# stand out of the head's silhouette from the front
	var m_hair := _toon(WHITE, _matte({"rim": 0.02, "shade": 0.24}))
	for sx: float in [-1.0, 1.0]:
		# both puffs are ONE mesh, the smaller one scaled (one Forward+ draw for all four)
		var puffs := [
			[Vector3(head_semi.x * 1.00 * sx, 0.070, 0.070), 1.0, -0.55],
			[Vector3(head_semi.x * 0.86 * sx, 0.165, 0.120), 0.84, -0.85],
		]
		for pf: Array in puffs:
			var puff := _mi(superellipsoid(Vector3(0.078, 0.064, 0.100), 2.3, 8, 5), m_hair, _head, pf[0], "Hair")
			puff.rotation.z = float(pf[2]) * sx
			puff.scale = Vector3.ONE * float(pf[1])

	# elder brow ridges: thin muted-bone arcs, a heavy brow rather than two clown eyebrows
	for sx3: float in [-1.0, 1.0]:
		var brow := _node("BrowRidge", _face, Vector3.ZERO)
		_orient_on_head(brow, (EYE_YAW + 1.0) * sx3, EYE_PITCH + 16.5, 0.004)
		var barc := _mi(arc_tube(0.050, 0.0085, deg_to_rad(34.0), deg_to_rad(146.0), 12, 6),
			_toon(WHITE, _matte({"rim": 0.02})), brow, Vector3.ZERO, "Arc")
		barc.rotation.z = deg_to_rad(-9.0 * sx3)

	# chin beard: one tapered bone plate clear of the smile (five balls read as teeth)
	var beard := _node("Beard", _face, Vector3.ZERO)
	_orient_on_head(beard, 0.0, -36.0, 0.004)
	var m_white := _toon(WHITE, {"spec": 0.02, "rim": 0.02, "shade": 0.20})
	_mi(superellipsoid(Vector3(0.104, 0.036, 0.022), 2.7, 12, 7), m_white, beard, Vector3(0.0, 0.006, -0.004), "Plate")
	_mi(superellipsoid(Vector3(0.052, 0.034, 0.019), 2.6, 8, 5), m_white, beard, Vector3(0.0, -0.028, -0.002), "Tip")


## The pencil he always forgets, tucked behind his right side plate.
func _build_pencil() -> void:
	var pen := _node("Pencil", _head, Vector3(head_semi.x + 0.020, 0.040, 0.010))
	pen.rotation = Vector3(0.0, 0.0, 1.05)
	_mi(cylinder(0.012, 0.012, 0.160, 6), _toon(PENCIL, _matte({})), pen, Vector3.ZERO, "Wood")
	_mi(cylinder(0.002, 0.012, 0.030, 6), _toon(Color("#6a5a4a"), _matte({})), pen, Vector3(0.0, 0.095, 0.0), "Point")


# -------------------------------------------------------------------------------------- the cane
## The walking cane. Parented to the MODEL, not the hand, and placed under the grip every frame
## (`_place_cane`), so it stays upright however the torso waddles, its tip rests on the ground in
## every grounded state, and it lifts with him when he hops.
func _build_cane(m_brass: Material) -> void:
	var m_wood := _toon(WOOD, _matte({"spec": 0.06}))
	_cane = _node("Cane", self, Vector3.ZERO)
	_cane_basis = Basis(Vector3(0.0, 0.0, 1.0), CANE_TILT_OUT) * Basis(Vector3(1.0, 0.0, 0.0), CANE_TILT_FWD)
	_cane_up = _cane_basis * Vector3.UP
	# Exact, not fitted: the hand's height in the resting cane pose (the torso chain is identity at
	# rest, and the arm's YXZ Euler turns (0, -L, 0) into y = -L cos(roll) cos(pitch)), then the shaft
	# length below the grip that puts the tip on CANE_TIP_MIN_Y.
	var hand_len := ARM_LEN + 0.030
	_rest_grip_y = SHOULDER.y - hand_len * cos(CANE_ARM_ROLL) * cos(CANE_ARM_PITCH)
	_cane_len = (_rest_grip_y - CANE_TIP_MIN_Y) / _cane_up.y
	var total := _cane_len + CANE_ABOVE
	_mi(cylinder(CANE_R, CANE_R, total, 8), m_wood, _cane, Vector3(0.0, (CANE_ABOVE - _cane_len) * 0.5, 0.0), "Shaft")
	# the crook curls up and over AWAY from his body (+X), so it reads in silhouette from the front
	var crook := _node("Crook", _cane, Vector3(0.0, CANE_ABOVE, 0.0))
	_mi(arc_tube(CANE_HOOK_R, CANE_R, deg_to_rad(-40.0), PI, 10, 6), m_wood, crook, Vector3(CANE_HOOK_R, 0.0, 0.0), "Hook")
	# collar and ferrule share one mesh (one Forward+ draw)
	var m_band := cylinder(0.030, 0.030, 0.026, 8)
	_mi(m_band, m_brass, _cane, Vector3(0.0, CANE_ABOVE - 0.010, 0.0), "Collar")
	_mi(m_band, m_brass, _cane, Vector3(0.0, -_cane_len + 0.014, 0.0), "Ferrule")
	_place_cane()


## The cane node's origin is the grip point on the shaft axis; its tip is `_cane_len` below it.
func _place_cane() -> void:
	if _cane == null or _hand_r == null or not _hand_r.is_inside_tree():
		return
	var grip := to_local(_hand_r.global_position)
	var axis := grip + CANE_GRIP_OFFSET
	var tip_y := axis.y - _cane_up.y * _cane_len
	# the stick only leaves the ground when the hand rises past the press band (a hop, a big bob)
	var target := CANE_TIP_MIN_Y + maxf(0.0, grip.y - _rest_grip_y - CANE_PRESS)
	if _state == "walk" and _speed_factor > 0.05:
		target += CANE_STEP_LIFT * maxf(0.0, cos(_stride_phase)) * clampf(_speed_factor / 0.7, 0.0, 1.0)
	# slide the stick along its own axis so the tip lands exactly on the target height
	axis += _cane_up * ((target - tip_y) / _cane_up.y)
	_cane.transform = Transform3D(_cane_basis, axis)


## The right hand holds the cane in EVERY state. The base poses that animate the right arm (talk,
## wave, think) are mirrored onto the free LEFT arm, head tilt included, so he still waves and
## gestures — with the other hand. The torso lean is not mirrored: he leans on the stick.
func _compute_target(p: PackedFloat32Array, t: float) -> void:
	super(p, t)
	var swing := p[P.ARM_R_PITCH]
	if _state in ["talk", "wave", "think"]:
		p[P.ARM_L_PITCH] = p[P.ARM_R_PITCH]
		p[P.ARM_L_ROLL] = p[P.ARM_R_ROLL]
		p[P.ARM_L_YAW] = p[P.ARM_R_YAW]
		if _state != "talk":
			p[P.HEAD_ROLL] = -p[P.HEAD_ROLL]
			p[P.HEAD_YAW] = -p[P.HEAD_YAW]
	if _state in ["idle", "walk", "talk"]:
		p[P.ARM_L_ROLL] += LEFT_ARM_CLEAR
	p[P.ARM_R_ROLL] = CANE_ARM_ROLL
	p[P.ARM_R_YAW] = 0.0
	p[P.ARM_R_PITCH] = CANE_ARM_PITCH + (0.35 * swing if _state == "walk" else 0.0)


func _animate_extras(_delta: float) -> void:
	_place_cane()
