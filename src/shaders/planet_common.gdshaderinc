// Shared helpers for the planet ground / water / prop shaders (PLANET BUILDER).
// Everything is procedural: hashes, value noise, the ACNH-style triangle pattern, cube-sphere
// mapping (seamless-enough planar coordinates on a sphere) and the shared toon light ramp.

// --- WEB PARITY: THE COMPATIBILITY sRGB HELPERS -------------------------------------------------
// READ THIS BEFORE TOUCHING ANY COLOUR MATHS IN A SPATIAL SHADER. This block is the foundation the
// whole renderer-parity round is built on; the recipe at the bottom is what every other shader
// conversion must follow, verbatim.
//
// THE BUG (proven independently by two agents, then reproduced from scratch in a clean project):
// Godot's Compatibility renderer (WebGL2, which the web export is forced onto, and which is what
// the game is actually played on) moves the sRGB->linear conversion from CPU uniform-upload time —
// where Forward+ does it — to the END OF THE FRAGMENT STAGE. Measured:
//   * Compatibility does NOT convert `source_color` uniforms on upload; Forward+ does.
//   * Compatibility applies srgb_to_linear() to whatever fragment() writes to ALBEDO and EMISSION;
//     Forward+ does not.
//   * The two therefore break even ONLY for a shader that assigns a source_color uniform straight
//     to ALBEDO with no maths in between. (Measured; the two renderers agreed within 2 code values.)
//
// Every surface shader in this project instead does arithmetic on colour inside fragment() — the
// detail-band multiplies, pc_pastel, the vertex-colour multiply, grass_planet's sun_patch lift.
// Under Compatibility that arithmetic runs in DISPLAY space instead of LINEAR space and is THEN
// gamma-decoded, so every multiplicative term t lands as t^2.2 instead of t. Measured: a 2.09x
// contrast expansion on the material's own texture, pivoting on the untinted colour. That is the
// S-curve the user has been reporting for three rounds — "the grass comes out very white", "the
// plants are very black" — and it is one bug, not two.
//
// THE PROBE NUMBERS (unshaded quads, LINEAR tonemap, ten steps of 0.0667..1.0):
//   ALBEDO = literal            F+ [73,102,124,141,156,170,188,213,231,255]
//                               C  [12, 32, 50, 68, 85,102,128,170,204,255]
//   ALBEDO = pc_out(literal)    F+ [73,102,124,141,156,170,188,213,231,255]
//                               C  [73,102,124,141,156,170,188,213,231,255]   <- MAXDIFF 0
// Two agents reached maxdiff 0 separately, without seeing each other's work. Nothing here is a
// fitted constant, and nothing here may BECOME one: a magic gain that "closes the last few units"
// is exactly the mistake that cost this project its three previous attempts at web parity.
//
// WHAT THIS IS *NOT*. The "double-albedo divergence" written up in docs/OPEN_ISSUES.md 19 and 32
// IS NOT REAL and nobody should re-add a knob for it. Measured with a flat probe: BOTH renderers
// multiply DIFFUSE_LIGHT by ALBEDO exactly once, light() sees the same ALBEDO the engine goes on to
// multiply by, and specular is never multiplied by albedo in either. So light(), pc_light_term and
// the albedo bookkeeping below are CORRECT AS THEY STAND — leave them alone. (The separate "albedo
// applied twice" note about six shaders composing the finished colour in light() is real, but it is
// renderer-INDEPENDENT: it costs Forward+ exactly as much, so it is a desktop art question.)
//
// The per-shader compat knobs that were invented to paper over the phantom bug have been deleted as
// part of each shader's conversion — grass_planet's `compat_gain` (which was additionally costing
// Compatibility ~40% of the ground's brightness) and planet_foliage's `compat_light_boost`.
// sky.gdshader's `compat_sky_lift` is the ONE exception and it stays: a cross-check found the sky
// path's transfer is col^1.28 rather than a clean decode, so the scheme below is UNVALIDATED there
// and every `shader_type sky` shader is frozen this round.

// Exact sRGB transfer functions (the piecewise IEC 61966-2-1 pair, not a 2.2 power approximation —
// the linear toe below 0.04045 is where the dark end of the ramp lives, and an approximation there
// is worth several code values on exactly the shadow tones this project keeps failing on).
vec3 pc_s2l(vec3 q) { return mix(q / 12.92, pow((q + vec3(0.055)) / 1.055, vec3(2.4)), step(vec3(0.04045), q)); }
vec3 pc_l2s(vec3 q) { q = max(q, vec3(0.0)); return mix(q * 12.92, 1.055 * pow(q, vec3(1.0 / 2.4)) - vec3(0.055), step(vec3(0.0031308), q)); }

// The two workhorses take the flag as an argument, and the MACROS below supply it. That indirection
// is not style, it is the only arrangement that compiles:
//   * `global uniform float astro_compat;` may be declared only ONCE per shader. Declaring it here
//     in the include is a "Redefinition of 'astro_compat'" error in every shader that already has
//     its own (grass_planet and planet_foliage both did) — verified in a scratch project, not
//     guessed.
//   * Godot's shader parser is single-pass, so a FUNCTION in this include cannot reference a uniform
//     the including shader declares further down its own file.
//   * A macro is expanded at the CALL site, where astro_compat is in scope whatever the declaration
//     order. Wrapping the real work in pc_in_f / pc_out_f keeps the argument evaluated exactly once,
//     which a naive `#define pc_out(q) ((astro_compat > 0.5) ? pc_l2s(q) : (q))` would not — and the
//     argument at the ALBEDO write is usually a large expression.
// So: your shader still declares `global uniform float astro_compat;` itself, anywhere it likes.
vec3 pc_in_f(vec3 q, float compat) { return (compat > 0.5) ? pc_s2l(q) : q; }
vec3 pc_out_f(vec3 q, float compat) { return (compat > 0.5) ? pc_l2s(q) : q; }

// A colour ARRIVING from a `source_color` uniform. Compatibility skips Godot's CPU-side sRGB->linear
// on these, so do it here. Identity on Forward+ (astro_compat == 0.0), which is why the reference
// look cannot move.
#define pc_in(q) pc_in_f((q), astro_compat)

// A colour LEAVING fragment() into ALBEDO or EMISSION. Compatibility applies srgb_to_linear after
// fragment() returns, so pre-encode. Identity on Forward+.
#define pc_out(q) pc_out_f((q), astro_compat)

// --- THE RECIPE. FOLLOW IT EXACTLY; THE RISK IS ALL IN GETTING THESE WRONG ----------------------
// (a) WRAP with pc_in() every `source_color` uniform, at the point it first enters the colour maths:
//     pc_in(color_a.rgb), pc_in(shade_tint.rgb), pc_in(sand_color.rgb), pc_in(emission_color.rgb)...
//     Wrap it ONCE, at first use, not at every mention — double-wrapping is a second decode.
// (b) WRAP THE FINAL WRITES: ALBEDO = pc_out(...); EMISSION = pc_out(...);
// (c) DO NOT pc_in() vertex COLOR, INSTANCE_CUSTOM, literals, or computed values. They are delivered
//     identically to both renderers and Forward+ treats them as linear already. They need pc_out on
//     the WRITE only. (This is the toon_soft / planet_foliage / planet_glow_pulse / crystal case.)
// (d) DO NOT WRAP ANYTHING USED AS A MASK OR SELECTOR rather than as a colour. This is the failure
//     mode that is hardest to see, because it changes geometry-driven behaviour rather than tone.
//     The known list, so nobody has to rediscover it:
//       * metal_plates.gdshader:236 and :258 — bank selectors
//       * plaza_tiles.gdshader:205        — bank selector
//       * planet_foliage.gdshader         — the COLOR.a wood marker
//       * grass_planet.gdshader           — COLOR.b crater dust and v_color.a baked AO
//       * AO, ROUGHNESS, METALLIC, SPECULAR anywhere — these are not colours.
// (e) DO NOT CONVERT ANY `shader_type sky` SHADER. Measured: that path's transfer is col^1.28, not a
//     clean decode, and nobody has explained why. sky.gdshader keeps its compat_sky_lift = 0.08.
// (f) DO NOT touch light(), beyond deleting that shader's own dead compat knob. See the
//     "WHAT THIS IS NOT" paragraph above: the albedo bookkeeping is already correct.
// (g) The maxdiff-0 guarantee holds for values in [0, 1]. It does NOT hold for a colour driven ABOVE
//     1.0 inside fragment(), because pc_l2s clamps nothing and the encode of an over-range value is
//     not the inverse of the decode the engine applies. grass_planet's `sun_patch` is the one
//     shipped case; its measurement is recorded in that file.
// (h) One shader per commit, scoring with parity.sh after each. A cross-check specifically overruled
//     the "ship it as one big commit" advice — the knobs are per-shader, so the conversion is too,
//     and this project has already had to revert one all-at-once shader sweep.
// (i) DO NOT EXPECT parity.sh's LUMA GAP TO REACH 0, AND DO NOT FIT A CONSTANT TRYING TO GET IT
//     THERE. The two captures it compares are not the same scene at the same quality, because the
//     project deliberately ships a low-power profile to the browser build:
//       * src/world/environment.gd:462,479  glow_enabled and ssao_enabled are OFF under
//         Compatibility. SSAO is where a lot of the ground's and props' contact darkening comes
//         from, so Compatibility renders brighter and flatter no matter what the shaders do.
//       * src/autoload/platform.gd:49+      MSAA off, FXAA on, a cheaper directional shadow filter.
//       * src/planet/props/planet_props.gd:230  prop density drops to 0.35, and :236 turns some
//         props off entirely — so the two frames do not even contain the same objects.
//     Those are intentional performance decisions, not colour bugs. The number that tells you a
//     SHADER is right is a maxdiff of 0-1 for that shader in isolation (a fixed sun, a fixed
//     ambient, nothing else in the scene); parity.sh's job is to catch a regression, not to hit 0.
//     MEASURED for the two shaders converted first: grass_planet maxdiff 0 (1 at sun_patch 1.72),
//     toon_soft maxdiff 1 on both its plain and its vertex-coloured path.

float pc_hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float pc_hash31(vec3 p) {
	p = fract(p * vec3(0.1031, 0.1030, 0.0973));
	p += dot(p, p.yxz + 33.33);
	return fract((p.x + p.y) * p.z);
}

// Smooth 3D value noise in [0, 1].
float pc_noise3(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float n000 = pc_hash31(i);
	float n100 = pc_hash31(i + vec3(1.0, 0.0, 0.0));
	float n010 = pc_hash31(i + vec3(0.0, 1.0, 0.0));
	float n110 = pc_hash31(i + vec3(1.0, 1.0, 0.0));
	float n001 = pc_hash31(i + vec3(0.0, 0.0, 1.0));
	float n101 = pc_hash31(i + vec3(1.0, 0.0, 1.0));
	float n011 = pc_hash31(i + vec3(0.0, 1.0, 1.0));
	float n111 = pc_hash31(i + vec3(1.0, 1.0, 1.0));
	float x00 = mix(n000, n100, f.x);
	float x10 = mix(n010, n110, f.x);
	float x01 = mix(n001, n101, f.x);
	float x11 = mix(n011, n111, f.x);
	float y0 = mix(x00, x10, f.y);
	float y1 = mix(x01, x11, f.y);
	return mix(y0, y1, f.z);
}

float pc_fbm3(vec3 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 3; i++) {
		v += a * pc_noise3(p);
		p = p * 2.03 + vec3(17.1, 9.7, 3.3);
		a *= 0.5;
	}
	return v / 0.875;
}

// Signed distance to an equilateral triangle of "radius" r centered at the origin.
float pc_tri_sdf(vec2 p, float r) {
	const float k = 1.7320508;
	p.x = abs(p.x) - r;
	p.y = p.y + r / k;
	if (p.x + k * p.y > 0.0) {
		p = vec2(p.x - k * p.y, -k * p.x - p.y) * 0.5;
	}
	p.x -= clamp(p.x, -2.0 * r, 0.0);
	return -length(p) * sign(p.y);
}

// Signed distance to a rounded box (half extents b, corner radius r).
float pc_rbox_sdf(vec2 p, vec2 b, float r) {
	vec2 q = abs(p) - b + vec2(r);
	return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;
}

// ACNH-style scattered triangles. uv in cell units. Returns (mask, variant) where variant in [0,1]
// picks a lighter/darker triangle. density = fraction of cells that get a triangle.
vec2 pc_tri_pattern(vec2 uv, float r, float density) {
	vec2 cell = floor(uv);
	vec2 f = uv - cell;
	float h1 = pc_hash21(cell);
	float h2 = pc_hash21(cell + vec2(7.13, 3.71));
	float h3 = pc_hash21(cell + vec2(2.91, 9.17));
	vec2 c = vec2(0.5) + (vec2(h1, h2) - 0.5) * 0.42;
	float ang = h2 * 6.28318;
	vec2 d = f - c;
	float cs = cos(ang);
	float sn = sin(ang);
	d = vec2(cs * d.x - sn * d.y, sn * d.x + cs * d.y);
	float sd = pc_tri_sdf(d, r);
	float aa = fwidth(sd) * 0.9 + 0.004;
	float m = (1.0 - smoothstep(-aa, aa, sd)) * step(h3, density);
	return vec2(m, fract(h1 * 5.37));
}

// Procedural-texture LOD. Returns 0 where one pattern cell is comfortably bigger than a pixel and
// ramps to 1 once a cell is about a pixel across. EVERY hard per-cell ground pattern is blended
// toward its own average by this.
//
// This is the fix for the "concentric contour rings" defect: the grass triangles (0.40 m cells), the
// plaza tiles and Bolt's plates are per-cell step() functions with no mip chain, so past ~8 m they
// undersample and beat against the pixel grid. The beat pattern of a regular grid seen in
// perspective runs along lines of constant sampling rate — which on a tiny planet are circles around
// the point under the camera, getting denser toward the limb. That is exactly the topographic-map
// moire the critic photographed, and no amount of shadow or albedo work would have touched it.
float pc_detail_lod(vec2 uv_cells) {
	float w = max(length(dFdx(uv_cells)), length(dFdy(uv_cells)));
	return clamp((w - 0.38) / 0.62, 0.0, 1.0);
}

// Average coverage of pc_tri_pattern, so the faded-out pattern keeps the same mean tone instead of
// popping brighter in the distance. (Equilateral triangle area = 3*sqrt(3)/4 * r^2, plus the
// antialias band, times the fraction of cells that carry a triangle.)
float pc_tri_avg(float r, float density) {
	return clamp(1.75 * r * r * density, 0.0, 1.0);
}

// --- R2.9 SURFACE TEXTURE: turning a scalar detail field into a normal ---------------------------
// The sd_* library in surface_detail.gdshaderinc returns its bump as a model-space VECTOR, which is
// the right shape for a small prop but is a no-op on the ground: its dominant term is `n * k`, and
// normalize(N + N*k) == N. A large surface needs the TANGENTIAL gradient of the detail field.
//
// `pc_surface_grad` is Mikkelsen's surface-gradient bump: it reconstructs the world-space slope of a
// height field h from screen-space derivatives, so it costs two derivatives and NO extra noise
// samples (the alternative — sampling the field again at +du/+dv — triples the cost of the most
// expensive thing on screen). Subtract the result from the world normal, scaled to taste.
//
// The returned vector is world-space; in a shader whose NORMAL is already view-space, rotate it with
// VIEW_MATRIX and subtract, so the terrain's own displaced normal is perturbed rather than replaced.
vec3 pc_surface_grad(vec3 wpos, vec3 n, float h) {
	vec3 dpx = dFdx(wpos);
	vec3 dpy = dFdy(wpos);
	vec3 r1 = cross(dpy, n);
	vec3 r2 = cross(n, dpx);
	float det = dot(dpx, r1);
	if (abs(det) < 1e-9) {
		return vec3(0.0);
	}
	return (r1 * dFdx(h) + r2 * dFdy(h)) / det;
}

// How aggressively a procedural detail band is faded out before it can alias. Same measurement as
// pc_detail_lod (texels per pixel from the screen-space derivatives) but expressed as "how much of
// this band survives": 1 near, 0 once a cycle is close to a pixel.
//
// `cycles_per_m` is the band's DOMINANT frequency. The 1.6 safety factor completes the fade at about
// 1.6 px per cycle instead of 1.0, because unlike the triangle/tile patterns these bands are value
// noise with no fwidth antialiasing of their own — a noise field taken to Nyquist is exactly the
// circular moire that pc_detail_lod was written to remove.
float pc_band_lod(vec2 uv_m, float cycles_per_m) {
	return 1.0 - pc_detail_lod(uv_m * (cycles_per_m * 1.6));
}

// A DETAIL BAND MUST NOT CHANGE THE TONE, only the texture.
//
// `sd_fbm()` in surface_detail.gdshaderinc is not normalised: it sums octaves at 0.5, 0.25, 0.125
// without dividing by the total, so two octaves average 0.375 and three average 0.4375 — never the
// 0.5 that the `- 0.5` recentring in every sd_* function assumes. Every sd_* tint therefore has a
// mean BELOW 1.0, and multiplying it into a colour darkens the surface as well as texturing it.
//
// MEASURED: two sd_foliage bands at strength 2.7 cost the meadow 12% of its value and pushed the
// ground crop's `value mean` from 0.676 to 0.653, i.e. straight out of the R2.6 gate — a tone
// regression bought by nothing. These are the analytic means of each tint as a function of
// (strength * lod); divide the tint by its own mean and the band is pure texture again.
float pc_sd_mean_foliage(float strength_lod) { return 1.0 - 0.0248 * strength_lod; }
float pc_sd_mean_rock(float strength_lod) { return 1.0 - 0.0185 * strength_lod; }
float pc_sd_mean_wood(float strength_lod) { return 1.0 - 0.0078 * strength_lod; }
float pc_sd_mean_metal(float strength_lod) { return 1.0 - 0.0012 * strength_lod; }

// Cube-sphere planar coordinates (meters) for a unit direction d on a planet of radius R.
// Each cube face gets its own gnomonic-with-atan map so scale stays near-uniform; faces meet at hard
// seams (tiny for small patterns) instead of the ghosting of triplanar blending.
vec2 pc_cube_uv(vec3 d, float R) {
	vec3 a = abs(d);
	vec2 uv;
	float off;
	if (a.x >= a.y && a.x >= a.z) {
		uv = vec2(d.z * sign(d.x), d.y) / a.x;
		off = 0.0;
	} else if (a.y >= a.z) {
		uv = vec2(d.x, d.z * sign(d.y)) / a.y;
		off = 1000.0;
	} else {
		uv = vec2(-d.x * sign(d.z), d.y) / a.z;
		off = 2000.0;
	}
	return R * atan(uv) + vec2(off, off * 0.5);
}

// Angular distance (radians) from unit dir d to the great-circle arc segment a -> b.
float pc_arc_distance(vec3 d, vec3 a, vec3 b) {
	vec3 n = normalize(cross(a, b));
	float sd = dot(d, n);
	vec3 p = normalize(d - n * sd);
	float ab = acos(clamp(dot(a, b), -1.0, 1.0));
	float ap = acos(clamp(dot(a, p), -1.0, 1.0));
	float pb = acos(clamp(dot(p, b), -1.0, 1.0));
	if (ap + pb <= ab + 0.002) {
		return abs(asin(clamp(sd, -1.0, 1.0)));
	}
	return min(acos(clamp(dot(d, a), -1.0, 1.0)), acos(clamp(dot(d, b), -1.0, 1.0)));
}

// Fraction of `shade_floor` that survives inside a CAST shadow (atten -> 0). Keeps the self-shaded
// terminator soft while props and characters throw a shadow you can actually read on the ground.
// Matches shadow_floor / shade_floor in src/shaders/toon_soft.gdshader (0.08 / 0.62) so the ground
// and everything standing on it darken by the same amount. [environment builder, authorized fix]
const float PC_CAST_SHADOW_SCALE = 0.12;

// --- R2.6 PASTEL GUARD --------------------------------------------------------------------------
// MEASURED: the ACES tonemapper plus the environment's colour grade (contrast 1.04, saturation 1.08)
// amplify chroma enormously as value falls. A green of albedo S 0.40 / V 0.35 comes out of the pipe
// at S 1.00 with the red channel clipped to zero — which is exactly how our shadow green measured
// #0f6247 S 0.84 against the ACNH reference's #3d6e5b S 0.44.
//
// So every planet surface runs its final albedo through `pc_pastel`, which:
//   * caps saturation at `s_max`, and
//   * removes extra chroma as the colour darkens (`dark_desat`), pre-compensating the tonemapper.
// It desaturates toward a neutral sitting between the colour's own luma and its brightest channel,
// so the result is a LIGHTER, SOFTER version of the same hue (a pastel) and never a darker, browner
// one. The hue is never touched, so home stays green, Zorp stays violet and Bolt stays steel.
vec3 pc_pastel(vec3 c, float s_max, float dark_desat) {
	float mx = max(c.r, max(c.g, c.b));
	if (mx <= 0.0002) {
		return c;
	}
	float mn = min(c.r, min(c.g, c.b));
	float sat = (mx - mn) / mx;
	// Neutral target: 55% of the way from luma to the max channel, so desaturating does not darken
	// (mixing toward pure luma crushes blues and violets, mixing toward pure max washes everything out).
	float lum = dot(c, vec3(0.2126, 0.7152, 0.0722));
	float neutral = mix(lum, mx, 0.55);
	float k = (sat > s_max) ? 1.0 - s_max / sat : 0.0;
	k = max(k, dark_desat * (1.0 - smoothstep(0.14, 0.52, mx)));
	return mix(c, vec3(neutral), clamp(k, 0.0, 0.88));
}

// Chroma cap applied to a surface AFTER it is multiplied by LIGHT_COLOR. The albedo guard cannot
// see the light: a green meadow albedo (S 0.48) under the strongly blue moon came back out of the
// tonemapper as a cyan #245e74 S 0.69 covering 45% of the night ground. Capping the lit product
// keeps moonlit grass a soft blue-green instead of neon teal, and is a no-op in daylight (the sun
// is near-white, so the lit ground already sits well under the cap).
const float PC_LIGHT_S_MAX = 0.55;

// How much chroma the self-shaded side loses on top of the albedo's own pastel guard. A surface in
// shadow is lit by broad-spectrum skylight, so it loses saturation as well as brightness — the same
// reason the reference's shadow green is only S 0.44. Without this the shaded side is where the
// whole saturation p90 tail lives.
const float PC_SHADE_S_MAX = 0.42;
const float PC_SHADE_DESAT = 0.26;

// --- THE ALBEDO IS APPLIED BY THE ENGINE, NOT BY light() ----------------------------------------
// MEASURED in-engine (Godot 4.7.1, Forward+): writing `DIFFUSE_LIGHT = vec3(0.20)` from light() with
// `ALBEDO = vec3(1.0, 0.5, 0.25)` renders exactly the pipeline result for (0.20, 0.10, 0.05) — the
// renderer multiplies the accumulated `diffuse_light` by ALBEDO *after* light() returns. (Two more
// probes confirm it: ALBEDO = 0 renders black no matter what light() writes, and LIGHT_COLOR does
// include the * PI, so `LIGHT_COLOR / PI` is exactly sun_colour * energy.)
//
// Every toon light() here composes the FINAL surface colour — it needs the albedo in hand to apply
// the toon ramp, the shade tint and the chroma guards — so handing that colour straight to
// DIFFUSE_LIGHT squares the albedo. Squaring is invisible on a neutral surface and catastrophic on a
// chromatic one: a leaf green of linear (0.074, 0.342, 0.223) becomes (0.005, 0.117, 0.050), whose
// saturation is 0.95 instead of 0.78, with the red channel crushed to ~1/255. That is exactly the
// #065f33 S 0.94 foliage the critic measured, and the same mechanism darkens every shaded side far
// past its authored value.
//
// `pc_light_term` divides the composed colour back out, so the engine's multiply lands it once.
// ALBEDO must be clamped to PC_ALBEDO_FLOOR in fragment() (see pc_albedo_floor) so a channel that is
// zero in the albedo cannot make the quotient explode.
const float PC_ALBEDO_FLOOR = 0.0035;

vec3 pc_albedo_floor(vec3 albedo) {
	return max(albedo, vec3(PC_ALBEDO_FLOOR));
}

vec3 pc_light_term(vec3 composed, vec3 albedo) {
	return composed / max(albedo, vec3(PC_ALBEDO_FLOOR));
}

// Shared toon diffuse: soft two-tone ramp with tinted shadow side (same language as toon_soft.gdshader).
// The tinted "shadow side" base term belongs to the sun only; point/spot lights contribute a pure
// attenuated ramp (otherwise every omni light paints its cluster cells with the base term).
vec3 pc_toon_diffuse(vec3 albedo, float ndl, float atten, float softness, float shade_strength, vec3 shade_tint, float shade_floor, bool is_directional, out float lit_out) {
	float lit = smoothstep(-softness, softness, ndl) * atten;
	lit_out = lit;
	if (!is_directional) {
		return albedo * lit;
	}
	vec3 shadow_col = albedo * mix(vec3(1.0), shade_tint, shade_strength);
	shadow_col = pc_pastel(shadow_col, PC_SHADE_S_MAX, PC_SHADE_DESAT);
	float floor_level = shade_floor * mix(PC_CAST_SHADOW_SCALE, 1.0, atten);
	return mix(shadow_col * floor_level, albedo, lit);
}

// A CAST SHADOW IS NOT AN ABSENCE OF LIGHT — it is ground lit by the sky alone. Without this the
// shadow term is `albedo * shade_tint * shade_floor * PC_CAST_SHADOW_SCALE`, and with the engine's
// own albedo multiply on top of it that is a near-black hole with a hard edge: measured on Bolt,
// 4.7-7.5% of the documented ground crop fell below luma 0.15 under the tower shadows (luma 0.15
// against a lit deck of 0.59), which is what pinned its luma p05 at 0.105. ACNH shadows are TINTED.
//
// The returned term goes straight into DIFFUSE_LIGHT, so the engine multiplies it by the albedo
// exactly once — it is the surface's own colour under a cool sky, never a grey wash — and it is
// scaled by LIGHT_COLOR by the caller so it tracks the sun's energy and disappears at night.
// It applies ONLY where the surface faces the sun but is blocked (atten < 1), so the self-shaded
// terminator keeps its toon ramp and the lit ground is untouched.
vec3 pc_shadow_fill(float ndl, float atten, float softness, vec3 fill_color, float strength) {
	float shadowed = (1.0 - atten) * smoothstep(-softness, softness, ndl);
	return fill_color * (strength * shadowed);
}

vec3 pc_hsv2rgb(vec3 c) {
	vec3 p = abs(fract(c.xxx + vec3(0.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0);
	return c.z * mix(vec3(1.0), clamp(p - 1.0, 0.0, 1.0), c.y);
}
