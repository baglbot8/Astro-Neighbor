shader_type spatial;
// THE SYSTEM'S PLANETS, HUGE IN THE METEOR'S SKY (docs/STORY_HOME_SPEC.md 9.2; builder METEOR). Unlit and
// out of the fog: each is lit by a fixed direction (the sun's at the start of the survey), with soft
// latitude bands and a thin atmosphere rim, so it reads as a world and not a ball.
render_mode unshaded, fog_disabled;

// CROCHET (2026-10-15, builder C): with the astro_yarn global on each planet is a crocheted ball, 90 stitches round
// its equator (as env_globe's are; 1-3 reads, mostly a far mip). With the global at 0 this shader is exactly what
// it was.
#include "res://src/shaders/planet_common.gdshaderinc"
#include "res://src/style/yarn/yarn_lite.gdshaderinc"
global uniform float astro_compat;

uniform vec3 base_color : source_color = vec3(0.4, 0.6, 0.45);
uniform vec3 band_color : source_color = vec3(0.3, 0.45, 0.35);
uniform vec3 rim_color : source_color = vec3(0.7, 0.8, 0.9);
uniform vec3 light_dir = vec3(0.5, 0.6, 0.3);
uniform float bands = 7.0;
uniform float night_floor = 0.10;

varying vec3 n_obj;
varying vec3 n_world;

void vertex() {
	n_obj = NORMAL;
	n_world = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	float lat = n_obj.y;
	float wob = sin(n_obj.x * 5.0 + n_obj.z * 3.0) * 0.25;
	float b = 0.5 + 0.5 * sin((lat + wob * 0.2) * bands * 3.14159);
	vec3 col = mix(base_color, band_color, smoothstep(0.25, 0.75, b) * 0.6);
	vec3 nwl = normalize(n_world);
	float relief = 1.0;
	if (astro_yarn > 0.5) {
		// A big ball on screen: many small stitches, the gaps only part-dark (mean-preserving: the stitch occlusion
		// averages to 1), and the relief a slope-only term on the lit side so the terminator and the limb are the
		// plain ones (the normal that sets them is left alone).
		// ONE chart (rows round the planet's axis, no cap chart: two charts met in a visible crease), faded out
		// toward the poles where its rows would squeeze. 90 stitches round the equator.
		vec3 yd = normalize(n_obj);
		const float N_ST = 90.0;
		vec2 q = vec2(atan(yd.x, -yd.z) * (N_ST / 6.2831853), asin(clamp(yd.y, -1.0, 1.0)) * (N_ST / 6.2831853) * (YL_W / YL_H));
		// footprint from the continuous direction (the angle wraps), in stitches
		float fq = max(length(dFdx(yd)), length(dFdy(yd))) * (N_ST / 6.2831853);
		vec4 t = yl_tap(q, log2(max(fq * YL_TEXELS, 1e-4)) + YL_LOD_BIAS);
		float amp = 0.5 * (1.0 - smoothstep(0.55, 0.85, abs(yd.y)));
		col = pc_out(pc_in(col) * mix(1.0, t.x, amp));
		vec3 east = normalize(vec3(yd.z, 0.0, -yd.x) + vec3(1e-4, 0.0, 0.0));
		vec3 north = cross(yd, east);
		vec3 nb = normalize(nwl + mat3(MODEL_MATRIX) * (east * t.y + north * t.z) / max(length(MODEL_MATRIX[0].xyz), 1e-5) * amp);
		relief = mix(1.0, yl_relief_light(nb, nwl, normalize(light_dir)), 0.6);
	}
	float ndl = dot(nwl, normalize(light_dir));
	float lit = max(smoothstep(-0.15, 0.6, ndl), night_floor) * relief;
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	ALBEDO = col * lit + rim_color * fres * 0.45 * max(lit, 0.25);
}
