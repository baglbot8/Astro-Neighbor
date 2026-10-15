// THE CAVE'S MATERIAL (builder C, crochet round 2026-10-15). One unshaded vertex-colour shader for every
// cave surface that used a plain StandardMaterial3D: the stone (walls, floor, rubble), every creature,
// crystal and prop (a Kit mesh) and the pulsing lamps. With the astro_yarn global at 0 it draws what the
// StandardMaterial3D drew (unshaded, vertex colour sRGB times the albedo, cull off, no fog, the rock
// texture laid on object-space triplanar at 0.3 tiles per metre). With it at 1:
//   mode 0 STONE  chunky dark yarn: the rock texture is replaced by stitches (mean-preserving: rock_mean
//                 keeps the brightness the rock gave), lit by the baked vertex colour as before;
//   mode 1 KIT    UV.x = 0 soft parts become amigurumi yarn, UV.x = 1 crystals / eyes / glints stay smooth
//                 glossy beads with a sequin glint, UV.x = 2 contact shadows stay as they were.
shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled, depth_draw_opaque;

#include "res://src/shaders/planet_common.gdshaderinc"
#include "res://src/style/yarn/yarn_lite.gdshaderinc"
#include "res://src/cave/yarn_cave.gdshaderinc"

global uniform float astro_compat;

uniform int mode = 1;                       // 0 stone, 1 kit
// source_color: Forward+ uploads it linear, Compatibility raw (encoded) - exactly what the plain material got
uniform vec4 albedo_color : source_color = vec4(1.0);
// the rock texture arrives already LINEAR (half-float, CaveRockTex.linear_half): the plain material's
// sRGB sampler filtered decoded texels, which the Compatibility renderer's sampler does not do for a shader
uniform sampler2D rock_tex : filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool use_rock = false;
uniform vec3 rock_scale = vec3(0.3);
uniform vec3 rock_mean = vec3(1.0);         // the rock texture's mean, linear (replaces it when crochet is on)
uniform vec3 rock_mean_enc = vec3(1.0);     // the same mean of the sRGB-ENCODED texture (Compatibility multiplies encoded)
uniform float triplanar_sharpness = 3.0;
uniform float bead_glint = 0.34;

varying vec3 v_pos;
varying vec3 v_nrm;

void vertex() {
	v_pos = VERTEX;
	v_nrm = NORMAL;
}

void fragment() {
	// THE PLAIN MATERIAL'S ARITHMETIC. Forward+ decodes the sRGB vertex colour and the texture and multiplies in
	// LINEAR light. Compatibility (the phone) does not decode anything: it multiplies the sRGB-ENCODED vertex colour
	// by the encoded albedo and texture, and sRGB is not multiplicative, so dark tones differ from the linear
	// product (measured by the round-1 critic: parity_compat.png). `x` is the plain result in the renderer's own
	// space; `lin` is it as linear light, which the yarn terms multiply.
	bool cmp = astro_compat > 0.5;
	vec3 x = (cmp ? COLOR.rgb : pc_s2l(COLOR.rgb)) * albedo_color.rgb;
	vec3 nm = normalize(v_nrm);
	vec3 lin;
	if (mode == 0) {
		if (astro_yarn > 0.5) {
			// the stitches replace the rock; its mean (encoded on Compatibility, linear on Forward+) keeps the brightness
			x *= cmp ? rock_mean_enc : rock_mean;
			lin = cmp ? pc_s2l(x) : x;
			float fp = max(length(dFdx(v_pos)), length(dFdy(v_pos)));
			YcStone st = yc_stone(v_pos, nm, yl_lod(fp, YC_H));
			vec3 tv = (VIEW_MATRIX * (MODEL_MATRIX * vec4(st.tilt, 0.0))).xyz;
			lin *= st.ao * (1.0 + yl_fuzz(dot(NORMAL, VIEW), st.fibre)) * yc_relief(NORMAL, tv);
		} else {
			if (use_rock) {
				vec3 pw = pow(abs(nm), vec3(triplanar_sharpness));
				pw /= dot(pw, vec3(1.0));
				vec3 tp = v_pos * rock_scale * vec3(1.0, -1.0, 1.0);
				vec3 t = texture(rock_tex, tp.xy).rgb * pw.z
					+ texture(rock_tex, tp.xz).rgb * pw.y
					+ texture(rock_tex, tp.zy * vec2(-1.0, 1.0)).rgb * pw.x;
				x *= cmp ? pc_l2s(t) : t;
			}
			lin = cmp ? pc_s2l(x) : x;
		}
	} else {
		lin = cmp ? pc_s2l(x) : x;
		if (astro_yarn > 0.5) {
			if (UV.x < 0.5) {
				vec3 ys = yl_scale(MODEL_MATRIX);
				vec3 yp = v_pos * ys;
				YlObj yo = yl_object(yp, normalize(nm / ys), yl_obj_lod(yp));
				vec3 tv = (VIEW_MATRIX * (MODEL_MATRIX * vec4(yo.tilt / ys, 0.0))).xyz;
				lin *= yo.ao * (1.0 + yl_fuzz(dot(NORMAL, VIEW), yo.fibre)) * yc_relief(NORMAL, tv);
			} else if (UV.x < 1.5) {
				// glossy bead: a sequin glint on the flat facet
				vec3 h = normalize(normalize(YC_LIGHT) + VIEW);
				float g = pow(max(dot(normalize(NORMAL), h), 0.0), 18.0);
				lin = mix(lin, vec3(1.0), g * bead_glint);
			}
		}
	}
	ALBEDO = pc_out(lin);
}
