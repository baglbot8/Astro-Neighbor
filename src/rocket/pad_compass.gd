class_name PadCompass
extends CanvasLayer
## "Your rocket is that way" pip — the off-screen half of the pad's discoverability kit.
##
## The rocket pad sits ~9-16 m from the spawn point on a 13-26 m planet, which is over the horizon
## and (because the spawn facing is not aimed at it) usually behind the player. Nothing on screen
## used to say the rocket existed, on any planet. This draws a cream AC-style pip clamped to the
## screen edge, pointing at the pad, with the distance in metres — and gets out of the way the
## moment the pad is actually visible on screen or the player has walked up to it.
##
## Owned by rocket_pad.tscn (a CanvasLayer child of the pad), so it dies with the pad and needs
## nothing from the UI builder.

## Screen inset the pip is clamped inside.
const MARGIN := Vector2(96.0, 150.0)
## Below this distance the player has clearly found the pad and the pip retires for the session.
const ARRIVED_M := 7.0
## The pip fades out while the pad is comfortably inside the frame.
const ON_SCREEN_INSET := Vector2(120.0, 110.0)
const PILL_H := 44.0
const ARROW := 15.0
const FADE := 0.25

var target: Vector3 = Vector3.ZERO
var label_text: String = "Rocket"

var _root: Control
var _shown := true
var _alpha := 0.0
var _dist := 0.0
var _angle := 0.0
var _pos := Vector2.ZERO
var _want := false
var _font: Font
var _pill: StyleBoxFlat
var _pulse := 0.0


func _ready() -> void:
	layer = 4
	_font = UIStyle.font()
	_root = Control.new()
	_root.name = "Pip"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.draw.connect(_draw_pip)
	add_child(_root)


## Turns the pip off for good (the player reached the pad, or a cutscene took over).
func retire() -> void:
	_shown = false


func _process(delta: float) -> void:
	_pulse += delta
	_want = _shown and not EventBus.is_modal_open() and _evaluate()
	var goal := 1.0 if _want else 0.0
	_alpha = move_toward(_alpha, goal, delta / FADE)
	_root.visible = _alpha > 0.003
	if _root.visible:
		_root.queue_redraw()


## Works out where the pip should sit this frame. Returns false when it should be hidden.
func _evaluate() -> bool:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return false
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null or not is_instance_valid(player):
		return false
	_dist = player.global_position.distance_to(target)
	if _dist < ARRIVED_M:
		_shown = false
		return false
	var size := Vector2(get_viewport().get_visible_rect().size)
	var centre := size * 0.5
	var behind := cam.is_position_behind(target)
	var sp := cam.unproject_position(target)
	if behind:
		# unproject_position mirrors points behind the camera; flip it back around the centre so the
		# pip still points the right way instead of the exact opposite way.
		sp = centre - (sp - centre)
	var inside := not behind \
		and sp.x > ON_SCREEN_INSET.x and sp.x < size.x - ON_SCREEN_INSET.x \
		and sp.y > ON_SCREEN_INSET.y and sp.y < size.y - ON_SCREEN_INSET.y
	if inside:
		return false
	var dir := sp - centre
	if dir.length_squared() < 1.0:
		dir = Vector2.DOWN
	dir = dir.normalized()
	# Clamp onto the inset rectangle edge.
	var half := centre - MARGIN
	var scale_x := half.x / maxf(absf(dir.x), 0.0001)
	var scale_y := half.y / maxf(absf(dir.y), 0.0001)
	_pos = centre + dir * minf(scale_x, scale_y)
	_angle = dir.angle()
	return true


func _draw_pip() -> void:
	var text := "%s  %d m" % [label_text, roundi(_dist)]
	var text_size := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, UIStyle.SIZE_SMALL)
	var pill_w := text_size.x + 74.0
	var bob := 1.0 + 0.05 * sin(_pulse * 4.2)
	var a := _alpha
	var rect := Rect2(_pos - Vector2(pill_w, PILL_H) * 0.5 * bob, Vector2(pill_w, PILL_H) * bob)
	# Keep the whole pill (and the room its arrow needs) inside the frame: clamping only the centre
	# to the inset rect let half the pill hang off the screen edge on the wide planets.
	var screen := Vector2(_root.size)
	var pad := Vector2(ARROW + 12.0, 10.0)
	rect.position.x = clampf(rect.position.x, pad.x, maxf(screen.x - rect.size.x - pad.x, pad.x))
	rect.position.y = clampf(rect.position.y, pad.y, maxf(screen.y - rect.size.y - pad.y, pad.y))
	_pos = rect.position + rect.size * 0.5
	# Rounded cream pill with a warm border and soft shadow — the shared HUD pill look.
	if _pill == null:
		_pill = UIStyle.make_pill_style()
	_pill.bg_color = Color(UIStyle.CREAM, a)
	_pill.border_color = Color(UIStyle.CREAM_EDGE, a)
	_pill.shadow_color = Color(UIStyle.SHADOW_COLOR, UIStyle.SHADOW_COLOR.a * a)
	_root.draw_style_box(_pill, rect)
	# Direction arrow on the outward side of the pill.
	var tip := _pos + Vector2.from_angle(_angle) * (pill_w * 0.5 * bob + ARROW + 5.0)
	var base := _pos + Vector2.from_angle(_angle) * (pill_w * 0.5 * bob + 3.0)
	var perp := Vector2.from_angle(_angle + PI * 0.5) * ARROW
	_root.draw_colored_polygon(PackedVector2Array([tip, base + perp, base - perp]), Color(UIStyle.ORANGE, a))
	# Little rocket glyph: a cream capsule with an orange nose, drawn at the left of the pill.
	var g := rect.position + Vector2(26.0, rect.size.y * 0.5)
	_root.draw_circle(g + Vector2(0.0, 4.0), 8.0, Color(UIStyle.NAME_BLUE, a * 0.85))
	_root.draw_colored_polygon(PackedVector2Array([
		g + Vector2(0.0, -13.0), g + Vector2(8.0, 2.0), g + Vector2(-8.0, 2.0)]), Color(UIStyle.ORANGE, a))
	_root.draw_string(_font, rect.position + Vector2(48.0, rect.size.y * 0.5 + 6.0), text,
		HORIZONTAL_ALIGNMENT_LEFT, -1.0, UIStyle.SIZE_SMALL, Color(UIStyle.TEXT_BROWN, a))
