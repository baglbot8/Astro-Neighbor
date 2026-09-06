class_name SpaceMapUI
extends CanvasLayer
## The solar-system map's HUD: a cream card at the bottom naming the focused planet with a one-line
## description, a "(you are here)" tag on the planet you took off from, and the control hint.
## Uses the shared theme (res://src/ui/theme/astro_theme.tres) so it matches the rest of the game.

const CARD_W := 620.0
const EDGE := 26.0

var _card: PanelContainer
var _name_label: Label
var _desc_label: Label
var _here: PanelContainer
var _hint: PanelContainer
var _toasts: VBoxContainer
var _swap: Tween
var _chrome: Control
var _clock_label: Label


func _ready() -> void:
	layer = 5
	var root := Control.new()
	root.name = "Root"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UIStyle.theme()
	add_child(root)

	var column := VBoxContainer.new()
	column.name = "Column"
	column.alignment = BoxContainer.ALIGNMENT_END
	column.add_theme_constant_override("separation", 12)
	column.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	column.offset_top = -260.0
	column.offset_bottom = -EDGE
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(column)

	_card = PanelContainer.new()
	_card.name = "PlanetCard"
	_card.theme_type_variation = "Banner"
	_card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_card.custom_minimum_size = Vector2(CARD_W, 0.0)
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_card)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 4)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(box)

	_name_label = UIStyle.make_label("", "Header", HORIZONTAL_ALIGNMENT_CENTER)
	_name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	box.add_child(_name_label)
	_desc_label = UIStyle.make_label("", "Soft", HORIZONTAL_ALIGNMENT_CENTER)
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_desc_label)

	_here = PanelContainer.new()
	_here.name = "YouAreHere"
	_here.theme_type_variation = "Badge"
	_here.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_here.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var here_label := UIStyle.make_label("(you are here)", "Badge", HORIZONTAL_ALIGNMENT_CENTER)
	_here.add_child(here_label)
	box.add_child(_here)

	_hint = PanelContainer.new()
	_hint.name = "Hint"
	_hint.theme_type_variation = "HudPillSoft"
	_hint.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hint_label := UIStyle.make_label("◀ ▶ choose  ·  E fly  ·  Esc back  ·  P pause", "Hint", HORIZONTAL_ALIGNMENT_CENTER)
	_hint.add_child(hint_label)
	column.add_child(_hint)

	_toasts = VBoxContainer.new()
	_toasts.name = "Toasts"
	_toasts.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_toasts.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_toasts.offset_left = -EDGE - Toast.WIDTH
	_toasts.offset_right = -EDGE
	_toasts.offset_top = EDGE
	_toasts.offset_bottom = EDGE + (Toast.HEIGHT + 8.0) * 2.0
	_toasts.add_theme_constant_override("separation", 8)
	_toasts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_toasts)

	UIStyle.pop_in(_card, 0.35)


## Fills the card. `origin` marks the planet the rocket took off from.
func show_planet(display_name: String, description: String, origin: bool) -> void:
	_name_label.text = display_name
	_desc_label.text = description
	_here.visible = origin
	if _swap != null and _swap.is_valid():
		_swap.kill()
	_card.pivot_offset = _card.size * 0.5
	_card.scale = Vector2(0.94, 0.94)
	_swap = _card.create_tween()
	_swap.tween_property(_card, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Swaps the hint line (used when the flight starts).
func set_hint(text: String) -> void:
	var label := _hint.get_child(0) as Label
	label.text = text
	_hint.visible = text != ""


## The two HUD chips the planet scenes carry (stardust top-left, clock top-right), rebuilt here for
## the journey's space leg. The pad's launch cutscene fades the real HUD chrome away before the
## departure cut, so nothing pops there; these fade IN mid-flight so that by the time the arrival
## cut lands the chips are already on screen at the same size, in the same corners, and the world
## scene's own HUD simply continues them.
## Positions and styling mirror src/ui/hud/hud.gd::_build_stardust / _build_clock.
func show_flight_chrome(delay: float = 1.4, fade: float = 0.7) -> void:
	if _chrome != null:
		return
	var hud_edge := 24.0
	_chrome = Control.new()
	_chrome.name = "FlightChrome"
	_chrome.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_chrome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chrome.modulate.a = 0.0
	(get_node("Root") as Control).add_child(_chrome)

	var star_pill := PanelContainer.new()
	star_pill.name = "Stardust"
	star_pill.theme_type_variation = "HudPill"
	star_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	star_pill.position = Vector2(hud_edge, hud_edge - 4.0)
	_chrome.add_child(star_pill)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	star_pill.add_child(row)
	var star := StarIcon.new()
	star.icon_size = 30.0
	row.add_child(star)
	row.add_child(UIStyle.make_label(str(GameState.stardust), "Header"))

	var clock_pill := PanelContainer.new()
	clock_pill.name = "Clock"
	clock_pill.theme_type_variation = "HudPill"
	clock_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clock_pill.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	clock_pill.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	clock_pill.offset_right = -hud_edge
	clock_pill.offset_top = hud_edge
	_clock_label = UIStyle.make_label("", "Small")
	clock_pill.add_child(_clock_label)
	_chrome.add_child(clock_pill)
	_refresh_clock()

	var t := create_tween()
	t.tween_interval(delay)
	t.tween_property(_chrome, "modulate:a", 1.0, fade).set_trans(Tween.TRANS_SINE)


func _refresh_clock() -> void:
	if _clock_label != null:
		_clock_label.text = "%s · Day %d" % [UIStyle.format_clock(GameState.time_of_day), GameState.day_count]


func _process(_delta: float) -> void:
	if _clock_label != null:
		_refresh_clock()


## Slides a toast in from the right ("Flying to Zorp's Violet Hollow…").
func toast(text: String, icon: String = "star") -> void:
	var t := Toast.new()
	_toasts.add_child(t)
	t.dismissed.connect(func(_t: Toast) -> void: pass)
	t.setup(text, icon)


## Hides the card and hint while the rocket is flying.
func set_card_visible(v: bool) -> void:
	_card.visible = v
	_hint.visible = v
