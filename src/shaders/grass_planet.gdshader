// Planet ground: ACNH-style triangle grass on a sphere (meadow + violet biomes).
// Procedural, no UVs: cube-sphere mapping from world position. Height-based sand near the water,
// wet shore ring under the water line, optional sand paths (great-circle arcs), crater dust from
// vertex COLOR.b, and (violet) glowing river beds + bioluminescent specks.
//
// R2.9 SURFACE TEXTURE — the ground is the biggest surface in the game and the one the user named
// ("nothing looks too flat / cheap... notably... the ground", "grass as plump softeness"). The
// detail comes from the shared library in surface_detail.gdshaderinc, in bands chosen for the
// distance the ground is actually seen at. See the block comment above the SD_* constants.
shader_type spatial;
render_mode cull_back, depth_draw_opaque, diffuse_lambert, specular_schlick_ggx;
#include "res://src/shaders/planet_common.gdshaderinc"
#include "res://src/shaders/surface_detail.gdshaderinc"

// --- R2.9 FREQUENCY BANDS -------------------------------------------------------------------------
// The gameplay camera sits 6.5 m back at 28 deg, so its eye is ~3.0 m above a 13-26 m planet and the
// visible ground runs from ~2 m (bottom of frame) to the horizon at ~10-12 m. In a pulled-back or
// orbit shot it reaches ~40 m. A ground pixel is therefore about `dist * 0.0025 m` across.
//
// sd_cloth-style frequencies (190 cycles/m) are invisible past 1.5 m and are useless here; the two
// bands below sit where the ground is actually looked at. The `*_K` numbers scale the position
// handed to sd_foliage/sd_rock, which run at 30/7 and 46/6.5 cycles per unit internally:
//
//   CLUMP  x0.26 ->  7.8 and 1.8 cycles/m  (13 cm sub-forms inside 55 cm clumps) - the "plump"
//                    band. Safe to ~32 m, so it survives all the way to the horizon.
//   TUFT   x0.85 -> 25.5 and 6.0 cycles/m  (3.9 cm blade grain) - reads inside ~4 m and is faded
//                    out by ~10 m, which is where it would start to alias.
//   ROCKC  x0.16 ->  7.4 and 1.0 cycles/m  (13 cm mottling inside metre-scale tonal drift) and
//   ROCKF  x0.62 -> 28.5 and 4.0 cycles/m  (3.5 cm chipped grain, near range only)
//                    on sand, the trodden path, crater dust, and the bare-earth cliff faces of
//                    plateau banks and crater walls. Two calls, because stone needs "mottled tonal
//                    variation at TWO scales" and one lod cannot fade a coarse and a fine band
//                    independently — a single call either loses the mottling early or aliases late.
//
// Every band is multiplied by pc_band_lod (the derivative-based fade that removed the original
// contour-ring moire) keyed to its own dominant frequency, so no band is ever sampled near Nyquist.
const float SD_CLUMP_K = 0.26;
const float SD_CLUMP_HZ = 7.8;
const float SD_TUFT_K = 0.85;
const float SD_TUFT_HZ = 25.5;
const float SD_ROCKC_K = 0.16;
const float SD_ROCKC_HZ = 7.4;
const float SD_ROCKF_K = 0.62;
const float SD_ROCKF_HZ = 28.5;

// WEB PARITY. Under the Compatibility (WebGL2) renderer that the web export is forced onto,
// `astro_compat` is 1.0; it is 0.0 on desktop, set once by the Platform autoload, so everything
// below is the exact identity on Forward+ and the reference look cannot move.
//
// This shader is converted with pc_in() / pc_out() — see the long block at the top of
// planet_common.gdshaderinc for the measurement, the probe numbers and the rules. In short:
// Compatibility does not sRGB-decode `source_color` uniforms on upload (so they arrive in display
// space and need pc_in), and it sRGB-ENCODES whatever fragment() writes to ALBEDO/EMISSION (so the
// writes need pc_out). Everything between the two then runs in linear on both renderers, which is
// the whole point: this shader does a great deal of arithmetic on colour — the triangle mix, the
// macro shadow blend, the sun patch, the detail bands, pc_pastel — and under the old code every one
// of those multiplies was landing as t^2.2. That is the "grass comes out very white" S-curve.
//
// DELETED HERE: `compat_gain` and the `* ALBEDO * compat_gain` it rode in on at the end of light().
// It was compensating for a "double albedo under Compatibility" divergence that was MEASURED NOT TO
// EXIST (both renderers multiply DIFFUSE_LIGHT by ALBEDO exactly once). Worse, it was not free: the
// extra `* ALBEDO` cost the web build a further ~40% of the ground's brightness on top of the real
// bug. Do not re-add it, or any constant like it.
global uniform float astro_compat;

uniform vec4 color_a : source_color = vec4(0.361, 0.706, 0.373, 1.0);   // base grass  #5cb45f
uniform vec4 color_b : source_color = vec4(0.247, 0.541, 0.290, 1.0);   // darker triangles #3f8a4a
uniform vec4 color_c : source_color = vec4(0.435, 0.769, 0.443, 1.0);   // lighter triangles
// Large-scale shadow tone (ACNH's #3d6e5b covers ~24% of a reference frame). This is where our dark
// values come from — without it the ground has no tonal range at all.
uniform vec4 shadow_color : source_color = vec4(0.239, 0.431, 0.357, 1.0);
// ACNH's shadow green covers ~24% of a reference frame. At 0.88 ours covered ~44% and the whole
// meadow averaged out to the shadow tone's teal hue instead of reading as green with shade in it.
uniform float shadow_patch : hint_range(0.0, 1.0) = 0.58;
// Exposed earth on plateau banks / crater walls (vertex COLOR.g) — the ACNH cliff face.
uniform vec4 bank_color : source_color = vec4(0.663, 0.478, 0.310, 1.0);
uniform vec4 sand_color : source_color = vec4(0.859, 0.788, 0.612, 1.0);
uniform vec4 shore_color : source_color = vec4(0.620, 0.560, 0.420, 1.0);
uniform vec4 crater_color : source_color = vec4(0.72, 0.57, 0.40, 1.0);
uniform vec4 path_color : source_color = vec4(0.859, 0.788, 0.612, 1.0);
uniform vec4 path_edge_color : source_color = vec4(0.69, 0.62, 0.47, 1.0);
uniform float planet_radius = 16.0;
uniform float water_radius = 15.65;
uniform float sand_band = 0.24;
uniform float cell_size = 0.40;
uniform float tri_radius = 0.17;
uniform float tri_density = 0.72;
uniform float patch_strength = 0.07;
// Broad sunlit patches on the high ground. Per biome: the violet world needs luma RANGE more than
// it needs a brighter or a darker mean, and a stronger sun patch is the honest way to buy it.
uniform float sun_patch : hint_range(1.0, 2.4) = 1.15;
uniform float sun_patch_lo : hint_range(0.2, 0.9) = 0.52;
uniform float sun_patch_amt : hint_range(0.0, 1.0) = 0.60;
// Warm tint on the sunlit patch. On a violet world this is the one lever that separates the two
// gates: HSV "value" is the blue channel there, luma is mostly green, so warming the patch buys luma
// range without pushing the value mean over its ceiling - and warm sun on cool ground is true anyway.
uniform vec4 sun_patch_tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
// Limb shading: ground seen edge-on (far away / over the curve) goes darker and cooler so the planet
// reads as a rounded FORM instead of a flat sheet of colour.
uniform float limb_darken : hint_range(0.0, 1.0) = 0.54;
// R2.6: a strongly blue limb tint pulls the red channel of an already green surface toward zero,
// which is a saturation *boost*, not a shade. Keep it a near-neutral cool grey.
uniform vec4 limb_tint : source_color = vec4(0.76, 0.80, 0.87, 1.0);
uniform int path_count = 0;
uniform vec3 path_a[8];
uniform vec3 path_b[8];
uniform float path_width = 1.9;
// Violet extras
uniform vec4 river_color : source_color = vec4(0.243, 0.776, 1.0, 1.0);
uniform vec4 riverbed_color : source_color = vec4(0.36, 0.72, 0.86, 1.0);
uniform float river_glow = 0.0;
uniform float speck_strength = 0.0;
uniform vec4 speck_color_a : source_color = vec4(0.5, 1.0, 0.95, 1.0);
uniform vec4 speck_color_b : source_color = vec4(1.0, 0.55, 0.9, 1.0);
// Baked ground occlusion (Planet._bake_color -> COLOR.a): contact pools under props, the concave
// feet of crater walls and plateau banks, and broad low ground. This is where the ground's tonal
// range comes from at noon, when nothing casts a long shadow. It multiplies the LIT result, never
// the albedo, so shaded grass stays the same happy green, just darker.
uniform float ao_ambient : hint_range(0.0, 1.0) = 1.0;
uniform float ao_direct : hint_range(0.0, 1.0) = 0.85;
// Toon
uniform float ramp_softness : hint_range(0.01, 1.0) = 0.35;
uniform float shade_strength : hint_range(0.0, 1.0) = 0.32;
uniform float shade_floor : hint_range(0.0, 1.0) = 0.32;
uniform vec4 shade_tint : source_color = vec4(0.70, 0.66, 0.86, 1.0);
uniform float spec_strength = 0.0;
// R2.6 pastel guard (see pc_pastel in planet_common.gdshaderinc). Ground is a natural surface and
// covers most of the frame, so it gets the tightest cap in the game.
uniform float pastel_max : hint_range(0.05, 1.0) = 0.54;
uniform float pastel_dark : hint_range(0.0, 1.0) = 0.45;
// R2.6 / ACNH: cast shadows are TINTED, not holes. See pc_shadow_fill in planet_common.gdshaderinc.
// `shadow_fill_color` is the cool skylight that survives inside a cast shadow; `shadow_fill` is how
// much of it. Set per planet from Planet._make_ground_material().
uniform vec4 shadow_fill_color : source_color = vec4(0.72, 0.80, 0.95, 1.0);
uniform float shadow_fill : hint_range(0.0, 0.6) = 0.16;
// R2.9 surface texture. `detail_grass` scales the two soft/plump grass bands, `detail_rock` the
// mineral band (sand, path, crater dust, cliff faces) and `detail_bump` the tangential normal
// perturbation that gives the meadow its soft undulating read instead of a flat mat of triangles.
uniform float detail_grass : hint_range(0.0, 4.0) = 2.7;
uniform float detail_rock : hint_range(0.0, 4.0) = 1.5;
uniform float detail_bump : hint_range(0.0, 1.0) = 0.17;
// TEXTURE IS NOT FREE IN THE TONEMAPPER. The detail bands are mean-preserving in LINEAR albedo
// (see pc_sd_mean_* ), but ACES is concave, so a symmetric multiplicative texture always renders
// DARKER on average than the flat surface it replaced - measured at 0.9% on a home gameplay
// framing, which was enough to walk the ground crop's value mean from 0.664 to 0.658 and out of
// the R2.6 gate. `detail_gain` is that 0.9% put back, so the texture costs no brightness at all.
uniform float detail_gain : hint_range(0.9, 1.1) = 1.020;
// THE TOON RAMP SATURATES. `pc_toon_diffuse` returns exactly ALBEDO wherever `lit` reaches 1, which
// is most of the sunlit ground, so a perturbed normal on its own changes nothing there — it only
// shows in the narrow band around the terminator. `detail_light` re-introduces the detail's own
// slope as a small UNCLAMPED lambert modulation of the diffuse term, which is what makes the ground
// read as soft plump forms in full sun instead of as flat mottled paint. It is a multiplier centred
// on 1.0 and hard-clamped, so it adds no energy and cannot create a hotspot (R2.6 stands).
uniform float detail_light : hint_range(0.0, 3.0) = 1.45;


varying vec3 v_world_pos;
varying vec4 v_color;
/// View-space normal BEFORE the R2.9 detail bump, so light() can measure what the bump changed.
varying vec3 v_flat_nrm;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_color = COLOR;
}

void fragment() {
	vec3 wp = v_world_pos;
	float dist = length(wp);
	vec3 dir = wp / max(dist, 0.0001);
	float h = dist - planet_radius;            // meters above nominal radius
	float wl = water_radius - planet_radius;   // water level relative to radius

	// --- triangle grass -------------------------------------------------------------------------
	// `lod` fades every sub-pixel detail toward its own average (see pc_detail_lod): without it the
	// 0.40 m triangle grid beats against the pixel grid past ~8 m and paints concentric moire rings.
	vec2 uv_m = pc_cube_uv(dir, planet_radius);
	vec2 uv = uv_m / cell_size;
	float lod = pc_detail_lod(uv);
	float fine = 1.0 - lod;
	vec2 tri = pc_tri_pattern(uv, tri_radius, tri_density);
	vec3 tri_col = mix(pc_in(color_b.rgb), pc_in(color_c.rgb), mix(step(0.62, tri.y), 0.38, lod));
	vec3 grass = mix(pc_in(color_a.rgb), tri_col, mix(tri.x, pc_tri_avg(tri_radius, tri_density), lod));
	float patch = pc_fbm3(wp * 0.11 + vec3(3.7));
	grass *= 1.0 + (patch - 0.5) * patch_strength * 2.0;
	grass = mix(grass, grass * vec3(1.03, 1.0, 0.93), smoothstep(0.55, 0.8, patch) * 0.35);
	// Broad, deliberate darker meadow regions (large scale, NOT more noise) so real dark tones exist.
	float macro = pc_fbm3(wp * 0.042 + vec3(11.3, 4.1, 7.9));
	grass = mix(grass, pc_in(shadow_color.rgb), smoothstep(0.30, 0.62, macro) * shadow_patch);
	// Sunlit meadow patches. R2.6: the old 1.34x lift pushed the brightest grass past luma 0.95 and
	// was a big part of the blown-highlight count; a gentler lift still reads as a sunlit patch.
	float macro_sun = pc_fbm3(wp * 0.055 + vec3(31.7, 2.3, 19.1));
	// NOT clamped to 1.0: clipping a strong sunlit patch clips the dominant channel first, which
	// desaturates it. That is what turned Zorp's violet into a washed lilac while chasing luma p95.
	// The albedo is allowed over 1 here; the tonemapper is what decides how bright it lands.
	//
	// WEB PARITY, THE ONE PLACE THE ROUND TRIP IS NOT GUARANTEED. pc_out()'s maxdiff-0 proof is only
	// for values in [0, 1], and this line is the one shipped multiplier that drives the albedo ABOVE
	// 1 inside fragment(): Zorp runs `sun_patch` 1.72 with `sun_patch_tint` (1.0, 1.14, 0.84), set in
	// src/planet/planet.gd:776-779. It was the prime suspect for the blotchy bleached-mint meadow on
	// the web build.
	//
	// MEASURED, AND IT IS NOT THE CAUSE. This shader was rendered on a vertex-coloured sphere under
	// BOTH renderers at the shipped values, in an isolated project with a fixed sun and a fixed
	// ambient so that nothing but the shader could differ. Five sample points, sRGB:
	//   sun_patch 1.15  F+ (66,136,83) (48,100,64) (56,117,72) (49,101,67) (50,105,68)
	//                   C  (66,136,83) (48,100,64) (56,117,72) (49,101,67) (50,105,68)   maxdiff 0
	//   sun_patch 1.72  F+ (78,160,95) (56,116,72) (68,140,83) (59,118,76) (58,120,75)
	//                   C  (78,160,95) (56,116,72) (68,140,83) (59,118,77) (58,120,75)   maxdiff 1
	// pc_l2s and the engine's srgb_to_linear are exact inverses well past 1.0 (neither clamps the high
	// end), so the over-range patch survives the round trip intact. The bleached mint is therefore the
	// SAME on both renderers - an art call about an over-range patch, not a parity bug - and it must
	// not be papered over with a compat-only clamp.
	grass = mix(grass, grass * sun_patch * pc_in(sun_patch_tint.rgb), smoothstep(sun_patch_lo, sun_patch_lo + 0.34, macro_sun) * sun_patch_amt);

	// --- sand by height, wet shore, underwater darkening ----------------------------------------
	float edge_n = (pc_noise3(wp * 0.9) - 0.5) * 0.4 * fine;
	float sand_t = 1.0 - smoothstep(wl + 0.12 + edge_n, wl + sand_band + edge_n, h);
	float wet_t = 1.0 - smoothstep(wl - 0.22, wl + 0.02, h);
	vec3 sand = pc_in(sand_color.rgb) * (1.0 + (pc_noise3(wp * 3.0) - 0.5) * 0.08 * fine);
	vec3 col = mix(grass, sand, sand_t);
	col = mix(col, pc_in(shore_color.rgb), wet_t * sand_t * 0.85);
	col *= 1.0 - 0.32 * smoothstep(wl, wl - 0.9, h);

	// --- crater dust (baked in COLOR.b) ----------------------------------------------------------
	col = mix(col, pc_in(crater_color.rgb) * (0.9 + 0.2 * patch), v_color.b * (1.0 - sand_t) * 0.55);

	// --- cliff face on plateau banks / crater walls (baked in COLOR.g) ----------------------------
	// ACNH grammar: a CLEAN warm rock face with a crisp top edge and quiet vertical striations —
	// never blotchy noise, which reads as a dirt stain smeared on the hillside.
	float bank_t = smoothstep(0.36, 0.52, v_color.g) * (1.0 - sand_t);
	// Vertical strata: thin darker seams running down the face (uv.x walks around the planet).
	float strata = 0.5 + 0.5 * sin(uv.x * cell_size * 7.0 + pc_noise3(dir * 5.0) * 4.0);
	strata = mix(strata, 0.5, lod);
	vec3 bank = pc_in(bank_color.rgb) * (0.96 + 0.08 * mix(pc_noise3(wp * 1.1), 0.5, lod));
	bank *= 1.0 - 0.10 * smoothstep(0.55, 0.95, strata);
	// A slightly lighter lip right under the grass edge so the top of the cliff reads as an edge.
	bank = mix(bank, min(bank * 1.14, vec3(1.0)), smoothstep(0.86, 0.52, v_color.g) * 0.55);
	col = mix(col, bank, bank_t);

	// --- sand paths --------------------------------------------------------------------------------
	float path_t = 0.0;
	if (path_count > 0) {
		float pd = 1e9;
		for (int i = 0; i < 8; i++) {
			if (i >= path_count) { break; }
			pd = min(pd, pc_arc_distance(dir, normalize(path_a[i]), normalize(path_b[i])));
		}
		float pm = pd * planet_radius - path_width * 0.5 + edge_n * 0.35;
		path_t = 1.0 - smoothstep(-0.05, 0.05, pm);
		float path_edge = (1.0 - smoothstep(0.0, 0.16, abs(pm + 0.06))) * 0.85;
		vec3 pc = pc_in(path_color.rgb) * (1.0 + (pc_noise3(wp * 2.5) - 0.5) * 0.10 * fine);
		pc = mix(pc, pc_in(path_edge_color.rgb), path_edge);
		col = mix(col, pc, path_t);
	}

	// --- violet: glowing river beds + specks -----------------------------------------------------
	vec3 emission = vec3(0.0);
	if (river_glow > 0.0) {
		float river_t = 1.0 - smoothstep(wl - 0.02, wl + 0.16, h);
		col = mix(col, pc_in(riverbed_color.rgb), river_t * 0.9);
		float flow = pc_noise3(wp * 1.6 + vec3(TIME * 0.35, 0.0, TIME * 0.2));
		emission += pc_in(river_color.rgb) * river_glow * river_t * (0.55 + 0.45 * flow);
	}
	if (speck_strength > 0.0) {
		vec3 sc = floor(wp * 3.5);
		float sh = pc_hash31(sc);
		vec3 cp = (sc + 0.5 + (vec3(pc_hash31(sc + 1.7), pc_hash31(sc + 2.3), pc_hash31(sc + 3.9)) - 0.5) * 0.7) / 3.5;
		float dd = length(wp - cp);
		float spot = (1.0 - smoothstep(0.035, 0.07, dd)) * step(0.905, sh) * (1.0 - sand_t);
		float pulse = 0.55 + 0.45 * sin(TIME * 2.2 + sh * 50.0);
		vec3 sc_col = mix(pc_in(speck_color_a.rgb), pc_in(speck_color_b.rgb), step(0.5, fract(sh * 7.0)));
		col = mix(col, sc_col, spot * 0.7);
		emission += sc_col * spot * pulse * speck_strength;
	}

	// --- R2.9 SURFACE TEXTURE ----------------------------------------------------------------------
	// "grass as plump softeness" / "rock should have a rougher texture". Two soft bands on the
	// living ground and one mineral band on sand, path, crater dust and cliff faces. Every band is
	// gated by pc_band_lod, so a band is faded to nothing BEFORE its wavelength approaches a pixel —
	// which is the whole reason the ground's earlier contour-ring moire happened.
	float mineral = clamp(max(max(sand_t, path_t), bank_t) + v_color.b * 0.55, 0.0, 1.0);
	float soft = 1.0 - mineral;
	float lod_c = pc_band_lod(uv_m, SD_CLUMP_HZ) * soft;
	float lod_t = pc_band_lod(uv_m, SD_TUFT_HZ) * soft;
	float lod_rc = pc_band_lod(uv_m, SD_ROCKC_HZ) * mineral;
	float lod_rf = pc_band_lod(uv_m, SD_ROCKF_HZ) * mineral;
	SdSurface sd_clump = sd_foliage(wp, dir, lod_c, detail_grass, SD_CLUMP_K);
	SdSurface sd_tuft = sd_foliage(wp, dir, lod_t, detail_grass * 0.85, SD_TUFT_K);
	SdSurface sd_rc = sd_none();
	SdSurface sd_rf = sd_none();
	if (mineral > 0.004) {
		sd_rc = sd_rock(wp, dir, lod_rc, detail_rock, SD_ROCKC_K);
		sd_rf = sd_rock(wp, dir, lod_rf, detail_rock * 0.85, SD_ROCKF_K);
	}
	// Divided by each band's own mean (pc_sd_mean_*): sd_fbm is not normalised, so an undivided band
	// darkens the whole meadow instead of texturing it — that alone moved the ground's value mean out
	// of the R2.6 gate. See the note in planet_common.gdshaderinc.
	vec3 tint_c = sd_clump.tint / pc_sd_mean_foliage(detail_grass * lod_c);
	vec3 tint_t = sd_tuft.tint / pc_sd_mean_foliage(detail_grass * 0.85 * lod_t);
	vec3 tint_rc = sd_rc.tint / pc_sd_mean_rock(detail_rock * lod_rc);
	vec3 tint_rf = sd_rf.tint / pc_sd_mean_rock(detail_rock * 0.85 * lod_rf);
	col *= tint_c * tint_t * tint_rc * tint_rf * detail_gain;
	// The bump is driven mostly by the COARSE bands. Slope scales with frequency, so a normal built
	// from the finest band would tilt by tens of degrees for the same amplitude and read as
	// sandpaper; the fine bands earn their keep in the albedo instead.
	float detail_h = (tint_c.r - 1.0) + (tint_t.r - 1.0) * 0.22
		+ (tint_rc.r - 1.0) * 0.9 + (tint_rf.r - 1.0) * 0.25;
	v_flat_nrm = NORMAL;
	vec3 sgrad = pc_surface_grad(wp, dir, detail_h);
	NORMAL = normalize(NORMAL - (VIEW_MATRIX * vec4(sgrad, 0.0)).xyz * detail_bump);

	// --- limb shading: distant / edge-on ground reads darker and cooler --------------------------
	// Driven by the GEOMETRIC radial direction against the camera, never by the interpolated NORMAL.
	// The displaced icosphere's smooth normals are only C0, so a normal-driven gradient put a kink in
	// the shading at every triangle row — which is what painted the topographic-map moire of
	// concentric contour rings across the mid-distance ground. World position interpolates smoothly.
	float facing = clamp(dot(dir, normalize(CAMERA_POSITION_WORLD - wp)), 0.0, 1.0);
	float limb = 1.0 - smoothstep(0.10, 0.86, facing);
	// A hair of screen-space dither: this gradient is so low-slope that 8-bit output alone bands it.
	limb = clamp(limb + (pc_hash21(FRAGCOORD.xy) - 0.5) * 0.016, 0.0, 1.0);
	col = mix(col, col * pc_in(limb_tint.rgb), limb * limb_darken);

	// R2.6: pastel guard last, so procedurally derived tones (bank strata, crater dust, wet shore,
	// the macro shadow blend) are capped too, not just the authored uniforms.
	ALBEDO = pc_out(pc_pastel(col, pastel_max, pastel_dark));
	ROUGHNESS = 0.98;
	METALLIC = 0.0;
	// Matte: grass and earth have no gloss. The old 0.2 put a sheen on every ground facet turned
	// toward the sun, which is what made the daytime ground read as a printed poster.
	SPECULAR = 0.02;
	AO = mix(1.0, v_color.a, ao_ambient);
	AO_LIGHT_AFFECT = 0.0;
	EMISSION = pc_out(emission * (1.0 - limb * 0.5) * mix(1.0, v_color.a, 0.5));
}

void light() {
	float lit;
	float ndl = dot(NORMAL, LIGHT);
	vec3 diffuse = pc_toon_diffuse(ALBEDO, ndl, ATTENUATION, ramp_softness, shade_strength, pc_in(shade_tint.rgb), shade_floor, LIGHT_IS_DIRECTIONAL, lit);
	// R2.9: carry the surface detail's slope into the saturated part of the toon ramp (see the
	// `detail_light` uniform). Clamped hard on both sides so it can never blow out or punch a hole.
	diffuse *= clamp(1.0 + (ndl - dot(v_flat_nrm, LIGHT)) * detail_light, 0.80, 1.22);
	vec3 lit_rgb = pc_pastel(diffuse * LIGHT_COLOR, PC_LIGHT_S_MAX, 0.0) * mix(1.0, v_color.a, ao_direct) / PI;
	DIFFUSE_LIGHT += lit_rgb;
	DIFFUSE_LIGHT += pc_shadow_fill(dot(NORMAL, LIGHT), ATTENUATION, ramp_softness, pc_in(shadow_fill_color.rgb), shadow_fill) * LIGHT_COLOR / PI;
	vec3 hv = normalize(VIEW + LIGHT);
	float ndh = max(dot(NORMAL, hv), 0.0);
	float spec = smoothstep(0.45, 0.6, pow(ndh, 40.0)) * spec_strength * lit;
	SPECULAR_LIGHT += spec * LIGHT_COLOR / PI;
}
