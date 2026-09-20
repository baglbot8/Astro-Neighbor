class_name FenVineModel
extends ChibiModel
## Fen — the pan-watcher of Fen's Long Dusk, a SENTIENT ALIEN PLANT. THIRD LOOK (2026-09-15).
## A pale bud face set in a big collar of petals that grows out of the neck, on a slim stem, carried
## and gestured by four long tapering vines whose soft pointed tips curl upward. No hands, no feet.
##
## THE USER'S NOTES on the first-pass bloom (2026-09-15), all three answered here:
##   1. "They shouldnt have hands and feet but rather like long vines with pointy ends curling up."
##      Every limb is ONE tapering tube (`vine_mesh`) that ends in a soft point which curls up and a
##      little back over itself. Fen stands on the BENDS of the two leg vines, where they turn from
##      hanging to running along the ground; the arm vines hang and gesture, and their curled tips
##      do the waving, the pointing and the chin-tap in think.
##   2. "The head's petals dont really read like a flower. We may need more petals."
##      Round 1 had seven broad petals closed round the bud (a tulip cup). This is an open bloom: a
##      full ring (`collar_style` "double": two rings of 12 pointed petals, "daisy": one ring of 16
##      narrow round-tipped rays) with the bud face as the flower's centre.
##   3. "...coming out at an angle from the neck so it's more like a huge collar (except for petals
##      blocking the face)."  The petals are rooted on the lip of a green CALYX CUP that grows out of
##      the top of the stem and holds the bud at the jaw line without touching it. They leave it on a
##      cone whose axis leans forward (COLLAR_TILT), so the ring rises behind the head and opens out
##      round its sides like a ruff, and droops under the chin at the front. Round 2 (2026-09-15
##      critic): round 1 rooted the ring INSIDE the bud (head-local y -0.17, where the bud is 0.24 m
##      wide), so from behind and the side the petals came out of the back of the head. Now the cup's
##      mouth is outside the bud and every petal's cone angle is SOLVED at build (`_clear_alpha`), so
##      no blade vertex comes within BUD_CLEAR of the bud at any flare.
##
## Everything that is Fen stays: the id, the name, the terse elder who has kept a nine-year logbook
## of which pools have moved, and the slowest manner in the cast.
##
## CAST_VARIETY SLOTS HELD (docs/CAST_VARIETY.md):
##   * eyestalks: NONE. Two small dark eyes sit flat on the bud face, no sclera (R2.3).
##   * wide toothy grin: NONE. No teeth of any kind.
##   * closed mouth KIND: a short STRAIGHT LIPLESS BAR (Zorp holds the one arc, Vela has none, Grig an
##     under-bite).
##   * surface: `sd_scales` stays Fen's, spent as a FINE bud texture on the face only; the stem and
##     vines carry `wood` grain, the petals `cloth`. No `sd_skin`, no `sd_foliage`.
##   * hard vocabulary: NONE of {brow ridge, heavy lid, horns, tusks, fangs, shoulder yoke}; Fen is
##     still the elder who wears none (ruling 2). The vine thorns are not in that list and are kept
##     soft: short blunt cones leaning back along the vine like a rose thorn.
##   * lashes: none. Blush: none. No declared sex in this file (ruling 3). Fen WALKS.
##
## MANNER: the slowest blink in the cast (`_update_blink`), a slow clock (`anim_time_scale` 0.80), a
## slight stoop, a shuffle, and petals that open a little when Fen speaks and wide when surprised.

# ---------------------------------------------------------------------------- palette
## Cool teal-sage stem and pale celadon bud against a warm terracotta pan and an amber sky: the
## complement of the ground, so the plant separates by HUE at 8 m. Every swatch is authored low in
## saturation, because the warm key light lifts chroma on mid-value warm albedos (the first pass
## measured an S 0.13 petal rendering at S 0.50).
const STEM := Color("#7a9893")        ## S 0.20 V 0.60 — torso stem
const VINE := Color("#6f8783")        ## S 0.18 V 0.53 — the four vines
const BUD := Color("#9cb3aa")         ## S 0.13 V 0.70 — the face
const CALYX := Color("#7a9990")       ## S 0.20 V 0.60 — the calyx cup the petals grow from
const THORN := Color("#95a49d")       ## S 0.09 V 0.64 — reads as a bump, not a spike
const EYE := Color("#22252d")
const MOUTH := Color("#34303a")
## Petal colours per ring are in COLLARS (so the two variants can differ); see that table.

const SURF_BUD := {"surface": "scales", "surface_scale": 4.2, "surface_strength": 0.12,
	"surface_near": 6.0, "surface_far": 18.0}
const SURF_STEM := {"surface": "wood", "surface_scale": 2.2, "surface_strength": 0.45,
	"surface_near": 6.0, "surface_far": 18.0, "surface_knot": 0.25}
const SURF_PETAL := {"surface": "cloth", "surface_scale": 2.0, "surface_strength": 0.30,
	"surface_near": 6.0, "surface_far": 18.0}

# ---------------------------------------------------------------------------- head
## THE BUD. Wider than tall like every chibi head, a true ellipsoid (n 2.0): a bud is soft.
const BUD_SEMI := Vector3(0.315, 0.265, 0.290)
const BUD_Y := 0.870

## Two eyes, flat on the bud. Yaw 19 puts the centres 0.190 m apart on a 0.630 m head = 30.2 %,
## inside the 28-35 % band.
const EYE_SPECS: Array[Dictionary] = [
	{"yaw": -19.0, "pitch": 2.0},
	{"yaw": 19.0, "pitch": 2.0},
]
## The bar mouth: 0.118 m on a 0.630 m head = 18.7 %, inside the 16-25 % band.
const MOUTH_BAR := Vector3(0.118, 0.012, 0.014)
const MOUTH_PITCH_FEN := -17.0

const SLOW_BLINK_HOLD := 0.30
const SLOW_LID_RATE := 11.0

# ---------------------------------------------------------------------------- collar
## Which bloom to build. "double" (the default) or "daisy"; `FenVineDaisyModel` sets the other.
var collar_style := "double"

## THE COLLAR FRAME, head-local. The receptacle's centre sits under the chin and a little back, and
## its axis leans FORWARD by COLLAR_TILT_DEG from straight up, so the rim is low at the front (under
## the chin) and high at the back (behind the jaw). Petal `alpha` is the angle between the axis and a
## petal's direction: the back petals rise at (alpha - tilt) from vertical, the front ones droop at
## (alpha + tilt), which is what makes it a COLLAR standing behind the face rather than a flat disc.
const COLLAR_CENTRE := Vector3(0.0, -0.215, 0.040)
const COLLAR_TILT_DEG := 10.0
## The receptacle: a green saucer the bud sits in. Its rim is where the petals are rooted, so they
## visibly grow out of it instead of out of the air beside the neck.
## THE CALYX CUP: the receptacle is a green cup, not a disc. A rounded LIP round the jaw (where the
## petals are rooted) and a wall that narrows down into the top of the stem, so the bloom visibly grows
## out of the stalk (round 2's first try, a bare ring, floated over a visible gap from behind). Its
## mouth is wider than the bud at that height, so the bud sits IN the cup without touching it and the
## petals can stand up from outside the head's silhouette. The profile is [radius, height] along the
## collar axis, one closed loop (lip crest, outer wall, foot, inner wall), turned by `lathe_mesh`. It
## replaces round 1's four sepals, which the cup would have swallowed.
const CUP_PROFILE := [
	Vector2(0.292, 0.026), Vector2(0.330, 0.016), Vector2(0.338, -0.004), Vector2(0.318, -0.024),
	Vector2(0.235, -0.058), Vector2(0.150, -0.104), Vector2(0.118, -0.120), Vector2(0.108, -0.104),
	Vector2(0.205, -0.050), Vector2(0.240, -0.012), Vector2(0.252, 0.014),
]
const CUP_SIDES := 20
## No blade vertex may come closer to the bud than this, as a fraction of the bud's size (the bud's
## implicit value must stay >= 1 + BUD_CLEAR: about 16-19 mm on its 0.265-0.315 m semi-axes).
const BUD_CLEAR := 0.06
## The outer ring stands at least this many degrees outside the inner ring at the same azimuth, so the
## two layers never scissor through each other when the solve lifts the inner ring.
const RING_GAP_DEG := 9.0

## One entry per ring. `count` petals start at azimuth `phase` degrees (0 = the back). `r0` is the
## root radius on the receptacle, `alpha_back`/`alpha_front` the cone angle at the back and front of
## the ring (blended by (1 - cos azimuth) / 2), `len_back`/`len_front` the same for length. The blade
## is `leaf_mesh(len, w, thick, c1, c2, cup, nl, nw, fat)`: c1 > 0 curls it OUTWARD (away from the
## face), `fat` > 1 moves the widest point toward the tip (a round daisy ray), < 1 toward the base (a
## pointed petal). `lift` raises the ring along the axis so an inner ring sits in front of the outer.
const COLLARS := {
	"double": [
		{"count": 12, "phase": 0.0, "r0": 0.300, "lift": 0.000, "alpha_back": 26.0, "alpha_front": 96.0,
			"len_back": 0.50, "len_front": 0.20, "w": 0.180, "w_front": 0.135, "c1": 0.45, "c2": 0.20, "cup": -0.15,
			"fat": 0.85, "color": "#98a0c4", "nl": 6, "nw": 2},
		{"count": 12, "phase": 15.0, "r0": 0.282, "lift": 0.012, "alpha_back": 16.0, "alpha_front": 84.0,
			"len_back": 0.40, "len_front": 0.16, "w": 0.150, "w_front": 0.115, "c1": 0.30, "c2": 0.15, "cup": -0.15,
			"fat": 0.85, "color": "#9297b5", "nl": 6, "nw": 2},
	],
	"daisy": [
		{"count": 16, "phase": 11.25, "r0": 0.295, "lift": 0.000, "alpha_back": 20.0, "alpha_front": 92.0,
			"len_back": 0.50, "len_front": 0.22, "w": 0.120, "c1": 0.40, "c2": 0.30, "cup": -0.18,
			"fat": 1.55, "color": "#b4b2c8", "nl": 7, "nw": 2},
	],
}
const PETAL_THICK := 0.020

# ---------------------------------------------------------------------------- vines
## A vine is a list of [arc length, total turn in radians, segments] pieces. Built along +Y bending
## toward +Z (the `taper_tube` convention), then turned so +Y hangs DOWN and +Z points along the
## vine's bend direction, which is outboard and a little forward (BEND_FWD_DEG ahead of straight out),
## so the curl reads from the front AND from the gameplay camera. The heading runs from 0 (straight
## down) past PI (straight up): every limb ends curled UP and a little back over itself.
const VINE_SHOULDER := Vector3(0.215, 0.515, -0.010)
## 0.60 m of vine on a 1.16 m plant: the user asked for LONG vines, and at 0.51 m the arm tips hung
## at the hip and the arms vanished under the collar at 8 m.
const ARM_PIECES := [[0.26, 0.20, 3], [0.16, 0.95, 4], [0.18, 2.65, 9]]
const ARM_R := Vector2(0.040, 0.0075)
const ARM_TAPER := 0.85
const ARM_BEND_FWD_DEG := 25.0
## Hang the arms this far out (roll, radians) so the vines stand clear of the stem.
const VINE_HANG_ROLL := 0.40

## The leg's first piece is straight down; its length is SOLVED at build (`_solve_leg_drop`) so the
## lowest vertex of the bend sits exactly GROUND_EPS above the ground plane at rest.
const LEG_BEND := [[0.10, PI * 0.5, 5], [0.07, 0.0, 2], [0.09, 1.15, 4], [0.09, 1.95, 7]]
const LEG_R := Vector2(0.046, 0.0070)
const LEG_TAPER := 0.62
const LEG_BEND_FWD_DEG := 28.0
const GROUND_EPS := 0.0015

## [fraction along the vine, side angle in degrees about the vine (0 = outboard of the bend plane,
## +90 = the bend side), length]. Only on the upper, straight part of each vine.
const ARM_THORNS := [[0.18, -70.0, 0.046], [0.40, 110.0, 0.040]]
const LEG_THORNS := [[0.22, -80.0, 0.044]]
const THORN_TIP_K := 0.33             ## tip radius / base radius — blunt, a bump with a point


# ---------------------------------------------------------------------------- state
## How far the petals open, radians on top of each petal's rest angle (a positive flare swings a petal
## OUTWARD, away from the face). `marker_clearance` and `_animate_extras` read the same numbers.
const FLARE_TALK := 0.06
const FLARE_OPEN := 0.16              ## happy, dance
const FLARE_SURPRISED := 0.26
const FLARE_THINK := -0.06
const PETAL_BREATHE := 0.020
const PETAL_DANCE := 0.06
## Fen's hops are a fraction of the chibi's: a calm elder.
const HOP_SCALE := 0.45
## Arm targets (pitch, roll, yaw) per gesture; see the pose functions. WAVE_ARM and THINK_ARM come
## from a grid search on the built model (pitch -1.8..2.4, roll -0.9..2.7, yaw -1.6..1.6): every arm
## vertex >= 22 mm from a dense sampling of every collar triangle, outside the bud and outside the
## stem. Round 2 re-ran the search on the lower collar. A RAISED wave still does not exist on this
## body: the side petals stand up from the jaw ring at 0.30 m out, and no passing pose put the curled
## tip above y 0.72, so Fen waves with the vine held straight out at shoulder height and a little
## forward, the curled tip flapping side to side (rather than round 1's low fling, which read as talk).
## THINK now reaches the chin: the lower collar leaves room beside the face, and the tip sits about
## 6 cm from the search target beside the mouth.
const TALK_ARM := Vector3(0.55, 0.55, 0.0)
const WAVE_ARM := Vector3(0.45, 1.50, -0.40)
## The wave arm this model uses; a collar variant whose side petals hang lower sets its own.
var wave_arm := WAVE_ARM
const HAPPY_ARM := Vector3(0.35, 1.00, 0.0)
const DANCE_ARM := Vector3(0.35, 0.80, 0.0)
const SURPRISED_ARM := Vector3(0.25, 1.10, 0.0)
const THINK_ARM := Vector3(0.0, 1.35, -1.20)

var _petal_pivots: Array[Node3D] = []
var _petal_verts: Array[PackedVector3Array] = []
var _petal_rest: Array[Basis] = []
var _petal_az: PackedFloat32Array = PackedFloat32Array()
var _collar: Node3D
var _flare: float = 0.0
var _t: float = 0.0
## Leg planting: the lowest leg vertex (leg-pivot space) as a function of the leg's pitch, sampled
## every PLANT_STEP radians over +/- PLANT_RANGE (see `_build_plant_table`).
const PLANT_RANGE := 1.2
const PLANT_STEP := 0.03
var _plant_min: PackedFloat32Array = PackedFloat32Array()
var _leg_first := 0.0
## Where each arm vine's tip is, in arm-pivot space (for the probes and the think pose).
var arm_tip_local := Vector3.ZERO


func _init() -> void:
	super()
	body_scale = 1.0
	anim_time_scale = 0.80
	hover_height = 0.0
	blink_hold = 1.6
	eye_w = 0.034
	eye_h = 0.040
	eye_d = 0.018
	mouth_w = 0.050
	mouth_h = 0.044
	face_scale = 1.0
	head_semi = BUD_SEMI
	head_n = 2.0
	head_segs = Vector2i(36, 18)
	head_y = BUD_Y


func _build_geometry() -> void:
	_petal_pivots.clear()
	_petal_verts.clear()
	_petal_rest.clear()
	_petal_az = PackedFloat32Array()
	_collar = null
	_marker_clear = -1.0
	_build_body()
	_add_head_shell(BUD, _merged(SURF_BUD, {"crown_seam": false}))
	_add_face(EYE, MOUTH, BUD, {
		"nose": false, "blush": false, "brows": false, "eyes": EYE_SPECS,
	})
	_build_bar_mouth()
	_build_collar()


## START IN THE IDLE POSE, not the base class's all-zero pose. At zero roll a vine arm hangs straight
## down through the stem, and `tick` only blends toward idle, so the first frames after a spawn showed
## both vines inside the body (the state probe caught it at frame 0 of every run).
func _ready() -> void:
	super()
	_reset_pose(_pose)
	_compute_target(_pose, 0.0)
	_apply_pose(0.0)
	_animate_extras(0.0)


# ============================================================================= body
func _build_body() -> void:
	# THE STEM. A narrower bean than the chibi torso, no waist chamfer (a chamfer ring read as a vest).
	_add_torso_bean(STEM, _merged(SURF_STEM, {"size_mul": Vector3(0.92, 0.92, 0.95),
		"waist_chamfer": false}))
	var m_vine := _toon(VINE, _matte(SURF_STEM))
	var m_thorn := _toon(THORN, _matte({"spec": 0.02}))
	_arm_l.position = Vector3(-VINE_SHOULDER.x, VINE_SHOULDER.y, VINE_SHOULDER.z)
	_arm_r.position = Vector3(VINE_SHOULDER.x, VINE_SHOULDER.y, VINE_SHOULDER.z)
	_hand_l = _build_vine_arm(_arm_l, -1.0, m_vine, m_thorn)
	_hand_r = _build_vine_arm(_arm_r, 1.0, m_vine, m_thorn)
	_leg_first = _solve_leg_drop()
	_build_vine_leg(_leg_l, -1.0, m_vine, m_thorn)
	_build_vine_leg(_leg_r, 1.0, m_vine, m_thorn)
	_build_plant_table()


## The basis that hangs a +Y-growing vine DOWN and turns its +Z bend toward `bend` (unit, in XZ).
static func _hang_basis(bend: Vector3) -> Basis:
	var y := Vector3.DOWN
	var z := bend
	return Basis(y.cross(z), y, z)


static func _bend_dir(sx: float, fwd_deg: float) -> Vector3:
	var a := deg_to_rad(fwd_deg)
	return Vector3(sx * cos(a), 0.0, -sin(a))


## One vine arm under the shoulder pivot. Returns the TIP node (the "hand" the base class tracks).
func _build_vine_arm(arm: Node3D, sx: float, m_vine: Material, m_thorn: Material) -> Node3D:
	# A knot where the vine leaves the stem, so the joint is a shape, not a seam.
	_mi(superellipsoid(Vector3(0.050, 0.047, 0.049), 2.4, 12, 7), m_vine, arm, Vector3.ZERO, "Knot")
	var vine := _node("Vine", arm, Vector3.ZERO)
	vine.basis = _hang_basis(_bend_dir(sx, ARM_BEND_FWD_DEG))
	_mi(vine_mesh(ARM_PIECES, ARM_R.x, ARM_R.y, ARM_TAPER, 7), m_vine, vine, Vector3.ZERO, "Stem")
	for th: Array in ARM_THORNS:
		_add_vine_thorn(vine, ARM_PIECES, ARM_R, ARM_TAPER, float(th[0]), _mirror_side(float(th[1]), sx),
			float(th[2]), m_thorn)
	var smp := _vine_samples(ARM_PIECES)
	var pts: PackedVector3Array = smp[0]
	var tip := _node("Tip", vine, pts[pts.size() - 1])
	arm_tip_local = vine.basis * tip.position
	return tip


## One vine leg under the hip pivot: straight down for `_leg_first`, round the bend onto the ground,
## along it, and up into the curl.
func _build_vine_leg(leg: Node3D, sx: float, m_vine: Material, m_thorn: Material) -> void:
	var vine := _node("Vine", leg, Vector3.ZERO)
	vine.basis = _hang_basis(_bend_dir(sx, LEG_BEND_FWD_DEG))
	var pieces := _leg_pieces(_leg_first)
	_mi(vine_mesh(pieces, LEG_R.x, LEG_R.y, LEG_TAPER, 7), m_vine, vine, Vector3.ZERO, "Stem")
	for th: Array in LEG_THORNS:
		_add_vine_thorn(vine, pieces, LEG_R, LEG_TAPER, float(th[0]), _mirror_side(float(th[1]), sx),
			float(th[2]), m_thorn)


static func _leg_pieces(first: float) -> Array:
	var p: Array = [[first, 0.0, 2]]
	p.append_array(LEG_BEND)
	return p


## EXACT, not tuned: the first piece is straight down, so lengthening it by d lowers everything after
## it by exactly d. Build once with a trial length, read the lowest vertex (in hip space, the vine
## hanging straight), and correct by the difference. One step, no iteration.
func _solve_leg_drop() -> float:
	var trial := 0.10
	var low := _lowest_leg_y(trial)
	return trial + (low + (HIP_Y - GROUND_EPS))


func _lowest_leg_y(first: float) -> float:
	var b := _hang_basis(_bend_dir(1.0, LEG_BEND_FWD_DEG))
	var mesh := vine_mesh(_leg_pieces(first), LEG_R.x, LEG_R.y, LEG_TAPER, 7)
	var low := INF
	for v: Vector3 in mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
		low = minf(low, (b * v).y)
	return low


## The lowest vertex of a leg (vine and thorns, in hip space) at every pitch in the table. Taken off
## the built meshes, so a thorn that dips lower than the bend at some pitch is included.
func _build_plant_table() -> void:
	var verts := PackedVector3Array()
	_collect_verts(_leg_r, Transform3D.IDENTITY, verts, true)
	var n := int(round(2.0 * PLANT_RANGE / PLANT_STEP)) + 1
	_plant_min.resize(n)
	for i in n:
		var p := -PLANT_RANGE + PLANT_STEP * float(i)
		var c := cos(p)
		var s := sin(p)
		var low := INF
		for v: Vector3 in verts:
			low = minf(low, v.y * c - v.z * s)
		_plant_min[i] = low


## Every mesh vertex under `node`, in `node`'s own space (`skip_self` ignores the node's transform).
static func _collect_verts(node: Node3D, xf: Transform3D, out: PackedVector3Array, skip_self: bool) -> void:
	var here := xf if skip_self else xf * node.transform
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		for v: Vector3 in (node as MeshInstance3D).mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
			out.append(here * v)
	for c: Node in node.get_children():
		if c is Node3D:
			_collect_verts(c as Node3D, here, out, false)


## The lowest leg vertex at `pitch`, linearly interpolated. The function is a minimum of sinusoids of
## amplitude <= R (the leg's reach, ~0.25 m), so the interpolation error is at most R * step^2 / 8,
## 28 microns at step 0.03: below anything a renderer can show.
func _plant_low(pitch: float) -> float:
	if _plant_min.is_empty():
		return -HIP_Y
	var f := (clampf(pitch, -PLANT_RANGE, PLANT_RANGE) + PLANT_RANGE) / PLANT_STEP
	var i := mini(int(floor(f)), _plant_min.size() - 2)
	return lerpf(_plant_min[i], _plant_min[i + 1], f - float(i))


## The side angle that MIRRORS a right-side thorn onto the left vine. `_hang_basis` keeps both vine
## frames right-handed, so the left frame's +X is the mirror image NEGATED while its bend axis is the
## plain mirror image: angle a on the right lands at (180 - a) on the left. Round 1 of this file used a
## on both sides, so the left arm's thorns pointed back into the stem.
static func _mirror_side(side_deg: float, sx: float) -> float:
	return side_deg if sx > 0.0 else 180.0 - side_deg


## A SOFT THORN on a vine built by `vine_mesh(pieces, r.x, r.y, taper)` in `parent` space, at arc
## fraction `f`, turned `side_deg` about the vine. It leans back toward the vine's base like a rose thorn.
func _add_vine_thorn(parent: Node3D, pieces: Array, r: Vector2, taper: float, f: float, side_deg: float,
		thorn_len: float, mat: Material) -> void:
	var smp := _vine_samples(pieces)
	var pts: PackedVector3Array = smp[0]
	var ang: PackedFloat32Array = smp[1]
	var arc: PackedFloat32Array = smp[2]
	var total := arc[arc.size() - 1]
	var s := f * total
	var i := 0
	while i < arc.size() - 2 and arc[i + 1] < s:
		i += 1
	var k := clampf((s - arc[i]) / maxf(arc[i + 1] - arc[i], 1e-6), 0.0, 1.0)
	var p := pts[i].lerp(pts[i + 1], k)
	var a := lerpf(ang[i], ang[i + 1], k)
	var tang := Vector3(0.0, cos(a), sin(a))
	var perp_a := Vector3.RIGHT
	var perp_b := perp_a.cross(tang)
	var sd := deg_to_rad(side_deg)
	var out := perp_a * cos(sd) + perp_b * sin(sd)
	var dir := (out - tang * 0.55).normalized()
	var vr := _vine_radius(r.x, r.y, taper, f)
	var node := _node("Thorn", parent, p + out * (vr * 0.55))
	node.basis = _basis_from_up(dir)
	var base_r := vr * 0.62
	_mi(taper_tube(thorn_len, base_r, base_r * THORN_TIP_K, 0.0, 3, 5), mat, node, Vector3.ZERO, "Cone")


# ============================================================================= head parts
func _build_bar_mouth() -> void:
	var mouth_node := _face.get_node_or_null("Mouth") as Node3D
	if mouth_node == null:
		return
	_orient_on_head(mouth_node, 0.0, MOUTH_PITCH_FEN, 0.004)
	if _mouth_smile != null and is_instance_valid(_mouth_smile):
		var dead := _mouth_smile
		_mouth_smile = null
		dead.visible = false
		dead.queue_free()
	var bar := _node("Bar", mouth_node, Vector3(0.0, 0.0, -0.004))
	_mi(rounded_box(MOUTH_BAR, 0.0055, 10), _toon(MOUTH, {"spec": 0.0, "rim": 0.0, "shade": 0.06}),
		bar, Vector3.ZERO, "Slot")
	# `_apply_face` closes the smile node out as the mouth opens, so the bar gives way to the open
	# mouth instead of being drawn across it.
	_mouth_smile = bar
	if _mouth_open != null:
		_mouth_open.position.y = 0.0


## The receptacle and every petal ring, all under one COLLAR node on the head, whose +Y is the tilted
## collar axis, +Z the back of the ring and +X the model's right.
func _build_collar() -> void:
	var tilt := deg_to_rad(COLLAR_TILT_DEG)
	var axis := Vector3(0.0, cos(tilt), -sin(tilt))
	_collar = _node("Collar", _head, COLLAR_CENTRE)
	_collar.basis = _basis_from_up(axis)
	var m_rec := _toon(CALYX, _matte(SURF_PETAL))
	_mi(lathe_mesh(PackedVector2Array(CUP_PROFILE), CUP_SIDES), m_rec, _collar, Vector3.ZERO, "Receptacle")
	var rings: Array = COLLARS[collar_style]
	for ri in rings.size():
		var ring: Dictionary = rings[ri]
		var m_petal := _toon(Color(String(ring["color"])), _matte(SURF_PETAL))
		var count := int(ring["count"])
		for k in count:
			var az := deg_to_rad(float(ring["phase"]) + 360.0 * float(k) / float(count))
			var alpha := _clear_alpha(ring, az)
			# An outer ring (listed first) stays RING_GAP_DEG outside the inner ring's solved angle, at
			# this azimuth AND at the two inner petals either side, which its blade overlaps. Checking
			# only the same azimuth let an inner side petal stand outside its steeper outer neighbour,
			# and the two scissored as soon as the collar flared (the round-2 probe: 132-956 crossings).
			for rj in range(ri + 1, rings.size()):
				var half := PI / float(int(rings[rj]["count"]))
				for off: float in [-half, 0.0, half]:
					alpha = maxf(alpha, _clear_alpha(rings[rj], az + off) + deg_to_rad(RING_GAP_DEG))
			var pivot := _node("Petal", _collar, _petal_origin(ring, az))
			pivot.basis = _petal_basis(az, alpha)
			var blade := _petal_blade(ring, az)
			_mi(blade, m_petal, pivot, Vector3.ZERO, "Blade")
			_petal_pivots.append(pivot)
			_petal_verts.append(blade.surface_get_arrays(0)[Mesh.ARRAY_VERTEX])
			_petal_rest.append(pivot.basis)
			_petal_az.append(az)


## How far round the ring toward the front a petal at azimuth `az` is: 0 at the back, 1 at the front.
static func _front(az: float) -> float:
	return 0.5 - 0.5 * cos(az)


static func _petal_origin(ring: Dictionary, az: float) -> Vector3:
	return Vector3(sin(az), 0.0, cos(az)) * float(ring["r0"]) + Vector3.UP * float(ring["lift"])


## Collar-space basis of a petal: +Y along the blade (`alpha` from the collar axis, out at azimuth
## `az`), +Z the outward side it curls toward, +X tangential (the flare hinge).
static func _petal_basis(az: float, alpha: float) -> Basis:
	var u := Vector3(sin(az), 0.0, cos(az))
	var d := Vector3.UP * cos(alpha) + u * sin(alpha)
	var w := Vector3.UP * -sin(alpha) + u * cos(alpha)
	return Basis(d.cross(w), d, w)


## Length and width fall off with the SQUARE of `_front`, so the side petals stay nearly as long as the
## back ones (they frame the face) and only the few under the chin are short.
static func _petal_blade(ring: Dictionary, az: float) -> ArrayMesh:
	var f := _front(az) * _front(az)
	return leaf_mesh(lerpf(float(ring["len_back"]), float(ring["len_front"]), f),
		lerpf(float(ring["w"]), float(ring.get("w_front", ring["w"])), f), PETAL_THICK,
		float(ring["c1"]), float(ring["c2"]), float(ring["cup"]), int(ring["nl"]), int(ring["nw"]),
		float(ring["fat"]))


## THE CLEARANCE SOLVE. The smallest cone angle, not below the ring's authored angle at `az`, at which
## every vertex of the petal's blade stays outside the bud grown by BUD_CLEAR, at every flare the petals
## can reach (the range `marker_clearance` bounds). A blade rooted below the bud moves away from it as
## it swings away from the axis, so a walk up in 2-degree steps finds the first passing angle and a
## bisection refines it to 0.1 degree. Solved, not tuned: no petal needs a hand-set angle to miss the
## head, and a change to the bud, the saucer or a blade re-solves itself.
func _clear_alpha(ring: Dictionary, az: float) -> float:
	# the SQUARE of `_front` again: the sides stand up round the face and only the front ring drops
	var authored := deg_to_rad(lerpf(float(ring["alpha_back"]), float(ring["alpha_front"]), _front(az) * _front(az)))
	var verts: PackedVector3Array = _petal_blade(ring, az).surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var origin := _petal_origin(ring, az)
	if _petal_clears(verts, origin, az, authored):
		return authored
	var lo := authored
	var hi := authored + deg_to_rad(2.0)
	while not _petal_clears(verts, origin, az, hi) and hi < PI * 0.95:
		lo = hi
		hi += deg_to_rad(2.0)
	while hi - lo > deg_to_rad(0.1):
		var mid := (lo + hi) * 0.5
		if _petal_clears(verts, origin, az, mid):
			hi = mid
		else:
			lo = mid
	return hi


## Flares sampled across the reachable range by `_petal_clears` (both ends included).
const CLEAR_FLARES := 5

func _petal_clears(verts: PackedVector3Array, origin: Vector3, az: float, alpha: float) -> bool:
	var cx := _collar.transform
	var rest := _petal_basis(az, alpha)
	var lo := minf(FLARE_THINK, 0.0) - PETAL_BREATHE - PETAL_DANCE
	var hi := FLARE_SURPRISED + PETAL_BREATHE + PETAL_DANCE
	var inv := Vector3(1.0 / BUD_SEMI.x, 1.0 / BUD_SEMI.y, 1.0 / BUD_SEMI.z)
	var lim := (1.0 + BUD_CLEAR) * (1.0 + BUD_CLEAR)
	for k in CLEAR_FLARES:
		var fl := lerpf(lo, hi, float(k) / float(CLEAR_FLARES - 1))
		var xf := cx * Transform3D(rest * Basis(Vector3.RIGHT, fl), origin)
		for v: Vector3 in verts:
			if ((xf * v) * inv).length_squared() < lim:
				return false
	return true


## Every petal vertex in HEAD space with the whole collar opened by `flare`.
func _petal_points(flare: float) -> PackedVector3Array:
	var pts := PackedVector3Array()
	var cx := _collar.transform
	for i in _petal_pivots.size():
		var xf := cx * Transform3D(_petal_rest[i] * Basis(Vector3.RIGHT, flare), _petal_pivots[i].position)
		for v: Vector3 in _petal_verts[i]:
			pts.append(xf * v)
	return pts


## The highest a collar vertex can stand above the bud's centre for any flare in [f0, f1] with the
## head tipped by at most `tilt` radians: a vertex at elevation e and distance r from the centre can
## rise no higher than r * sin(min(e + tilt, 90 deg)). The flare range is sampled every FLARE_STEP;
## between samples a vertex at radius <= R from its petal root moves at most R * step / 2, which is
## added, so the result is a bound and not an estimate.
const FLARE_STEP := 0.02

func _crown_rise(f0: float, f1: float, tilt: float) -> float:
	var top := 0.0
	var reach := 0.0
	var steps := maxi(1, int(ceil((f1 - f0) / FLARE_STEP)))
	for k in steps + 1:
		var fl := lerpf(f0, f1, float(k) / float(steps))
		for q: Vector3 in _petal_points(fl):
			var r := q.length()
			if r < 1e-5:
				continue
			top = maxf(top, r * sin(minf(asin(clampf(q.y / r, -1.0, 1.0)) + tilt, PI * 0.5)))
	for v: PackedVector3Array in _petal_verts:
		for p: Vector3 in v:
			reach = maxf(reach, p.length())
	return top + reach * (f1 - f0) / float(steps) * 0.5


## The worst body lift, squash and head tilt any state's TARGET pose asks for, read by running this
## model's own pose functions over 6 s of every state (a blended pose never exceeds its targets).
func _pose_extent() -> Vector3:
	var saved := [_state, _time, _stride_phase, _speed_factor, _look_pitch]
	var p := PackedFloat32Array()
	p.resize(P.COUNT)
	var ext := Vector3(0.0, 1.0, 0.0)
	_speed_factor = 1.0
	_look_pitch = -0.10                   # the widest look `_update_look` can roll
	for st: String in ["idle", "walk", "talk", "wave", "happy", "think", "surprised", "dance"]:
		_state = st
		for k in 180:
			var t := float(k) / 30.0
			_time = t * anim_time_scale
			_stride_phase = TAU * float(k) / 45.0
			_reset_pose(p)
			_compute_target(p, t)
			ext.x = maxf(ext.x, p[P.BODY_Y])
			ext.y = maxf(ext.y, p[P.SQUASH])
			ext.z = maxf(ext.z, absf(p[P.TORSO_PITCH]) + absf(p[P.TORSO_ROLL]) + absf(p[P.HEAD_PITCH])
				+ absf(p[P.HEAD_ROLL]))
	_state = saved[0]
	_time = saved[1]
	_stride_phase = saved[2]
	_speed_factor = saved[3]
	_look_pitch = saved[4]
	return ext


## The '!' must clear the petals in EVERY state. A TRUE upper bound with no tuned margin: the bud
## centre sits at `head_y` at rest (a torso pitch about the hip only lowers it), a pose lifts it by at
## most the worst hop, the collar rises at most `_crown_rise` above it over the whole flare range and
## the worst tilt, and `_root.scale.y` (squash) stretches everything about the feet. The bud's own
## crown is included, and so are the arm vines at their highest reach. Computed once, at build.
var _marker_clear := -1.0

func marker_clearance() -> float:
	if not _built:
		return head_y + head_semi.y
	if _marker_clear < 0.0:
		var ext := _pose_extent()
		var lo := minf(FLARE_THINK, 0.0) - PETAL_BREATHE - PETAL_DANCE
		var hi := FLARE_SURPRISED + PETAL_BREATHE + PETAL_DANCE
		var rise := maxf(_crown_rise(lo, hi, ext.z), head_semi.y)
		_marker_clear = ext.y * (head_y + ext.x + rise)
	return _marker_clear


## The collision capsule this body wants, in METRES: the radius is the widest the model reaches from
## its axis at rest (the collar's side petals), the height its highest point at rest.
func collision_size() -> Vector2:
	var pts := PackedVector3Array()
	_collect_verts(self, Transform3D.IDENTITY, pts, true)
	var r := 0.0
	var h := 0.0
	for p: Vector3 in pts:
		r = maxf(r, Vector2(p.x, p.z).length())
		h = maxf(h, p.y)
	return Vector2(r, h) * body_scale


# ============================================================================= animation
## THE SLOWEST BLINK IN THE CAST. Mirrors ChibiModel._update_blink with Fen's hold and lid rate.
func _update_blink(delta: float) -> void:
	if _blink_t > 0.0:
		_blink_t -= delta
	else:
		_blink_timer -= delta
		if _blink_timer <= 0.0 and _state != "surprised":
			_blink_t = SLOW_BLINK_HOLD
			_blink_timer = randf_range(3.0, 5.0) * maxf(blink_hold, 0.05)
	var want := 0.06 if _blink_t > 0.0 else 1.0
	_eye_open = lerpf(_eye_open, want, 1.0 - exp(-SLOW_LID_RATE * delta))


## A slight stoop at rest: an elder leaning into a long evening. The vines hang loose.
func _pose_idle(p: PackedFloat32Array) -> void:
	super._pose_idle(p)
	p[P.TORSO_PITCH] += 0.05
	p[P.HEAD_PITCH] -= 0.03
	p[P.ARM_L_ROLL] += VINE_HANG_ROLL - ARM_REST_ROLL
	p[P.ARM_R_ROLL] += VINE_HANG_ROLL - ARM_REST_ROLL


## A SHUFFLE. The leg vines swing a little, their bends barely lift, the body hardly bobs.
func _pose_walk(p: PackedFloat32Array) -> void:
	var ph := _stride_phase
	var s := sin(ph)
	var c := cos(ph)
	var amp := 0.22 * clampf(_speed_factor / 0.7, 0.0, 1.0)
	p[P.LEG_L_PITCH] = amp * s
	p[P.LEG_R_PITCH] = -amp * s
	p[P.LEG_L_LIFT] = 0.024 * clampf(c * 1.5, 0.0, 1.0)
	p[P.LEG_R_LIFT] = 0.024 * clampf(-c * 1.5, 0.0, 1.0)
	p[P.BODY_Y] = 0.010 * (0.5 + 0.5 * cos(2.0 * ph))
	p[P.SQUASH] = 1.0 + 0.012 * cos(2.0 * ph)
	p[P.TORSO_ROLL] = 0.05 * c
	p[P.TORSO_YAW] = -0.06 * s
	p[P.TORSO_PITCH] = 0.10
	p[P.HEAD_ROLL] = -0.04 * c
	p[P.HEAD_YAW] = 0.03 * s
	p[P.HEAD_PITCH] = -0.05
	p[P.ARM_L_PITCH] = 0.30 * s
	p[P.ARM_R_PITCH] = -0.30 * s
	p[P.ARM_L_ROLL] = VINE_HANG_ROLL + 0.06
	p[P.ARM_R_ROLL] = VINE_HANG_ROLL + 0.06


## Every gesture below keeps the vines UNDER the collar: the petals stand out from the neck at
## shoulder height and above, so a vine raised above the shoulder would sweep through them. The vines
## swing out and forward below the rim instead, and the curled tips do the rest. The probe numbers in
## the scratch report (arm-collar crossings, every state and every blend) are what these were set by.

## Talk: the right vine swings forward under the collar and its curled tip gestures; the left hangs.
func _pose_talk(p: PackedFloat32Array, t: float) -> void:
	super._pose_talk(p, t)
	p[P.ARM_L_ROLL] = VINE_HANG_ROLL + 0.04 * sin(TAU * t * 0.9 + 1.0)
	p[P.ARM_L_PITCH] = 0.0
	p[P.ARM_R_ROLL] = TALK_ARM.y + 0.10 * sin(TAU * t * 1.15)
	p[P.ARM_R_PITCH] = TALK_ARM.x + 0.18 * sin(TAU * t * 1.7)
	p[P.ARM_R_YAW] = 0.0


## Wave: the right vine goes straight out at shoulder height and a little forward, under the side
## petals (WAVE_ARM), and swings side to side there, so the upturned tip does the waving. The roll only
## dips BELOW WAVE_ARM, never above it: above is where the petals are.
func _pose_wave(p: PackedFloat32Array, t: float) -> void:
	super._pose_wave(p, t)
	var w := sin(TAU * t * 2.4)
	p[P.ARM_R_PITCH] = wave_arm.x
	p[P.ARM_R_ROLL] = wave_arm.y - 0.16 * (0.5 + 0.5 * w)
	p[P.ARM_R_YAW] = wave_arm.z + 0.30 * w
	p[P.ARM_L_ROLL] = VINE_HANG_ROLL
	p[P.ARM_L_PITCH] = 0.0


## Happy: a small glad bounce, both vines swing out and a little forward, and the collar opens.
func _pose_happy(p: PackedFloat32Array, t: float) -> void:
	super._pose_happy(p, t)
	p[P.BODY_Y] *= HOP_SCALE
	p[P.SQUASH] = 1.0 + (p[P.SQUASH] - 1.0) * HOP_SCALE
	p[P.LEG_L_LIFT] *= HOP_SCALE
	p[P.LEG_R_LIFT] *= HOP_SCALE
	p[P.LEG_L_PITCH] *= HOP_SCALE
	p[P.LEG_R_PITCH] *= HOP_SCALE
	p[P.ARM_L_ROLL] = HAPPY_ARM.y + 0.14 * sin(TAU * t * 2.2)
	p[P.ARM_R_ROLL] = HAPPY_ARM.y - 0.14 * sin(TAU * t * 2.2)
	p[P.ARM_L_PITCH] = HAPPY_ARM.x
	p[P.ARM_R_PITCH] = HAPPY_ARM.x
	p[P.ARM_L_YAW] = 0.0
	p[P.ARM_R_YAW] = 0.0


## Dance keeps the chibi's sway, with the vines swinging out and forward in turn, below the collar.
func _pose_dance(p: PackedFloat32Array, t: float) -> void:
	super._pose_dance(p, t)
	var alt := sin(TAU * t)
	p[P.ARM_L_ROLL] = DANCE_ARM.y + 0.25 * alt
	p[P.ARM_R_ROLL] = DANCE_ARM.y - 0.25 * alt
	p[P.ARM_L_PITCH] = DANCE_ARM.x + 0.25 * alt
	p[P.ARM_R_PITCH] = DANCE_ARM.x - 0.25 * alt
	p[P.ARM_L_YAW] = 0.0
	p[P.ARM_R_YAW] = 0.0


## Surprise: the collar flies open (see `_animate_extras`), the vines fling out; no jump.
func _pose_surprised(p: PackedFloat32Array, t: float) -> void:
	super._pose_surprised(p, t)
	p[P.BODY_Y] *= HOP_SCALE
	p[P.SQUASH] = 1.0 + (p[P.SQUASH] - 1.0) * HOP_SCALE
	p[P.ARM_L_ROLL] = SURPRISED_ARM.y
	p[P.ARM_R_ROLL] = SURPRISED_ARM.y
	p[P.ARM_L_PITCH] = SURPRISED_ARM.x
	p[P.ARM_R_PITCH] = SURPRISED_ARM.x
	p[P.ARM_L_YAW] = 0.0
	p[P.ARM_R_YAW] = 0.0


## Think: the right vine comes round in front of the body and its curled tip rises to the chin, over
## the front petals; the head tips (the chibi's think) and the petals close a little.
func _pose_think(p: PackedFloat32Array, t: float) -> void:
	super._pose_think(p, t)
	p[P.ARM_L_ROLL] = VINE_HANG_ROLL
	p[P.ARM_L_PITCH] = 0.0
	# In two steps: the vine lifts out to the side under the side petals first, THEN swings round to
	# the front. A straight blend of all three angles cut through the front petals on the way.
	var u := clampf(t / 0.4, 0.0, 1.0)
	var v := clampf((t - 0.3) / 0.4, 0.0, 1.0)
	p[P.ARM_R_PITCH] = THINK_ARM.x * u
	p[P.ARM_R_ROLL] = VINE_HANG_ROLL + (THINK_ARM.y - VINE_HANG_ROLL) * u
	p[P.ARM_R_YAW] = THINK_ARM.z * v


func _animate_extras(delta: float) -> void:
	_t += delta
	# GROUND CONTACT, exact rather than tuned: lift each leg by exactly what its pitch would push the
	# lowest vertex under the ground, or by the pose's own lift if that is more.
	_plant_leg(_leg_l, pose(P.LEG_L_PITCH), pose(P.LEG_L_LIFT), -HIP_X)
	_plant_leg(_leg_r, pose(P.LEG_R_PITCH), pose(P.LEG_R_LIFT), HIP_X)

	# PETALS: breathe at rest, part a little while talking, open for happy / dance, widest for surprise.
	var want := FLARE_TALK * clampf(pose(P.EXTRA_A), 0.0, 1.0)
	match _state:
		"happy", "dance":
			want = FLARE_OPEN
		"surprised":
			want = FLARE_SURPRISED
		"think":
			want = FLARE_THINK
	_flare = lerpf(_flare, want, 1.0 - exp(-(9.0 if _state == "surprised" else 3.5) * delta))
	for i in _petal_pivots.size():
		# A WAVE ROUND THE RING, not a random phase per petal: neighbours stay within ~0.01 rad of
		# each other, so two overlapping petals never scissor through one another (a per-petal
		# 1.37 rad phase step made adjacent blades cross 100+ times a second in the probe).
		var ph := _petal_az[i]
		var breathe := PETAL_BREATHE * sin(TAU * _t / 3.6 + ph)
		var dance := 0.0
		if _state == "dance":
			dance = PETAL_DANCE * sin(TAU * _state_time * 1.0 + ph)
		_petal_pivots[i].basis = _petal_rest[i] * Basis(Vector3.RIGHT, _flare + breathe + dance)


func _plant_leg(leg: Node3D, pitch: float, lift: float, hip_x: float) -> void:
	if leg == null:
		return
	var need := -HIP_Y + GROUND_EPS - _plant_low(pitch)
	leg.position = Vector3(hip_x, HIP_Y + maxf(lift, need), 0.0)


# ============================================================================= primitives
## A VINE — `taper_tube` with a heading that changes piece by piece, so one tube can hang straight,
## round a bend and then curl up tightly at its end. `pieces` is a list of [arc length, total turn,
## segments]; within a piece the heading turns linearly. The radius runs from r0 to r1 as
## r1 + (r0 - r1) * (1 - u)^taper along the arc (u = 0..1): taper < 1 keeps the vine thick for most of
## its length and draws it to a point near the end. The tip is capped at r1 (a soft point, not a
## needle). Same frame, winding and caps as `taper_tube`.
static func vine_mesh(pieces: Array, r0: float, r1: float, taper: float, sides: int = 7) -> ArrayMesh:
	var key := "fenvine|%s|%.4f|%.4f|%.3f|%d" % [str(pieces), r0, r1, taper, sides]
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var smp := _vine_samples(pieces)
	var pts: PackedVector3Array = smp[0]
	var ang: PackedFloat32Array = smp[1]
	var arc: PackedFloat32Array = smp[2]
	var total := arc[arc.size() - 1]
	var n := pts.size()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in n:
		var a := ang[i]
		var tang := Vector3(0.0, cos(a), sin(a))
		var n1 := Vector3.RIGHT
		var n2 := n1.cross(tang)
		var r := _vine_radius(r0, r1, taper, arc[i] / total)
		var i0 := maxi(i - 1, 0)
		var i1 := mini(i + 1, n - 1)
		var slope := (_vine_radius(r0, r1, taper, arc[i1] / total) - _vine_radius(r0, r1, taper, arc[i0] / total)) \
			/ maxf(arc[i1] - arc[i0], 1e-5)
		for j in sides + 1:
			var b := TAU * float(j) / float(sides)
			var radial := n1 * cos(b) + n2 * sin(b)
			st.set_normal((radial - tang * slope).normalized())
			st.set_uv(Vector2(arc[i] / total, float(j) / float(sides)))
			st.add_vertex(pts[i] + radial * r)
	for i in n - 1:
		for j in sides:
			var a2 := i * (sides + 1) + j
			var b2 := (i + 1) * (sides + 1) + j
			st.add_index(a2)
			st.add_index(b2 + 1)
			st.add_index(b2)
			st.add_index(a2)
			st.add_index(a2 + 1)
			st.add_index(b2 + 1)
	var used := n * (sides + 1)
	used += _taper_cap(st, used, pts[0], r0, 0.0, sides, false)
	_taper_cap(st, used, pts[n - 1], r1, ang[n - 1], sides, true)
	var mesh := st.commit()
	_mesh_cache[key] = mesh
	return mesh


static func _vine_radius(r0: float, r1: float, taper: float, u: float) -> float:
	return r1 + (r0 - r1) * pow(clampf(1.0 - u, 0.0, 1.0), taper)


## The vine's centreline: [points, heading at each point, arc length at each point].
static func _vine_samples(pieces: Array) -> Array:
	var pts := PackedVector3Array([Vector3.ZERO])
	var ang := PackedFloat32Array([0.0])
	var arc := PackedFloat32Array([0.0])
	var p := Vector3.ZERO
	var a := 0.0
	var s := 0.0
	for pc: Array in pieces:
		var ln := float(pc[0])
		var turn := float(pc[1])
		var segs := maxi(1, int(pc[2]))
		var step := ln / float(segs)
		for i in segs:
			# heading sampled at the MIDDLE of each step, so the polyline sits on the arc
			var am := a + turn * (float(i) + 0.5) / float(segs)
			p += Vector3(0.0, cos(am), sin(am)) * step
			pts.append(p)
			ang.append(a + turn * float(i + 1) / float(segs))
			s += step
			arc.append(s)
		a += turn
	return [pts, ang, arc]


## A SOLID OF REVOLUTION about +Y: `profile` is one closed loop of [radius, height] points, turned
## through `sides` steps. Smooth normals (the profile is rounded). Winding is decided per triangle
## against the loop's outward normal, the same rule as `_leaf_tri`. Triangles: 2 * points * sides.
static func lathe_mesh(profile: PackedVector2Array, sides: int) -> ArrayMesh:
	var key := "fenlathe|%s|%d" % [str(profile), sides]
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var n := profile.size()
	# the loop's orientation (shoelace sign) says which side of each edge is outside
	var area := 0.0
	for i in n:
		var a := profile[i]
		var b := profile[(i + 1) % n]
		area += a.x * b.y - b.x * a.y
	var sgn := 1.0 if area > 0.0 else -1.0
	var pn := PackedVector2Array()   # outward 2D normal at each profile point (average of its edges)
	for i in n:
		var e0 := profile[i] - profile[(i + n - 1) % n]
		var e1 := profile[(i + 1) % n] - profile[i]
		var t := (e0.normalized() + e1.normalized()).normalized()
		pn.append(Vector2(t.y, -t.x) * sgn)
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	for j in sides + 1:
		var az := TAU * float(j) / float(sides)
		var u := Vector3(sin(az), 0.0, cos(az))
		for i in n:
			verts.append(u * profile[i].x + Vector3.UP * profile[i].y)
			norms.append((u * pn[i].x + Vector3.UP * pn[i].y).normalized())
	var idx := PackedInt32Array()
	for j in sides:
		for i in n:
			var a0 := j * n + i
			var a1 := j * n + (i + 1) % n
			var b0 := (j + 1) * n + i
			var b1 := (j + 1) * n + (i + 1) % n
			_leaf_tri(idx, verts, norms, a0, b0, b1)
			_leaf_tri(idx, verts, norms, a0, b1, a1)
	var arr: Array = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = norms
	arr[Mesh.ARRAY_INDEX] = idx
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	_mesh_cache[key] = am
	return am


## A CLOSED, CURVED LEAF (petal). The centreline starts at the origin along +Y and turns
## toward +Z with heading a(t) = c1*t + c2*t^2 (t = 0..1). `cup` lifts the edges toward +N, the two
## faces bulge apart by `thick` along the midrib and MEET at the rim, base and tip, so it is a closed
## lens-section solid, never a double-sided quad (`toon_soft` is `cull_back`). `fat` moves the widest
## point: < 1 toward the base (a pointed petal), > 1 toward the tip (a round daisy ray).
## Triangles: 4 * nl * nw.
static func leaf_mesh(length: float, width: float, thick: float, c1: float, c2: float = 0.0,
		cup: float = 0.0, nl: int = 7, nw: int = 3, fat: float = 1.0) -> ArrayMesh:
	var key := "fenvleaf|%.4f|%.4f|%.4f|%.3f|%.3f|%.3f|%d|%d|%.2f" % [length, width, thick, c1, c2,
		cup, nl, nw, fat]
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	nl = maxi(nl, 2)
	nw = maxi(nw, 1)
	var cols := nw * 2
	var pts := _leaf_path(length, c1, c2, nl)
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var uvs := PackedVector2Array()
	for side in 2:
		var sgn := 1.0 if side == 0 else -1.0
		for i in nl + 1:
			var t := float(i) / float(nl)
			var a := c1 * t + c2 * t * t
			var tang := Vector3(0.0, cos(a), sin(a))
			var nn := Vector3.RIGHT.cross(tang)
			var prof := pow(maxf(sin(PI * pow(t, fat)), 0.0), 0.6)
			var hw := width * 0.5 * prof
			for j in cols + 1:
				var u := -1.0 + 2.0 * float(j) / float(cols)
				var bulge := thick * 0.5 * (1.0 - u * u) * sqrt(prof)
				verts.append(pts[i] + Vector3.RIGHT * (hw * u) + nn * (cup * hw * u * u + bulge * sgn))
				var nrm := (nn - Vector3.RIGHT * (2.0 * cup * u)).normalized()
				nrm = (nrm * sgn + Vector3.RIGHT * (u * 0.35)).normalized()
				norms.append(nrm)
				uvs.append(Vector2(0.5 + 0.5 * u, t))
	var idx := PackedInt32Array()
	var row := cols + 1
	var per_side := (nl + 1) * row
	for side in 2:
		var base := side * per_side
		for i in nl:
			for j in cols:
				var a0 := base + i * row + j
				var b0 := base + (i + 1) * row + j
				_leaf_tri(idx, verts, norms, a0, b0, b0 + 1)
				_leaf_tri(idx, verts, norms, a0, b0 + 1, a0 + 1)
	var arr: Array = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = norms
	arr[Mesh.ARRAY_TEX_UV] = uvs
	arr[Mesh.ARRAY_INDEX] = idx
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	_mesh_cache[key] = am
	return am


static func _leaf_path(length: float, c1: float, c2: float, nl: int) -> PackedVector3Array:
	var pts := PackedVector3Array()
	pts.resize(nl + 1)
	var p := Vector3.ZERO
	pts[0] = p
	var step := length / float(nl)
	for i in range(1, nl + 1):
		var tm := (float(i) - 0.5) / float(nl)
		var am := c1 * tm + c2 * tm * tm
		p += Vector3(0.0, cos(am), sin(am)) * step
		pts[i] = p
	return pts


## Winding decided per triangle against the intended outward normal (Godot's front face has
## (b-a) x (c-a) pointing INWARD).
static func _leaf_tri(idx: PackedInt32Array, verts: PackedVector3Array, norms: PackedVector3Array,
		a: int, b: int, c: int) -> void:
	var cr := (verts[b] - verts[a]).cross(verts[c] - verts[a])
	var outward := norms[a] + norms[b] + norms[c]
	idx.append(a)
	if cr.dot(outward) > 0.0:
		idx.append(c)
		idx.append(b)
	else:
		idx.append(b)
		idx.append(c)


## `_matte()` fills defaults into a COPY, so option dicts compose cleanly; this is just the merge.
static func _merged(base: Dictionary, extra: Dictionary) -> Dictionary:
	var o := base.duplicate()
	for k: Variant in extra:
		o[k] = extra[k]
	return o
