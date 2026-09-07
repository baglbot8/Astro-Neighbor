class_name FenModel
extends ChibiModel
## Fen — the pan-watcher of Fen's Long Dusk. Big, slow, low and wide: the opposite of the twins.
## Keeps a nine-year logbook of which mirror pools have moved, which is the only record anyone has
## of that world.
##
## THE SILHOUETTE, and the one thing that must survive being seen from 8 m at 20 deg: a wide flat
## wedge of a head under THREE SEPARATE EYESTALKS OF GRADED LENGTH IN AN ASYMMETRIC FAN, all leaning
## the same way, tallest on the left down to shortest on the right. Nothing else in the cast is a
## fan: Zorp has two matched stalks, Pip one long + one short, Pop two short close-set, Mayor Orbit
## brass horns and goggles, Grig one thick central trunk. Three graded stems read as a fan from
## every angle, including straight on, which a matched pair never does.
##
## R4: THE THIRD STALK IS NOW A REAL EYE. The version of this file that shipped before R4 carried a
## flat sensory VANE on the shortest stalk and a long comment explaining why it could not be an eye:
## `_add_eyestalks` walks `mini(specs.size(), _eyes.size())` and `_add_face` hardcoded exactly two
## eyes, so a third eye would have been invisible to `_apply_face` and would have sat wide open and
## staring while the other two blinked. Both halves of that are fixed in ChibiModel now —
## `_add_face` takes a LIST of eye specs and `_build_eye` is the single thing that appends to the
## five parallel arrays — so the fan is three real eyes and the vane is gone.
##
## WHAT MAKES THE FAN GRADED RATHER THAN THREE COPIES, and all three parts are load-bearing:
##  1. STEM LENGTH — 0.407 / 0.319 / 0.240 m, unchanged from the vane build.
##  2. EYEBALL SIZE — 0.058 / 0.052 / 0.044 m, via the per-spec `eyeball_r` key `_add_eyestalks`
##     now reads. Without it the helper's single `eyeball_r` argument would put three IDENTICAL
##     balls on three different stems, which reads as a manufacturing error, not an organism.
##  3. PUPIL SIZE — 0.048 / 0.043 / 0.036 half-width, via `_eye_size`. Before that array existed
##     `_apply_face` rewrote every oval from the model-wide `eye_w`/`eye_h` on frame 1, so a per-eye
##     size authored on frame 0 was stamped flat immediately. Each pupil is ~0.82 of its own ball,
##     so all three keep the same sclera ring and read as one set of organs at three sizes.
## The three eyes land in `_eyes` / `_eye_ovals` / `_eye_happy` / `_eye_round` / `_eye_size` in the
## same order and the same length, so blink, squint, the happy "^" and the surprise "O" all drive
## every one of them. `fit_expr` is deliberately LEFT OFF: her model-wide eye is 0.048 against the
## chibi 0.0375, so turning it on would resize the shipped happy arc and surprise ball on the two
## larger eyes. The per-eye ratio (which is always applied) already grades all three against each
## other, which is the part the fan actually needs.
##
## BLINK RIPPLE — see `_animate_extras`. The three eyes do not blink in unison; the lid runs down
## the fan tallest-first at 60 ms a step. It is the single cheapest thing on this model (no
## triangles, no nodes) and it is what stops three stalks reading as one forked object.
##
## SKIN: JUST SCALY. She is off the spot-dominant `sd_skin` preset she used to share with three
## other neighbours and onto `sd_scales` (kind 8) — genuine overlapping shingle rows with a painter's
## order, so a scale passes IN FRONT OF the row below it and casts an occlusion crease at its free
## edge. That is a different silhouette of detail, not a different speckle, and it leaves Grig the
## cracked craze outright. Zero triangles, which is exactly what this budget can afford.
##
## HER READ — proportion, drape and manner, not accessories. The broadest and lowest-shouldered body
## in the cast (body_scale 1.06, torso 1.10 x 1.16 x 1.08, shoulders outboard at +/-0.278 and 13 mm
## below the chibi line); a long asymmetric shawl whose fall hangs past the left hip and whose hem
## and fall both LAG the torso, so the garment settles a beat after she does; a WARM rose-clay wrap
## on a COOL slate body, which is the exact inversion of Grig's cool smock on warm clay and is what
## keeps the two elders apart at 8 m; one of the slowest gaits in the cast; and the slowest blink of
## anyone, because she has watched the same low light for nine years.
## She carries NONE of {brow ridge, heavy lid, horns, tusks, fangs, shoulder yoke} — no member of
## that vocabulary appears anywhere on this model. That is a deliberate cast-wide ruling: at least
## one of the three elders wears none of it, and she is the one.
##
## R2.6 palette. Cool slate-blue under a rose-clay wrap, on a warm terracotta pan under an amber
## 11-degree sun: Fen is the most legible silhouette in the game at distance and nobody else in the
## cast is slate-blue (Zorp lavender, the twins green, Bolt steel-blue-but-metal, the Mayor brass,
## Stella cream).

const SKIN := Color("#6f8cb8")        ## S 0.397 V 0.722 — dusty slate-blue
const SKIN_DARK := Color("#586f94")   ## S 0.404 V 0.580
## THE WRAP, warmed from the old tan #c4a184 to a dusty rose-clay, and DESATURATED with it. Three
## reasons, and the third one was found by rendering, not by arithmetic:
##  * the hue moves off the terracotta pan she stands on (a tan garment on a terracotta world is one
##    mass at 8 m) and away from Grig's warm clay body, which is what keeps the two elders apart;
##  * S drops 0.327 -> 0.198 at nearly the same value (V 0.769 -> 0.753), which buys back headroom
##    on the saturation gate that the new full-coverage `sd_scales` tint spends;
##  * the first build of this colour was #c49a94 at S 0.245, which is a defensible number on paper
##    and rendered as SALMON — `toon_soft`'s warm key light pushes a mid-value warm albedo up in
##    chroma, so a garment this large has to be authored below where the swatch looks right. The
##    blue channel is lifted (154 against a tan's 132) specifically to grey it, not to cool it.
const CAPE := Color("#c09f9a")        ## S 0.198 V 0.753 — the shawl
const CAPE_TRIM := Color("#907066")   ## S 0.292 V 0.565 — under-tunic, hem rim, and the fall's end
const EYE := Color("#1e2130")
const SCLERA := Color("#e8e4ee")
const GRIN := Color("#33283e")
const TOOTH := Color("#efe9dc")
const FOOT := Color("#4a4f66")        ## the dark value anchor every AC villager has

## SKIN TEXTURE — the zero-shader-edit route. `_matte()` duplicates opts and only fills defaults, so
## any unrecognised key reaches `MaterialLib.toon` untouched.
##
## `scales` (kind 8), NOT `skin` (kind 7) and NOT `rock`. sd_rock is fbm, so it produces MOTTLING
## and its tint amplitude tops out near 6% — invisible at the 7.4 m camera (docs/OPEN_ISSUES.md item
## 35). sd_skin is cellular blobs on a cell ground, which is cracked sun-dried mud: right for a
## stonecutter, wrong for a reptile, and it is what Zorp, the twins and Grig are already spending.
## sd_scales is the only function in the library where one feature passes IN FRONT OF another.
##
## FREQUENCY. sd_scales runs 9 cycles per unit at scale 1.0, so a head of width W shows 9 * scale * W
## rows across it. Her head is 0.820 wide, so scale 1.85 gives 9 * 1.85 * 0.820 = 13.7 rows — 60 mm
## scales, ~7 px at the ~117 px/m gameplay camera that grig_model.gd's strata arithmetic uses, which
## is well past that file's ~2.8 px legibility bar. Reptile shingles, not a speckle.
##
## AMPLITUDE IS A PALETTE COST, and it is measured, not guessed: an A/B on one identical frame moved
## Zorp's head-crop saturation mean by +0.099, because the tint multiplies the albedo and darkening
## a colour RAISES its HSV saturation. sd_scales differs from sd_skin in a way that matters here:
## sd_skin's spot term only fires on the ~5% of the surface a blob covers, while sd_scales tints
## EVERY fragment, and its bump term perturbs every fragment's normal as well.
##
## STRENGTH 0.45, AND THE FIRST BUILD AT 0.85 WAS WRONG. Its DC (the measured mean of
## `top - occl * 0.55`, 0.4442) is subtracted inside the shader, so the mean albedo multiplier is
## 1.0 at any strength and the arithmetic says 0.85 is safe — it is not. Rendered at 0.85 and
## scale 1.40 the head came back as soft round BUBBLES, which is the exact "too bubbly" read
## art-direction revision 2 rejects: `s.bump = vec3(d) * 0.11 * strength` tilts the normal on every
## fragment, and at that amplitude the lobes shade like balls rather than like plates with an edge.
## Halving the strength and raising the frequency is what turns them back into overlapping shingles
## with a visible free edge. Re-measure in src/world/world.tscn — NOT a showcase — if you raise it,
## and LOOK at it, because the number that passes the gate is not the number that reads.
##
## R5 — 0.45 WAS STILL BUBBLES, AND THIS IS THE THIRD SETTING. Captured at the 6.5 m gameplay
## distance and in a face close-up, the 1.85/0.45 build read as a BLACKBERRY: ~8 lobes across the
## head, each one a fat dome, which is "lumpy" in exactly the sense art-direction revision 2
## rejects. The note above had the remedy right and did not go far enough. Applying it a second
## time — strength halved again, frequency raised — gives ~13 scales across the head at an
## amplitude where `bump` tilts the normal enough to find the free edge and not enough to inflate
## the face into a ball. Verified in a re-render at both distances, not by arithmetic.
const SURF_HEAD := {"surface": "scales", "surface_scale": 3.10, "surface_strength": 0.24,
	"surface_near": 9.0, "surface_far": 26.0, "surface_macro": 0.10}
## The limbs need their OWN preset and it must be much finer and much weaker. A mitten is ~150 mm,
## so the head setting would put barely one scale on a hand and it renders as cauliflower — and
## that is not hypothetical: at 0.22 the mittens still came back as blackberries, because the mitt
## is a superellipsoid at only 8 x 5 segments after DETAIL and the bump term amplifies its own
## facets. 0.14 is a pebbling you can see and not a lump you can count.
## 9 * 4.20 * 0.152 = 5.7 scales across a mitten, i.e. 26 mm each.
const SURF_LIMB := {"surface": "scales", "surface_scale": 4.20, "surface_strength": 0.14,
	"surface_near": 7.0, "surface_far": 20.0}
## Cloth grain on the shawl and sleeves, held very low — it is a tonal break, not a pattern.
const SURF_CLOTH := {"surface": "cloth", "surface_scale": 2.4, "surface_strength": 0.55,
	"surface_near": 7.0, "surface_far": 22.0}

# ---------------------------------------------------------------------------- the crown fan
## THREE SEPARATE STALKS, graded 0.407 / 0.319 / 0.240 m long and swept left-to-right across the
## crown, each leaning a little further out than the last. Head-local, so they follow `head_semi`.
## `eyeball_r` is per spec (see the class header, point 2); `splay` aims each eye, and the shortest
## one is splayed hardest so it looks out across the pan while the two big ones face front.
##
## EYE SPACING: the two LARGE eyeball tips land 0.258 m apart on an 0.820 m head = 31.5%, inside the
## 28-35% band docs/STYLE_GUIDE.md mandates. Zorp ships at 52% as a documented stalk-eye exemption;
## Fen does not need the exemption, because the fan (not the spacing) is what carries her.
##
## MARKER CLEARANCE, measured not guessed: `NPC.MARKER_HEIGHT` is 1.52 and the '!' sits at
## `MARKER_HEIGHT * body_scale`, so the tallest thing on the model must clear 1.52 in MODEL space.
## Tallest is stalk 0: head_y 0.841 + tip 0.556 + eyeball 0.058 = 1.455, i.e. 65 mm of headroom.
## The spec's original fan (tip 0.712) lands at 1.553 and buries the marker inside the eye cluster.
## Nothing in the R4 pass moves any tip, so this figure is unchanged.
const STALK_BASE_K := 0.88            ## bases sit at head_semi.y * this, buried inside the crown
const STALKS: Array[Dictionary] = [
	{"base": Vector3(-0.148, 0.0, -0.048), "tip": Vector3(-0.176, 0.556, -0.068), "r": 0.027,
		"splay": -0.26, "eyeball_r": 0.058},
	{"base": Vector3(0.070, 0.0, -0.030), "tip": Vector3(0.082, 0.470, -0.044), "r": 0.025,
		"splay": 0.14, "eyeball_r": 0.052},
	{"base": Vector3(0.190, 0.0, 0.004), "tip": Vector3(0.248, 0.378, -0.004), "r": 0.020,
		"splay": 0.34, "eyeball_r": 0.044},
]
## The dark pupil that rides each ball, at ~0.82 of the ball radius so all three keep the same
## sclera ring. `yaw`/`pitch` only matter for the instant between `_add_face` seating the eye on the
## head and `_add_eyestalks` lifting it onto a stem, but they are chosen to roughly match the stalk
## so a future build that drops the stalks still has a face rather than three eyes stacked at 0.
const EYE_SPECS: Array[Dictionary] = [
	{"w": 0.048, "h": 0.048, "d": 0.019, "yaw": -18.0},
	{"w": 0.043, "h": 0.043, "d": 0.017, "yaw": 8.0},
	{"w": 0.036, "h": 0.036, "d": 0.015, "yaw": 24.0},
]
## Three different sway periods so the cluster never moves as one unit — a fan that swings together
## reads as one forked object, which is the silhouette this design exists to avoid.
const STALK_PERIOD := [2.9, 3.7, 4.6]
const STALK_PHASE := [0.0, 1.9, 3.4]

## BLINK RIPPLE. `_update_blink` drives ONE `_eye_open` for the whole model, so three eyes on three
## stems shut as one shutter — which is exactly the "one forked object" read the graded fan exists
## to avoid, and it is most visible at the moment the fan is doing the least.
##
## WHY THIS IS NOT A DELAY LINE ON `_eye_open`: sampling a ring buffer of past values needs an
## allocation or fiddly wrap-around indexing every frame for nine neighbours, and it would still
## have to re-derive the lid rate. Instead each eye runs its own copy of the base class's blink
## state machine, started `RIPPLE_STAGGER` seconds later than the eye above it. Eye 0 uses delay 0
## and the same three numbers `_update_blink` uses, so it tracks `_eye_open` exactly — which is what
## makes this a ripple rather than three unrelated blinks.
## The three numbers are mirrored from ChibiModel._update_blink; if that function's timing changes,
## change these with it or the tallest eye will drift out of step with the base class.
const RIPPLE_STAGGER := 0.06
const LID_HOLD := 0.11                ## ChibiModel._update_blink's `_blink_t`
const LID_SHUT := 0.06                ## ChibiModel._update_blink's closed `want`
const LID_RATE := 38.0                ## ChibiModel._update_blink's lerp rate

## The mouth. The spec asked for `mouth_node.scale = (2.40, 1.70, 1.0)` on a 0.104 half-width grin
## and called the result 25.4% of head width — but `_add_wide_grin` parents the cavity to the mouth
## NODE, so that scale multiplies it: 0.208 * 2.40 = 0.499 m on an 0.820 m head is 61%, a gaping
## hole across the whole lower face. 1.34 gives 0.279 m = 34%: absolutely NARROWER than Zorp's
## 0.318 m grin, on a head 28% wider than his, which is what keeps an elder reading as calm.
## She is one of only TWO characters in the cast who keep the wide open grin at all (the other is
## Grig); the ruling is that the grin belongs to the two stalk-eyed neighbours, because
## `_add_wide_grin`'s own docstring says it exists to stop a blank stalk-eyed dome reading as an
## eyeless monster. Hers is wide, shallow, open and BLUNT; his is short, heavy, square and
## under-bitten, from the same helper.
const MOUTH_SPREAD := Vector3(1.34, 1.15, 1.0)
const MOUTH_PITCH_FEN := -8.0         ## high on a low head — at Zorp's -18 the mouth falls off the chin

var _stalks: Array[Node3D] = []
var _hem: Node3D
var _hem_lag: Vector3 = Vector3.ZERO
var _fall: Node3D
var _fall_lag: Vector3 = Vector3.ZERO
var _t: float = 0.0
## Per-eye lid state for the ripple, one entry per eye, in `_eyes` order.
var _lid_open: PackedFloat32Array = PackedFloat32Array()
var _lid_delay: PackedFloat32Array = PackedFloat32Array()
var _lid_hold: PackedFloat32Array = PackedFloat32Array()
var _blink_was_shut := false


func _init() -> void:
	super()
	# The largest neighbour, and one of the slowest. 0.88 against the 1.0 default is a readable
	# difference and it leaves room under Grig's 0.70; the spec's 0.72 against 0.70 is not.
	body_scale = 1.06
	anim_time_scale = 0.88
	# No hover. Zorp floats 5 cm; Fen is heavy and planted.
	hover_height = 0.0
	# THE SLOWEST BLINK IN THE CAST, and it is free. `blink_hold` multiplies the interval BETWEEN
	# blinks, so 1.55 gives one every 4.7-7.8 s against everyone else's 3-5 s. Manner is a
	# differentiator that costs no triangles: an elder who has read the same low light for nine
	# years holds her eyes open, and at 8 m "that one hardly blinks" is a read a player gets for
	# free while standing still. It also keeps the ripple rare enough to stay an event.
	blink_hold = 1.55
	# The model-wide default; EYE_SPECS overrides it per eye and `_eye_size` makes that survive
	# `_apply_face`. Smaller and rounder than Zorp's 0.062: the largest eyeball is a pale ball 0.058
	# across, so a 0.048 oval leaves a visible sclera ring and reads as a PUPIL rather than a disc.
	eye_w = 0.048
	eye_h = 0.048
	eye_d = 0.019
	mouth_w = 0.092
	mouth_h = 0.056
	face_scale = 1.0

	# HER OWN HEAD — a low wide wedge. 0.820 x 0.340 x 0.520 m against Zorp's measured
	# 0.640 x 0.450 x 0.544: 28% wider and 24% shorter. Nothing else in the cast is a plate.
	head_semi = Vector3(0.4100, 0.1700, 0.2600)
	# EXPONENT AND SEGMENTS MOVE TOGETHER. NEVER DROP ONE WITHOUT THE OTHER.
	# `superellipsoid()` samples a UV sphere's uniform angular directions, so raising n packs the
	# curvature into a narrow chamfer band and a fixed segment count renders a faceted BOX. Measure
	# it: on the equator the surface normal turns (n - 1) times faster than the sampling angle at
	# the 45-degree corner, so the per-segment normal swing is (360 / radial) * (n - 1), and
	# `_segs()` scales the authored count by DETAIL 0.60. The shipped heads (n 3.2, 26 radial)
	# swing 30.0 deg per segment, which is the bar.
	#   n 4.6 at (36, 18) -> 22 radial -> 58.9 deg   (a faceted box; this was the original spec)
	#   n 4.6 at (58, 28) -> 35 radial -> 37.0 deg   (past the rejected 41.5-deg build's neighbourhood)
	#   n 4.0 at (46, 22) -> 28 radial -> 38.6 deg   (WORSE than the n=4.0 build two reviewers rejected;
	#                                                 this is what "save triangles by cutting segments" gets)
	#   n 4.0 at (58, 28) -> 35 radial -> 30.9 deg   1260 tris  (what R3 shipped)
	#   n 3.6 at (50, 26) -> 30 radial -> 31.2 deg   1020 tris  <- HERE
	# R4 takes the last line: 240 triangles bought back at a faceting figure 0.3 deg off the shipped
	# build, which pays for the third eye. The flatness given up is small — front-face recession at
	# 60% of half-width is 4.2% at n 3.6 against 3.4% at n 4.0, versus 12.4% at the chibi default
	# 2.6 — and the wedge PROPORTIONS, not the exponent, are what make this head unlike anything
	# else shipped.
	head_n = 3.6
	head_segs = Vector2i(50, 26)
	# Chin at 0.671 — the same collar line as Zorp, Grig and the twins, so the shared shoulder
	# geometry still meets it (0.841 - 0.170 = 0.671). The crown seam fraction is derived from
	# head_n by `_add_head_shell` now, so it follows the exponent automatically.
	head_y = 0.8410


func _build_geometry() -> void:
	# `rebuild()` frees every child but cannot know about these, and a stale pivot list would index
	# STALK_PERIOD out of range on the first frame after a rebuild.
	_stalks.clear()
	_hem = null
	_fall = null
	_hem_lag = Vector3.ZERO
	_fall_lag = Vector3.ZERO
	_build_body()
	_add_head_shell(SKIN, SURF_HEAD)

	# THREE eyes, graded, and no brows. `brows: false` is the switch that replaces the hand-rolled
	# "build them then free them" loop this file used to carry: brows are drawn on the HEAD, and
	# with the real eyes lifted onto stalks two dark bars up there read as a second pair of eyes,
	# which puts the animal face straight back. She wears no brow ridge of any kind by ruling.
	# No nose, no blush either. A TRANSPARENT blush colour does not disable blush — `toon_soft` is
	# opaque, so an alpha-0 colour renders as two BLACK ovals on the cheeks; the switches are the
	# only way.
	_add_face(EYE, GRIN, SKIN_DARK, {
		"mouth_inner": Color("#5a3a52"), "nose": false, "blush": false, "brows": false,
		"eyes": EYE_SPECS,
	})
	_build_grin()
	_build_crown_fan()
	_reset_lids()


# ============================================================================= body
func _build_body() -> void:
	# A taller, wider bean than the chibi default — the broadest, softest, lowest-shouldered body in
	# the cast. The waist chamfer is off because the shawl covers that whole band; it would be 100
	# tris of hidden geometry.
	var torso_opts := _merged(SURF_CLOTH, {
		"size_mul": Vector3(1.10, 1.16, 1.08), "waist_chamfer": false,
	})
	_add_torso_bean(CAPE_TRIM, torso_opts)

	# THE SHAWL — a long draped plate over the shoulders with an asymmetric fall, not a scarf and no
	# longer a symmetrical sun-shade poncho. It is still the practical garment of a world where the
	# sun never leaves the horizon, and it is ~840 tris cheaper than Zorp's collar-plus-three-
	# stripes-plus-tail scarf.
	#
	# WHERE THE "LONG" GOES, and the first build put it in the wrong place. Lengthening the SHELL
	# (half-height 0.155 -> 0.182, bottom edge 0.360 -> 0.312) rendered as a smooth pink block with
	# nothing but mittens showing below it — the shell's bottom edge landed level with the cuffs, so
	# the entire arm was inside the garment. That is exactly the "bell with hands" failure the R3
	# comment warned about, reached by a different route. The shell is therefore back to a SHOULDER
	# cape (centre 0.520, half-height 0.152, bottom edge 0.368, which leaves 55 mm of sleeve plus the
	# cuff and the mitt in silhouette) and ALL of the length is spent on the asymmetric fall below.
	# That is also the better read: a shawl is long on one side, and a symmetrical hem is a poncho.
	var shawl := _node("Shawl", _torso, Vector3(0.0, 0.5200, 0.010))
	var m_cape := _toon(CAPE, _matte(SURF_CLOTH))
	var m_trim := _toon(CAPE_TRIM, _matte(_merged(SURF_CLOTH, {"rim": 0.02})))
	_mi(superellipsoid(Vector3(0.300, 0.152, 0.250), 3.6, 24, 12), m_cape, shawl, Vector3.ZERO, "Drape")
	# A hard hem rim near the bottom edge, standing ~15 mm proud of the shell, so the plate ends on
	# an EDGE instead of fading out. It is its own node because it lags the torso (see
	# `_animate_extras`). At local y -0.130 the shell's own x half-width has fallen to 0.235, which
	# is where the 0.250 rim gets its proud edge; move one and re-solve the other.
	_hem = _node("Hem", shawl, Vector3(0.0, -0.1300, 0.0))
	_mi(superellipsoid(Vector3(0.250, 0.019, 0.208), 3.8, 18, 5), m_trim, _hem, Vector3.ZERO, "Rim")

	# THE ASYMMETRIC FALL — the end of the shawl thrown over the LEFT shoulder (-X, the same side the
	# tallest stalk leans) and hanging to mid-shin, in two shrinking `rounded_box` segments. It is
	# the reason the garment reads as a WRAP rather than a poncho: a poncho is symmetrical by
	# construction, and symmetry is what made this silhouette interchangeable with a bell.
	#
	# IT HAS TO HANG IN CLEAR AIR, and TWO different solids buried the first two attempts:
	#   * the DRAPE is a 0.300 x 0.250 slab at n 3.6, so at x -0.19 its own half-depth is still
	#     0.238 — a fall tucked in beside it is inside the shell. A 300 mm tail rendered as an
	#     80 mm tab.
	#   * the TORSO bean is 0.244 x 0.273 x 0.205 centred at y 0.40, so the whole region below the
	#     hem and outboard of the hip is inside the BODY. Moving the fall down did not free it.
	# The only clear volume is FORWARD: at (x -0.150, y 0.30) the torso's own front surface is at
	# z -0.164, so a 90 mm-deep fall centred at z -0.215 hangs entirely proud of it, down the front
	# of the left hip the way a shawl end actually falls. Its top overlaps the drape by 77 mm purely
	# to attach (at y 0.42 the drape still reaches z -0.221, so the join is hidden), and 205 mm —
	# a seventh of her height — is visible below the hem.
	# It clears the mitten in Z, not in X: the mitt sits at x -0.354..-0.202 but only z -0.080..0.056,
	# and the fall is at z -0.260..-0.170, so they overlap in plan and never in space. It stops 37 mm
	# above the boot, so the legs stay fully readable.
	_fall = _node("Fall", _torso, Vector3(-0.150, 0.4300, -0.215))
	_mi(rounded_box(Vector3(0.150, 0.240, 0.090), 0.030, 10), m_cape, _fall,
		Vector3(0.0, -0.1050, 0.0), "FallUpper")
	var tail := _node("FallTail", _fall, Vector3(0.0, -0.1850, 0.008))
	tail.rotation.z = 0.22
	_mi(rounded_box(Vector3(0.110, 0.165, 0.076), 0.026, 8), m_trim, tail, Vector3.ZERO, "FallLower")

	# The shoulders have to move outboard of the shawl plate or the arms vanish inside it, and they
	# sit 13 mm below the chibi shoulder line, which is where "lowest-shouldered in the cast" comes
	# from. `rebuild()` places them at +/-SHOULDER.x, and `_apply_pose` only ever writes their
	# ROTATION, so overriding the position here is safe.
	_arm_l.position = Vector3(-0.278, 0.4920, SHOULDER.z)
	_arm_r.position = Vector3(0.278, 0.4920, SHOULDER.z)
	# FOUR fingers. Zorp has three, the twins none.
	_add_arms(CAPE, SKIN, 4, SURF_LIMB, SURF_CLOTH)
	_add_legs(SKIN_DARK, FOOT, SURF_LIMB)


func _build_grin() -> void:
	var mouth_node := _face.get_node_or_null("Mouth") as Node3D
	if mouth_node == null:
		return
	_orient_on_head(mouth_node, 0.0, MOUTH_PITCH_FEN, 0.004)
	mouth_node.scale = MOUTH_SPREAD
	# FOUR teeth of uneven width, all BLUNT and all in the upper row. Zorp and the twins have three,
	# so an even count is itself a difference, and uneven widths keep it off the neat cartoon-animal
	# smile. No fangs, no tusks and no lower row: the under-bite belongs to Grig, and she wears none
	# of the hard vocabulary.
	_add_wide_grin(mouth_node, GRIN, TOOTH, Vector3(0.104, 0.030, 0.020),
		[[-0.062, 0.016], [-0.020, 0.022], [0.024, 0.014], [0.066, 0.019]])


# ============================================================================= the crown fan
func _build_crown_fan() -> void:
	var by := head_semi.y * STALK_BASE_K
	var specs: Array = []
	for s0: Dictionary in STALKS:
		var s := s0.duplicate()
		var b: Vector3 = s["base"]
		s["base"] = Vector3(b.x, by, b.z)
		specs.append(s)
	# THREE ANIMATED eyes. The eye nodes are only repositioned, never rebuilt, so blink, squint, the
	# happy "^" and the surprise "O" all keep running exactly as they do on a flat face. The default
	# `eyeball_r` argument is never used — every spec carries its own.
	_add_eyestalks(specs, SKIN, SCLERA, 0.058)
	for i in specs.size():
		_stalks.append(_lift_stalk_onto_pivot(i, specs[i]["base"]))


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


# ============================================================================= animation
## Sizes the ripple state to however many eyes actually got built, and starts them all open. Called
## at the end of `_build_geometry()` because `rebuild()` empties `_eyes` and refills it.
func _reset_lids() -> void:
	var n := _eyes.size()
	_lid_open.resize(n)
	_lid_delay.resize(n)
	_lid_hold.resize(n)
	for i in n:
		_lid_open[i] = 1.0
		_lid_delay[i] = 0.0
		_lid_hold[i] = 0.0
	_blink_was_shut = false


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
		if i < 2:
			# The two big eyes lean toward whoever is speaking. Negative X tips a stalk's +Y tip
			# toward -Z, which is the direction the face looks.
			pitch -= 0.16 * talk
			yaw += 0.06 * talk * (-1.0 if i == 0 else 1.0)
		else:
			# The small one does NOT attend. It keeps sweeping the pan on a wider arc while she
			# talks — the nine-year logbook made visible, and the thing that stops the fan reading
			# as one organ pointed in one direction.
			pitch += 0.05 * talk
			yaw = 0.155 * scan
		pv.rotation = Vector3(pitch, yaw, roll)

	_ripple_blink(delta)

	# The shawl's hem and its fall both LAG the torso, so the garment swings a beat behind the body
	# instead of being welded to it. Both are children of `_torso` (which rides `_torso_pivot`), so
	# writing the DIFFERENCE between the filtered and the live rotation leaves the part sitting at
	# the old angle. The fall is longer and looser than the hem, so it is filtered more slowly
	# (5.0 against 8.0) and swings further (1.15 against 0.85) — that difference is what makes the
	# two read as one garment of two weights rather than two welded plates.
	var cur := _torso_pivot.rotation
	if _hem != null:
		_hem_lag = _hem_lag.lerp(cur, 1.0 - exp(-8.0 * delta))
		_hem.rotation = (_hem_lag - cur) * 0.85
	if _fall != null:
		_fall_lag = _fall_lag.lerp(cur, 1.0 - exp(-5.0 * delta))
		_fall.rotation = (_fall_lag - cur) * 1.15


## THE BLINK RIPPLE. A post-pass, and it must stay one: `tick()` calls `_apply_pose` (and therefore
## `_apply_face`) BEFORE `_animate_extras` every frame, so `oval.scale` has already been written
## from the model-wide `_eye_open` by the time this runs and rewriting `.y` here cannot fight it.
##
## Each eye runs its own copy of the base class's lid machine, started `RIPPLE_STAGGER * i` seconds
## after the base's blink begins — tallest first, so the lid runs DOWN the fan. Eye 0's delay is 0
## and its three constants are the base's own, so it tracks `_eye_open` exactly.
##
## The oval is skipped while it is hidden: `_apply_face` swaps in the happy arc or the surprise ball
## instead of the oval, and those are separate meshes that carry no lid.
func _ripple_blink(delta: float) -> void:
	if _lid_open.size() < _eyes.size():
		_reset_lids()
	# Rising edge of the base class's blink. `_blink_t` is set to LID_HOLD the frame a blink starts
	# and counts down from there, so a level test plus a latch is all this needs.
	var shut := _blink_t > 0.0
	if shut and not _blink_was_shut:
		for i in _lid_hold.size():
			_lid_delay[i] = RIPPLE_STAGGER * float(i)
			_lid_hold[i] = LID_HOLD
	_blink_was_shut = shut

	var wide := pose(P.EYE_WIDE)
	var fs := face_scale
	var k := 1.0 - exp(-LID_RATE * delta)
	for i in mini(_eye_ovals.size(), _lid_open.size()):
		var want := 1.0
		if _lid_delay[i] > 0.0:
			_lid_delay[i] -= delta
		elif _lid_hold[i] > 0.0:
			_lid_hold[i] -= delta
			want = LID_SHUT
		_lid_open[i] = lerpf(_lid_open[i], want, k)
		var oval := _eye_ovals[i]
		if oval == null or not is_instance_valid(oval) or not oval.visible:
			continue
		var sz: Vector3 = _eye_size[i] if i < _eye_size.size() else Vector3(eye_w, eye_h, eye_d)
		oval.scale.y = sz.y * fs * wide * _lid_open[i]


# ============================================================================= helpers
## `_matte()` fills defaults into a COPY, so option dicts compose cleanly; this is just the merge.
static func _merged(base: Dictionary, extra: Dictionary) -> Dictionary:
	var o := base.duplicate()
	for k: Variant in extra:
		o[k] = extra[k]
	return o
