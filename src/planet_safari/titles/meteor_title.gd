extends RefCounted
## THE METEOR'S TITLE SHAPES (a DRAFT, builder JUNGLE+METEOR intro, 2026-10-20, polish round; TitleLettering, THE PLANET
## INTERFACE). The lead's pick direction (Zorp's M1 "crest"): an EMBLEM behind two-line lettering. The Meteor's emblem is
## the rock itself, falling: a big faceted charcoal boulder that holds BOTH lines inside it (round 1's was smaller than the
## words and "THE" stuck out above it - the critic: "plain"), bevelled - a lit top face and a lit top edge, a shaded foot,
## a few pocked craters - split by three lava seams that glow hot (a wide warm haze, the molten line, a white-hot core,
## brighter pools where they meet), with a clear gold falling-star trail streaming up and away behind it and embers off
## the trail. Colours are the survey's own (meteor_props.gd SHARD_ROCK, WARM, MOLTEN, BEACON); the big areas stay under
## S 0.60 (docs/STYLE_GUIDE.md), only the seams' hot cores are saturated, and they are thin. Edges are antialiased lines.
## The letters are M1's (TitleMockups._letters): an ember underglow, a charcoal outline, an ember-gold body, a cream-gold
## lit top edge. Every letter is replaced through `glyph` (none falls back to Baloo). Built once at `build`, baked once.

const Shapes := preload("res://src/planet_safari/title_mockups.gd")

const ROCK_TOP := Color("#655c72")     # SHARD_ROCK lit (S 0.19)
const ROCK := Color("#3d3647")
const ROCK_FOOT := Color("#221e29")
const CHAR := Color("#16131a")         # charcoal: every outline
const FACET := Color("#9a90a8")        # the lit edge
const SEAM_GLOW := Color("#ff8a3d")    # MeteorProps.WARM (thin, small)
const SEAM := Color("#ffb46a")         # MeteorProps.MOLTEN
const SEAM_HOT := Color("#ffe8c0")
const STREAK := Color("#efc77c")       # gold (S 0.48)
const EMBER := Color("#e0763a")

## The rock's outline: radius factors round it, from straight up clockwise (fixed: no random numbers).
const JIT := [1.0, 0.9, 1.06, 0.97, 0.92, 1.08, 0.95, 1.03, 0.88, 1.05, 0.98, 0.91, 1.07, 0.94, 1.02, 0.89, 1.04, 0.96]
## The seams, in rock radii from its centre (x right, y down).
const SEAMS := [
	[Vector2(-0.98, -0.22), Vector2(-0.62, -0.08), Vector2(-0.44, 0.2), Vector2(-0.06, 0.3), Vector2(0.18, 0.6),
		Vector2(0.3, 0.94)],
	[Vector2(0.1, -0.95), Vector2(0.22, -0.58), Vector2(0.48, -0.4), Vector2(0.56, -0.06), Vector2(0.95, 0.12)],
	[Vector2(-0.44, 0.2), Vector2(-0.66, 0.5), Vector2(-0.58, 0.84)],
]
const CRATERS := [Vector3(-0.62, -0.5, 0.09), Vector3(0.7, -0.5, 0.07), Vector3(-0.78, 0.42, 0.06), Vector3(0.66, 0.55, 0.08),
	Vector3(-0.2, -0.78, 0.05)]


static func backdrop(block_size: Vector2, _style: Dictionary) -> Node2D:
	var c := _Crest.new()
	c.bs = block_size
	var rx := block_size.x * 0.64
	var ry := block_size.y * 0.86
	# The trail reaches up and right of the rock: the extent covers it (a box centred on the block).
	c.set_meta("size", Vector2(rx * 2.0 * 1.62, ry * 2.0 * 1.72))
	return c


static func glyph(ch: String, _index: int, style: Dictionary) -> Node2D:
	TitleLettering._ensure_tables()
	if not TitleLettering._glyphs.has(ch):
		return null
	var root := Node2D.new()
	root.add_child(Shapes._letters({"glyphs": [[ch, Vector2.ZERO]]}, {
		"core_top": style.get("core_top", Color("#f3d79c")), "core": style.get("core", Color("#dc9a5e")),
		"outline": style.get("outline_col", CHAR), "shadow": style.get("shadow_col", Color(EMBER, 0.45)),
		"stroke": float(style.get("stroke", 0.17)), "outline_w": float(style.get("outline", 0.05)),
		"slant": float(style.get("slant", 0.0)), "wobble": float(style.get("wobble", 0.0))}))
	return root


class _Crest extends Node2D:
	var bs := Vector2(440, 250)

	func _draw() -> void:
		var rx := bs.x * 0.64
		var ry := bs.y * 0.86
		var c := Vector2(0.0, bs.y * 0.04)
		var pts := PackedVector2Array()
		var n := JIT.size()
		for i in n:
			var a := TAU * float(i) / float(n) - PI * 0.5
			pts.append(c + Vector2(cos(a) * rx, sin(a) * ry) * float(JIT[i]))
		# The falling-star trail, behind everything: three tapered gold streaks from the rock's upper right, up and away.
		var up := Vector2(0.8, -0.6).normalized()
		var side := Vector2(-up.y, up.x)
		for s: Vector3 in [Vector3(0.0, 1.0, 1.0), Vector3(-0.38, 0.78, 0.7), Vector3(0.36, 0.66, 0.6)]:
			var root := c + Vector2(up.x * rx, up.y * ry) * 0.62 + side * ry * s.x
			_streak(root, root + up * rx * 1.05 * s.y, ry * 0.26 * s.z)
		# The ember glow under the rock.
		for k in 3:
			var g := 1.12 - 0.09 * float(k)
			_ellipse(c + Vector2(0.0, ry * 0.3), Vector2(rx * g, ry * 0.8 * g), Color(EMBER, 0.08))
		# The rock: outline, a body lit top to dark foot, a lit top FACE (a bevel), facets, craters.
		var outer := PackedVector2Array()
		for p in pts:
			outer.append(c + (p - c) * 1.04)
		draw_colored_polygon(outer, CHAR)
		var cols := PackedColorArray()
		for p in pts:
			var t := clampf((p.y - (c.y - ry)) / (2.0 * ry), 0.0, 1.0)
			cols.append(ROCK_TOP.lerp(ROCK, smoothstep(0.0, 0.55, t)).lerp(ROCK_FOOT, smoothstep(0.55, 1.0, t)))
		draw_polygon(pts, cols)
		var bevel := PackedVector2Array()
		var bcols := PackedColorArray()
		for p in pts:
			var q := c + (p - c) * 0.86 + Vector2(0.0, ry * 0.07)
			bevel.append(q)
			var t2 := clampf((q.y - (c.y - ry)) / (2.0 * ry), 0.0, 1.0)
			bcols.append(Color(FACET, 0.22 * (1.0 - smoothstep(0.1, 0.6, t2))))
		draw_polygon(bevel, bcols)
		var inner := c + Vector2(-rx * 0.1, -ry * 0.16)
		for i in [1, 5, 10, 14]:
			draw_line(inner.lerp(pts[i], 0.35), pts[i], Color(CHAR, 0.5), maxf(1.5, rx * 0.01), true)
		for cr: Vector3 in CRATERS:
			var at := c + Vector2(cr.x * rx, cr.y * ry)
			var r := cr.z * rx
			_ellipse(at, Vector2(r, r * 0.62), Color(ROCK_FOOT, 0.7))
			var arc := PackedVector2Array()
			for j in 13:
				var a2 := lerpf(0.15, PI - 0.15, float(j) / 12.0)
				arc.append(at + Vector2(cos(a2) * r, sin(a2) * r * 0.62))
			draw_polyline(arc, Color(FACET, 0.55), maxf(1.5, r * 0.18), true)
		# The lit top edge and the shaded foot.
		var lit := PackedVector2Array()
		for i in [n - 4, n - 3, n - 2, n - 1, 0, 1, 2, 3]:
			lit.append(c + (pts[i] - c) * 0.975)
		draw_polyline(lit, Color(FACET, 0.9), maxf(2.0, rx * 0.028), true)
		var foot := PackedVector2Array()
		for i in range(6, 13):
			foot.append(c + (pts[i] - c) * 0.965)
		draw_polyline(foot, Color(CHAR, 0.6), maxf(2.0, rx * 0.035), true)
		var edge := outer.duplicate()
		edge.append(outer[0])
		draw_polyline(edge, CHAR, maxf(2.0, rx * 0.016), true)
		# Three lava seams that glow hot: a wide warm haze, the glow, the molten line, a white-hot core; pools of heat
		# where they meet and where they run out.
		for sm: Array in SEAMS:
			var seam := PackedVector2Array()
			for p: Vector2 in sm:
				seam.append(c + Vector2(p.x * rx, p.y * ry) * 0.9)
			draw_polyline(seam, Color(SEAM_GLOW, 0.16), rx * 0.15, true)
			draw_polyline(seam, Color(SEAM_GLOW, 0.32), rx * 0.085, true)
			draw_polyline(seam, SEAM, rx * 0.036, true)
			draw_polyline(seam, SEAM_HOT, rx * 0.013, true)
		for hp: Vector2 in [Vector2(-0.44, 0.2), Vector2(0.48, -0.4), Vector2(0.22, -0.58)]:
			var at3 := c + Vector2(hp.x * rx, hp.y * ry) * 0.9
			draw_circle(at3, rx * 0.11, Color(SEAM_GLOW, 0.18), true, -1.0, true)
			draw_circle(at3, rx * 0.04, Color(SEAM, 0.85), true, -1.0, true)
			draw_circle(at3, rx * 0.016, SEAM_HOT, true, -1.0, true)
		# Embers off the trail.
		for e: Vector3 in [Vector3(0.95, -1.15, 1.0), Vector3(1.28, -0.82, 0.7), Vector3(0.62, -1.38, 0.8),
				Vector3(1.42, -1.3, 0.6), Vector3(1.12, -1.55, 0.5)]:
			var at4 := c + Vector2(e.x * rx, e.y * ry)
			draw_circle(at4, rx * 0.045 * e.z, Color(SEAM_GLOW, 0.25), true, -1.0, true)
			draw_circle(at4, rx * 0.016 * e.z, SEAM, true, -1.0, true)

	## A tapered streak, widest and brightest at the rock, thinning and fading toward the tip: a soft wide glow, the
	## streak, a bright core line.
	func _streak(root: Vector2, tip: Vector2, half_w: float) -> void:
		var axis := tip - root
		var nrm := Vector2(-axis.y, axis.x).normalized()
		for layer: Vector2 in [Vector2(2.3, 0.28), Vector2(1.0, 0.9)]:
			var p2 := PackedVector2Array()
			var cols := PackedColorArray()
			var m := 12
			for i in m + 1:
				var t := float(i) / float(m)
				p2.append(root + axis * t + nrm * half_w * layer.x * (1.0 - t * 0.92))
				cols.append(Color(STREAK, layer.y * pow(1.0 - t, 1.3)))
			for i in range(m, -1, -1):
				var t := float(i) / float(m)
				p2.append(root + axis * t - nrm * half_w * layer.x * (1.0 - t * 0.92))
				cols.append(Color(STREAK, layer.y * pow(1.0 - t, 1.3)))
			draw_polygon(p2, cols)
		var core := PackedVector2Array()
		var ccols := PackedColorArray()
		for i in 9:
			var t := float(i) / 8.0 * 0.8
			core.append(root + axis * t)
			ccols.append(Color(SEAM_HOT, 0.85 * (1.0 - t / 0.8)))
		draw_polyline_colors(core, ccols, half_w * 0.35, true)

	func _ellipse(c: Vector2, half: Vector2, col: Color) -> void:
		var pts := PackedVector2Array()
		for i in 40:
			var a := TAU * float(i) / 40.0
			pts.append(c + Vector2(cos(a) * half.x, sin(a) * half.y))
		draw_colored_polygon(pts, col)
