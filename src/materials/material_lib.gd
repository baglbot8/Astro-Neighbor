class_name MaterialLib
extends RefCounted
## One-stop shop for consistent materials. ALL builders use these instead of raw StandardMaterial3D
## so the whole game shares one lighting language.
##
##   MaterialLib.toon(Color("#ff7a59"))                       -> soft toon
##   MaterialLib.toon(c, {"rim": 0.5, "spec": 0.4, "spec_size": 120.0, "shade": 0.5})
##   MaterialLib.glow(Color("#7cf"), 2.5)                     -> toon + emission (lamps, crystals, screens)
##   MaterialLib.glass(Color("#6fc3ff"), 0.35)                -> transparent glossy (helmet visor, windows)
##   MaterialLib.metal(Color("#b8c4d6"))                      -> toon with metallic sheen
##   MaterialLib.flat_unlit(Color)                            -> unshaded (UI in 3D, star sprites)
## Materials are cached by key so thousands of props don't allocate thousands of materials.

const TOON_SHADER := preload("res://src/shaders/toon_soft.gdshader")
const VISOR_SHADER := preload("res://src/shaders/visor.gdshader")
const STAR_SHADER := preload("res://src/shaders/star.gdshader")
static var _cache: Dictionary = {}

## R2.9 surface kinds, matching the `surface_kind` uniform in toon_soft.gdshader.
const SURFACE_KINDS := {"none": 0, "cloth": 1, "metal": 2, "wood": 3, "rock": 4, "foliage": 5, "rubber": 6, "skin": 7}

static func toon(color: Color, opts: Dictionary = {}) -> ShaderMaterial:
	var key := "toon|%s|%s" % [color.to_html(), str(opts)]
	if _cache.has(key):
		return _cache[key]
	var m := ShaderMaterial.new()
	m.shader = TOON_SHADER
	m.set_shader_parameter("albedo", color)
	m.set_shader_parameter("ramp_softness", opts.get("softness", 0.32))
	m.set_shader_parameter("shade_strength", opts.get("shade", 0.42))
	m.set_shader_parameter("shade_tint", opts.get("shade_tint", Color(0.62, 0.55, 0.85)))
	# R2.6 (PASTEL AND MATTE): natural surfaces are matte by default and gloss is opt-in.
	# These used to default to rim 0.28 / spec 0.22, which painted a wet white ellipse on every
	# flat top face in the game (decorations, buildings, characters and the rocket all inherit
	# these). Genuinely shiny things - the visor, water, polished chrome, glass - pass their own
	# higher values, and MaterialLib.metal() still overrides both.
	m.set_shader_parameter("rim_strength", opts.get("rim", 0.09))
	m.set_shader_parameter("spec_strength", opts.get("spec", 0.05))
	m.set_shader_parameter("spec_size", opts.get("spec_size", 60.0))
	m.set_shader_parameter("roughness", opts.get("roughness", 0.85))
	m.set_shader_parameter("metallic", opts.get("metallic", 0.0))
	if opts.has("emission"):
		m.set_shader_parameter("emission_color", opts["emission"])
		m.set_shader_parameter("emission_strength", opts.get("emission_strength", 1.5))
	# R2.9 surface detail (docs/STYLE_GUIDE.md). Opt in with {"surface": "cloth"|"metal"|"wood"|
	# "rock"|"foliage"}. Adds material character through roughness/normal/albedo variation, never
	# by raising specular, so it does not undo R2.6 (pastel and matte). Fine detail fades with
	# distance automatically - a high-frequency pattern with no mip chain moires otherwise.
	# Optional: "surface_strength" (default 1.0), "surface_near"/"surface_far" fade distances in
	# metres, and "grain_dir" (a Vector3, wood only - the plank's long axis in model space).
	if opts.has("surface"):
		var kind: int = SURFACE_KINDS.get(str(opts["surface"]), 0)
		m.set_shader_parameter("surface_kind", kind)
		m.set_shader_parameter("surface_strength", opts.get("surface_strength", 1.0))
		m.set_shader_parameter("surface_lod_near", opts.get("surface_near", 3.0))
		m.set_shader_parameter("surface_lod_far", opts.get("surface_far", 14.0))
		if opts.has("grain_dir"):
			m.set_shader_parameter("surface_grain_dir", opts["grain_dir"])
		# "surface_scale" moves a pattern into a band that survives the distance it is viewed at:
		# below 1 is coarser, above 1 is finer. "surface_macro" adds low-frequency tonal drift,
		# the only band that survives past ~20 m on a large surface. "surface_knot" weights wood
		# knots against rings (0.15-0.25 gives combed lines rather than marbling).
		m.set_shader_parameter("surface_scale", opts.get("surface_scale", 1.0))
		m.set_shader_parameter("surface_macro", opts.get("surface_macro", 0.0))
		m.set_shader_parameter("surface_macro_cycles", opts.get("surface_macro_cycles", 2.6))
		m.set_shader_parameter("surface_knot", opts.get("surface_knot", 0.55))
		# "skin" only: spot vs scale-edge weighting and the spot size.
		m.set_shader_parameter("surface_spot_amount", opts.get("surface_spot", 1.0))
		m.set_shader_parameter("surface_scale_amount", opts.get("surface_scales", 1.0))
		m.set_shader_parameter("surface_spot_radius", opts.get("surface_spot_radius", 0.34))
	if opts.has("texture"):
		m.set_shader_parameter("albedo_texture", opts["texture"])
		m.set_shader_parameter("use_texture", true)
		m.set_shader_parameter("uv_scale", opts.get("uv_scale", Vector2.ONE))
	_cache[key] = m
	return m

static func glow(color: Color, strength: float = 2.0, base: Color = Color.TRANSPARENT) -> ShaderMaterial:
	var b := color if base == Color.TRANSPARENT else base
	return toon(b, {"emission": color, "emission_strength": strength, "shade": 0.1, "rim": 0.0})

static func metal(color: Color, opts: Dictionary = {}) -> ShaderMaterial:
	var o := opts.duplicate()
	# R2.9: metal gets brushed grain and a travelling sheen by default. Pass {"surface": "none"}
	# to opt out (a tiny decoration part does not need it).
	o["surface"] = o.get("surface", "metal")
	o["metallic"] = o.get("metallic", 0.6)
	o["roughness"] = o.get("roughness", 0.45)
	o["spec"] = o.get("spec", 0.6)
	o["spec_size"] = o.get("spec_size", 140.0)
	o["rim"] = o.get("rim", 0.45)
	return toon(color, o)

static func glass(tint: Color, alpha: float = 0.35, opts: Dictionary = {}) -> StandardMaterial3D:
	var key := "glass|%s|%.2f|%s" % [tint.to_html(), alpha, str(opts)]
	if _cache.has(key):
		return _cache[key]
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(tint.r, tint.g, tint.b, alpha)
	m.roughness = opts.get("roughness", 0.08)
	m.metallic = opts.get("metallic", 0.2)
	m.metallic_specular = 0.9
	m.cull_mode = BaseMaterial3D.CULL_BACK
	m.rim_enabled = true
	m.rim = 0.6
	m.rim_tint = 0.3
	m.clearcoat_enabled = true
	m.clearcoat = 0.8
	m.refraction_enabled = false
	_cache[key] = m
	return m

static func flat_unlit(color: Color, billboard: bool = false) -> StandardMaterial3D:
	var key := "unlit|%s|%s" % [color.to_html(), billboard]
	if _cache.has(key):
		return _cache[key]
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = color
	if color.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if billboard:
		m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	_cache[key] = m
	return m

## Vertex-colored toon (for meshes built with SurfaceTool that bake colors into COLOR).
static func toon_vertex_color(opts: Dictionary = {}) -> ShaderMaterial:
	var key := "toonvc|%s" % str(opts)
	if _cache.has(key):
		return _cache[key]
	var m := toon(Color.WHITE, opts).duplicate()
	var sh := Shader.new()
	sh.code = TOON_SHADER.code.replace("vec3 base = albedo.rgb;", "vec3 base = albedo.rgb * COLOR.rgb;")
	m.shader = sh
	_cache[key] = m
	return m

## Helmet visor / window glass: tinted, glossy, fresnel rim, reflects the sky, painted highlight blob.
##   MaterialLib.visor(Color("#6fc3ff"))                 -> astronaut visor
##   MaterialLib.visor(c, 0.55, {"rim": 0.4, "highlight": 0.5})
static func visor(tint: Color, alpha: float = 0.4, opts: Dictionary = {}) -> ShaderMaterial:
	var key := "visor|%s|%.2f|%s" % [tint.to_html(), alpha, str(opts)]
	if _cache.has(key):
		return _cache[key]
	var m := ShaderMaterial.new()
	m.shader = VISOR_SHADER
	m.set_shader_parameter("tint", Color(tint.r, tint.g, tint.b, alpha))
	m.set_shader_parameter("rim_strength", opts.get("rim", 0.7))
	m.set_shader_parameter("highlight_strength", opts.get("highlight", 0.9))
	m.set_shader_parameter("gloss", opts.get("gloss", 0.92))
	m.set_shader_parameter("fresnel_power", opts.get("fresnel", 3.0))
	_cache[key] = m
	return m

## Soft additive glow sprite (camera billboard). Put on a QuadMesh or a particle draw pass for
## sparkles, stardust twinkles, fireflies, lamp flares.
##   MaterialLib.glow_sprite(Color("#ffe27a"), 2.5)
##   MaterialLib.glow_sprite(c, 2.0, {"points": 1.0, "blink": 0.5, "blink_speed": 4.0, "softness": 0.5})
static func glow_sprite(color: Color, intensity: float = 2.0, opts: Dictionary = {}) -> ShaderMaterial:
	var key := "glowsprite|%s|%.2f|%s" % [color.to_html(), intensity, str(opts)]
	if _cache.has(key):
		return _cache[key]
	var m := ShaderMaterial.new()
	m.shader = STAR_SHADER
	m.set_shader_parameter("tint", color)
	m.set_shader_parameter("intensity", intensity)
	m.set_shader_parameter("softness", opts.get("softness", 0.55))
	m.set_shader_parameter("core", opts.get("core", 0.35))
	m.set_shader_parameter("points", opts.get("points", 0.0))
	m.set_shader_parameter("blink_amount", opts.get("blink", 0.0))
	m.set_shader_parameter("blink_speed", opts.get("blink_speed", 3.0))
	_cache[key] = m
	return m
