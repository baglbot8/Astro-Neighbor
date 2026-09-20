class_name PipModel
extends ChibiModel
## Pip — the chatty half of the Cosmo Depot pair, now a TINY GREEN ALIEN FLYING A SMALL SAUCER.
##
## R7 (2026-09-15, THE USER'S OWN IDEA). "tiny green alien (stereotypical alien black eyes) floating
## sitting in a stereotypical saucer ship with two small levers". Pip used to share `TwinModel` with
## Pop; this is Pip's own class, and it is the open-cockpit saucer ("A"). `PipDomeModel` extends it
## with a low glass canopy instead ("B") and changes only the craft, never the pilot.
##
## WHAT READS AT 8 m, IN ORDER: (1) a wide flat disc with a small figure sitting in it, HANGING IN THE
## AIR over its own soft shadow — no other neighbour has a horizontal silhouette at all; (2) two big black almond eyes on a round green head
## that narrows a little toward the chin — the "little green alien" read; (3) one antenna with a
## star on it, standing off the back of the saucer; (4) the two lever knobs under the hands.
##
## THE PILOT IS A CHIBI, AND THE RIG IS THE CAST'S RIG. `ChibiModel.rebuild()` makes the usual
## Root > Body > TorsoPivot > Torso tree; `_build_geometry` slides a `Craft` node in between Body and
## TorsoPivot, so the saucer tilts and bobs with Pip riding in it, while every face, blink, look and
## arm channel keeps working exactly as it does on the rest of the cast. There are no legs: the lower
## half of the body is inside the hull and nothing is built for it.
##
## CAST SLOTS HELD (docs/CAST_VARIETY.md, the 2026-09-15 slot plan):
##   * NO SURFACE PATTERN AT ALL — Pip is the one blank (Pop gave it up). Not on the skin, not on the
##     hull. The saucer's metal read comes from colour blocking, a bumper and a low spec, never from
##     a `surface` key. Do not "improve" that with a faint grain: then nobody in the cast is smooth.
##   * NO FUR (Pip gave `sd_foliage` and the fur fringe to Pop), no lashes, no brows.
##   * HARD VOCABULARY: NONE of {brow ridge, heavy lid, horns, tusks, fangs, shoulder yoke}. The old
##     sleepy lid is gone with the TwinModel build.
##   * MOUTH KIND: an OPEN ROUND SLOT with a tongue — the kind Pip already held. It is not a closed arc,
##     not a bar, not a grin and not a light strip, so it cannot collide with anyone's slot.
##   * NOT AN EYESTALK, NOT A GRIN. Floating is fine under ruling 4: nothing in shipped text marks
##     this character as the designated-female one (npc_data.gd only calls Pop a brother).
##
## DIALOGUE-LOCKED: EXACTLY ONE ANTENNA ("One antenna. Best antenna. Fact."). It rides the saucer, as
## the slot plan asks, and its tip is a matte STAR — the Cosmo Depot star ("Our star logo? I drew it.
## Mostly.") — not a glowing bulb, which is Bolt's. The shop bib stays for "Pop and I share one apron
## budget." Pip still carries crates ("Almost three."), so the arms are real arms that leave the
## levers to wave, think and cheer.

# ---------------------------------------------------------------------------------------- palette
## R2.6 gate, checked at authoring time: every albedo here is under S 0.46 and V 0.86 except the eye
## ink (near-black, S is meaningless there). The two lamp colours are emissive ACCENTS a few pixels
## across, which is what R2.6 allows bright colour to be.
## SKIN went #96c26f (S 0.43) -> #9ac279 (S 0.38) after the first measured render: the lit face read
## S 0.42 but its shaded underside rendered S 0.54-0.59, one step from the "no swatch above S 0.60"
## gate. Same hue, less chroma — pastel, not mud.
const SKIN := Color("#9ac279")          ## S 0.38 V 0.76 — Pip's leaf green, softened
const EYE := Color("#1b1823")           ## the black almond ink
const MOUTH := Color("#452c28")
const MOUTH_INNER := Color("#7a3941")
const TONGUE := Color("#c9848c")        ## S 0.34
const BLUSH := Color("#c99a92")         ## S 0.27 V 0.79 — restrained, and warmer than the skin
const APRON := Color("#d6c9a8")         ## the shop's cream, S 0.21 V 0.84
const TRIM := Color("#c49a9c")          ## Pip's dusty rose, S 0.21 V 0.77
const STAR := Color("#d9b96e")          ## the Cosmo Depot star, S 0.49 V 0.85
const HULL := Color("#a19eb2")          ## cool lilac-silver, S 0.11 V 0.70
const HULL_DARK := Color("#6d697e")     ## underside, S 0.16 V 0.49
const DECK := Color("#878299")          ## the raised deck, one value step under the hull
const PAD := Color("#5b5368")           ## cockpit padding, S 0.19 V 0.41
const BUMPER := Color("#5f5a70")        ## gunmetal band, S 0.20 V 0.44 — a rim, not a pool float
const LAMP := Color("#f0dcae")          ## warm cream lamp, S 0.28 — NOT Bolt's orange
const LAMP_OFF := Color("#8a7f70")
const KNOB_L := Color("#cf8f8a")        ## rose lever knob
const KNOB_R := Color("#d7c48f")        ## cream-gold lever knob — two knobs, two colours
const MAST := Color("#7b778b")

# ---------------------------------------------------------------------------------------- pilot
## The whole model is scaled by `body_scale` (0.80), so every length below is MODEL space.
const TORSO_MUL := Vector3(0.76, 0.85, 0.80)
## The pilot sits HIGHER in the rig than a standing chibi: the rim cuts the torso a little above its
## middle, so ~45 % of the bean shows over the cockpit and the head sits right on it.
const SEAT_LIFT := 0.05
## HEAD: 660 x 580 x 600 mm at n 2.5, wider than tall, and TAPERED below the equator (see
## `_taper`) so the lower face narrows toward a small chin. That taper is most of the "little alien"
## read and it is kept gentle — 18 % at the chin — because a needle chin under big black eyes is the
## grey-alien horror register, which is exactly the "never creepy" rule.
const PIP_HEAD_SEMI := Vector3(0.330, 0.290, 0.300)
const PIP_HEAD_N := 2.5
const TAPER := 0.18
const TAPER_POW := 1.6
## EYES — the classic black almond, cut with the recipe Pop's eyes proved (a rounded-rectangle lens
## plus one cone carrying the taper out to a point at the OUTER corner; built at the inner corner it
## renders as a scowl). 0.072 x 0.054 half-size is BIG for this cast on purpose — it is the one
## feature the user named, and at 0.052 x 0.040 the eyes read as two small cat-eyes, not an alien's.
## It is held off the baby-doll register by shape (a hard almond, no sclera, no iris, one dull
## glint) rather than by area, and the glint is what keeps a black eye from reading as a hole.
const PIP_EYE_W := 0.072
const PIP_EYE_H := 0.054
const PIP_EYE_YAW := 21.0
const PIP_EYE_PITCH := 3.0
const EYE_RAKE := 7.0                   ## see `_cut_almond_eyes` for why not more
## Arms "on the levers": pitched forward and rolled out. These two numbers ARE the rest pose; the
## lever pivots are SOLVED from them at build time (`_hand_rest`), so changing them moves the levers
## with the hands instead of leaving a gap.
const GRIP_PITCH := 1.60
const GRIP_ROLL := 0.46

# ---------------------------------------------------------------------------------------- craft
## Hover: the Root sits this far up. ROUND 2 (critic, 2026-09-15): at 0.14 the keel cleared the ground
## by 0.20 m rendered and there was no shadow, so at the 28-degree gameplay camera the disc read as a
## rug lying on the plaza — a flat disc with no contact cue has no height. 0.26 puts the keel bottom
## at model 0.375 = 0.30 m rendered at rest (0.26 + CRAFT_Y 0.30 - keel 0.140 - its 0.045 semi), and
## `_build_ground_shadow` puts the missing cue under it.
const HOVER := 0.26
## Pivot the craft tilts about: the hull's own centre, not the ground, or every tilt would swing the
## whole saucer sideways.
const CRAFT_Y := 0.30
const HULL_R := 0.560
const HULL_H := 0.140
const BUMPER_R := 0.575                  ## ring centre radius
const BUMPER_TUBE := 0.036
const DECK_R := 0.320
const DECK_H := 0.090
const DECK_Y := 0.390
const COLLAR_R := 0.222                  ## padded cockpit ring, tube centre radius
const COLLAR_TUBE := 0.032
const COLLAR_Y := 0.452
const LAMPS := 8
const LEVER_LEN := 0.120                ## first guess only; `_build_levers` solves the real length
## Where on the mitten the knob is gripped, in the craft frame: in front of and a little below the
## hand centre, so the knob shows at the front of the fist instead of vanishing inside it.
const GRIP_OFF := Vector3(0.0, -0.036, -0.056)
## The lever's own lean at rest: up, a little outboard and raked back toward the pilot.
const LEVER_LEAN := Vector3(0.10, 0.93, 0.30)
## Antenna: a curved mast off the back of the deck, slightly to Pip's right, tip well clear of the
## crown so it reads above the head from the front and as the saucer's mast from the side.
const MAST_SEAT := Vector3(0.16, 0.40, 0.33)
const MAST_LEN := 0.80
const MAST_CURL := -0.30                 ## bends the top forward over the cockpit
const STAR_R := 0.092

## Craft channels, lerped separately from the body's pose channels so the saucer has its own inertia.
enum C { LIFT, PITCH, ROLL, BACK, LAMP_RATE, LAMP_GAIN, COUNT }

## THE MOTION ENVELOPE. The peaks of every pose below are written with these, and `marker_clearance`
## bounds the star's reach from the SAME numbers, so a livelier emote can never quietly push the star
## up into the "!" again (round 1 did: the bound ignored the bob, the lift, the hop and the tilt).
const BOB_AMP := 0.022                   ## always-on hover bob
const LIFT_MAX := 0.030                  ## craft LIFT peak (walk, dance)
## BODY_Y peak (the happy hop and the surprise jolt). 0.16 in round 1; 0.12 in round 2 because every
## 10 mm of hop is 10 mm more the "!" has to float above the crown all the time, and the spin, the
## squash and the shadow shrinking under the saucer carry the joy.
const HOP_MAX := 0.12
const DANCE_HOP := 0.05                  ## BODY_Y peak of the dance bounce
## The most the whole craft rises above its rest height at once. No pose lifts the craft AND hops the
## body at their peaks: the hop emotes write LIFT 0, and dance's bounce rides on LIFT_MAX.
const RISE_MAX := maxf(HOP_MAX, DANCE_HOP + LIFT_MAX)
const PITCH_MIN := -0.13                 ## nose down, gliding
const PITCH_MAX := 0.20                  ## nose up, braking on a surprise
const ROLL_MAX := 0.15                   ## the dance rock
## `_animate_mast` writes tilt = 0.18 - 0.8 * pitch + (0.10 thinking | -0.05 talking) and
## sway = -0.6 * roll + (0.05 sway + 0.16 surprise wobble): the mast LEANS AGAINST the craft's pitch
## and roll, so the bound walks those couplings instead of treating the mast as free.
const MAST_REST_TILT := 0.18
const MAST_PITCH_FOLLOW := 0.8
const MAST_ROLL_FOLLOW := 0.6
const MAST_THINK_TILT := 0.10
const MAST_TALK_TILT := 0.05
const MAST_WOBBLE_MAX := 0.05 + 0.16
## Where npc.gd's "!" dot ends, measured from what `marker_clearance` returns: the marker sits at
## clearance + MARKER_CLEARANCE_GAP (0.18) and its dot hangs 0.085 + 0.0425 + 0.013 (outline) below
## that, bobbing 0.06 — so the dot's lowest edge is clearance - 0.0205. The clearance adds that back
## plus 40 mm of air, so at the bottom of both bobs the dot still floats clear of the star.
const MARKER_DOT_REACH := 0.0205
const MARKER_AIR := 0.040
## The player's blob-shadow laws (player.gd `_update_shadow`), reused as they are so Pip's shadow
## shrinks and fades with height exactly as the astronaut's does on a jetpack hop.
const SHADOW_COLOR := Color(0.12, 0.09, 0.28, 0.42)
const SHADOW_SOFT := 0.6

var _craft: Node3D                       ## tilt/bob pivot at CRAFT_Y
var _craft_local: Node3D                 ## feet-relative frame under it (everything rides here)
var _craft_pose := PackedFloat32Array()
var _craft_target := PackedFloat32Array()
var _lever_pivots: Array[Node3D] = []
var _lever_sticks: Array[Node3D] = []
var _lever_knobs: Array[Node3D] = []
var _lever_rest: Array[Vector3] = []     ## rest direction per lever (unit)
var _lever_dir: Array[Vector3] = []      ## current, smoothed
var _lever_len: Array[float] = []
var _lever_base: Array[float] = []    ## each lever's solved rest length
var _lamp_mats: Array[ShaderMaterial] = []
var _mast: Node3D
var _star: Node3D
var _shadow: MeshInstance3D
var _shadow_mat: ShaderMaterial
var _clock := 0.0
var _lamp_phase := 0.0
var _spin := 0.0
## Model-space crown height at rest, for `marker_clearance` and `collision_size`.
var _crown_y := 0.0


func _init() -> void:
	super()
	body_scale = 0.80
	hover_height = HOVER
	head_semi = PIP_HEAD_SEMI
	head_n = PIP_HEAD_N
	# Chin 12 mm into the torso top: 0.40 + 0.235 * 0.85 = 0.5998, minus 0.012, plus the semi-y.
	head_y = TORSO_Y + TORSO_RY * TORSO_MUL.y - 0.012 + PIP_HEAD_SEMI.y
	eye_w = PIP_EYE_W
	eye_h = PIP_EYE_H
	eye_d = 0.018
	mouth_w = 0.050
	mouth_h = 0.044
	# Chatty and bright-eyed: blinks a little more often than the cast default, never parked shut.
	blink_hold = 0.75
	anim_time_scale = 1.06
	_craft_pose.resize(C.COUNT)
	_craft_target.resize(C.COUNT)


# ===================================================================================== build
func _build_geometry() -> void:
	_lever_pivots.clear()
	_lever_sticks.clear()
	_lever_knobs.clear()
	_lever_rest.clear()
	_lever_dir.clear()
	_lever_len.clear()
	_lever_base.clear()
	_lamp_mats.clear()
	# THE CRAFT GOES BETWEEN BODY AND TORSO PIVOT. Body carries the emote hop (BODY_Y/BODY_Z), so the
	# whole saucer hops with Pip in it; Craft carries the tilt; TorsoPivot keeps the pilot's own sway.
	_craft = _node("Craft", _body, Vector3(0.0, CRAFT_Y, 0.0))
	_craft_local = _node("CraftLocal", _craft, Vector3(0.0, -CRAFT_Y, 0.0))
	_body.remove_child(_torso_pivot)
	_craft_local.add_child(_torso_pivot)
	_torso_pivot.position = Vector3(0.0, HIP_Y + SEAT_LIFT, 0.0)
	# The legs are never built; park the empty nodes inside the hull so nothing can ever hang below.
	_leg_l.visible = false
	_leg_r.visible = false

	_build_pilot()
	_build_craft()
	_build_levers()
	_build_mast()
	_build_ground_shadow()
	_crown_y = HOVER + SEAT_LIFT + head_y + head_semi.y


func _build_pilot() -> void:
	# TORSO: a small bean, no waist chamfer (the chamfer would sit right at the rim line and read as
	# a second collar). NO surface dict — see the class docstring.
	_add_torso_bean(SKIN, {"size_mul": TORSO_MUL, "waist_chamfer": false})
	_seat_shoulders(TORSO_MUL.x, TORSO_MUL.y)
	_add_arms(SKIN, SKIN, 0)
	_mi(_tapered_head_mesh(), _toon(SKIN, _matte({"spec": 0.03})), _head, Vector3.ZERO, "HeadShell")

	var eyes: Array = []
	for sx: float in [-1.0, 1.0]:
		eyes.append({"yaw": PIP_EYE_YAW * sx, "pitch": PIP_EYE_PITCH, "brow": false, "fit_expr": true,
			"slant_deg": EYE_RAKE * sx})
	_add_face(EYE, MOUTH, BLUSH, {"eyes": eyes, "nose": false, "blush": true, "brows": false,
		"mouth_inner": MOUTH_INNER})
	_cut_almond_eyes()
	_build_slot_mouth()
	_build_bib()


## Moves the arm roots to follow the torso multipliers (the shared SHOULDER const is sized for an
## unscaled bean). `_apply_pose` only writes arm ROTATION, so the position survives every frame.
func _seat_shoulders(kx: float, ky: float) -> void:
	var y := TORSO_Y + TORSO_RY * ky * ((SHOULDER.y - TORSO_Y) / TORSO_RY)
	_arm_l.position = Vector3(-SHOULDER.x * kx, y, SHOULDER.z)
	_arm_r.position = Vector3(SHOULDER.x * kx, y, SHOULDER.z)


# ------------------------------------------------------------------------------ the tapered head
## THE HEAD SURFACE: the superellipsoid, with x and z pulled in below the equator by `_taper`.
## Face placement goes through the SAME map (`_orient_on_head` is overridden below), so the eyes,
## mouth and blush land exactly on the tapered shell rather than on the untapered one inside it.
static func _taper(y_frac: float) -> float:
	return 1.0 - TAPER * pow(clampf(-y_frac, 0.0, 1.0), TAPER_POW)


static func _taper_slope(y: float, semi_y: float) -> float:
	var t := -y / semi_y
	if t <= 0.0:
		return 0.0
	# d/dy of 1 - TAPER * (-y/b)^k  =  TAPER * k * (-y/b)^(k-1) / b
	return TAPER * TAPER_POW * pow(minf(t, 1.0), TAPER_POW - 1.0) / semi_y


## Maps an untapered surface point and its normal onto the tapered surface. The normal goes through
## the inverse transpose of the map's Jacobian, which is the exact normal of the deformed surface.
static func _taper_map(p: Vector3, n: Vector3, semi_y: float) -> Array:
	var s := _taper(p.y / semi_y)
	var ds := _taper_slope(p.y, semi_y)
	var j := Basis(Vector3(s, 0.0, 0.0), Vector3(p.x * ds, 1.0, p.z * ds), Vector3(0.0, 0.0, s))
	var n2 := (j.inverse().transposed() * n).normalized()
	return [Vector3(p.x * s, p.y, p.z * s), n2]


static var _head_cache: Dictionary = {}

func _tapered_head_mesh() -> ArrayMesh:
	var key := "%s|%.3f|%.3f" % [str(head_semi), head_n, TAPER]
	if _head_cache.has(key):
		return _head_cache[key]
	var src := superellipsoid(head_semi, head_n, head_segs.x, head_segs.y)
	var arr: Array = src.surface_get_arrays(0)
	var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var norms: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	for i in verts.size():
		var m: Array = _taper_map(verts[i], norms[i], head_semi.y)
		verts[i] = m[0]
		norms[i] = m[1]
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = norms
	var out := ArrayMesh.new()
	out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	_head_cache[key] = out
	return out


func _orient_on_head(node: Node3D, yaw_deg: float, pitch_deg: float, inset: float = 0.004) -> void:
	var yaw := deg_to_rad(yaw_deg)
	var pitch := deg_to_rad(pitch_deg)
	var d := Vector3(sin(yaw) * cos(pitch), sin(pitch), -cos(yaw) * cos(pitch))
	var p := se_point(d, head_semi, head_n)
	var m: Array = _taper_map(p, se_normal(p, head_semi, head_n), head_semi.y)
	var outward: Vector3 = m[1]
	node.position = (m[0] as Vector3) - outward * inset
	node.basis = Basis.looking_at(outward, Vector3.UP)


# ------------------------------------------------------------------------------ face parts
## THE ALMOND. `_eye_mesh("almond")` is a rounded octahedron (a diamond), so the lens is cut here:
## a rounded rectangle at n 2.4 for the fat lobe plus one short cone to a BLUNT point at the OUTER
## corner. Blunt is measured, not taste: the first build ran the cone to a 6 % tip at 13 degrees of
## rake, and rendered close up the thin tip read as a winged eyeliner flick — i.e. as LASHES, which
## nobody in the cast wears. A 34 % tip over a 0.78 cone at 7 degrees keeps the teardrop and loses
## the flick.
## Both live in the oval's UNIT space, so `_apply_face`'s per-frame scale (blink, EYE_WIDE) carries
## them. Outboard is local +X on the model's right eye and -X on its left (`_orient_on_head` ends in
## `Basis.looking_at`, whose +X points toward model +X for both eyes).
func _cut_almond_eyes() -> void:
	var m_eye := _toon(EYE, {"spec": 0.0, "rim": 0.0, "shade": 0.08})
	for i in _eye_ovals.size():
		var oval := _eye_ovals[i]
		oval.mesh = superellipsoid(Vector3.ONE, 2.4, 16, 9)
		var outer := 1.0 if _eyes[i].position.x > 0.0 else -1.0
		var tip := _node("Canthus", oval, Vector3(0.30 * outer, 0.0, 0.0))
		tip.rotation.z = -PI * 0.5 * outer
		_mi(taper_tube(0.78, 0.86, 0.34, 0.0, 3, 5), m_eye, tip, Vector3.ZERO, "Point")
		# The glint moves INBOARD onto the fat lobe (the shared spot is on the +X side, which on the
		# left eye is the pointed end) and up, so both eyes catch the light on the same side of the
		# face — one small dull dot each, the life that keeps a black eye from reading as a hole.
		var glint := oval.get_node_or_null("Glint") as Node3D
		if glint != null:
			glint.position = Vector3(-0.30 * outer + 0.10, 0.42, -0.52)


## THE MOUTH: a small OPEN ROUND SLOT with a tongue, sitting low on the narrowed chin. Assigned to
## `_mouth_smile` so the SMILE_HIDE_AT crossfade hands over to the real open mouth when Pip talks.
func _build_slot_mouth() -> void:
	var mouth_node := _face.get_node_or_null("Mouth") as Node3D
	if mouth_node == null:
		return
	_orient_on_head(mouth_node, 0.0, -27.0, 0.004)
	if _mouth_smile != null and is_instance_valid(_mouth_smile):
		var dead := _mouth_smile
		_mouth_smile = null
		dead.visible = false
		dead.queue_free()
	var slot := _node("Slot", mouth_node, Vector3(0.0, 0.0, -0.004))
	# A soft D: wider than tall, 88 mm on a 660 mm head = 13 % — deliberately under the 16-25 % arc
	# band, because this is an open hole and a hole reads larger than a line of the same width.
	var cav := _mi(superellipsoid(Vector3(0.046, 0.030, 0.016), 2.2, 14, 8),
		_toon(MOUTH, {"spec": 0.0, "rim": 0.0, "shade": 0.06}), slot, Vector3(0.0, 0.006, 0.0), "Cavity")
	# Tipped about X so the TOP half sinks into the chin and the bottom half stands proud: the visible
	# outline is a flat-topped D — a small open smile — rather than a round "ooh".
	cav.rotation.x = deg_to_rad(-38.0)
	_mi(sphere(1.0, 10, 5), _toon(TONGUE, {"spec": 0.0, "rim": 0.0, "shade": 0.12}), slot,
		Vector3(0.0, -0.010, -0.009), "Tongue").scale = Vector3(0.024, 0.011, 0.010)
	_mouth_smile = slot


## THE SHOP BIB: a short cream panel on the chest above the rim with a rose hem, and the star badge
## on it. It is the one piece of the Cosmo Depot uniform the brothers share.
func _build_bib() -> void:
	var k := TORSO_MUL
	var front := TORSO_RZ * k.z
	var bib_y := TORSO_Y + TORSO_RY * k.y * 0.30
	_mi(superellipsoid(Vector3(TORSO_RX * k.x * 0.78, 0.070, 0.030), 2.8, 14, 8),
		_toon(APRON, _matte({"spec": 0.02})), _torso, Vector3(0.0, bib_y, -front * 0.86), "Bib")
	_mi(superellipsoid(Vector3(TORSO_RX * k.x * 0.80, 0.012, 0.032), 2.8, 14, 5),
		_toon(TRIM, _matte({})), _torso, Vector3(0.0, bib_y + 0.064, -front * 0.86), "BibHem")
	var logo := _node("Logo", _torso, Vector3(0.0, bib_y - 0.004, -front * 0.86 - 0.030))
	_mi(_star_mesh(0.040, 0.018, 0.012), _toon(STAR, _matte({"spec": 0.05})), logo, Vector3.ZERO, "Star")


# ------------------------------------------------------------------------------ the saucer ("A")
## THE OPEN-COCKPIT SAUCER. Profile, bottom to top: a dark underside lens, the wide lilac-silver hull,
## a rose bumper ring at the equator carrying eight cream lamps, a raised deck one value step darker,
## and a padded plum ring the pilot sits in. Flat planes and a hard bumper edge, not a ball (R2.3).
func _build_craft() -> void:
	var m_hull := _toon(HULL, _matte({"spec": 0.10, "spec_size": 90.0, "rim": 0.06}))
	var m_dark := _toon(HULL_DARK, _matte({"spec": 0.04}))
	var m_deck := _toon(DECK, _matte({"spec": 0.08, "rim": 0.04}))
	var m_bump := _toon(BUMPER, _matte({"spec": 0.04}))
	var m_pad := _toon(PAD, _matte({"spec": 0.02}))
	var c := _craft_local
	# Hull: a lens at n 2.2 — flatter than an ellipsoid across the top, with a soft edge the bumper hides.
	_lens(Vector3(HULL_R, HULL_H, HULL_R), 2.0, 34, 14, m_hull, c, Vector3(0.0, CRAFT_Y, 0.0), "Hull")
	# Underside: a darker shallow dome, so the saucer has a readable dark belly (R2.3's "darker flat
	# underside") and a clear shadow shape on the ground.
	_lens(Vector3(0.36, 0.090, 0.36), 2.0, 22, 8, m_dark, c, Vector3(0.0, CRAFT_Y - 0.065, 0.0), "Belly")
	_lens(Vector3(0.12, 0.045, 0.12), 2.0, 14, 6, _toon(LAMP_OFF.darkened(0.2), _matte({"spec": 0.06})),
		c, Vector3(0.0, CRAFT_Y - 0.140, 0.0), "Keel")
	# Bumper ring round the equator, squashed so it is a band and not a doughnut.
	var bump := _mi(torus(BUMPER_R - BUMPER_TUBE, BUMPER_R + BUMPER_TUBE, 40, 8), m_bump, c,
		Vector3(0.0, CRAFT_Y, 0.0), "Bumper")
	bump.scale = Vector3(1.0, 0.60, 1.0)
	_build_lamps(BUMPER_R + BUMPER_TUBE * 0.55, CRAFT_Y + 0.004, 0.036)
	# Raised deck and the padded cockpit ring the pilot sits in.
	_lens(Vector3(DECK_R, DECK_H, DECK_R), 2.6, 28, 10, m_deck, c, Vector3(0.0, DECK_Y, 0.0), "Deck")
	var collar := _mi(torus(COLLAR_R - COLLAR_TUBE, COLLAR_R + COLLAR_TUBE, 26, 8), m_pad, c,
		Vector3(0.0, COLLAR_Y, 0.0), "Collar")
	collar.scale = Vector3(1.0, 0.80, 1.0)
	# ROUND 2: the round-1 "NoseBadge" (a dark plate with the shop star, laid on the front of the hull) is
	# GONE. From the front and gameplay cameras the plate was edge-on and rendered as a black dash across
	# the hull — a slot, or a second mouth on the saucer — and its star never showed. The star already
	# reads twice, on the mast tip and on the bib; the hull stays a clean lilac band with its lamps.


## A FLAT round part built NEAR-ROUND and squashed with a node scale. A flat `superellipsoid()` does
## not reach its own equator (see `ChibiModel._se_slab`): the first hull asked for a 560 mm radius and
## built 457 mm, which left the bumper ring floating 100 mm off the hull like a ring round a drum.
func _lens(semi: Vector3, n: float, seg: int, rings: int, mat: Material, parent: Node3D, pos: Vector3,
		node_name: String) -> MeshInstance3D:
	var r := maxf(semi.x, semi.z)
	var mi := _mi(superellipsoid(Vector3(semi.x, r, semi.z), n, seg, rings), mat, parent, pos, node_name)
	mi.scale = Vector3(1.0, semi.y / r, 1.0)
	return mi


## Lamps round the bumper, on TWO materials (odd and even) so they chase as a marquee for two draw
## materials instead of eight. Small emissive accents, which is where R2.6 lets colour be bright.
func _build_lamps(ring_r: float, y: float, r: float) -> void:
	var m_a := MaterialLib.glow(LAMP, 0.6, LAMP.darkened(0.25)).duplicate() as ShaderMaterial
	var m_b := MaterialLib.glow(LAMP, 0.6, LAMP.darkened(0.25)).duplicate() as ShaderMaterial
	_lamp_mats = [m_a, m_b]
	for i in LAMPS:
		var a := TAU * (float(i) + 0.5) / float(LAMPS)
		_mi(sphere(r, 10, 6), m_a if i % 2 == 0 else m_b, _craft_local,
			Vector3(sin(a) * ring_r, y, -cos(a) * ring_r), "Lamp")


## THE TWO LEVERS — solved from the hands, not placed by eye. `_hand_rest` gives the grip point with
## the arms at GRIP_PITCH / GRIP_ROLL; each lever then runs back down its lean from there until it
## meets the craft's own surface (`_surface_y`), and a small housing is seated on the surface at that
## point. In `_animate_extras` every lever re-aims at its hand each frame, so pushing, pumping and
## letting go all move the lever with no extra animation.
func _build_levers() -> void:
	var m_house := _toon(PAD, _matte({"spec": 0.03}))
	var m_stick := _toon(MAST.darkened(0.1), _matte({"spec": 0.08}))
	for side: Array in [[-1.0, KNOB_L], [1.0, KNOB_R]]:
		var sx: float = side[0]
		var grip := _hand_rest(sx) + GRIP_OFF
		var lean := Vector3(LEVER_LEAN.x * sx, LEVER_LEAN.y, LEVER_LEAN.z).normalized()
		# Fixed-point solve: the pivot's height depends on where it lands, which depends on the length.
		var length := LEVER_LEN
		for it in 6:
			var p0 := grip - lean * length
			length = clampf((grip.y - _surface_y(p0.x, p0.z) - 0.010) / lean.y, 0.06, 0.30)
		var pivot_pos := grip - lean * length
		var pivot := _node("Lever", _craft_local, pivot_pos)
		_mi(superellipsoid(Vector3(0.042, 0.030, 0.046), 2.8, 12, 7), m_house, pivot,
			Vector3(0.0, -0.004, 0.0), "Housing")
		var stick := _node("Stick", pivot, Vector3.ZERO)
		_mi(taper_tube(length, 0.013, 0.010, 0.0, 3, 6), m_stick, stick, Vector3.ZERO, "Rod")
		var knob := _node("Knob", pivot, lean * length)
		_mi(superellipsoid(Vector3(0.046, 0.040, 0.046), 2.4, 12, 7), _toon(side[1], _matte({"spec": 0.06})),
			knob, Vector3.ZERO, "Ball")
		stick.basis = _basis_from_up(lean)
		_lever_pivots.append(pivot)
		_lever_sticks.append(stick)
		_lever_knobs.append(knob)
		_lever_rest.append(lean)
		_lever_dir.append(lean)
		_lever_len.append(length)
		_lever_base.append(length)


## Height of the craft's top surface above (x, z) in the CraftLocal frame: the hull lens or the deck,
## whichever is higher. Exact for both, since both are node-scaled round shapes (`_lens`).
func _surface_y(x: float, z: float) -> float:
	var r := Vector2(x, z).length()
	var y := CRAFT_Y + HULL_H * sqrt(maxf(0.0, 1.0 - pow(r / HULL_R, 2.0)))
	if r < DECK_R:
		y = maxf(y, DECK_Y + DECK_H * pow(maxf(0.0, 1.0 - pow(r / DECK_R, 2.6)), 1.0 / 2.6))
	return y


## The saucer's widest radius in model space. Variants override it.
func _craft_radius() -> float:
	return BUMPER_R + BUMPER_TUBE


## Where a hand's centre sits at the grip pose, in the CraftLocal frame, solved with the same euler
## order and the same arm-local offset the rig uses (`_apply_pose` writes (pitch, yaw, -roll) on the
## left arm and (pitch, -yaw, roll) on the right; `_add_arms` hangs the hand at -ARM_LEN - 0.030).
func _hand_rest(sx: float) -> Vector3:
	var arm := _arm_r if sx > 0.0 else _arm_l
	var rot := Vector3(GRIP_PITCH, 0.0, GRIP_ROLL * sx)
	var b := Basis.from_euler(rot)
	return Vector3(0.0, SEAT_LIFT, 0.0) + arm.position + b * Vector3(0.0, -ARM_LEN - 0.030, 0.0)


## THE ONE ANTENNA: a curved mast off the back of the deck with the Cosmo Depot star on top.
func _build_mast() -> void:
	_mast = _node("Mast", _craft_local, MAST_SEAT)
	_mast.rotation.x = 0.18
	var m := _toon(MAST, _matte({"spec": 0.08}))
	_mi(rounded_box(Vector3(0.080, 0.060, 0.080), 0.024, 10), _toon(PAD, _matte({})), _mast,
		Vector3(0.0, 0.010, 0.0), "Socket")
	_mi(taper_tube(MAST_LEN, 0.022, 0.014, MAST_CURL, 7, 6), m, _mast, Vector3.ZERO, "Rod")
	var tip := taper_tube_end(MAST_LEN, MAST_CURL, 7)
	_star = _node("StarTip", _mast, tip + Vector3(0.0, STAR_R * 0.85, 0.0))
	_mi(_star_mesh(STAR_R, STAR_R * 0.46, 0.026), _toon(STAR, _matte({"spec": 0.06, "rim": 0.05})),
		_star, Vector3.ZERO, "Star")


## THE GROUND SHADOW — the cue that makes the hover read. A soft blob on the ground under the saucer,
## on the player's own shader and colour (`src/player/blob_shadow.gdshader`, which already runs on both
## renderers and under every prop), as wide as the hull. It hangs off Root at -hover so it never tilts,
## spins or hops with the craft; `_animate_extras` shrinks and fades it as the craft rises, with the
## player's laws. One quad, one draw.
func _build_ground_shadow() -> void:
	var quad := QuadMesh.new()
	var w := _craft_radius() * 2.0
	quad.size = Vector2(w, w)
	_shadow_mat = ShaderMaterial.new()
	_shadow_mat.shader = load("res://src/player/blob_shadow.gdshader")
	_shadow_mat.set_shader_parameter("color", SHADOW_COLOR)
	_shadow_mat.set_shader_parameter("softness", SHADOW_SOFT)
	_shadow = MeshInstance3D.new()
	_shadow.name = "GroundShadow"
	_shadow.mesh = quad
	_shadow.material_override = _shadow_mat
	_shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# 40 mm off the ground in MODEL space (player.gd lifts its blob 0.04 m) so it never z-fights the tiles.
	_shadow.position = Vector3(0.0, -hover_height + 0.04, 0.0)
	_shadow.rotation.x = -PI * 0.5
	_root.add_child(_shadow)


## A chunky five-point star prism in the XY plane, facing -Z, `depth` thick. Built winding-correct
## for `cull_back` (Godot fronts are clockwise seen from outside) with flat face normals.
static var _star_cache: Dictionary = {}

static func _star_mesh(r_out: float, r_in: float, depth: float) -> ArrayMesh:
	var key := "%.4f|%.4f|%.4f" % [r_out, r_in, depth]
	if _star_cache.has(key):
		return _star_cache[key]
	var pts: Array[Vector2] = []
	for i in 10:
		var a := PI * 0.5 + TAU * float(i) / 10.0
		var r := r_out if i % 2 == 0 else r_in
		pts.append(Vector2(cos(a), sin(a)) * r)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var zf := -depth * 0.5
	var zb := depth * 0.5
	for i in 10:
		var p0 := pts[i]
		var p1 := pts[(i + 1) % 10]
		# front (-Z): seen from -Z, clockwise
		_tri(st, Vector3(0, 0, zf), Vector3(p1.x, p1.y, zf), Vector3(p0.x, p0.y, zf), Vector3(0, 0, -1))
		# back (+Z)
		_tri(st, Vector3(0, 0, zb), Vector3(p0.x, p0.y, zb), Vector3(p1.x, p1.y, zb), Vector3(0, 0, 1))
		# side wall
		var e := (p1 - p0)
		var nrm := Vector3(e.y, -e.x, 0.0).normalized()
		_tri(st, Vector3(p0.x, p0.y, zf), Vector3(p1.x, p1.y, zf), Vector3(p1.x, p1.y, zb), nrm)
		_tri(st, Vector3(p0.x, p0.y, zf), Vector3(p1.x, p1.y, zb), Vector3(p0.x, p0.y, zb), nrm)
	var mesh := st.commit()
	_star_cache[key] = mesh
	return mesh


## Adds one triangle facing `nrm`, flipping the order if needed so it is clockwise from outside.
static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, nrm: Vector3) -> void:
	if (b - a).cross(c - a).dot(nrm) > 0.0:
		var t := b
		b = c
		c = t
	for v: Vector3 in [a, b, c]:
		st.set_normal(nrm)
		st.add_vertex(v)


# ===================================================================================== poses
## Every state is authored for a SEATED pilot: hands on the levers unless the emote needs them, no
## leg channels, small torso sway (the pivot is inside the cockpit, so big rolls would push the bean
## through the padded ring). The craft's own motion goes into `_craft_target`.
func _compute_target(p: PackedFloat32Array, t: float) -> void:
	for i in C.COUNT:
		_craft_target[i] = 0.0
	_craft_target[C.LAMP_RATE] = 0.6
	_craft_target[C.LAMP_GAIN] = 0.55
	super(p, t)


func _grip(p: PackedFloat32Array, push: float = 0.0) -> void:
	p[P.ARM_L_PITCH] = GRIP_PITCH + push
	p[P.ARM_R_PITCH] = GRIP_PITCH + push
	p[P.ARM_L_ROLL] = GRIP_ROLL
	p[P.ARM_R_ROLL] = GRIP_ROLL


func _pose_idle(p: PackedFloat32Array) -> void:
	var breathe := sin(TAU * _time / 2.1)
	p[P.SQUASH] = 1.0 + 0.012 * breathe
	p[P.TORSO_ROLL] = 0.02 * sin(TAU * _time / 3.9)
	p[P.HEAD_YAW] = _look_yaw
	p[P.HEAD_PITCH] = _look_pitch
	p[P.HEAD_ROLL] = 0.035 * sin(TAU * _time / 4.5)
	_grip(p, 0.03 * breathe)
	p[P.EXTRA_A] = 0.05 * breathe
	_craft_target[C.ROLL] = 0.030 * sin(TAU * _time / 3.3)
	_craft_target[C.PITCH] = 0.018 * sin(TAU * _time / 2.7 + 0.8)


## GLIDE. No stride and no footsteps: the saucer dips its nose into the direction of travel, both
## levers go forward, Pip leans in and looks ahead, and the lamps chase.
func _pose_walk(p: PackedFloat32Array) -> void:
	var amp := clampf(_speed_factor / 0.7, 0.0, 1.0)
	p[P.TORSO_PITCH] = 0.10 * amp
	p[P.TORSO_ROLL] = 0.025 * sin(TAU * _time * 0.8)
	p[P.HEAD_PITCH] = -0.08 * amp
	p[P.HEAD_ROLL] = -0.03 * sin(TAU * _time * 0.8)
	_grip(p, 0.26 * amp)
	_craft_target[C.PITCH] = PITCH_MIN * amp
	_craft_target[C.ROLL] = 0.040 * sin(TAU * _time * 0.8)
	_craft_target[C.LIFT] = LIFT_MAX * amp
	_craft_target[C.LAMP_RATE] = 3.2
	_craft_target[C.LAMP_GAIN] = 0.9


func _pose_talk(p: PackedFloat32Array, t: float) -> void:
	_pose_idle(p)
	p[P.HEAD_PITCH] += 0.05 * sin(TAU * t * 1.25)
	p[P.HEAD_ROLL] += 0.06 * sin(TAU * t * 0.7)
	p[P.MOUTH_OPEN] = 0.45 + 0.55 * maxf(0.0, sin(TAU * t * 4.2))
	# Chatty: the right hand leaves its lever to talk with; the left keeps flying.
	p[P.ARM_R_ROLL] = 0.95 + 0.25 * sin(TAU * t * 1.15)
	p[P.ARM_R_PITCH] = 0.55 + 0.30 * sin(TAU * t * 1.7)
	p[P.EXTRA_A] = 1.0
	_craft_target[C.LIFT] = 0.014 * maxf(0.0, sin(TAU * t * 4.2))
	_craft_target[C.LAMP_RATE] = 1.4


func _pose_wave(p: PackedFloat32Array, t: float) -> void:
	_pose_idle(p)
	var w := sin(TAU * t * 3.6)
	p[P.ARM_R_ROLL] = 2.35 + 0.4 * w
	p[P.ARM_R_PITCH] = -0.2
	p[P.ARM_R_YAW] = 0.28 * w
	p[P.HEAD_ROLL] = -0.16
	p[P.HEAD_YAW] = 0.10
	p[P.EYE_HAPPY] = 1.0
	p[P.MOUTH_OPEN] = 0.35
	# The saucer banks toward the waving hand and rocks with it.
	_craft_target[C.ROLL] = 0.10 + 0.03 * w
	_craft_target[C.LAMP_RATE] = 2.0


## HAPPY: the whole saucer hops and does one full turn (see `_animate_extras`), both arms up.
func _pose_happy(p: PackedFloat32Array, t: float) -> void:
	var hop := absf(sin(TAU * t / 0.62))
	p[P.BODY_Y] = HOP_MAX * hop
	p[P.SQUASH] = 1.0 + 0.07 * sin(TAU * t / 0.62 * 2.0)
	p[P.ARM_L_ROLL] = 2.6 + 0.12 * sin(TAU * t * 3.0)
	p[P.ARM_R_ROLL] = 2.6 - 0.12 * sin(TAU * t * 3.0)
	p[P.ARM_L_PITCH] = 0.12
	p[P.ARM_R_PITCH] = 0.12
	p[P.HEAD_PITCH] = -0.16
	p[P.HEAD_ROLL] = 0.09 * sin(TAU * t * 1.6)
	p[P.EYE_HAPPY] = 1.0
	p[P.MOUTH_OPEN] = 0.85
	p[P.EXTRA_B] = 1.0
	_craft_target[C.PITCH] = 0.06 * sin(TAU * t / 0.62)
	_craft_target[C.LAMP_RATE] = 4.0
	_craft_target[C.LAMP_GAIN] = 1.0


func _pose_think(p: PackedFloat32Array, t: float) -> void:
	_pose_idle(p)
	var u := clampf(t / 0.4, 0.0, 1.0)
	# Hand under the chin. The standing chibi's (-1.75, 0.75, -0.45) does not reach a seated pilot's
	# chin, so these three were SOLVED against this rig (grid search on the same euler order and arm
	# length): the mitten's centre lands 2.6 mm from a point just under and in front of the chin.
	p[P.ARM_R_PITCH] = lerpf(GRIP_PITCH, 2.06, u)
	p[P.ARM_R_ROLL] = lerpf(GRIP_ROLL, -0.36, u)
	p[P.ARM_R_YAW] = -0.08 * u
	p[P.HEAD_ROLL] = 0.20 * u + 0.03 * sin(TAU * t * 0.8)
	p[P.HEAD_PITCH] = -0.12 * u
	p[P.HEAD_YAW] = -0.14 * u
	p[P.BROW] = u
	p[P.EXTRA_A] = -1.0
	# The saucer drifts into a slow lean, nose up, and the lamps nearly stop.
	_craft_target[C.ROLL] = -0.07 * u
	_craft_target[C.PITCH] = 0.05 * u
	_craft_target[C.LAMP_RATE] = 0.2
	_craft_target[C.LAMP_GAIN] = 0.35


## DANCE: the saucer rocks on the beat and Pip pumps the levers in turn.
func _pose_dance(p: PackedFloat32Array, t: float) -> void:
	var beat := TAU * t * 2.0
	var bounce := absf(sin(beat))
	var alt := sin(beat * 0.5)
	p[P.BODY_Y] = DANCE_HOP * bounce
	p[P.SQUASH] = 1.0 + 0.05 * sin(beat * 2.0)
	p[P.TORSO_YAW] = 0.22 * alt
	p[P.TORSO_ROLL] = 0.05 * alt
	p[P.ARM_L_PITCH] = GRIP_PITCH + 0.32 * alt
	p[P.ARM_R_PITCH] = GRIP_PITCH - 0.32 * alt
	p[P.ARM_L_ROLL] = GRIP_ROLL
	p[P.ARM_R_ROLL] = GRIP_ROLL
	p[P.HEAD_ROLL] = 0.16 * alt
	p[P.HEAD_YAW] = 0.10 * sin(beat)
	p[P.MOUTH_OPEN] = 0.55
	p[P.EYE_HAPPY] = 1.0
	p[P.EXTRA_B] = 1.0
	_craft_target[C.ROLL] = ROLL_MAX * alt
	_craft_target[C.LIFT] = LIFT_MAX * bounce
	_craft_target[C.LAMP_RATE] = 5.0
	_craft_target[C.LAMP_GAIN] = 1.0


func _pose_surprised(p: PackedFloat32Array, t: float) -> void:
	var u := clampf(t / 0.3, 0.0, 1.0)
	var hop := sin(u * PI)
	p[P.BODY_Y] = HOP_MAX * hop
	p[P.BODY_Z] = 0.20 * u
	p[P.SQUASH] = 1.05
	p[P.ARM_L_ROLL] = 1.45
	p[P.ARM_R_ROLL] = 1.45
	p[P.ARM_L_PITCH] = -0.30
	p[P.ARM_R_PITCH] = -0.30
	p[P.TORSO_PITCH] = -0.12
	p[P.HEAD_PITCH] = -0.12
	p[P.EYE_ROUND] = 1.0
	p[P.EYE_WIDE] = 1.30
	p[P.MOUTH_OPEN] = 1.0
	p[P.EXTRA_B] = 1.0
	# Jolts back with its nose up, like braking hard.
	_craft_target[C.PITCH] = PITCH_MAX * u
	_craft_target[C.LAMP_RATE] = 8.0
	_craft_target[C.LAMP_GAIN] = 1.0


## `ChibiModel._apply_pose` without the legs and without the stride: a saucer makes no footsteps,
## and `footstep` is what npc.gd turns into step sounds. SQUASH goes on the pilot only — squashing
## the Root would squash the hull too.
func _apply_pose(_delta: float) -> void:
	var p := _pose
	var sq := p[P.SQUASH]
	var xz := 1.0 / sqrt(maxf(sq, 0.2))
	_root.scale = Vector3.ONE
	_torso_pivot.scale = Vector3(xz, sq, xz)
	_body.position = Vector3(0.0, p[P.BODY_Y], p[P.BODY_Z])
	_torso_pivot.rotation = Vector3(p[P.TORSO_PITCH], p[P.TORSO_YAW], -p[P.TORSO_ROLL])
	_head.rotation = Vector3(p[P.HEAD_PITCH], p[P.HEAD_YAW], p[P.HEAD_ROLL])
	_arm_l.rotation = Vector3(p[P.ARM_L_PITCH], p[P.ARM_L_YAW], -p[P.ARM_L_ROLL])
	_arm_r.rotation = Vector3(p[P.ARM_R_PITCH], -p[P.ARM_R_YAW], p[P.ARM_R_ROLL])
	_apply_face(p)


# ===================================================================================== extras
func _animate_extras(delta: float) -> void:
	if _craft == null:
		return
	_clock += delta
	var k := 1.0 - exp(-7.0 * delta)
	for i in C.COUNT:
		_craft_pose[i] = lerpf(_craft_pose[i], _craft_target[i], k)
	# Always-on hover bob, on its own clock so emotes blending in never jump its phase.
	var bob := BOB_AMP * sin(TAU * _clock / 2.4)
	_craft.position = Vector3(0.0, CRAFT_Y + bob + _craft_pose[C.LIFT], 0.0)
	# HAPPY SPIN: one full turn per happy emote. Not lerped (a lerp from TAU back to 0 would unwind
	# it); when the emote ends it eases on to the NEAREST whole turn, which is the same as zero.
	if _state == "happy":
		_spin = TAU * smoothstep(0.15, 1.35, _state_time)
	else:
		var goal := roundf(_spin / TAU) * TAU
		_spin = lerpf(_spin, goal, 1.0 - exp(-6.0 * delta))
		if absf(_spin - goal) < 1e-3:
			_spin = 0.0
	_craft.rotation = Vector3(_craft_pose[C.PITCH], _spin, _craft_pose[C.ROLL])
	if _shadow_mat != null:
		# Height above rest, in rendered metres, through the player's two laws.
		var h := maxf(0.0, (bob + BOB_AMP + _craft_pose[C.LIFT] + pose(P.BODY_Y)) * body_scale)
		var s := 1.0 / (1.0 + h * 0.3)
		_shadow.scale = Vector3(s, s, 1.0)
		_shadow_mat.set_shader_parameter("strength", 1.0 / (1.0 + h * 0.9))
	_animate_levers(delta)
	_animate_lamps(delta)
	_animate_mast()


## Each lever aims at its hand's grip point when the hand is within reach, and springs back to its
## rest lean when the hand is off doing something else (waving, thinking, cheering).
func _animate_levers(delta: float) -> void:
	if not is_inside_tree():
		return
	var hands: Array[Node3D] = [_hand_l, _hand_r]
	var k := 1.0 - exp(-16.0 * delta)
	var inv := _craft_local.global_transform.affine_inverse()
	for i in _lever_pivots.size():
		var pivot := _lever_pivots[i]
		var grip := inv * hands[i].global_position + GRIP_OFF
		var to := grip - pivot.position
		var dist := to.length()
		var base := _lever_base[i]
		var engaged := 1.0 - smoothstep(base * 1.35, base * 1.9, dist)
		var want := _lever_rest[i].slerp(to.normalized(), engaged) if dist > 1e-4 else _lever_rest[i]
		# Never let a lever lie down into the deck, whatever the hand does.
		if want.y < 0.45:
			want = Vector3(want.x, 0.45, want.z).normalized()
		_lever_dir[i] = _lever_dir[i].slerp(want, k).normalized()
		var reach := lerpf(base, clampf(dist, base * 0.8, base * 1.35), engaged)
		_lever_len[i] = lerpf(_lever_len[i], reach, k)
		# Stretch along the stick's OWN axis (its basis Y column), never the parent's.
		var b := _basis_from_up(_lever_dir[i])
		b.y *= _lever_len[i] / base
		_lever_sticks[i].basis = b
		_lever_knobs[i].position = _lever_dir[i] * _lever_len[i]


func _animate_lamps(delta: float) -> void:
	if _lamp_mats.size() < 2:
		return
	_lamp_phase += delta * _craft_pose[C.LAMP_RATE]
	var a := 0.5 + 0.5 * sin(TAU * _lamp_phase)
	var gain := _craft_pose[C.LAMP_GAIN]
	_lamp_mats[0].set_shader_parameter("emission_strength", gain * (0.25 + 1.0 * a))
	_lamp_mats[1].set_shader_parameter("emission_strength", gain * (0.25 + 1.0 * (1.0 - a)))


## The mast sways a little behind the craft's motion, flicks on every syllable, droops when thinking
## and wobbles hard on a surprise.
func _animate_mast() -> void:
	if _mast == null:
		return
	var talk := clampf(pose(P.EXTRA_A), 0.0, 1.0) * clampf(pose(P.MOUTH_OPEN), 0.0, 1.0)
	var think := clampf(-pose(P.EXTRA_A), 0.0, 1.0)
	var surpr := clampf(pose(P.EYE_ROUND), 0.0, 1.0)
	# The two wobble amplitudes here (0.05, 0.16) are the two in MAST_WOBBLE_MAX; keep them in step.
	var sway := 0.05 * sin(TAU * _clock / 1.7) - _craft_pose[C.ROLL] * MAST_ROLL_FOLLOW
	sway += surpr * 0.16 * sin(TAU * _clock * 5.0)
	_mast.rotation = Vector3(MAST_REST_TILT - _craft_pose[C.PITCH] * MAST_PITCH_FOLLOW
		+ MAST_THINK_TILT * think - MAST_TALK_TILT * talk, 0.0, sway)
	if _star:
		_star.rotation.z = 0.25 * sin(TAU * _clock / 2.9) + 0.3 * talk


# ===================================================================================== contract
## Model-space height the NPC's "!" must clear. `npc.gd` multiplies it by `body_scale` exactly as it
## does MARKER_HEIGHT. ROUND 2: round 1 returned the star's REST height (1.516) while the star really
## reached 1.555 idle, 1.625 gliding and 1.686 on the happy hop, and the dot sat on it. (Those are
## round-1 heights; the round-2 hover adds 0.12 to all of them and to this.) Now it is the
## highest the star or the crown can go anywhere inside the motion envelope, plus the dot's own reach.
func marker_clearance() -> float:
	var crown := _crown_y + BOB_AMP + RISE_MAX
	return maxf(crown, _star_top_bound()) + MARKER_DOT_REACH + MARKER_AIR


## The highest point the mast star can reach, in model space, found by walking the REAL node chain
## (Root > Body > Craft > CraftLocal > Mast > StarTip, with the positions the build gave them) over a
## grid spanning the envelope: craft pitch, roll and spin, mast tilt and sway, and every lift on top.
## The star spins in its own plane, so its top is at most its circumradius above its centre.
func _star_top_bound() -> float:
	if _mast == null or _star == null:
		return 0.0
	var reach := Vector2(STAR_R, 0.013).length()
	var lift := HOVER + RISE_MAX + CRAFT_Y + BOB_AMP
	var best := -INF
	const N := 6
	for ip in N + 1:
		var pitch := lerpf(PITCH_MIN, PITCH_MAX, float(ip) / N)
		for ir in N + 1:
			var roll := lerpf(-ROLL_MAX, ROLL_MAX, float(ir) / N)
			for isp in 8:
				var craft := Basis.from_euler(Vector3(pitch, TAU * float(isp) / 8.0, roll))
				for it in 4:
					var tilt := MAST_REST_TILT - MAST_PITCH_FOLLOW * pitch \
						+ lerpf(-MAST_TALK_TILT, MAST_THINK_TILT, float(it) / 3.0)
					for isw in 5:
						var sway := -MAST_ROLL_FOLLOW * roll + lerpf(-MAST_WOBBLE_MAX, MAST_WOBBLE_MAX, float(isw) / 4.0)
						var in_mast := Basis.from_euler(Vector3(tilt, 0.0, sway)) * _star.position
						var local := _mast.position + in_mast - Vector3(0.0, CRAFT_Y, 0.0)
						best = maxf(best, lift + (craft * local).y + reach)
	return best


## The collision capsule this body wants, in METRES (body_scale applied). The saucer, not the
## pilot, is the widest thing, so the radius is the bumper's outer edge.
func collision_size() -> Vector2:
	var r := _craft_radius() * body_scale
	var h := maxf(_crown_y * body_scale, r * 2.0 + 0.05)
	return Vector2(r, h)
