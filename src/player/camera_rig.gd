class_name CameraRig
extends Node3D
## ACNH-style third-person camera that follows the player around the sphere.
## Lives at /root/World/CameraRig. Finds the player via group "player" (or EventBus.player_spawned).
##
## Orientation is kept as a tangent "forward" vector that is parallel-transported as the player's
## up vector changes, so walking over the poles never flips or jitters. Player movement never
## rotates the camera; only the mouse / camera_left-right-up-down do (plus a slow auto-recenter
## while walking).
## Public: get_camera(), focus_on(pos, duration), release_focus(), orbit_front(), release_orbit().
## Touch front end (see the "external look / zoom" block): add_look(), add_look_px(), add_zoom(),
## set_zoom_distance(), get_zoom_distance(), get_zoom_range(), get_zoom_fraction().
## It also fades out any decoration standing between the camera and the astronaut, so hub props can
## never hide the player - see the near-geometry fade block below.

const PIVOT_HEIGHT := 1.0
const YAW_SPEED_DEG := 120.0

# ============================================================================= framing, per platform
## R2.10, the user: *"I'd prefer to play the game in horizontal view, not have the UI taking too much
## space on the screen. We should zoom out the camera a bit more but not so much that we cant
## appreciate the decor and details."*
##
## The second half of that sentence is the hard limit, so this is not "as far back as it will go".
## The decision frame is ~/.astro_captures/cmp/mobile_orientation.png: at 6.5 m a plaza lamp post and
## a bunting pole between the camera and the astronaut each cover a big slice of the frame, because a
## 0.45 m globe 2 m from the lens is enormous while the same globe 4 m away is a detail. Distance is
## the fix - the fade below can only ghost an occluder, it cannot make the plaza legible.
##
## DESKTOP 7.4 m. Measured by looking (see the report's dist ladder, 6.5 / 7.0 / 7.4 / 8.0): 7.4 is
## where the house, the path and both flanking trees fit on a 16:9 frame while a moon lamp beside the
## astronaut is still an object with a shape rather than a blob. 8.0 starts costing the lamp.
##
## MOBILE 8.6 m and 34 deg. A phone is not a small monitor - it is the same pixel count at a third of
## the angular size, and both bottom corners are under a thumb, so the useful frame is the middle
## band. More distance puts the world in that band; the extra pitch tips the ground plane up into it,
## which is what the player decorates on. It is a separate CONSTANT SET, not a compromise value:
## `Platform.is_mobile()` picks one at `_ready` and `Platform.mode_changed` re-applies on a runtime
## switch, so neither front end has to live with the other's framing.
##
## The zoom RANGE moves with the default and keeps roughly the same span in both directions, so the
## close end still gets the player nose-to-nose with a decoration they are placing.
const PITCH_DEFAULT_DEG := 28.0
const DIST_DEFAULT := 7.4
const DIST_MIN := 4.4
const DIST_MAX := 11.4

const MOBILE_PITCH_DEFAULT_DEG := 34.0
const MOBILE_DIST_DEFAULT := 8.6
const MOBILE_DIST_MIN := 5.0
const MOBILE_DIST_MAX := 13.0

## The player, after playing the build: *"I can't control the camera well I dont think, so sometimes
## i cant see what im trying to interact with"*. Part of that was the missing mouse look (below);
## part was this range. 15 deg is not low enough to look level along the ground at something a few
## metres ahead (a shop sign, an NPC on a rise), and 60 deg is not high enough to look down at a
## collectible or a placed decoration right at your boots. Widened at both ends; the default and the
## framing at the default are untouched.
const PITCH_MIN_DEG := 6.0
const PITCH_MAX_DEG := 72.0
const PITCH_SPEED_DEG := 60.0
const ZOOM_STEP := 1.0
const POS_SMOOTH := 8.0
const ROT_SMOOTH := 6.0
const RECENTER_DELAY := 1.5
const RECENTER_RATE := 0.9
const TERRAIN_MARGIN := 0.35
const FOCUS_PUSH_IN := 0.78

# ============================================================================= spring-arm lift
## THE OTHER HALF OF *"sometimes i cant see what im trying to interact with"*, and it is not a mouse
## problem. Stand at the mailbox, the house door, a shop front - anywhere the astronaut has their
## back to a wall - and the spring arm has nowhere to go but straight in, down to its 0.8 m floor.
## At 0.8 m the back of the helmet fills the screen and the thing being interacted with is off
## frame entirely, prompt and all: see /tmp/reachhome/mailbox_1_arrive.png (a white wall and no
## mailbox) and mailbox_3_orbit90.png (inside the astronaut's head) in the report.
##
## A real third-person camera does not only push IN when it is blocked - it climbs OVER. Before
## shortening the arm at all, the rig now tries raising the camera's elevation in steps, keeping the
## full 6.5 m, and takes the lowest lift that gives a clear line to the astronaut. Looking down over
## a roof frames both the player AND what they are standing at; jammed against the wall frames
## neither. Shortening is kept as the last resort, for the case where lifting cannot clear either.
##
## The lift is a smoothed ANGLE, not a smoothed position: a raw "blocked / not blocked" test flips
## between frames as the player shuffles, and applying its result straight to the camera position
## would pop. Moving the angle toward its target at a fixed rate makes engaging and releasing a
## short camera move instead.
const LIFT_MAX_DEG := 38.0
const LIFT_STEPS := 5
const LIFT_RATE := 3.2

# ============================================================================= near-geometry fade
## The integration critic, BLOCKING: *"The camera has no near-geometry fade, so hub props routinely
## hide the player. On the hub the lamp-post globes and potted bushes sit in the spring-arm's path
## and fill 15-25% of the frame; in several captures the astronaut is completely hidden behind a
## bush while standing at a shop door."* `_avoid_terrain` below only ever knew about layer 1.
##
## WHY FADE AND NOT A LONGER SPRING ARM. Pulling the camera in is the right answer for terrain: the
## ground is one continuous surface, the pull is smooth, and there is nowhere else to stand. It is
## the wrong answer for hub props. The plaza has a lamp post or a planter every few metres, so a
## spring arm that respected them would slam the camera from 6.5 m to 1.5 m and back several times
## per walk — the exact "camera jitter" the feel checklist forbids — and a bush is 0.8 m wide, so
## 95 % of the time the fix costs the player their whole framing to solve 5 % of an occlusion.
## Fading the handful of objects actually between the camera and the astronaut costs nothing else
## on screen and is what Animal Crossing itself does with foreground trees.
##
## DECORATIONS FADE, BUILDINGS PUSH. Layer 4 (decoration: hub props, planet trees and rocks, and
## everything the player places) is what fades. Buildings (layer 7) were tried in the same set and
## looked wrong: a shop is a hollow box, so fading one shows its counter, its stock and its far wall
## ghosting through the near wall - transparency sorting noise across a quarter of the frame, to
## solve an occlusion that only happens when the camera is inside the wall anyway. Buildings joined
## the SPRING ARM instead (see AVOID_MASK), which is the right tool for large solid volumes: the
## camera slides in front of the wall and everything stays opaque.
const OCCLUDER_MASK := 1 << 3
## What the spring arm pulls the camera in front of: terrain and buildings.
const AVOID_MASK := 1 | (1 << 6)
## How transparent an occluder goes. Not 1.0: a prop that vanishes entirely reads as a pop-out bug,
## and a ghost still tells the player there is a lamp post there. But not 0.80 either, which is
## where this started: a topiary is two or three leaf tiers plus a pot, and 20 % opacity per layer
## stacks to nearly half coverage over the astronaut behind it. 0.90 measured clean through the
## worst case in the plaza (see the before/after pair in the report) and still leaves a visible ghost.
const FADE_TO := 0.90
## Fade in fast enough that the player is never hidden for long, out slowly so a prop the camera
## brushes past does not strobe.
const FADE_IN_RATE := 7.0
const FADE_OUT_RATE := 3.2
## Seconds between sight-line probes. The fade itself runs every frame; only the probes are rate
## limited, and 12 Hz is far faster than a prop can cross the arm.
const PROBE_INTERVAL := 0.08
## Heights above the player's feet that must stay visible: boots, chest, and the top of the helmet.
## Probing the pivot alone missed the bush in ~/.astro_captures/integ08/13_clothes_shop.png, which
## covered the body while leaving the pivot ray clear.
const SIGHT_HEIGHTS: Array[float] = [0.25, 0.85, 1.45]
## THE SIGHT LINE HAS WIDTH, and it has to. This started as three infinitely thin rays to the
## astronaut's centre line, and the mobile decision mockup
## (~/.astro_captures/cmp/mobile_orientation.png) shows what that misses: a plaza lamp POLE standing
## a fifth of a metre to one side of the centre line covers half the visor on screen and never
## touches a centre ray, so it never faded. Reproduced at the new distance in
## ~/.astro_captures/occ_desk/09_orbited.png - the pole runs straight through the astronaut's face
## with `--fade-debug` printing an empty fade set.
##
## So each sight line is now a swept CAPSULE of this radius rather than a ray: "is any prop within
## 0.34 m of the line from the lens to this point on the astronaut", which is the question the fade
## was always trying to ask. 0.34 m is the helmet's own half-width (astronaut_model.HELMET_R.x =
## 0.372), so the probe is as wide as the thing it is protecting and no wider. One shape query per
## height replaces a chain of up to MAX_OCCLUDER_DEPTH rays and returns every occluder at once
## instead of walking them one hit at a time, so this is also the cheaper of the two.
##
## A cylinder rather than a cone (which is what the astronaut's silhouette from the lens actually
## sweeps) deliberately over-selects at the CAMERA end. That is the right way to be wrong: a prop
## within 0.34 m of the lens fills a huge part of the frame whether or not it is geometrically over
## the player.
##
## `--fade-thin` (after "--") shrinks the probe back to the old thin ray, so the before/after pair
## for this fix can be re-captured from one timeline whenever a critic wants to see it.
const SIGHT_RADIUS := 0.34
## Ceiling on how many occluders one sight line may return. A bush in front of a fence in front of a
## shop wall is three; the plaza's worst case measured six.
const MAX_OCCLUDER_DEPTH := 12
## Occluders nearer the player than this are ignored: a prop the astronaut is standing right next to
## is not what is hiding them, and fading it would flicker as they brush past. Applied by stopping
## the capsule short of the player rather than by testing each hit's distance.
const OCCLUDER_MIN_DIST := 0.6

# ============================================================================= mouse look
## THE PLAYER'S NUMBER ONE COMPLAINT: *"I can't control the camera well I dont think, so sometimes i
## cant see what im trying to interact with"*. The cause was not subtle - there was **no mouse
## control at all**. `camera_left/right` were bound to the J and L keys and the gamepad right stick,
## `camera_up/down` to the gamepad stick ONLY, and nothing in this file or `player.gd` ever read an
## `InputEventMouseMotion` or set `Input.mouse_mode`. On a keyboard-and-mouse setup that leaves the
## player with one dead key (J is also the journal hotkey, so it opens the log instead of panning),
## one working key (L), and no pitch control whatsoever.
##
## So: standard third-person mouse look. The cursor is CAPTURED during gameplay, the raw relative
## motion orbits the yaw and tilts the pitch, and the capture is dropped whenever the player is not
## actually playing - any modal UI, a cutscene (the rocket sets `Player.input_enabled = false`), a
## paused tree, or an explicit `ui_cancel`. Left-click takes it back.
##
## COEXISTENCE. Both schemes write the same `_fwd` / `_pitch` through `_handle_input`, once per
## frame, additively - the mouse contributes a per-frame pixel delta, the keys and the stick a
## per-frame rate. Neither latches anything, so holding L while moving the mouse simply sums, and
## a gamepad player never sees the mouse path run because the cursor is only captured on a real
## windowed session (see `_mouse_blocked` / `_grab_cursor`).
##
## Degrees of orbit per pixel of motion at sensitivity 1.0. Yaw is the faster axis because the yaw
## range is unlimited while the pitch is clamped to PITCH_MIN..MAX (66 deg total): at 0.10 the full
## tilt range is a 660 px drag, which is about one comfortable wrist sweep.
const MOUSE_YAW_DEG_PER_PX := 0.16
const MOUSE_PITCH_DEG_PER_PX := 0.10
## Guard against a single monstrous relative value after a window focus change or a mode switch,
## which would otherwise spin the camera through several turns in one frame.
const MOUSE_MAX_PX_PER_FRAME := 400.0

# ================================================================= external look / zoom (touch API)
## The mobile front end lives in `src/ui/**` and is forbidden from touching this folder, so it drives
## the camera through `add_look` / `add_look_px` / `add_zoom` instead of reaching into the rig. Those
## calls do NOT move anything themselves: they add into the two accumulators below, which
## `_handle_input` drains once per frame alongside the mouse and the stick. That is deliberate - it
## is the same "one place where every camera scheme lands" rule the mouse follows, so a UI node that
## calls add_look every frame of a drag can never fight the recentre, the emote orbit or the stick
## over `_fwd`, and a modal that opens mid-drag drops the leftovers instead of flinging the camera.
##
## The same per-frame guard the mouse uses, so a touch front end that hands over one absurd delta
## (a finger teleporting across the screen when a second finger lands) cannot spin the camera.
const EXT_LOOK_MAX_DEG_PER_FRAME := 90.0
## Ceiling on one frame's pinch, for the same reason.
const EXT_ZOOM_MAX_M_PER_FRAME := 4.0

# ============================================================================= emote orbit
## How far off dead-front the emote orbit settles, in degrees (see `orbit_front`).
const ORBIT_YAW_DEG := 26.0
## Distance and pitch the orbit blends toward: a little closer and a little lower than the follow
## camera, because the poses live in the arms and the chest, not on top of the helmet.
const ORBIT_PUSH_IN := 0.86
const ORBIT_PITCH_DEG := 19.0
## How fast the heading chases the front target while the orbit is engaged.
const ORBIT_TURN_RATE := 3.4
## How long after `reseat_behind_player` the emote orbit is refused, in seconds — the BACKSTOP; the
## normal exit is the player's first real movement input, see `_consume_orbit_grace`. 3.5 s brackets
## the arrival emote's whole life (it is requested 0.35 s after control returns and holds the camera
## for about 2.2 s more) plus a margin, and it is short enough that an emote the player themselves
## asks for while standing by the pad still gets its framing.
##
## It is no longer load-bearing. It used to be the only thing standing between the player and a
## control basis 154 deg out; now that `get_planar_forward` resolves movement against the player's
## own heading, the worst an expired or mistuned grace can cost is an arrival hop framed from behind.
const LANDING_ORBIT_GRACE := 3.5
## How far the stick has to be pushed to count as the player taking control and end the grace early
## (see `_consume_orbit_grace`). 0.2 of full deflection, comfortably above a resting thumb — the
## mobile stick reports 0.00 untouched, and `Input.get_vector` has already applied the action
## deadzone by the time we see it — and comfortably below anything a player means as "walk".
const GRACE_RELEASE_PUSH := 0.2

var _player: PlanetBody
var _camera: Camera3D
var _up: Vector3 = Vector3.UP
var _fwd: Vector3 = Vector3.FORWARD
var _pitch: float = deg_to_rad(PITCH_DEFAULT_DEG)
var _dist_target: float = DIST_DEFAULT
var _dist: float = DIST_DEFAULT
## True once the player has moved the zoom / the pitch off this platform's default. A runtime
## `Platform.mode_changed` re-applies the new mode's default to whichever of the two the player has
## NOT touched, and only re-maps (by fraction) / re-clamps the one they have - switching layouts
## should hand you the new layout's framing, not silently undo a choice you made.
var _zoom_user_set := false
var _pitch_user_set := false
## The zoom range that `_dist_target` was last clamped against, so a mode switch can work out where
## in the OLD range the player had parked the camera before the new stops replace it.
var _prev_dist_min: float = DIST_MIN
var _prev_dist_max: float = DIST_MAX
var _zoom_tween: Tween
var _moving_time: float = 0.0
var _initialized := false
## Standpoint remembered by `debug_mark` and reported by `debug_travel` (the stuck-after-landing
## measurement). Diagnostic only — nothing in the running game reads these.
var _probe_mark_pos: Vector3 = Vector3.ZERO
var _probe_mark_fwd: Vector3 = Vector3.FORWARD
var _probe_mark_head: Vector3 = Vector3.FORWARD
var _focus_pos: Vector3 = Vector3.ZERO
var _focus_weight: float = 0.0
var _focus_tween: Tween
var _orbit_weight: float = 0.0
var _orbit_tween: Tween
var _fwd_saved: Vector3 = Vector3.FORWARD
var _has_saved_fwd := false
var _restoring_fwd := false
## Wall-clock deadline (ms, `Time.get_ticks_msec`) before which `orbit_front` refuses to engage.
## Armed by `reseat_behind_player`. A monotonic clock and not a `delta` countdown on purpose: the
## landing hands control back around a cutscene and a modal, and a paused tree stops feeding
## `_process` — a countdown would sit frozen and then fire the grace long after the player was
## walking. `--no-orbit-grace` disables the refusal so the swing can be re-measured on demand.
var _orbit_grace_until_ms: int = 0
var _orbit_grace_off := false
## `--no-control-basis` puts `get_planar_forward` back on the raw camera heading, i.e. re-arms the
## emote-camera steering bug on purpose. Same reason `--no-orbit-grace` and `--no-reseat` exist: a
## fix whose "before" arm cannot be re-run is a fix nobody can re-check. Never set in normal play.
var _control_basis_off := false
var _smoothed_pos: Vector3 = Vector3.ZERO
var _smoothed_quat: Quaternion = Quaternion.IDENTITY
## instance id -> {"meshes": Array[GeometryInstance3D], "t": float, "want": float}. `t` is the
## current fade, `want` what the last probe asked for.
var _faded: Dictionary = {}
var _probe_timer: float = 0.0
## The swept sight-line volume and its query, built once and re-aimed per probe rather than
## reallocated - the probe runs 12 times a second for the whole session.
var _sight_capsule: CapsuleShape3D
var _sight_query: PhysicsShapeQueryParameters3D
## Current extra elevation the spring arm is holding to see over an obstacle, in radians. Smoothed
## (see the LIFT_* block) so engaging and releasing it is a camera move, not a pop.
var _lift: float = 0.0
## `--fade-debug` (after "--") prints the fade set whenever it changes. Off in normal play; it is
## the only way to prove from a capture run that the right prop faded and not merely that the
## astronaut happened to be visible.
var _fade_debug := false
var _fade_debug_last := ""
## `--fade-off` keeps the whole probe running but stops applying the transparency, so the same
## timeline can be captured with and without the fix for a before/after pair.
var _fade_off := false
## `--fade-thin` shrinks the sight-line probe back to the infinitely thin centre-line ray it used to
## be (see SIGHT_RADIUS). Same purpose as `--fade-off`: it is what lets the "a lamp pole beside the
## centre line never faded" before/after pair be re-captured from one timeline at any time, instead
## of being a claim about a build that no longer exists.
var _probe_radius := SIGHT_RADIUS

# ---- mouse look
## Unconsumed mouse motion in pixels, accumulated by `_unhandled_input` and drained once per frame
## by `_handle_input`.
var _mouse_dx: float = 0.0
var _mouse_dy: float = 0.0
## Logical state: true while mouse motion is allowed to move the camera. Kept separately from the
## OS cursor mode so a Director run can exercise the real input path without grabbing the cursor.
var _mouse_look := false
## True when `_mouse_look` should also be mirrored onto the real OS cursor. False headless, and
## false under the Director, so an automated capture never steals the mouse from whoever is at the
## machine (and a stray hand on the desk cannot corrupt a 350-frame capture).
var _grab_cursor := true
## `--no-mouse-look` (after "--") disables the whole path; the Director implies it unless
## `--mouse-look-test` is also given, which is how tests/director/player_mouse_look.json runs.
var _mouse_blocked := false
## The player pressed ui_cancel to get the cursor back. Sticky until they click in the window again,
## so a modal opening and closing does not silently re-grab it.
var _mouse_freed_by_player := false
## `--mouse-look-test`: arms mouse look under the Director (which otherwise implies --no-mouse-look)
## and prints every capture-state change, which is the only way a headless run can assert that a
## modal or an Esc actually took the camera away from the mouse.
var _mouse_test := false
## Set when a zoom action arrived as a real InputEvent, and consumed by the next `_handle_input`, so
## a single wheel notch cannot be counted twice (once by the event and once by the poll). A latch
## rather than a frame-number comparison: input is flushed before `_process` every frame, so the
## handshake holds without depending on when Engine.get_process_frames() ticks.
var _zoom_from_event := false

# ---- external look / zoom (the touch front end; see the block above)
## Degrees of yaw / pitch handed over since the last drain. Raw: sensitivity, invert and the clamp
## are applied in `_handle_input` with everything else.
var _ext_look := Vector2.ZERO
## Metres of zoom handed over since the last drain. Positive pulls the camera back.
var _ext_zoom: float = 0.0



func _ready() -> void:
	var argv := OS.get_cmdline_user_args()
	_camera = get_node_or_null("Camera3D") as Camera3D
	if _camera == null:
		_camera = Camera3D.new()
		_camera.name = "Camera3D"
		add_child(_camera)
	_camera.fov = 45.0
	_camera.near = 0.1
	_camera.far = 300.0
	_camera.current = true
	_apply_platform_framing(true)
	Platform.mode_changed.connect(_on_platform_mode_changed)
	if argv.has("--fade-thin"):
		_probe_radius = 0.005
	_sight_capsule = CapsuleShape3D.new()
	_sight_capsule.radius = _probe_radius
	_sight_capsule.height = 2.0 * _probe_radius
	_sight_query = PhysicsShapeQueryParameters3D.new()
	_sight_query.shape = _sight_capsule
	_sight_query.collision_mask = OCCLUDER_MASK
	_sight_query.collide_with_areas = false
	_sight_query.collide_with_bodies = true
	var p := get_tree().get_first_node_in_group("player")
	if p is PlanetBody:
		_bind_player(p as PlanetBody)
	EventBus.player_spawned.connect(_on_player_spawned)
	_fade_debug = argv.has("--fade-debug")
	_fade_off = argv.has("--fade-off")
	_orbit_grace_off = argv.has("--no-orbit-grace")
	_control_basis_off = argv.has("--no-control-basis")
	_mouse_test = argv.has("--mouse-look-test")
	_mouse_blocked = argv.has("--no-mouse-look") or (Director.is_active() and not _mouse_test)
	# Never grab the cursor on the web or on a touch device. Pointer lock throws
	# `WrongDocumentError: The root document of this element is not valid for pointer lock`
	# in a browser (found by actually running the HTML5 build), and on mobile there is no
	# cursor to capture - grabbing it there also fights the touch controls' own fallback.
	_grab_cursor = (not _mouse_blocked
		and not Director.is_active()
		and DisplayServer.get_name() != "headless"
		and not OS.has_feature("web")
		and not Platform.is_mobile())
	EventBus.ui_modal_opened.connect(_on_modal_changed)
	EventBus.ui_modal_closed.connect(_on_modal_changed)
	set_process_priority(10)
	_update_mouse_capture()


func _exit_tree() -> void:
	# The cursor mode is a global on DisplayServer, so it outlives this scene. Leaving the world
	# with it captured would hand the space map and the title screen an invisible mouse.
	if _grab_cursor and _mouse_look:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_mouse_look = false


func _on_player_spawned(p: Node3D) -> void:
	if p is PlanetBody:
		_bind_player(p as PlanetBody)


func _bind_player(p: PlanetBody) -> void:
	_player = p
	_initialized = false


# ============================================================================= framing, per platform
## This platform's default follow distance / zoom stops / resting pitch. Read through these, never
## the raw constants, so mobile and desktop cannot drift into one compromise number.
func dist_default() -> float:
	return MOBILE_DIST_DEFAULT if Platform.is_mobile() else DIST_DEFAULT


func dist_min() -> float:
	return MOBILE_DIST_MIN if Platform.is_mobile() else DIST_MIN


## Fraction of the planet's radius the eye may sit above the surface at full zoom-out. A fixed
## metre cap does not survive worlds of different sizes: at MOBILE_DIST_MAX 13 m on the 10.5 m
## Zorp and Bolt the whole limb fits in frame with sky on both sides and the astronaut becomes a
## speck. Home can also GROW to 18 m via GameState.home_planet_size, so the cap has to follow the
## world rather than be authored against one of them.
const DIST_MAX_RADIUS_FRAC := 0.75


func dist_max() -> float:
	var base: float = MOBILE_DIST_MAX if Platform.is_mobile() else DIST_MAX
	var p := _planet()
	if p != null and p.radius > 0.0:
		base = minf(base, p.radius * DIST_MAX_RADIUS_FRAC)
	return maxf(base, dist_min() + 1.0)


## The planet the player is standing on, or null before the world has assembled.
func _planet() -> Planet:
	var n := get_tree().get_first_node_in_group("planet")
	return n as Planet if n is Planet else null


func pitch_default_deg() -> float:
	return MOBILE_PITCH_DEFAULT_DEG if Platform.is_mobile() else PITCH_DEFAULT_DEG


## Puts the rig on this platform's framing. `initial` is the `_ready` case, where nothing the player
## chose exists yet and everything is simply set.
##
## On a runtime switch the rule is: whatever the player has NOT touched moves to the new mode's
## default; whatever they HAVE touched is carried across - the zoom by its position within the range
## (so "all the way in" stays all the way in), the pitch by value, re-clamped. Switching the layout
## should hand the player the new layout's framing without quietly discarding a deliberate choice.
func _apply_platform_framing(initial: bool) -> void:
	var lo := dist_min()
	var hi := dist_max()
	if initial:
		_dist_target = dist_default()
		_dist = _dist_target
		_pitch = deg_to_rad(pitch_default_deg())
		_prev_dist_min = lo
		_prev_dist_max = hi
		return
	if _zoom_tween:
		_zoom_tween.kill()
	if _zoom_user_set:
		# `_dist_target` is still in the OLD range here, so the fraction has to be taken against it.
		var frac := 0.5
		if _prev_dist_max - _prev_dist_min > 0.0001:
			frac = clampf((_dist_target - _prev_dist_min) / (_prev_dist_max - _prev_dist_min), 0.0, 1.0)
		_dist_target = lerpf(lo, hi, frac)
	else:
		_dist_target = dist_default()
	_dist = clampf(_dist, lo, hi)
	if not _pitch_user_set:
		_pitch = deg_to_rad(pitch_default_deg())
	_pitch = clampf(_pitch, deg_to_rad(PITCH_MIN_DEG), deg_to_rad(PITCH_MAX_DEG))
	# Ease rather than cut: a settings toggle that snapped the camera would read as a glitch.
	_zoom_tween = create_tween()
	_zoom_tween.tween_property(self, "_dist", _dist_target, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _on_platform_mode_changed(_mobile: bool) -> void:
	_apply_platform_framing(false)
	_prev_dist_min = dist_min()
	_prev_dist_max = dist_max()


## The active Camera3D.
func get_camera() -> Camera3D:
	return _camera


# ================================================================= external look / zoom (touch API)
## Orbits the camera by `delta_deg` DEGREES: x yaws (positive = the same direction a rightward mouse
## drag or `camera_right` turns it), y pitches (positive = the same direction a downward mouse drag
## tilts it, i.e. the camera climbs and the view looks further down).
##
## This is the touch front end's entry point for a look drag, and the ONLY thing it needs for
## camera control. Safe to call every frame, and safe to call with a zero delta. The rig applies
## `mouse_sensitivity`, `camera_invert_x` and `camera_invert_y` itself and clamps the pitch to
## PITCH_MIN_DEG..PITCH_MAX_DEG, so the caller must not pre-apply any of them. Deltas are summed
## until the next frame's drain, so several calls in one frame behave as one.
##
## Dropped while a modal is open or the player is frozen (a cutscene clears `Player.input_enabled`),
## which is the same gate mouse look uses - a drag started before a shop opened cannot leak through.
func add_look(delta_deg: Vector2) -> void:
	if not is_finite(delta_deg.x) or not is_finite(delta_deg.y):
		return
	# Clamped as it goes IN as well as on the way out, because the drain only runs while a player is
	# bound: a front end that keeps calling across a planet load would otherwise bank a whole scene
	# transition's worth of drag and spend it in one frame.
	_ext_look.x = clampf(_ext_look.x + delta_deg.x, -EXT_LOOK_MAX_DEG_PER_FRAME, EXT_LOOK_MAX_DEG_PER_FRAME)
	_ext_look.y = clampf(_ext_look.y + delta_deg.y, -EXT_LOOK_MAX_DEG_PER_FRAME, EXT_LOOK_MAX_DEG_PER_FRAME)


## The same thing in SCREEN PIXELS, converted with the constants mouse look uses
## (MOUSE_YAW_DEG_PER_PX / MOUSE_PITCH_DEG_PER_PX). Use this for a finger drag and a touch drag will
## feel like a mouse drag of the same length, including when the player has changed the sensitivity.
func add_look_px(delta_px: Vector2) -> void:
	add_look(Vector2(delta_px.x * MOUSE_YAW_DEG_PER_PX, delta_px.y * MOUSE_PITCH_DEG_PER_PX))


## Changes the follow distance by `delta_m` METRES. Positive pulls the camera back (fingers pinching
## together), negative pushes it in. Clamped to this platform's zoom range.
##
## Unlike the mouse wheel this does NOT tween: a pinch has to track the fingers, and a 0.35 s ease
## behind every frame's delta would feel like rubber. Safe to call every frame.
func add_zoom(delta_m: float) -> void:
	if not is_finite(delta_m):
		return
	_ext_zoom = clampf(_ext_zoom + delta_m, -EXT_ZOOM_MAX_M_PER_FRAME, EXT_ZOOM_MAX_M_PER_FRAME)


## Jumps the follow distance straight to `metres` (clamped to the platform range), tweening like the
## wheel does. For a zoom slider or a "reset view" button, not for a pinch - use `add_zoom` there.
func set_zoom_distance(metres: float) -> void:
	_set_zoom(metres)


## Current follow distance in metres (the target, not the smoothed value in flight).
func get_zoom_distance() -> float:
	return _dist_target


## This platform's zoom stops as (min, max), for a slider or a pinch that wants to scale by ratio.
func get_zoom_range() -> Vector2:
	return Vector2(dist_min(), dist_max())


## Where the zoom currently sits in its range: 0 fully in, 1 fully out. For a zoom indicator.
func get_zoom_fraction() -> float:
	var lo := dist_min()
	var hi := dist_max()
	if hi - lo < 0.0001:
		return 0.0
	return clampf((_dist_target - lo) / (hi - lo), 0.0, 1.0)


## False while the camera is deliberately not the player's to move (a modal, a cutscene, a pause).
## `add_look` / `add_zoom` already drop their input in that state; this is so a touch overlay can
## also HIDE itself rather than draw a dead control.
func is_look_input_allowed() -> bool:
	return not EventBus.is_modal_open() and _gameplay_active()


## Dollies to frame the player and `pos` together (dialogue framing). Blends in over `duration`.
func focus_on(pos: Vector3, duration: float = 0.6) -> void:
	_focus_pos = pos
	if not _has_saved_fwd:
		_fwd_saved = _fwd
		_has_saved_fwd = true
	_restoring_fwd = false
	if _focus_tween:
		_focus_tween.kill()
	_focus_tween = create_tween()
	_focus_tween.tween_property(self, "_focus_weight", 1.0, maxf(duration, 0.01)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


## Swings the camera round to a three-quarter FRONT view of the astronaut and holds it there.
##
## The integration critic: *"Emotes are only ever seen from behind. The follow camera never fronts
## the player, so the R2.4 run pose and every emote pose are invisible in normal play."* True and
## worth fixing — the wave, the happy hop, the dance and the think pose are all built in the arms
## and the chest, and the player was watching a backpack. `Player.play_emote` calls this, and
## `release_orbit` on the way out puts the heading back exactly where the player left it.
##
## Three-quarter, not dead front: a straight-on camera flattens the pose and hides the arm the
## character is waving, and swinging a full 180 degrees is twice the travel. ORBIT_YAW_DEG off the
## nose keeps the chest, both arms and the visor in frame, and reads as a camera move rather than a
## cut. Ignored while a dialogue focus is running — that framing is doing the same job already.
##
## WHAT THIS FUNCTION NO LONGER DOES, and it is the important part: it does not move the stick.
## Swinging the heading 154 deg off the astronaut's facing USED TO mean 154 deg of error in what
## "forward" meant, because `_fwd` was both the camera heading and the movement basis. Tap an emote,
## push the stick, walk sideways or backwards for about two seconds — measured independently at
## 151.7 deg peak on zorp and 148.6 deg on a cold start at home, and re-measured here at 154.0 deg
## peak on home, zorp and bolt. The two jobs are now separate variables: the camera still swings
## exactly as far and for exactly as long, while `get_planar_forward` hands movement the heading the
## player left the camera on. See `get_planar_forward` for the before/after tables. The trade this
## comment describes below — an arrival emote seen from behind — is therefore now paid ONLY for the
## landing, and only for as long as the grace lasts.
##
## STILL IGNORED FOR `LANDING_ORBIT_GRACE` SECONDS AFTER A LANDING, and that was the fix for the
## player's *"I still have the problem after I land that I can't move"*. THE MECHANISM, traced
## frame by frame on a home -> zorp landing (a temporary `--rig-trace` print of every heading state
## in `_process`, Compatibility renderer, NO player input at all, t measured from the rig's first
## frame):
##
##   t=10.33  orbit_w=0.000  head_err=0.0    <- control handed back, `reseat_behind_player` correct
##   t=10.43  orbit_w=0.097  head_err=1.7    <- emote="happy" appears; RocketPad's arrival plays it
##   t=10.83  orbit_w=1.000  head_err=89.5      0.35 s after the thaw, and Player.play_emote calls
##   t=11.73  orbit_w=1.000  head_err=151.0     THIS FUNCTION
##   t=11.83  orbit_w=1.000  head_err=151.8   <- peak: the orbit target IS 180 - ORBIT_YAW_DEG
##   t=11.88  orbit_w=0.991  head_err=133.2   <- emote ends, release_orbit, _restoring_fwd=true
##   t=12.43  orbit_w=0.000  head_err=40.8
##   t=13.4+  orbit_w=0.000  head_err=1.1    <- settled back on the reseated heading
##
## `_fwd_saved` read 0.0 deg of error for the WHOLE of that window: the heading the reseat placed
## was never lost, it was being deliberately driven away from it by this function and then driven
## back. So the post-landing swing was not the arrival camera settling and not a smoothing lag —
## it was a cinematic camera move, requested at the exact moment the player was handed the stick.
## `move_forward` is resolved against `_fwd` (`get_planar_forward`), so a 1.0 s forward push landing
## inside that window walked the astronaut sideways or backwards: measured on home -> zorp at
## +1.50 s after handback, displacement along facing was -0.99 m with a 147.3 deg heading error.
##
## WHY REFUSE THE ORBIT RATHER THAN DROP THE ARRIVAL EMOTE. The emote itself is fine and the hop is
## worth keeping; it is only the camera half of it that is wrong here. Refusing in the rig also
## covers every other way an emote could be triggered in the same window (a favor completing, an
## NPC greeting, the emote cycle) instead of one call site in `RocketPad`.
##
## WHAT IT COSTS, honestly: for the first 3.5 s after a landing the astronaut's happy hop is seen
## from behind, which is the framing the integration critic complained about above. That is a
## deliberate trade — in that exact window the camera belongs to the player, who is trying to walk
## away from the rocket, and being 151 deg wrong about which way "forward" is has now been reported
## three separate times. An emote the player asks for after the grace expires still gets its orbit.
func orbit_front(duration: float = 0.5) -> void:
	if _focus_weight > 0.5:
		return
	if not _orbit_grace_off and Time.get_ticks_msec() < _orbit_grace_until_ms:
		return
	if not _has_saved_fwd:
		_fwd_saved = _fwd
		_has_saved_fwd = true
	_restoring_fwd = false
	if _orbit_tween:
		_orbit_tween.kill()
	_orbit_tween = create_tween()
	_orbit_tween.tween_property(self, "_orbit_weight", 1.0, maxf(duration, 0.01)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## Releases the emote orbit; the heading eases back to where it was before `orbit_front`.
func release_orbit(duration: float = 0.55) -> void:
	if _orbit_weight <= 0.0 and (_orbit_tween == null or not _orbit_tween.is_valid()):
		return
	_restoring_fwd = _has_saved_fwd
	if _orbit_tween:
		_orbit_tween.kill()
	_orbit_tween = create_tween()
	_orbit_tween.tween_property(self, "_orbit_weight", 0.0, maxf(duration, 0.01)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## Returns to normal follow framing; the yaw drifts back to where it was before focus_on.
func release_focus(duration: float = 0.6) -> void:
	_restoring_fwd = _has_saved_fwd
	if _focus_tween:
		_focus_tween.kill()
	_focus_tween = create_tween()
	_focus_tween.tween_property(self, "_focus_weight", 0.0, maxf(duration, 0.01)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## THE PLAYER'S CONTROL HEADING on the tangent plane — what `move_forward` means. Normally that is
## the camera heading `_fwd`; while a CINEMATIC is driving `_fwd` it is the heading the player last
## left the camera on, `_fwd_saved`.
##
## WHY THE TWO ARE NOT THE SAME VARIABLE ANY MORE. `_fwd` was doing two jobs — where the camera
## looks, and what the stick means — and the emote camera needs those to disagree. `orbit_front`
## deliberately swings `_fwd` round to 180 - ORBIT_YAW_DEG = 154 deg off the astronaut's facing so
## the pose is visible (that is the whole point of the feature; see `orbit_front`). Resolving the
## stick against that heading meant: TAP AN EMOTE, PUSH THE STICK, WALK SIDEWAYS OR BACKWARDS for
## about two seconds. Measured by an independent critic before this change — 151.7 deg peak on
## zorp, 148.6 deg on a cold start at home — and re-measured here, with a player-triggered emote on
## a cold start and no landing involved (Compatibility renderer, `--ui=mobile`, Director timeline,
## heading error sampled every 0.15 s for 4 s from the emote):
##
##                     BEFORE (peak head_err)     AFTER (peak head_err)
##     home                 151.9 deg                   0.0 deg
##     zorp                 151.9 deg                   0.0 deg
##     bolt                 151.9 deg                   0.0 deg
##
## and a 1.0 s forward push at +0.3 / +0.8 / +1.5 / +2.5 s after the emote, displacement measured
## ALONG the astronaut's facing at the mark: before, 12 of 12 pushes across those three planets
## were NEGATIVE or sideways (worst -2.03 m on bolt at +1.5 s); after, 12 of 12 are positive
## (+2.4 to +3.8 m). The numbers per planet are in the round report.
##
## THE CORRECT HEADING WAS NEVER LOST. `_fwd_saved` — which `focus_on` / `orbit_front` latch on the
## way in so `release_*` can put the camera back — measured 0.0 deg of error for the WHOLE of the
## 151 deg swing. It was simply not the heading movement used. So this returns it, and the camera is
## free to go wherever the shot wants.
##
## WHY `_has_saved_fwd` IS THE RIGHT TEST, and not `_orbit_weight > 0`. The flag is true from the
## instant a cinematic latches the heading until the restore has finished converging (`_process`
## clears it together with `_restoring_fwd`), so it covers the tail as well as the swing — in the
## trace above, the 0.55 s `release_orbit` ease used to still be 40 deg out a third of the way
## through it. It covers the dialogue focus for the same reason and by the same mechanism: that
## branch also pushes `_fwd` up to ~58 deg off for its two-shot framing, and although the player is
## normally frozen for dialogue, "normally" is not a guarantee worth resting the control basis on.
##
## AND WHY IT CANNOT STRAND THE PLAYER ON A STALE HEADING: the moment the player touches the camera
## themselves, `_handle_input`'s yaw branch clears `_has_saved_fwd` (and kills the orbit — "the
## player taking the camera always wins"), so the very next call here returns the `_fwd` they just
## turned to. There is no state in which the stick answers to a heading the player cannot change.
##
## CALLERS CHECKED, all of them, because a caller that wanted the CAMERA heading would break:
##   - `Player._camera_planar_forward` (src/player/player.gd) — builds the movement wish vector.
##     Wants the control heading. This is the bug being fixed.
##   - `JetpackShowcase` (src/player/jetpack_showcase.gd) — only names it in a comment explaining
##     that flight is camera-relative; it drives the rig itself and never calls this.
## Nothing else in the project calls it (grep `planar_forward` over `**/*.gd`). Anything that really
## does want where the lens points should read `get_camera_forward()` below.
func get_planar_forward() -> Vector3:
	if _has_saved_fwd and not _control_basis_off:
		return _fwd_saved
	return _fwd


## Where the camera is actually looking, on the tangent plane. Differs from `get_planar_forward`
## only while a cinematic (emote orbit / dialogue focus) is driving the heading. Diagnostics and
## anything genuinely about the lens want this; movement wants the other one.
func get_camera_forward() -> Vector3:
	return _fwd


## PUTS THE CAMERA BACK BEHIND THE ASTRONAUT, in one frame, without touching the zoom or the pitch.
##
## WHY THIS EXISTS. `_process` latches the heading exactly once, on its first processed frame:
## `_fwd = _player.surface_forward()` under `if not _initialized`. After a rocket flight that first
## frame lands in the MIDDLE of the landing cutscene, while `RocketPad._prepare_journey_arrival` has
## the astronaut deliberately turned to FACE the pad for the framing. `RocketPad._pop_out` then
## re-faces them away from the rocket to hand control back — and nothing told the rig, so the
## heading stayed pointed at the rocket the player just climbed out of.
##
## MEASURED, on a scripted round trip home -> zorp -> bolt -> hub -> home, at the instant control
## returns (`CameraRig.debug_landing_probe`, before this fix): the angle between the camera heading
## and the astronaut's facing was 180.0 / 180.0 / 180.0 / 180.0 deg on the four landings, and still
## 163 / 150 / 180 deg a second later once the slow auto-recentre had begun eating it. `move_forward`
## is resolved against this heading, so pushing the stick forward walked the astronaut BACKWARDS,
## straight into the rocket: the same run measured 4.20 m/s of speed that dropped to 0.00 within
## 0.7 s as they hit the hull. That is the player's *"the move joystick just moved the camera"* and
## *"coming out of a spaceship on new planet still doesnt let me move"*.
##
## PROVENANCE of those numbers, because it matters: the four-landing round trip is one scripted run
## from the original diagnosis. What has since been reproduced independently, twice each and on the
## Compatibility renderer, is the single home -> zorp landing: `--no-reseat` gives head_err 180.0
## deg at handback and a forward pulse of dist=2.12 along_facing=-2.08 (walking BACKWARDS), with a
## second pulse three seconds later travelling 0.00 m — the astronaut wedged against the hull, which
## is literally the player's report. With the fix: head_err 0.0 deg, pulse1 3.73/+3.49, pulse2
## 3.79/+3.54, free both times. The per-planet spread across four planets is NOT independently
## confirmed; the two-arm difference on one planet is.
##
## WHY A SNAP AND NOT A TWEEN. This is called from the end of `RocketPad._pop_out`, before the
## cutscene camera has been handed back — `_hand_camera_back` then blends the flight camera onto an
## already-correct rig transform, and the journey path's `_drop_camera` cuts to one. Nothing on
## screen is looking through this camera at the moment it moves, so easing it would only mean the
## first second of gameplay is spent swinging. `_snap_to_target` also resets `_smoothed_pos` /
## `_smoothed_quat`, so the follow smoothing does not chase the old heading afterwards.
##
## THE SETTLE SWING, AND A CORRECTION. An earlier draft of this comment said the post-landing swing
## was "PRE-EXISTING and NOT caused by this function", on the grounds that the `--no-reseat` arm
## swung too. The arm-vs-arm numbers did not support that and it was wrong: on a home -> zorp
## landing with no player input, sampled every 0.25 s from handback, this function ON gave
## 0.0 -> 100.0 -> 147.0 -> peak 151.0 (+1.85 s) -> 33.4 -> 1.1 deg, an excursion of 151.5 deg,
## against 25.6 deg with `--no-reseat`. The endpoints were right and the middle was worse.
##
## The cause was neither the snap nor "the arrival camera settling": `RocketPad`'s arrival plays a
## "happy" emote 0.35 s after control returns, `Player.play_emote` calls `CameraRig.orbit_front`,
## and that deliberately swings the heading to 180 - ORBIT_YAW_DEG = 154 deg off the astronaut's
## facing for the length of the emote. `orbit_front` carries the frame-by-frame trace. The reseat
## did not cause it — but it did not survive it either, and "correct at handback" was worth very
## little while the next two seconds were not. So the reseat now also arms LANDING_ORBIT_GRACE,
## which makes `orbit_front` decline inside that window.
##
## WHAT IS LEFT, measured the same way with both parts in (see the report for the four-planet
## table): the heading holds within a couple of degrees for the whole 0.0 - 3.0 s window instead of
## touring 151 deg of it, and a 1.0 s forward push is positive along facing at every delay tested.
##
## Any saved heading is dropped with it: `_fwd_saved` is what a dialogue focus or an emote orbit
## restores to, and restoring to a pre-landing heading would re-introduce the bug on the first NPC
## the player talks to after stepping off the ladder.
func reseat_behind_player() -> void:
	if _player == null or not is_instance_valid(_player) or _camera == null:
		return
	_up = _player.up.normalized()
	var fwd := _player.surface_forward()
	fwd -= _up * fwd.dot(_up)
	if fwd.length_squared() < 1e-6:
		return
	_fwd = fwd.normalized()
	_fwd_saved = _fwd
	_has_saved_fwd = false
	_restoring_fwd = false
	# Marked initialised even if this rig has never processed a frame. It has everything the first
	# frame would have set (`_up`, `_fwd`, a snapped transform) and it read them from the astronaut's
	# FINAL post-`_pop_out` facing, which is strictly better than what that frame would have latched.
	# Leaving it false would re-run the latch next frame from the same values — harmless, but it
	# would also re-run `_snap_to_target` and discard any handback blend already in progress.
	_initialized = true
	# Zeroed for the same reason the first-frame latch zeroes it (see `_process`): `_moving_time`
	# drives the slow auto-recentre, and a heading we have just placed deliberately should not be
	# treated as one the player has been walking away from. Inert in practice today — the rig has
	# always already processed a frame by the time `_pop_out` runs (every logged landing read
	# `init=true` before the call), so this path only matters for a rig that lands here virgin.
	_moving_time = 0.0
	# The emote orbit is the one thing that undoes all of the above, and after a landing it fires
	# on its own: see `orbit_front` for the frame-by-frame trace of the 151.8 deg swing it used to
	# put in. Both halves of the guard matter — the deadline stops the orbit that the arrival emote
	# is ABOUT to request 0.35 s from now, and the cancel below covers one that is already running.
	_orbit_grace_until_ms = Time.get_ticks_msec() + int(LANDING_ORBIT_GRACE * 1000.0)
	# Inert in every landing measured so far (`orbit_w` read 0.000 at handback on all four planets),
	# and kept only so that this function's promise — "the heading is now THIS" — cannot be quietly
	# revoked by a tween that was already in flight when the rocket touched down.
	if _orbit_tween:
		_orbit_tween.kill()
	_orbit_weight = 0.0
	_snap_to_target()


# ============================================================================= mouse look
## Raw mouse motion, the mouse wheel, and the cursor-release / re-grab gestures. Motion is only
## ACCUMULATED here; it is applied once per frame in `_handle_input` so the mouse and the
## keys/stick share one code path and cannot fight over `_fwd`.
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if _mouse_look:
			var m := (event as InputEventMouseMotion).relative
			_mouse_dx += clampf(m.x, -MOUSE_MAX_PX_PER_FRAME, MOUSE_MAX_PX_PER_FRAME)
			_mouse_dy += clampf(m.y, -MOUSE_MAX_PX_PER_FRAME, MOUSE_MAX_PX_PER_FRAME)
		return
	# The wheel is bound to zoom_in/zoom_out. A wheel notch is pressed and released inside a single
	# frame, which the polled `is_action_just_pressed` in `_handle_input` can drop at high frame
	# rates, so the event path is authoritative and the poll is suppressed for that frame. The poll
	# has to stay: a Director timeline taps zoom with `Input.action_press`, which emits no event.
	if event.is_action_pressed("zoom_in"):
		_zoom_from_event = true
		if not EventBus.is_modal_open():
			_set_zoom(_dist_target - ZOOM_STEP)
		return
	if event.is_action_pressed("zoom_out"):
		_zoom_from_event = true
		if not EventBus.is_modal_open():
			_set_zoom(_dist_target + ZOOM_STEP)
		return
	if event.is_action_pressed("ui_cancel") and _mouse_look:
		_mouse_freed_by_player = true
		_update_mouse_capture()
		return
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		if (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT and _mouse_freed_by_player:
			_mouse_freed_by_player = false
			_update_mouse_capture()


func _on_modal_changed(_name: String) -> void:
	_update_mouse_capture()


## True only while the player is genuinely driving the astronaut: bound, in the tree, unpaused, and
## not frozen by a cutscene. `Player.input_enabled` is what the rocket's liftoff sequence and the
## dialogue runner clear, and it is the only cutscene signal that crosses domains.
func _gameplay_active() -> bool:
	if _player == null or not is_instance_valid(_player) or not _player.is_inside_tree():
		return false
	if get_tree().paused:
		return false
	var enabled: Variant = _player.get("input_enabled")
	if enabled != null and not bool(enabled):
		return false
	return true


## Recomputes whether the mouse owns the camera, and mirrors it onto the OS cursor. Cheap; called
## every frame as well as on the modal signals, because a cutscene freezes the player without one.
func _update_mouse_capture() -> void:
	# NOT ON MOBILE. A phone (and a touch browser) emits an EMULATED mouse event for every finger,
	# with a `relative` that jumps from wherever the last one was to the new touch point. With
	# mouse look armed, `_unhandled_input` accumulated those, so tapping Jump or Fly threw the
	# camera across the sky — reported from a real iPhone. On mobile the camera belongs to
	# TouchControls, which drives it through add_look_px(). This is checked every frame, so the
	# pause menu's Controls setting switches it live.
	var want := (not _mouse_blocked and not _mouse_freed_by_player
		and not EventBus.is_modal_open() and _gameplay_active()
		and not Platform.is_mobile())
	if want == _mouse_look:
		return
	_mouse_look = want
	if _mouse_test:
		print("MOUSELOOK %s (freed=%s modal=%s gameplay=%s)" % [str(want), str(_mouse_freed_by_player), str(EventBus.is_modal_open()), str(_gameplay_active())])
	# Drop whatever was in flight, so a modal that opens mid-flick does not fling the camera when
	# it closes again.
	_mouse_dx = 0.0
	_mouse_dy = 0.0
	if _grab_cursor:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if want else Input.MOUSE_MODE_VISIBLE


## Test hook. A Director timeline drives actions with `Input.action_press`, which sets action state
## but emits no InputEvent, so it cannot deliver mouse motion. This synthesises a real
## InputEventMouseMotion and pushes it through the ordinary input pipeline, so what the timeline
## exercises is `_unhandled_input` and `_handle_input` themselves - not a private shortcut.
## Run the scene with `--mouse-look-test` so the rig arms mouse look without grabbing the cursor.
func debug_mouse_motion(dx: float, dy: float) -> void:
	var ev := InputEventMouseMotion.new()
	ev.relative = Vector2(dx, dy)
	ev.screen_relative = Vector2(dx, dy)
	ev.velocity = Vector2.ZERO
	Input.parse_input_event(ev)


## Test hooks for the two cursor gestures, same principle as `debug_mouse_motion`: a real event
## through the real pipeline, because `Input.action_press` (all a Director timeline has) emits none.
func debug_send_action(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)


## Test hooks for the touch API. A Director timeline can only pass scalars and 3-element vectors, so
## these are the way `tests/director/player_touch_camera.json` exercises the REAL public entry points
## (`add_look` / `add_zoom`) rather than a private shortcut.
func debug_touch_look(dx_deg: float, dy_deg: float) -> void:
	add_look(Vector2(dx_deg, dy_deg))


func debug_touch_look_px(dx_px: float, dy_px: float) -> void:
	add_look_px(Vector2(dx_px, dy_px))


func debug_touch_zoom(delta_m: float) -> void:
	add_zoom(delta_m)


## Test hook for the framing ladder. Snaps distance and pitch so one Director run can capture the
## same standpoint at 6.5 / 7.0 / 7.4 / 8.0 m and the choice is made from frames rather than taste.
## Prints what it set, so a capture can be tied to its numbers from the log alone.
func debug_set_framing(dist_m: float, pitch_deg: float) -> void:
	if _zoom_tween:
		_zoom_tween.kill()
	_dist_target = clampf(dist_m, dist_min(), dist_max())
	_dist = _dist_target
	_pitch = clampf(deg_to_rad(pitch_deg), deg_to_rad(PITCH_MIN_DEG), deg_to_rad(PITCH_MAX_DEG))
	print("CAMRIG framing dist=%.2f pitch=%.1f (mode=%s range=%.1f-%.1f)" % [
		_dist, rad_to_deg(_pitch), Platform.mode_name(), dist_min(), dist_max()])


## Prints the framing the rig is actually running, so a capture can assert it rather than assume it.
func debug_report() -> void:
	print("CAMRIG mode=%s dist=%.2f (target %.2f, range %.1f-%.1f) pitch=%.1f fov=%.1f user_zoom=%s user_pitch=%s" % [
		Platform.mode_name(), _dist, _dist_target, dist_min(), dist_max(),
		rad_to_deg(_pitch), _camera.fov if _camera else -1.0, str(_zoom_user_set), str(_pitch_user_set)])


## THE STUCK-AFTER-LANDING PROBE. Prints, in one line a Director timeline can call at any instant,
## every quantity the "I can't move after I land" report could plausibly turn on:
##
##   gate   - is the tree paused, is a modal up, is `Player.input_enabled` set, is the player
##            physics-processing. If any of these is wrong the astronaut is frozen and the joystick
##            is innocent.
##   head   - the angle between the camera heading `_fwd` (which is what `move_forward` is resolved
##            against, via `get_planar_forward`) and the astronaut's own facing. On a clean follow
##            camera this is ~0 deg because the camera sits BEHIND the player. A large value means
##            the heading was latched somewhere else, and pushing "forward" walks sideways or
##            straight into the rocket.
##   speed  - the tangential speed the body is actually achieving, which is the only number that
##            settles whether the player can move.
##
## Deliberately one print with a tag rather than a return value: a Director `call` step discards
## return values, so the log is the measurement channel.
func debug_landing_probe(tag: String) -> void:
	var paused := get_tree().paused
	var modal := EventBus.is_modal_open()
	if _player == null or not is_instance_valid(_player):
		print("LANDPROBE %s NO PLAYER paused=%s modal=%s" % [tag, str(paused), str(modal)])
		return
	var enabled: Variant = _player.get("input_enabled")
	var facing: Vector3 = _player.surface_forward()
	# `head_err` is measured against the CONTROL heading (`get_planar_forward`), not against `_fwd`,
	# because the control heading is what this probe has always been about — "pushing forward walks
	# into the rocket". Since the two were separated they can differ, and `cam_err` reports the
	# camera's own heading beside it so a cinematic swing is still visible in the log rather than
	# hidden by the fix: during an emote the healthy reading is head_err ~0 with cam_err ~154.
	var head := get_planar_forward()
	# Both are already tangent to the sphere, so the plain dot is the heading error the player feels.
	var err_deg := rad_to_deg(acos(clampf(head.normalized().dot(facing.normalized()), -1.0, 1.0)))
	var cam_err_deg := rad_to_deg(acos(clampf(_fwd.normalized().dot(facing.normalized()), -1.0, 1.0)))
	var vel: Vector3 = _player.velocity
	var tangential := vel - _player.up * vel.dot(_player.up)
	# The planet id is in the line because of a review note on the last round: a landing measurement
	# that does not say WHERE it landed cannot be checked, and a four-planet table built from four
	# director timelines that differ only in how many menu taps they send is exactly the kind of
	# thing that silently measures the same planet four times.
	var pid := "?"
	var pl: Variant = _player.get("planet")
	if pl != null and is_instance_valid(pl as Object):
		var pdata: Variant = (pl as Object).get("data")
		if pdata != null:
			pid = str((pdata as Object).get("id"))
	print("LANDPROBE %s planet=%s paused=%s modal=%s input_enabled=%s phys=%s init=%s head_err=%.1fdeg cam_err=%.1fdeg orbit_w=%.3f speed=%.2f" % [
		tag, pid, str(paused), str(modal), str(enabled),
		str(_player.is_physics_processing()), str(_initialized), err_deg, cam_err_deg,
		_orbit_weight, tangential.length()])


## DISPLACEMENT, not speed, is what settles this bug — and the two disagree.
##
## The first pass at measuring the landing bug recorded SPEED at the moment control returned. Speed
## is not WRONG — the original four-landing baseline read 4.20 / 0.00 / 0.50 / 1.50 m/s, and those
## zeroes and near-zeroes are the bug showing through — but it is ambiguous in the one direction
## that matters: a healthy-looking 4.20 m/s is the astronaut sprinting BACKWARDS into the rocket
## with the camera heading 180 deg out, and it collapses to 0.00 within about 0.7 s when they hit
## the hull. Which of the two you sample depends entirely on when you look. (An earlier version of
## this comment claimed speed "does not" distinguish the broken state at all; that was too strong —
## a later cross-check hit 0.00 in the broken arm on its first try. Speed is a lagging, timing-
## dependent read of the same fault, not a blind one.) `debug_mark` remembers
## where the astronaut is and which way they are facing; `debug_travel` then reports how far they
## actually got and how much of it was along the direction they were facing when the mark was set.
## A negative along-facing figure is the bug, in one number.
func debug_mark(_tag: String = "") -> void:
	if _player == null or not is_instance_valid(_player):
		return
	_probe_mark_pos = _player.global_position
	_probe_mark_fwd = _player.surface_forward()
	# The CONTROL heading, for the same reason `debug_landing_probe` reports that one: what this
	# probe answers is "did pushing forward move them forward", and that is resolved against
	# `get_planar_forward`, which is no longer always `_fwd`.
	_probe_mark_head = get_planar_forward()


func debug_travel(tag: String) -> void:
	if _player == null or not is_instance_valid(_player):
		print("TRAVEL %s NO PLAYER" % tag)
		return
	var d := _player.global_position - _probe_mark_pos
	# Only the tangential part: a landing hop and a bit of settle onto the surface are not travel.
	var up := _player.up.normalized()
	d -= up * d.dot(up)
	var head_err := rad_to_deg(acos(clampf(_probe_mark_head.normalized().dot(
		_probe_mark_fwd.normalized()), -1.0, 1.0)))
	print("TRAVEL %s dist=%.2f along_facing=%+.2f head_err_at_mark=%.1fdeg" % [
		tag, d.length(), d.dot(_probe_mark_fwd.normalized()), head_err])


func debug_click() -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	Input.parse_input_event(ev)


## True while the mouse is driving the camera (tests and the HUD may want to know).
func is_mouse_look_active() -> bool:
	return _mouse_look


func _process(delta: float) -> void:
	# Polled, not purely signal-driven: a cutscene freezes the player by clearing
	# `Player.input_enabled`, which emits nothing, and the tree can be paused from anywhere.
	_update_mouse_capture()
	if _player == null or not is_instance_valid(_player):
		return
	var target_up := _player.up.normalized()
	if not _initialized:
		_up = target_up
		_fwd = _player.surface_forward()
		_initialized = true
		_moving_time = 0.0
		_snap_to_target()
		return

	# parallel-transport the forward vector as the up vector changes (no world-up reference -> no pole flips)
	var d := clampf(_up.dot(target_up), -1.0, 1.0)
	if d < 0.999999:
		var axis := _up.cross(target_up)
		if axis.length_squared() > 1e-10:
			var ang := acos(d)
			_fwd = _fwd.rotated(axis.normalized(), ang)
			_fwd_saved = _fwd_saved.rotated(axis.normalized(), ang)
	_up = target_up
	_fwd = (_fwd - _up * _fwd.dot(_up)).normalized()
	_fwd_saved = (_fwd_saved - _up * _fwd_saved.dot(_up)).normalized()
	if _restoring_fwd:
		_fwd = _fwd.slerp(_fwd_saved, 1.0 - exp(-3.0 * delta)).normalized()
		_fwd = (_fwd - _up * _fwd.dot(_up)).normalized()
		if _fwd.dot(_fwd_saved) > 0.9998:
			_restoring_fwd = false
			_has_saved_fwd = false

	_consume_orbit_grace()
	_handle_input(delta)
	_auto_recenter(delta)

	var pivot := _player.global_position + _up * PIVOT_HEIGHT
	var dist := _dist
	var pitch := _pitch
	var look_fwd := _fwd
	if _focus_weight > 0.001:
		var to_focus := _focus_pos - _player.global_position
		to_focus -= _up * to_focus.dot(_up)
		if to_focus.length_squared() > 0.01:
			var side := to_focus.normalized().cross(_up)
			var best := side if side.dot(_fwd) >= 0.0 else -side
			look_fwd = _fwd.slerp(best, _focus_weight * 0.85).normalized()
			look_fwd = (look_fwd - _up * look_fwd.dot(_up)).normalized()
		var mid := (_player.global_position + _up * 0.9 + _focus_pos + _up * 0.9) * 0.5
		pivot = pivot.lerp(mid, _focus_weight * 0.75)
		dist = lerpf(_dist, _dist * FOCUS_PUSH_IN, _focus_weight)
		pitch = lerpf(_pitch, deg_to_rad(20.0), _focus_weight)
		# Rotated about an EXPLICITLY normalised axis rather than `_fwd.slerp(look_fwd, ...)`.
		#
		# `Vector3.slerp` derives its axis as `cross(a, b) / sqrt(cross(a, b).length_squared())`,
		# and once this ease has CONVERGED — which it does within about a second, and then stays
		# converged for as long as the dialogue is held — `_fwd` and `look_fwd` are parallel to
		# within a few ULPs. The cross product is then almost entirely cancellation error, and
		# normalising it in float32 lands outside `Math::is_equal_approx(1, len)`, so the
		# `rotated()` inside slerp asserts:
		#     ERROR: The axis Vector3 (0.0, -1.000509, 0.0) must be normalized.
		# once per frame. A two-minute run in which the intro dialogue was never dismissed logged
		# 13,342 of those lines; an ordinary run, where dialogue is read and closed, logs zero,
		# which is why it went unnoticed. Pre-existing, and cosmetic in the sense that the returned
		# heading was still fine — but it is a real un-normalised axis and it drowns the log.
		#
		# So: bail out below the angle where the axis stops being meaningful (1e-4 rad ~ 0.006 deg,
		# far finer than the ROT_SMOOTH follow can express) and otherwise rotate about the axis we
		# normalised ourselves. Same curve as before — slerp of two unit vectors IS a rotation
		# about that axis by `w` of the angle between them.
		var fw := 1.0 - exp(-2.0 * delta * _focus_weight)
		var dp := clampf(_fwd.dot(look_fwd), -1.0, 1.0)
		var ang_f := acos(dp)
		if ang_f > 1e-4:
			var ax := _fwd.cross(look_fwd)
			if ax.length_squared() > 1e-12:
				_fwd = _fwd.rotated(ax.normalized(), ang_f * fw).normalized()
		_fwd = (_fwd - _up * _fwd.dot(_up)).normalized()
	elif _orbit_weight > 0.001:
		# Emote orbit. The camera looks ALONG _fwd at the player, so to see the astronaut's front
		# the heading has to end up opposite their facing; the extra yaw makes it three-quarter.
		var face := _player.surface_forward()
		face = (face - _up * face.dot(_up)).normalized()
		if face.length_squared() > 0.5:
			var target := (-face).rotated(_up, deg_to_rad(ORBIT_YAW_DEG))
			target = (target - _up * target.dot(_up)).normalized()
			_fwd = _fwd.slerp(target, 1.0 - exp(-ORBIT_TURN_RATE * delta * _orbit_weight)).normalized()
			_fwd = (_fwd - _up * _fwd.dot(_up)).normalized()
			look_fwd = _fwd
		dist = lerpf(_dist, _dist * ORBIT_PUSH_IN, _orbit_weight)
		pitch = lerpf(_pitch, deg_to_rad(ORBIT_PITCH_DEG), _orbit_weight)

	var desired := pivot - look_fwd * cos(pitch) * dist + _up * sin(pitch) * dist
	var kp := 1.0 - exp(-POS_SMOOTH * delta)
	var kr := 1.0 - exp(-ROT_SMOOTH * delta)
	_smoothed_pos = _smoothed_pos.lerp(desired, kp)

	# The look direction is taken from the FINAL position, after the spring arm has had its say.
	# For the old pull-in this is identical (shortening the arm does not change the direction to
	# the pivot), but a LIFT does change it, and aiming from the pre-avoidance position would point
	# the lifted camera past the astronaut.
	var final_pos := _avoid_terrain(delta, pivot, _smoothed_pos)
	var look_basis := Basis.looking_at((pivot - final_pos).normalized(), _up)
	_smoothed_quat = _smoothed_quat.slerp(look_basis.get_rotation_quaternion(), kr).normalized()
	_camera.global_transform = Transform3D(Basis(_smoothed_quat), final_pos)
	_update_occluder_fade(delta, final_pos)


func _snap_to_target() -> void:
	var pivot := _player.global_position + _up * PIVOT_HEIGHT
	_smoothed_pos = pivot - _fwd * cos(_pitch) * _dist + _up * sin(_pitch) * _dist
	_smoothed_quat = Basis.looking_at((pivot - _smoothed_pos).normalized(), _up).get_rotation_quaternion()
	_camera.global_transform = Transform3D(Basis(_smoothed_quat), _smoothed_pos)


## One place where every camera scheme lands. Mouse motion (pixels, drained from the accumulator),
## the touch front end's `add_look` / `add_zoom` (degrees and metres, same accumulator treatment),
## and the H/L/K/M keys and the gamepad right stick (a rate x delta) are summed into a single yaw and
## pitch delta for this frame, so no scheme can latch a value another scheme then fights.
func _handle_input(delta: float) -> void:
	var mouse_x := _mouse_dx
	var mouse_y := _mouse_dy
	_mouse_dx = 0.0
	_mouse_dy = 0.0
	# Drained unconditionally, before the modal gate: input handed over while a shop was opening must
	# be thrown away, not held and applied the moment it closes.
	var ext_yaw_deg := clampf(_ext_look.x, -EXT_LOOK_MAX_DEG_PER_FRAME, EXT_LOOK_MAX_DEG_PER_FRAME)
	var ext_pitch_deg := clampf(_ext_look.y, -EXT_LOOK_MAX_DEG_PER_FRAME, EXT_LOOK_MAX_DEG_PER_FRAME)
	var ext_zoom := clampf(_ext_zoom, -EXT_ZOOM_MAX_M_PER_FRAME, EXT_ZOOM_MAX_M_PER_FRAME)
	_ext_look = Vector2.ZERO
	_ext_zoom = 0.0
	# A cutscene freezes the astronaut without opening a modal (the rocket clears
	# `Player.input_enabled`), and the camera is the cutscene's during that. The keys and the stick
	# have always been left alone here; the touch API is new, so it gets the stricter gate.
	if not _gameplay_active():
		ext_yaw_deg = 0.0
		ext_pitch_deg = 0.0
		ext_zoom = 0.0
	var zoom_by_event := _zoom_from_event
	_zoom_from_event = false
	if EventBus.is_modal_open():
		return

	var sens := clampf(float(GameState.settings.get("mouse_sensitivity", 1.0)), 0.1, 4.0)
	var invert_x := bool(GameState.settings.get("camera_invert_x", false))
	var invert_y := bool(GameState.settings.get("camera_invert_y", false))

	# ---- external zoom (pinch). Applied straight to the distance with no tween, so it tracks the
	# fingers; the wheel keeps its ease below.
	if absf(ext_zoom) > 0.00001:
		if _zoom_tween:
			_zoom_tween.kill()
		_dist_target = clampf(_dist_target + ext_zoom, dist_min(), dist_max())
		_dist = _dist_target
		_zoom_user_set = true

	# ---- yaw: mouse pixels + touch degrees + stick/key rate, all in the same sign convention as
	# camera_right.
	var yaw_in := Input.get_axis("camera_left", "camera_right")
	var yaw_rad := yaw_in * deg_to_rad(YAW_SPEED_DEG) * delta
	if _mouse_look:
		yaw_rad += mouse_x * deg_to_rad(MOUSE_YAW_DEG_PER_PX) * sens
	yaw_rad += deg_to_rad(ext_yaw_deg) * sens
	if invert_x:
		yaw_rad = -yaw_rad
	if absf(yaw_rad) > 0.00001:
		_fwd = _fwd.rotated(_up, -yaw_rad).normalized()
		_moving_time = 0.0
		_restoring_fwd = false
		_has_saved_fwd = false
		# The player taking the camera always wins: an emote orbit that fought the stick would feel
		# like the camera was stuck.
		if _orbit_weight > 0.0 or (_orbit_tween != null and _orbit_tween.is_valid()):
			if _orbit_tween:
				_orbit_tween.kill()
			_orbit_weight = 0.0

	# ---- pitch. Mouse DOWN raises `_pitch`, which lifts the camera and tilts the view downward -
	# the standard non-inverted third-person mapping, and the same direction camera_down already had.
	var pitch_in := Input.get_axis("camera_down", "camera_up")
	var pitch_rad := pitch_in * deg_to_rad(PITCH_SPEED_DEG) * delta
	if _mouse_look:
		pitch_rad += mouse_y * deg_to_rad(MOUSE_PITCH_DEG_PER_PX) * sens
	pitch_rad += deg_to_rad(ext_pitch_deg) * sens
	if invert_y:
		pitch_rad = -pitch_rad
	if absf(pitch_rad) > 0.00001:
		_pitch = clampf(_pitch + pitch_rad, deg_to_rad(PITCH_MIN_DEG), deg_to_rad(PITCH_MAX_DEG))
		_pitch_user_set = true

	# Wheel zoom normally arrives as an event (see `_unhandled_input`); this polled path is what a
	# Director timeline's `Input.action_press("zoom_in")` goes through, and is suppressed on any
	# frame the event path already fired.
	if zoom_by_event:
		return
	if Input.is_action_just_pressed("zoom_in"):
		_set_zoom(_dist_target - ZOOM_STEP)
	elif Input.is_action_just_pressed("zoom_out"):
		_set_zoom(_dist_target + ZOOM_STEP)


func _set_zoom(target: float) -> void:
	_dist_target = clampf(target, dist_min(), dist_max())
	_zoom_user_set = true
	if _zoom_tween:
		_zoom_tween.kill()
	_zoom_tween = create_tween()
	_zoom_tween.tween_property(self, "_dist", _dist_target, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


## ENDS `LANDING_ORBIT_GRACE` ON THE PLAYER'S FIRST REAL MOVEMENT INPUT, keeping the timer only as
## a backstop.
##
## WHY. 3.5 s was chosen to bracket an OBSERVED sequence — the arrival emote is requested 0.35 s
## after the thaw and holds the camera about 2.2 s more — rather than derived from one, and nothing
## in the code enforces the link. Move the arrival emote later, or lengthen it, and the constant
## silently stops covering the window it exists for. The event the grace is really waiting for is
## not a duration at all: it is "has the player started driving yet". Once they have, an emote
## camera can no longer surprise them, because a surprise is only a surprise before you take the
## wheel — and after the separation of the control basis from the camera heading (see
## `get_planar_forward`) the orbit cannot misdirect the stick even if it does fire. That is the
## point of doing both fixes: this constant stops being load-bearing.
##
## WHAT COUNTS AS "FIRST REAL INPUT", precisely: gameplay is live (tree not paused, no modal,
## `Player.input_enabled` true — a cutscene's own scripted presses therefore do not count), and
## `Input.get_vector` over the four move actions has a magnitude above GRACE_RELEASE_PUSH. It is the
## same vector `Player._physics_process` builds its wish direction from, read the same polled way,
## so it cannot disagree with what the astronaut is doing; and a resting thumb at push 0.00 — or a
## drifting one anywhere under 0.2 — does not count. Camera input is deliberately NOT included:
## looking around is not taking control of the walk, and `_handle_input`'s yaw branch already
## cancels an orbit outright.
##
## Only ever SHORTENS the window, never extends it, so the measured landing behaviour can only be
## preserved or improved by it: with no input the deadline is still 3.5 s of wall clock.
##
## MEASURED, home -> zorp landing, both runs identical apart from the push (Compatibility renderer,
## `--ui=mobile`; `play_emote("dance")` requested 2.0 s after control returns, i.e. well inside the
## 3.5 s window; `orbit_w` and `cam_err` sampled at +0.2 / +0.5 / +0.9 / +1.4 s from that request):
##
##   no input at all      orbit_w 0.000 0.000 0.000 0.000   cam_err 0.0 0.0 0.0 0.0    <- refused
##   0.4 s push at +0.9 s orbit_w 0.345 1.000 1.000 1.000   cam_err 10.9 86.3 136.6 150.8
##
## and `head_err` — the control basis — read 0.0 deg on every one of those eight samples, in both
## runs. So the player who takes the stick gets their emote framing back immediately, the player who
## has not touched it still gets the quiet arrival camera, and neither of them can be steered by it.
## The five-delay post-landing push table (15/15 positive, in `Player._camera_planar_forward`) was
## measured with this code in, so it is a reading of both fixes together.
func _consume_orbit_grace() -> void:
	if _orbit_grace_until_ms == 0:
		return
	if Time.get_ticks_msec() >= _orbit_grace_until_ms:
		_orbit_grace_until_ms = 0
		return
	if EventBus.is_modal_open() or not _gameplay_active():
		return
	var move := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if move.length() > GRACE_RELEASE_PUSH:
		_orbit_grace_until_ms = 0


## Slowly drifts behind the player after they have been moving for a while.
func _auto_recenter(delta: float) -> void:
	var v := _player.get_tangent_velocity()
	if v.length() > 1.0:
		_moving_time += delta
	else:
		_moving_time = 0.0
	if _moving_time > RECENTER_DELAY and _focus_weight < 0.5:
		var target := _player.surface_forward()
		var w := clampf((_moving_time - RECENTER_DELAY) / 1.5, 0.0, 1.0)
		var k := 1.0 - exp(-RECENTER_RATE * w * delta)
		_fwd = _fwd.slerp(target, k).normalized()
		_fwd = (_fwd - _up * _fwd.dot(_up)).normalized()


# ============================================================================= near-geometry fade
## Fades out anything on OCCLUDER_MASK standing between the camera and the astronaut, and fades it
## back in once it moves off the sight line. See the constants above for why this and not a longer
## spring arm. Called once per frame with the camera's FINAL position, after `_avoid_terrain`.
func _update_occluder_fade(delta: float, cam_pos: Vector3) -> void:
	_probe_timer -= delta
	if _probe_timer <= 0.0:
		_probe_timer = PROBE_INTERVAL
		_probe_occluders(cam_pos)
	var done: Array[int] = []
	for id: int in _faded:
		var e: Dictionary = _faded[id]
		var want := float(e["want"])
		var cur := float(e["t"])
		var rate := FADE_IN_RATE if want > cur else FADE_OUT_RATE
		var t := move_toward(cur, want, rate * delta)
		e["t"] = t
		var alive := false
		var meshes: Array = e["meshes"]
		for g: GeometryInstance3D in meshes:
			if is_instance_valid(g):
				g.transparency = 0.0 if _fade_off else t * FADE_TO
				alive = true
		if not alive or (t <= 0.0 and want <= 0.0):
			done.append(id)
	for id: int in done:
		_faded.erase(id)
	if _fade_debug:
		var names: Array[String] = []
		for id: int in _faded:
			var e: Dictionary = _faded[id]
			if float(e["t"]) > 0.01:
				var meshes: Array = e["meshes"]
				if not meshes.is_empty() and is_instance_valid(meshes[0]):
					names.append("%s@%.2f" % [(meshes[0] as Node).get_parent().name, float(e["t"])])
		names.sort()
		var line := ", ".join(names)
		if line != _fade_debug_last:
			_fade_debug_last = line
			print("CAMFADE [%s]" % line)


## One probe cycle: a SIGHT_RADIUS capsule swept from the lens to each of SIGHT_HEIGHTS on the
## astronaut, marking everything on OCCLUDER_MASK it passes through. See SIGHT_RADIUS for why this is
## a volume and not three thin rays.
func _probe_occluders(cam_pos: Vector3) -> void:
	for id: int in _faded:
		(_faded[id] as Dictionary)["want"] = 0.0
	var space := get_world_3d().direct_space_state
	if space == null or _player == null:
		return
	var feet := _player.global_position
	for h: float in SIGHT_HEIGHTS:
		var target := feet + _up * h
		var to_target := target - cam_pos
		# Stop OCCLUDER_MIN_DIST short of the astronaut: a prop they are standing against is not what
		# is hiding them, and fading it would flicker as they brush past.
		var span := to_target.length() - OCCLUDER_MIN_DIST
		if span <= 0.05:
			continue
		var dir := to_target / to_target.length()
		_sight_capsule.height = maxf(span, 2.0 * SIGHT_RADIUS + 0.01)
		_sight_query.transform = Transform3D(_capsule_basis(dir), cam_pos + dir * (span * 0.5))
		for hit: Dictionary in space.intersect_shape(_sight_query, MAX_OCCLUDER_DEPTH):
			var col: Variant = hit.get("collider")
			if col is Node3D:
				_mark_occluder(col as Node3D)


## A basis whose +Y runs along `dir`, because CapsuleShape3D is Y-aligned. The reference axis is the
## planet up unless the sight line is nearly parallel to it (looking straight down at the astronaut
## from a full lift), in which case any perpendicular will do.
func _capsule_basis(dir: Vector3) -> Basis:
	var ref := _up if absf(_up.dot(dir)) < 0.98 else _fwd
	var x := dir.cross(ref)
	if x.length_squared() < 1e-8:
		x = dir.cross(Vector3.RIGHT if absf(dir.x) < 0.9 else Vector3.UP)
	x = x.normalized()
	return Basis(x, dir, x.cross(dir).normalized())


## Marks one hit collider's visual body as wanting to be faded, building its mesh list on first use.
##
## The meshes may hang off the collider itself (planet props: `PlanetProps._spawn_blocking` makes
## the StaticBody3D the model root) or off its parent (`DecoItem` and `BuildingBase` add a child
## body called "Blocker"/similar next to the visuals), so this walks up until it finds geometry,
## at most two levels, and never past a node in the "player" group.
func _mark_occluder(col: Node3D) -> void:
	var id := col.get_instance_id()
	if _faded.has(id):
		(_faded[id] as Dictionary)["want"] = 1.0
		return
	var root: Node3D = col
	var meshes: Array[GeometryInstance3D] = _collect_geometry(root)
	var hops := 0
	while meshes.is_empty() and hops < 2:
		var parent := root.get_parent()
		if parent == null or not (parent is Node3D) or parent.is_in_group("player"):
			break
		root = parent as Node3D
		meshes = _collect_geometry(root)
		hops += 1
	if meshes.is_empty():
		# A bare collider with no visuals of its own (a trigger volume, a stray blocker). There is
		# nothing to fade, so it is dropped again on this same tick; re-walking two nodes at 12 Hz
		# costs nothing and keeps the dictionary free of dead weight.
		_faded[id] = {"meshes": [] as Array[GeometryInstance3D], "t": 0.0, "want": 0.0}
		return
	_faded[id] = {"meshes": meshes, "t": 0.0, "want": 1.0}


func _collect_geometry(n: Node) -> Array[GeometryInstance3D]:
	var out: Array[GeometryInstance3D] = []
	if n is GeometryInstance3D:
		out.append(n as GeometryInstance3D)
	for c: Node in n.get_children():
		out.append_array(_collect_geometry(c))
	return out


## Spring arm. If terrain or a building sits between the pivot and the camera, first try to climb
## OVER it at full distance (see the LIFT_* block), and only pull the camera in if no lift clears.
## Small props are handled by the fade above instead - see OCCLUDER_MASK for why.
func _avoid_terrain(delta: float, pivot: Vector3, cam_pos: Vector3) -> Vector3:
	var space := get_world_3d().direct_space_state
	if space == null:
		return cam_pos
	var off := cam_pos - pivot
	var full := off.length()
	if full < 0.001:
		return cam_pos

	# ---- how much lift would this frame need? Lowest step that clears, MAX if none does, 0 if the
	# unlifted arm is already clear.
	var want_lift := 0.0
	var axis := Vector3.ZERO
	var horiz := off - _up * off.dot(_up)
	if horiz.length_squared() > 0.000001:
		axis = horiz.normalized().cross(_up).normalized()
	if not _arm_clear(space, pivot, cam_pos):
		want_lift = deg_to_rad(LIFT_MAX_DEG)
		if axis != Vector3.ZERO:
			for i in range(1, LIFT_STEPS + 1):
				var a := deg_to_rad(LIFT_MAX_DEG) * float(i) / float(LIFT_STEPS)
				if _arm_clear(space, pivot, pivot + off.rotated(axis, a)):
					want_lift = a
					break
	_lift = move_toward(_lift, want_lift, LIFT_RATE * delta)
	var lifted := cam_pos
	if _lift > 0.0001 and axis != Vector3.ZERO:
		lifted = pivot + off.rotated(axis, _lift)

	# ---- last resort: the classic pull-in, along the (possibly lifted) arm.
	var dir := lifted - pivot
	var hit := space.intersect_ray(_arm_query(pivot, lifted))
	if hit.is_empty():
		return lifted
	var hit_pos: Vector3 = hit["position"]
	var d := maxf((hit_pos - pivot).length() - TERRAIN_MARGIN, 0.8)
	return pivot + dir.normalized() * minf(d, dir.length())


func _arm_query(pivot: Vector3, cam_pos: Vector3) -> PhysicsRayQueryParameters3D:
	var q := PhysicsRayQueryParameters3D.create(pivot, cam_pos, AVOID_MASK)
	q.hit_from_inside = false
	return q


func _arm_clear(space: PhysicsDirectSpaceState3D, pivot: Vector3, cam_pos: Vector3) -> bool:
	return space.intersect_ray(_arm_query(pivot, cam_pos)).is_empty()
