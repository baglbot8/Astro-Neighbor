extends Node3D
## GUIDE THEM HOME - the third mini-game (docs/CORE_LOOP.md "More mini-games, one per neighbour",
## decided 2026-09-13; docs/BUILD_PLAN.md Phase 3). Companion to catch_game.gd and ring_game.gd on
## the same contract - read minigame_system.gd's header first.
##
## A few of the neighbour's things hover low over the ground near a home spot. They are SHY: when
## the astronaut comes close, a thing drifts away along the surface, away from the astronaut - the
## opposite rule to catch_game's runaways, which do not react to the player at all. Coming at one
## from the FAR side (the side away from home) therefore pushes it toward home; coming at it from
## the home side pushes it further out, where it is walled back into a band around home rather than
## let escape. Steer it - by walking, running or flying over it, all read the same way, ground
## distance only - until it drifts into the home spot itself, where it sinks in, glows and counts.
## First use: Fen's glow moths carried the light out of his pools; you guide them back to the edge
## of one.
##
## ============================================================================== CONFIG (all optional)
##   "count": 5                 how many things. 1-8 is the useful range.
##   "done": 2                  how many are ALREADY home (resuming a half-played game).
##   "flavour": "moth"          which art/colours, read from catch_game.gd's own FLAVOURS table (one
##                              source of truth since 2026-09-13 - see that file's header and
##                              ring_game.gd's identical reuse). Unknown flavours fall back to "moth".
##   "label": "glow moth"       noun for the toasts, singular. Default: the flavour's own.
##   "label_plural": "glow moths"  ...and plural.
##   "title": "Guide the glow moths home"   the line on the progress pill. Default "Guide the <plural>
##                              home".
##   "home_dir": [x, y, z]      planet-local unit direction of the home spot. Left out, the game picks
##                              a free, walkable spot of its own - see "PICKING HOME" below. A given
##                              direction is used as it is (the ring and glow still follow its ground),
##                              with one push_warning if the ground there is not level enough for the
##                              ring or sits at the waterline - a hint to the world builder, not a refusal.
##   "home_radius_m": 1.7       how close counts as "home". Clamped to HOME_RADIUS_RANGE. The ground
##                              ring drawn at the home spot is exactly this radius, so what you see is
##                              what counts.
##   "seed": 12345              fixes the layout. Default: hashed from the owner and the planet, so
##                              the same save always gets the same start and two captures match.
##   "npc": "fen"                optional neighbour id. Purely a courtesy: if given and that neighbour
##                              is standing in the world, they play a "happy" emote when the last
##                              thing settles (`NPC.play_emote`, an existing method call - not a new
##                              node, so it is fine under the contract). Nothing else reads it; a
##                              missing or unknown id just skips the emote.
##
## ============================================================================== PICKING HOME
## `home_dir` left out: the game SCORES a pool of candidates (`_home_spot_score`) and takes the best
## one, rather than gating on pass/fail and stopping at the first pass. It tries the RIM of the
## planet's own craters first, in random (seeded) order - Planet.gd's craters are the same soft bowls
## Fen's pools sit in (planet_props.gd's `_fen()`: "the 14 craters are pools, not hills") - on a world
## that HAS pools this puts the home spot at the edge of one, on dry ground, exactly rule 7's ask. The
## settle circle is centred HOME_EDGE_GAP_M beyond the rim so the WHOLE ring is dry land, never
## straddling the water. A world with no craters (grig, vela), or where the crater rims score badly,
## falls through to open ground (`Planet.find_free_dir`) and, only if that keeps failing too, a raw
## random pool - EVERY candidate from every one of those sources is scored the same way and the best
## of them all wins, so a hard world still gets its LEAST BAD spot rather than an unvetted one (round
## 2, finding 5 - see `_pick_home_dir`'s own header for what broke). Round 3 (finding B) adds the
## GROUND under the ring to that score (`_home_ground`): a spot whose rim and settle slots do not lie on
## one level-or-evenly-sloped patch - a terrace riser, a pool rim or a bump crossing the ring - loses to
## any spot that does, and so does one at the waterline or steeper than DecorationManager's walkable
## slope.
##
## ============================================================================== WHY THESE NUMBERS
## HOVER_HEIGHT_M sits at roughly torso height on the chibi astronaut and well under the 1.20 m jump
## apex (Player.JUMP_VELOCITY^2 / 2g), so a jump is never needed and never overshoots it - "steer a
## WALKING astronaut" (rule 1) is a height choice, not a speed one. FLEE_SPEED_MAX (3.4 m/s) is kept
## a firm margin under Player.WALK_SPEED (4.2 m/s): "you can always catch up" (rule 2) is a promise
## made by that margin, not by anything reactive. BAND_MARGIN_M keeps every thing within roughly
## home_radius + 5-8 m of home - comfortably inside the horizon on the smallest world this ships on
## (Fen, radius 13 m) and every other world, and small enough that "guide it home" stays a short,
## visible chase rather than a hike (rule 1's "never over the horizon").
##
## ============================================================================== WHY THE DECIDE CLOCK
## A thing's heading depends on the astronaut's LIVE position, so - unlike catch's fixed great
## circles or ring's static hoops - it cannot be pre-computed once in setup(). But testing "is the
## astronaut close, and is the way ahead clear of a prop/building/neighbour" every physics frame for
## every thing is the one part of this game with a real per-frame planet-query cost (OPEN_ISSUES 44:
## the phone runs hot). So the STEERING DECISION (flee-or-idle-or-escape, and the short obstacle sweep
## behind rule 3) is only remade DECIDE_HZ times a second per thing - the same idea as this system's
## own chevron pointer (POINTER_HZ, "it only has to be roughly right"); movement, ground height and
## the settle check still run every frame, off the last decision, so motion stays smooth at 60 fps. A
## reaction lag of at most 1/DECIDE_HZ seconds is not felt against a 3.6 m flee radius, and the escape
## hill-climb added in round 2 (see `_escape`) rides the SAME clock, not an extra one.
##
## ============================================================================== PHONE AND HEAT
## docs/OPEN_ISSUES.md 44: small node/draw budgets, one shared material per look, no GPUParticles3D -
## see catch_game.gd's own header. Each thing is TWO draw calls (a vertex-coloured body, one shared
## material per flavour; a soft additive halo, also shared) - the same shape of budget as a runaway
## or a hoop, and round 2's mesh/material now literally ARE catch_game's own cached resources (see
## "ROUND 2" below), so a world running both games shares them rather than doubling them. The home
## spot is a further two draw calls total (a ring, a ground glow), built ONCE in setup rather than per
## thing - round 3 builds both from the ground's own heights (about 650 and 480 triangles for the
## default 1.7 m ring; the same one draw call each, the height samples paid once in setup, never per
## frame); a SETTLED thing (round 2) adds no ongoing cost at all - it leaves `_items`, so it leaves the
## steering loop, and is otherwise a static prop. The steering decision's planet queries (see above)
## are the one cost a resting-thing game like ring_game.gd does not have; DECIDE_HZ is the mitigation,
## and this builder's report measures it on vs off rather than assuming the throttle is enough.
##
## ============================================================================== ROUND 2 (2026-09-13)
## The critic's round-1 pass FAILED on five measured points; this file's round-2 changes, one per
## point (each has its own comment at the fix site too):
##  1. FROZEN FOREVER. `_jitter_in_band` handed out spawn spots with no collision check at all, and a
##     thing that ever ended up "boxed" (nothing clear within one lookahead step) just held speed 0
##     forever. Fix: every start-spot source is now `_blocked`-tested (`_pick_start_dirs`,
##     `_jitter_in_band`), and a blocked thing always MOVES - `_decide` checks its current spot first,
##     unconditionally, and hill-climbs clear of it (`_escape`/`_hazard_pressure`) rather than holding.
##  2. PLAYS ITSELF. Idle drift alone could carry a thing into the home ring with no player input.
##     Fix: settling now requires the astronaut to have been in the thing's flee radius within the
##     last ~1.5 s (`last_guided_t`, checked in `_process`); idle headings steer clear of a keep-out
##     disc around home; things spawn at least 3 m outside the ring (`START_HOME_GAP_M`).
##  3. NOT A GLOW MOTH, NO SETTLE MOMENT. The custom shape read as a generic puffball, and a settled
##     thing shrank to nothing and was freed - so a resumed game showed no sign of what was already
##     home. Fix: the body/halo are now catch_game's own flavour mesh and materials, at catch size
##     (`CatchGame._body_mesh` etc.); a settled thing STAYS, parked in the ring at a visible size, and
##     resuming with `done` > 0 pre-places that many (`_spawn_settled_fixture`); the settle pulse is
##     bigger, on both the item and the home glow.
##  4. FULL-STICK CHASE CIRCLES. Running straight at a thing swings pure point-repulsion through ~180
##     degrees the instant the astronaut passes close by or through it, and chasing that flip in a
##     straight line circled instead of pushing forward. Fix: within CLOSE_PASS_RADIUS_M of a MOVING
##     astronaut, blend the flee heading toward the astronaut's own travel direction instead.
##  5. DEV-MENU START NOT SENSIBLE. The last-resort home spot (`random_surface_dir`) skipped every
##     safety check - no prop, water or slope test at all - so a config that exhausted the earlier,
##     gated attempts could put the ring right on top of a prop. Fix: `_pick_home_dir` scores every
##     candidate from every source, including that last resort, and always returns the best one it
##     saw, with no console warning for a spot that is merely imperfect rather than broken.
##
## ============================================================================== ROUND 3 (2026-09-13)
## Opus fix round 1, against the round-2 critic's blocking list (its evidence: phase3a/guide-critic2).
##  A. SETTLED THINGS WERE BURIED. The settle slot was a fixed local y (-0.12 m) on the home node's
##     TANGENT PLANE, which ignores both the planet's curvature (0.11 m down at 1.7 m on Fen) and the
##     terrain, so a live settle ended 0.08-0.09 m under the ground and a resumed fixture 0.10 m under -
##     and at scale 1.0, because `node.basis =` after `node.scale =` resets the scale. Only the wing tips
##     showed, like Fen's scrub. Fix: every settled thing rests on its own SLOT's real ground
##     (`_slot_local_position`: `height_at` under the whole body, plus the body's own lowest vertex, plus
##     SETTLED_CLEARANCE_M - a moth's origin sits ~0.15 m up), its halo shrinks to the body's width and
##     centres on the body so the glow stays above the ground (`_halo_rest_*`), and the fixture sets its
##     scale AFTER its basis. Slots are now one per thing, claimed nearest the arrival bearing
##     (`_claim_slot`), so two settled things never sit on top of each other and "how many are home"
##     can be counted in the ring.
##  B. THE HOME RING WAS A FLAT TORUS on the centre's tangent plane: buried across terrace risers on
##     grig (17 of 36 rim samples), bolt (16) and zorp (11, up to 0.24 m deep), floating up to 0.18 m
##     elsewhere. Fix: the ring is swept along the REAL ground (`_build_ring_mesh`: every cross-section
##     sits RING_GROUND_GAP_M above the highest `height_at` under its span), the ground glow is a
##     conformed disc too (`_build_glow_mesh`, its pulse now a UV scale so the geometry never leaves the
##     ground), and a picked home spot is rejected when the ground under the ring is not level
##     (`_home_ground`: the rim-to-ground gap a flat ring WOULD have had, with the curvature and any
##     smooth slope taken out - a terrace riser or a pool rim inside the ring shows up as a step).
##  Should-fix, both done: `_hazard_pressure` is now ordered (props and neighbours strictly before zones
##  and water, compared lexicographically), so escaping a zone can never pick a path through a
##  standing stone; and `_decide`/`_escape` write the item's heading and speed in place instead of
##  allocating an Array per decision.
##  Found while re-proving round 2's passes, and fixed at their sites: a neighbour walking at a thing
##  parked on the band wall could walk onto it (once in a real play; every time in a SYNTHETIC chase),
##  because `_escape` judged steps that the wall clamp would cancel and took the first of several tied
##  steps rather than the one furthest away (`_escape`, `_hazard_pressure`'s z); and a tall flavour's
##  body dipped into the ground at the peak of the settle pop (`_settle`).
##
## ============================================================================== ROUND 4 (2026-09-13)
## Opus fix round 2, against the fix-round-1 critic (its evidence: phase3a/guide-fixcritic1). NO CODE
## CHANGED: only the Fen `home_dir` handed to the world builder moved. Round 3 gave crater 5's cluttered
## side, (-0.6946, -0.0154, 0.7193) - a clean pool edge, but stones and the pool block 29% of its band
## (3-7 m out), and running at the moths there took a median 90 s (critic, 16 seeds; one moth needed
## 12 approaches). Crater 5's CLEAR side, (-0.2216, -0.0157, 0.9750), is the same pool edge (ring 1.0 m
## from the water, ground step 0.018 m, 0 of 36 rim samples buried) with the least blocked band of any
## clean pool-rim spot on Fen (14%; 24 spots per pool scanned): running took a median 42 s (16 seeds,
## max 80 s, at most 8 approaches to one moth) and walking only a median 41 s (8 seeds, max 59 s). All
## scripted plays through TouchControls' real routing (`debug_stick`, --ui=mobile); seeds and captures
## in phase3a/guide-fix2.
##
## ============================================================================== ROUND 5 (2026-09-13)
## Against the fix-round-2 critic (its evidence: phase3a/guide-fixcritic2). Two blockers, nothing else:
##  1. RESTING HALOS CLIPPED THE GROUND. catch_game's halo material billboards WITHOUT
##     billboard_keep_scale, so a billboard ignores every scale above it: `_halo_rest_scale` did nothing
##     and each resting halo drew 1.45 m wide, centred 0.22 m up, 16-22% of its soft dot under the
##     ground - five of them a hard-edged pale slab in the ring. Fix: a settled thing's halo switches to
##     ONE guide-owned copy of that material with billboard_keep_scale on (`_rest_halo_material`, cached
##     per glow colour like catch_game's own), so it really draws the body's width (0.58 m for the moth),
##     and `_measure_body` lifts its centre to at least its own drawn radius above the slot's ground, so
##     no part of the dot can reach the ground under any camera pitch (a billboard's lowest point is at
##     most one radius below its centre, reached under a level camera).
##  2. THE FINALE POPPED. `report_finished` ran as the last settle tween ended; the system frees this node,
##     so the ring, the glow and all the settled things vanished in one frame. Fix (the same shape as
##     hunt_game.gd's "WHY THE FINALE HOLDS"): the completion sound and the neighbour's emote play at once,
##     everything HOLDS for FINALE_HOLD_S, then over FINALE_FADE_S the settled things shrink down onto their
##     own ground, the ring sinks into the ground and the glow fades out - and only then does the game
##     report finished (`_process_finale`, `_finish`, guarded to run once). Progress was already reported
##     at each settle, so nothing waits on this. A stop() or a scene change during the finale frees the node
##     like any other moment: the finale is plain per-frame state on this node, with no timer or callback
##     that could outlive it.

## Metres above the ground under it. Low enough that a WALKING astronaut is already at the right
## height to nudge one - see "WHY THESE NUMBERS" above.
const HOVER_HEIGHT_M := 0.62
const BOB_M := 0.08
const BOB_HZ := 0.35

const DEFAULT_COUNT := 5
const COUNT_RANGE := Vector2i(1, 8)

const HOME_RADIUS_RANGE := Vector2(1.0, 3.0)
const DEFAULT_HOME_RADIUS_M := 1.7
## Band radius = home_radius_m + this. See "WHY THESE NUMBERS".
const BAND_MARGIN_M := 5.3

## Ground distance inside which a thing flees. Generous enough that walking up to one is a real
## chase; tight enough that merely passing near the home spot does not scatter everything loose.
const FLEE_RADIUS_M := 3.6
## Top flee speed, reached only right on top of it. See "WHY THESE NUMBERS" - kept under
## Player.WALK_SPEED (4.2 m/s) with a real margin, not a near-miss.
const FLEE_SPEED_MAX := 3.4
const IDLE_DRIFT_MS := 0.45
const IDLE_TURN_RAD_S := 0.5
const IDLE_TURN_HZ := 0.12
## How much of the flee heading is pulled toward home instead of straight away from the astronaut,
## AT the band wall (eased down to ~0 through the middle of the band - see `_decide`'s own comment,
## added after this builder's report measured a thing stuck on the rim for 130+ seconds without it).
const HOME_BIAS_AT_EDGE := 0.55

## ROUND 2, finding 4 ("full-stick chase circles"): inside this many metres of a MOVING astronaut,
## the flee heading blends toward the astronaut's own travel direction instead of pure point-away -
## see `_decide`'s comment at the blend site for why. MIN speed distinguishes "the astronaut is
## walking/running near it" from "the astronaut is standing still nearby", which should still get the
## ordinary point-repulsion (a stationary astronaut has no travel direction worth fleeing "along").
const CLOSE_PASS_RADIUS_M := 1.5
const CLOSE_PASS_MIN_SPEED_MS := 0.5

## ROUND 2, finding 2 ("plays itself"): a thing only counts as guided-home if the astronaut was in
## its flee radius within this many seconds - see `_process`'s settle check. Generous enough that a
## push landing the instant after the player moves on to chase another thing still counts.
const GUIDED_RECENCY_S := 1.5
## Idle wandering steers clear of a disc this much wider than home_radius_m - see `_decide`'s idle
## branch. Keeps a thing that is merely left alone from ever lingering at the ring's own door.
const IDLE_HOME_MARGIN_M := 2.0

## How often the steering decision (flee-or-idle-or-escape, obstacle sweep) is remade. See "WHY THE
## DECIDE CLOCK". 8 Hz: a lag of at most 0.125 s, well under anything felt against a 3.6 m flee
## radius.
const DECIDE_HZ := 8.0
const DECIDE_PERIOD_S := 0.125
## Rule 3, "slides free within 3 seconds": a blocked heading is replaced by the first of a small fan
## of alternatives that IS clear one lookahead step out, re-tried at the next decide tick (rotated by
## `escape_phase`) if all six were blocked THIS tick. When none is fully clear either, `_escape` takes
## over - see that function's own header for why (round 2, finding 1).
const ESCAPE_TRY_COUNT := 6
const MIN_LOOKAHEAD_M := 0.6
const PROP_CLEAR_M := 0.55
const NPC_CLEAR_M := 1.3

## ROUND 2, finding 1 ("frozen forever"): a thing whose CURRENT spot is already blocked - it spawned
## inside a footprint, or last frame's band-wall clamp parked it somewhere bad - hill-climbs clear of
## it (`_escape`/`_hazard_pressure`) rather than trying, and possibly failing, a single "is this
## heading clear" test. The step is a little longer than MIN_LOOKAHEAD_M so real headway is made even
## while still technically inside a wide footprint; the speed is brisk but calmer than a real flee,
## since nothing is chasing it - just enough that even a several-metre-deep start clears well inside
## rule 3's 3 s ceiling.
const ESCAPE_SWEEP_COUNT := 12
const ESCAPE_STEP_M := 0.9
const ESCAPE_SPEED_MS := 2.6
## How many band-jitter samples `_jitter_in_band` tries before giving up on finding an unblocked one.
const JITTER_TRIES := 16

const SPOT_CANDIDATES := 24
const ITEM_CLEARANCE_M := 0.45
## A thing never starts already "home". ROUND 2, finding 2: raised from 1.0 to 3.0 - a thing born
## only a metre outside the ring needed almost no idle drift at all to wander in with no input.
const START_HOME_GAP_M := 3.0
## Ground distance from the astronaut's start the FIRST thing spawns at - same idea as
## catch_game.gd's FIRST_SPOT_M, so the opening frame has something in view.
const FIRST_SPOT_M := 6.0

const RIM_TRIES := 10
## How far beyond a crater's rim the settle circle's NEAR edge sits, so the whole home_radius_m ring
## is dry land beside the pool, never straddling the waterline.
const HOME_EDGE_GAP_M := 0.55
## DecorationManager.RESERVED_CLEARANCE (spawn/pad/building exclusion) plus a bit more room - the
## home spot is a fixture for the length of the game, not a passer-by, so it gets the same courtesy
## project_system.gd's own markers give reserved zones (MARKER_RESERVED_GAP_M).
const HOME_RESERVED_GAP_M := DecorationManager.RESERVED_CLEARANCE + 1.0
const HOME_PROP_MARGIN_M := 0.5
## ROUND 2, finding 5: how many candidates `_pick_home_dir` scores from each source before deciding.
## Craters are capped (a many-crater world like Fen need not scan all 14 once an early one scores
## clean); the open-ground and raw pools are only spent at all when nothing has scored clean yet.
const HOME_CRATER_CAP := 8
const HOME_OPEN_CANDIDATES := 20
const HOME_RAW_CANDIDATES := 16
## Ring-sample count `_home_spot_score` uses to catch a prop or reserved zone that only grazes the
## CENTRE checks but still pokes into the drawn ring (finding 5's "grig ring over a prop").
const HOME_SCORE_RING_SAMPLES := 16

const HOME_RING_TUBE_R := 0.06
## ROUND 3, finding B: the ring is swept along the ground (`_build_ring_mesh`) rather than lathed as a
## flat torus. RING_SEGMENT_M caps each segment's arc (a 1.7 m ring gets 54 of them), so the tube
## follows a riser-free but gently rolling rim closely; RING_SIDES is the tube's cross-section, the
## same 6 round 2's torus used; RING_GROUND_GAP_M is how far the tube's underside sits above the
## highest ground under each cross-section - just enough that it never z-fights the terrain.
const RING_SEGMENT_M := 0.2
const RING_SIDES := 6
const RING_GROUND_GAP_M := 0.01
## ROUND 3, finding B: how level the ground under the ring must be (`_home_ground`). STEP is how far
## any rim or settle-slot sample strays from the best-fit plane through all of them - curvature and a
## smooth slope both fit that plane exactly, a terrace riser or a pool rim does not. It may not exceed
## the ring tube's own radius: past that, the ring visibly climbs a step instead of lying on the ground.
## TILT is the rim's rise from that plane's slope; a gentle slope is fine for a ground-hugging ring, so
## it only starts costing past the ring's full thickness, and becomes "not walkable" at
## DecorationManager's own MAX_SLOPE_DEG. Measured before choosing (400 free spots per world, 1.7 m
## ring): the step's median is 0.008-0.015 m on fen, hub, home, zorp and vela, 0.08-0.10 m on bolt and
## grig, whose treads are narrow; Fen's pool rims measure 0.009-0.02 m except where a second pool
## overlaps, and the world builder's spot on crater 5's clear side (round 4) 0.018 m.
const HOME_RIM_STEP_MAX_M := HOME_RING_TUBE_R
const HOME_RIM_TILT_MAX_M := HOME_RING_TUBE_R * 2.0
const HOME_GROUND_RIM_SAMPLES := 32
const HOME_GROUND_SLOT_SAMPLES := 12

## ROUND 2, finding 3: a settled thing rests at this fraction of home_radius_m from centre (inside the
## ring line, not on it), at a size that still reads clearly - not the vanishing point round 1 shrank
## to before freeing it.
const SETTLE_SLOT_RADIUS_FRAC := 0.55
const SETTLED_SCALE := 0.8
## ROUND 3, finding A: a settled thing's LOWEST vertex rests this far above the highest ground under
## its whole body (`_slot_local_position`). For the moth (lowest vertex 0.083 m below its origin,
## x SETTLED_SCALE) that puts the origin at ~0.15 m, the height the round-2 critic asked for; every
## other flavour gets the same clearance under its own lowest point instead of a shared fixed height,
## so a long bolt shank or a pod's stalk is never pushed into the ground either.
const SETTLED_CLEARANCE_M := 0.08
## How many ground samples around a settled body `_slot_local_position` takes (plus its centre).
const SETTLED_GROUND_SAMPLES := 8
## Extra scale added at the MIDDLE of the settle tween only (sin curve, zero at both ends) - the
## "stronger settle pulse" finding 3 asked for, on the item itself.
const SETTLE_POP_SCALE := 0.35

const SETTLE_TIME_S := 0.65

## ROUND 5, blocker 2: after the last thing settles, how long everything holds still, then how long the
## settled things, the ring and the glow take to go before `report_finished` (hunt_game.gd holds up to
## 2.5 s and drains in 0.5 s; this game has no "step off the spot" cue, so it holds a flat second).
const FINALE_HOLD_S := 1.0
const FINALE_FADE_S := 0.6

## Ground-glow alpha at zero done / all done - the pool visibly brightens as things come home. Kept
## alongside round 2's visible settled fixtures as a second, redundant signal, not the only one
## resuming now relies on (round 1's bug: it effectively WAS the only one, and was too subtle).
const HOME_GLOW_ALPHA_RANGE := Vector2(0.10, 0.32)
## Stronger settle pulse (finding 3), on the ground glow itself. Was 1.35.
const HOME_GLOW_PULSE_SCALE := 1.75
## The glow's resting radius as a fraction of home_radius_m - round 2's quad was home_radius_m * 1.7
## on a side, so its soft dot reached 0.85 of the ring. Unchanged by round 3, only now measured on a
## conformed disc (`_build_glow_mesh`) instead of a flat quad.
const HOME_GLOW_RADIUS_FRAC := 0.85
## ROUND 3, finding B: the glow disc's polar grid, and how far above `height_at` its vertices sit (the
## same 0.03 m round 2's flat quad sat above the tangent plane).
const GLOW_RINGS := 8
const GLOW_SEGMENTS := 32
const GLOW_LIFT_M := 0.03

## ROUND 2, finding 3: reuse catch_game's OWN flavour art wholesale - one source of truth for the
## LOOK, same as `FLAVOURS` already was for the colours, rather than a second, custom "wisp" shape
## that measured as a generic puffball. `CatchGame._body_mesh/_body_material/_halo_material` are
## static funcs on that script, cached there - calling them from here shares the exact same Mesh and
## Material resources a catch_game or ring_game of the same flavour already uses, so this does not
## add new ones.
const CatchGame := preload("res://src/minigames/catch_game.gd")
const FLAVOURS := CatchGame.FLAVOURS
const DEFAULT_FLAVOUR := "moth"

var _system: MinigameSystem
var _planet: Planet
var _player: Node3D
var _npcs: Array[Node3D] = []
var _npc_id: String = ""

var _flavour: String = DEFAULT_FLAVOUR
var _label: String = "glow moth"
var _plural: String = "glow moths"
var _title: String = ""
var _total: int = 0
var _done: int = 0
var _home_dir: Vector3 = Vector3.UP
var _home_radius_m: float = DEFAULT_HOME_RADIUS_M
var _band_radius_m: float = DEFAULT_HOME_RADIUS_M + BAND_MARGIN_M
var _t: float = 0.0

## ROUND 2, finding 4: the astronaut's own travel direction/speed, refreshed every frame (not
## throttled to DECIDE_HZ - a fast pass is exactly the moment freshness matters). See `_process`.
var _player_prev_dir: Vector3 = Vector3.ZERO
var _player_travel_dir: Vector3 = Vector3.ZERO
var _player_travel_speed: float = 0.0

var _home_node: Node3D
var _home_glow_mat: StandardMaterial3D
var _home_glow_node: MeshInstance3D
var _home_glow_color: Color = Color.WHITE

## ROUND 3: the reserved-zone centres, read ONCE in setup - `Planet.get_reserved_dirs()` builds a new
## Array on every call, and `_hazard_pressure`'s zone gradient needs them at DECIDE_HZ.
var _reserved_dirs: Array[Vector3] = []
## ROUND 3, finding A: one settle slot per thing (`_claim_slot`), true once something rests in it.
var _slot_taken: Array[bool] = []
## ROUND 3, finding A: the flavour body's own size at SETTLED_SCALE, from its mesh's AABB
## (`_measure_body`) - how far its lowest vertex sits below its origin, and its half-width.
var _settled_low_m: float = 0.0
var _settled_half_w_m: float = 0.0
## ...and the settled halo's local offset (node units, along the node's up) and scale.
var _halo_rest_y: float = 0.0
var _halo_rest_scale: float = 1.0
## ROUND 5, blocker 1: the keep-scale halo material every settled thing wears (`_rest_halo_material`).
var _rest_halo_mat: Material
## ROUND 5, blocker 2: seconds since the finale began (-1 before it), each settled thing's resting
## position/scale captured when the fade starts, and whether `report_finished` has been sent.
var _finale_t: float = -1.0
var _finale_rest: Array = []
var _finish_sent: bool = false

## One entry per LIVE (not yet home) thing. Settled entries are removed, so `_items.size()` is what
## is left loose. Keys: node, dir (Vector3, current position), heading (Vector3, unit tangent),
## speed (float m/s), decide_t (float, countdown to the next steering decision), phase/bob_phase
## (float, per-thing idle/bob variation), escape_phase (float, rotates the obstacle-sweep/escape fan
## so a thing stuck for more than one tick tries new angles rather than repeating a blocked one),
## last_guided_t (float, game-time the astronaut was last in this thing's flee radius - round 2,
## finding 2's settle gate; -INF until it ever happens).
var _items: Array[Dictionary] = []


# ============================================================================= setup
func setup(system: MinigameSystem, config: Dictionary) -> String:
	_system = system
	var tree := get_tree()
	if tree == null:
		return "not in a scene tree"
	_planet = tree.get_first_node_in_group("planet") as Planet
	if _planet == null:
		return "no planet here"
	_player = tree.get_first_node_in_group("player") as Node3D
	if _player == null:
		return "no player here"
	for n in tree.get_nodes_in_group("npc"):
		if n is Node3D:
			_npcs.append(n)

	_flavour = str(config.get("flavour", DEFAULT_FLAVOUR))
	if not FLAVOURS.has(_flavour):
		push_warning("guide_game: unknown flavour '%s', using '%s'" % [_flavour, DEFAULT_FLAVOUR])
		_flavour = DEFAULT_FLAVOUR
	var f: Dictionary = FLAVOURS[_flavour]
	_label = str(config.get("label", f["label"]))
	_plural = str(config.get("label_plural", f["plural"]))
	_title = str(config.get("title", ""))
	if _title == "":
		_title = "Guide the %s home" % _plural
	_npc_id = str(config.get("npc", ""))

	_total = clampi(int(config.get("count", DEFAULT_COUNT)), COUNT_RANGE.x, COUNT_RANGE.y)
	_done = clampi(int(config.get("done", 0)), 0, _total)
	_home_radius_m = clampf(float(config.get("home_radius_m", DEFAULT_HOME_RADIUS_M)), HOME_RADIUS_RANGE.x, HOME_RADIUS_RANGE.y)
	_band_radius_m = _home_radius_m + BAND_MARGIN_M

	var rng := RandomNumberGenerator.new()
	rng.seed = int(config["seed"]) if config.has("seed") \
		else hash([str(config.get("owner", "")), _planet.data.id, _planet.data.seed, _total])

	_reserved_dirs = _planet.get_reserved_dirs()
	_home_dir = _resolve_home_dir(config, rng)
	_build_home()

	var body := CatchGame._body_mesh(_flavour)
	var body_mat := CatchGame._body_material(_flavour)
	var halo := CatchGame._halo_material(Color(str(f["glow"])))
	_rest_halo_mat = _rest_halo_material(Color(str(f["glow"])))
	_measure_body(body)
	_slot_taken.resize(_total)

	# ROUND 2, finding 3: resuming shows what is ALREADY home as real, visible, glowing fixtures
	# sitting in the ring - not just a slightly brighter ground glow - so `done` from a previous
	# session reads at a glance. ROUND 3, finding A: each on its own slot's real ground, see
	# `_spawn_settled_fixture`.
	for slot in _done:
		_spawn_settled_fixture(slot, body, body_mat, _rest_halo_mat)

	# A resumed game spawns only what is LEFT, exactly like catch_game.gd - which particular ones
	# already settled is not saved and does not matter, they are interchangeable.
	var left := _total - _done
	if left > 0:
		var dirs := _pick_start_dirs(rng, left)
		for i in left:
			_items.append(_spawn(dirs[i], rng, body, body_mat, halo, i))
	_system.report_progress(_done, _total)
	if left <= 0:
		_start_finale.call_deferred()
	return ""


func title() -> String:
	return _title


## Rule 5's chevron: always the LOOSE thing nearest to home (finish escorting the nearly-done one
## first, rather than whichever is nearest to the player - catch_game's convention, which does not
## fit a game about shepherding). Falls back to the home spot itself when nothing is loose (the
## brief's own "or at home" case) - a one-frame gap between the last settle and `finished`, or a
## same-frame call before anything has spawned - so the pointer is never blank.
func hint_direction() -> Vector3:
	var best_node: Node3D = null
	var best_d := INF
	for it: Dictionary in _items:
		var node: Node3D = it["node"]
		if not is_instance_valid(node):
			continue
		var d: float = _planet.surface_distance(it["dir"], _home_dir)
		if d < best_d:
			best_d = d
			best_node = node
	if best_node != null:
		return best_node.global_position
	return _home_node.global_position if is_instance_valid(_home_node) else Vector3.INF


## Called by the system just before this node is freed. Nothing to unwind: every node and material
## this game made is a child of it (or a cached static shared with every other game using catch_game's
## art), and it never touched the player, a modal or the tree - the same as catch_game.gd and
## ring_game.gd. Settled fixtures (round 2) are children of `_home_node`, itself a child of this, so
## they free with everything else.
func outro() -> void:
	pass


# ============================================================================= per-frame
func _process(delta: float) -> void:
	if _finale_t >= 0.0:
		_process_finale(delta)
		return
	if _items.is_empty() or not is_instance_valid(_planet):
		return
	_t += delta
	var alive := is_instance_valid(_player)
	var player_dir := _planet.dir_of(_player.global_position) if alive else Vector3.ZERO

	# ROUND 2, finding 4: the astronaut's own travel direction, refreshed every frame - see the const
	# comment above and `_decide`'s close-pass blend. One extra `surface_distance` a frame, not per
	# item, so it does not touch the per-thing cost this file otherwise budgets so carefully.
	if alive:
		if _player_prev_dir != Vector3.ZERO:
			var moved_m := _planet.surface_distance(_player_prev_dir, player_dir)
			if moved_m > 0.001:
				var tv := player_dir - _player_prev_dir
				tv -= player_dir * tv.dot(player_dir)
				if tv.length_squared() > 0.000001:
					_player_travel_dir = tv.normalized()
			_player_travel_speed = moved_m / maxf(delta, 0.0001)
		_player_prev_dir = player_dir

	var settled := -1
	for i in _items.size():
		var it: Dictionary = _items[i]
		var node: Node3D = it["node"]
		if not is_instance_valid(node):
			continue
		var dir: Vector3 = it["dir"]
		var heading: Vector3 = it["heading"]
		var speed: float = it["speed"]

		var timer: float = float(it["decide_t"]) - delta
		if timer <= 0.0:
			timer += DECIDE_PERIOD_S
			# ROUND 3 (should-fix): the decision is written into `it` in place - round 2 returned a new
			# two-element Array per decision, a heap allocation DECIDE_HZ times a second per thing.
			_decide(dir, heading, alive, player_dir, it)
			heading = it["heading"]
			speed = it["speed"]
		it["decide_t"] = timer

		var desired := _tangent_step(dir, heading, speed * delta)
		var d_home := _planet.surface_distance(desired, _home_dir)
		if d_home > _band_radius_m:
			# Walled back in, not stopped dead: sliding along the band edge (rather than snapping to
			# it) is what makes "coming from the far side" still feel like a push, not a wall bump.
			# ROUND 2, finding 1: this clamp can land on a spot `_decide` never actually tested against
			# `_blocked` (its own lookahead sample was taken BEFORE this clamp runs). Nothing extra is
			# needed here, though - `it["dir"]` below becomes exactly the `dir` argument `_decide` gets
			# NEXT time it runs for this thing, and that call checks `_blocked` on it first thing (see
			# `_decide`'s header), so the clamp result is always rechecked, one decide tick later.
			desired = _home_dir.slerp(desired, _band_radius_m / d_home)
			d_home = _band_radius_m

		it["dir"] = desired
		it["heading"] = heading
		it["speed"] = speed

		# The terrain under it, exactly, every frame - not cached (see catch_game.gd's own note on
		# why: `Planet.height_at` is cheap, and stale ground reads wrong the moment it crosses a rise).
		var ground := _planet.height_at(desired)
		var bob := sin(_t * TAU * BOB_HZ + float(it["bob_phase"])) * BOB_M
		node.global_position = _planet.global_position + desired * (ground + HOVER_HEIGHT_M + bob)
		node.global_basis = Basis.looking_at(heading, desired)

		# ROUND 2, finding 2: geometry alone no longer settles a thing. Idle drift used to be able to
		# finish the whole game with no input (measured: seed 42, 4/5 settled in 35 s with the
		# astronaut teleported to the far side of the planet). `last_guided_t` is stamped by `_decide`
		# only while the astronaut is genuinely in this thing's flee radius, so a thing only counts
		# once that happened recently - generous enough (~1.5 s) that a push landing the instant after
		# the player moves on to the next one still counts.
		if settled < 0 and d_home <= _home_radius_m:
			var last_guided: float = float(it.get("last_guided_t", -INF))
			if _t - last_guided <= GUIDED_RECENCY_S:
				settled = i
	if settled >= 0:
		_settle(settled)


## The steering decision (see "WHY THE DECIDE CLOCK"): writes `it["heading"]` (Vector3) and
## `it["speed"]` (float) in place - round 3's should-fix, see `_process`. `prev_heading` is
## re-projected onto the tangent plane at the thing's CURRENT position first - its position has moved
## since the last decision, so the stored heading needs re-levelling before it means anything here.
func _decide(dir: Vector3, prev_heading: Vector3, alive: bool, player_dir: Vector3, it: Dictionary) -> void:
	# ROUND 2, finding 1 ("frozen forever"): a spot that is ALREADY blocked - it spawned inside a
	# footprint despite this round's spawn-time filters, or last frame's band-wall clamp parked it
	# somewhere bad - is escaped FIRST and unconditionally, before flee/idle logic runs at all. This
	# doubles as rechecking the band clamp (see `_process`'s comment at the clamp site): `dir` here is
	# always exactly last frame's post-clamp position.
	if _blocked(dir):
		_escape(dir, it)
		return

	var heading := prev_heading - dir * prev_heading.dot(dir)
	heading = heading.normalized() if heading.length_squared() > 0.0001 else _arbitrary_tangent(dir)

	var speed := 0.0
	var to_player_m := _planet.surface_distance(dir, player_dir) if alive else INF
	if alive and to_player_m <= FLEE_RADIUS_M:
		# ROUND 2, finding 2: the ONE place a thing is marked "a real chase touched it" - see
		# `_process`'s settle gate. Stamped even on a tick where the edge-pin or close-pass blends
		# below change the exact heading; being IN the flee radius is what counts, not which blend won.
		it["last_guided_t"] = _t

		# Rule 2: away from the astronaut, along the surface, faster the closer it is, never faster
		# than FLEE_SPEED_MAX (itself under Player.WALK_SPEED - see the header).
		var away := dir - player_dir
		away -= dir * away.dot(dir)
		var have_away := away.length_squared() > 0.0001
		if have_away:
			away = away.normalized()
			if to_player_m <= CLOSE_PASS_RADIUS_M and _player_travel_speed > CLOSE_PASS_MIN_SPEED_MS:
				# ROUND 2 FIX (finding 4, "full-stick chase circles"): pure point-repulsion flips
				# almost instantly as a FAST astronaut passes close by or straight through - "away
				# from your exact spot" swings through ~180 degrees in one tick, and chasing that flip
				# in a straight line is what turned a naive full-stick approach into a stable circling
				# loop (measured: naive strategy, 4/5 settled in 180 s). Blend toward the astronaut's
				# OWN travel direction instead, more so the closer they are: a thing that gets run at
				# (or run straight through) scoots forward out of the way along the astronaut's path,
				# the way a startled animal hops clear of a jogger, rather than reversing on a hair
				# trigger. (When the astronaut is essentially exactly underfoot, `have_away` is false
				# below and the existing "keep the previous heading" rule already covers "passed over"
				# - this is the same idea one ring further out, where a direction still exists but
				# flips fast.)
				var close_t := 1.0 - clampf(to_player_m / CLOSE_PASS_RADIUS_M, 0.0, 1.0)
				var travel_blend := away * (1.0 - close_t) + _player_travel_dir * close_t
				if travel_blend.length_squared() > 0.0001:
					away = travel_blend.normalized()
			heading = away
		# else: the astronaut is (almost) exactly underfoot/overhead - a rare frame; holding the
		# previous heading beats a divide-by-zero snap to some arbitrary direction.
		speed = lerpf(FLEE_SPEED_MAX, 0.0, to_player_m / FLEE_RADIUS_M)

		# EDGE-PIN FIX (measured, this builder's report): pure "away from the astronaut" is exactly
		# right near the middle of the band, where it is what makes coming from the far side push a
		# thing home. But AT the band wall it can also point mostly ALONG the wall - the astronaut
		# chasing a thing already pinned to the rim from the home side pushes it sideways, not in,
		# and a straight "walk at it" pursuit measured one thing stuck on the rim for 130+ seconds,
		# well past the "understand it within 30 seconds" bar (rule 2). Fix: blend in a pull toward
		# home, weighted by how close to the wall the thing already is (eased so it is near zero
		# through the middle of the band and only real right at the edge) - so a good far-side
		# approach is unchanged (there, "away from you" and "toward home" already roughly agree) and
		# a bad-angle approach at the wall still makes real, if slower, progress instead of a stable
		# loop. Re-measured after this change: the same repro (autopilot always walking straight at
		# the nearest-to-home loose thing) finished all 5 in 14-24 s where it previously stalled at
		# 3 of 5 for 110+ s - see the builder's report.
		if have_away:
			var edge_t := clampf(_planet.surface_distance(dir, _home_dir) / _band_radius_m, 0.0, 1.0)
			var bias := HOME_BIAS_AT_EDGE * edge_t * edge_t
			if bias > 0.001:
				var to_home := _home_dir - dir
				to_home -= dir * to_home.dot(dir)
				if to_home.length_squared() > 0.0001:
					var blended := away * (1.0 - bias) + to_home.normalized() * bias
					if blended.length_squared() > 0.0001:
						heading = blended.normalized()
	else:
		# Idle: a slow, smoothly wandering heading - never aimed at home (rule 1 walls it back into
		# the band if it strays, it does not pull it home; that would let the game finish itself).
		var wobble := IDLE_TURN_RAD_S * sin(_t * IDLE_TURN_HZ + float(it["phase"]))
		heading = heading.rotated(dir, wobble * DECIDE_PERIOD_S)
		# ROUND 2 FIX (finding 2, "plays itself"): idle drift used to be free to wander anywhere in
		# the band, including straight through the home spot - the geometric half of "plays itself"
		# (the `last_guided_t` gate above stops it COUNTING, but a thing visibly sliding into the ring
		# unguided still looks wrong). Steer clear of a keep-out disc around home, harder the closer
		# in, so a thing left alone drifts back OUT on its own instead of lingering at the door.
		var keep_out := _home_radius_m + IDLE_HOME_MARGIN_M
		var d_home_now := _planet.surface_distance(dir, _home_dir)
		if d_home_now < keep_out:
			var away_home := dir - _home_dir
			away_home -= dir * away_home.dot(dir)
			if away_home.length_squared() > 0.0001:
				var t2 := 1.0 - clampf(d_home_now / keep_out, 0.0, 1.0)
				var blended2 := heading * (1.0 - t2) + away_home.normalized() * t2
				if blended2.length_squared() > 0.0001:
					heading = blended2.normalized()
		speed = IDLE_DRIFT_MS

	# Rule 3: try the chosen heading's next step; if it runs into a prop, a building/reserved zone or
	# a neighbour, sweep a small fan of alternatives around it and take the first that is clear.
	var step_m := maxf(speed * DECIDE_PERIOD_S, MIN_LOOKAHEAD_M)
	if _blocked(_tangent_step(dir, heading, step_m)):
		var phase: float = float(it.get("escape_phase", 0.0))
		var found := false
		for k in ESCAPE_TRY_COUNT:
			var ang := TAU * float(k) / float(ESCAPE_TRY_COUNT) + phase
			var alt := heading.rotated(dir, ang)
			if not _blocked(_tangent_step(dir, alt, step_m)):
				heading = alt
				found = true
				break
		it["escape_phase"] = phase + 0.9   # next attempt sweeps new angles, not the same failed ones
		if not found:
			# ROUND 2 FIX (finding 1): `dir` ITSELF is clear (checked at the very top of this
			# function) but nothing a single lookahead step away is - a large obstacle's edge sits
			# just past it, say. Round 1 held speed 0 here, which can never resolve: standing still
			# cannot cross an edge that is further away than one lookahead step. Hill-climb clear of
			# it instead, the same as an already-blocked spot.
			_escape(dir, it)
			return

	it["heading"] = heading
	it["speed"] = speed


## ROUND 2 FIX (finding 1, "frozen forever"): moves a thing OUT of a blocked spot by hill-climbing
## `_hazard_pressure` - a continuous stand-in for `_blocked` - rather than requiring a direction that
## is already fully clear. A thing can be blocked because it is DEEP inside a footprint (round 1's
## `_jitter_in_band` could spawn one there with no check at all; a live neighbour can also walk up to
## one), in which case every direction at the normal one-step lookahead can still read "blocked" even
## though real, useful progress toward the edge is being made every tick - the old code read that as
## permanently "boxed" and stopped. This always sets a real, non-zero speed: the whole point is that
## standing still can never fix a footprint bigger than one lookahead step. Writes `it["heading"]` and
## `it["speed"]` in place, like `_decide`.
func _escape(dir: Vector3, it: Dictionary) -> void:
	var phase: float = float(it.get("escape_phase", 0.0))
	var base := _arbitrary_tangent(dir)
	var best_heading := base
	var best_pressure := Vector3(INF, INF, INF)
	for k in ESCAPE_SWEEP_COUNT:
		var ang := TAU * float(k) / float(ESCAPE_SWEEP_COUNT) + phase
		var alt := base.rotated(dir, ang)
		# ROUND 3: judged where the step would REALLY end - `_process` walls every move back into the
		# band, so a step straight out through the wall ends on the wall, next to where it started.
		# Round 2 judged the unclamped point, and "away" from a neighbour walking at a thing on the
		# wall pointed straight out: the thing chose it, did not move, and the neighbour walked onto
		# it (measured, SYNTHETIC chase at the neighbour's 2.2 m/s walk: 0.00 m, 134 frames within
		# its body radius; the same happened once in a real naive play on fen seed 7).
		var p := _hazard_pressure(_clamp_to_band(_tangent_step(dir, alt, ESCAPE_STEP_M)))
		# Vector3's `<` is lexicographic (x, then y, then z) - see `_hazard_pressure`.
		if p < best_pressure:
			best_pressure = p
			best_heading = alt
	it["escape_phase"] = phase + 1.1   # a different fan next tick, so a narrow gap is found within a
	                                    # few ticks rather than the same twelve angles repeating
	it["heading"] = best_heading
	it["speed"] = ESCAPE_SPEED_MS


## A continuous stand-in for `_blocked` (round 2, finding 1): (0, 0) is clear, larger is worse, so
## `_escape` can hill-climb AWAY from whatever is blocking a spot without needing to know WHICH prop,
## zone or neighbour it is - the public Planet/DecorationManager API only ever answers "how far",
## never "which one", so a smooth distance-based cost is what makes a gradient possible at all.
##
## ROUND 3 (should-fix): the result is ORDERED, not summed. x is what a thing must never pass
## through - a prop's or a neighbour's clearance, by how deep; y is what it may cross on its way out -
## a reserved zone or water. `_escape` compares them lexicographically, so ANY step that stays out of
## every prop beats ANY step into one, however deep in a zone the first is. Round 2 added a flat +4
## for a zone and the prop's depth (at most ~1 m) to one number, so from inside a zone a path through a
## standing stone scored better than one staying in the zone (measured by the critic: a thing starting
## in a zone escaped through a stone). The zone term also has a slope now: the farther from the
## nearest zone centre the better, so a thing deep in a wide zone walks OUT rather than wandering inside
## it on a flat cost (the zone radii are private to Planet; the centres are public, and moving away
## from the centre of the zone you are in always moves you toward its edge).
##
## z breaks the remaining tie: once several steps are clear of everything, x and y are all zero, and
## round 2 took whichever came first in the fan - up to 45 degrees off "straight away". Against a
## neighbour walking at 2.2 m/s that lost ground to a 2.6 m/s escape (SYNTHETIC chase: the thing
## never got more than 1.0 m clear and was caught at 0.39 m). z is the step's clearance from the
## NEAREST prop or neighbour, negated so smaller is better, which picks the step that gets furthest away.
func _hazard_pressure(dir: Vector3) -> Vector3:
	var solid := 0.0
	var prop_edge := _planet.nearest_prop_distance(dir)
	var margin := prop_edge - PROP_CLEAR_M
	if prop_edge < PROP_CLEAR_M:
		solid += PROP_CLEAR_M - prop_edge
	for n in _npcs:
		if is_instance_valid(n):
			var dn := _planet.surface_distance(dir, _planet.dir_of(n.global_position))
			margin = minf(margin, dn - NPC_CLEAR_M)
			if dn < NPC_CLEAR_M:
				solid += NPC_CLEAR_M - dn
	var soft := 0.0
	if _planet.reserved_zone_at(dir) != "":
		var nearest_m := INF
		for r in _reserved_dirs:
			nearest_m = minf(nearest_m, _planet.surface_distance(dir, r))
		soft += 1.0 + 1.0 / (1.0 + nearest_m)
	if _planet.is_underwater(dir):
		soft += 1.0 + maxf(_planet.water_radius() - _planet.height_at(dir), 0.0)
	return Vector3(solid, soft, -margin)


## `dir` walled back into the band exactly the way `_process` walls a move (see its clamp comment).
func _clamp_to_band(dir: Vector3) -> Vector3:
	var d_home := _planet.surface_distance(dir, _home_dir)
	if d_home > _band_radius_m:
		return _home_dir.slerp(dir, _band_radius_m / d_home)
	return dir


## True when `dir` is inside a prop's clearance, a reserved zone (spawn/pad/building/npc home - "a
## building", rule 1), a live neighbour's own clearance ("a neighbour"), or underwater. Deliberately
## NOT the fuller slope/shore test DecorationManager.ground_block_reason runs (that costs up to six
## extra height_at samples) - this runs from `_decide` at DECIDE_HZ, not every frame, and the band is
## already anchored on validated ground (see `_pick_home_dir`/`_home_spot_score`), so the remaining
## risk is a moving thing wandering into a LOCAL obstacle, which is exactly what this catches.
func _blocked(dir: Vector3) -> bool:
	if _planet.is_underwater(dir):
		return true
	if _planet.reserved_zone_at(dir) != "":
		return true
	if _planet.nearest_prop_distance(dir) < PROP_CLEAR_M:
		return true
	for n in _npcs:
		if is_instance_valid(n) and _planet.surface_distance(dir, _planet.dir_of(n.global_position)) < NPC_CLEAR_M:
			return true
	return false


## Moves `dir` by `meters` along the great circle whose initial tangent AT `dir` is `tangent` - the
## same u/v great-circle idiom catch_game.gd's drift uses, just re-aimed every decision instead of
## fixed for the whole game.
func _tangent_step(dir: Vector3, tangent: Vector3, meters: float) -> Vector3:
	var ang := meters / maxf(_planet.radius, 1.0)
	return (dir * cos(ang) + tangent * sin(ang)).normalized()


static func _arbitrary_tangent(dir: Vector3) -> Vector3:
	var t := dir.cross(Vector3.UP)
	if t.length_squared() < 0.0001:
		t = dir.cross(Vector3.RIGHT)
	return t.normalized()


# ============================================================================= settling
func _settle(index: int) -> void:
	var it: Dictionary = _items[index]
	_items.remove_at(index)
	_done += 1
	# Persist FIRST, celebrate second - minigame_system.gd's header: completion must never depend on
	# the `finished` signal, which can be missed.
	if is_instance_valid(_system):
		_system.report_progress(_done, _total)
	_update_home_glow()
	_pulse_home_glow()
	AudioManager.play_sfx("pickup")
	var last := _items.is_empty()
	if not last:
		EventBus.toast_requested.emit("%s came home (%d/%d)" % [_label.capitalize(), _done, _total], "")
	var node: Node3D = it["node"]
	if is_instance_valid(node):
		# ROUND 2 REWRITE (finding 3, "not a glow moth, no settle moment"): round 1 shrank the body to
		# nothing and freed it, so nothing was left to look at - resuming a game had only a faint
		# difference in the ground glow's alpha to show for "this many are already home" (rule 4), and
		# the critic judged that "shows nothing". This keeps the node: it moves into the home node
		# (reparenting keeps its world position, so there is no visual pop), sinks to a settle slot at a
		# size that still reads clearly, and STAYS - a real, visible, glowing fixture, not an inferred
		# brightness.
		#
		# ROUND 3 FIX (finding A, "settled moths are buried"): round 2 aimed the slide at a FIXED local
		# y of -0.12 m on the home node's tangent plane, which ignores the planet's curvature and the
		# terrain - measured 0.08-0.09 m under the ground at rest, only the wing tips showing. The end
		# point is now the slot's own ground (`_slot_local_position`), and the halo shrinks onto the
		# body on the way down so it ends above the ground too (`_measure_body`). The slot is the free
		# one nearest the bearing it actually arrived on (`_claim_slot`), so the sideways move is at
		# most half a slot, and no two settled things ever share a spot.
		var start_scale := node.scale
		node.reparent(_home_node, true)
		var local_now: Vector3 = node.position
		var end_local := _slot_local_position(_claim_slot(local_now))
		var halo := node.get_node_or_null("Halo") as MeshInstance3D
		# ROUND 5, blocker 1: from here on the halo honours its scale (see `_rest_halo_material`). At this
		# instant the node and halo scales are both 1, so the swap draws exactly what the old one did.
		if is_instance_valid(halo):
			halo.material_override = _rest_halo_mat
		var halo_y := _halo_rest_y
		var halo_s := _halo_rest_scale
		# How far the body reaches below its origin per unit of scale - the pop below is lifted by
		# exactly this, so the extra size grows the body UP and never pushes its lowest vertex into the
		# ground (measured without it: a grig pod's stalk touched the ground mid-pop, 0.000 m).
		var low_per_scale := _settled_low_m / SETTLED_SCALE
		var tw := node.create_tween()
		tw.tween_method(func(t: float) -> void:
			if is_instance_valid(node):
				# Stronger settle pulse (finding 3): a quick pop past the resting size on the way in
				# reads as a little flourish, before it settles at SETTLED_SCALE for good.
				var pop := sin(t * PI) * SETTLE_POP_SCALE
				node.position = local_now.lerp(end_local, t) + Vector3.UP * (low_per_scale * pop)
				node.scale = start_scale.lerp(Vector3.ONE * SETTLED_SCALE, t) + Vector3.ONE * pop
				if is_instance_valid(halo):
					halo.position = Vector3(0.0, halo_y * t, 0.0)
					halo.scale = Vector3.ONE * lerpf(1.0, halo_s, t)
			, 0.0, 1.0, SETTLE_TIME_S).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		if last:
			tw.tween_callback(_start_finale)
	elif last:
		_start_finale.call_deferred()


## ROUND 5, blocker 2: the celebration plays the moment the last thing is home, then `_process_finale`
## holds and fades before reporting. Also the path for a resumed game that is already complete.
func _start_finale() -> void:
	if _finale_t >= 0.0 or _finish_sent:
		return
	_finale_t = 0.0
	AudioManager.play_sfx("quest_complete", -3.0)
	var npc := _npc_node()
	if npc != null and npc.has_method("play_emote"):
		npc.call("play_emote", "happy")


## ROUND 5, blocker 2: FINALE_HOLD_S of stillness, then FINALE_FADE_S in which every settled thing
## shrinks to nothing while its origin slides down onto the ground it rests over (origin height and
## lowest vertex both go with (1 - e), so the body never dips below the ground on the way, and the
## keep-scale halo shrinks with it), the ring sinks by its own full height so its top ends at the ground,
## and the glow's alpha runs to zero. Then `_finish`. Five nodes and two material/position writes a frame
## for 0.6 s - nothing is created.
func _process_finale(delta: float) -> void:
	_finale_t += delta
	if _finish_sent or _finale_t < FINALE_HOLD_S:
		return
	if not is_instance_valid(_home_node):
		_finish()
		return
	if _finale_rest.is_empty():
		_capture_finale_rest()
	var e := clampf((_finale_t - FINALE_HOLD_S) / FINALE_FADE_S, 0.0, 1.0)
	e = e * e * (3.0 - 2.0 * e)
	var keep := 1.0 - e
	for rest: Array in _finale_rest:
		var node: Node3D = rest[0]
		if not is_instance_valid(node):
			continue
		node.position = (rest[1] as Vector3) - (rest[2] as Vector3) * e
		node.scale = (rest[3] as Vector3) * maxf(keep, 0.001)
		node.visible = keep > 0.0
	var ring := _home_node.get_node_or_null("Ring") as Node3D
	if ring != null:
		# The tube's top sits RING_GROUND_GAP_M + its diameter above the highest ground under it, measured
		# along the planet's radial; this node's local down is that radial only at the centre, so the sink
		# is lengthened by 1/cos of the ring's angle from centre to drop exactly that height at the rim.
		var rim_cos := cos(_home_radius_m / maxf(_planet.radius, 1.0))
		ring.position = Vector3.DOWN * ((RING_GROUND_GAP_M + 2.0 * HOME_RING_TUBE_R) / rim_cos) * e
		ring.visible = keep > 0.0
	if _home_glow_mat != null:
		var t := float(_done) / float(maxi(_total, 1))
		var a := lerpf(HOME_GLOW_ALPHA_RANGE.x, HOME_GLOW_ALPHA_RANGE.y, t) * keep
		_home_glow_mat.albedo_color = Color(_home_glow_color.r, _home_glow_color.g, _home_glow_color.b, a)
	if e >= 1.0:
		_finish()


## Each settled thing's resting local position, its sink vector (along the planet's radial at its spot,
## by its own origin height above the ground it was placed over - `_slot_local_position`) and its scale.
func _capture_finale_rest() -> void:
	var inv_basis := _home_node.global_transform.basis.inverse()
	var sink_m := _settled_low_m + SETTLED_CLEARANCE_M
	for ch in _home_node.get_children():
		if ch is Node3D and str(ch.name).begins_with("Wanderer"):
			var n3 := ch as Node3D
			var up := (inv_basis * _planet.dir_of(n3.global_position)).normalized()
			_finale_rest.append([n3, n3.position, up * sink_m, n3.scale])


## Sends `report_finished` exactly once, and never from a node the system has already let go of (a stop()
## earlier this frame queues this node for deletion - and may have started another game already, which a
## late report must not end).
func _finish() -> void:
	if _finish_sent:
		return
	_finish_sent = true
	if _system == null or not is_instance_valid(_system) or is_queued_for_deletion():
		return
	_system.report_finished(true)


## Optional courtesy only (see the "npc" config key) - never adds a node, only calls an existing
## method on one that is already in the tree.
func _npc_node() -> Node3D:
	if _npc_id == "":
		return null
	for n in _npcs:
		if is_instance_valid(n) and str(n.get("npc_id")) == _npc_id:
			return n
	return null


# ============================================================================= spawning
## Body + halo for one thing - shared by a LIVE spawn (`_spawn`) and an already-home resume fixture
## (`_spawn_settled_fixture`, round 2, finding 3), so both are built exactly the same way and cost the
## same two draw calls.
func _build_thing_node(body: Mesh, body_mat: Material, halo_mat: Material, node_name: String) -> Node3D:
	var node := Node3D.new()
	# ROUND 3: a unique name per thing ("Wanderer0".."WandererHome4"). Round 2 named every one
	# "Wanderer", so Godot silently renamed the second sibling to "@Node3D@..." and a QA count of the
	# ring's fixtures by name read 1 for a done=2 resume.
	node.name = node_name
	var mi := MeshInstance3D.new()
	mi.mesh = body
	mi.material_override = body_mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.add_child(mi)
	var halo := MeshInstance3D.new()
	var hq := QuadMesh.new()
	hq.size = Vector2(CatchGame.HALO_SIZE_M, CatchGame.HALO_SIZE_M)
	halo.name = "Halo"
	halo.mesh = hq
	halo.material_override = halo_mat
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.add_child(halo)
	return node


func _spawn(dir: Vector3, rng: RandomNumberGenerator, body: Mesh, body_mat: Material, halo_mat: Material, index: int) -> Dictionary:
	var node := _build_thing_node(body, body_mat, halo_mat, "Wanderer%d" % index)
	add_child(node)
	return {
		"node": node, "dir": dir, "heading": _arbitrary_tangent(dir), "speed": 0.0,
		# Staggered so every thing does not remake its steering decision on the same frame.
		"decide_t": rng.randf() * DECIDE_PERIOD_S,
		"phase": rng.randf() * TAU, "bob_phase": rng.randf() * TAU, "escape_phase": 0.0,
		# ROUND 2, finding 2: not guided yet - see `_process`'s settle gate and `_decide`'s stamp.
		"last_guided_t": -INF,
	}


## ROUND 2, finding 3: a static "already home" fixture for a resumed game's `done` count - built once
## in setup(), never touched again, so it costs nothing beyond its own two draw calls: no entry in
## `_items`, no per-frame work, nothing for `_process` to iterate. One per slot index (there is no
## "where it actually arrived" to reuse the way a live settle has - see `_settle`).
##
## ROUND 3 FIX (finding A): round 2 put it at a fixed local y of -0.12 m on the tangent plane (measured
## 0.10 m under the ground) and assigned `node.basis` AFTER `node.scale`, which resets the scale, so it
## also sat at 1.0 instead of SETTLED_SCALE. It now stands on its slot's real ground, facing out of
## the ring along its own up, with the scale set LAST, and its halo already at the settled size.
func _spawn_settled_fixture(slot: int, body: Mesh, body_mat: Material, halo_mat: Material) -> void:
	var node := _build_thing_node(body, body_mat, halo_mat, "WandererHome%d" % slot)
	_home_node.add_child(node)
	_slot_taken[slot] = true
	var pos := _slot_local_position(slot)
	var up := _home_node.global_transform.basis.inverse() * _slot_dir(slot)
	var out := Vector3(pos.x, 0.0, pos.z)
	out -= up * out.dot(up)
	if out.length_squared() < 0.000001:
		out = _arbitrary_tangent(up)
	node.position = pos
	node.basis = Basis.looking_at(out.normalized(), up.normalized())
	node.scale = Vector3.ONE * SETTLED_SCALE   # AFTER the basis - assigning a basis resets the scale
	var halo := node.get_node_or_null("Halo") as Node3D
	if halo != null:
		halo.position = Vector3(0.0, _halo_rest_y, 0.0)
		halo.scale = Vector3.ONE * _halo_rest_scale


## ROUND 5, blocker 1: catch_game's halo material with billboard_keep_scale on, so a settled halo's
## `_halo_rest_scale` (and the settle pop) really change what it draws. One per glow colour for the whole
## session, shared by every settled thing - the same cache shape as `CatchGame._halo_material`. The copy
## shares that material's soft-dot texture; only the flag differs.
static var _rest_halo_mats: Dictionary = {}

static func _rest_halo_material(glow: Color) -> Material:
	var key := glow.to_html(false)
	if _rest_halo_mats.has(key):
		return _rest_halo_mats[key]
	var m := (CatchGame._halo_material(glow) as StandardMaterial3D).duplicate() as StandardMaterial3D
	m.billboard_keep_scale = true
	_rest_halo_mats[key] = m
	return m


## ROUND 3, finding A: the direction of settle slot `slot` - one per thing, evenly spaced round the
## home spot at SETTLE_SLOT_RADIUS_FRAC of the ring, measured along the ground (a great circle, the
## same distance `_process`'s settle check uses), not across the tangent plane.
func _slot_dir(slot: int) -> Vector3:
	var hb := _home_node.global_transform.basis
	var ang := TAU * float(slot) / float(maxi(_slot_taken.size(), 1))
	var a := _home_radius_m * SETTLE_SLOT_RADIUS_FRAC / _planet.radius
	return (_home_dir * cos(a) + (hb.x * cos(ang) + hb.z * sin(ang)) * sin(a)).normalized()


## ROUND 3, finding A: where a settled thing's ORIGIN rests for `slot`, in `_home_node`'s local space.
## The height is the HIGHEST ground under its whole body (its centre and SETTLED_GROUND_SAMPLES points
## at its settled half-width), plus how far its lowest vertex sits below its origin, plus
## SETTLED_CLEARANCE_M - so no part of it is ever inside the ground, whatever its orientation or the
## slope under it.
func _slot_local_position(slot: int) -> Vector3:
	var d := _slot_dir(slot)
	var ground := _planet.height_at(d)
	var xf := _planet.surface_transform(d)
	var e := _settled_half_w_m / _planet.radius
	for k in SETTLED_GROUND_SAMPLES:
		var ang := TAU * float(k) / float(SETTLED_GROUND_SAMPLES)
		var tangent := xf.basis.x * cos(ang) + xf.basis.z * sin(ang)
		ground = maxf(ground, _planet.height_at((d + tangent * e).normalized()))
	var world := _planet.global_position + d * (ground + _settled_low_m + SETTLED_CLEARANCE_M)
	return _home_node.global_transform.affine_inverse() * world


## ROUND 3, finding A: the free slot nearest the bearing a thing arrived on (`arrival_local` is its
## position in `_home_node`'s space). There is one slot per thing, so a free one always exists.
func _claim_slot(arrival_local: Vector3) -> int:
	var bearing := atan2(arrival_local.z, arrival_local.x)
	var best := -1
	var best_diff := INF
	for s in _slot_taken.size():
		if _slot_taken[s]:
			continue
		var diff := absf(angle_difference(bearing, TAU * float(s) / float(_slot_taken.size())))
		if diff < best_diff:
			best_diff = diff
			best = s
	if best < 0:
		best = 0   # unreachable while each settle removes one of `_total` things; never an index error
	else:
		_slot_taken[best] = true
	return best


## ROUND 3, finding A: reads the flavour body's own size from its mesh, so every flavour rests and
## glows correctly without a per-flavour table. The settled halo becomes exactly as wide as the settled
## body (drawn at that width only because of `_rest_halo_material` - round 5) and centres on the body's
## middle, or higher when that middle is lower than the halo's own radius: ROUND 5 measured the moth's
## middle at 0.22 m for a 0.29 m radius, which let the dot's lower edge into the ground. A billboard's
## lowest point is at most one radius below its centre (a level camera), so the centre sits at least one
## radius plus RING_GROUND_GAP_M above the slot's ground and no part of the dot can reach it.
func _measure_body(body: Mesh) -> void:
	var box := body.get_aabb()
	_settled_low_m = maxf(-box.position.y, 0.0) * SETTLED_SCALE
	var half_w := maxf(maxf(absf(box.position.x), absf(box.end.x)), maxf(absf(box.position.z), absf(box.end.z)))
	_settled_half_w_m = half_w * SETTLED_SCALE
	_halo_rest_scale = clampf(2.0 * half_w / CatchGame.HALO_SIZE_M, 0.1, 1.0)
	var halo_r_m := 0.5 * CatchGame.HALO_SIZE_M * _halo_rest_scale * SETTLED_SCALE
	var origin_h_m := _settled_low_m + SETTLED_CLEARANCE_M
	_halo_rest_y = maxf(box.get_center().y, (halo_r_m + RING_GROUND_GAP_M - origin_h_m) / SETTLED_SCALE)


## Start directions: scattered inside the band around home, farthest-point sampling from each other
## so "guide them all home" means covering the band, not standing in one place - the same idea as
## catch_game.gd's `_pick_start_dirs`, anchored on home instead of "near", and using
## Planet.find_free_dir_near so every candidate is already off water/props/reserved zones instead of
## being screened after the fact.
func _pick_start_dirs(rng: RandomNumberGenerator, count: int) -> Array[Vector3]:
	var candidates: Array[Vector3] = []
	for _i in SPOT_CANDIDATES:
		var v := _planet.find_free_dir_near(rng, _home_dir, _band_radius_m, ITEM_CLEARANCE_M, 10)
		if v == Vector3.ZERO:
			continue
		if _planet.surface_distance(v, _home_dir) < _home_radius_m + START_HOME_GAP_M:
			continue
		# ROUND 2 FIX (finding 1, "frozen forever"): `find_free_dir_near`'s notion of "free" is
		# planet-only (reserved zones, props, slope) - it does not know about a live neighbour, which
		# is guide_game's OWN extra clearance (`_blocked`'s NPC_CLEAR_M term). A candidate blocked by
		# anything `_blocked` checks is exactly a candidate this game could spawn a thing PERMANENTLY
		# BOXED into (measured: 39/205 fen configs, 69/205 hub's, including the dev menu's own row).
		if _blocked(v):
			continue
		candidates.append(v)
	while candidates.size() < count:
		# A tight band on a busy world can starve the sample; jitter around home instead of leaving
		# the step unfinishable (catch_game.gd's `_jitter` fallback, same shape) - `_jitter_in_band`
		# itself now `_blocked`-tests its own picks too (see that function).
		candidates.append(_jitter_in_band(rng))

	var chosen: Array[Vector3] = []
	var here := _planet.dir_of(_player.global_position) if is_instance_valid(_player) else _home_dir
	var first := Vector3.ZERO
	var first_err := INF
	for c: Vector3 in candidates:
		var err := absf(_planet.surface_distance(c, here) - FIRST_SPOT_M)
		if err < first_err:
			first_err = err
			first = c
	if first != Vector3.ZERO:
		chosen.append(first)
	while chosen.size() < count:
		var best := Vector3.ZERO
		var best_d := -1.0
		for c: Vector3 in candidates:
			if chosen.has(c):
				continue
			var dmin := INF
			for s: Vector3 in chosen:
				dmin = minf(dmin, _planet.surface_distance(c, s))
			if dmin > best_d:
				best_d = dmin
				best = c
		if best == Vector3.ZERO:
			best = _jitter_in_band(rng)
		chosen.append(best)
	return chosen


## ROUND 2 FIX (finding 1, "frozen forever"): round 1 returned a purely geometric point in the band
## with no collision awareness at all - the one path in the whole spawn pipeline that could still hand
## out a permanently-blocked start even after `_pick_start_dirs`' own `_blocked` filter was in place,
## since THIS is exactly the fallback that fires when that filter starves the candidate pool (a busy
## band). Now retries up to JITTER_TRIES times and `_blocked`-tests each one; only on a band so
## crowded that every single try is still blocked does it fall back to the first sample, so the caller
## always gets a real direction (never Vector3.ZERO).
func _jitter_in_band(rng: RandomNumberGenerator) -> Vector3:
	var lo := _home_radius_m + START_HOME_GAP_M
	var hi := maxf(lo + 0.5, _band_radius_m)
	var first := Vector3.ZERO
	for _try in JITTER_TRIES:
		var ang := rng.randf_range(lo, hi) / maxf(_planet.radius, 1.0)
		var t := Vector3(rng.randfn(), rng.randfn(), rng.randfn())
		t -= _home_dir * t.dot(_home_dir)
		if t.length_squared() < 0.0001:
			t = _home_dir.cross(Vector3.UP)
		var d := (_home_dir * cos(ang) + t.normalized() * sin(ang)).normalized()
		if first == Vector3.ZERO:
			first = d
		if not _blocked(d):
			return d
	return first


# ============================================================================= picking home
func _resolve_home_dir(config: Dictionary, rng: RandomNumberGenerator) -> Vector3:
	if config.has("home_dir"):
		var raw: Variant = config["home_dir"]
		var v := Vector3.ZERO
		if raw is Vector3:
			v = raw
		elif raw is Array and (raw as Array).size() == 3:
			var a: Array = raw
			v = Vector3(float(a[0]), float(a[1]), float(a[2]))
		if v.length_squared() > 0.0001:
			v = v.normalized()
			_warn_if_home_ground_bad(v)
			return v
	return _pick_home_dir(rng)


## ROUND 3, finding B: a world builder's explicit `home_dir` is used as given - the ring and glow follow
## its ground anyway - but one that `_pick_home_dir` would have scored as a riser, a pool rim inside the
## ring, the waterline or unwalkable slope gets ONE warning with the measured numbers, so the builder
## hears about it before a player sees it. Nothing else changes.
func _warn_if_home_ground_bad(d: Vector3) -> void:
	var g := _home_ground(d)
	var tilt_walkable := tan(deg_to_rad(DecorationManager.MAX_SLOPE_DEG)) * _home_radius_m
	if _planet.is_underwater(d) or g.x > HOME_RIM_STEP_MAX_M or g.y > tilt_walkable or g.z < 0.0:
		push_warning("guide_game: home_dir (%.4f, %.4f, %.4f) on %s is not level ground for the ring: step %.3f m (max %.3f), tilt %.3f m (max %.3f), waterline margin %.3f m" % [
			d.x, d.y, d.z, _planet.data.id, g.x, HOME_RIM_STEP_MAX_M, g.y, tilt_walkable, g.z])


## See the header's "PICKING HOME". ROUND 2 REWRITE (finding 5, "dev-menu start not sensible"): round
## 1 took the FIRST candidate that passed a pass/fail gate, and its very last resort -
## `random_surface_dir` - skipped that gate entirely (no prop, water or slope check at all), which is
## how a dev-menu game on grig once put the home ring directly on top of a prop (0/5 settled in 161 s,
## critic round 1) after only 3 gated attempts had been tried. This version SCORES every candidate
## instead of gating it (`_home_spot_score`, below) and always returns the single BEST one it saw - so
## a world with no clean spot still gets its LEAST BAD one, never an unvetted one, and never a console
## warning for what is, worst case, a slightly tight placement rather than a broken one.
func _pick_home_dir(rng: RandomNumberGenerator) -> Vector3:
	var reserved := _reserved_dirs
	var best_d := Vector3.ZERO
	var best_score := -INF

	var craters := _planet.crater_dirs()
	if not craters.is_empty():
		var order: Array[int] = []
		for i in craters.size():
			order.append(i)
		_shuffle(order, rng)
		for oi in mini(order.size(), HOME_CRATER_CAP):
			var idx: int = order[oi]
			var cd: Vector3 = craters[idx].normalized()
			var spot_r := _planet.crater_angle(idx) * _planet.radius + HOME_EDGE_GAP_M + _home_radius_m
			var xf := _planet.surface_transform(cd)
			for _try in RIM_TRIES:
				var ang := TAU * rng.randf()
				var off := (xf.basis.x * cos(ang) + xf.basis.z * sin(ang)) * (spot_r / _planet.radius)
				var d := (cd + off).normalized()
				var s := _home_spot_score(d, reserved, best_score)
				if s > best_score:
					best_score = s
					best_d = d
			if best_score >= 0.0:   # clean already (every check below passed) - stop shopping
				return best_d

	if best_score < 0.0:
		for _try in HOME_OPEN_CANDIDATES:
			var d2 := _planet.find_free_dir(rng, _home_radius_m, 24, false)
			if d2 == Vector3.ZERO:
				continue
			var s2 := _home_spot_score(d2, reserved, best_score)
			if s2 > best_score:
				best_score = s2
				best_d = d2
				if best_score >= 0.0:
					return best_d

	if best_score < 0.0:
		# Worlds with no craters AND where `find_free_dir` itself keeps failing (a very cramped or
		# steep world) - still SCORED, never returned blind the way round 1's raw fallback was.
		for _try in HOME_RAW_CANDIDATES:
			var d3 := _planet.random_surface_dir(rng, reserved, 20.0)
			var s3 := _home_spot_score(d3, reserved, best_score)
			if s3 > best_score:
				best_score = s3
				best_d = d3

	return best_d if best_d != Vector3.ZERO else Vector3.UP


## A continuous stand-in for "is this a good home spot" (round 2, finding 5), used ONLY to RANK
## candidates against each other in `_pick_home_dir` - 0.0 or better means every check below passed
## cleanly; a negative score says how far short it fell, so the best of a bad lot is still a
## meaningful choice, not an arbitrary one. Being under water is the one thing worth ruling out almost
## absolutely: a home spot in the drink is never the right trade against any of the softer costs
## below, which is why it alone returns a value nothing else could ever outweigh.
##
## ROUND 3 (finding B): `beat` is the best score seen so far. Every term only ever SUBTRACTS, so once a
## candidate is at or below it, it cannot win - the remaining, costlier samples are skipped and the
## partial score returned (the caller only keeps a strictly better one). The ground test that replaced
## round 2's `DecorationManager.ground_block_reason` call is `_home_ground` - see there for why.
func _home_spot_score(d: Vector3, reserved: Array[Vector3], beat: float) -> float:
	if _planet.is_underwater(d):
		return -1.0e6
	var score := 0.0
	var gap := INF
	for r in reserved:
		gap = minf(gap, _planet.surface_distance(d, r))
	if gap < HOME_RESERVED_GAP_M:
		score -= (HOME_RESERVED_GAP_M - gap) * 12.0
	var prop_edge := _planet.nearest_prop_distance(d)
	var prop_need := _home_radius_m + HOME_PROP_MARGIN_M
	if prop_edge < prop_need:
		score -= (prop_need - prop_edge) * 12.0
	var bank := _planet.bank_weight(d)
	if bank > 0.35:   # never on a crater wall itself
		score -= (bank - 0.35) * 40.0
	if score <= beat:
		return score
	# ROUND 3 FIX (finding B, "the ring buries itself"): the ground under the ring must be level enough
	# for the ring to lie on it (rule 7: ground the astronaut can walk to). A step or a waterline is as
	# bad as round 2's "not walkable at all" (-60), plus how far past the limit it is, so the least bad
	# of a bad lot still wins; a tilt past the ring's thickness only costs its excess, until it is
	# steeper than a decoration may stand on.
	var ground := _home_ground(d)
	if ground.x > HOME_RIM_STEP_MAX_M:
		score -= 60.0 + (ground.x - HOME_RIM_STEP_MAX_M) * 12.0
	var tilt_walkable := tan(deg_to_rad(DecorationManager.MAX_SLOPE_DEG)) * _home_radius_m
	if ground.y > tilt_walkable:
		score -= 60.0
	if ground.y > HOME_RIM_TILT_MAX_M:
		score -= (ground.y - HOME_RIM_TILT_MAX_M) * 12.0
	if ground.z < 0.0:
		score -= 60.0 - ground.z * 12.0
	if score <= beat:
		return score
	# Ring check (finding 5's "grig ring over a prop"): a prop or reserved zone that only grazes the
	# CENTRE checks above can still poke into the drawn ring - sample the ring itself with the same
	# test a wandering thing gets, and penalise every blocked point on it.
	var xf := _planet.surface_transform(d)
	var blocked_n := 0
	for k in HOME_SCORE_RING_SAMPLES:
		var ang := TAU * float(k) / float(HOME_SCORE_RING_SAMPLES)
		var off := (xf.basis.x * cos(ang) + xf.basis.z * sin(ang)) * (_home_radius_m / _planet.radius)
		if _blocked((d + off).normalized()):
			blocked_n += 1
	score -= float(blocked_n) * 20.0
	return score


## ROUND 3 (finding B): how the ground under a home ring at `d` lies, as Vector3(step, tilt, shore):
##   step   metres the worst rim or settle-slot sample strays from the best-fit plane through all of
##          them (and the centre). This IS the rim-to-ground gap a flat ring would have had, with the
##          planet's curvature and any smooth slope taken out - both fit the plane exactly, so what is
##          left is a terrace riser, a pool rim or a bump inside or across the ring.
##   tilt   metres the rim rises from that plane's own slope (a gentle slope is fine for a ring that
##          follows the ground; a steep one is not walkable).
##   shore  metres the LOWEST sample clears the waterline by, less DecorationManager.SHORE_MARGIN -
##          negative is too close to the water. INF on a world without water.
## `height_at` is radial, so heights on the tangent grid are already curvature-free; the rim and slot
## samples are each evenly spaced round the centre, so the least-squares plane decouples into three
## sums (mean height, and one slope per axis) with no matrix solve. HOME_GROUND_RIM_SAMPLES rim points
## plus HOME_GROUND_SLOT_SAMPLES at the settle slots' radius plus the centre - one call per candidate
## in setup, never per frame. Round 2 used `ground_block_reason(d, home_radius_m)` here: six rim
## samples against the TANGENT plane with a 0.24 m tolerance, which both passed grig's riser spot
## (17 of 36 rim samples buried, critic round 2) and failed most flat spots on the small worlds
## because the planet's own curvature at 1.7 m is 0.11-0.15 m there.
func _home_ground(d: Vector3) -> Vector3:
	var xf := _planet.surface_transform(d)
	var bx := xf.basis.x
	var bz := xf.basis.z
	var n := 1 + HOME_GROUND_RIM_SAMPLES + HOME_GROUND_SLOT_SAMPLES
	var xs := PackedFloat32Array()
	var ys := PackedFloat32Array()
	var hs := PackedFloat32Array()
	xs.resize(n)
	ys.resize(n)
	hs.resize(n)
	hs[0] = _planet.height_at(d)
	var i := 1
	for ring in 2:
		var count := HOME_GROUND_RIM_SAMPLES if ring == 0 else HOME_GROUND_SLOT_SAMPLES
		var r_m := _home_radius_m if ring == 0 else _home_radius_m * SETTLE_SLOT_RADIUS_FRAC
		var a := r_m / _planet.radius
		for k in count:
			var ang := TAU * float(k) / float(count)
			var c := cos(ang)
			var s := sin(ang)
			xs[i] = c * r_m
			ys[i] = s * r_m
			hs[i] = _planet.height_at(d * cos(a) + (bx * c + bz * s) * sin(a))
			i += 1
	var mean := 0.0
	var sxx := 0.0
	var syy := 0.0
	var sxh := 0.0
	var syh := 0.0
	var lowest := INF
	for j in n:
		mean += hs[j]
		lowest = minf(lowest, hs[j])
	mean /= float(n)
	for j in n:
		sxx += xs[j] * xs[j]
		syy += ys[j] * ys[j]
		sxh += xs[j] * (hs[j] - mean)
		syh += ys[j] * (hs[j] - mean)
	var slope_x := sxh / maxf(sxx, 0.000001)
	var slope_y := syh / maxf(syy, 0.000001)
	var step := 0.0
	for j in n:
		step = maxf(step, absf(hs[j] - (mean + slope_x * xs[j] + slope_y * ys[j])))
	var tilt := sqrt(slope_x * slope_x + slope_y * slope_y) * _home_radius_m
	var wr := _planet.water_radius()
	var shore := (lowest - wr - DecorationManager.SHORE_MARGIN) if wr > 0.0 else INF
	return Vector3(step, tilt, shore)


static func _shuffle(arr: Array, rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp


# ============================================================================= home spot art
func _build_home() -> void:
	var f: Dictionary = FLAVOURS.get(_flavour, FLAVOURS[DEFAULT_FLAVOUR])
	_home_glow_color = Color(str(f["glow"]))
	var accent := Color(str(f["accent"]))

	_home_node = Node3D.new()
	_home_node.name = "Home"
	add_child(_home_node)
	_home_node.global_transform = _planet.surface_transform(_home_dir)

	# ROUND 3 FIX (finding B): round 2 lathed a flat torus (`DecoKit.torus`) on the centre's tangent
	# plane, which the ground buried across a terrace riser and floated over on a curved world - see
	# `_build_ring_mesh`. Same node, same shared material, same one draw call.
	var ring_mi := MeshInstance3D.new()
	ring_mi.name = "Ring"
	ring_mi.mesh = _build_ring_mesh(accent)
	ring_mi.material_override = CatchGame._body_material(_flavour)
	ring_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_home_node.add_child(ring_mi)

	_home_glow_node = MeshInstance3D.new()
	_home_glow_node.name = "Glow"
	_home_glow_node.mesh = _build_glow_mesh(_home_radius_m * HOME_GLOW_RADIUS_FRAC * HOME_GLOW_PULSE_SCALE)
	_home_glow_mat = StandardMaterial3D.new()
	_home_glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_home_glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_home_glow_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_home_glow_mat.albedo_texture = DecoItem.soft_dot_texture()
	# The disc is built at the PULSE's full size and the dot drawn smaller inside it (`_set_glow_scale`),
	# so UVs past the dot's edge must clamp to its transparent border rather than repeat the dot.
	_home_glow_mat.texture_repeat = false
	_home_glow_mat.disable_receive_shadows = true
	_home_glow_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_home_glow_node.material_override = _home_glow_mat
	_home_glow_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_home_node.add_child(_home_glow_node)

	_set_glow_scale(1.0)
	_update_home_glow()


## ROUND 3 FIX (finding B): the home ring as a tube swept along the REAL ground. Each of `seg`
## cross-sections sits at exactly home_radius_m from the centre ALONG THE GROUND (a great circle - the
## distance `_process`'s settle check measures, so what you see is still exactly what counts), with its
## underside RING_GROUND_GAP_M above the HIGHEST `height_at` under its span: sampled at the tube's
## inner edge, middle and outer edge, at every cross-section and every midpoint between two, each
## cross-section taking the higher of its own samples and both neighbouring midpoints - so the straight
## tube between two cross-sections also clears the ground under its middle. Built in world space, then
## brought into `_home_node`'s frame. Vertex colours are linear, the same as DecoKit's
## (`PlanetMeshKit._lin`), for the shared vertex-colour toon material.
func _build_ring_mesh(color: Color) -> ArrayMesh:
	var home_xf := _home_node.global_transform
	var inv := home_xf.affine_inverse()
	var bx := home_xf.basis.x
	var bz := home_xf.basis.z
	var seg := clampi(ceili(TAU * _home_radius_m / RING_SEGMENT_M), 24, 96)
	var samples := seg * 2
	var a := _home_radius_m / _planet.radius
	var da := HOME_RING_TUBE_R / _planet.radius
	var ground := PackedFloat32Array()
	ground.resize(samples)
	for k in samples:
		var ang := TAU * float(k) / float(samples)
		var tangent := bx * cos(ang) + bz * sin(ang)
		var g := -INF
		for e in 3:
			var aa := a + da * float(e - 1)
			g = maxf(g, _planet.height_at(_home_dir * cos(aa) + tangent * sin(aa)))
		ground[k] = g
	var centres := PackedVector3Array()
	centres.resize(seg)
	for i in seg:
		var k := i * 2
		var g := maxf(ground[k], maxf(ground[(k + 1) % samples], ground[(k + samples - 1) % samples]))
		var ang := TAU * float(i) / float(seg)
		var d := (_home_dir * cos(a) + (bx * cos(ang) + bz * sin(ang)) * sin(a)).normalized()
		centres[i] = _planet.global_position + d * (g + RING_GROUND_GAP_M + HOME_RING_TUBE_R)

	var lin := color.srgb_to_linear()
	lin.a = color.a
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var cols := PackedColorArray()
	for i in seg:
		var p := centres[i]
		var along := (centres[(i + 1) % seg] - centres[(i + seg - 1) % seg]).normalized()
		var up := _planet.dir_of(p)
		up = (up - along * up.dot(along)).normalized()
		var side := along.cross(up)
		for j in RING_SIDES:
			var phi := TAU * float(j) / float(RING_SIDES)
			var nrm := side * cos(phi) + up * sin(phi)
			verts.append(inv * (p + nrm * HOME_RING_TUBE_R))
			norms.append(inv.basis * nrm)
			cols.append(lin)
	var idx := PackedInt32Array()
	for i in seg:
		var i2 := (i + 1) % seg
		for j in RING_SIDES:
			var j2 := (j + 1) % RING_SIDES
			var va := i * RING_SIDES + j
			var vb := i * RING_SIDES + j2
			var vc := i2 * RING_SIDES + j
			var vd := i2 * RING_SIDES + j2
			# Front faces wind so their right-hand normal points AWAY from the outward normal - the
			# order `PlanetMeshKit.lathe` emits, which the cull_back toon shader renders. Checked per
			# quad rather than trusted to the loop direction, so a mirrored home basis cannot flip it.
			if (verts[vb] - verts[va]).cross(verts[vc] - verts[va]).dot(norms[va]) > 0.0:
				idx.append_array(PackedInt32Array([va, vc, vb, vb, vc, vd]))
			else:
				idx.append_array(PackedInt32Array([va, vb, vc, vb, vd, vc]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_COLOR] = cols
	arrays[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## ROUND 3 FIX (finding B): the ground glow as a polar disc whose every vertex sits GLOW_LIFT_M above
## `height_at` (or above the water surface, where the pulse reaches over a pool) - round 2's flat quad
## had the same tangent-plane problem as the ring. `radius_m` is the pulse's FULL reach; the UVs map
## the soft dot across the whole disc, and `_set_glow_scale` shrinks it back to its resting size. One
## draw call, as before; unshaded and double-sided, so it needs no normals or winding.
func _build_glow_mesh(radius_m: float) -> ArrayMesh:
	var home_xf := _home_node.global_transform
	var inv := home_xf.affine_inverse()
	var bx := home_xf.basis.x
	var bz := home_xf.basis.z
	var wr := _planet.water_radius()
	var verts := PackedVector3Array()
	var uvs := PackedVector2Array()
	var h0 := _planet.height_at(_home_dir)
	if wr > 0.0:
		h0 = maxf(h0, wr)
	verts.append(inv * (_planet.global_position + _home_dir * (h0 + GLOW_LIFT_M)))
	uvs.append(Vector2(0.5, 0.5))
	for r in range(1, GLOW_RINGS + 1):
		var frac := float(r) / float(GLOW_RINGS)
		var a := radius_m * frac / _planet.radius
		for s in GLOW_SEGMENTS:
			var ang := TAU * float(s) / float(GLOW_SEGMENTS)
			var d := (_home_dir * cos(a) + (bx * cos(ang) + bz * sin(ang)) * sin(a)).normalized()
			var h := _planet.height_at(d)
			if wr > 0.0:
				h = maxf(h, wr)
			verts.append(inv * (_planet.global_position + d * (h + GLOW_LIFT_M)))
			uvs.append(Vector2(0.5 + 0.5 * frac * cos(ang), 0.5 + 0.5 * frac * sin(ang)))
	var idx := PackedInt32Array()
	for s in GLOW_SEGMENTS:
		var s2 := (s + 1) % GLOW_SEGMENTS
		idx.append_array(PackedInt32Array([0, 1 + s, 1 + s2]))
	for r in range(1, GLOW_RINGS):
		var inner := 1 + (r - 1) * GLOW_SEGMENTS
		var outer := 1 + r * GLOW_SEGMENTS
		for s in GLOW_SEGMENTS:
			var s2 := (s + 1) % GLOW_SEGMENTS
			idx.append_array(PackedInt32Array([inner + s, outer + s, outer + s2, inner + s, outer + s2, inner + s2]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## ROUND 3 (finding B): the glow's size as a multiple of its resting radius (1.0 at rest,
## HOME_GLOW_PULSE_SCALE at the pulse's peak), drawn by scaling the soft dot's UVs inside the
## pulse-sized disc instead of scaling the node - a node scale would lift the conformed disc's heights
## off the ground (y scales too) and carry its outer vertices over ground they were not built for.
func _set_glow_scale(s: float) -> void:
	if _home_glow_mat == null:
		return
	var k := HOME_GLOW_PULSE_SCALE / maxf(s, 0.01)
	_home_glow_mat.uv1_scale = Vector3(k, k, 1.0)
	_home_glow_mat.uv1_offset = Vector3(0.5 - 0.5 * k, 0.5 - 0.5 * k, 0.0)


## Baseline brightness from progress (rule 4: a resumed game reads "this many already home" with no
## extra nodes) - a fresh pulse on top happens separately, in `_pulse_home_glow`. Round 2: this is now
## a SECOND signal alongside the visible settled fixtures (`_spawn_settled_fixture`/`_settle`), not
## the only one - see the HOME_GLOW_ALPHA_RANGE comment.
func _update_home_glow() -> void:
	if _home_glow_mat == null:
		return
	var t := float(_done) / float(maxi(_total, 1))
	var a := lerpf(HOME_GLOW_ALPHA_RANGE.x, HOME_GLOW_ALPHA_RANGE.y, t)
	_home_glow_mat.albedo_color = Color(_home_glow_color.r, _home_glow_color.g, _home_glow_color.b, a)


## Stronger settle pulse (round 2, finding 3): bigger peak than round 1's 1.35, held a touch longer,
## so it reads clearly alongside the (also new) pop on the settling item itself. Round 3: the same
## size curve and timings, driven through `_set_glow_scale` instead of the node's scale.
func _pulse_home_glow() -> void:
	if _home_glow_node == null or not is_instance_valid(_home_glow_node):
		return
	var tw := _home_glow_node.create_tween()
	tw.tween_method(_set_glow_scale, 1.0, HOME_GLOW_PULSE_SCALE, 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_method(_set_glow_scale, HOME_GLOW_PULSE_SCALE, 1.0, 0.42).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


# ============================================================================= QA
## Prints one line per loose thing: where it is, how far from home and from the astronaut, and its
## current speed - the measurement behind "coming from the far side pushes it home" and "slides free".
func debug_report(tag: String = "") -> void:
	var g := _home_ground(_home_dir)
	print("GUIDE %s flavour=%s done=%d/%d left=%d home=[%.3f,%.3f,%.3f] home_r=%.2f band_r=%.2f ground_step=%.3f tilt=%.3f shore=%.3f" % [
		tag, _flavour, _done, _total, _items.size(), _home_dir.x, _home_dir.y, _home_dir.z, _home_radius_m, _band_radius_m, g.x, g.y, g.z])
	# Round 3, finding A: every settled thing's origin height above the ground under it, and its scale.
	if is_instance_valid(_home_node):
		for ch in _home_node.get_children():
			if ch is Node3D and str(ch.name).begins_with("Wanderer"):
				var n3 := ch as Node3D
				var nd := _planet.dir_of(n3.global_position)
				print("  settled %s above_ground=%.3f scale=%.2f" % [n3.name, (n3.global_position - _planet.global_position).length() - _planet.height_at(nd), n3.scale.x])
	var pdir := _planet.dir_of(_player.global_position) if is_instance_valid(_player) else Vector3.INF
	for i in _items.size():
		var it: Dictionary = _items[i]
		var node: Node3D = it["node"]
		if not is_instance_valid(node):
			continue
		var dir: Vector3 = it["dir"]
		var dh := _planet.surface_distance(dir, _home_dir)
		var dp := _planet.surface_distance(dir, pdir) if pdir.is_finite() else -1.0
		print("  thing %d dist_home=%.2f dist_player=%.2f speed=%.2f pos=%s" % [
			i, dh, dp, float(it["speed"]), str(node.global_position)])
