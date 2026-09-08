// NEIGHBOURING WORLDS hanging in the sky of a tiny planet (STYLE_GUIDE R2.1).
//
// This is the ground-level twin of the solar-system map's src/rocket/globe.gdshader: same seven
// biome modes, same noise grammar, same soft toon terminator, so the green world you see over the
// hill is recognisably the green world you fly to. That shader belongs to the rocket builder and is
// referenced read-only; this is an independent implementation with three deliberate differences:
//
//   1. UNSHADED with an analytic `sun_dir`. A sky body must show the correct phase at every hour,
//      including at night when environment.gd switches the sun DirectionalLight3D off entirely and
//      only the (differently aimed) moon fill remains. Scene lights cannot do that.
//   2. `fog_disabled`. These sit ~140 m out, far past Environment.fog_depth_end.
//   3. The night side keeps a readable floor. The rocket critic measured Zorp's map globe at 0.0166
//      luma on the dark side against 0.110 lit — a black bite out of the disc. Here `shade_floor`
//      holds the unlit hemisphere at ~1/3 of the lit one so the terminator reads as shading, not as
//      a hole in the sky.
//
// Output is authored display-referred and pushed through the inverse ACES curve (like the sky and
// the ring) so the tonemapper hands the palette back unchanged and nothing crosses the glow
// threshold — a blooming planet would smear a white ball over the horizon.
shader_type spatial;
render_mode unshaded, cull_back, depth_draw_opaque, shadows_disabled, fog_disabled;

#include "res://src/shaders/aces_inverse.gdshaderinc"
#include "res://src/shaders/planet_common.gdshaderinc"

/// 0 meadow (green + seas), 1 violet (glowing rivers), 2 chrome (plate grid + seams), 3 plaza,
/// 4 flats (pale salt rings round dark pools), 5 chalk (quantised contour terraces),
/// 6 frost (polar caps, dark fracture veins, a sparse scatter of station lights).
/// 3 IS ALSO THE FALLBACK: sky_bodies.gd reads `BIOME_MODE.get(biome, 3)`, so a biome with no mode
/// of its own hangs in every sky as the green-and-cream hub, silently.
uniform int mode : hint_range(0, 6) = 0;
uniform vec3 land_a : source_color = vec3(0.30, 0.55, 0.26);
uniform vec3 land_b : source_color = vec3(0.22, 0.44, 0.21);
uniform vec3 low_color : source_color = vec3(0.86, 0.80, 0.62);
uniform vec3 sea_color : source_color = vec3(0.16, 0.40, 0.66);
uniform vec3 sea_deep : source_color = vec3(0.08, 0.22, 0.45);
uniform vec3 accent : source_color = vec3(0.24, 0.78, 1.0);
uniform float accent_glow : hint_range(0.0, 2.0) = 0.45;
uniform float sea_level : hint_range(0.0, 1.0) = 0.46;
uniform float pattern_scale = 2.2;
/// Flat white cloud patches painted on the surface (meadow / plaza), 0 = none.
uniform float cloud_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec3 cloud_color : source_color = vec3(0.92, 0.94, 0.96);

// ---- lighting ---------------------------------------------------------------------------------
/// World-space unit vector pointing TOWARD the sun.
uniform vec3 sun_dir = vec3(0.0, 1.0, 0.0);
uniform vec3 sun_light : source_color = vec3(1.0, 0.97, 0.90);
uniform vec3 shade_tint : source_color = vec3(0.46, 0.44, 0.70);
uniform float shade_strength : hint_range(0.0, 1.0) = 0.50;
/// Fraction of the lit tone the night side keeps. Never near zero — see the header note.
uniform float shade_floor : hint_range(0.0, 1.0) = 0.36;
uniform float ramp_softness : hint_range(0.02, 1.0) = 0.16;
uniform vec3 rim_color : source_color = vec3(0.62, 0.78, 1.0);
uniform float rim_strength : hint_range(0.0, 2.0) = 0.34;
/// Overall brightness, faded down at night with the rest of the sky.
uniform float exposure : hint_range(0.0, 2.0) = 1.0;

uniform float tonemap_white = 6.0;
uniform float display_cap : hint_range(0.1, 1.0) = 0.58;

varying vec3 obj_dir;
varying vec3 world_normal;

float hash13(vec3 p3) {
	p3 = fract(p3 * 0.1031);
	p3 += dot(p3, p3.zyx + 31.32);
	return fract((p3.x + p3.y) * p3.z);
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
	for (int i = 0; i < 4; i++) {
		v += a * vnoise3(p);
		p = p * 2.03 + vec3(11.3, 5.1, 9.7);
		a *= 0.5;
	}
	return v;
}

void vertex() {
	obj_dir = normalize(VERTEX);
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

// WEB PARITY: THE WRITE TRANSFER (planet_common.gdshaderinc lines 5-104 — read that block first).
// Compatibility does not sRGB-decode `source_color` uniforms on upload the way Forward+ does, and
// it DOES sRGB-decode whatever fragment() writes to ALBEDO. This shader does a great deal of
// arithmetic in between — every mix() below, the terminator ramp, the rim add — so on the phone all
// of it ran in display space and each multiplicative term landed as t^2.2. Measured before the fix,
// masked to the sky bodies only, Forward+ vs Compatibility at hour 13: home 166.2 -> 90.3 luma p50
// (GAP 62.8, saturation +0.233), vela 144.4 -> 81.0 (GAP 49.6), grig 171.9 -> 110.6 (GAP 53.6).
// These were the worst objects in the game, and the most eye-catching: home's purple neighbour and
// fen's yellow moon (which came out orange) hang in open sky.
//
// The six palette uniforms that appear more than once are decoded ONCE into locals instead of
// being pc_in()-wrapped at each mention: land_a is read seven times across the biome branches,
// land_b six, sea_deep and low_color four, sea_color and accent three. A second wrap on any one of
// them is a second decode — a silent, plausible-looking error, and recipe note (a) exists because
// somebody will otherwise write it. One alias each makes that impossible. The four that appear
// exactly once (cloud_color, shade_tint, sun_light, rim_color) stay wrapped in place. Cost on the
// phone is six pow() triples on a body 2-4 deg across.
global uniform float astro_compat;

void fragment() {
	vec3 c_land_a = pc_in(land_a);
	vec3 c_land_b = pc_in(land_b);
	vec3 c_low = pc_in(low_color);
	vec3 c_sea = pc_in(sea_color);
	vec3 c_sea_deep = pc_in(sea_deep);
	vec3 c_accent = pc_in(accent);
	vec3 p = obj_dir * pattern_scale;
	vec3 col = c_land_a;
	float em = 0.0;

	if (mode == 0) {
		// Meadow: broad continents, small round seas, a thin sand shore.
		float n = fbm3(p);
		float land = smoothstep(sea_level - 0.035, sea_level + 0.035, n);
		float depth = smoothstep(sea_level, sea_level - 0.14, n);
		vec3 water = mix(c_sea, c_sea_deep, depth);
		vec3 ground = mix(c_land_a, c_land_b, smoothstep(0.50, 0.76, n));
		float shore = smoothstep(sea_level + 0.004, sea_level + 0.026, n)
			* (1.0 - smoothstep(sea_level + 0.026, sea_level + 0.055, n));
		ground = mix(ground, c_low * 0.82, shore * 0.55);
		col = mix(water, ground, land);
	} else if (mode == 1) {
		// Violet: muted lilac land with thin glowing rivers along the noise ridges.
		float n = fbm3(p);
		col = mix(c_land_b, c_land_a, smoothstep(0.36, 0.70, n));
		float r = fbm3(p * 0.85 + 31.0);
		float ridge = 1.0 - abs(r * 2.0 - 1.0);
		float river = smoothstep(0.93, 0.995, ridge);
		col = mix(col, c_accent * 0.42, river * 0.62);
		em = river;
	} else if (mode == 2) {
		// Chrome: irregular flat plates with glowing seams.
		vec3 q = vec3(dot(p, vec3(0.80, 0.36, -0.48)), dot(p, vec3(-0.30, 0.92, 0.24)), dot(p, vec3(0.52, 0.14, 0.84)));
		q *= 1.15;
		q += vec3(fbm3(p * 1.3), fbm3(p * 1.3 + 7.0), fbm3(p * 1.3 + 19.0)) * 0.55;
		vec3 cell = floor(q);
		vec3 f = q - cell;
		float plate = hash13(cell);
		col = mix(c_land_b, c_land_a, plate);
		float e = min(min(min(f.x, 1.0 - f.x), min(f.y, 1.0 - f.y)), min(f.z, 1.0 - f.z));
		float seam = smoothstep(0.030, 0.006, e);
		col = mix(col, c_accent * 0.30, seam * 0.45);
		em = seam;
	} else if (mode == 4) {
		// Flats: a dry salt pan pocked with round pools. A broad crust mottle for the pan, plus a
		// lower-frequency bowl field whose low ground IS the pool; the pale ring between the two is
		// the salt crust, and it is what makes each pool read as a bowl and not as a blue dot.
		// Kept identical to src/rocket/globe.gdshader mode 4 so Fen in the sky is Fen on the map.
		float n = fbm3(p * 1.35);
		float b = fbm3(p * 1.05 + 19.0);
		vec3 pan = mix(c_land_a, c_land_b, smoothstep(0.44, 0.68, n));
		float pool = 1.0 - smoothstep(sea_level - 0.025, sea_level + 0.015, b);
		float ring = smoothstep(sea_level - 0.005, sea_level + 0.030, b)
			* (1.0 - smoothstep(sea_level + 0.055, sea_level + 0.105, b));
		col = mix(pan, c_low * 0.92, ring * 0.80);
		// Capped at 0.7 toward c_sea_deep: these are 40-70 cm mirror pools you can see the floor of,
		// and the full deep tone punched black holes in a body only 2-4 deg across.
		col = mix(col, mix(c_sea, c_sea_deep, pool * 0.7), pool);
	} else if (mode == 5) {
		// Chalk: the world cut into concentric terraces - the sky-scale twin of the real
		// terrace_bank contour rings. Quantise one height field into steps, alternate the tread
		// tone so neighbouring shelves separate, and paint a thin band at every step boundary in
		// c_low for the riser faces.
		// DELIBERATELY NOT fbm3, and identical to src/rocket/globe.gdshader mode 5: fbm's upper
		// octaves shatter a contour line into speckle, and Grig's real terrain is only ~1.9 noise
		// cycles around the whole world. One dominant smooth octave, a light second, 7 steps.
		float h = vnoise3(p) * 0.82 + vnoise3(p * 2.1 + 7.0) * 0.18;
		float f = h * 7.0;
		float tread = floor(f);
		float band = f - tread;
		col = mix(c_land_a, c_land_b, mod(tread, 2.0) * 0.5);
		col *= mix(0.90, 1.10, clamp(h * 1.5 - 0.25, 0.0, 1.0));
		float edge = min(band, 1.0 - band);
		float riser = 1.0 - smoothstep(0.06, 0.14, edge);
		col = mix(col, c_low, riser * 0.80);
	} else if (mode == 6) {
		// Frost: an ice world read by LATITUDE. Every other mode here is isotropic 3D noise, so
		// "poles" is the one structural cue none of them can say - bright caps over a darker
		// fractured belt, which is what keeps Vela from reading as Grig's bone-white ball in a
		// cooler tint on a body only 2-4 deg across. Identical to src/rocket/globe.gdshader
		// mode 6 so Vela in the sky is Vela on the map.
		float cap = smoothstep(0.44, 0.80, abs(obj_dir.y));
		float n = fbm3(p * 1.5);
		col = mix(c_land_b, c_land_a, smoothstep(0.40, 0.66, n));
		// Melt ponds in the low ground of the belt, never on the caps.
		float melt = 1.0 - smoothstep(sea_level - 0.030, sea_level + 0.020, n);
		col = mix(col, mix(c_sea, c_sea_deep, melt * 0.75), melt * (1.0 - cap) * 0.85);
		// Fracture veins: the SAME ridge construction as mode 1's rivers, deliberately inverted -
		// thin and DARK instead of thin and glowing, so the two never read as the same world.
		float r = fbm3(p * 0.95 + 43.0);
		float ridge = 1.0 - abs(r * 2.0 - 1.0);
		float crack = smoothstep(0.90, 0.99, ridge);
		col = mix(col, c_sea_deep, crack * 0.50);
		col = mix(col, c_low, cap * 0.90);
		// The Long Array: a sparse scatter of station lights on the belt, never on the ice cap.
		// ~11 cells across the diameter and a 0.955 cut, so it is a handful of pinpricks on the
		// night side rather than the hub's whole lit town.
		em = smoothstep(0.955, 0.988, hash13(floor(obj_dir * 11.0))) * (1.0 - cap);
	} else {
		// Plaza: cream tiles and broad green lawns.
		float n = fbm3(p * 1.15);
		col = mix(c_low, c_land_a, smoothstep(0.40, 0.60, n));
		col = mix(col, c_land_b, smoothstep(0.64, 0.84, n) * 0.65);
	}

	// Flat cloud patches, painted rather than modelled: at 2-3 deg across, a mesh puff would be a
	// single aliased pixel. Crisp-edged, so the silhouette stays defined like the map globes.
	if (cloud_amount > 0.002) {
		float cn = fbm3(obj_dir * 3.4 + 57.0);
		float cover = smoothstep(0.56, 0.66, cn) * cloud_amount;
		col = mix(col, pc_in(cloud_color), cover);
	}

	// ---- analytic sun lighting: a soft toon terminator with a readable night side --------------
	vec3 n_w = normalize(world_normal);
	float ndl = dot(n_w, normalize(sun_dir));
	float lit = smoothstep(-ramp_softness, ramp_softness, ndl);
	vec3 shadow_col = col * mix(vec3(1.0), pc_in(shade_tint), shade_strength);
	vec3 outc = mix(shadow_col * shade_floor, col, lit) * pc_in(sun_light);

	// Thin atmosphere rim on the lit limb.
	float rim = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), 3.2);
	outc += pc_in(rim_color) * rim * rim_strength * smoothstep(-0.05, 0.55, ndl);

	// Settlement / river / seam lights belong to the night side.
	float night_side = 1.0 - smoothstep(-0.18, 0.28, ndl);
	outc += c_accent * em * accent_glow * mix(0.22, 1.0, night_side);

	// The write transfer, once, on the way out. `display_cap` is 0.58 and aces_inverse maps that to
	// ~0.24 HDR, well under the 1.0 at which Compatibility clips a fragment write, so nothing here
	// runs into the over-range caveat in planet_common's recipe note (g).
	ALBEDO = pc_out(aces_inverse(cap_display(outc * exposure, display_cap), tonemap_white));
}
