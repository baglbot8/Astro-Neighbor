// SPIKE (2026-09-21, scratch only). ONE SKY, SHARED BY THE WINDOW AND THE GLASS.
//
// This exists because of a bug you can only see by swinging the scope. The eyepiece used to build
// its star field from `abs_p = p + look * 2.35` - a FLAT slide of a flat grid. Two things follow
// from that and both were on the frames: the stars shear and smear as you pan (a plane pretending
// to be a sphere), and the sky inside the glass has no relation to the sky outside it, so the
// spyglass reads as a sticker over a different night.
//
// The brief this round is "a thing you saw on your left is still on your left when you swing back,
// and the stars do not smear". The only honest way to get that is to key the sky on a DIRECTION,
// not on a screen offset - so both shaders now build a world-space `d` and call the same functions
// out of this one file. Panning is then just a different `d`: the same stars are in the same places
// from any heading, at either magnification, because there is only one sky and it is a function of
// where you are pointing.
//
// MAGNIFICATION IS FREE and it is also correct. The glass covers 14 degrees where the window covers
// 70, so it walks the same equirectangular chart five times more slowly: the same stars come out
// further apart. The one thing added on purpose is LAYERS: the naked eye gets 3 octaves, the glass
// gets 5, so swinging the scope over an empty patch of window finds stars that were not there. That
// is what a 10x glass does, and it costs two more octaves inside a 14-degree field.
//
// Everything procedural. No texture is sampled anywhere in here.

const float LANE_TAU = 6.2831853;
const float LANE_PI = 3.1415927;

float lane_h21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// Smooth 2D value noise off the same hash. Anything that wants a soft cloud uses this; anything
// that uses lane_h21(floor(x)) directly gets rectangles, which is a bug, not a style.
float lane_vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(lane_h21(i), lane_h21(i + vec2(1.0, 0.0)), f.x),
		mix(lane_h21(i + vec2(0.0, 1.0)), lane_h21(i + vec2(1.0, 1.0)), f.x), f.y);
}

// An equirectangular chart of the sky. Cells stay roughly square away from the poles, which a plain
// xy projection does not, and it is the same chart at both magnifications.
vec2 lane_chart(vec3 d) {
	return vec2(atan(d.z, d.x) / LANE_TAU + 0.5, asin(clamp(d.y, -1.0, 1.0)) / LANE_PI + 0.5);
}

// THE STARS. `layers` octaves of a jittered grid; `rad_mul` shrinks them for a magnified view so a
// star stays a point instead of becoming a blob; `faint` is the brightness cut - the glass lets
// more through. Layers 0-2 are identical in both callers, so the bright stars ARE the same stars.
vec3 lane_stars(vec3 d, int layers, float rad_mul, float faint, float gain) {
	vec2 uv = lane_chart(d);
	vec3 col = vec3(0.0);
	for (int i = 0; i < 5; i++) {
		if (i >= layers) {
			break;
		}
		float lay = float(i);
		vec2 gs = uv * vec2(190.0 + lay * 165.0, 95.0 + lay * 82.0) + vec2(lay * 11.3, lay * 7.7);
		vec2 cell = floor(gs);
		vec2 f = fract(gs) - 0.5;
		vec2 o = vec2(lane_h21(cell + lay * 3.1), lane_h21(cell + 3.3 + lay)) - 0.5;
		float m = lane_h21(cell + 7.1 + lay * 2.0);
		float rad = (0.055 + 0.075 * m) * rad_mul;
		float s = smoothstep(rad, 0.0, length(f - o * 0.74));
		// a blue-white ramp, not one flat star colour
		vec3 sc = mix(vec3(1.0, 0.90, 0.78), vec3(0.80, 0.87, 1.0), lane_h21(cell + 19.0 + lay));
		col += sc * s * step(faint, m) * (0.22 + 0.55 * m) * gain / (1.0 + 0.7 * lay);
	}
	return col;
}

// THE NEBULA. The user called the old lane "too serious, empty" - this is most of the answer, and
// it is the one thing out here that never moves, so it is also the compass: the rose core sits
// across the lane ahead and to port, the teal drift sits astern. Swing until the warm band is on
// your right and you are looking down the lane. Dim on purpose (peaks near 0.17) so STYLE_GUIDE
// R2.6's "blown highlights under 5%" is not spent on empty sky.
vec3 lane_nebula(vec3 d) {
	// the milky band: one plane through the sky, softly fogged
	float bandv = (d.y * 0.80 + d.x * 0.42 + 0.22) / 0.55;
	float band = exp(-bandv * bandv);
	vec3 col = vec3(0.050, 0.048, 0.092) * band;
	// dust inside the band, so it is not a smooth airbrush stripe. SMOOTH value noise, not raw
	// cells: a `floor()` lookup here painted visible rectangles across the whole sky on the first
	// capture of this round, which is the kind of thing only a frame tells you.
	vec2 ch = lane_chart(d);
	float dust = lane_vnoise(ch * vec2(26.0, 13.0)) * 0.62
		+ lane_vnoise(ch * vec2(57.0, 29.0) + 4.0) * 0.38;
	col *= 0.55 + 0.90 * dust;
	// the warm core, off the port bow
	vec3 rose_at = normalize(vec3(-0.52, 0.30, -0.80));
	float rose = pow(max(dot(d, rose_at), 0.0), 5.0);
	col += vec3(0.120, 0.052, 0.062) * rose * (0.55 + 0.75 * band);
	col += vec3(0.085, 0.040, 0.105) * pow(max(dot(d, normalize(vec3(-0.80, 0.10, -0.42))), 0.0), 3.2);
	// the cold drift astern, so looking BACK is a different colour from looking ahead
	vec3 teal_at = normalize(vec3(0.34, -0.16, 0.92));
	col += vec3(0.028, 0.072, 0.078) * pow(max(dot(d, teal_at), 0.0), 4.0);
	return col;
}

// =============================================================================================
// WAVE 3 (G5, spec R11): THE GAME'S OWN SPACE.
//
// The user, after flying wave 2: "Space looks too realistic which is different than the art style
// we've established in the game today." Measured before this change, on a real Compatibility frame
// of the lowered glass (home->zorp, t=84): the dominant swatches were #322730 / #261e27 / #3e3037 -
// a hazy mauve-grey, saturation 0.21, from five octaves of jittered stars (thousands of pinpoints
// in the window), a blotchy dust nebula and radial warp streaks. That is a telescope photograph.
//
// The game already has a space look, and the user already approved it ("the space scenes look
// good", STYLE_GUIDE R2.6): the rocket flight, src/rocket/space_sky.gdshader, and the sky over
// every planet, src/shaders/sky.gdshader. Both are a deep indigo-navy, a few hundred crisp stars
// with a small cross flare on the brightest, and a handful of soft flat cloud patches in violet,
// teal and rose. So this is NOT a new style - it is that one, brought into the glass:
//
//   * THE STAR GRAMMAR IS THE SAME FUNCTION. lane_star_field() is space_sky.gdshader's
//     star_layer() - one 3D cell per star, a crisp dot that goes straight to zero, a cross flare
//     on the top few - with its first three layers at the same scales and thresholds. The 254-cell
//     dust layer is left out: at 56 degrees it is the grit that read as a photograph.
//   * THE NAVY IS THE ROCKET SKY'S. Measured off a real Compatibility frame of the rocket flight
//     (showcase/rocket_journey, frame 120, the open sky): median #0e1031, (10..14, 13..16, 47..49).
//     That swatch is S 0.72-0.81; LANE_NAVY_HIGH is it lifted to V 0.195 and held at S 0.62, and
//     LANE_NAVY_LEVEL (on the flight's plane) at S 0.56, because the aurora's periwinkle haze
//     (safari_eyepiece.gdshader, R2) lifts the whole lower half of the window on top of it and a
//     measured frame is what gates STYLE_GUIDE's S 0.60 swatch rule, not these two constants.
//   * THE NEBULA IS FLAT PATCHES, NOT DUST. Two flat tiers with soft edges (a paper cut-out, the
//     cloud rule of STYLE_GUIDE "Shape language corrections": "soft flat puffs with a defined
//     silhouette"), in the rocket sky's own violet / teal / rose, at the rocket sky's weights.
//
// Keyed on the WORLD direction, like everything in this file, so the window and the glass still
// draw one sky.

const vec3 LANE_NAVY_HIGH = vec3(0.074, 0.082, 0.195);   // away from the flight's plane
const vec3 LANE_NAVY_LEVEL = vec3(0.096, 0.098, 0.220);  // on it

float lane_hash13(vec3 p3) {
	p3 = fract(p3 * 0.1031);
	p3 += dot(p3, p3.zyx + 31.32);
	return fract((p3.x + p3.y) * p3.z);
}

vec3 lane_hash33(vec3 p3) {
	p3 = fract(p3 * vec3(0.1031, 0.1030, 0.0973));
	p3 += dot(p3, p3.yxz + 33.33);
	return fract((p3.xxy + p3.yxx) * p3.zyx);
}

float lane_vnoise3(vec3 p) {
	vec3 i = floor(p);
	vec3 f = p - i;
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(lane_hash13(i), lane_hash13(i + vec3(1.0, 0.0, 0.0)), f.x),
			mix(lane_hash13(i + vec3(0.0, 1.0, 0.0)), lane_hash13(i + vec3(1.0, 1.0, 0.0)), f.x), f.y),
		mix(mix(lane_hash13(i + vec3(0.0, 0.0, 1.0)), lane_hash13(i + vec3(1.0, 0.0, 1.0)), f.x),
			mix(lane_hash13(i + vec3(0.0, 1.0, 1.0)), lane_hash13(i + vec3(1.0, 1.0, 1.0)), f.x), f.y),
		f.z);
}

float lane_fbm3(vec3 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 3; i++) {
		v += a * lane_vnoise3(p);
		p = p * 2.07 + vec3(13.1, 7.7, 3.3);
		a *= 0.5;
	}
	return v;
}

// The navy, lighter and a little warmer on the flight's level plane (dw.y = 0 in the world) and
// deeper toward either pole - the same shape as the planet sky's limb, without the ground.
vec3 lane_space_base(vec3 d) {
	return mix(LANE_NAVY_LEVEL, LANE_NAVY_HIGH, smoothstep(0.0, 0.75, abs(d.y)));
}

// Flat cloud patches in the rocket sky's own three colours, at the rocket sky's own centres
// (space_sky.gdshader's ma/mb/mc), posterised into two tiers so they read as cut paper.
vec3 lane_space_clouds(vec3 d) {
	float f = lane_fbm3(d * 2.35 + 17.0);
	// the rocket sky's second field is three octaves too; here it is one, because it only shapes
	// the patch edges and the heat bench (safari_run.gd --heat --heat-copies) charges ~0.1 ms a
	// porthole at 2556x1179 for the other two
	float g = lane_vnoise3(d * 5.60 + 41.0);
	float m1 = f * 0.72 + g * 0.28;
	float m2 = f * 0.45 + g * 0.55;
	// two tiers, each a flat level with a soft edge a few percent of the noise range wide
	float c1 = smoothstep(0.52, 0.56, m1) * 0.55 + smoothstep(0.62, 0.66, m1) * 0.45;
	float c2 = smoothstep(0.55, 0.59, m2) * 0.55 + smoothstep(0.65, 0.69, m2) * 0.45;
	float ma = smoothstep(0.42, 0.98, dot(d, normalize(vec3(-0.62, 0.28, 0.73))));
	float mb = smoothstep(0.50, 0.99, dot(d, normalize(vec3(0.78, -0.16, 0.60))));
	float mc = smoothstep(0.55, 1.00, dot(d, normalize(vec3(0.08, 0.72, -0.69))));
	vec3 col = vec3(0.36, 0.24, 0.60) * ma * c1 * 0.20;
	col += vec3(0.16, 0.42, 0.48) * mb * c2 * 0.17;
	col += vec3(0.52, 0.26, 0.40) * mc * c1 * 0.13;
	// the milky band: one soft flat stripe along GALAXY_N, as the rocket sky has it
	float gd = dot(d, normalize(vec3(0.30, 0.75, 0.55)));
	float band = smoothstep(0.30, 0.10, abs(gd));
	col += vec3(0.34, 0.33, 0.56) * band * (0.35 + 0.65 * smoothstep(0.45, 0.60, f)) * 0.07;
	return col;
}

// One layer of space_sky.gdshader's star_layer(), ported line for line. `size_mul` shrinks the
// star's ANGULAR size so it keeps its PIXEL size when the glass magnifies (field_half / 28 deg).
vec3 lane_star_layer(vec3 d, float scale, float thresh, float size_max, float bright, float t,
		float size_mul) {
	vec3 p = d * scale;
	vec3 cell = floor(p);
	float sp = lane_hash13(cell + 5.71);
	if (sp < thresh) {
		return vec3(0.0);
	}
	vec3 h = lane_hash33(cell);
	vec3 pos = 0.28 + 0.44 * h;
	vec3 q3 = p - cell - pos;
	float dist = length(q3);
	float b = (sp - thresh) / max(1.0 - thresh, 0.001);
	float size = mix(size_max * 0.35, size_max, b * b) * size_mul;
	// a crisp dot: flat inside, a short soft edge, then nothing - a sticker, not a PSF
	float s = smoothstep(size, size * 0.55, dist);
	float tw = 0.72 + 0.28 * sin(t * (1.1 + 2.4 * h.x) + h.y * LANE_TAU);
	vec3 tint = mix(vec3(0.80, 0.88, 1.0), vec3(1.0, 0.90, 0.76), h.z);
	vec3 acc = tint * s * bright * (0.35 + 0.9 * b) * tw;
	// the brightest few are four-point sparkles in stardust cream (#fff6c8), the shape the game
	// already uses for stardust, instead of a lens-flare cross
	if (b > 0.86) {
		vec3 a3 = abs(q3) / max(size_mul, 0.05);
		float spk = exp(-a3.x * 34.0) * exp(-(a3.y + a3.z) * 11.0)
			+ exp(-a3.y * 34.0) * exp(-(a3.x + a3.z) * 11.0);
		acc += vec3(1.0, 0.965, 0.784) * spk * 0.55 * bright * tw;
	}
	return acc;
}

vec3 lane_star_field(vec3 d, float t, float size_mul) {
	// space_sky.gdshader at its shipped star_density 1.0: dense = 0.872, then +0.030, +0.052
	vec3 s = lane_star_layer(d, 54.0, 0.872, 0.120, 1.00, t, size_mul);
	s += lane_star_layer(d, 98.0, 0.902, 0.088, 0.70, t + 3.1, size_mul);
	s += lane_star_layer(d, 176.0, 0.924, 0.072, 0.44, t + 6.4, size_mul);
	return s;
}
