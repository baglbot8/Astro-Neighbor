class_name DialogueBox
extends Control
## ACNH-style speech box (ARCHITECTURE §6). Wide cream rounded panel at the bottom, blue pill name tag
## overlapping the top-left corner, brown typewriter text with voice blips, bouncing yellow marker,
## and stacked pill choices.
##
##   dialogue_box.show_lines("Zorp", ["Hi!", "Nice planet."], "alien", Color("#8a4fe8"))
##   await dialogue_box.finished            # (or: await dialogue_box.show_lines(...))
##   var i: int = await dialogue_box.show_choice("Help me?", ["Sure!", "Later"])   # -1 on cancel
##
## interact / ui_accept: finish the line instantly while typing, otherwise advance. Last line -> finished.
## `cancel` does nothing while lines play (it must not skip a conversation); on a choice it answers -1.
## Emits EventBus.ui_modal_opened("dialogue") when the box appears and ui_modal_closed when it hides.

signal finished
signal choice_made(index: int)

const CHARS_PER_SEC := 40.0
## The box GROWS TO ITS LINE. It used to be a flat 176 px whatever was in it, so a one-line greeting
## - which is most of the writing in the game - left about 70% of the panel as empty cream and every
## conversation read as unfinished. Height is now `inset + wrapped text + bottom pad`, clamped
## between these two, and tweened so consecutive lines of different lengths do not snap.
const PANEL_MIN_HEIGHT := 118.0
const PANEL_MAX_HEIGHT := 236.0
## MOBILE: the shared mobile Theme sets dialogue type 1.2x, so the box's own bounds move with it -
## otherwise a long line clips at PANEL_MAX_HEIGHT instead of growing (the content-sized box is a
## PRESERVE item, and it has to stay content-sized in both front ends).
const PANEL_MIN_HEIGHT_MOBILE := 132.0
const PANEL_MAX_HEIGHT_MOBILE := 286.0
const PANEL_RESIZE := 0.18
const BOTTOM_MARGIN := 34.0
const WIDTH_FRACTION := 0.70
const INPUT_COOLDOWN := 0.14
## After the last line the box lingers briefly so a follow-up show_* call reuses it without flicker.
const LINGER := 0.16
const CHOICE_WIDTH := 300.0
## MOBILE (R2.10). A wider choice column, because the mobile Theme sets the "Choice" pill 1.2x
## bigger and pads it to a thumb-sized target.
const CHOICE_WIDTH_MOBILE := 430.0

# --- layout (all in panel-local pixels) ---
## Text inset from the panel's left/right edge and from its top.
const TEXT_INSET := Vector2(46.0, 28.0)
## Height taken off the panel below the text (room for the advance marker at the bottom edge).
const TEXT_BOTTOM_PAD := 38.0
## Name-tag anchor: it overlaps the panel's top-left corner like the reference screenshot.
const NAME_TAG_POS := Vector2(22.0, -24.0)
## Advance marker size; half of it hangs BELOW the panel edge (reference "AC Reference 4 copy.jpg").
const MARKER_SIZE := Vector2(28.0, 18.0)
## How far the marker bobs up and down.
const MARKER_BOB := 3.0
const MARKER_BOB_SPEED := 5.0
## Gap between the choice box and the panel, and its inset from the panel's right edge.
const CHOICE_GAP := 12.0
const CHOICE_RIGHT_INSET := 20.0

enum State { HIDDEN, LINES, CHOICE, IDLE }

var _state: State = State.HIDDEN
var _lines: PackedStringArray = []
var _line_index := 0
var _voice := "alien"
var _typing := false
var _typed := 0.0
var _visible_chars := 0
var _blip_counter := 0
var _next_blip := 2
var _cooldown := 0.0
var _close_timer := -1.0
var _options: PackedStringArray = []
var _choice_index := 0
var _choice_buttons: Array[Button] = []
var _choices_shown := false
var _repeat := UIFocus.NavRepeat.new()
var _marker_phase := 0.0
var _closing_tween: Tween
## Current (animated) panel height. See PANEL_MIN_HEIGHT.
var _panel_h := PANEL_MIN_HEIGHT
var _resize_tween: Tween

@onready var _panel: Panel = $Panel
@onready var _text: RichTextLabel = $Panel/Text
@onready var _name_tag: PanelContainer = $Panel/NameTag
@onready var _name_label: Label = $Panel/NameTag/NameLabel
@onready var _marker: Control = $Panel/Marker
@onready var _choice_box: PanelContainer = $ChoiceBox
@onready var _choice_list: VBoxContainer = $ChoiceBox/List

## MOBILE: a full-screen catcher that turns a tap anywhere into "advance". It is REQUIRED, not a
## convenience - the touch controls hide behind every modal, so without it a conversation on a
## phone has nothing to press. Added below Panel and ChoiceBox in the draw order and only alive
## while lines are being read, so a choice is always answered by its own button.
var _tap_catcher: Control

func _ready() -> void:
	# The HUD runs with PROCESS_MODE_ALWAYS so the pause menu keeps working while the tree is paused,
	# and children inherit that. The speech box must NOT: now that `pause` opens over a conversation
	# (hud.gd), an ALWAYS box would keep typing and would answer the same `interact` press that is
	# driving the pause menu. PAUSABLE freezes the typewriter and its input for the duration.
	MobileUI.apply_theme(self)
	process_mode = Node.PROCESS_MODE_PAUSABLE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_panel.visible = false
	_choice_box.visible = false
	_marker.visible = false
	_marker.draw.connect(_draw_marker)
	_text.bbcode_enabled = false
	_text.visible_characters = 0
	_text.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	_build_tap_catcher()
	_layout()
	resized.connect(_layout)
	MobileUI.on_mode_changed(func(_m: bool) -> void:
		MobileUI.apply_theme(self)
		_refresh_tap_catcher()
		_layout())


func _build_tap_catcher() -> void:
	_tap_catcher = Control.new()
	_tap_catcher.name = "TapCatcher"
	_tap_catcher.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tap_catcher.mouse_filter = Control.MOUSE_FILTER_STOP
	_tap_catcher.visible = false
	_tap_catcher.gui_input.connect(func(event: InputEvent) -> void:
		var mb := event as InputEventMouseButton
		if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			debug_tap())
	add_child(_tap_catcher)
	move_child(_tap_catcher, 0)


## Tap-to-advance, and the hook a Director timeline calls (a timeline can deliver actions but not
## touches). Same path a finger takes: finish the line if it is still typing, else advance.
func debug_tap() -> void:
	if _state != State.LINES or _cooldown > 0.0:
		return
	_advance()


## Keeps the mobile tap catcher alive only while a line is being read.
func _refresh_tap_catcher() -> void:
	if _tap_catcher != null:
		_tap_catcher.visible = MobileUI.is_mobile() and _state == State.LINES

func _layout() -> void:
	# The speech box keeps clear of a home indicator / notch on mobile (Platform.safe_area_insets).
	var sa := MobileUI.safe_area()
	var w := size.x * WIDTH_FRACTION
	# The box is anchored to its BOTTOM edge, so growing for a longer line pushes the top up and the
	# text never jumps away from the marker.
	_panel.size = Vector2(w, _panel_h)
	_panel.position = Vector2((size.x - w) * 0.5 + (sa.x - sa.z) * 0.5,
		size.y - sa.w - BOTTOM_MARGIN - _panel_h)
	_panel.pivot_offset = Vector2(w * 0.5, _panel_h)
	_text.position = TEXT_INSET
	_text.size = Vector2(w - TEXT_INSET.x * 2.0, _panel_h - TEXT_BOTTOM_PAD - TEXT_INSET.y)
	_name_tag.position = NAME_TAG_POS
	_marker.size = MARKER_SIZE
	_marker.position = Vector2(w * 0.5 - MARKER_SIZE.x * 0.5, _marker_rest_y())
	_choice_box.position = Vector2(_panel.position.x + w - _choice_box.size.x - CHOICE_RIGHT_INSET,
		_panel.position.y - _choice_box.size.y - CHOICE_GAP)

## Resting Y of the advance marker: half of the triangle hangs outside the panel's bottom edge.
func _marker_rest_y() -> float:
	return _panel_h - MARKER_SIZE.y * 0.5

## Width available to the wrapped text inside the panel.
func _text_width() -> float:
	return maxf(80.0, size.x * WIDTH_FRACTION - TEXT_INSET.x * 2.0)

## Height the panel needs for `line`, measured off the real font so it is exact on the first frame
## (RichTextLabel.get_content_height() only settles after a layout pass, which would show one frame
## of the old size and read as a flicker).
func _height_for(line: String) -> float:
	var f: Font = _text.get_theme_font("normal_font")
	var fs: int = _text.get_theme_font_size("normal_font_size")
	var lines := 1
	if f != null and fs > 0:
		var one := maxf(f.get_height(fs), 1.0)
		var box := f.get_multiline_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, _text_width(), fs)
		lines = maxi(1, int(round(box.y / one)))
	var sep := float(_text.get_theme_constant("line_separation"))
	var line_h: float = (f.get_height(fs) if f != null and fs > 0 else 32.0)
	var content := float(lines) * line_h + float(maxi(0, lines - 1)) * sep
	var mobile := MobileUI.is_mobile()
	return clampf(TEXT_INSET.y + content + TEXT_BOTTOM_PAD,
		PANEL_MIN_HEIGHT_MOBILE if mobile else PANEL_MIN_HEIGHT,
		PANEL_MAX_HEIGHT_MOBILE if mobile else PANEL_MAX_HEIGHT)

## Grows / shrinks the box to fit `line`. `instant` is used when the box first appears.
func _resize_for(line: String, instant: bool = false) -> void:
	var want := _height_for(line)
	if _resize_tween != null and _resize_tween.is_valid():
		_resize_tween.kill()
	if instant or absf(want - _panel_h) < 1.0:
		_panel_h = want
		_layout()
		return
	_resize_tween = create_tween()
	_resize_tween.tween_method(_set_panel_height, _panel_h, want, PANEL_RESIZE) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _set_panel_height(h: float) -> void:
	_panel_h = h
	_layout()

func is_open() -> bool:
	return _state != State.HIDDEN

# ----------------------------------------------------------------------------- public API
## Shows a sequence of lines. Resolves (and emits `finished`) after the last line is advanced.
func show_lines(speaker: String, lines: Array, voice_profile: String = "alien", accent: Color = Color("#5b7cff")) -> void:
	_lines.clear()
	for l in lines:
		_lines.append(str(l))
	if _lines.is_empty():
		_lines.append("...")
	_voice = voice_profile
	_hide_choices(true)
	_set_speaker(speaker, accent)
	_open()
	_state = State.LINES
	_line_index = 0
	_start_line()
	await finished

## Shows a prompt with 2-4 pill options. Returns the chosen index, -1 on cancel.
func show_choice(prompt: String, options: Array) -> int:
	_options.clear()
	for o in options:
		_options.append(str(o))
	if _options.is_empty():
		_options.append("OK")
	_hide_choices(true)
	if _state == State.HIDDEN:
		_set_speaker("", Color.WHITE)
	# Set the line BEFORE _open() so a fresh box pops in already sized to the prompt.
	_lines = PackedStringArray([prompt])
	_line_index = 0
	_open()
	_state = State.CHOICE
	_choice_index = 0
	_start_line()
	if prompt == "":
		_complete_line()
	var idx: int = await choice_made
	return idx

## Hides the box immediately (pending awaits resolve: finished / choice_made(-1)).
func hide_box() -> void:
	if _state == State.HIDDEN:
		return
	var prev := _state
	_state = State.HIDDEN
	_refresh_tap_catcher()
	_close_timer = -1.0
	_typing = false
	_hide_choices(false)
	EventBus.ui_modal_closed.emit("dialogue")
	UIStyle.play_close()
	_closing_tween = UIStyle.pop_out(_panel, 0.18)
	_closing_tween.chain().tween_callback(func() -> void:
		if _state == State.HIDDEN:
			visible = false)
	if prev == State.LINES:
		finished.emit()
	elif prev == State.CHOICE:
		choice_made.emit(-1)

# ----------------------------------------------------------------------------- internals
func _open() -> void:
	_close_timer = -1.0
	_cooldown = INPUT_COOLDOWN
	_repeat.reset()
	if _state != State.HIDDEN and _panel.visible and (_closing_tween == null or not _closing_tween.is_valid()):
		return
	if _closing_tween != null and _closing_tween.is_valid():
		_closing_tween.kill()
	visible = true
	_panel.modulate.a = 1.0
	_panel.scale = Vector2.ONE
	if _state == State.HIDDEN:
		EventBus.ui_modal_opened.emit("dialogue")
		# Size to the first line before the pop-in so the box never appears at the wrong height.
		if _lines.size() > 0:
			_panel_h = _height_for(_lines[clampi(_line_index, 0, _lines.size() - 1)])
		_layout()
		UIStyle.pop_in(_panel)
		_panel.pivot_offset = Vector2(_panel.size.x * 0.5, _panel.size.y)
		UIStyle.play_open()
	_state = State.IDLE
	_refresh_tap_catcher()

func _set_speaker(speaker: String, accent: Color) -> void:
	_name_tag.visible = speaker != ""
	if speaker == "":
		return
	var changed := _name_label.text != speaker
	_name_label.text = speaker
	_name_tag.add_theme_stylebox_override("panel", UIStyle.make_pill_style(accent, accent.darkened(0.2), 0, 5, 22.0, 5.0))
	_name_tag.reset_size()
	_name_tag.pivot_offset = Vector2(12.0, _name_tag.size.y)
	_name_tag.rotation = deg_to_rad(-4.0)
	if changed or _state == State.HIDDEN:
		_bounce_name_tag()

func _bounce_name_tag() -> void:
	_name_tag.scale = Vector2(0.4, 0.4)
	var t := _name_tag.create_tween()
	t.tween_property(_name_tag, "scale", Vector2(1.12, 1.12), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(_name_tag, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_SINE)

func _start_line() -> void:
	_refresh_tap_catcher()
	_text.text = _lines[_line_index]
	# Grow / shrink before the typewriter starts: the wrap is already decided by the full string, so
	# the box settles once per line instead of jittering as characters appear.
	_resize_for(_lines[_line_index])
	_text.visible_characters = 0
	_visible_chars = 0
	_typed = 0.0
	_typing = true
	_blip_counter = 0
	_next_blip = 2
	_marker.visible = false
	_cooldown = maxf(_cooldown, 0.08)

func _complete_line() -> void:
	_typing = false
	_text.visible_characters = -1
	_visible_chars = _text.get_total_character_count()
	_on_line_complete()

func _on_line_complete() -> void:
	if _state == State.LINES:
		_marker.visible = true
		_marker_phase = 0.0
	elif _state == State.CHOICE:
		_show_choices()

func _advance() -> void:
	if _typing:
		_complete_line()
		return
	if _state != State.LINES:
		return
	UIStyle.play_sfx("ui_tick", -2.0)
	if _line_index + 1 < _lines.size():
		_line_index += 1
		_start_line()
	else:
		_marker.visible = false
		_state = State.IDLE
		_close_timer = LINGER
		_refresh_tap_catcher()
		finished.emit()

func _show_choices() -> void:
	if _choices_shown:
		return
	_choices_shown = true
	for c in _choice_list.get_children():
		c.queue_free()
	_choice_buttons.clear()
	var cw: float = CHOICE_WIDTH_MOBILE if MobileUI.is_mobile() else CHOICE_WIDTH
	for i in _options.size():
		var b := UIStyle.make_button(_options[i], "Choice", cw - 28.0)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(func() -> void: _choose(i))
		b.focus_entered.connect(func() -> void: _choice_index = i)
		_choice_list.add_child(b)
		_choice_buttons.append(b)
	_choice_box.visible = true
	_choice_box.reset_size()
	_layout()
	_choice_box.pivot_offset = Vector2(_choice_box.size.x, _choice_box.size.y)
	UIStyle.pop_in(_choice_box, 0.25, 0.7)
	_choice_index = 0
	UIFocus.focus(_choice_buttons[0])
	_cooldown = INPUT_COOLDOWN

func _hide_choices(instant: bool) -> void:
	if not _choices_shown:
		return
	_choices_shown = false
	if instant:
		_choice_box.visible = false
		for c in _choice_list.get_children():
			c.queue_free()
		_choice_buttons.clear()
	else:
		var buttons := _choice_buttons.duplicate()
		_choice_buttons.clear()
		var t := UIStyle.pop_out(_choice_box, 0.14, 0.8)
		t.chain().tween_callback(func() -> void:
			for b in buttons:
				b.queue_free())

func _choose(i: int) -> void:
	if _state != State.CHOICE:
		return
	if i >= 0:
		UIStyle.play_confirm()
	else:
		UIStyle.play_cancel()
	_hide_choices(false)
	_state = State.IDLE
	_close_timer = LINGER
	choice_made.emit(i)

func _process(delta: float) -> void:
	if _state == State.HIDDEN:
		return
	if _marker.visible:
		_marker_phase += delta * MARKER_BOB_SPEED
		_marker.position.y = _marker_rest_y() + sin(_marker_phase) * MARKER_BOB
	if _typing:
		_typed += delta * CHARS_PER_SEC
		var total := _text.get_total_character_count()
		var n := mini(int(_typed), total)
		if n > _visible_chars:
			var txt := _text.text
			for ci in range(_visible_chars, n):
				var ch := txt[ci] if ci < txt.length() else " "
				if ch != " " and ch != "\n":
					_blip_counter += 1
					if _blip_counter >= _next_blip:
						_blip_counter = 0
						_next_blip = 2 + (randi() % 2)
						UIStyle.play_voice_blip(_voice)
			_visible_chars = n
			_text.visible_characters = n
		if n >= total:
			_typing = false
			_text.visible_characters = -1
			_on_line_complete()
	if _state == State.IDLE:
		if _close_timer >= 0.0:
			_close_timer -= delta
			if _close_timer < 0.0:
				hide_box()
		return
	_cooldown -= delta
	if _cooldown > 0.0:
		return
	match _state:
		State.LINES:
			# Only interact / ui_accept advance. `cancel` must not skip a conversation.
			if UIFocus.accept_pressed():
				_advance()
		State.CHOICE:
			# On a choice, cancel always answers -1 — even while the prompt is still typing.
			if UIFocus.cancel_pressed():
				_typing = false
				_choose(-1)
				return
			if _typing and UIFocus.accept_pressed():
				_complete_line()
				return
			if not _choices_shown:
				return
			var step := _repeat.poll(delta)
			if step.y != 0:
				_choice_index = UIFocus.list_move(_choice_index, _choice_buttons.size(), step.y)
				UIFocus.focus(_choice_buttons[_choice_index])
			if UIFocus.accept_pressed():
				_choose(_choice_index)
			elif UIFocus.cancel_pressed():
				_choose(-1)

func _input(event: InputEvent) -> void:
	if _state != State.HIDDEN:
		UIFocus.consume_nav_event(self, event)

func _draw_marker() -> void:
	var s := _marker.size
	var pts := PackedVector2Array([Vector2(2.0, 2.0), Vector2(s.x - 2.0, 2.0), Vector2(s.x * 0.5, s.y - 1.0)])
	_marker.draw_colored_polygon(pts, UIStyle.YELLOW)
	var closed := pts.duplicate()
	closed.append(pts[0])
	_marker.draw_polyline(closed, UIStyle.YELLOW_EDGE, 2.0, true)
