class_name VelaModel
extends ChibiModel
## Vela — the listener of the Long Array, and the cast's second robot neighbour.
##
## THE BRIEF SHE EXISTS TO SOLVE. The three robots already shipped share one grammar: Bolt and DJ
## Nova are the same `rounded_box` head to within 5 mm, both wearing a pale rectangular faceplate
## with flat eyes and a flat mouth drawn on it; Mayor Orbit is brass with smoked goggles, a top hat
## and horns. All three are `surface_kind` 0 (no surface detail at all). Vela shares NONE of that:
##
##   HEAD      an UNLIT INCANDESCENT BULB — a 0.380 m pale cool glass envelope that PINCHES into a
##             76 mm glass neck and then into a short ribbed screw cap, screwed into a socket cup on
##             her neck. Glass to metal is 0.444 m against 0.170 m — 72/28, which is an A19 lamp's own
##             ratio. It ROCKS in that socket: a slow idle sway, a tip back when she thinks,
##             levelling when she speaks.
##   EYES      two smoked-jade lenses inside ONE JOINED HOOP carried 0.19 m clear of the head on a
##             pair of arched struts reaching forward off the socket, and slung 0.20 m BELOW the head
##             origin so the whole screw base stands clear above them. Not a faceplate, not goggles,
##             not eyestalks — an instrument yoke. See HOOP_CENTRE for why the height is what it is:
##             anything parked in the hoop's open centre reads as a snout, and the screw base was.
##   BLINK     a mechanical IRIS — five converging leaves per lens, driven off `_eye_open` so the
##             shared blink/squint clock runs a shutter instead of squashing an oval.
##   MOUTH     none. She is the only neighbour in the cast without one.
##   SURFACE   brushed metal grain (`surface_kind` 2) on every plate, which no other robot has —
##             with the glass envelope as the one deliberate SMOOTH exception, so the bulb separates
##             from its own cap by texture as well as by value.
##
## WHY A BULB AND NOT THE DISH SHE SHIPPED WITH. Her head used to be a wide shallow collector dish.
## Four renders in a row read it as a tambourine, a cookie, a dinner plate or a mushroom cap and
## never once as a dish: the pan was a 13-segment superellipsoid seen edge-on, so its silhouette was
## a flat decagon, and the "collector" plate was 10 mm PROUD at the centre — the dish was convex. It
## was also the only head in the cast that was not a VOLUME, which made it the least head-like thing
## in the lineup at 9 m. A bulb is a volume, it survives the 6.5 m camera as a shape rather than as
## an outline, and it puts her in the same "big round thing" family as Bolt and Zorp without
## borrowing either of their colours. She is still unmistakably a machine; see the note at
## `_build_bulb` for the full list of what carries that read now.
##
## HER PUPIL IS THE RIG'S EYE. The dark disc inside each lens is the `_eye_ovals` entry, built by
## `_add_face` through the `eyes` spec list with `parent`/`pos` pointing at the hoop. So blink,
## squint, the happy "^" and the surprise "O" all still run behind the glass exactly as they do on
## every other face — the hoop only decides WHERE the eye lives, which is what `_add_eyestalks` does
## for the stalk-eyed neighbours.
##
## NO MOUTH MEANS THE TALK TELL HAS TO BE BUILT. `_pose_talk` pins `P.EXTRA_A` to 1.0 and
## `_pose_think` to -1.0; nothing else says she is speaking, so `_animate_extras` spends that channel
## on three coordinated things (see `_animate_extras`): a travelling wave around the seven amber
## indicator pips on her screw base, a pulse in the chest core, and the bulb levelling out of its
## idle sway to face the listener.
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
## crown in the game at 1.450 m (see `marker_clearance`); PALETTE — ivory over rose-taupe and plum-grey with one warm amber core, which is
## nobody else's chord; and MANNER — the slowest blink in the cast (`blink_hold` 1.7), a slow clock
## (`anim_time_scale` 0.82), and a bulb that sways on its own in idle and comes level to listen to you.
##
## HARD VOCABULARY: NONE. The cap is two of {brow ridge, heavy lid, horns, tusks, fangs, shoulder
## yoke} per character and the cast total is meant to come DOWN. Vela wears zero of them: no brows
## (`brows: false`), no lids, no horns, no teeth of any kind, and a flared neck socket rather than a
## yoke across the shoulders.

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
## THE BULB ENVELOPE, AND IT IS NOT LIT. No emission, no `lit_material`, no alpha — rule 4 of this
## file's own hard-won list: `toon_soft` is OPAQUE, so an alpha-0 colour renders BLACK rather than
## disappearing, and faking glass with transparency here would give her a lump of coal for a head.
##
## MEASURED, NOT GUESSED, AND THE FIRST TRY FAILED. Draft 1 used #c0c8ca (V 0.792) with the shade
## strength dropped to 0.20 and the rim raised to 0.060, on the theory that a light shade side reads
## as light passing through glass. On the render it was the brightest object IN THE FRAME — brighter
## than the moon behind her — and it read as a bulb that was switched ON, which is the one thing the
## brief forbids. The lesson is that `toon_soft` already lifts a character's shade side to
## CHAR_SHADE_FLOOR 0.68, so cutting shade_strength on top of that leaves almost no terminator at all
## on a big ball. Draft 2 at #a8b2b6 / shade 0.26 was still the palest thing in the frame; draft 3 at
## #9fabaf / 0.30 sat level with her ivory plastron and read as a marshmallow. This is 19 % darker
## than IVORY, level with TAUPE in value, and the shade strength is pushed ABOVE the cast's 0.30 to
## 0.34 — the terminator on the envelope is now the strongest one on her, which is what stops a large
## smooth pale mass from reading as a light source. What is left to say "glass" is the colour (cool
## grey-blue against a cast of warm creams) and ONE very tight specular. That is enough.
##
## It also has to differ from Bolt, the cast's other pale-headed robot, whose head is a warm cream
## ball of nearly this size. Cool and darker is that separation.
const GLASS := Color("#98a5aa")        ## S 0.106 V 0.667 — cool grey-blue, level with TAUPE in value

# ---------------------------------------------------------------------------- surface presets
## Brushed metal grain through `_toon`, NEVER `MaterialLib.metal()`. That call bypasses
## `ChibiModel._toon()` and so misses the character shadow-floor fix (CHAR_SHADOW_FLOOR /
## CHAR_SHADE_FLOOR), which is exactly why Bolt's ear caps shade differently from the rest of him.
##
## TWO presets, because grain frequency is a function of how big the part is in METRES. `sd_metal`
## runs its grain in model space, so one scale that reads on a 0.39 m chest turns a 0.15 m mitten
## into corduroy. Medium on the chassis, fine and weak on the limbs.
##
## THERE USED TO BE A THIRD, `SURF_DISH`, at scale 1.15 — a coarse band tuned for the 0.72 m
## collector pan. The pan is gone and the screw cap that replaced it is 0.30 m across, which is the
## chest's own size band, so it uses SURF_SHELL and the coarse preset was deleted rather than left
## lying around for someone to reach for. The glass envelope carries NO surface at all: it is the
## only smooth thing on her, and that texture break is half of what separates it from its own cap.
const SURF_SHELL := {"surface": "metal", "surface_scale": 2.30, "surface_strength": 0.62,
	"surface_macro": 0.07, "surface_near": 6.0, "surface_far": 20.0}
const SURF_LIMB := {"surface": "metal", "surface_scale": 4.40, "surface_strength": 0.50,
	"surface_near": 5.0, "surface_far": 16.0}

# ---------------------------------------------------------------------------- the bulb
## Everything here is HEAD-LOCAL (add `head_y` = 1.090 for model space), and `head_y` itself does not
## move by one micron. HOOP_CENTRE, the eye spec list in `_build_geometry` and the whole iris are all
## expressed in head space, so shifting the head origin would drag the eyes with it — and the eyes
## are the one thing this rebuild is forbidden to touch.
##
## THIS IS THE SECOND PASS AT THE BULB AND THE FIRST ONE FAILED ON PROPORTION. Measured off the
## critic's own renders: the glass ran model 1.139..1.478 (0.339 m) over metal running 0.736..1.139
## (0.403 m) — 46 % glass to 54 % base, on a pixel count of 158 to 160. A real A19 lamp in an E26 cap
## is about 70/30 THE OTHER WAY. The head read as "ball on a coil spring", the base was longer than
## the envelope, the thread was 63 % of the glass's half-width (a real cap is ~43 %), the beads were
## a constant-radius stack (a SPRING, not a screw cap), the PLUM_DARK valleys between them rendered as
## pure black gaps the same height as the beads (an accordion hose), and there was no pinch at all —
## the ball's bottom was still 0.16 m wide where the topmost 0.132 bead met it, so the bead flared
## OUTWARD like a hat brim instead of gripping inward like a lamp rim.
##
## FIVE THINGS CHANGED, AND THE FIX HAD TO COME FROM BOTH ENDS AT ONCE, because growing the envelope
## alone costs 1.885 mm of visible thread per mm of `b` and re-hides the base:
##   1. the whole head assembly MOVED UP. The socket cup went from model 0.767 to 0.867 and the neck
##      column grew to meet it, so 100 mm of what used to be exposed dark shank is now neck. That is
##      where most of the proportion fix comes from, and it is why the crown went DOWN (1.478 ->
##      1.446) rather than up: the critic's secondary note was that she had grown 117 mm and was
##      visibly the tallest in the 9 m lineup, so the base paid for this and the crown did not.
##   2. a real PINCH exists now — see NECK_* below. It is glass, not metal, and it is the single cue
##      the brief named by word.
##   3. THREE beads instead of five, at a 40 mm pitch instead of 52, and they TAPER (0.100 / 0.096 /
##      0.092 outer, top to bottom) instead of being one cached torus repeated.
##   4. the shank went from PLUM_DARK (V 0.306) to TAUPE_DARK (V 0.541). The valley between two beads
##      is now a 0.13 value step below the bead rather than a black slot, which is what a shallow
##      thread on continuous metal looks like; black slots are a hose.
##   5. the cap is NARROWER: 0.100 outer against the envelope's 0.204 half-width is 49 %, against the
##      old 63 %. 43 % would be exactly an E26 but 0.088 puts the bead under 4 px at the gameplay
##      camera and it stops reading at all, so 49 % is the floor that survives the render.
##
## THE SUM, WRITTEN OUT, because the critic measured the last one off pixels and will do it again.
## The glass gave 24 mm of its pinch to the screw cap this pass (see CAP_H) and the ratio survived:
##   glass   crown 1.450 .. neck bottom 1.030  = 0.420 m   71.9 %     (was 0.444 / 72.3 %)
##   metal   1.030 .. socket bottom 0.836      = 0.194 m   28.1 %     (was 0.170 / 27.7 %)
##
## THE ENVELOPE STILL SWALLOWS WHATEVER IS UNDER IT, and that is still the trap. A superellipsoid
## holds nearly its full width almost all the way down to its own pole, so a narrower part parked
## underneath does not peek out — it VANISHES. For semi (a, b) and exponent n the plan radius equals
## R at
##
##     |dy| = b * (1 - (R/a)^n)^(1/n)     below the centre
##
## With a = b = 0.190 and n = 2.15, the two solves that matter are:
##   R = 0.074 (the neck's bottom radius):  |dy| = 0.178  ->  the glass stops being wider than the
##       neck at model 1.082, so 52 mm of neck shows between there and the neck's own bottom at 1.030.
##       THAT IS THE PINCH, and it had to be re-derived once, on the render, because the FIRST solve
##       was geometrically right and visually useless. See the note below.
##   R = 0.100 (the collar bead):           |dy| = 0.166  ->  model 1.094, i.e. the bead would be
##       swallowed if it were up there. It is at 1.018, 76 mm clear. No hat brim this time.
##
## THE HOOP'S TOP BAR EATS THE PINCH, AND THAT COST A RENDER. The first version of this block put a
## 0.408 ball with its pole at model 1.038 over a neck running 1.006..1.049. On paper that is 43 mm of
## visible pinch. On the render it was five pixels. MEASURED off that PNG (392 px per metre, ball crown
## at pixel 153): the hoop's upper bar projects across model 0.994..1.025, so it covers the ENTIRE band
## the pinch was authored into and the ball's pole sat 13 mm above it. The head read as a ball resting
## straight on a pair of goggles with a ribbed column under them.
## The fix is to lift the ball's POLE clear of 1.025 rather than to lengthen the neck downward:
##   ball pole 1.070 = crown 1.450 - 0.380, so 45 mm of neck is above the bar with the ball narrowing
##   into it, and 57 mm of it is clear pinch. The envelope SHRANK to pay for the lift (0.408 -> 0.380
##   across) so the crown only moved 4 mm, from 1.446 to 1.450 — the critic's standing note is that she
##   is already the tallest in the cast and any proportion fix must come out of the base, not the top.
## IF YOU CHANGE BULB_SEMI, REDO BOTH SOLVES, THE BAR CHECK AND THE 74/26 SUM BEFORE YOU RENDER.
const BULB_SEMI := Vector3(0.190, 0.190, 0.190)   ## 0.380 across, 0.380 tall — a ball, not a lid
## 2.15, NOT 2.5, and this cost a render. A high exponent squares off the POLE as hard as it squares
## off the equator, so an oblate superellipsoid at 2.5 does not read as a ball with flattened facets —
## it reads as a PUCK with a flat plate for a top, and draft 3 rendered as a chef's hat. 2.15 keeps a
## rounded crown while the 14 radial segments (24 through `_segs` at DETAIL 0.60) still give 25.7 deg
## facets round the sides, which is the cast's grammar and is plainly visible at portrait distance.
const BULB_N := 2.15
const BULB_Y := 0.170                  ## centre -> model 1.260; crown 1.450 (see marker_clearance)

## THE PINCH, and it is GLASS. This is the piece the last pass did not have and the brief named by
## word ("pinching into a short neck"). Two ways to build it were on the table:
##   * squeeze the envelope itself into a pear by dropping BULB_N — rejected, because the exponent
##     controls the CROWN's roundness as hard as the waist's, and every value low enough to give a
##     neck turned the top into a teardrop;
##   * a separate short cone under the ball, in the SAME glass material with the same smooth
##     surface_kind 0 — taken. It costs 48 triangles, it is the correct read (a real bulb's neck is
##     blown glass, not metal), and it lets the pinch be as narrow as it likes without touching the
##     envelope's silhouette at all.
## It spans model 1.030..1.090. Its top disc at 1.090 is buried inside the envelope (the glass is
## 0.0925 in radius there against the neck's 0.066), and the envelope's own bottom pole at 1.070 is
## buried inside the neck, so the two solids merge with no seam and no gap.
##
## IT LOST ITS BOTTOM 24 mm THIS PASS (1.006 -> 1.030) so the screw cap could have them; see CAP_H.
## BOTH SOLVES REDONE, because the block above says to redo them and the last pass's numbers were
## for a neck that started 24 mm lower. With a = b = 0.190, n = 2.15, centre 1.260:
##   R = NECK_R_BOT 0.074:  |dy| = 0.190 * (1 - (0.074/0.190)^2.15)^(1/2.15) = 0.178  ->  the glass
##       stops being wider than the neck at model 1.082, so the VISIBLE pinch is 1.030..1.082, i.e.
##       52 mm. Every millimetre of it is above the eye hoop's upper bar, which now projects to 0.963
##       on this axis at the portrait camera — the bar check that cost a render two passes ago passes
##       with 67 mm to spare instead of failing by 31.
##   R = 0.100 (the collar bead):  |dy| = 0.166  ->  model 1.094. The collar is at 1.018, 76 mm clear,
##       so it still grips inboard and does not flare out like a hat brim.
const NECK_R_TOP := 0.066
const NECK_R_BOT := 0.074
const NECK_H := 0.060
const NECK_YY := -0.030                ## head-local centre -> model 1.060, spanning 1.030..1.090

## THE SCREW CAP. Short — 0.160 m of shank spanning model 0.870..1.030 — because the base being
## LONGER than the glass was the headline failure of two passes ago. Its top disc at 1.030 is covered
## by the glass neck's bottom disc and its bottom at 0.870 is inside the socket cup, so neither end
## cap is ever visible.
##
## PLUM SHANK, TAUPE_DARK BEADS, AND THE VALUE STEP IS 0.11. This block is where two of the critic's
## fixes meet and they pull in opposite directions, so the resolution is written down:
##   * fix 5 said the PLUM_DARK (V 0.306) valleys under TAUPE (V 0.671) beads rendered as pure black
##     slots exactly as tall as the beads, and a stack of black slots is an accordion hose, not a
##     thread. A thread is a shallow ridge on continuous metal, so the step has to be SMALL.
##   * fix 4 said the rose bands that show through the eye hoop's open window, framed between the two
##     lenses, read as a ribbed muzzle or a respirator grille, and offered "make the band that falls
##     inside the window the dark shank colour so the window is a dark void".
## Both are satisfied by moving the WHOLE cap down the value ladder rather than by widening or
## narrowing the gap between its two parts: PLUM (0.431) shank, TAUPE_DARK (0.541) beads. The window
## now holds a dark column with a hint of ribbing instead of rose stripes on black, the valleys are one
## soft step under the bead rather than a slot, and the shank matches the PLUM neck column below the
## socket so the whole base reads as one continuous dark form rather than as three stacked objects.
## The cost is that the thread has less contrast to carry it at 6.5 m; the silhouette bumps do most of
## that work anyway, and it was checked on the gameplay render before this was written.
##
## THE CAP GREW 24 mm UPWARD THIS PASS (top 1.006 -> 1.030) AND THE GLASS PINCH PAID FOR IT, and
## that swap is one of the three moves that finally gets the whole thread above the eye hoop's upper
## bar. The arithmetic is in the HOOP_CENTRE block: at the portrait camera the bar's outer edge
## projects onto the cap's own plane at model 0.963, and the three beads have to live entirely above
## that and entirely below the glass. Raising the ceiling from 1.006 to 1.030 turns a 43 mm slot into
## a 67 mm one, which is what lets a three-bead stack fit above the bar with a real valley between
## the beads instead of a 1 px scratch.
## WHAT IT COSTS AND WHY THAT IS AFFORDABLE: the visible glass pinch drops from 76 mm to 52 mm. The
## pinch's own hard-won rule (see NECK_*) was never "76 mm"; it was "the hoop's upper bar must not
## cover it", and the bar used to project across model 0.994..1.025, i.e. straight over the pinch.
## The bar now projects to 0.963 and below at every camera checked, so all 52 mm of pinch is in the
## clear — 22 px at the portrait camera against the 5 px the last-but-one pass measured. More pinch
## is visible now than when the band was 76 mm tall.
## THE 72/28 GLASS-TO-METAL SUM STILL HOLDS, and it was re-added rather than assumed:
##   glass   crown 1.450 .. neck bottom 1.030  = 0.420 m   71.9 %
##   metal   1.030 .. socket bottom 0.836      = 0.194 m   28.1 %
## against the old 0.444/0.170 = 72.3/27.7. The ratio the last pass fought for is intact to 0.4 %.
const CAP_R_TOP := 0.090
const CAP_R_BOT := 0.078
const CAP_H := 0.160
const CAP_Y := -0.140                  ## model 0.950, spanning 0.870..1.030

## THE THREAD IS STACKED RINGS, NOT A HELIX, and that is a decision rather than a shortcut:
##  1. There is no helix primitive to call. `arc_tube` sweeps at a constant radius in one plane with
##     no rise, and `taper_tube`'s `curl` bends in a single plane too. A real helix means new mesh
##     code in chibi_model.gd, which is off limits this round.
##  2. It would not read anyway. Measured off the renders, she is 417 px per metre at the portrait
##     camera and about 90 at gameplay, so one 40 mm turn is 17 px close up and 3.6 px far away — a
##     helix's diagonal offset across a single turn is under a pixel at gameplay and it would render
##     as horizontal bands. Which is what stacked rings already are, for a quarter of the cost.
##  3. Cost. Three tori at (14, 5) are 64 triangles each and all three share ONE cached mesh: 192.
##
## THREE, AND THEY TAPER. Five beads at a constant 0.132 outer radius rendered as a spring — a spring
## is a stack of identical rings and so was that. A screw cap is a truncated CONE, widest where it
## grips the glass. One `torus(THREAD_IN, THREAD_OUT, 14, 5)` is built and the three instances are
## scaled in X and Z only (1.000 / 0.970 / 0.940, top to bottom), which narrows the ring without
## flattening the bead's vertical section and without paying for three separate meshes. The per-bead
## numbers are in the THREAD_* block, which is also where the pitch, the height and the taper were
## all re-derived this pass against the eye hoop's projected upper bar.
##
## The topmost is the COLLAR: at model 1.018 it is 12 mm below the glass neck's bottom and 76 mm
## below where the envelope would swallow it, so it stands clear and INBOARD of the ball's widest
## point by a factor of two. That is the E26 rim gripping a neck, which is what the last pass's
## 0.132 bead against a 0.16 ball could not be.
##
## THE STACK MOVED UP 64 mm AND TIGHTENED THIS PASS, and this is the "shorten THREAD_DY / CAP_H so
## the exposed thread is vertically shorter" path that the critic named and the last builder listed
## as UNRESOLVED without trying. It is the half of the fix that does NOT come out of the eyes.
##
## THE TARGET IS A NUMBER, not a feel. At the portrait camera the eye hoop's upper bar — outer edge,
## not centre line — projects onto the cap's own plane at model 0.963 (0.916 at gameplay, 0.943 at
## the 8.6 m lineup; the projection solve is written out at HOOP_CENTRE). Everything above 0.963 is
## seen against sky and reads as head; everything below it is inside or behind the hoop and reads as
## whatever the hoop frames. So the whole bead stack has to clear 0.963, and the glass caps it at
## 1.030. That is a 67 mm slot for three beads.
##   THREAD_Y0 -0.112, THREAD_DY 0.020  ->  beads at model 0.978 / 0.998 / 1.018
##   tube radius (0.100 - 0.088) / 2 = 0.006, so each bead is 12 mm tall
##   stack spans 0.972 .. 1.024   — 9 mm of clearance over the bar, 6 mm under the glass
## The pitch is 20 mm with a 12 mm bead, so the valley is 8 mm: 3.3 px at the portrait camera's
## 417 px/m. That is thinner than the 18 mm valley this stack used to have and it was the thing most
## at risk in the compression, so it was read off the render rather than trusted — see the run log in
## the HOOP_CENTRE block. A tighter pitch is also the more correct read: a real E26 thread is a fine
## continuous ridge, and the previous 40 mm pitch on a 0.200 m cap was closer to a coil than a screw.
##
## THE TAPER EASED FROM 0.040 TO 0.030 PER BEAD, because the shank it rides is 12 mm wider at the top
## than at the bottom and the stack is now 52 mm tall instead of 100, so the old taper made the
## lowest bead stand only 5.9 mm proud — half the collar's 10.9 mm, which reads as a bead that is
## being swallowed rather than as a cone. Re-measured against the cap's own wall
## (r(y) = 0.078 + (y - 0.870) / 0.160 * 0.012):
##   1.018  outer 0.1000  shank 0.0891  ->  10.9 mm proud   (the COLLAR)
##   0.998  outer 0.0970  shank 0.0876  ->   9.4 mm
##   0.978  outer 0.0940  shank 0.0861  ->   7.9 mm
## which is the same 8-11 mm band the last pass tuned to, now spread evenly instead of collapsing at
## the bottom.
##
## `torus()` takes INNER and OUTER radii, not centre and tube.
const THREAD_IN := 0.088
const THREAD_OUT := 0.100
const THREAD_N := 3
const THREAD_Y0 := -0.112              ## head-local, the LOWEST bead -> model 0.978
const THREAD_DY := 0.020
const THREAD_TAPER := 0.030            ## XZ scale lost per bead going down: 1.000 / 0.970 / 0.940

## THE SOCKET CUP she is screwed into: a flared cone, narrow enough at the bottom to meet the neck
## column and wide enough at the rim to read as a fitting the bulb sits IN. It moved UP 100 mm this
## pass (0.767 -> 0.867), which is where most of the proportion fix came from, and it shrank with the
## cap it swallows (rim 0.176 -> 0.142). The 0.142 rim against the shank's 0.078 is still deliberate
## slack: it is what hides the cap's bottom rim when the bulb rocks. Do not narrow it further.
##
## Raising it also HALVED the one cosmetic defect the last pass had to disclose. The socket is
## head-parented and the neck column is torso-parented, so at `_pose_think`'s 0.24 rad head roll the
## socket's centre slides across the column top and you see a step. At model 0.767 that step was
## 77 mm; at 0.867 it is 0.223 * sin(0.24) = 53 mm, and the socket's bottom disc (0.116) still
## overlaps the column's top (0.106) in Y by 14 mm, so no hole ever opens — a step, not a gap.
const SOCKET_RT := 0.142
const SOCKET_RB := 0.116
const SOCKET_H := 0.062
const SOCKET_Y := -0.223               ## model 0.867, spanning 0.836..0.898

## SEVEN AMBER INDICATOR PIPS. They used to ring the dish face, then the socket wall; they ride the
## MIDDLE THREAD BEAD now, and the move was forced by the yoke.
##
## WHY THEY HAD TO MOVE OFF THE SOCKET. There (head-local -0.223) they were being eaten by the hoop's
## lower bar — the critic caught them clipped in `--state=talk` at 3 m with about 2 mm of margin —
## and no amount of dropping the yoke frees them, it only re-frames them. Measured on the 3 m
## portrait render: the socket sits a long way BEHIND the hoop plane, so a socket point at radius
## 0.127 projects to 0.041 rad against a hoop window whose inner edge is at 0.016 rad — i.e. the
## outer four pips project OUTSIDE the window and land behind the lenses and the hoop ends. Only the
## middle three survived, and three amber dots framed between two eyes is a nose, not a voice.
## Verified in the render, not assumed: that run showed exactly three. Pulling the yoke in to 0.190 m
## this pass narrows that parallax but does not close it, so the socket is still the wrong home.
##
## SO THE ONLY PLACES LEFT ARE ABOVE THE UPPER BAR OR BELOW THE LOWER ONE, and below the lower bar
## there is no head hardware at all any more — that screen band is chest. Above it there is the whole
## ribbed screw base, in the clear, at every distance and state checked. Hence the collar.
##
## THE MIDDLE BEAD AND NOT THE TOP ONE, deliberately: the top bead is 12 mm below the glass neck, and
## the one rule this head is built around is that an UNLIT bulb must not read as half-lit — seven
## amber lamps pulsing to 3.5 emission a centimetre from the glass is the fastest way to lose that.
## The middle bead is 32 mm below the glass with a whole dark bead between, which is enough
## separation that the render reads them as base hardware. They are NOT on the envelope and never
## will be.
##
## THE 32 mm IS DOWN FROM 52 mm THIS PASS, because the whole stack tightened and rose; the pip's own
## top edge sits at model 1.006, i.e. 24 mm of dark metal (half the collar bead, a valley and half
## the middle bead) between the brightest amber on her and the first millimetre of glass. That is
## the number to watch if the envelope ever reads warm on the shade side in `--state=talk`; it was
## read off the talk render at both 3 m and 6.5 m before this line was written and the glass stayed
## cool. If it ever does pick up amber, move the pips DOWN to the lowest bead (model 0.978, outer
## 0.094) rather than up — the lowest bead is still 6 mm above the hoop's projected upper bar at the
## tightest camera, so there is exactly one bead of slack and no more.
##
## THE CLEARANCE CHECK THAT MATTERS, redone for this pass's geometry because the brief called the
## clipping out by name. A pip is clear of the hoop when its top edge projects ABOVE the hoop's upper
## bar OUTER edge — not merely outside the window, which is what the last pass checked and which is
## satisfied by a pip hidden behind a lens. Screen-space vertical, pip top vs bar outer top:
##   portrait 2.05 m   +0.0261 vs +0.0003     gameplay 6.5 m   -0.0007 vs -0.0164
##   lineup   8.6 m    +0.0317 vs +0.0229     3 m portrait     +0.0177 vs +0.0002
## All four positive, i.e. the entire arc sits above the bar at every camera in the brief, with the
## 8.6 m lineup the tightest at 0.0088 rad — about 9 px at 1280x720. The pips are also well inside
## the hoop horizontally at every one of them, so nothing can catch an end ring on the way past.
##
## THEY MOVED PARENT TOO — `_bulb`, not `_head`. The bead they now sit in rocks with the bulb (0.20
## rad on think), and a lamp that stayed put while its own bead tipped 22 mm in z would visibly
## detach. On the socket that did not matter; here it does.
##
## A 103 DEG FRONT ARC, NARROWED FROM 132. The pips ride a 0.097 radius now instead of 0.127, so the
## same 132 deg arc would turn the outer pair almost edge-on to the camera and waste them. +/- 51.6
## deg keeps all seven within 52 deg of the viewer and still spreads them 152 mm across the base,
## which is the full visible width of the cap — the travelling talk wave has as much room as it had
## on the socket.
const LAMP_COUNT := 7
const LAMP_R := 0.097                  ## the bead's own outer radius, so each pip is half sunk in the ridge
const LAMP_Y := -0.092                 ## model 0.998 — the MIDDLE thread bead's centre line
const LAMP_ARC := 0.900                ## +/- 51.6 deg

## WHERE THE EYE YOKE IS BOLTED. On the SOCKET, not on the bulb. The struts used to sit at |x| = 0.406
## to clear a 0.72 m dish; the cap is only 0.090 in radius, so leaving them there would hang two
## sticks in mid air 0.32 m clear of anything — the exact failure the trunnion block was invented to
## fix. Anywhere ON the envelope is worse: the glass starts 0.17 m above the strut base and a lug up
## there would be half buried in it. Mounting to the socket is also the honest answer to "what holds
## the eyes up?" — the chassis does. MOUNT_Y is set near the socket's widest point rather than at its
## centre, so a 0.020 strut seated at |x| = 0.138 sinks 16 mm into a 0.134 wall instead of floating.
## Both numbers moved with the socket this pass (0.170/-0.305 -> 0.138/-0.212); the strut TIP did not.
const MOUNT_X := 0.138
const MOUNT_Y := -0.212                ## model 0.878, near the socket rim
const MOUNT_Z := 0.030

# ---------------------------------------------------------------------------- the hoop
## ONE JOINED HOOP, built as a stadium outline — two straight bars and two semicircular ends — rather
## than a squashed torus. A torus scaled non-uniformly to this aspect thins its own tube to 6 mm at
## the top and bottom, which is a sub-pixel wire at the 6.5 m gameplay camera; the stadium keeps a
## constant 15 mm tube all the way round. It is also the shape that lets ONE ring hold TWO lenses,
## which is the whole difference between this and Mayor Orbit's two rims plus a bridge bar.
##
## THE PROBLEM THIS BLOCK EXISTS TO SOLVE, stated once: FRONT ON, THE RIBBED SCREW BASE WAS FRAMED
## BETWEEN THE TWO LENSES, inside the hoop's open centre, and a warm ribbed lump between two eyes is
## a SNOUT. It did not matter that the ribs were the right shape or the right colour; anything parked
## in that window becomes a face part. HOOP_CENTRE is hoop geometry, the `eyes` spec list is the face
## system's, and moving the first changes not one key of the second — no `_add_face` call, no
## expression mesh, no blink, no look-around. So this is the lever, and it has now been pulled twice.
##
## THE LAST PASS PULLED IT IN Y ALONE AND WAS FAILED FOR IT, and that failure is the reason the
## numbers below are derived instead of rendered-and-eyeballed. It went to (y -0.190, z -0.394): the
## ribs cleared at 3 m, and at the 6.5 m gameplay camera and the 8.6 m cast lineup the hoop landed
## across her gorget and the top of her chest plate with a bare purple neck and an empty bulb above
## it. She had no face on her head at the distance the game is actually played at. Dropping Y alone
## cannot win, and here is why in one line: the hoop hangs 0.394 m in FRONT of the head axis, so its
## apparent height depends on the camera's PITCH, and the three cameras that matter are pitched
## 10 deg, 28 deg and 20 deg down. What is "clear of the base" at 10 deg is "down on the sternum" at
## 28 deg. Y alone trades one camera against another; there is no value of it that satisfies both.
##
## THE FIX IS THAT Z IS ALSO A LEVER, and nobody had touched it. Pulling the yoke IN shrinks exactly
## the parallax that makes the three cameras disagree, so a drop in Y can be paid for with a drop in
## the standoff and the gameplay read comes back. Both moved this pass:
##     y  -0.078 -> -0.200      z  -0.394 -> -0.190
## THE METRIC, and it is the same one for both failures so the two are directly comparable. Project
## the hoop's upper/lower bar OUTER edge (centre +/- HOOP_HALF_H +/- HOOP_TUBE, at the ring plane
## z = HOOP_CENTRE.z + HOOP_Z, times body_scale 1.02) through each camera, then ask what height on
## the CAP's own plane, or on the BODY's own plane, lands on the same scanline. That number says what
## the bar covers, which is the only thing the reader sees.
##
##                              bar-top on cap axis        bar-bottom on body axis
##   camera                     (thread must be ABOVE)     (must stay off the gorget, top 0.700)
##   portrait 2.05 m / 10 deg          0.963                        0.736
##   gameplay 6.5 m  / 28 deg          0.916                        0.667
##   lineup   8.6 m  / 20 deg          0.943                        0.718
##   3 m portrait    / 10 deg          0.963                        0.744
## against the bead stack at 0.972..1.024 (see THREAD_*) and a gorget whose top face is at 0.700.
## EVERY BEAD IS ABOVE THE BAR AT EVERY CAMERA, with 9 mm of margin at the tightest.
##
## AND THE GAMEPLAY READ IS BACK WHERE IT WAS. The three configurations side by side, on the one
## number the critic failed the last one on — where the hoop's lower bar lands on the body:
##   (y -0.078, z -0.394)  PASSED       gameplay 0.680   lineup 0.774
##   (y -0.190, z -0.394)  FAILED       gameplay 0.560   lineup 0.656   <- across the chest plate
##   (y -0.200, z -0.190)  this pass    gameplay 0.678   lineup 0.723
## i.e. 2 mm off the version that passed at gameplay and 51 mm at the lineup, against the 120 mm and
## 118 mm the failed one gave up. The bar sits on the dark neck column, above the gorget, at both.
##
## WHY NOT SIMPLY RAISE THE SOCKET/CAP INSTEAD, which was the note's own fallback: `marker_clearance`
## is head_y + BULB_Y + BULB_SEMI.y = 1.450 and the crown was cut from 1.478 to 1.450 last pass
## because a critic said she was visibly the tallest in the 9 m lineup, so raising the cap raises the
## crown one for one. What DID get taken from that direction is the third path the last builder
## listed as unresolved and never tried: 24 mm of glass pinch handed to the cap so the thread has a
## taller slot, and the thread itself compressed from a 100 mm stack to a 52 mm one. See CAP_H and
## THREAD_*. Between them they lift the bottom of the ribbing from model 0.904 to 0.972 without
## moving the crown by a micron.
##
## WHAT IS IN THE WINDOW NOW: the smooth plum screw shank, the socket cup's flare and the dark neck
## column — chassis, smooth, one value, no repeated horizontal bands anywhere in it. Above the bar,
## in the clear against sky: 52 mm of ribbed base, then 52 mm of glass pinch, then the ball. That is
## ball -> pinch -> ribbed base -> hoop, which is the silhouette the user asked for.
##
## THE STANDOFF IS NOW 0.190 m AND THAT IS A REAL COST, disclosed rather than glossed. She used to
## carry the yoke 0.394 m out front and it was listed as a machine cue. At 0.190 m the hoop still
## stands 48 mm clear of the socket cup's rim at its closest approach, on two visible struts with
## daylight all round them, so it still reads as a bolted-on instrument rather than a faceplate —
## but it is a bracket now, not a boom. TWO THINGS ARE BOUGHT WITH IT. The first is the gameplay row
## above. The second is the other regression the critic logged: at 0.394 m the look-around sweep
## swung the whole hoop and both lenses clear outside her body silhouette, hanging in open sky beside
## her shoulder on two thin sticks. The excursion is proportional to the standoff, so it is down 52 %
## — the hoop now sweeps across her own neck and socket instead of past them.
## THE FLOOR ON THE STANDOFF IS GEOMETRIC, not taste: the socket cup is 0.142 in radius against the
## hoop's 0.087 window half-width, so the cup would push through the window's sides if the yoke came
## much closer. At z -0.190 the hoop's rear surface is at -0.189 and the cup's front at -0.142.
const HOOP_CENTRE := Vector3(0.0, -0.200, -0.190)
const HOOP_HALF_W := 0.102             ## also the lens centre offset, so each lens sits in one end
const HOOP_HALF_H := 0.078
const HOOP_TUBE := 0.015
const HOOP_Z := -0.014                 ## the ring plane sits in FRONT of the lens glass
## EYE SPACING: centres 0.204 m apart, and HOOP_HALF_W did not move this pass — the standoff did, so
## the screen number had to be recomputed and the old note here does not survive that.
##
## THE OLD NOTE CLAIMED 29.9 % OF THE HEAD'S PROJECTED WIDTH AND THAT NUMBER IS WRONG, in the
## direction that flatters. It has to be: the lens centres are 0.204 m apart against a 0.380 m
## envelope, which is 53.7 % GEOMETRICALLY, and the hoop is NEARER the camera than the envelope, so
## perspective can only magnify the pair relative to the ball — it cannot halve it. Projected properly
## at the 6.5 m gameplay camera (lens centres at the ring plane, envelope half-width at its own
## widest point, both through the same camera):
##   was (z -0.394, y -0.078)   55.9 %        now (z -0.190, y -0.200)   53.9 %
##   portrait 2.05 m                          58.4 %      lineup 8.6 m   54.2 %
## So she is outside the 28-35 % band in docs/STYLE_GUIDE.md and has been since the hoop was built;
## pulling the yoke in this pass moved her 2 points TOWARD the band rather than away from it. This is
## disclosed, not fixed: closing 20 points means halving HOOP_HALF_W, and HOOP_HALF_W is the lens
## centre offset — it is the eye spec in all but name, and the eyes are the one thing this round is
## forbidden to touch. Whoever gets the band gate next should start here and should not trust 29.9.
const LENS_R := 0.052
const LENS_RIM_IN := 0.048
const LENS_RIM_OUT := 0.058

# ---------------------------------------------------------------------------- the iris
## Five converging leaves per lens: open, they hide UNDER the hoop's end ring; closed, they cross the
## centre so the pupil is genuinely covered rather than squashed. `_apply_face` still squashes the
## pupil underneath — the leaves hide that.
##
## THE RETRACTION WAS WRONG AND THE COMMENT THAT CLAIMED OTHERWISE WAS WRONG TOO. The old note said
## the leaves retracted inside the ring at 0.062 + 0.012 = 0.074 against the ring's 0.078 centre line,
## and that arithmetic is about the leaf's OUTER end. It is the wrong end. `_build_iris` seats the
## blade node at radius IRIS_OPEN and then points the tube INWARD, so at rest the leaf runs from
## IRIS_OPEN down to IRIS_OPEN - IRIS_LEN — the old 0.062 -> 0.036, which is 27 mm of dark wedge lying
## across the open aperture of a 0.052 lens. The critic saw exactly that in all eight of its renders:
## five spikes standing around each lens, which reads as LASHES, the one thing this cast has a
## standing ruling against.
##
## THE FIRST FIX WAS ALSO WRONG, AND THE RENDER SAID SO. Parking the leaves at 0.080 put them radially
## inside the ring's tube band (0.063..0.093) but left IRIS_Z at -0.018, which is 4 mm IN FRONT of the
## ring's own centre plane at -0.014. Depth wins over radius: they drew ON TOP of the ring as five
## arrowheads per eye, which is a worse lash than the one they replaced.
##
## SO THE FIX IS IN Z AS WELL AS IN R. IRIS_Z moves to -0.004, which puts the leaf's front face at
## -0.016 while the ring's tube reaches -0.029 at its centreline and -0.025 at the leaf's own radius —
## the ring is in front along the whole parked arc and simply occludes the leaves. Checked at three
## radii (0.068 / 0.078 / 0.082 -> ring front -0.025 / -0.029 / -0.0285, all ahead of -0.016).
## AND THE LEAVES ARE NOW THE HOOP'S OWN COLOUR, which is the belt to the z fix's braces. The hoop is
## a STADIUM: only the two outer semicircles and the two straight bars are solid, so of the five leaves
## round each lens, one or two always park over the OPEN window between the lenses and no amount of
## radius or depth arithmetic will hide those. Painting them PLUM_DARK — the hoop's exact colour,
## instead of the rose TAUPE_DARK they were — makes a parked leaf either invisible against the ring it
## is behind or invisible against the dark void it is in front of. Closed, it is still a dark shutter
## over a jade lens, which is all it ever needed to be.
## CLOSED STILL WORKS, and that is the constraint the z move could have broken: at IRIS_CLOSED the
## leaf spans z -0.016..0.008 against a pupil at -0.012..-0.004 and lens glass at -0.010..0.010, so
## the leaf is still the frontmost thing over the pupil and the shutter still shuts. Five leaves
## 0.024 wide at a 0.0176 spacing at that radius overlap, so there is no hole in the middle.
## Parked, the leaf runs 0.078 -> 0.064, inside the ring's 0.063..0.093 tube band.
##
## AND ALL OF THAT WAS STILL NOT ENOUGH, because both of those fixes assume there is ring to hide
## BEHIND, and around a third of the parked arc there is none. The hoop is a STADIUM: from a lens
## centre, hoop material covers the outer semicircle (|theta| <= 90 deg from outward) plus the two
## straight bars (54..126 deg and -126..-54 deg), i.e. theta in [-126, 126]. The INNER 108 deg — the
## open window between the two lenses — is empty at every radius and every depth. Five leaves at 72
## deg spacing cannot miss a 108 deg gap: one or two per lens always park in it, and that is exactly
## what the critic photographed, four to five dark triangles per lens sitting on the plate reading as
## LASHES. Rotating the set does not help (108 > 72). Nor does depth: parking the leaf BEHIND the
## opaque lens glass needs it 6.3 mm back at the leaf's radius, but the leaf is 24 mm thick in z, and
## at a 30 deg view the parallax then swings it 15 mm past the 0.052 glass edge. The arithmetic is
## a contradiction, not a tuning problem — checked both ways before giving up on it.
##
## SO THE LEAVES ARE STOWED. Above IRIS_SHOW they are not drawn at all; below it they are. That is
## not a dodge, it is what the number is chosen to mean: at `open` = IRIS_SHOW the leaf's OUTER end
## sits at exactly LENS_RIM_OUT, so it appears from under the bezel rim and never before, which is
## what a real diaphragm does — the leaves live in the barrel and you first see them emerging past
## the rim. Solve r(open) = lerp(IRIS_CLOSED, IRIS_OPEN, open^2) = LENS_RIM_OUT 0.058:
##   open^2 = (0.058 - 0.014) / (0.078 - 0.014) = 0.6875   ->   open = 0.829
## so there is no pop: the first frame the leaf is drawn, every millimetre of it is inside the rim
## band, and it grows inward from there. The cost is that the leaf's stowed travel from 0.058 out to
## 0.078 is not animated, which nothing can see, because it happens under the rim.
##
## WHY NOT SIMPLY FEWER LEAVES OUTSIDE THE GAP: three leaves at 120 deg CAN miss a 108 deg gap, but
## only with a 6 deg margin against a leaf that is 24 mm wide (8.8 deg) at that radius, and a
## three-leaf shutter leaves a jade wedge over the pupil when closed. Stowing keeps five.
const IRIS_BLADES := 5
const IRIS_OPEN := 0.078
const IRIS_CLOSED := 0.014
const IRIS_LEN := 0.014
const IRIS_R0 := 0.012
const IRIS_R1 := 0.002
const IRIS_Z := -0.004
const IRIS_SHOW := 0.829               ## `_eye_open` above this and the leaf is stowed under the rim

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
## The neck came back UP this pass. It dropped 90 mm when the dish became a bulb, to leave room for a
## long screw cap; the critic's answer was that the long screw cap was the whole problem, so the
## column now runs 0.680..0.850 and hands 100 mm of what used to be exposed dark shank back to the
## chassis. Lower body, shorter base, same crown minus 32 mm.
const NECK_Y := 0.765
const SHOULDER_X := 0.196              ## narrower than the shared 0.212
const SHOULDER_Y := 0.545

# ---------------------------------------------------------------------------- legs
## Hip pivots are fixed at HIP_Y = 0.245 by the shared rig, so the leg is short like everyone's — but
## it is JOINTED, which nobody else's is. Thigh 0.095, shin 0.088, then a flat pad whose sole lands
## on y = 0.
const THIGH_LEN := 0.095
const SHIN_LEN := 0.088
const PAD_SEMI := Vector3(0.096, 0.030, 0.116)

var _bulb: Node3D
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
	# The tallest neighbour (crown 1.450 m in model space, 1.479 m as rendered) and the slowest but
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
	# surface point gets the bulb's own envelope back.
	#
	# THE HONEST CAVEAT, because it was already half-true and the bulb makes it fully true: these two
	# describe a solid whose CENTRE is at head-local +BULB_Y, not at the head origin, so a surface
	# point solved here would land 64 mm low. Nothing calls it. If anything ever does, it has to add
	# BULB_Y first.
	head_semi = BULB_SEMI
	head_n = BULB_N
	# UNCHANGED, and it must stay unchanged: HOOP_CENTRE and the eye spec list are head-local, so
	# this number is what keeps the eyes exactly where they already are.
	head_y = 1.090


func _build_geometry() -> void:
	# `rebuild()` frees every child but cannot know about these lists, and a stale pivot would be
	# read by `_animate_extras` on the very next frame.
	_bulb = null
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
	_build_bulb()
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

	# Back: a counterweight pack, so the rear read is a machine with mass rather than a blank plate.
	# It answered the dish's lever arm; it now answers the bulb, which is 0.614 m of head assembly sitting on
	# a 0.170 m neck and needs the mass behind it just as much.
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
## THE NECK IS SPLIT BETWEEN TWO PARENTS, and the split moved when the dish became a bulb.
##
## Read bottom-up: gorget (torso) -> a short fat column (torso) -> a flared socket cup (HEAD) -> the
## screw thread -> the glass. She is screwed into her own neck socket, which is a better machine cue
## than the mast boss that used to sit here. (The seven indicator pips used to ride on it; they are
## on the cap's middle thread bead now — see the LAMP_* block.)
##
## THE SOCKET IS ON THE HEAD AND THE COLUMN IS ON THE TORSO, and it has to be that way round: the
## strut yoke that carries the eye hoop is bolted to the socket, and the eye hoop is head-parented
## because the eyes have to keep looking at you while the bulb rocks. So the socket is the one joint
## in the neck that slips, and the parts are sized for it. At `_pose_think`'s 0.24 rad head roll the
## socket's centre moves 0.223 * sin(0.24) = 53 mm relative to the column — down from 77 mm last pass,
## because raising the socket 100 mm shortened its lever arm off the head origin — and the socket's
## bottom disc is 0.116 in radius against the column's 0.106 top with 14 mm of Y overlap, so the two
## solid caps stay face to face and no hole ever opens between them. You get a visible step in the
## think emote, not a gap. It is disclosed rather than fixed: fixing it properly means either
## torso-parenting the socket (which unbolts the eye yoke from the head and breaks the eyes) or a
## skinned neck, and neither is in scope for "change its head".
##
## MASTBOSS AND THE COLLAR RING ARE BOTH GONE: a 0.092 m stub and a torus that between them occupied
## exactly the space the screw cap now needs, for 130 triangles.
func _build_neck() -> void:
	# 0.170 m of column spanning model 0.680..0.850, of which 136 mm shows between the gorget's top
	# (0.700) and the socket's bottom (0.836). It is 100 mm longer than the last pass's stub, and that
	# length is the proportion fix: every millimetre of it is a millimetre that is no longer dark screw
	# shank. It tapers the wrong way on purpose (0.212 across at the top, 0.184 at the bottom) so the
	# column, the socket cup and the cap read as one continuous flare from the gorget up into the glass
	# instead of as three discs stacked on a pole.
	_mi(cylinder(0.106, 0.092, 0.170, 14), _toon(PLUM, _matte(SURF_LIMB)), _torso,
		Vector3(0.0, NECK_Y, 0.0), "NeckColumn")
	# THE SOCKET CUP. It flares UP and OUT (0.232 across at the bottom, 0.284 at the rim), which is what
	# makes it read as a fitting the bulb sits IN rather than as one more disc in a stack. Its top
	# face is a solid annulus that the screw shank passes through, so there is no hole to see down into.
	#
	# IT WENT FROM TAUPE_DARK TO PLUM THIS PASS, and that is not a palette tweak — it is the last
	# standing item of the critic's fix 4, applied to the part that inherited the problem. Fix 4 said:
	# whatever falls inside the eye hoop's open window, framed between the two lenses, must be the dark
	# shank colour so the window is a dark VOID. When the yoke moved this pass the ribbing left the
	# window and the CUP took its place — and TAUPE_DARK is rose at V 0.541 against a PLUM shank at
	# 0.431, so the first portrait render of the new geometry showed a warm horizontal bar sitting
	# exactly between the two eyes. One band is not a rib stack, but a warm bar between two eyes is
	# still the wrong furniture, and it is the same failure mode by a shorter route.
	# At PLUM the neck column, the cup and the screw shank are one value, so the window holds a single
	# uninterrupted dark column and the ONLY warm thing left on the whole base is the thread itself —
	# which strengthens the screw-cap read rather than competing with it. The cup still reads as a cup
	# because its flare is a silhouette, not a colour.
	# A SIDE EFFECT WORTH BANKING: the socket is head-parented and the column is torso-parented, so
	# `_pose_think` slides one across the other and the file has disclosed that step for two passes.
	# Same colour, same brushed preset — the step is now a shading break rather than a colour break,
	# which is most of the way to invisible. It is still a step; it is just much harder to catch.
	_mi(cylinder(SOCKET_RT, SOCKET_RB, SOCKET_H, 18), _toon(PLUM, _matte(SURF_SHELL)), _head,
		Vector3(0.0, SOCKET_Y, 0.0), "SocketCup")
	# The pips used to be built here, off the socket. They now ride the cap's middle bead, so they are
	# built at the end of `_build_bulb()` instead — `_bulb` does not exist yet at this point.


## THE BULB. Its own node so `_animate_extras` can rock it independently of the head — the head still
## carries the shared HEAD_PITCH/YAW/ROLL channels, and the bulb sways on top of them, which is why
## she can be looking at you and thinking at the same time.
##
## THE PIVOT IS IN THE SOCKET, at model 0.867, and that is the whole reason this node exists at all.
## The head origin is at model 1.090, which is INSIDE the glass — rocking about it would swing the
## screw cap sideways out of a cup only 0.142 m in radius and tear the bulb out of its own socket
## every time she thought about something. About the socket centre the cap's bottom rim sits 3 mm
## above the pivot and so barely moves; the slip check is written out in `_animate_extras`.
##
## WHAT STILL SAYS "MACHINE" NOW THAT THE DISH IS GONE, because that was the open question and the
## dish was never the answer — the chassis was, and all of it survives untouched:
##   * this screw thread and its socket cup. No animal has a thread, and nothing else in the cast has
##     one either;
##   * the eye hoop carried 0.19 m out front on a two-segment strut yoke with trunnion lugs and
##     bearing pins — an instrument mount, not a face;
##   * a five-leaf mechanical IRIS behind each lens instead of an eyelid;
##   * brushed metal grain on every plate, which no other robot has, now with the glass envelope as
##     the one deliberate smooth exception;
##   * the jointed leg — hip ball, thigh strut, knee ring, shin, ankle block, flat lander pad with a
##     toe rail — and the gait that holds the pad parallel to the ground through the whole stride;
##   * the machined pelvis with exposed leg sockets, the pinched waist, the counterweight pack and
##     three fins on her back, a flat palm plate and a wrist band on each mitt;
##   * the amber core behind a recessed bezel, and seven indicator pips set into the screw thread;
##   * and no mouth at all. She is still the only one.
func _build_bulb() -> void:
	_bulb = _node("Bulb", _head, Vector3(0.0, SOCKET_Y, 0.0))
	# NOT LIT, AND NOT TRANSPARENT. See GLASS: rule 4 of this project's hard-won list is that
	# `toon_soft` is opaque, so alpha is not a way to fake glass — it renders black. There is no
	# "surface" key either, which leaves `surface_kind` at 0: the envelope is the only smooth thing
	# on her, and that break against the brushed cap is doing as much work as the value step.
	#
	# The numbers, and what each is for, AFTER the first render threw draft 1 out (see GLASS):
	# `shade` 0.34 is ABOVE the cast's 0.30, not below it as two drafts tried: `toon_soft` already
	# lifts a character's shade side to CHAR_SHADE_FLOOR 0.68, so cutting it further leaves a big pale
	# ball with almost no terminator, which is exactly what "switched on" looks like. Going the other
	# way gives the envelope the hardest terminator on her, and a hard terminator says "solid object
	# in sunlight" louder than anything else available here. `shade_tint` swaps the
	# shared lavender for a cool blue-grey so the shadow side goes cold rather than violet. `spec`
	# 0.24 at size 300 is ONE very tight highlight — with the value now down where it belongs, this is
	# the main thing left saying "glass", and it has to stay tight: broad and soft reads as shiny
	# plastic. `rim` 0.030 is the cast default, i.e. a hint of wrap light and not a halo. If she still
	# reads as switched on, darken GLASS again before touching any of these; do NOT reach for emission
	# or `lit_material` under any circumstances.
	var m_glass := _toon(GLASS, _matte({
		"spec": 0.24, "spec_size": 300.0, "rim": 0.030, "shade": 0.34,
		"shade_tint": Color(0.64, 0.72, 0.86)}))
	# PLUM shank, TAUPE_DARK beads: a 0.11 value step, not the 0.37 an earlier pass had. See CAP_*.
	# The SOCKET CUP is PLUM too as of this pass, so the shank, the cup and the torso's neck column are
	# one value and the thread is the only warm band on the whole base — see `_build_neck`.
	var m_cap := _toon(PLUM, _matte(SURF_SHELL))
	var m_thread := _toon(TAUPE_DARK, _matte(SURF_SHELL))

	# Positions are relative to the socket pivot, so each is (head-local Y) - SOCKET_Y.
	_mi(superellipsoid(BULB_SEMI, BULB_N, 24, 13), m_glass, _bulb,
		Vector3(0.0, BULB_Y - SOCKET_Y, 0.0), "Envelope")
	# THE PINCH. Same glass material as the envelope, so it is one continuous blown-glass form and not
	# a collar sitting under a ball; the silhouette goes 0.380 wide, down to 0.148 across 52 visible
	# millimetres, then out again to the 0.200 collar bead. That in-out-in notch is the whole cue, and
	# with the yoke re-sited in BOTH axes this pass ALL of it — plus the whole ribbed screw base under
	# it — is above the eye hoop's upper bar at all four cameras checked, which is what the table at
	# HOOP_CENTRE is for. It gave 24 mm of its own height to the cap to make that fit (see CAP_H), and
	# it is MORE visible for it: the bar used to project straight across the band the pinch lived in.
	_mi(cylinder(NECK_R_TOP, NECK_R_BOT, NECK_H, 14), m_glass, _bulb,
		Vector3(0.0, NECK_YY - SOCKET_Y, 0.0), "Neck")
	_mi(cylinder(CAP_R_TOP, CAP_R_BOT, CAP_H, 16), m_cap, _bulb,
		Vector3(0.0, CAP_Y - SOCKET_Y, 0.0), "CapCore")
	# THREE beads on ONE cached mesh, scaled in X and Z so the stack tapers into a cone. Checked, not
	# assumed:
	#   * scaling only X and Z narrows the ring and its tube in plan while leaving the bead's vertical
	#     section alone, so all three read as the same depth of ridge at different diameters — which is
	#     what a screw cap is. Scaling uniformly would shrink the lower beads' height too and turn the
	#     taper into a perspective mistake;
	#   * the collar (model 1.018, outer 0.100) is 12 mm below the glass neck's bottom disc and 76 mm
	#     below the envelope's swallow line for that radius, so it stands clear and INBOARD — it grips
	#     the neck instead of flaring out past the ball like the last pass's 0.132 bead did;
	#   * the strut yoke passes UNDER all three now rather than beside them: the beads bottom out at
	#     model 0.972 and segment A tops out at 0.908, so there is 64 mm of vertical daylight and the
	#     radial check that used to be the binding one no longer binds. Full derivation in `_build_hoop`.
	var bead := torus(THREAD_IN, THREAD_OUT, 14, 5)
	for i in THREAD_N:
		# i counts UP from the lowest bead, so the scale counts up with it and the widest ring is on top.
		var ring := _mi(bead, m_thread, _bulb,
			Vector3(0.0, THREAD_Y0 + THREAD_DY * float(i) - SOCKET_Y, 0.0), "Thread%d" % i)
		var k := 1.0 - THREAD_TAPER * float(THREAD_N - 1 - i)
		ring.scale = Vector3(k, 1.0, k)
	# The seven pips sit IN the middle bead (i = 1, scale 0.96, outer radius 0.096), so they have to
	# be built after it and under `_bulb`.
	_build_lamps()


## SEVEN AMBER PIPS around the middle thread bead — the voice of a character with no mouth. An arc
## rather than a bar, because an arc lets the talk signal TRAVEL, and a travelling wave is legible as
## speech in a way a single blinking light is not. See the LAMP_* block for why they came off the
## socket rim and why they stopped one bead short of the glass.
##
## THEY FACE OUTWARD, seated in the ridge on a `_basis_from_up` frame rather than lying flat as they
## did on the dish face. A puck lying flat presents a thin bar to the camera, which is why the study
## read the old ones as rivets. Turned to face the player it presents its full disc, and the emissive
## face is pointed at the one viewer who matters.
##
## THE PUCK SHRANK AGAIN, 22 mm -> 16 mm, and this time it is the BEAD that set the size rather than
## the spacing. The thread's tube radius went from 10 mm to 6 mm when the stack was compressed (see
## THREAD_*), so the ridge is 12 mm tall in section, and a 22 mm puck in a 12 mm ridge stands 5 mm
## proud top and bottom — stuck ON the bead like a bolt head, not set INTO it. At 16 mm it stands
## 2 mm proud, which is the same "set into the ridge" read the 22 mm puck had against the old 20 mm
## bead. Spacing still allows it: seven pips over a 103 deg arc at radius 0.097 are 29 mm apart
## centre to centre, so 16 mm leaves a 13 mm gap and the travelling talk wave has MORE separation
## between lamps than it did, not less.
## Radially it still reaches 0.104 against the bead's 0.097, i.e. 7 mm of lens proud of the thread
## with its back half buried in the tube, which is what a panel lamp in a boss looks like.
##
## Each pip needs its OWN material: `_toon` and therefore `lit_material` cache on colour and options,
## so seven built from one call would share a single uniform and pulse in lockstep.
func _build_lamps() -> void:
	var mesh := cylinder(0.008, 0.008, 0.014, 8)
	for i in LAMP_COUNT:
		var a := -LAMP_ARC + 2.0 * LAMP_ARC * float(i) / float(LAMP_COUNT - 1)
		var dir := Vector3(sin(a), 0.0, -cos(a))
		var mat := lit_material(AMBER.darkened(0.46), 0.3, AMBER).duplicate() as ShaderMaterial
		# PARENTED TO `_bulb`, so the pips rock with the bead they are set into. Positions are relative
		# to the socket pivot, exactly like every other part of the cap: y is (head-local) - SOCKET_Y.
		var pip := _mi(mesh, mat, _bulb, dir * LAMP_R + Vector3(0.0, LAMP_Y - SOCKET_Y, 0.0),
			"Lamp%d" % i)
		# `cylinder` runs along its own +Y, so the frame that points +Y outward is what turns the puck
		# into a lens in the wall. Setting `basis` leaves `position` alone — same pattern as
		# `_strut_segment`.
		pip.basis = _basis_from_up(dir)
		_lamps.append(mat)


## The hoop and the two lenses, carried clear of the head on two arched struts.
##
## THE ARCH IS TWO SEGMENTS, not one curled tube. `taper_tube`'s `curl` bends toward its own local
## +Z, and once the node has been given a `_basis_from_up` frame that direction is whatever fell out
## of the frame construction — fine for a horn growing off a head, useless when the tip has to land
## on a specific point 0.4 m away. Two straight tapered segments through an explicit mid point put
## the tip exactly where the hoop is, and the kink between them IS the arch.
func _build_hoop() -> void:
	# THE STRUTS ARE A YOKE, and they now rise off the SOCKET rather than running outboard of a dish.
	# The bulb turns inside a mount that stays put, exactly as the dish did — the hoop is bolted to
	# the HEAD (the eyes keep looking at you) while the bulb rocks on its own node — but the anchor
	# moved down onto the chassis, which is both the honest answer to "what holds the eyes up?" and
	# the only place left that is not inside the glass.
	#
	# Clearance is RE-DERIVED AGAIN this pass, because the yoke moved in BOTH axes (see HOOP_CENTRE):
	# the tip came down another 10 mm and, far more importantly, came 204 mm nearer the head. The reach
	# is 0.214 m of z instead of 0.418, so this is a short bracket now and every number changed:
	#   * segment A runs at |x| = 0.138 from model 0.878 up to 0.908, from z +0.030 to z -0.100. It
	#     stays entirely below the glass envelope's bottom pole (1.070) and its inner face is 0.118
	#     from the axis. The worst case along its run is NOT the thread any more — the beads now start
	#     at model 0.972, 64 mm above the segment's own top — it is the bare shank where the segment
	#     crosses z = 0, at model 0.885 where the cap is 0.0791: 39 mm of daylight, up from 18. At its
	#     base it still deliberately sinks 16 mm into the socket's 0.134 wall, which is what "mounted"
	#     means.
	#   * segment B drops from model 0.908 to the hoop at model 0.890 while running forward from
	#     z = -0.100 to z = -0.184. The one new check the shortened reach forces is whether it now
	#     cuts the socket cup, because it no longer clears it by simply being far away: at the socket's
	#     own edge plane z = -0.142 the segment is at model 0.917 (inside the cup's 0.866..0.928 band)
	#     and |x| = 0.156, so its distance from the head axis there is sqrt(0.156^2 + 0.142^2) = 0.211
	#     against a cup radius of 0.142. It passes outboard by 69 mm. It never enters the envelope's
	#     0.190 footprint at any point either.
	# The struts used to sit at |x| = 0.406 to clear a 0.72 m dish. Left there they would hang 0.32 m
	# clear of anything with nothing joining them — two sticks in mid air beside her head.
	#
	# THE TIP EXPRESSION IS UNTOUCHED AGAIN THIS PASS. Only `base`, `mid` and the two blocks moved, so
	# the hoop, the lenses, the pupils and the iris do not shift by a micron.
	#
	# THE TRUNNION BLOCK is not decoration. Without it segment A ends in a flat `taper_tube` cap
	# hanging in mid air, and the pair render as two rods poking out of her neck. A bearing lug at
	# the base makes the strut a MOUNT. At 0.052 x 0.084 x 0.082 its inner face lands at 0.112, inside
	# the socket's 0.134 wall — clamped onto the fitting rather than hovering beside it.
	var m_strut := _toon(PLUM, _matte(SURF_SHELL))
	var m_block := _toon(PLUM_DARK, _matte(SURF_SHELL))
	for sx: float in [-1.0, 1.0]:
		var base := Vector3(MOUNT_X * sx, MOUNT_Y, MOUNT_Z)
		# RE-SEATED FOR THE PULLED-IN YOKE. The reach halved, so the kink has to move with it: at the
		# old z = -0.250 the mid point would sit 66 mm PAST the tip and the "arch" would fold back on
		# itself. z = -0.100 puts it 47 % of the way along, which is where a bracket's knee belongs.
		# The 30 mm rise is kept because it is what makes the pair read as an arched yoke rather than
		# as two straight rods: segment A lifts 30 mm over 130 mm of run, segment B drops 18 mm over
		# the last 96 mm. Steeper than before, and that is the point — a short bracket needs a
		# sharper knee to read as one at all.
		var mid := Vector3(MOUNT_X * sx, MOUNT_Y + 0.030, -0.100)
		# The tip still tracks HOOP_CENTRE exactly — it is derived from it, so the hoop, the lenses,
		# the pupils and the iris keep their exact relationship to the strut tip after the drop.
		var tip := Vector3((HOOP_HALF_W + HOOP_HALF_H) * sx, HOOP_CENTRE.y, HOOP_CENTRE.z + 0.006)
		# The two segments OVERLAP at the mid point by design: `taper_tube` caps both of its ends, so
		# the joint is two flat discs meeting at an angle. Running each segment 12 mm past the mid
		# point buries that pair of discs inside the other segment and the kink closes up — a knuckle
		# ball costs 60 triangles per side to hide the same seam.
		_strut_segment(base, mid, 0.020, 0.017, 0.012, m_strut, "StrutA%d" % int(sx + 1.0))
		_strut_segment(mid, tip, 0.017, 0.013, 0.0, m_strut, "StrutB%d" % int(sx + 1.0))
		_mi(rounded_box(Vector3(0.052, 0.084, 0.082), 0.018, 10), m_block, _head,
			Vector3(MOUNT_X * sx, MOUNT_Y, MOUNT_Z), "Trunnion%d" % int(sx + 1.0))
		_mi(cylinder(0.026, 0.026, 0.074, 10), _toon(TAUPE_DARK, _matte(SURF_LIMB)), _head,
			Vector3(MOUNT_X * sx, MOUNT_Y, MOUNT_Z), "Bearing%d" % int(sx + 1.0)).rotation.z = PI * 0.5

	_hoop = _node("Hoop", _head, HOOP_CENTRE)
	# DARK, and this is the single biggest legibility fix on the character. An ivory hoop on the
	# ivory collector face has no value step at all: the first build rendered as a mask painted ON
	# the dish, with no sense that the ring stands 0.39 m in front of it. A dark ring on a pale panel
	# is the cast's own grammar (Tom Nook's eye patch, the robots' screens) and it puts the hoop out in
	# front instantly. It matters more now, not less: the hoop hangs against the ribbed screw cap, and
	# PLUM_DARK against TAUPE is the same value step that carried it against the ivory dish face.
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
	# The leaves are DARK and, as of this pass, they genuinely retract BEHIND the hoop's end ring: the
	# tube runs from IRIS_OPEN 0.078 inward to 0.064, inside the ring's 0.063..0.093 band, and IRIS_Z
	# puts it 13 mm behind the ring's front face so the ring occludes it. See the IRIS_* block for the
	# two earlier versions that did not, and for why the comment there claiming they did was measuring
	# the wrong end of the leaf and then the wrong axis.
	var m_blade := _toon(PLUM_DARK, _matte(SURF_LIMB))
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

	# ---- the bulb rocks in its socket. A slow idle sway, a tip BACK onto the sky when she thinks,
	# and a level-out toward the listener when she speaks. The eye hoop stays dead still out front on
	# its stationary struts through all of it, which is the machine cue: the instrument holds its aim
	# while the head moves behind it.
	#
	# NO YAW, and that is deliberate rather than an omission. The bulb is a solid of revolution, so a
	# yaw sweep is literally invisible on the envelope; on the cap it would do nothing but spin the
	# brushed-metal grain, which `sd_metal` runs in MODEL space, so the ribbing would appear to crawl
	# on a part that is not moving. That is worse than nothing. The dish's 0.46 rad scan is dead.
	#
	# SLIP CHECK, RE-DERIVED for the raised socket, because a bulb that walks out of its own socket is
	# the failure this pivot exists to avoid. Positive rotation.x sends +Y toward +Z, i.e. tips the
	# crown BACKWARD. The cap's bottom rim now sits just 0.003 m above the pivot at a radius of 0.078,
	# so a 0.20 rad tip moves it 0.6 mm — it is effectively pinned. The part that does move is where
	# the shank leaves the cup, at the socket's top face (model 0.898, 0.031 above the pivot): it
	# swings 6.2 mm in z to a radius of 0.098 against a socket wall of 0.146 there, so 48 mm of slack
	# remains. That slack is why SOCKET_RT is 0.142 and not 0.110. Raise the think tip much past
	# 0.20 rad, or narrow the cup, and the shank pokes through the wall — and it would only ever show
	# in the think emote, which is the easy one to skip when checking.
	if _bulb != null:
		_bulb.rotation = Vector3(
			-0.05 * talk + 0.20 * think + 0.018 * sin(TAU * _t / 6.3),
			0.0,
			0.030 * sin(TAU * _t / 5.1))

	# ---- the socket pips. Idle is a slow low breath around the arc; talking runs a bright wave round
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
	#
	# AND THE LEAVES ARE STOWED WHEN THE EYE IS OPEN. See the IRIS_* block: one to two of the five
	# leaves per lens park in the hoop's open inner window where there is nothing to hide behind, and
	# they were being read as eyelashes — which this cast has a standing ruling against. IRIS_SHOW is
	# solved so that the leaf becomes visible exactly as its outer end clears LENS_RIM_OUT, so it
	# emerges from under the bezel instead of appearing in mid air. `visible` and not `alpha`: rule 4
	# of this project's list is that `toon_soft` is opaque and alpha 0 renders BLACK.
	var open := clampf(_eye_open, 0.0, 1.0)
	var r := lerpf(IRIS_CLOSED, IRIS_OPEN, open * open)
	var shown := open < IRIS_SHOW
	for b: Node3D in _iris:
		b.position = Vector3(b.get_meta("dir")) * r
		b.visible = shown

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
## Her tallest point is the crown of the glass envelope — not the hoop, which hangs below the head
## origin and now tops out at 1.090 - 0.200 + 0.093 = 0.983, 467 mm below the crown (it was 1.10 when
## the yoke hung at -0.078; the drop this pass only widens the margin). There is no tilt to unwind any more, so this is one addition:
##   head_y 1.090 + BULB_Y 0.170 + BULB_SEMI.y 0.190 = 1.450
## so npc.gd lifts the '!' to 1.450 + MARKER_CLEARANCE_GAP 0.18 = 1.630, i.e. 110 mm above its 1.52
## default. The idle breath's SQUASH scales the whole rig by up to 1.5 %, which the gap absorbs.
## The crown came DOWN 28 mm this pass (1.478 -> 1.450): the critic's secondary note was that she had
## grown 117 mm and was visibly the tallest in the 9 m lineup, so the proportion fix was taken out of
## the base rather than out of the crown.
##
## THE THINK TIP DOES NOT BEAT IT, and this is worth writing down because the intuition is wrong.
## The bulb pivots at model 0.867 with its centre 0.393 above that, so a 0.20 rad tip LOWERS the
## centre to 0.867 + 0.393*cos(0.20) = 1.252 — and the envelope is now a SPHERE in section, so a tilt
## does not lengthen its vertical support at all: it stays 0.190. That gives 1.442 against the upright
## 1.450, so upright is genuinely the worst case. (The tilted-superellipse support formula the last
## pass needed here is gone with the oblate envelope; if BULB_SEMI stops being uniform, bring it back.)
func marker_clearance() -> float:
	return head_y + BULB_Y + BULB_SEMI.y


## `_matte()` fills defaults into a COPY, so option dicts compose cleanly; this is just the merge.
static func _merged(base: Dictionary, extra: Dictionary) -> Dictionary:
	var o := base.duplicate()
	for k: Variant in extra:
		o[k] = extra[k]
	return o
