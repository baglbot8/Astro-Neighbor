// Soft toon shader — the default look for every prop, character and building.
// Two-tone lighting with a smooth ramp, tinted shadows, gentle rim and a small crisp specular.
// Environment builder may refine; keep uniform names stable (MaterialLib depends on them).
//
// Two darkness levels: `shade_floor` is the self-shaded (terminator) side, `shadow_floor` is the
// inside of a CAST shadow (ATTENUATION -> 0). Keeping them apart lets the shaded side stay soft and
// pastel while a prop still throws a shadow you can actually read, like the reference screenshots.
// Emission is scaled by the `astro_night` global (see docs/ARCHITECTURE.md 9.1): lamps and crystals
// glow at full strength at night and only faintly at noon, and never clip their hue to white.
shader_type spatial;
render_mode cull_back, depth_draw_opaque, diffuse_lambert, specular_schlick_ggx;

global uniform float astro_night;

#include "res://src/shaders/surface_detail.gdshaderinc"

// --- WEB PARITY: THE COMPATIBILITY sRGB HELPERS, INLINED -----------------------------------------
// THE CANONICAL COPY AND THE FULL WRITE-UP LIVE AT THE TOP OF src/shaders/planet_common.gdshaderinc:
// the measurement, the probe numbers (maxdiff 0), the conversion rules, and the list of masks that
// must NOT be wrapped. Read that first. They are inlined here rather than included because this is
// the shader on EVERY character, prop and building, and it has no other reason to pull in the whole
// planet ground library; keep the two copies byte-identical if either is ever changed.
//
// One-paragraph version: Compatibility (WebGL2, which the web export is forced onto and which is
// what the game is actually played on) does not sRGB-decode `source_color` uniforms on upload the
// way Forward+ does, and it sRGB-ENCODES whatever fragment() writes to ALBEDO/EMISSION. So a colour
// uniform arrives in DISPLAY space and every multiply done on it inside fragment() lands as t^2.2.
// This shader's vertex-colour path is the worst case in the game, because it multiplies by COLOR:
// MEASURED, the hub bench slats rendered F+ (201,164,110) -> C (157,62,38) and the flower-bed soil
// F+ (133,115,79) -> C (57,44,33). That is the user's "the plants are very black".
//
// `astro_compat` is 1.0 only under Compatibility (Platform._apply_renderer_parity), so every wrap
// below is the exact identity on desktop and the Forward+ reference look cannot move.
//
// MEASURED AFTER THE CONVERSION. Both of this shader's albedo paths were rendered under BOTH
// renderers in an isolated project (fixed sun, fixed ambient, nothing else in the scene, so only
// the shader could differ), on the hub bench wood, the flower-bed soil, a mid grey and a saturated
// green:
//   vertex-colour path (MaterialLib.toon_vertex_color's rewrite, COLOR carrying the colour)
//     F+ (213,163,109) (123,102,80) (172,173,179) (155,213,169)
//     C  (213,163,109) (124,102,80) (172,173,179) (156,214,170)        MAXDIFF 1
//   plain path (`albedo` uniform carrying the colour, COLOR white)
//     F+ (151,83,37) (49,32,21) (77,77,84) (26,92,34)
//     C  (151,83,37) (49,32,20) (77,77,84) (27,92,34)                  MAXDIFF 1
// In the real hub scene the near bench slat went C (156,39,19) -> C (230,204,175) against a
// Forward+ (211,169,111): the hue and the near-black are gone. It does not land ON the Forward+
// value there because the browser build renders that frame with SSAO and glow switched off and at
// 0.35 prop density (see rule (i) in planet_common) — the shader itself is at maxdiff 1.
global uniform float astro_compat;

vec3 pc_s2l(vec3 q) { return mix(q / 12.92, pow((q + vec3(0.055)) / 1.055, vec3(2.4)), step(vec3(0.04045), q)); }
vec3 pc_l2s(vec3 q) { q = max(q, vec3(0.0)); return mix(q * 12.92, 1.055 * pow(q, vec3(1.0 / 2.4)) - vec3(0.055), step(vec3(0.0031308), q)); }
vec3 pc_in_f(vec3 q, float compat) { return (compat > 0.5) ? pc_s2l(q) : q; }
vec3 pc_out_f(vec3 q, float compat) { return (compat > 0.5) ? pc_l2s(q) : q; }
// Macros, not functions, so `astro_compat` is resolved at the CALL site — a function in a shared
// include cannot see a uniform the including shader declares further down. See planet_common.
#define pc_in(q) pc_in_f((q), astro_compat)
#define pc_out(q) pc_out_f((q), astro_compat)

// R2.9 surface detail. `surface_kind`: 0 none, 1 cloth, 2 metal, 3 wood, 4 rock, 5 foliage,
// 6 rubber, 7 skin, 8 scales. Keep this list, MaterialLib.SURFACE_KINDS and the if-chain in
// fragment() in step.
//
// WARNING — THE CHAIN'S FINAL `else` IS sd_foliage, NOT sd_none. A kind id with no branch of its
// own does not fall back to "no detail", it silently renders as GRASS. Every new kind needs an
// explicit `else if`.
// Off by default so nothing changes until a material opts in. See docs/STYLE_GUIDE.md R2.9 -
// this adds material character through roughness/normal/albedo variation, never by raising
// specular into a hotspot, so it does not undo R2.6 (pastel and matte).
// ---------------------------------------------------------------------------------------------
// KNOWN BUG, NOT YET FIXED HERE - see docs/OPEN_ISSUES.md item 19. THE ALBEDO IS APPLIED TWICE.
//
// Godot 4.7 multiplies DIFFUSE_LIGHT by ALBEDO *after* light() returns. This light() composes the
// FINISHED surface colour (it mixes ALBEDO in itself), so every prop, character and building in
// the game renders albedo-squared.
//
// Verified in-engine, not inferred: a shader writing a constant DIFFUSE_LIGHT = vec3(0.20) with
// ALBEDO = (1.0, 0.5, 0.25) renders ORANGE (143,103,74), not neutral grey.
//
// Squaring is invisible on a neutral surface and catastrophic on a chromatic one, and it is worst
// in shadow where albedo is already low: a leaf green of linear (0.074, 0.342, 0.223) becomes
// (0.005, 0.117, 0.050) - saturation 0.78 -> 0.95 with red crushed to 1/255. This is the root
// cause of the user's standing "the colors are popping too much" note and of every oversaturated
// shadow the tone passes have been working around.
//
// The one-line fix is to divide the composed colour by ALBEDO before writing it. It is NOT applied
// yet because every colour in the game was authored against the doubled behaviour, so the fix
// alone leaves surfaces washed out and hue-shifted (measured: the hub's wooden bench loses its
// brown entirely). It must land together with a palette re-author, as one measured pass.
// `planet_common.gdshaderinc` already has the correct helper: `pc_light_term` + `pc_albedo_floor`.
//
// IT IS NOT A WEB-PARITY BUG, AND IT MUST NOT BE "FIXED" WITH A COMPAT KNOB. docs/OPEN_ISSUES.md 19
// and 32 both claimed Compatibility applies the albedo a DIFFERENT number of times from Forward+.
// That claim is FALSE and was measured false with a flat probe: BOTH renderers multiply
// DIFFUSE_LIGHT by ALBEDO exactly once, light() sees the same ALBEDO the engine multiplies by, and
// specular is never multiplied by albedo in either. The squaring above therefore costs Forward+
// exactly as much as it costs the web build — it is a desktop art question, tracked separately, and
// it is invisible to parity.sh. The per-shader `compat_gain` / `compat_light_boost` knobs that were
// invented for the phantom divergence have been deleted. Do not re-add one.
// ---------------------------------------------------------------------------------------------

uniform int surface_kind : hint_range(0, 8) = 0;
/// hint_range is advisory in Godot, not clamping. Values above 2 are legitimate: a near-white
/// surface sits on the ACES shoulder, so a boulder needed 3.2 to move its albedo at all.
uniform float surface_strength : hint_range(0.0, 4.0) = 1.0;
uniform float surface_lod_near : hint_range(0.5, 40.0) = 3.0;
uniform float surface_lod_far : hint_range(1.0, 80.0) = 14.0;
uniform vec3 surface_grain_dir = vec3(0.0, 1.0, 0.0);
/// Multiplies every frequency inside the chosen material. Below 1 makes the pattern coarser (so it
/// survives more distance); above 1 makes it finer (so a small part gets enough cycles across it).
uniform float surface_scale : hint_range(0.05, 8.0) = 1.0;
/// Low-frequency tonal drift. The only band that survives past ~20 m on a large surface.
uniform float surface_macro : hint_range(0.0, 0.6) = 0.0;
uniform float surface_macro_cycles : hint_range(0.2, 12.0) = 2.6;
/// "skin" only. `surface_spot_amount` weights the blobs, `surface_scale_amount` the cell walls.
uniform float surface_spot_amount : hint_range(0.0, 2.0) = 1.0;
uniform float surface_scale_amount : hint_range(0.0, 2.0) = 1.0;
/// Blob size, in cells (sd_skin's lattice is 7 cells per unit at surface_scale 1.0). Was capped at
/// 0.60, which is roughly one cell - anything that reads as a BIG spot rather than a freckle needs
/// more. 1.20 is the honest ceiling: past ~1.0 a blob can reach a fragment from two cells away and
/// sd_skin's 3x3x3 window starts clipping it.
uniform float surface_spot_radius : hint_range(0.05, 1.20) = 0.34;
/// The mean of sd_skin's spot term, subtracted so the pattern averages out instead of tinting the
/// character. IT TRACKS surface_spot_radius AND IS WRONG IF YOU CHANGE ONE WITHOUT THE OTHER —
/// dc(r) = 1 - exp(-(0.74343*r^3 + 0.52963*r^4 - 0.33228*r^5)), tabulated in surface_detail's
/// sd_skin header. MaterialLib.spot_dc() computes it, and MaterialLib.toon() sets both together;
/// this default is the value for the default radius 0.34.
uniform float surface_spot_dc : hint_range(0.0, 1.0) = 0.0342;
/// Weights knots against rings for wood. 0.55 reads as marbling; 0.15-0.25 gives combed lines.
uniform float surface_knot : hint_range(0.0, 1.0) = 0.55;

varying float v_sheen;
/// Model-space position, so surface detail is locked to the object rather than swimming through
/// world space as a character or a rocket moves.
varying vec3 v_objpos;
/// Model-space normal. sd_metal picks its brush axis from the normal it is given, so handing it
/// the view-space NORMAL makes the grain direction flip in patches as the camera orbits.
varying vec3 v_objnorm;
/// Interpolated shading normal before surface detail perturbs it. `detail_light` needs the
/// UNperturbed normal to measure how far the detail tilted it.
varying vec3 v_flat_nrm;
/// How far surface detail tilted the normal, as a signed lambert delta. See detail_light below.
varying float v_detail;

void vertex() {
	v_objpos = VERTEX;
	v_objnorm = NORMAL;
}

uniform vec4 albedo : source_color = vec4(1.0);
uniform float ramp_softness : hint_range(0.01, 1.0) = 0.32;
uniform float shade_strength : hint_range(0.0, 1.0) = 0.42;
uniform vec4 shade_tint : source_color = vec4(0.62, 0.55, 0.85, 1.0);
uniform float shade_floor : hint_range(0.0, 1.0) = 0.62;
uniform float shadow_floor : hint_range(0.0, 1.0) = 0.08;
uniform float rim_strength : hint_range(0.0, 2.0) = 0.28;
uniform vec4 rim_color : source_color = vec4(1.0, 0.97, 0.9, 1.0);
uniform float spec_strength : hint_range(0.0, 2.0) = 0.22;
uniform float spec_size : hint_range(1.0, 400.0) = 60.0;
uniform vec4 emission_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float emission_strength : hint_range(0.0, 8.0) = 0.0;
// Fraction of emission_strength left in broad daylight (astro_night = 0).
uniform float emission_day_scale : hint_range(0.0, 1.0) = 0.15;
// Brightest channel an emissive may reach before it is scaled back, hue intact (no white cutouts).
uniform float emission_cap : hint_range(0.2, 8.0) = 1.9;
uniform float roughness : hint_range(0.0, 1.0) = 0.85;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D albedo_texture : source_color, hint_default_white, filter_linear_mipmap;
uniform bool use_texture = false;
uniform vec2 uv_scale = vec2(1.0);

void fragment() {
	// DO NOT REWRITE THE NEXT LINE. MaterialLib.toon_vertex_color (src/materials/material_lib.gd:165)
	// does a literal string replace of it with `vec3 base = albedo.rgb * COLOR.rgb;` to build the
	// vertex-coloured variant that every SurfaceTool-built prop uses. Change its text and every
	// bench, flower bed and building silently loses its vertex colours.
	vec3 base = albedo.rgb;
	// Which is why the sRGB fix-up is a SEPARATE line: it has to be correct for both spellings of
	// the line above. `base` is either `albedo.rgb` or `albedo.rgb * COLOR.rgb`, so multiplying by
	// the uniform's own linearisation ratio converts the uniform's contribution and ONLY that.
	// Vertex COLOR is deliberately left alone — per the conversion rules in planet_common, vertex
	// colours, INSTANCE_CUSTOM and literals are delivered identically to both renderers and Forward+
	// already treats them as linear, so they need the pc_out on the WRITE and nothing on the read.
	// The max() guard is for a channel the artist authored as 0: pc_in(0) is 0, so the ratio is 0
	// and the channel stays 0 instead of dividing by zero.
	base *= pc_in(albedo.rgb) / max(albedo.rgb, vec3(1e-5));
	if (use_texture) {
		// NOT wrapped: `albedo_texture` is hinted `source_color`, so Godot uploads it in an sRGB
		// texture format and the decode happens in the sampler on BOTH renderers. This sample is
		// already linear either way; a pc_in here would be a second decode.
		base *= texture(albedo_texture, UV * uv_scale).rgb;
	}
	// ALBEDO is kept LINEAR through the whole of fragment() and encoded once at the very bottom, so
	// the surface-detail multiplies below still happen in linear space.
	ALBEDO = base;
	ROUGHNESS = roughness;
	METALLIC = metallic;
	// SPACE BUG, fixed. This used to be assigned in vertex(), where NORMAL is in MODEL space,
	// while light() compares it against fragment's VIEW-space NORMAL:
	//     dot(normalize(NORMAL) - normalize(v_flat_nrm), LIGHT) * 2.4
	// The difference of two unit vectors in DIFFERENT spaces has magnitude up to 2, so that term
	// was garbage that swung with the camera rather than with the surface detail — and it stayed
	// hidden only because no character had surface_kind > 0. grass_planet.gdshader and
	// planet_foliage.gdshader both already capture it here, in fragment, before NORMAL is bent by
	// the detail bump below. Same thing now.
	v_flat_nrm = NORMAL;
	v_sheen = 0.0;
	if (surface_kind > 0) {
		float lod = sd_lod(VERTEX, surface_lod_near, surface_lod_far);
		vec3 wpos = v_objpos;
		SdSurface sd = sd_none();
		vec3 onrm = normalize(v_objnorm);
		if (surface_kind == 1) { sd = sd_cloth(wpos, onrm, lod, surface_strength, surface_scale); }
		else if (surface_kind == 2) { sd = sd_metal(wpos, onrm, lod, surface_strength, surface_scale); }
		else if (surface_kind == 3) { sd = sd_wood(wpos, surface_grain_dir, lod, surface_strength, surface_scale, surface_knot); }
		else if (surface_kind == 4) { sd = sd_rock(wpos, onrm, lod, surface_strength, surface_scale); }
		else if (surface_kind == 6) { sd = sd_rubber(wpos, onrm, lod, surface_strength, surface_scale); }
		else if (surface_kind == 7) { sd = sd_skin(wpos, onrm, lod, surface_strength, surface_scale,
			surface_spot_amount, surface_scale_amount, surface_spot_radius, surface_spot_dc); }
		else if (surface_kind == 8) { sd = sd_scales(wpos, onrm, lod, surface_strength, surface_scale); }
		// 5, and anything unrecognised, lands here on FOLIAGE - not on "no detail". A new kind
		// without its own branch above renders as grass. Add the branch.
		else { sd = sd_foliage(wpos, onrm, lod, surface_strength, surface_scale); }
		// The macro band uses its own generous fade: it is the term that must survive the distance.
		v_detail = sd.height;
		ALBEDO *= sd.tint * sd_macro(wpos, surface_macro_cycles, surface_macro,
			sd_lod(VERTEX, surface_lod_far, surface_lod_far * 4.0));
		ROUGHNESS = clamp(ROUGHNESS + sd.rough, 0.0, 1.0);
		NORMAL = normalize(NORMAL + sd.bump);
		v_sheen = sd.aniso;
	}
	vec3 em = pc_in(emission_color.rgb) * emission_strength * mix(emission_day_scale, 1.0, astro_night);
	float peak = max(em.r, max(em.g, em.b));
	EMISSION = pc_out((peak > emission_cap) ? em * (emission_cap / peak) : em);
	// The one encode of the frame. Everything above ran in linear on both renderers; Compatibility
	// applies its own srgb_to_linear() to this value after fragment() returns, and pc_out is the
	// exact inverse of that, so the two renderers land on the same linear albedo. Identity on
	// Forward+. light() below still sees the linear ALBEDO on both renderers (measured: light()
	// sees the same ALBEDO the engine goes on to multiply DIFFUSE_LIGHT by, exactly once).
	ALBEDO = pc_out(ALBEDO);
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float lit = smoothstep(-ramp_softness, ramp_softness, ndl) * ATTENUATION;
	vec3 shadow_col = ALBEDO * mix(vec3(1.0), pc_in(shade_tint.rgb), shade_strength);
	float floor_level = mix(shadow_floor, shade_floor, ATTENUATION);
	vec3 diffuse = mix(shadow_col * floor_level, ALBEDO, lit);
	// The toon ramp SATURATES: `mix(..., ALBEDO, lit)` returns exactly ALBEDO once lit == 1, which
	// is most of a sunlit surface. So a perturbed NORMAL changes nothing outside a narrow band at
	// the terminator, and the whole `bump` third of the surface-detail library was dead in daylight.
	// This puts the detail's slope back as a multiplier centred on 1.0 and hard-clamped, so it adds
	// no energy and cannot make a hotspot - R2.6 holds, nothing here raises specular.
	float detail_light = 1.0;
	if (surface_kind > 0) {
		float slope = dot(normalize(NORMAL) - normalize(v_flat_nrm), LIGHT) * 2.4 + v_detail * 0.6;
		detail_light = clamp(1.0 + slope, 0.80, 1.22);
	}
	DIFFUSE_LIGHT += diffuse * detail_light * LIGHT_COLOR / PI;

	vec3 h = normalize(VIEW + LIGHT);
	float ndh = max(dot(NORMAL, h), 0.0);
	// Widen the toon lobe by ROUGHNESS so the `rough` half of every sd_* result actually does
	// something. Without this the toon pipeline never reads ROUGHNESS at all (only Godot's ambient
	// sky reflection does), so a rock's roughness budget was being spent for nothing.
	float rough_size = spec_size * mix(1.0, 0.35, clamp(ROUGHNESS, 0.0, 1.0));
	float spec = smoothstep(0.5, 0.78, pow(ndh, rough_size)) * spec_strength * lit;
	SPECULAR_LIGHT += spec * LIGHT_COLOR / PI;

	float rim = 1.0 - max(dot(NORMAL, VIEW), 0.0);
	rim = smoothstep(0.6, 0.9, rim) * rim_strength * lit;
	SPECULAR_LIGHT += rim * pc_in(rim_color.rgb) * LIGHT_COLOR / PI;

	// R2.9 sheen: broad and low-amplitude, so metal reads as metal without a blown highlight.
	if (v_sheen > 0.001) {
		float sheen = (surface_kind == 1)
			? sd_cloth_sheen(NORMAL, VIEW, v_sheen)
			: sd_sheen(NORMAL, VIEW, LIGHT, v_sheen);
		SPECULAR_LIGHT += sheen * lit * LIGHT_COLOR / PI;
	}
}
