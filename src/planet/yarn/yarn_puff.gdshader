// CROCHET billboard puff (builder B, 2026-10-15) - PlanetPropMeshes.pompom_material(): steam and dust.
// With the astro_yarn global at 0 this is the StandardMaterial3D it replaces: unshaded, alpha-blended,
// billboard-particles, vertex colour as albedo, a soft radial dot. With it on, each puff is a WOOL
// POM-POM (yl_pompom, as the jet puffs): same colour and opacity, a fibrous rim and radial strands.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx, unshaded, shadows_disabled;
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
	vec4 albedo_tex = texture(texture_albedo, UV);
	albedo_tex *= COLOR;
	if (astro_yarn > 0.5) {
		// The dot's alpha integrates to ~0.30 of the quad; the pom-pom's solid ball covers ~0.5 of it,
		// so its opacity is scaled to keep the same amount of puff on screen.
		vec2 pp = yl_pompom(UV * 2.0 - 1.0);
		ALBEDO = albedo.rgb * COLOR.rgb * pp.y;
		ALPHA = albedo.a * COLOR.a * pp.x * 0.62;
	} else {
		ALBEDO = albedo.rgb * albedo_tex.rgb;
		ALPHA *= albedo.a * albedo_tex.a;
	}
}
