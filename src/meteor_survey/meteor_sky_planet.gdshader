shader_type spatial;
// THE SYSTEM'S PLANETS, HUGE IN THE METEOR'S SKY (docs/STORY_HOME_SPEC.md 9.2; builder METEOR). Unlit and
// out of the fog: each is lit by a fixed direction (the sun's at the start of the survey), with soft
// latitude bands and a thin atmosphere rim, so it reads as a world and not a ball.
render_mode unshaded, fog_disabled;

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
	float ndl = dot(normalize(n_world), normalize(light_dir));
	float lit = max(smoothstep(-0.15, 0.6, ndl), night_floor);
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	ALBEDO = col * lit + rim_color * fres * 0.45 * max(lit, 0.25);
}
