class_name YarnLite
extends Node
## YARNLITE - the crochet / amigurumi look at a phone budget (heat test, 2026-10-14).
##
## The look lives in the game shaders (src/style/yarn/yarn_lite.gdshaderinc), behind the global
## shader parameter `astro_yarn` ([shader_globals] in project.godot, 0 = the plain game). Every hook
## is `if (astro_yarn > 0.5) { ... }` - a branch on a uniform, so switching it changes no material and
## compiles nothing mid-play.
##
## Where the promo version evaluated the stitch height field 8x per pixel, this one bakes it ONCE,
## here, into a small tiling texture with mipmaps (the mipmaps are the anti-shimmer):
##   yarn_stitch_tex  128 x 128 RGBA8, 8 x 8 stitches of 16 x 16 texels:
##     r = occlusion (gaps dark, fibre grain), scaled so its mean is exactly AO_STORE (the shader
##         multiplies by 1 / AO_STORE, so a far, fully-mipped surface is the plain game colour);
##     g, b = the stitch normal's tangent components * 0.5 + 0.5 (they average to flat in the mips);
##     a = fibre noise, for the cheap fuzz rim.
##   yarn_star_tex    64 x 64, one embroidered asterisk (r = coverage, g = yarn shading).
##
## The node also marks face features and tiny parts (a material copy with `yarn_skip` set) so eyes,
## glints, mouths and buttons stay smooth like the safety eyes and embroidered features of a real
## amigurumi. It marks each mesh once, one frame after it appears; the ON/OFF switch touches no material.
## A mesh that measures tiny only because its node spawned at a near-zero scale (a placed decoration's
## pop-in) is watched for a few frames first, so it is not marked smooth by mistake.
##
## Boot: MaterialLib calls `YarnLite.ensure()` the first time it builds a toon material.

## THE TEST-BUILD DEFAULT. true = the game starts in the crochet look. The dev menu's Perf tab flips it
## at runtime ("Crochet look"); the choice is not saved.
const DEFAULT_ON := true

const TILE := 8          # stitches (and rows) per texture tile - must match YL_TILE in the include
const TEXELS := 16       # texels per stitch - must match YL_TEXELS
const STAR_SIZE := 64
## Mean of the stored occlusion. The shader multiplies by 1 / AO_STORE (YL_AO_GAIN); 178/255 keeps
## the brightest stored value under 1.0 after normalising (measured max ratio 1.21 -> 0.85).
const AO_STORE := 178.0 / 255.0
const GAP := 0.42        # darkest gap, fraction of the yarn colour (promo YARN_GAP)
const RELIEF_U := 0.4125 # tilt per unit stitch slope along the row (promo YARN_RELIEF * H / W)
const RELIEF_V := 0.55   # ... and up the column (promo YARN_RELIEF)
## A part whose largest world-space side is below this is a button or bead, not a crocheted piece
## (under one 0.056 m stitch, it could not show one anyway). Same rule as the promo.
const DETAIL_MAX_M := 0.045

static var _ready_done := false
static var _node: YarnLite
static var gen_ms := 0.0

var _pending: Array[GeometryInstance3D] = []
## Parts that measured tiny and are waiting to show whether that is their real size: mesh -> {last, still, age}.
var _watch := {}
## A tiny part is a real detail once its size has not changed for this many frames in a row ...
const SETTLE_FRAMES := 3
## ... or, if something keeps it moving (a breathing idle scale), once it has been watched this long (3 s at 60 fps).
const WATCH_MAX_FRAMES := 180


## Builds the textures once, publishes them as shader globals, applies DEFAULT_ON and parks the
## marker node under the root. Safe to call any number of times.
static func ensure() -> void:
	if _ready_done:
		return
	_ready_done = true
	var t0 := Time.get_ticks_usec()
	RenderingServer.global_shader_parameter_set("yarn_stitch_tex", _build_stitch_texture())
	RenderingServer.global_shader_parameter_set("yarn_star_tex", _build_star_texture())
	gen_ms = (Time.get_ticks_usec() - t0) / 1000.0
	print("[YarnLite] stitch + star textures built in %.1f ms; crochet %s" % [gen_ms, "ON" if DEFAULT_ON else "OFF"])
	set_on(DEFAULT_ON)
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null:
		_node = YarnLite.new()
		_node.name = "YarnLite"
		tree.root.add_child.call_deferred(_node)


## Mirrors the astro_yarn global. global_shader_parameter_get() only works in the editor (an
## exported or played game logs an error and reads false), so the state is kept here.
static var _on := false


static func set_on(on: bool) -> void:
	_on = on
	RenderingServer.global_shader_parameter_set("astro_yarn", 1.0 if on else 0.0)


static func is_on() -> bool:
	return _on


# ------------------------------------------------------------------------------ sprites
const SPRITE_ADD := preload("res://src/style/yarn/yarn_sprite_add.gdshader")
const SPRITE_MIX := preload("res://src/style/yarn/yarn_sprite_mix.gdshader")
enum Sprite { NONE = -1, FELT = 0, STAR = 1, POMPOM = 2 }


## The crochet-able twin of an unshaded, alpha-blended StandardMaterial3D glow or puff (see
## yarn_sprite.gdshaderinc): the same albedo colour, texture, vertex colour, billboard and blend, so
## with crochet OFF it draws what the StandardMaterial3D drew. `kind` is how it looks with crochet ON
## (Sprite.FELT halo, Sprite.STAR embroidered star, Sprite.POMPOM wool ball). Animate it through the
## "albedo" shader parameter (it replaces `albedo_color`). Supports billboard DISABLED / ENABLED /
## PARTICLES (no particle anim frames) and cull BACK only (a billboard always faces the camera).
static func sprite_material(std: StandardMaterial3D, kind: int) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SPRITE_ADD if std.blend_mode == BaseMaterial3D.BLEND_MODE_ADD else SPRITE_MIX
	m.set_shader_parameter("albedo", std.albedo_color)
	if std.albedo_texture != null:
		m.set_shader_parameter("texture_albedo", std.albedo_texture)
		m.set_shader_parameter("use_texture", true)
	m.set_shader_parameter("use_vertex_color", std.vertex_color_use_as_albedo)
	var bb := 0
	if std.billboard_mode == BaseMaterial3D.BILLBOARD_ENABLED:
		bb = 1
	elif std.billboard_mode == BaseMaterial3D.BILLBOARD_PARTICLES:
		bb = 2
	elif std.billboard_mode != BaseMaterial3D.BILLBOARD_DISABLED:
		push_warning("YarnLite.sprite_material: billboard mode %d is not supported; drawn unbillboarded" % std.billboard_mode)
	m.set_shader_parameter("billboard", bb)
	m.set_shader_parameter("billboard_keep_scale", std.billboard_keep_scale)
	m.set_shader_parameter("yarn_kind", kind)
	m.render_priority = std.render_priority
	return m


# ------------------------------------------------------------------------------ texture bake
static func _hash21(x: float, y: float) -> float:
	# The promo's yarn_hash21, so the per-stitch randomness has the same character.
	var p3 := Vector3(x, y, x) * 0.1031
	p3 = Vector3(p3.x - floorf(p3.x), p3.y - floorf(p3.y), p3.z - floorf(p3.z))
	var d := p3.dot(Vector3(p3.y, p3.z, p3.x) + Vector3(33.33, 33.33, 33.33))
	p3 += Vector3(d, d, d)
	var r := (p3.x + p3.y) * p3.z
	return r - floorf(r)


## One yarn leg: a hemi-ellipsoid along unit axis (ax, ay) with a twisted-ply groove (promo yarn_leg).
static func _leg(fx: float, fy: float, cx: float, cy: float, ax: float, ay: float, ln: float, wd: float) -> float:
	var dx := fx - cx
	var dy := fy - cy
	var al := (dx * ax + dy * ay) / ln
	var ac := (-dx * ay + dy * ax) / wd
	var e := al * al + ac * ac
	if e >= 1.0:
		return 0.0
	var body := sqrt(1.0 - e)
	var ply := 0.5 + 0.5 * cos(TAU * (al * 1.6 + ac * 0.45))
	return body * lerpf(0.80, 1.0, ply)


## Height of one single-crochet "V" stitch at cell-local (fx, fy) in [-0.5, 0.5] (promo yarn_v).
static func _stitch_h(fx: float, fy: float, rx: float, ry: float) -> float:
	fx += (rx - 0.5) * 0.06
	fy += (ry - 0.5) * 0.05
	var lean := 0.36 + (rx - 0.5) * 0.10
	var inv := 1.0 / sqrt(lean * lean + 1.0)
	var alx := -lean * inv
	var aly := inv
	var hl := _leg(fx, fy, -0.19, 0.03, alx, aly, 0.56, 0.27)
	var hr := _leg(fx, fy, 0.19, 0.03, -alx, aly, 0.56, 0.27)
	var row := 1.0 - smoothstep(0.38, 0.5, absf(fy))
	return maxf(hl, hr) * row


static func _build_stitch_texture() -> ImageTexture:
	var n := TILE * TEXELS
	var h := PackedFloat32Array()
	h.resize(n * n)
	var rnd := PackedFloat32Array()
	rnd.resize(TILE * TILE * 2)
	for cy in TILE:
		for cx in TILE:
			rnd[(cy * TILE + cx) * 2] = _hash21(cx + 0.37, cy + 0.37)
			rnd[(cy * TILE + cx) * 2 + 1] = _hash21(cx + 7.91, cy + 7.91)
	var inv_t := 1.0 / TEXELS
	for y in n:
		var cy := y / TEXELS
		var fy := (float(y % TEXELS) + 0.5) * inv_t - 0.5
		for x in n:
			var cx := x / TEXELS
			var fx := (float(x % TEXELS) + 0.5) * inv_t - 0.5
			var ri := (cy * TILE + cx) * 2
			h[y * n + x] = _stitch_h(fx, fy, rnd[ri], rnd[ri + 1])
	# Occlusion with a fibre grain, then its exact mean.
	var ao := PackedFloat32Array()
	ao.resize(n * n)
	var fib := PackedFloat32Array()
	fib.resize(n * n)
	var sum := 0.0
	for y in n:
		for x in n:
			var i := y * n + x
			# Fibre: value noise streaked along the row direction (two texels long, one across).
			var f := _hash21(floorf(x * 0.5) + 13.1, float(y) + 5.7) * 0.6 + _hash21(float(x) + 2.3, float(y) + 91.0) * 0.4
			fib[i] = f
			var a := lerpf(GAP, 1.0, smoothstep(0.0, 0.40, h[i])) * (1.0 + (f - 0.5) * 0.16)
			ao[i] = a
			sum += a
	var mean := sum / float(n * n)
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var step := 2.0 * inv_t   # central difference span, in stitches
	for y in n:
		var yu := ((y + 1) % n) * n
		var yd := ((y - 1 + n) % n) * n
		for x in n:
			var xr := (x + 1) % n
			var xl := (x - 1 + n) % n
			var gx := (h[y * n + xr] - h[y * n + xl]) / step
			var gy := (h[yu + x] - h[yd + x]) / step
			var nrm := Vector3(-gx * RELIEF_U, -gy * RELIEF_V, 1.0).normalized()
			var i := y * n + x
			img.set_pixel(x, y, Color(clampf(ao[i] / mean * AO_STORE, 0.0, 1.0),
				nrm.x * 0.5 + 0.5, nrm.y * 0.5 + 0.5, fib[i]))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


static func _build_star_texture() -> ImageTexture:
	var n := STAR_SIZE
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var px := 2.0 / n
	for y in n:
		for x in n:
			var p := Vector2((x + 0.5) / n * 2.0 - 1.0, (y + 0.5) / n * 2.0 - 1.0)
			var s := 0.0
			for k in 4:
				var a := k * PI * 0.25
				var d := Vector2(cos(a), sin(a))
				var al := p.dot(d) / (1.0 if k % 2 == 0 else 0.62)
				var ac := p.dot(Vector2(-d.y, d.x)) / 0.14
				var e := al * al + ac * ac
				if e < 1.0:
					var ply := 0.5 + 0.5 * cos(TAU * (al * 3.0 + ac * 0.35))
					s = maxf(s, sqrt(1.0 - e) * lerpf(0.72, 1.0, ply))
			var cov := smoothstep(0.0, px * 3.0, s)
			img.set_pixel(x, y, Color(cov, lerpf(0.70, 1.15, s) / 1.2, 0.0, 1.0))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


# ------------------------------------------------------------------------------ detail marking
## Node meta that keeps a part smooth (glossy plastic, like the face parts): screens, visors, lenses
## (docs: CROCHET_SPEC "Glass, visor, eyes, crystals, gems: glossy plastic"). Set it with keep_glossy()
## when the part is built; the marker picks it up with the rest, one frame after the part appears.
const GLOSSY_META := &"yarn_glossy"
## Meta on a hidden part parked smooth: [material_override, [surface overrides]] from before, to restore
## if it is shown at a real size. It lives and dies with the mesh.
const ORIG_META := &"yarn_orig_mats"


## Marks a part to stay glossy plastic in the crochet look. Call when the part is built (no cost
## after that; the ON/OFF switch still touches no material).
static func keep_glossy(g: GeometryInstance3D) -> void:
	if g != null:
		g.set_meta(GLOSSY_META, true)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().node_added.connect(_on_node_added)
	_collect(get_tree().root)


func _collect(n: Node) -> void:
	if n is GeometryInstance3D:
		_pending.append(n)
	for c in n.get_children():
		_collect(c)


func _on_node_added(n: Node) -> void:
	if n is MeshInstance3D:
		_pending.append(n)


## Marked one frame after they appear, once their builder has placed and scaled them. A part that
## looks tiny is not marked at once: it is watched until it is clear the size is real (see _watch).
func _process(_delta: float) -> void:
	if not _watch.is_empty():
		_poll_watch()
	if _pending.is_empty():
		return
	var batch := _pending
	_pending = []
	for g in batch:
		if is_instance_valid(g) and g.is_inside_tree():
			_mark(g)


## World-space size of a mesh's largest side, from its own AABB and its current global scale.
func _world_size(g: GeometryInstance3D) -> float:
	var s := g.global_transform.basis.get_scale().abs()
	var size := g.get_aabb().size * s
	return maxf(size.x, maxf(size.y, size.z))


func _mark(g: GeometryInstance3D) -> void:
	var mi := g as MeshInstance3D
	if mi == null or mi.mesh == null:
		return
	var in_face := String(g.get_path()).contains("/Face/") or g.has_meta(GLOSSY_META)
	if in_face:
		_apply_skip(mi)
		return
	if _world_size(g) >= DETAIL_MAX_M:
		_unskip(mi)   # a part parked as hidden-and-tiny that has now been shown at its real size
		return
	# Looks tiny: smooth now, as before, so a real button never flickers through crochet. But a part
	# that spawns at a near-zero scale and tweens up (a placed decoration's pop starts at 0.02, a hidden
	# part waits at 0.001) measures tiny too, and marking it for good kept it smooth for good
	# (docs/OPEN_ISSUES.md 72). So the original materials are remembered and the part is watched: it is
	# a real detail only if it never reaches DETAIL_MAX_M; if it does, crochet is restored.
	_apply_skip(mi, true)
	if not g.is_visible_in_tree():
		_park_hidden(mi)
		return
	_watch[g] = {"last": _world_size(g), "still": 0, "age": 0}


## Settled-size check for the parts _mark found tiny. Runs only while some are being watched (a few
## frames after a spawn); once a part is decided it costs nothing again.
func _poll_watch() -> void:
	# Untyped loop variable: a typed one raises on a freed key before is_instance_valid can run.
	for k in _watch.keys():
		if not is_instance_valid(k):
			_watch.erase(k)
			continue
		var g := k as GeometryInstance3D
		if not g.is_inside_tree():
			_watch.erase(g)
			continue
		if not g.is_visible_in_tree():
			_watch.erase(g)
			_park_hidden(g as MeshInstance3D)
			continue
		var size := _world_size(g)
		if size >= DETAIL_MAX_M:
			_watch.erase(g)   # grew past a detail's size: a real crocheted part
			_unskip(g as MeshInstance3D)
			continue
		var e: Dictionary = _watch[g]
		e["age"] = int(e["age"]) + 1
		if is_equal_approx(size, float(e["last"])):
			e["still"] = int(e["still"]) + 1
		else:
			e["still"] = 0
			e["last"] = size
		if int(e["still"]) >= SETTLE_FRAMES or int(e["age"]) >= WATCH_MAX_FRAMES:
			_watch.erase(g)   # a real detail: it stays smooth (the remembered materials stay for a later hide/show)


## A hidden tiny part (a blink leaf, or a part parked at a token scale until it is shown): its size now
## says nothing about its size when shown. It stays smooth meanwhile (_mark already marked it, with its
## original materials remembered), and is looked at again when it appears - polling a hidden part would cost a
## check per frame for as long as it stays hidden.
func _park_hidden(mi: MeshInstance3D) -> void:
	var shown := _on_part_shown.bind(mi)
	if not mi.visibility_changed.is_connected(shown):
		mi.visibility_changed.connect(shown)


func _unskip(mi: MeshInstance3D) -> void:
	if not mi.has_meta(ORIG_META):
		return
	var o: Array = mi.get_meta(ORIG_META)
	mi.remove_meta(ORIG_META)
	mi.material_override = o[0]
	var surf: Array = o[1]
	for i in surf.size():
		mi.set_surface_override_material(i, surf[i])


func _on_part_shown(g: Object) -> void:
	if not is_instance_valid(g):
		return
	if g is GeometryInstance3D and g.is_visible_in_tree():
		g.visibility_changed.disconnect(_on_part_shown.bind(g))
		_pending.append(g)


func _apply_skip(mi: MeshInstance3D, remember := false) -> void:
	if remember and not mi.has_meta(ORIG_META):
		var surf := []
		for i in mi.mesh.get_surface_count():
			surf.append(mi.get_surface_override_material(i))
		mi.set_meta(ORIG_META, [mi.material_override, surf])
	# A per-MATERIAL flag, not an instance uniform: an instance uniform takes a slot of the global
	# shader buffer for every instance of the shader (the hub overflowed its 4096 on the Mac, and
	# WebGL2 only guarantees a quarter of that). Copies are cached per source material, so all the
	# eyes that share a material share one copy.
	if mi.material_override != null:
		var o := _skip_copy(mi.material_override)
		if o != null:
			mi.material_override = o
		return
	for i in mi.mesh.get_surface_count():
		var c := _skip_copy(mi.get_active_material(i))
		if c != null:
			mi.set_surface_override_material(i, c)


var _skip_copies := {}
var _has_skip := {}


func _skip_copy(m: Material) -> Material:
	var sm := m as ShaderMaterial
	if sm == null or sm.shader == null:
		return null
	if sm.get_meta("yarn_skip_copy", false):
		return null
	if _skip_copies.has(sm):
		return _skip_copies[sm]
	var sh := sm.shader
	if not _has_skip.has(sh):
		_has_skip[sh] = sh.code.contains("uniform bool yarn_skip")
	if not _has_skip[sh]:
		return null
	var c := sm.duplicate() as ShaderMaterial
	c.set_shader_parameter("yarn_skip", true)
	c.set_meta("yarn_skip_copy", true)
	_skip_copies[sm] = c
	return c
