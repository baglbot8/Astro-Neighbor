class_name ChibiModel
extends CharacterModel
## Base class for every Animal-Crossing-cute neighbour model (Zorp, Bolt, Pip, Pop, Mayor Orbit,
## DJ Nova). Procedural geometry + the same pose-lerp animation system the astronaut uses, so an NPC
## can be driven with exactly the AstronautModel API:
##
##   model.set_state("walk")          # idle walk talk wave happy think surprised dance
##   model.tick(delta, speed_factor)  # every frame; speed_factor 1.0 == walk speed
##
## Proportions follow docs/STYLE_GUIDE.md "Character rules — Animal Crossing cute":
## head ≈ 0.49 H and wider than tall, NO neck, squat bean torso, stub arms with round mitten hands,
## stubby legs, big round feet. Origin at the feet, model faces -Z, ~1.4 m tall (before `body_scale`).
##
## Subclasses only implement `_build_geometry()` and compose the shared parts:
##   _add_head_shell(), _add_torso_bean(), _add_arms(), _add_legs(), _add_face(), _add_blush()...
## Anything species specific (antenna, scarf, headphones, screen) is added there too; per-frame
## motion for those parts goes in `_animate_extras(delta)` driven by the EXTRA_A / EXTRA_B channels.

const EMOTE_DURATIONS := {"wave": 1.4, "happy": 1.6, "think": 2.0, "surprised": 1.2, "dance": 2.8}
const STATES: PackedStringArray = ["idle", "walk", "talk", "wave", "happy", "think", "surprised", "dance"]

# --- proportions for a 1.4 m villager (metres) -------------------------------------------------
const HEIGHT := 1.4
const HEAD_R := 0.36
const HEAD_SQUASH := 0.905          ## head y radius = HEAD_R * this -> slightly wider than tall
const HEAD_Y := 0.945
## R2.3 ("less round, more structure"). The head is no longer a sphere: it is a SUPERELLIPSOID,
## |x/a|^n + |y/b|^n + |z/c|^n = 1. n = 2 is the old ball; n = 2.6 keeps the chunky plush mass but
## gives it flat-ish cheek, brow and crown planes with soft chamfered corners — the ACNH
## "rounded but structured" read instead of "a ball". Face placement uses the SAME surface (see
## `_orient_on_head`), so every feature still lands exactly on the shell.
const HEAD_SEMI := Vector3(HEAD_R * 1.04, HEAD_R * HEAD_SQUASH, HEAD_R * 0.96)
const HEAD_N := 2.6
## How far the crown seam stands OUT of the shell it rings. `_add_head_shell` sizes the seam so its
## edge is exactly ON the shell, which is co-planar geometry: it z-fights, and the fight resolves
## differently per triangle, so the seam reads as a dashed line rather than a rim. 2 % clears it and
## is what turns the seam into the hard rim the top plane needs to read AS a plane. The waist
## chamfer needs no equivalent — at half a semi-axis down the bean it is already 3.5 % proud.
const SEAM_PROUD := 1.02
## Body superellipsoid exponents: the bean, the mitts and the feet all get planes too.
const TORSO_N := 2.4
const HAND_N := 2.3
const FOOT_N := 3.0
const TORSO_Y := 0.40
const TORSO_RX := 0.222
const TORSO_RY := 0.235
const TORSO_RZ := 0.190
const HIP_Y := 0.245
const HIP_X := 0.088
const SHOULDER := Vector3(0.212, 0.505, -0.012)
const ARM_LEN := 0.175
const HAND_R := 0.076
const LEG_LEN := 0.135
const FOOT_R := 0.100
const ARM_REST_ROLL := 0.30      ## arms hang clear of the bean so the silhouette reads like AC

# --- face grammar (fractions of the head, per STYLE_GUIDE) --------------------------------------
## Head width used for every "% of head width" figure below: 2 * HEAD_R * 1.04 = 0.749 m.
const HEAD_W := HEAD_R * 2.08
## Eye yaw on the head superellipsoid. At n = 2.6 the surface point for yaw 16.8 deg sits at
## x = 0.1029, i.e. centres 0.2058 m apart = 27.5 % of head width *geometrically* — the same figure
## the sphere gave at yaw 17.4, so the mandated 28-35 % as-rendered band (docs/STYLE_GUIDE.md, and
## the orchestrator's standing ruling) is unchanged by the shape pass. The eyes sit ~0.34 m in
## front of the silhouette so they project wider than the geometric figure, and the factor grows as
## the camera closes in; measured values are in the report for this pass.
const EYE_YAW := 16.8
const EYE_PITCH := 1.0             ## vertical middle of the face
## R2.3 ("smaller and less glossy eyes relative to the head, no giant white sclera domes"). The eye
## was 0.092 x 0.116 m = 12.3 % of head width by 17.8 % of head HEIGHT, which is the baby-doll
## register the user rejected. 0.075 x 0.094 is 10.0 % of head width by 14.4 % of head height —
## between AC Isabelle (9 % wide) and Tom Nook (19 %), at the quiet end of the range.
const EYE_HALF_W := 0.0375
const EYE_HALF_H := 0.0470
const EYE_DEPTH := 0.019
## Resting brow: a nearly straight, slightly angled bar above each eye. This is the single strongest
## "not a baby" cue on the face — Tom Nook's dark mask brow, Blathers' heavy brow — and it costs one
## thin arc per eye. It lifts and steepens for "think" (see `_apply_face`).
const BROW_ARC_R := 0.070
const BROW_HALF := 24.0            ## degrees each side of straight up: a shallow, adult brow
const BROW_TUBE := 0.0088
const BROW_LIFT := 0.0755          ## resting height above the eye centre
const BLUSH_YAW := 31.0
const BLUSH_PITCH := -13.0
const MOUTH_PITCH := -20.0
const NOSE_PITCH := -7.5
## R2.3 ("no wide permanent grin"). The old arc was ring 0.072 swept 116 deg: chord + tube 0.147 m
## = 19.6 % of head width but with a 0.034 m CURL, which is a beaming cartoon grin. A much larger
## ring swept much less keeps the width (0.142 m = 19.0 % geometric, still inside the mandated
## 16-25 %) while halving the curl to 0.017 m, so the resting mouth reads as calm, not delighted.
const MOUTH_ARC_R := 0.1020
const MOUTH_HALF := 34.0           ## degrees each side of straight down
const MOUTH_TUBE := 0.0140
const MUZZLE_INSET := 0.006

## Pose channels — everything the animator drives is one float, so states blend by lerp.
enum P {
	BODY_Y, BODY_Z, SQUASH,
	TORSO_PITCH, TORSO_YAW, TORSO_ROLL,
	HEAD_PITCH, HEAD_YAW, HEAD_ROLL,
	ARM_L_PITCH, ARM_L_ROLL, ARM_L_YAW,
	ARM_R_PITCH, ARM_R_ROLL, ARM_R_YAW,
	LEG_L_PITCH, LEG_R_PITCH, LEG_L_LIFT, LEG_R_LIFT,
	EYE_WIDE, EYE_HAPPY, EYE_ROUND, MOUTH_OPEN, BROW,
	EXTRA_A, EXTRA_B,
	COUNT,
}

## Constant hover above the ground (Zorp floats 5 cm).
@export var hover_height: float = 0.0
## Multiplies the SIZE of every face feature (not their spacing, so the "% of head width" figures
## stay put). Small neighbours raise it so their eyes and mouth still read at 6.5 m — scaling the
## whole model down is what made Pip & Pop faceless at gameplay distance.
@export var face_scale: float = 1.0
## How long this character HOLDS its eyes open between blinks, as a multiple of the cast default
## (one blink every 3-5 s). 0.3 is a nervy character that crinkles shut three times as often; 2.0 is
## an unblinking one. MANNER IS A DIFFERENTIATOR AND IT IS FREE — two neighbours with the same face
## read as different creatures if one of them blinks at a different rate.
##
## Why a multiplier on the interval and not a "rest on the happy arcs" state: `_apply_face` applies
## `_eye_open` to `oval.scale.y` ONLY, and the happy arcs are a different mesh that is shown INSTEAD
## of the oval — so a character parked on the arcs would not blink at all, it would simply be a
## character whose eyes are permanently closed and whose blink is invisible.
@export var blink_hold: float = 1.0

## HEAD SHAPE, PER SPECIES. Set these in a subclass `_init()`, which runs before `_build_geometry()`.
##
## Why they are vars and not consts: GDScript will not let a subclass redeclare a parent const —
## it is a hard parse error ("The member HEAD_R already exists in parent class"), so every organic
## neighbour was stuck with one shape. Worse, `superellipsoid()` caches on its arguments, so Zorp,
## Pip, Pop and Mayor Orbit were literally sharing ONE ArrayMesh. "It still looks like it's just a
## reused head" was true at the mesh level.
##
## `_head.scale` was the only lever before this, and it is uniform-only: it shrinks the eyestalks,
## the antenna, the grin and every face feature along with the dome. These let a species change the
## PROPORTIONS of its head while the face-placement maths in `_orient_on_head` follows automatically.
##
## Bolt and DJ Nova ignore all of this — they build their own `rounded_box` heads and never call
## `_add_head_shell` or `_orient_on_head`.
var head_semi: Vector3 = HEAD_SEMI
var head_n: float = HEAD_N
var head_y: float = HEAD_Y
## Shell tessellation. Raising `head_n` concentrates the curvature into a narrow chamfer band, so a
## higher exponent needs MORE segments, never fewer, or the head renders as a faceted box.
var head_segs: Vector2i = Vector2i(44, 22)
## REVERTED 2026-09-05. docs/OPEN_ISSUES.md issue 1 is RESOLVED: the "golf-ball" stipple was Godot's
## PCSS blocker search, fixed by `light_angular_distance = 0` on the sun, so the head no longer has
## to give up its shadow. Default is now false — every neighbour casts a complete ground shadow
## again. The flag is kept (and `set_head_shadow_cheat` with it) purely so the regression can be
## re-measured with a one-line change if the shadow settings are ever touched.
@export var head_shadow_cheat: bool = false

# Face metrics — subclasses may enlarge them (robot screens use chunkier features).
var eye_w: float = EYE_HALF_W
var eye_h: float = EYE_HALF_H
var eye_d: float = EYE_DEPTH
var mouth_w: float = 0.056
var mouth_h: float = 0.048
var mouth_d: float = 0.012

var _state: String = "idle"
var _state_time: float = 0.0
var _emote_done: bool = false
var _time: float = 0.0
var _speed_factor: float = 0.0
var _stride_phase: float = 0.0
var _blend_rate: float = 12.0
var _pose: PackedFloat32Array
var _target: PackedFloat32Array

var _blink_timer: float = 3.0
var _blink_t: float = 0.0
var _eye_open: float = 1.0
var _look_timer: float = 4.0
var _look_hold: float = 0.0
var _look_yaw: float = 0.0
var _look_pitch: float = 0.0

# --- shared rig nodes ---------------------------------------------------------------------------
var _root: Node3D
var _body: Node3D
var _torso_pivot: Node3D           ## rotates at hip height (the AC waddle pivot)
var _torso: Node3D                 ## meshes/head/arms parent — children use feet-relative Y
var _head: Node3D
var _arm_l: Node3D
var _arm_r: Node3D
var _hand_l: Node3D
var _hand_r: Node3D
var _leg_l: Node3D
var _leg_r: Node3D
var _face: Node3D
## THE FIVE PARALLEL EYE ARRAYS. One entry per eye, in the same order and always the same length.
## `_build_eye` is the only thing that appends to them and `_drop_eye` the only thing that removes,
## so they cannot drift apart. `_apply_face` walks all five EVERY FRAME.
var _eyes: Array[Node3D] = []
var _eye_ovals: Array[MeshInstance3D] = []
var _eye_happy: Array[Node3D] = []
var _eye_round: Array[Node3D] = []
## PER-EYE RESTING SIZE, and the reason per-eye sizes are possible at all. `_apply_face` rewrites
## `oval.scale` every frame, so before this array existed it could only rewrite it from the single
## model-wide `eye_w`/`eye_h`/`eye_d` — anything authored per eye on frame 0 was stamped flat on
## frame 1. A graded set of eyes (a big one and two small ones, a squint beside a stare) was
## therefore impossible, not merely awkward. Defaults to `Vector3(eye_w, eye_h, eye_d)`, which is
## exactly what the old code hardcoded.
var _eye_size: Array[Vector3] = []
var _eye_flat: Array[Node3D] = []
var _brows: Array[Node3D] = []
## How far the muzzle patch stands proud of the head shell (0 when the character has no muzzle).
var _muzzle_lift: float = 0.0
## How far the mouth has to open before the closed-mouth smile arc is hidden outright. Below
## this the arc flattens toward nothing, so the two never overlap as separate mouths.
const SMILE_HIDE_AT := 0.34
var _mouth_smile: Node3D
var _mouth_open: Node3D
var _built := false


func _init() -> void:
	_pose = PackedFloat32Array()
	_pose.resize(P.COUNT)
	_target = PackedFloat32Array()
	_target.resize(P.COUNT)
	_reset_pose(_pose)
	_reset_pose(_target)


func _ready() -> void:
	_blink_timer = randf_range(2.0, 4.5) * maxf(blink_hold, 0.05)
	_look_timer = randf_range(3.0, 6.0)
	_time = randf() * 10.0
	if not _built:
		rebuild()


# ============================================================================= public API
## (Re)builds the whole model. Called automatically on _ready.
func rebuild() -> void:
	for c: Node in get_children():
		remove_child(c)
		c.queue_free()
	_eyes.clear()
	_eye_ovals.clear()
	_eye_happy.clear()
	_eye_round.clear()
	_eye_size.clear()
	_eye_flat.clear()
	_brows.clear()
	_mouth_smile = null
	_mouth_open = null
	_muzzle_lift = 0.0
	scale = Vector3.ONE * body_scale
	_root = _node("Root", self, Vector3(0.0, hover_height, 0.0))
	_body = _node("Body", _root, Vector3.ZERO)
	_torso_pivot = _node("TorsoPivot", _body, Vector3(0.0, HIP_Y, 0.0))
	_torso = _node("Torso", _torso_pivot, Vector3(0.0, -HIP_Y, 0.0))
	_head = _node("Head", _torso, Vector3(0.0, head_y, 0.0))
	_arm_l = _node("ArmL", _torso, Vector3(-SHOULDER.x, SHOULDER.y, SHOULDER.z))
	_arm_r = _node("ArmR", _torso, Vector3(SHOULDER.x, SHOULDER.y, SHOULDER.z))
	_leg_l = _node("LegL", _root, Vector3(-HIP_X, HIP_Y, 0.0))
	_leg_r = _node("LegR", _root, Vector3(HIP_X, HIP_Y, 0.0))
	_face = _node("Face", _head, Vector3.ZERO)
	_build_geometry()
	_disable_head_self_shadow()
	_built = true
	_apply_pose(0.016)


## Applies `head_shadow_cheat` (see the export). Now a no-op in the shipping configuration: the flag
## defaults to false, so the head casts like every other part of the body.
func _disable_head_self_shadow() -> void:
	var mode := GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if head_shadow_cheat else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_set_cast_shadow(_head, mode)


## Flips the head-shadow workaround at runtime (see `_disable_head_self_shadow`).
func set_head_shadow_cheat(enabled: bool) -> void:
	head_shadow_cheat = enabled
	if _head != null:
		_disable_head_self_shadow()


static func _set_cast_shadow(root: Node, mode: GeometryInstance3D.ShadowCastingSetting) -> void:
	if root is GeometryInstance3D:
		(root as GeometryInstance3D).cast_shadow = mode
	for c: Node in root.get_children():
		_set_cast_shadow(c, mode)


## Switches animation state ("idle" "walk" "talk" "wave" "happy" "think" "surprised" "dance").
func set_state(new_state: String) -> void:
	if new_state == _state:
		return
	_state = new_state
	_state_time = 0.0
	_emote_done = false
	_blend_rate = 22.0 if new_state == "surprised" else 12.0


func get_state() -> String:
	return _state


func get_state_time() -> float:
	return _state_time


## Duration of a timed emote (0 for looping states).
static func get_emote_duration(emote: String) -> float:
	return float(EMOTE_DURATIONS.get(emote, 0.0))


func emote_duration(emote: String) -> float:
	return get_emote_duration(emote)


## Advances the animation. speed_factor: 0 = standing, 1 = walking.
func tick(delta: float, speed_factor: float) -> void:
	if not _built:
		return
	_time += delta * anim_time_scale
	_state_time += delta
	_speed_factor = speed_factor
	_update_blink(delta)
	_update_look(delta)
	_reset_pose(_target)
	_compute_target(_target, _state_time)
	var k := 1.0 - exp(-_blend_rate * delta)
	for i in P.COUNT:
		_pose[i] = lerpf(_pose[i], _target[i], k)
	_apply_pose(delta)
	_animate_extras(delta)
	if _state in EMOTE_DURATIONS and not _emote_done and _state_time >= float(EMOTE_DURATIONS[_state]):
		_emote_done = true
		emote_finished.emit(_state)


## Current value of a pose channel (subclasses use it in _animate_extras).
func pose(channel: int) -> float:
	return _pose[channel]


# ============================================================================= virtuals
## Subclasses build all meshes here (parents: _torso, _head, _arm_l/_arm_r, _leg_l/_leg_r, _face).
func _build_geometry() -> void:
	pass


## Per-frame motion for species-specific parts (antenna droop, spinning dial, equalizer...).
func _animate_extras(_delta: float) -> void:
	pass


# ============================================================================= animation
func _reset_pose(p: PackedFloat32Array) -> void:
	for i in P.COUNT:
		p[i] = 0.0
	p[P.SQUASH] = 1.0
	p[P.EYE_WIDE] = 1.0


func _update_blink(delta: float) -> void:
	if _blink_t > 0.0:
		_blink_t -= delta
	else:
		_blink_timer -= delta
		if _blink_timer <= 0.0 and _state != "surprised":
			_blink_t = 0.11
			_blink_timer = randf_range(3.0, 5.0) * maxf(blink_hold, 0.05)
	var want := 0.06 if _blink_t > 0.0 else 1.0
	_eye_open = lerpf(_eye_open, want, 1.0 - exp(-38.0 * delta))


func _update_look(delta: float) -> void:
	if _state != "idle":
		_look_yaw = lerpf(_look_yaw, 0.0, 1.0 - exp(-6.0 * delta))
		_look_pitch = lerpf(_look_pitch, 0.0, 1.0 - exp(-6.0 * delta))
		_look_hold = 0.0
		return
	if _look_hold > 0.0:
		_look_hold -= delta
		if _look_hold <= 0.0:
			_look_timer = randf_range(3.0, 6.5)
	else:
		_look_timer -= delta
		if _look_timer <= 0.0:
			_look_hold = randf_range(1.0, 1.8)
			_look_yaw = randf_range(-0.5, 0.5)
			_look_pitch = randf_range(-0.10, 0.08)
		else:
			_look_yaw = lerpf(_look_yaw, 0.0, 1.0 - exp(-5.0 * delta))
			_look_pitch = lerpf(_look_pitch, 0.0, 1.0 - exp(-5.0 * delta))


func _compute_target(p: PackedFloat32Array, t: float) -> void:
	match _state:
		"walk":
			_pose_walk(p)
		"talk":
			_pose_talk(p, t)
		"wave":
			_pose_wave(p, t)
		"happy":
			_pose_happy(p, t)
		"think":
			_pose_think(p, t)
		"surprised":
			_pose_surprised(p, t)
		"dance":
			_pose_dance(p, t)
		_:
			_pose_idle(p)


func _pose_idle(p: PackedFloat32Array) -> void:
	var breathe := sin(TAU * _time / 2.1)
	p[P.BODY_Y] = 0.006 * breathe
	p[P.SQUASH] = 1.0 + 0.015 * breathe
	p[P.TORSO_ROLL] = 0.022 * sin(TAU * _time / 3.9)
	p[P.HEAD_YAW] = _look_yaw
	p[P.HEAD_PITCH] = _look_pitch
	p[P.HEAD_ROLL] = 0.03 * sin(TAU * _time / 4.5)
	p[P.ARM_L_ROLL] = ARM_REST_ROLL + 0.045 * breathe
	p[P.ARM_R_ROLL] = ARM_REST_ROLL + 0.045 * breathe
	p[P.ARM_L_PITCH] = 0.05 * breathe
	p[P.ARM_R_PITCH] = 0.05 * breathe
	p[P.EXTRA_A] = 0.05 * breathe


## AC waddle: short legs swing, whole body rolls side to side, head bobs a beat behind.
func _pose_walk(p: PackedFloat32Array) -> void:
	var ph := _stride_phase
	var s := sin(ph)
	var c := cos(ph)
	var amp := 0.62 * clampf(_speed_factor / 0.7, 0.0, 1.0)
	p[P.LEG_L_PITCH] = amp * s
	p[P.LEG_R_PITCH] = -amp * s
	var air_l := clampf(c * 1.5, 0.0, 1.0)
	var air_r := clampf(-c * 1.5, 0.0, 1.0)
	p[P.LEG_L_LIFT] = 0.035 * air_l - (1.0 - air_l) * LEG_LEN * (1.0 - cos(amp * s))
	p[P.LEG_R_LIFT] = 0.035 * air_r - (1.0 - air_r) * LEG_LEN * (1.0 - cos(amp * s))
	p[P.BODY_Y] = 0.035 * (0.5 + 0.5 * cos(2.0 * ph)) - 0.012
	p[P.SQUASH] = 1.0 + 0.03 * cos(2.0 * ph)
	p[P.TORSO_ROLL] = 0.16 * c            # the waddle
	p[P.TORSO_YAW] = -0.12 * s
	p[P.TORSO_PITCH] = 0.05
	p[P.HEAD_ROLL] = -0.10 * c
	p[P.HEAD_YAW] = 0.06 * s
	p[P.HEAD_PITCH] = -0.03
	p[P.ARM_L_PITCH] = -amp * s * 0.9
	p[P.ARM_R_PITCH] = amp * s * 0.9
	p[P.ARM_L_ROLL] = ARM_REST_ROLL + 0.10
	p[P.ARM_R_ROLL] = ARM_REST_ROLL + 0.10


func _pose_talk(p: PackedFloat32Array, t: float) -> void:
	_pose_idle(p)
	p[P.HEAD_PITCH] += 0.05 * sin(TAU * t * 1.25)
	p[P.HEAD_ROLL] += 0.05 * sin(TAU * t * 0.7)
	p[P.MOUTH_OPEN] = 0.45 + 0.55 * maxf(0.0, sin(TAU * t * 4.2))
	p[P.ARM_R_ROLL] = 0.44 + 0.22 * sin(TAU * t * 1.15)
	p[P.ARM_R_PITCH] = -0.30 + 0.28 * sin(TAU * t * 1.7)
	p[P.ARM_L_ROLL] = 0.24 + 0.10 * sin(TAU * t * 0.9 + 1.0)
	p[P.EXTRA_A] = 1.0


func _pose_wave(p: PackedFloat32Array, t: float) -> void:
	_pose_idle(p)
	var w := sin(TAU * t * 3.6)
	p[P.ARM_R_ROLL] = 2.35 + 0.4 * w
	p[P.ARM_R_PITCH] = -0.2
	p[P.ARM_R_YAW] = 0.28 * w
	p[P.HEAD_ROLL] = -0.16
	p[P.HEAD_YAW] = 0.10
	p[P.TORSO_ROLL] = 0.07
	p[P.EYE_HAPPY] = 1.0
	p[P.MOUTH_OPEN] = 0.35


func _pose_happy(p: PackedFloat32Array, t: float) -> void:
	var hop := absf(sin(TAU * t / 0.62))
	p[P.BODY_Y] = 0.20 * hop
	p[P.SQUASH] = 1.0 + 0.09 * sin(TAU * t / 0.62 * 2.0)
	p[P.LEG_L_LIFT] = 0.20 * hop
	p[P.LEG_R_LIFT] = 0.20 * hop
	p[P.LEG_L_PITCH] = -0.35 * hop
	p[P.LEG_R_PITCH] = -0.35 * hop
	p[P.ARM_L_ROLL] = 2.6 + 0.12 * sin(TAU * t * 3.0)
	p[P.ARM_R_ROLL] = 2.6 - 0.12 * sin(TAU * t * 3.0)
	p[P.ARM_L_PITCH] = 0.12
	p[P.ARM_R_PITCH] = 0.12
	p[P.HEAD_PITCH] = -0.16
	p[P.HEAD_ROLL] = 0.09 * sin(TAU * t * 1.6)
	p[P.EYE_HAPPY] = 1.0
	p[P.MOUTH_OPEN] = 0.85
	p[P.EXTRA_B] = 1.0


func _pose_think(p: PackedFloat32Array, t: float) -> void:
	_pose_idle(p)
	var u := clampf(t / 0.4, 0.0, 1.0)
	p[P.ARM_R_PITCH] = -1.75 * u
	p[P.ARM_R_ROLL] = 0.75 * u
	p[P.ARM_R_YAW] = -0.45 * u
	p[P.HEAD_ROLL] = 0.24 * u + 0.03 * sin(TAU * t * 0.8)
	p[P.HEAD_PITCH] = -0.14 * u
	p[P.HEAD_YAW] = -0.18 * u
	p[P.ARM_L_ROLL] = 0.14
	p[P.BROW] = u
	p[P.MOUTH_OPEN] = 0.0
	p[P.EXTRA_A] = -1.0


## Two-step villager bop — the event space's dance emote.
func _pose_dance(p: PackedFloat32Array, t: float) -> void:
	var beat := TAU * t * 2.0
	var bounce := absf(sin(beat))
	var alt := sin(beat * 0.5)
	p[P.BODY_Y] = 0.055 * bounce
	p[P.SQUASH] = 1.0 + 0.055 * sin(beat * 2.0)
	p[P.TORSO_YAW] = 0.26 * alt
	p[P.TORSO_ROLL] = 0.14 * alt
	p[P.ARM_L_ROLL] = 1.5 + 0.9 * alt
	p[P.ARM_R_ROLL] = 1.5 - 0.9 * alt
	p[P.ARM_L_PITCH] = 0.25
	p[P.ARM_R_PITCH] = 0.25
	p[P.ARM_L_YAW] = 0.35 * alt
	p[P.ARM_R_YAW] = -0.35 * alt
	p[P.LEG_L_LIFT] = 0.05 * clampf(alt, 0.0, 1.0)
	p[P.LEG_R_LIFT] = 0.05 * clampf(-alt, 0.0, 1.0)
	p[P.HEAD_ROLL] = 0.16 * alt
	p[P.HEAD_YAW] = 0.10 * sin(beat)
	p[P.MOUTH_OPEN] = 0.55
	p[P.EYE_HAPPY] = 1.0
	p[P.EXTRA_B] = 1.0


func _pose_surprised(p: PackedFloat32Array, t: float) -> void:
	var hop := sin(clampf(t / 0.3, 0.0, 1.0) * PI)
	p[P.BODY_Y] = 0.15 * hop
	p[P.BODY_Z] = 0.26 * clampf(t / 0.3, 0.0, 1.0)
	p[P.SQUASH] = 1.07
	p[P.ARM_L_ROLL] = 1.45
	p[P.ARM_R_ROLL] = 1.45
	p[P.ARM_L_PITCH] = -0.45
	p[P.ARM_R_PITCH] = -0.45
	p[P.LEG_L_PITCH] = 0.35 * hop
	p[P.LEG_R_PITCH] = -0.35 * hop
	p[P.TORSO_PITCH] = -0.16
	p[P.HEAD_PITCH] = -0.12
	p[P.EYE_ROUND] = 1.0
	p[P.EYE_WIDE] = 1.35
	p[P.MOUTH_OPEN] = 1.0
	p[P.EXTRA_B] = 1.0


func _apply_pose(delta: float) -> void:
	var p := _pose
	if _state == "walk" and _speed_factor > 0.05:
		var cadence := 2.55 * sqrt(maxf(_speed_factor, 0.15))
		var prev := _stride_phase
		_stride_phase += TAU * cadence * 0.5 * delta
		if _crossed(prev, _stride_phase, PI * 0.5):
			footstep.emit(0)
		if _crossed(prev, _stride_phase, PI * 1.5):
			footstep.emit(1)
		if _stride_phase > TAU:
			_stride_phase -= TAU
	elif _state != "walk":
		_stride_phase = lerpf(_stride_phase, 0.0, 1.0 - exp(-10.0 * delta))

	var sq := p[P.SQUASH]
	var xz := 1.0 / sqrt(maxf(sq, 0.2))
	_root.scale = Vector3(xz, sq, xz)
	_body.position = Vector3(0.0, p[P.BODY_Y], p[P.BODY_Z])
	_torso_pivot.rotation = Vector3(p[P.TORSO_PITCH], p[P.TORSO_YAW], -p[P.TORSO_ROLL])
	_head.rotation = Vector3(p[P.HEAD_PITCH], p[P.HEAD_YAW], p[P.HEAD_ROLL])
	_arm_l.rotation = Vector3(p[P.ARM_L_PITCH], p[P.ARM_L_YAW], -p[P.ARM_L_ROLL])
	_arm_r.rotation = Vector3(p[P.ARM_R_PITCH], -p[P.ARM_R_YAW], p[P.ARM_R_ROLL])
	_leg_l.rotation = Vector3(p[P.LEG_L_PITCH], 0.0, 0.0)
	_leg_r.rotation = Vector3(p[P.LEG_R_PITCH], 0.0, 0.0)
	_leg_l.position = Vector3(-HIP_X, HIP_Y + p[P.LEG_L_LIFT], 0.0)
	_leg_r.position = Vector3(HIP_X, HIP_Y + p[P.LEG_R_LIFT], 0.0)
	_apply_face(p)


func _apply_face(p: PackedFloat32Array) -> void:
	var brow := p[P.BROW]
	var happy := p[P.EYE_HAPPY] > 0.5
	var round_eye := p[P.EYE_ROUND] > 0.5
	var flat := brow > 0.5 and not _eye_flat.is_empty()
	var wide := p[P.EYE_WIDE]
	var fs := face_scale
	for i in _eye_ovals.size():
		var oval := _eye_ovals[i]
		oval.visible = not happy and not round_eye and not flat
		if oval.visible:
			# PER EYE, not model-wide (see `_eye_size`). The fallback keeps a subclass that has
			# pulled an eye out of four arrays but not the fifth rendering instead of crashing.
			var sz: Vector3 = _eye_size[i] if i < _eye_size.size() else Vector3(eye_w, eye_h, eye_d)
			oval.scale = Vector3(sz.x * fs * wide, sz.y * fs * wide * _eye_open, sz.z)
	for n: Node3D in _eye_happy:
		n.visible = happy
	for n2: Node3D in _eye_round:
		n2.visible = round_eye and not happy
	for n3: Node3D in _eye_flat:
		n3.visible = flat and not happy and not round_eye
	# R2.3: the brow is part of the RESTING face now (it is what keeps these off the baby-doll
	# register), so it is always drawn; "think" lifts it and steepens its slant.
	for b: Node3D in _brows:
		b.position.y = float(b.get_meta("base_y", 0.0)) + 0.024 * brow * fs
		b.rotation.z = float(b.get_meta("base_roll", 0.0)) * 1.5 * brow
	if _mouth_open:
		var mo := clampf(p[P.MOUTH_OPEN], 0.0, 1.0)
		_mouth_open.visible = mo > 0.02
		if _mouth_open.visible:
			_mouth_open.scale = Vector3(mouth_w * fs * (0.62 + 0.38 * mo), maxf(0.0012, mouth_h * fs * mo), mouth_d)
		if _mouth_smile:
			# TWO MOUTHS BUG. The smile arc IS the closed mouth; the ellipse below is the open one.
			# This used to squash the arc to 5-10% of its height and leave it VISIBLE, so a talking
			# neighbour showed the open mouth with a thin line still drawn across it — reported as
			# "two mouths, one thin one that talks and another big open one". The arc now closes
			# out completely before the ellipse is wide enough to read as a mouth of its own.
			_mouth_smile.visible = mo < SMILE_HIDE_AT
			if _mouth_smile.visible:
				_mouth_smile.scale = Vector3(1.0, maxf(0.05, 1.0 - mo / SMILE_HIDE_AT), 1.0)


static func _crossed(a: float, b: float, mark: float) -> bool:
	return a < mark and b >= mark


# ============================================================================= shared AC parts
## Wide head shell — a superellipsoid, not a ball (R2.3). Flat-ish cheeks, brow and crown with soft
## chamfered corners. `_orient_on_head` uses the same surface, so the face lands on it exactly.
## Adds a chamfer seam around the crown so the top plane reads as a plane. Returns the shell mesh.
func _add_head_shell(color: Color, opts: Dictionary = {}) -> MeshInstance3D:
	var mi := _mi(superellipsoid(head_semi, head_n, head_segs.x, head_segs.y), _toon(color, _matte(opts)), _head, Vector3.ZERO, "HeadShell")
	if bool(opts.get("crown_seam", true)):
		var seam_col: Color = opts.get("seam_color", color.darkened(0.16))
		# The seam disc's own edge sits at 0.795 of the head's x semi-axis, so the height that puts
		# that edge exactly ON the shell is (1 - 0.795^n)^(1/n) — which is 0.7351 at the default
		# n = 2.6, i.e. the 0.735 literal this replaces. Deriving it keeps the seam welded to the
		# shell for any species that changes `head_n`.
		var seam_frac := pow(1.0 - pow(0.795, head_n), 1.0 / head_n)
		# `_se_slab`, not a flat `superellipsoid()` — see that helper. Built the old way this seam
		# reached 37 % of its own radius and was buried inside the shell on EVERY character.
		#
		# IT TAKES THE HEAD'S OWN `head_n` AND `head_segs.x`, NOT CONSTANTS. Hard-coded at n 2.8
		# and seg 30 it rendered as a DASHED zigzag of light triangles across the forehead: an
		# 18-gon slab sitting flush on a 26-gon shell pokes out at its own vertices and sinks
		# between them. Sharing the exponent makes the two cross-sections the same CURVE, and
		# sharing the radial count puts their vertices on the same rays, so the seam can only be
		# uniformly proud. SEAM_PROUD is what makes it proud rather than co-planar — a hard rim is
		# the point of the part, and flush geometry z-fights.
		# Radial count is CAPPED at the head's, not simply copied: Fen's 50-segment shell would
		# spend 360 tris on a 6 mm rim and put her at 5998 of the 6000 budget. Being proud is what
		# makes the cap safe — an 18-gon inscribed in a 30-gon dips to 1.02*cos(PI/18) = 1.005 of
		# the shell at its edge midpoints, so it is still outside everywhere and cannot dash.
		var seam := _se_slab(_head, Vector2(head_semi.x * 0.795, head_semi.z * 0.795) * SEAM_PROUD,
			head_semi.y * 0.10, head_n, _toon(seam_col, _matte({"rim": 0.02})),
			Vector3(0.0, head_semi.y * seam_frac, 0.012), "CrownSeam", mini(head_segs.x, 30))
		seam.rotation.x = -0.06
	return mi


## Squat bean torso — a superellipsoid with a flat chest plane and a chamfered waist, so it has an
## upper and a lower half instead of reading as one balloon. Returns the mesh instance.
func _add_torso_bean(color: Color, opts: Dictionary = {}) -> MeshInstance3D:
	var k: Vector3 = opts.get("size_mul", Vector3.ONE)
	var semi := Vector3(TORSO_RX * k.x, TORSO_RY * k.y, TORSO_RZ * k.z)
	var mi := _mi(superellipsoid(semi, TORSO_N, 20, 12),
		_toon(color, _matte(opts)), _torso, Vector3(0.0, TORSO_Y, 0.0), "Torso")
	if bool(opts.get("waist_chamfer", true)):
		var chamfer: Color = opts.get("chamfer_color", color.darkened(0.14))
		# `_se_slab`, not a flat `superellipsoid()` — see that helper. Built the old way this
		# chamfer reached 31 % of its own radius and never appeared on any character. It takes the
		# TORSO's own exponent and radial count for the same reason the crown seam takes the
		# head's: a slab on a different polygon than the shell it rings renders dashed.
		_se_slab(_torso, Vector2(semi.x * 0.965, semi.z * 0.965), semi.y * 0.085, TORSO_N,
			_toon(chamfer, _matte({"rim": 0.02})),
			Vector3(0.0, TORSO_Y - semi.y * 0.50, 0.0), "WaistChamfer", 20)
	return mi


## Muzzle patch around the nose and mouth — the villager snout every AC character has. R2.3: it is
## now a superellipsoid (a jaw PLANE with a chamfered edge, not a snout ball) and callers pass a
## colour much closer to the skin, because a bright white oval on a coloured head is half of the
## teddy-bear read the user rejected.
func _add_muzzle(color: Color, pitch_deg: float = -14.5, size3: Vector3 = Vector3(0.118, 0.086, 0.019)) -> void:
	var muzzle := _node("Muzzle", _face, Vector3.ZERO)
	_orient_on_head(muzzle, 0.0, pitch_deg, MUZZLE_INSET)
	_mi(superellipsoid(size3 * face_scale, 2.7, 14, 8), _toon(color, _matte({"rim": 0.03, "spec": 0.0})),
		muzzle, Vector3.ZERO, "Patch")
	# remember how far the patch stands proud of the shell, so the nose and smile are pushed out in
	# front of it. Without this they sink inside the muzzle and it renders as a featureless blob.
	_muzzle_lift = size3.z * face_scale - MUZZLE_INSET


## Short stub arms ending in mitten hands. The shoulder is a bevelled cap and the mitt is a
## superellipsoid (R2.3), so the arm is a tapered form with a knuckle plane rather than three balls.
## `fingers` draws 3 little bumps (Zorp's hands).
## `hand_opts` / `sleeve_opts` exist so a species can put SKIN TEXTURE on its bare parts. Spots that
## stop at the jaw look like a mask, so whatever the head wears the hands and arms need too. They are
## separate dicts because a sleeve is often cloth while the hand is bare.
func _add_arms(sleeve: Color, hand_color: Color, fingers: int = 0, hand_opts: Dictionary = {},
		sleeve_opts: Dictionary = {}) -> void:
	var m_sleeve := _toon(sleeve, _matte(sleeve_opts))
	var m_cuff := _toon(sleeve.darkened(0.16), _matte(sleeve_opts))
	var m_hand := _toon(hand_color, _matte(hand_opts))
	var sides: Array = [[-1.0, _arm_l], [1.0, _arm_r]]
	for side: Array in sides:
		var sx: float = side[0]
		var arm: Node3D = side[1]
		_mi(superellipsoid(Vector3(0.074, 0.066, 0.070), 2.6, 12, 7), m_sleeve, arm, Vector3.ZERO, "Shoulder")
		var upper := _mi(capsule(0.055, ARM_LEN, 12, 3), m_sleeve, arm, Vector3(0.0, -ARM_LEN * 0.5 + 0.01, 0.0), "Upper")
		upper.rotation.z = -0.06 * sx
		# cuff: a hard edge where the sleeve ends, so the arm is not one continuous sausage
		_mi(superellipsoid(Vector3(0.062, 0.017, 0.060), 2.9, 10, 5), m_cuff, arm, Vector3(0.0, -ARM_LEN - 0.004, 0.0), "Cuff")
		var hand := _node("Hand", arm, Vector3(0.0, -ARM_LEN - 0.030, 0.0))
		_mi(superellipsoid(Vector3(HAND_R, HAND_R * 1.06, HAND_R * 0.90), HAND_N, 14, 8), m_hand, hand, Vector3.ZERO, "Mitten")
		for f in fingers:
			var a := deg_to_rad(-38.0 + 38.0 * f)
			_mi(superellipsoid(Vector3(HAND_R * 0.40, HAND_R * 0.44, HAND_R * 0.40), 2.4, 8, 5), m_hand, hand,
				Vector3(sin(a) * HAND_R * 0.70, -HAND_R * 0.60, -cos(a) * HAND_R * 0.70), "Finger")
		if sx < 0.0:
			_hand_l = hand
		else:
			_hand_r = hand


## Stubby legs with chunky boots: a superellipsoid shoe with a genuinely FLAT sole and a flat top
## plane, plus a thin sole plate and a toe cap so the foot reads as a shoe and not a squashed ball.
## `leg_opts` carries skin texture onto a bare leg. The BOOT materials below are deliberately left
## alone — a boot is not skin.
func _add_legs(leg_color: Color, foot_color: Color, leg_opts: Dictionary = {}) -> void:
	var m_leg := _toon(leg_color, _matte(leg_opts))
	var m_foot := _toon(foot_color, _matte({"spec": 0.06}))
	var m_sole := _toon(foot_color.darkened(0.30), _matte({"spec": 0.0}))
	for leg: Node3D in [_leg_l, _leg_r]:
		_mi(capsule(0.056, LEG_LEN, 12, 3), m_leg, leg, Vector3(0.0, -LEG_LEN * 0.42, 0.0), "Leg")
		var foot_y := -HIP_Y + 0.064
		_mi(superellipsoid(Vector3(FOOT_R * 0.95, 0.062, FOOT_R * 1.22), FOOT_N, 14, 8), m_foot, leg,
			Vector3(0.0, foot_y, -0.022), "Foot")
		_mi(superellipsoid(Vector3(FOOT_R * 0.97, 0.016, FOOT_R * 1.24), 3.4, 12, 5), m_sole, leg,
			Vector3(0.0, foot_y - 0.050, -0.022), "Sole")
		_mi(superellipsoid(Vector3(FOOT_R * 0.80, 0.030, FOOT_R * 0.34), 2.9, 10, 5), m_sole, leg,
			Vector3(0.0, foot_y + 0.024, -0.022 - FOOT_R * 0.92), "ToeCap")


## The whole AC face in one call: two small dark vertical-oval eyes under a resting brow, a soft
## rounded nose, a calm smile with a real open mouth, optional blush, plus the happy "^ ^" /
## surprised "O O" variants. Every size is multiplied by `face_scale`.
##
## R2.3 changes: the eyes are ~28 % smaller in area, the specular glint is a small dull off-white
## dot instead of a big pure-white one, the brow is visible AT REST (the strongest "not a baby"
## cue), and `opts.blush = false` turns blush off entirely for the robots.
## R4 (CAST VARIETY). The two-eye loop is gone; `opts.eyes` is a LIST OF EYE SPECS and the default
## list is exactly the two eyes this function always built, so every existing call site is untouched.
## `opts.mouth = false` and `opts.brows = false` are the switches that replace the hand-rolled
## "build it then free it" loops four model files had each written out by hand.
##
## THE TRAP, WRITTEN DOWN BECAUSE THREE FILES HAVE HIT IT: you cannot turn a face part off by giving
## it a transparent colour. `toon_soft` is OPAQUE, so an alpha-0 blush renders as two BLACK ovals on
## the cheeks. The boolean switches are the only way.
func _add_face(eye_color: Color, mouth_color: Color, blush_color: Color, opts: Dictionary = {}) -> void:
	var inset: float = opts.get("inset", 0.004)
	## Eyes may sit proud of the shell (Mayor Orbit's sit on top of his goggle lenses) while the
	## mouth, nose and blush stay flush — hence a separate inset for them.
	var eye_inset: float = opts.get("eye_inset", inset)
	var m_eye := _toon(eye_color, {"spec": 0.0, "rim": 0.0, "shade": 0.08})
	var m_hl := _toon(GLINT, {"spec": 0.0, "rim": 0.0, "shade": 0.02})
	var m_mouth := _toon(mouth_color, {"spec": 0.0, "rim": 0.0, "shade": 0.06})
	var brow_col: Color = opts.get("brow_color", eye_color)
	var m_brow := _toon(brow_col, {"spec": 0.0, "rim": 0.0, "shade": 0.05})
	var eyes: Array = opts.get("eyes", [{"yaw": -EYE_YAW}, {"yaw": EYE_YAW}])
	for e: Dictionary in eyes:
		var spec := e.duplicate()
		spec["inset"] = spec.get("inset", eye_inset)
		spec["brow"] = spec.get("brow", bool(opts.get("brows", true)))
		spec["fit_expr"] = spec.get("fit_expr", bool(opts.get("fit_expr", false)))
		_build_eye(spec, m_eye, m_hl, m_brow)
	# the nose and smile ride on top of the muzzle patch, not on the shell underneath it
	if bool(opts.get("nose", true)):
		_add_nose(Color(opts.get("nose_color", mouth_color)), inset - _muzzle_lift - 0.004)
	if bool(opts.get("mouth", true)):
		_add_mouth(m_mouth, Color(opts.get("mouth_inner", Color("#8c3b52"))), inset - _muzzle_lift - 0.002)
	if bool(opts.get("blush", true)):
		_add_blush(blush_color, inset)


## ONE EYE, and the only thing in this file that appends to the five parallel eye arrays. Everything
## a face can vary about an eye lives here so a species is a LIST OF SPECS rather than a new loop.
##
## spec keys (all optional):
##   w / h / d      resting half-size; defaults to the model-wide `eye_w`/`eye_h`/`eye_d`. Stored in
##                  `_eye_size`, which is what makes a graded set of eyes survive `_apply_face`.
##   yaw / pitch    degrees on the head superellipsoid (`_orient_on_head`). pitch defaults EYE_PITCH.
##   inset          how far into the shell, negative to sit proud of it.
##   parent / pos   place the eye at `pos` under `parent` INSTEAD of on the head — for a faceplate.
##   shape          "oval" (default sphere) | "almond" (a four-pointed DIAMOND, not a lens — see
##                  the warning on `_eye_mesh`) | "bar" (a hard rounded rectangle) | "pixel" (a
##                  chunky square). All are UNIT meshes, because `_apply_face` owns the scale.
##   slant_deg      rolls the whole eye — oval, arcs and brow together — on a child node.
##   brow           false drops the resting brow bar (ruling: the hard vocabulary is capped).
##   sclera         a Color adds a pale backing disc, so the dark oval reads as a PUPIL.
##   glint          false drops the specular dot.
##   fit_expr       see below.
##
## FIT_EXPR — the "surprised makes small eyes GROW" bug. The happy "^" arc and the surprise "O" ball
## are authored at fixed chibi sizes and were never scaled by the eye they belong to, so a character
## with a small pupil visibly gained eye area at the exact moment its expression was meant to read.
## GrigModel compensated by hand with two magic scale numbers. The fix is graded:
##   * ALWAYS, and for free: the expression nodes are scaled by this eye's size RELATIVE TO THE
##     MODEL-WIDE `eye_w`/`eye_h`. For every character shipped before R4 that ratio is exactly 1, so
##     nothing moves — but a per-eye size now carries its own expressions with it, which is the bug
##     `_eye_size` would otherwise have introduced.
##   * OPT IN with `fit_expr = true`: scale against the chibi CONSTANTS instead, which additionally
##     fixes the model-wide case (Zorp, Fen and Grig all run eyes well off the chibi default). It is
##     opt-in because it changes those three characters' expressions, and that is a design decision
##     belonging to their files, not to this one.
func _build_eye(spec: Dictionary, m_eye: Material, m_hl: Material, m_brow: Material) -> Node3D:
	var fs := face_scale
	var idx := _eyes.size()
	var w: float = float(spec.get("w", eye_w))
	var h: float = float(spec.get("h", eye_h))
	var d: float = float(spec.get("d", eye_d))
	var yaw: float = float(spec.get("yaw", 0.0))
	var eye := _node("Eye%d" % idx, spec.get("parent", _face), Vector3.ZERO)
	if spec.has("pos"):
		eye.position = spec["pos"]
	else:
		_orient_on_head(eye, yaw, float(spec.get("pitch", EYE_PITCH)), float(spec.get("inset", 0.004)))
	_eyes.append(eye)
	_eye_size.append(Vector3(w, h, d))
	# The slant goes on a CHILD. `_add_eyestalks` overwrites `eye.basis` outright when it lifts an
	# eye onto a stalk, so a roll written on the eye node itself would silently vanish there.
	var host := eye
	var slant: float = float(spec.get("slant_deg", 0.0))
	if not is_zero_approx(slant):
		host = _node("Slant", eye, Vector3.ZERO)
		host.rotation.z = deg_to_rad(slant)
	# A SCLERA IS A PALE BALL WITH THE PUPIL PROUD OF IT, which is the arrangement `_add_eyestalks`
	# already ships and the only one that works here. Nesting the sclera INSIDE the dark oval reads
	# well on paper — it would inherit the blink squash — but the maths kills it: to stay behind the
	# pupil at the pupil's own silhouette the sclera's front can never get further forward than
	# ~0.24 of the eye depth, which is less than the 4 mm the eye is inset into the shell, so it
	# renders half-buried in the head. Measured on the first build; it looked like a bandage.
	# So: sclera as a SIBLING, and the whole pupil stack pushed out in front of it.
	var lift_z := 0.0
	if spec.has("sclera"):
		var sm: float = float(spec.get("sclera_mul", 1.50))
		var lift: float = float(spec.get("sclera_lift", d * 0.55))
		var m_sc := _toon(Color(spec["sclera"]), _matte({"spec": 0.04, "rim": 0.02}))
		_mi(sphere(1.0, 14, 8), m_sc, host, Vector3(0.0, 0.0, -lift), "Sclera").scale = \
			Vector3(w * fs * sm, h * fs * sm, d * 1.2)
		lift_z = lift + d * 1.03
	var mesh := _eye_mesh(String(spec.get("shape", "oval")))
	var oval := _mi(mesh, m_eye, host, Vector3.ZERO, "Oval")
	if lift_z != 0.0:
		oval.position.z = -lift_z
	oval.scale = Vector3(w * fs, h * fs, d)
	_eye_ovals.append(oval)
	if bool(spec.get("glint", true)):
		_add_glint(oval, m_hl)
	var ref_w: float = EYE_HALF_W if bool(spec.get("fit_expr", false)) else eye_w
	var ref_h: float = EYE_HALF_H if bool(spec.get("fit_expr", false)) else eye_h
	var expr := Vector3(w / maxf(ref_w, 1e-4), h / maxf(ref_h, 1e-4), 1.0)
	# happy "^ ^" — ONE solid arc, the same grammar the robots use. Both expression meshes ride the
	# same `lift_z` as the pupil, or a sclera'd eye would show its arc INSIDE the pale ball.
	var happy := _node("Happy", host, Vector3(0.0, -0.006 * fs, -0.004 - lift_z))
	_mi(arc_tube(0.042 * fs, 0.0115 * fs, deg_to_rad(24.0), deg_to_rad(156.0), 12, 6), m_eye, happy, Vector3.ZERO, "Arc")
	happy.visible = false
	happy.scale = expr
	_eye_happy.append(happy)
	# surprised "O O" — one solid round eye, a little bigger than the resting oval
	var round_eye := _node("Round", host, Vector3(0.0, 0.003, -0.002 - lift_z))
	var ball := _mi(sphere(1.0, 12, 7), m_eye, round_eye, Vector3.ZERO, "Ball")
	ball.scale = Vector3(0.043 * fs, 0.048 * fs, d)
	round_eye.visible = false
	round_eye.scale = expr
	_eye_round.append(round_eye)
	# brow: visible AT REST as a shallow near-straight bar, lifting and steepening for "think"
	if bool(spec.get("brow", true)):
		_add_brow(host, m_brow, float(spec.get("sx", -1.0 if yaw < 0.0 else 1.0)))
	return eye


## The unit meshes an eye can be cut from. All are -1..1 in every axis, because `_apply_face` owns
## `oval.scale` and would flatten anything pre-sized. "oval" is the shipped sphere.
static func _eye_mesh(shape: String) -> Mesh:
	match shape:
		"almond":
			# WARNING — THIS IS NOT AN ALMOND, AND THE NAME IS KEPT ONLY BECAUSE IT IS THE `shape`
			# string. n < 2 pulls the DIAGONALS in while the axes stay at 1.0, so what comes out is
			# a rounded OCTAHEDRON: a four-pointed diamond with points at top, bottom and both ends.
			# It is a diamond eye, which is a real and usable look — it is just not a lens.
			#
			# A TRUE LENS CANNOT BE ONE SUPERELLIPSOID (the two side points need the profile to be
			# convex between them, which a single radial projection will not give you). The working
			# recipe is Pop's, in twin_model.gd `_cut_almond_eyes()`: a rounded rectangle at n ~2.4
			# for the fat lobe, PLUS one cone carrying the taper out to a single point. Copy that if
			# you want a lens; do not reach for this expecting one.
			return superellipsoid(Vector3.ONE, 1.55, 14, 8)
		"bar":
			return rounded_box(Vector3(2.0, 2.0, 2.0), 0.90, 12)
		"pixel":
			return rounded_box(Vector3(2.0, 2.0, 2.0), 0.34, 10)
		_:
			return sphere(1.0, 14, 8)


## Removes one eye from ALL FIVE parallel arrays and then frees it. `remove_child` first, because
## `queue_free` alone runs at the END of the frame and would leave the eye visible for one frame.
##
## This exists because doing it by hand is a crash: an index that outlives its node fires on the
## very next blink, and it is five arrays now, not four.
func _drop_eye(index: int) -> void:
	if index < 0 or index >= _eyes.size():
		return
	var dead: Node3D = _eyes[index]
	_eyes.remove_at(index)
	if index < _eye_ovals.size():
		_eye_ovals.remove_at(index)
	if index < _eye_happy.size():
		_eye_happy.remove_at(index)
	if index < _eye_round.size():
		_eye_round.remove_at(index)
	if index < _eye_size.size():
		_eye_size.remove_at(index)
	if index < _eye_flat.size():
		_eye_flat.remove_at(index)
	# The brow is a CHILD of the eye, so it dies with it — and `_brows` is walked every frame, so
	# the entry has to go first or `_apply_face` reads a freed node on the next tick.
	for b: Node3D in _brows.duplicate():
		if b == dead or dead.is_ancestor_of(b):
			_brows.erase(b)
	var parent := dead.get_parent()
	if parent != null:
		parent.remove_child(dead)
	dead.queue_free()


## The eye glint. R2.3 asked for "less glossy eyes": the old dot was pure #ffffff at 0.34 x 0.26 of
## the eye, which is the wet anime highlight. This is 0.19 x 0.15 in a dulled bone white, so the eye
## still has life at close range and reads as a flat dark shape at gameplay distance.
const GLINT := Color("#ded9ce")

func _add_glint(oval: MeshInstance3D, m_hl: Material) -> void:
	_mi(sphere(1.0, 8, 4), m_hl, oval, Vector3(0.36, 0.40, -0.52), "Glint").scale = Vector3(0.19, 0.15, 0.72)


## One resting brow bar above an eye. Nearly straight (a 48 deg sweep of a large ring), angled down
## toward the nose, in the eye's own ink. `_apply_face` lifts and steepens it for "think".
func _add_brow(eye: Node3D, m_brow: Material, sx: float) -> void:
	var fs := face_scale
	var brow_y := BROW_LIFT * fs
	var brow := _node("Brow", eye, Vector3(0.0, brow_y, -0.004))
	brow.set_meta("base_y", brow_y)
	var a0 := deg_to_rad(90.0 - BROW_HALF)
	var a1 := deg_to_rad(90.0 + BROW_HALF)
	var barc := _mi(arc_tube(BROW_ARC_R * fs, BROW_TUBE * fs, a0, a1, 8, 5), m_brow, brow,
		Vector3(0.0, -BROW_ARC_R * fs * cos(deg_to_rad(BROW_HALF)), 0.0), "Arc")
	barc.rotation.z = deg_to_rad(7.0 * sx)
	brow.set_meta("base_roll", barc.rotation.z)
	_brows.append(brow)


## Soft rounded wedge, built from four overlapping lobes so it never reads as a dark rectangle.
## R2.3: the lobes are superellipsoids and the whole nose is ~12 % smaller, so it reads as a small
## structured muzzle tip instead of a shiny button.
func _add_nose(color: Color, inset: float) -> void:
	var fs := face_scale
	var nose := _node("Nose", _face, Vector3.ZERO)
	_orient_on_head(nose, 0.0, NOSE_PITCH, inset)
	var m := _toon(color, {"spec": 0.04, "spec_size": 90.0, "rim": 0.0, "shade": 0.10})
	var lobes: Array = [
		[Vector3(-0.0140, 0.0055, -0.0025), Vector3(0.0138, 0.0110, 0.0080)],
		[Vector3(0.0140, 0.0055, -0.0025), Vector3(0.0138, 0.0110, 0.0080)],
		[Vector3(0.0, -0.0085, -0.0020), Vector3(0.0120, 0.0115, 0.0076)],
		[Vector3(0.0, 0.0030, -0.0038), Vector3(0.0174, 0.0115, 0.0085)],
	]
	for lobe: Array in lobes:
		var pos: Vector3 = lobe[0] * fs
		var siz: Vector3 = lobe[1] * fs
		_mi(superellipsoid(siz, 2.5, 8, 5), m, nose, pos, "Lobe")


## A calm, wide smile plus a real open mouth: dark lip ring, lighter interior, small tongue — so
## "talk" / "happy" / "surprised" read as a mouth instead of a hole punched in a white blob.
## R2.3: the arc is a big ring swept only 68 deg, so the resting mouth is a soft curve at the same
## WIDTH as before but with half the curl — no permanent beaming grin.
func _add_mouth(m_mouth: Material, inner: Color, inset: float) -> void:
	var fs := face_scale
	var mouth := _node("Mouth", _face, Vector3.ZERO)
	_orient_on_head(mouth, 0.0, MOUTH_PITCH, inset)
	_mouth_smile = _smile_arc(m_mouth, mouth, MOUTH_ARC_R * fs, MOUTH_TUBE * fs, -0.002)
	var open := _node("Open", mouth, Vector3(0.0, -0.014 * fs, -0.003))
	# The dark lip is the outline; the interior and the tongue are stacked in FRONT of it, each a
	# little smaller, so the dark rim always frames them. (Nesting the interior *inside* the lip let
	# it poke through the low-poly lip's facets as two maroon specks that read as nostrils.)
	_mi(sphere(1.0, 14, 8), m_mouth, open, Vector3.ZERO, "Lip")
	var m_inner := _toon(inner, {"spec": 0.0, "rim": 0.0, "shade": 0.10})
	_mi(sphere(1.0, 12, 7), m_inner, open, Vector3(0.0, 0.04, -0.62), "Inner").scale = Vector3(0.70, 0.60, 0.50)
	var m_tongue := _toon(Color("#e8788f"), {"spec": 0.0, "rim": 0.0, "shade": 0.12})
	_mi(sphere(1.0, 10, 5), m_tongue, open, Vector3(0.0, -0.40, -0.90), "Tongue").scale = Vector3(0.44, 0.30, 0.40)
	_mouth_open = open
	_mouth_open.scale = Vector3(mouth_w * fs, 0.0008, mouth_d)


## One continuous smile arc, anchored so its ENDPOINTS sit at y = 0 and it hangs down from there.
## Shared by the organic faces and the robot faceplates so both get exactly the same mouth curve.
func _smile_arc(m_mouth: Material, parent: Node3D, ring_r: float, tube_r: float, z: float) -> MeshInstance3D:
	var a0 := deg_to_rad(270.0 - MOUTH_HALF)
	var a1 := deg_to_rad(270.0 + MOUTH_HALF)
	var y := ring_r * cos(deg_to_rad(MOUTH_HALF))
	return _mi(arc_tube(ring_r, tube_r, a0, a1, 14, 6), m_mouth, parent, Vector3(0.0, y, z), "Smile")


## Two soft blush ovals low on the cheeks, wider than tall. R2.3 asks for "restrained blush (or
## none on the robots)": the patch is ~30 % smaller than the first pass and callers pass a dusty,
## desaturated rose rather than a hot pink. Robots pass `blush = false` and get none at all.
func _add_blush(blush_color: Color, inset: float = 0.003) -> void:
	var m := _toon(blush_color, {"spec": 0.0, "rim": 0.02, "shade": 0.12})
	for sx: float in [-1.0, 1.0]:
		var b := _node("Blush", _face, Vector3.ZERO)
		_orient_on_head(b, BLUSH_YAW * sx, BLUSH_PITCH, inset)
		var mi := _mi(sphere(1.0, 10, 5), m, b, Vector3.ZERO, "Oval")
		mi.scale = Vector3(0.050 * face_scale, 0.029 * face_scale, 0.012)


## The AC face drawn on a flat robot faceplate (`parent` faces -Z). Every expression is ONE solid
## mesh — a filled oval, a single "^" arc, a single "O" ring, a single "-" dash — so the face is
## never a scatter of disconnected blocks. Fills the same eye arrays as the organic villagers, so
## `_apply_face` drives blink / happy / surprised / thinking identically across species.
func _add_flat_eyes(parent: Node3D, spacing: float, y_off: float, m_dark: Material, m_hl: Material) -> void:
	var fs := face_scale
	for i in 2:
		var sx := -1.0 if i == 0 else 1.0
		var eye := _node("Eye%d" % i, parent, Vector3(spacing * 0.5 * sx, y_off, 0.0))
		_eyes.append(eye)
		var oval := _mi(sphere(1.0, 14, 8), m_dark, eye, Vector3.ZERO, "Oval")
		oval.scale = Vector3(eye_w * fs, eye_h * fs, eye_d)
		_eye_ovals.append(oval)
		# The FIFTH parallel array has to be fed here too, or a screen face and an organic face
		# disagree about how many eyes exist and `_apply_face` indexes past the end.
		_eye_size.append(Vector3(eye_w, eye_h, eye_d))
		if m_hl != null:
			_add_glint(oval, m_hl)
		# happy "^ ^" — one solid arc
		var happy := _node("Happy", eye, Vector3(0.0, -0.006 * fs, -0.002))
		_mi(arc_tube(eye_w * fs * 1.10, eye_w * fs * 0.30, deg_to_rad(24.0), deg_to_rad(156.0), 12, 6), m_dark, happy, Vector3.ZERO, "Arc")
		happy.visible = false
		_eye_happy.append(happy)
		# surprised "O O" — one solid ring
		var round_eye := _node("Round", eye, Vector3(0.0, 0.002, -0.002))
		var ring := _mi(torus(eye_w * fs * 0.60, eye_w * fs * 1.16, 16, 5), m_dark, round_eye, Vector3.ZERO, "Ring")
		ring.rotation.x = PI * 0.5
		ring.scale = Vector3(1.0, 1.0, 1.12)
		round_eye.visible = false
		_eye_round.append(round_eye)
		# thinking "- -" — one solid dash
		var flat := _node("Flat", eye, Vector3(0.0, -0.006 * fs, -0.002))
		var dash := _mi(rounded_box(Vector3(eye_w * fs * 2.10, eye_h * fs * 0.42, eye_d * 1.6), eye_h * fs * 0.20, 12), m_dark, flat, Vector3.ZERO, "Dash")
		dash.rotation.z = deg_to_rad(-5.0 * sx)
		flat.visible = false
		_eye_flat.append(flat)
		# resting brow bar, exactly the organic villagers' grammar drawn on a screen
		_add_brow(eye, m_dark, sx)


## One calm smile arc plus a real open mouth (lip / interior / tongue) on a flat faceplate.
func _add_flat_mouth(parent: Node3D, y_off: float, m_dark: Material, inner: Color) -> void:
	var fs := face_scale
	var mouth := _node("Mouth", parent, Vector3(0.0, y_off, 0.0))
	_mouth_smile = _smile_arc(m_dark, mouth, MOUTH_ARC_R * fs * 0.86, MOUTH_TUBE * fs * 1.15, -0.004)
	var open := _node("Open", mouth, Vector3(0.0, -0.014 * fs, -0.003))
	_mi(sphere(1.0, 14, 8), m_dark, open, Vector3.ZERO, "Lip")
	var m_inner := _toon(inner, {"spec": 0.0, "rim": 0.0, "shade": 0.10})
	_mi(sphere(1.0, 12, 7), m_inner, open, Vector3(0.0, 0.04, -0.62), "Inner").scale = Vector3(0.70, 0.60, 0.50)
	_mouth_open = open
	_mouth_open.scale = Vector3(mouth_w * fs, 0.0008, mouth_d)


## Two soft blush ovals on a flat faceplate.
func _add_flat_blush(parent: Node3D, spacing: float, y_off: float, m_blush: Material, w: float = 0.052) -> void:
	for sx: float in [-1.0, 1.0]:
		var b := _mi(sphere(1.0, 12, 6), m_blush, parent, Vector3(spacing * 0.5 * sx, y_off, -0.002), "Blush")
		b.scale = Vector3(w * face_scale, w * 0.62 * face_scale, 0.012)


## Emissive part that still reads as a *colour* in daylight instead of blowing out to white:
## a saturated base albedo plus measured emission. toon_soft scales emission to 15 % by day and
## 100 % at night, so these parts glow properly after dark without washing out the face at noon.
static func lit_material(base: Color, strength: float = 1.4, emit: Color = Color.TRANSPARENT) -> ShaderMaterial:
	var e := base.lightened(0.25) if emit == Color.TRANSPARENT else emit
	return _toon(base, {"emission": e, "emission_strength": strength, "shade": 0.16, "rim": 0.08, "spec": 0.0})


## ---------------------------------------------------------------------------- alien features
## EYESTALKS. Two of the cast keep these; the ruling is that they are a CHOICE, not the species.
## (The stray two-line `_add_antenna` docstring that used to sit here has moved to the function it
## documents, which now has options of its own.)
##
## Shared by the neighbours that do wear them (see reference/'Alien References.webp'): the one trait
## that most separates those creatures from animals is that their eyes are not on their face.
##
## Each spec is `{"base": Vector3, "tip": Vector3, "r": float}` in HEAD-LOCAL space, and specs are
## matched to `_eyes` in order. The eye nodes are only REPOSITIONED, never rebuilt, so every blink,
## squint, happy-arc and surprise state keeps animating exactly as it does on a normal face. Do not
## supply more specs than there are eyes: an eye that cannot blink beside two that can reads as a
## bug, not as an extra eye.
## R4: `eyeball_r` is now a DEFAULT, not a constant — a spec may carry its own `eyeball_r`, and it
## is used in BOTH the sphere and the eye-node offset. Without that a "graded fan" of stalks ships
## as three different stem lengths carrying three identical balls, which reads as a manufacturing
## error rather than as an organism.
func _add_eyestalks(specs: Array, stalk_color: Color, sclera_color: Color, eyeball_r: float = 0.062) -> void:
	var m_stalk := _toon(stalk_color, _matte({"spec": 0.05}))
	var m_sclera := _toon(sclera_color, _matte({"spec": 0.04, "rim": 0.02}))
	for i in mini(specs.size(), _eyes.size()):
		var spec: Dictionary = specs[i]
		var base: Vector3 = spec["base"]
		var tip: Vector3 = spec["tip"]
		var r: float = float(spec.get("r", 0.030))
		var ball_r: float = float(spec.get("eyeball_r", eyeball_r))
		var span := tip - base
		var length := span.length()
		var stalk := _node("EyeStalk%d" % i, _head, base + span * 0.5)
		# A capsule runs along its own +Y, so build a basis whose Y follows the stalk.
		stalk.basis = _basis_from_up(span.normalized())
		_mi(capsule(r, maxf(0.02, length - r * 2.0), 8, 2), m_stalk, stalk, Vector3.ZERO, "Stem")
		# A pale ball at the tip; the face's dark oval sits proud of it and becomes the pupil.
		_mi(sphere(ball_r, 14, 8), m_sclera, _head, tip, "Eyeball%d" % i)
		# Splay each eye outward and down. Two stalks staring dead ahead in parallel look like a toy.
		var splay: float = float(spec.get("splay", 0.20 if tip.x >= 0.0 else -0.20))
		var eye: Node3D = _eyes[i]
		eye.basis = Basis.looking_at(Vector3(splay, -0.14, -1.0).normalized(), Vector3.UP)
		eye.position = tip + eye.basis.z * -(ball_r * 0.84)


## A WIDE OPEN GRIN with blunt teeth, replacing the hairline smile arc.
##
## With the eyes lifted onto stalks the head becomes a large blank dome, and a thin curve at the
## bottom of it reads as an EYELESS monster rather than a creature. Every alien on the reference
## sheet that wears its eyes on stalks also wears a mouth across most of its face; the grin is what
## makes the blank area read as a face at all.
##
## `_mouth_smile` is freed and nulled. `_apply_face` guards every use of it, so the open-mouth blend
## that drives talking still runs and now animates INSIDE this grin instead of fighting a second
## line drawn across it.
func _add_wide_grin(mouth_node: Node3D, grin_color: Color, tooth_color: Color,
		size3: Vector3 = Vector3(0.086, 0.034, 0.020), teeth: Array = []) -> void:
	if _mouth_smile != null and is_instance_valid(_mouth_smile):
		_mouth_smile.queue_free()
	_mouth_smile = null
	var m_grin := _toon(grin_color, {"spec": 0.0, "rim": 0.0, "shade": 0.05})
	var m_tooth := _toon(tooth_color, {"spec": 0.02, "rim": 0.02, "shade": 0.04})
	var grin := _node("Grin", mouth_node, Vector3(0.0, 0.0, -0.004))
	_mi(superellipsoid(size3, 2.4, 20, 10), m_grin, grin, Vector3.ZERO, "Cavity")
	# Odd count and uneven widths on purpose: a neat even row reads as a cartoon animal's smile.
	var rows: Array = teeth if not teeth.is_empty() else [[-0.045, 0.019], [0.002, 0.023], [0.046, 0.016]]
	for t: Array in rows:
		_add_tooth(grin, m_tooth, size3, t)


## ONE TOOTH. An entry is `[x, w]`, `[x, w, row]` or `[x, w, row, shape]`:
##   x      offset across the grin.
##   w      the tooth's FULL width (this is what the shipped call sites pass).
##   row    +1 hangs from the upper jaw (the default, and what every tooth in the game did before
##          R4 — the row was hardcoded), -1 stands up from the LOWER jaw. A lower row alone is an
##          under-bite, and an under-bite is a whole different animal from a top-row grin.
##   shape  "blunt" (the shipped rounded slab) | "point" (a cone — a fang) | "peg" (a rounded stub).
## Two- and three-element entries mean exactly what they meant before, so no existing call moves.
func _add_tooth(grin: Node3D, m_tooth: Material, size3: Vector3, t: Array) -> void:
	var x := float(t[0])
	var w := float(t[1])
	var row := float(t[2]) if t.size() > 2 else 1.0
	var shape := String(t[3]) if t.size() > 3 else "blunt"
	match shape:
		"point":
			# taper_tube grows along +Y, so a top-row fang is the same cone turned over.
			var fang := _node("Tooth", grin, Vector3(x, row * size3.y * 0.92, -0.006))
			fang.rotation.x = PI if row > 0.0 else 0.0
			_mi(taper_tube(size3.y * 1.05, w * 0.50, w * 0.10, 0.0, 4, 6), m_tooth, fang, Vector3.ZERO, "Fang")
		"peg":
			_mi(capsule(w * 0.44, size3.y * 0.62, 8, 2), m_tooth, grin,
				Vector3(x, row * size3.y * 0.56, -0.006), "Tooth")
		_:
			_mi(rounded_box(Vector3(w, size3.y * 0.62, 0.016), 0.005, 8), m_tooth, grin,
				Vector3(x, row * size3.y * 0.56, -0.006), "Tooth")


## R4 (CAST VARIETY). Four neighbours wore this and it built exactly one thing every time — a
## straight 16 mm capsule with an ALWAYS-emissive ball on the end — which is why Zorp, Pip, Pop and
## Bolt read as the same character from the eyebrows up. `opts` EXTENDS it; every default reproduces
## the shipped antenna exactly, so no existing call site moves:
##   tip      "bulb" (the shipped ball) | "paddle" (a flat blade) | "knob" (a squat faceted cap)
##   glow     true (shipped) | false for a dead, unlit tip | a float for a different emission
##            strength. The meta is set EITHER WAY, see below.
##   stalk_r  stem radius, default the shipped 0.016
##   curve    total bend of the stem in radians; 0 keeps the shipped straight capsule
##
## It MUST keep setting the metas "bulb_mat" and "rest_tilt" and returning the pivot: three
## `_animate_extras` implementations read them, and one of them pulses `emission_strength` on the
## material every frame. An unlit tip therefore still gets its own duplicated material with the
## uniform present — writing to it is simply inert — rather than a null those callers would crash on.
func _add_antenna(parent: Node3D, offset: Vector3, tilt: float, stalk_color: Color, bulb_color: Color,
		length: float = 0.20, bulb_r: float = 0.045, opts: Dictionary = {}) -> Node3D:
	var pivot := _node("Antenna", parent, offset)
	pivot.rotation.z = tilt
	var m_stalk := _toon(stalk_color, _matte({"spec": 0.06}))
	var stalk_r: float = float(opts.get("stalk_r", 0.016))
	var curve: float = float(opts.get("curve", 0.0))
	var tip_pos := Vector3(0.0, length + bulb_r * 0.6, 0.0)
	var tip_up := Vector3.UP
	if is_zero_approx(curve):
		_mi(capsule(stalk_r, length, 8, 2), m_stalk, pivot, Vector3(0.0, length * 0.5, 0.0), "Stalk")
	else:
		_mi(taper_tube(length, stalk_r, stalk_r * 0.82, curve, 7, 6), m_stalk, pivot, Vector3.ZERO, "Stalk")
		tip_up = Vector3(0.0, cos(curve), sin(curve))
		tip_pos = taper_tube_end(length, curve, 7) + tip_up * (bulb_r * 0.6)
	var glow: Variant = opts.get("glow", true)
	var bulb_mat: ShaderMaterial
	if typeof(glow) == TYPE_BOOL and not bool(glow):
		bulb_mat = _toon(bulb_color, _matte({"spec": 0.10, "rim": 0.04})).duplicate() as ShaderMaterial
	else:
		var strength := 1.2 if typeof(glow) == TYPE_BOOL else float(glow)
		bulb_mat = lit_material(bulb_color.darkened(0.48), strength, bulb_color).duplicate() as ShaderMaterial
	var bulb: MeshInstance3D
	match String(opts.get("tip", "bulb")):
		"paddle":
			bulb = _mi(rounded_box(Vector3(bulb_r * 2.3, bulb_r * 3.0, bulb_r * 0.70), bulb_r * 0.30, 10),
				bulb_mat, pivot, tip_pos, "Bulb")
		"knob":
			bulb = _mi(superellipsoid(Vector3(bulb_r * 1.06, bulb_r * 0.74, bulb_r * 1.06), 3.2, 12, 6),
				bulb_mat, pivot, tip_pos, "Bulb")
		_:
			bulb = _mi(sphere(bulb_r, 12, 6), bulb_mat, pivot, tip_pos, "Bulb")
	if not is_zero_approx(curve):
		bulb.basis = _basis_from_up(tip_up)
	bulb.set_meta("bulb_mat", bulb_mat)
	pivot.set_meta("bulb_mat", bulb_mat)
	pivot.set_meta("rest_tilt", tilt)
	return pivot


## ---------------------------------------------------------------------------- horns, crests, ruffs
## A BANDED HORN, seated on the real head surface and growing along its outward normal.
##
## `seat_dir` is a direction in head-local space (it is normalised here, so `Vector3(0.6, 1, -0.2)`
## is a perfectly good argument). The seat and the normal come from `se_point`/`se_normal` DIRECTLY,
## never from `_orient_on_head`: that ends in `Basis.looking_at(outward, Vector3.UP)`, which warns on
## colinear vectors as the seat approaches the crown and whose yaw is already meaningless by 85 deg
## of pitch — and the crown is exactly where horns go.
##
## `tilt` is euler radians and is applied to a CHILD of the seated pivot, so aiming the horn cannot
## destroy the placement. `segments` stacked `taper_tube`s in ALTERNATING `band_colors` give the
## keratin ring pattern; each segment is nested inside the last, so `opts.curl` (total bend in
## radians, default straight) sweeps the whole horn instead of kinking it. Returns the seated pivot.
func _add_horn(parent: Node3D, seat_dir: Vector3, tilt: Vector3, segments: int, length: float,
		base_r: float, band_colors: Array, opts: Dictionary = {}) -> Node3D:
	segments = maxi(segments, 1)
	var semi: Vector3 = opts.get("semi", head_semi)
	var n: float = float(opts.get("exp", head_n))
	var p := se_point(seat_dir.normalized(), semi, n)
	var outward := se_normal(p, semi, n)
	var pivot := _node("Horn", parent, p - outward * float(opts.get("inset", 0.012)))
	pivot.basis = _basis_from_up(outward)
	var aim := _node("Aim", pivot, Vector3.ZERO)
	aim.rotation = tilt
	var seg_len := length / float(segments)
	var tip_r := float(opts.get("tip_r", base_r * 0.16))
	var seg_curl := float(opts.get("curl", 0.0)) / float(segments)
	var mat_opts: Dictionary = opts.get("surface", {"spec": 0.05, "rim": 0.03})
	var cursor := aim
	for i in segments:
		var r_a := lerpf(base_r, tip_r, float(i) / float(segments))
		var r_b := lerpf(base_r, tip_r, float(i + 1) / float(segments))
		var col: Color = Color.WHITE if band_colors.is_empty() else Color(band_colors[i % band_colors.size()])
		_mi(taper_tube(seg_len, r_a, r_b, seg_curl, 4, 6), _toon(col, _matte(mat_opts)),
			cursor, Vector3.ZERO, "Band%d" % i)
		if i < segments - 1:
			var joint := _node("Joint%d" % i, cursor, taper_tube_end(seg_len, seg_curl, 4))
			joint.rotation.x = seg_curl
			cursor = joint
	return pivot


## A ROW OF SEATS on the head superellipsoid — the spine of a crest, a fan of horns, a row of vents.
## `count` pivots spaced evenly in PITCH from `pitch_from` to `pitch_to` at a fixed `yaw_deg` (call it
## twice with +/- yaw for a symmetric pair of rows).
##
## Returns the TILT CHILDREN, not the seats. That is the whole point: a node `_orient_on_head` has
## posed carries a basis, and writing `rotation.x` on it makes Godot rebuild that basis from euler
## and throw the placement away — a bug three files in this project have written by hand. The nodes
## you get back start at identity and are safe to rotate however you like; their PARENT holds the
## placement, with +Y pointing straight out of the head, which is the direction every long primitive
## in this file grows along.
func _crown_row(count: int, pitch_from: float, pitch_to: float, yaw_deg: float = 0.0,
		inset: float = 0.006) -> Array[Node3D]:
	var out: Array[Node3D] = []
	count = maxi(count, 1)
	var yaw := deg_to_rad(yaw_deg)
	for i in count:
		var t := 0.5 if count == 1 else float(i) / float(count - 1)
		var pitch := deg_to_rad(lerpf(pitch_from, pitch_to, t))
		# The same direction formula `_orient_on_head` uses, so a crest lines up with the face.
		var d := Vector3(sin(yaw) * cos(pitch), sin(pitch), -cos(yaw) * cos(pitch))
		var p := se_point(d, head_semi, head_n)
		var outward := se_normal(p, head_semi, head_n)
		var seat := _node("CrownSeat%d" % i, _head, p - outward * inset)
		seat.basis = _basis_from_up(outward)
		out.append(_node("Tilt", seat, Vector3.ZERO))
	return out


## A PLASTRON — the contrasting belly plate six of the eighteen reference creatures wear and nothing
## in this game has. It is a cheap, strong species mark: it breaks the torso into a front and a back
## instead of one coloured bean, and it reads at gameplay distance because it is a large flat value
## contrast rather than a small detail.
##
## The rim is drawn FIRST, slightly larger and slightly further back, so the plate's own front face
## always sits proud of it and the rim reads as an outline band rather than z-fighting with it.
##
## THE DEPTH IS COMPUTED, NOT GUESSED. The torso is a superellipsoid, so its front surface RECEDES
## as you move up or down the belly; a hand-picked z sinks the plate inside the bean and all that
## ships is a thin dark arc peeking out under it (measured on the first build of this). The default
## solves the torso's own implicit equation at the plate's centre height and buries just over half
## the plate's depth, so it stands proud by a definite amount at any `y`. Pass `torso_mul` if the
## character scaled its bean with `_add_torso_bean`'s `size_mul`, or the surface is somewhere else.
##
## opts: y, z (explicit centre, skipping the solve), torso_mul, n (superellipsoid exponent), rim_w,
## seams (horizontal scute lines), navel_r, navel_color, plus any `_matte` keys for the plate.
func _add_plastron(color: Color, rim_color: Color, size3: Vector3 = Vector3(0.140, 0.150, 0.046),
		navel: bool = true, opts: Dictionary = {}) -> Node3D:
	var y: float = float(opts.get("y", TORSO_Y - 0.010))
	var k: Vector3 = opts.get("torso_mul", Vector3.ONE)
	# torso front half-depth at this height: |dy/ry|^n + |dz/rz|^n = 1 solved for dz
	var dy := absf(y - TORSO_Y) / maxf(TORSO_RY * k.y, 1e-4)
	var front := TORSO_RZ * k.z * pow(maxf(1.0 - pow(minf(dy, 1.0), TORSO_N), 0.0), 1.0 / TORSO_N)
	var z: float = float(opts.get("z", -(front - size3.z * 0.55)))
	var n: float = float(opts.get("n", 2.7))
	var rim_w: float = float(opts.get("rim_w", 0.015))
	var plate := _node("Plastron", _torso, Vector3(0.0, y, z))
	var m_rim := _toon(rim_color, _matte({"rim": 0.02}))
	_mi(superellipsoid(Vector3(size3.x + rim_w, size3.y + rim_w, size3.z * 0.90), n, 18, 10),
		m_rim, plate, Vector3(0.0, 0.0, size3.z * 0.10), "Rim")
	var plate_mesh := superellipsoid(size3, n, 18, 10)
	_mi(plate_mesh, _toon(color, _matte(opts)), plate, Vector3.ZERO, "Plate")
	# SCUTE LINES. A seam is a SQUASHED COPY OF THE PLATE'S OWN MESH, not a bar laid across it, and
	# both facts are load-bearing:
	#   * the plate's front recedes toward its edges, so a bar at a fixed z is buried at both ends
	#     and shows only as a stub in the middle;
	#   * and building the slice as its own very FLAT superellipsoid does not work either —
	#     `se_point` collapses a slab whose y semi-axis is tiny toward the poles unless a vertex ring
	#     happens to land on the equator, so the seam can vanish entirely depending on the ring count
	#     the DETAIL constant happens to produce. Both were measured, in that order.
	# Reusing the plate mesh and scaling the NODE sidesteps the whole question: the ratio is exactly
	# the 1.05 asked for, whatever the tessellation, and the mesh is already in the cache.
	var seams: int = int(opts.get("seams", 0))
	for i in seams:
		var sy := lerpf(size3.y * 0.62, -size3.y * 0.62, float(i + 1) / float(seams + 1))
		var az := pow(maxf(1.0 - pow(minf(absf(sy) / size3.y, 1.0), n), 0.0), 1.0 / n)
		_mi(plate_mesh, m_rim, plate, Vector3(0.0, sy, 0.0), "Seam").scale = \
			Vector3(az * 0.99, rim_w * 0.34 / maxf(size3.y, 1e-4), az * 1.05)
	if navel:
		var nr: float = float(opts.get("navel_r", size3.x * 0.13))
		_mi(superellipsoid(Vector3(nr, nr * 0.72, nr * 0.40), 2.5, 10, 6),
			_toon(Color(opts.get("navel_color", rim_color.darkened(0.28))), _matte({"rim": 0.0})),
			plate, Vector3(0.0, -size3.y * 0.44, -size3.z * 0.92), "Navel")
	return plate


## A RING OF TENDRILS hanging off `parent` — a beard of feelers, a mane of cables, a jellyfish skirt.
##
## The joints are NESTED, not siblings. That is the difference between a tendril that WHIPS — each
## joint's swing carried and amplified by every joint above it — and one that shears, where the
## whole strand slides sideways as one rigid stick. It costs nothing: it is the same node count.
##
## The ring sits at `parent`'s ORIGIN with radius `ring_r`; `drop` is how far each strand hangs,
## split evenly between `joints` nested segments tapering `r0` -> `r1`. Angles run from -Z (the
## model's facing), so `arc_deg` under 360 leaves the gap at the BACK.
##
## Returns a FLAT array of EVERY joint pivot, tendril-major. Each one carries the metas an animator
## needs, so `_animate_extras` is a single loop with no bookkeeping of its own:
##   "tendril" / "joint"  indices, if a caller wants to treat strands differently
##   "period" / "phase"   this joint's own cycle — every joint is on a different one, which is what
##                        keeps the ring from pulsing in lockstep like a machine
##   "rest_x" / "rest_z"  the resting euler this joint was built at; ADD your swing to these, and
##                        write `rotation`, which is safe because these pivots were seated by euler
##                        and not by a basis.
func _add_tendril_ring(parent: Node3D, count: int, ring_r: float, drop: float, r0: float, r1: float,
		color: Color, joints: int = 3, arc_deg: float = 360.0) -> Array[Node3D]:
	var out: Array[Node3D] = []
	count = maxi(count, 1)
	joints = maxi(joints, 1)
	var m := _toon(color, _matte({"spec": 0.04}))
	var span := deg_to_rad(clampf(arc_deg, 1.0, 360.0))
	var full := arc_deg >= 359.9
	var seg_len := 1.0 / float(joints)
	var seg_drop := drop / float(joints)
	for i in count:
		var a := TAU * float(i) / float(count) if full else \
			(-span * 0.5 + span * float(i) / float(maxi(count - 1, 1)))
		var cursor := _node("Tendril%d" % i, parent, Vector3(sin(a) * ring_r, 0.0, -cos(a) * ring_r))
		# Yaw puts this strand's local -Z along the outward radial, so the pitch that follows leans
		# it OUTWARD from the ring wherever round the ring it happens to sit.
		cursor.rotation = Vector3(0.13, a, 0.0)
		for j in joints:
			var t0 := float(j) * seg_len
			var t1 := float(j + 1) * seg_len
			var node := cursor
			if j > 0:
				node = _node("Joint%d" % j, cursor, Vector3(0.0, -seg_drop, 0.0))
				# a little more lean at every joint, so the strand hangs in a curve, not a rod
				node.rotation = Vector3(0.11, 0.0, 0.0)
			# taper_tube grows along +Y; a tendril hangs, so the mesh is turned over in place.
			_mi(taper_tube(seg_drop, lerpf(r0, r1, t0), lerpf(r0, r1, t1), 0.0, 4, 5),
				m, node, Vector3.ZERO, "Seg").rotation.x = PI
			node.set_meta("tendril", i)
			node.set_meta("joint", j)
			node.set_meta("period", 1.45 + 0.31 * float(i) + 0.23 * float(j))
			node.set_meta("phase", fmod(0.618 * float(i) + 0.317 * float(j), 1.0))
			node.set_meta("rest_x", node.rotation.x)
			node.set_meta("rest_z", node.rotation.z)
			out.append(node)
			cursor = node
	return out


# ============================================================================= helpers
## AC silhouettes are crisp against the sky: `rim` used to be 0.13, which put a bright halo around
## every neighbour and washed the outline out. 0.035 keeps a hint of wrap light and nothing more.
##
## R2.6, and the reason a character's saturation p90 was 0.72-0.79 while its albedo was in band:
## `toon_soft` multiplies the shaded side by `shade_tint` at `shade_strength`. The engine default
## tint is a strong lavender (0.62, 0.55, 0.85) at 0.42, which on a teal or a violet crushes the
## channels UNEVENLY and pushes the shade side far MORE saturated than the albedo — Bolt's shell
## measured S 0.37 as albedo, 0.27 lit and 0.59 shaded, and that shade side was setting his p90.
## The style guide's own note is "dark does not mean saturated". Characters therefore use a gentler,
## nearly neutral cool shade (0.74, 0.71, 0.84) at 0.30, which still tints the shadow cool and still
## reads as a toon terminator, but stops manufacturing chroma the albedo never had.
static func _matte(opts: Dictionary) -> Dictionary:
	var o := opts.duplicate()
	o["spec"] = o.get("spec", 0.0)
	o["spec_size"] = o.get("spec_size", 110.0)
	o["rim"] = o.get("rim", 0.035)
	o["roughness"] = o.get("roughness", 0.95)
	o["shade"] = o.get("shade", 0.30)
	o["shade_tint"] = o.get("shade_tint", Color(0.74, 0.71, 0.84))
	return o


## Every character material goes through here instead of straight to `MaterialLib.toon`.
##
## R2.6, and the last thing standing between these models and the palette gates. `toon_soft` drops a
## surface inside a CAST shadow to `shadow_floor` (0.08) of its albedo, at which point the only
## light left on it is the scene's ambient — which, since R2.1 replaced the blue sky with a dark
## thin-atmosphere one, is a deep navy. On a small object that is mostly self-shadowed (a big head
## sitting on a small body) that turned every shaded pocket into a strongly BLUE-SHIFTED pixel:
## Bolt's teal shell measured S 0.31 as albedo and S 0.60 in his own head's shadow, and those
## pixels — not the albedo — were what put four of the seven neighbours over the "no dominant
## swatch above S 0.60" gate. Lifting the floor to 0.24 keeps the sun's own warm colour in the
## shadow instead of letting ambient own it. It also matters more now than it used to, because the
## head casts again (docs/OPEN_ISSUES.md issue 1 is resolved and `head_shadow_cheat` is off).
## The self-shaded terminator is lifted much more gently (0.62 -> 0.68) — the shade side is meant to
## stay a readable dark, and the ground, not the cast, is where luma p05 comes from.
const CHAR_SHADOW_FLOOR := 0.24
const CHAR_SHADE_FLOOR := 0.68
static var _char_mat_cache: Dictionary = {}

static func _toon(color: Color, opts: Dictionary = {}) -> ShaderMaterial:
	var key := "%s|%s" % [color.to_html(), str(opts)]
	if _char_mat_cache.has(key):
		return _char_mat_cache[key]
	var m := MaterialLib.toon(color, opts).duplicate() as ShaderMaterial
	m.set_shader_parameter("shadow_floor", CHAR_SHADOW_FLOOR)
	m.set_shader_parameter("shade_floor", CHAR_SHADE_FLOOR)
	_char_mat_cache[key] = m
	return m


func _node(n: String, parent: Node, pos: Vector3) -> Node3D:
	var nd := Node3D.new()
	nd.name = n
	nd.position = pos
	parent.add_child(nd)
	return nd


func _mi(mesh: Mesh, mat: Material, parent: Node, pos: Vector3, n: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = n
	mi.mesh = mesh
	if mat:
		mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi


## A THIN SLAB that hugs a superellipsoid cross-section: a crown seam, a waist chamfer, a strata
## band. Use this instead of calling `superellipsoid()` with a tiny Y semi-axis.
##
## WHY THIS EXISTS — A FLAT SUPERELLIPSOID DOES NOT REACH ITS OWN EQUATOR, AND SILENTLY RENDERS
## NOTHING. `superellipsoid()` projects SphereMesh vertex DIRECTIONS radially onto the implicit
## surface, so the mesh only reaches the equatorial radius if a vertex row lies ON the equator.
## Godot places SphereMesh's rows at v = j/(rings+1), so an EVEN ring count has no equator row —
## and `_segs(6, 4)` resolves to exactly 4. On a pancake the outermost row runs out of the thin Y
## axis long before it reaches the wide X one, so it lands well inside the requested radius and the
## part sits INSIDE its parent shell drawing nothing at all.
##
## MEASURED, on the two parts that used to be built the wrong way:
##   crown seam   asked half-x 0.203600, built 0.076166 -> 37.4 % of what it asked for
##   waist chamfer asked half-x 0.214300, built 0.066913 -> 31.2 %
## Both were completely buried. Every character in the game was missing both hard edges, which is
## why heads read rounder than art direction revision 2 asks for.
##
## THE FIX: build the part NEAR-ROUND (Y semi = the larger of the two plan radii), where the row
## nearest the equator is at worst PI/2*(1/(rings+1)) off it and still reaches >= 99 % of the plan,
## then squash it to a slab with a NODE SCALE. Same triangle count, same primitive cache, and the
## cross-section at y = 0 is still exactly the shell's own plan — which is what lets it hug a
## rounded-square head where a torus or a rounded_box cannot.
##
## Do NOT "fix" this instead by picking a ring count that happens to land on the equator. That
## works today and breaks silently the next time `DETAIL` moves.
##
## RINGS ARE FORCED ODD, AND THAT IS A BUDGET DECISION, NOT A TRICK. Near-round alone is not
## enough on a cheap mesh: with an even ring count the row nearest the equator is up to
## PI/2*(1/(rings+1)) off it, which at 4 rings reaches only ~95 % of the plan — and 95 % of a seam
## sized at 0.795 of the head is 0.755, still inside the shell. The honest ways out are many rings
## (a 30/30 slab measured +1158 tris per character and put four neighbours over the 6 k budget) or
## ONE row landing exactly on the equator, which is what an odd ring count guarantees. So this
## searches for the smallest `rings` argument whose RESOLVED count is odd, instead of hard-coding
## one that happens to be odd at today's `DETAIL`. That is the distinction the warning above draws:
## depending on parity is fine when you ENFORCE it, and fatal when you assume it.
##
## `plan` is the slab's half-extents in X and Z; `thickness` is its half-height AFTER the squash.
## `seg` must be high enough to wrap the parent cleanly — at seg 18 against a 23-segment head the
## slab pokes out at its vertices and sinks between them, and renders DASHED. 30 is the smallest
## that wraps cleanly at the ~1.04 oversizing these parts use.
func _se_slab(parent: Node, plan: Vector2, thickness: float, n: float, mat: Material,
		pos: Vector3, node_name: String, seg: int = 30, rings: int = 5) -> MeshInstance3D:
	var r := maxf(plan.x, plan.y)
	var want := maxi(1, rings)
	# `_segs` is not invertible in closed form, so step up until the resolved count is odd. Bounded:
	# `_segs` is monotonic in its argument, so parity flips within a few steps at any DETAIL.
	while _segs(want, 4) % 2 == 0 and want < rings + 12:
		want += 1
	var mi := _mi(superellipsoid(Vector3(plan.x, r, plan.y), n, seg, want), mat, parent, pos, node_name)
	mi.scale = Vector3(1.0, thickness / r, 1.0)
	return mi


## Places `node` on the head SUPERELLIPSOID (the same surface `_add_head_shell` builds) so its
## local -Z points along the outward normal and `inset` pushes it in (or out, if negative) along
## that normal. Because the head has flat-ish planes now, the two eye planes are nearly coplanar and
## the face reads as a painted front rather than a pattern wrapped round a ball.
func _orient_on_head(node: Node3D, yaw_deg: float, pitch_deg: float, inset: float = 0.004) -> void:
	var yaw := deg_to_rad(yaw_deg)
	var pitch := deg_to_rad(pitch_deg)
	var d := Vector3(sin(yaw) * cos(pitch), sin(pitch), -cos(yaw) * cos(pitch))
	var p := se_point(d, head_semi, head_n)
	var outward := se_normal(p, head_semi, head_n)
	node.position = p - outward * inset
	node.basis = Basis.looking_at(outward, Vector3.UP)


## An orthonormal basis whose +Y is `up` (already normalised). Use this, NOT `_orient_on_head`, for
## anything that GROWS out of the head near the crown: `_orient_on_head` ends in
## `Basis.looking_at(outward, Vector3.UP)`, which warns on colinear vectors as the pitch approaches
## 90 deg and whose yaw is meaningless well before that. Every primitive in this file that has a
## length — capsule, taper_tube, cylinder — runs along its own +Y, so this is the frame they want.
static func _basis_from_up(up: Vector3) -> Basis:
	var yv := up
	var xv := Vector3.RIGHT if absf(yv.dot(Vector3.RIGHT)) < 0.9 else Vector3.FORWARD
	var zv := xv.cross(yv).normalized()
	xv = yv.cross(zv).normalized()
	return Basis(xv, yv, zv)


# ---------------------------------------------------------------------------- mesh primitives
## Global mesh density. Call sites ask for the segment count that *reads* well; every primitive then
## scales it by this factor, which is what keeps all seven neighbours inside the 6k triangle budget
## from docs/ARCHITECTURE.md §10. Lower it for more headroom, raise it for close-up beauty shots.
const DETAIL := 0.60

## Primitive meshes are immutable once built, so every character shares one instance per shape.
static var _mesh_cache: Dictionary = {}


static func _segs(n: int, lo: int = 6) -> int:
	return maxi(lo, int(round(float(n) * DETAIL)))


static func sphere(r: float, seg: int = 20, rings: int = 10) -> SphereMesh:
	var key := "sp|%.4f|%d|%d" % [r, seg, rings]
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	m.radial_segments = _segs(seg)
	m.rings = _segs(rings, 4)
	_mesh_cache[key] = m
	return m


static func capsule(r: float, h: float, seg: int = 12, rings: int = 3) -> CapsuleMesh:
	var key := "cap|%.4f|%.4f|%d|%d" % [r, h, seg, rings]
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var m := CapsuleMesh.new()
	m.radius = r
	m.height = maxf(h, r * 2.0)
	m.radial_segments = _segs(seg)
	m.rings = _segs(rings, 2)
	_mesh_cache[key] = m
	return m


static func cylinder(rt: float, rb: float, h: float, seg: int = 16) -> CylinderMesh:
	var key := "cyl|%.4f|%.4f|%.4f|%d" % [rt, rb, h, seg]
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var m := CylinderMesh.new()
	m.top_radius = rt
	m.bottom_radius = rb
	m.height = h
	m.radial_segments = _segs(seg)
	m.rings = 1
	_mesh_cache[key] = m
	return m


static func torus(inner: float, outer: float, rings: int = 20, sides: int = 8) -> TorusMesh:
	var key := "tor|%.4f|%.4f|%d|%d" % [inner, outer, rings, sides]
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var m := TorusMesh.new()
	m.inner_radius = inner
	m.outer_radius = outer
	m.rings = _segs(rings)
	m.ring_segments = _segs(sides, 4)
	_mesh_cache[key] = m
	return m


## A unit rounded cube (-1..1) used for every chunky screen pixel.
static func pixel_mesh() -> ArrayMesh:
	return rounded_box(Vector3(2.0, 2.0, 2.0), 0.62, 8)


# ---------------------------------------------------------------------------- superellipsoid
## R2.3 ("If a shape can be described as 'a ball' or 'a bunch of balls', rebuild it").
##
## A superellipsoid satisfies |x/a|^n + |y/b|^n + |z/c|^n = 1. At n = 2 it is an ellipsoid; as n
## rises the faces flatten and the corners turn into chamfers, so one parameter takes a shape from
## "ball" to "chunky rounded box" continuously. Every head, torso, mitt, boot and muzzle in this
## file is one of these, which is what gives the neighbours flat planes and hard-ish edges while
## keeping the plush mass. It is also cheap: the surface point along a direction is closed form, so
## `_orient_on_head` places face features on the exact same surface with no ray marching.

## Surface point along unit direction `d`.
static func se_point(d: Vector3, semi: Vector3, n: float) -> Vector3:
	var s := pow(absf(d.x) / semi.x, n) + pow(absf(d.y) / semi.y, n) + pow(absf(d.z) / semi.z, n)
	return d * pow(maxf(s, 1e-9), -1.0 / n)


## Outward unit normal at a surface point (the gradient of the implicit function).
static func se_normal(p: Vector3, semi: Vector3, n: float) -> Vector3:
	var g := Vector3(
		signf(p.x) * pow(absf(p.x) / semi.x, n - 1.0) / semi.x,
		signf(p.y) * pow(absf(p.y) / semi.y, n - 1.0) / semi.y,
		signf(p.z) * pow(absf(p.z) / semi.z, n - 1.0) / semi.z)
	return g.normalized() if g.length_squared() > 1e-12 else Vector3.FORWARD


## Superellipsoid mesh with `semi` half-extents and exponent `n`, sharing the primitive cache.
static func superellipsoid(semi: Vector3, n: float, seg: int = 28, rings: int = 14) -> ArrayMesh:
	var key := "se|%.4f,%.4f,%.4f|%.3f|%d|%d" % [semi.x, semi.y, semi.z, n, seg, rings]
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var sph := SphereMesh.new()
	sph.radius = 1.0
	sph.height = 2.0
	sph.radial_segments = _segs(seg)
	sph.rings = _segs(rings, 4)
	var arr: Array = sph.get_mesh_arrays()
	var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var out := PackedVector3Array()
	var norms := PackedVector3Array()
	out.resize(verts.size())
	norms.resize(verts.size())
	for i in verts.size():
		var p := se_point(verts[i].normalized(), semi, n)
		out[i] = p
		norms[i] = se_normal(p, semi, n)
	var mesh_arr: Array = []
	mesh_arr.resize(Mesh.ARRAY_MAX)
	mesh_arr[Mesh.ARRAY_VERTEX] = out
	mesh_arr[Mesh.ARRAY_NORMAL] = norms
	mesh_arr[Mesh.ARRAY_TEX_UV] = arr[Mesh.ARRAY_TEX_UV]
	mesh_arr[Mesh.ARRAY_INDEX] = arr[Mesh.ARRAY_INDEX]
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_arr)
	_mesh_cache[key] = am
	return am


## Rounded box (sphere vertices pushed out to the box corners) — chunky toon bevels.
static func rounded_box(size3: Vector3, radius: float, seg: int = 16) -> ArrayMesh:
	var key := "rb|%.4f,%.4f,%.4f|%.4f|%d" % [size3.x, size3.y, size3.z, radius, seg]
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var half := size3 * 0.5
	var r := minf(radius, minf(half.x, minf(half.y, half.z)))
	var sph := SphereMesh.new()
	var rb_seg := _segs(seg)
	sph.radius = 1.0
	sph.height = 2.0
	sph.radial_segments = rb_seg
	sph.rings = maxi(3, int(float(rb_seg) * 0.5))
	var arr: Array = sph.get_mesh_arrays()
	var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var out := PackedVector3Array()
	var norms := PackedVector3Array()
	out.resize(verts.size())
	norms.resize(verts.size())
	for i in verts.size():
		var n := verts[i].normalized()
		var p := n * r + Vector3(signf(n.x) * (half.x - r), signf(n.y) * (half.y - r), signf(n.z) * (half.z - r))
		if absf(n.x) < 0.02:
			p.x = 0.0
		if absf(n.z) < 0.02:
			p.z = 0.0
		out[i] = p
		norms[i] = n
	var mesh_arr: Array = []
	mesh_arr.resize(Mesh.ARRAY_MAX)
	mesh_arr[Mesh.ARRAY_VERTEX] = out
	mesh_arr[Mesh.ARRAY_NORMAL] = norms
	mesh_arr[Mesh.ARRAY_TEX_UV] = arr[Mesh.ARRAY_TEX_UV]
	mesh_arr[Mesh.ARRAY_INDEX] = arr[Mesh.ARRAY_INDEX]
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_arr)
	_mesh_cache[key] = am
	return am


## Tube swept along an arc in the XY plane (smiles, closed eyes, brows). Angles CCW from +X.
static func arc_tube(ring_r: float, tube_r: float, a0: float, a1: float, segs: int = 10, sides: int = 6) -> ArrayMesh:
	var akey := "arc|%.4f|%.4f|%.4f|%.4f|%d|%d" % [ring_r, tube_r, a0, a1, segs, sides]
	if _mesh_cache.has(akey):
		return _mesh_cache[akey]
	var st := SurfaceTool.new()
	segs = _segs(segs, 5)
	sides = _segs(sides, 4)
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in segs + 1:
		var a := lerpf(a0, a1, float(i) / segs)
		var radial := Vector3(cos(a), sin(a), 0.0)
		var center := radial * ring_r
		for j in sides + 1:
			var b := TAU * float(j) / sides
			var n := radial * cos(b) + Vector3(0.0, 0.0, 1.0) * sin(b)
			st.set_normal(n)
			st.set_uv(Vector2(float(i) / segs, float(j) / sides))
			st.add_vertex(center + n * tube_r)
	for i in segs:
		for j in sides:
			var a2 := i * (sides + 1) + j
			var b2 := (i + 1) * (sides + 1) + j
			# INSIDE-OUT, AND LEFT THAT WAY DELIBERATELY — see the winding note below. Flipping
			# these two triples is the whole "fix"; it was tried during integration and reverted.
			st.add_index(a2)
			st.add_index(b2)
			st.add_index(b2 + 1)
			st.add_index(a2)
			st.add_index(b2 + 1)
			st.add_index(a2 + 1)
	var arc := st.commit()
	_mesh_cache[akey] = arc
	return arc


# ---------------------------------------------------------------------------- R4 organic primitives
## WINDING, once, because both primitives below depend on it and getting it wrong is invisible from
## exactly one side — which is why it survives a screenshot check.
##
## GODOT WINDS FRONT FACES CLOCKWISE seen from outside: for a triangle (v0, v1, v2) on a correctly
## built closed mesh, `(v1-v0) x (v2-v0)` points INWARD. Measured, not assumed — the signed volume
## of BoxMesh, SphereMesh, TorusMesh, CapsuleMesh and of this file's own `superellipsoid` and
## `rounded_box` (which inherit SphereMesh's index order) all come out NEGATIVE. `toon_soft` is
## `render_mode cull_back` and MaterialLib has no cull_disabled material, so the other winding is a
## solid you can see straight through from the front.
##
## `arc_tube` IS WOUND THE OTHER WAY, AND IT STAYS THAT WAY FOR NOW. Confirmed by signed volume in
## one deterministic run, against Godot's own primitives and this file's:
##     TorusMesh -0.19582   BoxMesh -1.00000   superellipsoid -4.75974   taper_tube -0.04161
##     arc_tube (360 deg sweep) +0.15783        <-- the odd one out
## So under `cull_back` every smile, brow, lid ridge, Grig's ridge and DJ Nova's headband is drawing
## its FAR wall. Silhouettes are unaffected and the vertex normals still point outward, so nothing
## renders as a hole; it is wrong in principle rather than broken in practice.
##
## IT IS NOT FIXED HERE BECAUSE THE FIX IS A CAST-WIDE REPAINT THAT CANNOT CURRENTLY BE REVIEWED.
## Flipping the two index triples changes the shading of a brow or smile on all nine shipped
## neighbours at once, and those nine were authored and signed off against how they look today.
## An A/B was attempted and is INCONCLUSIVE — do not trust a pixel diff here: `tools/capture.sh` is
## NOT deterministic. Two captures of the same scene with identical code differ by ~55,000 pixels
## (`--face=dj_nova --freeze`, 1280x720), because neither the idle phase nor the framing is pinned.
## Any before/after smaller than that is invisible to the harness. Fixing the winding properly needs
## a deterministic capture first, then its own review pass — it is not integration cleanup.
##
## The primitives below deliberately follow GODOT, not `arc_tube`: a horn or a fur fin is a fat
## solid seen from every angle, and inside-out is obvious on those.

## The centreline of a `taper_tube`: `segs` equal steps of arc length, turning `curl` radians in
## total. Shared with `taper_tube_end` so a caller can seat something at the tip and land on the
## exact vertex the mesh ends at rather than near it.
static func _taper_path(length: float, curl: float, segs: int) -> PackedVector3Array:
	var pts := PackedVector3Array()
	pts.resize(segs + 1)
	pts[0] = Vector3.ZERO
	var p := Vector3.ZERO
	var step := length / float(segs)
	for i in range(1, segs + 1):
		# tangent sampled at the MIDDLE of each step, so the polyline sits on the arc, not outside it
		var a := curl * (float(i) - 0.5) / float(segs)
		p += Vector3(0.0, cos(a), sin(a)) * step
		pts[i] = p
	return pts


## Where a `taper_tube` with these arguments ends, in its own local space.
static func taper_tube_end(length: float, curl: float = 0.0, segs: int = 6) -> Vector3:
	var pts := _taper_path(length, curl, _segs(segs, 3))
	return pts[pts.size() - 1]


## A TAPERING, OPTIONALLY CURVED TUBE — the missing primitive. `arc_tube` sweeps in XY at a CONSTANT
## tube radius, so every organic part that narrows (a horn, a tendril, a fang, a bent antenna stem)
## had to be faked as a stack of shrinking capsules: ~300 triangles and a visibly lumpy silhouette
## where 6 x 6 here is 72 wall triangles plus two 6-triangle caps.
##
## Runs along +Y from the origin (the same convention as `capsule` and `cylinder`, so it drops into
## `_basis_from_up` frames unchanged) and bends toward +Z as it rises; `curl` is the TOTAL turn in
## radians. Both ends are capped — an open tube under `cull_back` reads as a hole punched in the
## model. Same SurfaceTool pattern and `_mesh_cache` keying as `arc_tube`.
static func taper_tube(length: float, r0: float, r1: float, curl: float = 0.0,
		segs: int = 6, sides: int = 6) -> ArrayMesh:
	var key := "tt|%.4f|%.4f|%.4f|%.4f|%d|%d" % [length, r0, r1, curl, segs, sides]
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	segs = _segs(segs, 3)
	sides = _segs(sides, 4)
	var pts := _taper_path(length, curl, segs)
	var slope := (r1 - r0) / maxf(length, 1e-5)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in segs + 1:
		var t := float(i) / float(segs)
		var a := curl * t
		var tang := Vector3(0.0, cos(a), sin(a))
		var n1 := Vector3.RIGHT
		var n2 := n1.cross(tang)          ## n1 x n2 == -tang; the caps rely on that identity
		var r := lerpf(r0, r1, t)
		for j in sides + 1:
			var b := TAU * float(j) / float(sides)
			var radial := n1 * cos(b) + n2 * sin(b)
			st.set_normal((radial - tang * slope).normalized())
			st.set_uv(Vector2(t, float(j) / float(sides)))
			st.add_vertex(pts[i] + radial * r)
	for i in segs:
		for j in sides:
			var a2 := i * (sides + 1) + j
			var b2 := (i + 1) * (sides + 1) + j
			# clockwise from outside — see the winding note above
			st.add_index(a2)
			st.add_index(b2 + 1)
			st.add_index(b2)
			st.add_index(a2)
			st.add_index(a2 + 1)
			st.add_index(b2 + 1)
	# SurfaceTool has no vertex counter, so the caps are told where their own vertices start.
	var used := (segs + 1) * (sides + 1)
	used += _taper_cap(st, used, pts[0], r0, 0.0, sides, false)
	_taper_cap(st, used, pts[segs], r1, curl, sides, true)
	var mesh := st.commit()
	_mesh_cache[key] = mesh
	return mesh


## One flat end cap for `taper_tube`, whose first vertex lands at index `base`. `forward` = the tip
## (normal +tangent); otherwise the base (normal -tangent). Returns the vertex count it added.
static func _taper_cap(st: SurfaceTool, base: int, centre: Vector3, r: float, a: float,
		sides: int, forward: bool) -> int:
	if r <= 1e-5:
		return 0
	var tang := Vector3(0.0, cos(a), sin(a))
	var n1 := Vector3.RIGHT
	var n2 := n1.cross(tang)
	var nrm := tang if forward else -tang
	st.set_normal(nrm)
	st.set_uv(Vector2(0.5, 0.5))
	st.add_vertex(centre)
	for j in sides:
		var b := TAU * float(j) / float(sides)
		st.set_normal(nrm)
		st.set_uv(Vector2(0.5 + 0.5 * cos(b), 0.5 + 0.5 * sin(b)))
		st.add_vertex(centre + (n1 * cos(b) + n2 * sin(b)) * r)
	for j in sides:
		var v0 := base + 1 + j
		var v1 := base + 1 + (j + 1) % sides
		st.add_index(base)
		# radial(j) x radial(j+1) == -tang. Godot wants the cross product pointing INWARD, so the
		# BASE cap (outward normal -tang) takes the reversed order and the TIP cap the forward one.
		st.add_index(v0 if forward else v1)
		st.add_index(v1 if forward else v0)
	return sides + 1


## A RING OF FUR / SPINES / FRONDS — `count` fins radiating outward from a ring of radius `ring_r`
## in the XZ plane, angles measured from -Z (the model's facing) so `arc_deg` under 360 leaves a gap
## centred on the BACK. Rotate the parent to put the gap anywhere else.
##
## THE FINS ARE THREE-SIDED PYRAMIDS — 4 triangles each — and NEVER double-sided quads. `toon_soft`
## is `render_mode cull_back` and MaterialLib has no cull_disabled material, so a quad fringe simply
## disappears when the camera walks round to the other side of the character.
##
## `jitter` (0..1) varies each fin's length, angle and rise. It is DETERMINISTIC: the RNG is seeded
## from the cache key, because these meshes are shared and two call sites with identical arguments
## must not get two different ruffs.
static func fur_ring(ring_r: float, fin_len: float, fin_w: float, count: int,
		jitter: float = 0.25, arc_deg: float = 360.0) -> ArrayMesh:
	var key := "fur|%.4f|%.4f|%.4f|%d|%.3f|%.2f" % [ring_r, fin_len, fin_w, count, jitter, arc_deg]
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	count = maxi(count, 1)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(key)
	var span := deg_to_rad(clampf(arc_deg, 1.0, 360.0))
	var full := arc_deg >= 359.9
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in count:
		var a := TAU * float(i) / float(count) if full else \
			(-span * 0.5 + span * float(i) / float(maxi(count - 1, 1)))
		a += rng.randf_range(-jitter, jitter) * span / float(count) * 0.5
		var dir := Vector3(sin(a), 0.0, -cos(a))
		var tan := Vector3(cos(a), 0.0, sin(a))
		var seat := dir * ring_r
		var jl := 1.0 + rng.randf_range(-jitter, jitter)
		# Four points: two on the ring, one lifted spine vertex that gives the fin its thickness,
		# and the tip. Flat, but a closed volume — which is the whole point.
		var v0 := seat + tan * (fin_w * 0.5)
		var v1 := seat - tan * (fin_w * 0.5)
		var v2 := seat + dir * (fin_len * 0.14) + Vector3.UP * (fin_w * 0.42)
		var v3 := seat + dir * (fin_len * jl) + Vector3.UP * (fin_len * (0.18 + rng.randf_range(-jitter, jitter) * 0.25) * jl)
		var g := (v0 + v1 + v2 + v3) * 0.25
		for f: Array in [[v0, v1, v2], [v0, v1, v3], [v0, v2, v3], [v1, v2, v3]]:
			_tri_out(st, f[0], f[1], f[2], g)
	var mesh := st.commit()
	_mesh_cache[key] = mesh
	return mesh


## Emits one triangle facing AWAY from `inside`, with a flat outward normal and the winding Godot
## culls correctly (clockwise from outside, i.e. `(b-a) x (c-a)` pointing INWARD).
static func _tri_out(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, inside: Vector3) -> void:
	var n := (b - a).cross(c - a)
	if n.dot((a + b + c) / 3.0 - inside) < 0.0:
		# already wound Godot's way; the shading normal is the other one
		n = -n
	else:
		var t := b
		b = c
		c = t
	n = n.normalized()
	for v: Vector3 in [a, b, c]:
		st.set_normal(n)
		st.set_uv(Vector2(v.x, v.z))
		st.add_vertex(v)
