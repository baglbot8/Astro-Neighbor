// Soft exhaust smoke for the rocket and the pad's dust ring.
//
// Lit spheres read as a bunch of grey balls — exactly the "bubbly" look docs/STYLE_GUIDE.md calls
// out. This is a camera-facing quad with a soft round falloff and a top-lit gradient instead: many
// of them overlap into one soft mass with a defined silhouette and no visible ball edges.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

uniform vec4 lit_color : source_color = vec4(0.80, 0.78, 0.75, 1.0);
uniform vec4 shade_color : source_color = vec4(0.40, 0.38, 0.45, 1.0);
uniform float edge_softness : hint_range(0.05, 1.0) = 0.55;
uniform float opacity : hint_range(0.0, 1.0) = 1.0;

varying vec4 pcolor;

void vertex() {
	pcolor = COLOR;
	// Camera billboard that keeps the instance's own scale (particles set it per puff).
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(
		vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
		vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
		vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
		vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float r = length(p);
	float a = smoothstep(1.0, 1.0 - edge_softness, r);
	a *= a;
	// Top-lit: the sun side of a puff is pale, the underside keeps the scene's cool shadow tint.
	float up = clamp(0.58 - p.y * 0.42, 0.0, 1.0);
	ALBEDO = mix(shade_color.rgb, lit_color.rgb, up) * pcolor.rgb;
	ALPHA = clamp(a * pcolor.a * opacity, 0.0, 1.0);
}
