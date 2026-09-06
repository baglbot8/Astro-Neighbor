class_name PillSlider
extends Control
## Procedurally drawn 0..1 slider: cream track, yellow fill, white knob, percentage label.
## Keyboard/gamepad: the owning menu calls adjust(-1 / +1). Mouse: click or drag on the track.

signal value_changed(value: float)

const TRACK_HEIGHT := 14.0
const KNOB_RADIUS := 13.0
const LABEL_WIDTH := 54.0
## MOBILE (R2.10): a fatter track and a bigger knob, in a row tall enough to be a touch target.
const TRACK_HEIGHT_MOBILE := 20.0
const KNOB_RADIUS_MOBILE := 19.0
const LABEL_WIDTH_MOBILE := 68.0

@export var value: float = 0.8: set = set_value
@export var step: float = 0.05

## Per-front-end geometry. Read these, never the raw constants.
func _track_h() -> float:
	return TRACK_HEIGHT_MOBILE if MobileUI.is_mobile() else TRACK_HEIGHT


func _knob_r() -> float:
	return KNOB_RADIUS_MOBILE if MobileUI.is_mobile() else KNOB_RADIUS


func _label_w() -> float:
	return LABEL_WIDTH_MOBILE if MobileUI.is_mobile() else LABEL_WIDTH


## Re-applies the per-front-end geometry after a runtime UI-mode switch (pause > Settings).
func refresh_platform() -> void:
	custom_minimum_size = Vector2(250.0, MobileUI.pick(36.0, 54.0))
	queue_redraw()


func _ready() -> void:
	refresh_platform()
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_entered.connect(func() -> void:
		UIStyle.play_tick()
		queue_redraw())
	focus_exited.connect(queue_redraw)
	mouse_entered.connect(func() -> void:
		if is_visible_in_tree():
			grab_focus())

func set_value(v: float) -> void:
	var nv := clampf(v, 0.0, 1.0)
	if is_equal_approx(nv, value):
		return
	value = nv
	value_changed.emit(value)
	queue_redraw()

## Nudge by one step (dir = -1 / +1).
func adjust(dir: int) -> void:
	set_value(snappedf(value + step * float(dir), step))
	UIStyle.play_tick()

func _track_rect() -> Rect2:
	var th := _track_h()
	var kr := _knob_r()
	var w := size.x - _label_w() - kr * 2.0
	return Rect2(kr, (size.y - th) * 0.5, w, th)

func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	var mm := event as InputEventMouseMotion
	if mb != null and mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
		_set_from_x(mb.position.x)
		accept_event()
	elif mm != null and (mm.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		_set_from_x(mm.position.x)
		accept_event()

func _set_from_x(x: float) -> void:
	var r := _track_rect()
	set_value(snappedf(clampf((x - r.position.x) / maxf(1.0, r.size.x), 0.0, 1.0), step))

func _draw() -> void:
	var r := _track_rect()
	var th := _track_h()
	var kr := _knob_r()
	var lw := _label_w()
	var focused := has_focus()
	UIDraw.rrect(self, r, UIStyle.CREAM_EDGE, th * 0.5)
	var fill_w := r.size.x * value
	if fill_w > 0.0:
		UIDraw.rrect(self, Rect2(r.position, Vector2(maxf(fill_w, th), th)), UIStyle.YELLOW, th * 0.5)
	var knob := Vector2(r.position.x + fill_w, r.get_center().y)
	if focused:
		UIDraw.circle(self, knob, kr + 4.0, UIStyle.YELLOW)
	UIDraw.circle(self, knob + Vector2(0, 2), kr, UIStyle.CREAM_EDGE.darkened(0.1))
	UIDraw.circle(self, knob, kr, UIStyle.WHITE)
	UIDraw.circle(self, knob + Vector2(-3, -4), kr * 0.27, Color(1, 1, 1, 0.9))
	var f := get_theme_default_font()
	var fs: int = UIStyle.SIZE_SMALL + (4 if MobileUI.is_mobile() else 0)
	var txt := "%d%%" % int(round(value * 100.0))
	var y := (size.y - (f.get_ascent(fs) + f.get_descent(fs))) * 0.5 + f.get_ascent(fs)
	draw_string(f, Vector2(size.x - lw + 6.0, y), txt, HORIZONTAL_ALIGNMENT_RIGHT, lw - 6.0, fs, UIStyle.TEXT_BROWN)
