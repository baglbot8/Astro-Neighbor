class_name AstronautModel
extends Node3D
## The astronaut: procedural geometry + a procedural pose-blending animation system.
## Origin at the feet, faces -Z, 1.4 m tall in Animal Crossing chibi proportions: the opaque
## helmet is 0.47 of the height (see HELMET_SCALE) and there is no neck.
##
## ART DIRECTION REVISION 2 (docs/STYLE_GUIDE.md R2.2). The user's note was
## *"the characters faces look too much like a cute kids tv show like cocomelon and flat pressed
## into the glass mask ... Maybe the astronauts mask is just navy blue like you cant see through
## it"*, so the visor is now an OPAQUE navy pane and there is no face, no head, no hair and no
## see-through-glass machinery behind it. Everything this character expresses, it expresses with
## its body: posture, weight, the swing of the arms, the tilt of the helmet, and one small status
## lamp on the helmet rim. All 14 states still read — see `_compute_target`.
##
## Usage (Player and NPC mannequins):
##   model.set_state("walk")            # idle walk run jump fall land talk wave happy think dance surprised carry_idle carry_walk boost
##   model.tick(delta, speed_factor)    # every frame; speed_factor 1 = walk speed, ~1.67 = run
##   model.set_lean(forward, side)      # lean from acceleration (radians, small)
##   model.set_carry_item(mesh)         # held in both mittens in front of the chest (null clears)
##   model.set_boost_thrust(k, vel)     # 0..1 jetpack thrust + the astronaut's world velocity
##   model.apply_style(dict)            # or let it follow GameState.player_style (default)
## Signals: footstep(foot) on each foot plant while walking/running, emote_finished(name).
##
## "boost" is the 15th state, added for the jetpack (docs/STYLE_GUIDE.md R2.8). The other 14 and
## every other entry point are unchanged, so NPC Stella and the clothes-store mannequin keep working
## without knowing the jetpack exists.

const SHELL_SHADER := preload("res://src/player/astro_shell.gdshader")
const VISOR_SHADER := preload("res://src/player/astro_visor.gdshader")

signal footstep(foot: int)
signal emote_finished(emote: String)

## When true the model re-reads GameState.player_style on EventBus.player_style_changed.
@export var follow_game_state: bool = true
## Optional style override used when follow_game_state is false (keys as in GameState.player_style).
@export var style_override: Dictionary = {}

## ---- Animal Crossing chibi proportions (docs/STYLE_GUIDE.md "Character rules"). Total ~1.42 m,
## helmet half of it, so the silhouette is a two-heads-tall plush.
const HEIGHT := 1.42
## ---- THE BUBBLE (docs/STYLE_GUIDE.md R2.7). The user: *"The astronaut character reads more like a
## scuba diver."* The diagnosis in R2.7 is exact — the old helmet was a tight shell HUGGING the head
## with a small window, which is a wetsuit hood with a dive mask. Every reference
## (reference/"astronaut 1-3.jpeg") instead has a big rigid bubble sitting ON a visible neck ring,
## clearly wider than the head and than the shoulders are thick, with a large visor filling the
## front. So the dome is now:
##   * wider (0.744 across, 1.44x the torso's 0.515 width) and near-spherical (AstroShapes.SHELL_EXP
##     dropped 2.4 -> 2.1 — the flat-sided squircle is what read as a moulded hood);
##   * lifted so its base narrows INTO a real collar assembly (see `_build_collar`) instead of
##     merging straight into the shoulders;
##   * fitted with a window that is bigger AND tilted DOWN, leaving a clean crown of shell above it.
##     A window centred on the dome's own equator, with white shell all the way round it, is the
##     single strongest "dive mask" cue there is.
##
## SIZE PASS (2026-09-05, integration critic + orchestrator): *"The helmet is very large relative
## to the body — proportionally bigger than in any of the three references, which reads slightly
## bobblehead. Consider bringing it down a notch or giving the torso a little more mass."* Measured
## on reference/"astronaut 3.jpeg" (the only reference standing straight enough to measure): the
## dome runs y 87..300 px of a 87..545 figure, i.e. **46 % of total height**, and ours was 0.712 of
## 1.42 = **50 %**. So the dome is scaled by HELMET_SCALE and the torso takes the freed 4 cm back as
## height, which lands the dome at 47 % and the helmet-to-torso width ratio at 1.44x (was 1.62x).
## BOTH halves of that matter: shrinking the helmet alone would just make a smaller plush, and the
## style guide's "from the gameplay camera the head must look bigger than the body" still holds.
## Every collar number below is the old one scaled by the same factor and re-seated on the new dome
## base, so the "barrel swallowed by the bubble" relationship in `_build_collar` is preserved exactly.
const HELMET_SCALE := 0.94
const HELMET_R := Vector3(0.372, 0.335, 0.363)
const HELMET_CY := 1.087       # dome centre: base at 0.752 (inside the collar), crown at 1.422
const SHELL_THICK := 0.014
## Half-angle of the round front window. sin(44°) = 0.695 → the window spans ~70 % of the dome width.
const WINDOW_ANGLE := 0.7679   # deg_to_rad(44.0)
## Downward pitch of the window's axis. 11° puts the visor's top edge 0.16 m below the crown and its
## bottom edge just above the collar, which is the proportion every reference uses.
const WINDOW_TILT := 0.1920    # deg_to_rad(11.0)
## Ring index (of RING_HELMET) at which the dome would change colour, or -1 for one colour.
## Currently -1: the rear value zone is a latitude BAND (see `_build_helmet`), because a concentric
## split always produces a disc on the back of the head and that read as a beanie.
const HELMET_SPLIT_RING := -1
const NECK_Y := 0.726          # helmet pivot = torso top; there is NO neck
## ---- Collar / neck ring. R2.7 point 1: "meeting the suit at a visible collar/neck ring — a
## distinct band, not a smooth blend. This single change is most of the fix." The dome's base at
## y 0.71 is a point and the surface has only narrowed to r ≈ 0.18 by y 0.742, so a 0.185 m barrel
## from the shoulders up to COLLAR_TOP is swallowed by the bubble at the top and shows as a real
## neck below it, with the flange ring clamped around the narrowing.
## All four numbers are the pre-HELMET_SCALE ones scaled by HELMET_SCALE about the dome base, so the
## smaller bubble swallows exactly as much of the barrel as the old one did.
const COLLAR_BASE := 0.686     # bottom of the barrel, buried in the torso bean
const COLLAR_TOP := 0.794
const COLLAR_R := 0.172
const COLLAR_RING_Y := 0.774
const COLLAR_RING_OUTER := 0.209
const PELVIS_Y := 0.325
## The torso takes back the height the dome gave up, plus a little width and depth. 69 % of the
## helmet's width and 66 % of its height (was 64 % / 53 %): the bean is now a body the bubble sits
## on rather than a stalk it balances on. Cross-checked against reference/"astronaut 2.jpeg", whose
## torso is visibly deeper than half the dome.
const TORSO_SIZE := Vector3(0.515, 0.44, 0.395)
## Vertical offset of the bean's centre inside the Torso node (its top lands at NECK_Y).
const TORSO_MESH_Y := 0.181
const HIP_X := 0.098
## Relative to the pelvis. The shoulders stay at the SAME height they have always been (abs 0.575):
## the taller bean grows upward into the collar, so the arms simply hang from a little lower down
## the chest, which is where every reference has them — and the measured carry pose, the arm-reach
## clamp and the walk cycle's amplitudes all stay valid. Only the sideways offset follows the wider
## bean, by exactly the half-width it gained.
const SHOULDER := Vector3(0.224, 0.25, 0.0)
## Arm segments. The arm is two short capsules with an elbow between them: without a joint there is
## nothing for the follow-through in the walk cycle to lag behind (docs/STYLE_GUIDE.md R2.4 asks for
## "arms swinging from the shoulder with a lagging elbow"). Lengths add up to the old single stub.
const ARM_UPPER_Y := -0.062    # upper-arm capsule centre, relative to the shoulder
const ELBOW_Y := -0.122        # elbow pivot, relative to the shoulder
const FORE_Y := -0.055         # forearm capsule centre, relative to the elbow
const HAND_LOCAL_Y := -0.113   # mitten, relative to the elbow
const HAND_Y := -0.235         # total shoulder-to-mitten reach: the mittens land at the suit hem
const HAND_R := 0.072          # 0.144 across ≈ 0.10 H mitten
const LEG_PIVOT_TO_FOOT := 0.30
const ARM_REST_ROLL := 0.55
const ELBOW_REST := 0.16
const CARRY_STATES := ["carry_idle", "carry_walk"]
## Hoisted out of _apply_pose: NPCs share this model and the literal allocated an Array every frame.
const MOVING_STATES := ["walk", "run", "carry_walk"]
const EMOTE_DURATIONS := {"wave": 1.3, "happy": 1.5, "think": 1.8, "dance": 2.8, "surprised": 1.1}

## ---- Arm safety envelope. The mittens live one short arm-length from the shoulder and the helmet
## is enormous, so an unclamped raised arm drives the upper-arm capsule and the mitten straight
## through the opaque shell (a hard white wedge and a dither band across the dome). These two caps
## keep the whole arm outside the helmet ellipsoid in every pose; see `_clamp_arm_reach`.
const MAX_ARM_STRETCH := 1.60
const MAX_ARM_ROLL := 2.45
## How much the roll ceiling tightens per unit of extra stretch (a longer arm reaches the dome sooner).
const ARM_ROLL_STRETCH_PENALTY := 1.6
const MIN_ARM_ROLL_CEIL := 0.9

## ---- Two-handed carry, measured so the item sits BETWEEN the mittens instead of floating over
## the helmet. Both mittens land on the item's side faces at chest height, in front of the body.
const CARRY_ROLL := 0.42
const CARRY_PITCH := 1.4347
const CARRY_YAW := -0.457
const CARRY_STRETCH := 1.545
## Item origin (its bottom face; callers pass half the item height as the offset, as before).
const CARRY_ANCHOR := Vector3(0.0, 0.38, -0.36)

## ---- Suit albedo. docs/STYLE_GUIDE.md: "Darken every base albedo by roughly 20-25% and let light,
## not albedo, create brightness", and REVISION 2 asks for another notch down (value mean
## 0.66-0.76). A pure #f4f4f8 suit clipped to literal (255,255,255) at noon — 43% blown highlights,
## no value gradient on the dome, a white marshmallow at gameplay distance.
## The tint is WARM, not neutral: Animal Crossing's own whites are cream. Measured off the AC player
## in reference/"AC Reference 2 copy.jpg", the jacket is #f0ead2 (S 0.13) and the cap #f7e6d0
## (S 0.16) — a dead-neutral white is the thing that reads as untextured plastic.
const SUIT_DARKEN := 0.19
const SUIT_TINT := 0.62
const SUIT_TINT_COLOR := Color("#ecd9a4")
## Default opaque visor navy, exactly the colour the user asked for. `visor_tint` tints THIS now.
const VISOR_NAVY := Color("#1b2450")

## ---- THE DOME / VISOR CONTRAST LAW (integration critic, BLOCKING).
## Wearing the shop's Deep Space Suit (`#2e3760`) the helmet shell rendered at #191b33 (V 0.20)
## while the visor pane rendered at V 0.31 — **the window was LIGHTER than the shell**, so the
## character's single most important read vanished and the head was one black ball from every
## angle. Three of the wardrobe's 17 suits are dark enough to do this and several more get close.
##
## The fix is two rules that hold for ANY suit colour a shop, a save file or a mannequin hands us:
##
##   1. **The dome has a floor.** Every reference astronaut has a light dome regardless of what the
##      rest of the suit is doing, and the Deep Space Suit's own shop icon is navy-with-CREAM. So
##      the helmet shell (and only the shell — the body keeps the player's colour at full strength)
##      is lifted to at least DOME_MIN_V, keeping its hue and shedding chroma in proportion, which
##      turns a midnight navy into a pale slate-navy shell rather than into white.
##   2. **The visor is derived from the dome, never fixed.** The pane's value is capped at
##      VISOR_V_RATIO of the dome's AND at least VISOR_MIN_DROP below it, floored at VISOR_MIN_V so
##      it never crushes to black. Whatever the dome does, the window is a distinctly darker hole.
## `_dome_albedo` and `_visor_color` are static and pure, so the relationship can be unit-checked
## without rendering (see `report_wardrobe_contrast`).
const DOME_MIN_V := 0.66
const DOME_MAX_S := 0.34
const VISOR_V_RATIO := 0.38
const VISOR_MIN_DROP := 0.30
const VISOR_MIN_V := 0.11

## ---- Torso colour blocking. The bean is one mesh with a flat seam: cream suit above, the dark
## lower-torso assembly below. R2.7 point 8 asks for an off-white suit, and the dark block is the
## hip assembly.
##
## Ring 7 of 10, was 6, and the reason is the orchestrator's second note: *"The large blue block on
## the torso is not in any reference; all three are cream-dominant with orange accents only, and
## that blue is the last thing pulling toward a wetsuit. Try reducing it to a yoke or trim."* That
## is correct against the references and it is easy to check: at ring 6 the indigo covered the bean
## from y 0.286 to 0.425 — 0.139 m, a third of the whole torso and the largest single colour field
## on the character after the cream. At ring 7 it is 0.089 m, a hip band the belt sits on, and the
## legs and boots still carry the dark value anchor the palette needs. Cream gains the belly back.
const TORSO_RINGS := 10
const TORSO_SPLIT_RING := 7
## Ring the accent belt band rides (see `_build`), independent of the colour seam.
const BELT_RING := 6

## ---- Accent bands (R2.7 point 4). *"Orange/amber accent bands on the limbs — a ring at the bicep
## and forearm, at the thigh and shin, and around the boot cuffs. The references use 4-8 of these.
## Ours has piping down the torso instead, which reads as a wetsuit zip. Bands around limbs, not
## stripes down the middle."* Eight rings per astronaut: bicep, forearm, thigh, shin (x2 sides).
## Each is a flattened torus sized to the limb it rides, so it reads as a band and not as a hoop.
const BAND_HEIGHT := 0.030
## Amber, and the most the band hue may travel toward it (see `_band_hue`).
const BAND_HUE_TARGET := 0.0833   # 30 deg
const BAND_HUE_PULL := 0.055      # 20 deg

## ---- R2.9 SURFACE TEXTURE. The user: *"I want to minimize larger surfaces on important things
## that dont have a 'texture' to them, so that nothing looks too flat / cheap. Notably things like
## the astronaut's helmet/clothes"* — and this character is the headline example, so every surface
## that is large on screen carries material character. It all comes from the SHARED library
## (src/shaders/surface_detail.gdshaderinc, docs/OPEN_ISSUES.md item 18) via astro_shell.gdshader,
## which #includes it and calls the same sd_cloth / sd_metal / sd_sheen / sd_cloth_sheen functions
## the rest of the game uses. Nothing here is a private reimplementation.
##
##   CLOTH  suit torso, sleeves, forearms, thighs, shins, the collar barrel and the seam rings
##   METAL  the helmet dome, the rear shell segment, the ear pods, the neck-ring flange, the chest
##          panel and the life-support pack — the character's hard parts
##   RUBBER gloves, boot shells and soles — sd_metal's grain and micro-scuffs with the sheen OFF,
##          plus a moulded welt seam, so the gauntlets and boots read as a different MATERIAL from
##          the sleeve above them and not merely as a different colour (see SURF_RUBBER, and the
##          report: the shared library has no `sd_rubber` and `sd_rock` is authored for cliffs)
##   none   the eight accent bands, the visor rim, the jet puffs and every small trim piece. R2.9:
##          *"Non-important things like decor items and small pieces dont necessarily need this."*
##   The VISOR keeps its gloss and its own shader. Per R2.9, glass is the one place a real highlight
##   belongs, so it gets no weave and is not made matte.
##
## THE FADE DISTANCES ARE THE WHOLE BALLGAME. The library's fine patterns are ~190 cycles/m (cloth)
## and ~320 cycles/m (metal brush). At the 6.5 m gameplay camera a 0.09 m limb is about 24 px wide,
## so those patterns land well past Nyquist and would sparkle as the astronaut walks — the exact
## moire the library's header warns about and that already had to be fixed once on the planet
## ground. So the fine detail is faded out between SURFACE_NEAR and SURFACE_FAR, i.e. it is at full
## strength at conversation range and gone before the gameplay camera. What survives to 6.5 m is the
## LOW-frequency half: the seams (SEAM_FAR) and the sheen (SHEEN_NEAR/SHEEN_FAR), neither of which
## can alias. Measured with tools/hf_noise.py at both distances; see the builder report.
const SURFACE_NEAR := 1.4
const SURFACE_FAR := 5.0
## The sheen is a broad lobe that cannot alias, so it runs much further out — and it fades
## continuously to zero rather than sitting on the library's 0.20 floor, which would pop off the
## helmet the moment the fine lod reached 0.
const SHEEN_NEAR := 6.0
const SHEEN_FAR := 22.0
## Seams run much further out, and they are the half of R2.9's cloth row that has to do the work in
## actual play. `CameraRig.DIST_MIN` is 4.0 m and `DIST_MAX` 10.0, so the player never gets closer
## than 4 m: at 190 cycles/m the weave needs about 570 px/m to stay above Nyquist and only has 217
## at 4 m, which is why it is faded to nothing long before then. A 7-rings/m seam is a 0.14 m
## period — 19 px at 6.5 m and still 12 px at the 10 m zoom-out — so it can never alias, and at
## SEAM_FAR = 14 it is still at 68 % strength at the gameplay camera. R2.9 asks for exactly this
## split: "a fine woven weave AT CLOSE RANGE THAT FADES OUT WITH DISTANCE ... seams and stitching
## where panels meet".
const SEAM_FAR := 14.0
## Matches the `surface_kind` numbering in surface_detail.gdshaderinc / toon_soft.gdshader.
const SURFACE_KINDS := {"none": 0, "cloth": 1, "metal": 2, "wood": 3, "rock": 4, "foliage": 5}
## Per-material R2.9 option blocks, so the big cloth surfaces cannot drift apart by accident.
## Ring spacing is in seams per metre of the part's own long axis: 7/m is a seam every 14 cm, which
## on a 0.30 m leg is the two-panel construction the references show, and 4 gores is the standard
## pressure-garment panel count. `seam_gore_phase` defaults to half a period in the shader, so a
## gore can never land on the centre-front of the torso — that is the placket R2.7 calls a zip.
const SURF_CLOTH := {"surface": "cloth", "sheen": 0.13, "seam": 0.85, "seam_rings": 7.0, "seam_gores": 4.0}
## The torso is one big bean, so it gets fewer, wider panels than a limb does.
const SURF_CLOTH_TORSO := {"surface": "cloth", "sheen": 0.13, "seam": 0.85, "seam_rings": 5.0, "seam_gores": 6.0}
## Metal hardware. `sheen` is well under the library's own 0.20: the dome is the largest and
## lightest surface on the character and R2.6 forbids buying detail with a hotspot.
const SURF_METAL := {"surface": "metal", "surface_strength": 0.8, "sheen": 0.11}
## The dome specifically — the single biggest smooth surface in the game and the one the user named.
## Strength is pulled down again because a cream sphere shows grain far more readily than a plate.
const SURF_DOME := {"surface": "metal", "surface_strength": 1.3, "sheen": 0.35, "seam": 0.85, "seam_rings": 3.0, "seam_gores": 0.0, "seam_far": 16.0}
## RUBBER — gloves, boot shells and soles. There is no `sd_rubber` in the shared library yet (this
## is the one addition the report asks for), so this is `sd_metal`'s fine grain and micro-scuffs
## with the sheen turned OFF and a moulded welt seam over it: a matte speckled shell, which is what
## a rubber gauntlet or boot is. `sd_rock` was tried first and is the wrong tool at this size — its
## two scales are 6.5 and 46 cycles/m, authored for a cliff, and across a 0.24 m boot that is 1.5
## and 11 cycles, so at any sane strength it moved the rendered albedo by under 3% and the boots
## stayed visibly flat. (It also spends most of its budget on ROUGHNESS, which this shader's custom
## light() never reads — see the report.)
const SURF_RUBBER := {"surface": "metal", "surface_strength": 1.0, "sheen": 0.0, "seam": 0.9, "seam_rings": 16.0, "seam_gores": 3.0}

## ---- Tessellation. docs/OPEN_ISSUES.md issue 4: this model was 23,408 tris against a 6,000
## character budget, and NPC Stella instances it. Deleting the head bought 4.5k, sealing the helmet
## with an opaque pane bought another 2.1k (the inner lining existed only to be seen through the
## glass), and the rest is this table. Every number is the coarsest that still looks smooth at the
## close-up showcase distance, checked frame by frame.
const SEG_HELMET := 30
const RING_HELMET := 11
const RING_VISOR := 3
const SEG_RIM := 26
const SIDES_RIM := 3
const SEG_TORSO := 16
const SEG_LIMB := 8
const RINGS_LIMB := 1
## Hardware (pods, nozzles, valves, dials) is small on screen and does not need limb tessellation.
const SEG_HW := 10
const SEG_HW_SMALL := 7

## Pose channels. Everything the animation system drives is one float per channel so states blend by lerp.
enum P {
	BODY_X, BODY_Y, BODY_Z, SQUASH,
	PELVIS_ROLL, PELVIS_PITCH, PELVIS_YAW, TORSO_ROLL, TORSO_YAW,
	HEAD_PITCH, HEAD_YAW, HEAD_ROLL,
	ARM_L_PITCH, ARM_L_ROLL, ARM_L_YAW, ELBOW_L,
	ARM_R_PITCH, ARM_R_ROLL, ARM_R_YAW, ELBOW_R,
	LEG_L_PITCH, LEG_R_PITCH, LEG_L_ROLL, LEG_R_ROLL, LEG_L_LIFT, LEG_R_LIFT,
	ARM_STRETCH, LAMP,
	COUNT,
}

# ============================================================================= locomotion tuning
## docs/STYLE_GUIDE.md R2.4: *"The walking also looks a bit stiff like a waddle."* The old cycle was
## a single sine on every channel, all in phase, with the body bobbing symmetrically — a metronome,
## which is exactly what "mechanical waddle" means. The rebuild below adds the four things that make
## a walk read as weight: a lateral shift onto the planted foot, shoulders counter-rotating against
## the hips, an arm swing that settles at each end with the elbow a beat behind, and a helmet that
## arrives last. Amplitudes are tuned for the GAMEPLAY camera (6.5 m, character ~85 px tall), where
## a previous "correct-looking" close-up bob measured ~1.5 px on screen and read as gliding.
const WALK_LEG_AMP := 0.52
const RUN_LEG_AMP := 0.92
## Stride cadence, in full leg cycles per second, at walk speed and at run speed.
##
## THE PLAYER, after playing the build: *"The dashing animation looks strange. Can we just make it a
## run animation faster leg movements and arms spread wide and slightly behind?"* — and "faster leg
## movements" is the first half of the fix. The cadence used to be a single `2.8 * sqrt(speed)`
## curve, which at run speed (speed_factor 1.667) gave 3.61 cycles/s against the walk's 2.80: the
## legs were only **29 % faster** while the astronaut was moving **67 %** faster, so the extra speed
## went almost entirely into a longer, slower, floatier stride. That is what reads as a "dash" — the
## character glides and paddles rather than sprinting.
##
## 5.0 makes the run 79 % faster than the walk, which is unmistakable, and it also makes the feet
## LESS wrong: 7.0 m/s at 5.0 cycles/s is 1.40 m per step against the walk's 1.50 m, where the old
## 3.61 needed a 1.94 m step and slid the boots visibly. Footsteps fire twice per cycle, so this is
## also the sprint footstep rate.
const WALK_CADENCE := 2.8
const RUN_CADENCE := 5.0
## Lateral shift of the pelvis onto the stance foot, in metres.
const WALK_WEIGHT_SHIFT := 0.030
const RUN_WEIGHT_SHIFT := 0.018
## Phase lag (radians of stride) between the foot plant and the weight arriving over it.
const WEIGHT_LAG := 0.38
## Shoulders turn AGAINST the hips. Applied on top of the pelvis yaw, so the net shoulder rotation
## is -TORSO_COUNTER times the hip rotation; equal-and-opposite reads robotic, 0.5 reads human.
const TORSO_COUNTER := 0.50
## How far behind the shoulder swing the elbow trails.
const ELBOW_LAG := 0.95
const ELBOW_SWING := 0.34
## How far behind the body the helmet's own bob and roll run.
const HEAD_LAG := 0.70
## Asymmetry between the left and right step, so the cycle is not a perfect metronome.
const STEP_ASYMMETRY := 0.075
## Warp of the vertical bob: the body drops fast onto the planted foot and rises slowly off it.
const BOB_WARP := 0.5
## Run silhouette, straight from the user: *"Running should have his hands spread out and slightly
## behind him"*, restated after playing as *"arms spread wide and slightly behind"*. Roll swings the
## arm out to the side; because Node3D uses YXZ euler order, YAW is what sweeps an already-spread
## arm backwards (pitch does almost nothing once roll ≈ 90°).
##
## WHY THIS WAS STILL WRONG, and it is not what the pose *is* - it is what the pose *does*. The
## previous version reached this silhouette and then FROZE in it: at full run blend the only arm
## motion left was ±0.16 rad of pitch (a no-op at roll 1.34, see above) and ±0.07 rad of roll. Ten
## consecutive frames from behind at 6.5 m are in ~/.astro_captures/strips/before_run.png and the
## arms are pixel-identical across all of them. A sprinting character whose arms do not move reads
## as gliding, hovering, or the "Naruto run" — which is exactly the *"looks strange"* in the note.
## So the base pose is kept and a real alternating drive is added on top of it, phased against the
## legs (the arm on the same side as the forward leg sweeps BACK).
##
## Two other numbers moved for the same complaint, both about what the camera actually sees. The
## player is behind the astronaut essentially all the time, and an arm swept 42 deg back points
## partly AT that camera, so it foreshortens to a stub: 0.74 rad projected only 0.67 of the arm's
## length onto the screen's horizontal. 0.50 rad is still clearly "slightly behind" in profile and
## projects 0.93 — a 39 % wider arm from the angle that matters. And the elbow went from 0.10
## (a straight, rigid wing) to a slight, moving bend.
const RUN_ARM_ROLL := 1.28
const RUN_ARM_YAW := 0.50
const RUN_ARM_PITCH := -0.34
const RUN_ARM_ELBOW := 0.26
## Amplitudes of the alternating drive, in radians, all in phase with the legs via `shape`.
## Roll raises and drops each arm (vertical read from behind), yaw sweeps it back and out (lateral
## read from behind), and they are deliberately both large: the mitten is only 0.235 m from the
## shoulder, so at 6.5 m a swing has to be big in angle to be worth anything in pixels.
const RUN_ARM_ROLL_SWING := 0.26
const RUN_ARM_YAW_SWING := 0.42
const RUN_ARM_PITCH_SWING := 0.16
const RUN_ELBOW_SWING := 0.17
## The arms extend slightly at a sprint, which widens the silhouette without touching the pose.
## Stays well inside the roll ceiling `_clamp_arm_reach` allows at this stretch (2.19 rad).
const RUN_ARM_STRETCH := 1.16
## Outward splay of the legs at a sprint. From directly behind, a leg that swings straight fore/aft
## is invisible; a little roll throws each boot out past the hips as it passes.
const RUN_LEG_ROLL := 0.17
const RUN_LEAN := 0.40

## ---- Jetpack boost pose (docs/STYLE_GUIDE.md R2.8: *"a distinct in-air boost pose, legs trailing,
## arms out for balance — readable in silhouette against the jump and fall poses"*). The three
## airborne silhouettes must not be confusable at 6.5 m, so they are deliberately opposed:
##   jump  — compact: arms UP and in (roll 1.2-1.6), one knee tucked, body stretched;
##   fall  — arms nearly overhead (roll 2.3) and flailing, legs forward and apart;
##   boost — arms held OUT and swept BACK at shoulder height, legs trailing straight down and
##           behind, torso tipped back against the thrust. A wide, calm, cruciform silhouette.
const BOOST_ARM_ROLL := 1.44
## Slightly NEGATIVE: positive yaw is what sweeps a spread arm backwards (the run pose uses +0.74),
## and swept-back arms over bent legs is the jump pose. Out and a touch forward is the balance pose.
const BOOST_ARM_YAW := -0.20
const BOOST_ARM_PITCH := 0.10
const BOOST_ELBOW := 0.22
## NEGATIVE pitch trails the legs BEHIND the body (positive swings them forward - see `_pose_fall`).
## From the side this is the whole difference between boost and jump: jump tucks the legs UNDER a
## stretched body, boost hangs them BEHIND a body tipped back against the thrust.
const BOOST_LEG_PITCH := -0.62
const BOOST_LEAN_BACK := -0.30
## Exhaust puffs emitted per second per nozzle at full thrust. 16 x 2 nozzles x JetPuffs.PUFF_LIFE
## keeps ~24 puffs alive, which overlaps into one continuous painted plume without filling the pool.
const PUFF_RATE := 16.0

var _style: Dictionary = {}
var _state: String = "idle"
var _state_time: float = 0.0
var _emote_done: bool = false
var _time: float = 0.0
var _speed_factor: float = 0.0
var _stride_phase: float = 0.0
var _blend_rate: float = 12.0
var _lean_fwd: float = 0.0
var _lean_side: float = 0.0
var _jet_burst: float = 0.0
## Jetpack thrust 0..1, set every frame by the Player (see `set_boost_thrust`).
var _boost_thrust: float = 0.0
var _boost_vel: Vector3 = Vector3.ZERO
var _puff_accum: float = 0.0
var _puff_emitted: int = 0

var _pose: PackedFloat32Array
var _target: PackedFloat32Array

# idle look-around (the helmet turns; there are no eyes to move any more)
var _look_timer: float = 4.0
var _look_hold: float = 0.0
var _look_yaw: float = 0.0
var _look_pitch: float = 0.0
# helmet lag
var _lag_pitch: float = 0.0
var _lag_roll: float = 0.0
var _lag_y: float = 0.0
var _antenna_t: float = 0.0

# nodes
var _root: Node3D
var _pelvis: Node3D
var _torso: Node3D
var _neck: Node3D
var _arm_l: Node3D
var _arm_r: Node3D
var _leg_l: Node3D
var _leg_r: Node3D
var _upper_arms: Array[MeshInstance3D] = []
var _forearms: Array[MeshInstance3D] = []
var _elbows: Array[Node3D] = []
var _hands: Array[Node3D] = []
var _carry_anchor: Node3D
var _carry_mesh: MeshInstance3D
var _sparkles: GPUParticles3D
var _antenna_mat: ShaderMaterial
var _lamp_mat: ShaderMaterial
var _jet_mats: Array[ShaderMaterial] = []
## Exhaust markers on whichever backpack is fitted; their -Y is the thrust direction.
var _jet_nozzles: Array[Node3D] = []
var _puffs: JetPuffs

static var _star_tex: ImageTexture


func _init() -> void:
	_pose = PackedFloat32Array()
	_pose.resize(P.COUNT)
	_target = PackedFloat32Array()
	_target.resize(P.COUNT)
	_reset_pose(_pose)
	_reset_pose(_target)


func _ready() -> void:
	_look_timer = randf_range(3.0, 6.0)
	# A tiny per-instance phase offset so a crowd of astronauts never walks in lockstep.
	_time = randf_range(0.0, 6.0)
	if follow_game_state:
		apply_style(GameState.player_style)
		EventBus.player_style_changed.connect(_on_style_changed)
	else:
		apply_style(style_override)


func _on_style_changed() -> void:
	if follow_game_state:
		apply_style(GameState.player_style)


# ============================================================================= public API
## Rebuilds the model from a style dictionary (missing keys fall back to the default look).
func apply_style(style: Dictionary) -> void:
	var s := GameState.player_style.duplicate()
	for k: Variant in style.keys():
		s[k] = style[k]
	_style = s
	_build()


func get_style() -> Dictionary:
	return _style


## Switches the animation state. Blends smoothly from the current pose; same state = no-op.
func set_state(state: String) -> void:
	if state == _state:
		return
	_state = state
	_state_time = 0.0
	_emote_done = false
	match state:
		"jump":
			_blend_rate = 26.0
		"land":
			_blend_rate = 30.0
		"surprised":
			_blend_rate = 22.0
		"fall":
			_blend_rate = 10.0
		"boost":
			# Fast, but not a snap: the boost pose is entered from a jump that is still opening out,
			# and blending in over ~0.06 s is what makes it read as the thrust taking hold.
			_blend_rate = 18.0
		_:
			_blend_rate = 12.0
	if state == "happy" and _sparkles:
		_sparkles.restart()
		_sparkles.emitting = true
	if (state == "jump" or state == "boost") and not _jet_mats.is_empty():
		_jet_burst = 1.0


func get_state() -> String:
	return _state


func get_state_time() -> float:
	return _state_time


## Duration of a timed emote (0 for looping / non-emote states).
static func get_emote_duration(emote: String) -> float:
	return float(EMOTE_DURATIONS.get(emote, 0.0))


## Lean in radians: forward (positive = nose down into movement) and side (positive = lean to +X).
func set_lean(forward: float, side: float) -> void:
	_lean_fwd = forward
	_lean_side = side


## Shows a mesh held in both mittens in front of the chest. Pass null to clear.
## The anchor is the item's BOTTOM face, so callers pass half the item height as `offset`.
func set_carry_item(mesh: Mesh, offset: Vector3 = Vector3.ZERO) -> void:
	if _carry_mesh == null:
		return
	_carry_mesh.mesh = mesh
	_carry_mesh.position = offset
	_carry_mesh.visible = mesh != null


func is_carrying() -> bool:
	return _carry_mesh != null and _carry_mesh.visible


## Jetpack thrust for this frame (docs/STYLE_GUIDE.md R2.8). `amount` 0 = off, 1 = full burn; it
## drives the nozzle throat glow and the rate of exhaust puffs. `world_velocity` is the astronaut's
## own velocity, which each puff partly inherits so the plume trails instead of hanging in a line.
## Safe to call every frame from anywhere; the model does nothing if it has no nozzles.
func set_boost_thrust(amount: float, world_velocity: Vector3 = Vector3.ZERO) -> void:
	_boost_thrust = clampf(amount, 0.0, 1.0)
	_boost_vel = world_velocity


func get_boost_thrust() -> float:
	return _boost_thrust


## Drops every exhaust puff instantly (planet change / teleport, where a trailing plume would be
## stretched across the world).
func clear_jet_puffs() -> void:
	if _puffs:
		_puffs.clear_all()


## Advances the animation. speed_factor: 0 idle, 1 walking speed, ~1.67 running.
func tick(delta: float, speed_factor: float) -> void:
	if _root == null:
		return
	_time += delta
	_state_time += delta
	_speed_factor = speed_factor
	_update_look(delta)
	_reset_pose(_target)
	_compute_target(_target, _state_time)
	var k := 1.0 - exp(-_blend_rate * delta)
	for i in P.COUNT:
		_pose[i] = lerpf(_pose[i], _target[i], k)
	_apply_pose(delta)
	if _state in EMOTE_DURATIONS and not _emote_done and _state_time >= float(EMOTE_DURATIONS[_state]):
		_emote_done = true
		emote_finished.emit(_state)


# ============================================================================= animation
func _reset_pose(p: PackedFloat32Array) -> void:
	for i in P.COUNT:
		p[i] = 0.0
	p[P.SQUASH] = 1.0
	p[P.ARM_L_ROLL] = ARM_REST_ROLL
	p[P.ARM_R_ROLL] = ARM_REST_ROLL
	p[P.ELBOW_L] = ELBOW_REST
	p[P.ELBOW_R] = ELBOW_REST
	p[P.ARM_STRETCH] = 1.0


## Idle "looking around": with no eyes, the whole helmet has to do it, so this is now a body-language
## channel rather than a face one. Small, slow, and only while standing.
func _update_look(delta: float) -> void:
	if _state != "idle" and _state != "carry_idle" and _state != "talk":
		_look_yaw = lerpf(_look_yaw, 0.0, 1.0 - exp(-6.0 * delta))
		_look_pitch = lerpf(_look_pitch, 0.0, 1.0 - exp(-6.0 * delta))
		_look_hold = 0.0
		return
	if _look_hold > 0.0:
		_look_hold -= delta
		if _look_hold <= 0.0:
			_look_timer = randf_range(3.5, 7.0)
	else:
		_look_timer -= delta
		if _look_timer <= 0.0:
			_look_hold = randf_range(1.0, 1.7)
			_look_yaw = randf_range(-0.5, 0.5)
			_look_pitch = randf_range(-0.14, 0.12)
	if _look_hold <= 0.0:
		_look_yaw = lerpf(_look_yaw, 0.0, 1.0 - exp(-5.0 * delta))
		_look_pitch = lerpf(_look_pitch, 0.0, 1.0 - exp(-5.0 * delta))


func _compute_target(p: PackedFloat32Array, t: float) -> void:
	match _state:
		"idle":
			_pose_idle(p, false)
		"carry_idle":
			_pose_idle(p, true)
		"walk", "run":
			_pose_locomotion(p, false)
		"carry_walk":
			_pose_locomotion(p, true)
		"jump":
			_pose_jump(p, t)
		"boost":
			_pose_boost(p, t)
		"fall":
			_pose_fall(p, t)
		"land":
			_pose_land(p, t)
		"talk":
			_pose_talk(p, t)
		"wave":
			_pose_wave(p, t)
		"happy":
			_pose_happy(p, t)
		"think":
			_pose_think(p, t)
		"dance":
			_pose_dance(p, t)
		"surprised":
			_pose_surprised(p, t)
		_:
			_pose_idle(p, false)
	# lean from acceleration is layered on every state
	p[P.PELVIS_PITCH] += _lean_fwd
	p[P.TORSO_ROLL] += _lean_side


func _pose_idle(p: PackedFloat32Array, carry: bool) -> void:
	var breathe := sin(TAU * _time / 2.0)
	p[P.BODY_Y] = 0.005 * breathe
	p[P.SQUASH] = 1.0 + 0.013 * breathe
	# A standing person is never square on both feet: the weight rests on one hip and drifts.
	p[P.BODY_X] = 0.012 * sin(TAU * _time / 7.3)
	p[P.PELVIS_ROLL] = 0.030 * sin(TAU * _time / 3.7)
	p[P.TORSO_ROLL] = 0.018 * sin(TAU * _time / 5.1 + 1.0)
	p[P.TORSO_YAW] = 0.020 * sin(TAU * _time / 6.7)
	p[P.HEAD_YAW] = _look_yaw
	p[P.HEAD_PITCH] = _look_pitch
	p[P.HEAD_ROLL] = 0.025 * sin(TAU * _time / 4.3)
	if carry:
		_arms_carry(p)
		p[P.ARM_L_ROLL] += 0.03 * breathe
		p[P.ARM_R_ROLL] += 0.03 * breathe
	else:
		p[P.ARM_L_ROLL] = ARM_REST_ROLL + 0.03 * breathe
		p[P.ARM_R_ROLL] = ARM_REST_ROLL + 0.03 * breathe
		p[P.ARM_L_PITCH] = 0.04 * breathe
		p[P.ARM_R_PITCH] = 0.04 * breathe
		p[P.ELBOW_L] = ELBOW_REST + 0.05 * breathe
		p[P.ELBOW_R] = ELBOW_REST + 0.05 * breathe


## Animal Crossing's two-handed hold: both arms swing forward and in, the mittens close on the
## item's side faces at chest height, and the item hangs between them (never over the helmet).
func _arms_carry(p: PackedFloat32Array) -> void:
	p[P.ARM_L_ROLL] = CARRY_ROLL
	p[P.ARM_R_ROLL] = CARRY_ROLL
	p[P.ARM_L_PITCH] = CARRY_PITCH
	p[P.ARM_R_PITCH] = CARRY_PITCH
	p[P.ARM_L_YAW] = CARRY_YAW
	p[P.ARM_R_YAW] = CARRY_YAW
	p[P.ELBOW_L] = 0.0
	p[P.ELBOW_R] = 0.0
	p[P.ARM_STRETCH] = CARRY_STRETCH


## Walk and run. `_speed_factor` 1.0 = walk, ~1.67 = run, and `run_blend` crossfades the two
## silhouettes: upright with the arms swinging past the hips, versus leaning forward with the arms
## spread and swept behind. The two must be distinguishable from silhouette alone at 6.5 m.
func _pose_locomotion(p: PackedFloat32Array, carry: bool) -> void:
	var run_blend := clampf((_speed_factor - 1.0) / 0.67, 0.0, 1.0)
	var gain := clampf(_speed_factor / 0.6, 0.0, 1.0)
	var ph := _stride_phase
	var s := sin(ph)
	var c := cos(ph)

	# ---- legs. One leg reaches slightly further than the other (STEP_ASYMMETRY) so the gait is not
	# a perfect metronome; the modulation is smooth in ph, so nothing pops at the passing pose.
	var amp := lerpf(WALK_LEG_AMP, RUN_LEG_AMP, run_blend) * gain
	var asym := 1.0 + STEP_ASYMMETRY * s
	var leg_l := amp * s * asym
	var leg_r := -amp * s * asym
	p[P.LEG_L_PITCH] = leg_l
	p[P.LEG_R_PITCH] = leg_r
	# airborne leg lifts; the stance leg is pushed down so its foot stays planted despite the arc
	var air_l := clampf(c * 1.4, 0.0, 1.0)
	var air_r := clampf(-c * 1.4, 0.0, 1.0)
	var lift := lerpf(0.040, 0.088, run_blend)
	p[P.LEG_L_LIFT] = lift * air_l - (1.0 - air_l) * LEG_PIVOT_TO_FOOT * (1.0 - cos(leg_l))
	p[P.LEG_R_LIFT] = lift * air_r - (1.0 - air_r) * LEG_PIVOT_TO_FOOT * (1.0 - cos(leg_r))
	var leg_roll := lerpf(0.07, RUN_LEG_ROLL, run_blend)
	p[P.LEG_L_ROLL] = leg_roll
	p[P.LEG_R_ROLL] = leg_roll

	# ---- weight. The pelvis translates onto whichever foot is planted (left foot plants at
	# ph = PI/2 and carries the body through ph = PI), and the vertical bob is phase-warped so the
	# drop onto the foot is fast and the rise off it is slow. Without these two the character rocks
	# from side to side without ever committing — the "stiff waddle" the user objected to.
	var shift := lerpf(WALK_WEIGHT_SHIFT, RUN_WEIGHT_SHIFT, run_blend) * gain
	p[P.BODY_X] = shift * cos(ph - WEIGHT_LAG)
	var bounce := lerpf(0.042, 0.125, run_blend) * gain
	var bob_ph := 2.0 * ph + BOB_WARP * sin(2.0 * ph)
	p[P.BODY_Y] = bounce * (0.5 + 0.5 * cos(bob_ph)) - bounce * 0.36
	p[P.SQUASH] = 1.0 + lerpf(0.026, 0.052, run_blend) * cos(bob_ph)

	# ---- hips and shoulders, turning against each other
	p[P.PELVIS_ROLL] = lerpf(0.115, 0.150, run_blend) * c
	var hip_yaw := -lerpf(0.150, 0.215, run_blend) * s
	p[P.PELVIS_YAW] = hip_yaw
	p[P.TORSO_YAW] = -hip_yaw * (1.0 + TORSO_COUNTER)
	p[P.TORSO_ROLL] = -lerpf(0.045, 0.070, run_blend) * c
	p[P.PELVIS_PITCH] = lerpf(0.05, RUN_LEAN, run_blend)

	# ---- helmet, arriving a beat behind everything else
	var hph := ph - HEAD_LAG
	p[P.HEAD_YAW] = 0.055 * sin(hph)
	p[P.HEAD_ROLL] = -0.075 * cos(hph)
	p[P.HEAD_PITCH] = -lerpf(0.02, 0.12, run_blend) + 0.030 * cos(2.0 * hph)

	if carry:
		_arms_carry(p)
		p[P.ARM_L_PITCH] += 0.09 * s
		p[P.ARM_R_PITCH] -= 0.09 * s
		return

	# ---- arms. `shape` is a sine with broadened peaks (pow < 1): the arm crosses the body quickly
	# and then SETTLES at each end of the swing instead of turning around instantly. The elbow runs
	# ELBOW_LAG behind it, which is the follow-through.
	## The run arms are the base spread-and-back pose PLUS an alternating drive on every channel, so
	## the sprint is something the character does rather than a shape it holds. `shape` is the same
	## broadened sine the legs use, and the left arm takes `+shape` while the left LEG takes
	## `+amp*s` — opposite ends of the body swinging together is what counter-rotation looks like,
	## and it is what stops a run from reading as a hop.
	var shape := signf(s) * pow(absf(s), 0.72)
	var swing := lerpf(0.98, 0.34, run_blend) * gain
	var lag_s := sin(ph - ELBOW_LAG)
	var walk_roll := lerpf(0.30, 0.44, run_blend)
	var drive := run_blend * gain
	p[P.ARM_L_PITCH] = lerpf(-shape * swing, RUN_ARM_PITCH, run_blend) + RUN_ARM_PITCH_SWING * shape * drive
	p[P.ARM_R_PITCH] = lerpf(shape * swing, RUN_ARM_PITCH, run_blend) - RUN_ARM_PITCH_SWING * shape * drive
	p[P.ARM_L_ROLL] = lerpf(walk_roll, RUN_ARM_ROLL, run_blend) + RUN_ARM_ROLL_SWING * shape * drive
	p[P.ARM_R_ROLL] = lerpf(walk_roll, RUN_ARM_ROLL, run_blend) - RUN_ARM_ROLL_SWING * shape * drive
	p[P.ARM_L_YAW] = lerpf(0.06, RUN_ARM_YAW, run_blend) + RUN_ARM_YAW_SWING * shape * drive
	p[P.ARM_R_YAW] = lerpf(0.06, RUN_ARM_YAW, run_blend) - RUN_ARM_YAW_SWING * shape * drive
	p[P.ELBOW_L] = lerpf(ELBOW_REST - ELBOW_SWING * lag_s, RUN_ARM_ELBOW, run_blend) + RUN_ELBOW_SWING * shape * drive
	p[P.ELBOW_R] = lerpf(ELBOW_REST + ELBOW_SWING * lag_s, RUN_ARM_ELBOW, run_blend) - RUN_ELBOW_SWING * shape * drive
	p[P.ARM_STRETCH] = lerpf(1.0, RUN_ARM_STRETCH, run_blend)


func _pose_jump(p: PackedFloat32Array, t: float) -> void:
	if t < 0.08:
		# anticipation squash
		p[P.SQUASH] = 0.84
		p[P.BODY_Y] = -0.06
		p[P.ARM_L_PITCH] = -0.9
		p[P.ARM_R_PITCH] = -0.9
		p[P.ARM_L_ROLL] = 0.5
		p[P.ARM_R_ROLL] = 0.5
		p[P.ELBOW_L] = 0.55
		p[P.ELBOW_R] = 0.55
		p[P.LEG_L_PITCH] = 0.15
		p[P.LEG_R_PITCH] = 0.15
		p[P.HEAD_PITCH] = 0.15
	else:
		var u := clampf((t - 0.08) / 0.25, 0.0, 1.0)
		p[P.SQUASH] = lerpf(1.16, 1.06, u)
		p[P.BODY_Y] = 0.02
		p[P.ARM_L_PITCH] = 0.4
		p[P.ARM_R_PITCH] = 0.4
		p[P.ARM_L_ROLL] = lerpf(1.6, 1.2, u)
		p[P.ARM_R_ROLL] = lerpf(1.6, 1.2, u)
		p[P.ELBOW_L] = 0.1
		p[P.ELBOW_R] = 0.1
		p[P.LEG_L_PITCH] = -0.35
		p[P.LEG_R_PITCH] = 0.45
		p[P.LEG_L_LIFT] = 0.06
		p[P.LEG_R_LIFT] = 0.10
		p[P.HEAD_PITCH] = -0.15
		p[P.LAMP] = 0.5


## Jetpack cruise (docs/STYLE_GUIDE.md R2.8). Arms out and swept back at shoulder height, legs
## trailing straight down and behind, torso tipped back against the thrust — a wide, calm cruciform
## that cannot be confused with the compact jump or the flailing fall. It is a HELD pose, so the
## life in it comes from a slow two-rate sway rather than from a cycle: the astronaut is hanging
## under a thruster, not running.
func _pose_boost(p: PackedFloat32Array, t: float) -> void:
	var sway := sin(TAU * t * 0.85)
	var bob := sin(TAU * t * 1.7)
	p[P.SQUASH] = 1.05
	p[P.BODY_Y] = 0.018 * bob
	p[P.BODY_X] = 0.020 * sway
	p[P.PELVIS_PITCH] = BOOST_LEAN_BACK + 0.035 * bob
	p[P.PELVIS_ROLL] = 0.05 * sway
	p[P.TORSO_ROLL] = -0.045 * sway
	p[P.TORSO_YAW] = 0.05 * sin(TAU * t * 0.62)
	p[P.ARM_L_ROLL] = BOOST_ARM_ROLL + 0.10 * sway
	p[P.ARM_R_ROLL] = BOOST_ARM_ROLL - 0.10 * sway
	p[P.ARM_L_PITCH] = BOOST_ARM_PITCH
	p[P.ARM_R_PITCH] = BOOST_ARM_PITCH
	p[P.ARM_L_YAW] = BOOST_ARM_YAW
	p[P.ARM_R_YAW] = BOOST_ARM_YAW
	p[P.ELBOW_L] = BOOST_ELBOW + 0.09 * bob
	p[P.ELBOW_R] = BOOST_ELBOW - 0.09 * bob
	p[P.LEG_L_PITCH] = BOOST_LEG_PITCH + 0.07 * sway
	p[P.LEG_R_PITCH] = BOOST_LEG_PITCH - 0.07 * sway
	p[P.LEG_L_ROLL] = 0.14
	p[P.LEG_R_ROLL] = 0.14
	p[P.LEG_L_LIFT] = -0.02
	p[P.LEG_R_LIFT] = -0.02
	p[P.HEAD_PITCH] = -0.16 + 0.03 * bob
	p[P.HEAD_ROLL] = 0.05 * sway
	p[P.LAMP] = 0.85


func _pose_fall(p: PackedFloat32Array, t: float) -> void:
	var w := sin(TAU * t * 1.5)
	p[P.SQUASH] = 1.03
	p[P.ARM_L_PITCH] = 0.3
	p[P.ARM_R_PITCH] = 0.3
	p[P.ARM_L_ROLL] = 2.3 + 0.15 * w
	p[P.ARM_R_ROLL] = 2.3 - 0.15 * w
	p[P.ELBOW_L] = 0.35 + 0.2 * w
	p[P.ELBOW_R] = 0.35 - 0.2 * w
	p[P.LEG_L_PITCH] = 0.5 + 0.1 * w
	p[P.LEG_R_PITCH] = 0.5 - 0.1 * w
	p[P.LEG_L_ROLL] = 0.25
	p[P.LEG_R_ROLL] = 0.25
	p[P.LEG_L_LIFT] = 0.10
	p[P.LEG_R_LIFT] = 0.10
	p[P.HEAD_PITCH] = 0.12
	p[P.LAMP] = 0.85


func _pose_land(p: PackedFloat32Array, t: float) -> void:
	# squash 0.12 s with overshoot then settle
	var sq: float
	if t < 0.12:
		sq = lerpf(1.0, 0.76, sin(t / 0.12 * PI * 0.5))
	elif t < 0.26:
		sq = lerpf(0.76, 1.07, smoothstep(0.0, 1.0, (t - 0.12) / 0.14))
	else:
		sq = lerpf(1.07, 1.0, clampf((t - 0.26) / 0.14, 0.0, 1.0))
	p[P.SQUASH] = sq
	var u := 1.0 - clampf(t / 0.3, 0.0, 1.0)
	p[P.BODY_Y] = -0.04 * u
	p[P.ARM_L_ROLL] = ARM_REST_ROLL + 1.1 * u
	p[P.ARM_R_ROLL] = ARM_REST_ROLL + 1.1 * u
	p[P.ARM_L_PITCH] = -0.4 * u
	p[P.ARM_R_PITCH] = -0.4 * u
	p[P.ELBOW_L] = ELBOW_REST + 0.5 * u
	p[P.ELBOW_R] = ELBOW_REST + 0.5 * u
	p[P.LEG_L_ROLL] = 0.2
	p[P.LEG_R_ROLL] = 0.2
	p[P.HEAD_PITCH] = 0.2 * u
	p[P.PELVIS_PITCH] = 0.1


## Talking with no mouth: the whole body does it. A slow nod, a shifting weight, and one hand
## gesturing on a different, slightly slower rhythm than the other, so it never looks like a loop.
func _pose_talk(p: PackedFloat32Array, t: float) -> void:
	_pose_idle(p, false)
	p[P.HEAD_PITCH] += 0.075 * sin(TAU * t * 1.3) + 0.035 * sin(TAU * t * 2.7)
	p[P.HEAD_ROLL] += 0.055 * sin(TAU * t * 0.7)
	p[P.HEAD_YAW] += 0.05 * sin(TAU * t * 0.53)
	p[P.BODY_X] = 0.016 * sin(TAU * t * 0.41)
	p[P.TORSO_YAW] = 0.05 * sin(TAU * t * 0.61)
	p[P.ARM_R_ROLL] = 0.45 + 0.22 * sin(TAU * t * 1.1)
	p[P.ARM_R_PITCH] = 0.5 + 0.25 * sin(TAU * t * 1.7)
	p[P.ELBOW_R] = 0.7 + 0.35 * sin(TAU * t * 1.7 + 1.1)
	p[P.ARM_L_ROLL] = 0.3 + 0.1 * sin(TAU * t * 0.9 + 1.0)
	p[P.ELBOW_L] = ELBOW_REST + 0.18 * sin(TAU * t * 0.9)
	p[P.LAMP] = 0.35 + 0.35 * sin(TAU * t * 5.0)


func _pose_wave(p: PackedFloat32Array, t: float) -> void:
	_pose_idle(p, false)
	var w := sin(TAU * t * 4.0)
	p[P.ARM_R_ROLL] = 2.45 + 0.35 * w
	p[P.ARM_R_PITCH] = -0.25
	p[P.ARM_R_YAW] = 0.3 * w
	p[P.ELBOW_R] = 0.28 + 0.22 * w
	p[P.HEAD_ROLL] = -0.15
	p[P.HEAD_YAW] = 0.1
	p[P.TORSO_ROLL] = 0.06
	p[P.TORSO_YAW] = -0.10
	p[P.LAMP] = 0.4


func _pose_happy(p: PackedFloat32Array, t: float) -> void:
	var hop := absf(sin(TAU * t / 0.75))
	p[P.BODY_Y] = 0.22 * hop
	p[P.SQUASH] = 1.0 + 0.08 * sin(TAU * t / 0.75 * 2.0)
	p[P.ARM_L_ROLL] = 2.8 + 0.1 * sin(TAU * t * 3.0)
	p[P.ARM_R_ROLL] = 2.8 - 0.1 * sin(TAU * t * 3.0)
	p[P.ARM_L_PITCH] = 0.15
	p[P.ARM_R_PITCH] = 0.15
	p[P.ELBOW_L] = 0.05
	p[P.ELBOW_R] = 0.05
	p[P.LEG_L_PITCH] = -0.3 * hop
	p[P.LEG_R_PITCH] = -0.3 * hop
	p[P.LEG_L_LIFT] = 0.1 * hop
	p[P.LEG_R_LIFT] = 0.1 * hop
	p[P.HEAD_PITCH] = -0.18
	p[P.HEAD_ROLL] = 0.10 * sin(TAU * t * 1.5)
	p[P.LAMP] = 1.0


func _pose_think(p: PackedFloat32Array, t: float) -> void:
	_pose_idle(p, false)
	var u := clampf(t / 0.35, 0.0, 1.0)
	# The mitten cannot reach a chin that no longer exists, so the "hmm" is a hand brought up under
	# the helmet rim with the whole body cocked over to one side.
	p[P.ARM_R_PITCH] = 2.15 * u
	p[P.ARM_R_ROLL] = 0.55 * u
	p[P.ARM_R_YAW] = -0.5 * u
	p[P.ELBOW_R] = 0.85 * u
	p[P.HEAD_ROLL] = 0.26 * u + 0.02 * sin(TAU * t * 0.8)
	p[P.HEAD_PITCH] = -0.20 * u
	p[P.HEAD_YAW] = -0.18 * u
	p[P.TORSO_YAW] = -0.10 * u
	p[P.PELVIS_ROLL] = -0.05 * u
	p[P.ARM_L_ROLL] = 0.15
	p[P.ARM_L_PITCH] = 0.45 * u
	p[P.ARM_L_YAW] = 0.9 * u
	p[P.ELBOW_L] = 0.6 * u
	p[P.LAMP] = 0.15 + 0.15 * sin(TAU * t * 0.9)


func _pose_dance(p: PackedFloat32Array, t: float) -> void:
	var beat := TAU * t * 2.0
	var b := absf(sin(beat))
	var alt := sin(beat * 0.5)
	p[P.BODY_Y] = 0.05 * b
	p[P.BODY_X] = 0.05 * alt
	p[P.SQUASH] = 1.0 + 0.05 * sin(beat * 2.0)
	p[P.PELVIS_YAW] = 0.25 * alt
	p[P.PELVIS_ROLL] = 0.10 * alt
	p[P.TORSO_ROLL] = -0.08 * alt
	p[P.TORSO_YAW] = -0.30 * alt
	p[P.ARM_L_ROLL] = 1.4 + 0.9 * alt
	p[P.ARM_R_ROLL] = 1.4 - 0.9 * alt
	p[P.ARM_L_PITCH] = 0.3
	p[P.ARM_R_PITCH] = 0.3
	p[P.ARM_L_YAW] = 0.4 * alt
	p[P.ARM_R_YAW] = -0.4 * alt
	p[P.ELBOW_L] = 0.35 + 0.3 * alt
	p[P.ELBOW_R] = 0.35 - 0.3 * alt
	p[P.LEG_L_ROLL] = 0.25
	p[P.LEG_R_ROLL] = 0.25
	p[P.LEG_L_LIFT] = 0.06 * clampf(alt, 0.0, 1.0)
	p[P.LEG_R_LIFT] = 0.06 * clampf(-alt, 0.0, 1.0)
	p[P.HEAD_ROLL] = 0.18 * alt
	p[P.HEAD_YAW] = 0.12 * sin(beat)
	p[P.LAMP] = 0.5 + 0.5 * b


func _pose_surprised(p: PackedFloat32Array, t: float) -> void:
	var hop := sin(clampf(t / 0.3, 0.0, 1.0) * PI)
	p[P.BODY_Y] = 0.16 * hop
	p[P.BODY_Z] = 0.28 * clampf(t / 0.3, 0.0, 1.0)
	p[P.SQUASH] = 1.06
	p[P.ARM_L_ROLL] = 1.5
	p[P.ARM_R_ROLL] = 1.5
	p[P.ARM_L_PITCH] = -0.5
	p[P.ARM_R_PITCH] = -0.5
	p[P.ELBOW_L] = 0.75
	p[P.ELBOW_R] = 0.75
	p[P.LEG_L_ROLL] = 0.3
	p[P.LEG_R_ROLL] = 0.3
	p[P.LEG_L_PITCH] = 0.4 * hop
	p[P.LEG_R_PITCH] = 0.4 * hop
	p[P.PELVIS_PITCH] = -0.15
	p[P.HEAD_PITCH] = -0.16
	p[P.LAMP] = 1.0


func _apply_pose(delta: float) -> void:
	var p := _pose
	# Stride phase advances with speed; footsteps at the plants. The cadence carries a slow
	# irregularity so the gait is never a perfect metronome (docs/STYLE_GUIDE.md R2.4).
	var moving := _state in MOVING_STATES
	if moving and _speed_factor > 0.05:
		var wobble := 1.0 + 0.055 * sin(TAU * _time / 3.1) + 0.035 * sin(TAU * _time / 1.73)
		# Walk keeps the old sqrt curve (it is what makes a slow shuffle look like a shuffle);
		# above walk speed the cadence is blended toward RUN_CADENCE instead, because sqrt alone
		# spent the extra speed on stride length and left the run looking like a slow-motion glide.
		# See the comment on WALK_CADENCE / RUN_CADENCE.
		var run_blend := clampf((_speed_factor - 1.0) / 0.67, 0.0, 1.0)
		var cadence := lerpf(WALK_CADENCE * sqrt(maxf(_speed_factor, 0.15)), RUN_CADENCE, run_blend) * wobble
		var prev := _stride_phase
		_stride_phase += TAU * cadence * 0.5 * delta
		if _crossed(prev, _stride_phase, PI * 0.5):
			footstep.emit(0)
		if _crossed(prev, _stride_phase, PI * 1.5):
			footstep.emit(1)
		if _stride_phase > TAU:
			_stride_phase -= TAU
	elif not moving:
		_stride_phase = lerpf(_stride_phase, 0.0, 1.0 - exp(-10.0 * delta))

	var sq := p[P.SQUASH]
	var xz := 1.0 / sqrt(maxf(sq, 0.2))
	_root.scale = Vector3(xz, sq, xz)
	_pelvis.position = Vector3(p[P.BODY_X], PELVIS_Y + p[P.BODY_Y], p[P.BODY_Z])
	_pelvis.rotation = Vector3(p[P.PELVIS_PITCH], p[P.PELVIS_YAW], -p[P.PELVIS_ROLL])
	_torso.rotation = Vector3(0.0, p[P.TORSO_YAW], -p[P.TORSO_ROLL])

	# helmet lag: it trails the body's pitch/roll and bob a little
	var kl := 1.0 - exp(-9.0 * delta)
	_lag_pitch = lerpf(_lag_pitch, -p[P.PELVIS_PITCH] * 0.45, kl)
	_lag_roll = lerpf(_lag_roll, (p[P.PELVIS_ROLL] + p[P.TORSO_ROLL]) * 0.5, kl)
	_lag_y = lerpf(_lag_y, p[P.BODY_Y], 1.0 - exp(-14.0 * delta))
	_neck.rotation = Vector3(p[P.HEAD_PITCH] + _lag_pitch, p[P.HEAD_YAW], p[P.HEAD_ROLL] - _lag_roll)
	_neck.position = Vector3(0.0, NECK_Y - PELVIS_Y + (_lag_y - p[P.BODY_Y]) * 0.7, 0.0)

	# Arms are clamped into the safety envelope BEFORE they are applied, so no pose (and no blend
	# between two poses) can drive a mitten or an upper arm into the opaque helmet shell.
	var stretch := clampf(p[P.ARM_STRETCH], 0.6, MAX_ARM_STRETCH)
	var roll_ceil := _clamp_arm_reach(stretch)
	_arm_l.rotation = Vector3(p[P.ARM_L_PITCH], p[P.ARM_L_YAW], -minf(p[P.ARM_L_ROLL], roll_ceil))
	_arm_r.rotation = Vector3(p[P.ARM_R_PITCH], -p[P.ARM_R_YAW], minf(p[P.ARM_R_ROLL], roll_ceil))
	for i in 2:
		var bend := clampf(p[P.ELBOW_L] if i == 0 else p[P.ELBOW_R], 0.0, 1.5)
		_upper_arms[i].scale = Vector3(1.0, stretch, 1.0)
		_upper_arms[i].position = Vector3(0.0, ARM_UPPER_Y * stretch, 0.0)
		_elbows[i].position = Vector3(0.0, ELBOW_Y * stretch, 0.0)
		_elbows[i].rotation = Vector3(bend, 0.0, 0.0)
		_forearms[i].scale = Vector3(1.0, stretch, 1.0)
		_forearms[i].position = Vector3(0.0, FORE_Y * stretch, 0.0)
		_hands[i].position = Vector3(0.0, HAND_LOCAL_Y * stretch, 0.0)
	_leg_l.rotation = Vector3(p[P.LEG_L_PITCH], 0.0, -p[P.LEG_L_ROLL])
	_leg_r.rotation = Vector3(p[P.LEG_R_PITCH], 0.0, p[P.LEG_R_ROLL])
	_leg_l.position = Vector3(-HIP_X, PELVIS_Y + p[P.LEG_L_LIFT], 0.0)
	_leg_r.position = Vector3(HIP_X, PELVIS_Y + p[P.LEG_R_LIFT], 0.0)

	# Status lamp on the helmet rim — the one expressive light allowed now that the face is gone
	# (docs/STYLE_GUIDE.md R2.2: "a small emissive glyph or indicator ... but keep it subtle").
	_antenna_t += delta
	if _lamp_mat:
		var idle_pulse := 0.5 + 0.5 * sin(TAU * _antenna_t / 2.6)
		_lamp_mat.set_shader_parameter("emission_strength", 0.5 + 0.5 * idle_pulse + 2.6 * clampf(p[P.LAMP], 0.0, 1.0))
	if _antenna_mat:
		var pulse := pow(maxf(0.0, sin(TAU * _antenna_t / 1.3)), 10.0)
		_antenna_mat.set_shader_parameter("emission_strength", 0.6 + 3.4 * pulse)
	if not _jet_mats.is_empty():
		_jet_burst = maxf(0.0, _jet_burst - delta * 1.6)
		# The nozzle throats brighten with thrust and flicker while burning, so the pack is visibly
		# the thing doing the work even before you notice the puffs.
		var flicker := 0.6 * sin(TAU * _antenna_t * 3.0) + _boost_thrust * 0.9 * sin(TAU * _antenna_t * 14.0)
		var glow := 1.2 + flicker + 3.5 * _jet_burst + 3.2 * _boost_thrust
		for m: ShaderMaterial in _jet_mats:
			m.set_shader_parameter("emission_strength", glow)
	_tick_jet_puffs(delta)


## Exhaust. Puffs are spawned round-robin across the pack's nozzles at a rate proportional to
## thrust, with a small burst on ignition so the plume does not fade up from nothing.
func _tick_jet_puffs(delta: float) -> void:
	if _puffs == null:
		return
	if _boost_thrust > 0.01 and not _jet_nozzles.is_empty():
		if _puff_accum <= 0.0:
			# Ignition burst: two puffs per nozzle at once, so the plume arrives as a puff of smoke
			# rather than fading up out of nothing over the first quarter second.
			_puff_accum = float(_jet_nozzles.size()) * 2.0
		_puff_accum += delta * PUFF_RATE * _boost_thrust * float(_jet_nozzles.size())
		var budget := mini(int(_puff_accum), 6)
		for i in budget:
			var nz := _jet_nozzles[(_puff_emitted + i) % _jet_nozzles.size()]
			_puffs.emit(nz.global_transform, _boost_vel)
		_puff_emitted += budget
		_puff_accum -= float(budget)
	else:
		_puff_accum = 0.0
	_puffs.tick(delta)


static func _crossed(a: float, b: float, mark: float) -> bool:
	return a < mark and b >= mark


## Highest arm roll (arm swung up and outward) that still keeps the mitten — and therefore the whole
## straight upper arm behind it — outside the helmet ellipsoid inflated by the mitten radius.
## Measured: at rest length the mitten crosses the inflated shell at roll ~2.5, so 2.45 is the
## ceiling; every extra unit of stretch pulls that ceiling down by ARM_ROLL_STRETCH_PENALTY.
static func _clamp_arm_reach(stretch: float) -> float:
	return maxf(MAX_ARM_ROLL - (stretch - 1.0) * ARM_ROLL_STRETCH_PENALTY, MIN_ARM_ROLL_CEIL)


# ============================================================================= geometry
func _build() -> void:
	for c: Node in get_children():
		remove_child(c)
		c.queue_free()
	_antenna_mat = null
	_lamp_mat = null
	_puffs = null
	_jet_mats.clear()
	_jet_nozzles.clear()
	_upper_arms.clear()
	_forearms.clear()
	_elbows.clear()
	_hands.clear()

	# Colour blocking. Still the FOUR zones the contract requires, but REDISTRIBUTED for R2.7.
	# The old layout put `panel_color` on both whole sleeves and `accent_color` on both whole mittens
	# and both whole boots: a blue-and-white body with red gloves and red booties, which is a WETSUIT
	# palette and was a large part of the diver read. Every reference astronaut is overwhelmingly
	# off-white with the warm hue confined to thin rings. So the zones now land as:
	#   suit    - dome, torso above the hip seam, sleeves, forearms, thighs, shins, mittens
	#   trouser - the hip assembly (lower torso), the boots and soles: the dark value anchor
	#   panel   - the HARD parts: collar barrel, shoulder yokes, chest control panel, backpack,
	#             ear pods, the dome's rear shell segment
	#   accent  - the eight limb bands, the glove and boot cuffs, the visor rim, the pack trim
	# R2.6 is better served too: the loud hue now covers a few percent of the character instead of
	# its four biggest limb volumes.
	var suit := Color(_style.get("suit_color", "#f4f4f8"))
	var trouser := Color(_style.get("trouser_color", "#42419c"))
	var panel := Color(_style.get("panel_color", "#5f92cc"))
	var accent := Color(_style.get("accent_color", "#ff7a59"))
	# `visor_tint` used to be the colour of see-through glass. It now tints the opaque navy pane:
	# a light tint keeps the pane recognisably navy while letting a suit variant shift it warm/cool.
	# The result is only the STARTING point — `_visor_color` below re-seats it against the dome so a
	# dark suit can never end up with a window lighter than the shell around it.
	var visor_base := VISOR_NAVY.lerp(Color(_style.get("visor_tint", "#6fc3ff")).darkened(0.62), 0.35)
	# The accent is now only ever a RING or a rim, so it can keep more of its own hue than it could
	# when it covered whole mittens and boots. It still takes one step down: the references' amber
	# sits around S 0.62, and the default #ff7a59 at full strength measured S 0.74 V 0.98 on a
	# character whose REVISION 2 gate is saturation 0.36-0.48.
	var accent_band := _band_hue(accent).darkened(0.10)
	var accent_dark := _band_hue(accent).darkened(0.34)
	# The rendered suit is deliberately NOT the nominal colour: albedo is darkened and warmed so the
	# light, not the paint, makes it read white (see SUIT_DARKEN).
	# The cream tint is scaled by how LIGHT the chosen suit already is. At a flat SUIT_TINT every
	# suit in the wardrobe came out the same cream — the showcase's "dark suit" variant (#2b2f5e)
	# rendered as tan — which makes the clothes shop cosmetic in name only. A near-white suit still
	# gets the full warm tint (that is the point of SUIT_TINT: an untinted white reads as plastic),
	# while a genuinely coloured suit keeps its hue.
	var tint_k := SUIT_TINT * pow(clampf(suit.get_luminance(), 0.0, 1.0), 1.2)
	var suit_albedo := suit.darkened(SUIT_DARKEN).lerp(SUIT_TINT_COLOR, tint_k)
	var suit_shade := suit_albedo.darkened(0.10)
	# The dome is the suit colour with a VALUE FLOOR (see DOME_MIN_V) and the pane is derived from
	# the dome, so "the visor is a dark window in a lighter shell" is true for every suit in the
	# wardrobe instead of only for the light ones.
	var dome_albedo := _dome_albedo(suit_albedo)
	var visor := _visor_color(visor_base, dome_albedo)
	# Mittens and boot shells are the suit, one step down, so they read as thick gauntlets rather
	# than as a separate garment (reference/"astronaut 3.jpeg": white gloves, orange trim only).
	var glove := suit_albedo.darkened(0.07)
	var boot := trouser.lerp(suit_albedo, 0.20).lerp(Color("#6a7285"), 0.16)

	# Matte everywhere (spec 0.05): Animal Crossing has no glossy plastic on characters. The only
	# specular in the whole model is on the navy visor pane. Rim light is kept low on the suit — a
	# bright rim on a near-white dome is just more blown white — and the shell shader's limb
	# darkening does the job a rim light used to pretend to do.
	# R2.9: the four big cloth surfaces (sleeves, forearms, thighs, shins) and the torso take the
	# shared sd_cloth weave plus panel seams; the torso gets fewer, wider panels than a limb does,
	# which is why it is a separate material with the same albedo.
	var m_suit := _shell_toon(suit_albedo, _surf(SURF_CLOTH))
	var m_suit_torso := _shell_toon(suit_albedo, _surf(SURF_CLOTH_TORSO))
	# The seam rings, the collar barrel and the cuffs: the same fabric, no seams of their own (they
	# ARE the seams, and a 5 mm ring does not need a panel line drawn on it).
	var m_suit_shade := _shell_toon(suit_shade, {"surface": "cloth", "sheen": 0.13})
	var m_dome := _shell_toon(dome_albedo, _surf(SURF_DOME))
	var m_trouser := _shell_toon(trouser, _surf(SURF_CLOTH_TORSO, {"limb": 0.20}))
	# HARDWARE GREY, and this is now a saturation CAP rather than a lerp toward a grey swatch.
	# The shell shader's limb darkening and shade ramp push chroma hard - #5f92cc (S 0.54 as
	# authored) measured S 0.75 as rendered on the collar and the pack - so anything authored as a
	# real blue comes out as a blue GARMENT. Capping saturation in HSV and letting the hue through
	# gives the cool instrument grey that reference/"astronaut 3.jpeg" puts on its hard parts, and
	# it answers the orchestrator's note that the blue on the torso is in none of the references:
	# the pack, the chest case, the shoulder bearings and the ear pods are hardware, not clothing.
	# `panel_color` still steers the hue, it just cannot shout. (No suit in
	# src/hub/clothing_catalog.gd sets panel_color at all, so this costs the wardrobe nothing.)
	var panel_soft := _hardware(panel, 0.22, 0.76)
	# The hard parts are METAL: brushed grain and the shared travelling sheen (R2.9's metal row).
	var m_panel := _shell_toon(panel_soft, _surf(SURF_METAL, {"limb": 0.22}))
	var m_panel_dark := _shell_toon(panel_soft.darkened(0.24), _surf(SURF_METAL, {"limb": 0.18}))
	var m_accent := _shell_toon(accent, {"limb": 0.22})
	var m_band := _shell_toon(accent_band, {"limb": 0.22})
	# Gauntlets and boot shells are RUBBER, not suit fabric — a pebbled microsurface, so they read
	# as a different material from the sleeve above them and not merely as a different colour.
	var m_glove := _shell_toon(glove, _surf(SURF_RUBBER, {"limb": 0.24}))
	var m_boot := _shell_toon(boot, _surf(SURF_RUBBER, {"limb": 0.20}))
	# The helmet's rear shell segment: a muted steel blue-grey, one clear value step below the DOME
	# (not below the body suit — on a dark suit those are now different colours and the segment has
	# to stay darker than the shell it seats into, or it reads as a light patch on the back).
	# Not the indigo of the trousers — a saturated cap on the back of a white dome read as a beanie.
	var m_shell_back := _shell_toon(dome_albedo.darkened(0.20).lerp(panel_soft, 0.30),
			_surf(SURF_DOME, {"limb": 0.24}))
	var m_accent_dark := _shell_toon(accent_dark, {"limb": 0.18})
	# Boot soles are rubber, not trim. Painting them accent put a fourth warm element on a 0.20 m leg.
	var m_sole := _shell_toon(trouser.darkened(0.45).lerp(Color("#3a3a42"), 0.5),
			_surf(SURF_RUBBER, {"limb": 0.16}))
	# The visor rim. It rings the largest dark shape on the character, so at full accent strength it
	# is the loudest element in the frame; a step down keeps it a trim line.
	var m_rim := _shell_toon(_band_hue(accent).darkened(0.18).lerp(panel.darkened(0.35), 0.22), {"limb": 0.20})
	# The ear pods are HARDWARE, so they take a pale instrument grey-blue: at full panel saturation
	# two bright blue discs on a cream dome were the loudest thing on the head after the visor.
	var m_pod := _shell_toon(_hardware(panel, 0.15, 0.84), _surf(SURF_METAL, {"limb": 0.22}))
	var m_metal := MaterialLib.metal(Color("#b8c4d6"), {"spec": 0.35, "spec_size": 120.0})
	var m_dark_metal := MaterialLib.metal(Color("#5d6678"), {"spec": 0.3})

	_root = _node("Root", self, Vector3.ZERO)
	_pelvis = _node("Pelvis", _root, Vector3(0.0, PELVIS_Y, 0.0))
	_torso = _node("Torso", _pelvis, Vector3.ZERO)

	# ---- torso: one short rounded bean, no neck, no shoulders to speak of. ONE mesh, TWO surfaces:
	# the cream suit above the hip seam and the dark lower-torso assembly below it. A separate
	# overlay shell would z-fight; the seam is a real latitude ring of the mesh.
	var torso_mi := _mi(AstroShapes.split_box(TORSO_SIZE, 0.16, TORSO_SPLIT_RING, SEG_TORSO, TORSO_RINGS),
			null, _torso, Vector3(0.0, TORSO_MESH_Y, 0.0), "TorsoMesh")
	torso_mi.set_surface_override_material(0, m_suit_torso)
	torso_mi.set_surface_override_material(1, m_trouser)
	_build_collar(m_suit_shade, m_panel_dark, m_band, m_metal)
	# R2.7 point 5: a chest control panel. It REPLACES the vertical placket, which was the "stripe
	# down the middle" the note calls a wetsuit zip — the single most diver-ish thing on the torso
	# after the mask. A raised rounded box with four small dials, as in reference/"astronaut 3.jpeg".
	_build_chest_panel(m_panel, m_panel_dark, m_accent, accent, panel_soft)
	# waistband, sitting exactly ON the suit/hip seam and flush with the bean's cross-section
	# (the old hem torus stood 0.055 proud of both hips and read as a hula hoop)
	# The belt rides its OWN ring, not the colour seam. Now that the dark hip block has shrunk to a
	# band (TORSO_SPLIT_RING 6 -> 7) the seam is down at the hip crease, where an accent ring reads
	# as a small orange tab between the legs instead of as a belt. BELT_RING keeps it on the waist,
	# which is where reference/"astronaut 2.jpeg" wears its orange band.
	var seam_y := TORSO_MESH_Y + AstroShapes.split_box_seam_y(TORSO_SIZE, 0.16, BELT_RING, TORSO_RINGS)
	var seam := AstroShapes.split_box_ring_extent(TORSO_SIZE, 0.16, cos(PI * float(BELT_RING) / float(TORSO_RINGS)))
	# One accent ring on the belt line: the references all carry the hue across the waist, and it
	# ties the eight limb bands to the body instead of leaving them scattered.
	var belt_trim := _mi(_cylinder(seam.x + 0.012, seam.x + 0.012, 0.026, 14), m_band, _torso, Vector3(0.0, seam_y + 0.028, 0.0), "BeltBand")
	belt_trim.scale = Vector3(1.0, 1.0, (seam.y + 0.012) / (seam.x + 0.012))

	# ---- arms: two short capsules with an elbow between them, ending in round mittens. The sleeve
	# is the SUIT now, not the panel colour (see the colour-blocking note): a cream limb wearing a
	# bicep band and a forearm band, which is what every reference does. The panel colour survives
	# on the shoulder yoke, so the arm still has a hard joint at the top.
	_arm_l = _node("ArmL", _torso, Vector3(-SHOULDER.x, SHOULDER.y, SHOULDER.z))
	_arm_r = _node("ArmR", _torso, Vector3(SHOULDER.x, SHOULDER.y, SHOULDER.z))
	for arm: Node3D in [_arm_l, _arm_r]:
		# The shoulder bearing: the suit's one hard joint at the top of the arm, and the panel
		# colour's home now that the yokes are gone. Slightly larger than it was so it reads as a
		# ring joint in silhouette rather than as a bead.
		var bearing := _mi(_sphere(0.098, 10, 5), m_panel, arm, Vector3.ZERO, "Shoulder")
		bearing.scale = Vector3(1.0, 0.92, 1.0)
		var upper := _mi(_capsule(0.062, 0.150, SEG_LIMB, RINGS_LIMB), m_suit, arm, Vector3(0.0, ARM_UPPER_Y, 0.0), "UpperArm")
		# BICEP band (1 of 8)
		_band_ring(arm, m_band, 0.062, Vector3(0.0, ARM_UPPER_Y - 0.030, 0.0), "BicepBand")
		# soft segmentation seam at the elbow (R2.7 point 7: thick fabric over a pressure layer)
		_band_ring(arm, m_suit_shade, 0.062, Vector3(0.0, ELBOW_Y + 0.010, 0.0), "ElbowSeam", 0.005, 0.016)
		var elbow := _node("Elbow", arm, Vector3(0.0, ELBOW_Y, 0.0))
		var fore := _mi(_capsule(0.059, 0.140, SEG_LIMB, RINGS_LIMB), m_suit, elbow, Vector3(0.0, FORE_Y, 0.0), "Forearm")
		# FOREARM band (2 of 8)
		_band_ring(elbow, m_band, 0.059, Vector3(0.0, FORE_Y - 0.026, 0.0), "ForearmBand")
		var hand := _node("Hand", elbow, Vector3(0.0, HAND_LOCAL_Y, 0.0))
		var mitten := _mi(_sphere(HAND_R, 9, 4), m_glove, hand, Vector3.ZERO, "Glove")
		mitten.scale = Vector3(1.0, 1.04, 0.96)
		_band_ring(hand, m_suit_shade, 0.058, Vector3(0.0, 0.056, 0.0), "Cuff", 0.012, 0.026)
		_upper_arms.append(upper)
		_forearms.append(fore)
		_elbows.append(elbow)
		_hands.append(hand)

	# ---- legs: cream suit legs with a thigh band, a knee seam and a shin band, ending in big dark
	# boots with an accent cuff. Orange booties went with the wetsuit palette.
	_leg_l = _node("LegL", _root, Vector3(-HIP_X, PELVIS_Y, 0.0))
	_leg_r = _node("LegR", _root, Vector3(HIP_X, PELVIS_Y, 0.0))
	for leg: Node3D in [_leg_l, _leg_r]:
		_mi(_capsule(0.089, 0.205, SEG_LIMB, RINGS_LIMB), m_suit, leg, Vector3(0.0, -0.088, 0.0), "Leg")
		# THIGH band (3 of 8) and SHIN band (4 of 8), with a knee seam between them
		_band_ring(leg, m_band, 0.089, Vector3(0.0, -0.046, 0.0), "ThighBand")
		_band_ring(leg, m_suit_shade, 0.089, Vector3(0.0, -0.108, 0.0), "KneeSeam", 0.005, 0.018)
		_band_ring(leg, m_band, 0.089, Vector3(0.0, -0.176, -0.004), "BootCuff", 0.013, 0.032)
		var boot_mi := _mi(_rounded_box(Vector3(0.176, 0.150, 0.236), 0.064, 12), m_boot, leg, Vector3(0.0, -0.252, -0.028), "Boot")
		boot_mi.rotation.x = -0.04
		# boot cuff: the eighth accent ring, right where the suit enters the boot
		_mi(_rounded_box(Vector3(0.174, 0.036, 0.230), 0.017, 8), m_sole, leg, Vector3(0.0, -0.307, -0.028), "Sole")

	# ---- helmet. The helmet pivots at the torso top, there is no neck node in between; the collar
	# assembly below it belongs to the TORSO, so the bubble turns inside a ring that does not.
	_neck = _node("Neck", _torso, Vector3(0.0, NECK_Y - PELVIS_Y, 0.0))
	var helm := _node("Helmet", _neck, Vector3(0.0, HELMET_CY - NECK_Y, 0.0))
	_build_helmet(helm, m_dome, m_rim, m_shell_back, m_pod, m_panel_dark, m_metal, visor)
	var hat := _node("Hat", helm, Vector3.ZERO)
	_build_hat(hat, str(_style.get("hat_id", "")), accent)

	# ---- life-support pack, sized so it reads from the SIDE and the BACK (R2.7 point 6)
	var pack := _node("Backpack", _torso, Vector3(0.0, 0.206, 0.206))
	# panel_soft, not the raw panel: from BEHIND — which is where the gameplay camera lives — the
	# pack is the largest single object on the character after the dome, and at full panel
	# saturation it made the back view a blue box on a cream body.
	_build_backpack(pack, str(_style.get("backpack_id", "pack_basic")), panel_soft, accent, m_metal, m_dark_metal)

	# Carry anchor BETWEEN the mittens, in front of the chest — it hangs off the torso (not the
	# helmet) so it travels with the shoulders the arms are attached to. The anchor is the item's
	# bottom face: callers pass half the item height as the offset.
	_carry_anchor = _node("CarryAnchor", _torso, CARRY_ANCHOR - Vector3(0.0, PELVIS_Y, 0.0))
	_carry_mesh = _mi(null, null, _carry_anchor, Vector3.ZERO, "CarryItem")
	_carry_mesh.visible = false

	_sparkles = _make_sparkles()
	_sparkles.position = Vector3(0.0, 1.0, 0.0)
	add_child(_sparkles)

	# The jetpack plume. `top_level`, so puffs stay where they were born and trail behind (see
	# src/player/jet_puffs.gd). Added last so it draws over the pack.
	_puffs = JetPuffs.new()
	add_child(_puffs)

	# make sure the pose is applied once so the first frame isn't in T-pose
	_apply_pose(0.016)


## ---- THE BUBBLE HELMET. docs/STYLE_GUIDE.md R2.7, straight from the user: *"The astronaut
## character reads more like a scuba diver."* R2.7's diagnosis is exact and this function is the
## answer to it. The old build was a tight shell hugging the head with a window punched dead-centre
## in it, ringed by white all the way round — a wetsuit hood wearing a dive mask. What the three
## references (reference/"astronaut 1-3.jpeg") all do instead:
##
##   1. a big rigid bubble, clearly wider than the head, sitting ON a visible collar (`_build_collar`);
##   2. a LARGE dark visor filling the front, pitched DOWN (WINDOW_TILT) so a clean crown of shell
##      shows above it and only a thin lip below — never an oval floating in a white disc;
##   3. two crisp comma highlights on the pane, the big one upper-left and a small bead lower-right
##      (reference/"astronaut 2.jpeg" has exactly this pair);
##   4. side EAR PODS: a short cylindrical housing on each side of the dome. Small, but it is a
##      strong astronaut signal and we had none.
##
## GONE, and not coming back: the orange spine ridge that ran over the crown. The user read it as a
## crack down the middle of the helmet, and they were right — a raised meridian with an accent edge
## is a seam, and seams on a pressure vessel read as damage. Two earlier attempts at breaking up the
## rear dome are also recorded as failures: a concentric colour split read as a beanie, and a single
## high port read as an eye. This build does not try a third: the value break on the back now comes
## from things that are actually THERE on a spacesuit — the rear shell segment (a latitude band that
## runs off both silhouette edges, so it cannot be mistaken for a feature), the collar flange, the
## two ear pods breaking the outline, and the life-support pack rising behind the shoulders.
func _build_helmet(helm: Node3D, m_dome: ShaderMaterial,
		m_rim: ShaderMaterial, m_shell_back: ShaderMaterial, m_pod: ShaderMaterial,
		m_panel_dark: ShaderMaterial, m_metal: ShaderMaterial, visor: Color) -> void:
	var shell_mi := _mi(AstroShapes.helmet_shell(HELMET_R, WINDOW_ANGLE, SHELL_THICK, SEG_HELMET, RING_HELMET, HELMET_SPLIT_RING, WINDOW_TILT),
			null, helm, Vector3.ZERO, "Shell")
	shell_mi.set_surface_override_material(0, m_dome)
	if shell_mi.mesh.get_surface_count() > 1:
		shell_mi.set_surface_override_material(1, m_shell_back)
	# The shell CASTS its shadow again. It used to be excluded from the shadow map (docs/OPEN_ISSUES.md
	# issue 1: a crawling golf-ball stipple across the dome, luma sigma swinging 0.0035 -> 0.0124
	# between consecutive walk frames) — which cost the character half of its ground shadow and made
	# it read as a sticker. Re-measured at noon in the real environment after the environment
	# builder's shadow fix: high-frequency luma energy inside the dome is 0.0006 rms with casting ON
	# and 0.0006 with it OFF, so the cheat now buys nothing and the head shadow is worth more.

	# The visor pane sits at the INNER shell radius, so the window is a real 2 cm recess with the
	# rim wall as its bevel, and shell + rim wall + pane is a closed solid (no inner lining needed).
	var pane_r := Vector3(HELMET_R.x - SHELL_THICK, HELMET_R.y - SHELL_THICK, HELMET_R.z - SHELL_THICK)
	var pane := _mi(AstroShapes.glass_cap(pane_r, WINDOW_ANGLE, SEG_HELMET, RING_VISOR, WINDOW_TILT),
			_visor_mat(visor), helm, Vector3.ZERO, "Visor")
	pane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# thin raised accent rim around the window
	_mi(AstroShapes.cap_tube(HELMET_R, WINDOW_ANGLE, 0.0, TAU, 0.0105, 0.0072, SEG_RIM, SIDES_RIM, false, WINDOW_TILT),
			m_rim, helm, Vector3.ZERO, "Rim")

	# TWO comma highlights (R2.7 point 2). The big one sweeps across the upper-left of the pane; the
	# small bead sits lower-right, the way a cartoon visor is nearly always drawn. Both are painted
	# ON the pane at a hair over its radius, both taper to nothing at each end, and both are unlit —
	# they are highlights, not geometry, so they must not pick up a second highlight of their own.
	var streak_r := Vector3(pane_r.x + 0.004, pane_r.y + 0.004, pane_r.z + 0.004)
	var streak := _mi(AstroShapes.cap_band(streak_r, WINDOW_ANGLE * 0.62, deg_to_rad(101.0), deg_to_rad(164.0), 0.030, true, 18, WINDOW_TILT),
			_streak_mat(), helm, Vector3.ZERO, "Streak")
	streak.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var bead := _mi(AstroShapes.cap_band(streak_r, WINDOW_ANGLE * 0.66, deg_to_rad(-46.0), deg_to_rad(-19.0), 0.026, true, 10, WINDOW_TILT),
			_streak_mat(), helm, Vector3.ZERO, "StreakBead")
	bead.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# ---- the rear shell segment. Built in a frame whose cap axis points UP instead of forward,
	# because `cap_tube`'s rings are concentric with whatever the node's -Z is: concentric with the
	# WINDOW, every back detail comes out as a circle floating in the middle of a white disc, which
	# is how the previous two attempts ended up reading as a mouth and then as an eye. Rotated to
	# the vertical axis, the same call produces a LATITUDE band that runs off both silhouette edges
	# — a shell joint, which cannot be mistaken for a facial feature.
	# Rx(+90 deg) maps local -Z to world +Y, and local (x, y, z) to world (x, -z, y), so the radii
	# permute the same way. In this frame alpha is measured DOWN from straight up, beta 0 is the
	# character's right and beta 90 the back, so beta -10..190 is exactly the rear half of the dome.
	# The plate runs from the equator DOWN past the bottom of the dome, so it has no lower edge of
	# its own: it is the shell's lower rear segment seating into the collar, not a shape drawn on a
	# circle. (A band with a visible bottom edge, tried first, read as a grin from behind.)
	# `cap_tube` centres its cross-section ON the surface and dips half of it inside, which at these
	# near-tangent angles z-fights into a sawtooth — so every flat detail is built on a slightly
	# inflated ellipsoid and floats clear of the shell.
	# SIZE MATTERS HERE, and the first attempt at this rebuild got it wrong: run the segment from the
	# equator down and it paints the entire lower half of the dome navy, with its top edge cutting a
	# hard horizontal line across the back of the head — a helmet sawn in half, which is the *same*
	# defect the user reported as "an orange seam down the middle that reads as a crack", just
	# rotated 90 degrees. So the segment is confined to the bottom quarter (alpha 137..176 deg), it
	# takes the COLLAR's own colour so it reads as the hard neck assembly continuing up into the
	# shell rather than as a painted zone, and it has NO accent edge at all. Nothing on this helmet
	# draws a line across it any more.
	var band := _node("BackBand", helm, Vector3.ZERO)
	band.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	var band_r := Vector3(HELMET_R.x, HELMET_R.z, HELMET_R.y)
	_mi(AstroShapes.cap_patch(_inflate(band_r, 0.008), deg_to_rad(137.0), deg_to_rad(176.0), deg_to_rad(-16.0), deg_to_rad(196.0), 14, 3),
			m_shell_back, band, Vector3.ZERO, "Plate")

	# ---- EAR PODS (R2.7 point 3), one per side at the dome's widest point, just above the visor's
	# centre line. Sized off reference/"astronaut 2.jpeg", whose pod is ~21 % of the dome diameter;
	# ours is 0.17 across a 0.79 dome. A hard cylinder with a dark face plate and an accent ring is
	# unmistakably hardware, it puts a real bump in the silhouette from EVERY angle (including the
	# back, which is where the gameplay camera lives), and it is the cheapest astronaut cue we were
	# missing. These replace the old "hose connectors", which were half the size and mounted low and
	# rearward where they mostly disappeared behind the shoulders.
	for sx: float in [-1.0, 1.0]:
		var pod := _surface_node("EarPod", helm, Vector3(1.0 * sx, -0.10, 0.10), HELMET_R, -0.030)
		_mi(_cylinder(0.083, 0.088, 0.072, SEG_HW), m_pod, pod, Vector3(0.0, 0.030, 0.0), "Housing")
		_mi(_torus(0.070, 0.090, 12, 3), m_metal, pod, Vector3(0.0, 0.056, 0.0), "PodRing")
		# SEG_HW, not SEG_HW_SMALL: the pod face is the one piece of small hardware that sits on the
		# silhouette of the dome, and at 7 sides it read as a blue hexagon in a close-up.
		var face := _mi(_cylinder(0.052, 0.056, 0.020, SEG_HW), m_panel_dark, pod, Vector3(0.0, 0.072, 0.0), "PodFace")
		face.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# Status lamp on the rim, upper right of the window: with no face this is the only feature that
	# can blink, so it carries talk / surprise / happy (see `_apply_pose`). Kept small and dim.
	var lamp := _surface_node("Lamp", helm, AstroShapes.front_dir(WINDOW_ANGLE + 0.058, deg_to_rad(48.0), WINDOW_TILT), HELMET_R, 0.004)
	_lamp_mat = MaterialLib.glow(Color("#7fe9ff"), 1.0).duplicate() as ShaderMaterial
	var lamp_bead := _mi(_sphere(0.021, 7, 3), _lamp_mat, lamp, Vector3.ZERO, "Bead")
	lamp_bead.scale = Vector3(1.0, 0.65, 1.0)
	lamp_bead.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## ---- THE NECK RING (R2.7 point 1: *"meeting the suit at a visible collar/neck ring — a distinct
## band, not a smooth blend. This single change is most of the fix."*).
##
## Geometry note, because the numbers are load-bearing: the dome is a superellipsoid centred at
## HELMET_CY whose base is a point at y 0.710, and its surface has only widened to r ≈ 0.18 by
## y 0.742. So a barrel of radius COLLAR_R rising from the shoulders to COLLAR_TOP is SWALLOWED by
## the bubble at the top and shows as a real neck for ~9 cm below it, and the flange ring at
## COLLAR_RING_Y clamps exactly where the bubble narrows. Nothing here is placed by eye.
func _build_collar(m_barrel: ShaderMaterial, m_panel_dark: ShaderMaterial, m_band: ShaderMaterial,
		m_metal: ShaderMaterial) -> void:
	# Local space is the torso node, whose origin is the pelvis.
	var y0 := COLLAR_BASE - PELVIS_Y
	var y1 := COLLAR_TOP - PELVIS_Y
	var mid := (y0 + y1) * 0.5
	# The hard upper torso the bubble locks into: a slightly tapered barrel, in the SUIT one step
	# down rather than in the panel colour. It used to be panel blue, and a saturated band right
	# under the dome - the widest horizontal line on the character - was a large part of what the
	# orchestrator's note meant by "the large blue block on the torso". Every reference has a cream
	# neck section with a machined ring on it; the ring below is what makes the joint read, not paint.
	_mi(_cylinder(COLLAR_R - 0.006, COLLAR_R + 0.020, y1 - y0, 14), m_barrel, _torso, Vector3(0.0, mid, 0.0), "CollarBarrel")
	# The flange itself: a squashed torus standing proud of the barrel, in machined metal so it
	# reads as a mechanical joint rather than as more fabric.
	var flange := _mi(_torus(COLLAR_R - 0.010, COLLAR_RING_OUTER, 16, 3), m_metal, _torso,
			Vector3(0.0, COLLAR_RING_Y - PELVIS_Y, 0.0), "CollarRing")
	flange.scale = Vector3(1.0, 0.42, 1.0)
	# The shoulder YOKES are gone, and this is deliberate. They were rounded boxes half-buried in the
	# bean, and the intersection of a box with a rounded box at a shallow angle is a ragged curve:
	# zoomed in on the three-quarter view they read as a torn blue patch stuck to the shoulder, not
	# as a hard cap. Widening the torso made it worse. The hard shoulder joint is now carried by the
	# arm's own bearing sphere (see `_build`), which is a clean silhouette bump from every angle and
	# is what reference/"astronaut 3.jpeg" actually has; the barrel-to-bean seam the yokes used to
	# hide is cream-on-cream now that the barrel is suit-coloured, so there is nothing left to hide.


## ---- THE CHEST CONTROL PANEL (R2.7 point 5: *"a rectangular box on the chest with a few small
## buttons or dials"*). This is the piece that replaces the vertical placket — a stripe down the
## middle of the chest is a wetsuit zip, and it was doing real damage to the read.
## Modelled on reference/"astronaut 3.jpeg", which has a wide instrument block with a row of small
## coloured dials, plus reference/"astronaut 2.jpeg"'s simpler box with one warm dot.
func _build_chest_panel(m_panel: ShaderMaterial, m_panel_dark: ShaderMaterial, m_accent: ShaderMaterial,
		accent: Color, panel: Color) -> void:
	var chest := _node("ChestPanel", _torso, Vector3(0.0, 0.238, -0.186))
	_mi(_rounded_box(Vector3(0.196, 0.112, 0.030), 0.018, 10), m_panel, chest, Vector3.ZERO, "Case")
	_mi(_rounded_box(Vector3(0.166, 0.058, 0.022), 0.010, 6), m_panel_dark, chest, Vector3(0.0, 0.016, -0.012), "Screen")
	# Four small dials in a row along the bottom of the case. One takes the accent, the others are
	# muted instrument colours — R2.6 wants saturated things to be small, and these are 1.6 cm wide.
	var dial_cols: Array[Color] = [accent, panel.darkened(0.45), Color("#8fd6c8").darkened(0.18), Color("#c9cfdd").darkened(0.15)]
	for i in 4:
		var m_dial := m_accent if i == 0 else _shell_toon(dial_cols[i], {"limb": 0.18})
		var dial := _mi(_cylinder(0.016, 0.016, 0.016, 5), m_dial, chest, Vector3(-0.060 + 0.040 * float(i), -0.034, -0.016), "Dial")
		dial.rotation.x = PI * 0.5


## Warm-shift for the accent BANDS, rim and cuffs (docs/STYLE_GUIDE.md R2.7 point 4 asks for
## "orange/amber accent bands", and all three references use a clear amber around hue 30 deg).
## The shipped default `accent_color` #ff7a59 sits at hue 12 deg and renders as a coral RED, which
## is the one colour note that still read wrong against the reference sheet.
##
## Rather than overriding the player's colour, this nudges the hue toward amber by AT MOST
## BAND_HUE_PULL: a red-orange accent lands on amber, while a violet or teal accent (the clothes
## store sells both) moves by a fifth of a hue step and stays unmistakably itself. Saturation and
## value are untouched. Everything else the accent paints — the chest dial, the pack trim — keeps
## the player's exact colour, so the choice still reads on the character.
static func _band_hue(c: Color) -> Color:
	var h := c.h
	var d := BAND_HUE_TARGET - h
	if d > 0.5:
		d -= 1.0
	elif d < -0.5:
		d += 1.0
	return Color.from_hsv(fposmod(h + clampf(d, -BAND_HUE_PULL, BAND_HUE_PULL), 1.0), c.s, c.v, c.a)


## Hardware grey: the panel hue at a capped saturation and a fixed value. See the note in `_build`.
static func _hardware(c: Color, s_cap: float, v: float) -> Color:
	return Color.from_hsv(c.h, minf(c.s, s_cap), v, c.a)


## Rule 1 of the dome/visor contrast law (see DOME_MIN_V). The helmet shell may never be darker
## than DOME_MIN_V, whatever the suit is: every reference astronaut has a light dome, and a dark
## dome leaves the visor nothing to be a hole IN.
##
## The lift keeps the HUE and sheds chroma in proportion to how far the value had to travel
## (`s * v / DOME_MIN_V` holds the absolute chroma roughly constant), because lifting value alone on
## a saturated midnight navy gives a vivid cornflower shell — the Deep Space Suit would have gone
## from black ball to blue ball. Instead #2e3760 becomes a pale slate-navy: still unmistakably that
## suit's colour, and exactly the "navy with cream" its shop icon shows.
static func _dome_albedo(c: Color) -> Color:
	if c.v >= DOME_MIN_V:
		return c
	var k := c.v / DOME_MIN_V
	return Color.from_hsv(c.h, minf(c.s * k, DOME_MAX_S), DOME_MIN_V, c.a)


## Rule 2 of the dome/visor contrast law. The pane's value is capped BOTH at a fraction of the
## dome's and at a fixed drop below it, then floored so it never crushes to black. Hue and
## saturation are the caller's (so `visor_tint` still shifts the pane warm or cool); only the value
## is re-seated. With DOME_MIN_V 0.66 the darkest a dome can be, the pane lands at 0.25 or below —
## a value ratio of at least 2.6:1 against the shell before the shader's own ramps, which push the
## two further apart because the pane's `shade_floor` is flat where the dome's limb darkening is not.
static func _visor_color(base: Color, dome: Color) -> Color:
	var ceiling := maxf(minf(dome.v * VISOR_V_RATIO, dome.v - VISOR_MIN_DROP), VISOR_MIN_V)
	if base.v <= ceiling:
		return base
	return Color.from_hsv(base.h, base.s, ceiling, base.a)


## Prints the dome/visor value relationship for a list of style dictionaries. Used by
## `showcase/astronaut_wardrobe.tscn --contrast` to prove the law holds for every shop suit without
## anyone having to eyeball 17 renders; the numbers are ALBEDO, the renders are the real evidence.
static func contrast_row(style: Dictionary) -> Dictionary:
	var suit := Color(str(style.get("suit_color", "#f4f4f8")))
	var tint_k := SUIT_TINT * pow(clampf(suit.get_luminance(), 0.0, 1.0), 1.2)
	var suit_albedo := suit.darkened(SUIT_DARKEN).lerp(SUIT_TINT_COLOR, tint_k)
	var dome := _dome_albedo(suit_albedo)
	var visor := _visor_color(VISOR_NAVY.lerp(Color(str(style.get("visor_tint", "#6fc3ff"))).darkened(0.62), 0.35), dome)
	return {
		"suit": suit.to_html(false), "dome": dome.to_html(false), "visor": visor.to_html(false),
		"dome_v": dome.v, "visor_v": visor.v, "ratio": dome.v / maxf(visor.v, 0.001),
	}


## A band around a limb: the "band around the limb, not a stripe down the middle" that R2.7 point 4
## asks for, eight times per astronaut. `r` is the limb radius it rides, `proud` how far it stands
## off it, `h` its height along the limb.
##
## A short CYLINDER, not a torus: it is the more accurate shape (a suit band is a sleeve of webbing
## clamped round the limb, not a doughnut), it has crisp edges where a torus has a soft roll — which
## R2.3 asks for — and it costs 48 triangles against a torus's 112. With sixteen rings on the model
## that difference alone is a thousand triangles against a 6,000 budget.
func _band_ring(parent: Node3D, mat: ShaderMaterial, r: float, pos: Vector3, n: String,
		proud: float = 0.009, h: float = BAND_HEIGHT) -> MeshInstance3D:
	return _mi(_cylinder(r + proud, r + proud, h, 10), mat, parent, pos, n)


## Ellipsoid radii grown by `d` in every axis — flat details are built on an inflated shell so the
## near-tangent half of a `cap_tube` cross-section cannot z-fight against the dome.
static func _inflate(r: Vector3, d: float) -> Vector3:
	return Vector3(r.x + d, r.y + d, r.z + d)


## A node sitting on the helmet ellipsoid in direction `dir`, with its local +Y along the outward
## surface normal, lifted `lift` metres off the surface. Torus / cylinder details are Y-axis aligned,
## so this is how a hardware detail gets planted flush on a curved dome.
func _surface_node(n: String, parent: Node, dir: Vector3, r: Vector3, lift: float) -> Node3D:
	var d := dir.normalized()
	# The shell is a superellipsoid (AstroShapes.SHELL_EXP), so a hardware boss placed with the plain
	# ellipsoid formula sinks up to 7 mm into a chamfer. Both come from AstroShapes now.
	var pos := AstroShapes.surface_point(r, d)
	var nrm := AstroShapes.surface_normal(r, d)
	var nd := _node(n, parent, pos + nrm * lift)
	nd.basis = Basis.looking_at(nrm, Vector3.UP) * Basis(Vector3.RIGHT, -PI * 0.5)
	return nd


## Hats sit on the helmet (local space = helmet centre). Sizes follow the 0.70 m helmet.
func _build_hat(hat: Node3D, hat_id: String, accent: Color) -> void:
	match hat_id:
		"hat_cap":
			# The Animal Crossing ball cap from reference/"AC Reference 2 copy.jpg": a soft dome
			# clamped over the crown with a wide rounded brim above the visor window.
			var m_cap := _shell_toon(accent, {"limb": 0.22})
			var m_cap_dark := _shell_toon(accent.darkened(0.3), {"limb": 0.18})
			# Built on the shell's own superellipsoid, inflated by 19 mm, so the dome hugs the squircle
			# helmet everywhere instead of floating off the flat sides and being punched through at the
			# chamfers (which is what any single-radius sphere does now).
			var cap_node := _node("Cap", hat, Vector3.ZERO)
			_mi(AstroShapes.hair_cap(_inflate(HELMET_R, 0.019), 0.016, {
				"front_deg": 45.0, "side_deg": 67.0, "back_deg": 90.0,
				"scallop_deg": 0.0, "scallops": 1, "part_deg": 0.0,
			}, 28, 8), m_cap, cap_node, Vector3.ZERO, "Dome")
			var brim := _mi(_rounded_box(Vector3(0.45, 0.05, 0.27), 0.022, 14), m_cap_dark, cap_node, Vector3(0.0, 0.276, -0.34), "Brim")
			brim.rotation.x = -0.14
			_mi(_sphere(0.027, 10, 5), m_cap_dark, cap_node, Vector3(0.0, 0.393, 0.0), "Button")
			# A raised badge instead of a painted logo — the face-decal shader is gone with the face.
			var badge := _mi(_rounded_box(Vector3(0.115, 0.075, 0.02), 0.03, 10), m_cap_dark, cap_node, Vector3(0.0, 0.300, -0.268), "Badge")
			badge.rotation.x = deg_to_rad(-42.0)
		"hat_antenna":
			var m_base := MaterialLib.metal(Color("#8fa3bf"), {"spec": 0.35})
			var m_glow := MaterialLib.glow(Color("#7fffd4"), 2.4)
			var base := _node("AntennaBase", hat, Vector3(0.0, HELMET_R.y - 0.03, 0.0))
			var dome := _mi(_sphere(0.075, 14, 7), m_base, base, Vector3.ZERO, "Dome")
			dome.scale = Vector3(1.35, 0.6, 1.35)
			for sx: float in [-1.0, 1.0]:
				var stalk := _node("Stalk", base, Vector3(0.038 * sx, 0.02, 0.0))
				stalk.rotation.z = -0.42 * sx
				_mi(_cylinder(0.009, 0.013, 0.2, 8), m_base, stalk, Vector3(0.0, 0.10, 0.0), "Rod")
				_mi(_sphere(0.04, 12, 6), m_glow, stalk, Vector3(0.0, 0.215, 0.0), "Bulb")
		"hat_crown":
			var m_gold := MaterialLib.metal(Color("#ffcf4a"), {"spec": 0.5, "spec_size": 160.0})
			var m_gold_dark := MaterialLib.metal(Color("#d9a12a"), {"spec": 0.35})
			var crown := _node("Crown", hat, Vector3(0.0, 0.288, 0.0))
			_mi(_cylinder(0.225, 0.245, 0.05, 24), m_gold_dark, crown, Vector3.ZERO, "Band")
			_mi(_torus(0.222, 0.262, 24, 6), m_gold, crown, Vector3(0.0, 0.024, 0.0), "Ring")
			var gems: Array[Color] = [Color("#ff5d8f"), Color("#5dd0ff"), Color("#8dff7a"), Color("#ffd35d"), Color("#c47aff")]
			for i in 5:
				var a := TAU * float(i) / 5.0 + PI
				var spike := _node("Spike", crown, Vector3(0.235 * sin(a), 0.03, -0.235 * cos(a)))
				spike.rotation = Vector3(0.0, a, 0.0)
				var cone := _mi(_cylinder(0.0, 0.042, 0.11, 10), m_gold, spike, Vector3(0.0, 0.055, 0.0), "Cone")
				cone.rotation.x = 0.3
				_mi(_sphere(0.026, 10, 5), MaterialLib.glow(gems[i], 1.6), spike, Vector3(0.0, 0.115, -0.033), "Gem")
		_:
			pass


## Packs sit on the small torso, right under the enormous helmet. Every antenna is therefore SHORT
## and mounted low and outboard: the original 0.16-0.18 m rods put their blinking light at world
## y 0.76-0.82, which pushed a dark navy rod up through the collar beside the helmet (and the bulb
## inside the dome) in every back and gameplay frame.
##
## R2.7 point 6 asks for "a backpack (life-support pack) that reads clearly from the SIDE and BACK
## as a box or a pair of cylinders behind the shoulders". The old default pack was 0.125 m deep and
## sat flush against a 0.375 m torso, so from the side it was a bump and from the front it did not
## exist at all. Every variant is now deeper, taller and pushed further out, and every variant ends
## in TWO JET NOZZLES (`_jet_nozzles`), because R2.8's boost has to come out of a real hole in a
## real pack whichever pack the player is wearing.
func _build_backpack(pack: Node3D, pack_id: String, panel: Color, accent: Color, m_metal: ShaderMaterial, m_dark_metal: ShaderMaterial) -> void:
	# One value step UP from the old panel.darkened(0.18): from BEHIND — which is where the gameplay
	# camera lives — a dark box on a dark hip block was one unreadable mass.
	# R2.9: the pack is the largest single object on the character after the dome from the gameplay
	# camera's own angle, so it is METAL — brushed grain and the shared travelling sheen.
	var m_shell := _shell_toon(panel, _surf(SURF_METAL, {"limb": 0.22}))
	var m_lid := _shell_toon(panel.darkened(0.40), _surf(SURF_METAL, {"limb": 0.20}))
	var m_accent := _shell_toon(accent, {"limb": 0.22})
	var m_light := MaterialLib.glow(Color("#ff5a5a"), 2.0).duplicate() as ShaderMaterial
	_antenna_mat = m_light
	match pack_id:
		"pack_rocket":
			_mi(_rounded_box(Vector3(0.29, 0.30, 0.15), 0.05, 14), m_shell, pack, Vector3.ZERO, "Shell")
			_mi(_rounded_box(Vector3(0.25, 0.036, 0.13), 0.014, 10), m_lid, pack, Vector3(0.0, 0.152, 0.0), "Lid")
			for sx: float in [-1.0, 1.0]:
				_mi(_capsule(0.058, 0.30, SEG_HW_SMALL, RINGS_LIMB), m_metal, pack, Vector3(0.080 * sx, -0.015, 0.098), "Tank")
				_mi(_cylinder(0.066, 0.066, 0.030, 10), m_accent, pack, Vector3(0.080 * sx, 0.058, 0.098), "TankBand")
				var fin := _mi(_rounded_box(Vector3(0.022, 0.12, 0.08), 0.009, 10), m_accent, pack, Vector3(0.166 * sx, -0.075, 0.020), "Fin")
				fin.rotation.z = 0.15 * sx
				_jet_nozzle(pack, Vector3(0.080 * sx, -0.196, 0.098), m_dark_metal, m_accent)
			_mi(_cylinder(0.008, 0.011, 0.075, 8), m_dark_metal, pack, Vector3(0.116, 0.062, 0.062), "Antenna")
			_mi(_sphere(0.026, 7, 3), m_light, pack, Vector3(0.116, 0.115, 0.062), "AntennaLight")
		"pack_jet":
			var m_jet_shell := _shell_toon(accent.darkened(0.34), _surf(SURF_METAL, {"limb": 0.22}))
			_mi(_rounded_box(Vector3(0.27, 0.29, 0.15), 0.055, 14), m_jet_shell, pack, Vector3(0.0, 0.0, -0.005), "Shell")
			_mi(_rounded_box(Vector3(0.17, 0.17, 0.04), 0.018, 12), m_shell, pack, Vector3(0.0, 0.018, 0.075), "Plate")
			var vent_mat := MaterialLib.glow(Color("#7fd0ff"), 1.6).duplicate() as ShaderMaterial
			_jet_mats.append(vent_mat)
			_mi(_rounded_box(Vector3(0.1, 0.026, 0.018), 0.008, 8), vent_mat, pack, Vector3(0.0, 0.030, 0.095), "Vent")
			for sx: float in [-1.0, 1.0]:
				var thr := _node("Thruster", pack, Vector3(0.168 * sx, -0.05, 0.03))
				thr.rotation.z = -0.2 * sx
				_mi(_capsule(0.044, 0.23, SEG_HW_SMALL, RINGS_LIMB), m_metal, thr, Vector3.ZERO, "Body")
				_mi(_cylinder(0.050, 0.050, 0.030, 10), m_accent, thr, Vector3(0.0, 0.072, 0.0), "Band")
				_jet_nozzle(thr, Vector3(0.0, -0.112, 0.0), m_dark_metal, m_accent)
			_mi(_cylinder(0.008, 0.011, 0.07, 8), m_dark_metal, pack, Vector3(0.100, 0.082, 0.052), "Antenna")
			_mi(_sphere(0.024, 7, 3), m_light, pack, Vector3(0.100, 0.131, 0.052), "AntennaLight")
		_:
			# The default life-support pack: a deep box with a dark lid, two tanks standing proud on
			# the outside so the SIDE view has a stack of cylinders, and two nozzles underneath.
			_mi(_rounded_box(Vector3(0.30, 0.30, 0.168), 0.055, 12), m_shell, pack, Vector3.ZERO, "Shell")
			_mi(_rounded_box(Vector3(0.26, 0.038, 0.148), 0.015, 6), m_lid, pack, Vector3(0.0, 0.152, 0.0), "Lid")
			_mi(_rounded_box(Vector3(0.19, 0.090, 0.030), 0.012, 8), m_lid, pack, Vector3(0.0, -0.080, 0.090), "Hatch")
			for sx: float in [-1.0, 1.0]:
				_mi(_capsule(0.048, 0.26, SEG_HW_SMALL, RINGS_LIMB), m_metal, pack, Vector3(0.104 * sx, 0.010, 0.100), "Tank")
				_mi(_cylinder(0.056, 0.056, 0.030, 10), m_accent, pack, Vector3(0.104 * sx, 0.082, 0.100), "TankBand")
				_mi(_sphere(0.020, 7, 3), m_lid, pack, Vector3(0.104 * sx, 0.156, 0.100), "Valve")
				_jet_nozzle(pack, Vector3(0.122 * sx, -0.172, 0.058), m_dark_metal, m_accent)
			_mi(_cylinder(0.008, 0.011, 0.075, 8), m_dark_metal, pack, Vector3(0.124, 0.058, 0.058), "Antenna")
			_mi(_sphere(0.026, 7, 3), m_light, pack, Vector3(0.124, 0.112, 0.058), "AntennaLight")


## One jetpack thruster nozzle: a short cone with a glowing throat, plus an (invisible) marker whose
## -Y is the exhaust direction. `_jet_nozzles` is what the boost puffs are spawned from, so every
## pack variant reaches the same place in `set_boost_thrust`. The nozzle is pitched back 20 deg so
## the exhaust goes down AND behind the astronaut instead of straight through the boots.
func _jet_nozzle(parent: Node3D, pos: Vector3, m_dark_metal: ShaderMaterial, m_accent: ShaderMaterial) -> void:
	var nz := _node("Nozzle", parent, pos)
	nz.rotation.x = deg_to_rad(-20.0)
	_mi(_cylinder(0.040, 0.058, 0.062, SEG_HW), m_dark_metal, nz, Vector3(0.0, -0.020, 0.0), "Cone")
	_mi(_cylinder(0.056, 0.056, 0.024, SEG_HW), m_accent, nz, Vector3(0.0, 0.006, 0.0), "Collar")
	var throat_mat := MaterialLib.glow(Color("#9bdcff"), 1.2, Color("#ffd9a0")).duplicate() as ShaderMaterial
	_jet_mats.append(throat_mat)
	var throat := _mi(_cylinder(0.034, 0.034, 0.010, SEG_HW_SMALL), throat_mat, nz, Vector3(0.0, -0.048, 0.0), "Throat")
	throat.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_jet_nozzles.append(nz)


func _make_sparkles() -> GPUParticles3D:
	var gp := GPUParticles3D.new()
	gp.name = "Sparkles"
	gp.emitting = false
	gp.one_shot = true
	gp.amount = 22
	gp.lifetime = 1.0
	gp.explosiveness = 0.85
	gp.local_coords = false
	gp.visibility_aabb = AABB(Vector3(-2, -2, -2), Vector3(4, 4, 4))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.45
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 80.0
	pm.initial_velocity_min = 0.8
	pm.initial_velocity_max = 2.0
	pm.gravity = Vector3.ZERO
	pm.damping_min = 1.5
	pm.damping_max = 2.5
	pm.angular_velocity_min = -180.0
	pm.angular_velocity_max = 180.0
	var sc := Curve.new()
	sc.add_point(Vector2(0.0, 0.3))
	sc.add_point(Vector2(0.25, 1.0))
	sc.add_point(Vector2(1.0, 0.0))
	var sct := CurveTexture.new()
	sct.curve = sc
	pm.scale_curve = sct
	pm.scale_min = 0.6
	pm.scale_max = 1.2
	var grad := Gradient.new()
	grad.set_color(0, Color("#fff6c8"))
	grad.set_color(1, Color("#ffe27a"))
	var gt := GradientTexture1D.new()
	gt.gradient = grad
	pm.color_ramp = gt
	gp.process_material = pm
	var quad := QuadMesh.new()
	quad.size = Vector2(0.16, 0.16)
	var mat := MaterialLib.flat_unlit(Color.WHITE, true).duplicate() as StandardMaterial3D
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = _get_star_texture()
	mat.billboard_keep_scale = true
	quad.material = mat
	gp.draw_pass_1 = quad
	return gp


## Small 4-point sparkle texture generated in code (shared).
static func _get_star_texture() -> ImageTexture:
	if _star_tex:
		return _star_tex
	var n := 48
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var u := (float(x) + 0.5) / n * 2.0 - 1.0
			var v := (float(y) + 0.5) / n * 2.0 - 1.0
			var star := 1.0 - (sqrt(absf(u)) + sqrt(absf(v)))
			var core := 1.0 - (u * u + v * v) * 4.0
			var a := clampf(maxf(star * 1.6, core), 0.0, 1.0)
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, a))
	_star_tex = ImageTexture.create_from_image(img)
	return _star_tex


# ============================================================================= mesh helpers
## Cache for the model-local materials (the suit shell shader, the visor pane, the streak).
static var _mat_cache: Dictionary = {}


## The suit's toon material: src/player/astro_shell.gdshader, i.e. the house toon look plus limb
## darkening and a darker underside, because a big smooth near-white suit has no value gradient
## otherwise. opts: limb, floor, spec, rim, softness, shade.
##
## R2.9 SURFACE (docs/STYLE_GUIDE.md). The same vocabulary as MaterialLib.toon's `surface` option,
## because astro_shell.gdshader includes the same src/shaders/surface_detail.gdshaderinc:
##   "surface"          - "cloth" | "metal" | "rock" (the kinds this character uses)
##   "surface_strength" - 0..2, default 1.0
##   "surface_near/far" - the FINE grain's fade in metres (defaults SURFACE_NEAR/SURFACE_FAR)
##   "sheen"            - sd_sheen / sd_cloth_sheen amplitude; rides its own broad fade
##   "seam"             - seam+topstitch strength, with "seam_rings" per metre and "seam_gores"
## Merge one of the SURF_* R2.9 blocks with a material's own shading options. The SURF_* consts are
## read-only, so this duplicates rather than mutating them.
static func _surf(surface: Dictionary, extra: Dictionary = {}) -> Dictionary:
	var o: Dictionary = surface.duplicate()
	o.merge(extra, true)
	return o


static func _shell_toon(color: Color, opts: Dictionary) -> ShaderMaterial:
	var key := "shell|%s|%s" % [color.to_html(), str(opts)]
	if _mat_cache.has(key):
		return _mat_cache[key]
	var m := ShaderMaterial.new()
	m.shader = SHELL_SHADER
	m.set_shader_parameter("albedo", color)
	if opts.has("surface"):
		m.set_shader_parameter("surface_kind", SURFACE_KINDS.get(str(opts["surface"]), 0))
		m.set_shader_parameter("surface_strength", opts.get("surface_strength", 1.0))
		m.set_shader_parameter("surface_lod_near", opts.get("surface_near", SURFACE_NEAR))
		m.set_shader_parameter("surface_lod_far", opts.get("surface_far", SURFACE_FAR))
		m.set_shader_parameter("sheen_strength", opts.get("sheen", 0.0))
		m.set_shader_parameter("sheen_near", opts.get("sheen_near", SHEEN_NEAR))
		m.set_shader_parameter("sheen_far", opts.get("sheen_far", SHEEN_FAR))
	if opts.has("seam"):
		m.set_shader_parameter("seam_strength", opts["seam"])
		m.set_shader_parameter("seam_rings", opts.get("seam_rings", 0.0))
		m.set_shader_parameter("seam_gores", opts.get("seam_gores", 0.0))
		m.set_shader_parameter("seam_far", opts.get("seam_far", SEAM_FAR))
	m.set_shader_parameter("ramp_softness", opts.get("softness", 0.38))
	m.set_shader_parameter("shade_strength", opts.get("shade", 0.36))
	m.set_shader_parameter("rim_strength", opts.get("rim", 0.10))
	m.set_shader_parameter("spec_strength", opts.get("spec", 0.05))
	m.set_shader_parameter("limb_darken", opts.get("limb", 0.28))
	m.set_shader_parameter("floor_shade", opts.get("floor", 0.18))
	# Cast-shadow floor. The shader ships 0.10, which was fine while the limbs were mid-blue but is
	# not once the suit is cream everywhere: the torso's own shadow across the back of the thighs
	# rendered as a near-black hard-edged trapezoid that read as a hole in the leg. 0.22 keeps a
	# shadowed cream limb recognisably cream — docs/STYLE_GUIDE.md: "A surface in shadow should look
	# like the same happy colour in shade, never like dirt."
	m.set_shader_parameter("shadow_floor", opts.get("shadow_floor", 0.22))
	_mat_cache[key] = m
	return m


## The opaque navy visor pane (src/player/astro_visor.gdshader). Cached per tint.
static func _visor_mat(tint: Color) -> ShaderMaterial:
	var key := "visor|%s" % tint.to_html()
	if _mat_cache.has(key):
		return _mat_cache[key]
	var m := ShaderMaterial.new()
	m.shader = VISOR_SHADER
	m.set_shader_parameter("tint", Color(tint.r, tint.g, tint.b, 1.0))
	_mat_cache[key] = m
	return m


## The single crisp white streak painted on the visor pane (unlit, drawn over it).
static func _streak_mat() -> StandardMaterial3D:
	if _mat_cache.has("streak"):
		return _mat_cache["streak"]
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	# 0.55, not the old 0.82: on a navy pane a near-opaque white band is a blown highlight, and the
	# REVISION 2 gate is blown < 5% of the character crop.
	m.albedo_color = Color(0.92, 0.95, 1.0, 0.55)
	m.cull_mode = BaseMaterial3D.CULL_BACK
	m.render_priority = 2
	_mat_cache["streak"] = m
	return m


func _node(n: String, parent: Node, pos: Vector3) -> Node3D:
	var nd := Node3D.new()
	nd.name = n
	nd.position = pos
	parent.add_child(nd)
	return nd


func _mi(mesh: Mesh, mat: Material, parent: Node, pos: Vector3, n: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = n
	mi.mesh = mesh
	if mat:
		mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi


static func _sphere(r: float, seg: int = 24, rings: int = 12) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	m.radial_segments = seg
	m.rings = rings
	return m


static func _capsule(r: float, h: float, seg: int = 16, rings: int = 4) -> CapsuleMesh:
	var m := CapsuleMesh.new()
	m.radius = r
	m.height = maxf(h, r * 2.0)
	m.radial_segments = seg
	m.rings = rings
	return m


static func _cylinder(rt: float, rb: float, h: float, seg: int = 16) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = rt
	m.bottom_radius = rb
	m.height = h
	m.radial_segments = seg
	m.rings = 1
	return m


static func _torus(inner: float, outer: float, rings: int = 24, sides: int = 8) -> TorusMesh:
	var m := TorusMesh.new()
	m.inner_radius = inner
	m.outer_radius = outer
	m.rings = rings
	m.ring_segments = sides
	return m


## Rounded box built by pushing a sphere's vertices out to the box corners (smooth toon-friendly bevels).
static func rounded_box_mesh(size: Vector3, radius: float, seg: int = 20) -> ArrayMesh:
	return _rounded_box(size, radius, seg)


static func _rounded_box(size: Vector3, radius: float, seg: int = 20) -> ArrayMesh:
	var half := size * 0.5
	var r := minf(radius, minf(half.x, minf(half.y, half.z)))
	var sph := SphereMesh.new()
	sph.radius = 1.0
	sph.height = 2.0
	sph.radial_segments = seg
	sph.rings = int(float(seg) * 0.5)
	var arr: Array = sph.get_mesh_arrays()
	var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var norms := PackedVector3Array()
	var out := PackedVector3Array()
	out.resize(verts.size())
	norms.resize(verts.size())
	for i in verts.size():
		var n := verts[i].normalized()
		var p := n * r + Vector3(signf(n.x) * (half.x - r), signf(n.y) * (half.y - r), signf(n.z) * (half.z - r))
		# vertices right on an axis plane sit in the middle of a flat face; keep them centered
		if absf(n.x) < 0.02:
			p.x = 0.0
		if absf(n.z) < 0.02:
			p.z = 0.0
		out[i] = p
		norms[i] = n
	var mesh_arr: Array = []
	mesh_arr.resize(Mesh.ARRAY_MAX)
	mesh_arr[Mesh.ARRAY_VERTEX] = out
	mesh_arr[Mesh.ARRAY_NORMAL] = norms
	mesh_arr[Mesh.ARRAY_TEX_UV] = arr[Mesh.ARRAY_TEX_UV]
	mesh_arr[Mesh.ARRAY_INDEX] = arr[Mesh.ARRAY_INDEX]
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_arr)
	return am


## Placeholder held item: a chunky rounded cube in the item's icon color (until real decorations
## exist). Sized so the two mittens close on its side faces at the carry pose without it swallowing
## the whole torso.
static func make_item_placeholder(color: Color) -> ArrayMesh:
	var m := _rounded_box(Vector3(0.27, 0.25, 0.27), 0.075, 16)
	var mat := MaterialLib.toon(color, {"spec": 0.35})
	m.surface_set_material(0, mat)
	return m


## Height of the placeholder item (its origin is centered; pass half of this as the carry offset).
const PLACEHOLDER_ITEM_HEIGHT := 0.25
