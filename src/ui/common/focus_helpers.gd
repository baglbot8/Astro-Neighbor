class_name UIFocus
extends RefCounted
## Keyboard / gamepad / Director-friendly menu navigation.
##
## Every Astro Neighbor menu POLLS Input in _process (Input.is_action_just_pressed) instead of relying on
## Godot's event-driven focus navigation. Reasons: the Director test driver uses Input.action_press (no
## InputEvents are generated), and one code path for keyboard, gamepad and automation keeps behaviour
## identical. Menus call consume_nav_event() from _input so the built-in GUI navigation does not ALSO
## react to the same key press. Mouse events are never consumed, so clicking/hovering keeps working.

const UP_ACTIONS: PackedStringArray = ["ui_up", "move_forward"]
const DOWN_ACTIONS: PackedStringArray = ["ui_down", "move_back"]
const LEFT_ACTIONS: PackedStringArray = ["ui_left", "move_left"]
const RIGHT_ACTIONS: PackedStringArray = ["ui_right", "move_right"]
const ACCEPT_ACTIONS: PackedStringArray = ["ui_accept", "interact"]
const CANCEL_ACTIONS: PackedStringArray = ["cancel", "ui_cancel"]
const PREV_TAB_ACTIONS: PackedStringArray = ["rotate_left"]
const NEXT_TAB_ACTIONS: PackedStringArray = ["rotate_right"]
## Every action a menu owns while open (consumed from the GUI so nothing double-fires).
const ALL_MENU_ACTIONS: PackedStringArray = [
	"ui_up", "ui_down", "ui_left", "ui_right", "ui_accept", "ui_cancel", "ui_focus_next", "ui_focus_prev",
	"move_forward", "move_back", "move_left", "move_right", "interact", "cancel", "jump",
	"rotate_left", "rotate_right", "inventory", "decorate", "pause", "emote", "run",
]

const REPEAT_DELAY := 0.38
const REPEAT_INTERVAL := 0.11

## Held-direction auto repeat. Create one per menu and call poll(delta) every frame.
class NavRepeat:
	var _held := Vector2i.ZERO
	var _timer := 0.0
	var _repeating := false

	## Returns a unit step (x: -1/0/1, y: -1/0/1) when the menu should move this frame, else ZERO.
	func poll(delta: float) -> Vector2i:
		var dir := UIFocus.held_dir()
		if dir == Vector2i.ZERO:
			_held = Vector2i.ZERO
			_repeating = false
			_timer = 0.0
			return Vector2i.ZERO
		if dir != _held:
			_held = dir
			_timer = 0.0
			_repeating = false
			return dir
		_timer += delta
		var limit := REPEAT_INTERVAL if _repeating else REPEAT_DELAY
		if _timer >= limit:
			_timer = 0.0
			_repeating = true
			return dir
		return Vector2i.ZERO

	func reset() -> void:
		_held = Vector2i.ZERO
		_timer = 0.0
		_repeating = false

static func _any_pressed(actions: PackedStringArray) -> bool:
	for a in actions:
		if InputMap.has_action(a) and Input.is_action_pressed(a):
			return true
	return false

static func _any_just_pressed(actions: PackedStringArray) -> bool:
	for a in actions:
		if InputMap.has_action(a) and Input.is_action_just_pressed(a):
			return true
	return false

## Direction currently held (for repeat handling).
static func held_dir() -> Vector2i:
	var d := Vector2i.ZERO
	if _any_pressed(LEFT_ACTIONS):
		d.x -= 1
	if _any_pressed(RIGHT_ACTIONS):
		d.x += 1
	if _any_pressed(UP_ACTIONS):
		d.y -= 1
	if _any_pressed(DOWN_ACTIONS):
		d.y += 1
	return d

## Direction pressed this frame only.
static func just_dir() -> Vector2i:
	var d := Vector2i.ZERO
	if _any_just_pressed(LEFT_ACTIONS):
		d.x -= 1
	if _any_just_pressed(RIGHT_ACTIONS):
		d.x += 1
	if _any_just_pressed(UP_ACTIONS):
		d.y -= 1
	if _any_just_pressed(DOWN_ACTIONS):
		d.y += 1
	return d

static func accept_pressed() -> bool:
	return _any_just_pressed(ACCEPT_ACTIONS)

static func cancel_pressed() -> bool:
	return _any_just_pressed(CANCEL_ACTIONS)

static func prev_tab_pressed() -> bool:
	return _any_just_pressed(PREV_TAB_ACTIONS)

static func next_tab_pressed() -> bool:
	return _any_just_pressed(NEXT_TAB_ACTIONS)

## True for key / joypad events that belong to menu actions (never mouse).
static func is_menu_event(event: InputEvent) -> bool:
	if not (event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion):
		return false
	for a in ALL_MENU_ACTIONS:
		if InputMap.has_action(a) and event.is_action(a):
			return true
	return false

## Call from a menu's _input while it is open: swallows menu key/joypad events so the GUI never double-handles them.
static func consume_nav_event(control: Control, event: InputEvent) -> void:
	if control.is_visible_in_tree() and is_menu_event(event):
		control.get_viewport().set_input_as_handled()

## Moves an index in a list (wrapping optional).
static func list_move(index: int, count: int, step: int, wrap: bool = true) -> int:
	if count <= 0:
		return -1
	var i := index + step
	if wrap:
		return posmod(i, count)
	return clampi(i, 0, count - 1)

## Moves an index inside a column grid. Horizontal moves stay on the row; vertical moves clamp to the last item.
static func grid_move(index: int, count: int, columns: int, dir: Vector2i) -> int:
	if count <= 0:
		return -1
	if index < 0:
		return 0
	var col := index % columns
	var i := index
	if dir.x != 0:
		var nc := col + dir.x
		if nc >= 0 and nc < columns:
			i = index - col + nc
	if dir.y != 0:
		i = index + dir.y * columns
	return clampi(i, 0, count - 1)

## Focuses a control if it exists and is visible; safe to call every frame.
static func focus(control: Control) -> void:
	if control != null and control.is_visible_in_tree() and not control.has_focus():
		control.grab_focus()
