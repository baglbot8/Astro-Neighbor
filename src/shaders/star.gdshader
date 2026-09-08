// Soft additive glow sprite, camera-billboarded. Used for fireflies, sparkles, the head of a
// shooting star and stardust twinkles. Works on GPUParticles3D (uses COLOR + INSTANCE_CUSTOM.z
// as a per-particle blink phase) and on plain QuadMesh instances.
shader_type spatial;

// WEB PARITY: DELIBERATELY NOT CONVERTED, AND THE REASON IS THE BLEND MODE, NOT AN OVERSIGHT.
// The sky, the sky bodies and the ring were converted this round with pc_in()/pc_out() from
// planet_common.gdshaderinc; this shader was measured against that scheme and left alone.
// `blend_add` is why. An additive fragment does not stand on its own: Forward+ adds its
// contribution into the LINEAR HDR buffer and tonemaps the sum,
//     result = l2s(tonemap(background_linear + source_linear))
// while Compatibility tonemaps and sRGB-encodes each fragment and adds in DISPLAY space,
//     result = clamp(background_display + l2s(tonemap(s2l(ALBEDO))))
// Those are not the same function of the same inputs, and no per-shader transform of ALBEDO turns
// one into the other — the destination is inside the tonemap on one renderer and outside it on the
// other. It is the same class of defect as the shadow pass in src/world/environment.gd, which had
// to be fixed at the renderer level (`_no_cast_shadows`) rather than in a shader.
// pc_out() here would make the source term correct in isolation and the composite no more correct
// than it is now, and nothing in the seven showcase frames or the title scene renders enough of
// this material to measure whether that helped or hurt. Applying it would be a guess.
// IF YOU PICK THIS UP: build a frame that is mostly this material (a night world with the
// fireflies cranked, or a shooting-star scrub), score it per-region the way the sky was scored, and
// expect the answer to be a renderer-level change to how the additive pass composites — not a
// constant in this file. THE IRON RULE STILL HOLDS: if it needs a gain to pass, it has failed.
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec4 tint : source_color = vec4(1.0, 0.95, 0.6, 1.0);
uniform float intensity : hint_range(0.0, 10.0) = 2.0;
uniform float softness : hint_range(0.0, 1.0) = 0.55;
uniform float core : hint_range(0.0, 1.0) = 0.35;
uniform float blink_speed = 3.0;
uniform float blink_amount : hint_range(0.0, 1.0) = 0.0;
uniform float points : hint_range(0.0, 1.0) = 0.0;
uniform float fade : hint_range(0.0, 1.0) = 1.0;

varying vec4 pcolor;
varying float phase;

void vertex() {
	pcolor = COLOR;
	phase = INSTANCE_CUSTOM.z;
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
	float d = length(p);
	float glow = smoothstep(1.0, softness, d);
	glow *= glow;
	float c = smoothstep(core, 0.0, d);
	float star = 0.0;
	if (points > 0.001) {
		float ax = abs(p.x);
		float ay = abs(p.y);
		star = (exp(-ax * 9.0) * exp(-ay * 2.2) + exp(-ay * 9.0) * exp(-ax * 2.2)) * smoothstep(1.0, 0.2, d);
		star *= points;
	}
	float blink = 1.0 - blink_amount * 0.5 * (1.0 + sin(TIME * blink_speed + phase * 6.2831853));
	float a = (glow * 0.6 + c + star) * blink * pcolor.a * fade;
	ALBEDO = tint.rgb * pcolor.rgb * intensity * a;
	ALPHA = clamp(a, 0.0, 1.0);
}
