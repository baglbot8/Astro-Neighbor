// Shared procedural surface detail — the implementation of docs/STYLE_GUIDE.md R2.9.
//
// The user's note: "I want to minimize larger surfaces on important things that dont have a
// 'texture' to them, so that nothing looks too flat / cheap... metal things should have a sheen,
// clothes might have a fabricy pattern/texture, wood will have a wood groove pattern/texture,
// rock should have a rougher texture, grass as plump softeness."
//
// EVERY builder uses these rather than inventing a private version, so the whole game shares one
// material vocabulary and there is one place to tune it.
//
// TWO RULES THAT MATTER
//  1. This does NOT undo R2.6 (pastel and matte). Detail comes from ROUGHNESS, NORMAL and subtle
//     ALBEDO variation. It must never be bought by raising specular into a blown hotspot.
//  2. FREQUENCY vs DISTANCE. sd_cloth runs at ~190 cycles/m, which needs the camera inside ~1.5 m
//     at 720p to stay above Nyquist. On a character judged at the 6.5 m gameplay camera you will
//     see NOTHING from it - do not crank `strength` chasing it, that only buys aliasing. Fine
//     grain is for conversation range; SEAMS and larger forms are what must carry 4-10 m. Use
//     `scale` to move a pattern into a band that survives the distance you actually need.
//  3. BRIGHT SURFACES CRUSH THIS LIBRARY. A cream wall renders at display luma ~0.88, up on the
//     compressive shoulder of ACES (white 6), so a 10% albedo change arrives as ~1.5% on screen -
//     measured: raising a macro amount from 0.18 to 0.32 moved a wall's luma std by 0.0015. Dark
//     timber sits on the linear part of the curve and needs a fraction of the same numbers. If a
//     light surface looks like the library "does nothing", that is why: reach for NORMAL and
//     SEAMS there, not for more albedo, and do not crank `strength` into aliasing.
//  4. NO OVERLOADING. Godot's shading language has no user function overloading and no default
//     arguments, so every function here has exactly ONE signature. `scale`, `knot_amount` and
//     `stitch_amount` are required, not optional - pass 1.0, 0.55 and 1.0 for the original
//     behaviour. If you extend a signature, update every caller in the same change.
//  5. Every fine pattern MUST fade with distance via sd_lod(). A high-frequency pattern with no
//     mip chain beats against the pixel grid and produces the circular moire that already had to
//     be fixed once on the planet ground. sd_lod() is not optional.
//
// USAGE (in a spatial shader's fragment()):
//     float lod  = sd_lod(VERTEX, 3.0, 14.0);            // 1 near, 0 far
//     vec3  wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
//     SdSurface s = sd_cloth(wpos, NORMAL, lod, 1.0);
//     ALBEDO   *= s.tint;
//     ROUGHNESS = clamp(ROUGHNESS + s.rough, 0.0, 1.0);
//     NORMAL    = normalize(NORMAL + s.bump);
// then in light(), optionally: SPECULAR_LIGHT += sd_sheen(NORMAL, VIEW, LIGHT, s.aniso) * ...

// ---------------------------------------------------------------------------- noise primitives

float sd_hash(vec3 p) {
	p = fract(p * vec3(0.1031, 0.1030, 0.0973));
	p += dot(p, p.yxz + 33.33);
	return fract((p.x + p.y) * p.z);
}

float sd_noise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float n000 = sd_hash(i);
	float n100 = sd_hash(i + vec3(1.0, 0.0, 0.0));
	float n010 = sd_hash(i + vec3(0.0, 1.0, 0.0));
	float n110 = sd_hash(i + vec3(1.0, 1.0, 0.0));
	float n001 = sd_hash(i + vec3(0.0, 0.0, 1.0));
	float n101 = sd_hash(i + vec3(1.0, 0.0, 1.0));
	float n011 = sd_hash(i + vec3(0.0, 1.0, 1.0));
	float n111 = sd_hash(i + vec3(1.0, 1.0, 1.0));
	return mix(mix(mix(n000, n100, f.x), mix(n010, n110, f.x), f.y),
	           mix(mix(n001, n101, f.x), mix(n011, n111, f.x), f.y), f.z);
}

float sd_fbm(vec3 p, int octaves) {
	float sum = 0.0;
	float amp = 0.5;
	for (int i = 0; i < octaves; i++) {
		sum += sd_noise(p) * amp;
		p *= 2.03;
		amp *= 0.5;
	}
	return sum;
}

// sd_fbm's octaves sum to 0.75, so `sd_fbm(p) - 0.5` biases a surface ~1.6% dark. Use this when
// you want a term centred on 0.5.
float sd_fbm01(vec3 p, int octaves) {
	return sd_fbm(p, octaves) / 0.75;
}

// MACRO band: low-frequency tonal drift. On a large surface this is the ONLY term that survives
// past ~20 m (a 2.6 cycles/m pattern is still ~13 px/cycle at 22 m), and it is what stops a big
// wall or a hillside reading as one flat swatch. Returns a multiplier centred on 1.0.
float sd_macro(vec3 objpos, float cycles_per_m, float amount, float lod) {
	if (lod <= 0.001 || amount <= 0.0) { return 1.0; }
	return 1.0 + (sd_fbm01(objpos * cycles_per_m, 2) - 0.5) * amount * lod;
}


// ---------------------------------------------------------------------------- distance fade

// 1.0 within `near` metres of the camera, 0.0 beyond `far`. VERTEX in a fragment shader is already
// view-space, so its length is the distance to the camera. ALWAYS multiply fine detail by this.
float sd_lod(vec3 view_vertex, float near_m, float far_m) {
	return 1.0 - smoothstep(near_m, far_m, length(view_vertex));
}

// ---------------------------------------------------------------------------- result struct

struct SdSurface {
	vec3  tint;   // multiply into ALBEDO (centred on 1.0)
	float rough;  // add to ROUGHNESS (signed, small)
	vec3  bump;   // add to NORMAL before normalize (small)
	float aniso;  // 0..1 strength for sd_sheen(); 0 for non-metals
	// The raw signed height field the tint was built from, centred on 0. USE THIS for bump on a
	// large flat surface: `bump`'s dominant term is along the normal, and normalize(N + N*k) == N,
	// so `bump` alone is a literal no-op on a flat wall or a ground. Take the screen-space
	// derivatives of `height` instead and tilt the normal by the tangential gradient (the planet
	// builder's `pc_surface_grad` in planet_common.gdshaderinc is a worked implementation).
	float height;
};

SdSurface sd_none() {
	SdSurface s;
	s.tint = vec3(1.0);
	s.rough = 0.0;
	s.bump = vec3(0.0);
	s.aniso = 0.0;
	s.height = 0.0;
	return s;
}

// ---------------------------------------------------------------------------- materials

// CLOTH — a fine woven weave with soft fibre roughness. For the astronaut's suit, NPC clothing,
// awnings, flags and bunting. Matte: the sheen belongs at grazing angles only, via sd_sheen.
SdSurface sd_cloth(vec3 wpos, vec3 n, float lod, float strength, float scale) {
	SdSurface s = sd_none();
	if (lod <= 0.001) { return s; }
	vec3 p = wpos * (190.0 * scale);
	// Two perpendicular thread families beating against each other = weave.
	float warp = sin(p.x + p.y * 0.14);
	float weft = sin(p.z * 1.03 - p.y * 0.11);
	float weave = warp * weft * 0.5 + 0.5;
	float fibre = sd_fbm01(wpos * (42.0 * scale), 2);
	float d = (weave - 0.5) * 0.55 + (fibre - 0.5) * 0.45;
	s.tint  = vec3(1.0 + d * 0.105 * strength * lod);
	s.height = d * strength * lod;
	s.rough = (0.10 + d * 0.10) * strength * lod;
	s.bump  = n * 0.0;
	s.bump += vec3(d) * 0.030 * strength * lod;
	s.aniso = 0.10 * strength * lod;
	return s;
}

// METAL — fine brushed grain plus a soft anisotropic sheen that travels as the view moves, and
// slightly darker micro-scratches. For helmet hardware, the rocket hull, Bolt's plates, robot
// shells and lamp posts. Not a mirror and not a hotspot.
// `n` MUST be the MODEL-space normal. The brush axis is chosen from it, so handing in a
// view-space normal makes the axis re-pick as the camera orbits and the grain direction flips in
// patches and crawls. toon_soft passes v_objnorm for exactly this reason.
SdSurface sd_metal(vec3 wpos, vec3 n, float lod, float strength, float scale) {
	SdSurface s = sd_none();
	if (lod <= 0.001) { return s; }
	// Brush direction follows the dominant axis of the surface, so the grain runs along the part
	// rather than along the world axes.
	vec3 an = abs(n);
	vec3 brush_dir = an.y > max(an.x, an.z) ? vec3(1.0, 0.0, 0.35) : vec3(0.0, 1.0, 0.0);
	float grain = sd_noise(wpos * (320.0 * scale) * (vec3(1.0) - abs(brush_dir) * 0.985));
	float scratch = smoothstep(0.86, 1.0, sd_noise(wpos * (84.0 * scale) + 11.0));
	float d = (grain - 0.5);
	s.tint  = vec3(1.0 + d * 0.085 * strength * lod - scratch * 0.06 * strength * lod);
	s.height = d * strength * lod;
	s.rough = (d * 0.10 - scratch * 0.16) * strength * lod;
	s.bump  = vec3(d) * 0.022 * strength * lod;
	// Kept low on purpose: at 0.55 the sheen lifted a mid-blue plate to pale blue, which is
	// exactly the "wet plastic across a whole panel" R2.6 forbids. The grain carries the read.
	// Faded in, not held: without this the sheen holds to the fade edge and snaps off, which
	// pops on a part crossing that distance and draws a ring on a surface spanning it.
	s.aniso = (0.20 + 0.10 * lod) * strength * smoothstep(0.0, 0.25, lod);
	return s;
}

// WOOD — directional grain along the plank with knots and a colour drift between boards. For
// benches, signs, doors, fences, market stalls and tree trunks. `grain_dir` is the plank's long
// axis in MODEL space.
//
// WARNING - the ring frequency is geometry-dependent. Rings are contours of the distance from the
// grain axis THROUGH THE MODEL ORIGIN, so the on-screen frequency depends on how fast that
// distance changes across the part. On a door 2.9 m from its origin it barely changes and the
// default 26 c/m is right; on a stage deck where it changes 1:1 the same default produced 220
// grain lines across 3.9 m - a third of a pixel each, i.e. invisible mush. Check your part and use
// `scale` to compensate.
//
// `knot_amount` weights the knots against the rings. The default 0.55 reads as wandering marbling;
// drop it toward 0.15-0.25 for the combed parallel lines ACNH's doors and signs actually have.
SdSurface sd_wood(vec3 wpos, vec3 grain_dir, float lod, float strength, float scale, float knot_amount) {
	SdSurface s = sd_none();
	if (lod <= 0.001) { return s; }
	vec3 g = normalize(grain_dir);
	float along = dot(wpos, g);
	// Squash across the grain so rings stretch along the plank.
	vec3 across = wpos - g * along;
	float rings = fract(length(across) * (26.0 * scale) + sd_fbm(wpos * 3.4, 2) * 2.6 + along * 0.35);
	float grain = smoothstep(0.42, 0.5, rings) * (1.0 - smoothstep(0.5, 0.62, rings));
	float knot = smoothstep(0.80, 0.97, sd_fbm01(wpos * (5.2 * scale) + 7.0, 2));
	// Board-to-board colour drift, quantised so neighbouring planks differ.
	// Board drift keyed off the ACROSS-grain axis only. Hashing both axes drew rectangles.
	float board = sd_noise(vec3(length(across) * 2.1, 0.0, 0.0) + 19.0);
	float d = grain * 0.65 + knot * knot_amount + (board - 0.5) * 0.5;
	s.tint  = vec3(1.0 - d * 0.115 * strength * lod);
	s.height = d * strength * lod;
	s.rough = (0.10 + d * 0.14) * strength * lod;
	s.bump  = vec3(grain - knot) * 0.045 * strength * lod;
	return s;
}

// ROCK — a genuinely rough microsurface with chipped edges and mottling at two scales. For rocks,
// cliffs, plateau banks, plaza paving and meteorites. Stone must never read as smooth plastic.
SdSurface sd_rock(vec3 wpos, vec3 n, float lod, float strength, float scale) {
	SdSurface s = sd_none();
	if (lod <= 0.001) { return s; }
	float coarse = sd_fbm01(wpos * (6.5 * scale), 3);
	float fine = sd_fbm01(wpos * (46.0 * scale), 2);
	float chip = smoothstep(0.62, 0.90, sd_noise(wpos * (19.0 * scale) + 3.0));
	float d = (coarse - 0.5) * 0.7 + (fine - 0.5) * 0.5;
	s.tint  = vec3(1.0 + d * 0.135 * strength * lod - chip * 0.06 * strength * lod);
	s.height = d * strength * lod;
	s.rough = (0.22 + fine * 0.16) * strength * lod;
	s.bump  = vec3(d) * 0.085 * strength * lod;
	return s;
}

// FOLIAGE / GRASS — plump softness: fine tuft detail and a hint of subsurface warmth where the sun
// passes through a leaf. Keep `warm` low; this is a suggestion of translucency, not a glow.
SdSurface sd_foliage(vec3 wpos, vec3 n, float lod, float strength, float scale) {
	SdSurface s = sd_none();
	if (lod <= 0.001) { return s; }
	float tuft = sd_fbm01(wpos * (30.0 * scale), 2);
	float clump = sd_fbm01(wpos * (7.0 * scale) + 5.0, 2);
	float d = (tuft - 0.5) * 0.65 + (clump - 0.5) * 0.55;
	s.tint  = vec3(1.0 + d * 0.165 * strength * lod);
	s.height = d * strength * lod;
	s.rough = (0.10 + d * 0.10) * strength * lod;
	// Puff the normal outward along the clump so the dome reads soft rather than hard-shaded.
	s.bump  = n * (clump - 0.5) * 0.26 * strength * lod;
	s.bump += vec3(d) * 0.085 * strength * lod;
	return s;
}

// ---------------------------------------------------------------------------- seams

// Panel seams with a topstitch bead. R2.9's cloth row asks for "seams and stitching where panels
// meet" and sd_cloth alone does not provide it; this is the generalised version of what the
// astronaut needed. `up` and `tan` are the PART's own model-space axes, so rings run around the
// limb and gores run along it regardless of world orientation.
//
// Seams survive far more distance than the weave does (a 0.14 m pitch is still 19 px at 6.5 m),
// so this is the term that carries gameplay range. `gore_phase` defaults to half a period on
// purpose: at phase 0 a gore lands on the centre-front of a torso, which is the vertical placket
// R2.7 explicitly calls a wetsuit zip.
SdSurface sd_seams(vec3 objpos, vec3 up, vec3 tan, float rings_per_m, float gores,
		float lod, float strength, float gore_phase, float stitch_amount) {
	SdSurface s = sd_none();
	if (lod <= 0.001 || strength <= 0.001) { return s; }
	float along = dot(objpos, normalize(up));
	vec3 flat_p = objpos - normalize(up) * along;
	float ang = atan(dot(flat_p, normalize(cross(up, tan))), dot(flat_p, normalize(tan)));
	float ring = fract(along * rings_per_m);
	float gore = fract((ang / (2.0 * PI) + gore_phase) * gores);
	// A soft V groove, plus a dashed bead sitting in it.
	float rg = 1.0 - smoothstep(0.0, 0.10, min(ring, 1.0 - ring));
	float gg = 1.0 - smoothstep(0.0, 0.10, min(gore, 1.0 - gore));
	float groove = max(rg, gg);
	// stitch_amount 0 = groove only. The bead is right on cloth and reads as a rivet line on
	// sheet metal, but on a plaster wall it draws a ladder of dashes climbing the surface.
	float stitch = step(0.55, fract(along * rings_per_m * 9.0 + ang * 3.0)) * groove * stitch_amount;
	s.tint  = vec3(1.0 - groove * 0.10 * strength * lod + stitch * 0.05 * strength * lod);
	s.rough = groove * 0.12 * strength * lod;
	// Crease pushes ACROSS the seam, using the part's own axes.
	s.bump  = normalize(up) * (rg - 0.5) * 0.055 * strength * lod;
	s.bump += normalize(tan) * (gg - 0.5) * 0.055 * strength * lod;
	return s;
}

// RUBBER — boots, gloves, hoses, mats, tyres. Fine speckle and sparse scuffs, and deliberately no
// sheen. sd_rock was tried for this and is authored for cliffs: at 6.5 and 46 cycles/m it gives
// only 1.5 and 11 cycles across a 0.24 m boot, so it moved the albedo under 3% and boots stayed
// visibly flat.
SdSurface sd_rubber(vec3 objpos, vec3 n, float lod, float strength, float scale) {
	SdSurface s = sd_none();
	if (lod <= 0.001) { return s; }
	float speckle = sd_noise(objpos * (165.0 * scale));
	float scuff = smoothstep(0.74, 0.94, sd_fbm01(objpos * (26.0 * scale) + 4.0, 2));
	float d = (speckle - 0.5);
	s.tint  = vec3(1.0 + d * 0.10 * strength * lod - scuff * 0.07 * strength * lod);
	s.height = d * strength * lod;
	s.rough = (0.20 + d * 0.10) * strength * lod;
	s.bump  = vec3(d) * 0.030 * strength * lod;
	s.aniso = 0.0;
	return s;
}

// Planar panel seams for BOXY surfaces. `sd_seams`' gore family is angular, so on a flat 5 m wall
// the spacing varies about 3x from centre to corner. This drives two uniform ring families along
// the part's own axes instead, each weighted by how much the surface faces that axis - which also
// keeps vertical joints off roofs.
SdSurface sd_panel_seams(vec3 objpos, vec3 axis_a, vec3 axis_b, float pitch_a, float pitch_b,
		vec3 n, float lod, float strength, float stitch_amount) {
	SdSurface s = sd_none();
	if (lod <= 0.001 || strength <= 0.001) { return s; }
	vec3 a = normalize(axis_a);
	vec3 b = normalize(axis_b);
	float wa = 1.0 - abs(dot(n, a));
	float wb = 1.0 - abs(dot(n, b));
	float ra = fract(dot(objpos, a) * pitch_a);
	float rb = fract(dot(objpos, b) * pitch_b);
	float ga = (1.0 - smoothstep(0.0, 0.10, min(ra, 1.0 - ra))) * wa;
	float gb = (1.0 - smoothstep(0.0, 0.10, min(rb, 1.0 - rb))) * wb;
	float groove = max(ga, gb);
	float stitch = step(0.55, fract(dot(objpos, a) * pitch_a * 9.0)) * groove * stitch_amount;
	s.tint  = vec3(1.0 - groove * 0.10 * strength * lod + stitch * 0.05 * strength * lod);
	s.rough = groove * 0.12 * strength * lod;
	s.bump  = a * (ga - 0.5) * 0.055 * strength * lod + b * (gb - 0.5) * 0.055 * strength * lod;
	return s;
}


// ---------------------------------------------------------------------------- sheen

// A soft anisotropic sheen for metal, to be added in light(). It travels as the view moves, which
// is what sells "metal", but it is broad and low-amplitude so it never becomes a blown hotspot.
// Multiply the result by LIGHT_COLOR / PI at the call site, as the toon light() does.
float sd_sheen(vec3 n, vec3 view, vec3 light, float aniso) {
	if (aniso <= 0.001) { return 0.0; }
	vec3 h = normalize(view + light);
	float ndh = max(dot(n, h), 0.0);
	// Broad lobe, deliberately far softer than the toon spec blob.
	// Broad on purpose. At pow 18 the lobe is 0.26 at 20 degrees off-axis, so it read on flat
	// plates (where it once lifted a mid-blue panel to pale) and did nothing on a curved
	// helmet. Broader and lower-amplitude reads as a sheen on both.
	float lobe = pow(ndh, 8.0);
	// Grazing-angle lift is what makes a sheen read as a sheen rather than a highlight.
	float graze = pow(1.0 - max(dot(n, view), 0.0), 2.5);
	return (lobe * 0.22 + graze * 0.34) * aniso;
}

// A cloth sheen: grazing angles only, no lobe. Fabric catches light at the silhouette.
float sd_cloth_sheen(vec3 n, vec3 view, float aniso) {
	if (aniso <= 0.001) { return 0.0; }
	return pow(1.0 - max(dot(n, view), 0.0), 3.0) * aniso;
}
