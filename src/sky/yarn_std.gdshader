// YARNLITE stand-in for a plain StandardMaterial3D (albedo colour, roughness, metallic) on builder D's
// props: the sky-watch telescope (src/sky/telescope.gd) and the print easel (src/sky/print_gift.gd).
//
// WITH THE SWITCH OFF THIS IS THE STANDARD MATERIAL: same render modes, same uniforms (albedo is a
// source_color like the engine's own), and the same four writes the engine generates for a
// StandardMaterial3D with no textures (its albedo/metallic/roughness textures default to white, so
// ALBEDO = albedo.rgb, METALLIC = metallic, ROUGHNESS = roughness, SPECULAR = 0.5, and with
// emission on EMISSION = emission.rgb * emission_energy). Measured against
// the base copy in the report, not assumed.
//
// ON: amigurumi stitches in the part's own frame, exactly toon_soft's hook (1-3 reads), and matte
// yarn. `yarn_skip` keeps glass (the telescope's lens) glossy, like safety eyes.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;
#include "res://src/style/yarn/yarn_lite.gdshaderinc"

uniform vec4 albedo : source_color = vec4(1.0);
uniform float roughness : hint_range(0.0, 1.0) = 1.0;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float specular : hint_range(0.0, 1.0) = 0.5;
uniform vec4 emission : source_color = vec4(0.0, 0.0, 0.0, 1.0);
/// StandardMaterial3D's emission_energy_multiplier; 0 = emission off (the engine writes nothing then,
/// and an EMISSION of zero adds nothing).
uniform float emission_energy = 0.0;
uniform bool yarn_skip = false;

varying vec3 v_objpos;
varying vec3 v_objnorm;

void vertex() {
	v_objpos = VERTEX;
	v_objnorm = NORMAL;
}

void fragment() {
	ALBEDO = albedo.rgb;
	METALLIC = metallic;
	ROUGHNESS = roughness;
	SPECULAR = specular;
	EMISSION = emission.rgb * emission_energy;
	if (astro_yarn > 0.5 && !yarn_skip) {
		vec3 ys = yl_scale(MODEL_MATRIX);
		vec3 yp = v_objpos * ys;
		YlObj yo = yl_object(yp, normalize(v_objnorm / ys), yl_obj_lod(yp));
		ALBEDO *= yo.ao * (1.0 + yl_fuzz(dot(NORMAL, VIEW), yo.fibre));
		NORMAL = normalize(NORMAL * yo.nz + (VIEW_MATRIX * (MODEL_MATRIX * vec4(yo.tilt / ys, 0.0))).xyz);
		ROUGHNESS = 1.0;
		METALLIC = 0.0;
		SPECULAR = 0.25;
	}
}
