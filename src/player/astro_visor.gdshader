// OPAQUE navy visor pane (docs/STYLE_GUIDE.md R2.2: "Maybe the astronauts mask is just navy blue
// like you cant see through it"). There is no face behind it any more, so this shader no longer
// tints anything through the glass — it paints a solid, slightly glossy dark pane.
//
// Three jobs, in order of how much they matter at gameplay distance (6.5 m, ~85 px tall):
//   1. Be genuinely DARK. This pane is the character's large dark anchor — every Animal Crossing
//      character has one and ours had none (the old crop measured 43% blown highlights and a flat
//      white circle for a head). Its shade floor is high enough that it never crushes to black.
//   2. Read as a CURVED pane, not a painted disc: the albedo lifts towards the top of the cap
//      (where a real visor picks up the sky) and a narrow fresnel band lights the very edge.
//   3. Carry exactly ONE highlight. The tight specular below plus the single painted streak mesh
//      in astronaut_model.gd is the whole highlight budget; anything more reads as a shiny toy.
shader_type spatial;
render_mode cull_back, depth_draw_opaque, diffuse_lambert, specular_schlick_ggx;

uniform vec4 tint : source_color = vec4(0.106, 0.141, 0.314, 1.0);
// Vertical albedo ramp across the pane: bottom is `low_mul` of the tint, top is `high_mul`.
uniform float low_mul : hint_range(0.3, 1.0) = 0.70;
uniform float high_mul : hint_range(1.0, 2.5) = 1.55;
// Narrow cool band right at the silhouette edge of the pane, so the rim ring is not the only edge.
uniform float fresnel_gain : hint_range(0.0, 1.0) = 0.26;
uniform vec4 fresnel_color : source_color = vec4(0.44, 0.60, 0.92, 1.0);
uniform float spec_strength : hint_range(0.0, 2.0) = 0.5;
uniform float spec_size : hint_range(1.0, 400.0) = 190.0;
uniform float ramp_softness : hint_range(0.01, 1.0) = 0.40;
// A dark surface that also uses the world's 0.08 shadow floor turns into a black hole under a
// tree. 0.55 keeps the navy readable as navy in shade without making it glow.
uniform float shade_floor : hint_range(0.0, 1.0) = 0.55;
uniform vec4 shade_tint : source_color = vec4(0.62, 0.66, 0.92, 1.0);
uniform float shade_strength : hint_range(0.0, 1.0) = 0.35;

varying vec3 v_dir;

void vertex() {
	// The pane is a cap of the helmet ellipsoid centred on the helmet node's origin, so the raw
	// local position already points from the helmet centre out through the pane.
	v_dir = normalize(VERTEX);
}

void fragment() {
	float up = smoothstep(-0.45, 0.80, v_dir.y);
	ALBEDO = tint.rgb * mix(low_mul, high_mul, up);
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.4);
	ALBEDO += fresnel_color.rgb * fres * fresnel_gain;
	ROUGHNESS = 0.35;
	METALLIC = 0.0;
	SPECULAR = 0.5;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float lit = smoothstep(-ramp_softness, ramp_softness, ndl) * ATTENUATION;
	vec3 shadow_col = ALBEDO * mix(vec3(1.0), shade_tint.rgb, shade_strength);
	DIFFUSE_LIGHT += mix(shadow_col * shade_floor, ALBEDO, lit) * LIGHT_COLOR / PI;

	vec3 h = normalize(VIEW + LIGHT);
	float spec = smoothstep(0.45, 0.80, pow(max(dot(NORMAL, h), 0.0), spec_size)) * spec_strength * lit;
	SPECULAR_LIGHT += spec * LIGHT_COLOR / PI;
}
