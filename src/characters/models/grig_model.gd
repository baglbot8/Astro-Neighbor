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
##   2. A TALL HEAD — 0.550 x 0.660 x 0.500 at n 2.3, a rounded oval (see the 2026-09-15 ROUND 2 note
##      on HEAD_N_GRIG below — round 1 of this same change deleted the capital block but left the
##      exponent at the old boxy 3.2, and a critic caught the flat top that left behind). Not the
##      tallest-to-widest ratio the first build tried (see HEAD_SEMI_GRIG's R3.3 note) but still the
##      tallest head in the cast, and a standing stone with a face, which ties him to his planet.
##   3. AN UNDER-BITE. Four blunt near-square teeth hang from the upper jaw and TWO tusks stand up
##      from the lower one, so the two rows interlock the wrong way round. Everyone else's mouth is
##      a single top row of points. Plus a TWO-lobed mitt against three-or-zero fingers.
##   4. WORN STONE — a tally collar of chalk slabs on a cord, one notched per terrace cut. The rest
##      of the cast wears cloth (Zorp's scarf, the twins' aprons, the Mayor's waistcoat).
##   5. A LAGGING EYE-TRACK. The trunk arrives a beat after the head turns; nothing else in the cast
##      has a delayed feature, and on one huge eye it reads instantly as thought.
##   6. ===== FORMER TRAIT, REMOVED 2026-09-15 ===== used to be A CAPITAL: one continuous chamfered
##      block of cut stone ringing the top of the head. The user looked at the cast lineup and said
##      "remove that flat square at the top of Grig's head? It should just be a rounded oval" — so
##      `_build_capital` and its slab are GONE and the head is now the plain superellipsoid crown on
##      its own, the same primitive `_add_head_shell` gives everyone else. See the tombstone at the
##      top of the "head detail" section below for the full removal note (what it was, why it read as
##      a flat square, and why it is not coming back on a whim).
##   7. CRACKED CRAZE AND NOTHING ELSE. His skin runs `sd_skin` with the spot term switched fully
##      OFF, so he is cell walls only where Zorp is blobs only — see SURF_HEAD.
##
## THE CARVER'S KIT (2026-10-01, the user's pick "Grig grumpy carver" from the design sheets): a
## chalk-canvas apron with a pocket, a chisel in the pocket, a pale stone mallet over his shoulder
## (a new corner in the outline), and the one brow and lid tipped into a sceptical squint. See
## `_build_kit` and LID_ROLL.
##
## NO NOSE (2026-10-01). He wore two nostril holes from 2026-09-15 (a user request, in place of a rim
## plate that crossed his face). The user, on the design sheets: "remove the nostrils and slide the
## mouth more towards the center". At phone size the two slots read as a second pair of squinting
## eyes under the eye on the stalk. The lower face is one uninterrupted crazed field with the grin in
## it; MOUTH_PITCH_GRIG carries the move. The tombstone under "the nose" below keeps what they were.
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
const SMOCK := Color("#64798a")       ## a slate-blue mason's smock — the one cool note
const SMOCK_DARK := Color("#4c5c6b")
const TALLY := Color("#cabfa6")       ## the chalk slabs
const APRON := Color("#cdbfa4")       ## chalk-dusted canvas (the carver's kit)
const MALLET := Color("#b3ab9c")      ## pale chalk-stone mallet head, not his own clay
const STEEL := Color("#9aa0a6")       ## chisel blade, mallet bands
const FOOT := Color("#5a4f45")
const WEDGE := Color("#8b8578")       ## the cutting wedge at his hip

# ---------------------------------------------------------------------------------- head shape
## A head nearly twice as tall as it is wide, a ROUNDED OVAL — not flat-sided, see the ROUND 2 note
## on `HEAD_N_GRIG` just below. `head_y` puts the chin at 1.1010 - 0.4300 = 0.6710, which is EXACTLY
## Zorp's chin line (0.8963 - 0.2250), so the shared shoulder and collar geometry still meets it.
## R3.3 — REBALANCED. The first build was 490 x 860 mm, nearly twice as tall as wide, and it read as
## a vertical loaf with a small mouth floating on a large blank field — the exact complaint the user
## made about Zorp ("a lot of open space ... shrink that open space down more"). 550 x 660 keeps him
## clearly the TALLEST head in the cast, which is his silhouette, without the blank slab.
const HEAD_SEMI_GRIG := Vector3(0.2750, 0.3300, 0.2500)
## ROUND 2, 2026-09-15 — LOWERED 3.2 -> 2.3. The change just before this one deleted the capital
## block (a "flat square at the top of Grig's head" the user asked to have removed) but left this
## exponent untouched, and a critic measured what that left behind: a rounded BOX, not an oval — the
## top 2% of the head's height (i.e. the band from 96% to 100% of the way from chin to crown) spanned
## 49-52% of the head's own width in a silhouette render, dead flat, against 28% for a true ellipse
## (n 2) and the critic's own theoretical number for the shipped 3.2: `[1 - 0.96^n]^(1/n)` gives
## 51.9% at n 3.2, matching the 49-52% measurement almost exactly. That formula is the whole story of
## this constant: it is the fraction of the head's half-width still standing at 4% of the way down
## from the crown, and it is monotonically INCREASING in n — a higher exponent packs more of the
## curvature into a narrower band right at the pole, which is exactly what "flat top" means on a
## superellipsoid. Solving it back down: n 2.4 -> 37.2%, n 2.3 -> 35.0%, n 2.2 -> 32.8%. 2.3 was
## picked as the critic's suggested-range midpoint (2.2-2.4) — comfortably under the 40% ceiling,
## and closer to a true oval's 28% than to the rejected box's 52%, while still reading as slightly
## more definite than a bare ellipse, which is the "standing stone" trait #2 in the class header
## asks for. Re-measured after the change on both renderers, front/3-4/side, surfaces-off silhouette:
## see the grig2 comparison sheet. This ALSO makes the tessellation note below more conservative than
## it was — n 2.3 spreads its curvature more evenly than 3.2 did, so `HEAD_SEGS_GRIG` (tuned for the
## harder case) has more facet margin now than it needs, not less.
const HEAD_N_GRIG := 2.3
## Holds the chin where it was: 1.1010 - 0.4300 = 0.6710, so 0.6710 + 0.3300.
const HEAD_Y_GRIG := 1.0010
## Tessellation. Tuned when `HEAD_N_GRIG` was 3.2 — Zorp's proven exponent, where the DEFAULT (44, 22)
## would not facet, but Zorp's head is 0.45 m tall and this one is 0.86 m, so the same 13 latitude
## rings would stretch to 66 mm bands down the tall front plane. 38 x 26 resolves to 23 x 16 after
## ChibiModel.DETAIL and costs 782 tris against the default's 728. `HEAD_N_GRIG` has since dropped to
## 2.3 (see its own note above), which spreads curvature more evenly and so needs LESS tessellation to
## avoid faceting than the number below was built for — this is now a safety margin, not a floor. Do
## NOT raise `head_n` back toward 3.2+ without re-checking these: above ~3.2 the curvature repacks
## into a narrow chamfer band and the shell renders as a box again, which is the bug this whole note
## exists to prevent a repeat of.
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
## THE UPPER EYELID (2026-09-27, the user: Grig should read "a little grumpy"). A skin-coloured cap
## over the top of the eyeball, cut FLAT so its edge is a level line across the top of the pupil:
## a heavy-lidded, unimpressed look, still one big soft eye. It is the SAME slot as the ridge (the
## lid family of the hard vocabulary), not a third one, and it lifts clear for the happy "^" and the
## surprised "O" so those expressions are unchanged.
## AN ELLIPSOID, NOT A SPHERE. The pupil is a FLAT disc (0.088 x 0.092 x 0.030) centred 0.094 out
## and pitched down 8 deg, so its upper rim stands 0.131-0.133 from the ball centre: a 0.128 sphere
## rendered BEHIND the pupil, and a 0.140 sphere cleared it but overhung the 0.112 ball by 28 mm a side
## and read as a mushroom hat (both measured on real-world frames). So the lid hugs the ball at the
## sides (x 0.120) and reaches forward only where the pupil is (z 0.148). Sampled over the pupil
## surface above the cut, the largest ellipsoid metric is 0.952, i.e. the pupil stays inside.
## The cut at y 0.042 covers the top 20 % of the pupil (y -0.104..0.078) and leaves the glint clear.
const EYELID_SEMI := Vector3(0.120, 0.124, 0.148)
const EYELID_CUT_Y := 0.042
const EYELID_RIM := 0.075            ## rim tube, in the lid's unit space (~9 mm)
const EYELID_LIFT := 0.80            ## radians the lid swings back for happy / surprised
## The sceptical squint (2026-10-01, the carver's kit): the one brow and the lid are tipped 0.20 rad
## (11 degrees) about the view axis, and the lid rests 0.05 rad lower over the pupil. The lift for
## happy / surprised blends from this rest, so both emotes still open the eye fully.
const LID_ROLL := 0.20
const EYELID_REST := -0.05
## How far the stalk is allowed to trail the head, and how fast it catches up.
## 2.8 rather than the first build's 3.4: measured on a real head turn the faster filter only trailed
## 0.053 rad, which on a 0.226 m stalk moves the eyeball 12 mm and does not read at all. At 2.8 an
## ordinary idle look-around reaches the 0.14 cap, which is 32 mm of drift on a 224 mm eyeball —
## visible as the eye arriving late, which is the whole trait.
const EYE_LAG_MAX := 0.14
const EYE_LAG_RATE := 2.8

# ---------------------------------------------------------------------------------- the mouth
## 2026-10-01: -26 -> -12, the user with the nostrils removed: "slide the mouth more towards the
## center". Measured on the built model: the grin's centre moves from head-local y -0.120 to -0.053
## (36 % -> 16 % of the head's 0.330 half height), and its top edge (centre + GRIN_SIZE.y 0.026 *
## MOUTH_SPREAD.y 1.70) lands at -0.008, just under the head's middle line. History: the first build
## had it at -46 (almost under the chin on the shortened head), then -26, kept low while two nostril
## holes filled the field above it.
const MOUTH_PITCH_GRIG := -12.0
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
var _eyelid: Node3D
var _eyelid_lift: float = 0.0
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
	# No `_build_capital()` call — REMOVED 2026-09-15, see the tombstone under "head detail" below.
	# The head is now the bare `_add_head_shell` oval with nothing capping its crown.

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
	# No `_build_nostrils()` call - REMOVED 2026-10-01, see the tombstone under "the nose" below.
	_build_tally_collar()
	_build_wedge()
	_build_kit()


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
	_lid.rotation.z = LID_ROLL
	_mi(arc_tube(LID_RING_R, LID_TUBE, deg_to_rad(14.0), deg_to_rad(166.0), 14, 6),
		_toon(SKIN_DEEP, _matte({"rim": 0.02})), _lid, Vector3.ZERO, "Ridge")
	# The upper eyelid (see EYELID_R): a flat-cut cap on the ball centre plus a soft rim along its
	# edge, so the lid has a thickness instead of a paper edge. Rotating `_eyelid` about X swings it.
	# Built in unit space and scaled to EYELID_SEMI on the node, so rotating it swings it rigidly.
	_eyelid = _node("Eyelid", _head, STALK_TIP)
	_eyelid.scale = EYELID_SEMI
	_eyelid.rotation.z = LID_ROLL
	var h := EYELID_CUT_Y / EYELID_SEMI.y
	var m_lid := _toon(SKIN, _matte({"spec": 0.04, "rim": 0.02}))
	_mi(_cap_mesh(1.0, h, 5, 20), m_lid, _eyelid, Vector3.ZERO, "Cap")
	var rim := _node("Rim", _eyelid, Vector3(0.0, h, 0.0))
	rim.rotation.x = PI * 0.5
	_mi(arc_tube(sqrt(1.0 - h * h), EYELID_RIM, PI - 0.35, TAU + 0.35, 12, 5),
		m_lid, rim, Vector3.ZERO, "Edge")
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
	riders.append(_eyelid)
	for n: Node3D in riders:
		_adopt(n, _eye_pivot, STALK_BASE)


## A spherical cap of radius `r` above the plane y = `h`, open at the cut (the eyeball fills it).
## Wound like Godot's own primitives - `(b-a) x (c-a)` points INWARD, which is what `toon_soft`'s
## cull_back draws as the outside (see ChibiModel's winding note) - checked per triangle rather than
## assumed, with outward normals.
static func _cap_mesh(r: float, h: float, rings: int, segs: int) -> ArrayMesh:
	var phi_max := acos(clampf(h / r, -1.0, 1.0))
	var pts: Array[PackedVector3Array] = []
	for i in rings + 1:
		var phi := phi_max * float(i) / float(rings)
		var row := PackedVector3Array()
		for j in segs + 1:
			var th := TAU * float(j) / float(segs)
			row.append(Vector3(sin(phi) * cos(th), cos(phi), sin(phi) * sin(th)) * r)
		pts.append(row)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in rings:
		for j in segs:
			var a := pts[i][j]
			var b := pts[i + 1][j]
			var c := pts[i + 1][j + 1]
			var d := pts[i][j + 1]
			var tris: Array = [[a, b, c]]
			if i > 0:
				tris.append([a, c, d])
			for t: Array in tris:
				var v0: Vector3 = t[0]
				var v1: Vector3 = t[1]
				var v2: Vector3 = t[2]
				if (v1 - v0).cross(v2 - v0).dot(v0 + v1 + v2) > 0.0:
					var tmp := v1
					v1 = v2
					v2 = tmp
				for v: Vector3 in [v0, v1, v2]:
					st.set_normal(v.normalized())
					st.add_vertex(v)
	return st.commit()


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
##    worse than deleting it. The capital tombstone below has the identification (and is now itself
##    a tombstone, for the same reason: the block it identified is gone too).
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
## ===== TOMBSTONE: THE CAPITAL, REMOVED 2026-09-15. ===== It used to be R4's answer to "every alien
## has the same crown": a thick chamfered `rounded_box` block, `CAPITAL_SLAB` = (0.536, 0.124, 0.488)
## at head-local y 0.238, that the head widened into near the top, with the head's own dome and eye
## trunk still rising above it — built by a one-line `_mi(rounded_box(...), ..., "CapitalSlab")` in a
## `_build_capital()` this section used to hold. GONE, on the user's direct instruction after looking
## at the cast lineup: "remove that flat square at the top of Grig's head? It should just be a rounded
## oval." That is exactly what the block was — the rest of this file's own case for it (silhouette
## overhang of 87 mm at the block's top face, a cornice under the dome, a topology nobody else in the
## cast shares) was true and is now moot: the read the user is naming is the same overhang, and he
## does not want it. The head is a plain `_add_head_shell` superellipsoid crown now, the same
## primitive every other neighbour ships, with nothing capping it.
##
## WHAT WAS BEDDED UNDER IT, FOR ANYONE WHO GOES LOOKING: a dark `CapitalRim` slab (`rounded_box(0.564,
## 0.026, 0.514)` in SKIN_DEEP at head-local y 0.168) used to run under this block as "the line across
## Grig's face" and was deleted in the change just before this one, once nostril holes took its place.
## Removing the block it was bedded under changes nothing about that earlier call.
##
## COST AND CLEARANCE. -782 tris off his budget (see the class header's "Seven traits" list, which
## drops this as a distinguishing trait). `marker_clearance()` did not reference the block (it is
## `head_y + STALK_TIP.y + EYEBALL_R`, all eye-trunk geometry) and is unaffected. The eye trunk's base
## (0.257) and tip (0.560) both still clear the bare head crown (0.330) with room to spare, so the
## "trunk rises through the block" clearance note that used to live here has nothing left to clear.
##
## IF ANYONE PUTS A CROWN DETAIL BACK ON THIS HEAD: it is a design change needing its own approval,
## the same way the strata bands above do — the user has now rejected two different hard shapes
## capping this head (three horizontal bands, then one block) for the same reason both times: a flat
## man-made mark clamped on top of an otherwise rounded, weathered stone read as machined, not carved.
## The lead the same paragraph would give: if this head ever needs a crown accent again, make it
## something that follows the oval's OWN curvature rather than something that caps or bands it flat.


## The grin, just under the middle of the face, four blunt square uppers and two upward tusks.
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
## REMOVED 2026-10-01. The user, picking Grig's look from the design sheets: "remove the nostrils and
## slide the mouth more towards the center".
##
## WHAT IT WAS, FOR ANYONE WHO GOES LOOKING: two nostril HOLES (a user request of 2026-09-15, in place
## of a rim plate that crossed his face), one per side at yaw +/-12.5 deg, pitch +3 deg on the head.
## Each was a squashed torus lip in SKIN (radii 0.034 / 0.050, squash 0.28, standing 2 mm proud) round
## a squashed dark cylinder bore (#221a15, radius 0.038, 0.030 deep), rolled 0.10 rad so the outer
## ends rode higher: 76 x 21 mm of slot per side. The design review's note on them: at phone size two
## dark slots side by side under the stalk eye read as a second pair of squinting eyes.
##
## IF A NOSE EVER COMES BACK it is a design change needing its own approval, and it should not be two
## dark marks side by side at eye spacing.


# ============================================================================== the carver's kit
## What says "carver" at gameplay distance (2026-10-01): a canvas apron, a chisel in its pocket and a
## mallet over the shoulder. His line "My chisel is older than your planet" now has a chisel to point
## at. Everything is rigid on the torso, so it rides every body animation. KNOWN LIMIT: the mallet is
## fixed to his back and passes close to the raised arm in the happy emote.
func _build_kit() -> void:
	var semi := Vector3(TORSO_RX * TORSO_MUL.x, TORSO_RY * TORSO_MUL.y, TORSO_RZ * TORSO_MUL.z)
	var m_apron := _toon(APRON, _matte(SURF_CLOTH))
	# a narrower, deeper copy of the torso pushed forward: only its front shows, as a bib
	_mi(superellipsoid(Vector3(semi.x * 0.70, semi.y * 0.80, semi.z * 1.0), 3.2, 16, 9), m_apron, _torso,
		Vector3(0.0, TORSO_Y - 0.040, -0.022), "Apron")
	var pk := BoxMesh.new()
	pk.size = Vector3(0.150, 0.070, 0.012)
	_mi(pk, _toon(APRON.darkened(0.14), _matte({})), _torso, Vector3(0.0, TORSO_Y - 0.085, -semi.z - 0.014), "Pocket")
	# the chisel: steel blade down into the pocket, wooden handle up and out
	var m_wood := _toon(SKIN_DEEP.darkened(0.25), _matte({}))
	var ch := _node("Chisel", _torso, Vector3(0.040, TORSO_Y - 0.040, -semi.z - 0.026))
	ch.rotation.z = deg_to_rad(16.0)
	_mi(cylinder(0.019, 0.016, 0.085, 6), m_wood, ch, Vector3(0.0, 0.050, 0.0), "Handle")
	var bl := BoxMesh.new()
	bl.size = Vector3(0.026, 0.060, 0.008)
	_mi(bl, _toon(STEEL, _matte({"spec": 0.12})), ch, Vector3(0.0, -0.020, 0.0), "Blade")
	# the mallet on his back, head up beside his own: the silhouette's new corner
	var ml := _node("Mallet", _torso, Vector3(-0.400, 0.800, 0.120))
	ml.rotation = Vector3(0.0, 0.0, deg_to_rad(30.0))
	_mi(cylinder(0.022, 0.020, 0.560, 6), m_wood, ml, Vector3(0.0, -0.250, 0.0), "Haft")
	var hd := _mi(cylinder(0.082, 0.082, 0.200, 10), _toon(MALLET, _matte({})), ml, Vector3(0.0, 0.050, 0.0), "Head")
	hd.rotation.z = PI * 0.5
	for sx: float in [-1.0, 1.0]:
		_mi(cylinder(0.086, 0.086, 0.022, 10), _toon(STEEL, _matte({"spec": 0.10})), ml,
			Vector3(0.075 * sx, 0.050, 0.0), "Band").rotation.z = PI * 0.5


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
	# The eyelid rests over the top of the pupil (the grumpy resting face) and swings back (+X
	# rotation lifts the front edge) for the happy "^" and the surprised "O", so both still read.
	if _eyelid != null:
		var lift := 0.0
		if pose(P.EYE_HAPPY) > 0.5 or pose(P.EYE_ROUND) > 0.5:
			lift = 1.0
		lift = maxf(lift, clampf((pose(P.EYE_WIDE) - 1.0) / 0.35, 0.0, 1.0))
		_eyelid_lift = lerpf(_eyelid_lift, lift, 1.0 - exp(-14.0 * delta))
		_eyelid.rotation.x = EYELID_REST * (1.0 - _eyelid_lift) + EYELID_LIFT * _eyelid_lift
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
