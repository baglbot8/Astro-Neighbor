// CROCHET particle sparkle (builder B, 2026-10-15) - PlanetPropMeshes.sparkle_material().
// With the astro_yarn global at 0 this is the StandardMaterial3D it replaces, line for line: unshaded,
// additive, two-sided, billboard-particles, vertex colour as albedo, a soft radial dot.
// With it on, each sparkle is a little EMBROIDERED STAR STITCH (yarn_star_tex, the sky's star) in the
// same colour, over a faint felt halo of the old dot so it stays as visible as before. 1 read either way.
shader_type spatial;
render_mode blend_add, depth_draw_opaque, cull_disabled, diffuse_burley, specular_schlick_ggx, unshaded, shadows_disabled;
#include "res://src/style/yarn/yarn_lite.gdshaderinc"

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;

void vertex() {
	mat4 mat_world = mat4(normalize(INV_VIEW_MATRIX[0]), normalize(INV_VIEW_MATRIX[1]), normalize(INV_VIEW_MATRIX[2]), MODEL_MATRIX[3]);
	mat_world = mat_world * mat4(vec4(cos(INSTANCE_CUSTOM.x), -sin(INSTANCE_CUSTOM.x), 0.0, 0.0), vec4(sin(INSTANCE_CUSTOM.x), cos(INSTANCE_CUSTOM.x), 0.0, 0.0), vec4(0.0, 0.0, 1.0, 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_MATRIX = VIEW_MATRIX * mat_world;
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	vec4 dot_tex = texture(texture_albedo, UV);
	vec4 albedo_tex = dot_tex * COLOR;
	if (astro_yarn > 0.5) {
		// The star stitch fills ~70% of the quad (the dot's visible core is about that wide); the
		// stitch's own shading (g) gives the strands; the old dot stays at 30% as a felt halo.
		vec2 sp = (UV - 0.5) / 0.70 + 0.5;
		float inq = step(0.0, sp.x) * step(sp.x, 1.0) * step(0.0, sp.y) * step(sp.y, 1.0);
		vec4 st = textureLod(yarn_star_tex, sp, 0.0) * inq;
		float cov = st.r;
		ALBEDO = albedo.rgb * COLOR.rgb * mix(1.0, st.g * 1.15, cov);
		ALPHA = albedo.a * COLOR.a * max(cov * 0.95, dot_tex.a * 0.30);
	} else {
		ALBEDO = albedo.rgb * albedo_tex.rgb;
		ALPHA *= albedo.a * albedo_tex.a;
	}
}
