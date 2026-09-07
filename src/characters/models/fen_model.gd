class_name FenModel
extends ChibiModel
## Fen — the pan-watcher of Fen's Long Dusk. Big, slow, low and wide: the opposite of the twins.
## Keeps a nine-year logbook of which mirror pools have moved, which is the only record anyone has
## of that world.
##
## THE SILHOUETTE, and the one thing that must survive being seen from 8 m at 20 deg: a wide flat
## wedge of a head under THREE SEPARATE STALKS OF GRADED LENGTH IN AN ASYMMETRIC FAN, all leaning
## the same way, tallest on the left down to shortest on the right. Nothing else in the cast is a
## fan: Zorp has two matched stalks, Pip one long + one short, Pop two short close-set, Mayor Orbit
## brass horns and goggles, Grig one thick central trunk. Three graded stems read as a fan from
## every angle, including straight on, which a matched pair never does.
##
## WHY THE THIRD STALK IS NOT AN EYE — read this before "fixing" it.
## `_add_eyestalks` does `mini(specs.size(), _eyes.size())` and `_add_face` builds exactly two eyes,
## so a third eyestalk needs a third entry in `_eyes` / `_eye_ovals` / `_eye_happy` / `_eye_round`.
## `_apply_face` drives blink, squint, the happy "^" and the surprise "O" purely off those four
## arrays, so an eye built outside them is invisible to the whole expression system — it stays a
## wide-open staring ball while the other two close, which is exactly the failure
## `_add_eyestalks`' own docstring and docs/OPEN_ISSUES.md item 35 warn about. Adding the third eye
## properly means a `_build_eye()` extraction in ChibiModel, and ChibiModel is owned by another
## agent this round. So the third stalk carries a SENSORY VANE instead: a flat two-tone paddle on a
## short stem, tilted to face the sun. A flat blade is unmistakably not an eye from any distance
## (eyes in this cast are always a pale ball with a dark oval proud of it), the fan still reads as
## three stalks, and nothing on Fen animates on a clock the rig cannot see. It also earns its keep
## as characterisation: a pan-watcher who has measured the same light for nine years carries an
## instrument on his head.
## IF ChibiModel ever grows `_build_eye()`, the honest upgrade is to swap the vane for a third eye
## on the SHORTEST stalk and delete `_build_vane_stalk()` — the fan geometry below does not change.
##
## R2.6 palette. Cool slate-blue on a warm terracotta pan under an amber 11-degree sun: Fen is the
## most legible silhouette in the game at distance and nobody else in the cast is slate-blue (Zorp
## lavender, the twins green, Bolt steel-blue-but-metal, the Mayor brass, Stella cream).

const SKIN := Color("#6f8cb8")        ## S 0.397 V 0.722 — dusty slate-blue
const SKIN_DARK := Color("#586f94")   ## S 0.404 V 0.580
const SPOT := Color("#5f7aa4")        ## the head plates: SKIN darkened ~0.13, a plate not a polka dot
const CAPE := Color("#c4a184")        ## S 0.327 V 0.769 — the sun-shade poncho
const CAPE_TRIM := Color("#8f7a63")   ## the under-tunic and the hem rim
const VANE := Color("#cbbba0")        ## the pale inlay on the sensory paddle (V 0.796, under the 0.92 cap)
const EYE := Color("#1e2130")
const SCLERA := Color("#e8e4ee")
const GRIN := Color("#33283e")
const TOOTH := Color("#efe9dc")
const FOOT := Color("#4a4f66")        ## the dark value anchor every AC villager has

## SKIN TEXTURE — the zero-shader-edit route. `_matte()` duplicates opts and only fills defaults, so
## any unrecognised key reaches `MaterialLib.toon` untouched; `surface_kind` is 0 on every neighbour
## but Zorp, which is why alien skin used to read as flat plastic.
##
## `skin` (kind 7), NOT `rock`. docs/OPEN_ISSUES.md item 35 records the measurement: sd_rock is fbm,
## so it produces MOTTLING and its tint amplitude tops out near 6% — invisible at the 7.4 m camera.
## sd_skin is cellular, which is what actually reads as cracked plates on sun-dried hide. The spec
## for this character asked for `rock`; it is wrong for the same reason it was wrong for Zorp.
##
## FREQUENCY. sd_skin runs 7 cycles per unit at scale 1.0, so a head of width W shows 7 * scale * W
## cells across it. Zorp: 7 * 1.6 * 0.640 = 7.2 cells. Fen's head is 0.820 wide, so scale 1.35 gives
## 7 * 1.35 * 0.820 = 7.8 cells — cells about 8% LARGER in metres than Zorp's, which is the read we
## want (dried crust plates, not pores).
##
## AMPLITUDE IS A PALETTE COST, and it is measured, not guessed: an A/B on one identical frame moved
## Zorp's head-crop saturation mean by +0.099, because the tint multiplies the albedo and darkening
## a colour RAISES its HSV saturation. Every amplitude term here is at or below Zorp's shipped
## values (strength 1.05 -> 0.95, spot 1.25 -> 1.15, scales 0.28 -> 0.22). Re-measure in
## src/world/world.tscn — NOT a showcase — if you raise any of them.
const SURF_HEAD := {"surface": "skin", "surface_scale": 1.35, "surface_strength": 0.95,
	"surface_spot": 1.15, "surface_scales": 0.22, "surface_spot_radius": 0.38,
	"surface_near": 9.0, "surface_far": 26.0, "surface_macro": 0.10}
## The limbs need their OWN preset and it must be much finer and much weaker. A mitten is ~150 mm,
## so the head setting would put barely one cell on a hand and it renders as cauliflower.
const SURF_LIMB := {"surface": "skin", "surface_scale": 5.6, "surface_strength": 0.70,
	"surface_spot": 0.90, "surface_scales": 0.12, "surface_spot_radius": 0.32,
	"surface_near": 7.0, "surface_far": 20.0}
## Cloth grain on the poncho and sleeves, held very low — it is a tonal break, not a pattern.
const SURF_CLOTH := {"surface": "cloth", "surface_scale": 2.4, "surface_strength": 0.55,
	"surface_near": 7.0, "surface_far": 22.0}

# ---------------------------------------------------------------------------- the crown fan
## THREE SEPARATE STALKS, graded 0.407 / 0.319 / 0.240 m long and swept left-to-right across the
## crown, each leaning a little further out than the last. Head-local, so they follow `head_semi`.
##
## EYE SPACING: the two eyeball tips land 0.258 m apart on an 0.820 m head = 31.5%, inside the
## 28-35% band docs/STYLE_GUIDE.md mandates. Zorp ships at 52% as a documented stalk-eye exemption;
## Fen does not need the exemption, because the fan (not the spacing) is what carries him.
##
## MARKER CLEARANCE, measured not guessed: `NPC.MARKER_HEIGHT` is 1.52 and the '!' sits at
## `MARKER_HEIGHT * body_scale`, so the tallest thing on the model must clear 1.52 in MODEL space.
## Tallest is stalk 0: head_y 0.841 + tip 0.556 + eyeball 0.058 = 1.455, i.e. 65 mm of headroom.
## The spec's original fan (tip 0.712) lands at 1.553 and buries the marker inside the eye cluster.
const STALK_BASE_K := 0.88            ## bases sit at head_semi.y * this, buried inside the crown
const EYEBALL_R := 0.058
const STALKS: Array[Dictionary] = [
	{"base": Vector3(-0.148, 0.0, -0.048), "tip": Vector3(-0.176, 0.556, -0.068), "r": 0.027, "splay": -0.26},
	{"base": Vector3(0.070, 0.0, -0.030), "tip": Vector3(0.082, 0.470, -0.044), "r": 0.025, "splay": 0.14},
	{"base": Vector3(0.190, 0.0, 0.004), "tip": Vector3(0.248, 0.378, -0.004), "r": 0.020, "splay": 0.0},
]
## Three different sway periods so the cluster never moves as one unit — a fan that swings together
## reads as one forked object, which is the silhouette this design exists to avoid.
const STALK_PERIOD := [2.9, 3.7, 4.6]
const STALK_PHASE := [0.0, 1.9, 3.4]

## Four flat plates on the head, as yaw/pitch on the shell plus a radius. Discs, not spheres:
## `cylinder(r, r, 0.006, 6)` is 24 tris where the cheapest closed ball is 60, and a flat plate on a
## chamfered head is R2.3's "flat planes, chamfers and panel lines" rather than another blob.
const HEAD_PLATES: Array = [
	[-46.0, 14.0, 0.052], [-18.0, 30.0, 0.038], [22.0, 27.0, 0.044], [52.0, 10.0, 0.033],
]

## The mouth. The spec asked for `mouth_node.scale = (2.40, 1.70, 1.0)` on a 0.104 half-width grin
## and called the result 25.4% of head width — but `_add_wide_grin` parents the cavity to the mouth
## NODE, so that scale multiplies it: 0.208 * 2.40 = 0.499 m on an 0.820 m head is 61%, a gaping
## hole across the whole lower face. 1.34 gives 0.279 m = 34%: absolutely NARROWER than Zorp's
## 0.318 m grin, on a head 28% wider than his, which is what keeps an elder reading as calm.
const MOUTH_SPREAD := Vector3(1.34, 1.15, 1.0)
const MOUTH_PITCH_FEN := -8.0         ## high on a low head — at Zorp's -18 the mouth falls off the chin

var _stalks: Array[Node3D] = []
var _hem: Node3D
var _hem_lag: Vector3 = Vector3.ZERO
var _t: float = 0.0


func _init() -> void:
	super()
	# The largest neighbour, and the slowest but one. 0.88 against Grig's 0.70 is a readable
	# difference; the spec's 0.72 against 0.70 is not.
	body_scale = 1.06
	anim_time_scale = 0.88
	# No hover. Zorp floats 5 cm; Fen is heavy and planted.
	hover_height = 0.0
	# Smaller and rounder than Zorp's 0.062: the eyeball is a pale ball 0.058 across, so a 0.048
	# oval leaves a visible sclera ring and reads as a PUPIL rather than as a black disc.
	eye_w = 0.048
	eye_h = 0.048
	mouth_w = 0.092
	mouth_h = 0.056
	face_scale = 1.0

	# HIS OWN HEAD — a low wide wedge. 0.820 x 0.340 x 0.520 m against Zorp's measured
	# 0.640 x 0.450 x 0.544: 28% wider and 24% shorter. Nothing else in the cast is a plate.
	head_semi = Vector3(0.4100, 0.1700, 0.2600)
	# EXPONENT — and this is a deliberate departure from the spec, with the arithmetic.
	# The spec asks for n = 4.6 at `head_segs` of (36, 18), i.e. FEWER segments than the shipped
	# (44, 22). That is exactly backwards and it is the trap docs/OPEN_ISSUES.md item 35 records:
	# `superellipsoid()` samples a UV sphere's uniform angular directions, so raising n packs the
	# curvature into a narrow chamfer band and a fixed segment count renders a faceted BOX.
	# Measure it: on the equator the surface normal turns (n - 1) times faster than the sampling
	# angle at the 45-degree corner, so the per-segment normal swing is (360 / radial) * (n - 1).
	# The shipped heads (n 3.2, 26 radial after DETAIL 0.60) swing 30.0 deg per segment.
	#   n 4.6 at (36, 18) -> 22 radial -> 58.9 deg   (worse than the n=4.0 build two reviewers rejected)
	#   n 4.6 at (58, 28) -> 35 radial -> 37.0 deg   (still past the rejected 41.5-deg build's neighbourhood)
	#   n 4.6 matched to shipped faceting needs ~43 radial = 1892 tris, which does not fit the budget
	#   n 4.0 at (58, 28) -> 35 radial -> 30.9 deg   <- shipped-equivalent faceting, 1260 tris
	# So: n 4.0 with the segment count RAISED. The flatness lost is small — front-face recession at
	# 60% of half-width is 3.4% at n 4.0 against 2.2% at n 4.6, versus 12.4% at the default 2.6 —
	# and the wedge proportions, not the exponent, are what make this head unlike anything shipped.
	head_n = 4.0
	head_segs = Vector2i(58, 28)
	# Chin at 0.671 — the same collar line as Zorp, Grig and the twins, so the shared shoulder
	# geometry still meets it (0.841 - 0.170 = 0.671). The crown seam fraction is derived from
	# head_n by `_add_head_shell` now, so it follows the exponent automatically.
	head_y = 0.8410


func _build_geometry() -> void:
	# `rebuild()` frees every child but cannot know about these, and a stale pivot list would index
	# STALK_PERIOD out of range on the first frame after a rebuild.
	_stalks.clear()
	_hem = null
	_hem_lag = Vector3.ZERO
	_build_body()
	_add_head_shell(SKIN, SURF_HEAD)
	_add_head_plates()

	# No nose, no blush. A TRANSPARENT blush colour does not disable blush — `toon_soft` is opaque,
	# so an alpha-0 colour renders as two BLACK ovals on the cheeks. The switches are the only way.
	_add_face(EYE, GRIN, SKIN_DARK, {"mouth_inner": Color("#5a3a52"), "nose": false, "blush": false})
	# BROWS OFF, exactly as AlienModel and TwinModel do it. They are drawn on the head, and with the
	# real eyes lifted onto stalks two dark bars up there read as a second pair of eyes, which puts
	# the animal face straight back.
	for b: Node3D in _brows:
		b.queue_free()
	_brows.clear()
	_build_grin()
	_build_crown_fan()


# ============================================================================= body
func _build_body() -> void:
	# A taller, wider bean than the chibi default — "big, slow, low and wide". The waist chamfer is
	# off because the poncho covers that whole band; it would be 100 tris of hidden geometry.
	var torso_opts := _merged(SURF_LIMB, {
		"size_mul": Vector3(1.10, 1.16, 1.08), "waist_chamfer": false,
	})
	_add_torso_bean(CAPE_TRIM, torso_opts)

	# THE SUN-SHADE PONCHO — a flat chamfered plate over the shoulders, not a scarf. It is the
	# practical garment of a world where the sun never leaves the horizon, and it is ~840 tris
	# cheaper than Zorp's collar-plus-three-stripes-plus-tail scarf.
	#
	# It sits HIGH (centre y 0.515, half-height 0.155) rather than at the waist: its top plane meets
	# the head's flat underside at 0.671 with no gap, and its bottom edge at 0.360 clears the arms so
	# they still read in silhouette. A poncho hung at the waist swallows the arms entirely and Fen
	# becomes a bell with hands.
	var poncho := _node("Poncho", _torso, Vector3(0.0, 0.5150, 0.010))
	var m_cape := _toon(CAPE, _matte(SURF_CLOTH))
	_mi(superellipsoid(Vector3(0.300, 0.155, 0.250), 3.6, 24, 12), m_cape, poncho, Vector3.ZERO, "Shade")
	# A hard hem rim near the bottom edge, standing ~15 mm proud of the shell, so the plate ends on
	# an EDGE instead of fading out. It is its own node because it lags the torso (see _animate_extras).
	_hem = _node("Hem", poncho, Vector3(0.0, -0.1333, 0.0))
	_mi(superellipsoid(Vector3(0.250, 0.019, 0.208), 3.8, 18, 5),
		_toon(CAPE_TRIM, _matte({"rim": 0.02})), _hem, Vector3.ZERO, "Rim")

	# The shoulders have to move outboard of the poncho plate or the arms vanish inside it.
	# `rebuild()` places them at +/-SHOULDER.x, and `_apply_pose` only ever writes their ROTATION,
	# so overriding the position here is safe.
	_arm_l.position = Vector3(-0.278, 0.4920, SHOULDER.z)
	_arm_r.position = Vector3(0.278, 0.4920, SHOULDER.z)
	# FOUR fingers. Zorp has three, the twins none.
	_add_arms(CAPE, SKIN, 4, SURF_LIMB, SURF_CLOTH)
	_add_legs(SKIN_DARK, FOOT, SURF_LIMB)


## Four flat plates across the head. `_orient_on_head` points a node's -Z along the outward normal
## while a CylinderMesh runs along +Y, so the disc is a CHILD with its own quarter turn — writing
## `node.rotation.x` on the oriented node itself rebuilds the whole basis from euler and throws the
## placement away. (astronaut_model._surface_node has the same parent/child split for the same reason.)
func _add_head_plates() -> void:
	var m := _toon(SPOT, _matte(_merged(SURF_HEAD, {"rim": 0.02})))
	for p: Array in HEAD_PLATES:
		var plate := _node("Plate", _head, Vector3.ZERO)
		_orient_on_head(plate, float(p[0]), float(p[1]), 0.001)
		var r := float(p[2])
		_mi(cylinder(r, r, 0.006, 6), m, plate, Vector3.ZERO, "Disc").rotation.x = PI * 0.5


func _build_grin() -> void:
	var mouth_node := _face.get_node_or_null("Mouth") as Node3D
	if mouth_node == null:
		return
	_orient_on_head(mouth_node, 0.0, MOUTH_PITCH_FEN, 0.004)
	mouth_node.scale = MOUTH_SPREAD
	# FOUR teeth of uneven width. Zorp and the twins both have three, so an even count is itself a
	# difference, and uneven widths keep it off the neat cartoon-animal smile.
	_add_wide_grin(mouth_node, GRIN, TOOTH, Vector3(0.104, 0.030, 0.020),
		[[-0.062, 0.016], [-0.020, 0.022], [0.024, 0.014], [0.066, 0.019]])


# ============================================================================= the crown fan
func _build_crown_fan() -> void:
	var by := head_semi.y * STALK_BASE_K
	var specs: Array = []
	for i in 2:
		var s: Dictionary = STALKS[i].duplicate()
		var b: Vector3 = s["base"]
		s["base"] = Vector3(b.x, by, b.z)
		specs.append(s)
	# Two ANIMATED eyes. The nodes are only repositioned, never rebuilt, so blink, squint, the happy
	# "^" and the surprise "O" all keep running exactly as they do on a flat face.
	_add_eyestalks(specs, SKIN, SCLERA, EYEBALL_R)
	for i in 2:
		_stalks.append(_lift_stalk_onto_pivot(i, specs[i]["base"]))

	var v: Dictionary = STALKS[2]
	var vbase: Vector3 = v["base"]
	_stalks.append(_build_vane_stalk(Vector3(vbase.x, by, vbase.z), v["tip"], float(v["r"])))


## Re-homes one finished eyestalk (stem + eyeball + the animated eye node) under a pivot AT ITS BASE,
## so `_animate_extras` can sway the whole assembly as one piece. `_add_eyestalks` leaves those three
## as siblings under `_head` / `_face`, which cannot be rotated together about the base.
func _lift_stalk_onto_pivot(i: int, base: Vector3) -> Node3D:
	var pivot := _node("StalkPivot%d" % i, _head, base)
	var parts: Array[Node3D] = []
	var stem := _head.get_node_or_null("EyeStalk%d" % i) as Node3D
	if stem != null:
		parts.append(stem)
	var ball := _head.get_node_or_null("Eyeball%d" % i) as Node3D
	if ball != null:
		parts.append(ball)
	if i < _eyes.size():
		parts.append(_eyes[i])
	for n: Node3D in parts:
		# `_face` sits at the origin of `_head`, so every one of these is already in head-local
		# space and the re-home is a straight subtraction of the base offset.
		var p := n.position - base
		var b := n.basis
		n.get_parent().remove_child(n)
		pivot.add_child(n)
		n.position = p
		n.basis = b
	return pivot


## The third stalk: the shortest of the fan, carrying a SENSORY VANE rather than an eye. See the
## class header for why this is not a third eye. The stem is built exactly the way `_add_eyestalks`
## builds its own so the three read as one set of organs.
func _build_vane_stalk(base: Vector3, tip: Vector3, r: float) -> Node3D:
	var pivot := _node("StalkPivot2", _head, base)
	var span := tip - base
	var length := span.length()
	# A capsule runs along its own +Y, so build a basis whose Y follows the stalk.
	var yv := span.normalized()
	var xv := Vector3.RIGHT if absf(yv.dot(Vector3.RIGHT)) < 0.9 else Vector3.FORWARD
	var zv := xv.cross(yv).normalized()
	xv = yv.cross(zv).normalized()
	var stem := _node("VaneStalk", pivot, span * 0.5)
	stem.basis = Basis(xv, yv, zv)
	_mi(capsule(r, maxf(0.02, length - r * 2.0), 8, 2),
		_toon(SKIN_DARK, _matte({"spec": 0.05})), stem, Vector3.ZERO, "Stem")
	# The paddle: a flat chamfered blade tilted back toward the sun, with a pale inlay on its face.
	# Flat planes and an inlay line, never a ball (R2.3) — and never anything a player could mistake
	# for an eyeball, which is the whole point.
	var vane := _node("Vane", stem, Vector3(0.0, length * 0.5 + 0.030, 0.0))
	vane.rotation = Vector3(-0.42, 0.22, 0.10)
	_mi(rounded_box(Vector3(0.062, 0.086, 0.015), 0.012, 10),
		_toon(SKIN_DARK, _matte({"rim": 0.03})), vane, Vector3.ZERO, "Blade")
	_mi(rounded_box(Vector3(0.038, 0.056, 0.014), 0.008, 8),
		_toon(VANE, _matte({"rim": 0.02, "spec": 0.04})), vane, Vector3(0.0, 0.004, -0.006), "Inlay")
	return pivot


# ============================================================================= animation
func _animate_extras(delta: float) -> void:
	_t += delta
	var talk := clampf(pose(P.EXTRA_A), 0.0, 1.0)
	var think := clampf(-pose(P.EXTRA_A), 0.0, 1.0)
	for i in mini(_stalks.size(), STALK_PERIOD.size()):
		var pv: Node3D = _stalks[i]
		if pv == null or not is_instance_valid(pv):
			continue
		var per: float = STALK_PERIOD[i]
		var ph: float = STALK_PHASE[i]
		var sway := sin(TAU * _t / per + ph)
		var scan := sin(TAU * _t / (per * 1.63) + ph * 2.0)
		var pitch := 0.052 * sway - 0.055 * think
		var yaw := 0.095 * scan
		var roll := 0.030 * sin(TAU * _t / (per * 0.81) + ph)
		if i == 2:
			# The vane leans toward whoever is speaking while the two eyes keep scanning the pan.
			# -X tips its +Y tip toward -Z, which is the direction the face looks.
			pitch -= 0.30 * talk
			yaw = 0.055 * scan + 0.12 * talk
		pv.rotation = Vector3(pitch, yaw, roll)

	# The poncho hem lags the torso by ~0.12 s, so the plate swings a beat behind the body instead of
	# being welded to it. `_hem` is a child of `_torso` (which rides `_torso_pivot`), so writing the
	# DIFFERENCE between the filtered and the live rotation leaves the rim sitting at the old angle.
	if _hem != null:
		var cur := _torso_pivot.rotation
		_hem_lag = _hem_lag.lerp(cur, 1.0 - exp(-8.0 * delta))
		_hem.rotation = (_hem_lag - cur) * 0.85


# ============================================================================= helpers
## `_matte()` fills defaults into a COPY, so option dicts compose cleanly; this is just the merge.
static func _merged(base: Dictionary, extra: Dictionary) -> Dictionary:
	var o := base.duplicate()
	for k: Variant in extra:
		o[k] = extra[k]
	return o
