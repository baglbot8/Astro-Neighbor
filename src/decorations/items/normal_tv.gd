extends DecoItem
## Television Show Box (Norm's Totally Normal Collection, docs/DAILY_STAMPS_SPEC.md 3) — a chunky
## old wood-case TV on a little table. It gets no channels out here, so Norm taped a crayon drawing
## of a TV show over the screen. The person in it has four arms.

const Letters := preload("res://src/decorations/items/normal_letters.gd")

const CASE := Color("#b08d79")
const CASE_DARK := Color("#967766")
const BEZEL := Color("#3a3f52")
const CREAM := Color("#e0d4b4")
const TABLE := Color("#cdbb9d")
const METAL := Color("#8fa3bf")
const SCREEN := Color("#6aa9bd")
const PAPER := Color("#e6dcc0")
const TAPE := Color("#cfc48f")
const INK := Color("#4a4655")
const SUN := Color("#d8ac77")
const GRASS := Color("#8baa83")
## Screen centre on the case front (the control strip sits beside it).
const SCREEN_AT := Vector3(-0.14, 1.0, 0.0)
const PAPER_TILT_DEG := 4.0


func _init() -> void:
	footprint = 0.7
	collide_radius = 0.5
	collide_height = 1.4


func _build() -> void:
	var kit := DecoKit.new()
	# --- little table -------------------------------------------------------------------------
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			kit.tube(Vector3(0.44 * sx, 0.0, 0.22 * sz), Vector3(0.38 * sx, 0.52, 0.18 * sz), 0.04, TABLE, 8)
	kit.rbox(Vector3(0.0, 0.54, 0.0), Vector3(1.1, 0.09, 0.6), 0.04, TABLE)
	# --- case ---------------------------------------------------------------------------------
	kit.rbox(Vector3(0.0, 1.0, 0.02), Vector3(1.14, 0.84, 0.6), 0.13, CASE)
	kit.rbox(Vector3(0.0, 0.61, 0.02), Vector3(1.0, 0.06, 0.5), 0.03, CASE_DARK, Basis.IDENTITY, 0)
	kit.rbox(SCREEN_AT + Vector3(0.0, 0.0, -0.275), Vector3(0.74, 0.66, 0.08), 0.07, BEZEL)
	# control strip: two dials and a speaker grille
	var out := DecoKit.axis_basis(Vector3(0.0, 0.0, -1.0))
	for y in [1.22, 1.04]:
		kit.cone(Vector3(0.4, y, -0.27), 0.065, 0.055, 0.06, CREAM, out, 12)
		kit.rbox(Vector3(0.4, y + 0.02, -0.335), Vector3(0.02, 0.07, 0.02), 0.008, BEZEL, Basis.IDENTITY, 0)
	for i in 4:
		kit.rbox(Vector3(0.4, 0.88 - float(i) * 0.05, -0.285), Vector3(0.15, 0.022, 0.02), 0.01, CASE_DARK, Basis.IDENTITY, 0)
	# rabbit ears
	kit.dome(Vector3(0.0, 1.41, 0.02), 0.1, CASE_DARK, 0.7, Basis.IDENTITY, 12)
	for s in [-1.0, 1.0]:
		kit.tube(Vector3(0.03 * s, 1.45, 0.02), Vector3(0.38 * s, 1.96, 0.02), 0.018, METAL, 6)
		kit.sphere(Vector3(0.39 * s, 1.98, 0.02), 0.05, CREAM, Vector3.ONE, 8)
	# --- the taped-on drawing -----------------------------------------------------------------
	var tilt := Basis(Vector3(0.0, 0.0, 1.0), deg_to_rad(PAPER_TILT_DEG))
	var paper_at := SCREEN_AT + Vector3(0.0, 0.0, -0.345)
	kit.extrude(DecoKit.round_rect_poly(0.56, 0.46, 0.02, 2), 0.012, PAPER, Transform3D(tilt, paper_at))
	var page := Transform3D(tilt * Letters.FRONT, paper_at + Vector3(0.0, 0.0, -0.01))
	_draw_show(kit, page)
	for s in [-1.0, 1.0]:
		var corner := page * Vector3(0.25 * s, 0.2, 0.004)
		kit.rbox(corner, Vector3(0.13, 0.05, 0.008), 0.004, TAPE, tilt * Basis(Vector3(0.0, 0.0, 1.0), deg_to_rad(40.0 * s)), 0)
	add_body(kit.commit())

	# The tube behind the paper is still on: a soft blue edge around the drawing, and a power light.
	var glow := DecoKit.new()
	glow.extrude(DecoKit.round_rect_poly(0.64, 0.56, 0.1, 4), 0.03, SCREEN, Transform3D(Basis.IDENTITY, SCREEN_AT + Vector3(0.0, 0.0, -0.315)))
	glow.sphere(Vector3(0.4, 0.69, -0.3), 0.028, Color("#d96143"), Vector3.ONE, 8)
	add_glow(glow.commit(), 1.5, "Screen", 1.3, 0.12)
	# NO lamp light, on purpose. An add_light() 0.25 m in front of the paper turned the whole page
	# black at 22:30 on Compatibility (o3stampitems_out/tv_ab.png, same frame with and without):
	# toon_soft's light() extrapolates its ramp by the omni ATTENUATION, which passes 1 inside about
	# a metre and goes negative inside about 0.6 m. The glowing screen edge carries the night look.


## The show: a four-armed stick person waving under a sun. Page space: x right, y up, metres.
func _draw_show(kit: DecoKit, page: Transform3D) -> void:
	var w := 0.022
	_ring(kit, page, Vector2(-0.06, 0.085), 0.05, w, INK)
	_stroke(kit, page, Vector2(-0.06, 0.035), Vector2(-0.06, -0.07), w, INK)
	_stroke(kit, page, Vector2(-0.15, 0.03), Vector2(-0.06, -0.01), w, INK)
	_stroke(kit, page, Vector2(0.03, 0.03), Vector2(-0.06, -0.01), w, INK)
	_stroke(kit, page, Vector2(-0.15, -0.055), Vector2(0.03, -0.055), w, INK)
	_stroke(kit, page, Vector2(-0.06, -0.07), Vector2(-0.12, -0.15), w, INK)
	_stroke(kit, page, Vector2(-0.06, -0.07), Vector2(0.0, -0.15), w, INK)
	_stroke(kit, page, Vector2(-0.24, -0.16), Vector2(0.24, -0.16), w, GRASS)
	var sun := Vector2(0.16, 0.11)
	_ring(kit, page, sun, 0.04, w, SUN)
	for i in 5:
		var a := -0.5 + float(i) * 0.9
		var d := Vector2(cos(a), sin(a))
		_stroke(kit, page, sun + d * 0.065, sun + d * 0.1, w * 0.8, SUN)


## One crayon stroke: a flat quad from `a` to `b`, `w` wide.
func _stroke(kit: DecoKit, page: Transform3D, a: Vector2, b: Vector2, w: float, color: Color) -> void:
	var d := (b - a).normalized()
	var n := Vector2(-d.y, d.x) * w * 0.5
	var a0 := a - d * w * 0.3
	var b0 := b + d * w * 0.3
	var p0 := a0 - n
	var p1 := a0 + n
	var p2 := b0 + n
	var p3 := b0 - n
	kit.quad(page * Vector3(p0.x, p0.y, 0.0), page * Vector3(p1.x, p1.y, 0.0), page * Vector3(p2.x, p2.y, 0.0), page * Vector3(p3.x, p3.y, 0.0), color, true)


## A wobbly crayon circle.
func _ring(kit: DecoKit, page: Transform3D, c: Vector2, r: float, w: float, color: Color) -> void:
	var steps := 8
	for i in steps:
		var a0 := TAU * float(i) / float(steps)
		var a1 := TAU * float(i + 1) / float(steps)
		_stroke(kit, page, c + Vector2(cos(a0), sin(a0)) * r, c + Vector2(cos(a1), sin(a1)) * r, w, color)
