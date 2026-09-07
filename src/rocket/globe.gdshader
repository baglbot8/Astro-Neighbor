// Miniature planet surfaces for the solar-system map. One shader, seven biome modes, all driven from
// the planet's PlanetData so the globe you see in space matches the world you land on:
//   0 meadow  green land + small blue seas with a sand shore
//   1 violet  muted violet land with thin glowing river lines
//   2 chrome  grey-blue plate grid with glowing orange seams
//   3 plaza   cream/green patchwork with a few lit windows
//   4 flats   a dry terracotta pan pocked with dark pools, each ringed in pale salt crust
//   5 chalk   a bone-white ball cut into quantised contour terraces, risers in the bank tone
//   6 frost   a pale ice ball with bright polar caps, dark fracture veins and a scatter of lights
//
// 3 IS ALSO THE FALLBACK. The final `else` is plaza, so a biome with no mode of its own renders as
// the green-and-cream hub with no error anywhere - see space_globe.gd::_apply_biome, which must
// carry an explicit arm for every biome that ships.
//
// Lighting is the game's soft toon ramp (same grammar as toon_soft.gdshader) so the globes read as
// rounded forms with a clean terminator — the dark limb is what keeps the space frames dark.
// Accent emission is boosted on the night side, which is where a planet's lights should show.
shader_type spatial;
render_mode cull_back, depth_draw_opaque, diffuse_lambert, specular_schlick_ggx;

uniform int mode : hint_range(0, 6) = 0;
uniform vec4 land_a : source_color = vec4(0.30, 0.55, 0.26, 1.0);
uniform vec4 land_b : source_color = vec4(0.22, 0.44, 0.21, 1.0);
uniform vec4 low_color : source_color = vec4(0.86, 0.80, 0.62, 1.0);
uniform vec4 sea_color : source_color = vec4(0.16, 0.40, 0.66, 1.0);
uniform vec4 sea_deep : source_color = vec4(0.08, 0.22, 0.45, 1.0);
uniform vec4 accent : source_color = vec4(0.24, 0.78, 1.0, 1.0);
uniform float accent_glow : hint_range(0.0, 8.0) = 2.4;
uniform float sea_level : hint_range(0.0, 1.0) = 0.46;
uniform float pattern_scale = 2.6;
uniform vec4 shade_tint : source_color = vec4(0.42, 0.38, 0.68, 1.0);
// Night side. A floor of 0.19 with a 0.19 ramp measured a 6.6x cliff between Zorp's lit and dark
// hemispheres (0.0166 vs 0.110 luma) — a black bite out of the disc, not a terminator. 0.60 with a
// wide ramp keeps the dark side reading as the SAME planet in shade, which is what the AC night
// reference does (p95 0.329, nothing near black).
uniform float shade_strength : hint_range(0.0, 1.0) = 0.45;
uniform float shade_floor : hint_range(0.0, 1.0) = 0.60;
uniform float ramp_softness : hint_range(0.02, 1.0) = 0.42;
uniform float rim_strength : hint_range(0.0, 2.0) = 0.35;
uniform vec4 rim_color : source_color = vec4(0.62, 0.78, 1.0, 1.0);
// World-space direction TOWARD the sun; only used to decide which face is the night side.
uniform vec3 sun_dir = vec3(0.0, 0.0, 1.0);

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

void fragment() {
	vec3 p = obj_dir * pattern_scale;
	vec3 col = land_a.rgb;
	vec3 em = vec3(0.0);
	float rough = 0.88;

	if (mode == 0) {
		// Meadow: broad continents, small round seas, a thin sand shore.
		float n = fbm3(p);
		float land = smoothstep(sea_level - 0.035, sea_level + 0.035, n);
		float depth = smoothstep(sea_level, sea_level - 0.14, n);
		vec3 water = mix(sea_color.rgb, sea_deep.rgb, depth);
		vec3 ground = mix(land_a.rgb, land_b.rgb, smoothstep(0.50, 0.76, n));
		float shore = smoothstep(sea_level + 0.004, sea_level + 0.026, n) * (1.0 - smoothstep(sea_level + 0.026, sea_level + 0.055, n));
		ground = mix(ground, low_color.rgb * 0.82, shore * 0.55);
		col = mix(water, ground, land);
		rough = mix(0.35, 0.92, land);
	} else if (mode == 1) {
		// Violet: muted lilac land, glowing blue rivers along the noise ridges.
		float n = fbm3(p);
		col = mix(land_b.rgb, land_a.rgb, smoothstep(0.36, 0.70, n));
		float r = fbm3(p * 0.85 + 31.0);
		float ridge = 1.0 - abs(r * 2.0 - 1.0);
		// Thin rivers: the ridge band has to be narrow AND the pattern high-frequency, or the
		// "rivers" come out as neon amoebas covering a quarter of the disc.
		float river = smoothstep(0.94, 0.995, ridge);
		col = mix(col, accent.rgb * 0.42, river * 0.62);
		em = accent.rgb * river * accent_glow;
	} else if (mode == 2) {
		// Chrome: a grid of flat plates with glowing seams (rotated so it is not axis aligned).
		vec3 q = vec3(dot(p, vec3(0.80, 0.36, -0.48)), dot(p, vec3(-0.30, 0.92, 0.24)), dot(p, vec3(0.52, 0.14, 0.84)));
		q *= 1.15;
		// Warp the grid so the plates are irregular panels, not a wireframe globe.
		q += vec3(fbm3(p * 1.3), fbm3(p * 1.3 + 7.0), fbm3(p * 1.3 + 19.0)) * 0.55;
		vec3 cell = floor(q);
		vec3 f = q - cell;
		float plate = hash13(cell);
		col = mix(land_b.rgb, land_a.rgb, plate);
		float e = min(min(min(f.x, 1.0 - f.x), min(f.y, 1.0 - f.y)), min(f.z, 1.0 - f.z));
		float seam = smoothstep(0.016, 0.003, e);
		col = mix(col, accent.rgb * 0.30, seam * 0.45);
		em = accent.rgb * seam * accent_glow;
		rough = 0.52;
	} else if (mode == 4) {
		// Flats: a dry salt pan pocked with round pools. Two fields, deliberately at different
		// frequencies: a broad crust mottle for the pan, and a lower-frequency bowl field whose
		// low ground IS the pool. The pale ring is the salt crust the shallow water leaves behind
		// as it retreats, and it is what makes each pool read as a bowl and not as a blue dot.
		float n = fbm3(p * 1.35);
		float b = fbm3(p * 1.05 + 19.0);
		vec3 pan = mix(land_a.rgb, land_b.rgb, smoothstep(0.44, 0.68, n));
		float pool = 1.0 - smoothstep(sea_level - 0.025, sea_level + 0.015, b);
		float ring = smoothstep(sea_level - 0.005, sea_level + 0.030, b)
			* (1.0 - smoothstep(sea_level + 0.055, sea_level + 0.105, b));
		col = mix(pan, low_color.rgb, ring * 0.80);
		// Capped at 0.7 toward sea_deep on purpose: these are 40-70 cm mirror pools you can see the
		// floor of, and taking them all the way to the deep tone punched black holes in the disc.
		col = mix(col, mix(sea_color.rgb, sea_deep.rgb, pool * 0.7), pool);
		// The pools are mirror-still; the pan is gritty crust.
		rough = mix(0.94, 0.22, pool);
	} else if (mode == 5) {
		// Chalk: the world cut into concentric terraces - the map-scale twin of the real
		// terrace_bank contour rings. Quantise one height field into steps, alternate the tread
		// tone so neighbouring shelves separate, and paint a thin band at every step boundary in
		// low_color for the riser faces.
		// DELIBERATELY NOT fbm3. Its upper octaves shatter a contour line into speckle: a first
		// pass at 4 octaves and 13 steps rendered Grig as a mottled ball with no rings visible at
		// all. Grig's real terrain is ~1.9 noise cycles around the whole world, so this is one
		// dominant smooth octave with a light second one for interest, and 7 steps.
		float h = vnoise3(p) * 0.82 + vnoise3(p * 2.1 + 7.0) * 0.18;
		float f = h * 7.0;
		float tread = floor(f);
		float band = f - tread;
		col = mix(land_a.rgb, land_b.rgb, mod(tread, 2.0) * 0.5);
		col *= mix(0.90, 1.10, clamp(h * 1.5 - 0.25, 0.0, 1.0));
		float edge = min(band, 1.0 - band);
		float riser = 1.0 - smoothstep(0.06, 0.14, edge);
		col = mix(col, low_color.rgb, riser * 0.80);
		rough = 0.90;
	} else if (mode == 6) {
		// Frost: an ice world read by LATITUDE. Every other mode here is isotropic 3D noise, so
		// "poles" is the one structural cue none of them can say - bright caps over a darker
		// fractured belt, which is what keeps Vela from reading as Grig's bone-white ball in a
		// cooler tint. Kept identical to src/shaders/env_globe.gdshader mode 6 so the world in
		// another planet's sky is the world on the map.
		float cap = smoothstep(0.44, 0.80, abs(obj_dir.y));
		float n = fbm3(p * 1.5);
		col = mix(land_b.rgb, land_a.rgb, smoothstep(0.40, 0.66, n));
		// Melt ponds in the low ground of the belt, never on the caps.
		float melt = 1.0 - smoothstep(sea_level - 0.030, sea_level + 0.020, n);
		col = mix(col, mix(sea_color.rgb, sea_deep.rgb, melt * 0.75), melt * (1.0 - cap) * 0.85);
		// Fracture veins: the SAME ridge construction as mode 1's rivers, deliberately inverted -
		// thin and DARK instead of thin and glowing, so the two never read as the same world.
		float r = fbm3(p * 0.95 + 43.0);
		float ridge = 1.0 - abs(r * 2.0 - 1.0);
		float crack = smoothstep(0.90, 0.99, ridge);
		col = mix(col, sea_deep.rgb, crack * 0.50);
		col = mix(col, low_color.rgb, cap * 0.90);
		// The Long Array: a sparse scatter of station lights on the belt, never on the ice cap.
		float lights = smoothstep(0.955, 0.988, hash13(floor(obj_dir * 11.0))) * (1.0 - cap);
		em = accent.rgb * lights * accent_glow;
		// Wet ice reads specular; the frost cap and the crust do not.
		rough = mix(0.86, 0.28, melt) + cap * 0.06;
	} else {
		// Plaza: cream tiles and lawn patches with a scatter of warm lit windows.
		// Cream plaza tiles with broad green lawns; the town lights are real meshes (space_globe.gd),
		// not a scatter, so the hub reads as one bright settlement instead of confetti.
		float n = fbm3(p * 1.15);
		col = mix(low_color.rgb, land_a.rgb, smoothstep(0.40, 0.60, n));
		col = mix(col, land_b.rgb, smoothstep(0.64, 0.84, n) * 0.65);
	}

	ALBEDO = col;
	ROUGHNESS = rough;
	METALLIC = 0.0;
	// Lights belong to the night side: fade the accent in as the surface turns away from the sun.
	float night_side = 1.0 - smoothstep(-0.18, 0.28, dot(normalize(world_normal), normalize(sun_dir)));
	EMISSION = em * mix(0.30, 1.0, night_side);
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float lit = smoothstep(-ramp_softness, ramp_softness, ndl) * ATTENUATION;
	vec3 shadow_col = ALBEDO * mix(vec3(1.0), shade_tint.rgb, shade_strength);
	vec3 diffuse = mix(shadow_col * shade_floor, ALBEDO, lit);
	DIFFUSE_LIGHT += diffuse * LIGHT_COLOR / PI;

	// Thin atmosphere rim on the lit limb.
	float rim = 1.0 - max(dot(NORMAL, VIEW), 0.0);
	rim = pow(rim, 3.5) * rim_strength * smoothstep(0.02, 0.55, ndl);
	SPECULAR_LIGHT += rim * rim_color.rgb * LIGHT_COLOR / PI;
}
