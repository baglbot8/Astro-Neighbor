// Faceted glowing crystal: flat facets from screen-space derivatives, view-dependent inner glow
// (fresnel) that reads as translucency, slow pulse, crisp specular. Used by crystal clusters,
// mushroom-tree spots, stardust shards and crystal chunks.
//
// TWO BUGS FIXED HERE (the stardust shard rendered as a flat unlit cream card, rgb(240,229,194),
// hue 43 / saturation 0.19, against an authored amber #f7b928):
//
// 1. THE FLAT NORMAL POINTED AWAY FROM THE CAMERA. `cross(dFdx(VERTEX), dFdy(VERTEX))` is the
//    geometric normal in VIEW space, but under Vulkan screen Y runs downward, so the cross product
//    comes out as -Z_view — i.e. facing away from the viewer — on every front face. Two things then
//    broke at once: the fresnel term `1 - clamp(dot(n, VIEW), 0, 1)` clamped to 1 EVERYWHERE, so the
//    rim glow became a flat full-strength wash over the whole crystal (that is the cream), and it was
//    identical on every facet, so the faceting was invisible and the shard read as one flat plane.
//    The normal is now flipped to face the viewer.
// 2. THE ALBEDO WAS APPLIED TWICE. See pc_light_term in planet_common.gdshaderinc.
//
// The emission is also capped and scaled by daylight now, the way toon_soft.gdshader does it, so a
// collectible glows at night without bleaching its own hue out at noon.
shader_type spatial;
render_mode cull_back, depth_draw_opaque, diffuse_lambert, specular_schlick_ggx;
#include "res://src/shaders/planet_common.gdshaderinc"

global uniform float astro_night;

uniform vec4 albedo : source_color = vec4(0.55, 0.85, 1.0, 1.0);
uniform vec4 glow_color : source_color = vec4(0.4, 0.9, 1.0, 1.0);
uniform float glow_strength : hint_range(0.0, 8.0) = 2.2;
uniform float core_glow : hint_range(0.0, 2.0) = 0.35;
uniform float pulse_speed = 1.3;
uniform float pulse_amount : hint_range(0.0, 1.0) = 0.25;
uniform bool faceted = true;
uniform float ramp_softness : hint_range(0.01, 1.0) = 0.2;
uniform float shade_strength : hint_range(0.0, 1.0) = 0.3;
// Low-chroma cool shade tint (was a fully saturated lavender): a chromatic tint multiplies the weak
// channel of an already chromatic albedo down again, which reads as a saturation boost, not a shade.
uniform vec4 shade_tint : source_color = vec4(0.74, 0.72, 0.82, 1.0);
uniform float shade_floor : hint_range(0.0, 1.0) = 0.55;
// Fraction of glow_strength left in broad daylight. A collectible still needs to catch the eye at
// noon, so this is much higher than toon_soft's 0.15 — but not 1.0, which is what bleached the
// shard's amber into cream. Measured: 0.42 left the shard at S 0.42; the day product is now
// glow_strength 1.3 x 0.16, which matches the S 0.55 amber measured at 0.7 x 0.30 but leaves the
// NIGHT emission (unscaled) above the environment's glow threshold of 1.15, so a collectible finally
// blooms after dark instead of sitting there as a dull tan pebble.
uniform float emission_day_scale : hint_range(0.0, 1.0) = 0.16;
// Brightest channel the emission may reach before it is scaled back with its hue intact. Without
// this the rim term clips all three channels and the crystal turns into a white cut-out.
uniform float emission_cap : hint_range(0.1, 8.0) = 1.6;
uniform float spec_strength : hint_range(0.0, 3.0) = 1.0;

varying vec3 v_world_pos;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 n = NORMAL;
	if (faceted) {
		vec3 g = normalize(cross(dFdx(VERTEX), dFdy(VERTEX)));
		// Face the viewer (see note 1 at the top). VIEW points from the fragment to the camera.
		n = (dot(g, VIEW) < 0.0) ? -g : g;
		NORMAL = n;
	}
	float fres = pow(1.0 - clamp(dot(n, VIEW), 0.0, 1.0), 3.0);
	float phase = pc_hash31(floor(v_world_pos * 0.5)) * 6.28;
	float pulse = 1.0 + pulse_amount * sin(TIME * pulse_speed + phase);
	ALBEDO = pc_albedo_floor(albedo.rgb * COLOR.rgb);
	vec3 glow = glow_color.rgb * glow_strength * (core_glow + fres) * pulse
		* mix(emission_day_scale, 1.0, astro_night);
	// Hue-preserving cap: scale the whole colour by its brightest channel instead of clipping.
	float peak = max(glow.r, max(glow.g, glow.b));
	EMISSION = glow * (peak > emission_cap ? emission_cap / peak : 1.0);
	ROUGHNESS = 0.2;
	METALLIC = 0.0;
	SPECULAR = 0.8;
}

void light() {
	float lit;
	vec3 diffuse = pc_toon_diffuse(ALBEDO, dot(NORMAL, LIGHT), ATTENUATION, ramp_softness, shade_strength, shade_tint.rgb, shade_floor, LIGHT_IS_DIRECTIONAL, lit);
	DIFFUSE_LIGHT += pc_light_term(diffuse * LIGHT_COLOR / PI, ALBEDO);
	vec3 hv = normalize(VIEW + LIGHT);
	float ndh = max(dot(NORMAL, hv), 0.0);
	float spec = smoothstep(0.4, 0.55, pow(ndh, 160.0)) * spec_strength * lit;
	SPECULAR_LIGHT += spec * LIGHT_COLOR / PI;
}
