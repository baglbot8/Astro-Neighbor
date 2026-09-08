class_name AlienModel
extends ChibiModel
## Zorp — the lavender alien neighbour, and the one with FACE TENTACLES.
##
## R5 (LESS CREEPY, AND THE TENTACLES FINALLY GET BUILT). The user looked at the R4 Zorp and said
## his eyes and lips "look too strange... can we make them less creepy", asked for tall black
## ellipses instead of the eyes, "just leave the line and no lips" for the mouth, and — instead of
## the single antenna, which Pip also wears — three tentacles on each side of the face. Four
## changes, and each one is a deletion except the last:
##
##   1. THE IRIS AND THE SCLERA ARE GONE, replaced by ONE solid near-black ellipse per eye, 116 mm
##      tall by 68 mm wide (1.71 : 1). The sclera is what was doing the damage, and it is worth
##      being precise about why, because "add an iris" reads like a warmth move on paper: a PALE
##      BALL carrying a small dark PUPIL is the anatomy of a prey animal's eye, and the R4 build
##      stacked an amber annulus around that pupil, which is specifically a goat/bird read. Rendered
##      close up it was three concentric bands — cream, ochre, black — sitting proud of the head as
##      two balls stuck on, and that is what "creepy" meant. A flat ink shape has no ball, no ring
##      and nothing to stare with. The R4 note claimed the iris was "his face's identity"; it was,
##      and that was the problem. The eye is now the only face part with any ink in it, so the glint
##      is load-bearing — see the eye block for why it was re-authored rather than left alone.
##   2. THE LIP IS GONE. R4 built a 33 mm-thick mauve band standing 21 mm proud of the shell with a
##      dark seam along its crest, on the argument that thickness is what survives at 8 m. It does
##      survive — it survives as LIPSTICK, because a warm band is the only warm thing on a face with
##      no nose and no blush, and it takes a specular highlight along its top edge. What the user
##      was pointing at when they said "the line" was the 9.6 mm seam, so the seam is all that is
##      left: a 22 mm ink arc on the bare shell, `_smile_arc`'s curve at a thinner tube than the
##      default. The OPEN mouth (dark ellipse, interior, tongue) is untouched and still reads.
##   3. THE ANTENNA IS GONE, and this one is a cast decision rather than a Zorp decision. Pip wears
##      an antenna too, the user noticed the duplication, and Pip's is DIALOGUE-LOCKED — six shipped
##      lines in npc_data.gd talk about it — so Pip's cannot move. Zorp's could, so Zorp's went, and
##      the antenna is now unique to Pip. The mint accent survives in the hover ring, which is where
##      BULB still gets used.
##   4. SIX FACE TENTACLES, three a side. This is the one trait the user named two rounds ago that
##      nobody had ever shipped — docs/OPEN_ISSUES.md tracked it as zero call sites, and explicitly
##      ruled Zorp out as its home on the grounds that he was the deliberate control who spends none
##      of the vocabulary budget. The user has now overridden that, so Zorp is NOT the control any
##      more, and the ruling and the CAST_VARIETY row that depends on it are both stale.
##
## He does still wear none of the HARD vocabulary — no brow ridge, no heavy lid, no horns, no tusks,
## no fangs, no shoulder yoke, no lashes — so everyone else's ridge or crest still reads as a choice
## rather than as the house style. The tentacles are soft vocabulary and they are his alone.
##
## R4 SKIN, kept: SMOOTH WITH BIG SOFT SPOTS — the user's exact first ask. `surface_scales` is 0,
## which kills the Voronoi cell walls entirely (they are what has been reading as "rocky texture
## skin"), and the lattice pitch and spot radius together take 65 mm speckles up to ~210 mm blotches.
## It costs LESS palette than the pattern it replaces, not more: an A/B on one identical frame
## (strength 0 vs on, same crop) moves the head crop's saturation mean by +0.028, against the +0.099
## the old setting was measured at. See SURF_HEAD.
##
## Kept, because they are the half of him that already worked: lavender, the striped space-scarf, the
## teal tee with its badge, three-fingered mittens, the bean torso, and the 5 cm hover with its bob
## and glow ring — he is the only neighbour who floats and that is half his identity. He also keeps
## his legs and a real walk cycle; the hover is a hover, not a substitute for a lower body. The
## think-droop and the talk-perk the antenna used to carry did NOT die with it: `_animate_extras`
## drives the same EXTRA_A channel into the tentacles, so "think" still slackens something and
## "talk" still lifts it.
##
## R2.6 (PASTEL AND MATTE). Every albedo below was re-picked against the CURRENT game — the dark
## thin-atmosphere sky and the repainted pastel ground — not the old white-void showcase. The rule
## from the style guide is "desaturate toward the hue's own pastel, never toward brown, and handle
## value separately", so each swatch keeps its hue and loses chroma and top-end value:
##   skin   #a77ff5 S0.48 V0.96 -> #9a80cc S0.37 V0.80   (still lavender, no longer neon)
##   shirt  #5fd0c8 S0.55 V0.82 -> #84bdb5 S0.30 V0.74
##   scarf  #ff8fa8 S0.44 V1.00 -> #c4858f S0.32 V0.77   (V 1.0 pinks were the clipping culprits)
##   trim   #fff1e0 V1.00       -> #e8ddc9 V0.91         (style guide caps near-whites at ~0.92)
##   feet   #7449d4 S0.66       -> #665c93 S0.37 V0.58   (the dark value anchor every AC villager has)
const SKIN := Color("#9a80cc")
const SKIN_DARK := Color("#7c6aa6")
## THE EYE INK, and after R5 it is the whole eye rather than a pupil inside one. S 0.21 V 0.18 — a
## near-black that is still violet, not a pure #000, so the shade term has something to do and the
## ellipse does not read as a die-cut hole. `_add_face` builds the oval material from it at
## spec 0.0 / rim 0.0 / shade 0.08, i.e. deliberately flat: a specular lobe on a 116 mm ink shape is
## the shine that made the R4 lip read as lipstick, and it would do the same to an eye.
const EYE := Color("#221c2e")
const BLUSH := Color("#b3868f")      ## passed but switched off — see `_add_face`'s transparency trap
## THE INK THE CLOSED MOUTH LINE IS DRAWN IN, and R5.1 moved it 75 % of the way from the old plum
## #472440 to the eye's own #221c2e. It is a CONTRAST change, and it is the SECOND of the two
## things wrong with the mouth — the first, and much larger, one is the winding bug written up on
## `_wound_outward`. This one was found first and measured on its own, and the measurement is kept
## because it is why the colour stays where it is now that the geometry draws properly:
##
##   Measured at --gameplay off the capture: skin renders at luma 126-175 and the #472440 line
##   rendered at 60-88, so every partially-covered pixel blended back toward the skin and only the
##   rare fully-covered one stayed dark enough to read as ink. The eye, drawn in #221c2e, rendered
##   at luma 4-33 in the same frames and never breaks up. Swapping the colour ALONE, geometry
##   untouched, roughly doubled the number of the arc's columns carrying a well-inked pixel — a
##   real gain, and nowhere near enough on its own, which is what sent the search at the geometry.
##
##   #2b1e32 is lerp(#472440, #221c2e, 0.75): R 71->43, G 36->30, B 64->50. Albedo luma drops
##   45.4 -> 34.2, which is within 4 of the eye's 30.5, so the line sits in the same ink family as
##   the eyes. The remaining 4 points are deliberate: the mouth should read a hair softer than the
##   eyes rather than compete with them, and the residual red channel keeps a trace of warmth so
##   the face is not drawn in one flat value. Hue is still plum (it is a mouth); it has only lost
##   the top-end value that was letting the lit skin swallow it. Going the last 25 % to #221c2e was
##   not built: nothing at play distance can resolve a 4-luma difference, and spending it buys a
##   mouth drawn in exactly the eye ink, which is a hierarchy this face does not want.
const MOUTH := Color("#2b1e32")
## The open mouth's interior is UNTOUCHED. It is only ever seen behind the open ellipse when Zorp
## talks, at which point the closed line has already faded out (SMILE_HIDE_AT), so it is not part
## of the contrast problem and darkening it would only mute the talking mouth.
const MOUTH_INNER := Color("#6e3049")
const SCARF_A := Color("#c4858f")
const SCARF_B := Color("#e8ddc9")
const SHIRT := Color("#84bdb5")      ## a proper tee — every AC villager wears clothes
const SHIRT_TRIM := Color("#e8ddc9")
const FOOT := Color("#665c93")
const HOVER := 0.05
## Mint. This WAS the antenna bulb's emissive; the antenna is gone and this is now purely the hover
## glow's accent (`_build_glow_ring`, `_animate_extras`). It is kept because a small saturated accent
## is allowed and because deleting it with the antenna is a compile error, not a cleanup.
const BULB := Color("#7fffd4")

# ----------------------------------------------------------------------------------------- eyes
## R5 — ONE TALL INK ELLIPSE PER EYE, seated flat ON the shell. No ball, no ring, no lens stack.
## 116 mm tall by 68 mm wide is 1.71 : 1, which is inside the 1.6-2.0 the brief asked for and is
## also where the shape stops being ambiguous: below about 1.4 a "tall" oval just reads as a circle
## that has been squashed by the blink, because `_apply_face` drives `oval.scale.y` down for blinks
## and a near-round eye spends part of every cycle indistinguishable from a wide one.
##
## THE BROW IS ALREADY OFF and there is no `_drop_brow` to go looking for: `_add_face` is called
## with `"brows": false`, which is a per-eye spec switch `_build_eye` reads, so no brow is ever
## built. Nothing to remove for R5's "drop the brow".
##
## WHY THE YAW MOVED 22.5 -> 20.0, with the arithmetic, because eye spacing is a REVIEWED metric and
## moving one silently is how a style-guide band gets broken. On this shell (semi 0.3200/0.2250/
## 0.2720, n 3.2) the surface point at yaw 22.5 has x = 0.11133, so the two centres are 222.7 mm
## apart = 34.8 % of the 640 mm head — the very TOP of the mandated 28-35 % band, and it was tuned
## for a 104 mm-wide pale ball. The new eye is only 68 mm wide, so at 22.5 the gap between the two
## INNER EDGES opens from 119 mm to 155 mm and the face reads wall-eyed: the eyes stop being a pair.
## At yaw 20.0 the surface x is 0.09828 (s = 53.85, s^(-1/3.2) = 0.28773), centres 196.6 mm = 30.7 %
## of head width — mid-band — and the inner gap comes back to 128.6 mm, within 8 mm of what R4
## shipped.
##
## MEASURED AS RENDERED, because the style guide's band is on the rendered figure and the projection
## widens the geometric one. Connected-component pass over the near-black pixels in the portrait
## capture: two blobs 29 x 51 and 28 x 51 px, centres 94.6 px apart, on a head 277 px wide at the
## eye row. That is 34.2 % — inside the 28-35 % band, at its top, and 0.6 points BELOW where the R4
## build's geometry already sat before its own projection widened it further. As-rendered aspect is
## 1.76 : 1 and 1.82 : 1 against the 1.71 authored (the ellipse curves away at its sides, so the
## silhouette loses width before it loses height), still inside the 1.6-2.0 asked for. Eye width is
## 10.5 % of head width rendered against 10.6 % authored.
const EYE_YAW_A := 20.0
const EYE_PITCH_A := 3.0             ## vertical middle of the face
const EYE_W := 0.034                 ## half-width  ->  68 mm  = 10.6 % of head width
const EYE_H := 0.058                 ## half-height -> 116 mm  = 25.8 % of head height
const EYE_D := 0.016                 ## half-depth
## INSET IS POSITIVE, i.e. the eye node sits 6 mm INSIDE the shell, and it must stay that way.
## The oval's 16 mm half-depth then stands 10 mm proud at the centre while its zero-depth RIM is
## buried. Over the ellipse's 58 mm half-height this flat forehead only recedes 2.9 mm (solved on
## the shell: at x = 0.09828 the surface z goes from -0.26999 at the eye's own height to -0.26706
## at 58 mm up), so the rim is still 3.1 mm under the surface at the top and the bottom. Pushing the
## inset negative to seat the eye proud is the obvious "make it pop" move and it is wrong here: on a
## nearly flat forehead a proud tall ellipse shows a floating collar at its extremes, which is the
## exact failure the deleted iris solve was written to avoid.
const EYE_INSET := 0.006
## The "^ ^" and "O O" expression meshes are authored at chibi eye size, so they are fitted to THIS
## eye by hand. `fit_expr` is still not used — it normalises against the chibi constants, which is
## the wrong reference for a 116 mm ellipse.
##   HAPPY_FIT  the happy arc is `arc_tube(0.042, 0.0115, 24deg, 156deg)` = 99.8 mm wide at 1.0;
##              0.72 gives 72 mm against a 68 mm eye, a hair wider, which is what a smiling arc
##              closing over an eye should be.
##   ROUND_FIT  the surprise ball is authored 86 x 96 mm; (0.79, 0.81) gives 68 x 78 mm — so on
##              "surprised" the eye gets SHORTER and ROUNDER than it is at rest. That inversion is
##              the whole point: with a tall resting ellipse, a taller surprised one reads as
##              nothing, and the "O O" only lands if the shape actually changes kind.
## BOTH KEEP Z AT 1.0. The z of those nodes is their standoff from the shell plus their own solid
## depth; squashing it buries them. Checked: Round sits at eye-local z -0.002 with a 16 mm half-
## depth so its front is 12 mm proud of the shell, Happy at z -0.004 with an 11.5 mm tube radius
## (unscaled in z) so its front is 9.5 mm proud. Both clear.
const HAPPY_FIT := 0.72
const ROUND_FIT := Vector2(0.79, 0.81)

# ----------------------------------------------------------------------------------------- mouth
## R5 — JUST THE LINE. The R4 lip (a 33 mm `taper_tube` band standing 21 mm proud with a 9.6 mm dark
## seam laid on its crest, plus the `_arc_band` helper that built both) is deleted outright. What is
## left is the cast's own `_smile_arc` on the bare shell, at a thinner tube than the default.
##
## THE MOUTH NODE IS NOT RE-ORIENTED ANY MORE, and the old -18 override was dead weight even before
## this pass. Deleting `_build_lip` hands the mouth back to `_add_mouth`, which seats it at the cast
## MOUTH_PITCH of -20 with an effective inset of 0.002 (0.004 - _muzzle_lift 0 - 0.002). Solved on
## Zorp's shell that is y = -0.0969, which is 43.1 % of the way from the head's centre to its chin —
## proportionally LOWER than the same pitch gives a default chibi head (37.4 %), because Zorp's head
## is flat and 450 mm tall rather than 652. So -20 already lands where the local override was
## reaching for, and there is now one fewer number here that can drift away from the cast.
##
## R5.1 — THE LINE WENT DOWN, NOT UP, AND THE REAL BUG WAS NEVER THE THICKNESS. Read
## `_wound_outward` before touching this number; the short version is that `arc_tube` is wound
## inside-out against a `cull_back` shader, so what rendered was the tube's FAR wall — two hairline
## rims with lit skin between them — and RAISING the radius only pushed the two rims further apart.
## That is the whole "4-5 disconnected dark pixels, a dashed smudge" report: two ~1 px rims landing
## on the same pixel row or on neighbouring ones depending on where the head's bob put them.
##
## WITH THE WINDING FIXED THE TUBE DRAWS SOLID, so the number that used to buy nothing now buys the
## full band, and 0.0125 became a heavy bar. Rendered and read at --dist=1.4 and at --gameplay:
##   0.0125  25 mm  the previous value; now a confident bar, on the edge of reading as a lip
##   0.0110  22 mm  KEPT. 3.4 % of head width, 2.3 px at --gameplay (0.103 px/mm, solved off the
##                  eyes: 68 mm of eye measures 7 px and 116 mm measures 12 px in the same frame).
##                  Continuous in all four sampled frames and unmistakably a drawn line.
##   0.0095  19 mm  also continuous, but at 2.0 px it is one antialiasing step from breaking again
##                  and it buys nothing that 0.0110 does not.
## So this is now THINNER than the 25 mm the file shipped and less than half the cast's 28 mm, and
## it reads far heavier than either did — which is the answer to "just leave the line". Do NOT push
## it back up to compensate for anything, and do NOT bring back a coloured band: the band is what
## read as lipstick. Width is UNCHANGED from the cast: ring 0.102 swept +/-34 deg = 114 mm = 17.8 %
## of head width, inside the mandated 16-25 %.
##
## WHY z = -0.004 AND NOT THE CAST -0.002. The mouth node is 2 mm inside the shell, so at -0.002 the
## tube's CENTRELINE lands exactly on the surface and the near wall is half-buried. -0.004 puts it
## proud — solved on the shell at three points along the arc (theta 270 / 285 / 304) the centreline
## clears the surface by 2.7 / 2.5 / 2.4 mm, so every part of the 22 mm silhouette is in front of
## the face and nothing dives in at the corners. The shell recedes only 0.35 mm over the arc's
## 57 mm half-width, i.e. the face is effectively flat across the mouth.
##
## Clearance to the new taller eyes, checked because both moved this pass: the eye bottom sits at
## y = -0.0477 and the arc's corners (its highest points) at -0.0801, so 32 mm of clear face between
## them — and they are 54 mm apart horizontally in any case.
const MOUTH_TUBE_A := 0.0110
const MOUTH_LINE_Z := -0.004         ## negative is proud: `_orient_on_head` puts -Z along the normal

# ------------------------------------------------------------------------------------- tentacles
## SIX FACE TENTACLES, three a side, hanging down the lower cheek and past the jaw. This is the
## trait the user asked for two rounds ago; the antenna it replaces was Pip's as well as Zorp's.
##
## [yaw_deg, pitch_deg, splay_deg, front_deg, drop, base_r, tip_r], mirrored to both sides.
##   yaw/pitch    WHERE the strand is planted, solved on the head shell the same way the eyes are,
##                so the seats travel with `head_semi` / `head_n`.
##   splay/front  WHICH WAY it hangs — see `_hang_basis`. These exist because of a rebuild.
##   drop         its length. base_r/tip_r its thickness at each end.
##
## THE FIRST BUILD OF THIS WAS RENDERED AND THROWN AWAY, and both of its faults are worth writing
## down because they are not visible in source. It seated the strands under the jaw (pitch -30 to
## -18) at 135-185 mm and let `_orient_on_head`'s own basis aim them. On screen they were SHORT DARK
## DRIPS clinging to the jawline — they read as melted wax, not as limbs. Two separate causes:
##
##   1. NOT ENOUGH FREE LENGTH BELOW THE CHIN. Zorp's chin is at torso y 0.6713 and his head
##      overhangs, so a strand seated at y 0.74-0.80 spends most of itself hidden against the head.
##      Measured on that build, the length hanging in open air below the chin was 116 / 67 / 9 mm —
##      the third strand literally ended ABOVE the chin line and was never visible at all. It is
##      free length, not total length, that decides whether this reads. Now 191 / 150 / 65 mm.
##   2. THE SEAT'S OWN BASIS AIMS THEM WRONG. `_orient_on_head` ends in
##      `Basis.looking_at(outward, UP)`, whose local -Y at a DOWNWARD-facing seat tilts back under
##      the head — so the strands converged toward the midline as they fell and hung over the chest
##      like a bib. Solved: from a seat at yaw 38 pitch -26, the tip landed at x 0.159 against a
##      0.202 seat, i.e. 43 mm INBOARD of where it started.
##
## So the seat's basis is REPLACED (see `_build_tentacles`); `_orient_on_head` is used for the
## POSITION only. That is not the forbidden move — the rule is never to write `.rotation` on a node
## it has posed, because euler assignment rebuilds the basis and loses the outward AIM. Here the aim
## is exactly what is being replaced on purpose, and `position` is a separate field that survives.
##
## SEATS AND PATHS, solved on the shell against the final curl and then confirmed in the render
## (right side, torso space, mirrored to the left; "free" is the length hanging below the chin at
## torso y 0.6713, which is the only length that reads):
##   T0 yaw 36 pitch -21 -> seat (0.174, 0.785, -0.231), tip (0.238, 0.480, -0.302), 191 mm free
##   T1 yaw 54 pitch -18 -> seat (0.256, 0.794, -0.185), tip (0.324, 0.521, -0.227), 150 mm free
##   T2 yaw 72 pitch -15 -> seat (0.295, 0.812, -0.099), tip (0.352, 0.606, -0.119),  65 mm free
## Sampling the shell's implicit sum every 4 % of each path: the strand is BURIED for its first
## 12 / 12 / 21 % and outside the head for all of the rest, which is what makes the base emerge from
## the skin instead of resting on it.
##
## THE THREE GUARDS AGAINST A BEARD, which is the failure mode for anything hanging off a face —
## too many, too thin, too even:
##   COUNT.   Three a side, not five. The ask was three.
##   SPACING. 94 mm and 96 mm between seats against a 60 mm base diameter, so there is ~35 mm of
##            bare skin between neighbours and the eye counts three limbs rather than a fringe.
##   LENGTH.  Graded 320 / 285 / 215 mm. An even trio reads as a comb. The taper is 2.7 : 1
##            (30 mm base radius to 11 mm tip on T0) — a limb, not a rope. The bases went UP from
##            the thrown-away build's 25 mm: at the 7.4 m camera's 0.116 px/mm a 50 mm strand is
##            5.8 px and read as a string.
## If a render still says beard, the answer is FEWER AND THICKER. Do not add a fourth.
##
## CLEARANCE, solved against the arm as a capsule of r 0.055 from the shoulder at
## (0.212, 0.505, -0.012) over ARM_LEN 0.175 plus the 76 mm mitten, swept through the real pose
## envelope and INCLUDING the head rotation each of those poses applies (which is what actually
## brings a strand toward a raised arm). Tightest gap per strand, T0 / T1 / T2:
##   rest and walk   +200 / +164 / +132 mm          wave  +85 mm at worst, on T2
##   happy / dance   +110 /  +39 /  -28 mm
## Nothing touches the torso bean (closest approach 3.8x its own radius) or the scarf collar.
##
## THE -28 mm IS REAL AND IT IS A DELIBERATE TRADE. In `happy` and `dance` BOTH arms go to roll 2.72
## and sweep up alongside the head, and the back strand grazes the raised upper arm. Two things were
## tried and rejected: shortening T2 does not help at all, because the contact is up near its SEAT
## and not at its tip; and pulling T2 forward to yaw 62-66, which does clear it, closes the T1-T2
## seat gap from 96 mm to 47-69 mm and merges those two strands into exactly the fringe this block
## exists to prevent. Rendered `dance` at 3.2 m and at gameplay: the strands pass in FRONT of the
## raised arms and no interpenetration is visible, because they sit ~100 mm forward of the shoulder
## in z. Left as is, and called out in the report rather than hidden.
const TENT_SEATS := [
	[36.0, -21.0, 7.0, 48.0, 0.320, 0.030, 0.011],
	[54.0, -18.0, 6.0, 32.0, 0.285, 0.028, 0.010],
	[72.0, -15.0, 6.0, 20.0, 0.215, 0.026, 0.009],
]
## 16 mm into the shell, so each strand emerges FROM the skin rather than balancing on it. The base
## is 60 mm thick, so this buries about half a radius.
const TENT_INSET := 0.016
## Three nested joints. TENT_LEAN is the angle each joint sits at relative to its parent, TENT_CURL
## is the bend WITHIN one joint's tube, and the two are different tools:
##   * the leans are what `_animate_extras` swings, so they have to stay small enough that adding
##     0.03-0.09 rad of sway to them still looks like a limb bending and not a hinge popping;
##   * the curl is static geometry and is what stops each 107 mm section from being a straight rod.
## Joints 1 and 2 sit at the same angle as the curl on purpose: that is the tangent the previous
## tube ENDS at, so the strand is continuous in direction as well as in position, and the joints
## disappear. The first render of this had curl 0 and read as six jointed spider legs.
##
## Total bend from seat to tip is 0.06 + 3 x 0.08 = 0.30 rad, i.e. the tip hangs 17 deg off vertical
## and the strand's average direction over its length is 0.18 rad. The seat table's paths were
## re-solved against exactly this before it was written down — an earlier draft of the solver added
## the lean AND the curl at every joint and reported a 26 deg tip, which is the wrong number and
## would have flared the trio like a squid.
const TENT_JOINTS := 3
const TENT_LEAN := [0.06, 0.08, 0.08]
const TENT_CURL := 0.08
## Tube resolution. SIDES is the number that matters and it is the main reason these are built here
## instead of through `_add_tendril_ring`: the helper hard-codes `taper_tube(..., 4, 5)`, and after
## DETAIL 0.60 that 5 resolves to FOUR sides — a square rod. On the 22 mm barbel the helper was
## written for nobody sees it; on a 60 mm tentacle at portrait distance it is unmistakable, and the
## first render of this came back as six lavender chair legs with visible flat faces. 10 resolves to
## 6 sides, round enough to hold a highlight, and costs 288 triangles across all six strands (48 per
## joint against 32). Measured after: 5720 of 6000.
##
## SEGS 5 IS THE SAME 3 LENGTH SEGMENTS the helper gets from 4 — `_segs(4, 3)` and `_segs(5, 3)` are
## both 3 at DETAIL 0.60. It is written as 5 so that raising DETAIL for a beauty shot buys the curl
## some resolution before it buys the tube more sides, which is the order that helps here.
const TENT_SEGS := 5
const TENT_SIDES := 10

# ------------------------------------------------------------------------------------------ skin
## R4 SKIN — "Some should have smooth skin, but have big spots."
##
## `surface_scales` 0.0 is the whole first half of that. In sd_skin the scale term is the Voronoi
## CELL WALL, and it is what has been reading as "rocky texture skin with spots" on five characters
## at once; at 0.0 both its tint contribution and its roughness contribution drop out of the shader
## (the roughness gate matters — before R4 a character who asked for smooth skin still carried the
## full wall pattern in roughness, and toon_soft widens its spec lobe by roughness, so the walls
## came back as ghosts).
##
## The second half is size, and it is a two-number change because blob size is set by the LATTICE
## PITCH as well as by the radius. sd_skin runs at 7 cells per unit at `surface_scale` 1.0, so:
##   scale 1.60 (the old value) -> 89 mm cells -> at radius 0.36, ~65 mm speckles
##   scale 1.00 (now)           -> 143 mm cells -> at radius 0.74, blobs 159 mm across at half
##                                 amplitude and 211 mm at their full extent
## About 3.5 cells span the 640 mm head and the pick rate is 0.478, so roughly a third of him is
## blotch — dappled, not stained, and readable at the 7.4 m gameplay camera where the old speckle
## collapsed into noise.
##
## AMPLITUDE IS A PALETTE COST, measured not guessed: the tint MULTIPLIES the albedo, and darkening
## a colour RAISES its HSV saturation, so a strong pattern pushes straight at the R2.6 gate. The old
## setting was measured at +0.099 saturation mean for turning the pattern on. THIS one was measured
## the same way — one identical frame, one identical 200x160 head crop, `surface_strength` 0.0 vs
## 1.0 — and costs +0.028 (0.432 -> 0.460), with value mean moving -0.012 and blown highlights at
## 0.0 % either way. Two things bought that back: `surface_scales` 0.0 drops the cell walls, which
## were doing most of the darkening, and the R4 shader fix centres the spot term on zero
## (`surface_spot_dc` is DERIVED from the radius by `MaterialLib.spot_dc`, 0.3205 at 0.74), so the
## mean albedo is now unchanged and only the swing costs anything. At spot 1.25 and strength 1.0 the
## swing is a tint of 0.899 to 1.214 — 10 % down in the gaps, 21 % up in the blotches. The dominant
## swatch measures S 0.55, under the 0.60 gate. Re-measure if you raise either.
##
## The limbs need their own pitch: `objpos` is per-mesh, so a 152 mm mitten at the head's setting
## would carry one blob or none and the two hands would be identical. Scale 2.90 puts 49 mm cells on
## a mitten — two or three blotches each — which keeps the hands part of the same animal without
## pretending a hand is a head. Spots that stop at the jaw look like a mask.
const SURF_HEAD := {"surface": "skin", "surface_scale": 1.00, "surface_strength": 1.00,
	"surface_spot": 1.25, "surface_scales": 0.0, "surface_spot_radius": 0.74,
	"surface_near": 9.0, "surface_far": 26.0, "surface_macro": 0.10}
const SURF_LIMB := {"surface": "skin", "surface_scale": 2.90, "surface_strength": 0.95,
	"surface_spot": 1.15, "surface_scales": 0.0, "surface_spot_radius": 0.74,
	"surface_near": 7.0, "surface_far": 20.0}

## Every tentacle JOINT pivot, flat, in build order. `_build_tentacles` clears it — see the note
## there; `ChibiModel.rebuild()` has no idea this array exists.
var _tentacles: Array[Node3D] = []
var _glow_ring: MeshInstance3D
var _ring_mat: StandardMaterial3D
var _bob: float = 0.0
## A SEPARATE clock from `_bob`, and this is not tidiness — see `_animate_extras`.
var _sway: float = 0.0


func _init() -> void:
	super()
	hover_height = HOVER
	# THE EYE'S SIZE LIVES HERE AND NOWHERE ELSE. `_apply_face` rewrites `oval.scale` from
	# `_eye_size[i]` every single frame, and `_build_eye` fills `_eye_size` from the spec's w/h/d,
	# which default to these three — so the spec omits them, anything assigned to `oval.scale` by
	# hand is gone by frame 1, and this is the one place the number can be authored.
	#
	# Leaving them model-wide (rather than per-spec) also keeps `_build_eye`'s `expr` at exactly
	# (1, 1, 1), which is what the HAPPY_FIT / ROUND_FIT numbers are measured against.
	eye_w = EYE_W
	eye_h = EYE_H
	eye_d = EYE_D
	# A SMALL mouth. The wide grin is gone, so the open-mouth ellipse that drives talking shrinks
	# with it — 80 mm across at full open on a 640 mm head, against the 274 mm the grin needed.
	mouth_w = 0.044
	mouth_h = 0.030
	# R3.2 — HIS OWN HEAD, low and flat. Until now every organic neighbour shared ONE cached head
	# mesh, which is exactly why the user said it "still looks like it's just a reused head".
	#
	# 640 x 450 x 544 mm, against the shared 749 x 652 x 691. The height is what does the work: the
	# blank band between the top of the grin and the crown drops by about 40%, and the front surface
	# stops bulging — measured recession from the apex out to 60% / 80% of half-width falls from
	# 32 / 79 mm to about 12 / 40 mm. That flattening is the "flatten it out" the user asked for.
	#
	# EXPONENT: the design pass proposed n = 4.0, and two independent reviewers each built it and
	# rendered it — at 4.0 with this tessellation the head reads as a hard-edged faceted BOX, because
	# superellipsoid() samples a UV sphere's uniform angular directions while a high exponent packs
	# all the curvature into a narrow chamfer band. 3.2 keeps most of the flattening and still reads
	# as a blob. Do not raise it without also raising head_segs.
	head_semi = Vector3(0.3200, 0.2250, 0.2720)
	head_n = 3.2
	# Holds the chin exactly where it rendered before (0.945 - 0.3258 * 0.84 = 0.6713), so the scarf,
	# the torso and the hover are all untouched.
	head_y = 0.8963


func _build_geometry() -> void:
	_add_torso_bean(SHIRT, {"chamfer_color": SHIRT.darkened(0.20)})
	# hem: a band of bare skin under the tee so the bean still reads as a body. Superellipsoid, so
	# the tee ends on a hard horizontal edge instead of fading into another sphere.
	_mi(superellipsoid(Vector3(TORSO_RX * 0.93, TORSO_RY * 0.44, TORSO_RZ * 0.95), 2.9, 16, 8),
		_toon(SKIN, _matte({})), _torso, Vector3(0.0, TORSO_Y - 0.142, 0.0), "Hem")
	# chest motif, the way AC tees carry one — a flat chamfered badge with a bevelled rim, not the
	# six-ball star the first pass used (R2.3: "if a form can be described as a bunch of balls...").
	var emblem := _node("Emblem", _torso, Vector3(0.0, TORSO_Y + 0.012, -TORSO_RZ * 0.93))
	_mi(rounded_box(Vector3(0.108, 0.108, 0.020), 0.030, 12), _toon(SHIRT_TRIM, _matte({"rim": 0.03})),
		emblem, Vector3.ZERO, "Badge").rotation.z = PI * 0.25
	_mi(rounded_box(Vector3(0.062, 0.062, 0.022), 0.016, 10), _toon(SHIRT.darkened(0.22), _matte({})),
		emblem, Vector3(0.0, 0.0, -0.006), "Inlay").rotation.z = PI * 0.25
	_add_arms(SHIRT, SKIN, 3, SURF_LIMB)
	_add_legs(SKIN_DARK, FOOT, SURF_LIMB)
	_add_head_shell(SKIN, SURF_HEAD)

	# NO NOSE, NO BLUSH, NO BROWS. The first two are mammal cues on a creature that is meant not to
	# be one; the brows are the hard vocabulary Zorp is the control for. All three are BOOLEAN
	# switches — you cannot turn a face part off by passing it a transparent colour, because
	# `toon_soft` is opaque and an alpha-0 blush renders as two BLACK ovals on the cheeks. Three
	# files have hit that trap.
	_add_face(EYE, MOUTH, BLUSH, {
		"nose": false, "blush": false, "brows": false, "mouth_inner": MOUTH_INNER,
		"eyes": [_eye_spec(-1.0), _eye_spec(1.0)],
	})
	_fit_eyes()
	_thin_mouth()
	_build_scarf()
	_build_tentacles()
	_build_glow_ring()


# ================================================================================= eyes on the head
## The spec `_add_face` builds one eye from. NO `pos` KEY — that is the change that matters. R4
## passed one, which told `_build_eye` to place the eye outright, because the pupil belonged to a
## ball floating off the shell rather than to the shell. With the ball gone the eye is a shape ON
## the head again, so it is seated by `_orient_on_head` on the same superellipsoid
## `_add_head_shell` builds, and it travels with `head_semi` / `head_n` for free.
##
## No w/h/d either: those come from the model-wide `eye_w`/`eye_h`/`eye_d` set in `_init`, which is
## what holds `_build_eye`'s expression scaling at exactly 1.0.
func _eye_spec(sx: float) -> Dictionary:
	return {"yaw": EYE_YAW_A * sx, "pitch": EYE_PITCH_A, "inset": EYE_INSET}


## The three things about the ink ellipse the base class cannot know: it needs a denser mesh than a
## pupil does, its glint has to be re-authored against a non-uniform scale, and its expression
## meshes are authored at chibi size. Everything else about the eye is `_build_eye`'s.
func _fit_eyes() -> void:
	for i in _eye_ovals.size():
		var oval := _eye_ovals[i]
		# MESH DENSITY. `_eye_mesh("oval")` returns `sphere(1.0, 14, 8)`, which after DETAIL 0.60
		# resolves to 8 radial x 5 rings — roughly a 12-sided silhouette. That is invisible on the
		# 44 mm pupil it was chosen for, and visibly polygonal on a 116 mm ellipse: you can see flat
		# sides on the R4 sclera, which was smaller than this. 18/11 resolves to 11 x 7, a ~16-sided
		# outline. Swapping `.mesh` is safe — `_apply_face` only ever writes `.scale` and
		# `.visible` — and the Glint is a CHILD of the oval, so it survives the swap.
		oval.mesh = sphere(1.0, 18, 11)
		# THE GLINT IS THE ONLY THING SAYING "EYE" RATHER THAN "HOLE", now the sclera is gone, so it
		# is worth the seven lines. `_add_glint` parents a unit sphere to the oval at local
		# (0.36, 0.40, -0.52) scale (0.19, 0.15, 0.72) — and those are OVAL-LOCAL, so they inherit
		# the oval's non-uniform scale. Left alone on a 68 x 116 mm eye they come out as a
		# 12.9 x 17.4 mm vertical STREAK, which reads as a second, smaller eye highlight bar.
		# Re-authored to 13.6 x 13.3 mm — a round dot — 11.6 mm out and 26.7 mm up from the centre.
		# Checked: the ellipse's half-width at y = 26.7 mm is 30.2 mm and the dot spans 4.8-18.4 mm,
		# so it is comfortably inside the outline; and its front face lands 6.7 mm proud of the eye
		# surface at that point, so the eye cannot swallow it. Both eyes' glints sit on the SAME
		# side — a highlight comes from one light, and mirroring them reads as a squint.
		var glint := oval.get_node_or_null("Glint") as MeshInstance3D
		if glint != null:
			glint.position = GLINT_AT
			glint.scale = GLINT_R
		# X and Y only. Z is these nodes' standoff plus their own depth — see ROUND_FIT's note.
		_eye_happy[i].scale = Vector3(HAPPY_FIT, HAPPY_FIT, 1.0)
		_eye_round[i].scale = Vector3(ROUND_FIT.x, ROUND_FIT.y, 1.0)
		_glint_the_round_eye(_eye_round[i])


## A GLINT ON THE "O O" SURPRISE EYE, because without one --state=surprised is the one pose where
## Zorp goes back to being creepy — and creepy is the exact thing R5 was written to fix.
##
## WHAT GOES WRONG WITHOUT IT. `_apply_face` swaps expressions by VISIBILITY: it hides the Oval and
## shows `_eye_round`. The resting glint is a CHILD of the Oval, so it is hidden along with it, and
## `_build_eye` gives the Round node a bare solid Ball and no highlight of its own. On every other
## neighbour that is survivable — their resting eye is a small dark pupil on a pale sclera, so the
## surprise ball is a small dark mark on a face that still has whites in it. On Zorp there is no
## sclera left: the eye IS the ink, 68 x 78 mm of it, and with the glint gone the pose is two flat
## black holes. The critic's word for it was "creepy", which is the user's word from R5.
##
## THE FIX IS LOCAL. The clean place for it is `_build_eye`, which already knows the highlight
## material and could give the Round node a glint the same way it gives the Oval one, but
## chibi_model.gd is off limits this round; if it opens up, the fix there is one `_add_glint` call
## against the Ball's parent and this function goes away.
##
## PARENTED TO THE ROUND NODE, NOT TO THE BALL. The Ball carries the non-uniform scale that makes
## the ellipse (0.043 x 0.048 x d, i.e. 0.90 : 1), so a unit sphere hung off it comes out as a
## squashed dash rather than a dot — the same trap the resting glint's re-authoring above is about,
## and the reason `Round` (whose own 0.79 / 0.81 is nearly uniform) is the right parent. The 0.79 /
## 0.81 is then divided back out below so what lands on screen is a dot and not a 2.5 % ellipse.
##
## PLACED TO MATCH THE RESTING GLINT IN WORLD TERMS, not in fractions of its own eye: the highlight
## comes from one light, and a highlight that jumps when an expression changes reads as the eye
## having MOVED. Resting glint centre is (0.34, 0.46, -0.52) of the oval's (34, 58, 16) mm
## half-extents, i.e. (11.6, 26.7, -8.3) mm in the eye's frame; the Round node sits at
## (0, 3, -2) mm in that same frame, so the local offset is ((11.6 - 0) / 0.79,
## (26.7 - 3) / 0.81, (-8.3 + 2) / 1.0). Solved from the constants below rather than typed in, so
## it tracks EYE_W / EYE_H / EYE_D and ROUND_FIT if any of them move again.
##
## CHECKED AGAINST THE BALL IT SITS ON, because a highlight that clips out of its own eye or sinks
## into it is worse than none. In Round-local units the ball is an ellipsoid of radii
## (0.043, 0.048, 0.016) and the dot's centre lands at (0.0146, 0.0292, -0.0063) — normalised
## (0.34, 0.61), r^2 = 0.49, comfortably inside the outline, and even the corner of the dot's
## bounding box is at r^2 = 0.90. Depth: the ball's front surface at that point is at z = -0.0115
## and the dot's front face at -0.0178, so it stands 6.4 mm proud — within 0.3 mm of the 6.7 mm the
## resting glint stands proud of the resting eye, so it catches the same amount of light.
##
## `_eye_happy` DELIBERATELY GETS NOTHING. The "^ ^" arc is a 23 mm stroke, not a mass — there is no
## hole for a highlight to rescue — and a specular dot on an eye that is drawn CLOSED reads as an
## error rather than as life. NOT verified in a render, and it is worth saying so: --state=happy
## pitches the head far enough back that the lineup camera sees the underside of the chin and not
## the face at all, at 2.4 s, 3.2 s and 4.6 s. So this is an argument, not a measurement — if the
## happy pose is ever re-aimed and the arcs turn out to need life, the same helper works on
## `_eye_happy[i]` with HAPPY_FIT in place of ROUND_FIT.
const GLINT_AT := Vector3(0.34, 0.46, -0.52)   ## oval-local centre of the resting glint
const GLINT_R := Vector3(0.20, 0.115, 0.72)    ## oval-local radii of the resting glint

func _glint_the_round_eye(round_eye: Node3D) -> void:
	if round_eye.get_node_or_null("Glint") != null:
		return
	var fs := face_scale
	# The resting glint expressed in the EYE's frame: the oval sits at the eye's origin and carries
	# scale (eye_w * fs, eye_h * fs, eye_d), and GLINT_AT / GLINT_R are fractions of that.
	var eye_sz := Vector3(EYE_W * fs, EYE_H * fs, EYE_D)
	var centre := GLINT_AT * eye_sz
	var radii := GLINT_R * eye_sz
	var rs := Vector3(ROUND_FIT.x, ROUND_FIT.y, 1.0)
	var dot := _mi(sphere(1.0, 8, 4), _toon(GLINT, {"spec": 0.0, "rim": 0.0, "shade": 0.02}),
		round_eye, (centre - round_eye.position) / rs, "Glint")
	dot.scale = radii / rs


# ================================================================================ the closed smile
## Swaps the cast's default smile arc for a THINNER one at the same width and a little further
## proud of the shell — see the mouth block for both numbers. Nothing else about the mouth changes:
## `_mouth_open` (the ellipse plus interior plus tongue that drives talking) stays exactly where
## `_add_mouth` put it, so the talk / happy / surprised blend still runs untouched.
##
## THE RESULT MUST BE ASSIGNED TO `_mouth_smile`, not merely parented under the Mouth node.
## `_apply_face` fades this arc out as the mouth opens (SMILE_HIDE_AT), and it finds it through that
## member — a smile it does not hold stays drawn across the open mouth, which is the "two mouths,
## one thin one that talks and another big open one" bug written up on `_apply_face` itself.
func _thin_mouth() -> void:
	var mouth_node := _face.get_node_or_null("Mouth") as Node3D
	if mouth_node == null:
		return
	if _mouth_smile != null and is_instance_valid(_mouth_smile):
		# `remove_child` first, the way `_drop_eye` does it: `queue_free` alone runs at the END of
		# the frame, so the cast's own arc would be drawn on top of this one for frame 0.
		var old_parent := _mouth_smile.get_parent()
		if old_parent != null:
			old_parent.remove_child(_mouth_smile)
		_mouth_smile.queue_free()
	# `_smile_arc`'s own placement, reproduced here because the arc mesh has to be rebuilt before it
	# is handed over: the mesh's origin is the RING CENTRE, which `_smile_arc` seats at
	# y = ring_r * cos(MOUTH_HALF) so the arc's endpoints land on the mouth node's y = 0 and the
	# curve hangs down from there. Same numbers, same node name, same parent.
	var a0 := deg_to_rad(270.0 - MOUTH_HALF)
	var a1 := deg_to_rad(270.0 + MOUTH_HALF)
	var ring_y := MOUTH_ARC_R * cos(deg_to_rad(MOUTH_HALF))
	_mouth_smile = _mi(_wound_outward(arc_tube(MOUTH_ARC_R, MOUTH_TUBE_A, a0, a1, 14, 6)),
		_toon(MOUTH, {"spec": 0.0, "rim": 0.0, "shade": 0.06}),
		mouth_node, Vector3(0.0, ring_y, MOUTH_LINE_Z), "Smile")


## THE SAME ARC, WITH ITS TRIANGLES TURNED RIGHT WAY OUT. This is the fix for "the mouth is not a
## line, it is 4-5 disconnected dark pixels", and it is worth the whole block because the cause is
## invisible in source and three passes of tuning went at the wrong lever before it was found.
##
## WHAT WAS ACTUALLY ON SCREEN. `arc_tube` is documented in chibi_model.gd as being wound
## INSIDE-OUT ("Flipping these two triples is the whole fix; it was tried during integration and
## reverted"). The toon shader is `render_mode cull_back`, so on an inside-out tube the NEAR wall
## is culled and what draws is the FAR wall — the inside of the back of the tube — seen through the
## hole where the near wall should have been. The far wall is buried in the head for everything
## except a narrow strip at each rim, so a 25 mm tube rendered as TWO ~1 px outlines with bare skin
## between them, not as a 25 mm band.
##
## MEASURED, at --dist=1.4 where the head is 290 px wide (0.453 px/mm): with MOUTH_TUBE_A at
## 0.0220 the mouth drew as two separate arcs 20 px apart — exactly the tube's 44 mm diameter —
## with lit skin in the gap. With the winding turned out, the same frame draws one solid band.
## AND AT --gameplay, per column of the arc's span, ink coverage against the local skin, four
## sampled frames each (the head bobs, so one frame proves nothing):
##   before  3, 5, 7 and 9 of ~29 columns inked; longest unbroken run 2, 2, 2, 4 px
##   after   15, 15, 16, 16 of ~29 columns inked at 100 %; longest run 15, 15, 16, 16 — i.e. the
##           whole span, with no interior column below full ink, in every frame. That is also why the previous pass's "raise MOUTH_TUBE_A" did not
## help: raising the radius does not thicken the line, it drives the two rims FURTHER APART, and
## at --gameplay the two 1 px rims land on the same pixel row or on neighbouring ones depending on
## where the head's bob puts them that frame. A stroke that breaks in and out along its length is
## precisely what a pair of hairline rims does.
##
## WHY NOT THE OBVIOUS FIXES.
##   * chibi_model.gd's `arc_tube` is off limits this round, and flipping it there would silently
##     change every brow, every "^ ^" happy eye and every other neighbour's smile at once.
##   * A negative scale (`Vector3(1, 1, -1)`) on the mesh instance was built and rendered first. It
##     is a no-op: Godot flips the front-face direction for a negative-determinant transform so
##     that mirrored meshes do not turn inside out, so the cull flips back. Measured identical to
##     no change at all (inked columns 13.0 vs 12.5, longest run 8.2 vs 8.2 — inside the noise).
##   * The shader's cull mode is baked into `render_mode`, so there is no per-material override.
## Rebuilding the index buffer is what is left, and it is cheap and completely local.
##
## THE SOURCE MESH IS SHARED AND MUST NOT BE TOUCHED. `arc_tube` hands back a cached ArrayMesh that
## other characters are already using; `surface_get_arrays` copies, so a fresh ArrayMesh built from
## the copy leaves the cache alone. Vertex positions, normals and UVs are carried over untouched —
## `arc_tube` already sets correct OUTWARD normals, so only the winding was ever wrong, and shading
## is bit-for-bit what it was.
static func _wound_outward(src: ArrayMesh) -> ArrayMesh:
	var arr: Array = src.surface_get_arrays(0)
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var flipped := PackedInt32Array()
	flipped.resize(idx.size())
	@warning_ignore("integer_division")
	var tris := idx.size() / 3
	for t in tris:
		flipped[t * 3] = idx[t * 3]
		flipped[t * 3 + 1] = idx[t * 3 + 2]
		flipped[t * 3 + 2] = idx[t * 3 + 1]
	arr[Mesh.ARRAY_INDEX] = flipped
	var out := ArrayMesh.new()
	out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return out


# ==================================================================================== the tentacles
## Three strands a side, built joint by joint here rather than through `_add_tendril_ring`.
##
## USING THE HELPER WAS TRIED FIRST AND RENDERED. It is the right shape of thing — nested joints,
## a tapering tube per joint, animation metas on every pivot — and this function keeps its whole
## structure and its meta contract deliberately, so `_animate_extras` is the same single loop it
## would have been. Three things forced the copy, and none of them are style:
##   1. SIDES. The helper hard-codes `taper_tube(..., 4, 5)` and there is no argument for it. See
##      TENT_SIDES: four sides is a square rod at this thickness, and it rendered as one.
##   2. CURL. The helper passes curl 0, so each joint is dead straight and the only bend is at the
##      hinges. See TENT_CURL.
##   3. ONE DROP PER CALL. Every strand in a call shares a `drop`, and graded lengths are the main
##      thing keeping this off a beard — so it would have been six calls of `count = 1` regardless,
##      which also means the helper's per-strand phase spread (derived from the index WITHIN a call)
##      would have come out identical for all six and marched them in lockstep.
## chibi_model.gd is off limits this round; if it opens up, the clean fix is `sides`, `segs` and
## `curl` arguments on `_add_tendril_ring` plus a phase seed, and this function goes away.
##
## THE SEAT'S BASIS IS REPLACED OUTRIGHT, and only the basis — see the tentacle constants for why
## `_orient_on_head`'s outward-facing frame hangs these wrong. `seat.position` is written by
## `_orient_on_head` and left alone, so the strand stays exactly on the shell. What is forbidden and
## still forbidden is writing `seat.rotation` (euler) on a part that has to keep FACING outward —
## an eye, the mouth — and the sway therefore writes to the joint pivots below, which are seated by
## euler, never to these seats.
func _build_tentacles() -> void:
	# LOAD-BEARING. `ChibiModel.rebuild()` frees every child and clears its own five eye arrays and
	# `_brows`, but it knows nothing about this one. Without the clear, a second `rebuild()` leaves
	# six freed Node3Ds in the array and `_animate_extras` calls `get_meta` on a freed node on the
	# very next tick. twin_model.gd clears `_antennae` at the top of its own `_build_geometry` for
	# the same reason.
	_tentacles.clear()
	# SKIN_DARK, NOT SKIN, and carrying SURF_LIMB. Two reasons:
	#   1. This file's rule is that spots which stop at the jaw look like a mask, so the strands have
	#      to be spotted like the rest of him. SURF_LIMB's 2.90 scale puts 49 mm cells on a 60 mm
	#      strand — two to four blotches each, the same pitch the mittens and legs run at.
	#   2. SKIN_DARK because the top third of every strand is seen AGAINST the head, and a same-value
	#      limb on a same-value head is one silhouette rather than seven. It is a single value step
	#      down and is already the legs' colour, so it is not a new number in the palette.
	var m_tent := _toon(SKIN_DARK, _matte(SURF_LIMB))
	var strand := 0
	for sx: float in [-1.0, 1.0]:
		for i in TENT_SEATS.size():
			var t: Array = TENT_SEATS[i]
			var seat := _node("Tentacle%s%d" % ["L" if sx < 0.0 else "R", i], _head, Vector3.ZERO)
			_orient_on_head(seat, float(t[0]) * sx, float(t[1]), TENT_INSET)
			seat.basis = _hang_basis(sx, float(t[2]), float(t[3]))
			_build_strand(seat, m_tent, float(t[4]), float(t[5]), float(t[6]), strand)
			strand += 1


## ONE hanging strand of TENT_JOINTS nested pivots under `seat`, tapering `r0` to `r1` over `drop`.
##
## The mesh is turned over in place (`rotation.x = PI`) because `taper_tube` grows along its own +Y
## and a tentacle hangs — the same trick `_add_tendril_ring` uses. That flip also sends the tube's
## bend direction, its own +Z, to the pivot's -Z, which is the OUTWARD direction `_hang_basis` set.
## So a positive TENT_CURL bends the strand away from the head, which is the way it should fall.
##
## THE CHILD PIVOT SITS AT `taper_tube_end`, NOT AT (0, -seg, 0). With curl 0 those are the same
## point and the helper can get away with the constant; with curl they are 4 mm apart per joint and
## the strand would show a visible step at every hinge. `taper_tube_end` reports the end of the very
## path `taper_tube` builds, so the two cannot drift apart, and the same PI flip is applied to it.
func _build_strand(seat: Node3D, mat: Material, drop: float, r0: float, r1: float, idx: int) -> void:
	var seg_drop := drop / float(TENT_JOINTS)
	var tip: Vector3 = taper_tube_end(seg_drop, TENT_CURL, TENT_SEGS)
	var step := Vector3(tip.x, -tip.y, -tip.z)      ## the mesh's PI flip, applied to the join point
	var cursor := seat
	for j in TENT_JOINTS:
		var t0 := float(j) / float(TENT_JOINTS)
		var t1 := float(j + 1) / float(TENT_JOINTS)
		var node := _node("Joint%d" % j, cursor, Vector3.ZERO if j == 0 else step)
		node.rotation.x = float(TENT_LEAN[mini(j, TENT_LEAN.size() - 1)])
		_mi(taper_tube(seg_drop, lerpf(r0, r1, t0), lerpf(r0, r1, t1), TENT_CURL,
			TENT_SEGS, TENT_SIDES), mat, node, Vector3.ZERO, "Seg").rotation.x = PI
		# The animation contract, copied from `_add_tendril_ring` so `_animate_extras` stays a plain
		# loop. "period"/"phase" are seeded from the GLOBAL strand index, which is the whole reason
		# they are re-derived: the helper seeds them from the index within one call, and with one
		# strand per call all six would have shared a clock and swayed in lockstep. "rest_x"/"rest_z"
		# must record the pose actually built — a rest_x that disagrees snaps the strand on frame 1.
		node.set_meta("joint", j)
		node.set_meta("period", 1.45 + 0.19 * float(idx) + 0.23 * float(j))
		node.set_meta("phase", fmod(0.618 * float(idx) + 0.317 * float(j), 1.0))
		node.set_meta("rest_x", node.rotation.x)
		node.set_meta("rest_z", node.rotation.z)
		_tentacles.append(node)
		cursor = node


## THE FRAME A STRAND HANGS IN, built in head-local space so it owes nothing to the shell's normal
## at the seat. Two angles, both in degrees:
##   splay  how far off straight-down the strand leans, toward `front`. Small — 5-7 deg — because
##          TENT_LEAN and TENT_CURL add another 17 deg of flare on top of it by the tip.
##   front  the AZIMUTH of that lean in the head's XZ plane: 0 is straight out to the side, 90 is
##          straight forward. So the front strand (48) falls forward and out across the cheek and
##          the back one (20) falls almost straight down the flank. Grading it is what stops the
##          trio from looking like one fan.
##
## The basis is built rather than eulered because the two angles are a direction, not a rotation
## order: -Y is the hang, and -Z is the outward direction the nested joint leans then follow (the
## helper's joints pitch about local X, which tips them toward local -Z). `xb = yb.cross(zb)` keeps
## it right-handed — the same identity Basis.IDENTITY satisfies.
func _hang_basis(sx: float, splay_deg: float, front_deg: float) -> Basis:
	var outv := Vector3(sx * cos(deg_to_rad(front_deg)), 0.0, -sin(deg_to_rad(front_deg))).normalized()
	var s := deg_to_rad(splay_deg)
	var yb := -(Vector3.DOWN * cos(s) + outv * sin(s)).normalized()
	var zb := -(outv - yb * outv.dot(yb)).normalized()
	return Basis(yb.cross(zb), yb, zb)


## Striped space-scarf where a neck would be (there is none — it sits on the shoulders).
func _build_scarf() -> void:
	var m_a := _toon(SCARF_A, _matte({"spec": 0.03}))
	var m_b := _toon(SCARF_B, _matte({"spec": 0.03}))
	var scarf := _node("Scarf", _torso, Vector3(0.0, TORSO_Y + TORSO_RY * 0.74, 0.0))
	# one collar with a flat top face and a chamfered edge, wrapped by thin stripes: fabric with a
	# fold in it, not a stack of donuts
	_mi(superellipsoid(Vector3(0.176, 0.076, 0.160), 3.0, 14, 8), m_a, scarf, Vector3(0.0, -0.012, 0.0), "Collar")
	for i in 3:
		var stripe := _mi(torus(0.150, 0.188, 18, 5), m_b, scarf, Vector3(0.0, 0.012 - 0.034 * i, 0.0), "Stripe")
		stripe.scale = Vector3(0.99 - 0.05 * i, 0.30, 0.90 - 0.05 * i)
	# a short tail hanging over the left shoulder
	var tail := _node("Tail", scarf, Vector3(-0.115, -0.048, -0.115))
	tail.rotation = Vector3(-0.22, 0.30, 0.30)
	for i in 3:
		var seg := _mi(rounded_box(Vector3(0.075, 0.052, 0.032), 0.016, 10), m_b if i % 2 == 0 else m_a, tail, Vector3(0.008 * i, -0.05 * i, 0.0), "Seg")
		seg.rotation.z = 0.06 * i


func _build_glow_ring() -> void:
	var q := QuadMesh.new()
	q.size = Vector2(0.72, 0.72)
	q.orientation = PlaneMesh.FACE_Y
	_glow_ring = MeshInstance3D.new()
	_glow_ring.name = "HoverGlow"
	_glow_ring.mesh = q
	_ring_mat = StandardMaterial3D.new()
	_ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ring_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_ring_mat.albedo_color = Color(BULB.r, BULB.g, BULB.b, 0.30)
	_ring_mat.albedo_texture = soft_dot_texture()
	_ring_mat.disable_receive_shadows = true
	_glow_ring.material_override = _ring_mat
	_glow_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_glow_ring.position = Vector3(0.0, 0.012, 0.0)
	add_child(_glow_ring)


func _animate_extras(delta: float) -> void:
	_bob += delta
	# soft hover bob (the whole model floats; the glow ring stays on the ground)
	_root.position.y = hover_height + sin(TAU * _bob / 2.6) * 0.022
	# The EXTRA_A channel keeps exactly the meaning the antenna gave it — "think" drives droop to 1,
	# "talk" drives perk to 1, idle breathes it +/-0.05 — it just drives six strands now instead of
	# one stalk. droop cuts each joint's resting lean to 40 % (0.06 -> 0.024, 0.08 -> 0.032), so the
	# strands straighten and hang limp; perk adds up to 0.33 rad of cumulative outward flare and
	# speeds the sway 55 %, so they lift and spread while he talks.
	var droop := clampf(-pose(P.EXTRA_A), 0.0, 1.0)
	var perk := clampf(pose(P.EXTRA_A), 0.0, 1.0)
	# A SEPARATE ACCUMULATOR, NOT `_bob`, and this is not a style choice. `perk` multiplies the sway
	# RATE, and multiplying a rate into an absolute clock jumps the PHASE the instant perk blends in
	# — the tentacles would snap sideways at the start of every talk. Integrating the rate keeps the
	# phase continuous through the blend. `_bob` stays on its own clock because the hover and the
	# glow ring are not rate-modulated.
	_sway += delta * (1.0 + 0.55 * perk)
	for t: Node3D in _tentacles:
		# AMPLITUDE GROWS DOWN THE STRAND because the joints are NESTED — the helper's docstring is
		# explicit that this is the difference between a tentacle that whips and one that shears.
		# k = 1/2/3 gives 0.030 / 0.060 / 0.090 rad of pitch sway summing to 0.18 rad at the tip.
		# On the 320 mm front strand each joint's share moves the length hanging below it by about
		# 10 / 13 / 10 mm, so the tip travels ~32 mm off centre over a 1.45-2.4 s period — a slow
		# lean, roughly a tenth of the strand's own length. The lateral drift runs on a different
		# multiple of the same clock (0.71, offset 1.4) so no two joints and no two strands are ever
		# in lockstep. Gentle idle sway, not a wag.
		var k := float(int(t.get_meta("joint", 0))) + 1.0
		var per := maxf(float(t.get_meta("period", 1.6)), 0.2)
		var w := TAU * (_sway / per + float(t.get_meta("phase", 0.0)))
		# Writing `rotation` on these is SAFE: `_build_strand` seats every joint pivot by euler, and
		# records that pose in "rest_x"/"rest_z". The SEAT above them carries a BASIS and must never
		# be written to here — euler assignment would rebuild it and throw the hang direction away.
		t.rotation.x = float(t.get_meta("rest_x", 0.0)) * (1.0 - 0.60 * droop) \
			+ 0.030 * k * sin(w) + 0.055 * k * perk
		t.rotation.z = float(t.get_meta("rest_z", 0.0)) + 0.026 * k * sin(w * 0.71 + 1.4)
	if _ring_mat:
		var a := 0.24 + 0.10 * sin(TAU * _bob / 2.6 + 1.2)
		_ring_mat.albedo_color = Color(BULB.r, BULB.g, BULB.b, a)


## Small radial falloff texture used for the hover glow (shared, generated once).
static var _dot_tex: ImageTexture

static func soft_dot_texture() -> ImageTexture:
	if _dot_tex:
		return _dot_tex
	var n := 48
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var u := (float(x) + 0.5) / n * 2.0 - 1.0
			var v := (float(y) + 0.5) / n * 2.0 - 1.0
			var d := sqrt(u * u + v * v)
			var a := clampf(1.0 - smoothstep(0.15, 1.0, d), 0.0, 1.0)
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, a * a))
	_dot_tex = ImageTexture.create_from_image(img)
	return _dot_tex
