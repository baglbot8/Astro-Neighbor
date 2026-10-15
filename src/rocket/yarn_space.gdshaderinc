// YARN SPACE - builder D's crochet helpers for space, the sky safari, the story beats and the title.
// Include AFTER res://src/style/yarn/yarn_lite.gdshaderinc (it uses YL_* constants, yl_tap,
// yl_hash21 and the yarn_star_tex global). Every caller branches on `astro_yarn > 0.5`, so with the
// switch off none of this runs and each shader is the code it was before.
//
// BUDGET (CROCHET_SPEC "Phone budget"): yd_sky_fp = 2 reads, yd_ball = 1 (knit + one embroidered star), the same
// as yl_sky. yd_strand, yd_tassel, yd_chain, yd_felt_halo are ALU only. No loops anywhere.

// ------------------------------------------------------------------------------------------------
// CANVAS-SAFE TAP. yl_tap() relies on the sampler repeating. A spatial or sky shader's global
// sampler does; a CANVAS ITEM's does not - it takes the item's texture_repeat, which is off - so
// in the safari glass every coordinate outside one tile clamped to the tile's edge and drew flat
// smears and lines (measured: stitches showed only in the one quadrant where q/8 was in 0..1).
// This is yl_tap() with the wrap done by hand. textureLod has an explicit level, so fract()'s jump
// costs no derivative; bilinear at the tile edge clamps instead of wrapping, which is one texel at
// a stitch crevice (tile edges are stitch edges) - not visible.
vec4 yd_tap(vec2 q, float lod) {
	q.x += q.y * YL_SKEW;
	vec4 t = textureLod(yarn_stitch_tex, fract(q * (1.0 / YL_TILE)), lod);
	vec2 n = t.gb * 2.0 - 1.0;
	return vec4(t.r * YL_AO_GAIN, n.x, n.y + YL_SKEW * 1.333 * n.x, t.a);
}

// ------------------------------------------------------------------------------------------------
// SKY with the footprint passed in and a stitch scale. yl_sky() takes its own derivatives, which is
// right for a sky shader but not for the safari glass (a canvas item whose sky is drawn inside a
// branch: derivatives there read neighbours that took another path). The glass measures `px_rad`
// at the top of fragment(), in uniform control flow, and hands it in as `fp` (radians per pixel).
// `k` scales the stitch's angular size: 1.0 is the planet sky's stitch; the raised 7-degree scope
// passes field_half / 28 deg so a stitch keeps its PIXEL size when the glass magnifies, the same
// exact inversion the glass already applies to its stars. `star_k` shrinks each embroidered star
// inside its block (1 = the planet sky's size). Body otherwise identical to yl_sky().
//
// THE GLASS'S STARS (round 2, critic): the safari glass is a photo game and its stars are clutter
// around the sights, so there they are small - about the plain glass's biggest point star with its
// flare, 0.38 of the sky's stitch star - and capped below the sights' light: 0.5 of the thread
// colour, a peak near the plain glass's bright stars instead of near white.
const float YD_GLASS_STAR_K = 0.38;
const float YD_GLASS_STAR_GAIN = 0.5;
YlSky yd_sky_fp(vec3 d, float fp, float k, float star_k) {
	YlSky o;
	vec3 ad = abs(d);
	vec2 fc;
	float fid;
	if (ad.x >= ad.y && ad.x >= ad.z) { fc = vec2(d.z * sign(d.x), d.y) / ad.x; fid = 1.0 + step(d.x, 0.0); }
	else if (ad.y >= ad.z) { fc = vec2(d.x, d.z * sign(d.y)) / ad.y; fid = 3.0 + step(d.y, 0.0); }
	else { fc = vec2(-d.x * sign(d.z), d.y) / ad.z; fid = 5.0 + step(d.z, 0.0); }
	vec2 local = atan(fc);
	float sw = YL_SKY_W * k;
	vec2 q = local / vec2(sw, sw * (YL_H / YL_W)) + vec2(fid * 17.0, fid * 5.0);
	vec4 t = yd_tap(q, yl_lod(fp, sw * (YL_H / YL_W)));
	o.ao = mix(1.0, t.x, 1.0 - YL_SKY_FLAT);
	vec2 sq = local / (3.0 * sw);
	vec2 sc = floor(sq) + vec2(fid * 91.0, fid * 37.0);
	vec2 sf = (fract(sq) - 0.5) * 3.0;
	float big = yl_hash21(sc + 4.4);
	float rad = mix(0.45, 1.05, big * big);
	vec2 c = (vec2(yl_hash21(sc + 1.1), yl_hash21(sc + 2.2)) - 0.5) * (3.0 - 2.0 * rad);
	vec2 p = (sf - c) / (rad * star_k);
	float ang = yl_hash21(sc + 5.5) * 0.8;
	float ca = cos(ang);
	float sa = sin(ang);
	p = vec2(ca * p.x - sa * p.y, sa * p.x + ca * p.y);
	float inside = step(max(abs(p.x), abs(p.y)), 1.0) * step(0.88, yl_hash21(sc));
	float slod = log2(max(fp / (sw * rad * star_k * 2.0) * 64.0, 1e-4));
	vec4 st = textureLod(yarn_star_tex, p * 0.5 + 0.5, slod);
	o.star = st.r * inside;
	o.star_v = st.g * 1.2;
	o.star_h = yl_hash21(sc + 6.6);
	return o;
}

// The embroidered star's thread colour: the planet sky's two tints (sky.gdshader's yarn block), so a
// star stitched in space is the same thread as one stitched over a planet.
vec3 yd_star_col(YlSky ys) {
	return mix(vec3(0.80, 0.88, 1.0), vec3(1.0, 0.90, 0.76), ys.star_h) * 0.9 * ys.star_v;
}

// ------------------------------------------------------------------------------------------------
// STRAND: one length of plied yarn (a streak, a speed line, a mote's trail). `along` 0..1 down the
// strand, `across` -1..1 over it, `n_ply` twists along it. Returns (coverage, shade): coverage cuts
// the strand into a RUNNING STITCH (dashes with gaps) when `dash` > 0; shade is the round profile of
// the yarn and its twist, averaging ~1 so an additive streak keeps its energy.
vec2 yd_strand(float along, float across, float n_ply, float dash) {
	float a = clamp(abs(across), 0.0, 1.0);
	float round_ = sqrt(max(1.0 - a * a, 0.0));
	float tw = fract(along * n_ply + across * 0.35);
	float ply = 0.80 + 0.40 * smoothstep(0.0, 0.25, tw) * (1.0 - smoothstep(0.55, 0.95, tw));
	float shade = mix(0.75, 1.10, round_) * ply;
	float cov = 1.0;
	if (dash > 0.0) {
		float s = fract(along * dash);
		// stitch on the top 70% of each repeat, a gap where the thread goes under the cloth
		cov = smoothstep(0.0, 0.08, s) * (1.0 - smoothstep(0.62, 0.72, s));
	}
	return vec2(cov, shade);
}

// ------------------------------------------------------------------------------------------------
// TASSEL: a rocket flame as a bundle of glowing yarn ends. `u` round the lathe (0..1), `v` down the
// plume (0 throat .. 1 tip). Returns (cut, shade): cut = 1 where this strand has already ended (the
// tassel's ragged tip, caller discards); shade averages ~1 so the plume keeps its glow.
vec2 yd_tassel(float u, float v, float strands) {
	float s = u * strands;
	float id = floor(s);
	float f = fract(s) - 0.5;
	// the strand's own round profile across it, and its twist along it
	float round_ = 1.0 - f * f * 4.0;
	float tw = fract(v * 9.0 + f * 0.8 + yl_hash21(vec2(id, 2.0)));
	float ply = 0.82 + 0.30 * smoothstep(0.0, 0.3, tw) * (1.0 - smoothstep(0.6, 1.0, tw));
	float shade = mix(0.78, 1.12, round_) * ply;
	// each strand is cut to its own length; the ends untwist into a little fluff
	float len = mix(0.80, 1.02, yl_hash21(vec2(id, 7.0)));
	float cut = step(len, v);
	shade *= 1.0 - 0.25 * smoothstep(len - 0.10, len, v);
	return vec2(cut, shade);
}

// ------------------------------------------------------------------------------------------------
// CHAIN: a ring as a crochet chain band. `ang` round the ring (radians), `rn` 0..1 across the band
// (inner .. outer edge), `links` chain links round the whole ring (whole number: no seam). Returns
// the shade multiply (mean ~1): oval links in two rows, dark where the loops cross.
float yd_chain(float ang, float rn, float links) {
	float s = ang / 6.2831853 * links;
	float row = rn * 2.0;
	float ri = floor(clamp(row, 0.0, 1.999));
	float rf = fract(row) - 0.5;
	float lf = fract(s + ri * 0.5) - 0.5;
	// an oval loop: bright on the yarn, dark in the hole and on the crossing
	float e = (lf * lf) / 0.16 + (rf * rf) / 0.18;
	float loop_ = smoothstep(0.30, 0.55, e) * (1.0 - smoothstep(0.85, 1.05, e));
	float edge = smoothstep(0.0, 0.08, rn) * (1.0 - smoothstep(0.92, 1.0, rn));
	return mix(0.62, 1.16, loop_) * mix(0.8, 1.0, edge);
}

// ------------------------------------------------------------------------------------------------
// FELT HALO: a glow sprite or lantern halo as a soft felt disc with a blanket-stitch rim. `q` the
// sprite's -1..1 coordinate. Returns a multiply with mean ~1 over the disc: a faint fibre grain
// inside and short radial stitches round the edge, so the light keeps its brightness and colour.
float yd_felt(vec2 q) {
	float r = length(q);
	float th = atan(q.y, q.x);
	float fib = yl_hash21(floor(q * 18.0)) * 0.5 + yl_hash21(floor(q * 31.0) + 3.0) * 0.5;
	float grain = mix(0.90, 1.08, fib);
	// blanket stitch: 16 short radial bars round 0.62..0.82 of the radius
	float bar = smoothstep(0.30, 0.0, abs(fract(th / 6.2831853 * 16.0) - 0.5) * 2.0 - 0.0)
		* smoothstep(0.58, 0.64, r) * (1.0 - smoothstep(0.78, 0.84, r));
	return grain * (1.0 + 0.35 * bar);
}

// ------------------------------------------------------------------------------------------------
// Compatibility write transfer for shaders that do not include planet_common (the space sky, the
// title sky): the exact sRGB encode, applied only when `compat` > 0.5. A sky that writes COLOR raw
// under Compatibility is sRGB-decoded after fragment(), so a multiply or a thread colour meant in
// linear has to be pre-encoded to land where the planet sky's pc_out() puts it.
vec3 yd_enc(vec3 q, float compat) {
	q = max(q, vec3(0.0));
	vec3 e = mix(q * 12.92, 1.055 * pow(q, vec3(1.0 / 2.4)) - vec3(0.055), step(vec3(0.0031308), q));
	return compat > 0.5 ? e : q;
}

// ------------------------------------------------------------------------------------------------
// BALL: a world drawn as a flat disc (the safari glass) shaded as a crocheted ball worked in rounds.
// `q` is the offset from the disc's centre and `R` its radius, both in glass units; `px` is glass
// units per pixel. One read. Returns the multiply (mean ~1; the stored occlusion averages to the
// plain colour in the far mips, as on every hooked surface).
const float YD_BALL_ROUND = 34.0;    // stitches round the equator of a world in the glass
float yd_ball(vec2 q, float R, float px, float rounds) {
	vec2 nq = q / R;
	float nz = sqrt(max(1.0 - dot(nq, nq), 0.0));
	float k = rounds / 6.2831853;
	vec2 st = vec2(atan(nq.x, max(nz, 1e-4)), asin(clamp(nq.y, -1.0, 1.0)) * (YL_W / YL_H)) * k;
	float fp = k * px / R / max(nz, 0.2);
	float lod = log2(max(fp * YL_TEXELS, 1e-4)) + YL_LOD_BIAS;
	vec4 t = yd_tap(st, lod);
	// the limb picks up the yarn's fuzz, as yl_fuzz does on a lit object; and the stitch fades out
	// once it is too small to read (the middle mips keep only the row lines - see yd_felt_sight)
	// 70% of the stitch depth: the world's own land and terminator are a navigation cue (forward /
	// back on the lane) and must still read through the yarn
	// (and shallower on a magnified ball: 0.70 at the sky's 34 rounds, 0.50 at the raised scope's 68)
	float depth = mix(0.70, 0.50, clamp(rounds / YD_BALL_ROUND - 1.0, 0.0, 1.0));
	return mix(1.0, t.x, depth * (1.0 - smoothstep(1.4, 2.6, lod))) * (1.0 + yl_fuzz(nz, t.w));
}
