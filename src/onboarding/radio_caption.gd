class_name RadioCaption
extends CanvasLayer
## The crash shot's screen furniture: the Professor's radio captions, the navy opening card and the
## "tap to skip" hint. Owned and driven by `CrashIntro`; nothing here keeps its own timeline.
##
## WHY NOT THE DIALOGUE BOX. `DialogueBox` waits for a press to advance and is a "dialogue" modal -
## right for a conversation, wrong for a shot that must keep moving on its own and treat ANY press as
## "skip". So the lines spoken DURING the crash are captions that type and clear on CrashIntro's
## clock. They use the same Moonstone panel language (UIStyle) and, deliberately, the same voice path
## the box uses: `RadioSpeaker.resolve_voice("mayor_orbit_radio")` -> NpcData "mayor_orbit" ->
## `UIStyle.comms_voice_for` -> the shared doot (STYLE_GUIDE "Sound identity", rule 3). Nothing in
## this file picks a voice of its own, so the voice wiring stays exactly where it was finished.
##
## LAYER 95: over the HUD (10) and a standalone dialogue layer (10), under SceneRouter's fade (100),
## so a skip's fade-to-navy still covers the captions.
##
## SIZE ON A PHONE. Text is UIStyle.SIZE_DIALOGUE (26 px at the 720p canvas) and 1.2x on the mobile
## front end - the same step the mobile Theme gives dialogue - so a caption is never smaller than the
## conversation that follows it.

const LAYER := 95
## DialogueBox.CHARS_PER_SEC, so a caption types at the speed a box does.
const CHARS_PER_SEC := 40.0
const SPEAKER_ID := "mayor_orbit_radio"
## SceneRouter's own fade colour (scene_router.gd `_fade.color`), so the router's fade-in from the
## title and this card are the same navy and the hand-over between them cannot be seen.
const CARD_COLOR := Color(0.05, 0.04, 0.12)
const PANEL_TOP := 26.0
const PANEL_WIDTH_FRAC := 0.60
const PANEL_MIN_W := 520.0
const PANEL_MAX_W := 860.0
## Seconds for the panel to fade in / out between lines.
const PANEL_FADE := 0.22
## The on-air dot pulses while the line types (a radio reads as live).
const DOT_SIZE := 14.0

var _root: Control
var _card: ColorRect
var _panel: PanelContainer
var _name_pill: PanelContainer
var _name_label: Label
var _dot: Panel
var _text: Label
var _skip_pill: PanelContainer
var _speaker := "Radio"
var _accent := Color("#c9a15c")
var _voice := ""
var _typing := false
var _typed := 0.0
var _total := 0
var _line_index := 0
var _panel_alpha := 0.0
var _panel_target := 0.0
var _skip_alpha := 0.0
var _skip_target := 0.0
var _time := 0.0


## `speaker_name` is what the name pill shows ("Professor Comet (radio)"); the voice is resolved
## from SPEAKER_ID, never from this string.
func setup(speaker_name: String, accent: Color) -> void:
	_speaker = speaker_name
	_accent = accent
	if _name_label != null:
		_name_label.text = _speaker
		_name_pill.add_theme_stylebox_override("panel",
			UIStyle.make_pill_style(_accent, _accent.darkened(0.2), 0, 5, 18.0, 4.0))


func _ready() -> void:
	layer = LAYER
	# Pausable like the dialogue box: the shot's clock is CrashIntro's _process, and a caption that
	# kept typing behind a paused tree would drift off its picture.
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = UIStyle.theme()
	add_child(_root)
	MobileUI.apply_theme(_root)

	_card = ColorRect.new()
	_card.name = "Card"
	_card.color = CARD_COLOR
	_card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_card)

	_build_panel()
	_build_skip()
	_root.resized.connect(_layout)
	_layout()
	setup(_speaker, _accent)


func _build_panel() -> void:
	_panel = PanelContainer.new()
	_panel.name = "Caption"
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_theme_stylebox_override("panel",
		UIStyle.make_panel_style(UIStyle.CREAM, UIStyle.RADIUS_CARD, UIStyle.CREAM_EDGE, 3, 10, 16.0))
	_panel.modulate.a = 0.0
	_root.add_child(_panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(col)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(head)
	_dot = Panel.new()
	_dot.custom_minimum_size = Vector2(DOT_SIZE, DOT_SIZE)
	_dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dot.add_theme_stylebox_override("panel",
		UIStyle.make_pill_style(UIStyle.YELLOW, UIStyle.YELLOW_EDGE, 2, 0, 0.0, 0.0))
	head.add_child(_dot)
	_name_pill = PanelContainer.new()
	_name_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(_name_pill)
	_name_label = Label.new()
	_name_label.add_theme_color_override("font_color", UIStyle.WHITE)
	_name_label.add_theme_font_size_override("font_size", int(MobileUI.pick(UIStyle.SIZE_SMALL, 21.0)))
	_name_pill.add_child(_name_label)

	_text = Label.new()
	_text.name = "Text"
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.add_theme_color_override("font_color", UIStyle.TEXT_BROWN)
	_text.add_theme_font_size_override("font_size", int(MobileUI.pick(UIStyle.SIZE_DIALOGUE, 31.0)))
	_text.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	_text.visible_characters = 0
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(_text)


func _build_skip() -> void:
	_skip_pill = PanelContainer.new()
	_skip_pill.name = "SkipHint"
	_skip_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# A dark glass pill with light text: it sits over the deep-space navy for most of the shot, where
	# the Moonstone slate-on-cream "Soft" style would be a pale blotch.
	_skip_pill.add_theme_stylebox_override("panel",
		UIStyle.make_pill_style(Color(0.09, 0.10, 0.20, 0.62), Color(0.55, 0.58, 0.72, 0.5), 2, 0, 16.0, 6.0))
	_skip_pill.modulate.a = 0.0
	_root.add_child(_skip_pill)
	var l := Label.new()
	l.text = "Tap to skip" if MobileUI.is_mobile() else "Press any key to skip"
	l.add_theme_color_override("font_color", Color("#dfe2ee"))
	l.add_theme_font_size_override("font_size", int(MobileUI.pick(UIStyle.SIZE_HINT, 19.0)))
	_skip_pill.add_child(l)


func _layout() -> void:
	if _root == null:
		return
	var vp := _root.size
	var safe := MobileUI.safe_area() if MobileUI.is_mobile() else Vector4.ZERO
	var w := clampf(vp.x * PANEL_WIDTH_FRAC, PANEL_MIN_W, minf(PANEL_MAX_W, vp.x - 40.0))
	_panel.custom_minimum_size = Vector2(w, 0.0)
	_panel.size = Vector2(w, 0.0)
	_panel.reset_size()
	_panel.position = Vector2((vp.x - w) * 0.5, PANEL_TOP + safe.y)
	_skip_pill.reset_size()
	_skip_pill.position = Vector2(vp.x - _skip_pill.size.x - 24.0 - safe.z, vp.y - _skip_pill.size.y - 22.0 - safe.w)


# ============================================================================= public API
## Starts typing a line. A line that was still typing is cut off first (voice stops, squelch).
func show_line(text: String) -> void:
	if _typing:
		UIStyle.comms_close_line(true)
	_text.text = text
	_text.visible_characters = 0
	_total = _text.get_total_character_count()
	_typed = 0.0
	_typing = true
	_panel_target = 1.0
	_panel.reset_size()
	_layout()
	_voice = UIStyle.comms_voice_for(RadioSpeaker.resolve_voice(SPEAKER_ID, "elder"), _speaker, _line_index)
	_line_index += 1
	# Each caption is its own short transmission, so each one closes its own turn.
	UIStyle.comms_open_line(_voice, text, true)


func hide_line() -> void:
	stop_voice()
	_panel_target = 0.0


## Cuts the voice off without waiting for the line to finish (a skip, or the node leaving).
func stop_voice() -> void:
	if _typing:
		_typing = false
		UIStyle.comms_close_line(true)


func set_card_alpha(a: float) -> void:
	if _card == null:
		return
	_card.color.a = clampf(a, 0.0, 1.0)
	_card.visible = _card.color.a > 0.001


func show_skip_hint(on: bool) -> void:
	_skip_target = 0.72 if on else 0.0


func is_typing() -> bool:
	return _typing


## The caption panel's rect in canvas pixels and its current opacity - what `CrashIntro`'s trace
## tests the rock, the ship and the contact point against, so "the action is never under the
## caption" is measured per frame at whatever canvas size the run has.
func panel_rect() -> Rect2:
	return _panel.get_global_rect() if _panel != null else Rect2()


func panel_alpha() -> float:
	return _panel_alpha if _panel != null and _panel.visible else 0.0


func _process(delta: float) -> void:
	_time += delta
	if _typing:
		_typed += delta * CHARS_PER_SEC
		var n := mini(int(_typed), _total)
		_text.visible_characters = n
		# Told every frame, exactly as DialogueBox does it: a doot that came due while the voice was
		# busy plays on a later frame with no new letter.
		UIStyle.comms_reveal(n)
		if n >= _total:
			_typing = false
			_text.visible_characters = -1
			UIStyle.comms_close_line(false)
	_panel_alpha = move_toward(_panel_alpha, _panel_target, delta / PANEL_FADE)
	_panel.modulate.a = _panel_alpha
	_panel.visible = _panel_alpha > 0.005
	_skip_alpha = move_toward(_skip_alpha, _skip_target, delta / 0.4)
	_skip_pill.modulate.a = _skip_alpha
	_skip_pill.visible = _skip_alpha > 0.005
	if _dot != null:
		_dot.modulate.a = (0.55 + 0.45 * sin(_time * 9.0)) if _typing else 0.55


func _exit_tree() -> void:
	stop_voice()
