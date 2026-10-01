extends Control
## The stamp card's three little drawings (docs/DAILY_STAMPS_SPEC.md 2). One Control, three `kind`s,
## all drawn in code with the Moonstone UI colours (src/ui/theme/ui_style.gd) - no textures.
##
##   "stamp"  Norm's stamp: an orange ink ring with a tentacle curl in it ("my stamp ink is orange"),
##            pressed a little crooked. `on` false = the empty dashed circle waiting for one.
##   "tick"   a task's circle: empty ring, or green with a white tick when `on`.
##   "mark"   a small filled stamp for the HUD chip.

const INK := Color("#ef7f52")        # UIStyle.ORANGE
const INK_DEEP := Color("#c9613a")   # UIStyle.ORANGE_EDGE
const RING := Color("#9295ac")       # UIStyle.CREAM_EDGE
const GREEN := Color("#6fc47f")      # UIStyle.GREEN
const GREEN_EDGE := Color("#4fa663") # UIStyle.GREEN_EDGE
const AMBER := Color("#f0a64a")      # UIStyle.YELLOW
const WHITE := Color("#fbfcff")      # UIStyle.WHITE

var kind := "stamp"
var on := false
## "stamp" only: this is today's circle (an amber ring round it).
var today := false
## "stamp" only: how crooked the press is, radians.
var tilt := -0.22


static func make(p_kind: String, px: float, p_on: bool = false, p_today: bool = false, p_tilt: float = -0.22) -> Control:
	var a: Variant = (load("res://src/stamps/stamp_art.gd") as GDScript).new()
	a.kind = p_kind
	a.on = p_on
	a.today = p_today
	a.tilt = p_tilt
	a.custom_minimum_size = Vector2(px, px)
	a.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	a.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return a as Control


func _draw() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.5 - 2.0
	match kind:
		"tick":
			_draw_tick(c, r)
		"mark":
			draw_circle(c, r, INK)
			draw_arc(c, r, 0.0, TAU, 28, INK_DEEP, maxf(1.5, r * 0.14), true)
			_curl(c, r * 0.78, WHITE, tilt)
		_:
			_draw_stamp(c, r)


func _draw_stamp(c: Vector2, r: float) -> void:
	if today:
		draw_arc(c, r, 0.0, TAU, 40, AMBER, maxf(2.5, r * 0.13), true)
	if not on:
		# The empty place: a dashed ring.
		var rr := r - (r * 0.22 if today else 0.0)
		for i in 12:
			var a0 := TAU * float(i) / 12.0
			draw_arc(c, rr, a0, a0 + TAU / 24.0, 5, Color(RING, 0.75), maxf(1.5, r * 0.08), true)
		return
	var sr := r * (0.78 if today else 0.92)
	draw_arc(c, sr, 0.0, TAU, 40, INK, maxf(2.5, sr * 0.16), true)
	draw_arc(c, sr * 0.68, 0.0, TAU, 32, Color(INK, 0.45), maxf(1.0, sr * 0.05), true)
	_curl(c, sr, INK, tilt)


## Norm's tentacle doing the happy curl: a spiral, drawn as one thick line.
func _curl(c: Vector2, r: float, ink: Color, rot: float) -> void:
	var pts := PackedVector2Array()
	var turns := 1.35
	for i in 33:
		var t := float(i) / 32.0
		var ang := rot + t * TAU * turns
		var rad := r * (0.06 + 0.44 * t)
		pts.append(c + Vector2(cos(ang), sin(ang)) * rad)
	draw_polyline(pts, ink, maxf(2.0, r * 0.17), true)
	draw_circle(pts[pts.size() - 1], maxf(1.5, r * 0.12), ink)


func _draw_tick(c: Vector2, r: float) -> void:
	if not on:
		draw_arc(c, r, 0.0, TAU, 32, RING, maxf(2.0, r * 0.16), true)
		return
	draw_circle(c, r, GREEN)
	draw_arc(c, r, 0.0, TAU, 32, GREEN_EDGE, maxf(1.5, r * 0.12), true)
	var pts := PackedVector2Array([c + Vector2(-0.45, 0.02) * r, c + Vector2(-0.12, 0.36) * r, c + Vector2(0.48, -0.32) * r])
	draw_polyline(pts, WHITE, maxf(2.5, r * 0.22), true)
