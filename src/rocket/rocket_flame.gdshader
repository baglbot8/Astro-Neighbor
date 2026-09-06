// PAINTED CARTOON EXHAUST for the rocket (docs/STYLE_GUIDE.md R2.6 + "Shape language").
//
// The plume used to be three nested lathe shells: an orange body with a hot core and a blue collar
// tucked INSIDE it. Opaque geometry nested inside opaque geometry is invisible, so all anyone ever
// saw was the outer shell — a flat, hard-edged, uniformly pale-yellow teardrop with a red bloom
// round it (integration critic: "the exhaust is a paper cutout"). Bloom then washed the one visible
// colour out to cream, which is why it read as paper rather than as fire.
//
// So the structure is PAINTED ON one silhouette instead of built out of shells:
//   * an axial ramp from a hot blue-white throat, through white-gold, into the saturated orange
//     body, to a deep orange-red at the tip — the classic cartoon flame reading, bottom to top;
//   * a view-facing term, so the middle of the plume is hotter than its edges and the silhouette
//     rolls off into a deeper, more saturated rim instead of sitting there as one flat fill. This
//     is what gives it volume;
//   * a crisp painted outline right at the limb (no alpha feathering — the shape stays hard-edged
//     the way the guide asks, it just is not one colour any more);
//   * `emission_cap`, borrowed from toon_soft.gdshader, rescaling rather than clipping so the hot
//     end keeps its hue instead of blowing to white;
//   * life: a travelling ripple along the ramp and a rolling lick on the silhouette itself, so a
//     solid mesh still reads as fire without a particle soup.
//
// `intensity` is the one knob the game turns: ~1.0 over a daylit planet, ~0.35 in space, where an
// additive-bright plume against a starfield blooms into a red disc twice the size of the rocket.
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, depth_draw_opaque;

// Ramp stops, throat -> tip.
uniform vec4 core_color : source_color = vec4(0.78, 0.90, 1.00, 1.0);
uniform vec4 hot_color : source_color = vec4(1.00, 0.95, 0.80, 1.0);
uniform vec4 body_color : source_color = vec4(1.00, 0.68, 0.22, 1.0);
uniform vec4 deep_color : source_color = vec4(0.94, 0.44, 0.11, 1.0);
uniform vec4 tip_color : source_color = vec4(0.80, 0.23, 0.09, 1.0);
// Where each stop lands along the plume (0 = throat, 1 = tip).
uniform float stop_core : hint_range(0.0, 1.0) = 0.07;
uniform float stop_hot : hint_range(0.0, 1.0) = 0.19;
uniform float stop_body : hint_range(0.0, 1.0) = 0.55;

// Overall brightness. 1.0 = the planet-side burn; the space map runs it near 0.35.
uniform float intensity : hint_range(0.0, 3.0) = 1.0;
// Emission gain at the throat and at the tip, before `intensity`.
uniform float gain_hot : hint_range(0.2, 4.0) = 1.90;
uniform float gain_tip : hint_range(0.2, 4.0) = 0.95;
// Hue-preserving ceiling: the brightest channel is rescaled to this, never clipped.
uniform float emission_cap : hint_range(0.2, 6.0) = 2.3;
// How much hotter the part of the plume facing the camera is than its limb.
uniform float face_gain : hint_range(0.0, 1.0) = 0.42;
// Depth and width of the painted outline at the silhouette.
uniform float edge_strength : hint_range(0.0, 1.0) = 0.62;
uniform float edge_width : hint_range(0.05, 0.9) = 0.42;
uniform vec4 edge_color : source_color = vec4(0.68, 0.17, 0.06, 1.0);
// Motion.
uniform float ripple : hint_range(0.0, 0.3) = 0.055;
uniform float lick : hint_range(0.0, 0.25) = 0.045;
uniform float speed : hint_range(0.0, 20.0) = 7.0;

varying float axial;

float band(float t) {
	// Ripple travels tip-ward and dies out at both ends so the throat stays welded to the nozzle.
	float w = sin(t * 12.0 - TIME * speed) * 0.6 + sin(t * 21.0 - TIME * speed * 1.7 + 1.3) * 0.4;
	t += w * ripple * smoothstep(0.0, 0.22, t) * (1.0 - smoothstep(0.72, 1.0, t));
	return clamp(t, 0.0, 1.0);
}

void vertex() {
	// The lathe's UV.y runs 1 at the throat (profile end) to 0 at the tip (profile start).
	axial = clamp(1.0 - UV.y, 0.0, 1.0);
	// Rolling licks on the silhouette: an integer number of lobes around the axis, so the seam at
	// UV.x 0/1 stays continuous.
	float a = UV.x * 6.2831853;
	float l = sin(a * 5.0 + TIME * speed * 0.9) * 0.55 + sin(a * 3.0 - TIME * speed * 1.4) * 0.45;
	float env = smoothstep(0.06, 0.42, axial) * (1.0 - smoothstep(0.70, 0.99, axial));
	VERTEX += normalize(NORMAL) * (l * lick * env);
}

void fragment() {
	float t = band(axial);
	vec3 c;
	if (t < stop_core) {
		c = mix(core_color.rgb, hot_color.rgb, t / max(stop_core, 0.001));
	} else if (t < stop_hot) {
		c = mix(hot_color.rgb, body_color.rgb, (t - stop_core) / max(stop_hot - stop_core, 0.001));
	} else if (t < stop_body) {
		c = mix(body_color.rgb, deep_color.rgb, (t - stop_hot) / max(stop_body - stop_hot, 0.001));
	} else {
		c = mix(deep_color.rgb, tip_color.rgb, (t - stop_body) / max(1.0 - stop_body, 0.001));
	}
	// 1 head-on, 0 at the limb. abs() so back faces (cull_disabled, for the open throat) match.
	float face = abs(dot(normalize(NORMAL), normalize(VIEW)));
	float rim = 1.0 - smoothstep(0.0, edge_width, face);
	c = mix(c, edge_color.rgb, rim * edge_strength);
	float gain = mix(gain_tip, gain_hot, 1.0 - t) * mix(1.0 - face_gain, 1.0, face) * intensity;
	vec3 em = c * gain;
	float m = max(max(em.r, em.g), em.b);
	if (m > emission_cap) {
		em *= emission_cap / m;
	}
	// `unshaded` writes ALBEDO straight to the HDR frame buffer and IGNORES EMISSION entirely, so
	// the colour goes there. Values over 1.0 still cross the glow threshold and bloom.
	ALBEDO = em;
}
