class_name TitleLettering
extends Node2D
## PROCEDURAL PLANET LETTERING (builder SINTRO, 2026-10-19; the user: "Can the text that appears be a unique font
## that matches the planet and also takes up a lot of the screen and is in the center middle. Then it becomes more
## transparent and fades out."). The project has one font file (Baloo 2) and draws everything procedurally, so a
## "planet font" is a tiny STROKE FONT: each glyph is a few polylines on a unit grid (baseline y = 0, cap height
## y = 1, y up), drawn as thick round-capped strokes, and a per-planet STYLE (a Dictionary from the world script,
## e.g. worlds/zorp.gd `intro_title_style()`) makes the lettering that planet's own: stroke width, slant, a baked
## wobble that grows up the letter (tentacle-like), colours, glowing bulbs on the upward stroke tips, a glow band,
## spore sparkles drifting up, and a gentle out-of-step sway.
##
## COST. `build()` lays the title out and makes each letter's strokes as Line2D trees (a glow band, then every
## outline, then every core, then the bulbs) - but those are NEVER drawn on screen: the bake (`bake_start` /
## `bake_finish`) renders them ONCE, behind the black, into ONE atlas SubViewport that then stops updating, and from
## then on each letter is two Sprite2D cut from that atlas (its glow band; its body), all halos before all bodies so no letter's
## band covers its neighbour. Measured before the bake: drawn live, the Line2D title added ~160 draw calls (34 ->
## ~195 a frame; each antialiased Line2D is its own polygon draw). Per frame `_process` only writes each letter's
## skew/position and each sparkle's position and alpha: no allocation, no rebuild. The owner fades it with
## `set_strength(a)` and grows it with `scale`. Everything here is drawn PREMULTIPLIED (the atlas was rendered onto a
## clear target): a fade must scale colour and alpha together, or the letters brighten instead of thinning (seen in
## the frames when only `modulate.a` was lowered). Each letter's body (outline + core + bulbs) is ONE baked sprite, so a fade cannot
## show the dark outline through the light core (the grey ghosts seen when every stroke layer faded on its own);
## a CanvasGroup did that job before the bake and cost a screen-sized back-buffer (~12 MB), so it is gone.
##
## GLYPHS: only those Zorp's title needs are drawn so far (Z O R P ' S V I L E T H W, and space). A character with
## no glyph falls back to a Baloo 2 Label for that character (and a push_warning) - never a crash.
##
## Units: the layout is in pixels at BUILD_CAP_PX of cap height (the owner scales the node to fit); the atlas is
## baked at the cap height the screen will really show (`bake(cap_px)`), so it is sharp on the phone.

const BUILD_CAP_PX := 100.0
## Glyph polylines are resampled to this spacing (glyph units) so the wobble bends them smoothly.
const SAMPLE_STEP := 0.035
const SPACE_ADVANCE := 0.42
## The baked atlas is at most this wide and tall (pixels); the bake scale drops to fit.
const ATLAS_MAX := 2048
## Space round each letter's cell (pixels) so atlas neighbours never bleed into each other when filtered.
const CELL_PAD := 4

## The glyph table: char -> {"w": advance width (units), "strokes": Array of PackedVector2Array}. Built once.
static var _glyphs: Dictionary = {}
static var _dot_tex: GradientTexture2D
static var _spark_tex: GradientTexture2D

var style: Dictionary = {}
var lines: PackedStringArray = []
## The lettering's size at scale 1 (pixels), centred on this node's origin.
var block_size := Vector2.ZERO
## The baked atlas and its size, for a report.
var atlas_size := Vector2i.ZERO

var _halo_root: Node2D
var _body_root: Node2D
var _spark_root: Node2D
## The unbaked stroke trees: per letter a glow-band node and a body node, kept off screen until `bake`.
var _src_halo: Array[Node2D] = []
var _src_body: Array[Node2D] = []
var _src_w := PackedFloat32Array()        # each letter's glyph width (units), for its atlas cell
## The sprites that sway: 2 per letter (halo, body).
var _letter_nodes: Array[Node2D] = []
var _letter_rest := PackedVector2Array()
var _letter_phase := PackedFloat32Array()
var _sparks: Array[Sprite2D] = []
var _spark_col := PackedColorArray()
var _spark_pos := PackedVector2Array()
var _spark_vel := PackedVector2Array()
var _spark_age := PackedFloat32Array()
var _spark_life := PackedFloat32Array()
var _rng := RandomNumberGenerator.new()
var _t := 0.0
var _sway := 0.0
var _sway_hz := 0.3
var _fallbacks := 0
var _baked := false


## Lays out `text_lines` (one entry per line) in `st` (see worlds/zorp.gd `intro_title_style`) and makes the
## stroke trees. Nothing is drawn until `bake`.
func build(text_lines: PackedStringArray, st: Dictionary) -> void:
	style = st
	lines = text_lines
	_ensure_tables()
	_rng.seed = 7_1019
	_sway = deg_to_rad(float(st.get("sway_deg", 3.0)))
	_sway_hz = float(st.get("sway_hz", 0.3))
	# Glow bands of every letter first, then every body, then the sparkles.
	_halo_root = _layer("Halo")
	_body_root = _layer("Bodies")
	_spark_root = _layer("Sparks")
	var px := BUILD_CAP_PX
	var track := float(st.get("tracking", 0.16))
	var gap := float(st.get("line_gap", 0.36))
	# Line widths first, to centre each line.
	var widths := PackedFloat32Array()
	var maxw := 0.0
	for ln in lines:
		var w := 0.0
		for i in ln.length():
			w += _advance(ln[i]) + (track if i < ln.length() - 1 else 0.0)
		widths.append(w)
		maxw = maxf(maxw, w)
	var n := lines.size()
	var total_h := float(n) + gap * float(n - 1)
	block_size = Vector2(maxw, total_h) * px
	var letter_i := 0
	for li in n:
		var ln := lines[li]
		var x := -widths[li] * 0.5
		# Baseline of this line, y down on screen, the block centred on the origin.
		var base_y := -total_h * 0.5 + float(li) * (1.0 + gap) + 1.0
		for i in ln.length():
			var ch := ln[i]
			var adv := _advance(ch)
			if ch != " ":
				_build_letter(ch, Vector2((x + adv * 0.5) * px, base_y * px), letter_i)
				letter_i += 1
			x += adv + track
	_build_sparks(int(st.get("sparks", 12)))


func _layer(nm: String) -> Node2D:
	var n := Node2D.new()
	n.name = nm
	add_child(n)
	return n


func _advance(ch: String) -> float:
	if ch == " ":
		return SPACE_ADVANCE
	if _glyphs.has(ch):
		return float((_glyphs[ch] as Dictionary)["w"])
	return 0.6


## How far a letter's drawing reaches outside its glyph box (units): half the glow band, the bulbs' glow, the
## slant and wobble.
func _margin() -> float:
	var band := (float(style.get("stroke", 0.13)) + float(style.get("halo", 0.45))) * 0.5
	var bulb := float(style.get("bulb_r", 0.0)) * 2.5
	return maxf(band, bulb) + absf(float(style.get("slant", 0.0))) + absf(float(style.get("wobble", 0.0))) + 0.06


## One letter's stroke trees (slanted and wobbled once), drawn at its own origin = the baseline centre: a glow-band
## node, and a body node holding every outline, then every core, then the bulbs on its free upward tips.
func _build_letter(ch: String, rest: Vector2, idx: int) -> void:
	var px := BUILD_CAP_PX
	var halo_n := Node2D.new()
	var body_n := Node2D.new()
	_src_halo.append(halo_n)
	_src_body.append(body_n)
	_letter_rest.append(rest)
	_letter_phase.append(float(idx) * 1.7 + _rng.randf_range(0.0, 0.8))
	if not _glyphs.has(ch):
		_fallbacks += 1
		_src_w.append(0.6)
		push_warning("TitleLettering: no glyph for \"%s\"; drawn in Baloo 2 instead" % ch)
		var l := Label.new()
		l.text = ch
		l.add_theme_font_override("font", UIStyle.ui_font())
		l.add_theme_font_size_override("font_size", int(px * 1.35))
		l.add_theme_color_override("font_color", style.get("core", Color.WHITE))
		l.add_theme_color_override("font_outline_color", style.get("outline_col", Color.BLACK))
		l.add_theme_constant_override("outline_size", int(px * 0.12))
		l.reset_size()
		l.position = Vector2(-l.size.x * 0.5, -l.size.y * 0.82)
		body_n.add_child(l)
		return
	var g: Dictionary = _glyphs[ch]
	var w := float(g["w"])
	_src_w.append(w)
	var slant := float(style.get("slant", 0.0))
	var wob := float(style.get("wobble", 0.0))
	var ph := float(idx) * 2.3
	var stroke := float(style.get("stroke", 0.13))
	var outline := float(style.get("outline", 0.05))
	var halo := float(style.get("halo", 0.45))
	var strokes: Array = g["strokes"]
	var baked: Array[PackedVector2Array] = []
	for s: PackedVector2Array in strokes:
		var pts := PackedVector2Array()
		var dense := _resample(s)
		for p in dense:
			var x := p.x - w * 0.5 + slant * p.y + wob * sin(PI * 1.3 * p.y + ph) * p.y
			pts.append(Vector2(x, -p.y) * px)
		baked.append(pts)
	# The glow band is OPAQUE (a deep tint of the glow colour) and lives on its own sprite, drawn under every body.
	# Tried and dropped, each seen in a close-up: a textured soft Line2D (seams along every segment), translucent
	# strokes (round joints overlap into "sunburst" fans), a nested CanvasGroup (a grey box on Compatibility).
	for pts in baked:
		_line(halo_n, pts, (stroke + halo) * px, style.get("halo_col", Color.WHITE))
	for pts in baked:
		_line(body_n, pts, (stroke + outline * 2.0) * px, style.get("outline_col", Color.BLACK))
	for pts in baked:
		_line(body_n, pts, stroke * px, style.get("core", Color.WHITE))
	# Bulbs: on stroke tips that are high (y >= bulb_min_y), touch no other stroke, and END GOING UP like a
	# tentacle (the last stretch rises more than it runs) - not on a bar's flat end.
	var bulb_r := float(style.get("bulb_r", 0.0))
	if bulb_r <= 0.0:
		return
	var min_y := float(style.get("bulb_min_y", 0.9))
	for si in strokes.size():
		var s: PackedVector2Array = strokes[si]
		for end_p: Vector2 in [s[0], s[s.size() - 1]]:
			if end_p.y < min_y or _touches_other(strokes, si, end_p):
				continue
			var nb: Vector2 = s[1] if end_p == s[0] else s[s.size() - 2]
			var d := (end_p - nb).normalized()
			if d.y < 0.5:
				continue
			if str(style.get("bulb_skip", "")).contains(ch):
				continue
			var bi := baked[si]
			var at := bi[0] if end_p == s[0] else bi[bi.size() - 1]
			_bulb(body_n, at, bulb_r * px)


## THE BAKE, in two calls so it rides on frames the caller draws anyway (the intro's warm-up behind the black):
## `bake_start(cap_px)` lays every letter's glow band and body into one atlas SubViewport set to render ONCE;
## after at least one drawn frame, `bake_finish()` stops that viewport (UPDATE_DISABLED: its texture stays on the
## GPU, nothing is read back - a get_image() readback of the ~2000x1600 atlas cost ~190 ms, measured) and puts up
## two sprites per letter cut from it. `cap_px` is the cap height the screen will really show, in physical pixels,
## so the atlas is sharp.
var _bake_vp: SubViewport
var _bake_cells: Array[Rect2i] = []
var _bake_k := 1.0
var _bake_m := 0.0


func bake_start(cap_px: float) -> void:
	if _baked or _bake_vp != null:
		return
	var m := _margin()
	var k := maxf(cap_px, 8.0) / BUILD_CAP_PX
	var cell_h := 0
	var cells: Array[Rect2i] = []
	var size := Vector2i.ZERO
	# Shelf packing, halo cells then body cells; shrink the scale until the atlas fits ATLAS_MAX.
	for attempt in 6:
		cells.clear()
		cell_h = int(ceil((1.0 + 2.0 * m) * BUILD_CAP_PX * k)) + CELL_PAD * 2
		var x := 0
		var y := 0
		var row_w := 0
		for pass_i in 2:
			for i in _src_w.size():
				var cw := int(ceil((_src_w[i] + 2.0 * m) * BUILD_CAP_PX * k)) + CELL_PAD * 2
				if x + cw > ATLAS_MAX:
					x = 0
					y += cell_h
				cells.append(Rect2i(x, y, cw, cell_h))
				x += cw
				row_w = maxi(row_w, x)
		size = Vector2i(row_w, y + cell_h)
		if size.y <= ATLAS_MAX:
			break
		k *= 0.8
	_bake_cells = cells
	_bake_k = k
	_bake_m = m
	var vp := SubViewport.new()
	_bake_vp = vp
	vp.name = "LetteringBake"
	vp.size = size
	vp.transparent_bg = true
	vp.disable_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	var holder := Node2D.new()
	vp.add_child(holder)
	var n := _src_w.size()
	for i in n:
		for pass_i in 2:
			var src: Node2D = _src_halo[i] if pass_i == 0 else _src_body[i]
			src.position = _anchor(cells[pass_i * n + i])
			src.scale = Vector2.ONE * k
			holder.add_child(src)
	atlas_size = size
	add_child(vp)


## Each letter's origin (its baseline centre) inside its atlas cell, in atlas pixels.
func _anchor(c: Rect2i) -> Vector2:
	return Vector2(c.position.x + c.size.x * 0.5, c.position.y + CELL_PAD + (_bake_m + 1.0) * BUILD_CAP_PX * _bake_k)


func bake_finish() -> void:
	if _baked or _bake_vp == null:
		return
	_bake_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	var tex := _bake_vp.get_texture()
	var cells := _bake_cells
	var k := _bake_k
	var n := _src_w.size()
	_src_halo.clear()
	_src_body.clear()
	# The swaying sprites: halos under _halo_root, bodies under _body_root, at each letter's rest position. The
	# atlas was rendered onto a clear target, so its colours are premultiplied: blend them that way (one shared
	# material, so they still batch).
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA
	for i in n:
		for pass_i in 2:
			var c := cells[pass_i * n + i]
			var sp := Sprite2D.new()
			sp.texture = tex
			sp.region_enabled = true
			sp.region_rect = Rect2(c)
			sp.centered = false
			sp.offset = -(_anchor(c) - Vector2(c.position))
			sp.scale = Vector2.ONE / k
			sp.position = _letter_rest[i]
			sp.material = mat
			(_halo_root if pass_i == 0 else _body_root).add_child(sp)
			_letter_nodes.append(sp)
	_baked = true


func _touches_other(strokes: Array, own: int, p: Vector2) -> bool:
	for j in strokes.size():
		if j == own:
			continue
		var o: PackedVector2Array = strokes[j]
		for k in range(1, o.size()):
			if Geometry2D.get_closest_point_to_segment(p, o[k - 1], o[k]).distance_to(p) < 0.08:
				return true
	return false


func _resample(s: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	if s.size() < 2:
		return s
	out.append(s[0])
	for i in range(1, s.size()):
		var a := s[i - 1]
		var b := s[i]
		if a.distance_to(b) < 1e-4:
			continue   # a zero-length segment (an arc starting on the last point) draws a spike in Line2D
		var k := maxi(1, int(ceil(a.distance_to(b) / SAMPLE_STEP)))
		for j in range(1, k + 1):
			out.append(a.lerp(b, float(j) / float(k)))
	return out


func _line(parent: Node2D, pts: PackedVector2Array, width: float, col: Color) -> void:
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


## A tentacle-plant bulb: a soft glow, a pink ball with a dark rim, a small highlight.
func _bulb(parent: Node2D, at: Vector2, r: float) -> void:
	var glow := Sprite2D.new()
	glow.texture = _dot_texture()
	glow.modulate = style.get("bulb_glow", Color.WHITE)
	glow.position = at
	glow.scale = Vector2.ONE * (r * 5.0 / float(_dot_tex.width))
	parent.add_child(glow)
	var b := _Disc.new()
	b.position = at
	b.r = r
	b.fill = style.get("bulb", Color.WHITE)
	b.rim = style.get("outline_col", Color.BLACK)
	b.rim_w = float(style.get("outline", 0.05)) * BUILD_CAP_PX
	b.hi = style.get("core", Color.WHITE)
	parent.add_child(b)


## The title's strength 0..1, premultiplied (see the header).
func set_strength(a: float) -> void:
	modulate = Color(a, a, a, a)


func _build_sparks(n: int) -> void:
	var cols: Array = style.get("spark_cols", [Color.WHITE])
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA
	for i in n:
		var s := Sprite2D.new()
		s.texture = _spark_texture()
		s.material = mat
		_spark_col.append(cols[i % cols.size()])
		_spark_root.add_child(s)
		_sparks.append(s)
		_spark_pos.append(Vector2.ZERO)
		_spark_vel.append(Vector2.ZERO)
		_spark_age.append(0.0)
		_spark_life.append(1.0)
		_respawn_spark(i, true)


func _respawn_spark(i: int, anywhere: bool) -> void:
	var half := block_size * 0.5
	var y0 := _rng.randf_range(-half.y, half.y) if anywhere else _rng.randf_range(0.0, half.y)
	_spark_pos[i] = Vector2(_rng.randf_range(-half.x * 1.05, half.x * 1.05), y0)
	_spark_vel[i] = Vector2(_rng.randf_range(-6.0, 6.0), -_rng.randf_range(18.0, 34.0))
	_spark_life[i] = _rng.randf_range(1.4, 2.4)
	_spark_age[i] = _rng.randf_range(0.0, _spark_life[i]) if anywhere else 0.0
	_sparks[i].scale = Vector2.ONE * (_rng.randf_range(10.0, 18.0) / float(_spark_tex.width))


func _process(delta: float) -> void:
	_t += delta
	var w := TAU * _sway_hz
	var n := _letter_rest.size()
	for i in n:
		var ph := _letter_phase[i]
		# Tentacle sway: the top leans while the baseline stays put (skew about the baseline origin), plus a
		# breath of bob - out of step letter to letter.
		var sk := _sway * sin(w * _t + ph)
		var bob := Vector2(0.0, 1.6 * sin(w * 1.3 * _t + ph * 0.7))
		if not _baked:
			break
		for k in 2:
			var node := _letter_nodes[i * 2 + k]
			node.skew = sk
			node.position = _letter_rest[i] + bob
	for i in _sparks.size():
		_spark_age[i] += delta
		if _spark_age[i] >= _spark_life[i]:
			_respawn_spark(i, false)
		var p := _spark_pos[i] + _spark_vel[i] * delta
		p.x += sin(_t * 1.7 + float(i)) * 6.0 * delta
		_spark_pos[i] = p
		_sparks[i].position = p
		var u := _spark_age[i] / _spark_life[i]
		var f := sin(PI * clampf(u, 0.0, 1.0))
		var c := _spark_col[i]
		_sparks[i].self_modulate = Color(c.r * f, c.g * f, c.b * f, f)


## Characters drawn by the Baloo 2 fallback (no glyph): for tests.
func fallback_count() -> int:
	return _fallbacks


# ======================================================================================== TEXTURES
## The sparkles' soft dot, premultiplied (white scaled by its own alpha).
static func _spark_texture() -> GradientTexture2D:
	if _spark_tex == null:
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.25, 1.0])
		g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(0.55, 0.55, 0.55, 0.55), Color(0, 0, 0, 0)])
		_spark_tex = GradientTexture2D.new()
		_spark_tex.gradient = g
		_spark_tex.width = 32
		_spark_tex.height = 32
		_spark_tex.fill = GradientTexture2D.FILL_RADIAL
		_spark_tex.fill_from = Vector2(0.5, 0.5)
		_spark_tex.fill_to = Vector2(1.0, 0.5)
	return _spark_tex


static func _dot_texture() -> GradientTexture2D:
	if _dot_tex == null:
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.25, 1.0])
		g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.55), Color(1, 1, 1, 0)])
		_dot_tex = GradientTexture2D.new()
		_dot_tex.gradient = g
		_dot_tex.width = 32
		_dot_tex.height = 32
		_dot_tex.fill = GradientTexture2D.FILL_RADIAL
		_dot_tex.fill_from = Vector2(0.5, 0.5)
		_dot_tex.fill_to = Vector2(1.0, 0.5)
	return _dot_tex


class _Disc extends Node2D:
	var r := 6.0
	var fill := Color.WHITE
	var rim := Color.BLACK
	var rim_w := 4.0
	var hi := Color.WHITE

	func _draw() -> void:
		draw_circle(Vector2.ZERO, r + rim_w, rim, true, -1.0, true)
		draw_circle(Vector2.ZERO, r, fill, true, -1.0, true)
		draw_circle(Vector2(-r * 0.3, -r * 0.35), r * 0.32, Color(hi, 0.85), true, -1.0, true)


# ======================================================================================== THE GLYPHS
## Unit grid: baseline y = 0, cap height y = 1, y up; x from 0 to "w". Rounded and tall (narrow).
static func _ensure_tables() -> void:
	if not _glyphs.is_empty():
		return
	var G := _glyphs
	G["Z"] = {"w": 0.62, "strokes": [_pts([0.06, 1.0, 0.58, 1.0, 0.04, 0.0, 0.6, 0.0])]}
	G["O"] = {"w": 0.66, "strokes": [_arc(0.33, 0.5, 0.31, 0.5, 90.0, 450.0, 40)]}
	var r_stroke := _pts([0.05, 0.0, 0.05, 1.0, 0.3, 1.0])
	r_stroke.append_array(_arc(0.3, 0.75, 0.25, 0.25, 90.0, -90.0, 14))
	r_stroke.append(Vector2(0.05, 0.5))
	G["R"] = {"w": 0.6, "strokes": [r_stroke, _pts([0.27, 0.5, 0.58, 0.0])]}
	var p_stroke := _pts([0.05, 0.0, 0.05, 1.0, 0.28, 1.0])
	p_stroke.append_array(_arc(0.28, 0.74, 0.26, 0.26, 90.0, -90.0, 14))
	p_stroke.append(Vector2(0.05, 0.48))
	G["P"] = {"w": 0.56, "strokes": [p_stroke]}
	G["'"] = {"w": 0.14, "strokes": [_pts([0.08, 1.0, 0.06, 0.72])]}
	var s_stroke := _arc(0.3, 0.745, 0.27, 0.255, 25.0, 270.0, 22)
	s_stroke.append_array(_arc(0.3, 0.255, 0.28, 0.255, 90.0, -155.0, 22))
	G["S"] = {"w": 0.6, "strokes": [s_stroke]}
	G["V"] = {"w": 0.64, "strokes": [_pts([0.02, 1.0, 0.32, 0.0, 0.62, 1.0])]}
	G["I"] = {"w": 0.14, "strokes": [_pts([0.07, 0.0, 0.07, 1.0])]}
	G["L"] = {"w": 0.5, "strokes": [_pts([0.05, 1.0, 0.05, 0.0, 0.48, 0.0])]}
	G["E"] = {"w": 0.52, "strokes": [_pts([0.5, 1.0, 0.05, 1.0, 0.05, 0.0, 0.5, 0.0]), _pts([0.05, 0.5, 0.42, 0.5])]}
	G["T"] = {"w": 0.62, "strokes": [_pts([0.02, 1.0, 0.6, 1.0]), _pts([0.31, 1.0, 0.31, 0.0])]}
	G["H"] = {"w": 0.6, "strokes": [_pts([0.04, 0.0, 0.04, 1.0]), _pts([0.56, 0.0, 0.56, 1.0]),
		_pts([0.04, 0.5, 0.56, 0.5])]}
	G["W"] = {"w": 0.86, "strokes": [_pts([0.02, 1.0, 0.22, 0.0, 0.43, 0.72, 0.64, 0.0, 0.84, 1.0])]}


static func _pts(xy: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in range(0, xy.size(), 2):
		out.append(Vector2(float(xy[i]), float(xy[i + 1])))
	return out


## An elliptical arc from `a0` to `a1` degrees (counter-clockwise for a1 > a0, y up), `n` segments.
static func _arc(cx: float, cy: float, rx: float, ry: float, a0: float, a1: float, n: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in n + 1:
		var a := deg_to_rad(lerpf(a0, a1, float(i) / float(n)))
		out.append(Vector2(cx + rx * cos(a), cy + ry * sin(a)))
	return out
