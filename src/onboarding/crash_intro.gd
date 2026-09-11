class_name CrashIntro
extends Node3D
## THE CRASH - the Stranded campaign's opening shot (docs/CORE_LOOP.md "Knocked off course";
## docs/BUILD_PLAN.md Phase 1, builder C). Spawned once by IntroDirector on a new campaign game.
##
## THE SHOT, one camera and no cut (docs/STYLE_GUIDE.md R2.5), 1.9 s of card + 20.6 s of picture:
##   -1.9 s  navy card; Professor Comet's first radio line types over it
##    0.0    the card lifts on your ship cruising through deep space, the small home planet ahead
##           and below, the neighbouring worlds hanging in the sky around it
##    5.0    a lumpy asteroid drifts in from the right, dead ahead of the ship; the Professor spots
##           it on his scope, and his caption has cleared before it arrives
##    7.0    BONK on the nose: a spark burst, a small flash, hull flakes, a squash and a shake
##    7-15   the ship tumbles end over end and falls toward home, which grows to fill the frame;
##           the sky turns from space back into the thin-atmosphere sky as it comes down
##   13.9    a coughing engine burn rights it, nose up, over the rocket pad
##   15.65   it drops onto the pad with a thump, bounces twice and wobbles to rest, smoking a little
##   17.6    the hatch opens; the astronaut pops out, bounces once more to clear the pad's Fly zone,
##           and turns to look at the poor rocket
##   19.5    the camera blends into the gameplay rig behind the astronaut; control returns at 20.6
##
## THE CRASHED SHIP IS THE ROCKET ON THE PAD. This borrows /root/World/Rocket's `rocket` (a
## RocketModel) for the shot and hands it back on exactly its parked transform, so the rocket you
## walk up to afterwards - rusty, per CampaignData.finish_stage() - is the one you watched fall.
## Nothing under src/rocket/ is edited; only RocketModel's public API is called.
##
## THE FINISH: CLEAN UNTIL THE HIT. `_begin` repaints the borrowed rocket to RocketModel.FINISH_CLEAN
## (stage 4, the ordinary white finish every rocket on the pad wears before the story's wear gates
## kick in) so the opening card and the whole cruise show a normal ship - rocket_pad.gd would
## otherwise have already painted it to CampaignData.finish_stage() (0, rusty, on a new game) before
## this node ever runs.
##
## AT THE HIT, `_update_fx` steps the finish down one stage at a time - FINISH_CLEAN, then each stage
## below it in turn, to CampaignData.finish_stage() - over FLASH_LIFE, the same window the contact
## flash burns in (`_finish_step`). NOT one swap: measured (round 1, f00000267 of a 30 fps default-
## renderer capture) a single repaint made the SAME call as the flash and spark burst read as a pop
## anyway, because the flash is a small disc AT the contact point (round 2's geometry, `_contact`),
## not a wash over the hull, and was one frame from even starting to grow when the whole hull had
## already gone patchily rusty. Stepping it - clean for the flash's first fifth of a second, then a
## stage every ~0.056 s - reads as the impact rusting the ship through the same burst of flash, sparks,
## chips and shake, rather than a colour swap arriving with nothing to hide it.
##
## `_apply_end_state` (every _complete: natural end, a skip before the hit, a skip after it) and
## `_exit_tree` (leaving mid-shot) both set CampaignData.finish_stage() directly (not stepped - there
## is no flash to hide behind once the shot has ended), so the rocket you end up at is always at that
## stage regardless of exit path - a skip before the hit is the one path nothing else would repaint.
##
## WHY THE NAVY CARD. environment.gd freezes where the neighbouring worlds hang from whatever camera
## it sees during the first BODY_AZ_LOCK_SEC (1.5 s) of the scene. Were that this shot's camera,
## 200 m out, the worlds would lock to elevations measured off a planet 3 deg across - below the
## ground once you land, so no neighbours in the gameplay sky (R2.1). So for CARD_SECONDS the
## gameplay rig stays current, parked behind the hidden astronaut at the landing spot, under an
## opaque card (which also hides the first frames' shader-compile stall), and the lock lands on the
## gameplay framing. The shot's camera takes over only while the card is fully opaque. From space
## those worlds then sit at fixed directions around home - which is what distant planets do.
##
## CONTINUITY. Every camera value is a continuous function of the shot clock `_t`. At the bonk the
## camera does not follow the ship's new path at once: its target starts ON the cruise line with
## the cruise velocity and eases onto the fall path over CAM_CATCHUP, so the camera's position AND
## velocity are continuous through the hit and only the ship lurches in frame. The framing rules
## cross-fade with smoothsteps and the last HANDBACK_SECONDS blend into the live rig transform, as
## rocket_pad.gd `_hand_camera_back` does. `--crash-trace=<file>` (after "--") writes the rendered
## camera every frame, so "no cut" is measured rather than asserted.
##
## SKIP. Any key, click, tap or pad button - or the interact / ui_accept / jump / cancel / pause
## actions, so a Director timeline can skip it too - fades to navy, puts everything where the shot
## would have left it and fades back in. Armed from SKIP_ARM_T, after SceneRouter's own fade-in.

signal finished(skipped: bool)

# ------------------------------------------------------------------------------------ timeline
## Seconds of navy card before the picture. The camera switch (CARD_SECONDS - CAM_SWITCH_LEAD =
## 1.7 s in) must come after environment.gd BODY_AZ_LOCK_SEC (1.5 s): see the header. The shot
## clock is clamped per frame (MAX_STEP), the environment's is not, so the card always lasts at
## least as long in the environment's time as in ours.
const CARD_SECONDS := 1.9
## The shot's camera goes current this long before the card starts to lift.
const CAM_SWITCH_LEAD := 0.2
const REVEAL_SECONDS := 0.9
## SceneRouter fades in over 0.6 s starting 2 frames after the scene change; a press before this
## is the one that started the game, not a request to skip.
const SKIP_ARM_T := -0.9
const SKIP_HINT_T := -0.8
## 2 s of approach: the rock is in frame for ~1.6 s before it lands, long enough to register on a
## phone with the Professor's "what's that on my scope?" caption running under it.
const ASTEROID_IN_T := 5.0
const HIT_T := 7.0
const FALL_SECONDS := 8.2
const FALL_END_T := HIT_T + FALL_SECONDS
## The nose is slerped upright over the last this-many seconds of the fall.
const RIGHTING_SECONDS := 1.6
## The righting burn lights this long before the fall ends, and cuts BURN_CUT after it.
const BURN_LEAD := 1.3
const BURN_CUT := 0.08
const DROP_SECONDS := 0.45
const TD_T := FALL_END_T + DROP_SECONDS
## The landing camera's aim settles this long after the thump (see `_aim_point`).
const DROP_FOLLOW := 0.3
const SETTLE_SECONDS := 2.2
const HATCH_T := TD_T + 1.5
const POP_T := HATCH_T + 0.45
## Two hops out of the hatch, like the ship's own two bounces. The first is rocket_pad.gd
## `_pop_out`'s hop (0.65 s, 0.45 m arc), so a crash exit and a normal landing exit start alike; the
## second, smaller one carries the astronaut on out of the pad's Fly zone (see `_exit_distance`).
const HOP1_SECONDS := 0.65
const HOP1_ARC := 0.45
const HOP2_SECONDS := 0.38
const HOP2_ARC := 0.16
const POP_SECONDS := HOP1_SECONDS + HOP2_SECONDS
const POP_END_T := POP_T + POP_SECONDS
const TURN_SECONDS := 0.4
const SURPRISE_T := POP_END_T + 0.12
const HANDOFF_T := POP_END_T + 0.85
## rocket_pad.gd blends its flight camera back in 0.8 s from a chase framing; ours starts from a
## framing already near the rig's, so a slightly longer blend reads as a settle, not a move.
const HANDBACK_SECONDS := 1.1
const END_T := HANDOFF_T + HANDBACK_SECONDS
## Seconds the post-landing smoke wisp keeps rising after control is back.
const WISP_TAIL := 5.5
## Longest step the shot clock takes in one frame. A load stall must not jump the picture.
const MAX_STEP := 0.05

# ------------------------------------------------------------------------------------ the cruise
## Home's distance from the camera at the bonk: 200 m puts the R 12 planet at 3.4 deg of angular
## radius - a small world, clearly a planet, clearly not yet "the ground".
const CRUISE_DIST := 200.0
## How far below the camera's horizontal home sits during the cruise. The neighbouring worlds hang
## 8-20 deg below the landing spot's horizontal (environment.gd's band fractions 0.20-0.88 on a
## 7.4 m / 28 deg rig); at 27 deg home sits under that band, so no world is drawn over it.
const CRUISE_ELEV_DEG := 27.0
## Survey-flight speed. Slow: a 42 m drift in 7 s slides home from the right of frame toward the
## middle, which is the parallax that sells the flight without star streaks.
const CRUISE_SPEED := 6.0
## Cruise camera, from the ship's centre along (-flight axis toward home, up, -screen right):
## 11.9 m away (11.5 back, 2.2 up, 3.2 aside) the 3.2 m hull spans 3.2 / (2 x 11.9 x tan 23 deg) =
## 32% of frame height at FOV 46 when side-on - the size it reads at in the 1560x720 phone frames.
const CRUISE_BACK := 11.5
const CRUISE_UP := 2.2
const CRUISE_SIDE := 3.2
const CRUISE_NOSE_UP_DEG := 5.0
const BOB_M := 0.12
const BOB_HZ := 0.27
## Share of the look direction that aims at home rather than the ship (a two-shot). Faded out as
## the ship gets close, where home fills the frame on its own. Round 2's 0.38 sat the ship's top at
## ~29% of frame height - exactly the phone caption's bottom edge (28.5%) - so the nose and the bonk
## happened under the panel. At 0.20 the ship's centre rides at 42-44% through the cruise and its
## silhouette's top never rises above 33.7% on a 2.17:1 canvas (measured, Compatibility, 1404x648);
## home drops to ~78%, still whole in frame. Vertical placement does not depend on aspect (the FOV is
## vertical), so desktop gets the same composition with more room under its higher caption.
const LOOK_PLANET_W := 0.20
const LOOK_PLANET_ALT := Vector2(45.0, 130.0)
## The ship's centre never sits further than this off the look axis. FOV 46 is 23 deg half-height
## and the hull spans about +/-9 deg from the landing vantage (3.2 m at ~10 m), so 12 keeps the
## nose inside the frame too.
const KEEP_SHIP_DEG := 12.0
const FLIGHT_FOV := 46.0
## RocketModel.TOTAL_HEIGHT 3.2 / 2, minus the flame: the point the hull tumbles about.
const SHIP_HALF := 1.55

# ------------------------------------------------------------------------------------ the bonk
## THE ROCK'S APPROACH, a direction in (screen right, up, toward home). Round 2 started it 11 m right
## and 4.5 m UP of the ship, and on a phone it ran along the top edge and then behind the caption
## panel for its last 0.8 s, bonking the nose under the panel (critic, 2.17:1 canvas): the cruise
## camera looks down ~13 deg, so anything distant and high sits near the top of the frame, and a
## phone caption's bottom edge is at ~28% of frame height. So it comes in LEVEL from the right - the
## way the ship is flying, so the ship flies into it - and a touch nearer the camera, so it grows as
## it comes. `_solve_rock` starts it just outside the right edge of a WIDEST_ASPECT frame (20:9, the
## widest phones) at ASTEROID_IN_T.
const AST_DIR := Vector3(1.0, 0.0, -0.2)
const WIDEST_ASPECT := 20.0 / 9.0
const AST_SPIN_DEG := 70.0
const AST_SPIN_AFTER_DEG := 240.0
const AST_BOUNCE_SPEED := 6.5
const AST_HIDE_T := HIT_T + 3.0
## THE ROCK'S FILL LIGHT. From the mast-clear vantages the morning sun sits past 90 deg from the
## cruise camera, so the face the rock shows us is its night side: measured at 0.12 luma against a
## 0.08-0.13 sky (contrast -0.03 to +0.05) for its last second in - a dark hole with a lit rim.
## Raising the toon shader's shadow floor on it changed nothing (p10 0.110 before, 0.111 after). So,
## as on a set, a fill rides on the camera and lights ONLY the rock (CrashAsteroid.FILL_LAYER), its
## energy tied to the sun's. TUNED BY MEASUREMENT, not derived: a third of the sun's energy (the
## textbook 3:1 key-to-fill) was a no-op on Forward+ - the face stayed at 0.12-0.13 luma, because an
## omni's energy lands far weaker in this shader than the directional sun's. 3x puts the face at
## 0.32-0.35 luma on Forward+ and 0.36-0.38 on Compatibility (~0.09 linear against ~0.22 on the sunlit
## crescent, about 2.5:1 on the frame), with nothing blown (face p90 <= 0.64).
const FILL_RATIO := 3.0
## Where on the hull it lands: this far up the axis from the centre (the tip is 1.65 m up), pushed
## out toward the rock by about the cone's radius there - the front of the nose.
const CONTACT_UP_NOSE := 1.25
const CONTACT_OFF := 0.34
## The lurch: a 0.9 m shove that peaks 0.12 s after the hit and dies away (the camera ignores it).
const LURCH_M := 0.9
const LURCH_TAU := 0.12
## Tumble rate: 560 deg/s right after the bonk decaying over 1.1 s onto a lazy 150 deg/s - about
## five comic turns across the fall. A wobble about the flight axis keeps it from looking like a
## flat pinwheel.
const TUMBLE_W0_DEG := 560.0
const TUMBLE_TAU := 1.1
const TUMBLE_W1_DEG := 150.0
const TUMBLE_WOBBLE := 0.35
const SQUASH_HIT := 0.10
const SQUASH_TD := 0.15
## Damage smoke runs over this window after the bonk (the engine's cough, HIT_T to +1.3 s).
const SMOKE_WINDOW := Vector2(0.05, 1.0)
const SHAKE_HIT := Vector2(0.075, 0.55)
const SHAKE_TD := Vector2(0.05, 0.45)
const CHIPS := 5
## How long the contact flash burns (its own scale curve dies at this age - see `_update_fx`). The
## finish's clean-to-rusty repaint (see "THE FINISH" above) is spread over the same window, one stage
## at a time, rather than one swap: measured (round 1) a single swap at the hit put full rust patches
## over most of the hull one frame before the flash - a small disc AT the contact point, not over the
## hull - had grown big enough to cover any of it (f00000267 of a 30 fps capture, default renderer).
const FLASH_LIFE := 0.28

# ------------------------------------------------------------------------------------ the fall
## Hermite slopes of the fall's progress curve: leave at half the mean rate (the bump carries it),
## arrive at a tenth - which comes out near 2 m/s at the hover point, the speed the drop starts at.
const FALL_M0 := 0.5
const FALL_M1 := 0.1
## The camera's target eases from the cruise line onto the fall path with this time constant.
const CAM_CATCHUP := 0.35
## Chase framing during the fall (metres behind along the path, up, left of screen).
const FALL_BACK := 12.0
const FALL_UP := 3.0
const FALL_SIDE := 2.5
const CHASE_BLEND := Vector2(HIT_T + 0.3, HIT_T + 2.2)
## The camera settles into the landing vantage over this window.
const LAND_BLEND := Vector2(FALL_END_T - 3.0, FALL_END_T + 0.3)
## Ship centre height above its parked centre at the end of the fall (the righting hover).
const HOVER_H := 4.5
## Bounces after the thump: [seconds, metres].
const BOUNCES := [[0.42, 0.50], [0.24, 0.14]]
const WOBBLE_DEG := 8.0
const WOBBLE_HZ := 1.7
const WOBBLE_TAU := 0.55
## Sky and rocket both cross from space back to ground over these altitudes (metres above R).
const SPACE_ALT := Vector2(18.0, 110.0)
const LOOK_ALT := Vector2(14.0, 70.0)
## Never let the chase camera inside a hill (rocket_pad.gd CAM_GROUND_CLEAR).
const CAM_GROUND_CLEAR := 2.6

# ------------------------------------------------------------------------------------ the exit
## Where the astronaut lands: the first hop comes down HOP_MID_M from the pad centre (round 2's one
## and only hop), the second carries on to `_exit_distance` - just outside the pad's Fly zone, which
## round 2 left them inside: the "E Fly" prompt was up at the hand-off, and on a phone the big button
## read "Fly" through the move and scrap hints, one tap from opening the destination card. Both lie
## at one of HOP_ANGLES off the hatch line (see `_choose_landing_spot`; 0 is excluded because the FLY
## gateway stands on it).
const HOP_MID_M := 3.0
const HOP_ANGLES: Array[float] = [-45.0, 45.0, -30.0, 30.0, -60.0, 60.0, -75.0, 75.0]
## The feet end at least this far outside the pad Interactable's reach (player.gd
## `_update_interact_target` measures feet to the Interactable's origin), searched out to EXIT_MAX_M.
const REACH_MARGIN := 0.35
const EXIT_MIN_M := 3.6
const EXIT_MAX_M := 6.5
## Every sight-line in the hand-off must clear the pad's posts, plate, console and mast by this.
const MIN_CLEAR := 0.5
## Then turns this far from facing the rocket: 65 deg puts the hull ~20 deg off the rig's axis (in
## frame, to one side) and leaves the way forward clear of it. 55 and 75 are there for when no 65 deg
## candidate keeps the mast clear (below); each 10 deg away from 65 costs a little score.
const LOOK_BACK_DEGS: Array[float] = [65.0, 55.0, 75.0]
## THE BEACON MAST MUST STAND CLEAR OF THE SHIP ON SCREEN, not just out of the sight-lines. Round 2
## tested only what stood between the eye and the ship, and the 7.9 m candy-striped mast stood
## exactly BEHIND the ship's long axis from the landing vantage: it ran straight down out of the
## righting burn's flame, stuck out of the nose up to its beacon through the drop, and rose out of
## the landed rocket through the pop-out and the hand-off - at phone size, one skewered shape
## (critic, f505-f685). So every candidate's whole camera path is flown in `_worst_mast_gap`, and the
## gap between the two silhouettes, in degrees of view, must stay at least MAST_GAP_DEG from the
## landing blend to the end of the shot. 3 deg is ~46 px on a 720 px canvas at FOV 46, and it puts
## the two axes >= ~8.5 deg apart (the critic asked for no overlap and 4-5 deg between them).
const MAST_GAP_DEG := 3.0
## Silhouette half-widths for that test: the ship to its fin tips, the mast to its lamp (the lamp cap
## is 0.34 m, the column 0.16 m at the foot). MAST_H is rocket_pad.gd MAST_TOP 7.6 + the lamp roof.
const SHIP_SIL_R := 0.95
const MAST_SIL_R := 0.25
const MAST_H := 7.9
## The landing vantage: the rig's own eye, pulled back and up so the drop and bounces fit.
const LAND_CAM_BACK := 1.8
const LAND_CAM_UP := 1.4

## rocket_pad.gd's in-space rocket look (SPACE_FLAME_INTENSITY / GROUND_FLAME_INTENSITY /
## SPACE_LIGHT_RANGE), so this rocket in space looks like the one the journey flies.
const SPACE_FLAME := 0.30
const GROUND_FLAME := 1.15
const SPACE_LIGHT_RANGE := 0.16

## [start, end, text]. Timed so each types (40 chars/s) and is read before the next; <= 60 chars.
## "Look out!" is typed by 5.38 - as the rock first shows in a 16:9 frame - and gone (RadioCaption
## PANEL_FADE 0.22 s) by 6.32, so the rock's last 0.7 s and the bonk play on a clear frame whatever
## the caption's size: round 2 held it to 7.2 and on a phone the bonk happened under it.
const CAPTIONS := [
	[-1.5, 1.3, "Professor Comet to the survey ship. Do you read?"],
	[1.6, 4.0, "Lovely clear sky tonight. Not a pebble in sight."],
	[4.3, 6.1, "Hang on, what's that on my scope? Look out!"],
	# From 7.95, not 7.6: the first fast spin swings the nose up to the phone caption's bottom edge
	# at 7.8-7.9 (measured 0.015 of frame height under it at 1404x648), and this lets that pass first.
	[7.95, 10.3, "Bonk! Oh dear, you're spinning like a top!"],
	[10.6, 13.3, "Hold tight! Aim for that little green planet!"],
	[13.6, 15.4, "Nose up! Nose up!"],
]
const SKIP_ACTIONS: PackedStringArray = ["interact", "ui_accept", "jump", "cancel", "pause"]

var _planet: Planet
var _pad: Node3D
var _rocket: RocketModel
var _player: Player
var _rig: CameraRig
var _env: Node
var _cam: Camera3D
var _captions: RadioCaption
var _asteroid: CrashAsteroid
var _fill: OmniLight3D
var _sun: DirectionalLight3D
var _sparks: GPUParticles3D
var _flash: MeshInstance3D
var _smoke: GPUParticles3D
var _wisp: GPUParticles3D
var _dust: GPUParticles3D
var _chips: Array[MeshInstance3D] = []
var _chip_vel: Array[Vector3] = []
var _chip_spin: Array[Vector3] = []

var _t := -CARD_SECONDS
var _running := false
var _done := false
var _skipping := false
var _modal := false
var _fired: Dictionary = {}
var _caption_on := -1
## Read once, at the hit, and held: what the finish is stepping down to (see "THE FINISH" above). -1
## before the hit, so `_update_fx` knows not to touch the finish yet.
var _end_finish_stage := -1
var _after := 0.0
var _skip_held: Dictionary = {}
var _skip_primed := false

# geometry, fixed at _begin
var _rest := Transform3D.IDENTITY
var _rest_q := Quaternion.IDENTITY
var _pad_up := Vector3.UP
var _up_l := Vector3.UP
var _land_dir := Vector3.UP
var _land_pos := Vector3.ZERO
var _hop_dir := Vector3.FORWARD
var _face := Vector3.FORWARD
var _b := Vector3.FORWARD
var _s := Vector3.RIGHT
var _wobble_axis := Vector3.RIGHT
var _offset_c := Vector3.ZERO
var _cruise_origin := Vector3.ZERO
var _p0 := Vector3.ZERO
var _p1 := Vector3.ZERO
var _p2 := Vector3.ZERO
var _p3 := Vector3.ZERO
var _hover_speed := 2.0
var _hit_basis := Basis.IDENTITY
var _contact := Vector3.ZERO
var _contact_n := Vector3.UP
var _kick_dir := Vector3.ZERO
var _ast_hit_pos := Vector3.ZERO
var _ast_bounce := Vector3.ZERO
var _ast_axis := Vector3.UP
var _hop_from := Vector3.ZERO
var _hop_mid := Vector3.ZERO
var _hop_to := Vector3.ZERO
var _ast_rel_from := Vector3.ZERO
var _mast_base := Vector3.ZERO
var _mast_top := Vector3.ZERO
var _has_mast := false
var _pad_interact: Node3D
var _rig_eye := Vector3.ZERO
var _rig_pivot := Vector3.ZERO
var _land_eye := Vector3.ZERO
var _music := ""

var _trace: FileAccess
var _trace_frame := 0
## True on a measurement run (`--crash-trace=`): also logs every landing candidate's numbers.
var _trace_on := false


func _ready() -> void:
	# Before the environment (0) and the rig (10): the sky reads the camera's position in its own
	# _process, and a camera moved after it would leave the neighbouring worlds a frame behind -
	# 1.7 m at the fall's peak speed, a visible swim at 140 m.
	process_priority = -5
	set_process(false)
	call_deferred("_begin")


## Deferred so world.gd has finished building (and played its music) before we take over.
func _begin() -> void:
	var world := get_node_or_null("/root/World")
	if world != null:
		_planet = world.get_node_or_null("Planet") as Planet
		_pad = world.get_node_or_null("Rocket") as Node3D
		_rig = world.get_node_or_null("CameraRig") as CameraRig
		_env = world.get_node_or_null("Environment")
	if _pad != null:
		_rocket = _pad.get("rocket") as RocketModel
	_player = get_tree().get_first_node_in_group("player") as Player
	if _planet == null or _rocket == null or _player == null or _rig == null or _rig.get_camera() == null:
		# Never strand anybody on a missing piece: no shot, straight to the radio call.
		push_warning("CrashIntro: world is missing a piece (planet/rocket/player/rig); skipping the crash.")
		_done = true
		finished.emit(false)
		queue_free()
		return
	_modal = true
	EventBus.ui_modal_opened.emit("cutscene")
	for a in OS.get_cmdline_user_args():
		_trace_on = _trace_on or a.begins_with("--crash-trace=")
	_freeze_player()
	_solve_geometry()
	_build_nodes()
	_music = _planet.data.music_track if _planet.data != null else ""
	AudioManager.play_music("space", 0.8)
	_rocket.set_ladder_deployed(false)
	_rocket.set_engine(true, 0.7)
	_rocket.set_flame_scale(0.55)
	# Clean for the card and the cruise (the user: "normal / clean looking before it hits the
	# asteroid"); rocket_pad.gd has already painted CampaignData.finish_stage() (0, rusty, on a new
	# game) by the time this node runs, so this overrides it. The hit swaps it back (_update_fx).
	_rocket.set_finish_stage(RocketModel.FINISH_CLEAN)
	_open_trace()
	_log("begin card=%.2fs hit=%.2f td=%.2f end=%.2f" % [CARD_SECONDS, HIT_T, TD_T, END_T])
	_running = true
	set_process(true)
	_step(0.0)


# ============================================================================= geometry
func _solve_geometry() -> void:
	_rest = _rocket.global_transform
	_rest_q = _rest.basis.orthonormalized().get_rotation_quaternion()
	_pad_up = _planet.data.pad_dir.normalized() if _planet.data != null else _rest.basis.y.normalized()
	# The hatch is on the model's -Z (rocket_model.gd header); the pad turns it toward the spawn.
	var hatch := -_rest.basis.z
	hatch = hatch - _pad_up * hatch.dot(_pad_up)
	if hatch.length_squared() < 1e-6:
		hatch = _pad_up.cross(Vector3.RIGHT)
	hatch = hatch.normalized()
	_find_pad_pieces()
	_choose_landing_spot(hatch)


## Everything that follows from where the astronaut ends up: the flight frame (the landing spot's
## facing is "toward home" in the cruise, so the fall brings the ship down the right way round), the
## cruise and fall paths, the hit, and the hop. `_choose_landing_spot` runs it once per candidate.
func _solve_path() -> void:
	_b = _face
	_s = _b.cross(_up_l).normalized()
	_wobble_axis = _tangent(_s, _pad_up, _b.cross(_pad_up))
	var elev := deg_to_rad(CRUISE_ELEV_DEG)
	var cam_hit := (-_b * cos(elev) + _up_l * sin(elev)) * CRUISE_DIST
	_offset_c = -_b * CRUISE_BACK + _up_l * CRUISE_UP - _s * CRUISE_SIDE
	_cruise_origin = cam_hit - _offset_c
	_hit_basis = _cruise_basis(HIT_T)
	_p0 = _cruise_pos(HIT_T)
	# The rock meets the front of the nose from the side it comes in on, so the normal it strikes
	# along is its own approach direction.
	_contact_n = _rel(AST_DIR).normalized()
	_contact = _p0 + _hit_basis.y * CONTACT_UP_NOSE + _contact_n * CONTACT_OFF
	_ast_hit_pos = _contact + _contact_n * CrashAsteroid.RADIUS * 0.95
	_kick_dir = (-_contact_n + _b * 0.2).normalized()
	# It glances back the way it came, a little down and away from the camera, so it never sails up
	# through the caption band either (round 2 bounced it up and to the right).
	_ast_bounce = _s * CRUISE_SPEED + (_contact_n * 0.7 - _up_l * 0.25 + _b * 0.4).normalized() * AST_BOUNCE_SPEED
	_ast_axis = (_up_l * 0.7 + _s * 0.4 + _b * 0.3).normalized()

	var hover := _rest.origin + _pad_up * (SHIP_HALF + HOVER_H)
	var v0 := (_s * 0.45 + _b * 0.8 - _up_l * 0.35).normalized()
	var span := _p0.distance_to(hover)
	_p1 = _p0 + v0 * span * 0.28
	_p2 = hover + _pad_up * span * 0.26 - _b * span * 0.10
	_p3 = hover
	_hover_speed = maxf((3.0 * (_p3 - _p2) * FALL_M1 / FALL_SECONDS).dot(-_pad_up), 0.0)
	_hop_from = _rocket.hatch_point()
	_hop_to = _land_pos + _land_dir * 0.02


## Starts the rock just outside the right edge of a WIDEST_ASPECT frame at ASTEROID_IN_T, on the line
## it will travel - straight in the ship's frame, so its screen path is nearly straight too while the
## camera tracks the ship. A 16:9 frame first shows it a few tenths of a second later, further in.
func _solve_rock() -> void:
	var rel_hit := _ast_hit_pos - _cruise_line(HIT_T)
	var rule := _camera_rule(ASTEROID_IN_T)
	var eye: Vector3 = rule[0]
	var basis := _look_basis(eye, rule[1])
	var tan_v := tan(deg_to_rad(FLIGHT_FOV * 0.5))
	var line_in := _cruise_line(ASTEROID_IN_T)
	var d := 2.0
	while d < 60.0:
		var local := basis.transposed() * (line_in + rel_hit + _contact_n * d - eye)
		if local.z < -0.5:
			var half_w := -local.z * tan_v * WIDEST_ASPECT
			if (local.x - CrashAsteroid.RADIUS * 1.3) / half_w >= 1.0:
				break
		d += 0.1
	_ast_rel_from = rel_hit + _contact_n * d
	_log("rock: starts %.1f m out along its line, %.1f m/s relative to the ship" % [d, d / (HIT_T - ASTEROID_IN_T)])


## WHERE THE ASTRONAUT STANDS WHEN CONTROL COMES BACK - chosen, not assumed.
##
## Round 1 hopped straight out of the hatch and the hand-off frame put the FLY sign's right post
## through the astronaut: rocket_pad.gd `_build_sign` stands that gateway 4.1 m out along exactly
## that line with posts 1.34 m either side, and the rig 6.5 m behind looked straight through it.
## Round 2 stood the 7.9 m beacon mast straight up out of the rocket's nose (MAST_GAP_DEG). So each
## LOOK_BACK_DEGS x HOP_ANGLES x (left, right) candidate - 48 of them - is FLOWN: the hidden
## astronaut is placed, the rig is snapped behind them (reseat_behind_player sets the camera
## transform at once), the whole cruise-fall-landing path is solved for that spot, and then
##   - five sight-lines must clear the pad's posts, plate, console and mast by MIN_CLEAR: rig eye to
##     the astronaut, landing vantage to the landed and the hovering rocket, and both hops;
##   - the mast's silhouette must stay MAST_GAP_DEG clear of the ship's all the way from the landing
##     blend to the end of the shot, measured from the camera the shot will actually fly.
## Of the candidates that pass both, the one with the sun most behind the camera wins (a sunlit
## hand-off frame, and from space the face of home we fall toward is the lit one). On home at a new
## game's 10 am only 2-3 of the 48 pass, all with the sun off to the side (hence the rock's fill,
## FILL_RATIO). 37-39 ms, once, under the opaque card (measured, desktop and phone).
func _choose_landing_spot(hatch: Vector3) -> void:
	var t0 := Time.get_ticks_usec()
	var sun := Vector3.UP
	if _env != null and _env.has_method("get_sun_direction"):
		sun = (_env.call("get_sun_direction") as Vector3).normalized()
	var obstacles := _pad_obstacles()
	var rocket_mid := _rest.origin + _pad_up * (SHIP_HALF * 0.9)
	# The ship also hangs HOVER_H above the pad for the righting burn, seen from nearly the same
	# vantage; round 2's frames had the beacon mast across the hull there for about a second.
	var hover_mid := _rest.origin + _pad_up * (SHIP_HALF + HOVER_H)
	var best: Dictionary = {}
	var best_score := -INF
	var n := 0
	var n_ok := 0
	for lb: float in LOOK_BACK_DEGS:
		for a_deg: float in HOP_ANGLES:
			var hd := hatch.rotated(_pad_up, deg_to_rad(a_deg))
			var toward := (_pad_up + hd * 0.5).normalized()
			var exit_m := _exit_distance(toward)
			var ldir := _planet.step_dir(_pad_up, toward, exit_m)
			var lpos := _planet.surface_point(ldir)
			var mdir := _planet.step_dir(_pad_up, toward, HOP_MID_M)
			var mpos := _planet.surface_point(mdir) + mdir * 0.02
			var hop := _tangent(lpos - _rest.origin, ldir, hd)
			for sgn: float in [1.0, -1.0]:
				var face := (-hop).rotated(ldir, sgn * deg_to_rad(lb))
				var c := {"ldir": ldir, "lpos": lpos, "mid": mpos, "hop": hop, "face": face,
					"a": a_deg, "sgn": sgn, "lb": lb, "exit": exit_m}
				_apply_candidate(c)
				var lift := mdir * 0.5
				var clear := minf(minf(_clearance(_rig_eye, _rig_pivot, obstacles, false),
					_clearance(_land_eye, rocket_mid, obstacles, true)),
					minf(minf(_clearance(_land_eye, hover_mid, obstacles, true),
					_clearance(_rocket.hatch_point(), mpos + lift, obstacles, true)),
					_clearance(mpos + lift, lpos + ldir * 0.5, obstacles, true)))
				var gap := _worst_mast_gap()
				var ok := clear >= MIN_CLEAR and gap >= MAST_GAP_DEG
				var score := (10.0 if clear >= MIN_CLEAR else 0.0) + (10.0 if gap >= MAST_GAP_DEG else 0.0) \
					- face.dot(sun) - absf(lb - LOOK_BACK_DEGS[0]) * 0.03 \
					+ clampf(clear, 0.0, 2.0) * 0.25 + clampf(gap, -5.0, 10.0) * 0.05
				n += 1
				if ok:
					n_ok += 1
				if _trace_on:
					_log("  candidate lb %2.0f hop %+4.0f side %+2.0f: out %.2f m clear %+.2f gap %+5.1f sun %+.2f score %.2f" % [
						lb, a_deg, sgn, exit_m, clear, gap, -face.dot(sun), score])
				if score > best_score:
					best_score = score
					c["clear"] = clear
					c["gap"] = gap
					best = c
	_apply_candidate(best)
	_solve_rock()
	_log("landing spot: %d of %d candidates pass; hop %+.0f deg off the hatch line to %.2f m out, facing %+.0f deg from the rocket; sight-lines clear by %.2f m, mast gap >= %.1f deg (%.0f ms)" % [
		n_ok, n, float(best["a"]), float(best["exit"]), float(best["sgn"]) * float(best["lb"]),
		float(best["clear"]), float(best["gap"]), float(Time.get_ticks_usec() - t0) / 1000.0])


## Puts the astronaut and the rig where candidate `c` says, and solves the shot for it.
func _apply_candidate(c: Dictionary) -> void:
	_land_dir = c["ldir"]
	_up_l = _land_dir
	_land_pos = c["lpos"]
	_hop_mid = c["mid"]
	_hop_dir = c["hop"]
	_face = c["face"]
	_place_player(_face, 0.02)
	_rig.reseat_behind_player()
	_read_rig()
	_solve_path()


## The pad's beacon mast and its Fly zone, found by the node names rocket_pad.gd gives them
## ("Pad/BeaconMast", "Pad/Interactable"). A missing piece is simply not tested.
func _find_pad_pieces() -> void:
	var root := _pad.get_node_or_null("Pad")
	if root == null:
		return
	var mast := root.get_node_or_null("BeaconMast") as Node3D
	if mast != null:
		_mast_base = mast.global_position
		_mast_top = _mast_base + _pad_up * MAST_H
		_has_mast = true
	_pad_interact = root.get_node_or_null("Interactable") as Node3D


## Metres along the surface from the pad centre (toward `toward`) at which the astronaut's feet are
## REACH_MARGIN outside the pad's Fly zone. Solved against the live Interactable - rocket_pad.gd puts
## it 0.9 m above the deck centre with a 4.2 m reach today, which comes out at ~4.4 m.
func _exit_distance(toward: Vector3) -> float:
	if _pad_interact == null or not ("reach" in _pad_interact):
		return EXIT_MIN_M
	var need := float(_pad_interact.get("reach")) + REACH_MARGIN
	var at := _pad_interact.global_position
	var m := EXIT_MIN_M
	while m < EXIT_MAX_M:
		if _planet.surface_point(_planet.step_dir(_pad_up, toward, m)).distance_to(at) >= need:
			return m
		m += 0.1
	return EXIT_MAX_M


## The smallest mast-to-ship silhouette gap (deg) over the current candidate's camera path, every
## 0.25 s from the start of the landing blend to the end of the shot: the ship where `_rocket_xf`
## puts it, the eye where `_camera_rule` does (and the rig's own eye from the hand-off on).
func _worst_mast_gap() -> float:
	if not _has_mast:
		return INF
	var worst := INF
	var t := LAND_BLEND.x
	while t <= END_T + 1e-3:
		var eye: Vector3 = _rig_eye if t >= HANDOFF_T else (_camera_rule(t)[0] as Vector3)
		worst = minf(worst, _mast_gap(eye, _rocket_xf(t)))
		t += 0.25
	return worst


func _mast_gap(eye: Vector3, ship: Transform3D) -> float:
	var top := ship.origin + ship.basis.y * RocketModel.TOTAL_HEIGHT
	return _silhouette_gap_deg(eye, ship.origin, top, SHIP_SIL_R, _mast_base, _mast_top, MAST_SIL_R)


## The gap between two capsules' silhouettes seen from `eye`, in degrees of view: the angular
## distance between the segments a0-a1 and b0-b1, less each one's angular half-width. Below zero they
## overlap on screen. Framing- and aspect-independent: it is about directions from the eye, not
## pixels. Each sample point is measured exactly against the other segment's arc on the view sphere.
static func _silhouette_gap_deg(eye: Vector3, a0: Vector3, a1: Vector3, ra: float,
		b0: Vector3, b1: Vector3, rb: float) -> float:
	var best := INF
	for i in 17:
		var f := float(i) / 16.0
		best = minf(best, _point_arc_gap(eye, a0.lerp(a1, f), ra, b0, b1, rb))
		best = minf(best, _point_arc_gap(eye, b0.lerp(b1, f), rb, a0, a1, ra))
	return best


static func _point_arc_gap(eye: Vector3, p: Vector3, rp: float, s0: Vector3, s1: Vector3, rs: float) -> float:
	var d := p - eye
	var dl := d.length()
	var u0 := s0 - eye
	var u1 := s1 - eye
	var l0 := u0.length()
	var l1 := u1.length()
	if dl < 1e-3 or l0 < 1e-3 or l1 < 1e-3:
		return -90.0
	d /= dl
	u0 /= l0
	u1 /= l1
	var ang := minf(d.angle_to(u0), d.angle_to(u1))
	var depth := l0 if d.angle_to(u0) < d.angle_to(u1) else l1
	var nrm := u0.cross(u1)
	if nrm.length_squared() > 1e-12:
		nrm = nrm.normalized()
		var c := d - nrm * d.dot(nrm)
		if c.length_squared() > 1e-12:
			c = c.normalized()
			var span := u0.angle_to(u1)
			var c0 := c.angle_to(u0)
			if c0 <= span + 1e-5 and c.angle_to(u1) <= span + 1e-5:
				ang = asin(clampf(absf(d.dot(nrm)), 0.0, 1.0))
				depth = lerpf(l0, l1, c0 / maxf(span, 1e-5))
	return rad_to_deg(ang - atan(rp / dl) - atan(rs / maxf(depth, 0.01)))


## The pad's tall pieces as upright cylinders [base, up, height, radius, is_rocket], found by the node
## names rocket_pad.gd gives them ("Pad/FlySign/Post-1", "ControlPost", "BeaconMast"). A missing one
## is simply not tested - the rocket itself always is.
func _pad_obstacles() -> Array:
	var out: Array = [[_rest.origin, _pad_up, 3.3, 0.85, true]]
	var root := _pad.get_node_or_null("Pad")
	if root == null:
		return out
	for n: String in ["FlySign/Post-1", "FlySign/Post1"]:
		var post := root.get_node_or_null(n) as Node3D
		if post != null:
			out.append([post.global_position - _pad_up * 1.45, _pad_up, 3.0, 0.14, false])
	var sign_node := root.get_node_or_null("FlySign") as Node3D
	if sign_node != null:
		# The plate slung between the posts, 2.05-2.95 m up and 1.24 m wide.
		out.append([sign_node.global_position + _pad_up * 2.05, _pad_up, 0.9, 0.66, false])
	var console := root.get_node_or_null("ControlPost") as Node3D
	if console != null:
		out.append([console.global_position, _pad_up, 1.65, 0.42, false])
	var mast := root.get_node_or_null("BeaconMast") as Node3D
	if mast != null:
		out.append([mast.global_position, _pad_up, 7.9, 0.28, false])
	return out


## Smallest gap (metres) between the segment a-b and any obstacle's surface, sampled at 17 points.
static func _clearance(a: Vector3, b: Vector3, obstacles: Array, skip_rocket: bool) -> float:
	var best := INF
	for o: Array in obstacles:
		if skip_rocket and bool(o[4]):
			continue
		var base: Vector3 = o[0]
		var up: Vector3 = o[1]
		for i in 17:
			var v := a.lerp(b, float(i) / 16.0) - base
			var along := v.dot(up)
			if along < 0.0 or along > float(o[2]):
				continue
			best = minf(best, (v - up * along).length() - float(o[3]))
	return best


## The rig's eye and pivot, re-read while the rig is parked (it settles its terrain lift over the
## first frames after the snap).
func _read_rig() -> void:
	var cam := _rig.get_camera()
	_rig_eye = cam.global_position
	_rig_pivot = _player.global_position + _up_l * CameraRig.PIVOT_HEIGHT
	var back := _tangent(_rig_eye - _rig_pivot, _up_l, -_face)
	_land_eye = _rig_eye + back * LAND_CAM_BACK + _up_l * LAND_CAM_UP


## `v` flattened onto the tangent plane of `up` and normalised; `fallback` if it degenerates.
static func _tangent(v: Vector3, up: Vector3, fallback: Vector3) -> Vector3:
	var t := v - up * v.dot(up)
	if t.length_squared() < 1e-8:
		t = fallback - up * fallback.dot(up)
	if t.length_squared() < 1e-8:
		return up.cross(Vector3.RIGHT).normalized()
	return t.normalized()


## (screen right, up, toward home) -> world.
func _rel(v: Vector3) -> Vector3:
	return _s * v.x + _up_l * v.y + _b * v.z


# ============================================================================= the ship's path
func _cruise_line(t: float) -> Vector3:
	return _cruise_origin + _s * CRUISE_SPEED * (t - HIT_T)


func _cruise_pos(t: float) -> Vector3:
	return _cruise_line(t) + _up_l * BOB_M * sin(t * TAU * BOB_HZ)


func _cruise_basis(t: float) -> Basis:
	var nu := deg_to_rad(CRUISE_NOSE_UP_DEG + 1.5 * sin(t * 1.1))
	var nose := (_s * cos(nu) + _up_l * sin(nu)).normalized()
	var b := _nose_basis(nose, -_b)
	return Basis(nose, deg_to_rad(3.0) * sin(t * 1.3)) * b


## Rocket basis with its nose (+Y) along `nose` and its hatch (-Z) toward `face`.
static func _nose_basis(nose: Vector3, face: Vector3) -> Basis:
	var y := nose.normalized()
	var f := face - y * face.dot(y)
	if f.length_squared() < 1e-8:
		f = y.cross(Vector3.RIGHT)
	var z := -f.normalized()
	var x := y.cross(z).normalized()
	return Basis(x, y, z)


## Hermite progress along the fall: k(0)=0, k(1)=1, k'(0)=FALL_M0, k'(1)=FALL_M1.
static func _fall_k(u: float) -> float:
	var x := clampf(u, 0.0, 1.0)
	var x2 := x * x
	var x3 := x2 * x
	return (x3 - 2.0 * x2 + x) * FALL_M0 + (-2.0 * x3 + 3.0 * x2) + (x3 - x2) * FALL_M1


func _fall_pos(t: float) -> Vector3:
	var k := _fall_k((t - HIT_T) / FALL_SECONDS)
	var pos := _p0.bezier_interpolate(_p1, _p2, _p3, k)
	var floor_r := _planet.height_at(pos.normalized()) + SHIP_HALF + 0.6
	if pos.length() < floor_r:
		pos = pos.normalized() * floor_r
	return pos


func _fall_tangent(t: float) -> Vector3:
	var d := _fall_pos(minf(t + 0.03, FALL_END_T)) - _fall_pos(maxf(t - 0.03, HIT_T))
	if d.length_squared() < 1e-8:
		return -_pad_up
	return d.normalized()


func _lurch(tau: float) -> Vector3:
	if tau <= 0.0:
		return Vector3.ZERO
	var x := tau / LURCH_TAU
	return _kick_dir * LURCH_M * x * exp(1.0 - x)


func _tumble_basis(t: float) -> Basis:
	var tau := maxf(t - HIT_T, 0.0)
	var phi := deg_to_rad(TUMBLE_W0_DEG) * TUMBLE_TAU * (1.0 - exp(-tau / TUMBLE_TAU)) \
		+ deg_to_rad(TUMBLE_W1_DEG) * tau
	var wob := TUMBLE_WOBBLE * sin(tau * 1.3) * minf(tau / 0.6, 1.0)
	var b := Basis(_b, phi) * Basis(_s, wob) * _hit_basis
	var w := smoothstep(FALL_END_T - RIGHTING_SECONDS, FALL_END_T, t)
	if w > 0.0:
		b = Basis(b.orthonormalized().get_rotation_quaternion().slerp(_rest_q, w))
	return b.orthonormalized()


## Height of the ship's base above the deck after the fall: the drop (starting at the fall's own
## arrival speed, so there is no hitch), then the bounces.
func _land_height(t: float) -> float:
	var tau := t - FALL_END_T
	if tau < DROP_SECONDS:
		var a := 2.0 * (HOVER_H - _hover_speed * DROP_SECONDS) / (DROP_SECONDS * DROP_SECONDS)
		return maxf(HOVER_H - _hover_speed * tau - 0.5 * a * tau * tau, 0.0)
	tau -= DROP_SECONDS
	for bounce: Array in BOUNCES:
		var dur: float = bounce[0]
		if tau < dur:
			return float(bounce[1]) * sin(PI * tau / dur)
		tau -= dur
	return 0.0


static func _squash(tau: float, amp: float) -> float:
	if tau < 0.0:
		return 0.0
	return amp * exp(-tau / 0.16) * cos(tau * TAU / 0.32)


## The rocket's world transform at shot time `t`.
func _rocket_xf(t: float) -> Transform3D:
	if t <= HIT_T:
		var b := _cruise_basis(t)
		return Transform3D(b, _cruise_pos(t) - b.y * SHIP_HALF)
	if t <= FALL_END_T:
		var c := _fall_pos(t) + _lurch(t - HIT_T)
		var b := _tumble_basis(t)
		var sq := _squash(t - HIT_T, SQUASH_HIT)
		var scaled := Basis(b.x * (1.0 + sq * 0.5), b.y * (1.0 - sq), b.z * (1.0 + sq * 0.5))
		return Transform3D(scaled, c - b.y * (1.0 - sq) * SHIP_HALF)
	var settle := TD_T + SETTLE_SECONDS
	if t >= settle:
		return _rest
	var h := _land_height(t)
	var tau := t - TD_T
	var tilt := 0.0
	var sq2 := 0.0
	if tau > 0.0:
		var fade := 1.0 - smoothstep(settle - 0.4, settle, t)
		tilt = deg_to_rad(WOBBLE_DEG) * exp(-tau / WOBBLE_TAU) * sin(TAU * WOBBLE_HZ * tau) * fade
		sq2 = _squash(tau, SQUASH_TD) * fade
	var rb := Basis(_rest_q)
	var b2 := Basis(_wobble_axis, tilt) * rb
	var scaled2 := Basis(b2.x * (1.0 + sq2 * 0.5), b2.y * (1.0 - sq2), b2.z * (1.0 + sq2 * 0.5))
	return Transform3D(scaled2, _rest.origin + _pad_up * h)


func _ship_centre(t: float) -> Vector3:
	var xf := _rocket_xf(t)
	return xf.origin + xf.basis.y.normalized() * SHIP_HALF


# ============================================================================= the camera
## [eye, look point] from the framing rules, before the hand-back blend.
func _camera_rule(t: float) -> Array:
	var line := _cruise_line(t)
	if t > HIT_T:
		var fall := _fall_pos(t)
		line = fall + (line - fall) * exp(-(t - HIT_T) / CAM_CATCHUP)
	var off := _offset_c
	var w_ch := smoothstep(CHASE_BLEND.x, CHASE_BLEND.y, t)
	if w_ch > 0.0:
		var tan := _fall_tangent(t)
		off = _offset_c.lerp(-tan * FALL_BACK + _up_l * FALL_UP - _s * FALL_SIDE, w_ch)
	var eye := line + off
	var floor_r := _planet.height_at(eye.normalized()) + CAM_GROUND_CLEAR
	if eye.length() < floor_r:
		eye = eye.normalized() * floor_r
	var to_ship := (line - eye).normalized()
	var alt := line.length() - _planet.radius
	var wp := LOOK_PLANET_W * smoothstep(LOOK_PLANET_ALT.x, LOOK_PLANET_ALT.y, alt)
	var dir := (to_ship * (1.0 - wp) + (-eye).normalized() * wp).normalized()
	var off_deg := rad_to_deg(acos(clampf(dir.dot(to_ship), -1.0, 1.0)))
	if off_deg > KEEP_SHIP_DEG:
		dir = to_ship.slerp(dir, KEEP_SHIP_DEG / off_deg).normalized()
	var look := eye + dir * 12.0

	var w_l := smoothstep(LAND_BLEND.x, LAND_BLEND.y, t)
	if w_l > 0.0:
		eye = eye.lerp(_land_eye, w_l)
		look = look.lerp(_aim_point(t), w_l)
	# Whatever the blends did, the ship stays in frame until the astronaut takes over. Round 1 aimed
	# the landing blend at the hover point while the ship was still ~20 m above it, and measured the
	# ship's centre 7% from the top edge at T 13.9 - half the hull out of frame.
	if t < POP_T:
		look = _keep_in_frame(eye, look, _aim_point(t))
	var w_p := smoothstep(POP_T - 0.2, POP_END_T + 0.45, t)
	if w_p > 0.0:
		eye = eye.lerp(_rig_eye, w_p)
		look = look.lerp(_rig_pivot, w_p)
	return [eye, look]


## Where the camera keeps the ship: its path WITHOUT the lurch (so the bonk visibly shoves it) and
## without the bounces (so the camera does not bob with them).
func _aim_point(t: float) -> Vector3:
	if t <= HIT_T:
		return _cruise_line(t)
	if t <= FALL_END_T:
		return _fall_pos(t)
	# The aim EASES down after the drop instead of tracking it: tracked exactly, it stopped dead on
	# the thump (2.2 deg of turn in the touchdown frame, then nothing). This lags the 0.45 s fall a
	# little and settles DROP_FOLLOW after it, like an operator catching the landing. At FALL_END_T
	# it equals the fall's end point, so the hand-over between the two rules is continuous.
	var k := smoothstep(FALL_END_T, TD_T + DROP_FOLLOW, t)
	return _rest.origin + _pad_up * (SHIP_HALF + HOVER_H * (1.0 - k))


## Turns `look` toward `target` just enough that the target sits within KEEP_SHIP_DEG of the view
## axis. Continuous: inside the cone it changes nothing.
func _keep_in_frame(eye: Vector3, look: Vector3, target: Vector3) -> Vector3:
	var reach := maxf((look - eye).length(), 0.5)
	var dir := (look - eye).normalized()
	var to := (target - eye).normalized()
	var off := rad_to_deg(acos(clampf(dir.dot(to), -1.0, 1.0)))
	if off <= KEEP_SHIP_DEG:
		return look
	return eye + to.slerp(dir, KEEP_SHIP_DEG / off).normalized() * reach


func _look_basis(eye: Vector3, look: Vector3) -> Basis:
	var fwd := look - eye
	if fwd.length_squared() < 1e-8:
		fwd = _b
	fwd = fwd.normalized()
	var up := _up_l if absf(fwd.dot(_up_l)) < 0.985 else _b
	return Basis.looking_at(fwd, up)


func _place_camera(t: float) -> void:
	var rule := _camera_rule(t)
	var eye: Vector3 = rule[0]
	var look: Vector3 = rule[1]
	var xf := Transform3D(_look_basis(eye, look), eye)
	var fov := FLIGHT_FOV
	if t >= HANDOFF_T:
		var rc := _rig.get_camera()
		var k := smoothstep(0.0, 1.0, (t - HANDOFF_T) / HANDBACK_SECONDS)
		var q := xf.basis.get_rotation_quaternion().slerp(rc.global_basis.get_rotation_quaternion(), k)
		xf = Transform3D(Basis(q), xf.origin.lerp(rc.global_position, k))
		fov = lerpf(FLIGHT_FOV, rc.fov, k)
	_cam.global_transform = xf
	_cam.fov = fov
	var shake := _shake(t, HIT_T, SHAKE_HIT) + _shake(t, TD_T, SHAKE_TD)
	_cam.h_offset = shake.x
	_cam.v_offset = shake.y


## Decaying lens shake, deterministic in `t` (the same noise rocket_pad.gd `_shake_step` uses).
static func _shake(t: float, start: float, spec: Vector2) -> Vector2:
	var tau := t - start
	if tau < 0.0 or tau > spec.y:
		return Vector2.ZERO
	var k := 1.0 - tau / spec.y
	var s := spec.x * k * k
	return Vector2(s * (sin(t * 41.0) * 0.6 + sin(t * 73.3 + 1.7) * 0.4),
		s * (sin(t * 37.5 + 0.9) * 0.6 + sin(t * 89.1) * 0.4))


# ============================================================================= per frame
func _process(delta: float) -> void:
	if _done:
		_after += delta
		if _after >= WISP_TAIL:
			queue_free()
		elif _after >= 3.0 and _wisp != null:
			_wisp.emitting = false
		return
	if not _running or _skipping:
		return
	_step(minf(delta, MAX_STEP))


## THE ACTION HALF OF THE SKIP, for Director timelines: `Input.action_press` sends no InputEvent, so
## `_input` never sees a timeline's tap. And a timeline "tap" is only "just pressed" for nodes that
## process AFTER the Director in that frame (it presses in its _process and releases at the next
## frame's process_frame) - this node runs at priority -5, before it, and round 1's skip tap was
## missed outright: the crash played to the end. The next frame's physics tick runs before that
## release, so an edge on `is_action_pressed` taken here sees every tap. `_skip_primed` swallows a
## key that was already held when the shot began (still down from the title screen, say).
func _physics_process(_delta: float) -> void:
	if not _running or _done or _skipping:
		return
	var edge := false
	for a in SKIP_ACTIONS:
		var now := Input.is_action_pressed(a)
		if now and not bool(_skip_held.get(a, false)) and _skip_primed and _t >= SKIP_ARM_T:
			edge = true
		_skip_held[a] = now
	_skip_primed = true
	if edge:
		_skip()


func _input(event: InputEvent) -> void:
	if not _running or _done or _skipping or _t < SKIP_ARM_T:
		return
	var hit := false
	if event is InputEventKey:
		hit = (event as InputEventKey).pressed and not (event as InputEventKey).echo
	elif event is InputEventMouseButton:
		# Real buttons only. The mouse wheel and trackpad scroll arrive as InputEventMouseButton presses
		# too (MOUSE_BUTTON_WHEEL_*), so without this a two-finger swipe skipped the whole shot. Flagged
		# by builder C's critic; fixed by the lead after C's round closed.
		var mb := event as InputEventMouseButton
		hit = mb.pressed and mb.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]
	elif event is InputEventScreenTouch:
		hit = (event as InputEventScreenTouch).pressed
	elif event is InputEventJoypadButton:
		hit = (event as InputEventJoypadButton).pressed
	if hit:
		get_viewport().set_input_as_handled()
		_skip()


func _step(dt: float) -> void:
	_t += dt
	var t := _t
	if t >= END_T:
		_complete(false)
		return
	# While the card is up the rig still owns the view (see the header); take over under it, a few
	# frames BEFORE it starts to lift, so the switch lands on a fully opaque card. (Switching at
	# t >= 0 measured card opacity 0.998 on the switch frame: a sliver of the new view showed.)
	if t >= -CAM_SWITCH_LEAD and not _cam.current:
		_cam.current = true
		_log("reveal: flight camera current")
	if t < POP_T - 0.25:
		_read_rig()

	var xf := _rocket_xf(t)
	_rocket.global_transform = xf
	_update_engine(t)
	var centre := xf.origin + xf.basis.y.normalized() * SHIP_HALF
	var ralt := centre.length() - _planet.radius
	# 1 = the space look, high up. (Round 1 had this inverted: the rocket cruised through space in
	# its ground look, trailing exhaust smoke - visible as a line of grey puffs in the cruise frames.)
	_rocket_look(smoothstep(LOOK_ALT.x, LOOK_ALT.y, ralt))

	_update_asteroid(t, dt)
	_update_fx(t, dt, xf)
	_update_player(t, dt)
	_place_camera(t)
	if _env != null:
		var calt := _cam.global_position.length() - _planet.radius
		_env.call("set_space_blend", smoothstep(SPACE_ALT.x, SPACE_ALT.y, calt))
	_update_captions(t)
	if _captions != null:
		_captions.set_card_alpha(1.0 - smoothstep(0.0, REVEAL_SECONDS, t))
		_captions.show_skip_hint(t >= SKIP_HINT_T and t < HANDOFF_T)


func _once(key: String) -> bool:
	if _fired.has(key):
		return false
	_fired[key] = true
	return true


func _update_engine(t: float) -> void:
	if t < HIT_T:
		_rocket.set_flame_scale(0.55 + 0.05 * sin(t * 5.0))
		if _t >= 0.0 and _once("cruise_loop"):
			AudioManager.start_loop("rocket_loop", -15.0, 0.6)
		return
	if t < HIT_T + 1.3:
		# The engine coughs: a stutter of short bursts, then nothing.
		var on := fposmod((t - HIT_T) * 6.5, 1.0) < 0.4
		_rocket.set_flame_scale(0.45 if on else 0.0)
		return
	if _once("engine_out"):
		_rocket.set_engine(false)
		AudioManager.stop_loop("rocket_loop", 0.3)
	var burn_on := FALL_END_T - BURN_LEAD
	if t >= burn_on and t < FALL_END_T + BURN_CUT + 0.12:
		if _once("burn"):
			_rocket.set_engine(true, 1.0)
			AudioManager.play_sfx_at("rocket_ignite", _rocket.engine_point(), -4.0)
			AudioManager.start_loop("rocket_loop", -9.0, 0.2)
		var up := smoothstep(burn_on, burn_on + 0.25, t)
		var cut := 1.0 - smoothstep(FALL_END_T + BURN_CUT, FALL_END_T + BURN_CUT + 0.12, t)
		_rocket.set_flame_scale(1.25 * up * cut)
	elif t >= FALL_END_T + BURN_CUT + 0.12 and _once("burn_out"):
		_rocket.set_engine(false)
		AudioManager.stop_loop("rocket_loop", 0.15)


## rocket_pad.gd `_rocket_space_look`: 1 = the dim space plume, tiny light ranges, no smoke.
func _rocket_look(k: float) -> void:
	var w := clampf(k, 0.0, 1.0)
	_rocket.set_flame_intensity(lerpf(GROUND_FLAME, SPACE_FLAME, w))
	_rocket.set_light_range_scale(lerpf(1.0, SPACE_LIGHT_RANGE, w))
	_rocket.set_local_lights_enabled(w <= 0.5)
	_rocket.set_smoke_enabled(w <= 0.5)


func _update_asteroid(t: float, _dt: float) -> void:
	if t < ASTEROID_IN_T - 0.1 or t > AST_HIDE_T:
		if _asteroid.visible:
			_asteroid.visible = false
			_asteroid.set_trail(false)
		if _fill != null:
			_fill.visible = false
		return
	if not _asteroid.visible:
		_asteroid.visible = true
		# The camera rides with the ship (CRUISE_SPEED along _s), so the trail rides with it too.
		_asteroid.set_trail_drift(_s * CRUISE_SPEED)
		_asteroid.set_trail(true)
	# The fill reads the sun the environment set last frame (it runs after us); a sun below the horizon
	# (a night start) gives no key, so no fill either.
	if _fill != null:
		var sun_on := _sun != null and is_instance_valid(_sun) and _sun.visible
		_fill.visible = sun_on
		if sun_on:
			_fill.light_energy = _sun.light_energy * FILL_RATIO
			_fill.light_color = _sun.light_color
	var pos: Vector3
	var spin: float
	if t <= HIT_T:
		var k := clampf((t - ASTEROID_IN_T) / (HIT_T - ASTEROID_IN_T), 0.0, 1.0)
		var rel_to := _ast_hit_pos - _cruise_line(HIT_T)
		pos = _cruise_line(t) + _ast_rel_from.lerp(rel_to, k)
		spin = deg_to_rad(AST_SPIN_DEG) * (t - ASTEROID_IN_T)
	else:
		var tau := t - HIT_T
		pos = _ast_hit_pos + _ast_bounce * tau
		spin = deg_to_rad(AST_SPIN_DEG) * (HIT_T - ASTEROID_IN_T) + deg_to_rad(AST_SPIN_AFTER_DEG) * tau
	_asteroid.global_transform = Transform3D(Basis(_ast_axis, spin), pos)


func _update_fx(t: float, dt: float, xf: Transform3D) -> void:
	if t >= HIT_T and _once("hit"):
		_log("hit")
		_sparks.global_position = _contact
		CrashFx.aim_sparks(_sparks, _contact_n)
		_sparks.restart()
		_sparks.emitting = true
		_flash.global_position = _contact
		_flash.visible = true
		_end_finish_stage = CampaignData.finish_stage()
		var rng := RandomNumberGenerator.new()
		rng.seed = 2026
		for i in _chips.size():
			var c := _chips[i]
			c.global_position = _contact
			c.visible = true
			var spread := Vector3(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0))
			# Out along the strike and AWAY from the camera (+_b), so a flake shrinks as it goes rather
			# than swelling past the lens.
			_chip_vel[i] = (_contact_n * 0.4 + _b * 0.5 + spread * 0.6).normalized() * rng.randf_range(2.4, 4.0)
			_chip_spin[i] = Vector3(rng.randf_range(-9.0, 9.0), rng.randf_range(-9.0, 9.0), rng.randf_range(-9.0, 9.0))
		AudioManager.play_sfx_at("rocket_land", _contact, -2.0, 0.02)
	var ft := t - HIT_T
	if _end_finish_stage >= 0:
		var stage := _finish_step(ft, _end_finish_stage)
		if stage != _rocket.finish_stage():
			_rocket.set_finish_stage(stage)
	if _flash.visible:
		if ft > FLASH_LIFE:
			_flash.visible = false
		else:
			_flash.scale = Vector3.ONE * maxf(sin(PI * ft / FLASH_LIFE) * 1.2, 0.01)
	for i in _chips.size():
		var c := _chips[i]
		if not c.visible:
			continue
		if ft > 1.4:
			c.visible = false
			continue
		c.global_position += _chip_vel[i] * dt
		c.rotation += _chip_spin[i] * dt
		c.scale = Vector3.ONE * (1.0 - smoothstep(0.8, 1.4, ft))
	# A few puffs of smoke while the engine coughs, thrown AWAY from the camera and up. Round 1
	# trailed smoke for the whole fall and the camera flew through the trail; round 2 threw it up and
	# to screen-right, and a puff still drifted close enough to the trailing camera to be a big soft
	# grey disc at T 8.1. Along the camera-to-ship line, a puff can only recede.
	var smoking := t >= HIT_T + SMOKE_WINDOW.x and t < HIT_T + SMOKE_WINDOW.y
	if smoking:
		_smoke.global_position = xf.origin + xf.basis.y.normalized() * 0.35
		var away := (xf.origin - _cam.global_position).normalized()
		CrashFx.aim_puffs(_smoke, (away + _up_l * 0.5).normalized())
	if _smoke.emitting != smoking:
		_smoke.emitting = smoking
	if t >= TD_T and _once("touchdown"):
		_log("touchdown")
		_dust.global_transform = Transform3D(_rest.basis.orthonormalized(), _rest.origin + _pad_up * 0.05)
		_dust.restart()
		_dust.emitting = true
		AudioManager.play_sfx_at("rocket_land", _rest.origin, 0.0)
		AudioManager.play_music(_music, 2.5)
	for i in BOUNCES.size():
		var bt := TD_T
		for j in i + 1:
			bt += float((BOUNCES[j] as Array)[0])
		if t >= bt and _once("bounce_%d" % i):
			AudioManager.play_sfx_at("land", _rest.origin, -5.0 - 4.0 * float(i))
	if t >= TD_T + 0.3 and _once("wisp"):
		_start_wisp()
	if t >= HATCH_T and _once("hatch"):
		_rocket.set_ladder_deployed(true)
		_rocket.open_hatch()
		AudioManager.play_sfx_at("door_open", _rest.origin, -3.0)
	if t >= POP_END_T + 0.4 and _once("hatch_shut"):
		_rocket.close_hatch()
		AudioManager.play_sfx_at("door_close", _rest.origin, -4.0)


## The finish stage to show at age `ft` (seconds since the hit), stepping from FINISH_CLEAN down to
## `target` in equal slices of FLASH_LIFE - one stage per slice, floor-rounded, so the last slice holds
## `target` itself rather than overshooting it. `steps` (5 for the new-game target of 0) comes from the
## actual distance between the two stages, not a chosen count, so nothing here is a tuned number.
func _finish_step(ft: float, target: int) -> int:
	var steps := RocketModel.FINISH_CLEAN - target + 1
	if steps <= 1 or ft >= FLASH_LIFE:
		return target
	var k := clampi(int(ft / FLASH_LIFE * float(steps)), 0, steps - 1)
	return RocketModel.FINISH_CLEAN - k


func _start_wisp() -> void:
	_wisp.global_position = _rest.origin + _pad_up * 0.55
	CrashFx.aim_puffs(_wisp, _pad_up)
	_wisp.emitting = true


func _update_captions(t: float) -> void:
	if _captions == null:
		return
	var want := -1
	for i in CAPTIONS.size():
		var c: Array = CAPTIONS[i]
		if t >= float(c[0]) and t < float(c[1]):
			want = i
			break
	if want == _caption_on:
		return
	if want < 0:
		_captions.hide_line()
	else:
		_captions.show_line(str((CAPTIONS[want] as Array)[2]))
	_caption_on = want


# ============================================================================= the astronaut
## Hidden and deaf, but PHYSICS STAYS ON until the pop-out. event_bus.gd's stuck-player watchdog
## restores control to any player whose physics has been off for STUCK_GRACE (12 s) - it checks
## only that, not the modal - and this shot is 22 s long. Measured on the first headless run with
## physics off: the watchdog fired at shot time 10.2 s and un-hid the astronaut mid-fall. With input
## off (the "cutscene" modal already drives Player.input_enabled) and no velocity, physics just
## keeps the astronaut standing on the landing spot, which is where the rig and the sky want them.
## It goes off only for the hop out of the hatch (POP_T to the end, 2.6 s), where this file moves
## the astronaut by hand.
func _freeze_player() -> void:
	_player.input_enabled = false
	_player.set_process(false)
	_player.velocity = Vector3.ZERO
	_player.visible = false


func _thaw_player() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	_player.set_physics_process(true)
	_player.set_process(true)
	_player.input_enabled = not EventBus.is_modal_open()
	_player.visible = true


func _place_player(facing: Vector3, lift: float) -> void:
	var xf := _planet.surface_transform(_land_dir, facing)
	xf.origin += xf.basis.y * lift
	_player.global_transform = xf


func _update_player(t: float, dt: float) -> void:
	if t < POP_T:
		return
	var model := _player.get_model()
	if _once("pop"):
		_log("pop out")
		# From here to the end (3.0 s, well under the 12 s watchdog) this file moves the astronaut
		# by hand, so the physics step must not add gravity to the hops.
		_player.set_physics_process(false)
		_player.velocity = Vector3.ZERO
		_player.visible = true
		model.scale = Vector3.ONE * 0.02
		model.set_state("jump")
		AudioManager.play_sfx("jump", -6.0)
	if t < POP_END_T:
		var hop2_t := POP_T + HOP1_SECONDS
		var from := _hop_from
		var to := _hop_mid
		var arc := HOP1_ARC
		var x := clampf((t - POP_T) / HOP1_SECONDS, 0.0, 1.0)
		if t >= hop2_t:
			if _once("hop_mid"):
				AudioManager.play_sfx("land", -11.0)
			from = _hop_mid
			to = _hop_to
			arc = HOP2_ARC
			x = clampf((t - hop2_t) / HOP2_SECONDS, 0.0, 1.0)
		var k := 0.5 - 0.5 * cos(PI * x)
		var base := from.lerp(to, k)
		# Up is re-taken along the way: on a 12 m world the two hops cross ~21 deg of its curve.
		var up := base.normalized()
		var basis := _planet.surface_transform(up, _hop_dir).basis
		_player.global_transform = Transform3D(basis, base + up * sin(PI * k) * arc)
		model.scale = Vector3.ONE * maxf(_back_out(clampf((t - POP_T) / 0.42, 0.0, 1.0)), 0.02)
	else:
		if _once("hop_land"):
			model.scale = Vector3.ONE
			model.set_state("idle")
			AudioManager.play_sfx("land", -7.0)
		var w := smoothstep(POP_END_T, POP_END_T + TURN_SECONDS, t)
		_place_player(_hop_dir.slerp(_face, w).normalized(), 0.02)
		if t >= SURPRISE_T and _once("surprised"):
			model.set_state("surprised")
		if t >= HANDOFF_T and _once("reseat"):
			_place_player(_face, 0.02)
			_rig.reseat_behind_player()
			_log("handoff: blending into the rig")
	model.tick(dt, 0.0)


## Tween.TRANS_BACK / EASE_OUT, the curve rocket_pad.gd pops the astronaut out with.
static func _back_out(x: float) -> float:
	const C1 := 1.70158
	const C3 := C1 + 1.0
	var y := x - 1.0
	return 1.0 + C3 * y * y * y + C1 * y * y


# ============================================================================= ending
func _skip() -> void:
	if _skipping or _done:
		return
	_skipping = true
	_log("skip at t=%.2f" % _t)
	if _captions != null:
		_captions.stop_voice()
	await SceneRouter.fade_out(0.25)
	if not is_inside_tree():
		return
	_complete(true)
	SceneRouter.fade_in(0.45)


## Puts everything exactly where the shot leaves it. Idempotent; safe from a skip at any point.
func _apply_end_state() -> void:
	_rocket.global_transform = _rest
	_rocket.set_engine(false)
	_rocket.set_flame_scale(0.0)
	_rocket_look(0.0)
	# Idempotent for the natural end and a skip after the hit (the hit swap already did this); the
	# one path that needs it is a skip BEFORE the hit, which would otherwise leave the pad rocket clean.
	_rocket.set_finish_stage(CampaignData.finish_stage())
	_rocket.set_ladder_deployed(true)
	_rocket.close_hatch()
	AudioManager.stop_loop("rocket_loop", 0.2)
	if _asteroid != null:
		_asteroid.visible = false
		_asteroid.set_trail(false)
	if _flash != null:
		_flash.visible = false
	for c in _chips:
		c.visible = false
	if _smoke != null:
		_smoke.emitting = false
	if _wisp != null and not _wisp.emitting:
		_start_wisp()
	if _env != null:
		_env.call("set_space_blend", 0.0)
	_place_player(_face, 0.02)
	var model := _player.get_model()
	model.scale = Vector3.ONE
	model.set_state("idle")
	_player.visible = true
	if _music != "":
		AudioManager.play_music(_music, 1.2)


func _complete(skipped: bool) -> void:
	if _done:
		return
	_apply_end_state()
	if not _fired.has("reseat") or skipped:
		_rig.reseat_behind_player()
	_drop_camera()
	_thaw_player()
	if _captions != null:
		_captions.queue_free()
		_captions = null
	_end_modal()
	_done = true
	_running = false
	_log("complete skipped=%s finish=%d" % [str(skipped), _rocket.finish_stage()])
	finished.emit(skipped)


func _drop_camera() -> void:
	var rc := _rig.get_camera() if _rig != null and is_instance_valid(_rig) else null
	if rc != null:
		rc.current = true
	if _cam != null and is_instance_valid(_cam):
		_cam.current = false
		_cam.queue_free()
	_cam = null


func _end_modal() -> void:
	if _modal:
		_modal = false
		EventBus.ui_modal_closed.emit("cutscene")


func _exit_tree() -> void:
	# Leaving mid-shot (quit to title): never leave the menus locked, the player frozen or the
	# rocket hanging in space.
	if not _done and _running:
		if _rocket != null and is_instance_valid(_rocket):
			_rocket.global_transform = _rest
			_rocket.set_engine(false)
			# Same reasoning as _apply_end_state: a mid-shot exit before the hit must not leave the
			# pad rocket clean.
			_rocket.set_finish_stage(CampaignData.finish_stage())
			_log("exit_tree mid-shot: rocket repainted finish=%d" % _rocket.finish_stage())
		if _env != null and is_instance_valid(_env):
			_env.call("set_space_blend", 0.0)
		AudioManager.stop_loop("rocket_loop", 0.1)
		_thaw_player()
		_end_modal()
	if _trace != null:
		_trace.close()
		_trace = null
	if RenderingServer.frame_pre_draw.is_connected(_on_pre_draw):
		RenderingServer.frame_pre_draw.disconnect(_on_pre_draw)


# ============================================================================= building
func _build_nodes() -> void:
	_cam = Camera3D.new()
	_cam.name = "CrashCamera"
	_cam.fov = FLIGHT_FOV
	_cam.near = 0.08
	# Home is 200 m out at the bonk; room beyond it for the neighbouring worlds at 140 m from us.
	_cam.far = 2000.0
	# Own attributes with depth of field off, like rocket_pad.gd's flight camera: the environment's
	# rig would defocus a planet 200 m away, and stars must stay pinpoints.
	var attr := CameraAttributesPractical.new()
	attr.auto_exposure_enabled = false
	attr.dof_blur_far_enabled = false
	attr.dof_blur_near_enabled = false
	_cam.attributes = attr
	add_child(_cam)
	_cam.global_transform = _rig.get_camera().global_transform
	# The rock's fill (FILL_RATIO): on the camera, culled to the rock's own layer, no shadows, no
	# specular, no falloff over the few metres it works at. Its energy follows the sun every frame.
	_fill = OmniLight3D.new()
	_fill.name = "RockFill"
	_fill.light_cull_mask = 1 << (CrashAsteroid.FILL_LAYER - 1)
	_fill.shadow_enabled = false
	_fill.light_specular = 0.0
	_fill.omni_range = 60.0
	_fill.omni_attenuation = 0.0
	_fill.visible = false
	_cam.add_child(_fill)
	if _env != null:
		_sun = _env.get_node_or_null("Sun") as DirectionalLight3D

	_asteroid = CrashAsteroid.new()
	_asteroid.name = "Asteroid"
	add_child(_asteroid)
	_asteroid.visible = false
	_sparks = CrashFx.sparks()
	add_child(_sparks)
	_flash = CrashFx.flash()
	add_child(_flash)
	for i in CHIPS:
		var c := CrashFx.chip(i)
		add_child(c)
		_chips.append(c)
		_chip_vel.append(Vector3.ZERO)
		_chip_spin.append(Vector3.ZERO)
	_smoke = CrashFx.damage_smoke()
	add_child(_smoke)
	_wisp = CrashFx.wisp()
	add_child(_wisp)
	_dust = CrashFx.dust_ring()
	add_child(_dust)

	_captions = RadioCaption.new()
	_captions.name = "CrashCaptions"
	add_child(_captions)
	var who := str(NpcData.get_data("mayor_orbit").get("display_name", "Professor Comet"))
	var accent := Color(str(NpcData.get_data("mayor_orbit").get("accent", "#c9a15c")))
	_captions.setup("%s (radio)" % who, accent)
	_captions.set_card_alpha(1.0)


# ============================================================================= measurement
## `--crash-trace=<file>` writes one CSV row per rendered frame: the ACTIVE camera's transform and
## FOV, the card's opacity, where the ship's centre lands on screen, and the shot phase. Hooked on
## RenderingServer.frame_pre_draw, i.e. after every _process has run, so it is the camera that
## actually drew that frame - including the rig's, before the reveal and after the hand-back.
func _open_trace() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--crash-trace="):
			_trace = FileAccess.open(a.substr(14), FileAccess.WRITE)
			break
	if _trace == null:
		return
	_trace.store_line("frame,t,cam,card,px,py,pz,qx,qy,qz,qw,fov,hoff,voff,ship_sx,ship_sy,ship_front,space_blend,"
		+ "rock_sx,rock_sy,rock_sr,hit_sx,hit_sy,ship_x0,ship_y0,ship_x1,ship_y1,"
		+ "cap_x0,cap_y0,cap_x1,cap_y1,cap_a,mast_gap,plx,ply,plz")
	RenderingServer.frame_pre_draw.connect(_on_pre_draw)


func _on_pre_draw() -> void:
	if _trace == null or not is_inside_tree():
		return
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var xf := cam.global_transform
	var q := xf.basis.orthonormalized().get_rotation_quaternion()
	var vp := get_viewport().get_visible_rect().size
	var centre := _ship_centre(clampf(_t, -CARD_SECONDS, END_T))
	var sp := cam.unproject_position(centre)
	var card := 0.0
	if not _done:
		card = 1.0 - smoothstep(0.0, REVEAL_SECONDS, _t)
	var blend := 0.0
	if _env != null and _env.has_method("get_space_blend"):
		blend = float(_env.call("get_space_blend"))
	# Quaternions at 8 decimals: at 5 the rounding alone read as 0.5 deg "rotations" between frames
	# (2 acos(1 - 1e-5) = 0.51 deg), which swamped the real per-frame turn in round 1's trace.
	_trace.store_line("%d,%.4f,%s,%.3f,%.4f,%.4f,%.4f,%.8f,%.8f,%.8f,%.8f,%.3f,%.4f,%.4f,%.4f,%.4f,%d,%.3f,%s" % [
		_trace_frame, _t, "crash" if cam == _cam else "rig", card,
		xf.origin.x, xf.origin.y, xf.origin.z, q.x, q.y, q.z, q.w, cam.fov, cam.h_offset, cam.v_offset,
		sp.x / vp.x, sp.y / vp.y, 0 if cam.is_position_behind(centre) else 1, blend, _trace_extra(cam, vp)])
	_trace_frame += 1
	# Runs on after the hand-back until this node leaves (WISP_TAIL), so the radio call's opening
	# push-in, 0.9 s after control returns, is in the same file as the shot.


## The trace's measurement columns, all as fractions of the canvas: the rock's centre and radius, the
## contact point, the ship's screen box (the union of three discs along its axis - fins, body, nose),
## the caption panel's rect and opacity, the mast-to-ship silhouette gap in degrees from the camera
## that drew this frame, and the astronaut's position.
func _trace_extra(cam: Camera3D, vp: Vector2) -> String:
	var rock := "-1,-1,0"
	if _asteroid != null and _asteroid.visible and not cam.is_position_behind(_asteroid.global_position):
		var c := cam.unproject_position(_asteroid.global_position)
		var e := cam.unproject_position(_asteroid.global_position
			+ cam.global_basis.x * CrashAsteroid.RADIUS * CrashAsteroid.SQUASH.x)
		rock = "%.4f,%.4f,%.4f" % [c.x / vp.x, c.y / vp.y, c.distance_to(e) / vp.y]
	var hit := "-1,-1"
	if not cam.is_position_behind(_contact):
		var h := cam.unproject_position(_contact)
		hit = "%.4f,%.4f" % [h.x / vp.x, h.y / vp.y]
	var sxf := _rocket.global_transform
	var a1 := sxf.origin + sxf.basis.y * RocketModel.TOTAL_HEIGHT
	var box := "-1,-1,-1,-1"
	if not cam.is_position_behind(sxf.origin) and not cam.is_position_behind(a1):
		# The hull as three discs along its axis: the fins at the base (SHIP_SIL_R), the body at mid
		# height (RocketModel.HULL_R), the nose near the tip.
		var r := Rect2()
		var discs := [[0.15, SHIP_SIL_R], [0.5, RocketModel.HULL_R], [0.93, 0.22]]
		for i in discs.size():
			var p: Vector3 = sxf.origin.lerp(a1, float(discs[i][0]))
			var s := cam.unproject_position(p)
			var rr := s.distance_to(cam.unproject_position(p + cam.global_basis.x * float(discs[i][1])))
			var disc := Rect2(s - Vector2(rr, rr), Vector2(rr, rr) * 2.0)
			r = disc if i == 0 else r.merge(disc)
		box = "%.4f,%.4f,%.4f,%.4f" % [r.position.x / vp.x, r.position.y / vp.y, r.end.x / vp.x, r.end.y / vp.y]
	var cap := "-1,-1,-1,-1,0"
	if _captions != null and is_instance_valid(_captions):
		var pr := _captions.panel_rect()
		cap = "%.4f,%.4f,%.4f,%.4f,%.3f" % [pr.position.x / vp.x, pr.position.y / vp.y,
			pr.end.x / vp.x, pr.end.y / vp.y, _captions.panel_alpha()]
	var gap := _mast_gap(cam.global_position, sxf) if _has_mast else 99.0
	var pp := _player.global_position if _player != null and is_instance_valid(_player) else Vector3.ZERO
	return "%s,%s,%s,%s,%.2f,%.4f,%.4f,%.4f" % [rock, hit, box, cap, gap, pp.x, pp.y, pp.z]


func _log(msg: String) -> void:
	print("CRASH [%6.2f] %s" % [_t, msg])
