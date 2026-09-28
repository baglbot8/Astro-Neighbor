shader_type spatial;
render_mode blend_mix, unshaded, cull_disabled, depth_draw_never, shadows_disabled;
// SPIKE (2026-09-21, scratch only). The ring on the far chrome world.
//
// A flat annulus on one quad: no geometry, all in the alpha. It is here as the FAR anchor of the
// parallax ladder - it is 3 km out and it barely slides at all over a 56 s run, so the near motes
// whipping past it are what read as speed. It also gives the sky one landmark with a shape you
// cannot mistake for anything else, which is what you steer by.

uniform vec3 tint : source_color = vec3(0.72, 0.70, 0.66);
uniform float r_in : hint_range(0.1, 0.9) = 0.44;
uniform float r_out : hint_range(0.2, 1.0) = 0.86;
uniform float gain : hint_range(0.0, 2.0) = 0.60;
uniform float seed = 3.0;

float h11(float x) {
	return fract(sin(x * 91.37 + seed) * 43758.5453);
}

void fragment() {
	vec2 q = (UV - 0.5) * 2.0;
	float r = length(q);
	float band = smoothstep(r_in - 0.05, r_in + 0.03, r) * smoothstep(r_out, r_out - 0.06, r);
	// gaps: a ring is never one solid sheet, and the gaps are what make it read as a RING
	float g = 0.0;
	for (int i = 0; i < 4; i++) {
		float rg = mix(r_in, r_out, h11(float(i) * 2.7));
		g += exp(-(r - rg) * (r - rg) / 0.00055);
	}
	band *= clamp(1.0 - g * 0.85, 0.0, 1.0);
	// grain around the ring, so it is dust and not paint
	float grain = 0.72 + 0.44 * h11(floor(atan(q.y, q.x) * 26.0) + floor(r * 40.0) * 0.31);
	ALBEDO = tint * grain;
	ALPHA = band * gain;
}
