// Deep-space sky for the solar-system map (src/rocket/space_travel.gd).
//
// IT ALSO HAS TO BE ABLE TO IMPERSONATE THE GROUND SKY. The rocket journey (STYLE_GUIDE R2.5) cuts
// from a planet scene into this one mid-flight and back again, and Godot cannot cross-fade two
// scenes - so on the seam frame this shader has to paint EXACTLY what src/shaders/sky.gdshader was
// painting at full space blend. `ground_match` does that: at 1.0 the gradient collapses to the
// ground sky's zenith tone with the ground sky's milky band, moons and sun, the nebulae are gone
// and the stars run at the ground sky's brightness and HDR cap. space_travel.gd holds it at 1.0 on
// the seam frame and eases it to 0 over a couple of seconds, so the nebulae bloom in unnoticed.
//
// THE STAR FIELD IS SHARED. The cell scales, thresholds, sizes, twinkle and galaxy normal below are
// the SAME NUMBERS as src/shaders/sky.gdshader, so a given world-space view direction produces the
// same stars in both scenes. That is what lets the cut hide: space_travel.gd rotates its whole
// solar system so the seam camera keeps the world basis it had on the planet, and the star field
// then lines up pixel for pixel. Keep the two lists in step if either is ever retuned.
//
// Mood board: the two ACNH night screenshots in reference/ — a deep navy-violet ground tone, a
// faint milky band, and thousands of CRISP pinpoint stars (never soft blobs). Nebulae are muted
// violet / teal / pink washes, not neon.
//
// The painted layers (gradient, nebula, band) are authored in display-referred colour and pushed
// through the inverse ACES curve so the tonemapper hands the palette back unchanged; the stars are
// added afterwards in HDR so glow blooms only on them.
shader_type sky;
render_mode use_debanding;

#include "res://src/shaders/aces_inverse.gdshaderinc"

// ---- gradient ---------------------------------------------------------------------------------
uniform vec3 zenith_color : source_color = vec3(0.055, 0.062, 0.152);
uniform vec3 mid_color : source_color = vec3(0.101, 0.107, 0.248);
uniform vec3 nadir_color : source_color = vec3(0.078, 0.064, 0.156);

// ---- nebulae ----------------------------------------------------------------------------------
uniform vec3 nebula_violet : source_color = vec3(0.36, 0.24, 0.60);
uniform vec3 nebula_teal : source_color = vec3(0.16, 0.42, 0.48);
uniform vec3 nebula_pink : source_color = vec3(0.52, 0.26, 0.40);
uniform float nebula_strength : hint_range(0.0, 1.0) = 0.80;

// ---- milky way --------------------------------------------------------------------------------
uniform vec3 band_color : source_color = vec3(0.34, 0.33, 0.56);
uniform float band_strength : hint_range(0.0, 1.0) = 0.44;

// ---- stars ------------------------------------------------------------------------------------
uniform float star_brightness : hint_range(0.0, 6.0) = 2.4;
uniform float star_density : hint_range(0.0, 1.0) = 1.0;
uniform float twinkle_speed = 1.0;

uniform float tonemap_white = 6.0;
uniform float display_cap : hint_range(0.1, 1.0) = 0.62;

// ---- Compatibility (WebGL2) dark-end parity ---------------------------------------------------
// SAME DEFECT AS src/shaders/sky.gdshader:299 AND src/ui/title/title_sky.gdshader. Everything
// painted above is authored display-referred and pushed back through the inverse ACES curve so the
// tonemapper hands the palette out unchanged. That round trip does NOT close under the
// Compatibility (WebGL2) renderer, which the web export is forced onto. This sky is dark enough
// that the residual does not merely dim it: it clips red and green to zero outright across the
// whole dome, leaving a blue-only near-black.
//
// The user has NOT reported this one. They reported the start screen four times ("the sky is black
// instead of navy like on the computer" and three restatements) and it was fixed in
// title_sky.gdshader; this sky is the solar-system map you fly through, and they have been getting
// stuck before flying far. It is the same bug and it is measured here so it does not become the
// fifth report.
//
// Measured on showcase/space_map.tscn at 1280x720, median RGB of four clean sky crops that avoid
// the sun bloom, the planets and the info card - TL x 0-120 y 0-160, TR x 1160-1280 y 0-160,
// L x 0-60 y 180-520, BL x 0-120 y 560-700:
//
//                          TL              TR              L               BL
//   Forward+  shipped  (23,24,65) L27.11 (20,21,61) L23.75 (19,19,56) L21.61 (15,13,44) L15.87
//   Compat    shipped  ( 0, 0,29) L 2.09 ( 0, 0,25) L 1.80 ( 0, 0,20) L 1.44 ( 0, 0,10) L 0.72
//   Compat    0.10     (13,17,55) L18.75 (12,14,52) L16.53 (11,13,45) L14.60 (10, 8,32) L10.16
//   Compat    0.12     (18,21,62) L23.32 (16,19,57) L21.11 (16,17,51) L18.96 (14,12,38) L14.59
//   Compat    0.13 *   (20,23,65) L25.11 (18,21,60) L23.68 (17,19,54) L20.81 (16,14,41) L16.37
//   Compat    0.14     (22,25,68) L27.82 (21,23,64) L25.46 (20,21,57) L23.60 (18,17,44) L18.88
//   Compat    0.18     (33,35,83) L38.11 (31,34,78) L36.33 (30,31,70) L33.60 (27,25,55) L27.88
//
// 0.13 is shipped. Mean absolute luma error against the Forward+ reference over the four crops is
// 0.84 for 0.13 against 1.86 for 0.14: 0.14 fits the bright top of the dome slightly better but
// overshoots the dark bottom by 3 luma, and overshooting is the worse failure here - it fogs the
// dome and eats the contrast the pinpoint stars need. Two consecutive captures of identical code
// moved these medians by at most 1/255, well inside the reading, so the ranking is real and not
// the capture noise of docs/OPEN_ISSUES.md 37.
//
// 0.13 HERE, 0.12 IN title_sky.gdshader, 0.08 IN sky.gdshader. THESE ARE NOT MEANT TO AGREE AND
// THE NUMBER MUST NEVER BE COPIED BETWEEN THEM. The lift is added to the authored display colour
// before a steep curve, so where it lands depends entirely on what that colour already was, and
// the three skies are authored at three different darknesses. The title's 0.12 was tried here and
// measures (18,21,62) at TL - visibly short of the (23,24,65) reference. Each sky is fitted to its
// own palette by rendering it, both ways, and reading the pixels.
//
// It is a neutral ADD and must never become a multiply. The multiply was tried on the ground sky
// and rejected: the dark sky is blue-dominant, so scaling grows blue fastest, and at the strength
// needed to rescue the darks the dome went vivid royal blue - the Earth-like daytime sky
// STYLE_GUIDE R2.1 bans. A neutral add raises the black end toward navy and leaves the hue alone.
//
// THE SEAM. `gcol` below - this shader's impersonation of the ground sky at ground_match 1 - is
// deliberately left unlifted in this change. src/shaders/sky.gdshader applies its own 0.08 there,
// so under Compatibility this shader's ground-match tone is already slightly darker than the real
// ground sky it is impersonating. That mismatch predates this change and is untouched by it: at
// ground_match 1 the lift is mixed out entirely, so the seam frame renders exactly as it did
// before. Fixing it means tracking sky.gdshader's constant from here, and it could not be measured
// in this round because reproducing the seam frame needs a real journey, not the static showcase.
// Left as a follow-up rather than shipped on reasoning alone.
//
//
// THE pc_in/pc_out MECHANISM WAS TRIED HERE AND MEASURED WORSE. DO NOT RE-TRY IT WITHOUT NEW DATA.
// src/shaders/sky.gdshader now fixes the in-game sky properly (Compatibility does not sRGB-decode
// `source_color` uniforms at upload and DOES sRGB-decode the COLOR write; pc_in on the tints plus
// pc_out on the write took its dome from GAP 13.6-26.2 to 1.2-3.7 codes on all seven worlds). The
// same conversion applied here — pc_in on zenith/mid/nadir, the three nebula tints, band_color and
// every g_* ground-sky tint, pc_out on the write, lift deleted — did NOT beat the lift. Measured on
// showcase/space_map.tscn at 1280x720 (median RGB, then luma, then whole-crop MAE):
//
//   crop                  Forward+ ref      lift 0.13 (shipped)       pc_in + pc_out
//   top strip y0-90       (23,24,64) 26.04  (19,22,63) 24.32  -1.72   (17,19,63) 21.68  -4.36
//   left col x0-120       (23,23,62) 26.09  (20,21,60) 23.67  -2.43   (20,20,62) 22.96  -3.13
//   bottom strip y640-720 (16,13,40) 14.95  (16,14,38) 16.02  +1.07   (10, 7,38)  9.95  -5.00
//   MAE, same three crops                   2.76 / 3.55 / 2.61        3.13 / 3.16 / 3.81
//
// MAE is a wash and luma is clearly worse, for the same reason as src/ui/title/title_sky.gdshader:
// Compatibility renders a few codes short of Forward+ at the very bottom of the range whatever the
// shader writes (probed with flat constants through pc_out: 0.008 -> F+ 2 vs C 0, 0.016 -> 13 vs 9,
// 0.035 -> 36 vs 34), and this sky is authored down in that band. The in-game sky escapes it only
// because it sits higher (COLOR ~0.035 by day, brighter still at night).
//
// The lift stays. To retire it you must first remove the dark-end residual, which is a renderer
// effect and not reachable from this file.
// astro_compat is 1.0 only under Compatibility; src/autoload/platform.gd:78-81 drives it and
// project.godot [shader_globals] declares it. On desktop and the native mobile renderer this whole
// term is a literal zero, so the Forward+ reference look is bit-identical to before.
//
// NOT applied in the AT_CUBEMAP_PASS branch: that pass only feeds radiance and reflections.
//
// TO RE-MEASURE: invoke godot directly, never tools/snap.sh, which appends flags after the `--`
// separator where --rendering-method is silently ignored and hands you a Forward+ render:
//   godot --path . res://showcase/space_map.tscn --rendering-method gl_compatibility \
//         -- "--director=<timeline.json>" "--capture-dir=<dir>"
// and confirm "[Platform] renderer: Compatibility (parity correction ON)" before believing any
// pixel. Note showcase/space_map.tscn builds the fallback Environment in space_travel.gd:375
// (no RocketJourney.env), so an in-flight capture, which inherits the departure planet's
// Environment, may sit a little off these absolute numbers.
global uniform float astro_compat;
uniform float compat_sky_lift : hint_range(0.0, 0.4) = 0.13;

// ---- ground-sky impersonation (the seam) ------------------------------------------------------
// 0 = this scene's own look. 1 = exactly what src/shaders/sky.gdshader paints at space_blend 1.
uniform float ground_match : hint_range(0.0, 1.0) = 0.0;
uniform vec3 g_zenith : source_color = vec3(0.039, 0.059, 0.180);
uniform vec3 g_milky : source_color = vec3(0.34, 0.33, 0.56);
uniform float g_star_brightness : hint_range(0.0, 6.0) = 2.0;
uniform float g_display_cap : hint_range(0.1, 1.0) = 0.82;
uniform vec3 g_sky_up = vec3(0.0, 1.0, 0.0);
uniform vec3 g_sky_east = vec3(1.0, 0.0, 0.0);
uniform vec3 g_sun_dir = vec3(0.0, 1.0, 0.0);
uniform vec3 g_sun_color : source_color = vec3(1.0, 0.96, 0.85);
uniform float g_sun_disc : hint_range(0.005, 0.2) = 0.026;
/// 0 hides the ground sun disc entirely (used when the far side's sun is out of frame anyway).
uniform float g_sun_vis : hint_range(0.0, 1.0) = 0.0;
uniform vec3 g_moon_a = vec3(0.0, 0.6, -0.8);
uniform vec3 g_moon_b = vec3(0.5, 0.5, -0.7);
uniform vec3 g_moon_color : source_color = vec3(1.0, 0.96, 0.82);
uniform vec3 g_moon_b_color : source_color = vec3(0.85, 0.9, 1.0);
uniform float g_moon_size : hint_range(0.01, 0.2) = 0.055;
uniform int g_moon_count = 0;
uniform float g_night : hint_range(0.0, 1.0) = 1.0;

// Same normal as src/shaders/sky.gdshader, so the milky band sits in the same place in both skies.
const vec3 GALAXY_N = vec3(0.30, 0.75, 0.55);
// Stars are clamped just under Environment.glow_hdr_threshold so they stay crisp pinpoints instead
// of being smeared into 3-4 px blobs by the bloom pass (same cap the ground sky uses).
const float STAR_HDR_CAP = 0.92;

// ---------------------------------------------------------------------------------- hashing
float hash13(vec3 p3) {
	p3 = fract(p3 * 0.1031);
	p3 += dot(p3, p3.zyx + 31.32);
	return fract((p3.x + p3.y) * p3.z);
}

vec3 hash33(vec3 p3) {
	p3 = fract(p3 * vec3(0.1031, 0.1030, 0.0973));
	p3 += dot(p3, p3.yxz + 33.33);
	return fract((p3.xxy + p3.yxx) * p3.zyx);
}

float vnoise3(vec3 p) {
	vec3 i = floor(p);
	vec3 f = p - i;
	f = f * f * (3.0 - 2.0 * f);
	float n000 = hash13(i);
	float n100 = hash13(i + vec3(1.0, 0.0, 0.0));
	float n010 = hash13(i + vec3(0.0, 1.0, 0.0));
	float n110 = hash13(i + vec3(1.0, 1.0, 0.0));
	float n001 = hash13(i + vec3(0.0, 0.0, 1.0));
	float n101 = hash13(i + vec3(1.0, 0.0, 1.0));
	float n011 = hash13(i + vec3(0.0, 1.0, 1.0));
	float n111 = hash13(i + vec3(1.0, 1.0, 1.0));
	return mix(mix(mix(n000, n100, f.x), mix(n010, n110, f.x), f.y),
			   mix(mix(n001, n101, f.x), mix(n011, n111, f.x), f.y), f.z);
}

float fbm3(vec3 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 3; i++) {
		v += a * vnoise3(p);
		p = p * 2.07 + vec3(13.1, 7.7, 3.3);
		a *= 0.5;
	}
	return v;
}

// ---------------------------------------------------------------------------------- stars
// One cell grid = one star layer. Stars live inside their cell so a single lookup is exact, which
// keeps the points razor sharp (smoothstep straight to zero, no soft falloff halo).
vec3 star_layer(vec3 d, float scale, float thresh, float size_max, float bright, float t) {
	vec3 p = d * scale;
	vec3 cell = floor(p);
	float sp = hash13(cell + 5.71);
	if (sp < thresh) {
		return vec3(0.0);
	}
	vec3 h = hash33(cell);
	vec3 pos = 0.28 + 0.44 * h;
	float dist = length(p - cell - pos);
	float b = (sp - thresh) / max(1.0 - thresh, 0.001);
	float size = mix(size_max * 0.35, size_max, b * b);
	float s = smoothstep(size, 0.0, dist);
	s *= s;
	float tw = 0.66 + 0.34 * sin(t * (1.1 + 2.4 * h.x) * twinkle_speed + h.y * 6.2831853);
	vec3 tint = mix(vec3(0.80, 0.88, 1.0), vec3(1.0, 0.90, 0.76), h.z);
	vec3 acc = tint * s * bright * (0.35 + 0.9 * b) * tw;
	// The brightest few get a small cross flare, like the reference night sky.
	if (b > 0.86) {
		vec3 q = abs(p - cell - pos);
		float flare = exp(-q.x * 30.0) * exp(-(q.y + q.z) * 9.0) + exp(-q.y * 30.0) * exp(-(q.x + q.z) * 9.0);
		acc += tint * flare * 0.45 * bright * tw;
	}
	return acc;
}

// ---------------------------------------------------------------------------------- moons
// Same construction as src/shaders/sky.gdshader: a lit disc with a phase bite, a faint earthshine
// night side so it never punches a hole in the star field, and a tight halo.
vec3 draw_moon(vec3 d, vec3 m, float r, vec3 col, float phase_offset, float vis) {
	float c = dot(d, m);
	float ang = acos(clamp(c, -1.0, 1.0));
	float disc = 1.0 - smoothstep(r * 0.88, r, ang);
	vec3 side = cross(m, g_sky_up);
	if (dot(side, side) < 0.0001) {
		side = g_sky_east;
	}
	side = normalize(side);
	vec3 m2 = normalize(m + side * r * phase_offset);
	float ang2 = acos(clamp(dot(d, m2), -1.0, 1.0));
	float cut = 1.0 - smoothstep(r * 0.92, r * 1.04, ang2);
	float shape = clamp(disc - cut, 0.0, 1.0) + disc * cut * 0.10;
	float halo = pow(max(c, 0.0), 700.0) * 0.45 + pow(max(c, 0.0), 120.0) * 0.10;
	return (shape * col * 2.4 + halo * col * 0.7) * vis;
}

void sky() {
	vec3 d = normalize(EYEDIR);
	float el = d.y;

	// ---- base gradient: navy overhead, a touch warmer violet low down -------------------------
	vec3 col = mix(mid_color, zenith_color, smoothstep(0.0, 0.85, el));
	col = mix(col, nadir_color, smoothstep(0.0, 0.75, -el));

	if (AT_CUBEMAP_PASS) {
		// Cheap radiance for ambient / reflections: gradient only.
		COLOR = mix(col, g_zenith, ground_match);
	} else {
		vec3 gn = normalize(GALAXY_N);
		float gd = dot(d, gn);
		float band = exp(-gd * gd * 13.0);
		float wisp = fbm3(d * 4.0 + 2.0);
		col += band_color * band * band_strength * (0.35 + 0.65 * wisp) * 0.34;

		// ---- three muted nebula clouds -------------------------------------------------------
		float f = fbm3(d * 2.35 + 17.0);
		float g = fbm3(d * 5.60 + 41.0);
		float cloud = smoothstep(0.40, 0.86, f * 0.72 + g * 0.28);
		float cloud2 = smoothstep(0.46, 0.90, f * 0.45 + g * 0.55);
		float ma = smoothstep(0.42, 0.98, dot(d, normalize(vec3(-0.62, 0.28, 0.73))));
		float mb = smoothstep(0.50, 0.99, dot(d, normalize(vec3(0.78, -0.16, 0.60))));
		float mc = smoothstep(0.55, 1.00, dot(d, normalize(vec3(0.08, 0.72, -0.69))));
		col += nebula_violet * ma * cloud * nebula_strength * 0.30;
		col += nebula_teal * mb * cloud2 * nebula_strength * 0.22;
		col += nebula_pink * mc * cloud * nebula_strength * 0.16;

		// ---- the ground sky, for the seam ----------------------------------------------------
		// At full space blend src/shaders/sky.gdshader collapses to a flat zenith tone plus the
		// milky band; the haze, wisps and sun scatter are all multiplied out by (1 - space_blend).
		float mw_band_g = exp(-gd * gd * 14.0);
		float mwn = fbm3(d * 4.2 + 3.0);
		vec3 gcol = g_zenith + g_milky * mw_band_g * (0.30 + 0.70 * mwn) * 0.20;

		// The lift goes in BEFORE the inverse curve so it moves the authored colour rather than
		// scaling the result; the curve is steep down here, so the darks recover while the stars,
		// the moons and the sun disc - all added afterwards, in HDR - are untouched. Deliberately
		// NOT applied to `gcol` below; see the seam note in the uniform's comment block.
		col = aces_inverse(cap_display(col + vec3(compat_sky_lift * astro_compat), display_cap),
				tonemap_white);
		if (ground_match > 0.001) {
			gcol = aces_inverse(cap_display(gcol, g_display_cap), tonemap_white);
			col = mix(col, gcol, ground_match);
		}

		// ---- stars in HDR so only they bloom -------------------------------------------------
		// Cell scales, thresholds and sizes are src/shaders/sky.gdshader's, so the same view
		// direction gives the same stars in both scenes - the whole point of the seam.
		float t = TIME;
		float dense = mix(0.955, 0.872, star_density);
		vec3 stars = star_layer(d, 54.0, dense, 0.120, 1.00, t);
		stars += star_layer(d, 98.0, dense + 0.030, 0.088, 0.70, t + 3.1);
		stars += star_layer(d, 176.0, dense + 0.052, 0.072, 0.44, t + 6.4);
		// The band is dusted with extra faint stars, like the reference.
		stars += star_layer(d, 254.0, 0.966 - 0.03 * mw_band_g, 0.056, 0.28, t + 9.2);
		// The ground sky clamps each channel; this one does not. Cross-fade the two treatments so
		// the star POSITIONS never move - only their brightness relaxes after the cut.
		col += mix(stars * star_brightness, min(stars * g_star_brightness, vec3(STAR_HDR_CAP)),
				ground_match);

		if (ground_match > 0.001) {
			// ---- the ground sky's moons and sun ----------------------------------------------
			float moon_vis = mix(0.55, 1.0, g_night) * ground_match;
			col += draw_moon(d, g_moon_a, g_moon_size, g_moon_color, 0.62, moon_vis);
			if (g_moon_count > 1) {
				col += draw_moon(d, g_moon_b, g_moon_size * 0.55, g_moon_b_color, 1.35, moon_vis);
			}
			float sc = dot(d, g_sun_dir);
			float ang = acos(clamp(sc, -1.0, 1.0));
			float disc = 1.0 - smoothstep(g_sun_disc * 0.82, g_sun_disc, ang);
			float halo = pow(max(sc, 0.0), 620.0) * 0.75 + pow(max(sc, 0.0), 90.0) * 0.16;
			col += (disc * 3.4 + halo) * g_sun_color * g_sun_vis * ground_match;
		}

		COLOR = col;
	}
}
