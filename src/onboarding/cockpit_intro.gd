class_name CockpitIntro
extends Node
## THE COCKPIT - the opening of a new campaign game, before the crash (docs/INTRO_SPEC.md 1-5).
## Spawned once by IntroDirector on the scene's first frame, AFTER a CrashIntro made with
## `wait_for_go` (B2's intro_director.gd `_start_crash`), exactly like CrashIntro:
##     var c := CockpitIntro.new(); c.name = "CockpitIntro"; c.finished.connect(cb); add_child(c)
## No properties are set; it starts itself. A missing world piece emits finished(false) and frees.
##
## WHAT IT OWNS, AND WHAT IT DOES NOT. The waiting CrashIntro has already frozen and hidden the
## astronaut at the landing spot, snapped the gameplay rig behind them and holds the "cutscene" modal
## (which hides the HUD and the touch controls). So this node never touches the player, the rig's
## placement, the modal, the HUD or the touch controls. It owns: its own nodes (the room, its camera,
## the meteor, the captions, the overlay), which camera is current while it plays, the sky's space
## blend while it plays, and the "rocket_loop" hum.
##
## THE BEATS (INTRO_SPEC 3, beats 1-5), on the clock `_t` (0 = the picture starts):
##   -1.9 s   navy card (RadioCaption's), the radio hums. The gameplay rig is still the current
##            camera under it - see "THE SKY LOCK" below.
##    0       the card lifts on the cockpit: first person, seated, the little system ahead.
##    LOOK    drag to look (finger or mouse; arrows / WASD / stick too). Rest the centre dot on one
##            of four things for DWELL seconds and its line types at the BOTTOM. The Professor's
##            radio lines type at the TOP and wait while an item line is up; the two never type at
##            the same time. A thing counts as seen when its line has finished.
##            Never stuck: NUDGE_IDLE s with no look input -> "Still there, pilot?"; at FORCE_T the
##            meteor comes anyway.
##    METEOR  all four seen + the radio line in progress finished + METEOR_BEAT s: the meteor slides
##            in over the top of the window, alarm, "Pilot! Look up! LOOK UP!", the view is taken and
##            turned to it, the ship banks away and grazes it (shake, sparks, alarm light), then a
##            WHITE flash. At the flash's full opacity: the cut (`_cut`), finished(false).
##
## THE HAND-OFF (the interface B2's IntroDirector codes against). At the instant the white is fully
## opaque (`_cut`): the rig's camera is made current (a safe default should the crash shot have bowed
## out), the sky's space blend goes back to 0, the cockpit's nodes are queued for freeing, and then
## finished(false) is emitted - IntroDirector calls CrashIntro.go(), whose first step takes the current
## camera on this same frame. After the emit this node never touches camera currency again; it only
## fades its white out over WHITE_OUT s (FLASH_LAYER 99, over the crash's "Tap to skip" on 95) and
## frees itself.
##
## SKIP. The overlay's own "Skip" button (bottom right, where the crash's hint pill sits), any key
## that is not a look key or a modifier, a pad button, or one of CrashIntro's SKIP_ACTIONS (for
## Director timelines) opens SkipConfirm ("Skip the intro?"). The clock is frozen while it is open.
## On "Skip": SceneRouter.fade_out(0.25), the same teardown as the cut, finished(true), free. No
## fade_in here: CrashIntro.finish_skipped() does that. A tap or a drag on the picture NEVER skips -
## in here touching the screen is how you look (round 2: a tap on the plant asked to skip the intro).
##
## THE SKY LOCK (INTRO_SPEC 5; environment.gd BODY_AZ_LOCK_SEC). The environment freezes where the
## neighbouring worlds hang from the camera it sees in the scene's first 1.5 s. The waiting CrashIntro
## has put the rig at the hand-off framing on frame 1, so, as the crash's old navy card did, the rig
## stays current under a navy card until the environment's own lock timer has passed BODY_AZ_LOCK_SEC
## (read from the node, `_env_locked`), and only then does the cockpit camera take over. Nothing here
## calls reset_bearing_lock().
##
## WHERE THE COCKPIT IS. In the live World, VIEW_DIST m out from home on the crash's own cruise
## bearing (CRUISE_ELEV_DEG above the landing spot's horizon, behind the hand-off camera), facing
## home. So the window shows the real home planet and the neighbouring worlds where the crash shot
## shows them (SkyBodies hang them BODY_DISTANCE from whatever camera is current). Measured, not
## reasoned: see the builder report for the sky-lock A/B.

signal finished(skipped: bool)

# ------------------------------------------------------------------------------------ timeline
const CARD_SECONDS := 1.9
const CAM_SWITCH_LEAD := 0.2
const REVEAL_SECONDS := 0.9
## environment.gd BODY_AZ_LOCK_SEC. Read from the node when it has it; this is the fallback only.
const ENV_LOCK_SEC := 1.5
## Skip armed after SceneRouter's own 0.6 s fade-in (CrashIntro SKIP_ARM_T).
const SKIP_ARM_T := -0.9
const SKIP_HINT_T := -0.8
const MAX_STEP := 0.05

## Look clamps (INTRO_SPEC 4: about 75 and 35 degrees each way).
const YAW_LIMIT := 75.0
const PITCH_LIMIT := 35.0
## Degrees of turn per canvas row of drag: a drag the full height of the screen turns 80 degrees.
const DRAG_DEG_PER_SCREEN := 80.0
const KEY_DEG_PER_SEC := 75.0
const LOOK_SMOOTH := 14.0
## Seconds the dot must rest on a thing for its line to show.
const DWELL := 0.5

const NUDGE_IDLE := 30.0
## No nudge when the forced meteor is closer than this: it would be cut off mid-line (round 2 played
## run: nudge at 74.49, meteor at 75.59).
const NUDGE_MIN_LEFT := 8.0
const FORCE_T := 75.0
const METEOR_BEAT := 2.0
## Hold after a line has finished typing: base + per character.
const ITEM_HOLD := Vector2(1.3, 0.025)
const RADIO_HOLD := Vector2(1.1, 0.02)
const RADIO_GAP := 0.5

## The meteor beat, in seconds from its start (tau).
const ALARM_LINE_T := 2.4
const LOOK_TAKE := Vector2(2.6, 3.8)
const SWERVE := Vector2(4.2, 6.6)
const CONTACT_T := 6.6
const FLASH := Vector2(6.9, 7.2)
const WHITE_OUT := 0.4
const SWERVE_YAW_DEG := 20.0
const SWERVE_ROLL_DEG := 24.0
const SWERVE_SIDE_M := 3.0
const BEEP_EVERY := 0.62
## [tau, Vector3(yaw deg (+ left), pitch deg, distance m)] of the meteor's centre from the eye, in the
## cockpit as it is at that tau (see `_solve_meteor_keys`). The window spans about yaw +-35, pitch
## -10..+30; the radio caption covers pitch above ~14 at the screen's middle on a phone (--ui=mobile
## fonts and safe area, measured round 3), so the rock's top edge enters below ~13. The rock is CockpitProps.meteor_radius() (41 m; ~45 m at its lumps), so: it slides in at the
## window's LEFT edge already three times home's size (18 deg radius against home's ~6), crosses in
## front of home and eclipses it at 4.2 s (100 m, inside home's 150 m), fills half the window by 5.8 s,
## and at the graze its curved limb sweeps across the window from the right. It never starts further
## than ~135 m: SkyBodies hangs the neighbour worlds 140 m from the camera, and a rock behind them had
## them drawn ON it (round 3 frames at 230 m). 52 m at the graze clears the cabin's front corner
## (1.5 m from the eye) by ~5.5 m even at its lumpiest.
const METEOR_KEYS := [
	[0.0, Vector3(40.0, -5.0, 135.0)],
	[2.6, Vector3(22.0, -6.0, 116.0)],
	[4.2, Vector3(2.0, -2.0, 100.0)],
	[5.8, Vector3(-22.0, 4.0, 72.0)],
	[6.6, Vector3(-56.0, 8.0, 52.0)],
]
## How far the taken view turns toward the meteor (yaw, pitch fractions of its bearing).
const VIEW_FOLLOW := Vector2(0.45, 0.7)

## Where the cockpit hangs (see the header): home's centre VIEW_DIST m ahead, on the crash's cruise
## bearing. CrashIntro CRUISE_ELEV_DEG; its camera is 200 m out at the bonk, but a closer home reads
## as "the little system ahead" through a window instead of a speck.
const VIEW_DIST := 150.0
const CRUISE_ELEV_DEG := 27.0
const FOV := 62.0

const SKIP_ACTIONS: PackedStringArray = ["interact", "ui_accept", "jump", "cancel", "pause"]
const LOOK_ACTIONS: PackedStringArray = ["camera_left", "camera_right", "camera_up", "camera_down",
	"move_left", "move_right", "move_forward", "move_back", "zoom_in", "zoom_out"]

## INTRO_SPEC 4. Every box <= 60 characters (tests/director/cockpit_lines.gd checks).
const ITEM_LINES := {
	"photos": ["Your photo wall. It has room for more."],
	"camera": ["Your camera. Brass, dented and all yours."],
	"letter": ["Almost day one of the new job at the Intergalactic Station!",
		"If only it wasn't just photographing mineral samples..."],
	"plant": ["A tiny plant. You make every place homey."],
}
const RADIO_HELLO := "Survey ship, this is Professor Comet. Loud and clear!"
const RADIO_NEIGHBOURS := "You're passing through our little neighbourhood."
const RADIO_QUIET := "Quiet day. Just how I like the sky."
const RADIO_NUDGE := "Still there, pilot? Take a good look around."
const RADIO_LATE := "That rock is far bigger than my scope said!"
const RADIO_ALARM := "Pilot! Look up! LOOK UP!"
## [due t, text]. Chatter between the looking; each waits for any item line to finish.
const RADIO_SCHEDULE := [[0.3, RADIO_HELLO], [8.0, RADIO_NEIGHBOURS], [18.0, RADIO_QUIET]]

enum Phase { CARD, LOOK, METEOR, DONE }

var _planet: Node3D
var _rig: CameraRig
var _env: Node
var _player: Player
var _cam: Camera3D
var _root: Node3D
var _head: Node3D
var _captions: RadioCaption
var _overlay: CockpitOverlay
var _props: Dictionary = {}
var _meteor: Node3D
var _sparks: GPUParticles3D
var _targets: Dictionary = {}

var _phase := Phase.CARD
var _t := -CARD_SECONDS
var _look_t := 0.0
var _tau := 0.0
var _running := false
var _done := false
## environment.gd `time_scale` as it was before the cockpit stopped the clock (-1 = not stopped).
var _time_scale := -1.0
var _skipping := false
var _confirming := false
var _fired: Dictionary = {}

# look
var _yaw := 0.0
var _pitch := 0.0
var _yaw_target := 0.0
var _pitch_target := 0.0
var _pending_look := Vector2.ZERO
var _idle := 0.0
var _player_yaw := 0.0
var _player_pitch := 0.0
# pointers: id -> {"pos", "start", "moved", "ms"}; id -1 is the real mouse
var _pointers: Dictionary = {}
var _skip_held: Dictionary = {}
var _skip_primed := false

# targets and lines
var _seen: Dictionary = {}
var _triggered: Dictionary = {}
var _dwell_id := ""
var _dwell_t := 0.0
var _pending_item := ""
var _item_id := ""
var _item_box := 0
var _item_hold := 0.0
var _radio_queue: Array = []
var _radio_on := false
var _radio_hold := 0.0
var _radio_gap := 0.0
var _nudged := false
var _meteor_wait := -1.0
var _meteor_forced := false

# geometry, fixed when the cockpit is placed
var _home := Vector3.ZERO
var _f0 := Transform3D.IDENTITY
var _beep_next := 0.0
var _meteor_keys: Array = []
var _warm_frames := 0
var _meteor_bearing := Vector2.ZERO
var _shake := 0.0
var _white := 0.0


func _ready() -> void:
	# Before the environment (0) and the rig (10), like CrashIntro: the sky reads the current camera's
	# position in its own _process, and the neighbouring worlds would lag a frame behind the head.
	process_priority = -5
	set_process(false)
	set_physics_process(false)
	call_deferred("_begin")


func _begin() -> void:
	var world := get_node_or_null("/root/World")
	if world != null:
		_planet = world.get_node_or_null("Planet") as Node3D
		_rig = world.get_node_or_null("CameraRig") as CameraRig
		_env = world.get_node_or_null("Environment")
	_player = get_tree().get_first_node_in_group("player") as Player
	if _planet == null or _player == null or _rig == null or _rig.get_camera() == null or _env == null:
		push_warning("CockpitIntro: world is missing a piece (planet/player/rig/environment); skipping the cockpit.")
		_done = true
		finished.emit(false)
		queue_free()
		return
	# The world clock stops for the cockpit (lead, 2026-10-18): the opening hands back at the hour the
	# old crash-only opening did (~10:00), not 75 s of game time (1.2 h) later. Put back in `_teardown`.
	var ts: Variant = _env.get("time_scale")
	if ts != null:
		_time_scale = float(ts)
		_env.set("time_scale", 0.0)
	_build()
	AudioManager.play_music("space", 0.8)
	_radio_queue = RADIO_SCHEDULE.duplicate(true)
	_log("begin modal_open=%s" % str(EventBus.is_modal_open()))
	_running = true
	set_process(true)
	set_physics_process(true)
	_step(0.0)


# ============================================================================= building
func _build() -> void:
	_root = Node3D.new()
	_root.name = "Cockpit"
	add_child(_root)
	_props = CockpitProps.build(_root)
	_targets = CockpitProps.targets()
	_head = Node3D.new()
	_head.name = "Head"
	_root.add_child(_head)
	_cam = Camera3D.new()
	_cam.name = "CockpitCamera"
	_cam.fov = FOV
	_cam.near = 0.04
	_cam.far = 3000.0
	# Own attributes with depth of field off (CrashIntro / rocket_pad.gd's flight camera): the
	# environment's would defocus home 150 m away and blur the dash 0.7 m away.
	var attr := CameraAttributesPractical.new()
	attr.auto_exposure_enabled = false
	attr.dof_blur_far_enabled = false
	attr.dof_blur_near_enabled = false
	_cam.attributes = attr
	_head.add_child(_cam)
	_root.visible = false

	_meteor = CockpitProps.meteor()
	add_child(_meteor)
	_meteor.visible = false
	_sparks = CockpitProps.spark_streaks()
	_root.add_child(_sparks)
	_sparks.position = _props["spark_at"]

	_captions = RadioCaption.new()
	_captions.name = "CockpitRadio"
	add_child(_captions)
	var who := str(NpcData.get_data("mayor_orbit").get("display_name", "Professor Comet"))
	var accent := Color(str(NpcData.get_data("mayor_orbit").get("accent", "#c9a15c")))
	_captions.setup("%s (radio)" % who, accent)
	_captions.set_card_alpha(1.0)
	_overlay = CockpitOverlay.new()
	_overlay.name = "CockpitOverlay"
	add_child(_overlay)
	_overlay.skip_pressed.connect(_on_skip_button)


## Puts the cockpit on the crash's cruise bearing, facing home (header "WHERE THE COCKPIT IS"). Read
## at the camera switch, after the rig has settled behind the astronaut (which the waiting CrashIntro placed).
func _place() -> void:
	_home = _planet.global_position
	var up := (_player.global_position - _home).normalized()
	var rc := _rig.get_camera()
	var fwd := -rc.global_basis.z
	var b := fwd - up * fwd.dot(up)
	if b.length_squared() < 1e-6:
		b = up.cross(Vector3.RIGHT)
	b = b.normalized()
	var el := deg_to_rad(CRUISE_ELEV_DEG)
	var eye := _home + (-b * cos(el) + up * sin(el)) * VIEW_DIST
	var z := (eye - _home).normalized()
	var x := up.cross(z).normalized()
	var y := z.cross(x).normalized()
	_f0 = Transform3D(Basis(x, y, z), eye)
	_root.global_transform = _f0


# ============================================================================= per frame
func _process(delta: float) -> void:
	if _done:
		return
	if not _running or _skipping or _confirming:
		return
	_step(minf(delta, MAX_STEP))


func _step(dt: float) -> void:
	_t += dt
	var t := _t
	if _phase == Phase.CARD:
		if t >= -CAM_SWITCH_LEAD and _env_locked() and not _cam.current:
			_place()
			_root.visible = true
			_cam.current = true
			_env.call("set_space_blend", 1.0)
			AudioManager.start_loop("rocket_loop", -22.0, 0.8)
			_warm_up(true)
			_log("reveal: cockpit camera current at t=%.2f" % t)
		if _cam.current and t >= 0.0:
			_phase = Phase.LOOK
	if _cam.current:
		_env.call("set_space_blend", 1.0)
	if _warm_frames > 0:
		_warm_frames -= 1
		if _warm_frames == 0:
			_warm_up(false)
	match _phase:
		Phase.LOOK:
			_look_t += dt
			_update_look(dt)
			_update_targets(dt)
			_update_item(dt)
			_update_radio(dt)
			_update_meteor_trigger(dt)
		Phase.METEOR:
			_tau += dt
			_update_meteor(dt)
	_apply_view(dt)
	_update_pulses()
	if _captions != null:
		var reveal := 1.0 - smoothstep(0.0, REVEAL_SECONDS, t) if _cam.current else 1.0
		_captions.set_card_alpha(reveal)
		# RadioCaption's "Tap to skip" pill is wrong here (a tap is a look); the overlay's button replaces it.
		_captions.show_skip_hint(false)
	if _overlay != null:
		_overlay.set_skip_button(t >= SKIP_HINT_T and _phase != Phase.DONE and not _confirming and not _skipping)
	if _overlay != null:
		var dot_on := _phase == Phase.LOOK and t >= REVEAL_SECONDS * 0.5
		var prog := clampf(_dwell_t / DWELL, 0.0, 1.0) if _dwell_id != "" else 0.0
		if _pending_item != "" and _pending_item == _dwell_id:
			prog = 1.0
		_overlay.set_dot(dot_on, prog, _dwell_id != "")


func _env_locked() -> bool:
	var lock: Variant = _env.get("_body_az_lock")
	var need: Variant = _env.get("BODY_AZ_LOCK_SEC")
	if lock == null:
		return true
	return float(lock) >= (float(need) if need != null else ENV_LOCK_SEC)


# ----------------------------------------------------------------------------- look
func _update_look(dt: float) -> void:
	var axis := Vector2(
		Input.get_axis("camera_left", "camera_right") + Input.get_axis("move_left", "move_right"),
		Input.get_axis("camera_down", "camera_up") + Input.get_axis("move_back", "move_forward"))
	axis = axis.limit_length(1.0)
	var deg := _pending_look + Vector2(-axis.x, axis.y) * KEY_DEG_PER_SEC * dt
	_pending_look = Vector2.ZERO
	if deg.length() > 0.05:
		_idle = 0.0
	else:
		_idle += dt
	_player_yaw = clampf(_player_yaw + deg.x, -YAW_LIMIT, YAW_LIMIT)
	_player_pitch = clampf(_player_pitch + deg.y, -PITCH_LIMIT, PITCH_LIMIT)
	_yaw_target = _player_yaw
	_pitch_target = _player_pitch


func _apply_view(dt: float) -> void:
	if _head == null:
		return
	var k := 1.0 - exp(-LOOK_SMOOTH * dt) if dt > 0.0 else 1.0
	_yaw = lerpf(_yaw, _yaw_target, k)
	_pitch = lerpf(_pitch, _pitch_target, k)
	var sx := 0.0
	var sy := 0.0
	var sr := 0.0
	if _shake > 0.0:
		var tt := _tau
		sx = _shake * (sin(tt * 41.0) * 0.6 + sin(tt * 73.3 + 1.7) * 0.4)
		sy = _shake * (sin(tt * 37.5 + 0.9) * 0.6 + sin(tt * 89.1) * 0.4)
		sr = _shake * 0.6 * sin(tt * 29.0 + 0.3)
	_head.basis = Basis(Vector3.UP, deg_to_rad(_yaw + sx)) * Basis(Vector3.RIGHT, deg_to_rad(_pitch + sy)) \
		* Basis(Vector3.BACK, deg_to_rad(sr))
	# The ship's own slow sway while cruising, so the room is never dead still.
	if _phase != Phase.METEOR and _root != null:
		var sway := Basis(Vector3.BACK, deg_to_rad(0.8 * sin(_t * 0.42))) * Basis(Vector3.RIGHT, deg_to_rad(0.35 * sin(_t * 0.31 + 1.0)))
		_root.global_transform = Transform3D(_f0.basis * sway, _f0.origin)


## Yaw/pitch (deg, yaw positive = left) of a point in cockpit-local space, seen from the eye.
static func _bearing(local: Vector3) -> Vector2:
	var flat := sqrt(local.x * local.x + local.z * local.z)
	return Vector2(rad_to_deg(atan2(-local.x, -local.z)), rad_to_deg(atan2(local.y, flat)))


## Angle (deg) between the centre of view and a cockpit-local point.
func _off_centre(local: Vector3) -> float:
	var fwd := _head.basis * Vector3.FORWARD
	return rad_to_deg(fwd.angle_to(local.normalized()))


# ----------------------------------------------------------------------------- targets
func _update_targets(dt: float) -> void:
	var hovered := ""
	var best := INF
	var can_dwell := _meteor_wait < 0.0 and _item_id == "" and _pending_item == ""
	for id: String in _targets:
		if _triggered.has(id):
			continue
		var d: Dictionary = _targets[id]
		var off := _off_centre(d["at"] as Vector3)
		if off <= float(d["r"]) and off < best:
			best = off
			hovered = id
	if not can_dwell:
		if _pending_item == "":
			_dwell_id = ""
			_dwell_t = 0.0
		return
	if hovered != _dwell_id:
		_dwell_id = hovered
		_dwell_t = 0.0
	if _dwell_id == "":
		return
	_dwell_t += dt
	if _dwell_t >= DWELL:
		_triggered[_dwell_id] = true
		_pending_item = _dwell_id
		_idle = 0.0
		_log("look: %s (dwell %.2f s)" % [_dwell_id, _dwell_t])


func _update_item(dt: float) -> void:
	if _item_id == "":
		if _pending_item == "" or _captions.is_typing():
			return
		_item_id = _pending_item
		_pending_item = ""
		_dwell_id = ""
		_dwell_t = 0.0
		_item_box = 0
		_show_item_box()
		return
	if _overlay.is_typing():
		return
	_item_hold -= dt
	if _item_hold > 0.0:
		return
	var boxes: Array = ITEM_LINES[_item_id]
	_item_box += 1
	if _item_box < boxes.size():
		if _captions.is_typing():
			_item_box -= 1
			return
		_show_item_box()
		return
	_overlay.hide_line()
	_seen[_item_id] = true
	_idle = 0.0
	_log("seen: %s (%d of %d)" % [_item_id, _seen.size(), _targets.size()])
	_item_id = ""


func _show_item_box() -> void:
	var text := str((ITEM_LINES[_item_id] as Array)[_item_box])
	_overlay.show_line(text)
	_item_hold = ITEM_HOLD.x + ITEM_HOLD.y * float(text.length())
	_log("item line: \"%s\"" % text)


func _item_busy() -> bool:
	return _item_id != "" or _pending_item != "" or (_overlay != null and _overlay.is_showing())


func _update_radio(dt: float) -> void:
	if _radio_on:
		if _captions.is_typing():
			return
		_radio_hold -= dt
		if _radio_hold <= 0.0:
			_captions.hide_line()
			_radio_on = false
			_radio_gap = RADIO_GAP
		return
	_radio_gap -= dt
	if _radio_gap > 0.0 or _item_busy():
		return
	if not _nudged and _idle >= NUDGE_IDLE and _seen.size() < _targets.size() and FORCE_T - _look_t >= NUDGE_MIN_LEFT:
		_nudged = true
		_say(RADIO_NUDGE)
		return
	if not _radio_queue.is_empty() and _look_t >= float((_radio_queue[0] as Array)[0]):
		var line: Array = _radio_queue.pop_front()
		_say(str(line[1]))


func _say(text: String) -> void:
	_captions.show_line(text)
	_radio_on = true
	_radio_hold = RADIO_HOLD.x + RADIO_HOLD.y * float(text.length())
	_log("radio: \"%s\"" % text)


func _update_meteor_trigger(dt: float) -> void:
	if _meteor_wait < 0.0:
		var all_seen := _seen.size() >= _targets.size()
		if all_seen and not _radio_on and not _item_busy():
			_meteor_wait = METEOR_BEAT
			_radio_queue.clear()
			_log("all four seen: the meteor in %.1f s" % METEOR_BEAT)
		elif _look_t >= FORCE_T and not _item_busy() and not _captions.is_typing():
			_meteor_wait = 0.0
			_meteor_forced = true
			_radio_queue.clear()
			if _radio_on:
				_captions.hide_line()
				_radio_on = false
			_log("idle cap %.0f s: the meteor comes anyway (seen %d of %d)" % [FORCE_T, _seen.size(), _targets.size()])
		return
	_meteor_wait -= dt
	if _meteor_wait <= 0.0:
		_start_meteor()


# ============================================================================= the meteor
## SHADER WARM-UP under the opaque navy card (the camera switch is CAM_SWITCH_LEAD before the card
## lifts). The meteor's rock material, its rim light, the alarm omni and the spark streaks are all
## drawn for the first time when the meteor arrives; measured round 3, that first frame was a 133 ms
## hitch on the desktop (Compatibility). So for WARM_FRAMES they are drawn once, hidden inside the dash
## (in the frustum, behind the dash and the floor), then put back.
const WARM_FRAMES := 3

func _warm_up(on: bool) -> void:
	var alarm: OmniLight3D = _props["alarm"]
	if on:
		_warm_frames = WARM_FRAMES
		_meteor.visible = true
		# FULL size (a shrunk copy is a "tiny part" to YarnLite, which swaps in a smooth material copy
		# and swaps it back later: a different shader, so it warmed the wrong one), 85 m out and 45 deg
		# down: inside the frustum by its bounds, behind the dash and the floor, never seen.
		_meteor.global_transform = Transform3D(Basis(), _root.global_transform * Vector3(0.0, -60.0, -60.0))
		var rim := _meteor.get_node_or_null("RimLight") as Node3D
		if rim != null:
			rim.visible = true
		alarm.visible = true
		alarm.light_energy = 0.001
		_sparks.position = Vector3(0.0, -0.7, -0.95)
		_sparks.restart()
		_sparks.emitting = true
	else:
		_meteor.visible = false
		alarm.visible = false
		alarm.light_energy = 0.0
		_sparks.emitting = false
		_sparks.position = _props["spark_at"]



func _start_meteor() -> void:
	_phase = Phase.METEOR
	_tau = 0.0
	_dwell_id = ""
	_dwell_t = 0.0
	_f0 = _root.global_transform
	_solve_meteor_keys()
	_meteor.visible = true
	_meteor.global_transform = Transform3D(Basis(), _meteor_world(0.0))
	var alarm: OmniLight3D = _props["alarm"]
	alarm.visible = true
	_say(RADIO_LATE)
	_beep_next = 0.0
	_log("meteor: in at look t=%.1f (forced=%s)" % [_look_t, str(_meteor_forced)])


## Where the cockpit is at `tau` of the swerve, without the contact jolt: yaw and roll left, slide left.
func _swerve_xf(tau: float) -> Transform3D:
	var w := smoothstep(SWERVE.x, SWERVE.y, tau)
	var wr := smoothstep(SWERVE.x, SWERVE.y - 0.4, tau)
	var rot := Basis(Vector3.UP, deg_to_rad(SWERVE_YAW_DEG * w)) * Basis(Vector3.BACK, deg_to_rad(SWERVE_ROLL_DEG * wr))
	return Transform3D(_f0.basis * rot, _f0 * Vector3(-SWERVE_SIDE_M * w, 0.0, 0.0))


## THE METEOR'S PATH is set where it is SEEN: METEOR_KEYS give its bearing and distance from the eye in
## the cockpit as the cockpit is at that moment (swerve included), so it is in the window when it has
## to be - just over the top edge, sliding down into it, huge in it, then past the right window edge
## at the graze. Each key is turned into a world point once (`_start_meteor`), and the rock flies a
## smooth Catmull-Rom curve through those world points, so the ship's bank really moves the view
## across a rock that keeps its own course.
func _solve_meteor_keys() -> void:
	_meteor_keys.clear()
	for k: Array in METEOR_KEYS:
		var tau: float = k[0]
		var b: Vector3 = k[1]
		var yaw := deg_to_rad(b.x)
		var pitch := deg_to_rad(b.y)
		var d := Vector3(-sin(yaw) * cos(pitch), sin(pitch), -cos(yaw) * cos(pitch))
		_meteor_keys.append([tau, _swerve_xf(tau) * (d * b.z)])


func _meteor_world(tau: float) -> Vector3:
	var n := _meteor_keys.size()
	var last: Array = _meteor_keys[n - 1]
	if tau >= float(last[0]):
		# After the graze it carries on past: its last velocity with the part that points at the ship
		# taken out, so it slides by instead of through the cabin (round 2 measured it 7.8 m from the
		# eye at the flash, inside its own 11 m radius).
		var prev: Array = _meteor_keys[n - 2]
		var v := ((last[1] as Vector3) - (prev[1] as Vector3)) / (float(last[0]) - float(prev[0]))
		var away := ((last[1] as Vector3) - _swerve_xf(float(last[0])).origin).normalized()
		v -= away * minf(v.dot(away), 0.0)
		return (last[1] as Vector3) + v * (tau - float(last[0]))
	var i := 0
	while i < n - 2 and tau >= float((_meteor_keys[i + 1] as Array)[0]):
		i += 1
	var t0 := float((_meteor_keys[i] as Array)[0])
	var t1 := float((_meteor_keys[i + 1] as Array)[0])
	var u := clampf((tau - t0) / (t1 - t0), 0.0, 1.0)
	var p1: Vector3 = (_meteor_keys[i] as Array)[1]
	var p2: Vector3 = (_meteor_keys[i + 1] as Array)[1]
	var p0: Vector3 = (_meteor_keys[i - 1] as Array)[1] if i > 0 else p1 * 2.0 - p2
	var p3: Vector3 = (_meteor_keys[i + 2] as Array)[1] if i + 2 < n else p2 * 2.0 - p1
	var u2 := u * u
	var u3 := u2 * u
	return 0.5 * ((2.0 * p1) + (-p0 + p2) * u + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * u2
		+ (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * u3)


func _update_meteor(dt: float) -> void:
	var tau := _tau
	# The ship banks away (`_swerve_xf`), with a jolt of roll at the contact.
	var xf := _swerve_xf(tau)
	if tau >= CONTACT_T:
		var jolt := 4.0 * exp(-(tau - CONTACT_T) / 0.25) * sin((tau - CONTACT_T) * 30.0)
		xf.basis = xf.basis * Basis(Vector3.BACK, deg_to_rad(jolt))
	_root.global_transform = xf
	_meteor.global_transform = Transform3D(Basis(Vector3(0.3, 1.0, 0.2).normalized(), deg_to_rad(6.0) * tau),
		_meteor_world(tau))
	var rim := _meteor.get_node_or_null("RimLight") as DirectionalLight3D
	if rim != null:
		# Light travels down and toward the eye from above and behind the rock: its top limb is lit.
		var to_eye := (xf.origin - _meteor.global_position).normalized()
		var travel := (-xf.basis.y * 0.8 + to_eye * 0.6).normalized()
		rim.global_transform = Transform3D(Basis.looking_at(travel, xf.basis.z), _meteor.global_position)

	# The view: the player's own until the alarm line, then taken and turned toward the meteor - part
	# way (VIEW_FOLLOW), so the window stays in the frame and the rock fills it rather than the wall.
	var to_m := xf.affine_inverse() * _meteor.global_position
	var mb := _bearing(to_m)
	_meteor_bearing = mb
	var take := smoothstep(LOOK_TAKE.x, LOOK_TAKE.y, tau)
	_yaw_target = lerpf(_player_yaw, clampf(mb.x * VIEW_FOLLOW.x, -YAW_LIMIT, YAW_LIMIT), take)
	_pitch_target = lerpf(_player_pitch, clampf(mb.y * VIEW_FOLLOW.y, -PITCH_LIMIT, PITCH_LIMIT), take)

	if tau >= ALARM_LINE_T and _once("alarm_line"):
		_say(RADIO_ALARM)
	# Alarm: the light and the beacon pulse; a low buzz every BEEP_EVERY until the contact.
	var pulse := 0.5 + 0.5 * sin(tau * TAU * 1.6)
	pulse *= pulse
	var alarm: OmniLight3D = _props["alarm"]
	alarm.light_energy = (0.35 + 1.1 * pulse) * (1.0 if tau < FLASH.x else 0.0)
	var amat: ShaderMaterial = _props["alarm_mat"]
	amat.set_shader_parameter("emission_strength", 2.2 * pulse)
	_overlay.set_alarm((0.25 + 0.75 * pulse) * (1.0 - smoothstep(CONTACT_T, FLASH.x, tau)) * smoothstep(0.0, 0.4, tau))
	var lamp: OmniLight3D = _props["lamp"]
	lamp.light_energy = lerpf(0.9, 0.55, smoothstep(0.0, 0.6, tau))
	if tau >= _beep_next and tau < CONTACT_T:
		_beep_next += BEEP_EVERY
		AudioManager.play_sfx("blocked", -9.0, 0.0)
	# Rumble through the bank, a hard shake at the contact.
	_shake = 0.35 * smoothstep(SWERVE.x, SWERVE.y, tau)
	if tau >= CONTACT_T:
		_shake = 0.35 + 2.6 * exp(-(tau - CONTACT_T) / 0.45)
	if tau >= CONTACT_T and _once("contact"):
		_sparks.restart()
		_sparks.emitting = true
		AudioManager.play_sfx("rocket_land", -1.0, 0.02)
		_log("graze")
	if tau >= FLASH.x:
		if _once("impact_sfx"):
			AudioManager.play_sfx("finale_impact", -2.0, 0.0)
		_white = smoothstep(FLASH.x, FLASH.y, tau)
		_overlay.set_flash(_white)
	if tau >= FLASH.y:
		_overlay.set_flash(1.0)
		_cut()


# ============================================================================= ending
## THE CUT. The white is fully opaque: put back what this node changed (header "THE HAND-OFF"), tell
## IntroDirector (which starts the crash shot), then fade the white off over the crash and leave.
func _cut() -> void:
	if _done:
		return
	_log("cut: white opaque at tau=%.2f, look t=%.1f" % [_tau, _look_t])
	_teardown()
	finished.emit(false)
	if not is_inside_tree():
		return
	var tw := create_tween()
	tw.tween_method(_overlay.set_flash, 1.0, 0.0, WHITE_OUT)
	tw.tween_callback(queue_free)


## Everything this node changed, put back - BEFORE any emit. The rig's camera goes current only if the
## cockpit's still is (a no-op when CrashIntro or anything else already has the view); the crash
## shot takes the view from it on its first step. Player, rig placement, modal: never touched.
func _teardown() -> void:
	_done = true
	_running = false
	_phase = Phase.DONE
	var rc := _rig.get_camera() if _rig != null and is_instance_valid(_rig) else null
	if _cam != null and is_instance_valid(_cam) and _cam.current and rc != null:
		rc.current = true
	if _root != null and is_instance_valid(_root):
		_root.queue_free()
	_root = null
	_head = null
	_cam = null
	if _meteor != null and is_instance_valid(_meteor):
		_meteor.queue_free()
	_meteor = null
	if _env != null and is_instance_valid(_env):
		_env.call("set_space_blend", 0.0)
		if _time_scale >= 0.0:
			_env.set("time_scale", _time_scale)
			_time_scale = -1.0
	AudioManager.stop_loop("rocket_loop", 0.1)
	if _captions != null and is_instance_valid(_captions):
		_captions.stop_voice()
		_captions.queue_free()
	_captions = null
	if _overlay != null:
		_overlay.hide_line()
		_overlay.set_dot(false, 0.0, false)
		_overlay.set_alarm(0.0)


func _skip() -> void:
	if _skipping or _done or _confirming:
		return
	_confirming = true
	# _step (which drives the button) is frozen while the question is open, so hide it here: under the
	# pop-up it would be a second, dead "Skip" (found by the round-3 probe clicking it by mistake).
	if _overlay != null:
		_overlay.set_skip_button(false)
	var go: bool = await SkipConfirm.ask(self, "Skip the intro?", "Skip", "Keep watching")
	_confirming = false
	if not is_inside_tree() or _done or _skipping:
		return
	if not go:
		# The key that answered may be one of SKIP_ACTIONS and still down: resync (CrashIntro._skip).
		for a in SKIP_ACTIONS:
			_skip_held[a] = Input.is_action_pressed(a)
		_pointers.clear()
		return
	_skipping = true
	_log("skip at t=%.2f" % _t)
	if _captions != null:
		_captions.stop_voice()
	await SceneRouter.fade_out(0.25)
	if not is_inside_tree():
		return
	_teardown()
	_overlay.set_flash(0.0)
	finished.emit(true)
	queue_free()


func _exit_tree() -> void:
	# Freed mid-scene (quit to title, or IntroDirector torn down): put back the view and the sky. The
	# player and the modal belong to CrashIntro, which has its own _exit_tree.
	if not _done and _running:
		_teardown()


# ============================================================================= input
## The action half of the skip, for Director timelines (`Input.action_press` sends no InputEvent):
## CrashIntro._physics_process, same edges, same priming.
func _physics_process(_delta: float) -> void:
	if not _running or _done or _skipping or _confirming:
		return
	var edge := false
	for a in SKIP_ACTIONS:
		var now := Input.is_action_pressed(a)
		if now and not bool(_skip_held.get(a, false)) and _skip_primed and _t >= SKIP_ARM_T:
			edge = true
		_skip_held[a] = now
	_skip_primed = true
	if edge and _phase != Phase.DONE:
		_skip()


func _input(event: InputEvent) -> void:
	if not _running or _done or _skipping or _confirming:
		return
	var armed := _t >= SKIP_ARM_T
	if event is InputEventKey:
		var k := event as InputEventKey
		if not k.pressed or k.echo or _is_look_event(event) or k.keycode in [KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META]:
			return
		if armed:
			get_viewport().set_input_as_handled()
			_skip()
		return
	if event is InputEventJoypadButton:
		if (event as InputEventJoypadButton).pressed and armed:
			get_viewport().set_input_as_handled()
			_skip()
		return
	# A finger also arrives as an emulated mouse copy (device -1): only the touch itself counts.
	if event.device == InputEvent.DEVICE_ID_EMULATION and (event is InputEventMouseButton or event is InputEventMouseMotion):
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_pointer(-1, mb.pressed, mb.position)
		return
	if event is InputEventMouseMotion:
		if _pointers.has(-1):
			_drag(-1, (event as InputEventMouseMotion).position, (event as InputEventMouseMotion).relative)
		return
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		_pointer(st.index, st.pressed, st.position)
		return
	if event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		if _pointers.has(sd.index):
			_drag(sd.index, sd.position, sd.relative)


func _on_skip_button() -> void:
	if not _running or _done or _skipping or _confirming or _t < SKIP_ARM_T:
		return
	_pointers.clear()
	_log("skip button")
	_skip()


func _is_look_event(event: InputEvent) -> bool:
	for a in LOOK_ACTIONS:
		if InputMap.has_action(a) and event.is_action(a):
			return true
	return false


func _pointer(id: int, pressed: bool, pos: Vector2) -> void:
	if pressed:
		# One looking finger at a time: a second finger is ignored (no pinch, no double count).
		if _pointers.is_empty():
			_pointers[id] = {"start": pos, "moved": 0.0, "ms": Time.get_ticks_msec()}
		return
	# A lift ends the look. A tap is NOT a skip here (lead, round 2): a child taps the plant or the
	# photos to "look" at them. Skipping is the overlay's Skip button, keys, pad buttons, SKIP_ACTIONS.
	_pointers.erase(id)


func _drag(id: int, _pos: Vector2, rel: Vector2) -> void:
	var p: Dictionary = _pointers[id]
	p["moved"] = float(p["moved"]) + rel.length()
	if _phase != Phase.LOOK:
		return
	var rows := maxf(get_viewport().get_visible_rect().size.y, 1.0)
	var k := DRAG_DEG_PER_SCREEN / rows
	# Drag right -> look right; drag up -> look up (the game's own camera look direction).
	_pending_look += Vector2(-rel.x, -rel.y) * k


# ============================================================================= helpers
func _update_pulses() -> void:
	var pulses: Dictionary = _props.get("pulses", {})
	for id: String in pulses:
		var p: MeshInstance3D = pulses[id]
		if not is_instance_valid(p):
			continue
		var on := _phase == Phase.LOOK and not _triggered.has(id)
		var phase := float(id.hash() % 100) * 0.07
		var k := 0.5 + 0.5 * sin(_t * 2.4 + phase)
		var target := (0.25 + 0.45 * k) if on else 0.0
		var m := (p.mesh as QuadMesh).material as ShaderMaterial
		var fv: Variant = m.get_shader_parameter("fade")
		var cur := float(fv) if fv != null else 1.0
		m.set_shader_parameter("fade", move_toward(cur, target, 0.05))
		p.visible = cur > 0.01 or on
		p.scale = Vector3.ONE * (0.85 + 0.25 * k)


func _once(key: String) -> bool:
	if _fired.has(key):
		return false
	_fired[key] = true
	return true


func _log(msg: String) -> void:
	print("COCKPIT [%6.2f] %s" % [_t, msg])


# ============================================================================= test hooks
## For the showcase / critics: a snapshot of the state (nothing in the game calls this).
func debug_state() -> Dictionary:
	return {
		"phase": Phase.keys()[_phase], "t": _t, "look_t": _look_t, "tau": _tau,
		"yaw": _yaw, "pitch": _pitch, "yaw_target": _yaw_target, "pitch_target": _pitch_target,
		"player_yaw": _player_yaw, "player_pitch": _player_pitch, "seen": _seen.keys(), "triggered": _triggered.keys(),
		"dwell": _dwell_id, "item": _overlay.shown_text() if _overlay != null else "",
		"item_typing": _overlay.is_typing() if _overlay != null else false,
		"radio_typing": _captions.is_typing() if _captions != null else false,
		"radio_on": _radio_on, "nudged": _nudged, "forced": _meteor_forced, "idle": _idle,
		"cam_current": _cam != null and _cam.current, "confirming": _confirming, "pointers": _pointers.size(),
		"white": _overlay.flash_alpha() if _overlay != null else 0.0,
		"meteor_bearing": _meteor_bearing,
		"meteor_dist": _meteor.global_position.distance_to(_root.global_position) if _meteor != null and _root != null and _meteor.visible else -1.0,
	}


## Where target `id` is on screen (canvas pixels), for the showcase's synthesised taps.
func debug_target_screen(id: String) -> Vector2:
	if _cam == null or _root == null:
		return Vector2(-1, -1)
	var world := _root.global_transform * ((_targets[id] as Dictionary)["at"] as Vector3)
	return _cam.unproject_position(world)


func debug_skip_rect() -> Rect2:
	return _overlay.skip_rect() if _overlay != null else Rect2()


## Cockpit-local yaw/pitch of each target, for the showcase to aim the synthesised drags.
func debug_target_bearings() -> Dictionary:
	var out := {}
	for id: String in _targets:
		out[id] = _bearing((_targets[id] as Dictionary)["at"] as Vector3)
	return out
