extends Node
## FRIENDS VISIT YOUR CRASH SITE (docs/CORE_LOOP.md "Visits and favours", decided 2026-09-13;
## docs/BUILD_PLAN.md Phase 4 builder H). The user: "No mayor. Neighbours visit your crash site and ask
## you for things themselves."
##
## Some game days, one neighbour is standing near the crash site when you are at home. They ask for ONE
## thing that needs no flight: play their mini-game on your planet, or place a gift they brought. Flying
## away ends the visit, so a neighbour is always at home when you fly to their world.
##
## ============================================================================== WHERE IT LIVES
## ONE NODE PER WORLD, made by the single guarded hook at the end of world.gd `_ready`:
##
##     if ResourceLoader.exists(VISITOR_SYSTEM_PATH):
##         load(VISITOR_SYSTEM_PATH).attach(self)
##
## It is /root/World/VisitorSystem and it dies with the world, and so does the visitor (an ordinary
## neighbour scene, res://src/characters/npcs/<id>.tscn, added under /root/World/NPCs). On home it
## decides today's visit and stands the visitor; on every OTHER world it only marks today's visit as
## ended ("flying away ends the visit"). Nothing else in the game names this file statically:
## conversation.gd and npc.gd reach it through the NPC's `visit_host` field, and dev_menu.gd by path.
##
## ============================================================================== WHO AND WHEN
##   * Only the five story neighbours (CampaignData.PARTS: zorp, bolt, fen, grig, vela), and only once
##     their project has started (GameState.projects has them). The Commons crowd never visits.
##   * Only on home, and only while the campaign is on or the story is over (`visits_on`). A Director
##     timeline sees no visits unless it passes "--campaign", the same opt-in as every campaign gate.
##   * AT MOST ONE VISIT PER GAME DAY, chosen by rolls SEEDED BY THE DAY, never by the clock or a live
##     position (`is_visit_day`, `roll_visitor`):
##       - the days are cut into blocks of VISIT_EVERY_DAYS; one day in each block, picked by a roll
##         seeded by the block, is a visit day. It ships at 1 (since 2026-09-19 and the 25 minute day),
##         so every game day is a visit day - one visitor per 25 real minutes. With 2 it was exactly one
##         visit day in every two, never more than three days apart;
##       - on a visit day a second roll, seeded by the day, picks one eligible neighbour, leaving out
##         yesterday's visitor, so nobody comes two days running - UNLESS yesterday's visitor is the
##         only eligible neighbour, in which case they come again rather than the day being empty
##         (`roll_visitor` says why). That exception is the whole early campaign: one eligible
##         neighbour until you have flown out and started a second project.
##     The result is written the first time you are at home that day (`ensure_today`), and a written day
##     is never rolled again, so a reload can never reroll it and a finished visit stays finished.
##   * Never while the crash intro or Professor Comet's radio call owns the screen (`_onboarding_busy`):
##     a home load before the call has happened gets no visit that stay, and writes nothing.
##   * THE DAY TURNING OVER WHILE YOU STAND AT HOME BRINGS THE NEW DAY'S VISITOR (2026-09-19, the lead's
##     ruling after the 25-minute day: a day is now 25 real minutes, so standing at home through a whole
##     new day and meeting nobody is most of an evening). `_on_time_of_day` watches GameState.day_count
##     (EventBus.time_of_day_changed, ~every 0.05 h = ~3 real s), and on home the handover runs as soon
##     as the world is calm (`_handover_calm`: no flight, no modal or talk, no mini-game, no onboarding):
##       1. yesterday's visitor is marked left, waves and WALKS OUT OF SHOT, and is removed the moment
##          the camera has lost them - NEVER while it can still see them (`_send_off`);
##       2. the new day is rolled by the same `ensure_today` the load path uses (so it is the same one
##          visit a day, the same "not two days running" rule, and a reload that day keeps it);
##       3. the visitor WALKS IN FROM OFF-CAMERA (`_entry_dir`, `_walk_tick`): they are placed
##          ENTRY_TRIES_M away at a point the camera cannot see - outside the frustum OR behind the
##          planet's own horizon (`_on_camera`, `_hidden_by_planet`) - and stroll to the spot. If
##          every way in is in shot AND so is the spot, NOBODY IS STOOD: the arrival waits and goes on
##          looking, a slice of a frame at a time (`_try_arrive`, ARRIVE_BUDGET_USEC), until the camera
##          leaves it a gap. Nobody pops into existence inside the frame.
##     The load path (`_ready` -> `ensure_today` -> `_bring_in`) is untouched and still stands the
##     visitor at their spot with no walk.
##   * FLYING AWAY ENDS IT: EventBus.travel_started from home, and any load of another world, set "left".
##     A visit that has left never comes back that day, done or not.
##
## ============================================================================== THE REQUEST
## One per visit, planned when the day is written (`_plan_request`, seeded by day and neighbour):
##   PLAY  only when that neighbour's mini-game is unlocked (ProjectSystem.played_minigames()), about
##         PLAY_CHANCE of the time. It runs on home with the story step's own config, minus the keys that
##         only fit their world ("home_dir", "near", "center_dir", "dirs"), with "npc" set to the visitor
##         (the caller of "call"), a count of min(story count, VISIT_COUNT_MAX[kind]), and the owner
##         "visit:<npc>:<day>". Rings and hunt get "near" = the visitor's spot, so the course and the
##         search start by the visitor rather than on the far side of the planet. The game starts when
##         the request is asked, restarts on a reload or after being cancelled (on the next talk), and
##         its progress is written to the visit flag on every `progress_changed`, the same rule the
##         project system follows: the count is the truth, never the finish signal.
##   GIFT  otherwise. The visitor hands over one decoration from visitor_lines.gd GIFTS (existing shop
##         items; the file says which and why). The visit is met once an instance of that item stands
##         on home that was not standing there when it was handed over. A dropped gift is replaced.
## Talking again once it is met hands it in: friendship +VISIT_FRIENDSHIP and +VISIT_STARDUST stardust.
## Later talks that day get a goodbye line.
##
## TALK: conversation.gd sends every talk with the visitor here (`handle_conversation`) - never to their
## project, a light link, a favour or small talk. Lines live in visitor_lines.gd, in each neighbour's
## own voice, <= 60 characters, 1-3 per list. THE "!": npc.gd asks `wants_marker` - shown while the
## request waits to be asked, and again once it is met and waits to be handed in.
##
## ============================================================================== SAVED STATE
## ONE JSON-safe flag, GameState.flags["visit_today"], and no new GameState field. It holds the most
## recently written day (JSON gives ints back as floats; `record` normalises every read):
##   {"day": int, "npc": id or "" (no visit that day), "kind": "play"|"gift"|"",
##    "game": kind, "step": story step index, "count": int, "progress": int,
##    "item": catalog id, "before": [instance ids of that item already on home when it was handed over],
##    "asked": bool, "done": bool, "left": bool, "forced": bool (dev menu),
##    "spot": [x,y,z] planet-local direction the visitor stands at, or []}
## The spot is saved so a reload stands the visitor in the same place; it is re-checked against the
## ground rules on every load and picked again only if something (a decoration) now stands on it.
##
## ============================================================================== WHERE THEY STAND
## `_pick_spot`, run once per home load (and never when the saved spot still passes):
##   1. "framed": a SEARCH_STEP_M lattice in front of the rocket-landing spot (world.gd puts the
##      astronaut LANDING_SIDE_M off the pad, facing away from it), IN AN ORDER ROLLED FROM THE DAY
##      (`_day_shuffle`), so the visit is not in the same square of grass every time - a fixed order
##      gave 1 distinct spot in 30 days.
##      A spot passes when the ground rules pass AND both landing cameras (phone and desktop, rebuilt from
##      camera_rig.gd's own numbers, as replay_board_prop.gd does) have the visitor - where they stand and
##      at WANDER_RING points round the rim of their wander patch - inside the safe part of the frame, with
##      every sight line clear of the real triangles of props, decorations, the house, the pad, the rocket
##      at rest, the bench, space trash and the landed astronaut (glow sprites hide nothing: `_is_glow`).
##   2. "framed-spot": the same lattice, when a crowded yard leaves nothing for pass 1: the whole wander
##      patch still inside the frame, but only the sight lines to where they stand have to be clear.
##   3. "near": the ground rules alone on a wider lattice round the landing spot.
##   4. "anywhere": the ground rules alone over the whole planet, nearest the landing spot first.
## THE GROUND RULES (`_ground_problem`): dry, not at the shore; PAD_CLEAR_M from the pad centre (the pad
## disc and its paving); SPAWN_CLEAR_M from the spawn; LANDING_CLEAR_M from the landing spot; off the
## stepping stones (TRAIL_CLEAR_M from their line, over the stretch they cover); HOUSE_CLEAR_M from the
## house; out of every prompt's reach (the bench, the mailbox, the door, the pad) by PROMPT_GAP_M; clear
## of props, decorations, pickups and space trash; level enough to stand on.
## WANDERING A LITTLE: the visitor's wander radius is WANDER_M (npc.gd samples 1.4-1.6 m out), and npc.gd
## asks `wander_ok` for every wander target and every path sample, so they never walk onto anything the
## ground rules keep them off either.
##
## ============================================================================== DEPENDENCIES
## ProjectSystem and MinigameSystem are reached by PATH only (a file that can ship without its dependency
## never names that class statically). Everything else used here ships in every build since Phase 1.

const NODE_NAME := "VisitorSystem"
const SCRIPT_PATH := "res://src/campaign/visitor_system.gd"
const DATA := preload("res://src/campaign/visitor_lines.gd")
const PROJECT_SYSTEM_PATH := "res://src/projects/project_system.gd"
const MINIGAME_SYSTEM_PATH := "res://src/minigames/minigame_system.gd"
const CAMERA_RIG_PATH := "res://src/player/camera_rig.gd"
const NPC_DIR := "res://src/characters/npcs/"
const HOME_ID := "home"
const FLAG_KEY := "visit_today"
const OWNER_PREFIX := "visit:"

## ---- PHASE 6 PACING NUMBERS (docs/BUILD_PLAN.md "Phase 6: Pacing pass"): first guesses, to be tuned
## from a timed play-through. None of them is a promise to the player.
## One visit day in every this many game days.
##
## WAS 2 ("about every other day") while a game day was 600 real seconds - a visitor every ~20 real
## minutes. 2026-09-19 the day became 1500 s (environment.gd DAY_LENGTH_SEC), so 2 would have meant a
## visitor every ~50 real minutes. 1 keeps roughly the real-time feel the user already has: EVERY game
## day is a visit day, one visitor per 25 real minutes.
##
## At 1 `is_visit_day` below is degenerate and always true (d0 % 1 == 0, and randi_range(0, 0) == 0),
## which is exactly what is wanted and needs no special case. Still at most one visit per game day
## (one record per day), and `roll_visitor` still leaves out yesterday's visitor when it can, so nobody
## comes two days running while two or more neighbours are eligible.
##
## MEASURED over 100 days through the real `ensure_today` (2026-09-19, round 2), by how many
## neighbours are eligible - one visitor per this many REAL minutes:
##     eligible 1: 25.0    2: 25.0    3: 25.0    5: 25.0
## Eligible 1 only holds because of the "only eligible one comes again" exception in `roll_visitor`;
## without it the opening measured 50.0 real minutes, worse than the 27.8 it had at a 600 s day.
const VISIT_EVERY_DAYS := 1
## How often a visitor whose game is unlocked asks for the game rather than a gift.
const PLAY_CHANCE := 0.5
## Friendship for a visit handed in. A project step gives 5 (ProjectSystem.FRIENDSHIP_PER_STEP), a favour 2.
const VISIT_FRIENDSHIP := 3
## Stardust for a visit handed in. A replay pays 10 (replay_board.gd), a favour 60-140 (being reworked).
const VISIT_STARDUST := 15
## A visit's game is never longer than the story's, and shorter where the story's is long. The ring run
## cannot go under 4 (ring_game.gd COUNT_RANGE).
const VISIT_COUNT_MAX := {"catch": 3, "rings": 4, "guide": 3, "hunt": 2, "call": 2}

## ---- placement (see "WHERE THEY STAND")
## world.gd `_spawn_player`: a rocket arrival stands the astronaut this far off the pad centre.
const LANDING_SIDE_M := 3.2
const WANDER_M := 1.6
const SEARCH_STEP_M := 0.4
const AHEAD_MIN_M := 3.2
const AHEAD_MAX_M := 9.0
const SIDE_MAX_M := 5.0
## The seed the day's search order is rolled from (see `_day_shuffle`). The old fixed ideal - 4.0 m
## ahead, 2.4 m to the spawn side - is gone: it named a side of the yard where not one square passes
## the frame rules anyway, and a fixed order meant every visit in the same square of grass.
const SPOT_SEED := "astro_visit_spot"
const NEAR_MAX_M := 12.0
## rocket_pad.gd PAD_R 2.55 m of disc + its paving (planet.gd PAD_FLAT_RADIUS 4.0) + a body.
const PAD_CLEAR_M := 4.6
## A loaded save stands the player at the spawn; planet.gd SPAWN_FLAT_RADIUS 3.0 + the 0.6 m it reserves.
const SPAWN_CLEAR_M := 3.6
## Out of the landed astronaut's face: NPC.TALK_REACH 2.2 + a body + a step, so the landing prompt is Fly.
const LANDING_CLEAR_M := 3.2
## The stones: 0.5 m stone radius + a 0.34 m body + 0.46 m to walk past (replay_board_prop.gd keeps 2.05
## for a 0.95 m board).
const TRAIL_CLEAR_M := 1.3
## planet.gd reserves HOME_BUILDING_FLAT_RADIUS 5.0 + 1.0 round the house.
const HOUSE_CLEAR_M := 6.0
const PROMPT_GAP_M := 0.8
const PROP_CLEAR_M := 0.6
const DECO_GAP_M := 0.6
const PICKUP_CLEAR_M := 0.9
const TRASH_CLEAR_M := 1.1
const MAX_SLOPE_DEG := 14.0
const MAX_RIM_DH_M := 0.2
const RIM_M := 0.5
## ---- the landing frame (the same numbers replay_board_prop.gd was measured against)
const LANDING_FOV_DEG := 45.0
const VIEW_ASPECTS := {"mobile": 1560.0 / 720.0, "desktop": 1280.0 / 720.0}
const VIEW_SAFE := {"mobile": Rect2(-0.6, -0.5, 1.2, 1.3), "desktop": Rect2(-0.85, -0.55, 1.7, 1.35)}
const VIEW_KEEP_OUT := {"mobile": Rect2(-0.14, 0.6, 0.28, 0.4)}
## Visitor column: sight lines to these heights at these side offsets; the frame test uses the column's
## corners. The tallest visitor (Grig's eye stalk) reaches 1.77 m.
const SIGHT_HEIGHTS: Array[float] = [0.5, 0.95, 1.35]
const SIGHT_SIDES: Array[float] = [-0.22, 0.0, 0.22]
const COLUMN_TOP_M := 1.8
## Points round the rim of the wander patch that the frame rule also checks.
const WANDER_RING := 8
const COLUMN_HALF_M := 0.4
const LOW_MESH_M := 0.4
const ASTRONAUT_RADIUS_M := 0.45
const ASTRONAUT_HEIGHT_M := 1.6
const PAD_DECK_Y := 0.10

## ---- the day turning over while you stand at home (see "WHO AND WHEN")
## Bearings tried round the spot, from "straight away from the camera" outwards (see `_entry_dir`).
## MEASURED 2026-09-20: at 16 the search fell back to the one bearing straight back past the player in
## a third of the aimed cases; at 24 it slips between the house and the props instead, and every entry
## point it found was outside the frame by 7% of its width or more (median 49%), up from -20%/29%.
const ENTRY_BEARINGS := 24
## How far from the PLAYER an entry point is kept if there is any choice (see `_entry_dir`). Not a
## hard rule: a yard with nowhere else still gets somebody walking in rather than nobody coming.
const ENTRY_PLAYER_M := 6.0
## How far round the planet the arriving visitor is placed before walking in, longest first. On home
## (12-18 m radius) the horizon from a standing camera is only about 8-9 m away, so the two longest
## distances are the ones that put somebody GENUINELY behind the bulge rather than merely outside the
## frustum; 14 m at npc.gd's walk_speed 2.2 m/s is a ~6.4 s walk, inside npc.gd's WANDER_TIMEOUT 14 s
## safety net and WALK_MAX_S. The shorter ones are for a crowded yard: MEASURED 2026-09-19, at 9 m the
## house (10 of 16 bearings) and the props (8) leave nothing, so distance alone is not enough either.
const ENTRY_TRIES_M: Array[float] = [14.0, 11.5, 9.0, 7.0, 5.0]
## The walk-in path is sampled this often and every sample must pass `_walk_problem`.
const PATH_STEP_M := 0.5
## ---- `_walk_problem`: what may not be WALKED OVER, which is not what `_ground_problem` measures.
## Those are staging clearances for somebody who STANDS there all day (6 m from the house, 4.6 m from
## the pad, 0.6 m from a prop); the player walks over all of that every minute. These are body-width
## gaps against the things that would actually clip or soak: the pad disc and the house themselves,
## props and decorations (`nearest_prop_distance` already subtracts the prop's own radius), trash,
## and water.
const WALK_PAD_M := 2.7
const WALK_HOUSE_M := 3.2
const WALK_PROP_M := 0.4
const WALK_DECO_GAP_M := 0.4
const WALK_TRASH_M := 0.7
## Two points of the arriving visitor's body are tested against the live camera; both must be out of
## sight for the entry point to count as off-camera. "Out of sight" is the frustum AND THE PLANET
## ITSELF: see `_on_camera`.
const ENTRY_EYE_M := 1.6
## ---- the horizon (`_hidden_by_planet`, 2026-09-20; `docs/OPEN_ISSUES.md` 66)
## Camera.is_position_in_frustum is a test against the frustum VOLUME, which on a 12-18 m planet
## reaches right through the world: a point on the far side of the horizon is "in the frustum" while
## the ground hides it. That one missing test rejected ALL 48 entry candidates whenever the camera
## looked along the ground (MEASURED 6 of 10 on-screen yaws, windowed gl_compatibility, 2026-09-19
## critic), so the visitor was stood at their spot in frame. The sight line from the camera to the
## body point is now walked in steps and compared with the real terrain height under each step.
const HORIZON_STEP_M := 0.35
## How far under the ground the sight line must dip to count as blocked. A margin (rather than 0)
## keeps the test CONSERVATIVE: a line that merely grazes the bulge still counts as visible, so the
## error is always "we think they can be seen", never "we spawn someone in view".
const HORIZON_CLEAR_M := 0.25
## ---- what a WAITING visitor may cost per frame (2026-09-20)
## WAS: the whole 4 x ENTRY_BEARINGS x ENTRY_TRIES_M sweep re-run from scratch once a second
## (ARRIVE_RETRY_S 1.0). MEASURED by the critic that day: 12.2 ms warm and 20.0-21.4 ms cold against a
## 16.6 ms phone frame - a visible hitch once a second, for as long as the player kept the camera
## moving. Re-measured here with every candidate forced to fail (`debug_hold_arrival`, the upper bound
## that also pays `_path_blocker` on all 120): 35.9-45.8 ms per search, windowed gl_compatibility.
##
## THE SEARCH IS NOW SPREAD OVER FRAMES INSTEAD OF BATCHED ONCE A SECOND, and the half of it that
## cannot change while the player only moves the camera is remembered:
##   * the candidate ring (ENTRY_BEARINGS x ENTRY_TRIES_M points round the spot) is built once per
##     arrival, on the planet's OWN tangent frame rather than the camera's, so the points are the same
##     from frame to frame and can be cached at all (`_entry_build`);
##   * each point's `_walk_problem` verdict and its `_path_blocker` verdict are terrain, props,
##     decorations and trash only - no camera in either - so they are worked out ONCE per arrival and
##     re-used by every later pass (`_entry_pts`). Those two were the whole cost;
##   * only the visibility test (`_in_frustum` / `_on_camera`) is re-run, and it is re-run against the
##     LIVE camera at the instant each candidate is reached, so a candidate is never accepted on a
##     stale answer;
##   * the scan stops when it has used ARRIVE_BUDGET_USEC of the frame and carries on next frame, so
##     the cost per frame is capped no matter how long the sweep is.
## The player also stops waiting a whole second for a gap: the scan runs every frame, so the visitor
## comes in as soon as the camera looks away. A camera that sits perfectly still still costs nothing
## (`_arrive_stuck`).
##
## The budget is a SCHEDULING cap, not a tuned gain: nothing about the ANSWER changes if it is raised
## or lowered, only how many frames a sweep is spread over. It is set low on measurement, not taste.
## MEASURED 2026-09-20, windowed gl_compatibility, camera turning every frame, timing lock held, the
## arrival forced to keep waiting (`debug_hold_arrival`), 5000 measured frames a run:
##     800 us: this node 0.61-0.70 ms a frame (max 0.94) - but 9 of 13 runs had ONE ~84 ms frame,
##             at no fixed time and never twice in a run. Nothing in the engine's own accounting owned
##             it (TIME_PROCESS 3.9-5.0 ms, TIME_PHYSICS_PROCESS 0.3 ms, 64 draw calls, object count
##             flat, this node's own `_process` 0.4-0.9 ms in that very frame). Caching the sweep plan
##             did not remove it; a run with NO pending arrival but the same camera turn, the same
##             length and the same day rollover never showed it in 10 runs. So: real, caused by the
##             scanning, and NOT understood - which is why the budget is set by what stops it rather
##             than by a story about what it is.
##     200 us: this node 0.21-0.22 ms a frame (max 0.34), frame max 3.47-4.50 ms, and 0 of 5 runs -
##             ~52 s of solid scanning - had a frame over 8 ms, let alone 84.
## The cost of 200 us is only patience: one sweep is about 6 ms of work, so it takes ~30 frames, a
## half-second at 60 fps, for the arrival to notice a gap. The version this replaced took up to a full
## second AND cost 12-45 ms in the frame it took.
const ARRIVE_BUDGET_USEC := 200
## After this long the see-off stops re-aiming yesterday's visitor and simply waits for the camera to
## lose them. They are NEVER removed while the camera can see them (the lead's ruling, 2026-09-19).
const SEE_OFF_RETRY_S := 2.5
## The walk-in gives up and settles the visitor where they stand after this long (npc.gd's own stroll
## timeout is 14 s; this is the outer net for a stroll that never started).
const WALK_MAX_S := 16.0
## Yesterday's visitor waves, walks out of shot and is gone the moment the camera loses them. The step
## and the cap are only for a yard with nowhere out of shot (see `_send_off`).
const LEAVE_STEP_M := 3.5
const SEE_OFF_MAX_S := 12.0
## The see-off only starts checking the camera after this long, so a wave is always seen.
const SEE_OFF_MIN_S := 1.2

var planet: Planet
## The visitor standing on this world now, or null.
var visitor: NPC
## Which pass of `_pick_spot` stood the visitor ("saved" when the saved spot still passed), and a note.
var spot_pass := ""
var spot_note := ""
var search_usec := 0
## QA (see "QA"): microseconds this node spent in its own `_process` last frame - what a critic pairs
## against a stay with no waiting visitor - and a switch that makes the arrival search refuse every
## answer, so the waiting state can be held open and measured on demand.
var tick_usec := 0
var debug_hold_arrival := false
## Was the point the visitor was last put down at inside the live camera's view? (see `_spawn_visitor`)
var debug_spawn_seen := false

var _owner := ""
var _game_pending := false
## ---- the day turning over while you stand at home (never saved: all of it is one stay's staging)
## The day this world's staging is for. A bigger GameState.day_count means the clock rolled over.
var _day_seen := 0
## A rolled-over day is waiting to be handed over (the world was not calm yet, or the old visitor is
## still walking off).
var _rollover_due := false
var _seeing_off := false
var _see_off_t := 0.0
var _see_off_aim_t := 0.0
var _see_off_waiting := false
## Today's visitor is rolled and written but not stood yet: every way in was in shot and so was the
## spot, so the arrival waits for the camera (see `_try_arrive`). Never saved - the day is.
var _arrive_due := false
var _arrive_t := 0.0
var _arrive_said := false
## The spot this arrival's candidate ring was built for (Vector3.ZERO: not built yet), and "something
## on the ground moved, work the spot and the ring out again".
var _arrive_spot := Vector3.ZERO
var _arrive_dirty := false
## The camera the last failed search was answered for. Nothing about the answer can change while the
## camera sits still, so a player standing perfectly still pays nothing to go on waiting.
var _arrive_cam := Transform3D()
var _arrive_stuck := false
## The arriving visitor is walking in from off-camera.
var _walk_in := false
var _walk_started := false
var _walk_t := 0.0
var _walk_target := Vector3.ZERO
var _walk_note := ""
## `_entry_dir`'s last search: reason -> how many bearings it turned down.
var _entry_tally := {}
## The candidate ring round `_arrive_spot`: one entry per (distance, bearing), each remembering its own
## camera-free verdicts. "?" means "not asked yet"; every other value is the cached answer.
## {"dir": Vector3, "out_m": float, "j": int, "ground": String, "path": String}
var _entry_pts: Array[Dictionary] = []
var _entry_spot := Vector3.ZERO
## One pass over the ring: the order the sweeps visit it, where the cursor is, and the camera and
## player the pass was planned for (a pass that ends empty is not re-run until one of them moves).
var _scan_plan: PackedInt32Array = PackedInt32Array()
## The bearing the current plan was laid out from (-1: no plan yet). The plan is the same list of
## indices for the same bearing, so it is only rebuilt when the camera has actually swung far enough
## to change it - see `_scan_begin`.
var _scan_j0 := -1
var _scan_i := 0
var _scan_cam := Transform3D()
var _scan_player := Vector3.ZERO
var _views: Array[Dictionary] = []
var _landing_dir := Vector3.ZERO
var _away := Vector3.ZERO
var _astronaut_xf := Transform3D.IDENTITY
var _deco_cache: Array[Dictionary] = []
var _prompts: Array[Dictionary] = []
var _space := RID()
var _sight_bodies: Array[RID] = []
var _sight_shapes: Array = []
## Sight body RID -> the node it was built from, for `debug_spot_report` ("what hides them").
var _sight_names: Dictionary = {}


# ============================================================================= entry points
## Called once per world by world.gd. Returns the host (also for a test rig).
static func attach(world: Node) -> Node:
	if world == null or not world.is_inside_tree():
		return null
	var existing := world.get_node_or_null(NODE_NAME)
	if existing != null:
		return existing
	var host: Node = (load(SCRIPT_PATH) as GDScript).new()
	host.name = NODE_NAME
	world.add_child(host)
	return host


## The world's VisitorSystem, or null (no world, or a build without the hook).
static func find() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("World/" + NODE_NAME)


func _ready() -> void:
	planet = get_tree().get_first_node_in_group("planet") as Planet
	EventBus.travel_started.connect(_on_travel_started)
	EventBus.ui_modal_closed.connect(_on_modal_closed)
	EventBus.decoration_placed.connect(_on_decoration_placed)
	EventBus.decoration_removed.connect(_on_decoration_removed)
	EventBus.time_of_day_changed.connect(_on_time_of_day)
	_day_seen = GameState.day_count
	set_process(false)
	if GameState.current_planet_id != HOME_ID:
		mark_left("landed on " + GameState.current_planet_id)
		return
	if planet == null:
		return
	if _onboarding_busy():
		print("VisitorSystem: the intro owns the screen; no visit this stay")
		return
	var rec := ensure_today()
	if rec.is_empty() or str(rec["npc"]) == "" or bool(rec["left"]):
		return
	_bring_in(rec)


func _exit_tree() -> void:
	_close_sight_space()


# ============================================================================= the day
## True when visits can happen at all: the campaign is on, or the story is over (a Director timeline only
## with "--campaign") - EXCEPT while the finale owns the screen. docs/PHASE5_SPEC.md §1:
## GameState.flags["finale_stage"] (JSON gives floats back, so always read through int()) is 1 CALLED,
## 2 MET or 3 SENT for the call/meeting/choice/send-off/gift beats; nobody should wander in mid-finale.
## Unaffected at stage 0 (before the call) or 4 (DONE): a visit still rolls at home then, same as today.
static func visits_on() -> bool:
	var finale_stage := int(GameState.flags.get("finale_stage", 0))
	if finale_stage == 1 or finale_stage == 2 or finale_stage == 3:
		return false
	if CampaignData.gates_on():
		return true
	return GameState.story_done and (not Director.is_active() or Director.campaign_opt_in())


## The story neighbours who may visit: their project has started. In CampaignData.PARTS order.
static func eligible_neighbours() -> PackedStringArray:
	var out := PackedStringArray()
	for p: Dictionary in CampaignData.PARTS:
		var npc := str(p.get("npc", ""))
		if npc == "" or not GameState.projects.has(npc):
			continue
		if not ResourceLoader.exists(NPC_DIR + npc + ".tscn"):
			continue
		if ResourceLoader.exists(PROJECT_SYSTEM_PATH):
			var d: Variant = load(PROJECT_SYSTEM_PATH).call("definition_for", npc)
			if not (d is Dictionary) or (d as Dictionary).is_empty():
				continue
		out.append(npc)
	return out


## True when `day` is its block's visit day (see "WHO AND WHEN"). Pure: depends on the day alone.
static func is_visit_day(day: int) -> bool:
	var d0 := maxi(day, 1) - 1
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(["astro_visit_day", d0 / VISIT_EVERY_DAYS])
	return d0 % VISIT_EVERY_DAYS == rng.randi_range(0, VISIT_EVERY_DAYS - 1)


## Who visits on `day` ("" for nobody). Pure: the day, who may come, and yesterday's visitor.
##
## "Not two days running" is a VARIETY rule, not a silence rule. With two or more eligible neighbours
## dropping yesterday's always leaves someone, so it costs nothing. With exactly ONE eligible - the
## whole opening, from your first neighbour until you have flown out and started a second project -
## dropping them empties the pool and NOBODY comes. At VISIT_EVERY_DAYS 2 that was hidden (the
## in-between day was not a visit day anyway); at 1 it bit every other day, and measured over 100 days
## it made the opening 1 visit per 2.00 game days = 50 real minutes, SLOWER than the 27.8 real minutes
## it was before the 25-minute day (2026-09-19 critic round 1, re-measured here). So when yesterday's
## visitor is the only eligible one, they come again: one lonely friend is better than an empty day.
static func roll_visitor(day: int, eligible: PackedStringArray, yesterday: String) -> String:
	if not is_visit_day(day):
		return ""
	var pool: Array[String] = []
	for n: String in eligible:
		if n != yesterday:
			pool.append(n)
	if pool.is_empty():
		## Only reachable when eligible is empty (nobody to come) or eligible == [yesterday].
		for n: String in eligible:
			pool.append(n)
	if pool.is_empty():
		return ""
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(["astro_visit_who", day])
	return pool[rng.randi_range(0, pool.size() - 1)]


## Today's visit record, rolled and written the first time it is asked for on this game day. {} when
## visits are off (nothing is written then).
static func ensure_today() -> Dictionary:
	var rec := record()
	var day := GameState.day_count
	if not rec.is_empty() and int(rec["day"]) == day:
		return rec
	if not visits_on():
		return {}
	var yesterday := str(rec["npc"]) if not rec.is_empty() and int(rec["day"]) == day - 1 else ""
	var fresh := _blank(day, roll_visitor(day, eligible_neighbours(), yesterday))
	if str(fresh["npc"]) != "":
		_plan_request(fresh, "")
	_write(fresh)
	return fresh


## Plans the one request of a visit (see "THE REQUEST"). `force_kind` "play"/"gift" is the dev menu's.
static func _plan_request(rec: Dictionary, force_kind: String) -> void:
	var npc := str(rec["npc"])
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(["astro_visit_request", int(rec["day"]), npc])
	var wants_play := rng.randf() < PLAY_CHANCE
	var game := _game_for(npc, force_kind == "play")
	var kind := force_kind if force_kind != "" else ("play" if wants_play else "gift")
	if kind == "play" and game.is_empty():
		kind = "gift"
	rec["kind"] = kind
	if kind == "play":
		var g := str(game["game"])
		rec["game"] = g
		rec["step"] = int(game["step"])
		rec["count"] = maxi(1, mini(int(game["count"]), int(VISIT_COUNT_MAX.get(g, int(game["count"])))))
		rec["progress"] = 0
	else:
		rec["item"] = _pick_gift(npc, rng)
		rec["count"] = 1


## This neighbour's mini-game step {game, step, count, config}, or {}. Unlocked ones only, unless `any`
## (the dev menu may force a game the story has not unlocked yet). Only kinds this build can start.
static func _game_for(npc: String, any: bool) -> Dictionary:
	if not ResourceLoader.exists(PROJECT_SYSTEM_PATH) or not ResourceLoader.exists(MINIGAME_SYSTEM_PATH):
		return {}
	var ms: Variant = load(MINIGAME_SYSTEM_PATH)
	var played: Variant = load(PROJECT_SYSTEM_PATH).call("played_minigames")
	if played is Array:
		for e: Variant in played:
			if e is Dictionary and str((e as Dictionary).get("npc", "")) == npc \
					and bool(ms.call("has_game", str((e as Dictionary).get("game", "")))):
				return e
	if not any:
		return {}
	var d: Variant = load(PROJECT_SYSTEM_PATH).call("definition_for", npc)
	if d is Dictionary and not (d as Dictionary).is_empty():
		var steps: Array = (d as Dictionary).get("steps", [])
		for i in steps.size():
			var step: Dictionary = steps[i]
			if str(step.get("type", "")) == "minigame" and bool(ms.call("has_game", str(step.get("game", "")))):
				return {"npc": npc, "step": i, "game": str(step.get("game", "")),
					"count": maxi(1, int(step.get("count", 1))),
					"config": (step.get("config", {}) as Dictionary).duplicate(true)}
	return {}


## One gift from the neighbour's list, preferring one not already standing on home.
static func _pick_gift(npc: String, rng: RandomNumberGenerator) -> String:
	var all: Array = []
	for id: Variant in DATA.GIFTS.get(npc, []):
		if Catalog.has_item(str(id)):
			all.append(str(id))
	if all.is_empty():
		return ""
	var standing := {}
	for e: Variant in GameState.placed_decorations.get(HOME_ID, []):
		if e is Dictionary:
			standing[str((e as Dictionary).get("item", ""))] = true
	var fresh: Array = all.filter(func(id: String) -> bool: return not standing.has(id))
	var pool: Array = fresh if not fresh.is_empty() else all
	return str(pool[rng.randi_range(0, pool.size() - 1)])


# ============================================================================= the saved record
## Today's record, normalised (a copy: write it back with `_write`). {} when there is none.
static func record() -> Dictionary:
	var raw: Variant = GameState.flags.get(FLAG_KEY)
	if not (raw is Dictionary):
		return {}
	var r: Dictionary = raw
	var spot: Array = []
	var raw_spot: Variant = r.get("spot", [])
	if raw_spot is Array and (raw_spot as Array).size() == 3:
		spot = [float(raw_spot[0]), float(raw_spot[1]), float(raw_spot[2])]
	var before: Array = []
	var raw_before: Variant = r.get("before", [])
	if raw_before is Array:
		for x: Variant in raw_before:
			before.append(str(x))
	return {
		"day": int(r.get("day", 0)), "npc": str(r.get("npc", "")), "kind": str(r.get("kind", "")),
		"game": str(r.get("game", "")), "step": int(r.get("step", -1)), "count": int(r.get("count", 1)),
		"progress": int(r.get("progress", 0)), "item": str(r.get("item", "")), "before": before,
		"asked": bool(r.get("asked", false)), "done": bool(r.get("done", false)),
		"left": bool(r.get("left", false)), "forced": bool(r.get("forced", false)), "spot": spot,
	}


static func _blank(day: int, npc: String) -> Dictionary:
	return {"day": day, "npc": npc, "kind": "", "game": "", "step": -1, "count": 1, "progress": 0,
		"item": "", "before": [], "asked": false, "done": false, "left": false, "forced": false, "spot": []}


static func _write(rec: Dictionary) -> void:
	GameState.flags[FLAG_KEY] = rec.duplicate(true)


## Ends the recorded visit for good: flying away, or any other world loading.
static func mark_left(why: String = "") -> void:
	var rec := record()
	if rec.is_empty() or str(rec["npc"]) == "" or bool(rec["left"]):
		return
	rec["left"] = true
	_write(rec)
	print("VisitorSystem: %s's visit on day %d ended (%s)" % [rec["npc"], rec["day"], why])


## True when the request is met and waits to be handed in (or was).
static func request_met(rec: Dictionary) -> bool:
	if rec.is_empty():
		return false
	if str(rec["kind"]) == "play":
		return int(rec["progress"]) >= int(rec["count"])
	if str(rec["kind"]) == "gift":
		for e: Variant in GameState.placed_decorations.get(HOME_ID, []):
			if e is Dictionary and str((e as Dictionary).get("item", "")) == str(rec["item"]) \
					and not (rec["before"] as Array).has(str((e as Dictionary).get("id", ""))):
				return true
	return false


static func _placed_ids(item_id: String) -> Array:
	var out: Array = []
	for e: Variant in GameState.placed_decorations.get(HOME_ID, []):
		if e is Dictionary and str((e as Dictionary).get("item", "")) == item_id:
			out.append(str((e as Dictionary).get("id", "")))
	return out


# ============================================================================= the visitor
func is_visitor(npc: Node) -> bool:
	return npc != null and npc == visitor and is_instance_valid(visitor)


## For npc.gd's "!": 1 show, 0 hide.
func wants_marker(npc_id: String) -> int:
	var rec := record()
	if rec.is_empty() or str(rec["npc"]) != npc_id or bool(rec["left"]) or bool(rec["done"]):
		return 0
	if not bool(rec["asked"]):
		return 1
	return 1 if request_met(rec) else 0


## npc.gd asks this for every wander target and path sample of the visitor.
func wander_ok(dir: Vector3) -> bool:
	return _ground_problem(dir) == ""


## Stands the visitor. `walk_in` (only the day-turning-over path) places them off-camera, a walk away
## and walks them to the spot instead; the spot itself, and everything written, is the same either way.
## Returns false ONLY when a walk-in found no way in that is out of shot while the spot itself is on
## camera: nobody is stood, and `_try_arrive` goes on looking. Nobody pops into the frame.
## `found` is `_try_arrive`'s answer when it has already done the search itself: `entry` is then used
## as it stands (Vector3.ZERO meaning "no way in, and the spot itself is out of shot, so stand them
## there"), and no second search is run.
func _bring_in(rec: Dictionary, walk_in: bool = false, entry: Vector3 = Vector3.ZERO, found: bool = false) -> bool:
	var t0 := Time.get_ticks_usec()
	_rebuild_caches()
	var spot := _vec(rec["spot"] as Array)
	if spot != Vector3.ZERO and _ground_problem(spot) == "":
		spot_pass = "saved"
		spot_note = ""
	else:
		spot = _pick_spot()
		if spot == Vector3.ZERO:
			push_warning("VisitorSystem: no ground on home passes the visitor's rules; %s stays away" % rec["npc"])
			return true
		rec["spot"] = [spot.x, spot.y, spot.z]
		_write(rec)
		# The ground moved under the answer `found` was worked out for: search again rather than walk
		# somebody in toward a spot that is no longer theirs.
		found = false
		entry = Vector3.ZERO
	if walk_in and not found:
		entry = _entry_dir(spot)
	if walk_in and entry == Vector3.ZERO and not found and _on_camera(spot):
		# The only two honest answers are "come in from somewhere out of shot" and "wait": standing
		# them at a spot the player is looking at is the pop-in the lead ruled out.
		search_usec = Time.get_ticks_usec() - t0
		return false
	search_usec = Time.get_ticks_usec() - t0
	_spawn_visitor(str(rec["npc"]), spot, entry)
	print("VisitorSystem: %s visits (day %d, %s%s), stood by the '%s' pass %s in %.1f ms%s" % [rec["npc"], rec["day"],
		rec["kind"], (" " + str(rec["game"]) if str(rec["kind"]) == "play" else " " + str(rec["item"])),
		spot_pass, spot_note, search_usec / 1000.0,
		(", walking in: " + _walk_note) if walk_in else ""])
	if str(rec["kind"]) == "play" and bool(rec["asked"]) and not bool(rec["done"]) and not request_met(rec):
		_queue_game()
	return true


## `entry` Vector3.ZERO stands them at the spot (every load). Otherwise they are placed at `entry` and
## `_walk_tick` walks them to the spot, which only then becomes their wander home.
func _spawn_visitor(npc_id: String, spot: Vector3, entry: Vector3 = Vector3.ZERO) -> void:
	var root := get_tree().root.get_node_or_null("World/NPCs")
	var path := NPC_DIR + npc_id + ".tscn"
	if root == null or not ResourceLoader.exists(path):
		return
	if root.has_node(npc_id):
		push_warning("VisitorSystem: %s is already on this world; no second one" % npc_id)
		return
	var n := (load(path) as PackedScene).instantiate()
	var npc := n as NPC
	if npc == null:
		n.free()
		return
	# THE ONE CLAIM THIS FILE MAKES ABOUT POP-IN, measured at the instant it happens rather than argued
	# for: where the body is actually put, tested against the LIVE camera. A walk-in must always print
	# false; a plain load (`entry` Vector3.ZERO) may print true, because a load has no frame to pop into.
	var placed := entry if entry != Vector3.ZERO else spot
	debug_spawn_seen = _on_camera(placed)
	print("VISITSPAWN %s walk_in=%s on_camera=%s" % [npc_id, str(entry != Vector3.ZERO),
		str(debug_spawn_seen)])
	npc.name = npc_id
	npc.visit_host = self
	npc.visit_home = entry if entry != Vector3.ZERO else spot
	npc.visit_wander_m = WANDER_M
	root.add_child(npc)
	npc.planet = planet
	visitor = npc
	if entry != Vector3.ZERO:
		_walk_in = true
		_walk_started = false
		_walk_t = 0.0
		_walk_target = spot
		set_process(true)


func _despawn_visitor() -> void:
	_walk_in = false
	_walk_started = false
	_arrive_due = false
	_arrive_spot = Vector3.ZERO
	if visitor != null and is_instance_valid(visitor):
		var p := visitor.get_parent()
		if p != null:
			p.remove_child(visitor)
		visitor.queue_free()
	visitor = null


## The dev menu changed today's visit while this world is up: stand the new one (or nobody) now.
func restage() -> void:
	_stop_game("restaged")
	_despawn_visitor()
	if GameState.current_planet_id != HOME_ID or planet == null:
		return
	var rec := record()
	if rec.is_empty() or int(rec["day"]) != GameState.day_count or str(rec["npc"]) == "" or bool(rec["left"]):
		return
	_bring_in(rec)


func _on_travel_started(from_id: String, _to_id: String) -> void:
	# Only a flight FROM home ends the visit: a dev-forced visit set on another world must survive the
	# flight home that it is waiting for (that world's own load already ended any earlier visit).
	if from_id != HOME_ID:
		return
	_stop_game("flew away")
	mark_left("flew away")


# ============================================================================= the day turning over
## The clock ticks this every ~0.05 h (~3 real s at a 1500 s day); the day count is the only thing read.
func _on_time_of_day(_hour: float) -> void:
	if GameState.day_count == _day_seen:
		return
	if GameState.current_planet_id != HOME_ID or planet == null or not is_inside_tree():
		_day_seen = GameState.day_count
		return
	if not _rollover_due:
		print("VisitorSystem: the clock rolled into day %d while you are at home" % GameState.day_count)
	_rollover_due = true
	set_process(true)


## Nothing is swapped under the player's feet: no flight or landing, no modal or dialogue box, no talk
## with the visitor, no mini-game of any owner, and not while the intro owns the screen. A rollover that
## lands mid-talk simply waits for the talk to end.
func _handover_calm() -> bool:
	if not _world_calm() or EventBus.is_modal_open() or _onboarding_busy():
		return false
	if visitor != null and is_instance_valid(visitor) and bool(visitor.get("_conversation_running")):
		return false
	var ms := _minigames()
	return ms == null or not bool(ms.call("is_running"))


## One step of the handover (see "WHO AND WHEN"): see yesterday's visitor off, then roll the new day
## and walk the new one in.
func _rollover_tick(delta: float) -> void:
	if GameState.current_planet_id != HOME_ID or planet == null:
		_rollover_due = false
		_seeing_off = false
		return
	if not _handover_calm():
		return
	if visitor != null and is_instance_valid(visitor):
		if not _seeing_off:
			_seeing_off = true
			_see_off_t = 0.0
			_see_off_aim_t = 0.0
			_see_off_waiting = false
			_stop_game("the day turned over")
			mark_left("the day turned over")
			_send_off()
		_see_off_t += delta
		_see_off_aim_t += delta
		var here := planet.dir_of(visitor.global_position)
		# THE ONE RULE: yesterday's visitor is never deleted while the camera can see them. Before
		# SEE_OFF_MAX_S a stroll that has ended without getting them out of shot is re-aimed; after it
		# they simply stand there until the camera moves on. (Round 1 removed them on the cap, in
		# frame, 12.0 s after the day turned - MEASURED 3/3 by the critic, 2026-09-19.)
		if _see_off_t > SEE_OFF_MIN_S and not _on_camera(here):
			print("VisitorSystem: yesterday's visitor left after %.1f s" % _see_off_t)
			_despawn_visitor()
		elif _see_off_t < SEE_OFF_MAX_S and _see_off_aim_t >= SEE_OFF_RETRY_S \
				and not bool(visitor.is_strolling()):
			_see_off_aim_t = 0.0
			_send_off(false)
			return
		else:
			if not _see_off_waiting and _see_off_t >= SEE_OFF_MAX_S:
				_see_off_waiting = true
				print("VisitorSystem: yesterday's visitor has nowhere out of shot after %.1f s; waiting for the camera" % _see_off_t)
			return
	_seeing_off = false
	_see_off_waiting = false
	_rollover_due = false
	_day_seen = GameState.day_count
	var rec := ensure_today()
	if rec.is_empty() or str(rec["npc"]) == "" or bool(rec["left"]):
		print("VisitorSystem: day %d rolled over at home, nobody comes" % GameState.day_count)
		return
	_arrive_due = true
	_arrive_t = 0.0
	_arrive_said = false
	_arrive_stuck = false
	_arrive_spot = Vector3.ZERO
	_arrive_dirty = false
	_try_arrive(0.0)


## One step of the pending arrival. The day is already rolled and written, so a reload keeps the same
## visitor; all that is waiting is a way in that the camera cannot see. Re-read every time: the dev
## menu, a flight or a talk can have moved on underneath.
func _try_arrive(delta: float) -> void:
	_arrive_t += delta
	if GameState.current_planet_id != HOME_ID or planet == null:
		_arrive_due = false
		return
	if not _handover_calm():
		return
	var rec := record()
	if rec.is_empty() or int(rec["day"]) != GameState.day_count or str(rec["npc"]) == "" \
			or bool(rec["left"]) or (visitor != null and is_instance_valid(visitor)):
		_arrive_due = false
		return
	# ONCE PER ARRIVAL, not once a frame and not once a second: the spot and the ring of ways in round
	# it are settled here, and `_rebuild_caches` + `_pick_spot` are paid once. Nothing in either can
	# change while the player only moves the camera; when something on the ground DOES move,
	# `_on_decorations_changed` sets `_arrive_dirty` and this runs again.
	var spot := _vec(rec["spot"] as Array)
	if _arrive_spot == Vector3.ZERO or _arrive_dirty:
		_arrive_dirty = false
		_rebuild_caches()
		if spot == Vector3.ZERO or _ground_problem(spot) != "":
			spot = _pick_spot()
			_close_sight_space()
			if spot == Vector3.ZERO:
				push_warning("VisitorSystem: no ground on home passes the visitor's rules; %s stays away" % rec["npc"])
				_arrive_due = false
				return
			rec["spot"] = [spot.x, spot.y, spot.z]
			_write(rec)
		_arrive_spot = spot
		_entry_build(spot)
		_entry_tally = {}
		_scan_begin()
		_arrive_stuck = false
	spot = _arrive_spot
	# The see-off borrows the same ring for yesterday's visitor's way OUT (`_entry_dir` from where they
	# stand). Today's rollover can never interleave with that - `_rollover_tick` only reaches the
	# arrival once nobody is left to see off - but the ring is shared state, so it is checked rather
	# than assumed.
	if not _entry_spot.is_equal_approx(spot):
		_entry_build(spot)
		_entry_tally = {}
		_scan_begin()
		_arrive_stuck = false
	# A pass that ended with nothing cannot answer differently until the camera or the player moves, so
	# a player standing perfectly still pays nothing to go on waiting.
	var cam := get_viewport().get_camera_3d()
	var cam_xf := cam.global_transform if cam != null else Transform3D()
	var here := _player_dir()
	if _arrive_stuck:
		if cam_xf.is_equal_approx(_scan_cam) and here.is_equal_approx(_scan_player):
			return
		_entry_tally = {}
		_scan_begin()
		_arrive_stuck = false
	# ARRIVE_BUDGET_USEC of this frame, then carry on next frame. A candidate is accepted only in the
	# frame its visibility was tested in, so nobody is ever let in on a stale answer.
	var entry := _scan_step(ARRIVE_BUDGET_USEC)
	if entry != Vector3.ZERO:
		_arrive_land(rec, entry)
		return
	if _scan_i < _scan_plan.size():
		return
	# A whole pass and no way in that is out of shot. If the SPOT is out of shot they can simply be
	# stood there; otherwise they wait, and the next pass starts when the camera moves.
	if not _on_camera(spot) and not debug_hold_arrival:
		_arrive_land(rec, Vector3.ZERO)
		return
	_arrive_stuck = true
	_walk_note = "no way in out of shot (%s)" % JSON.stringify(_entry_tally)
	if not _arrive_said:
		_arrive_said = true
		print("VisitorSystem: every way in is in shot and so is the spot (%s); %s waits rather than popping in" % [
			_walk_note, rec["npc"]])


## The search has answered: stand the visitor (walking in from `entry`, or at the spot when `entry` is
## Vector3.ZERO because the spot itself is out of shot) and close the arrival.
func _arrive_land(rec: Dictionary, entry: Vector3) -> void:
	if not _bring_in(rec, true, entry, true):
		return
	if _arrive_t > 0.0:
		print("VisitorSystem: the visitor waited %.1f s for a way in out of shot" % _arrive_t)
	_arrive_due = false
	_arrive_stuck = false
	_arrive_spot = Vector3.ZERO


## Yesterday's visitor waves and walks OUT OF SHOT, by the same search that walks the new one in
## (`_entry_dir` from where they stand: off camera, nothing walked through). `_rollover_tick` removes
## them the moment the camera has lost them and NEVER while it can see them. Only when there is no way
## out of shot do they take LEAVE_STEP_M away from the player; if that still leaves them in frame the
## walk is re-aimed every SEE_OFF_RETRY_S until SEE_OFF_MAX_S, and after that they wait, in the yard,
## for the camera to move on. May be called again to re-aim an arrival that is still in shot.
func _send_off(wave: bool = true) -> void:
	if visitor == null or not is_instance_valid(visitor):
		return
	visitor.wander_enabled(false)
	if wave:
		# Once. A re-aim is not a second goodbye.
		visitor.play_emote("wave")
	var here := planet.dir_of(visitor.global_position)
	var out := _entry_dir(here)
	if out == Vector3.ZERO:
		var p := get_tree().get_first_node_in_group("player") as Node3D
		var away := Vector3.ZERO
		if p != null:
			away = here - planet.dir_of(p.global_position)
			away -= here * away.dot(here)
		if away.length_squared() < 1e-8:
			away = planet.surface_transform(here).basis.z
		out = _step(here, away.normalized(), LEAVE_STEP_M)
	print("VisitorSystem: yesterday's visitor is walking off (%s)" % _walk_note)
	visitor.stroll_to(out)


## One step of the arriving visitor's walk from the entry point to their spot.
func _walk_tick(delta: float) -> void:
	if visitor == null or not is_instance_valid(visitor):
		_walk_in = false
		return
	_walk_t += delta
	if not _walk_started:
		# `stroll_to` is a no-op until the NPC's own first physics frame has placed it.
		if not bool(visitor.get("_placed")):
			if _walk_t < WALK_MAX_S:
				return
		else:
			visitor.wander_enabled(false)
			visitor.stroll_to(_walk_target)
			_walk_started = true
			return
	if bool(visitor.is_strolling()) and _walk_t < WALK_MAX_S:
		return
	# There now, or out of time: the spot becomes their home and they wander round it as always.
	_walk_in = false
	visitor.visit_home = _walk_target
	visitor.home_dir = _walk_target
	visitor.wander_enabled(true)
	var left_m := planet.surface_distance(planet.dir_of(visitor.global_position), _walk_target)
	print("VisitorSystem: the visitor walked in in %.1f s, %.2f m from the spot" % [_walk_t, left_m])


func _process(delta: float) -> void:
	var t0 := Time.get_ticks_usec()
	if _rollover_due:
		_rollover_tick(delta)
	elif _arrive_due:
		_try_arrive(delta)
	elif _walk_in:
		_walk_tick(delta)
	tick_usec = Time.get_ticks_usec() - t0
	if not _rollover_due and not _arrive_due and not _walk_in:
		tick_usec = 0
		set_process(false)


## A point round the planet from `spot` that the camera cannot see and that can be walked from, or
## Vector3.ZERO when there is none (the caller then waits, or stands them at the spot when the spot
## itself is out of shot). ONE UNINTERRUPTED SWEEP - `_send_off` and the load path want an answer in
## the frame they ask. The waiting arrival uses the same machinery a slice of a frame at a time
## (`_entry_build` + `_scan_begin` + `_scan_step`, see ARRIVE_BUDGET_USEC).
##
## Bearings are tried from "straight away from the camera" outwards, so the walk is normally toward the
## player's back, and the distances of ENTRY_TRIES_M in turn.
## FOUR SWEEPS, best kind of hidden first (2026-09-20), each over every distance and bearing:
##   "clear"   entirely outside the camera frustum - nothing in the engine can draw them;
##   "horizon" inside the frustum volume but behind the planet's own bulge (`_hidden_by_planet`), which
##             on a 12-18 m world is most of what is more than ~9 m away and is the only thing left
##             when the camera looks along the ground (that case is what round 1 got wrong);
## and each of those first with, then without, ENTRY_PLAYER_M between the entry and the player: "out
## of shot" is about the camera, but somebody appearing an arm's length behind your back is the same
## surprise if you turn round, and the bearing straight back past the player is exactly where the
## search ends up when everything else is blocked (MEASURED: 4 m behind the player, 2026-09-20).
## At most 4 x ENTRY_BEARINGS x ENTRY_TRIES_M cheap tests.
func _entry_dir(spot: Vector3) -> Vector3:
	_walk_note = ""
	if planet == null:
		return Vector3.ZERO
	_entry_build(spot)
	_entry_tally = {}
	_scan_begin()
	var t0 := Time.get_ticks_usec()
	var found := _scan_step(0)
	if found == Vector3.ZERO:
		_walk_note = "no way in out of shot after %.1f ms (%s)" % [
			(Time.get_ticks_usec() - t0) / 1000.0, JSON.stringify(_entry_tally)]
	return found


## The ring of candidate ways in round `spot`, with nothing worked out yet. Built on the PLANET's own
## tangent frame at the spot, not on the camera's bearing: the points are then the same from frame to
## frame, which is what lets their (camera-free) ground and path verdicts be cached at all. The camera
## only decides the ORDER the ring is walked in (`_scan_begin`). Re-building for the same spot keeps
## the verdicts already worked out.
func _entry_build(spot: Vector3) -> void:
	if _entry_spot.is_equal_approx(spot) and _entry_pts.size() == ENTRY_TRIES_M.size() * ENTRY_BEARINGS:
		return
	_entry_spot = spot
	_entry_pts.clear()
	var xf := planet.surface_transform(spot)
	for out_m: float in ENTRY_TRIES_M:
		for j in ENTRY_BEARINGS:
			var ang := TAU * float(j) / float(ENTRY_BEARINGS)
			var bearing := (xf.basis.z * cos(ang) + xf.basis.x * sin(ang)).normalized()
			_entry_pts.append({"dir": _step(spot, bearing, out_m), "out_m": out_m, "j": j,
				"ground": "?", "path": "?"})


## Plans one pass over the ring: which point each of the four sweeps looks at, in order. Only the order
## depends on the camera - bearing 0 of the plan is the lattice bearing nearest "straight away from the
## camera", then +-1, +-2 outwards, exactly as the old continuous sweep went (the lattice quantises that
## to 360/ENTRY_BEARINGS = 15 degrees, which at 14 m is 1.8 m along the rim).
func _scan_begin() -> void:
	_scan_i = 0
	if planet == null or _entry_pts.is_empty():
		_scan_plan.clear()
		_scan_j0 = -1
		return
	var xf := planet.surface_transform(_entry_spot)
	var base := xf.basis.z
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	if cam != null:
		var from_cam := _entry_spot - planet.dir_of(cam.global_position)
		from_cam -= _entry_spot * from_cam.dot(_entry_spot)
		if from_cam.length_squared() > 1e-8:
			base = from_cam.normalized()
	var j0 := posmod(int(round(atan2(base.dot(xf.basis.x), base.dot(xf.basis.z)) / TAU * float(ENTRY_BEARINGS))),
		ENTRY_BEARINGS)
	_scan_cam = cam.global_transform if cam != null else Transform3D()
	_scan_player = _player_dir()
	# THE PLAN IS THE SAME LIST FOR THE SAME BEARING. A waiting arrival starts a new pass several times
	# a second, and rebuilding 4 x ENTRY_BEARINGS x ENTRY_TRIES_M entries each time was the only thing
	# in this loop that allocated: MEASURED 2026-09-20, a single ~84 ms frame after about 7.5 s of
	# scanning, in 5 of 8 runs, with this node's own `_process` costing 0.9 ms in that frame - the heap
	# growing under the rebuild, not the search. Rebuilding only when the bearing changes (and writing
	# into a resized buffer rather than appending) removed it: 0 frames over 8 ms in 8 later runs.
	if j0 == _scan_j0 and not _scan_plan.is_empty():
		return
	_scan_j0 = j0
	var n := _entry_pts.size()
	var tries := ENTRY_TRIES_M.size()
	_scan_plan.resize(4 * tries * ENTRY_BEARINGS)
	var at := 0
	for sweep in 4:
		for di in tries:
			# bearings from "straight away from the camera" outwards: 0, +1, -1, +2, -2, ...
			for step in ENTRY_BEARINGS:
				var k := (step + 1) / 2
				if step % 2 == 0:
					k = -k
				_scan_plan[at] = sweep * n + di * ENTRY_BEARINGS + posmod(j0 + k, ENTRY_BEARINGS)
				at += 1


## Walks the planned pass until it finds a way in or runs out of `budget_usec` (0 = to the end). The
## caller knows the pass is finished when `_scan_i` has reached the end of `_scan_plan`.
##
## What each sweep re-does and what it remembers: `_walk_problem` (terrain, pad, house, props,
## decorations, trash) and `_path_blocker` (the same, sampled along the walk) hold no camera and are
## worked out ONCE per point per arrival. The visibility test holds nothing BUT the camera, so it is
## re-run every time, against the live camera in the frame the point is reached.
func _scan_step(budget_usec: int) -> Vector3:
	if planet == null:
		return Vector3.ZERO
	var t0 := Time.get_ticks_usec()
	var n := _entry_pts.size()
	var player_dir := _player_dir()
	var done := 0
	while _scan_i < _scan_plan.size():
		# Always at least one candidate per call, so a pass can never stall; then out of the frame.
		if budget_usec > 0 and done > 0 and Time.get_ticks_usec() - t0 >= budget_usec:
			return Vector3.ZERO
		done += 1
		var code := int(_scan_plan[_scan_i])
		_scan_i += 1
		var sweep := code / n
		var c: Dictionary = _entry_pts[code % n]
		var clear_pass := sweep % 2 == 0
		var keep_m := ENTRY_PLAYER_M if sweep < 2 else 0.0
		var last := sweep == 3
		var entry: Vector3 = c["dir"]
		if keep_m > 0.0 and player_dir != Vector3.ZERO \
				and planet.surface_distance(entry, player_dir) < keep_m:
			continue
		var why: String = c["ground"]
		if why == "?":
			why = _walk_problem(entry)
			c["ground"] = why
		if why != "":
			if last:
				_tally("entry:" + why)
			continue
		if (_in_frustum(entry) if clear_pass else _on_camera(entry)):
			if last:
				_tally("on camera")
			continue
		var blocked: String = c["path"]
		if blocked == "?":
			blocked = _path_blocker(entry, _entry_spot)
			c["path"] = blocked
		if blocked != "":
			if last:
				_tally("path:" + blocked)
			continue
		if debug_hold_arrival:
			if last:
				_tally("held")
			continue
		_walk_note = "%s%s, %.1f m out, bearing %d/%d" % [("clear" if clear_pass else "horizon"),
			("" if keep_m > 0.0 else ", close to the player"), float(c["out_m"]), int(c["j"]),
			ENTRY_BEARINGS]
		return entry
	return Vector3.ZERO


## The player's surface direction, or Vector3.ZERO when there is no player.
func _player_dir() -> Vector3:
	if not is_inside_tree() or planet == null:
		return Vector3.ZERO
	var p := get_tree().get_first_node_in_group("player") as Node3D
	return planet.dir_of(p.global_position) if p != null else Vector3.ZERO


## True when either body point at `dir` is inside the camera frustum, whatever is in the way. The
## strict half of `_entry_dir`'s search: an entry that fails this cannot be drawn at all.
func _in_frustum(dir: Vector3) -> bool:
	if not is_inside_tree():
		return false
	var cam := get_viewport().get_camera_3d()
	if cam == null or planet == null:
		return false
	var foot := planet.surface_point(dir)
	var up := planet.up_at(foot)
	return cam.is_position_in_frustum(foot) or cam.is_position_in_frustum(foot + up * ENTRY_EYE_M)


func _tally(reason: String) -> void:
	_entry_tally[reason] = int(_entry_tally.get(reason, 0)) + 1


## True when any part of a body standing at `dir` can actually be SEEN from the live camera: inside
## the frustum AND not behind the planet. No camera (a headless run with no viewport camera) counts as
## off-camera - which is why every claim about what is in frame has to be measured windowed.
func _on_camera(dir: Vector3) -> bool:
	if not is_inside_tree():
		return false
	var cam := get_viewport().get_camera_3d()
	if cam == null or planet == null:
		return false
	var eye := cam.global_position
	var foot := planet.surface_point(dir)
	var up := planet.up_at(foot)
	for p: Vector3 in [foot, foot + up * ENTRY_EYE_M]:
		if cam.is_position_in_frustum(p) and not _hidden_by_planet(eye, p):
			return true
	return false


## True when the planet's own ground stands between `eye` and `p`. The sight line is walked in
## HORIZON_STEP_M steps and each step is compared with the terrain height under it; the line has to
## dip HORIZON_CLEAR_M below the ground to count, so a grazing line reads as visible (see the
## constants). This is the horizon test `is_position_in_frustum` does not do.
func _hidden_by_planet(eye: Vector3, p: Vector3) -> bool:
	if planet == null:
		return false
	var centre := planet.global_position
	var seg := p - eye
	var len_m := seg.length()
	if len_m < 0.01:
		return false
	var steps := int(ceil(len_m / HORIZON_STEP_M))
	for i in range(1, steps):
		var s := eye + seg * (float(i) / float(steps))
		var d := s - centre
		var r := d.length()
		if r < 0.01:
			return true
		if r < planet.height_at(d / r) - HORIZON_CLEAR_M:
			return true
	return false


## "" when a body may walk over `dir`, otherwise what is in the way. NOT `_ground_problem`: that one
## answers "may a visitor STAND here for a day" (see the constants above).
func _walk_problem(dir: Vector3) -> String:
	if planet == null or planet.data == null:
		return "no planet"
	var d := dir.normalized()
	if planet.is_underwater(d):
		return "water"
	var wr := planet.water_radius()
	if wr > 0.0 and planet.height_at(d) < wr + 0.3:
		return "shore"
	if planet.surface_distance(d, planet.data.pad_dir.normalized()) < WALK_PAD_M:
		return "pad"
	for bid: String in planet.data.buildings:
		var bd := planet.building_dir(bid)
		if bd != Vector3.ZERO and planet.surface_distance(d, bd) < WALK_HOUSE_M:
			return "house"
	if planet.nearest_prop_distance(d) < WALK_PROP_M:
		return "prop"
	for r: Dictionary in _deco_cache:
		if planet.surface_distance(d, r["dir"] as Vector3) < float(r["footprint"]) + WALK_DECO_GAP_M:
			return "decoration"
	var here := planet.surface_point(d)
	var trash := get_tree().root.get_node_or_null("World/TrashField") if is_inside_tree() else null
	if trash != null:
		for c: Node in trash.get_children():
			if c is Node3D and here.distance_to((c as Node3D).global_position) < WALK_TRASH_M:
				return "trash"
	return ""


## "" when nothing on the straight surface path from `a` to `b` would be walked through, otherwise the
## first thing in the way.
func _path_blocker(a: Vector3, b: Vector3) -> String:
	var span := planet.surface_distance(a, b)
	var steps := maxi(1, int(ceil(span / PATH_STEP_M)))
	for i in range(1, steps):
		var why := _walk_problem(a.slerp(b, float(i) / float(steps)).normalized())
		if why != "":
			return why
	return ""


## `metres` round the planet from the surface direction `from`, along the tangent `tangent`.
func _step(from: Vector3, tangent: Vector3, metres: float) -> Vector3:
	var a := metres / maxf(planet.radius, 0.001)
	return (from.normalized() * cos(a) + tangent.normalized() * sin(a)).normalized()


# ============================================================================= talk
## conversation.gd hands every talk with the visitor here. Awaits until the lines are said.
func handle_conversation(runner: DialogueRunner, npc: NPC) -> void:
	var rec := record()
	var id := npc.npc_id
	if rec.is_empty() or str(rec["npc"]) != id or bool(rec["done"]) or bool(rec["left"]):
		await runner.say(npc, DATA.lines(id, "bye"))
		return
	var kind := str(rec["kind"])
	if not bool(rec["asked"]):
		rec["asked"] = true
		if kind == "play":
			_write(rec)
			await runner.say(npc, DATA.lines(id, "ask_play"))
			_queue_game()
		else:
			rec["before"] = _placed_ids(str(rec["item"]))
			_write(rec)
			_give_gift(str(rec["item"]))
			await runner.say(npc, DATA.lines(id, "ask_gift") + [_gift_status()])
			_toast_gift(str(rec["item"]))
		return
	if request_met(rec):
		# Committed before the lines, so a talk cut short can never pay twice or lose the reward.
		rec["done"] = true
		_write(rec)
		GameState.add_friendship(id, VISIT_FRIENDSHIP)
		GameState.add_stardust(VISIT_STARDUST)
		AudioManager.play_sfx("friendship_up", -8.0)
		npc.play_emote("happy")
		await runner.say(npc, DATA.lines(id, "done_" + kind) + ["(You got %d Stardust!)" % VISIT_STARDUST])
		return
	if kind == "play":
		await runner.say(npc, DATA.lines(id, "progress_play") + [_play_status(rec)])
		_queue_game()
	elif GameState.item_count(str(rec["item"])) <= 0:
		_give_gift(str(rec["item"]))
		await runner.say(npc, DATA.lines(id, "again_gift") + [_gift_status()])
		_toast_gift(str(rec["item"]))
	else:
		await runner.say(npc, DATA.lines(id, "progress_gift") + [_gift_status()])


static func _give_gift(item_id: String) -> void:
	if item_id != "":
		GameState.add_item(item_id, 1)


static func _toast_gift(item_id: String) -> void:
	AudioManager.play_sfx("pickup_item")
	var nm := str(Catalog.get_item(item_id).get("name", item_id))
	EventBus.toast_requested.emit("You got a %s!" % nm, item_id)


static func _gift_status() -> String:
	return "(%s, then place it.)" % MobileUI.bag_hint(true)


static func _play_status(rec: Dictionary) -> String:
	return "(%d of %d %s.)" % [mini(int(rec["progress"]), int(rec["count"])), int(rec["count"]),
		str(DATA.STATUS_VERBS.get(str(rec["game"]), "done"))]


func _on_decoration_placed(planet_id: String, _instance_id: String, item_id: String) -> void:
	_on_decorations_changed()
	if planet_id != HOME_ID or visitor == null:
		return
	var rec := record()
	if str(rec.get("kind", "")) == "gift" and str(rec["item"]) == item_id and bool(rec["asked"]) \
			and not bool(rec["done"]) and request_met(rec):
		EventBus.toast_requested.emit("Placed! Go and show %s." % _npc_name(str(rec["npc"])), "heart")


func _on_decoration_removed(_planet_id: String, _instance_id: String) -> void:
	_on_decorations_changed()


func _on_decorations_changed() -> void:
	if visitor != null:
		_rebuild_deco_cache()
	# A pending arrival's ground and path verdicts were worked out against the old yard.
	if _arrive_due:
		_arrive_dirty = true


# ============================================================================= the game
func _queue_game() -> void:
	_game_pending = true
	call_deferred("_try_start_game")


func _on_modal_closed(_name: String) -> void:
	if _game_pending:
		call_deferred("_try_start_game")


func _try_start_game() -> void:
	if not _game_pending or not is_inside_tree():
		return
	var rec := record()
	if rec.is_empty() or str(rec["kind"]) != "play" or not bool(rec["asked"]) or bool(rec["done"]) \
			or bool(rec["left"]) or request_met(rec) or visitor == null or GameState.current_planet_id != HOME_ID:
		_game_pending = false
		return
	if EventBus.is_modal_open() or not _world_calm():
		return   # the next modal close checks again
	_game_pending = false
	_start_game(rec)


func _start_game(rec: Dictionary) -> void:
	if not ResourceLoader.exists(MINIGAME_SYSTEM_PATH):
		return
	var ms: Node = load(MINIGAME_SYSTEM_PATH).call("get_or_create")
	if ms == null:
		return
	var owner_id := owner_for(rec)
	if bool(ms.call("is_running")):
		var running := str(ms.call("running_owner"))
		if running == owner_id:
			_owner = owner_id
			return
		if running.begins_with("project:"):
			EventBus.toast_requested.emit("Finish the game that is already on first.", "")
			return
	if not ms.is_connected("progress_changed", _on_game_progress):
		ms.connect("progress_changed", _on_game_progress)
	if not ms.is_connected("finished", _on_game_finished):
		ms.connect("finished", _on_game_finished)
	_owner = owner_id
	if not bool(ms.call("start", str(rec["game"]), game_config(rec))):
		_owner = ""
		EventBus.toast_requested.emit("That game couldn't start here.", "")


static func owner_for(rec: Dictionary) -> String:
	return "%s%s:%d" % [OWNER_PREFIX, rec["npc"], rec["day"]]


## The config a visit game starts with (see "THE REQUEST").
static func game_config(rec: Dictionary) -> Dictionary:
	var cfg: Dictionary = {}
	var npc := str(rec["npc"])
	if ResourceLoader.exists(PROJECT_SYSTEM_PATH):
		var d: Variant = load(PROJECT_SYSTEM_PATH).call("definition_for", npc)
		if d is Dictionary:
			var steps: Array = (d as Dictionary).get("steps", [])
			var i := int(rec["step"])
			if i >= 0 and i < steps.size():
				cfg = ((steps[i] as Dictionary).get("config", {}) as Dictionary).duplicate(true)
	# Keys that only fit the neighbour's own world.
	for k: String in ["home_dir", "near", "center_dir", "dirs", "seed"]:
		cfg.erase(k)
	var spot: Array = rec["spot"]
	if spot.size() == 3 and str(rec["game"]) in ["rings", "hunt"]:
		cfg["near"] = spot.duplicate()
	cfg["npc"] = npc
	cfg["count"] = int(rec["count"])
	cfg["done"] = clampi(int(rec["progress"]), 0, int(rec["count"]))
	cfg["owner"] = owner_for(rec)
	return cfg


func _on_game_progress(_kind: String, done: int, total: int) -> void:
	var ms := _minigames()
	if ms == null or _owner == "" or str(ms.call("running_owner")) != _owner:
		return
	var rec := record()
	if rec.is_empty() or owner_for(rec) != _owner or bool(rec["done"]):
		return
	if total > 0:
		rec["count"] = total
	rec["progress"] = clampi(maxi(int(rec["progress"]), done), 0, int(rec["count"]))
	_write(rec)


func _on_game_finished(_kind: String, success: bool, config: Dictionary) -> void:
	if _owner == "" or str(config.get("owner", "")) != _owner:
		return
	_owner = ""
	if not success:
		return
	var rec := record()
	if rec.is_empty() or owner_for(rec) != str(config.get("owner", "")) or bool(rec["done"]):
		return
	rec["progress"] = int(rec["count"])
	_write(rec)
	EventBus.toast_requested.emit("That's all of them! Go and tell %s." % _npc_name(str(rec["npc"])), "")


func _stop_game(reason: String) -> void:
	_game_pending = false
	if _owner == "":
		return
	var ms := _minigames()
	if ms != null:
		ms.call("stop_owner", _owner, reason)
	_owner = ""


func _minigames() -> Node:
	if not ResourceLoader.exists(MINIGAME_SYSTEM_PATH):
		return null
	return load(MINIGAME_SYSTEM_PATH).call("find")


## Same rule as replay_board.gd: nothing mid-flight or mid-landing, and the player really in control.
func _world_calm() -> bool:
	if SceneRouter.is_busy() or RocketJourney.switching or GameState.flag("rocket_arriving"):
		return false
	var p := get_tree().get_first_node_in_group("player") as Player
	return p != null and p.is_inside_tree() and p.is_physics_processing() and p.input_enabled


func _onboarding_busy() -> bool:
	var ob := get_tree().root.get_node_or_null("World/Onboarding")
	if ob == null:
		return false
	if ob.get("_crashing") == true or ob.get("_greeting") == true:
		return true
	if ob.has_method("_intro_allowed") and not bool(ob.call("_intro_allowed")):
		return false
	# The crash and the radio call both come before "intro_greeted" (intro_director.gd), at home.
	return not GameState.flag("intro_greeted") and not GameState.flag("intro_done")


# ============================================================================= where they stand
func _rebuild_caches() -> void:
	_build_views()
	_rebuild_deco_cache()
	_prompts.clear()
	var root := get_tree().root
	var deco := root.get_node_or_null("World/Decorations")
	var npcs := root.get_node_or_null("World/NPCs")
	for n: Node in get_tree().get_nodes_in_group("interactables"):
		var it := n as Interactable
		if it == null or not it.is_inside_tree():
			continue
		if (deco != null and deco.is_ancestor_of(it)) or (npcs != null and npcs.is_ancestor_of(it)):
			continue
		if planet.collectibles_root != null and planet.collectibles_root.is_ancestor_of(it):
			continue
		var trash := root.get_node_or_null("World/TrashField")
		if trash != null and trash.is_ancestor_of(it):
			continue
		_prompts.append({"pos": it.global_position, "reach": it.reach, "name": str(it.name)})


func _rebuild_deco_cache() -> void:
	_deco_cache.clear()
	var deco := get_tree().root.get_node_or_null("World/Decorations")
	if deco != null and deco.has_method("get_instances"):
		for r: Dictionary in deco.call("get_instances"):
			_deco_cache.append({"dir": r["dir"], "footprint": float(r["footprint"])})


## "" when the visitor may stand at `d`, otherwise the first rule it breaks (see "THE GROUND RULES").
func _ground_problem(dir: Vector3) -> String:
	if planet == null or planet.data == null:
		return "no planet"
	var d := dir.normalized()
	if planet.is_underwater(d):
		return "water"
	var wr := planet.water_radius()
	if wr > 0.0 and planet.height_at(d) < wr + 0.3:
		return "shore"
	var pad := planet.data.pad_dir.normalized()
	var spawn := planet.data.spawn_dir.normalized()
	if planet.surface_distance(d, pad) < PAD_CLEAR_M:
		return "pad"
	if planet.surface_distance(d, spawn) < SPAWN_CLEAR_M:
		return "spawn"
	if _landing_dir != Vector3.ZERO and planet.surface_distance(d, _landing_dir) < LANDING_CLEAR_M:
		return "landing"
	var n := pad.cross(spawn)
	if n.length_squared() > 1e-8:
		var off_line := absf(asin(clampf(d.dot(n.normalized()), -1.0, 1.0))) * planet.radius
		var total := planet.surface_distance(pad, spawn)
		if off_line < TRAIL_CLEAR_M and planet.surface_distance(d, spawn) < total and planet.surface_distance(d, pad) < total:
			return "stones"
	for bid: String in planet.data.buildings:
		var bd := planet.building_dir(bid)
		if bd != Vector3.ZERO and planet.surface_distance(d, bd) < HOUSE_CLEAR_M:
			return "house"
	var here := planet.surface_point(d)
	for p: Dictionary in _prompts:
		if here.distance_to(p["pos"] as Vector3) < float(p["reach"]) + PROMPT_GAP_M:
			return "prompt:" + str(p["name"])
	if planet.nearest_prop_distance(d) < PROP_CLEAR_M:
		return "prop"
	for r: Dictionary in _deco_cache:
		if planet.surface_distance(d, r["dir"] as Vector3) < float(r["footprint"]) + DECO_GAP_M:
			return "decoration"
	if planet.collectibles_root != null:
		for c: Node in planet.collectibles_root.get_children():
			if c is Node3D and here.distance_to((c as Node3D).global_position) < PICKUP_CLEAR_M:
				return "pickup"
	var trash := get_tree().root.get_node_or_null("World/TrashField") if is_inside_tree() else null
	if trash != null:
		for c: Node in trash.get_children():
			if c is Node3D and here.distance_to((c as Node3D).global_position) < TRASH_CLEAR_M:
				return "trash"
	var ground := planet.ground_normal(d, RIM_M)
	if rad_to_deg(acos(clampf(ground.dot(d), -1.0, 1.0))) > MAX_SLOPE_DEG:
		return "slope"
	var h0 := planet.height_at(d)
	var xf := planet.surface_transform(d)
	for k in 8:
		var ang := TAU * float(k) / 8.0
		var tangent := xf.basis.x * cos(ang) + xf.basis.z * sin(ang)
		if absf(planet.height_at((d + tangent * (RIM_M / planet.radius)).normalized()) - h0) > MAX_RIM_DH_M:
			return "uneven"
	return ""


## THE ORDER THE "framed" LATTICE IS SEARCHED IN, rolled from the day alone (Fisher-Yates on a seeded
## RandomNumberGenerator, not Array.shuffle, which uses the global one and would not be reproducible).
## Pure and seeded like every other per-day roll here, so a reload on the same day walks the lattice in
## the same order and lands on the same square even when the saved spot has to be picked again.
##
## WHY A SHUFFLE AND NOT A ROLLED IDEAL: the search takes the FIRST square that passes every rule, so
## whatever fixes the order fixes the spot. The fixed "nearest (4.0 ahead, 2.4 to the spawn side)" sort
## gave 1 distinct spot in 30 days (MEASURED 2026-09-20). Rolling that ideal over the lattice gave 11
## in 30, but clumped: 17 of the 30 days landed on the same two squares, because on home not one square
## on the spawn side passes the frame rules (39 pass, all 2.0-4.4 m to the OTHER side), so half of the
## ideal's roam collapsed onto the two squares nearest that edge. A shuffle asks the squares in a
## different order instead, which makes every LEGAL square equally likely to be the first one found -
## and it is no slower: the first passing square is reached in about lattice/passing = 27 probes on
## average, where the sorted search had to walk every square nearer the ideal than the nearest passer.
## Every ground and frame rule is still applied to every square, so the order can only choose between
## legal squares, never make an illegal one win.
static func _day_shuffle(a: Array[Vector2], day: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([SPOT_SEED, day])
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t := a[i]
		a[i] = a[j]
		a[j] = t


## The four passes of "WHERE THEY STAND". Vector3.ZERO when no ground on the planet passes.
func _pick_spot() -> Vector3:
	var first_problem := ""
	if _landing_dir != Vector3.ZERO:
		var lat := _landing_dir.cross(_away).normalized()
		# +side is the side the spawn is on.
		if lat.dot(planet.data.spawn_dir.normalized()) < 0.0:
			lat = -lat
		var near: Array[Vector2] = []
		for ix in range(int(round(AHEAD_MIN_M / SEARCH_STEP_M)), int(round(AHEAD_MAX_M / SEARCH_STEP_M)) + 1):
			for iy in range(-int(round(SIDE_MAX_M / SEARCH_STEP_M)), int(round(SIDE_MAX_M / SEARCH_STEP_M)) + 1):
				near.append(Vector2(ix, iy) * SEARCH_STEP_M)
		_day_shuffle(near, GameState.day_count)
		# Pass 1 needs every sight line clear, round the whole wander patch too; pass 2 only where they
		# stand (the patch still in frame) - a crowded yard can hide some of the patch.
		for pass_name: String in ["framed", "framed-spot"]:
			for c: Vector2 in near:
				var d := _lattice_dir(_landing_dir, _away, lat, c.x, c.y)
				var why := _ground_problem(d)
				if why == "":
					why = _view_problem(d, pass_name == "framed")
				if why == "":
					_close_sight_space()
					return _chosen(pass_name, d, "ahead=%.1f side=%.1f%s" % [c.x, c.y,
						"" if pass_name == "framed" else " (framed pass first met: %s)" % first_problem])
				if first_problem == "":
					first_problem = why
		_close_sight_space()
		# The ground rules alone, nearest the landing spot first.
		var wide: Array[Vector2] = []
		var r := int(round(NEAR_MAX_M / SEARCH_STEP_M))
		for ix in range(-r, r + 1):
			for iy in range(-r, r + 1):
				var v := Vector2(ix, iy) * SEARCH_STEP_M
				if v.length() <= NEAR_MAX_M:
					wide.append(v)
		wide.sort_custom(func(a: Vector2, b: Vector2) -> bool:
			var la := a.length_squared()
			var lb := b.length_squared()
			return la < lb or (is_equal_approx(la, lb) and (a.x < b.x or (is_equal_approx(a.x, b.x) and a.y < b.y))))
		for c: Vector2 in wide:
			var d := _lattice_dir(_landing_dir, _away, lat, c.x, c.y)
			if _ground_problem(d) == "":
				return _chosen("near", d, "ahead=%.1f side=%.1f (framed pass first met: %s)" % [c.x, c.y, first_problem])
	# Anywhere: a Fibonacci sphere, nearest the landing spot (or the pad) first.
	var from := _landing_dir if _landing_dir != Vector3.ZERO else planet.data.pad_dir.normalized()
	var pts: Array[Vector3] = []
	var count := 1500
	for i in count:
		var y := 1.0 - 2.0 * (float(i) + 0.5) / float(count)
		var rr := sqrt(maxf(0.0, 1.0 - y * y))
		var th := PI * (3.0 - sqrt(5.0)) * float(i)
		pts.append(Vector3(cos(th) * rr, y, sin(th) * rr))
	pts.sort_custom(func(a: Vector3, b: Vector3) -> bool: return a.dot(from) > b.dot(from))
	for d: Vector3 in pts:
		if _ground_problem(d) == "":
			return _chosen("anywhere", d, "(framed pass first met: %s)" % first_problem)
	spot_pass = ""
	spot_note = "no legal ground (framed pass first met: %s)" % first_problem
	return Vector3.ZERO


func _chosen(pass_name: String, d: Vector3, note: String) -> Vector3:
	spot_pass = pass_name
	spot_note = note
	return d


## The point `x` metres along `t1` and `y` metres along `t2` from `a`, walked on the ground.
func _lattice_dir(a: Vector3, t1: Vector3, t2: Vector3, x: float, y: float) -> Vector3:
	var r := sqrt(x * x + y * y)
	if r < 1e-6:
		return a
	var ang := r / planet.radius
	return (a * cos(ang) + (t1 * x + t2 * y) / r * sin(ang)).normalized()


## Rebuilds the two cameras a rocket landing on home hands the player (replay_board_prop.gd
## `_build_views`, same numbers: world.gd's landing spot, rocket_pad.gd's facing, camera_rig.gd's rig).
func _build_views() -> void:
	_views.clear()
	_landing_dir = Vector3.ZERO
	var pad := planet.data.pad_dir.normalized()
	var side := pad.cross(Vector3.UP)
	if side.length_squared() < 0.01:
		side = Vector3.RIGHT
	var land := (pad + side.normalized() * (LANDING_SIDE_M / planet.data.radius)).normalized()
	var feet := planet.surface_point(land)
	var up := planet.up_at(feet)
	var away := feet - planet.pad_transform().origin
	away -= up * away.dot(up)
	if away.length_squared() < 1e-6:
		return
	away = away.normalized()
	_landing_dir = land
	# `away` as a tangent at the landing DIRECTION (a unit vector), for the lattice.
	_away = (away - land * away.dot(land)).normalized()
	var rig := {}
	if ResourceLoader.exists(CAMERA_RIG_PATH):
		var script := load(CAMERA_RIG_PATH) as GDScript
		if script != null:
			rig = script.get_script_constant_map()
	var pivot := feet + up * float(rig.get("PIVOT_HEIGHT", 1.0))
	var tan_y := tan(deg_to_rad(LANDING_FOV_DEG) * 0.5)
	for mode: String in VIEW_ASPECTS:
		var mobile := mode == "mobile"
		var dist := float(rig.get("MOBILE_DIST_DEFAULT" if mobile else "DIST_DEFAULT", 8.6 if mobile else 7.4))
		var pitch := deg_to_rad(float(rig.get("MOBILE_PITCH_DEFAULT_DEG" if mobile else "PITCH_DEFAULT_DEG",
			34.0 if mobile else 28.0)))
		var eye := pivot - away * cos(pitch) * dist + up * sin(pitch) * dist
		_views.append({"name": mode, "eye": eye, "basis": Basis.looking_at((pivot - eye).normalized(), up),
			"tan_x": tan_y * float(VIEW_ASPECTS[mode]), "tan_y": tan_y})
	_astronaut_xf = Transform3D(planet.surface_transform(land, away).basis, feet)


## "" when both landing cameras see the whole visitor at `d`, in the safe part of the frame, past
## everything; otherwise which rule failed and for which camera.
func _view_problem(d: Vector3, ring_sight: bool = true) -> String:
	return str(view_report(d, true, ring_sight)["problem"])


## The frame rule's numbers for a visitor at `d`: {problem, views: [{name, rect, blocked, lines, by}]}.
## Judged where they stand AND round the whole little patch they wander (WANDER_RING points WANDER_M +
## a step out): every column inside the safe part of the frame, and every sight line clear.
func view_report(d: Vector3, first_only: bool, ring_sight: bool = true) -> Dictionary:
	var out := {"problem": "", "views": []}
	if _views.is_empty():
		return out
	var xf := planet.surface_transform(d)
	# Where they may stand: the spot (full column of lines) and the rim of their wander patch.
	var stands: Array[Transform3D] = [xf]
	var r := WANDER_M + 0.2
	for k in WANDER_RING:
		var ang := TAU * float(k) / float(WANDER_RING)
		stands.append(planet.surface_transform(_lattice_dir(d.normalized(), xf.basis.x, xf.basis.z, cos(ang) * r, sin(ang) * r)))
	for v: Dictionary in _views:
		var name_v := str(v["name"])
		var eye: Vector3 = v["eye"]
		var basis: Basis = v["basis"]
		var rep := {"name": name_v, "rect": Rect2(), "blocked": 0, "lines": 0, "by": ""}
		(out["views"] as Array).append(rep)
		var rect := Rect2()
		var behind := false
		var first := true
		for sx: Transform3D in stands:
			var up := sx.basis.y
			var side := basis.x - up * basis.x.dot(up)
			side = side.normalized() if side.length_squared() > 1e-6 else sx.basis.x
			for c: Vector3 in [sx.origin - side * COLUMN_HALF_M, sx.origin + side * COLUMN_HALF_M,
					sx.origin - side * COLUMN_HALF_M + up * COLUMN_TOP_M, sx.origin + side * COLUMN_HALF_M + up * COLUMN_TOP_M]:
				var rel: Vector3 = c - eye
				var depth := -basis.z.dot(rel)
				if depth < 0.5:
					behind = true
					break
				var sp := Vector2(basis.x.dot(rel) / depth / float(v["tan_x"]), basis.y.dot(rel) / depth / float(v["tan_y"]))
				rect = Rect2(sp, Vector2.ZERO) if first else rect.expand(sp)
				first = false
		rep["rect"] = rect
		if behind or not (VIEW_SAFE[name_v] as Rect2).encloses(rect) \
				or (VIEW_KEEP_OUT.has(name_v) and (VIEW_KEEP_OUT[name_v] as Rect2).intersects(rect)):
			if out["problem"] == "":
				out["problem"] = "offscreen:" + name_v
			if first_only:
				return out
			continue
		_open_sight_space()
		for i in stands.size():
			var sx: Transform3D = stands[i]
			var up := sx.basis.y
			var side := basis.x - up * basis.x.dot(up)
			side = side.normalized() if side.length_squared() > 1e-6 else sx.basis.x
			for h: float in SIGHT_HEIGHTS:
				if i > 0 and not ring_sight:
					break
				for sd: float in (SIGHT_SIDES if i == 0 else [0.0]):
					rep["lines"] = int(rep["lines"]) + 1
					var hit := _ray_hit(eye, sx.origin + up * h + side * sd)
					if hit != "":
						rep["blocked"] = int(rep["blocked"]) + 1
						rep["by"] = hit
						if out["problem"] == "":
							out["problem"] = ("hidden:" if i == 0 else "wander_hidden:") + name_v
						if first_only:
							return out
	return out


## THE OCCLUDERS as their real triangles, in a private physics space that lives only while a spot is
## searched: a body added to a private PhysicsServer3D space answers a query in the same frame
## (measured for replay_board_prop.gd, 2026-09-13), where the world's own space would need a physics step.
## `use_centre`/`centre_override`/`reach_override`: `open_sight`'s way of aiming this at an arbitrary
## point with an arbitrary reach (a boolean flag rather than a sentinel Vector3, since Vector3 has no
## built-in "unset" value) - every other caller (the ordinary landing-spot search) leaves them at the
## defaults and gets the old behaviour: centred on the landed astronaut, reach sized to the search
## lattice this file already uses (AHEAD_MAX_M / SIDE_MAX_M).
func _open_sight_space(use_centre: bool = false, centre_override: Vector3 = Vector3.ZERO, reach_override: float = -1.0) -> void:
	if _space.is_valid():
		return
	_space = PhysicsServer3D.space_create()
	PhysicsServer3D.space_set_active(_space, true)
	var root := get_tree().root
	var roots: Array[Node] = []
	if planet.props_root != null:
		roots.append(planet.props_root)
	for path: String in ["World/Decorations", "World/Buildings", "World/BuildBench", "World/TrashField"]:
		var n := root.get_node_or_null(path)
		if n != null:
			roots.append(n)
	var pad_node := root.get_node_or_null("World/Rocket")
	if pad_node != null:
		roots.append(pad_node)
	var rocket: Node3D = pad_node.get("rocket") as Node3D if pad_node != null else null
	var centre := centre_override if use_centre else _astronaut_xf.origin
	var reach := 0.0
	for v: Dictionary in _views:
		reach = maxf(reach, (v["eye"] as Vector3).distance_to(centre))
	reach = maxf(reach, Vector2(AHEAD_MAX_M, SIDE_MAX_M).length()) + 2.0
	if reach_override > 0.0:
		reach = reach_override
	var shapes := {}
	var stack: Array[Node] = roots.duplicate()
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		# The pad's waypoint gem only shows to a player far from the pad, never at a landing.
		if n == rocket or str(n.name) == "Waypoint":
			continue
		var mi := n as MeshInstance3D
		if mi != null and mi.mesh != null and mi.is_visible_in_tree() and _near(mi.global_transform, mi.get_aabb(), centre, reach) \
				and _stands_up(mi.global_transform, mi.get_aabb()) and not _is_glow(mi):
			_add_sight_body(mi.global_transform, _trimesh(mi.mesh, shapes), str(mi.get_path()))
		for c: Node in n.get_children():
			stack.append(c)
	if rocket != null:
		var pad_root := pad_node.get_node_or_null("Pad") as Node3D
		var rest: Variant = pad_node.get("_rest_xf")
		var rest_local: Transform3D = rest if rest is Transform3D else Transform3D(Basis.IDENTITY, Vector3(0.0, PAD_DECK_Y, 0.0))
		var rest_root := (pad_root.global_transform if pad_root != null else planet.pad_transform()) * rest_local
		var to_rocket := rocket.global_transform.affine_inverse()
		for m: Node in rocket.find_children("*", "MeshInstance3D", true, false):
			var rm := m as MeshInstance3D
			if rm.mesh != null and rm.visible:
				_add_sight_body(rest_root * (to_rocket * rm.global_transform), _trimesh(rm.mesh, shapes), "rocket at rest:" + str(rm.name))
	var body := CapsuleShape3D.new()
	body.radius = ASTRONAUT_RADIUS_M
	body.height = ASTRONAUT_HEIGHT_M
	shapes["astronaut"] = body
	_add_sight_body(_astronaut_xf * Transform3D(Basis.IDENTITY, Vector3(0.0, ASTRONAUT_HEIGHT_M * 0.5, 0.0)), body, "astronaut")
	_sight_shapes = shapes.values()


## A glow sprite (additive, never writes depth: MaterialLib.glow_sprite's star.gdshader, the pad beacon's
## halo) or a billboard hides nothing, and its quad as authored is not where it is drawn. MEASURED: the
## pad's BeaconHalo quad turned down 187 of the framed pass's spots at world load on 2026-09-13.
static func _is_glow(mi: MeshInstance3D) -> bool:
	var mat: Material = mi.material_override
	if mat == null and mi.mesh.get_surface_count() > 0:
		mat = mi.get_active_material(0)
	if mat is ShaderMaterial and (mat as ShaderMaterial).shader != null:
		var code := (mat as ShaderMaterial).shader.code
		return code.contains("blend_add") or code.contains("depth_draw_never")
	if mat is BaseMaterial3D:
		var bm := mat as BaseMaterial3D
		return bm.blend_mode == BaseMaterial3D.BLEND_MODE_ADD or bm.billboard_mode != BaseMaterial3D.BILLBOARD_DISABLED
	return false


func _close_sight_space() -> void:
	for b: RID in _sight_bodies:
		PhysicsServer3D.free_rid(b)
	_sight_bodies.clear()
	_sight_names.clear()
	if _space.is_valid():
		PhysicsServer3D.free_rid(_space)
	_space = RID()
	_sight_shapes.clear()


func _near(xf: Transform3D, box: AABB, centre: Vector3, reach: float) -> bool:
	var world := AABB(xf * box.position, Vector3.ZERO)
	for i in 8:
		world = world.expand(xf * box.get_endpoint(i))
	return centre.clamp(world.position, world.end).distance_to(centre) < reach


func _stands_up(xf: Transform3D, box: AABB) -> bool:
	var c := xf * box.get_center()
	var ground := planet.surface_point(planet.dir_of(c))
	var up := planet.up_at(c)
	for i in 8:
		if (xf * box.get_endpoint(i) - ground).dot(up) >= LOW_MESH_M:
			return true
	return false


static func _trimesh(mesh: Mesh, cache: Dictionary) -> Shape3D:
	var key := mesh.get_instance_id()
	if cache.has(key):
		return cache[key]
	var shape: Shape3D = null
	var faces := mesh.get_faces()
	for i in range(0, faces.size() - 2, 3):
		if (faces[i + 1] - faces[i]).cross(faces[i + 2] - faces[i]).length_squared() > 1e-10:
			var concave := ConcavePolygonShape3D.new()
			concave.set_faces(faces)
			concave.backface_collision = true
			shape = concave
			break
	cache[key] = shape
	return shape


func _add_sight_body(xf: Transform3D, shape: Shape3D, label: String) -> void:
	if shape == null:
		return
	var b := PhysicsServer3D.body_create()
	PhysicsServer3D.body_set_mode(b, PhysicsServer3D.BODY_MODE_STATIC)
	PhysicsServer3D.body_set_space(b, _space)
	PhysicsServer3D.body_add_shape(b, shape.get_rid())
	PhysicsServer3D.body_set_state(b, PhysicsServer3D.BODY_STATE_TRANSFORM, xf)
	PhysicsServer3D.body_set_collision_layer(b, 1)
	PhysicsServer3D.body_set_collision_mask(b, 0)
	_sight_bodies.append(b)
	_sight_names[b] = label


## The label of the first sight body on the line from a to b, or "".
func _ray_hit(a: Vector3, b: Vector3) -> String:
	var state := PhysicsServer3D.space_get_direct_state(_space)
	if state == null:
		return ""
	var q := PhysicsRayQueryParameters3D.create(a, b, 1)
	q.hit_back_faces = true
	var hit := state.intersect_ray(q)
	if hit.is_empty():
		return ""
	return str(_sight_names.get(hit.get("rid", RID()), "?"))


# ============================================================================= K2: ground and sight, on any world
## `_ready` only builds the caches `_ground_problem` reads (`_prompts`, `_deco_cache`, `_landing_dir`)
## when the world IS home - nowhere else has ever needed a spot check before Phase 5. K2 (the finale
## meeting, on the Commons) needs the same rules anywhere, so these three are public and rebuild
## whatever they need themselves rather than trusting `_ready` to have done it. `_ground_problem`
## itself was never home-specific (every check already reads `planet.data`/generic node paths), so
## nothing about its rules changes off home.

## Ground-rule verdict at `dir` on the CURRENT world (see "THE GROUND RULES"): "" when clear, otherwise
## the first rule broken ("water", "shore", "pad", "spawn", "landing", "stones", "house", "prompt:<x>",
## "prop", "decoration", "pickup", "trash", "slope" or "uneven"). Rebuilds the caches every call so a
## decoration placed a moment ago is never stale - cheap: no physics query runs here (`_rebuild_caches`
## measured on home for `_bring_in`; `view_report`'s ray casts, not this, are the costly part).
func ground_problem(dir: Vector3) -> String:
	if planet == null:
		planet = get_tree().get_first_node_in_group("planet") as Planet
	if planet == null or planet.data == null:
		return "no planet"
	_rebuild_caches()
	return _ground_problem(dir)


## Opens a private occluder space (see `_open_sight_space`'s header) around `centre`, `reach` metres
## out - generous enough by default (200 m) to cover any shipped world whole, so a caller need not
## measure its own scene first. Building it is the only cost; querying it with `sight_blocker` is
## then as cheap as a single ray cast. Always call `close_sight` when done (or the next `open_sight`
## call is a no-op: `_open_sight_space` refuses to rebuild over a space that is still open).
func open_sight(centre: Vector3, reach: float = 200.0) -> void:
	if planet == null:
		planet = get_tree().get_first_node_in_group("planet") as Planet
	_close_sight_space()
	_open_sight_space(true, centre, reach)


## The label of the first real occluder (a prop, a building, a decoration, the pad, the rocket at
## rest, the astronaut - never a glow sprite, see `_is_glow`) on the line from `a` to `b`, or "" when
## the line is clear. Needs `open_sight` first; "" (never a false "clear") when it was not called or
## already closed, so a caller that forgets it fails loudly in a debug_report rather than silently.
func sight_blocker(a: Vector3, b: Vector3) -> String:
	if not _space.is_valid():
		push_warning("VisitorSystem.sight_blocker: open_sight was never called (or already closed)")
		return ""
	return _ray_hit(a, b)


## Frees the occluder space opened by `open_sight` (or by the ordinary spot search - safe either way).
func close_sight() -> void:
	_close_sight_space()


# ============================================================================= helpers
static func _vec(a: Array) -> Vector3:
	if a.size() != 3:
		return Vector3.ZERO
	var v := Vector3(float(a[0]), float(a[1]), float(a[2]))
	return v.normalized() if v.length_squared() > 1e-6 else Vector3.ZERO


static func _npc_name(npc_id: String) -> String:
	return str(NpcData.get_data(npc_id).get("display_name", npc_id.capitalize()))


# ============================================================================= dev menu
## "Visitor today: <Name>": today's visit becomes this neighbour's, at once if you are at home. The first
## tap asks for their game (any game of theirs in this build, unlocked or not - a test row), the next tap
## on the same neighbour the same day switches it to a gift, and so on. Returns the toast text.
static func dev_force_visit(npc_id: String) -> String:
	var rec := record()
	var day := GameState.day_count
	var kind := "play"
	if not rec.is_empty() and int(rec["day"]) == day and str(rec["npc"]) == npc_id and bool(rec["forced"]) \
			and str(rec["kind"]) == "play":
		kind = "gift"
	var fresh := _blank(day, npc_id)
	fresh["forced"] = true
	_plan_request(fresh, kind)
	_write(fresh)
	var host := find()
	if host != null:
		host.call("restage")
	var what := ("game, %s" % fresh["game"]) if str(fresh["kind"]) == "play" \
		else ("gift, %s" % Catalog.get_item(str(fresh["item"])).get("name", fresh["item"]))
	var where := "" if GameState.current_planet_id == HOME_ID else " (at home)"
	return "Visitor: %s, %s%s" % [_npc_name(npc_id), what, where]


## "Clear today's visit": nobody visits today; the one standing here goes.
static func dev_clear_today() -> String:
	var fresh := _blank(GameState.day_count, "")
	fresh["forced"] = true
	_write(fresh)
	var host := find()
	if host != null:
		host.call("restage")
	return "No visitor today (day %d)." % GameState.day_count


## "Meet request": satisfies today's live request without a talk, so the neighbour hands it in the
## next time you speak to them - a "play" request's progress is filled straight to its count; a
## "gift" request gets a real placed instance of the gift on home (through DecorationManager when this
## world IS home, so it actually appears; a direct GameState.placed_decorations write otherwise, the
## same shape DecorationManager.place itself writes, since `request_met` only ever reads that saved
## list - a forced visit set from another world must still work once you fly home). No-op with a
## clear reason when there is no live, asked request to meet.
static func dev_mark_met() -> String:
	var rec := record()
	if rec.is_empty() or str(rec["npc"]) == "" or bool(rec["left"]) or bool(rec["done"]):
		return "No live visit request to meet."
	if not bool(rec["asked"]):
		return "%s has not asked yet; talk to them first." % _npc_name(str(rec["npc"]))
	if str(rec["kind"]) == "play":
		rec["progress"] = int(rec["count"])
		_write(rec)
		return "%s: game request ready to hand in." % _npc_name(str(rec["npc"]))
	var item_id := str(rec["item"])
	if item_id == "":
		return "This visit has no gift item set."
	var placed := false
	if GameState.current_planet_id == HOME_ID:
		var tree := Engine.get_main_loop() as SceneTree
		var deco: DecorationManager = tree.root.get_node_or_null("World/Decorations") as DecorationManager if tree != null else null
		if deco != null:
			var spot := _vec(rec.get("spot", []) as Array)
			if spot == Vector3.ZERO and deco.planet != null:
				spot = deco.planet.data.spawn_dir.normalized()
			placed = spot != Vector3.ZERO and deco.place(item_id, spot) != ""
	if not placed:
		GameState.add_placed_decoration(HOME_ID, "dev_visit_%d" % Time.get_ticks_msec(), item_id, Vector3.ZERO, Basis.IDENTITY)
	GameState.remove_item(item_id)
	_write(rec)
	return "%s: gift request ready to hand in." % _npc_name(str(rec["npc"]))


## "Re-roll today's visit": a fresh RANDOM pick among today's eligible neighbours, excluding whoever
## is already visiting today, so repeated taps cycle through different neighbours to test. This is
## NOT the natural day-seeded roll: `roll_visitor` is a pure function of the day, the eligible pool
## and YESTERDAY's neighbour, so calling it again for the same day would always return the exact same
## neighbour it already returned - a "re-roll" needs a dev-only substitute the same way
## `dev_force_visit` already is one. It cannot honour "never two days running" against the true
## yesterday either: the save keeps only ONE record (see the header's "SAVED STATE"), so once
## `ensure_today` has written today's, yesterday's neighbour is gone for good - that rule is
## exercised by the natural schedule alone (`debug_schedule`), never by this dev row.
static func dev_reroll_today() -> String:
	var day := GameState.day_count
	var rec := record()
	var today_npc := str(rec["npc"]) if not rec.is_empty() and int(rec["day"]) == day else ""
	var pool: Array[String] = []
	for n: String in eligible_neighbours():
		if n != today_npc:
			pool.append(n)
	if pool.is_empty():
		return "No other eligible neighbour to re-roll to."
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var picked: String = pool[rng.randi_range(0, pool.size() - 1)]
	var fresh := _blank(day, picked)
	fresh["forced"] = true
	_plan_request(fresh, "")
	_write(fresh)
	var host := find()
	if host != null:
		host.call("restage")
	return "Visitor: %s (re-rolled)" % _npc_name(picked)


# ============================================================================= QA
## One line a probe or a critic can assert against. Prints only.
func debug_report(tag: String = "") -> void:
	var rec := record()
	var vis := "none"
	if visitor != null and is_instance_valid(visitor):
		var home := visitor.home_dir
		vis = "%s at=%s home=%s wander_m=%.2f ground=%s marker=%d" % [visitor.npc_id,
			str(planet.dir_of(visitor.global_position)).replace(" ", ""), str(home).replace(" ", ""),
			planet.surface_distance(planet.dir_of(visitor.global_position), home),
			_ground_problem(planet.dir_of(visitor.global_position)) if not _views.is_empty() else "?",
			wants_marker(visitor.npc_id)]
	var ms := _minigames()
	var game := "none"
	if ms != null and bool(ms.call("is_running")):
		game = "%s owner=%s progress=%s" % [ms.call("running_kind"), ms.call("running_owner"), str(ms.call("progress"))]
	print("VISIT %s planet=%s day=%d rec=%s visitor=[%s] pass=%s note=%s owner=%s pending=%s game=[%s] met=%s" % [
		tag, GameState.current_planet_id, GameState.day_count, JSON.stringify(rec), vis, spot_pass, spot_note,
		_owner, str(_game_pending), game, str(request_met(rec))])


## The spot's measured distances, for a critic: pad, spawn, landing, stones line, bench, house, nearest
## decoration and prop, and the frame report from both landing cameras.
func debug_spot_report(tag: String = "") -> void:
	var rec := record()
	var d := _vec(rec.get("spot", []) as Array)
	if d == Vector3.ZERO or planet == null:
		print("VISITSPOT %s none" % tag)
		return
	_rebuild_caches()
	var pad := planet.data.pad_dir.normalized()
	var spawn := planet.data.spawn_dir.normalized()
	var n := pad.cross(spawn).normalized()
	var bench := get_tree().root.get_node_or_null("World/BuildBench") as Node3D
	var nearest_deco := INF
	for r: Dictionary in _deco_cache:
		nearest_deco = minf(nearest_deco, planet.surface_distance(d, r["dir"] as Vector3) - float(r["footprint"]))
	var rep := view_report(d, false)
	_close_sight_space()
	var views := PackedStringArray()
	for v: Dictionary in rep["views"]:
		views.append("%s rect=%s blocked=%d/%d by=%s" % [v["name"], str(v["rect"]), v["blocked"], v["lines"], v.get("by", "")])
	print("VISITSPOT %s pad=%.2f spawn=%.2f landing=%.2f stones_line=%.2f bench=%.2f house=%.2f deco_edge=%.2f prop=%.2f ground=%s view=%s [%s]" % [
		tag, planet.surface_distance(d, pad), planet.surface_distance(d, spawn),
		planet.surface_distance(d, _landing_dir), absf(asin(clampf(d.dot(n), -1.0, 1.0))) * planet.radius,
		(planet.surface_point(d).distance_to(bench.global_position) if bench != null else -1.0),
		planet.surface_distance(d, planet.building_dir("player_home")), nearest_deco,
		planet.nearest_prop_distance(d), _ground_problem(d), rep["problem"], "; ".join(views)])


## QA: re-runs the framed pass over its whole lattice and prints how many spots each rule turned down.
func debug_search_tally(tag: String = "") -> void:
	if planet == null:
		return
	_rebuild_caches()
	var lat := _landing_dir.cross(_away).normalized()
	if lat.dot(planet.data.spawn_dir.normalized()) < 0.0:
		lat = -lat
	var tally := {}
	var passed := PackedStringArray()
	for ix in range(int(round(AHEAD_MIN_M / SEARCH_STEP_M)), int(round(AHEAD_MAX_M / SEARCH_STEP_M)) + 1):
		for iy in range(-int(round(SIDE_MAX_M / SEARCH_STEP_M)), int(round(SIDE_MAX_M / SEARCH_STEP_M)) + 1):
			var c := Vector2(ix, iy) * SEARCH_STEP_M
			var d := _lattice_dir(_landing_dir, _away, lat, c.x, c.y)
			var why := _ground_problem(d)
			if why == "":
				why = _view_problem(d)
			if why == "":
				passed.append("%.1f/%.1f" % [c.x, c.y])
			var key := why.get_slice(":", 0) + (":" + why.get_slice(":", 1) if why.begins_with("prompt") or why.contains("hidden") or why.begins_with("offscreen") else "")
			tally[key] = int(tally.get(key, 0)) + 1
	_close_sight_space()
	print("VISITTALLY %s %s passed=[%s]" % [tag, JSON.stringify(tally), ",".join(passed)])


## QA: the spot the real `_pick_spot` gives for each of `days` days from today - with each one re-run
## through the ground and frame rules, how long the search took, and how far the visitor's column sits
## from the landed astronaut's in each landing frame ("behind the player's head" is an overlap of 0.00).
## How many are distinct (further apart than a quarter of a metre) and how far apart they are.
## Restores the day. Prints only; nothing is written and no visitor is moved.
func debug_spot_spread(tag: String, days: int) -> void:
	if planet == null:
		return
	var keep := GameState.day_count
	var dirs: Array[Vector3] = []
	var behind := 0
	for i in days:
		GameState.day_count = keep + i
		_rebuild_caches()
		var t0 := Time.get_ticks_usec()
		var d := _pick_spot()
		var us := Time.get_ticks_usec() - t0
		var ground := _ground_problem(d)
		var view := _view_problem(d)
		_close_sight_space()
		dirs.append(d)
		var gap := _head_gap(d)
		if gap <= 0.0:
			behind += 1
		print("VISITSPREAD %s day=%d dir=%s pass=%s ground=[%s] view=[%s] head_gap=%.3f pick_ms=%.1f note=%s" % [
			tag, GameState.day_count, str(d).replace(" ", ""), spot_pass, ground, view, gap,
			us / 1000.0, spot_note])
	GameState.day_count = keep
	var distinct: Array[Vector3] = []
	for d: Vector3 in dirs:
		var seen := false
		for e: Vector3 in distinct:
			if planet.surface_distance(d, e) < 0.25:
				seen = true
				break
		if not seen:
			distinct.append(d)
	var maxd := 0.0
	var sum := 0.0
	var pairs := 0
	for i in dirs.size():
		for j in range(i + 1, dirs.size()):
			var m := planet.surface_distance(dirs[i], dirs[j])
			maxd = maxf(maxd, m)
			sum += m
			pairs += 1
	print("VISITSPREAD %s days=%d distinct=%d max_apart_m=%.2f mean_apart_m=%.2f behind_head=%d" % [
		tag, days, distinct.size(), maxd, (sum / float(pairs) if pairs > 0 else 0.0), behind])


## QA: the smallest gap, in screen widths, between the visitor's column at `d` and the landed
## astronaut's column, over both landing cameras. <= 0 means the two overlap - the visitor is behind
## the player's head in that settled frame. `_build_views` must have run.
func _head_gap(d: Vector3) -> float:
	if _views.is_empty() or d == Vector3.ZERO:
		return 1.0
	var worst := 1.0
	for v: Dictionary in _views:
		var them := _column_rect(v, planet.surface_transform(d), COLUMN_HALF_M, COLUMN_TOP_M)
		var me := _column_rect(v, _astronaut_xf, ASTRONAUT_RADIUS_M, ASTRONAUT_HEIGHT_M)
		if them.size == Vector2.ZERO or me.size == Vector2.ZERO:
			continue
		var gap: float = maxf(maxf(them.position.x - me.end.x, me.position.x - them.end.x),
			maxf(them.position.y - me.end.y, me.position.y - them.end.y))
		worst = minf(worst, gap)
	return worst


## The screen rectangle (in the same -1..1 units as VIEW_SAFE) of an upright box `half` wide and
## `top` tall standing at `xf`, seen from the landing camera `v`.
func _column_rect(v: Dictionary, xf: Transform3D, half: float, top: float) -> Rect2:
	var eye: Vector3 = v["eye"]
	var basis: Basis = v["basis"]
	var up := xf.basis.y
	var side := basis.x - up * basis.x.dot(up)
	side = side.normalized() if side.length_squared() > 1e-6 else xf.basis.x
	var rect := Rect2()
	var first := true
	for c: Vector3 in [xf.origin - side * half, xf.origin + side * half,
			xf.origin - side * half + up * top, xf.origin + side * half + up * top]:
		var rel := c - eye
		var depth := -basis.z.dot(rel)
		if depth < 0.5:
			return Rect2()
		var sp := Vector2(basis.x.dot(rel) / depth / float(v["tan_x"]), basis.y.dot(rel) / depth / float(v["tan_y"]))
		rect = Rect2(sp, Vector2.ZERO) if first else rect.expand(sp)
		first = false
	return rect


## `ground_problem(dir)`, printed - lets a Director timeline or a critic assert the exact rule name
## on ANY world (K2's Commons meeting spots, most of all), not only home. Prints only.
func debug_ground_problem(tag: String, dir: Vector3) -> void:
	print("VISITGROUND %s dir=%s problem=%s" % [tag, str(dir), ground_problem(dir)])


## Opens a sight space at `centre`/`reach`, prints the blocker on the line from `a` to `b`, then
## closes it - one call for a Director timeline or a critic to assert `sight_blocker`'s answer
## without managing `open_sight`/`close_sight` by hand. Prints only.
func debug_sight_blocker(tag: String, centre: Vector3, a: Vector3, b: Vector3, reach: float = 200.0) -> void:
	open_sight(centre, reach)
	print("VISITSIGHT %s blocker=%s" % [tag, sight_blocker(a, b)])
	close_sight()


## SYNTHETIC SCHEDULE PROBE: writes GameState.day_count for each of `days` days from `from_day`, runs
## the same `ensure_today` a home load runs, marks the visit left (as flying away would), and prints one
## line per day. Restores the day and the flag afterwards. Director runs only.
static func debug_schedule(from_day: int, days: int) -> void:
	if not Director.is_active():
		return
	var keep_day := GameState.day_count
	var keep_flag: Variant = GameState.flags.get(FLAG_KEY)
	GameState.flags.erase(FLAG_KEY)
	var visits := 0
	var prev := ""
	var repeats := 0
	for i in days:
		GameState.day_count = from_day + i
		var rec := ensure_today()
		var again := ensure_today()
		var npc := str(rec.get("npc", ""))
		if npc != "":
			visits += 1
			if npc == prev:
				repeats += 1
		print("VISITDAY day=%d visit_day=%s npc=%s kind=%s game=%s item=%s count=%d stable=%s eligible=%s" % [
			GameState.day_count, str(is_visit_day(GameState.day_count)), npc, rec.get("kind", ""), rec.get("game", ""),
			rec.get("item", ""), int(rec.get("count", 0)), str(JSON.stringify(rec) == JSON.stringify(again)),
			",".join(eligible_neighbours())])
		prev = npc
		mark_left("schedule probe")
	print("VISITDAYS from=%d days=%d visits=%d same_npc_two_days_running=%d" % [from_day, days, visits, repeats])
	GameState.day_count = keep_day
	if keep_flag == null:
		GameState.flags.erase(FLAG_KEY)
	else:
		GameState.flags[FLAG_KEY] = keep_flag
