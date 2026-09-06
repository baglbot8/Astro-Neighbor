class_name TouchButton
extends Control
## One round, translucent touch control (docs/STYLE_GUIDE.md R2.10).
##
## Two flavours, both drawn procedurally in the project's cream/brown palette:
##   * HOLD buttons own a list of input actions. They `Input.action_press` on touch-down and
##     `Input.action_release` on lift, so holding Boost flies for exactly as long as holding the
##     key does, and nothing in the player or the menus has to know a finger is involved.
##   * TAP buttons emit `tapped` instead, for HUD affordances that call a method (bag, journal,
##     pause) rather than an action.
##
## The hit area is a CIRCLE of `hit_radius`, which is deliberately larger than the drawn
## `radius` - R2.10 asks for at least 48 dp with generous invisible padding, and lets the visual
## be smaller than the target so the world stays visible around it.

signal tapped

enum Glyph { NONE, JUMP, BOOST, BAG, JOURNAL, PAUSE, ROTATE_L, ROTATE_R, CLOSE }

## Actions held down while this button is touched (empty for a TAP button).
var actions: PackedStringArray = []
var glyph: Glyph = Glyph.NONE
var label := ""
var radius := MobileUI.SAT_R
var hit_radius := MobileUI.SAT_HIT_R
var fill: Color = UIStyle.CREAM
var edge: Color = UIStyle.CREAM_EDGE
var text_color: Color = UIStyle.TEXT_BROWN
## Font size for `label`. Set by the owner; the primary button uses a bigger one.
var font_size := 20
## A dimmed button still draws and still accepts touches; it just reads as "nothing to do here"
## (the context button with no interact target).
var dimmed := false: set = set_dimmed
## HUD chrome (bag / journal / pause) rather than a thumb control: it keeps a higher resting
## opacity, because R2.10's see-through rule is about the stick and the action cluster and a small
## icon the player has to find still has to be findable. See MobileUI.ALPHA_CHROME.
var chrome := false

var down := false
## Centre in the parent's coordinates; the control sizes itself around it.
var centre := Vector2.ZERO: set = set_centre

var _font: Font


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = UIStyle.font()
	modulate.a = MobileUI.ALPHA_IDLE
	_resize()


func set_centre(v: Vector2) -> void:
	centre = v
	_resize()


func set_dimmed(v: bool) -> void:
	if dimmed == v:
		return
	dimmed = v
	queue_redraw()


func _resize() -> void:
	var r := maxf(radius, hit_radius)
	position = centre - Vector2(r, r)
	size = Vector2(r, r) * 2.0
	pivot_offset = size * 0.5
	queue_redraw()


## True when `p` (in the PARENT's coordinates) is inside the circular hit area.
func contains(p: Vector2) -> bool:
	return visible and p.distance_to(centre) <= hit_radius


func press() -> void:
	if down:
		return
	down = true
	for a in actions:
		if InputMap.has_action(a):
			Input.action_press(a)
	if actions.is_empty():
		tapped.emit()
	# A little squash so a touch is unmistakable even at 0.88 alpha over a busy planet.
	var t := create_tween()
	t.tween_property(self, "scale", Vector2(1.08, 1.08), 0.08).set_trans(Tween.TRANS_BACK)
	queue_redraw()


func release() -> void:
	if not down:
		return
	down = false
	release_actions()
	var t := create_tween()
	t.tween_property(self, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_SINE)
	queue_redraw()


## Drops the held actions without touching the visual state (used when a modal opens mid-hold).
func release_actions() -> void:
	for a in actions:
		if InputMap.has_action(a):
			Input.action_release(a)


func _draw() -> void:
	var c := size * 0.5
	var f: Color = fill if not dimmed else fill.lerp(UIStyle.CREAM_INSET, 0.55)
	# Shapes are drawn FULLY OPAQUE; `modulate.a` carries the whole transparency, so the R2.10
	# numbers (0.45 idle / 0.88 touched) are exactly what a screenshot measures.
	var a: float = 1.0 if not dimmed else 0.7
	if down:
		f = f.lightened(0.10)
	MobileUI.draw_disc(self, c, radius, f, edge, 5.0, a)
	var ink := Color(text_color, (1.0 if not dimmed else 0.7))
	match glyph:
		Glyph.JUMP:
			MobileUI.draw_chevron(self, c + Vector2(0.0, -radius * 0.10), radius * 0.42, ink)
			draw_arc(c + Vector2(0.0, radius * 0.36), radius * 0.30, deg_to_rad(200.0),
				deg_to_rad(340.0), 20, Color(ink, 0.55), 3.0, true)
		Glyph.BOOST:
			_draw_flame(c, radius * 0.62, ink)
		Glyph.BAG:
			_draw_bag(c, radius * 0.60, ink)
		Glyph.JOURNAL:
			_draw_book(c, radius * 0.58, ink)
		Glyph.PAUSE:
			var w := radius * 0.16
			var h := radius * 0.52
			draw_rect(Rect2(c + Vector2(-w * 2.1, -h * 0.5), Vector2(w, h)), ink)
			draw_rect(Rect2(c + Vector2(w * 1.1, -h * 0.5), Vector2(w, h)), ink)
		Glyph.ROTATE_L:
			_draw_rotate(c, radius * 0.52, ink, true)
		Glyph.ROTATE_R:
			_draw_rotate(c, radius * 0.52, ink, false)
		Glyph.CLOSE:
			var d := radius * 0.38
			draw_line(c - Vector2(d, d), c + Vector2(d, d), ink, 5.0, true)
			draw_line(c + Vector2(d, -d), c + Vector2(-d, d), ink, 5.0, true)
		_:
			pass
	if label != "" and _font != null:
		# Shrink to fit rather than overflow: the context button's label is whatever the interact
		# prompt says, and "Pick up" is a lot wider than "Fly".
		var fs := font_size
		var budget := radius * 1.62
		var w := _font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1.0, fs)
		while w.x > budget and fs > 11:
			fs -= 2
			w = _font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1.0, fs)
		var base := c + Vector2(-w.x * 0.5, w.y * 0.32)
		if glyph != Glyph.NONE:
			base.y = c.y + radius * 0.88
		# A white halo keeps the label readable at 0.45 alpha over any planet.
		draw_string_outline(_font, base, label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs, 5,
			Color(UIStyle.WHITE, 0.8 * a))
		draw_string(_font, base, label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs, ink)


func _draw_flame(c: Vector2, r: float, ink: Color) -> void:
	# A painted cartoon puff-and-flame, matching the jetpack's language rather than a rocket icon.
	var pts := PackedVector2Array([
		Vector2(0.0, -r), Vector2(r * 0.62, -r * 0.05), Vector2(r * 0.30, r * 0.75),
		Vector2(0.0, r * 0.30), Vector2(-r * 0.30, r * 0.75), Vector2(-r * 0.62, -r * 0.05)])
	var out := PackedVector2Array()
	for p in pts:
		out.append(c + p)
	draw_colored_polygon(out, Color(UIStyle.ORANGE, 0.85))
	var closed := out.duplicate()
	closed.append(out[0])
	draw_polyline(closed, ink, 3.0, true)


func _draw_bag(c: Vector2, r: float, ink: Color) -> void:
	var body := Rect2(c + Vector2(-r, -r * 0.42), Vector2(r * 2.0, r * 1.5))
	draw_rect(body, Color(UIStyle.YELLOW, 0.8))
	draw_rect(body, ink, false, 3.0)
	draw_arc(c + Vector2(0.0, -r * 0.42), r * 0.55, PI, TAU, 18, ink, 3.0, true)


func _draw_book(c: Vector2, r: float, ink: Color) -> void:
	var body := Rect2(c + Vector2(-r * 0.85, -r), Vector2(r * 1.7, r * 2.0))
	draw_rect(body, Color(UIStyle.WHITE, 0.85))
	draw_rect(body, ink, false, 3.0)
	for i in 3:
		var y := c.y - r * 0.45 + float(i) * r * 0.5
		draw_line(Vector2(c.x - r * 0.5, y), Vector2(c.x + r * 0.55, y), Color(ink, 0.7), 2.5, true)


func _draw_rotate(c: Vector2, r: float, ink: Color, ccw: bool) -> void:
	var from := deg_to_rad(210.0)
	var to := deg_to_rad(480.0)
	draw_arc(c, r, from, to, 26, ink, 4.0, true)
	var tip_a: float = from if ccw else to
	var tip := c + Vector2.RIGHT.rotated(tip_a) * r
	MobileUI.draw_chevron(self, tip, r * 0.36, ink, tip_a + (PI if ccw else 0.0))
