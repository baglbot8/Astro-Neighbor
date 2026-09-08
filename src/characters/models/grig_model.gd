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
## An eighth is TWO NOSTRIL HOLES, and it is new. Until this change he had no nose at all and a hard
## dark RIM PLATE bedded under the stone capital. The user asked what that line across the middle of
## his face was supposed to be and asked for two nostril holes in its place, so the rim is gone, the
## lower face is one uninterrupted crazed field, and the nose is two sunk black slots in raised stone
## lips. `_build_capital` records what the rim was, how it was identified and what still separates
## the block from the head without it; `_build_nostrils` records the holes and the two "the mesh is
## not the extent you asked for" traps that decide their primitives.
##
## The STRATA BANDS that used to ring the head went with it. They never rendered, they cost 330
## triangles of buried geometry, and after this change they are one "fix" away from redrawing the
## exact mark the user has just rejected. The tombstone under "head detail" keeps the judgement.
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
const SKIN_DEEP := Color("#8d735c")   ## S 0.348 V 0.553 — lid ridge, bare legs, tally cord, haft
const SCLERA := Color("#ece4d4")      ## the big pale eyeball, so the dark oval becomes a pupil
const EYE := Color("#241d18")
const GRIN := Color("#3a2b22")        ## mouth cavity, V 0.227
const TOOTH := Color("#efe7d6")
## THE NOSTRIL BORES, and they are DELIBERATELY DARKER THAN THE MOUTH — V 0.133 against the grin's
## 0.227. Not a stylistic preference: a hole reads as deep because of how much light fails to come
## back out of it, and a 76 mm slot catches far less bounce than a 242 mm cavity, so painting them
## the same value makes the small one read as the shallow one. Going darker still is not available —
## `_matte`'s shade floor and the scene's navy ambient put a near-black under this in shadow anyway,
## and the difference between #221a15 and pure black is under a value point once the toon shade term
## has run. If the bores ever read FLAT rather than shallow, that is the ring lip's job, not this
## colour's; see `_build_nostrils`.
const NOSTRIL := Color("#221a15")
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
## 7.8 cycles/m it would draw about 1.9 of them across the whole head. The horizontal banding was
## therefore built as real geometry instead — and has now been REMOVED outright, so this shell's
## craze is the only pattern on the head and there is nothing horizontal left to interfere with it
## (see the strata tombstone below). The shell gets the CELLULAR `skin` kind, weighted the opposite
## way from Zorp's: he is spot-dominant (blotches, an animal), Grig is EDGE-dominant (crazed cell
## walls, cracked chalk).
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
## `crown_seam: false` — R4, and it STAYS false, but the reason has completely changed and the old
## one is now a trap. It was originally two mechanical arguments: the seam was a flat pancake
## superellipsoid and was invisible for the same reason the strata bands were, and the capital's rim
## plate was already drawing the hard horizontal anyway. BOTH have expired. `ChibiModel._se_slab`
## fixed the flat-pancake bug for every character (it measures the old seam at 37.4% of its
## requested radius), so the seam WOULD render now; and the rim plate is gone, deleted because the
## user asked for the line across Grig's face to be taken off. So turning the seam on today would
## put a hard horizontal band back round the top of this head — the exact mark that was just
## removed, drawn by a different part. It is off on DESIGN grounds now, not on broken-mesh grounds.
## Skipping it is also 110 tris back toward the capital's cost.
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
	# After the mouth, because the nostrils are placed RELATIVE to it — the blank field they sit in
	# is bounded below by the grin cavity's top edge and above by the capital's base, and both of
	# those numbers are derived in `_build_nostrils`' comment from constants the two owners declare.
	_build_nostrils()
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
## ===== TOMBSTONE: THE STRATA BANDS. Three horizontal panel grooves used to be built here, wrapping
## the whole head at 0.50 / 0.20 / -0.12 of the y semi-axis (an even 0.099 m pitch down the face),
## mirroring the contour rings of Grig's own planet. THEY ARE GONE. Three reasons, in the order they
## matter, and the last one is why they went NOW rather than at some tidy-up later.
##
## 1. THEY NEVER RENDERED, ON ANY BUILD, ON ANY FRAME. They were flat superellipsoids, and
##    `superellipsoid()` projects SphereMesh vertex DIRECTIONS radially onto the implicit surface,
##    so the mesh only reaches its own equatorial radius if a vertex row lies ON the equator. Godot
##    puts rows at v = j/(rings+1), so an EVEN ring count has none — and `_segs(5, 4)` is 4. On a
##    0.2845 x 0.024 pancake the outermost row (72 deg) runs out of the thin Y axis long before it
##    reaches the wide X one and lands at 0.1934: 66% of what was asked for, i.e. 21 cm inside an
##    opaque shell. Measured three ways — `get_aabb()` reported 0.193374, a row-by-row model
##    predicted 0.193374, and rendering all three bands in pure #ff0000 produced a head with no red
##    on it anywhere. Front and back renders taken for THIS change confirm it again: a row-luminance
##    profile down the head interior is flat at 165-172 with only the craze's own +/-6 wobble.
## 2. THEY COST 330 TRIANGLES to draw nothing (3 x 110). That is 6% of his budget on buried mesh.
## 3. AND AS OF THIS CHANGE THEY ARE ARMED IN THE WRONG DIRECTION. The base class has since grown
##    `ChibiModel._se_slab`, which is the correct fix for reason 1 and carries the whole measurement
##    (crown seam asked 0.2036, built 0.0762 -> 37.4%; waist chamfer 31.2%). So the bands are now one
##    two-line edit away from becoming visible — at the exact moment the user has looked at this
##    character and asked for the ONE horizontal line on his face to be taken off. Leaving a loaded
##    version of the rejected mark sitting in the file, behind a comment that reads like a to-do, is
##    worse than deleting it. `_build_capital` has the identification.
##
## WHAT WOULD HAVE BEEN LOST AND IS KEPT HERE. The mechanics live in `_se_slab` and do not need
## repeating. The JUDGEMENT does, because nothing else in the codebase records it: the working
## version WAS built, rendered and deliberately reverted. Three visible horizontals on a rounded
## vertical form read as BARREL HOOPS, and with the R4 craze underneath them the head read as woven
## WICKER — a beehive with a plate on top. That is structural, not tuning: the band pitch (0.099 m)
## and the craze cell (0.065 m) are close enough to interfere, and thinning the bands (t 0.020),
## softening them (proud 1.036) and refining the craze (scale 3.4) all failed to separate them.
##
## SO IF ANYONE REVIVES THEM: it is a design change needing its own approval, and it now needs the
## USER's, not a reviewer's — he has independently rejected a single horizontal band on this face.
## The strongest lead is still FEWER bands (one heavy line low on the face reads as a stratum; three
## read as a barrel), built with `_se_slab` at seg 30, and re-measured with the craze on rather than
## in isolation. Do not rebuild them as flat `superellipsoid()` calls; that is the bug above.


# --------------------------------------------------------------------------------- the capital
## THE CAPITAL — R4's answer to "every alien has the same crown". A thick chamfered block of cut
## stone that the head widens into near the top, with the head's own dome and eye trunk still rising
## above it. A quarried thing on a creature who cuts stone for a living and whose head is already a
## standing stone.
##
## ===== IT USED TO HAVE A DARK RIM PLATE UNDER IT, AND THAT PLATE WAS "THE LINE ON HIS FACE". =====
## The user asked what the line in the middle of Grig's face was supposed to be, and said to make
## that part of the face the same as the rest of the lower face with two nostril holes instead. The
## line was `CapitalRim`: a `rounded_box(0.564, 0.026, 0.514)` in SKIN_DEEP at head-local y 0.168,
## bedded under the slab. It is deleted. Three measurements identified it, and they are recorded
## because "which line did he mean" was the risky half of this change, not the removal:
##   1. IT WAS THE ONLY HARD HORIZONTAL ON HIM THAT ACTUALLY DREW. The strata bands never rendered
##      (see their tombstone) and `crown_seam` is false, so the shell below the block is one
##      uninterrupted crazed field. There was nothing else on the head it could have been.
##   2. IT PROTRUDED PAST THE BLOCK ON BOTH SIDES, which is its own fingerprint: half-width 0.282
##      against the slab's 0.268. In a zoomed portrait crop it reads as a drawn line with rounded
##      ends sticking out either end of the pale block — unmistakably this part and not the slab.
##   3. AT THE CAMERA THE PLAYER ACTUALLY USES IT SAT AT THE MIDDLE OF THE FACE. Measured off a
##      6.5 m / 28 deg render: head crown at screen y 327, chin at 402, the rim at 364 — 49% of the
##      way down. At that distance the slab's only other separator from the head is smooth-versus-
##      crazed, which is gone by ~4 m, so the head reads as ONE tan mass with a brown band clamped
##      round its middle and no visible reason for it. At 2 m the block still reads as a cap and the
##      band reads as its underside; the "what IS that?" reading is specifically a gameplay reading,
##      which is exactly why it took a --gameplay render to see what the user was seeing.
##
## WHAT REMOVING IT COSTS, STATED PLAINLY, BECAUSE POINT 2 BELOW USED TO ARGUE THE OPPOSITE. The rim
## was half of how this block separated from a head of its own colour. What is left is the half the
## same paragraph calls the real read: silhouette. The junction still works without it — the slab's
## bottom face is 0.240 half-wide after its bevel against a head that is 0.2629 there, so the
## underside is entirely INSIDE the shell; the bevel crosses the head surface at about y 0.186 and
## reaches full width by y 0.204. So the head flares continuously into the block with no gap, no
## floating edge and no pinch, and nothing else had to move. If the block ever reads as a shapeless
## smooth patch at 6.5 m, the honest answer is a capital pass with its own review — NOT putting the
## rim back, which is the thing the user asked to have taken off.
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
## so it renders as a shallow double cone; the strata tombstone above has the full measurement, and
## it is why those bands were invisible. `rounded_box` places every vertex as `n*r + sign(n)*(half-r)`,
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
##      OWN skin tone, SMOOTH and unpatterned. The texture break separates the two forms at
##      conversation range; the OVERHANG alone carries it at 6.5 m, now that the rim is gone. That
##      is a thinner margin than this paragraph originally claimed and it is deliberate — see the
##      rim note at the top. Do not answer a weak read here with a second dark horizontal.
##   3. IT RINGS THE TOP OF THE HEAD, IT DOES NOT CAP IT. Seated as a cap, with its top face the
##      highest thing on the skull, it read as a mortarboard from every gameplay angle — and a hat is
##      Mayor Orbit's. Dropped so it spans 0.176-0.300 against a crown at 0.330, the dome and the eye
##      trunk still stand above it, and a horizontal that has head above it is a cornice, not a brim.
##
## THE OVERHANG IS THE READ. Surface detail cannot carry identity at the 7.4 m gameplay camera — the
## library's own header puts a 10% albedo change at ~1.5% on screen — so this has to be silhouette.
## The head is 0.181 half-wide at the block's top face and the block is 0.268, so it stands 87 mm
## proud there and breaks the outline from every angle. THAT 87 MM IS NOW THE WHOLE CASE. It used to
## be backed by a wider (0.282) rim plate giving a light-over-dark-over-crazed profile; with the rim
## deleted the block is carried by overhang and by the top face's exposure under the 28-degree
## camera, and by nothing else.
##
## CLEARANCE: the block's top is 0.300, the eye trunk's base is 0.257 and its tip 0.560, so the trunk
## rises THROUGH the block and out of the head's crown — intended, and it gives the lagging eye-track
## somewhere to hinge. `marker_clearance()` is unchanged: 1.673 still dwarfs the block's 1.301.
const CAPITAL_SLAB := Vector3(0.536, 0.124, 0.488)
const CAPITAL_SLAB_Y := 0.238                       ## 0.176-0.300, against a crown at 0.330
const CAPITAL_SLAB_BEVEL := 0.028

## ONE MESH. It used to build a `CapitalRim` first — see the rim note at the top of this section for
## what that was, how it was identified as the line the user objected to, and why it is not coming
## back. The slab's own numbers are untouched: nothing about the block had to move to close the gap
## the rim left, because the rim was never load-bearing on the junction, only on the read.
func _build_capital() -> void:
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


# ==================================================================================== the nose
## TWO NOSTRIL HOLES, and until this change he had no nose at all. The user asked for them in place
## of the rim plate that used to cross his face (`_build_capital` has the identification). "Nostril
## HOLES" is the whole brief, so this is built to read as two things sunk INTO the head rather than
## as two marks painted on it — which on an opaque closed shell that cannot be cut is entirely a
## matter of standing something in front of something dark.
##
## THE ANATOMY OF THE FAKE HOLE. Per side: a torus LIP seated 2 mm proud of the shell, and a
## cylinder BORE whose flat outward cap sits 2 mm proud in the middle of it. The lip's crest is
## 8.0 mm proud, so the black cap sits 6.0 mm BEHIND the ring standing around it. That 6.0 mm of
## standoff is the entire illusion; there is no other depth cue and nothing else to tune if it fails.
##
## WHY A CYLINDER AND NOT A SUPERELLIPSOID — the first of two "the mesh is not the extent you asked
## for" traps on this part, and the same family of bug as the strata tombstone above. A CONVEX blob
## seated 2 mm proud does not show its own width, it shows the tiny cap that clears the surface: the
## same 0.038 half-width built as a superellipsoid 0.026 deep at n 2.4 and poked 2 mm out shows a cap
## only 0.0184 half-wide — 48% of the shape asked for — and shows it as a soft dome, which reads as a
## painted dot with a smudge on it. A cylinder's cap is FLAT, so it shows exactly its radius with a
## hard silhouette
## edge all the way round, and 2 mm of its side wall stands proud as a dark collar under the lip.
## "Hole" is a hard edge; do not swap this primitive for a rounder one.
##
## WHY THE LIP IS SMOOTH SKIN AND NOT CRAZED — the second trap, and it is measured. toon_soft.gdshader
## sets `v_objpos = VERTEX` and reads `wpos = v_objpos`, so the surface pattern is OBJECT space,
## anchored per MeshInstance. SURF_HEAD runs sd_skin at surface_scale 2.2 = 7 * 2.2 = 15.4 cells/m,
## a 65 mm cell. The lip is 100 mm across, so carrying SURF_HEAD onto it would land about ONE AND A
## HALF cells on the whole part — a coin flip between an invisible interior and a solid dark donut,
## decided by the hash and not by anything anyone can tune. Smooth SKIN is the precedent this character
## already ships (the capital slab, same `_matte` family), and the material library's own header puts
## a 10% albedo change at ~1.5% on screen at 7.4 m, so at gameplay the lip is pure silhouette and the
## smooth/crazed difference does not exist. The BORE keeps the mouth cavity's exact material family —
## `{"spec": 0.0, "rim": 0.0, "shade": 0.05}`, no `_matte` — so his two dark openings shade
## identically instead of the small one catching a rim light and reading as a bead. NO alpha anywhere
## (an alpha-0 colour renders BLACK on this material), and no new `surface_kind`.
##
## ===== THE TWO-EYES TRAP, WHICH IS THE REAL RISK ON THIS PART AND NOT A HYPOTHETICAL. =====
## Two dark ovals side by side in the middle of a blank face are EYES. This file already records that
## exact failure once — see `_build_geometry`, where two brow bars left on the head "read as a second
## pair of eyes and put the generic animal face straight back" — and on a CYCLOPS whose one real eye
## is up on a trunk off the head entirely, a second pair on the face is not a blemish, it is a
## different creature. Three separate things fight it and ALL THREE have to survive any tuning:
##   1. THEY ARE LOW, NOT CENTRED. The blank field runs from the capital's base (y 0.176) to the top
##      of the grin cavity (y -0.076: mouth centre -0.1204 plus GRIN_SIZE.y 0.026 * MOUTH_SPREAD.y
##      1.70). Its midpoint is y 0.050 and these sit at y 0.013 — 89 mm above the mouth against
##      163 mm below the block, so they group with the MOUTH rather than floating where eyes live.
##      Measured on the 6.5 m render, that is 70% of the way down the head, against the deleted
##      rim's 49%. This is the mitigation that is doing the most work; give it up last.
##   2. THEY ARE SQUASHED FLAT. 76 x 38 mm, a 2:1 SLOT. Eyes in this game are round-ish (his own
##      pupil is 0.088 x 0.092, i.e. slightly TALLER than wide). A 2:1 slot is not an eye shape, and
##      this is the mitigation the second build got wrong: at 1.6:1 the close-up read as a pair of
##      eyes, pale lip standing in for a sclera and all. Flattening it is what fixed that.
##   3. THEY NEARLY TOUCH. The two lips finish 10.6 mm apart and the whole nose is 211 mm wide — 38%
##      of the 550 mm head, against a 242 mm mouth at 44% — so the pair merges into ONE nose mass
##      instead of reading as two separate symmetric features. Eyes are spaced about one eye-width
##      apart; these two bores are 34.6 mm apart against a 76 mm width, well under half that.
## If a render ever reads as eyes, the fix order is: closer together, then squashed harder, then
## lower. Making them SMALLER is the last resort — the user asked for holes and said nothing about
## subtlety, so the failure mode to avoid is "I cannot see them".
##
## ANIMATION: NONE, DELIBERATELY. These are rigid head geometry and ride `_head` exactly like the
## capital. They are NOT added to `_animate_extras`, which already carries two named cast-unique
## traits (the lagging eye-track and the tally swing); a third first-order filter in there is budget
## spent on something nobody asked for, and a flaring nostril is not in Grig's character. Nor are
## they appended to `_eyes` / `_eye_ovals` / `_eye_happy` / `_eye_round` / `_eye_size` / `_brows`.
## They are not eyes and `_apply_face`, which rewrites all five arrays every frame, must never see
## them. Parented under `_face`, which sits at the head origin with no rotation, so `_orient_on_head`'s
## head-space result drops in untouched (the same fact `_build_stalk` relies on).
##
## R4 VOCABULARY CAP: unaffected. The two hard/heavy slots are spent on the lid ridge and the tusks.
## A nostril is a HOLE, not a protrusion; the only thing here that stands proud is an 8 mm lip. Over
## this change as a whole the character LOSES one hard horizontal band and gains no hard silhouette,
## and the triangle count goes DOWN. He gets softer, not harder.

## Seat. `_orient_on_head` builds d = (sin(yaw)cos(pitch), sin(pitch), -cos(yaw)cos(pitch)) and drops
## it on the head superellipsoid, giving p = (0.0553, 0.0134, -0.2495) with a surface normal of
## (0.0268, 0.0007, -0.9996) — 1.54 degrees off dead forward. Both nostrils therefore sit on the same
## near-flat frontal plane and face the camera squarely, which is what lets two separate meshes read
## as one nose instead of as two beads wrapped round a curve.
const NOSTRIL_YAW := 12.5           ## deg, mirrored -> x = +/-0.0553
const NOSTRIL_PITCH := 3.0          ## deg -> y = +0.0134 (see the two-eyes note, point 1)
## Torus inner/outer radius -> tube radius 0.008, centre radius 0.042.
const NOSTRIL_LIP := Vector2(0.034, 0.050)
## Vertical squash, applied as a node scale to BOTH parts so the lip and the hole stay concentric.
## 0.50 makes the hole a 2:1 SLOT, and that ratio is a two-eyes mitigation before it is a style
## choice — see point 2 of the note above. It was 0.64 in the first build and the close-up read as a
## pair of eyes; flattening it is what broke that.
const NOSTRIL_SQUASH := 0.50
## The lip's DEPTH scale, and it is deliberately NOT NOSTRIL_SQUASH. The squash runs on the mesh's
## Z (up the face) and the standoff on its Y (out of the face), so flattening the hole into a slot
## with one number would flatten the lip's crest by the same factor and take the depth cue with it —
## at squash 0.50 the crest would drop from 8.0 mm to 6.0 mm proud for no reason anyone asked for.
## Keeping the two separate is what lets the slot get flatter WITHOUT the hole getting shallower.
const NOSTRIL_LIP_DEPTH := 0.75
## The lip PLANE off the shell. DO NOT TIDY THIS TO ZERO. At 0 the lip z-fights the shell and the
## bore's cap is coplanar with an opaque surface; at a negative value both are inside a solid and
## draw NOTHING AT ALL — the same silent-disappearance failure the strata bands died of. The shell is
## nearly flat here (it recedes only 0.8-1.9 mm from the tangent plane out to the lip's outer edge),
## so 2 mm clears everywhere on the part with room to spare and never floats: the tube's back reaches
## 4.0 mm INTO the tangent plane and is buried by 2.1 mm even at the lip's widest point.
const NOSTRIL_PROUD := 0.002
## Bore radius, horizontal; vertical is this times NOSTRIL_SQUASH. 76 x 38 mm of hole per side.
## SIZED FROM RENDERS, NOT FROM TASTE, AND IT TOOK THREE. 60 x 36 mm measured 7 x 4 px at the 6.5 m
## camera and read as two faint dashes rather than as holes. 68 x 43.5 mm was legible at gameplay but
## its close-up read as EYES — round enough, ringed by a pale lip, sitting in a blank field. This is
## the third: WIDER than the version that was too eye-like and FLATTER than it, so it gains screen
## area (9 x 4.5 px at gameplay) while losing the eye shape. Do not shrink it back, and do not make
## it rounder, without re-reading BOTH a portrait and a --gameplay capture.
## The cap is 4 mm wider than the lip's opening horizontally and 2.0 mm taller vertically, so no
## shell shows through the gap between them from any angle.
const NOSTRIL_BORE := 0.038
## Long enough that the far cap is deep inside the shell and can never poke out of the back of the
## head as the surface curves; only the near cap and 2 mm of side wall are ever visible.
const NOSTRIL_BORE_DEPTH := 0.030
## rad. A little cant so the pair is not a perfectly level pair of dots — outer ends ride higher,
## which is the direction that reads as a flared animal nostril rather than as a drilled hole. Sign
## verified by render, not by reasoning: `_orient_on_head` leaves node-local +Z pointing INTO the
## head, so a positive Z rotation lifts node-local +X, and node-local +X is the OUTBOARD side only
## because the seat yaw is mirrored with the same `s`.
const NOSTRIL_ROLL := 0.10

func _build_nostrils() -> void:
	# Both sides pass identical mesh arguments, so `_mesh_cache` hands out ONE torus and ONE cylinder
	# for the pair and the second nostril is free in memory.
	var m_lip := _toon(SKIN, _matte({"rim": 0.03, "spec": 0.02}))
	var m_bore := _toon(NOSTRIL, {"spec": 0.0, "rim": 0.0, "shade": 0.05})
	for s: float in [-1.0, 1.0]:
		var seat := _node("Nostril%s" % ("L" if s < 0.0 else "R"), _face, Vector3.ZERO)
		# inset 0.0: the seat sits exactly ON the shell and everything below is pushed out along -Z.
		_orient_on_head(seat, s * NOSTRIL_YAW, NOSTRIL_PITCH, 0.0)
		var roll := _node("Roll", seat, Vector3.ZERO)
		roll.rotation.z = s * NOSTRIL_ROLL
		# AXIS MAPPING, and it is the same for both meshes. TorusMesh and CylinderMesh both run along
		# their own +Y; `_orient_on_head` leaves node-local -Z as the outward normal. Rotating -90 deg
		# about X sends +Y to -Z, so the parts point OUT of the face, and sends the mesh's own +Z to
		# node +Y (up the face). Godot applies `scale` in the mesh's LOCAL frame (Node3D builds the
		# basis as rotation THEN `scale_local`), so the scale components below are read in MESH axes:
		# X = across the face, Y = the outward axis, Z = up the face. That is why the vertical squash
		# lands on Z and not on Y, and why the lip is squashed on Y as well (flattening its standoff
		# so the crest stays a hair proud instead of a fat doughnut, at its own NOSTRIL_LIP_DEPTH).
		var lip := _mi(torus(NOSTRIL_LIP.x, NOSTRIL_LIP.y, 18, 10), m_lip,
			roll, Vector3(0.0, 0.0, -NOSTRIL_PROUD), "Lip")
		lip.rotation.x = -PI * 0.5
		lip.scale = Vector3(1.0, NOSTRIL_LIP_DEPTH, NOSTRIL_SQUASH)
		# The cylinder is centred on its own origin, so pushing it back by half its depth puts the
		# OUTWARD cap exactly NOSTRIL_PROUD off the shell and buries the rest.
		var bore := _mi(cylinder(NOSTRIL_BORE, NOSTRIL_BORE, NOSTRIL_BORE_DEPTH, 14), m_bore,
			roll, Vector3(0.0, 0.0, NOSTRIL_BORE_DEPTH * 0.5 - NOSTRIL_PROUD), "Bore")
		bore.rotation.x = -PI * 0.5
		bore.scale = Vector3(1.0, 1.0, NOSTRIL_SQUASH)


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
