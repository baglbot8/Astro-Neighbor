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

		col = aces_inverse(cap_display(col, display_cap), tonemap_white);
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
