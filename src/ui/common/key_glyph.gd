class_name KeyGlyph
extends Control
## Small procedurally drawn input glyph: a rounded keycap ("E", "Esc", "Tab", "WASD") or, when a gamepad
## is connected, a colored controller button ("A", "B", "X", "Y", "LB"...).
## Use set_action("interact") to pick the label from the InputMap, or set_text("WASD").

const CAP_HEIGHT := 28.0
const PAD_COLORS := {
	"A": Color("#7ed957"), "B": Color("#ff6b6b"), "X": Color("#4c6fff"), "Y": Color("#ffcc33"),
}
## Joypad button index -> label (Xbox layout, what Godot's SDL mapping reports).
const PAD_LABELS := {
	0: "A", 1: "B", 2: "X", 3: "Y", 4: "Back", 5: "Guide", 6: "Start", 7: "LS", 8: "RS",
	9: "LB", 10: "RB", 11: "Up", 12: "Down", 13: "Left", 14: "Right",
}
const KEY_SHORT := {
	"Escape": "Esc", "Space": "Space", "Enter": "Enter", "Tab": "Tab", "Shift": "Shift", "Backspace": "Bksp",
}

@export var text: String = "E": set = set_text
@export var font_size: int = 15
## Per-glyph override: 1 = gamepad look, 0 = keyboard look, -1 = auto-detect from connected joypads.
var force_gamepad: int = -1
## Global override with the same meaning (showcases / settings can force the controller look everywhere).
static var force_gamepad_all: int = -1

var _gamepad := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gamepad = _detect_gamepad()
	_update_size()

func _detect_gamepad() -> bool:
	if force_gamepad >= 0:
		return force_gamepad == 1
	if force_gamepad_all >= 0:
		return force_gamepad_all == 1
	return Input.get_connected_joypads().size() > 0

## Sets the label text directly.
func set_text(v: String) -> void:
	text = v
	if is_inside_tree():
		_update_size()
	queue_redraw()

## Picks the glyph from the first key (or joypad button) bound to an InputMap action.
func set_action(action: String) -> void:
	_gamepad = _detect_gamepad()
	if not InputMap.has_action(action):
		set_text(action)
		return
	var key_label := ""
	var pad_label := ""
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey and key_label == "":
			var k := ev as InputEventKey
			var code := k.physical_keycode if k.physical_keycode != KEY_NONE else k.keycode
			var s := OS.get_keycode_string(code)
			key_label = str(KEY_SHORT.get(s, s))
		elif ev is InputEventJoypadButton and pad_label == "":
			pad_label = str(PAD_LABELS.get((ev as InputEventJoypadButton).button_index, "?"))
	if _gamepad and pad_label != "":
		set_text(pad_label)
	elif key_label != "":
		set_text(key_label)
	else:
		set_text(pad_label if pad_label != "" else action)

func _update_size() -> void:
	var f := get_theme_default_font()
	var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size).x
	var min_w := CAP_HEIGHT if text.length() <= 1 else w + 16.0
	custom_minimum_size = Vector2(maxf(CAP_HEIGHT, min_w), CAP_HEIGHT + 3.0)
	size = custom_minimum_size

func _draw() -> void:
	var f := get_theme_default_font()
	var h := CAP_HEIGHT
	var rect := Rect2(0.0, 0.0, size.x, h)
	if _gamepad and text.length() == 1 and PAD_COLORS.has(text):
		var col: Color = PAD_COLORS[text]
		var c := Vector2(size.x * 0.5, h * 0.5 + 1.5)
		UIDraw.circle(self, c + Vector2(0, 2.5), h * 0.5, col.darkened(0.35))
		UIDraw.circle(self, c, h * 0.5, col)
		UIDraw.circle(self, c + Vector2(-h * 0.14, -h * 0.16), h * 0.12, Color(1, 1, 1, 0.55))
		_draw_label(f, Color.WHITE, 1.5)
		return
	# Keycap: darker base offset down, cream cap on top, thin edge.
	var radius := 8.0
	UIDraw.rrect(self, Rect2(rect.position + Vector2(0, 3), rect.size), UIStyle.CREAM_EDGE.darkened(0.12), radius)
	UIDraw.rrect(self, rect, UIStyle.WHITE, radius)
	var inner := rect.grow(-1.5)
	UIDraw.rrect(self, inner, UIStyle.WHITE, radius - 1.0)
	_draw_label(f, UIStyle.TEXT_BROWN, 0.0)

func _draw_label(f: Font, color: Color, y_shift: float) -> void:
	var asc := f.get_ascent(font_size)
	var desc := f.get_descent(font_size)
	var y := (CAP_HEIGHT - (asc + desc)) * 0.5 + asc + y_shift
	draw_string(f, Vector2(0.0, y), text, HORIZONTAL_ALIGNMENT_CENTER, size.x, font_size, color)
