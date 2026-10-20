extends RefCounted
## THE TANGLE'S TITLE SHAPES (a DRAFT, builder JUNGLE+METEOR intro, 2026-10-20, polish round; TitleLettering, THE PLANET
## INTERFACE). The lead's pick direction is Zorp's mock-up M1 "crest": an EMBLEM behind two-line lettering in the planet's
## own palette. The Tangle's emblem is a turquoise LILY PAD (its notch, its veins, a lit rim) caught in a TANGLE: an
## indigo root and a turquoise moss vine BRAIDED round its top - twisting over and under each other, thick in the middle
## and tapering to fine ends, crossing in front of the pad at its shoulders - with coral leaves sprouting off them, teal
## glow beads at the crossings and thin roots hanging from both ends. (Round 1 had a fan of pointed leaves: the critic
## read it as a flower or a crown, flat and sticker-like, with stair-stepped curved edges. A first try at loose vines read
## as pipes, and tendril curls at the sides read as letters.) Each vine is a tapered ribbon, shaded: a dark outline, the
## body, a shade along the side away from the light and a lit stripe along the side toward it, all antialiased, so the
## curves stay smooth when baked; the pad's edge is an antialiased line too. Every colour is the Tangle's own
## (jungle_props.gd L1 LOOK: wine, turquoise, gold, indigo - no green); the big areas stay under S 0.60
## (docs/STYLE_GUIDE.md), only the beads are saturated, and they are small.
## The letters are M1's (TitleMockups._letters): a soft shadow, a dark outline, the body, a lit top edge - in amber-gold
## with a cream lit edge and a deep-teal outline. Every letter is replaced through `glyph` (so none falls back to Baloo).
## Called once at `build`, baked once behind the black: nothing here runs per frame.

const Shapes := preload("res://src/planet_safari/title_mockups.gd")
const PX := TitleLettering.BUILD_CAP_PX

const PAD := Color("#3f7f7e")          # deep turquoise (S 0.50 V 0.50), the pools' and parasols' family
const PAD_LIGHT := Color("#6aa8a0")    # its lit top (jungle_props PARASOL_LIGHT, a step down)
const PAD_VEIN := Color("#8cc0b4")
const INK := Color("#22283c")          # the deep indigo of the Tangle's trunks, darkened: every outline
const ROOT := Color("#5f5a7c")         # trunk indigo (jungle.tres trunk_color 0.40 0.38 0.50, a step lighter)
const ROOT_LIT := Color("#9590b0")
const ROOT_SHADE := Color("#3c3854")
const MOSS := Color("#4f8f8c")         # turquoise moss vine (BROAD_COLS[1])
const MOSS_LIT := Color("#86bdb2")
const MOSS_SHADE := Color("#33605e")
const LEAF := Color("#a8605c")         # coral leaf (BROAD_COLS[2])
const LEAF_TIP := Color("#c88478")
const BEAD := Color("#14c8a6")         # GLOW_TEAL (tiny)
const AMBER := Color("#e6a24a")        # GLOW_AMBER, softened (tiny)

## THE BRAID: round an ellipse this many pad radii out, from BRAID_A0 to BRAID_A1 degrees (screen angles, y down: 270 is
## straight up), TWISTS crossings, the two vines AMP pad radii either side of it, WIDTH thick at the middle.
const BRAID_R := Vector2(1.13, 1.2)
const BRAID_A0 := 160.0
const BRAID_A1 := 380.0
const TWISTS := 3.5
const AMP := 0.075
const WIDTH := 0.095
const SAMPLES := 140
## Coral leaves along the braid: [u 0..1 along it, vine 0/1, size]. Beads sit on the crossings.
const LEAVES := [[0.07, 0, 0.8], [0.2, 1, 0.95], [0.33, 0, 1.0], [0.46, 1, 0.9], [0.6, 0, 1.0], [0.74, 1, 0.95],
	[0.88, 0, 0.85], [0.95, 1, 0.7]]


## The crest behind the letters, centred on the block. `size` meta = its whole extent round that centre.
static func backdrop(block_size: Vector2, _style: Dictionary) -> Node2D:
	var c := _Crest.new()
	c.bs = block_size
	var rx := block_size.x * 0.56
	var ry := block_size.y * 0.62
	c.set_meta("size", Vector2(rx * 2.0 * 1.62, ry * 2.0 * 1.42))
	return c


## Every letter in M1's layered look (shadow, outline, body, lit top edge), the Tangle's colours.
static func glyph(ch: String, _index: int, style: Dictionary) -> Node2D:
	TitleLettering._ensure_tables()
	if not TitleLettering._glyphs.has(ch):
		return null
	var root := Node2D.new()
	root.add_child(Shapes._letters({"glyphs": [[ch, Vector2.ZERO]]}, {
		"core_top": style.get("core_top", Color("#f2e2b6")), "core": style.get("core", Color("#e6c27a")),
		"outline": style.get("outline_col", INK), "shadow": style.get("shadow_col", Color(INK, 0.5)),
		"stroke": float(style.get("stroke", 0.17)), "outline_w": float(style.get("outline", 0.05)),
		"slant": float(style.get("slant", 0.0)), "wobble": float(style.get("wobble", 0.0))}))
	return root


class _Crest extends Node2D:
	var bs := Vector2(440, 250)
	var _c := Vector2.ZERO
	var _rx := 1.0
	var _ry := 1.0
	var _mid := PackedVector2Array()    # the braid's centre line
	var _out := PackedVector2Array()    # its outward unit normal at each sample
	var _vines: Array = [PackedVector2Array(), PackedVector2Array()]
	var _w := PackedFloat32Array()      # vine width at each sample

	func _draw() -> void:
		_rx = bs.x * 0.56
		_ry = bs.y * 0.62
		_c = Vector2(0.0, bs.y * 0.04)
		_build_braid()
		# A soft shadow under the whole emblem (three shrinking ellipses), so it sits on the scene, not on it.
		for k in 3:
			var s := 1.24 - 0.09 * float(k)
			_ellipse(_c + Vector2(0.0, _ry * 0.1), Vector2(_rx * s, _ry * s * 1.06), Color(INK, 0.15))
		# Hanging roots from both ends, then the braid behind the pad (with its over/under), its leaves.
		_hanging(0)
		_hanging(SAMPLES)
		_braid(0, SAMPLES)
		for l: Array in LEAVES:
			_leaf_on(l)
		# The lily pad: a notched disc with a vertical light (lit top, deeper foot), its veins, a lit rim.
		var pad := _pad_points(_c, _rx, _ry)
		var outer := _pad_points(_c, _rx * 1.045, _ry * 1.06)
		draw_colored_polygon(outer, INK)
		var cols := PackedColorArray()
		for p in pad:
			var t := clampf((p.y - (_c.y - _ry)) / (2.0 * _ry), 0.0, 1.0)
			cols.append(PAD_LIGHT.lerp(PAD, smoothstep(0.1, 0.85, t)))
		draw_polygon(pad, cols)
		var apex := pad[0]
		for i in 11:
			var a3 := deg_to_rad(-60.0 - 25.0 * float(i))
			var e := _c + Vector2(cos(a3) * _rx * 0.9, sin(a3) * _ry * 0.9)
			draw_line(apex, e, Color(PAD_VEIN, 0.3), maxf(2.0, _rx * 0.012), true)
		var rim := PackedVector2Array()
		for i in 25:
			var a4 := deg_to_rad(lerpf(196.0, 344.0, float(i) / 24.0))
			rim.append(_c + Vector2(cos(a4) * _rx * 0.93, sin(a4) * _ry * 0.9))
		draw_polyline(rim, Color(PAD_VEIN, 0.75), maxf(2.0, _rx * 0.022), true)
		var foot := PackedVector2Array()
		for i in 17:
			var a5 := deg_to_rad(lerpf(95.0, 160.0, float(i) / 16.0))
			foot.append(_c + Vector2(cos(a5) * _rx * 0.94, sin(a5) * _ry * 0.92))
		draw_polyline(foot, Color(INK, 0.45), maxf(2.0, _rx * 0.03), true)
		var edge := outer.duplicate()
		edge.append(outer[0])
		draw_polyline(edge, INK, maxf(2.0, _rx * 0.016), true)
		# The braid passes IN FRONT of the pad at its two shoulders (clear of the first line's letters).
		_braid(int(SAMPLES * 0.12), int(SAMPLES * 0.3))
		_braid(int(SAMPLES * 0.7), int(SAMPLES * 0.88))
		for l: Array in LEAVES:
			var u := float(l[0])
			if (u > 0.12 and u < 0.3) or (u > 0.7 and u < 0.88):
				_leaf_on(l)
		# Teal glow beads on the crossings, two amber glints on the pad.
		for k in int(TWISTS * 2.0) + 1:
			var i := int(round(float(k) / (TWISTS * 2.0) * float(SAMPLES)))
			if i <= 4 or i >= SAMPLES - 4:
				continue
			var at := _mid[i]
			var r := _rx * 0.028
			draw_circle(at, r * 2.6, Color(BEAD, 0.2), true, -1.0, true)
			draw_circle(at, r * 1.35, INK, true, -1.0, true)
			draw_circle(at, r, BEAD.lerp(Color("#bfeee2"), 0.25), true, -1.0, true)
		for b2: Vector2 in [Vector2(-0.62, 0.55), Vector2(0.66, 0.5)]:
			var at2 := _c + Vector2(b2.x * _rx, b2.y * _ry)
			draw_circle(at2, _rx * 0.06, Color(AMBER, 0.2), true, -1.0, true)
			draw_circle(at2, _rx * 0.022, AMBER, true, -1.0, true)

	## The braid's centre line, normals, the two vines (opposite sine offsets) and the taper.
	func _build_braid() -> void:
		_mid.clear()
		_out.clear()
		_w.clear()
		_vines = [PackedVector2Array(), PackedVector2Array()]
		for i in SAMPLES + 1:
			var u := float(i) / float(SAMPLES)
			var a := deg_to_rad(lerpf(BRAID_A0, BRAID_A1, u))
			var p := _c + Vector2(cos(a) * _rx * BRAID_R.x, sin(a) * _ry * BRAID_R.y)
			var nrm := Vector2(cos(a) / BRAID_R.x, sin(a) / BRAID_R.y).normalized()
			_mid.append(p)
			_out.append(nrm)
			var off := sin(TAU * TWISTS * u) * AMP * _rx
			_vines[0].append(p + nrm * off)
			_vines[1].append(p - nrm * off)
			_w.append(WIDTH * _rx * (0.45 + 0.55 * pow(sin(PI * u), 0.7)))

	## Samples i0..i1 of the braid: both vines, the one that is UNDER first (by the twist's phase, per piece).
	func _braid(i0: int, i1: int) -> void:
		var start := i0
		var i := i0 + 1
		while i <= i1:
			var u0 := float(start) / float(SAMPLES)
			var u := float(i) / float(SAMPLES)
			var over0 := cos(TAU * TWISTS * u0) > 0.0
			var over := cos(TAU * TWISTS * u) > 0.0
			if over != over0 or i == i1:
				var top := 0 if over0 else 1
				_ribbon(1 - top, start, i)
				_ribbon(top, start, i)
				start = i
			i += 1

	## Vine `v` (0 the indigo root, 1 the moss) from sample i0 to i1 as a shaded, tapered ribbon: an outline, the body, a
	## shade along the side away from the light, a lit stripe along the side toward it (the light comes from the upper left).
	## Each layer is drawn as one quad a sample step (a long strip polygon can fold on itself and fail to triangulate).
	func _ribbon(v: int, i0: int, i1: int) -> void:
		if i1 - i0 < 1:
			return
		var pts: PackedVector2Array = _vines[v]
		var body: Color = ROOT if v == 0 else MOSS
		var lit: Color = ROOT_LIT if v == 0 else MOSS_LIT
		var shade: Color = ROOT_SHADE if v == 0 else MOSS_SHADE
		var a0 := maxi(i0 - 1, 0)
		var a1 := mini(i1 + 1, SAMPLES)
		var o := maxf(2.0, _rx * 0.012)
		_layer(pts, a0, a1, 1.0, 0.0, o, INK)
		_layer(pts, a0, a1, 1.0, 0.0, 0.0, body)
		_layer(pts, a0, a1, 0.42, 0.26, 0.0, shade)
		_layer(pts, a0, a1, 0.22, -0.27, 0.0, lit)
		var l_edge := PackedVector2Array()
		var r_edge := PackedVector2Array()
		for i in range(a0, a1 + 1):
			var nv := _normal(pts, i)
			l_edge.append(pts[i] - nv * (_w[i] * 0.5 + o))
			r_edge.append(pts[i] + nv * (_w[i] * 0.5 + o))
		draw_polyline(l_edge, INK, maxf(1.2, _rx * 0.006), true)
		draw_polyline(r_edge, INK, maxf(1.2, _rx * 0.006), true)

	func _normal(pts: PackedVector2Array, i: int) -> Vector2:
		var tv := (pts[mini(i + 1, SAMPLES)] - pts[maxi(i - 1, 0)]).normalized()
		return Vector2(-tv.y, tv.x)

	## One layer along `pts` (samples a0..a1): `k` of the vine's width, its centre moved `shift` widths away from the
	## light, `grow` pixels added each side, as quads.
	func _layer(pts: PackedVector2Array, a0: int, a1: int, k: float, shift: float, grow: float, col: Color) -> void:
		var prev_l := Vector2.ZERO
		var prev_r := Vector2.ZERO
		for i in range(a0, a1 + 1):
			var nv := _normal(pts, i)
			var away := 1.0 if nv.dot(Vector2(0.4, 1.0)) >= 0.0 else -1.0
			var half := _w[i] * 0.5 * k + grow
			var cen := pts[i] + nv * away * _w[i] * shift
			var l := cen - nv * half
			var r := cen + nv * half
			if i > a0:
				draw_colored_polygon(PackedVector2Array([prev_l, l, r, prev_r]), col)
			prev_l = l
			prev_r = r

	## A thin root hanging from braid end sample `i`: a tapered, slightly waving ribbon, down and outward.
	func _hanging(i: int) -> void:
		var side := -1.0 if i == 0 else 1.0
		for r in 2:
			var start: Vector2 = _vines[r][i]
			var pts := PackedVector2Array()
			var ws := PackedFloat32Array()
			var n := 16
			var length := _ry * (0.42 if r == 0 else 0.3)
			for j in n + 1:
				var t := float(j) / float(n)
				pts.append(start + Vector2(side * (_rx * 0.05 * t + sin(t * 5.0 + float(r)) * _rx * 0.018), length * t))
				ws.append(_w[i] * (1.0 - 0.85 * t))
			var poly := PackedVector2Array()
			var back := PackedVector2Array()
			for j in n + 1:
				var tv := (pts[mini(j + 1, n)] - pts[maxi(j - 1, 0)]).normalized()
				var nv := Vector2(-tv.y, tv.x)
				poly.append(pts[j] + nv * (ws[j] * 0.5 + 1.5))
				back.append(pts[j] - nv * (ws[j] * 0.5 + 1.5))
			back.reverse()
			poly.append_array(back)
			draw_colored_polygon(poly, INK)
			for j in n:
				draw_line(pts[j], pts[j + 1], ROOT if r == 0 else MOSS, maxf(1.0, ws[j] - 1.0), true)

	## A coral leaf off the braid at `l[0]` of its length, on vine `l[1]`, pointing outward: outline, a body lit toward
	## the tip, a midrib.
	func _leaf_on(l: Array) -> void:
		var i := int(float(l[0]) * float(SAMPLES))
		var at: Vector2 = _vines[int(l[1])][i]
		var tv := (_mid[mini(i + 1, SAMPLES)] - _mid[maxi(i - 1, 0)]).normalized()
		var size := _rx * 0.2 * float(l[2])
		var axis := (_out[i] * 0.9 + tv * 0.45).normalized() * size
		var side := Vector2(-axis.y, axis.x).normalized()
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		var m := 12
		for j in m + 1:
			var t := float(j) / float(m)
			pts.append(at + axis * t + side * size * 0.32 * pow(sin(PI * t), 0.8) * (1.0 - 0.3 * t))
			cols.append(LEAF_TIP.lerp(LEAF, 0.35).lerp(LEAF_TIP, t))
		for j in range(m - 1, 0, -1):
			var t := float(j) / float(m)
			pts.append(at + axis * t - side * size * 0.32 * pow(sin(PI * t), 0.8) * (1.0 - 0.3 * t))
			cols.append(LEAF.darkened(0.18).lerp(LEAF, t))
		draw_polygon(pts, cols)
		var loop := pts.duplicate()
		loop.append(pts[0])
		draw_polyline(loop, INK, maxf(1.5, size * 0.07), true)
		draw_line(at + axis * 0.08, at + axis * 0.85, Color(LEAF_TIP.lightened(0.2), 0.7), maxf(1.2, size * 0.05), true)

	## A notched disc: the rim all round except a wedge cut to near the centre (lower right).
	func _pad_points(c: Vector2, rx: float, ry: float) -> PackedVector2Array:
		var pts := PackedVector2Array()
		pts.append(c + Vector2(rx * 0.06, ry * 0.08))
		for i in 61:
			var a := deg_to_rad(lerpf(77.0, 391.0, float(i) / 60.0))
			pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
		return pts

	func _ellipse(c: Vector2, half: Vector2, col: Color) -> void:
		var pts := PackedVector2Array()
		for i in 48:
			var a := TAU * float(i) / 48.0
			pts.append(c + Vector2(cos(a) * half.x, sin(a) * half.y))
		draw_colored_polygon(pts, col)
