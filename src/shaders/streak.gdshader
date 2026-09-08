// Shooting-star streak: a quad oriented along the motion (x = travel direction, head at u=1).
// Bright warm head, tapering tail with a sparkly dotted pattern. Additive, unlit, no fog.
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

uniform vec4 head_color : source_color = vec4(1.0, 0.97, 0.85, 1.0);
uniform vec4 tail_color : source_color = vec4(0.65, 0.85, 1.0, 1.0);
uniform float intensity : hint_range(0.0, 10.0) = 3.0;
uniform float fade : hint_range(0.0, 1.0) = 1.0;
uniform float scroll = 0.0;

float hash11(float p) {
	p = fract(p * 0.1031);
	p *= p + 33.33;
	return fract(p * p * 2.0);
}

void fragment() {
	float u = UV.x;
	float v = (UV.y - 0.5) * 2.0;
	float width = mix(0.15, 1.0, pow(u, 1.6));
	float across = smoothstep(width, width * 0.2, abs(v));
	float along = pow(u, 2.2);
	float dots = 0.0;
	float cell = floor(u * 26.0 + scroll);
	float fu = fract(u * 26.0 + scroll);
	float h = hash11(cell);
	float dy = (h - 0.5) * 1.2 * width;
	float dd = length(vec2((fu - 0.5) * 0.5, (v - dy) * 1.5));
	dots = smoothstep(0.32, 0.05, dd) * step(0.35, h) * (0.3 + 0.7 * u);
	float a = (across * along * 0.8 + dots * 0.9) * fade;
	vec3 col = mix(tail_color.rgb, head_color.rgb, along);
	ALBEDO = col * intensity * a;
	ALPHA = clamp(a, 0.0, 1.0);
}
