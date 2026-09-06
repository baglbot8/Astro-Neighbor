// Soft radial blob shadow under characters (readability aid on top of real shadows).
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

uniform vec4 color : source_color = vec4(0.12, 0.09, 0.28, 0.5);
uniform float softness : hint_range(0.05, 1.0) = 0.55;
uniform float strength : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec2 d = UV - vec2(0.5);
	float r = length(d) * 2.0;
	float a = 1.0 - smoothstep(1.0 - softness, 1.0, r);
	ALBEDO = color.rgb;
	ALPHA = a * a * color.a * strength;
}
