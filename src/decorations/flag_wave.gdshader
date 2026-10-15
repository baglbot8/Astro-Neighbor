// Cloth wave for flags and banners. Vertex-colored toon (same look as MaterialLib.toon_vertex_color)
// with a travelling sine that grows with UV.x, so the edge attached to the pole stays put and the free
// end ripples. Normals are re-derived from the wave slope so the shading ripples too.
shader_type spatial;
render_mode cull_disabled, depth_draw_opaque, diffuse_lambert, specular_schlick_ggx;

// WEB PARITY. planet_common is included for pc_in/pc_out only - the recipe is written out at its
// lines 84-104. Under Compatibility the sRGB->linear step moves off the CPU uniform upload and onto
// the ALBEDO write, so each `source_color` uniform is decoded once at first use and the single
// ALBEDO write is encoded once. `astro_compat` is 1.0 only under Compatibility, so on Forward+ both
// wraps are the identity and the desktop look cannot move. v_col carries the baked pennant colour
// and is NOT wrapped - vertex colour arrives identically on both renderers (recipe (c)).
//
// MEASURED, showcase/decorations_gallery.tscn --still --row=26 (the Star Flag, the only decoration
// on this shader besides the Town Hall pennant), on the 12,989-px cloth. The mask is the pixels a
// magenta-emission build of THIS shader moves by more than 30 codes on BOTH renderers - a hue test
// is useless here because the night hub is lit violet. Two independent captures per row, agreeing
// to the second decimal, Forward+ vs Compatibility:
//     night (--night)   before  MAE 48.65  p95 63.00   region SAT 0.5166 -> 0.6051 (gap 0.0886)
//                       after   MAE  2.74  p95  6.00   region SAT 0.5165 -> 0.5391 (gap 0.0226)
//     day               before  MAE 60.78  p95 75.67   region SAT 0.7335 -> 0.9635 (gap 0.2300)
//                       after   MAE  2.45  p95  8.67   region SAT 0.7335 -> 0.7341 (gap 0.0006)
// Forward+ did not move: p05/p50/p95 108.8 / 147.6 / 198.1 by day and 66.0 / 117.0 / 142.0 at
// night, identical before and after, every run.
//
// THE ~2.5 MAE LEFT IS THE SURFACE'S FLOOR, NOT THIS SHADER. A flat literal
// `ALBEDO = pc_out(vec3(0.90, 0.10, 0.05))` - no uniform, no vertex colour, nothing that can be
// converted wrongly - measures MAE 2.60 / p95 5.33 on the same pixels of the same frame, against
// the real shader's 2.74 / 6.00. Eroding the mask by 4 and by 6 does not move either number, so it
// is not silhouette antialiasing; it is the scene-level difference planet_common rule (i) lists
// (no SSAO and no glow under Compatibility) landing on a curved cloth. The day-frame SAT gap of
// 0.0006 is the number that says the colour transform itself is right.
//
// Two things this measurement settled that are worth not re-testing:
//   * pc_in() on the VERTEX COLOUR is catastrophic, exactly as recipe (c) says: `pc_out(pc_in(v_col))`
//     scores MAE 50.47 against the correct form's 2.74. Vertex colour is already linear on both.
//   * The rim term in light() is not involved - forcing rim_strength to 0 leaves MAE at 2.74.
#include "res://src/shaders/planet_common.gdshaderinc"
global uniform float astro_compat;
// CROCHET (2026-10-15, builder C): with the astro_yarn global on the pennant is crocheted cloth - single-crochet
// stitches glued to the cloth (its rest position, so they ride the wave), 1-3 stitch reads, the relief lit by the
// game's own light. The wave, the vertex colour and the toon ramp are untouched; with the global at 0 this shader is
// exactly what it was.
#include "res://src/style/yarn/yarn_lite.gdshaderinc"
#include "res://src/cave/yarn_cave.gdshaderinc"

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
varying vec3 v_op;
varying vec3 v_on;
varying vec3 v_flat;

void vertex() {
	v_op = VERTEX;
	v_on = NORMAL;
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
	vec3 flag_col = pc_in(albedo.rgb) * v_col;
	v_flat = NORMAL;
	if (astro_yarn > 0.5) {
		vec3 sc = yl_scale(MODEL_MATRIX);
		vec3 yp = v_op * sc;
		float fp = max(length(dFdx(yp)), length(dFdy(yp)));
		YcStone ys = yc_stone_sz(yp, normalize(v_on / sc), yl_lod(fp, YL_H), vec2(YL_W, YL_H));
		flag_col *= ys.ao * (1.0 + yl_fuzz(dot(NORMAL, VIEW), ys.fibre));
		NORMAL = normalize(NORMAL + (VIEW_MATRIX * (MODEL_MATRIX * vec4(ys.tilt / sc, 0.0))).xyz);
	}
	ALBEDO = pc_out(flag_col);
	ROUGHNESS = 0.9;
	METALLIC = 0.0;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float lit = smoothstep(-ramp_softness, ramp_softness, ndl) * ATTENUATION;
	vec3 shadow_col = ALBEDO * mix(vec3(1.0), pc_in(shade_tint.rgb), shade_strength);
	float relief = astro_yarn > 0.5 ? yl_relief_light(NORMAL, v_flat, LIGHT) : 1.0;
	DIFFUSE_LIGHT += mix(shadow_col * 0.55, ALBEDO, lit) * relief * LIGHT_COLOR / PI;
	float rim = 1.0 - max(dot(NORMAL, VIEW), 0.0);
	rim = smoothstep(0.6, 0.9, rim) * rim_strength * lit;
	SPECULAR_LIGHT += rim * LIGHT_COLOR / PI;
}
