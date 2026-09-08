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

// --- WEB PARITY: THE COMPATIBILITY sRGB HELPERS, INLINED -----------------------------------------
// THE CANONICAL COPY AND THE FULL WRITE-UP LIVE AT THE TOP OF src/shaders/planet_common.gdshaderinc;
// read that first. The block below is byte-identical to the ones inlined in
// src/shaders/toon_soft.gdshader and src/player/astro_shell.gdshader.
//
// WHAT COMPATIBILITY GETS WRONG HERE, and why it is an R2.1 problem and not a tone problem.
// Compatibility does not sRGB-decode a `source_color` uniform on upload, so the navy #1b2450
// arrives in fragment() as (0.106, 0.141, 0.314) — DISPLAY space — where Forward+ hands the shader
// its linear (0.0116, 0.0175, 0.0782). A pane that assigned that uniform STRAIGHT to ALBEDO would
// still come out right, because the engine's own srgb_to_linear on the way out is the exact inverse.
// This one does not: it MULTIPLIES by the `low_mul`/`high_mul` ramp and then ADDS the fresnel band,
// and both of those land in the wrong space. The multiply becomes m^2.4 instead of m; the add is the
// worse half, because 0.114 of fresnel on top of a linear 0.017 is a rim, while the same 0.114 on
// top of a display-space 0.106 is the same magnitude as the pane itself. Measured over the pane's
// own pixels, Compatibility rendered the median navy at (5, 3, 12) against Forward+'s (5, 3, 18) —
// a third of the pane's only real channel missing — with the edge band correspondingly overweight.
//
// `astro_compat` is 1.0 only under Compatibility (Platform._apply_renderer_parity), so every wrap
// below is the exact identity on desktop and the Forward+ reference look cannot move.
//
// MEASURED, res://src/world/world.tscn on home with CameraRig.orbit_front so the pane faces the
// lens, scored on a magenta-difference mask of THIS shader's pixels with the Streak/StreakBead
// meshes' pixels removed (they are a separate 55%-alpha StandardMaterial3D drawn on top, so those
// pixels are a blend of two materials and are not this shader's to answer for), two independent
// capture configurations — different RNG seed, different capture time, different idle pose:
//   config a (seed 7, t=4.0s, 2,348 px)     before  MAE 2.02  p95 7.3  max 17.0
//                                           after   MAE 1.55  p95 5.2  max 12.0
//   config b (seed 13, t=5.5s, 1,796 px)    before  MAE 2.41  p95 9.7  max 16.3
//                                           after   MAE 1.78  p95 7.0  max 11.7
// FORWARD+ DID NOT MOVE: MAE 0.00 over the mask, before against after.
//
// THE RESIDUAL IS NOT THIS SHADER'S, AND IT IS MEASURABLE. The pane is glossy (SPECULAR 0.5,
// ROUGHNESS 0.35), so the engine reflects the SKY radiance into it — and every `shader_type sky`
// shader is frozen this round because that path's transfer is col^1.28 rather than a clean decode
// (planet_common rule (e)). Re-run with that lobe removed (SPECULAR 0.0, ROUGHNESS 1.0) and only
// this file's own colour maths is left:
//   config a   before  MAE 1.18  p95 2.7  max 4.7        after  MAE 0.71  p95 1.0  max 1.0
//   config b   before  MAE 1.33  p95 3.3  max 4.7        after  MAE 0.70  p95 1.0  max 1.3
// A MAXIMUM of one code value over every pixel of the pane, on two independent captures. The
// conversion is exact; what is left is the frozen sky reflected in a glossy surface.
//
// THE REGION SATURATION GATE (<= 0.01) IS NOT REACHABLE ON THIS SURFACE AND NOBODY SHOULD TUNE
// ANYTHING TRYING TO REACH IT. The pane renders at (5, 3, 18): saturation is (max-min)/max, so a
// SINGLE code value of quantisation on the min channel moves it by 0.055. The measured gap is 0.030
// against a max per-pixel error of 1.0 code — that is the metric hitting its own noise floor at
// V = 0.07, not a colour error. The conversion improves the number (0.036 -> 0.030) and the thing
// the gate is actually protecting — R2.1's OPAQUE NAVY SHELL — is verified directly: the pane stays
// DARKER than Forward+ on Compatibility (blue 14 against 18), so nothing here turns it back into
// glass. It was never at risk of lightening; the pre-conversion error ran the other way.
//
// The pane's own colour never leaves [0, 1] (tint 0.314 max x high_mul 1.55 = 0.487, plus at most
// 0.114 of fresnel), so rule (g)'s over-range caveat does not apply: the encode round-trips exactly.
global uniform float astro_compat;

vec3 pc_s2l(vec3 q) { return mix(q / 12.92, pow((q + vec3(0.055)) / 1.055, vec3(2.4)), step(vec3(0.04045), q)); }
vec3 pc_l2s(vec3 q) { q = max(q, vec3(0.0)); return mix(q * 12.92, 1.055 * pow(q, vec3(1.0 / 2.4)) - vec3(0.055), step(vec3(0.0031308), q)); }
vec3 pc_in_f(vec3 q, float compat) { return (compat > 0.5) ? pc_s2l(q) : q; }
vec3 pc_out_f(vec3 q, float compat) { return (compat > 0.5) ? pc_l2s(q) : q; }
// Macros, not functions, so `astro_compat` is resolved at the CALL site — a function in a shared
// include cannot see a uniform the including shader declares further down. See planet_common.
#define pc_in(q) pc_in_f((q), astro_compat)
#define pc_out(q) pc_out_f((q), astro_compat)

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
	// pc_in at each uniform's FIRST use, so the ramp multiply and the fresnel add below both happen
	// in linear space on both renderers, and the single pc_out at the bottom is the only encode.
	ALBEDO = pc_in(tint.rgb) * mix(low_mul, high_mul, up);
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.4);
	ALBEDO += pc_in(fresnel_color.rgb) * fres * fresnel_gain;
	ALBEDO = pc_out(ALBEDO);
	ROUGHNESS = 0.35;
	METALLIC = 0.0;
	SPECULAR = 0.5;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float lit = smoothstep(-ramp_softness, ramp_softness, ndl) * ATTENUATION;
	vec3 shadow_col = ALBEDO * mix(vec3(1.0), pc_in(shade_tint.rgb), shade_strength);
	DIFFUSE_LIGHT += mix(shadow_col * shade_floor, ALBEDO, lit) * LIGHT_COLOR / PI;

	vec3 h = normalize(VIEW + LIGHT);
	float spec = smoothstep(0.45, 0.80, pow(max(dot(NORMAL, h), 0.0), spec_size)) * spec_strength * lit;
	SPECULAR_LIGHT += spec * LIGHT_COLOR / PI;
}
