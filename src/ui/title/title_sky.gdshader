// TITLE SCREEN SKY — thin-atmosphere deep space (docs/STYLE_GUIDE.md R2.1).
//
// This used to be the last place in the game where the pre-R2.1 look survived: a bright royal-blue
// dome with a big violet/blue nebula wash, which is exactly the "earth-like blue sky" the user threw
// out. The title is the FIRST thing anyone sees, so it now speaks the same language as the two
// shipping space skies:
//   * gradient, milky band and nebula are authored in display-referred colour and pushed through the
//     inverse ACES curve, so the tonemapper hands the palette back unchanged;
//   * the star field uses the SAME cell grammar, scales, thresholds, sizes, twinkle and galaxy
//     normal as src/shaders/sky.gdshader and src/rocket/space_sky.gdshader — one cell lookup per
//     layer, smoothstep straight to zero — so the stars are crisp pinpoints, never soft blobs, and
//     the title reads as the same universe you are about to fly around in;
//   * stars are clamped just under Environment.glow_hdr_threshold so the bloom pass cannot smear
//     them into 3-4 px balls.
// The nebula survives only as a very faint, desaturated violet/teal wash — enough that the sky is
// not dead flat behind the logo, far too dim to read as a colour field.
shader_type sky;
render_mode use_debanding;

#include "res://src/shaders/aces_inverse.gdshaderinc"

// ---- gradient (near-black at the zenith, a hair warmer low down) -------------------------------
uniform vec3 zenith_color : source_color = vec3(0.031, 0.043, 0.121);
uniform vec3 mid_color : source_color = vec3(0.055, 0.062, 0.152);
uniform vec3 nadir_color : source_color = vec3(0.070, 0.058, 0.140);

// ---- nebulae (muted; a wash, not a colour field) -----------------------------------------------
uniform vec3 nebula_violet : source_color = vec3(0.36, 0.24, 0.60);
uniform vec3 nebula_teal : source_color = vec3(0.16, 0.42, 0.48);
uniform float nebula_strength : hint_range(0.0, 1.0) = 0.30;

// ---- milky way ---------------------------------------------------------------------------------
uniform vec3 band_color : source_color = vec3(0.34, 0.33, 0.56);
uniform float band_strength : hint_range(0.0, 1.0) = 0.40;

// ---- stars -------------------------------------------------------------------------------------
uniform float star_brightness : hint_range(0.0, 6.0) = 2.3;
uniform float star_density : hint_range(0.0, 1.0) = 1.0;

// ---- display-referred output --------------------------------------------------------------------
uniform float tonemap_white = 6.0;
uniform float display_cap : hint_range(0.1, 1.0) = 0.62;

// Same normal as the two shipping skies, so the band sits in the same place everywhere.
const vec3 GALAXY_N = vec3(0.30, 0.75, 0.55);
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
// One cell grid = one star layer, star inside its own cell so a single lookup is exact.
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
	float tw = 0.66 + 0.34 * sin(t * (1.1 + 2.4 * h.x) + h.y * 6.2831853);
	vec3 tint = mix(vec3(0.80, 0.88, 1.0), vec3(1.0, 0.90, 0.76), h.z);
	vec3 acc = tint * s * bright * (0.35 + 0.9 * b) * tw;
	if (b > 0.86) {
		vec3 q = abs(p - cell - pos);
		float flare = exp(-q.x * 30.0) * exp(-(q.y + q.z) * 9.0) + exp(-q.y * 30.0) * exp(-(q.x + q.z) * 9.0);
		acc += tint * flare * 0.45 * bright * tw;
	}
	return acc;
}

void sky() {
	vec3 d = normalize(EYEDIR);
	float el = d.y;

	// ---- base gradient -------------------------------------------------------------------
	vec3 col = mix(mid_color, zenith_color, smoothstep(0.0, 0.85, el));
	col = mix(col, nadir_color, smoothstep(0.0, 0.75, -el));

	if (AT_CUBEMAP_PASS) {
		// Cheap radiance for ambient light / reflections: gradient only.
		COLOR = col;
	} else {
		// ---- milky band ------------------------------------------------------------------
		vec3 gn = normalize(GALAXY_N);
		float gd = dot(d, gn);
		float band = exp(-gd * gd * 13.0);
		float wisp = fbm3(d * 4.0 + 2.0);
		col += band_color * band * band_strength * (0.35 + 0.65 * wisp) * 0.30;

		// ---- two very faint nebula washes -------------------------------------------------
		float f = fbm3(d * 2.35 + 17.0);
		float g = fbm3(d * 5.60 + 41.0);
		float cloud = smoothstep(0.42, 0.88, f * 0.72 + g * 0.28);
		float ma = smoothstep(0.44, 0.98, dot(d, normalize(vec3(-0.62, 0.28, 0.73))));
		float mb = smoothstep(0.52, 0.99, dot(d, normalize(vec3(0.78, -0.16, 0.60))));
		col += nebula_violet * ma * cloud * nebula_strength * 0.26;
		col += nebula_teal * mb * cloud * nebula_strength * 0.16;

		// ---- to HDR, then the stars on top ------------------------------------------------
		col = aces_inverse(cap_display(col, display_cap), tonemap_white);
		float t = TIME;
		float dense = mix(0.955, 0.872, star_density);
		vec3 stars = star_layer(d, 54.0, dense, 0.120, 1.00, t);
		stars += star_layer(d, 98.0, dense + 0.030, 0.088, 0.70, t + 3.1);
		stars += star_layer(d, 176.0, dense + 0.052, 0.072, 0.44, t + 6.4);
		stars += star_layer(d, 254.0, 0.966 - 0.03 * band, 0.056, 0.28, t + 9.2);
		col += min(stars * star_brightness, vec3(STAR_HDR_CAP));
	}

	COLOR = col;
}
