// Vertex-colored toon with wind sway for foliage: grass tufts, flowers, tree canopies, tentacle plants.
// Thin blades/flags are built double-sided by PlanetMeshKit, so back-face culling stays on.
// Sway is applied in model space along local X/Z, scaled by (local height / sway_height)^2 so the
// base stays planted. With MultiMesh + use_custom_data, INSTANCE_CUSTOM.rgb tints vertices whose
// COLOR.a is > 0.5 (petals), leaving stems (COLOR.a == 0) with their baked color.
//
// R2.6 / "the greens are popping" — THE ALBEDO USED TO BE APPLIED TWICE. See the long note on
// pc_light_term in planet_common.gdshaderinc: the renderer multiplies whatever light() writes to
// DIFFUSE_LIGHT by ALBEDO afterwards, so composing the finished colour here squared it. On a leaf
// green that turned linear (0.074, 0.342, 0.223) into (0.005, 0.117, 0.050) — red crushed to 1/255,
// saturation 0.78 -> 0.95 — and the bush beside the player rendered #065f33 / #0b7e3e at S 0.91-0.94
// against the R2.6 ceiling of 0.68. Every brightness constant below was tuned around that square, so
// they are all re-derived here: light_gain 0.62 -> 0.36, ambient_damp 0.16 -> 0.24, shade_floor 0.76 -> 0.70.
//
// R2.9 SURFACE TEXTURE. Two materials share this shader, and they are told apart by COLOR.a:
//   * LEAF (COLOR.a outside 0.20-0.60) — canopies, bush clumps, mushroom caps, petals, blades.
//     "plump softness ... a soft, slightly translucent read with fine tuft/blade detail" plus a hint
//     of subsurface warmth where the sun passes through a leaf.
//   * WOOD (COLOR.a in 0.20-0.60) — trunks, stems and the woody base of a bush, marked by
//     PlanetPropMeshes with WOOD_ALPHA. "directional grain running along the plank, with knots".
shader_type spatial;
render_mode cull_back, depth_draw_opaque, diffuse_lambert, specular_schlick_ggx;
#include "res://src/shaders/planet_common.gdshaderinc"
#include "res://src/shaders/surface_detail.gdshaderinc"

// WEB PARITY (docs/OPEN_ISSUES.md 32). Under the Compatibility (WebGL2) renderer the canopy
// comes out far too dark: measured V 0.293 against a Forward+ target of 0.513. The correction
// is a straight LIFT of this shader's own light gain, NOT a corrective albedo divide — that
// was tried twice and rendered the trees white and pink both times, because dividing by a dark
// leaf albedo is a ~14x multiply that clips into the ACES shoulder where chroma collapses.
// `astro_compat` is 1.0 only under Compatibility, so this is a no-op on desktop and mobile.
global uniform float astro_compat;
// 3.6 was fitted to the tree CANOPY crop alone. Grass tufts run through the same shader with a
// much lighter albedo, and at 3.6 they rendered almost white on a real iPhone. Fit to both.
uniform float compat_light_boost : hint_range(1.0, 6.0) = 2.0;

uniform vec4 albedo : source_color = vec4(1.0);
uniform float sway_amount = 0.05;
uniform float sway_speed = 1.6;
uniform float sway_height = 1.0;
uniform bool use_instance_tint = false;
uniform vec4 emission_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float emission_strength : hint_range(0.0, 8.0) = 0.0;
uniform float ramp_softness : hint_range(0.01, 1.0) = 0.45;
uniform float shade_strength : hint_range(0.0, 1.0) = 0.34;
// Foliage shade floor is HIGH on purpose: an ACNH canopy is an even gradient (lit crown ~1.0, shade
// side ~0.75), not a two-tone poster. At 0.66 the vertical faces of a lower tier dropped to half the
// crown's value and the canopy read as blotchy. The dark underside comes from the vertex colour.
uniform float shade_floor : hint_range(0.0, 1.0) = 0.70;
// LOW-CHROMA shade tint (was 0.62/0.55/0.85, a fully saturated lavender). A strongly chromatic tint
// multiplies the leaf's already-weak red channel down again, which is a saturation BOOST dressed up
// as a shadow. A surface in shade is lit by broad-spectrum skylight: it should lose chroma, not gain
// it. This is a cool grey with just enough violet in it to keep the ACNH shadow hue.
uniform vec4 shade_tint : source_color = vec4(0.74, 0.72, 0.82, 1.0);
uniform float rim_strength : hint_range(0.0, 2.0) = 0.09;
// R2.6 MATTE: leaves are the most matte thing on a planet. The old 0.12 fake specular painted a
// bright ellipse across the top of every canopy tier, which read as wet plastic.
uniform float spec_strength : hint_range(0.0, 2.0) = 0.03;
// R2.6 pastel guard (pc_pastel in planet_common.gdshaderinc). With the albedo applied once this is
// the ONLY thing setting the canopy's chroma, so it is what the saturation gate answers to. The leaf
// colours in PlanetData are authored in sRGB and baked to LINEAR vertex colours by PlanetMeshKit, so
// a hex of S 0.51 arrives here at S 0.78 — the cap does the real work.
uniform float pastel_max : hint_range(0.05, 1.0) = 0.72;
uniform float pastel_dark : hint_range(0.0, 1.0) = 0.30;
// Ambient reaching the canopy. Now that the albedo is applied once, this is a genuine sky fill on
// down-facing surfaces rather than a doubly-darkened trace, so it can carry the tier undersides
// instead of letting them posterise to a black slab.
uniform float ambient_damp : hint_range(0.0, 1.0) = 0.24;
// How much of a CAST shadow foliage actually receives. A canopy is a cluster of overlapping tiers,
// so at 1.0 the tiers shadow-map each other into irregular near-black blotches that read as mould or
// rot. ACNH foliage is shaded by an even gradient plus its own tier edges, so we keep a fraction of
// the cast term and floor it (cast_floor). The tree still CASTS its full shadow on the ground.
uniform float cast_shadow_recv : hint_range(0.0, 1.0) = 0.35;
// Chroma cap on the LIT product. planet_common's shared PC_LIGHT_S_MAX (0.55) is a no-op on ground
// albedo but bites hard on the more chromatic leaf colours, costing the canopy 28% of its saturation
// exactly where the reference is greenest. Foliage gets its own, looser cap.
uniform float light_s_max : hint_range(0.2, 1.0) = 0.74;
// Sunlit canopies land high on the ACES shoulder, where chroma collapses to a pale sage. Foliage
// takes a fraction of the direct sun so the crown sits where the curve still holds colour — which is
// true to the reference too, where the canopy is clearly darker than the lawn it stands on.
// Re-derived after the double-albedo fix: at 0.62 the crown came out #90c1a9 S 0.25 (pale sage
// again); 0.38 puts it at #5caa7f S 0.46 V 0.67 against ACNH's #5eb972 S 0.49 V 0.73.
uniform float light_gain : hint_range(0.2, 1.5) = 0.36;
// Chroma clamp on the SHADE side specifically. Measured against reference/AC Reference 3: the ACNH
// shaded canopy is #5b9e76 S 0.42, i.e. LESS saturated than its sunlit crown, never more.
uniform float shade_s_max : hint_range(0.1, 1.0) = 0.44;
uniform float shade_desat : hint_range(0.0, 1.0) = 0.32;
// How dark a canopy goes inside a CAST shadow (its own upper tier, or a neighbour). A canopy is not
// an opaque wall - light filters through it - and this is a hard floor, not a ramp, so a tier can
// never posterise to near-black.
uniform float cast_floor : hint_range(0.0, 1.0) = 0.74;
// --- R2.9 surface texture ------------------------------------------------------------------------
// Off by default: the grass-tuft MultiMesh (thousands of 16 cm blades) is exempt per R2.9's "small
// pieces do not need this", and pays nothing. Canopies, bushes, mushroom caps and trunks opt in.
// The pattern is evaluated in MODEL space so it is locked to the prop instead of swimming through
// world space as the tree sways, and it is faded by sd_lod so it can never alias.
uniform float surface_strength : hint_range(0.0, 4.0) = 0.0;
// sd_foliage runs at 30 and 7 cycles per unit, which is a 3 cm feature on a 2.5 m canopy: far too
// fine for a tree judged at 6-12 m. `surface_scale` moves the whole pattern into a band that
// survives that distance - at 0.35 it is 10.5 and 2.5 cycles/m, i.e. leaf clumps rather than grain.
// This also matters for the bump: the slope of a field is amplitude x frequency, so the unscaled
// pattern produced a normal that was pure per-pixel noise and rendered as dither on the crown.
uniform float surface_scale : hint_range(0.05, 2.0) = 0.35;
uniform float surface_near : hint_range(0.5, 40.0) = 4.0;
uniform float surface_far : hint_range(1.0, 80.0) = 16.0;
uniform float surface_bump : hint_range(0.0, 1.0) = 0.10;
// The canopy ramp saturates like every other toon ramp here, so the detail's own slope is carried
// into the lit region explicitly. Clamped, so it never adds energy (R2.6 stands).
uniform float surface_light : hint_range(0.0, 3.0) = 0.8;
// Wood grain on trunks and stems (COLOR.a marks them). `wood_squash` compresses the model position
// along the trunk axis BEFORE sd_wood sees it. This matters: sd_wood's ring term is a function of
// the distance from the grain axis, which on a lathed trunk is just the radius and therefore
// CONSTANT over the whole surface — the directional read has to come from its fbm phase term, and
// squashing along the axis stretches that fbm into grain lines that run up the trunk.
uniform float wood_strength : hint_range(0.0, 4.0) = 1.6;
// Coarse ON PURPOSE. sd_wood's knot term thresholds the top of a 2-octave fbm, so at a fine scale
// its second octave picks out 2-3 px dots and the trunk renders as speckle rather than as bark. At
// 1.8 the knots are 10 cm and the grain resolves into 2-3 broad vertical bands, which is also what
// the ACNH reference trunks actually have.
uniform float wood_scale : hint_range(0.2, 12.0) = 1.8;
uniform float wood_squash : hint_range(0.02, 1.0) = 0.30;
// sd_wood's `knot_amount`. The library's own default of 0.55 reads as heavy marbling; bark wants
// the rings to lead with knots as an accent. `wood_scale` is applied to the position rather than
// to sd_wood's `scale` argument on purpose: `scale` deliberately leaves the ring PHASE fbm at
// 3.4 c/unit, and on a lathed trunk that phase term is the only thing that varies at all (the
// ring term itself is a function of the distance from the axis, which on a lathe IS the radius
// and is therefore constant over the whole surface).
uniform float wood_knot : hint_range(0.0, 1.0) = 0.35;
// R2.9: "Leaves want a hint of subsurface warmth where the sun passes through." Strongest when the
// camera is looking toward the sun through a leaf, and only on the shaded side of the ramp. Added to
// SPECULAR_LIGHT with the albedo already folded in, so the engine's own albedo multiply (see
// OPEN_ISSUES item 19) does not land on it twice.
uniform float sss_strength : hint_range(0.0, 1.0) = 0.0;
uniform vec4 sss_color : source_color = vec4(1.0, 0.86, 0.52, 1.0);

varying vec3 v_col;
/// Model-space position and normal, after sway, for the R2.9 detail.
varying vec3 v_objpos;
varying vec3 v_objnrm;
/// World position and normal, for the tangential bump.
varying vec3 v_wpos;
varying vec3 v_wnrm;
/// 1.0 on a wood vertex (trunk/stem), 0.0 on a leaf. Baked into COLOR.a by PlanetPropMeshes.
varying float v_wood;
/// View-space normal BEFORE the R2.9 detail bump.
varying vec3 v_flat_nrm;

void vertex() {
	vec3 wp = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float k = clamp(VERTEX.y / max(sway_height, 0.001), 0.0, 1.0);
	k = k * k;
	float ph = dot(wp, vec3(0.7, 0.45, 0.55));
	float sx = sin(TIME * sway_speed + ph) + 0.4 * sin(TIME * sway_speed * 2.3 + ph * 1.7);
	float sz = cos(TIME * sway_speed * 0.8 + ph * 1.3);
	VERTEX.x += sx * sway_amount * k;
	VERTEX.z += sz * sway_amount * 0.6 * k;
	vec3 c = COLOR.rgb;
	if (use_instance_tint) {
		c = mix(c, INSTANCE_CUSTOM.rgb, step(0.5, COLOR.a));
	}
	v_col = c;
	// The wood marker is a narrow window in COLOR.a, so 0.0 (untinted petals/stems) and 1.0 (leaves,
	// blades, tinted petals) both stay leaf and nothing already in the game changes meaning.
	v_wood = step(0.20, COLOR.a) * step(COLOR.a, 0.60);
	v_objpos = VERTEX;
	v_objnrm = NORMAL;
	v_wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_wnrm = normalize(mat3(MODEL_MATRIX) * NORMAL);
}

void fragment() {
	// pc_albedo_floor keeps every channel above PC_ALBEDO_FLOOR so pc_light_term's divide stays sane.
	vec3 base = albedo.rgb * v_col;
	float rough = 0.97;
	v_flat_nrm = NORMAL;
	// --- R2.9 SURFACE TEXTURE ----------------------------------------------------------------------
	if (surface_strength > 0.001) {
		float lod = sd_lod(VERTEX, surface_near, surface_far);
		// sd_fbm is not normalised, so an sd_* tint has a mean below 1.0 and would darken the canopy
		// as well as texture it. `mean` divides that out. See planet_common.gdshaderinc.
		float mean = 1.0;
		SdSurface s = sd_none();
		if (v_wood > 0.5) {
			// Squash along the trunk axis so sd_wood's fbm phase term becomes grain lines running UP
			// the trunk rather than blobs (see the wood_squash note above). grain_dir is the part's
			// OWN axis in model space (+Y for every lathed trunk and stem the mesh kit builds), never
			// a world axis, so the grain stays put wherever on the planet the tree stands.
			vec3 wp_wood = vec3(v_objpos.x, v_objpos.y * wood_squash, v_objpos.z) * wood_scale;
			s = sd_wood(wp_wood, vec3(0.0, 1.0, 0.0), lod, wood_strength * surface_strength, 1.0, wood_knot);
			mean = pc_sd_mean_wood(wood_strength * surface_strength * lod);
		} else {
			s = sd_foliage(v_objpos, normalize(v_objnrm), lod, surface_strength, surface_scale);
			mean = pc_sd_mean_foliage(surface_strength * lod);
		}
		vec3 tint = s.tint / mean;
		base *= tint;
		rough = clamp(rough + s.rough * 0.5, 0.0, 1.0);
		// Tangential bump from the detail's own slope. The library returns its bump as a model-space
		// VECTOR whose dominant term is along the normal, which cannot tilt a normal at all; the
		// surface gradient of the same field can.
		vec3 sgrad = pc_surface_grad(v_wpos, normalize(v_wnrm), tint.r - 1.0);
		NORMAL = normalize(NORMAL - (VIEW_MATRIX * vec4(sgrad, 0.0)).xyz * surface_bump);
	}
	ALBEDO = pc_albedo_floor(pc_pastel(base, pastel_max, pastel_dark));
	ROUGHNESS = rough;
	METALLIC = 0.0;
	SPECULAR = 0.02;
	AO = ambient_damp;
	AO_LIGHT_AFFECT = 0.0;
	EMISSION = emission_color.rgb * emission_strength * v_col;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float lit = smoothstep(-ramp_softness, ramp_softness, ndl);
	if (LIGHT_IS_DIRECTIONAL) {
		// EXPLICIT, BOUNDED canopy ramp: the shaded side is a fixed fraction of the sunlit side and a
		// cast shadow is one further bounded step, so a tier is always ONE green with a soft gradient
		// across it rather than a posterised patchwork.
		float shade = mix(shade_floor, 1.0, lit) * mix(cast_floor, 1.0, mix(1.0, ATTENUATION, cast_shadow_recv));
		// R2.9: the ramp above saturates, so the detail bump alone would be invisible on the sunlit
		// crown. Clamped hard, so it can never blow the crown out or punch a dark hole in it.
		shade *= clamp(1.0 + (ndl - dot(v_flat_nrm, LIGHT)) * surface_light, 0.82, 1.14);
		vec3 shaded = pc_pastel(ALBEDO * mix(vec3(1.0), shade_tint.rgb, shade_strength), shade_s_max, shade_desat);
		vec3 col = mix(shaded, ALBEDO, lit) * shade;
		vec3 composed = pc_pastel(col * LIGHT_COLOR / PI, light_s_max, 0.0) * (light_gain * mix(1.0, compat_light_boost, astro_compat));
		DIFFUSE_LIGHT += pc_light_term(composed, ALBEDO);
		// R2.9: a hint of subsurface warmth where the sun passes through a leaf. Strongest looking
		// INTO the sun through the shaded side of the canopy, which is when you really see it.
		if (sss_strength > 0.001 && v_wood < 0.5) {
			float thru = pow(clamp(dot(VIEW, -LIGHT), 0.0, 1.0), 2.0) * smoothstep(0.30, -0.35, ndl);
			SPECULAR_LIGHT += ALBEDO * sss_color.rgb * (thru * sss_strength) * LIGHT_COLOR / PI;
		}
	} else {
		vec3 composed = pc_pastel(ALBEDO * lit * ATTENUATION * LIGHT_COLOR / PI, light_s_max, 0.0);
		DIFFUSE_LIGHT += pc_light_term(composed, ALBEDO);
	}
	vec3 hv = normalize(VIEW + LIGHT);
	float ndh = max(dot(NORMAL, hv), 0.0);
	float spec = smoothstep(0.45, 0.6, pow(ndh, 60.0)) * spec_strength * lit;
	SPECULAR_LIGHT += spec * LIGHT_COLOR / PI;
	float rim = 1.0 - max(dot(NORMAL, VIEW), 0.0);
	rim = smoothstep(0.6, 0.9, rim) * rim_strength * lit;
	SPECULAR_LIGHT += rim * vec3(1.0, 0.97, 0.9) * LIGHT_COLOR / PI;
}
