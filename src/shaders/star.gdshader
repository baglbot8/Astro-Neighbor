// Soft additive glow sprite, camera-billboarded. Used for fireflies, sparkles, the head of a
// shooting star and stardust twinkles. Works on GPUParticles3D (uses COLOR + INSTANCE_CUSTOM.z
// as a per-particle blink phase) and on plain QuadMesh instances.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec4 tint : source_color = vec4(1.0, 0.95, 0.6, 1.0);
uniform float intensity : hint_range(0.0, 10.0) = 2.0;
uniform float softness : hint_range(0.0, 1.0) = 0.55;
uniform float core : hint_range(0.0, 1.0) = 0.35;
uniform float blink_speed = 3.0;
uniform float blink_amount : hint_range(0.0, 1.0) = 0.0;
uniform float points : hint_range(0.0, 1.0) = 0.0;
uniform float fade : hint_range(0.0, 1.0) = 1.0;

varying vec4 pcolor;
varying float phase;

void vertex() {
	pcolor = COLOR;
	phase = INSTANCE_CUSTOM.z;
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
	float d = length(p);
	float glow = smoothstep(1.0, softness, d);
	glow *= glow;
	float c = smoothstep(core, 0.0, d);
	float star = 0.0;
	if (points > 0.001) {
		float ax = abs(p.x);
		float ay = abs(p.y);
		star = (exp(-ax * 9.0) * exp(-ay * 2.2) + exp(-ay * 9.0) * exp(-ax * 2.2)) * smoothstep(1.0, 0.2, d);
		star *= points;
	}
	float blink = 1.0 - blink_amount * 0.5 * (1.0 + sin(TIME * blink_speed + phase * 6.2831853));
	float a = (glow * 0.6 + c + star) * blink * pcolor.a * fade;
	ALBEDO = tint.rgb * pcolor.rgb * intensity * a;
	ALPHA = clamp(a, 0.0, 1.0);
}
