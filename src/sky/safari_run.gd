class_name SafariRun
extends Node3D
## SPIKE (2026-09-21, scratch only). THE FLIGHT IS THE GAME.
##
## Two spike rounds measured the same failure: standing at a telescope was 99 seconds of DOING in
## an 11.6-minute night, and the user read it straight off the frames - "this telescope game seems
## to feel more like a mini-game than a core game loop... I'd keep trying until I get a perfect
## shot and be done in 3-4 minutes". Their fix is the direction now:
##
##     "is there a way to make it more like a safari or journey on rails where you have to move
##      your scope around as you are travelling around in your space ship... and you have to move
##      around to get the right shot before it passes you by?"
##
## So the 27-29 s scripted cutscene between two worlds - the one that shipped WITH A SKIP BUTTON
## because it was boring - becomes this: 56 s of lane, eight things cast into it (safari_cast.gd),
## and a scope you swing with your thumb. Everything the standing scope taught is kept and inverted:
##
##   STANDING SCOPE (round 2)            SAFARI RUN (here)
##   one sight, centred by the forecast  six to eight, and you have to FIND them
##   20 s exposure, drifting focus       1.0-3.2 s hold, focus is a RANGE dial you can learn
##   the sky turns at 0.050 field/s      things fly PAST you and do not come back
##   you can wait for the next one       the window closes, permanently
##   a print, or a ruined plate          a HAUL: what you got and what you let go
##
## WHAT MAKES IT A SAFARI AND NOT A SHOOTING GALLERY. Three things, all in the data:
##   * MOMENTS. A driftling is worth twice as much caught turning to look at you. The shutter takes
##     whatever moment was strongest while you held it, so the question is never "did I hit it" but
##     "did I wait for the good one" - and waiting costs you the other thing in the sky.
##   * THE OVERLAP. `pod_driftlings` and `ice_frozen` are up together for 8.5 s on opposite sides of
##     the lane. MEASURED in the autopilot run: waiting for the pod's moment and then going for the
##     ice leaves the ice 1.99 s of hold against the 2.20 s it needs - 0.21 s short, with the window
##     shutting. You get one. It is the frame the sheet is built around.
##   * THE HAUL CARD names what you missed and WHY. "You were busy with the pod" is the sentence
##     the whole design is for: it is why you fly the lane again.
##
## SKIP STILL WORKS. A player who taps it lands with an empty haul, which is its own answer.
##
## SYNTHETIC. `--auto` drives the scope from code at a capped slew rate - it pushes the same
## numbers a thumb does but it is NOT proof a real finger works (CLAUDE.md, "Say what is
## synthesised"). Nothing here has been on a phone.
##
## Run it:
##   godot --path <copy> res://showcase/safari.tscn --rendering-method gl_compatibility \
##       -- --route=home_zorp --hour=3.2 --auto

## WHERE EVERYTHING IN A RUN COMES FROM (WIRE round, 2026-09-21). This file used to hold its cast
## in safari_cast.gd's two hand-written CAST_* arrays and price a catch with SafariCast.value_of
## and SkyPrint.grade_for. All three are BYPASSED now:
##
##   THE CAST      SafariLanes.draw_cast(from, to, ctx) - 8 lanes, all 21 pairs, both directions,
##                 drawn out of SafariCatalog's 51 sights. `_ctx()` says what the draw knows.
##   THE WORDS     SafariCatalog.kind_name / rarity_name (FOUR rungs; SafariCast's clamped at 3).
##   THE MONEY     SafariScoring.grade_for / price_of / quality_of, so the moment is worth as much
##                 as the hold and rarity 4 is a real rung.
##   THE FILM      SafariScoring.FILM_BASE and a day box in GameState.
##   THE LANDING   src/sky/safari_haul.gd, which files a print, a journal page and a coin.
##
## WHAT IS LEFT OF safari_cast.gd: four pure functions with no data in them - `pos_at`, `is_up`,
## `moment_at`, `moment_strength` (and `overlaps`, used only by the report). They are the geometry
## of a sight crossing a porthole, they take a cast entry as an argument, and SafariLanes emits
## entries in exactly their shape on purpose. Its CAST_HOME_ZORP / CAST_BOLT_FEN / ROUTES / HINT_LANE
## tables are now dead weight that nothing in a flight reads; deleting them is a tidy-up for
## whoever retires the file, not a behaviour change.

## ================================================================ WAVE 3, G7 "THE SHUTTER"
## (docs/SAFARI_FLIGHT_SPEC.md 9.3 R9, 10.2 R12, 10.3 R13.) The user flew wave 2 and caught 1 of 17.
## Measured cause: `_focus` sat at 0.5 unless you found the knob, `sharp` hit 0 at 0.30 of dial
## error, and exposure only ran while q >= Q_FLOOR - so 19 of the catalog's 51 sights could not be
## photographed at the starting knob however well you aimed, and the shutter refused ("nothing
## exposing") every one of the player's 110 presses. What changed, and none of it touches the
## grading maths (CENTRE_R / EDGE_R / FOCUS_TOL / Q_FLOOR and SafariScoring are as they were):
##
##   AUTOFOCUS   `_autofocus()`: focus glides, at the knob's own KNOB_RATE, to the sight nearest the
##               crosshair inside the glass. Touch the knob and it is yours until the glass settles
##               on a different sight. The knob is now a way to be sharp SOONER, never a wall.
##   THE SHUTTER a tap TAKES THE PICTURE NOW (`_shutter_press` -> `_take`), graded on that instant.
##               Keep your thumb down and the plate BLOOMS (`_bloom_step`): each frame it is re-graded
##               on the same two numbers the full hold always used - how sharp, and the best moment
##               caught - and it only ever goes UP. Let go, or lose the sight, and you keep it.
##               A press that cannot take anything SAYS WHY on the nameplate (`_refuse`); none is
##               silent. The old passive path is untouched: a full hold still takes itself, which is
##               why the expert autopilot's catch lines are byte-identical.
##   MISS CARD   `_miss_reason()` names only causes its own counters recorded. "found it too late"
##               is gone: it was printed for sights that were centred and never sharp.
##   NO SWIM     R12. `swim` is written as 0.0: the glass no longer wobbles when you are lost.
##   CLOCK+BOOST R13. The cabin draws the time left (safari_cockpit.gd `_flight_clock`); `boost` is a
##               toggle that runs the run clock BOOST_X times faster (`_process`).

## ================================================================ FLIGHT WAVE 4, F4 "THE FIRST LESSON"
## (docs/SAFARI_FLIGHT_SPEC.md 11 R14, 12.3, 12.6; docs/STORY_SPINE_SPEC.md 2.5, 2.5b, 6.3.)
##
##   NO PHOTO WITHOUT A PRESS (12.3). G7's critic measured a player who never touched the shutter
##               filling all 10 plates: a full passive hold still called `_catch` by itself. It does
##               not any more. Centring still exposes (`tr["hold"]` grows exactly as before), and a
##               FULL exposure now waits, pinned at `hold_sec`, lit on the shutter cap and the ring,
##               for a press. The press develops it through the untouched `_catch` - the same grade a
##               full hold always got - so a patient tap is still the better picture and nothing in
##               the grading moved. `--policy=never` is the player who never presses: it catches 0.
##               The synthetic `--auto` expert now PRESSES (`_auto_press`, the Space key's function)
##               on the frame its exposure fills, which is why its catch lines stay byte-identical.
##   THE FIRST LESSON (R14). Four pauses on the first photo flight, in the user's order, each fired
##               by the moment the player reaches it - see `_tut_check()` for the triggers and the
##               out-of-order rules, and `TutorialCard` for what is drawn. A pause freezes `_t`, so
##               the lane, the cast and the cabin clock all hold still; it resumes on a tap.
##   THE ASK IN THE SKY. A sight in `PhotoAsks.for_trip()` wears a gold sparkle on its far mark and
##               on its collar dab (safari_cockpit.gd `_ask_*`), and the nameplate says whose ask it is.
##   12.6        `_feed_rail` writes only `rail_on`, the one rail uniform the shader still reads; the
##               old great-circle arc, its "SAFARI rail:" counter and the PROBE rail-tip line are gone.

const EYE_SHADER := preload("res://src/sky/safari_eyepiece.gdshader")

enum Ph { PAD, RUN, HAUL }

# ---------------------------------------------------------------- the skill model, in one place
## Seconds of leaving the pad before the scope comes up. Short: the run is the game, the departure
## is the breath before it.
const PAD_SEC := 6.0

# ---------------------------------------------------------------- safari6: THE WINDOW AND THE SCOPE
## THE CENTRAL CHANGE OF THIS ROUND (docs/SAFARI_FLIGHT_SPEC.md 6.2). A real person flew this twice
## and caught nothing: the glass showed a 14-degree circle out of a reachable sky of 360 x 108
## degrees, 0.46% of it. So there are two fields now:
##
##   LOWERED (the default) 28 deg half-field - a 56-degree window. Shapes drift past small and soft;
##                         this is where you look around, read the horizon band, follow the rail and
##                         decide what to go for. 18x more sky than before.
##   RAISED (the scope)    7 deg half-field - EXACTLY the old glass, for the shot.
##
## LANDMINE, and it is the reason the spec had to be written twice: the shader reads `field_half`
## and IGNORES `field_deg`, and the flight only ever set `field_deg`. So `field_half` sat at its
## 7-degree default no matter what any constant said, and moving SafariCatalog.FIELD_HALF_DEG moved
## the scoring and the collar and LEFT THE PICTURE IDENTICAL. `_update_glass` now writes
## `field_half` from `field_half_deg()` every frame; nothing else can widen the window.
const FIELD_LOW_DEG := 28.0
const FIELD_HIGH_DEG := 7.0

## SCORING IS IN ABSOLUTE DEGREES NOW, and that is the whole point of the conversion.
##
## CENTRE_R and EDGE_R used to be read as fractions of "the field", and the field was about to stop
## being one number. Five rounds of exposure, hold and clash tuning are sitting on the ANGLES those
## fractions happened to mean at a 7-degree field - a 2.10 degree bullseye and a 5.46 degree edge -
## so those angles are what is preserved. `field_of()` reports in units of SCORE_UNIT_DEG, which is
## a constant of THIS file and not the window's width, so widening the window cannot move a score
## and neither can anyone changing SafariCatalog.FIELD_HALF_DEG.
##
## The arithmetic below is left in the exact form it was tuned in, on purpose: the proof for this
## change is "the same seeds give byte-identical catch lines", and rewriting `1 - (d - 0.30)/0.48`
## as `1 - (deg - 2.10)/3.36` would make that proof approximate instead of exact.
const SCORE_UNIT_DEG := 7.0
const CENTRE_R := 0.30
const EDGE_R := 0.78
## The same two numbers as ANGLES, which is what they now are. Anything outside the scoring loop
## (the rail's keep-out, a critic's tape measure) uses these.
const CENTRE_DEG := CENTRE_R * SCORE_UNIT_DEG   # 2.10
const EDGE_DEG := EDGE_R * SCORE_UNIT_DEG       # 5.46
## Range-dial error at which sharpness hits 0. The knob runs 0..1 over the whole lane's depth, so
## 0.30 is a third of the dial: forgiving, because you are also steering.
const FOCUS_TOL := 0.30
## Below this the shot does not expose at all and you start losing what you had.
const Q_FLOOR := 0.30
const DRAIN_RATE := 0.90
## Dragging one glass-radius swings the scope this many degrees. 34 deg is 2.4 fields, which is the
## number that makes a 132 deg cross-lane swing about four thumb-drags - a decision you can feel.
const DRAG_DEG_PER_R := 34.0
## Keyboard and autopilot slew. A thumb on glass can beat this in a flick; the autopilot must not,
## or the overlap stops being a choice and the measurement is a lie.
const SLEW_MAX_DEG := 55.0
const KNOB_RATE := 0.85
## R9: autofocus turns the SAME dial at the SAME rate a thumb on the keys does (KNOB_RATE), so there
## is no new tuning number in it. From the worst end of the dial to any catalog focus is <= 0.82 of
## travel = 0.96 s. A finger dragging the knob is faster than that, which is the knob's reward.

## R13: the boost runs the lane clock this many times faster. Not tuned: R4 made flights 156-234 s,
## at least three times the old 56 s run; x4 puts the longest lane (234 s) back to 58.5 s, i.e. a
## player who has what they came for can give the whole R4 lengthening back.
const BOOST_X := 4.0
## R13 BOOST IS NOT LIVE (G7 round 2, critic FAIL 2026-09-22). Boosting from t=0 on home_vela cut the
## DAYLEDGER bill from 6.06 h to 1.91 h, because safari_flight.gd bills the leg's real seconds and
## nothing reads `boost_saved_sec()`. Spec 10.3: the 6.0 h cost "must not silently change". Until
## safari_flight.gd (G4) bills `boost_saved_sec()`, the button is hidden and `set_boost` refuses, so
## no path (button, B key, `--boost-at=`) can turn it on. Flip this once the flight bills it.
## LEAD, merge4 2026-09-23 (docs/SAFARI_FLIGHT_SPEC.md 12.2): flipped to true after G4b made a
## photo flight bill exactly PHOTO_TRIP_HOURS whatever its real duration, and after the lead's
## boosted-vs-plain ledger on the merged build read the same trip hours.
const BOOST_LIVE := true
## A moment counts toward a plate only past this strength - the same 0.35 `_catch` always used.
const MOMENT_MIN := 0.35

## R5 - YOU CANNOT LOOK STRAIGHT UP OR STRAIGHT DOWN, and the number is not a taste call.
##
## THE RULE: the flight's horizontal plane must never leave the wide window. The horizon band (R2)
## sits at elevation 0 and the lowered window reaches FIELD_LOW_DEG above and below the crosshair,
## so clamping the crosshair to +-FIELD_LOW_DEG puts the plane, at worst, exactly on the porthole's
## rim. Point as high as the ship allows and the gold band is still there, at the bottom edge,
## telling you so. That is an exact inversion of the window's own half-field with no free parameter
## in it, and it is a direct answer to "was I looking up or down sideways or backwards".
##
## It also kills the empty pole: the old +-52/56 let you park 63 degrees up, where the cast never
## goes and nothing is ever drawn.
##
## THE OTHER HALF OF R5 IS NOT MINE. safari_lanes.gd holds its own EL_MIN/EL_MAX copy (its :43-44)
## and its SIDES table places sights up to el 44; until G3 matches these numbers, a sight can sit
## above the reachable sky. `_clamp_cast_el()` below is the bridge, and it becomes a no-op the
## moment safari_lanes.gd's copy matches.
const EL_MIN := -FIELD_LOW_DEG
const EL_MAX := FIELD_LOW_DEG

## R1 - how many uncaught sights can carry a far mark at once. The shader block is unrolled (WebGL2
## bans a dynamically indexed uniform array), so this is a hard count; the nearest MARK_N to the
## crosshair win it. Measured over all 8 lanes x 3 hours, the most ever up at one instant is 3.
const MARK_N := 8
## S3: "every subject gets a 1-2 second warning before it can be framed". The mark comes up this
## many seconds BEFORE the sight's window opens (SafariCast.pos_at clamps, so it sits at az0/el0
## waiting) and flares while it does. This is the in-glass half of S3; the collar dab is G2's half.
const MARK_LEAD_SEC := 2.0
## A far mark's CORE is this many degrees across; the ring around it sits at 1.9 core-radii, so the
## whole mark is 1.9 x MARK_DEG = 2.47 degrees wide. A star in lane_sky.gdshaderinc is about a tenth
## of a degree, so the mark is an order of magnitude wider before a single photon of brightness is
## compared - and it is an ANNULUS, which no star in the field is. Measured on a 1280x720 frame at
## the 28-degree field: the ring spans 30 device px where the median star spans 2.
const MARK_DEG := 1.30

const C_CREAM := Color("#e9eaf1")
const C_TEXT := Color("#2c2f42")
const C_SOFT := Color("#6d7288")
const C_NAVY := Color("#1b1f33")
const C_BRASS_SH := Color("#3a2b18")
const C_BRASS_D := Color("#6d5230")
const C_BRASS := Color("#a87f4c")
const C_BRASS_HI := Color("#dcb87a")
const C_AMBER := Color("#f0a64a")
const C_GOLD := Color("#ffe27a")
const C_MISS := Color("#8d93a8")

## THE CABIN. Fractions of the viewport taken by the hull above and below the porthole.
##
## THE WINDOW IS A ROUND PORTHOLE (2026-09-21, second pass). The first pass made it a wide rounded
## rectangle and the user caught it on a single frame:
##
##     "I do like the round porthole, but just the outside of the porthole would be the inside of
##      the ship. I saw a flash on the screen of a rectangular view and wanted to clarify that."
##
## So the opening is a circle again and the HULL is what changed. `_win` is now the porthole's
## BOUNDING SQUARE, centred across the screen; everything inside that square but outside the disc
## is hull, painted by safari_cockpit._aperture().
##
## HOW BIG IT CAN BE, measured rather than argued. An uncropped circle can never be wider than the
## screen is tall, so on the user's 2556x1179 phone the largest possible porthole is
## pi/4 x 1179^2 / (2556 x 1179) = 36% of the frame. The brief asked for "at least half the
## screen"; half is only reachable by cropping the disc or going back to a rectangle, which is the
## thing the user just corrected.
##
## SO THE BANDS WENT. The review measured the disc at 21.5% of the phone frame - 59% of what an
## uncropped circle can have - because the rail (0.075) and the console (0.145) ate a fifth of the
## height between them. Everything those bands carried now lives in the SIDE COLUMNS, which on a
## 2556x1179 phone are 446 UI px wide each and already hold both thumbs: the heading instrument is
## engraved around the porthole's own collar (src/sky/safari_cockpit.gd), and the nameplate sits
## over the left thumb. What is left up top is a lip for the Skip button and a sill at the bottom,
## and the porthole gets 668 of 720 UI px - 31.2% of the frame. The real numbers print at startup.
const RAIL_F := 0.043
const CONSOLE_F := 0.029
## The porthole may not take more than this fraction of the WIDTH (matters on a narrow viewport).
const PORT_MAX_W := 0.62
## 13.5: THE COLLAR RING'S OWN GEOMETRY, read by `_layout_cockpit()` below AND by
## `SafariCockpit.collar_width()` / `_rose()` / `dab_point()` / `_elev_tag()`, so there is exactly
## one copy of each number - a second copy is how the console band's old "30 UI px" comment went
## stale (see the GRID ROUND note below). `COLLAR_RW_FRAC` is the ring's width as a fraction of the
## disc radius; `COLLAR_DAB_OFFSET_FRAC` is how far out on the ring a mark's centre sits beyond the
## glass edge - the SAME ring a dab, an S3 "about to be up" ping and the ask sparkle all sit on.
## `COLLAR_DAB_HALO_FRAC` is a caught-up dab's own outer circle at its biggest (`mo` == 1,
## `0.42 + 0.26 * mo` in `_rose()`). `COLLAR_DAB_REACH_FRAC` is the offset plus that halo: the
## farthest a plain DAB ever draws beyond the glass edge, in units of the ring width - what
## `_layout_cockpit()` leaves the disc room for. Two OTHER marks reach further still at their own
## extreme (the S3 ping's biggest pulse, `COLLAR_PING_HALO_FRAC` below; the elevation chevron at
## `del` near `_pitch_span_deg()`) - rather than size the whole disc for either of THEIR worst cases
## too (a much bigger porthole shrink for a case that is not "a dab"), each shrinks ITSELF to fit
## the real room left, the same idea `_elev_tag()`'s existing clipped-chevron fix already uses.
const COLLAR_RW_FRAC := 0.052
const COLLAR_DAB_OFFSET_FRAC := 0.45
const COLLAR_DAB_HALO_FRAC := 0.68
const COLLAR_DAB_REACH_FRAC := COLLAR_DAB_OFFSET_FRAC + COLLAR_DAB_HALO_FRAC
## The S3 ping's own ring at its biggest pulse (`rw * lerp(0.30, COLLAR_PING_HALO_FRAC, pulse)` in
## `_rose()`) - bigger than a dab's halo, self-shrunk at draw time rather than budgeted into the
## layout (see the block comment above).
const COLLAR_PING_HALO_FRAC := 1.05
## A dab drawn dead ahead or dead astern reaches `rad * COLLAR_RW_FRAC * COLLAR_DAB_REACH_FRAC`
## beyond the glass, at every bearing the ring has (a uniform ring radius, not bearing-dependent) -
## so this is the one number `_layout_cockpit()` has to leave both the top of the frame AND the
## real bottom safe-area inset room for. A flat "clears the drawing's own soft edge" cushion, same
## idea as `_elev_tag()`'s `margin` - not a fitted number, just enough that nothing sits exactly on
## the literal pixel edge.
const COLLAR_EDGE_CUSHION := 4.0
## The window's corner radius, in q units (q.y spans +-1). Must match the shader's `corner`.
## On a SQUARE opening 1.0 IS a circle: the shader's rounded-box SDF collapses to length(p) - 1.
const CORNER_Q := 1.0
const FF_COUNT := 7
## How long the nameplate keeps showing what you just caught before it goes back to the sky.
const CATCH_HOLD_SEC := 1.8

signal shot_taken(rec: Dictionary)
signal run_finished(haul: Array)
## The shutter button was pressed. `took` is whether a plate was actually exposed - false both for
## a refused press (nothing takeable, and the words why) and for "the magazine is empty" (see
## `_shutter_press`). FILM builder pass:
## the limit the user asked for ("limited film for each trip") is built and real as of this round -
## see `film_start` below and `GameState.film_capacity()`.
signal shutter_used(took: bool)
## MODE round: fired once, when the player leaves the HAUL card ("Land"), replacing the old
## `get_tree().quit()` placeholder. `wall_seconds` is `_wall` at that moment — real seconds since
## THIS scene's `_ready()`, PAD + RUN + however long the player lingered reading the haul card —
## so whoever is listening (the pad-side wrapper) can charge the in-game clock for exactly how
## long the player was actually away, not a guessed number.
signal landed(wall_seconds: float)

# ---------------------------------------------------------------- state
## WIRE round (2026-09-21). THE TRIP IS TWO WORLD IDS, not a route key. safari_cast.gd's ROUTES
## table had exactly two entries and only one of them flyable; SafariLanes covers all 21 pairs and
## all 42 directed trips, and the DIRECTION of the trip is content (it reverses every sweep and
## gates `dir` sights), so "home -> zorp" and "zorp -> home" can no longer share one id.
## `route_id` is kept ONLY as an argument alias: `--route=home_zorp` still means from=home, to=zorp
## (every world id is one word, so the split is unambiguous), so old showcase scenes and timelines
## still run.
var from_id := "home"
var to_id := "zorp"
var route_id := "home_zorp"
var hour := 3.2
## WIRE (2026-09-21). The day is what decides whether a heard hint's sight is out on the lane today
## (SkyHints._unlocked_today, one day in three). Defaults to the real clock; `--day=` overrides it so
## a capture of the green moon is repeatable.
var day := -1
var auto_pilot := false

var _phase: int = Ph.PAD
var _t := 0.0                    # seconds since the scope came up (negative during the pad drop)
var _cast: Array = []
var _run_seconds := 56.0

var _az := 0.0
var _el := 4.0
var _focus := 0.5
var _flash := 0.0
## safari6: the scope. False is LOWERED - the wide 56-degree window - and that is the default state
## of a run, because the first thing a player has to be able to do is find something.
var _scope := false
## SYNTHETIC, measurement only (`--el-span=MIN:MAX`). Lets a capture reproduce the old +-52/56 sky
## so the scoring A/B can isolate the field change from the R5 clamp. A real flight never sets it.
var _el_min := EL_MIN
var _el_max := EL_MAX
## SYNTHETIC A/B switches (`--no-aurora`, `--no-rail`). Shipped values are 1.0 and false.
var _aurora := 1.0
var _rail_off := false
var _marks_off := false
var _scope_taps: Array = []
## The last zone a press landed in, kept for `--tap-scope=`'s report (a press's `_zones` entry is
## erased again by the release, so it cannot be read afterwards).
var _last_zone := ""
var _tap_trace := false
var _heat := false
## SYNTHETIC, `--heat-copies=N`: extra rasterisations of the shipped eyepiece, for the slope fit.
var _heat_copies := 0
var _heat_rects: Array = []
var _heat_gpu: Array[float] = []
var _heat_cpu: Array[float] = []
## R1's accounting, in SIGHT-SECONDS. `_up_sec` counts every second an uncaught sight is up;
## `_old_drawn_sec` is how much of that the OLD build put on the glass (the `d < 1.65` gate, 11.5
## deg); `_window_sec` is how much of it is inside the window the player actually has; `_mark_sec`
## is how much of it carries a mark or a shape. Printed at the end of a run, so "the sky was empty"
## has a number attached to it instead of an argument.
var _up_sec := 0.0
var _old_drawn_sec := 0.0
var _window_sec := 0.0
var _mark_dropped_sec := 0.0

## id -> {"hold", "qsum", "qtime", "best_moment", "best_line", "caught", "seen"}
var _track: Dictionary = {}
var _haul: Array = []
var _auto_plan: Array = []
var _auto_i := 0

# ---------------------------------------------------------------- film (FILM builder pass, points 3/4)
## WIRE round: SafariScoring.FILM_BASE (4), not GameState's old 5, because this is a
## default field initializer and autoload access there is not reliable. A real flight always
## overwrites it with `GameState.film_capacity()` before `_ready()` runs (`safari_flight.gd`); this
## is only what a showcase/direct run gets with no caller.
const FILM_BASE_FALLBACK := SafariScoring.FILM_BASE

## Plates loaded for THIS run, always a FULL magazine - film is per trip, not a day box (point 3/4).
## `--film=N` (below) overrides it for measuring other values than the real one.
##
## WHY 5, MEASURED, not 4 or 7 (`--route=home_zorp --hour=3.2 --auto --report --film=N`, this
## round): the home_zorp cast at hour 3.2 is 6 subjects (not 8 - two more are heard-hint sights that
## only join some days), and the autopilot's own greedy plan — the same plan the pod/ice overlap is
## built to punish — clears exactly 5 of them, missing only `ice_frozen` to the overlap by design.
##   film=7: two plates spare. The same 5 land; the 2 extras are free - a wasted or premature
##           shutter press costs nothing, so film is decoration. This is the bug this round fixes.
##   film=5: zero plates spare. The same 5 land, `film_left=0` on the very last one - a player who
##           fires early on a weak exposure, or spends a plate on the wrong thing, is now short one
##           of the 5 real catches for it. Every press has to count, without punishing a clean run.
##   film=4: one short of even a flawless run. `moon_zorp_rim` (hold 1.40/1.40, fully held) logs
##           "the plates ran out first" instead of landing - a perfect flight gets charged for being
##           perfect, which is a tax, not a choice.
var film_start := FILM_BASE_FALLBACK
var _film_left := 0
var _film_plates: Array[PanelContainer] = []
var _film_row: GridContainer
var _film_out_toast: Label
## GRID ROUND (SAFARI_FLIGHT_SPEC.md 7.3). The last `plate_side` `_layout_cockpit()` computed, so it
## only calls `_update_film_row()` (which rebuilds every plate's StyleBoxFlat) when the size the
## grid search picked has actually changed - a resize or a film-count change - rather than on every
## `_process()` frame the way calling it unconditionally from inside `_layout_cockpit()` would.
var _film_plate_side := -1.0

var _haul_sink: SafariHaul
var _cam: Camera3D
## ROUND 2 (space builder). Everything outside the window - the sky, the two worlds, the lantern
## gates, the dust - moved into src/sky/space_lane.gd, which owns it and drives it off ONE speed.
## SafariRun keeps only the camera, the canopy and the naked-eye smudges of its own cast.
var _lane: SpaceLane

var _layer: CanvasLayer
var _root: Control
var _eye_root: Control
var _eye: ColorRect
var _eye_mat: ShaderMaterial
var _cockpit: SafariCockpit
var _scope_fb: ScopeFallback
var _skip: Button
var _card: PanelContainer
var _zones: Dictionary = {}
var _win := Rect2()
var _rail := Rect2()
var _con := Rect2()
var _uis := 1.0
var _lead_hold := 0.0
## {"title", "sub", "t"} of the last plate exposed, for the nameplate. Empty before the first one.
var _last_catch: Dictionary = {}
var _press_t := 0.0
var _touch_seen := false
var _ff_settle: Array[float] = []
var _ff_seed: Array[float] = []
var _live: Array = []            # the up-to-3 subjects the glass is drawing this frame

# capture
var _cap_dir := ""
var _shots: Array = []           # [{"name", "t"}], t in RUN time (PAD time is negative)
var _quit_at := -1.0
## SYNTHETIC. Taps Skip at this run second, so "a player who skips gets an empty haul" is a thing
## that was RUN and not a thing that was claimed.
var _skip_at := -1.0
var _report := false
var _reported := false
var _wall := 0.0
## SYNTHETIC, captures only. `--pose=t:az:el,...` snaps the scope to a heading at a run second so
## the sheet can show the cabin looking left, right and behind. It sets _az/_el directly: it is not
## a thumb, it does not obey SLEW_MAX_DEG, and it proves nothing about input.
var _poses: Array = []
var _auto_land_timer := -1.0
## SYNTHETIC, G6 WAVE 2 REGRESSION PROOF ONLY (SAFARI_FLIGHT_SPEC.md 7.5, the clipped chevron).
## `--fake-sight=az:el` injects one permanently-up, permanently-uncaught cast entry at a FIXED
## absolute az/el, never emitted by SafariLanes. Combined with `--pose=t:az:el`, which snaps the
## PLAYER's own heading, this lets a capture put the fake sight at ANY relative bearing and ANY
## elevation delta on demand - including exactly dead-astern and below, the one combination the
## wave-1 critic reproduced on only 2 of 7 real captures and could not have gone looking for on
## purpose. It never enters `_live` (nothing drives the scope toward it in this mode) and it is
## not part of any lane's real content.
var _fake_sight_on := false
var _fake_sight_az := 0.0
var _fake_sight_el := 0.0
## SYNTHETIC, F5 (SAFARI_FLIGHT_SPEC.md 13.5, the S3 "about to be up" ping). `--fake-sight=az:el:ts`
## with a third field sets the fake sight's `t_start` (default -999, i.e. always up) so a capture
## can sweep it through the ping's pulse (`_rose()`'s S3 loop, `WARN_LEAD_SEC`) instead of the plain
## caught-up dab, which is a smaller mark. A real flight never passes the third field.
var _fake_sight_t_start := -999.0
## SYNTHETIC, F5 (SAFARI_FLIGHT_SPEC.md 13.5, the collar dab clipping off the bottom). Same idea as
## `--fake-sight=` above but a whole ring of them over time, one process: `--fake-sight-seq=t:az:el,...`
## re-points the single fake sight at a new absolute az/el once `_t` reaches each entry, so one run
## paired with `--shots=name@t,...` can capture every bearing round the compass, above and below,
## without paying for 16 separate headless launches. Never a lane's real content.
var _fake_sight_seq: Array = []

# ---------------------------------------------------------------- R9: autofocus and the shutter
## The sight autofocus is on ("" when nothing is in the glass).
var _af_id := ""
## True once a thumb (or Q/E) has turned the knob. Autofocus then leaves the dial alone until the
## glass settles on a DIFFERENT sight than the one it was on when the knob was touched.
var _manual := false
var _manual_for := ""
var _manual_sec := 0.0
## The plate that is blooming under a held shutter: {"id", "rec", "t0"}. Empty when none is.
var _shot: Dictionary = {}
var _space_held := false
## A refused press whose thumb is still down: it takes the first frame something becomes takeable.
var _armed := false
## {"title", "sub", "t"}: what the last refused press said. Shown on the nameplate.
var _note: Dictionary = {}
## Counters for the end-of-run line, so "no press is ever dead" is a number.
var _st := {"press": 0, "take": 0, "refuse": 0, "nothing": 0, "offcentre": 0, "unsharp": 0,
	"nofilm": 0, "caught": 0, "armed_take": 0, "bloomed": 0, "early": 0, "full": 0}
## 12.3: catches the camera took with NO press. Nothing increments it any more; it is printed so the
## end-of-run line proves it stays 0 (G7's critic measured 10 of 10 plates filled this way).
var _auto_fill := 0

# ---------------------------------------------------------------- R13: boost
var _boost := false
## Run seconds the boost has flown that the wall clock did not pay for. Read by `boost_saved_sec()`.
var _boost_saved := 0.0
var _boost_wall := 0.0
## SYNTHETIC `--boost-at=T,T2,...`: toggles the boost at those run seconds.
var _boost_ats: Array = []
var _boost_btn: Button

# ---------------------------------------------------------------- SYNTHETIC: the tap-only policy
## `--policy=tap` / `--policy=tap-blind`. A first-time player who NEVER touches the knob and NEVER
## holds the shutter. See `_policy_step()` for exactly what it can see and do.
var _policy := ""
var _pol_rng := RandomNumberGenerator.new()
var _pol_id := ""
var _pol_seen: Dictionary = {}
var _pol_err := Vector2.ZERO
var _pol_err_at := -1.0
var _pol_next_tap := 0.0
var _pol_look_at := -1.0
var _pol_tap_deg := 4.0
var _pol_aim_err := 1.5
var _pol_react := 0.40
var _pol_gap := 0.35
var _pol_real_input := true
var _catalog_probe := false
var _holds: Array = []
var _swim_legacy := false
var _probe_win := 15.0

# ---------------------------------------------------------------- R14: the first lesson
## The flag that says the tutorial has been played (or skipped). In GameState.flags, so it rides the
## save like every other story flag.
const TUT_FLAG := "safari_tutorial_done"
## Which lessons have been shown or skipped so far, bit N for lesson N (far, zoom, snap, film), in
## GameState.flags beside TUT_FLAG. A flight that ends with lessons still owed leaves TUT_FLAG unset
## and keeps this, so the next photo flight teaches only what is left (critic round 1: a player who
## never raised the scope got cards 1-2 and then the flag, and was never shown the hold or the film).
const TUT_PROGRESS := "safari_tutorial_seen"
const TUT_ALL := 15
## A tap that lands this soon after a card appears does not dismiss it: a thumb already on its way
## to the shutter must not wave away a card nobody has read.
const TUT_TAP_GUARD := 0.45
## Lesson 1's fallback. If the asked sight has been up this long and has never been in the window,
## the card fires anyway and points at the collar dab alone. Without it a player looking the other
## way would never be shown where to look - the one thing lesson 1 is for.
const TUT_FAR_WAIT := 3.0
## The ids of this trip's asks that are in the cast, -> who asked ("The Professor", "Zorp").
var _ask_by: Dictionary = {}
## Is the tutorial running on this flight at all, and what it is teaching on.
var _tut_on := false
var _tut_id := ""
## 0 far, 1 zoom are taught in order; 2 = both of those are behind us and snap and film each wait
## for their own moment (bits 2 and 3 of `_tut_res`). 4 = all done.
var _tut_step := 0
## Bitmask of the lessons shown or skipped, this flight and earlier ones (TUT_PROGRESS).
var _tut_res := 0
var _tut_paused := false
var _tut_card := -1
var _tut_wall0 := 0.0
var _tut_t0 := 0.0
## `GameState.time_of_day` at the moment this pause fired - logged at resume so a probe can check
## the cabin clock read the same value both times (13.4/13.5).
var _tut_cabin_hour0 := 0.0
var _tut_paused_wall := 0.0
var _tut_shown := 0
var _tut_variant := ""
## What the player has already done by themselves (the out-of-order rule).
var _tut_zoomed := false
var _tut_tapped := false
var _tut_held := false
var _tut_up_since := -1.0
var _tut_node: TutorialCard
## SYNTHETIC: `--tutorial` makes a showcase run eligible (a real flight always is); `--no-tutorial`
## turns it off; `--pol-skip-tut` makes the policy take "skip tutorial" on card 1.
var _tut_force := false
var _tut_block := false
var _pol_skip_tut := false
var _pol_scope_up := false
var _pol_want_scope := false
var _pol_empty_since := -1.0


func _ready() -> void:
	_parse_args()
	if day < 0:
		day = GameState.day_count
	# WIRE round: THE CONTENT IS THE GAME. The cast is drawn off SafariLanes (8 lanes, all 21 pairs,
	# the clash, the conditions slot) out of SafariCatalog's 51 sights. safari_cast.gd's CAST_*
	# arrays are BYPASSED - nothing in this file reads them any more; see `_ctx()` for what the draw
	# is allowed to know, and the file header for what is left of safari_cast.gd (pure geometry).
	_cast = SafariLanes.draw_cast(from_id, to_id, _ctx())
	_run_seconds = SafariLanes.seconds_for(from_id, to_id)
	_clamp_cast_el()
	_film_left = film_start
	for e in _cast:
		_track[str(e["id"])] = _new_track()
	if _fake_sight_on:
		# SYNTHETIC, G6 WAVE 2 CHEVRON REGRESSION ONLY - appended AFTER `_clamp_cast_el()` so R5's
		# bridge never touches it, and its az/el are whatever `--fake-sight=` asked for exactly.
		# Every field a real SafariLanes entry carries, so nothing downstream (the nameplate, the
		# journal swatch, the focus sharpness math) hits a missing key and aborts mid-frame the way
		# the field_half_deg()/scope_raised() landmine did before this file shipped them.
		var fe := {
			"id": "fake_sight", "tint_a": "#ff2a2a", "az0": _fake_sight_az, "el0": _fake_sight_el,
			"az1": _fake_sight_az, "el1": _fake_sight_el, "t_start": _fake_sight_t_start, "t_end": 999999.0,
			"moments": [], "title": "fake sight (SYNTHETIC)", "kind": 0, "rarity": 1,
			"journal_kind": "fake", "slot": "fake_slot", "focus": 0.5, "hold_sec": 2.0,
		}
		_cast.append(fe)
		_track["fake_sight"] = _new_track()
	_ff_settle.resize(FF_COUNT)
	_ff_seed.resize(FF_COUNT)
	for i in FF_COUNT:
		_ff_settle[i] = 0.0
		_ff_seed[i] = float(i) * 2.37 + 0.91
	_build_3d()
	_build_ui()
	_tut_setup()
	# WIRE (2026-09-21). `run_finished` had no listener anywhere in the project: every photograph a
	# player took was destroyed with the scene. The flight now brings its own landing, so any scene
	# that plays a run gets the journal page and the coin without knowing this file exists.
	_haul_sink = SafariHaul.new()
	add_child(_haul_sink)
	_haul_sink.attach(self)
	if _heat:
		# The Compatibility renderer reports viewport_get_measured_render_time_gpu() as 0.000 on this
		# machine (measured: 1620 frames, every sample exactly zero), so the GPU timer is not
		# available and the honest thing left is the FRAME INTERVAL with the frame rate uncapped.
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		Engine.max_fps = 0
	_t = -PAD_SEC
	if auto_pilot:
		_auto_plan = _make_auto_plan()
	if _policy != "":
		# Repeatable: the same trip, hour and day always draws the same thumb.
		_pol_rng.seed = hash("%s_%s_%.2f_%d_%s" % [from_id, to_id, hour, day, _policy])
	if _catalog_probe:
		_run_catalog_probe()
		get_tree().quit()
		return
	set_process(true)
	var ids: Array = []
	for e in _cast:
		ids.append(str(e["id"]))
	print("SAFARI lane=%s %s->%s dir=%s hour=%.2f day=%d cast=%d [%s] run=%.1fs film=%d auto=%s" % [
		str(lane().get("id", "")), from_id, to_id, str(lane().get("direction", "")), hour, day,
		_cast.size(), ", ".join(PackedStringArray(ids)), _run_seconds, film_start,
		str(auto_pilot)])
	if _report:
		_print_report()


## R14 and the ask marker: who asked for what on THIS trip, and whether the first lesson runs.
##
## THE ASKED SIGHT is the first of `PhotoAsks.for_trip()` that the draw actually put in the cast
## (the draw's guarantee means it always is, while an ask is open); an old save with no ask teaches
## on the lane's dead-ahead opener, the cast entry in the "open" slot.
##
## WHO GETS THE TUTORIAL: a real flight (this node's parent is safari_flight.gd) whose save has not
## set TUT_FLAG. A showcase run only with `--tutorial`; never under `--auto` or a policy unless
## `--tutorial` is also passed, so no existing measurement run is paused by it.
func _tut_setup() -> void:
	var lid := str(lane().get("id", ""))
	var asked: Array[String] = PhotoAsks.for_trip(lid, from_id, to_id, hour)
	for sid in asked:
		if _find_cast(sid).is_empty():
			continue
		_ask_by[sid] = SafariRun.asker_label(str(PhotoAsks.get_ask(sid).get("by", "")))
		if _tut_id == "":
			_tut_id = sid
	if _tut_id == "":
		for e in _cast:
			if str(e.get("slot", "")) == "open":
				_tut_id = str(e["id"])
				break
	var real_flight: bool = get_parent() != null and get_parent().get_script() != null \
		and str((get_parent().get_script() as Script).resource_path).ends_with("safari_flight.gd")
	var eligible: bool = _tut_force or (real_flight and not auto_pilot and _policy == "")
	var done: bool = bool(GameState.flags.get(TUT_FLAG, false))
	_tut_res = int(GameState.flags.get(TUT_PROGRESS, 0)) & TUT_ALL
	_tut_step = _tut_next_step()
	_tut_on = eligible and not done and _tut_res != TUT_ALL and not _tut_block and _tut_id != "" \
		and not _catalog_probe
	if _tut_on:
		_tut_node = TutorialCard.new()
		_tut_node.run = self
		_tut_node.name = "FirstLesson"
		_tut_node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_tut_node.visible = false
		_tut_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_root.add_child(_tut_node)
	print("SAFARI asks on this trip: [%s]; tutorial %s (flag %s=%s, lessons already seen mask=%d, real flight %s, teaching on %s)" % [
		", ".join(PackedStringArray(_ask_by.keys().map(func(k): return "%s by %s" % [k, _ask_by[k]]))),
		"ON" if _tut_on else "off", TUT_FLAG, str(done), _tut_res, str(real_flight),
		_tut_id if _tut_id != "" else "-"])


## "The Professor", or a neighbour's own display name - the same labels the pad's mode card uses
## (pad_mode_picker.gd `_asker_label`), so the sky and the pad name the asker the same way.
static func asker_label(by: String) -> String:
	if by == "professor":
		return "The Professor"
	if by == "":
		return "Someone"
	return Journal.npc_name(by)


## One sight's running record. The first eight keys are the ones the scoring always kept. The rest
## exist so `_miss_reason()` can only ever say what these counters actually saw (R9, spec 9.3).
func _new_track() -> Dictionary:
	return {
		"hold": 0.0, "qsum": 0.0, "qtime": 0.0, "best_moment": 0.0,
		"best_line": "", "best_mult": 1.0, "caught": false, "seen": 0.0,
		"win_sec": 0.0,        # seconds it was up, uncaught and INSIDE the glass
		"centred_sec": 0.0,    # ...of those, seconds centred well enough (centred >= Q_FLOOR)
		"sharp_c_max": 0.0,    # the sharpest it ever was while centred like that
		"nofilm_q_sec": 0.0,   # seconds it was takeable (q >= Q_FLOOR) with the magazine empty
		"busy": {},            # other id -> seconds the player was exposing THAT while this was up
		"presses": 0,          # shutter presses that were refused while this was the nearest sight
		"up_wall": 0.0,        # wall seconds it was up at all (R13: the boost compresses this)
	}


## WHAT THE DRAW IS ALLOWED TO KNOW. Four things, and every one of them is real player state:
## the hour (which sights are up), the day (the seed, and `days` gates), how far the story has got
## (rarity 3-4 get slightly likelier per part fitted) and WHICH HINTS THIS PLAYER HAS HEARD - which
## is the only gate on the ten hinted rares. See src/sky/safari_heard.gd for where that set lives.
func _ctx() -> Dictionary:
	return SafariLanes.make_ctx(hour, day, GameState.rocket_parts.size(), SafariHeard.heard_ids())


## The lane this trip is flown on, for its name and its seconds.
func lane() -> Dictionary:
	return SafariLanes.lane_for(from_id, to_id)


## Everything a critic would otherwise have to take on trust, printed from the same data the run
## uses. No separate copy of any number lives in here.
func _print_report() -> void:
	print("--- SAFARI REPORT ---")
	var ln := lane()
	print("lane %s (%s) %s -> %s dir=%s seconds=%.0f pay_band=%d" % [
		str(ln.get("id", "")), str(ln.get("name", "")), from_id, to_id,
		str(ln.get("direction", "")), float(ln.get("seconds", 0.0)), int(ln.get("pay_band", 1))])
	print("ctx hour=%.2f day=%d parts=%d heard=[%s]" % [
		hour, day, GameState.rocket_parts.size(),
		", ".join(PackedStringArray(SafariHeard.heard_ids()))])
	# R5 evidence: el0/el1 are printed now. Without them nobody can tell from a report whether the
	# reachable sky still contains the cast, which is exactly what R5 asks a builder to prove.
	var el_lo := 999.0
	var el_hi := -999.0
	for e in _cast:
		el_lo = minf(el_lo, minf(float(e["el0"]), float(e["el1"])))
		el_hi = maxf(el_hi, maxf(float(e["el0"]), float(e["el1"])))
		print("  %-22s r%d %-10s hold=%.2f  t=%5.1f..%5.1f  az %6.1f..%6.1f  el %6.1f..%6.1f  slot=%s" % [
			str(e["id"]), int(e["rarity"]), str(e.get("journal_kind", "")),
			float(e["hold_sec"]), float(e["t_start"]), float(e["t_end"]),
			float(e["az0"]), float(e["az1"]), float(e["el0"]), float(e["el1"]),
			str(e.get("slot", ""))])
	print("  cast elevation %.1f .. %.1f deg; reachable sky %.1f .. %.1f (R5) -> %s" % [
		el_lo, el_hi, _el_min, _el_max,
		"every sight reachable" if el_lo >= _el_min and el_hi <= _el_max
		else "A SIGHT IS OUT OF REACH"])
	print("  field: lowered +-%.1f deg, raised +-%.1f deg, scope starts %s; scoring bullseye %.2f deg and edge %.2f deg, ABSOLUTE (not a fraction of the field)" % [
		FIELD_LOW_DEG, FIELD_HIGH_DEG, "RAISED" if _scope else "lowered", CENTRE_DEG, EDGE_DEG])
	for ov in SafariCast.overlaps(_cast):
		print("  overlap %s / %s  %.1fs together, %.0f deg apart" % [ov[0], ov[1], ov[2], ov[3]])
	print("film: %d loaded, day box %d of %d left (SafariScoring.FILM_BASE=%d)" % [
		film_start, GameState.film_left_today(), GameState.film_capacity(),
		SafariScoring.FILM_BASE])
	for row in SafariScoring.example_payout_table():
		print("  pay %-8s common %2d  uncommon %2d  rare %2d  hardly-ever %2d" % [
			str(row["shot"]), int(row["common"]), int(row["uncommon"]), int(row["rare"]),
			int(row["hardly_ever"])])
	# THE CABIN is measured on the first PROCESSED frame, not here: at _ready() the window has
	# not been resized yet and this printed 1559x720 for a run whose captures were 2556x1180.
	# THE PILLAR CLEARANCE TABLE IS GONE BECAUSE THE PILLARS ARE. Round 3 deleted every piece of
	# ship that was drawn inside the opening, so there is nothing left to clear a subject of: the
	# heading instrument is engraved on the porthole's collar instead, outside the glass.
	print("  no structure inside the opening: %d drawing children over the glass (the eyepiece)" % [
		_eye_root.get_child_count()])
	print("catch lines <= %d chars: %s  (longest %d); %d hinted sights in the catalog" % [
		SafariHeard.LINE_MAX, str(SafariHeard.lines_ok()), SafariHeard.longest_line(),
		SafariCatalog.hinted_ids().size()])
	for sid in SafariCatalog.hinted_ids():
		var he := SafariCatalog.by_id(sid)
		print("  %-16s %-12s heard=%-5s  \"%s\"" % [
			sid, str(he.get("hint_npc", "")), str(SafariHeard.is_heard(sid)),
			str(he.get("hint_line", ""))])
	# THE CLASH, measured off the paths this run actually drew rather than asserted. The two
	# `clash_a` / `clash_b` entries open in the same instant on opposite sides (SafariLanes), so
	# the number that matters is how late the second catch is - printed here, and by SafariLanes
	# itself from the same formula.
	# F4: ALL THREE CLASHES. This used to read only `clash_a`/`clash_b` and call clash_miss_sec
	# without its `which`, so every flight log printed one clash's arithmetic for a lane that flies
	# three. The slots are clash_a/b, clash2_a/b and clash3_a/b (SafariLanes' segment roles).
	for which in 3:
		var pre: String = "clash" if which == 0 else "clash%d" % (which + 1)
		var a := _clash_entry(pre + "_a")
		var b := _clash_entry(pre + "_b")
		if a.is_empty() or b.is_empty():
			print("  clash %d: not drawn on this run (%s_a/%s_b missing)" % [which + 1, pre, pre])
			continue
		var t0: float = float(a["t_start"])
		var pa: Vector2 = SafariCast.pos_at(a, t0)
		var pb: Vector2 = SafariCast.pos_at(b, t0)
		var sep: float = absf(wrapf(pa.x - pb.x, -180.0, 180.0))
		print("  clash %d %s vs %s at t=%.1f: %.0f deg apart, swing %.2fs at %.0f deg/s, second catch %.2fs late" % [
			which + 1, str(a["id"]), str(b["id"]), t0, sep, sep / SLEW_MAX_DEG, SLEW_MAX_DEG,
			SafariLanes.clash_miss_sec(str(lane().get("id", "")), float(a["hold_sec"]), which)])
	print("--- END REPORT ---")



## The cabin's real geometry, printed once the viewport has settled. Everything in it is read
## back out of _layout_cockpit(), so no number in here is a second copy of anything.
func _print_cabin() -> void:
	# THE CABIN, measured rather than claimed.
	var vs := get_viewport().get_visible_rect().size
	_layout_cockpit()
	var dia: float = _win.size.x
	# vs is in UI units. On the phone run the captured framebuffer is 1.64x this (2556x1180), so the
	# PERCENTAGES below are the numbers to read - and they match the disc measured off the PNG.
	print("porthole ROUND dia=%.0f in %.0fx%.0f UI units = %.0f%% of the height, %.0f%% of the width, %.1f%% of the frame (an uncropped disc cannot beat %.1f%% here)" % [
	dia, vs.x, vs.y, 100.0 * dia / vs.y, 100.0 * dia / vs.x,
	100.0 * PI * dia * dia * 0.25 / maxf(vs.x * vs.y, 1.0),
	100.0 * PI * vs.y * vs.y * 0.25 / maxf(vs.x * vs.y, 1.0)])
	print("aspect=%.2f corner_q=%.2f (1.00 on a square opening IS a circle); field +-%.1f deg on both axes (%s), %.2f deg per porthole pixel" % [
	window_aspect(), CORNER_Q, field_half_deg(), "scope RAISED" if _scope else "lowered",
	2.0 * field_half_deg() / maxf(dia, 1.0)])
	var np: Array = nameplate_span()
	print("subject label x=%.0f..%.0f centre %.0f (screen centre %.0f; it used to be pinned at x=26); knob at %.0f,%.0f r=%.0f; shutter at %.0f,%.0f r=%.0f" % [
	float(np[0]), float(np[0]) + float(np[1]), float(np[0]) + float(np[1]) * 0.5, vs.x * 0.5,
	knob_xf()[0].x, knob_xf()[0].y, knob_xf()[1],
	shutter_xf()[0].x, shutter_xf()[0].y, shutter_xf()[1]])
	# ROUND 2 FIX (critic finding 1, this round). `plate_side` in `_layout_cockpit()` is computed and
	# clamped in Control-local ("UI") units - correctly, that clamp does not need to change - but a
	# report that repeats that UI number AS a device-px count is wrong on any capture where the
	# canvas_items stretch is not 1:1 (2556x1179 --ui=mobile stretches ~1.64x). Same conversion the
	# tap dispatch and the heat report already use below, MEASURED off `DisplayServer.window_get_size()`
	# rather than assumed, so this line cannot go stale the way the deleted "30 UI px = 49 device px"
	# comment did once the grid replaced the single column.
	if _film_row != null and not _film_plates.is_empty():
		var dev_stretch: Vector2 = Vector2(DisplayServer.window_get_size()) / _root.size
		var plate_ui: float = _film_plates[0].custom_minimum_size.x
		print("film plates N=%d cols=%d rows=%d plate=%.0f UI px = %.0f device px (stretch %.2fx across; ceiling 64.0*_uis UI px = %.0f device px at this stretch, floor 14.0*_uis UI px = %.0f device px)" % [
		film_start, _film_row.columns, int(ceil(float(film_start) / maxf(float(_film_row.columns), 1.0))),
		plate_ui, plate_ui * dev_stretch.x, dev_stretch.x,
		64.0 * _uis * dev_stretch.x, 14.0 * _uis * dev_stretch.x])


func _parse_args() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--route="):
			route_id = a.substr(8)
			var bits := route_id.split("_", false)
			if bits.size() == 2:
				from_id = bits[0]
				to_id = bits[1]
		elif a.begins_with("--from="):
			from_id = a.substr(7)
		elif a.begins_with("--to="):
			to_id = a.substr(5)
		elif a.begins_with("--hour="):
			hour = float(a.substr(7))
		elif a.begins_with("--day="):
			day = int(a.substr(6))
		elif a == "--auto":
			auto_pilot = true
		elif a.begins_with("--capture-dir="):
			_cap_dir = a.substr(14)
		elif a.begins_with("--shots="):
			for part in a.substr(8).split(",", false):
				var bits := part.split("@")
				if bits.size() == 2:
					_shots.append({"name": bits[0], "t": float(bits[1]), "done": false})
		elif a.begins_with("--quit-at="):
			_quit_at = float(a.substr(10))
		elif a.begins_with("--skip-at="):
			_skip_at = float(a.substr(10))
		elif a.begins_with("--pose="):
			for part in a.substr(7).split(",", false):
				var bits := part.split(":")
				if bits.size() == 3:
					_poses.append({"t": float(bits[0]), "az": float(bits[1]), "el": float(bits[2])})
		elif a == "--report":
			_report = true
		elif a.begins_with("--fake-sight="):
			# SYNTHETIC, G6 WAVE 2 CHEVRON REGRESSION ONLY - see the var declaration above.
			var fb := a.substr(13).split(":")
			if fb.size() >= 2:
				_fake_sight_az = float(fb[0])
				_fake_sight_el = float(fb[1])
				_fake_sight_on = true
				if fb.size() >= 3:
					_fake_sight_t_start = float(fb[2])
		elif a.begins_with("--fake-sight-seq="):
			# SYNTHETIC, F5 - see the var declaration above.
			for part in a.substr(17).split(",", false):
				var sb := part.split(":")
				if sb.size() == 3:
					_fake_sight_seq.append({"t": float(sb[0]), "az": float(sb[1]), "el": float(sb[2])})
					_fake_sight_on = true
		elif a.begins_with("--heard="):
			# WIRE round. SYNTHETIC CAPTURE HOOK, not a way to hear a hint: it writes ids straight
			# into SafariHeard's set so a frame of a hinted rare can be filmed without driving a
			# conversation first. A real player only ever gets there through
			# SkyHints.maybe_hint_line (see showcase/safari_wire_probe.gd, which does it the long
			# way on purpose).
			for hid in a.substr(8).split(",", false):
				SafariHeard.mark_heard(hid)
		elif a.begins_with("--film="):
			# FILM builder pass (2026-09-21, scratch only). SYNTHETIC test hook, not a real film
			# source: lets `--auto --report` measure "how many sights pass with N plates" for
			# different N without touching the caller. A real flight always gets `film_start` from
			# `safari_flight.gd` (GameState.film_capacity()), never this flag.
			film_start = int(a.substr(7))
		elif a.begins_with("--scope="):
			# SYNTHETIC, captures and measurement. `raised` starts the run with the 7-degree scope
			# up, `lowered` (the default, and what a player gets) with the 56-degree window.
			_scope = a.substr(8) == "raised"
		elif a.begins_with("--el-span="):
			# SYNTHETIC, measurement only. Restores an older elevation clamp so the scoring A/B can
			# isolate the field change from R5's clamp. A real flight never passes this.
			var b := a.substr(10).split(":", false)
			if b.size() == 2:
				_el_min = float(b[0])
				_el_max = float(b[1])
				_el = clampf(_el, _el_min, _el_max)
		elif a == "--no-aurora":
			# SYNTHETIC, A/B only: draws the run with R2's horizon band switched off.
			_aurora = 0.0
		elif a == "--no-rail":
			_rail_off = true
		elif a.begins_with("--tap-scope="):
			# SYNTHETIC, but LESS synthetic than debug_touch: this pushes a real
			# InputEventScreenTouch through Input.parse_input_event at the given run seconds, so it
			# travels the whole gui_input path (_on_eye_input -> _press -> the zone test) exactly as
			# a thumb's event would. It still is not a finger and it proves nothing about the phone's
			# digitiser - but it does prove the scope's hit zone is reachable and does not get eaten
			# by the knob or by the aim drag.
			for part in a.substr(12).split(",", false):
				var bt := part.split("@")
				if bt.size() == 2:
					_scope_taps.append({"what": bt[0], "t": float(bt[1]), "rep": false})
				else:
					_scope_taps.append({"what": "scope", "t": float(part), "rep": false})
		elif a == "--tap-trace":
			_tap_trace = true
		elif a.begins_with("--heat-copies="):
			_heat_copies = clampi(int(a.substr(14)), 0, 32)
		elif a == "--heat":
			# SYNTHETIC, measurement only. Turns on the viewport's own GPU render-time measurement
			# and prints the distribution at the end of the run. It is the honest way to A/B this
			# shader: the numbers are not capped by vsync or by --fixed-fps the way a frame counter
			# is, and the same block is pasted into the before-snapshot so the two arms are measured
			# by identical code. It is a desktop M5 on Compatibility, not a phone.
			_heat = true
		elif a.begins_with("--policy="):
			# SYNTHETIC. `tap` or `tap-blind` - see `_policy_step()`.
			_policy = a.substr(9)
		elif a.begins_with("--pol-tap-deg="):
			_pol_tap_deg = float(a.substr(14))
		elif a.begins_with("--pol-aim-err="):
			_pol_aim_err = float(a.substr(14))
		elif a.begins_with("--pol-react="):
			_pol_react = float(a.substr(12))
		elif a == "--pol-direct":
			# SYNTHETIC: the policy calls `_press()` directly instead of sending an InputEvent.
			_pol_real_input = false
		elif a.begins_with("--boost-at="):
			# SYNTHETIC: toggle the boost at these run seconds, e.g. `--boost-at=0` boosts the whole run.
			for part in a.substr(11).split(",", false):
				_boost_ats.append({"t": float(part), "done": false})
		elif a.begins_with("--hold-shutter="):
			# SYNTHETIC: `T0:T1,...` - a real InputEventScreenTouch PRESS on the shutter at run second
			# T0 and its RELEASE at T1, through Input.parse_input_event (see `_do_holds`).
			for part in a.substr(15).split(",", false):
				var hb := part.split(":")
				if hb.size() == 2:
					_holds.append({"t0": float(hb[0]), "t1": float(hb[1]), "st": 0})
		elif a == "--catalog-probe":
			# SYNTHETIC: R9 item 4, the no-knob table over all 51 catalog sights. See the function.
			_catalog_probe = true
		elif a.begins_with("--probe-win="):
			_probe_win = float(a.substr(12))
		elif a == "--swim-legacy":
			# SYNTHETIC, R12 A/B ONLY: writes the wave-2 `swim = 1 - best_q` so a before/after pair
			# differs in nothing but the wobble. A real flight never passes it.
			_swim_legacy = true
		elif a == "--tutorial":
			# SYNTHETIC: a showcase run is not a real flight, so it gets the tutorial only on request.
			# The GameState flag still wins: a run whose flag is set shows nothing either way.
			_tut_force = true
		elif a == "--no-tutorial":
			_tut_block = true
		elif a == "--pol-skip-tut":
			_pol_skip_tut = true
		elif a.begins_with("--ask="):
			# SYNTHETIC: opens an ask exactly as the story does (PhotoAsks.add), BEFORE the cast is
			# drawn, so the draw's guarantee and this file's marker see it the way a real flight would.
			# `--ask=lantern_fish:professor:hub` is the Professor's own (intro_director.gd:643).
			var ab := a.substr(6).split(":")
			if ab.size() >= 1 and ab[0] != "":
				PhotoAsks.add(ab[0], {"by": ab[1] if ab.size() > 1 else "professor", "lane": "",
					"from": "", "to": ab[2] if ab.size() > 2 else "", "hours": [0, 24],
					"one_way": ab.size() > 2})
		elif a == "--no-marks":
			# SYNTHETIC, A/B only: the same frame with R1's marks suppressed, so a difference image
			# gives the mark's exact contribution instead of a reading contaminated by whatever star
			# happens to sit beside it.
			_marks_off = true
	if _cap_dir != "":
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_cap_dir))


# ================================================================== the world outside the glass
func _build_3d() -> void:
	# ROUND 2 (space builder): the lane. See src/sky/space_lane.gd for what is in it and why.
	_lane = SpaceLane.new()
	_lane.name = "Lane"
	add_child(_lane)
	_lane.setup(from_id, to_id, _run_seconds, PAD_SEC)

	_cam = Camera3D.new()
	_cam.name = "Eye"
	_cam.fov = 70.0
	_cam.far = 4000.0
	_cam.current = true
	add_child(_cam)

	# --- NO 3D CANOPY ANY MORE. The spike had a bubble canopy of hoops and ribs out here; it is
	# gone because the cabin is now drawn in 2D over the whole screen (src/sky/safari_cockpit.gd)
	# and the hoops were either hidden behind that panel or, during the pad drop, two tan bars
	# across the window that read as landing legs. The ship you are sitting in is the panel.

	# --- THE NAKED-EYE SMUDGES ARE GONE (safari6, 2026-09-21). This built one additive billboard per
	# sight at 300 m and repositioned all of them every frame. NOBODY HAS EVER SEEN ONE. During a run
	# this scene's CanvasLayer (layer 40) holds an opaque shader disc plus an opaque 2D hull that
	# together cover the whole screen, so nothing 3D is on screen at all between the pad drop and the
	# haul card - and the quads were `visible = false` for the whole pad drop, because `is_up` is
	# false while `_t` is negative. It is the fourth invisible feature found on this project
	# (docs/SAFARI_FLIGHT_SPEC.md 6.1); the far marks that replace it are drawn in the eyepiece
	# shader, where the player can actually see them.


func _dir_of(az_deg: float, el_deg: float) -> Vector3:
	var a := deg_to_rad(az_deg)
	var b := deg_to_rad(el_deg)
	return Vector3(sin(a) * cos(b), sin(b), -cos(a) * cos(b))


func _update_3d(delta: float) -> void:
	# THE PAD DROP. The scope is aimed down at the pad and comes level exactly as the glass opens.
	if _phase == Ph.PAD:
		var pu: float = clampf((_t + PAD_SEC) / PAD_SEC, 0.0, 1.0)
		_az = 0.0
		# R5: the drop starts at the bottom of the reachable sky, not 12 degrees below it. It used
		# to begin at -40, which the clamp no longer allows, so the cinematic and the controls would
		# have disagreed about where "down" ends on the very first second of the flight.
		_el = lerp(_el_min, 4.0, pu * pu * (3.0 - 2.0 * pu))
	_cam.rotation = Vector3(deg_to_rad(_el), deg_to_rad(-_az), 0.0)
	_lane.advance(_t, delta)


# ================================================================== the glass
func _build_ui() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 40
	add_child(_layer)

	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = UIStyle.theme()
	_layer.add_child(_root)

	_eye_root = Control.new()
	_eye_root.name = "Glass"
	_eye_root.visible = false
	_eye_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_eye_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_eye_root.gui_input.connect(_on_eye_input)
	_root.add_child(_eye_root)

	_eye = ColorRect.new()
	_eye.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_eye_mat = ShaderMaterial.new()
	_eye_mat.shader = EYE_SHADER
	_eye.material = _eye_mat
	_eye_root.add_child(_eye)

	# SYNTHETIC, `--heat-copies=N`, MEASUREMENT ONLY. N extra copies of the SAME ColorRect with the
	# SAME material, stacked on the porthole, so every one of them rasterises the shipped shader
	# with the shipped uniforms - the real field, the real marks, the real rail, the real band.
	# The whole-frame A/B cannot separate this shader from the rest of the frame (the spread of the
	# frame interval is larger than the effect); a straight line fitted through N = 0, 2, 4, 8 can,
	# and its SLOPE is the cost of one porthole-sized copy. That is the number the heat budget is
	# about, and the round-1 bench got it from a 7-degree field with the marks and the rail at their
	# uniform defaults, which is not what ships.
	for i in _heat_copies:
		var cp := ColorRect.new()
		cp.name = "HeatCopy%d" % i
		cp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cp.material = _eye_mat
		_eye_root.add_child(cp)
		_heat_rects.append(cp)

	# NOTHING IS DRAWN INSIDE THE OPENING ANY MORE. There used to be a clipped `SafariCockpit.Frame`
	# here - pillars, a roof lip and the ship's nose - and the user wrote in about exactly the shape
	# it made: a rectangle inside the round window. It is gone, node and class, so the only node that
	# can paint a pixel inside the disc is the eyepiece itself.

	_cockpit = SafariCockpit.new()
	_cockpit.run = self
	_cockpit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cockpit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_cockpit)

	# FILM builder pass. THE PLATES SIT ON TOP OF THE HULL, NOT UNDER IT. The last review caught
	# this exactly: `_cockpit` is a full-rect `_draw()` (the hull, the aperture, the console lamp)
	# and it used to be added to `_root` AFTER the film row - so every frame painted straight over
	# the plates and the "out of film" toast. Building them here, once `_cockpit` already has its
	# place in the tree, is the whole fix: later siblings draw on top in Godot, so the plates are
	# now always the last thing painted over the cabin and can never be hidden behind it again.
	_build_film_row()

	# THE SCOPE CONTROL MUST NEVER BE INVISIBLE (safari6). This file owns where the scope switch is
	# and what it does; G2 owns what it looks like and what it is labelled. If the two land out of
	# step, the result is a control with a live hit zone and nothing on screen - which is the fourth
	# kind of bug this round exists to delete, not a fifth one to add. So this draws a plain ring at
	# scope_xf(), and it switches itself OFF the moment safari_cockpit.gd grows a `draws_scope()`
	# that returns true. That handshake is one line in G2's file and this node then never paints.
	_scope_fb = ScopeFallback.new()
	_scope_fb.run = self
	_scope_fb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_scope_fb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_scope_fb)

	_skip = Button.new()
	_skip.text = "Skip"
	_skip.add_theme_font_override("font", UIStyle.ui_font())
	_skip.add_theme_font_size_override("font_size", 17)
	_skip.pressed.connect(_on_skip)
	_root.add_child(_skip)

	# R13, THE FIFTH CONTROL (spec 10.3 raises the ceiling from four to five; no sixth). A toggle
	# in the top-right corner, the mirror of Skip: both are "I am done with this lane" controls and
	# neither belongs under a thumb that is aiming or shooting. Its one word is its own label.
	_boost_btn = Button.new()
	_boost_btn.text = "boost"
	_boost_btn.focus_mode = Control.FOCUS_NONE
	_boost_btn.add_theme_font_override("font", UIStyle.ui_font())
	_boost_btn.add_theme_font_size_override("font_size", 17)
	_boost_btn.pressed.connect(func() -> void: set_boost(not _boost))
	# not live (BOOST_LIVE): the button still exists and is laid out, because the cabin clock
	# (safari_cockpit.gd `_flight_clock`) sits beside `boost_rect()`; it is just not shown or pressable.
	_boost_btn.visible = BOOST_LIVE
	_boost_btn.disabled = not BOOST_LIVE
	if not BOOST_LIVE:
		_boost_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_boost_btn)

	_card = PanelContainer.new()
	_card.visible = false
	_card.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_card.grow_vertical = Control.GROW_DIRECTION_BOTH
	_card.add_theme_stylebox_override("panel", UIStyle.make_panel_style(C_CREAM, 26))
	_root.add_child(_card)
	_layout_cockpit()


## "shown as something physical on the panel, not a counter" (point 3). A little stack of plates
## in a slot cut into the RIGHT hull column - the same warm hull the shutter sits in, not a HUD
## bolted over the sky. Cream and proud while loaded, dark and sunk once shot, read left-to-right,
## top-to-bottom. (FILM built it in the LEFT column; the merge moved it right, because GLASS put
## the nameplate where it was. `_layout_cockpit()` has the measurement and the reasoning.)
##
## GRID ROUND (SAFARI_FLIGHT_SPEC.md 7.3, G6 wave 2). A single VBoxContainer column read 49x29
## device px per plate on a real 2556x1179 --ui=mobile Compatibility capture at the OLD film count
## of 5 - "too small to read" even then, per the spec that opened this round - and film is going to
## 10 base, 14 bought, 16 upgraded. A column of 16 at that size is 622 device px tall: it ran past
## the side port at the top of the column AND collided with the "scope"/"shutter" legend at the
## bottom (`film16.png` in the report - the plate stack draws over half of "shutter"). MEASURED,
## not guessed: a taller column cannot fix this, because the column's own height budget (the gap
## between the side port and the legend) does not grow with the plate count.
##
## So this is a GridContainer, not a VBoxContainer, and its `columns` is picked fresh every layout
## pass by `_best_plate_grid()` below: whichever column count makes a SQUARE plate as large as
## possible for THIS COUNT inside the ACTUAL available rectangle (between the port and the legend,
## the same rectangle the old column was already computed against). No fitted size: a 2-plate run
## gets one big square, a 16-plate run gets a dense grid, and both come out of the same formula.
func _build_film_row() -> void:
	_film_row = GridContainer.new()
	_film_row.name = "FilmRow"
	_film_row.add_theme_constant_override("h_separation", 6)
	_film_row.add_theme_constant_override("v_separation", 6)
	# ROUND 2, BLOCKING FIX (critic finding 1), STILL TRUE OF THE GRID. The plates are drawn on top
	# of the hull (see the comment above), which means they also SIT on top of `_eye_root` in tree
	# order - and Godot's GUI dispatch offers input to the topmost Control first. A PanelContainer's
	# default mouse_filter is STOP, so every plate was silently eating the drag before `_eye_root`'s
	# `_on_eye_input` ever saw it: a `crit_drag_probe` run of real InputEventScreenTouch/Drag
	# through the viewport measured +7.265 deg on the glass and beside the stack, 0.000 ON it.
	# `_press()` itself documents the plate's column as part of the swing's aim region ("the glass
	# AND the hull either side of it"), so the plates must never be able to claim a touch - IGNORE
	# on the row and on every plate lets the same press fall through to `_eye_root` beneath.
	_film_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_film_row)
	for i in film_start:
		var plate := PanelContainer.new()
		plate.custom_minimum_size = Vector2(22.0, 22.0)
		plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_film_row.add_child(plate)
		_film_plates.append(plate)
	_film_out_toast = _lbl("out of film", 14, C_CREAM)
	_film_out_toast.add_theme_color_override("font_outline_color", C_NAVY)
	_film_out_toast.add_theme_constant_override("outline_size", 6)
	_film_out_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_film_out_toast.visible = false
	_root.add_child(_film_out_toast)
	_update_film_row()


func _update_film_row() -> void:
	# Radius and border scale with the plate itself (read back off the live node, not recomputed -
	# `_layout_cockpit()` is the one place that sets the real size) so a 60-device-px plate at a
	# low count does not carry the same hairline border a 30-px plate at 16 needed.
	var side: float = 22.0
	if not _film_plates.is_empty():
		side = _film_plates[0].custom_minimum_size.x
	var rad: int = clampi(roundi(side * 0.16), 3, 11)
	var bw_on: int = clampi(roundi(side * 0.065), 2, 4)
	var bw_off: int = clampi(roundi(side * 0.035), 1, 2)
	for i in _film_plates.size():
		var used: bool = i >= _film_left
		var plate := _film_plates[i]
		if used:
			plate.add_theme_stylebox_override("panel",
				UIStyle.make_panel_style(Color(C_NAVY, 0.35), rad, C_SOFT, bw_off, 0, 0.0))
		else:
			plate.add_theme_stylebox_override("panel",
				UIStyle.make_panel_style(C_CREAM, rad, C_AMBER, bw_on, 0, 0.0))
	if _film_out_toast != null:
		_film_out_toast.visible = _film_left <= 0 and _phase == Ph.RUN


## THE GRID SEARCH ITSELF. `n` plates, an `avail_w` x `avail_h` rectangle, a `gap` between cells.
## Tries every column count from 1 to `n` and keeps whichever gives the largest SQUARE plate that
## still fits `ceil(n/cols)` rows in `avail_h` and `cols` columns in `avail_w` - an exhaustive search
## over a range too small to matter (at most 16 iterations), so there is no local optimum to worry
## about. This is the one piece of geometry that has to work for every count from 1 to 16
## (SAFARI_FLIGHT_SPEC.md 7.3): it never special-cases a count, it just re-solves the same rectangle
## each time.
static func _best_plate_grid(n: int, avail_w: float, avail_h: float, gap: float) -> Dictionary:
	var count: int = maxi(n, 1)
	var best_size := 0.0
	var best_cols := count
	var best_rows := 1
	for cols in range(1, count + 1):
		var rows: int = int(ceil(float(count) / float(cols)))
		var w: float = (avail_w - gap * float(cols - 1)) / float(cols)
		var h: float = (avail_h - gap * float(rows - 1)) / float(rows)
		var s: float = minf(w, h)
		if s > best_size:
			best_size = s
			best_cols = cols
			best_rows = rows
	return {"cols": best_cols, "rows": best_rows, "size": maxf(best_size, 0.0)}


## THE CABIN, laid out. Everything else in the file asks this for its rectangle, so there is one
## copy of the geometry and a phone and a desktop differ only in the numbers that come out.
func _layout_cockpit() -> void:
	var vs := _root.size
	if vs.x < 4.0 or vs.y < 4.0:
		return
	var rail_h: float = maxf(vs.y * RAIL_F, 26.0)
	var con_h: float = maxf(vs.y * CONSOLE_F, 16.0)
	# THE PORTHOLE. As big a disc as fits between the rail and the console, centred across.
	var d: float = maxf(minf(vs.y - rail_h - con_h, vs.x * PORT_MAX_W), 120.0)
	var cx: float = vs.x * 0.5
	var cy: float = rail_h + (vs.y - rail_h - con_h) * 0.5
	# 13.5: THE COLLAR DAB, DEAD AHEAD OR DEAD ASTERN. Centring the disc with only rail_h/con_h
	# between it and the screen edges left a dab's own reach (`COLLAR_DAB_REACH_FRAC` above) 9 of the
	# needed 34 device px clear of the bottom on a real 2556x1179 --ui=mobile frame - under the home
	# indicator (MEASURED, this round's report: the glass edge itself just fit the safe line, 699.04
	# of 699.24 UI px; the ring beyond it did not, because rail_h/con_h alone left only ~1 UI px of
	# the ~19.6 a full-size dab needs, top or bottom). FIX: an exact inversion, not a fitted number -
	# the largest disc whose worst-case DAB reach clears BOTH the top of the frame and the real
	# bottom safe-area inset (`MobileUI.safe_area()`, zero on desktop), centred exactly between those
	# two now-equal limits. `MobileUI` is a global script class (`class_name`), reachable from any
	# file, no import needed. The S3 ping and the elevation chevron reach further still at THEIR own
	# extremes; rather than size the whole porthole for either (a much bigger shrink for a case that
	# is not "a dab"), each shrinks ITSELF to whatever room this leaves - see `_rose()`'s ping loop
	# and `_elev_tag()` in safari_cockpit.gd.
	var safe_bottom: float = MobileUI.safe_area().w
	var reach_frac: float = COLLAR_RW_FRAC * COLLAR_DAB_REACH_FRAC
	var budget: float = vs.y - COLLAR_EDGE_CUSHION * 2.0 - safe_bottom
	var rad_cap: float = budget / (2.0 * (1.0 + reach_frac))
	if rad_cap < d * 0.5:
		d = maxf(rad_cap * 2.0, 120.0)
		cy = COLLAR_EDGE_CUSHION + d * 0.5 * (1.0 + reach_frac)
	_win = Rect2(cx - d * 0.5, cy - d * 0.5, d, d)
	_rail = Rect2(0.0, 0.0, vs.x, _win.position.y)
	_con = Rect2(0.0, _win.end.y, vs.x, maxf(vs.y - _win.end.y, 12.0))
	# Text scales with the SCREEN, not with the console: the phone frame is 1.6x the desktop one
	# and the old console-height rule shrank the phone's nameplate to 0.93x instead.
	_uis = clampf(vs.y / 720.0, 0.85, 1.85)
	_eye.position = _win.position
	_eye.size = _win.size
	for cp in _heat_rects:
		cp.position = _win.position
		cp.size = _win.size
	_skip.position = Vector2(vs.x * 0.012, _rail.size.y * 0.20)
	_skip.size = Vector2(maxf(vs.x * 0.062, 62.0), maxf(_rail.size.y * 0.58, 30.0))
	_skip.custom_minimum_size = _skip.size
	if _boost_btn != null:
		# the mirror of Skip across the screen's centre line
		_boost_btn.size = _skip.size
		_boost_btn.custom_minimum_size = _skip.size
		_boost_btn.position = Vector2(vs.x - _skip.position.x - _skip.size.x, _skip.position.y)
		_boost_btn.add_theme_font_size_override("font_size", roundi(17.0 * _uis))

	# FILM builder pass, MOVED TO THE RIGHT COLUMN BY THE MERGE (2026-09-21). Read this before
	# touching the numbers, because two builders wrote this area against different layouts.
	#
	# FILM built the stack in the LEFT column at `_win.position.x * 0.5`, which was free in the base
	# it branched from (the subject label was centred in a 171 px console down at the bottom). GLASS
	# deleted that console and moved the nameplate INTO the left column at the same x - a plate
	# `_win.position.x * 0.86` wide spanning `win.y + win.h * 0.335 - 26*k` to `+76*k`
	# (safari_cockpit.gd::_nameplate). MEASURED on the merged 2556x1179 frame before this change, the
	# two overlapped by ~75 UI px and the "out of film" toast landed inside the nameplate.
	#
	# The stack moved rather than the nameplate because GLASS's own `nameplate_span()` comment
	# reserves the other side for exactly this ("The right panel is left clear on purpose: it is
	# where the film magazine goes"). So: same band logic FILM wrote, mirrored in x about the screen
	# centre, sharing the right column with the shutter the way the left one shares with the knob.
	#
	# WHY NOT AT THE TOP OF THE COLUMN: `safari_cockpit.gd::_hull()` puts a decorative "side port"
	# there, on the SAME x in both columns. FILM replicated its two numbers as 0.20 and 0.115; GLASS
	# moved the port in the same round, to `win.position.y + win.size.y * 0.150` and radius
	# `max(col * 0.105, 16)`, so the copies below are updated to GLASS's values - stale ones put the
	# stack 33 UI px lower than it needs to be. COORDINATE WITH THE GLASS BUILDER: if `_hull()`'s
	# `0.150` or `0.105` change, or the port moves, this band needs the same numbers again.
	#
	# GRID ROUND (SAFARI_FLIGHT_SPEC.md 7.3). The old single column ran the plate CAP at 30 UI px =
	# 49 device px whatever the band's real height was, because a column's height grows with its
	# item count and nothing here ever measured against the legend below it. Both are fixed now: the
	# BOTTOM of the band is `_cockpit.legend_clear_y()`, the exact top of the "scope"/"shutter" text
	# stack (not a second copy of its geometry - see that function), and `_best_plate_grid()` above
	# picks whatever column count makes THIS COUNT's plates as large as the resulting rectangle
	# allows, so the band's real height is what actually bounds the plate size, not a flat 30 px cap.
	if _film_row != null:
		var col_w: float = maxf(_win.position.x, 1.0)
		var port_bottom: float = _win.position.y + _win.size.y * 0.150 + maxf(col_w * 0.105, 16.0) * 1.2
		var band_top: float = port_bottom + 10.0 * _uis
		# The shutter sits at the same height on the right as the knob does on the left, so this
		# clearance is the same number on either side - only the x below is mirrored. Capped by
		# whichever is tighter, the shutter housing itself or the "scope"/"shutter" legend stacked
		# above it (`_legend()` draws those OVER the housing's own 1.35x clearance near the top of
		# the count range - see the report for the measured before/after).
		var ctrl_top: float = _ctrl_y() - _ctrl_r() * 1.35
		if _cockpit != null:
			ctrl_top = minf(ctrl_top, _cockpit.legend_clear_y(shutter_xf()) - 6.0 * _uis)
		var avail_w: float = clampf(col_w * 0.80, 60.0 * _uis, col_w)
		var avail_h: float = maxf(ctrl_top - band_top, 0.0)
		var gap: float = 6.0 * _uis
		var grid: Dictionary = _best_plate_grid(film_start, avail_w, avail_h, gap)
		# A floor so a pathological (near-zero) band still gives a plate someone could tap, not a
		# 0x0 rect; a ceiling so a 1- or 2-plate run does not paint a plate the size of the column.
		var plate_side: float = clampf(float(grid["size"]), 14.0 * _uis, 64.0 * _uis)
		_film_row.columns = int(grid["cols"])
		# The theme constant is the gap Godot ACTUALLY renders between cells - kept equal to the
		# `gap` the grid search above was solved against, so a non-1.0 `_uis` (a desktop capture)
		# cannot make the real layout diverge from the rectangle the search thought it was filling.
		var gap_i: int = roundi(gap)
		_film_row.add_theme_constant_override("h_separation", gap_i)
		_film_row.add_theme_constant_override("v_separation", gap_i)
		for p in _film_plates:
			p.custom_minimum_size = Vector2(plate_side, plate_side)
		if _film_out_toast != null:
			_film_out_toast.add_theme_font_size_override("font_size", roundi(22.0 * _uis))
		# Only rebuild every plate's StyleBoxFlat when the size actually moved (a resize or a film
		# count change) - `_layout_cockpit()` runs every `_process()` frame, and the grid search
		# above returns the same size on every one of those frames that nothing changed.
		if not is_equal_approx(plate_side, _film_plate_side):
			_film_plate_side = plate_side
			_update_film_row()
		var cols: int = maxi(int(grid["cols"]), 1)
		var rows: int = maxi(int(grid["rows"]), 1)
		var grid_w: float = float(cols) * plate_side + float(cols - 1) * gap
		var grid_h: float = float(rows) * plate_side + float(rows - 1) * gap
		# RIGHT column: mirror of `_side_col_x()`, the same x `shutter_xf()` uses. Centred on that
		# axis rather than left-aligned like the old single column, because a grid can be narrower
		# than the column it sits in and a left-pinned grid would read as stuck to the porthole.
		var stack_cx: float = vs.x - _win.position.x * 0.5
		_film_row.position = Vector2(stack_cx - grid_w * 0.5, band_top)
		# ON the grid, not under it. Under it is the "scope" legend word: the grid is solved to end
		# 6 px above `legend_clear_y()`, so a toast hung below it printed straight over "scope" on
		# the 2556x1179 phone frame (G7 wave 3, t152.png). When the toast shows, every plate is
		# spent and dark, so the words sit on the plates they are about.
		_film_out_toast.reset_size()
		var tsz: Vector2 = _film_out_toast.get_combined_minimum_size()
		_film_out_toast.position = Vector2(stack_cx - tsz.x * 0.5,
			band_top + grid_h * 0.5 - tsz.y * 0.5)


# ---------------------------------------------------------------- geometry the cabin reads
func window_rect() -> Rect2:
	return _win


func rail_rect() -> Rect2:
	return _rail


func console_rect() -> Rect2:
	return _con


func ui_scale() -> float:
	return _uis


func window_aspect() -> float:
	return _win.size.x / maxf(_win.size.y, 1.0)


func window_corner_px() -> float:
	return CORNER_Q * _win.size.y * 0.5


## The ribbon runs nearly the full rail now, not just the porthole's width: it maps 360 degrees, so
## every pixel of it is a degree you can tell apart.
func ribbon_rect() -> Rect2:
	var vs := _root.size
	var rh: float = clampf(_rail.size.y * 0.46, 20.0, 52.0)
	var x0: float = vs.x * 0.105
	return Rect2(x0, _rail.size.y * 0.52 - rh * 0.5, vs.x - x0 * 2.0, rh)


## THE TWO CHUNKY CONTROLS LIVE IN THE SIDE PANELS. The round porthole leaves a tall column of hull
## on each side - on the phone frame each column is 812 px wide - which is exactly where a thumb
## already is when you hold the phone in two hands. The old pass had them in the strip under the
## window, where the disc left them 51 px of radius; here they get twice that.
func _side_col_x() -> float:
	return _win.position.x * 0.5


func _ctrl_y() -> float:
	return _root.size.y * 0.655


func _ctrl_r() -> float:
	return clampf(_root.size.y * 0.086, 42.0, 112.0)


## Left thumb. A dial sunk in the panel, the warm one carried over from the brass spyglass.
func knob_xf() -> Array:
	return [Vector2(_side_col_x(), _ctrl_y()), _ctrl_r() * 0.92]


## Right thumb. The big one.
func shutter_xf() -> Array:
	return [Vector2(_root.size.x - _side_col_x(), _ctrl_y()), _ctrl_r()]


## WHERE THE SUBJECT LABEL LIVES. [x, width]. It was on the far left edge, then centred in the
## console; the console is 21 px tall now, so it is a plate on the LEFT PANEL, centred over the
## range knob. That is still "next to a thumb and inside one glance of the glass" - the thing the
## far-left version got wrong was being nowhere near either hand, not being off centre. The right
## panel is left clear on purpose: it is where the film magazine goes.
func nameplate_span() -> Array:
	var w: float = _win.position.x * 0.86
	return [_win.position.x * 0.5 - w * 0.5, w]


# ---------------------------------------------------------------- state the cabin reads
## THE HALF-FIELD THE GLASS IS SHOWING RIGHT NOW, in degrees: 28.0 lowered, 7.0 raised. This is the
## number the cabin needs for anything that maps sky to screen - the collar's heading scale, the
## pitch scale, a dab's position on the ring. It is not a constant any more and it must not be
## cached across frames.
func field_half_deg() -> float:
	return FIELD_HIGH_DEG if _scope else FIELD_LOW_DEG


## True when the player has the scope up: the 7-degree glass, for the shot.
func scope_raised() -> bool:
	return _scope


## The scope control, [centre, radius], in the same shape as knob_xf()/shutter_xf(). G2 owns what
## is drawn here and what it is labelled; this file owns where it is, how big it is, and what it
## does.
##
## IT MOVED IN ROUND 2, OUT OF THE LEFT COLUMN AND UNDER THE SHUTTER, AND THE REASON IS A NUMBER.
## Round 1 put it between the subject nameplate and the range knob, the only gap the left column
## has: 331 to 400 UI px, 69 px tall, which caps the control at a 34 px radius. On the real
## 2556x1179 --ui=mobile frame the UI lays out at 1559x720, so one UI pixel is 1.64 device pixels
## and a 3x iPhone point is 3 device pixels - a 28 px radius is a 91 device-px disc, 30 dp. The
## cabin's own critic measured it against QUALITY_BAR's ~48 dp minimum and against its neighbours
## (the knob draws 187 device px across, the shutter 203) and called it what it is: the one new
## control a first-time player has to find in order to aim was the smallest thing in the room.
## Nothing in that gap could have fixed it - 69 UI px is 42 dp even if the control fills it edge to
## edge.
##
## WHERE THERE IS ROOM, measured off the same frame: the right column below the shutter is empty
## from the shutter's recess (_ctrl_y() + 1.37 * _ctrl_r(), safari_cockpit._shutter draws its
## shadow there) down to the console lip at win.end.y - 143 UI px on both the phone frame and the
## 1280x720 desktop one, because the porthole is height-limited on both. The left column's matching
## band is taken by the clock pill (safari_flight._build_clock_pill).
##
## SO: radius 0.80 * _ctrl_r() = 50 UI px = 162 device px across = 54 dp drawn, sitting 13 UI px
## under the shutter's recess and 35 px clear of the lip. It is deliberately smaller than the
## shutter (0.80 against 1.00) because it is not the button you press to take the picture, and
## deliberately bigger than 48 dp so that rounding on a different phone cannot put it under.
##
## AND THE HIT ZONE IS NOW THE SAME DISC. `_press` used to widen this by 1.45 - so the returned
## radius, the thing a critic measures and the thing G2 draws, was not the thing you could tap. It
## is 1.20 now, the same kind of small courtesy margin the knob and the shutter get, and the drawn
## ring is the control.
##
## The pairing is on purpose too: raise the scope, then press the shutter, both under the right
## thumb, with focus under the left.
##
## *** G2, READ THIS: THE SCOPE MOVED COLUMNS. *** It was in the LEFT column under the nameplate in
## round 1 and it is in the RIGHT column under the shutter now. If you are drawing it or labelling
## it, `scope_xf()` is still the only thing to ask; this file draws a labelled fallback until
## `draws_scope()` returns true, and then stops for good.
func scope_xf() -> Array:
	var r: float = _ctrl_r() * 0.80
	# CENTRED IN THE BAND THE SHUTTER LEAVES: from the bottom of its drawn recess
	# (safari_cockpit._shutter draws its shadow at 1.30 r, offset 0.07 r) to the console lip. That
	# band measures 142 UI px on the 2556x1179 phone frame and on the 1280x720 desktop one, so a
	# 99 px disc sits with 22 px clear above and below. If G2 moves the shutter's recess, the 1.37
	# moves with it.
	var top: float = _ctrl_y() + _ctrl_r() * 1.37
	var cy: float = clampf((top + _con.position.y) * 0.5, top + r, maxf(_con.position.y - r, top + r))
	return [Vector2(_root.size.x - _side_col_x(), cy), r]


## Raise or lower the scope. One control of five in the cabin: swing, scope, focus, shutter and
## (R13, spec 10.3) boost.
func set_scope(raised: bool) -> void:
	_scope = raised


## THE HANDSHAKE WITH G2. True once safari_cockpit.gd declares `func draws_scope() -> bool: return
## true`, at which point this file stops drawing its plain fallback ring and the cabin owns the
## control's whole appearance. Until then the switch is visible, because a live hit zone with
## nothing on screen is exactly the bug this round is here to delete.
func cockpit_draws_scope() -> bool:
	return _cockpit != null and _cockpit.has_method("draws_scope") \
		and bool(_cockpit.call("draws_scope"))


func az_deg() -> float:
	return _az


func el_deg() -> float:
	return _el


func focus_value() -> float:
	return _focus


func run_time() -> float:
	return _t


func flash_value() -> float:
	return _flash


func shutter_press() -> float:
	return _press_t


func lead_hold() -> float:
	return _lead_hold


func cast_list() -> Array:
	return _cast


func route_name_id() -> String:
	return route_id


func is_caught(id: String) -> bool:
	return bool(_track.get(id, {}).get("caught", false))


func hud_live() -> bool:
	return _phase != Ph.HAUL


func ff_count() -> int:
	return FF_COUNT


func ff_seed(i: int) -> float:
	return _ff_seed[i] if i < _ff_seed.size() else float(i)


func ff_settle(i: int) -> float:
	return _ff_settle[i] if i < _ff_settle.size() else 0.0


## WHAT IS IN THE GLASS, in words, for the nameplate in the middle of the console. Same rule the
## old far-left label had: name the nearest live thing, and if the glass is empty name the nearest
## thing that is still out there and say which way it is. Only the place it is drawn changed.
func glass_info() -> Dictionary:
	if _phase == Ph.PAD:
		return {"title": "leaving the pad", "sub": "", "dim": true, "got": false}
	# JUST CAUGHT. For a second and a half after the shutter closes the nameplate holds what you got
	# and the moment you got it on. Without this the label jumped straight to the next thing in the
	# sky the instant you succeeded - the capture sheet caught it naming a subject behind you while
	# the pod you had just landed was still filling the glass.
	# R9: a refused press answers HERE, in words, the moment it happens - on WALL seconds, so a
	# boosted lane clock cannot cut the sentence short.
	if _shot.is_empty() and not _note.is_empty() and _wall - float(_note["wall"]) < CATCH_HOLD_SEC:
		return {"title": str(_note["title"]), "sub": str(_note["sub"]),
			"dim": false, "got": false, "note": true}
	if not _last_catch.is_empty() and (not _shot.is_empty()
			or _t - float(_last_catch["t"]) < CATCH_HOLD_SEC * (BOOST_X if _boost else 1.0)):
		return {"title": str(_last_catch["title"]), "sub": str(_last_catch["sub"]),
			"dim": false, "got": true}
	var title := ""
	var sub := ""
	var lead := -1.0
	var named := ""
	for l in _live:
		var e: Dictionary = l["e"]
		if bool(_track[str(e["id"])]["caught"]):
			continue
		var d: float = float(l["f"].length())
		if lead < 0.0 or d < lead:
			lead = d
			title = str(e["title"])
			named = str(e["id"])
			var mm := SafariCast.moment_at(e, _t)
			# WIRE: the words are the catalog's - its own kind vocabulary (creature / weather /
			# moon / wreck / ...) and its FOUR rarity rungs. SafariCast.rarity_name clamps at 3 and
			# would have called every "Hardly ever" sight in the game a plain Rare.
			sub = str(mm["line"]) if not mm.is_empty() else "%s  ·  %s" % [
				SafariCatalog.kind_name(str(e.get("journal_kind", ""))),
				SafariCatalog.rarity_name(int(e["rarity"]))]
	if title != "":
		# THE ASK IN THE GLASS: the nameplate says who wants it (safari_cockpit.gd `_nameplate`)
		return {"title": title, "sub": sub, "dim": false, "got": false, "ask": ask_label(named)}
	var near := 1e9
	for e2 in _cast:
		if not SafariCast.is_up(e2, _t):
			continue
		if bool(_track[str(e2["id"])]["caught"]):
			continue
		var f2: Vector2 = field_of(e2)
		var d2 := f2.length()
		if d2 < near:
			near = d2
			title = str(e2["title"])
			sub = SafariRun.way_to(f2)
			named = str(e2["id"])
	return {"title": title, "sub": sub, "dim": true, "got": false, "ask": ask_label(named)}


# ================================================================== the run
func _process(delta: float) -> void:
	_wall += delta
	_layout_cockpit()
	if _report and not _reported:
		_reported = true
		_print_cabin()
	_press_t = maxf(0.0, _press_t - delta / 0.18)
	if _shutter_held():
		# the cap stays pushed in for as long as a thumb is on it: that IS the hold
		_press_t = 1.0
	if _phase == Ph.PAD:
		_t += delta
		_update_3d(delta)
		if _t >= 0.0:
			_phase = Ph.RUN
			_eye_root.visible = true
	elif _phase == Ph.RUN and _tut_paused:
		# R14: THE FLIGHT STOPS. Nothing below runs - not the run clock, not the lane (driven off
		# `_t`), not the cast (placed off `_t`), not the glass, not the scoring, not the policy's
		# thumb. Only the card and the cabin redraw. The wall clock `_wall` still runs, and how much
		# of it was spent paused is kept in `_tut_paused_wall` for whoever bills the flight.
		_tut_paused_wall += delta
		if _policy != "" or auto_pilot:
			_tut_policy_paused()
		if _tut_node != null:
			_tut_node.queue_redraw()
	elif _phase == Ph.RUN:
		for ba in _boost_ats:
			if not bool(ba["done"]) and _t >= float(ba["t"]):
				ba["done"] = true
				set_boost(not _boost)
		# R13 BOOST. Only the RUN CLOCK speeds up. The lane is driven off it (space_lane.gd advance()
		# sets `_lane_z` from `t`), so the ship, the destination and the cast move together and
		# nothing is dropped: every sight still crosses the sky, in a quarter of the wall time.
		# Everything a HAND does stays on wall seconds - the slew, the knob, autofocus, and the
		# exposure (`_update_glass(delta)`) - so boosting never makes a plate fill faster; it makes
		# the sight cross faster, which is its only price.
		var rd: float = delta * (BOOST_X if _boost else 1.0)
		_t += rd
		if _boost:
			_boost_saved += rd - delta
			_boost_wall += delta
		if not _fake_sight_seq.is_empty():
			for fz in _fake_sight_seq:
				if _t >= float(fz["t"]):
					_fake_sight_az = float(fz["az"])
					_fake_sight_el = float(fz["el"])
			# `_cast`'s "fake_sight" entry was baked once in `_ready()` (own dict, but GDScript
			# Dictionaries are references, so this mutates the SAME one `cast_list()` hands out) -
			# without this, `_fake_sight_az`/`_el` above move but the drawn dab never does.
			var fse := _find_cast("fake_sight")
			if not fse.is_empty():
				fse["az0"] = _fake_sight_az
				fse["az1"] = _fake_sight_az
				fse["el0"] = _fake_sight_el
				fse["el1"] = _fake_sight_el
				# Re-centred every frame so `SafariCast.moment_strength()` (sin(u*PI), peaking at the
				# moment's own midpoint) reads exactly 1.0 whenever a shot fires - the dab's OWN
				# worst-case size (`0.42 + 0.26 * mo` in `_rose()`), not whatever a fixed window
				# happened to be mid-fade through. F5/13.5 proof only; a real cast entry's moments
				# never move like this.
				fse["moments"] = [{"t0": _t - 1.0, "t1": _t + 1.0, "line": "fake sight (SYNTHETIC)"}]
		if not _poses.is_empty():
			for pz in _poses:
				if _t >= float(pz["t"]):
					_az = wrapf(float(pz["az"]), -180.0, 180.0)
					_el = clampf(float(pz["el"]), _el_min, _el_max)
		elif auto_pilot:
			_auto_step(delta)
		elif _policy != "":
			_policy_step(delta)
		else:
			_read_keys(delta)
		_update_3d(rd)
		_update_glass(delta)
		if auto_pilot:
			_auto_press()
		if _scope:
			_tut_zoomed = true
			_tut_zoom_wait = false
		if _tut_on:
			_tut_check()
		if _skip_at > -0.5 and _t >= _skip_at:
			print("SAFARI skip tapped at t=%.1f" % _t)
			_on_skip()
		elif _t >= _run_seconds:
			_finish()
	else:
		# the clock keeps running past the end so a capture can be aimed at the haul card
		_t += delta
		_film_row.visible = false
		_film_out_toast.visible = false
		# `--auto` finishes the WHOLE leg, not just the lane: a synthetic run that stops at the
		# haul card never exercises `landed` / the clock charge / the film debit, which is most of
		# what MODE round changed. 0.6 s is long enough that a capture aimed at the haul card still
		# gets one.
		if auto_pilot:
			if _auto_land_timer < 0.0:
				_auto_land_timer = 0.6
			else:
				_auto_land_timer -= delta
				if _auto_land_timer <= 0.0:
					_auto_land_timer = 999.0
					_on_skip()
	_do_scope_taps()
	_do_holds()
	_cockpit.queue_redraw()
	if _scope_fb != null:
		_scope_fb.queue_redraw()
	if _heat and _phase == Ph.RUN and _t > 2.0:
		_heat_gpu.append(delta * 1000.0)
		_heat_cpu.append(RenderingServer.viewport_get_measured_render_time_cpu(
			get_viewport().get_viewport_rid()))
	_do_shots()
	if _quit_at > 0.0 and _wall >= _quit_at:
		_print_heat()
		get_tree().quit()


func _read_keys(delta: float) -> void:
	var a := Vector2.ZERO
	if Input.is_key_pressed(KEY_LEFT):
		a.x -= 1.0
	if Input.is_key_pressed(KEY_RIGHT):
		a.x += 1.0
	if Input.is_key_pressed(KEY_UP):
		a.y += 1.0
	if Input.is_key_pressed(KEY_DOWN):
		a.y -= 1.0
	if a != Vector2.ZERO:
		_swing(a.x * SLEW_MAX_DEG * delta, a.y * SLEW_MAX_DEG * delta)
	var f := 0.0
	if Input.is_key_pressed(KEY_Q):
		f -= 1.0
	if Input.is_key_pressed(KEY_E):
		f += 1.0
	if f != 0.0:
		_focus = clampf(_focus + f * delta * KNOB_RATE, 0.0, 1.0)
		_knob_touched()


func _swing(daz: float, del: float) -> void:
	_az = wrapf(_az + daz, -180.0, 180.0)
	_el = clampf(_el + del, _el_min, _el_max)


## Where subject `e` sits relative to the crosshair right now, in SCORE UNITS - one unit is
## SCORE_UNIT_DEG (7.0) degrees, always, whatever the window is showing. x right, y DOWN (screen
## order).
##
## THE DIVISOR IS THE CHANGE. It used to be SafariCatalog.FIELD_HALF_DEG, which made every number
## downstream of here - the scoring, the autopilot's aim, the nameplate's "well over to your left",
## the collar - a fraction of whatever the field happened to be. Now it is a constant of this file,
## so the scope can go from 56 degrees to 14 and back without any of them moving. `glass_of()`
## below is the only place the window's width enters.
func field_of(e: Dictionary) -> Vector2:
	var p := SafariCast.pos_at(e, _t)
	var daz := wrapf(p.x - _az, -180.0, 180.0)
	var del := p.y - _el
	return Vector2(daz, -del) / SCORE_UNIT_DEG


## Score units -> GLASS units, where 1.0 is the edge of the opening. This is the one conversion the
## window's width touches, and it is exactly the magnification: at 7 degrees it is 1.0 (the old
## picture, unchanged) and at 28 it is 0.25.
func glass_zoom() -> float:
	return SCORE_UNIT_DEG / field_half_deg()


## An (az, el) in degrees, in score units off the crosshair. Same convention as `field_of`.
func aim_off(az_deg_in: float, el_deg_in: float) -> Vector2:
	return Vector2(wrapf(az_deg_in - _az, -180.0, 180.0), -(el_deg_in - _el)) / SCORE_UNIT_DEG


## R5 BRIDGE, and it is meant to become a no-op. safari_lanes.gd keeps its own EL_MIN/EL_MAX copy
## (its :43-44) and clamps every sight to that copy +-4 degrees; until G3 lands the matching
## numbers, its SIDES table can place a sight at elevation 44, which this file's clamp can no longer
## reach - an uncatchable sight, which is worse than the bug this round is fixing. So the cast is
## pulled inside the reachable sky here, once, at _ready(). When safari_lanes.gd's copy matches
## EL_MIN/EL_MAX, every entry already satisfies this and it changes nothing.
func _clamp_cast_el() -> void:
	var lo: float = _el_min + 2.0
	var hi: float = _el_max - 2.0
	var moved := 0
	for e in _cast:
		for k in ["el0", "el1"]:
			var v: float = float(e[k])
			var c: float = clampf(v, lo, hi)
			if absf(c - v) > 0.001:
				moved += 1
			e[k] = c
	if moved > 0:
		print("SAFARI R5 bridge: %d cast elevations pulled into %.0f..%.0f (safari_lanes.gd still has its own EL_MIN/EL_MAX)" % [
			moved, lo, hi])


func _update_glass(delta: float) -> void:
	_layout_cockpit()
	_live.clear()
	var best_q := 0.0
	# R9: autofocus moves the dial BEFORE anything is scored, so this frame's sharpness is the one
	# the player is looking at.
	_autofocus(delta)
	var shot_id: String = str(_shot.get("id", ""))
	var q_of: Dictionary = {}
	var cur_id := ""
	var cur_q := 0.0
	# --- score every subject that is up, whether or not it is the one you are on. A thing you are
	# half-pointed at still exposes, slowly; that is what makes a greedy swing between two subjects
	# lose BOTH, which is the lesson the overlap is there to teach.
	for e in _cast:
		var id := str(e["id"])
		var tr: Dictionary = _track[id]
		if not SafariCast.is_up(e, _t):
			continue
		var f := field_of(e)
		var d := f.length()
		tr["up_wall"] = float(tr["up_wall"]) + delta
		# the opening is a disc again, so what it can draw is a disc. Scoring is untouched: it is
		# still the radial distance `d` below.
		if d < 1.65:
			_live.append({"e": e, "f": f})
		# R9: the plate blooming under a held shutter is already in the haul, but it keeps
		# exposing - on exactly the arithmetic below - until the thumb comes off.
		var blooming: bool = id == shot_id
		if bool(tr["caught"]) and not blooming:
			continue
		var in_win: bool = d * SCORE_UNIT_DEG <= field_half_deg()
		if not blooming:
			# --- R1's accounting, in sight-seconds. This is the "the sky was empty" complaint
			# turned into a number: how much of the time a sight is up is it actually ON THE GLASS?
			_up_sec += delta
			if d < 1.65:
				_old_drawn_sec += delta
			if in_win:
				_window_sec += delta
		var centred: float = clampf(1.0 - (d - CENTRE_R) / (EDGE_R - CENTRE_R), 0.0, 1.0)
		var sharp: float = clampf(1.0 - absf(_focus - float(e["focus"])) / FOCUS_TOL, 0.0, 1.0)
		var q := centred * sharp
		tr["seen"] = maxf(float(tr["seen"]), centred)
		if not blooming:
			# R9's miss ledger. Read only by `_miss_reason()`; nothing here changes a score.
			if in_win:
				tr["win_sec"] = float(tr["win_sec"]) + delta
			if centred >= Q_FLOOR:
				tr["centred_sec"] = float(tr["centred_sec"]) + delta
				tr["sharp_c_max"] = maxf(float(tr["sharp_c_max"]), sharp)
			if q >= Q_FLOOR and _film_left <= 0:
				tr["nofilm_q_sec"] = float(tr["nofilm_q_sec"]) + delta
			q_of[id] = q
		if q >= Q_FLOOR and q > cur_q:
			cur_q = q
			cur_id = id
		if q >= Q_FLOOR:
			tr["hold"] = float(tr["hold"]) + delta * q
			tr["qsum"] = float(tr["qsum"]) + q * delta
			tr["qtime"] = float(tr["qtime"]) + delta
			var ms := SafariCast.moment_strength(e, _t)
			if ms > float(tr["best_moment"]):
				var m := SafariCast.moment_at(e, _t)
				tr["best_moment"] = ms
				tr["best_line"] = str(m.get("line", ""))
				tr["best_mult"] = float(m.get("mult", 1.0))
		else:
			tr["hold"] = maxf(0.0, float(tr["hold"]) - delta * DRAIN_RATE)
		best_q = maxf(best_q, q)
		if blooming:
			# never the auto path: `_bloom_step` below finishes a plate that is already taken
			continue
		# 12.3, NO PHOTO WITHOUT A PRESS. A full exposure used to call `_catch` right here, by
		# itself, and G7's critic filled all 10 plates without once touching the shutter. Now a
		# full exposure WAITS: `hold` is pinned at hold_sec - the same pin the film-out case always
		# used (point 3: film gates the shutter, not the sky) - `caught` stays false, the cap and
		# the ring read full, and a press develops it (`_shutter_press` -> `_catch`). Let it go,
		# and it drains exactly as any exposure does once it leaves the middle.
		if float(tr["hold"]) >= float(e["hold_sec"]):
			tr["hold"] = float(e["hold_sec"])

	# R9's "you were busy with X", as a number: every second one sight is up while the player is
	# exposing ANOTHER is charged to that other one, by name.
	if cur_id != "":
		for oid in q_of:
			if oid != cur_id:
				var bz: Dictionary = _track[oid]["busy"]
				bz[cur_id] = float(bz.get(cur_id, 0.0)) + delta
	_bloom_step()

	# --- feed the glass. Nearest three, furthest first so a hull can cover a glow behind it.
	_live.sort_custom(func(a, b): return float(a["f"].length()) > float(b["f"].length()))
	while _live.size() > 3:
		_live.remove_at(0)
	var zoom := glass_zoom()
	var fh_rad := deg_to_rad(field_half_deg())
	_eye_mat.set_shader_parameter("aspect", window_aspect())
	# THE LINE THE WHOLE ROUND TURNS ON. `field_deg` is a uniform the shader declares and never
	# reads; `field_half` is the one it actually uses, and until now nothing wrote it, so the glass
	# was pinned at 7 degrees whatever any constant said. Both are set, the real one first.
	_eye_mat.set_shader_parameter("field_half", fh_rad)
	_eye_mat.set_shader_parameter("field_ref", deg_to_rad(FIELD_HIGH_DEG))
	_eye_mat.set_shader_parameter("field_deg", field_half_deg())
	_eye_mat.set_shader_parameter("centre_rad", deg_to_rad(CENTRE_DEG))
	# a star is a point source: its PSF stays the same size in PIXELS when the window widens
	_eye_mat.set_shader_parameter("star_rad", 0.42 / zoom)
	_eye_mat.set_shader_parameter("corner", CORNER_Q)
	_eye_mat.set_shader_parameter("n_subj", _live.size())
	_eye_mat.set_shader_parameter("t", _t)
	_eye_mat.set_shader_parameter("run", _t)
	_eye_mat.set_shader_parameter("look", Vector2(deg_to_rad(_az), deg_to_rad(_el)))
	# ROUND 2: where the ship is heading and where the two worlds are, in field radii
	_lane.feed_eyepiece(_eye_mat, _az, _el)
	# ...and then rescaled into GLASS units, because space_lane.gd divides by its own copy of a
	# fixed 7.0 (`SafariCast.FIELD_HALF_DEG`, its :561 and :565) and knows nothing about the window.
	# NEEDS_FROM_OTHERS: G5 should take the divisor from `run.field_half_deg()` and this block goes.
	# Until then this is the exact inverse of what it just did, so nothing is approximated.
	if not is_equal_approx(zoom, 1.0):
		for nm in ["flow_from", "dest_pos", "home_pos", "sun_at"]:
			_eye_mat.set_shader_parameter(nm, Vector2(_eye_mat.get_shader_parameter(nm)) * zoom)
		for nr in ["dest_r", "home_r"]:
			_eye_mat.set_shader_parameter(nr, float(_eye_mat.get_shader_parameter(nr)) * zoom)
	_feed_rail(delta)
	_feed_marks(zoom)
	_eye_mat.set_shader_parameter("aurora", _aurora)
	_eye_mat.set_shader_parameter("sky_light", 0.0)
	# R12, THE WOBBLE IS GONE (spec 10.2, the user: "the wavy effect of the planet is disorienting").
	# This used to be `1.0 - best_q`, and safari_eyepiece.gdshader bends the whole glass coordinate
	# space by it - so the sky swam hardest exactly when the player was lost and not aimed at
	# anything. The uniform stays (the shader is G5's, and safari_haul.gd / sky_watch.gd write 0.0
	# to it too); this file just stops asking for it. The far marks and the bullseye were already
	# drawn in the un-swum `p_dry`, so they do not move.
	_eye_mat.set_shader_parameter("swim", clampf(1.0 - best_q, 0.0, 1.0) if _swim_legacy else 0.0)
	_eye_mat.set_shader_parameter("warm", clampf(best_q, 0.0, 1.0))
	_eye_mat.set_shader_parameter("flash", _flash)
	for i in 3:
		if i >= _live.size():
			_eye_mat.set_shader_parameter("s%d_pos" % i, Vector2(9.0, 9.0))
			continue
		var e: Dictionary = _live[i]["e"]
		var f: Vector2 = _live[i]["f"]
		var sharp: float = clampf(1.0 - absf(_focus - float(e["focus"])) / FOCUS_TOL, 0.0, 1.0)
		# REVIEW MERGE (safari4-review, 2026-09-21). This was eight set_shader_parameter lines that
		# sent kind/scale/tints plus a seed taken from the SLOT index. SafariShapes.apply sends the
		# same five plus the sight's OWN seed and its twelve shape knobs (f1/f2/f3) - the whole
		# point of the shapes round. NEITHER BUILDER MADE THIS CALL: SafariShapes was reached only
		# from showcase/safari_sheet.gd and showcase/safari_bench.gd, so in a real flight the new
		# shader ran with f1=f2=f3=0 and every sight fell back to its bare six-branch look.
		# `zoom` is the magnification: it puts the sight where the WINDOW shows it and shrinks the
		# drawing by the same factor, so a subject keeps its true angular size in both fields. That
		# is the "shapes drift past small and soft" of spec 6.2 - the same picture, further away.
		SafariShapes.apply(_eye_mat, i, e, f, 1.0 - sharp, SafariCast.moment_strength(e, _t), zoom)

	# --- the fireflies are the hold meter, on whichever subject you are closest to holding
	var lead := 0.0
	for e in _cast:
		var tr: Dictionary = _track[str(e["id"])]
		if bool(tr["caught"]) and str(e["id"]) != shot_id:
			continue
		# F4: only what is still in the sky. A sight that left keeps its `hold` (nothing drains it
		# once it is down), and since 12.3 that can be a FULL exposure nobody pressed for - which
		# held the ring and the fireflies at "ready" long after there was nothing left to take.
		if not SafariCast.is_up(e, _t):
			continue
		lead = maxf(lead, float(tr["hold"]) / float(e["hold_sec"]))
	# FILM builder pass, point 3: OUT OF FILM READS DEAD, NOT READY. Above, a full hold with no
	# plates left pins `tr["hold"]` at the ceiling instead of calling `_catch` - which used to leave
	# `lead` (and therefore the shutter ring and the fireflies) sitting at 1.0, amber and armed, the
	# exact frame it is least true: the shutter cannot do anything. Zeroing `lead` here, once, is the
	# one line that makes the shutter and the fireflies agree with what a press would actually do.
	if _film_left <= 0:
		lead = 0.0
	# R9: while a plate blooms, the fireflies ARE the bloom - that plate's exposure and nothing else
	# (film may be 0 now: the plate it blooms on was paid for at the press).
	if not _shot.is_empty():
		var se: Dictionary = _shot["e"]
		lead = float(_track[str(se["id"])]["hold"]) / float(se["hold_sec"])
	_lead_hold = clampf(lead, 0.0, 1.0)
	var landed: int = int(floor(clampf(lead, 0.0, 1.0) * float(FF_COUNT) + 0.0001))
	for i in FF_COUNT:
		var want: float = 1.0 if i < landed else 0.0
		_ff_settle[i] = move_toward(_ff_settle[i], want, delta * (2.6 if want > 0.5 else 1.5))

	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta / 0.45)



# ================================================================== R1: the far marks
## EVERY SIGHT THAT IS UP AND UNCAUGHT GETS A MARK AT ITS TRUE ANGLE. This is the answer to "the sky
## was empty just little star dots": before this, `_live`'s `d < 1.65` gate meant nothing at all was
## drawn more than 11.5 degrees off the crosshair, out of a sky 360 degrees round.
##
## It does not score and it cannot: nothing reads these uniforms back, and the scoring loop above
## has already run. It hands over to the real shape between 1.0 and 1.8 score units (7 to 12.6
## degrees) - inside that the shape itself is drawn, outside it only the mark is - so a sight is
## never drawn twice and never drops out between the two.
##
## S3, the 1-2 second warning: the mark comes up MARK_LEAD_SEC before the sight's window opens and
## flares while it does, so the thing announces itself before it can be framed. SafariCast.pos_at
## clamps its parameter, so during the lead the mark sits exactly where the sight will enter.
func _feed_marks(zoom: float) -> void:
	var cand: Array = []
	for e in _cast:
		var id := str(e["id"])
		if bool(_track[id]["caught"]):
			continue
		var t0: float = float(e["t_start"])
		if _t < t0 - MARK_LEAD_SEC or _t > float(e["t_end"]):
			continue
		var f := field_of(e)
		var d := f.length()
		# the handover: nothing where the real shape already is
		var over: float = clampf((d - 1.0) / 0.8, 0.0, 1.0)
		if over <= 0.0:
			continue
		# S3's warning flare, and then a steady mark
		var warn: float = clampf(1.0 - (_t - (t0 - MARK_LEAD_SEC)) / MARK_LEAD_SEC, 0.0, 1.0)
		var moment: float = SafariCast.moment_strength(e, _t)
		var s: float = over * (0.52 + 0.85 * warn + 0.22 * moment)
		cand.append({"f": f, "d": d, "s": s})
	# nearest first: with only MARK_N slots, the ones you could actually turn to win them
	cand.sort_custom(func(a, b): return float(a["d"]) < float(b["d"]))
	var n: int = 0 if _marks_off else mini(cand.size(), MARK_N)
	if cand.size() > MARK_N:
		# MARK_N is a hard count because the uniform block is unrolled. If this ever prints a
		# non-zero number, a sight went unmarked and the block needs more slots.
		_mark_dropped_sec += float(cand.size() - MARK_N) * get_process_delta_time()
	_eye_mat.set_shader_parameter("n_mark", n)
	var rad: float = MARK_DEG * 0.5 / field_half_deg()
	for i in MARK_N:
		if i >= n:
			_eye_mat.set_shader_parameter("mk%d" % i, Vector4.ZERO)
			continue
		var c: Dictionary = cand[i]
		var g: Vector2 = Vector2(c["f"]) * zoom
		_eye_mat.set_shader_parameter("mk%d" % i,
			Vector4(g.x, g.y, rad, float(c["s"])))


# ================================================================== R10: the track's one switch
## 12.6 CLEANUP. This used to solve the old single gold rail - a great circle from the ship's floor
## to the destination's lower limb - and feed it as `rail_far`, `rail_near`, `rail_n`, `rail_smin`,
## `rail_h`, `rail_gap` and `rail_phase`, and it counted "arc within CENTRE_DEG of the crosshair"
## seconds for R3's gate. R10 replaced that rail with the two-rail track space_lane.gd feeds
## (`trk_*`), and the shader stopped reading every one of those uniforms except `rail_on`
## (safari_eyepiece.gdshader, its "WAVE 3 (G5)" note). So they are gone, with the counter and its
## "SAFARI rail:" line, which measured a rail nobody draws. What is left is the one switch the
## shader still reads: the track is drawn with the scope LOWERED only (nothing decorative belongs
## in a photograph), and `--no-rail` turns it off for an A/B. The track's own gates are measured by
## space_lane.gd's probes (G5b), against what is actually drawn.
func _feed_rail(_delta: float) -> void:
	var on: bool = _phase == Ph.RUN and not _scope and not _rail_off
	_eye_mat.set_shader_parameter("rail_on", 1.0 if on else 0.0)


func _catch(e: Dictionary, tr: Dictionary) -> void:
	tr["caught"] = true
	_flash = 1.0
	var avg: float = float(tr["qsum"]) / maxf(float(tr["qtime"]), 0.0001)
	var mult: float = float(tr["best_mult"]) if float(tr["best_moment"]) >= 0.35 else 1.0
	var line: String = str(tr["best_line"]) if float(tr["best_moment"]) >= 0.35 else ""
	# WIRE round: PRICED BY SafariScoring, not by SafariCast.value_of (rarity x hold, a placeholder
	# that paid 1..3) and not by SkyPrint.grade_for (sharpness alone, so the moment did nothing).
	# `grade` folds the moment in at a 50/50 weight, `price` is the real stardust Gloop pays, and
	# rarity 4 is a real rung in both.
	var rarity: int = int(e["rarity"])
	var rec := {
		"id": str(e["id"]), "title": str(e["title"]), "kind": int(e["kind"]), "via": "full",
		"rarity": rarity, "sharpness": avg, "moment": line, "mult": mult,
		"grade": SafariScoring.grade_for(avg, mult), "t": _t,
		"price": SafariScoring.price_of(rarity, avg, mult),
		"value": SafariScoring.quality_of(rarity, avg, mult),
		# WIRE: the whole cast entry travels with the catch. safari_haul.gd needs the tints, the
		# scale and the blurb to re-render the print and to open a journal page for a sight
		# SkyEvents has never heard of, and copying four fields out here would be a third place
		# that has to be kept in step with the sheet.
		"subject": e.duplicate(true)}
	_haul.append(rec)
	var got_sub: String = line if line != "" else "%s  ·  a plain one" % str(rec["grade"])
	if got_sub.length() > 60:
		got_sub = got_sub.substr(0, 59)
	_last_catch = {"title": str(e["title"]), "sub": got_sub, "t": _t}
	_film_left = maxi(0, _film_left - 1)
	_update_film_row()
	shot_taken.emit(rec)
	print("SAFARI catch t=%.1f %-22s r%d sharp=%.2f moment='%s' x%.2f grade=%s pays=%d film_left=%d" % [
		_t, str(rec["id"]), rarity, avg, line, mult, str(rec["grade"]), int(rec["price"]),
		_film_left])


func _on_skip() -> void:
	if _phase == Ph.HAUL:
		# MODE round: this used to be get_tree().quit() - a HAUL-phase "Skip" quit the whole
		# engine, which is why nothing downstream of a run ever saw its haul. "Land" now hands
		# control back to whoever opened this scene instead.
		landed.emit(_wall)
		return
	_finish()


func _finish() -> void:
	if _phase == Ph.HAUL:
		return
	_end_bloom("the lane ended")
	# R14: the flag is set only when every lesson has been shown or skipped (`_tut_resolve` does
	# that). A lane that ends with lessons still owed leaves it unset; TUT_PROGRESS already holds the
	# ones that were taught, so the next photo flight teaches only the rest.
	if _tut_on:
		var owed: Array = []
		for i in 4:
			if _tut_res & (1 << i) == 0:
				owed.append(str(i + 1))
		print("SAFARI tutorial: the lane ended with lesson(s) [%s] still owed after %d card(s) this flight; flag %s stays unset, %s=%d, they come on the next photo flight" % [
			", ".join(PackedStringArray(owed)), _tut_shown, TUT_FLAG, TUT_PROGRESS, _tut_res])
	if _tut_node != null:
		_tut_node.visible = false
		_tut_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tut_paused = false
	_phase = Ph.HAUL
	if _boost:
		set_boost(false)
	if _boost_btn != null:
		_boost_btn.visible = false
	_eye_root.visible = false
	_skip.text = "Land"
	_fill_card()
	_card.visible = true
	run_finished.emit(_haul)
	var got := 0
	for e in _cast:
		var tr: Dictionary = _track[str(e["id"])]
		if bool(tr["caught"]):
			got += 1
		else:
			print("SAFARI miss %-22s hold=%.2f/%.2f seen=%.2f  \"%s\"" % [
				str(e["id"]), float(tr["hold"]), float(e["hold_sec"]),
				float(tr["seen"]), _miss_reason(e)])
	print("SAFARI haul: %d of %d, t=%.1f" % [got, _cast.size(), _t])
	# R13: did the boost SKIP anything? Every sight is listed with the wall seconds it was up.
	var ups: Array = []
	var never_up := 0
	var in_glass := 0
	for e in _cast:
		var trk: Dictionary = _track[str(e["id"])]
		ups.append(float(trk["up_wall"]))
		if float(trk["up_wall"]) <= 0.0:
			never_up += 1
		if float(trk["win_sec"]) > 0.0 or bool(trk["caught"]):
			in_glass += 1
	ups.sort()
	print("SAFARI sights: %d of %d came up (%d never did); %d were in the glass or caught; wall seconds up min %.2f median %.2f; boost %s" % [
		_cast.size() - never_up, _cast.size(), never_up, in_glass,
		float(ups[0]) if not ups.is_empty() else 0.0,
		float(ups[ups.size() / 2]) if not ups.is_empty() else 0.0,
		"used" if _boost_wall > 0.0 else "never used"])
	# R9: "no press is ever dead", as numbers. Every press either took a plate or printed why not.
	print("SAFARI shutter-stats presses=%d took=%d (full exposures developed %d, armed-hold %d, bloomed a grade %d) refused=%d [nothing %d, off-centre %d, not-sharp %d, out-of-film %d, already-got %d, before-run %d] silent=%d; auto-filled catches=%d (12.3: no press, no photo); knob manual %.1fs; boost saved %.1f run-s over %.1f wall-s" % [
		int(_st["press"]), int(_st["take"]), int(_st["full"]), int(_st["armed_take"]), int(_st["bloomed"]),
		int(_st["refuse"]), int(_st["nothing"]), int(_st["offcentre"]), int(_st["unsharp"]),
		int(_st["nofilm"]), int(_st["caught"]), int(_st["early"]),
		int(_st["press"]) - int(_st["take"]) - int(_st["refuse"]), _auto_fill, _manual_sec,
		_boost_saved, _boost_wall])
	_print_heat()
	print("SAFARI sky: %.1f sight-seconds up; ON THE GLASS %.1f s under the old d<1.65 gate (11.5 deg) -> %.1f s inside the %.0f deg window; %.0f%% -> %.0f%% of up-time; mark slots overflowed for %.2f sight-seconds" % [
		_up_sec, _old_drawn_sec, _window_sec, 2.0 * field_half_deg(),
		100.0 * _old_drawn_sec / maxf(_up_sec, 0.001),
		100.0 * _window_sec / maxf(_up_sec, 0.001), _mark_dropped_sec])


## WHY YOU MISSED IT is the whole card. A thing you never pointed at reads differently from a thing
## you were two seconds short on, and a thing you gave up to catch something else reads differently
## again - that last line is the one the run is built to produce.
## The run's own GPU and CPU render time, as a distribution rather than a mean. See `--heat`.
## See `--tap-scope=`. Fires a press and a release on the scope switch through the real input path.
func _do_scope_taps() -> void:
	if _scope_taps.is_empty() or _phase != Ph.RUN or _tut_paused:
		return
	for tap in _scope_taps:
		if bool(tap["rep"]):
			# the injected event is handled on the frame AFTER parse_input_event queues it, so the
			# result has to be read a frame late or it always reports "nothing happened"
			tap["rep"] = false
			print("SAFARI tap RESULT %s: landed in zone '%s', scope now %s" % [
				str(tap["what"]), _last_zone, str(_scope)])
	var i := 0
	while i < _scope_taps.size():
		var tap: Dictionary = _scope_taps[i]
		if _t < float(tap["t"]) or bool(tap.get("fired", false)):
			i += 1
			continue
		tap["fired"] = true
		tap["rep"] = true
		var what := str(tap["what"])
		var base := what.trim_suffix("_mouse")
		var xf: Array = shutter_xf() if base == "shutter" else (
			knob_xf() if base == "knob" else scope_xf())
		# UI units -> WINDOW units. Input.parse_input_event takes display coordinates, and on the
		# phone frame the viewport is stretched 1.64x, so an unconverted position lands 40% of the
		# way toward the top-left corner and hits nothing. This is the whole reason the first
		# attempt reported "zone=NONE".
		var stretch: Vector2 = Vector2(DisplayServer.window_get_size()) / _root.size
		var at: Vector2 = Vector2(xf[0]) * stretch
		_last_zone = ""
		var as_mouse: bool = what.ends_with("_mouse")
		for pressed in [true, false]:
			if as_mouse:
				# a REAL mouse: device 0, which is what a desktop click looks like. The emulated one
				# Godot makes from a touch is device -1, and `_real_mouse()` drops that.
				var mb := InputEventMouseButton.new()
				mb.device = 0
				mb.button_index = MOUSE_BUTTON_LEFT
				mb.position = at
				mb.pressed = pressed
				Input.parse_input_event(mb)
			else:
				var ev := InputEventScreenTouch.new()
				ev.index = 0
				ev.position = at
				ev.pressed = pressed
				Input.parse_input_event(ev)
		print("SAFARI tap SENT %s t=%.2f at window (%.0f,%.0f)" % [what, _t, at.x, at.y])
		i += 1


## See `--hold-shutter=`. One touch index per hold, so a hold and a policy tap never share one.
func _do_holds() -> void:
	if _holds.is_empty() or _phase != Ph.RUN or _tut_paused:
		return
	var ws: Vector2 = Vector2(DisplayServer.window_get_size())
	var stretch: Vector2 = ws / _root.size if ws.x > 1.0 else Vector2.ONE
	var at: Vector2 = Vector2(shutter_xf()[0]) * stretch
	for i in _holds.size():
		var h: Dictionary = _holds[i]
		var want := -1
		if int(h["st"]) == 0 and _t >= float(h["t0"]):
			want = 1
		elif int(h["st"]) == 1 and _t >= float(h["t1"]):
			want = 0
		if want < 0:
			continue
		h["st"] = int(h["st"]) + 1
		if ws.x <= 1.0:
			# headless: no window for an event to land in (measured) - call what it would reach
			if want == 1:
				_press(20 + i, Vector2(shutter_xf()[0]))
			else:
				_zones.erase(20 + i)
				if not _shutter_held():
					_armed = false
		else:
			var ev := InputEventScreenTouch.new()
			ev.index = 20 + i
			ev.position = at
			ev.pressed = want == 1
			Input.parse_input_event(ev)
		print("SAFARI hold-shutter %s t=%.2f (%s)" % ["DOWN" if want == 1 else "UP", _t,
			"headless direct" if ws.x <= 1.0 else "InputEventScreenTouch"])


func _print_heat() -> void:
	if not _heat or _heat_gpu.is_empty():
		return
	var g := _heat_gpu.duplicate()
	var c := _heat_cpu.duplicate()
	g.sort()
	c.sort()
	var n := g.size()
	print("SAFARI heat n=%d frames  frame ms p10=%.3f median=%.3f p90=%.3f  CPU ms median=%.3f p90=%.3f  field=%s" % [
		n, g[int(n * 0.10)], g[n / 2], g[int(n * 0.90)], c[n / 2], c[int(n * 0.90)],
		"raised 7" if _scope else "lowered 28"])
	print("SAFARI heat copies=%d porthole=%.0fx%.0f UI px, %.0f device px across" % [
		_heat_copies, _win.size.x, _win.size.y,
		_win.size.x * DisplayServer.window_get_size().x / maxf(_root.size.x, 1.0)])


## WHY YOU MISSED IT, and R9's rule for it: every line names a cause its own counters recorded
## (see `_new_track`), never a guess. Checked in this order, first true one wins:
##   plates ran out     it was full-held with no film, or takeable while the magazine was empty
##   never found it     it was never inside the glass while it was up
##   busy with X        while it was up you spent longer exposing X (and got X) than you ever had
##                      this one framed
##   had it N s         it was takeable (centred AND sharp past Q_FLOOR) for N seconds and no tap
##                      landed on it - a tap would have taken it
##   never sharp        centred well enough, but focus never got it past Q_FLOOR (spec 9.1's lie:
##                      this used to fall through to "found it too late")
##   never centred      in the glass, never brought to the middle
## "found it too late" is gone. It was the fall-through, and the player's log printed it six times
## for sights that were dead centre and never sharp.
func _miss_reason(e: Dictionary) -> String:
	var tr: Dictionary = _track[str(e["id"])]
	# It was takeable while the magazine was empty. 12.3: a full `hold` alone no longer means this -
	# a full exposure with plates left is now simply one that was never pressed, and falls through
	# to "you had it N s - a tap takes it" below, which is the true reason.
	if float(tr["nofilm_q_sec"]) > 0.0:
		return "the plates ran out first"
	if float(tr["win_sec"]) <= 0.0:
		return "never found it"
	var takeable: float = float(tr["qtime"])
	var busy_id := ""
	var busy_s := 0.0
	var bz: Dictionary = tr["busy"]
	for oid in bz:
		if not bool(_track.get(oid, {}).get("caught", false)):
			continue
		if float(bz[oid]) > busy_s:
			busy_s = float(bz[oid])
			busy_id = str(oid)
	if busy_id != "" and busy_s >= 0.5 and busy_s > takeable:
		return "you were busy with %s" % _mid(str(_find_cast(busy_id).get("title", busy_id)))
	if takeable > 0.0:
		return "you had it %.1fs - a tap takes it" % maxf(takeable, 0.1)
	if float(tr["centred_sec"]) > 0.0:
		return "centred, but never sharp"
	return "seen, but never in the middle"


## The entry sitting in a named slot of this run's cast, or {}. Used by the report for the clash.
func _clash_entry(slot_key: String) -> Dictionary:
	for e in _cast:
		if str(e.get("slot", "")) == slot_key:
			return e
	return {}


func _find_cast(id: String) -> Dictionary:
	for e in _cast:
		if str(e["id"]) == id:
			return e
	return {}


## Which way something off the glass is, in words. No degrees, no arrow, no minimap: on a phone in
## two thumbs the only useful answer is "swing left" or "look behind you", and a number would turn
## the run into a radar game.
static func way_to(f: Vector2) -> String:
	var fl := f.length()
	if fl > 12.0:
		return "somewhere behind you"
	var side := "to your right" if f.x > 0.0 else "to your left"
	if absf(f.y) > absf(f.x) * 1.4:
		return "above you" if f.y < 0.0 else "below you"
	if fl > 5.0:
		return "well over %s" % side
	return side


static func _short(s: String) -> String:
	var t := s
	if t.length() > 26:
		t = t.substr(0, 25).strip_edges() + "."
	return t


## Titles are written as headings ("A pod of driftlings"), so dropping one into the middle of a
## sentence needs its capital taken off or it reads as somebody's name.
static func _mid(s: String) -> String:
	var t := _short(s)
	if t.is_empty():
		return t
	return t.substr(0, 1).to_lower() + t.substr(1)


func _fill_card() -> void:
	for c in _card.get_children():
		c.queue_free()
	var pad := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		pad.add_theme_constant_override("margin_" + side, 24)
	_card.add_child(pad)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 5)
	pad.add_child(col)

	var got := _haul.size()
	col.add_child(_lbl("The haul", 30, C_TEXT))
	var pay := 0
	for r in _haul:
		pay += int(r.get("price", 0))
	col.add_child(_lbl("%d of %d, on %s" % [got, _cast.size(), str(lane().get("name", "the lane"))],
		19, C_SOFT))
	if got > 0:
		col.add_child(_lbl("Gloop will pay %d for the copies" % pay, 17, C_GOLD))
	var plates_used := film_start - _film_left
	col.add_child(_lbl("%d of %d plates" % [plates_used, film_start],
		15, C_SOFT if _film_left > 0 else C_AMBER))
	col.add_child(HSeparator.new())

	# TWO COLUMNS AND A SCROLL (G7, wave 3). One tall column of every catch and every miss ran off
	# the top AND the bottom of the 720-UI-row screen once a run had ~10 of each - measured on a real
	# 2556x1179 frame of a tap-only flight (10 caught, 8 let go). That was already true of a full
	# expert run; R9 makes it the NORMAL case, because a first-time player now catches ~10. So the
	# haul and the misses sit side by side, and if even that is taller than the screen allows, the
	# pair scrolls (a drag scrolls a ScrollContainer on touch) instead of leaving the screen.
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 28)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 5)
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 5)
	cols.add_child(left)
	for rec in _haul:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		row.add_child(_swatch(int(rec["kind"]), true))
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 1)
		v.add_child(_lbl(str(rec["title"]), 22, C_TEXT))
		var sub: String = str(rec["moment"])
		if sub == "":
			sub = "a plain one"
		v.add_child(_lbl("%s  ·  %s  ·  %d" % [str(rec["grade"]), sub, int(rec.get("price", 0))],
			17, C_SOFT))
		row.add_child(v)
		left.add_child(row)

	var missed: Array = []
	for e in _cast:
		if not bool(_track[str(e["id"])]["caught"]):
			missed.append(e)
	if not missed.is_empty():
		if not _haul.is_empty():
			cols.add_child(VSeparator.new())
		cols.add_child(right)
		right.add_child(_lbl("Let go", 22, C_MISS))
		for e in missed:
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 12)
			row.add_child(_swatch(int(e["kind"]), false))
			var v := VBoxContainer.new()
			v.add_theme_constant_override("separation", 1)
			v.add_child(_lbl(str(e["title"]), 21, C_MISS))
			v.add_child(_lbl(_miss_reason(e), 17, C_MISS.darkened(0.15)))
			row.add_child(v)
			right.add_child(row)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.add_child(cols)
	col.add_child(sc)
	# as tall as the longer column wants, up to what the screen leaves under the header and footer
	var want_h: float = cols.get_combined_minimum_size().y
	var room: float = maxf(_root.size.y - 380.0, 160.0)
	sc.custom_minimum_size = Vector2(cols.get_combined_minimum_size().x, minf(want_h, room))
	col.add_child(HSeparator.new())
	col.add_child(_lbl("The lane runs again tomorrow.", 19, C_SOFT))

	# FILM builder pass, point 4, WITH SafariScoring'S NUMBERS (WIRE round): the upgrade is a SCRAP
	# sink of 400 then 850, +1 plate a DAY, two tiers - not 340 stardust for +2 a trip. Offered only
	# when it is relevant: the box ran dry and there is a tier left.
	if _film_left <= 0 and GameState.film_upgrade_available():
		col.add_child(HSeparator.new())
		var up_row := HBoxContainer.new()
		up_row.add_theme_constant_override("separation", 10)
		var up_cost := SafariScoring.film_upgrade_cost(GameState.film_upgrades)
		var up_lbl := _lbl("Bigger magazine: +1 plate a day — %d scrap" % up_cost, 15, C_SOFT)
		up_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		up_lbl.custom_minimum_size = Vector2(260.0 * _uis, 0.0)
		up_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		up_row.add_child(up_lbl)
		var buy_btn := UIStyle.make_button("Buy", "Pill")
		buy_btn.disabled = not GameState.can_afford_scrap(up_cost)
		buy_btn.pressed.connect(func() -> void:
			if GameState.buy_film_upgrade():
				_fill_card())
		up_row.add_child(buy_btn)
		col.add_child(up_row)


func _lbl(t: String, px: int, c: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_override("font", UIStyle.ui_font())
	l.add_theme_font_size_override("font_size", px)
	l.add_theme_color_override("font_color", c)
	return l


## A tiny brass-ringed chip per row, filled for a catch and hollow for a miss. Same language as the
## rim: no ticks, no crosses, nothing green.
func _swatch(kind: int, filled: bool) -> Control:
	var c := Chip.new()
	c.kind = kind
	c.filled = filled
	c.custom_minimum_size = Vector2(34.0, 34.0)
	return c


## THE SCOPE SWITCH, drawn plainly, ONLY until the cabin draws it properly. See `_build_ui`. A brass
## ring, dark when the scope is down, amber and filled when it is up.
##
## ROUND 2: IT SAYS "scope" NOW. It used to be deliberately wordless, on the argument that the label
## is G2's and two builders writing the same label is how a merge goes wrong. The critic was right
## that that left the one control a first-time player must find as a nameless brass ring, and the
## argument does not actually hold: this node and G2's drawing can never be on screen at the same
## time - the first line of `_draw` returns the moment `draws_scope()` is true, and the whole label
## goes with it. R6 asks for every control to say what it does, and "until the other group lands" is
## not an exception a player experiences. One word, so G2 can replace it with anything better.
class ScopeFallback extends Control:
	var run: SafariRun

	func _draw() -> void:
		if run == null:
			return
		# the handshake: one method in safari_cockpit.gd and this node stops painting for good
		if run.cockpit_draws_scope():
			return
		# the haul card is up: no controls are live, so none is drawn (it used to sit beside the card)
		if not run.hud_live():
			return
		var xf: Array = run.scope_xf()
		var c: Vector2 = xf[0]
		var r: float = xf[1]
		draw_circle(c, r, Color(SafariRun.C_BRASS_SH, 0.55))
		draw_arc(c, r, 0.0, TAU, 44, SafariRun.C_BRASS, 3.0, true)
		# the lens sits in the UPPER two thirds so the word has the lower third to itself
		var lens: Vector2 = c - Vector2(0.0, r * 0.18)
		if run.scope_raised():
			draw_circle(lens, r * 0.42, SafariRun.C_AMBER)
			draw_circle(lens, r * 0.22, SafariRun.C_GOLD)
		else:
			draw_arc(lens, r * 0.40, 0.0, TAU, 32, SafariRun.C_BRASS_HI, 2.5, true)
		# ON the disc, not under it: under it is the console lip. 0.42 r is a 21 px font on the
		# 1280x720 desktop frame and 34 device px on the 2556x1179 phone one, which measures 22
		# device px of ink - R6's floor - with the word 82 px wide inside a 166 px disc.
		var f: Font = UIStyle.ui_font()
		var px: int = maxi(roundi(r * 0.42), 11)
		var w: float = f.get_string_size(
			"scope", HORIZONTAL_ALIGNMENT_LEFT, -1.0, px).x
		draw_string(f, c + Vector2(-w * 0.5, r * 0.80), "scope",
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, px, SafariRun.C_TEXT)


class Chip extends Control:
	var kind := 0
	var filled := true

	func _draw() -> void:
		var ctr := size * 0.5
		var r: float = minf(size.x, size.y) * 0.44
		draw_arc(ctr, r, 0.0, TAU, 40, SafariRun.C_BRASS_D, 3.0, true)
		if filled:
			draw_circle(ctr, r * 0.72, SafariRun.C_AMBER)
			draw_circle(ctr, r * 0.40, SafariRun.C_GOLD)
		else:
			draw_arc(ctr, r * 0.55, 0.0, TAU, 32, SafariRun.C_MISS, 2.0, true)


# ================================================================== input
func _on_eye_input(event: InputEvent) -> void:
	if _tap_trace:
		print("TAPTRACE event %s device=%d" % [event.get_class(), event.device])
	if event is InputEventScreenTouch:
		_touch_seen = true
		var t := event as InputEventScreenTouch
		if t.pressed:
			_press(t.index, t.position)
		else:
			_zones.erase(t.index)
			if not _shutter_held():
				_armed = false
		_eye_root.accept_event()
	elif event is InputEventScreenDrag:
		_touch_seen = true
		var d := event as InputEventScreenDrag
		_move(d.index, d.position, d.relative)
		_eye_root.accept_event()
	elif _real_mouse(event) and event is InputEventMouseButton:
		var b := event as InputEventMouseButton
		if b.button_index == MOUSE_BUTTON_LEFT:
			if b.pressed:
				_press(-1, b.position)
			else:
				_zones.erase(-1)
				if not _shutter_held():
					_armed = false
			_eye_root.accept_event()
	elif _real_mouse(event) and event is InputEventMouseMotion:
		if _zones.has(-1):
			var mm := event as InputEventMouseMotion
			_move(-1, mm.position, mm.relative)
			_eye_root.accept_event()


## IS THIS A REAL MOUSE, OR A TOUCH WEARING A MOUSE COSTUME?
##
## MEASURED, 2026-09-21, and it was a live bug before this round added a control that shows it.
## Godot's `input_devices/pointing/emulate_mouse_from_touch` is on, and the emulated
## InputEventMouseButton arrives BEFORE the InputEventScreenTouch that produced it - so the old
## guard, `not _touch_seen`, lost the race on the FIRST touch of a run and `_press` ran twice:
##
##     TAPTRACE event InputEventMouseButton device=-1     <- emulated, _touch_seen still false
##     TAPTRACE _press index=-1 zone=scope
##     TAPTRACE event InputEventScreenTouch device=0      <- the real one, sets _touch_seen
##     TAPTRACE _press index=0  zone=scope
##
## On the shutter that meant the first tap of every flight fired `_fire_shutter()` twice; on the
## new scope switch it meant the first tap toggled it on and straight back off, so the control
## looked dead until you pressed it a second time. `device == -1` is Godot's own marker for an
## emulated event (a real mouse is device 0), so the test is exact rather than a timing guess.
func _real_mouse(event: InputEvent) -> bool:
	return not _touch_seen and event.device != -1


## THREE ZONES AND A DEAD ONE. The glass is where you aim, the knob is under the left thumb and
## the shutter under the right. A thumb resting on the hull between them does nothing, which is
## what hull is for.
func _press(index: int, pos: Vector2) -> void:
	if _tut_paused:
		# the card sits on top of everything and takes its own taps; this is a belt for a press
		# that reached the glass anyway (a synthetic call, or a touch that began under the card)
		return
	var xk: Array = knob_xf()
	var xs: Array = shutter_xf()
	var xz: Array = scope_xf()
	var zone := "dead"
	if pos.distance_to(Vector2(xs[0])) <= float(xs[1]) * 1.32:
		zone = "shutter"
	elif pos.distance_to(Vector2(xz[0])) <= float(xz[1]) * 1.20:
		# THE SCOPE (safari6). A tap, not a hold: on a phone a hold competes with the aim drag, and
		# the player has to be able to raise the glass and then swing while it is up.
		#
		# ROUND 2: 1.20, not 1.45, because the control itself is now a 54 dp disc instead of a
		# 30 dp one (see scope_xf). The old 1.45 was doing the work the radius should have been
		# doing, which made the returned radius a lie: G2 would have drawn a ring smaller than the
		# zone, and the critic who measured the returned radius measured 30 dp while the reachable
		# zone was 44. The drawn ring is the control now, with the same small courtesy margin the
		# knob and the shutter get. It still sits below the shutter's own 1.32 zone, which is
		# tested first: shutter reaches _ctrl_y() + 1.32 * _ctrl_r(), this starts 18 UI px lower.
		zone = "scope"
	elif pos.distance_to(Vector2(xk[0])) <= float(xk[1]) * 1.55:
		zone = "knob"
	elif pos.y > _rail.end.y and pos.y < _con.position.y:
		# the glass AND the hull either side of it: a thumb does not have to find the disc to swing
		zone = "aim"
	_zones[index] = zone
	_last_zone = zone
	if _tap_trace:
		print("TAPTRACE _press index=%d pos=(%.0f,%.0f) zone=%s" % [index, pos.x, pos.y, zone])
	if zone == "shutter":
		_press_t = 1.0
		_shutter_press()
	elif zone == "scope":
		_scope = not _scope


func _move(index: int, pos: Vector2, rel: Vector2) -> void:
	# R14: a thumb that was already dragging when a card came up keeps its touch, but the sky does
	# not move under it while the flight is stopped.
	if _tut_paused:
		return
	var zone: String = str(_zones.get(index, ""))
	if zone == "":
		_press(index, pos)
		zone = str(_zones.get(index, "dead"))
	if zone == "knob":
		# up is farther away. One console-and-a-bit of travel covers the whole dial.
		_focus = clampf(_focus - rel.y / maxf(_con.size.y * 1.2, 120.0), 0.0, 1.0)
		_knob_touched()
	elif zone == "aim":
		# degrees per pixel is the same in both axes, matching the glass
		var r: float = maxf(_win.size.y * 0.5, 1.0)
		# drag LEFT to swing the scope RIGHT: you are pushing the sky, the way a real tube feels
		_swing(-rel.x / r * DRAG_DEG_PER_R, rel.y / r * DRAG_DEG_PER_R)


## ================================================================== R9: THE SHUTTER ALWAYS DOES SOMETHING
## (docs/SAFARI_FLIGHT_SPEC.md 9.3, a user ruling: "I was expecting the shutter to click, not for me
## to need to hold anything.")
##
##   TAP    takes the picture NOW, graded on this instant: how centred and how sharp it is this
##          frame (the scoring loop's own `q`) and the moment it is in this frame, if any.
##   HOLD   the plate is already taken and paid for; while the thumb stays down it BLOOMS. Every
##          frame it is re-graded - on this instant, and on the whole exposure so far (the same
##          average sharpness and best moment a full passive hold is graded on) - and it keeps
##          whichever is best. It can only go up. Let go, or lose the sight out of the glass, or fill
##          the exposure, and it stops where it got to. Nothing is lost by letting go.
##   NO     If nothing can be taken the press says why, in words, on the nameplate - nothing in the
##          glass (and which way the nearest thing is), not centred, not sharp yet, already got it,
##          out of film. A press with the thumb left down after a refusal is ARMED: it takes the
##          first frame the sight becomes takeable.
##
## WHAT DID NOT CHANGE: the grading. `q = centred * sharp` with CENTRE_R, EDGE_R, FOCUS_TOL and
## Q_FLOOR as they were; SafariScoring.grade_for / price_of / quality_of as they were. A tap is the
## same arithmetic applied to a one-frame exposure, and Q_FLOOR keeps its meaning: below it the
## glass "does not expose at all", so a tap below it takes nothing and costs no film.

## The instant, for one sight - EXACTLY the scoring loop's arithmetic, so a tap and the loop can
## never disagree about what "centred" or "sharp" means.
func _snap(e: Dictionary) -> Dictionary:
	var f := field_of(e)
	var d := f.length()
	var centred: float = clampf(1.0 - (d - CENTRE_R) / (EDGE_R - CENTRE_R), 0.0, 1.0)
	var sharp: float = clampf(1.0 - absf(_focus - float(e["focus"])) / FOCUS_TOL, 0.0, 1.0)
	return {"f": f, "d": d, "centred": centred, "sharp": sharp, "q": centred * sharp,
		"in_win": d * SCORE_UNIT_DEG <= field_half_deg()}


## The best plate this sight gives RIGHT NOW: this instant (only if it clears Q_FLOOR - below it
## nothing is exposing), or the exposure so far (only while it is live, hold > 0). Both are graded
## by SafariScoring.skill_moment, and a moment only counts past MOMENT_MIN, exactly as `_catch` does.
func _plate_pick(e: Dictionary, tr: Dictionary, q_now: float) -> Dictionary:
	var pick := {"sharp": 0.0, "mult": 1.0, "line": "", "skill": -1.0, "how": ""}
	if q_now >= Q_FLOOR:
		var mult := 1.0
		var line := ""
		if SafariCast.moment_strength(e, _t) >= MOMENT_MIN:
			var m := SafariCast.moment_at(e, _t)
			mult = float(m.get("mult", 1.0))
			line = str(m.get("line", ""))
		pick = {"sharp": q_now, "mult": mult, "line": line,
			"skill": SafariScoring.skill_moment(q_now, mult), "how": "instant"}
	if float(tr["qtime"]) > 0.0 and float(tr["hold"]) > 0.0:
		var avg: float = float(tr["qsum"]) / maxf(float(tr["qtime"]), 0.0001)
		var xm: float = float(tr["best_mult"]) if float(tr["best_moment"]) >= MOMENT_MIN else 1.0
		var xl: String = str(tr["best_line"]) if float(tr["best_moment"]) >= MOMENT_MIN else ""
		var xs: float = SafariScoring.skill_moment(avg, xm)
		if xs > float(pick["skill"]):
			pick = {"sharp": avg, "mult": xm, "line": xl, "skill": xs, "how": "exposure"}
	return pick


func _rec_apply(rec: Dictionary, e: Dictionary, pick: Dictionary) -> void:
	var rarity: int = int(e["rarity"])
	var sh: float = float(pick["sharp"])
	var mu: float = float(pick["mult"])
	rec["sharpness"] = sh
	rec["moment"] = str(pick["line"])
	rec["mult"] = mu
	rec["grade"] = SafariScoring.grade_for(sh, mu)
	rec["price"] = SafariScoring.price_of(rarity, sh, mu)
	rec["value"] = SafariScoring.quality_of(rarity, sh, mu)


## What a press would hit right now. `take` is the uncaught sight with the best q at or over
## Q_FLOOR; `near` is the uncaught sight nearest the crosshair inside the glass (for the words when
## nothing can be taken); `got` is a CAUGHT sight nearer the crosshair than `near`; `far` is the
## nearest uncaught sight anywhere in the sky.
func _shutter_targets() -> Dictionary:
	var out := {"take": {}, "take_q": 0.0, "near": {}, "near_s": {}, "got": {}, "far": {}, "far_f": Vector2.ZERO,
		"full": {}}
	var near_d := 1e9
	var got_d := 1e9
	var far_d := 1e9
	for e in _cast:
		if not SafariCast.is_up(e, _t):
			continue
		var id := str(e["id"])
		var s := _snap(e)
		var d: float = float(s["d"])
		if bool(_track[id]["caught"]):
			if bool(s["in_win"]) and d < got_d:
				got_d = d
				out["got"] = e
			continue
		if d < far_d:
			far_d = d
			out["far"] = e
			out["far_f"] = s["f"]
		if bool(s["in_win"]) and d < near_d:
			near_d = d
			out["near"] = e
			out["near_s"] = s
		if float(s["q"]) >= Q_FLOOR and float(s["q"]) > float(out["take_q"]):
			out["take_q"] = float(s["q"])
			out["take"] = e
		# 12.3: an exposure that filled and is waiting for its press. The first one in cast order -
		# the order the old passive loop caught them in - so a press develops the same plate the
		# old build would have caught on its own.
		if (out["full"] as Dictionary).is_empty() \
				and float(_track[id]["hold"]) >= float(e["hold_sec"]):
			out["full"] = e
	if got_d > near_d:
		out["got"] = {}
	return out


## THE SHUTTER, pressed (a thumb on the cap, a click, or Space).
func _shutter_press() -> void:
	_st["press"] = int(_st["press"]) + 1
	if not _shot.is_empty():
		_end_bloom("pressed again")
	if _phase != Ph.RUN:
		_refuse("", "not yet", "the glass opens in a moment", "early")
		emit_signal("shutter_used", false)
		return
	# FILM builder pass, point 3, kept: an empty magazine takes nothing. It SAYS so now.
	if _film_left <= 0:
		print("SAFARI shutter t=%.1f out of film" % _t)
		_refuse("", "out of film", "no plates left this trip", "nofilm")
		emit_signal("shutter_used", false)
		return
	var tg := _shutter_targets()
	# 12.3: A FULL EXPOSURE IS DEVELOPED, not re-graded. It is the plate the old build caught by
	# itself, and it is graded by the same untouched `_catch` - the average sharpness and the best
	# moment of the whole exposure - so centring and waiting still pays, and only the press is new.
	var fe: Dictionary = tg["full"]
	if not fe.is_empty():
		_armed = false
		_note = {}
		_st["take"] = int(_st["take"]) + 1
		_st["full"] = int(_st["full"]) + 1
		_tut_tapped = true
		_catch(fe, _track[str(fe["id"])])
		emit_signal("shutter_used", true)
		return
	var e: Dictionary = tg["take"]
	if not e.is_empty():
		var tr: Dictionary = _track[str(e["id"])]
		_take(e, tr, _plate_pick(e, tr, float(tg["take_q"])), "tap")
		emit_signal("shutter_used", true)
		return
	_armed = true
	var near: Dictionary = tg["near"]
	var got: Dictionary = tg["got"]
	if not got.is_empty():
		_refuse("", str(got["title"]), "already in the box", "caught")
	elif near.is_empty():
		var far: Dictionary = tg["far"]
		if far.is_empty():
			_refuse("", "nothing in the glass", "nothing is out there yet", "nothing")
		else:
			_refuse(str(far["id"]), "nothing in the glass",
				"nearest: %s" % SafariRun.way_to(Vector2(tg["far_f"])), "nothing")
	else:
		var s: Dictionary = tg["near_s"]
		if float(s["centred"]) < Q_FLOOR:
			_refuse(str(near["id"]), str(near["title"]),
				"centre it - %s" % SafariRun.way_to(Vector2(s["f"])), "offcentre")
		else:
			# Centred and still not sharp. Pressing hands the dial back to autofocus - a half-press,
			# the way a real camera does it - so the NEXT frame is already turning toward sharp.
			_manual = false
			_refuse(str(near["id"]), str(near["title"]), "not sharp yet - focusing", "unsharp")
	emit_signal("shutter_used", false)


func _refuse(id: String, title: String, sub: String, kind: String) -> void:
	_st["refuse"] = int(_st["refuse"]) + 1
	if _st.has(kind):
		_st[kind] = int(_st[kind]) + 1
	if id != "" and _track.has(id):
		_track[id]["presses"] = int(_track[id]["presses"]) + 1
	_note = {"title": title, "sub": sub, "wall": _wall}
	print("SAFARI shutter t=%.1f refused (%s): %s / %s" % [_t, kind, title, sub])


## A plate goes in the box NOW and starts to bloom.
func _take(e: Dictionary, tr: Dictionary, pick: Dictionary, via: String) -> void:
	_armed = false
	_note = {}
	tr["caught"] = true
	_flash = 1.0
	var rec := {
		"id": str(e["id"]), "title": str(e["title"]), "kind": int(e["kind"]),
		"rarity": int(e["rarity"]), "t": _t, "via": via,
		"subject": e.duplicate(true)}
	_rec_apply(rec, e, pick)
	_haul.append(rec)
	_film_left = maxi(0, _film_left - 1)
	_update_film_row()
	_st["take"] = int(_st["take"]) + 1
	_tut_tapped = true
	if via == "held":
		_st["armed_take"] = int(_st["armed_take"]) + 1
	_shot = {"id": str(e["id"]), "e": e, "rec": rec, "t0": _t, "w0": _wall,
		"skill": float(pick["skill"]), "grade0": str(rec["grade"])}
	_last_catch = {"title": str(e["title"]), "sub": _got_sub(rec), "t": _t}
	shot_taken.emit(rec)
	print("SAFARI take t=%.1f %-22s r%d via=%s q_now=%.2f from=%s sharp=%.2f moment='%s' x%.2f grade=%s pays=%d film_left=%d" % [
		_t, str(e["id"]), int(e["rarity"]), via, float(pick["sharp"]) if str(pick["how"]) == "instant" else -1.0,
		str(pick["how"]), float(rec["sharpness"]), str(rec["moment"]), float(rec["mult"]),
		str(rec["grade"]), int(rec["price"]), _film_left])


func _got_sub(rec: Dictionary) -> String:
	var line: String = str(rec["moment"])
	var s: String = line if line != "" else "%s  ·  a plain one" % str(rec["grade"])
	if s.length() > 60:
		s = s.substr(0, 59)
	return s


## Once a frame, after the scoring loop. Grows a blooming plate, ends it, or fires an armed press.
func _bloom_step() -> void:
	if _shot.is_empty():
		if _armed and _shutter_held() and _phase == Ph.RUN and _film_left > 0:
			var tg := _shutter_targets()
			var ae: Dictionary = tg["take"]
			if not ae.is_empty():
				var atr: Dictionary = _track[str(ae["id"])]
				_take(ae, atr, _plate_pick(ae, atr, float(tg["take_q"])), "held")
		return
	if not _shutter_held():
		_end_bloom("let go")
		return
	var e: Dictionary = _shot["e"]
	var tr: Dictionary = _track[str(e["id"])]
	if not SafariCast.is_up(e, _t):
		_end_bloom("it left the sky")
		return
	var s := _snap(e)
	if not bool(s["in_win"]):
		_end_bloom("lost it out of the glass")
		return
	var pick := _plate_pick(e, tr, float(s["q"]))
	if float(pick["skill"]) > float(_shot["skill"]) + 0.000001:
		var rec: Dictionary = _shot["rec"]
		var was: String = str(rec["grade"])
		_rec_apply(rec, e, pick)
		_shot["skill"] = float(pick["skill"])
		if str(rec["grade"]) != was:
			print("SAFARI bloom t=%.1f %-22s %s -> %s (sharp=%.2f x%.2f)" % [
				_t, str(e["id"]), was, str(rec["grade"]), float(rec["sharpness"]), float(rec["mult"])])
	_last_catch = {"title": str(e["title"]), "sub": "%s, and blooming" % str(_shot["rec"]["grade"]), "t": _t}
	if float(tr["hold"]) >= float(e["hold_sec"]):
		_end_bloom("full exposure")


func _end_bloom(why: String) -> void:
	if _shot.is_empty():
		return
	var rec: Dictionary = _shot["rec"]
	var e: Dictionary = _shot["e"]
	if str(rec["grade"]) != str(_shot["grade0"]):
		_st["bloomed"] = int(_st["bloomed"]) + 1
	_last_catch = {"title": str(e["title"]), "sub": _got_sub(rec), "t": _t}
	print("SAFARI plate t=%.1f %-22s grade=%s (took %s, held %.2fs wall) - %s" % [
		_t, str(e["id"]), str(rec["grade"]), str(_shot["grade0"]), _wall - float(_shot["w0"]), why])
	# R14's out-of-order rule: a thumb that stayed down and let a plate bloom has learned the hold.
	if _wall - float(_shot["w0"]) >= 0.35 and why != "pressed again":
		_tut_held = true
	_shot = {}
	if why != "let go":
		# a thumb still down after the plate finished must be LIFTED before it takes another one:
		# otherwise holding through a full exposure would silently spend a plate on the next thing
		_armed = false


func _shutter_held() -> bool:
	if _space_held:
		return true
	for z in _zones.values():
		if str(z) == "shutter":
			return true
	return false


## For the cabin: would a tap take a picture this instant? The cap glows when it would.
func shutter_ready() -> bool:
	if _phase != Ph.RUN or _film_left <= 0:
		return false
	return not (_shutter_targets()["take"] as Dictionary).is_empty()


## True while a plate is blooming under a held shutter.
func shutter_blooming() -> bool:
	return not _shot.is_empty()


# ================================================================== R9: autofocus
## FOCUS GLIDES BY ITSELF to the sight nearest the crosshair INSIDE THE GLASS, at KNOB_RATE - the
## rate the knob turns under a key, so it is a thumb that never lets go, not a new tuning number.
## Nothing in the glass, and it holds where it is. Touch the knob and the dial is yours until the
## glass settles on a different sight. The synthetic `--auto` expert turns the knob itself, every
## frame, so autofocus never runs for it: that is why its catch lines are unchanged.
func _autofocus(delta: float) -> void:
	if auto_pilot:
		return
	var tid := ""
	var te: Dictionary = {}
	if not _shot.is_empty() and bool(_snap(_shot["e"])["in_win"]):
		te = _shot["e"]
		tid = str(te["id"])
	else:
		var best := 1e9
		for e in _cast:
			if not SafariCast.is_up(e, _t) or bool(_track[str(e["id"])]["caught"]):
				continue
			var d: float = field_of(e).length()
			if d * SCORE_UNIT_DEG <= field_half_deg() and d < best:
				best = d
				te = e
				tid = str(e["id"])
	if _manual:
		_manual_sec += delta
		if _manual_for == "":
			_manual_for = tid          # the knob was set before anything arrived: keep it for that one
		elif tid != "" and tid != _manual_for:
			_manual = false
	_af_id = tid
	if _manual or te.is_empty():
		return
	_focus = move_toward(_focus, float(te["focus"]), KNOB_RATE * delta)


func _knob_touched() -> void:
	if not _manual:
		_manual_for = _af_id
	_manual = true


## For the cabin: true while autofocus has the dial.
func autofocus_on() -> bool:
	return not _manual and not auto_pilot


# ================================================================== R13: the boost
func set_boost(on: bool) -> void:
	if _phase == Ph.HAUL:
		on = false
	if on and not BOOST_LIVE:
		print("SAFARI boost refused at t=%.1f: not live until safari_flight.gd bills boost_saved_sec()" % _t)
		on = false
	_boost = on
	_style_boost()
	print("SAFARI boost %s at t=%.1f wall=%.1f" % ["ON" if on else "off", _t, _wall])


func boost_on() -> bool:
	return _boost


## Run seconds the boost flew that the wall clock did not pay. A flight that must cost
## PHOTO_TRIP_HOURS whatever the player did bills these (see the report's needs_from_others).
func boost_saved_sec() -> float:
	return _boost_saved


## Seconds of lane left, in LANE seconds (they run BOOST_X times faster while boosting).
func flight_left_sec() -> float:
	return maxf(0.0, _run_seconds - maxf(_t, 0.0))


func flight_seconds() -> float:
	return _run_seconds


func boost_rect() -> Rect2:
	if _boost_btn == null:
		return Rect2()
	return Rect2(_boost_btn.position, _boost_btn.size)


## Where this flight lands, in words, for the cabin clock.
## The world id, as a name: every id is the world's own name except the hub, which the lanes call
## the Commons (SafariLanes.WORLD_LIMB "The Commons, plaza wide open").
func dest_name() -> String:
	if to_id == "hub":
		return "Commons"
	return to_id.capitalize()


func _style_boost() -> void:
	if _boost_btn == null:
		return
	if _boost:
		var sb := UIStyle.make_panel_style(C_AMBER, 14, C_BRASS_D, 3, 0, 4.0)
		for st in ["normal", "hover", "pressed", "focus"]:
			_boost_btn.add_theme_stylebox_override(st, sb)
		_boost_btn.add_theme_color_override("font_color", C_TEXT)
		_boost_btn.add_theme_color_override("font_hover_color", C_TEXT)
		_boost_btn.add_theme_color_override("font_pressed_color", C_TEXT)
	else:
		for st in ["normal", "hover", "pressed", "focus"]:
			_boost_btn.remove_theme_stylebox_override(st)
		for fc in ["font_color", "font_hover_color", "font_pressed_color"]:
			_boost_btn.remove_theme_color_override(fc)


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or event.is_echo():
		return
	var k := (event as InputEventKey).keycode
	if not event.is_pressed():
		if k == KEY_SPACE:
			_space_held = false
			if not _shutter_held():
				_armed = false
		return
	if k == KEY_ESCAPE:
		get_tree().quit()
	elif _tut_paused:
		# R14 on a keyboard: Space or Enter goes on, and nothing else does anything while paused
		if k == KEY_SPACE or k == KEY_ENTER or k == KEY_KP_ENTER:
			_tut_resume("key")
	elif k == KEY_SPACE:
		_space_held = true
		_press_t = 1.0
		_shutter_press()
	elif k == KEY_Z:
		# the desktop twin of the scope button. Same toggle, same state, no second code path.
		_scope = not _scope
	elif k == KEY_B:
		set_boost(not _boost)
	elif k == KEY_S:
		_on_skip()


# ================================================================== SYNTHETIC: the tap-only first-timer
## THE GATE POLICY OF SPEC 9.3, the builder's own copy (the critic writes its own and does not trust
## this one). It NEVER touches the knob and NEVER holds the shutter. What it can know:
##
##   `tap`        what is inside the glass (the 56-degree lowered window - it never raises the
##                scope), plus, when the glass is empty, the collar dabs: it swings toward the
##                nearest one. That is exactly what the cabin shows a player.
##   `tap-blind`  the glass only. When the glass is empty it sweeps right at half slew and levels
##                out, the way someone who has not noticed the collar looks around.
##
## HOW IT MOVES: a sight must have been in the glass for `_pol_react` wall seconds (0.40, the
## wave-2 critic's commit delay) before it goes for it; it slews at SLEW_MAX_DEG straight at where
## the sight IS (no lead) plus an aim error of up to `_pol_aim_err` degrees, re-rolled every half
## second; it TAPS whenever the sight is within `_pol_tap_deg` degrees of the crosshair ("roughly
## aimed"), no faster than every `_pol_gap` seconds. The tap is a real InputEventScreenTouch press
## and release on the shutter's own position, sent through Input.parse_input_event (the same path a
## thumb takes), so it goes through `_on_eye_input` -> `_press` -> the zone test. It is still not a
## finger, and slewing is set in code, not dragged.
func _policy_step(delta: float) -> void:
	# R14, SYNTHETIC: the tutorial-following first-timer does what the cards say. After "Zoom in" it
	# taps the scope control; once the raised glass has been empty for a second it lowers it again.
	# None of this runs unless the tutorial is on, so the plain tap policy is untouched by it.
	if _pol_want_scope:
		_pol_want_scope = false
		if not _scope:
			_policy_tap_at(Vector2(scope_xf()[0]), 8)
			_pol_scope_up = true
	var fh: float = field_half_deg()
	var vis: Dictionary = {}
	for e in _cast:
		var id := str(e["id"])
		if not SafariCast.is_up(e, _t) or bool(_track[id]["caught"]):
			continue
		if field_of(e).length() * SCORE_UNIT_DEG <= fh:
			vis[id] = e
			if not _pol_seen.has(id):
				_pol_seen[id] = _wall
	if _pol_scope_up and _scope:
		if not vis.is_empty():
			_pol_empty_since = -1.0
		elif _pol_empty_since < 0.0:
			_pol_empty_since = _wall
		elif _wall - _pol_empty_since > 1.0:
			_policy_tap_at(Vector2(scope_xf()[0]), 8)
			_pol_scope_up = false
			_pol_empty_since = -1.0
	var tgt: Dictionary = {}
	# R14: once the first card has named the asked sight, a player who read it goes for that one.
	var ask_e: Dictionary = {}
	if _tut_on and _tut_shown > 0 and _tut_id != "":
		var ae := _find_cast(_tut_id)
		if not ae.is_empty() and SafariCast.is_up(ae, _t) and not is_caught(_tut_id):
			ask_e = ae
	if not ask_e.is_empty():
		if vis.has(_tut_id):
			tgt = vis[_tut_id]
			_pol_id = _tut_id
		else:
			_pol_slew(SafariCast.pos_at(ask_e, _t), delta)
			return
	elif vis.has(_pol_id):
		tgt = vis[_pol_id]
	else:
		_pol_id = ""
		var bd := 1e9
		for id in vis:
			if _wall - float(_pol_seen[id]) < _pol_react:
				continue
			var d: float = field_of(vis[id]).length()
			if d < bd:
				bd = d
				tgt = vis[id]
				_pol_id = id
	if tgt.is_empty():
		if _policy != "tap-blind":
			# swing toward the nearest collar dab (every up, uncaught sight has one)
			var best := 1e9
			var aim := Vector2.ZERO
			for e in _cast:
				if not SafariCast.is_up(e, _t) or bool(_track[str(e["id"])]["caught"]):
					continue
				var f := field_of(e)
				if f.length() < best:
					best = f.length()
					aim = SafariCast.pos_at(e, _t)
			if best < 1e8:
				_pol_slew(aim, delta)
		else:
			_swing(SLEW_MAX_DEG * 0.5 * delta, clampf(-_el, -SLEW_MAX_DEG * delta, SLEW_MAX_DEG * delta))
		return
	if _pol_err_at < 0.0 or _wall - _pol_err_at > 0.5:
		_pol_err_at = _wall
		var a: float = _pol_rng.randf() * TAU
		var r: float = sqrt(_pol_rng.randf()) * _pol_aim_err
		_pol_err = Vector2(cos(a), sin(a)) * r
	var p: Vector2 = SafariCast.pos_at(tgt, _t)
	_pol_slew(p + _pol_err, delta)
	var off_deg: float = field_of(tgt).length() * SCORE_UNIT_DEG
	# 12.3: `--policy=never` is the same player with its thumb never on the shutter. Under the old
	# passive exposure it filled every plate; with no photo without a press it must catch nothing.
	if off_deg <= _pol_tap_deg and _wall >= _pol_next_tap and _policy != "never":
		_pol_next_tap = _wall + _pol_gap
		_policy_tap()


func _pol_slew(want: Vector2, delta: float) -> void:
	var daz := wrapf(want.x - _az, -180.0, 180.0)
	var del: float = want.y - _el
	var step: float = SLEW_MAX_DEG * delta
	var v := Vector2(daz, del)
	if v.length() > step:
		v = v.normalized() * step
	_swing(v.x, v.y)


## A synthetic tap anywhere (the scope switch, a card's button) - the same two paths `_policy_tap`
## uses for the shutter: a real InputEventScreenTouch windowed, a direct `_press` headless.
func _policy_tap_at(at_ui: Vector2, index: int) -> void:
	if not _pol_real_input or DisplayServer.window_get_size().x <= 1:
		_press(index, at_ui)
		_zones.erase(index)
		if not _shutter_held():
			_armed = false
		return
	var stretch: Vector2 = Vector2(DisplayServer.window_get_size()) / _root.size
	for pressed in [true, false]:
		var ev := InputEventScreenTouch.new()
		ev.index = index
		ev.position = at_ui * stretch
		ev.pressed = pressed
		Input.parse_input_event(ev)


func _policy_tap() -> void:
	# MEASURED: a headless run has no window (DisplayServer.window_get_size() is 0x0) and an
	# InputEvent sent into it at the shutter's position never reaches `_on_eye_input` at all. So a
	# headless batch calls `_press()` directly - the same function the event would reach - and a
	# windowed run sends the real event. The report says which runs were which.
	if not _pol_real_input or DisplayServer.window_get_size().x <= 1:
		_press(7, Vector2(shutter_xf()[0]))
		_zones.erase(7)
		if not _shutter_held():
			_armed = false
		return
	var stretch: Vector2 = Vector2(DisplayServer.window_get_size()) / _root.size
	var at: Vector2 = Vector2(shutter_xf()[0]) * stretch
	for pressed in [true, false]:
		var ev := InputEventScreenTouch.new()
		ev.index = 7
		ev.position = at
		ev.pressed = pressed
		Input.parse_input_event(ev)


# ================================================================== SYNTHETIC: R9 item 4, the no-knob table
## "Nothing in the catalog may be unreachable without touching the knob - prove this by listing,
## for all 51 catalog entries, the best grade a player who never touches the knob can get."
##
## For EVERY SafariCatalog sight, laid into a real lane window by SafariLanes._place (the lanes' own
## placement, moments in real seconds) of `--probe-win` seconds (default 15, the shortest window
## the eight lanes draw), this runs THIS FILE's `_update_glass` frame by frame at 60 Hz. Every
## player PARKS 9 degrees off the sight (inside the 28-degree glass, so autofocus can see it, but
## past EDGE_DEG so nothing exposes - the autopilot's own trick) until its move, then holds the
## scope dead on it. Focus starts at the WORST end of the dial for that sight (0 or 1, whichever is
## further from its focus) for every no-knob player. Four players:
##   OLD      the wave-2 build: focus stuck at the 0.5 default, no autofocus, no tap; centres at
##            the time the autopilot would (so the passive hold closes mid best-moment).
##   TAP      no knob, one tap at the peak of the sight's best moment.
##   HOLD     no knob, shutter pressed at the start of its best moment and held to the end.
##   KNOB     the expert: focus preset exactly, otherwise HOLD. The ceiling to compare against.
## It is synthetic twice over: aim is perfect (set, not slewed) and the shutter is set, not pressed.
## It measures what the grading allows once aim is solved, which is what "reachable" means.
func _run_catalog_probe() -> void:
	_phase = Ph.RUN
	var dt := 1.0 / 60.0
	var rows: Array = []
	var worst_no_knob := "Gallery"
	var unreachable := 0
	print("CATPROBE window=%.1fs dt=%.4f  id | focus | best_mult | OLD(focus 0.5, no AF, passive) | TAP no-knob at best-moment peak | HOLD no-knob through best moment | KNOB expert (preset focus, held) | AF sharp>=Q_FLOOR after" % [_probe_win, dt])
	for c in SafariCatalog.all():
		var e: Dictionary = SafariLanes._place(c, "bow", 0.0, _probe_win, 1.0, "probe")
		var fcs: float = float(e["focus"])
		var peak_t := -1.0
		var bm := 1.0
		for m in e["moments"]:
			if float(m["mult"]) > bm:
				bm = float(m["mult"])
				peak_t = (float(m["t0"]) + float(m["t1"])) * 0.5
		if peak_t < 0.0:
			peak_t = _probe_win * 0.5
		var worst: float = 0.0 if fcs > 0.5 else 1.0
		var old := _probe_one(e, "old", 0.5, -1.0)
		var hold := _probe_one(e, "hold", worst, -1.0)
		var tap := _probe_one(e, "tap", worst, peak_t)
		var knob := _probe_one(e, "knob", fcs, -1.0)
		if str(hold["grade"]) == "-" or str(tap["grade"]) == "-":
			unreachable += 1
		for g in [str(hold["grade"]), str(tap["grade"])]:
			if SafariScoring.GRADES.find(g) < SafariScoring.GRADES.find(worst_no_knob):
				worst_no_knob = g
		print("CATPROBE %-22s f=%.2f x%.1f | OLD %-7s | TAP %-7s | HOLD %-7s | KNOB %-7s | AF %.2fs" % [
			str(e["id"]), fcs, bm, str(old["grade"]), str(tap["grade"]), str(hold["grade"]),
			str(knob["grade"]), float(tap["af_sec"])])
		rows.append(e)
	print("CATPROBE done: %d sights, %d with no no-knob grade at all, worst no-knob grade %s" % [
		rows.size(), unreachable, worst_no_knob])


func _probe_one(e: Dictionary, mode: String, focus0: float, tap_t: float) -> Dictionary:
	_cast = [e]
	_track.clear()
	_track[str(e["id"])] = _new_track()
	_haul.clear()
	_shot = {}
	_armed = false
	_space_held = false
	_film_left = 99
	_focus = focus0
	_manual = mode == "old" or mode == "knob"
	_manual_for = str(e["id"])
	_t = 0.0
	var dt := 1.0 / 60.0
	var af_sec := -1.0
	var tapped := false
	# the best moment, and when each player comes off its park
	var m0 := -1.0
	var m1 := -1.0
	var bm := 1.0
	for m in e["moments"]:
		if float(m["mult"]) > bm:
			bm = float(m["mult"])
			m0 = float(m["t0"])
			m1 = float(m["t1"])
	var go: float = 0.0
	if mode == "old":
		go = maxf(0.0, _fire_from(e)) if m0 >= 0.0 else 0.0
	elif mode == "tap":
		go = tap_t
	else:
		go = maxf(m0, 0.0)
	while _t <= float(e["t_end"]):
		var p: Vector2 = SafariCast.pos_at(e, _t)
		_az = p.x + (9.0 if _t < go else 0.0)
		_el = p.y
		if _t >= go:
			if mode == "hold" or mode == "knob":
				if not _space_held:
					_space_held = true
					_shutter_press()
			elif mode == "tap" and not tapped:
				tapped = true
				_space_held = true
				_shutter_press()
				_space_held = false
		_update_glass(dt)
		if af_sec < 0.0 and absf(_focus - float(e["focus"])) <= FOCUS_TOL * (1.0 - Q_FLOOR):
			af_sec = _t
		_t += dt
	_space_held = false
	_update_glass(dt)
	var g := "-"
	if not _haul.is_empty():
		g = str(_haul[0]["grade"])
	return {"grade": g, "af_sec": af_sec}


# ================================================================== autopilot (SYNTHETIC)
## A scripted thumb, for captures and for measuring. It obeys SLEW_MAX_DEG and KNOB_RATE exactly
## as a finger would, so the timings it produces are honest - but it never generates an
## InputEvent, so it proves NOTHING about whether a real finger works (CLAUDE.md).
##
## The plan is the interesting part: it deliberately goes for the pod and THEN tries for the ice,
## which is the greedy play the overlap is designed to punish. The miss in the sheet is the design
## working, not the autopilot failing.
func _make_auto_plan() -> Array:
	# WIRE round (2026-09-21). THE PLAN IS NO LONGER A LIST OF NAMES. It used to name seven
	# safari_cast.gd ids by hand; with the cast drawn from SafariCatalog those ids do not exist on
	# any lane, so the autopilot flew 56 seconds and photographed nothing (measured: 0 of 6 before
	# this, 5 of 6 after). It is now written off whatever was drawn, so it flies any of the eight
	# lanes without being told anything about them.
	#
	# STILL GREEDY, STILL WAITING. Each subject is taken in the order its window opens, the scope
	# parks just off it until the hold would close in the middle of its BEST moment, and it does not
	# give up on a subject to chase a better one. That is what makes the clash cost something: the
	# two clash entries open in the same instant, and waiting out the first one's moment spends
	# exactly the seconds the second one needed.
	var plan: Array = []
	for e in _cast:
		plan.append({
			"id": str(e["id"]),
			"from": float(e["t_start"]),
			"until": float(e["t_end"]),
			"fire": _fire_from(e),
			"wait": true,
		})
	plan.sort_custom(func(a, b): return float(a["from"]) < float(b["from"]))
	return plan


## The subject the synthetic thumb is on right now. Of everything that is up, uncaught and still
## inside its window it takes the RAREST, and among equals the one whose window shuts first. That
## is the model of a player who has heard a hint: a rarity-4 green moon is worth giving up a
## rarity-2 hulk for, and giving it up is exactly what the clash charges you. It does not wander -
## once it is on something, only a rarer thing appearing, or the window shutting, moves it.
func _auto_target() -> Dictionary:
	var best: Dictionary = {}
	var best_r := -1
	var best_end := 1e9
	for entry in _auto_plan:
		var id := str(entry["id"])
		if bool(_track.get(id, {}).get("caught", false)):
			continue
		if _t < float(entry["from"]) or _t > float(entry["until"]):
			continue
		var e := _find_cast(id)
		if e.is_empty():
			continue
		var r := int(e["rarity"])
		var en := float(entry["until"])
		if r > best_r or (r == best_r and en < best_end):
			best_r = r
			best_end = en
			best = entry
	return best


## The run second at which the hold must START for the shutter to close in the middle of this
## subject's BEST moment (the highest multiplier it has, not merely its first one - a catalog sight
## carries two or three and the last is often the good one).
func _fire_from(e: Dictionary) -> float:
	var ms: Array = e.get("moments", [])
	if ms.is_empty():
		return -1.0
	var best: Dictionary = ms[0]
	for m in ms:
		if float(m["mult"]) > float(best["mult"]):
			best = m
	return (float(best["t0"]) + float(best["t1"])) * 0.5 - float(e["hold_sec"])


## 12.3: THE EXPERT PRESSES. The camera no longer shoots by itself, so the synthetic expert does
## what a player must: on the frame an exposure fills it presses the shutter - `_shutter_press()`,
## the function the Space key and a thumb on the cap both reach - which develops that full plate via
## `_catch`, on the same frame and in the same cast order the old passive loop caught it. SYNTHETIC:
## a direct call, not an InputEvent; it proves the grading is unchanged, not that a finger works.
func _auto_press() -> void:
	for _i in 4:
		if _film_left <= 0 or _phase != Ph.RUN:
			return
		if (_shutter_targets()["full"] as Dictionary).is_empty():
			return
		_press_t = 1.0
		_shutter_press()


func _auto_step(delta: float) -> void:
	var entry := _auto_target()
	if entry.is_empty():
		return
	var e := _find_cast(str(entry["id"]))
	if e.is_empty():
		return
	# lead the target: aim where it will be by the time the scope gets there
	var here: Vector2 = SafariCast.pos_at(e, _t)
	var soon: Vector2 = SafariCast.pos_at(e, _t + 0.55)
	var want: Vector2 = here.lerp(soon, 0.75)
	# PARK, do not shoot. Nine degrees off is 1.3 field radii - past EDGE_R, so nothing exposes -
	# but close enough that one flick puts it in the middle.
	if bool(entry.get("wait", false)):
		var ff := _fire_from(e)
		if ff > 0.0 and _t < ff:
			want.x += 9.0
	var daz := wrapf(want.x - _az, -180.0, 180.0)
	var del: float = want.y - _el
	var step: float = SLEW_MAX_DEG * delta
	var mag := Vector2(daz, del).length()
	if mag > step:
		var s := Vector2(daz, del).normalized() * step
		_swing(s.x, s.y)
	else:
		_swing(daz, del)
	_focus = move_toward(_focus, float(e["focus"]), KNOB_RATE * delta)


# ================================================================== captures
func _do_shots() -> void:
	if _cap_dir == "" or _shots.is_empty():
		return
	for s in _shots:
		if bool(s["done"]) or _t < float(s["t"]):
			continue
		s["done"] = true
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		var path: String = _cap_dir.path_join(str(s["name"]) + ".png")
		img.save_png(path)
		print("SAFARI shot %s t=%.2f -> %s (%dx%d)" % [
			str(s["name"]), _t, path, img.get_width(), img.get_height()])
		_probe_frame(str(s["name"]), img.get_width(), img.get_height())


## R1's EVIDENCE, printed from the frame's own state at the instant the PNG was saved.
##
## It prints, for every sight that is up and uncaught, its TRUE az/el, and the PIXEL the mark for it
## should be at - worked out here from the spherical geometry again rather than from the numbers the
## shader was handed, so an error in `_feed_marks` cannot hide inside its own check. A script then
## looks for a blob in the PNG at that pixel; the disagreement, converted back to degrees with the
## printed degrees-per-pixel, is the "within 2 degrees" gate.
func _probe_frame(name: String, iw: int, ih: int) -> void:
	if not _report:
		return
	var vs := _root.size
	var sx: float = float(iw) / maxf(vs.x, 1.0)
	var sy: float = float(ih) / maxf(vs.y, 1.0)
	var cx: float = (_win.position.x + _win.size.x * 0.5) * sx
	var cy: float = (_win.position.y + _win.size.y * 0.5) * sy
	var rpx: float = _win.size.y * 0.5 * sy          # one glass unit, in device pixels
	print("PROBE %s t=%.2f look az=%.2f el=%.2f field=%.1f scope=%s disc c=(%.1f,%.1f) r=%.1fpx  %.4f deg/px" % [
		name, _t, _az, _el, field_half_deg(), str(_scope), cx, cy, rpx,
		field_half_deg() / maxf(rpx, 1.0)])
	# Where the destination is, and how big. 12.6: this line used to call the planet's radius "the
	# rail's tip" - true of the old single rail, which ended on the lower limb; the R10 track ends
	# at the planet's CENTRE (space_lane.gd), so the claim is gone and only the planet is reported.
	var rp: Dictionary = _lane.lane_report(_t)
	var ddist: float = maxf(float(rp.get("dest_dist", 1000.0)), 1.0)
	var limb: float = rad_to_deg(atan(SpaceLane.WORLD_RADIUS / ddist))
	print("PROBE %s dest az=%.2f el=%.2f dist=%.0fm angular radius=%.2f deg" % [
		name, float(rp.get("dest_az", 0.0)), float(rp.get("dest_el", 0.0)), ddist, limb])
	for e in _cast:
		var id := str(e["id"])
		if bool(_track[id]["caught"]):
			continue
		var t0: float = float(e["t_start"])
		if _t < t0 - MARK_LEAD_SEC or _t > float(e["t_end"]):
			continue
		var p := SafariCast.pos_at(e, _t)
		var daz := wrapf(p.x - _az, -180.0, 180.0)
		var del := p.y - _el
		var gx: float = daz / field_half_deg()
		var gy: float = -del / field_half_deg()
		var off: float = sqrt(daz * daz + del * del)
		print("  PROBEMARK %s az=%.2f el=%.2f off=%.2fdeg glass=(%.4f,%.4f) px=(%.1f,%.1f) in=%s" % [
			id, p.x, p.y, off, gx, gy, cx + gx * rpx, cy + gy * rpx,
			str(sqrt(gx * gx + gy * gy) <= 1.0)])


# ================================================================== R14: THE FIRST LESSON
## (docs/SAFARI_FLIGHT_SPEC.md 11, docs/STORY_SPINE_SPEC.md 2.5b.) The user: "the game should have
## a tutorial where it should pause multiple times to show you: that its viewable in the distance;
## how to zoom in; how to hold and snap the photo; the number of limited camera shots you have."
##
## FOUR LESSONS. FAR and ZOOM come in that order (`_tut_step`); once both are behind us SNAP waits
## for its own moment (`_tut_res` bit 2). FILM (bit 3) is checked first, every frame, independent of
## the other three (SPEC 13.4): it fires on the very first plate used in the flight, whenever that
## is, even before FAR has fired. Each fires on a moment the player reaches:
##
##   0 FAR    the taught sight's far mark is up (inside MARK_LEAD_SEC of opening, or open) and inside
##            the window the player is looking through. Points at the mark. If it has been open
##            TUT_FAR_WAIT s and never been in the window, it fires anyway and points at the collar
##            dab, worded as the compass it is (top = straight ahead) - "it is over there" is the
##            lesson a player facing the wrong way needs, and without it they would never be shown it.
##   1 ZOOM   the sight is in the LOWERED window and within FIELD_HIGH_DEG of the crosshair - close
##            enough that raising the scope puts it in the glass. Points at the scope control.
##   2 SNAP   a press would take a plate right now, in EITHER view (`_shutter_targets()` has a
##            `take` or a filled exposure), or the taught sight is inside the raised glass, or a
##            plate has been spent since ZOOM was resolved. Right after the ZOOM card, the lowered
##            view waits until the scope has gone up once (`_tut_zoom_wait`); a spent plate still
##            fires it, so a player who ignores "Tap scope" is taught on their next shot. Points at the shutter. (Round 1 required
##            the raised scope, so a player who never raised it, or took the sight on the frame the
##            scope went up, was never taught the hold.)
##   3 FILM   the very first plate used in the flight, whenever that is (SPEC 13.4: worth most at
##            the first plate, so it no longer waits its turn behind FAR/ZOOM/SNAP - on the Commons
##            flight the strict order used to land it after plates 4-5 were already spent). Points at
##            the film plates, with the real count.
##
## A LANE THAT ENDS WITH LESSONS OWED does not set TUT_FLAG: TUT_PROGRESS keeps what was taught and
## the next photo flight teaches the rest. "Skip tutorial" (on the first card a flight shows) is the
## only way to stop early.
##
## THE OUT-OF-ORDER RULE ("never stop a player to teach what they just did"):
##   ZOOM is skipped if the scope has been raised at any moment of the flight before it fires.
##   SNAP teaches two things, the tap AND the hold, so it is skipped only once the player has done
##        both (`_tut_tapped`: a press that took a plate; `_tut_held`: a plate that bloomed under a
##        thumb held >= 0.35 s). A player who has only tapped still gets it, worded for what is new
##        to them ("you've been tapping - that's a quick snap; keep your thumb on it and it blooms").
##        LEAD'S CALL, flagged in the report: the brief says "shot before pause 3 -> skipped", which,
##        read literally, skips the snap lesson on every Commons flight - the Lantern Lane's opener
##        is dead ahead at t=0 and a first-timer snaps it long before the lantern-fish comes up at
##        t=42 - and then the hold is never taught at all.
##   FAR and FILM are never skipped: seeing is not a thing you can do by accident, and nothing a
##        player does tells them the magazine has a bottom.
##
## NEVER DURING A HOLD. No card fires while a plate is blooming or a thumb is on the shutter; it
## waits for the thumb to come up. A card over a held bloom would eat the release.
##
## THE TAUGHT SIGHT is the trip's ask (`_tut_setup`). If it is caught, or its window closes, before a
## lesson fires, the next sight that is up takes over, so a player who wanders is still taught.
##
## PAUSE MEANS PAUSE. `_process` stops advancing `_t` and runs nothing else of the flight while
## `_tut_paused`; the SAFARI tutorial PAUSE and RESUME lines print `_t` at both ends so "frozen" is a
## number. The wall seconds spent paused are `paused_wall_sec()` - billing is safari_flight.gd's.

## The sight being taught right now, or {}. See the header for the hand-over rule.
func _tut_subject() -> Dictionary:
	var e := _find_cast(_tut_id)
	if not e.is_empty() and not is_caught(_tut_id) and _t <= float(e["t_end"]):
		return e
	var best := 1e9
	var pick: Dictionary = {}
	for c in _cast:
		var id := str(c["id"])
		if is_caught(id) or _t > float(c["t_end"]) or _t < float(c["t_start"]) - MARK_LEAD_SEC:
			continue
		var d: float = field_of(c).length()
		if d < best:
			best = d
			pick = c
	if not pick.is_empty():
		print("SAFARI tutorial subject %s -> %s at t=%.1f (the first was caught or gone)" % [
			_tut_id, str(pick["id"]), _t])
		_tut_id = str(pick["id"])
		_tut_up_since = -1.0
	return pick


func _tut_check() -> void:
	if not _tut_on or _tut_paused or _tut_step >= 4:
		return
	if not _shot.is_empty() or _shutter_held() or _t < 0.5:
		return
	# 13.4: FILM is independent of FAR/ZOOM/SNAP and fires on the very first plate used in the
	# flight, whenever that is - even before card 1, if the player's first shot lands before the
	# taught sight has ever been seen. Checked before the others so it always wins the frame it
	# becomes true on; cards 1-3 keep their own order and triggers below, untouched by this.
	if not _tut_has(3) and film_start - _film_left >= 1:
		_tut_fire(3, "")
		return
	if _tut_step == 1 and _tut_zoomed:
		_tut_skip(1, "the player had already raised the scope")
		return
	if _tut_step >= 2:
		if not _tut_has(2) and _tut_tapped and _tut_held:
			_tut_skip(2, "the player had already snapped AND held a plate to bloom")
			return
		if not _tut_has(2):
			var tg := _shutter_targets()
			var se := _tut_subject()
			var in_glass: bool = _scope and not se.is_empty() and SafariCast.is_up(se, _t) \
				and field_of(se).length() * SCORE_UNIT_DEG <= FIELD_HIGH_DEG
			var takeable: bool = not (tg["take"] as Dictionary).is_empty() \
				or not (tg["full"] as Dictionary).is_empty()
			# a plate spent since ZOOM was resolved: the player took one on a frame no earlier card
			# could fire (the sight came up and was taken at once, measured zorp_hub 1.5h) - teach
			# the hold now, in its "you've been tapping" words
			var spent: bool = film_start - _film_left > _tut_used_at
			if (takeable and not _tut_zoom_wait) or (takeable and _scope) or in_glass or spent:
				_tut_fire(2, "tapped" if _tut_tapped else "")
				return
		return
	var e := _tut_subject()
	if e.is_empty():
		return
	var d_deg: float = field_of(e).length() * SCORE_UNIT_DEG
	if _tut_step == 0:
		if _t < float(e["t_start"]) - MARK_LEAD_SEC:
			return
		if d_deg <= field_half_deg():
			_tut_fire(0, "window")
			return
		if _t >= float(e["t_start"]):
			if _tut_up_since < 0.0:
				_tut_up_since = _t
			elif _t - _tut_up_since >= TUT_FAR_WAIT:
				_tut_fire(0, "dab")
		return
	if not SafariCast.is_up(e, _t):
		return
	if _tut_step == 1 and not _scope and d_deg <= FIELD_HIGH_DEG:
		_tut_fire(1, "")


func _tut_has(lesson: int) -> bool:
	return _tut_res & (1 << lesson) != 0


## 0 while FAR is owed, 1 while ZOOM is, 2 once both are behind us, 4 when all four are.
func _tut_next_step() -> int:
	if _tut_res & TUT_ALL == TUT_ALL:
		return 4
	if not _tut_has(0):
		return 0
	if not _tut_has(1):
		return 1
	return 2


## Lesson `lesson` has been shown or skipped: remember it (in the save too), move on, and finish
## when none is owed.
func _tut_resolve(lesson: int, why_done: String) -> void:
	_tut_res |= 1 << lesson
	GameState.flags[TUT_PROGRESS] = _tut_res
	if lesson == 1 or lesson == 2:
		_tut_used_at = film_start - _film_left
	_tut_step = _tut_next_step()
	if _tut_step >= 4:
		_tut_done(why_done)


var _tut_used_at := 0
## True from the moment the ZOOM card is dismissed until the scope next goes up: SNAP does not fire
## in the lowered view in between, so "Tap scope" is not chased one frame later by "Tap the shutter"
## before the player could do what it said (a spent plate still fires it).
var _tut_zoom_wait := false
var _tut_snap_skipped := false
var _tut_captured: Dictionary = {}
var _tut_pol_sent := -1.0
var _tut_log: Array = []


func _tut_fire(card: int, variant: String) -> void:
	_tut_paused = true
	_tut_card = card
	_tut_variant = variant
	_tut_wall0 = _wall
	_tut_t0 = _t
	_tut_cabin_hour0 = GameState.time_of_day
	_tut_shown += 1
	_tut_pol_sent = -1.0
	_tut_node.visible = true
	_tut_node.mouse_filter = Control.MOUSE_FILTER_STOP
	_tut_node.queue_redraw()
	_tut_freeze_cabin_clock(true)
	var e := _find_cast(_tut_id)
	print("SAFARI tutorial PAUSE %d/4 \"%s\" (%s) t=%.4f wall=%.2f subject=%s off=%.1fdeg scope=%s plates %d/%d cabin_hour=%.4f" % [
		card + 1, tut_title(), variant if variant != "" else "-", _t, _wall, _tut_id,
		field_of(e).length() * SCORE_UNIT_DEG if not e.is_empty() else -1.0,
		"RAISED" if _scope else "lowered", film_start - _film_left, film_start, GameState.time_of_day])
	_tut_log.append("%d@%.1f" % [card + 1, _t])


## 13.4: the cabin clock (the "10:00" pill `safari_flight.gd` draws, backed by `GameState.time_of_day`)
## must LOOK paused too - the run clock `_t` already freezes, this only made the display keep moving.
## `safari_flight.gd` is comments-only for this builder, so the fix cannot add a check inside that
## file's `_process`; instead this reaches for the one flag that already gates its clock-advancing
## code, `_burning` (`_begin_clock_burn` / `_process` / `_on_landed`), and turns it off for the pause.
## SAFE FOR BILLING (do not change billing, spec item 2): `_on_landed` always trues up whatever the
## smooth burn had not ticked in one lump (12.2's fix), so how many ticks land before then never
## changes the total - only pausing and resuming when they land, which is exactly "look paused".
## DUCK-TYPED AND GUARDED: `in` and `set()` on the parent Node, not a typed reference to
## `safari_flight.gd` (this script must not depend on that file's class) - a showcase or probe run of
## `safari_run.gd` with no such parent, or a parent that has since renamed the field, is a silent
## no-op, never an error.
func _tut_freeze_cabin_clock(freeze: bool) -> void:
	var p := get_parent()
	if p == null or not ("_burning" in p):
		return
	p.set("_burning", not freeze)


## Go on. `how` is for the log: "tap", "key", "policy".
func _tut_resume(how: String) -> void:
	if not _tut_paused:
		return
	if _wall - _tut_wall0 < TUT_TAP_GUARD:
		return
	print("SAFARI tutorial RESUME %d/4 via %s: t=%.4f at the pause, t=%.4f now (%s), paused %.2f wall-s, cabin_hour=%.4f (was %.4f at pause)" % [
		_tut_card + 1, how, _tut_t0, _t, "FROZEN" if _t == _tut_t0 else "MOVED", _wall - _tut_wall0,
		GameState.time_of_day, _tut_cabin_hour0])
	_tut_paused = false
	_tut_node.visible = false
	_tut_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tut_freeze_cabin_clock(false)
	if _tut_card == 1 and (_policy != "") and not _scope:
		_pol_want_scope = true
	if _tut_card == 1 and not _scope:
		_tut_zoom_wait = true
	_tut_resolve(_tut_card, "all four lessons shown or skipped")


func _tut_skip(step: int, why: String) -> void:
	print("SAFARI tutorial SKIP %d/4 at t=%.1f: %s" % [step + 1, _t, why])
	_tut_log.append("%d skipped@%.1f" % [step + 1, _t])
	if step == 2:
		_tut_snap_skipped = true
	_tut_resolve(step, "finished")


## "Skip tutorial" on the first card: never again, from here.
func _tut_skip_all() -> void:
	print("SAFARI tutorial SKIPPED BY THE PLAYER on card %d at t=%.4f (paused %.2f wall-s)" % [
		_tut_card + 1, _t, _wall - _tut_wall0])
	_tut_log.append("skip-all@%.1f" % _t)
	_tut_paused = false
	_tut_node.visible = false
	_tut_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tut_freeze_cabin_clock(false)
	_tut_done("skipped")


func _tut_done(why: String) -> void:
	GameState.flags[TUT_FLAG] = true
	_tut_on = false
	_tut_step = 4
	print("SAFARI tutorial DONE (%s): GameState.flags[\"%s\"] = true; cards [%s]; %.2f wall-s paused in all" % [
		why, TUT_FLAG, ", ".join(PackedStringArray(_tut_log)), _tut_paused_wall])


## A tap on the card layer. "Skip tutorial" is a button on card 1; anywhere else goes on.
func _tut_tap(pos: Vector2) -> void:
	if not _tut_paused or _tut_node == null:
		return
	if _wall - _tut_wall0 < TUT_TAP_GUARD:
		return
	var sk: Rect2 = _tut_node.button_rect("skip")
	if sk.size.x > 0.0 and sk.grow(6.0).has_point(pos):
		_tut_skip_all()
	else:
		_tut_resume("tap")


## A touch that began on the glass and ends on the card: its zone still has to be let go, or a
## thumb that was on the shutter reads as held for the rest of the flight.
func _tut_release(index: int) -> void:
	_zones.erase(index)
	if not _shutter_held():
		_armed = false


## SYNTHETIC: the policy reads a card for 1.2 s, then taps "Go on" (or "Skip tutorial", with
## `--pol-skip-tut`) - a real InputEventScreenTouch windowed, a direct `_tut_tap` headless.
func _tut_policy_paused() -> void:
	if not _tut_paused or _tut_node == null:
		return
	if _cap_dir != "" and not _tut_captured.has(_tut_card) and _wall - _tut_wall0 >= 0.6:
		_tut_captured[_tut_card] = true
		_tut_capture("tut%d" % (_tut_card + 1))
	if _wall - _tut_wall0 < 1.2:
		return
	if _tut_pol_sent >= 0.0 and _wall - _tut_pol_sent < 0.5:
		return
	_tut_pol_sent = _wall
	var which := "skip" if (_pol_skip_tut and tut_offers_skip()) else "go"
	var at: Vector2 = _tut_node.button_rect(which).get_center()
	if not _pol_real_input or DisplayServer.window_get_size().x <= 1:
		_tut_tap(at)
		return
	var stretch: Vector2 = Vector2(DisplayServer.window_get_size()) / _root.size
	for pressed in [true, false]:
		var ev := InputEventScreenTouch.new()
		ev.index = 9
		ev.position = at * stretch
		ev.pressed = pressed
		Input.parse_input_event(ev)


func _tut_capture(nm: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path: String = _cap_dir.path_join(nm + ".png")
	img.save_png(path)
	print("SAFARI shot %s t=%.2f (paused card %d) -> %s (%dx%d)" % [
		nm, _t, _tut_card + 1, path, img.get_width(), img.get_height()])
	_tut_print_geom(nm, img.get_width(), img.get_height())


## Where the card, its words and its pointers are on the saved frame, in DEVICE pixels, so a critic
## can crop the text and measure it instead of trusting the font size.
func _tut_print_geom(nm: String, iw: int, ih: int) -> void:
	var sx: float = float(iw) / maxf(_root.size.x, 1.0)
	var sy: float = float(ih) / maxf(_root.size.y, 1.0)
	var r: Rect2 = _tut_node.card_rect()
	print("TUTGEOM %s card device px x=%.0f..%.0f y=%.0f..%.0f; fonts title %.0f body %.0f button %.0f device px (font size, not ink)" % [
		nm, r.position.x * sx, r.end.x * sx, r.position.y * sy, r.end.y * sy,
		_tut_node.fs("title") * sy, _tut_node.fs("body") * sy, _tut_node.fs("button") * sy])
	for tg in tut_targets():
		print("TUTGEOM %s points at %s centre (%.0f,%.0f) ring r=%.0f device px" % [
			nm, str(tg["what"]), Vector2(tg["p"]).x * sx, Vector2(tg["p"]).y * sy, float(tg["r"]) * sy])
	for b in ["go", "skip"]:
		var br: Rect2 = _tut_node.button_rect(b)
		if br.size.x > 0.0:
			print("TUTGEOM %s button %s device px x=%.0f..%.0f y=%.0f..%.0f" % [
				nm, b, br.position.x * sx, br.end.x * sx, br.position.y * sy, br.end.y * sy])
	var ks: Array = [["knob", knob_xf()], ["shutter", shutter_xf()]]
	for kk in ks:
		var c: Vector2 = Vector2(kk[1][0])
		var rr: float = float(kk[1][1]) * 1.32
		var clear: bool = not r.grow(0.0).intersects(Rect2(c - Vector2(rr, rr), Vector2(rr, rr) * 2.0))
		print("TUTGEOM %s thumb %s zone clear of the card: %s" % [nm, kk[0], str(clear)])


## Where the sight being taught is on screen (UI units), or (-1e9, -1e9) when it is not on the glass.
func tut_subject_point() -> Vector2:
	var e := _find_cast(_tut_id)
	if e.is_empty() or is_caught(_tut_id):
		return Vector2(-1e9, -1e9)
	var f := field_of(e)
	if f.length() * SCORE_UNIT_DEG > field_half_deg() * 0.95:
		return Vector2(-1e9, -1e9)
	return glass_point(f)


func tutorial_paused() -> bool:
	return _tut_paused


func tutorial_card() -> int:
	return _tut_card if _tut_paused else -1


## "Skip tutorial" rides the first card a flight shows: card 1 on a first flight, or the first of
## the lessons still owed on a later one.
func tut_offers_skip() -> bool:
	return _tut_paused and _tut_shown == 1


## Wall seconds the tutorial has held the flight still. `landed(wall_seconds)` includes them; a
## flight that bills wall time must subtract these (NEEDS_FROM_OTHERS, G4b / safari_flight.gd).
func paused_wall_sec() -> float:
	return _tut_paused_wall


## "the Professor's lantern-fish", or just "the snow lane" for a sight nobody asked for.
func _tut_subject_words(cap: bool) -> String:
	var e := _find_cast(_tut_id)
	var nm := str(SafariCatalog.by_id(_tut_id).get("name", e.get("title", "that sight")))
	var comma := nm.find(",")
	if comma > 0:
		nm = nm.substr(0, comma)
	nm = nm.strip_edges()
	nm = nm.substr(0, 1).to_lower() + nm.substr(1)
	var who: String = str(_ask_by.get(_tut_id, ""))
	var out: String
	if who == "The Professor":
		out = "the Professor's " + nm
	elif who != "":
		out = "%s's %s" % [who, nm]
	else:
		out = nm if nm.begins_with("the ") or nm.begins_with("a ") else "the " + nm
	if cap:
		out = out.substr(0, 1).to_upper() + out.substr(1)
	return out


func tut_title() -> String:
	match _tut_card:
		0:
			return "You can spot it from far away"
		1:
			return "Zoom in"
		2:
			return "Take the picture"
		3:
			return "Film is limited"
	return ""


func tut_body() -> String:
	match _tut_card:
		0:
			if _tut_variant == "dab":
				return "%s is out there. The dab on the rim is a compass: top is straight ahead, bottom is behind you. Swing toward it; its little arrow shows how high." % _tut_subject_words(true)
			return "That soft ring is %s, still far off. Swing to keep it in the middle of the glass while it comes closer." % _tut_subject_words(false)
		1:
			return "%s is close enough now. Tap scope to raise the zoom lens and see it big." % _tut_subject_words(true)
		2:
			if _tut_variant == "tapped":
				return "You've been tapping - that's a quick snap. Keep your thumb on the shutter instead and the picture blooms into a better one."
			return "Tap the shutter for a quick snap. Or keep your thumb on it and the picture blooms - the longer you hold, the better it gets."
		3:
			var used: int = film_start - _film_left
			var lead := "That used 1 of your %d plates" % film_start if used == 1 \
				else "That was plate %d of your %d" % [used, film_start]
			return "%s - %d left. When they're gone, the camera is done for this trip, so pick your shots." % [
				lead, _film_left]
	return ""


## What the card points at, in UI units: [{"what", "p", "r"}].
func tut_targets() -> Array:
	var out: Array = []
	var k: float = _uis
	match _tut_card:
		0:
			var e := _find_cast(_tut_id)
			if e.is_empty():
				return out
			if _tut_variant != "dab":
				var f := field_of(e)
				if f.length() * SCORE_UNIT_DEG <= field_half_deg():
					out.append({"what": "the far mark", "p": glass_point(f),
						"r": maxf(mark_ring_px() * 1.9, 26.0 * k)})
			# the dab only when the mark is not on the glass: the rim is a heading compass (top =
			# straight ahead), so beside a mark on the glass it points somewhere else (critic round 1,
			# lantern-fish mark at 9 o'clock, its dab near 12)
			if _cockpit != null and out.is_empty():
				out.append({"what": "the collar dab", "p": _cockpit.dab_point(e),
					"r": _cockpit.collar_width() * 1.35})
		1:
			out.append({"what": "the scope control", "p": Vector2(scope_xf()[0]), "r": float(scope_xf()[1]) * 1.28})
		2:
			out.append({"what": "the shutter", "p": Vector2(shutter_xf()[0]), "r": float(shutter_xf()[1]) * 1.40})
		3:
			if _film_row != null:
				# a rounded box round the grid, not a circle: a circle big enough for 16 plates swallowed
				# the side port and the legend (first capture of card 4)
				var fr := Rect2(_film_row.position, _film_row.size).grow(10.0 * k)
				out.append({"what": "the film plates", "p": fr.get_center(),
					"r": fr.size.y * 0.5, "rect": fr})
	return out


# ---------------------------------------------------------------- the ask, for the cabin
## A score-unit offset (field_of's convention) as a point on screen, in UI units.
func glass_point(f: Vector2) -> Vector2:
	return _win.get_center() + f * glass_zoom() * (_win.size.y * 0.5)


## A far mark's ring radius on screen, in UI units: the shader's ring sits at 1.9 core radii and
## `_feed_marks` sends the core as MARK_DEG * 0.5 / field_half_deg() glass units.
func mark_ring_px() -> float:
	return 1.9 * MARK_DEG * 0.5 / field_half_deg() * (_win.size.y * 0.5)


func is_asked(id: String) -> bool:
	return _ask_by.has(id)


## "The Professor's ask", "Zorp's ask", or "".
func ask_label(id: String) -> String:
	if not _ask_by.has(id):
		return ""
	return "%s's ask" % str(_ask_by[id])


## Every asked sight whose far mark is on the glass this frame: [{"id", "p", "r", "a"}] in UI units.
## The same gates `_feed_marks` uses (up or inside the lead, uncaught, faded by the same handover to
## the real shape between 1.0 and 1.8 score units), so the sparkle is on exactly the marks drawn.
func ask_marks() -> Array:
	var out: Array = []
	if _phase != Ph.RUN or _marks_off:
		return out
	for id in _ask_by:
		var e := _find_cast(str(id))
		if e.is_empty() or is_caught(str(id)):
			continue
		if _t < float(e["t_start"]) - MARK_LEAD_SEC or _t > float(e["t_end"]):
			continue
		var f := field_of(e)
		var over: float = clampf((f.length() - 1.0) / 0.8, 0.0, 1.0)
		if over <= 0.0 or f.length() * SCORE_UNIT_DEG > field_half_deg():
			continue
		out.append({"id": str(id), "p": glass_point(f), "r": mark_ring_px(), "a": over})
	return out


## True while the boost button is on screen - the cabin clock closes the gap when it is not.
func boost_shown() -> bool:
	return _boost_btn != null and _boost_btn.visible


# ---------------------------------------------------------------- the card itself
## THE CARD. One Control over the whole screen, topmost in the cabin, drawn only while the flight is
## paused. It takes every touch while it is up (MOUSE_FILTER_STOP), so nothing reaches the glass:
## a tap anywhere goes on, and the first card has a "Skip tutorial" button.
##
## WHERE IT SITS, measured against the cabin rather than chosen: centred across the porthole, never
## wider than the disc, so both side columns - where the knob, the shutter and both thumbs are - stay
## uncovered (`_tut_print_geom` prints the check on every captured card). It goes to the top or the
## bottom of the disc, whichever is away from the thing it points at, so the sight stays visible.
## Text is 26 UI px for the body and 32 for the title at a 720-row UI: on the 2556x1179 phone frame
## (a 1.64x stretch) that is 43 and 52 device px of font.
class TutorialCard extends Control:
	var run: SafariRun
	var _rects: Dictionary = {}

	func fs(which: String) -> float:
		var k: float = run.ui_scale()
		match which:
			"title":
				return 32.0 * k
			"body":
				return 26.0 * k
			"button":
				return 26.0 * k
			"count":
				return 22.0 * k
		return 24.0 * k

	func card_rect() -> Rect2:
		_layout()
		return _rects.get("card", Rect2())

	func button_rect(which: String) -> Rect2:
		_layout()
		return _rects.get(which, Rect2())

	func _layout() -> void:
		_rects.clear()
		if run == null:
			return
		var k: float = run.ui_scale()
		var win: Rect2 = run.window_rect()
		var font: Font = UIStyle.ui_font()
		var w: float = minf(win.size.x * 0.92, 660.0 * k)
		var pad: float = 24.0 * k
		var th: float = font.get_height(int(fs("title")))
		var bs: Vector2 = font.get_multiline_string_size(run.tut_body(), HORIZONTAL_ALIGNMENT_LEFT,
			w - pad * 2.0, int(fs("body")))
		var bh: float = 58.0 * k
		var h: float = pad + th + 6.0 * k + bs.y + 18.0 * k + bh + pad
		# away from what it points at: the average height of the targets, against the disc's middle
		var ty := 0.0
		var tg: Array = run.tut_targets()
		for t in tg:
			ty += Vector2(t["p"]).y
		ty = ty / float(tg.size()) if not tg.is_empty() else win.end.y
		if run.tutorial_card() == 0 and not tg.is_empty():
			ty = Vector2(tg[0]["p"]).y
		# ...but never over the sight being taught: if it is on the glass, the card takes the other
		# half of the disc (measured: card 3 once covered the lantern-fish in the raised scope)
		var sp: Vector2 = run.tut_subject_point()
		if sp.x > -1e8:
			ty = sp.y
		var y0: float = win.position.y + 16.0 * k if ty > win.get_center().y \
			else win.end.y - h - 16.0 * k
		var card := Rect2(win.get_center().x - w * 0.5, y0, w, h)
		_rects["card"] = card
		_rects["title_at"] = Vector2(card.position.x + pad, card.position.y + pad + font.get_ascent(int(fs("title"))))
		_rects["body_at"] = Vector2(card.position.x + pad, card.position.y + pad + th + 6.0 * k
			+ font.get_ascent(int(fs("body"))))
		_rects["body_w"] = w - pad * 2.0
		var go_w: float = font.get_string_size("Go on", HORIZONTAL_ALIGNMENT_LEFT, -1, int(fs("button"))).x + 56.0 * k
		_rects["go"] = Rect2(card.end.x - pad - go_w, card.end.y - pad - bh, go_w, bh)
		if run.tut_offers_skip():
			var sk_w: float = font.get_string_size("Skip tutorial", HORIZONTAL_ALIGNMENT_LEFT, -1,
				int(fs("button"))).x + 40.0 * k
			_rects["skip"] = Rect2(card.position.x + pad, card.end.y - pad - bh, sk_w, bh)

	func _gui_input(event: InputEvent) -> void:
		if run == null or not run.tutorial_paused():
			return
		if event is InputEventScreenTouch:
			var t := event as InputEventScreenTouch
			if t.pressed:
				run._tut_tap(t.position)
			else:
				run._tut_release(t.index)
			accept_event()
		elif event is InputEventMouseButton and event.device != -1:
			var b := event as InputEventMouseButton
			if b.button_index == MOUSE_BUTTON_LEFT and b.pressed:
				run._tut_tap(b.position)
			elif b.button_index == MOUSE_BUTTON_LEFT:
				run._tut_release(-1)
			accept_event()
		elif event is InputEventScreenDrag or event is InputEventMouseMotion:
			accept_event()

	func _draw() -> void:
		if run == null or not run.tutorial_paused():
			return
		_layout()
		var k: float = run.ui_scale()
		var font: Font = UIStyle.ui_font()
		var card: Rect2 = _rects["card"]
		var pulse: float = 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * 0.0045)
		# the scrim: enough to say "stopped", not so much the sky cannot be read under it
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.06, 0.07, 0.13, 0.30))
		# the pointers, under the card
		for t in run.tut_targets():
			var p: Vector2 = t["p"]
			var r: float = t["r"]
			var from := Vector2(clampf(p.x, card.position.x, card.end.x), clampf(p.y, card.position.y, card.end.y))
			var tip := Vector2.ZERO
			if t.has("rect"):
				var tr: Rect2 = t["rect"]
				var box := StyleBoxFlat.new()
				box.bg_color = Color(SafariRun.C_GOLD, 0.10 + 0.08 * pulse)
				box.border_color = SafariRun.C_GOLD
				box.set_border_width_all(int(maxf(4.0 * k, 3.0)))
				box.set_corner_radius_all(int(14.0 * k))
				box.shadow_color = Color(SafariRun.C_NAVY, 0.45)
				box.shadow_size = int(4.0 * k)
				draw_style_box(box, tr)
				tip = Vector2(clampf(from.x, tr.position.x, tr.end.x), clampf(from.y, tr.position.y, tr.end.y))
			else:
				draw_circle(p, r * (1.10 + 0.10 * pulse), Color(SafariRun.C_GOLD.r, SafariRun.C_GOLD.g,
					SafariRun.C_GOLD.b, 0.10 + 0.08 * pulse))
				draw_arc(p, r, 0.0, TAU, 56, Color(SafariRun.C_NAVY, 0.55), 8.0 * k, true)
				draw_arc(p, r, 0.0, TAU, 56, SafariRun.C_GOLD, 4.0 * k, true)
				tip = p - (p - from).normalized() * (r + 4.0 * k)
			var dv: Vector2 = tip - from
			if dv.length() > 12.0 * k:
				var dir: Vector2 = dv.normalized()
				draw_line(from, tip, Color(SafariRun.C_NAVY, 0.55), 8.0 * k, true)
				draw_line(from, tip, SafariRun.C_GOLD, 4.0 * k, true)
				var side := Vector2(-dir.y, dir.x) * 11.0 * k
				var back: Vector2 = tip - dir * 20.0 * k
				draw_colored_polygon(PackedVector2Array([tip, back + side, back - side]), SafariRun.C_GOLD)
				draw_polyline(PackedVector2Array([tip, back + side, back - side, tip]),
					Color(SafariRun.C_NAVY, 0.55), 2.0, true)
		# the card
		var sb := StyleBoxFlat.new()
		sb.bg_color = SafariRun.C_CREAM
		sb.border_color = SafariRun.C_AMBER
		sb.set_border_width_all(int(maxf(3.0 * k, 2.0)))
		sb.set_corner_radius_all(int(22.0 * k))
		sb.shadow_color = Color(0.0, 0.0, 0.0, 0.30)
		sb.shadow_size = int(10.0 * k)
		draw_style_box(sb, card)
		var pad: float = 24.0 * k
		draw_string(font, _rects["title_at"], run.tut_title(), HORIZONTAL_ALIGNMENT_LEFT, -1.0,
			int(fs("title")), SafariRun.C_TEXT)
		var cnt := "%d of 4" % (run.tutorial_card() + 1)
		var cw: float = font.get_string_size(cnt, HORIZONTAL_ALIGNMENT_LEFT, -1, int(fs("count"))).x
		draw_string(font, Vector2(card.end.x - pad - cw, Vector2(_rects["title_at"]).y), cnt,
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, int(fs("count")), SafariRun.C_SOFT)
		draw_multiline_string(font, _rects["body_at"], run.tut_body(), HORIZONTAL_ALIGNMENT_LEFT,
			float(_rects["body_w"]), int(fs("body")), -1, SafariRun.C_TEXT)
		# the buttons
		var go: Rect2 = _rects["go"]
		var gsb := StyleBoxFlat.new()
		gsb.bg_color = SafariRun.C_AMBER
		gsb.border_color = SafariRun.C_BRASS_D
		gsb.set_border_width_all(2)
		gsb.set_corner_radius_all(int(go.size.y * 0.5))
		draw_style_box(gsb, go)
		_label_in(font, go, "Go on", SafariRun.C_TEXT)
		if _rects.has("skip"):
			var skr: Rect2 = _rects["skip"]
			var ssb := StyleBoxFlat.new()
			ssb.bg_color = Color(SafariRun.C_CREAM, 0.0)
			ssb.border_color = SafariRun.C_SOFT
			ssb.set_border_width_all(2)
			ssb.set_corner_radius_all(int(skr.size.y * 0.5))
			draw_style_box(ssb, skr)
			_label_in(font, skr, "Skip tutorial", SafariRun.C_SOFT.darkened(0.25))

	func _label_in(font: Font, r: Rect2, txt: String, col: Color) -> void:
		var f := int(fs("button"))
		var tw: float = font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, f).x
		var base: float = r.position.y + (r.size.y + font.get_ascent(f) - font.get_descent(f)) * 0.5
		draw_string(font, Vector2(r.get_center().x - tw * 0.5, base), txt, HORIZONTAL_ALIGNMENT_LEFT,
			-1.0, f, col)


# ================================================================== debug hooks (SYNTHETIC)
## Plates left in THIS run. Read by `safari_flight.gd` once, after `landed` fires, to work out
## how many of the plates it loaded were actually spent.
func film_left() -> int:
	return _film_left


func debug_state() -> int:
	return _phase


func debug_time() -> float:
	return _t


func debug_aim(az: float, el: float) -> void:
	_az = wrapf(az, -180.0, 180.0)
	_el = clampf(el, _el_min, _el_max)


func debug_focus(v: float) -> void:
	_focus = clampf(v, 0.0, 1.0)


func debug_haul() -> Array:
	return _haul


func debug_track(id: String) -> Dictionary:
	return _track.get(id, {})


func debug_live_ids() -> Array:
	var out: Array = []
	for l in _live:
		out.append(str(l["e"]["id"]))
	return out


# ================================================================== the cabin
## The LOOK lives in src/sky/safari_cockpit.gd: warm white hull, one big ROUND porthole, a range knob and a
## shutter, and the direction ribbon on the top rail. The brass spyglass rim that used to float in
## black space is gone; its knob is the one thing kept, now a real control on the panel.
