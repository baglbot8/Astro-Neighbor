class_name TouchStick
extends Control
## The floating left thumbstick (docs/STYLE_GUIDE.md R2.10).
##
## It is NOT a fixed ring the player has to find: it materialises wherever the thumb lands inside a
## generous bottom-left zone and follows the drag from there. A faint "home" ghost is drawn at the
## resting spot while nothing is touching it, purely so a first-time player knows the corner is live.
##
## ANALOGUE, AND IT REPLACES THE SHIFT KEY. A small push walks, a full push runs; there is no run
## button. Nothing in `src/player/player.gd` changes - the stick writes the ordinary
## `move_*` actions with `Input.action_press(action, strength)` plus `run`, and the player keeps
## polling `Input.get_vector` / `Input.is_action_pressed` exactly as it does for a keyboard.
##
## ---------------------------------------------------------------------------------------------
## HOW THE ANALOGUE SPEED IS MADE CONTINUOUS ACROSS THE WALK -> RUN STEP
## `player.gd` computes `target_vel = wish * max_speed * wish_len`, with `max_speed` = WALK_SPEED
## (4.2) or, while `run` is held, RUN_SPEED (7.0), and `wish_len` = the LENGTH of
## `Input.get_vector(...)`. So the stick has to pick BOTH the run flag and a vector length that
## make the speed a single smooth ramp:
##     push m <= 0.60  ->  run OFF, length = m * (7.0 / 4.2)   ->  speed = 7.0 * m   (0 .. 4.2 m/s)
##     push m >  0.60  ->  run ON,  length = m                 ->  speed = 7.0 * m   (4.2 .. 7 m/s)
## Both branches are exactly `7 * m`, so the changeover at m = 0.60 is invisible: 4.2 m/s on either
## side. The astronaut's own animation switch (`speed > WALK_SPEED + 0.6`) then falls where it
## should, a little past the hand-over.
##
## `Input.get_vector` applies a CIRCULAR DEADZONE to the raw strengths, so writing a strength of
## `L` would arrive at the player as `(L - dz) / (1 - dz)`. `_axis_strength` pre-compensates, and
## reads the deadzone out of the InputMap rather than hardcoding 0.2, so retuning the action in
## `project.godot` cannot silently change how fast the thumbstick walks.

## Actions the stick owns. Released together whenever it lets go, so a modal can never open with
## the astronaut still walking.
const MOVE_ACTIONS: PackedStringArray = ["move_left", "move_right", "move_forward", "move_back"]

## Speeds from `src/player/player.gd`. Duplicated deliberately: this file must not import the
## player domain, and the pair is only used to shape the analogue curve - if they ever drift the
## symptom is a small step in speed at the run hand-over, not a broken control.
const WALK_SPEED := 4.2
const RUN_SPEED := 7.0

## Where the ghost ring rests while nothing is touching it, as a fraction of the stick zone.
const HOME := Vector2(0.30, 0.68)

var active := false
var origin := Vector2.ZERO
var knob := Vector2.ZERO
## Zone the stick may appear in, in this control's coordinates. Set by TouchControls.
var zone := Rect2(Vector2.ZERO, Vector2(400.0, 300.0))

## Last strengths written, so an unchanged frame does not re-`action_press` (which would re-arm
## `is_action_just_pressed` every frame for anything else that polls these actions).
var _last: Dictionary = {}
var _last_run := false
## Normalised push, 0..1, after the deadzone rescale. Exposed for the debug readout.
var push := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modulate.a = MobileUI.ALPHA_IDLE


## Resting position of the ghost ring (also where a tap with no drag starts from).
func home_position() -> Vector2:
	return zone.position + zone.size * HOME


func begin(pos: Vector2) -> void:
	active = true
	origin = pos
	knob = pos
	_apply()


func drag(pos: Vector2) -> void:
	if not active:
		return
	knob = pos
	_apply()


func end() -> void:
	active = false
	push = 0.0
	knob = origin
	release_all()
	queue_redraw()


## Drops every action the stick holds. Safe to call at any time.
func release_all() -> void:
	for a in MOVE_ACTIONS:
		if float(_last.get(a, 0.0)) > 0.0:
			Input.action_release(a)
		_last[a] = 0.0
	if _last_run:
		Input.action_release("run")
		_last_run = false


## Offset of the knob from the stick origin, clamped to the ring.
func offset() -> Vector2:
	var d := knob - origin
	return d.limit_length(MobileUI.STICK_TRAVEL)


func _apply() -> void:
	var d := offset()
	var raw := clampf(d.length() / MobileUI.STICK_TRAVEL, 0.0, 1.0)
	# Rescale past the deadzone so the speed ramp starts from zero instead of stepping up to it.
	push = 0.0 if raw <= MobileUI.STICK_DEADZONE \
		else (raw - MobileUI.STICK_DEADZONE) / (1.0 - MobileUI.STICK_DEADZONE)
	_emit_move(d.normalized() if push > 0.0 else Vector2.ZERO, push)
	queue_redraw()


## The circular deadzone `Input.get_vector` will apply to the four move actions (their mean).
func _move_deadzone() -> float:
	var sum := 0.0
	for a in MOVE_ACTIONS:
		sum += InputMap.action_get_deadzone(a) if InputMap.has_action(a) else 0.2
	return sum / float(MOVE_ACTIONS.size())


## Raw per-action strength that makes `Input.get_vector` hand the player a vector of length `want`.
func _axis_strength(want: float) -> float:
	var dz := _move_deadzone()
	return clampf(dz + (1.0 - dz) * want, 0.0, 1.0)


func _emit_move(dir: Vector2, m: float) -> void:
	if m <= 0.0:
		release_all()
		return
	# See the header: run flag + vector length chosen so the speed is one smooth 7 * m ramp.
	var run := m > MobileUI.STICK_RUN_AT
	var want: float = m if run else m * (RUN_SPEED / WALK_SPEED)
	var s := _axis_strength(clampf(want, 0.0, 1.0))
	# Screen up (-y) is "away from the camera" = move_forward, which is what `player.gd` turns into
	# `wish = fwd * (-move.y) + right * move.x`.
	_press("move_right", maxf(dir.x, 0.0) * s)
	_press("move_left", maxf(-dir.x, 0.0) * s)
	_press("move_back", maxf(dir.y, 0.0) * s)
	_press("move_forward", maxf(-dir.y, 0.0) * s)
	if run != _last_run:
		if run:
			Input.action_press("run")
		else:
			Input.action_release("run")
		_last_run = run


func _press(action: String, strength: float) -> void:
	var prev := float(_last.get(action, 0.0))
	if absf(prev - strength) < 0.008:
		return
	_last[action] = strength
	if strength <= 0.0:
		Input.action_release(action)
	else:
		Input.action_press(action, strength)


# ----------------------------------------------------------------------------- draw
## Shapes are drawn fully opaque and the whole transparency rides on `modulate.a` (set by
## TouchControls), so the numbers in R2.10 are the numbers a screenshot measures. The only alpha
## used here is the extra step down for the resting GHOST, which is a hint, not a control.
func _draw() -> void:
	var c := origin if active else home_position()
	var ring_a: float = 1.0 if active else 0.70
	draw_circle(c, MobileUI.STICK_RING_R, Color(UIStyle.CREAM, 0.34 * ring_a))
	draw_arc(c, MobileUI.STICK_RING_R - 2.5, 0.0, TAU, 64,
		Color(UIStyle.CREAM_EDGE, ring_a), 6.0, true)
	draw_arc(c, MobileUI.STICK_RING_R - 6.0, 0.0, TAU, 64,
		Color(UIStyle.TEXT_BROWN, 0.30 * ring_a), 2.0, true)
	# Four tick marks read as a d-pad hint without cluttering the ring.
	for i in 4:
		var a := deg_to_rad(90.0 * float(i))
		var v := Vector2.RIGHT.rotated(a)
		draw_line(c + v * (MobileUI.STICK_RING_R - 20.0), c + v * (MobileUI.STICK_RING_R - 11.0),
			Color(UIStyle.TEXT_BROWN, 0.5 * ring_a), 4.0, true)
	var k := c + (offset() if active else Vector2.ZERO)
	# The knob warms toward the stardust yellow as the push passes into the run band, so the
	# walk/run hand-over is visible as well as felt.
	var knob_fill: Color = UIStyle.CREAM.lerp(UIStyle.YELLOW, clampf(
		(push - MobileUI.STICK_RUN_AT) / (1.0 - MobileUI.STICK_RUN_AT), 0.0, 1.0))
	MobileUI.draw_disc(self, k, MobileUI.STICK_KNOB_R, knob_fill, UIStyle.CREAM_EDGE, 4.0, ring_a)
