// Shooting-star streak: a quad oriented along the motion (x = travel direction, head at u=1).
// Bright warm head, tapering tail with a sparkly dotted pattern. Additive, unlit, no fog.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec4 head_color : source_color = vec4(1.0, 0.97, 0.85, 1.0);
uniform vec4 tail_color : source_color = vec4(0.65, 0.85, 1.0, 1.0);
uniform float intensity : hint_range(0.0, 10.0) = 3.0;
uniform float fade : hint_range(0.0, 1.0) = 1.0;
uniform float scroll = 0.0;

float hash11(float p) {
	p = fract(p * 0.1031);
	p *= p + 33.33;
	return fract(p * p * 2.0);
}

void fragment() {
	float u = UV.x;
	float v = (UV.y - 0.5) * 2.0;
	float width = mix(0.15, 1.0, pow(u, 1.6));
	float across = smoothstep(width, width * 0.2, abs(v));
	float along = pow(u, 2.2);
	float dots = 0.0;
	float cell = floor(u * 26.0 + scroll);
	float fu = fract(u * 26.0 + scroll);
	float h = hash11(cell);
	float dy = (h - 0.5) * 1.2 * width;
	float dd = length(vec2((fu - 0.5) * 0.5, (v - dy) * 1.5));
	dots = smoothstep(0.32, 0.05, dd) * step(0.35, h) * (0.3 + 0.7 * u);
	float a = (across * along * 0.8 + dots * 0.9) * fade;
	vec3 col = mix(tail_color.rgb, head_color.rgb, along);
	ALBEDO = col * intensity * a;
	ALPHA = clamp(a, 0.0, 1.0);
}
