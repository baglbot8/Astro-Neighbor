shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never, shadows_disabled;
// SPIKE (2026-09-21, scratch only). A LANTERN ON THE LANE.
//
// The route is already called "the Lantern Lane" in safari_cast.gd and nothing in the scene had
// ever been a lantern. Now the lane is marked by gates of them, in pairs, receding to a point - and
// a corridor of lights converging on a vanishing point is the single strongest "this is which way
// I am going" picture there is. It is also the cosy half of the brief: the user called the old
// version "too serious, empty", and a warm amber light every couple of seconds is the answer.
//
// One camera-facing quad, a soft core and a four-point glint, additive. No texture.

uniform vec3 tint : source_color = vec3(1.00, 0.68, 0.32);
uniform float core : hint_range(0.02, 0.5) = 0.13;
// WAVE 3 (G5, R11): the four-point lens glint is off by default. It was the one camera-lens effect
// left on the pad, and the game draws its lamps as soft round lights, not photographs of them.
uniform float glint : hint_range(0.0, 1.0) = 0.0;
uniform float gain : hint_range(0.0, 3.0) = 1.0;

void vertex() {
	// full camera-facing billboard, keeping the instance's own scale
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		INV_VIEW_MATRIX[0] * length(MODEL_MATRIX[0].xyz),
		INV_VIEW_MATRIX[1] * length(MODEL_MATRIX[1].xyz),
		INV_VIEW_MATRIX[2],
		MODEL_MATRIX[3]);
}

void fragment() {
	vec2 q = (UV - 0.5) * 2.0;
	float r = length(q);
	float halo = exp(-r * r / 0.26) * 0.42;
	float c = exp(-r * r / (core * core)) * 1.25;
	// the glint: two soft bars, so a lantern at a distance is a star and not a dot
	float bar = exp(-(q.y * q.y) / 0.0022) * exp(-(q.x * q.x) / 0.62)
		+ exp(-(q.x * q.x) / 0.0022) * exp(-(q.y * q.y) / 0.62);
	vec3 col = tint * (halo + c) + mix(tint, vec3(1.0), 0.45) * bar * glint * 0.55;
	col *= smoothstep(1.0, 0.72, r);
	ALBEDO = col * gain;
	ALPHA = 1.0;
}
