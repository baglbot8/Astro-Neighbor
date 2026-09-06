// Subtle warm-violet vignette drawn on a full-screen ColorRect (CanvasLayer below the HUD).
shader_type canvas_item;

uniform float strength : hint_range(0.0, 1.0) = 0.3;
uniform float radius : hint_range(0.2, 1.5) = 0.72;
uniform float softness : hint_range(0.05, 1.5) = 0.55;
uniform vec4 tint : source_color = vec4(0.12, 0.06, 0.22, 1.0);

void fragment() {
	vec2 p = (UV - 0.5) * vec2(1.25, 1.0);
	float d = length(p) * 1.6;
	float v = smoothstep(radius, radius + softness, d) * strength;
	COLOR = vec4(tint.rgb, v);
}
