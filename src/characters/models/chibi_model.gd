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
var _eyes: Array[Node3D] = []
var _eye_ovals: Array[MeshInstance3D] = []
var _eye_happy: Array[Node3D] = []
var _eye_round: Array[Node3D] = []
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
	_blink_timer = randf_range(2.0, 4.5)
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
			_blink_timer = randf_range(3.0, 5.0)
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
			oval.scale = Vector3(eye_w * fs * wide, eye_h * fs * wide * _eye_open, eye_d)
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
		var seam := _mi(superellipsoid(Vector3(head_semi.x * 0.795, head_semi.y * 0.10, head_semi.z * 0.795), 2.8, 18, 6),
			_toon(seam_col, _matte({"rim": 0.02})), _head, Vector3(0.0, head_semi.y * seam_frac, 0.012), "CrownSeam")
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
		_mi(superellipsoid(Vector3(semi.x * 0.965, semi.y * 0.085, semi.z * 0.965), 2.8, 16, 6),
			_toon(chamfer, _matte({"rim": 0.02})), _torso, Vector3(0.0, TORSO_Y - semi.y * 0.50, 0.0), "WaistChamfer")
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
func _add_face(eye_color: Color, mouth_color: Color, blush_color: Color, opts: Dictionary = {}) -> void:
	var inset: float = opts.get("inset", 0.004)
	## Eyes may sit proud of the shell (Mayor Orbit's sit on top of his goggle lenses) while the
	## mouth, nose and blush stay flush — hence a separate inset for them.
	var eye_inset: float = opts.get("eye_inset", inset)
	var fs := face_scale
	var m_eye := _toon(eye_color, {"spec": 0.0, "rim": 0.0, "shade": 0.08})
	var m_hl := _toon(GLINT, {"spec": 0.0, "rim": 0.0, "shade": 0.02})
	var m_mouth := _toon(mouth_color, {"spec": 0.0, "rim": 0.0, "shade": 0.06})
	var brow_col: Color = opts.get("brow_color", eye_color)
	var m_brow := _toon(brow_col, {"spec": 0.0, "rim": 0.0, "shade": 0.05})
	var yaws: Array[float] = [-EYE_YAW, EYE_YAW]
	for i in 2:
		var eye := _node("Eye%d" % i, _face, Vector3.ZERO)
		_orient_on_head(eye, yaws[i], EYE_PITCH, eye_inset)
		_eyes.append(eye)
		var oval := _mi(sphere(1.0, 14, 8), m_eye, eye, Vector3.ZERO, "Oval")
		oval.scale = Vector3(eye_w * fs, eye_h * fs, eye_d)
		_eye_ovals.append(oval)
		_add_glint(oval, m_hl)
		# happy "^ ^" — ONE solid arc, the same grammar the robots use
		var happy := _node("Happy", eye, Vector3(0.0, -0.006 * fs, -0.004))
		_mi(arc_tube(0.042 * fs, 0.0115 * fs, deg_to_rad(24.0), deg_to_rad(156.0), 12, 6), m_eye, happy, Vector3.ZERO, "Arc")
		happy.visible = false
		_eye_happy.append(happy)
		# surprised "O O" — one solid round eye, a little bigger than the resting oval
		var round_eye := _node("Round", eye, Vector3(0.0, 0.003, -0.002))
		var ball := _mi(sphere(1.0, 12, 7), m_eye, round_eye, Vector3.ZERO, "Ball")
		ball.scale = Vector3(0.043 * fs, 0.048 * fs, eye_d)
		round_eye.visible = false
		_eye_round.append(round_eye)
		# brow: visible AT REST as a shallow near-straight bar, lifting and steepening for "think"
		_add_brow(eye, m_brow, -1.0 if i == 0 else 1.0)
	# the nose and smile ride on top of the muzzle patch, not on the shell underneath it
	if bool(opts.get("nose", true)):
		_add_nose(Color(opts.get("nose_color", mouth_color)), inset - _muzzle_lift - 0.004)
	_add_mouth(m_mouth, Color(opts.get("mouth_inner", Color("#8c3b52"))), inset - _muzzle_lift - 0.002)
	if bool(opts.get("blush", true)):
		_add_blush(blush_color, inset)


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


## A single antenna: stalk + glowing bulb. Returns the pivot (rotate it to droop) and stores the
## bulb material in meta "bulb_mat" so subclasses can pulse it.
## ---------------------------------------------------------------------------- alien features
## EYESTALKS. Shared by every non-robot neighbour (see reference/'Alien References.webp'): the one
## trait that most separates those creatures from animals is that their eyes are not on their face.
##
## Each spec is `{"base": Vector3, "tip": Vector3, "r": float}` in HEAD-LOCAL space, and specs are
## matched to `_eyes` in order. The eye nodes are only REPOSITIONED, never rebuilt, so every blink,
## squint, happy-arc and surprise state keeps animating exactly as it does on a normal face. Do not
## supply more specs than there are eyes: an eye that cannot blink beside two that can reads as a
## bug, not as an extra eye.
func _add_eyestalks(specs: Array, stalk_color: Color, sclera_color: Color, eyeball_r: float = 0.062) -> void:
	var m_stalk := _toon(stalk_color, _matte({"spec": 0.05}))
	var m_sclera := _toon(sclera_color, _matte({"spec": 0.04, "rim": 0.02}))
	for i in mini(specs.size(), _eyes.size()):
		var spec: Dictionary = specs[i]
		var base: Vector3 = spec["base"]
		var tip: Vector3 = spec["tip"]
		var r: float = float(spec.get("r", 0.030))
		var span := tip - base
		var length := span.length()
		# A capsule runs along its own +Y, so build a basis whose Y follows the stalk.
		var yv := span.normalized()
		var xv := Vector3.RIGHT if absf(yv.dot(Vector3.RIGHT)) < 0.9 else Vector3.FORWARD
		var zv := xv.cross(yv).normalized()
		xv = yv.cross(zv).normalized()
		var stalk := _node("EyeStalk%d" % i, _head, base + span * 0.5)
		stalk.basis = Basis(xv, yv, zv)
		_mi(capsule(r, maxf(0.02, length - r * 2.0), 8, 2), m_stalk, stalk, Vector3.ZERO, "Stem")
		# A pale ball at the tip; the face's dark oval sits proud of it and becomes the pupil.
		_mi(sphere(eyeball_r, 14, 8), m_sclera, _head, tip, "Eyeball%d" % i)
		# Splay each eye outward and down. Two stalks staring dead ahead in parallel look like a toy.
		var splay: float = float(spec.get("splay", 0.20 if tip.x >= 0.0 else -0.20))
		var eye: Node3D = _eyes[i]
		eye.basis = Basis.looking_at(Vector3(splay, -0.14, -1.0).normalized(), Vector3.UP)
		eye.position = tip + eye.basis.z * -(eyeball_r * 0.84)


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
		_mi(rounded_box(Vector3(float(t[1]), size3.y * 0.62, 0.016), 0.005, 8), m_tooth, grin,
			Vector3(float(t[0]), size3.y * 0.56, -0.006), "Tooth")


func _add_antenna(parent: Node3D, offset: Vector3, tilt: float, stalk_color: Color, bulb_color: Color, length: float = 0.20, bulb_r: float = 0.045) -> Node3D:
	var pivot := _node("Antenna", parent, offset)
	pivot.rotation.z = tilt
	_mi(capsule(0.016, length, 8, 2), _toon(stalk_color, _matte({"spec": 0.06})), pivot, Vector3(0.0, length * 0.5, 0.0), "Stalk")
	var bulb_mat := lit_material(bulb_color.darkened(0.48), 1.2, bulb_color).duplicate() as ShaderMaterial
	var bulb := _mi(sphere(bulb_r, 12, 6), bulb_mat, pivot, Vector3(0.0, length + bulb_r * 0.6, 0.0), "Bulb")
	bulb.set_meta("bulb_mat", bulb_mat)
	pivot.set_meta("bulb_mat", bulb_mat)
	pivot.set_meta("rest_tilt", tilt)
	return pivot


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
			st.add_index(a2)
			st.add_index(b2)
			st.add_index(b2 + 1)
			st.add_index(a2)
			st.add_index(b2 + 1)
			st.add_index(a2 + 1)
	var arc := st.commit()
	_mesh_cache[akey] = arc
	return arc
