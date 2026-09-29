class_name CaveLayer
extends SafariLayer
## The planet safari's own on-screen controls (safari_layer.gd, read-only): the sun-dial for the three
## minutes and the film count, as on a safari (9.4); only the corner End button reads "Leave" (an
## opaque pill drawn over it; same rect, same tap).


var _leave: Control


func _ready() -> void:
	super._ready()
	_leave = _LeavePill.new()
	_leave.owner_layer = self
	_leave.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_leave.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_leave)


func _process(delta: float) -> void:
	super._process(delta)
	if _leave != null and _root.visible:
		_leave.queue_redraw()


class _LeavePill:
	extends Control
	var owner_layer: SafariLayer

	func _draw() -> void:
		var r := owner_layer.end_rect
		draw_style_box(UIStyle.make_pill_style(UIStyle.NAVY, Color(UIStyle.CREAM, 0.6), 2), r)
		var font := UIStyle.ui_font()
		var t := "Leave"
		var w := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
		draw_string(font, Vector2(r.get_center().x - w * 0.5, r.get_center().y + 7.0), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, UIStyle.CREAM)
