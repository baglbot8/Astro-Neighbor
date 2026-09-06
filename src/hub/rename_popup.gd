extends CanvasLayer
## Themed "name your planet" popup used by the Town Hall.
##
##   var name: String = await popup.ask(GameState.home_planet_name)   # "" = cancelled
##
## A cream modal with a rounded inset field (max 18 characters), Cancel / Rename pills. Enter
## confirms, Escape cancels, and the field is focused the moment it opens so you can just type.
## Emits EventBus.ui_modal_opened("rename") / ui_modal_closed("rename") so gameplay input freezes.

signal answered(new_name: String)

const MAX_CHARS := 18
const PANEL_WIDTH := 560.0

var _root: Control
var _backdrop: ColorRect
var _panel: PanelContainer
var _field: LineEdit
var _hint: Label
var _ok: Button
var _cancel: Button
var _open := false
var _cooldown := 0.0


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.theme = UIStyle.theme()
	_root.visible = false
	add_child(_root)

	_backdrop = ColorRect.new()
	_backdrop.color = Color(UIStyle.BACKDROP, 0.42)
	_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(_backdrop)

	_panel = PanelContainer.new()
	_panel.theme_type_variation = "ModalContainer"
	_panel.custom_minimum_size = Vector2(PANEL_WIDTH, 0.0)
	_root.add_child(_panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	_panel.add_child(box)

	var title := UIStyle.make_label("Name your planet", "Header", HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(title)

	_field = LineEdit.new()
	_field.max_length = MAX_CHARS
	_field.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_field.custom_minimum_size = Vector2(PANEL_WIDTH - 80.0, 62.0)
	_field.add_theme_font_override("font", UIStyle.font())
	_field.add_theme_font_size_override("font_size", UIStyle.SIZE_HEADER)
	_field.add_theme_color_override("font_color", UIStyle.TEXT_BROWN)
	_field.add_theme_color_override("font_placeholder_color", UIStyle.TEXT_SOFT)
	_field.add_theme_color_override("caret_color", UIStyle.ORANGE)
	_field.add_theme_color_override("selection_color", Color(UIStyle.YELLOW, 0.5))
	_field.add_theme_stylebox_override("normal", UIStyle.make_panel_style(UIStyle.CREAM_INSET, 20, UIStyle.CREAM_EDGE, 3))
	_field.add_theme_stylebox_override("focus", UIStyle.make_panel_style(UIStyle.WHITE, 20, UIStyle.ORANGE, 4))
	_field.text_submitted.connect(func(_t: String) -> void: _answer(true))
	_field.text_changed.connect(func(_t: String) -> void: _update_hint())
	box.add_child(_field)

	_hint = UIStyle.make_label("", "Hint", HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(_hint)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	box.add_child(row)
	_cancel = UIStyle.make_button("Cancel", "Pill", 160.0)
	_cancel.pressed.connect(func() -> void: _answer(false))
	row.add_child(_cancel)
	_ok = UIStyle.make_button("Rename", "PillPrimary", 160.0)
	_ok.pressed.connect(func() -> void: _answer(true))
	row.add_child(_ok)


func is_open() -> bool:
	return _open


## Opens the popup pre-filled with `current` and waits. Returns the trimmed new name, or "" when
## the player cancelled or cleared the field.
func ask(current: String) -> String:
	_field.text = current
	_field.select_all()
	_update_hint()
	_open = true
	_cooldown = 0.18
	_root.visible = true
	EventBus.ui_modal_opened.emit("rename")
	UIStyle.play_open()
	_backdrop.modulate.a = 0.0
	create_tween().tween_property(_backdrop, "modulate:a", 1.0, 0.18)
	_panel.reset_size()
	_panel.position = (_root.size - _panel.size) * 0.5
	UIStyle.pop_in(_panel)
	_field.grab_focus()
	var out: String = await answered
	return out


func _update_hint() -> void:
	var n := _field.text.strip_edges().length()
	_hint.text = "%d / %d characters" % [n, MAX_CHARS]
	_ok.disabled = n == 0


func _answer(confirm: bool) -> void:
	if not _open:
		return
	var out := _field.text.strip_edges() if confirm else ""
	if confirm and out == "":
		UIStyle.wobble(_field, 5.0)
		UIStyle.play_cancel()
		return
	_open = false
	_field.release_focus()
	EventBus.ui_modal_closed.emit("rename")
	if confirm:
		UIStyle.play_confirm()
	else:
		UIStyle.play_cancel()
	create_tween().tween_property(_backdrop, "modulate:a", 0.0, 0.16)
	var t := UIStyle.pop_out(_panel, 0.16)
	t.chain().tween_callback(func() -> void: _root.visible = false)
	answered.emit(out)


func _process(delta: float) -> void:
	if not _open:
		return
	_cooldown -= delta
	if _cooldown > 0.0:
		return
	# Polled as well as event-driven: the Director drives input through Input.action_press(), which
	# never produces an InputEvent, so `_input` alone would never see a cancel in an automated run.
	# Only "cancel" is polled — polling accept would make typing the letter E confirm the rename.
	if UIFocus.cancel_pressed():
		_answer(false)


func _input(event: InputEvent) -> void:
	if not _open or _cooldown > 0.0:
		return
	if event.is_action_pressed("cancel"):
		get_viewport().set_input_as_handled()
		_answer(false)
