// Additive star streaks for the rocket's cruise through space.
//
// The particle process material sets `align_y`, which points each particle's local +Y along its
// velocity. This shader then billboards the quad *around that axis* so a streak always faces the
// camera while staying aligned with the direction of travel — the hyperspace look, without needing
// the particle system to know where the camera is.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec4 tint : source_color = vec4(0.82, 0.90, 1.0, 1.0);
uniform float intensity : hint_range(0.0, 8.0) = 2.6;
uniform float core_width : hint_range(0.02, 1.0) = 0.30;

varying vec4 pcolor;

void vertex() {
	pcolor = COLOR;
	vec3 origin = MODEL_MATRIX[3].xyz;
	vec3 axis = MODEL_MATRIX[1].xyz;
	float len_y = length(axis);
	if (len_y < 0.0001) {
		axis = vec3(0.0, 1.0, 0.0);
		len_y = 1.0;
	}
	axis /= len_y;
	vec3 to_cam = INV_VIEW_MATRIX[3].xyz - origin;
	vec3 right = cross(axis, to_cam);
	if (dot(right, right) < 0.000001) {
		right = vec3(1.0, 0.0, 0.0);
	}
	right = normalize(right) * length(MODEL_MATRIX[0].xyz);
	vec3 fwd = normalize(cross(right, axis));
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		vec4(right, 0.0),
		vec4(axis * len_y, 0.0),
		vec4(fwd, 0.0),
		vec4(origin, 1.0));
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float across = smoothstep(1.0, core_width, abs(uv.x));
	float along = smoothstep(1.0, 0.0, abs(uv.y));
	float a = across * across * along * pcolor.a;
	ALBEDO = tint.rgb * pcolor.rgb * intensity * a;
	ALPHA = clamp(a, 0.0, 1.0);
}
