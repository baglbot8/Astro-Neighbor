class_name ToggleSwitch
extends Control
## Procedurally drawn on/off switch (orange when on). Keyboard/gamepad: activate() toggles, adjust(dir) sets.

signal toggled(on: bool)

const TRACK := Vector2(64.0, 32.0)
## MOBILE (R2.10): a thumb-sized switch. The whole row is the hit area, and the track grows with it.
const TRACK_MOBILE := Vector2(92.0, 46.0)

@export var on: bool = false: set = set_on

var _knob_t := 0.0

func _track() -> Vector2:
	return TRACK_MOBILE if MobileUI.is_mobile() else TRACK


## Re-applies the per-front-end geometry after a runtime UI-mode switch (pause > Settings).
func refresh_platform() -> void:
	var t := _track()
	custom_minimum_size = Vector2(t.x + 90.0, maxf(36.0, t.y + 10.0))
	queue_redraw()


func _ready() -> void:
	refresh_platform()
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	_knob_t = 1.0 if on else 0.0
	focus_entered.connect(func() -> void:
		UIStyle.play_tick()
		queue_redraw())
	focus_exited.connect(queue_redraw)
	mouse_entered.connect(func() -> void:
		if is_visible_in_tree():
			grab_focus())

func set_on(v: bool) -> void:
	if on == v:
		return
	on = v
	toggled.emit(on)
	if is_inside_tree():
		var t := create_tween()
		t.tween_method(func(x: float) -> void:
			_knob_t = x
			queue_redraw(), _knob_t, 1.0 if on else 0.0, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		_knob_t = 1.0 if on else 0.0
	queue_redraw()

## Flip the switch (accept button).
func activate() -> void:
	set_on(not on)
	UIStyle.play_confirm()

## Left = off, right = on.
func adjust(dir: int) -> void:
	if (dir > 0) != on:
		set_on(dir > 0)
		UIStyle.play_tick()

func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
		activate()
		accept_event()

func _draw() -> void:
	var trk := _track()
	var r := Rect2(Vector2(0.0, (size.y - trk.y) * 0.5), trk)
	var col := UIStyle.CREAM_EDGE.lerp(UIStyle.ORANGE, _knob_t)
	if has_focus():
		UIDraw.rrect(self, r.grow(4.0), UIStyle.YELLOW, trk.y * 0.5 + 4.0)
	UIDraw.rrect(self, r, col, trk.y * 0.5)
	var kr := trk.y * 0.5 - 4.0
	var kx := lerpf(r.position.x + kr + 4.0, r.end.x - kr - 4.0, _knob_t)
	var kc := Vector2(kx, r.get_center().y)
	UIDraw.circle(self, kc + Vector2(0, 1.5), kr, Color(0, 0, 0, 0.12))
	UIDraw.circle(self, kc, kr, UIStyle.WHITE)
	var f := get_theme_default_font()
	var fs: int = UIStyle.SIZE_SMALL + (4 if MobileUI.is_mobile() else 0)
	var y := (size.y - (f.get_ascent(fs) + f.get_descent(fs))) * 0.5 + f.get_ascent(fs)
	draw_string(f, Vector2(trk.x + 14.0, y), "On" if on else "Off", HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs, UIStyle.TEXT_BROWN)
