shader_type spatial;
render_mode unshaded, cull_back, depth_draw_opaque, diffuse_burley;
// SPIKE (2026-09-21, scratch only). A WORLD YOU CAN SEE FROM THE LANE.
//
// The user, on the safari frames: "There's no real clear sense of direction as you're moving
// through space... We need some point of reference e.g. the target planet in the distance getting
// closer?" A sphere with one flat albedo does not do that job: at 2 degrees across it is a dot, and
// a dot that gets bigger is still a dot. What reads as APPROACHING is a body that gains DETAIL -
// first a lit crescent, then bands, then a coastline, then a bright air shell at the limb.
//
// So this is lit by hand rather than by the engine. `unshaded` and one `sun_dir` uniform, because
// the thing that matters is the TERMINATOR, and a DirectionalLight3D's terminator on a 48-segment
// sphere is a faceted stair at 12 degrees across. Doing it per-pixel against the true normal makes
// it a clean curve at any size, and it costs one dot product.
//
// Everything procedural, no texture sampled: three octaves of value noise on the object-space
// normal give the land, one more gives the weather, and the night side is not black - there is a
// faint aurora at the poles and a few embers where the land is.
//
// Same shader for home and for the destination; they differ only in these uniforms.

uniform vec3 sun_dir = vec3(-0.62, 0.30, 0.72);   // WORLD space, pointing from the world TO the sun
uniform vec3 c_low : source_color = vec3(0.16, 0.30, 0.44);    // the seas / the low ground
uniform vec3 c_high : source_color = vec3(0.42, 0.52, 0.40);   // the land
uniform vec3 c_air : source_color = vec3(0.46, 0.66, 0.92);    // the air shell at the limb
uniform vec3 c_night : source_color = vec3(0.10, 0.16, 0.30);  // what the dark side is lit BY
uniform vec3 c_ember : source_color = vec3(1.00, 0.78, 0.42);  // the lights on the night side
uniform float land_freq : hint_range(0.5, 8.0) = 2.4;
uniform float land_bias : hint_range(-0.4, 0.4) = 0.0;
uniform float band_gain : hint_range(0.0, 1.0) = 0.30;   // gas-giant banding, 0 for a rocky world
uniform float ember_gain : hint_range(0.0, 2.0) = 1.0;
uniform float spin : hint_range(0.0, 0.2) = 0.010;
uniform float seed = 1.0;
uniform float cap : hint_range(0.5, 1.0) = 0.86;  // STYLE_GUIDE R2.6: nothing near-clips to white

varying vec3 v_obj;

float h31(vec3 p) {
	return fract(sin(dot(p, vec3(127.1, 311.7, 74.7)) + seed) * 43758.5453);
}

float vnoise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float n = mix(
		mix(mix(h31(i + vec3(0, 0, 0)), h31(i + vec3(1, 0, 0)), f.x),
			mix(h31(i + vec3(0, 1, 0)), h31(i + vec3(1, 1, 0)), f.x), f.y),
		mix(mix(h31(i + vec3(0, 0, 1)), h31(i + vec3(1, 0, 1)), f.x),
			mix(h31(i + vec3(0, 1, 1)), h31(i + vec3(1, 1, 1)), f.x), f.y), f.z);
	return n;
}

float fbm(vec3 p) {
	return vnoise(p) * 0.55 + vnoise(p * 2.07 + 11.3) * 0.28 + vnoise(p * 4.13 + 5.7) * 0.17;
}

void vertex() {
	v_obj = normalize(VERTEX);
}

void fragment() {
	vec3 o = normalize(v_obj);
	// the world turns slowly under its own weather, so a long look is not a still picture
	float a = TIME * spin;
	vec3 os = vec3(o.x * cos(a) - o.z * sin(a), o.y, o.x * sin(a) + o.z * cos(a));

	// world-space normal and view direction, for the terminator and the limb
	vec3 nw = normalize((MODEL_MATRIX * vec4(o, 0.0)).xyz);
	vec3 vw = normalize((INV_VIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz
		- (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz);

	// ---- the ground
	float land = fbm(os * land_freq) + land_bias;
	float bands = sin(os.y * 9.0 + fbm(os * 1.6) * 2.6) * 0.5 + 0.5;
	land = mix(land, mix(land, bands, 0.75), band_gain);
	float coast = smoothstep(0.46, 0.60, land);
	vec3 ground = mix(c_low, c_high, coast);
	// a little mottle so a big disc is not two flat colours
	ground *= 0.86 + 0.28 * fbm(os * 7.4 + 30.0);
	// ice at the poles, which is also what tells you the world has an axis
	float pole = smoothstep(0.74, 0.95, abs(os.y));
	ground = mix(ground, vec3(0.80, 0.85, 0.92), pole * 0.55);

	// ---- weather: one thin high layer, drifting the other way
	float cl = fbm(os * 3.1 + vec3(TIME * 0.006, 0.0, -TIME * 0.004) + 60.0);
	float cloud = smoothstep(0.54, 0.74, cl) * 0.55;
	ground = mix(ground, vec3(0.86, 0.88, 0.93), cloud);

	// ---- day and night
	float lam = dot(nw, normalize(sun_dir));
	// R11 (wave 3): toon light, as in the glass's world_disc - a crisp terminator and a lavender
	// shade side instead of a photographic Lambert ramp.
	float lit = smoothstep(-0.03, 0.09, lam);
	vec3 col = mix(ground * vec3(0.44, 0.42, 0.62), ground * (0.82 + 0.18 * max(lam, 0.0)), lit);

	// the dark side reads: a cool wash, an aurora ring, and embers where the land is
	col += c_night * (1.0 - lit) * 0.30;
	// WAVE 3 (G5, R12): this ring used to carry `sin(os.x * 14 + TIME * 0.7)` - a wave that
	// travelled round the pole on the dark side, the one moving ripple on the 3D globe. The user
	// asked for the planet's wavy effect to go; the ring stays, still.
	float aur = smoothstep(0.58, 0.86, abs(os.y)) * (1.0 - lit)
		* (0.55 + 0.45 * sin(os.x * 14.0 + seed));
	col += vec3(0.32, 0.86, 0.62) * aur * 0.18;
	float ember = step(0.62, land) * step(0.986, h31(floor(os * 46.0)));
	col += c_ember * ember * (1.0 - lit) * 0.55 * ember_gain;

	// ---- the air shell. A thin atmosphere (STYLE_GUIDE R2.1), so it is a narrow bright rim, not a
	// fat blue halo, and it is brightest where the sun grazes it.
	float rim = pow(1.0 - clamp(dot(nw, vw), 0.0, 1.0), 3.4);
	col += c_air * rim * (0.16 + 0.95 * smoothstep(-0.35, 0.55, lam));

	ALBEDO = (vec3(1.0) - exp(-col * 1.25)) * cap;
}
