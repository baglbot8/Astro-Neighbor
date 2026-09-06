class_name Toast
extends Control
## One notification card: [icon] text. Slides in from the right, lives LIFETIME seconds, slides out.
## icon: a Catalog item id (procedural swatch), or "stardust" / "star" / "heart" / "check" / "warn".

signal dismissed(toast: Toast)

const LIFETIME := 3.0
const WIDTH := 344.0
const HEIGHT := 62.0
const SLIDE := 380.0

var _panel: PanelContainer
var _label: Label
var _icon_slot: Control
var _life := LIFETIME
var _dismissing := false

## Simple drawn icon for non-item toasts.
class SymbolIcon extends Control:
	var kind := "star"
	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.46
		match kind:
			"heart":
				var pts := PackedVector2Array()
				for i in 40:
					var t := TAU * float(i) / 40.0
					var x := 16.0 * pow(sin(t), 3.0)
					var y := -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))
					pts.append(c + Vector2(x, y) * (r / 17.0))
				UIDraw.poly(self, pts, Color("#ff6b8b"))
				UIDraw.circle(self, c + Vector2(-r * 0.35, -r * 0.3), r * 0.14, Color(1, 1, 1, 0.8))
			"check":
				UIDraw.circle(self, c, r, UIStyle.GREEN)
				var a := c + Vector2(-r * 0.45, 0.0)
				var b := c + Vector2(-r * 0.1, r * 0.35)
				var d := c + Vector2(r * 0.5, -r * 0.35)
				UIDraw.capsule(self, a, b, r * 0.28, Color.WHITE)
				UIDraw.capsule(self, b, d, r * 0.28, Color.WHITE)
			"warn":
				UIDraw.circle(self, c, r, UIStyle.ORANGE)
				UIDraw.capsule(self, c + Vector2(0, -r * 0.5), c + Vector2(0, r * 0.12), r * 0.26, Color.WHITE)
				UIDraw.circle(self, c + Vector2(0, r * 0.5), r * 0.15, Color.WHITE)
			_:
				UIDraw.star(self, c, r, UIStyle.STARDUST, UIStyle.STARDUST_EDGE, 2.0)

func _ready() -> void:
	custom_minimum_size = Vector2(WIDTH, HEIGHT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = false
	_panel = PanelContainer.new()
	_panel.theme_type_variation = "Toast"
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.position = Vector2(SLIDE, 0.0)
	_panel.size = Vector2(WIDTH, HEIGHT)
	add_child(_panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(row)
	_icon_slot = Control.new()
	_icon_slot.custom_minimum_size = Vector2(38.0, 38.0)
	_icon_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_icon_slot)
	_label = UIStyle.make_label("", "Small")
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.custom_minimum_size = Vector2(WIDTH - 90.0, 0.0)
	_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label.max_lines_visible = 2
	_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(_label)

## Sets content and starts the slide-in.
func setup(text: String, icon: String) -> void:
	_label.text = text
	for c in _icon_slot.get_children():
		c.queue_free()
	var icon_node: Control
	if icon != "" and Catalog.has_item(icon):
		var g := ItemGlyph.new()
		g.set_def(Catalog.get_item(icon))
		icon_node = g
	else:
		var s := SymbolIcon.new()
		s.kind = icon if icon in ["heart", "check", "warn"] else "star"
		icon_node = s
	icon_node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon_slot.add_child(icon_node)
	_panel.position = Vector2(SLIDE, 0.0)
	var t := create_tween()
	t.tween_property(_panel, "position:x", 0.0, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_life = LIFETIME
	set_process(true)

## The line this toast is showing (the HUD uses it to spot a duplicate).
func text() -> String:
	return _label.text if _label != null else ""

func is_dismissing() -> bool:
	return _dismissing

## Restarts the lifetime and gives a small nudge, instead of a second identical card being stacked.
func refresh() -> void:
	if _dismissing:
		return
	_life = LIFETIME
	UIStyle.bump(_panel, 1.06, 0.35)

func _process(delta: float) -> void:
	_life -= delta
	if _life <= 0.0 and not _dismissing:
		dismiss()

## Slides out and frees itself.
## `duration` shortens the exit; the HUD uses a fast one when a modal panel takes over the screen,
## so a leaving toast never lingers on top of the panel.
func dismiss(duration: float = 0.28) -> void:
	if _dismissing:
		return
	_dismissing = true
	set_process(false)
	var t := create_tween().set_parallel(true)
	t.tween_property(_panel, "position:x", SLIDE, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	t.tween_property(_panel, "modulate:a", 0.0, duration * 0.85)
	t.chain().tween_callback(func() -> void:
		dismissed.emit(self)
		queue_free())
