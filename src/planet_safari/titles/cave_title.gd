extends RefCounted
## THE CRYSTAL CAVE'S TITLE SHAPES (TitleLettering, THE PLANET INTERFACE; builder CAVE-INTRO 2026-10-19, a DRAFT).
## The lead's direction is Zorp's M1 "crest": an EMBLEM behind two lines of lettering. The cave's emblem is a fan of
## faceted teal crystals (the cave's own crystal teal, cave_world.gd C_TEAL / C_TEAL_LIGHT / C_AQUA) growing out of a
## ledge of faceted warm-brown boulders, with a soft teal glow behind it. Every letter is drawn here too (`glyph` for every
## character), in layers that give it depth instead of a flat outline: a soft teal glow, a drop shadow, a warm
## stone-brown outline, a darker gold bevel at its foot, the gold-cream face, a lit top edge; two letters carry a small
## crystal glint. No pure white anywhere (the lightest colour is the highlight #f4e4bc, S 0.23).
## Wired in by CaveWorld.intro_data()'s "title_style" ("title_file"). Static, built once at `build`, then baked.

const PX := TitleLettering.BUILD_CAP_PX

# The letters: gold-cream face, a lighter lit top, a deeper gold foot, warm stone-brown outline, a dark umber shadow.
const FACE := Color("#e7c98c")
const FACE_TOP := Color("#f4e4bc")
const FACE_FOOT := Color("#c99a5a")
const RIM := Color("#4b3424")
const SHADOW := Color("#22170f")
const GLOW := Color("#35d8c4")            # CaveWorld.C_TEAL
# The emblem: the crystals' facets (deep, mid, light, the lit ridge), their outline; the stone ledge.
const CR_DEEP := Color("#1e6a6a")
const CR_MID := Color("#2f9f98")
const CR_LIGHT := Color("#6fd2c6")
const CR_RIDGE := Color("#b6ebe0")
const CR_RIM := Color("#10303a")
const STONE := Color("#6e5039")
## The warm underlight on the crest (the gold of the chest road's crystals, CaveWorld.C_GOLD / C_AMBER, softened).
const WARM := Color("#f0b266")
const STONE_TOP := Color("#937055")
const STONE_RIM := Color("#2c1f16")

## Letters (by index over the whole title, spaces not counted) that carry a crystal glint, and where on the letter
## (cap units from its baseline centre, y up).
const GLINTS := {5: Vector2(0.27, 1.0), 11: Vector2(0.0, 1.04)}


## The emblem behind the letters, centred on the title block, drawn for the layout "THE" / "CRYSTAL CAVE" (CaveWorld's
## title_lines). Round 3 (the critic: the crystals crowded "THE", which sat inside the crest): the crest now FRAMES
## "THE" - two tall crystals rise either side of it, leaning out, with their inner edges kept clear of the word's own
## width; the middle holds only a short crystal whose tip stops in the gap under "THE". The crystals grow from a ledge of
## faceted boulders under "CRYSTAL CAVE" and are lit WARM from below (an amber light off the ledge fading up each crystal),
## with the cave's teal glow behind and low.
static func backdrop(block_size: Vector2, _style: Dictionary) -> Node2D:
	var e := _Emblem.new()
	var w := block_size.x
	var h := block_size.y
	var base := Vector2(0.0, h * 0.45)
	# [angle (deg from up, + right), length (x block height), half-width (x cap), x of the root (x block width)].
	# Outer pair, middle pair, the pair framing "THE", the short middle one - back to front.
	var crystals := [
		[-48.0, 0.55, 0.27, -0.27], [48.0, 0.53, 0.26, 0.27],
		[-30.0, 0.88, 0.32, -0.23], [31.0, 0.84, 0.31, 0.23],
		[-12.0, 1.15, 0.38, -0.17], [12.0, 1.12, 0.38, 0.17],
		[0.0, 0.43, 0.3, 0.0],
	]
	e.glow_c = Vector2(0.0, h * 0.1)
	e.glow_r = Vector2(w * 0.34, h * 0.5)
	for c: Array in crystals:
		var dir := Vector2(sin(deg_to_rad(float(c[0]))), -cos(deg_to_rad(float(c[0]))))
		e.add_crystal(base + Vector2(float(c[3]) * w, 0.0), dir, float(c[1]) * h, float(c[2]) * PX)
	e.ledge_c = base + Vector2(0.0, h * 0.16)
	e.ledge_half = Vector2(w * 0.3, h * 0.22)
	# Extent round the block centre (symmetric): from the framing crystals' tips / the ledge's foot, the outer tips' width.
	var top := maxf(maxf(1.15 * h - h * 0.45, h * 0.1 + h * 0.5), h * 0.16 + h * 0.45 + h * 0.3) + PX * 0.3
	e.set_meta("size", Vector2(w * 0.88, top * 2.0))
	# The teal glow: one smooth radial sprite behind the shapes, low (so "THE" sits on stone-dark, not on the glow).
	var dot := TitleLettering._dot_texture()
	var gs := Sprite2D.new()
	gs.texture = dot
	gs.modulate = Color(GLOW, 0.26)
	gs.position = e.glow_c
	gs.scale = e.glow_r * 2.0 / float(dot.width)
	gs.show_behind_parent = true
	e.add_child(gs)
	# The warm light off the ledge, over the crystals' feet and the ledge's top (drawn after them).
	var ws := Sprite2D.new()
	ws.texture = dot
	ws.modulate = Color(WARM, 0.38)
	ws.position = base + Vector2(0.0, h * 0.04)
	ws.scale = Vector2(w * 0.62, h * 0.5) / float(dot.width)
	e.add_child(ws)
	return e


## Every letter: the stroke font's own strokes (TitleLettering's glyph table), drawn in depth layers.
static func glyph(ch: String, index: int, style: Dictionary) -> Node2D:
	var gl: Dictionary = TitleLettering._glyphs
	if not gl.has(ch):
		return null
	var g: Dictionary = gl[ch]
	var w := float(g["w"])
	var stroke := float(style.get("stroke", 0.17))
	var ow := float(style.get("outline", 0.05))
	var root := Node2D.new()
	var strokes: Array[PackedVector2Array] = []
	for s: PackedVector2Array in g["strokes"]:
		var pts := PackedVector2Array()
		for p in _dense(s):
			pts.append(Vector2(p.x - w * 0.5, -p.y) * PX)
		strokes.append(pts)
	# 1. the soft teal glow: faint radial dots along every stroke (they add up into a halo; never a hard ring)
	var dot := TitleLettering._dot_texture()
	for pts in strokes:
		var step := maxi(1, int(pts.size() / maxf(1.0, _len(pts) / (PX * 0.16))))
		for i in range(0, pts.size(), step):
			var sp := Sprite2D.new()
			sp.texture = dot
			sp.modulate = Color(GLOW, 0.42)
			sp.position = pts[i] + Vector2(0.0, PX * 0.02)
			sp.scale = Vector2.ONE * (PX * 0.4 / float(dot.width))
			root.add_child(sp)
	# 2. the drop shadow (opaque: a translucent Line2D shows its joints), down and a little right
	for pts in strokes:
		_line(root, _shift(pts, Vector2(PX * 0.025, PX * 0.065)), (stroke + ow * 2.0) * PX, SHADOW)
	# 3. the outline, 4. the foot's deeper gold (nudged down), 5. the face, 6. the lit top edge (nudged up, thinner)
	for pts in strokes:
		_line(root, pts, (stroke + ow * 2.0) * PX, RIM)
	for pts in strokes:
		_line(root, _shift(pts, Vector2(0.0, PX * 0.022)), stroke * PX, FACE_FOOT)
	for pts in strokes:
		_line(root, _shift(pts, Vector2(0.0, -PX * 0.012)), stroke * PX * 0.8, FACE)
	for pts in strokes:
		_line(root, _shift(pts, Vector2(0.0, -stroke * PX * 0.26)), stroke * PX * 0.34, FACE_TOP)
	if GLINTS.has(index):
		var at: Vector2 = GLINTS[index]
		var gn := _Glint.new()
		gn.position = Vector2(at.x, -at.y) * PX
		gn.r = PX * 0.17
		root.add_child(gn)
	root.set_meta("w", w)
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


static func _len(pts: PackedVector2Array) -> float:
	var l := 0.0
	for i in range(1, pts.size()):
		l += pts[i - 1].distance_to(pts[i])
	return l


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


## A small four-point crystal glint: a soft teal glow, a pale-cream star.
class _Glint extends Node2D:
	var r := 16.0

	func _draw() -> void:
		draw_circle(Vector2.ZERO, r * 0.9, Color(GLOW, 0.22), true, -1.0, true)
		draw_circle(Vector2.ZERO, r * 0.5, Color(GLOW, 0.3), true, -1.0, true)
		var pts := PackedVector2Array()
		for i in 8:
			var a := TAU * float(i) / 8.0 - PI * 0.5
			var rr := r if i % 2 == 0 else r * 0.22
			pts.append(Vector2(cos(a), sin(a)) * rr)
		draw_colored_polygon(pts, FACE_TOP)


## The crystal emblem, drawn once (then baked).
class _Emblem extends Node2D:
	var glow_c := Vector2.ZERO
	var glow_r := Vector2.ONE
	var ledge_c := Vector2.ZERO
	var ledge_half := Vector2.ONE
	var _cr: Array = []   # [root, dir, length, half-width]

	func add_crystal(root: Vector2, dir: Vector2, length: float, half_w: float) -> void:
		_cr.append([root, dir, length, half_w])

	func _draw() -> void:
		# back to front: the outer (lower) crystals first, the tall middle one last
		for c: Array in _cr:
			_crystal(c[0], c[1], c[2], c[3])
		_ledge()

	## Polygons are drawn without antialiasing: a thin antialiased line round the outer shape keeps its edge smooth
	## once the backdrop is baked small and scaled up.
	func _aa_edge(pts: PackedVector2Array, col: Color) -> void:
		var loop := pts.duplicate()
		loop.append(pts[0])
		draw_polyline(loop, col, 9.0, true)

	func _ellipse(c: Vector2, half: Vector2, n: int) -> PackedVector2Array:
		var pts := PackedVector2Array()
		for i in n:
			var a := TAU * float(i) / float(n)
			pts.append(c + Vector2(cos(a) * half.x, sin(a) * half.y))
		return pts

	## A hexagonal prism seen side-on with a pointed tip: an outline, a deep left face, a lit right face, a pale
	## ridge between them, and the tip's two facets.
	func _crystal(root: Vector2, dir: Vector2, length: float, hw: float) -> void:
		var side := Vector2(-dir.y, dir.x)   # to the crystal's right (y down: dir up -> side to the right)
		var tip_l := hw * 1.5
		var sh := root + dir * (length - tip_l)
		var tip := root + dir * length
		var rim := hw * 0.16
		var outer := PackedVector2Array([root - side * (hw + rim), sh - side * (hw + rim), tip + dir * rim * 1.6,
			sh + side * (hw + rim), root + side * (hw + rim)])
		draw_colored_polygon(outer, CR_RIM)
		_aa_edge(outer, CR_RIM)
		var ridge_r := root + side * hw * 0.18
		var ridge_s := sh + side * hw * 0.18
		draw_colored_polygon(PackedVector2Array([root - side * hw, sh - side * hw, ridge_s, ridge_r]), CR_DEEP)
		draw_colored_polygon(PackedVector2Array([ridge_r, ridge_s, sh + side * hw, root + side * hw]), CR_MID)
		# a lighter band down the right face, the tip facets
		draw_colored_polygon(PackedVector2Array([root + side * hw * 0.55, sh + side * hw * 0.55, sh + side * hw * 0.9,
			root + side * hw * 0.9]), Color(CR_LIGHT, 0.55))
		draw_colored_polygon(PackedVector2Array([sh - side * hw, tip, ridge_s]), CR_MID)
		draw_colored_polygon(PackedVector2Array([ridge_s, tip, sh + side * hw]), CR_LIGHT)
		draw_polyline(PackedVector2Array([sh - side * hw, tip, sh + side * hw]), CR_RIM, 5.0, true)
		# antialiased seams over the facet edges (the polygons themselves are drawn without antialiasing)
		draw_line(root - side * hw, sh - side * hw, CR_DEEP, 3.0, true)
		draw_line(root + side * hw, sh + side * hw, CR_MID, 3.0, true)
		draw_line(root + side * hw * 0.55, sh + side * hw * 0.55, CR_MID.lerp(CR_LIGHT, 0.4), 2.5, true)
		draw_line(root + side * hw * 0.9, sh + side * hw * 0.9, CR_MID.lerp(CR_LIGHT, 0.4), 2.5, true)
		draw_line(ridge_r, ridge_s, CR_RIDGE, maxf(1.5, hw * 0.1), true)
		# warm underlight: amber at the root fading out 45 % of the way up (per-vertex colours: a smooth gradient)
		var up := root + dir * length * 0.45
		draw_polygon(PackedVector2Array([root - side * hw, up - side * hw, up + side * hw, root + side * hw]),
			PackedColorArray([Color(WARM, 0.32), Color(WARM, 0.0), Color(WARM, 0.0), Color(WARM, 0.32)]))
		# and a warm rim up the lower part of both edges, brightest at the foot (the light catches the outline)
		for sg: float in [-1.0, 1.0]:
			var e0 := root + side * sg * (hw + rim * 0.5)
			var e1 := root + dir * length * 0.4 + side * sg * (hw + rim * 0.5)
			draw_polygon(PackedVector2Array([e0 - side * rim * 0.6, e1 - side * rim * 0.6, e1 + side * rim * 0.6,
				e0 + side * rim * 0.6]), PackedColorArray([WARM, Color(WARM, 0.0), Color(WARM, 0.0), WARM]))
		draw_line(ridge_s, tip, CR_RIDGE, maxf(1.5, hw * 0.08), true)

	## The stone the crystals grow from: a heap of FACETED boulders (the crystals' own cut look, not round blobs), read as
	## one mass - every dark rim first, then each boulder's shaded body, its lit top facets and a crack or two.
	func _ledge() -> void:
		var bl := [Vector3(-0.8, 0.2, 0.42), Vector3(-0.42, 0.0, 0.62), Vector3(0.0, -0.15, 0.72), Vector3(0.44, 0.02, 0.6),
			Vector3(0.82, 0.22, 0.4)]
		var rim := ledge_half.y * 0.13
		var shapes: Array[PackedVector2Array] = []
		for bi in bl.size():
			var b: Vector3 = bl[bi]
			var c := ledge_c + Vector2(b.x * ledge_half.x, b.y * ledge_half.y)
			shapes.append(_rock(c, Vector2(b.z * ledge_half.x * 0.5, b.z * ledge_half.y * 1.25), 7 + bi % 3, bi))
		for sh in shapes:
			var cen := _centre(sh)
			var grown := PackedVector2Array()
			for p in sh:
				grown.append(p + (p - cen).normalized() * rim)
			draw_colored_polygon(grown, STONE_RIM)
			_aa_edge(grown, STONE_RIM)
		for bi in shapes.size():
			var sh := shapes[bi]
			var cen := _centre(sh)
			draw_colored_polygon(sh, STONE.darkened(0.18))
			# the upper facets catch the crystals' light: a fan from a point above the centre to every top edge
			var hub := cen + Vector2(-0.1, -0.35) * (sh[0] - cen).length()
			for k in sh.size():
				var a := sh[k]
				var b := sh[(k + 1) % sh.size()]
				var mid := (a + b) * 0.5 - cen
				if mid.y < 0.0:
					var lit := clampf(-mid.normalized().y, 0.0, 1.0)
					draw_colored_polygon(PackedVector2Array([hub, a, b]), STONE.lerp(STONE_TOP, 0.25 + 0.75 * lit))
				else:
					draw_colored_polygon(PackedVector2Array([hub, a, b]), STONE.darkened(0.08))
			# a crack across the face, and a teal glint where the crystals' light catches an edge
			var r0 := (sh[0] - cen).length()
			draw_polyline(PackedVector2Array([cen + Vector2(-0.45, -0.1) * r0, cen + Vector2(-0.1, 0.05) * r0,
				cen + Vector2(0.05, 0.4) * r0]), STONE_RIM, maxf(2.0, r0 * 0.05), true)
			draw_line(sh[sh.size() - 2].lerp(sh[sh.size() - 1], 0.3), sh[sh.size() - 1].lerp(sh[0], 0.6), Color(CR_LIGHT, 0.55),
				maxf(2.0, r0 * 0.04), true)

	## A faceted rock outline: `n` corners round `c`, each pulled in or out a little (fixed per `sd`).
	func _rock(c: Vector2, half: Vector2, n: int, sd: int) -> PackedVector2Array:
		var pts := PackedVector2Array()
		for k in n:
			var a := PI + TAU * float(k) / float(n) + 0.3 * float(sd)
			var j := 0.85 + 0.15 * sin(float(k) * 2.7 + float(sd) * 1.3)
			pts.append(c + Vector2(cos(a) * half.x, sin(a) * half.y) * j)
		return pts

	func _centre(pts: PackedVector2Array) -> Vector2:
		var s := Vector2.ZERO
		for p in pts:
			s += p
		return s / float(pts.size())
