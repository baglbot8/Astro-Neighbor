shader_type canvas_item;
render_mode blend_mix, unshaded;
// SPIKE ROUND 2 (2026-09-20, scratch only). What you see through the telescope.
//
// Everything here is procedural - no texture is sampled. One shader draws all three kinds of sight
// so the phone only ever compiles one material:
//   kind 0  AURORA  four wobbling curtains, ribbed, green at the foot and violet above it
//   kind 1  COMET   a hard core, a coma, a straight ion tail and a wider curved dust tail
//   kind 2  RING    a lit, banded disc with a ring drawn half behind it and half in front
//
// DEFOCUS with no extra taps: `blur` widens every falloff and divides every peak. A real lens does
// exactly that - it spreads the same light over a bigger disc - so one uniform buys the whole
// focus mini-game and costs nothing on WebGL2.
//
// The field of view is a unit circle. `aim` is where the sight sits in it: (0,0) is dead centre,
// length 1.0 is the edge of the tube.
//
// ROUND 2 CHANGES, all from the round-1 review:
//  * mode 0 (the eyepiece) is now TRANSPARENT outside the circle instead of near-black, so the
//    player's own planet, the scope and the horizon stay on screen around the view. Finding 5.
//  * mode 1 (a print) fills the whole square with no vignette and no rim - a photograph, not a
//    view down a tube.
//  * `grain` puts read noise on a short exposure, so a plate pulled early LOOKS pulled early.

uniform int kind : hint_range(0, 2) = 0;
uniform int mode : hint_range(0, 1) = 0;   // 0 = looking through it, 1 = a finished print
uniform float t = 0.0;
uniform vec2 aim = vec2(0.0);
uniform float blur : hint_range(0.0, 1.0) = 0.0;
uniform float grain : hint_range(0.0, 1.0) = 0.0;
uniform vec4 tint_a : source_color = vec4(0.66, 0.49, 0.95, 1.0);
uniform vec4 tint_b : source_color = vec4(0.44, 0.89, 0.71, 1.0);
// 0 = the dead of night, 1 = dawn twilight. R2.1: the stars never go out on these worlds, they
// just sit under a slightly lifted sky, so this only lifts the background and dims stars to 0.55 -
// the same STAR_DAY_SCALE environment.gd uses.
uniform float sky_light : hint_range(0.0, 1.0) = 0.0;
uniform float seed = 1.0;

float h21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7)) + seed) * 43758.5453);
}

void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float r = length(p);
	// Round hole when you are looking through it; the whole square when it is a print.
	if (mode == 0 && r > 1.0) {
		// TRANSPARENT, not black. The 3D world behind this ColorRect is the point.
		COLOR = vec4(0.0);
	} else {
		// ---- background sky (deep space, plus the milky band)
		vec3 sky = mix(vec3(0.026, 0.032, 0.080), vec3(0.150, 0.140, 0.235), sky_light);
		float bandv = (p.y * 0.85 + p.x * 0.40 + 0.30) / 0.52;
		sky += vec3(0.095, 0.092, 0.160) * exp(-bandv * bandv) * (1.0 - 0.45 * sky_light);

		// ---- stars (two grid octaves). Defocus fattens and dims them.
		vec3 stars = vec3(0.0);
		for (int i = 0; i < 2; i++) {
			vec2 gs = p * (7.0 + float(i) * 11.0) + vec2(float(i) * 13.7, float(i) * 5.1);
			vec2 cell = floor(gs);
			vec2 f = fract(gs) - 0.5;
			vec2 o = vec2(h21(cell), h21(cell + 3.3)) - 0.5;
			float m = h21(cell + 7.1);
			float rad = (0.032 + 0.115 * blur) * (0.55 + m);
			float d = length(f - o * 0.72);
			float s = smoothstep(rad, 0.0, d);
			float bright = step(0.615, m) * (0.42 + m) / (1.0 + 7.0 * blur);
			stars += vec3(0.86, 0.89, 1.0) * s * bright;
		}
		stars *= mix(1.0, 0.55, sky_light);

		// ---- the sight
		vec2 q = p - aim;
		vec3 sight = vec3(0.0);
		// how much of the background this sight HIDES. Glows hide nothing; a solid disc hides all.
		float occlude = 0.0;

		if (kind == 0) {
			// AURORA: four curtains, each a gaussian in x wobbling with height, ribbed across.
			// +y is DOWN. A curtain has a hard bright FOOT and a diffuse glow rising above it.
			float a = 0.0;
			for (int i = 0; i < 4; i++) {
				float fi = float(i);
				float xoff = 0.30 * fi - 0.45;
				float wob = 0.17 * sin(q.y * 2.2 + t * (0.40 + 0.09 * fi) + fi * 2.1)
					+ 0.07 * sin(q.y * 4.7 - t * 0.55 + fi * 1.3);
				float dx = q.x - xoff - wob;
				float w = 0.011 + 0.070 * blur;
				float curtain = exp(-dx * dx / w);
				// each curtain's foot sits at its own height and ripples along x, so the row of
				// feet is ragged instead of one flat line across the field
				float fy = 0.14 + 0.055 * fi + 0.085 * sin(q.x * 3.1 + fi * 2.3 + t * 0.3);
				float foot = smoothstep(fy + 0.16 + 0.12 * blur, fy, q.y);
				float top = smoothstep(-0.88, -0.14, q.y);
				float rib = 0.60 + 0.40 * sin(q.x * 22.0 + t * 1.15 + fi * 3.0);
				a += curtain * foot * top * rib * (0.70 + 0.30 * sin(t * 0.50 + fi * 1.9));
			}
			a /= (1.0 + 1.9 * blur);
			vec3 col = mix(tint_a.rgb, tint_b.rgb, smoothstep(-0.28, 0.18, q.y));
			sight = col * a * 1.30;
		} else if (kind == 1) {
			// COMET: ion tail straight away from the sun, dust tail wider and curved behind it.
			vec2 dir = normalize(vec2(-0.80, 0.60));
			float along = dot(q, dir);
			float across = dot(q, vec2(-dir.y, dir.x));
			float fwd = max(along, 0.0);
			float gate = smoothstep(-0.03, 0.02, along);
			float w1 = 0.020 + 0.115 * fwd + 0.095 * blur;
			float ion = exp(-across * across / (w1 * w1)) * exp(-fwd * 1.45) * gate;
			float across2 = across + 0.30 * fwd * fwd + 0.12 * fwd;
			float w2 = 0.080 + 0.36 * fwd + 0.13 * blur;
			float dust = exp(-across2 * across2 / (w2 * w2)) * exp(-fwd * 1.05) * gate;
			float d2 = dot(q, q);
			float coma = exp(-d2 / (0.0032 + 0.028 * blur));
			float core = exp(-d2 / (0.00030 + 0.0080 * blur));
			float k = 1.0 / (1.0 + 2.6 * blur);
			sight = tint_a.rgb * ion * 1.15
				+ tint_b.rgb * dust * 0.72
				+ mix(tint_a.rgb, vec3(1.0), 0.40) * coma * 1.05 * k
				+ vec3(0.94, 0.96, 1.0) * core * 1.45 * k;
		} else {
			// RING: the far half of the ring, then the lit disc, then the near half over the top.
			float pr = 0.285;
			float pd = length(q);
			float soft = 0.010 + 0.075 * blur;
			float disc = smoothstep(pr + soft, pr - soft, pd);
			float nz = sqrt(max(1.0 - (pd * pd) / (pr * pr), 0.0));
			vec3 n = vec3(q / pr, nz);
			float lam = clamp(dot(normalize(n), normalize(vec3(-0.55, 0.62, 0.45))), 0.0, 1.0);
			float lat = q.y / pr;
			float bands = 0.84 + 0.16 * sin(lat * 12.0 + 0.7) + 0.07 * sin(lat * 29.0 + 2.1);
			vec3 pcol = tint_a.rgb * (0.14 + 0.98 * lam) * bands;

			float tilt = 0.30;
			vec2 rq = vec2(q.x, q.y / tilt);
			float rr = length(rq);
			float ri = 1.45 * pr;
			float ro = 2.30 * pr;
			float e = 0.020 + 0.085 * blur;
			float ring = smoothstep(ri - e, ri + e, rr) * smoothstep(ro + e, ro - e, rr);
			// the gap through the middle of the band
			float gapc = 1.80 * pr;
			float gw = 0.045 * pr + 0.10 * blur;
			ring *= 1.0 - 0.72 * exp(-(rr - gapc) * (rr - gapc) / (gw * gw));
			ring *= 0.82 + 0.18 * sin(rr * 70.0);
			vec3 rcol = tint_b.rgb * 0.95;
			// the bottom half of the screen is the half of the ring in FRONT of the planet
			float near = step(0.0, q.y);

			vec3 s = vec3(0.0);
			s = mix(s, rcol, ring * (1.0 - near) * (1.0 - disc));
			s = mix(s, pcol, disc);
			s = mix(s, rcol, ring * near);
			sight = s;
			// the disc and the band are SOLID - stars must not shine through them
			occlude = clamp(max(disc, ring * 0.92), 0.0, 1.0);
		}

		// ---- highlight shoulder. R2.6 (docs/STYLE_GUIDE.md): no near-clipping whites, cap ~0.92.
		// An exponential roll-off, so dim detail stays linear and nothing can reach pure white.
		sight = (vec3(1.0) - exp(-sight * 1.20)) * 0.90;

		vec3 col = (sky + stars) * (1.0 - occlude) + sight;

		if (mode == 0) {
			// ---- eyepiece: field vignette, then the glass rim
			col *= mix(0.22, 1.0, smoothstep(1.0, 0.52, r));
			col += vec3(0.30, 0.34, 0.50) * smoothstep(0.962, 0.996, r) * 0.55;
		} else {
			// ---- a print: read noise from a short exposure, and the faintest corner falloff a
			// plate has. No tube rim - you are holding a photograph now.
			float n = h21(UV * 512.0 + vec2(t, seed)) - 0.5;
			col += vec3(n) * grain * 0.30;
			col *= mix(1.0, 0.88, smoothstep(0.55, 1.35, r));
			col = max(col, vec3(0.0));
		}
		COLOR = vec4(col, 1.0);
	}
}
