// Soft volumetric-looking light shaft (the Beacon Tower's sweeping beam).
//
// The mesh is an open lathed cone shell with NO end caps (see beacon_tower.gd), so this shader only
// has to make it fade out instead of stopping in a blunt straight edge:
//   * lengthwise   UV.y goes 0 at the lamp to 1 at the far tip; alpha falls to exactly 0 there.
//   * radially     abs(dot(NORMAL, VIEW)) is ~1 on the part of the shell facing the camera (the
//                  middle of the projected shaft) and ~0 at its projected silhouette, which gives a
//                  bright soft core with feathered sides instead of an opaque slab.
//   * back faces are culled, so the shaft is drawn once, not twice.
// Peak alpha is deliberately tiny (~0.07): a beacon beam is a hint of light in the air, not a wall.
// Intensity follows the `astro_night` global (docs/ARCHITECTURE.md 9.1) so the beam is invisible by
// day without any per-frame GDScript.
shader_type spatial;
render_mode blend_add, depth_draw_never, cull_back, unshaded, shadows_disabled;

global uniform float astro_night;

uniform vec4 beam_color : source_color = vec4(1.0, 0.86, 0.55, 1.0);
uniform float peak_alpha : hint_range(0.0, 0.4) = 0.07;
// Higher = the shaft dies away sooner along its length.
uniform float length_falloff : hint_range(0.5, 6.0) = 1.9;
// Higher = a narrower, more focused core across the shaft.
uniform float radial_falloff : hint_range(0.5, 6.0) = 1.5;
// Fraction of the peak still shown in broad daylight.
uniform float day_floor : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	float along = clamp(UV.y, 0.0, 1.0);
	float len_fade = pow(1.0 - along, length_falloff);
	float ndv = abs(dot(normalize(NORMAL), normalize(VIEW)));
	float radial = pow(ndv, radial_falloff);
	float night = mix(day_floor, 1.0, clamp(astro_night, 0.0, 1.0));
	ALBEDO = beam_color.rgb;
	ALPHA = clamp(peak_alpha * len_fade * radial * night, 0.0, 1.0);
}
