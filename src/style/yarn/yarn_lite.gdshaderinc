// YARNLITE - crochet / amigurumi look at a phone budget. Shared by every hooked game shader.
//
// Switch: the global `astro_yarn` ([shader_globals], 0 = plain game; YarnLite.DEFAULT_ON sets it at
// boot). Every hook is `if (astro_yarn > 0.5) { ... }` placed so that with the switch at 0 each hooked
// shader runs exactly the code it ran before.
//
// COST, PER PIXEL OF A HOOKED SURFACE (vs the promo's 8-tap supersampled height field + a 64-tap
// full-screen fuzz pass): no loops, no screen or depth texture, no extra pass.
//   characters / props / plants / sky planets: 1-3 textureLod reads of one 128x128 RGBA8 tile (one
//     per cylindrical-triplanar chart whose weight is above 1%; most pixels need 1, seams 2-3);
//   ground blanket: 1 read;  sky: 2 reads (knit + one embroidered star);  jet puffs: 0 reads.
// The stitch pattern was baked ONCE at start-up by src/style/yarn/yarn_lite.gd. Mipmaps replace the
// promo's supersampling as the anti-shimmer: the level is chosen from the footprint of the pixel ON
// THE SURFACE (derivatives of the metric position, which are continuous), so the round's seam - where
// the angle wraps - does not pull a 1-pixel line of the blurriest mip like hardware selection would.
// The relief is a NORMAL stored in the texture: it averages to flat in the far mips, and the stored
// occlusion averages to exactly the plain colour (YL_AO_GAIN), so distant stitches fade to the game.

global uniform float astro_yarn;
global uniform sampler2D yarn_stitch_tex;
global uniform sampler2D yarn_star_tex;

const float YL_W = 0.056;            // stitch width / height, metres (characters and props)
const float YL_H = 0.042;
const float YL_TILE = 8.0;           // stitches per texture tile (YarnLite.TILE)
const float YL_TEXELS = 16.0;        // texels per stitch (YarnLite.TEXELS)
const float YL_AO_GAIN = 255.0 / 178.0;   // 1 / YarnLite.AO_STORE
const float YL_SKEW = 0.25;          // columns lean 1/4 stitch per row (amigurumi worked in a spiral)
const float YL_LOD_BIAS = 0.35;      // a little softer than the hardware pick: the crevices are crisp
const float YL_GROUND_W = 0.12;      // the blanket's bigger stitches
const float YL_GROUND_H = 0.095;
const float YL_GROUND_FLAT = 0.5;    // blanket relief taken this far toward flat (background)
const float YL_GROUND_TONE = 0.5;    // how far each square is dyed toward a game grass tone
const float YL_SKY_W = 0.017;        // ~1 degree per sky stitch
const float YL_SKY_FLAT = 0.725;

// Mip level for a surface whose pixel covers `fp_m` metres and whose smaller stitch side is `st_m`.
float yl_lod(float fp_m, float st_m) {
	return log2(max(fp_m / st_m * YL_TEXELS, 1e-4)) + YL_LOD_BIAS;
}

// One read. q in stitches (x along the row, y up the column). Returns (ao, tilt_u, tilt_v, fibre):
// ao is normalised to mean 1, tilt is the stitch normal's tangent part in (u, v).
vec4 yl_tap(vec2 q, float lod) {
	q.x += q.y * YL_SKEW;
	vec4 t = textureLod(yarn_stitch_tex, q * (1.0 / YL_TILE), lod);
	vec2 n = t.gb * 2.0 - 1.0;
	// The tile is baked in the sheared frame; d/dv of the sheared pattern picks up SKEW * d/du
	// (ratio of the two relief factors 0.55 / 0.4125 = 1.333).
	return vec4(t.r * YL_AO_GAIN, n.x, n.y + YL_SKEW * 1.333 * n.x, t.a);
}

// ------------------------------------------------------------------------------------------------
// OBJECT mapping for characters, props, plants and sky planets: "cylindrical triplanar" round the
// object's own Y axis (the promo's charts): the side (rows round the part like amigurumi rounds), the
// caps (concentric rounds, the magic ring on top of a head) and radial fins. P is metres in the
// object's frame (object position times its scale), n the normal in that frame.
struct YlObj {
	float ao;     // occlusion multiply (mean 1)
	vec3 tilt;    // tangent tilt of the normal, metric object space
	float nz;     // weight left on the flat normal
	float fibre;  // 0..1 fibre noise (0.5 in the far mips)
};

YlObj yl_object(vec3 P, vec3 n, float lod) {
	YlObj o;
	float rho = length(P.xz);
	vec3 rh = rho > 1e-5 ? vec3(P.x, 0.0, P.z) / rho : vec3(1.0, 0.0, 0.0);
	vec3 th = vec3(-rh.z, 0.0, rh.x);
	float u = rho * atan(P.x, -P.z);    // the round's start-of-row jog sits at the back (+Z)
	vec3 w = abs(vec3(dot(n, rh), n.y, dot(n, th)));
	w *= w;
	w *= w;
	w *= w;                              // pow 8: sharp chart blend, so most pixels read one chart
	w /= max(w.x + w.y + w.z, 1e-5);
	vec2 inv = vec2(1.0 / YL_W, 1.0 / YL_H);
	vec4 acc = vec4(0.0);
	vec3 tilt = vec3(0.0);
	float ws = 0.0;
	// textureLod has an explicit level, so it is legal (and skipped) inside these branches.
	if (w.x > 0.01) {
		vec4 t = yl_tap(vec2(u, P.y) * inv, lod);
		acc += vec4(t.x, 0.0, 0.0, t.w) * w.x;
		tilt += (th * t.y + vec3(0.0, 1.0, 0.0) * t.z) * w.x;
		ws += w.x;
	}
	if (w.y > 0.01) {
		vec4 t = yl_tap(vec2(u, rho) * inv, lod);
		acc += vec4(t.x, 0.0, 0.0, t.w) * w.y;
		tilt += (th * t.y + rh * t.z) * w.y;
		ws += w.y;
	}
	if (w.z > 0.01) {
		vec4 t = yl_tap(vec2(rho, P.y) * inv, lod);
		acc += vec4(t.x, 0.0, 0.0, t.w) * w.z;
		tilt += (rh * t.y + vec3(0.0, 1.0, 0.0) * t.z) * w.z;
		ws += w.z;
	}
	float k = 1.0 / max(ws, 1e-5);
	o.ao = acc.x * k;
	o.fibre = acc.w * k;
	o.tilt = tilt * k;
	o.tilt -= n * dot(o.tilt, n);
	o.nz = sqrt(max(1.0 - dot(o.tilt, o.tilt), 0.0));
	return o;
}

// Metric object position, normal and mip level from the raw object position / normal and the
// model matrix. Derivatives here, in uniform control flow of the caller's `if (astro_yarn ...)`.
vec3 yl_scale(mat4 model) {
	return max(vec3(length(model[0].xyz), length(model[1].xyz), length(model[2].xyz)), vec3(1e-5));
}

float yl_obj_lod(vec3 P) {
	float fp = max(length(dFdx(P)), length(dFdy(P)));
	return yl_lod(fp, YL_H);
}

// Silhouette fuzz: a soft lift of the yarn colour where the surface turns away, broken by the
// fibre noise (the promo's yarn_fuzz without its 3D noise; the promo's fuzz PASS is dropped).
float yl_fuzz(float ndv, float fibre) {
	return smoothstep(0.45, 1.0, 1.0 - clamp(abs(ndv), 0.0, 1.0)) * (0.55 + 0.45 * fibre) * 0.19;
}

// Relief light for the toon light() functions (promo yarn_relief_light): their ramp is flat on the lit
// side, which would hide the stitches. Only the SLOPE term of Lambert is added relative to the flat
// N.L, so it averages to zero over a stitch and the surface keeps the game's brightness.
float yl_relief_light(vec3 n, vec3 n_flat, vec3 l) {
	float slope = dot(n, l) - dot(n, n_flat) * dot(n_flat, l);
	return clamp(1.0 + slope / max(dot(n_flat, l), 0.25), 0.5, 1.5);
}

// ------------------------------------------------------------------------------------------------
// GROUND: a crocheted blanket of joined squares on the cube-sphere chart (pc_cube_uv's `uv_m`).
// Square size is chosen so a whole number of squares fills each cube face.
struct YlGround {
	float ao;
	vec3 tilt_w;    // world-space tangent tilt of the normal
	float nz;
	float tone;     // 0, 1, 2: which of the game's three grass tones this square takes
	float tone_amt; // how much of that tone shows here (0 on the join seams)
	float fibre;
};

float yl_hash21(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

YlGround yl_ground(vec3 dir, vec2 uv_m, float R, vec3 wp) {
	YlGround g;
	// Recover the face from pc_cube_uv's offsets (0, 1000, 2000) and the dominant axis's sign.
	vec3 ad = abs(dir);
	float off;
	float sgn;
	vec3 au;
	vec3 av;
	if (ad.x >= ad.y && ad.x >= ad.z) { off = 0.0; sgn = sign(dir.x); au = vec3(0.0, 0.0, sgn); av = vec3(0.0, 1.0, 0.0); }
	else if (ad.y >= ad.z) { off = 1000.0; sgn = sign(dir.y); au = vec3(1.0, 0.0, 0.0); av = vec3(0.0, 0.0, sgn); }
	else { off = 2000.0; sgn = sign(dir.z); au = vec3(-sgn, 0.0, 0.0); av = vec3(0.0, 1.0, 0.0); }
	float face = R * 1.5707963;
	vec2 local = uv_m - vec2(off, off * 0.5) + vec2(face * 0.5);
	float nsq = max(round(face / 2.1), 1.0);
	float sq = face / nsq;
	vec2 sid = floor(local / sq);
	vec2 sf = local / sq - sid;
	sid += vec2(off * 0.037 + sgn * 5.0, off * 0.011 + sgn * 3.0);
	float parity = mod(sid.x + sid.y, 2.0);
	// Stitch rows across x in even squares, across y in odd ones (a patchwork of panels).
	vec2 sp = (sf - 0.5) * sq;
	vec2 a = parity < 0.5 ? sp : vec2(sp.y, -sp.x);
	vec2 q = a / vec2(YL_GROUND_W, YL_GROUND_H) + vec2(yl_hash21(sid), yl_hash21(sid + 3.3)) * 7.0;
	float fp = max(length(dFdx(wp)), length(dFdy(wp)));
	vec4 t = yl_tap(q, yl_lod(fp, YL_GROUND_H));
	vec2 tq = t.yz;
	vec2 tl = parity < 0.5 ? tq : vec2(-tq.y, tq.x);
	// Join seam: a raised chain of slip stitches; the edge scallops with the edge stitches.
	vec2 wav = 0.025 * sin(6.2831853 * vec2(sp.y, sp.x) / YL_GROUND_W);
	vec2 de = min(sf, 1.0 - sf) * sq + wav;
	float dmin = min(de.x, de.y);
	float along = de.x < de.y ? sp.y : sp.x;
	float link = fract(along / 0.07) - 0.5;
	float across = dmin / 0.05;
	float chain = sqrt(max(1.0 - (link * link) / 0.16 - across * across, 0.0));
	float jlod = 1.0 - smoothstep(0.012, 0.03, fp);
	float seam = 1.0 - smoothstep(0.035, 0.06, dmin);
	float ao_seam = mix(1.0, mix(0.42, 1.0, smoothstep(0.0, 0.4, chain)) / 0.832, jlod);
	g.ao = mix(mix(1.0, t.x, 1.0 - YL_GROUND_FLAT), ao_seam, seam);
	// Chart axes projected onto the ground's tangent plane (no derivatives needed).
	vec3 tu = normalize(au - dir * dot(au, dir));
	vec3 tv = normalize(av - dir * dot(av, dir));
	vec2 tlf = tl * (1.0 - seam) * (1.0 - YL_GROUND_FLAT);
	g.tilt_w = tu * tlf.x + tv * tlf.y;
	g.nz = sqrt(max(1.0 - dot(tlf, tlf), 0.0));
	g.tone_amt = YL_GROUND_TONE * smoothstep(0.03, 0.10, dmin);
	g.tone = floor(yl_hash21(sid + 11.7) * 3.0);
	g.fibre = t.w;
	return g;
}

// ------------------------------------------------------------------------------------------------
// SKY: a knitted backdrop on the cube-sphere chart of the WORLD direction (fixed in the sky like the
// game's stars) and embroidered stars from yarn_star_tex, one candidate per 3x3-stitch block.
struct YlSky {
	float ao;
	float star;     // coverage 0..1
	float star_v;   // yarn shading
	float star_h;   // per-star random (tint)
};

YlSky yl_sky(vec3 d) {
	YlSky o;
	vec3 ad = abs(d);
	vec2 fc;
	float fid;
	if (ad.x >= ad.y && ad.x >= ad.z) { fc = vec2(d.z * sign(d.x), d.y) / ad.x; fid = 1.0 + step(d.x, 0.0); }
	else if (ad.y >= ad.z) { fc = vec2(d.x, d.z * sign(d.y)) / ad.y; fid = 3.0 + step(d.y, 0.0); }
	else { fc = vec2(-d.x * sign(d.z), d.y) / ad.z; fid = 5.0 + step(d.z, 0.0); }
	vec2 local = atan(fc);
	float fp = max(length(dFdx(d)), length(dFdy(d)));   // radians per pixel
	vec2 q = local / vec2(YL_SKY_W, YL_SKY_W * (YL_H / YL_W)) + vec2(fid * 17.0, fid * 5.0);
	vec4 t = yl_tap(q, yl_lod(fp, YL_SKY_W * (YL_H / YL_W)));
	o.ao = mix(1.0, t.x, 1.0 - YL_SKY_FLAT);
	// Stars: one candidate per 3x3-stitch block, 12% of blocks.
	vec2 sq = local / (3.0 * YL_SKY_W);
	vec2 sc = floor(sq) + vec2(fid * 91.0, fid * 37.0);
	vec2 sf = (fract(sq) - 0.5) * 3.0;          // stitch-width units, -1.5..1.5
	float big = yl_hash21(sc + 4.4);
	float rad = mix(0.45, 1.05, big * big);
	vec2 c = (vec2(yl_hash21(sc + 1.1), yl_hash21(sc + 2.2)) - 0.5) * (3.0 - 2.0 * rad);
	vec2 p = (sf - c) / rad;
	float ang = yl_hash21(sc + 5.5) * 0.8;
	float ca = cos(ang);
	float sa = sin(ang);
	p = vec2(ca * p.x - sa * p.y, sa * p.x + ca * p.y);
	float inside = step(max(abs(p.x), abs(p.y)), 1.0) * step(0.88, yl_hash21(sc));
	// Star texels per pixel: the star spans 2 * rad stitch widths over 64 texels.
	float slod = log2(max(fp / (YL_SKY_W * rad * 2.0) * 64.0, 1e-4));
	vec4 st = textureLod(yarn_star_tex, p * 0.5 + 0.5, slod);
	o.star = st.r * inside;
	o.star_v = st.g * 1.2;
	o.star_h = yl_hash21(sc + 6.6);
	return o;
}

// ------------------------------------------------------------------------------------------------
// POM-POM: a jet puff as a ball of wool (promo yarn_pompom; ALU only). p is the billboard coordinate
// (-1..1); returns (coverage, value multiply).
vec2 yl_pompom(vec2 p) {
	float r = length(p);
	float th = atan(p.y, p.x);
	float fib = yl_hash21(vec2(floor(th * 9.549), 3.0)) * 0.5
		+ yl_hash21(vec2(floor(th * 19.1), 7.0)) * 0.5;
	float edge = 0.80 + 0.18 * fib;
	float px = max(fwidth(r), 0.004);
	float cov = 1.0 - smoothstep(edge - px * 1.5, edge + px * 1.5, r);
	float streak = 0.5 + 0.5 * sin(th * 120.0 + r * 9.0);
	float v = mix(0.86, 1.08, streak * smoothstep(0.15, 0.6, r)) * mix(1.0, 0.82, smoothstep(0.55, 0.95, r));
	return vec2(cov, v);
}

// ------------------------------------------------------------------------------------------------
// TUFTS: grass-tuft blades become chunky plied yarn ends (promo yarn_tuft; ALU only).
// u across the blade (tangential, metres), v metres up it. x = shading multiply, y = 1 to cut away.
vec2 yl_tuft(float u, float v) {
	float s = u / 0.04;
	float lod = 1.0 - smoothstep(0.2, 0.5, max(fwidth(s * 3.0), fwidth(v / 0.022)));
	float tw = fract(s * 1.5 + v / 0.022);
	float band = smoothstep(0.0, 0.18, tw) * (1.0 - smoothstep(0.62, 1.0, tw));
	float tip = smoothstep(0.06, 0.15, v);
	float q = fract(s * 3.0) - 0.5;
	float gap = step(0.5 - 0.22 * tip, abs(q)) * step(0.02, tip) * step(0.5, lod);
	float shade = mix(1.0, mix(0.58, 1.10, band), lod);
	return vec2(shade, gap);
}

// ================================================================================================
// ADDED 2026-10-15 (crochet for the whole game). Nothing above changed.
// ================================================================================================

// ------------------------------------------------------------------------------------------------
// EMBROIDERED STAR STITCH on a sprite: yarn_star_tex (one read) at sprite coordinate sp, where the
// star fills -1..1. Returns coverage * yarn shading (peak ~1.15, mean over the square 0.256);
// 0 outside the square. The mip level comes from the pixel footprint, so a far sparkle fades to a
// soft dot instead of shimmering. Call in uniform control flow (it takes derivatives).
float yl_star_stitch(vec2 sp) {
	float lod = log2(max(max(fwidth(sp.x), fwidth(sp.y)) * 32.0, 1e-4));
	vec4 st = textureLod(yarn_star_tex, sp * 0.5 + 0.5, lod);
	float inside = step(max(abs(sp.x), abs(sp.y)), 1.0);
	return st.r * st.g * 1.2 * inside;
}

// Mean of yl_star_stitch over its square (measured from the baked texture, YarnLite._build_star_texture).
const float YL_STAR_MEAN = 0.2556;

// ------------------------------------------------------------------------------------------------
// FELT HALO: a soft round glow whose rim wobbles gently like the edge of a felt circle. d = distance
// from the centre (0..1 at the quad edge), soft = where the falloff starts (star.gdshader's
// `softness`). Same profile as the plain glow `smoothstep(1, soft, d)^2`. Round 2: the radial fibre
// streaks and the hashed per-sector rim read as a spiky lens-flare sunburst (critic), so the rim is now
// two low sine wobbles (5 and 9 lobes) and the body is smooth. The wobble fades out when the sprite is
// small on screen. ALU only.
float yl_felt(vec2 p, float d, float soft) {
	float th = atan(p.y, p.x);
	float near = 1.0 - smoothstep(0.04, 0.12, fwidth(d));
	float wob = 0.6 * sin(th * 5.0 + 1.3) + 0.4 * sin(th * 9.0 - 0.7);
	float edge = 1.0 + 0.045 * wob * near;
	float g = smoothstep(1.0, soft, d / edge);
	return g * g;
}

// ------------------------------------------------------------------------------------------------
// RUNNING STITCH along a strand: u along it (0..1), v across it (-1..1 = the strand's half width),
// `n` stitches over the length, `scroll` slides them. Each stitch is a plump yarn capsule (f 0.07-0.83
// of its cell, 3/4 of the strand's width) with a twisted ply; returns coverage * shading, whose mean
// over a cell (f 0..1, v -1..1) is YL_RUN_MEAN (measured numerically from these formulas), so a caller
// can keep the plain strand's brightness exactly by scaling with (its own across-profile mean) /
// YL_RUN_MEAN. When a stitch is under ~2 px long it would only alias, so it fades to that mean. ALU only.
const float YL_RUN_MEAN = 0.3141;
float yl_running_stitch(float u, float v, float n, float scroll) {
	float s = u * n + scroll;
	float f = fract(s);
	float px = max(fwidth(s), 1e-4);
	vec2 q = vec2((f - 0.45) / 0.38, v / 0.75);
	float e = dot(q, q);
	float cov = 1.0 - smoothstep(0.7, 1.0, e);
	float ply = 0.5 + 0.5 * cos(6.2831853 * (f * 4.0 + v * 0.8));
	float shade = (sqrt(max(1.0 - e, 0.0)) * 0.5 + 0.5) * (0.8 + 0.3 * ply);
	float far = smoothstep(0.25, 0.5, px);
	return mix(cov * shade, YL_RUN_MEAN, far);
}

// ------------------------------------------------------------------------------------------------
// CHUNKY TUFTS: grass-tuft blades as thick plied yarn ends that still read at the gameplay camera,
// where a tuft is only 10-25 px tall and yl_tuft's 1.3 cm plies are sub-pixel (so it showed nothing).
// One twist band per 5.5 cm (3-4 per blade), a lighter frayed end that splits into fibres up close.
// u across the blade (tangential, metres), v metres up it. x = shading multiply (mean ~1), y = 1 to
// cut away. ALU only.
vec2 yl_tuft_chunky(float u, float v) {
	float s = u / 0.04;
	float tv = v / 0.055;
	float px = max(fwidth(tv), fwidth(s * 0.5));
	float lod = 1.0 - smoothstep(0.35, 0.7, px);
	float tw = fract(tv + s * 0.5);
	// Band profile mean 0.65, so 0.68 + 0.49 * band averages 1.0: the tuft keeps its colour.
	float band = smoothstep(0.0, 0.25, tw) * (1.0 - smoothstep(0.55, 1.0, tw));
	float shade = mix(1.0, 0.68 + 0.49 * band, lod);
	float fray = smoothstep(0.12, 0.16, v);
	float fib = abs(fract(s * 4.0) - 0.5) * 2.0;
	float near = 1.0 - smoothstep(0.08, 0.2, fwidth(s * 4.0));
	float cut = step(0.6, fib) * step(0.5, fray) * step(0.5, near);
	shade *= 1.0 + 0.12 * fray;
	return vec2(shade, cut);
}
