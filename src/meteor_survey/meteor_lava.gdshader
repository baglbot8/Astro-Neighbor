shader_type spatial;
// THE VOLCANO'S LAVA (builder METEOR3, spec 9.6.5: the lava lines "look just like red sticks stuck to the
// mountain"). Laid on the flank as ribbons by MeteorProps._lava_flows_mesh: UV.x across a ribbon (0..1), UV.y
// along it in metres from the rim, COLOR.r the flow's heat (1 fresh at the rim, lower toward the tip).
// Opaque and unshaded (it is its own light; no new light, planet_safari.gd RULES FOR CONTENT), so there is no
// transparent sorting against the plumes. A yellow-orange core, deep red edges, and dark crust breaks that drift
// downhill, so a flow reads as moving liquid, not a painted stick.
render_mode unshaded, cull_disabled, shadows_disabled;

uniform vec3 core : source_color = vec3(1.0, 0.72, 0.28);
uniform vec3 hot : source_color = vec3(1.0, 0.36, 0.14);
uniform vec3 edge : source_color = vec3(0.45, 0.07, 0.06);
uniform vec3 crust : source_color = vec3(0.16, 0.08, 0.09);
uniform float flow_speed = 0.35;

float h1(float n) { return fract(sin(n) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = h1(dot(i, vec2(1.0, 57.0)));
	float b = h1(dot(i + vec2(1.0, 0.0), vec2(1.0, 57.0)));
	float c = h1(dot(i + vec2(0.0, 1.0), vec2(1.0, 57.0)));
	float d = h1(dot(i + vec2(1.0, 1.0), vec2(1.0, 57.0)));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	float across = abs(UV.x - 0.5) * 2.0;          // 0 centre, 1 edge
	float heat = COLOR.r;
	float v = UV.y - TIME * flow_speed;             // crust breaks drift downhill
	float n = vnoise(vec2(UV.x * 3.0, v * 2.6)) * 0.65 + vnoise(vec2(UV.x * 7.0, v * 6.5)) * 0.35;
	// The hot channel: wide at the rim, narrower where the flow has cooled.
	float channel = 1.0 - smoothstep(0.15, 0.55 + 0.25 * heat, across + (n - 0.5) * 0.35);
	vec3 col = mix(edge, hot, smoothstep(0.0, 0.6, channel));
	col = mix(col, core, smoothstep(0.55, 1.0, channel) * (0.45 + 0.55 * heat));
	// Cooled crust plates floating on it, more of them as the flow cools; and a dark crusted rim.
	float plates = smoothstep(0.62 - 0.22 * (1.0 - heat), 0.78 - 0.22 * (1.0 - heat), n);
	col = mix(col, crust, plates * 0.8);
	col = mix(col, crust, smoothstep(0.8, 1.0, across));
	ALBEDO = col;
}
