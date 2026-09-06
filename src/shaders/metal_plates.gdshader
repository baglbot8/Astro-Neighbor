// Chrome planet ground: rounded metal plates with pulsing orange seam lights, rivets, a few raised
// plates (fake bevel via normal tilt), brushed grime, and dark oil pools in the low areas.
//
// R2.9 SURFACE TEXTURE: R2.9's metal row asks for "a soft anisotropic sheen that travels as the view
// moves, fine brushed grain, slightly darker micro-scratches near edges. Not a mirror, not a
// hotspot." The deck is the biggest metal surface in the game, so it gets all three, at two scales.
shader_type spatial;
render_mode cull_back, depth_draw_opaque, diffuse_lambert, specular_schlick_ggx;
#include "res://src/shaders/planet_common.gdshaderinc"
#include "res://src/shaders/surface_detail.gdshaderinc"

// sd_metal picks its BRUSH AXIS from the normal it is handed (see OPEN_ISSUES item 20.2). On a
// sphere the world normal turns through every direction, so feeding it the deck's real normal would
// re-pick the axis in patches all over the planet and the grain would visibly change direction. It
// is instead evaluated in the deck's own cube-sphere UV plane with a constant up vector, so the
// brush runs along the deck's u axis everywhere and only steps at the cube-face seams the ground
// already has.
//   FINE   x0.10 -> 21.0 cycles/m across the brush (4.8 cm), scratches at 8.4/m  - near range
//   COARSE x0.03 ->  6.3 cycles/m across the brush (16 cm),  scratches at 2.5/m  - survives far
// ROCK on the worn plateau banks, x0.22 -> 10.1 / 1.4 cycles/m.
const float SD_MFINE_K = 0.10;
const float SD_MFINE_HZ = 21.0;
const float SD_MCOARSE_K = 0.030;
const float SD_MCOARSE_HZ = 6.3;
const float SD_BANK_K = 0.22;
const float SD_BANK_HZ = 10.1;

// COOL BLUE-GREY CHROME (docs/STYLE_GUIDE "Chrome planet plates" #8fa3bf / #6f819c). Bolt's identity
// is steel; the ONLY saturated accent is the warm orange seam light. Panel variety is a few percent
// of value/hue, never a coloured tile — scattered red/green plates read as a bathroom floor.
uniform vec4 plate_a : source_color = vec4(0.561, 0.639, 0.749, 1.0);
uniform vec4 plate_b : source_color = vec4(0.435, 0.506, 0.612, 1.0);
uniform vec4 plate_c : source_color = vec4(0.647, 0.714, 0.808, 1.0);
// The one rare "maintenance panel": a DESATURATED dark slate-teal, ~4% of plates. It is a dark tone,
// not a colour accent — at gameplay distance it reads as a service hatch.
uniform vec4 plate_panel : source_color = vec4(0.310, 0.416, 0.471, 1.0);
uniform float panel_rarity : hint_range(0.0, 0.2) = 0.028;
// The unlit part of a seam is a MID steel groove, not a black slot: at 13% of the surface a dark
// gap grid is what dragged Bolt's luma p05 to 0.17 and made the yard read as a solar farm.
uniform vec4 seam_dark : source_color = vec4(0.400, 0.463, 0.561, 1.0);
uniform vec4 seam_light : source_color = vec4(1.0, 0.541, 0.239, 1.0);
uniform vec4 oil_color : source_color = vec4(0.110, 0.122, 0.169, 1.0);
uniform vec4 oil_ring : source_color = vec4(0.239, 0.271, 0.353, 1.0);
uniform vec4 bank_color : source_color = vec4(0.365, 0.420, 0.514, 1.0);
uniform vec4 grime_color : source_color = vec4(0.294, 0.353, 0.451, 1.0);
uniform float limb_darken : hint_range(0.0, 1.0) = 0.13;
// R2.6: a strongly blue limb/shade tint crushes the red channel of an already cool plate, and the
// tonemapper turns that into a vivid cobalt. Near-neutral cool instead.
uniform vec4 limb_tint : source_color = vec4(0.74, 0.79, 0.88, 1.0);
uniform float seam_glow = 0.9;
uniform float seam_fraction = 0.24;
uniform float planet_radius = 13.0;
uniform float water_radius = 12.7;
// TWO SCALES. Bolt used to be ONE pillowy plate repeated over the whole sphere with an orange grid
// on top — a golf ball, or an air mattress. The deck is now laid out in `section_size` bays, and each
// bay is subdivided 2x2, 3x3 or 4x4, so plate size, tone and rivet pattern change from bay to bay and
// a wide expansion joint runs between them. Structure at two scales is what makes a machined deck
// read as machinery instead of upholstery.
uniform float section_size = 3.4;
uniform float plate_size = 0.85;
uniform float gap = 0.045;
// Less pillow: a big corner radius plus a big fake bevel is exactly what made every plate read as an
// inflated cushion. Machined plate, crisp edge.
uniform float corner = 0.07;
uniform float bevel = 0.11;
uniform float joint = 0.10;
uniform float ramp_softness : hint_range(0.01, 1.0) = 0.3;
uniform float shade_strength : hint_range(0.0, 1.0) = 0.56;
uniform float shade_floor : hint_range(0.0, 1.0) = 0.74;
// Steel goes COOL BLUE in shade — that is where Bolt's darkness and its remaining chroma come from,
// instead of muddying the plates to beige. R2.6 pulled the tint back from (0.40,0.56,0.95): it was
// driving the shaded plates to a measured S 0.77 cobalt. Still unmistakably cool, no longer vivid.
uniform vec4 shade_tint : source_color = vec4(0.62, 0.71, 0.94, 1.0);
// R2.6 pastel guard (pc_pastel in planet_common.gdshaderinc). Bolt is steel: chroma belongs to the
// seam lights, not to the deck.
uniform float pastel_max : hint_range(0.05, 1.0) = 0.70;
uniform float pastel_dark : hint_range(0.0, 1.0) = 0.22;
// Baked ground occlusion (Planet._bake_color -> COLOR.a): contact pools under every mast, gantry,
// pipe and crate, plus the feet of the landforms. Multiplies the LIT deck, not the plate albedo.
uniform float ao_ambient : hint_range(0.0, 1.0) = 1.0;
uniform float ao_direct : hint_range(0.0, 1.0) = 0.85;

// R2.6 / ACNH: cast shadows are TINTED, not holes. See pc_shadow_fill in planet_common.gdshaderinc.
// `shadow_fill_color` is the cool skylight that survives inside a cast shadow; `shadow_fill` is how
// much of it. Set per planet from Planet._make_ground_material().
uniform vec4 shadow_fill_color : source_color = vec4(0.72, 0.80, 0.95, 1.0);
uniform float shadow_fill : hint_range(0.0, 0.6) = 0.16;
// R2.9 surface texture. `detail_metal` scales the brushed grain and micro-scratches, `detail_sheen`
// the travelling anisotropic sheen (kept low on purpose — at full strength a sheen across a whole
// plate is exactly the "wet plastic" R2.6 forbids, which is why the shared library dropped its own
// aniso from 0.55 to 0.20), and `detail_light` carries the grain's slope into the saturated part of
// the toon ramp, where a bumped normal would otherwise do nothing at all.
uniform float detail_metal : hint_range(0.0, 4.0) = 1.9;
uniform float detail_rock : hint_range(0.0, 4.0) = 1.5;
uniform float detail_bump : hint_range(0.0, 1.0) = 0.16;
uniform float detail_light : hint_range(0.0, 3.0) = 1.3;
// MEASURED: at 0.5 the sheen's grazing term swept a pale wash across the curved deck and cost Bolt
// 16% of its saturation mean (0.408 -> 0.342) - the steel read as pale plastic, which is precisely
// what R2.6 forbids. At 0.22 the sheen still travels as the camera moves and the brushed grain,
// which costs no brightness at all, carries the metal read.
uniform float detail_sheen : hint_range(0.0, 1.0) = 0.22;


varying vec3 v_world_pos;
varying vec3 v_world_nrm;
varying vec4 v_color;
/// View-space normal BEFORE the R2.9 detail bump, so light() can measure what the bump changed.
varying vec3 v_flat_nrm;
/// R2.9 anisotropic sheen strength from sd_metal, consumed by sd_sheen() in light().
varying float v_sheen;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_nrm = normalize(mat3(MODEL_MATRIX) * NORMAL);
	v_color = COLOR;
}

// Deck bay containing `uv`, and how finely that bay is plated.
void deck_section(vec2 uv, out vec2 sec, out float div, out vec2 luv) {
	sec = floor(uv / section_size);
	float sh = pc_hash21(sec + vec2(3.3, 7.7));
	div = sh < 0.30 ? 2.0 : (sh < 0.68 ? 3.0 : 4.0);
	luv = uv - sec * section_size;
}

float plate_sdf(vec2 uv, out vec2 cell, out vec2 local, out float psize) {
	vec2 sec; float div; vec2 luv;
	deck_section(uv, sec, div, luv);
	psize = section_size / div;
	vec2 g = luv / psize;
	cell = sec * 16.0 + floor(g);
	local = (fract(g) - 0.5) * psize;
	float gp = gap * 0.5 * (0.7 + 0.5 * psize / plate_size);
	return pc_rbox_sdf(local, vec2(psize * 0.5 - gp), min(corner, psize * 0.13));
}

void fragment() {
	vec3 wp = v_world_pos;
	float dist = length(wp);
	vec3 dir = wp / max(dist, 0.0001);
	float h = dist - planet_radius;
	float wl = water_radius - planet_radius;

	vec2 uv = pc_cube_uv(dir, planet_radius);
	// Sub-pixel detail fades to its own average (pc_detail_lod): a plate grid that undersamples is
	// exactly what made Bolt read as a golf ball, beating concentric moire rings into the deck.
	float lod = pc_detail_lod(uv / plate_size);
	float fine = 1.0 - lod;
	vec2 cell; vec2 local; float psize;
	float sd = plate_sdf(uv, cell, local, psize);
	vec2 sec; float div; vec2 luv;
	deck_section(uv, sec, div, luv);
	float sech = pc_hash21(sec + vec2(19.4, 1.2));
	// Expansion joint between bays: a wide dark groove, the deck's large-scale structure.
	float bay_d = min(min(luv.x, section_size - luv.x), min(luv.y, section_size - luv.y));
	float bay_joint = 1.0 - smoothstep(joint * 0.45, joint, bay_d);
	float ch = pc_hash21(cell);
	float ch2 = pc_hash21(cell + vec2(5.1, 8.7));
	float raised = step(0.72, ch2);
	// Panel variety = a few percent of value, plus a barely-there warm/cool hue drift. Nothing here
	// changes the hue family: every plate is still steel.
	vec3 pcol = mix(plate_a.rgb, plate_b.rgb, step(0.5, ch) * 0.55 + ch * 0.28);
	pcol = mix(pcol, plate_c.rgb, raised * 0.42);
	float warm = pc_hash21(cell + vec2(11.7, 3.3)) - 0.5;
	pcol *= vec3(1.0 + warm * 0.045, 1.0, 1.0 - warm * 0.045);
	// Bay-level tone: whole sections read a little lighter or darker than their neighbours.
	pcol *= 0.90 + 0.19 * sech;
	// One rare desaturated slate maintenance hatch, and ONLY on a finely plated bay: on a 2x2 bay the
	// same hatch turned a 1.7 m slab of deck dark teal and read as a hole in the floor.
	pcol = mix(pcol, plate_panel.rgb, step(1.0 - panel_rarity, pc_hash21(cell + vec2(2.9, 17.1))) * step(3.5, div));
	// Inner panel line: every plate carries a recessed rectangle a hand's width inside its edge, so
	// the big 1.7 m plates in a coarse bay still have something at small scale instead of reading as
	// a blank slab. This is the second scale of detail, under the plate and the bay.
	float inner = pc_rbox_sdf(local, vec2(psize * 0.5 - 0.20), 0.05);
	float inner_line = (1.0 - smoothstep(0.0, 0.016, abs(inner))) * fine;
	pcol *= 1.0 - 0.10 * inner_line;
	pcol = mix(pcol, pcol * 1.05, (1.0 - smoothstep(-0.05, 0.0, inner)) * 0.5 * fine);
	// brushed lines + grime
	float brush = (pc_noise3(vec3(uv.x * 40.0, uv.y * 3.0, 1.0)) * 0.05 - 0.025) * fine;
	float grime = pc_fbm3(wp * 0.7) ;
	pcol = pcol * (1.0 + brush);
	// Broad grime pooling gives large-scale value variation (dark tones) in the SAME cool hue family.
	pcol = mix(pcol, grime_color.rgb, smoothstep(0.46, 0.84, pc_fbm3(wp * 0.10 + vec3(6.1))) * 0.09);
	pcol *= 0.95 + 0.11 * mix(grime, 0.5, lod * 0.7);
	// rivets at plate corners
	vec2 rp = abs(local) - vec2(psize * 0.5 - gap * 0.5 - 0.15);
	float rivet = (1.0 - smoothstep(0.03, 0.05, length(rp))) * step(0.45, ch) * fine;
	pcol = mix(pcol, pcol * 0.75, rivet * 0.9);

	float aa = fwidth(sd) + 0.003;
	// 0.90 is the fraction of a cell that is plate rather than seam — the pattern's own mean.
	float in_plate = mix(1.0 - smoothstep(-aa, aa, sd), 0.90, lod);
	// seam center line glow (sd == gap/2 exactly between two plates)
	float seam_d = abs(sd - gap * 0.5);
	float seam = (1.0 - smoothstep(0.008, 0.022, seam_d)) * mix(1.0, 0.30, lod);
	// only some seams carry light (circuit-trace look); pulses travel along them
	vec2 ap = abs(local);
	bool vertical = ap.x > ap.y;
	vec2 seam_key = vertical ? vec2(cell.x + (local.x > 0.0 ? 0.5 : -0.5), cell.y) : vec2(cell.x, cell.y + (local.y > 0.0 ? 0.5 : -0.5));
	float lit_seam = step(pc_hash21(seam_key * 1.37 + vec2(2.0, 5.0)), seam_fraction);
	seam *= lit_seam;
	float along = vertical ? uv.y : uv.x;
	float pulse = 0.5 + 0.5 * sin(TIME * 2.2 - along * 2.5 + pc_hash21(seam_key) * 6.28);
	pulse = 0.3 + 0.7 * pulse * pulse;
	// R2.6: the pastel guard belongs to the DECK only. The warm orange seam light is the one small
	// saturated accent Bolt is allowed, so it is mixed in after the guard and keeps its full chroma.
	vec3 col = pc_pastel(mix(seam_dark.rgb, pcol, in_plate), pastel_max, pastel_dark);
	col = mix(col, seam_dark.rgb * 0.94, bay_joint * fine);
	col = mix(col, seam_light.rgb, seam * 0.85);
	vec3 emission = seam_light.rgb * seam * pulse * seam_glow;

	// bevel: tilt normal outward near the plate edge (stronger on raised plates)
	float e = 0.01;
	vec2 c2; vec2 l2; float p2;
	float gx = plate_sdf(uv + vec2(e, 0.0), c2, l2, p2) - sd;
	float gy = plate_sdf(uv + vec2(0.0, e), c2, l2, p2) - sd;
	vec2 grad = vec2(gx, gy) / e;
	float bev = (1.0 - smoothstep(-0.09, -0.015, sd)) * smoothstep(-0.15, -0.09, sd) * bevel * (0.6 + 0.8 * raised) * fine;
	// rivet dome normal
	vec2 rgrad = normalize(rp + vec2(0.0001)) * rivet * 0.6;
	vec3 a3 = abs(dir);
	vec3 tu; vec3 tv;
	if (a3.x >= a3.y && a3.x >= a3.z) { tu = vec3(0.0, 0.0, sign(dir.x)); tv = vec3(0.0, 1.0, 0.0); }
	else if (a3.y >= a3.z) { tu = vec3(1.0, 0.0, 0.0); tv = vec3(0.0, 0.0, sign(dir.y)); }
	else { tu = vec3(-sign(dir.z), 0.0, 0.0); tv = vec3(0.0, 1.0, 0.0); }
	vec3 wn = normalize(v_world_nrm + (tu * (grad.x * bev + rgrad.x) + tv * (grad.y * bev + rgrad.y)));

	// oil pools: dark wet look below the oil line, ring just above it
	float oil_t = 1.0 - smoothstep(wl - 0.02, wl + 0.10, h);
	float ring_t = (1.0 - smoothstep(wl + 0.10, wl + 0.30, h)) * (1.0 - oil_t);
	col = mix(col, oil_color.rgb, oil_t * 0.80);
	col = mix(col, oil_ring.rgb, ring_t * 0.8);
	emission *= (1.0 - oil_t);
	wn = normalize(mix(wn, v_world_nrm, oil_t));
	// Worn edge on plateau banks / crater walls (baked in COLOR.g).
	col = mix(col, bank_color.rgb * (0.88 + 0.24 * mix(pc_noise3(wp * 2.2), 0.5, lod)), smoothstep(0.34, 0.72, v_color.g) * (1.0 - oil_t));
	// Limb shading driven by the GEOMETRIC radial direction, not the bevelled normal — see the note
	// in grass_planet.gdshader. Driving it from `wn` also gave every plate its own limb step.
	float facing = clamp(dot(dir, normalize(CAMERA_POSITION_WORLD - wp)), 0.0, 1.0);
	float limb = 1.0 - smoothstep(0.10, 0.86, facing);
	limb = clamp(limb + (pc_hash21(FRAGCOORD.xy) - 0.5) * 0.016, 0.0, 1.0);
	col = mix(col, col * limb_tint.rgb, limb * limb_darken);
	emission *= (1.0 - limb * 0.4);

	NORMAL = normalize((VIEW_MATRIX * vec4(wn, 0.0)).xyz);

	// --- R2.9 SURFACE TEXTURE ----------------------------------------------------------------------
	// Brushed grain at two scales in the deck's own UV plane (see the SD_* note at the top), plus a
	// rougher stone microsurface on the worn banks. Both bands are gated by pc_band_lod so neither is
	// ever sampled near Nyquist — a plate grid that undersampled is what made Bolt read as a golf
	// ball once already.
	vec3 deck_p = vec3(uv.x, 0.0, uv.y);
	float deck_dry = 1.0 - oil_t;
	float lod_mf = pc_band_lod(uv, SD_MFINE_HZ) * deck_dry;
	float lod_mc = pc_band_lod(uv, SD_MCOARSE_HZ) * deck_dry;
	SdSurface sd_mf = sd_metal(deck_p, vec3(0.0, 1.0, 0.0), lod_mf, detail_metal, SD_MFINE_K);
	SdSurface sd_mc = sd_metal(deck_p, vec3(0.0, 1.0, 0.0), lod_mc, detail_metal * 0.8, SD_MCOARSE_K);
	float bank_m = smoothstep(0.34, 0.72, v_color.g) * deck_dry;
	float lod_bk = pc_band_lod(uv, SD_BANK_HZ) * bank_m;
	SdSurface sd_bk = sd_none();
	if (bank_m > 0.004) {
		sd_bk = sd_rock(wp, dir, lod_bk, detail_rock, SD_BANK_K);
	}
	// Divided by each band's own mean — sd_fbm is not normalised (see planet_common.gdshaderinc), so
	// an undivided band darkens the deck instead of texturing it.
	vec3 tint_mf = sd_mf.tint / pc_sd_mean_metal(detail_metal * lod_mf);
	vec3 tint_mc = sd_mc.tint / pc_sd_mean_metal(detail_metal * 0.8 * lod_mc);
	vec3 tint_bk = sd_bk.tint / pc_sd_mean_rock(detail_rock * lod_bk);
	col *= tint_mf * tint_mc * tint_bk;
	// The sheen comes from the COARSE band: it survives to the horizon and is faded in by the shared
	// library's own smoothstep, so a plate spanning the fade distance cannot draw a ring.
	v_sheen = sd_mc.aniso * detail_sheen;
	float detail_h = (tint_mc.r - 1.0) + (tint_mf.r - 1.0) * 0.3 + (tint_bk.r - 1.0) * 0.8;
	v_flat_nrm = NORMAL;
	vec3 sgrad = pc_surface_grad(wp, dir, detail_h);
	NORMAL = normalize(NORMAL - (VIEW_MATRIX * vec4(sgrad, 0.0)).xyz * detail_bump);

	ALBEDO = col;
	AO = mix(1.0, v_color.a, ao_ambient);
	AO_LIGHT_AFFECT = 0.0;
	// Painted steel, not glass: a toon planet needs a matte plate with one crisp highlight.
	// The oil pools keep their gloss (real wet surface); the painted deck goes matte.
	// R2.9: the brushed grain and the micro-scratches vary the roughness, which the toon lobe reads
	// (OPEN_ISSUES item 20.3) — that is where "brushed steel" comes from rather than from specular.
	ROUGHNESS = clamp(mix(0.80, 0.18, oil_t) + (sd_mf.rough + sd_mc.rough + sd_bk.rough) * 0.5, 0.0, 1.0);
	METALLIC = mix(0.06, 0.06, oil_t);
	SPECULAR = mix(0.10, 0.45, oil_t);
	EMISSION = emission;
}

void light() {
	float lit;
	float ndl = dot(NORMAL, LIGHT);
	vec3 diffuse = pc_toon_diffuse(ALBEDO, ndl, ATTENUATION, ramp_softness, shade_strength, shade_tint.rgb, shade_floor, LIGHT_IS_DIRECTIONAL, lit);
	// R2.9: carry the grain's slope into the saturated part of the toon ramp. Clamped, so it adds no
	// energy and cannot make a hotspot (R2.6 stands).
	diffuse *= clamp(1.0 + (ndl - dot(v_flat_nrm, LIGHT)) * detail_light, 0.82, 1.20);
	DIFFUSE_LIGHT += pc_pastel(diffuse * LIGHT_COLOR, PC_LIGHT_S_MAX, 0.0) * mix(1.0, v_color.a, ao_direct) / PI;
	DIFFUSE_LIGHT += pc_shadow_fill(ndl, ATTENUATION, ramp_softness, shadow_fill_color.rgb, shadow_fill) * LIGHT_COLOR / PI;
	vec3 hv = normalize(VIEW + LIGHT);
	float ndh = max(dot(NORMAL, hv), 0.0);
	float spec = smoothstep(0.4, 0.6, pow(ndh, 90.0)) * 0.10 * lit;
	SPECULAR_LIGHT += spec * LIGHT_COLOR / PI;
	float rim = 1.0 - max(dot(NORMAL, VIEW), 0.0);
	rim = smoothstep(0.65, 0.95, rim) * 0.06 * lit;
	SPECULAR_LIGHT += rim * LIGHT_COLOR / PI;
	// R2.9 metal sheen: broad, low-amplitude, and it TRAVELS as the view moves, which is what sells
	// steel. Deliberately not a mirror and not a hotspot — see sd_sheen's own note.
	if (v_sheen > 0.001) {
		SPECULAR_LIGHT += sd_sheen(NORMAL, VIEW, LIGHT, v_sheen) * lit * LIGHT_COLOR / PI;
	}
}
