shader_type spatial;
render_mode blend_add, unshaded, cull_front, depth_draw_never, shadows_disabled;
// SPIKE (2026-09-21, scratch only). The air a world holds onto, seen from outside it.
//
// A shell at 1.09x the globe's radius, drawn BACK faces only and added. Looking at the middle of
// the disc you are looking through the thinnest part of the shell and it contributes nothing;
// looking at the limb you are looking along it and it stacks up. That is the actual physics of why
// a planet has a bright edge, and it costs one dot product - so the destination gets a visible halo
// at 2 degrees across, long before any surface detail is legible. On the frames it is the first
// thing that says "that dot is a WORLD".
//
// It is also the cheapest honest distance cue we have: the halo widens as you close.

uniform vec3 tint : source_color = vec3(0.42, 0.62, 0.95);
uniform vec3 sun_dir = vec3(-0.62, 0.30, 0.72);
uniform float gain : hint_range(0.0, 2.0) = 0.65;
uniform float power : hint_range(1.0, 8.0) = 3.0;

void fragment() {
	vec3 nw = normalize((MODEL_MATRIX * vec4(normalize(VERTEX), 0.0)).xyz);
	vec3 vw = normalize((INV_VIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz
		- (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz);
	// cull_front means nw faces away from us, so the limb is where |dot| is SMALL
	float limb = pow(1.0 - abs(dot(nw, vw)), power);
	float lam = dot(nw, normalize(sun_dir));
	// forward scattering: the air is far brighter on the sunlit side, which also tells you where
	// the sun is without ever drawing one
	float day = 0.12 + 0.88 * smoothstep(-0.45, 0.45, lam);
	ALBEDO = tint * limb * day * gain;
	ALPHA = 1.0;
}
