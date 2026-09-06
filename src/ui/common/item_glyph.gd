class_name ItemGlyph
extends Control
## Procedural item icon: a rounded swatch filled with the item's icon_color plus a cute glyph.
##
## The glyph is chosen from the item **id** first (ID_GLYPHS keyword table: "deco_moon_lamp" -> lamp,
## "gear_bit" -> cog, "stardust_shard" -> spark, "deco_rocket_planter" -> rocket-nose planter) and only
## falls back to the item **category** when no keyword matches. That way items that share a category
## (Gear Bit / Crystal Chunk / Stardust Shard are all "material") still read differently at card size.
## Clothing categories (suit / hat / backpack) always win over id keywords, so "hat_antenna" is a cap
## and not a satellite dish.
##
## Everything is drawn in a 100x100 unit space centered on the control, so it scales to any size.

## Item-id keyword -> glyph name, checked in order (first substring match wins).
## Order matters: "crystal_lamp" must hit `lamp` before `crystal`, "gear_fountain" `fountain` before
## `cog`, "holo_sign" `sign` before `screen`, "robot_dog" `dog` before `robot`.
const ID_GLYPHS: Array = [
	["mailbox", "mailbox"],
	["rocket_planter", "rocket_planter"], ["rocket", "rocket_planter"],
	["fountain", "fountain"],
	["dog", "dog"], ["robot", "robot"], ["statue", "robot"],
	["orb", "orb"],
	["lamp", "lamp"], ["light", "lamp"],
	["crystal", "gem"], ["gem", "gem"],
	["shard", "spark"], ["stardust", "spark"], ["sparkle", "spark"], ["wish", "spark"],
	["flower", "flower"], ["bloom", "flower"], ["mushroom", "mushroom"],
	["bench", "bench"], ["chair", "chair"], ["seat", "chair"],
	["flag", "flag"],
	["telescope", "telescope"],
	["dish", "dish"], ["satellite", "dish"], ["antenna", "dish"],
	["ufo", "ufo"],
	["tent", "tent"], ["dome", "tent"],
	["campfire", "fire"], ["fire", "fire"], ["flame", "fire"],
	["table", "table"], ["picnic", "table"],
	["egg", "egg"], ["swing", "swing"],
	["tower", "tower"], ["beacon", "tower"],
	["projector", "projector"], ["globe", "globe"], ["console", "console"],
	["vending", "vending"],
	["rack", "rack"], ["crate", "crate"], ["rug", "rug"],
	["rock", "rock"], ["meteor", "rock"], ["asteroid", "rock"],
	["sign", "sign"], ["post", "sign"],
	["screen", "screen"], ["holo", "screen"], ["monitor", "screen"],
	["planter", "plant"], ["plant", "plant"], ["tree", "plant"], ["fern", "plant"],
	["gear", "cog"], ["cog", "cog"],
]

## Category -> glyph, used when no id keyword matches.
const CATEGORY_GLYPHS := {
	"lights": "lamp", "furniture": "chair", "plants": "plant", "tech": "screen", "signs": "sign",
	"material": "gem", "suit": "suit", "hat": "hat", "backpack": "backpack", "fun": "party",
}

## Categories that describe what the item IS worn as; they beat the id keyword table.
const CLOTHING_CATEGORIES: PackedStringArray = ["suit", "hat", "backpack"]

## Warm swatch colour per inferred category, for ids the Catalog does not know (never grey).
const FALLBACK_COLORS := {
	"lights": "#ffd166", "furniture": "#e0b98a", "plants": "#8fd97a", "tech": "#8fc4ef",
	"signs": "#ff9f7a", "material": "#c6a3ff", "suit": "#ffb59a", "hat": "#9fdcd6",
	"backpack": "#f0b98f", "fun": "#ffc2a1",
}
const FALLBACK_COLOR_DEFAULT := "#ffcf9b"

## The opaque navy visor (docs/STYLE_GUIDE.md R2.2 — you cannot see through it) used by the suit glyph.
const VISOR_NAVY := Color("#1b2450")
## Minimum HSV-value separation between a wearable's swatch and the accent drawn on top of it.
const WEAR_CONTRAST := 0.20

@export var icon_color: Color = Color("#ffd166"): set = set_icon_color
@export var category: String = "fun": set = set_category
## Item id; picks the glyph variant (see ID_GLYPHS).
@export var item_id: String = "": set = set_item_id
## Draw the rounded swatch background (off = glyph only).
@export var rounded_bg: bool = true: set = set_rounded_bg
## Dims everything (used for unaffordable shop items).
@export var dimmed: bool = false: set = set_dimmed

## Wearable colours lifted from the catalog item's own `style` dict (src/hub/clothing_catalog.gd).
## Alpha 0 means "this item has none", so the glyph falls back to a shade of the swatch.
## Without these, all 21 suits drew the SAME grey mannequin — `dark = swatch.darkened(0.48)` on an
## already-pale suit colour is grey, so Deep Space and Nebula were indistinguishable in the grid.
var style_accent: Color = Color(0, 0, 0, 0)
var style_visor: Color = Color(0, 0, 0, 0)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

## Reads id, icon_color, category and (for clothing) the style colours from a Catalog definition.
func set_def(def: Dictionary) -> void:
	item_id = str(def.get("id", ""))
	category = str(def.get("category", "fun"))
	var style: Dictionary = def.get("style", {}) if def.get("style") is Dictionary else {}
	style_accent = Color(str(style["accent_color"])) if style.has("accent_color") else Color(0, 0, 0, 0)
	style_visor = Color(str(style["visor_tint"])) if style.has("visor_tint") else Color(0, 0, 0, 0)
	icon_color = Color(str(def.get("icon_color", fallback_color(item_id))))

func set_icon_color(v: Color) -> void:
	icon_color = v
	queue_redraw()

func set_category(v: String) -> void:
	category = v
	queue_redraw()

func set_item_id(v: String) -> void:
	item_id = v
	queue_redraw()

func set_rounded_bg(v: bool) -> void:
	rounded_bg = v
	queue_redraw()

func set_dimmed(v: bool) -> void:
	dimmed = v
	queue_redraw()

# ----------------------------------------------------------------------------- id inference (static)
## Glyph name for an id + category pair (see ID_GLYPHS / CATEGORY_GLYPHS).
static func glyph_for(id: String, item_category: String) -> String:
	if item_category in CLOTHING_CATEGORIES:
		return item_category
	var lower := id.to_lower()
	for pair in ID_GLYPHS:
		if lower.contains(str(pair[0])):
			return str(pair[1])
	return str(CATEGORY_GLYPHS.get(item_category, "party"))

## Best-guess category for an id the Catalog does not know ("deco_moon_lamp" -> "lights").
static func category_for_id(id: String) -> String:
	var lower := id.to_lower()
	if lower.begins_with("suit_"):
		return "suit"
	if lower.begins_with("hat_"):
		return "hat"
	if lower.begins_with("pack_"):
		return "backpack"
	var glyph := glyph_for(id, "")
	for c in CATEGORY_GLYPHS:
		if str(CATEGORY_GLYPHS[c]) == glyph:
			return str(c)
	match glyph:
		"lamp", "tower", "orb", "fire", "projector":
			return "lights"
		"bench", "table", "crate", "rug", "rack", "tent":
			return "furniture"
		"flower", "mushroom", "rocket_planter":
			return "plants"
		"dish", "console", "globe", "vending", "ufo", "robot", "fountain":
			return "tech"
		"flag", "mailbox":
			return "signs"
		"spark", "rock":
			return "material"
	return "fun"

## Warm swatch colour for an id the Catalog does not know (never the old grey placeholder).
static func fallback_color(id: String) -> String:
	return str(FALLBACK_COLORS.get(category_for_id(id), FALLBACK_COLOR_DEFAULT))

# ----------------------------------------------------------------------------- draw
func _draw() -> void:
	var m := minf(size.x, size.y)
	if m <= 0.0:
		return
	var origin := (size - Vector2(m, m)) * 0.5
	var bg := icon_color
	if dimmed:
		bg = bg.lerp(Color("#bdb6a8"), 0.6)
	if rounded_bg:
		UIDraw.rrect(self, Rect2(origin, Vector2(m, m)), bg, m * 0.26)
		# soft highlight band at the top of the swatch
		var hl := Rect2(origin + Vector2(m * 0.12, m * 0.08), Vector2(m * 0.76, m * 0.16))
		UIDraw.rrect(self, hl, Color(1, 1, 1, 0.16), m * 0.08, 0.0)
	# glyph space: 100 units
	var u := m / 100.0
	draw_set_transform(origin + Vector2(m, m) * 0.5, 0.0, Vector2(u, u))
	var dark := bg.darkened(0.48)
	dark.s = minf(dark.s * 1.05, 1.0)
	var light := Color("#fffaea")
	var mid := bg.darkened(0.2)
	if dimmed:
		light = light.lerp(Color("#bdb6a8"), 0.4)
	match glyph_for(item_id, category):
		"lamp": _glyph_lamp(dark, light)
		"chair": _glyph_chair(dark, light, mid)
		"plant": _glyph_plant(dark, light)
		"screen": _glyph_screen(dark, light)
		"sign": _glyph_sign(dark, light)
		# Wearables paint themselves in their OWN two style colours, not in a shade of the swatch.
		"suit": _glyph_suit(_wear_main(bg), light, _wear_soft(bg))
		"hat": _glyph_hat(_wear_main(bg), light, _wear_soft(bg))
		"backpack": _glyph_backpack(_wear_main(bg), light, _wear_soft(bg))
		"gem": _glyph_crystal(dark, light, mid)
		"cog": _glyph_cog(dark, light)
		"spark": _glyph_spark(dark, light)
		"flower": _glyph_flower(dark, light)
		"rocket_planter": _glyph_rocket_planter(dark, light)
		"bench": _glyph_bench(dark, light)
		"flag": _glyph_flag(dark, light)
		"telescope": _glyph_telescope(dark, light)
		"dish": _glyph_dish(dark, light)
		"ufo": _glyph_ufo(dark, light)
		"robot": _glyph_robot(dark, light)
		"dog": _glyph_dog(dark, light)
		"tent": _glyph_tent(dark, light)
		"fire": _glyph_fire(dark, light)
		"table": _glyph_table(dark, light)
		"mushroom": _glyph_mushroom(dark, light)
		"egg": _glyph_egg(dark, light)
		"swing": _glyph_swing(dark, light)
		"tower": _glyph_tower(dark, light)
		"projector": _glyph_projector(dark, light)
		"globe": _glyph_globe(dark, light, bg)
		"console": _glyph_console(dark, light)
		"orb": _glyph_orb(dark, light)
		"vending": _glyph_vending(dark, light)
		"fountain": _glyph_fountain(dark, light)
		"rack": _glyph_rack(dark, light)
		"crate": _glyph_crate(dark, light)
		"rug": _glyph_rug(dark, light)
		"rock": _glyph_rock(dark, light)
		"mailbox": _glyph_mailbox(dark, light)
		_: _glyph_party(dark, light)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# ----------------------------------------------------------------------------- glyphs (unit space, center = 0,0, half-size 50)
func _glyph_lamp(dark: Color, light: Color) -> void:
	UIDraw.rrect(self, Rect2(-20, 26, 40, 10), dark, 5)
	UIDraw.rrect(self, Rect2(-5, -6, 10, 34), dark, 4)
	# glow halo + bulb
	UIDraw.circle(self, Vector2(0, -14), 25, Color(light, 0.35))
	UIDraw.circle(self, Vector2(0, -14), 19, light)
	UIDraw.circle(self, Vector2(-6, -20), 5, Color(1, 1, 1, 0.9))
	# rays
	for i in 3:
		var a := -PI * 0.5 + (float(i) - 1.0) * 0.75
		var p0 := Vector2(0, -14) + Vector2(cos(a), sin(a)) * 27
		var p1 := Vector2(0, -14) + Vector2(cos(a), sin(a)) * 35
		UIDraw.capsule(self, p0, p1, 4.5, light)

func _glyph_chair(dark: Color, light: Color, mid: Color) -> void:
	UIDraw.rrect(self, Rect2(-28, -30, 15, 48), dark, 7)        # back
	UIDraw.rrect(self, Rect2(-28, 4, 56, 16), dark, 8)          # seat
	UIDraw.rrect(self, Rect2(-24, 18, 10, 16), dark, 4)         # legs
	UIDraw.rrect(self, Rect2(14, 18, 10, 16), dark, 4)
	UIDraw.rrect(self, Rect2(-10, 6, 34, 8), light, 4, 0.0)     # cushion highlight
	UIDraw.rrect(self, Rect2(-24, -24, 6, 30), mid.lightened(0.3), 3, 0.0)

## A rotated leaf blade. Round scoops on a tapered pot read as ice cream, angled blades read as a plant.
func _leaf(center: Vector2, radii: Vector2, angle: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in 26:
		var t := TAU * float(i) / 26.0
		pts.append(center + Vector2(cos(t) * radii.x, sin(t) * radii.y).rotated(angle))
	UIDraw.poly(self, pts, color)

func _glyph_plant(dark: Color, light: Color) -> void:
	var stem := light.darkened(0.28)
	UIDraw.capsule(self, Vector2(0, 8), Vector2(-14, -16), 3.5, stem)
	UIDraw.capsule(self, Vector2(0, 8), Vector2(14, -14), 3.5, stem)
	UIDraw.capsule(self, Vector2(0, 8), Vector2(1, -24), 3.5, stem)
	_leaf(Vector2(-20, -24), Vector2(14, 7), -0.85, light)
	_leaf(Vector2(20, -21), Vector2(14, 7), 0.85, light)
	_leaf(Vector2(2, -34), Vector2(13, 7), -1.45, light)
	UIDraw.poly(self, PackedVector2Array([Vector2(-18, 6), Vector2(18, 6), Vector2(13, 32), Vector2(-13, 32)]), dark)
	UIDraw.rrect(self, Rect2(-22, 1, 44, 10), dark, 5)
	UIDraw.rrect(self, Rect2(-10, 14, 5, 12), Color(1, 1, 1, 0.22), 2.5, 0.0)

func _glyph_screen(dark: Color, light: Color) -> void:
	UIDraw.capsule(self, Vector2(0, -24), Vector2(12, -40), 4, dark)
	UIDraw.circle(self, Vector2(13, -41), 5, light)
	UIDraw.rrect(self, Rect2(-28, -24, 56, 40), dark, 9)
	UIDraw.rrect(self, Rect2(-22, -18, 44, 28), light, 6)
	# happy pixel face
	UIDraw.rrect(self, Rect2(-12, -10, 6, 8), dark, 2, 0.0)
	UIDraw.rrect(self, Rect2(6, -10, 6, 8), dark, 2, 0.0)
	UIDraw.capsule(self, Vector2(-8, 3), Vector2(8, 3), 3.5, dark)
	UIDraw.rrect(self, Rect2(-6, 16, 12, 8), dark, 3)
	UIDraw.rrect(self, Rect2(-18, 24, 36, 8), dark, 4)

func _glyph_sign(dark: Color, light: Color) -> void:
	UIDraw.rrect(self, Rect2(-5, -2, 10, 36), dark, 4)
	var board := PackedVector2Array([Vector2(-28, -32), Vector2(20, -32), Vector2(32, -17), Vector2(20, -2), Vector2(-28, -2)])
	UIDraw.poly(self, board, dark)
	UIDraw.rrect(self, Rect2(-20, -24, 30, 6), light, 3, 0.0)
	UIDraw.rrect(self, Rect2(-20, -14, 22, 6), light, 3, 0.0)
	UIDraw.rrect(self, Rect2(-14, 30, 28, 6), dark, 3)

func _glyph_party(dark: Color, light: Color) -> void:
	var pts := UIDraw.star_points(Vector2(0, -2), 34, 0.52)
	UIDraw.poly(self, pts, light)
	UIDraw.circle(self, Vector2(-8, -6), 3.6, dark)
	UIDraw.circle(self, Vector2(8, -6), 3.6, dark)
	# smile
	var smile := PackedVector2Array()
	for i in 9:
		var a := PI * 0.15 + PI * 0.7 * float(i) / 8.0
		smile.append(Vector2(0, 0) + Vector2(cos(a), sin(a)) * 9)
	draw_polyline(smile, dark, 3.2, true)
	UIDraw.circle(self, Vector2(-15, 2), 3, Color(1, 0.55, 0.55, 0.7))
	UIDraw.circle(self, Vector2(15, 2), 3, Color(1, 0.55, 0.55, 0.7))

# ------------------------------------------------------------------- wearables (suit / hat / pack)
## The colour a wearable's glyph is drawn in: its own `accent_color`, pushed away from the swatch
## when the two sit at the same brightness (Lunar Ranger's grey-blue and orange both measure V 0.87,
## which would read as one flat blob at card size).
func _wear_main(bg: Color) -> Color:
	var c := style_accent if style_accent.a > 0.0 else bg.darkened(0.48)
	if absf(c.v - bg.v) < WEAR_CONTRAST:
		c.v = clampf(c.v - 0.28, 0.14, 1.0) if bg.v > 0.5 else clampf(c.v + 0.28, 0.0, 0.96)
	if dimmed:
		c = c.lerp(Color("#bdb6a8"), 0.55)
	return c

## Secondary tone for belts, boots and neck rings — the swatch itself, shifted so it still reads
## against both the swatch behind it and the accent beside it.
func _wear_soft(bg: Color) -> Color:
	var c: Color = bg.darkened(0.26) if bg.v > 0.55 else bg.lightened(0.34)
	if dimmed:
		c = c.lerp(Color("#bdb6a8"), 0.55)
	return c

func _wear_visor() -> Color:
	# R2.2: the visor is OPAQUE deep navy. The item's own visor_tint only colours the highlight.
	return VISOR_NAVY.lerp(Color("#bdb6a8"), 0.55) if dimmed else VISOR_NAVY

## A chibi astronaut in the item's own two colours, built to the R2.7 grammar: a bubble helmet on a
## visible neck ring, a big dark visor with a crisp highlight, side ear-pods, and accent BANDS around
## the limbs (never a stripe down the torso, which reads as a wetsuit zip).
func _glyph_suit(main: Color, light: Color, soft: Color) -> void:
	UIDraw.rrect(self, Rect2(-32, -8, 13, 22), main, 6)         # arms
	UIDraw.rrect(self, Rect2(19, -8, 13, 22), main, 6)
	UIDraw.rrect(self, Rect2(-32, 9, 13, 5), soft, 2, 0.0)      # forearm bands
	UIDraw.rrect(self, Rect2(19, 9, 13, 5), soft, 2, 0.0)
	UIDraw.rrect(self, Rect2(-19, -10, 38, 34), main, 11)       # torso
	UIDraw.rrect(self, Rect2(-8, -3, 16, 14), light, 4, 0.0)    # chest control panel
	UIDraw.rrect(self, Rect2(-5.5, -0.5, 4, 3.5), soft, 1.2, 0.0)   # two little dials
	UIDraw.rrect(self, Rect2(1.5, -0.5, 4, 3.5), soft, 1.2, 0.0)
	UIDraw.rrect(self, Rect2(-19, 16, 38, 6), soft, 3, 0.0)     # waist band
	UIDraw.rrect(self, Rect2(-17, 25, 15, 11), soft, 4)         # boots
	UIDraw.rrect(self, Rect2(2, 25, 15, 11), soft, 4)
	UIDraw.rrect(self, Rect2(-21, -30, 8, 11), soft, 3)         # ear pods (behind the dome)
	UIDraw.rrect(self, Rect2(13, -30, 8, 11), soft, 3)
	UIDraw.rrect(self, Rect2(-14, -14, 28, 7), soft, 3)         # neck ring
	UIDraw.circle(self, Vector2(0, -26), 17, light)             # bubble helmet
	UIDraw.ellipse(self, Vector2(0, -25), Vector2(12.0, 9.0), _wear_visor())
	UIDraw.ellipse(self, Vector2(-5, -29), Vector2(3.6, 1.8), Color(1, 1, 1, 0.9))
	UIDraw.circle(self, Vector2(4.5, -29.5), 1.6, Color(1, 1, 1, 0.75))

## Three hats, three silhouettes: a peaked cap, a bobble antenna, a star crown.
func _glyph_hat(main: Color, light: Color, soft: Color) -> void:
	var kind := "cap"
	if item_id.contains("crown"):
		kind = "crown"
	elif item_id.contains("antenna"):
		kind = "antenna"
	if kind == "crown":
		var band := PackedVector2Array([Vector2(-30, 6), Vector2(30, 6), Vector2(30, -6),
			Vector2(18, -14), Vector2(9, -2), Vector2(0, -22), Vector2(-9, -2),
			Vector2(-18, -14), Vector2(-30, -6)])
		UIDraw.poly(self, band, main)
		UIDraw.rrect(self, Rect2(-31, 4, 62, 11), soft, 5)
		UIDraw.circle(self, Vector2(0, -24), 4.5, light)
		UIDraw.circle(self, Vector2(-19, -16), 3.2, light)
		UIDraw.circle(self, Vector2(19, -16), 3.2, light)
		UIDraw.sparkle(self, Vector2(24, -26), 7, light)
		return
	if kind == "cap":
		UIDraw.poly(self, PackedVector2Array([Vector2(-6, 2), Vector2(-40, 4), Vector2(-38, 12),
			Vector2(-6, 12)]), soft)                                        # peaked brim
	var dome := PackedVector2Array()
	for i in 25:
		var a := PI + PI * float(i) / 24.0
		dome.append(Vector2(0, 4) + Vector2(cos(a), sin(a)) * 24)
	UIDraw.poly(self, dome, main)
	UIDraw.rrect(self, Rect2(-26, 0, 52, 9), soft, 4)                       # crown band
	if kind == "antenna":
		# springy coil + glowing bobble
		for i in 4:
			UIDraw.capsule(self, Vector2(-4 if i % 2 == 0 else 4, -22 - float(i) * 5.0),
				Vector2(4 if i % 2 == 0 else -4, -27 - float(i) * 5.0), 2.0, soft)
		UIDraw.circle(self, Vector2(2, -46), 8.5, Color(light, 0.4))
		UIDraw.circle(self, Vector2(2, -46), 6.0, light)
		return
	UIDraw.rrect(self, Rect2(-3, -18, 6, 14), light, 2, 0.0)                # panel seam
	UIDraw.circle(self, Vector2(0, -19), 4, light)                          # button

## Two packs, two silhouettes: a stubby booster and twin thrusters.
func _glyph_backpack(main: Color, light: Color, soft: Color) -> void:
	UIDraw.rrect(self, Rect2(-17, -36, 8, 13), soft, 4)         # shoulder straps
	UIDraw.rrect(self, Rect2(9, -36, 8, 13), soft, 4)
	if item_id.contains("jet"):
		for sx: float in [-1.0, 1.0]:
			var x: float = sx * 12.0
			UIDraw.rrect(self, Rect2(x - 10.0, -26, 20, 42), main, 9)       # thruster can
			UIDraw.rrect(self, Rect2(x - 10.0, -14, 20, 6), soft, 3, 0.0)   # band
			UIDraw.poly(self, PackedVector2Array([Vector2(x - 8, 16), Vector2(x + 8, 16),
				Vector2(x + 5, 26), Vector2(x - 5, 26)]), soft)             # nozzle
			UIDraw.circle(self, Vector2(x, 32), 6.0, Color(light, 0.85))    # puff
			UIDraw.circle(self, Vector2(x + sx * 5.0, 39), 4.0, Color(light, 0.5))
		return
	if item_id.contains("rocket"):
		UIDraw.poly(self, PackedVector2Array([Vector2(-11, -18), Vector2(0, -38), Vector2(11, -18)]), soft)
		UIDraw.rrect(self, Rect2(-13, -20, 26, 40), main, 8)                # booster body
		UIDraw.rrect(self, Rect2(-13, -6, 26, 7), soft, 3, 0.0)             # band
		UIDraw.poly(self, PackedVector2Array([Vector2(-13, 8), Vector2(-13, 22), Vector2(-24, 24)]), main)
		UIDraw.poly(self, PackedVector2Array([Vector2(13, 8), Vector2(13, 22), Vector2(24, 24)]), main)
		UIDraw.poly(self, PackedVector2Array([Vector2(-11, 20), Vector2(11, 20), Vector2(8, 30), Vector2(-8, 30)]), soft)
		UIDraw.circle(self, Vector2(0, 36), 6.5, Color(light, 0.8))
		return
	UIDraw.rrect(self, Rect2(-24, -24, 48, 54), main, 14)       # rucksack body
	UIDraw.rrect(self, Rect2(-16, 2, 32, 20), light, 7)         # pocket
	UIDraw.rrect(self, Rect2(-16, -14, 32, 6), soft, 3, 0.0)    # zip
	UIDraw.circle(self, Vector2(0, 12), 3.5, soft)

func _glyph_crystal(dark: Color, light: Color, mid: Color) -> void:
	var gem := PackedVector2Array([Vector2(-26, -6), Vector2(-12, -26), Vector2(12, -26), Vector2(26, -6), Vector2(0, 30)])
	UIDraw.poly(self, gem, light)
	var facet := PackedVector2Array([Vector2(-26, -6), Vector2(0, 30), Vector2(-10, -6)])
	UIDraw.poly(self, facet, Color(mid, 0.45), 0.0)
	var facet2 := PackedVector2Array([Vector2(26, -6), Vector2(0, 30), Vector2(10, -6)])
	UIDraw.poly(self, facet2, Color(mid, 0.3), 0.0)
	draw_polyline(PackedVector2Array([Vector2(-26, -6), Vector2(26, -6)]), Color(dark, 0.35), 2.0, true)
	UIDraw.sparkle(self, Vector2(-18, -30), 8, light)
	UIDraw.sparkle(self, Vector2(24, 12), 5, light)

func _glyph_cog(dark: Color, light: Color) -> void:
	var pts := PackedVector2Array()
	for i in 96:
		var a := TAU * float(i) / 96.0
		var w := cos(a * 8.0)
		var r := 32.0
		if w < -0.4:
			r = 24.0
		elif w < 0.4:
			r = lerpf(24.0, 32.0, (w + 0.4) / 0.8)
		pts.append(Vector2(cos(a), sin(a)) * r)
	UIDraw.poly(self, pts, dark)
	UIDraw.circle(self, Vector2(0, 0), 12, light)
	UIDraw.circle(self, Vector2(-4, -4), 4, Color(1, 1, 1, 0.55))
	UIDraw.sparkle(self, Vector2(26, -28), 7, light)

func _glyph_spark(dark: Color, light: Color) -> void:
	UIDraw.sparkle(self, Vector2(-3, -4), 38, Color(dark, 0.30))
	UIDraw.sparkle(self, Vector2(-3, -4), 33, light)
	UIDraw.circle(self, Vector2(-3, -4), 6.5, Color(1, 1, 1, 0.9))
	UIDraw.sparkle(self, Vector2(25, 19), 14, light)
	UIDraw.sparkle(self, Vector2(-26, 21), 10, light)

func _glyph_flower(dark: Color, light: Color) -> void:
	UIDraw.capsule(self, Vector2(1, 34), Vector2(0, 4), 5, dark)
	UIDraw.ellipse(self, Vector2(16, 22), Vector2(12, 7), dark)
	for i in 6:
		var a := TAU * float(i) / 6.0 - PI * 0.5
		UIDraw.circle(self, Vector2(0, -10) + Vector2(cos(a), sin(a)) * 19, 12, light)
	UIDraw.circle(self, Vector2(0, -10), 11, dark)
	UIDraw.circle(self, Vector2(-3, -13), 3.5, Color(1, 1, 1, 0.65))

## A retired rocket nose used as a plant pot: fins + porthole so it never reads as an ice-cream cone,
## and the foliage is angled blades rather than round scoops.
func _glyph_rocket_planter(dark: Color, light: Color) -> void:
	UIDraw.capsule(self, Vector2(-3, -12), Vector2(-23, -32), 8, light)
	UIDraw.capsule(self, Vector2(3, -12), Vector2(22, -29), 8, light)
	UIDraw.capsule(self, Vector2(0, -12), Vector2(1, -39), 8, light)
	UIDraw.circle(self, Vector2(1, -41), 5, light.darkened(0.14))
	UIDraw.poly(self, PackedVector2Array([Vector2(-12, 4), Vector2(-32, 32), Vector2(-12, 32)]), dark.lightened(0.3))
	UIDraw.poly(self, PackedVector2Array([Vector2(12, 4), Vector2(32, 32), Vector2(12, 32)]), dark.lightened(0.3))
	UIDraw.poly(self, PackedVector2Array([Vector2(-18, -11), Vector2(18, -11), Vector2(12, 32), Vector2(-12, 32)]), dark)
	UIDraw.rrect(self, Rect2(-22, -16, 44, 10), dark, 5)
	UIDraw.circle(self, Vector2(0, 9), 7.5, Color(light, 0.9))
	UIDraw.circle(self, Vector2(0, 9), 4, Color(dark, 0.45))
	UIDraw.rrect(self, Rect2(-9, 17, 4, 11), Color(1, 1, 1, 0.22), 2, 0.0)

func _glyph_bench(dark: Color, light: Color) -> void:
	UIDraw.rrect(self, Rect2(-26, -28, 7, 28), dark, 3)         # back posts
	UIDraw.rrect(self, Rect2(19, -28, 7, 28), dark, 3)
	UIDraw.rrect(self, Rect2(-28, -24, 56, 7), dark, 3.5)       # back slats
	UIDraw.rrect(self, Rect2(-28, -13, 56, 7), dark, 3.5)
	UIDraw.rrect(self, Rect2(-30, -2, 60, 11), dark, 5)         # seat
	UIDraw.rrect(self, Rect2(-24, 9, 8, 21), dark, 4)           # legs
	UIDraw.rrect(self, Rect2(16, 9, 8, 21), dark, 4)
	UIDraw.rrect(self, Rect2(-24, 0, 40, 4), Color(light, 0.5), 2, 0.0)

func _glyph_flag(dark: Color, light: Color) -> void:
	UIDraw.rrect(self, Rect2(-4, -34, 8, 66), dark, 4)
	UIDraw.circle(self, Vector2(0, -37), 6, light)
	var wave := PackedVector2Array([Vector2(3, -30), Vector2(34, -25), Vector2(30, -14), Vector2(34, -3), Vector2(3, -7)])
	UIDraw.poly(self, wave, light)
	UIDraw.star(self, Vector2(17, -17), 8.5, dark, dark, 1.2)
	UIDraw.rrect(self, Rect2(-16, 28, 32, 8), dark, 4)

func _glyph_telescope(dark: Color, light: Color) -> void:
	UIDraw.capsule(self, Vector2(0, 6), Vector2(-17, 32), 5, dark)
	UIDraw.capsule(self, Vector2(0, 6), Vector2(17, 32), 5, dark)
	UIDraw.capsule(self, Vector2(0, 6), Vector2(0, 30), 5, dark)
	UIDraw.capsule(self, Vector2(-18, 14), Vector2(19, -21), 14, dark)
	UIDraw.circle(self, Vector2(20, -23), 11, light)
	UIDraw.circle(self, Vector2(20, -23), 5, Color(dark, 0.55))
	UIDraw.circle(self, Vector2(-19, 15), 6, dark.lightened(0.3))
	UIDraw.capsule(self, Vector2(-7, 4), Vector2(7, -9), 4, Color(1, 1, 1, 0.25))
	UIDraw.sparkle(self, Vector2(33, -36), 8, light)

func _glyph_dish(dark: Color, light: Color) -> void:
	UIDraw.rrect(self, Rect2(-17, 25, 34, 9), dark, 4.5)
	UIDraw.capsule(self, Vector2(0, 28), Vector2(-3, 2), 6, dark)
	UIDraw.ellipse(self, Vector2(-2, -10), Vector2(29, 23), dark)
	UIDraw.ellipse(self, Vector2(0, -12), Vector2(24, 18), light)
	UIDraw.capsule(self, Vector2(0, -12), Vector2(15, -27), 3, dark)
	UIDraw.circle(self, Vector2(0, -12), 5.5, dark)
	UIDraw.circle(self, Vector2(16, -28), 4, dark)
	UIDraw.sparkle(self, Vector2(28, -34), 8, light)

func _glyph_ufo(dark: Color, light: Color) -> void:
	UIDraw.poly(self, PackedVector2Array([Vector2(-13, 14), Vector2(13, 14), Vector2(24, 36), Vector2(-24, 36)]), Color(light, 0.32), 0.0)
	var dome := PackedVector2Array()
	for i in 25:
		var a := PI + PI * float(i) / 24.0
		dome.append(Vector2(0, -4) + Vector2(cos(a) * 17.0, sin(a) * 17.0))
	UIDraw.poly(self, dome, light)
	UIDraw.ellipse(self, Vector2(-6, -12), Vector2(5, 3.5), Color(1, 1, 1, 0.55))
	UIDraw.ellipse(self, Vector2(0, 2), Vector2(35, 13), dark)
	UIDraw.ellipse(self, Vector2(0, -2), Vector2(28, 8), dark.lightened(0.22))
	for i in 3:
		UIDraw.circle(self, Vector2(-19.0 + 19.0 * float(i), 8), 4.5, light)

func _glyph_robot(dark: Color, light: Color) -> void:
	UIDraw.capsule(self, Vector2(0, -33), Vector2(0, -41), 3, dark)
	UIDraw.circle(self, Vector2(0, -43), 5, light)
	UIDraw.rrect(self, Rect2(-27, 2, 8, 18), dark, 4)           # arms
	UIDraw.rrect(self, Rect2(19, 2, 8, 18), dark, 4)
	UIDraw.rrect(self, Rect2(-17, -2, 34, 28), dark, 11)        # body
	UIDraw.circle(self, Vector2(0, 12), 6, light)
	UIDraw.rrect(self, Rect2(-22, -34, 44, 32), dark, 13)       # head
	UIDraw.rrect(self, Rect2(-16, -29, 32, 21), light, 8)       # face screen
	UIDraw.circle(self, Vector2(-7, -21), 3.4, dark)
	UIDraw.circle(self, Vector2(7, -21), 3.4, dark)
	UIDraw.capsule(self, Vector2(-4, -14), Vector2(4, -14), 3, dark)

func _glyph_dog(dark: Color, light: Color) -> void:
	UIDraw.capsule(self, Vector2(23, 4), Vector2(34, -8), 5, dark)   # tail
	UIDraw.rrect(self, Rect2(-11, 18, 9, 15), dark, 4)               # legs
	UIDraw.rrect(self, Rect2(9, 18, 9, 15), dark, 4)
	UIDraw.ellipse(self, Vector2(5, 10), Vector2(23, 15), dark)      # body
	UIDraw.ellipse(self, Vector2(-30, -19), Vector2(7, 12), dark.lightened(0.18))
	UIDraw.ellipse(self, Vector2(-1, -19), Vector2(7, 12), dark.lightened(0.18))
	UIDraw.circle(self, Vector2(-15, -7), 19, dark)                  # head
	UIDraw.ellipse(self, Vector2(-17, 1), Vector2(13, 9), light)     # muzzle
	UIDraw.circle(self, Vector2(-17, -3), 4, dark)                   # nose
	UIDraw.circle(self, Vector2(-23, -13), 3.2, light)               # eyes
	UIDraw.circle(self, Vector2(-8, -13), 3.2, light)

func _glyph_tent(dark: Color, light: Color) -> void:
	var dome := PackedVector2Array()
	for i in 33:
		var a := PI + PI * float(i) / 32.0
		dome.append(Vector2(0, 26) + Vector2(cos(a) * 34.0, sin(a) * 40.0))
	UIDraw.poly(self, dome, dark)
	var door := PackedVector2Array()
	for i in 17:
		var a := PI + PI * float(i) / 16.0
		door.append(Vector2(0, 26) + Vector2(cos(a) * 13.0, sin(a) * 24.0))
	UIDraw.poly(self, door, light)
	UIDraw.rrect(self, Rect2(-36, 24, 72, 8), dark.lightened(0.22), 4)
	UIDraw.capsule(self, Vector2(0, -12), Vector2(0, -22), 3, dark)
	UIDraw.circle(self, Vector2(0, -25), 4.5, light)

func _glyph_fire(dark: Color, light: Color) -> void:
	# Wavy flame silhouette (a plain teardrop reads as a leaf), logs drawn over its base.
	UIDraw.poly(self, PackedVector2Array([
		Vector2(0, -38), Vector2(9, -22), Vector2(16, -27), Vector2(18, -5),
		Vector2(11, 13), Vector2(0, 19), Vector2(-11, 13), Vector2(-18, -5),
		Vector2(-16, -27), Vector2(-9, -22)]), light)
	UIDraw.poly(self, PackedVector2Array([Vector2(0, -13), Vector2(7, 2), Vector2(0, 13), Vector2(-7, 2)]), Color(1, 1, 1, 0.72))
	UIDraw.capsule(self, Vector2(-27, 23), Vector2(19, 32), 7, dark)
	UIDraw.capsule(self, Vector2(-19, 32), Vector2(27, 23), 7, dark.lightened(0.3))
	UIDraw.sparkle(self, Vector2(-25, -19), 7, light)
	UIDraw.sparkle(self, Vector2(25, -27), 5, light)

func _glyph_table(dark: Color, light: Color) -> void:
	UIDraw.capsule(self, Vector2(0, -30), Vector2(0, -16), 2.5, dark)
	UIDraw.circle(self, Vector2(0, -24), 8, light)
	UIDraw.poly(self, PackedVector2Array([Vector2(-22, -4), Vector2(-14, -4), Vector2(-2, 30), Vector2(-10, 30)]), dark)
	UIDraw.poly(self, PackedVector2Array([Vector2(14, -4), Vector2(22, -4), Vector2(10, 30), Vector2(2, 30)]), dark)
	UIDraw.rrect(self, Rect2(-32, 8, 20, 9), dark, 4)
	UIDraw.rrect(self, Rect2(12, 8, 20, 9), dark, 4)
	UIDraw.rrect(self, Rect2(-34, -14, 68, 11), dark, 5)
	UIDraw.rrect(self, Rect2(-28, -12, 44, 4), Color(light, 0.45), 2, 0.0)

func _glyph_mushroom(dark: Color, light: Color) -> void:
	UIDraw.rrect(self, Rect2(-9, -4, 18, 34), light, 8)
	var cap := PackedVector2Array()
	for i in 33:
		var a := PI + PI * float(i) / 32.0
		cap.append(Vector2(0, -2) + Vector2(cos(a) * 32.0, sin(a) * 29.0))
	UIDraw.poly(self, cap, dark)
	UIDraw.circle(self, Vector2(-14, -14), 6, light)
	UIDraw.circle(self, Vector2(9, -18), 5, light)
	UIDraw.circle(self, Vector2(17, -6), 4, light)
	UIDraw.circle(self, Vector2(-5, -6), 3, light)
	UIDraw.rrect(self, Rect2(-13, 26, 26, 8), dark, 4)

func _glyph_egg(dark: Color, light: Color) -> void:
	var e := PackedVector2Array()
	for i in 40:
		var a := TAU * float(i) / 40.0
		var t := (sin(a) + 1.0) * 0.5
		e.append(Vector2(cos(a) * 24.0 * (0.78 + 0.22 * t), sin(a) * 33.0 + 2.0))
	UIDraw.poly(self, e, light)
	UIDraw.ellipse(self, Vector2(-4, 12), Vector2(8, 6), Color(dark, 0.5))
	UIDraw.ellipse(self, Vector2(10, -5), Vector2(6, 5), Color(dark, 0.5))
	UIDraw.ellipse(self, Vector2(-9, -12), Vector2(5, 4), Color(dark, 0.5))
	UIDraw.ellipse(self, Vector2(-10, -21), Vector2(7, 5), Color(1, 1, 1, 0.55))
	UIDraw.sparkle(self, Vector2(26, -27), 8, light)

func _glyph_swing(dark: Color, light: Color) -> void:
	UIDraw.capsule(self, Vector2(-30, -28), Vector2(-35, 30), 5, dark)
	UIDraw.capsule(self, Vector2(30, -28), Vector2(35, 30), 5, dark)
	UIDraw.capsule(self, Vector2(-31, -28), Vector2(31, -28), 6, dark)
	UIDraw.rrect(self, Rect2(-42, 28, 20, 8), dark, 4)
	UIDraw.rrect(self, Rect2(22, 28, 20, 8), dark, 4)
	UIDraw.capsule(self, Vector2(-12, -25), Vector2(-12, 8), 3, dark.lightened(0.25))
	UIDraw.capsule(self, Vector2(12, -25), Vector2(12, 8), 3, dark.lightened(0.25))
	UIDraw.rrect(self, Rect2(-19, 8, 38, 10), light, 5)
	UIDraw.sparkle(self, Vector2(24, -14), 7, light)

func _glyph_tower(dark: Color, light: Color) -> void:
	UIDraw.poly(self, PackedVector2Array([Vector2(6, -28), Vector2(40, -40), Vector2(40, -12)]), Color(light, 0.38), 0.0)
	UIDraw.poly(self, PackedVector2Array([Vector2(-6, -28), Vector2(-40, -40), Vector2(-40, -12)]), Color(light, 0.38), 0.0)
	UIDraw.poly(self, PackedVector2Array([Vector2(-10, -20), Vector2(10, -20), Vector2(20, 28), Vector2(-20, 28)]), dark)
	UIDraw.rrect(self, Rect2(-25, 26, 50, 9), dark, 4.5)
	UIDraw.rrect(self, Rect2(-16, 0, 32, 7), dark.lightened(0.25), 3.5, 0.0)
	UIDraw.rrect(self, Rect2(-14, -32, 28, 13), dark, 6)
	UIDraw.circle(self, Vector2(0, -26), 8, light)

func _glyph_projector(dark: Color, light: Color) -> void:
	UIDraw.poly(self, PackedVector2Array([Vector2(8, -14), Vector2(42, -36), Vector2(42, 10), Vector2(8, 2)]), Color(light, 0.34), 0.0)
	UIDraw.rrect(self, Rect2(-26, 14, 10, 15), dark, 4)
	UIDraw.rrect(self, Rect2(-4, 14, 10, 15), dark, 4)
	UIDraw.rrect(self, Rect2(-34, -16, 44, 30), dark, 10)
	UIDraw.rrect(self, Rect2(-28, -10, 12, 8), Color(light, 0.8), 3, 0.0)
	UIDraw.circle(self, Vector2(9, -2), 11, dark.lightened(0.2))
	UIDraw.circle(self, Vector2(9, -2), 7, light)
	UIDraw.star(self, Vector2(34, -26), 7, light, light, 1.0)
	UIDraw.star(self, Vector2(31, 4), 5, light, light, 1.0)

func _glyph_globe(dark: Color, light: Color, bg: Color) -> void:
	UIDraw.rrect(self, Rect2(-15, 26, 30, 9), dark, 4.5)
	UIDraw.capsule(self, Vector2(0, 28), Vector2(0, 10), 5, dark)
	UIDraw.ellipse(self, Vector2(0, -8), Vector2(37, 12), dark)
	UIDraw.ellipse(self, Vector2(0, -8), Vector2(27, 8), bg)
	UIDraw.circle(self, Vector2(0, -8), 22, light)
	UIDraw.circle(self, Vector2(-8, -16), 6, Color(1, 1, 1, 0.5))
	UIDraw.ellipse(self, Vector2(8, -2), Vector2(9, 5), Color(dark, 0.3))
	# front half of the ring, drawn over the planet
	var front := PackedVector2Array()
	for i in 25:
		var a := PI * float(i) / 24.0
		front.append(Vector2(0, -8) + Vector2(cos(a) * 37.0, sin(a) * 12.0))
	for i in 25:
		var a := PI * (1.0 - float(i) / 24.0)
		front.append(Vector2(0, -8) + Vector2(cos(a) * 27.0, sin(a) * 8.0))
	UIDraw.poly(self, front, dark)

func _glyph_console(dark: Color, light: Color) -> void:
	UIDraw.rrect(self, Rect2(-24, 20, 48, 12), dark, 5)
	UIDraw.poly(self, PackedVector2Array([Vector2(-32, -8), Vector2(32, -8), Vector2(36, 18), Vector2(-36, 18)]), dark)
	UIDraw.rrect(self, Rect2(-26, -32, 52, 24), dark, 8)
	UIDraw.rrect(self, Rect2(-21, -28, 42, 16), light, 6)
	UIDraw.rrect(self, Rect2(-17, -24, 12, 3), dark, 1.5, 0.0)
	UIDraw.rrect(self, Rect2(-17, -19, 22, 3), dark, 1.5, 0.0)
	for i in 4:
		UIDraw.circle(self, Vector2(-21.0 + 14.0 * float(i), 5), 4.5, light)

func _glyph_orb(dark: Color, light: Color) -> void:
	UIDraw.rrect(self, Rect2(-22, 26, 44, 9), dark, 4.5)
	UIDraw.ellipse(self, Vector2(0, 24), Vector2(15, 5), dark.lightened(0.25))
	UIDraw.circle(self, Vector2(0, -6), 30, Color(light, 0.28))
	UIDraw.circle(self, Vector2(0, -6), 21, light)
	UIDraw.circle(self, Vector2(-7, -14), 6, Color(1, 1, 1, 0.8))
	UIDraw.sparkle(self, Vector2(27, -27), 8, light)
	UIDraw.sparkle(self, Vector2(-27, 5), 6, light)

func _glyph_vending(dark: Color, light: Color) -> void:
	UIDraw.rrect(self, Rect2(-26, -34, 52, 66), dark, 11)
	UIDraw.rrect(self, Rect2(-20, -28, 27, 40), light, 6)
	for r in 3:
		for c in 2:
			UIDraw.rrect(self, Rect2(-17.0 + 13.0 * float(c), -25.0 + 13.0 * float(r), 9, 9), Color(dark, 0.75), 3, 0.0)
	UIDraw.rrect(self, Rect2(11, -26, 11, 17), Color(light, 0.85), 4, 0.0)
	UIDraw.rrect(self, Rect2(-20, 16, 40, 11), dark.lightened(0.28), 5)
	UIDraw.rrect(self, Rect2(-23, 30, 11, 7), dark, 3)
	UIDraw.rrect(self, Rect2(12, 30, 11, 7), dark, 3)

func _glyph_fountain(dark: Color, light: Color) -> void:
	for s in [-1.0, 1.0]:
		var arc := PackedVector2Array()
		for i in 13:
			var t := float(i) / 12.0
			arc.append(Vector2(s * (2.0 + 24.0 * t), -18.0 + 30.0 * t * t - 6.0 * t))
		draw_polyline(arc, light, 4.5, true)
	UIDraw.capsule(self, Vector2(0, 14), Vector2(0, -8), 6, dark)
	UIDraw.ellipse(self, Vector2(0, -11), Vector2(16, 6), dark)
	UIDraw.circle(self, Vector2(0, -23), 6, light)
	UIDraw.ellipse(self, Vector2(0, 20), Vector2(34, 14), dark)
	UIDraw.ellipse(self, Vector2(0, 17), Vector2(27, 10), light)
	UIDraw.sparkle(self, Vector2(0, -33), 7, light)

func _glyph_rack(dark: Color, light: Color) -> void:
	UIDraw.capsule(self, Vector2(-24, -22), Vector2(-24, 30), 4, dark)
	UIDraw.capsule(self, Vector2(24, -22), Vector2(24, 30), 4, dark)
	UIDraw.rrect(self, Rect2(-34, 28, 20, 8), dark, 4)
	UIDraw.rrect(self, Rect2(14, 28, 20, 8), dark, 4)
	UIDraw.capsule(self, Vector2(-30, -22), Vector2(30, -22), 5, dark)
	for i in 2:
		var x := -12.0 + 24.0 * float(i)
		UIDraw.capsule(self, Vector2(x, -22), Vector2(x, -12), 3, dark.lightened(0.25))
		UIDraw.poly(self, PackedVector2Array([Vector2(x - 12, -11), Vector2(x + 12, -11), Vector2(x + 9, 18), Vector2(x - 9, 18)]), light)

func _glyph_crate(dark: Color, light: Color) -> void:
	UIDraw.rrect(self, Rect2(-30, -25, 60, 52), dark, 9)
	UIDraw.rrect(self, Rect2(-30, -25, 60, 11), dark.lightened(0.25), 5)
	UIDraw.poly(self, PackedVector2Array([Vector2(-26, -11), Vector2(-16, -11), Vector2(24, 21), Vector2(14, 21)]), Color(light, 0.5), 0.0)
	UIDraw.poly(self, PackedVector2Array([Vector2(16, -11), Vector2(26, -11), Vector2(-14, 21), Vector2(-24, 21)]), Color(light, 0.5), 0.0)
	UIDraw.star(self, Vector2(0, 5), 9, light, light, 1.2)

## A rug lying flat in perspective, with fringe on both ends (concentric ellipses read as an eye).
func _glyph_rug(dark: Color, light: Color) -> void:
	for i in 5:
		var x := -22.0 + 11.0 * float(i)
		UIDraw.capsule(self, Vector2(x, -18), Vector2(x, -25), 2.5, dark)
	for i in 7:
		var x := -34.0 + 11.3 * float(i)
		UIDraw.capsule(self, Vector2(x, 20), Vector2(x, 27), 2.5, dark)
	UIDraw.poly(self, PackedVector2Array([Vector2(-26, -18), Vector2(26, -18), Vector2(38, 20), Vector2(-38, 20)]), dark)
	UIDraw.poly(self, PackedVector2Array([Vector2(-20, -12), Vector2(20, -12), Vector2(29, 14), Vector2(-29, 14)]), light)
	UIDraw.poly(self, PackedVector2Array([Vector2(-12, -6), Vector2(12, -6), Vector2(18, 8), Vector2(-18, 8)]), dark)
	UIDraw.star(self, Vector2(0, 1), 9, light, light, 1.2)

## Space rock: a lumpy silhouette with a flat-ish base, a sunlit top face and dented craters
## (light dots on a dark body just read as dice pips).
func _glyph_rock(dark: Color, light: Color) -> void:
	UIDraw.poly(self, PackedVector2Array([
		Vector2(-35, 4), Vector2(-25, -17), Vector2(-6, -27), Vector2(15, -23),
		Vector2(31, -7), Vector2(34, 11), Vector2(21, 25), Vector2(-17, 25), Vector2(-31, 17)]), dark)
	UIDraw.poly(self, PackedVector2Array([
		Vector2(-25, -17), Vector2(-6, -27), Vector2(15, -23), Vector2(7, -8), Vector2(-14, -6)]),
		Color(light, 0.30), 0.0)
	_crater(Vector2(-13, 8), 8.5, dark, light)
	_crater(Vector2(13, 11), 5.5, dark, light)
	_crater(Vector2(18, -7), 4.5, dark, light)
	UIDraw.sparkle(self, Vector2(28, -27), 7, light)

## One crater: a dark dent with a light rim along its top edge.
func _crater(center: Vector2, r: float, dark: Color, light: Color) -> void:
	UIDraw.ellipse(self, center, Vector2(r, r * 0.72), dark.darkened(0.34))
	UIDraw.ellipse(self, center - Vector2(0.0, r * 0.22), Vector2(r * 0.82, r * 0.44), Color(light, 0.20))

func _glyph_mailbox(dark: Color, light: Color) -> void:
	UIDraw.rrect(self, Rect2(-5, -4, 10, 36), dark, 4)
	UIDraw.capsule(self, Vector2(25, -24), Vector2(25, -40), 3, light)
	UIDraw.rrect(self, Rect2(21, -45, 14, 10), light, 3)
	UIDraw.rrect(self, Rect2(-26, -30, 52, 30), dark, 13)
	UIDraw.rrect(self, Rect2(-26, -30, 52, 12), dark.lightened(0.22), 6)
	UIDraw.rrect(self, Rect2(-14, -20, 28, 15), light, 5)
	UIDraw.circle(self, Vector2(0, -12), 3.5, dark)
	UIDraw.rrect(self, Rect2(-17, 28, 34, 8), dark, 4)
