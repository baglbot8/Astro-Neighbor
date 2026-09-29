shader_type spatial;
// THE METEOR'S CRUST (docs/STORY_HOME_SPEC.md 9.2: "dark crust, glowing seams"; builder METEOR; textures
// beefed up by builder METEOR2 for spec 9.5.4, "the textures of the planet seem to be a bit plain compared
// to our other planets"). A dark cool-violet stone, still strange and still dark, now built in layers the
// way the planets' ground is (STYLE_GUIDE R2.9 rock: "rougher microsurface, chipped edges, mottled tonal
// variation at two scales"):
//   1. TONE REGIONS (0.22 /m): the old two-tone mottle, plus a slow ash/glass split - dull ash-grey dust
//      patches and darker glassy basalt - so the ground is never one violet.
//   2. PLATES (cells ~1.1 m): the crust is broken into cooled plates, each its own shade (cellular noise,
//      F1/F2 on the object-space position). The gaps between plates are thin dark cracks, and each plate's
//      edge is a touch lighter where it chipped (the "chipped edges").
//   3. GRAIN (5 and 12 /m): pitted, gritty microsurface, value-noise, faded out by its own screen-space
//      rate (pc_band_lod) so it never moires on the phone.
//   4. FLECKS: a sparse sprinkle of tiny mineral glints, violet and teal - the strange part.
//   5. THE LAVA FLOWS: the old warm glowing seams, the same network, meandering, pinching and swelling, a hot
//      core and red banks, crusting over near the eye and in stretches (builder LOOKOUT); a crusted lighter lip
//      and a scorched halo; plus a second, dim, dull-red network of half-cooled seams between them.
//   6. BUMP: plates raised, cracks and pits sunk, as a surface-gradient normal (pc_surface_grad, the
//      ground's own method: two derivatives, no extra noise samples).
//   7. RISE MODE (builder RISE, 2026-09-29; `rise_mode` 1 on the lookout rises only, meteor_vantage.gd, whose
//      meshes are written in this same rock space so layers 1-6 run onto them seamlessly): cooled-lava strata
//      on the steep faces, a dark contact where the rise meets the ground (UV2.x = fraction of the way up; not COLOR, which the
//      Compatibility renderer turns sRGB-to-linear), the
//      open lava damped on its back, and the guide - one faint, broken teal crystal vein up the walkable back
//      (UV = across the ridge, along the back from the crest; UV2.y 1 = a loose stone: no vein, no strata).
// The plate and grain layers are skipped past PLATE_FAR_M / fade with distance, so the far crust costs
// what the old one did. Matte: no specular (R2.6).
render_mode diffuse_lambert_wrap, specular_disabled;

#include "res://src/shaders/planet_common.gdshaderinc"

uniform vec3 crust_dark : source_color = vec3(0.215, 0.195, 0.275);
uniform vec3 crust_light : source_color = vec3(0.430, 0.395, 0.505);
uniform vec3 ash : source_color = vec3(0.415, 0.400, 0.430);
uniform vec3 glassy : source_color = vec3(0.150, 0.130, 0.200);
uniform vec3 scorch : source_color = vec3(0.090, 0.070, 0.095);
uniform vec3 fleck_a : source_color = vec3(0.780, 0.620, 1.000);
uniform vec3 fleck_b : source_color = vec3(0.450, 0.950, 0.880);
uniform vec3 seam_color : source_color = vec3(1.0, 0.54, 0.24);
uniform vec3 lava_core : source_color = vec3(1.0, 0.76, 0.34);
uniform vec3 cool_seam_color : source_color = vec3(0.62, 0.16, 0.12);
uniform float seam_energy = 1.35;
uniform float seam_scale = 0.16;
uniform float seam_width = 0.045;
uniform float plate_scale = 0.9;
uniform float bump = 0.22;
uniform float rise_mode = 0.0;
uniform float vein_len = 0.0;
uniform vec3 vein_color : source_color = vec3(0.50, 0.95, 0.86);

varying vec3 obj_pos;
varying vec2 rise_uv;
varying vec2 rise_uv2;

vec3 hash3(vec3 p) {
	p = vec3(dot(p, vec3(127.1, 311.7, 74.7)), dot(p, vec3(269.5, 183.3, 246.1)), dot(p, vec3(113.5, 271.9, 124.6)));
	return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

// Gradient noise, -1..1.
float gnoise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	vec3 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(dot(hash3(i + vec3(0, 0, 0)), f - vec3(0, 0, 0)), dot(hash3(i + vec3(1, 0, 0)), f - vec3(1, 0, 0)), u.x),
				mix(dot(hash3(i + vec3(0, 1, 0)), f - vec3(0, 1, 0)), dot(hash3(i + vec3(1, 1, 0)), f - vec3(1, 1, 0)), u.x), u.y),
			mix(mix(dot(hash3(i + vec3(0, 0, 1)), f - vec3(0, 0, 1)), dot(hash3(i + vec3(1, 0, 1)), f - vec3(1, 0, 1)), u.x),
				mix(dot(hash3(i + vec3(0, 1, 1)), f - vec3(0, 1, 1)), dot(hash3(i + vec3(1, 1, 1)), f - vec3(1, 1, 1)), u.x), u.y), u.z);
}

// Cellular noise: x = F1, y = F2 (distances to the nearest and second-nearest feature point), z = the
// nearest cell's own random 0..1 (its plate shade). The cheap 2x2x2 form: the eight cells round the corner
// nearest p, one hash each (feature point and shade both drawn from it), jitter 0.5 so the nearest point is
// always among them. A full 3x3x3 search with four hashes a cell measured +1.2-2.2 ms a frame on the desktop
// (Compatibility, 1560x720); this costs a quarter of that. The warp in fragment() hides the regularity.
vec3 cells(vec3 p) {
	vec3 i = floor(p - 0.5);
	vec3 f = p - i;
	float f1 = 8.0;
	float f2 = 8.0;
	float id = 0.0;
	for (int z = 0; z <= 1; z++) {
		for (int y = 0; y <= 1; y++) {
			for (int x = 0; x <= 1; x++) {
				vec3 g = vec3(float(x), float(y), float(z));
				float h = pc_hash31(i + g);
				vec3 o = fract(vec3(h * 17.13, h * 41.71, h * 97.37)) - 0.5;
				vec3 r = g + 0.5 + o * 0.5 - f;
				float d = dot(r, r);
				if (d < f1) {
					f2 = f1;
					f1 = d;
					id = fract(h * 213.7);
				} else if (d < f2) {
					f2 = d;
				}
			}
		}
	}
	return vec3(sqrt(f1), sqrt(f2), id);
}

const float PLATE_FAR_M = 26.0;

void vertex() {
	obj_pos = VERTEX;
	rise_uv = UV;
	rise_uv2 = UV2;
}

void fragment() {
	vec3 p = obj_pos;
	float dist = length(VERTEX);

	// 1. TONE REGIONS - the old two-scale mottle, then the ash / glassy split.
	float big = gnoise(p * 0.22) * 0.5 + 0.5;
	float fine_fade = 1.0 - smoothstep(4.0, 16.0, dist);
	float fine = (gnoise(p * 2.3) * 0.5) * fine_fade;
	float tone = clamp(big * 0.85 + fine * 0.35, 0.0, 1.0);
	vec3 base = mix(crust_dark, crust_light, tone);
	float region = gnoise(p * 0.11 + vec3(4.0, 1.0, 7.0));
	base = mix(base, ash, smoothstep(0.12, 0.42, region) * 0.45);
	base = mix(base, glassy, smoothstep(-0.12, -0.40, region) * 0.55);

	float height = 0.0;
	vec3 emit = vec3(0.0);
	// The plate field, kept for the lava's crust (5).
	float plate_edge = 1.0;
	float plate_id = 0.5;
	float plate_k = 0.0;
	// 2. PLATES and 3. GRAIN, near only.
	if (dist < PLATE_FAR_M) {
		float near_k = 1.0 - smoothstep(PLATE_FAR_M * 0.6, PLATE_FAR_M, dist);
		// Warped, so the plates are irregular flakes rather than paving; and the crack network is broken
		// (some edges are sealed) so it reads as fractured crust, not tiles.
		vec3 warp = vec3(pc_noise3(p * 0.7), pc_noise3(p * 0.7 + vec3(7.3)), pc_noise3(p * 0.7 + vec3(3.9))) - 0.5;
		vec3 cl = cells(p * plate_scale + warp * 1.1);
		float edge = cl.y - cl.x;   // 0 on the crack between two plates
		plate_edge = edge;
		plate_id = cl.z;
		plate_k = near_k;
		float crack_w = 0.03 + 0.04 * smoothstep(4.0, 18.0, dist);
		float open_k = smoothstep(0.35, 0.6, pc_noise3(p * 0.45 + vec3(5.0, 2.0, 8.0)));
		float crack = (1.0 - smoothstep(0.0, crack_w, edge)) * near_k * mix(0.25, 1.0, open_k);
		float lip = (smoothstep(crack_w, crack_w * 2.2, edge) - smoothstep(crack_w * 2.2, crack_w * 5.0, edge)) * near_k;
		float plate_shade = (cl.z - 0.5) * 0.22 * near_k;
		base *= 1.0 + plate_shade;
		base = mix(base, base * 1.22 + vec3(0.02), lip * 0.55);
		base = mix(base, scorch, crack * 0.8);
		height += (1.0 - crack) * 0.35 - crack * 0.6 + plate_shade * 0.6;

		vec2 uvm = vec2(p.x + p.y * 0.37, p.z - p.y * 0.61);
		float g1k = pc_band_lod(uvm, 5.0) * near_k;
		float g2k = pc_band_lod(uvm, 12.0) * near_k;
		float g1 = (pc_noise3(p * 5.0) - 0.5) * g1k;
		float g2 = (pc_noise3(p * 12.0 + vec3(3.0)) - 0.5) * g2k;
		base *= 1.0 + g1 * 0.28 + g2 * 0.22;
		// Pits: the low spots of the coarse grain, darker and sunk.
		float pit = smoothstep(0.22, 0.34, -g1) * g1k;
		base = mix(base, base * 0.6, pit);
		height += g1 * 0.8 + g2 * 0.45 - pit * 0.5;

		// 4. FLECKS: one candidate per 0.14 m cell, ~5% of them lit.
		vec3 fc = floor(p * 7.0);
		float fh = pc_hash31(fc);
		vec3 fo = vec3(pc_hash31(fc + vec3(1.3)), pc_hash31(fc + vec3(2.7)), pc_hash31(fc + vec3(4.1)));
		float fd = length(fract(p * 7.0) - fo);
		float fleck = step(0.95, fh) * (1.0 - smoothstep(0.08, 0.2, fd)) * g1k;
		vec3 fcol = mix(fleck_a, fleck_b, step(0.975, fh));
		base = mix(base, fcol, fleck * 0.8);
		emit = fcol * fleck * 0.25;
	}

	// 7a. RISE: strata on the steep faces, a darker contact at the ground (before the lava so it can still cross the
	// contact). `rise_k` 0 on the ground's own mesh, so the ground is untouched.
	float rise_k = rise_mode * (1.0 - rise_uv2.y);
	float up_frac = rise_uv2.x;
	if (rise_mode > 0.5) {
		vec3 ng = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
		float steep = 1.0 - dot(ng, normalize(p));
		float sk = smoothstep(0.26, 0.5, steep) * rise_k;   // ~42-60 deg: the flanks and the cliff, not the lumps on top
		float hr = length(p) * 2.4 + gnoise(p * vec3(0.9, 0.35, 0.9)) * 0.9;
		float lay = floor(hr);
		float band = fract(hr);
		float lay_tone = fract(sin(lay * 12.9898 + 4.1) * 43758.5453);
		vec3 strata = mix(crust_dark * 0.78, mix(crust_light, ash, 0.35) * 0.92, lay_tone * 0.8 + 0.1);
		strata *= 1.0 + (gnoise(p * vec3(6.0, 1.2, 6.0)) * 0.18);
		float seam_line = 1.0 - smoothstep(0.0, 0.1, band);
		float ledge = smoothstep(0.84, 0.97, band) * (1.0 - smoothstep(0.97, 1.0, band));
		strata = mix(strata, scorch, seam_line * 0.75);
		strata = mix(strata, strata * 1.28 + vec3(0.02), ledge * 0.6);
		base = mix(base, strata, sk * 0.92);
		height += (ledge * 0.5 - seam_line * 0.7) * sk;
		// Lower faces and the ground contact sit in their own shade.
		base *= mix(1.0, 0.88, sk);
		base = mix(base, base * 0.55, (1.0 - smoothstep(0.0, 0.22, up_frac)) * rise_k * 0.8);
	}

	// 5. THE LAVA FLOWS - the warm open seams (the same network, the same place), made to read as molten rock
	// that ran (builder LOOKOUT, 2026-09-29; the lead: "make the lava stripe near the lookouts read as a natural
	// flow, not a straight band"). Before, each was one zero line of a smooth noise at one width: a smooth, even,
	// glowing ribbon. Now: (a) the line meanders at ~2-4 m (a warp from one extra noise, `m`); (b) it pinches and
	// swells along its length (width x0.35..1.6 from the tone field `big`); (c) a yellow core, orange body and deep
	// red banks; (d) near the eye the banks crust over into the crust's own plates, glowing only in the gaps, and
	// odd plates ride the middle; (e) stretches go dim where the flow has crusted over (`m` high), so a flow comes
	// and goes like a channel with roofed-over parts instead of running unbroken over the horizon.
	float m = gnoise(p * 0.42 + vec3(2.0, 9.0, 4.0));
	vec3 sp = p * seam_scale + vec3(3.1, 7.7, 1.3) + vec3(0.3, -0.2, 0.25) * m;
	float n = gnoise(sp);
	// A rise is cooled rock: no flow (open, crusted or its scorched halo) on its back and crest, only where it meets
	// the ground. Damping just the glow left the flow's dark crusted band lying over the crest (first crest frames).
	float lava_k = 1.0 - rise_mode * smoothstep(0.02, 0.1, up_frac);
	float mask = smoothstep(0.02, 0.22, gnoise(p * 0.07 + vec3(9.0, 2.0, 5.0)) * 0.5 + 0.25) * lava_k;
	float w = seam_width * (1.0 + smoothstep(8.0, 30.0, dist) * 1.5) * mix(0.35, 1.6, smoothstep(0.2, 0.8, big));
	float across = abs(n) / w + fine * 0.35;          // 0 on the flow's middle line, 1 at its banks (ragged near)
	float body = 1.0 - smoothstep(0.7, 1.0, across);
	float roofed = smoothstep(0.25, 0.6, m);          // crusted-over stretches
	// Crust on the flow, near only: the banks' plates cool first, the middle stays molten but for a few rafts.
	float gap = 1.0 - smoothstep(0.02, 0.07, plate_edge);
	float raft = step(0.78, plate_id) * (1.0 - gap);
	float crust_k = plate_k * (1.0 - gap) * max(smoothstep(0.35, 0.85, across), raft * 0.85);
	crust_k = max(crust_k, roofed * (1.0 - gap * plate_k * 0.7));
	float heat = body * (1.0 - crust_k) * mask;
	float halo = (1.0 - smoothstep(0.0, 3.5, across)) * mask;
	float seam_lip = (smoothstep(1.0, 1.5, across) - smoothstep(1.5, 2.4, across)) * mask;
	base = mix(base, scorch, halo * 0.55);
	base = mix(base, crust_light * 1.1, seam_lip * 0.35);
	height -= halo * 0.4;
	vec3 flow = mix(lava_core, seam_color, smoothstep(0.0, 0.5, across + (1.0 - heat) * 0.4));
	flow = mix(flow, cool_seam_color, smoothstep(0.45, 1.0, across));
	float n2 = gnoise(p * seam_scale * 2.3 + vec3(11.0, 5.0, 2.0));
	float w2 = seam_width * (1.0 + smoothstep(8.0, 30.0, dist) * 1.5) * 0.55;
	float cool_mask = smoothstep(0.1, 0.3, gnoise(p * 0.09 + vec3(1.0, 8.0, 3.0)) * 0.5 + 0.3) * (1.0 - mask) * mix(1.0, 0.4, 1.0 - lava_k);
	float cool = (1.0 - smoothstep(0.0, w2, abs(n2))) * cool_mask;
	base = mix(base, scorch, (1.0 - smoothstep(0.0, w2 * 3.0, abs(n2))) * cool_mask * 0.4);
	base = mix(base, cool_seam_color * 0.5, cool * 0.7);
	float breathe = 0.82 + 0.18 * sin(TIME * 1.3 + p.x * 0.21 + p.z * 0.17);
	// The crusted parts of a flow keep a dark-red ember look; the open parts glow.
	base = mix(base, mix(scorch, cool_seam_color * 0.45, 0.3), body * mask * crust_k);
	ALBEDO = mix(base, flow * 0.6, heat);
	// 7b. THE GUIDE VEIN (rise only): a thin broken teal line of crystal up the walkable back, wandering a little,
	// from just past the foot to the crest's middle; brightest near the top, gone in stretches.
	vec3 vein_emit = vec3(0.0);
	if (rise_mode > 0.5 && vein_len > 0.0) {
		float vu = rise_uv.y;
		float vx = rise_uv.x - (0.22 * sin(vu * 0.85 + 1.3) + 0.09 * sin(vu * 2.3 + 0.4) + gnoise(vec3(vu * 1.7, 2.0, 5.0)) * 0.06);
		float along = (1.0 - smoothstep(vein_len - 1.2, vein_len, vu)) * smoothstep(-0.4, 0.3, vu);
		// The crack runs the whole way (dark); the crystal in it shows only in stretches, so from below it reads as
		// a few glints climbing the slope, not a painted line.
		float lit = smoothstep(0.05, 0.3, gnoise(vec3(vu * 1.25, 7.0, 1.0)) + 0.12);
		float vw = 0.016 * (0.7 + 0.6 * (gnoise(vec3(vu * 3.1, 1.0, 9.0)) * 0.5 + 0.5)) * (1.0 + smoothstep(8.0, 24.0, dist) * 0.5);
		float crack_v = (1.0 - smoothstep(vw, vw * 2.2, abs(vx))) * along * rise_k;
		float core = (1.0 - smoothstep(vw * 0.4, vw, abs(vx))) * along * lit * rise_k;
		float glow = (1.0 - smoothstep(vw, vw * 4.0, abs(vx))) * along * lit * rise_k;
		float lift = mix(0.5, 1.0, 1.0 - smoothstep(0.0, vein_len, vu));
		ALBEDO = mix(ALBEDO, scorch, crack_v * 0.8);
		ALBEDO = mix(ALBEDO, vein_color * 0.7, core * 0.75);
		vein_emit = vein_color * (core * 0.75 + glow * 0.06) * lift * (0.8 + 0.2 * sin(TIME * 0.9 + vu * 0.7));
		height -= crack_v * 0.6;
	}
	EMISSION = emit + flow * heat * seam_energy * breathe + cool_seam_color * body * mask * crust_k * 0.12
		+ cool_seam_color * cool * 0.35 * (0.7 + 0.3 * breathe) + vein_emit;

	// 6. BUMP from the height field (world = object space here: the rock sits at the origin, unrotated).
	vec3 nw = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec3 sgrad = pc_surface_grad(p, nw, height * 0.12);
	NORMAL = normalize(NORMAL - (VIEW_MATRIX * vec4(sgrad, 0.0)).xyz * bump * 6.0);
	ROUGHNESS = 0.96;
}
