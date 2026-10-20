extends RefCounted
## FEN'S TITLE SHAPES (TitleLettering, THE PLANET INTERFACE; builder BOLT-FEN intro, 2026-10-20). A DRAFT in the lead's
## picked direction (Zorp's mock-up M1: an emblem behind two-line lettering in the planet's own palette).
##
##   backdrop  THE CREST: the OLD ARCH (the ruin at the end of Fen's avenue, his vine in flower on it) framing the
##             LONG DUSK - a violet-to-amber sky and the low sun sitting on the horizon, never climbing - cut stone
##             courses on its legs and crown, two leaning standing stones of the colonnade either side (each with the
##             game's orange rope band), a soft amber glow behind and a band of low mist across the foot.
##   glyph     EVERY LETTER: the tall stroke font (TitleLettering's own glyph table) CARVED IN STONE, lit by a low sun
##             from the upper left - a soft amber glow round it (stamped, so no overlap fans), a deep violet extrude and
##             outline, a sandstone core with a CHISELLED V: a lit facet on the upper-left half and a shaded facet on the
##             lower-right half meeting at a ridge, then weathering - pits, pale chips and a fleck of moss. The O of
##             LONG holds a tiny sunset (an amber sun on a violet horizon), the way Zorp's T is a mushroom.
##             (Round 2, the critic: "near-monoline cream" letters, a stair-stepped crest, slabs like a doorway.)
##
## Every colour is Fen's own (fen.tres sun / ground / stone, fen_meshes.gd PETAL_A / PETAL_B / VINE / MOTH_WING),
## inside docs/STYLE_GUIDE.md: nothing over S 0.60, nothing whiter than V 0.92, no pure white. Called once at
## `TitleLettering.build`; baked into the atlas behind the black, never drawn live.

const M := preload("res://src/planet_safari/worlds/fen_meshes.gd")
const PX := TitleLettering.BUILD_CAP_PX
const STEP := 0.035

# The crest
const STONE := Color("#8c6a58")        # the arch's stone (S 0.37 V 0.55), its knitted brown in the frames
const STONE_LIT := Color("#b28a70")    # the side the low sun lights (S 0.37 V 0.70)
const STONE_SHADE := Color("#694c45")  # the shaded side (S 0.35 V 0.41)
const STONE_RIM := Color("#33283a")    # the dark rim round everything (S 0.31 V 0.23)
const SKY_TOP := Color("#3a3358")      # the dusk sky in the arch: violet (S 0.42 V 0.35)
const SKY_MID := Color("#8a5f7a")      # rose (S 0.31 V 0.54)
const SKY_LOW := Color("#d9946a")      # amber at the horizon (S 0.51 V 0.85)
const SUN := Color("#e6b977")          # fen.tres sun_color muted (S 0.48 V 0.90)
const SUN_GLOW := Color("#e8a060")     # its glow, used faint (S 0.59 V 0.91)
const HORIZON := Color("#4b3a4e")      # the far pan under the sun (S 0.24 V 0.31)

const ROPE := Color("#b8704f")         # the colonnade stones' orange rope band (S 0.57 V 0.72)
const ROPE_DARK := Color("#7e4a3a")    # its shadowed twist (S 0.54 V 0.49)
const MIST := Color("#b9aec4")         # the low mist (S 0.12 V 0.77), used faint

# The letters: sandstone, lit from the upper left
const SAND := Color("#c2a882")         # the core, in between the two facets (S 0.33 V 0.76)
const SAND_LIT := Color("#e4d4b2")     # the lit facet (S 0.22 V 0.89)
const SAND_SHADE := Color("#8f7556")   # the shaded facet (S 0.40 V 0.56)
const RIDGE := Color("#ead9b2")        # a thin catch-light along the lit facet's edge (S 0.24 V 0.92)
const PIT := Color("#8a7358")          # weathering pits (S 0.36 V 0.54)
const CHIP := Color("#eadcbc")         # pale chips (S 0.20 V 0.92)
const MOSS := Color("#7f8c6c")         # fen_meshes.gd MOSS (S 0.23 V 0.55)
const OUTLINE := Color("#2e2640")      # deep violet outline (S 0.41 V 0.25)
const EXTRUDE := Color("#4a3a5c")      # the extrude under it (S 0.37 V 0.36)
const GLOW := Color(0.91, 0.63, 0.38, 0.11)   # one stamp of the warm glow round the letters (they stack)


## THE STYLE lives in the world script (worlds/fen.gd `intro_title_style`), which names this file by PATH in
## "title_file" - never a preload, so a missing or broken title file only costs the shapes (TitleLettering falls back to
## plain lettering with one warning) and never the world script. Keys read here besides TitleLettering's own: "sun_at"
## (which letter is the sunset O). "halo" is not drawn (every glyph is replaced): it reserves room in each atlas cell.

# ======================================================================================== THE CREST
static func backdrop(block_size: Vector2, _style: Dictionary) -> Node2D:
	var n := _Crest.new()
	n.bs = block_size
	n.set_meta("size", Vector2(block_size.x * 1.02, block_size.y * 2.4))
	return n


class _Crest extends Node2D:
	var bs := Vector2(660, 242)
	## One ATLAS pixel in this node's own units (the bake scales it), so the antialiased edges are a real pixel wide.
	var _px := 1.0

	func _draw() -> void:
		_px = 1.0 / maxf(get_global_transform().get_scale().x, 0.05)
		var aw := bs.x * 0.25                 # the arch's outer half-width
		var t := aw * 0.30                    # its legs' thickness
		var iw := aw - t                      # the opening's half-width
		var top := -bs.y * 1.18               # the arch's outer crown
		var spring := top + aw                # where the round top meets the legs
		var foot := bs.y * 0.98               # the legs' foot
		var ground := bs.y * 0.80             # the horizon inside the opening
		# 1. The low sun's glow, wide and soft, behind everything.
		for k in 9:
			var s := 1.0 - 0.1 * float(k)
			_ellipse(Vector2(0.0, ground), Vector2(bs.x * 0.5, bs.y * 0.95) * s, Color(SUN_GLOW, 0.03))
		# 2. Two standing stones of the colonnade, leaning out, shorter than the arch and set back from it.
		for side in [-1.0, 1.0]:
			_menhir(Vector2(side * aw * 1.72, foot), bs.y * 1.25, aw * 0.24, side)
		# 3. The arch: rim, then the stone (lit left, shaded right), its cut courses, then the opening with the dusk.
		var rim := _arch_pts(aw + 5.0 * _px, spring, foot + 4.0 * _px, 40)
		_poly(rim, STONE_RIM)
		var outer := _arch_pts(aw, spring, foot, 40)
		var cols := PackedColorArray()
		for p in outer:
			cols.append(STONE_LIT.lerp(STONE_SHADE, clampf((p.x + aw) / (2.0 * aw), 0.0, 1.0)))
		_poly_cols(outer, cols)
		_courses(aw, iw, spring, foot)
		var orim := _arch_pts(iw + 4.0 * _px, spring, ground + 2.0 * _px, 32)
		_poly(orim, STONE_RIM)
		var opening := _arch_pts(iw, spring, ground, 32)
		var sky := PackedColorArray()
		for p in opening:
			var u := clampf((p.y - (spring - iw)) / (ground - (spring - iw)), 0.0, 1.0)
			sky.append(SKY_TOP.lerp(SKY_MID, smoothstep(0.0, 0.55, u)).lerp(SKY_LOW, smoothstep(0.5, 1.0, u)))
		_poly_cols(opening, sky)
		# the sun on the horizon (its top half), its own small glow, and the far pan under it
		var sc := Vector2(0.0, ground)
		var sr := iw * 0.5
		for k in 4:
			draw_circle(sc, sr * (1.9 - 0.2 * float(k)), Color(SUN_GLOW, 0.10), true, -1.0, true)
		draw_circle(sc, sr, SUN, true, -1.0, true)
		_poly(PackedVector2Array([Vector2(-iw, ground), Vector2(iw, ground), Vector2(iw, foot), Vector2(-iw, foot)]), HORIZON)
		# a lit edge round the arch's crown (the low sun catching it), then the vine in flower
		var crown := PackedVector2Array()
		for i in 25:
			var a := PI + PI * 0.55 * float(i) / 24.0
			crown.append(Vector2(cos(a) * (aw - t * 0.16), spring + sin(a) * (aw - t * 0.16)))
		draw_polyline(crown, Color(STONE_LIT.lightened(0.12), 0.8), t * 0.12, true)
		_vine(aw, t, spring)
		# 4. Low mist across the foot, in front of everything: wide, thin, faint.
		for k in 8:
			var s := 1.0 - 0.1 * float(k)
			_ellipse(Vector2(0.0, foot - bs.y * 0.02), Vector2(bs.x * 0.5, bs.y * 0.16) * s, Color(MIST, 0.06))

	## The arch outline: a half-circle crown on two straight legs, closed along the foot.
	func _arch_pts(hw: float, spring: float, foot: float, n: int) -> PackedVector2Array:
		var pts := PackedVector2Array()
		pts.append(Vector2(-hw, foot))
		for i in n + 1:
			var a := PI + PI * float(i) / float(n)
			pts.append(Vector2(cos(a) * hw, spring + sin(a) * hw))
		pts.append(Vector2(hw, foot))
		return pts

	## Cut stone: voussoir joints radiating round the crown and level courses down the legs, a dark groove with a
	## lighter lip under it (lit from above).
	func _courses(aw: float, iw: float, spring: float, foot: float) -> void:
		var groove := Color(STONE_RIM, 0.55)
		var lip := Color(STONE_LIT.lightened(0.08), 0.35)
		var w := maxf(1.6 * _px, (aw - iw) * 0.035)
		for i in range(1, 7):
			var a := PI + PI * float(i) / 7.0
			var d := Vector2(cos(a), sin(a))
			var p0 := Vector2(0.0, spring) + d * iw
			var p1 := Vector2(0.0, spring) + d * aw
			draw_line(p0, p1, groove, w, true)
			draw_line(p0 + Vector2(w, 0.0), p1 + Vector2(w, 0.0), lip, w * 0.7, true)
		var y := spring + (aw - iw) * 0.9
		var k := 0
		while y < foot - (aw - iw) * 0.4:
			for side in [-1.0, 1.0]:
				var x0: float = side * iw
				var x1: float = side * aw
				draw_line(Vector2(x0, y), Vector2(x1, y), groove, w, true)
				draw_line(Vector2(x0, y + w), Vector2(x1, y + w), lip, w * 0.7, true)
				# a vertical joint half-way along every other course (staggered blocks)
				if (k + int(side > 0.0)) % 2 == 0:
					var xm := (x0 + x1) * 0.5
					draw_line(Vector2(xm, y), Vector2(xm, y + (aw - iw) * 1.0), groove, w, true)
			y += (aw - iw) * 1.0
			k += 1

	## A standing stone: a slab that tapers to a broken, slanted top (high corner on the outside), with a narrow
	## shaded side face, cut-stone pits, and the colonnade's orange rope band round its middle.
	func _menhir(foot: Vector2, h: float, hw: float, side: float) -> void:
		var rot := deg_to_rad(side * 6.0)
		var o := side   # +1 = right stone: its outside is +x
		var front := PackedVector2Array([Vector2(-hw, 0.0), Vector2(-hw * 0.86, -h * (0.97 if o < 0.0 else 0.8)),
			Vector2(-hw * 0.3, -h * (0.9 if o < 0.0 else 0.84)), Vector2(hw * 0.2, -h * (0.92 if o > 0.0 else 0.82)),
			Vector2(hw * 0.84, -h * (1.0 if o > 0.0 else 0.78)), Vector2(hw, 0.0)])
		# the side face: a strip on the side away from the arch, a little darker
		var sx := hw * o
		var sidef := PackedVector2Array([Vector2(sx, 0.0), Vector2(sx * 0.84, -h * (1.0 if o > 0.0 else 0.97)),
			Vector2(sx * 1.25, -h * (0.95 if o > 0.0 else 0.92)), Vector2(sx * 1.32, 0.0)])
		var xf := func(p: Vector2) -> Vector2: return foot + p.rotated(rot)
		var rim := PackedVector2Array()
		var all_pts := front.duplicate()
		all_pts.append_array(sidef)
		var cen := Vector2(0.0, -h * 0.45)
		for p in _hull(all_pts):
			rim.append(xf.call(p + (p - cen).normalized() * 4.0 * _px))
		_poly(rim, STONE_RIM)
		var sp := PackedVector2Array()
		for p in sidef:
			sp.append(xf.call(p))
		_poly(sp, STONE_SHADE.darkened(0.12))
		var fp := PackedVector2Array()
		var cols := PackedColorArray()
		for p in front:
			fp.append(xf.call(p))
			var u := clampf(-p.y / h, 0.0, 1.0)
			cols.append(STONE_SHADE.lerp(STONE, u).lerp(STONE_LIT, clampf((-p.x * o) / hw, 0.0, 1.0) * 0.5 * u))
		_poly_cols(fp, cols)
		# the rope band
		var by := -h * 0.46
		var band := PackedVector2Array([xf.call(Vector2(-hw * 1.02, by - h * 0.035)),
			xf.call(Vector2(sx * 1.34 if o > 0.0 else hw * 1.02, by - h * 0.035)),
			xf.call(Vector2(sx * 1.34 if o > 0.0 else hw * 1.02, by + h * 0.035)), xf.call(Vector2(-hw * 1.02, by + h * 0.035))])
		if o < 0.0:
			band = PackedVector2Array([xf.call(Vector2(sx * 1.34, by - h * 0.035)), xf.call(Vector2(hw * 1.02, by - h * 0.035)),
				xf.call(Vector2(hw * 1.02, by + h * 0.035)), xf.call(Vector2(sx * 1.34, by + h * 0.035))])
		_poly(band, ROPE)
		for i in 7:
			var u := float(i) / 6.0
			var x := lerpf(-hw, hw, u)
			draw_line(xf.call(Vector2(x - h * 0.02, by - h * 0.03)), xf.call(Vector2(x + h * 0.02, by + h * 0.03)),
				ROPE_DARK, maxf(1.5 * _px, h * 0.012), true)
		# a few weathering pits on the front
		for q: Vector3 in [Vector3(-0.4, 0.22, 0.05), Vector3(0.3, 0.33, 0.04), Vector3(-0.1, 0.62, 0.045),
				Vector3(0.45, 0.72, 0.035), Vector3(-0.5, 0.8, 0.03)]:
			draw_circle(xf.call(Vector2(q.x * hw, -q.y * h)), q.z * hw * 2.0, Color(STONE_RIM, 0.35), true, -1.0, true)

	## Convex hull (monotone chain), for the menhir's dark rim.
	func _hull(pts: PackedVector2Array) -> PackedVector2Array:
		var a := Array(pts)
		a.sort_custom(func(p: Vector2, q: Vector2) -> bool: return p.x < q.x or (p.x == q.x and p.y < q.y))
		var lower: Array = []
		for p in a:
			while lower.size() >= 2 and (lower[-1] - lower[-2]).cross(p - lower[-2]) <= 0.0:
				lower.pop_back()
			lower.append(p)
		var upper: Array = []
		for i in range(a.size() - 1, -1, -1):
			var p: Vector2 = a[i]
			while upper.size() >= 2 and (upper[-1] - upper[-2]).cross(p - upper[-2]) <= 0.0:
				upper.pop_back()
			upper.append(p)
		lower.pop_back()
		upper.pop_back()
		return PackedVector2Array(lower + upper)

	## Fen's vine up the arch's left side and over the crown, with his flowers (PETAL_A / PETAL_B).
	func _vine(aw: float, t: float, spring: float) -> void:
		var path := PackedVector2Array()
		var r := aw - t * 0.5
		for i in 25:
			var a := PI * 0.98 + PI * 0.62 * float(i) / 24.0
			var wig := sin(float(i) * 1.3) * t * 0.12
			path.append(Vector2(cos(a) * (r + wig), spring + sin(a) * (r + wig)))
		draw_polyline(path, STONE_RIM, t * 0.14, true)
		draw_polyline(path, M.VINE, t * 0.09, true)
		for i in [2, 6, 9, 13, 17, 21]:
			var p: Vector2 = path[i]
			_flower(p, t * (0.17 if i % 2 == 0 else 0.14), M.PETAL_A if i % 3 == 0 else M.PETAL_B)
		for i in [4, 11, 15, 19]:
			var p: Vector2 = path[i]
			draw_circle(p + Vector2(t * 0.1, -t * 0.06), t * 0.07, M.LEAF, true, -1.0, true)

	func _flower(c: Vector2, r: float, col: Color) -> void:
		for k in 5:
			var a := TAU * float(k) / 5.0 - PI * 0.5
			var p := c + Vector2(cos(a), sin(a)) * r * 0.62
			draw_circle(p, r * 0.52, STONE_RIM, true, -1.0, true)
		for k in 5:
			var a := TAU * float(k) / 5.0 - PI * 0.5
			draw_circle(c + Vector2(cos(a), sin(a)) * r * 0.62, r * 0.42, col, true, -1.0, true)
		draw_circle(c, r * 0.3, M.FLOWER_EYE, true, -1.0, true)

	func _ellipse(c: Vector2, half: Vector2, col: Color) -> void:
		var pts := PackedVector2Array()
		for i in 64:
			var a := TAU * float(i) / 64.0
			pts.append(c + Vector2(cos(a) * half.x, sin(a) * half.y))
		draw_colored_polygon(pts, col)

	## A solid polygon with an ANTIALIASED edge one atlas pixel wide (draw_colored_polygon alone is aliased: the
	## critic saw the arch stair-step ~2 px then blur at phone size).
	func _poly(pts: PackedVector2Array, col: Color) -> void:
		draw_colored_polygon(pts, col)
		var l := pts.duplicate()
		l.append(pts[0])
		draw_polyline(l, col, 1.2 * _px, true)

	func _poly_cols(pts: PackedVector2Array, cols: PackedColorArray) -> void:
		draw_polygon(pts, cols)
		var l := pts.duplicate()
		l.append(pts[0])
		var lc := cols.duplicate()
		lc.append(cols[0])
		draw_polyline_colors(l, lc, 1.2 * _px, true)


# ======================================================================================== THE LETTERS
static func glyph(ch: String, index: int, style: Dictionary) -> Node2D:
	TitleLettering._ensure_tables()
	var table: Dictionary = TitleLettering._glyphs
	if not table.has(ch):
		return null
	var g: Dictionary = table[ch]
	var w := float(g["w"])
	var slant := float(style.get("slant", 0.0))
	var root := Node2D.new()
	var stroke := float(style.get("stroke", 0.17))
	var outline := float(style.get("outline", 0.045))
	var lines: Array[PackedVector2Array] = []
	for s: PackedVector2Array in g["strokes"]:
		var pts := PackedVector2Array()
		for p in _dense(s):
			pts.append(Vector2(p.x - w * 0.5 + slant * p.y, -p.y) * PX)
		lines.append(pts)
	var sun := ch == "O" and index == int(style.get("sun_at", -1))
	# 1. the warm glow, stamped along every stroke
	var gl := _Stamps.new()
	gl.lines = lines
	gl.offset = Vector2(0.0, 0.03) * PX
	gl.radius = (stroke * 0.5 + outline + 0.13) * PX
	gl.col = GLOW
	root.add_child(gl)
	# 0. the O of LONG: a tiny sunset inside the ring (over the glow, under the ring's strokes)
	if sun:
		var ss := _Sunset.new()
		ss.c = Vector2(0.33 - w * 0.5 + slant * 0.5, -0.5) * PX
		ss.r = Vector2(0.31, 0.5) * PX
		root.add_child(ss)
	# 2. extrude, 3. outline, 4. the sandstone core
	for pts in lines:
		_line(root, _shift(pts, Vector2(0.025, 0.05) * PX), (stroke + outline * 2.0) * PX, EXTRUDE)
	for pts in lines:
		_line(root, pts, (stroke + outline * 2.0) * PX, OUTLINE)
	for pts in lines:
		_line(root, pts, stroke * PX, SAND_LIT)
	# 5. THE CHISELLED V (cut into the stone, lit from the upper left): the lit upper-left wall is the core; the shaded
	# lower-right wall is a narrower stroke pushed toward the lower right; a dark crease runs down the bottom of the V
	# just off the centre line, with a thin catch-light on its lit side. Every round end stays inside the core's
	# (offset + radius < half the stroke). The first draft's facets were too faint to read at phone size (the critic:
	# "near-monoline cream").
	var d := Vector2(1.0, 1.0).normalized() * stroke * PX
	for pts in lines:
		_line(root, _shift(pts, d * 0.2), stroke * 0.56 * PX, SAND_SHADE)
	for pts in lines:
		_line(root, _shift(pts, d * 0.02), stroke * 0.13 * PX, PIT.darkened(0.25))
	for pts in lines:
		_line(root, _shift(pts, -d * 0.1), stroke * 0.07 * PX, RIDGE)
	# 6. weathering: pits, pale chips, a fleck of moss low on some letters - fixed per letter (its index), not random
	var wx := _Weather.new()
	var h := float(index) * 12.9898
	var n := 0
	for li in lines.size():
		var pts: PackedVector2Array = lines[li]
		for i in range(2, pts.size() - 2, 5):
			h = fmod(h * 1.37 + 7.31 + float(i) * 0.618, 97.0)
			var r := fmod(h, 1.0)
			if r > 0.26:
				continue
			var tng := (pts[i + 1] - pts[i - 1]).normalized()
			var nrm := Vector2(-tng.y, tng.x)
			var off := (fmod(h * 3.1, 1.0) - 0.5) * stroke * 0.55 * PX
			var at := pts[i] + nrm * off
			var kind := 0 if r < 0.12 else (1 if r < 0.22 else 2)
			if kind == 2 and -pts[i].y > 0.3 * PX:
				kind = 0
			wx.marks.append(Vector3(at.x, at.y, float(kind)))
			wx.sizes.append(stroke * PX * (0.045 + 0.05 * fmod(h * 7.7, 1.0)))
			n += 1
	root.add_child(wx)
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
		var k := maxi(1, int(ceil(a.distance_to(b) / STEP)))
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


## Weathering marks on a carved letter: 0 = a pit (dark, a light lip below it), 1 = a pale chip, 2 = a fleck of moss.
class _Weather extends Node2D:
	var marks := PackedVector3Array()
	var sizes := PackedFloat32Array()

	func _draw() -> void:
		for i in marks.size():
			var p := Vector2(marks[i].x, marks[i].y)
			var r := sizes[i]
			match int(marks[i].z):
				0:
					draw_circle(p + Vector2(0.0, r * 0.35), r, Color(CHIP, 0.35), true, -1.0, true)
					draw_circle(p, r, Color(PIT, 0.85), true, -1.0, true)
				1:
					draw_circle(p, r * 0.8, Color(CHIP, 0.9), true, -1.0, true)
				_:
					draw_circle(p, r * 1.2, Color(MOSS, 0.9), true, -1.0, true)
					draw_circle(p + Vector2(r, -r * 0.3), r * 0.8, Color(MOSS.lightened(0.12), 0.9), true, -1.0, true)


## A soft band along each line: the shared soft dot stamped every few pixels (see bolt_title.gd `_Stamps`).
class _Stamps extends Node2D:
	var lines: Array[PackedVector2Array] = []
	var offset := Vector2.ZERO
	var radius := 20.0
	var col := Color(1, 1, 1, 0.2)

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


## The sunset inside the O: an amber sun half-sunk on a violet horizon, filling the ring's inside.
class _Sunset extends Node2D:
	var c := Vector2.ZERO
	var r := Vector2(31, 50)

	func _draw() -> void:
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		for i in 40:
			var a := TAU * float(i) / 40.0
			var p := c + Vector2(cos(a) * r.x, sin(a) * r.y)
			pts.append(p)
			var u := clampf((p.y - (c.y - r.y)) / (2.0 * r.y), 0.0, 1.0)
			cols.append(SKY_TOP.lerp(SKY_MID, smoothstep(0.0, 0.6, u)).lerp(SKY_LOW, smoothstep(0.55, 0.9, u)))
		draw_polygon(pts, cols)
		var hy := c.y + r.y * 0.38
		draw_circle(Vector2(c.x, hy), r.x * 0.62, SUN, true, -1.0, true)
		# the horizon: the ring's lower part below hy, in the far pan's violet
		var low := PackedVector2Array()
		for i in 21:
			var a := asin(clampf((hy - c.y) / r.y, -1.0, 1.0)) + (PI - 2.0 * asin(clampf((hy - c.y) / r.y, -1.0, 1.0))) * float(i) / 20.0
			low.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
		draw_colored_polygon(low, HORIZON)
