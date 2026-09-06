// Inverse of Godot's ACES (fitted) tonemapper (tonemap.glsl, Godot 4.x) so that painted,
// display-referred colors (sky, cloud puffs, ring) come out of the tonemapper exactly as designed.
// `tonemap_white` must match Environment.tonemap_white. Feed linear display colors in 0..1.
// Bright inputs map to large HDR values: keep the max channel <= ~0.85 to stay under the glow threshold.
vec3 aces_inverse(vec3 display, float tonemap_white) {
	const float bias = 1.8;
	const float ka = 0.0245786;
	const float kb = 0.000090537;
	const float kc = 0.983729;
	const float kd = 0.432951;
	const float ke = 0.238081;
	const mat3 rgb_to_rrt = mat3(
		vec3(0.59719 * bias, 0.35458 * bias, 0.04823 * bias),
		vec3(0.07600 * bias, 0.90834 * bias, 0.01566 * bias),
		vec3(0.02840 * bias, 0.13383 * bias, 0.83777 * bias));
	const mat3 odt_to_rgb = mat3(
		vec3(1.60475, -0.53108, -0.07367),
		vec3(-0.10208, 1.10813, -0.00605),
		vec3(-0.00327, -0.07276, 1.07602));
	float w = tonemap_white * bias;
	float white_t = (w * (w + ka) - kb) / (w * (kc * w + kd) + ke);
	vec3 y = max(display, vec3(0.0)) * white_t;
	y = max(y * inverse(odt_to_rgb), vec3(0.0));
	vec3 a = y * kc - 1.0;
	vec3 b = y * kd - ka;
	vec3 c = y * ke + kb;
	vec3 disc = max(b * b - 4.0 * a * c, vec3(0.0));
	vec3 x = (-b - sqrt(disc)) / (2.0 * a);
	x = max(x, vec3(0.0)) * inverse(rgb_to_rrt);
	return max(x, vec3(0.0));
}

// Scales a display color so its brightest channel is at most `cap` (keeps hue, avoids bloom).
vec3 cap_display(vec3 c, float cap) {
	float m = max(c.r, max(c.g, c.b));
	return (m > cap) ? c * (cap / m) : c;
}
