// YARNLITE sprite: the unshaded, alpha-blended StandardMaterial3D the cast and the player built for
// their own glows and puffs (alien hover glow, Vela's halo, the astronaut's happy sparkles, the
// footstep dust, Bolt's vent puff), rewritten as a shader so it can take the crochet look behind the
// astro_yarn switch. With the switch at 0 it is the code Godot generates for that StandardMaterial3D
// (BaseMaterial3D, unshaded + alpha + texture + vertex colour + billboard), line for line, so the
// plain game cannot move. Used through YarnLite.sprite_material().
//
// yarn_kind: 0 = felt halo (a soft dot whose rim breaks into wool fibres; replaces the soft-dot
// texture, whose profile it reproduces exactly: (1 - smoothstep(0.15, 1, d))^2), 1 = embroidered
// star stitch (replaces the 4-point sparkle texture), 2 = wool pom-pom (a dust/steam sphere seen as a
// ball of wool), -1 = none. Cost when ON: felt / pom-pom ALU only, star one read of yarn_star_tex.
#include "res://src/style/yarn/yarn_lite.gdshaderinc"

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform bool use_texture = false;
uniform bool use_vertex_color = false;
// 0 = none, 1 = BILLBOARD_ENABLED, 2 = BILLBOARD_PARTICLES (spin from INSTANCE_CUSTOM.x).
uniform int billboard = 0;
uniform bool billboard_keep_scale = false;
uniform int yarn_kind = -1;

void vertex() {
	if (billboard == 1) {
		MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
				MAIN_CAM_INV_VIEW_MATRIX[0],
				MAIN_CAM_INV_VIEW_MATRIX[1],
				MAIN_CAM_INV_VIEW_MATRIX[2],
				MODEL_MATRIX[3]);
		if (billboard_keep_scale) {
			MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(
					vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
					vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
					vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
					vec4(0.0, 0.0, 0.0, 1.0));
		}
		MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
	} else if (billboard == 2) {
		mat4 mat_world = mat4(
				normalize(INV_VIEW_MATRIX[0]),
				normalize(INV_VIEW_MATRIX[1]),
				normalize(INV_VIEW_MATRIX[2]),
				MODEL_MATRIX[3]);
		mat_world = mat_world * mat4(
				vec4(cos(INSTANCE_CUSTOM.x), -sin(INSTANCE_CUSTOM.x), 0.0, 0.0),
				vec4(sin(INSTANCE_CUSTOM.x), cos(INSTANCE_CUSTOM.x), 0.0, 0.0),
				vec4(0.0, 0.0, 1.0, 0.0),
				vec4(0.0, 0.0, 0.0, 1.0));
		MODELVIEW_MATRIX = VIEW_MATRIX * mat_world;
		if (billboard_keep_scale) {
			MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(
					vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
					vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
					vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
					vec4(0.0, 0.0, 0.0, 1.0));
		}
		MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
	}
}

void fragment() {
	vec4 albedo_tex = vec4(1.0);
	if (use_texture) {
		albedo_tex = texture(texture_albedo, UV);
	}
	if (use_vertex_color) {
		albedo_tex *= COLOR;
	}
	if (astro_yarn > 0.5 && yarn_kind >= 0) {
		vec2 p = (UV - 0.5) * 2.0;
		float d = length(p);
		if (yarn_kind == 0) {
			albedo_tex.a = (use_vertex_color ? COLOR.a : 1.0) * yl_felt(p, d, 0.15);
		} else if (yarn_kind == 1) {
			albedo_tex.a = (use_vertex_color ? COLOR.a : 1.0) * clamp(yl_star_stitch(p), 0.0, 1.0);
		} else {
			// The sphere's view-space normal is its own billboard coordinate (-1..1 to the rim).
			vec2 pp = yl_pompom(NORMAL.xy);
			albedo_tex.a *= pp.x;
			albedo_tex.rgb *= pp.y;
		}
	}
	ALBEDO = albedo.rgb * albedo_tex.rgb;
	ALPHA *= albedo.a * albedo_tex.a;
}
