// Vertex-coloured emissive for hub buildings: lit windows, glowing signs, string-light bulbs and
// the dance floor. One material for every glowing surface of a building, so a whole shopfront is a
// single extra draw call and the colours come from the baked vertex colours.
//
// Emission follows the `astro_night` global (docs/ARCHITECTURE.md 9.1): a faint tint by day so the
// glass still reads as glass at noon, full strength at night. `emission_cap` scales a hot emissive
// back so its brightest channel stays under ~1.9 and it keeps its hue instead of clipping to white.
// `force_on` lets the event space light its dance floor in broad daylight while the party is on.
shader_type spatial;
render_mode cull_back, depth_draw_opaque, diffuse_lambert, specular_schlick_ggx;

global uniform float astro_night;

// R2.9: most surfaces on this shader are small (a window pane, a sign halo, a bulb) and are
// exempt. The dance floor is not - it is 5.6 x 3.4 m and the player stands on it - so the shared
// surface library is available here too, off by default and switched on per instance.
#include "res://src/shaders/surface_detail.gdshaderinc"

instance uniform float surface_amount = 0.0;   // 0 = off. Laid-tile microsurface via sd_rock.
instance uniform float surface_macro = 0.0;    // large-scale tonal drift, cycles/m x amount

// Fraction of the emission left in broad daylight (astro_night = 0).
uniform float day_scale : hint_range(0.0, 1.0) = 0.14;
// Brightest channel an emissive may reach before it is scaled back, hue intact.
uniform float emission_cap : hint_range(0.2, 8.0) = 1.9;
uniform float albedo_scale : hint_range(0.0, 1.0) = 0.82;
// Colour an unlit window shows in daylight. Windows must be DARK by day (AC Reference 4) and warm
// at night, so they blend toward this while the sun is up and back to their own colour after dusk.
uniform vec4 day_color : source_color = vec4(0.20, 0.23, 0.34, 1.0);
// Toon ramp, matched to toon_soft.gdshader so glowing surfaces shade like every other surface.
uniform float ramp_softness : hint_range(0.01, 1.0) = 0.32;
uniform float shade_strength : hint_range(0.0, 1.0) = 0.40;
uniform vec4 shade_tint : source_color = vec4(0.62, 0.55, 0.85, 1.0);
uniform float shade_floor : hint_range(0.0, 1.0) = 0.62;
uniform float shadow_floor : hint_range(0.0, 1.0) = 0.10;

instance uniform float glow_strength = 2.2;
// 0 = steady. > 0 breathes at this speed.
instance uniform float pulse_speed = 0.0;
instance uniform float pulse_depth : hint_range(0.0, 1.0) = 0.3;
instance uniform float phase = 0.0;
// 1 = ignore the clock and glow at full strength (party mode, indoor display cases).
instance uniform float force_on : hint_range(0.0, 1.0) = 0.0;
// 1 = this surface is a window pane: dark slate in daylight, its own warm colour after dusk.
instance uniform float day_dark : hint_range(0.0, 1.0) = 0.0;

varying vec3 v_col;
varying vec3 v_objpos;
varying vec3 v_objnorm;

void vertex() {
	v_col = COLOR.rgb;
	v_objpos = VERTEX;
	v_objnorm = NORMAL;
}

void fragment() {
	float lit = max(astro_night, force_on);
	ALBEDO = mix(v_col, day_color.rgb, day_dark * (1.0 - lit)) * albedo_scale;
	ROUGHNESS = 0.72;
	if (surface_amount > 0.001) {
		// Laid stone tile: sd_rock at `scale` 0.55 (render/paving frequencies, not cliff), faded
		// out by 18 m, plus a low-frequency drift that survives the whole plaza.
		float lod = sd_lod(VERTEX, 5.0, 18.0);
		SdSurface sd = sd_rock(v_objpos * 0.55, normalize(v_objnorm), lod, surface_amount, 1.0);
		ALBEDO *= sd.tint;
		ROUGHNESS = clamp(ROUGHNESS + sd.rough, 0.0, 1.0);
		NORMAL = normalize(NORMAL + sd.bump);
	}
	if (surface_macro > 0.001) {
		float mlod = sd_lod(VERTEX, 20.0, 48.0);
		float m = sd_fbm(v_objpos * 2.0, 2) * 1.3333 - 0.5;
		ALBEDO *= vec3(1.0 + m * surface_macro * mlod);
	}
	METALLIC = 0.0;
	float night = max(mix(day_scale, 1.0, astro_night), force_on);
	float pulse = 1.0;
	if (pulse_speed > 0.001) {
		pulse = 1.0 - pulse_depth + pulse_depth * (0.5 + 0.5 * sin(TIME * pulse_speed + phase));
	}
	vec3 em = v_col * glow_strength * night * pulse;
	float peak = max(em.r, max(em.g, em.b));
	EMISSION = (peak > emission_cap) ? em * (emission_cap / peak) : em;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float lit = smoothstep(-ramp_softness, ramp_softness, ndl) * ATTENUATION;
	vec3 shadow_col = ALBEDO * mix(vec3(1.0), shade_tint.rgb, shade_strength);
	float floor_level = mix(shadow_floor, shade_floor, ATTENUATION);
	DIFFUSE_LIGHT += mix(shadow_col * floor_level, ALBEDO, lit) * LIGHT_COLOR / PI;
}
