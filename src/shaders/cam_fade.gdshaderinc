// Camera near-geometry fade as a SCREEN-DOOR DITHER (CameraRig, src/player/camera_rig.gd).
//
// WHY THIS EXISTS. CameraRig ghosts a layer-4 prop that stands between the camera and the astronaut.
// It used to do that with GeometryInstance3D.transparency = 0.90. The Compatibility renderer - the
// WebGL2 web build the game is actually played on - never reads that value: in Godot 4.7.1
// drivers/gles3 never reads the instance force_alpha that set_transparency writes, while Forward+
// multiplies it into the instance alpha. Measured in world.tscn at 2556x1179 with --ui=mobile and
// --fade-off as the same-run control: hub Lamp, hub Topiary, home PuffTree and home Rock drew SOLID
// in Compatibility (on-vs-off at the noise floor, the astronaut fully hidden behind the topiary and
// the tree) and drew the ghost in Forward+ (on-vs-off mean abs RGB 12.1 / 9.5 / 3.2 / 7.4).
//
// WHY A PER-MATERIAL UNIFORM AND NOT AN `instance uniform`. In Compatibility every GeometryInstance
// whose material declares any instance uniform takes 16 slots of the global shader uniform buffer,
// sized GL_MAX_UNIFORM_BLOCK_SIZE / 16. WebGL2 on Apple (ANGLE Metal) reports 16384 bytes = 1024
// slots, so about 63 instances for the whole scene; the hub alone has 385 toon_soft instances. So
// `cam_fade` is a plain uniform, and CameraRig writes it only on its OWN duplicated copy of each
// material of the prop being faded - never on a shared or cached MaterialLib material.
//
// WHY DISCARD AND NOT ALPHA. A material that writes ALPHA casts no shadow in either renderer and is
// sorted as transparent; StandardMaterial3D's alpha hash draws solid in Compatibility. A 4x4 Bayer
// screen door with discard works identically in both renderers (cam_fade 0.9 removes exactly 14/16
// pixels) and keeps the prop in the OPAQUE pipeline: no sorting against the plaza, and no stacking -
// a topiary's three leaf tiers remove the same screen pixels, so the astronaut shows through all of
// them at once instead of through 10 % x 10 % x 10 % of alpha.
//
// WHY BOTH GUARDS. Without a guard the dither punches the same holes into the prop's own shadow.
// `!IN_SHADOW_PASS` keeps the shadow whole in Compatibility but NOT in Forward+ (4.7.1, repeated);
// `PROJECTION_MATRIX[3][3] == 0.0` (a perspective projection, i.e. the camera and not the
// orthographic directional shadow pass) keeps it whole in both. Both are kept: IN_SHADOW_PASS is the
// one that matters where the discard compiles today (Compatibility, see below), and the perspective
// test keeps shadows whole if the dither is ever compiled for Forward+ as well.
//
// COST - NOT FREE. With cam_fade 0 the branch is never taken, so no picture changes, but the frame
// gets slower. Hub, Compatibility, phone size, GPU-bound at scaling_3d_scale 2.0, --disable-vsync, M5
// (2026-09-13): all 11 shaders hooked cost about +1.1 ms per frame (~4%), even with nothing fading
// (builder medians 28.37 -> 29.40 ms, the same in every A/B pair; critic re-run with --fade-off
// 28.27 / 27.76 -> 29.45 / 28.86 ms). Bisection: keeping the include and uniform but removing the
// discard line costs nothing, so the cost is the discard line itself; hooking only toon_soft and
// planet_foliage cost about +0.5 ms. An earlier A/B of those two shaders read +0.06 ms inside a
// 2-8 ms run-to-run spread: too noisy to see it, not proof it was free.
// At the game's scaling_3d_scale 0.75 on this Mac every frame sits at the 16.65 ms compositor cap, so
// it does not show there. The iPhone (a tile-based GPU, where discard can cost more) is unmeasured.
// Those numbers were taken before the discard was limited to Compatibility (the #if below); the
// desktop Forward+ build no longer compiles it.
//
// HOW TO HOOK A SHADER: `#include` this at file scope ABOVE vertex(), then make CAM_FADE_DISCARD the
// first statement of fragment(). It is a macro because FRAGCOORD, IN_SHADOW_PASS and
// PROJECTION_MATRIX are only visible inside fragment(). CameraRig recognises a hookable material by
// its shader declaring `cam_fade`.

// Fraction of the prop's pixels removed. 0 = solid (the default every material ships with).
uniform float cam_fade : hint_range(0.0, 1.0) = 0.0;

// COMPATIBILITY ONLY. CameraRig dithers only under Compatibility; Forward+ keeps
// GeometryInstance3D.transparency. So the discard is compiled only where it is used, and every other
// renderer - the desktop build - draws these shaders exactly as before, without the cost above.
// CURRENT_RENDERER is Godot's built-in preprocessor define (the current rendering method).
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY

// 4x4 Bayer threshold for a screen pixel, (i + 0.5) / 16. Tied to the screen, not the mesh, so every
// surface of a prop - and every prop - removes the same pixels.
float cam_fade_threshold(vec2 frag) {
	int x = int(mod(floor(frag.x), 4.0));
	int y = int(mod(floor(frag.y), 4.0));
	int i = 0;
	if (y == 0) {
		i = x == 0 ? 0 : (x == 1 ? 8 : (x == 2 ? 2 : 10));
	} else if (y == 1) {
		i = x == 0 ? 12 : (x == 1 ? 4 : (x == 2 ? 14 : 6));
	} else if (y == 2) {
		i = x == 0 ? 3 : (x == 1 ? 11 : (x == 2 ? 1 : 9));
	} else {
		i = x == 0 ? 15 : (x == 1 ? 7 : (x == 2 ? 13 : 5));
	}
	return (float(i) + 0.5) / 16.0;
}

#define CAM_FADE_DISCARD if (cam_fade > 0.0 && !IN_SHADOW_PASS && PROJECTION_MATRIX[3][3] == 0.0 && cam_fade_threshold(FRAGCOORD.xy) < cam_fade) { discard; }

#else

#define CAM_FADE_DISCARD

#endif
