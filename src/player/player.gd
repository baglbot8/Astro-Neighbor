class_name Player
extends PlanetBody
## The playable astronaut. Camera-relative movement on the sphere, jump with coyote time / buffer /
## variable height, procedural animation via AstronautModel, interaction finder, footsteps, dust,
## blob shadow. See docs/ARCHITECTURE.md §6 for the public contract.

signal interact_target_changed(target: Interactable)

const WALK_SPEED := 4.2
const RUN_SPEED := 7.0
const ACCEL := 30.0
const DECEL := 40.0
const AIR_CONTROL := 0.55
const TURN_SPEED := 11.0
const JUMP_VELOCITY := 8.5
const JUMP_ANTICIPATION := 0.06
const COYOTE_TIME := 0.1
const JUMP_BUFFER := 0.1
const JUMP_CUT := 0.5
const LAND_TIME := 0.24

# ===================================================================== airborne animation grace
## THE ACTUAL REASON THE RUN LOOKED STRANGE. The user: *"The dashing animation looks strange."*
##
## Measured, not guessed. `showcase/player_walk.tscn --debug` now prints a per-frame histogram of
## the animation state; ten seconds of holding `run` on the showcase planet gave:
##     fall 49%, land 47%, idle 2%, walk 1%, **run 0%**
## against ten seconds of walking, which gave walk 95%. At 7 m/s the boots skip off every small rise
## in the ground for a frame or two at a time, `is_on_floor()` drops, and `_select_state` swapped the
## whole body to the FALL pose (arms nearly overhead, legs forward and apart) and then to the LAND
## pose for LAND_TIME afterwards. The player was almost never seeing the run pose at all — they were
## seeing fall and land alternating several times a second. No amount of tuning the run pose could
## have fixed that, which is presumably why the previous pass, built to the same brief, still read
## as wrong.
##
## The fix is the standard one: the ANIMATION gets a grace window that the physics does not. Contact
## lost for less than AIR_ANIM_GRACE while running keeps the locomotion pose, and a landing only
## plays the land pose (with its dust puff and its thud) if the astronaut was genuinely airborne for
## LAND_MIN_AIRTIME. A real jump is exempt from both — `_jumping` is set the moment one launches, so
## deliberate air always animates as air.
const AIR_ANIM_GRACE := 0.16
const LAND_MIN_AIRTIME := 0.20
const LEAN_SIDE_GAIN := 0.0065
const LEAN_FWD_GAIN := 0.004
const LEAN_MAX := 0.22
const RUN_DUST_MIN_SPEED := 5.2

# ============================================================================= jetpack (R2.8)
## docs/STYLE_GUIDE.md R2.8, from the user: *"let's add a small jetpack boost (with puff clouds
## coming out from the backpack) that if held helps the astronaut go higher and float a bit toward
## the ground while moving. It should be about as fast as sprinting while floating in the air, and
## may also help with hopping over tall decor or something"*.
##
## The verb has two phases and one resource:
##   CLIMB  - below BOOST_CLIMB_HEIGHT the thrust drives the radial velocity up to BOOST_RISE_SPEED;
##   FLOAT  - above it the target flips to a slow BOOST_FALL_SPEED descent, so holding the button
##            gives a long, controlled, cruising glide rather than unlimited altitude;
##   FUEL   - BOOST_BURN_TIME seconds of it, refilled only on the ground.
## Horizontal speed is pinned to RUN_SPEED while boosting whether or not `run` is held, which is
## exactly the *"about as fast as sprinting while floating"* the note asks for, and air control is
## raised so the glide can actually be steered.
##
## SAFETY (R2.8: "must not break spherical gravity, must not let the player leave the planet or get
## stuck off-surface"): the boost only ever writes the component of velocity along `up`, so radial
## gravity, the tangent-plane movement and the sphere alignment are all untouched. Thrust is refused
## above BOOST_MAX_HEIGHT and cancelled outright above BOOST_ABORT_HEIGHT, fuel is finite and only
## refills with both feet on the ground, and nothing here disables gravity - let go, or run out, and
## the astronaut falls normally.
## Numbers below were tuned by flying `tests/director/player_jetpack.json` over the tall props.

## Upward speed the thruster drives toward while climbing (m/s). Straight jump apex is 1.20 m
## (JUMP_VELOCITY^2 / 2g); this takes the ceiling to ~3.4 m, which clears every tall decoration.
const BOOST_RISE_SPEED := 5.6
## Thrust accelerations must BEAT gravity, not merely oppose it: `apply_planet_gravity` runs first
## and subtracts PlanetBody.gravity_strength (30 m/s^2) from the radial velocity every tick, so an
## accel of 26 left the float losing 4 m/s^2 and drifting down at 1.95 m/s instead of the 0.75 it
## was asked for. These are the NET rates plus 30.
const BOOST_RISE_ACCEL := 80.0
## Descent speed once the climb tops out. This is the *"float a bit toward the ground while moving"*
## of the note, so it has to be a visible, committed descent - the first tuning pass let the climb
## and float targets fight across the threshold every frame and the result was a dead-level hover at
## 3.40 m, which reads as flying, not floating. Hence the latch in `_update_boost_state`.
## The user's words are *"float A BIT toward the ground"*, and the number is set by the props: the
## tallest decorations (beacon_tower, antenna_tree) top out at 2.62 m, so a full-tank hold has to
## spend nearly all of its burn above that. 0.75 m/s over the ~2.1 s of float a full tank buys is a
## 1.6 m descent from 3.8 m - a visible, committed drift downward that still clears every prop for
## the useful part of the flight.
const BOOST_FALL_SPEED := 0.75
const BOOST_FALL_ACCEL := 60.0
## Feet-above-ground at which the climb LATCHES into the float, and the height it un-latches at.
## The latch is what makes the float a float: without it the two targets fight across the threshold
## every frame and the result is a dead-level hover, which reads as flying rather than gliding. The
## un-latch is deliberately LOW - lower than a single tank can ever sink to - so it only ever helps
## a second boost taken close to the ground, never turns one long hold into a bouncing sawtooth.
const BOOST_CLIMB_HEIGHT := 3.8
const BOOST_FLOAT_EXIT := 0.8
## No thrust at all above this, so the ceiling is hard even if the height probe is momentarily wrong.
const BOOST_MAX_HEIGHT := 4.6
## And a belt-and-braces cut-out: past this the boost is cancelled outright.
const BOOST_ABORT_HEIGHT := 7.0
## Air control while boosting. The normal 0.55 makes a glide feel like ice.
const BOOST_AIR_CONTROL := 0.92
## Seconds of continuous burn on a full tank, and seconds to refill it standing on the ground.
const BOOST_BURN_TIME := 2.8
const BOOST_REFILL_TIME := 1.5
## Ground time before the tank starts refilling, so a bunny-hop cannot top up mid-stride.
const BOOST_REFILL_DELAY := 0.25
## The tank must reach this before the boost can be re-engaged, so an empty tank cannot be stuttered.
const BOOST_RESTART_FUEL := 0.12
## Held-from-standing delay. Boost and jump share the space bar (R2.8: "jump held while airborne is
## the natural fit"), so a tap must stay a plain jump: from the ground the thruster only lights
## after the button has been down this long, by which time a jump is already airborne anyway.
const BOOST_GROUND_DELAY := 0.18
## Thrust ramp, so ignition and cut-off are not instant steps in the plume or the sound.
const BOOST_SPOOL_UP := 9.0
const BOOST_SPOOL_DOWN := 5.0
const BOOST_LOOP_DB := -13.0
## Preferred looping thruster sample, then fallbacks. `rocket_loop` is LAST and is a poor substitute:
## AudioManager keys its loop players by sample name, so sharing it with the rocket would let one
## system's stop_loop kill the other's sound.
const BOOST_LOOP_CANDIDATES := ["jetpack_loop", "thruster_loop", "rocket_loop"]

const EMOTE_CYCLE := ["wave", "happy", "dance"]
## Extra seconds allowed past an emote's nominal length before the watchdog force-clears it.
const EMOTE_GRACE := 0.75
const FOOTSTEP_CANDIDATES := ["footstep_grass", "footstep_grass_1", "footstep_grass_2", "footstep_grass_a", "footstep_grass_b"]

## False while a modal UI is open (or when a system such as dialogue freezes the player).
var input_enabled: bool = true

var _model: AstronautModel
var _shadow: MeshInstance3D
var _shadow_mat: ShaderMaterial
var _dust_land: GPUParticles3D
var _dust_run: GPUParticles3D
var _target: Interactable
var _carry_id: String = ""
var _emote: String = ""
## Wall-clock deadline for the active emote. The model's `emote_finished` signal is the normal
## way an emote ends, but it only fires while the model is STILL in that emote state. If anything
## else overwrites the model state in the same frame (the landing handler setting "land" is the
## known case, found by the rocket critic), the signal never arrives and `_emote` stays set
## forever - which silently disables `interact` for the rest of the session. This deadline is the
## guaranteed backstop. Never rely on the signal alone.
var _emote_deadline: float = 0.0
var _talking: bool = false
var _speed_factor: float = 0.0
var _coyote: float = 0.0
var _jump_buffer: float = 0.0
var _jump_anticipation: float = -1.0
var _jumping: bool = false
var _jump_cut_done: bool = false
var _jump_was_pressed: bool = false
var _interact_was_pressed: bool = false
var _emote_was_pressed: bool = false
var _was_on_floor: bool = true
## Seconds since the feet last touched anything. Drives the animation grace above; the physics is
## untouched and still uses `is_on_floor()` directly.
var _air_time: float = 0.0
var _land_timer: float = 0.0
var _prev_tv: Vector3 = Vector3.ZERO
var _lean_side: float = 0.0
var _lean_fwd: float = 0.0
var _emote_cycle_index: int = 0
var _footstep_sfx: Array[String] = []
var _footstep_alt: int = 0
var _has_jump_sfx := false
var _has_land_sfx := false
var _face_override_timer: float = 0.0
var _face_override_pos: Vector3 = Vector3.ZERO
var _ground_height: float = 0.0
# ---- jetpack
var _boost_fuel: float = 1.0
var _boosting: bool = false
var _boost_thrust: float = 0.0
var _boost_hold: float = 0.0
var _boost_floating: bool = false
var _grounded_time: float = 0.0
var _boost_loop_sfx: String = ""
var _boost_loop_on: bool = false
var _last_pos: Vector3 = Vector3.ZERO
## Cached CameraRig (see `_camera_rig`), used to front the camera during an emote.
var _rig: CameraRig = null


func _ready() -> void:
	super._ready()
	add_to_group("player")
	collision_layer = 1 << 1
	collision_mask = 1 | (1 << 2) | (1 << 3) | (1 << 6)
	jump_velocity = JUMP_VELOCITY
	_model = get_node_or_null("Model") as AstronautModel
	if _model == null:
		_model = AstronautModel.new()
		_model.name = "Model"
		add_child(_model)
	_model.footstep.connect(_on_footstep)
	_model.emote_finished.connect(_on_emote_finished)
	_build_shadow()
	_build_dust()
	_resolve_sfx()
	EventBus.ui_modal_opened.connect(_on_modal_changed)
	EventBus.ui_modal_closed.connect(_on_modal_changed)


func _exit_tree() -> void:
	# The thruster loop lives on AudioManager, which outlives the scene, so it has to be stopped by
	# hand or it keeps humming through the next planet.
	if _boost_loop_on and _boost_loop_sfx != "":
		AudioManager.stop_loop(_boost_loop_sfx, 0.1)
		_boost_loop_on = false


## THE ONLY WRITER OF `input_enabled` THAT TRACKS THE MODAL GATE, and it is a RECOMPUTE from the
## gate rather than a per-signal toggle — deliberately, because `EventBus.reset_modals()` now calls
## it a second way. That reset zeroes the gate on a scene change and then replays one
## `ui_modal_closed` per modal it cleared, precisely so this line runs again; before it did, a reset
## left `input_enabled` false with `is_modal_open()` already false and the astronaut could look
## around but never walk. Measured: two `ui_modal_opened("shop")` then `reset_modals()` left
## `en=N modal=0` for the whole 16 s run and a 1.0 s forward push travelled 0.00 m; with the replay
## the next frame reads `en=Y` and the same push travels +3.80 m along facing.
##
## So this must stay a recompute of the CURRENT gate. `input_enabled = false` on open / `true` on
## close would look identical in normal play and would break the replay: a reset that cleared two
## modals emits two closes, and the second one would re-enable input that the first had already
## handled — or, worse, an ordering where an open follows and never gets its close.
##
## The rocket pad (`_freeze_player` / `_thaw_player`) and the dialogue runner write `input_enabled`
## too, and those are NOT modal-driven. That is why the launch cutscene still reads `en=N` here with
## `modal=0`: physics is off as well, which is the pad's freeze, not a stale gate.
func _on_modal_changed(_name: String) -> void:
	input_enabled = not EventBus.is_modal_open()


# ============================================================================= public API
## Turns the astronaut toward a world position (used when an NPC starts talking).
func face_toward(world_pos: Vector3) -> void:
	_face_override_pos = world_pos
	_face_override_timer = 0.35


## Plays an emote: "wave", "happy", "think", "dance", "surprised". Movement input cancels it.
##
## Also asks the camera to swing round to a three-quarter FRONT view for the duration. The
## integration critic: *"Emotes are only ever seen from behind ... that is a lot of good work the
## player never sees."* Every emote is built in the arms and the chest, and the follow camera sits
## squarely behind the backpack, so without this the player's own wave is a shrug of a helmet.
## `CameraRig.orbit_front` declines while a dialogue focus is running and puts the heading back
## where it was on release, so nothing else has to know about it.
func play_emote(emote_name: String) -> void:
	if AstronautModel.get_emote_duration(emote_name) <= 0.0:
		push_warning("Player: unknown emote '%s'" % emote_name)
		return
	_emote = emote_name
	_emote_deadline = Time.get_ticks_msec() / 1000.0 + AstronautModel.get_emote_duration(emote_name) + EMOTE_GRACE
	_model.set_state(emote_name)
	var rig := _camera_rig()
	if rig:
		rig.orbit_front()


## Shows an item held above the head (favor deliveries). "" clears.
func set_carry_item(item_id: String) -> void:
	_carry_id = item_id
	if item_id == "":
		_model.set_carry_item(null)
		return
	var def := Catalog.get_item(item_id)
	var col := Color(str(def.get("icon_color", "#ffe27a")))
	_model.set_carry_item(AstronautModel.make_item_placeholder(col), Vector3(0.0, AstronautModel.PLACEHOLDER_ITEM_HEIGHT * 0.5, 0.0))


func get_carry_item() -> String:
	return _carry_id


## While true the astronaut plays the talk animation instead of idle (dialogue systems toggle this).
func set_talking(on: bool) -> void:
	_talking = on


func get_model() -> AstronautModel:
	return _model


func get_interact_target() -> Interactable:
	return _target


## Test hook for the *"sometimes i cant see what im trying to interact with"* complaint. Prints one
## line per Interactable in the scene: its prompt, its reach, its surface direction (so a Director
## timeline can `teleport_to_dir` straight to it), how far the astronaut is from it, whether it is
## inside the camera frustum, and whether the sight line from the camera to it is clear of terrain
## and buildings. Twelve interactables across three planets is more than can be judged by eye from
## twelve screenshots, and "on screen but behind a wall" is exactly the failure the player reported.
func debug_dump_interactables() -> void:
	var cam := get_viewport().get_camera_3d()
	var space := get_world_3d().direct_space_state
	var rows: Array[String] = []
	for n: Node in get_tree().get_nodes_in_group("interactables"):
		var it := n as Interactable
		if it == null or not it.is_inside_tree():
			continue
		var pos := it.global_position
		var d := pos.distance_to(global_position)
		var on_screen := false
		var clear := false
		if cam:
			on_screen = not cam.is_position_behind(pos) and Rect2(Vector2.ZERO, Vector2(get_viewport().get_visible_rect().size)).has_point(cam.unproject_position(pos))
			if space:
				var q := PhysicsRayQueryParameters3D.create(cam.global_position, pos, 1 | (1 << 6))
				q.hit_from_inside = false
				clear = space.intersect_ray(q).is_empty()
		var dir := (pos - (planet.global_position if planet else Vector3.ZERO)).normalized()
		rows.append("INTERACT %-22s prompt=%-14s reach=%.1f dist=%.2f on_screen=%s sight_clear=%s dir=[%.4f,%.4f,%.4f]"
			% [it.get_parent().name if it.get_parent() else it.name, it.prompt_text, it.reach, d, str(on_screen), str(clear), dir.x, dir.y, dir.z])
	rows.sort()
	print("INTERACT COUNT %d" % rows.size())
	for r: String in rows:
		print(r)


func is_running() -> bool:
	return _speed_factor > 1.2


## Height of the feet above the ground under them (0 when standing).
func get_ground_height() -> float:
	return _ground_height


# ============================================================================= loop
func _find_planet() -> void:
	var p := get_tree().get_first_node_in_group("planet")
	if p == null:
		var parent := get_parent()
		if parent:
			p = parent.get_node_or_null("Planet")
	if p is Planet:
		planet = p as Planet


func _physics_process(delta: float) -> void:
	# Watchdog: guarantee an emote always ends. See the comment on `_emote_deadline`.
	if _emote != "" and _emote_deadline > 0.0 and Time.get_ticks_msec() / 1000.0 > _emote_deadline:
		push_warning("Player: emote '%s' never reported finishing; clearing it." % _emote)
		_cancel_emote()
	if planet == null:
		_find_planet()
		if planet == null:
			return
	# Teleport guard: the exhaust plume is world-space by design (that trailing arc is the point),
	# so anything that moves the astronaut instantly — a spawn, a rocket arrival — would otherwise
	# leave a line of puffs stretched across the planet.
	var step := global_position.distance_to(_last_pos)
	_last_pos = global_position
	if step > 3.0 and _model:
		_model.clear_jet_puffs()
	align_to_planet()
	var gameplay := input_enabled and not EventBus.is_modal_open()

	# ---- read input
	var move := Vector2.ZERO
	var running := false
	var jump_pressed := false
	var interact_pressed := false
	var emote_pressed := false
	var boost_pressed := false
	if gameplay:
		move = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		running = Input.is_action_pressed("run")
		jump_pressed = Input.is_action_pressed("jump")
		interact_pressed = Input.is_action_pressed("interact")
		emote_pressed = Input.is_action_pressed("emote")
		boost_pressed = Input.is_action_pressed("boost")
	var jump_just := jump_pressed and not _jump_was_pressed
	var interact_just := interact_pressed and not _interact_was_pressed
	var emote_just := emote_pressed and not _emote_was_pressed
	_jump_was_pressed = jump_pressed
	_interact_was_pressed = interact_pressed
	_emote_was_pressed = emote_pressed

	# ---- camera-relative wish direction on the tangent plane
	var wish := Vector3.ZERO
	var wish_len := 0.0
	if move.length_squared() > 0.0001:
		var fwd := _camera_planar_forward()
		var right := fwd.cross(up).normalized()
		wish = fwd * (-move.y) + right * move.x
		wish_len = minf(wish.length(), 1.0)
		if wish_len > 0.001:
			wish = wish / wish.length()
	if wish_len > 0.01 and _emote != "":
		_cancel_emote()
	if _emote != "":
		wish_len = 0.0

	# ---- jetpack arbitration (before movement, so the boost can raise the speed cap and air control)
	var on_floor_before := is_on_floor()
	_update_boost_state(delta, boost_pressed, on_floor_before)

	# ---- accelerate / decelerate
	# While boosting the horizontal cap is RUN_SPEED whether or not `run` is held — R2.8 asks for
	# "about as fast as sprinting while floating in the air", i.e. boosting IS a way to travel.
	var max_speed := RUN_SPEED if (running or _boosting) else WALK_SPEED
	var target_vel := wish * max_speed * wish_len
	var tv := get_tangent_velocity()
	var accel := ACCEL if wish_len > 0.01 else DECEL
	if not on_floor_before:
		accel *= BOOST_AIR_CONTROL if _boosting else AIR_CONTROL
	tv = tv.move_toward(target_vel, accel * delta)
	set_tangent_velocity(tv)

	# ---- turning
	if _face_override_timer > 0.0:
		_face_override_timer -= delta
		face_direction(_face_override_pos - global_position, 22.0, delta)
	elif wish_len > 0.01:
		face_direction(wish, TURN_SPEED, delta)

	# ---- jump: buffer + coyote + anticipation + variable height
	_coyote = COYOTE_TIME if on_floor_before else maxf(_coyote - delta, 0.0)
	if jump_just:
		_jump_buffer = JUMP_BUFFER
	else:
		_jump_buffer = maxf(_jump_buffer - delta, 0.0)
	if _jump_anticipation >= 0.0:
		_jump_anticipation -= delta
		if _jump_anticipation < 0.0:
			_launch_jump()
	elif _jump_buffer > 0.0 and _coyote > 0.0 and not _jumping and _emote == "":
		_jump_buffer = 0.0
		_coyote = 0.0
		_jump_anticipation = JUMP_ANTICIPATION
		_model.set_state("jump")
	if _jumping and not _jump_cut_done and not jump_pressed:
		var radial := velocity.dot(up)
		if radial > 0.0:
			velocity -= up * radial * JUMP_CUT
		_jump_cut_done = true

	apply_planet_gravity(delta)
	# The thruster is applied AFTER gravity and only along `up`, so it overrides the fall without
	# ever touching the tangent-plane motion or the radial gravity model.
	_apply_boost_thrust(delta)
	move_and_slide()

	# ---- landing
	var on_floor := is_on_floor()
	if on_floor and not _was_on_floor:
		_on_land(_air_time)
	_air_time = 0.0 if on_floor else _air_time + delta
	if on_floor and _jumping and velocity.dot(up) <= 0.01 and _jump_anticipation < 0.0:
		_jumping = false
	_was_on_floor = on_floor
	if _land_timer > 0.0:
		_land_timer -= delta

	# ---- lean from acceleration (lateral -> side lean, forward -> nose down)
	var tv_after := get_tangent_velocity()
	var acc := (tv_after - _prev_tv) / maxf(delta, 0.0001)
	_prev_tv = tv_after
	var right_axis := global_transform.basis.x
	var fwd_axis := -global_transform.basis.z
	var side_target := clampf(acc.dot(right_axis) * LEAN_SIDE_GAIN, -LEAN_MAX, LEAN_MAX)
	var fwd_target := clampf(acc.dot(fwd_axis) * LEAN_FWD_GAIN, -LEAN_MAX * 0.6, LEAN_MAX * 0.6)
	var kl := 1.0 - exp(-7.0 * delta)
	_lean_side = lerpf(_lean_side, side_target, kl)
	_lean_fwd = lerpf(_lean_fwd, fwd_target, kl)
	_model.set_lean(_lean_fwd, _lean_side)

	# ---- animation state
	var speed := tv_after.length()
	_speed_factor = speed / WALK_SPEED
	_select_state(on_floor, speed)
	# Same grace as the pose: without it the trail strobes on and off several times a second while
	# sprinting, because `is_on_floor()` does.
	_dust_run.emitting = (on_floor or _grounded_enough()) and speed > RUN_DUST_MIN_SPEED
	# The model owns the plume; it needs the world velocity so each puff inherits some of it.
	_model.set_boost_thrust(_boost_thrust, velocity)

	# ---- ground / shadow
	_update_shadow()

	# ---- interaction
	_update_interact_target()
	if interact_just and _target and _emote == "" and _jump_anticipation < 0.0:
		_target.interact(self)
	if emote_just and on_floor and _emote == "":
		play_emote(EMOTE_CYCLE[_emote_cycle_index])
		_emote_cycle_index = (_emote_cycle_index + 1) % EMOTE_CYCLE.size()


func _process(delta: float) -> void:
	if _model:
		_model.tick(delta, _speed_factor)


## THE BASIS "move_forward" IS RESOLVED AGAINST, on the tangent plane.
##
## ASKS THE RIG FIRST, and only falls back to the active camera's own basis. That order is the fix
## for "tap an emote, push the stick, and you walk sideways or backwards for a beat".
##
## WHAT WAS WRONG. This function read `-camera.basis.z` — where the LENS points — and
## `CameraRig.orbit_front` deliberately swings the lens round to a three-quarter FRONT view for the
## length of an emote, 180 - ORBIT_YAW_DEG = 154 deg off the astronaut's facing, so the player can
## see the pose (that is a feature; see `CameraRig.orbit_front`). For those ~2 s "forward" therefore
## meant "roughly backwards". The rig keeps the player's control heading intact throughout — it is
## `_fwd_saved`, and it measured 0.0 deg of error for the whole swing — and now exposes it as
## `CameraRig.get_planar_forward()`, with `get_camera_forward()` for anything that really wants the
## lens. Reading the lens here was what kept the two welded together.
##
## MEASURED on a cold start with a player-triggered "dance" emote, no landing involved
## (Compatibility renderer, `--ui=mobile`, Director timeline; a 1.0 s `move_forward` push starting
## at the given delay after the emote, displacement projected on the astronaut's facing at the
## moment the push began, `--no-control-basis` for the before arm):
##
##                        BEFORE (m along facing)            AFTER (m along facing)
##     delay          home     zorp     bolt             home     zorp     bolt
##     +0.3 s        +3.01    +2.89    +2.45            +3.71    +3.63    +3.63
##     +0.8 s        -1.29    -1.13    -1.78            +3.55    +2.06    +3.63
##     +1.5 s        -2.17    -2.17    -2.21            +3.61    +3.63    +3.64
##     +2.5 s        -1.39    -1.38    -1.16            +3.75    +3.64    +3.63
##
## 9 of 12 pushes were NEGATIVE before (the astronaut walking away from where they were pointed);
## 12 of 12 are positive after, and 11 of those 12 are within 0.1 m of the 3.6-3.7 m an unobstructed
## 1.0 s walk covers. The exception is zorp at +0.8 s: 2.06 m along a total displacement of 2.18 m,
## i.e. straight but SHORT — the astronaut walked into something. Heading error sampled every 0.15 s
## for 4 s from the emote peaked at 154.0 deg on all three planets before and 0.0 deg on all three
## after, while the camera's own heading still peaks at 154.0 deg after — the emote camera is
## untouched, it just no longer steers the stick. The +0.3 s row is positive in both arms only
## because the orbit is still winding in at that point; it is not evidence of anything working.
##
## THE LANDING CASE, which this must not regress, re-measured the same way after the change (one
## landing per run, `Rocket.launch_to`, a 1.0 s push at +0.3 / +0.8 / +1.5 / +2.5 / +3.8 s after
## control returns, on zorp / bolt / hub): 15 of 15 positive, +3.63 to +3.68 m on zorp and bolt and
## +2.85 to +2.89 m on hub (a shorter run there, and consistent across all five delays), with
## head_err 0.0 deg at every mark. The +3.8 s row is outside `LANDING_ORBIT_GRACE`, so it checks the
## window the grace does NOT cover; no emote is running by then either way, so it is a regression
## check on ordinary walking rather than a second reading of the bug.
##
## PROVENANCE, because the before/after arms are not symmetrical. The BEFORE column is a run of the
## code as it stood — this function reading the lens — in which the rig's `--no-control-basis`
## toggle was a no-op precisely BECAUSE nothing here consulted the rig; the arm with the toggle off
## measured the same thing (home -1.61 / -2.26 / -1.36 at the three later delays) which is the
## clearest evidence that the rig-side change alone fixed nothing. `--no-control-basis` is only a
## faithful "before" for the rig; with this function now asking the rig, it restores the bug in a
## milder form (the heading is already easing back as the push starts), so the honest before/after
## comparison is the one tabulated above.
##
## WHY THE FALLBACK STAYS, and why it is gated on the rig owning the ACTIVE camera. Two showcases
## (`jetpack_showcase --chase/--side`, and anything else that makes its own Camera3D current) rely
## on movement being relative to the camera the viewer is actually looking through — the jetpack
## chase camera comment spells that out. Asking a rig that is not on screen would silently change
## what "forward" means in those scenes. So: rig's heading when the rig's camera is the one
## rendering, otherwise exactly the old behaviour.
func _camera_planar_forward() -> Vector3:
	var cam := get_viewport().get_camera_3d()
	var rig := _camera_rig()
	if rig != null and cam != null and rig.get_camera() == cam:
		var rf: Vector3 = rig.get_planar_forward()
		rf -= up * rf.dot(up)
		if rf.length_squared() > 0.0001:
			return rf.normalized()
	var fwd: Vector3
	if cam:
		fwd = -cam.global_transform.basis.z
		fwd -= up * fwd.dot(up)
		if fwd.length_squared() < 0.0004:
			fwd = -cam.global_transform.basis.y
			fwd -= up * fwd.dot(up)
	else:
		fwd = surface_forward()
	if fwd.length_squared() < 0.0001:
		return surface_forward()
	return fwd.normalized()


# ============================================================================= jetpack
## Decides whether the thruster is lit this frame, burns / refills fuel, and drives the spool ramp,
## the looping sound and the model's plume. Called before movement so `_boosting` can raise the
## horizontal speed cap and the air control in the same tick.
func _update_boost_state(delta: float, held: bool, on_floor: bool) -> void:
	if on_floor:
		_grounded_time += delta
	else:
		_grounded_time = 0.0
	_boost_hold = _boost_hold + delta if held else 0.0

	var want := held and _emote == "" and _jump_anticipation < 0.0
	# From the ground, the button has to be HELD past BOOST_GROUND_DELAY: boost shares the space bar
	# with jump, and a tap must stay a plain jump. Airborne there is no delay, so holding through a
	# jump lights the thruster the moment the feet leave the floor.
	if want and on_floor and _boost_hold < BOOST_GROUND_DELAY:
		want = false
	# Fuel: an empty tank has to recover past BOOST_RESTART_FUEL before it will light again, so a
	# dry jetpack cannot be stuttered for free lift.
	if want and _boost_fuel <= (BOOST_RESTART_FUEL if not _boosting else 0.0):
		want = false
	# Hard ceiling. Two of them: no thrust above BOOST_MAX_HEIGHT, and a full cancel above
	# BOOST_ABORT_HEIGHT, so nothing can walk the player off the top of the world.
	if want and _ground_height > BOOST_ABORT_HEIGHT:
		want = false

	# Climb / float latch. Set once the astronaut tops out, cleared again if they sink back toward
	# the ground, and always cleared when the boost ends.
	if not want:
		_boost_floating = false
	elif _ground_height >= BOOST_CLIMB_HEIGHT:
		_boost_floating = true
	elif _ground_height <= BOOST_FLOAT_EXIT:
		_boost_floating = false

	if want:
		_boost_fuel = maxf(_boost_fuel - delta / BOOST_BURN_TIME, 0.0)
		if not _boosting:
			_model.set_state("boost")
	elif on_floor and _grounded_time >= BOOST_REFILL_DELAY:
		_boost_fuel = minf(_boost_fuel + delta / BOOST_REFILL_TIME, 1.0)
	_boosting = want

	var spool := BOOST_SPOOL_UP if want else BOOST_SPOOL_DOWN
	_boost_thrust = lerpf(_boost_thrust, 1.0 if want else 0.0, 1.0 - exp(-spool * delta))
	if _boost_thrust < 0.02 and not want:
		_boost_thrust = 0.0
	_update_boost_loop()


## The thrust itself: nudges the RADIAL velocity toward a target and leaves everything else alone.
## Below BOOST_CLIMB_HEIGHT that target is a climb; above it, a slow float down — which is the
## "go higher, then float a bit toward the ground while moving" of R2.8.
func _apply_boost_thrust(delta: float) -> void:
	if not _boosting:
		return
	if _ground_height > BOOST_MAX_HEIGHT:
		return
	var radial := velocity.dot(up)
	var climbing := not _boost_floating
	var target := BOOST_RISE_SPEED if climbing else -BOOST_FALL_SPEED
	var rate := BOOST_RISE_ACCEL if climbing else BOOST_FALL_ACCEL
	# move_toward, never assignment: the thruster accelerates you, it does not teleport your speed,
	# so a boost caught mid-fall still has to arrest the fall first.
	velocity += up * (move_toward(radial, target, rate * delta) - radial)


## Soft looping thruster while the boost is held (R2.8). AudioManager owns the player, so a modal
## opening mid-flight silences it through the same path as letting go of the button.
func _update_boost_loop() -> void:
	if _boost_loop_sfx == "":
		return
	var want := _boost_thrust > 0.12
	if want == _boost_loop_on:
		return
	_boost_loop_on = want
	if want:
		var p := AudioManager.start_loop(_boost_loop_sfx, BOOST_LOOP_DB, 0.12)
		# A jetpack is a smaller, tighter thruster than the rocket: pitching the loop up keeps the
		# two readable as different machines even when they share a sample.
		if p:
			p.pitch_scale = 1.32
	else:
		AudioManager.stop_loop(_boost_loop_sfx, 0.22)


## 0 (empty) .. 1 (full). The HUD reads this for the fuel pill.
func get_boost_fuel() -> float:
	return _boost_fuel


func is_boosting() -> bool:
	return _boosting


func _launch_jump() -> void:
	_jump_anticipation = -1.0
	do_jump(JUMP_VELOCITY)
	_jumping = true
	_jump_cut_done = false
	_was_on_floor = false
	if _has_jump_sfx:
		AudioManager.play_sfx("jump", -4.0)


## True while the astronaut counts as "on the ground" for ANIMATION purposes: really on the floor,
## or off it so briefly that it is a stride skipping a bump rather than a fall. A deliberate jump
## never qualifies. See AIR_ANIM_GRACE.
func _grounded_enough() -> bool:
	return not _jumping and not _boosting and _air_time < AIR_ANIM_GRACE


## `airtime` is how long the feet were off the ground. A sprint clips the ground constantly, and
## firing the full landing every time gave a dust burst and a landing thud several times a second
## on flat ground - so a landing that short is swallowed entirely. A real jump always lands.
func _on_land(airtime: float) -> void:
	var was_real := _jumping or airtime >= LAND_MIN_AIRTIME
	_jumping = false
	if not was_real:
		return
	_land_timer = LAND_TIME
	_model.set_state("land")
	_dust_land.restart()
	_dust_land.emitting = true
	if _has_land_sfx:
		AudioManager.play_sfx("land", -6.0)
	elif not _footstep_sfx.is_empty():
		AudioManager.play_sfx(_footstep_sfx[0], -4.0, 0.1)


func _select_state(on_floor: bool, speed: float) -> void:
	if _emote != "":
		return
	if _jump_anticipation >= 0.0:
		return
	var carrying := _carry_id != ""
	if _boosting:
		# The boost pose outranks jump and fall: while the thruster is lit the astronaut is not
		# rising or falling, it is flying, and R2.8 wants that readable in silhouette.
		_model.set_state("boost")
		return
	# A stride that skips a bump is not a fall (AIR_ANIM_GRACE). Only commit to an airborne pose
	# once the astronaut has actually been off the ground for a moment, or jumped on purpose.
	if not on_floor and not _grounded_enough():
		var radial := velocity.dot(up)
		if radial > 0.3 or (_jumping and radial > -1.0):
			_model.set_state("jump")
		else:
			_model.set_state("fall")
		return
	if _land_timer > 0.0:
		_model.set_state("land")
		return
	if speed > 0.35:
		if carrying:
			_model.set_state("carry_walk")
		elif speed > WALK_SPEED + 0.6:
			_model.set_state("run")
		else:
			_model.set_state("walk")
	else:
		if _talking:
			_model.set_state("talk")
		elif carrying:
			_model.set_state("carry_idle")
		else:
			_model.set_state("idle")


func _cancel_emote() -> void:
	_emote = ""
	_emote_deadline = 0.0
	_release_emote_camera()


func _on_emote_finished(_emote_name: String) -> void:
	_emote = ""
	_emote_deadline = 0.0
	_release_emote_camera()


func _release_emote_camera() -> void:
	var rig := _camera_rig()
	if rig:
		rig.release_orbit()


## The rig is a sibling of the player under World (docs/ARCHITECTURE.md 3), with a fallback search
## so a showcase that parents things differently still finds it. Cached; re-resolved if it dies.
func _camera_rig() -> CameraRig:
	if _rig != null and is_instance_valid(_rig):
		return _rig
	var parent := get_parent()
	if parent:
		var sib := parent.get_node_or_null("CameraRig")
		if sib is CameraRig:
			_rig = sib as CameraRig
			return _rig
	var cam := get_viewport().get_camera_3d()
	if cam and cam.get_parent() is CameraRig:
		_rig = cam.get_parent() as CameraRig
	return _rig


func _on_footstep(_foot: int) -> void:
	if not is_on_floor() or _footstep_sfx.is_empty():
		return
	AudioManager.play_sfx(_footstep_sfx[_footstep_alt % _footstep_sfx.size()], -8.0 if _speed_factor < 1.2 else -5.0, 0.08)
	_footstep_alt += 1


# ============================================================================= interaction
func _update_interact_target() -> void:
	var best: Interactable = null
	var best_d := INF
	var feet := global_position
	var facing := surface_forward()
	for n: Node in get_tree().get_nodes_in_group("interactables"):
		var it := n as Interactable
		if it == null or not it.enabled or not it.is_inside_tree():
			continue
		var to := it.global_position - feet
		var d := to.length()
		if d > it.reach:
			continue
		if it.require_facing:
			var t := to - up * to.dot(up)
			if t.length_squared() > 0.0001 and facing.dot(t.normalized()) <= 0.2:
				continue
		if d < best_d:
			best = it
			best_d = d
	if best == _target:
		return
	if _target and is_instance_valid(_target):
		_target.set_focused(false)
	_target = best
	if _target:
		_target.set_focused(true)
	interact_target_changed.emit(_target)
	EventBus.interact_prompt_changed.emit(_target.prompt_text if _target else "")


# ============================================================================= shadow / dust / sfx
func _build_shadow() -> void:
	_shadow = MeshInstance3D.new()
	_shadow.name = "BlobShadow"
	var quad := QuadMesh.new()
	quad.size = Vector2(1.0, 1.0)
	_shadow.mesh = quad
	_shadow_mat = ShaderMaterial.new()
	_shadow_mat.shader = load("res://src/player/blob_shadow.gdshader")
	_shadow_mat.set_shader_parameter("color", Color(0.12, 0.09, 0.28, 0.42))
	_shadow_mat.set_shader_parameter("softness", 0.6)
	_shadow.material_override = _shadow_mat
	_shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_shadow.top_level = true
	add_child(_shadow)


func _update_shadow() -> void:
	var space := get_world_3d().direct_space_state
	var from := global_position + up * 0.4
	# 12 m, not 6: the jetpack's ceiling sits at 4.6 m and this probe is what enforces it. A ray that
	# stops short would report "no ground", and a miss used to mean `_ground_height = 0`, i.e. "on
	# the floor" — which would have let the boost climb for ever off a cliff edge.
	var to := global_position - up * 12.0
	var q := PhysicsRayQueryParameters3D.create(from, to, 1)
	q.exclude = [get_rid()]
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		_shadow.visible = false
		# A miss means the ground is further than the probe reaches, so report it as HIGH. This is
		# the fail-safe direction: the jetpack refuses to thrust, gravity keeps working, and the
		# player falls back to the surface.
		_ground_height = 99.0
		return
	_shadow.visible = true
	var hp: Vector3 = hit["position"]
	var n: Vector3 = hit["normal"]
	if n.dot(up) < 0.2:
		n = up
	var h := maxf((global_position - hp).dot(up), 0.0)
	_ground_height = h
	var s := 1.0 / (1.0 + h * 0.3)
	# quad faces +Z locally; align +Z with the ground normal so it hugs slopes
	var fwd := -global_transform.basis.z
	var x := fwd.cross(n)
	if x.length_squared() < 0.0001:
		x = global_transform.basis.x
	x = x.normalized()
	var y := n.cross(x).normalized()
	_shadow.global_transform = Transform3D(Basis(x * s, y * s, n), hp + n * 0.04)
	_shadow_mat.set_shader_parameter("strength", 1.0 / (1.0 + h * 0.9))


func _build_dust() -> void:
	_dust_land = _make_dust("DustLand", true, 16, 0.6, 0.11)
	add_child(_dust_land)
	# THE RUN DUST WAS HIDING THE RUN. It sat 0.20 m behind the astronaut and blew UPWARD
	# (direction 0,1,0.35 at 1.3-2.6 m/s), which puts a bright cream cloud at shin-to-knee height
	# directly on the line between the follow camera and the boots — see
	# ~/.astro_captures/strips/before_run.png, where the legs are simply gone behind it in half the
	# frames. The player's complaint was that the run looks strange, and part of the run was
	# literally not visible. Same puff language, but pushed further back, kept LOW and thrown
	# backward rather than up, so at the 28 deg camera it trails below the boots instead of over
	# them. Slightly fewer and smaller too; the cue never needed to be this big.
	_dust_run = _make_dust("DustRun", false, 7, 0.42, 0.038, 0.32)
	_dust_run.position = Vector3(0.0, 0.02, 0.44)
	var rpm := _dust_run.process_material as ParticleProcessMaterial
	if rpm:
		rpm.direction = Vector3(0.0, 0.28, 1.0)
		rpm.spread = 32.0
		rpm.initial_velocity_min = 0.7
		rpm.initial_velocity_max = 1.7
	add_child(_dust_run)


func _make_dust(n: String, one_shot: bool, amount: int, life: float, size: float, alpha: float = -1.0) -> GPUParticles3D:
	var gp := GPUParticles3D.new()
	gp.name = n
	gp.emitting = false
	gp.one_shot = one_shot
	gp.amount = amount
	gp.lifetime = life
	gp.explosiveness = 1.0 if one_shot else 0.0
	gp.local_coords = false
	gp.position = Vector3(0.0, 0.06, 0.0)
	gp.visibility_aabb = AABB(Vector3(-3, -3, -3), Vector3(6, 6, 6))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.22 if one_shot else 0.18
	pm.direction = Vector3(0.0, 1.0, 0.35)
	pm.spread = 80.0 if one_shot else 60.0
	pm.initial_velocity_min = 1.3 if one_shot else 0.3
	pm.initial_velocity_max = 2.6 if one_shot else 0.9
	pm.gravity = Vector3.ZERO
	pm.damping_min = 4.0
	pm.damping_max = 6.0
	var sc := Curve.new()
	sc.add_point(Vector2(0.0, 0.5))
	sc.add_point(Vector2(0.3, 1.0))
	sc.add_point(Vector2(1.0, 0.0))
	var sct := CurveTexture.new()
	sct.curve = sc
	pm.scale_curve = sct
	pm.scale_min = 0.7
	pm.scale_max = 1.3
	var grad := Gradient.new()
	var a0 := alpha if alpha >= 0.0 else (0.85 if one_shot else 0.55)
	grad.set_color(0, Color(0.96, 0.92, 0.80, a0))
	grad.set_color(1, Color(0.96, 0.92, 0.80, 0.0))
	var gt := GradientTexture1D.new()
	gt.gradient = grad
	pm.color_ramp = gt
	gp.process_material = pm
	var mesh := SphereMesh.new()
	mesh.radius = size
	mesh.height = size * 2.0
	mesh.radial_segments = 10
	mesh.rings = 5
	var mat := MaterialLib.flat_unlit(Color(0.96, 0.92, 0.80, 0.8)).duplicate() as StandardMaterial3D
	mat.vertex_color_use_as_albedo = true
	mesh.material = mat
	gp.draw_pass_1 = mesh
	return gp


func _resolve_sfx() -> void:
	for cand: String in FOOTSTEP_CANDIDATES:
		if _sfx_exists(cand):
			_footstep_sfx.append(cand)
		if _footstep_sfx.size() >= 2:
			break
	_has_jump_sfx = _sfx_exists("jump")
	_has_land_sfx = _sfx_exists("land")
	for cand: String in BOOST_LOOP_CANDIDATES:
		if _sfx_exists(cand):
			_boost_loop_sfx = cand
			break
	if _boost_loop_sfx == "":
		push_warning("Player: no jetpack thruster loop found (tried %s); the boost will be silent." % str(BOOST_LOOP_CANDIDATES))


static func _sfx_exists(n: String) -> bool:
	return ResourceLoader.exists(AudioManager.SFX_DIR + n + ".wav") or ResourceLoader.exists(AudioManager.SFX_DIR + n + ".ogg")
