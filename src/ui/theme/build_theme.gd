extends SceneTree
## Generates res://src/ui/theme/astro_theme.tres from the UIStyle palette.
## Run once (and again after editing this file):
##   godot --headless --path . -s res://src/ui/theme/build_theme.gd
## Every UI scene applies the resulting Theme at its root.

const S := preload("res://src/ui/theme/ui_style.gd")

func _init() -> void:
	var theme := Theme.new()
	var font := S.ui_font()
	theme.default_font = font
	theme.default_font_size = S.SIZE_BODY
	_labels(theme)
	_buttons(theme)
	_panels(theme)
	_misc(theme)
	var err := ResourceSaver.save(theme, S.THEME_PATH)
	print("build_theme: saved %s (%s)" % [S.THEME_PATH, error_string(err)])
	quit()

# ----------------------------------------------------------------------------- labels
func _labels(theme: Theme) -> void:
	theme.set_color("font_color", "Label", S.TEXT_BROWN)
	theme.set_font_size("font_size", "Label", S.SIZE_BODY)
	theme.set_constant("line_spacing", "Label", 2)
	var variants := {
		"Title": [S.SIZE_TITLE, S.TEXT_BROWN],
		"Header": [S.SIZE_HEADER, S.TEXT_BROWN],
		"Small": [S.SIZE_SMALL, S.TEXT_BROWN],
		"Soft": [S.SIZE_SMALL, S.TEXT_SOFT],
		"Hint": [S.SIZE_HINT, S.TEXT_SOFT],
		"Dialogue": [S.SIZE_DIALOGUE, S.TEXT_BROWN],
		"OnBlue": [S.SIZE_BODY, S.WHITE],
		"OnBlueSmall": [S.SIZE_SMALL, S.WHITE],
		"Price": [S.SIZE_SMALL, S.TEXT_BROWN],
		"PriceBad": [S.SIZE_SMALL, S.RED],
		"Badge": [14, S.WHITE],
		"CardName": [15, S.TEXT_BROWN],
	}
	for v in variants:
		theme.add_type(v)
		theme.set_type_variation(v, "Label")
		theme.set_font_size("font_size", v, int(variants[v][0]))
		theme.set_color("font_color", v, variants[v][1])
	# RichTextLabel (dialogue body + descriptions)
	theme.set_color("default_color", "RichTextLabel", S.TEXT_BROWN)
	theme.set_font_size("normal_font_size", "RichTextLabel", S.SIZE_BODY)
	theme.set_stylebox("normal", "RichTextLabel", StyleBoxEmpty.new())
	theme.set_stylebox("focus", "RichTextLabel", StyleBoxEmpty.new())
	theme.set_constant("line_separation", "RichTextLabel", 4)
	theme.add_type("DialogueText")
	theme.set_type_variation("DialogueText", "RichTextLabel")
	theme.set_font_size("normal_font_size", "DialogueText", S.SIZE_DIALOGUE)
	theme.set_constant("line_separation", "DialogueText", 6)
	theme.add_type("SoftText")
	theme.set_type_variation("SoftText", "RichTextLabel")
	theme.set_font_size("normal_font_size", "SoftText", S.SIZE_SMALL)
	theme.set_color("default_color", "SoftText", S.TEXT_SOFT)

# ----------------------------------------------------------------------------- buttons
## Variations whose fill is yellow / orange: a yellow focus ring would vanish on them, so they get a
## dark-brown ring instead (critic: "Wear" and "Back" were yellow-ring-on-yellow).
const WARM_FILL_TYPES: PackedStringArray = ["PillPrimary", "PillOrange", "TabActive"]

func _button_set(theme: Theme, type: String, bg: Color, edge: Color, text: Color, radius: int,
		margin_h: float, margin_v: float, shadow: int, border: int = 3) -> void:
	var normal := S.make_panel_style(bg, radius, edge, border, shadow, margin_h)
	normal.content_margin_top = margin_v
	normal.content_margin_bottom = margin_v
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = bg.lightened(0.06)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = bg.darkened(0.08)
	pressed.shadow_size = 0
	pressed.content_margin_top = margin_v + 2.0
	pressed.content_margin_bottom = margin_v - 2.0
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = bg.lerp(Color("#d8d0bd"), 0.55)
	disabled.border_color = edge.lerp(Color("#cfc6b1"), 0.5)
	disabled.shadow_size = 0
	theme.set_stylebox("normal", type, normal)
	theme.set_stylebox("hover", type, hover)
	theme.set_stylebox("pressed", type, pressed)
	theme.set_stylebox("hover_pressed", type, pressed)
	theme.set_stylebox("disabled", type, disabled)
	var warm := WARM_FILL_TYPES.has(type)
	theme.set_stylebox("focus", type, S.make_focus_style(radius, 5 if warm else 4, 4.0,
		S.FOCUS_ON_WARM if warm else S.YELLOW))
	theme.set_color("font_color", type, text)
	theme.set_color("font_hover_color", type, text)
	theme.set_color("font_pressed_color", type, text)
	theme.set_color("font_hover_pressed_color", type, text)
	theme.set_color("font_focus_color", type, text)
	theme.set_color("font_disabled_color", type, Color(text, 0.45))
	theme.set_color("icon_normal_color", type, text)
	theme.set_font_size("font_size", type, S.SIZE_BODY)
	theme.set_constant("h_separation", type, 8)
	theme.set_constant("outline_size", type, 0)

func _buttons(theme: Theme) -> void:
	# Base Button = cream pill.
	_button_set(theme, "Button", S.CREAM, S.CREAM_EDGE, S.TEXT_BROWN, S.RADIUS_PILL, 26.0, 10.0, 6)
	var variants := {
		# name: [bg, edge, text, radius, margin_h, margin_v, shadow, border]
		"Pill": [S.CREAM, S.CREAM_EDGE, S.TEXT_BROWN, S.RADIUS_PILL, 26.0, 10.0, 6, 3],
		"PillPrimary": [S.YELLOW, S.YELLOW_EDGE, S.TEXT_BROWN, S.RADIUS_PILL, 26.0, 10.0, 6, 3],
		"PillBlue": [S.NAME_BLUE, S.NAME_BLUE_EDGE, S.WHITE, S.RADIUS_PILL, 26.0, 10.0, 6, 3],
		"PillOrange": [S.ORANGE, S.ORANGE_EDGE, S.WHITE, S.RADIUS_PILL, 26.0, 10.0, 6, 3],
		"PillSmall": [S.CREAM, S.CREAM_EDGE, S.TEXT_BROWN, S.RADIUS_PILL, 18.0, 6.0, 4, 2],
		"Choice": [S.CREAM, S.CREAM_EDGE, S.TEXT_BROWN, S.RADIUS_PILL, 28.0, 9.0, 5, 3],
		"Card": [S.CARD_FILL, S.CREAM_EDGE, S.TEXT_BROWN, S.RADIUS_CARD, 8.0, 8.0, 4, 2],
		"Tab": [S.CREAM_DEEP, S.CREAM_DEEP, S.TEXT_SOFT, S.RADIUS_PILL, 18.0, 6.0, 0, 0],
		"TabActive": [S.YELLOW, S.YELLOW_EDGE, S.TEXT_BROWN, S.RADIUS_PILL, 18.0, 6.0, 3, 2],
	}
	for v in variants:
		var a: Array = variants[v]
		theme.add_type(v)
		theme.set_type_variation(v, "Button")
		_button_set(theme, v, a[0], a[1], a[2], int(a[3]), float(a[4]), float(a[5]), int(a[6]), int(a[7]))
	theme.set_font_size("font_size", "PillSmall", S.SIZE_SMALL)
	theme.set_font_size("font_size", "Tab", S.SIZE_SMALL)
	theme.set_font_size("font_size", "TabActive", S.SIZE_SMALL)
	theme.set_font_size("font_size", "Choice", S.SIZE_BODY)
	# Cards draw their own content; keep the button label invisible.
	theme.set_font_size("font_size", "Card", 1)
	# Tabs: no visual state change on hover so the active one stays the only highlight.
	theme.set_stylebox("hover", "Tab", theme.get_stylebox("normal", "Tab"))
	theme.set_stylebox("focus", "Tab", S.make_focus_style(S.RADIUS_PILL, 3, 2.0))
	theme.set_stylebox("focus", "TabActive", S.make_focus_style(S.RADIUS_PILL, 3, 2.0, S.FOCUS_ON_WARM))

# ----------------------------------------------------------------------------- panels
func _panels(theme: Theme) -> void:
	var panel := S.make_panel_style(S.CREAM, S.RADIUS, S.CREAM_EDGE, 3, 12, 22.0)
	theme.set_stylebox("panel", "PanelContainer", panel)
	theme.set_stylebox("panel", "Panel", panel)
	# The reference speech box (reference/AC Reference 4 copy.jpg) has NO border — just a soft cream
	# blob with a gentle drop shadow — so Speech is borderless with a bigger, softer shadow.
	var speech := S.make_panel_style(S.CREAM, 44, Color.TRANSPARENT, 0, 22, 30.0)
	speech.shadow_color = Color(0.30, 0.19, 0.06, 0.22)
	speech.shadow_offset = Vector2(0.0, 6.0)
	var variants := {
		# name: [base, stylebox]
		"Speech": ["Panel", speech],
		"Modal": ["Panel", S.make_panel_style(S.CREAM, 34, S.CREAM_EDGE, 3, 18, 26.0)],
		"ModalContainer": ["PanelContainer", S.make_panel_style(S.CREAM, 34, S.CREAM_EDGE, 3, 18, 26.0)],
		"Inset": ["PanelContainer", S.make_panel_style(S.CREAM_INSET, 24, S.CREAM_EDGE, 2, 0, 18.0)],
		"GridWell": ["PanelContainer", S.make_panel_style(S.CREAM_INSET, 24, S.CREAM_EDGE, 2, 0, 12.0)],
		"HudPill": ["PanelContainer", S.make_pill_style(S.CREAM, S.CREAM_EDGE, 3, 6, 18.0, 6.0)],
		"HudPillSoft": ["PanelContainer", S.make_pill_style(Color(S.CREAM, 0.86), Color(S.CREAM_EDGE, 0.6), 2, 0, 16.0, 6.0)],
		"NameTag": ["PanelContainer", S.make_pill_style(S.NAME_BLUE, S.NAME_BLUE_EDGE, 0, 5, 22.0, 6.0)],
		"Toast": ["PanelContainer", S.make_panel_style(S.CREAM, 22, S.CREAM_EDGE, 3, 8, 12.0)],
		"Banner": ["PanelContainer", S.make_panel_style(S.CREAM, 36, S.CREAM_EDGE, 3, 14, 26.0)],
		"ChoiceBox": ["PanelContainer", S.make_panel_style(S.CREAM, 30, S.CREAM_EDGE, 3, 12, 14.0)],
		"Tag": ["PanelContainer", S.make_pill_style(S.NAME_BLUE, S.NAME_BLUE_EDGE, 0, 0, 12.0, 2.0)],
		"Badge": ["PanelContainer", S.make_pill_style(S.ORANGE, S.ORANGE_EDGE, 0, 2, 8.0, 1.0)],
	}
	for v in variants:
		theme.add_type(v)
		theme.set_type_variation(v, variants[v][0])
		theme.set_stylebox("panel", v, variants[v][1])
	var banner_style := theme.get_stylebox("panel", "Banner") as StyleBoxFlat
	banner_style.content_margin_left = 48.0
	banner_style.content_margin_right = 48.0
	banner_style.content_margin_top = 14.0
	banner_style.content_margin_bottom = 18.0

# ----------------------------------------------------------------------------- misc controls
func _misc(theme: Theme) -> void:
	# ScrollContainer / scrollbars
	theme.set_stylebox("panel", "ScrollContainer", StyleBoxEmpty.new())
	var track := S.make_panel_style(Color(S.CREAM_EDGE, 0.55), S.RADIUS_PILL, Color.TRANSPARENT, 0, 0, 0.0)
	track.set_content_margin_all(0.0)
	var grabber := S.make_panel_style(S.TEXT_SOFT, S.RADIUS_PILL, Color.TRANSPARENT, 0, 0, 0.0)
	grabber.set_content_margin_all(0.0)
	var grabber_hi := grabber.duplicate() as StyleBoxFlat
	grabber_hi.bg_color = S.TEXT_BROWN
	for bar in ["VScrollBar", "HScrollBar"]:
		theme.set_stylebox("scroll", bar, track)
		theme.set_stylebox("scroll_focus", bar, track)
		theme.set_stylebox("grabber", bar, grabber)
		theme.set_stylebox("grabber_highlight", bar, grabber_hi)
		theme.set_stylebox("grabber_pressed", bar, grabber_hi)
	# LineEdit (town hall rename etc.)
	var le := S.make_panel_style(S.CARD_FILL, 18, S.CREAM_EDGE, 3, 0, 14.0)
	le.content_margin_top = 8.0
	le.content_margin_bottom = 8.0
	theme.set_stylebox("normal", "LineEdit", le)
	theme.set_stylebox("read_only", "LineEdit", le)
	theme.set_stylebox("focus", "LineEdit", S.make_focus_style(18, 3, 2.0))
	theme.set_color("font_color", "LineEdit", S.TEXT_BROWN)
	theme.set_color("font_placeholder_color", "LineEdit", S.TEXT_SOFT)
	theme.set_color("caret_color", "LineEdit", S.ORANGE)
	theme.set_color("selection_color", "LineEdit", Color(S.YELLOW, 0.5))
	theme.set_font_size("font_size", "LineEdit", S.SIZE_BODY)
	# ProgressBar (favor progress etc.)
	var pb_bg := S.make_panel_style(S.CREAM_EDGE, S.RADIUS_PILL, Color.TRANSPARENT, 0, 0, 0.0)
	pb_bg.set_content_margin_all(0.0)
	var pb_fill := S.make_panel_style(S.YELLOW, S.RADIUS_PILL, Color.TRANSPARENT, 0, 0, 0.0)
	pb_fill.set_content_margin_all(0.0)
	theme.set_stylebox("background", "ProgressBar", pb_bg)
	theme.set_stylebox("fill", "ProgressBar", pb_fill)
	theme.set_color("font_color", "ProgressBar", S.TEXT_BROWN)
	# Containers
	theme.set_constant("separation", "VBoxContainer", 10)
	theme.set_constant("separation", "HBoxContainer", 10)
	theme.set_constant("h_separation", "GridContainer", 12)
	theme.set_constant("v_separation", "GridContainer", 12)
	# Tooltips (just in case)
	theme.set_stylebox("panel", "TooltipPanel", S.make_panel_style(S.CREAM, 14, S.CREAM_EDGE, 2, 6, 10.0))
	theme.set_color("font_color", "TooltipLabel", S.TEXT_BROWN)
