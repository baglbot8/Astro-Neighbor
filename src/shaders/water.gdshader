// Planet water shell: two-tone by depth (baked per-vertex depth in COLOR.r + screen depth), moving
// wave normals, wobbling foam line at the shoreline (depth-texture based), light wave streaks,
// twinkling sparkles, fresnel transparency. Extras: emissive glow (violet rivers), oil sheen (chrome).
//
// WEB PARITY. EVERY POND IN THE GAME USED TO BE A FLAT WHITE SHEET IN THE BROWSER. Two things were
// wrong; both are fixed below and BOTH ARE MECHANISMS, NOT CONSTANTS. Forward+ is byte-identical
// before and after (md5 of the capture, hub and fen, unchanged), because both corrections are gated
// on astro_compat and astro_compat is 0.0 on Forward+.
//
// All numbers are the two frames that actually contain water — a camera aimed at the plaza pond
// (showcase/planet_hub, 701,694 water pixels) and at a fen crater pool (149,001) — on a water mask
// built by forcing this shader to EMISSION 0 and then EMISSION 1 on BOTH renderers and keeping the
// pixels that moved in both, eroded 3 px. Two captures per configuration, byte-identical each time.
//
// 1. THE CLIP-SPACE Z CONVENTION — this is what made the pond white. NOT a colour bug.
//    The previous round's note in this file said "hint_depth_texture RETURNS ZERO under
//    Compatibility". THAT IS WRONG AND IS RETRACTED. Re-probed with a step() threshold sweep, which
//    is immune to the transfer function (the earlier probe read a legitimately DARK emission as a
//    zero, i.e. it was reading bug 1 on its own probe output):
//        texture(depth_tex, SCREEN_UV).r     F+ 100% in (0.05, 0.10)   C 100% in (0.05, 0.10)
//    The depth buffer is fine on both, and its distribution is the SAME on both. What differs is the
//    convention for reconstructing view space from it. Forward+ (Vulkan) has clip/NDC z in [0, 1],
//    so the sample IS the ndc z. Compatibility (WebGL2/OpenGL) has clip/NDC z in [-1, 1] and stores
//    (z + 1) / 2, so the sample must be expanded first. Feeding the raw sample to
//    INV_PROJECTION_MATRIX under Compatibility collapsed the reconstruction:
//        scene_z, fraction of water pixels over a threshold   3.0 m   4.5 m   6.0 m   7.0 m
//          Forward+, raw sample (correct there)               82.4%   39.8%   29.2%    1.5%
//          Compatibility, raw sample                           0.0%    0.0%    0.0%    0.0%   <- broken
//          Compatibility, sample * 2 - 1                      82.4%   39.8%   29.1%    1.5%   <- matches
//    ray_depth was therefore 0 everywhere in the browser, `foam` was 1.0 everywhere, `col` was mixed
//    95% to the white foam_color, and the pond rendered as a flat white sheet. With the expansion in
//    place the shader's own derived quantities agree across renderers to within 1% of pixels:
//        foam > 0.5   F+ 8.2% / C 8.2%      ray_depth > 0.3   F+ 90.7% / C 91.0%
//        alpha > 0.7  F+ 93.1% / C 93.2%
//
// 2. THE ORDINARY pc_in / pc_out CONVERSION, which the previous round measured as worthless and
//    reverted. It was measured THROUGH THE BROKEN FOAM (the surface was 95% white foam_color, where
//    the wrap genuinely cancels), so that verdict does not survive the fix. Re-measured on the fixed
//    shader with cast shadows neutralised on both renderers (see 3):
//        region MAE / SAT gap        hub                    fen
//          depth fix only            6.60  +0.0244          17.38  +0.1989
//          depth fix + conversion    5.10  +0.0096           6.61  +0.0944
//    So the conversion is worth 11 codes of MAE and half the saturation gap on fen. It follows the
//    recipe at the top of planet_common.gdshaderinc verbatim: pc_in on shallow/deep/foam/glow/
//    shade_tint at first use (glow_color is read twice, so it is decoded into a local once), pc_out
//    on the two writes, and NOTHING else — the sparkle tint, the pc_hsv2rgb oil film, the
//    `col * 1.25 + vec3(0.08)` literals and every mask stay unwrapped, per rule (c) and (d).
//
// 3. WHAT IS LEFT, AND WHY NO CONSTANT WILL FIX IT. Region MAE on the shipped shader is 5.09 (hub)
//    and 20.68 (fen). Decomposed by neutralising one non-shader difference at a time:
//                                                     hub MAE   fen MAE
//      shipped                                          5.09     20.68
//      + cast shadows off on BOTH renderers             5.10      6.61   <- environment.gd's
//          `_no_cast_shadows` gate (the shadow-pass fix) means Compatibility casts NO sun shadow at
//          all; fen is a deep crater under an 11-degree sun, so a third of its pool is in a shadow
//          that cannot exist in the browser. Nothing to do with this file.
//      + water forced opaque (ALPHA = 1)                1.91      2.61
//      + ALBEDO forced to a flat pc_out(vec3(0.5))      1.23      0.48   <- THE GATE, MET. The lit
//          surface, the specular lobe and the encode path are all at parity; dropping the specular
//          lobe as well changes nothing (0.91 / 0.48).
//    The whole remaining gap is THE ALPHA BLEND, and it is engine-side. Holding this shader's colour
//    flat and sweeping only ALPHA over the same region:
//        ALPHA        1.00   0.75   0.50   0.25   0.00
//        hub MAE      1.23   5.83  12.23  25.20   2.71
//        fen MAE      0.48   3.61   7.05   8.63   9.17
//    At ALPHA 0 (water invisible) the region is just the pond floor, and that is at 2.71 / 9.17 —
//    so the error is not the background showing through, it is the COMPOSITE. Compatibility with
//    glow disabled tonemaps in the object shader and blends into the display-space target, the way
//    the shadow pass in environment.gd does; Forward+ blends in linear HDR before the tonemap. A
//    fragment shader cannot invert that without reading the destination, and any single number that
//    "closes" it would be a fitted gain — exactly the thing this project has reverted three times.
//    DO NOT ADD ONE. The honest next move, if this ever matters, is to give the shader
//    hint_screen_texture and do the composite itself at ALPHA 1 — a real mechanism, and a round of
//    its own, because SCREEN_TEXTURE is in a different space on the two renderers too.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_schlick_ggx;
#include "res://src/shaders/planet_common.gdshaderinc"
global uniform float astro_compat;

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
	// THE CLIP-SPACE Z CONVENTION. This is the whole "the pond is a white sheet in the browser" bug,
	// and it is a graphics-API convention difference, not a colour-space one and not a tuning knob.
	// Forward+ (Vulkan) has clip/NDC z in [0, 1], so the depth-buffer sample IS the ndc z. The
	// Compatibility renderer (WebGL2/OpenGL) has clip/NDC z in [-1, 1] and stores (z + 1) / 2 in the
	// buffer, so the sample has to be expanded before it is fed to INV_PROJECTION_MATRIX. Godot's own
	// screen-space-depth docs say exactly this; nothing here is fitted.
	float sdepth = texture(depth_tex, SCREEN_UV).r;
	float ndc_z = (astro_compat > 0.5) ? (sdepth * 2.0 - 1.0) : sdepth;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, ndc_z);
	vec4 vp = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	float scene_z = -(vp.z / vp.w);
	float water_z = -VERTEX.z;
	float ray_depth = max(scene_z - water_z, 0.0);

	// --- colors ------------------------------------------------------------------------------------
	float depth_m = max(v_depth, ray_depth * 0.45);
	float deep_t = smoothstep(0.0, deep_range, depth_m);
	vec3 col = mix(pc_in(shallow_color.rgb), pc_in(deep_color.rgb), deep_t);
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
	col = mix(col, pc_in(foam_color.rgb), foam * 0.95);

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
		// glow_color is read twice, so it is decoded into a local ONCE (a second pc_in is a second decode).
		vec3 glow = pc_in(glow_color.rgb);
		emission += glow * glow_strength * (0.6 + 0.4 * n0 / 1.5) * (1.0 - foam);
		col = mix(col, glow, 0.35);
	}
	if (sheen_strength > 0.0) {
		vec3 rainbow = pc_hsv2rgb(vec3(fract(fres * 1.6 + n0 * 0.4 + TIME * 0.02), 0.8, 1.0));
		emission += rainbow * sheen_strength * (0.25 + fres) * 0.35;
		alpha = clamp(alpha + 0.05, 0.0, 1.0);
	}

	ALBEDO = pc_out(col);
	ALPHA = alpha;
	ROUGHNESS = 0.08;
	METALLIC = 0.0;
	SPECULAR = 0.7;
	EMISSION = pc_out(emission);
}

void light() {
	float lit;
	vec3 diffuse = pc_toon_diffuse(ALBEDO, dot(NORMAL, LIGHT), ATTENUATION, ramp_softness, shade_strength, pc_in(shade_tint.rgb), 0.6, LIGHT_IS_DIRECTIONAL, lit);
	DIFFUSE_LIGHT += diffuse * LIGHT_COLOR / PI;
	vec3 hv = normalize(VIEW + LIGHT);
	float ndh = max(dot(NORMAL, hv), 0.0);
	float spec = smoothstep(0.3, 0.55, pow(ndh, 220.0)) * 1.4 * lit;
	spec += smoothstep(0.5, 0.7, pow(ndh, 24.0)) * 0.12 * lit;
	SPECULAR_LIGHT += spec * LIGHT_COLOR / PI;
}
