class_name VelaModel
extends ChibiModel
## Vela — the listener of the Long Array, and the cast's second robot neighbour.
##
## THE BRIEF SHE EXISTS TO SOLVE. The three robots already shipped share one grammar: Bolt and DJ
## Nova are the same `rounded_box` head to within 5 mm, both wearing a pale rectangular faceplate
## with flat eyes and a flat mouth drawn on it; Mayor Orbit is brass with smoked goggles, a top hat
## and horns. All three are `surface_kind` 0 (no surface detail at all). Vela shares NONE of that:
##
##   HEAD      a wide shallow COLLECTOR DISH on a short neck ring — 0.72 m across and 0.14 m deep,
##             the widest and flattest head in the game. It TRACKS: a slow yaw sweep that stops
##             when she speaks to you, and tips back when she thinks.
##   EYES      two smoked-jade lenses inside ONE JOINED HOOP carried 0.39 m clear of the head on a
##             pair of arched struts, exactly where a dish carries its feed. Not a faceplate, not
##             goggles, not eyestalks.
##   BLINK     a mechanical IRIS — five converging leaves per lens, driven off `_eye_open` so the
##             shared blink/squint clock runs a shutter instead of squashing an oval.
##   MOUTH     none. She is the only neighbour in the cast without one.
##   SURFACE   brushed metal grain (`surface_kind` 2) on every plate, which no other robot has.
##
## HER PUPIL IS THE RIG'S EYE. The dark disc inside each lens is the `_eye_ovals` entry, built by
## `_add_face` through the `eyes` spec list with `parent`/`pos` pointing at the hoop. So blink,
## squint, the happy "^" and the surprise "O" all still run behind the glass exactly as they do on
## every other face — the hoop only decides WHERE the eye lives, which is what `_add_eyestalks` does
## for the stalk-eyed neighbours.
##
## NO MOUTH MEANS THE TALK TELL HAS TO BE BUILT. `_pose_talk` pins `P.EXTRA_A` to 1.0 and
## `_pose_think` to -1.0; nothing else says she is speaking, so `_animate_extras` spends that channel
## on three coordinated things (see `_animate_extras`): a travelling wave around the seven amber rim
## lamps, a pulse in the chest core, and the dish giving up its sweep to face the listener.
##
## THE LEGS ARE THE POINT, NOT AN AFTERTHOUGHT. The first design for this character was a legless
## floating bell skirt. Making the one character denied legs also the one presented as feminine is
## the genie/mermaid trope, and it was struck out. SHE WALKS, on a real mechanical lower body: a hip
## yoke with visible sockets, a thigh strut, a hinged knee ring and a flat lander pad for a foot. She
## also gets a gait no one else in the cast has — `_animate_extras` flexes the trailing knee off
## `P.LEG_*_PITCH` and counter-rotates the ankle so the pad stays FLAT to the ground through the whole
## stride. Everyone else swings two rigid stubs from the hip.
##
## WHAT CARRIES HER PRESENTATION, since it is not a skirt and it is not lashes (at most one character
## in the whole cast may wear those, and it is not this one): PROPORTION — the narrowest chest in the
## cast (0.392 m against the shared 0.444), a pinched waist, a wide flat hip yoke and the tallest
## crown in the game at 1.361 m (see `marker_clearance`); PALETTE — ivory over rose-taupe and plum-grey with one warm amber core, which is
## nobody else's chord; and MANNER — the slowest blink in the cast (`blink_hold` 1.7), a slow clock
## (`anim_time_scale` 0.82), and a scan she interrupts to listen to you.
##
## HARD VOCABULARY: NONE. The cap is two of {brow ridge, heavy lid, horns, tusks, fangs, shoulder
## yoke} per character and the cast total is meant to come DOWN. Vela wears zero of them: no brows
## (`brows: false`), no lids, no horns, no teeth of any kind, and a thin turret collar ring rather
## than a yoke across the shoulders.

# ---------------------------------------------------------------------------- palette
## Ivory over rose-taupe and plum-grey, one warm amber core, smoked jade lenses. Deliberately NOT
## brass (Mayor Orbit), NOT teal (Bolt) and NOT violet (DJ Nova) — the three chords already taken by
## robots. Values are held under the 0.92 ceiling and chroma is low everywhere except the two small
## emissive accents, which R2.6 allows: "small bright accents (a seam light, a screen), just not
## whole surfaces".
const IVORY := Color("#d3c8b6")        ## S 0.137 V 0.827 — the pale plates, and the palest thing on her
const IVORY_DIM := Color("#b3a794")    ## S 0.172 V 0.702 — ivory in shadow, for inset panels
const TAUPE := Color("#ab8279")        ## S 0.292 V 0.671 — rose-taupe: the chassis
const TAUPE_DARK := Color("#8a675f")   ## S 0.312 V 0.541
const PLUM := Color("#6e5a6b")         ## S 0.187 V 0.431 — plum-grey: limbs and the hip yoke
const PLUM_DARK := Color("#4e414d")    ## S 0.169 V 0.306 — the dark value anchor every AC villager needs
const AMBER := Color("#d8a25c")        ## the core and the rim lamps; emissive, and small
const JADE := Color("#5f7d70")         ## smoked jade lens glass
const INK := Color("#221d26")          ## the pupil — the darkest thing on her, which is AC grammar

# ---------------------------------------------------------------------------- surface presets
## Brushed metal grain through `_toon`, NEVER `MaterialLib.metal()`. That call bypasses
## `ChibiModel._toon()` and so misses the character shadow-floor fix (CHAR_SHADOW_FLOOR /
## CHAR_SHADE_FLOOR), which is exactly why Bolt's ear caps shade differently from the rest of him.
##
## THREE presets, because grain frequency is a function of how big the part is in METRES. `sd_metal`
## runs its grain in model space, so one scale that reads on a 0.72 m dish turns a 0.15 m mitten into
## corduroy. Coarse on the dish (it is the largest flat surface in the cast and needs a band that
## survives 8 m), medium on the chassis, fine and weak on the limbs.
const SURF_DISH := {"surface": "metal", "surface_scale": 1.15, "surface_strength": 0.80,
	"surface_macro": 0.12, "surface_near": 8.0, "surface_far": 26.0}
const SURF_SHELL := {"surface": "metal", "surface_scale": 2.30, "surface_strength": 0.62,
	"surface_macro": 0.07, "surface_near": 6.0, "surface_far": 20.0}
const SURF_LIMB := {"surface": "metal", "surface_scale": 4.40, "surface_strength": 0.50,
	"surface_near": 5.0, "surface_far": 16.0}

# ---------------------------------------------------------------------------- the dish
## The pan: 0.720 m across and 0.144 m deep. Exponent 2.9 at (24, 12) segments keeps the per-segment
## normal swing near the shipped heads' 30 deg (see FenModel's arithmetic for why a high exponent
## needs MORE segments, not fewer).
const DISH_SEMI := Vector3(0.360, 0.072, 0.360)
const DISH_N := 2.9
## Radians about +X. NEGATIVE tips the pan's face (its local +Y) FORWARD, toward -Z, which is the way
## the model looks — so the player sees INTO the dish rather than at the back of it.
const DISH_TILT := -0.52
const DISH_OFFSET := Vector3(0.0, 0.030, 0.028)
const RIM_OUTER := 0.374               ## the rim ring's outer radius
const RIM_INNER := 0.330
const RIM_TUBE := (RIM_OUTER - RIM_INNER) * 0.5
const RIM_Y := 0.030                   ## the rim ring's height above the pan's equator
const FACE_SEMI := Vector3(0.318, 0.030, 0.318)
## THE COLLECTOR PLATE HAS TO OUT-CROWN THE PAN, and this is arithmetic, not taste. Both are
## superellipsoids about the same axis, so the plate only hides the pan where
## FACE_Y + FACE_SEMI.y > DISH_SEMI.y. The first build had 0.038 + 0.030 = 0.068 against the pan's
## 0.072, so a 4 mm dome of bare rose-taupe pan pushed THROUGH the middle of the ivory face and
## rendered as a pink oval in the centre of the dish. 0.052 + 0.030 = 0.082 puts the plate 10 mm
## proud at the centre and still 2 mm proud at its own rim (the pan is at 0.0477 there).
const FACE_Y := 0.052
const RIB_COUNT := 4
const LAMP_COUNT := 7
const LAMP_R := 0.300                  ## lamp ring radius on the dish face
## Everything mounted ON the face has to clear the plate's own crown at that radius, which falls off
## toward the rim: 0.0798 at r 0.10, 0.070 at r 0.30. The lamps and the ribs are set above the
## highest of those, not above the plate's edge, or they sink into it near the middle.
const LAMP_Y := 0.086

# ---------------------------------------------------------------------------- the hoop
## ONE JOINED HOOP, built as a stadium outline — two straight bars and two semicircular ends — rather
## than a squashed torus. A torus scaled non-uniformly to this aspect thins its own tube to 6 mm at
## the top and bottom, which is a sub-pixel wire at the 6.5 m gameplay camera; the stadium keeps a
## constant 15 mm tube all the way round. It is also the shape that lets ONE ring hold TWO lenses,
## which is the whole difference between this and Mayor Orbit's two rims plus a bridge bar.
const HOOP_CENTRE := Vector3(0.0, -0.078, -0.394)
const HOOP_HALF_W := 0.102             ## also the lens centre offset, so each lens sits in one end
const HOOP_HALF_H := 0.078
const HOOP_TUBE := 0.015
const HOOP_Z := -0.014                 ## the ring plane sits in FRONT of the lens glass
## EYE SPACING: centres 0.204 m apart on a 0.720 m head = 28.3 % geometric, and the hoop rides 0.40 m
## in front of the head's widest point so it projects wider still (~29.5 % at the 6.5 m camera) —
## inside the 28-35 % band docs/STYLE_GUIDE.md mandates, with no stalk-eye exemption needed.
const LENS_R := 0.052
const LENS_RIM_IN := 0.048
const LENS_RIM_OUT := 0.058

# ---------------------------------------------------------------------------- the iris
## Five converging leaves per lens. They retract INTO the hoop's end ring when open (base radius
## 0.070 against the ring's 0.063 inner edge, so they are half-buried in it at rest, which is what a
## real iris does) and cross the centre when closed, so the pupil is genuinely covered rather than
## squashed. `_apply_face` still squashes the pupil underneath — the leaves hide that.
const IRIS_BLADES := 5
const IRIS_OPEN := 0.062
const IRIS_CLOSED := 0.014
const IRIS_LEN := 0.026
const IRIS_R0 := 0.012
const IRIS_R1 := 0.002
const IRIS_Z := -0.018

# ---------------------------------------------------------------------------- chassis
## The chest is 0.392 m wide against the shared bean's 0.444, over a 0.300 m hip yoke: a narrow
## column that widens at the pelvis. Nothing here is a gown — the yoke is a machined block with the
## leg sockets showing, and the legs hang free below it in full view.
const CHEST_Y := 0.545
const CHEST_SEMI := Vector3(0.196, 0.150, 0.160)
const WAIST_Y := 0.408
const YOKE_Y := 0.288
const YOKE_SIZE := Vector3(0.300, 0.118, 0.238)
const GORGET_Y := 0.678
const NECK_Y := 0.790
const SHOULDER_X := 0.196              ## narrower than the shared 0.212
const SHOULDER_Y := 0.545

# ---------------------------------------------------------------------------- legs
## Hip pivots are fixed at HIP_Y = 0.245 by the shared rig, so the leg is short like everyone's — but
## it is JOINTED, which nobody else's is. Thigh 0.095, shin 0.088, then a flat pad whose sole lands
## on y = 0.
const THIGH_LEN := 0.095
const SHIN_LEN := 0.088
const PAD_SEMI := Vector3(0.096, 0.030, 0.116)

var _dish: Node3D
var _hoop: Node3D
## The two lens pivots, kept as references rather than looked up by name. GODOT RENAMES DUPLICATE
## SIBLINGS: two `_node("Lens", _hoop, ...)` calls give you "Lens" and "@Node3D@12", so a
## `name.begins_with("Lens")` scan silently finds ONE of them — which shipped an iris on her left eye
## and none on her right. Caught in the per-node triangle dump, not by eye.
var _lens: Array[Node3D] = []
var _knee: Array[Node3D] = []
var _ankle: Array[Node3D] = []
var _iris: Array[Node3D] = []
var _lamps: Array[ShaderMaterial] = []
var _core_mat: ShaderMaterial
var _t: float = 0.0


func _init() -> void:
	super()
	# The tallest neighbour (crown 1.361 m in model space, 1.388 m as rendered) and the slowest but
	# for Mayor Orbit.
	body_scale = 1.02
	anim_time_scale = 0.82
	hover_height = 0.0
	# THE SLOWEST BLINK IN THE CAST. Manner is a free differentiator and this is the cheapest one
	# there is: an iris that closes once every 5-8 s reads as unhurried and deliberate next to Zorp,
	# who blinks at the default rate, and it costs nothing.
	blink_hold = 1.7
	# A ROUND pupil, not the cast's vertical oval — a lens has a circular aperture. Small, because it
	# is a pupil inside a 0.104 m lens rather than a whole eye.
	eye_w = 0.026
	eye_h = 0.026
	eye_d = 0.008
	# She has no mouth, but `_add_face` still builds the materials from these; they are never drawn.
	mouth_w = 0.0
	mouth_h = 0.0
	# `_orient_on_head` is never called on this model (the eyes live on the hoop and there is no
	# nose, mouth or blush), but head_semi/head_n stay honest so anything that DOES ask the head for a
	# surface point gets the dish's own pan back.
	head_semi = DISH_SEMI
	head_n = DISH_N
	head_y = 1.090


func _build_geometry() -> void:
	# `rebuild()` frees every child but cannot know about these lists, and a stale pivot would be
	# read by `_animate_extras` on the very next frame.
	_dish = null
	_hoop = null
	_lens.clear()
	_knee.clear()
	_ankle.clear()
	_iris.clear()
	_lamps.clear()
	_core_mat = null

	_build_chassis()
	_build_arms()
	_build_legs()
	_build_neck()
	_build_dish()
	_build_hoop()

	# THE FACE IS TWO PUPILS AND NOTHING ELSE. No mouth (she is the only one), no nose, no blush, no
	# brows. Note that you CANNOT turn a face part off by passing a transparent colour — `toon_soft`
	# is opaque, so an alpha-0 blush renders as two black ovals on the cheeks. The switches are the
	# only way, which is why `_add_face` grew them.
	#
	# `fit_expr` is ON, and it has to be: the happy "^" arc and the surprise "O" ball are authored at
	# the chibi constants (EYE_HALF_W 0.0375, EYE_HALF_H 0.0470) and this pupil is 0.026 round. Left
	# unscaled the surprise ball would be 0.043 x 0.048 — WIDER than the pupil and nearly the size of
	# the whole lens, so "surprised" would burst her eye out of its glass.
	var eyes: Array = []
	for sx: float in [-1.0, 1.0]:
		eyes.append({
			"parent": _hoop, "pos": Vector3(HOOP_HALF_W * sx, 0.0, -0.008),
			"w": eye_w, "h": eye_h, "d": eye_d, "brow": false, "fit_expr": true,
		})
	_add_face(INK, INK, Color.TRANSPARENT, {
		"eyes": eyes, "mouth": false, "nose": false, "blush": false, "brows": false,
	})
	_build_iris()


# ============================================================================= chassis
func _build_chassis() -> void:
	var m_shell := _toon(TAUPE, _matte(SURF_SHELL))
	var m_dark := _toon(TAUPE_DARK, _matte(SURF_SHELL))
	var m_plum := _toon(PLUM, _matte(SURF_SHELL))
	var m_ivory := _toon(IVORY, _matte(SURF_SHELL))

	# Chest: a narrow column, 0.392 m across against the shared bean's 0.444. `_add_torso_bean` is
	# not used — it hardcodes the shared semi-axes and the shared TORSO_N, and the proportion IS the
	# character here.
	_mi(superellipsoid(CHEST_SEMI, 2.9, 20, 12), m_shell, _torso, Vector3(0.0, CHEST_Y, 0.0), "Chest")
	# Waist: a pinched machined collar between the chest and the hip yoke, so the column has a
	# genuine narrow point instead of tapering vaguely.
	_mi(cylinder(0.090, 0.104, 0.120, 14), m_dark, _torso, Vector3(0.0, WAIST_Y, 0.0), "Waist")
	# Hip yoke: a wide flat block with the leg sockets cut into its underside. This is the widest part
	# of her body and it is unmistakably a machined pelvis, not a hem.
	_mi(rounded_box(YOKE_SIZE, 0.046, 14), m_plum, _torso, Vector3(0.0, YOKE_Y, 0.0), "HipYoke")
	for sx: float in [-1.0, 1.0]:
		_mi(cylinder(0.048, 0.048, 0.034, 12), _toon(PLUM_DARK, _matte(SURF_LIMB)), _torso,
			Vector3(HIP_X * 1.28 * sx, YOKE_Y - 0.052, 0.0), "HipSocket%d" % int(sx + 1.0))
	# Gorget: the flat collar the neck rises out of.
	_mi(cylinder(0.112, 0.136, 0.044, 16), m_ivory, _torso, Vector3(0.0, GORGET_Y, 0.0), "Gorget")

	# CHEST PANEL via `_add_plastron`. The helper draws the rim FIRST and slightly larger, so the
	# plate always sits proud of it instead of z-fighting, and it solves the host surface's depth
	# rather than guessing a z — here the host is her own chest superellipsoid, not the shared bean,
	# so the explicit `y`/`z` are passed and the solve is skipped.
	## `seams` is 0 deliberately: a scute line is a COPY of the plate's whole mesh scaled flat (see
	## the helper's own note on why a bar does not work), so each one costs a full 154 triangles. On a
	## panel 112 mm across that is an expensive way to draw a 5 mm line nobody can see at 6.5 m, and
	## the core bezel already breaks the plate up.
	var panel := _add_plastron(IVORY, TAUPE_DARK, Vector3(0.112, 0.118, 0.038), false, _merged(SURF_SHELL, {
		"y": 0.560, "z": -(CHEST_SEMI.z - 0.038 * 0.55), "n": 2.9, "rim_w": 0.014, "seams": 0,
	}))
	# THE CORE. Warm amber behind a recessed bezel, at the centre of the panel — her voice, since she
	# has no mouth. It pulses with `P.EXTRA_A` in `_animate_extras`.
	_mi(cylinder(0.036, 0.036, 0.020, 14), _toon(PLUM_DARK, _matte({"spec": 0.05})), panel,
		Vector3(0.0, 0.006, -0.036), "CoreBezel").rotation.x = PI * 0.5
	_core_mat = lit_material(AMBER.darkened(0.42), 0.7, AMBER).duplicate() as ShaderMaterial
	_mi(cylinder(0.027, 0.027, 0.022, 14), _core_mat, panel, Vector3(0.0, 0.006, -0.041), "Core").rotation.x = PI * 0.5

	# Back: a counterweight pack, so the rear read is a machine with mass behind the dish rather than
	# a blank plate. The dish is a big lever arm out front and this is what answers it.
	_mi(rounded_box(Vector3(0.226, 0.220, 0.076), 0.030, 14), m_dark, _torso,
		Vector3(0.0, CHEST_Y - 0.010, CHEST_SEMI.z - 0.012), "Counterweight")
	for i in 3:
		_mi(rounded_box(Vector3(0.176, 0.018, 0.026), 0.008, 10), _toon(PLUM_DARK, _matte(SURF_LIMB)),
			_torso, Vector3(0.0, CHEST_Y + 0.058 - 0.062 * float(i), CHEST_SEMI.z + 0.028), "Fin%d" % i)


func _build_arms() -> void:
	# Narrower shoulders than the shared rig's +/-0.212. `rebuild()` seats the arms and `_apply_pose`
	# only ever writes their ROTATION, so moving them here is safe.
	_arm_l.position = Vector3(-SHOULDER_X, SHOULDER_Y, SHOULDER.z)
	_arm_r.position = Vector3(SHOULDER_X, SHOULDER_Y, SHOULDER.z)
	_add_arms(PLUM, IVORY, 0, SURF_LIMB, SURF_LIMB)
	# INSTRUMENT HANDS, not Bolt's pincer claws and not Zorp's three fingers: a flat palm plate and a
	# wrist band on each mitt. Reads as a hand built to hold a pen and a dial.
	var m_plate := _toon(IVORY_DIM, _matte(SURF_LIMB))
	var m_band := _toon(TAUPE_DARK, _matte(SURF_LIMB))
	for hand: Node3D in [_hand_l, _hand_r]:
		if hand == null:
			continue
		_mi(rounded_box(Vector3(0.098, 0.104, 0.024), 0.018, 10), m_plate, hand,
			Vector3(0.0, -0.004, -HAND_R * 0.76), "Palm")
		_mi(torus(0.058, 0.076, 14, 5), m_band, hand, Vector3(0.0, HAND_R * 0.88, 0.0), "WristBand")


## HER GAIT'S SKELETON. Every other neighbour swings a capsule and a boot from the hip as one rigid
## piece; Vela has a thigh strut, a hinged knee ring, a shin and an ankle, and `_animate_extras`
## drives the knee and the ankle off the shared walk channels (see there for the gait itself).
##
## `_add_legs` is deliberately not called: it builds a soft capsule leg and a shoe with a sole plate
## and a toe cap, which is the villager grammar. A lander pad is not a shoe.
func _build_legs() -> void:
	var m_strut := _toon(PLUM, _matte(SURF_LIMB))
	var m_joint := _toon(TAUPE_DARK, _matte(SURF_LIMB))
	var m_pad := _toon(PLUM_DARK, _matte(SURF_LIMB))
	var m_rail := _toon(IVORY_DIM, _matte(SURF_LIMB))
	for leg: Node3D in [_leg_l, _leg_r]:
		_mi(sphere(0.052, 10, 5), m_joint, leg, Vector3.ZERO, "HipBall")
		# taper_tube grows along +Y; a leg hangs, so the mesh is turned over in place.
		_mi(taper_tube(THIGH_LEN, 0.046, 0.038, 0.0, 4, 5), m_strut, leg, Vector3.ZERO, "Thigh").rotation.x = PI
		var knee := _node("Knee", leg, Vector3(0.0, -THIGH_LEN, 0.0))
		# A real hinge: the ring's axis runs along X, which is the axis the knee actually bends about.
		_mi(torus(0.026, 0.048, 14, 5), m_joint, knee, Vector3.ZERO, "KneeRing").rotation.z = PI * 0.5
		_mi(taper_tube(SHIN_LEN, 0.036, 0.030, 0.0, 4, 5), m_strut, knee, Vector3.ZERO, "Shin").rotation.x = PI
		var ankle := _node("Ankle", knee, Vector3(0.0, -SHIN_LEN, 0.0))
		_mi(superellipsoid(Vector3(0.034, 0.026, 0.034), 2.6, 10, 6), m_joint, ankle, Vector3.ZERO, "AnkleBlock")
		# THE PAD. Flat-bottomed and wider front-to-back than side-to-side, with a raised rail across
		# the toe: a lander foot. `_animate_extras` keeps it parallel to the ground through the whole
		# stride, which is the single clearest "this is a machine walking" cue she has.
		_mi(superellipsoid(PAD_SEMI, 3.6, 14, 8), m_pad, ankle, Vector3(0.0, -0.032, -0.018), "Pad")
		_mi(rounded_box(Vector3(0.150, 0.018, 0.030), 0.008, 10), m_rail, ankle,
			Vector3(0.0, -0.016, -0.018 - PAD_SEMI.z * 0.80), "ToeRail")
		_knee.append(knee)
		_ankle.append(ankle)


# ============================================================================= head
## The neck is SPLIT between two parents on purpose. The column belongs to the torso, so it stays put
## while she looks around; the collar ring belongs to the head, so it turns with the dish and reads
## as the turret bearing the whole assembly sits on.
func _build_neck() -> void:
	_mi(cylinder(0.072, 0.088, 0.160, 14), _toon(PLUM, _matte(SURF_LIMB)), _torso,
		Vector3(0.0, NECK_Y, 0.0), "NeckColumn")
	var collar_y := GORGET_Y + 0.192 - head_y      ## head-local, i.e. just above the neck column
	_mi(torus(0.078, 0.106, 18, 6), _toon(IVORY_DIM, _matte(SURF_SHELL)), _head,
		Vector3(0.0, collar_y, 0.0), "CollarRing")
	_mi(cylinder(0.056, 0.070, 0.092, 12), _toon(TAUPE_DARK, _matte(SURF_SHELL)), _head,
		Vector3(0.0, collar_y + 0.050, 0.0), "MastBoss")


## THE COLLECTOR DISH. Its own node so `_animate_extras` can sweep and tip it independently of the
## head — the head still carries the shared HEAD_PITCH/YAW/ROLL channels, and the dish scans on top
## of them, which is why she can be looking at you and scanning the sky at the same time.
func _build_dish() -> void:
	_dish = _node("Dish", _head, DISH_OFFSET)
	_dish.rotation.x = DISH_TILT
	var m_pan := _toon(TAUPE, _matte(SURF_DISH))
	var m_face := _toon(IVORY, _matte(SURF_DISH))
	var m_rim := _toon(TAUPE_DARK, _matte(SURF_SHELL))
	# DARK ribs on a PALE face. The first build made them IVORY_DIM on IVORY and they rendered as a
	# scatter of near-white sticks with no read at all — the only thing separating them from the
	# collector plate was a lighting accident. Dark spokes on a pale dish is the same value grammar
	# the robots' faceplates use (dark features on a pale panel), and it is legible at 8 m.
	var m_rib := _toon(TAUPE_DARK, _matte(SURF_SHELL))

	_mi(superellipsoid(DISH_SEMI, DISH_N, 22, 11), m_pan, _dish, Vector3.ZERO, "Pan")
	# The collecting surface: a shallow ivory plate standing ~3 mm proud of the pan all the way out
	# to the rim, so the dish has a FACE with a value step rather than being one solid puck.
	_mi(superellipsoid(FACE_SEMI, 3.4, 18, 8), m_face, _dish, Vector3(0.0, FACE_Y, 0.0), "Collector")
	_mi(torus(RIM_INNER, RIM_OUTER, 22, 6), m_rim, _dish, Vector3(0.0, RIM_Y, 0.0), "Rim")
	# Radial ribs. These are what make the shape read as a DISH and not a plate: a struck ring plus
	# spokes is the universally legible antenna silhouette, and five of them survive 8 m.
	for i in RIB_COUNT:
		# Offset by half a step so four spokes read as an X rather than a +, which would put one rib
		# pointing straight down the face at the hoop and one straight up out of the silhouette.
		var a := TAU * (float(i) + 0.5) / float(RIB_COUNT)
		var rib := _node("Rib%d" % i, _dish, Vector3(sin(a) * 0.200, 0.088, -cos(a) * 0.200))
		rib.rotation.y = a
		_mi(rounded_box(Vector3(0.024, 0.014, 0.208), 0.006, 8), m_rib, rib, Vector3.ZERO, "Bar")
	_build_lamps()
	# THE BACK OF THE DISH. A player walks all the way round these characters, and the underside is
	# the second-largest single surface on her. A hub boss and three stiffeners are what a dish
	# actually carries back there, and they reuse the rib mesh that is already in the cache, so the
	# whole rear detail costs one new cylinder.
	_mi(cylinder(0.070, 0.086, 0.044, 12), m_rim, _dish, Vector3(0.0, -0.084, 0.0), "BackHub")
	for i in 3:
		var a2 := TAU * float(i) / 3.0 + PI * 0.5
		var stiff := _node("Stiffener%d" % i, _dish, Vector3(sin(a2) * 0.200, -0.086, -cos(a2) * 0.200))
		stiff.rotation.y = a2
		_mi(rounded_box(Vector3(0.024, 0.014, 0.208), 0.006, 8), m_rim, stiff, Vector3.ZERO, "Bar")


## SEVEN AMBER LAMPS around the dish face — the voice of a character with no mouth. A ring rather
## than a bar, because a ring lets the talk signal TRAVEL, and a travelling wave is legible as speech
## from any angle the dish is visible from. Each lamp needs its OWN material: `_toon` (and therefore
## `lit_material`) caches on colour and options, so seven lamps built from one call would share one
## uniform and pulse in lockstep.
func _build_lamps() -> void:
	var mesh := cylinder(0.020, 0.020, 0.014, 8)
	for i in LAMP_COUNT:
		var a := TAU * float(i) / float(LAMP_COUNT)
		var mat := lit_material(AMBER.darkened(0.46), 0.3, AMBER).duplicate() as ShaderMaterial
		_mi(mesh, mat, _dish, Vector3(sin(a) * LAMP_R, LAMP_Y, -cos(a) * LAMP_R), "Lamp%d" % i)
		_lamps.append(mat)


## The hoop and the two lenses, carried clear of the head on two arched struts.
##
## THE ARCH IS TWO SEGMENTS, not one curled tube. `taper_tube`'s `curl` bends toward its own local
## +Z, and once the node has been given a `_basis_from_up` frame that direction is whatever fell out
## of the frame construction — fine for a horn growing off a head, useless when the tip has to land
## on a specific point 0.4 m away. Two straight tapered segments through an explicit mid point put
## the tip exactly where the hoop is, and the kink between them IS the arch.
func _build_hoop() -> void:
	# THE STRUTS ARE A YOKE, and they run OUTBOARD of the dish, not off it. That is the one routing
	# that survives the dish sweeping: a real dish pans inside a yoke, so the mount stays put while
	# the pan turns in it — and here it also has to, because the hoop is bolted to the HEAD (the eyes
	# keep looking at you) while the dish is on its own node turning up to 0.46 rad. A strut anchored
	# to the rim would tear off it the moment she scanned.
	#
	# Clearance is checked, not assumed. In head space the tilted rim is an ellipse of semi-axes
	# 0.374 (x) and 0.374*cos(0.52) = 0.324 (z) about the dish centre, and a yaw sweep keeps every
	# rim point within 0.374 m of the dish axis in the XZ plane. Both struts stay outside that: the
	# whole of segment A sits at |x| = 0.406, and segment B never comes closer than 0.44. The first
	# routing ran them from the NECK, behind the dish, where they were invisible from every angle a
	# player ever sees.
	#
	# THE TRUNNION BLOCK is not decoration. Without it segment A ends in a flat `taper_tube` cap
	# hanging in mid air beside her head, and the pair render as two sticks poking out of the dish —
	# the same "random rods" failure the ribs had. A bearing block at the base makes the strut a
	# MOUNT, and a mount is also the honest answer to "how does the dish pan?".
	var m_strut := _toon(PLUM, _matte(SURF_SHELL))
	var m_block := _toon(PLUM_DARK, _matte(SURF_SHELL))
	for sx: float in [-1.0, 1.0]:
		var base := Vector3(0.406 * sx, -0.010, 0.014)
		var mid := Vector3(0.406 * sx, -0.010, -0.240)
		var tip := Vector3((HOOP_HALF_W + HOOP_HALF_H) * sx, HOOP_CENTRE.y, HOOP_CENTRE.z + 0.006)
		# The two segments OVERLAP at the mid point by design: `taper_tube` caps both of its ends, so
		# the joint is two flat discs meeting at an angle. Running each segment 12 mm past the mid
		# point buries that pair of discs inside the other segment and the kink closes up — a knuckle
		# ball costs 60 triangles per side to hide the same seam.
		_strut_segment(base, mid, 0.020, 0.017, 0.012, m_strut, "StrutA%d" % int(sx + 1.0))
		_strut_segment(mid, tip, 0.017, 0.013, 0.0, m_strut, "StrutB%d" % int(sx + 1.0))
		_mi(rounded_box(Vector3(0.058, 0.090, 0.086), 0.020, 10), m_block, _head,
			Vector3(0.406 * sx, -0.006, 0.032), "Trunnion%d" % int(sx + 1.0))
		_mi(cylinder(0.026, 0.026, 0.074, 10), _toon(TAUPE_DARK, _matte(SURF_LIMB)), _head,
			Vector3(0.406 * sx, -0.006, 0.032), "Bearing%d" % int(sx + 1.0)).rotation.z = PI * 0.5

	_hoop = _node("Hoop", _head, HOOP_CENTRE)
	# DARK, and this is the single biggest legibility fix on the character. An ivory hoop on the
	# ivory collector face has no value step at all: the first build rendered as a mask painted ON
	# the dish, with no sense that the ring stands 0.39 m in front of it. A dark ring on a pale panel
	# is the cast's own grammar (Tom Nook's eye patch, the robots' screens) and it puts the hoop in
	# front of the dish instantly.
	var m_hoop := _toon(PLUM_DARK, _matte(SURF_SHELL))
	# Two straight bars top and bottom...
	for sy: float in [-1.0, 1.0]:
		var bar := _mi(capsule(HOOP_TUBE, HOOP_HALF_W * 2.0, 8, 2), m_hoop, _hoop,
			Vector3(0.0, HOOP_HALF_H * sy, HOOP_Z), "HoopBar%d" % int(sy + 1.0))
		bar.rotation.z = PI * 0.5
	# ...and two semicircular ends, each of which frames one lens.
	for sx2: float in [-1.0, 1.0]:
		var a0 := -PI * 0.5 if sx2 > 0.0 else PI * 0.5
		var a1 := a0 + PI
		_mi(arc_tube(HOOP_HALF_H, HOOP_TUBE, a0, a1, 8, 5), m_hoop, _hoop,
			Vector3(HOOP_HALF_W * sx2, 0.0, HOOP_Z), "HoopEnd%d" % int(sx2 + 1.0))

	var m_glass := _toon(JADE, _matte({"spec": 0.16, "spec_size": 150.0, "rim": 0.05, "shade": 0.20}))
	var m_lens_rim := _toon(PLUM_DARK, _matte(SURF_LIMB))
	for i in 2:
		var sx3 := -1.0 if i == 0 else 1.0
		var lens := _node("Lens%d" % i, _hoop, Vector3(HOOP_HALF_W * sx3, 0.0, 0.0))
		_mi(superellipsoid(Vector3(LENS_R, LENS_R, 0.010), 2.4, 12, 7), m_glass, lens, Vector3.ZERO, "Glass")
		_mi(torus(LENS_RIM_IN, LENS_RIM_OUT, 16, 5), m_lens_rim, lens, Vector3(0.0, 0.0, 0.004), "Rim").rotation.x = PI * 0.5
		_lens.append(lens)


## One straight tapered strut from `a` to `b`, in head-local space, running `over` metres past `b`.
func _strut_segment(a: Vector3, b: Vector3, r0: float, r1: float, over: float, mat: Material, n: String) -> void:
	var span := b - a
	var node := _node(n, _head, a)
	node.basis = _basis_from_up(span.normalized())
	_mi(taper_tube(span.length() + over, r0, r1, 0.0, 4, 5), mat, node, Vector3.ZERO, "Seg")


## THE MECHANICAL IRIS. Five leaves per lens on radial pivots; `_animate_extras` slides them along
## their own radial off `_eye_open`, so the shared blink clock that squashes everyone else's eye
## drives a shutter here instead. Each pivot carries its radial as a meta so the animation loop needs
## no bookkeeping of its own.
##
## Built AFTER `_add_face`, because the leaves have to be drawn in front of the pupil the face system
## owns — a leaf behind the pupil leaves a dark disc showing through a "closed" eye.
func _build_iris() -> void:
	# The leaves are DARK and they retract INSIDE the hoop's end ring (0.062 + 0.012 = 0.074 against
	# the ring's 0.078 centre line). The first build made them pale and 11 mm too long, so at rest
	# they stood proud of the hoop as five bright spokes per eye — which read as LASHES, the one
	# thing this cast has a standing ruling against. Measured off the render, not guessed.
	var m_blade := _toon(TAUPE_DARK, _matte(SURF_LIMB))
	for lens: Node3D in _lens:
		var plane := _node("Iris", lens, Vector3(0.0, 0.0, IRIS_Z))
		for i in IRIS_BLADES:
			var a := TAU * float(i) / float(IRIS_BLADES) + PI * 0.5
			var dir := Vector3(cos(a), sin(a), 0.0)
			var blade := _node("Blade%d" % i, plane, dir * IRIS_OPEN)
			# +Y points INWARD, at the lens centre, so the leaf is a tapered wedge aimed at the pupil.
			blade.basis = _basis_from_up(-dir)
			_mi(taper_tube(IRIS_LEN, IRIS_R0, IRIS_R1, 0.0, 4, 5), m_blade, blade, Vector3.ZERO, "Leaf")
			blade.set_meta("dir", dir)
			_iris.append(blade)


# ============================================================================= animation
func _animate_extras(delta: float) -> void:
	_t += delta
	# `_pose_talk` pins EXTRA_A to +1 and `_pose_think` to -1; idle leaves it near zero.
	var talk := clampf(pose(P.EXTRA_A), 0.0, 1.0)
	var think := clampf(-pose(P.EXTRA_A), 0.0, 1.0)

	# ---- the dish tracks. A slow sweep of the sky that she GIVES UP to face whoever is speaking to
	# her, and a tip back onto the sky when she is thinking. The sweep stopping is half the talk tell:
	# a scanning instrument going still is unmistakable, and it costs one multiply.
	if _dish != null:
		var scan := sin(TAU * _t / 7.4)
		_dish.rotation = Vector3(
			DISH_TILT - 0.10 * talk + 0.40 * think,
			0.46 * scan * (1.0 - talk) * (1.0 - 0.6 * think),
			0.045 * sin(TAU * _t / 5.1))

	# ---- the rim lamps. Idle is a slow low breath around the ring; talking runs a bright wave round
	# it once every ~0.38 s. THIS IS HER MOUTH: she is the only neighbour with none, so without an
	# explicit signal on EXTRA_A nothing at all would say she is speaking.
	var n := float(maxi(_lamps.size(), 1))
	for i in _lamps.size():
		var phase := float(i) / n
		var wave := 0.5 + 0.5 * sin(TAU * (_t * 2.6 - phase))
		var idle := 0.5 + 0.5 * sin(TAU * (_t * 0.28 - phase * 0.5))
		_lamps[i].set_shader_parameter("emission_strength",
			0.22 + 0.26 * idle + 3.0 * talk * wave * wave)

	# ---- the core answers the lamps at a different rate, so the two do not read as one blinking
	# light. It also lifts a little on "think", which is the only other place she is doing something
	# a player cannot otherwise see.
	if _core_mat != null:
		_core_mat.set_shader_parameter("emission_strength",
			0.55 + 1.7 * talk * (0.55 + 0.45 * sin(TAU * _t * 3.1)) + 0.5 * think)

	# ---- the iris. `_eye_open` is the shared blink clock; here it drives a shutter instead of a
	# vertical squash. The leaves cross the centre at full close, so the pupil (which `_apply_face` is
	# squashing underneath at the same moment) is genuinely covered.
	var open := clampf(_eye_open, 0.0, 1.0)
	var r := lerpf(IRIS_CLOSED, IRIS_OPEN, open * open)
	for b: Node3D in _iris:
		b.position = Vector3(b.get_meta("dir")) * r

	# ---- HER GAIT. The shared rig swings each leg about the hip as one rigid piece; hers is jointed.
	# The TRAILING leg (negative pitch, the one behind her) flexes its knee and the ankle takes the
	# whole of that back out again, so the flat pad stays parallel to the ground for the entire
	# stride. That is what a walking machine does and what a walking villager does not.
	#
	# Sign discipline, because it is easy to get backwards: rotation.x > 0 swings the downward leg
	# toward -Z, i.e. FORWARD. So a knee that folds the heel BACKWARD is a NEGATIVE knee rotation,
	# and the ankle cancels the sum of the two.
	for i in mini(_knee.size(), _ankle.size()):
		var lp := pose(P.LEG_L_PITCH if i == 0 else P.LEG_R_PITCH)
		var flex := 0.055 + 0.80 * clampf(-lp, 0.0, 1.2)
		_knee[i].rotation.x = -flex
		_ankle[i].rotation.x = -(lp - flex)


# ================================================================================= QA
## MARKER CLEARANCE, derived rather than guessed. `NPC.MARKER_HEIGHT` is 1.52 and npc.gd places the
## '!' at `MARKER_HEIGHT * body_scale` while `ChibiModel.rebuild()` sets `scale = ONE * body_scale`,
## so body_scale cancels and the marker always lands at 1.52 in MODEL space.
##
## Her tallest point is the BACK of the dish after the tilt — not the hoop, which hangs below the
## dish's own axis and tops out at 1.09. Two candidates, both
## taken as their bounding corner (conservative on purpose: a marker that clears by a millimetre is a
## marker drawn inside the mesh the first time anything moves). Rotating by DISH_TILT about +X sends
## a point (0, y, z) to y' = y*cos + z*|sin|:
##   pan  0.072*0.8678 + 0.360*0.4969 = 0.2414   <- the winner
##   rim  0.052*0.8678 + 0.374*0.4969 = 0.2309
##   + DISH_OFFSET.y 0.030 + head_y 1.090        = 1.361
## so npc.gd lifts the '!' to 1.361 + MARKER_CLEARANCE_GAP 0.18 = 1.541, i.e. 21 mm above its 1.52
## default. The idle breath's SQUASH scales the whole rig by up to 1.5 %, which the gap absorbs.
## Returned as a computation rather than a literal so it follows any change to the tilt or the pan.
func marker_clearance() -> float:
	var c := cos(DISH_TILT)
	var s := absf(sin(DISH_TILT))
	var top := maxf(DISH_SEMI.y * c + DISH_SEMI.z * s, (RIM_Y + RIM_TUBE) * c + RIM_OUTER * s)
	return head_y + DISH_OFFSET.y + top


## `_matte()` fills defaults into a COPY, so option dicts compose cleanly; this is just the merge.
static func _merged(base: Dictionary, extra: Dictionary) -> Dictionary:
	var o := base.duplicate()
	for k: Variant in extra:
		o[k] = extra[k]
	return o
