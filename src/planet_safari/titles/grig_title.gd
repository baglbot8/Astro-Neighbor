extends RefCounted
## GRIG'S TITLE SHAPES (TitleLettering, THE PLANET INTERFACE; builder GV, 2026-10-20). A DRAFT in the lead's picked
## direction (Zorp's M1: an emblem behind two-line lettering in the planet's own palette).
##   `backdrop`  THE HENGE CREST: a stepped mound of four chalk-white terraces, each tread capped with a strip of
##               sage grass, two henge stones standing at its ends like gate posts, Grig's big chalk moon rising behind
##               its top with the edge-on ring across it, and his tally marks (a five-bar gate each side of the second
##               line) cut bold and deep into the bottom riser. (Round 2, the critic: the buff tiers "read as dull
##               stone" and the thin tally marks as scratches.)
##   `glyph`     EVERY letter, so the name reads as cut chalk with depth: a soft umber drop shadow, a dark umber
##               outline, and a core lit from above (chalk cream at the cap height down to ochre at the baseline,
##               a vertical gradient in a tiny canvas shader).
## Everything is drawn once and baked by TitleLettering behind the black; nothing here runs per frame. Colours are
## Grig's own (grig_meshes.gd: CHALK, BUFF, BUFF_DARK, ACCENT's ochre family); none over S 0.60.

const Meshes := preload("res://src/planet_safari/worlds/grig_meshes.gd")
const PX := TitleLettering.BUILD_CAP_PX

const UMBER := Color("#3a2d22")        # outlines (S 0.41 V 0.23)
const UMBER_SOFT := Color("#2a1f17")
const LETTER_TOP := Color("#f2e8cf")   # chalk lit from above (S 0.14 V 0.95)
const LETTER_BOT := Color("#cfa25e")   # ochre at the foot (S 0.55 V 0.81)
const CHALK_TOP := Color("#efe9dc")   # a chalk riser lit from above (S 0.08 V 0.94)
const CHALK_FOOT := Color("#cfc5ae")  # its foot (S 0.16 V 0.81)
const CHALK_SHADE := Color("#a99c80") # the shade under a tread's lip
const CHALK_LIP := Color("#fbf7ee")   # the lit lip of a tally cut
const GRASS := Color("#8c9c70")       # SAGE, grig_meshes.gd (S 0.28 V 0.61)
const GRASS_DARK := Color("#6c7a52")
const GRASS_LIT := Color("#b2c08f")
const MOON := Color("#d9cfb8")
const MOON_SHADE := Color("#b3a68a")
const RING := Color("#c8bc9f")

static var _grad_shader: Shader


## The crest behind the letters, centred on the block's centre (layout pixels, y down).
static func backdrop(block_size: Vector2, _style: Dictionary) -> Node2D:
	var c := _Crest.new()
	c.bs = block_size
	var w := block_size.x
	var h := block_size.y
	# Its extent round the centre: the widest tier plus the stones' outline, the moon's top to the bottom tier.
	c.set_meta("size", Vector2(w * 1.2, h * 2.0 * 1.15))
	return c


## Every letter as cut chalk (see the header). Drawn at the letter's baseline centre, cap height PX going up.
static func glyph(ch: String, _index: int, style: Dictionary) -> Node2D:
	TitleLettering._ensure_tables()
	var gl: Dictionary = TitleLettering._glyphs
	if not gl.has(ch):
		return null
	var g: Dictionary = gl[ch]
	var w := float(g["w"])
	var stroke := float(style.get("stroke", 0.17))
	var ow := float(style.get("outline", 0.05))
	var root := Node2D.new()
	var shadow := Node2D.new()
	var outline := Node2D.new()
	var core := Node2D.new()
	root.add_child(shadow)
	root.add_child(outline)
	root.add_child(core)
	var mat := gradient_material(LETTER_TOP, LETTER_BOT, -PX * 1.05, PX * 0.05)
	for s: PackedVector2Array in g["strokes"]:
		var pts := PackedVector2Array()
		for p in TitleMockups._dense(s):
			pts.append(Vector2(p.x - w * 0.5, -p.y) * PX)
		_line(shadow, TitleMockups._shift(pts, Vector2(PX * 0.03, PX * 0.06)), (stroke + ow * 2.0 + 0.02) * PX,
			Color(UMBER_SOFT, 0.55))
		_line(outline, pts, (stroke + ow * 2.0) * PX, UMBER)
		var l := _line(core, pts, stroke * PX, Color.WHITE)
		l.material = mat
	root.set_meta("w", w)
	return root


## A canvas material that paints its node from `top` (at local y0) to `bottom` (at local y1), keeping the vertex
## alpha (the line's antialiased edge). Local y, so it is the same in the bake whatever the bake's scale.
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


## THE HENGE CREST, drawn once in `_draw` (baked; never redrawn).
class _Crest extends Node2D:
	var bs := Vector2(800, 250)

	func _draw() -> void:
		var w := bs.x
		var h := bs.y
		var ol := maxf(3.0, h * 0.022)    # outline width
		# A soft warm glow under everything (three shrinking ellipses), so the crest sits in light, not on a sticker.
		_glow(Vector2(0.0, -h * 0.1), Vector2(w * 0.58, h * 1.12), Color(Meshes.BUFF, 0.28))
		# THE MOON rising behind the top tier, with the edge-on ring across it (back half first).
		var mc := Vector2(0.0, -h * 0.8)
		var mr := h * 0.3
		_ring_half(mc, Vector2(mr * 2.15, mr * 0.34), -0.14, true, ol)
		draw_circle(mc, mr + ol, UMBER, true, -1.0, true)
		_disc_shaded(mc, mr)
		# an antialiased rim over the fan's edge (the bake is at a reduced resolution: a bare polygon edge stair-steps)
		draw_arc(mc, mr, 0.0, TAU, 96, UMBER, maxf(2.0, ol * 0.8), true)
		# craters
		for cr: Vector3 in [Vector3(-0.35, -0.3, 0.16), Vector3(0.28, -0.45, 0.1), Vector3(0.42, 0.05, 0.13),
				Vector3(-0.1, 0.25, 0.09)]:
			draw_circle(mc + Vector2(cr.x, cr.y) * mr, cr.z * mr, Color(MOON_SHADE, 0.75), true, -1.0, true)
			draw_arc(mc + Vector2(cr.x, cr.y) * mr, cr.z * mr, PI * 1.1, PI * 1.9, 10, Color(UMBER, 0.35),
				maxf(1.5, ol * 0.4), true)
		_ring_half(mc, Vector2(mr * 2.15, mr * 0.34), -0.14, false, ol)
		# THE STEPS: four chalk-white tiers from the foot up, each with a grass cap along its tread (the critic,
		# 2026-10-20: the shadowed-buff tiers "read as dull stone"). A shade at each riser's foot gives the depth.
		var foot := h * 0.78
		var tier_h := h * 0.36
		# Narrower than the letters' first line, so the crest reads as a stepped mound against the sky, not a sign.
		var widths := [0.88, 0.68, 0.50, 0.34]
		for i in widths.size():
			var hw: float = w * 0.5 * float(widths[i])
			var y1 := foot - tier_h * float(i)
			var y0 := y1 - tier_h
			var r := Rect2(-hw, y0, hw * 2.0, tier_h)
			draw_rect(r.grow(ol), UMBER)
			_vgrad_rect(r, CHALK_TOP, CHALK_FOOT)
			# the shadow the tier above (and its grass) throws on this riser's top
			_vgrad_rect(Rect2(-hw, y0, hw * 2.0, tier_h * 0.22), Color(CHALK_SHADE, 0.75), Color(CHALK_SHADE, 0.0))
			_grass(-hw, hw, y0, h, ol, i)
		# The tally marks Grig cuts (a five-bar gate each side of the second line): big, bold, cut deep into the chalk
		# (an umber groove with a lit lip on its right), so they read as counting, not as scratches.
		var ty0 := foot - tier_h * 0.80
		var ty1 := foot - tier_h * 0.14
		var tw := h * 0.045
		for side in [-1.0, 1.0]:
			var gx: float = side * w * 0.325
			for k in 4:
				var x := gx + (float(k) - 1.5) * h * 0.085
				_cut(Vector2(x, ty0), Vector2(x, ty1), tw)
			_cut(Vector2(gx - h * 0.2, ty1 - tier_h * 0.1), Vector2(gx + h * 0.2, ty0 + tier_h * 0.1), tw)
		# THE GATE STONES: two henge monoliths standing on the ground either side of the mound.
		for side in [-1.0, 1.0]:
			_monolith(Vector2(side * w * 0.5, foot), h * 0.16, h * 1.74, ol)

	## A grass cap along a tread from x0 to x1 at y: an umber-outlined sage strip with tufts standing up from it.
	func _grass(x0: float, x1: float, y: float, h: float, ol: float, seed_i: int) -> void:
		var band := h * 0.045
		var pts := PackedVector2Array([Vector2(x0, y + band * 0.5)])
		var n := int((x1 - x0) / (h * 0.055))
		for k in n + 1:
			var x := lerpf(x0, x1, float(k) / float(n))
			var tall := h * (0.035 + 0.03 * float((k * 7 + seed_i * 3) % 4) / 3.0)
			if k > 0:
				pts.append(Vector2(x - (x1 - x0) / float(n) * 0.5, y - band * 0.4))
			pts.append(Vector2(x, y - band * 0.4 - tall))
		pts.append(Vector2(x1, y + band * 0.5))
		var ring := pts.duplicate()
		ring.append(pts[0])
		draw_polyline(ring, UMBER, ol * 1.6, true)
		draw_colored_polygon(pts, GRASS)
		# a lighter top edge on each tuft, a darker underside band
		draw_rect(Rect2(x0, y + band * 0.1, x1 - x0, band * 0.4), GRASS_DARK)
		for k in n + 1:
			var x := lerpf(x0, x1, float(k) / float(n))
			var tall := h * (0.035 + 0.03 * float((k * 7 + seed_i * 3) % 4) / 3.0)
			draw_line(Vector2(x, y - band * 0.4 - tall), Vector2(x - h * 0.008, y - band * 0.1), GRASS_LIT,
				maxf(1.5, h * 0.008), true)

	## One tally stroke cut into the chalk: an umber groove, a lit lip along its right side.
	func _cut(a: Vector2, b: Vector2, wd: float) -> void:
		var n := (b - a).normalized().orthogonal()
		draw_line(a, b, UMBER, wd, true)
		draw_line(a + n * wd * 0.55, b + n * wd * 0.55, CHALK_LIP, wd * 0.28, true)

	## A tapered four-sided stone: a lit face and a shaded side, a pale cap, a dark collar band.
	func _monolith(base: Vector2, hw: float, tall: float, ol: float) -> void:
		var top := base.y - tall
		var body := PackedVector2Array([base + Vector2(-hw, 0.0), base + Vector2(hw, 0.0),
			Vector2(base.x + hw * 0.78, top), Vector2(base.x - hw * 0.78, top)])
		var ring := body.duplicate()
		ring.append(body[0])
		draw_polyline(ring, UMBER, ol * 2.0, true)
		draw_colored_polygon(body, UMBER)
		var cols := PackedColorArray([Meshes.CHALK_DARK, Meshes.CHALK_DARK, Meshes.CHALK, Meshes.CHALK])
		draw_polygon(body, cols)
		# the shaded side (its right third)
		var side := PackedVector2Array([base + Vector2(hw * 0.35, 0.0), base + Vector2(hw, 0.0),
			Vector2(base.x + hw * 0.78, top), Vector2(base.x + hw * 0.27, top)])
		draw_colored_polygon(side, Color(Meshes.SHADOW, 0.45))
		# the collar band and the cap
		draw_rect(Rect2(base.x - hw * 0.9, top + tall * 0.3, hw * 1.8, tall * 0.045), Color(UMBER, 0.55))
		var cap := Rect2(base.x - hw * 0.95, top - tall * 0.05, hw * 1.9, tall * 0.07)
		draw_rect(cap.grow(ol * 0.8), UMBER)
		draw_rect(cap, Color("#e4dccb"))

	func _vgrad_rect(r: Rect2, top: Color, bot: Color) -> void:
		draw_polygon(PackedVector2Array([r.position, r.position + Vector2(r.size.x, 0.0), r.end,
			r.position + Vector2(0.0, r.size.y)]), PackedColorArray([top, top, bot, bot]))

	## The moon: a lit disc, lighter toward the upper left (a fan of vertex colours).
	func _disc_shaded(c: Vector2, r: float) -> void:
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		var light := Vector2(-0.5, -0.6).normalized()
		pts.append(c + light * r * 0.3)
		cols.append(MOON.lightened(0.12))
		for i in 49:
			var a := TAU * float(i) / 48.0
			var d := Vector2(cos(a), sin(a))
			pts.append(c + d * r)
			cols.append(MOON.lerp(MOON_SHADE, clampf(0.5 - 0.5 * d.dot(light), 0.0, 1.0)))
		var idx := PackedInt32Array()
		for i in 48:
			idx.append_array([0, i + 1, i + 2])
		RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), idx, pts, cols)

	## Half of the edge-on ring (an ellipse band tilted by `tilt` radians): the back half (`back`) or the front.
	func _ring_half(c: Vector2, half: Vector2, tilt: float, back: bool, ol: float) -> void:
		var pts := PackedVector2Array()
		var a0 := PI if back else 0.0
		for i in 33:
			var a := a0 + PI * float(i) / 32.0
			pts.append(c + Vector2(cos(a) * half.x, sin(a) * half.y).rotated(tilt))
		draw_polyline(pts, UMBER, half.y * 0.42 + ol * 2.0, true)
		draw_polyline(pts, RING if not back else RING.darkened(0.18), half.y * 0.42, true)
		draw_polyline(pts, Color(Color("#ece3cf"), 0.7 if not back else 0.3), half.y * 0.1, true)

	## A soft glow: an ellipse fan, `col` at the middle fading to clear at the rim (vertex colours: no bands).
	func _glow(c: Vector2, half: Vector2, col: Color) -> void:
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
