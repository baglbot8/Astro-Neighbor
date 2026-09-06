// Helmet visor / window glass: tinted, glossy, fresnel rim, sky reflection via the environment
// radiance, plus a soft painted highlight blob. Use through MaterialLib.visor().
// The painted highlight is a fake specular, not a light source, so it fades out with the
// `astro_night` global (see docs/ARCHITECTURE.md 9.1) — otherwise it blooms into a white dot on
// the helmet in every night frame.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, specular_schlick_ggx;

global uniform float astro_night;

uniform vec4 tint : source_color = vec4(0.44, 0.76, 1.0, 0.4);
uniform vec4 rim_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float fresnel_power : hint_range(0.5, 8.0) = 3.0;
uniform float rim_strength : hint_range(0.0, 2.0) = 0.7;
uniform float highlight_strength : hint_range(0.0, 3.0) = 0.9;
uniform vec2 highlight_offset = vec2(-0.35, 0.4);
uniform float gloss : hint_range(0.0, 1.0) = 0.92;
// How much of the painted highlight / rim survives at full night (astro_night = 1).
uniform float night_dim : hint_range(0.0, 1.0) = 0.2;

void fragment() {
	float ndv = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float fres = pow(1.0 - ndv, fresnel_power);
	// painted highlight: a soft blob in view space toward the upper-left of the visor
	vec3 vn = NORMAL;
	vec2 hp = vn.xy - highlight_offset;
	float hl = smoothstep(0.55, 0.15, length(hp)) * highlight_strength * step(0.0, vn.z);
	float dim = mix(1.0, night_dim, clamp(astro_night, 0.0, 1.0));
	ALBEDO = tint.rgb;
	ALPHA = clamp(tint.a + fres * 0.45 + hl * 0.35, 0.0, 1.0);
	ROUGHNESS = 1.0 - gloss;
	METALLIC = 0.35;
	SPECULAR = 0.9;
	EMISSION = (rim_color.rgb * fres * rim_strength * 0.3 + vec3(1.0) * hl * 0.45) * dim;
}
