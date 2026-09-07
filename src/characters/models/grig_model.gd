class_name GrigModel
extends ChibiModel
## Grig — the step-cutter of Grig's Chalk Steps. Older, slower and heavier than anyone else in the
## cast: he has quarried the terraces one riser at a time for longer than he will admit, numbers each
## one, and has firm views about where you put your feet.
##
## Built to docs/NEXT_WORLDS.md's "CREATURE grig" section, then widened by R4 (CAST VARIETY), which
## was raised because five aliens shared one recipe — eyestalks, a wide grin and a spotted `sd_skin`
## head — and so read as one creature in five colours. Grig is one of the TWO characters allowed to
## keep the stalk and the grin (they are load-bearing on him, see below); everything else about him
## moves further away from the other four. Seven traits nothing else in the cast has:
##   1. ONE EYE. A single 0.112 m eyeball on ONE thick central trunk. Every other neighbour has
##      exactly two (Zorp two matched stalks, Pip long+short, Pop two close-set, Mayor Orbit two on
##      goggle lenses, Bolt and DJ Nova two on a faceplate).
##   2. A TALL HEAD — 0.550 x 0.660 x 0.500 at n 3.2. Not the tallest-to-widest ratio the first
##      build tried (see HEAD_SEMI_GRIG's R3.3 note) but still the tallest head in the cast, and a
##      standing stone with a face, which ties him to his planet.
##   3. AN UNDER-BITE. Four blunt near-square teeth hang from the upper jaw and TWO tusks stand up
##      from the lower one, so the two rows interlock the wrong way round. Everyone else's mouth is
##      a single top row of points. Plus a TWO-lobed mitt against three-or-zero fingers.
##   4. WORN STONE — a tally collar of chalk slabs on a cord, one notched per terrace cut. The rest
##      of the cast wears cloth (Zorp's scarf, the twins' aprons, the Mayor's waistcoat).
##   5. A LAGGING EYE-TRACK. The trunk arrives a beat after the head turns; nothing else in the cast
##      has a delayed feature, and on one huge eye it reads instantly as thought.
##   6. A CAPITAL. One continuous chamfered block of cut stone ringing the top of the head, with the
##      dome and the eye trunk still rising above it — see `_build_capital`. Every other crown in the
##      game is a ROW of small parts (antennae, stalks, horns, cups, spikes); his is a single
##      quarried block, so it shares no primitive with anyone.
##   7. CRACKED CRAZE AND NOTHING ELSE. His skin runs `sd_skin` with the spot term switched fully
##      OFF, so he is cell walls only where Zorp is blobs only — see SURF_HEAD.
##
## The STRATA BANDS round the head are meant to be an eighth, mirroring the contour rings of his own
## world. THEY DO NOT RENDER AND NEVER HAVE — the mesh is built by a method that cannot produce the
## shape it asks for. `_add_strata`'s comment has the measurement, the root cause, the fix and the
## reason the fix is deliberately not applied in this change. Do not cite them as a shipped feature.
##
## WHAT HE DELIBERATELY DOES NOT HAVE. R4 caps the hard/heavy vocabulary — brow ridge, heavy lid,
## horns, tusks, fangs, shoulder yoke — at TWO per character, because the cast's complaint was that
## everything read male and the fix is a WIDER range of shapes, not a bigger pile of the same ones on
## the character who already wears them. Grig spends his two on the LID RIDGE and the TUSKS. So: no
## horn ring around the trunk, no dorsal bump ridge and no shoulder yoke, all three of which were
## drafted for him and all three of which are deliberately absent. If you are adding hard geometry
## here, you are over the cap and something else has to come off first.

# ---------------------------------------------------------------------------------- palette
## R2.6 (pastel and matte). He must NOT vanish into his own world: the ground is cool grey chalk
## #b7b4a2 at S 0.115 V 0.718, so Grig separates by HUE (warm clay against cool chalk) and by VALUE
## (the smock and the boots are the dark anchors every AC villager has). No brass anywhere — aged
## brass is Mayor Orbit's, and the two would confuse at distance.
const SKIN := Color("#b99a7e")        ## warm stone-clay, S 0.319 V 0.725
const SKIN_DEEP := Color("#8d735c")   ## S 0.348 V 0.553 — strata, grooves, lid ridge, bare legs
const SCLERA := Color("#ece4d4")      ## the big pale eyeball, so the dark oval becomes a pupil
const EYE := Color("#241d18")
const GRIN := Color("#3a2b22")        ## mouth cavity
const TOOTH := Color("#efe7d6")
const SMOCK := Color("#64798a")       ## a slate-blue mason's smock — the one cool note
const SMOCK_DARK := Color("#4c5c6b")
const TALLY := Color("#cabfa6")       ## the chalk slabs
const FOOT := Color("#5a4f45")
const WEDGE := Color("#8b8578")       ## the cutting wedge at his hip

# ---------------------------------------------------------------------------------- head shape
## A head nearly twice as tall as it is wide with flat chamfered side planes. `head_y` puts the chin
## at 1.1010 - 0.4300 = 0.6710, which is EXACTLY Zorp's chin line (0.8963 - 0.2250), so the shared
## shoulder and collar geometry still meets it.
## R3.3 — REBALANCED. The first build was 490 x 860 mm, nearly twice as tall as wide, and it read as
## a vertical loaf with a small mouth floating on a large blank field — the exact complaint the user
## made about Zorp ("a lot of open space ... shrink that open space down more"). 550 x 660 keeps him
## clearly the TALLEST head in the cast, which is his silhouette, without the blank slab.
const HEAD_SEMI_GRIG := Vector3(0.2750, 0.3300, 0.2500)
const HEAD_N_GRIG := 3.2
## Holds the chin where it was: 1.1010 - 0.4300 = 0.6710, so 0.6710 + 0.3300.
const HEAD_Y_GRIG := 1.0010
## Tessellation. n 3.2 is exactly Zorp's proven exponent, so the DEFAULT (44, 22) would not facet —
## but Zorp's head is 0.45 m tall and this one is 0.86 m, so the same 13 latitude rings would stretch
## to 66 mm bands down the tall front plane. 38 x 26 resolves to 23 x 16 after ChibiModel.DETAIL and
## costs 782 tris against the default's 728. Do NOT raise `head_n` past 3.2 without raising these
## again: above ~3.2 the curvature packs into a narrow chamfer band and the shell renders as a box.
const HEAD_SEGS_GRIG := Vector2i(38, 26)

# ---------------------------------------------------------------------------------- the one eye
## An eyeball nearly twice Zorp's 0.058, on a stalk nearly twice his 0.026 radius: a thick neck-stalk
## carrying one huge eye rather than two delicate stems.
const EYEBALL_R := 0.112
const STALK_BASE := Vector3(0.006, 0.2574, -0.026)   ## head_semi.y * 0.78, just inside the crown
const STALK_TIP := Vector3(0.0, 0.560, -0.048)
const STALK_R := 0.052
## The LID RIDGE replaces both brow bars. One heavy arc hooding the top of the eyeball — the "quiet
## end of the AC range" cue R2.3 asks for, expressed once instead of twice. Radius 0.130 with a 0.018
## tube puts its inner edge at 0.112, exactly hugging the ball, and its outer edge at 0.148, which
## still clears the pupil at the 1.35x "surprised" widening.
const LID_RING_R := 0.130
const LID_TUBE := 0.018
const LID_TILT := -0.20
## How far the stalk is allowed to trail the head, and how fast it catches up.
## 2.8 rather than the first build's 3.4: measured on a real head turn the faster filter only trailed
## 0.053 rad, which on a 0.226 m stalk moves the eyeball 12 mm and does not read at all. At 2.8 an
## ordinary idle look-around reaches the 0.14 cap, which is 32 mm of drift on a 224 mm eyeball —
## visible as the eye arriving late, which is the whole trait.
const EYE_LAG_MAX := 0.14
const EYE_LAG_RATE := 2.8

# ---------------------------------------------------------------------------------- the mouth
## Low on the face, because the head is tall. At the chibi default (-20 deg) the mouth would float in
## the middle of a blank plane and read as a nose. Raised from the first build's -46, which on the
## shortened head put the mouth almost under his chin.
const MOUTH_PITCH_GRIG := -26.0
## DO NOT SHRINK THIS. Rendered grin width is 0.062 * 2 * 1.95 = 0.242 m = 44% of the 0.550 m head,
## which is over the style guide's 16-25% band — see the documented exemption for stalk-eyed
## neighbours in docs/NEXT_WORLDS.md, which Zorp also ships under. R4 makes the exemption a
## STRUCTURAL rule rather than a per-character judgement: exactly the two characters who keep their
## eyes up on stalks keep the wide grin, because `_add_wide_grin`'s own docstring says the grin
## exists only to stop a large blank stalk-eyed head reading as an eyeless monster. Put the eyes back
## on the face and the exemption goes with them. On top of that, docs/OPEN_ISSUES.md 35-36 records
## that Grig's FIRST build was rejected for exactly "a small mouth on a large blank field"; a
## narrower grin here walks straight back into a recorded failure.
const MOUTH_SPREAD := Vector3(1.95, 1.70, 1.0)
const GRIN_SIZE := Vector3(0.062, 0.026, 0.018)
## AN UNDER-BITE — R4, and the thing that makes his mouth structurally unmistakable against Fen's
## from the same helper: hers is wide, shallow and blunt, his is short, heavy and bites the wrong way
## round. FOUR blunt near-SQUARE uppers (full widths 0.022 / 0.026 / 0.020 / 0.016 against the
## 0.0161 height `_add_tooth` derives from GRIN_SIZE.y) rather than the pointed rows the rest of the
## cast wears; even count but uneven widths and uneven spacing, so it still is not a neat row.
##
## THE LAST TWO ENTRIES ARE THE TUSKS. `_add_tooth`'s third element is the ROW: +1 hangs from the
## upper jaw (what every tooth in the game did before R4, when the row was hardcoded), -1 stands up
## from the LOWER jaw. Fourth is the shape — "point" builds a `taper_tube` cone, turned over for a
## lower tusk. Two-element entries above still mean exactly what they always did.
##
## WHY x = +/-0.048 AND NOT THE CORNERS AT +/-0.062. A "point" tooth is seated at
## `row * GRIN_SIZE.y * 0.92` = -0.0239, and the cavity is a superellipsoid at n 2.4, so its own half
## height falls off toward the corners: 0.0228 at x 0.036, 0.0188 at 0.048, 0.0167 at 0.050 and
## nothing at 0.062. Seated at the true corner a tusk's base would hang ~7 mm clear of the cavity and
## render as a cream cone floating on the chin — the failure the mouth code already records once, as
## "two maroon specks that read as nostrils". At 0.048 the base is 5 mm below the cavity edge, which
## is the tusk EMERGING FROM THE LIP rather than detached from it, and it is far enough out to still
## read as a corner tusk rather than a pair of fangs under the front teeth. Rendered before shipping.
const GRIN_TEETH: Array = [[-0.038, 0.022], [-0.002, 0.026], [0.034, 0.020], [0.062, 0.016],
	[-0.048, 0.020, -1, "point"], [0.048, 0.020, -1, "point"]]

# ---------------------------------------------------------------------------------- skin texture
## THE ZERO-SHADER-EDIT SKIN ROUTE, the same one AlienModel proved: `_matte()` duplicates the opts
## and only fills defaults, so `{"surface": ...}` travels intact through `_add_head_shell` into
## `MaterialLib.toon` and sets `surface_kind`, which is 0 on every neighbour and is why alien skin
## reads as flat plastic.
##
## KIND: `skin`, not `wood`. docs/NEXT_WORLDS.md specifies sd_wood for "horizontal strata" and that
## is not what sd_wood draws — its rings are contours of `length(wpos - g * dot(wpos, g))`, i.e.
## coaxial cylinders around the grain axis, so +Y gives VERTICAL bands wrapping the head and any
## other axis gives concentric rings centred on the ear line. Neither is strata, and at 26 * 0.30 =
## 7.8 cycles/m it would draw about 1.9 of them across the whole head. The horizontal banding is
## therefore built as real geometry instead (see `_add_strata`), and the shell gets the CELLULAR
## `skin` kind, weighted the opposite way from Zorp's: he is spot-dominant (blotches, an animal),
## Grig is EDGE-dominant (crazed cell walls, cracked chalk).
##
## FREQUENCY: sd_skin runs at 7 cycles/unit at scale 1.0, so 2.2 puts 15.4 cells/m — about 8.5
## across the 0.550 m head and 10 down its 0.660 m height. AMPLITUDE IS A PALETTE COST (an A/B on
## one frame moved a head crop's saturation mean by +0.099), so strength stays at 0.9; re-measure in
## src/world/world.tscn, never in a showcase, if it is raised.
##
## R4 — ZERO SPOTS. `surface_spot` goes 0.30 -> 0.0 and `surface_scales` 1.15 -> 1.35. He was
## already the only edge-weighted character; this makes him own the treatment OUTRIGHT rather than
## merely differing from Zorp by a dial setting, which is exactly the "same creature, different
## parameters" complaint R4 was raised over. Read sd_skin's own line to see how total the switch is:
##   d = (spot - spot_dc) * spot_amount * 0.6 - (edge - 0.3242) * scale_amount * 0.4
## `spot_amount` 0.0 multiplies the ENTIRE spot term away, DC included, so there is no residue and no
## tint to correct — he is cell walls and nothing else, and Zorp is blobs. It is also the cheap half
## of the palette bargain: the edge term is centred on its own measured mean, so a pure craze costs
## essentially no mean saturation where the spots cost 4-6%.
## `surface_spot_radius` is DELIBERATELY ABSENT rather than set to 0: with the amount at 0 the radius
## feeds nothing, and MaterialLib derives `surface_spot_dc` from it, so leaving a stale radius here
## would only invite someone to "fix" the pairing later. Set the radius again if you ever set the
## amount again — MaterialLib.spot_dc() keeps the two consistent for you.
## `crown_seam: false` — R4. The seam is a flat pancake superellipsoid and is invisible for the same
## reason the strata bands are (see `_add_strata`), and the capital's rim plate now draws the hard
## horizontal it was there to draw, in a primitive that actually renders. Skipping it is 110 tris
## back toward the capital's cost.
const SURF_HEAD := {"surface": "skin", "surface_scale": 2.2, "surface_strength": 0.9,
	"surface_spot": 0.0, "surface_scales": 1.35,
	"surface_near": 9.0, "surface_far": 26.0, "surface_macro": 0.10, "surface_macro_cycles": 2.2,
	"crown_seam": false, "seam_color": SKIN_DEEP}
## Limbs are far smaller than the head (a mitt is ~150 mm), so the head's setting would put barely
## one cell on a hand, and texture that stops at the jaw looks like a mask. But this is NOT the head
## preset scaled down: OPEN_ISSUES item 35 records that the head setting rendered the twins' arms as
## CAULIFLOWER, and names the culprit — the cell-EDGE term on a small, strongly curved capsule.
## Grig's head is deliberately edge-dominant, so his limbs are the one place that has to invert his
## own identity: edges nearly off (0.18 against the head's 1.35), spots carrying what little is
## there, finer and much weaker. THE SPOTS STAY HERE even though the head's are now switched off —
## with the edge term this low something has to carry the texture, and at 0.35 amount on a 150 mm
## mitt it is a faint mottle at conversation range, not the blotchy hide the head used to share with
## Zorp. Do not "tidy" this to match SURF_HEAD; matching it renders the arms as cauliflower.
const SURF_LIMB := {"surface": "skin", "surface_scale": 6.5, "surface_strength": 0.55,
	"surface_spot": 0.35, "surface_scales": 0.18, "surface_spot_radius": 0.30,
	"surface_near": 7.0, "surface_far": 20.0}
## The smock is cloth, not stone. sd_cloth runs at ~190 cycles/m, which needs the camera inside
## ~1.5 m, so the fade is deliberately short — it is a dialogue-range nicety and it must be gone
## before it can alias at the 7.4 m gameplay camera.
const SURF_CLOTH := {"surface": "cloth", "surface_scale": 0.8, "surface_strength": 0.7,
	"surface_near": 4.0, "surface_far": 12.0}

# ---------------------------------------------------------------------------------- body
## A tapered column, not a bean: 0.88 / 1.16 / 0.86 of the chibi torso gives semi
## (0.1954, 0.2726, 0.1634) — narrow and tall. Its top lands at 0.673, just under the 0.671 chin.
const TORSO_MUL := Vector3(0.88, 1.16, 0.86)
const COLLAR_Y := 0.594
const BELT_Y := 0.318

var _eye_pivot: Node3D             ## everything on the stalk, rotated about the stalk base
var _lid: Node3D
var _tally: Node3D
var _eye_follow_yaw: float = 0.0
var _eye_follow_pitch: float = 0.0
var _tally_follow: float = 0.0


func _init() -> void:
	super()
	# Slow and deliberate — slower than everyone but Mayor Orbit's 0.62. He is the oldest thing on
	# a world made of things he cut himself.
	anim_time_scale = 0.70
	# 0.92 is NOT a fix for the name-marker collision (see the note on `_check_marker_height`); it is
	# here because at 1.0 the stalk tip stands 1.77 m off the ground, taller than the 1.4 m
	# astronaut by a quarter. At 0.92 he tops out at 1.63 m: still the tallest neighbour in the
	# cast, which is the read, without dwarfing the player.
	body_scale = 0.92
	# Planted, not floating. Zorp hovers 5 cm; Grig is a walking piece of the ground.
	hover_height = 0.0
	# The dark pupil has to scale with a 0.112 m eyeball or it becomes a dot ON it. 0.088 x 0.092
	# half-extents put the pupil at 78% of the ball's width — a real pupil on a real sclera, where
	# Zorp's 0.062 on a 0.055 ball is actually WIDER than the ball it sits on.
	eye_w = 0.088
	eye_h = 0.092
	# Deeper than the chibi default so the pupil stands clear of the low-poly ball's front facet.
	eye_d = 0.030
	# Sized to sit INSIDE the grin cavity (half-extents 0.062 x 0.026) at the same proportion Zorp's
	# open mouth sits inside his.
	mouth_w = 0.052
	mouth_h = 0.038
	head_semi = HEAD_SEMI_GRIG
	head_n = HEAD_N_GRIG
	head_y = HEAD_Y_GRIG
	head_segs = HEAD_SEGS_GRIG


func _build_geometry() -> void:
	_add_torso_bean(SMOCK, _with(SURF_CLOTH, {"size_mul": TORSO_MUL, "chamfer_color": SMOCK_DARK}))
	_build_belt()
	# TWO fingers. Zorp has three, the twins none — a two-lobed mitt is a third hand silhouette.
	_add_arms(SMOCK, SKIN, 2, SURF_LIMB, SURF_CLOTH)
	_add_legs(SKIN_DEEP, FOOT, SURF_LIMB)
	_add_head_shell(SKIN, SURF_HEAD)
	_add_strata()
	_build_capital()

	# `blush: false`, `nose: false` and `brows: false` are switches on `_add_face`. Passing a
	# TRANSPARENT colour instead does not work — the toon material is opaque, so an alpha-0 blush
	# renders as two BLACK ovals on the cheeks. The colour below is inert; the flags are what matter.
	#
	# `brows: false` is R4 and replaces a hand-rolled deletion loop that used to run inside
	# `_make_cyclops`. With the eye up on a trunk, two brow bars left on the head read as a second
	# pair of eyes and put the generic animal face straight back; the lid ridge is his one brow and
	# it lives on the trunk with the eye it belongs to. Not building them is also cheaper than
	# building and freeing them, and it means nothing can reach `_brows` holding a dead node.
	_add_face(EYE, GRIN, SKIN_DEEP,
		{"mouth_inner": Color("#5a3a2e"), "nose": false, "blush": false, "brows": false})
	_make_cyclops()
	_build_stalk()
	_build_mouth()
	_build_tally_collar()
	_build_wedge()


# ================================================================================= the one eye
## CYCLOPS SURGERY — spelled out because getting it wrong is a crash and not a cosmetic bug. The
## warning is in `_add_eyestalks`' own docstring and in the completeness critic's note on Fen in
## docs/NEXT_WORLDS.md: an eye that is not in the arrays is invisible to the whole expression system,
## and an INDEX that outlives its node is worse.
##
## `_add_face()` builds one eye per entry in its `eyes` list, defaulting to TWO, and `_build_eye`
## appends one entry per eye to FIVE parallel arrays — `_eyes`, `_eye_ovals`, `_eye_happy`,
## `_eye_round` and `_eye_size`. `_apply_face()` walks all five EVERY FRAME to drive blink, squint,
## the happy "^" and the surprise "O". So it is not enough to free the second eye: an index left
## pointing at a freed node is a dangling reference that fires on the very next blink.
##
## THIS USED TO BE HAND-ROLLED AND WAS A LATENT CRASH. It dropped index 1 from FOUR arrays, which was
## correct until R4 added the fifth (`_eye_size`, the array that makes per-eye sizes survive
## `_apply_face`'s every-frame rewrite). A five-array structure taken apart by four-array code leaves
## `_eye_size` one entry long against `_eyes` zero — and `_apply_face` indexes them together. So the
## teardown is now `_drop_eye()`, which is the base class's own single point of removal and cannot
## fall out of step with the arrays again. DO NOT re-inline it here, whatever it is replaced with.
##
## `_drop_eye` also erases the dead eye's brow from `_brows` — a no-op for Grig, who is built with
## `brows: false` and never has any (see `_build_geometry`), but it is what makes the helper safe for
## a model that does.
func _make_cyclops() -> void:
	if _eyes.size() < 2:
		return
	_drop_eye(1)
	# The surviving eye's happy arc and surprise ball are authored at fixed chibi sizes (a 0.042 ring
	# and a 0.043 x 0.048 ball), so on a pupil this size both expressions would visibly SHRINK the
	# eye at the exact moment it is meant to be most readable. These two numbers are tuned by eye at
	# the gameplay camera and are NOT the ratio arithmetic — `_build_eye`'s `fit_expr` opt would
	# derive 0.088/0.0375 = 2.35 and 0.092/0.0470 = 1.96, which overshoots the arc. Grig therefore
	# stays opted OUT of `fit_expr` and keeps the measured values.
	# MULTIPLIED, not assigned: `_build_eye` has already written the per-eye ratio into these nodes.
	# For Grig that ratio is exactly (1, 1, 1) — he sets no per-eye size — so this is identical to
	# the assignment it replaces, but it stays correct if he is ever given one.
	if not _eye_happy.is_empty():
		_eye_happy[0].scale *= Vector3(1.85, 1.85, 1.0)
	if not _eye_round.is_empty():
		_eye_round[0].scale *= Vector3(2.05, 1.92, 1.0)


## One thick central stalk, one huge eye, and a heavy lid ridge over it — all re-parented under a
## pivot AT THE STALK BASE so `_animate_extras` can lag the whole assembly as one piece.
func _build_stalk() -> void:
	_add_eyestalks([{"base": STALK_BASE, "tip": STALK_TIP, "r": STALK_R, "splay": 0.0}],
		SKIN, SCLERA, EYEBALL_R)
	_eye_pivot = _node("EyePivot", _head, STALK_BASE)
	# The lid ridge: a single arc hooding the ball, in the deep skin tone so it reads as bone rather
	# than as a second dark mark. Built before the re-parent so it travels with everything else.
	_lid = _node("LidRidge", _head, STALK_TIP + Vector3(0.0, 0.006, -0.030))
	_lid.rotation.x = LID_TILT
	_mi(arc_tube(LID_RING_R, LID_TUBE, deg_to_rad(14.0), deg_to_rad(166.0), 14, 6),
		_toon(SKIN_DEEP, _matte({"rim": 0.02})), _lid, Vector3.ZERO, "Ridge")
	# `_add_eyestalks` parents the stem and the eyeball to `_head` and re-positions `_eyes[0]` (which
	# lives under `_face`). `_face` sits at the head origin with no rotation, so head-local and
	# face-local are the same frame and the transforms below carry across untouched.
	var riders: Array[Node3D] = []
	var stem := _head.get_node_or_null("EyeStalk0") as Node3D
	var ball := _head.get_node_or_null("Eyeball0") as Node3D
	if stem != null:
		riders.append(stem)
	if ball != null:
		riders.append(ball)
	if not _eyes.is_empty():
		riders.append(_eyes[0])
	riders.append(_lid)
	for n: Node3D in riders:
		_adopt(n, _eye_pivot, STALK_BASE)


## Merges `extra` over a copy of `base`, so a const opts dict can be reused with a couple of keys
## added. `_matte()` duplicates again downstream, so nothing here mutates a constant.
static func _with(base: Dictionary, extra: Dictionary) -> Dictionary:
	var o := base.duplicate()
	for key: Variant in extra:
		o[key] = extra[key]
	return o


## Moves `n` under `pivot` while keeping its world placement, given that `pivot` sits at `origin` in
## the same (unrotated) parent frame.
func _adopt(n: Node3D, pivot: Node3D, origin: Vector3) -> void:
	var xf := n.transform
	var parent := n.get_parent()
	if parent != null:
		parent.remove_child(n)
	pivot.add_child(n)
	n.transform = xf
	n.position = xf.origin - origin


# ================================================================================= head detail
## PANEL GROOVES as horizontal STRATA — thin bands intended to wrap the WHOLE head, mirroring the
## contour rings of Grig's own planet.
##
## docs/NEXT_WORLDS.md specifies three `arc_tube`s placed with `_orient_on_head`, but an arc_tube
## sweeps in the tangent plane at one point, so it draws a stripe across the FRONT of the face and
## stops — it cannot wrap. The band below uses the same trick `_add_head_shell` uses for its crown
## seam. That trick does not work, for either of them.
##
## The arithmetic: on the head superellipsoid, the horizontal half-extents at height `frac * semi.y`
## are `semi.xz * (1 - |frac|^n)^(1/n)`. Building the band at that size times `STRATA_PROUD` welds it
## to the shell and buries everything outside the protruding rim, so only a band shows. Sharing the
## head's own exponent keeps the band's cross-section identical to the shell's, which the crown
## seam's fixed 2.8 only approximates.
##
## ===== READ THIS BEFORE TOUCHING THE NUMBERS: THE BANDS DO NOT CURRENTLY RENDER. =====
## They have never rendered. The comment that used to sit here derived a "23.7 mm band standing
## 8.6 mm proud, ~2.8 px at the gameplay camera" from the IDEAL superellipsoid surface. The MESH is
## not that surface, and at this aspect ratio it is nowhere near it.
##
## `superellipsoid()` warps a `SphereMesh` by radially projecting each unit vertex direction onto the
## implicit surface (`se_point`), so the mesh can only reach the equatorial radius if some vertex row
## actually lies ON the equator. Godot places `SphereMesh`'s latitude rows at `v = j / (rings + 1)`,
## so an EVEN ring count has no equator row at all. `_segs(5, 4)` is 4 — even — putting the rows at
## 0, 36, 72, 108, 144 and 180 degrees. On a 4:1-flat superellipsoid the 72-degree ray runs out of
## the thin Y axis long before it reaches the wide X one, so the outermost row lands at 66% of the
## intended radius. The whole band therefore sits INSIDE the head shell and draws nothing.
##
## MEASURED, NOT DEDUCED. The frac 0.50 band asks for x-semi 0.2918; the built mesh's own
## `get_aabb()` reports half-x 0.193374, and a row-by-row model of the above predicts 0.193374.
## Rendering all three bands in pure #ff0000 produces a head with no red on it anywhere.
##
## THE FIX, WHEN SOMEONE PICKS THIS UP, IS TWO CHANGES AND IT IS NOT A TUNING PASS:
##   1. NEVER BUILD A FLAT SUPERELLIPSOID. Build the band NEAR-ROUND — `(rx, rx, rz)`, where the
##      outermost row reaches 99% of the equator instead of 66% — and squash it to a band with a
##      NODE SCALE (`band.scale = Vector3(1, STRATA_T / rx, 1)`). Same 110 tris, same cache, and the
##      cross-section at y = 0 is still exactly the head's own plan, which is what lets it hug a
##      rounded-square head where a circular torus or a `rounded_box` cannot. It is also robust
##      rather than lucky: picking a ring count that happens to land on the equator works today and
##      breaks silently the next time `ChibiModel.DETAIL` moves.
##   2. MATCH THE HEAD'S RADIAL COUNT. At `STRATA_SEGS` 18 the band resolves to an 11-gon against the
##      head's 23-gon, so it pokes out at its vertices and sinks between them and renders as a DASHED
##      line. 30 (-> 18 segments) is the smallest count that wraps cleanly at PROUD 1.04.
##
## WHY IT IS NOT FIXED IN THIS CHANGE, WHICH IS A DELIBERATE CALL AND NOT AN OVERSIGHT. I built all
## of that, rendered it, and it makes him WORSE. Three visible horizontals on a rounded vertical form
## read as BARREL HOOPS, and with the R4 craze underneath them the head reads as woven wicker — a
## beehive with a plate on top. That is structural, not a tuning problem: the band pitch (0.099 m)
## and the craze cell size (0.065 m) are close enough to interfere, and I could not separate them by
## thinning the bands (t 0.020), softening them (proud 1.036) or refining the craze (scale 3.4).
## Making them visible is therefore a DESIGN change needing its own pass and its own review, not a
## side effect of the skin change — and the character shipped and passed review looking exactly as he
## does now. So the geometry below is byte-for-byte the shipped build, and this comment is the fix.
## Whoever takes it: the strongest lead is FEWER bands (one heavy line low on the face reads as a
## stratum; three read as a barrel), and re-measure with the craze on, never in isolation.
##
## THE SAME TRAP IS LIVE ON EVERY CHARACTER IN THE GAME — see the report's `needs_from_others`.
## `_add_head_shell`'s crown seam (y-semi 0.10 of the head's, `rings` 6 -> 4) and `_add_torso_bean`'s
## waist chamfer (y-semi 0.085, `rings` 6 -> 4) are the same flat-pancake-at-an-even-ring-count
## shape. Do not copy this pattern into a new part.
##
## Heights: 0.50 / 0.20 / -0.12 of the y semi-axis, which lands them at 0.165 / 0.066 / -0.040
## head-local — an even 0.099 m pitch down the face, and the lowest still clears the mouth. Grading a
## stack of horizontals at a constant pitch is exactly what his terraces do.
const STRATA_FRACS: Array = [0.50, 0.20, -0.12]
const STRATA_T := 0.024
const STRATA_SEGS := 18
const STRATA_PROUD := 1.035

func _add_strata() -> void:
	var m := _toon(SKIN_DEEP, _matte({"rim": 0.02}))
	for frac: float in STRATA_FRACS:
		var k: float = pow(maxf(1.0 - pow(absf(frac), head_n), 1e-4), 1.0 / head_n)
		# The head's own half-extents at this height, oversized so a rim of the band SHOULD clear the
		# shell. It does not — the mesh only reaches 66% of `rx`. See the note above.
		var rx: float = head_semi.x * k * STRATA_PROUD
		var rz: float = head_semi.z * k * STRATA_PROUD
		# THIS IS THE SHIPPED BUILD AND IT IS THE BROKEN ONE — a flat superellipsoid, kept byte for
		# byte so this change stays a skin/crown/mouth change and nothing else. The working form is
		# `superellipsoid(Vector3(rx, rx, rz), ...)` plus `band.scale = Vector3(1, STRATA_T / rx, 1)`
		# at STRATA_SEGS 30; do not apply it without re-judging the barrel-hoop read. See above.
		_mi(superellipsoid(Vector3(rx, STRATA_T, rz), head_n, STRATA_SEGS, 5), m, _head,
			Vector3(0.0, head_semi.y * frac, 0.0), "Strata")


# --------------------------------------------------------------------------------- the capital
## THE CAPITAL — R4's answer to "every alien has the same crown". A thick chamfered block of cut
## stone that the head widens into near the top, with a hard dark rim line bedded under it, and the
## head's own dome and eye trunk still rising above it. A quarried thing on a creature who cuts stone
## for a living and whose head is already a standing stone.
##
## WHY A BLOCK AND NOT A RING OF HORNS. A ring of four short banded horns was drafted for him and was
## rejected twice over. First on variety: Mayor Orbit already wears horns and Pip and Fen were both
## being given crown ROWS, so a fifth row of small repeated cones is the eyestalk problem rebuilt
## with a new part number — at 8 m a row of nubs and a row of spikes and a row of stems are one
## shape. Second on the hard-vocabulary cap: horns plus his existing lid ridge plus the new tusks is
## three, and the cap is two. So his crown is ONE CONTINUOUS PIECE, which is a topology nobody else
## in the cast has at all — every other crown in the game is a row of small parts.
##
## WHY `rounded_box` AND NOT `superellipsoid`. A flat superellipsoid cannot make a slab. Its vertex
## rows sit at fixed latitudes and collapse onto the top plane within a few centimetres of the axis,
## so it renders as a shallow double cone; the strata note above has the full measurement, and it is
## why those bands are invisible. `rounded_box` places every vertex as `n * r + sign(n) * (half - r)`,
## so the flat faces are exactly flat and the corner radius is exactly the bevel — which is what
## "chamfered with a hard rim" means, and it is immune to the ring count. It is also rectangular in
## plan, which agrees with the head: at head_n 3.2 the horizontal cross-section is a rounded square.
##
## THE THREE THINGS THE FIRST BUILDS GOT WRONG, ALL FOUND BY RENDERING, NONE BY ARITHMETIC:
##   1. A THIN WIDE SLAB IS A PLANK. 0.598 across by 0.070 thick is 8.5:1, and the head at that
##      height is only 0.380 wide, so it read as a shelf cantilevered out of nothing. The shipping
##      block is 0.536 by 0.124 — 4.3:1 — and its BASE is flush with the head (0.268 against the
##      head's 0.263 at y 0.176) so it grows out of the shell instead of being stuck on it.
##   2. THE SAME COLOUR *AND* THE SAME TEXTURE AS THE HEAD MERGES; THE SAME COLOUR ALONE DOES NOT.
##      Carrying SURF_HEAD onto the slab let the craze run straight over it and the eye read one
##      object. But a CONTRASTING pale dressed-stone tone was worse: under the gameplay camera's
##      28-degree downward pitch the top face is fully exposed and a large bright plane up there is
##      the single brightest thing on him, which R2.6 exists to prevent. Shipping answer: the head's
##      OWN skin tone, SMOOTH and unpatterned, with SKIN_DEEP under it. The texture break separates
##      the two forms at conversation range; the dark rim and the overhang carry it at 6.5 m.
##   3. IT RINGS THE TOP OF THE HEAD, IT DOES NOT CAP IT. Seated as a cap, with its top face the
##      highest thing on the skull, it read as a mortarboard from every gameplay angle — and a hat is
##      Mayor Orbit's. Dropped so it spans 0.176-0.300 against a crown at 0.330, the dome and the eye
##      trunk still stand above it, and a horizontal that has head above it is a cornice, not a brim.
##
## THE OVERHANG IS THE READ. Surface detail cannot carry identity at the 7.4 m gameplay camera — the
## library's own header puts a 10% albedo change at ~1.5% on screen — so this has to be silhouette.
## The head is 0.181 half-wide at the block's top face and the block is 0.268, so it stands 87 mm
## proud there and breaks the outline from every angle. The rim plate is wider still (0.282) and much
## thinner, so the profile is light over dark over crazed: the same trick the strata bands were meant
## to play, on a part that actually renders.
##
## CLEARANCE: the block's top is 0.300, the eye trunk's base is 0.257 and its tip 0.560, so the trunk
## rises THROUGH the block and out of the head's crown — intended, and it gives the lagging eye-track
## somewhere to hinge. `marker_clearance()` is unchanged: 1.673 still dwarfs the block's 1.301.
const CAPITAL_RIM := Vector3(0.564, 0.026, 0.514)   ## FULL size — `rounded_box` halves it
const CAPITAL_RIM_Y := 0.168                        ## 0.155-0.181, bedded under the block's base
const CAPITAL_RIM_BEVEL := 0.010
const CAPITAL_SLAB := Vector3(0.536, 0.124, 0.488)
const CAPITAL_SLAB_Y := 0.238                       ## 0.176-0.300, against a crown at 0.330
const CAPITAL_SLAB_BEVEL := 0.028

func _build_capital() -> void:
	# Rim first and slightly larger, so it shows as a hard dark lip all the way round the block's
	# underside rather than as a separate plate. Same order `_add_plastron` uses for the same reason.
	_mi(rounded_box(CAPITAL_RIM, CAPITAL_RIM_BEVEL, 18), _toon(SKIN_DEEP, _matte({"rim": 0.02})),
		_head, Vector3(0.0, CAPITAL_RIM_Y, 0.0), "CapitalRim")
	# NO surface opts: the block is a DRESSED face against a weathered one. See point 2 above.
	_mi(rounded_box(CAPITAL_SLAB, CAPITAL_SLAB_BEVEL, 18), _toon(SKIN, _matte({"rim": 0.03, "spec": 0.03})),
		_head, Vector3(0.0, CAPITAL_SLAB_Y, 0.0), "CapitalSlab")


## The grin, dropped to the bottom of the tall face, four blunt square uppers and two upward tusks.
func _build_mouth() -> void:
	var mouth_node := _face.get_node_or_null("Mouth") as Node3D
	if mouth_node == null:
		return
	_orient_on_head(mouth_node, 0.0, MOUTH_PITCH_GRIG, 0.004)
	# Applied to the parent Mouth node, NOT to the smile arc: `_apply_face` rewrites the arc's own
	# scale every frame to drive the open/closed blend.
	mouth_node.scale = MOUTH_SPREAD
	_add_wide_grin(mouth_node, GRIN, TOOTH, GRIN_SIZE, GRIN_TEETH)


# ================================================================================= worn stone
## THE TALLY COLLAR — five flat chamfered chalk slabs hanging on a cord, one notched per terrace he
## has cut. Nobody in the cast wears stone. Graded so the centre slab hangs lowest, which reads as a
## worn working object rather than a neat five-piece necklace.
func _build_tally_collar() -> void:
	_tally = _node("TallyCollar", _torso, Vector3(0.0, COLLAR_Y, 0.0))
	var cord := _mi(torus(0.150, 0.172, 18, 5), _toon(SKIN_DEEP, _matte({"spec": 0.03})),
		_tally, Vector3(0.0, 0.004, 0.0), "Cord")
	cord.scale = Vector3(1.06, 0.55, 0.88)
	var m_slab := _toon(TALLY, _matte({"rim": 0.03}))
	var m_notch := _toon(TALLY.darkened(0.34), _matte({"spec": 0.0}))
	for i in 5:
		var off := float(i - 2)
		var ang := off * 0.26
		var drop := 0.030 + 0.016 * (2.0 - absf(off))
		var slab := _node("Slab%d" % i, _tally,
			Vector3(sin(ang) * 0.175, -drop, -cos(ang) * 0.148))
		slab.rotation = Vector3(0.10, ang, -0.06 * off)
		_mi(rounded_box(Vector3(0.050, 0.072, 0.014), 0.008, 10), m_slab, slab, Vector3.ZERO, "Slab")
		# Not every slab is notched — an even five would read as decoration rather than as a count.
		if i % 2 == 0:
			_mi(rounded_box(Vector3(0.030, 0.006, 0.004), 0.002, 6), m_notch, slab,
				Vector3(0.0, -0.018, -0.008), "Notch")


## A hard waist so the smock ends on an edge instead of fading into the hips, and something for the
## wedge to hang from.
func _build_belt() -> void:
	var semi := Vector3(TORSO_RX * TORSO_MUL.x, TORSO_RY * TORSO_MUL.y, TORSO_RZ * TORSO_MUL.z)
	_mi(superellipsoid(Vector3(semi.x * 1.03, 0.018, semi.z * 1.03), 3.0, 16, 5),
		_toon(SMOCK_DARK, _matte({"rim": 0.02})), _torso, Vector3(0.0, BELT_Y, 0.0), "Belt")


## THE CUTTING WEDGE at his hip — deliberately GREY, not brass. Brass is Mayor Orbit's and the two
## would read as the same accessory at gameplay distance.
func _build_wedge() -> void:
	var hip := _node("Wedge", _torso, Vector3(0.192, 0.300, 0.006))
	hip.rotation = Vector3(0.0, 0.12, -0.20)
	_mi(superellipsoid(Vector3(0.036, 0.086, 0.022), 2.2, 8, 5), _toon(WEDGE, _matte({"spec": 0.08})),
		hip, Vector3.ZERO, "Head")
	_mi(rounded_box(Vector3(0.020, 0.075, 0.018), 0.006, 8), _toon(SKIN_DEEP, _matte({})),
		hip, Vector3(0.0, 0.074, 0.0), "Haft")


# ================================================================================= animation
func _animate_extras(delta: float) -> void:
	# THE LAGGING EYE-TRACK. The pivot sits INSIDE `_head`, so its rotation is added on top of the
	# head's own. Rotating it toward HEAD_YAW would make the eye OVERSHOOT the turn; what reads as
	# thought is the eye holding still in world space and then catching up. So the pivot is driven by
	# the DIFFERENCE between a lagged copy of the head angle and the head's current angle: the moment
	# the head turns, that difference is large and negative, which cancels the head's rotation and
	# pins the eye where it was; as the filter catches up the difference decays to zero and the eye
	# arrives. Clamped so it can trail by at most 0.14 rad — past that the stalk reads as broken
	# rather than as slow.
	var yaw := pose(P.HEAD_YAW)
	var pitch := pose(P.HEAD_PITCH)
	var k := 1.0 - exp(-EYE_LAG_RATE * delta)
	_eye_follow_yaw = lerpf(_eye_follow_yaw, yaw, k)
	_eye_follow_pitch = lerpf(_eye_follow_pitch, pitch, k)
	if _eye_pivot != null:
		_eye_pivot.rotation.y = clampf((_eye_follow_yaw - yaw) * 0.9, -EYE_LAG_MAX, EYE_LAG_MAX)
		_eye_pivot.rotation.x = clampf((_eye_follow_pitch - pitch) * 0.7,
			-EYE_LAG_MAX * 0.6, EYE_LAG_MAX * 0.6)
	# The lid ridge is the only expression the face has above the grin: it hoods down when he is
	# thinking (EXTRA_A goes to -1) and lifts a little while he talks (EXTRA_A goes to +1).
	if _lid != null:
		var think := clampf(-pose(P.EXTRA_A), 0.0, 1.0)
		var talk := clampf(pose(P.EXTRA_A), 0.0, 1.0)
		_lid.rotation.x = LID_TILT - 0.26 * think + 0.10 * talk
	# The tally slabs swing on their cord: same first-order trick, driven by the torso roll at 0.4x.
	# `_torso_pivot` applies -TORSO_ROLL, so a positive difference here is the slabs hanging behind
	# the body as it rolls out from under them.
	if _tally != null:
		var roll := pose(P.TORSO_ROLL)
		_tally_follow = lerpf(_tally_follow, roll, 1.0 - exp(-5.2 * delta))
		_tally.rotation.z = clampf((roll - _tally_follow) * 0.4, -0.24, 0.24)


# ================================================================================= QA
## MARKER HEIGHT — measured, not guessed, and it does NOT come out the way the spec predicts.
##
## `NPC.MARKER_HEIGHT` is 1.52 and npc.gd:477 places the '!' at `Vector3(0, MARKER_HEIGHT *
## _body_scale, 0)` while `ChibiModel.rebuild()` sets `scale = Vector3.ONE * body_scale`. BOTH are
## multiplied by the same factor, so body_scale cancels out entirely and the marker always lands at
## 1.52 in MODEL space. docs/NEXT_WORLDS.md's fix ("either set body_scale 0.92 (tip 1.528)") cannot
## work for that reason — and 1.528 is above 1.52 even on its own arithmetic.
##
## In model space Grig's crown is at 1.531, his stalk tip at 1.661 and the top of his eyeball at
## 1.773, so the marker would be drawn inside his head no matter what body_scale is. This needs a
## per-model marker height in npc.gd (see the report's `needs_from_others`); ~1.95 clears him.
## Returns the model-space height the marker must clear, so a showcase or a test can assert on it.
func marker_clearance() -> float:
	return head_y + STALK_TIP.y + EYEBALL_R
