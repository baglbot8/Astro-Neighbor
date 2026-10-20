class_name TitleMockups
extends RefCounted
## THREE TITLE MOCK-UPS for Zorp's name card (builder SINTRO, 2026-10-19; STILLS for the user to pick from). The user:
## the current lettering "looks a bit too cheap ... Could partially be the color choices here with the bright white
## and light blue. I do want the font to have a bit of the personality of the planet. Almost a bit like how Kingdom
## Hearts levels have artwork for each location ... Zorp's planet is known for mushrooms maybe the 'T' is a mushroom
## or there's a wider purple mushroom silhouette behind the letters."
##
##   M1 `crest()`        a wide violet mushroom crest (cap with spots and gills, a stalk) behind the two lines, the
##                       letters warm cream-gold with a plum outline, a soft pink-violet shadow and a lit top edge
##   M2 `mushroom_t()`   the T in VIOLET is a little glowing mushroom; the other letters lilac with a plum outline,
##                       amber bulbs on their tips, a few drifting spores
##   M3 `plaque()`       a location plaque: a rounded deep-violet card with a thin gold border, a mushroom-ring
##                       motif along its foot, sparkles, and engraved gold letters
##
## Each returns a CanvasGroup centred on its origin (fade it with `self_modulate`, so the layers never ghost) with
## meta "block_size". Drawn LIVE (Line2D strokes + simple shapes): fine for a still; to ship one, bake it the way
## TitleLettering does. The glyphs are TitleLettering's stroke font. Every colour is Zorp's own (zorp_meshes.gd and
## the planet's glow keys) - no white, no light blue as a main colour; teal not used.

const Z := preload("res://src/planet_safari/worlds/zorp_meshes.gd")
const PX := 100.0                       # cap height while drawing (the caller scales the group)
const AMBER := Color("#e8bf72")         # the lantern-beetles' warm glow key (zorp.gd _glow_warm)
const AMBER_DEEP := Color("#c99a52")    # the same amber a step down, for a letter's lower half / a border's shade
const BULB_PINK := Color("#d692c4")     # the tentacle bulbs (_glow_pink)
const BULB_GLOW := Color("#d066ae")
const PLUM_DARK := Color("#2e2440")     # SHELL, a step darker (the plaque's face; under S 0.40)


# ======================================================================================== M1: THE MUSHROOM CREST
static func crest(lines: PackedStringArray, subtitle: String) -> CanvasGroup:
	var g := _group()
	var lay := _layout(lines, 0.17, 0.42)
	var bs: Vector2 = lay["size"]
	# The crest: a wide, low cap (scalloped rim), its gills underneath, spots, and a short stalk below the words.
	var shapes := _Shapes.new()
	# A tall dome sitting on the gap between the two lines; the stalk comes down behind HOLLOW and shows below it.
	var cap_w := bs.x * 0.58
	var cap_h := bs.y * 0.95
	var cap_c := Vector2(0.0, bs.y * 0.02)
	shapes.add_shadow_ellipse(cap_c + Vector2(0.0, -cap_h * 0.35), Vector2(cap_w * 1.06, cap_h * 0.85), Color(BULB_GLOW, 0.12))
	shapes.add_stalk(cap_c + Vector2(0.0, cap_h * 0.1), cap_w * 0.17, bs.y * 0.78, Z.STALK, PLUM_DARK)
	shapes.add_dome(cap_c, cap_w, cap_h, Z.SHELL, PLUM_DARK, 9)
	shapes.add_crown(cap_c, cap_w, cap_h, Z.STALK)
	shapes.add_gills(cap_c, cap_w * 0.97, cap_h * 0.13, Z.CAP_UNDER, PLUM_DARK)
	for sp: Vector3 in [Vector3(-0.62, -0.42, 0.06), Vector3(-0.3, -0.8, 0.055), Vector3(0.18, -0.9, 0.05),
			Vector3(0.55, -0.62, 0.065), Vector3(0.84, -0.22, 0.045), Vector3(-0.86, -0.15, 0.04)]:
		shapes.add_spot(cap_c + Vector2(sp.x * cap_w, sp.y * cap_h), sp.z * cap_w, Z.SPOT, Color(AMBER, 0.0))
	g.add_child(shapes)
	var letters := _letters(lay, {"core_top": Z.SPOT, "core": Color("#e9cf96"), "outline": Z.SHELL,
		"shadow": Color(BULB_GLOW, 0.45), "stroke": 0.17, "outline_w": 0.05, "slant": 0.0, "wobble": 0.0})
	g.add_child(letters)
	_subtitle(g, subtitle, bs, Z.RING_STEM, Z.SHELL)
	g.set_meta("block_size", Vector2(cap_w * 2.1, bs.y * 1.25))
	return g


# ======================================================================================== M2: THE MUSHROOM T
static func mushroom_t(lines: PackedStringArray, subtitle: String) -> CanvasGroup:
	var g := _group()
	var lay := _layout(lines, 0.17, 0.42)
	var bs: Vector2 = lay["size"]
	var letters := _letters(lay, {"core_top": Color("#d7cae6"), "core": Z.FRILL, "outline": Z.SHELL,
		"shadow": Color(Z.SHELL, 0.55), "stroke": 0.16, "outline_w": 0.05, "slant": 0.04, "wobble": 0.03,
		"tip_bulb": AMBER, "skip": "T"})
	g.add_child(letters)
	# The T: a mushroom - stalk where the T's stem is, a cap where its bar is, glowing spots.
	# Shaped as a T: a wide, flat cap whose top lines up with the other letters' tops (the T's bar), and a stalk in the
	# letters' own lilac-and-plum stroke (the T's stem), so it reads as a letter first and a mushroom second.
	var t_at: Vector2 = lay.get("T", Vector2.ZERO)
	var shapes := _Shapes.new()
	var hw := PX * 0.4
	var h := PX * 0.34
	var cap_c := t_at + Vector2(0.0, -PX * 0.7)
	shapes.add_shadow_ellipse(cap_c + Vector2(0.0, -h * 0.4), Vector2(hw * 1.15, h * 0.95), Color(BULB_GLOW, 0.22))
	shapes.add_stalk(cap_c, PX * 0.1, PX * 0.7, Color("#d7cae6"), Z.SHELL)
	shapes.add_dome(cap_c, hw, h, Z.CAP, Z.SHELL, 5)
	shapes.add_crown(cap_c, hw, h, Z.PETAL_TIP)
	shapes.add_gills(cap_c, hw * 0.97, h * 0.2, Z.CAP_UNDER, Z.SHELL)
	for sp: Vector3 in [Vector3(-0.5, -0.4, 0.13), Vector3(0.05, -0.72, 0.12), Vector3(0.52, -0.38, 0.11)]:
		shapes.add_spot(cap_c + Vector2(sp.x * hw, sp.y * h), sp.z * hw, AMBER, Color(AMBER, 0.35))
	g.add_child(shapes)
	var spores := _Shapes.new()
	for sp: Vector3 in [Vector3(-0.42, -0.62, 3.0), Vector3(-0.2, -0.75, 2.2), Vector3(0.08, -0.7, 2.6),
			Vector3(0.33, -0.66, 2.0), Vector3(0.46, -0.3, 2.4), Vector3(-0.47, 0.05, 1.8)]:
		spores.add_spore(Vector2(sp.x * bs.x, sp.y * bs.y), sp.z, AMBER if int(sp.z * 10) % 2 == 0 else BULB_PINK)
	g.add_child(spores)
	_subtitle(g, subtitle, bs, Z.FRILL, Z.SHELL)
	g.set_meta("block_size", bs * Vector2(1.05, 1.3))
	return g


# ======================================================================================== M3: THE LOCATION PLAQUE
static func plaque(lines: PackedStringArray, subtitle: String) -> CanvasGroup:
	var g := _group()
	var lay := _layout(lines, 0.15, 0.36)
	var bs: Vector2 = lay["size"]
	var shapes := _Shapes.new()
	var size := bs + Vector2(PX * 1.1, PX * 1.35)
	var c := Vector2(0.0, PX * 0.12)
	shapes.add_shadow_rrect(c + Vector2(0.0, PX * 0.08), size + Vector2(PX * 0.2, PX * 0.2), Color(PLUM_DARK, 0.45))
	shapes.add_plaque(c, size, PX * 0.42, PLUM_DARK, Z.SHELL, AMBER, AMBER_DEEP)
	# The mushroom-ring motif along the plaque's foot, and a few sparkles on its face.
	# A little mushroom ring either side of the subtitle, tallest at the outside (a fairy ring seen side-on).
	var foot := c.y + size.y * 0.5 - PX * 0.24
	for side in [-1.0, 1.0]:
		for i in 4:
			var u := 0.26 + 0.06 * float(i)
			shapes.add_tiny_mushroom(Vector2(side * u * size.x, foot), PX * (0.2 + 0.05 * float(i)),
				Z.CAP if i % 2 == 0 else Z.RING_CAP, Z.RING_STEM, Z.SHELL)
	for sp: Vector3 in [Vector3(-0.44, -0.4, 2.6), Vector3(0.43, -0.36, 2.2), Vector3(-0.38, 0.22, 1.8),
			Vector3(0.41, 0.25, 2.0)]:
		shapes.add_spore(Vector2(sp.x * size.x, sp.y * size.y) + c, sp.z, AMBER)
	g.add_child(shapes)
	var letters := _letters(lay, {"core_top": Color("#f0d79a"), "core": AMBER, "outline": Color("#6b4f2e"),
		"engrave": true, "stroke": 0.15, "outline_w": 0.025, "slant": 0.0, "wobble": 0.0})
	g.add_child(letters)
	_subtitle(g, subtitle, bs, AMBER, PLUM_DARK, PX * 0.02)
	g.set_meta("block_size", size)
	return g


# ======================================================================================== LETTERS
## Lays out `lines` centred on the origin (y down, baselines in pixels at PX cap height). Returns {"size",
## "glyphs": Array of [char, baseline-centre Vector2], and each special char's position by name}.
static func _layout(lines: PackedStringArray, track: float, gap: float) -> Dictionary:
	TitleLettering._ensure_tables()
	var gl: Dictionary = TitleLettering._glyphs
	var widths := PackedFloat32Array()
	var maxw := 0.0
	for ln in lines:
		var w := 0.0
		for i in ln.length():
			w += _adv(gl, ln[i]) + (track if i < ln.length() - 1 else 0.0)
		widths.append(w)
		maxw = maxf(maxw, w)
	var n := lines.size()
	var total_h := float(n) + gap * float(n - 1)
	var out := {"size": Vector2(maxw, total_h) * PX, "glyphs": []}
	for li in n:
		var x := -widths[li] * 0.5
		var base_y := (-total_h * 0.5 + float(li) * (1.0 + gap) + 1.0) * PX
		for i in lines[li].length():
			var ch := lines[li][i]
			var adv := _adv(gl, ch)
			if ch != " ":
				var at := Vector2((x + adv * 0.5) * PX, base_y)
				(out["glyphs"] as Array).append([ch, at])
				if not out.has(ch):
					out[ch] = at
			x += adv + track
	return out


static func _adv(gl: Dictionary, ch: String) -> float:
	if ch == " ":
		return TitleLettering.SPACE_ADVANCE
	return float((gl.get(ch, {"w": 0.6}) as Dictionary)["w"])


## The strokes of every glyph, drawn in layers so each reads with depth: a soft offset shadow, a dark outline, the
## core, then a lit top edge (a thinner, lighter stroke nudged up). `st`: core_top, core, outline, shadow, stroke,
## outline_w, slant, wobble, tip_bulb (a colour: bulbs on upward tips), skip (chars drawn elsewhere), engrave (gold
## letters cut into a plaque: a dark lip above, a light lip below, instead of the shadow).
static func _letters(lay: Dictionary, st: Dictionary) -> Node2D:
	var root := Node2D.new()
	var gl: Dictionary = TitleLettering._glyphs
	var layers: Array[Node2D] = []
	for i in 5:
		var n := Node2D.new()
		root.add_child(n)
		layers.append(n)
	var stroke := float(st.get("stroke", 0.15))
	var ow := float(st.get("outline_w", 0.05))
	var skip := str(st.get("skip", ""))
	var engrave := bool(st.get("engrave", false))
	for item: Array in lay["glyphs"]:
		var ch: String = item[0]
		var at: Vector2 = item[1]
		if skip.contains(ch) or not gl.has(ch):
			continue
		var g: Dictionary = gl[ch]
		var w := float(g["w"])
		var idx := (lay["glyphs"] as Array).find(item)
		for s: PackedVector2Array in g["strokes"]:
			var pts := PackedVector2Array()
			for p in _dense(s):
				var x := p.x - w * 0.5 + float(st.get("slant", 0.0)) * p.y \
					+ float(st.get("wobble", 0.0)) * sin(PI * 1.3 * p.y + float(idx) * 2.3) * p.y
				pts.append(at + Vector2(x, -p.y) * PX)
			if engrave:
				_line(layers[0], _shift(pts, Vector2(0.0, -PX * 0.035)), (stroke + ow * 2.0) * PX, Color(PLUM_DARK, 0.9))
				_line(layers[0], _shift(pts, Vector2(0.0, PX * 0.035)), (stroke + ow * 2.0) * PX, Color(AMBER_DEEP, 0.55))
			else:
				_line(layers[0], _shift(pts, Vector2(PX * 0.03, PX * 0.07)), (stroke + ow * 2.0 + 0.06) * PX,
					st.get("shadow", Color(0, 0, 0, 0.4)))
			_line(layers[1], pts, (stroke + ow * 2.0) * PX, st.get("outline", Color.BLACK))
			_line(layers[2], pts, stroke * PX, st.get("core", Color.WHITE))
			_line(layers[3], _shift(pts, Vector2(0.0, -stroke * PX * 0.22)), stroke * PX * 0.42, st.get("core_top", Color.WHITE))
		var tip: Variant = st.get("tip_bulb")
		if tip is Color:
			for s: PackedVector2Array in g["strokes"]:
				for end_i in [0, s.size() - 1]:
					var e: Vector2 = s[end_i]
					var nb: Vector2 = s[1] if end_i == 0 else s[s.size() - 2]
					if e.y < 0.9 or (e - nb).normalized().y < 0.5 or ch == "I":
						continue
					var sh := _Shapes.new()
					var px_at := at + Vector2(e.x - w * 0.5 + float(st.get("slant", 0.0)), -e.y) * PX
					sh.add_spot(px_at, PX * 0.085, tip, Color(tip, 0.45), st.get("outline", Color.BLACK))
					layers[4].add_child(sh)
	return root


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
		var k := maxi(1, int(ceil(a.distance_to(b) / 0.035)))
		for j in range(1, k + 1):
			out.append(a.lerp(b, float(j) / float(k)))
	return out


static func _shift(pts: PackedVector2Array, d: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		out.append(p + d)
	return out


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


static func _group() -> CanvasGroup:
	var g := CanvasGroup.new()
	g.name = "TitleMockup"
	return g


static func _subtitle(g: Node, text: String, bs: Vector2, col: Color, outline: Color, extra_y: float = 0.0) -> void:
	if text == "":
		return
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", UIStyle.ui_font())
	l.add_theme_font_size_override("font_size", int(PX * 0.34))
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(outline, 0.9))
	l.add_theme_constant_override("outline_size", int(PX * 0.07))
	l.reset_size()
	l.position = Vector2(-l.size.x * 0.5, bs.y * 0.5 + PX * 0.12 + extra_y)
	g.add_child(l)


# ======================================================================================== SHAPES
## The procedural shapes, drawn once in `_draw`.
class _Shapes extends Node2D:
	var _ops: Array = []

	func add_dome(c: Vector2, half_w: float, h: float, col: Color, rim: Color, scallops: int) -> void:
		_ops.append(["dome", c, half_w, h, col, rim, scallops])

	## `alpha` < 1: a translucent sheen (the stills). 1.0 with a colour already blended over the cap: opaque, so its
	## edge can be antialiased (a baked crest).
	func add_crown(c: Vector2, half_w: float, h: float, col: Color, alpha: float = 0.55) -> void:
		_ops.append(["crown", c, half_w, h, col, alpha])

	func add_gills(c: Vector2, half_w: float, h: float, col: Color, line_col: Color) -> void:
		_ops.append(["gills", c, half_w, h, col, line_col])

	func add_stalk(top: Vector2, half_w: float, h: float, col: Color, rim: Color) -> void:
		_ops.append(["stalk", top, half_w, h, col, rim])

	func add_spot(c: Vector2, r: float, col: Color, glow: Color, rim: Color = Color(0, 0, 0, 0)) -> void:
		_ops.append(["spot", c, r, col, glow, rim])

	func add_spore(c: Vector2, r: float, col: Color) -> void:
		_ops.append(["spore", c, r, col])

	func add_shadow_ellipse(c: Vector2, half: Vector2, col: Color) -> void:
		_ops.append(["ell", c, half, col])

	func add_shadow_rrect(c: Vector2, size: Vector2, col: Color) -> void:
		_ops.append(["rrect", c, size, size.y * 0.3, col])

	func add_plaque(c: Vector2, size: Vector2, r: float, face: Color, face_top: Color, border: Color, border_shade: Color) -> void:
		_ops.append(["plaque", c, size, r, face, face_top, border, border_shade])

	func add_tiny_mushroom(base: Vector2, s: float, cap: Color, stem: Color, rim: Color) -> void:
		_ops.append(["tiny", base, s, cap, stem, rim])

	func _draw() -> void:
		for op: Array in _ops:
			match str(op[0]):
				"dome": _dome(op[1], op[2], op[3], op[4], op[5], op[6])
				"gills": _gills(op[1], op[2], op[3], op[4], op[5])
				"crown":
					var cp := PackedVector2Array()
					var cc: Vector2 = op[1]
					var chw: float = op[2]
					var ch: float = op[3]
					for i in 25:
						var a := PI * 1.12 + PI * 0.76 * float(i) / 24.0
						cp.append(cc + Vector2(cos(a) * chw * 0.86, sin(a) * ch * 0.9))
					for i in 25:
						var a := PI * 1.88 - PI * 0.76 * float(i) / 24.0
						cp.append(cc + Vector2(cos(a) * chw * 0.62, sin(a) * ch * 0.62))
					draw_colored_polygon(cp, Color(op[4], op[5]))
					if float(op[5]) >= 1.0:
						_aa_edge(cp, op[4])
				"stalk": _stalk(op[1], op[2], op[3], op[4], op[5])
				"spot":
					if (op[4] as Color).a > 0.0:
						draw_circle(op[1], (op[2] as float) * 1.45, op[4], true, -1.0, true)
					if (op[5] as Color).a > 0.0:
						draw_circle(op[1], (op[2] as float) * 1.18, op[5], true, -1.0, true)
					draw_circle(op[1], op[2], op[3], true, -1.0, true)
				"spore":
					draw_circle(op[1], (op[2] as float) * 2.4, Color(op[3], 0.25), true, -1.0, true)
					draw_circle(op[1], op[2], op[3], true, -1.0, true)
				"ell": _ellipse(op[1], op[2], op[3])
				"rrect": draw_colored_polygon(_rrect_pts(op[1], op[2], op[3]), op[4])
				"plaque": _plaque(op[1], op[2], op[3], op[4], op[5], op[6], op[7])
				"tiny": _tiny(op[1], op[2], op[3], op[4], op[5])

	func _ellipse(c: Vector2, half: Vector2, col: Color) -> void:
		var pts := PackedVector2Array()
		for i in 48:
			var a := TAU * float(i) / 48.0
			pts.append(c + Vector2(cos(a) * half.x, sin(a) * half.y))
		# a soft edge: three shrinking copies
		for k in 3:
			var s := 1.0 - 0.12 * float(k)
			var q := PackedVector2Array()
			for p in pts:
				q.append(c + (p - c) * s)
			draw_colored_polygon(q, Color(col, col.a * 0.6))

	## A cap: the upper half of an ellipse with a scalloped rim, a darker band at its foot, a lighter crown.
	func _dome(c: Vector2, hw: float, h: float, col: Color, rim: Color, scallops: int) -> void:
		var pts := PackedVector2Array()
		for i in 41:
			var a := PI + PI * float(i) / 40.0
			pts.append(c + Vector2(cos(a) * hw, sin(a) * h))
		for i in range(scallops * 2 + 1):
			var u := 1.0 - 2.0 * float(i) / float(scallops * 2)
			var dip := 0.0 if i % 2 == 0 else h * 0.08
			pts.append(c + Vector2(u * hw, dip))
		draw_colored_polygon(pts, rim)
		_aa_edge(pts, rim)
		var inner := PackedVector2Array()
		var k := 0.95
		for p in pts:
			inner.append(c + (p - c) * Vector2(k, k) - Vector2(0.0, h * 0.02))
		draw_colored_polygon(inner, col)
		_aa_edge(inner, col)

	## A polygon's edge redrawn as a thin antialiased line in its own colour: draw_colored_polygon has no
	## antialiasing, and a shape baked at half resolution and scaled up showed stair-stepped edges (the crest in
	## the game, 2026-10-20).
	func _aa_edge(pts: PackedVector2Array, col: Color, w: float = 2.5) -> void:
		var loop := pts.duplicate()
		loop.append(pts[0])
		draw_polyline(loop, col, w, true)


	func _gills(c: Vector2, hw: float, h: float, col: Color, line_col: Color) -> void:
		var pts := PackedVector2Array([c + Vector2(-hw, 0.0), c + Vector2(hw, 0.0), c + Vector2(hw * 0.7, h),
			c + Vector2(-hw * 0.7, h)])
		draw_colored_polygon(pts, col)
		_aa_edge(pts, col)
		for i in 15:
			var u := -1.0 + 2.0 * float(i) / 14.0
			draw_line(c + Vector2(u * hw * 0.95, 1.0), c + Vector2(u * hw * 0.55, h), Color(line_col, 0.55), maxf(1.5, hw * 0.006), true)

	func _stalk(top: Vector2, hw: float, h: float, col: Color, rim: Color) -> void:
		var pts := PackedVector2Array([top + Vector2(-hw * 0.85, 0.0), top + Vector2(hw * 0.85, 0.0),
			top + Vector2(hw, h * 0.9), top + Vector2(hw * 0.6, h), top + Vector2(-hw * 0.6, h), top + Vector2(-hw, h * 0.9)])
		var outer := PackedVector2Array()
		for p in pts:
			outer.append(top + (p - top) * 1.06 + Vector2(0.0, -h * 0.02))
		draw_colored_polygon(outer, rim)
		_aa_edge(outer, rim)
		draw_colored_polygon(pts, col)
		_aa_edge(pts, col)
		draw_line(top + Vector2(-hw * 0.4, h * 0.1), top + Vector2(-hw * 0.5, h * 0.85), Color(col.lightened(0.2), 0.8), hw * 0.18, true)

	func _rrect_pts(c: Vector2, size: Vector2, r: float) -> PackedVector2Array:
		var pts := PackedVector2Array()
		var hx := size.x * 0.5 - r
		var hy := size.y * 0.5 - r
		var corners := [Vector2(hx, hy), Vector2(-hx, hy), Vector2(-hx, -hy), Vector2(hx, -hy)]
		for k in 4:
			for i in 9:
				var a := PI * 0.5 * float(k) + PI * 0.5 * float(i) / 8.0
				pts.append(c + (corners[k] as Vector2) + Vector2(cos(a), sin(a)) * r)
		return pts

	## A rounded card with an arched top: border shade, gold border, the face (darker toward the foot), a thin
	## inner gold line.
	func _plaque(c: Vector2, size: Vector2, r: float, face: Color, face_top: Color, border: Color, shade: Color) -> void:
		var arch := size.y * 0.12
		var outer := _arched(c, size + Vector2(r * 0.22, r * 0.22), r, arch)
		draw_colored_polygon(_arched(c + Vector2(0.0, r * 0.06), size + Vector2(r * 0.22, r * 0.22), r, arch), shade)
		draw_colored_polygon(outer, border)
		draw_colored_polygon(_arched(c, size, r, arch), face)
		draw_colored_polygon(_arched(c - Vector2(0.0, size.y * 0.18), size * Vector2(0.97, 0.6), r * 0.8, arch * 0.8),
			Color(face_top, 0.55))
		var line := _arched(c, size - Vector2(r * 0.5, r * 0.5), r * 0.8, arch * 0.9)
		line.append(line[0])
		draw_polyline(line, Color(border, 0.75), maxf(1.5, r * 0.05), true)

	func _arched(c: Vector2, size: Vector2, r: float, arch: float) -> PackedVector2Array:
		var pts := _rrect_pts(c, size, r)
		var top := c.y - size.y * 0.5
		for i in pts.size():
			var p := pts[i]
			if p.y < c.y:
				var u := (p.x - c.x) / (size.x * 0.5)
				var w := (p.y - top) / maxf(size.y * 0.5, 1.0)
				pts[i] = p - Vector2(0.0, arch * (1.0 - u * u) * (1.0 - w))
		return pts

	func _tiny(base: Vector2, s: float, cap: Color, stem: Color, rim: Color) -> void:
		draw_rect(Rect2(base + Vector2(-s * 0.22, -s * 0.9), Vector2(s * 0.44, s * 0.9)), stem)
		var pts := PackedVector2Array()
		for i in 17:
			var a := PI + PI * float(i) / 16.0
			pts.append(base + Vector2(0.0, -s * 0.85) + Vector2(cos(a) * s * 0.62, sin(a) * s * 0.5))
		draw_colored_polygon(pts, cap)
		pts.append(pts[0])
		draw_polyline(pts, Color(rim, 0.8), maxf(1.0, s * 0.07), true)
		draw_circle(base + Vector2(-s * 0.2, -s * 1.08), s * 0.09, Z.SPOT, true, -1.0, true)
