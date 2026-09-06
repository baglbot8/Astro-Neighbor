class_name SegmentedControl
extends Control
## Procedurally drawn "pick one of a few" pill row, in the same family as PillSlider and
## ToggleSwitch so a settings row can hold any of the three.
##
## Built for R2.10's UI-mode setting (Auto / Computer / Phone), which needs three states rather
## than the two a ToggleSwitch can express. Works with every input scheme the project supports:
## `adjust(dir)` for the keyboard and stick, `activate()` for the accept button, a tap or a click
## anywhere in a segment for the mouse and for a finger.
##
## Segment hit areas are at least `MobileUI.MIN_TOUCH` wide on mobile - the control simply grows
## rather than dividing a fixed width into thumb-hostile slivers.

signal selected(index: int)

const HEIGHT := 38.0
const HEIGHT_MOBILE := 56.0
const GAP := 6.0

var options: PackedStringArray = []
var index := 0: set = set_index

var _font: Font


func _ready() -> void:
	_font = UIStyle.font()
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	_apply_min_size()
	focus_entered.connect(func() -> void:
		UIStyle.play_tick()
		queue_redraw())
	focus_exited.connect(queue_redraw)
	mouse_entered.connect(func() -> void:
		if is_visible_in_tree():
			grab_focus())


## Fills the row. `start` is the initially selected index.
func setup(labels: PackedStringArray, start: int = 0) -> void:
	options = labels
	index = clampi(start, 0, maxi(0, labels.size() - 1))
	_apply_min_size()
	queue_redraw()


## Re-applies the per-front-end geometry after a runtime UI-mode switch (pause > Settings).
func refresh_platform() -> void:
	_apply_min_size()
	queue_redraw()


func _apply_min_size() -> void:
	var mobile := MobileUI.is_mobile()
	var h: float = HEIGHT_MOBILE if mobile else HEIGHT
	var seg: float = MobileUI.MIN_TOUCH if mobile else 90.0
	custom_minimum_size = Vector2(seg * float(maxi(1, options.size())), h)


func set_index(v: int) -> void:
	var n := clampi(v, 0, maxi(0, options.size() - 1))
	if n == index:
		return
	index = n
	queue_redraw()
	selected.emit(index)


## Accept button: step to the next option, wrapping.
func activate() -> void:
	if options.is_empty():
		return
	set_index(posmod(index + 1, options.size()))
	UIStyle.play_confirm()


## Left / right on the keyboard, the d-pad or the stick.
func adjust(dir: int) -> void:
	if options.is_empty() or dir == 0:
		return
	var n := clampi(index + signi(dir), 0, options.size() - 1)
	if n != index:
		set_index(n)
		UIStyle.play_tick()


func _segment_rect(i: int) -> Rect2:
	var n := maxf(1.0, float(options.size()))
	var w := (size.x - GAP * (n - 1.0)) / n
	return Rect2(Vector2((w + GAP) * float(i), 0.0), Vector2(w, size.y))


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	for i in options.size():
		# Grown by half the gap so the dead strip between two segments still picks one - a 6 px
		# miss is nothing with a mouse and everything with a thumb.
		if _segment_rect(i).grow(GAP * 0.5).has_point(mb.position):
			if i != index:
				set_index(i)
				UIStyle.play_confirm()
			return


func _draw() -> void:
	if options.is_empty() or _font == null:
		return
	var fs: int = UIStyle.SIZE_SMALL + (4 if MobileUI.is_mobile() else 0)
	for i in options.size():
		var r := _segment_rect(i)
		var live := i == index
		if live and has_focus():
			UIDraw.rrect(self, r.grow(4.0), UIStyle.FOCUS_ON_WARM, r.size.y * 0.5 + 4.0)
		elif live:
			UIDraw.rrect(self, r.grow(2.0), UIStyle.YELLOW_EDGE, r.size.y * 0.5 + 2.0)
		elif has_focus():
			UIDraw.rrect(self, r.grow(2.0), Color(UIStyle.YELLOW, 0.45), r.size.y * 0.5 + 2.0)
		UIDraw.rrect(self, r, UIStyle.YELLOW if live else UIStyle.CREAM_DEEP, r.size.y * 0.5)
		var label := options[i]
		var w := _font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs)
		var y := r.position.y + (r.size.y - (_font.get_ascent(fs) + _font.get_descent(fs))) * 0.5 \
			+ _font.get_ascent(fs)
		draw_string(_font, Vector2(r.get_center().x - w.x * 0.5, y), label,
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs,
			UIStyle.TEXT_BROWN if live else UIStyle.TEXT_SOFT)
