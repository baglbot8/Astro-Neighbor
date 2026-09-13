class_name PartCelebration
extends Node3D
## THE PART CELEBRATION - the short cutscene each time a rocket part is fitted (docs/CORE_LOOP.md
## "Changed after the build plan": *"When a part is fitted, the camera zooms in on the astronaut
## celebrating, then shows the rocket's new finish."*). world.gd spawns it on home only, as
## /root/World/PartCelebration. It listens for EventBus.rocket_part_fitted, which the build bench
## emits when a part goes in - never on load, so a loaded save never replays it.
##
## THE SHOT, one camera and no cut (the rocket trip's R2.5 rule, kept here too). Measured 6.6-7.3 s
## over six layouts round the pad, 8.0 s at most by construction (CAM_*_MAX); times below are the
## desktop run with the crane at its 1.1 s base - a longer crane pushes every beat after it back:
##   0.0   the camera leaves the gameplay rig and cranes in to a close three-quarter shot of the
##         astronaut from just above helmet height, the planet's horizon arc behind them; they spin
##         round to face it
##   0.85  a big jump with the arms flung up (the model's "jump" pose), a landing squash with the
##         real landing dust and thud
##   1.6   the "happy" cheer: hops with both arms overhead and the model's own sparkles
##   3.1   the astronaut turns away; the camera swings out to the rocket - a two-shot with the
##         astronaut in it where the pad allows one, else the rocket alone from the astronaut's side
##   4.4   THE REVEAL: sparkles run up the hull and the finish steps to its new stage, and the
##         astronaut starts back at it ("surprised")
##   5.7   the camera settles back into the gameplay rig, reseated behind the astronaut; control
##         returns at ~6.7
##
## WHY ITS OWN CAMERA and not CameraRig.focus_on. focus_on is the dialogue two-shot: it pushes in to
## FOCUS_PUSH_IN (0.78) of the follow distance and swings side-on across the line to its focus point.
## On the astronaut alone that is 0.78 x 7.4 = 5.8 m on desktop and 0.78 x 8.6 = 6.7 m on a phone,
## where the 1.45 m astronaut is 1.45 / (2 x 5.8 x tan 22.5) = 30% and 26% of the frame height - the
## gameplay framing, not a close-up. This shot puts them at ~55% (see FOV_A / A_DISTS). A camera of
## its own also means the rig is never left in a focus or orbit state that a skip would have to
## unwind: the rig keeps following the frozen astronaut the whole time and is only REseated, once, at
## the hand-back (CameraRig.reseat_behind_player), which is the same call the landing uses.
##
## THE FINISH REVEAL. GameState.fit_rocket_part has already repainted the hull by the time
## rocket_part_fitted arrives (RocketModel listens to rocket_parts_changed). Parts 1-3 each clean it
## only "a little", so a rocket that is simply cleaner when the camera gets there is easy to miss.
## So the moment the part is fitted the hull is held on its OLD finish (RocketModel.set_finish_stage,
## public for exactly this), and on the rocket shot a burst of sparkles runs up the hull and
## RocketModel.refresh_finish() puts the real stage back - the new finish appears under the sparkle.
## Every exit path calls refresh_finish(), so the hold can never outlive the cutscene. A timeline that
## pins `--rocket-finish=N`, or any run where the story's gates are off, has no before/after
## (the stage does not change) and just shows the rocket.
##
## WHEN IT STARTS. Not on the signal itself: the bench's own panel is probably still open then. It
## waits until nothing modal is open, no scene fade is running, the astronaut is standing on the
## ground and not mid-emote, for SETTLE_SECONDS in a row - then plays.
##
## FREEZE AND MODAL. EventBus.ui_modal_opened("cutscene") locks every hotkey and hides the touch
## controls; exactly one ui_modal_closed("cutscene") follows on EVERY exit path - the end, a skip, and
## _exit_tree. Physics stays on (input off, no velocity) except for the ~2.2 s jump-and-cheer window,
## where this node moves the body and poses the model itself, the way CrashIntro does its hop - see
## `_freeze_player` for why the whole shot cannot run with physics off.
##
## SKIP. Any real key, a real mouse BUTTON (left, right, middle - not the wheel, whose notches are
## InputEventMouseButton presses too, and not a trackpad pan), a touch or a pad button; plus the
## interact / ui_accept / jump / cancel / pause actions, which is the only way a Director timeline's
## `tap` can reach it (Input.action_press emits no InputEvent). A skip fades to navy, puts everything
## where the shot would have left it and fades back. Control is handed back only once the key that
## skipped is let go, so the press that skipped cannot also jump or re-open the bench.
##
## SOUND. AudioManager.play_sfx(PART_SFX) at the start, only if that file exists - the lead generates
## it after this build (STYLE_GUIDE "Sound identity": no mallet jingle). The jump and the landing use
## the player's own jump.wav / land.wav, the sounds every jump already makes.

signal finished(skipped: bool)

enum Phase { IDLE, PENDING, RUNNING, SKIPPING, RELEASING }

const MODAL_NAME := "cutscene"
const PART_SFX := "part_fitted"
const PART_SFX_DB := 0.0
## A rocket_parts_changed this recent (ms) is taken to be the fit that rocket_part_fitted announces,
## so the "before" finish is the one sampled just before it - even if the bench emits a frame later.
const RECENT_CHANGE_MS := 2000

# ------------------------------------------------------------------------------------ timeline
## Seconds the start conditions must hold in a row before the shot begins: long enough for the
## bench panel's close animation and the HUD's chrome fade to finish, short enough to still read as
## the answer to the button press.
const SETTLE_SECONDS := 0.35
## Rig -> close-up crane. The astronaut's spin to face the lens is faster, so they are round before
## the camera arrives.
const CAM_IN_SECONDS := 1.1
const TURN_TO_CAM_SECONDS := 0.45
## The jump starts as the crane is settling (it arrives at CAM_IN_SECONDS), so the camera "catches"
## it rather than waiting for it.
const JUMP_T := 0.85
## AstronautModel._pose_jump squats for its first 0.08 s - the anticipation - before the arms go up.
const JUMP_SQUASH := 0.08
## Airtime and apex of the celebration jump. A real jump (player.gd JUMP_VELOCITY 8.5 m/s against
## 30 m/s^2) tops out at 1.20 m with 0.57 s in the air; this one is lower so the close-up holds the
## raised arms in frame at the apex (see the A_* framing numbers), and a touch quicker.
const JUMP_AIR := 0.52
const JUMP_APEX := 0.55
## The landing squash (AstronautModel._pose_land bottoms out at 0.12 s) plays before the cheer.
const LAND_HOLD := 0.12
const CHEER_EMOTE := "happy"
const REACT_EMOTE := "surprised"
const TURN_TO_ROCKET_SECONDS := 0.5
const CAM_ROCKET_SECONDS := 1.3
## The finish swaps this long after the sparkles start, so the first of them are already on the
## hull and the repaint happens under them rather than as a bare pop.
const REVEAL_SWAP_DELAY := 0.08
const REACT_DELAY := 0.1
## How long the new finish is held on screen before the hand-back starts: long enough for the sparkles
## (SPARKLE_LIFE 1.3 s) to run their course over the new paint.
const REVEAL_HOLD := 1.25
const HANDBACK_SECONDS := 1.0
## A press in the first moments is more likely the tail of the bench click than a request to skip.
const SKIP_ARM_T := 0.4
const SKIP_HINT_T := 0.7
const SKIP_HINT_ALPHA := 0.72
const SKIP_HINT_FADE := 0.4
const SKIP_FADE_OUT := 0.2
const SKIP_FADE_IN := 0.35
## Longest the astronaut is held after the end waiting for the skip key to be let go.
const RELEASE_WAIT_MAX := 1.0
## Longest step the shot clock takes in one frame (CrashIntro MAX_STEP). A load stall - the first
## sight of a new stretch of world compiles shaders - must slow the shot, not jump it: on the first
## desktop run one stalled frame moved the camera 5.8 m and 29 deg at once; headless, where nothing
## compiles, the same path never moved more than 0.8 m in a frame.
const MAX_STEP := 0.05
## `--celebration-trace=<file>` (after "--") writes the rendered camera every frame of the shot, so
## "no cut" can be measured from a run rather than asserted.
const TRACE_ARG := "--celebration-trace="
const SKIP_ACTIONS: PackedStringArray = ["interact", "ui_accept", "jump", "cancel", "pause"]
## Actions that must be up before control returns (see SKIP in the header).
const HOLD_ACTIONS: PackedStringArray = ["interact", "ui_accept", "jump", "boost", "emote"]

# ------------------------------------------------------------------------------------ shot A: the close-up
## Vertical FOV of the close-up. Narrower than the rig's 45 so the move in reads as a zoom as well as
## a dolly. At A_DISTS[0] = 3.6 m the frame is 2 x 3.6 x tan 20 = 2.62 m tall, so the 1.45 m
## astronaut is 55% of it standing, with the jump apex (+0.55 m) and the raised arms still inside.
const FOV_A := 40.0
## The FOV narrows by this much over the cheer: a slow creep in, so the held shot is not dead.
const A_CREEP_FOV := 3.0
## Camera eye and aim heights above the astronaut's feet: a little above the helmet, looking ~12 deg
## down, so the planet's own horizon arc curves away behind the cheer. It started as a low angle (eye
## 0.85, aim 1.0) and the frames looked heroic but measured as mostly sky: on a 12 m world the horizon
## dips ~26 deg from 1.4 m up, so a level eye sees almost nothing but sky past the astronaut. Fifth
## run, whole frame: saturation p90 0.694 and mean 0.504 with the sky navy (#131433, S 0.62) the
## dominant swatch at 37%, against 0.593 / 0.387 for the gameplay frame from the same run and hour -
## the difference was the framing. Checked against the frame limits by hand at 3.6 m: feet at 0.66
## and the jump's raised arms at 0.78 of the half-height, both inside the 0.92 margin.
const A_EYE_H := 1.7
const A_LOOK_H := 0.95
## Share of the jump height the aim follows, like an operator tilting with it.
const A_JUMP_FOLLOW := 0.35
## The astronaut faces the lens turned this far toward the rocket side: a three-quarter, not a mugshot.
const A_FACE_OFF_DEG := 22.0
const A_DISTS: Array[float] = [3.6, 4.3]
## Bearings round the astronaut, measured from where the gameplay camera already is (0 = straight in
## from behind them, which is the shortest camera move).
const A_YAWS: Array[float] = [0.0, 30.0, -30.0, 60.0, -60.0, 95.0, -95.0, 130.0, -130.0, 165.0, -165.0]
## SECOND PASS, only when no eye at A_EYE_H passes: the same bearings from these heights above the
## feet, looking down over whatever stands round the astronaut. Measured, standing in the Fly gateway
## facing the rocket: no eye at A_EYE_H passed, and the pure zoom below put the gateway's plate over
## the helmet for the whole cheer (fallback run, f08-f22). A look down over the plate is the better
## picture of the same moment.
const A_HIGH_EYE_HS: Array[float] = [2.8, 3.6]
## If nothing passes the sight-line tests, the rig's own eye with this FOV: a pure zoom.
const FOV_FALLBACK := 30.0

# ------------------------------------------------------------------------------------ shot B: the rocket
## Camera candidates round the astronaut, measured from straight behind them as they face the rocket.
const B_YAWS: Array[float] = [30.0, -30.0, 45.0, -45.0, 60.0, -60.0, 75.0, -75.0, 90.0, -90.0, 110.0, -110.0]
const B_DISTS: Array[float] = [2.6, 3.4, 4.4, 5.6]
const B_HEIGHTS: Array[float] = [1.5, 2.3]
## The aim sits this far from the astronaut's chest toward the rocket's middle.
const B_AIM_W := 0.62
## The FOV is solved per candidate so the whole 3.2 m rocket is this share of the frame height.
const B_ROCKET_FRAC := 0.56
const FOV_B_MIN := 26.0
const FOV_B_MAX := 46.0
const B_CREEP_FOV := 2.0
## Fallback family: framed on the rocket alone when no two-shot passes - from these distances out, and
## these heights above the rocket's middle. The high ones look DOWN over the pad's posts and sign,
## which is what is left when every level eye is blocked: the fourth run's tightest layout (the
## astronaut 2.6 m from the pad, facing away) passed no level eye at all and showed no rocket.
const SOLO_DISTS: Array[float] = [7.5, 6.0]
## Heights above the rocket's middle, the FIRST being the preferred one (W_SOLO_HIGH costs each metre
## away from it): 2.6 m looks down ~19 deg from 7.5 m out, near the gameplay rig's own 28 deg, so the
## pad deck and the curve of the ground fill the lower frame behind the rocket. A near-level look
## leaves the rocket standing against empty sky: the sixth run's solo shot, 1.2 m above the middle
## (9 deg down), had the sky navy (#131433, S 0.61) as its dominant swatch at 34% of the frame, against
## the "no dominant swatch above S 0.60" gate, where the same run's gameplay frame had none.
const SOLO_HEIGHTS: Array[float] = [2.6, 1.6, 3.8]

# ------------------------------------------------------------------------------------ framing tests
## The narrowest frame the game ships at (1280x720 / 1920x1080). Phones are wider (2.17:1), so a
## candidate that fits 16:9 fits them too - the FOV is vertical.
const FRAME_ASPECT := 16.0 / 9.0
## Everything that must be in frame stays this far inside the edge (in units of the half-height).
const FRAME_MARGIN := 0.08
## Helmet top above the feet (CameraRig.SIGHT_HEIGHTS' top probe) and a half-width that covers the
## arms out.
const ASTRO_TOP := 1.45
const ASTRO_HALF_W := 0.40
## The rocket's silhouette half-width to its fin tips (CrashIntro.SHIP_SIL_R).
const ROCKET_SIL_R := 0.95
## Screen gap wanted between the astronaut and the rocket in the two-shot, in half-height units.
const B_SEPARATION := 0.06
## What can hide the astronaut or the rocket from a candidate eye: terrain (1), NPCs (3),
## decorations and the rocket's own blocker (4), buildings (7). Same layers the player bumps into.
const SIGHT_MASK := 1 | (1 << 2) | (1 << 3) | (1 << 6)
## A candidate eye must sit at least this far above the ground under it.
const CAM_GROUND_CLEAR := 0.45
## Sight-lines must clear the pad's posts, plate, console and mast (which have no colliders) by this.
const MIN_CLEAR := 0.25
## And the mast's silhouette must stand this far off the rocket's, in degrees of view: round 2 of the
## crash intro was failed for a beacon mast skewering the hull on screen.
const MAST_GAP_DEG := 2.5
const MAST_H := 7.9
const MAST_SIL_R := 0.25
## A pad piece (the Fly sign's posts, the console, the mast) standing in frame nearer the lens than
## the subject is a pole across the shot: the first run's close-up had a Fly sign post down its right
## edge the whole time, and its rocket shot had the 7.9 m mast as a giant stripe in front. In frame
## and nearer than this: rejected. Further: penalised by its angular width (W_FOREGROUND).
const FOREGROUND_REJECT_M := 4.0
## Any pad piece in frame within this distance of the lens - in front of the subject or behind it -
## costs W_CLUTTER by its angular width. The second run's close-up had a Fly sign post 5-6 m away,
## BEHIND the astronaut, standing as a leaning orange pole through the right third of every frame.
const CLUTTER_DEPTH_M := 8.0
## The camera's path keeps this far from the rocket's axis (its fins reach 0.95 m) and from each pad
## piece's surface. At 0.8 m the second run's move to the rocket shot still swept the console past
## the lens as a pillar filling half the frame (f35).
const ROCKET_KEEP_M := 1.8
const OBSTACLE_KEEP_M := 1.4
## Camera moves take at least their base time, and longer when the path is long or the view turns a
## long way: at most this average speed and turn rate (smootherstep peaks at 1.875x the average).
## Measured on the second run with a fixed 1.0 s hand-back: 40 m/s and 264 deg/s at its peak, a whip.
const CAM_AVG_SPEED := 5.5
const CAM_AVG_TURN_DEG := 70.0
## Longest any single move may take. With every one of them maxed the shot is 8.0 s long - the top
## of the brief's "about 5-8 s"; the third run's layout, with the old 1.5 / 1.8 / 1.8 caps, ran 8.35.
## The crane-in gets the most room: on a phone it starts from the rig's 8.6 m / 34 deg framing, and at
## 1.4 s the fifth run's phone crane-in hit its cap and peaked at 18.8 m/s and 181 deg/s.
const CAM_IN_MAX := 1.6
const CAM_ROCKET_MAX := 1.6
const HANDBACK_MAX := 1.6
## Solo rocket shots stay on the astronaut's side of the rocket, within this bearing of the line from
## the rocket to them, so the hand-back behind the astronaut is short. The second run's solo shot sat
## across the rocket from them and the hand-back had to fly ~20 m round it. For the same reason the
## astronaut, in a solo shot, turns to look the way the camera looks (not straight at the rocket):
## the rig is then reseated right behind that view. With them facing the rocket instead, the fourth
## run's hand-back still peaked at 22 m/s and 151 deg/s.
const SOLO_BEARINGS: Array[float] = [0.0, 25.0, -25.0, 50.0, -50.0, 75.0, -75.0]
## A solo eye this close to the astronaut would be inside or grazing their helmet.
const SOLO_ASTRO_KEEP_M := 1.6
## Nothing may stand behind or in front of the astronaut's silhouette in the close-up - no pad post
## or hull "growing out of" the helmet. Measured in half-height units either side of their outline.
## The third run's close-up had a Fly sign post rising straight out of the helmet for its whole hold.
const SUBJECT_MARGIN := 0.10

# ------------------------------------------------------------------------------------ scoring weights
## Unitless preferences, all against the same scale (1.0 = "worth a 180 deg camera move").
const W_TRAVEL := 1.0
const W_TURN := 0.35
const W_DIST := 0.25
const W_SUN := 0.25
const W_ROCKET_BG := 0.2
const W_B_TRAVEL := 0.8
const W_B_FRAC := 1.5
const W_B_SOLO := 1.2
## Per 10 degrees of view taken up by a pad piece in front of the subject.
const W_FOREGROUND := 0.3
## Per 10 degrees of view taken up by any pad piece in frame within CLUTTER_DEPTH_M. Heavier on the
## close-up, where the astronaut is the whole picture; lighter on the rocket shot, where the pad is
## the rocket's own setting.
const W_CLUTTER_A := 0.5
const W_CLUTTER_B := 0.15
## Per second of camera move time, on the rocket shot's two moves.
const W_MOVE_TIME := 0.3
## A solo rocket shot that cuts the astronaut in half at the frame edge.
const W_EDGE_CUT := 0.6
## Per metre a solo eye sits away from the preferred height (SOLO_HEIGHTS[0]), up or down.
const W_SOLO_HIGH := 0.12
## Per metre a second-pass close-up eye sits above A_EYE_H.
const W_A_HIGH := 0.15

# ------------------------------------------------------------------------------------ reveal sparkles
const SPARKLE_COUNT := 40
const SPARKLE_LIFE := 1.3
const SPARKLE_SIZE := 0.17
## Cream, not white: a pure white star is a blown pixel on every frame it is in (QUALITY_BAR blown
## highlights < 5%), and cream is the colour the model's own "happy" sparkles and the dust use.
const SPARKLE_COLOR := Color(1.0, 0.95, 0.82)
const HINT_LAYER := 95

var _phase: int = Phase.IDLE
var _t := 0.0
var _wait := 0.0
var _release_t := 0.0
var _skipped := false
var _modal := false
var _revealed := true
var _reseated := false
## True once the reaction was started through Player.play_emote: that emote must be left to end by
## itself, or player.gd's emote watchdog prints a warning when it never reports finishing.
var _reacted := false
var _fired: Dictionary = {}
var _skip_held: Dictionary = {}
var _skip_primed := false
var _part_id := ""

## Finish bookkeeping (see THE FINISH REVEAL). `_last_stage` is sampled every idle frame, so at the
## moment a part is fitted it still holds the stage painted before the fit.
var _last_stage := -1
var _stage_before_change := -1
var _change_ms := -1
var _from_stage := -1
var _to_stage := -1

# scene pieces, resolved at the start of each run
var _player: Player
var _model: AstronautModel
var _rig: CameraRig
var _planet: Planet
var _rocket: RocketModel
var _env: Node
var _cam: Camera3D
var _prev_cam: Camera3D
var _space: PhysicsDirectSpaceState3D

# geometry, fixed at the start of each run
var _p0 := Vector3.ZERO
var _up := Vector3.UP
var _face0 := Vector3.FORWARD
var _face_a := Vector3.FORWARD
var _face_end := Vector3.FORWARD
var _u := Vector3.FORWARD
var _sun := Vector3.ZERO
var _has_rocket := false
var _rocket_base := Vector3.ZERO
var _rocket_up := Vector3.UP
var _rocket_mid := Vector3.ZERO
var _rocket_top := Vector3.ZERO
var _obstacles: Array = []
var _has_mast := false
var _mast_base := Vector3.ZERO
var _mast_top := Vector3.ZERO
var _c0 := Transform3D.IDENTITY
var _c0_look := Vector3.ZERO
var _fov0 := 45.0
var _a_eye := Vector3.ZERO
var _a_fov := FOV_A
var _a_ok := false
var _a_best := -INF
var _b_eye := Vector3.ZERO
var _b_aim := Vector3.ZERO
var _b_fov := FOV_B_MAX
var _has_b := false
var _b_solo := false
## The rocket shot is levelled to the planet's up at its aim, not the astronaut's: on a 12 m world
## the rocket stands ~20 deg round the curve from someone 4.5 m away, and the first run's rocket shot,
## levelled to the astronaut, showed the rocket leaning 20 deg with the horizon slanted.
var _b_up := Vector3.UP
## Where the rig's eye will be once reseated behind the astronaut facing `_face_end` (predicted).
var _rig_after := Vector3.ZERO
## Why candidates failed, per test (logged; see `_count`).
var _reject: Dictionary = {}

# schedule, from the model's emote lengths and the solved camera paths
var _cam_in_s := CAM_IN_SECONDS
var _cam_rocket_s := CAM_ROCKET_SECONDS
var _handback_s := HANDBACK_SECONDS
## How much later than JUMP_T the astronaut's beats run because the crane-in took longer than its
## base time: the jump always waits for the camera to be nearly there.
var _shift := 0.0
var _t_jump := 0.0
var _t_land := 0.0
var _t_cheer := 0.0
var _t_turn := 0.0
var _t_reveal := 0.0
var _t_handback := 0.0
var _t_end := 0.0

# measurement (see `_track_camera`)
var _last_xf := Transform3D.IDENTITY
var _last_fov := 45.0
var _have_last := false
var _max_step_m := 0.0
var _max_step_deg := 0.0
var _max_step_fov := 0.0
var _max_speed := 0.0
var _max_ang_speed := 0.0
var _trace: FileAccess
var _trace_frame := 0

# persistent nodes
var _burst: GPUParticles3D
var _hint_layer: CanvasLayer
var _hint_root: Control
var _hint_pill: PanelContainer
var _hint_alpha := 0.0


func _ready() -> void:
	# After the Director (an autoload, so earlier in tree order at the same priority) and before the
	# camera rig (10): a timeline `tap` pressed in the Director's _process this frame is still down
	# when `_poll_skip_actions` reads it here.
	process_priority = 1
	EventBus.rocket_part_fitted.connect(_on_part_fitted)
	EventBus.rocket_parts_changed.connect(_on_parts_changed)
	_burst = _make_sparkles()
	add_child(_burst)
	_build_skip_hint()


func _exit_tree() -> void:
	# Leaving mid-shot (a quit, a scene change): never leave the menus locked, the astronaut frozen,
	# the view on a camera that is about to be freed, or the rocket on its old finish. Children leave
	# the tree before this runs, so the camera's transform is not read here (no hand-back gap log).
	if _phase == Phase.RUNNING or _phase == Phase.SKIPPING or _phase == Phase.RELEASING:
		_drop_camera(false)
		_thaw_player()
		_end_modal()
	if _rocket != null and is_instance_valid(_rocket) and not _revealed:
		_rocket.refresh_finish()
	if _trace != null:
		_trace.close()
		_trace = null
	_phase = Phase.IDLE


# ============================================================================= trigger
func _on_parts_changed(_count: int) -> void:
	# `_last_stage` was sampled last frame, before this change repainted the hull.
	_stage_before_change = _last_stage
	_change_ms = Time.get_ticks_msec()


func _on_part_fitted(part_id: String) -> void:
	var rocket := _find_rocket()
	var to_stage := rocket.finish_stage() if rocket != null else -1
	_part_id = part_id
	_to_stage = to_stage
	if _phase == Phase.IDLE:
		# The stage from before the fit: the one sampled just before rocket_parts_changed if that came
		# recently (the bench fits, then emits), else the one sampled last frame.
		var recent := _change_ms >= 0 and Time.get_ticks_msec() - _change_ms < RECENT_CHANGE_MS
		_from_stage = _stage_before_change if recent else _last_stage
		_fired.clear()
		_phase = Phase.PENDING
		_wait = 0.0
	# A second part fitted while one celebration is pending or playing merges into it: one shot, and
	# the reveal shows the newest finish.
	_log("part fitted: %s (finish %d -> %d)%s" % [part_id, _from_stage, to_stage,
		"" if _phase == Phase.PENDING else " - merged into the running celebration"])
	if rocket != null and not _fired.has("swap") and _from_stage >= 0 and _from_stage != to_stage:
		rocket.set_finish_stage(_from_stage)
		_revealed = false


func _can_start() -> bool:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Player
	if _player == null or not _player.is_inside_tree() or not _player.visible:
		return false
	if get_tree().paused or EventBus.is_modal_open() or SceneRouter.is_busy():
		return false
	# Frozen by someone else (the pad's own cutscenes) or mid-dialogue: wait for them to finish.
	if not _player.is_physics_processing() or not _player.input_enabled:
		return false
	if not _player.is_on_floor():
		return false
	# An emote in flight would never report finishing once this takes the model over, and player.gd's
	# watchdog would then print a warning when control came back. They are all under 3 s.
	var model := _player.get_model()
	if model != null and AstronautModel.EMOTE_DURATIONS.has(model.get_state()):
		return false
	return true


# ============================================================================= per frame
func _process(delta: float) -> void:
	_update_hint(delta)
	match _phase:
		Phase.IDLE:
			var rocket := _find_rocket()
			if rocket != null:
				_last_stage = rocket.finish_stage()
		Phase.PENDING:
			if _can_start():
				_wait += delta
				if _wait >= SETTLE_SECONDS:
					_begin()
			else:
				_wait = 0.0
		Phase.RUNNING:
			_poll_skip_actions()
			if _phase != Phase.RUNNING:
				return
			var dt := minf(delta, MAX_STEP)
			_t += dt
			if _t >= _t_end:
				_finish(false)
				return
			_step(dt)
		Phase.SKIPPING:
			pass
		Phase.RELEASING:
			_release_t += delta
			if not _hold_keys_down() or _release_t >= RELEASE_WAIT_MAX:
				_release()


func _step(delta: float) -> void:
	var t := _t
	_update_astronaut(t)
	_update_events(t)
	_place_camera(t, delta)


# ============================================================================= begin
func _begin() -> void:
	_player = get_tree().get_first_node_in_group("player") as Player
	_model = _player.get_model() if _player != null else null
	_rig = get_node_or_null("/root/World/CameraRig") as CameraRig
	_planet = get_node_or_null("/root/World/Planet") as Planet
	_env = get_node_or_null("/root/World/Environment")
	_rocket = _find_rocket()
	_prev_cam = get_viewport().get_camera_3d()
	if _player == null or _model == null or _planet == null or _prev_cam == null:
		# Nothing to stage it with: show the real finish and let the moment pass rather than freeze.
		_log("a piece of the world is missing (player/model/planet/camera); no celebration")
		if _rocket != null:
			_rocket.refresh_finish()
		_revealed = true
		_phase = Phase.IDLE
		return
	_p0 = _player.global_position
	_up = _player.up.normalized()
	_face0 = _player.surface_forward()
	_has_rocket = _rocket != null
	if _has_rocket:
		_rocket_base = _rocket.global_position
		_rocket_up = _rocket.global_basis.y.normalized()
		_rocket_mid = _rocket_base + _rocket_up * (RocketModel.TOTAL_HEIGHT * 0.5)
		_rocket_top = _rocket_base + _rocket_up * RocketModel.TOTAL_HEIGHT
		_u = _tangent(_rocket_mid - _p0, _up, _face0)
	else:
		_u = _face0
	_face_end = _u
	_sun = Vector3.ZERO
	if _env != null and _env.has_method("get_sun_direction"):
		_sun = (_env.call("get_sun_direction") as Vector3).normalized()
	var t0 := Time.get_ticks_usec()
	_solve_shots()
	_schedule()
	_log("begin part=%s finish %d -> %d; close-up %s fov %.0f; rocket shot %s fov %.1f; ends at %.2f s (solved in %.1f ms)" % [
		_part_id, _from_stage, _to_stage,
		"ok" if _a_ok else "FALLBACK (rig eye)", _a_fov,
		("solo" if _b_solo else "two-shot") if _has_b else "NONE", _b_fov, _t_end,
		float(Time.get_ticks_usec() - t0) / 1000.0])
	_log("candidates rejected, by test: %s" % str(_reject))
	for a in OS.get_cmdline_user_args():
		if a.begins_with(TRACE_ARG):
			_trace = FileAccess.open(a.substr(TRACE_ARG.length()), FileAccess.WRITE)
			if _trace != null:
				_trace.store_line("frame,t,dt,px,py,pz,qx,qy,qz,qw,fov")
				_trace_frame = 0

	_modal = true
	EventBus.ui_modal_opened.emit(MODAL_NAME)
	_freeze_player()
	_cam = Camera3D.new()
	_cam.name = "CelebrationCamera"
	_cam.fov = _fov0
	_cam.near = _prev_cam.near
	_cam.far = _prev_cam.far
	_cam.cull_mask = _prev_cam.cull_mask
	# No attributes of its own: the WorldEnvironment's (environment.gd `_cam_attr`) apply, exactly as
	# they do to the rig's camera, so this shot is lit and focused the way gameplay is.
	add_child(_cam)
	_cam.global_transform = _c0
	_cam.current = true
	_keep_rocket_solid()
	_have_last = false
	_max_step_m = 0.0
	_max_step_deg = 0.0
	_max_step_fov = 0.0
	_max_speed = 0.0
	_max_ang_speed = 0.0
	_t = 0.0
	_fired.clear()
	_skip_held.clear()
	_skip_primed = false
	_skipped = false
	_reseated = false
	_reacted = false
	_phase = Phase.RUNNING
	if AudioManager.sfx_exists(PART_SFX):
		AudioManager.play_sfx(PART_SFX, PART_SFX_DB, 0.0)
	_step(0.0)


func _schedule() -> void:
	var pivot := _p0 + _up * CameraRig.PIVOT_HEIGHT
	_cam_in_s = _move_seconds(_c0.origin, _a_eye, _c0_look, _p0 + _up * A_LOOK_H, CAM_IN_SECONDS, CAM_IN_MAX)
	_shift = _cam_in_s - CAM_IN_SECONDS
	_t_jump = JUMP_T + _shift
	_t_land = _t_jump + JUMP_SQUASH + JUMP_AIR
	_t_cheer = _t_land + LAND_HOLD
	_t_turn = _t_cheer + AstronautModel.get_emote_duration(CHEER_EMOTE)
	if _has_b:
		_cam_rocket_s = _move_seconds(_a_eye, _b_eye, _p0 + _up * A_LOOK_H, _b_aim, CAM_ROCKET_SECONDS, CAM_ROCKET_MAX)
		_handback_s = _move_seconds(_b_eye, _rig_after, _b_aim, pivot, HANDBACK_SECONDS, HANDBACK_MAX)
		_t_reveal = _t_turn + _cam_rocket_s
		_t_handback = _t_reveal + REVEAL_HOLD
	else:
		# No rocket shot: the finish changes as the cheer ends, and the camera goes straight home.
		_handback_s = _move_seconds(_a_eye, _rig_after, _p0 + _up * A_LOOK_H, pivot, HANDBACK_SECONDS, HANDBACK_MAX)
		_t_reveal = _t_turn
		_t_handback = _t_turn + TURN_TO_ROCKET_SECONDS
	_t_end = _t_handback + _handback_s


## How long a camera move from eye `e0` (looking at `l0`) to `e1` (looking at `l1`) should take: its
## base time, or longer if its arc is long or its view turns far (CAM_AVG_SPEED / CAM_AVG_TURN_DEG),
## capped at `cap`.
func _move_seconds(e0: Vector3, e1: Vector3, l0: Vector3, l1: Vector3, base: float, cap: float) -> float:
	# Both summed ALONG the path `_place_camera` flies (the arc, with the aim lerped): comparing only the
	# two end directions under-counted the turn of a move that swings round the astronaut while its aim
	# slides, and the fifth run's phone crane-in peaked at 181 deg/s against an estimate half that.
	var length := 0.0
	var turn := 0.0
	var prev_e := e0
	var prev_d := (l0 - e0).normalized()
	for i in range(1, 13):
		var k := float(i) / 12.0
		var e := _arc(e0, e1, k)
		var d := (l0.lerp(l1, k) - e).normalized()
		length += e.distance_to(prev_e)
		turn += rad_to_deg(prev_d.angle_to(d))
		prev_e = e
		prev_d = d
	return clampf(maxf(length / CAM_AVG_SPEED, turn / CAM_AVG_TURN_DEG), base, maxf(cap, base))


# ============================================================================= the astronaut
## Deaf to input (the "cutscene" modal already clears Player.input_enabled; this makes it explicit),
## standing still. PHYSICS STAYS ON except for the jump-and-cheer window (`_t_jump` to `_t_turn`,
## ~2.2 s of shot time), because event_bus.gd's stuck-player watchdog restores any player whose
## physics has been off for 12 s of WALL time. The first build switched physics off for the whole
## shot and the third run tripped it: 8.35 s of shot time plus 55 load-stall frames came to more
## than 12 s of wall time, and the watchdog handed the astronaut back mid-shot. With input off and
## no velocity, physics simply keeps them standing where they are, and its `_select_state` shows
## "idle", which is what the turns want. Inside the window this node owns the body and the model
## (the jump arc, "jump", "land", the cheer); the reaction later goes through Player.play_emote,
## which `_select_state` respects. The player's own _process keeps ticking the model throughout.
func _freeze_player() -> void:
	_player.input_enabled = false
	_player.velocity = Vector3.ZERO
	_model.set_state("idle")


## THE ROCKET MUST NOT BE A GHOST AT ITS OWN REVEAL. CameraRig fades any decoration-layer body standing
## between ITS camera and the astronaut to 90% transparent (camera_rig.gd FADE_TO), and the rocket's
## blocker is on that layer (rocket_model.gd `_build_collision`). The rig keeps following the astronaut
## through this whole shot, so with the part fitted while the rocket stood between the gameplay camera
## and the astronaut, the rocket stayed a ghost right through the reveal: measured on the 2.6 m layout
## (astronaut facing away from the pad), frames f08-f36, solid again only at f37 once the hand-back had
## reseated the rig. So the rig is reseated here behind the astronaut AS IF they faced the rocket -
## which puts the rocket beyond them, outside every sight line the rig probes - while nothing looks
## through it (this shot's camera is already current); its fade lets go at FADE_OUT_RATE, about 0.3 s,
## under the crane-in. The astronaut's facing is put straight back, and `_update_astronaut` starts the
## turn from `_face0`, so nothing on screen moves. Only the rocket is protected this way: any other
## prop the rig fades still fades - see needs_from_others in the Phase 2 report (a rig API to suspend
## the fade for a cutscene would cover them all).
func _keep_rocket_solid() -> void:
	if _rig == null or not is_instance_valid(_rig) or not _has_rocket:
		return
	_player.global_transform = Transform3D(Basis.looking_at(_u, _up), _p0)
	_rig.reseat_behind_player()
	_player.global_transform = Transform3D(Basis.looking_at(_face0, _up), _p0)


func _thaw_player() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	_player.velocity = Vector3.ZERO
	_player.set_physics_process(true)
	_player.input_enabled = not EventBus.is_modal_open()


func _update_astronaut(t: float) -> void:
	var face: Vector3
	if t < _t_turn:
		face = _turn(_face0, _face_a, _ease(clampf(t / TURN_TO_CAM_SECONDS, 0.0, 1.0)))
	else:
		face = _turn(_face_a, _face_end, _ease(clampf((t - _t_turn) / TURN_TO_ROCKET_SECONDS, 0.0, 1.0)))
	_player.global_transform = Transform3D(Basis.looking_at(face, _up), _p0 + _up * _jump_h(t))


## Height of the feet above the start point: a parabola over JUMP_AIR, after the squat.
func _jump_h(t: float) -> float:
	var x := (t - _t_jump - JUMP_SQUASH) / JUMP_AIR
	if x <= 0.0 or x >= 1.0:
		return 0.0
	return 4.0 * JUMP_APEX * x * (1.0 - x)


func _update_events(t: float) -> void:
	if t >= _t_jump and _once("jump"):
		# The window opens: from here to `_t_turn` this node moves the body by hand (the arc), so the
		# physics step must not add gravity to it or re-pick the model's pose.
		_player.set_physics_process(false)
		_player.velocity = Vector3.ZERO
		_model.set_state("jump")
	if t >= _t_jump + JUMP_SQUASH and _once("liftoff"):
		_sfx("jump", -4.0)
	if t >= _t_land and _once("land"):
		_model.set_state("land")
		# The player's own landing puff (player.gd `_build_dust`, one-shot, world-space), so this lands
		# exactly like every other jump in the game.
		var dust := _player.get_node_or_null("DustLand") as GPUParticles3D
		if dust != null:
			dust.restart()
			dust.emitting = true
		_sfx("land", -6.0)
	if t >= _t_cheer and _once("cheer"):
		_model.set_state(CHEER_EMOTE)
	if t >= _cam_in_s and _once("measure_a"):
		_measure("close-up")
	if t >= _t_turn and _once("turn"):
		_model.set_state("idle")
		_player.global_transform = Transform3D(Basis.looking_at(_face_a, _up), _p0)
		_player.velocity = Vector3.ZERO
		_player.set_physics_process(true)
	if t >= _t_reveal and _once("reveal"):
		if _has_rocket:
			_burst.visible = true
			_burst.global_transform = Transform3D(_rocket.global_basis.orthonormalized(), _rocket_mid)
			_burst.restart()
			_burst.emitting = true
		_measure("rocket shot")
	if t >= _t_reveal + REVEAL_SWAP_DELAY and _once("swap"):
		if _has_rocket:
			_rocket.refresh_finish()
		_revealed = true
	if _has_b and t >= _t_reveal + REACT_DELAY and _once("react"):
		# Through the player, so physics' `_select_state` holds it and the emote ends itself (it asks the
		# rig for its emote orbit too, which nobody sees - this shot's camera is current - and which the
		# reseat at the hand-back cancels).
		_player.play_emote(REACT_EMOTE)
		_reacted = true
	if t >= _t_handback and _once("reseat"):
		# The astronaut has held `_face_end` since _t_turn + TURN_TO_ROCKET_SECONDS (the rocket in a
		# two-shot, the camera's own view in a solo shot); the rig snaps in behind that facing now, while
		# nothing is looking through it, and the hand-back below blends onto it.
		if _rig != null:
			_rig.reseat_behind_player()
		_reseated = true


# ============================================================================= the camera
func _place_camera(t: float, dt: float) -> void:
	var eye: Vector3
	var look: Vector3
	var fov: float
	var upv := _up
	var fov_a_end := _a_fov - (A_CREEP_FOV if _a_ok else 0.0)
	if t < _cam_in_s:
		var k := _ease(t / _cam_in_s)
		eye = _arc(_c0.origin, _a_eye, k)
		look = _c0_look.lerp(_a_look(t), k)
		fov = lerpf(_fov0, _a_fov, k)
	elif t < _t_turn:
		eye = _a_eye
		look = _a_look(t)
		fov = _a_fov - (A_CREEP_FOV if _a_ok else 0.0) * smoothstep(_cam_in_s, _t_turn, t)
	elif _has_b and t < _t_reveal:
		var k2 := _ease((t - _t_turn) / _cam_rocket_s)
		eye = _arc(_a_eye, _b_eye, k2)
		look = _a_look(t).lerp(_b_aim, k2)
		fov = lerpf(fov_a_end, _b_fov, k2)
		upv = _up.slerp(_b_up, k2)
	elif _has_b and t < _t_handback:
		eye = _b_eye
		look = _b_aim
		fov = _b_fov - B_CREEP_FOV * smoothstep(_t_reveal, _t_handback, t)
		upv = _b_up
	else:
		# THE HAND-BACK, onto the rig's LIVE camera: it has just been reseated behind the astronaut and
		# is settling, so the target is re-read every frame, and the last frames slerp onto its exact
		# basis so the switch at the end is invisible (measured in `_drop_camera`). The rig levels
		# itself to the astronaut's up, so the roll reference eases back to that too.
		var from_eye := _b_eye if _has_b else _a_eye
		var from_look := _b_aim if _has_b else _a_look(t)
		var from_fov := (_b_fov - B_CREEP_FOV) if _has_b else fov_a_end
		var rc := _target_camera()
		var k3 := _ease(clampf((t - _t_handback) / _handback_s, 0.0, 1.0))
		var rig_eye := rc.global_position
		var rig_fwd := -rc.global_basis.z
		var rig_look := rig_eye + rig_fwd * maxf((_p0 + _up * CameraRig.PIVOT_HEIGHT).distance_to(rig_eye), 1.0)
		eye = _arc(from_eye, rig_eye, k3)
		look = from_look.lerp(rig_look, k3)
		fov = lerpf(from_fov, rc.fov, k3)
		upv = (_b_up if _has_b else _up).slerp(_up, k3)
		var xf := _look_xf(eye, look, upv)
		var snap := smoothstep(0.7, 1.0, k3)
		var q := xf.basis.get_rotation_quaternion().slerp(rc.global_basis.get_rotation_quaternion(), snap)
		_apply_camera(Transform3D(Basis(q), eye.lerp(rig_eye, snap)), fov, dt)
		return
	_apply_camera(_look_xf(eye, look, upv), fov, dt)


func _apply_camera(xf: Transform3D, fov: float, dt: float) -> void:
	_cam.global_transform = xf
	_cam.fov = fov
	_track_camera(xf, fov, dt)


## Aim of the close-up at time `t`: the chest, tilting a share of the way up with the jump.
func _a_look(t: float) -> Vector3:
	return _p0 + _up * (A_LOOK_H + A_JUMP_FOLLOW * _jump_h(t))


## The camera the hand-back lands on: the rig's, or whatever was current before the shot.
func _target_camera() -> Camera3D:
	if _rig != null and is_instance_valid(_rig) and _rig.get_camera() != null:
		return _rig.get_camera()
	return _prev_cam


func _drop_camera(log_gap: bool = true) -> void:
	var rc := _target_camera()
	if log_gap and _cam != null and is_instance_valid(_cam) and rc != null and is_instance_valid(rc):
		# The gap between the last frame this shot drew and the first the rig will: ~0 on a normal end.
		_log("hand-back gap: %.3f m, %.2f deg, fov %.2f" % [_cam.global_position.distance_to(rc.global_position),
			rad_to_deg(_cam.global_basis.get_rotation_quaternion().angle_to(rc.global_basis.get_rotation_quaternion())),
			absf(_cam.fov - rc.fov)])
	if rc != null and is_instance_valid(rc) and rc.is_inside_tree():
		rc.current = true
	if _cam != null and is_instance_valid(_cam):
		_cam.current = false
		_cam.queue_free()
	_cam = null


# ============================================================================= shot solving
## Picks the close-up (A) and the rocket shot (B) for where the astronaut and the rocket actually are,
## instead of assuming a layout: the bench, the pad, the dome and whatever the player has placed can
## be anywhere round the crash site. Each candidate is tested against the physics world (terrain,
## NPCs, decorations, the rocket, buildings) and the pad's collider-less posts and mast, then scored.
func _solve_shots() -> void:
	_space = get_world_3d().direct_space_state
	_obstacles = _pad_obstacles()
	_c0 = _prev_cam.global_transform
	_fov0 = _prev_cam.fov
	var pivot := _p0 + _up * CameraRig.PIVOT_HEIGHT
	_c0_look = _c0.origin - _c0.basis.z * maxf(pivot.distance_to(_c0.origin), 1.0)
	var rig_bearing := _tangent(_c0.origin - _p0, _up, -_face0)
	var sun_t := _tangent(_sun, _up, Vector3.ZERO) if _sun != Vector3.ZERO else Vector3.ZERO
	_rig_after = _rig_after_for(_face_end)
	_reject.clear()

	# ---- A: the close-up
	_a_ok = false
	_a_best = -INF
	var n_ok := 0
	for dist: float in A_DISTS:
		for yaw: float in A_YAWS:
			if _a_try(rig_bearing.rotated(_up, deg_to_rad(yaw)), dist, A_EYE_H, absf(yaw), sun_t, 0.0, "a_"):
				n_ok += 1
	if not _a_ok:
		for eye_h: float in A_HIGH_EYE_HS:
			for dist: float in A_DISTS:
				for yaw: float in A_YAWS:
					if _a_try(rig_bearing.rotated(_up, deg_to_rad(yaw)), dist, eye_h, absf(yaw), sun_t,
							W_A_HIGH * (eye_h - A_EYE_H), "a_high_"):
						n_ok += 1
	if _a_ok:
		_a_fov = FOV_A
	else:
		# Nothing clear: stay on the rig's own eye (the rig already keeps the astronaut in view) and
		# zoom with the lens alone.
		_a_eye = _c0.origin
		_a_fov = FOV_FALLBACK
		_face_a = _face_for(rig_bearing)
	_log("close-up: %d candidates pass" % n_ok)

	# ---- B: the rocket
	_has_b = false
	_b_solo = false
	if not _has_rocket:
		return
	var best := -INF
	n_ok = 0
	var a_bearing := _tangent(_a_eye - _p0, _up, rig_bearing)
	var aim := (_p0 + _up * A_LOOK_H).lerp(_rocket_mid, B_AIM_W)
	for dist: float in B_DISTS:
		for h: float in B_HEIGHTS:
			for yaw: float in B_YAWS:
				var dir := (-_u).rotated(_up, deg_to_rad(yaw))
				var eye := _p0 + dir * dist + _up * h
				var res := _b_eval(eye, aim, true)
				if res.is_empty():
					continue
				n_ok += 1
				var score: float = float(res["score"]) - _b_travel_cost(a_bearing, eye, res)
				if score > best:
					best = score
					_b_eye = eye
					_b_aim = aim
					_b_fov = res["fov"]
					_has_b = true
	# The rocket alone, round the rocket on the astronaut's side of it: for an astronaut too far from
	# it (or too boxed in) for a two-shot. Scored lower, so it only wins when the two-shot cannot.
	var toward := _tangent(_p0 - _rocket_base, _rocket_up, -_u)
	for dist_r: float in SOLO_DISTS:
		for h_r: float in SOLO_HEIGHTS:
			for bearing: float in SOLO_BEARINGS:
				var dir_r := toward.rotated(_rocket_up, deg_to_rad(bearing))
				var eye_r := _rocket_mid + dir_r * dist_r + _rocket_up * h_r
				if _axis_dist(eye_r, _p0, _up, ASTRO_TOP) < SOLO_ASTRO_KEEP_M:
					_count("solo_astro_near")
					continue
				var res_r := _b_eval(eye_r, _rocket_mid, false)
				if res_r.is_empty():
					continue
				n_ok += 1
				var score_r: float = float(res_r["score"]) - W_B_SOLO - W_SOLO_HIGH * absf(h_r - SOLO_HEIGHTS[0]) \
					- _b_travel_cost(a_bearing, eye_r, res_r)
				if score_r > best:
					best = score_r
					_b_eye = eye_r
					_b_aim = _rocket_mid
					_b_fov = res_r["fov"]
					_has_b = true
					_b_solo = true
	if _has_b:
		_b_up = _planet.dir_of(_b_aim)
		if _b_solo:
			_face_end = _tangent(_b_aim - _b_eye, _up, _u)
	_rig_after = _rig_after_for(_face_end)
	_log("rocket shot: %d candidates pass" % n_ok)


## Tests one close-up eye - `dist` out along `dir` from the astronaut, `eye_h` above their feet - and
## keeps it in `_a_eye` if it passes and beats the best so far. `yaw_abs` is how far round from the
## gameplay camera it sits (degrees), `penalty` any extra cost, `tag` the prefix its failures are
## counted under. Returns whether it passed.
func _a_try(dir: Vector3, dist: float, eye_h: float, yaw_abs: float, sun_t: Vector3, penalty: float, tag: String) -> bool:
	var eye := _p0 + dir * dist + _up * eye_h
	if not _eye_ok(eye):
		_count(tag + "eye")
		return false
	if not _astro_visible(eye, true):
		_count(tag + "sight")
		return false
	if not _arc_ok(_c0.origin, eye):
		_count(tag + "path")
		return false
	if not _a_frames(eye):
		_count(tag + "frame")
		return false
	var a_xf := _look_xf(eye, _p0 + _up * A_LOOK_H)
	# The subject's real distance, not the flat one: from a second-pass eye above them it is longer.
	var fg := _foreground(a_xf, FOV_A, eye.distance_to(_p0 + _up * A_LOOK_H), true)
	if fg < 0.0:
		_count(tag + "foreground")
		return false
	if _crosses_subject(a_xf, FOV_A):
		_count(tag + "behind_head")
		return false
	var face := _face_for(dir)
	var score := -W_TRAVEL * yaw_abs / 180.0 \
		- W_TURN * rad_to_deg(absf(_signed_angle(_face0, face))) / 180.0 \
		- W_DIST * (dist - A_DISTS[0]) + W_SUN * dir.dot(sun_t) - W_FOREGROUND * fg \
		- W_CLUTTER_A * _clutter(a_xf, FOV_A) - penalty
	if _has_rocket and _rocket_in_frame(a_xf, FOV_A, _rocket_mid):
		score += W_ROCKET_BG
	if score > _a_best:
		_a_best = score
		_a_eye = eye
		_face_a = face
		_a_ok = true
	return true


## Where the rig's eye will be once reseated behind an astronaut facing `face`: the distance and
## elevation it has now (reseat_behind_player keeps the zoom and the pitch), behind that facing.
func _rig_after_for(face: Vector3) -> Vector3:
	var pivot := _p0 + _up * CameraRig.PIVOT_HEIGHT
	var off := _c0.origin - pivot
	var elev := off.dot(_up)
	return pivot - face * (off - _up * elev).length() + _up * elev


## The cost of the two camera moves a rocket shot at `eye` implies: how far round the astronaut it
## swings in from the close-up and out to the reseated rig, and how long those moves take.
func _b_travel_cost(a_bearing: Vector3, eye: Vector3, res: Dictionary) -> float:
	var after: Vector3 = res["after"]
	var bear := _tangent(eye - _p0, _up, a_bearing)
	var after_bearing := _tangent(after - _p0, _up, -_face_end)
	return W_B_TRAVEL * rad_to_deg(absf(_signed_angle(a_bearing, bear)) + absf(_signed_angle(bear, after_bearing))) / 180.0 \
		+ W_MOVE_TIME * float(res["move"])


## Scores one rocket-shot eye, or returns {} if it fails a hard test. `two_shot` also demands the
## astronaut in frame, clear of the rocket on screen. Every failure is counted by test (`_count`).
func _b_eval(eye: Vector3, aim: Vector3, two_shot: bool) -> Dictionary:
	var tag := "two_" if two_shot else "solo_"
	# A two-shot eye must be reachable from the astronaut, a solo one from the rocket's middle (the
	# rocket itself may stand between a solo eye and the astronaut).
	if not _eye_ok(eye, _p0 + _up * CameraRig.PIVOT_HEIGHT if two_shot else _rocket_mid, null if two_shot else _rocket):
		_count(tag + "eye")
		return {}
	var xf := _look_xf(eye, aim, _planet.dir_of(aim))
	var vb := _view(xf, _rocket_base)
	var vt := _view(xf, _rocket_top)
	var vm := _view(xf, _rocket_mid)
	if vb.z < 1.0 or vt.z < 1.0:
		_count(tag + "behind")
		return {}
	# The FOV that makes the rocket B_ROCKET_FRAC of the frame, clamped; then everything in half-height
	# units of THAT frame.
	var tan_lo := tan(deg_to_rad(FOV_B_MIN) * 0.5)
	var tan_hi := tan(deg_to_rad(FOV_B_MAX) * 0.5)
	var tv := clampf((vt.y - vb.y) / (2.0 * B_ROCKET_FRAC), tan_lo, tan_hi)
	var frac := (vt.y - vb.y) / (2.0 * tv)
	var fov_deg := rad_to_deg(2.0 * atan(tv))
	var lim := 1.0 - FRAME_MARGIN
	if vb.y / tv < -lim or vt.y / tv > lim:
		_count(tag + "rocket_v")
		return {}
	var rocket_hw := ROCKET_SIL_R / vm.z / tv
	var rocket_x := vm.x / tv
	if absf(rocket_x) + rocket_hw > FRAME_ASPECT - FRAME_MARGIN:
		_count(tag + "rocket_h")
		return {}
	# The rocket must be visible where the finish shows: its middle and upper hull not hidden behind
	# anything but itself, and clear of the pad's posts and mast; the mast not standing across it on
	# screen. The foot is left out on purpose - the pad's own clutter round the base is its setting,
	# and testing it there rejected 49 of 96 two-shots on the second run for a post at the fins.
	for p: Vector3 in [_rocket_mid, _rocket_top - _rocket_up * 0.3]:
		if not _ray_clear(eye, p, _rocket):
			_count(tag + "rocket_ray")
			return {}
		if _pad_clearance(eye, p) < MIN_CLEAR:
			_count(tag + "rocket_pad")
			return {}
	if _mast_gap_deg(eye) < MAST_GAP_DEG:
		_count(tag + "mast_gap")
		return {}
	var fg := _foreground(xf, fov_deg, vm.z, false)
	if fg < 0.0:
		_count(tag + "foreground")
		return {}
	if not _arc_ok(_a_eye, eye):
		_count(tag + "path_in")
		return {}
	# A two-shot ends with the astronaut facing the rocket; a solo shot with them facing the way the
	# camera looks (see SOLO_BEARINGS) - the rig is reseated behind whichever it is.
	var after := _rig_after_for(_u if two_shot else _tangent(aim - eye, _up, _u))
	if not _arc_ok(eye, after, false):
		_count(tag + "path_out")
		return {}
	var score := -W_B_FRAC * absf(frac - B_ROCKET_FRAC) - W_FOREGROUND * fg - W_CLUTTER_B * _clutter(xf, fov_deg)
	if _sun != Vector3.ZERO:
		score += W_SUN * (eye - _rocket_mid).normalized().dot(_sun)
	var vh := _view(xf, _p0 + _up * ASTRO_TOP)
	var vf := _view(xf, _p0 + _up * 0.05)
	var vc := _view(xf, _p0 + _up * 0.8)
	var astro_x := vc.x / tv if vc.z > 0.0 else 99.0
	var astro_hw := ASTRO_HALF_W / vc.z / tv if vc.z > 0.0 else 0.0
	# Standing between the lens and the rocket, the astronaut would hide the reveal - in a solo shot
	# too, where they are not meant to be in frame at all but can wander into it.
	if vc.z > 0.5 and vc.z < vm.z and absf(astro_x) - astro_hw < FRAME_ASPECT \
			and absf(astro_x - rocket_x) - astro_hw - rocket_hw < B_SEPARATION:
		_count(tag + "overlap")
		return {}
	if not two_shot and vc.z > 0.5 and absf(absf(astro_x) - FRAME_ASPECT) < astro_hw:
		score -= W_EDGE_CUT
	if two_shot:
		if vh.z < 0.5 or vf.z < 0.5:
			_count(tag + "astro_behind")
			return {}
		if vh.y / tv > lim or vf.y / tv < -1.15 or absf(astro_x) + astro_hw > FRAME_ASPECT - FRAME_MARGIN:
			_count(tag + "astro_frame")
			return {}
		if not _astro_visible(eye, false):
			_count(tag + "astro_sight")
			return {}
		# Prefer the astronaut big enough to read (a quarter of the frame and up) but not filling it.
		var astro_frac := (vh.y - vf.y) / (2.0 * tv)
		score -= maxf(0.25 - astro_frac, 0.0) * 2.0 + maxf(astro_frac - 0.6, 0.0) * 2.0
	return {"score": score, "fov": fov_deg, "after": after, "move": _b_move_time(eye, aim, after)}


func _count(key: String) -> void:
	_reject[key] = int(_reject.get(key, 0)) + 1


## Seconds of camera move a rocket shot at `eye` (aimed at `aim`) costs: the move in from the close-up
## plus the hand-back out to the rig reseated at `after`.
func _b_move_time(eye: Vector3, aim: Vector3, after: Vector3) -> float:
	return _move_seconds(_a_eye, eye, _p0 + _up * A_LOOK_H, aim, CAM_ROCKET_SECONDS, CAM_ROCKET_MAX) \
		+ _move_seconds(eye, after, aim, _p0 + _up * CameraRig.PIVOT_HEIGHT, HANDBACK_SECONDS, HANDBACK_MAX)


## True if a pad piece or the rocket, at any depth, crosses the astronaut's silhouette on screen in
## the close-up - standing up behind the helmet or across the body - from the boots to the top of the
## jump, within SUBJECT_MARGIN either side.
func _crosses_subject(xf: Transform3D, fov_deg: float) -> bool:
	var tv := tan(deg_to_rad(fov_deg) * 0.5)
	var vc := _view(xf, _p0 + _up * 0.8)
	if vc.z <= 0.05:
		return false
	var ax := vc.x / tv
	var ahw := ASTRO_HALF_W / vc.z / tv
	var y_lo := _view(xf, _p0).y / tv
	var apex := _look_xf(xf.origin, _p0 + _up * (A_LOOK_H + A_JUMP_FOLLOW * JUMP_APEX))
	var y_hi := maxf(_view(xf, _p0 + _up * ASTRO_TOP).y, _view(apex, _p0 + _up * (ASTRO_TOP + JUMP_APEX)).y) / tv
	var shapes: Array = _obstacles.duplicate()
	if _has_rocket:
		shapes.append([_rocket_base, _rocket_up, RocketModel.TOTAL_HEIGHT, ROCKET_SIL_R])
	for o: Array in shapes:
		var base: Vector3 = o[0]
		var axis: Vector3 = o[1]
		var hgt: float = o[2]
		var rad: float = o[3]
		for i in 17:
			var v := _view(xf, base + axis * (hgt * float(i) / 16.0))
			if v.z <= 0.05:
				continue
			var y := v.y / tv
			if y < y_lo or y > y_hi:
				continue
			if absf(v.x / tv - ax) < ahw + rad / v.z / tv + SUBJECT_MARGIN:
				return true
	return false


## Tens of degrees of view taken up by pad pieces in frame within CLUTTER_DEPTH_M of the lens.
func _clutter(xf: Transform3D, fov_deg: float) -> float:
	var tv := tan(deg_to_rad(fov_deg) * 0.5)
	var total := 0.0
	for o: Array in _obstacles:
		var base: Vector3 = o[0]
		var ax: Vector3 = o[1]
		var hgt: float = o[2]
		var rad: float = o[3]
		var nearest := INF
		for i in 17:
			var v := _view(xf, base + ax * (hgt * float(i) / 16.0))
			if v.z <= 0.05 or v.z > CLUTTER_DEPTH_M:
				continue
			if absf(v.x / tv) > FRAME_ASPECT + rad / v.z / tv or absf(v.y / tv) > 1.0:
				continue
			nearest = minf(nearest, v.z)
		if nearest < INF:
			total += rad_to_deg(2.0 * atan(rad / nearest)) / 10.0
	return total


## Pad pieces (and, for the close-up, the rocket) standing in frame between the lens and a subject
## `subject_depth` m away: -1 if one is nearer than FOREGROUND_REJECT_M, else the sum of their
## angular widths in tens of degrees - the W_FOREGROUND penalty.
func _foreground(xf: Transform3D, fov_deg: float, subject_depth: float, with_rocket: bool) -> float:
	var tv := tan(deg_to_rad(fov_deg) * 0.5)
	var shapes: Array = _obstacles.duplicate()
	if with_rocket and _has_rocket:
		shapes.append([_rocket_base, _rocket_up, RocketModel.TOTAL_HEIGHT, ROCKET_SIL_R])
	var total := 0.0
	for o: Array in shapes:
		var base: Vector3 = o[0]
		var ax: Vector3 = o[1]
		var hgt: float = o[2]
		var rad: float = o[3]
		var nearest := INF
		# 17 samples: at 9 the 7.9 m mast was probed every metre and slipped into the 2.6 m layout's
		# close-up as a pole down the left edge between two probes.
		for i in 17:
			var v := _view(xf, base + ax * (hgt * float(i) / 16.0))
			if v.z <= 0.05 or v.z >= subject_depth:
				continue
			if absf(v.x / tv) > FRAME_ASPECT + rad / v.z / tv or absf(v.y / tv) > 1.0:
				continue
			nearest = minf(nearest, v.z)
		if nearest == INF:
			continue
		if nearest < FOREGROUND_REJECT_M:
			return -1.0
		total += rad_to_deg(2.0 * atan(rad / nearest)) / 10.0
	return total


## The close-up keeps the astronaut whole: feet in frame standing, the raised arms in frame at the
## top of the jump (with the aim's A_JUMP_FOLLOW tilt), both inside the 16:9 margin.
func _a_frames(eye: Vector3) -> bool:
	var tv := tan(deg_to_rad(FOV_A) * 0.5)
	var lim := 1.0 - FRAME_MARGIN
	var rest := _look_xf(eye, _p0 + _up * A_LOOK_H)
	var feet := _view(rest, _p0)
	if feet.z < 0.5 or feet.y / tv < -lim:
		return false
	var apex_look := _look_xf(eye, _p0 + _up * (A_LOOK_H + A_JUMP_FOLLOW * JUMP_APEX))
	var top := _view(apex_look, _p0 + _up * (ASTRO_TOP + JUMP_APEX + 0.15))
	return top.z > 0.5 and top.y / tv < lim


func _rocket_in_frame(xf: Transform3D, fov_deg: float, p: Vector3) -> bool:
	var v := _view(xf, p)
	var tv := tan(deg_to_rad(fov_deg) * 0.5)
	return v.z > 0.5 and absf(v.x / tv) < FRAME_ASPECT - FRAME_MARGIN and absf(v.y / tv) < 1.0


## Where the astronaut faces for the close-up: at the lens, turned A_FACE_OFF_DEG toward the rocket.
func _face_for(dir: Vector3) -> Vector3:
	var sgn := 1.0
	if _has_rocket and dir.cross(_u).dot(_up) < 0.0:
		sgn = -1.0
	return dir.rotated(_up, deg_to_rad(A_FACE_OFF_DEG) * sgn)


## An eye is usable if it is above the ground under it and can see `from` (the astronaut's pivot,
## unless given) through nothing but `allow` - the same test the rig's spring arm makes, so it is
## never inside a hill or the dome.
func _eye_ok(eye: Vector3, from: Vector3 = Vector3.INF, allow: Node = null) -> bool:
	var d := _planet.dir_of(eye)
	if eye.distance_to(_planet.global_position) < _planet.height_at(d) + CAM_GROUND_CLEAR:
		return false
	var src := _p0 + _up * CameraRig.PIVOT_HEIGHT if from == Vector3.INF else from
	return _ray_clear(src, eye, allow)


## The camera's path from `from` to `to` (see `_arc`): every sample above the ground and clear of the
## rocket and the pad pieces, and - with `rays` - nothing solid between one sample and the next. The
## hand-back is tested without rays: its far end is only a prediction of where the rig will stand.
func _arc_ok(from: Vector3, to: Vector3, rays: bool = true) -> bool:
	var prev := from
	for i in range(1, 9):
		var e := _arc(from, to, float(i) / 8.0)
		if e.distance_to(_planet.global_position) < _planet.height_at(_planet.dir_of(e)) + CAM_GROUND_CLEAR * 0.5:
			return false
		if _has_rocket and _axis_dist(e, _rocket_base, _rocket_up, RocketModel.TOTAL_HEIGHT) < ROCKET_KEEP_M:
			return false
		for o: Array in _obstacles:
			var base: Vector3 = o[0]
			var ax: Vector3 = o[1]
			if _axis_dist(e, base, ax, float(o[2])) - float(o[3]) < OBSTACLE_KEEP_M:
				return false
		if rays and not _ray_clear(prev, e, null):
			return false
		prev = e
	return true


## Distance from `p` to the segment from `base` along `ax` for `hgt` metres.
static func _axis_dist(p: Vector3, base: Vector3, ax: Vector3, hgt: float) -> float:
	var v := p - base
	var along := clampf(v.dot(ax), 0.0, hgt)
	return (v - ax * along).length()


## Boots, chest and helmet visible from `eye` (and, for the close-up, the top of the jump - tested
## against solid things only: the apex lasts a tenth of a second, and holding it to the pad pieces'
## clearance rejected every close-up of an astronaut standing in the Fly gateway on the second run).
func _astro_visible(eye: Vector3, with_apex: bool) -> bool:
	for h: float in [0.3, 0.85, ASTRO_TOP - 0.1]:
		var p := _p0 + _up * h
		if not _ray_clear(eye, p, null) or _pad_clearance(eye, p) < MIN_CLEAR:
			return false
	if with_apex and not _ray_clear(eye, _p0 + _up * (ASTRO_TOP + JUMP_APEX), null):
		return false
	return true


func _ray_clear(from: Vector3, to: Vector3, allow: Node) -> bool:
	var q := PhysicsRayQueryParameters3D.create(from, to, SIGHT_MASK)
	q.exclude = [_player.get_rid()]
	var hit := _space.intersect_ray(q)
	if hit.is_empty():
		return true
	if allow != null:
		var col := hit.get("collider") as Node
		if col != null and (col == allow or allow.is_ancestor_of(col)):
			return true
	return false


## The pad's upright pieces as cylinders [base, axis, height, radius], found by the node names
## rocket_pad.gd gives them - the same five shapes CrashIntro tests. None of them has a collider, so
## the physics rays above cannot see them. A missing piece is simply not tested.
func _pad_obstacles() -> Array:
	var out: Array = []
	_has_mast = false
	var pad := get_node_or_null("/root/World/Rocket")
	var root := pad.get_node_or_null("Pad") if pad != null else null
	if root == null:
		return out
	var pup := _rocket_up if _has_rocket else _up
	for n: String in ["FlySign/Post-1", "FlySign/Post1"]:
		var post := root.get_node_or_null(n) as Node3D
		if post != null:
			out.append([post.global_position - pup * 1.45, pup, 3.0, 0.14])
	var sign_root := root.get_node_or_null("FlySign") as Node3D
	if sign_root != null:
		out.append([sign_root.global_position + pup * 2.05, pup, 0.9, 0.66])
	var console := root.get_node_or_null("ControlPost") as Node3D
	if console != null:
		out.append([console.global_position, pup, 1.65, 0.42])
	var mast := root.get_node_or_null("BeaconMast") as Node3D
	if mast != null:
		out.append([mast.global_position, pup, MAST_H, 0.28])
		_mast_base = mast.global_position
		_mast_top = _mast_base + pup * MAST_H
		_has_mast = true
	return out


## Smallest gap (m) between the segment a-b and any pad piece, sampled at 17 points.
func _pad_clearance(a: Vector3, b: Vector3) -> float:
	var best := INF
	for o: Array in _obstacles:
		var base: Vector3 = o[0]
		var ax: Vector3 = o[1]
		var hgt: float = o[2]
		var rad: float = o[3]
		for i in 17:
			var v := a.lerp(b, float(i) / 16.0) - base
			var along := v.dot(ax)
			if along < 0.0 or along > hgt:
				continue
			best = minf(best, (v - ax * along).length() - rad)
	return best


## Degrees of view between the rocket's silhouette and the mast's from `eye`; below 0 they overlap.
## Each rocket sample is measured against the mast's whole arc of directions, not against samples of
## it, so a thin mast cannot slip between two probes.
func _mast_gap_deg(eye: Vector3) -> float:
	if not _has_mast:
		return INF
	var u0 := (_mast_base - eye).normalized()
	var u1 := (_mast_top - eye).normalized()
	var nrm := u0.cross(u1)
	var span := u0.angle_to(u1)
	var mast_d := eye.distance_to(_mast_base.lerp(_mast_top, 0.3))
	var best := INF
	for i in 9:
		var p := _rocket_base.lerp(_rocket_top, float(i) / 8.0)
		var d := (p - eye).normalized()
		var ang := minf(d.angle_to(u0), d.angle_to(u1))
		if nrm.length_squared() > 1e-10:
			var n := nrm.normalized()
			var c := d - n * d.dot(n)
			if c.length_squared() > 1e-10:
				c = c.normalized()
				if c.angle_to(u0) <= span + 1e-4 and c.angle_to(u1) <= span + 1e-4:
					ang = asin(clampf(absf(d.dot(n)), 0.0, 1.0))
		var gap := rad_to_deg(ang - atan(ROCKET_SIL_R / eye.distance_to(p)) - atan(MAST_SIL_R / maxf(mast_d, 0.1)))
		best = minf(best, gap)
	return best


# ============================================================================= math
## The camera path between two eyes: round the astronaut (angle, radius and height interpolated about
## their up axis) rather than straight through them.
func _arc(e0: Vector3, e1: Vector3, k: float) -> Vector3:
	var o0 := e0 - _p0
	var o1 := e1 - _p0
	var h0 := o0.dot(_up)
	var h1 := o1.dot(_up)
	var t0 := o0 - _up * h0
	var t1 := o1 - _up * h1
	var r0 := t0.length()
	var r1 := t1.length()
	if r0 < 0.05 or r1 < 0.05:
		return e0.lerp(e1, k)
	var a := _signed_angle(t0 / r0, t1 / r1)
	return _p0 + (t0 / r0).rotated(_up, a * k) * lerpf(r0, r1, k) + _up * lerpf(h0, h1, k)


## Camera transform from `eye` aimed at `target`, rolled level to `level_up` (the astronaut's up
## when not given - what the rig levels to).
func _look_xf(eye: Vector3, target: Vector3, level_up: Vector3 = Vector3.ZERO) -> Transform3D:
	var fwd := target - eye
	if fwd.length_squared() < 1e-8:
		fwd = -_face0
	fwd = fwd.normalized()
	var upv := _up if level_up == Vector3.ZERO else level_up.normalized()
	if absf(fwd.dot(upv)) > 0.985:
		upv = _face0
	return Transform3D(Basis.looking_at(fwd, upv), eye)


## `p` in the view of `xf`: (x / depth, y / depth, depth). Divide x and y by tan(fov / 2) for
## half-height units (y up); depth <= 0 is behind the lens.
static func _view(xf: Transform3D, p: Vector3) -> Vector3:
	var v := xf.basis.orthonormalized().transposed() * (p - xf.origin)
	var depth := -v.z
	if depth < 0.001:
		return Vector3(0.0, 0.0, depth)
	return Vector3(v.x / depth, v.y / depth, depth)


## Signed angle from `a` to `b` about the astronaut's up, in radians.
func _signed_angle(a: Vector3, b: Vector3) -> float:
	return atan2(a.cross(b).dot(_up), a.dot(b))


## Turns facing `a` toward `b` about up by fraction `k` - by the signed angle, so a 180 deg turn
## has a direction instead of slerp's coin toss.
func _turn(a: Vector3, b: Vector3, k: float) -> Vector3:
	return a.rotated(_up, _signed_angle(a, b) * k).normalized()


## `v` flattened onto the tangent plane of `up` and normalised; `fallback` if it degenerates.
static func _tangent(v: Vector3, up: Vector3, fallback: Vector3) -> Vector3:
	var t := v - up * v.dot(up)
	if t.length_squared() < 1e-8:
		return fallback
	return t.normalized()


## Smootherstep: zero velocity AND zero acceleration at both ends, so each camera move leaves a held
## shot and arrives at the next without a jerk.
static func _ease(x: float) -> float:
	var k := clampf(x, 0.0, 1.0)
	return k * k * k * (k * (k * 6.0 - 15.0) + 10.0)


func _once(key: String) -> bool:
	if _fired.has(key):
		return false
	_fired[key] = true
	return true


func _sfx(sfx_name: String, db: float) -> void:
	if AudioManager.sfx_exists(sfx_name):
		AudioManager.play_sfx(sfx_name, db, 0.06)


# ============================================================================= skip
func _input(event: InputEvent) -> void:
	if _phase != Phase.RUNNING or _t < SKIP_ARM_T:
		return
	if _is_skip_press(event):
		get_viewport().set_input_as_handled()
		_skip("%s" % event.get_class())


static func _is_skip_press(event: InputEvent) -> bool:
	if event is InputEventKey:
		var k := event as InputEventKey
		return k.pressed and not k.echo
	if event is InputEventMouseButton:
		# Real buttons only. A wheel notch and a trackpad scroll arrive as InputEventMouseButton
		# presses too (MOUSE_BUTTON_WHEEL_*), and must not skip - same filter as CrashIntro.
		var mb := event as InputEventMouseButton
		return mb.pressed and mb.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]
	if event is InputEventScreenTouch:
		return (event as InputEventScreenTouch).pressed
	if event is InputEventJoypadButton:
		return (event as InputEventJoypadButton).pressed
	return false


## THE ACTION HALF OF THE SKIP, for Director timelines: `Input.action_press` sends no InputEvent, so
## `_input` never sees a timeline's tap. Polled here, after the Director's _process has pressed it
## this frame (see process_priority in _ready). `_skip_primed` swallows an action already held when
## the shot began - the E that fitted the part, say.
func _poll_skip_actions() -> void:
	var edge := false
	for a: String in SKIP_ACTIONS:
		if not InputMap.has_action(a):
			continue
		var now := Input.is_action_pressed(a)
		if now and not bool(_skip_held.get(a, false)) and _skip_primed and _t >= SKIP_ARM_T:
			edge = true
		_skip_held[a] = now
	_skip_primed = true
	if edge:
		_skip("action")


func _skip(why: String) -> void:
	if _phase != Phase.RUNNING:
		return
	_phase = Phase.SKIPPING
	_skipped = true
	_log("skip (%s) at t=%.2f" % [why, _t])
	await SceneRouter.fade_out(SKIP_FADE_OUT)
	if not is_inside_tree() or _phase != Phase.SKIPPING:
		return
	_finish(true)
	SceneRouter.fade_in(SKIP_FADE_IN)


# ============================================================================= ending
## Puts everything exactly where the shot leaves it. Idempotent; safe from a skip at any moment.
func _apply_end_state() -> void:
	if _player != null and is_instance_valid(_player):
		_player.global_transform = Transform3D(Basis.looking_at(_face_end, _up), _p0)
		_player.velocity = Vector3.ZERO
	# A reaction started through play_emote is left to finish on its own (see `_reacted`); anything this
	# node set on the model directly is put back to idle.
	if _model != null and is_instance_valid(_model) and not _reacted:
		_model.set_state("idle")
	if _rocket != null and is_instance_valid(_rocket):
		_rocket.refresh_finish()
	_revealed = true
	_fired["swap"] = true
	if _skipped and _burst != null:
		# Under the fade: the sparkles of a skipped reveal must not still be drifting when it lifts.
		_burst.emitting = false
		_burst.visible = false


func _finish(skipped: bool) -> void:
	_skipped = skipped
	_apply_end_state()
	if not _reseated and _rig != null and is_instance_valid(_rig):
		_rig.reseat_behind_player()
	_reseated = true
	_drop_camera()
	_phase = Phase.RELEASING
	_release_t = 0.0
	if not _hold_keys_down():
		_release()


## Control goes back: astronaut thawed, then the modal closed - exactly once.
func _release() -> void:
	_thaw_player()
	_end_modal()
	_phase = Phase.IDLE
	_log("complete skipped=%s; camera max %.2f m/s and %.1f deg/s (max step %.3f m, %.2f deg, fov %.2f in one frame); control back after %.2f s held keys" % [
		str(_skipped), _max_speed, _max_ang_speed, _max_step_m, _max_step_deg, _max_step_fov, _release_t])
	if _trace != null:
		_trace.close()
		_trace = null
	finished.emit(_skipped)


func _end_modal() -> void:
	if _modal:
		_modal = false
		EventBus.ui_modal_closed.emit(MODAL_NAME)


func _hold_keys_down() -> bool:
	for a: String in HOLD_ACTIONS:
		if InputMap.has_action(a) and Input.is_action_pressed(a):
			return true
	return false


# ============================================================================= pieces
func _find_rocket() -> RocketModel:
	var pad := get_node_or_null("/root/World/Rocket")
	if pad == null:
		return null
	return pad.get("rocket") as RocketModel


## The reveal: cream stars that appear ON the hull (a ring round it, the rocket's height tall), swell
## and fade as they drift a little outward. The star is drawn once into a small texture here.
func _make_sparkles() -> GPUParticles3D:
	var gp := GPUParticles3D.new()
	gp.name = "RevealSparkles"
	gp.emitting = false
	gp.one_shot = true
	gp.amount = SPARKLE_COUNT
	gp.lifetime = SPARKLE_LIFE
	gp.explosiveness = 0.7
	gp.randomness = 0.4
	gp.local_coords = false
	gp.visible = false
	gp.visibility_aabb = AABB(Vector3(-3.0, -3.0, -3.0), Vector3(6.0, 6.0, 6.0))
	gp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	pm.emission_ring_axis = Vector3.UP
	pm.emission_ring_height = RocketModel.TOTAL_HEIGHT * 0.85
	pm.emission_ring_radius = RocketModel.HULL_R + 0.14
	pm.emission_ring_inner_radius = RocketModel.HULL_R + 0.02
	pm.direction = Vector3(0.0, 1.0, 0.0)
	pm.spread = 60.0
	pm.initial_velocity_min = 0.15
	pm.initial_velocity_max = 0.55
	pm.radial_accel_min = 0.4
	pm.radial_accel_max = 1.1
	pm.gravity = Vector3.ZERO
	pm.damping_min = 0.6
	pm.damping_max = 1.2
	pm.angle_min = -30.0
	pm.angle_max = 30.0
	var sc := Curve.new()
	sc.add_point(Vector2(0.0, 0.0))
	sc.add_point(Vector2(0.22, 1.0))
	sc.add_point(Vector2(0.6, 0.7))
	sc.add_point(Vector2(1.0, 0.0))
	var sct := CurveTexture.new()
	sct.curve = sc
	pm.scale_curve = sct
	pm.scale_min = 0.6
	pm.scale_max = 1.3
	var grad := Gradient.new()
	grad.set_color(0, Color(SPARKLE_COLOR, 0.95))
	grad.set_color(1, Color(SPARKLE_COLOR, 0.0))
	var gt := GradientTexture1D.new()
	gt.gradient = grad
	pm.color_ramp = gt
	gp.process_material = pm
	var quad := QuadMesh.new()
	quad.size = Vector2(SPARKLE_SIZE, SPARKLE_SIZE)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = _star_texture()
	mat.disable_receive_shadows = true
	quad.material = mat
	gp.draw_pass_1 = quad
	return gp


## A four-point star with a soft core, 48 px, white (the particle colour tints it).
static func _star_texture() -> ImageTexture:
	const N := 48
	var img := Image.create(N, N, false, Image.FORMAT_RGBA8)
	for y in N:
		for x in N:
			var u := (float(x) + 0.5) / float(N) * 2.0 - 1.0
			var v := (float(y) + 0.5) / float(N) * 2.0 - 1.0
			var core := exp(-(u * u + v * v) * 22.0)
			var rays := exp(-absf(u) * 26.0) * exp(-absf(v) * 2.6) + exp(-absf(v) * 26.0) * exp(-absf(u) * 2.6)
			var a := clampf(core + rays * 0.85, 0.0, 1.0) * (1.0 - smoothstep(0.85, 1.0, maxf(absf(u), absf(v))))
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, a))
	return ImageTexture.create_from_image(img)


## The same dark glass pill CrashIntro's caption shows (radio_caption.gd `_build_skip`), bottom right,
## inside the phone's safe area.
func _build_skip_hint() -> void:
	_hint_layer = CanvasLayer.new()
	_hint_layer.name = "SkipHint"
	_hint_layer.layer = HINT_LAYER
	add_child(_hint_layer)
	_hint_root = Control.new()
	_hint_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hint_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint_root.theme = UIStyle.theme()
	_hint_layer.add_child(_hint_root)
	MobileUI.apply_theme(_hint_root)
	_hint_pill = PanelContainer.new()
	_hint_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint_pill.add_theme_stylebox_override("panel",
		UIStyle.make_pill_style(Color(0.09, 0.10, 0.20, 0.62), Color(0.55, 0.58, 0.72, 0.5), 2, 0, 16.0, 6.0))
	_hint_pill.modulate.a = 0.0
	_hint_pill.visible = false
	_hint_root.add_child(_hint_pill)
	var l := Label.new()
	l.text = "Tap to skip" if MobileUI.is_mobile() else "Press any key to skip"
	l.add_theme_color_override("font_color", Color("#dfe2ee"))
	l.add_theme_font_size_override("font_size", int(MobileUI.pick(UIStyle.SIZE_HINT, 19.0)))
	_hint_pill.add_child(l)


func _update_hint(delta: float) -> void:
	if _hint_pill == null:
		return
	var want := 0.0
	if _phase == Phase.RUNNING and _t >= SKIP_HINT_T and _t < _t_handback:
		want = SKIP_HINT_ALPHA
	_hint_alpha = move_toward(_hint_alpha, want, delta / SKIP_HINT_FADE)
	if _phase == Phase.SKIPPING or _phase == Phase.RELEASING:
		_hint_alpha = 0.0
	_hint_pill.modulate.a = _hint_alpha
	_hint_pill.visible = _hint_alpha > 0.005
	if _hint_pill.visible:
		var vp := _hint_root.size
		var safe := MobileUI.safe_area() if MobileUI.is_mobile() else Vector4.ZERO
		_hint_pill.reset_size()
		_hint_pill.position = Vector2(vp.x - _hint_pill.size.x - 24.0 - safe.z, vp.y - _hint_pill.size.y - 22.0 - safe.w)


# ============================================================================= measurement
## Largest per-frame camera move over the shot, reported at the end: the "no cut" rule measured
## rather than asserted.
func _track_camera(xf: Transform3D, fov: float, dt: float) -> void:
	var q := xf.basis.get_rotation_quaternion()
	if _have_last:
		var dm := xf.origin.distance_to(_last_xf.origin)
		var da := rad_to_deg(q.angle_to(_last_xf.basis.get_rotation_quaternion()))
		_max_step_m = maxf(_max_step_m, dm)
		_max_step_deg = maxf(_max_step_deg, da)
		_max_step_fov = maxf(_max_step_fov, absf(fov - _last_fov))
		if dt > 0.0001:
			_max_speed = maxf(_max_speed, dm / dt)
			_max_ang_speed = maxf(_max_ang_speed, da / dt)
	_last_xf = xf
	_last_fov = fov
	_have_last = true
	if _trace != null:
		_trace.store_line("%d,%.4f,%.4f,%.4f,%.4f,%.4f,%.8f,%.8f,%.8f,%.8f,%.3f" % [
			_trace_frame, _t, dt, xf.origin.x, xf.origin.y, xf.origin.z, q.x, q.y, q.z, q.w, fov])
		_trace_frame += 1


## How big the astronaut and the rocket are in the frame right now, as a share of its height.
func _measure(tag: String) -> void:
	if _cam == null:
		return
	var vp := get_viewport().get_visible_rect().size
	var astro := absf(_cam.unproject_position(_player.global_position).y
		- _cam.unproject_position(_player.global_position + _up * ASTRO_TOP).y) / vp.y
	var line := "%s: astronaut %.0f%% of the frame height" % [tag, astro * 100.0]
	if _has_rocket and not _cam.is_position_behind(_rocket_base) and not _cam.is_position_behind(_rocket_top):
		var sb := _cam.unproject_position(_rocket_base)
		var st := _cam.unproject_position(_rocket_top)
		var rect := Rect2(Vector2.ZERO, vp)
		if rect.has_point(sb) or rect.has_point(st):
			line += ", rocket %.0f%% (base y %.2f, nose y %.2f, x %.2f)" % [absf(sb.y - st.y) / vp.y * 100.0,
				sb.y / vp.y, st.y / vp.y, (sb.x + st.x) * 0.5 / vp.x]
	line += " [fov %.1f]" % _cam.fov
	_log(line)


func _log(msg: String) -> void:
	print("CELEBRATE [%5.2f] %s" % [_t, msg])


# ============================================================================= test hooks
## TEST HOOK (Director timelines; nothing in the game calls it). Stands the astronaut `dist_m` metres
## along the surface from the pad centre, `bearing_deg` round from the rocket's hatch line, facing
## `facing_deg` from the direction to the rocket (0 faces it, 180 faces away), and snaps the gameplay
## camera in behind them - the framing a player finishing at a bench would have.
func debug_stage(dist_m: float, bearing_deg: float, facing_deg: float) -> void:
	var rocket := _find_rocket()
	var planet := get_node_or_null("/root/World/Planet") as Planet
	var p := get_tree().get_first_node_in_group("player") as Player
	if rocket == null or planet == null or p == null:
		_log("debug_stage: missing rocket/planet/player")
		return
	var pad_up := planet.dir_of(rocket.global_position)
	var hatch := _tangent(-rocket.global_basis.z, pad_up, pad_up.cross(Vector3.RIGHT))
	var toward := hatch.rotated(pad_up, deg_to_rad(bearing_deg))
	var dir := planet.step_dir(pad_up, (pad_up + toward * 0.5).normalized(), dist_m)
	var at := planet.surface_point(dir)
	var to_r := _tangent(rocket.global_position - at, dir, toward)
	p.place_on_planet(dir, to_r.rotated(dir, deg_to_rad(facing_deg)))
	var rig := get_node_or_null("/root/World/CameraRig") as CameraRig
	if rig != null:
		rig.reseat_behind_player()
	_log("debug_stage: %.1f m from the pad at bearing %.0f, facing %.0f from the rocket" % [dist_m, bearing_deg, facing_deg])


## TEST HOOKS: a real InputEvent press (and its release a frame later) through
## Input.parse_input_event - the path a keyboard, mouse or finger takes into `_input`. Still
## SYNTHESISED: no hardware is involved.
func debug_key(physical_keycode: int) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = physical_keycode as Key
	ev.keycode = physical_keycode as Key
	ev.pressed = true
	Input.parse_input_event(ev)
	await get_tree().process_frame
	var rel := ev.duplicate() as InputEventKey
	rel.pressed = false
	Input.parse_input_event(rel)


func debug_mouse(button_index: int) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = button_index as MouseButton
	ev.pressed = true
	ev.position = get_viewport().get_visible_rect().size * 0.5
	ev.global_position = ev.position
	Input.parse_input_event(ev)
	await get_tree().process_frame
	var rel := ev.duplicate() as InputEventMouseButton
	rel.pressed = false
	Input.parse_input_event(rel)


func debug_touch() -> void:
	var ev := InputEventScreenTouch.new()
	ev.index = 0
	ev.pressed = true
	ev.position = get_viewport().get_visible_rect().size * 0.5
	Input.parse_input_event(ev)
	await get_tree().process_frame
	var rel := ev.duplicate() as InputEventScreenTouch
	rel.pressed = false
	Input.parse_input_event(rel)


## A trackpad two-finger swipe as macOS delivers it (a pan gesture), which must not skip.
func debug_pan() -> void:
	var ev := InputEventPanGesture.new()
	ev.delta = Vector2(0.0, 4.0)
	ev.position = get_viewport().get_visible_rect().size * 0.5
	Input.parse_input_event(ev)


## One line: the phase, the modal gate and the astronaut's gates, for a timeline to assert on.
func debug_report(tag: String) -> void:
	var p := get_tree().get_first_node_in_group("player") as Player
	var cam := get_viewport().get_camera_3d()
	print("CELEBRATE REPORT %s phase=%s t=%.2f modal=%d names=%s input_enabled=%s phys=%s proc=%s cam=%s" % [
		tag, Phase.keys()[_phase], _t, EventBus.modal_total(), str(EventBus.modal_counts()),
		str(p.input_enabled) if p != null else "-", str(p.is_physics_processing()) if p != null else "-",
		str(p.is_processing()) if p != null else "-", cam.name if cam != null else "-"])
