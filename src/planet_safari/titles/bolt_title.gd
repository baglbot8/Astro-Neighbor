extends RefCounted
## BOLT'S TITLE SHAPES (TitleLettering, THE PLANET INTERFACE; builder BOLT-FEN intro, 2026-10-20). A DRAFT in the lead's
## picked direction (Zorp's mock-up M1: an emblem behind two-line lettering in the planet's own palette).
##
##   backdrop  THE CREST: a chunky steel-blue GEAR - Bolt's world as a machine part - with a brass hex hub, a ring of
##             rivets and a lit top edge, and Bolt's RING sweeping round it (the far half behind the gear, the near half
##             in front), over a soft warm glow.
##   glyph     EVERY LETTER: Bolt's tall stroke font (TitleLettering's own glyph table) drawn as cast brass plate -
##             a soft navy shadow (stamped, so no overlap fans), a dark steel extrude under a dark outline, a brass
##             core, a darker lower bevel and a pale-gold lit top edge, a rivet on each free stroke end. The O of
##             CHROME is a little brass COG (teeth round the ring), the way Zorp's T is a mushroom.
##
## Every colour is Bolt's own (bolt_meshes.gd STEEL / BRASS / TEAL / ORANGE, bolt.tres ring and ground), inside
## docs/STYLE_GUIDE.md: nothing over S 0.60, nothing whiter than V 0.92, no pure white. Called once at
## `TitleLettering.build`; everything here is baked into the atlas behind the black, never drawn live.

const M := preload("res://src/planet_safari/worlds/bolt_meshes.gd")
const PX := TitleLettering.BUILD_CAP_PX
## Keep in step with SAMPLE_STEP in title_lettering.gd (glyph units).
const STEP := 0.035

# The crest
const GEAR := Color("#6f84a0")          # steel blue (S 0.31 V 0.63), Bolt's ground a step deeper
const GEAR_LIT := Color("#9fb2c8")      # the gear's lit top (S 0.21 V 0.78)
const GEAR_DEEP := Color("#4b5a72")     # its lower face (S 0.34 V 0.45)
const GEAR_RIM := Color("#2a3142")      # the dark rim round everything (S 0.36 V 0.26)
const RING := Color("#e0b779")          # Bolt's ring, bolt.tres ring_color muted (S 0.46 V 0.88)
const RING_BACK := Color("#a48252")     # its far half, in the gear's shade (S 0.50 V 0.64)
const RING_LIT := Color("#ecd3a2")      # a highlight along the near half (S 0.31 V 0.93 -> kept thin)
const RIVET := Color("#c3ccd6")         # rivet heads (S 0.10 V 0.84)
const GLOW := Color("#dd8434")          # M.ORANGE: the warm glow behind the crest, used faint
const HALO := Color("#141a2c")          # the dark halo behind the crest (the UI navy family, S 0.55 V 0.17)

# The letters
const BRASS := Color("#d4ae6a")         # the core (S 0.50 V 0.83)
const BRASS_LOW := Color("#a78246")     # the lower bevel (S 0.58 V 0.65)
const BRASS_TOP := Color("#ead09a")     # the lit top edge (S 0.34 V 0.92)
const OUTLINE := Color("#232838")       # a dark steel outline (S 0.38 V 0.22)
const EXTRUDE := Color("#3a4152")       # the extrude under it (S 0.29 V 0.32)
const SHADOW := Color(0.06, 0.07, 0.12, 0.30)   # one stamp of the soft shadow (they stack to ~0.85)


## THE STYLE lives in the world script (worlds/bolt.gd `intro_title_style`), which names this file by PATH in
## "title_file" - never a preload, so a missing or broken title file only costs the shapes (TitleLettering falls back to
## plain lettering with one warning) and never the world script. Keys read here besides TitleLettering's own: "cog_at"
## (which letter is the cog O). "halo" is not drawn (every glyph is replaced): it reserves room in each atlas cell.

# ======================================================================================== THE CREST
static func backdrop(block_size: Vector2, _style: Dictionary) -> Node2D:
	var n := _Crest.new()
	n.bs = block_size
	var r := block_size.y * 0.98
	n.set_meta("size", Vector2(maxf(r * 4.4, block_size.x * 1.08), r * 2.0 * 1.26))
	return n


class _Crest extends Node2D:
	var bs := Vector2(800, 250)

	func _draw() -> void:
		var r := bs.y * 0.98                  # the gear's outer (tooth tip) radius
		var c := Vector2(0.0, bs.y * 0.02)
		var tilt := deg_to_rad(-11.0)
		var ring_a := Vector2(r * 1.9, r * 0.40)
		var ring_w := r * 0.17
		# 1. A soft DARK halo behind it all, so the busy yarn ring of the real sky does not compete with the crest (the
		# critic): fourteen nested navy ellipses, densest in the middle, then a faint warm core.
		for k in 14:
			var u := float(k) / 13.0
			_ellipse(c, Vector2(r * 2.2, r * 1.25) * (1.0 - 0.6 * u), Color(HALO, 0.095))
		for k in 4:
			_ellipse(c, Vector2(r * 1.2, r * 0.9) * (1.0 - 0.2 * float(k)), Color(GLOW, 0.03))
		# 2. The ring's FAR half (above the gear's centre on screen), in shade.
		_ring_band(c, ring_a, ring_w, tilt, PI, TAU, RING_BACK, GEAR_RIM)
		# 3. The gear: teeth + body in the rim colour, then the face (lit top, deep bottom), an inner groove.
		var outer := _gear_pts(c, r, r * 0.84, 12, 0.34)
		draw_colored_polygon(outer, GEAR_RIM)
		_aa_edge(outer, GEAR_RIM)
		var face := _gear_pts(c, r * 0.95, r * 0.80, 12, 0.30)
		var cols := PackedColorArray()
		for p in face:
			var u := clampf((p.y - (c.y - r)) / (2.0 * r), 0.0, 1.0)
			cols.append(GEAR_LIT.lerp(GEAR, smoothstep(0.0, 0.45, u)).lerp(GEAR_DEEP, smoothstep(0.5, 1.0, u)))
		draw_polygon(face, cols)
		var fl := face.duplicate()
		fl.append(face[0])
		var fc := cols.duplicate()
		fc.append(cols[0])
		draw_polyline_colors(fl, fc, 1.5, true)
		_circle_line(c, r * 0.62, GEAR_RIM, r * 0.035)
		# 4. Rivets on the face, between the groove and the teeth.
		for i in 12:
			var a := TAU * (float(i) + 0.5) / 12.0
			var p := c + Vector2(cos(a), sin(a)) * r * 0.71
			draw_circle(p, r * 0.045, GEAR_RIM, true, -1.0, true)
			draw_circle(p, r * 0.032, RIVET, true, -1.0, true)
			draw_circle(p + Vector2(-0.3, -0.35) * r * 0.03, r * 0.012, Color(RING_LIT, 0.9), true, -1.0, true)
		# 5. The brass hex hub (mostly behind the letters; it shows between the lines).
		var hexo := PackedVector2Array()
		var hexi := PackedVector2Array()
		for i in 6:
			var a := TAU * float(i) / 6.0 + PI / 6.0
			hexo.append(c + Vector2(cos(a), sin(a)) * r * 0.36)
			hexi.append(c + Vector2(cos(a), sin(a)) * r * 0.31)
		draw_colored_polygon(hexo, GEAR_RIM)
		_aa_edge(hexo, GEAR_RIM)
		draw_colored_polygon(hexi, BRASS_LOW)
		_aa_edge(hexi, BRASS_LOW)
		draw_circle(c, r * 0.14, GEAR_RIM, true, -1.0, true)
		# 6. The ring's NEAR half, in front of the gear, with a thin lit edge.
		_ring_band(c, ring_a, ring_w, tilt, 0.0, PI, RING, GEAR_RIM)
		_ring_edge(c, ring_a, tilt, 0.12 * PI, 0.88 * PI, RING_LIT, ring_w * 0.22)

	## Gear outline: `n` teeth, tip radius `ro`, root radius `ri`, `tw` = share of each pitch the tooth's top takes.
	func _gear_pts(c: Vector2, ro: float, ri: float, n: int, tw: float) -> PackedVector2Array:
		var pts := PackedVector2Array()
		for i in n:
			var a0 := TAU * float(i) / float(n)
			var pitch := TAU / float(n)
			# root, flank up, top, flank down (a trapezoid tooth with a slightly rounded top)
			var marks := [[0.0, ri], [0.5 - tw * 0.5 - 0.08, ri], [0.5 - tw * 0.5, ro], [0.5, ro * 1.01],
				[0.5 + tw * 0.5, ro], [0.5 + tw * 0.5 + 0.08, ri]]
			for m: Array in marks:
				var a := a0 + pitch * float(m[0])
				pts.append(c + Vector2(cos(a), sin(a)) * float(m[1]))
		return pts

	## A band of the tilted ellipse between angles a0..a1 (0 = right, PI/2 = down on screen), outlined in `rim`.
	func _ring_band(c: Vector2, ax: Vector2, w: float, tilt: float, a0: float, a1: float, col: Color, rim: Color) -> void:
		var steps := 40
		var outer := PackedVector2Array()
		var inner := PackedVector2Array()
		for i in steps + 1:
			var a := lerpf(a0, a1, float(i) / float(steps))
			outer.append(c + Vector2(cos(a) * (ax.x + w * 0.5), sin(a) * (ax.y + w * 0.22)).rotated(tilt))
			inner.append(c + Vector2(cos(a) * (ax.x - w * 0.5), sin(a) * (ax.y - w * 0.22)).rotated(tilt))
		var band := outer.duplicate()
		for i in range(inner.size() - 1, -1, -1):
			band.append(inner[i])
		var grow := PackedVector2Array()
		for p in band:
			grow.append(c + (p - c) * 1.0)
		# the rim: the same band drawn a little fatter first
		var fat_o := PackedVector2Array()
		var fat_i := PackedVector2Array()
		for i in steps + 1:
			var a := lerpf(a0, a1, float(i) / float(steps))
			fat_o.append(c + Vector2(cos(a) * (ax.x + w * 0.5 + w * 0.18), sin(a) * (ax.y + w * 0.22 + w * 0.12)).rotated(tilt))
			fat_i.append(c + Vector2(cos(a) * (ax.x - w * 0.5 - w * 0.18), sin(a) * (ax.y - w * 0.22 - w * 0.12)).rotated(tilt))
		var fat := fat_o.duplicate()
		for i in range(fat_i.size() - 1, -1, -1):
			fat.append(fat_i[i])
		draw_colored_polygon(fat, rim)
		_aa_edge(fat, rim)
		draw_colored_polygon(grow, col)
		_aa_edge(grow, col)

	func _ring_edge(c: Vector2, ax: Vector2, tilt: float, a0: float, a1: float, col: Color, w: float) -> void:
		var pts := PackedVector2Array()
		for i in 31:
			var a := lerpf(a0, a1, float(i) / 30.0)
			pts.append(c + Vector2(cos(a) * ax.x, sin(a) * ax.y + w * 0.6).rotated(tilt))
		draw_polyline(pts, col, w, true)

	## draw_colored_polygon is not antialiased; an antialiased line round it in the same colour softens the stair-steps
	## (the backdrop is baked at half the letters' resolution and shown 2x).
	func _aa_edge(pts: PackedVector2Array, col: Color) -> void:
		var l := pts.duplicate()
		l.append(pts[0])
		draw_polyline(l, col, 1.5, true)

	func _ellipse(c: Vector2, half: Vector2, col: Color) -> void:
		var pts := PackedVector2Array()
		for i in 48:
			var a := TAU * float(i) / 48.0
			pts.append(c + Vector2(cos(a) * half.x, sin(a) * half.y))
		draw_colored_polygon(pts, col)

	func _circle_line(c: Vector2, rad: float, col: Color, w: float) -> void:
		var pts := PackedVector2Array()
		for i in 65:
			var a := TAU * float(i) / 64.0
			pts.append(c + Vector2(cos(a), sin(a)) * rad)
		draw_polyline(pts, col, w, true)


# ======================================================================================== THE LETTERS
static func glyph(ch: String, index: int, style: Dictionary) -> Node2D:
	TitleLettering._ensure_tables()
	var table: Dictionary = TitleLettering._glyphs
	if not table.has(ch):
		return null
	var g: Dictionary = table[ch]
	var w := float(g["w"])
	var strokes: Array = []
	for s: PackedVector2Array in g["strokes"]:
		strokes.append(s)
	# The O of CHROME: the style names which letter (counted from 0 over both lines, spaces skipped).
	var cog := ch == "O" and index == int(style.get("cog_at", -1))
	var root := Node2D.new()
	var stroke := float(style.get("stroke", 0.17))
	var outline := float(style.get("outline", 0.045))
	# The cog's teeth: ten squared, slightly tapered blocks standing on the ring (round-capped strokes read as a ship's
	# wheel's handles - the critic). Each is a quad in layout pixels from the ring's centre line outward.
	var teeth: Array[PackedVector2Array] = []
	if cog:
		for i in 10:
			var a := TAU * (float(i) + 0.5) / 10.0
			var base := Vector2(0.33 + 0.31 * cos(a), 0.5 + 0.5 * sin(a))
			var nrm := Vector2(cos(a) / 0.31, sin(a) / 0.5).normalized()
			var tg := Vector2(-nrm.y, nrm.x)
			var h := stroke * 0.5 + 0.085
			var q := PackedVector2Array([base - tg * 0.068, base + tg * 0.068, base + nrm * h + tg * 0.046,
				base + nrm * h - tg * 0.046])
			var qp := PackedVector2Array()
			for p in q:
				qp.append(Vector2(p.x - w * 0.5, -p.y) * PX)
			teeth.append(qp)
	var lines: Array[PackedVector2Array] = []
	for s: PackedVector2Array in strokes:
		var pts := PackedVector2Array()
		for p in _dense(s):
			pts.append(Vector2(p.x - w * 0.5, -p.y) * PX)
		lines.append(pts)
	# 1. the soft shadow, stamped along every stroke, a little down
	var sh := _Stamps.new()
	sh.lines = lines
	sh.offset = Vector2(0.025, 0.07) * PX
	sh.radius = (stroke * 0.5 + outline + 0.10) * PX
	sh.col = SHADOW
	root.add_child(sh)
	# 2. the extrude (the plate's thickness), 3. the outline, 4. the core, 5. the lower bevel, 6. the lit top edge
	for pts in lines:
		_line(root, _shift(pts, Vector2(0.0, 0.055 * PX)), (stroke + outline * 2.0) * PX, EXTRUDE)
	if not teeth.is_empty():
		root.add_child(_Teeth.make(teeth, Vector2(0.0, 0.055 * PX), outline * PX, EXTRUDE, EXTRUDE))
	for pts in lines:
		_line(root, pts, (stroke + outline * 2.0) * PX, OUTLINE)
	if not teeth.is_empty():
		root.add_child(_Teeth.make(teeth, Vector2.ZERO, outline * PX, OUTLINE, OUTLINE))
		root.add_child(_Teeth.make(teeth, Vector2.ZERO, 0.0, BRASS_TOP, BRASS_LOW))
	for pts in lines:
		_line(root, pts, stroke * PX, BRASS)
	for pts in lines:
		_line(root, _shift(pts, Vector2(0.0, stroke * 0.24 * PX)), stroke * 0.40 * PX, BRASS_LOW)
	for pts in lines:
		_line(root, _shift(pts, Vector2(0.0, -stroke * 0.25 * PX)), stroke * 0.36 * PX, BRASS_TOP)
	# 7. rivets on the free stroke ends (not on the cog's teeth: they are the teeth)
	var dots := _Rivets.new()
	var n_main := (g["strokes"] as Array).size()
	for si in n_main:
		var s: PackedVector2Array = strokes[si]
		for e: Vector2 in [s[0], s[s.size() - 1]]:
			if "'.-".contains(ch) or _touches_other(strokes, si, e) or s[0].distance_to(s[s.size() - 1]) < 0.05:
				continue
			dots.at.append(Vector2(e.x - w * 0.5, -e.y) * PX)
	dots.r = stroke * 0.17 * PX
	root.add_child(dots)
	if cog:
		root.set_meta("w", w + 0.14)
	return root


## The cog's teeth, drawn once: each quad grown by `grow` px (the outline round it), shifted by `off`, the outer end in
## `outer_col` fading to `inner_col` at the ring, with an antialiased edge.
class _Teeth extends Node2D:
	var quads: Array[PackedVector2Array] = []
	var off := Vector2.ZERO
	var grow := 0.0
	var outer_col := Color.WHITE
	var inner_col := Color.WHITE

	static func make(q: Array[PackedVector2Array], o: Vector2, g: float, oc: Color, ic: Color) -> _Teeth:
		var t := _Teeth.new()
		t.quads = q
		t.off = o
		t.grow = g
		t.outer_col = oc
		t.inner_col = ic
		return t

	func _draw() -> void:
		for q in quads:
			var c := (q[0] + q[1] + q[2] + q[3]) * 0.25
			var pts := PackedVector2Array()
			for p in q:
				pts.append(p + (p - c).normalized() * grow * 1.4 + off)
			var cols := PackedColorArray([inner_col, inner_col, outer_col, outer_col])
			draw_polygon(pts, cols)
			var l := pts.duplicate()
			l.append(pts[0])
			var lc := cols.duplicate()
			lc.append(cols[0])
			draw_polyline_colors(l, lc, 1.5, true)


static func _dense(s: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	if s.size() < 2:
		return s
	out.append(s[0])
	for i in range(1, s.size()):
		var a := s[i - 1]
		var b := s[i]
		if a.distance_to(b) < 1e-4:
			continue
		var k := maxi(1, int(ceil(a.distance_to(b) / STEP)))
		for j in range(1, k + 1):
			out.append(a.lerp(b, float(j) / float(k)))
	return out


static func _shift(pts: PackedVector2Array, d: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		out.append(p + d)
	return out


static func _touches_other(strokes: Array, own: int, p: Vector2) -> bool:
	for j in strokes.size():
		if j == own:
			continue
		var o: PackedVector2Array = strokes[j]
		for k in range(1, o.size()):
			if Geometry2D.get_closest_point_to_segment(p, o[k - 1], o[k]).distance_to(p) < 0.08:
				return true
	return false


static func _line(parent: Node2D, pts: PackedVector2Array, width: float, col: Color) -> void:
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


## A soft band along each line: the shared soft dot stamped every few pixels. Translucent stamps stack smoothly to an
## even band (a translucent Line2D would double up at its round joints - the "sunburst fans" in title_lettering.gd).
class _Stamps extends Node2D:
	var lines: Array[PackedVector2Array] = []
	var offset := Vector2.ZERO
	var radius := 20.0
	var col := Color(0, 0, 0, 0.3)

	func _draw() -> void:
		var tex: Texture2D = TitleLettering._dot_texture()
		var size := Vector2.ONE * radius * 2.0
		var step := maxf(radius * 0.22, 1.0)
		for pts in lines:
			var acc := step
			for i in pts.size():
				if i > 0:
					acc += pts[i].distance_to(pts[i - 1])
				if acc < step and i < pts.size() - 1:
					continue
				acc = 0.0
				draw_texture_rect(tex, Rect2(pts[i] + offset - size * 0.5, size), false, col)


class _Rivets extends Node2D:
	var at := PackedVector2Array()
	var r := 3.0

	func _draw() -> void:
		for p in at:
			draw_circle(p, r * 1.35, OUTLINE, true, -1.0, true)
			draw_circle(p, r, RIVET, true, -1.0, true)
			draw_circle(p + Vector2(-0.3, -0.35) * r, r * 0.38, Color(BRASS_TOP, 0.95), true, -1.0, true)
