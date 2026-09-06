// Placement preview ghost. Translucent hologram of the item with a bright fresnel edge and a slow
// scan band travelling up the shape, so the silhouette stays readable against grass or metal ground.
// tint is cyan-white when the spot is free and red when it is blocked (PlacementController tweens it).
//
// The lit colour is rescaled HUE-PRESERVING against `color_cap` (same trick as
// src/shaders/toon_soft.gdshader). Without it the fresnel rim multiplied the tint past 1.0 on every
// channel, so both the free and the blocked ghost bleached to the same white outline.
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, unshaded, shadows_disabled;

uniform vec4 tint : source_color = vec4(0.62, 0.95, 1.0, 1.0);
uniform float fill : hint_range(0.0, 1.0) = 0.3;
uniform float edge : hint_range(0.0, 4.0) = 1.6;
uniform float fresnel_power : hint_range(0.5, 8.0) = 2.2;
uniform float scan_speed = 1.0;
uniform float scan_strength : hint_range(0.0, 1.0) = 0.3;
uniform float color_cap : hint_range(0.2, 3.0) = 1.1;

varying vec3 v_local;

void vertex() {
	v_local = VERTEX;
}

void fragment() {
	float f = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), fresnel_power);
	float scan = 0.5 + 0.5 * sin(v_local.y * 9.0 - TIME * scan_speed * 6.0);
	float a = fill + f * edge + scan * scan_strength * 0.25;
	vec3 c = tint.rgb * (0.55 + f * 0.9 + scan * 0.2);
	float peak = max(c.r, max(c.g, c.b));
	ALBEDO = (peak > color_cap) ? c * (color_cap / peak) : c;
	ALPHA = clamp(a, 0.0, 0.95) * tint.a;
}
