// Vertex-colored toon with a time-based emission pulse (blinking antenna lights, lamp bulbs,
// pulsing seam lamps). pulse_mode: 0 = soft sine breathe, 1 = hard blink, 2 = steady glow.
shader_type spatial;
render_mode cull_back, depth_draw_opaque, diffuse_lambert, specular_schlick_ggx;
#include "res://src/shaders/planet_common.gdshaderinc"

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
	ALBEDO = albedo.rgb * COLOR.rgb;
	EMISSION = emission_color.rgb * emission_strength * p;
	ROUGHNESS = 0.4;
	METALLIC = 0.0;
	SPECULAR = 0.5;
}

void light() {
	float lit;
	vec3 diffuse = pc_toon_diffuse(ALBEDO, dot(NORMAL, LIGHT), ATTENUATION, ramp_softness, shade_strength, shade_tint.rgb, 0.6, LIGHT_IS_DIRECTIONAL, lit);
	DIFFUSE_LIGHT += diffuse * LIGHT_COLOR / PI;
	vec3 hv = normalize(VIEW + LIGHT);
	float ndh = max(dot(NORMAL, hv), 0.0);
	float spec = smoothstep(0.45, 0.6, pow(ndh, 80.0)) * 0.5 * lit;
	SPECULAR_LIGHT += spec * LIGHT_COLOR / PI;
}
