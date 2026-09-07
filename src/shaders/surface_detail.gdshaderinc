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

// ---------------------------------------------------------------------------- alien skin
// A vec3 hash. `sd_hash` returns a float, and a cellular pass needs a jittered POINT per cell, so
// three floats per cell. This is the same Dave Hoskins "hash without sine" construction sd_hash uses.
vec3 sd_hash3(vec3 p) {
	p = fract(p * vec3(0.1031, 0.1030, 0.0973));
	p += dot(p, p.yxz + 33.33);
	return fract((p.xxy + p.yzz) * p.zyx);
}

// ALIEN SKIN — round spots sitting on a scaly cell ground.
//
// Why this is not sd_rock: rock is fbm, which is MOTTLING. Spots and scales are CELLULAR, so this
// runs one 3x3x3 cellular pass and reads two things out of it — a spot wherever a PICKED feature
// point is within `spot_radius`, and the gap between the two nearest points (f2 - f1) as the ridge
// between neighbouring cells, which is what reads as a scaly ground.
//
// Only some cells get a spot (`step(0.52, h.x)`, so 47.8% of them), which makes the skin blotchy
// like the reference sheet's creatures rather than a regular polka dot.
//
// SPOTS ARE ACCUMULATED INSIDE THE LOOP, NOT READ OFF f1 AFTERWARDS. Reading the spot off the
// nearest point only lets each point paint inside its OWN Voronoi cell, so every spot was clipped
// flat against its cell wall once the radius grew past the cell. Measured over 600k samples, the
// clipped form loses 6% of the spot mass at radius 0.55, 19% at 0.74 and 42% at 1.20 — and the
// missing mass is exactly the outside of each blob, which is the part that made it read as round.
// Below radius 0.5 the two agree to within 4%, which is why the shipping cast barely moved.
//
// spot_dc / THE DC TERM. `d` must average zero or this stops being a pattern and becomes a flat
// albedo shift. THE SPOT MEAN DEPENDS ON spot_radius AND MUST BE PASSED IN TO TRACK IT — it is not
// a constant. This used to be a hardcoded 0.22, which is ~6x the true mean at the shipping radius
// 0.34, so alien skin was a flat 6% DARKENING with a faint pattern on top (the +0.099 saturation
// cost in docs/OPEN_ISSUES.md item 35); above radius ~0.70 the same constant flips sign and
// LIGHTENS the character instead. Measured means of the accumulated spot term:
//
//     radius  0.10   0.20   0.30   0.34   0.40   0.50   0.60   0.74   0.90   1.00   1.20
//     mean    .001   .007   .024   .035   .057   .109   .183   .320   .500   .610   .789
//
// fitted to within 0.001 over the whole range by
//     dc(r) = 1 - exp(-(0.74343*r^3 + 0.52963*r^4 - 0.33228*r^5))
// which is what `MaterialLib.spot_dc()` evaluates for callers. The r^3 lead term is just the
// kernel volume times the 0.478 pick rate; the rest is blob overlap saturating toward 1.
//
// The edge term's DC was audited the same way and is a true constant (f2 - f1 does not depend on
// any uniform): measured mean 0.3242 over 600k samples, against the 0.30 that was assumed here.
//
// `tint` and `height` deliberately share the same signed `d` — every other sd_* function in this
// file pairs them that way, and a version where they disagreed made the lighting fight the albedo.
SdSurface sd_skin(vec3 objpos, vec3 n, float lod, float strength, float scale,
		float spot_amount, float scale_amount, float spot_radius, float spot_dc) {
	SdSurface s = sd_none();
	if (lod <= 0.001) { return s; }
	vec3 p = objpos * (7.0 * scale);
	vec3 ip = floor(p);
	vec3 fp = p - ip;
	float f1 = 8.0;
	float f2 = 8.0;
	float spot = 0.0;
	for (int k = -1; k <= 1; k++) {
		for (int j = -1; j <= 1; j++) {
			for (int i = -1; i <= 1; i++) {
				vec3 g = vec3(float(i), float(j), float(k));
				vec3 h = sd_hash3(ip + g);
				float dd = length(g + h - fp);
				// EVERY picked point paints, not just the nearest one, so a blob crosses its own
				// cell wall and stays round. Above radius 1.0 a point two cells away can reach
				// this fragment and this 3x3x3 window will clip it — that is the practical ceiling
				// behind `surface_spot_radius`'s 1.20 hint_range.
				spot = max(spot, (1.0 - smoothstep(spot_radius * 0.5, spot_radius, dd)) * step(0.52, h.x));
				if (dd < f1) { f2 = f1; f1 = dd; }
				else if (dd < f2) { f2 = dd; }
			}
		}
	}
	float edge = 1.0 - smoothstep(0.03, 0.16, f2 - f1);
	// Centred on zero so the skin is TEXTURED without being TINTED. See the DC note above.
	float d = (spot - spot_dc) * spot_amount * 0.6 - (edge - 0.3242) * scale_amount * 0.4;
	s.tint = vec3(1.0 + d * 0.42 * strength * lod);
	s.height = d * strength * lod;
	// Gated on scale_amount with the rest of the scale term. Without this a character who asked for
	// smooth skin (scale_amount 0) still carried the full cell-wall pattern in ROUGHNESS, and
	// toon_soft's light() widens its spec lobe by ROUGHNESS, so the ghost walls were visible.
	s.rough = edge * 0.18 * strength * lod * scale_amount;
	s.bump = vec3(d) * 0.10 * strength * lod;
	return s;
}

// SCALES — true overlapping shingle rows, for a reptile neighbour. Distinct from sd_skin's
// `scale_amount`, which only draws the WALLS between cells: that is a mosaic of abutting tiles,
// and at 8 m it collapses into the same speckle as everything else. A shingle needs one scale to
// pass IN FRONT OF the one below it, which a Voronoi partition can never express because its cells
// tile the space exactly once.
//
// HOW THE OVERLAP IS BUILT — three things, none of which is a plain cellular read:
//  1. STAGGERED LATTICE. Odd rows have their feature point pushed half a cell along X
//     (`fract(h.x + 0.5 * mod(cell.y, 2.0))`), so rows sit in running bond like brickwork instead
//     of lining up into a square grid. The offset is applied to the POINT, keyed off the integer
//     cell index, NOT by shearing the sampling coordinate (`p.y += floor(p.x) * 0.5`). A coordinate
//     shear is discontinuous at every integer plane and draws a hard vertical break line through
//     the pattern once per cell — rendered, measured and rejected; see the note in the return value
//     of the shader pass. Keying off the cell index is continuous everywhere and staggers the same.
//  2. LOBES, NOT CELLS. Each point paints a squashed ellipsoid that is far wider than its cell
//     (0.95 across, 0.76 tall against a 1.0 pitch), so neighbouring scales genuinely overlap.
//  3. A PAINTER'S ORDER. Among every lobe covering a fragment, the one from the HIGHEST row wins
//     (`float(j) * 4.0 + lobe` as the sort key), so a scale is drawn over the row beneath it. The
//     winner's height therefore steps discontinuously at the free edge — that step IS the shingle
//     edge — and `under - top` measures how deeply the losing scale is buried, which gives the
//     occlusion crease that sells the overhang.
//
// The lobe extents are chosen so a point two cells away is always outside the lobe
// ((1 - 0.20) * 1.25 = 1.00 >= 0.95 along Y, 1.0 >= 0.95 along X and Z), i.e. this 3x3x3 window is
// EXACT, not truncated: verified against a 5x5x5 window over 80k samples at max |diff| 0.000000.
// If you widen the lobes, widen the loop with them.
//
// DC: measured mean of (top - occl * 0.55) is 0.4442 over 500k samples. It is a genuine constant
// here (no uniform feeds the lobe geometry), unlike sd_skin's spot DC.
SdSurface sd_scales(vec3 objpos, vec3 n, float lod, float strength, float scale) {
	SdSurface s = sd_none();
	if (lod <= 0.001) { return s; }
	vec3 p = objpos * (9.0 * scale);
	vec3 ip = floor(p);
	vec3 fp = p - ip;
	float top = 0.0;    // the covering scale's height at this fragment
	float under = 0.0;  // the best-covered scale hidden beneath it
	float best = -1e9;
	for (int k = -1; k <= 1; k++) {
		for (int j = -1; j <= 1; j++) {
			for (int i = -1; i <= 1; i++) {
				vec3 g = vec3(float(i), float(j), float(k));
				vec3 cell = ip + g;
				// Jitter narrowed to 0.62 of a cell: scales are a grown, ordered structure, and at
				// full jitter the rows dissolve into the same blob field sd_skin already gives.
				vec3 h = 0.5 + (sd_hash3(cell) - 0.5) * 0.62;
				h.x = fract(h.x + 0.5 * mod(cell.y, 2.0));  // running-bond row stagger
				vec3 rv = g + h - fp;
				// Shift and squash along Y: the lobe hangs BELOW its own row, over the row under it.
				rv.y = (rv.y + 0.20) * 1.25;
				float lobe = 1.0 - smoothstep(0.30, 0.95, length(rv));
				// Higher row wins outright; within a row the nearer lobe wins.
				float key = (lobe > 0.0) ? (float(j) * 4.0 + lobe) : -1e9;
				if (key > best) { best = key; under = max(under, top); top = lobe; }
				else { under = max(under, lobe); }
			}
		}
	}
	// Where a buried scale is much higher than the one covering it, we are under an overhanging
	// free edge. That is the crease, and it is the whole reason this reads as overlap.
	float occl = smoothstep(0.05, 0.40, under - top);
	float d = (top - occl * 0.55) - 0.4442;
	s.tint = vec3(1.0 + d * 0.32 * strength * lod);
	s.height = d * strength * lod;
	// Creases hold grime; the domed face of a scale is the smooth part.
	s.rough = (0.05 + occl * 0.16) * strength * lod;
	s.bump = vec3(d) * 0.11 * strength * lod;
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
