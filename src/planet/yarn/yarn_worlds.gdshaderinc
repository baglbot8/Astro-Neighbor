// YARN WORLDS - builder B's helpers for the planet grounds, on top of the shared
// res://src/style/yarn/yarn_lite.gdshaderinc (include that FIRST: these call yl_tap / yl_lod / yl_hash21).
//
// Everything here is ALU plus at most ONE yl_tap (one textureLod of yarn_stitch_tex) per call. No loops,
// no screen or depth reads. Callers branch on `astro_yarn` so the plain game runs its old code.

// Pixel footprint on the surface, metres. Call in uniform control flow (derivatives).
float yw_fp(vec3 wp) {
	return max(length(dFdx(wp)), length(dFdy(wp)));
}

// ------------------------------------------------------------------------------------------------
// GRANNY SQUARE (the plaza tiles). p = metres from the square's centre on the ground chart, hs = the
// square's half size (to the join), fp = footprint. Four rounds of double-crochet clusters worked out
// from a magic ring: each side is clusters of three tall posts with a chain-space hole between them,
// the holes of one round sitting over the clusters of the round below, and a chain-space hole at
// every corner. Returns:
//   x  value multiply (stitch occlusion + holes), normalised so the square keeps its mean value
//   yz tilt of the normal in chart (u, v) units
//   w  round index 0..3 (the caller dyes each round)
const float YW_GR_ROUNDS = 3.0;
const float YW_GR_HOLE = 0.50;      // value inside a chain-space (the under-layer showing through)
const float YW_GR_HOLE_FRAC = 0.13; // share of the square that is hole (gaps + corners + ring), measured

vec4 yw_granny(vec2 p, float hs, float fp, vec2 cell) {
	float rw = hs / YW_GR_ROUNDS;           // round height (one dc tall)
	float sw = rw * 0.55;                    // one post's width
	vec2 ap = abs(p);
	bool sx = ap.x >= ap.y;
	float r = max(ap.x, ap.y);
	vec2 sg = vec2(p.x < 0.0 ? -1.0 : 1.0, p.y < 0.0 ? -1.0 : 1.0);
	// "along" runs round the square, continuous across each side.
	float along = sx ? p.y * sg.x : -p.x * sg.y;
	float k = min(floor(r / rw), YW_GR_ROUNDS - 1.0);
	float fr = r / rw - k;
	// Posts stand out from the centre: rows run along the side, columns run outward.
	vec2 q = vec2(along / sw, r / rw) + vec2(yl_hash21(cell) * 8.0, 0.0);
	vec4 t = yl_tap(q, yl_lod(fp, sw));
	// Cluster / chain-space rhythm: 3 posts then a round 1-post opening; each round shifted 2 posts so
	// its openings sit over the clusters of the round below.
	float m = fract((along / sw + k * 2.0 + 0.5) / 4.0);
	vec2 dg = vec2((m - 0.875) * 4.0 / 0.46, (fr - 0.5) / 0.34);
	float gap = 1.0 - smoothstep(0.75, 1.05, length(dg));
	// Corner chain-space on the diagonal (rounds 1+), and the magic ring's hole in the middle.
	vec2 dc = vec2((ap.x - ap.y) * 0.7071 / (0.55 * sw), (fr - 0.5) / 0.34);
	float corner = (1.0 - smoothstep(0.75, 1.05, length(dc))) * step(0.5, k);
	float ring = 1.0 - smoothstep(0.20 * rw, 0.32 * rw, r);
	float hole = max(max(gap, corner), ring);
	// The posts' heads: a darker line at each round's top edge where the next round is worked in.
	float head = smoothstep(0.80, 0.98, fr) * 0.18;
	// Fade the holes to their mean once a post is under ~half a pixel.
	float near_f = 1.0 - smoothstep(0.35, 0.80, fp / sw);
	float ao = mix(1.0, mix(t.x * (1.0 - head), YW_GR_HOLE, hole), near_f);
	ao /= mix(1.0, 1.0 - YW_GR_HOLE_FRAC * (1.0 - YW_GR_HOLE) - 0.03, near_f);
	vec2 au = sx ? vec2(0.0, sg.x) : vec2(-sg.y, 0.0);
	vec2 ar = sx ? vec2(sg.x, 0.0) : vec2(0.0, sg.y);
	vec2 tilt = (au * t.y + ar * t.z) * (1.0 - hole) * 0.9;
	return vec4(ao, tilt, k);
}

// ------------------------------------------------------------------------------------------------
// JOIN: the raised chain of slip stitches that joins two squares or panels (the same chain yl_ground
// draws on its seams). d = metres from the seam's centre line, s = metres along it. Returns the
// value multiply (mean ~1 across the seam's width at a distance).
float yw_join(float d, float s, float fp) {
	float link = fract(s / 0.055) - 0.5;
	float across = d / 0.040;
	float chain = sqrt(max(1.0 - (link * link) / 0.20 - across * across, 0.0));
	float jlod = 1.0 - smoothstep(0.012, 0.03, fp);
	return mix(1.0, mix(0.70, 1.10, smoothstep(0.0, 0.5, chain)), jlod);
}

// ------------------------------------------------------------------------------------------------
// PANEL ROWS: a square of plain single crochet worked in straight rows (Bolt's plates). p in metres,
// `turn` 0/1 swaps the row direction (alternate panels, like a patchwork). Stitch size `w` x `h`.
// Returns x = value multiply, yz = tilt in chart (u, v), w = row coordinate (in rows, for threads).
vec4 yw_rows(vec2 p, float turn, float w, float h, float fp, vec2 cell) {
	vec2 a = turn < 0.5 ? p : vec2(p.y, -p.x);
	vec2 q = a / vec2(w, h) + vec2(yl_hash21(cell), yl_hash21(cell + 3.3)) * 7.0;
	vec4 t = yl_tap(q, yl_lod(fp, h));
	vec2 tl = turn < 0.5 ? t.yz : vec2(-t.z, t.y);
	return vec4(t.x, tl, q.y);
}
