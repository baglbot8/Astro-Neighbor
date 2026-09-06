// Cloth wave for flags and banners. Vertex-colored toon (same look as MaterialLib.toon_vertex_color)
// with a travelling sine that grows with UV.x, so the edge attached to the pole stays put and the free
// end ripples. Normals are re-derived from the wave slope so the shading ripples too.
shader_type spatial;
render_mode cull_disabled, depth_draw_opaque, diffuse_lambert, specular_schlick_ggx;

uniform vec4 albedo : source_color = vec4(1.0);
uniform float wave_amp = 0.12;
uniform float wave_freq = 5.0;
uniform float wave_speed = 2.4;
uniform float flap = 0.35;
uniform float ramp_softness : hint_range(0.01, 1.0) = 0.32;
uniform float shade_strength : hint_range(0.0, 1.0) = 0.4;
uniform vec4 shade_tint : source_color = vec4(0.62, 0.55, 0.85, 1.0);
uniform float rim_strength : hint_range(0.0, 2.0) = 0.2;

varying vec3 v_col;

void vertex() {
	float grip = UV.x * UV.x;
	float t = TIME * wave_speed;
	float w = sin(UV.x * wave_freq - t) * wave_amp * grip;
	w += sin(UV.x * wave_freq * 0.53 - t * 0.7 + UV.y * 2.0) * wave_amp * flap * grip;
	VERTEX.z += w;
	VERTEX.y += sin(UV.x * 3.0 - t * 0.8) * wave_amp * 0.25 * grip;
	float slope = cos(UV.x * wave_freq - t) * wave_amp * wave_freq * grip;
	NORMAL = normalize(vec3(-slope * sign(NORMAL.z), 0.0, NORMAL.z));
	v_col = COLOR.rgb;
}

void fragment() {
	ALBEDO = albedo.rgb * v_col;
	ROUGHNESS = 0.9;
	METALLIC = 0.0;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float lit = smoothstep(-ramp_softness, ramp_softness, ndl) * ATTENUATION;
	vec3 shadow_col = ALBEDO * mix(vec3(1.0), shade_tint.rgb, shade_strength);
	DIFFUSE_LIGHT += mix(shadow_col * 0.55, ALBEDO, lit) * LIGHT_COLOR / PI;
	float rim = 1.0 - max(dot(NORMAL, VIEW), 0.0);
	rim = smoothstep(0.6, 0.9, rim) * rim_strength * lit;
	SPECULAR_LIGHT += rim * LIGHT_COLOR / PI;
}
