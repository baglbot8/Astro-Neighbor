shader_type spatial;
// THE SURVEY'S LIGHT EFFECTS (builder METEOR): the crack's molten split, the soft plume that marks an
// unmarked crack from afar, the beacon's lamp, ring and beam. One shader for all of them (one compile),
// additive and unlit, so no new light is ever added (planet_safari.gd RULES FOR CONTENT). fade_mode:
// 0 none, 1 fades toward the top of a cylinder (UV.y 0 at the top), 2 a soft radial disc on a quad.
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, fog_disabled;

uniform vec3 tint : source_color = vec3(1.0, 0.55, 0.25);
uniform float energy = 1.0;
uniform float pulse_speed = 1.5;
uniform float pulse_amount = 0.2;
uniform int fade_mode = 0;
uniform float fade_power = 1.6;

void fragment() {
	float a = 1.0;
	if (fade_mode == 1) {
		a = pow(clamp(UV.y, 0.0, 1.0), fade_power);
		// Soft sides: bright where the surface faces the eye, gone at the silhouette.
		a *= pow(abs(dot(NORMAL, VIEW)), 1.5);
	} else if (fade_mode == 2) {
		float r = length(UV - vec2(0.5)) * 2.0;
		a = pow(clamp(1.0 - r, 0.0, 1.0), fade_power);
	}
	float pulse = 1.0 - pulse_amount + pulse_amount * sin(TIME * pulse_speed);
	ALBEDO = tint * energy * a * pulse;
}
