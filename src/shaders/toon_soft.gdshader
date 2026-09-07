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

// R2.9 surface detail. `surface_kind`: 0 none, 1 cloth, 2 metal, 3 wood, 4 rock, 5 foliage,
// 6 rubber.
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
// ---------------------------------------------------------------------------------------------

uniform int surface_kind : hint_range(0, 7) = 0;
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
/// Weights knots against rings for wood. 0.55 reads as marbling; 0.15-0.25 gives combed lines.
uniform float surface_spot_amount : hint_range(0.0, 2.0) = 1.0;
uniform float surface_scale_amount : hint_range(0.0, 2.0) = 1.0;
uniform float surface_spot_radius : hint_range(0.05, 0.60) = 0.34;
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
	vec3 base = albedo.rgb;
	if (use_texture) {
		base *= texture(albedo_texture, UV * uv_scale).rgb;
	}
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
			surface_spot_amount, surface_scale_amount, surface_spot_radius); }
		else { sd = sd_foliage(wpos, onrm, lod, surface_strength, surface_scale); }
		// The macro band uses its own generous fade: it is the term that must survive the distance.
		v_detail = sd.height;
		ALBEDO *= sd.tint * sd_macro(wpos, surface_macro_cycles, surface_macro,
			sd_lod(VERTEX, surface_lod_far, surface_lod_far * 4.0));
		ROUGHNESS = clamp(ROUGHNESS + sd.rough, 0.0, 1.0);
		NORMAL = normalize(NORMAL + sd.bump);
		v_sheen = sd.aniso;
	}
	vec3 em = emission_color.rgb * emission_strength * mix(emission_day_scale, 1.0, astro_night);
	float peak = max(em.r, max(em.g, em.b));
	EMISSION = (peak > emission_cap) ? em * (emission_cap / peak) : em;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float lit = smoothstep(-ramp_softness, ramp_softness, ndl) * ATTENUATION;
	vec3 shadow_col = ALBEDO * mix(vec3(1.0), shade_tint.rgb, shade_strength);
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
	SPECULAR_LIGHT += rim * rim_color.rgb * LIGHT_COLOR / PI;

	// R2.9 sheen: broad and low-amplitude, so metal reads as metal without a blown highlight.
	if (v_sheen > 0.001) {
		float sheen = (surface_kind == 1)
			? sd_cloth_sheen(NORMAL, VIEW, v_sheen)
			: sd_sheen(NORMAL, VIEW, LIGHT, v_sheen);
		SPECULAR_LIGHT += sheen * lit * LIGHT_COLOR / PI;
	}
}
