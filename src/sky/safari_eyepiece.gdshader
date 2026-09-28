shader_type canvas_item;
render_mode blend_mix, unshaded;
#include "res://src/sky/lane_sky.gdshaderinc"
// SPIKE (2026-09-21, scratch only). WHAT YOU SEE THROUGH THE BRASS SPYGLASS WHILE THE SHIP MOVES.
//
// This is sky_eyepiece.gdshader's job done for a flight instead of for a tripod. Three differences,
// and each one is forced by the run rather than chosen:
//
//  1. THREE SUBJECTS AT ONCE, not one. Two things overlap on purpose (safari_cast.gd), and on a
//     safari you have to SEE both to feel the loss of the one you let go. Each slot is its own set
//     of plain scalar uniforms - no uniform arrays - because the phone build is WebGL2 and a
//     dynamically indexed uniform array is the first thing to go wrong there.
//  2. SIX SHAPES, not three. comet, drift pod, ice, derelict, moon rim, world below.
//  3. THE FIELD MOVES. `look` scrolls the star grid as you swing the scope, and `run` shears it
//     along the lane, so the glass is never still: you are flying. The standing scope's field was
//     nailed down and that is half of why a night at it felt like a menu.
//
// MOMENTS. `sN_moment` is 0..1. It is not a sparkle layer bolted on top: each shape OPENS with it -
// a driftling turns its face to you, the comet's tail forks, the derelict's lamp comes on, the ice
// lights up what is inside. Same subject, visibly different picture, which is what makes "I got
// the one where it looked at me" a thing a player can say.
//
// DEFOCUS is still one uniform per subject widening every falloff and dividing every peak, which
// is what a real lens does. Here it is a RANGE error - things are at different distances - so two
// subjects in one field can be sharp and soft at the same time, and that reads instantly.
//
// Everything is procedural. No texture is sampled anywhere.

// THE WINDOW IS A WINDOW NOW (2026-09-21, cockpit). It was a circle floating in black space; the
// user asked for the inside of the ship instead, so the glass is a wide rounded rectangle and the
// hull is drawn around it. `aspect` is the opening's width / height; the shader works in q-space
// where q.y spans +-1 (one FIELD_HALF_DEG) and q.x spans +-aspect, so degrees-per-pixel is the
// same in both axes and the wide window simply SHOWS MORE SKY sideways. Nothing about scoring
// changed: safari_run.gd still scores on the radial field distance it always did.
uniform float aspect = 1.0;
uniform float corner : hint_range(0.0, 1.0) = 0.22;
uniform float field_deg = 7.0;

uniform vec2 look = vec2(0.0);     // scope heading, radians, for scrolling the star field
uniform float run = 0.0;           // seconds into the run, for the lane shear
uniform float t = 0.0;
uniform float sky_light : hint_range(0.0, 1.0) = 0.0;
uniform float seed = 1.0;

// LOOK uniforms, shared with the brass spyglass and feeding nothing back into the scoring.
uniform float swim : hint_range(0.0, 1.0) = 0.0;
uniform float warm : hint_range(0.0, 1.0) = 0.0;
uniform float flash : hint_range(0.0, 1.0) = 0.0;

uniform int n_subj : hint_range(0, 3) = 0;

// ---------------------------------------------------------------- ROUND 2: WHERE AM I POINTING
// The user, on the first safari frames: "There's no real clear sense of direction as you're moving
// through space and looking around." Inside the glass that was literally true - the field was a
// star grid SLID by the heading, so every direction looked the same and nothing outside got in.
// Four things go across from space_lane.gd now, and each answers one half of that sentence:
//
//   `flow_from`  where the ship is HEADING, in field radii. The dust streams radially away from it,
//                so pointing down the lane blooms the field out of its centre and pointing abeam
//                makes every fleck run one way across it. Your heading, readable with no HUD.
//   `dest_*`     the destination, magnified. Raise the glass at it and there is a world in there,
//                growing run by run. This is the "point of reference" the user asked for.
//   `home_*`     the same for the world you left, over your shoulder.
//   `sun_at`     where the one sun is, so the crescents on both worlds agree with the lit sides of
//                the subjects and with the hulls outside the window.
uniform vec2 flow_from = vec2(0.0);
uniform float field_half = 0.12217305;   // 7 deg in radians; SafariCast.FIELD_HALF_DEG
uniform vec2 dest_pos = vec2(40.0);
uniform float dest_r = 0.0;
uniform vec4 dest_col : source_color = vec4(0.54, 0.37, 0.76, 1.0);
uniform vec4 dest_air : source_color = vec4(0.64, 0.46, 0.89, 1.0);
uniform vec2 home_pos = vec2(40.0);
uniform float home_r = 0.0;
uniform vec4 home_col : source_color = vec4(0.29, 0.48, 0.35, 1.0);
uniform vec4 home_air : source_color = vec4(0.41, 0.66, 0.88, 1.0);
uniform vec2 sun_at = vec2(-6.0, -3.0);

// ================================================================ safari6 (2026-09-21): THE WIDE
// WINDOW, THE FAR MARKS, THE HORIZON AND THE RAIL.
//
// A real person flew this twice and caught nothing. The cause, measured in
// docs/SAFARI_FLIGHT_SPEC.md 1 and 6.1: the glass showed a 14-degree circle out of a reachable sky
// of 360 x 108 degrees - 0.46 percent of it, one part in 217 - and `field_half` below was NEVER
// WRITTEN by the flight, so the only knob that could have widened it sat at its 7-degree default
// while safari_run.gd dutifully set `field_deg`, which this shader does not read.
//
// `field_half` is now written every frame by SafariRun.field_half_deg(): 28 degrees lowered (a
// 56-degree window, where you look around and plan) and 7 degrees raised (exactly the old glass,
// for the shot). Three consequences run through the rest of this file:
//
//   * GLASS UNITS ARE NO LONGER 7 DEGREES. `p` still spans +-1 across the opening, but one unit is
//     now `field_half`, not a fixed 7 deg. Anything that turned a glass distance into an ANGLE had
//     to be fixed, and doing so removed a magic `* 7.0` that was wrong at any field (see `theta`
//     and `world_disc`'s `sep`).
//   * `field_ref` is the field the ART was drawn against (7 deg). Anything that should keep its
//     SCREEN size rather than its angular size divides by it - that is `star_rad`, below.
//   * SCORING DOES NOT LIVE HERE AND DOES NOT MOVE. safari_run.gd scores on absolute degrees off
//     the crosshair (CENTRE_DEG 2.10, EDGE_DEG 5.46) and sends `centre_rad` only so the rail can
//     keep out of the bullseye.
uniform float field_ref = 0.12217305;    // 7 deg in radians: the field the art was authored at
uniform float star_rad = 0.42;           // star PSF, kept SCREEN-sized: 0.42 * field_half/field_ref
uniform float centre_rad = 0.03665191;   // CENTRE_DEG (2.10 deg) in radians
// ROUND 2: `edge_rad` is GONE. The rail's keep-out used to fade from centre_rad out to it, which
// is why the rail's tip was invisible for 5.46 degrees around the crosshair and appeared to stop
// short of the planet. Nothing else in this shader ever needed the scoring disc's outer radius.

// ---- R1, THE FAR MARKS. Every sight that is up and uncaught gets a mark at its TRUE angular
// position, so the sky is never empty and you can turn toward a thing before you can frame it.
// ONE UNROLLED BLOCK OF FIXED UNIFORMS, not an array: lines 11-12 say why - the phone build is
// WebGL2 and a dynamically indexed uniform array is the first thing to go wrong there.
// xy = position in glass units, z = radius in glass units, w = strength (0 = the slot is off).
// The mark does NOT score: safari_run.gd never reads it back. It hands over to the real shape as
// the sight comes inside the drawn field, so nothing is ever drawn twice.
uniform int n_mark = 0;
uniform vec4 mk0 = vec4(0.0);
uniform vec4 mk1 = vec4(0.0);
uniform vec4 mk2 = vec4(0.0);
uniform vec4 mk3 = vec4(0.0);
uniform vec4 mk4 = vec4(0.0);
uniform vec4 mk5 = vec4(0.0);
uniform vec4 mk6 = vec4(0.0);
uniform vec4 mk7 = vec4(0.0);

// ---- R2, THE HORIZON BAND. 0 turns it off (for an A/B); 1 is the shipped strength.
uniform float aurora = 1.0;

// ---- R3, THE GOLD RAIL. The lane's floor, one world-radius below the lane axis, so its far end
// arrives exactly on the destination's lower limb. It is a GREAT CIRCLE ARC, because every point
// of a straight lane at a constant offset lies in one plane through the eye - so the whole rail is
// three unit vectors and two angles, with no loop over samples. When the route starts to wind
// (R8), `rail_far` and `rail_n` follow it and the arc bends with it.
//   rail_far   the far end, in the lane frame: the destination's direction
//   rail_near  the near end: straight down the ship's own floor
//   rail_n     the arc's plane normal, normalize(cross(rail_near, rail_far))
//   rail_smin  angle from rail_far at which the rail STOPS - atan(rail_h / destination distance)
//   rail_h     the offset below the axis, in metres (SpaceLane.WORLD_RADIUS)
//   rail_gap   sleeper spacing in metres (SpaceLane.GATE_GAP), and rail_phase how far we have flown
uniform float rail_on = 0.0;
uniform vec3 rail_far = vec3(0.0, 0.0, -1.0);
uniform vec3 rail_near = vec3(0.0, -1.0, 0.0);
uniform vec3 rail_n = vec3(-1.0, 0.0, 0.0);
uniform float rail_smin = 0.05;
uniform float rail_h = 143.0;
uniform float rail_gap = 80.0;
uniform float rail_phase = 0.0;
// WAVE 3 (G5): the rail_* uniforms above are still written by safari_run.gd (its _feed_rail) but
// are NO LONGER READ here - R10 replaced the one great-circle rail with the two-rail track below,
// fed by space_lane.gd. `rail_on` is the one that is still read: it is the scope-down / --no-rail
// switch, and it gates the track exactly as it gated the rail.

// ---- R8: THE SHIP TURNS. space_lane.gd's route winds and climbs; this is the ship's heading as a
// basis (columns: right, up, back, in lane-zero coordinates). Everything that belongs to the WORLD -
// the stars, the nebula, the aurora's plane - is looked up through it. Everything that belongs to
// the SHIP - the sights, the far marks, the reticle, the dust stream - is not, because
// safari_lanes.gd places the sights in the ship's own frame. Identity = the old straight lane.
uniform mat3 ship_basis = mat3(1.0);

// ---- R10: THE TRACK UNDER THE HULL. Two rails, TRK_N points each, in METRES in the ship's frame
// (x right, y up, -z forward), from under the hull down the route to the destination's
// centre. `trk_s` is each point's distance along the route, which is what the sleepers are laid on.
// Indexed only by a for-loop counter against a constant bound - a constant-index-expression, which
// even WebGL1 guarantees - never by a computed index.
const int TRK_N = 24;
uniform vec3 trk_l[24];
uniform vec3 trk_r[24];
// PRECOMPUTED ONCE A FRAME in space_lane.gd, not once a pixel - measured: with them worked out
// here the track cost 1.9 ms per porthole-sized pass at 2556x1179 on this Mac (heat bench, 8
// copies), more than the whole rest of the glass.
//   trk_nl / trk_nr  xyz: the unit normal of piece k's great-circle plane; w: the rail's angular
//                    half-width at the piece's nearer end (TRK_RAIL_M / distance), or -1 when the
//                    piece is degenerate and must be skipped
//   trk_pc           a cone that contains ALL of piece k - both rails, their glow and its sleepers:
//                    xyz unit axis, w cos(half-angle). The first test every pixel meets, and the
//                    only one most pixels ever meet, per piece.
//   trk_q            the sleeper quad k's plane: xyz unit normal, w its offset (n . L0)
uniform vec4 trk_nl[24];
uniform vec4 trk_nr[24];
uniform vec4 trk_pc[24];
uniform vec4 trk_q[12];
uniform float trk_s[24];
uniform float trk_gap = 10.0;
uniform float trk_w = 2.5;

uniform int s0_kind = 0;
uniform vec2 s0_pos = vec2(9.0);
uniform float s0_blur = 0.0;
uniform float s0_scale = 1.0;
uniform float s0_moment = 0.0;
uniform float s0_seed = 1.0;
uniform vec4 s0_a : source_color = vec4(0.6, 0.8, 1.0, 1.0);
uniform vec4 s0_b : source_color = vec4(1.0, 0.9, 0.7, 1.0);
// TWELVE SHAPE KNOBS per sight (2026-09-21, shapes round). All zero = the classic
// composition for that branch, so an unwired caller still draws a picture. f2.w is the
// subject rotation in radians. safari_shapes.gd holds the numbers and what they mean.
uniform vec4 s0_f1 = vec4(0.0);
uniform vec4 s0_f2 = vec4(0.0);
uniform vec4 s0_f3 = vec4(0.0);

uniform int s1_kind = 0;
uniform vec2 s1_pos = vec2(9.0);
uniform float s1_blur = 0.0;
uniform float s1_scale = 1.0;
uniform float s1_moment = 0.0;
uniform float s1_seed = 2.0;
uniform vec4 s1_a : source_color = vec4(0.6, 0.8, 1.0, 1.0);
uniform vec4 s1_b : source_color = vec4(1.0, 0.9, 0.7, 1.0);
// TWELVE SHAPE KNOBS per sight (2026-09-21, shapes round). All zero = the classic
// composition for that branch, so an unwired caller still draws a picture. f2.w is the
// subject rotation in radians. safari_shapes.gd holds the numbers and what they mean.
uniform vec4 s1_f1 = vec4(0.0);
uniform vec4 s1_f2 = vec4(0.0);
uniform vec4 s1_f3 = vec4(0.0);

uniform int s2_kind = 0;
uniform vec2 s2_pos = vec2(9.0);
uniform float s2_blur = 0.0;
uniform float s2_scale = 1.0;
uniform float s2_moment = 0.0;
uniform float s2_seed = 3.0;
uniform vec4 s2_a : source_color = vec4(0.6, 0.8, 1.0, 1.0);
uniform vec4 s2_b : source_color = vec4(1.0, 0.9, 0.7, 1.0);
// TWELVE SHAPE KNOBS per sight (2026-09-21, shapes round). All zero = the classic
// composition for that branch, so an unwired caller still draws a picture. f2.w is the
// subject rotation in radians. safari_shapes.gd holds the numbers and what they mean.
uniform vec4 s2_f1 = vec4(0.0);
uniform vec4 s2_f2 = vec4(0.0);
uniform vec4 s2_f3 = vec4(0.0);

float h21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7)) + seed) * 43758.5453);
}


// ---------------------------------------------------------------- a world, seen through the glass
// Not a copy of lane_globe.gdshader - it cannot be, this is a 2D field and that is a mesh - but it
// is the same PICTURE: a hard limb, a terminator that is a curve and not a line, a dark side that
// is not black, and a bright air shell. `R` is its radius in field radii, straight off
// atan(radius / distance), so it grows in the glass at exactly the rate it grows in the window.
vec3 world_disc(vec2 q, float R, vec3 base, vec3 air, vec2 sun_rel, float sd, out float occl) {
	occl = 0.0;
	if (R < 0.004) {
		return vec3(0.0);
	}
	float d = length(q) / R;
	float edge = 0.045 / max(R, 0.02);           // a couple of pixels of limb, at any size
	float disc = smoothstep(1.0, 1.0 - edge, d);
	occl = disc;
	// the sun, as a 3D direction: `sun_rel` is how far off the world's middle it is, in glass units,
	// so one unit is `field_half` RADIANS. The `* 7.0` that used to be here was wrong at any field
	// (it made a 7-degree offset read as 49 degrees) and it became visible the moment the window
	// could change width, so it is gone rather than rescaled.
	float sep = length(sun_rel) * field_half;
	vec2 sdir = length(sun_rel) > 0.0001 ? normalize(sun_rel) : vec2(-1.0, 0.0);
	vec3 sun3 = vec3(sdir * sin(clamp(sep, 0.0, 1.5707963)), cos(clamp(sep, 0.0, 1.5707963)));
	vec3 n = vec3(q / max(R, 0.0001), sqrt(max(1.0 - d * d, 0.0)));
	float lam = dot(n, sun3);
	// R11 (wave 3): A TOON WORLD, the way the rocket flight draws the neighbours' planets. It was a
	// photographic ball - three octaves of noise continents, a Lambert ramp, embers on the night side
	// and a bright air halo. Now: a crisp terminator with a LAVENDER shade side (STYLE_GUIDE
	// "Lighting": cool tinted shadows, the toon shader's shade_tint), two flat land tones with a
	// clean coastline, and a thin rim of the world's own air colour on the lit limb only.
	float lit = smoothstep(-0.03, 0.09, lam);
	vec3 sn = vec3(n.x, n.y, n.z) * 2.6 + sd;
	float g = lane_vnoise(sn.xy + sn.z * 0.7) * 0.65
		+ lane_vnoise(sn.xy * 2.1 + sn.z * 1.6 + 9.0) * 0.35;
	float coast = smoothstep(0.50, 0.535, g);
	vec3 ground = mix(base * 0.82, base * 1.10, coast);
	vec3 shade = ground * vec3(0.44, 0.42, 0.62);
	vec3 col = mix(shade, ground, lit) * disc;
	// the lit limb's thin rim, and a whisper of air just outside it (R2.1: thin atmosphere)
	float rim = smoothstep(0.78, 0.98, d) * disc * smoothstep(-0.1, 0.5, lam);
	col = mix(col, air * 0.95, rim * 0.45);
	float shell = exp(-(d - 1.0) * (d - 1.0) / 0.0018) * (1.0 - disc);
	col += air * shell * (0.10 + 0.22 * smoothstep(-0.3, 0.5, lam));
	return col;
}

// ---------------------------------------------------------------- ROUND 3: TWELVE KNOBS, SIX BRANCHES
// THE PROBLEM THIS SOLVES, measured before it was fixed. The first contact sheet of all 51 sights
// (showcase/safari_sheet.gd) came back as SIX PICTURES, not 51. Every sight on a branch drew the
// identical composition and differed only in two tint colours and one scale: home's aurora, Fen's
// lamp line, the shadow line over Fen, Vela's frost crown, the dust veil, the fog on the pools,
// the heat shimmer and the glass tide were all the same curtains on the same limb. Ten sights, one
// picture. The same for the ten on the pod branch, the ten on ice, the eight on moonrim.
//
// It was also worse than "the branches repeat": safari_run.gd sets `sN_seed` from the SLOT index
// (float(i) * 3.7 + 1.3), so the sight's own identity never reached the shader at all. Two
// different sights caught in the same slot got byte-identical noise.
//
// THE FIX IS NOT MORE BRANCHES. Twelve floats per sight (three vec4s) are AMPLITUDES, COUNTS and
// ANGLES, so one piece of code draws a curtain of light or a row of lamps or a fog bank depending
// on which amplitude is non-zero. The expensive overlays sit behind `if (amount > 0.002)`, which
// is a UNIFORM-COHERENT branch - every fragment in the draw takes the same side of it - rather
// than a new per-kind branch that would widen the shader for all three slots at once. That is the
// whole reason 51 distinct pictures cost about what 6 did; the number is in the report.
//
// `f2.w` IS ALWAYS THE ROTATION, in radians, applied to the whole subject before anything else.
// One mat2 multiply, free, and it is the single cheapest thing that breaks sameness: a hull on a
// different diagonal, a pod line running up the glass instead of across it, a comet pointing at a
// different corner. Nothing else in the shader reads f2.w.
//
// ZERO MEANS CLASSIC. If a caller has not been wired up yet (safari_run.gd is another round's
// file tonight), f1.x arrives as 0 and the branch substitutes the composition the sight had
// before this round, so an unwired build still draws a picture instead of an empty field.
// safari_shapes.gd is the one place the real numbers live, and SafariShapes.apply() is the one
// call that sets them.
const vec4 CL1[6] = vec4[6](
	vec4(1.00, 1.00, 0.00, 1.00),        // comet:    core, tails, rays, nuclei
	vec4(5.00, 0.115, 0.042, 0.230),     // pod:      count, long axis, short axis, spacing
	vec4(4.00, 0.105, 0.00, 9.00),       // ice:      chunks, size, swarm, swarm scale
	vec4(0.300, 0.058, 1.00, 1.00),      // derelict: half-length, half-height, bridge, fins
	vec4(0.300, 0.90, 0.00, 0.00),       // moonrim:  radius, phase, pebbles, ring
	vec4(1.00, 0.62, 4.00, 0.42)         // limb:     curtains, height, count, lean
);
const vec4 CL2[6] = vec4[6](
	vec4(1.00, 0.00, 0.30, 0.00),        // comet:    tail length, static fork, dust curve, ROT
	vec4(0.00, 0.00, 1.00, 0.00),        // pod:      arc, scatter, fin, ROT
	vec4(0.00, 0.00, 0.25, 0.00),        // ice:      streak, spines, spread, ROT
	vec4(1.00, 0.00, 0.00, 0.00),        // derelict: mast, sheets, sheet size, ROT
	vec4(1.00, 0.00, 0.00, 0.00),        // moonrim:  craters, mirror, flare, ROT
	vec4(0.00, 0.00, 0.00, 0.00)         // limb:     haze wedge, slant, ripple, ROT
);
const vec4 CL3[6] = vec4[6](
	vec4(0.00, 0.30, 2.50, 0.00),        // comet:    halo, nucleus spread, tail bearing, -
	vec4(0.00, 0.00, 0.00, 1.00),        // pod:      lamps, crust, streak, wobble
	vec4(0.00, 0.50, 0.35, 0.00),        // ice:      backlight, bit hardness, tumble, -
	vec4(1.00, 0.00, 0.00, 0.00),        // derelict: lamp, lit glass, gantry arm, -
	vec4(0.055, 0.00, 0.00, 0.00),       // moonrim:  earthshine, -, -, -
	vec4(0.00, 0.00, 0.00, 0.00)         // limb:     lamps, lamp width, fog bank, terminator
);

float sh_h(float x) {
	return fract(sin(x * 91.3458) * 47453.5453) - 0.5;
}

// ---------------------------------------------------------------- the six shapes
// Each returns light, and writes how much of the background it HIDES into `occl`. A glow hides
// nothing; a hull hides everything behind it. Getting that wrong is what makes stars shine through
// a moon and the whole thing read as a sticker.
vec3 shape(int kind, vec2 q0, float bl, vec3 ca, vec3 cb, float mo, float sd, float tt,
		vec4 f1, vec4 f2, vec4 f3, out float occl) {
	occl = 0.0;
	vec3 s = vec3(0.0);
	int ki = clamp(kind, 0, 5);
	if (f1.x <= 0.0 && f1.y <= 0.0) {
		f1 = CL1[ki];
		f2 = CL2[ki];
		f3 = CL3[ki];
	}
	// the one rotation, before anything else
	float ro = f2.w;
	float cr = cos(ro);
	float sr = sin(ro);
	vec2 q = vec2(q0.x * cr - q0.y * sr, q0.x * sr + q0.y * cr);

	if (ki == 0) {
		// COMET / GLARE / COMBED STREAK. One piece of code, three readings:
		//   core=1 tails=1 rays=0   a comet: nucleus, coma, a forked ion tail and a curved dust tail
		//   core=1 tails=0 rays=1   a glare: a hard star with four spikes and, optionally, a halo
		//                           ring. Two of them side by side are the false suns.
		//   core=0 tails=1 rays=0   the star's wind: a combed streak with nothing at its head
		// THE MOMENT still forks the ion tail, and on a rays-only sight it flares the spikes.
		float core_k = f1.x;
		float tail_k = f1.y;
		float rays_k = f1.z;
		float cnt = max(f1.w, 1.0);
		float tlen = max(f2.x, 0.25);
		float fork0 = f2.y;
		float curve = f2.z;
		float halo_k = f3.x;
		float spread = f3.y;
		float bearing = f3.z;
		vec2 dir = vec2(cos(bearing), sin(bearing));
		// ---------------------------------------------------------------- A COMB, NOT A THIRD FAN
		// ROUND 4 (the "five families" round). The star's wind, Comet Thistle and the Returner came
		// back from the contact sheet as ONE FAN IN THREE TINTS, and the reason was structural: a
		// tail always leaves ONE point, so every comet-branch sight is a wedge radiating from a head
		// however the knobs are set. The star's wind is not a comet at all - the catalogue calls it
		// "long soft streaks, all combed one way" - so when there is no head and no glare (core and
		// rays both off) this draws SIX PARALLEL LANES that run right out of the field and never
		// meet. Parallel vs radiating is a difference a person names without being told what to
		// look for, and it costs one loop that only this sight ever enters.
		// The lane count is fixed at 6 on purpose: f1.w is the NUCLEUS count everywhere else and
		// tools/safari_shapes_selftest.gd checks it against the loop bound of 3. `spread` (f3.y) is
		// the gap between lanes, `curve` (f2.z) the sag along them.
		if (core_k <= 0.002 && rays_k <= 0.002) {
			float across_c = dot(q, vec2(-dir.y, dir.x));
			float along_c = dot(q, dir);
			float gap = 0.34 + 0.70 * spread;
			for (int i = 0; i < 6; i++) {
				float fi = float(i);
				float off = (fi - 2.5) * gap + gap * 0.22 * sh_h(fi * 5.1 + sd);
				float sag = curve * (along_c * along_c - 0.30);
				float dd2 = across_c - off + sag;
				float wv = (0.030 + 0.010 * sh_h(fi * 3.3 + sd + 1.0)) * (1.0 + 2.2 * bl);
				float line = exp(-dd2 * dd2 / (wv * wv));
				// combed, so the brightness runs ALONG the lane and thins at both ends
				line *= 0.45 + 0.55 * (0.5 + 0.5 * sin(along_c * 2.6 + fi * 1.7 + tt * 0.22));
				line *= 1.0 - smoothstep(0.80, 1.50, abs(along_c));
				s += mix(ca, cb, 0.30 + 0.35 * sh_h(fi * 7.9 + sd)) * line * tail_k
					* (0.55 + 0.45 * mo) * 1.05 / (1.0 + 1.3 * bl);
			}
			return s;
		}
		for (int i = 0; i < 3; i++) {
			float fi = float(i);
			if (fi + 0.5 > cnt) { continue; }
			float szi = (i == 0) ? 1.0 : 0.58;
			vec2 c = (i == 0) ? vec2(0.0)
				: vec2(sh_h(fi * 3.1 + sd), sh_h(fi * 7.7 + sd + 2.0)) * spread * 2.0;
			vec2 qq = (q - c) / szi;
			float k = 1.0 / (1.0 + 2.6 * bl);
			if (tail_k > 0.002) {
				float fork = fork0 + mo * 0.34;
				float acc = 0.0;
				for (int j = 0; j < 2; j++) {
					float sgn = float(j) * 2.0 - 1.0;
					float ang = sgn * fork;
					vec2 d2 = vec2(dir.x * cos(ang) - dir.y * sin(ang),
						dir.x * sin(ang) + dir.y * cos(ang));
					float along = dot(qq, d2);
					float across = dot(qq, vec2(-d2.y, d2.x));
					float fwd = max(along, 0.0);
					float gate = smoothstep(-0.03, 0.02, along);
					float w1 = 0.020 + 0.115 * fwd + 0.095 * bl;
					acc += exp(-across * across / (w1 * w1))
						* exp(-fwd * 1.45 / tlen) * gate * (0.5 + 0.5 * mo);
				}
				float along0 = dot(qq, dir);
				float across0 = dot(qq, vec2(-dir.y, dir.x));
				float fwd0 = max(along0, 0.0);
				float gate0 = smoothstep(-0.03, 0.02, along0);
				float across2 = across0 + curve * fwd0 * fwd0 + curve * 0.4 * fwd0;
				float w2 = 0.080 + 0.36 * fwd0 + 0.13 * bl;
				float dust = exp(-across2 * across2 / (w2 * w2)) * exp(-fwd0 * 1.05 / tlen) * gate0;
				s += (ca * acc * 1.15 + cb * dust * 0.72) * tail_k * szi;
			}
			if (core_k > 0.002) {
				float d2q = dot(qq, qq);
				float coma = exp(-d2q / (0.0032 + 0.028 * bl));
				float core = exp(-d2q / (0.00030 + 0.0080 * bl));
				s += (mix(ca, vec3(1.0), 0.40) * coma * 1.05
					+ vec3(0.94, 0.96, 1.0) * core * 1.45) * k * core_k;
			}
			if (rays_k > 0.002) {
				// a four-spike star: two crossed gaussian blades, flaring with the moment
				float fl = rays_k * (0.75 + 0.55 * mo);
				float wr = 0.0011 + 0.013 * bl;
				float bx = exp(-qq.y * qq.y / wr) * exp(-abs(qq.x) * 2.3);
				float by = exp(-qq.x * qq.x / wr) * exp(-abs(qq.y) * 2.3);
				s += mix(ca, vec3(1.0), 0.55) * (bx + by) * fl * 0.85;
			}
			if (halo_k > 0.002) {
				// A RING ROUND THE HEAD. It used to live inside the glare branch, so only the false
				// suns could have one; a comet with a big coma envelope is a real thing and it is
				// what makes the Returner the one sight in its family you cannot mistake.
				float L = length(qq);
				float hr = 0.34;
				s += cb * exp(-(L - hr) * (L - hr) / (0.0016 + 0.03 * bl)) * halo_k * 0.55;
			}
		}

	} else if (ki == 1) {
		// A SCHOOL, A FLOCK, OR ONE ANIMAL. count 1..6 bodies on a line that can be bowed into an
		// arc, shaken into a scatter, stretched from a round driftling into a long eel, crusted
		// into a barnacle, given wings or a motion streak or a lamp of its own.
		//   count 5, ax 0.115, ay 0.042, arc 0, scatter 0   -> the old pod, exactly
		//   count 1, ax 0.40,  ay 0.20                      -> one large sleeping animal
		//   count 6, scatter 0.30, fin 0.9                   -> moths, all over the field
		// THE MOMENT still turns the middle body: it rounds out of a lens into a disc and two eye
		// lights come on.
		float cnt = clamp(f1.x, 1.0, 6.0);
		float ax0 = max(f1.y, 0.01);
		float ay0 = max(f1.z, 0.004);
		float spc = f1.w;
		float arc = f2.x;
		float scat = f2.y;
		float fin = f2.z;
		float lamp = f3.x;
		float crust = f3.y;
		float strk = f3.z;
		float wob = f3.w;
		// ---------------------------------------------------------------- ROUND 4: THREE POD MODES
		// The contact sheet's second family was "the same teal blobs at three sizes", and its fifth
		// was "one pale oval, twice". Three sign/range flags on knobs that were already there turn
		// four of those sights into four different KINDS of thing, with no new branch and no new
		// uniform:
		//   lamp  > 1.0   LANTERN.  The bodies go nearly dark and the LAMP is the sight: it blinks
		//                 right out between beats, every body on its own phase. The moment pulls
		//                 the phases together, so "one blinks in time with your lamp" is real.
		//   fin   < 0     DARK FLECK. The body HIDES sky instead of adding light and carries one
		//                 hot rim down its lit edge. tower_swifts is "quick dark flecks" and was
		//                 drawn as a dim purple blob on a dim purple sky: it did not render at all.
		//                 This is the only sight in the game that is a hole with an edge.
		//   crust < 0     HOLLOW. No body, no occlusion, and the glow has its MIDDLE TAKEN OUT: a
		//                 ring of light with a dark centre that breathes. "A glow that goes out the
		//                 moment you look at it". The moment fills the centre back in.
		// HOISTED OUT OF THE LOOP, and this is the whole reason the pod branch is written this
		// way. The first cut put all three modes inside the six-body loop as one if/else chain,
		// and the paired bench measured +0.20 ms per full-screen copy on THREE SIGHTS THAT DO NOT
		// USE ANY OF THEM (showcase/look_bench.gd --set=b): the cost was the width of the loop
		// body, paid three times because shape() is inlined once per slot, not the modes running.
		// The hollow is one centred blob with no bodies at all, so it returns before the loop and
		// costs the loop nothing.
		float lantern = step(1.0, lamp);
		float rimlit = step(0.002, -fin);
		if (crust < -0.002) {
			// THE HOLLOW. A wide glow with a tighter one subtracted from it: a soft RING with a
			// dark middle, which is what "a glow that goes out the moment you look at it" is.
			// The breath floors at 0.42 on purpose - a breath that went to nothing made the sight
			// literally invisible on a frozen frame, which is the bug this round is fixing.
			float axh = max(f1.y, 0.01);
			float ayh = max(f1.z, 0.004);
			float eh = (q.x * q.x) / (axh * axh) + (q.y * q.y) / (ayh * ayh);
			float kin = 3.6 / (1.0 + 4.0 * bl);
			float inner = exp(-eh * kin);
			float ring = max(exp(-eh * (1.05 / (1.0 + 4.0 * bl))) - inner, 0.0);
			float breathe = 0.42 + 0.58 * pow(0.5 + 0.5 * sin(tt * 0.62 + sd), 2.0);
			s += mix(ca, cb, 0.35) * ring * 1.70 * breathe;
			// the moment is it lighting up again to see whether you left
			s += mix(ca, vec3(1.0), 0.25) * inner * mo * 0.95;
			return s;
		}
		float mid = (cnt - 1.0) * 0.5;
		float turn_i = floor(mid + 0.5);
		for (int i = 0; i < 6; i++) {
			float fi = float(i);
			if (fi + 0.5 > cnt) { continue; }
			float u = fi - mid;
			float ph = tt * (0.55 + 0.11 * fi) + sd * 2.0 + fi * 1.7;
			vec2 c = vec2(u * spc, arc * (u * u - mid * mid * 0.5));
			c += scat * vec2(sh_h(fi * 2.7 + sd) * 2.2, sh_h(fi * 5.3 + sd + 4.0) * 2.2);
			c += wob * vec2(0.030 * sin(ph * 0.8), 0.045 * sin(ph) + 0.17 * sin(fi * 1.9 + sd));
			vec2 r = q - c;
			float turn = (abs(fi - turn_i) < 0.5) ? mo : 0.0;
			float ax = ax0 * (1.0 + 0.17 * sin(ph * 0.6));
			float ay = mix(ay0, ax0 * 0.85, turn);
			float rot = 0.30 * clamp(wob, 0.12, 1.6) * sin(ph * 0.45 + fi);
			vec2 rr = vec2(r.x * cos(rot) - r.y * sin(rot), r.x * sin(rot) + r.y * cos(rot));
			float e0 = (rr.x * rr.x) / (ax * ax) + (rr.y * rr.y) / (ay * ay);
			// A CRUSTED BODY IS A DIFFERENT KIND OF EDGE, not just a wavier one. A pod body is a
			// soft gradient blob - full at 0.22 of its radius, gone at 1.0 - so putting an
			// angular wave on it only stretched that gradient and the barnacle came back twice as
			// an eight-pointed star. A crust gets a HARD rim with a lumpy outline instead, which
			// is what makes it read as a rock with an animal in it. The glow always keeps the
			// smooth radius.
			float body;
			if (crust > 0.002) {
				float pa = atan(rr.y, rr.x);
				// 7 + 13 + 3 at equal gains is a comb, and a comb on a radius is a ROSETTE: the
				// barnacle came back as a seven-petalled flower twice. A big 2-lobe term makes
				// the body lopsided first - an egg or a kidney - and the small harmonics are only
				// bumps on it.
				float lump = crust * (0.20 * sin(pa * 2.0 + sd * 1.9)
					+ 0.10 * sin(pa * 3.0 - sd * 1.3 + fi) + 0.07 * sin(pa * 7.0 + fi * 2.1));
				body = smoothstep(1.0 + lump + 0.5 * bl, 0.70 + lump, e0);
			} else {
				body = smoothstep(1.0 + 0.9 * bl, 0.05, e0);
			}
			float glow = exp(-e0 * (1.05 / (1.0 + 4.0 * bl)));
			vec3 col = mix(ca, cb, 0.35 + 0.35 * sin(fi * 2.1 + sd));
			if (rimlit > 0.5) {
				// THE DARK FLECK. It hides the sky (that is what makes it visible at all against a
				// star field) and one edge catches the low sun.
				occl = max(occl, body);
				float side = smoothstep(-0.25, 0.65, (-rr.y * 0.85 + rr.x * 0.55) / max(ax, 0.01));
				float rim2 = max(smoothstep(1.35 + 0.9 * bl, 0.62, e0)
					- smoothstep(1.00, 0.30, e0), 0.0);
				s += mix(cb, vec3(1.0), 0.30) * rim2 * side * 1.85;
				s += cb * body * 0.05;
			} else {
				s += col * (body * mix(0.62, 0.11, lantern) + glow * mix(0.30, 0.13, lantern));
				occl = max(occl, body * 0.85 * (1.0 - 0.80 * lantern));
			}
			if (fin > 0.002) {
				// wings or a trailing fin, out to the side and behind
				s += cb * fin * exp(-((rr.x + ax * 1.5) * (rr.x + ax * 1.5)) / (0.016 * fin + 0.05 * bl)
					- (rr.y * rr.y) / (0.0022 + ay * ay * 2.5 * fin + 0.02 * bl)) * 0.24;
			}
			if (strk > 0.002) {
				// a motion smear: long behind, and it does NOT occlude, so it reads as speed
				s += mix(ca, cb, 0.5) * strk * 0.30
					* exp(-(rr.y * rr.y) / (ay * ay * 0.9) ) * exp(-max(rr.x + ax, 0.0) * 0.0)
					* smoothstep(0.0, -ax * 6.0 * strk, rr.x) * smoothstep(-ax * 9.0 * strk, -ax, rr.x);
			}
			if (lamp > 0.002) {
				// OUT OF STEP is the sight. Each body carries its own phase; the moment pulls the
				// phases together so the school blinks as one.
				float lk = min(lamp, 1.0);
				float ph2 = tt * 1.7 + fi * 2.2 * (1.0 - 0.92 * mo) + sd * 1.3;
				float sw2 = max(sin(ph2), 0.0);
				float bk = mix(0.45 + 0.55 * pow(sw2, 3.0), 0.06 + 0.94 * pow(sw2, 6.0), lantern);
				float lr = mix(0.020, 0.040, lantern) + 0.05 * bl;
				s += vec3(1.0, 0.92, 0.70) * lk * bk
					* smoothstep(lr, 0.0, length(r - vec2(ax * 0.55, 0.0)));
				// a lantern also throws a soft pool of its own, which is what you actually see of
				// one of these from a lane away
				s += mix(cb, vec3(1.0, 0.94, 0.78), 0.5) * lk * lantern * bk * 0.55
					* exp(-dot(r, r) / (0.0075 + 0.05 * bl));
			}
			if (turn > 0.01) {
				for (int e2 = 0; e2 < 2; e2++) {
					vec2 ep = c + vec2(ax * 0.40, -0.018 + 0.036 * float(e2));
					s += vec3(1.0, 0.94, 0.78)
						* smoothstep(0.022 + 0.05 * bl, 0.0, length(q - ep)) * turn * 1.15;
				}
			}
		}

	} else if (ki == 2) {
		// ICE: a few big tumbling bodies, and/or a SWARM of small ones. The two are independent,
		// which is the whole point:
		//   chunks 4, swarm 0               -> the old four lumps
		//   chunks 0, swarm 1, streak 0.9   -> a squall: hundreds of streaking flecks, no lumps
		//   chunks 1, spines 1              -> a frost flower: one rock with radiating needles
		// THE MOMENT back-lights the biggest chunk and a dark curl shows through it.
		float cnt = f1.x;
		float sz = max(f1.y, 0.02);
		float swarm = f1.z;
		float sw_sc = max(f1.w, 1.0);
		float strk = f2.x;
		float spine = f2.y;
		float spread = max(f2.z, 0.02);
		float back = f3.x;
		float hard = clamp(f3.y, 0.0, 1.0);
		float tumble = f3.z;
		const float SZ[4] = float[4](1.00, 0.42, 0.68, 0.30);
		for (int i = 0; i < 4; i++) {
			float fi = float(i);
			if (fi + 0.5 > cnt) { continue; }
			float ph = tt * (0.22 + 0.07 * fi) * tumble * 3.0 + sd + fi * 2.3;
			vec2 c = vec2((fi - (cnt - 1.0) * 0.5) * spread * 1.8 + 0.05 * sin(ph * 0.7),
				spread * 2.4 * sh_h(fi * 2.7 + sd * 1.3) + 0.04 * cos(ph));
			float big = SZ[i];
			vec2 r = q - c;
			float rot = ph * 0.35;
			vec2 rr = vec2(r.x * cos(rot) - r.y * sin(rot), r.x * sin(rot) + r.y * cos(rot));
			float rad = sz * big;
			vec2 d1 = abs(rr) - vec2(rad * 1.20, rad * 0.86);
			float box1 = length(max(d1, 0.0)) + min(max(d1.x, d1.y), 0.0) - rad * 0.10;
			float rot2 = 0.95 + 0.30 * sin(sd + fi);
			vec2 r2 = vec2(rr.x * cos(rot2) - rr.y * sin(rot2), rr.x * sin(rot2) + rr.y * cos(rot2));
			vec2 d2i = abs(r2) - vec2(rad * 1.05, rad * 1.05);
			float box2 = length(max(d2i, 0.0)) + min(max(d2i.x, d2i.y), 0.0) - rad * 0.08;
			float sdf = max(box1, box2);
			float body = smoothstep(0.008 + 0.09 * bl, -0.008, sdf);
			occl = max(occl, body);
			float face = smoothstep(-rad * 0.9, rad * 0.9, -rr.y * 0.9 + rr.x * 0.45);
			s += mix(cb * 0.30, ca, face) * body * (0.42 + 0.58 * face);
			float edge = smoothstep(0.014 + 0.05 * bl, 0.002, abs(sdf + 0.007));
			s += mix(ca, vec3(1.0), 0.45) * edge * face * 0.85;
			if (spine > 0.002) {
				// FROST FLOWER: six needles growing out of the body, thin and bright
				float L = length(rr);
				float a6 = atan(rr.y, rr.x) * 3.0 + sd;
				float nd = pow(max(abs(cos(a6)), 0.0), 26.0);
				s += mix(ca, vec3(1.0), 0.5) * spine * nd
					* smoothstep(rad * 4.2, rad * 0.6, L) * smoothstep(rad * 0.5, rad * 1.1, L) * 1.1;
			}
			float bk = back + ((i == 0) ? mo : 0.0);
			if (bk > 0.01) {
				float inner = smoothstep(0.015, -0.05, sdf);
				vec2 ir = rr * (8.0 * 0.105 / max(sz, 0.02));
				float curl = smoothstep(0.58, 0.18,
					abs(length(ir) - 0.50 - 0.24 * sin(atan(ir.y, ir.x) * 2.0 + 1.2)));
				s += vec3(0.85, 0.94, 1.0) * inner * bk * 0.95;
				s -= vec3(0.72, 0.80, 0.94) * inner * curl * bk * 0.90;
			}
		}
		swarm *= 1.0 + 0.85 * mo;
		strk *= 1.0 + 1.10 * mo;
		spread *= 1.0 + 0.22 * mo;
		if (swarm > 0.002) {
			// THE SWARM, AND ROUND 4's FIX FOR IT. Two jittered cell layers, so it is hundreds of
			// bits and not four. It used to have exactly one shape - a round cloud of soft dots -
			// and four sights sat on it at four DENSITIES, which the contact sheet showed up as one
			// picture repeated: chrome dust, the snow lane, the squall and the scrap shoal.
			//
			// `f3.w` is the SWARM FORM, and it changes two things a person reads before they read
			// density: the ENVELOPE (what shape the crowd is) and the BIT (what one of them is).
			//   0  cloud   a round drift of soft dots                  (unchanged, the default)
			//   1  band    a long thin ribbon of fine hard glints      chrome_dust
			//   2  flakes   a still field of fat soft flakes, one in a while enormous, no drift
			//                                                          snow_lane
			//   3  wall    a hard STRAIGHT FRONT with streaks behind it snow_squall
			//   4  shards  a crowd of small angular lit chips          scrap_shoal
			// The form is a per-sight uniform, so every fragment in the draw takes the same side of
			// this branch; it is not three new shapes for every slot.
			int form = int(f3.w + 0.5);
			float w = mix(0.0050, 0.0011, hard) * (1.0 + 5.0 * bl);
			float env_q;
			float front = 0.0;
			if (form == 1) {
				// A BAND. Six times longer than it is wide, so it is a smear ACROSS the glass. The
				// rotation (f2.w) is what puts it on its diagonal.
				vec2 eb = vec2(q.x * 0.34, q.y * 2.15) / max(spread, 0.06);
				env_q = exp(-dot(eb, eb) * 0.58);
			} else if (form == 3) {
				// A WALL. The catalogue's own moment line is "the far edge is a clean straight
				// line", and a straight edge is the one thing no other swarm here has. It leans
				// (f2.w) and breathes; it does not wrap, so nothing ever pops.
				front = 0.16 + 0.10 * sin(tt * 0.33 + sd);
				env_q = smoothstep(front + 0.012, front - 0.030, q.x)
					* smoothstep(front - 1.45, front - 0.50, q.x);
				env_q *= exp(-q.y * q.y / (2.6 * spread * spread + 0.22));
				// packed hard up against the front, thinning out behind it
				env_q *= 1.0 + 1.5 * smoothstep(front - 0.42, front - 0.02, q.x);
			} else {
				// A DRIFT HAS EDGES. Without an envelope the swarm filled the field edge to edge and
				// read as a broken screen. `spread` is its radius, the knob that spaces the chunks.
				float sp2 = (form == 2) ? spread * 1.35 : spread;
				env_q = exp(-dot(q, q) / (2.2 * sp2 * sp2 + 0.03));
			}
			for (int k = 0; k < 2; k++) {
				// flakes hang; everything else drifts
				float drift = (form == 2) ? 0.0 : (0.20 + 1.9 * strk);
				vec2 g = q * sw_sc + vec2(float(k) * 0.41 + sd, float(k) * 0.27 - tt * drift);
				vec2 cell = floor(g);
				vec2 fr = fract(g) - 0.5;
				vec2 o = vec2(lane_h21(cell + 3.3), lane_h21(cell + 8.1)) - 0.5;
				float m = lane_h21(cell + 17.7);
				vec2 dv = fr - o * 0.80;
				float bit;
				float cut = 0.34;
				float solid = 0.0;
				if (form == 2) {
					// FLAKES: few, fat, soft, and about one cell in fourteen is a monster - the
					// catalogue's "one flake is the size of a door".
					// A GAUSSIAN WIDER THAN ITS CELL IS A SQUARE. The first attempt scaled the
					// radius by up to 75x and the whole sight came back as a grid of grey TILES,
					// because `dv` only runs to +-0.5 and the falloff never got to fall off. The
					// size is capped well inside the cell now and a radial cut kills the corners;
					// a big flake comes from a BIG CELL (a low swarm scale), not a fat gaussian.
					// A BIG BIT MUST STILL FIT INSIDE ITS CELL. `dv` cannot leave +-0.5, so
					// anything wider than that is CLIPPED SQUARE - twice in this round the lane
					// came back as a grid of grey tiles, first from a 75x gaussian and then from
					// a disc that the per-cell jitter pushed over the edge. So: the jitter is cut
					// to a fifth for flakes, the radius is capped, and a big flake comes from a
					// BIG CELL (swarm scale 3.4), which is the only way to get one honestly.
					cut = 0.58;
					vec2 dvf = fr - o * 0.16;
					float ldv = length(dvf);
					float fsz = min(w * (16.0 + 30.0 * m * m), 0.026);
					bit = exp(-dot(dvf, dvf) / fsz) * smoothstep(0.42, 0.22, ldv);
					// the door-sized one, about one cell in fourteen: a soft-edged DISC
					bit += step(0.93, m) * smoothstep(0.30, 0.09, ldv) * 0.85;
				} else if (form == 4) {
					// SHARDS: a rotated diamond with a hard edge and a bright lit side, so each bit
					// is a small SHARP thing you could cut yourself on, not a dot.
					cut = 0.50;
					float ra = m * 6.2832;
					vec2 dr2 = vec2(dv.x * cos(ra) - dv.y * sin(ra), dv.x * sin(ra) + dv.y * cos(ra));
					float rsz = 0.055 + 0.085 * m;
					float dia = abs(dr2.x) * 0.50 + abs(dr2.y) - rsz;
					float face2 = smoothstep(0.010 + 0.06 * bl, -0.004, dia);
					solid = face2;
					bit = face2 * 0.75
						+ smoothstep(0.014 + 0.06 * bl, 0.0, abs(dia + 0.005)) * 0.85;
				} else {
					bit = exp(-(dv.x * dv.x) / (w * (1.0 + strk * 22.0)) - (dv.y * dv.y) / w);
				}
				bit *= step(cut, m);
				solid *= step(cut, m);
				bit *= env_q;
				s += mix(cb, mix(ca, vec3(1.0), hard * 0.6), m) * bit * swarm * (0.45 + 0.85 * hard);
				occl = max(occl, max(bit * swarm * hard * 0.55, solid * env_q * swarm * 0.85));
			}
			if (form == 3) {
				// THE FRONT ITSELF: a soft lit edge, not a hairline. At 0.022 wide and 0.55 gain it
				// came back looking like a scratch on the lens; snow piled at a boundary is a band
				// you can see thickness in, it is brightest just behind the edge, and it frays.
				float fx = q.x - front;
				float fray = 0.70 + 0.30 * sin(q.y * 23.0 + sd * 3.1);
				float edge2 = smoothstep(0.010, -0.075, fx) * smoothstep(-0.16, -0.055, fx);
				s += mix(ca, vec3(1.0), 0.35) * swarm * 0.50 * edge2 * fray
					* exp(-q.y * q.y / (2.6 * spread * spread + 0.22));
			}
		}
		s = max(s, vec3(0.0));

	} else if (ki == 3) {
		// SOMETHING BUILT, AND DEAD. A hull whose proportions, superstructure, fins, mast, gantry
		// arm, lit glasshouse and hung sheets are all knobs, so the kettle, the mail hulk, the
		// Anvil, the seed barge, the sun-sail and the frozen laundry are six silhouettes and not
		// one. She is mostly SILHOUETTE: unlit, rim-lit along one edge, drawn by the sky behind her.
		// THE MOMENT is the lamp blinking, and on a sheeted wreck it also luffs the sheets.
		float hl = max(f1.x, 0.02);
		float hh = max(f1.y, 0.008);
		float brg = f1.z;
		float fnk = f1.w;
		float mstk = f2.x;
		float sails = f2.y;
		float ssz = max(f2.z, 0.02);
		float lampk = f3.x;
		float glass = f3.y;
		float gant = f3.z;
		float rot = 0.030 * sin(tt * 0.31 + sd);
		vec2 r = vec2(q.x * cos(rot) - q.y * sin(rot), q.x * sin(rot) + q.y * cos(rot));
		vec2 d = abs(r - vec2(0.0, 0.01)) - vec2(hl, hh);
		float hull = smoothstep(0.014 + 0.08 * bl, -0.008,
			length(max(d, 0.0)) + min(max(d.x, d.y), 0.0));
		vec2 d2 = abs(r - vec2(hl * 0.90, hh)) - vec2(hh * 1.3, hh * 1.3);
		float bite = smoothstep(0.012, -0.010, length(max(d2, 0.0)) + min(max(d2.x, d2.y), 0.0));
		hull = clamp(hull - bite, 0.0, 1.0);
		float body = hull;
		float bridge = 0.0;
		if (brg > 0.002) {
			vec2 bd = abs(r - vec2(-hl * 0.30, -hh * 1.3)) - vec2(hl * 0.24 * brg, hh * 0.70 * brg);
			bridge = smoothstep(0.012 + 0.07 * bl, -0.008,
				length(max(bd, 0.0)) + min(max(bd.x, bd.y), 0.0));
			body = clamp(body + bridge, 0.0, 1.0);
		}
		if (fnk > 0.002) {
			for (int fi2 = 0; fi2 < 2; fi2++) {
				float sgn2 = float(fi2) * 2.0 - 1.0;
				vec2 fd = abs(r - vec2(hl * 0.68, sgn2 * hh * 1.5))
					- vec2(hl * 0.13 * fnk, hh * 0.85 * fnk);
				body = clamp(body + smoothstep(0.011 + 0.06 * bl, -0.007,
					length(max(fd, 0.0)) + min(max(fd.x, fd.y), 0.0)), 0.0, 1.0);
			}
		}
		if (mstk > 0.002) {
			vec2 md = abs(r - vec2(-hl * 0.45, -hh * 2.7 * mstk))
				- vec2(0.011, hh * 1.75 * mstk);
			body = clamp(body + smoothstep(0.010 + 0.06 * bl, -0.006,
				length(max(md, 0.0)) + min(max(md.x, md.y), 0.0)), 0.0, 1.0);
		}
		if (gant > 0.002) {
			// THE ANVIL. A cross arm through the hull, which is what makes a lifter a T and not a
			// cigar. Two stubby legs hang off its ends.
			vec2 gd = abs(r - vec2(-hl * 0.10, -hh * 1.2)) - vec2(0.016, hh * 3.4 * gant);
			body = clamp(body + smoothstep(0.010, -0.006,
				length(max(gd, 0.0)) + min(max(gd.x, gd.y), 0.0)), 0.0, 1.0);
			vec2 ad = abs(r - vec2(-hl * 0.10, -hh * 4.3 * gant)) - vec2(hl * 0.62 * gant, 0.013);
			body = clamp(body + smoothstep(0.010, -0.006,
				length(max(ad, 0.0)) + min(max(ad.x, ad.y), 0.0)), 0.0, 1.0);
		}
		occl = body;
		float rim = body * smoothstep(hh * 1.2, hh * 0.28, abs(r.y + hh * 0.9))
			+ bridge * smoothstep(0.038, 0.008, abs(r.y + hh * 1.9)) * 0.8;
		s += ca * rim * 0.72 + ca * body * 0.055;
		if (glass > 0.002) {
			// A LIT HOLD. Something is still alive in there: a block of warm colour inside the
			// silhouette with bright mullions across it.
			vec2 gq = r - vec2(hl * 0.18, -hh * 0.15);
			vec2 gd2 = abs(gq) - vec2(hl * 0.42, hh * 0.55);
			float gb = smoothstep(0.010, -0.006,
				length(max(gd2, 0.0)) + min(max(gd2.x, gd2.y), 0.0));
			float mull = 0.55 + 0.45 * smoothstep(0.35, 0.0, abs(fract(gq.x * 14.0) - 0.5));
			s += cb * gb * glass * (0.55 + 0.30 * sin(tt * 0.7 + sd)) * mull;
		}
		if (sails > 0.002) {
			// SHEETS ON A SPAR. One big taut one is a sun-sail; four small slack ones are somebody's
			// washing. They CURVE, which is what stops them reading as more hull.
			for (int si = 0; si < 4; si++) {
				float fsi = float(si);
				if (fsi + 0.5 > sails) { continue; }
				float xo = (fsi - (sails - 1.0) * 0.5) * ssz * 2.5;
				float luff = (0.25 + 0.65 * mo) * sin(tt * 0.9 + fsi * 2.0 + sd);
				vec2 sq = r - vec2(xo, -hh * 2.2 - ssz * 0.9);
				sq.x += luff * 0.30 * (sq.y + ssz) * (sq.y + ssz) / max(ssz, 0.02);
				vec2 sd2 = abs(sq) - vec2(ssz * 0.80, ssz);
				float sheet = smoothstep(0.012 + 0.05 * bl, -0.004,
					length(max(sd2, 0.0)) + min(max(sd2.x, sd2.y), 0.0));
				occl = max(occl, sheet * 0.92);
				// lit face and a bright leading edge, so it is cloth catching a sun
				float lf = smoothstep(-ssz, ssz, -sq.y * 0.7 + sq.x * 0.5);
				s += mix(cb * 0.35, ca, lf) * sheet * (0.30 + 0.62 * lf);
				s += mix(ca, vec3(1.0), 0.35) * sheet
					* smoothstep(ssz * 0.55, ssz * 0.95, abs(sq.x)) * 0.35 * lf;
				// the line it hangs from
				s += ca * 0.30 * smoothstep(0.006, 0.0, abs(sq.y + ssz * 1.02))
					* step(abs(sq.x), ssz * 1.6);
			}
		}
		if (lampk > 0.002) {
			float lampn = (lampk > 1.0) ? 3.0 : 1.0;
			for (int li = 0; li < 3; li++) {
				float fl2 = float(li);
				if (fl2 + 0.5 > lampn) { continue; }
				float blink = mo * (0.55 + 0.45
					* pow(max(sin(tt * 2.1 + fl2 * 1.9), 0.0), 4.0));
				float base = (lampn > 1.0) ? 0.85 : 0.30;
				vec2 lp = vec2(-hl * 0.85 + fl2 * hl * 0.80, -hh * 1.1 - fl2 * hh * 0.4);
				float ld = length(r - lp);
				s += cb * lampk * smoothstep(0.016 + 0.05 * bl, 0.0, ld) * (base + 1.30 * blink);
				s += cb * lampk * exp(-ld * ld / (0.010 + 0.05 * bl)) * (base * 0.5 + blink) * 0.55;
				s += cb * lampk * body * exp(-max(r.x - lp.x, 0.0) * 5.5)
					* (base * 0.35 + blink) * 0.26;
			}
		}

	} else if (ki == 4) {
		// A MOON, OR SEVERAL. radius, PHASE (a hairline at 0.95, a half at 0.30, a gibbous at
		// -0.25), craters, a mirror sheen, a flare at the cusp, a ring band across the field, and
		// up to three pebbles in a row with it. THE MOMENT walks the terminator open by half a phase, so
		// the crescent grows while you watch it.
		float R = max(f1.x, 0.02);
		float phase = f1.y;
		float peb = f1.z;
		float ring = f1.w;
		float crat = f2.x;
		float mirr = f2.y;
		float flare = f2.z;
		float earth = f3.x;
		float soft = 0.010 + 0.075 * bl;
		vec3 ld = normalize(vec3(-0.86, -0.36, 0.36));
		float pd = length(q);
		float disc = smoothstep(R + soft, R - soft, pd);
		occl = disc;
		float nz = sqrt(max(1.0 - (pd * pd) / (R * R), 0.0));
		float lam = dot(normalize(vec3(q / R, nz)), ld);
		float open = mix(phase, phase - 0.54, mo);
		float lit = smoothstep(open - 0.10 - 0.30 * bl, open + 0.06, lam);
		float cr2 = 1.0;
		if (crat > 0.002) {
			vec3 mn = vec3(q / R, nz) * 3.1 + sd;
			float mg = lane_vnoise(mn.xy * 1.7 + mn.z * 0.8) * 0.62
				+ lane_vnoise(mn.xy * 4.3 + mn.z * 2.1 + 13.0) * 0.38;
			cr2 = 1.0 - crat * 0.34 * (1.0 - mg);
		}
		s += ca * disc * lit * (0.55 + 0.75 * mo) * cr2;
		s += cb * disc * earth * (1.0 - lit);
		float edge = disc * smoothstep(0.020 + 0.06 * bl, 0.0, abs(lam - open));
		s += mix(ca, vec3(1.0), 0.55) * edge * (0.60 + 1.10 * mo);
		if (mirr > 0.002) {
			// A POLISHED MOON: one tight specular arc, well inside the limb, that a rough moon
			// cannot have. No craters go with it.
			float sp = pow(max(lam, 0.0), 22.0);
			s += mix(ca, vec3(1.0), 0.75) * disc * sp * mirr * 1.5;
		}
		if (flare > 0.002) {
			// THE FLASH. One point on the cusp goes off, with two short blades.
			vec2 cusp = normalize(vec3(ld).xy) * R * -0.94;
			vec2 fq = q - cusp;
			float wf = 0.0009 + 0.012 * bl;
			float fl = flare * (0.30 + 1.50 * mo);
			s += mix(ca, vec3(1.0), 0.35) * fl
				* (exp(-dot(fq, fq) / (0.0006 + 0.006 * bl)) * 1.3
					+ exp(-fq.y * fq.y / wf) * exp(-abs(fq.x) * 7.0) * 0.8);
		}
		if (ring > 0.002) {
			// THE GAP. A ring band running across the field behind the moon, with a dark division
			// in it, so a shepherd moon is plainly IN something.
			float rb = abs(q.y * 3.1 + q.x * 0.55) ;
			float band = smoothstep(0.62, 0.30, rb) * smoothstep(0.02, 0.10, rb);
			band *= 0.70 + 0.30 * sin(q.x * 40.0 + sd);
			s += cb * band * ring * 0.38 * (1.0 - disc);
		}
		if (peb > 0.002) {
			// THE PEBBLES STAND IN A ROW with the moon (G5b, 2026-09-23). They were scattered by a
			// hash into a loose cluster, and with three of them the sight drew FOUR discs - while its
			// name, its blurb ("in a tidy row") and Grig's ask all say three, and Grig counts. Now
			// pebble i takes the next place along the row, alternating sides, each place one moon-
			// and-pebble width plus half a radius of sky from the last, so the gaps are equal and the
			// moon is the middle one. `peb` is the pebble count, so pebble_moons (the only sight with
			// pebbles) asks for 2: three discs.
			for (int i = 0; i < 3; i++) {
				float fi = float(i);
				if (fi + 0.5 > peb) { continue; }
				float pr = R * 0.80;
				float side = (mod(fi, 2.0) < 0.5) ? -1.0 : 1.0;
				vec2 pc = vec2(side * (floor(fi * 0.5) + 1.0) * (R + 0.5 * R + pr), 0.0);
				float dd = length(q - pc);
				float pdisc = smoothstep(pr + soft, pr - soft, dd);
				occl = max(occl, pdisc);
				float pn = sqrt(max(1.0 - (dd * dd) / (pr * pr), 0.0));
				float pl = dot(normalize(vec3((q - pc) / pr, pn)), ld);
				float plit = smoothstep(open - 0.16, open + 0.10, pl);
				s += ca * pdisc * plit * (0.50 + 0.60 * mo);
				s += cb * pdisc * earth * (1.0 - plit);
				s += mix(ca, vec3(1.0), 0.5) * pdisc
					* smoothstep(0.024, 0.0, abs(pl - open)) * 0.8;
			}
		}

	} else {
		// THE WORLD BELOW, and what is standing on it. The limb and its thin air shell are always
		// there; everything else is a knob, and the knobs are what make ten different sights:
		//   curtains         tall ribbed sheets of light  (an aurora, a frost crown)
		//   lamps + width    discrete points, or wide soft patches (a lamp line, pools of sky)
		//   haze + ripple    a wedge lifting off the limb; ripple turns it into a heat shimmer
		//   fog              a low bank lying in the hollows, hugging the surface
		//   terminator       a hard shadow crossing the limb, which nothing else here has
		// THE MOMENT folds the curtains over, opens the fog front, and brightens the lamps.
		float curk = f1.x;
		float curh = max(f1.y, 0.05);
		float curn = clamp(f1.z, 1.0, 5.0);
		float lean = f1.w;
		float haze = f2.x;
		float slant = f2.y;
		float ripp = f2.z;
		float lampk = f3.x;
		float lampw = clamp(f3.y, 0.0, 1.0);
		float fogk = f3.z;
		float term = f3.w;
		float R = 1.55;
		vec2 cc = vec2(0.0, R + 0.20);
		// (lampk is read by the air-shell line below, so it is declared before it)
		vec2 rel = q - cc;
		float pd = length(rel);
		float ground = smoothstep(R + 0.012 + 0.07 * bl, R - 0.012, pd);
		occl = ground;
		// which way round the limb we are, in radians from straight down: every overlay is placed
		// on this so they all sit ON the surface and not in the air
		float arc = atan(rel.x, -rel.y);
		// R12 (wave 3, G5): THE SECOND WAVE. This mottle was sin(q.x * 7) * sin((pd - R) * 22) -
		// the second factor is a set of RINGS concentric with the world, so every "world below"
		// sight (home_aurora and its nine siblings) carried a ripple pattern like a pond, which the
		// swim then set moving. The user's "wavy effect of the planet" is the swim (removed by G7
		// from safari_run.gd); this was the other half. Same amplitude, same 0.72 mean, no rings:
		// smooth value noise on the surface.
		float mot = 0.72 + 0.28 * (lane_vnoise(q * 3.4 + vec2(sd * 1.7, sd)) * 2.0 - 1.0);
		s += cb * ground * 0.085 * mot;
		float shell = exp(-(pd - R) * (pd - R) / (0.0016 + 0.030 * bl));
		// ROUND 4: a thick low bank HIDES the thin air shell. Without this, Fen's fog - which has
		// no lamps at all - got the full 0.55 shell and read as one smooth bright arc, which is
		// exactly the "warm glow on a rim" the reviewer put it in a family for.
		s += mix(ca, vec3(1.0), 0.30) * shell * (0.55 / (1.0 + 1.9 * lampk + 1.8 * fogk));
		if (term > 0.002) {
			// NIGHT COMING OVER. A hard edge across the surface, dark behind it, with a thin warm
			// line right on it. Nothing else on this branch has a straight edge.
			float e = (arc - slant) * 3.0;
			float night = smoothstep(-0.30 / max(term, 0.05), 0.02, e);
			s *= mix(1.0, 0.30, night);
			// ashen ground on the night side, above the sky behind it, so the world keeps its edge
			s += cb * ground * night * 0.055 * (0.70 + 0.30 * mot);
			// the warm line standing ON the surface, thin, and only on the surface
			s += vec3(1.0, 0.78, 0.52) * mix(ca, vec3(1.0), 0.25) * ground
				* smoothstep(0.070 / max(term, 0.05), 0.0, abs(e)) * term * 0.45;
			// the air shell goes out with the sun as the edge passes, by MULTIPLYING it down
			s += mix(ca, vec3(1.0), 0.30) * shell
				* (0.55 / (1.0 + 1.9 * lampk + 1.8 * fogk)) * (mix(1.0, 0.10, night) - 1.0) * term;
			s = max(s, vec3(0.0));
		}
		if (lampk > 0.002) {
			// LIGHTS ON THE GROUND, and ROUND 4's fix for the third family. Fen's pools, Vela's
			// lamps and the fog on Fen came back from the contact sheet as ONE WARM GLOW ON A RIM,
			// because all three were the same round blob at three widths. Two flags split them:
			//   lampw > 1.0        SLABS. A pool is flat: WIDE along the ground and THIN in height,
			//                      with a hard top edge and one specular line lying on it. A round
			//                      glow cannot look flat however wide you make it. (still_pools)
			//   fogk  > 0.002      HALOED. There is white stuff over these lights, so each one is a
			//                      small warm core inside a big COLD halo - what a window looks like
			//                      under ice, and nothing like a bare lamp. (vela_lamps)
			// Fen's fog keeps no lamps at all, so it is a bank and only a bank.
			float slab = step(1.0, lampw);
			float lw = min(lampw, 1.0);
			float lampn = clamp(f1.z, 1.0, 6.0);
			for (int i = 0; i < 6; i++) {
				float fi = float(i);
				if (fi + 0.5 > lampn) { continue; }
				float a = slant + (fi - (lampn - 1.0) * 0.5) * (1.24 / max(lampn - 1.0, 1.0))
					+ 0.055 * sh_h(fi * 4.1 + sd);
				vec2 lp = cc + (R - 0.008) * vec2(sin(a), -cos(a));
				float dd = length(q - lp);
				float w = mix(0.030, 0.100, lw) * (1.0 + 2.0 * bl);
				float br = 0.55 + 0.45 * sh_h(fi * 9.3 + sd) * 2.0;
				br *= 0.70 + 0.30 * mo;
				if (slab > 0.5) {
					float da3 = arc - a;
					float wide = 0.075 + 0.055 * abs(sh_h(fi * 6.7 + sd)) * 2.0;
					// flat: a hard-edged strip lying ON the surface, a few thousandths deep
					float lay = smoothstep(R - 0.034 - 0.030 * bl, R - 0.024, pd)
						* smoothstep(R + 0.006 + 0.030 * bl, R - 0.002, pd);
					float pool = smoothstep(wide, wide * 0.80, abs(da3)) * lay;
					s += mix(ca, vec3(1.0), 0.22) * lampk * pool * br * 1.85;
					// the sky lying in it: one bright specular streak, off to one side
					s += vec3(1.0, 0.97, 0.90) * lampk * pool
						* smoothstep(wide * 0.42, 0.0, abs(da3 + wide * 0.30)) * 0.75;
					// and a little of it bouncing back up, so it is water and not paint
					s += ca * lampk * br * 0.22 * smoothstep(wide * 1.5, 0.0, abs(da3))
						* smoothstep(R + 0.055, R, pd) * smoothstep(R - 0.004, R + 0.010, pd);
				} else {
					s += mix(ca, vec3(1.0), 0.45 * (1.0 - lw)) * lampk * br
						* smoothstep(w, 0.0, dd) * mix(2.10, 0.95, lw);
					s += ca * lampk * br * exp(-dd * dd / (w * w * 6.0)) * 0.55;
					if (fogk > 0.002) {
						// THE COLD HALO the ice spreads round each warm core. This is the whole
						// difference between "a lamp" and "a lamp seen through half a mile of
						// frost", and it is `cb` (cold) round an `ca` (warm) point, so the two
						// colours sit one inside the other instead of blending into a warm rim.
						// KEPT SMALL ON PURPOSE. At 1.45 and 42x it stopped being a halo per lamp
						// and became one bright dome over the whole limb, which is the exact
						// failure this round is fixing. Each core keeps its own ring.
						s += mix(cb, vec3(1.0), 0.18) * lampk * br * fogk * 0.60
							* exp(-dd * dd / (w * w * 34.0));
					}
				}
			}
		}
		if (fogk > 0.002) {
			// A BANK LYING IN THE HOLLOWS. It hugs the surface - its height is a fraction of the
			// limb, not a wall - and it is lumpy along the arc, which is what tells it from a
			// curtain standing up out of the ground.
			// ROUND 4 made the lumps DEEPER (0.45..1.0 was a gentle ripple that read as a smooth
			// warm rim, which is what put Fen's fog in a family with Fen's pools and Vela's lamps).
			// 0.12..1.0 with a third harmonic gives it real hollows and real ridges - the shape you
			// name when you say "a bank" - and the bank is now a good deal taller than it was.
			float lump = 0.12 + 0.88 * (0.5 + 0.5 * sin(arc * 9.0 + sd))
				* (0.5 + 0.5 * sin(arc * 3.3 - sd * 1.7 + tt * 0.22))
				* (0.62 + 0.38 * sin(arc * 21.0 + sd * 2.3));
			lump = clamp(lump, 0.0, 1.0);
			float top = R - (0.022 + 0.130 * fogk) * lump * (0.8 + 0.4 * mo);
			float band = smoothstep(top - 0.02, top + 0.012, pd) * smoothstep(R + 0.02, R - 0.004, pd);
			s += mix(ca, cb, 0.35) * band * fogk * 0.62;
			// the bright crest ON the ridge, which is what makes a bank a bank and not a haze
			s += mix(ca, vec3(1.0), 0.45) * fogk * 0.60
				* smoothstep(0.014, 0.0, abs(pd - top)) * (0.25 + 0.75 * lump);
		}
		if (haze > 0.002) {
			// A VEIL LIFTING OFF THE LIMB, seen edge-on: a wedge, widest where it leaves the
			// ground, thinning with height. `ripp` shakes it at high frequency, which is a heat
			// shimmer and reads nothing like a curtain.
			float da = arc - slant;
			float altu = (pd - R) / curh;
			float h = clamp(altu, 0.0, 1.0);
			float up = smoothstep(-0.05, 0.02, altu) * (1.0 - smoothstep(0.48, 1.05, altu));
			float rp = ripp * (0.45 + 1.30 * mo);
			float wob = rp * 0.055 * sin(h * 26.0 + tt * 3.1 + sd)
				+ rp * 0.030 * sin(h * 51.0 - tt * 2.2);
			// `lean` is the wedge's BROADNESS here. It only ever drives a curtain's fold when
			// there are curtains, so on a veil it is free and it is the knob that tells a broad
			// dust veil from a narrow heat shimmer.
			float wedge = exp(-(da + wob) * (da + wob) / (0.004 + 0.30 * lean + 0.145 * h));
			s += mix(ca, cb, h) * wedge * haze * up * (0.55 + 0.45 * mo) / (1.0 + 1.6 * bl);
		}
		if (curk > 0.002) {
			// CURTAINS, standing ON the limb and leaning as they fold.
			for (int i = 0; i < 5; i++) {
				float fi = float(i);
				if (fi + 0.5 > curn) { continue; }
				float a0 = slant + (fi - (curn - 1.0) * 0.5) * (0.46 / max(curn * 0.25, 0.4));
				float folded = mo * lean * sin(fi * 1.7 + sd);
				float altu = (pd - R) / curh;
				float h = clamp(altu, 0.0, 1.0);
				float da = arc - a0 - folded * h * 1.2
					- 0.050 * sin(h * 5.2 + tt * (0.45 + 0.08 * fi) + fi * 2.0);
				float w = 0.0022 + 0.016 * bl;
				float curtain = exp(-da * da / w);
				float up = smoothstep(-0.05, 0.03, altu) * (1.0 - smoothstep(0.42, 1.05, altu));
				float rib = 0.62 + 0.38 * sin(arc * 52.0 + tt * 1.1 + fi * 3.0);
				s += mix(ca, cb, h) * curtain * up * rib * curk
					* (0.45 + 0.55 * mo) / (1.0 + 1.9 * bl);
			}
		}
	}
	return s;
}

// ---------------------------------------------------------------- R1: one far mark
// WHY IT CANNOT BE MISTAKEN FOR A STAR, by construction rather than by hope. A star in
// lane_sky.gdshaderinc is a single smoothstep blob about a tenth of a degree across with nothing
// around it. A mark is a SOFT CORE INSIDE A THIN RING, about a degree across, and it breathes.
// Three differences - size, structure and motion - and only the first depends on how bright it is,
// so it survives being dim. Dim is the point: this is what a thing looks like before the glass
// finds it.
vec3 far_mark(vec2 q, vec4 m, float tt) {
	if (m.w <= 0.001) {
		return vec3(0.0);
	}
	float r = length(q - m.xy);
	float rc = max(m.z, 0.0008);
	// breathe: the same slow rate for every mark, so a field of them pulses together and reads as
	// instrumentation rather than as sky
	float br = 0.86 + 0.14 * sin(tt * 1.7);
	float core = exp(-(r * r) / (rc * rc * 0.50));
	float dr = r - rc * 1.90;
	float ring = exp(-(dr * dr) / (rc * rc * 0.085));
	// uncoloured on purpose (R1): a far mark says WHERE, never WHAT. The colour arrives with the
	// shape, which is the whole handover.
	vec3 tint = vec3(0.78, 0.83, 0.92);
	return tint * m.w * br * (core * 0.42 + ring * 0.50);
}


// ---------------------------------------------------------------- the rail's keep-out
// The old single rail's core half-width (0.20 deg) - no longer drawn here, kept because
// safari_run.gd's R3 counter still quotes it as `RAIL_W_RAD`.
const float RAIL_W = 0.0035;
// The bullseye keep-out fades back in over 0.57 deg, so the hole the track leaves round the
// reticle is soft. It now applies to the whole R10 track - rails, sleepers and bed.
const float RAIL_HALO_W = 0.0099;

// R2's veil floor: how bright the sky, nebula and stars are at the far edge of the reachable sky
// compared with on the flight's plane. 56 degrees is the worst a player can manage under the R5
// clamp (crosshair at +-28, porthole rim another 28 out), where the skirt is 0.114 and the veil
// lands at 0.58-0.60 depending on where the layer ridges fall. See the long note in fragment() for
// why a multiply and not just an add.
const float AUR_FLOOR = 0.55;

// R2's layer spacing. The band's ridges sit at |e| = (2*pi*n / LAYER_K)^2 radians off the plane,
// which at 26.0 is 3.3, 13.4, 30.1 and 53.5 degrees: four of them across the reachable sky, packed
// near the plane and spread out away from it. Square-root phase is the whole point - evenly spaced
// ridges would be a ruled grid and would say nothing about which way is level.
const float LAYER_K = 26.0;

// WAVE 3 (G5): `gold_rail()` - the single great-circle rail hung 143 m under the lane axis - is
// deleted. R10 replaced it with gold_track() below; see space_lane.gd "R10" for why one line
// slung far below read as "leading to something below me" and two rails under the hull do not.


// ---------------------------------------------------------------- R10: the track
// A rail is a straight 3D segment between two route points, and a straight segment seen from the
// eye is an arc of a great circle - so each piece is closed form: how far the pixel is off the
// arc's plane, whether it lies between the two ends, and (law of sines) how far away the rail is
// at that pixel. The distance is what makes it a RAILWAY: the line is TRK_RAIL_M metres wide, so
// it is fat where it comes out from under the hull and a hairline where it meets the planet, and
// it never goes thinner than a pixel.
const float TRK_RAIL_M = 0.09;     // the rail's half-width, metres (space_lane.gd TRACK_RAIL_M)
const float TRK_SLEEPER_M = 0.45;  // a sleeper's half-thickness along the track, metres

float trk_rail(vec3 d, vec3 A, vec3 B, vec4 nw, float px_rad) {
	// early out, first and cheap: one dot product. Most pixels leave every piece here.
	float sd = dot(d, nw.xyz);
	if (nw.w < 0.0 || abs(sd) > max(nw.w, px_rad) * 3.5) {
		return 0.0;
	}
	vec3 n = nw.xyz;
	float la = length(A);
	float lb = length(B);
	vec3 ua = A / max(la, 0.0001);
	vec3 ub = B / max(lb, 0.0001);
	vec3 dp = d - n * sd;
	float dpl = length(dp);
	if (dpl < 0.0001) {
		return 0.0;
	}
	dp /= dpl;
	float sa = dot(cross(ua, dp), n);    // sin of the angle from A's end to this pixel
	float sb = dot(cross(dp, ub), n);    // ...and from this pixel to B's end
	if (sa < 0.0 || sb < 0.0 || dot(dp, ua + ub) <= 0.0) {
		return 0.0;
	}
	float sg = length(cross(ua, ub));   // sin of the angle the whole piece spans
	float r = la * lb * sg / max(la * sa + lb * sb, 0.000001);
	float w = max(TRK_RAIL_M / max(r, 0.01), px_rad * 0.55);
	float off = abs(sd);
	// flat, like the rest of the game's line work: a solid core with a short soft edge, and a
	// faint glow one core-width either side so it sits in the sky rather than on the glass
	float core = 1.0 - smoothstep(w * 0.75, w * 1.35, off);
	float glow = exp(-(off * off) / (w * w * 9.0));
	return core * 0.58 + glow * 0.10;
}

// Sleepers on one piece of track: the quad between two consecutive pairs of rail points. The pixel
// ray is intersected with the quad's plane, and the hit is placed along (v) and across (u) it.
float trk_sleepers(vec3 d, vec3 L0, vec3 R0, vec3 L1, vec3 R1, vec4 q,
		float s0, float s1, float px_rad) {
	float den = dot(q.xyz, d);
	if (abs(den) < 0.0005) {
		return 0.0;
	}
	float tq = q.w / den;
	if (tq <= 0.0) {
		return 0.0;
	}
	vec3 X = d * tq;
	vec3 M0 = (L0 + R0) * 0.5;
	vec3 M1 = (L1 + R1) * 0.5;
	vec3 ax = M1 - M0;
	float v = dot(X - M0, ax) / max(dot(ax, ax), 0.000001);
	if (v < 0.0 || v > 1.0) {
		return 0.0;
	}
	vec3 rv = mix(R0 - L0, R1 - L1, v);
	float u = dot(X - mix(M0, M1, v), rv) / max(dot(rv, rv), 0.000001) * 2.0;
	if (abs(u) > 1.25) {
		return 0.0;
	}
	// metres of track per screen pixel here: the ray's footprint on a surface it grazes
	float mpp = tq * px_rad / max(abs(den), 0.04);
	float ph = fract(mix(s0, s1, v) / trk_gap);
	float along = abs(ph - 0.5) * trk_gap;
	float bar = 1.0 - smoothstep(TRK_SLEEPER_M - mpp, TRK_SLEEPER_M + mpp, along);
	float ends = 1.0 - smoothstep(1.05, 1.22, abs(u));
	// SAMPLING, not taste: once a sleeper period is under ~3 pixels there is no repeat left to
	// draw, only shimmer, so the sleepers hand over to a faint even bed at exactly that point.
	float res = 1.0 - smoothstep(trk_gap / 5.0, trk_gap / 2.5, mpp);
	float bed = (1.0 - smoothstep(0.85, 1.0, abs(u))) * 0.07;
	return (bar * 0.34 * res + bed * (0.4 + 0.6 * res)) * ends;
}

float gold_track(vec3 d, float px_rad) {
	if (rail_on <= 0.001) {
		return 0.0;
	}
	float acc = 0.0;
	for (int k = 0; k < TRK_N - 1; k++) {
		vec4 pc = trk_pc[k];
		if (dot(d, pc.xyz) < pc.w) {
			continue;
		}
		acc = max(acc, trk_rail(d, trk_l[k], trk_l[k + 1], trk_nl[k], px_rad));
		acc = max(acc, trk_rail(d, trk_r[k], trk_r[k + 1], trk_nr[k], px_rad));
		if (k < 11) {
			acc = max(acc, trk_sleepers(d, trk_l[k], trk_r[k], trk_l[k + 1], trk_r[k + 1],
				trk_q[k], trk_s[k], trk_s[k + 1], px_rad));
		}
	}
	return acc;
}

void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	p.x *= aspect;
	// HOW BIG A PIXEL IS, IN SKY. Taken here, at the top of fragment(), because this is the last
	// place the control flow is still uniform across the quad - a derivative sampled inside one of
	// the branches below would be reading neighbours that took a different path. `fwidth(p.y)` is
	// exactly 2 / viewport_height in glass units, so `px_rad` is radians of sky per screen pixel at
	// whatever resolution and field the frame is actually being drawn at. gold_track() needs it
	// for the rails' one-pixel floor and to know when the sleepers stop being resolvable.
	float px_rad = fwidth(p.y) * field_half;
	// THE MARKS AND THE RETICLE DO NOT SWIM (safari6). `p_dry` is the opening's own coordinate,
	// before the wobble below. Measured, and it cost the R1 gate half its budget: the swim moves
	// the whole picture by up to 0.05 glass units, which WAS 0.35 deg in a 7-degree glass and
	// becomes 1.4 deg in a 28-degree window. A mark is instrumentation drawn ON the glass - a
	// reticle does not shake with what it is pointed at - so it is placed in `p_dry` and lands
	// within a tenth of a degree of the sight's true bearing instead of within a degree and a half.
	vec2 p_dry = p;
	// SWIM. Same two slow layers as the brass spyglass, amplitude IS `swim` - no free gain.
	p += swim * 0.034 * vec2(sin(p.y * 3.1 + t * 1.35), cos(p.x * 2.7 + t * 1.10))
		+ swim * 0.016 * vec2(sin(t * 0.77), cos(t * 0.63));
	// rounded-box distance to the opening. Negative inside; `eg` is how far in from the edge.
	vec2 hb = vec2(aspect, 1.0) - vec2(corner);
	vec2 bd = abs(p) - hb;
	float sd = length(max(bd, 0.0)) + min(max(bd.x, bd.y), 0.0) - corner;
	float eg = max(-sd, 0.0);
	if (sd > 0.0) {
		// Outside the glass is TRANSPARENT: the hull is drawn over it by safari_cockpit.gd.
		COLOR = vec4(0.0);
	} else {
		vec3 sky = vec3(0.0);

		// ---- ONE SKY, MAGNIFIED. This used to be a flat grid slid sideways by `look`, which
		// sheared and smeared as you panned and had nothing to do with the sky outside the glass.
		// Now the pixel is turned back into a WORLD DIRECTION on the same az/el convention
		// SafariRun.field_of() uses, and lane_sky.gdshaderinc draws the same sky the window draws -
		// five octaves instead of three and a fainter cut, because a 10x glass finds stars an eye
		// cannot. Swing away and back and the same stars are in the same places, because there is
		// only one sky and this is a function of where you point.
		float azp = look.x + p.x * field_half;
		float elp = look.y - p.y * field_half;
		vec3 dirw = vec3(sin(azp) * cos(elp), sin(elp), -cos(azp) * cos(elp));
		// R8: `dirw` is in the SHIP's frame (where the sights live); `dw` is the same ray in the
		// WORLD, which the route turns and tilts under the ship. Sky, stars and aurora use `dw`.
		vec3 dw = normalize(ship_basis * dirw);
		// R2 ROUND 2: the band's frame is the LANE's - the ship's own level (it never rolls), turned
		// by the ship's heading. `elb` is the ship-frame elevation itself; `azb` is the ship-frame
		// azimuth plus the ship's world yaw, so the band's folds stay put in the world while the
		// ship turns under them. See the note at the top of the aurora block for why not `dw`.
		float elb = elp;
		float azb = azp + atan(-ship_basis[2].x, ship_basis[2].z);
		// R11: THE GAME'S OWN SPACE (lane_sky.gdshaderinc): the planet sky's navy, the rocket sky's
		// flat cloud patches, and its star grammar. `sky_light` is unused by the flight (0.0).
		sky = lane_space_base(dw) + lane_space_clouds(dw);
		// A star keeps its PIXEL size when the glass magnifies: its angular size is scaled by
		// field_half / 28 deg, the lowered field it is drawn for - an exact inversion, no gain.
		vec3 stars = lane_star_field(dw, t, field_half / 0.48869219);

		// ---- R2: WHICH WAY IS LEVEL. The user, after flying it: "I couldn't tell where I was ...
		// was I looking up or down sideways or backwards", and their own suggestion was "subtle
		// gold-ish aurora borealis waves that effectively act as the horizon line".
		//
		// TWO PARTS, AND THE SECOND ONE IS THE REQUIREMENT. The CORE is the aurora itself, a few
		// degrees of folded gold about the flight's plane - that is the "on it" read. The SKIRT is
		// a very broad, very dim falloff either side of the same plane, and it is what makes the
		// gate pass at +-40 degrees, where the core has already left a 56-degree window: the glow
		// is then simply stronger toward one edge of the porthole than the other, and which edge
		// is the answer. Both are monotonic in |elp|, so "brighter that way = the plane is that
		// way" is true everywhere and cannot lie.
		//
		// Subtle on purpose (R2, STYLE_GUIDE palette gates): peak add 0.15 of a gold that is
		// S 0.58 before it is dimmed, over a sky that is 0.02-0.06. It is a horizon, not a show.
		//
		// ================= ROUND 2. ADDING LIGHT WAS NOT ENOUGH, AND HERE IS WHY ================
		// A critic blind-graded 24 frames (8 headings x el -28/0/+28) and got 15 right, 2 wrong and
		// 7 uncallable, against a gate that says "right every time". The cause was measured, not
		// guessed: at el -28 az 45 the aurora added +0.058 luma to the top third and +0.010 to the
		// bottom, but THE BARE SKY THERE ALREADY LEANS THE OTHER WAY - the nebula makes the bottom
		// third (0.1018) brighter than the top (0.0814) all on its own - so the net top-to-bottom
		// signal was 0.028 and the frame read as a flat star field. An additive band can only ever
		// add to whatever gradient the nebula happens to have at that heading; at some headings the
		// nebula wins.
		//
		// THE FIX IS THE VEIL, and it is the other half of the same physical idea. The band is a
		// thin sheet of lit gas lying in the flight's plane. Near the plane you are looking THROUGH
		// that sheet and the sky behind it is lifted; away from it you are looking out of it into
		// deep space, and the sky behind is darker. So the same `skirt` that adds light near the
		// plane now also MULTIPLIES the sky, the nebula and the stars, from 1.0 on the plane down to
		// AUR_FLOOR at the far edge of the reachable sky. The nebula's own gradient is inside that
		// multiply, which is exactly what the additive band could not do: it cannot out-vote the
		// veil, because the veil scales it. Brighter is planewards at every heading, by
		// construction, and the margin roughly doubles (measured table in the round-2 report).
		//
		// AUR_FLOOR is the one art weight here and it is set by that table, not by inversion - it
		// is how dark the deepest reachable sky gets relative to the plane. At the R5 clamp the
		// furthest a player can get from the plane is 56 degrees, where the veil lands at 0.60.
		vec3 aur = vec3(0.0);
		float veil = 1.0;
		if (aurora > 0.001) {
			// the plane folds: two slow waves in azimuth, so it is an aurora and not a ruled line
			// R2 ROUND 2, AND WHY THE BAND NO LONGER TILTS WITH THE ROUTE. Round 1 hung the band on
			// the WORLD's level plane, so when the route climbed it sank below the bow. The critic
			// then blind-judged 24 glass-only frames at the steepest stretch of longhome (home_vela,
			// t=70-93, pitch 3.4-11.9 deg, 8 headings x el -26/0/+26) and got 15 right, against 24
			// of 24 on the same poses before round 1. The cause is arithmetic, not taste: R5 lets
			// the crosshair reach 28 deg off the ship's level and the lowered window is 28 deg in
			// half-height, so the band only stays on the glass if it sits within a couple of
			// degrees of the SHIP's level. Pitch added up to 12 deg and put the view 25-34 deg off
			// the band - past the rim, band gone - in 7 of the 24 frames. No tilt that keeps the
			// band on the glass at the clamp is big enough to see, so the band is the plane of the
			// LANE the ship is flying along: a sheet of lit gas laid along the route, which climbs
			// and dives with it as the track does. Elevation off it is the ship-frame `elb`, which
			// is exactly what it was before round 1; only its azimuth is the world's (`azb`), so
			// a turn still slides the folds across the glass. The stars and nebula keep the world
			// ray `dw`, so a climb is still seen in them, the track and the two planets.
			// `azb` jumps by 2*pi dead astern, so every azimuth frequency in the
			// band is a WHOLE number (2.7 -> 3, 5.3 -> 5, 8.3 -> 8, 1.9 -> 2): measured, the old
			// fractional ones drew a vertical seam across the window looking aft.
			float fold = 0.0185 * sin(azb * 3.0 + t * 0.10)
				+ 0.0105 * sin(azb * 5.0 - t * 0.07 + 1.7);
			float e = elb - fold;
			// THREE TERMS, MEASURED INTO SHAPE (2026-09-21). The first cut was one 6.6-degree core
			// plus a 42-degree skirt, and the frames said two things: at elevation 0 it read, but at
			// -28 - where R5 parks the plane exactly on the porthole's rim - the core was cut in
			// half by the rim AND dimmed by the opening's own vignette, and the top-to-bottom luma
			// difference came out at only 0.028. So:
			//   RIBBON  3.5 deg  the aurora proper, with the curtain grain on it. What you see when
			//                    you are ON the plane.
			//   CORE    12  deg  wide enough that a plane sitting on the rim still spills a long way
			//                    into the window. (20 deg after round 2 - see below.)
			//   SKIRT   45  deg  the monotonic wash that answers "above or below" when the band
			//                    itself has left the window entirely. (38 deg after the second
			//                    measurement below; it is also what drives round 2's veil.)
			// All three are even functions of the same `e`, so brighter is always planewards and the
			// picture cannot lie about which way is level.
			// SECOND MEASUREMENT (same day). With the skirt at 45 deg and 0.030 the weakest heading
			// (el -28, az 45, where the nebula is dimmest) showed only 0.024 of top-to-bottom luma.
			// The skirt is the whole signal there, so the weight moved INTO it - 38 deg and 0.050 -
			// and came back out of the ribbon and core, leaving the peak where it was.
			// THIRD MEASUREMENT, ROUND 2: THE CORE WENT FROM 12 DEGREES TO 20. At el +-28 - the R5
			// clamp, where the plane sits exactly on the porthole's rim - a 12-degree core is down
			// to 0.26 by the time it is a third of the way into the window and 0.004 at the far
			// rim, so everything the eye had to work with out there was the featureless skirt, and
			// the layer ridges below had nothing to ride on. At 20 degrees the same two points are
			// 0.84 and 0.50: the band spills properly into the window instead of clinging to the
			// edge the vignette is already dimming. The ribbon is untouched, so "you are ON the
			// plane" is still a 3.5-degree line and not a 40-degree glow.
			float ribbon = exp(-(e * e) / 0.003731);   // 3.5 deg
			float core = exp(-(e * e) / 0.121900);     // 20 deg
			float skirt = exp(-(e * e) / 0.439600);    // 38 deg
			// curtain grain, on the ribbon only: two rates so it folds instead of striping
			float grain = 0.66 + 0.34 * sin(azb * 21.0 + t * 0.22)
				* (0.50 + 0.50 * sin(azb * 8.0 - t * 0.13));
			// real curtains hang ABOVE the line they stand on; a touch of asymmetry stops the band
			// reading as a painted stripe
			float hang = 1.0 + 0.35 * smoothstep(0.0, 0.16, -e);
			// THE LAYERS, ROUND 2, AND THEY ARE WHAT MAKES THIS READABLE RATHER THAN MERELY
			// MEASURABLE. Everything above is a smooth glow: to read it a person has to compare
			// one half of a star field with the other half and decide which is brighter, which is
			// exactly what the critic could not do on 7 of 24 frames. A TEXTURE they can read at a
			// glance. Ridges sit at |e| = (2*pi*n / LAYER_K)^2 - 3.3, 13.4, 30.1 and 53.5 degrees
			// off the plane - so they CROWD TOGETHER toward the plane and SPREAD APART away from
			// it, which is what layers in a thin sheet do when you look along it. "The lines are
			// converging that way" needs no comparison and survives the band itself being off the
			// edge of the porthole; one ridge near a rim is enough to place you.
			// It rides on the SKIRT only, not the ribbon and not the core - see the note where
			// `aur` is assembled for the measurement that put it there. The envelope is still
			// monotone in |e|, which is what the third-to-third gate reads, while the local
			// gradient now reverses every few degrees on purpose.
			float lay = 0.5 + 0.5 * cos(LAYER_K * sqrt(abs(e))
				+ 0.55 * sin(azb * 2.0 + t * 0.06));
			float layer = 0.30 + 1.40 * lay;
			vec3 gold = vec3(1.00, 0.79, 0.41);
			// ROUND 2: the band is HELD BACK and added after the worlds, further down, instead of
			// going into `stars` here. At az 180 near the start of a run the home planet's disc
			// fills the porthole, `stars *= (1.0 - wocc)` erased the band with it, and the frame
			// had no level cue at all - one of the two the critic graded outright wrong. The sheet
			// is a few hundred metres of lit gas in the lane; the planet is thousands of
			// kilometres away, so the band passing in front of it is the right read as well as the
			// readable one.
			// WHO GETS WHAT, and it is not arbitrary - each term does one job.
			//   ribbon x grain x hang   the LINE. It has to win the peak when you are on the
			//                           plane, so nothing else is allowed to beat it there: the
			//                           layer ridges stay off it and off the core.
			//   core                    the smooth swell either side, plain, so the near-plane
			//                           region has ONE maximum and a ridge cannot be mistaken
			//                           for the horizon.
			//   skirt x layer           the far wash, where the ridges live. They matter exactly
			//                           where the core has gone and the eye has nothing else.
			// Measured: with `layer` on the core as well, three of the eight el-0 frames peaked on
			// the ridge 13 degrees BELOW the plane instead of on the plane itself - the ridge and
			// `hang` between them out-voted the line the band is supposed to be.
			// R11 (wave 3): ONLY THE RIBBON IS GOLD NOW. The core and the skirt are 20 and 38 degrees
			// wide, and in gold over the game's navy they turned half the window a neutral mauve-grey
			// (measured: navy (20,21,48) came out (40,36,53) on the glass, S 0.32). STYLE_GUIDE R2.1
			// already says what the sky does near a horizon - "a dusty, slightly warm haze" - so the
			// wide terms are that haze: a dusty periwinkle with the SAME luma as the gold (0.80
			// against 0.81), so R2's brighter-toward-the-plane gradient is unchanged in brightness
			// and only its colour moved. The ribbon, the aurora proper, stays gold.
			vec3 haze = vec3(0.80, 0.78, 0.98);
			aur = (gold * ribbon * 0.110 * grain * hang + haze * (core * 0.065 + skirt * 0.050 * layer))
				* aurora * mix(1.0, 0.70, sky_light);
			// THE VEIL. Same `skirt`, used the other way round: the sky, the nebula and the stars
			// are scaled by it, so the background's own gradient is multiplied by a function that
			// is monotone planewards and cannot be out-voted by whatever the nebula is doing at
			// this heading. See the long note above the `if`.
			// The ridges are in here too, at a third of the strength they have in the gold. That
			// puts them on the STAR FIELD, not only on the band, so the converging-layers read
			// survives where the gold itself is almost gone - and it costs no extra light, which
			// is what keeps the STYLE_GUIDE palette gates where they were.
			veil = mix(AUR_FLOOR, 1.0, skirt * (0.65 + 0.35 * lay));
		}
		sky *= veil;
		stars *= veil;

		// ---- WHICH WAY THE SHIP IS GOING, inside the glass. Dust streaming radially out of
		// `flow_from` - the heading, in field coordinates. Polar cells in (angle, log radius) mean
		// a constant scroll in `run` is an EXPONENTIAL radial speed, which is what a flow toward a
		// vanishing point actually looks like: nothing at the point, whipping at the edge. Point
		// down the lane and it blooms out of the middle; point abeam and it all runs one way.
		// TWO PARAMETRISATIONS, because one does not cover a sphere. `theta` is how far off the
		// heading you are pointing. Near the heading the dust EXPANDS out of a point and polar
		// cells are the honest shape; out on the beam it is a flat scroll across the field, fastest
		// there and slowing to a standstill dead astern - which is what translation actually looks
		// like (the apparent rate goes as sin(theta)). Looking back at home used to show no motion
		// at all because the polar branch degenerates there; now it converges instead.
		vec2 fv = p - flow_from;
		float fr = length(fv);
		// radians off the heading. The `* 7.0` that used to be here was a magic number that made a
		// 7-degree offset read as 49; with the window able to change width it had to become the
		// real conversion, which is one glass unit = `field_half` radians.
		float theta = length(flow_from) * field_half;
		// the old thresholds were 3.6 and 5.0 GLASS UNITS at a 7-degree field, i.e. 25.2 and 35.0
		// degrees. Written as the angles they always were, so the window cannot move them.
		float polar = 1.0 - smoothstep(0.43982, 0.61087, theta);
		vec2 fdir = length(flow_from) > 0.0001 ? -normalize(flow_from) : vec2(0.0, -1.0);
		vec2 fperp = vec2(-fdir.y, fdir.x);
		vec3 flow = vec3(0.0);
		for (int k = 0; k < 2; k++) {
			vec2 gk;
			float rate;
			if (polar > 0.5) {
				// log radius: a constant scroll here is an EXPONENTIAL radial speed, which is what
				// a flow toward a vanishing point looks like - still at the point, whipping at the
				// edge of the field
				gk = vec2(atan(fv.y, fv.x) * 5.5, log(max(fr, 0.02) + 0.22) * 3.4 - run * 0.80);
				rate = smoothstep(0.05, 0.55, fr);
			} else {
				gk = vec2(dot(p, fperp) * 7.0, dot(p, fdir) * 7.0 - run * 1.9 * sin(theta));
				rate = 1.0;
			}
			gk += vec2(float(k) * 0.5, float(k) * 0.37);
			vec2 cell = floor(gk);
			vec2 f = fract(gk) - 0.5;
			vec2 o = vec2(lane_h21(cell + 41.0), lane_h21(cell + 7.9)) - 0.5;
			float m = lane_h21(cell + 13.1);
			vec2 dv = f - o * 0.80;
			// R11: DUST, NOT WARP LINES. These were long thin Gaussian streaks - the hyperspace
			// picture, and the most "photograph" thing in the frame after the star grit. Now each
			// fleck is a small flat rounded mote, a little longer than it is wide, in the
			// game's own two dust colours (stardust cream #fff6c8, and a pale lavender), and there
			// are fewer of them. It still streams out of `flow_from`, which is its whole job.
			float st = 1.0 - smoothstep(0.45, 1.0,
				sqrt((dv.x * dv.x) / 0.0018 + (dv.y * dv.y) / 0.0034));
			flow += mix(vec3(0.80, 0.78, 0.95), vec3(1.0, 0.965, 0.784), m)
				* st * step(0.80, m) * 0.16 * rate;
		}
		// THE LANE'S DUST IS IN THE LANE'S PLANE, so it gets R2's veil too. Without this the flow
		// streaks are the brightest texture in the frame at every elevation and they wash the band
		// out; with it the streaks themselves thin out as you look away from level, which is one
		// more thing pointing the same way. Applied here rather than up with `sky` because the
		// flow is added after the veil multiply.
		stars += flow * veil;

		// ---- R3: THE ROUTE AHEAD. Drawn only with the scope LOWERED (safari_run.gd sets
		// `rail_on`), because the raised scope is the camera and nothing decorative belongs in a
		// photograph. It also parts around the bullseye: inside CENTRE_DEG of the crosshair the
		// rail is identically zero, so the thing you aim with is never painted over.
		float rail = gold_track(dirw, px_rad);
		if (rail > 0.0) {
			// THE RAIL KEEPS OUT OF THE BULLSEYE. Zero inside `centre_rad` - R3's own radius,
			// safari_run.gd's CENTRE_DEG, 2.10 degrees - and back to full one halo-width further
			// out, because the softest end a line with a 0.57-degree glow can have is 0.57 degrees.
			//
			// ROUND 2, AND THIS WAS THE REAL CAUSE OF "THE RAIL STOPS 5 DEGREES SHORT OF THE
			// PLANET". The fade used to run from `centre_rad` all the way out to `edge_rad`, so the
			// rail only reached full strength 5.46 degrees from the crosshair. The rail's tip sits
			// on the destination's LOWER LIMB, which on home_zorp at t=2 is 3.03 degrees from the
			// planet's centre - inside that band. The critic measured the first solid rail pixel
			// 8.5 degrees below the planet centre with the crosshair 6 degrees below it; 5.46 +
			// 3.03 = 8.49. The gap WAS the keep-out, to the second decimal.
			//
			// Narrowing it is safe, and not by argument: the rail is not drawn at all with the
			// scope raised (`rail_on`), which is the mode you aim and shoot in; and in the wide
			// view every subject is composited OVER the sky with its own `occ`, further down, so a
			// rail pixel can never land on top of a sight whatever the geometry does. What the
			// keep-out is actually protecting is the reticle, and the reticle is the bullseye.
			float from_x = length(p_dry) * field_half;  // radians from the crosshair
			rail *= smoothstep(centre_rad, centre_rad + RAIL_HALO_W, from_x);
			stars += vec3(1.00, 0.82, 0.42) * rail;
		}

		// ---- R1: THE FAR MARKS, at their true angular positions. Unrolled; see the uniforms.
		if (n_mark > 0) { stars += far_mark(p_dry, mk0, t); }
		if (n_mark > 1) { stars += far_mark(p_dry, mk1, t); }
		if (n_mark > 2) { stars += far_mark(p_dry, mk2, t); }
		if (n_mark > 3) { stars += far_mark(p_dry, mk3, t); }
		if (n_mark > 4) { stars += far_mark(p_dry, mk4, t); }
		if (n_mark > 5) { stars += far_mark(p_dry, mk5, t); }
		if (n_mark > 6) { stars += far_mark(p_dry, mk6, t); }
		if (n_mark > 7) { stars += far_mark(p_dry, mk7, t); }

		// ---- the two worlds, so the glass is not blind to what the window can see
		vec3 worlds = vec3(0.0);
		float wocc = 0.0;
		float wo1 = 0.0;
		worlds += world_disc(p - home_pos, home_r, home_col.rgb, home_air.rgb,
			sun_at - home_pos, 5.1, wo1);
		wocc = max(wocc, wo1);
		worlds += world_disc(p - dest_pos, dest_r, dest_col.rgb, dest_air.rgb,
			sun_at - dest_pos, 2.3, wo1);
		wocc = max(wocc, wo1);
		sky = sky * (1.0 - wocc);
		stars = stars * (1.0 - wocc);
		stars += worlds;
		// R2, AFTER THE WORLDS ON PURPOSE. The horizon band is near and the planets are not, so it
		// veils them rather than being cut out by them. This is the line that keeps a level cue in
		// the frame when a planet's disc fills the porthole (see the note in the aurora block).
		stars += aur;

		// ---- the subjects, nearest slot last so a close hull covers a far glow
		vec3 sight = vec3(0.0);
		float occ = 0.0;
		float o1 = 0.0;
		if (n_subj > 0) {
			sight += shape(s0_kind, (p - s0_pos) / max(s0_scale, 0.05), s0_blur,
				s0_a.rgb, s0_b.rgb, s0_moment, s0_seed, t, s0_f1, s0_f2, s0_f3, o1);
			occ = max(occ, o1);
		}
		if (n_subj > 1) {
			sight += shape(s1_kind, (p - s1_pos) / max(s1_scale, 0.05), s1_blur,
				s1_a.rgb, s1_b.rgb, s1_moment, s1_seed, t, s1_f1, s1_f2, s1_f3, o1);
			occ = max(occ, o1);
		}
		if (n_subj > 2) {
			sight += shape(s2_kind, (p - s2_pos) / max(s2_scale, 0.05), s2_blur,
				s2_a.rgb, s2_b.rgb, s2_moment, s2_seed, t, s2_f1, s2_f2, s2_f3, o1);
			occ = max(occ, o1);
		}

		// ---- highlight shoulder. docs/STYLE_GUIDE.md R2.6: no near-clipping whites, cap ~0.92.
		sight = (vec3(1.0) - exp(-sight * 1.20)) * 0.90;

		vec3 col = (sky + stars) * (1.0 - clamp(occ, 0.0, 1.0)) + sight;
		// the opening's own shading: dark in the recess at the edge, warm when a shot is close
		col *= mix(0.62, 1.0, smoothstep(0.0, 0.14, eg));
		col += vec3(0.40, 0.29, 0.13) * smoothstep(0.075, 0.0, eg) * (0.16 + 0.40 * warm);
		col += vec3(1.00, 0.89, 0.62) * flash * (0.16 + 0.22 * smoothstep(0.24, 0.0, eg));
		COLOR = vec4(col, smoothstep(0.0, 0.010, eg));
	}
}
