class_name MeteorHud
extends CanvasLayer
## THE SURVEY'S OWN SCREEN BITS (builder METEOR), on top of the safari's SafariLayer (camera, shutter,
## zoom, film, banner): the 2:15 clock (top right, where the safari's End button would be - the survey
## has no End), the "Marked n/5" count under the film, the Professor's radio lines (top centre, under the
## banner), and the friendly retry card. Sizes in the GUI's logical pixels, like SafariLayer.

signal retry_pressed

const LAYER := 31
const CARD_LAYER := 98
const LINE_SECS := 3.6
const CLOCK_W := 118.0
const CLOCK_H := 52.0
const MARKS_H := 36.0

var level: Node
var _root: Control
var _clock_panel: PanelContainer
var _clock: Label
var _marks_panel: PanelContainer
var _marks: Label
var _radio: PanelContainer
var _radio_line: Label
var _queue: Array = []
var _line_left := 0.0
var _card_layer: CanvasLayer
var _card_button: Button
var _time_left := MeteorSurveyLevel.TIME_LIMIT


func _ready() -> void:
	layer = LAYER
	name = "MeteorHud"
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_clock_panel = _pill(Color(UIStyle.NAVY, 0.72))
	_clock = _text("%d:%02d" % [int(MeteorSurveyLevel.TIME_LIMIT) / 60, int(MeteorSurveyLevel.TIME_LIMIT) % 60], 34,
		UIStyle.CREAM)
	_clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_clock_panel.add_child(_clock)
	_root.add_child(_clock_panel)
	_marks_panel = _pill(Color(UIStyle.NAVY, 0.6))
	_marks = _text("Marked 0/5", 22, UIStyle.CREAM)
	_marks_panel.add_child(_marks)
	_root.add_child(_marks_panel)
	_radio = PanelContainer.new()
	_radio.add_theme_stylebox_override("panel", UIStyle.make_panel_style(UIStyle.CREAM, 22))
	_radio.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	_radio.add_child(col)
	col.add_child(_text("Prof. Comet", 18, UIStyle.NAME_BLUE))
	_radio_line = _text("", 24, UIStyle.TEXT_BROWN)
	col.add_child(_radio_line)
	_radio.visible = false
	_root.add_child(_radio)
	_root.visible = false


func _pill(fill: Color) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := UIStyle.make_pill_style(fill, Color(UIStyle.CREAM, 0.5), 2)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


func _text(t: String, size: int, colour: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_override("font", UIStyle.ui_font())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", colour)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func show_play(on: bool) -> void:
	_root.visible = on
	if not on:
		_queue.clear()
		_radio.visible = false


func set_clock(secs_left: float) -> void:
	_time_left = maxf(secs_left, 0.0)
	var s := int(ceil(_time_left))
	_clock.text = "%d:%02d" % [s / 60, s % 60]
	_clock.add_theme_color_override("font_color", UIStyle.YELLOW if _time_left <= 20.0 else UIStyle.CREAM)


func set_marks(n: int, total: int) -> void:
	_marks.text = "Marked %d/%d" % [n, total]


## The Professor over the radio. Lines queue; each shows LINE_SECS.
func say(line: String) -> void:
	_queue.append(line)
	if not _radio.visible:
		_next_line()


func _next_line() -> void:
	if _queue.is_empty():
		_radio.visible = false
		return
	_radio_line.text = str(_queue.pop_front())
	_radio.visible = true
	_line_left = LINE_SECS
	_radio.reset_size()
	AudioManager.play_sfx("comms_key_down_0", -10.0)


func current_line() -> String:
	return _radio_line.text if _radio.visible else ""


func _process(delta: float) -> void:
	var vp := get_viewport().get_visible_rect().size
	var sa := MobileUI.safe_area()
	var left := sa.x + MobileUI.EDGE
	var right := vp.x - sa.z - MobileUI.EDGE
	var top := sa.y + MobileUI.EDGE
	_clock_panel.size = Vector2(CLOCK_W, CLOCK_H)
	_clock_panel.position = Vector2(right - CLOCK_W, top - 4.0)
	# Under the safari's film pill (SafariLayer._layout: film_pos = left, top + DIAL_R * 2 + 30).
	_marks_panel.reset_size()
	_marks_panel.position = Vector2(left, top + SafariLayer.DIAL_R * 2.0 + 30.0 + 22.0)
	if _radio.visible:
		_radio.reset_size()
		_radio.position = Vector2((vp.x - _radio.size.x) * 0.5, top + 64.0)
		_line_left -= delta
		if _line_left <= 0.0:
			_next_line()


# ======================================================================================== THE RETRY CARD
## A dimmed screen, the Professor's kind words and ONE button: "Try again". No game over, no other way
## out (spec 9.2: retry right away, as often as you like). Returns when it is pressed.
func show_retry_card(title: String, line: String) -> void:
	close_card()
	_card_layer = CanvasLayer.new()
	_card_layer.layer = CARD_LAYER
	_card_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_card_layer)
	var root := Control.new()
	root.name = "RetryCard"
	root.process_mode = Node.PROCESS_MODE_ALWAYS
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.theme = UIStyle.theme()
	MobileUI.apply_theme(root)
	_card_layer.add_child(root)
	var dim := ColorRect.new()
	dim.color = UIStyle.BACKDROP
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIStyle.make_panel_style())
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(col)
	var head := _text(title, UIStyle.SIZE_HEADER + 6, UIStyle.TEXT_BROWN)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(head)
	var who := _text("Prof. Comet", 18, UIStyle.NAME_BLUE)
	who.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(who)
	var body := _text(line, UIStyle.SIZE_BODY + 4, UIStyle.TEXT_BROWN)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(body)
	_card_button = UIStyle.make_button("Try again", "PillPrimary", 220.0)
	if MobileUI.is_mobile():
		_card_button.custom_minimum_size.y = MobileUI.MIN_TOUCH
	_card_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(_card_button)
	_card_button.pressed.connect(func() -> void: retry_pressed.emit())
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	panel.modulate.a = 0.0
	get_tree().process_frame.connect(func() -> void:
		if is_instance_valid(panel):
			panel.reset_size()
			panel.position = (root.size - panel.size) * 0.5
			panel.modulate.a = 1.0, CONNECT_ONE_SHOT)
	_card_button.grab_focus.call_deferred()
	UIStyle.play_open()
	await retry_pressed
	close_card()


func card_showing() -> bool:
	return _card_layer != null and is_instance_valid(_card_layer)


func close_card() -> void:
	if _card_layer != null and is_instance_valid(_card_layer):
		_card_layer.queue_free()
	_card_layer = null
	_card_button = null


## For a test run: presses "Try again" the way a finger would (MobileUI.synth_tap on its centre).
func debug_tap_retry() -> bool:
	if _card_button == null or not is_instance_valid(_card_button):
		return false
	MobileUI.synth_tap(_card_button.get_global_rect().get_center())
	return true
