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

// ---- Compatibility (WebGL2) dark-end parity -----------------------------------------------------
// THE BUG THIS FIXES. Reported from a real iPhone four separate times: "the sky is black instead
// of navy like on the computer", "sky still looks black on the start page", "the background at the
// start still looks very black", "The homescreen is still black in space instead of blue." All four
// previous attempts were made in src/shaders/sky.gdshader, which is the IN-GAME sky. The start
// screen is a different scene with a different Environment and THIS shader, which is exactly why
// four fixes in a row changed nothing the user could see.
//
// Same defect as src/shaders/sky.gdshader:299. Everything painted above is authored
// display-referred and pushed back through the inverse ACES curve so the tonemapper hands the
// palette out unchanged. That round trip does NOT close under the Compatibility (WebGL2) renderer,
// which the web export is forced onto. Because this sky is authored so close to black at the
// zenith, the residual does not merely darken it - it clips the red and green channels to zero
// outright, which is why the user's word for it is "black" and not "too dark".
//
// Measured on showcase/ui_title.tscn at 1280x720, median RGB of the left sky crop x 0-80, y 0-500
// (clean dome: the buttons start below y 520 and the planet is off to the right):
//
//   Forward+  as shipped            (10, 12, 36)  luma p50 13.09   <- the reference, correct navy
//   Compat    as shipped            ( 0,  0,  7)  luma p50  0.51   <- literally zero R and G
//   Compat    lift 0.08             ( 3,  5, 23)  luma p50  5.59   <- still reads black
//   Compat    lift 0.10             ( 7,  8, 27)  luma p50  9.23
//   Compat    lift 0.12  SHIPPED    (10, 12, 32)  luma p50 13.23   <- lands on the reference
//   Compat    lift 0.14             (14, 16, 37)  luma p50 17.30   <- overshoots
//
// A blue-biased variant, vec3(0.12, 0.12, 0.139), was measured too and hits blue exactly:
// (10, 12, 37) luma 13.38. It is deliberately NOT shipped. Neutral 0.12 matches red, green and
// luma to within 0.14 of the reference and leaves blue 4/255 short, which is the safer art call:
// a per-channel blue bias is the first step back toward the Earth-like blue dome R2.1 bans, and
// 4/255 of blue in the darkest part of the frame is invisible next to that risk.
//
// It is a neutral ADD and must never become a multiply. The multiply was tried on the ground sky
// and rejected: the dark sky is blue-dominant, so scaling grows blue fastest, and at the strength
// needed to rescue the darks the dome went vivid royal blue - the Earth-like daytime sky
// STYLE_GUIDE R2.1 bans. This is a thin-atmosphere space look. A neutral add raises the black end
// toward navy and leaves the hue balance alone.
//
// 0.12 HERE vs 0.08 IN sky.gdshader IS NOT AN INCONSISTENCY, AND THE NUMBER DOES NOT TRANSFER.
// The lift is added to the authored display colour before a steep curve, so where it lands depends
// entirely on what that colour already was. This sky is authored much darker (zenith
// 0.031, 0.043, 0.121) than the ground sky, and 0.08 measures (3, 5, 23) here - still black. Every
// sky fits its own lift to its own palette. Do not copy this constant anywhere.
//
// HOW TO RE-MEASURE (this cost an hour). You CANNOT capture the start screen from the main scene:
// title_screen.gd:56 auto-starts the game whenever Director.is_active(), so a director timeline
// aimed at res://src/ui/title/title_screen.tscn silently hands you an in-game world capture, and
// edits to this file then appear to do nothing at all. Use showcase/ui_title.tscn, which sets
// demo_mode = true and keeps the title up. Invoke godot directly rather than through tools/snap.sh,
// which appends flags after the `--` separator where --rendering-method is ignored:
//   godot --path . res://showcase/ui_title.tscn --rendering-method gl_compatibility \
//         -- "--director=<timeline.json>" "--capture-dir=<dir>"
// and confirm "[Platform] renderer: Compatibility (parity correction ON)" in the output before
// believing any pixel. Two consecutive captures of identical code were byte-identical on this
// crop, so the numbers above are not the capture noise of docs/OPEN_ISSUES.md 37.
//
//
// THE pc_in/pc_out MECHANISM WAS TRIED HERE AND MEASURED WORSE. DO NOT RE-TRY IT WITHOUT NEW DATA.
// src/shaders/sky.gdshader now fixes the in-game sky properly: Compatibility does not sRGB-decode
// `source_color` uniforms at upload and DOES sRGB-decode the COLOR write, so pc_in() on the tints
// plus pc_out() on the write closes it. That took the in-game dome from GAP 13.6-26.2 to 1.2-3.7
// codes across all seven worlds, day and night. Applied to THIS shader — pc_in on zenith_color,
// mid_color, nadir_color, nebula_violet, nebula_teal, band_color, pc_out on the write, lift deleted —
// it did NOT beat the lift, measured on showcase/ui_title.tscn at 1280x720 with glow forced off in
// BOTH renderers so the comparison is like for like (median RGB, then luma):
//
//   crop                       Forward+ ref     lift 0.12 (shipped)      pc_in + pc_out
//   left dome x0-80 y0-500     (10,11,36) 12.88 (10,12,32) 13.02  +0.14  ( 4, 7,34)  8.24  -4.64
//   band side x980-1280 y0-80  (21,21,50) 23.10 (13,15,39) 16.31  -6.79  (17,18,49) 19.74  -3.36
//   whole upper sky y0-420     (12,14,38) 14.60 (11,13,33) 13.73  -0.87  ( 6, 8,35)  9.52  -5.08
//   whole upper sky, MAE                        4.49                     4.57
//
// So: the mechanism wins the milky band (-3.4 instead of -6.8) and loses the dark dome (-4.6 instead
// of -0.1), and whole-crop MAE is a dead heat at 4.5. WHY: Compatibility renders a few codes short of
// Forward+ at the very bottom of the range no matter what the shader writes. Probed with flat
// constants written straight to COLOR through pc_out in THIS scene, Forward+ vs Compatibility:
// 0.004 -> 0 vs 0, 0.008 -> 2 vs 0, 0.016 -> 13 vs 9, 0.035 -> 36 vs 34. This sky is authored at
// zenith 0.031,0.043,0.121 and lands in exactly that 0.008-0.016 band, which is why the residual
// dominates here and is invisible in-game (the ground sky sits at COLOR ~0.035 by day and higher at
// night, where the same probe is within 2 codes).
//
// The dark dome is the bug the user reported four times, so the metric that matters here is the one
// the mechanism loses. The lift stays. If you want to retire it, retire the dark-end residual first
// — it is a renderer effect, not a shader one, and no constant in this file can reach it.
// astro_compat is 1.0 only under Compatibility; src/autoload/platform.gd:78-81 drives it and
// project.godot [shader_globals] declares it. On desktop and the native mobile renderer this whole
// term is a literal zero, so the reference look is untouched.
//
// Deliberately NOT applied in the AT_CUBEMAP_PASS branch below. That pass only feeds radiance, and
// the title Environment uses AMBIENT_SOURCE_COLOR with a fixed ambient (title_screen.gd:172-174),
// so lifting it would change nothing but the reflections on the rocket.
//
// KNOWN RESIDUALS, deliberately not chased. The lift raises the whole dome equally, so it slightly
// flattens the milky-band wash: measured on the band-side crop x 980-1280, y 0-80, Forward+ reads
// (22, 22, 52) and lift 0.12 reads (14, 16, 39) - still short, because the Compatibility error is
// not uniform across the dome and a single additive constant cannot track it. And the stars stay
// dimmer than desktop because glow is deliberately off under Compatibility
// (title_screen.gd:183). Neither is the reported bug; both are far better than a black sky.
global uniform float astro_compat;
uniform float compat_sky_lift : hint_range(0.0, 0.3) = 0.12;

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
		// The lift goes in BEFORE the inverse curve, so it moves the authored colour rather than
		// scaling the result. The curve is steep down here, so the darks recover while the stars —
		// added afterwards, in HDR — are untouched.
		col = aces_inverse(cap_display(col + vec3(compat_sky_lift * astro_compat), display_cap), tonemap_white);
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
