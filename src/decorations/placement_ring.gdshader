// Animated dashed ring drawn on the ground under the placement ghost.
// The mesh is rebuilt as an annulus conformed to the planet surface (PlacementController) whenever
// the target moves, so the ring hugs hills and crater rims instead of hovering.
// UV.x = angle 0..1, UV.y = 0 inner .. 1 outer.
//
// The band brightness is rescaled HUE-PRESERVING against `color_cap` (same trick as
// src/shaders/toon_soft.gdshader): without it `tint * (1 + glow)` clipped every channel and the
// "free" ring lost its cyan identity to white, and the "blocked" ring lost its red.
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, unshaded, shadows_disabled;

uniform vec4 tint : source_color = vec4(0.62, 0.95, 1.0, 1.0);
uniform float dashes = 20.0;
uniform float dash_fill : hint_range(0.05, 0.95) = 0.55;
uniform float spin_speed = 0.22;
uniform float softness : hint_range(0.001, 0.5) = 0.14;
uniform float glow : hint_range(0.0, 3.0) = 0.55;
// Brightest channel the ring may reach. Slightly over 1.0 so it still catches a little bloom.
uniform float color_cap : hint_range(0.2, 3.0) = 1.12;

void fragment() {
	float a = fract(UV.x + TIME * spin_speed);
	float d = fract(a * dashes);
	// dash mask with soft ends
	float m = smoothstep(0.0, softness, d) * (1.0 - smoothstep(dash_fill - softness, dash_fill, d));
	// soft band across the ring width
	float band = smoothstep(0.0, 0.45, UV.y) * (1.0 - smoothstep(0.55, 1.0, UV.y));
	float pulse = 0.82 + 0.18 * sin(TIME * 3.0);
	float alpha = m * band * tint.a * pulse;
	vec3 c = tint.rgb * (1.0 + glow * band);
	float peak = max(c.r, max(c.g, c.b));
	ALBEDO = (peak > color_cap) ? c * (color_cap / peak) : c;
	ALPHA = clamp(alpha, 0.0, 1.0);
}
