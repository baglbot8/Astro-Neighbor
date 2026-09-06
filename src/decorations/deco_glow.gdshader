// Emissive decoration parts (lamp bulbs, holo panels, console LEDs, plasma).
// One material for every glowing decoration surface: the tint comes from the baked vertex COLOR and
// the intensity from per-instance uniforms, so lamps share a single draw material but each item can
// dim by day, glow at night and blink at its own rate.
//   mi.set_instance_shader_parameter("glow_strength", 2.6)
//   mi.set_instance_shader_parameter("pulse_speed", 2.0)          // 0 = steady
//   mi.set_instance_shader_parameter("pulse_depth", 0.35)         // 0..1 dip amount
//   mi.set_instance_shader_parameter("pulse_mode", 0.0)           // 0 breathe, 1 hard blink
//
// WHY THIS IS DISPLAY-REFERRED (docs/OPEN_ISSUES.md #6)
// The old version emitted `color * strength` straight into the HDR buffer. Anything much over 1.0
// lands on the shoulder of the ACES curve, which desaturates as it brightens, so a red beacon, a
// cyan flame and a violet crystal all resolved to the same hue-free white blob (measured peak
// saturation 0.031 - 0.055 in the real game at 22:30). Instead we pick the colour we want to SEE,
// cap its brightest channel just above the bloom threshold, and run it back through the inverse of
// Godot's ACES fit, so the tonemapper hands back exactly that colour plus a soft halo.
//
// The day/night level comes from the `astro_night` global (docs/ARCHITECTURE.md 9.1), not from a
// GDScript clock poll, so a garden of lit props costs zero script time.
shader_type spatial;
// `ambient_light_disabled`: the ambient/IBL term is applied to ALBEDO outside our light() function
// and is broadly achromatic, so on a lit core it was a grey wash sitting on top of a hue-locked
// emission. A surface that makes its own light does not need the sky's.
render_mode cull_back, depth_draw_opaque, diffuse_lambert, specular_schlick_ggx, ambient_light_disabled;

#include "res://src/shaders/aces_inverse.gdshaderinc"

global uniform float astro_night;

// Must match Environment.tonemap_white (src/world/environment.gd TONEMAP_WHITE).
uniform float tonemap_white = 6.0;
// Fraction of the glow left in broad daylight (astro_night = 0).
uniform float day_floor : hint_range(0.0, 1.0) = 0.2;
uniform float emission_scale : hint_range(0.0, 2.0) = 0.42;
// Brightest LINEAR DISPLAY channel a lit core may reach. This is a uniform scale on all three
// channels, so it sets brightness WITHOUT touching hue or saturation: 0.96 renders as ~0.98 in sRGB
// (clearly "lit"), lands above the environment's 1.15 HDR glow threshold so the core still blooms,
// and keeps the value off the ACES shoulder where the hue would be eaten.
uniform float core_cap : hint_range(0.1, 1.0) = 0.96;
// How far the surface colour is pulled toward white. Anything above ~0.1 desaturates the core.
uniform float albedo_lift : hint_range(0.0, 1.0) = 0.06;
// How much external light (including the item's own lamp) still shades a lit core at night. Keeping
// this low is what stops an OmniLight sitting inside a bulb from washing the bulb out to white.
uniform float night_lit : hint_range(0.0, 1.0) = 0.14;
// Surface albedo multiplier at night. The ambient/IBL term is applied to ALBEDO outside our light()
// function, so a near-white bulb picked up a broad achromatic wash on top of its own emission;
// dimming the albedo leaves the emission (which is hue-locked) in charge after dark.
uniform float night_albedo : hint_range(0.0, 1.0) = 0.25;
uniform vec4 shade_tint : source_color = vec4(0.62, 0.55, 0.85, 1.0);

instance uniform float glow_strength = 2.4;
instance uniform float pulse_speed = 0.0;
instance uniform float pulse_depth = 0.0;
instance uniform float pulse_mode = 0.0;
instance uniform float phase = 0.0;

varying vec3 v_col;

void vertex() {
	v_col = COLOR.rgb;
}

void fragment() {
	float p = 1.0;
	if (pulse_speed > 0.001) {
		float s = sin(TIME * pulse_speed + phase);
		p = pulse_mode < 0.5 ? mix(1.0 - pulse_depth, 1.0, 0.5 + 0.5 * s) : mix(1.0 - pulse_depth, 1.0, step(0.35, s));
	}
	float night = clamp(astro_night, 0.0, 1.0);
	float lvl = mix(day_floor, 1.0, night) * p;
	ALBEDO = mix(v_col, vec3(1.0), albedo_lift * lvl) * mix(1.0, night_albedo, night);
	// The colour we want on screen, then the HDR value that survives the tonemapper as that colour.
	vec3 target = cap_display(v_col * glow_strength * emission_scale, core_cap) * lvl;
	EMISSION = aces_inverse(target, tonemap_white);
	ROUGHNESS = 0.5;
	METALLIC = 0.0;
	SPECULAR = 0.15;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float lit = smoothstep(-0.4, 0.4, ndl) * ATTENUATION;
	vec3 shadow_col = ALBEDO * mix(vec3(1.0), shade_tint.rgb, 0.18);
	float k = mix(1.0, night_lit, clamp(astro_night, 0.0, 1.0));
	DIFFUSE_LIGHT += mix(shadow_col * 0.7, ALBEDO, lit) * LIGHT_COLOR * k / PI;
}
