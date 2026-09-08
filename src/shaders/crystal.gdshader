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
// WEB PARITY. The full write-up, the probe numbers and the conversion recipe are at the top of the
// include above; `pc_in` / `pc_out` come from there and this is the uniform they read. Compatibility
// hands a `source_color` uniform to fragment() in DISPLAY space and sRGB-ENCODES whatever fragment()
// writes to ALBEDO/EMISSION, so a shader that does arithmetic in between — and this one multiplies
// the albedo by the vertex colour, and the glow by three separate scalars — lands every one of those
// multiplies in the wrong space. `astro_compat` is 1.0 only under Compatibility, so every wrap below
// is the exact identity on desktop and the Forward+ look cannot move.
//
// MEASURED on res://showcase/planet_shard.tscn — the close-up of a stardust shard, which is this
// shader's largest on-screen surface — scored on a magenta-difference mask of its own pixels, two
// independent capture configurations (different RNG seed, different capture time, so the orbit puts
// the shard at a different angle). Forward+ against Compatibility:
//   config a (seed 7, t=4.0s, 27,026 px)    before  MAE 4.33  p95  8.0     after  MAE 2.71  p95 5.0
//   config b (seed 13, t=5.5s, 19,354 px)   before  MAE 5.02  p95 11.3     after  MAE 3.21  p95 7.7
// FORWARD+ DID NOT MOVE: byte-identical over the mask before and after, MAE 0.00, on both configs.
//
// THAT IS AN IMPROVEMENT OF 1.6x AND IT DOES NOT CLEAR THE PROJECT'S <= 2.0 SHADER GATE. Read the
// decomposition before touching anything, because the part that is left is NOT this file's colour
// maths, and three of this project's four previous parity attempts died by adding a constant at
// exactly this point. Peeling the two non-albedo terms off, same mask, config a:
//   as shipped (glossy: SPECULAR 0.8, ROUGHNESS 0.2)      before 4.33   after 2.71   p95 5.0
//   + no environment reflection (SPECULAR 0, ROUGH 1)     before 3.27   after 1.28   p95 2.0
//   + no emission                                         before 3.27   after 1.22   p95 1.7
//   + no light() specular highlight                       before 3.08   after 0.93   p95 1.3, max 39.7
// The shard is a GLOSSY, EMISSIVE object, so two engine paths that this conversion does not touch
// are reflecting into it: the environment specular, which samples the sky radiance — and every
// `shader_type sky` shader is FROZEN this round because that path's transfer is col^1.28 rather
// than a clean decode (planet_common rule (e)) — and the specular highlight, which Compatibility
// renders weaker on 1.4% of the mask (F+ (209,176,95) against C (209,173,63), IDENTICALLY before
// and after this change, so it is not the conversion's). Exclude those 386 pixels and the rest of
// the shard reads MAE 0.77 with a region SAT gap of 0.0077.
//
// The region SAT gap is 0.0251 -> 0.0253 as shipped and 0.0013 -> 0.0096 with the glossy terms off.
// The direction is worth stating plainly: the conversion fixes RED and GREEN (mean signed error
// (+1.51, +2.97, +0.57) -> (-0.08, +0.33, -2.15) code values) and leaves BLUE about two codes low.
// Blue is amber #d99512's near-zero channel — linear 0.0057, which is in the toe of the sRGB curve
// and is also where the sky's ambient and the specular tail land hardest. It was NOT worth a knob:
// a probe that decoded ALBEDO again inside light() (the obvious "fix") made everything worse -
// MAE 8.85, SAT gap 0.0419 - which also settles, for this shader, that Compatibility hands light()
// the DECODED albedo, exactly as planet_common says. light() is correct as it stands.
global uniform float astro_compat;

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
	// COLOR is the vertex colour and is deliberately NOT wrapped: per rule (c) of the recipe, vertex
	// colours arrive identically on both renderers and Forward+ already treats them as linear. Only
	// the `albedo` uniform needs the decode, and only the WRITE needs the encode. pc_albedo_floor
	// stays INSIDE the encode because it is a linear-space clamp (pc_light_term divides by ALBEDO,
	// and the floor is what stops that quotient exploding on a zero channel).
	ALBEDO = pc_out(pc_albedo_floor(pc_in(albedo.rgb) * COLOR.rgb));
	vec3 glow = pc_in(glow_color.rgb) * glow_strength * (core_glow + fres) * pulse
		* mix(emission_day_scale, 1.0, astro_night);
	// Hue-preserving cap: scale the whole colour by its brightest channel instead of clipping.
	float peak = max(glow.r, max(glow.g, glow.b));
	// `emission_cap` is 1.6, so this write can leave [0, 1] and rule (g)'s caveat applies: pc_l2s is
	// not the exact inverse of the engine's decode above 1.0. It is still the right call here — the
	// term is capped, the cap is hue-preserving, and leaving the glow unwrapped would put the ENTIRE
	// emission a decode out on Compatibility instead of a fraction of the over-range tail.
	EMISSION = pc_out(glow * (peak > emission_cap ? emission_cap / peak : 1.0));
	ROUGHNESS = 0.2;
	METALLIC = 0.0;
	SPECULAR = 0.8;
}

void light() {
	float lit;
	vec3 diffuse = pc_toon_diffuse(ALBEDO, dot(NORMAL, LIGHT), ATTENUATION, ramp_softness, shade_strength, pc_in(shade_tint.rgb), shade_floor, LIGHT_IS_DIRECTIONAL, lit);
	DIFFUSE_LIGHT += pc_light_term(diffuse * LIGHT_COLOR / PI, ALBEDO);
	vec3 hv = normalize(VIEW + LIGHT);
	float ndh = max(dot(NORMAL, hv), 0.0);
	float spec = smoothstep(0.4, 0.55, pow(ndh, 160.0)) * spec_strength * lit;
	SPECULAR_LIGHT += spec * LIGHT_COLOR / PI;
}
