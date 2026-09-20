class_name PopFluffModel
extends ChibiModel
## Pop, Cosmo Depot's bigger twin — REBUILT 2026-09-15 as a FUZZY MONSTER, variant A: "the fluff ball".
##
## The user, on the shipped twins: "the two small green / yellow ish aliens ... need improvements", and
## for Pop specifically: "Fuzzy monster alien with sharp teethy smile". This file is that, and it
## replaces the Pop half of `TwinModel` outright — the slab head, raked almonds, paddle blades, horns
## and belly plate are all gone. Pip is being rebuilt at the same time as a tiny saucer pilot, so the
## pair no longer has to be told apart by proportion tricks: one is a bug-eyed kid in a flying dish and
## the other is a big round armful of fur. That difference survives a black cut-out at 8 m.
##
## WHAT HE IS, SHAPE FIRST (the order it reads in at gameplay distance):
##   silhouette  one ROUND fluffy mass — a big head overhanging a bigger belly, the join hidden under
##               a jaw ruff — on two stubby furry feet, with two thin feelers ending in fuzzy poms
##   outline     RAGGED: tiers of hanging fur fins around the crown, the jaw, the belly and shoulders.
##               Nobody else in the cast has a broken outline now that Pip gives up his fur.
##   face        two small round bead eyes, NO sclera, NO brows; a pale smooth muzzle; and across it a
##               wide SMILE-SHAPED grin (corners up) with a row of small rounded-point teeth
##   manner      clumsy: a bigger waddle than anyone, feelers that flop a beat behind the body
##   uniform     a teal-slate shop satchel across the body with the Cosmo Depot badge on the pouch —
##               he is a shopkeeper, and the strap is also what keeps a round fur ball from reading as
##               any film's forest spirit
##
## DIALOGUE-LOCKED (npc_data.gd, "pop"): exactly TWO antennae — "Two antennae. Double the listening!",
## "Two antennae, two opinions. Both mine.", "I hear twice as well." — so the two feelers are the
## brief's "antenna-like fuzzy feelers" and never ears; they rise off the crown on thin stalks, not
## from the sides of the head. He is Pip's BROTHER (the one gender stated in shipped text) and nothing
## here adds to that. Clumsy is written for him ("I dropped a crate", "the lamp rolled away"), which is
## what the waddle and the flopping feelers are acting.
##
## CAST_VARIETY SLOTS HE HOLDS (docs/CAST_VARIETY.md, the 2026-09-15 shared slot plan):
##   * the WIDE TOOTHY GRIN — one of two, with Grig. Fen gives his up. Grig's is an under-bite with a
##     corner tusk in a rounded-rectangle cavity; this is a CRESCENT with its corners turned up and a
##     top row of small points — a smile, where Grig's is a bite.
##   * `sd_foliage` AND real fur fringe geometry — taken over from Pip, who gives both up.
##   * he gives up "no surface pattern" to Pip.
##   * HARD VOCABULARY: NONE. The horns are gone (-1 from the cast total). The teeth are counted as the
##     grin slot, not as fangs: there are eleven of them, none longer than 32 mm, no canine pair stands
##     out of the row, and the tips are rounded. If a critic reads them as fangs he is at 1 of 2.
##   * no lashes, no brow ridge, no heavy lid.
##
## Origin at the feet, facing -Z, ~1.21 m to the crown and ~1.49 m to the pom tips at body_scale 1.0.

# ---------------------------------------------------------------------------------------- palette
## R2.6, MEASURED ON HIS OWN CROPS, NOT AUTHORED BLIND. Fur renders MORE saturated than its albedo:
## the toon terminator and sd_foliage's clump shading darken the fins' undersides and the tiers shade
## each other, and "dark does not mean saturated" is exactly the trap. Two builds, same camera:
##   #c1ca70 (Pop's shipped body, S 0.45 V 0.79)  -> head crop value mean 0.806: washed-out pale yellow
##   #a4b05c (S 0.48 V 0.69)                      -> body crop sat mean 0.58, dominant swatch S 0.71 (FAIL)
##   #a8b36f (S 0.38 V 0.70)                      -> Forward+ body crop: dominant swatch S 0.59, no margin
##   #a9b374 (S 0.35 V 0.70), this one            -> rendered/albedo saturation runs ~1.4x on fur, so
##                                                   S 0.35 is the value with margin under S 0.60 on
##                                                   BOTH renderers (numbers in the pop-fuzzy report)
## The first pass was olive-chartreuse; the user asked for orange (2026-09-15), so the fur is apricot now.
## His name-pill accent in `npc_data.gd` ("#b8c93a") is unchanged. The only darker-than-V 0.25 colours are the
## eye ink and the grin cavity, which is what the gate exempts.
const FUR := Color("#b28b6d")        ## 2026-09-19: apricot orange, the user's "Pop orange" (he read cinnamon brown at V 0.70).
## Rendered close-up #cc9056 (H29 S0.57-0.59 V0.80) on both renderers; dE76 15.0-16.2 from Grig's head and 19-20
## degrees from Norm's tentacle. V had to go up to kill the brown and S with it to keep the gap to Grig (raising V
## alone fell to dE 3.5). One 6-9% shadow-band swatch renders S 0.61; accepted with the gold trophy (OPEN_ISSUES 63).
## THE FUR FINS ARE NOT THE BODY COLOUR, for the reason Pip's file recorded when his first ruff
## "rendered as nothing": a silhouette cue needs a VALUE step. Paler and softer than the body.
const FUR_TIP := Color("#bf9b80")    ## moved with FUR: a half-step paler and less saturated, so the fringe reads as a lighter tier
const FUR_DEEP := Color("#a68c79")   ## moved with FUR so the legs and stalks read dark orange, not dark brown; low chroma on purpose
const MUZZLE := Color("#c9c29a")     ## S 0.234 V 0.788 — smooth, no pattern: the grin needs a clean ground
const PAD := Color("#b98f86")        ## S 0.274 V 0.725 — toe beans and palm pads, the warm note
const POM := Color("#a99bbd")        ## S 0.180 V 0.741 — dusty lilac: the only cool accent he wears
const EYE := Color("#231e2a")
const GRIN := Color("#3b2a30")       ## V 0.231 — the mouth cavity
const TOOTH := Color("#e6e0cf")      ## V 0.902 but S 0.10 and ~2 % of his area; no near-clipping white
const TONGUE := Color("#c9868f")     ## S 0.333 V 0.788
const BLUSH := Color("#c9998f")      ## S 0.289 V 0.788 — restrained, per R2.3
const APRON := Color("#6f8f92")      ## S 0.239 V 0.573 — the old paddle teal, now his shop cloth
const APRON_TRIM := Color("#55696b") ## S 0.204 V 0.420
const BADGE := Color("#d9b96e")      ## the shared Cosmo Depot star colour (TwinModel.STAR)

## sd_foliage, Pip's measured settings carried over with his fur (twin_model.gd PIP_SURF_HEAD): at
## scale 2.6 the clump octave is 60 mm and the tuft octave 13 mm — a fine even nap that survives to
## conversation range and fades cleanly by gameplay range. Scale 0.9 rendered as mould on him.
const SURF_FUR := {"surface": "foliage", "surface_scale": 2.6, "surface_strength": 0.42,
	"surface_near": 8.0, "surface_far": 22.0}
## Finer and weaker on the small curved limbs, where a head-sized nap reads as cauliflower.
const SURF_LIMB := {"surface": "foliage", "surface_scale": 3.6, "surface_strength": 0.34,
	"surface_near": 6.0, "surface_far": 18.0}

# ---------------------------------------------------------------------------------------- body
## The belly is WIDER than the default bean in both plan axes and a touch taller, so the body is a
## ball, not a bean: semi (0.284, 0.240, 0.232), spanning y 0.160..0.640.
const TORSO_MUL := Vector3(1.28, 1.02, 1.22)
## A round, soft head — n 2.35 is the roundest exponent in the cast (Pip's old 2.8 was), because a
## fur ball with chamfered planes reads as a box with hair on it. Slightly wider than tall (1.22:1).
const HEAD_SEMI_POP := Vector3(0.365, 0.300, 0.325)
const HEAD_N_POP := 2.35
## Chin seated 35 mm into the belly top (0.640), so the jaw ruff has a real join to hide.
const HEAD_Y_POP := 0.905
const HEAD_SEGS_POP := Vector2i(40, 20)
## Feet planted wider than the shared HIP_X (offset on the leg MESHES — see `_build_feet`).
const STANCE_X := 0.034

# ---------------------------------------------------------------------------------------- face
## Eyes: small ROUND beads (w 0.034 x h 0.038 — 9.3 % of head width, 12.7 % of head height), set at
## yaw 18 so the centres land ~28 % of head width apart as rendered. No sclera (R2.3), no brows.
const EYE_SPEC := {"w": 0.034, "h": 0.038, "d": 0.018}
const EYE_YAW_POP := 18.0
const EYE_PITCH_POP := 5.0
## The grin, in the Mouth node's frame (-Z out of the face). Full width 0.250 m = 34 % of the 0.730 m
## head — over the chibi 16-25 % band on purpose: this IS the capped wide-grin slot, and a toothy smile
## narrower than a third of the face reads as a snarl through a gap, not as a grin.
const GRIN_HALF_W := 0.125
const GRIN_DEPTH := 0.070            ## centre drop from the lip line
const GRIN_CORNER := 0.024           ## how far the corners turn UP — the whole of "friendly"
## THE MUZZLE AND GRIN ARE PAINTED ONTO THE HEAD'S OWN SURFACE, NOT STUCK ON IT (round 2 of the
## 2026-09-15 critic). Round 1 used `_add_muzzle`: a flat 380 mm rounded card. From the front it was
## fine; from 3/4 and the side it was a pasted-on mask with a hard edge that broke the head outline,
## and the grin, teeth and tongue rode 42-53 mm proud of the shell (critic's vertex probe) — three
## times the eyes' 18 mm. Now every vertex of the muzzle, the cavity, each tooth and the tongue is
## placed by `_face_pt`: a point in a tangent plane at the muzzle centre, projected onto the real
## superellipsoid, then lifted along its normal by a soft LENS — a parabolic swell that is
## `MUZZLE_H` at the centre and sinks under the fur at its rim. So the muzzle curves with the head,
## has no edge to show side-on, and the grin follows it round the cheeks.
const MUZZLE_PITCH := -19.0          ## the muzzle's centre on the head (deg below the equator)
const MUZZLE_RX := 0.165             ## lens half-width in the tangent plane (m); the visible edge is 0.84 of it
const MUZZLE_RY := 0.100             ## lens half-height; stops below the eyes (pitch +5)
const MUZZLE_H := 0.010              ## swell at the centre — a soft snout, 10 mm, under the eyes' 18
## THE RIM IS ABOVE THE ANALYTIC SHELL, NOT UNDER IT. A first build sank the rim 3 mm and let the shell
## cut the edge; the shell MESH is faceted (24 x 12 at DETAIL 0.6) and sits up to ~5 mm inside the
## analytic surface between its vertices, so the edge rendered as a ragged splotch. So the lens ends
## 1.5 mm proud on a clean ellipse and a short skirt drops 7 mm straight into the head under it:
## whatever the facets do, the visible edge is the ellipse.
const MUZZLE_EDGE := 0.0015
const MUZZLE_SKIRT := 0.007
const LIP_Y := 0.020                 ## the grin's lip line, above the muzzle centre (m)
const CAVITY_LIFT := 0.002           ## the cavity is a decal 2 mm off the muzzle ...
const CAVITY_SINK := 0.012           ## ... with its back sunk into the head, so no facet dip opens a gap
const TOOTH_LIFT := 0.003            ## tooth axis, just in front of the cavity
const TOOTH_FLAT := 0.45             ## teeth are flattened against the face in depth (never lengthened)
const GRIN_COLS := 18
## Mouth animation rebuilds the conformal cavity at these steps (a 70 mm mouth moves 1.4 mm a step).
const GRIN_Q := 0.02
## TEETH: [u across the grin (-1..1), full width, length]. Top row hangs from the lip line; small,
## slightly uneven, all the same KIND. The longest is 32 mm against a 70 mm mouth: a row of points, not
## a pair of fangs. Two short ones stand up from the lower edge so it reads as a mouthful of teeth.
const TOP_TEETH: Array = [[-0.64, 0.026, 0.024], [-0.38, 0.030, 0.030], [-0.13, 0.030, 0.032],
	[0.13, 0.030, 0.032], [0.38, 0.030, 0.029], [0.64, 0.026, 0.023]]
const LOW_TEETH: Array = [[-0.46, 0.024, 0.019], [0.46, 0.024, 0.019]]

# ---------------------------------------------------------------------------------------- feelers
## Two feelers, seated on the crown at yaw +/-30, pitch 60 — well inboard of the head's width, so they
## stand UP out of the fluff like antennae and can never read as a pair of ears at the temples.
const FEELER_YAW := 30.0
const FEELER_PITCH := 60.0
const FEELER_LEN := 0.250
const FEELER_CURL := 0.55            ## total bend, backward: the tips nod over the crown
const POM_R := 0.050
## SOFT POMS (round 2): 22 long thin spikes (42 mm, base 23 mm) read as little maces at conversation
## range. Now 48 stubby, broad-based tufts (16 mm long, base 24 mm) — a fuzzy ball, not a spiked one.
const POM_FIN := 0.016
const POM_FINS := 48
const POM_FIN_W := 1.5

var _feelers: Array[Node3D] = []
var _mouth: Node3D
var _cavity: MeshInstance3D
var _teeth: Array = []                 ## [node, u, width, length, top] per tooth
var _tongue: Node3D
## The muzzle's tangent frame on the head: centre ON the shell, right, and up along the surface.
var _mz_c := Vector3.ZERO
var _mz_t := Vector3.RIGHT
var _mz_u := Vector3.UP
var _grin_key := ""
var _grin_meshes: Dictionary = {}
var _skirt: Node3D                     ## belly fur, lags the waddle
var _t: float = 0.0
var _feeler_lag: float = 0.0
var _last_body_y: float = 0.0


func _init() -> void:
	super()
	body_scale = 1.0
	head_semi = HEAD_SEMI_POP
	head_n = HEAD_N_POP
	head_y = HEAD_Y_POP
	head_segs = HEAD_SEGS_POP
	eye_w = EYE_SPEC["w"]
	eye_h = EYE_SPEC["h"]
	eye_d = EYE_SPEC["d"]
	# A SLOW blink and slow time: the big, unhurried brother.
	blink_hold = 1.5
	anim_time_scale = 0.94
	_time = 0.85


func _build_geometry() -> void:
	_feelers.clear()
	_teeth.clear()
	_grin_key = ""
	_grin_meshes.clear()
	_add_torso_bean(FUR, _merged(SURF_FUR, {"size_mul": TORSO_MUL, "waist_chamfer": false}))
	_seat_shoulders()
	_add_arms(FUR, FUR_TIP, 0, SURF_LIMB, SURF_LIMB)
	_build_paw_pads()
	_build_feet()
	# NO CROWN SEAM: a hard chamfer rim is exactly what a fur ball must not have.
	_add_head_shell(FUR, _merged(SURF_FUR, {"crown_seam": false}))
	_build_muzzle()
	var eyes: Array = []
	for sx: float in [-1.0, 1.0]:
		eyes.append({"yaw": EYE_YAW_POP * sx, "pitch": EYE_PITCH_POP, "brow": false, "fit_expr": true})
	# The shared mouth is OFF: `_apply_face` would draw a smile arc and an open ellipse over the grin.
	# The grin owns talking instead (see `_animate_mouth`). The blush is built here, not by `_add_face`,
	# because the shared BLUSH_PITCH -13 lands it on the grin's upturned corners.
	_add_face(EYE, GRIN, BLUSH, {"eyes": eyes, "nose": false, "mouth": false, "blush": false,
		"brows": false})
	_build_blush()
	_build_grin()
	_build_fur()
	_build_feelers()
	_build_satchel()


# ============================================================================= body parts
## The shared SHOULDER const is cut for an unscaled bean; on a 1.28-wide belly it would bury the arm
## roots inside the fur. `rebuild()` seats these nodes and `_apply_pose` only writes ROTATION, so a
## position written here survives every frame (TwinModel `_seat_shoulders`, same reasoning).
func _seat_shoulders() -> void:
	var y := TORSO_Y + TORSO_RY * TORSO_MUL.y * ((SHOULDER.y - TORSO_Y) / TORSO_RY)
	_arm_l.position = Vector3(-SHOULDER.x * TORSO_MUL.x, y, SHOULDER.z)
	_arm_r.position = Vector3(SHOULDER.x * TORSO_MUL.x, y, SHOULDER.z)


## A pale PALM PAD on each mitt, facing forward and a little in — it is what turns a green mitten into
## a paw at conversation range, and it costs 2 x 40 tris.
func _build_paw_pads() -> void:
	var m_pad := _toon(PAD, _matte({"spec": 0.02}))
	for side: Array in [[-1.0, _hand_l], [1.0, _hand_r]]:
		var hand: Node3D = side[1]
		if hand == null:
			continue
		var pad := _mi(superellipsoid(Vector3(0.040, 0.044, 0.018), 2.4, 10, 6), m_pad, hand,
			Vector3(-0.016 * float(side[0]), -0.010, -HAND_R * 0.80), "PalmPad")
		pad.rotation.y = 0.30 * float(side[0])


## FURRY FEET, not boots. `_add_legs` builds a shoe with a sole plate and a toe cap, which on a monster
## reads as footwear. These are a short leg stub and a round squat foot with three toe beans on the
## front edge. The foot's flat underside is exactly at model y 0 at rest: the leg pivot sits at HIP_Y
## 0.245 and the foot's centre at local -0.245 + FOOT_SEMI.y.
##
## THE STANCE IS OFFSET ON THE MESHES, NOT THE PIVOTS: `_apply_pose` rewrites `_leg_l.position` from
## HIP_X every frame, so a wider pivot would be undone on the next tick (TwinModel records the same).
const FOOT_SEMI := Vector3(0.100, 0.058, 0.128)

func _build_feet() -> void:
	var m_leg := _toon(FUR_DEEP, _matte(SURF_LIMB))
	var m_foot := _toon(FUR_DEEP, _matte(_merged(SURF_LIMB, {"spec": 0.02})))
	var m_pad := _toon(PAD, _matte({"spec": 0.02}))
	for side: Array in [[-1.0, _leg_l], [1.0, _leg_r]]:
		var sx: float = side[0]
		var leg: Node3D = side[1]
		var ox := STANCE_X * sx
		_mi(capsule(0.060, LEG_LEN, 12, 3), m_leg, leg, Vector3(ox, -LEG_LEN * 0.42, 0.0), "Leg")
		var foot_y := -HIP_Y + FOOT_SEMI.y
		_mi(superellipsoid(FOOT_SEMI, 2.5, 14, 8), m_foot, leg, Vector3(ox, foot_y, -0.026), "Foot")
		for i in 3:
			var tx := (float(i) - 1.0) * 0.058
			_mi(superellipsoid(Vector3(0.024, 0.020, 0.016), 2.3, 8, 5), m_pad, leg,
				Vector3(ox + tx, foot_y - 0.010, -0.026 - FOOT_SEMI.z * 0.93 + absf(tx) * 0.30), "ToeBean")


# ============================================================================= face
## Two soft blush ovals just ABOVE the grin's corners and below the eyes, seated on the real head.
func _build_blush() -> void:
	var m := _toon(BLUSH, {"spec": 0.0, "rim": 0.02, "shade": 0.12})
	for sx: float in [-1.0, 1.0]:
		var b := _node("Blush", _face, Vector3.ZERO)
		_orient_on_head(b, 33.0 * sx, -5.0, 0.002)
		_mi(sphere(1.0, 10, 5), m, b, Vector3.ZERO, "Oval").scale = Vector3(0.046, 0.026, 0.012)


## THE MUZZLE FRAME. Its centre is ON the shell at `MUZZLE_PITCH`; right is +X; up is the surface's own
## up-tangent there. Every face part is placed in this frame by `_face_pt`.
func _init_face_frame() -> void:
	var p := deg_to_rad(MUZZLE_PITCH)
	_mz_c = se_point(Vector3(0.0, sin(p), -cos(p)), head_semi, head_n)
	var n0 := se_normal(_mz_c, head_semi, head_n)
	_mz_t = Vector3.RIGHT
	_mz_u = _mz_t.cross(n0).normalized()


## A point on the face: (x, y) in the muzzle's tangent plane, projected onto the head superellipsoid,
## then pushed out along the shell normal by the muzzle LENS (never below `lens_floor`) plus `lift`.
## Returns [position, normal of the lensed surface]. The normal tilts with the lens' own slope, so the
## swell shades as a soft bump and blends into the shell's shading at its rim.
func _face_pt(x: float, y: float, lift: float, lens_floor: float) -> Array:
	var q := _mz_c + _mz_t * x + _mz_u * y
	var p := se_point(q.normalized(), head_semi, head_n)
	var nrm := se_normal(p, head_semi, head_n)
	var k := 1.0 - (x * x) / (MUZZLE_RX * MUZZLE_RX) - (y * y) / (MUZZLE_RY * MUZZLE_RY)
	var rise := MUZZLE_H - MUZZLE_EDGE
	var lens := MUZZLE_EDGE + rise * k
	var n_out := nrm
	if lens > lens_floor:
		# d(lens)/dx and d(lens)/dy; a surface raised by h(x, y) tilts its normal by -grad h.
		var gx := -2.0 * rise * x / (MUZZLE_RX * MUZZLE_RX)
		var gy := -2.0 * rise * y / (MUZZLE_RY * MUZZLE_RY)
		n_out = (nrm - _mz_t * gx - _mz_u * gy).normalized()
	else:
		lens = lens_floor
	return [p + nrm * (lens + lift), n_out]


## THE MUZZLE — a pale lens on the head's own surface (see the note on `MUZZLE_PITCH`). A polar grid,
## 6 rings x 24 sectors plus the skirt ring (312 tris). Nothing of it stands more than `MUZZLE_H` off
## the head, so side-on it is part of the head's curve, not a card.
const MUZZLE_RINGS := 6
const MUZZLE_SECTORS := 24

func _build_muzzle() -> void:
	_init_face_frame()
	var node := _node("Muzzle", _face, Vector3.ZERO)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var centre: Array = _face_pt(0.0, 0.0, 0.0, -1.0)
	var rings: Array = []
	for i in range(1, MUZZLE_RINGS + 1):
		var r := float(i) / float(MUZZLE_RINGS)
		var ring: Array = []
		for j in MUZZLE_SECTORS:
			var a := TAU * float(j) / float(MUZZLE_SECTORS)
			ring.append(_face_pt(MUZZLE_RX * r * cos(a), MUZZLE_RY * r * sin(a), 0.0, -1.0))
		rings.append(ring)
	# The skirt: the rim ring again, dropped along the shell normal into the head, shaded as the shell.
	var skirt: Array = []
	for j in MUZZLE_SECTORS:
		var a := TAU * float(j) / float(MUZZLE_SECTORS)
		var rim: Array = _face_pt(MUZZLE_RX * cos(a), MUZZLE_RY * sin(a), 0.0, -1.0)
		var p := se_point((rim[0] as Vector3).normalized(), head_semi, head_n)
		var nrm := se_normal(p, head_semi, head_n)
		rings[MUZZLE_RINGS - 1][j] = [rim[0], nrm]
		skirt.append([p - nrm * MUZZLE_SKIRT, nrm])
	rings.append(skirt)
	for j in MUZZLE_SECTORS:
		var j2 := (j + 1) % MUZZLE_SECTORS
		_tri_smooth(st, centre, rings[0][j], rings[0][j2])
		for i in range(1, MUZZLE_RINGS + 1):
			# The skirt wall lies ALONG the normals, so its winding is judged against the outward
			# direction across the face instead.
			var facing: Vector3 = (rings[i][j][0] as Vector3) - _mz_c if i == MUZZLE_RINGS else Vector3.ZERO
			_tri_smooth(st, rings[i - 1][j], rings[i][j], rings[i][j2], facing)
			_tri_smooth(st, rings[i - 1][j], rings[i][j2], rings[i - 1][j2], facing)
	_mi(st.commit(), _toon(MUZZLE, _matte({"rim": 0.03, "spec": 0.0})), node, Vector3.ZERO, "Patch")


## One triangle from three [position, normal] pairs, wound the way Godot culls — clockwise from outside, i.e.
## (b - a) x (c - a) pointing INWARD (see the winding note above `_taper_path` in chibi_model.gd).
## `facing` overrides the normals as the outward test, for faces that lie along their own normals.
static func _tri_smooth(st: SurfaceTool, a: Array, b: Array, c: Array, facing: Vector3 = Vector3.ZERO) -> void:
	var pa: Vector3 = a[0]
	var pb: Vector3 = b[0]
	var pc: Vector3 = c[0]
	var n_sum: Vector3 = facing if facing != Vector3.ZERO else a[1] + b[1] + c[1]
	if (pb - pa).cross(pc - pa).dot(n_sum) > 0.0:
		var tmp := b
		b = c
		c = tmp
	for v: Array in [a, b, c]:
		st.set_normal(v[1])
		st.add_vertex(v[0])


## THE GRIN — a crescent with its corners turned up, a top row of small rounded points and two short
## lower ones, and a tongue, all ON the muzzle.
##
## WHY NOT `_add_wide_grin`: that helper's cavity is a rounded RECTANGLE. A rectangle full of pointed
## teeth is a grimace — the corners are what make a mouth smile, and a rectangle has none. The crescent
## drops `GRIN_DEPTH` at the centre and both edges meet at the corners `GRIN_CORNER` ABOVE the lip line,
## which is the literal shape of a smile.
##
## The "Mouth" node sits at the head origin with an identity transform: every child is placed in head
## space by `_face_pt`, so the cavity, teeth and tongue wrap round the cheek with the muzzle instead of
## being a flat plate standing off it (round 1's 42-53 mm).
func _build_grin() -> void:
	_mouth = _node("Mouth", _face, Vector3.ZERO)
	var m_grin := _toon(GRIN, {"spec": 0.0, "rim": 0.0, "shade": 0.05})
	var m_tooth := _toon(TOOTH, {"spec": 0.02, "rim": 0.02, "shade": 0.04})
	_cavity = _mi(_grin_mesh_at(1.0, 1.0), m_grin, _mouth, Vector3.ZERO, "Cavity")
	var m_tongue := _toon(TONGUE, {"spec": 0.0, "rim": 0.0, "shade": 0.10})
	_tongue = _node("Tongue", _mouth, Vector3.ZERO)
	_mi(superellipsoid(Vector3(0.046, 0.020, 0.006), 2.2, 12, 6), m_tongue, _tongue, Vector3.ZERO, "Blob")
	for t: Array in TOP_TEETH:
		_add_point_tooth(m_tooth, float(t[0]), float(t[1]), float(t[2]), true)
	for t: Array in LOW_TEETH:
		_add_point_tooth(m_tooth, float(t[0]), float(t[1]), float(t[2]), false)
	_set_grin(1.0, 1.0, 0.0)


## One small rounded-point tooth. A `taper_tube` grows along +Y from a round base; a TOP tooth is the
## same cone turned over so it hangs from the lip line. The tip radius is 22 % of the base — a rounded
## point at 40 cm and a clean point at 6.5 m, never a needle. Placed by `_set_grin`.
func _add_point_tooth(m_tooth: Material, u: float, w: float, length: float, top: bool) -> void:
	var tooth := _node("Tooth", _mouth, Vector3.ZERO)
	_mi(taper_tube(length, w * 0.50, w * 0.11, 0.0, 3, 6), m_tooth, tooth, Vector3.ZERO, "Point")
	_teeth.append([tooth, u, w, length, top])


## The grin's two edges in the muzzle plane at `u` (-1..1), for a mouth opened by `sy` (the lip line
## never moves; only the lower edge drops).
static func _grin_edges(u: float, sy: float) -> Vector2:
	var top := LIP_Y + grin_top(u, GRIN_CORNER)
	return Vector2(top, top - GRIN_DEPTH * sy * pow(maxf(1.0 - u * u, 0.0), 0.75))


## THE CONFORMAL CAVITY for one mouth shape: `GRIN_COLS` columns, the front 2 mm off the lensed face
## and the back sunk 12 mm, closed with the top and bottom walls. Cached per quantised (sx, sy).
func _grin_mesh_at(sx: float, sy: float) -> ArrayMesh:
	var key := "%.2f|%.2f" % [sx, sy]
	if _grin_meshes.has(key):
		return _grin_meshes[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ft: Array = []
	var fb: Array = []
	var bt: Array = []
	var bb: Array = []
	for i in GRIN_COLS + 1:
		var u := -1.0 + 2.0 * float(i) / float(GRIN_COLS)
		var x := u * GRIN_HALF_W * sx
		var e := _grin_edges(u, sy)
		ft.append(_face_pt(x, e.x, CAVITY_LIFT, 0.0))
		fb.append(_face_pt(x, e.y, CAVITY_LIFT, 0.0))
		var b0: Array = _face_pt(x, e.x, -CAVITY_SINK, 0.0)
		var b1: Array = _face_pt(x, e.y, -CAVITY_SINK, 0.0)
		bt.append([b0[0], -(b0[1] as Vector3)])
		bb.append([b1[0], -(b1[1] as Vector3)])
	for i in GRIN_COLS:
		_tri_smooth(st, ft[i], ft[i + 1], fb[i + 1])
		_tri_smooth(st, ft[i], fb[i + 1], fb[i])
		_tri_smooth(st, bt[i], bt[i + 1], bb[i + 1])
		_tri_smooth(st, bt[i], bb[i + 1], bb[i])
		# Walls: the top one faces up the face, the bottom one down it.
		var wt := [[ft[i][0], _mz_u], [ft[i + 1][0], _mz_u], [bt[i + 1][0], _mz_u], [bt[i][0], _mz_u]]
		_tri_smooth(st, wt[0], wt[1], wt[2], _mz_u)
		_tri_smooth(st, wt[0], wt[2], wt[3], _mz_u)
		var wb := [[fb[i][0], -_mz_u], [fb[i + 1][0], -_mz_u], [bb[i + 1][0], -_mz_u], [bb[i][0], -_mz_u]]
		_tri_smooth(st, wb[0], wb[1], wb[2], -_mz_u)
		_tri_smooth(st, wb[0], wb[2], wb[3], -_mz_u)
	var mesh := st.commit()
	_grin_meshes[key] = mesh
	return mesh


## Puts the mouth in shape: swaps the cavity mesh, and seats each tooth and the tongue on the face in
## its local frame (-Z out along the normal, +Y up the surface). Teeth are only MOVED and flattened in
## depth, never stretched — stretching a cone is how a tooth becomes a fang.
func _set_grin(sx: float, sy: float, mo: float) -> void:
	sx = snappedf(sx, GRIN_Q)
	sy = snappedf(sy, GRIN_Q)
	var key := "%.2f|%.2f" % [sx, sy]
	if key != _grin_key:
		_grin_key = key
		_cavity.mesh = _grin_mesh_at(sx, sy)
		for t: Array in _teeth:
			var u: float = t[1]
			var e := _grin_edges(u, sy)
			var top: bool = t[4]
			# Low teeth stand from a point a little INSIDE the lower edge so their base never shows under it.
			var y := e.x if top else e.y + 0.004
			var f: Array = _face_pt(u * GRIN_HALF_W * sx, y, TOOTH_LIFT, 0.0)
			var b := _surface_basis(f[1])
			if top:
				b = b * Basis(Vector3.RIGHT, PI)
			(t[0] as Node3D).transform = Transform3D(b * Basis.from_scale(Vector3(1.0, 1.0, TOOTH_FLAT)), f[0])
	# The tongue sits in the lower middle, in front of the cavity and behind the teeth.
	var fg: Array = _face_pt(0.0, LIP_Y - GRIN_DEPTH * 0.70 * sy, TOOTH_LIFT, 0.0)
	_tongue.transform = Transform3D(_surface_basis(fg[1]) * Basis.from_scale(Vector3(1.0, 1.0 + 0.8 * mo, 1.0)), fg[0])


## A basis for a part lying on the face: -Z along the outward normal, +Y up the surface.
func _surface_basis(n: Vector3) -> Basis:
	var z := -n
	var y := (_mz_u - n * _mz_u.dot(n)).normalized()
	return Basis(y.cross(z), y, z)


# ============================================================================= fur
## THE RAGGED OUTLINE — five tiers of hanging fins, the one silhouette cue nobody else has.
##
## Every ring is `shag_ring` (below), NOT `fur_ring`: `fur_ring`'s fins stick out almost HORIZONTALLY
## (the tip rises 18 % of the fin length), which is right for Pip's ruff but reads as a spiky collar on
## a body that is supposed to be soft. A shag fin DROOPS by a set angle, so a tier lies down the curve
## of the body like a coat. The fins are closed pyramids (4 tris) for the same cull_back reason
## `fur_ring` documents. Every ring sits at a height where its radius matches the shell's own half-width
## (solved on the superellipsoid, `_shell_half`), squashed in Z to the shell's plan, so the fins emerge
## FROM the surface rather than floating off it or burying themselves.
##
## Fin rules that bit on Pip and are kept: fins only read broadside — hanging down across a surface or
## standing out at the silhouette. A ring high on the crown shows its front fins end-on as white specks,
## so there is no crown ring at the front.
##
## NO FOREHEAD FRINGE, AND NO PALE FINS LYING ACROSS THE HEAD (round 2 of the 2026-09-15 critic). Round 1
## hung a 160-degree fringe of FUR_TIP fins over the forehead; on both renderers it rendered as a band
## of flat pale triangles — a second row of teeth echoing the grin, or stitching. The temple and crown
## tiers had the same pale fins down the sides of the face, which read as icicles at 3/4. So the fringe
## is gone, and every tier that lies ACROSS a visible surface is the body value, FUR: it breaks the
## outline where it meets the sky and shades as fur against the head, instead of drawing a pale
## pattern. FUR_TIP is kept only for the cheek puffs and shoulder tufts, which stand OUT at the
## silhouette and are what the value step is for.
func _build_fur() -> void:
	var m_fur := _toon(FUR_TIP, _matte({"spec": 0.02}))
	var m_fur_body := _toon(FUR, _matte({"spec": 0.02}))
	var zk := head_semi.z / head_semi.x
	# CHEEK / TEMPLE TIER round the sides and back, gap at the FRONT for the face (turned about Y).
	# Broader, shorter fins than round 1 (w 0.058 / len 0.070, was 0.050 / 0.080): tufts, not spikes.
	var temple := _node("TempleShag", _head, Vector3(0.0, head_semi.y * 0.10, 0.0))
	temple.rotation.y = PI
	temple.scale = Vector3(1.0, 1.0, zk)
	_mi(shag_ring(_shell_half(0.10) - 0.014, 0.070, 0.058, 28, 70.0, 0.32, 210.0), m_fur_body, temple,
		Vector3.ZERO, "Fins")
	# CROWN TIER at the back and sides only — the top of the silhouette from any 3/4 angle.
	var crown := _node("CrownShag", _head, Vector3(0.0, head_semi.y * 0.62, 0.0))
	crown.rotation.y = PI
	crown.scale = Vector3(1.0, 1.0, zk)
	_mi(shag_ring(_shell_half(0.62) - 0.012, 0.066, 0.056, 22, 64.0, 0.32, 180.0), m_fur_body, crown,
		Vector3.ZERO, "Fins")
	# JAW RUFF, the full ring: hangs over the belly top and hides the head/body join on every side.
	var ruff := _node("JawRuff", _head, Vector3(0.0, -head_semi.y * 0.78, 0.0))
	ruff.scale = Vector3(1.0, 1.0, zk)
	_mi(shag_ring(_shell_half(-0.78) - 0.008, 0.090, 0.052, 34, 74.0, 0.30, 360.0), m_fur_body, ruff,
		Vector3.ZERO, "Fins")
	# BELLY SKIRT, the full ring, low on the ball so the stubby legs peek out under it. Parented to its own node so `_animate_extras` can let it lag the waddle.
	var bk := TORSO_MUL.z / TORSO_MUL.x
	_skirt = _node("BellySkirt", _torso, Vector3(0.0, TORSO_Y - TORSO_RY * TORSO_MUL.y * 0.62, 0.0))
	var skirt_mesh := _node("Turn", _skirt, Vector3.ZERO)
	skirt_mesh.rotation.y = PI
	skirt_mesh.scale = Vector3(1.0, 1.0, bk)
	_mi(shag_ring(_torso_half(-0.62) - 0.010, 0.080, 0.052, 36, 70.0, 0.30, 360.0), m_fur_body,
		skirt_mesh, Vector3.ZERO, "Fins")
	# MID-BELLY TIER, the full ring.
	var mid := _node("BellyShag", _torso, Vector3(0.0, TORSO_Y + TORSO_RY * TORSO_MUL.y * 0.05, 0.0))
	mid.rotation.y = PI
	mid.scale = Vector3(1.0, 1.0, bk)
	_mi(shag_ring(_torso_half(0.05) - 0.012, 0.070, 0.050, 32, 70.0, 0.30, 360.0), m_fur_body, mid,
		Vector3.ZERO, "Fins")
	# CHEEK PUFFS — the silhouette mark. In the first all-black lineup the fluff ball was a plain round
	# head with two feelers, and at 8 m the ragged tiers above do not survive being a cut-out; that is
	# the same outline as any round-headed neighbour with antennae. A fan of long fins bursting SIDEWAYS
	# out of each cheek, just below eye level, makes him wider than his head on both sides — a puffball —
	# which nobody else in the cast is. Seated on the shell at the side (x = the shell's half-width at
	# that height), each fan is a narrow-arc `shag_ring` turned so its arc points outward, drooping only
	# 30 degrees so it reads as a tuft standing OUT, not hair lying down.
	for sx: float in [-1.0, 1.0]:
		var puff := _node("CheekPuff", _head, Vector3(sx * (_shell_half(-0.25) - 0.030), -head_semi.y * 0.25, 0.020))
		puff.rotation.y = -PI * 0.5 * sx
		_mi(shag_ring(0.030, 0.108, 0.054, 11, 30.0, 0.35, 120.0), m_fur, puff, Vector3.ZERO, "Fins")
		var puff_lo := _node("CheekPuffLow", _head, Vector3(sx * (_shell_half(-0.50) - 0.034), -head_semi.y * 0.50, 0.030))
		puff_lo.rotation.y = -PI * 0.5 * sx
		_mi(shag_ring(0.030, 0.100, 0.052, 7, 38.0, 0.35, 100.0), m_fur_body, puff_lo, Vector3.ZERO, "Fins")
	# SHOULDER TUFTS ride the arm pivots, so they follow the arm for free (Pip's recipe). The 240-degree
	# arc's gap is turned INBOARD so no fin is built inside the belly.
	for side: Array in [[-1.0, _arm_l], [1.0, _arm_r]]:
		var tuft := _node("ShoulderTuft", side[1], Vector3(0.0, -0.010, 0.0))
		tuft.rotation.y = -PI * 0.5 * float(side[0])
		_mi(shag_ring(0.066, 0.060, 0.044, 12, 55.0, 0.35, 240.0), m_fur, tuft, Vector3.ZERO, "Fins")


## Half-width of the HEAD shell at a height given as a fraction of its y semi-axis (-1..1).
func _shell_half(frac: float) -> float:
	return head_semi.x * pow(maxf(1.0 - pow(absf(frac), head_n), 0.0), 1.0 / head_n)


## Half-width of the BELLY at a height given as a fraction of its y semi-axis.
func _torso_half(frac: float) -> float:
	return TORSO_RX * TORSO_MUL.x * pow(maxf(1.0 - pow(absf(frac), TORSO_N), 0.0), 1.0 / TORSO_N)


# ============================================================================= feelers
## TWO FEELERS, dialogue-locked. Each is a thin curved stalk (`taper_tube`, bending backward) ending in
## a FUZZY POM — a lilac ball with a burst of short fins (`pom_mesh`). Matte, never emissive: a glowing
## bulb is Zorp's and Bolt's organ.
##
## THE SEAT IS A `_crown_row` TILT CHILD, so aiming it cannot destroy the placement (writing rotation on
## an `_orient_on_head`-posed node rebuilds its basis from euler — the bug three files here once hit).
## The splay goes on that child; the per-frame flop goes on a further child, `Flop`, so the animation
## never fights the authored aim.
func _build_feelers() -> void:
	var m_stalk := _toon(FUR_DEEP, _matte({"spec": 0.04}))
	var m_pom := _toon(POM, _matte({"spec": 0.02}))
	for sx: float in [-1.0, 1.0]:
		var seat: Node3D = _crown_row(1, FEELER_PITCH, FEELER_PITCH, FEELER_YAW * sx, 0.010)[0]
		# Outward splay. `_basis_from_up` gives both seats the same +X-branch frame (|n.x| < 0.9), so
		# the lean needs the side's sign; the backward rake needs none (see TwinModel's horn notes).
		seat.rotation = Vector3(0.10, 0.0, -0.30 * sx)
		var flop := _node("Flop", seat, Vector3.ZERO)
		_mi(taper_tube(FEELER_LEN, 0.021, 0.013, FEELER_CURL, 7, 6), m_stalk, flop, Vector3.ZERO, "Stalk")
		var tip_up := Vector3(0.0, cos(FEELER_CURL), sin(FEELER_CURL))
		var tip := taper_tube_end(FEELER_LEN, FEELER_CURL, 7) + tip_up * (POM_R * 0.70)
		_mi(sphere(POM_R, 12, 7), m_pom, flop, tip, "Pom")
		_mi(pom_mesh(POM_R * 0.92, POM_FIN, POM_FINS, POM_FIN_W), m_pom, flop, tip, "PomFluff")
		flop.set_meta("side", sx)
		_feelers.append(flop)


# ============================================================================= uniform
## A SHOP SATCHEL — a strap worn across the body and a pouch on the hip wearing the Cosmo Depot badge.
##
## WHY NOT AN APRON: two builds tried. A round panel on the belly rendered as a BELLY BUTTON; a square
## panel hung from a waistband rendered as a NAPPY on a round fur ball — the exact failure TwinModel's
## apron notes record for Pop's old body. A cross-body strap has no front panel to misread, it says
## "the one who runs the deliveries" (his favour lines are deliveries and wrapped parcels), and the badge
## still marks him as Cosmo Depot staff beside Pip.
##
## THE STRAP HUGS THE BODY EXACTLY, and this is solved, not eyeballed. It is a `_se_slab` rotated about Z
## by STRAP_TILT. A plane through the body's vertical centre line tilted by t cuts a superellipsoid in a
## curve |r/R|^n + |z/c|^n = 1 — the SAME exponent — where R solves |R cos t / a|^n + |R sin t / b|^n = 1.
## So a slab of plan (R, c) on the body's own exponent, rotated by t, lies on the surface everywhere; it
## is built 3.5 % proud so it cannot z-fight. The pouch is seated on the real surface normal at a point
## ON the band, and hangs a little below it.
const STRAP_TILT := 0.70            ## rad: high on his right shoulder, low on his left hip
const STRAP_PHI := 128.0             ## deg round the band where the pouch hangs (front-left-low)
const POUCH_SIZE := Vector3(0.150, 0.120, 0.056)

func _build_satchel() -> void:
	var m_strap := _toon(APRON_TRIM, _matte({"surface": "cloth", "surface_scale": 3.0, "surface_strength": 0.40}))
	var m_pouch := _toon(APRON, _matte({"surface": "cloth", "surface_scale": 2.4, "surface_strength": 0.45,
		"spec": 0.02}))
	var m_flap := _toon(APRON_TRIM, _matte({"spec": 0.02}))
	var c: Vector3 = Vector3(0.0, TORSO_Y, 0.0)
	var semi: Vector3 = Vector3(TORSO_RX * TORSO_MUL.x, TORSO_RY * TORSO_MUL.y, TORSO_RZ * TORSO_MUL.z)
	var n: float = TORSO_N
	var ct := cos(STRAP_TILT)
	var st := sin(STRAP_TILT)
	var big_r := pow(pow(ct / semi.x, n) + pow(st / semi.y, n), -1.0 / n)
	var proud := 1.035
	var strap := _se_slab(_torso, Vector2(big_r * proud, semi.z * proud), 0.017, n, m_strap, c, "Strap", 24)
	strap.rotation.z = STRAP_TILT
	# A point on the band at angle phi, in body space, and the body's own outward normal there.
	var phi := deg_to_rad(STRAP_PHI)
	var local := Vector3(big_r * cos(phi) * ct, big_r * cos(phi) * st, -semi.z * sin(phi))
	var outward := se_normal(local, semi, n)
	var pouch := _node("Pouch", _torso, c + local * proud + outward * (POUCH_SIZE.z * 0.45) + Vector3(0.0, -0.030, 0.0))
	pouch.basis = Basis.looking_at(outward, Vector3.UP)
	_mi(rounded_box(POUCH_SIZE, 0.030, 14), m_pouch, pouch, Vector3.ZERO, "Bag")
	_mi(rounded_box(Vector3(POUCH_SIZE.x * 1.02, POUCH_SIZE.y * 0.46, POUCH_SIZE.z * 0.30), 0.014, 12), m_flap,
		pouch, Vector3(0.0, POUCH_SIZE.y * 0.26, -POUCH_SIZE.z * 0.40), "Flap")
	var logo := _node("Badge", pouch, Vector3(0.0, 0.004, -POUCH_SIZE.z * 0.58))
	_mi(rounded_box(Vector3(0.056, 0.056, 0.012), 0.016, 12), _toon(BADGE, _matte({"spec": 0.05})),
		logo, Vector3.ZERO, "Star").rotation.z = PI * 0.25
	_mi(rounded_box(Vector3(0.028, 0.028, 0.014), 0.008, 10), _toon(APRON.darkened(0.24), _matte({})),
		logo, Vector3(0.0, 0.0, -0.004), "Inlay").rotation.z = PI * 0.25


# ============================================================================= animation
## CLUMSY: a waddle a third bigger than the cast's, and the head bobs further behind it.
func _pose_walk(p: PackedFloat32Array) -> void:
	super(p)
	p[P.TORSO_ROLL] *= 1.30
	p[P.HEAD_ROLL] *= 1.35
	p[P.BODY_Y] *= 1.15
	# TOE DIP. The shared lift term compensates the leg capsule's swing but not a foot that reaches
	# 128 mm ahead of the pivot: at full stride the toe (or heel) of the planted foot dips 32 mm into
	# the ground (clip probe, vertex-exact — the shipped Pop dips 31 mm on the same rig). Lifting the
	# foot by that swing's own (1 - cos) geometry, scaled to the foot's reach, cancels it at the
	# extremes and adds nothing mid-stance where the foot is flat.
	var reach := FOOT_SEMI.z + 0.026
	var sw := sin(_stride_phase)
	var amp := 0.62 * clampf(_speed_factor / 0.7, 0.0, 1.0)
	var dip := reach * absf(sin(amp * sw))
	p[P.LEG_L_LIFT] += dip
	p[P.LEG_R_LIFT] += dip


## SURPRISED: the jump-back kicks the legs +/-0.35 rad, and the same toe dip as the walk puts the front
## foot 14 mm into the ground on the first frames (clip probe). Same compensation as `_pose_walk`.
func _pose_surprised(p: PackedFloat32Array, t: float) -> void:
	super(p, t)
	var dip := (FOOT_SEMI.z + 0.026) * absf(sin(p[P.LEG_L_PITCH]))
	p[P.LEG_L_LIFT] += dip
	p[P.LEG_R_LIFT] += dip


## HAPPY: the shared arms-up cheer at roll 2.6 brings a mitt within ~2 cm of a head this wide (measured
## with the clip probe: implicit F 0.89 against the head inflated by one mitt radius). 0.22 rad further
## out keeps both paws clear of the fluff and reads as a bigger, wider cheer.
func _pose_happy(p: PackedFloat32Array, t: float) -> void:
	super(p, t)
	p[P.ARM_L_ROLL] -= 0.22
	p[P.ARM_R_ROLL] -= 0.22


## THINK: the shared pose lifts the hand to the chin, and his arms are far too short to reach a chin
## this wide — the mitt stopped in mid-air and read as a shrug. So he does the other "hmm": one paw
## raised in front of him, the head tipped right over and back to look UP, and the feelers droop
## (EXTRA_A -1, see `_animate_extras`). The grin also closes to a tight line of teeth (`_animate_mouth`).
func _pose_think(p: PackedFloat32Array, t: float) -> void:
	super(p, t)
	var u := clampf(t / 0.4, 0.0, 1.0)
	p[P.ARM_R_PITCH] = -2.35 * u
	p[P.ARM_R_ROLL] = 0.55 * u
	p[P.ARM_R_YAW] = 0.35 * u
	p[P.ARM_L_PITCH] = -0.45 * u
	p[P.ARM_L_ROLL] = 0.55 * u
	p[P.HEAD_ROLL] = 0.30 * u + 0.04 * sin(TAU * t * 0.8)
	p[P.HEAD_PITCH] = -0.20 * u
	p[P.TORSO_ROLL] = -0.06 * u


func _animate_extras(delta: float) -> void:
	_t += delta
	_animate_mouth()
	# FEELER FLOP: a first-order lag on the body's vertical speed, so a hop or a stride throws the poms
	# up and they settle a beat later. Clamped, so a teleport cannot fling them.
	var by := _body.position.y if _body != null else 0.0
	var vy := clampf((by - _last_body_y) / maxf(delta, 1e-3), -2.0, 2.0)
	_last_body_y = by
	_feeler_lag = lerpf(_feeler_lag, vy, 1.0 - exp(-6.0 * delta))
	var droop := clampf(-pose(P.EXTRA_A), 0.0, 1.0) * 0.35
	var perk := clampf(pose(P.EXTRA_B), 0.0, 1.0) * 0.18
	for f: Node3D in _feelers:
		var sx: float = f.get_meta("side", 1.0)
		var wob := sin(TAU * (_t + 0.4 * sx) / 1.9)
		f.rotation.x = 0.10 * wob + 0.22 * _feeler_lag + droop - perk
		f.rotation.z = -0.07 * sx * wob - perk * 0.8 * sx
	if _skirt != null:
		_skirt.rotation.z = 0.35 * pose(P.TORSO_ROLL)


## THE GRIN TALKS by opening its lower edge. `_mouth_open` does not exist on him (see `_build_geometry`),
## so this is the mouth. The lip line and top teeth stay put, the lower edge, lower teeth and tongue
## drop, and a surprised "O" pinches it narrow. `_set_grin` rebuilds the cavity ON the face for each
## shape rather than scaling a mesh, because a scaled cavity would lift off the curved muzzle.
func _animate_mouth() -> void:
	if _cavity == null:
		return
	var mo := clampf(pose(P.MOUTH_OPEN), 0.0, 1.0)
	var rnd := clampf(pose(P.EYE_ROUND), 0.0, 1.0)
	var hap := clampf(pose(P.EYE_HAPPY), 0.0, 1.0)
	# "think" closes the grin to a tight line: BROW is the think channel on every model.
	var shut := clampf(pose(P.BROW), 0.0, 1.0)
	var sy := (1.0 + 0.55 * mo + 0.25 * rnd) * (1.0 - 0.55 * shut)
	var sx := 1.0 - 0.26 * rnd + 0.06 * hap
	_set_grin(sx, sy, mo)


## The "!" must clear the pom tips. Computed from the built rest pose, not hard-coded, so moving a
## feeler moves the marker with it.
func marker_clearance() -> float:
	var top := head_y + head_semi.y
	for f: Node3D in _feelers:
		for c: Node in f.get_children():
			if c is MeshInstance3D and (c as Node3D).name == "Pom":
				top = maxf(top, _model_y(c as Node3D) + POM_R + POM_FIN)
	return top


## Model-space height of a node at the authored rest pose, walking local transforms up to this model.
## Works before the model is in the tree (npc.gd asks during `_ready`).
func _model_y(n: Node3D) -> float:
	var xf := Transform3D.IDENTITY
	var cur: Node = n
	while cur != null and cur != self:
		if cur is Node3D:
			xf = (cur as Node3D).transform * xf
		cur = cur.get_parent()
	# Undo the root's own squash scale if any (it is ~1 at rest).
	return xf.origin.y


# ============================================================================= mesh builders
## The grin's lip line: flat through the middle, lifting to `corner` at the ends (u^4, so the middle
## stays level and only the corners turn up).
static func grin_top(u: float, corner: float) -> float:
	return corner * pow(absf(u), 4.0)


## A RING OF DROOPING FUR FINS. Like `fur_ring` (angles from -Z, `arc_deg` < 360 leaves the gap at the
## BACK, deterministic jitter seeded from the cache key), but each fin leaves the ring along
## dir * cos(droop) + DOWN * sin(droop), so a tier lies down a curved body instead of standing off it.
## Each fin is a closed 4-triangle pyramid: two base corners on the ring, a spine vertex lifted off the
## surface for thickness, and the tip.
static func shag_ring(ring_r: float, fin_len: float, fin_w: float, count: int, droop_deg: float,
		jitter: float = 0.25, arc_deg: float = 360.0) -> ArrayMesh:
	var key := "shag|%.4f|%.4f|%.4f|%d|%.2f|%.3f|%.2f" % [ring_r, fin_len, fin_w, count, droop_deg, jitter, arc_deg]
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	count = maxi(count, 1)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(key)
	var span := deg_to_rad(clampf(arc_deg, 1.0, 360.0))
	var full := arc_deg >= 359.9
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in count:
		var a := TAU * float(i) / float(count) if full else \
			(-span * 0.5 + span * float(i) / float(maxi(count - 1, 1)))
		a += rng.randf_range(-jitter, jitter) * span / float(count) * 0.5
		var dir := Vector3(sin(a), 0.0, -cos(a))
		var tan := Vector3(cos(a), 0.0, sin(a))
		var d := deg_to_rad(droop_deg * (1.0 + rng.randf_range(-jitter, jitter) * 0.4))
		var axis := dir * cos(d) + Vector3.DOWN * sin(d)
		var nrm := dir * sin(d) + Vector3.UP * cos(d)
		var jl := 1.0 + rng.randf_range(-jitter, jitter)
		var seat := dir * ring_r
		var v0 := seat + tan * (fin_w * 0.5)
		var v1 := seat - tan * (fin_w * 0.5)
		var v2 := seat + axis * (fin_len * 0.30) + nrm * (fin_w * 0.30)
		var v3 := seat + axis * (fin_len * jl) + tan * (fin_w * rng.randf_range(-0.35, 0.35))
		var g := (v0 + v1 + v2 + v3) * 0.25
		for f: Array in [[v0, v1, v2], [v0, v1, v3], [v0, v2, v3], [v1, v2, v3]]:
			_tri_out(st, f[0], f[1], f[2], g)
	var mesh := st.commit()
	_mesh_cache[key] = mesh
	return mesh


## A FUZZY POM: `count` short pyramid fins bursting out of a ball of radius `r`, on a Fibonacci sphere
## so no two fins line up into a visible seam. Closed pyramids, deterministic.
static func pom_mesh(r: float, fin_len: float, count: int, width_k: float = 0.55) -> ArrayMesh:
	var key := "pom|%.4f|%.4f|%d|%.3f" % [r, fin_len, count, width_k]
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var golden := PI * (3.0 - sqrt(5.0))
	for i in count:
		var yv := 1.0 - 2.0 * (float(i) + 0.5) / float(count)
		var rr := sqrt(maxf(1.0 - yv * yv, 0.0))
		var th := golden * float(i)
		var dir := Vector3(cos(th) * rr, yv, sin(th) * rr)
		var t1 := dir.cross(Vector3.UP if absf(dir.y) < 0.9 else Vector3.RIGHT).normalized()
		var t2 := dir.cross(t1).normalized()
		var w := fin_len * width_k
		var base := dir * r
		var v0 := base + t1 * w * 0.5
		var v1 := base - t1 * w * 0.25 + t2 * w * 0.43
		var v2 := base - t1 * w * 0.25 - t2 * w * 0.43
		var v3 := dir * (r + fin_len * (0.8 + 0.4 * fmod(float(i) * 0.618, 1.0)))
		var g := (v0 + v1 + v2 + v3) * 0.25
		for f: Array in [[v0, v1, v2], [v0, v1, v3], [v0, v2, v3], [v1, v2, v3]]:
			_tri_out(st, f[0], f[1], f[2], g)
	var mesh := st.commit()
	_mesh_cache[key] = mesh
	return mesh


## `_matte()` fills defaults into a COPY, so option dicts compose; this is just the merge.
static func _merged(base: Dictionary, extra: Dictionary) -> Dictionary:
	var o := base.duplicate()
	for k: Variant in extra:
		o[k] = extra[k]
	return o
