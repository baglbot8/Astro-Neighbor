// Vertex-coloured toon for hub buildings, with R2.9 surface detail at ARCHITECTURAL scale.
//
// WHY THIS EXISTS RATHER THAN toon_soft's `surface_kind`
// -----------------------------------------------------
// `MaterialLib.toon_vertex_color({"surface": ...})` gives one detail band with one distance fade,
// and that is the right shape for a character or a prop. A building is not: the player stands
// 2 m from a wall, walks past it at 5 m, and looks at it from 22 m across the plaza, and the
// SAME wall has to carry material character at all three. One band cannot do that -
// docs/OPEN_ISSUES.md item 20.7 is explicit that a fine pattern is invisible past a couple of
// metres and that cranking `strength` only buys aliasing.
//
// So this shader layers THREE bands over the same shared library, each with its own sd_lod():
//   1. FINE   - one of the shared sd_* materials (cloth/metal/wood/rock/foliage/rubber). Carries
//               0-8 m. Faded out well before it can beat against the pixel grid.
//   2. SEAMS  - the shared sd_seams(), at plank / panel / masonry-course pitch. A 0.8 m course is
//               still 32 px at 22 m, so this is the band that survives the plaza.
//   3. MACRO  - a very low-frequency tonal drift built from the shared sd_fbm() primitive
//               (2-3 cycles/m). Also survives the plaza, and it is what stops a big plaster wall
//               reading as a single flat swatch from across the square.
//
// Everything else - the lighting, the ramp, the tinted shadow, the rim, the toon specular, the
// sheen call - is copied from src/shaders/toon_soft.gdshader so a building shades exactly like
// every other surface in the game. Keep them in step.
//
// KNOWN BUG, DELIBERATELY NOT FIXED HERE - docs/OPEN_ISSUES.md item 19. Godot 4.7 multiplies
// DIFFUSE_LIGHT by ALBEDO after light() returns, and this light() (like toon_soft's) composes the
// finished colour itself, so albedo lands twice. Every colour in the game was authored against
// that, so the divide has to land with a palette re-author as one measured pass. Working with the
// current behaviour on purpose: it means a tint of x renders as x*x, which is why the amplitudes
// below look conservative.
shader_type spatial;
render_mode cull_back, depth_draw_opaque, diffuse_lambert, specular_schlick_ggx;

global uniform float astro_night;

// WEB PARITY. Under the Compatibility (WebGL2) renderer the web export is forced onto,
// `astro_compat` is 1.0; it is 0.0 on desktop, set once by the Platform autoload, so every wrap
// below is the exact identity on Forward+ and the reference look cannot move.
//
// planet_common.gdshaderinc is included ONLY for pc_in() / pc_out() (it declares no uniforms, so
// there is nothing to collide with astro_night or the surface_detail bands above). Read the long
// block at the top of that file for the measurement and the rules; in short, Compatibility does not
// sRGB-decode `source_color` uniforms on upload, and it sRGB-DECODES whatever fragment() leaves in
// ALBEDO, so the uniform needs pc_in on the way in and the finished colour needs pc_out on the way
// out. In between, both renderers are in linear.
//
// The pc_out lands as a single line at the END of fragment(), not on the `ALBEDO = albedo.rgb *
// COLOR.rgb` at the top, because the three detail bands below multiply ALBEDO in place. Encoding
// early would put the seam and macro tints on the wrong side of the curve.
//
// THIS SHADER WAS THE WORST OFFENDER IN THE GAME. Measured on showcase/hub_buildings.tscn over a
// 51,635-pixel building mask (built by capturing the same frame twice with this shader forced to
// EMISSION 0 and EMISSION 1, on BOTH renderers, and keeping the pixels that moved in both; eroded
// 3 px). Cast shadows, MSAA/FXAA, SSAO and glow were all forced IDENTICAL on the two renderers for
// the probe, so the only thing left between the two frames is this shader:
//     before   per-pixel MAE 51.87 codes, p95 134.0, region SAT 0.3807 -> 0.5439 (gap 0.1632)
//              region luma p05/p50/p95  F+ 29.1 168.0 229.3   C 4.0 70.4 223.4   (GAP 42.86)
//     after    per-pixel MAE  1.79 codes, p95   7.0, region SAT 0.3807 -> 0.3844 (gap 0.0037)
//              region luma p05/p50/p95  F+ 29.1 168.0 229.3   C 28.4 166.9 229.8 (GAP 0.76)
// That p50 of 70.4 against 168.0 is the browser build's "the hub buildings are nearly black", and
// it is what an un-decoded source_color does to a shader whose light() composes the colour from
// ALBEDO itself (see the KNOWN BUG note above — the albedo lands twice, so the error squares).
//
// WHERE THE REMAINING 1.79 IS, because it is NOT colour. Excluding pixels whose 3x3 neighbourhood
// spans more than 6 codes (i.e. scoring only the flat interiors, 31,570 px) gives MAE 0.995,
// p95 3.0, SAT gap 0.0001 — and the SAME frame with this shader forced to a flat `pc_out(vec3(0.6))`
// albedo, where the two renderers are provably being handed the identical colour, still scores
// MAE 0.71 / p95 2.0. So the residual is edge rasterisation on a building covered in window trim,
// not a transfer error. Binned by brightness the mean C-F delta is under 2 codes in every bucket
// from 0 to 240 and changes sign, which is noise, not a curve.
// Two independent capture pairs both gave MAE 1.789. Forward+ did not move: the same mask scored
// between the pre- and post-conversion Forward+ frames is MAE 0.002, max 1 code.
//
// A CLAMP WAS RULED OUT, not assumed: `pc_out(clamp(ALBEDO, 0.0, 1.0))` changed the Compatibility
// result by 0.00 (rule (g) does not bite here — nothing drives this albedo over 1.0).
// pc_in(COLOR.rgb) WAS RULED OUT the same way: adding it takes MAE from 1.79 back to 54.31. The
// vertex colour really does arrive linear on both renderers, exactly as rule (c) says.
//
// NOT WRAPPED, deliberately: COLOR.rgb. It is a VERTEX colour, delivered identically to both
// renderers and already linear on Forward+ — rule (c) in planet_common.gdshaderinc. Nor
// ROUGHNESS / METALLIC / the sd_* tints, which are not colours arriving from a uniform.
global uniform float astro_compat;

#include "res://src/shaders/planet_common.gdshaderinc"
#include "res://src/shaders/surface_detail.gdshaderinc"

// ------------------------------------------------------------------ band 1: fine surface detail
// 0 none, 1 cloth, 2 metal, 3 wood, 4 rock, 5 foliage, 6 rubber - same numbering as toon_soft.
uniform int surface_kind : hint_range(0, 6) = 0;
uniform float surface_strength : hint_range(0.0, 6.0) = 1.0;
uniform float surface_lod_near : hint_range(0.5, 40.0) = 3.0;
uniform float surface_lod_far : hint_range(1.0, 80.0) = 11.0;
uniform vec3 surface_grain_dir = vec3(0.0, 1.0, 0.0);
// Multiplies the position handed to the sd_* function, which is the library header's own advice:
// "use `scale` to move a pattern into a band that survives the distance you actually need".
// > 1 makes the pattern finer, < 1 coarser. sd_cloth at 190 cycles/m needs ~0.28 here to be
// visible on an awning at 5 m instead of only inside 1.1 m.
uniform float surface_scale : hint_range(0.05, 4.0) = 1.0;

// ------------------------------------------------------------------------------ band 2: seams
// 0 off, 1 panel grid (two ring families on the part's own axes - boxy walls, roofs, decks),
// 2 cylindrical (rings up the axis + gores around it - drums, domes, masts).
uniform int seam_mode : hint_range(0, 2) = 0;
uniform float seam_strength : hint_range(0.0, 6.0) = 0.55;
uniform vec3 seam_axis_a = vec3(0.0, 1.0, 0.0);
uniform vec3 seam_axis_b = vec3(1.0, 0.0, 0.0);
// Seams per metre along each axis. 0 switches that family off.
uniform float seam_pitch_a : hint_range(0.0, 12.0) = 1.2;
uniform float seam_pitch_b : hint_range(0.0, 12.0) = 0.0;
// Cylindrical mode only: how many gores run up the drum.
uniform float seam_gores : hint_range(1.0, 48.0) = 16.0;
uniform float seam_phase : hint_range(0.0, 1.0) = 0.5;
uniform float seam_near : hint_range(1.0, 60.0) = 15.0;
uniform float seam_far : hint_range(2.0, 120.0) = 36.0;

// ------------------------------------------------------------------------------ band 3: macro
// Cycles per metre of the large-scale tonal drift. 0 = off. Keep it at 1.5-3.5: at 3 cycles/m a
// cycle is still 13 px at 22 m, so it never aliases, and it is the only band left out there.
//
// AMPLITUDES LOOK LARGE ON PURPOSE. A cream wall renders near display luma 0.88, which is up on
// the compressive shoulder of the ACES curve (white 6), so a 10% albedo change arrives as ~1.5%
// on screen - measured, not guessed: raising macro_amount from 0.18 to 0.32 moved the wall's luma
// std by 0.0015. Dark timber, which sits on the linear part of the curve, needs a fraction of
// this. Tune per material by MEASURING the rendered crop, never by reading the number.
uniform float macro_scale : hint_range(0.0, 8.0) = 0.0;
uniform float macro_amount : hint_range(0.0, 2.0) = 0.055;
uniform float macro_near : hint_range(1.0, 80.0) = 20.0;
uniform float macro_far : hint_range(2.0, 160.0) = 48.0;

// ------------------------------------------------------------------------------ toon (as toon_soft)
uniform vec4 albedo : source_color = vec4(1.0);
uniform float ramp_softness : hint_range(0.01, 1.0) = 0.34;
uniform float shade_strength : hint_range(0.0, 1.0) = 0.46;
uniform vec4 shade_tint : source_color = vec4(0.62, 0.55, 0.85, 1.0);
uniform float shade_floor : hint_range(0.0, 1.0) = 0.62;
uniform float shadow_floor : hint_range(0.0, 1.0) = 0.08;
uniform float rim_strength : hint_range(0.0, 2.0) = 0.13;
uniform vec4 rim_color : source_color = vec4(1.0, 0.97, 0.9, 1.0);
uniform float spec_strength : hint_range(0.0, 2.0) = 0.10;
uniform float spec_size : hint_range(1.0, 400.0) = 60.0;
uniform float roughness : hint_range(0.0, 1.0) = 0.85;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;

varying float v_sheen;
/// Model-space position and normal. Detail must be locked to the object, and sd_metal picks its
/// brush axis from the normal it is handed (docs/OPEN_ISSUES.md item 20.2).
varying vec3 v_objpos;
varying vec3 v_objnorm;

void vertex() {
	v_objpos = VERTEX;
	v_objnorm = NORMAL;
}

void fragment() {
	ALBEDO = pc_in(albedo.rgb) * COLOR.rgb;
	ROUGHNESS = roughness;
	METALLIC = metallic;
	v_sheen = 0.0;

	vec3 opos = v_objpos;
	vec3 onrm = normalize(v_objnorm);

	// -------------------------------------------------------------- band 1: fine material detail
	if (surface_kind > 0) {
		float lod = sd_lod(VERTEX, surface_lod_near, surface_lod_far);
		vec3 p = opos * surface_scale;
		SdSurface sd = sd_none();
		if (surface_kind == 1) { sd = sd_cloth(p, onrm, lod, surface_strength, 1.0); }
		else if (surface_kind == 2) { sd = sd_metal(p, onrm, lod, surface_strength, 1.0); }
		else if (surface_kind == 3) { sd = sd_wood(p, surface_grain_dir, lod, surface_strength, 1.0, 0.55); }
		else if (surface_kind == 4) { sd = sd_rock(p, onrm, lod, surface_strength, 1.0); }
		else if (surface_kind == 6) { sd = sd_rubber(p, onrm, lod, surface_strength, 1.0); }
		else { sd = sd_foliage(p, onrm, lod, surface_strength, 1.0); }
		ALBEDO *= sd.tint;
		ROUGHNESS = clamp(ROUGHNESS + sd.rough, 0.0, 1.0);
		NORMAL = normalize(NORMAL + sd.bump);
		v_sheen = sd.aniso;
	}

	// ---------------------------------------------------------------------------- band 2: seams
	if (seam_mode > 0 && seam_strength > 0.001) {
		float slod = sd_lod(VERTEX, seam_near, seam_far);
		if (slod > 0.001) {
			vec3 a = normalize(seam_axis_a);
			vec3 b = normalize(seam_axis_b);
			SdSurface s1 = sd_none();
			SdSurface s2 = sd_none();
			if (seam_mode == 2) {
				// A drum or a dome: rings run round it, gores run up it. This is exactly the case
				// sd_seams was written for, so one call does the whole job. Faded on surfaces that
				// FACE along the axis, for two reasons: a flat cap (a plinth top) otherwise lands
				// wholly inside one ring period and darkens all at once, and the gores converge to
				// a point at a dome's crown, where they would moire.
				float wc = mix(1.0, 0.35, abs(dot(onrm, a)));
				s1 = sd_seams(opos, a, b, seam_pitch_a, seam_gores, slod, seam_strength * wc, seam_phase, 1.0);
			} else {
				// A boxy wall. sd_seams' gores are ANGULAR, so on a flat face they fan out - the
				// spacing varies 3x from the middle of a 5 m wall to its corner. So drive the
				// uniform RING family on each of the part's two axes instead and park the single
				// gore behind the building with `seam_phase`. Each family is weighted by how
				// perpendicular the surface is to its own axis, which keeps the vertical joints
				// off the roof and the horizontal courses off the floor - without it a flat face
				// lying inside one groove period darkens all at once.
				float wa = 1.0 - abs(dot(onrm, a));
				float wb = 1.0 - abs(dot(onrm, b));
				if (seam_pitch_a > 0.001) {
					s1 = sd_seams(opos, a, b, seam_pitch_a, 1.0, slod, seam_strength * wa, seam_phase, 1.0);
				}
				if (seam_pitch_b > 0.001) {
					s2 = sd_seams(opos, b, a, seam_pitch_b, 1.0, slod, seam_strength * wb, seam_phase, 1.0);
				}
			}
			ALBEDO *= s1.tint * s2.tint;
			ROUGHNESS = clamp(ROUGHNESS + s1.rough + s2.rough, 0.0, 1.0);
			NORMAL = normalize(NORMAL + s1.bump + s2.bump);
		}
	}

	// ---------------------------------------------------------------------------- band 3: macro
	if (macro_scale > 0.001) {
		float mlod = sd_lod(VERTEX, macro_near, macro_far);
		if (mlod > 0.001) {
			// sd_fbm's two octaves sum to 0.75, not 1.0, so its mean is 0.375. Subtracting a flat
			// 0.5 would bias the whole surface ~1.6% dark instead of just varying it; normalise
			// first so this band only ever adds variation.
			float m = sd_fbm(opos * macro_scale, 2) * 1.3333 - 0.5;
			ALBEDO *= vec3(1.0 + m * macro_amount * mlod);
		}
	}

	// The one encode, after every band has had its say. Identity on Forward+.
	ALBEDO = pc_out(ALBEDO);
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float lit = smoothstep(-ramp_softness, ramp_softness, ndl) * ATTENUATION;
	vec3 shadow_col = ALBEDO * mix(vec3(1.0), pc_in(shade_tint.rgb), shade_strength);
	float floor_level = mix(shadow_floor, shade_floor, ATTENUATION);
	vec3 diffuse = mix(shadow_col * floor_level, ALBEDO, lit);
	DIFFUSE_LIGHT += diffuse * LIGHT_COLOR / PI;

	vec3 h = normalize(VIEW + LIGHT);
	float ndh = max(dot(NORMAL, h), 0.0);
	float rough_size = spec_size * mix(1.0, 0.35, clamp(ROUGHNESS, 0.0, 1.0));
	float spec = smoothstep(0.5, 0.78, pow(ndh, rough_size)) * spec_strength * lit;
	SPECULAR_LIGHT += spec * LIGHT_COLOR / PI;

	float rim = 1.0 - max(dot(NORMAL, VIEW), 0.0);
	rim = smoothstep(0.6, 0.9, rim) * rim_strength * lit;
	SPECULAR_LIGHT += rim * pc_in(rim_color.rgb) * LIGHT_COLOR / PI;

	if (v_sheen > 0.001) {
		float sheen = (surface_kind == 1)
			? sd_cloth_sheen(NORMAL, VIEW, v_sheen)
			: sd_sheen(NORMAL, VIEW, LIGHT, v_sheen);
		SPECULAR_LIGHT += sheen * lit * LIGHT_COLOR / PI;
	}
}
