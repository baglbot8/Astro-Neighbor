extends RefCounted
## VELA'S TITLE SHAPES (TitleLettering, THE PLANET INTERFACE; builder GV, 2026-10-20). A DRAFT in the lead's picked
## direction (Zorp's M1: an emblem behind two-line lettering in the planet's own palette).
##   `backdrop`  THE MIRROR-MOON CREST: a big still moon in frost blue, cut by a thin ice horizon, its reflection
##               below it darker and streaked (the Mirror Moon on the frozen lake), a small six-armed frost crystal
##               crowning it, and two of her listening masts standing either side with their amber lamps lit and
##               three quiet rings going out from each (she listens; the array "sings").
##   `glyph`     EVERY letter as frost silver with depth: a navy drop shadow, a deep navy-violet outline, a core lit
##               from above (near-white frost at the cap height to silver-violet at the baseline). (Round 2, the critic:
##               the amber lamps that sat on the L's "read like i-dots" - gone; the amber stays on the crest's masts.)
## SELF-CONTAINED on purpose: this file loads nothing but vela_meshes.gd, so a missing or renamed sibling title file
## can never break it (TitleLettering just draws the plain lettering when THIS file is missing).
## Baked once by TitleLettering behind the black; nothing here runs per frame. Colours are Vela's own (vela_meshes.gd:
## DOWN, ICE_TIP, SLATE, SLATE_DARK, AMBER - her one allowed accent); none over S 0.60.

const Meshes := preload("res://src/planet_safari/worlds/vela_meshes.gd")
const PX := TitleLettering.BUILD_CAP_PX

const NAVY := Color("#1d2444")         # outlines (S 0.56 V 0.27)
const NAVY_SOFT := Color("#0d1230")
const LETTER_TOP := Color("#eef2f8")   # frost lit from above (S 0.04 V 0.97)
const LETTER_BOT := Color("#a9b2d6")   # silver-violet at the foot (S 0.21 V 0.84)
const MOON_TOP := Color("#8fa4c2")     # S 0.26 V 0.76
const MOON_BOT := Color("#62789a")     # S 0.36 V 0.60
const REFL_TOP := Color("#465a7d")
const REFL_BOT := Color("#2f3d5c")
const ICE := Color("#c9d6e6")
const LAMP_GLOW := Color("#d8a25c")
const SHELF_TOP := Color("#dfe7f1")    # the ice bar's lit top edge
const SHELF_FACE := Color("#8ea3bf")   # its face (S 0.26 V 0.75)
const SHELF_UNDER := Color("#4d6082")  # its shadowed underside (S 0.41 V 0.51)

static var _grad_shader: Shader


static func backdrop(block_size: Vector2, _style: Dictionary) -> Node2D:
	var c := _Crest.new()
	c.bs = block_size
	c.set_meta("size", Vector2(block_size.x * 1.38, block_size.y * 2.0 * 1.18))
	return c


static func glyph(ch: String, _index: int, style: Dictionary) -> Node2D:
	TitleLettering._ensure_tables()
	var gl: Dictionary = TitleLettering._glyphs
	if not gl.has(ch):
		return null
	var g: Dictionary = gl[ch]
	var w := float(g["w"])
	var stroke := float(style.get("stroke", 0.16))
	var ow := float(style.get("outline", 0.05))
	var root := Node2D.new()
	var shadow := Node2D.new()
	var outline := Node2D.new()
	var core := Node2D.new()
	for n: Node2D in [shadow, outline, core]:
		root.add_child(n)
	var mat := gradient_material(LETTER_TOP, LETTER_BOT, -PX * 1.05, PX * 0.05)
	for s: PackedVector2Array in g["strokes"]:
		var pts := PackedVector2Array()
		for p in TitleMockups._dense(s):
			pts.append(Vector2(p.x - w * 0.5, -p.y) * PX)
		_line(shadow, TitleMockups._shift(pts, Vector2(PX * 0.03, PX * 0.06)), (stroke + ow * 2.0 + 0.02) * PX,
			Color(NAVY_SOFT, 0.55))
		_line(outline, pts, (stroke + ow * 2.0) * PX, NAVY)
		_line(core, pts, stroke * PX, Color.WHITE).material = mat
	root.set_meta("w", w)
	return root


## A canvas material painting its node from `top` (local y0) to `bottom` (local y1), keeping the vertex alpha (the
## line's antialiased edge). Local y, so it is the same whatever the bake's scale.
static func gradient_material(top: Color, bottom: Color, y0: float, y1: float) -> ShaderMaterial:
	if _grad_shader == null:
		_grad_shader = Shader.new()
		_grad_shader.code = """shader_type canvas_item;
uniform vec4 top_col : source_color;
uniform vec4 bot_col : source_color;
uniform float y0;
uniform float y1;
varying float vy;
void vertex() { vy = VERTEX.y; }
void fragment() {
	float t = clamp((vy - y0) / (y1 - y0), 0.0, 1.0);
	COLOR = vec4(mix(top_col.rgb, bot_col.rgb, t), COLOR.a);
}
"""
	var m := ShaderMaterial.new()
	m.shader = _grad_shader
	m.set_shader_parameter("top_col", top)
	m.set_shader_parameter("bot_col", bottom)
	m.set_shader_parameter("y0", y0)
	m.set_shader_parameter("y1", y1)
	return m


static func _line(parent: Node2D, pts: PackedVector2Array, width: float, col: Color) -> Line2D:
	var l := Line2D.new()
	l.points = pts
	l.width = width
	l.default_color = col
	l.joint_mode = Line2D.LINE_JOINT_ROUND
	l.begin_cap_mode = Line2D.LINE_CAP_ROUND
	l.end_cap_mode = Line2D.LINE_CAP_ROUND
	l.antialiased = true
	l.round_precision = 10
	parent.add_child(l)
	return l


## THE MIRROR-MOON CREST, drawn once in `_draw` (baked; never redrawn).
class _Crest extends Node2D:
	var bs := Vector2(800, 250)

	func _draw() -> void:
		var w := bs.x
		var h := bs.y
		var ol := maxf(3.0, h * 0.022)
		_fan(Vector2(0.0, -h * 0.1), Vector2(w * 0.66, h * 1.12), Color(Meshes.ICE_TIP, 0.30))
		# The listening rings first (under the masts), then the moon, its reflection, the ice horizon, the masts.
		var mast_x := w * 0.56
		var lamp_y := -h * 0.8
		for side in [-1.0, 1.0]:
			var lc := Vector2(side * mast_x, lamp_y)
			for k in 3:
				var rr := h * (0.14 + 0.09 * float(k))
				var a0: float = (-PI * 0.5 - 0.95) if side < 0.0 else (-PI * 0.5 + 0.95)
				var span := 0.9
				draw_arc(lc, rr, a0 - span * 0.5, a0 + span * 0.5, 16,
					Color(Meshes.AMBER, 0.55 - 0.14 * float(k)), maxf(2.0, h * 0.016), true)
		var mc := Vector2(0.0, -h * 0.12)
		var mr := h * 0.86
		var horizon := h * 0.3
		draw_circle(mc, mr + ol, NAVY, true, -1.0, true)
		_disc_half(mc, mr, horizon, true)
		_disc_half(mc, mr, horizon, false)
		# an antialiased rim over the fan's edge (the bake is half resolution: a bare polygon edge stair-steps)
		draw_arc(mc, mr, 0.0, TAU, 96, NAVY, maxf(2.0, ol * 0.8), true)
		# faint maria on the moon, mirrored (fainter) in the reflection
		for cr: Vector3 in [Vector3(-0.42, -0.45, 0.16), Vector3(0.3, -0.62, 0.11), Vector3(0.5, -0.2, 0.13),
				Vector3(-0.15, -0.15, 0.09)]:
			var p := mc + Vector2(cr.x, cr.y) * mr
			draw_circle(p, cr.z * mr, Color(MOON_BOT, 0.55), true, -1.0, true)
			var q := Vector2(p.x, 2.0 * (mc.y + horizon) - p.y)
			if (q - mc).length() < mr - cr.z * mr:
				draw_circle(q, cr.z * mr, Color(REFL_TOP.lightened(0.08), 0.5), true, -1.0, true)
		# ripple streaks across the reflection
		for k in 4:
			var y := mc.y + horizon + mr * (0.12 + 0.13 * float(k))
			var half := sqrt(maxf(mr * mr - (y - mc.y) * (y - mc.y), 0.0)) * (0.8 - 0.12 * float(k))
			draw_line(Vector2(-half, y), Vector2(half, y), Color(MOON_TOP, 0.35 - 0.06 * float(k)), maxf(2.0, h * 0.02), true)
		# the ice horizon: a DEEP bar right across (round 2, the critic: "deepen the crest bar") - a lit top edge, a
		# frost face, a shadowed underside, outlined in navy, so it reads as a slab of lake ice seen edge-on
		var hy := mc.y + horizon
		var bar_h := h * 0.12
		var shelf := Rect2(-w * 0.6, hy - bar_h * 0.4, w * 1.2, bar_h)
		draw_rect(shelf.grow(ol), NAVY)
		var y_face := shelf.position.y + bar_h * 0.22
		var y_under := shelf.position.y + bar_h * 0.62
		_band(shelf.position.x, shelf.end.x, shelf.position.y, y_face, SHELF_TOP, ICE)
		_band(shelf.position.x, shelf.end.x, y_face, y_under, ICE.lerp(SHELF_FACE, 0.5), SHELF_FACE)
		_band(shelf.position.x, shelf.end.x, y_under, shelf.end.y, SHELF_FACE.lerp(SHELF_UNDER, 0.6), SHELF_UNDER)
		draw_line(Vector2(shelf.position.x, y_face), Vector2(shelf.end.x, y_face), Color(NAVY, 0.35), maxf(1.5, ol * 0.4), true)
		# icicles hanging from its underside, short and still
		for k in 9:
			var x := lerpf(-w * 0.52, w * 0.52, float(k) / 8.0)
			if absf(x) < mr * 0.95 and absf(x) > mr * 0.2:
				continue
			var ln := h * (0.05 + 0.035 * float((k * 5) % 3) / 2.0)
			var tri := PackedVector2Array([Vector2(x - h * 0.02, shelf.end.y), Vector2(x + h * 0.02, shelf.end.y),
				Vector2(x, shelf.end.y + ln)])
			var ring := tri.duplicate()
			ring.append(tri[0])
			draw_polyline(ring, NAVY, ol * 1.2, true)
			draw_colored_polygon(tri, SHELF_FACE)
		# the masts
		for side in [-1.0, 1.0]:
			_mast(Vector2(side * mast_x, shelf.position.y), lamp_y, h, ol, side)
		# the frost crystal crowning the moon
		_crystal(mc + Vector2(0.0, -mr + h * 0.02), h * 0.17, ol)

	## A horizontal band from x0 to x1, y0 to y1, shaded `top` to `bottom`.
	func _band(x0: float, x1: float, y0: float, y1: float, top: Color, bottom: Color) -> void:
		draw_polygon(PackedVector2Array([Vector2(x0, y0), Vector2(x1, y0), Vector2(x1, y1), Vector2(x0, y1)]),
			PackedColorArray([top, top, bottom, bottom]))

	## The upper (moon) or lower (reflection) part of the disc, split at `horizon` below its centre, with a vertical
	## gradient (a fan of vertex colours).
	func _disc_half(c: Vector2, r: float, horizon: float, upper: bool) -> void:
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		var yh := c.y + horizon
		var ah := asin(clampf(horizon / r, -1.0, 1.0))   # angle (y down) where the horizon meets the rim
		var a0 := (PI - ah) if upper else ah
		var a1 := (TAU + ah) if upper else (PI - ah)
		var n := 48
		var top_y := c.y - r
		var bot_y := c.y + r
		for i in n + 1:
			var a := lerpf(a0, a1, float(i) / float(n))
			var p := c + Vector2(cos(a), sin(a)) * r
			pts.append(p)
			cols.append(_col_at(p.y, top_y, yh, bot_y, upper))
		var mid := Vector2(0.0, (top_y + yh) * 0.5) if upper else Vector2(0.0, (yh + bot_y) * 0.5)
		mid.x = c.x
		var idx := PackedInt32Array()
		pts.append(mid)
		cols.append(_col_at(mid.y, top_y, yh, bot_y, upper))
		var m := pts.size() - 1
		for i in n:
			idx.append_array([m, i, i + 1])
		idx.append_array([m, n, 0])
		RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), idx, pts, cols)

	func _col_at(y: float, top_y: float, yh: float, bot_y: float, upper: bool) -> Color:
		if upper:
			return MOON_TOP.lerp(MOON_BOT, clampf((y - top_y) / maxf(yh - top_y, 1.0), 0.0, 1.0))
		return REFL_TOP.lerp(REFL_BOT, clampf((y - yh) / maxf(bot_y - yh, 1.0), 0.0, 1.0))

	## One of her masts: a slim tapered pale-slate pole on the ice, two crossbars, the amber lamp on top with a glow.
	func _mast(foot: Vector2, top_y: float, h: float, ol: float, side: float) -> void:
		var hw := h * 0.045
		var body := PackedVector2Array([foot + Vector2(-hw, 0.0), foot + Vector2(hw, 0.0),
			Vector2(foot.x + hw * 0.6, top_y), Vector2(foot.x - hw * 0.6, top_y)])
		var ring := body.duplicate()
		ring.append(body[0])
		draw_polyline(ring, NAVY, ol * 2.0, true)
		draw_polygon(body, PackedColorArray([Meshes.SLATE_DARK, Meshes.SLATE_DARK, Meshes.SLATE, Meshes.SLATE]))
		for k in 2:
			var y := top_y + (foot.y - top_y) * (0.22 + 0.2 * float(k))
			var bw := h * (0.17 - 0.04 * float(k))
			var bar := Rect2(foot.x - bw, y - h * 0.018, bw * 2.0, h * 0.036)
			draw_rect(bar.grow(ol * 0.7), NAVY)
			draw_rect(bar, Meshes.SLATE.lightened(0.15))
		var lc := Vector2(foot.x, top_y)
		var lr := h * 0.055
		_fan(lc, Vector2(lr, lr) * 3.2, Color(LAMP_GLOW, 0.5))
		draw_circle(lc, lr + ol, NAVY, true, -1.0, true)
		draw_circle(lc, lr, Meshes.AMBER, true, -1.0, true)
		draw_circle(lc + Vector2(-lr * 0.3, -lr * 0.3), lr * 0.35, Color("#f2dcb0"), true, -1.0, true)

	## A six-armed frost crystal: navy outline pass, then the ice fill, each arm with two pairs of side branches.
	func _crystal(c: Vector2, r: float, ol: float) -> void:
		for pass_i in 2:
			var col := NAVY if pass_i == 0 else ICE
			var grow := ol * 1.6 if pass_i == 0 else 0.0
			for k in 6:
				var d := Vector2.UP.rotated(TAU * float(k) / 6.0)
				var n := Vector2(-d.y, d.x)
				draw_line(c, c + d * r, col, r * 0.16 + grow, true)
				for b in 2:
					var at := c + d * r * (0.45 + 0.25 * float(b))
					var bl := r * (0.34 - 0.12 * float(b))
					for sgn in [-1.0, 1.0]:
						draw_line(at, at + (d + n * sgn).normalized() * bl, col, r * 0.1 + grow, true)
			draw_circle(c, r * 0.2 + grow * 0.5, col, true, -1.0, true)

	func _fan(c: Vector2, half: Vector2, col: Color) -> void:
		var pts := PackedVector2Array([c])
		var cols := PackedColorArray([col])
		for i in 49:
			var a := TAU * float(i) / 48.0
			pts.append(c + Vector2(cos(a) * half.x, sin(a) * half.y))
			cols.append(Color(col, 0.0))
		var idx := PackedInt32Array()
		for i in 48:
			idx.append_array([0, i + 1, i + 2])
		RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), idx, pts, cols)
