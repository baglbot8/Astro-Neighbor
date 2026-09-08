// Hub ground: cream tile plazas + paths (great-circle arcs) over a triangle-pattern lawn.
// Tile zones are discs (zone_dirs / zone_radii) and arcs (path_a / path_b); masks are per-pixel so
// the tile edges stay crisp. Tiles get a soft fake bevel via a normal tilt near their edges.
//
// R2.9 SURFACE TEXTURE: the plaza is the single largest untextured area in the game — a 0.75 m tile
// grid drawn on a flat cream sheet. Paving is in R2.9's "rock / stone" row (a genuinely rougher
// microsurface, chipped edges, mottled tone at two scales) and the lawn is in the grass row (plump
// softness). Bands and their reasoning: see grass_planet.gdshader, which carries the full note.
shader_type spatial;
render_mode cull_back, depth_draw_opaque, diffuse_lambert, specular_schlick_ggx;
#include "res://src/shaders/planet_common.gdshaderinc"
#include "res://src/shaders/surface_detail.gdshaderinc"

// Frequency bands (cycles/m after scaling the position handed to the sd_* function).
//   grass clump x0.26 ->  7.8 / 1.8   grass tuft x0.85 -> 25.5 / 6.0
//   stone coarse x0.20 ->  9.2 / 1.3  stone fine x0.78 -> 35.9 / 5.1
// The plaza is a 26 m world and the paving is walked over at 2-8 m, so the stone bands sit a little
// finer than the meadow's: a 3 cm chipped grain inside an 11 cm mottle, under the existing 75 cm
// tile grid. That is the "variation at two scales" the paving row asks for, plus the tile as a third.
const float SD_CLUMP_K = 0.26;
const float SD_CLUMP_HZ = 7.8;
const float SD_TUFT_K = 0.85;
const float SD_TUFT_HZ = 25.5;
const float SD_STONEC_K = 0.20;
const float SD_STONEC_HZ = 9.2;
const float SD_STONEF_K = 0.78;
const float SD_STONEF_HZ = 35.9;

// WEB PARITY. Under the Compatibility (WebGL2) renderer the web export is forced onto,
// `astro_compat` is 1.0; it is 0.0 on desktop, set once by the Platform autoload, so every wrap
// below is the exact identity on Forward+ and the reference look cannot move.
//
// This shader is converted with pc_in() / pc_out() — see the long block at the top of
// planet_common.gdshaderinc for the measurement, the probe numbers and the rules. In short:
// Compatibility does not sRGB-decode `source_color` uniforms on upload (so they arrive in display
// space and need pc_in), and it sRGB-ENCODES whatever fragment() writes to ALBEDO (so the write
// needs pc_out). Everything between the two then runs in linear on both renderers.
//
// This is the single largest surface in the game and it does a lot of arithmetic on colour: the
// triangle lawn mix, the macro shadow blend, the checker/hash tile mix, the grout mix, the curb and
// bank mixes, the weathering mix, the edge-AO multiply, the four R2.9 detail bands and pc_pastel.
// Under the old code every one of those multiplies was landing as t^2.2, which is why the hub deck
// the user photographed reads as a flat bright sheet in the browser.
//
// MEASURED, showcase/planet_hub.tscn, on a 333,582-pixel plaza mask built by the
// black-emission / white-emission probe pair (both renderers, eroded 3 px):
// Both renderers with cast shadows off, so the only thing left between the two frames is this
// shader (Compatibility ships with shadows off anyway; Forward+ was made to match for the probe):
//     before   per-pixel MAE 6.15 codes, p95 19.0, region SAT 0.3180 -> 0.3390 (gap 0.0210)
//     after    per-pixel MAE 0.25 codes, p95  1.0, region SAT 0.3180 -> 0.3173 (gap 0.0007)
//     after    region luma p05/p50/p95  F+ 140.8 187.8 202.4   C 140.7 187.8 202.3  (GAP 0.06)
// Two independent capture pairs gave MAE 0.252 both times. Forward+ did not move: the same mask
// scored between the pre- and post-conversion Forward+ frames is MAE 0.000, max 1 code — as it
// must be, since astro_compat is 0.0 there and every wrap is the identity.
// With cast shadows left ON under Forward+ the same run reads MAE 2.38 with p95 still 1.0: 96% of
// the mask is under 4 codes and the whole residual is the bench and flowerbed shadow slabs that
// Compatibility does not draw at all. That is the deliberate low-power profile, not a colour bug.
// Forcing MSAA, FXAA, SSAO and glow identical on the two renderers as well (i.e. taking the whole
// low-power profile out of the comparison) gives MAE 0.76, p95 2.0, SAT gap 0.0045, GAP 0.60 —
// the same answer from the other direction.
//
// NOT WRAPPED, deliberately: `v_color` (COLOR.g is the plateau-bank SELECTOR at the bank_t line,
// COLOR.a is baked ground occlusion), AO / ROUGHNESS / METALLIC / SPECULAR, and every literal or
// computed value. Those arrive identically on both renderers; only the source_color uniforms and
// the ALBEDO write need the encode. See rule (c)/(d) in planet_common.gdshaderinc.
global uniform float astro_compat;

uniform vec4 lawn_a : source_color = vec4(0.373, 0.690, 0.388, 1.0);
uniform vec4 lawn_b : source_color = vec4(0.247, 0.541, 0.290, 1.0);
uniform vec4 lawn_c : source_color = vec4(0.447, 0.753, 0.455, 1.0);
// Large-scale shadow tone painted over the lawn so the hub has genuine dark values.
uniform vec4 lawn_shadow : source_color = vec4(0.180, 0.396, 0.322, 1.0);
uniform float shadow_patch : hint_range(0.0, 1.0) = 0.30;
// BRIGHT WARM CREAM SANDSTONE (STYLE_GUIDE hub tiles #f6efe2 / #e9dcc3). The plaza must feel
// welcoming: its darkness comes from grout, the edge AO pool and limb shading below — never from a
// brown base colour. A muddy plaza reads as a chocolate bar.
uniform vec4 tile_a : source_color = vec4(0.949, 0.918, 0.859, 1.0);
uniform vec4 tile_b : source_color = vec4(0.886, 0.831, 0.741, 1.0);
uniform vec4 grout_color : source_color = vec4(0.663, 0.596, 0.478, 1.0);
uniform vec4 curb_color : source_color = vec4(0.827, 0.769, 0.663, 1.0);
uniform vec4 bank_color : source_color = vec4(0.851, 0.639, 0.451, 1.0);
// Weathering tone: the SAME cream family, only darker — a stone that has seen rain, not dirt.
uniform vec4 tile_shadow : source_color = vec4(0.596, 0.541, 0.451, 1.0);
uniform float tile_weather : hint_range(0.0, 1.0) = 0.45;
// Soft ambient-occlusion pool where the paving meets the lawn / curb. This is where the plaza's dark
// tones live: contact shade, not brown albedo.
uniform float edge_ao : hint_range(0.0, 1.0) = 0.46;
uniform float edge_ao_width = 0.85;
uniform float joint_ao : hint_range(0.0, 1.0) = 0.16;
uniform vec4 sand_color : source_color = vec4(0.859, 0.788, 0.612, 1.0);
uniform vec4 shore_color : source_color = vec4(0.620, 0.560, 0.420, 1.0);
uniform float limb_darken : hint_range(0.0, 1.0) = 0.55;
// R2.6: near-neutral cool. A blue limb tint on a warm cream plaza drove the far tiles to a
// saturated amber and the far lawn to a vivid emerald.
uniform vec4 limb_tint : source_color = vec4(0.78, 0.81, 0.88, 1.0);
// R2.6 pastel guard (pc_pastel in planet_common.gdshaderinc). The plaza must stay CREAM: this caps
// chroma without darkening, so it can never slide to chocolate.
uniform float pastel_max : hint_range(0.05, 1.0) = 0.58;
uniform float pastel_dark : hint_range(0.0, 1.0) = 0.34;
uniform float planet_radius = 26.0;
uniform float water_radius = 25.65;
uniform float sand_band = 0.24;
uniform float cell_size = 0.40;
uniform float tri_radius = 0.17;
uniform float tri_density = 0.72;
uniform float tile_size = 0.75;
uniform float grout = 0.042;
uniform float tile_corner = 0.07;
uniform float bevel = 0.24;
uniform int zone_count = 0;
uniform vec3 zone_dirs[8];
uniform float zone_radii[8];
uniform int path_count = 0;
uniform vec3 path_a[8];
uniform vec3 path_b[8];
uniform float path_width = 2.2;
uniform float ramp_softness : hint_range(0.01, 1.0) = 0.35;
uniform float shade_strength : hint_range(0.0, 1.0) = 0.42;
uniform float shade_floor : hint_range(0.0, 1.0) = 0.27;
uniform vec4 shade_tint : source_color = vec4(0.62, 0.55, 0.85, 1.0);
// Baked ground occlusion (Planet._bake_color -> COLOR.a): a contact pool under every bench, bed,
// lamp, topiary and tree, plus the feet of the landforms. Multiplies the LIT result, not the albedo.
uniform float ao_ambient : hint_range(0.0, 1.0) = 1.0;
uniform float ao_direct : hint_range(0.0, 1.0) = 0.85;

// R2.6 / ACNH: cast shadows are TINTED, not holes. See pc_shadow_fill in planet_common.gdshaderinc.
// `shadow_fill_color` is the cool skylight that survives inside a cast shadow; `shadow_fill` is how
// much of it. Set per planet from Planet._make_ground_material().
uniform vec4 shadow_fill_color : source_color = vec4(0.72, 0.80, 0.95, 1.0);
uniform float shadow_fill : hint_range(0.0, 0.6) = 0.16;
// R2.9 surface texture. See grass_planet.gdshader for what each of these does; `detail_light` exists
// because the toon ramp saturates and a bumped normal would otherwise be invisible in full sun.
uniform float detail_grass : hint_range(0.0, 4.0) = 2.7;
uniform float detail_stone : hint_range(0.0, 4.0) = 1.35;
uniform float detail_bump : hint_range(0.0, 1.0) = 0.22;
// See grass_planet.gdshader for what this is for. MEASURED AT 1.0 HERE ON PURPOSE: the plaza is a
// bright cream surface sitting on the compressive shoulder of ACES, where a symmetric texture
// costs almost no mean brightness (0.754 -> 0.754 on a hub gameplay crop) — unlike the meadow,
// which sits lower on the curve and loses ~1%. At 1.014 the hub's ground crop went 0.759 -> 0.762
// and out of the top of the value-mean gate, so the compensation is left off here.
uniform float detail_gain : hint_range(0.9, 1.1) = 1.0;
uniform float detail_light : hint_range(0.0, 3.0) = 1.45;


varying vec3 v_world_pos;
varying vec3 v_world_nrm;
varying vec4 v_color;
/// View-space normal BEFORE the R2.9 detail bump, so light() can measure what the bump changed.
varying vec3 v_flat_nrm;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_nrm = normalize(mat3(MODEL_MATRIX) * NORMAL);
	v_color = COLOR;
}

float tile_sdf(vec2 uv, out vec2 cell) {
	vec2 g = uv / tile_size;
	cell = floor(g);
	vec2 p = (fract(g) - 0.5) * tile_size;
	return pc_rbox_sdf(p, vec2(tile_size * 0.5 - grout * 0.5), tile_corner);
}

void fragment() {
	vec3 wp = v_world_pos;
	float dist = length(wp);
	vec3 dir = wp / max(dist, 0.0001);
	float h = dist - planet_radius;
	float wl = water_radius - planet_radius;

	// --- lawn -------------------------------------------------------------------------------------
	vec2 uv = pc_cube_uv(dir, planet_radius);
	// Sub-pixel detail fades to its own average (pc_detail_lod) — a hard per-cell pattern that
	// undersamples paints concentric moire rings across the mid-distance ground.
	float lod_g = pc_detail_lod(uv / cell_size);
	float lod_t = pc_detail_lod(uv / tile_size);
	float fine_t = 1.0 - lod_t;
	vec2 tri = pc_tri_pattern(uv / cell_size, tri_radius, tri_density);
	vec3 tri_col = mix(pc_in(lawn_b.rgb), pc_in(lawn_c.rgb), mix(step(0.62, tri.y), 0.38, lod_g));
	vec3 lawn = mix(pc_in(lawn_a.rgb), tri_col, mix(tri.x, pc_tri_avg(tri_radius, tri_density), lod_g));
	float patch = pc_fbm3(wp * 0.11 + vec3(3.7));
	lawn *= 1.0 + (patch - 0.5) * 0.12;
	float macro = pc_fbm3(wp * 0.042 + vec3(11.3, 4.1, 7.9));
	lawn = mix(lawn, pc_in(lawn_shadow.rgb), smoothstep(0.40, 0.70, macro) * shadow_patch);

	// --- sand near water --------------------------------------------------------------------------
	float edge_n = (pc_noise3(wp * 0.9) - 0.5) * 0.4 * (1.0 - lod_g);
	float sand_t = 1.0 - smoothstep(wl + 0.12 + edge_n, wl + sand_band + edge_n, h);
	float wet_t = 1.0 - smoothstep(wl - 0.22, wl + 0.02, h);
	vec3 ground = mix(lawn, pc_in(sand_color.rgb), sand_t);
	ground = mix(ground, pc_in(shore_color.rgb), wet_t * sand_t * 0.85);
	ground *= 1.0 - 0.32 * smoothstep(wl, wl - 0.9, h);

	// --- tile region signed distance (meters, negative inside) ----------------------------------
	float sd_zone = 1e9;
	for (int i = 0; i < 8; i++) {
		if (i >= zone_count) { break; }
		float ang = acos(clamp(dot(dir, normalize(zone_dirs[i])), -1.0, 1.0));
		sd_zone = min(sd_zone, ang * planet_radius - zone_radii[i]);
	}
	for (int i = 0; i < 8; i++) {
		if (i >= path_count) { break; }
		float ang = pc_arc_distance(dir, normalize(path_a[i]), normalize(path_b[i]));
		sd_zone = min(sd_zone, ang * planet_radius - path_width * 0.5);
	}
	sd_zone += edge_n * 0.35;
	float tile_mask = 1.0 - smoothstep(-0.06, 0.06, sd_zone);
	float curb = 1.0 - smoothstep(0.10, 0.20, abs(sd_zone + 0.05));

	// --- tiles ------------------------------------------------------------------------------------
	vec2 cell;
	float sd = tile_sdf(uv, cell);
	float ch = pc_hash21(cell);
	float checker = mod(cell.x + cell.y, 2.0);
	vec3 tcol = mix(pc_in(tile_a.rgb), pc_in(tile_b.rgb), checker * 0.22 + ch * 0.28);
	tcol *= 1.0 + (pc_noise3(wp * 4.0) - 0.5) * 0.06 * fine_t;
	float aa = fwidth(sd) + 0.003;
	// 0.89 is the fraction of a cell that is stone rather than grout — the pattern's own mean.
	float in_tile = mix(1.0 - smoothstep(-aa, aa, sd), 0.89, lod_t);
	// Joint shadow: a thin band of contact AO on the stone right beside the grout. Real paving reads
	// dark at the joints, so the plaza can stay bright cream and still carry value structure.
	tcol *= 1.0 - joint_ao * mix(smoothstep(-0.075, -0.006, sd), 0.82, lod_t);
	vec3 tiles = mix(pc_in(grout_color.rgb), tcol, in_tile);
	// Fake bevel: tilt the normal outward near tile edges.
	float e = 0.01;
	vec2 c2;
	float gx = tile_sdf(uv + vec2(e, 0.0), c2) - sd;
	float gy = tile_sdf(uv + vec2(0.0, e), c2) - sd;
	vec2 grad = vec2(gx, gy) / e;
	float bev = (1.0 - smoothstep(-0.10, -0.01, sd)) * smoothstep(-0.16, -0.10, sd) * bevel * tile_mask * fine_t;
	// world tangent frame for this cube face
	vec3 a3 = abs(dir);
	vec3 tu; vec3 tv;
	if (a3.x >= a3.y && a3.x >= a3.z) { tu = vec3(0.0, 0.0, sign(dir.x)); tv = vec3(0.0, 1.0, 0.0); }
	else if (a3.y >= a3.z) { tu = vec3(1.0, 0.0, 0.0); tv = vec3(0.0, 0.0, sign(dir.y)); }
	else { tu = vec3(-sign(dir.z), 0.0, 0.0); tv = vec3(0.0, 1.0, 0.0); }
	vec3 wn = normalize(v_world_nrm + (tu * grad.x + tv * grad.y) * bev);
	NORMAL = normalize((VIEW_MATRIX * vec4(wn, 0.0)).xyz);

	vec3 col = mix(ground, tiles, tile_mask);
	col = mix(col, pc_in(curb_color.rgb), curb * 0.9);
	// Exposed rock on plateau banks / crater walls (baked in COLOR.g), lawn only: a clean warm
	// sandstone cliff face with vertical striations, NOT a blotchy earth stain.
	float bank_t = smoothstep(0.36, 0.50, v_color.g) * (1.0 - tile_mask) * (1.0 - sand_t);
	float strata = mix(pc_noise3(vec3(uv.x * 9.0, dir.y * 3.0, uv.y * 9.0)), 0.5, lod_t);
	vec3 bank = pc_in(bank_color.rgb) * (0.94 + 0.10 * strata);
	col = mix(col, bank, bank_t);
	// Weathering: same cream family, a few percent of value — enough to break the flat plate.
	col = mix(col, pc_in(tile_shadow.rgb), smoothstep(0.30, 0.70, pc_fbm3(wp * 0.075 + vec3(5.5))) * tile_weather * tile_mask);
	// Contact AO where the paving meets lawn/curb, and a matching pool on the grass just outside it.
	float ao_in = smoothstep(-edge_ao_width, -0.05, sd_zone) * tile_mask;
	float ao_out = (1.0 - smoothstep(0.05, edge_ao_width * 0.7, sd_zone)) * step(0.0, sd_zone);
	col *= 1.0 - edge_ao * max(ao_in, ao_out * 0.7);

	// --- R2.9 SURFACE TEXTURE ----------------------------------------------------------------------
	// Stone on everything paved, quarried or sandy; plump grass softness on the lawn. Each band is
	// gated by pc_band_lod against its own dominant frequency, so nothing is ever sampled near
	// Nyquist and the plaza cannot grow the contour-ring moire the ground already had to lose once.
	float stone_m = clamp(max(max(tile_mask, curb), max(sand_t, bank_t)), 0.0, 1.0);
	float soft_m = 1.0 - stone_m;
	float sdlod_c = pc_band_lod(uv, SD_CLUMP_HZ) * soft_m;
	float sdlod_t = pc_band_lod(uv, SD_TUFT_HZ) * soft_m;
	float sdlod_sc = pc_band_lod(uv, SD_STONEC_HZ) * stone_m;
	float sdlod_sf = pc_band_lod(uv, SD_STONEF_HZ) * stone_m;
	SdSurface sd_clump = sd_foliage(wp, dir, sdlod_c, detail_grass, SD_CLUMP_K);
	SdSurface sd_tuft = sd_foliage(wp, dir, sdlod_t, detail_grass * 0.85, SD_TUFT_K);
	SdSurface sd_sc = sd_none();
	SdSurface sd_sf = sd_none();
	if (stone_m > 0.004) {
		sd_sc = sd_rock(wp, dir, sdlod_sc, detail_stone, SD_STONEC_K);
		sd_sf = sd_rock(wp, dir, sdlod_sf, detail_stone * 0.9, SD_STONEF_K);
	}
	// Divided by each band's own mean — sd_fbm is not normalised and an undivided band darkens the
	// plaza instead of texturing it (see planet_common.gdshaderinc).
	vec3 tint_c = sd_clump.tint / pc_sd_mean_foliage(detail_grass * sdlod_c);
	vec3 tint_t = sd_tuft.tint / pc_sd_mean_foliage(detail_grass * 0.85 * sdlod_t);
	vec3 tint_sc = sd_sc.tint / pc_sd_mean_rock(detail_stone * sdlod_sc);
	vec3 tint_sf = sd_sf.tint / pc_sd_mean_rock(detail_stone * 0.9 * sdlod_sf);
	col *= tint_c * tint_t * tint_sc * tint_sf * detail_gain;
	// Stone is genuinely rougher than the lawn beside it; the toon lobe reads ROUGHNESS.
	float detail_h = (tint_c.r - 1.0) + (tint_t.r - 1.0) * 0.22
		+ (tint_sc.r - 1.0) * 0.9 + (tint_sf.r - 1.0) * 0.25;
	v_flat_nrm = NORMAL;
	vec3 sgrad = pc_surface_grad(wp, dir, detail_h);
	NORMAL = normalize(NORMAL - (VIEW_MATRIX * vec4(sgrad, 0.0)).xyz * detail_bump);
	// Limb shading driven by the GEOMETRIC radial direction, not the (bevelled, only-C0) NORMAL —
	// see the same note in grass_planet.gdshader. A normal-driven gradient contours the tessellation.
	float facing = clamp(dot(dir, normalize(CAMERA_POSITION_WORLD - wp)), 0.0, 1.0);
	float limb = 1.0 - smoothstep(0.10, 0.86, facing);
	limb = clamp(limb + (pc_hash21(FRAGCOORD.xy) - 0.5) * 0.016, 0.0, 1.0);
	col = mix(col, col * pc_in(limb_tint.rgb), limb * limb_darken);

	ALBEDO = pc_out(pc_pastel(col, pastel_max, pastel_dark));
	// Paving is polished-ish stone; the R2.9 microsurface roughens it back up unevenly.
	ROUGHNESS = clamp(mix(0.98, 0.92, tile_mask) + sd_sc.rough * 0.5 + sd_sf.rough * 0.5, 0.0, 1.0);
	METALLIC = 0.0;
	// Matte: lawn and unpolished sandstone paving. R2.6.
	SPECULAR = mix(0.02, 0.05, tile_mask);
	AO = mix(1.0, v_color.a, ao_ambient);
	AO_LIGHT_AFFECT = 0.0;
}

void light() {
	float lit;
	float ndl = dot(NORMAL, LIGHT);
	vec3 diffuse = pc_toon_diffuse(ALBEDO, ndl, ATTENUATION, ramp_softness, shade_strength, pc_in(shade_tint.rgb), shade_floor, LIGHT_IS_DIRECTIONAL, lit);
	// R2.9: carry the surface detail's slope into the saturated part of the toon ramp. Clamped, so
	// it adds no energy and cannot make a hotspot (R2.6 stands).
	diffuse *= clamp(1.0 + (ndl - dot(v_flat_nrm, LIGHT)) * detail_light, 0.80, 1.22);
	DIFFUSE_LIGHT += pc_pastel(diffuse * LIGHT_COLOR, PC_LIGHT_S_MAX, 0.0) * mix(1.0, v_color.a, ao_direct) / PI;
	DIFFUSE_LIGHT += pc_shadow_fill(dot(NORMAL, LIGHT), ATTENUATION, ramp_softness, pc_in(shadow_fill_color.rgb), shadow_fill) * LIGHT_COLOR / PI;
	vec3 hv = normalize(VIEW + LIGHT);
	float ndh = max(dot(NORMAL, hv), 0.0);
	float spec = smoothstep(0.45, 0.6, pow(ndh, 60.0)) * 0.06 * lit * (1.0 - ROUGHNESS);
	SPECULAR_LIGHT += spec * LIGHT_COLOR / PI;
}
