class_name ItemCard
extends Button
## Rounded item card used by the inventory and shops: procedural swatch glyph, name, count badge or price tag.
## It is a Button so mouse click / hover work; menus drive keyboard & gamepad selection by index.
##
## SIZE IS FIXED IN BOTH MODES (integration critic, blocking #1). A shop card used to be 18 px TALLER
## than a bag card, which pushed the third grid row past the bottom of the scroll well: the row was
## clipped through the name line ("Robot" for *Robot Buddy Statue*) and its whole price row was cut
## off, with no scrollbar to explain why. `ItemGridPanel` now sizes its well to a whole number of
## these rows, which only works if the height is a constant — so the price tag lives INSIDE the same
## 136 px box as the bag card, and the glyph / name block gives up the room for it.

const CARD_SIZE := Vector2(112.0, 136.0)
## MOBILE (R2.10: "bigger touch targets and larger type"). The card is both the touch target and
## the thing you read, so it grows on both axes; `ItemGridPanel` derives its column count from
## whichever size is live, so the grid stays whole-rows in either front end.
const CARD_SIZE_MOBILE := Vector2(132.0, 196.0)
## Swatch size. Bag cards can afford a big glyph; shop cards shrink it to make room for the price row.
const GLYPH_SIZE := 66.0
const GLYPH_SIZE_SHOP := 56.0
const GLYPH_SIZE_MOBILE := 100.0
const GLYPH_SIZE_SHOP_MOBILE := 86.0
## Text block geometry (two lines of "CardName" at font 15 + line_spacing 2 measure 40 px).
const NAME_H := 40.0
const NAME_H_MOBILE := 52.0
const PRICE_H := 24.0
const PRICE_H_MOBILE := 30.0
## Font sizes tried for the card name, largest first. A name that still needs three lines at 15 px
## ("Robot Vending Machine") is set one or two steps smaller rather than ellipsised - trimming the
## name is what made a card read "Robot" for *Robot Buddy Statue* in the first place.
const NAME_SIZES: PackedInt32Array = [15, 14, 13, 12]
const NAME_SIZES_MOBILE: PackedInt32Array = [17, 16, 15, 14]
const NAME_MAX_LINES := 2


## The card box for the front end that is running. Read this, never CARD_SIZE, so the two stay in
## step - `ItemGridPanel` sizes its grid well to a whole number of THESE rows.
static func card_size() -> Vector2:
	return CARD_SIZE_MOBILE if MobileUI.is_mobile() else CARD_SIZE


static func glyph_size(shop_mode: bool) -> float:
	if MobileUI.is_mobile():
		return GLYPH_SIZE_SHOP_MOBILE if shop_mode else GLYPH_SIZE_MOBILE
	return GLYPH_SIZE_SHOP if shop_mode else GLYPH_SIZE


static func name_height() -> float:
	return NAME_H_MOBILE if MobileUI.is_mobile() else NAME_H


static func price_height() -> float:
	return PRICE_H_MOBILE if MobileUI.is_mobile() else PRICE_H

var item_id: String = ""
var def: Dictionary = {}
var count: int = 0
var price: int = -1
var affordable: bool = true
## Index in the owning grid (set by the grid panel).
var grid_index: int = -1

var _glyph: ItemGlyph
var _name: Label
var _badge: PanelContainer
var _badge_label: Label
var _price_row: HBoxContainer
var _price_label: Label
var _price_star: StarIcon
var _selected := false

func _ready() -> void:
	var cs := card_size()
	var gs := glyph_size(false)
	custom_minimum_size = cs
	text = ""
	clip_contents = false
	UIStyle.setup_button(self, "Card")
	_glyph = ItemGlyph.new()
	_glyph.position = Vector2((cs.x - gs) * 0.5, 10.0)
	_glyph.size = Vector2(gs, gs)
	add_child(_glyph)
	_name = UIStyle.make_label("", "CardName", HORIZONTAL_ALIGNMENT_CENTER)
	_name.position = Vector2(6.0, 82.0)
	_name.size = Vector2(cs.x - 12.0, name_height())
	_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_name.max_lines_visible = 2
	_name.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	add_child(_name)
	_badge = PanelContainer.new()
	_badge.theme_type_variation = "Badge"
	_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_badge_label = UIStyle.make_label("", "Badge", HORIZONTAL_ALIGNMENT_CENTER)
	_badge.add_child(_badge_label)
	_badge.visible = false
	add_child(_badge)
	_price_row = HBoxContainer.new()
	_price_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_price_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_price_row.add_theme_constant_override("separation", 4)
	_price_star = StarIcon.new()
	_price_star.icon_size = 22.0 if MobileUI.is_mobile() else 18.0
	_price_row.add_child(_price_star)
	_price_label = UIStyle.make_label("", "Price")
	_price_row.add_child(_price_label)
	_price_row.position = Vector2(0.0, cs.y - price_height() - 4.0)
	_price_row.size = Vector2(cs.x, price_height())
	_price_row.visible = false
	add_child(_price_row)
	_apply()

## Fills the card from a Catalog definition.
func set_item(item_def: Dictionary, item_count: int = 1) -> void:
	def = item_def
	item_id = str(def.get("id", ""))
	count = item_count
	_apply()

## Shows a price tag (shop mode). affordable=false dims the card and paints the price red.
func set_price(p: int, can_afford: bool = true) -> void:
	price = p
	affordable = can_afford
	_apply()

## Selection highlight while the focus is elsewhere (e.g. on the action buttons).
func set_selected(v: bool) -> void:
	if _selected == v:
		return
	_selected = v
	queue_redraw()

## Little wobble for "can't do that" feedback.
func wobble() -> void:
	UIStyle.wobble(self, 6.0)

func _apply() -> void:
	if _glyph == null:
		return
	_glyph.set_def(def)
	_glyph.dimmed = not affordable
	_name.text = str(def.get("name", UIStyle.pretty_id(item_id)))
	var shop_mode := price >= 0
	# The card is ALWAYS card_size(). In shop mode the swatch shrinks and the name block slides up so
	# the price row fits inside the same box (see the header note): a taller shop card is what used
	# to make the third row of a stocked shop clip.
	var cs := card_size()
	custom_minimum_size = cs
	size = cs
	var g := glyph_size(shop_mode)
	_glyph.position = Vector2((cs.x - g) * 0.5, 8.0 if shop_mode else 10.0)
	_glyph.size = Vector2(g, g)
	var name_y: float = _glyph.position.y + g + 4.0
	_name.max_lines_visible = 2
	_name.position = Vector2(6.0, name_y)
	_name.size = Vector2(cs.x - 12.0, name_height())
	_price_row.visible = shop_mode
	if shop_mode:
		_price_label.text = str(price)
		_price_label.theme_type_variation = "Price" if affordable else "PriceBad"
		_price_star.modulate = Color.WHITE if affordable else Color(1, 1, 1, 0.55)
	_price_row.position = Vector2(0.0, cs.y - price_height() - 4.0)
	_price_row.size = Vector2(cs.x, price_height())
	_badge.visible = (not shop_mode) and count > 1
	if _badge.visible:
		_badge_label.text = "x%d" % count
		_badge.reset_size()
		_badge.position = Vector2(cs.x - _badge.size.x - 6.0, 6.0)
	_name.modulate = Color.WHITE if affordable else Color(1, 1, 1, 0.55)
	_fit_name()
	queue_redraw()

## Picks the largest NAME_SIZES entry that wraps this name into NAME_MAX_LINES lines.
func _fit_name() -> void:
	var f: Font = _name.get_theme_font("font")
	if f == null or _name.text == "":
		return
	var w := card_size().x - 12.0
	var sizes := NAME_SIZES_MOBILE if MobileUI.is_mobile() else NAME_SIZES
	var chosen: int = sizes[sizes.size() - 1]
	for s in sizes:
		var box := f.get_multiline_string_size(_name.text, HORIZONTAL_ALIGNMENT_CENTER, w, s)
		if int(round(box.y / maxf(f.get_height(s), 1.0))) <= NAME_MAX_LINES:
			chosen = s
			break
	_name.add_theme_font_size_override("font_size", chosen)

func _draw() -> void:
	if _selected and not has_focus():
		var sb := get_theme_stylebox("focus")
		if sb != null:
			sb.draw(get_canvas_item(), Rect2(Vector2.ZERO, size))
