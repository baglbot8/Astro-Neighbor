// Planetary ring band: soft concentric bands with grain, lit by the sun, dimming to navy at night.
// Double sided, unlit, transparent. Mesh is a flat annulus with UV.x = normalized radius.
shader_type spatial;
render_mode cull_disabled, unshaded, depth_draw_opaque, blend_mix, fog_disabled;

#include "res://src/shaders/aces_inverse.gdshaderinc"

uniform vec3 ring_color : source_color = vec3(1.0, 0.81, 0.54);
uniform vec3 ring_shade : source_color = vec3(0.65, 0.5, 0.55);
uniform vec3 sun_dir = vec3(0.0, 1.0, 0.0);
uniform float night : hint_range(0.0, 1.0) = 0.0;
uniform vec3 night_tint : source_color = vec3(0.42, 0.47, 0.82);
uniform float opacity : hint_range(0.0, 1.0) = 0.98;
uniform float tonemap_white = 6.0;
uniform float display_cap : hint_range(0.3, 1.0) = 0.85;

varying vec3 world_normal;

float hash11(float p) {
	p = fract(p * 0.1031);
	p *= p + 33.33;
	return fract(p * p * 2.0);
}

void fragment() {
	float r = UV.x;
	// Saturn-like structure: broad inner band, dark Cassini-style gap, bright outer A-ring, faint outer edge.
	float fine = 0.86 + 0.14 * sin(r * 46.0 + sin(r * 9.0) * 3.0);
	float inner_band = smoothstep(0.0, 0.06, r) * (1.0 - smoothstep(0.42, 0.5, r));
	float a_ring = smoothstep(0.54, 0.6, r) * (1.0 - smoothstep(0.82, 0.9, r));
	float outer_wisp = smoothstep(0.9, 0.93, r) * (1.0 - smoothstep(0.95, 1.0, r)) * 0.5;
	float shape = max(max(inner_band * 0.95, a_ring), outer_wisp);
	float grain = 0.94 + 0.06 * hash11(floor(r * 260.0) + floor(UV.y * 1100.0) * 3.1);
	float a = shape * fine * opacity * grain;
	// lit face toward the sun, warm highlight on the A-ring, deeper tone on the inner band.
	// The lit/unlit spread is deliberately shallow: an edge-on ring must still read as a solid band.
	vec3 n = normalize(world_normal);
	float facing = abs(dot(n, sun_dir));
	vec3 base = mix(ring_color * 0.86, ring_color, a_ring);
	base = mix(base, vec3(1.0, 0.97, 0.9), a_ring * 0.3);
	vec3 col = mix(ring_shade, base, 0.55 + 0.45 * facing);
	col = mix(col, night_tint * 0.85, night * 0.8);
	ALBEDO = aces_inverse(cap_display(col, display_cap), tonemap_white);
	ALPHA = clamp(a, 0.0, 1.0);
}

void vertex() {
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}
