// THIN-ATMOSPHERE SKY for the tiny airless worlds of Astro Neighbor (STYLE_GUIDE R2.1).
//
// There is not enough air out here to scatter a blue dome, so the sky is deep space with a thin
// band of dusty colour hugging the planet's limb — the look of the Moon's or Mars' horizon glow.
// Stars are ALWAYS visible, dimmer by day than at night, and always crisp pinpoints.
//
// Everything that hugs the horizon is measured as `h` = the angle of a view ray ABOVE THE VISIBLE
// LIMB, not as elevation above the local horizontal. On a 16 m planet the limb sits ~24 deg below
// local horizontal, so an elevation-based band would be painted entirely off-screen. `h` is
// computed from `limb_dir` / `limb_angle`, which environment.gd derives from the real camera
// position, so the band stays glued to the ground silhouette on any planet radius and slides
// correctly outward as the rocket climbs away.
//
// Layers (back to front): gradient -> limb haze -> sun scatter -> milky band -> HDR -> stars ->
// moons -> sun disc. The painted layers are authored in display-referred colour and pushed through
// the inverse ACES curve so the tonemapper hands the palette back unchanged; stars, moons and the
// sun are added afterwards in HDR so glow blooms only on them.
//
// The star grammar (one cell lookup per layer, smoothstep straight to zero) is deliberately the
// same as src/rocket/space_sky.gdshader so the ground sky and the space-travel scene read as one
// world. Uniforms are driven per frame by src/world/environment.gd.
shader_type sky;
render_mode use_debanding;

#include "res://src/shaders/aces_inverse.gdshaderinc"
#include "res://src/shaders/planet_common.gdshaderinc"

// ---- local frame & bodies -------------------------------------------------------------------
uniform vec3 sky_up = vec3(0.0, 1.0, 0.0);
uniform vec3 sky_east = vec3(1.0, 0.0, 0.0);
/// Unit vector from the camera toward the planet centre.
uniform vec3 limb_dir = vec3(0.0, -1.0, 0.0);
/// Angular radius of the planet as seen from the camera (radians).
uniform float limb_angle : hint_range(0.0, 1.5708) = 0.9;
uniform vec3 sun_dir = vec3(0.0, 0.7071, 0.7071);
uniform vec3 moon_dir_a = vec3(0.0, 0.6, -0.8);
uniform vec3 moon_dir_b = vec3(0.5, 0.5, -0.7);
uniform int moon_count = 1;

// ---- gradient ---------------------------------------------------------------------------------
uniform vec3 zenith_color : source_color = vec3(0.039, 0.059, 0.180);
uniform vec3 mid_color : source_color = vec3(0.075, 0.090, 0.230);
uniform vec3 limb_color : source_color = vec3(0.165, 0.170, 0.310);
uniform vec3 haze_color : source_color = vec3(0.780, 0.650, 0.520);
uniform float haze_strength : hint_range(0.0, 1.0) = 0.55;
/// Angular thickness of the bright rim on the limb (radians). Thin: this is a trace atmosphere.
uniform float haze_width : hint_range(0.005, 0.6) = 0.045;
/// Angle above the limb where `mid_color` sits, and where the deep zenith is reached (radians).
/// The gameplay camera only ever sees the first ~18 deg (0.32 rad) above the limb, so these are
/// small on purpose: the frame has to run all the way from dusty rim to near-black inside that.
uniform float mid_height : hint_range(0.02, 1.0) = 0.10;
uniform float zenith_height : hint_range(0.1, 3.0) = 0.45;

// ---- sun ------------------------------------------------------------------------------------
uniform vec3 sun_color : source_color = vec3(1.0, 0.96, 0.85);
uniform vec3 sun_glow_color : source_color = vec3(1.0, 0.7, 0.45);
uniform float sun_glow : hint_range(0.0, 1.0) = 0.0;
/// Airless worlds get a hard-edged sun, not a soft bloom ball.
uniform float sun_disc_size : hint_range(0.005, 0.2) = 0.026;

// ---- high dust wisps (the ONLY thing left of the old clouds) ---------------------------------
// R2.1: "at most a few very thin, high, sparse wisps, or none at all". These are thin horizontal
// streaks living inside the limb band, so they read as suspended dust, never as puffy clouds.
uniform vec3 wisp_color : source_color = vec3(0.86, 0.80, 0.76);
uniform float wisp_amount : hint_range(0.0, 0.35) = 0.10;
uniform float wind = 0.012;

// ---- night / space ----------------------------------------------------------------------------
uniform float night : hint_range(0.0, 1.0) = 0.0;
/// 0 = standing on the surface, 1 = full space. Fades the limb haze out and stars up.
uniform float space_blend : hint_range(0.0, 1.0) = 0.0;
uniform vec3 moon_color : source_color = vec3(1.0, 0.96, 0.82);
uniform vec3 moon_b_color : source_color = vec3(0.85, 0.9, 1.0);
uniform float moon_size : hint_range(0.01, 0.2) = 0.055;
uniform float star_brightness : hint_range(0.0, 4.0) = 2.1;
/// Star brightness scale in full daylight. Never 0 — there is no air to scatter them out.
uniform float star_day : hint_range(0.0, 1.0) = 0.40;
uniform float star_density : hint_range(0.0, 1.0) = 1.0;
uniform vec3 milky_way_color : source_color = vec3(0.34, 0.33, 0.56);

// ---- display-referred output ---------------------------------------------------------------
uniform float tonemap_white = 6.0;
uniform float display_cap : hint_range(0.3, 1.0) = 0.85;
// WEB PARITY: THE SKY'S HALF OF THE COMPATIBILITY COLOUR BUG (docs/OPEN_ISSUES.md 32).
// This sky is authored in DISPLAY-REFERRED colour and pushed back through the inverse ACES curve so
// the renderer's tonemapper returns the palette unchanged. Under the Compatibility (WebGL2) renderer
// the web export is forced onto, that round trip did NOT close: the dome rendered about half as
// bright and noticeably more saturated than the desktop reference, across 35-53% of every frame.
// Reported from a real iPhone as 'the sky is black instead of navy'.
//
// IT IS THE SAME TWO-PART BUG planet_common.gdshaderinc lines 5-104 documents for spatial shaders,
// and `shader_type sky` is subject to BOTH halves. Neither part is fitted; both were measured.
//
//   (1) UNIFORMS IN. Compatibility does not sRGB-decode `source_color` uniforms at upload; Forward+
//       does. So zenith_color, mid_color, limb_color, haze_color, sun_glow_color, milky_way_color,
//       wisp_color, moon_color, moon_b_color and sun_color all arrived display-encoded, and every
//       mix() and += below composed in the wrong space. -> pc_in() each, once, at first use.
//   (2) COLOUR OUT. Compatibility sRGB-decodes whatever the shader writes to COLOR (its sky pass
//       does it before tonemapping, "so color matches scene shader better"). -> pc_out() the write.
//
// THIS COST A FULL BISECT, SO HERE IS THE TRAP. Part (2) alone LOOKS right and is catastrophically
// wrong: with pc_out on the write and the uniforms still undecoded, home's dome went from Cp50 17.0
// to 94.1 against a Forward+ reference of 31.5 — three times too bright, worse than doing nothing.
// A flat constant written to COLOR through pc_out matched Forward+ perfectly at the same time, in
// the same frame, which is what made it so confusing: constants need no pc_in, and the sky's real
// colour is nothing but uniforms. If you ever see "the probe passes but the scene fails", suspect a
// missing pc_in before you suspect the write.
//
// THE PROBE for part (2), flat constants written straight to COLOR, read off one pixel of
// showcase/planet_home.tscn at hour 13, both renderers:
//
//   COLOR      F+ rgb          C rgb (plain)     C rgb (pc_out)   maxdiff F+ vs C(pc_out)
//   0.010    ( 11,  7, 19)     (  8,  4, 16)     (  8,  4, 16)          3.0
//   0.025    ( 24, 20, 33)     (  8,  4, 16)     ( 22, 18, 31)          2.5
//   0.035    ( 32, 27, 40)     (  8,  4, 16)     ( 30, 26, 38)          2.1
//   0.070    ( 55, 51, 63)     (  8,  4, 16)     ( 55, 50, 62)          0.9
//   0.20     (138,135,142)     ( 29, 24, 37)     (139,136,143)          0.8
//   0.45     (180,176,179)     (126,122,130)     (180,176,179)          0.4
//   0.80     (197,192,193)     (190,185,187)     (197,192,193)          0.4
//   0.95     (201,197,197)     (200,195,195)     (201,197,197)          0.3
//
// RESULT, per-region, sky dome masked by repainting this shader magenta and applying that mask to
// unmodified captures, Forward+ vs Compatibility, luma p50 and mean |F-C| over p05/p50/p95:
//
//   world   npx      GAP before -> after     dSAT before -> after
//   home   427,938   15.66 -> 1.26           +0.1838 -> +0.0129
//   hub    347,253   26.19 -> 1.22           +0.2095 -> +0.0115
//   vela   481,593   22.82 -> 1.64           +0.1561 -> +0.0268
//   zorp   479,327   15.65 -> 1.26           +0.1352 -> +0.0237
//   bolt   414,097   13.67 -> 3.74           +0.1541 -> +0.0095   (see the ring note below)
//   fen    455,155   20.44 -> 1.64           +0.1503 -> +0.0231
//   grig   444,150   13.56 -> 2.07           +0.1772 -> +0.0132
//
// AT NIGHT TOO, hour 21.5, dome crop y80-330, MAE and luma p50: home 13.28 -> 2.92 and -15.87 ->
// -2.86 luma, fen 17.66 -> 3.02 and -18.08 -> -2.57, vela 14.43 -> 3.69 and -10.57 -> -3.92. The
// retired lift was a day-tuned constant and was costing the night sky the most.
//
// pc_out() and pc_in() are the identity on Forward+ (astro_compat == 0.0), so the desktop reference
// cannot move: byte-identical on home and bolt, and on the other five within the run-to-run noise
// the twinkling stars already produce between two captures of unchanged code.
//
// `compat_sky_lift = 0.08` IS RETIRED BY THIS. It was a stand-in for (2) alone and would now
// overshoot. The MULTIPLY that was tried before it stays banned: the dark sky is blue-dominant, so
// scaling grows blue fastest and at the strength needed to rescue the darks the dome went royal
// blue, the Earth-like daytime sky STYLE_GUIDE R2.1 forbids.
//
// FOUR LIMITS OF THE FIX. All four are renderer-side; none is worth a constant.
//  * Compatibility CLAMPS this write at 1.0. Measured: COLOR 1.0, 1.5 and 2.5 all render the
//    identical (202,197,197) while Forward+ climbs 202/208/214. So the sun disc (3.4x), the star
//    cores and the brightest haze clip on the phone. They clipped before this change too, and
//    pc_out cannot make it worse because pc_l2s(x) <= 1 for every x <= 1.
//  * THE 3D PASS RUNS AT HALF LINEAR RESOLUTION on Compatibility (platform.gd sets
//    scaling_3d_scale = 0.5). That is a deliberate thermal decision and it puts a floor under any
//    per-pixel score. Measured by forcing the SAME 0.5 scale on Forward+ and comparing it with
//    full-res Forward+ — one renderer, one set of shaders, resolution the only variable: dome MAE
//    1.31-1.77 / p95 4. The shipped Forward+ vs Compatibility dome is MAE 1.85-2.22 / p95 5-6 on
//    the six ringless worlds, i.e. within ~0.4 of a floor that has nothing to do with colour.
//  * BOLT AND VELA'S RING is the one dome region still visibly off, because ring.gdshader is
//    blend_mix and Forward+ blends it into a linear HDR buffer before tonemapping while
//    Compatibility blends it in sRGB display space after. Masked to bolt's ring pixels only:
//    MAE 29.15 before this round, 15.09 after ring.gdshader's own conversion, against a resolution
//    floor of 0.74. Bolt's dome MINUS the ring is 17.72 -> 2.28 against a floor of 1.54.
//  * BELOW COLOR ~0.03 about 3 codes remain and Compatibility floors on the grade LUT's black
//    point (8,4,16) — 8-bit quantisation ahead of the adjustment pass. It is small here because the
//    dome sits at COLOR ~0.035 by day and higher at night. It is NOT small in the two skies that
//    are authored darker: src/ui/title/title_sky.gdshader and src/rocket/space_sky.gdshader both
//    keep their empirical lifts because this same conversion measured WORSE on them. Their files
//    carry the tables. Do not "finish the job" by converting them without re-measuring.
global uniform float astro_compat;

const float WISP_PERIOD = 9.0;
// Stars are clamped just under Environment.glow_hdr_threshold so they stay crisp pinpoints
// instead of being smeared into 3-4 px blobs by the bloom pass.
const float STAR_HDR_CAP = 0.92;
const vec3 GALAXY_N = vec3(0.30, 0.75, 0.55);

// ---------------------------------------------------------------------------------- hashing
float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

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

// Value noise, periodic along x with period `per` cells (so the sky has no seam).
float vnoise(vec2 p, float per) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float x0 = mod(i.x, per);
	float x1 = mod(i.x + 1.0, per);
	float a = hash12(vec2(x0, i.y));
	float b = hash12(vec2(x1, i.y));
	float c = hash12(vec2(x0, i.y + 1.0));
	float d = hash12(vec2(x1, i.y + 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p, float per) {
	float v = 0.0;
	float amp = 0.5;
	for (int k = 0; k < 4; k++) {
		v += amp * vnoise(p, per);
		p = p * 2.0 + vec2(17.1, 9.7);
		per *= 2.0;
		amp *= 0.5;
	}
	return v;
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
// One cell grid = one star layer. A star lives inside its own cell so a single lookup is exact,
// which keeps the point razor sharp (smoothstep straight to zero, no soft falloff halo).
// Same construction as src/rocket/space_sky.gdshader so both skies read as the same universe.
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
	float tw = 0.66 + 0.34 * sin(t * (1.1 + 2.4 * h.x) + h.y * TAU);
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
vec3 draw_moon(vec3 d, vec3 m, float r, vec3 col, float phase_offset, float vis) {
	float c = dot(d, m);
	float ang = acos(clamp(c, -1.0, 1.0));
	float disc = 1.0 - smoothstep(r * 0.88, r, ang);
	vec3 side = cross(m, sky_up);
	if (dot(side, side) < 0.0001) {
		side = sky_east;
	}
	side = normalize(side);
	vec3 m2 = normalize(m + side * r * phase_offset);
	float ang2 = acos(clamp(dot(d, m2), -1.0, 1.0));
	float cut = 1.0 - smoothstep(r * 0.92, r * 1.04, ang2);
	// The unlit part of the disc stays faintly visible (earthshine) instead of biting a hole in
	// the star field — the same "no crushed night side" rule the sky planets follow.
	float shape = clamp(disc - cut, 0.0, 1.0) + disc * cut * 0.10;
	float halo = pow(max(c, 0.0), 700.0) * 0.45 + pow(max(c, 0.0), 120.0) * 0.10;
	return (shape * col * 2.4 + halo * col * 0.7) * vis;
}

/// Angle of `dir` above the visible limb of the planet, in radians (0 exactly on the silhouette).
float limb_height(vec3 dir) {
	return acos(clamp(dot(dir, limb_dir), -1.0, 1.0)) - limb_angle;
}

// ---------------------------------------------------------------------------------- sky
void sky() {
	vec3 d = normalize(EYEDIR);
	vec3 north = normalize(cross(sky_up, sky_east));
	float el = clamp(dot(d, sky_up), -1.0, 1.0);
	float az = atan(dot(d, north), dot(d, sky_east));
	// Angle above the visible ground silhouette — every horizon effect is anchored to this.
	float h = limb_height(d);
	float hp = max(h, 0.0);

	// ---- gradient: deep space, warming only in the last few degrees above the limb -----------
	// In space (space_blend -> 1) the whole dome collapses to the deep zenith tone, which is the
	// same navy the solar-system map uses.
	vec3 c_zenith = pc_in(zenith_color);
	vec3 c_sun_glow = pc_in(sun_glow_color);
	vec3 c_limb = mix(pc_in(limb_color), c_zenith, space_blend);
	vec3 c_mid = mix(pc_in(mid_color), c_zenith, space_blend * 0.9);
	float t_low = clamp(hp / mid_height, 0.0, 1.0);
	float t_high = clamp((hp - mid_height) / max(zenith_height - mid_height, 0.01), 0.0, 1.0);
	vec3 col = mix(c_limb, c_mid, t_low * t_low * (3.0 - 2.0 * t_low));
	col = mix(col, c_zenith, t_high * t_high * (3.0 - 2.0 * t_high));

	// ---- the thin limb band ------------------------------------------------------------------
	// Two falloffs: a tight bright rim right on the silhouette plus a much wider, fainter skirt,
	// so the band has a soft top edge instead of a hard ring.
	float above_ground = smoothstep(-0.02, 0.004, h);   // 0 below the silhouette, 1 above it
	float rim = exp(-hp / haze_width);
	float skirt = exp(-hp / (haze_width * 2.8)) * 0.26;
	float haze = clamp((rim + skirt) * haze_strength * (1.0 - space_blend), 0.0, 1.0);
	col = mix(col, pc_in(haze_color), haze);

	// ---- sunrise / sunset: the band burns warm on the sun's side ------------------------------
	float sc = dot(d, sun_dir);
	float sun_h = limb_height(sun_dir);
	float sun_vis = smoothstep(-0.16, -0.03, sun_h);
	float glow = pow(max(sc, 0.0), 3.0) * exp(-hp / (haze_width * 4.5)) * sun_glow * (1.0 - space_blend);
	col = mix(col, c_sun_glow, clamp(glow, 0.0, 1.0));
	col += pow(max(sc, 0.0), 2.5) * sun_glow * c_sun_glow * 0.10 * (1.0 - space_blend);

	if (AT_CUBEMAP_PASS) {
		// Cheap radiance for ambient light / reflections: gradient + limb band only.
		COLOR = col;
	} else {
		// ---- painterly brush variation --------------------------------------------------
		float paint = fbm(vec2(az / TAU * 6.0, hp * 2.4 + 3.0), 6.0) - 0.5;
		col *= 1.0 + paint * 0.05;

		// ---- the milky band (faint by day, strong at night and in space) ------------------
		vec3 gn = normalize(GALAXY_N);
		float gd = dot(d, gn);
		float mw_band = exp(-gd * gd * 14.0);
		float mwn = fbm3(d * 4.2 + 3.0);
		float mw_vis = max(max(night, space_blend), 0.13) * (1.0 - haze * 0.9);
		col += pc_in(milky_way_color) * mw_band * (0.30 + 0.70 * mwn) * 0.20 * mw_vis;

		// ---- thin high dust wisps inside the band ----------------------------------------
		float cov = 0.0;
		if (wisp_amount > 0.002) {
			// Only in the first ~10 deg above the limb, and squashed hard in elevation so the
			// streaks are horizontal filaments rather than blobs.
			float band = exp(-hp / 0.10) * smoothstep(-0.005, 0.02, h);
			vec2 cuv = vec2(az / TAU * WISP_PERIOD + TIME * wind, hp * 22.0);
			float n = fbm(cuv, WISP_PERIOD);
			cov = smoothstep(0.60, 0.80, n) * band * wisp_amount * (1.0 - space_blend);
			col = mix(col, pc_in(wisp_color), cov);
		}

		// ---- to HDR ----------------------------------------------------------------------
		col = aces_inverse(cap_display(col, display_cap), tonemap_white);

		// ---- stars: always present, dimmer by day ---------------------------------------
		// Suppressed inside the bright limb band (the only place there is enough dust to
		// scatter them out) and hidden below the ground silhouette.
		float star_vis = mix(mix(star_day, 1.0, night), 1.0, space_blend);
		star_vis *= (1.0 - clamp(haze * 1.15, 0.0, 1.0)) * (1.0 - cov) * above_ground;
		if (star_vis > 0.002) {
			float t = TIME;
			float dense = mix(0.955, 0.872, star_density);
			vec3 stars = star_layer(d, 54.0, dense, 0.120, 1.00, t);
			stars += star_layer(d, 98.0, dense + 0.030, 0.088, 0.70, t + 3.1);
			stars += star_layer(d, 176.0, dense + 0.052, 0.072, 0.44, t + 6.4);
			stars += star_layer(d, 254.0, 0.966 - 0.03 * mw_band, 0.056, 0.28, t + 9.2);
			col += min(stars * star_brightness * star_vis, vec3(STAR_HDR_CAP));
		}

		// ---- moons (visible by day too — there is no blue haze to hide them) --------------
		float moon_vis = mix(0.55, 1.0, night) * (1.0 - cov * 0.6) * (1.0 - haze * 0.55);
		float vis_a = moon_vis * smoothstep(-0.14, -0.01, limb_height(moon_dir_a));
		col += draw_moon(d, moon_dir_a, moon_size, pc_in(moon_color), 0.62, vis_a);
		if (moon_count > 1) {
			float vis_b = moon_vis * smoothstep(-0.14, -0.01, limb_height(moon_dir_b));
			col += draw_moon(d, moon_dir_b, moon_size * 0.55, pc_in(moon_b_color), 1.35, vis_b);
		}

		// ---- sun disc + a tight halo (no air, so no big glare ball) ----------------------
		float ang = acos(clamp(sc, -1.0, 1.0));
		float disc = 1.0 - smoothstep(sun_disc_size * 0.82, sun_disc_size, ang);
		float halo = pow(max(sc, 0.0), 620.0) * 0.75 + pow(max(sc, 0.0), 90.0) * 0.16;
		col += (disc * 3.4 + halo * (1.0 - cov * 0.6)) * pc_in(sun_color) * sun_vis;
	}

	// The write transfer, once, on the way out — and NOT on the cubemap pass. That branch feeds the
	// radiance map behind ambient_light_sky_contribution, and whether Compatibility applies the same
	// decode to a cubemap-pass write was never measured, so encoding it would be a guess on the one
	// region (the ground) that is already at parity. pc_in() above DOES reach it, because the
	// gradient is built before the branch, and that is correct in either case: it only makes the
	// radiance colour agree with what Forward+ uploads. Measured effect on the ground+props region,
	// Compatibility vs Forward+ MAE, before -> after this whole change: home 4.37 -> 4.38,
	// hub 6.24 -> 6.16, vela 2.97 -> 2.77, zorp 4.56 -> 4.53, bolt 4.60 -> 4.35, fen 11.17 -> 11.15,
	// grig 3.46 -> 3.42. Nothing moved, which is the result this line is protecting.
	COLOR = AT_CUBEMAP_PASS ? col : pc_out(col);
}
