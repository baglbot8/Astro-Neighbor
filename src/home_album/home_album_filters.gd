class_name HomeAlbumFilters
extends RefCounted
## PHOTO FILTERS FOR THE HOME ALBUM (docs/JUNGLE_PLANET_SPEC.md 6.1, builder HOMECAM 2026-09-30).
##
## "A look you can apply to home album photos, cosmetic only. Flag `flags.filters_owned` (list)."
## Moss sells them (another builder's shop); this file only knows the ids and how each one looks.
##
## ORIGINAL KEPT, BY CONSTRUCTION: a filter never touches the stored pixels. HomeAlbumStore keeps the
## photo's `thumb_b64` exactly as captured and a separate `filter` id beside it; the look is a canvas
## shader applied where the photo is DRAWN (the album grid and the enlarged view in sky_journal.gd).
## Changing or removing the filter is therefore free and lossless, and a GPU shader costs nothing on
## the CPU - a per-pixel GDScript pass over 25 thumbnails would stall a phone for about a second.
##
## Everything is procedural (a shader string here, no imported asset).

## Order the album cycles through, after "no filter".
const IDS: Array[String] = ["warm", "old_film", "dreamy", "night_glow"]
const NAMES := {
	"": "None",
	"warm": "Warm",
	"old_film": "Old Film",
	"dreamy": "Dreamy",
	"night_glow": "Night Glow",
}
const F_OWNED := "filters_owned"

const _SHADER_CODE := """
shader_type canvas_item;
// 0 none, 1 warm, 2 old film, 3 dreamy, 4 night glow (HomeAlbumFilters.IDS order + 1)
uniform int mode = 0;

float luma(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }
float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }

vec3 blur9(sampler2D tex, vec2 uv, vec2 px) {
	vec3 s = vec3(0.0);
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			s += texture(tex, uv + vec2(float(x), float(y)) * px).rgb;
		}
	}
	return s / 9.0;
}

void fragment() {
	vec4 t = texture(TEXTURE, UV);
	vec3 c = t.rgb;
	vec2 d = UV - vec2(0.5);
	float r = length(d * vec2(1.0, 0.8));
	if (mode == 1) {
		// WARM: late-afternoon white balance, a touch richer.
		c = c * vec3(1.10, 1.02, 0.84) + vec3(0.035, 0.018, 0.0);
		c = mix(vec3(luma(c)), c, 1.12);
	} else if (mode == 2) {
		// OLD FILM: sepia, faded blacks and creamy whites, fixed grain, dark corners.
		float l = luma(c);
		vec3 sep = vec3(l) * vec3(1.08, 0.95, 0.76);
		c = mix(c, sep, 0.88);
		c = mix(vec3(0.11, 0.09, 0.07), vec3(0.94, 0.89, 0.77), clamp(c, 0.0, 1.0));
		vec2 cell = floor(UV / TEXTURE_PIXEL_SIZE);
		c += (hash(cell) - 0.5) * 0.07;
		c *= 1.0 - smoothstep(0.32, 0.78, r) * 0.5;
	} else if (mode == 3) {
		// DREAMY: soft focus, lifted pastel tones, a pale glow at the edges.
		vec3 b = blur9(TEXTURE, UV, TEXTURE_PIXEL_SIZE * 2.5);
		c = mix(c, max(c, b), 0.6);
		c = c * 0.82 + vec3(0.16);
		c *= vec3(1.03, 0.96, 1.05);
		c = mix(vec3(luma(c)), c, 0.85);
		c = mix(c, vec3(0.97, 0.92, 0.97), smoothstep(0.30, 0.80, r) * 0.55);
	} else if (mode == 4) {
		// NIGHT GLOW: a cool, darker night with the bright parts blooming softly.
		// Two blur radii averaged: one wide 9-tap alone leaves visible ghost copies of edges.
		vec3 b = (blur9(TEXTURE, UV, TEXTURE_PIXEL_SIZE * 1.5) + blur9(TEXTURE, UV, TEXTURE_PIXEL_SIZE * 3.5)
			+ blur9(TEXTURE, UV, TEXTURE_PIXEL_SIZE * 6.0)) / 3.0;
		vec3 glow = max(b - vec3(0.42), vec3(0.0)) * 1.4;
		c = c * 0.62 * vec3(0.80, 0.88, 1.14);
		c += glow * vec3(1.0, 0.86, 1.05);
		c *= 1.0 - smoothstep(0.35, 0.85, r) * 0.45;
	}
	COLOR = vec4(clamp(c, 0.0, 1.0), t.a);
}
"""

static var _shader: Shader


static func is_known(filter_id: String) -> bool:
	return filter_id == "" or IDS.has(filter_id)


static func display_name(filter_id: String) -> String:
	return str(NAMES.get(filter_id, "None"))


## The filters the player owns, in IDS order (unknown ids in the flag are ignored).
static func owned() -> Array[String]:
	var raw: Variant = GameState.flags.get(F_OWNED, [])
	var out: Array[String] = []
	if raw is Array:
		for id in IDS:
			if (raw as Array).has(id):
				out.append(id)
	return out


## The choices the album cycles through for one photo: "" (none) then every owned filter. A photo that
## already carries a filter the player no longer owns keeps it in the list, so a tap never silently
## throws it away.
static func choices_for(current: String) -> Array[String]:
	var out: Array[String] = [""]
	out.append_array(owned())
	if current != "" and IDS.has(current) and not out.has(current):
		out.append(current)
	return out


static func next_after(current: String) -> String:
	var ch := choices_for(current)
	var i := ch.find(current)
	return ch[(i + 1) % ch.size()]


## A material that draws a photo in `filter_id`'s look, or null for no filter.
static func material_for(filter_id: String) -> ShaderMaterial:
	var i := IDS.find(filter_id)
	if i < 0:
		return null
	if _shader == null:
		_shader = Shader.new()
		_shader.code = _SHADER_CODE
	var m := ShaderMaterial.new()
	m.shader = _shader
	m.set_shader_parameter("mode", i + 1)
	return m


## Sets `filter_id`'s look on every TextureRect under `ctrl` (the album cell or the enlarged view).
static func apply_to(ctrl: Node, filter_id: String) -> void:
	if ctrl == null:
		return
	var mat := material_for(filter_id)
	for n in ctrl.find_children("*", "TextureRect", true, false):
		(n as TextureRect).material = mat
	if ctrl is TextureRect:
		(ctrl as TextureRect).material = mat
