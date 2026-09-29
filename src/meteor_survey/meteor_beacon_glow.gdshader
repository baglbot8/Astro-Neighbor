shader_type spatial;
// THE TARGET BEACON'S AMBER LIGHT (builder METEORPOL, 2026-09-28). Two shapes (`shape`):
//   0  a camera-facing glow on a QuadMesh: a solid amber disc, and a soft halo and four short star points round
//      it at partial opacity that pulse. The send-off's beacons on the rock (FinaleLaunch._build_beacons, via
//      MeteorProps.beacon_glow) and the survey beacon's lamp (MeteorProps.beacon).
//   1  a surface faded like meteor_fx's fade_mode 1 (toward the top of a cylinder, UV.y 0 at the top) with soft
//      sides, opacity `halo`, pulsing: the survey beacon's beam.
//   2  a plain surface at opacity `halo`, pulsing: the survey beacon's ring.
//
// WHY NOT ADDITIVE. Both used to be additive (the shared star sprite; meteor_fx), and both read near-white:
// in the send-off the amber was added ON TOP of the lit blue-lavender rock, and a sum can only gain blue
// (1560x720 Compatibility frame at shot t = 9.5 s: 919 of 928 bright pixels near-white, 0 amber); in the survey
// Compatibility sRGB-encodes each additive layer before summing, which flattens the channel ratios, and a
// sphere or torus adds itself 2-4 times (lamp measured (228,215,184) cream even at a third of the old energy).
// So this one MIXES: amber over amber stays amber however many layers, and it covers what is behind it.
// The colour is picked as
// the colour to SEE and handed back through the exact inverse of each step after it: the environment's 1D
// colour grade (`grade_inverse`, the last step; at night it lifts blue to 0.20 and more, which first turned the
// disc peach, measured (212,163,126)), sRGB, then Godot's ACES fit (aces_inverse.gdshaderinc, as deco_glow
// does), with the web-parity wraps (planet_common recipe). Not inverted: the environment's small contrast and
// saturation adjustment (1.04 / ~1.08), which only push the amber a touch further out.
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

#include "res://src/shaders/aces_inverse.gdshaderinc"
#include "res://src/shaders/planet_common.gdshaderinc"
global uniform float astro_compat;
// The night factor the environment grades with (environment.gd sets it with `_update_grade(_night)`).
global uniform float astro_night;

// The beacon colour ON SCREEN (MeteorProps.BEACON, #f0a64a).
uniform vec4 tint : source_color = vec4(0.941, 0.651, 0.290, 1.0);
// Must match Environment.tonemap_white (src/world/environment.gd TONEMAP_WHITE).
uniform float tonemap_white = 6.0;
// Radius of the solid disc, as a fraction of the quad's half-size.
uniform float core = 0.34;
// Opacity of the halo at the disc's edge (it falls to 0 at the quad's edge) and of the star points.
uniform float halo = 0.6;
uniform float points = 0.7;
uniform float blink_amount : hint_range(0.0, 1.0) = 0.45;
uniform float blink_speed = 2.4;
uniform int shape = 0;
uniform float fade_power = 1.6;

// MUST MATCH src/world/environment.gd GRADE_OFFSETS / GRADE_DAY / GRADE_NIGHT: the per-channel grade the
// WorldEnvironment applies last, day and night stops cross-faded by the night factor. Each channel is a
// rising piecewise-linear curve, so its inverse is exact (clamped to the curve's own floor and ceiling).
const vec4 GRADE_OFFSETS = vec4(0.0, 0.25, 0.6, 1.0);
const vec3 GRADE_DAY_0 = vec3(0.020, 0.012, 0.045);
const vec3 GRADE_DAY_1 = vec3(0.205, 0.195, 0.228);
const vec3 GRADE_DAY_2 = vec3(0.655, 0.648, 0.656);
const vec3 GRADE_DAY_3 = vec3(0.945, 0.932, 0.900);
const vec3 GRADE_NIGHT_0 = vec3(0.115, 0.105, 0.200);
const vec3 GRADE_NIGHT_1 = vec3(0.300, 0.385, 0.428);
const vec3 GRADE_NIGHT_2 = vec3(0.575, 0.595, 0.652);
const vec3 GRADE_NIGHT_3 = vec3(0.930, 0.930, 0.958);

float grade_inverse_1(float y, vec4 s) {
	y = clamp(y, s.x, s.w);
	if (y <= s.y) {
		return mix(GRADE_OFFSETS.x, GRADE_OFFSETS.y, (y - s.x) / max(s.y - s.x, 1e-5));
	} else if (y <= s.z) {
		return mix(GRADE_OFFSETS.y, GRADE_OFFSETS.z, (y - s.y) / max(s.z - s.y, 1e-5));
	}
	return mix(GRADE_OFFSETS.z, GRADE_OFFSETS.w, (y - s.z) / max(s.w - s.z, 1e-5));
}

// The sRGB value that the grade turns into `display` (sRGB) at night factor `night`.
vec3 grade_inverse(vec3 display, float night) {
	vec3 s0 = mix(GRADE_DAY_0, GRADE_NIGHT_0, night);
	vec3 s1 = mix(GRADE_DAY_1, GRADE_NIGHT_1, night);
	vec3 s2 = mix(GRADE_DAY_2, GRADE_NIGHT_2, night);
	vec3 s3 = mix(GRADE_DAY_3, GRADE_NIGHT_3, night);
	return vec3(
		grade_inverse_1(display.r, vec4(s0.r, s1.r, s2.r, s3.r)),
		grade_inverse_1(display.g, vec4(s0.g, s1.g, s2.g, s3.g)),
		grade_inverse_1(display.b, vec4(s0.b, s1.b, s2.b, s3.b)));
}

void vertex() {
	if (shape == 0) {
		// Camera-facing, keeping the node's scale (the same billboard as star.gdshader).
		MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
		MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(
			vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
			vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
			vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
			vec4(0.0, 0.0, 0.0, 1.0));
		MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
	}
}

void fragment() {
	float blink = 1.0 - blink_amount * 0.5 * (1.0 + sin(TIME * blink_speed));
	// The on-screen sRGB colour (a source_color uniform arrives linear on Forward+, as authored on Compatibility).
	vec3 want = (astro_compat > 0.5) ? tint.rgb : pc_l2s(tint.rgb);
	vec3 pre_grade = grade_inverse(want, clamp(astro_night, 0.0, 1.0));
	ALBEDO = pc_out(aces_inverse(pc_s2l(pre_grade), tonemap_white));
	if (shape == 1) {
		float f = pow(clamp(UV.y, 0.0, 1.0), fade_power) * pow(abs(dot(NORMAL, VIEW)), 1.5);
		ALPHA = clamp(halo * f * blink, 0.0, 1.0);
	} else if (shape == 2) {
		ALPHA = clamp(halo * blink, 0.0, 1.0);
	} else {
		vec2 p = (UV - 0.5) * 2.0;
		float d = length(p);
		float disc = 1.0 - smoothstep(core * 0.75, core, d);
		float ring = clamp((1.0 - d) / max(1.0 - core, 0.001), 0.0, 1.0);
		float glow = ring * ring * halo;
		float ax = abs(p.x);
		float ay = abs(p.y);
		float star = (exp(-ax * 9.0) * exp(-ay * 2.2) + exp(-ay * 9.0) * exp(-ax * 2.2)) * smoothstep(1.0, 0.2, d) * points;
		// The pulse is in the halo and the points only: a blinking disc would let the blue rock through its
		// middle at the trough and the core would read grey-peach, not amber.
		ALPHA = clamp(max(disc, (glow + star) * blink), 0.0, 1.0);
	}
}
