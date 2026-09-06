class_name ConfirmPopup
extends Control
## Small centered "Are you sure?" panel with Yes / No pill buttons.
##   var ok: bool = await confirm.ask("Buy Moon Lamp for 240?", "Yes", "No", 240)
## Keyboard/gamepad: left/right (or up/down) switch, accept confirms, cancel answers No. Mouse works too.

signal answered(yes: bool)

const PANEL_WIDTH := 500.0

var _backdrop: ColorRect
var _panel: PanelContainer
var _label: Label
var _price_row: HBoxContainer
var _price_label: Label
var _yes: Button
var _no: Button
var _open := false
var _index := 0
var _cooldown := 0.0
var _repeat := UIFocus.NavRepeat.new()

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_backdrop = ColorRect.new()
	_backdrop.color = Color(UIStyle.BACKDROP, 0.35)
	_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_backdrop)
	_panel = PanelContainer.new()
	_panel.theme_type_variation = "ModalContainer"
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(PANEL_WIDTH, 0.0)
	add_child(_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	_panel.add_child(box)
	_label = UIStyle.make_label("", "", HORIZONTAL_ALIGNMENT_CENTER)
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.custom_minimum_size = Vector2(PANEL_WIDTH - 60.0, 0.0)
	box.add_child(_label)
	_price_row = HBoxContainer.new()
	_price_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_price_row.add_theme_constant_override("separation", 6)
	var star := StarIcon.new()
	star.icon_size = 28.0
	_price_row.add_child(star)
	_price_label = UIStyle.make_label("", "Header")
	_price_row.add_child(_price_label)
	_price_row.visible = false
	box.add_child(_price_row)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 18)
	box.add_child(buttons)
	_no = UIStyle.make_button("No", "Pill", 150.0)
	_no.pressed.connect(func() -> void: _answer(false))
	_no.focus_entered.connect(func() -> void: _index = 0)
	buttons.add_child(_no)
	_yes = UIStyle.make_button("Yes", "PillPrimary", 150.0)
	_yes.pressed.connect(func() -> void: _answer(true))
	_yes.focus_entered.connect(func() -> void: _index = 1)
	buttons.add_child(_yes)

func is_open() -> bool:
	return _open

## Shows the question and waits for the answer. price >= 0 shows a stardust price row.
func ask(text: String, yes_text: String = "Yes", no_text: String = "No", price: int = -1, default_yes: bool = true) -> bool:
	_label.text = text
	_yes.text = yes_text
	_no.text = no_text
	_price_row.visible = price >= 0
	_price_label.text = str(price)
	_open = true
	_cooldown = 0.18
	_repeat.reset()
	visible = true
	EventBus.ui_modal_opened.emit("confirm")
	_backdrop.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(_backdrop, "modulate:a", 1.0, 0.18)
	_panel.reset_size()
	_panel.position = (size - _panel.size) * 0.5
	UIStyle.pop_in(_panel)
	_index = 1 if default_yes else 0
	_focus_current()
	var yes: bool = await answered
	return yes

func _focus_current() -> void:
	var b := _yes if _index == 1 else _no
	b.grab_focus()

func _answer(yes: bool) -> void:
	if not _open:
		return
	_open = false
	EventBus.ui_modal_closed.emit("confirm")
	if yes:
		UIStyle.play_confirm()
	else:
		UIStyle.play_cancel()
	var t := create_tween()
	t.tween_property(_backdrop, "modulate:a", 0.0, 0.16)
	var p := UIStyle.pop_out(_panel, 0.16)
	p.chain().tween_callback(func() -> void: visible = false)
	answered.emit(yes)

func _process(delta: float) -> void:
	if not _open:
		return
	_cooldown -= delta
	if _cooldown > 0.0:
		return
	var step := _repeat.poll(delta)
	if step.x != 0 or step.y != 0:
		_index = 1 - _index
		_focus_current()
	if UIFocus.accept_pressed():
		_answer(_index == 1)
	elif UIFocus.cancel_pressed():
		_answer(false)

func _input(event: InputEvent) -> void:
	if _open:
		UIFocus.consume_nav_event(self, event)
