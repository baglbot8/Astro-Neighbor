class_name CockpitOverlay
extends CanvasLayer
## The cockpit's screen furniture: the centre dot (with the hold ring that fills while you look at
## something), the item lines at the BOTTOM of the screen, and the white impact flash. Owned and
## driven by `CockpitIntro`; nothing here keeps its own timeline except the typing of a line.
##
## The Professor's radio lines are NOT here: they use the crash's own `RadioCaption` at the TOP, so
## the radio looks and sounds the same in the cockpit and in the fall (INTRO_SPEC 4). The item lines
## are your own thoughts, so they use the same Moonstone panel without a name pill or a voice.
##
## LAYER 96: over the HUD (10), the dialogue layer (10) and RadioCaption (95), under SceneRouter's
## fade (100), so a skip's fade-to-navy still covers everything. The white flash is its own layer,
## FLASH_LAYER 99, so it covers the radio caption too but still sits under SceneRouter's fade and
## SkipConfirm (150).

signal skip_pressed

const LAYER := 96
const FLASH_LAYER := 99
## RadioCaption.CHARS_PER_SEC, so both kinds of line type at the same speed.
const CHARS_PER_SEC := 40.0
const PANEL_BOTTOM := 30.0
const PANEL_WIDTH_FRAC := 0.56
const PANEL_MIN_W := 480.0
const PANEL_MAX_W := 820.0
const PANEL_FADE := 0.22
## The centre dot and the hold ring, in canvas pixels at the 720-row canvas.
const DOT_R := 5.0
const RING_R := 17.0
const RING_W := 4.0
const DOT_FILL := Color("#f4efe6")
const DOT_EDGE := Color(0.10, 0.11, 0.18, 0.75)
const RING_COLOR := Color("#f0a64a")
const ALARM_TINT := Color("#ff5a3c")
const SKIP_MIN_PT := 44.0

var _root: Control
var _dot: _Dot
var _panel: PanelContainer
var _text: Label
var _flash: ColorRect
var _alarm: TextureRect
var _skip: Button
var _flash_layer: CanvasLayer
var _typing := false
var _typed := 0.0
var _total := 0
var _panel_alpha := 0.0
var _panel_target := 0.0


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = UIStyle.theme()
	add_child(_root)
	MobileUI.apply_theme(_root)

	_dot = _Dot.new()
	_dot.name = "Dot"
	_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dot.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dot.visible = false
	_root.add_child(_dot)

	_panel = PanelContainer.new()
	_panel.name = "ItemLine"
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_theme_stylebox_override("panel",
		UIStyle.make_panel_style(UIStyle.CREAM, UIStyle.RADIUS_CARD, UIStyle.CREAM_EDGE, 3, 10, 16.0))
	_panel.modulate.a = 0.0
	_panel.visible = false
	_root.add_child(_panel)
	_text = Label.new()
	_text.name = "Text"
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_text.add_theme_color_override("font_color", UIStyle.TEXT_BROWN)
	_text.add_theme_font_size_override("font_size", int(MobileUI.pick(UIStyle.SIZE_DIALOGUE, 31.0)))
	_text.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	_text.visible_characters = 0
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_text)

	# The alarm: a soft warm-red glow round the screen's edges, pulsed by CockpitIntro. Cheap (one
	# gradient texture) and it reads on a phone where a coloured light in the room did not (round 2:
	# the sun out-lit the alarm lamp and no frame showed it).
	_alarm = TextureRect.new()
	_alarm.name = "Alarm"
	_alarm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_alarm.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_alarm.stretch_mode = TextureRect.STRETCH_SCALE
	var g := Gradient.new()
	g.set_color(0, Color(ALARM_TINT, 0.0))
	g.set_color(1, Color(ALARM_TINT, 0.85))
	g.add_point(0.55, Color(ALARM_TINT, 0.0))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 1.0)
	gt.width = 128
	gt.height = 128
	_alarm.texture = gt
	_alarm.modulate.a = 0.0
	_alarm.visible = false
	_root.add_child(_alarm)
	_root.move_child(_alarm, 0)

	# THE SKIP BUTTON (lead, round 2). In the cockpit a tap is a look, so skipping needs its own
	# target: a small pill at the bottom right, where the crash's "Tap to skip" hint sits, at least
	# SKIP_MIN_PT tall on a phone and clear of the home indicator (MobileUI.safe_area). It never takes
	# keyboard focus, so Enter / Space stay the SKIP_ACTIONS they always were.
	_skip = Button.new()
	_skip.name = "SkipButton"
	_skip.text = "Skip"
	_skip.focus_mode = Control.FOCUS_NONE
	_skip.mouse_filter = Control.MOUSE_FILTER_STOP
	_skip.add_theme_stylebox_override("normal",
		UIStyle.make_pill_style(Color(0.09, 0.10, 0.20, 0.62), Color(0.55, 0.58, 0.72, 0.5), 2, 0, 22.0, 8.0))
	_skip.add_theme_stylebox_override("hover",
		UIStyle.make_pill_style(Color(0.13, 0.14, 0.26, 0.75), Color(0.70, 0.72, 0.85, 0.7), 2, 0, 22.0, 8.0))
	_skip.add_theme_stylebox_override("pressed",
		UIStyle.make_pill_style(Color(0.18, 0.19, 0.32, 0.85), Color(0.80, 0.82, 0.92, 0.8), 2, 0, 22.0, 8.0))
	_skip.add_theme_color_override("font_color", Color("#dfe2ee"))
	_skip.add_theme_color_override("font_hover_color", Color("#ffffff"))
	_skip.add_theme_color_override("font_pressed_color", Color("#ffffff"))
	_skip.add_theme_font_size_override("font_size", int(MobileUI.pick(UIStyle.SIZE_BODY, 26.0)))
	_skip.visible = false
	_skip.pressed.connect(func() -> void: skip_pressed.emit())
	_root.add_child(_skip)

	_flash_layer = CanvasLayer.new()
	_flash_layer.name = "FlashLayer"
	_flash_layer.layer = FLASH_LAYER
	add_child(_flash_layer)
	_flash = ColorRect.new()
	_flash.name = "Flash"
	_flash.color = Color(1.0, 1.0, 1.0, 0.0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flash.visible = false
	_flash_layer.add_child(_flash)

	_root.resized.connect(_layout)
	_layout()


func _layout() -> void:
	if _root == null:
		return
	var vp := _root.size
	var safe := MobileUI.safe_area() if MobileUI.is_mobile() else Vector4.ZERO
	var w := clampf(vp.x * PANEL_WIDTH_FRAC, PANEL_MIN_W, minf(PANEL_MAX_W, vp.x - 40.0))
	_panel.custom_minimum_size = Vector2(w, 0.0)
	_panel.size = Vector2(w, 0.0)
	_panel.reset_size()
	_panel.position = Vector2((vp.x - w) * 0.5, vp.y - _panel.size.y - PANEL_BOTTOM - safe.w)
	if _skip != null:
		# 44 pt minimum: the canvas is 720 rows tall, an iPhone landscape screen ~390 pt, so 1 pt is
		# ~1.85 canvas px and 44 pt ~81 px. Desktop keeps a smaller pill.
		var h := MobileUI.pick(52.0, SKIP_MIN_PT * 720.0 / 390.0)
		_skip.custom_minimum_size = Vector2(h * 1.9, h)
		_skip.reset_size()
		_skip.position = Vector2(vp.x - _skip.size.x - 24.0 - safe.z, vp.y - _skip.size.y - 22.0 - safe.w)


# ============================================================================= public API
func show_line(text: String) -> void:
	_text.text = text
	_text.visible_characters = 0
	_total = _text.get_total_character_count()
	_typed = 0.0
	_typing = true
	_panel_target = 1.0
	_layout()
	UIStyle.play_sfx("text_advance", -16.0)


func hide_line() -> void:
	_typing = false
	_panel_target = 0.0


func is_typing() -> bool:
	return _typing


## True while the panel is on screen at all (typing, held, or still fading out).
func is_showing() -> bool:
	return _panel_alpha > 0.005 or _panel_target > 0.0


func set_dot(on: bool, progress: float, hovering: bool) -> void:
	_dot.visible = on
	_dot.progress = clampf(progress, 0.0, 1.0)
	_dot.hovering = hovering
	_dot.queue_redraw()


func set_flash(a: float) -> void:
	_flash.color.a = clampf(a, 0.0, 1.0)
	_flash.visible = _flash.color.a > 0.001


func set_skip_button(on: bool) -> void:
	if _skip.visible != on:
		_skip.visible = on
		_layout()


## The Skip button's rect in canvas pixels, for tests that click it.
func skip_rect() -> Rect2:
	return _skip.get_global_rect() if _skip != null and _skip.visible else Rect2()


func set_alarm(a: float) -> void:
	_alarm.modulate.a = clampf(a, 0.0, 1.0)
	_alarm.visible = _alarm.modulate.a > 0.005


func flash_alpha() -> float:
	return _flash.color.a


## The item panel's rect, for tests that check the two text boxes never overlap.
func panel_rect() -> Rect2:
	return _panel.get_global_rect()


func shown_text() -> String:
	return _text.text if is_showing() else ""


func _process(delta: float) -> void:
	if _typing:
		_typed += delta * CHARS_PER_SEC
		var n := mini(int(_typed), _total)
		_text.visible_characters = n
		if n >= _total:
			_typing = false
			_text.visible_characters = -1
	_panel_alpha = move_toward(_panel_alpha, _panel_target, delta / PANEL_FADE)
	_panel.modulate.a = _panel_alpha
	_panel.visible = _panel_alpha > 0.005
	# Re-placed every frame it shows: an autowrapping label only knows its real height once it has
	# been laid out at the panel's width, and the panel hangs from the BOTTOM edge. Placed once at
	# show_line, round 1's first line measured its one-letter-per-row height and covered the screen.
	if _panel.visible:
		_layout()


## The centre dot: a small cream dot with a dark edge, and an amber ring that fills clockwise while
## the dot rests on something you have not looked at yet.
class _Dot extends Control:
	var progress := 0.0
	var hovering := false

	func _draw() -> void:
		var s := MobileUI.pick(1.0, 1.25)
		var c := size * 0.5
		var r := CockpitOverlay.DOT_R * s * (1.25 if hovering else 1.0)
		draw_circle(c, r + 1.6 * s, CockpitOverlay.DOT_EDGE)
		draw_circle(c, r, CockpitOverlay.DOT_FILL)
		if hovering:
			var rr := CockpitOverlay.RING_R * s
			draw_arc(c, rr, 0.0, TAU, 40, Color(CockpitOverlay.DOT_EDGE, 0.35), CockpitOverlay.RING_W * s + 2.0, true)
			if progress > 0.0:
				draw_arc(c, rr, -PI * 0.5, -PI * 0.5 + TAU * progress, 40, CockpitOverlay.RING_COLOR,
					CockpitOverlay.RING_W * s, true)
