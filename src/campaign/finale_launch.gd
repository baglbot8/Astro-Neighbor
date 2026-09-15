class_name FinaleLaunch
extends Node3D
## THE SEND-OFF - the Phase 5 showpiece (docs/PHASE5_SPEC.md §2 "Send-off", §4 "Shower", §5, §7).
## finale.gd instances this under /root/World (by path) once "Send her" is chosen, calls
## `play(meeting)`, and waits for `finished`. Nothing in it is spoken: it is one shot, seen from the
## ground, of the empty gold rocket flying into the giant asteroid and the rock turning into a meteor
## shower over your friends' upturned faces.
##
## THE SHOT, one camera and no cut, 22 s (shot clock; every value is a function of it):
##    0.0   the camera starts on the meeting's own camera and settles, behind the crowd 2.5 m up with a
##          50 deg vertical FOV, on the whole rocket, the front heads and half the rock
##    1.0   ignition: `rocket_ignite`, the rocket loop, `CrashFx.dust_ring()` on the deck, a shake of at
##          most 0.075, the plume growing as the rocket eases 1.45 m off the deck; the music fades out
##    2.5   lift-off: the rocket climbs and leans over onto its path to the rock, faster and faster; the
##          camera cranes up to ~12 m behind the crowd, following her
##    7.5   the camera eases to a stop on the rock, letting her go
##   11.0   she reaches it: `CrashFx.flash()` swells over the hit and hides the rocket; the rock breaks
##          (GiantAsteroid.break_at): ten chunks part over the gold core, warm and shrink into heads
##   11.4   `finale_impact`
##   12.5   the first wave of the shower (`finale_shower`), more at 14.5 and 16.5; from 12.9 the chunks
##          streak away one by one as the remnant shrinks to nothing (scale, never a fade)
##   13.0   the camera swings down over the crowd to a low three-quarter front of their upturned faces,
##          the streaks pouring over them; everyone cheers and DJ Nova dances
##   15-18  five hero stars, one in each friend's accent (`finale_hero_star`), cross the faces frame
##   22.0   settled on the gift frame with the pad out of view; `finished(false)`
##
## BORROWED, NOT OWNED. The rocket is /root/World/Rocket's `rocket` (a RocketModel), moved only through
## its transform and RocketModel's public API, the way CrashIntro borrows it; at the end it is back on
## its parked transform, engine off, and hidden - the gift (finale_gift.gd) swaps the skiff in with
## `rocket_pad.adopt_model`. The rock, the crowd and the meeting camera come from the meeting
## (finale_meeting.gd, loaded by path by finale.gd - never named here), each looked up with a guarded
## `has_method`, with a fallback so a missing piece degrades the shot instead of stranding the player.
##
## CONTINUITY. The camera is seeded from `meeting.camera()` and every rule value is continuous in the
## shot clock (clamped to MAX_STEP per frame, so a load stall slows the shot rather than jumping it).
## Eye moves are smoothed trapezoids in the crowd's own ground frame; the look is interpolated as yaw
## and pitch in the eye's local frame (never a look-at through a point the eye passes), so the turn
## rate is bounded by construction. A final limiter holds the rendered camera to CAM_MAX_SPEED and
## CAM_MAX_TURN_DEG per second of shot clock whatever the rules ask; the run logs how often it had to.
##
## SKIP (CrashIntro's contract, and it ASKS FIRST - the user, 2026-09-14, after an accidental skip). From
## SKIP_ARM_T (0.6 s): any real key, a real mouse button, a touch or a pad button - or the interact /
## ui_accept / jump / cancel / pause actions, polled for Director taps - opens the one shared question,
## SkipConfirm.ask ("Skip the send-off?", "Keep watching" focused; loaded by path). WHILE IT IS OPEN THE
## SHOT HOLDS (SkipConfirm's caller contract): the shot clock does not advance, so the camera, the rocket,
## the rock, the flash, the shower and every timed sound hold exactly where they were, and nothing of the
## shot can end under the question; sounds already playing (the engine loop, a wave) play on, and the dust
## ring's particles are paused with it. "Keep watching" resumes on the very next frame from the held clock
## (one MAX_STEP-clamped step, no jump). "Skip" fades to navy, runs `apply_end_state()` (idempotent, and
## also what finale.gd calls instead of `play` after `debug_start_gift`), fades back in, and hands
## `finished(true)` over only once the key or finger that answered is let go, so it cannot also advance the
## gift's first box. The opening press never answers the question, and a 10 taps/s train never can
## (SkipConfirm's quiet-gap guard).
##
## FREEZE AND MODAL. Exactly one `ui_modal_opened("cutscene")` and one `ui_modal_closed("cutscene")` per
## play, on every exit path. The astronaut keeps physics ON (EventBus's 12 s stuck-player watchdog) with
## input off, except for the 1.6 s cheer. The day clock is held (Environment.time_scale 0) and restored
## to exactly what it was when `play` started.
##
## HEAT (§7). One draw for the whole shower (StarShower, a MultiMesh), two for the broken rock (L1), one
## for the flash quad, one for the dust ring. No new Shader: star_streak.gdshader, the glow sprite and the
## puff shader, all listed by `warm_materials()` for the meeting's warm-up quads. `--finale-trace=<file>`
## (after "--") appends one "L2 cam" row per rendered frame to K's shared trace file, in batches.

signal finished(skipped: bool)

enum Phase { IDLE, WAITING, RUNNING, SKIPPING, RELEASING, DONE }

const MODAL_NAME := "cutscene"
const TRACE_TAG := "L2"
const FINALE_STATE_PATH := "res://src/campaign/finale_state.gd"
const SHOWER_PATH := "res://src/campaign/star_shower.gd"

# ------------------------------------------------------------------------------------ timeline (s)
const IGNITE_T := 1.0
const IGNITE_GROW := 0.85
const IGNITION_LIFT := 1.45
const LIFT_T := 2.5
const HIT_T := 11.0
const IMPACT_SFX_T := HIT_T + 0.4
const WAVE_T: Array[float] = [12.5, 14.5, 16.5]
const HERO_T: Array[float] = [15.0, 15.75, 16.5, 17.25, 18.0]
const CHUNK_STREAK_T := 12.95
const CHUNK_STREAK_GAP := 0.27
const REMNANT_SHRINK := Vector2(13.0, 15.7)
const CHEER_T := 13.3
const CHEER2_T := 16.7
const DANCE_T: Array[float] = [13.4, 16.3, 19.2]
const ASTRO_CHEER_T := 13.6
const ASTRO_CHEER_S := 1.6
const END_T := 22.0
const SKIP_ARM_T := 0.6
const SKIP_HINT_T := 0.9
const SKIP_HINT_ALPHA := 0.72
const SKIP_FADE_OUT := 0.25
const SKIP_FADE_IN := 0.45
const RELEASE_WAIT_MAX := 1.0
## Longest wait in `play` for the pad to finish landing the rocket before the shot starts anyway.
const ARRIVAL_WAIT_MAX := 20.0
const MAX_STEP := 0.05
const MUSIC_FADE := 1.5
## Plume at ignition and in the climb (rocket_pad.gd's own launch numbers).
const FLAME_IGNITE := 1.6
const FLAME_CLIMB := 1.25
const GROUND_FLAME_INTENSITY := 1.15
## The rocket's exhaust smoke stops this long after lift-off, so its puffs (1.3 s life) are long gone
## before the flash hides the rocket and every child with it.
const SMOKE_OFF_T := 6.0
## Flight path: the first control point this far straight up from the lift point; the approach from
## this far out along the line into the rock; the hit this far inside the rock's bounding radius.
const CLIMB_UP_M := 34.0
const CLIMB_SIDE_M := 18.0
const APPROACH_M := 38.0
const HIT_DEPTH := 0.80
## Arc-length progress along the flight is x^FLIGHT_POW (x = share of the flight time): zero speed at
## lift-off, accelerating all the way in.
const FLIGHT_POW := 3.0
const SHAKE := Vector2(0.075, 1.2)
const FLASH_LIFE := 0.55
const FLASH_GROW := 0.09
## The flash quad at its peak, as a share of the rock's bounding diameter.
const FLASH_SIZE := 0.95

# ------------------------------------------------------------------------------------ camera
## Blend limits (§2): at most 35 deg/s and 2.5 m/s. The limiter runs a hair under them.
const CAM_MAX_SPEED := 2.45
const CAM_MAX_TURN_DEG := 34.0
const CAM_NEAR := 0.08
const CAM_FAR := 400.0
## Keyframes in the crowd's ground frame: azimuth round the crowd centre from the pad bearing (deg,
## positive toward the rock's side), distance along the ground (m) and height above it (m).
const A_ALPHA := 150.0
const A_RHO := 4.4
const A_H := 2.5
const A_FOV := 50.0
const B_ALPHA := 150.0
const B_RHO := 3.0
const B_H := 10.5
const B_FOV := 36.0
const D_ALPHA := 30.0
const D_RHO := 4.8
const D_H := 1.0
const D_FOV := 52.0
## The crane runs CRANE_T.x-.y, the swing SWING_T.x-.y, both smoothed trapezoids (accel, decel shares).
const CRANE_T := Vector2(2.2, 11.0)
const CRANE_SHAPE := Vector2(0.18, 0.40)
const SWING_T := Vector2(12.0, 21.0)
const SWING_SHAPE := Vector2(0.26, 0.30)
## Mid-swing the look tips up this much more (a sin bump over the swing), keeping the pad mast under the
## frame while the camera turns past the pad bearing.
const SWING_LIFT_DEG := 14.0
## After the swing, a slow creep in toward the faces (m over the hold).
const D_CREEP_M := 0.35
## Opening framing: the look yaw this share of the way from the rocket toward the rock.
const A_ROCK_YAW_SHARE := 0.25
const A_HEADS_FROM_TOP := 0.88
## Heads (crowd head tops) for framing: this far above each neighbour's feet.
const HEAD_H := 1.15
## Look weights: follow the rocket (ramp in, ramp out), then settle on the rock.
const TRACK_IN := Vector2(2.4, 4.6)
const TRACK_OUT := Vector2(6.6, 10.4)
const ROCK_LOOK := Vector2(5.6, 10.8)
## The followed point leads the rocket this share of the way toward the rock.
const TRACK_LEAD := 0.22
## Where the rock sits in the break frame, in half-heights above the frame centre.
const B_ROCK_UP := 0.12
## The faces frame: the crowd's heads this far down the frame, the look yawed this share of the way from
## the crowd toward the astronaut.
const D_HEADS_FROM_TOP := 0.66
const D_ASTRO_YAW_SHARE := 0.22
## The zoom from the wide opening to the rock framing.
const FOV_IN := Vector2(3.0, 7.8)
## Sight lines for `_pick_side`: the occluder space's reach round the crowd, and how far short of the
## rocket's axis and the astronaut's head a line stops (both are occluders themselves).
const SIGHT_REACH := 24.0
const SIGHT_ROCKET_CLEAR := 1.4
const SIGHT_ASTRO_CLEAR := 0.45
## The meeting works out `opening_frame` inside its load (so the sight lines never stall a frame of the
## beat); that call leaves its side pick on the meeting as this meta, and `play` reuses it instead of
## building VisitorSystem's occluder space again (38-42 ms measured by K2: a 53-60 ms frame at the start
## of the shot). Reused only while the crowd centre is within SIDE_REUSE_M of where it was solved: half
## the meeting's 1.0 m step back, the midpoint between the two crowd poses the pick could have seen.
## Decorations can be placed or picked up in free roam between the meeting and the send-off (§0 round 3),
## and a lamp placed on the chosen side's sight line would otherwise stand in the shot: when the list is
## not the one the pick saw (`_decor_sig`), `_recheck_side` casts the stored lines against only the added
## or moved decorations (no full rebuild) and flips the side if the other one now scores better.
const SIDE_META := "finale_launch_side"
const SIDE_REUSE_M := 0.5
const SEED_MIN_S := 1.2
const SEED_MAX_S := 9.0

# ------------------------------------------------------------------------------------ crowd
const DJ_NOVA := "dj_nova"
## §2's crowd (front row, then back row), for the warm-up models.
const CROWD_IDS: PackedStringArray = ["grig", "fen", "zorp", "mayor_orbit", "bolt", "vela", "pip", "pop", "stella", "dj_nova"]
const FRIENDS: PackedStringArray = ["zorp", "bolt", "fen", "grig", "vela"]
const FRIEND_FALLBACK_ACCENT := Color("#c9a15c")
## Crowd centre from the pad along the meeting axis when the meeting gives no crowd (§2: rows at 6.0 and
## 7.4 m).
const CROWD_FALLBACK_M := 6.7
## Streak counts per wave (shell streaks, spread over WAVE_S seconds) and the light base between them.
const WAVE_COUNTS: Array[int] = [16, 20, 22]
const WAVE_S := 2.2
const BASE_RATE := 1.2
const BASE_T := Vector2(12.6, 17.5)
## Over the faces frame, to the end and past it: the shower thins but never stops before the hand-off.
const TAIL_RATE := 5.0
const TAIL_THETA := Vector2(95.0, 150.0)
const TAIL_T := Vector2(17.5, 22.6)
const SHOWER_IN_FRAME := 0.8
const SHOWER_SEED := 5155

const SKIP_CONFIRM_PATH := "res://src/ui/common/skip_confirm.gd"
const SKIP_QUESTION := "Skip the send-off?"
const SKIP_YES := "Skip"
const SKIP_NO := "Keep watching"
const SKIP_ACTIONS: PackedStringArray = ["interact", "ui_accept", "jump", "cancel", "pause"]
const HOLD_ACTIONS: PackedStringArray = ["interact", "ui_accept", "jump", "boost", "emote"]
const HINT_LAYER := 95

var _phase: int = Phase.IDLE
var _t := 0.0
var _skipped := false
var _modal := false
var _fired: Dictionary = {}
var _skip_held: Dictionary = {}
var _skip_primed := false
var _touches: Dictionary = {}
var _release_t := 0.0
var _end_applied := false
var _hold_at := -1.0
var _worst_step_ms := 0.0
var _debug_no_shower := false
## True while the SkipConfirm question is open: the shot clock holds (see SKIP in the header).
var _confirming := false
var _confirm_count := 0
## The astronaut's cheer had physics off when the question opened (EventBus's 12 s watchdog must not
## see a frozen player while the question waits), so it is switched back on for the wait.
var _cheer_held := false
var _force_side_pick := false

# world pieces
var _meeting: Node
var _planet: Planet
var _pad: Node3D
var _rocket: RocketModel
var _player: Player
var _env: Node
var _rig: CameraRig
var _asteroid: Node3D
var _meeting_cam: Camera3D
var _crowd: Array[Node3D] = []
var _crowd_ids: PackedStringArray = []
var _music := ""
var _saved_time_scale := 1.0
var _held_clock := false

# geometry, solved once in play()
var _rest := Transform3D.IDENTITY
var _pad_up := Vector3.UP
var _c := Vector3.ZERO
var _up_c := Vector3.UP
var _b_c := Vector3.FORWARD
var _s_c := Vector3.RIGHT
var _rock_c := Vector3.ZERO
var _rock_r := 11.0
var _lift := Vector3.ZERO
var _hit := Vector3.ZERO
var _chunk_dirs: PackedVector3Array = PackedVector3Array()
var _bz: PackedVector3Array = PackedVector3Array()
var _bz_len: PackedFloat32Array = PackedFloat32Array()
var _astro_p := Vector3.ZERO
var _astro_up := Vector3.UP
var _astro_face0 := Vector3.FORWARD
var _astro_face1 := Vector3.FORWARD
var _a_yaw := 0.0
var _a_pitch := 0.0
var _b_yaw := 0.0
var _b_pitch := 0.0
var _d_yaw := 0.0
var _d_pitch := 0.0
var _seed_xf := Transform3D.IDENTITY
var _seed_fov := 45.0
var _seed_s := SEED_MIN_S
var _has_seed := false
## +1: the camera works from the rock's side of the crowd; -1: mirrored (see `_pick_side`).
var _side_sign := 1.0
var _side_note := ""
## Both sides' sight lines as `_pick_side` last cast them: {+1.0: [[a, b, label, blocker], ...], -1.0: ...}.
var _side_lines := {}

# nodes
var _cam: Camera3D
var _flash: MeshInstance3D
var _dust: GPUParticles3D
var _shower: MultiMeshInstance3D
var _hint_layer: CanvasLayer
var _hint_root: Control
var _hint_pill: PanelContainer
var _hint_alpha := 0.0

# measurement
var _last_xf := Transform3D.IDENTITY
var _last_t := 0.0
var _have_last := false
var _limited_frames := 0
var _max_speed := 0.0
var _max_turn := 0.0
var _stalls: Array[String] = []
var _fired_now := PackedStringArray()
var _trace_on := false
var _trace_buf: PackedStringArray = PackedStringArray()
var _trace_frame := 0
var _last_usec := 0
var _worst_ms := 0.0
var _peak_on_screen := 0
var _rng := RandomNumberGenerator.new()


# ============================================================================= public API
## Plays the send-off. `meeting` is the FinaleMeeting (any Node; its API is used through has_method).
func play(meeting: Node) -> void:
	if _phase != Phase.IDLE:
		return
	if not is_inside_tree():
		push_warning("FinaleLaunch.play: not in the tree")
		return
	_meeting = meeting
	_phase = Phase.WAITING
	# The pad may still be landing the rocket we borrow (a load that arrives by rocket at stage 3: the
	# meeting has nothing to wait for, so its send beat can end mid-descent). Flying the rocket out of
	# the pad's own arrival let the pad's touchdown hand the view back to the gameplay rig 5.4 s into
	# the shot - a cut (L2U probe, dev run). Start only once the pad has landed and let go of the view.
	var waited := 0.0
	var arriving := false
	while is_inside_tree() and waited < ARRIVAL_WAIT_MAX:
		arriving = arriving or GameState.flag("rocket_arriving") or _pad_camera_on()
		# The arrival's last step (`_finish_arrival`: thaw, hand the view to the rig, re-enable the pad's
		# Interactable) comes ~2 s after `rocket_arriving` clears at touchdown, so once an arrival has been
		# seen, wait for the Interactable too.
		if not (GameState.flag("rocket_arriving") or _pad_camera_on() or (arriving and not _pad_interactable_on())):
			break
		waited += get_process_delta_time()
		await get_tree().process_frame
	if not is_inside_tree():
		return
	if waited > 0.0:
		# The arrival's hand-back makes the rig current in the frame it ends; let that camera draw before
		# the shot seeds from "the camera drawing now" (seeding in the same frame read a camera that never
		# drew, and the shot opened with a 10 m jump from the frame on screen).
		await get_tree().process_frame
		await get_tree().process_frame
		if not is_inside_tree():
			return
		_log("waited %.2f s for the pad's arrival to finish" % waited)
	if not _resolve_world():
		# Never strand anybody on a missing piece: the end state (rocket hidden, rock gone), no shot.
		_log("a piece of the world is missing (planet/rocket/player); no send-off")
		apply_end_state()
		_phase = Phase.DONE
		# Deferred: finale.gd calls play() and only then awaits `finished`, so a same-frame emit would be
		# missed and the chain would wait forever.
		finished.emit.call_deferred(false)
		return
	for a: String in OS.get_cmdline_user_args():
		_trace_on = _trace_on or a.begins_with("--finale-trace=")
	var u0 := Time.get_ticks_usec()
	_solve_geometry()
	var u1 := Time.get_ticks_usec()
	# The sight lines in `_solve_geometry` build an occluder space (~33 ms measured): let that frame go
	# before anything of the shot is built or shown, then seed from the camera drawing after it.
	await get_tree().process_frame
	if not is_inside_tree():
		return
	var u1b := Time.get_ticks_usec()
	_read_seed()
	_build_nodes()
	var u2 := Time.get_ticks_usec()
	_schedule_shower()
	var u3 := Time.get_ticks_usec()
	_log("set-up ms: geometry %.1f (a frame before the shot), seed+nodes %.1f, shower schedule %.1f" % [(u1 - u0) / 1000.0, (u2 - u1b) / 1000.0, (u3 - u2) / 1000.0])
	_modal = true
	EventBus.ui_modal_opened.emit(MODAL_NAME)
	_hold_clock()
	_freeze_player()
	_rocket.set_ladder_deployed(false)
	_rocket.close_hatch()
	_rocket.set_flame_intensity(GROUND_FLAME_INTENSITY)
	if _asteroid != null and _asteroid.has_method("set_tumble_enabled"):
		_asteroid.call("set_tumble_enabled", false)
	for n in _crowd:
		if n.has_method("hold_facing"):
			n.call("hold_facing", _rocket_mid(0.0))
	_cam.current = true
	_t = 0.0
	_phase = Phase.RUNNING
	_last_usec = Time.get_ticks_usec()
	_beat("play crowd=%d rock=%s seed=%s cam_seed_s=%.2f %s" % [_crowd.size(), str(_asteroid != null), str(_has_seed), _seed_s, _side_note])
	set_process(true)
	_step(0.0)


## Puts everything where the shot leaves it: rocket parked and hidden with its engine off, the rock gone,
## no modal, the clock and the planet's music back, the camera on the final frame (handed to the
## meeting's camera), stragglers running. Idempotent; safe at any moment, and safe with no `play()` at
## all (finale.gd calls it straight after `debug_start_gift`).
func apply_end_state() -> void:
	if not is_inside_tree():
		return
	if _planet == null:
		if _meeting == null:
			_meeting = get_tree().root.get_node_or_null("World/FinaleMeeting")
		if _resolve_world():
			_solve_geometry()
	if _rocket != null and is_instance_valid(_rocket):
		_rocket.set_engine(false)
		_rocket.set_flame_scale(0.0)
		_rocket.set_smoke_enabled(true)
		_rocket.set_flame_intensity(GROUND_FLAME_INTENSITY)
		if _rest != Transform3D.IDENTITY:
			_rocket.global_transform = _rest
		_rocket.visible = false
	AudioManager.stop_loop("rocket_loop", 0.2)
	if _asteroid != null and is_instance_valid(_asteroid):
		_asteroid.visible = false
		_asteroid.scale = Vector3.ONE
	if _flash != null:
		_flash.visible = false
	if _dust != null:
		_dust.emitting = false
	if _shower == null and _planet != null:
		_build_shower()
	if _shower != null:
		_shower.call("start_stragglers")
	for n in _crowd:
		if is_instance_valid(n) and n.has_method("hold_facing"):
			n.call("hold_facing", _rock_c)
	if _player != null and is_instance_valid(_player) and _astro_p != Vector3.ZERO:
		_player.global_transform = Transform3D(_face_basis(_astro_face1, _astro_up), _astro_p)
		_player.velocity = Vector3.ZERO
		var model := _player.get_model()
		if model != null:
			model.set_state("idle")
		_player.set_physics_process(true)
	_restore_clock()
	if _music != "":
		AudioManager.play_music(_music, 1.2)
	_end_applied = true


## §2 stragglers: stops sending new ones (finale.gd calls this once the gift has ended).
func stop_stragglers() -> void:
	if _shower != null and is_instance_valid(_shower):
		_shower.call("stop_stragglers")
	_beat("stop_stragglers")


## §7 warm-up list for the meeting's 2 cm quads: the shower's streak material, the flash's glow sprite and
## the dust ring's puff (CrashFx's own builders, so the very same shader parameters are compiled).
static func warm_materials() -> Array[Material]:
	var out: Array[Material] = []
	if ResourceLoader.exists(SHOWER_PATH):
		for m: Material in load(SHOWER_PATH).call("warm_materials"):
			out.append(m)
	var f := CrashFx.flash()
	out.append((f.mesh as QuadMesh).material)
	f.free()
	var d := CrashFx.dust_ring()
	out.append((d.draw_pass_1 as QuadMesh).material)
	d.free()
	return out


## The send-off's opening frame for `meeting` - `[Transform3D, vfov_deg]` - without playing anything, so
## the meeting's last "Send her" framing can end on it (then the seed blend is a no-op and the opening
## wide keeps its 2.5 s). Empty if the world is missing a piece.
static func opening_frame(meeting: Node) -> Array:
	var tree := Engine.get_main_loop() as SceneTree
	var world := tree.root.get_node_or_null("World") if tree != null else null
	if world == null:
		return []
	var probe: Node = (load("res://src/campaign/finale_launch.gd") as GDScript).new()
	world.add_child(probe)
	var out: Array = probe.call("_opening_frame_for", meeting)
	world.remove_child(probe)
	probe.free()
	return out


## True when the side pick `opening_frame` left on `meeting` no longer matches the planet's placed
## decorations (placed, picked up or moved since), or there is none. With the crowd in place `play` then
## rechecks only the changed decorations (`_recheck_side`, no occluder rebuild); with no meta it picks the
## side again in full (one 36-41 ms occluder build). Crowd drift is not checked here (play checks it).
static func opening_frame_stale(meeting: Node) -> bool:
	if meeting == null or not is_instance_valid(meeting) or not meeting.has_meta(SIDE_META):
		return true
	var m: Dictionary = meeting.get_meta(SIDE_META)
	return not m.has("decor") or str(m["decor"]) != _decor_sig()


func _opening_frame_for(meeting: Node) -> Array:
	_meeting = meeting
	if not _resolve_world():
		return []
	_force_side_pick = true
	_solve_geometry()
	_force_side_pick = false
	if meeting != null and is_instance_valid(meeting):
		meeting.set_meta(SIDE_META, {"sign": _side_sign, "c": _c, "note": _side_note, "decor": _decor_sig(),
			"decor_map": _decor_map(), "lines": _side_lines})
	var r := _rule(0.0)
	return [Transform3D(r[1] as Basis, r[0] as Vector3), float(r[2])]


## §7 warm-up for the variants a plain quad cannot compile: the shower's MultiMesh (the instanced draw of
## star_streak), the dust ring's particles, and a 2 cm stand-in for the rocket's engine effects. Each is
## a real node to add 1 m in front of the camera for a few frames and then free. MEASURED (L2 probe,
## Compatibility, Mac): the first MultiMesh frame stalled 77-84 ms and the ignition 110 + 58 ms with the
## plain warm quads alone; drawing these first removed both.
static func warm_nodes() -> Array[Node3D]:
	var out: Array[Node3D] = []
	if ResourceLoader.exists(SHOWER_PATH):
		var sh := (load(SHOWER_PATH) as GDScript).new() as MultiMeshInstance3D
		sh.call("warm_pose")
		out.append(sh)
	var d := CrashFx.dust_ring()
	d.scale = Vector3.ONE * 0.015
	d.emitting = true
	out.append(d)
	var rm := (load("res://src/rocket/rocket_model.tscn") as PackedScene).instantiate() as Node3D
	rm.scale = Vector3.ONE * 0.006
	rm.ready.connect(func() -> void:
		rm.call("set_engine", true, 1.0)
		rm.call("set_flame_scale", 1.0), CONNECT_ONE_SHOT)
	out.append(rm)
	# The crowd's faces in their cheer: the "^ ^" happy-eye arcs are separate meshes shown only in
	# happy / wave / dance, so the shot's cheers were the first time they were ever drawn. MEASURED (L2U
	# probe, Compatibility, Mac, dev stand-in meeting): a 72-78 ms draw stall at 17.43 s, repeatable, gone
	# with every emote dropped and gone again (worst frame 20-21 ms, two runs) once these ten models had
	# drawn in "happy" first.
	var poser := _WarmPoser.new()
	for id in CROWD_IDS:
		var m: Node3D = NpcModels.make(id)
		if m != null:
			poser.add_child(m)
			m.position = Vector3((float(poser.get_child_count()) - 5.0) * 0.02, 0.0, 0.0)
			m.scale = Vector3.ONE * 0.01
	out.append(poser)
	return out


## Ticks the warm-up crowd models into their happy pose (models are posed by their owner's tick).
class _WarmPoser extends Node3D:
	func _ready() -> void:
		for c in get_children():
			if c.has_method("set_state"):
				c.call("set_state", "happy")

	func _process(_delta: float) -> void:
		for c in get_children():
			if c.has_method("tick"):
				c.call("tick", 0.3, 0.0)


## True while the rocket pad still has a flight camera of its own in the tree (current or not): its arrival
## ends by handing the view to the gameplay rig and freeing that camera, and that hand-over must not land
## inside the shot. (Measured: with only `rocket_arriving` waited for, the pad's hand-back still took the
## view 1.6 s into the shot, because the meeting's camera had been made current over the pad's.)
func _pad_camera_on() -> bool:
	var pad := get_tree().root.get_node_or_null("World/Rocket")
	if pad == null:
		return false
	for c in pad.find_children("*", "Camera3D", true, false):
		if not c.is_queued_for_deletion():
			return true
	return false


## The pad's own Interactable (its descendant named "Interactable"): off while the pad is busy with a
## boarding or an arrival. True when there is no pad or no such node.
func _pad_interactable_on() -> bool:
	var pad := get_tree().root.get_node_or_null("World/Rocket")
	var it := pad.find_child("Interactable", true, false) if pad != null else null
	return it == null or bool(it.get("enabled"))


func is_running() -> bool:
	return _phase == Phase.RUNNING or _phase == Phase.SKIPPING


## True while the SkipConfirm question is open (the shot is holding).
func is_confirming() -> bool:
	return _confirming


func shot_time() -> float:
	return _t


# ============================================================================= set-up
func _resolve_world() -> bool:
	var world := get_tree().root.get_node_or_null("World")
	if world == null:
		return false
	_planet = world.get_node_or_null("Planet") as Planet
	_pad = world.get_node_or_null("Rocket") as Node3D
	_env = world.get_node_or_null("Environment")
	_rig = world.get_node_or_null("CameraRig") as CameraRig
	_rocket = _pad.get("rocket") as RocketModel if _pad != null else null
	_player = get_tree().get_first_node_in_group("player") as Player
	_music = _planet.data.music_track if _planet != null and _planet.data != null else ""
	if _meeting != null and is_instance_valid(_meeting):
		if _meeting.has_method("asteroid"):
			_asteroid = _meeting.call("asteroid") as Node3D
		if _meeting.has_method("camera"):
			_meeting_cam = _meeting.call("camera") as Camera3D
		if _meeting.has_method("crowd_ids") and _meeting.has_method("npc"):
			_crowd.clear()
			_crowd_ids = PackedStringArray()
			for id: Variant in _meeting.call("crowd_ids"):
				var n := _meeting.call("npc", str(id)) as Node3D
				if n != null and is_instance_valid(n):
					_crowd.append(n)
					_crowd_ids.append(str(id))
	if _asteroid == null:
		_asteroid = _find_asteroid(world)
	return _planet != null and _rocket != null and _player != null


func _find_asteroid(n: Node) -> Node3D:
	for c in n.get_children():
		if c is Node3D and c.get_script() != null and str((c.get_script() as Script).resource_path).ends_with("giant_asteroid.gd"):
			return c as Node3D
		if c.get_child_count() > 0 and c is Node3D and not (c is Planet):
			var f := _find_asteroid(c)
			if f != null:
				return f
	return null


func _solve_geometry() -> void:
	_rest = _rocket.global_transform
	_pad_up = _rest.basis.y.normalized()
	var pad_ground := _rest.origin
	# The crowd centre: the mean of the crowd on the ground, else along the meeting axis from the pad.
	var axis := Vector3.ZERO
	if _meeting != null and is_instance_valid(_meeting) and _meeting.has_method("axis"):
		axis = _meeting.call("axis") as Vector3
	if axis.length_squared() < 0.0001:
		axis = _player.global_position - pad_ground
	axis = (axis - _pad_up * axis.dot(_pad_up)).normalized()
	if not _crowd.is_empty():
		var acc := Vector3.ZERO
		for n in _crowd:
			acc += n.global_position
		_c = _planet.surface_point(acc / float(_crowd.size()))
	else:
		_c = _planet.surface_point(_planet.step_dir(_pad_up, (_pad_up + axis * 0.3).normalized(), CROWD_FALLBACK_M))
	_up_c = _planet.dir_of(_c)
	var to_pad := pad_ground - _c
	_b_c = (to_pad - _up_c * to_pad.dot(_up_c)).normalized()
	# The rock: the meeting's GiantAsteroid, or where it would hang (§4) if there is none.
	if _asteroid != null and is_instance_valid(_asteroid):
		_rock_c = _asteroid.call("centre") as Vector3 if _asteroid.has_method("centre") else _asteroid.global_position
		if _asteroid.has_method("bounding_radius"):
			_rock_r = float(_asteroid.call("bounding_radius"))
	else:
		var bearing := _b_c.rotated(_up_c, deg_to_rad(20.0))
		_rock_c = _c + (bearing * cos(deg_to_rad(24.0)) + _up_c * sin(deg_to_rad(24.0))) * 130.0
	var rock_t := _rock_c - _c
	rock_t = rock_t - _up_c * rock_t.dot(_up_c)
	var side := _up_c.cross(_b_c).normalized()
	_s_c = side if rock_t.dot(side) >= 0.0 else -side
	# The flight: lift point, straight up, then onto the line into the rock.
	_lift = _rest.origin + _pad_up * IGNITION_LIFT
	# The climb leans out to the far side from the rock first, so the rocket arcs ACROSS the view from
	# behind the crowd and is seen side-on as she goes, rather than shrinking straight away nose-first.
	var p1 := _lift + _pad_up * CLIMB_UP_M - _s_c * CLIMB_SIDE_M
	var d_in := (_rock_c - p1).normalized()
	_hit = _rock_c - d_in * _rock_r * HIT_DEPTH
	var p2 := _hit - d_in * APPROACH_M
	_bz = PackedVector3Array([_lift, p1, p2, _hit])
	_bz_len = PackedFloat32Array()
	var acc_len := 0.0
	var prev := _lift
	_bz_len.append(0.0)
	for i in range(1, 201):
		var q := _bezier(float(i) / 200.0)
		acc_len += q.distance_to(prev)
		prev = q
		_bz_len.append(acc_len)
	# The astronaut keeps their spot and turns from the crowd to the rock.
	_astro_p = _player.global_position
	_astro_up = _planet.dir_of(_astro_p)
	_astro_face0 = _tangent(-_player.global_basis.z, _astro_up, _b_c)
	_astro_face1 = _tangent(_rock_c - _astro_p, _astro_up, _b_c)
	# Which side of the crowd the camera works from (see `_pick_side`).
	var heads := _head_points()
	_side_sign = _side_for(heads)
	# Look keyframes.
	var ea := _eye_at(A_ALPHA, A_RHO, A_H)
	var ya := _yaw_pitch(ea, _rest.origin + _pad_up * (RocketModel.TOTAL_HEIGHT * 0.5))
	var yr := _yaw_pitch(ea, _rock_c)
	var ytop := _yaw_pitch(ea, _rest.origin + _pad_up * (RocketModel.TOTAL_HEIGHT + 0.3))
	var low := ytop.y
	for hp in heads:
		low = minf(low, _yaw_pitch(ea, hp).y)
	_a_yaw = _lerp_angle(ya.x, yr.x, A_ROCK_YAW_SHARE)
	# The nearest heads' tops A_HEADS_FROM_TOP down the frame; the rock's centre no higher than the top
	# edge (§2 "half the rock"), the rocket between them.
	_a_pitch = low + rad_to_deg(atan((A_HEADS_FROM_TOP - 0.5) * 2.0 * tan(deg_to_rad(A_FOV * 0.5))))
	_a_pitch = maxf(_a_pitch, yr.y - A_FOV * 0.5)
	var eb := _eye_at(B_ALPHA, B_RHO, B_H)
	var rb := _yaw_pitch(eb, _rock_c)
	_b_yaw = rb.x
	_b_pitch = rb.y - B_ROCK_UP * B_FOV * 0.5
	var ed := _eye_at(D_ALPHA, D_RHO, D_H)
	var yaws := PackedFloat32Array()
	var pitch_sum := 0.0
	for hp in heads:
		var yp := _yaw_pitch(ed, hp)
		yaws.append(yp.x)
		pitch_sum += yp.y
	var ref := _yaw_pitch(ed, _c).x
	var ysum := 0.0
	for y in yaws:
		ysum += fposmod(y - ref + 180.0, 360.0) - 180.0
	var astro := _yaw_pitch(ed, _astro_p + _astro_up * 1.0)
	var crowd_yaw := ref + ysum / maxf(1.0, float(yaws.size()))
	_d_yaw = _lerp_angle(crowd_yaw, astro.x, D_ASTRO_YAW_SHARE)
	var head_pitch := pitch_sum / maxf(1.0, float(heads.size()))
	# Heads at D_HEADS_FROM_TOP of the frame height: the sky and the streaks over them.
	_d_pitch = head_pitch + rad_to_deg(atan((D_HEADS_FROM_TOP - 0.5) * 2.0 * tan(deg_to_rad(D_FOV * 0.5))))
	# The seed: the meeting's camera if it has one, else whatever is drawing now.
	_rng.seed = SHOWER_SEED


## The seed is the camera drawing right now - the meeting's, or whatever holds the view if the meeting's
## camera is not current - so the first frame of the shot is exactly the frame before it.
func _read_seed() -> void:
	var seed_cam := get_viewport().get_camera_3d()
	if seed_cam == null and _meeting_cam != null and is_instance_valid(_meeting_cam):
		seed_cam = _meeting_cam
	_has_seed = seed_cam != null
	if _has_seed:
		_seed_xf = seed_cam.global_transform
		_seed_fov = seed_cam.fov
		var r0 := _rule(0.0)
		var dist := (_seed_xf.origin).distance_to(r0[0] as Vector3)
		var ang := rad_to_deg(_seed_xf.basis.get_rotation_quaternion().angle_to((r0[1] as Basis).get_rotation_quaternion()))
		# Seed blend long enough that its own peak (1.875x average for smootherstep) stays inside the
		# limits with room for the crane that starts at CRANE_T.x.
		_seed_s = clampf(maxf(dist * 1.875 / 1.6, ang * 1.875 / 24.0), SEED_MIN_S, SEED_MAX_S)


## The side pick the meeting's `opening_frame` left (see SIDE_META), else a fresh `_pick_side`.
## Crowd moved more than SIDE_REUSE_M: a full pick. Crowd in place but the decoration list changed (placed,
## moved or picked up in free roam): `_recheck_side` casts the stored lines against ONLY the added or
## moved decorations - no full occluder rebuild on the shot's first frame (that rebuild measured 34-41 ms,
## a 54-57 ms frame at shot 0.00 in 4 of 4 runs, L2U critic 1).
func _side_for(heads: PackedVector3Array) -> float:
	if not _force_side_pick and _meeting != null and is_instance_valid(_meeting) and _meeting.has_meta(SIDE_META):
		var m: Dictionary = _meeting.get_meta(SIDE_META)
		var drift := _c.distance_to(m.get("c", Vector3.INF) as Vector3)
		var decor_now := _decor_sig()
		var decor_same: bool = m.has("decor") and str(m["decor"]) == decor_now
		if drift <= SIDE_REUSE_M and decor_same:
			_side_note = "side=%+d reused from opening_frame (crowd centre drift %.2f m, decorations unchanged [%s]; %s)" % [int(float(m["sign"])), drift, decor_now, str(m.get("note", ""))]
			return float(m["sign"])
		if drift <= SIDE_REUSE_M:
			var re := _recheck_side(m)
			if not is_nan(re):
				_side_note = "opening_frame side rechecked (crowd centre drift %.2f m; decorations CHANGED [%s] -> [%s]): %s; then: %s" % [drift,
					str(m.get("decor", "-")), decor_now, _side_note, str(m.get("note", ""))]
				return re
		var pick := _pick_side(heads)
		_side_note = "opening_frame side stale (crowd centre drift %.2f m; decorations %s [%s] -> [%s]), picked again: %s" % [drift,
			"unchanged" if decor_same else "CHANGED", str(m.get("decor", "-")), decor_now, _side_note]
		return pick
	return _pick_side(heads)


## The placed-decoration list as {instance id: hash of its entry (item, position, basis)}.
static func _decor_map() -> Dictionary:
	var out := {}
	for e: Variant in GameState.placed_decorations.get(GameState.current_planet_id, []):
		if e is Dictionary:
			out[str((e as Dictionary).get("id", ""))] = var_to_str(e).hash()
	return out


## THE DECORATION-ONLY RECHECK. Every stored line of BOTH sides that was clear when `opening_frame` cast it
## is cast again against a private physics space holding only the decorations added or moved since (their
## real triangles, with VisitorSystem's own "stands up" and "glow" filters); a line it now hits counts as
## blocked, and the side is scored by the same rule as `_pick_side` (fewer blocked lines, the rock's side
## on a tie). So a decoration off both sides' lines keeps the side, one on the chosen side's lines flips it
## only when the other side is now better. A picked-up decoration can only clear lines: its stored hits are
## kept (the side it left can stay slightly under-scored; never a hidden blocker). NAN when the meta carries
## no lines or the Decorations node or sight filters are missing (the caller then does the full pick).
func _recheck_side(m: Dictionary) -> float:
	if not m.has("lines") or not m.has("decor_map") or not m.has("sign"):
		return NAN
	var lines: Dictionary = m["lines"]
	if not lines.has(1.0) or not lines.has(-1.0):
		return NAN
	const VS_PATH := "res://src/campaign/visitor_system.gd"
	var vs: Node = load(VS_PATH).call("find") if ResourceLoader.exists(VS_PATH) else null
	var dm := get_tree().root.get_node_or_null("World/Decorations")
	if vs == null or dm == null or not dm.has_method("get_instances") or not vs.has_method("_stands_up") \
			or not vs.has_method("_is_glow"):
		return NAN
	var u0 := Time.get_ticks_usec()
	var old_map: Dictionary = m["decor_map"]
	var new_map := _decor_map()
	var changed := {}
	for id: String in new_map:
		if not old_map.has(id) or int(old_map[id]) != int(new_map[id]):
			changed[id] = true
	var removed := 0
	for id: String in old_map:
		if not new_map.has(id):
			removed += 1
	var space := RID()
	var bodies: Array[RID] = []
	var shapes: Array[Shape3D] = []
	var names := {}
	var meshes := 0
	for rec: Dictionary in dm.call("get_instances"):
		if not changed.has(str(rec.get("id", ""))):
			continue
		var node := rec.get("node") as Node3D
		if node == null or not is_instance_valid(node):
			continue
		for c: Node in node.find_children("*", "MeshInstance3D", true, false):
			var mi := c as MeshInstance3D
			if mi.mesh == null or not mi.is_visible_in_tree() or bool(vs.call("_is_glow", mi)) \
					or not bool(vs.call("_stands_up", mi.global_transform, mi.get_aabb())):
				continue
			var faces := mi.mesh.get_faces()
			if faces.size() < 3:
				continue
			if not space.is_valid():
				space = PhysicsServer3D.space_create()
				PhysicsServer3D.space_set_active(space, true)
			var shape := ConcavePolygonShape3D.new()
			shape.set_faces(faces)
			shape.backface_collision = true
			shapes.append(shape)
			var b := PhysicsServer3D.body_create()
			PhysicsServer3D.body_set_mode(b, PhysicsServer3D.BODY_MODE_STATIC)
			PhysicsServer3D.body_set_space(b, space)
			PhysicsServer3D.body_add_shape(b, shape.get_rid())
			PhysicsServer3D.body_set_state(b, PhysicsServer3D.BODY_STATE_TRANSFORM, mi.global_transform)
			PhysicsServer3D.body_set_collision_layer(b, 1)
			PhysicsServer3D.body_set_collision_mask(b, 0)
			bodies.append(b)
			names[b] = str(mi.get_path())
			meshes += 1
	var u1 := Time.get_ticks_usec()
	var scores := {}
	var notes := {}
	var state: PhysicsDirectSpaceState3D = PhysicsServer3D.space_get_direct_state(space) if space.is_valid() else null
	for sign: float in [1.0, -1.0]:
		var n := 0
		var fresh := PackedStringArray()
		for l: Array in lines[sign]:
			if str(l[3]) != "":
				n += 1
				continue
			if state == null:
				continue
			var q := PhysicsRayQueryParameters3D.create(l[0] as Vector3, l[1] as Vector3, 1)
			q.hit_back_faces = true
			var hit := state.intersect_ray(q)
			if not hit.is_empty():
				n += 1
				if fresh.size() < 6:
					fresh.append("%s:%s" % [l[2], str(names.get(hit.get("rid", RID()), "?")).get_file()])
		scores[sign] = n
		notes[sign] = ",".join(fresh)
	for b in bodies:
		PhysicsServer3D.free_rid(b)
	if space.is_valid():
		PhysicsServer3D.free_rid(space)
	shapes.clear()
	var was := float(m["sign"])
	var pick := 1.0 if int(scores[1.0]) <= int(scores[-1.0]) else -1.0
	_side_note = "side=%+d (was %+d) changed=%d removed=%d meshes=%d blocked rock-side=%d new[%s] other=%d new[%s] build %.2f ms, lines %.2f ms" % [
		int(pick), int(was), changed.size(), removed, meshes, int(scores[1.0]), notes[1.0], int(scores[-1.0]), notes[-1.0],
		(u1 - u0) / 1000.0, (Time.get_ticks_usec() - u1) / 1000.0]
	return pick


## The planet's placed-decoration list as the side pick saw it: "<count>:<hash>" over every entry (id,
## item, position, basis), so a placement, a pick-up or a move all change it.
static func _decor_sig() -> String:
	var list: Array = GameState.placed_decorations.get(GameState.current_planet_id, [])
	return "%d:%x" % [list.size(), var_to_str(list).hash()]


## THE CAMERA'S SIDE. The authored eyes (A behind the crowd, the crane above it, the swing, D in front of
## the faces) sit on the rock's side of the crowd by default, or mirrored onto the other side. The Commons
## is decorated by the player, so a lamp, a sign or a pole can stand exactly where an eye looks from:
## MEASURED (L2U probe, dev stand-in meeting) a striped pole filled a third of the opening frame and hid
## the rocket, and stood in front of the faces at 22 s. Each side is scored by VisitorSystem's sight lines
## (real triangles of props, buildings, decorations, the pad, the rocket at rest and the astronaut): A's
## lines to the rocket and every head, the crane's and the swing's lines back to the crowd, and D's lines
## to every head and the astronaut; the side with fewer blocked lines wins, the rock's side on a tie.
## Without VisitorSystem's sight API the default side is kept.
func _pick_side(heads: PackedVector3Array) -> float:
	_side_lines = {}
	const VS_PATH := "res://src/campaign/visitor_system.gd"
	if not ResourceLoader.exists(VS_PATH):
		return 1.0
	var vs: Node = load(VS_PATH).call("find")
	if vs == null or not vs.has_method("open_sight") or not vs.has_method("sight_blocker"):
		return 1.0
	var u0 := Time.get_ticks_usec()
	vs.call("open_sight", _c, SIGHT_REACH)
	var u1 := Time.get_ticks_usec()
	var scores := {}
	var notes := {}
	var rocket_mid := _rest.origin + _pad_up * (RocketModel.TOTAL_HEIGHT * 0.5)
	var rocket_top := _rest.origin + _pad_up * (RocketModel.TOTAL_HEIGHT - 0.2)
	var astro_head := _astro_p + _astro_up * HEAD_H
	var crowd_eye := _c + _up_c * 1.6
	for sign: float in [1.0, -1.0]:
		_side_sign = sign
		var lines: Array = []
		var ea := _eye_at(A_ALPHA, A_RHO, A_H)
		lines.append([ea, _short_of(ea, rocket_mid, SIGHT_ROCKET_CLEAR), "A>rocket"])
		lines.append([ea, _short_of(ea, rocket_top, SIGHT_ROCKET_CLEAR), "A>rocket top"])
		for hp in heads:
			lines.append([ea, hp, "A>head"])
		var eb := _eye_at(B_ALPHA, B_RHO, B_H)
		var em := _eye_at(lerpf(A_ALPHA, D_ALPHA, 0.5), lerpf(B_RHO, D_RHO, 0.5), lerpf(B_H, D_H, 0.5))
		lines.append([crowd_eye, eb, "crowd>crane"])
		lines.append([crowd_eye, em, "crowd>swing"])
		var ed := _eye_at(D_ALPHA, D_RHO, D_H)
		lines.append([crowd_eye, ed, "crowd>D"])
		for hp in heads:
			lines.append([ed, hp, "D>head"])
		lines.append([ed, _short_of(ed, astro_head, SIGHT_ASTRO_CLEAR), "D>astronaut"])
		var n := 0
		var why := PackedStringArray()
		for l: Array in lines:
			var hit := str(vs.call("sight_blocker", l[0] as Vector3, l[1] as Vector3))
			l.append(hit)
			if hit != "":
				n += 1
				if why.size() < 6:
					why.append("%s:%s" % [l[2], hit.get_file()])
		scores[sign] = n
		notes[sign] = ",".join(why)
		_side_lines[sign] = lines
	if vs.has_method("close_sight"):
		vs.call("close_sight")
	var pick := 1.0 if int(scores[1.0]) <= int(scores[-1.0]) else -1.0
	_side_note = "side=%+d blocked rock-side=%d [%s] other=%d [%s] open_sight %.1f ms, lines %.1f ms" % [int(pick),
		int(scores[1.0]), notes[1.0], int(scores[-1.0]), notes[-1.0], (u1 - u0) / 1000.0, (Time.get_ticks_usec() - u1) / 1000.0]
	return pick


static func _short_of(a: Vector3, b: Vector3, clear_m: float) -> Vector3:
	var d := b - a
	var l := d.length()
	return b if l <= clear_m + 0.01 else a + d * ((l - clear_m) / l)


## Head tops of the crowd (or of the §2 rows along the axis when there is no crowd).
func _head_points() -> PackedVector3Array:
	var out := PackedVector3Array()
	for n in _crowd:
		if is_instance_valid(n):
			out.append(n.global_position + _planet.dir_of(n.global_position) * HEAD_H)
	if out.is_empty():
		out.append(_c + _up_c * HEAD_H)
	return out


func _build_nodes() -> void:
	_cam = Camera3D.new()
	_cam.name = "SendOffCamera"
	var src := get_viewport().get_camera_3d()
	if src == null:
		src = _meeting_cam if _meeting_cam != null and is_instance_valid(_meeting_cam) else null
	if src != null:
		_cam.cull_mask = src.cull_mask
		_cam.fov = src.fov
	_cam.near = CAM_NEAR
	_cam.far = CAM_FAR
	add_child(_cam)
	if _has_seed:
		_cam.global_transform = _seed_xf
	_flash = CrashFx.flash()
	add_child(_flash)
	_dust = CrashFx.dust_ring()
	add_child(_dust)
	_dust.global_transform = Transform3D(_rest.basis.orthonormalized(), _rest.origin)
	_build_shower()
	_build_skip_hint()


func _build_shower() -> void:
	if not ResourceLoader.exists(SHOWER_PATH) or _debug_no_shower:
		return
	_shower = (load(SHOWER_PATH) as GDScript).new() as MultiMeshInstance3D
	add_child(_shower)
	_shower.global_transform = Transform3D.IDENTITY
	var eye := _c + _up_c * 1.2
	_shower.call("setup", eye, _up_c, _rock_c, SHOWER_SEED)


## The whole shower, decided up front from a seeded generator, so a run is the same run every time and
## a skip never changes what the natural end would have been.
func _schedule_shower() -> void:
	if _shower == null:
		return
	# Shell waves: a swell of streaks over WAVE_S after each wave time (sin^2-shaped density).
	for w in WAVE_T.size():
		var n := WAVE_COUNTS[w]
		for i in n:
			var u := (float(i) + _rng.randf_range(0.1, 0.9)) / float(n)
			# Inverse of the cumulative sin^2 density on [0, 1] by bisection.
			var lo := 0.0
			var hi := 1.0
			for k in 18:
				var mid := (lo + hi) * 0.5
				if mid - sin(TAU * mid) / TAU < u:
					lo = mid
				else:
					hi = mid
			var t0 := WAVE_T[w] + (lo + hi) * 0.5 * WAVE_S
			_shower.call("add_shell", t0, _frame_at(t0 + 0.4), SHOWER_IN_FRAME)
	# A light base between the waves, then a steadier fall over the faces frame.
	var tb := BASE_T.x
	while tb < BASE_T.y:
		_shower.call("add_shell", tb, _frame_at(tb + 0.4), SHOWER_IN_FRAME)
		tb += 1.0 / BASE_RATE * _rng.randf_range(0.6, 1.4)
	tb = TAIL_T.x
	while tb < TAIL_T.y:
		# The faces frame looks away from the radiant, so its sky is the far band of the shower.
		_shower.call("add_shell", tb, _frame_at(minf(tb + 0.4, END_T)), 0.9, 0, TAIL_THETA)
		tb += 1.0 / TAIL_RATE * _rng.randf_range(0.6, 1.4)
	# Heroes: one per friend, in their accent, placed to cross the frame they will be seen in.
	for i in HERO_T.size():
		var id := FRIENDS[i % FRIENDS.size()]
		var accent := Color(str(NpcData.get_data(id).get("accent", FRIEND_FALLBACK_ACCENT.to_html())))
		_shower.call("add_hero", accent, HERO_T[i], _frame_at(minf(HERO_T[i] + 1.5, END_T)))


# ============================================================================= per frame
func _process(delta: float) -> void:
	_update_hint(delta)
	match _phase:
		Phase.RUNNING:
			if _confirming:
				# SkipConfirm is open: the shot holds (no step, no skip poll, no stall log).
				_last_usec = Time.get_ticks_usec()
				return
			var now := Time.get_ticks_usec()
			var ms := float(now - _last_usec) / 1000.0
			_last_usec = now
			if _t > 0.2 and ms > 50.0:
				_stalls.append("t=%.2f %.0fms%s" % [_t, ms, (" after " + ",".join(_fired_now)) if not _fired_now.is_empty() else ""])
			_fired_now = PackedStringArray()
			_worst_ms = maxf(_worst_ms, ms if _t > 0.2 else 0.0)
			_poll_skip_actions()
			if _phase != Phase.RUNNING:
				return
			var dt := minf(delta, MAX_STEP)
			if _hold_at >= 0.0:
				dt = clampf(_hold_at - _t, 0.0, dt)
			var su := Time.get_ticks_usec()
			_step(dt)
			var step_ms := float(Time.get_ticks_usec() - su) / 1000.0
			_worst_step_ms = maxf(_worst_step_ms, step_ms)
			if step_ms > 8.0:
				_log("slow step %.1f ms" % step_ms)
		Phase.RELEASING:
			_release_t += delta
			if not _held_down() or _release_t >= RELEASE_WAIT_MAX:
				_release()


func _step(dt: float) -> void:
	_t += dt
	var t := _t
	if t >= END_T:
		_update_all(END_T)
		_complete(false)
		return
	_update_all(t)


func _update_all(t: float) -> void:
	_update_rocket(t)
	_update_fx(t)
	_update_rock(t)
	if _shower != null:
		_shower.call("advance_to", t)
	_update_crowd(t)
	_update_astronaut(t)
	_update_audio(t)
	_place_camera(t)


# ============================================================================= the rocket
func _update_rocket(t: float) -> void:
	if t >= HIT_T:
		if _once("rocket_gone"):
			_rocket.set_engine(false)
			_rocket.set_flame_scale(0.0)
			_rocket.visible = false
			_rocket.global_transform = _rest
			_beat("hit t=%.2f" % t)
		return
	_rocket.global_transform = _rocket_xf(t)
	if t >= IGNITE_T:
		if _once("ignite"):
			_rocket.set_engine(true, 1.0)
			_rocket.set_flame_scale(0.05)
			_dust.global_transform = Transform3D(_rest.basis.orthonormalized(), _rest.origin + _pad_up * 0.12)
			_dust.restart()
			_dust.emitting = true
			_beat("ignite t=%.2f" % t)
		var g := clampf((t - IGNITE_T) / IGNITE_GROW, 0.0, 1.0)
		var f := lerpf(0.05, FLAME_IGNITE, 1.0 - (1.0 - g) * (1.0 - g))
		if t >= LIFT_T:
			f = lerpf(FLAME_IGNITE, FLAME_CLIMB, smoothstep(LIFT_T, LIFT_T + 3.0, t))
		_rocket.set_flame_scale(f)
	if t >= SMOKE_OFF_T and _once("smoke_off"):
		_rocket.set_smoke_enabled(false)


func _rocket_xf(t: float) -> Transform3D:
	if t < IGNITE_T:
		return _rest
	if t < LIFT_T:
		var g := clampf((t - IGNITE_T) / IGNITE_GROW, 0.0, 1.0)
		var k := 1.0 - pow(1.0 - g, 3.0)
		return Transform3D(_rest.basis, _rest.origin + _pad_up * IGNITION_LIFT * k)
	var x := clampf((t - LIFT_T) / (HIT_T - LIFT_T), 0.0, 1.0)
	var u := _bz_u(pow(x, FLIGHT_POW))
	var pos := _bezier(u)
	var tan := _bezier_tangent(u)
	if tan.length_squared() < 1e-6:
		tan = _pad_up
	return Transform3D(_nose_basis(tan, -_rest.basis.z), pos)


func _rocket_mid(t: float) -> Vector3:
	var xf := _rocket_xf(t)
	return xf.origin + xf.basis.y.normalized() * RocketModel.TOTAL_HEIGHT * 0.5


func _bezier(u: float) -> Vector3:
	var v := 1.0 - u
	return _bz[0] * v * v * v + _bz[1] * 3.0 * v * v * u + _bz[2] * 3.0 * v * u * u + _bz[3] * u * u * u


func _bezier_tangent(u: float) -> Vector3:
	var v := 1.0 - u
	return (_bz[1] - _bz[0]) * 3.0 * v * v + (_bz[2] - _bz[1]) * 6.0 * v * u + (_bz[3] - _bz[2]) * 3.0 * u * u


## Bezier parameter at a share `s` of the path's arc length.
func _bz_u(s: float) -> float:
	var target := clampf(s, 0.0, 1.0) * _bz_len[_bz_len.size() - 1]
	var i := _bz_len.bsearch(target)
	if i <= 0:
		return 0.0
	if i >= _bz_len.size():
		return 1.0
	var a := _bz_len[i - 1]
	var b := _bz_len[i]
	var f := (target - a) / maxf(b - a, 1e-6)
	return (float(i - 1) + f) / float(_bz_len.size() - 1)


static func _nose_basis(nose: Vector3, face: Vector3) -> Basis:
	var y := nose.normalized()
	var f := face - y * face.dot(y)
	if f.length_squared() < 1e-8:
		f = y.cross(Vector3.RIGHT)
	var z := -f.normalized()
	var x := y.cross(z).normalized()
	return Basis(x, y, z)


# ============================================================================= flash, dust, rock
func _update_fx(t: float) -> void:
	if t >= HIT_T and t < HIT_T + FLASH_LIFE + 0.1:
		var tau := t - HIT_T
		var k := 0.0
		if tau < FLASH_GROW:
			k = smoothstep(0.0, FLASH_GROW, tau)
		else:
			k = 1.0 - smoothstep(FLASH_GROW, FLASH_LIFE, tau)
		var size := maxf(k, 0.001) * _rock_r * 2.0 * FLASH_SIZE / 1.5
		var cam_pos := _cam.global_position if _cam != null else _hit
		var toward := (cam_pos - _hit).normalized()
		_flash.global_transform = Transform3D(Basis.looking_at(-toward, _up_c).scaled(Vector3(size, size, size)), _hit + toward * (_rock_r * 0.3))
		_flash.visible = k > 0.002
	elif _flash.visible:
		_flash.visible = false


func _update_rock(t: float) -> void:
	if _asteroid == null or not is_instance_valid(_asteroid):
		return
	if t >= HIT_T and _asteroid.has_method("break_at"):
		_asteroid.call("break_at", t - HIT_T)
	if t >= REMNANT_SHRINK.x:
		var k := 1.0 - smoothstep(REMNANT_SHRINK.x, REMNANT_SHRINK.y, t)
		if k <= 0.0005:
			if _asteroid.visible:
				_asteroid.visible = false
				_beat("rock gone t=%.2f" % t)
		else:
			_asteroid.scale = Vector3.ONE * k
	# Chunks streak away one by one (§2 "streaks start from chunk_positions()"). Their directions are read
	# once, before the remnant shrinks, so a late chunk still leaves along its own radial line.
	if _shower != null and _asteroid.has_method("chunk_positions") and t >= CHUNK_STREAK_T:
		if _chunk_dirs.is_empty():
			var pts: PackedVector3Array = _asteroid.call("chunk_positions")
			for p in pts:
				_chunk_dirs.append(p - _rock_c)
		var k := _asteroid.scale.x if _asteroid.visible else 0.0
		for i in _chunk_dirs.size():
			var order := (i * 7) % _chunk_dirs.size()
			var ti := CHUNK_STREAK_T + float(order) * CHUNK_STREAK_GAP
			if t >= ti and _once("chunk%d" % i):
				_shower.call("add_chunk", _rock_c, _chunk_dirs[i], maxf(k, 0.05), ti, i % 3 == 0)


# ============================================================================= crowd and astronaut
func _update_crowd(t: float) -> void:
	var look := _rocket_mid(minf(t, HIT_T - 0.01)) if t < HIT_T else _rock_c
	for i in _crowd.size():
		var n := _crowd[i]
		if not is_instance_valid(n):
			continue
		if n.has_method("hold_facing"):
			n.call("hold_facing", look)
		var id := _crowd_ids[i] if i < _crowd_ids.size() else ""
		if not n.has_method("play_emote"):
			continue
		if id == DJ_NOVA:
			for k in DANCE_T.size():
				if t >= DANCE_T[k] and _once("dance%d" % k):
					n.call("play_emote", "dance")
		else:
			if t >= CHEER_T + 0.11 * float(i) and _once("cheer_%d" % i):
				n.call("play_emote", "happy")
			if i % 2 == 0 and t >= CHEER2_T + 0.13 * float(i) and _once("cheer2_%d" % i):
				n.call("play_emote", "happy")


func _freeze_player() -> void:
	_player.input_enabled = false
	_player.velocity = Vector3.ZERO
	var model := _player.get_model()
	if model != null:
		model.set_state("idle")


func _update_astronaut(t: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var w := smoothstep(0.3, 1.5, t)
	var face := _astro_face0.slerp(_astro_face1, w).normalized() if _astro_face0.dot(_astro_face1) > -0.99 else _astro_face1
	if _player.is_physics_processing():
		_player.velocity = Vector3.ZERO
	var p := _astro_p
	var model := _player.get_model()
	if t >= ASTRO_CHEER_T and t < ASTRO_CHEER_T + ASTRO_CHEER_S:
		if _once("astro_cheer"):
			# This node poses the model for the cheer, so physics must not re-pick "idle" under it.
			_player.set_physics_process(false)
			if model != null:
				model.set_state("happy")
	elif t >= ASTRO_CHEER_T + ASTRO_CHEER_S and _once("astro_cheer_end"):
		if model != null:
			model.set_state("idle")
		_player.set_physics_process(true)
	_player.global_transform = Transform3D(_face_basis(face, _astro_up), p)


# ============================================================================= sound and music
func _update_audio(t: float) -> void:
	if t >= IGNITE_T and _once("sfx_ignite"):
		_sfx_at("rocket_ignite", _rocket.engine_point(), 1.0)
		if AudioManager.sfx_exists("rocket_loop"):
			AudioManager.start_loop("rocket_loop", -8.0, 0.5)
		# §2: the music fades at ignition.
		AudioManager.play_music("", MUSIC_FADE)
	if t >= HIT_T and _once("loop_off"):
		AudioManager.stop_loop("rocket_loop", 0.3)
	if t >= IMPACT_SFX_T and _once("sfx_impact"):
		_sfx("finale_impact", -2.0, 0.0)
	for i in WAVE_T.size():
		if t >= WAVE_T[i] and _once("sfx_wave%d" % i):
			_sfx("finale_shower", -4.0, 0.0)
			_beat("wave %d t=%.2f" % [i, t])
	for i in HERO_T.size():
		if t >= HERO_T[i] and _once("sfx_hero%d" % i):
			_hero_sfx(i)


func _sfx(sfx_name: String, db: float, pitch_var: float) -> void:
	if AudioManager.sfx_exists(sfx_name):
		AudioManager.play_sfx(sfx_name, db, pitch_var)


func _sfx_at(sfx_name: String, at: Vector3, db: float) -> void:
	if AudioManager.sfx_exists(sfx_name):
		AudioManager.play_sfx_at(sfx_name, at, db)


## §5 "pitched per star": its own player, a step of a pentatonic-ish climb per hero.
func _hero_sfx(i: int) -> void:
	const NAME := "finale_hero_star"
	if not AudioManager.sfx_exists(NAME):
		return
	var path := AudioManager.SFX_DIR + NAME + ".wav"
	if not ResourceLoader.exists(path):
		path = AudioManager.SFX_DIR + NAME + ".ogg"
	var p := AudioStreamPlayer.new()
	p.stream = load(path) as AudioStream
	p.bus = "SFX"
	p.volume_db = -5.0
	const STEPS: Array[float] = [1.0, 1.122, 1.26, 1.498, 1.682]
	p.pitch_scale = STEPS[i % STEPS.size()]
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()


# ============================================================================= the camera
## The ground frame at the crowd, carried to a point: (toward the pad, toward the rock's side, up).
func _frame_at_point(dir: Vector3) -> Basis:
	var up := dir.normalized()
	var b := _b_c - up * _b_c.dot(up)
	if b.length_squared() < 1e-6:
		b = _s_c.cross(up)
	b = b.normalized()
	var s := _s_c - up * _s_c.dot(up)
	s = (s - b * s.dot(b)).normalized()
	return Basis(b, s, up)


## An eye `rho` metres along the ground from the crowd centre at `alpha_deg` round from the pad bearing
## (positive toward the rock's side), `h` metres above the ground.
func _eye_at(alpha_deg: float, rho: float, h: float) -> Vector3:
	var a := deg_to_rad(alpha_deg * _side_sign)
	var v := _b_c * cos(a) + _s_c * sin(a)
	var ang := rho / maxf(_planet.radius, 1.0)
	var dir := (_up_c * cos(ang) + v * sin(ang)).normalized()
	return _planet.surface_point(dir) + dir * h


## Yaw (deg, 0 = toward the pad bearing, positive toward the rock's side) and pitch (deg above the
## local horizontal) of `target` from `eye`, in the eye's own ground frame.
func _yaw_pitch(eye: Vector3, target: Vector3) -> Vector2:
	var f := _frame_at_point(_planet.dir_of(eye))
	var v := (target - eye).normalized()
	return Vector2(rad_to_deg(atan2(v.dot(f.y), v.dot(f.x))), rad_to_deg(asin(clampf(v.dot(f.z), -1.0, 1.0))))


func _dir_from(eye: Vector3, yaw_deg: float, pitch_deg: float) -> Vector3:
	var f := _frame_at_point(_planet.dir_of(eye))
	var y := deg_to_rad(yaw_deg)
	var p := deg_to_rad(pitch_deg)
	return (f.x * cos(y) * cos(p) + f.y * sin(y) * cos(p) + f.z * sin(p)).normalized()


## The authored camera at shot time `t`: [eye, basis, fov, pitch_deg].
func _rule(t: float) -> Array:
	var c := _trap((t - CRANE_T.x) / (CRANE_T.y - CRANE_T.x), CRANE_SHAPE.x, CRANE_SHAPE.y)
	var w := _trap((t - SWING_T.x) / (SWING_T.y - SWING_T.x), SWING_SHAPE.x, SWING_SHAPE.y)
	var alpha := lerpf(lerpf(A_ALPHA, B_ALPHA, c), D_ALPHA, w)
	var rho := lerpf(lerpf(A_RHO, B_RHO, c), D_RHO, w) - D_CREEP_M * smoothstep(SWING_T.y - 0.8, END_T, t)
	var h := lerpf(lerpf(A_H, B_H, c), D_H, w)
	var eye := _eye_at(alpha, rho, h)
	# Look: opening frame -> follow the rocket -> the rock -> the faces.
	var base_yaw := _lerp_angle(_a_yaw, _b_yaw, smoothstep(ROCK_LOOK.x, ROCK_LOOK.y, t))
	var base_pitch := lerpf(_a_pitch, _b_pitch, smoothstep(ROCK_LOOK.x, ROCK_LOOK.y, t))
	var wr := smoothstep(TRACK_IN.x, TRACK_IN.y, t) * (1.0 - smoothstep(TRACK_OUT.x, TRACK_OUT.y, t))
	var yaw := base_yaw
	var pitch := base_pitch
	if wr > 0.0 and t < HIT_T:
		var lead := _rocket_mid(t).lerp(_rock_c, TRACK_LEAD)
		var tp := _yaw_pitch(eye, lead)
		yaw = _lerp_angle(base_yaw, tp.x, wr)
		pitch = lerpf(base_pitch, tp.y, wr)
	if w > 0.0:
		# The long way round, turning away from the pad bearing, so the pad and its mast stay behind the
		# camera for the whole swing (the short way swept the mast across the frame at 16-18 s).
		yaw = yaw + _turn_away_from_pad(yaw, _d_yaw) * w
		pitch = lerpf(pitch, _d_pitch, w) + SWING_LIFT_DEG * sin(PI * w)
	var fov := lerpf(lerpf(A_FOV, B_FOV, smoothstep(FOV_IN.x, FOV_IN.y, t)), D_FOV, w)
	var d := _dir_from(eye, yaw, pitch)
	var up := _planet.dir_of(eye)
	var basis := Basis.looking_at(d, up if absf(d.dot(up)) < 0.985 else _b_c)
	return [eye, basis, fov, pitch]


## `[Transform3D, vfov, aspect]` of the authored camera at `t`, for placing streaks where they are seen.
func _frame_at(t: float) -> Array:
	var r := _rule(t)
	var vp := get_viewport().get_visible_rect().size
	return [Transform3D(r[1] as Basis, r[0] as Vector3), float(r[2]), vp.x / maxf(vp.y, 1.0)]


func _place_camera(t: float) -> void:
	var r := _rule(t)
	var eye: Vector3 = r[0]
	var basis: Basis = r[1]
	var fov: float = r[2]
	if _has_seed and t < _seed_s:
		var k := 1.0 - _smootherstep(clampf(t / _seed_s, 0.0, 1.0))
		eye = eye.lerp(_seed_xf.origin, k)
		var q := basis.get_rotation_quaternion().slerp(_seed_xf.basis.get_rotation_quaternion(), k)
		basis = Basis(q)
		fov = lerpf(fov, _seed_fov, k)
	var xf := Transform3D(basis, eye)
	# The limiter: whatever the rules ask, the rendered camera moves at most this far this frame.
	if _have_last:
		var dt := maxf(t - _last_t, 0.0)
		var max_m := CAM_MAX_SPEED * dt
		var max_deg := CAM_MAX_TURN_DEG * dt
		var dm := xf.origin.distance_to(_last_xf.origin)
		var q0 := _last_xf.basis.get_rotation_quaternion()
		var q1 := xf.basis.get_rotation_quaternion()
		var da := rad_to_deg(q0.angle_to(q1))
		var limited := false
		if dm > max_m + 1e-5:
			xf.origin = _last_xf.origin + (xf.origin - _last_xf.origin) * (max_m / dm)
			limited = true
		if da > max_deg + 1e-4:
			xf.basis = Basis(q0.slerp(q1, max_deg / da))
			limited = true
		if limited:
			_limited_frames += 1
		if dt > 0.0001:
			_max_speed = maxf(_max_speed, xf.origin.distance_to(_last_xf.origin) / dt)
			_max_turn = maxf(_max_turn, rad_to_deg(q0.angle_to(xf.basis.get_rotation_quaternion())) / dt)
	_last_xf = xf
	_last_t = t
	_have_last = true
	_cam.global_transform = xf
	_cam.fov = fov
	var tau := t - IGNITE_T
	if tau >= 0.0 and tau <= SHAKE.y:
		var k2 := 1.0 - tau / SHAKE.y
		var s := SHAKE.x * k2 * k2
		_cam.h_offset = s * (sin(t * 41.0) * 0.6 + sin(t * 73.3 + 1.7) * 0.4)
		_cam.v_offset = s * (sin(t * 37.5 + 0.9) * 0.6 + sin(t * 89.1) * 0.4)
	else:
		_cam.h_offset = 0.0
		_cam.v_offset = 0.0
	if _trace_on:
		_trace_row(t, float(r[3]), Transform3D(r[1] as Basis, r[0] as Vector3))


## Hands the view on at the end: the meeting's camera takes this camera's last frame, so whoever frames
## the gift next (camera_to) starts from exactly the picture on screen. Without a meeting camera the
## rig takes over (a cut, but only when the meeting is missing).
func _hand_camera_on() -> void:
	var cam_xf := _cam.global_transform if _cam != null and is_instance_valid(_cam) else Transform3D.IDENTITY
	var fov := _cam.fov if _cam != null and is_instance_valid(_cam) else 45.0
	if _cam != null and is_instance_valid(_cam) and _skipped:
		# A skip lands on the natural final frame, not wherever the shot was when the key went down.
		var r := _rule(END_T)
		cam_xf = Transform3D(r[1] as Basis, r[0] as Vector3)
		fov = float(r[2])
	if _meeting_cam != null and is_instance_valid(_meeting_cam):
		_meeting_cam.global_transform = cam_xf
		_meeting_cam.fov = fov
		_meeting_cam.current = true
	elif _rig != null and is_instance_valid(_rig) and _rig.get_camera() != null:
		_rig.reseat_behind_player()
		_rig.get_camera().current = true
	if _cam != null and is_instance_valid(_cam):
		_cam.current = false
		_cam.queue_free()
	_cam = null


# ============================================================================= skip and end
func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			_touches[st.index] = true
		else:
			_touches.erase(st.index)
	if _phase != Phase.RUNNING or _confirming or _t < SKIP_ARM_T:
		return
	if _is_skip_press(event):
		get_viewport().set_input_as_handled()
		_ask_skip(event.as_text())


static func _is_skip_press(event: InputEvent) -> bool:
	if event is InputEventKey:
		var k := event as InputEventKey
		return k.pressed and not k.echo
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		return mb.pressed and mb.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]
	if event is InputEventScreenTouch:
		return (event as InputEventScreenTouch).pressed
	if event is InputEventJoypadButton:
		return (event as InputEventJoypadButton).pressed
	return false


## Director taps (Input.action_press sends no InputEvent). `_skip_primed` swallows an action already
## held when the shot began - the tap that chose "Send her", say.
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
		_ask_skip("action")


## Asks first (SkipConfirm), holding the shot while the question is open; see SKIP in the header.
func _ask_skip(why: String) -> void:
	if _phase != Phase.RUNNING or _confirming:
		return
	if not ResourceLoader.exists(SKIP_CONFIRM_PATH):
		push_warning("FinaleLaunch: %s is missing; skipping without asking" % SKIP_CONFIRM_PATH)
		_skip(why)
		return
	_confirming = true
	_confirm_count += 1
	var t_open := _t
	var u_open := Time.get_ticks_usec()
	_beat("skip asked (%s) at t=%.2f" % [why, _t])
	_hold_effects(true)
	var go: bool = await (load(SKIP_CONFIRM_PATH) as Script).call("ask", self, SKIP_QUESTION, SKIP_YES, SKIP_NO)
	_confirming = false
	if not is_inside_tree() or _phase != Phase.RUNNING:
		return
	_hold_effects(false)
	_last_usec = Time.get_ticks_usec()
	_beat("skip %s at t=%.2f after %.2f s open (clock at open %.4f, now %.4f)" % ["confirmed" if go else "declined",
		_t, (Time.get_ticks_usec() - u_open) / 1e6, t_open, _t])
	if not go:
		# The key or button that answered is also a skip action: resync the edge detector to what is down
		# now, or a still-held answer reads as a new press next frame and asks again at once.
		for a: String in SKIP_ACTIONS:
			_skip_held[a] = InputMap.has_action(a) and Input.is_action_pressed(a)
		return
	_skip(why)


## What runs on its own time while the shot holds for the question: the dust ring's particles pause with
## it, and a cheering astronaut (physics off) gets physics back so EventBus's stuck-player watchdog never
## hands control over mid-shot; the cheer pose is put back on resume.
func _hold_effects(on: bool) -> void:
	if _dust != null and is_instance_valid(_dust):
		_dust.speed_scale = 0.0 if on else 1.0
	if _player == null or not is_instance_valid(_player):
		return
	if on:
		_cheer_held = not _player.is_physics_processing()
		if _cheer_held:
			_player.velocity = Vector3.ZERO
			_player.set_physics_process(true)
	elif _cheer_held:
		_cheer_held = false
		if _t >= ASTRO_CHEER_T and _t < ASTRO_CHEER_T + ASTRO_CHEER_S:
			_player.set_physics_process(false)
			var model := _player.get_model()
			if model != null:
				model.set_state("happy")


func _skip(why: String) -> void:
	if _phase != Phase.RUNNING:
		return
	_phase = Phase.SKIPPING
	_skipped = true
	_beat("skip (%s) at t=%.2f" % [why, _t])
	await SceneRouter.fade_out(SKIP_FADE_OUT)
	if not is_inside_tree() or _phase != Phase.SKIPPING:
		return
	_complete(true)
	SceneRouter.fade_in(SKIP_FADE_IN)


func _complete(skipped: bool) -> void:
	if _phase == Phase.RELEASING or _phase == Phase.DONE:
		return
	_skipped = skipped
	if skipped and _shower != null:
		_shower.call("clear")
	apply_end_state()
	_hand_camera_on()
	_phase = Phase.RELEASING
	_release_t = 0.0
	_beat("complete worst_step_ms=%.2f skipped=%s max_speed=%.2f max_turn=%.1f limited_frames=%d worst_ms=%.0f stalls=%s peak_on_screen=%d launched=%d" % [
		_worst_step_ms, str(skipped), _max_speed, _max_turn, _limited_frames, _worst_ms, str(_stalls), _peak_on_screen,
		int(_shower.call("launched_count")) if _shower != null else 0])
	_flush_trace()
	if not _held_down():
		_release()


func _release() -> void:
	_thaw_player()
	_end_modal()
	_phase = Phase.DONE
	_beat("finished skipped=%s release_wait=%.2f" % [str(_skipped), _release_t])
	_flush_trace()
	finished.emit(_skipped)


func _thaw_player() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	_player.velocity = Vector3.ZERO
	_player.set_physics_process(true)
	_player.input_enabled = not EventBus.is_modal_open()


func _end_modal() -> void:
	if _modal:
		_modal = false
		EventBus.ui_modal_closed.emit(MODAL_NAME)


func _held_down() -> bool:
	if not _touches.is_empty():
		return true
	for a: String in HOLD_ACTIONS:
		if InputMap.has_action(a) and Input.is_action_pressed(a):
			return true
	return Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)


func _hold_clock() -> void:
	if _env == null or _held_clock:
		return
	_saved_time_scale = float(_env.get("time_scale"))
	_env.set("time_scale", 0.0)
	_held_clock = true


func _restore_clock() -> void:
	if not _held_clock:
		return
	if _env != null and is_instance_valid(_env):
		_env.set("time_scale", _saved_time_scale)
	_held_clock = false


func _exit_tree() -> void:
	# Leaving mid-shot (a quit to the title, a scene change): never leave the menus locked, the astronaut
	# frozen, the clock stopped or the engine loop playing.
	if _phase == Phase.RUNNING or _phase == Phase.SKIPPING or _phase == Phase.RELEASING:
		if _rocket != null and is_instance_valid(_rocket):
			_rocket.set_engine(false)
			_rocket.global_transform = _rest
		AudioManager.stop_loop("rocket_loop", 0.1)
		_restore_clock()
		_thaw_player()
		_end_modal()
		_phase = Phase.DONE
	_flush_trace()


# ============================================================================= skip hint
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
	if _phase == Phase.RUNNING and not _confirming and _t >= SKIP_HINT_T and _t < END_T - 1.0:
		want = SKIP_HINT_ALPHA
	_hint_alpha = move_toward(_hint_alpha, want, delta / 0.4)
	if _phase != Phase.RUNNING:
		_hint_alpha = 0.0
	_hint_pill.modulate.a = _hint_alpha
	_hint_pill.visible = _hint_alpha > 0.005
	if _hint_pill.visible:
		var vp := _hint_root.size
		var safe := MobileUI.safe_area() if MobileUI.is_mobile() else Vector4.ZERO
		_hint_pill.reset_size()
		_hint_pill.position = Vector2(vp.x - _hint_pill.size.x - 24.0 - safe.z, vp.y - _hint_pill.size.y - 22.0 - safe.w)


# ============================================================================= helpers
func _once(key: String) -> bool:
	if _fired.has(key):
		return false
	_fired[key] = true
	_fired_now.append(key)
	return true


## Smoothed trapezoid: 0 -> 1 over x in 0..1, accelerating over the first `a` and braking over the last
## `d` share with smoothstep-shaped velocity ramps (continuous velocity and acceleration at both ends).
static func _trap(x: float, a: float, d: float) -> float:
	if x <= 0.0:
		return 0.0
	if x >= 1.0:
		return 1.0
	var vp := 1.0 / (1.0 - a * 0.5 - d * 0.5)
	var s := 0.0
	if x < a:
		var u := x / a
		s = vp * a * (u * u * u - u * u * u * u * 0.5)
	elif x <= 1.0 - d:
		s = vp * (a * 0.5 + (x - a))
	else:
		var u2 := (1.0 - x) / d
		s = 1.0 - vp * d * (u2 * u2 * u2 - u2 * u2 * u2 * u2 * 0.5)
	return clampf(s, 0.0, 1.0)


static func _smootherstep(x: float) -> float:
	return x * x * x * (x * (x * 6.0 - 15.0) + 10.0)


## Signed turn from yaw `a` to yaw `b` (deg) that goes round through the side AWAY from the pad bearing
## (yaw 0 points at the pad).
static func _turn_away_from_pad(a: float, b: float) -> float:
	var pos := fposmod(b - a, 360.0)
	var neg := pos - 360.0
	# Does sweeping through `pos` cross yaw 0 (the pad)? Then take the other way.
	var start := fposmod(a, 360.0)
	return neg if start + pos >= 360.0 else pos


static func _lerp_angle(a: float, b: float, k: float) -> float:
	var d := fposmod(b - a + 180.0, 360.0) - 180.0
	return a + d * k


static func _tangent(v: Vector3, up: Vector3, fallback: Vector3) -> Vector3:
	var t := v - up * v.dot(up)
	if t.length_squared() < 1e-6:
		t = fallback - up * fallback.dot(up)
	return t.normalized()


static func _face_basis(face: Vector3, up: Vector3) -> Basis:
	return Basis.looking_at(face, up)


func _beat(text: String) -> void:
	_log(text)
	if not _trace_on:
		return
	_trace_buf.append("%s %s" % [TRACE_TAG, text])
	_flush_trace()


func _log(msg: String) -> void:
	print("LAUNCH [%5.2f] %s" % [_t, msg])


# ============================================================================= measurement
func _trace_row(t: float, pitch: float, rule_xf: Transform3D) -> void:
	var xf := _cam.global_transform
	var q := xf.basis.get_rotation_quaternion()
	var vp := get_viewport().get_visible_rect().size
	var on := 0
	var heroes := 0
	if _shower != null:
		on = int(_shower.call("on_screen_count", _cam, vp))
		heroes = int(_shower.call("heroes_on_screen", _cam, vp))
	_peak_on_screen = maxi(_peak_on_screen, on)
	var rq := rule_xf.basis.get_rotation_quaternion()
	_trace_buf.append("%s cam %d %.4f %.4f %.4f %.4f %.8f %.8f %.8f %.8f %.3f %.2f %.4f %.4f %d %d %d %d %.4f %.4f %.4f %.8f %.8f %.8f %.8f" % [
		TRACE_TAG, _trace_frame, t, xf.origin.x, xf.origin.y, xf.origin.z, q.x, q.y, q.z, q.w, _cam.fov, pitch,
		_rocket_frac(vp), _rock_frac(vp), on, heroes, 1 if _pad_in_view() else 0, _limited_frames,
		rule_xf.origin.x, rule_xf.origin.y, rule_xf.origin.z, rq.x, rq.y, rq.z, rq.w])
	_trace_frame += 1
	if _trace_buf.size() >= 60:
		_flush_trace()


func _flush_trace() -> void:
	if _trace_buf.is_empty():
		return
	if not ResourceLoader.exists(FINALE_STATE_PATH):
		_trace_buf.clear()
		return
	var fs: Script = load(FINALE_STATE_PATH)
	if fs == null or not fs.has_script_method("trace"):
		# K's trace helper is not in this build: write the same file ourselves, appending.
		var path := ""
		for a: String in OS.get_cmdline_user_args():
			if a.begins_with("--finale-trace="):
				path = a.substr(15)
		if path != "":
			var f := FileAccess.open(path, FileAccess.READ_WRITE) if FileAccess.file_exists(path) else FileAccess.open(path, FileAccess.WRITE)
			if f != null:
				f.seek_end()
				for line in _trace_buf:
					f.store_line(line)
				f.close()
		_trace_buf.clear()
		return
	# One append for the batch: the tag is the first word of the joined text's first line.
	var joined := "\n".join(_trace_buf)
	fs.call("trace", joined.get_slice(" ", 0), joined.substr(joined.find(" ") + 1))
	_trace_buf.clear()


## The rocket's screen height as a share of the frame (the three-disc hull silhouette, as CrashIntro's
## trace measures it). -1 when it is not drawn or not in front of the camera.
func _rocket_frac(vp: Vector2) -> float:
	if _rocket == null or not _rocket.visible or _cam == null:
		return -1.0
	var xf := _rocket.global_transform
	var a1 := xf.origin + xf.basis.y.normalized() * RocketModel.TOTAL_HEIGHT
	if _cam.is_position_behind(xf.origin) or _cam.is_position_behind(a1):
		return -1.0
	var r := Rect2()
	var discs := [[0.15, 0.95], [0.5, RocketModel.HULL_R], [0.93, 0.22]]
	for i in discs.size():
		var p: Vector3 = xf.origin.lerp(a1, float(discs[i][0]))
		var s := _cam.unproject_position(p)
		var rr := s.distance_to(_cam.unproject_position(p + _cam.global_basis.x * float(discs[i][1])))
		var disc := Rect2(s - Vector2(rr, rr), Vector2(rr, rr) * 2.0)
		r = disc if i == 0 else r.merge(disc)
	return r.size.y / vp.y


## The rock's screen height as a share of the frame, from its real posed vertices (L1's debug_pose).
func _rock_frac(vp: Vector2) -> float:
	if _asteroid == null or not is_instance_valid(_asteroid) or not _asteroid.visible or _cam == null:
		return -1.0
	if not _asteroid.has_method("debug_pose"):
		return -1.0
	var rock := _asteroid.get_node_or_null("Spin/Rock") as Node3D
	if rock == null:
		return -1.0
	var pose: PackedVector3Array = (_asteroid.call("debug_pose") as Dictionary)["pos"]
	var rxf := rock.global_transform
	var lo := INF
	var hi := -INF
	var i := 0
	while i < pose.size():
		var p := rxf * pose[i]
		if not _cam.is_position_behind(p):
			var s := _cam.unproject_position(p)
			lo = minf(lo, s.y)
			hi = maxf(hi, s.y)
		i += 6
	if hi < lo:
		return -1.0
	return (minf(hi, vp.y) - maxf(lo, 0.0)) / vp.y


func _pad_in_view() -> bool:
	if _cam == null or _pad == null:
		return false
	var p := _rest.origin + _pad_up * 0.5
	if _cam.is_position_behind(p):
		return false
	var s := _cam.unproject_position(p)
	var vp := get_viewport().get_visible_rect().size
	return s.x >= -40.0 and s.x <= vp.x + 40.0 and s.y >= -40.0 and s.y <= vp.y + 40.0


# ============================================================================= test hooks
## TEST HOOK: samples the authored camera (seed blend included, limiter not) over the whole shot at
## 60 Hz without playing it, and prints the per-half-second maxima the critic's trace checks measure.
func debug_plan() -> void:
	if _cam == null:
		return
	var vp := get_viewport().get_visible_rect().size
	var prev_xf := Transform3D.IDENTITY
	var have := false
	var bucket := -1
	var mx_s := 0.0
	var mx_t := 0.0
	var line := ""
	var t := 0.0
	while t <= END_T + 0.001:
		var r := _rule(t)
		var eye: Vector3 = r[0]
		var basis: Basis = r[1]
		var fov: float = r[2]
		if _has_seed and t < _seed_s:
			var k := 1.0 - _smootherstep(clampf(t / _seed_s, 0.0, 1.0))
			eye = eye.lerp(_seed_xf.origin, k)
			basis = Basis(basis.get_rotation_quaternion().slerp(_seed_xf.basis.get_rotation_quaternion(), k))
			fov = lerpf(fov, _seed_fov, k)
		var xf := Transform3D(basis, eye)
		if have:
			mx_s = maxf(mx_s, xf.origin.distance_to(prev_xf.origin) * 60.0)
			mx_t = maxf(mx_t, rad_to_deg(prev_xf.basis.get_rotation_quaternion().angle_to(basis.get_rotation_quaternion())) * 60.0)
		prev_xf = xf
		have = true
		var b := int(floor(t * 2.0 + 0.0001))
		if b != bucket:
			if bucket >= 0:
				print(line % [mx_s, mx_t])
			bucket = b
			mx_s = 0.0
			mx_t = 0.0
			_cam.global_transform = xf
			_cam.fov = fov
			var rxf := _rocket_xf(t)
			var saved_vis := _rocket.visible
			_rocket.global_transform = rxf
			_rocket.visible = t < HIT_T
			var rs := _cam.unproject_position(rxf.origin + rxf.basis.y * 1.6) / vp
			var ks := _cam.unproject_position(_rock_c) / vp
			var hy := Vector2(INF, -INF)
			var hx := Vector2(INF, -INF)
			for hp in _head_points():
				if not _cam.is_position_behind(hp):
					var hs := _cam.unproject_position(hp) / vp
					hy = Vector2(minf(hy.x, hs.y), maxf(hy.y, hs.y))
					hx = Vector2(minf(hx.x, hs.x), maxf(hx.y, hs.x))
			var asp := _cam.unproject_position(_astro_p + _astro_up * 1.0) / vp
			line = "PLAN t=%5.2f spd=%%.2f turn=%%5.1f pitch=%5.1f fov=%4.1f rocket=%.3f at(%.2f,%.2f) d=%.0f rock=%.3f at(%.2f,%.2f) pad=%d heads x%.2f-%.2f y%.2f-%.2f astro(%.2f,%.2f)" % [
				t, float(r[3]), fov, _rocket_frac(vp), rs.x, rs.y, _cam.global_position.distance_to(rxf.origin), _rock_frac(vp), ks.x, ks.y, 1 if _pad_in_view() else 0,
				hx.x, hx.y, hy.x, hy.y, asp.x, asp.y]
			_rocket.visible = saved_vis
		t += 1.0 / 60.0
	print(line % [mx_s, mx_t])
	_rocket.global_transform = _rest


## TEST HOOK: plays the shot with no shower at all (to tell its cost and stalls from the world's).
func debug_disable_shower() -> void:
	_debug_no_shower = true


## TEST HOOK: holds the shot clock at `t` (for timing a fixed frame). Negative releases it.
func debug_hold(t: float) -> void:
	_hold_at = t


## TEST HOOKS: a real InputEvent press and its release a frame later, through Input.parse_input_event
## (the path a keyboard, mouse or finger takes into `_input`). Still SYNTHESISED: no hardware.
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


## One line for a timeline to assert on: phase, shot time, the end-state facts the critic checks.
func debug_report(tag: String = "") -> void:
	var cam := get_viewport().get_camera_3d()
	print("LAUNCH REPORT %s phase=%s t=%.2f skipped=%s modal=%d names=%s rocket_visible=%s engine_flame=%.2f rock_visible=%s time_scale=%s music=%s cam=%s shower_pending=%d player_input=%s phys=%s" % [
		tag, Phase.keys()[_phase], _t, str(_skipped), EventBus.modal_total(), str(EventBus.modal_counts()),
		str(_rocket.visible) if _rocket != null and is_instance_valid(_rocket) else "-",
		_rocket.flame_scale() if _rocket != null and is_instance_valid(_rocket) else -1.0,
		str(_asteroid.visible) if _asteroid != null and is_instance_valid(_asteroid) else "-",
		str(_env.get("time_scale")) if _env != null and is_instance_valid(_env) else "-",
		AudioManager.current_track(), cam.name if cam != null else "-",
		int(_shower.call("pending_count")) if _shower != null and is_instance_valid(_shower) else -1,
		str(_player.input_enabled) if _player != null and is_instance_valid(_player) else "-",
		str(_player.is_physics_processing()) if _player != null and is_instance_valid(_player) else "-"])
