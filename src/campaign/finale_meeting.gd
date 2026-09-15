extends Node
## THE MEETING AND THE CHOICE (docs/PHASE5_SPEC.md §2 "Meeting", "Choice"; §0 "The ending always plays at
## night"; docs/BUILD_PLAN.md Phase 5 builder K2). finale.gd creates this node, by path, as
## /root/World/FinaleMeeting whenever the Commons loads at finale stage 1, 2 or 3, during World._ready.
##
## WHAT HAPPENS, by the stage it was created at:
##   1 CALLED  the crowd is already standing when you land; once the world is calm (no fade, no landing,
##             control in your hands) the astronaut walks to a mark 3.6 m out facing them, the §3 MEETING
##             lines play on this node's own camera, stage 2 is written and checkpointed, and the
##             Professor asks. "Send her" emits `chose_send`; "Give me a moment" (or cancel) plays his
##             moment line and hands control back: free roam, flying allowed, a line from each friend when
##             you talk to them, and the Professor's "!" asks again.
##   2 MET     the crowd on its saved spots, free roam straight away, the Professor's "!" asks again.
##   3 SENT    the crowd staged, nothing said; finale.gd calls `play_send_beat()` then the send-off.
##
## THE NIGHT SWITCH (§0). `_ready` runs inside World._ready, before the Commons draws its first frame:
## it holds the clock (Environment.time_scale 0) and jumps it to NIGHT_HOUR, snaps every building's lamps
## to the new hour (building_base.gd otherwise fades them in over ~2 s) and re-announces the phase after
## Environment's own deferred "day" announcement, so the music does not stay on the day track. The clock
## stays held through the meeting, free roam, the send-off and the gift; `release()` and `_exit_tree()`
## (flying away, quitting, any scene change) put back the time_scale this node found.
##
## THE CROWD (§2). Axis `h`: AXIS_COUNT candidates AXIS_STEP_DEG apart round the pad, starting on the
## landing side (world.gd's pad-arrival spot). Front row FRONT_M out, GAP_M apart: Grig, Fen, Zorp,
## Professor, Bolt, Vela (the astronaut's left to right); back row BACK_M, in four of the five gaps, in
## order Pip, Pop, Stella, DJ Nova - a back slot starting as far out as its front neighbours slid (K2R) -
## the open gap chosen by measured head heights (`_back_gaps`), so the
## back row shows over the front row from the lowest camera. Each slot must pass VisitorSystem's ground rules (HOOKS' `ground_problem`: water, shore, pad,
## spawn, landing, stones, house, prompts, props, decorations, pickups, trash, slope, uneven) plus the
## replay board, sliding SLIDE_M outward up to SLIDES times. Layouts are tried in three passes:
##   framed       every slot passes and the W shot solves with every head clear on real triangles (the first
##                FRAMED_TRIES clear-ground axes, then - K2R - the other clear-ground axes and the half-step
##                axes between the 24, "framed-half", within FRAMED_BUDGET_MS of the load)
##   framed-spot  every slot passes and every head is in clear sight of the astronaut's mark
##   near         every slot passes
## and, only if no axis passes at all, the axis with the fewest failing slots (logged). The result goes to
## `FinaleState.set_spots` (planet directions) and is re-checked on every load: a saved layout whose slots
## all still pass is used as it is ("saved"), otherwise the search runs again.
## The five friends spawn as visitors (`visit_host` = this node, `visit_home` = their slot); the Commons
## five get the same fields before their first physics frame. Nobody wanders until `release()`.
##
## THE CAMERA (§2). Its own Camera3D, `camera()`, driven on the clock (MAX_STEP per frame, so a stall
## slows it rather than jumping it), from START_AFTER_S of scene time. Every move is a pursuit of a goal
## pose with a speed factor that ramps at CAM_ACC and brakes to arrive, capped at CAM_VMAX m/s, CAM_WMAX
## deg/s and CAM_FOVMAX deg/s (under §2's 2.5 m/s and 35 deg/s). A new goal mid-move keeps the speed
## factor, so there is no step. Nothing moves the camera without a goal, so after FinaleLaunch.finished
## writes its last frame into `camera()` it stays exactly there until the next `camera_to`.
## Rules, each solved against the real standing positions, searched over the frames after the load
## (SLICE_USEC a frame) and cached: every candidate first on cheap gates and a prism cover test (each head
## and body a round-footprint prism from its mesh bounds), then the best RAY_TRIES on the fine cover test
## (`_fine_cover`: inside each head's disc - the rendered measure's own region - a FINE_GRID of sight lines
## run against every mesh box of every neighbour, facing the way the meeting holds them in that shot, and
## the astronaut; a sample is covered when a box nearer along that line holds it) plus HEAD_RAYS of
## VisitorSystem's sight lines per head on real triangles for props, buildings, decorations and the pad.
## Sight lines and the lens test only add failures, so they run on EVERY candidate that could still become
## the result (round 1 ran them only on candidates with no failure, so a fallback was never checked).
## MEASURED (K2 round 2, showcase/finale_k2_probe.gd `_pairs`, 985 heads in every shot of 12 decoration
## layouts): the fine test's estimate minus the rendered cover averaged +0.013 and fell under it by more than
## 0.05 on 5 heads (0.10 at most); round 1's box rectangles averaged +0.039 and failed 65 heads the frame
## showed at most 15% covered. So a passing frame leaving a head within PASS_COVER_GAIN of MAX_COVER keeps
## looking (OK_TRIES) for a clearer one.
##   W  over the astronaut's shoulder: all ten heads inside 20-60% from the top, front heads >= 10% of
##      the frame height, back heads >= 7%, none more than 20% covered
##   P  the speaker (§0 Round 4 rulings): head >= 18% of the frame height, 20-60% from the top, clear of the
##      box, <= 20% covered, and NO OTHER HEAD in frame drawn taller than LOOM_MAX x the speaker's head; for
##      the ask ("PA") the Professor sits left of the pills and no head is under them. All HARD (HARD_W).
##      Other heads may be covered, cropped or under the box. The lens test reaches P_FG_SHARE of the way to
##      the speaker. Back-row speakers (Pip, Pop, Stella, DJ Nova) get no close-up: their P is W's framing,
##      and so is a front-row P with no passing framing (logged "P:<id> uses W"); such a box waits for the
##      camera (CAMERA_WAIT_MAX) and the speaker plays SPEAKER_MOVE as it opens. PA never falls back.
##   U  beside the crowd looking up: the whole rock in frame and >= 20% of its height; every head that
##      shows at all is whole, inside 20-60% from the top, clear of the box and uncovered (more of them
##      score better; a rock with no head passes)
##   S  a screen split (§0 Round 3 rulings, SPLIT_MARGIN): every crowd head that shows has its centre at
##      <= 0.47 or every one at >= 0.53 of the frame width, the astronaut's and the rocket's centres on the
##      other half; >= 6 heads whole, the whole rocket in frame; any raised angle down to S_MAX_DOWN. No
##      candidate passing the split and the cover gate -> W's framing, logged "S falls back to W"
##   R  the pad three-quarter with the crowd (solved for `camera_to`, not used by the meeting: see TURN_RULE)
## S falls back to W's framing whenever it fails; R when it fails and W passes. THE LENS (`_foreground`): no prop,
## decoration, building, pad or rocket mesh - glow globes included - may show within `reach` of the lens,
## where reach is FOREGROUND_M or half the way to the nearest head, whichever is longer (a mesh's box
## proposes, real triangles confirm; a glow shape outside VisitorSystem's space is judged by its box), and
## FG_COLS x FG_ROWS sight lines across the frame find anything else; in W, U, S and R no friend may stand
## within FOREGROUND_M of it either. No shot looks down more than `_max_down`. Every
## candidate is scored by the gates first and by how far the camera must travel from the shot before it
## second. §3 tags only U and S; the rest: W for Zorp's opening line, P for every other speaker, S for "all
## turn to the rocket" (TURN_RULE), P then W for the send beat (SEND_RULES), and for the meeting's final
## ask (finale_lines.gd leaves it untagged) P - the Professor, framed left of the pills ("PA").
##
## THE CHOICE (§2). `ask(prof, prompt, ["Give me a moment", "Send her"], ARM_DELAY)`: the focus starts on
## "moment" (index 0), cancel (-1) means moment, no timer. While the choice is open this node eats (at the
## press edge, in `_input`, before the GUI sees it) every touch or mouse press made before the pills show
## or within ARM_DELAY of their first frame - DialogueBox's own arm is checked on the button's release,
## which let a press inside the arm answer - and every press that follows another pointer event by less
## than QUIET_MS (SkipConfirm's MIN_ARM_MS rule; a tap's emulated mouse press counts with its touch): a
## 10 taps/s train can never open that gap, so it can never answer, while a deliberate tap after a pause
## answers at once. `--finale-trace` logs every guarded press with its ms since the pills.
## THE PILLS WAIT FOR THE CAMERA (§0 Round 3 rulings, `_pills_tick`): the prompt box shows during the blend
## to the ask's framing, the pills stay hidden (and every arm held) until this node's camera has settled,
## and the frame they pop in is the pills' first frame, from which both arms count.
##
## THE SEND-OFF HAND-OFF. FinaleLaunch.opening_frame(self) is worked out inside the load with the crowd,
## the astronaut and the rocket put for a moment where the send beat leaves them (`_precompute_opening`), so
## its sight lines never stall the beat; play_send_beat ends with `camera()` settled on it.
##
## THE SIGHT SPACE. VisitorSystem has ONE occluder space; FinaleLaunch's side pick and VisitorSystem's own
## spot search open and close it too. `_sight` re-opens it when someone closed it between two slices of the
## search (MEASURED, K2S: the gift debug entry's apply_end_state closed it the frame after the meeting's first
## slice and 4,338 "open_sight was never called" warnings followed, every sight line reading clear).
##
## WARM-UP (§7). At load, behind the SceneRouter fade (where a first compile costs no visible frame), and
## again in the first meeting box: a 2 cm quad of
## every GiantAsteroid.warm_materials() and FinaleLaunch.warm_materials() material and every
## FinaleLaunch.warm_nodes() node, 1 m before the drawing camera, low in the frame where the dialogue
## box panel covers them, for WARM_FRAMES frames, then freed.
##
## CONTRACT (§8 + K2's brief): signal `chose_send`, `crowd_ids()`, `npc(id)`, `axis()`, `mark()`,
## `asteroid()`, `camera()`, `camera_to(rule, ids, seconds)`, `say(id, lines)`, `say_turn(rule, id, lines)`,
## `uses_w_framing(rule, id)`, `ask(id, prompt, options, arm_delay)`, `play_send_beat()` (awaitable: Bolt's and the Professor's SEND boxes, the crowd strolls
## STEP_BACK_M back, the ladder stows, the astronaut waves, the camera settles on
## FinaleLaunch.opening_frame(self)), `release()` (friends become ordinary visitors). Visit host for
## npc.gd and conversation.gd: `wander_ok`, `wants_marker`, `handle_conversation`.
## Every other file is reached by path (FinaleState, FinaleLines, FinaleLaunch, GiantAsteroid,
## VisitorSystem, VisitorLines): this one parses with any of them missing, and a missing one degrades the
## beat instead of stopping it.
##
## TRACE. `--finale-trace=<file>` appends "K2 beat ..." lines at beat boundaries and "K2 cam <frame>
## <clock s> <px py pz> <qx qy qz qw> <fov> <rule>" for every frame this node's camera draws, in batches.

signal chose_send
signal camera_arrived

const FINALE_STATE_PATH := "res://src/campaign/finale_state.gd"
const LINES_PATH := "res://src/campaign/finale_lines.gd"
const LAUNCH_PATH := "res://src/campaign/finale_launch.gd"
const ASTEROID_PATH := "res://src/campaign/giant_asteroid.gd"
const VISITOR_SYSTEM_PATH := "res://src/campaign/visitor_system.gd"
const VISITOR_LINES_PATH := "res://src/campaign/visitor_lines.gd"
const NPC_DIR := "res://src/characters/npcs/"
const TRACE_TAG := "K2"
const MODAL_NAME := "cutscene"

# ------------------------------------------------------------------------------------ the crowd (§2)
const FRONT: PackedStringArray = ["grig", "fen", "zorp", "mayor_orbit", "bolt", "vela"]
const BACK: PackedStringArray = ["pip", "pop", "stella", "dj_nova"]
const FRIENDS: PackedStringArray = ["zorp", "bolt", "fen", "grig", "vela"]
const PROF := "mayor_orbit"
const FRONT_M := 6.0
const BACK_M := 7.4
const GAP_M := 1.0
const MARK_M := 3.6
## The front row stands at -2.5 .. 2.5; the back row, in its §2 order, takes four of the five gaps between
## them. Which gap stays open is measured, not chosen by eye: `_back_gaps` keeps the one that lets every
## back-row head clear its two front neighbours from the lowest camera behind the mark.
const FRONT_LATS: Array[float] = [-2.5, -1.5, -0.5, 0.5, 1.5, 2.5]
## A back-row head counts as clear with this share of it above the sight line over its neighbours (§2's
## "no head more than 20% covered").
const CLEAR_SHARE := 0.2
const AXIS_COUNT := 24
const AXIS_STEP_DEG := 15.0
const SLIDE_M := 0.5
const SLIDES := 3
## world.gd's pad-arrival spot: this far to the pad's `pad_dir x UP` side. The axis search starts there.
const LANDING_SIDE_M := 3.2
## The replay board (replay_board_prop.gd FOOTPRINT_M 0.95) plus VisitorSystem's DECO_GAP_M 0.6 and a
## neighbour's body radius (npc.gd BODY_RADIUS 0.34).
const BOARD_CLEAR_M := 1.9
## "The crowd steps back 1 m" (§2 Send).
const STEP_BACK_M := 1.0
## After the story: npc.gd samples wander targets 1.4 m and more out, VisitorSystem.WANDER_M.
const RELEASED_WANDER_M := 1.6

# ------------------------------------------------------------------------------------ clock and pacing
const NIGHT_HOUR := 21.0
const START_AFTER_S := 2.0
const CALM_HOLD := 1.0
const MAX_STEP := 0.05
const WALK_MPS := 2.5
## player.gd WALK_SPEED is 4.2 m/s; the astronaut model reaches its full stride at 0.6 (astronaut_model.gd).
const WALK_SPEED_FACTOR := 0.6
const TURN_S := 0.45
const ARRIVE_M := 0.35
## "all turn to the rocket": the crowd's turn (npc.gd idle turn rate) and a held beat on R.
const TURN_BEAT_S := 1.8
const CAMERA_WAIT_MAX := 6.0
## The hand-back to the gameplay rig after "Give me a moment": measured 5.5 s from the ask's framing at the
## speed limits (8.3 m and a 22 deg FOV change), so the wait is long enough never to end on a snap.
const HANDBACK_MAX := 10.0
const WARM_FRAMES := 10

# ------------------------------------------------------------------------------------ camera
const CAM_VMAX := 2.35
const CAM_WMAX := 33.0
const CAM_FOVMAX := 20.0
const CAM_ACC := 1.4
const CAM_NEAR := 0.05
const CAM_FAR := 400.0

# ------------------------------------------------------------------------------------ framing gates (§2)
const BAND_TOP := 0.20
const BAND_BOT := 0.60
const W_FRONT_SHARE := 0.10
const W_BACK_SHARE := 0.07
const P_SHARE := 0.18
const U_ROCK_SHARE := 0.20
const MAX_COVER := 0.20
const FOREGROUND_M := 2.6
## A mesh lower than this off the ground is no lens occluder (VisitorSystem's LOW_MESH_M).
const LOW_OCC_M := 0.4
const FG_COLS := 9
const FG_ROWS := 5
## Points along a near part's height for the lens test's sight lines (a mast needs more than a globe).
const NEAR_LATTICE_Y := 5
## S is a SCREEN SPLIT, not a camera angle (§0 Round 3 rulings): every crowd head that shows has its centre
## on one half with this margin (all x <= 0.47 or all x >= 0.53 of the frame width), and the astronaut's and
## the rocket's screen centres are on the other half with the same margin. A raised three-quarter camera is
## fine when that holds. Round 2 gated the MEAN head x with a 55 deg side-on tolerance, and a 3/4 view from
## behind the crowd passed with Grig, Fen and Zorp (x 0.52-0.62) on the rocket's half.
const SPLIT_MARGIN := 0.03
const S_MAX_DOWN := 55.0
## S's own cover limit, under MAX_COVER: S can fall back to W, and its high, far views put props between the
## lens and small heads, where the fine estimate read 0.19 and the frame 0.28 (K2R seed 9200 layout 8, Bolt); 0.15 left every S of 12 layouts on W.
const S_COVER := 0.18
## The rocket's fins reach about this far from its axis (rocket_model.gd HULL_R 0.62 plus the fins).
const ROCKET_FRAME_R := 1.0
## Gate weights for P and PA (§0 Round 3 and Round 4 rulings). A candidate is ranked by its weighted
## failures: every P / PA gate is hard (the speaker's share, band, box and cover, the Professor left of the
## pills, no head under the pills, no other head looming - LOOM_MAX); other heads' cover, band and box only
## rank. Round 2 let a cover fallback take W's framing for PA (seed 9100 layout 0: Bolt in the pill rect).
const HARD_W := 10
const SPEAKER_BAND_IN := 0.01
## §0 Round 4 rulings: in P and PA no other head in frame may be drawn taller than LOOM_MAX times the
## speaker's head (nothing looms in front of the speaker); the other heads' cover, band and box are free.
## The search holds LOOM_SOLVE, a little under the gate: the live heads stand a few cm off their slots.
const LOOM_MAX := 1.1
const LOOM_SOLVE := 1.05
## P / PA candidate grid (`_p_candidates_step`): the lens P_DISTS from the speaker's head, P_ELS above it,
## swung up to P_YAW_MAX deg (P_YAW_STEP apart) either side of facing the mark; the head fitted to
## P_FIT_SHARES of the frame height with its centre at P_XS of the frame width. MEASURED (K2S round 2, offline
## model of the gates on seed 9300's 12 layouts, k2s/model/gg2.py, then the game): once the lens stays within
## FACE_MAX_DEG and the helmet may not loom either, the round-1 grid (xs 0.15-0.85 in 5, 1.6-4.2 m, els
## 0-2.8) found no P for Zorp on any layout; with these 7 xs, 1.6-3.2 m and els -0.3-1.2 every front-row
## speaker has 15-310 passing framings per layout (the 4.2 m lens and the 2.0 m+ rise never passed).
const P_XS: Array[float] = [0.1, 0.2, 0.3, 0.5, 0.7, 0.8, 0.9]
const P_DISTS: Array[float] = [1.6, 2.0, 2.4, 2.8, 3.2]
const P_ELS: Array[float] = [-0.3, 0.0, 0.3, 0.6, 0.9, 1.2]
const P_YAW_MAX := 45
const P_YAW_STEP := 9
const P_FIT_SHARES: Array[float] = [0.25]
## PA (the ask, the Professor left of the pills) never falls back and has few framings left once nothing may
## loom: on P's grid it failed 3 of 12 layouts (a decoration by the lens, Zorp looming), on this finer
## one 1 (seed 9306: a robot statue 0.6 m in front of the mark, lens test only) - the same with 4 xs and 3
## shares as with these 3 and 2, which halve its cost (147 -> 85 ms of search).
const P_XS_PA: Array[float] = [0.1, 0.16, 0.26]
const PA_DISTS: Array[float] = [1.8, 2.1, 2.4, 2.7, 3.0, 3.4, 3.8, 4.6]
const PA_ELS: Array[float] = [-0.3, -0.1, 0.1, 0.3, 0.5, 1.0, 1.8, 2.8]
const PA_YAW_STEP := 5
const PA_YAW_MAX := 45
## A close-up faces its speaker (K2S critic 1): the lens stands at most FACE_MAX_DEG off the way the speaker
## faces (the mark: `_hold_crowd(_mark_look())`), measured round the speaker on its ground plane. The round-1
## grid reached 75 deg, and the chain's P:grig (75), P:bolt (60-75) and P:vela (75) showed the speaker's back
## or side once the lens also looked down. Hard in `_gates` (the grids above stop at it too).
const FACE_MAX_DEG := 45.0
const PA_FIT_SHARES: Array[float] = [0.21, 0.27]
## The lens test's reach in P and PA (`_foreground`): this share of the way to the speaker's head, at least
## P_FG_MIN_M.
const P_FG_SHARE := 0.6
const P_FG_MIN_M := 1.0
## A close-up's lens keeps this far from every head's disc and body (0.35 elsewhere): the lens-test's
## friend check is off in P, and at 0.35 seed 9305's P:zorp stood 0.8 m from the Professor's ringed head
## (Zorp 0.95 covered in the rendered frame, the Professor behind the lens plane so never measured).
const P_EYE_CLEAR_M := 0.6
## Back-row speakers get no close-up (§0 Round 4 rulings): their boxes use W's framing, and so does a
## front-row speaker whose P found no framing. Such a box opens once the camera has settled on W (at most
## CAMERA_WAIT_MAX s: a P:grig -> W blend took 3.5 s), and the speaker plays SPEAKER_MOVE as it opens.
## MEASURED (K2S, the chain's W frames 0.5 s into Pip's and Pop's boxes): "wave" raised one arm that the
## front row's heads mostly hid (Pop's barely showed); "happy" hops the whole body and raises both arms. It
## also plays NPC.play_emote's soft "emote_happy" sound. Stella's model (the astronaut's) restarts its
## sparkles on "happy" - a first-emit stall (OPEN_ISSUES 62 C) - so a model that is not a ChibiModel waves.
const SPEAKER_MOVE := "happy"
const SPEAKER_MOVE_OTHER := "wave"
## The reach of the meeting's VisitorSystem occluder space round the pad.
const SIGHT_REACH_M := 26.0
## Cheap-gate failures sort after every weighted failure.
const CHEAP_FAILS := 1000
## Shot search budget per frame (§7: no frame over 50 ms once the meeting's clock runs), and how many of the
## best prism-tested candidates get the fine cover test (and, if they pass it, real sight lines).
const SLICE_USEC := 9000.0
const RAY_TRIES := 80
## Sight lines per head: its centre and six round its disc at 0.6 of its radius.
const HEAD_RAYS := 7
## Passing candidates a shot search looks through for a clearer frame when the first passing one leaves a
## head more than MAX_COVER - PASS_COVER_GAIN covered, and how much clearer another must be to win.
const OK_TRIES := 6
const PASS_COVER_GAIN := 0.08
## Layouts the load's "framed" pass solves W for (nearest the landing side first), inside the load.
const FRAMED_TRIES := 3
## After those, more layouts get the W solve (see `_choose_spots`) until this much of the load has gone.
const FRAMED_BUDGET_MS := 1500.0
## The dialogue box and the choice pills on the phone frame (dialogue_box.gd `_layout`, mobile theme,
## 720 px canvas): panel 70% of the width centred, bottom margin 34 px, a two-line panel reaching up to
## 0.675 of the height. The pills, MEASURED on the ask at 2556x1179 --ui=mobile once their pop-in has
## finished (K2R probe send2, ChoiceBox global rect at scale 1): x 875-1305 of a 1559 px canvas, y 340-542,
## i.e. 450-20 px left of the panel's right edge (1325). Round 2's 906-1274 x 354-527 was read one frame
## into the pop-in, at scale ~0.8, and was too small.
const BOX_TOP_Y := 0.675
const BOX_X := Vector2(0.15, 0.85)
const PILL_X_PX := Vector2(450.0, 20.0)
const PILL_Y_PX := Vector2(340.0, 542.0)
const CANVAS_H := 720.0
## The shots in the order the meeting and the send beat use them (each one's travel scored from the one
## before): Zorp's opening W, then each speaker, U, R for the turn, S, the ask, and the send beat.
const SHOT_SEQUENCE: Array = [["W", ""], ["P", "grig"], ["P", "mayor_orbit"], ["U", ""], ["P", "bolt"], ["P", "vela"],
	["P", "fen"], ["P", "pip"], ["P", "pop"], ["P", "zorp"], ["S", ""], ["PA", "mayor_orbit"], ["P", "bolt"], ["R", ""]]
## "All turn to the rocket" and the send beat's two boxes. R, the pad three-quarter, is not used by the
## meeting: over 12 decoration layouts its best framing left Pop 35-93% covered in the RENDERED frame (the
## back row only clears the front row's crowns from ~11 m out when the lens is 6-9 m up, and from there the
## rocket's nose pulls the look past 48 deg down), while S, the side-on, kept every head under 20%. R stays
## solved for `camera_to("R")`.
const TURN_RULE := "S"
const SEND_RULES: Array = ["P", "W"]
const CHOICE_ARM_OPTIONS: PackedStringArray = ["Give me a moment", "Send her"]
const ARM_DELAY := 0.6
const QUIET_MS := 400
## The longest the pills wait for the camera to settle (the S -> PA blend measured 6.3 s in round 2).
const PILLS_HOLD_MAX := 12.0
## Astronaut discs for the analytic cover test: height above the feet, radius.
const ASTRO_DISCS: Array[Vector2] = [Vector2(0.45, 0.36), Vector2(0.95, 0.36), Vector2(1.32, 0.34)]
const HEAD_DEFAULT := {"c_h": 1.05, "r": 0.36, "h": 0.66, "bottom": 0.72, "hw": 0.72}
## A head or a body is a square-footprint prism round its bounding box; its silhouette is taken as the
## equal-area rectangle inside the projected box (a rounded shape fills pi/4 of its box: sqrt(pi/4) a side).
const SILHOUETTE := 0.886
## Boxes kept per neighbour for the fine cover test (the largest by volume).
const PARTS_HEAD := 6
const PARTS_BODY := 6
const FINE_GRID := 7
const ASTRO_W := 0.7
## The astronaut's helmet (astronaut_model.gd HELMET_CY 1.087, base 0.752, crown 1.422, HELMET_R.x 0.372).
## K2S round 2: in P and PA it is GATED like a crowd head - kept clear of the pills, and never drawn taller
## than LOOM_MAX times the speaker's head when it shows (critic 1: ranked only, it was 2.8-3.3x in P:zorp and
## P:mayor_orbit and filled a third of the chain's frames). With the lens held within FACE_MAX_DEG of the
## speaker's facing the close-up can stand between the astronaut and the speaker, the helmet behind the lens.
const ASTRO_HEAD := {"c_h": 1.087, "h": 0.67, "r": 0.372}
const ASTRO_H := 1.55

enum Phase { STAGED, WAITING, MEETING, ROAM, SENDING, SENT, RELEASED }

var planet: Planet
var _world: Node
var _env: Node
var _pad: Node3D
var _rocket: Node3D
var _player: Player
var _rig: Node
var _vs: Node
var _lines: Script
var _phase: int = Phase.STAGED
var _stage0 := 0

var _pad_dir := Vector3.UP
var _pad_ground := Vector3.ZERO
var _R := 21.0
var _axis := Vector3.ZERO
var _axis_k := 0
var _dirs: Dictionary = {}
var _back_dirs: Dictionary = {}
var _mark_dir := Vector3.UP
var _mark := Vector3.ZERO
var _crowd_centre := Vector3.ZERO
var _spot_pass := ""
var _spot_note := ""
var _npcs: Dictionary = {}
var _ids: Array[String] = []
var _spawned: Array[Node] = []
var _head_info: Dictionary = {}
var _back_gaps_cache: Array[float] = []
var _talk_off: Array[Node] = []
var _asteroid: Node3D
var _opening: Array = []
var _rock_half_v := 8.0
var _rocket_rest := Transform3D.IDENTITY

var _cam: Camera3D
var _goal := Transform3D.IDENTITY
var _goal_fov := 45.0
var _has_goal := false
var _k := 0.0
var _kmax := 1.0
var _follow_rig := false
var _rule := ""
var _shots: Dictionary = {}
var _asp := 1560.0 / 720.0
var _sight_open := false
var _occ: Array = []
## The fine cover test's model: "ray" (round 2: sight lines through each sample against every part's box)
## or "rect" (round 1: box rectangles, depth by centre; probes compare the two).
var fine_model := "ray"
var _solving := false

var _clock := 0.0
var _dt_typical := 0.0
var _calm_t := 0.0
var _saved_time_scale := 1.0
var _clock_held := false
var _modal := false
var _walking := false
var _walk_from := Vector3.ZERO
var _walk_dir := Vector3.ZERO
var _sent := false
var _roam_marker := false

var _guard_on := false
var _guard_open_ms := 0
var _guard_last_ms := 0
var _guard_press_frame := -1
var _guard_eat := false
var _guard_eaten := 0
var _guard_passed := 0
var _guard_arm := ARM_DELAY
var _guard_pills_ms := -1
var _touches_down: Dictionary = {}
## Eat desktop-cursor motion while a finger is down on the open choice (see `_input`). A probe switch.
var eat_stray_motion := true
var _pills_hold_ms := -1
var _settled_frame := -1

var _trace_on := false
var _trace_rows := PackedStringArray()
var _frame := 0
var _stats := {}


# ============================================================================= set-up
func _ready() -> void:
	_world = get_parent()
	planet = get_tree().get_first_node_in_group("planet") as Planet
	_env = _world.get_node_or_null("Environment") if _world != null else null
	_pad = _world.get_node_or_null("Rocket") as Node3D if _world != null else null
	_rocket = _pad.get("rocket") as Node3D if _pad != null else null
	_player = get_tree().get_first_node_in_group("player") as Player
	_rig = _world.get_node_or_null("CameraRig") if _world != null else null
	_lines = load(LINES_PATH) as Script if ResourceLoader.exists(LINES_PATH) else null
	_stage0 = _fs_int("stage")
	for a: String in OS.get_cmdline_user_args():
		_trace_on = _trace_on or a.begins_with("--finale-trace=")
	# Before anything else: the first frame the Commons draws must already be night (§0).
	_night_switch()
	EventBus.planet_leave_requested.connect(_on_leave_requested)
	if planet == null or planet.data == null or _pad == null or _player == null:
		_log("a piece of the world is missing (planet/pad/player); no meeting")
		return
	var u0 := Time.get_ticks_usec()
	_asp = _viewport_aspect()
	_pad_dir = planet.data.pad_dir.normalized()
	_pad_ground = planet.surface_point(_pad_dir)
	_R = _pad_ground.distance_to(planet.global_position)
	_rocket_rest = _rest_rocket_xf()
	if ResourceLoader.exists(VISITOR_SYSTEM_PATH):
		_vs = load(VISITOR_SYSTEM_PATH).call("find")
	_spawn_crowd()
	_measure_heads()
	_collect_occluders()
	var u1 := Time.get_ticks_usec()
	_open_sight()
	var u2 := Time.get_ticks_usec()
	_choose_spots()
	var u3 := Time.get_ticks_usec()
	_place_crowd()
	_place_asteroid()
	# FinaleLaunch's own sight lines reuse VisitorSystem's single occluder space: close ours first, then
	# build it again for the shot search.
	_close_sight()
	_precompute_opening()
	_open_sight()
	# The shots are searched over the next frames (SLICE_USEC each); the sight space stays open until then.
	_solve_all()
	var u4 := Time.get_ticks_usec()
	_stats["setup_ms"] = [(u1 - u0) / 1000.0, (u2 - u1) / 1000.0, (u3 - u2) / 1000.0, (u4 - u3) / 1000.0]
	_beat("staged stage=%d pass=%s axis_k=%d %s ms spawn+heads %.1f sight %.1f spots %.1f place+opening+first-slice %.1f (opening_frame %.1f)" % [
		_stage0, _spot_pass, _axis_k, _spot_note, _stats["setup_ms"][0], _stats["setup_ms"][1],
		_stats["setup_ms"][2], _stats["setup_ms"][3], float(_stats.get("opening_ms", -1.0))])
	var hs := PackedStringArray()
	for id in _ids:
		var hi: Dictionary = _head_info[id]
		hs.append("%s:c%.2f,r%.2f,h%.2f,bot%.2f,btop%.2f,br%.2f" % [id, hi["c_h"], hi["r"], hi["h"], hi["bottom"], float(hi.get("body_top", -1)), float(hi.get("body_r", -1))])
	_beat("heads " + " ".join(hs) + " back_gaps " + str(_stats.get("back_gaps", "")))
	_warm("load")
	_run.call_deferred()


func _exit_tree() -> void:
	# Every exit this node sees - flying away mid-moment, quitting to the title, a Director scene change.
	_restore_clock()
	_end_modal()
	_guard_on = false
	if RenderingServer.frame_pre_draw.is_connected(_pills_tick):
		RenderingServer.frame_pre_draw.disconnect(_pills_tick)
	if _walking and _player != null and is_instance_valid(_player):
		_player.set("_speed_factor", 0.0)
		_player.set_physics_process(true)
	_walking = false
	_close_sight()
	_flush_trace()


func _on_leave_requested(_planet_id: String) -> void:
	_restore_clock()


# ============================================================================= contract (§8)
func crowd_ids() -> Array[String]:
	return _ids.duplicate()


func npc(id: String) -> Node3D:
	var n: Variant = _npcs.get(id, null)
	return n as Node3D if n != null and is_instance_valid(n) else null


## The meeting axis: a unit tangent at the pad, pointing from the pad out toward the crowd.
func axis() -> Vector3:
	return _axis


## The astronaut's mark (feet), MARK_M out along the axis.
func mark() -> Vector3:
	return _mark


func asteroid() -> Node3D:
	return _asteroid if _asteroid != null and is_instance_valid(_asteroid) else null


## This node's camera, created (seeded from the camera drawing now) on first use.
func camera() -> Camera3D:
	_ensure_camera(false)
	return _cam


func phase_name() -> String:
	return Phase.keys()[_phase]


## Blends `camera()` to a §2 rule ("W", "P", "U", "S", "R", "R2", "PA") for `ids` (P: the first id is the
## speaker). `seconds` is a minimum blend time; the limits may make it longer. Makes the camera current.
## Returns the estimated blend time.
func camera_to(rule: String, ids: Array = [], seconds: float = 0.0) -> float:
	var shot := _shot_for(rule, ids)
	if shot.is_empty():
		return 0.0
	_ensure_camera(true)
	_rule = rule + (":" + str(ids[0]) if not ids.is_empty() else "")
	if shot.has("w_for_p"):
		_rule = "W<-" + _rule
	return _set_goal(Transform3D(shot["basis"] as Basis, shot["eye"] as Vector3), float(shot["fov"]), seconds)


## Blends to an explicit pose (for a later beat that frames something of its own).
func camera_to_transform(xf: Transform3D, fov: float, seconds: float = 0.0) -> float:
	_ensure_camera(true)
	_rule = "xf"
	return _set_goal(xf, fov, seconds)


func camera_settled() -> bool:
	return not _has_goal


## One spoken meeting box the way the meeting plays it: `camera_to(rule, [id])`, and when that is W's
## framing standing in for P (a back-row speaker, or no P framing: §0 Round 4 rulings) the box waits for
## the camera to settle (at most CAMERA_WAIT_MAX s) and the speaker plays SPEAKER_MOVE as it opens.
## Awaitable. For probes and later beats.
func say_turn(rule: String, id: String, lines: Array) -> void:
	camera_to(rule, [id])
	await _w_box_wait(rule, id)
	if not is_inside_tree():
		return
	var runner := DialogueRunner.get_or_create(self)
	if runner == null:
		return
	if not runner.is_active():
		runner.begin(npc(id), _player)
	_beat("say_turn %s rule=%s%s" % [id, rule, " (W's framing: %s)" % _rule if _rule.begins_with("W<-") else ""])
	_speaker_move(rule, id)
	await runner.say(npc(id), lines)


## Whether `rule` for speaker `id` plays on W's framing (a P with no close-up).
func uses_w_framing(rule: String, id: String) -> bool:
	return rule == "P" and _shot_for("P", [id]).has("w_for_p")


func _w_box_wait(rule: String, id: String) -> void:
	if not uses_w_framing(rule, id):
		return
	await _await_camera(CAMERA_WAIT_MAX)


## The speaker's visible move as a W-framed box opens (an existing model state: SPEAKER_MOVE, or
## SPEAKER_MOVE_OTHER for a model that is not a ChibiModel).
func _speaker_move(rule: String, id: String) -> void:
	if not uses_w_framing(rule, id):
		return
	var n := npc(id)
	if n != null and n.has_method("play_emote"):
		var model: Variant = n.call("get_model") if n.has_method("get_model") else null
		var move := SPEAKER_MOVE if model is ChibiModel else SPEAKER_MOVE_OTHER
		n.call("play_emote", move)
		if _trace_on:
			_trace_rows.append("beat t=%.3f speaker move %s %s frame=%d" % [_clock, id, move, Engine.get_frames_drawn()])


## `lines` spoken by crowd member `id` in the shared dialogue box. Awaitable.
func say(id: String, lines: Array) -> void:
	var n := npc(id)
	var runner := DialogueRunner.get_or_create(self)
	if runner == null:
		return
	if not runner.is_active():
		runner.begin(n, _player)
	await runner.say(n, lines)


## A choice from crowd member `id`. Awaitable; the chosen index, or -1 on cancel. See THE CHOICE.
func ask(id: String, prompt: String, options: Array, arm_delay: float = ARM_DELAY) -> int:
	var runner := DialogueRunner.get_or_create(self)
	if runner == null:
		return -1
	return await _guarded_ask(runner, npc(id), prompt, options, arm_delay)


# ============================================================================= the night (§0)
func _night_switch() -> void:
	if _env == null:
		return
	_saved_time_scale = float(_env.get("time_scale"))
	_env.set("time_scale", 0.0)
	_clock_held = true
	if _env.has_method("set_time"):
		_env.call("set_time", NIGHT_HOUR)
	# building_base.gd reads the night factor once in _ready (the old hour) and then lerps its lamps toward
	# the new one over ~2 s; snap them so nothing visibly switches on.
	var buildings := _world.get_node_or_null("Buildings") if _world != null else null
	if buildings != null:
		for b: Node in buildings.get_children():
			if b.has_method("night_factor") and b.has_method("_apply_night") and "_night" in b:
				var f := float(b.call("night_factor"))
				b.set("_night", f)
				b.set("_night_target", f)
				b.call("_apply_night")
	# environment.gd queues day_phase_changed(<the hour it was built at>) deferred in its _ready; this one
	# is queued later, so the last word the music hears is the real phase.
	if _env.has_method("get_phase"):
		EventBus.day_phase_changed.emit.call_deferred(str(_env.call("get_phase")))


func _restore_clock() -> void:
	if not _clock_held:
		return
	_clock_held = false
	var env := _env if _env != null and is_instance_valid(_env) else null
	if env != null:
		env.set("time_scale", _saved_time_scale)


# ============================================================================= staging
func _rest_rocket_xf() -> Transform3D:
	var pad_root := _pad.get_node_or_null("Pad") as Node3D
	var rest: Variant = _pad.get("_rest_xf")
	var rest_local: Transform3D = rest if rest is Transform3D else Transform3D(Basis.IDENTITY, Vector3(0.0, 0.10, 0.0))
	return (pad_root.global_transform if pad_root != null else planet.pad_transform()) * rest_local


func _spawn_crowd() -> void:
	var root := _world.get_node_or_null("NPCs")
	if root == null:
		root = Node3D.new()
		root.name = "NPCs"
		_world.add_child(root)
	var all: PackedStringArray = FRONT.duplicate()
	all.append_array(BACK)
	for id in all:
		var n := root.get_node_or_null(id) as NPC
		if n == null:
			var path := NPC_DIR + id + ".tscn"
			if not ResourceLoader.exists(path):
				_log("no scene for %s; the crowd stands without them" % id)
				continue
			n = (load(path) as PackedScene).instantiate() as NPC
			if n == null:
				continue
			n.name = id
			n.visit_host = self
			n.visit_home = _pad_dir
			root.add_child(n)
			n.planet = planet
			_spawned.append(n)
		n.visit_host = self
		n.wander_enabled(false)
		_npcs[id] = n
		_ids.append(id)


## Head disc per crowd member, from the model's own meshes under its "Head" node (every model in the cast
## builds one), in the neighbour's local frame: centre height, radius, vertical extent, lowest point.
func _measure_heads() -> void:
	for id in _ids:
		var n := _npcs[id] as NPC
		var info: Dictionary = HEAD_DEFAULT.duplicate()
		var model := n.get_model() if n != null else null
		if model != null:
			var inv := n.global_transform.affine_inverse()
			var head := model.find_child("Head", true, false)
			var box := _mesh_box(head if head != null else model, inv)
			if box.size != Vector3.ZERO:
				if head == null:
					# no head node: the top 40% of the model
					box = AABB(box.position + Vector3(0.0, box.size.y * 0.6, 0.0), Vector3(box.size.x, box.size.y * 0.4, box.size.z))
				info = {"c_h": box.get_center().y, "r": maxf(box.size.x, maxf(box.size.y, box.size.z)) * 0.5,
					"h": box.size.y, "bottom": box.position.y, "hw": maxf(box.size.x, box.size.z)}
			# The body below the head, for the cover test: every mesh not under the head node.
			var body := _mesh_box(model, inv, head)
			if body.size != Vector3.ZERO:
				info["body_top"] = minf(body.end.y, float(info["bottom"]) + 0.1)
				info["body_w"] = maxf(body.size.x, body.size.z)
			info["parts"] = _mesh_parts(model, inv, head)
		_head_info[id] = info


## Every visible mesh of a model as [local centre, local half extents, under the head node], at rest, in
## the neighbour's own frame - the fine cover test's silhouette (a stalk, an ear or a headphone is its own
## small box instead of widening the head's).
func _mesh_parts(model: Node, inv: Transform3D, head: Node) -> Array:
	var head_parts: Array = []
	var body_parts: Array = []
	for m: Node in model.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		if mi.mesh == null or not mi.visible:
			continue
		var b := (inv * mi.global_transform) * mi.get_aabb()
		if b.size.length() < 0.05:
			continue
		var part := [b.get_center(), b.size * 0.5, head != null and head.is_ancestor_of(mi), b.get_volume()]
		if bool(part[2]):
			head_parts.append(part)
		else:
			body_parts.append(part)
	# The largest boxes carry the silhouette; the rest (buttons, pupils, rivets) sit inside them.
	var by_volume := func(x: Array, y: Array) -> bool: return float(x[3]) > float(y[3])
	head_parts.sort_custom(by_volume)
	body_parts.sort_custom(by_volume)
	return head_parts.slice(0, PARTS_HEAD) + body_parts.slice(0, PARTS_BODY)


func _mesh_box(root: Node, inv: Transform3D, skip: Node = null) -> AABB:
	var box := AABB()
	var first := true
	var meshes: Array[Node] = root.find_children("*", "MeshInstance3D", true, false)
	if root is MeshInstance3D:
		meshes.append(root)
	for m: Node in meshes:
		var mi := m as MeshInstance3D
		if mi.mesh == null or not mi.visible or (skip != null and (skip == mi or skip.is_ancestor_of(mi))):
			continue
		var b := (inv * mi.global_transform) * mi.get_aabb()
		if first:
			box = b
			first = false
		else:
			box = box.merge(b)
	return box


func _ground(d: Vector3) -> String:
	if _vs == null:
		return ""
	var pr := ""
	if _vs.has_method("_ground_problem"):
		pr = str(_vs.call("_ground_problem", d))
	elif _vs.has_method("ground_problem"):
		pr = str(_vs.call("ground_problem", d))
	if pr != "":
		return pr
	var board := _world.get_node_or_null("ReplayBoard/Board") as Node3D
	if board != null and board.is_inside_tree() and planet.surface_distance(d, planet.dir_of(board.global_position)) < BOARD_CLEAR_M:
		return "board"
	return ""


## A surface direction `along` metres from the pad on the axis `ax` (a tangent at the pad), then `lateral`
## metres to the astronaut's right, both along great circles.
func _slot_dir(ax: Vector3, along: float, lateral: float) -> Vector3:
	var rot := _pad_dir.cross(ax)
	if rot.length_squared() < 1e-8:
		return _pad_dir
	rot = rot.normalized()
	var ang := along / _R
	var c := _pad_dir.rotated(rot, ang).normalized()
	var a_c := ax.rotated(rot, ang)
	var l := a_c.cross(c).normalized()
	if absf(lateral) < 1e-4:
		return c
	return c.rotated(c.cross(l).normalized(), lateral / _R).normalized()


func _slot_plan() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in FRONT.size():
		out.append({"id": FRONT[i], "along": FRONT_M, "lat": (float(i) - 2.5) * GAP_M})
	var gaps := _back_gaps()
	for j in BACK.size():
		out.append({"id": BACK[j], "along": BACK_M, "lat": gaps[j] * GAP_M})
	return out


## See FRONT_LATS. For each gap left open, the eye height (at the W camera's nearest distance, 1 m behind
## the mark) at which every back-row head shows CLEAR_SHARE above the line over its taller front
## neighbour's crown; the lowest wins.
func _back_gaps() -> Array[float]:
	if not _back_gaps_cache.is_empty():
		return _back_gaps_cache
	var d := FRONT_M - MARK_M + 1.0
	var k := d / (BACK_M - FRONT_M)
	var best: Array[float] = [-2.0, -1.0, 1.0, 2.0]
	var best_h := INF
	for skip in 5:
		var gaps: Array[float] = []
		for g in 5:
			if g != skip:
				gaps.append(float(g) - 2.0)
		var need := 0.0
		for j in BACK.size():
			var bh: Dictionary = _head_info.get(BACK[j], HEAD_DEFAULT)
			var clear := float(bh["bottom"]) + float(bh["h"]) * CLEAR_SHARE
			var gi := int(gaps[j] + 2.0)
			var crown := 0.0
			for f in [gi, gi + 1]:
				var fh: Dictionary = _head_info.get(FRONT[f], HEAD_DEFAULT)
				crown = maxf(crown, float(fh["bottom"]) + float(fh["h"]))
			need = maxf(need, crown + maxf(0.0, crown - clear) * k)
		if need < best_h - 0.01:
			best_h = need
			best = gaps
	_back_gaps_cache = best
	_stats["back_gaps"] = "%s need_h=%.2f" % [str(best), best_h]
	return best


func _landing_tangent() -> Vector3:
	var side := _pad_dir.cross(Vector3.UP)
	if side.length_squared() < 0.01:
		side = Vector3.RIGHT
	var land := (_pad_dir + side.normalized() * (LANDING_SIDE_M / planet.data.radius)).normalized()
	var t := land - _pad_dir * land.dot(_pad_dir)
	if t.length_squared() < 1e-8:
		t = side
	return t.normalized()


func _layout(k: int, half := false) -> Dictionary:
	var ax := _landing_tangent().rotated(_pad_dir, deg_to_rad(AXIS_STEP_DEG * (float(k) + (0.5 if half else 0.0)))).normalized()
	var dirs := {}
	var problems := 0
	var why := PackedStringArray()
	# A back-row slot starts as far out as the further of the two front slots it stands between has slid:
	# a front neighbour slid into the back row stood in front of it (K2R seed 9200 layout 7: Fen and Zorp slid
	# 0.8 and 0.3 m out, Pip and Pop 0.47-0.50 covered in every W). _slot_plan lists the front row first.
	var front_slide := {}
	for s: Dictionary in _slot_plan():
		var id := str(s["id"])
		if not _npcs.has(id):
			continue
		var base := float(s["along"])
		if BACK.has(id):
			var gl := float(s["lat"]) / GAP_M
			for fi in FRONT.size():
				if absf(FRONT_LATS[fi] - gl) < 0.6:
					base = maxf(base, float(s["along"]) + float(front_slide.get(FRONT[fi], 0.0)))
		var chosen := Vector3.ZERO
		var first_pr := ""
		for slide in SLIDES + 1:
			var d := _slot_dir(ax, base + SLIDE_M * float(slide), float(s["lat"]))
			if FRONT.has(id):
				front_slide[id] = SLIDE_M * float(slide)
			var pr := _ground(d)
			if slide == 0:
				first_pr = pr
			if pr == "":
				chosen = d
				break
		if chosen == Vector3.ZERO:
			problems += 1
			why.append("%s:%s" % [id, first_pr])
			chosen = _slot_dir(ax, float(s["along"]), float(s["lat"]))
			front_slide.erase(id)
		dirs[id] = chosen
	return {"k": k, "half": half, "axis": ax, "dirs": dirs, "problems": problems, "why": ",".join(why)}


func _choose_spots() -> void:
	_vs_rebuild()
	var saved: Dictionary = _fs_dict("spots")
	if _use_saved(saved):
		return
	var order: Array[int] = [0]
	for i in range(1, AXIS_COUNT / 2 + 1):
		order.append(i)
		if i < AXIS_COUNT / 2:
			order.append(-i)
	var layouts: Array[Dictionary] = []
	for k in order:
		layouts.append(_layout(k))
	var ground_ok: Array[Dictionary] = []
	for L in layouts:
		if int(L["problems"]) == 0:
			ground_ok.append(L)
	var chosen: Dictionary = {}
	var pass_name := ""
	var u0 := Time.get_ticks_usec()
	var tried := {}
	for L in ground_ok.slice(0, FRAMED_TRIES):
		_apply_layout(L)
		tried[int(L["k"])] = true
		var w := _solve("W", [], {}, true)
		if bool(w.get("ok", false)):
			chosen = L
			pass_name = "framed"
			break
	if chosen.is_empty():
		# A crowded Commons (K2R, seed 9200 layout 0: one axis of 24 on clear ground, an antenna tree where
		# Bolt's slot was, Bolt slid behind it and hidden in every shot). Before settling for less than
		# "framed", W is solved for every other clear-ground layout whose heads the mark sees, and then for
		# the half-step axes between the 24 (7.5 deg: the crowd ~0.8 m to the side), within FRAMED_BUDGET_MS.
		var extra: Array[Dictionary] = []
		for L in ground_ok:
			if not tried.has(int(L["k"])):
				extra.append(L)
		for k2 in order:
			var L2 := _layout(k2, true)
			if int(L2["problems"]) == 0:
				extra.append(L2)
		# The layouts whose heads the mark sees first (likelier to frame), then the rest.
		var seen: Array[Dictionary] = []
		var unseen: Array[Dictionary] = []
		for L4 in extra:
			_apply_layout(L4)
			if _heads_seen_from_mark():
				seen.append(L4)
			else:
				unseen.append(L4)
		for L3 in seen + unseen:
			if float(Time.get_ticks_usec() - u0) / 1000.0 > FRAMED_BUDGET_MS:
				break
			_apply_layout(L3)
			var w3 := _solve("W", [], {}, true)
			_stats["framed_extra"] = int(_stats.get("framed_extra", 0)) + 1
			if bool(w3.get("ok", false)):
				chosen = L3
				pass_name = "framed-half" if bool(L3["half"]) else "framed"
				break
	if chosen.is_empty():
		for L in ground_ok:
			_apply_layout(L)
			if _heads_seen_from_mark():
				chosen = L
				pass_name = "framed-spot"
				break
	if chosen.is_empty() and not ground_ok.is_empty():
		chosen = ground_ok[0]
		pass_name = "near"
	if chosen.is_empty():
		var best := 999
		for L in layouts:
			if int(L["problems"]) < best:
				best = int(L["problems"])
				chosen = L
		pass_name = "fewest-problems"
		push_warning("FinaleMeeting: no axis round the pad passes the ground rules; standing the crowd on k=%d (%s)" % [int(chosen["k"]), str(chosen["why"])])
	_apply_layout(chosen)
	_spot_pass = pass_name
	_spot_note = "ground_ok=%d/%d why=[%s] extra_w_solves=%d half=%s" % [ground_ok.size(), layouts.size(), str(chosen.get("why", "")), int(_stats.get("framed_extra", 0)), str(chosen.get("half", false))]
	_save_spots()


func _use_saved(saved: Dictionary) -> bool:
	if saved.is_empty() or not saved.has("axis") or not saved.has("spots"):
		return false
	var ax := _vec(saved["axis"])
	var spots: Dictionary = saved["spots"] if saved["spots"] is Dictionary else {}
	if ax == Vector3.ZERO:
		return false
	var dirs := {}
	for id in _ids:
		if not spots.has(id):
			return false
		var d := _vec(spots[id])
		if d == Vector3.ZERO or _ground(d) != "":
			return false
		dirs[id] = d
	_apply_layout({"k": int(saved.get("k", 0)), "axis": ax, "dirs": dirs})
	_spot_pass = "saved"
	_spot_note = ""
	return true


func _apply_layout(L: Dictionary) -> void:
	_axis_k = int(L["k"])
	var ax: Vector3 = L["axis"]
	_axis = (ax - _pad_dir * ax.dot(_pad_dir)).normalized()
	_dirs = (L["dirs"] as Dictionary).duplicate()
	_mark_dir = _slot_dir(_axis, MARK_M, 0.0)
	_mark = planet.surface_point(_mark_dir)
	var acc := Vector3.ZERO
	for id in _dirs:
		acc += planet.surface_point(_dirs[id] as Vector3)
	_crowd_centre = planet.surface_point(planet.dir_of(acc / maxf(1.0, float(_dirs.size()))))
	_back_dirs.clear()
	for id in _dirs:
		var d: Vector3 = _dirs[id]
		var away := _tangent(planet.surface_point(d) - _pad_ground, d, _axis)
		var back := d.rotated(d.cross(away).normalized(), STEP_BACK_M / _R).normalized()
		_back_dirs[id] = back if _ground(back) == "" else d.rotated(d.cross(away).normalized(), STEP_BACK_M * 0.5 / _R).normalized()
	_shots.clear()


func _save_spots() -> void:
	var spots := {}
	for id in _dirs:
		var d: Vector3 = _dirs[id]
		spots[id] = [d.x, d.y, d.z]
	_fs_call("set_spots", [{"axis": [_axis.x, _axis.y, _axis.z], "k": _axis_k, "spots": spots, "pass": _spot_pass}])


func _place_crowd() -> void:
	var look := _mark + planet.up_at(_mark) * 1.0
	for id in _ids:
		var n := _npcs[id] as NPC
		var d: Vector3 = _dirs.get(id, _pad_dir)
		n.visit_home = d
		if bool(n.get("_placed")):
			n.place_on_planet(d, look - planet.surface_point(d), 0.06)
		n.hold_facing(look)
		# Only the ones with a line of their own in free roam can be talked to during the finale.
		if not _roam_lines(id).is_empty():
			continue
		for c: Node in n.get_children():
			if c is Interactable and (c as Interactable).enabled:
				(c as Interactable).enabled = false
				_talk_off.append(c)


func _place_asteroid() -> void:
	if not ResourceLoader.exists(ASTEROID_PATH):
		_log("missing %s; no rock" % ASTEROID_PATH)
		return
	var existing := _world.get_node_or_null("GiantAsteroid") as Node3D
	if existing != null:
		_asteroid = existing
	else:
		var script := load(ASTEROID_PATH) as GDScript
		if script == null:
			return
		_asteroid = script.new() as Node3D
		_asteroid.name = "GiantAsteroid"
		_world.add_child(_asteroid)
	if _asteroid.has_method("place"):
		_asteroid.call("place", _crowd_centre, _axis, planet)
	var box := _mesh_box(_asteroid, _asteroid.global_transform.affine_inverse())
	if box.size != Vector3.ZERO:
		_rock_half_v = box.size.y * 0.5


## FinaleLaunch.opening_frame(self) as it will be after the send beat - the crowd STEP_BACK_M back, the
## astronaut on the mark - worked out inside the load: its sight lines (VisitorSystem.open_sight, ~40 ms
## measured) would otherwise stall a frame of the send beat. Everyone is put back before this returns, so
## no frame ever draws the borrowed poses - the rocket included, which a pad arrival has already lifted to
## the top of its descent by now (FinaleLaunch reads its transform as the parked one).
func _precompute_opening() -> void:
	_opening = []
	if not ResourceLoader.exists(LAUNCH_PATH) or _rocket == null:
		return
	var script := load(LAUNCH_PATH) as Script
	if script == null:
		return
	var saved := {}
	for id in _ids:
		var n := npc(id)
		if n != null and _back_dirs.has(id):
			saved[id] = n.global_transform
			var d: Vector3 = _back_dirs[id]
			n.global_transform = planet.surface_transform(d, _mark - planet.surface_point(d))
	var pxf := _player.global_transform
	_player.global_transform = planet.surface_transform(_mark_dir, _crowd_centre - _mark)
	var rxf := _rocket.global_transform
	_rocket.global_transform = _rocket_rest
	var u0 := Time.get_ticks_usec()
	_opening = script.call("opening_frame", self)
	_stats["opening_ms"] = (Time.get_ticks_usec() - u0) / 1000.0
	_rocket.global_transform = rxf
	_player.global_transform = pxf
	for id: String in saved:
		npc(id).global_transform = saved[id]


func _rock_centre() -> Vector3:
	if _asteroid != null and is_instance_valid(_asteroid):
		return _asteroid.call("centre") as Vector3 if _asteroid.has_method("centre") else _asteroid.global_position
	return _crowd_centre + planet.up_at(_crowd_centre) * 60.0


func _vs_rebuild() -> void:
	# ground_problem rebuilds VisitorSystem's caches (prompts, decorations, landing spot) on this world;
	# `_ground` then reads `_ground_problem` directly so 960 slot tests do not rebuild them 960 times.
	if _vs != null and _vs.has_method("ground_problem"):
		_vs.call("ground_problem", _pad_dir)


# ============================================================================= the beats
func _run() -> void:
	if not is_inside_tree():
		return
	if _stage0 >= 3:
		return  # finale.gd calls play_send_beat() itself.
	if _stage0 == 2:
		# §1 stage 2: the crowd on its saved spots and the Professor's "!" straight away; the shots finish
		# their search in the background for the send beat.
		_beat("choice re-ask (stage 2 load): free roam")
		await _enter_roam()
		return
	_phase = Phase.WAITING
	while _solving and is_inside_tree():
		await get_tree().process_frame
	await _wait_calm(CALM_HOLD)
	if not is_inside_tree() or _phase != Phase.WAITING:
		return
	if _stage0 <= 1:
		await _play_meeting()


func _wait_calm(hold: float) -> void:
	_calm_t = 0.0
	while is_inside_tree():
		if _clock >= START_AFTER_S and _calm():
			_calm_t += minf(get_process_delta_time(), MAX_STEP)
			if _calm_t >= hold:
				return
		else:
			_calm_t = 0.0
		await get_tree().process_frame


func _calm() -> bool:
	if _player == null or not is_instance_valid(_player) or not _player.is_inside_tree() or not _player.visible:
		return false
	if get_tree().paused or EventBus.is_modal_open() or SceneRouter.is_busy():
		return false
	if GameState.flag("rocket_arriving"):
		return false
	if not _player.is_physics_processing() or not _player.input_enabled or not _player.is_on_floor():
		return false
	var it := _pad.find_child("Interactable", true, false) if _pad != null else null
	if it != null and not bool(it.get("enabled")):
		return false
	var runner := DialogueRunner.get_or_create(self)
	return runner == null or not runner.is_active()


func _play_meeting() -> void:
	_phase = Phase.MEETING
	_begin_modal()
	_ensure_camera(true)
	_hold_crowd(_mark_look())
	camera_to("W")
	_beat("meeting begin")
	await _walk_to_mark()
	await _await_camera(CAMERA_WAIT_MAX)
	if not is_inside_tree():
		return
	var runner := DialogueRunner.get_or_create(self)
	var meeting: Array = _lines.get("MEETING") if _lines != null else []
	var first := true
	for turn: Dictionary in meeting:
		if not is_inside_tree():
			return
		if turn.has("action"):
			_beat("action %s" % str(turn["action"]))
			_hold_crowd(_rocket_mid())
			_face_player_toward(_rocket_mid())
			camera_to(TURN_RULE)
			await _wait(TURN_BEAT_S)
			continue
		var speaker := str(turn.get("speaker", ""))
		var n := npc(speaker)
		if turn.has("ask"):
			# §1: stage 2 at the meeting's last box, before the ask.
			_fs_call("set_stage", [2])
			_fs_call("checkpoint", [])
			_beat("stage 2 written; ask")
			var q: Dictionary = turn["ask"]
			camera_to("PA", [speaker])
			var choice := await _guarded_ask(runner, n, str(q.get("prompt", "")), q.get("options", []), ARM_DELAY)
			if not is_inside_tree():
				return
			if choice == 1:
				_send_chosen("meeting")
				return
			camera_to("PA", [speaker])
			await runner.say(n, _moment_lines(PROF))
			runner.finish()
			await _enter_roam()
			return
		var rule := str(turn.get("camera", ""))
		if rule == "":
			rule = "W" if first else "P"
		if rule == "U":
			_hold_crowd(_rock_centre())
		elif not _crowd_faces_rocket():
			_hold_crowd(_mark_look())
		camera_to(rule, [speaker])
		await _w_box_wait(rule, speaker)
		if not is_inside_tree():
			return
		if not runner.is_active():
			runner.begin(n, _player)
		if first:
			_warm_in_first_box()
		first = false
		_beat("say %s rule=%s%s" % [speaker, rule, " (W's framing: %s)" % _rule if _rule.begins_with("W<-") else ""])
		_speaker_move(rule, speaker)
		await runner.say(n, turn.get("lines", []))


func _enter_roam() -> void:
	for id in _ids:
		var n := npc(id) as NPC
		if n != null:
			n.release_facing()
	if _cam != null and is_instance_valid(_cam) and _cam.current:
		await _hand_back_to_rig()
	if not is_inside_tree():
		return
	_end_modal()
	_phase = Phase.ROAM
	_roam_marker = true
	for id in _ids:
		var n := npc(id) as NPC
		if n != null:
			n.call("_refresh_marker")
	_beat("free roam")


func _send_chosen(from: String) -> void:
	if _sent:
		return
	_sent = true
	_roam_marker = false
	_phase = Phase.SENDING
	var prof := npc(PROF) as NPC
	if prof != null:
		prof.call("_refresh_marker")
	_beat("chose_send from=%s guard_eaten=%d guard_passed=%d" % [from, _guard_eaten, _guard_passed])
	# Deferred: from free roam this runs inside Conversation.run, which still has to finish its runner;
	# finale.gd resumes on this signal and calls play_send_beat() straight away.
	chose_send.emit.call_deferred()


## §2 Send, awaited by finale.gd before FinaleLaunch.play(self).
func play_send_beat() -> void:
	if not is_inside_tree() or planet == null:
		return
	_phase = Phase.SENDING
	var runner := DialogueRunner.get_or_create(self)
	if not _modal:
		# From free roam (Conversation.run is closing its box) or a stage-3 load (the landing may still run).
		while is_inside_tree() and runner != null and runner.is_active():
			await get_tree().process_frame
		while _solving and is_inside_tree():
			await get_tree().process_frame
		await _wait_calm(0.2)
		if not is_inside_tree():
			return
		_begin_modal()
	_ensure_camera(true)
	_hold_crowd(_mark_look())
	if _player.global_position.distance_to(_mark) > ARRIVE_M:
		camera_to("W")
		await _walk_to_mark()
	var send: Array = _lines.get("SEND") if _lines != null else []
	var rules := SEND_RULES
	for i in send.size():
		var turn: Dictionary = send[i]
		var speaker := str(turn.get("speaker", ""))
		var n := npc(speaker)
		var rule_s: String = rules[mini(i, rules.size() - 1)]
		camera_to(rule_s, [speaker])
		await _w_box_wait(rule_s, speaker)
		if not is_inside_tree():
			return
		if not runner.is_active():
			runner.begin(n, _player)
		_beat("send say %s%s" % [speaker, " (W's framing: %s)" % _rule if _rule.begins_with("W<-") else ""])
		_speaker_move(rule_s, speaker)
		await runner.say(n, turn.get("lines", []))
		if not is_inside_tree():
			return
	runner.finish()
	_player.input_enabled = false
	# The crowd steps back, the ladder stows, the astronaut waves.
	for id in _ids:
		var n := npc(id) as NPC
		if n != null and _back_dirs.has(id):
			n.release_facing()
			n.stroll_to(_back_dirs[id] as Vector3)
	if _rocket != null and is_instance_valid(_rocket) and _rocket.has_method("set_ladder_deployed"):
		_rocket.call("set_ladder_deployed", false)
	_face_player_toward(_rocket_mid())
	await _wait(0.35)
	_player.play_emote("wave")
	var t := 0.0
	while is_inside_tree() and t < 2.5:
		var strolling := false
		for id in _ids:
			var n := npc(id) as NPC
			strolling = strolling or (n != null and n.is_strolling())
		if not strolling and t >= 1.4:
			break
		t += minf(get_process_delta_time(), MAX_STEP)
		await get_tree().process_frame
	_hold_crowd(_rocket_mid())
	var of: Array = _opening
	if of.size() != 2 and ResourceLoader.exists(LAUNCH_PATH):
		var script := load(LAUNCH_PATH) as Script
		if script != null:
			of = script.call("opening_frame", self)
	if of.size() == 2:
		_rule = "launch-open"
		_set_goal(of[0] as Transform3D, float(of[1]), 0.0)
		await _await_camera(10.0)
	_beat("send beat done opening_frame=%s cam_goal=%s" % [str(of.size() == 2), str(_has_goal)])
	_phase = Phase.SENT
	_hand_modal_to_launch()


## After the story (finale.gd, once the gift has finished): the friends wander a little as ordinary
## visitors, the Commons five go back to being themselves, the clock runs again, the rock is gone.
func release() -> void:
	if _phase == Phase.RELEASED:
		return
	_phase = Phase.RELEASED
	_roam_marker = false
	_guard_on = false
	for id in _ids:
		var n := npc(id) as NPC
		if n == null:
			continue
		n.release_facing()
		if FRIENDS.has(id):
			n.visit_wander_m = RELEASED_WANDER_M
			n.wander_radius_m = RELEASED_WANDER_M
		else:
			n.visit_host = null
			n.visit_home = Vector3.ZERO
			n.home_dir = n.resolve_home_dir()
		n.wander_enabled(true)
		n.call("_refresh_marker")
	for c in _talk_off:
		if is_instance_valid(c):
			(c as Interactable).enabled = true
	_talk_off.clear()
	if _cam != null and is_instance_valid(_cam):
		if _cam.current and _rig != null and _rig.has_method("get_camera"):
			var rc := _rig.call("get_camera") as Camera3D
			if rc != null:
				rc.current = true
		_cam.queue_free()
	_cam = null
	_has_goal = false
	if _asteroid != null and is_instance_valid(_asteroid):
		_asteroid.queue_free()
	_asteroid = null
	_end_modal()
	_restore_clock()
	_beat("release")
	_flush_trace()


# ============================================================================= visit host (npc.gd, conversation.gd)
func wander_ok(dir: Vector3) -> bool:
	return _phase == Phase.RELEASED and _ground(dir) == ""


func wants_marker(npc_id: String) -> int:
	return 1 if _roam_marker and _phase == Phase.ROAM and npc_id == PROF else 0


func handle_conversation(runner: DialogueRunner, n: NPC) -> void:
	var id := n.npc_id
	if _phase == Phase.RELEASED:
		if FRIENDS.has(id) and ResourceLoader.exists(VISITOR_LINES_PATH):
			await runner.say(n, load(VISITOR_LINES_PATH).call("lines", id, "bye"))
		return
	if _phase != Phase.ROAM:
		return
	if id == PROF:
		var q := _final_ask()
		var choice := await _guarded_ask(runner, n, str(q.get("prompt", "")), q.get("options", CHOICE_ARM_OPTIONS), ARM_DELAY)
		if choice == 1:
			_send_chosen("roam")
			return
		await runner.say(n, _moment_lines(PROF))
		return
	var lines := _roam_lines(id)
	if not lines.is_empty():
		await runner.say(n, lines)


func _final_ask() -> Dictionary:
	var meeting: Array = _lines.get("MEETING") if _lines != null else []
	for turn: Dictionary in meeting:
		if turn.has("ask"):
			return turn["ask"]
	return {"prompt": "", "options": CHOICE_ARM_OPTIONS}


func _moment_lines(id: String) -> Array:
	var moment: Array = _lines.get("MOMENT") if _lines != null else []
	for turn: Dictionary in moment:
		if str(turn.get("speaker", "")) == id:
			return turn.get("lines", [])
	return []


## A friend's MOMENT line; Pip and Pop have none in §3, so they keep their meeting line.
func _roam_lines(id: String) -> Array:
	if id == PROF:
		return ["-"]
	var l := _moment_lines(id)
	if not l.is_empty():
		return l
	if id == "pip" or id == "pop":
		var meeting: Array = _lines.get("MEETING") if _lines != null else []
		for turn: Dictionary in meeting:
			if str(turn.get("speaker", "")) == id and turn.has("lines"):
				return turn["lines"]
	return []


# ============================================================================= the choice
## When the pills of the open choice first showed on screen (ticks msec), or -1 while they have not.
func _pills_shown_ms() -> int:
	return _guard_pills_ms


func _dialogue_box() -> Node:
	var box := get_tree().get_first_node_in_group("dialogue_box")
	if box == null:
		box = get_tree().root.get_node_or_null(DialogueRunner.BOX_PATH)
	return box


## THE PILLS WAIT FOR THE CAMERA (§0 Round 3 rulings). DialogueBox shows the pills as soon as the prompt has
## typed, and round 2's critic saw them appear while the camera was still blending from S to PA (6.3 s),
## over four heads. While this node's camera is still moving to its goal, the pills are kept hidden and
## DialogueBox's own arm topped up (so neither a tap, ui_accept nor cancel can answer them unseen); the
## prompt box shows during the blend. The frame the camera has settled, they pop in, and that frame is the
## pills' first frame: the guard's ARM_DELAY and DialogueBox's arm both start from it. Run from
## RenderingServer.frame_pre_draw (after every _process, so a pill shown this frame is hidden before it is
## drawn) and from _process (a headless run draws nothing). PILLS_HOLD_MAX stops a camera that never
## settles from holding them for ever.
func _pills_tick() -> void:
	if not _guard_on or _guard_pills_ms >= 0 or not is_inside_tree():
		return
	var box := _dialogue_box()
	if box == null or not bool(box.get("_choices_shown")):
		return
	var cb := box.get("_choice_box") as Control
	var now := Time.get_ticks_msec()
	# Still moving, or settled on the frame being drawn now: the pills come on a later frame than the
	# camera's settled one, never the same.
	var ours := _cam != null and is_instance_valid(_cam) and _cam.current and not _follow_rig
	var moving := ours and (_has_goal or Engine.get_frames_drawn() <= _settled_frame)
	if moving and cb != null:
		if _pills_hold_ms < 0:
			_pills_hold_ms = now
			_beat("pills held: the camera is still moving (rule=%s)" % _rule)
		if now - _pills_hold_ms < int(PILLS_HOLD_MAX * 1000.0):
			cb.visible = false
			box.set("_arm_remaining", maxf(float(box.get("_arm_remaining")), _guard_arm))
			return
	if _pills_hold_ms >= 0 and cb != null:
		cb.visible = true
		UIStyle.pop_in(cb, 0.25, 0.7)
		box.set("_arm_remaining", _guard_arm)
	_guard_pills_ms = now
	_beat("pills first frame %d camera_settled=%s held_ms=%d rule=%s" % [Engine.get_frames_drawn(), str(not _has_goal), now - _pills_hold_ms if _pills_hold_ms >= 0 else 0, _rule])


func _guarded_ask(runner: DialogueRunner, n: Node3D, prompt: String, options: Array, arm_delay: float) -> int:
	_guard_on = true
	_guard_arm = arm_delay
	_guard_pills_ms = -1
	_pills_hold_ms = -1
	_guard_open_ms = Time.get_ticks_msec()
	_guard_last_ms = _guard_open_ms
	_guard_press_frame = -1
	_guard_eat = false
	_touches_down.clear()
	if not RenderingServer.frame_pre_draw.is_connected(_pills_tick):
		RenderingServer.frame_pre_draw.connect(_pills_tick)
	_beat("ask open")
	var choice: int = await runner.ask(n, prompt, options, arm_delay)
	_guard_on = false
	if RenderingServer.frame_pre_draw.is_connected(_pills_tick):
		RenderingServer.frame_pre_draw.disconnect(_pills_tick)
	_beat("ask answered choice=%d eaten=%d passed=%d ms_since_open=%d ms_since_pills=%d" % [choice, _guard_eaten, _guard_passed,
		Time.get_ticks_msec() - _guard_open_ms, Time.get_ticks_msec() - _guard_pills_ms if _guard_pills_ms >= 0 else -1])
	return 0 if choice < 0 else choice


func _input(event: InputEvent) -> void:
	if not _guard_on:
		return
	var pointer := false
	var pressed := false
	if event is InputEventScreenTouch:
		pointer = true
		pressed = (event as InputEventScreenTouch).pressed
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT and mb.button_index != MOUSE_BUTTON_RIGHT and mb.button_index != MOUSE_BUTTON_MIDDLE:
			return
		pointer = true
		pressed = mb.pressed
	elif event is InputEventMouseMotion and event.device != InputEvent.DEVICE_ID_EMULATION:
		# A mouse motion that did not come from the touch (a desktop cursor under a --ui=mobile window)
		# arriving between a tap's press and its release tells the pressed pill the pointer has left it
		# (BaseButton.pressing_inside), so the release answers nothing: a LOST TAP. While a finger is
		# down on the open choice it is eaten here, before the GUI sees it. A phone has no such events.
		var held := not _touches_down.is_empty() and eat_stray_motion
		if _trace_on:
			_trace_rows.append("guard stray-motion frame=%d device=%d pos=%s touch_down=%s eaten=%s" % [Engine.get_process_frames(), event.device,
				str((event as InputEventMouseMotion).position), str(not _touches_down.is_empty()), str(held)])
		if held:
			get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenTouch:
		var idx := (event as InputEventScreenTouch).index
		if pressed:
			_touches_down[idx] = true
		else:
			_touches_down.erase(idx)
	if not pointer:
		return
	var now := Time.get_ticks_msec()
	if not pressed:
		_guard_last_ms = now
		if _trace_on:
			_trace_rows.append("guard release %s frame=%d device=%d ms_since_pills=%d" % [event.get_class(), Engine.get_process_frames(), event.device, now - _guard_pills_ms if _guard_pills_ms >= 0 else -1])
		return
	var frame := Engine.get_process_frames()
	if frame != _guard_press_frame:
		_guard_press_frame = frame
		# DialogueBox answers on the button's RELEASE, so its own arm lets through a press made inside the
		# arm and let go after it (measured: a touch pressed 0.564 s after the pills' first frame answered).
		# The arm is on the press here: none before the pills show, none for ARM_DELAY after.
		var pills_ms := _pills_shown_ms()
		var armed := pills_ms >= 0 and now - pills_ms >= int(_guard_arm * 1000.0)
		var since_last := now - _guard_last_ms
		_guard_eat = not armed or since_last < QUIET_MS or now - _guard_open_ms < QUIET_MS
		_guard_last_ms = now
		if _guard_eat:
			_guard_eaten += 1
		else:
			_guard_passed += 1
		if _trace_on:
			_trace_rows.append("guard press ms_since_pills=%d ms_since_last=%d eat=%s frame=%d first=%s device=%d" % [now - pills_ms if pills_ms >= 0 else -1, since_last, str(_guard_eat), frame, event.get_class(), event.device])
	elif _trace_on:
		_trace_rows.append("guard press-same-frame %s eat=%s frame=%d device=%d" % [event.get_class(), str(_guard_eat), frame, event.device])
	if _guard_eat:
		get_viewport().set_input_as_handled()


# ============================================================================= the astronaut and the crowd
func _mark_look() -> Vector3:
	return _mark + planet.up_at(_mark) * 1.0


func _rocket_mid() -> Vector3:
	return _rocket_rest.origin + _rocket_rest.basis.y.normalized() * (RocketModel.TOTAL_HEIGHT * 0.5)


var _crowd_look := Vector3.ZERO


func _hold_crowd(point: Vector3) -> void:
	_crowd_look = point
	for id in _ids:
		var n := npc(id) as NPC
		if n != null:
			n.hold_facing(point)


func _crowd_faces_rocket() -> bool:
	return _crowd_look.distance_to(_rocket_mid()) < 0.01


## Turns the astronaut on the spot to face `point` over TURN_S (not awaited by the callers).
func _face_player_toward(point: Vector3) -> void:
	if _player == null or _walking:
		return
	var up := planet.up_at(_player.global_position)
	var p := _player.global_position
	var f0 := _tangent(-_player.global_basis.z, up, _axis)
	var f1 := _tangent(point - p, up, f0)
	var t := 0.0
	while is_inside_tree() and t < TURN_S and not _walking:
		t = minf(TURN_S, t + minf(get_process_delta_time(), MAX_STEP))
		var f := f0.slerp(f1, smoothstep(0.0, 1.0, t / TURN_S)).normalized()
		_player.global_transform = Transform3D(Basis.looking_at(_tangent(f, up, f1), up), _player.global_position)
		await get_tree().process_frame


## Walks the astronaut to the mark along the great circle and turns them to face the crowd, moving the
## body by hand the way part_celebration.gd does its jump (physics off for the walk, input off throughout).
func _walk_to_mark() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	_player.input_enabled = false
	_player.velocity = Vector3.ZERO
	var start := _player.global_position
	var dist := planet.surface_distance(planet.dir_of(start), _mark_dir)
	var face_end := _tangent(_crowd_centre - _mark, planet.up_at(_mark), _axis)
	var model := _player.get_model()
	_beat("walk from %.2f m" % dist)
	if dist > ARRIVE_M:
		_walking = true
		_player.set_physics_process(false)
		_player.set("_speed_factor", WALK_SPEED_FACTOR)
		if model != null:
			model.set_state("walk")
		var from_dir := planet.dir_of(start)
		var travelled := 0.0
		while is_inside_tree() and travelled < dist:
			travelled = minf(dist, travelled + WALK_MPS * minf(get_process_delta_time(), MAX_STEP))
			var d := from_dir.slerp(_mark_dir, travelled / dist).normalized()
			var p := planet.surface_point(d)
			var up := planet.up_at(p)
			var ahead := planet.surface_point(from_dir.slerp(_mark_dir, minf(1.0, (travelled + 0.3) / dist)).normalized())
			var f := _tangent(ahead - p, up, face_end)
			if travelled >= dist:
				f = _tangent(-_player.global_basis.z, up, face_end)
			_player.global_transform = Transform3D(Basis.looking_at(f, up), p + up * 0.02)
			await get_tree().process_frame
		if not is_inside_tree():
			return
		_player.set("_speed_factor", 0.0)
		if model != null:
			model.set_state("idle")
	var t := 0.0
	var up2 := planet.up_at(_mark)
	var f0 := _tangent(-_player.global_basis.z, up2, face_end)
	_walking = true
	_player.set_physics_process(false)
	while is_inside_tree() and t < TURN_S:
		t = minf(TURN_S, t + minf(get_process_delta_time(), MAX_STEP))
		var w := smoothstep(0.0, 1.0, t / TURN_S)
		var f := f0.slerp(face_end, w).normalized()
		_player.global_transform = Transform3D(Basis.looking_at(_tangent(f, up2, face_end), up2), _mark + up2 * 0.02)
		await get_tree().process_frame
	_walking = false
	if is_inside_tree():
		_player.velocity = Vector3.ZERO
		_player.set_physics_process(true)


func _wait(seconds: float) -> void:
	var t := 0.0
	while is_inside_tree() and t < seconds:
		t += minf(get_process_delta_time(), MAX_STEP)
		await get_tree().process_frame


func _begin_modal() -> void:
	if _modal:
		return
	_modal = true
	EventBus.ui_modal_opened.emit(MODAL_NAME)
	if _player != null and is_instance_valid(_player):
		_player.input_enabled = false
		_player.velocity = Vector3.ZERO


func _end_modal() -> void:
	if not _modal:
		return
	_modal = false
	EventBus.ui_modal_closed.emit(MODAL_NAME)


## Keeps this beat's modal open until FinaleLaunch opens its own, so the astronaut never gets a frame of
## control between the two (or for at most 3 s if nothing opens one).
func _hand_modal_to_launch() -> void:
	if not _modal:
		return
	var done := [false]
	var close := func(n: String) -> void:
		if n == MODAL_NAME and not done[0]:
			done[0] = true
			_end_modal.call_deferred()
	EventBus.ui_modal_opened.connect(close, CONNECT_ONE_SHOT)
	await _wait(3.0)
	if not done[0]:
		done[0] = true
		if EventBus.ui_modal_opened.is_connected(close):
			EventBus.ui_modal_opened.disconnect(close)
		_end_modal()


# ============================================================================= the camera: driver
func _ensure_camera(make_current: bool) -> void:
	if _cam == null or not is_instance_valid(_cam):
		var seed_cam := get_viewport().get_camera_3d()
		_cam = Camera3D.new()
		_cam.name = "MeetingCamera"
		_cam.near = CAM_NEAR
		_cam.far = CAM_FAR
		if seed_cam != null:
			_cam.cull_mask = seed_cam.cull_mask
			_cam.fov = seed_cam.fov
		add_child(_cam)
		if seed_cam != null:
			_cam.global_transform = seed_cam.global_transform
		_k = 0.0
	if make_current and not _cam.current:
		var seed_cam2 := get_viewport().get_camera_3d()
		if seed_cam2 != null and seed_cam2 != _cam and not _has_goal:
			_cam.global_transform = seed_cam2.global_transform
			_cam.fov = seed_cam2.fov
		_cam.current = true


func _set_goal(xf: Transform3D, fov: float, seconds: float) -> float:
	_goal = xf.orthonormalized()
	_goal_fov = fov
	_has_goal = true
	_follow_rig = false
	var cur := _cam.global_transform
	var e := _effort(cur, _cam.fov, _goal, _goal_fov)
	_kmax = 1.0
	if seconds > 0.0 and e > 0.0:
		_kmax = clampf(e * 1.3 / seconds, 0.1, 1.0)
	return e * 1.3 / _kmax


## Seconds the move would take at full speed on its slowest axis.
static func _effort(a: Transform3D, fov_a: float, b: Transform3D, fov_b: float) -> float:
	var d := a.origin.distance_to(b.origin)
	var ang := rad_to_deg(a.basis.get_rotation_quaternion().angle_to(b.basis.get_rotation_quaternion()))
	return maxf(d / CAM_VMAX, maxf(ang / CAM_WMAX, absf(fov_a - fov_b) / CAM_FOVMAX))


func _drive(dt: float) -> void:
	if _follow_rig and _rig != null and _rig.has_method("get_camera"):
		var rc := _rig.call("get_camera") as Camera3D
		if rc != null:
			_goal = rc.global_transform.orthonormalized()
			_goal_fov = rc.fov
	var cur := _cam.global_transform
	var e := _effort(cur, _cam.fov, _goal, _goal_fov)
	if e < 1e-4:
		_arrive()
		return
	var k_brake := sqrt(2.0 * CAM_ACC * e)
	_k = minf(minf(_k + CAM_ACC * dt, k_brake), _kmax)
	_k = maxf(_k, 0.0)
	var f := _k * dt / e
	if f >= 1.0:
		_arrive()
		return
	var q := cur.basis.get_rotation_quaternion().slerp(_goal.basis.get_rotation_quaternion(), f)
	_cam.global_transform = Transform3D(Basis(q), cur.origin.lerp(_goal.origin, f))
	_cam.fov = lerpf(_cam.fov, _goal_fov, f)


func _arrive() -> void:
	_cam.global_transform = _goal
	_cam.fov = _goal_fov
	if _follow_rig:
		return
	_has_goal = false
	_k = 0.0
	_settled_frame = Engine.get_frames_drawn()
	if _trace_on:
		_trace_rows.append("beat t=%.3f camera settled rule=%s frame=%d" % [_clock, _rule, _settled_frame])
	camera_arrived.emit()


func _await_camera(max_s: float) -> void:
	var t := 0.0
	while is_inside_tree() and _has_goal and t < max_s:
		t += minf(get_process_delta_time(), MAX_STEP)
		await get_tree().process_frame


func _hand_back_to_rig() -> void:
	if _rig == null or not _rig.has_method("get_camera"):
		_cam.current = false
		return
	if _rig.has_method("reseat_behind_player"):
		_rig.call("reseat_behind_player")
	_follow_rig = true
	_has_goal = true
	_rule = "rig"
	var t := 0.0
	var e := INF
	var next_log := 0.5
	while is_inside_tree() and t < HANDBACK_MAX:
		var rc := _rig.call("get_camera") as Camera3D
		if rc != null:
			e = _effort(_cam.global_transform, _cam.fov, rc.global_transform, rc.fov)
			if e < 0.02:
				break
			if t >= next_log:
				next_log += 0.5
				_beat("hand-back t=%.1f effort=%.3f dist=%.3f fov %.1f/%.1f k=%.2f" % [t, e, _cam.global_position.distance_to(rc.global_position), _cam.fov, rc.fov, _k])
		t += minf(get_process_delta_time(), MAX_STEP)
		await get_tree().process_frame
	_follow_rig = false
	_has_goal = false
	_k = 0.0
	var rc2 := _rig.call("get_camera") as Camera3D
	if rc2 != null and is_instance_valid(rc2):
		rc2.current = true
	_beat("camera handed to the rig after %.2f s" % t)


func _process(delta: float) -> void:
	var dt := minf(delta, MAX_STEP)
	_clock += dt
	if _guard_on:
		_pills_tick()
	# The camera's own step: a hitch may take at most twice the usual frame (§2 "no step above 2x the
	# median"), so a stalled frame slows the move instead of jumping it.
	var cam_dt := minf(dt, 2.0 * _dt_typical) if _dt_typical > 0.0 else dt
	_dt_typical = dt if _dt_typical <= 0.0 else lerpf(_dt_typical, minf(dt, 2.0 * _dt_typical), 0.05)
	if _cam != null and is_instance_valid(_cam) and _has_goal:
		_drive(cam_dt)
	if _trace_on and _cam != null and is_instance_valid(_cam) and _cam.current:
		_frame += 1
		var q := _cam.global_basis.get_rotation_quaternion()
		var p := _cam.global_position
		_trace_rows.append("cam %d %.5f %.5f %.5f %.5f %.7f %.7f %.7f %.7f %.4f %s" % [_frame, _clock, p.x, p.y, p.z, q.x, q.y, q.z, q.w, _cam.fov, _rule])
		if _trace_rows.size() >= 60:
			_flush_trace()


# ============================================================================= the camera: shots
func _viewport_aspect() -> float:
	var s := get_viewport().get_visible_rect().size
	return s.x / maxf(1.0, s.y)


func _shot_for(rule: String, ids: Array) -> Dictionary:
	var a := _viewport_aspect()
	if absf(a - _asp) > 0.01:
		_asp = a
		_shots.clear()
	var key := rule
	if rule == "P" or rule == "PA":
		key = "%s:%s" % [rule, str(ids[0]) if not ids.is_empty() else PROF]
	if _shots.has(key):
		return _shots[key]
	if rule == "P" and not ids.is_empty() and BACK.has(str(ids[0])):
		var wb := _w_for_p(str(ids[0]), "back row", {})
		if not wb.is_empty():
			_shots[key] = wb
			return wb
	var shot := _solve(rule, ids, {}, false)
	if rule == "P" and not bool(shot.get("ok", false)):
		var wf := _w_for_p(str(ids[0]) if not ids.is_empty() else PROF, "no P framing", shot)
		if not wf.is_empty():
			shot = wf
	_shots[key] = shot
	return shot


## W's framing standing in for `id`'s P (§0 Round 4 rulings): a back-row speaker, or a front-row one whose
## P found no framing (`failed` is that search's result). Empty when W itself is not solved yet.
func _w_for_p(id: String, reason: String, failed: Dictionary) -> Dictionary:
	var w: Dictionary = _shots.get("W", {})
	if w.is_empty() and not _solving and planet != null:
		# `_shot_for` cleared the cache (the viewport's aspect changed): W first, so a back-row P is still W.
		w = _shot_for("W", [])
	if w.is_empty():
		return {}
	var fb := w.duplicate()
	fb["w_for_p"] = id
	fb["fallback_from"] = "P:%s(%s%s)" % [id, reason, "" if failed.is_empty() else ": " + str(failed.get("why", ""))]
	if reason != "back row":
		_stats["p_fallbacks"] = int(_stats.get("p_fallbacks", 0)) + 1
	_beat("P:%s uses W: %s%s" % [id, reason, "" if failed.is_empty() else " (best failed: %s)" % str(failed.get("why", ""))])
	return fb


## Pre-solves every shot the meeting and the send beat use, in script order (each one's travel scored from
## the one before), with real sight lines. Runs in _ready, inside the load.
func _solve_all() -> void:
	_solving = true
	_shots.clear()
	var u0 := Time.get_ticks_usec()
	var prev: Dictionary = {}
	for s: Array in SHOT_SEQUENCE:
		var rule := str(s[0])
		var id := str(s[1])
		var key := rule if id == "" else "%s:%s" % [rule, id]
		if _shots.has(key):
			prev = _shots[key]
			continue
		if rule == "P" and BACK.has(id):
			# Back-row speakers get no close-up (§0 Round 4 rulings): W's framing, no search.
			_shots[key] = _w_for_p(id, "back row", {})
			prev = _shots[key]
			continue
		var shot: Dictionary = await _solve_async(rule, [id] if id != "" else [], prev, true)
		if not is_inside_tree():
			return
		if rule == "P" and not bool(shot.get("ok", false)):
			shot = _w_for_p(id, "no P framing", shot)
		_shots[key] = shot
		prev = shot
	for id in _ids:
		var key2 := "P:%s" % id
		if not _shots.has(key2):
			if BACK.has(id):
				_shots[key2] = _w_for_p(id, "back row", {})
				continue
			var sh2: Dictionary = await _solve_async("P", [id], {}, true)
			if not is_inside_tree():
				return
			_shots[key2] = sh2 if bool(sh2.get("ok", false)) else _w_for_p(id, "no P framing", sh2)
	# A crowd shot whose best framing still leaves a head more than MAX_COVER covered falls back to W's framing
	# when W covers less: every head in view matters more than the rule's own composition. The two wide crowd
	# rules (S, R) fall back to a W that passes whatever they failed (a steep look, a prop at the lens).
	# S's fallback is W's framing solved with the crowd as S holds it, turned to the rocket ("WS"): seed 9200
	# layout 7's W left Fen 0.03 covered facing the astronaut and 0.24 turned to the rocket (K2R).
	var s_shot: Dictionary = _shots.get("S", {})
	var ws: Dictionary = {}
	if not s_shot.is_empty() and not bool(s_shot.get("ok", false)):
		ws = await _solve_async("WS", [], _shots.get("P:zorp", {}), true)
		if not is_inside_tree():
			return
	# P already fell back above (back row, or no P framing: §0 Round 4 rulings); PA never falls back - W's
	# framing puts heads under the pills.
	var w: Dictionary = _shots.get("W", {})
	if not w.is_empty():
		for key4: String in _shots.keys():
			var sh4: Dictionary = _shots[key4]
			if key4 == "W" or sh4.is_empty() or bool(sh4.get("ok", false)) or key4.begins_with("P:") or key4.begins_with("PA:"):
				continue
			# S: no candidate passed the split and the cover gate, so it is W, whatever W's own verdict.
			var wide_fb := key4 == "S" or (key4 == "R" and bool(w.get("ok", false)))
			if wide_fb or float(sh4.get("worst_cov", 1.0)) > MAX_COVER and float(w.get("worst_cov", 1.0)) < float(sh4.get("worst_cov", 1.0)):
				var fb := (ws if key4 == "S" and not ws.is_empty() else w).duplicate()
				fb["fallback_from"] = "%s(%s)" % [key4, str(sh4.get("why", ""))]
				_shots[key4] = fb
				if key4 == "S":
					_stats["s_fallback"] = str(sh4.get("why", ""))
					_beat("S falls back to W: no candidate passed the split and the cover gate (best failed: %s); W's framing with the crowd turned to the rocket: %s" % [str(sh4.get("why", "")), "ok" if bool(fb.get("ok", false)) else "FAIL(" + str(fb.get("why", "")) + ")"])
	_close_sight()
	_solving = false
	var summary := PackedStringArray()
	for key3: String in _shots:
		var sh: Dictionary = _shots[key3]
		summary.append("%s=%s%s%s[%.0fms/%d]" % [key3, ("W" if sh.has("w_for_p") else "") + ("ok" if bool(sh.get("ok", false)) else "FAIL"), "" if bool(sh.get("ok", false)) else "(" + str(sh.get("why", "")) + ")",
			" <-W for " + str(sh["fallback_from"]) if sh.has("fallback_from") else "", float(sh.get("work_ms", 0.0)), int(sh.get("n_cands", 0))])
	_stats["solve_ms"] = (Time.get_ticks_usec() - u0) / 1000.0
	_beat("shots solved in %.0f ms over frames (longest slice %.1f ms, costliest sight-line candidate %.1f ms; P->W fallbacks %d; sight space reopened %d): %s" % [
		_stats["solve_ms"], float(_stats.get("slice_max_ms", 0.0)), float(_stats.get("ray_cost_ms", 0.0)), int(_stats.get("p_fallbacks", 0)), int(_stats.get("sight_reopened", 0)), " ".join(summary)])


## Head and body discs for the crowd standing on `dirs_map` (id -> surface direction).
func _heads(dirs_map: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id in _ids:
		if not dirs_map.has(id):
			continue
		var feet := planet.surface_point(dirs_map[id] as Vector3)
		var up := planet.up_at(feet)
		var hi: Dictionary = _head_info.get(id, HEAD_DEFAULT)
		var bottom := float(hi["bottom"])
		var h := float(hi["h"])
		out.append({"id": id, "feet": feet, "up": up, "c": feet + up * float(hi["c_h"]), "r": float(hi["r"]), "h": h,
			"hw": float(hi.get("hw", 0.7)), "hy0": bottom, "hy1": bottom + h,
			"bw": float(hi.get("body_w", 0.6)), "by1": float(hi.get("body_top", bottom)), "front": FRONT.has(id),
			"parts": hi.get("parts", []), "face": _tangent(_mark - feet, up, -_axis)})
	return out


func _solve(rule: String, ids: Array, prev: Dictionary, rays: bool) -> Dictionary:
	var job := _solve_job(rule, ids, prev, rays)
	while not _solve_step(job, INF):
		pass
	return job["result"]


## The same search spread over frames: at most SLICE_USEC of it per frame.
func _solve_async(rule: String, ids: Array, prev: Dictionary, rays: bool) -> Dictionary:
	var job := _solve_job(rule, ids, prev, rays)
	while true:
		var u0 := Time.get_ticks_usec()
		var done := _solve_step(job, SLICE_USEC)
		_stats["slice_max_ms"] = maxf(float(_stats.get("slice_max_ms", 0.0)), (Time.get_ticks_usec() - u0) / 1000.0)
		job["work_ms"] = float(job.get("work_ms", 0.0)) + (Time.get_ticks_usec() - u0) / 1000.0
		if done:
			break
		await get_tree().process_frame
		if not is_inside_tree():
			return {}
	(job["result"] as Dictionary)["work_ms"] = float(job.get("work_ms", 0.0))
	(job["result"] as Dictionary)["n_cands"] = (job.get("cands", []) as Array).size()
	return job["result"]


func _solve_job(rule: String, ids: Array, prev: Dictionary, rays: bool) -> Dictionary:
	return {"rule": rule, "speaker": str(ids[0]) if not ids.is_empty() else PROF, "prev": prev, "rays": rays,
		"phase": 0, "i": 0, "scored": [], "result": {}}


## One slice of a shot search; true when it is finished (`job.result`). Phases: 0 candidates, 1 the cheap
## gates and the analytic cover test for each, 2 real sight lines for the best few, in order.
func _solve_step(job: Dictionary, budget_usec: float) -> bool:
	var t0 := Time.get_ticks_usec()
	var rule := str(job["rule"])
	var speaker := str(job["speaker"])
	if int(job["phase"]) == 0:
		if not job.has("heads"):
			job["heads"] = _heads(_back_dirs if rule == "R2" else _dirs)
			if (job["heads"] as Array).is_empty():
				return true
		if rule == "P" or rule == "PA":
			# The close-up grid is large: generated over slices (`_p_candidates_step`).
			if not _p_candidates_step(job, t0, budget_usec):
				return false
		else:
			job["cands"] = _candidates(rule, job["heads"], speaker)
		job["phase"] = 1
		if float(Time.get_ticks_usec() - t0) > budget_usec:
			return false
	var heads: Array[Dictionary] = job["heads"]
	var cands: Array[Dictionary] = job["cands"]
	var scored: Array = job["scored"]
	var prev: Dictionary = job["prev"]
	if int(job["phase"]) == 1:
		while int(job["i"]) < cands.size():
			var c: Dictionary = cands[int(job["i"])]
			job["i"] = int(job["i"]) + 1
			var cheap := _cheap(rule, c, heads, speaker)
			if cheap > 0:
				c["fails"] = CHEAP_FAILS + cheap
				c["cheap"] = cheap
				c["why"] = "cheap"
				c["score"] = 0.0
				scored.append(c)
			else:
				var ev := _eval(c["eye"], c["basis"], float(c["fov"]), heads, _mark, false)
				var g := _gates(rule, c, ev, heads, speaker)
				var motion := 0.0
				if not prev.is_empty():
					motion = (c["eye"] as Vector3).distance_to(prev["eye"] as Vector3) * 0.05 + \
						rad_to_deg((c["basis"] as Basis).get_rotation_quaternion().angle_to((prev["basis"] as Basis).get_rotation_quaternion())) * 0.008
				c["fails"] = int(g["fails"])
				c["why"] = str(g["why"])
				c["worst_cov"] = float(g["worst_cov"])
				c["score"] = float(g["score"]) + motion + float(c.get("extra", 0.0))
				scored.append(c)
			if float(Time.get_ticks_usec() - t0) > budget_usec:
				return false
		if scored.is_empty():
			return true
		scored.sort_custom(func(x: Dictionary, y: Dictionary) -> bool:
			if int(x["fails"]) != int(y["fails"]):
				return int(x["fails"]) < int(y["fails"])
			return float(x["score"]) < float(y["score"]))
		job["phase"] = 2
		job["i"] = 0
		job["best"] = scored[0]
		job["best_r"] = {}
	if int(job["phase"]) == 2:
		if bool(job["rays"]) and _sight_open:
			var checked_here := 0
			while int(job["i"]) < mini(RAY_TRIES, scored.size()):
				# Stop before a candidate whose sight lines would not fit what is left of this frame's budget -
				# but never before the first one of a slice: a candidate costing more than the whole budget
				# (K2R, seed 9200 layout 7, a crowded Commons) made every slice return at once, the search never
				# finished and the meeting never started.
				var spent := float(Time.get_ticks_usec() - t0)
				if checked_here > 0 and spent + float(job.get("ray_cost", 0.0)) > budget_usec:
					return false
				checked_here += 1
				var c2: Dictionary = scored[int(job["i"])]
				job["i"] = int(job["i"]) + 1
				# The scan order puts every cheap-gate failure last: once a candidate has been checked, nothing
				# from here on can beat it. When none passed them, the least bad is still checked, and keeps
				# its cheap failures (so it never reads as passing).
				var cheap_add := CHEAP_FAILS + int(c2.get("cheap", 0)) if int(c2.get("cheap", 0)) > 0 else 0
				if cheap_add > 0 and not (job["best_r"] as Dictionary).is_empty():
					break
				var r0 := Time.get_ticks_usec()
				# The fine cover test first; sight lines (the costly part) only for a candidate it passes.
				var ev2 := _eval(c2["eye"], c2["basis"], float(c2["fov"]), heads, _mark, false)
				_fine_cover(c2["eye"], c2["basis"], float(c2["fov"]), heads, _mark, ev2, _facing_for(rule))
				var g2 := _gates(rule, c2, ev2, heads, speaker)
				c2["fails"] = int(g2["fails"]) + cheap_add
				c2["why"] = str(g2["why"])
				c2["worst_cov"] = float(g2["worst_cov"])
				var br: Dictionary = job["best_r"]
				# Sight lines and the lens test only add failures, so a candidate already failing more gates
				# than the best checked one can never win: skip it. EVERY candidate that can become the
				# result is checked on real triangles - round 1 checked only candidates that passed the
				# analytic test, so when none did, the fallback chosen had never been checked, and a
				# decoration pole covered 85-90% of Grig's head (layout 0, seed 7000, K2 critic 1).
				if br.is_empty() or int(c2["fails"]) <= int(br["fails"]):
					ev2 = _eval(c2["eye"], c2["basis"], float(c2["fov"]), heads, _mark, true)
					_fine_cover(c2["eye"], c2["basis"], float(c2["fov"]), heads, _mark, ev2, _facing_for(rule))
					g2 = _gates(rule, c2, ev2, heads, speaker)
					c2["fails"] = int(g2["fails"]) + cheap_add
					c2["why"] = str(g2["why"])
					c2["worst_cov"] = float(g2["worst_cov"])
					var fg := _foreground(c2, heads, rule, speaker)
					if fg != "":
						c2["fails"] = int(c2["fails"]) + 1
						c2["why"] = str(c2["why"]) + ",fg:" + fg
					c2["checked"] = true
					job["ray_cost"] = maxf(float(job.get("ray_cost", 0.0)), float(Time.get_ticks_usec() - r0))
					_stats["ray_cost_ms"] = maxf(float(_stats.get("ray_cost_ms", 0.0)), float(Time.get_ticks_usec() - r0) / 1000.0)
				# Fewest gates failed; between equals, the one leaving the least of any head covered (a passing
				# one only when it covers clearly less: the scan order already ranks composition and travel).
				if bool(c2.get("checked", false)) and (br.is_empty() or int(c2["fails"]) < int(br["fails"]) or (int(c2["fails"]) == int(br["fails"]) \
						and float(c2.get("worst_cov", 1.0)) < float(br.get("worst_cov", 1.0)) - (0.02 if int(br["fails"]) > 0 else PASS_COVER_GAIN))):
					job["best_r"] = c2
				if int(c2["fails"]) == 0:
					job["n_ok"] = int(job.get("n_ok", 0)) + 1
					# A passing frame near the cover gate keeps looking, a few candidates more, for a clearer one:
					# the fine test's estimate ran up to 0.10 under the rendered cover on 5 of 985 heads (K2 round 2).
					if float((job["best_r"] as Dictionary).get("worst_cov", 1.0)) <= MAX_COVER - PASS_COVER_GAIN or int(job["n_ok"]) >= OK_TRIES:
						break
				if float(Time.get_ticks_usec() - t0) > budget_usec:
					return false
			if not (job["best_r"] as Dictionary).is_empty():
				job["best"] = job["best_r"]
		var best: Dictionary = job["best"]
		best["ok"] = int(best["fails"]) == 0
		best["rule"] = rule
		var top := PackedStringArray()
		for k in mini(4, scored.size()):
			var c3: Dictionary = scored[k]
			top.append("[f%d s%.2f fov%.0f %s]" % [int(c3["fails"]), float(c3["score"]), float(c3["fov"]), str(c3["why"])])
		best["top"] = " ".join(top)
		best["n"] = scored.size()
		job["result"] = best
	return true


## Per head: projected centre (X in frame-height units from the left, Y from the top), disc radius, share
## of the frame height, whether it is whole in frame, and the share of it covered (other heads, bodies,
## the astronaut; with `rays`, VisitorSystem's sight lines on real triangles for everything else).
func _eval(eye: Vector3, b: Basis, fov: float, heads: Array[Dictionary], astro: Vector3, rays: bool) -> Array[Dictionary]:
	var tv := tan(deg_to_rad(fov) * 0.5)
	var occ: Array = []
	var head_rects: Array = []
	for i in heads.size():
		var hd: Dictionary = heads[i]
		var hr := _prism_rect(eye, b, tv, hd["feet"], hd["up"], float(hd["hw"]), float(hd["hy0"]), float(hd["hy1"]))
		head_rects.append(hr)
		if not hr.is_empty():
			hr.append(i)
			occ.append(hr)
		var br := _prism_rect(eye, b, tv, hd["feet"], hd["up"], float(hd["bw"]), 0.0, float(hd["by1"]))
		if not br.is_empty():
			br.append(i)
			occ.append(br)
	var ar := _prism_rect(eye, b, tv, astro, planet.up_at(astro), ASTRO_W, 0.0, ASTRO_H)
	if not ar.is_empty():
		ar.append(-1)
		occ.append(ar)
	var out: Array[Dictionary] = []
	for i in heads.size():
		var hd: Dictionary = heads[i]
		var ph := _proj(eye, b, tv, hd["c"])
		var hr: Array = head_rects[i]
		if ph.z <= 0.05 or hr.is_empty():
			out.append({"in": false, "touch": false, "full": false, "z": ph.z, "X": -9.0, "Y": -9.0, "rho": 0.0, "share": 0.0, "cov": 0.0})
			continue
		var rho := maxf(float(hr[2]) - float(hr[0]), float(hr[3]) - float(hr[1])) * 0.5 / SILHOUETTE
		var share := float(hd["h"]) / (2.0 * ph.z * tv)
		var centre_in := ph.x >= 0.0 and ph.x <= _asp and ph.y >= 0.0 and ph.y <= 1.0
		var full := float(hr[0]) >= 0.0 and float(hr[2]) <= _asp and float(hr[1]) >= 0.0 and float(hr[3]) <= 1.0
		var touch := float(hr[2]) > 0.0 and float(hr[0]) < _asp and float(hr[3]) > 0.0 and float(hr[1]) < 1.0
		var area := (float(hr[2]) - float(hr[0])) * (float(hr[3]) - float(hr[1]))
		var cov := 0.0
		for o: Array in occ:
			if int(o[5]) == i or float(o[4]) >= float(hr[4]) - 0.05:
				continue
			var ox := minf(float(hr[2]), float(o[2])) - maxf(float(hr[0]), float(o[0]))
			var oy := minf(float(hr[3]), float(o[3])) - maxf(float(hr[1]), float(o[1]))
			if ox > 0.0 and oy > 0.0:
				cov += ox * oy / maxf(area, 1e-6)
		if rays and centre_in:
			var c: Vector3 = hd["c"]
			var rr := float(hd["r"]) * 0.6
			var n := 0
			var by := ""
			# The centre and six points round the disc (a thin pole between three points went unseen).
			for k in HEAD_RAYS:
				var p := c
				if k > 0:
					var a := TAU * float(k - 1) / float(HEAD_RAYS - 1) + 0.3
					p = c + (b.x * cos(a) + b.y * sin(a)) * rr
				var hit := _sight(eye, p)
				if hit != "" and not hit.begins_with("astronaut"):
					n += 1
					by = hit
			var rc := float(n) / float(HEAD_RAYS)
			cov += rc
			out.append({"in": centre_in, "touch": touch, "full": full, "z": ph.z, "X": ph.x, "Y": ph.y, "rho": rho, "share": share, "cov": minf(cov, 1.0), "ray_cov": rc, "ray_by": by.get_file()})
			continue
		out.append({"in": centre_in, "touch": touch, "full": full, "z": ph.z, "X": ph.x, "Y": ph.y, "rho": rho, "share": share, "cov": minf(cov, 1.0)})
	return out


## The fine cover test, run on the few candidates that also get sight lines: every mesh box of every
## neighbour projected to a rectangle (SILHOUETTE of its box), and each head's own boxes sampled on an
## FINE_GRID square grid: the share of its samples behind a nearer neighbour's box or the astronaut replaces
## the prism estimate in `ev`, the sight-line share on top. `look_at`: where the crowd faces (`_facing_for`).
## Where the crowd looks during a rule's shot (the meeting holds their facing): the rocket for S and R,
## the rock for U, the astronaut's mark otherwise.
func _facing_for(rule: String) -> Vector3:
	match rule:
		"S", "R", "R2", "WS":
			return _rocket_rest.origin
		"U":
			return _rock_centre()
	return _mark


func _fine_cover(eye: Vector3, b: Basis, fov: float, heads: Array[Dictionary], astro: Vector3, ev: Array[Dictionary], look_at: Vector3) -> void:
	if fine_model == "rect":
		_fine_cover_rect(eye, b, fov, heads, astro, ev, look_at)
		return
	var tv := tan(deg_to_rad(fov) * 0.5)
	var parts: Array = []   # [x0, y0, x1, y1, depth, owner, is_head, centre, basis, half]
	for i in heads.size():
		var hd: Dictionary = heads[i]
		var up: Vector3 = hd["up"]
		var face := _tangent(look_at - (hd["feet"] as Vector3), up, hd["face"] as Vector3)
		var basis := Basis.looking_at(face, up)
		for part: Array in hd["parts"]:
			var pc: Vector3 = (hd["feet"] as Vector3) + basis * (part[0] as Vector3)
			var r := _box_rect(eye, b, tv, pc, basis, part[1] as Vector3)
			if not r.is_empty():
				parts.append(_unshrunk(r) + [i, bool(part[2]), pc, basis, part[1]])
	var au := planet.up_at(astro)
	var ab := Basis.looking_at(_tangent(eye - astro, au, -_axis), au)
	var ahalf := Vector3(ASTRO_W, ASTRO_H, ASTRO_W) * 0.5
	var ar := _box_rect(eye, b, tv, astro + au * ahalf.y, ab, ahalf)
	if not ar.is_empty():
		parts.append(_unshrunk(ar) + [-1, false, astro + au * ahalf.y, ab, ahalf])
	for i in heads.size():
		var e: Dictionary = ev[i]
		if not bool(e["in"]):
			continue
		# The head as the rendered measure defines it: this neighbour's own pixels inside the disc of its
		# head radius round its head centre (showcase/finale_k2_probe.gd `_cover`), so a hat brim or a big
		# ear outside that disc neither counts nor gets covered.
		var hd2: Dictionary = heads[i]
		var pc2 := _proj(eye, b, tv, hd2["c"])
		if pc2.z <= 0.05:
			continue
		var rad := float(hd2["r"]) / (2.0 * pc2.z * tv)
		var bx0 := pc2.x - rad
		var by0 := pc2.y - rad
		var bx1 := pc2.x + rad
		var by1 := pc2.y + rad
		var mine: Array = []
		for r: Array in parts:
			if int(r[5]) == i and float(r[2]) > bx0 and float(r[0]) < bx1 and float(r[3]) > by0 and float(r[1]) < by1:
				mine.append(r)
		if mine.is_empty():
			continue
		var near: Array = []
		for o: Array in parts:
			if int(o[5]) != i and float(o[2]) > bx0 and float(o[0]) < bx1 and float(o[3]) > by0 and float(o[1]) < by1:
				near.append(o)
		var total := 0
		var hidden := 0
		# When one of the head's sight lines met a prop, every sample's own line is tested on real triangles
		# too (the head's HEAD_RAYS share is only a 1/7 step).
		var props := float(e.get("ray_cov", 0.0)) > 0.0 and _sight_open
		for gy in FINE_GRID:
			for gx in FINE_GRID:
				var px := bx0 + (bx1 - bx0) * (float(gx) + 0.5) / float(FINE_GRID)
				var py := by0 + (by1 - by0) * (float(gy) + 0.5) / float(FINE_GRID)
				if Vector2(px - pc2.x, py - pc2.y).length() > rad:
					continue
				var dir := -b.z + b.x * ((2.0 * px / _asp - 1.0) * tv * _asp) + b.y * ((1.0 - 2.0 * py) * tv)
				var own_t := INF
				for r: Array in mine:
					if px >= float(r[0]) and px <= float(r[2]) and py >= float(r[1]) and py <= float(r[3]):
						own_t = minf(own_t, _ray_box(eye, dir, r[7], r[8], r[9]))
				if own_t == INF:
					continue
				total += 1
				var covered := false
				for o: Array in near:
					if px >= float(o[0]) and px <= float(o[2]) and py >= float(o[1]) and py <= float(o[3]) \
							and _ray_box(eye, dir, o[7], o[8], o[9]) < own_t:
						covered = true
						break
				if not covered and props:
					var ph := _sight(eye, eye + dir * own_t)
					covered = ph != "" and not ph.begins_with("astronaut")
				if covered:
					hidden += 1
		if total == 0:
			continue
		e["cov_prism"] = e["cov"]
		e["cov"] = minf(1.0, float(hidden) / float(total) + (0.0 if props else float(e.get("ray_cov", 0.0))))


## A shrunk silhouette rectangle ([x0, y0, x1, y1, depth] from `_box_rect`) back at the box's full extent.
static func _unshrunk(r: Array) -> Array:
	var cx := (float(r[0]) + float(r[2])) * 0.5
	var cy := (float(r[1]) + float(r[3])) * 0.5
	var hx := (float(r[2]) - float(r[0])) * 0.5 / SILHOUETTE
	var hy := (float(r[3]) - float(r[1])) * 0.5 / SILHOUETTE
	return [cx - hx, cy - hy, cx + hx, cy + hy, r[4]]


## Where the ray `eye + t * dir` enters the oriented box (centre, orthonormal basis, half extents), in
## units of `dir`; INF when it misses or the box is behind.
static func _ray_box(eye: Vector3, dir: Vector3, centre: Vector3, basis: Basis, half: Vector3) -> float:
	var o := eye - centre
	var tmin := -INF
	var tmax := INF
	for a in 3:
		var ax := basis[a]
		var oo := o.dot(ax)
		var dd := dir.dot(ax)
		var h := half[a]
		if absf(dd) < 1e-9:
			if absf(oo) > h:
				return INF
			continue
		var t1 := (-h - oo) / dd
		var t2 := (h - oo) / dd
		tmin = maxf(tmin, minf(t1, t2))
		tmax = minf(tmax, maxf(t1, t2))
		if tmin > tmax:
			return INF
	if tmax < 0.0:
		return INF
	return maxf(tmin, 0.0)


func _fine_cover_rect(eye: Vector3, b: Basis, fov: float, heads: Array[Dictionary], astro: Vector3, ev: Array[Dictionary], look_at: Vector3) -> void:
	var tv := tan(deg_to_rad(fov) * 0.5)
	var rects: Array = []   # [x0, y0, x1, y1, depth, owner, is_head]
	for i in heads.size():
		var hd: Dictionary = heads[i]
		var up: Vector3 = hd["up"]
		var face := _tangent(look_at - (hd["feet"] as Vector3), up, hd["face"] as Vector3)
		var basis := Basis.looking_at(face, up)
		for part: Array in hd["parts"]:
			var r := _box_rect(eye, b, tv, (hd["feet"] as Vector3) + basis * (part[0] as Vector3), basis, part[1] as Vector3)
			if not r.is_empty():
				r.append(i)
				r.append(bool(part[2]))
				rects.append(r)
	var ar := _prism_rect(eye, b, tv, astro, planet.up_at(astro), ASTRO_W, 0.0, ASTRO_H)
	if not ar.is_empty():
		ar.append(-1)
		ar.append(false)
		rects.append(ar)
	for i in heads.size():
		var e: Dictionary = ev[i]
		if not bool(e["in"]):
			continue
		var mine: Array = []
		var bx0 := INF
		var by0 := INF
		var bx1 := -INF
		var by1 := -INF
		for r: Array in rects:
			if int(r[5]) == i and bool(r[6]):
				mine.append(r)
				bx0 = minf(bx0, float(r[0]))
				by0 = minf(by0, float(r[1]))
				bx1 = maxf(bx1, float(r[2]))
				by1 = maxf(by1, float(r[3]))
		if mine.is_empty():
			continue
		var near: Array = []
		var far_depth := 0.0
		for r: Array in mine:
			far_depth = maxf(far_depth, float(r[4]))
		for o: Array in rects:
			if int(o[5]) != i and float(o[4]) < far_depth and float(o[2]) > bx0 and float(o[0]) < bx1 and float(o[3]) > by0 and float(o[1]) < by1:
				near.append(o)
		var total := 0
		var hidden := 0
		for gy in FINE_GRID:
			for gx in FINE_GRID:
				var px := bx0 + (bx1 - bx0) * (float(gx) + 0.5) / float(FINE_GRID)
				var py := by0 + (by1 - by0) * (float(gy) + 0.5) / float(FINE_GRID)
				var depth := INF
				for r: Array in mine:
					if px >= float(r[0]) and px <= float(r[2]) and py >= float(r[1]) and py <= float(r[3]):
						depth = minf(depth, float(r[4]))
				if depth == INF:
					continue
				total += 1
				for o: Array in near:
					if float(o[4]) >= depth - 0.05:
						continue
					if px >= float(o[0]) and px <= float(o[2]) and py >= float(o[1]) and py <= float(o[3]):
						hidden += 1
						break
		if total == 0:
			continue
		e["cov_prism"] = e["cov"]
		e["cov"] = minf(1.0, float(hidden) / float(total) + float(e.get("ray_cov", 0.0)))


## The silhouette rectangle of an oriented box (centre, basis, half extents) [x0, y0, x1, y1, depth].
func _box_rect(eye: Vector3, b: Basis, tv: float, centre: Vector3, basis: Basis, half: Vector3) -> Array:
	var x0 := INF
	var x1 := -INF
	var y0 := INF
	var y1 := -INF
	for sx: float in [-1.0, 1.0]:
		for sy: float in [-1.0, 1.0]:
			for sz: float in [-1.0, 1.0]:
				var p := _proj(eye, b, tv, centre + basis.x * (half.x * sx) + basis.y * (half.y * sy) + basis.z * (half.z * sz))
				if p.z <= 0.05:
					return []
				x0 = minf(x0, p.x)
				x1 = maxf(x1, p.x)
				y0 = minf(y0, p.y)
				y1 = maxf(y1, p.y)
	var cx := (x0 + x1) * 0.5
	var cy := (y0 + y1) * 0.5
	var hx := (x1 - x0) * 0.5 * SILHOUETTE
	var hy := (y1 - y0) * 0.5 * SILHOUETTE
	return [cx - hx, cy - hy, cx + hx, cy + hy, (centre - eye).dot(-b.z)]


## The silhouette rectangle [x0, y0, x1, y1, depth] of a square prism `w` wide standing `y0`-`y1` above
## `feet`, in frame-height units; [] when any corner is behind the lens.
func _prism_rect(eye: Vector3, b: Basis, tv: float, feet: Vector3, up: Vector3, w: float, y0: float, y1: float) -> Array:
	var right := b.x - up * b.x.dot(up)
	if right.length_squared() < 1e-6:
		right = up.cross(Vector3.RIGHT if absf(up.x) < 0.9 else Vector3.FORWARD)
	right = right.normalized()
	var fwd := up.cross(right).normalized()
	var hw := w * 0.5
	var x0 := INF
	var x1 := -INF
	var yy0 := INF
	var yy1 := -INF
	# A round footprint: its width is the diameter across the view; its top and bottom are the caps' near and far rims.
	for sx: float in [-hw, 0.0, hw]:
		for sz: float in ([0.0] if sx != 0.0 else [-hw, hw]):
			for sy: float in [y0, y1]:
				var p := _proj(eye, b, tv, feet + right * sx + fwd * sz + up * sy)
				if p.z <= 0.05:
					return []
				if sz == 0.0:
					x0 = minf(x0, p.x)
					x1 = maxf(x1, p.x)
				yy0 = minf(yy0, p.y)
				yy1 = maxf(yy1, p.y)
	var cx := (x0 + x1) * 0.5
	var cy := (yy0 + yy1) * 0.5
	var hx := (x1 - x0) * 0.5 * SILHOUETTE
	var hy := (yy1 - yy0) * 0.5 * SILHOUETTE
	return [cx - hx, cy - hy, cx + hx, cy + hy, (feet + up * (y0 + y1) * 0.5 - eye).dot(-b.z)]


func _proj(eye: Vector3, b: Basis, tv: float, p: Vector3) -> Vector3:
	var v := p - eye
	var z := -v.dot(b.z)
	if z < 0.05:
		return Vector3(-9.0, -9.0, z)
	var nx := v.dot(b.x) / (z * tv * _asp)
	var ny := v.dot(b.y) / (z * tv)
	return Vector3((nx + 1.0) * 0.5 * _asp, (1.0 - ny) * 0.5, z)


static func _overlap(d: float, r1: float, r2: float) -> float:
	if d >= r1 + r2:
		return 0.0
	if d <= absf(r1 - r2):
		var m := minf(r1, r2)
		return PI * m * m
	var a1 := r1 * r1 * acos(clampf((d * d + r1 * r1 - r2 * r2) / (2.0 * d * r1), -1.0, 1.0))
	var a2 := r2 * r2 * acos(clampf((d * d + r2 * r2 - r1 * r1) / (2.0 * d * r2), -1.0, 1.0))
	var k := (-d + r1 + r2) * (d + r1 - r2) * (d - r1 + r2) * (d + r1 + r2)
	return a1 + a2 - 0.5 * sqrt(maxf(k, 0.0))


func _gates(rule: String, c: Dictionary, ev: Array[Dictionary], heads: Array[Dictionary], speaker: String) -> Dictionary:
	var fails := 0
	var why := PackedStringArray()
	var score := 0.0
	var eye: Vector3 = c["eye"]
	if not _eye_ok(eye, heads, 0.15 if rule == "U" else 0.35, P_EYE_CLEAR_M if rule == "P" or rule == "PA" else 0.35):
		fails += 5
		why.append("eye")
	# A friendly camera: never a steep look down, and a lens between wide and long.
	var b0: Basis = c["basis"]
	var up_e := planet.up_at(eye)
	var down := rad_to_deg(asin(clampf(b0.z.dot(up_e), -1.0, 1.0)))
	if down > _max_down(rule):
		fails += 2
		why.append("steep=%.0f" % down)
	score += maxf(0.0, down - 30.0) * 0.06
	var fv := float(c["fov"])
	score += maxf(0.0, fv - 50.0) * 0.06 + maxf(0.0, 22.0 - fv) * 0.04
	var n_full := 0
	var min_share := 9.0
	var worst_cov := 0.0
	for i in ev.size():
		var e: Dictionary = ev[i]
		var hd: Dictionary = heads[i]
		var id := str(hd["id"])
		if bool(e["full"]):
			n_full += 1
		var is_p := rule == "P" or rule == "PA"
		# P and PA (§0 Round 4 rulings): only the speaker's cover counts - another head may be covered,
		# cropped or under the box; ranking on its cover pushed the lens up over giant front-row heads.
		if bool(e["in"]) and (not is_p or id == speaker):
			worst_cov = maxf(worst_cov, float(e["cov"]))
		if bool(e["in"]) and float(e["cov"]) > (S_COVER if rule == "S" else MAX_COVER) and (not is_p or id == speaker):
			fails += HARD_W if is_p else 1
			why.append("cov:%s=%.2f%s" % [id, float(e["cov"]), ("<" + str(e["ray_by"])) if str(e.get("ray_by", "")) != "" else ""])
		var hv := float(e["share"]) * 0.5
		var in_band := bool(e["full"]) and float(e["Y"]) - hv >= BAND_TOP - 0.005 and float(e["Y"]) + hv <= BAND_BOT + 0.005
		var clear_box := not (float(e["Y"]) + hv > BOX_TOP_Y and float(e["X"]) > BOX_X.x * _asp and float(e["X"]) < BOX_X.y * _asp)
		match rule:
			"W", "WS":
				if not in_band:
					fails += 1
					why.append("band:" + id)
				var need := W_FRONT_SHARE if bool(hd["front"]) else W_BACK_SHARE
				if float(e["share"]) < need:
					# Counted twice: the cover estimate is conservative against the rendered frame (12 layouts:
					# W's worst estimate 0.20-0.29, rendered 0.02-0.18), a head's share on screen is not.
					fails += 2
					why.append("share:" + id)
				min_share = minf(min_share, float(e["share"]) / need)
			"P", "PA":
				if id == speaker:
					# The shot's own gates, hard (HARD_W each). The band is kept with SPEAKER_BAND_IN to spare: the live
					# head stands up to a few cm off its slot and a 0.193 top read as out (K2R L02 P:grig).
					var sp_band := bool(e["full"]) and float(e["Y"]) - hv >= BAND_TOP + SPEAKER_BAND_IN and float(e["Y"]) + hv <= BAND_BOT - SPEAKER_BAND_IN
					if not sp_band:
						fails += HARD_W
						why.append("band:" + id)
					if not clear_box:
						fails += HARD_W
						why.append("box:" + id)
					if float(e["share"]) < P_SHARE:
						fails += HARD_W
						why.append("share:" + id)
					if rule == "PA" and float(e["X"]) + float(e["rho"]) > _pills_rect()[0]:
						fails += HARD_W
						why.append("not-left-of-pills:" + id)
					score += absf(float(e["share"]) - 0.25) * 4.0
				elif bool(e["in"]):
					# Another head that shows: a little better inside 20-60% from the top and clear of the box
					# (ranking only; P's band and box gates are the speaker's).
					if not clear_box:
						score += 0.5
					elif not in_band:
						score += 0.25
				if rule == "PA" and bool(e["touch"]) and _in_pills(e):
					fails += HARD_W
					why.append("pills:" + id)
			_:
				if bool(e["full"]) and not in_band:
					score += 0.4
				if bool(e["in"]) and not clear_box:
					score += 0.4
	if (rule == "P" or rule == "PA") and _yaw_off_facing(eye, heads, speaker) > FACE_MAX_DEG + 0.5:
		fails += HARD_W
		why.append("yaw=%.0f" % _yaw_off_facing(eye, heads, speaker))
	if rule == "P" or rule == "PA":
		# NOTHING LOOMS (§0 Round 4 rulings): no other head whose disc reaches into the frame is drawn taller
		# than the speaker's head times LOOM_SOLVE (a head behind the lens is not in frame).
		var sp_share := -1.0
		for i3 in ev.size():
			if str(heads[i3]["id"]) == speaker and float(ev[i3]["z"]) > 0.05:
				sp_share = float(ev[i3]["share"])
		if sp_share > 0.0:
			var tv3 := tan(deg_to_rad(float(c["fov"])) * 0.5)
			var ah := _proj(eye, b0, tv3, _mark + planet.up_at(_mark) * float(ASTRO_HEAD["c_h"]))
			if ah.z > 0.05:
				var a_share := float(ASTRO_HEAD["h"]) / (2.0 * ah.z * tv3)
				var a_ext := maxf(float(ASTRO_HEAD["r"]) / (2.0 * ah.z * tv3) / SILHOUETTE, a_share * 0.5) * 1.1
				var a_shows := ah.x + a_ext > 0.0 and ah.x - a_ext < _asp and ah.y + a_ext > 0.0 and ah.y - a_ext < 1.0
				if a_shows and a_share > sp_share * LOOM_SOLVE:
					fails += HARD_W
					why.append("looms:astronaut=%.2fx" % (a_share / sp_share))
				if rule == "PA" and a_shows and _in_pills({"X": ah.x, "Y": ah.y, "rho": a_ext}):
					fails += HARD_W
					why.append("pills:astronaut")
			for i3 in ev.size():
				var e3: Dictionary = ev[i3]
				var id3 := str(heads[i3]["id"])
				if id3 == speaker or float(e3["z"]) <= 0.05:
					continue
				var ext := maxf(float(e3["rho"]), float(e3["share"]) * 0.5) * 1.1
				var shows := float(e3["X"]) + ext > 0.0 and float(e3["X"]) - ext < _asp and float(e3["Y"]) + ext > 0.0 and float(e3["Y"]) - ext < 1.0
				if (shows or bool(e3["touch"])) and float(e3["share"]) > sp_share * LOOM_SOLVE:
					fails += HARD_W
					why.append("looms:%s=%.2fx" % [id3, float(e3["share"]) / sp_share])
	match rule:
		"W", "WS":
			score -= minf(min_share, 2.0)
		"U":
			# Every head that shows at all is whole in the frame, inside the 20-60% band, clear of the box
			# and uncovered; a frame of the rock with no head in it passes too (K2 critic 1, item 6: a
			# head cut by the frame edge, heads outside the band). Heads in the frame score better.
			var n_band := 0
			var n_bad := 0
			for i2 in ev.size():
				var e2: Dictionary = ev[i2]
				if not bool(e2.get("touch", e2["in"])):
					continue
				var hv2 := float(e2["share"]) * 0.5
				var clear2 := not (float(e2["Y"]) + hv2 > BOX_TOP_Y and float(e2["X"]) > BOX_X.x * _asp and float(e2["X"]) < BOX_X.y * _asp)
				if bool(e2["full"]) and float(e2["Y"]) - hv2 >= BAND_TOP - 0.005 and float(e2["Y"]) + hv2 <= BAND_BOT + 0.005 and clear2 and float(e2["cov"]) <= MAX_COVER:
					n_band += 1
				else:
					n_bad += 1
					fails += 1
					why.append("uhead:" + str(heads[i2]["id"]))
			var r := _rock_frame(c, ev)
			if not bool(r["full"]):
				fails += 3
				why.append("rock-out")
			if float(r["share"]) < U_ROCK_SHARE:
				fails += 1
				why.append("rock-share")
			# §2 "heads below it": frames with friends' heads under the rock beat an empty sky.
			score -= float(mini(n_band, 4)) * 1.0
			c["n_band"] = n_band
			if float(r["covered"]) > 0.1:
				fails += 1
				why.append("rock-cov=%.2f" % float(r["covered"]))
		"S", "R", "R2":
			var rk := _rocket_frame(c, rule)
			if not bool(rk["full"]):
				fails += 1
				why.append("rocket-out")
			var need_heads := 6 if rule == "S" else 7
			if n_full < need_heads:
				fails += 1
				why.append("heads=%d" % n_full)
			score -= float(n_full) * 0.3
			if rule == "S":
				var sp := _split(c, ev)
				if str(sp["why"]) != "":
					fails += 1
					why.append(str(sp["why"]))
				else:
					# A wider gap between the two halves reads better on the phone.
					score -= minf(float(sp["gap"]), 0.2) * 2.0
				c["split"] = sp
	return {"fails": fails, "why": ",".join(why), "score": score, "worst_cov": worst_cov}


## How far (deg) the lens at `eye` stands off the way `speaker` faces in a close-up (towards the mark), on the
## speaker's ground plane; 0 when the speaker is not among `heads`.
func _yaw_off_facing(eye: Vector3, heads: Array[Dictionary], speaker: String) -> float:
	for hd: Dictionary in heads:
		if str(hd["id"]) == speaker:
			var feet: Vector3 = hd["feet"]
			var up: Vector3 = hd["up"]
			var f := _tangent(_mark - feet, up, -_axis)
			var t := _tangent(eye - feet, up, f)
			return rad_to_deg(f.angle_to(t))
	return 0.0


## The steepest look down a shot may take. The gameplay camera itself looks down 28-34 deg
## (camera_rig.gd PITCH_DEFAULT_DEG / MOBILE_PITCH_DEFAULT_DEG); the crowd shots may go further, because
## the back row (Pop's head centre is 0.68 m up, the front row's crowns 1.2-1.6 m) only clears the front
## row from above: measured over all 728 P candidates for the Professor, none left every head <= 20%
## covered with the look capped at 42 deg, and 14 did at 48.
##
## S may look down to S_MAX_DOWN: its split needs the view nearly along the crowd's rows, where each head
## stands 1 m behind the next one, and on the plain Commons no S candidate kept every head <= 20% covered
## at 48 deg (best: Pop 0.43 covered); at 55 deg five passed, at 49-55 deg (K2R `--k2-rank=S`).
func _max_down(rule: String) -> float:
	if rule == "U":
		return 42.0
	return S_MAX_DOWN if rule == "S" else 48.0


## The gates that need no cover test, so most candidates never pay for one.
func _cheap(rule: String, c: Dictionary, heads: Array[Dictionary], speaker: String) -> int:
	var eye: Vector3 = c["eye"]
	if not _eye_ok(eye, heads, 0.15 if rule == "U" else 0.35, P_EYE_CLEAR_M if rule == "P" or rule == "PA" else 0.35):
		return 5
	var b: Basis = c["basis"]
	var up_e := planet.up_at(eye)
	if rad_to_deg(asin(clampf(b.z.dot(up_e), -1.0, 1.0))) > _max_down(rule):
		return 2
	var tv := tan(deg_to_rad(float(c["fov"])) * 0.5)
	var fails := 0
	match rule:
		"W", "WS", "P", "PA":
			for hd: Dictionary in heads:
				if rule != "W" and rule != "WS" and str(hd["id"]) != speaker:
					continue
				var p := _proj(eye, b, tv, hd["c"])
				if p.z <= 0.05:
					fails += 1
					continue
				var share := float(hd["h"]) / (2.0 * p.z * tv)
				var hv := share * 0.5
				if p.y - hv < BAND_TOP - 0.005 or p.y + hv > BAND_BOT + 0.005 or p.x < 0.0 or p.x > _asp:
					fails += 1
				elif (rule == "W" or rule == "WS") and share < (W_FRONT_SHARE if bool(hd["front"]) else W_BACK_SHARE):
					fails += 1
				elif rule != "W" and rule != "WS" and share < P_SHARE:
					fails += 1
		"U":
			var r := _rock_frame(c)
			if not bool(r["full"]) or float(r["share"]) < U_ROCK_SHARE:
				fails += 1
		"S", "R", "R2":
			if not bool(_rocket_frame(c, rule)["full"]):
				fails += 1
			if rule == "S" and not _split_cheap(c, heads):
				fails += 1
	return fails


## Anything standing within FOREGROUND_M of the lens across the frame (a lamp post, a planter, the pad's
## mast): sight lines on real triangles to a 4 x 3 grid of frame points.
func _foreground(c: Dictionary, heads: Array[Dictionary] = [], rule: String = "", speaker: String = "") -> String:
	var eye: Vector3 = c["eye"]
	# Foreground: nearer than FOREGROUND_M, or than half the way to the nearest head.
	var reach := FOREGROUND_M
	var nearest := INF
	for hd: Dictionary in heads:
		nearest = minf(nearest, eye.distance_to(hd["c"] as Vector3))
	if nearest < INF:
		reach = maxf(FOREGROUND_M, nearest * 0.5)
	if rule == "P" or rule == "PA":
		# A close-up (K2S): the lens stands 1.4-4.2 m from the speaker, so FOREGROUND_M reached past the
		# speaker's own head and a flower bed beside the Professor failed PA on 2 of 12 layouts (seed 9300).
		# In front of the speaker's head: at most P_FG_SHARE of the way to it (the speaker's own cover is
		# measured on sight lines anyway).
		for hd: Dictionary in heads:
			if str(hd["id"]) == speaker:
				reach = clampf(eye.distance_to(hd["c"] as Vector3) * P_FG_SHARE, P_FG_MIN_M, FOREGROUND_M)
	var b: Basis = c["basis"]
	var tv := tan(deg_to_rad(float(c["fov"])) * 0.5)
	if rule != "P" and rule != "PA":
		# In the wide and rock shots a friend within FOREGROUND_M of the lens is foreground too: a body
		# cut by the frame edge filling a third of it (U, round 1). A speaker's close-up is exempt.
		for hd: Dictionary in heads:
			var up: Vector3 = hd["up"]
			for hgt: float in [0.3, float(hd["hy0"]), float(hd["c"].distance_to(hd["feet"]))]:
				var v := (hd["feet"] as Vector3) + up * hgt - eye
				var z := -v.dot(b.z)
				if v.length() < FOREGROUND_M + float(hd["r"]) and z > CAM_NEAR \
						and absf(v.dot(b.x) / (z * tv * _asp)) <= 1.0 + float(hd["r"]) / (z * tv * _asp) \
						and absf(v.dot(b.y) / (z * tv)) <= 1.0 + float(hd["r"]) / (z * tv):
					return "near:" + str(hd["id"])
	# Every prop, decoration, building and pad mesh (glow globes included) whose box comes within
	# FOREGROUND_M of the lens and shows in the frame - a thin pole or a lamp globe slips between rays.
	for o: Array in _occ:
		var xf: Transform3D = o[0]
		var box: AABB = o[1]
		if ((o[3] as Vector3) - eye).length() > float(o[4]) + reach:
			continue
		var q := (xf.affine_inverse() * eye).clamp(box.position, box.end)
		if (xf * q).distance_to(eye) >= reach:
			continue
		if not _near_part_in_frame(eye, b, tv, xf, box, reach):
			continue
		if not bool(o[5]) or not _sight_open:
			# Not in VisitorSystem's occluder space (an additive glow shape): its box decides.
			return "near:" + str(o[2])
		# Its box only proposes (a merged mesh - all of a building's lamps - has a box far bigger than its
		# shapes): real triangles confirm, with sight lines from the lens to points inside the near part.
		var hit := _near_hit(eye, b, tv, xf, box, reach)
		if hit != "":
			return "near:" + hit.get_file()
	# Real triangles across the frame too: FG_COLS x FG_ROWS sight lines, `reach` long.
	for ix in FG_COLS:
		for iy in FG_ROWS:
			var nx := -0.92 + 1.84 * float(ix) / float(FG_COLS - 1)
			var ny := -0.9 + 1.8 * float(iy) / float(FG_ROWS - 1)
			var d := (-b.z + b.x * nx * tv * _asp + b.y * ny * tv).normalized()
			var hit := _sight(eye, eye + d * reach)
			if hit != "" and not hit.begins_with("astronaut"):
				return hit.get_file()
	return ""


## Whether the part of an oriented box near the lens shows in the frame: the box clipped to the cube of
## half-side FOREGROUND_M round the lens (in the box's own axes), its corners projected; a clipped box
## straddling the lens plane counts as shown. A tall mast whose foot stands beside the lens but whose top
## is far off in the frame is not a foreground object; the part of it beside the lens is.
func _near_hit(eye: Vector3, b: Basis, tv: float, xf: Transform3D, box: AABB, reach: float) -> String:
	var le := xf.affine_inverse() * eye
	var sc := Vector3(xf.basis.x.length(), xf.basis.y.length(), xf.basis.z.length())
	var r := Vector3(reach / maxf(sc.x, 1e-4), reach / maxf(sc.y, 1e-4), reach / maxf(sc.z, 1e-4))
	var lo := (le - r).max(box.position)
	var hi := (le + r).min(box.end)
	var clip := AABB(lo, (hi - lo).max(Vector3.ZERO))
	# The centre line and a 3 x 3 x 3 lattice through the clipped part, pulled in from its faces.
	for ix in 3:
		for iy in NEAR_LATTICE_Y:
			for iz in 3:
				var f := Vector3(0.15 + 0.35 * float(ix), float(iy) / float(NEAR_LATTICE_Y - 1) * 0.9 + 0.05, 0.15 + 0.35 * float(iz))
				var p := xf * (clip.position + clip.size * f)
				var v := p - eye
				var dist := v.length()
				if dist >= reach or dist < 0.01:
					continue
				var z := -v.dot(b.z)
				if z < CAM_NEAR or absf(v.dot(b.x) / (z * tv * _asp)) > 1.0 or absf(v.dot(b.y) / (z * tv)) > 1.0:
					continue
				var h := _sight(eye, eye + v * ((dist + 0.3) / dist))
				if h != "" and not h.begins_with("astronaut"):
					return h
	return ""


func _near_part_in_frame(eye: Vector3, b: Basis, tv: float, xf: Transform3D, box: AABB, reach: float) -> bool:
	var le := xf.affine_inverse() * eye
	var sc := Vector3(xf.basis.x.length(), xf.basis.y.length(), xf.basis.z.length())
	var r := Vector3(reach / maxf(sc.x, 1e-4), reach / maxf(sc.y, 1e-4), reach / maxf(sc.z, 1e-4))
	var lo := (le - r).max(box.position)
	var hi := (le + r).min(box.end)
	if lo.x > hi.x or lo.y > hi.y or lo.z > hi.z:
		return false
	var clip := AABB(lo, hi - lo)
	var x0 := INF
	var x1 := -INF
	var y0 := INF
	var y1 := -INF
	var behind := 0
	for i in 8:
		var v := xf * clip.get_endpoint(i) - eye
		var z := -v.dot(b.z)
		if z < CAM_NEAR:
			behind += 1
			continue
		var nx := v.dot(b.x) / (z * tv * _asp)
		var ny := v.dot(b.y) / (z * tv)
		x0 = minf(x0, nx)
		x1 = maxf(x1, nx)
		y0 = minf(y0, ny)
		y1 = maxf(y1, ny)
	if behind == 8:
		return false
	var rect_in := x1 > -1.0 and x0 < 1.0 and y1 > -1.0 and y0 < 1.0
	if behind == 0 or rect_in:
		return rect_in
	# Straddling the lens plane with every in-front corner outside the frame: shown only if a sight line
	# through the frame (its centre and four points near its corners) runs into the clipped box.
	var inv := xf.affine_inverse()
	for d2: Vector2 in [Vector2.ZERO, Vector2(-0.9, -0.9), Vector2(0.9, -0.9), Vector2(-0.9, 0.9), Vector2(0.9, 0.9)]:
		var dir := (-b.z + b.x * d2.x * tv * _asp + b.y * d2.y * tv).normalized()
		for dist: float in [0.15, 0.4, 0.8, 1.2, 1.7, 2.2, 2.6]:
			if clip.has_point(inv * (eye + dir * dist)):
				return true
	return false


## The static meshes a shot must keep clear of its lens (see `_foreground`): [global xf, local AABB,
## label, world centre, bounding radius, in VisitorSystem's occluder space], every visible mesh under the props, decorations, buildings, bench, trash, the
## replay board and the pad (not the rocket, not its waypoint gem), within 30 m of the pad, standing at
## least LOW_OCC_M off the ground, minus what draws no solid shape (a billboard, a depth-less beam or
## ghost, an additive quad).
func _collect_occluders() -> void:
	_occ.clear()
	var roots: Array[Node] = []
	if planet.props_root != null:
		roots.append(planet.props_root)
	for path: String in ["Decorations", "Buildings", "BuildBench", "TrashField", "ReplayBoard", "Rocket"]:
		var n := _world.get_node_or_null(path)
		if n != null:
			roots.append(n)
	var stack: Array[Node] = roots
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n == _rocket or str(n.name) == "Waypoint":
			continue
		var mi := n as MeshInstance3D
		if mi != null and mi.mesh != null and mi.is_visible_in_tree() and _solid(mi):
			var xf := mi.global_transform
			var box := mi.get_aabb()
			var c := xf * box.get_center()
			var rad := (xf.basis.x * box.size.x).length() * 0.5 + (xf.basis.y * box.size.y).length() * 0.5 + (xf.basis.z * box.size.z).length() * 0.5
			if c.distance_to(_pad_ground) < 30.0 + rad:
				var ground := planet.surface_point(planet.dir_of(c))
				var up := planet.up_at(c)
				var top := -INF
				for i in 8:
					top = maxf(top, (xf * box.get_endpoint(i) - ground).dot(up))
				if top >= LOW_OCC_M:
					_occ.append([xf, box, str(mi.get_parent().name) + "/" + str(mi.name), c, rad, not _vs_glow(mi)])
		for ch: Node in n.get_children():
			stack.append(ch)
	# The rocket as it stands at rest on the pad (a pad arrival may still be lifting it at load).
	if _rocket != null:
		var rb := _mesh_box(_rocket, _rocket.global_transform.affine_inverse())
		if rb.size != Vector3.ZERO:
			var rc := _rocket_rest * rb.get_center()
			_occ.append([_rocket_rest, rb, "rocket", rc, rb.size.length() * 0.5, true])


## VisitorSystem `_is_glow`'s rule (what its occluder space leaves out), for `_foreground`.
static func _vs_glow(mi: MeshInstance3D) -> bool:
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


static func _solid(mi: MeshInstance3D) -> bool:
	var mat: Material = mi.material_override
	if mat == null and mi.mesh.get_surface_count() > 0:
		mat = mi.get_active_material(0)
	if mat is ShaderMaterial and (mat as ShaderMaterial).shader != null:
		var code := (mat as ShaderMaterial).shader.code
		if code.contains("depth_draw_never") or code.contains("billboard") or (code.contains("blend_add") and (mi.mesh is QuadMesh or mi.mesh is PlaneMesh)):
			return false
	elif mat is BaseMaterial3D:
		var bm := mat as BaseMaterial3D
		if bm.billboard_mode != BaseMaterial3D.BILLBOARD_DISABLED:
			return false
		if bm.blend_mode == BaseMaterial3D.BLEND_MODE_ADD and (mi.mesh is QuadMesh or mi.mesh is PlaneMesh):
			return false
	return true


func _proj_c(c: Dictionary, p: Vector3) -> Vector3:
	return _proj(c["eye"], c["basis"], tan(deg_to_rad(float(c["fov"])) * 0.5), p)


## The choice pills' rectangle [x0, y0, x1, y1] in frame-height units (X from the left, Y from the top).
func _pills_rect() -> Array[float]:
	var canvas_w := CANVAS_H * _asp
	var panel_right := canvas_w * (0.5 + 0.35)
	return [(panel_right - PILL_X_PX.x) / CANVAS_H, PILL_Y_PX.x / CANVAS_H, (panel_right - PILL_X_PX.y) / CANVAS_H, PILL_Y_PX.y / CANVAS_H]


func _in_pills(e: Dictionary) -> bool:
	var pr := _pills_rect()
	var X := float(e["X"])
	var Y := float(e["Y"])
	var r := float(e["rho"])
	return X + r > pr[0] and X - r < pr[2] and Y + r > pr[1] and Y - r < pr[3]


## THE S SPLIT (see SPLIT_MARGIN), from a candidate's evaluated heads: {"why": "" when it holds, "gap": the
## smaller distance of the two halves' nearest centres from the frame's middle (width fractions), "crowd":
## "left" / "right", "heads": [min, max] head centre x, "astro", "rocket": centre x}. Every head whose disc
## shows in the frame at all counts; x is a share of the frame WIDTH.
func _split(c: Dictionary, ev: Array[Dictionary]) -> Dictionary:
	var hx: Array[float] = []
	for e: Dictionary in ev:
		if bool(e.get("touch", e["in"])):
			hx.append(float(e["X"]) / _asp)
	return _split_of(c, hx)


func _split_of(c: Dictionary, hx: Array[float]) -> Dictionary:
	var out := {"why": "", "gap": 0.0, "crowd": "", "heads": [-1.0, -1.0], "astro": -1.0, "rocket": -1.0}
	var ap := _proj_c(c, _mark + planet.up_at(_mark) * (ASTRO_H * 0.5))
	var rk := _rocket_frame(c, "S")
	if hx.is_empty() or ap.z <= 0.05:
		out["why"] = "split:none"
		return out
	# The astronaut's feet, middle and helmet and the rocket's foot, middle and nose all count, so the WHOLE
	# figure is on its half and any measure of its centre (a silhouette's centroid or its box) agrees.
	var au := planet.up_at(_mark)
	var ru := _rocket_rest.basis.y.normalized()
	var ax_lo := INF
	var ax_hi := -INF
	for hgt: float in [0.1, ASTRO_H * 0.5, ASTRO_H]:
		var q := _proj_c(c, _mark + au * hgt)
		if q.z <= 0.05:
			out["why"] = "split:none"
			return out
		ax_lo = minf(ax_lo, q.x / _asp)
		ax_hi = maxf(ax_hi, q.x / _asp)
	var rx_lo := INF
	var rx_hi := -INF
	for hgt2: float in [0.0, RocketModel.TOTAL_HEIGHT * 0.5, RocketModel.TOTAL_HEIGHT]:
		var q2 := _proj_c(c, _rocket_rest.origin + ru * hgt2)
		if q2.z <= 0.05:
			out["why"] = "split:none"
			return out
		rx_lo = minf(rx_lo, q2.x / _asp)
		rx_hi = maxf(rx_hi, q2.x / _asp)
	var lo := 1.0
	var hi := 0.0
	for x in hx:
		lo = minf(lo, x)
		hi = maxf(hi, x)
	var ax := ap.x / _asp
	var rx := float(rk["X"]) / _asp
	out["heads"] = [lo, hi]
	out["astro"] = ax
	out["rocket"] = rx
	var a := 0.5 - SPLIT_MARGIN
	var b := 0.5 + SPLIT_MARGIN
	if hi <= a and ax_lo >= b and rx_lo >= b:
		out["crowd"] = "left"
		out["gap"] = minf(0.5 - hi, minf(ax_lo, rx_lo) - 0.5)
	elif lo >= b and ax_hi <= a and rx_hi <= a:
		out["crowd"] = "right"
		out["gap"] = minf(lo - 0.5, 0.5 - maxf(ax_hi, rx_hi))
	else:
		out["why"] = "split:heads=%.2f-%.2f,astro=%.2f,rocket=%.2f" % [lo, hi, ax, rx]
	return out


## The split on head centres alone (no cover test), for `_cheap`.
func _split_cheap(c: Dictionary, heads: Array[Dictionary]) -> bool:
	var tv := tan(deg_to_rad(float(c["fov"])) * 0.5)
	var hx: Array[float] = []
	for hd: Dictionary in heads:
		var p := _proj(c["eye"], c["basis"], tv, hd["c"])
		if p.z <= 0.05:
			continue
		var rho := float(hd["r"]) / (2.0 * p.z * tv)
		if p.x + rho > 0.0 and p.x - rho < _asp and p.y + rho > 0.0 and p.y - rho < 1.0:
			hx.append(p.x / _asp)
	return str(_split_of(c, hx)["why"]) == ""


func _rock_frame(c: Dictionary, ev: Array[Dictionary] = []) -> Dictionary:
	var rc := _rock_centre()
	var p := _proj_c(c, rc)
	if p.z <= 0.05:
		return {"full": false, "share": 0.0, "covered": 1.0}
	var tv := tan(deg_to_rad(float(c["fov"])) * 0.5)
	var rho := _rock_half_v / (2.0 * p.z * tv)
	var hr := rho * 1.25
	var full := p.x - hr >= 0.0 and p.x + hr <= _asp and p.y - rho >= 0.02 and p.y + rho <= 0.62
	var covered := 0.0
	for e: Dictionary in ev:
		if float(e["z"]) > 0.05:
			covered += _overlap(Vector2(p.x, p.y).distance_to(Vector2(float(e["X"]), float(e["Y"]))), rho, float(e["rho"]))
	return {"full": full, "share": rho * 2.0, "covered": covered / (PI * rho * rho)}


## Whether the rocket is in the frame: S wants all of it; R its nose (the top fifth of the hull).
func _rocket_frame(c: Dictionary, rule: String = "S") -> Dictionary:
	var up := _rocket_rest.basis.y.normalized()
	var base := _proj_c(c, _rocket_rest.origin if rule == "S" else _rocket_rest.origin + up * (RocketModel.TOTAL_HEIGHT * 0.8))
	var top := _proj_c(c, _rocket_rest.origin + up * RocketModel.TOTAL_HEIGHT)
	var full := base.z > 0.05 and top.z > 0.05 and top.y >= 0.02 and base.y <= 0.98 and base.x >= 0.0 and base.x <= _asp and top.x >= 0.0 and top.x <= _asp
	if full and rule == "S":
		# S: the WHOLE rocket, fins included (a hull point at the edge left the nose cut, K2R L02), so its
		# base, middle and nose each keep ROCKET_FRAME_R clear of the frame's sides, top and bottom.
		var tv := tan(deg_to_rad(float(c["fov"])) * 0.5)
		for hgt: float in [0.0, RocketModel.TOTAL_HEIGHT * 0.5, RocketModel.TOTAL_HEIGHT]:
			var p := _proj_c(c, _rocket_rest.origin + up * hgt)
			var rr := ROCKET_FRAME_R / (2.0 * maxf(p.z, 0.05) * tv)
			if p.z <= 0.05 or p.x - rr < 0.0 or p.x + rr > _asp or p.y - rr < 0.0 or p.y + rr > 1.0:
				full = false
	return {"full": full, "X": (base.x + top.x) * 0.5}


func _eye_ok(eye: Vector3, heads: Array[Dictionary], min_h: float = 0.35, clear: float = 0.35) -> bool:
	var d := planet.dir_of(eye)
	var ground := planet.surface_point(d)
	if (eye - ground).dot(d) < min_h:
		return false
	for hd: Dictionary in heads:
		if eye.distance_to(hd["c"] as Vector3) < float(hd["r"]) + clear:
			return false
		var rel: Vector3 = eye - (hd["feet"] as Vector3)
		var upn: Vector3 = hd["up"]
		if rel.dot(upn) < float(hd["by1"]) + 0.2 and (rel - upn * rel.dot(upn)).length() < float(hd["bw"]) * 0.5 + clear:
			return false
	var au := planet.up_at(_mark)
	var rel := eye - _mark
	if rel.dot(au) < 1.9 and (rel - au * rel.dot(au)).length() < 0.6:
		return false
	var ru := _rocket_rest.basis.y.normalized()
	var rr := eye - _rocket_rest.origin
	if rr.dot(ru) < RocketModel.TOTAL_HEIGHT + 0.5 and (rr - ru * rr.dot(ru)).length() < 1.4:
		return false
	return true


func _candidates(rule: String, heads: Array[Dictionary], speaker: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var up_c := planet.up_at(_crowd_centre)
	var a_c := _tangent(_crowd_centre - _pad_ground, up_c, _axis)
	match rule:
		"W", "WS":
			var up := planet.up_at(_mark)
			var a := _tangent(_crowd_centre - _mark, up, _axis)
			var l := a.cross(up).normalized()
			var spheres := _head_spheres(heads)
			for h: float in [3.2, 4.0, 4.8, 5.6, 6.4, 7.2]:
				for back: float in [0.4, 1.2, 2.0, 2.8, 3.6]:
					for lat: float in [-2.0, -1.0, -0.4, 0.0, 0.4, 1.0, 2.0]:
						var eye := _mark + up * h - a * back + l * lat
						var fit := _fit(eye, spheres, 0.225, 0.575)
						out.append({"eye": eye, "basis": fit[0], "fov": fit[1]})
		"U":
			var rc := _rock_centre()
			var l_c := a_c.cross(up_c).normalized()
			for az in 24:
				var dirh := a_c.rotated(up_c, deg_to_rad(15.0 * float(az)))
				for dist3: float in [2.0, 3.0, 4.2, 5.6]:
					for side: float in [-2.0, 0.0, 2.0]:
						for h3: float in [0.18, 0.4, 0.7]:
							var base := _crowd_centre + l_c * side
							var eye3 := base + dirh * dist3
							eye3 = planet.surface_point(planet.dir_of(eye3)) + planet.up_at(eye3) * h3
							var z3 := eye3.distance_to(rc)
							var fov3 := clampf(rad_to_deg(2.0 * atan(_rock_half_v / (z3 * 0.215))), 20.0, 60.0)
							for xr: float in [0.3, 0.5, 0.7]:
								for yr: float in [0.13, 0.19]:
									out.append({"eye": eye3, "basis": _compose(eye3, rc, xr * _asp, yr, fov3), "fov": fov3, "tag": "az%d d%.1f s%.0f h%.2f x%.1f y%.2f" % [15 * az, dist3, side, h3, xr, yr]})
		"S":
			# Eyes all round the space between the astronaut and the crowd, raised; each one's yaw puts the
			# frame's middle in the angular gap between the crowd's head centres and the astronaut and rocket
			# (`_fit_split`), and an eye with no such gap is no candidate.
			# Round centres between the astronaut and the crowd and on the crowd; on the plain Commons the
			# split-and-cover passes came from 45-120 deg either side of the axis, 4-10 m out, 5-11 m up
			# (none from 3 m up or 12-14 m out).
			var centres := {"mid": planet.surface_point(planet.dir_of((_mark + _crowd_centre) * 0.5)), "crowd": _crowd_centre}
			for cn: String in centres:
				var mid: Vector3 = centres[cn]
				var up4 := planet.up_at(mid)
				var a4 := _tangent(_crowd_centre - _mark, up4, _axis)
				for az4 in range(0, 360, 10):
					var dir4 := a4.rotated(up4, deg_to_rad(float(az4)))
					for dist4: float in [4.0, 5.5, 7.0, 8.5, 10.0]:
						for h4: float in [4.5, 6.0, 7.5, 9.0, 10.5]:
							var eye4 := mid + dir4 * dist4
							eye4 = planet.surface_point(planet.dir_of(eye4)) + planet.up_at(eye4) * h4
							var fit4 := _fit_split(eye4, heads)
							if fit4.is_empty():
								continue
							out.append({"eye": eye4, "basis": fit4[0], "fov": fit4[1], "tag": "%s az%d d%.1f h%.1f" % [cn, az4, dist4, h4]})
		"R", "R2":
			# From the pad's side of the crowd: the rocket at a three-quarter in the frame's near side, the
			# crowd beyond it turned toward it (so toward the lens), the back row seen over the front row.
			var spr := _head_spheres(heads)
			spr.append([_rocket_rest.origin + _rocket_rest.basis.y.normalized() * RocketModel.TOTAL_HEIGHT, 0.5])
			var up_p := planet.up_at(_pad_ground)
			var to_pad := _tangent(_pad_ground - _crowd_centre, up_p, -_axis)
			for az5 in range(20, 141, 20):
				for side5: float in [-1.0, 1.0]:
					var dir5 := to_pad.rotated(up_p, deg_to_rad(float(az5)) * side5)
					for dist5: float in [2.5, 4.0, 5.5]:
						# The back row clears the front row's crowns from ~11 m only from 6-9 m up (Pip behind
						# Fen's eye stalks needs the most): see `_back_gaps`.
						for h5: float in [4.6, 5.8, 7.0, 8.2, 9.4]:
							var eye5 := _pad_ground + dir5 * dist5
							eye5 = planet.surface_point(planet.dir_of(eye5)) + planet.up_at(eye5) * h5
							var fit5 := _fit(eye5, spr, 0.08, 0.58)
							out.append({"eye": eye5, "basis": fit5[0], "fov": fit5[1]})
	return out


## P and PA candidates, generated over slices into job["cands"]; true when done.
## §0 Round 4 rulings: no other crowd head may be drawn taller than LOOM_MAX x the speaker's, and the front
## row's heads differ (Grig 0.96 m, Bolt 0.83, the Professor 0.57): a neighbour must stand farther from the
## lens than the speaker, or out of the frame. So the eyes swing round (a neighbour lined up behind the
## speaker), the speaker may sit near either side (a neighbour off the other edge), and the lens comes close.
## Two exact pre-tests keep the cost down, both dropping only framings `_gates` fails: an eye too near a
## head or body (`_eye_ok`, P_EYE_CLEAR_M) is skipped whole, and a framing where a head that could loom (by
## distance) shows drawn taller than LOOM_SOLVE x the speaker's is not proposed. With nothing left, the first
## framing is kept so the search still has a result.
func _p_candidates_step(job: Dictionary, t0: int, budget_usec: float) -> bool:
	var rule := str(job["rule"])
	var speaker := str(job["speaker"])
	var heads: Array[Dictionary] = job["heads"]
	if not job.has("gen"):
		var hd := {}
		for h2: Dictionary in heads:
			if str(h2["id"]) == speaker:
				hd = h2
		job["cands"] = [] as Array[Dictionary]
		if hd.is_empty():
			return true
		var pa := rule == "PA"
		var eyes: Array = []
		var ystep := PA_YAW_STEP if pa else P_YAW_STEP
		var ymax := PA_YAW_MAX if pa else P_YAW_MAX
		for yaw in range(-ymax, ymax + 1, ystep):
			for dist: float in (PA_DISTS if pa else P_DISTS):
				for el: float in (PA_ELS if pa else P_ELS):
					eyes.append(Vector3(float(yaw), dist, el))
		var hc0: Vector3 = hd["c"]
		var up0 := planet.up_at(hc0)
		job["gen"] = {"hd": hd, "eyes": eyes, "i": 0, "spare": {}, "up": up0, "to_mark": _tangent(_mark - hc0, up0, -_axis)}
	var gen: Dictionary = job["gen"]
	var out: Array[Dictionary] = job["cands"]
	var hd3: Dictionary = gen["hd"]
	var hc: Vector3 = hd3["c"]
	var up2: Vector3 = gen["up"]
	var to_mark: Vector3 = gen["to_mark"]
	var h_s := float(hd3["h"])
	var pa2 := rule == "PA"
	var xs: Array[float] = P_XS_PA if pa2 else P_XS
	var shares: Array[float] = PA_FIT_SHARES if pa2 else P_FIT_SHARES
	var eyes2: Array = gen["eyes"]
	while int(gen["i"]) < eyes2.size():
		if float(Time.get_ticks_usec() - t0) > budget_usec:
			return false
		var ye: Vector3 = eyes2[int(gen["i"])]
		gen["i"] = int(gen["i"]) + 1
		var dist := ye.y
		var el := ye.z
		var eye2 := hc + to_mark.rotated(up2, deg_to_rad(ye.x)) * dist + up2 * el
		var z := eye2.distance_to(hc)
		var extra := maxf(0.0, rad_to_deg(atan2(el, dist)) - 20.0) * 0.05 - dist * 0.05 + absf(ye.x) * 0.004
		var have_spare := not (gen["spare"] as Dictionary).is_empty()
		if have_spare and not _eye_ok(eye2, heads, 0.35, P_EYE_CLEAR_M):
			continue
		var risky: Array[Dictionary] = []
		for h3: Dictionary in heads:
			if str(h3["id"]) != speaker and float(h3["h"]) / maxf(eye2.distance_to(h3["c"] as Vector3), 0.01) > h_s / z * LOOM_SOLVE * 0.6:
				risky.append(h3)
		# The astronaut's helmet looms like a crowd head (ASTRO_HEAD).
		var a_c := _mark + planet.up_at(_mark) * float(ASTRO_HEAD["c_h"])
		if float(ASTRO_HEAD["h"]) / maxf(eye2.distance_to(a_c), 0.01) > h_s / z * LOOM_SOLVE * 0.6:
			risky.append({"c": a_c, "r": float(ASTRO_HEAD["r"]) / SILHOUETTE, "h": float(ASTRO_HEAD["h"])})
		# `_compose`, with what does not change across this eye's framings worked out once.
		var up_e := planet.up_at(eye2)
		var v := hc - eye2
		var b_look := Basis.looking_at(_tangent(v, up_e, -_axis), up_e)
		for want_share: float in shares:
			var fov := clampf(rad_to_deg(2.0 * atan(h_s / (2.0 * z * want_share))), 12.0, 50.0)
			var tv := tan(deg_to_rad(fov) * 0.5)
			for want_x: float in xs:
				var b := Basis.looking_at(-(b_look.rotated(up_e, atan((2.0 * want_x - 1.0) * tv * _asp))).z, up_e)
				var zh := -v.dot(b.z)
				# The head's centre 0.37 from the top, moved down when the lens's clamp (fov <= 50) draws the head
				# taller than wanted, so it still sits inside the band (K2S round 2, offline model of seed 9300: a
				# 2.0 m lens drew the Professor 0.34 tall, top 0.20 at 0.37; no framing within 45 deg of his facing
				# kept the helmet and Bolt from looming until he could sit at 0.40).
				var sh_d := h_s / (2.0 * maxf(zh, 0.01) * tv)
				var y_lo := BAND_TOP + SPEAKER_BAND_IN + sh_d * 0.5 + 0.01
				var y_hi := BAND_BOT - SPEAKER_BAND_IN - sh_d * 0.5 - 0.01
				var want_y := 0.40 if y_lo > y_hi else clampf(0.37, y_lo, y_hi)
				var bas := b.rotated(b.x, atan2(v.dot(up_e), maxf(zh, 0.01)) - atan((1.0 - 2.0 * want_y) * tv))
				var cand := {"eye": eye2, "basis": bas, "fov": fov, "extra": extra + absf(want_x - 0.5) * 0.4}
				if not have_spare:
					gen["spare"] = cand
					have_spare = true
				var ps := _proj(eye2, bas, tv, hc)
				var looms := false
				for h4: Dictionary in risky:
					var pn := _proj(eye2, bas, tv, h4["c"])
					if pn.z <= 0.05 or ps.z <= 0.05:
						continue
					var ext := float(h4["r"]) / (2.0 * pn.z * tv)
					if pn.x + ext > 0.0 and pn.x - ext < _asp and pn.y + ext > 0.0 and pn.y - ext < 1.0 \
							and float(h4["h"]) / pn.z > h_s / ps.z * LOOM_SOLVE:
						looms = true
						break
				if not looms:
					out.append(cand)
	if out.is_empty() and not (gen["spare"] as Dictionary).is_empty():
		out.append(gen["spare"])
	job.erase("gen")
	return true


func _head_spheres(heads: Array[Dictionary]) -> Array:
	var sp: Array = []
	for hd: Dictionary in heads:
		sp.append([hd["c"], hd["r"]])
	return sp


## A level basis at `eye` and a vertical FOV that fit `spheres` ([centre, radius] pairs) between `top_y` and
## `bot_y` of the frame height, centred left-right, inside the frame width.
func _fit(eye: Vector3, spheres: Array, top_y: float, bot_y: float) -> Array:
	var up := planet.up_at(eye)
	var cen := Vector3.ZERO
	for s: Array in spheres:
		cen += s[0] as Vector3
	cen /= maxf(1.0, float(spheres.size()))
	var fwd := _tangent(cen - eye, up, -_axis)
	var b := Basis.looking_at(fwd, up)
	for it in 2:
		var minx := INF
		var maxx := -INF
		for s: Array in spheres:
			var v := (s[0] as Vector3) - eye
			var z := -v.dot(b.z)
			if z < 0.1:
				continue
			var ax := atan2(v.dot(b.x), z)
			var al := asin(clampf(float(s[1]) / maxf(v.length(), 0.01), 0.0, 1.0))
			minx = minf(minx, ax - al)
			maxx = maxf(maxx, ax + al)
		if minx == INF:
			break
		var yc := (minx + maxx) * 0.5
		b = Basis.looking_at(-(b.rotated(up, -yc)).z, up)
	var top := -INF
	var bot := INF
	var hw := 0.0
	for s: Array in spheres:
		var v := (s[0] as Vector3) - eye
		var zh := -v.dot(b.z)
		if zh < 0.1:
			continue
		var ay := atan2(v.dot(b.y), zh)
		var ax2 := atan2(v.dot(b.x), zh)
		var al2 := asin(clampf(float(s[1]) / maxf(v.length(), 0.01), 0.0, 1.0))
		top = maxf(top, ay + al2)
		bot = minf(bot, ay - al2)
		hw = maxf(hw, maxf(absf(tan(ax2 + al2)), absf(tan(ax2 - al2))))
	if top == -INF:
		return [b, 45.0]
	var ut := 1.0 - 2.0 * top_y
	var ub := 1.0 - 2.0 * bot_y
	var half := (top - bot) / maxf(ut - ub, 0.05)
	var p := top - ut * half
	var T := tan(half)
	var T_h := hw / 0.94
	var T_a := T_h / _asp
	if T_a > T:
		T = T_a
		p = (top + bot) * 0.5 - (ut + ub) * 0.5 * atan(T)
	var fov := clampf(rad_to_deg(2.0 * atan(T)), 16.0, 60.0)
	return [b.rotated(b.x, p), fov]


## S's framing from `eye`: a level heading whose middle splits the crowd's head centres from the astronaut's
## and the rocket's centres (the middle of the widest angular gap between the two groups, [] when they
## overlap from here), a pitch and a vertical FOV that fit the heads, the rocket's nose and the astronaut
## between 10% and 58% of the frame height (the rocket's foot is checked by the gates), and a width that
## holds all of them. [basis, fov].
func _fit_split(eye: Vector3, heads: Array[Dictionary]) -> Array:
	var up := planet.up_at(eye)
	var b0 := Basis.looking_at(_tangent(_crowd_centre - eye, up, -_axis), up)
	var ru := _rocket_rest.basis.y.normalized()
	var astro_c := _mark + planet.up_at(_mark) * (ASTRO_H * 0.5)
	var rocket_c := _rocket_rest.origin + ru * (RocketModel.TOTAL_HEIGHT * 0.5)
	var hmin := INF
	var hmax := -INF
	for hd: Dictionary in heads:
		var v := (hd["c"] as Vector3) - eye
		var z := -v.dot(b0.z)
		if z < 0.1:
			return []
		var a := atan2(v.dot(b0.x), z)
		hmin = minf(hmin, a)
		hmax = maxf(hmax, a)
	var omin := INF
	var omax := -INF
	for p: Vector3 in [astro_c, rocket_c]:
		var v2 := p - eye
		var z2 := -v2.dot(b0.z)
		if z2 < 0.1:
			return []
		var a2 := atan2(v2.dot(b0.x), z2)
		omin = minf(omin, a2)
		omax = maxf(omax, a2)
	var split := 0.0
	if hmax < omin:
		split = (hmax + omin) * 0.5
	elif omax < hmin:
		split = (omax + hmin) * 0.5
	else:
		return []
	var b := Basis.looking_at(-(b0.rotated(up, -split)).z, up)
	var sp := _head_spheres(heads)
	sp.append([_rocket_rest.origin + ru * RocketModel.TOTAL_HEIGHT, 0.5])
	sp.append([_rocket_rest.origin + ru * 0.3, 0.6])
	sp.append([_mark + planet.up_at(_mark) * 1.3, 0.35])
	sp.append([_mark + planet.up_at(_mark) * 0.2, 0.35])
	var top := -INF
	var bot := INF
	var hw := 0.0
	for s: Array in sp:
		var v3 := (s[0] as Vector3) - eye
		var zh := -v3.dot(b.z)
		if zh < 0.1:
			return []
		var ay := atan2(v3.dot(b.y), zh)
		var ax := atan2(v3.dot(b.x), zh)
		var al := asin(clampf(float(s[1]) / maxf(v3.length(), 0.01), 0.0, 1.0))
		top = maxf(top, ay + al)
		bot = minf(bot, ay - al)
		hw = maxf(hw, maxf(absf(tan(ax + al)), absf(tan(ax - al))))
	var top_y := 0.10
	var bot_y := 0.90
	var ut := 1.0 - 2.0 * top_y
	var ub := 1.0 - 2.0 * bot_y
	var half := (top - bot) / maxf(ut - ub, 0.05)
	var pitch := top - ut * half
	var T := tan(half)
	var T_a := hw / 0.94 / _asp
	if T_a > T:
		T = T_a
		pitch = (top + bot) * 0.5 - (ut + ub) * 0.5 * atan(T)
	var fov := clampf(rad_to_deg(2.0 * atan(T)), 16.0, 60.0)
	return [b.rotated(b.x, pitch), fov]


## A basis at `eye` (level, no roll) that puts `point` at frame position (X, Y) with vertical FOV `fov`.
func _compose(eye: Vector3, point: Vector3, X: float, Y: float, fov: float) -> Basis:
	var up := planet.up_at(eye)
	var tv := tan(deg_to_rad(fov) * 0.5)
	var nx := 2.0 * X / _asp - 1.0
	var ny := 1.0 - 2.0 * Y
	var v := point - eye
	var fh := _tangent(v, up, -_axis)
	var b := Basis.looking_at(fh, up)
	b = Basis.looking_at(-(b.rotated(up, atan(nx * tv * _asp))).z, up)
	var zh := -v.dot(b.z)
	var el := atan2(v.dot(up), maxf(zh, 0.01))
	var pitch := el - atan(ny * tv)
	return b.rotated(b.x, pitch)


func _heads_seen_from_mark() -> bool:
	var eye := _mark + planet.up_at(_mark) * 1.5
	for hd: Dictionary in _heads(_dirs):
		if _sight(eye, hd["c"]) != "":
			return false
	return true


func _open_sight() -> void:
	if _vs == null or not _vs.has_method("open_sight"):
		return
	_vs.call("open_sight", _pad_ground, SIGHT_REACH_M)
	_sight_open = true


func _close_sight() -> void:
	if _sight_open and _vs != null and is_instance_valid(_vs) and _vs.has_method("close_sight"):
		_vs.call("close_sight")
	_sight_open = false


func _sight(a: Vector3, b: Vector3) -> String:
	if not _sight_open:
		return ""
	if _vs == null or not is_instance_valid(_vs):
		_sight_open = false
		return ""
	if not _sight_space_valid():
		# Someone else closed VisitorSystem's single occluder space between two slices of the shot search
		# (MEASURED, K2S: the gift debug entry's FinaleLaunch.apply_end_state -> _pick_side opens and closes
		# it in the frame after the meeting's first slice, and every sight line after that printed
		# "open_sight was never called" - 4,338 warnings - and read as clear). Build it again.
		_vs.call("open_sight", _pad_ground, SIGHT_REACH_M)
		_stats["sight_reopened"] = int(_stats.get("sight_reopened", 0)) + 1
		if not _sight_space_valid():
			_sight_open = false
			return ""
	return str(_vs.call("sight_blocker", a, b))


## Whether VisitorSystem's occluder space is still open. It is a single space shared with FinaleLaunch's
## side pick and VisitorSystem's own spot search, any of which may close it; "_space" is its RID (read by
## name - when the name is gone this trusts `_sight_open`, as before).
func _sight_space_valid() -> bool:
	if _vs == null or not is_instance_valid(_vs):
		return false
	var sp: Variant = _vs.get("_space")
	return not (sp is RID) or (sp as RID).is_valid()


# ============================================================================= warm-up (§7)
func _warm(tag: String) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		await get_tree().process_frame
		cam = get_viewport().get_camera_3d()
	if cam == null or not is_inside_tree():
		return
	var holder := Node3D.new()
	holder.name = "K2Warm"
	cam.add_child(holder)
	var tv := tan(deg_to_rad(cam.fov) * 0.5)
	holder.position = Vector3(0.0, -0.78 * tv, -1.0)
	var mats: Array = []
	if ResourceLoader.exists(ASTEROID_PATH):
		mats.append_array(load(ASTEROID_PATH).call("warm_materials"))
	var launch := load(LAUNCH_PATH) as Script if ResourceLoader.exists(LAUNCH_PATH) else null
	if launch != null:
		mats.append_array(launch.call("warm_materials"))
	var i := 0
	for m: Variant in mats:
		if not (m is Material):
			continue
		var mi := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(0.02, 0.02)
		mi.mesh = q
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		holder.add_child(mi)
		mi.position = Vector3((float(i) - float(mats.size()) * 0.5) * 0.026, 0.0, 0.0)
		i += 1
	var n_nodes := 0
	if launch != null:
		for n: Node3D in launch.call("warm_nodes"):
			holder.add_child(n)
			n.position += Vector3((float(n_nodes) - 2.0) * 0.03, -0.03, 0.0)
			n_nodes += 1
	var u0 := Time.get_ticks_usec()
	for f in WARM_FRAMES:
		await get_tree().process_frame
	if is_instance_valid(holder):
		holder.queue_free()
	_beat("warm %s materials=%d nodes=%d camera=%s frames=%d %.1f ms" % [tag, i, n_nodes, cam.name, WARM_FRAMES, (Time.get_ticks_usec() - u0) / 1000.0])


func _warm_in_first_box() -> void:
	var box := get_tree().get_first_node_in_group("dialogue_box")
	if box == null:
		box = get_tree().root.get_node_or_null(DialogueRunner.BOX_PATH)
	var t := 0.0
	while is_inside_tree() and t < 2.0:
		if box != null and box.has_method("is_open") and bool(box.call("is_open")) and t >= 0.3:
			break
		t += minf(get_process_delta_time(), MAX_STEP)
		await get_tree().process_frame
	if is_inside_tree():
		await _warm("first-box")


# ============================================================================= helpers
static func _tangent(v: Vector3, up: Vector3, fallback: Vector3) -> Vector3:
	var t := v - up * v.dot(up)
	if t.length_squared() < 1e-8:
		t = fallback - up * fallback.dot(up)
	if t.length_squared() < 1e-8:
		t = up.cross(Vector3.RIGHT if absf(up.x) < 0.9 else Vector3.FORWARD)
	return t.normalized()


static func _vec(a: Variant) -> Vector3:
	if not (a is Array) or (a as Array).size() != 3:
		return Vector3.ZERO
	var v := Vector3(float(a[0]), float(a[1]), float(a[2]))
	return v.normalized() if v.length_squared() > 1e-6 else Vector3.ZERO


func _fs() -> Script:
	return load(FINALE_STATE_PATH) as Script if ResourceLoader.exists(FINALE_STATE_PATH) else null


func _fs_call(method: String, args: Array) -> Variant:
	var s := _fs()
	if s == null:
		return null
	return s.callv(method, args)


func _fs_int(method: String) -> int:
	var v: Variant = _fs_call(method, [])
	return int(v) if v != null else 0


func _fs_dict(method: String) -> Dictionary:
	var v: Variant = _fs_call(method, [])
	return v if v is Dictionary else {}


func _log(msg: String) -> void:
	print("FINALE K2 " + msg)


func _beat(msg: String) -> void:
	print("FINALE K2 t=%.2f %s" % [_clock, msg])
	if _trace_on:
		_trace_rows.append("beat t=%.3f %s" % [_clock, msg])
		_flush_trace()


func _flush_trace() -> void:
	if _trace_rows.is_empty():
		return
	var s := _fs()
	if s != null and _trace_on:
		s.call("trace", TRACE_TAG, ("\n" + TRACE_TAG + " ").join(_trace_rows))
	_trace_rows.clear()


# ============================================================================= test hooks
## Live head discs of the crowd as they stand now (for probes): id, centre, radius, vertical extent.
func head_points() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id in _ids:
		var n := npc(id)
		if n == null:
			continue
		var hi: Dictionary = _head_info.get(id, HEAD_DEFAULT)
		var up := planet.up_at(n.global_position)
		out.append({"id": id, "c": n.global_position + up * float(hi["c_h"]), "r": float(hi["r"]), "h": float(hi["h"])})
	return out


## The astronaut's helmet as it stands now, in head_points' shape (id "astronaut"; for probes). Not a crowd
## head: see ASTRO_HEAD.
func astronaut_head_point() -> Dictionary:
	if _player == null or not is_instance_valid(_player) or planet == null:
		return {}
	var pu := planet.up_at(_player.global_position)
	return {"id": "astronaut", "c": _player.global_position + pu * float(ASTRO_HEAD["c_h"]), "r": float(ASTRO_HEAD["r"]), "h": float(ASTRO_HEAD["h"])}


func debug_report(tag: String = "") -> Dictionary:
	var shots := {}
	for key: String in _shots:
		var sh: Dictionary = _shots[key]
		shots[key] = {"ok": sh.get("ok", false), "why": sh.get("why", ""), "fov": sh.get("fov", 0.0), "top": sh.get("top", ""), "n": sh.get("n", 0),
			"fallback_from": sh.get("fallback_from", ""), "split": sh.get("split", {})}
	var d := {"tag": tag, "phase": phase_name(), "stage0": _stage0, "pass": _spot_pass, "axis_k": _axis_k,
		"note": _spot_note, "setup_ms": _stats.get("setup_ms", []), "shots": shots, "rule": _rule,
		"guard_eaten": _guard_eaten, "guard_passed": _guard_passed, "clock_held": _clock_held,
		"cam_current": _cam != null and is_instance_valid(_cam) and _cam.current}
	print("FINALE K2 REPORT %s" % JSON.stringify(d))
	return d
