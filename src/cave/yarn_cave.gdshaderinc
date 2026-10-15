// CROCHET for the cave (builder C): helpers on top of src/style/yarn/yarn_lite.gdshaderinc, which
// must be included BEFORE this file. ALU plus 1-3 reads of the shared stitch tile (never more than the
// rock's own 3 triplanar reads that the plain look spends).

const float YC_W = 0.28;             // chunky yarn: stitch width on the cave walls, metres
const float YC_H = 0.21;
const vec3 YC_LIGHT = vec3(-0.30, 0.52, 0.80);   // relief light, view space (a lamp near the camera)

// Triplanar chart blend, sharp (pow 8) so most pixels read ONE chart. n is the flat model-space normal.
vec3 yc_weights(vec3 n) {
	vec3 w = abs(n);
	w *= w;
	w *= w;
	w *= w;
	return w / max(w.x + w.y + w.z, 1e-5);
}

struct YcStone {
	float ao;
	vec3 tilt;    // model-space tangent tilt of the normal
	float fibre;
};

// Stitch rows run along the walls (horizontal strata), concentric on the floor and roof.
YcStone yc_stone_sz(vec3 P, vec3 n, float lod, vec2 size) {
	YcStone s;
	vec3 w = yc_weights(n);
	vec2 inv = 1.0 / size;
	float ao = 0.0;
	float fibre = 0.0;
	vec3 tilt = vec3(0.0);
	float ws = 0.0;
	if (w.x > 0.01) {
		vec4 t = yl_tap(vec2(P.z, P.y) * inv + vec2(3.7, 1.3), lod);
		ao += t.x * w.x; fibre += t.w * w.x;
		tilt += (vec3(0.0, 0.0, t.y) + vec3(0.0, t.z, 0.0)) * w.x;
		ws += w.x;
	}
	if (w.y > 0.01) {
		vec4 t = yl_tap(vec2(P.x, P.z) * inv + vec2(9.1, 5.3), lod);
		ao += t.x * w.y; fibre += t.w * w.y;
		tilt += (vec3(t.y, 0.0, 0.0) + vec3(0.0, 0.0, t.z)) * w.y;
		ws += w.y;
	}
	if (w.z > 0.01) {
		vec4 t = yl_tap(vec2(P.x, P.y) * inv + vec2(1.9, 7.7), lod);
		ao += t.x * w.z; fibre += t.w * w.z;
		tilt += (vec3(t.y, 0.0, 0.0) + vec3(0.0, t.z, 0.0)) * w.z;
		ws += w.z;
	}
	float k = 1.0 / max(ws, 1e-5);
	s.ao = ao * k;
	s.fibre = fibre * k;
	s.tilt = tilt * k;
	s.tilt -= n * dot(s.tilt, n);
	return s;
}

YcStone yc_stone(vec3 P, vec3 n, float lod) {
	return yc_stone_sz(P, n, lod, vec2(YC_W, YC_H));
}

// The stitch relief as a brightness multiply: the cave is unshaded, so the stitch normal is lit by one
// fixed lamp near the camera (slope term only, it averages to 1 over a stitch).
float yc_relief(vec3 n_view, vec3 tilt_view) {
	vec3 nb = normalize(n_view + tilt_view);
	return yl_relief_light(nb, n_view, normalize(YC_LIGHT));
}
