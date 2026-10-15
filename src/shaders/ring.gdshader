// Planetary ring band: soft concentric bands with grain, lit by the sun, dimming to navy at night.
// Double sided, unlit, transparent. Mesh is a flat annulus with UV.x = normalized radius.
shader_type spatial;
render_mode cull_disabled, unshaded, depth_draw_opaque, blend_mix, fog_disabled;

#include "res://src/shaders/aces_inverse.gdshaderinc"
#include "res://src/shaders/planet_common.gdshaderinc"
// YARNLITE: a crocheted band (concentric rounds of stitches) when the astro_yarn global is set
// (src/style/yarn/yarn_lite.gdshaderinc). Plain game otherwise, line for line.
#include "res://src/style/yarn/yarn_lite.gdshaderinc"

uniform vec3 ring_color : source_color = vec3(1.0, 0.81, 0.54);
uniform vec3 ring_shade : source_color = vec3(0.65, 0.5, 0.55);
uniform vec3 sun_dir = vec3(0.0, 1.0, 0.0);
uniform float night : hint_range(0.0, 1.0) = 0.0;
uniform vec3 night_tint : source_color = vec3(0.42, 0.47, 0.82);
uniform float opacity : hint_range(0.0, 1.0) = 0.98;
uniform float tonemap_white = 6.0;
uniform float display_cap : hint_range(0.3, 1.0) = 0.85;
// WEB PARITY: THE WRITE TRANSFER (planet_common.gdshaderinc lines 5-104). Compatibility leaves
// `source_color` uniforms sRGB-encoded and then sRGB-decodes the ALBEDO write, so the mix() chain
// below ran in display space on the phone. The ring is the widest single object in bolt's and
// vela's sky: masked to the sky dome, bolt scored MAE 7.72 / p95 43 against Forward+ with the ring
// still unconverted while the six ringless worlds sat at MAE 1.9-3.2 / p95 5-17 — the ring WAS
// bolt's dome error.
// ONE LIMIT, and it is not a shader bug: this material is blend_mix, and Forward+ blends it into a
// linear HDR buffer before tonemapping while Compatibility blends it in sRGB-encoded display space
// after. Where ALPHA is near 1 (the A-ring and the inner band, a = shape*fine*opacity*grain ~ 0.85
// upward) the destination barely participates and the fix is exact; the faint outer wisp and the
// band edges keep a blend-space error no per-shader constant can remove. Same class as the
// additive shaders left alone this round — see the report.
global uniform float astro_compat;

varying vec3 world_normal;

// YARNLITE ring: rounds across the band, and the inner radius in band widths (28 m / (39 - 28) m,
// planet_ring.gd's authored ring; the sky bodies' rings are close) for the stitch count per round.
const float YL_RING_ROWS = 14.0;
const float YL_RING_INNER = 2.55;

float hash11(float p) {
	p = fract(p * 0.1031);
	p *= p + 33.33;
	return fract(p * p * 2.0);
}

void fragment() {
	float r = UV.x;
	// Saturn-like structure: broad inner band, dark Cassini-style gap, bright outer A-ring, faint outer edge.
	float fine = 0.86 + 0.14 * sin(r * 46.0 + sin(r * 9.0) * 3.0);
	float inner_band = smoothstep(0.0, 0.06, r) * (1.0 - smoothstep(0.42, 0.5, r));
	float a_ring = smoothstep(0.54, 0.6, r) * (1.0 - smoothstep(0.82, 0.9, r));
	float outer_wisp = smoothstep(0.9, 0.93, r) * (1.0 - smoothstep(0.95, 1.0, r)) * 0.5;
	float shape = max(max(inner_band * 0.95, a_ring), outer_wisp);
	float grain = 0.94 + 0.06 * hash11(floor(r * 260.0) + floor(UV.y * 1100.0) * 3.1);
	float a = shape * fine * opacity * grain;
	// lit face toward the sun, warm highlight on the A-ring, deeper tone on the inner band.
	// The lit/unlit spread is deliberately shallow: an edge-on ring must still read as a solid band.
	vec3 n = normalize(world_normal);
	float facing = abs(dot(n, sun_dir));
	vec3 c_ring = pc_in(ring_color);
	vec3 base = mix(c_ring * 0.86, c_ring, a_ring);
	base = mix(base, vec3(1.0, 0.97, 0.9), a_ring * 0.3);
	vec3 col = mix(pc_in(ring_shade), base, 0.55 + 0.45 * facing);
	col = mix(col, pc_in(night_tint) * 0.85, night * 0.8);
	if (astro_yarn > 0.5) {
		// YARNLITE (1 read). Row q.y = the round; q.x = stitches round it. Each round's count is a
		// whole number of 8-stitch tiles so the 0/1 seam of UV.y lands on a tile edge, and the jump in
		// count between rounds falls in the row gap of the stitch. The mip level comes from the
		// CONTINUOUS count, so that jump does not pull a line of the blurriest mip.
		float circ = 6.2831853 * (YL_RING_INNER + r) * YL_RING_ROWS * (YL_H / YL_W);
		float row = floor(r * YL_RING_ROWS);
		float n_row = max(round(6.2831853 * (YL_RING_INNER + (row + 0.5) / YL_RING_ROWS) * YL_RING_ROWS
			* (YL_H / YL_W) / YL_TILE), 1.0) * YL_TILE;
		vec2 qc = vec2(UV.y * circ, r * YL_RING_ROWS);
		float lod = log2(max(max(length(dFdx(qc)), length(dFdy(qc))) * YL_TEXELS, 1e-4)) + YL_LOD_BIAS;
		vec4 t = yl_tap(vec2(UV.y * n_row, qc.y), lod);
		// Occlusion, and a fixed soft light from the outer edge on the stitch relief (the ring is
		// unshaded; the tilt averages to zero, so the band keeps its brightness at a distance).
		col *= t.x * (1.0 + 0.22 * t.z);
	}
	ALBEDO = pc_out(aces_inverse(cap_display(col, display_cap), tonemap_white));
	ALPHA = clamp(a, 0.0, 1.0);
}

void vertex() {
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}
