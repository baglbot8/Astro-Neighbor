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
// WEB PARITY (docs/OPEN_ISSUES.md 32). This sky is authored in DISPLAY-REFERRED colour and
// pushed back through the inverse ACES curve so the renderer's tonemapper returns the palette
// unchanged. That round trip does not close under the Compatibility (WebGL2) renderer, which
// the web export is forced onto: measured over the upper sky, Forward+ renders (29,28,57) —
// the intended navy — and Compatibility renders (8,5,31), which reads as flat black on a
// phone. Reported from a real iPhone as 'the sky is black instead of navy'.
// The lift is applied BEFORE the inverse curve, so it moves the authored colour rather than
// scaling the result: the curve is steep down there, so darks recover far more than the sun
// and stars, which are added afterwards and are untouched.
global uniform float astro_compat;
// A MULTIPLY was tried first and is wrong: the dark sky is blue-dominant, so scaling it grows
// the blue channel fastest and at the strength needed to fix the darks it turned the sky vivid
// royal blue — exactly the Earth-like sky R2.1 bans. A neutral ADD lifts the black end toward
// the intended navy without touching the hue balance. Desktop reference for the sky band is a
// near-neutral (91,88,99); Compatibility rendered the bulk of it at luma 13 against 33.
uniform float compat_sky_lift : hint_range(0.0, 0.3) = 0.08;

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
	vec3 c_limb = mix(limb_color, zenith_color, space_blend);
	vec3 c_mid = mix(mid_color, zenith_color, space_blend * 0.9);
	float t_low = clamp(hp / mid_height, 0.0, 1.0);
	float t_high = clamp((hp - mid_height) / max(zenith_height - mid_height, 0.01), 0.0, 1.0);
	vec3 col = mix(c_limb, c_mid, t_low * t_low * (3.0 - 2.0 * t_low));
	col = mix(col, zenith_color, t_high * t_high * (3.0 - 2.0 * t_high));

	// ---- the thin limb band ------------------------------------------------------------------
	// Two falloffs: a tight bright rim right on the silhouette plus a much wider, fainter skirt,
	// so the band has a soft top edge instead of a hard ring.
	float above_ground = smoothstep(-0.02, 0.004, h);   // 0 below the silhouette, 1 above it
	float rim = exp(-hp / haze_width);
	float skirt = exp(-hp / (haze_width * 2.8)) * 0.26;
	float haze = clamp((rim + skirt) * haze_strength * (1.0 - space_blend), 0.0, 1.0);
	col = mix(col, haze_color, haze);

	// ---- sunrise / sunset: the band burns warm on the sun's side ------------------------------
	float sc = dot(d, sun_dir);
	float sun_h = limb_height(sun_dir);
	float sun_vis = smoothstep(-0.16, -0.03, sun_h);
	float glow = pow(max(sc, 0.0), 3.0) * exp(-hp / (haze_width * 4.5)) * sun_glow * (1.0 - space_blend);
	col = mix(col, sun_glow_color, clamp(glow, 0.0, 1.0));
	col += pow(max(sc, 0.0), 2.5) * sun_glow * sun_glow_color * 0.10 * (1.0 - space_blend);

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
		col += milky_way_color * mw_band * (0.30 + 0.70 * mwn) * 0.20 * mw_vis;

		// ---- thin high dust wisps inside the band ----------------------------------------
		float cov = 0.0;
		if (wisp_amount > 0.002) {
			// Only in the first ~10 deg above the limb, and squashed hard in elevation so the
			// streaks are horizontal filaments rather than blobs.
			float band = exp(-hp / 0.10) * smoothstep(-0.005, 0.02, h);
			vec2 cuv = vec2(az / TAU * WISP_PERIOD + TIME * wind, hp * 22.0);
			float n = fbm(cuv, WISP_PERIOD);
			cov = smoothstep(0.60, 0.80, n) * band * wisp_amount * (1.0 - space_blend);
			col = mix(col, wisp_color, cov);
		}

		// ---- to HDR ----------------------------------------------------------------------
		col = aces_inverse(cap_display(col + vec3(compat_sky_lift * astro_compat), display_cap), tonemap_white);

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
		col += draw_moon(d, moon_dir_a, moon_size, moon_color, 0.62, vis_a);
		if (moon_count > 1) {
			float vis_b = moon_vis * smoothstep(-0.14, -0.01, limb_height(moon_dir_b));
			col += draw_moon(d, moon_dir_b, moon_size * 0.55, moon_b_color, 1.35, vis_b);
		}

		// ---- sun disc + a tight halo (no air, so no big glare ball) ----------------------
		float ang = acos(clamp(sc, -1.0, 1.0));
		float disc = 1.0 - smoothstep(sun_disc_size * 0.82, sun_disc_size, ang);
		float halo = pow(max(sc, 0.0), 620.0) * 0.75 + pow(max(sc, 0.0), 90.0) * 0.16;
		col += (disc * 3.4 + halo * (1.0 - cov * 0.6)) * sun_color * sun_vis;
	}

	COLOR = col;
}
