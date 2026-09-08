// Soft radial blob shadow under characters (readability aid on top of real shadows).
//
// --- WEB PARITY: DELIBERATELY NOT CONVERTED, AND THE MEASUREMENT THAT SAYS SO ------------------
// Every other surface shader in this project has been given the pc_in()/pc_out() treatment from the
// top of src/shaders/planet_common.gdshaderinc. This one has not, and must not be, for two reasons
// that were both measured on res://src/world/world.tscn (home, camera orbited to the front, the
// blob's own 1,438-pixel mask, Forward+ against Compatibility, two independent captures):
//
// 1. THE CONVERSION WOULD BE A LITERAL NO-OP. The recipe's own opening paragraph says the two
//    renderers already break even for a shader that assigns a `source_color` uniform STRAIGHT to
//    ALBEDO with no maths in between, because Compatibility's srgb_to_linear on the way out is the
//    exact inverse of the decode Forward+ does on upload. `ALBEDO = color.rgb` is that shader.
//    pc_out(pc_in(color.rgb)) is the identity function, not a fix. MEASURED, with this shader's
//    ALPHA forced to 1.0 so only its colour is under test: MAE 0.67 codes, max 0.7, on both
//    captures. It is already at parity and there is nothing here to correct.
//
// 2. THE REAL GAP IS THE ALPHA BLEND, WHICH NO SHADER CAN REACH. As shipped (blend_mix, alpha
//    ~0.5 over the ground) the same mask reads MAE 11.76 / p95 19.3 and MAE 10.64 / p95 18.3 on the
//    two captures, Compatibility rendering the blob much DARKER (median luma 59 against 80). That is
//    the same mechanism as the shadow-pass finding recorded above _apply() in src/world/environment.gd:
//    Compatibility combines a blend in sRGB-ENCODED space where Forward+ combines it in linear.
//    Mixing a dark source into a bright destination in encoded space lands darker — worked example,
//    dst linear 0.22 (code 128) and src linear 0.014 (code 33) at a = 0.5: linear gives code 96,
//    encoded gives code 80, and the measurement sits between them at the blob's real alpha.
//    The destination colour is not available to this shader, so no pre-distortion of ALBEDO can undo
//    it; a term that tried would be a fitted constant against one ground colour, which is precisely
//    the class of fix this project has already reverted three times. The cause-level fix belongs
//    with the same engine-side blend the environment note describes, not here.
//
// --- BATCHED MODE, ADDED FOR THE PROP CONTACT SHADOWS ------------------------------------------
// The Compatibility renderer now runs with the sun's shadow pass switched OFF (`_no_cast_shadows`
// in src/world/environment.gd; the mechanism and the 26-63 code GAP it closes are documented
// there). That fix cost the props their contact: an art review of the before/after pair called out
// the hub plaza bench "hovering a few centimetres above the tiles", and noted in the same breath
// that the astronaut does NOT float, because THIS shader is still under its boots. So the same
// blob goes under the props.
//
// `instanced` is the only addition. At its default 0.0 the branch is not taken and the fragment
// body is exactly what the player's material has always run — no new maths, no new constant on the
// player's path, so the astronaut's blob is unchanged on both renderers. At 1.0 the edge softness
// comes from the MultiMesh's per-instance custom data instead of from the uniform, which is what
// lets several hundred props of very different footprints share ONE draw call and ONE material.
// It is a uniform branch, so it is coherent across every fragment in the batch.
//
// Custom data layout, written by PlanetProps._build_contact_shadows():
//   .x = softness (see that function for why it is per-instance and not a uniform)   .yzw unused
// The instance TRANSFORM carries a non-uniform in-plane scale, so a batched blob is an ELLIPSE
// aimed down its prop's own X axis (a bench's pool lies along the bench). Nothing here has to know:
// the falloff is radial in UV, which the non-uniform scale stretches for free.
// It is read in vertex() and carried across in a varying because INSTANCE_CUSTOM does not exist in
// fragment() — reading it there is a compile error on both renderers, not a silent zero.
// `strength` and `color` stay uniforms because every blob in one batch shares them.
// A `mix()` was the obvious way to write this and is deliberately NOT used: INSTANCE_CUSTOM is not
// guaranteed to be a finite value on a plain MeshInstance3D (the player's blob is one), and a NaN
// there would survive `mix(x, NaN, 0.0)` and blank the astronaut's shadow. The branch cannot.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

uniform vec4 color : source_color = vec4(0.12, 0.09, 0.28, 0.5);
uniform float softness : hint_range(0.05, 1.0) = 0.55;
uniform float strength : hint_range(0.0, 1.0) = 1.0;
uniform float instanced : hint_range(0.0, 1.0) = 0.0;

varying float v_soft;

void vertex() {
	v_soft = softness;
	if (instanced > 0.5) {
		v_soft = INSTANCE_CUSTOM.x;
	}
}

void fragment() {
	float soft = v_soft;
	vec2 d = UV - vec2(0.5);
	float r = length(d) * 2.0;
	float a = 1.0 - smoothstep(1.0 - soft, 1.0, r);
	ALBEDO = color.rgb;
	ALPHA = a * a * color.a * strength;
}
