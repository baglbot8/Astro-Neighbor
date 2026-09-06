// Planet water shell: two-tone by depth (baked per-vertex depth in COLOR.r + screen depth), moving
// wave normals, wobbling foam line at the shoreline (depth-texture based), light wave streaks,
// twinkling sparkles, fresnel transparency. Extras: emissive glow (violet rivers), oil sheen (chrome).
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_schlick_ggx;
#include "res://src/shaders/planet_common.gdshaderinc"

uniform vec4 shallow_color : source_color = vec4(0.31, 0.76, 0.97, 1.0);
uniform vec4 deep_color : source_color = vec4(0.12, 0.53, 0.90, 1.0);
uniform vec4 foam_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 glow_color : source_color = vec4(0.243, 0.776, 1.0, 1.0);
uniform float glow_strength = 0.0;
uniform float sheen_strength = 0.0;
uniform float alpha_shallow = 0.62;
uniform float alpha_deep = 0.93;
uniform float deep_range = 1.3;
uniform float foam_width = 0.28;
uniform float wave_scale = 0.9;
uniform float wave_speed = 0.35;
uniform float wave_strength = 0.35;
uniform float streak_strength = 0.22;
uniform float sparkle_strength = 1.6;
uniform float bob = 0.02;
uniform float ramp_softness : hint_range(0.01, 1.0) = 0.4;
uniform float shade_strength : hint_range(0.0, 1.0) = 0.3;
uniform vec4 shade_tint : source_color = vec4(0.62, 0.55, 0.85, 1.0);
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;

varying vec3 v_world_pos;
varying vec3 v_world_nrm;
varying float v_depth;

void vertex() {
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float bobble = sin(TIME * 1.1 + dot(wp, vec3(0.9, 0.4, 0.6))) * bob;
	VERTEX += NORMAL * bobble;
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_nrm = normalize(mat3(MODEL_MATRIX) * NORMAL);
	v_depth = COLOR.r * 4.0;   // baked: meters of terrain below the water surface (0..4 m)
}

void fragment() {
	vec3 wp = v_world_pos;
	vec3 dir = normalize(wp);
	vec3 t = normalize(cross(dir, abs(dir.y) < 0.95 ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0)));
	vec3 b = cross(dir, t);

	// --- wave normal from scrolled 3D noise (finite-difference gradient along the tangent frame) ---
	vec3 p1 = wp * wave_scale + vec3(TIME * wave_speed, TIME * wave_speed * 0.35, 0.0);
	vec3 p2 = wp * wave_scale * 2.3 - vec3(0.0, TIME * wave_speed * 0.8, TIME * wave_speed * 0.6);
	float e = 0.09;
	float n0 = pc_noise3(p1) + 0.5 * pc_noise3(p2);
	float nt = pc_noise3(p1 + t * e * wave_scale) + 0.5 * pc_noise3(p2 + t * e * wave_scale * 2.3);
	float nb = pc_noise3(p1 + b * e * wave_scale) + 0.5 * pc_noise3(p2 + b * e * wave_scale * 2.3);
	vec2 grad = vec2(nt - n0, nb - n0) / e;
	vec3 wn = normalize(v_world_nrm - (t * grad.x + b * grad.y) * wave_strength * 0.25);
	NORMAL = normalize((VIEW_MATRIX * vec4(wn, 0.0)).xyz);

	// --- screen-depth difference to the terrain behind the surface -----------------------------
	float sdepth = texture(depth_tex, SCREEN_UV).r;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, sdepth);
	vec4 vp = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	float scene_z = -(vp.z / vp.w);
	float water_z = -VERTEX.z;
	float ray_depth = max(scene_z - water_z, 0.0);

	// --- colors ------------------------------------------------------------------------------------
	float depth_m = max(v_depth, ray_depth * 0.45);
	float deep_t = smoothstep(0.0, deep_range, depth_m);
	vec3 col = mix(shallow_color.rgb, deep_color.rgb, deep_t);
	// light wave streaks
	float streak = smoothstep(0.62, 0.78, n0 / 1.5);
	col = mix(col, col * 1.25 + vec3(0.08), streak * streak_strength);
	// foam: wobbly white line at the shore, plus a lighter aqua fringe
	float wob = (pc_noise3(wp * 5.0 + vec3(TIME * 0.5)) - 0.5) * 0.25;
	float fringe = 1.0 - smoothstep(0.0, foam_width * 3.0, ray_depth + wob * 0.5);
	float foam = 1.0 - smoothstep(foam_width * 0.35, foam_width, ray_depth + wob);
	float foam_pattern = smoothstep(0.35, 0.65, pc_noise3(wp * 9.0 - vec3(0.0, TIME * 0.8, 0.0)));
	foam = clamp(foam * (0.75 + 0.5 * foam_pattern) + (1.0 - smoothstep(0.0, foam_width * 0.3, ray_depth)), 0.0, 1.0);
	col = mix(col, col * 1.15 + vec3(0.06), fringe * 0.6);
	col = mix(col, foam_color.rgb, foam * 0.95);

	// sparkles: twinkling cells
	vec3 sp = wp * 7.0 + vec3(0.0, 0.0, TIME * 0.2);
	vec3 sc = floor(sp);
	float sh = pc_hash31(sc);
	float tw = pc_hash31(sc + floor(TIME * 3.0));
	vec3 scenter = sc + 0.5 + (vec3(pc_hash31(sc + 1.3), pc_hash31(sc + 2.9), pc_hash31(sc + 4.1)) - 0.5) * 0.6;
	float sdot = 1.0 - smoothstep(0.05, 0.16, length(sp - scenter));
	float spark = step(0.965, sh) * step(0.6, tw) * (1.0 - foam) * sdot;
	vec3 emission = vec3(1.0, 0.98, 0.9) * spark * sparkle_strength * (0.5 + 0.5 * sin(TIME * 8.0 + sh * 30.0));

	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	float alpha = mix(alpha_shallow, alpha_deep, deep_t);
	alpha = clamp(alpha + fres * 0.25 + foam * 0.5, 0.0, 1.0);

	if (glow_strength > 0.0) {
		emission += glow_color.rgb * glow_strength * (0.6 + 0.4 * n0 / 1.5) * (1.0 - foam);
		col = mix(col, glow_color.rgb, 0.35);
	}
	if (sheen_strength > 0.0) {
		vec3 rainbow = pc_hsv2rgb(vec3(fract(fres * 1.6 + n0 * 0.4 + TIME * 0.02), 0.8, 1.0));
		emission += rainbow * sheen_strength * (0.25 + fres) * 0.35;
		alpha = clamp(alpha + 0.05, 0.0, 1.0);
	}

	ALBEDO = col;
	ALPHA = alpha;
	ROUGHNESS = 0.08;
	METALLIC = 0.0;
	SPECULAR = 0.7;
	EMISSION = emission;
}

void light() {
	float lit;
	vec3 diffuse = pc_toon_diffuse(ALBEDO, dot(NORMAL, LIGHT), ATTENUATION, ramp_softness, shade_strength, shade_tint.rgb, 0.6, LIGHT_IS_DIRECTIONAL, lit);
	DIFFUSE_LIGHT += diffuse * LIGHT_COLOR / PI;
	vec3 hv = normalize(VIEW + LIGHT);
	float ndh = max(dot(NORMAL, hv), 0.0);
	float spec = smoothstep(0.3, 0.55, pow(ndh, 220.0)) * 1.4 * lit;
	spec += smoothstep(0.5, 0.7, pow(ndh, 24.0)) * 0.12 * lit;
	SPECULAR_LIGHT += spec * LIGHT_COLOR / PI;
}
