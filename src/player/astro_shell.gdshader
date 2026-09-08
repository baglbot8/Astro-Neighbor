// The astronaut's suit shader: src/shaders/toon_soft.gdshader with two extra terms that exist for
// one reason — a big, smooth, near-white pressure suit is the hardest thing in this art style to
// keep from turning into a marshmallow.
//
// A critic measured the old helmet at literally (255,255,255) with ZERO value gradient across the
// whole dome: "a flat circle, not a sphere", 43% blown highlights on the character crop. A toon
// ramp alone cannot fix that, because the entire sun-facing half of a sphere is one flat "lit"
// value by construction. So:
//   * `limb_darken` darkens the albedo towards the silhouette (limb darkening). This is what makes
//     a sphere read as a sphere in every painted/illustrated style, and it costs one dot product.
//   * `floor_shade` darkens downward-facing surfaces. Animal Crossing's forms all have a darker
//     underside (the style guide calls it out for tree canopies); on a character it grounds the
//     helmet against the shoulders and the torso against the legs.
// Both act on ALBEDO, so they survive into shadow and never introduce a rim-light hotspot.
//
// Uniform names are kept identical to toon_soft.gdshader so the two stay interchangeable.
//
// ---------------------------------------------------------------------------- R2.9 SURFACE DETAIL
// The user: *"I want to minimize larger surfaces on important things that dont have a 'texture' to
// them... Notably things like the astronaut's helmet/clothes"*. This shader draws the four biggest
// surfaces on the character (the dome, the torso, the sleeves and the legs), so it speaks the same
// vocabulary as src/shaders/toon_soft.gdshader: it includes the SHARED
// src/shaders/surface_detail.gdshaderinc and calls the SAME sd_cloth / sd_metal / sd_rock /
// sd_sheen / sd_cloth_sheen functions with the SAME `surface_kind` numbering, so there is one place
// to tune the whole game. Nothing here reimplements a private version of any of that.
//
// It differs from toon_soft in exactly one respect, and it is a frequency problem specific to this
// character. The library's fine patterns are authored around 190 cycles/m (cloth) and 320 cycles/m
// (metal brush). A 0.09 m limb at the 6.5 m gameplay camera is ~24 px wide, which puts those
// patterns well past Nyquist — they would sparkle as the astronaut walks, which is precisely the
// moire the library's own header warns about. But the metal SHEEN is the opposite case: it is a
// broad, low-frequency lobe that is still doing useful work at 6.5 m, and `sd_metal` ties its
// `aniso` to the same lod AND leaves it on a 0.20 floor that snaps to zero the instant lod hits 0
// (see the report). So this shader runs TWO fades:
//   * `surface_lod_near/far` — a TIGHT fade for the fine grain/weave (tint, roughness, normal).
//   * `sheen_near/far`       — a BROAD, continuous fade for the sheen only, with no floor to pop.
// Detail is model-space (the `v_objpos` varying, exactly as toon_soft does it), so the weave does
// not swim across the suit as the astronaut walks.
//
// R2.6 is NOT undone: every term below moves ROUGHNESS, NORMAL or ALBEDO. The only specular this
// adds is `sd_sheen`'s broad low-amplitude lobe, which is capped by `sheen_strength` and measured
// (blown highlights stay under the 5% gate).
shader_type spatial;
render_mode cull_back, depth_draw_opaque, diffuse_lambert, specular_schlick_ggx;

global uniform float astro_night;

#include "res://src/shaders/surface_detail.gdshaderinc"

// --- WEB PARITY: THE COMPATIBILITY sRGB HELPERS, INLINED -----------------------------------------
// THE CANONICAL COPY AND THE FULL WRITE-UP LIVE AT THE TOP OF src/shaders/planet_common.gdshaderinc.
// Read that first: the measurement, the probe numbers (maxdiff 0), the conversion recipe and the
// list of things that must NOT be wrapped. The block below is byte-identical to the one inlined in
// src/shaders/toon_soft.gdshader; this shader is toon_soft's sibling (same uniform names, so the two
// stay interchangeable) and it has no other reason to pull in the whole planet ground library, so it
// gets its own copy. Keep the three copies identical if any of them is ever changed.
//
// One-paragraph version: Compatibility (WebGL2, which the web export is forced onto and which is
// what the game is actually played on) does not sRGB-decode `source_color` uniforms on upload the
// way Forward+ does, and it sRGB-ENCODES whatever fragment() writes to ALBEDO/EMISSION. So a colour
// uniform arrives in DISPLAY space and every multiply done on it inside fragment() lands as t^2.2.
// This shader does FIVE such multiplies on the suit colour before it reaches ALBEDO — `limb_darken`,
// `floor_shade`, the surface-detail tint, the seam groove and the topstitch — which is exactly the
// contrast expansion the astronaut has been showing on the phone.
//
// `astro_compat` is 1.0 only under Compatibility (Platform._apply_renderer_parity), so every wrap
// below is the exact identity on desktop and the Forward+ reference look cannot move.
//
// MEASURED, in the real gameplay frame (res://src/world/world.tscn on home, camera orbited to the
// front with CameraRig.orbit_front so the suit and the visor both face the lens), Forward+ against
// Compatibility, scored ONLY on THIS shader's own pixels — a mask built by differencing a normal
// capture against one in which this file alone was swapped for a flat magenta unshaded shader, then
// eroded 1 px so no antialiased silhouette pixel (a blend of this shader and whatever is behind it)
// is charged to it. Two independent capture configurations, different RNG seed and different
// capture time, so the character stands in a different idle pose in each:
//   config a (seed 7, t=4.0s, 10,398 px)    before  MAE 10.27  p95 29.7   region SAT gap 0.0216
//                                           after   MAE  0.88  p95  3.3   region SAT gap 0.0086
//   config b (seed 13, t=5.5s, 11,004 px)   before  MAE 10.14  p95 29.7   region SAT gap 0.0222
//                                           after   MAE  0.86  p95  3.0   region SAT gap 0.0083
// The two configurations agree to 0.02 codes, so the numbers are the shader's and not a capture's.
// FORWARD+ DID NOT MOVE: the F+ frame before this change and the F+ frame after it are byte-
// identical over the mask (MAE 0.00, max 0.0), which is what `astro_compat == 0.0` guarantees.
//
// THOSE ARE SHADER NUMBERS AND THE FRAME THEY WERE TAKEN IN IS NOT THE SHIPPED FRAME. Per rule (i)
// in planet_common, the browser build deliberately renders a cheaper picture, and on a CHARACTER one
// of those decisions swamps everything else: `_no_cast_shadows` (environment.gd:683) turns the sun's
// shadow pass off under Compatibility, and an astronaut self-shadows heavily — the torso across the
// thighs, the helmet across the collar. Scoring F+ WITH those self-shadows against Compatibility
// WITHOUT them measures that decision, not this file: it reads MAE 17.6 before and 22.3 after, i.e.
// it moves the wrong way and says nothing about the conversion. The gate above therefore runs with
// the cast-shadow pass off on BOTH renderers (and SSAO, glow, MSAA/FXAA and prop scatter equalised
// the same way), which is the only configuration in which the two frames contain the same light.
// That equalisation lives in the measuring rig, never in the tree.
global uniform float astro_compat;

vec3 pc_s2l(vec3 q) { return mix(q / 12.92, pow((q + vec3(0.055)) / 1.055, vec3(2.4)), step(vec3(0.04045), q)); }
vec3 pc_l2s(vec3 q) { q = max(q, vec3(0.0)); return mix(q * 12.92, 1.055 * pow(q, vec3(1.0 / 2.4)) - vec3(0.055), step(vec3(0.0031308), q)); }
vec3 pc_in_f(vec3 q, float compat) { return (compat > 0.5) ? pc_s2l(q) : q; }
vec3 pc_out_f(vec3 q, float compat) { return (compat > 0.5) ? pc_l2s(q) : q; }
// Macros, not functions, so `astro_compat` is resolved at the CALL site — a function in a shared
// include cannot see a uniform the including shader declares further down. See planet_common.
#define pc_in(q) pc_in_f((q), astro_compat)
#define pc_out(q) pc_out_f((q), astro_compat)

// Shared R2.9 vocabulary, same names and same numbering as toon_soft.gdshader.
// `surface_kind`: 0 none, 1 cloth, 2 metal, 3 wood (unused here), 4 rock, 5 foliage (unused here).
uniform int surface_kind : hint_range(0, 5) = 0;
uniform float surface_strength : hint_range(0.0, 2.0) = 1.0;
uniform float surface_lod_near : hint_range(0.5, 40.0) = 1.4;
uniform float surface_lod_far : hint_range(1.0, 80.0) = 5.0;
// The sheen's own fade. Broad and continuous so a helmet does not pop as the player backs away.
uniform float sheen_strength : hint_range(0.0, 1.0) = 0.0;
uniform float sheen_near : hint_range(0.5, 40.0) = 6.0;
uniform float sheen_far : hint_range(1.0, 80.0) = 22.0;

// ---- Panel seams and topstitch. R2.9's cloth row asks for "seams and stitching where panels
// meet", and a real pressure garment is built from ring seams around the limb and vertical gores up
// it — which is why these follow the PART's own model axes (rings along model +Y, gores around it)
// rather than a world grid. They are far lower frequency than the weave, so they ride their own,
// much wider fade and are still legible at the 6.5 m gameplay camera when the weave has gone.
// `seam_rings` = ring seams per metre (0 disables), `seam_gores` = vertical panels around the axis.
uniform float seam_strength : hint_range(0.0, 1.0) = 0.0;
uniform float seam_rings : hint_range(0.0, 30.0) = 0.0;
uniform float seam_gores : hint_range(0.0, 16.0) = 0.0;
// Phase of the gore seams, in periods. It defaults to HALF a period for a reason: with the phase at
// zero a gore lands exactly on the centre-front of the torso, which is the vertical placket R2.7
// calls "a wetsuit zip" and had already been removed once. Half a period straddles the centreline
// so the panels meet off to the sides, as they do on the references.
uniform float seam_gore_phase : hint_range(0.0, 1.0) = 0.5;
uniform float seam_far : hint_range(1.0, 80.0) = 9.0;

varying vec3 v_objpos;
/// MODEL-space normal. `sd_metal` picks its brush direction from the normal it is handed, and
/// toon_soft hands it the VIEW-space one, so on a curved part the grain direction re-picks itself
/// as the camera orbits and the streaks crawl. Feeding it the model-space normal locks the brush to
/// the object, which is the same reasoning that put the detail in model space to begin with.
varying vec3 v_objnorm;
varying float v_sheen;
/// Model +Y and the tangential (around-the-axis) direction, both in VIEW space, so a seam crease
/// can push the normal ACROSS the seam instead of in some arbitrary direction.
varying vec3 v_axis_up;
varying vec3 v_axis_tan;

void vertex() {
	v_objpos = VERTEX;
	v_objnorm = NORMAL;
	v_axis_up = normalize((MODELVIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
	v_axis_tan = normalize((MODELVIEW_MATRIX * vec4(VERTEX.z, 0.0, -VERTEX.x, 0.0)).xyz + vec3(1e-6));
}

/// Signed distance (in seam periods) to the nearest seam line, -0.5..0.5.
float seam_offset(float u) {
	return fract(u + 0.5) - 0.5;
}

uniform vec4 albedo : source_color = vec4(1.0);
uniform float ramp_softness : hint_range(0.01, 1.0) = 0.38;
uniform float shade_strength : hint_range(0.0, 1.0) = 0.36;
uniform vec4 shade_tint : source_color = vec4(0.62, 0.58, 0.86, 1.0);
uniform float shade_floor : hint_range(0.0, 1.0) = 0.58;
uniform float shadow_floor : hint_range(0.0, 1.0) = 0.10;
uniform float rim_strength : hint_range(0.0, 2.0) = 0.10;
uniform vec4 rim_color : source_color = vec4(1.0, 0.97, 0.9, 1.0);
uniform float spec_strength : hint_range(0.0, 2.0) = 0.05;
uniform float spec_size : hint_range(1.0, 400.0) = 60.0;
uniform vec4 emission_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float emission_strength : hint_range(0.0, 8.0) = 0.0;
uniform float emission_day_scale : hint_range(0.0, 1.0) = 0.15;
uniform float emission_cap : hint_range(0.2, 8.0) = 1.9;
uniform float roughness : hint_range(0.0, 1.0) = 0.9;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
// How much darker the albedo goes at the silhouette edge (0 = plain toon_soft behaviour).
uniform float limb_darken : hint_range(0.0, 1.0) = 0.26;
uniform float limb_power : hint_range(0.5, 8.0) = 2.4;
// How much darker a fully downward-facing surface is than an upward-facing one.
uniform float floor_shade : hint_range(0.0, 1.0) = 0.18;

void fragment() {
	// pc_in ONCE, at the uniform's first use, before any of the maths below. Everything from here to
	// the pc_out at the bottom of fragment() therefore runs in LINEAR space on both renderers.
	vec3 base = pc_in(albedo.rgb);
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), limb_power);
	base *= mix(1.0, 1.0 - limb_darken, fres);
	// NORMAL is view space in fragment(); rotate it back to world to find which way is up.
	float up = (INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).y * 0.5 + 0.5;
	base *= mix(1.0 - floor_shade, 1.0, smoothstep(0.0, 0.85, up));
	ALBEDO = base;
	ROUGHNESS = roughness;
	METALLIC = metallic;

	// ---- R2.9 fine material character, from the shared library. VERTEX is view-space here, so its
	// length is the distance to the camera, which is what sd_lod() wants.
	v_sheen = 0.0;
	if (surface_kind > 0) {
		float lod = sd_lod(VERTEX, surface_lod_near, surface_lod_far);
		SdSurface sd = sd_none();
		vec3 onorm = normalize(v_objnorm);
		if (surface_kind == 1) { sd = sd_cloth(v_objpos, onorm, lod, surface_strength, 1.0); }
		else if (surface_kind == 2) { sd = sd_metal(v_objpos, onorm, lod, surface_strength, 1.0); }
		else if (surface_kind == 3) { sd = sd_wood(v_objpos, vec3(0.0, 1.0, 0.0), lod, surface_strength, 1.0, 0.55); }
		else if (surface_kind == 4) { sd = sd_rock(v_objpos, onorm, lod, surface_strength, 1.0); }
		else { sd = sd_foliage(v_objpos, onorm, lod, surface_strength, 1.0); }
		ALBEDO *= sd.tint;
		ROUGHNESS = clamp(ROUGHNESS + sd.rough, 0.0, 1.0);
		NORMAL = normalize(NORMAL + sd.bump);
		// The library's own `aniso` is deliberately NOT used (see the header): it rides the fine
		// lod and sits on a floor that snaps off at `surface_lod_far`. The sheen gets its own broad
		// fade to zero instead, so the dome keeps a travelling highlight at gameplay distance and
		// nothing pops as the camera pulls back.
		v_sheen = sheen_strength * sd_lod(VERTEX, sheen_near, sheen_far);
	}

	// ---- R2.9 seams and topstitch, in the part's own model space.
	if (seam_strength > 0.001 && (seam_rings > 0.001 || seam_gores > 0.001)) {
		float slod = sd_lod(VERTEX, surface_lod_near, seam_far) * seam_strength;
		// Ring seams around the limb, `seam_rings` per metre of the part's own long axis.
		float ring_u = v_objpos.y * seam_rings;
		float ring_s = seam_rings > 0.001 ? seam_offset(ring_u) : 0.5;
		// Vertical gore seams: `seam_gores` panels around that axis.
		float turns = atan(v_objpos.x, v_objpos.z) * 0.15915494;
		float gore_s = seam_gores > 0.001 ? seam_offset(turns * seam_gores + seam_gore_phase) : 0.5;
		// Groove profile: a soft V a fifth of a period wide.
		float ring_g = 1.0 - smoothstep(0.0, 0.20, abs(ring_s));
		float gore_g = 1.0 - smoothstep(0.0, 0.20, abs(gore_s));
		float groove = max(ring_g, gore_g);
		// Topstitch: a dashed bead sitting just off the groove, running ALONG each seam. The dash
		// phase comes from the other axis, so ring stitches run around the limb and gore stitches
		// run up it, exactly as they would on a sewn panel.
		float ring_dash = 0.5 + 0.5 * sin(turns * 100.5);
		float gore_dash = 0.5 + 0.5 * sin(v_objpos.y * 118.0);
		float stitch = max(
			ring_g * smoothstep(0.35, 0.85, ring_dash) * smoothstep(0.02, 0.11, abs(ring_s)),
			gore_g * smoothstep(0.35, 0.85, gore_dash) * smoothstep(0.02, 0.11, abs(gore_s)));
		ALBEDO *= 1.0 - groove * 0.115 * slod;
		ALBEDO *= 1.0 + stitch * 0.075 * slod;
		ROUGHNESS = clamp(ROUGHNESS + groove * 0.12 * slod - stitch * 0.05 * slod, 0.0, 1.0);
		// A real crease: push the normal ACROSS the seam, using the part's own axes.
		NORMAL = normalize(NORMAL
			- v_axis_up * ring_g * clamp(ring_s * 5.0, -1.0, 1.0) * 0.11 * slod
			- v_axis_tan * gore_g * clamp(gore_s * 5.0, -1.0, 1.0) * 0.09 * slod);
	}

	vec3 em = pc_in(emission_color.rgb) * emission_strength * mix(emission_day_scale, 1.0, astro_night);
	float peak = max(em.r, max(em.g, em.b));
	EMISSION = pc_out((peak > emission_cap) ? em * (emission_cap / peak) : em);
	// The one encode of the frame, AFTER the surface detail and the seams, so every multiply above
	// happened in linear on both renderers. Compatibility applies its own srgb_to_linear() to this
	// value once fragment() returns and pc_out is the exact inverse of that; identity on Forward+.
	// light() below still sees the linear ALBEDO on both renderers (measured: light() sees the same
	// ALBEDO the engine goes on to multiply DIFFUSE_LIGHT by, exactly once).
	ALBEDO = pc_out(ALBEDO);
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float lit = smoothstep(-ramp_softness, ramp_softness, ndl) * ATTENUATION;
	vec3 shadow_col = ALBEDO * mix(vec3(1.0), pc_in(shade_tint.rgb), shade_strength);
	float floor_level = mix(shadow_floor, shade_floor, ATTENUATION);
	DIFFUSE_LIGHT += mix(shadow_col * floor_level, ALBEDO, lit) * LIGHT_COLOR / PI;

	vec3 h = normalize(VIEW + LIGHT);
	float spec = smoothstep(0.5, 0.78, pow(max(dot(NORMAL, h), 0.0), spec_size)) * spec_strength * lit;
	SPECULAR_LIGHT += spec * LIGHT_COLOR / PI;

	float rim = smoothstep(0.6, 0.9, 1.0 - max(dot(NORMAL, VIEW), 0.0)) * rim_strength * lit;
	SPECULAR_LIGHT += rim * pc_in(rim_color.rgb) * LIGHT_COLOR / PI;

	// R2.9 sheen, from the shared library so the astronaut's metal matches the rocket's and the
	// neighbours'. Cloth catches light only at grazing angles (sd_cloth_sheen); metal gets the
	// broad travelling lobe (sd_sheen). Both are deliberately low-amplitude — this is the "matte
	// but not flat" the style guide asks for, not a hotspot.
	if (v_sheen > 0.001) {
		float sheen = (surface_kind == 1)
			? sd_cloth_sheen(NORMAL, VIEW, v_sheen)
			: sd_sheen(NORMAL, VIEW, LIGHT, v_sheen);
		SPECULAR_LIGHT += sheen * lit * LIGHT_COLOR / PI;
	}
}
