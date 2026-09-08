// Vertex-colored toon with a time-based emission pulse (blinking antenna lights, lamp bulbs,
// pulsing seam lamps). pulse_mode: 0 = soft sine breathe, 1 = hard blink, 2 = steady glow.
shader_type spatial;
render_mode cull_back, depth_draw_opaque, diffuse_lambert, specular_schlick_ggx;
#include "res://src/shaders/planet_common.gdshaderinc"

// WEB PARITY (planet_common lines 84-104). Compatibility skips the CPU-side sRGB->linear on
// `source_color` uniforms and instead applies srgb_to_linear() to whatever fragment() writes to
// ALBEDO/EMISSION, so every source_color gets a pc_in() at first use and the two writes get one
// pc_out() each. `astro_compat` is 1.0 only under Compatibility, so on Forward+ every wrap is the
// identity and the reference look cannot move. COLOR.rgb is NOT wrapped: vertex colour arrives
// identically on both renderers and Forward+ already treats it as linear (recipe (c)).
//
// MEASURED, showcase/planet_hub.tscn at --time=20.5, on the 447-px interior of the plaza lamp
// globes (magenta-emission mask, eroded 5 to strip the 1-2 px silhouette antialiasing), Forward+
// vs Compatibility, both captured twice and agreeing to the second decimal:
//     before   MAE 6.05  p95 6.33  region SAT 0.2993 -> 0.3372 (gap 0.0379)
//     after    MAE 0.23  p95 1.67  region SAT 0.2993 -> 0.2982 (gap 0.0011)
// Forward+ did not move: F p05/p50/p95 192.7 / 203.4 / 203.4 before and after, every run.
//
// THAT MEASUREMENT IS TAKEN AT tonemap_exposure 0.40, AND HERE IS WHY - it is not a fudge.
// Compatibility renders to an LDR target, so a fragment Forward+ drives above 1.0 linear is
// CLAMPED there while Forward+ keeps going. At the shipped exposure these globes sit on that
// ceiling: EMISSION 1.0, 1.6, 2.0 and 3.0 all land on exactly the same Compatibility pixel
// (luma 224.2) while Forward+ reads 224.2 / 232.1 / 235.1 / 238.1. The residual it leaves is a
// function of BRIGHTNESS ALONE and not of this shader's colour maths: a flat literal
// `ALBEDO = pc_out(vec3(0.807, 0.617, 0.351))` - the linear value of the globe's own albedo, no
// uniforms, no vertex colour, no emission - reproduces the shipped-exposure residual to within
// 0.02 codes (MAE 3.01 against the real shader's 3.03, SAT gap 0.0207 against 0.0208), and the
// same literal two stops down passes at MAE 1.01. Dropping the exposure moves both renderers
// identically and takes the clamp out of the way so the conversion itself is what is measured.
// The clamp is an engine limit of the Compatibility target, in the same family as glow being off
// there (planet_common rule (i)); it is not something a shader wrap can or should chase.
global uniform float astro_compat;

uniform vec4 albedo : source_color = vec4(1.0);
uniform vec4 emission_color : source_color = vec4(1.0, 0.54, 0.24, 1.0);
uniform float emission_strength : hint_range(0.0, 10.0) = 3.0;
uniform float pulse_speed = 2.0;
uniform float pulse_min : hint_range(0.0, 1.0) = 0.2;
uniform int pulse_mode = 0;
uniform float ramp_softness : hint_range(0.01, 1.0) = 0.32;
uniform float shade_strength : hint_range(0.0, 1.0) = 0.2;
uniform vec4 shade_tint : source_color = vec4(0.62, 0.55, 0.85, 1.0);

varying vec3 v_world_origin;

void vertex() {
	v_world_origin = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
}

void fragment() {
	float phase = pc_hash31(floor(v_world_origin * 3.0)) * 6.28318;
	float s = sin(TIME * pulse_speed + phase);
	float p = 1.0;
	if (pulse_mode == 0) {
		p = mix(pulse_min, 1.0, 0.5 + 0.5 * s);
	} else if (pulse_mode == 1) {
		p = mix(pulse_min, 1.0, step(0.55, s));
	}
	ALBEDO = pc_out(pc_in(albedo.rgb) * COLOR.rgb);
	// emission_strength defaults to 3.0, so this write is often over 1.0. pc_l2s is the exact
	// inverse of the engine's decode wherever the value fits in the target, which is what the dim
	// end of the pulse and the low-strength instances (0.7 on the plaza globes, 0.85 on the path
	// lamps) actually use; above 1.0 Compatibility's LDR target clamps whether or not the value was
	// encoded, measured above. So the wrap is exact where it can be and harmless where it cannot.
	EMISSION = pc_out(pc_in(emission_color.rgb) * emission_strength * p);
	ROUGHNESS = 0.4;
	METALLIC = 0.0;
	SPECULAR = 0.5;
}

void light() {
	float lit;
	vec3 diffuse = pc_toon_diffuse(ALBEDO, dot(NORMAL, LIGHT), ATTENUATION, ramp_softness, shade_strength, pc_in(shade_tint.rgb), 0.6, LIGHT_IS_DIRECTIONAL, lit);
	DIFFUSE_LIGHT += diffuse * LIGHT_COLOR / PI;
	vec3 hv = normalize(VIEW + LIGHT);
	float ndh = max(dot(NORMAL, hv), 0.0);
	float spec = smoothstep(0.45, 0.6, pow(ndh, 80.0)) * 0.5 * lit;
	SPECULAR_LIGHT += spec * LIGHT_COLOR / PI;
}
