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
## A kind only exists if that shader has an explicit `else if` branch for it — its chain ends in
## `else -> sd_foliage`, so an id with no branch silently renders as GRASS rather than as nothing.
## hub_surface.gdshader and astro_shell.gdshader carry their own shorter lists; "skin" and "scales"
## are toon_soft only, which is where every character material is built.
const SURFACE_KINDS := {"none": 0, "cloth": 1, "metal": 2, "wood": 3, "rock": 4, "foliage": 5, "rubber": 6, "skin": 7, "scales": 8}

## Mean of sd_skin's spot term at a given `surface_spot_radius`, which `toon()` feeds to the
## `surface_spot_dc` uniform so the spot pattern averages out instead of tinting the character.
##
## THIS IS NOT A CONSTANT AND USED NOT TO BE TREATED AS ONE. sd_skin hardcoded 0.22, while the true
## mean is 0.035 at the shipping radius 0.34 - so alien skin was a flat ~6% albedo DARKENING with a
## faint pattern riding on it, which is the saturation cost recorded in docs/OPEN_ISSUES.md item 35.
## Past radius ~0.70 that same constant flips sign and LIGHTENS the character instead.
##
## The curve is the kernel volume times the 0.478 spot pick rate, saturating as blobs overlap.
## Fitted to a 600k-sample measurement of the shader's own cellular pass to within 0.001 absolute
## across the whole 0.05-1.20 range; the measured table is in sd_skin's header comment.
static func spot_dc(radius: float) -> float:
	var r := clampf(radius, 0.0, 1.30)
	var r3 := r * r * r
	return 1.0 - exp(-(0.74343 * r3 + 0.52963 * r3 * r - 0.33228 * r3 * r * r))

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
	# "rock"|"foliage"|"rubber"|"skin"|"scales"}. Adds material character through roughness/normal/
	# albedo variation, never by raising specular, so it does not undo R2.6 (pastel and matte). Fine
	# detail fades with distance automatically - a high-frequency pattern with no mip chain moires.
	#
	# "skin" is blobs on a cell ground; "scales" is genuine overlapping shingle rows, which is a
	# different silhouette rather than a different speckle - a skin with "surface_scales" turned up
	# only draws the WALLS between abutting cells and still collapses into speckle at 8 m.
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
		# "skin" only: spot vs scale-edge weighting and the spot size. "surface_spot_radius" now
		# runs to 1.20 (it was capped at 0.60, roughly one cell) so a character can have BIG spots
		# rather than freckles. The DC that stops the pattern from tinting the whole character is
		# DERIVED from the radius by spot_dc() - never set the two independently unless you have
		# measured the mean yourself.
		var spot_r: float = float(opts.get("surface_spot_radius", 0.34))
		m.set_shader_parameter("surface_spot_amount", opts.get("surface_spot", 1.0))
		m.set_shader_parameter("surface_scale_amount", opts.get("surface_scales", 1.0))
		m.set_shader_parameter("surface_spot_radius", spot_r)
		m.set_shader_parameter("surface_spot_dc", opts.get("surface_spot_dc", spot_dc(spot_r)))
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

# ----------------------------------------------------------------------------- rocket finish
## The rocket's finish shader (RocketModel "Finish"; docs/CORE_LOOP.md "Changed after the build
## plan": rusty and dirty after the crash, cleaner with every part, then clean, then gold).
##
## It is toon_soft.gdshader with ONE extra pass spliced into fragment(), built by string rewrite
## exactly as `toon_vertex_color` is, so the rocket keeps every other line of the shared shader -
## the web-parity sRGB helpers, the surface-detail library, light(). A private copy would drift the
## first time either changed. The wear pass is gated on `rf_wear > 0` and the gold bands on
## `rf_gold > 0`, so the clean stage 4 (and every save or timeline outside the story) runs exactly
## the shared shader's maths.
##
## The two splice points are literal lines of toon_soft.gdshader. If either stops matching this
## pushes an ERROR (tools/check.sh fails on it) and hands back the plain toon shader: the rocket then
## draws its clean finish at every stage instead of failing to compile.
const _RF_DECL_AFTER := "#define pc_out(q) pc_out_f((q), astro_compat)"
const _RF_PASS_BEFORE := "\tvec3 em = pc_in(emission_color.rgb)"
static var _rocket_finish_shader: Shader

## Uniforms + comments spliced in after the parity macros (so `pc_in` and the sd_* noise exist).
const _RF_DECL := """
// ---- ROCKET FINISH (spliced in by MaterialLib.rocket_finish_shader(); driven by RocketModel) ----
// rf_wear: 0 = clean, and the wear pass below is skipped, so a clean rocket runs the shared toon
// maths untouched; 1 = straight out of the crash. Rust COVERAGE is a threshold on ONE fixed noise
// field (rf_rust_thr, set per stage from measured quantiles of that field), so a cleaner stage keeps
// the same patches, only smaller: the player sees the same rocket being cleaned, not a reshuffle.
// v_objpos is HULL space on every rocket part: RocketModel bakes each part's node transform into its
// vertices, because a porthole rim built at its own origin read y = 0 and took the ground-level soot
// and rust of the engine skirt (the "leopard print" rims of the first pass).
uniform float rf_wear : hint_range(0.0, 1.0) = 0.0;
uniform float rf_rust_thr = 2.0;
// Per surface: how readily it rusts (bare metal more than paint) and how far its paint bleaches.
uniform float rf_rust_bias : hint_range(-0.5, 0.5) = 0.0;
uniform float rf_fade : hint_range(0.0, 1.0) = 0.0;
// Defaults = RocketModel.RUST / RUST_DEEP / DUST / SOOT, which it sets on every material anyway.
uniform vec4 rf_rust_color : source_color = vec4(0.698, 0.584, 0.494, 1.0);
uniform vec4 rf_rust_deep : source_color = vec4(0.545, 0.486, 0.447, 1.0);
uniform vec4 rf_dust_color : source_color = vec4(0.45, 0.43, 0.41, 1.0);
uniform vec4 rf_soot_color : source_color = vec4(0.36, 0.35, 0.35, 1.0);
// How far the dirt layer covers the paint at full grime (0 = none, 1 = pure dust colour).
uniform float rf_grime_depth : hint_range(0.0, 1.0) = 0.5;
// How much of the crash scorch this surface takes: 0 on the dark skirt, nozzle and fin feet.
uniform float rf_scorch : hint_range(0.0, 1.0) = 1.0;
// Model-space XZ direction of the flank that scraped the ground in the crash.
uniform vec2 rf_scorch_dir = vec2(-0.6, -0.8);
// Stage 5 only (1 = gold): the polished-gold reflection bands. Each band is a range of the VIEW-space
// normal's x, so the bands stand still on screen and slide over the hull as the camera moves.
uniform float rf_gold = 0.0;
uniform vec4 rf_gold_hi : source_color = vec4(0.93, 0.88, 0.73, 1.0);
uniform vec4 rf_gold_lo : source_color = vec4(0.494, 0.478, 0.4, 1.0);
uniform vec2 rf_gold_hi_band = vec2(0.20, 0.50);
uniform vec2 rf_gold_lo_band = vec2(-0.62, -0.16);
"""

## The pass itself, spliced in just before emission, while ALBEDO is still LINEAR (toon_soft keeps it
## linear through fragment() and encodes once at the bottom), so it is renderer-parity-safe.
##
## WHY THE DIRT IS A LAYER AND NOT A MULTIPLY. The first pass multiplied the paint by 0.42 at full
## grime and pulled the scorch 0.75 toward a #3d3c40 soot. On the slate skirt, the nozzle and the fin
## feet that pushed the RENDERED colour down to V 0.07-0.12, where the only light left is the space
## sky's blue-violet ambient: it rendered #050512-#0e0b1d at S 0.62-0.73 over 7-9% of the crashed
## rocket (critic, both renderers). A layer mixed toward a dirt colour converges ON that colour, so it
## darkens the cream and greys - lightens - the slate; it can never take any surface below the dirt
## colour's own value, and the dust and soot colours are chosen for where THEY render (RocketModel).
const _RF_PASS := """	// ---- ROCKET FINISH pass. ALBEDO is still LINEAR here. ----
	if (rf_wear > 0.001) {
		vec3 fin_p = v_objpos;
		float fin_lod = sd_lod(VERTEX, 2.5, 12.0);
		// Dull, sun-bleached paint: toward its own grey, and a touch darker.
		float fin_grey = dot(ALBEDO, vec3(0.2126, 0.7152, 0.0722));
		ALBEDO = mix(ALBEDO, vec3(fin_grey), rf_fade * rf_wear) * (1.0 - 0.08 * rf_wear);
		// Grime: soot rising from the engine skirt, a dusty mottle over the whole hull, and dirty
		// runs hanging down from the upper hull, laid on as dust and soot layers (note above).
		float fin_blot = sd_fbm01(fin_p * 2.4 + vec3(3.1), 3);
		float fin_soot = smoothstep(1.35, 0.55, fin_p.y) * (0.45 + 0.55 * fin_blot);
		float fin_mottle = smoothstep(0.50, 0.80, fin_blot) * 0.55;
		// Runs: noise 6x finer across than down, so it streaks down the hull.
		vec3 fin_q = vec3(fin_p.x * 7.0, fin_p.y * 1.1, fin_p.z * 7.0) + vec3(7.3);
		float fin_runs = smoothstep(0.55, 0.85, sd_noise(fin_q))
			* smoothstep(0.35, 1.9, fin_p.y) * 0.8;
		// Two layers: light dust (mottle and runs) and dark engine soot. The soot is chosen at the
		// slate skirt's own value, so it greys the skirt rather than blackening it.
		float fin_dust = clamp(fin_mottle + fin_runs, 0.0, 1.0) * rf_wear;
		fin_soot *= rf_wear;
		ALBEDO = mix(ALBEDO, pc_in(rf_dust_color.rgb), fin_dust * rf_grime_depth);
		ALBEDO = mix(ALBEDO, pc_in(rf_soot_color.rgb), fin_soot * rf_grime_depth);
		float fin_grime = max(fin_dust, fin_soot);
		// The crash scorch: one sooty flank, gone once the rocket is half cleaned.
		float fin_side = dot(normalize(fin_p.xz + vec2(1e-4)), rf_scorch_dir);
		float fin_scorch = smoothstep(0.30, 0.85, fin_side + (fin_blot - 0.55) * 0.9)
			* smoothstep(2.5, 1.1, fin_p.y) * smoothstep(0.55, 1.0, rf_wear) * rf_scorch;
		ALBEDO = mix(ALBEDO, pc_in(rf_soot_color.rgb), fin_scorch * 0.75);
		// Rust: blotches biased low and toward bare metal. The fine octave only shapes the patch
		// edge up close, where there are pixels to resolve it (surface_detail rule 5); at 0.2 it
		// punched pinholes through the rust that showed the dark paint under it as black dots.
		float fin_field = sd_fbm01(fin_p * 3.3 + vec3(11.7), 3) * 0.8
			+ (sd_fbm01(fin_p * 13.0 + vec3(5.1), 2) - 0.5) * 0.12 * fin_lod
			+ rf_rust_bias + (1.0 - clamp(fin_p.y / 3.2, 0.0, 1.0)) * 0.12;
		float fin_rust = smoothstep(rf_rust_thr, rf_rust_thr + 0.03, fin_field);
		// The rust's own dark mottle comes from an INDEPENDENT noise. Taken deeper into the same
		// field it gave every patch a dark core inside a pale ring - a leopard rosette.
		float fin_core = smoothstep(0.42, 0.72, sd_fbm01(fin_p * 6.1 + vec3(2.9), 2));
		vec3 fin_rust_c = mix(pc_in(rf_rust_color.rgb), pc_in(rf_rust_deep.rgb), fin_core);
		ALBEDO = mix(ALBEDO, fin_rust_c, fin_rust);
		ROUGHNESS = clamp(ROUGHNESS + 0.12 * fin_grime + 0.2 * fin_rust, 0.0, 1.0);
	}
	// Stage 5 polished gold. At noon the sun is overhead and the whole hull side sits in ONE band of
	// the toon ramp, so lighting alone painted the gold as one flat butter-yellow (critic). Polished
	// metal gets its value structure from what it REFLECTS, not from the sun: a pale warm highlight
	// band and a darker amber-olive band, placed by the view-space normal so they slide over the
	// hull as the view moves. The grain sd_metal already put on ALBEDO is carried into both bands.
	if (rf_gold > 0.001) {
		float fin_nx = NORMAL.x;
		float fin_hi = smoothstep(rf_gold_hi_band.x - 0.05, rf_gold_hi_band.x + 0.05, fin_nx)
			* (1.0 - smoothstep(rf_gold_hi_band.y - 0.05, rf_gold_hi_band.y + 0.05, fin_nx));
		float fin_lo = smoothstep(rf_gold_lo_band.x - 0.08, rf_gold_lo_band.x + 0.08, fin_nx)
			* (1.0 - smoothstep(rf_gold_lo_band.y - 0.08, rf_gold_lo_band.y + 0.08, fin_nx));
		vec3 fin_grain = ALBEDO / max(pc_in(albedo.rgb), vec3(1e-4));
		ALBEDO = mix(ALBEDO, pc_in(rf_gold_lo.rgb) * fin_grain, fin_lo * rf_gold);
		ALBEDO = mix(ALBEDO, pc_in(rf_gold_hi.rgb) * fin_grain, fin_hi * rf_gold);
	}
"""

static func rocket_finish_shader() -> Shader:
	if _rocket_finish_shader != null:
		return _rocket_finish_shader
	var code := TOON_SHADER.code
	if code.find(_RF_DECL_AFTER) < 0 or code.find(_RF_PASS_BEFORE) < 0:
		push_error("MaterialLib.rocket_finish_shader: toon_soft.gdshader no longer contains the "
			+ "two lines the rocket finish splices at; the rocket falls back to its clean finish")
		_rocket_finish_shader = TOON_SHADER
		return _rocket_finish_shader
	code = code.replace(_RF_DECL_AFTER, _RF_DECL_AFTER + "\n" + _RF_DECL)
	code = code.replace(_RF_PASS_BEFORE, _RF_PASS + _RF_PASS_BEFORE)
	var sh := Shader.new()
	sh.code = code
	_rocket_finish_shader = sh
	return sh

# ----------------------------------------------------------------------------- rocket glints
## The stage 4-5 sparkle (RocketModel "_build_sparkle"): star.gdshader's four-point twinkle on ONE
## merged mesh, one draw call for every glint.
##
## Why not star.gdshader on a MultiMesh, which is what shipped first: star.gdshader billboards by
## rebuilding MODELVIEW_MATRIX around MODEL_MATRIX[3], and under Compatibility - the web build the
## phone runs - a MultiMesh draws its call but shows nothing, even at intensity 6 with the blink off
## (critic probe; the same material on plain QuadMesh nodes rendered fine). So the glints are one
## ordinary ArrayMesh with no instancing: all four corners of a glint sit ON its centre, UV says which
## corner each one is and UV2.x carries its blink phase, and the vertex function below opens each
## quad out in VIEW space. That is plain vertex maths, identical on both renderers.
##
## Built from star.gdshader by string rewrite, like rocket_finish_shader, so the twinkle's look stays
## the shared one: only the render_mode line gains skip_vertex_transform and vertex() is replaced.
## If an anchor stops matching this pushes an ERROR (tools/check.sh fails on it) and returns null;
## RocketModel then builds no sparkle rather than a broken one.
const _GLINT_MODE_FROM := "render_mode unshaded,"
const _GLINT_MODE_TO := "render_mode skip_vertex_transform, unshaded,"
const _GLINT_VERTEX_AT := "void vertex() {"
const _GLINT_FRAGMENT_AT := "void fragment() {"
const _GLINT_VERTEX := """// Glint size in metres at model scale 1 (RocketModel.GLINT_SIZE); scaled with the model, so the
// space map's 0.46x rocket (space_travel.gd ROCKET_SCALE) gets 0.46x glints.
uniform float rf_glint_size = 0.34;

void vertex() {
	pcolor = COLOR;
	phase = UV2.x;
	float fin_scale = length(MODEL_MATRIX[0].xyz);
	vec2 fin_corner = (UV - vec2(0.5)) * vec2(1.0, -1.0) * rf_glint_size * fin_scale;
	VERTEX = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz + vec3(fin_corner, 0.0);
	NORMAL = vec3(0.0, 0.0, 1.0);
}

"""
static var _rocket_glint_shader: Shader

static func rocket_glint_shader() -> Shader:
	if _rocket_glint_shader != null:
		return _rocket_glint_shader
	var code := STAR_SHADER.code
	var v0 := code.find(_GLINT_VERTEX_AT)
	var f0 := code.find(_GLINT_FRAGMENT_AT)
	if code.find(_GLINT_MODE_FROM) < 0 or v0 < 0 or f0 < v0:
		push_error("MaterialLib.rocket_glint_shader: star.gdshader no longer contains the lines the "
			+ "rocket glints rewrite; the rocket builds no sparkle")
		return null
	code = code.substr(0, v0) + _GLINT_VERTEX + code.substr(f0)
	code = code.replace(_GLINT_MODE_FROM, _GLINT_MODE_TO)
	var sh := Shader.new()
	sh.code = code
	_rocket_glint_shader = sh
	return sh

## glow_sprite's parameters on the glint shader. null when the shader could not be built.
static func rocket_glint(tint: Color, intensity: float, size: float, opts: Dictionary = {}) -> ShaderMaterial:
	var key := "rocketglint|%s|%.2f|%.3f|%s" % [tint.to_html(), intensity, size, str(opts)]
	if _cache.has(key):
		return _cache[key]
	var sh := rocket_glint_shader()
	if sh == null:
		return null
	var m := glow_sprite(tint, intensity, opts).duplicate() as ShaderMaterial
	m.shader = sh
	m.set_shader_parameter("rf_glint_size", size)
	_cache[key] = m
	return m
