// Soft cartoon exhaust puff for the astronaut's jetpack (docs/STYLE_GUIDE.md R2.8: "Soft cartoon
// puffs from the pack's nozzles — the same painted-puff language as the rocket's exhaust, not a
// particle soup").
//
// Same idea as the rocket's src/rocket/smoke_puff.gdshader, which is the house style for this: a
// camera-facing quad with a soft round falloff and a top-lit gradient, NOT a lit sphere. Lit
// spheres read as a bunch of grey balls, which is precisely the "bubbly" look the style guide
// keeps calling out; overlapping soft quads merge into one painted mass with a clean silhouette
// and no visible ball edges.
//
// It is a separate file rather than a reuse of the rocket's so the two domains stay independent
// (the rocket builder owns theirs), and because this one is driven by a per-instance uniform
// rather than by particle COLOR: the puffs are real MeshInstance3Ds updated in script, so their
// life can be shaped exactly and they can be spawned deterministically for captures.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

uniform vec4 lit_color : source_color = vec4(0.93, 0.91, 0.86, 1.0);
uniform vec4 shade_color : source_color = vec4(0.53, 0.52, 0.60, 1.0);
// Warm tint mixed in near the core of a young puff, so the exhaust reads hot at the nozzle and
// cools as it drifts. Keeps a small amount of the thruster's colour in the plume.
uniform vec4 hot_color : source_color = vec4(1.0, 0.83, 0.55, 1.0);
uniform float edge_softness : hint_range(0.05, 1.0) = 0.62;
uniform float opacity : hint_range(0.0, 1.0) = 1.0;
// 0 = just born (hot, tight), 1 = about to vanish (cool, diffuse). Set per instance.
uniform float age : hint_range(0.0, 1.0) = 0.0;

void vertex() {
	// Camera billboard that keeps the instance's own scale.
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(
		vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
		vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
		vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
		vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float r = length(p);
	float a = smoothstep(1.0, 1.0 - edge_softness, r);
	a *= a;
	// Top-lit: the sun side of a puff is pale, the underside keeps the scene's cool shadow tint.
	float up = clamp(0.58 - p.y * 0.42, 0.0, 1.0);
	vec3 base = mix(shade_color.rgb, lit_color.rgb, up);
	// The core of a fresh puff carries a little of the thruster's warmth; it fades out fast.
	float hot = (1.0 - smoothstep(0.0, 0.55, r)) * (1.0 - smoothstep(0.0, 0.35, age));
	ALBEDO = mix(base, hot_color.rgb, hot * 0.55);
	// Fade in over the first 12 % of life so a puff never pops into existence at full strength.
	float life = smoothstep(0.0, 0.12, age) * (1.0 - smoothstep(0.45, 1.0, age));
	ALPHA = clamp(a * life * opacity, 0.0, 1.0);
}
