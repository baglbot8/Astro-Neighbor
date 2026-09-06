class_name ItemGridPanel
extends Control
## Base class for the Inventory and the ShopPanel: dimmed backdrop, cream modal panel, header with title +
## optional tabs, a 5-column grid of ItemCards inside a scroll well, a details column with action buttons,
## a hint strip, and unified keyboard / gamepad / mouse navigation (grid -> actions -> back).
## Subclasses implement the _hook_* methods.

signal closed

## Grid columns and grid width are DERIVED (see `_measure_layout`), not fixed, because the mobile
## front end runs bigger cards in a wider viewport. The desktop numbers come out at exactly the 5
## columns / 664 px this panel has always used, so nothing about the desktop layout moves.
const MARGIN := 30.0
const HEADER_H := 54.0
## Tall enough to hold a full MobileUI.MIN_TOUCH tab / close button without them hanging out of
## the header rect (R2.10: every touch target at least ~48 dp - a 63 px tab was only 39 dp).
const HEADER_H_MOBILE := 92.0
## Width of the details column beside the grid. Desktop: 1128 - 60 - 664 - 18.
const DETAILS_W := 386.0
const DETAILS_W_MOBILE := 380.0
## Details column on mobile: the swatch and the description minimum are the two things `_fit_details`
## is allowed to give back when the column is short (a narrow viewport, or a big safe-area inset).
## The action buttons and the name never shrink - they are what the column is FOR.
const DETAIL_GLYPH_MOBILE := 96.0
const DETAIL_GLYPH_MOBILE_MIN := 52.0
const DETAIL_DESC_MOBILE := 76.0
## Room reserved for the scroll bar inside the grid well.
const SCROLLBAR_W := 10.0
## Gap between two cards (GridContainer h/v separation, set in build_theme.gd).
const CARD_GAP := 12.0
const BODY_Y := 88.0
const BODY_Y_MOBILE := 128.0
const HINT_H := 34.0
## Content margin baked into the "GridWell" stylebox (build_theme.gd) and the inner MarginContainer.
const WELL_INSET := 12.0
const GRID_PAD := 6.0
## Panel box. Derived from the viewport and then trimmed DOWN to a whole number of card rows, so the
## grid well can never rest on a half-card again (integration critic, blocking #1). The project uses
## `canvas_items` stretch from a 1280x720 base, so at 16:9 this always resolves to the same 628 px
## panel whatever the window size — the viewport terms only do work on an unusual aspect ratio.
const PANEL_W := 1128.0
## Mobile gets a wider panel because the landscape phone viewport is wider (1560 x 720 logical at
## 2340x1080), and a taller one because the keyboard hint strip is gone.
const PANEL_W_MOBILE := 1400.0
const PANEL_H_MIN := 560.0
const PANEL_H_MAX := 800.0
## Free space left around the panel (top+bottom / left+right combined).
const VIEWPORT_INSET := Vector2(100.0, 92.0)
const VIEWPORT_INSET_MOBILE := Vector2(120.0, 40.0)
const SCROLL_TWEEN := 0.16

enum NavState { GRID, ACTIONS }

var is_open := false
## Actual panel box and grid-well height, recomputed from the viewport in `_apply_layout`.
var _panel_size := Vector2(PANEL_W, 628.0)
var _body_h := 460.0
## Derived per front end in `_measure_layout` (5 x 664 on desktop, 6 x 902 on a landscape phone).
var _columns := 5
var _grid_w := 664.0
## Height of the DETAILS column. Equal to the grid well on desktop; on mobile it is the full body
## height while the well stays trimmed to whole card rows - the details column carries a 1.2x
## header, a description and two thumb-sized action buttons, and simply does not fit in a
## row-exact box. (It overflowed off the bottom of the screen before this split existed.)
var _details_h := 460.0
## Mobile close button in the header - a panel must not need a keyboard Esc on a phone.
var _close_btn: Button
var _scroll_tween: Tween

var _modal_name := "inventory"
var _entries: Array[Dictionary] = []
var _cards: Array[ItemCard] = []
var _selected := -1
var _nav_state := NavState.GRID
var _action_index := 0
var _action_buttons: Array[Button] = []
var _tabs: Array[Button] = []
var _tab_ids: PackedStringArray = []
var _tab := 0
var _repeat := UIFocus.NavRepeat.new()
var _cooldown := 0.0
var _refresh_queued := false

var _backdrop: ColorRect
var _panel: Panel
var _title_label: Label
var _subtitle_label: Label
var _tab_row: HBoxContainer
var _header_right: HBoxContainer
var _well: PanelContainer
var _scroll: ScrollContainer
var _grid: GridContainer
var _empty_box: VBoxContainer
var _empty_title: Label
var _empty_sub: Label
var _details: PanelContainer
var _details_box: VBoxContainer
var _detail_glyph: ItemGlyph
var _detail_name: Label
var _detail_tag: PanelContainer
var _detail_tag_label: Label
var _detail_desc: RichTextLabel
var _detail_extra: HBoxContainer
var _actions_box: VBoxContainer
var _details_empty: Label
var _hints: HBoxContainer
var _confirm: ConfirmPopup
var _well_overlay: Control
var _more_pill: PanelContainer
var _more_label: Label

# ----------------------------------------------------------------------------- hooks (override)
## Modal name reported to EventBus.
func _hook_modal_name() -> String:
	return "inventory"

## Title shown top-left.
func _hook_title() -> String:
	return "Bag"

## Tab ids + labels, e.g. [["all", "All"], ["decorations", "Decorations"]]. Empty = no tabs.
func _hook_tabs() -> Array:
	return []

## Entries for the current tab: [{"id": String, "def": Dictionary, "count": int, "price": int}].
func _hook_entries(_tab_id: String) -> Array[Dictionary]:
	return []

## Per-entry card decoration (price tags etc.).
func _hook_decorate_card(_card: ItemCard, _entry: Dictionary) -> void:
	pass

## Actions for the selected entry:
## [{"id": "place", "label": "Place", "primary": true, "disabled": false}].
## A "disabled" action still renders (greyed, unfocusable) so the panel can explain WHY it is unavailable.
func _hook_actions(_entry: Dictionary) -> Array:
	return []

## Fills the extra row in the details panel (count, price...).
func _hook_fill_extra(_extra: HBoxContainer, _entry: Dictionary) -> void:
	pass

## Performs the action `_action_id` on the selected entry (called from the action buttons).
func _hook_action(_entry: Dictionary, _action_id: String) -> void:
	pass

## Hint strip entries: [["interact", "Select"], ["cancel", "Close"]].
func _hook_hints() -> Array:
	return [["interact", "Select"], ["cancel", "Close"]]

## Empty-state copy.
func _hook_empty_text() -> PackedStringArray:
	return ["Nothing here yet", "Explore the planet to find treasures."]

# ----------------------------------------------------------------------------- setup
func _ready() -> void:
	# Mobile type scale + thumb-sized button padding, applied BEFORE _build so every minimum size
	# is measured once, at the size it will actually be drawn (R2.10: "larger type", "bigger
	# touch targets", "must not need a mouse").
	MobileUI.apply_theme(self)
	_modal_name = _hook_modal_name()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_measure_layout()
	_build()
	get_viewport().size_changed.connect(_apply_layout)
	MobileUI.on_mode_changed(_on_platform_mode_changed)
	EventBus.item_added.connect(func(_id: String, _c: int) -> void: _queue_refresh())
	EventBus.item_removed.connect(func(_id: String, _c: int) -> void: _queue_refresh())

## Nudge that keeps a centred panel out of the safe-area insets: a notch on one side of a landscape
## phone (or a home indicator at the bottom) makes the USABLE rectangle off-centre, and a panel
## centred in the whole viewport would sit under it.
func _safe_centre_offset() -> Vector2:
	var sa := MobileUI.safe_area()
	return Vector2((sa.x - sa.z) * 0.5, (sa.y - sa.w) * 0.5)


## Sizes and shows / hides the mobile close button for the current front end.
func _apply_close_button() -> void:
	if _close_btn == null:
		return
	var mobile := MobileUI.is_mobile()
	_close_btn.visible = mobile
	_close_btn.custom_minimum_size = Vector2(MobileUI.MIN_TOUCH * 1.6, MobileUI.MIN_TOUCH) if mobile else Vector2.ZERO


## A runtime UI-mode switch (pause > Settings > Controls) changes the Theme, the card size, the
## column count and which affordances exist, so the whole panel is re-themed and rebuilt. Cards are
## re-sized by `refresh()`, which calls `ItemCard.set_item` and therefore re-reads `card_size()`.
func _on_platform_mode_changed(_mobile: bool) -> void:
	MobileUI.apply_theme(self)
	_apply_close_button()
	_build_tabs()
	_build_hints()
	_hints.visible = not MobileUI.is_mobile()
	_apply_layout()
	if is_open:
		refresh()
		_show_details(_selected)


## Header height / first body row, per front end (mobile type is 1.2x, so the title needs more).
func _header_h() -> float:
	return HEADER_H_MOBILE if MobileUI.is_mobile() else HEADER_H


func _body_y() -> float:
	return BODY_Y_MOBILE if MobileUI.is_mobile() else BODY_Y


## Pitch of one grid row (card height + the GridContainer's v_separation).
func _row_pitch() -> float:
	return ItemCard.card_size().y + CARD_GAP

## How many WHOLE rows the grid well shows. Never returns a number that would clip a card.
func _visible_rows() -> int:
	var inner := _body_h - WELL_INSET * 2.0 - GRID_PAD * 2.0
	return maxi(1, int(floor((inner + CARD_GAP) / _row_pitch())))

func _total_rows() -> int:
	return int(ceil(float(_entries.size()) / float(_columns)))

## Chooses the panel box for the current window and then trims the grid well DOWN to a whole number
## of card rows, so a partially-visible card is impossible at rest (integration critic, blocking #1).
func _measure_layout() -> void:
	var mobile := MobileUI.is_mobile()
	var vp := get_viewport_rect().size
	var inset: Vector2 = VIEWPORT_INSET_MOBILE if mobile else VIEWPORT_INSET
	var sa := MobileUI.safe_area()
	var max_w: float = PANEL_W_MOBILE if mobile else PANEL_W
	var h := clampf(vp.y - inset.y - sa.y - sa.w, PANEL_H_MIN, PANEL_H_MAX)
	_panel_size = Vector2(minf(max_w, maxf(720.0, vp.x - inset.x - sa.x - sa.z)), h)
	# The grid takes whatever the details column does not, and the column count follows from the
	# card size - so a bigger mobile card simply means fewer, larger columns rather than a
	# hand-maintained second set of numbers.
	var details_w: float = DETAILS_W_MOBILE if mobile else DETAILS_W
	_grid_w = _panel_size.x - MARGIN * 2.0 - details_w - 18.0
	var card := ItemCard.card_size()
	var inner := _grid_w - WELL_INSET * 2.0 - GRID_PAD * 2.0 - SCROLLBAR_W + CARD_GAP
	_columns = maxi(1, int(floor(inner / (card.x + CARD_GAP))))
	# Room between the header and the hint strip (which is desktop-only, see `_build_hints`).
	var head: float = BODY_Y_MOBILE if mobile else BODY_Y
	var hint: float = 0.0 if mobile else HINT_H
	var avail := _panel_size.y - head - hint - 22.0 - 16.0
	var rows := maxi(1, int(floor((avail - WELL_INSET * 2.0 - GRID_PAD * 2.0 + CARD_GAP) / _row_pitch())))
	_body_h = float(rows) * _row_pitch() - CARD_GAP + WELL_INSET * 2.0 + GRID_PAD * 2.0
	if mobile:
		# Keep the full height: the well stays trimmed to whole rows (integration critic, blocking
		# #1) but the details column takes everything, because a phone-sized card leaves the grid
		# short and the details tall.
		_panel_size.y = maxf(head + _body_h + 16.0 + hint + 22.0, h)
		_details_h = _panel_size.y - head - 16.0 - hint - 22.0
	else:
		# Give the leftovers back to the panel so nothing sits in dead space below the grid.
		_panel_size.y = head + _body_h + 16.0 + hint + 22.0
		_details_h = _body_h

func _build() -> void:
	_backdrop = ColorRect.new()
	_backdrop.name = "Backdrop"
	_backdrop.color = UIStyle.BACKDROP
	_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_backdrop)

	_panel = Panel.new()
	_panel.name = "Panel"
	_panel.theme_type_variation = "Modal"
	UIStyle.center_control(_panel, _panel_size, _safe_centre_offset())
	add_child(_panel)

	# header
	var header := HBoxContainer.new()
	header.name = "Header"
	header.position = Vector2(MARGIN, 24.0)
	header.size = Vector2(_panel_size.x - MARGIN * 2.0, _header_h())
	header.add_theme_constant_override("separation", 14)
	_panel.add_child(header)
	var title_box := VBoxContainer.new()
	title_box.add_theme_constant_override("separation", -6)
	title_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(title_box)
	_title_label = UIStyle.make_label(_hook_title(), "Title")
	title_box.add_child(_title_label)
	_subtitle_label = UIStyle.make_label("", "Soft")
	_subtitle_label.visible = false
	title_box.add_child(_subtitle_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(spacer)
	_tab_row = HBoxContainer.new()
	_tab_row.name = "Tabs"
	_tab_row.add_theme_constant_override("separation", 6)
	_tab_row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(_tab_row)
	_header_right = HBoxContainer.new()
	_header_right.add_theme_constant_override("separation", 10)
	_header_right.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(_header_right)
	# MOBILE (R2.10: "must not need a mouse", and there is no Esc key on a phone). A close button
	# in the header is the panel's own exit; on desktop the hint strip's "Esc Close" still says it.
	# Built in BOTH modes and hidden on desktop, so a runtime UI-mode switch has one to show.
	_close_btn = UIStyle.make_button("Close", "Pill")
	_close_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_close_btn.pressed.connect(close_panel)
	header.add_child(_close_btn)
	_apply_close_button()
	_build_tabs()

	# grid well
	_well = PanelContainer.new()
	_well.name = "GridWell"
	_well.theme_type_variation = "GridWell"
	_well.position = Vector2(MARGIN, _body_y())
	_well.size = Vector2(_grid_w, _body_h)
	_well.clip_contents = true
	_panel.add_child(_well)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	# AUTO, not SHOW_ALWAYS: a full-height grabber on a shop that fits is noise. GRID_W carries
	# enough slack (5 * 112 + 4 * 12 + insets + 10) that the bar appearing never squeezes a column.
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	# follow_focus scrolls by the minimum needed to reveal a card, which lands the well on arbitrary
	# offsets and leaves a sliver of the row above. `_snap_scroll_to` moves in whole rows instead.
	_scroll.follow_focus = false
	_well.add_child(_scroll)
	var bar := _scroll.get_v_scroll_bar()
	bar.custom_minimum_size = Vector2(10.0, 0.0)
	bar.value_changed.connect(func(_v: float) -> void: _update_scroll_affordance())
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", int(GRID_PAD))
	pad.add_theme_constant_override("margin_right", int(GRID_PAD))
	pad.add_theme_constant_override("margin_top", int(GRID_PAD))
	pad.add_theme_constant_override("margin_bottom", int(GRID_PAD))
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(pad)
	_grid = GridContainer.new()
	_grid.name = "Grid"
	_grid.columns = _columns
	pad.add_child(_grid)
	_build_scroll_affordance()
	_empty_box = VBoxContainer.new()
	_empty_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_empty_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_empty_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_empty_box.add_theme_constant_override("separation", 6)
	_well.add_child(_empty_box)
	var empty_star := StarIcon.new()
	empty_star.icon_size = 44.0
	empty_star.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	empty_star.modulate = Color(1, 1, 1, 0.7)
	_empty_box.add_child(empty_star)
	var copy := _hook_empty_text()
	_empty_title = UIStyle.make_label(copy[0], "Header", HORIZONTAL_ALIGNMENT_CENTER)
	_empty_box.add_child(_empty_title)
	_empty_sub = UIStyle.make_label(copy[1] if copy.size() > 1 else "", "Soft", HORIZONTAL_ALIGNMENT_CENTER)
	_empty_box.add_child(_empty_sub)
	_empty_box.visible = false

	# details column
	_details = PanelContainer.new()
	_details.name = "Details"
	_details.theme_type_variation = "Inset"
	_details.position = Vector2(MARGIN + _grid_w + 18.0, _body_y())
	_details.size = Vector2(_panel_size.x - MARGIN * 2.0 - _grid_w - 18.0, _details_h)
	_panel.add_child(_details)
	_details_box = VBoxContainer.new()
	_details_box.add_theme_constant_override("separation", 8)
	_details.add_child(_details_box)
	_detail_glyph = ItemGlyph.new()
	# Deliberately SMALLER on mobile than on desktop: the type, the tag and both action buttons are
	# all 1.2x, and the glyph is the one thing in the column that can give the room back.
	_detail_glyph.custom_minimum_size = Vector2(DETAIL_GLYPH_MOBILE, DETAIL_GLYPH_MOBILE) if MobileUI.is_mobile() else Vector2(124.0, 124.0)
	_detail_glyph.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_details_box.add_child(_detail_glyph)
	_detail_name = UIStyle.make_label("", "Header", HORIZONTAL_ALIGNMENT_CENTER)
	_detail_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_name.max_lines_visible = 2
	_details_box.add_child(_detail_name)
	_detail_tag = PanelContainer.new()
	_detail_tag.theme_type_variation = "Tag"
	_detail_tag.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_detail_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_detail_tag_label = UIStyle.make_label("", "OnBlueSmall", HORIZONTAL_ALIGNMENT_CENTER)
	_detail_tag.add_child(_detail_tag_label)
	_details_box.add_child(_detail_tag)
	_detail_desc = RichTextLabel.new()
	_detail_desc.theme_type_variation = "SoftText"
	_detail_desc.bbcode_enabled = false
	_detail_desc.fit_content = true
	_detail_desc.scroll_active = false
	_detail_desc.custom_minimum_size = Vector2(0.0, DETAIL_DESC_MOBILE if MobileUI.is_mobile() else 84.0)
	_detail_desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_detail_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_details_box.add_child(_detail_desc)
	_detail_extra = HBoxContainer.new()
	_detail_extra.alignment = BoxContainer.ALIGNMENT_CENTER
	_detail_extra.add_theme_constant_override("separation", 6)
	_details_box.add_child(_detail_extra)
	var fill := Control.new()
	fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_details_box.add_child(fill)
	_actions_box = VBoxContainer.new()
	_actions_box.add_theme_constant_override("separation", 10)
	_details_box.add_child(_actions_box)
	_details_empty = UIStyle.make_label("Pick something to see its details.", "Soft", HORIZONTAL_ALIGNMENT_CENTER)
	_details_empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_details_empty.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_details_empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_details_empty.visible = false
	_details.add_child(_details_empty)

	# hints
	_hints = HBoxContainer.new()
	_hints.name = "Hints"
	_hints.position = Vector2(MARGIN, _panel_size.y - HINT_H - 22.0)
	_hints.size = Vector2(_panel_size.x - MARGIN * 2.0, HINT_H)
	_hints.add_theme_constant_override("separation", 22)
	_panel.add_child(_hints)
	_build_hints()

	_confirm = ConfirmPopup.new()
	_confirm.name = "Confirm"
	add_child(_confirm)

## The "N more below" chip: with the well trimmed to whole rows there is no half-card left to hint
## that the list continues, so the panel says so out loud (the scrollbar alone was the thing the
## critic could not see). It lives on the Panel rather than inside the GridWell, because a
## PanelContainer stretches every child to fill it — which blew the chip up to the whole well.
func _build_scroll_affordance() -> void:
	_well_overlay = Control.new()
	_well_overlay.name = "WellOverlay"
	_well_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_well_overlay)
	_more_pill = PanelContainer.new()
	_more_pill.name = "MorePill"
	_more_pill.theme_type_variation = "Badge"
	_more_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_more_pill.visible = false
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_more_pill.add_child(row)
	_more_label = UIStyle.make_label("", "Badge")
	row.add_child(_more_label)
	_well_overlay.add_child(_more_pill)

## First fully-visible row for the current scroll offset.
func _first_visible_row() -> int:
	return maxi(0, int(round(float(_scroll.scroll_vertical) / _row_pitch())))

## Repositions the "N more below" chip for the current scroll offset. The chip STRADDLES the well's
## bottom border, in the gap between the well and the hint strip, so it can never sit on top of a
## card's price the way a chip placed inside the well did.
func _update_scroll_affordance() -> void:
	if _more_pill == null or _well == null:
		return
	_well_overlay.position = _well.position
	_well_overlay.size = _well.size
	var bar_w: float = _scroll.get_v_scroll_bar().size.x if _scroll.get_v_scroll_bar().visible else 0.0
	var w := _well.size.x - WELL_INSET * 2.0 - bar_w
	var first := _first_visible_row()
	var hidden := maxi(0, _entries.size() - (first + _visible_rows()) * _columns)
	_more_pill.visible = hidden > 0
	if _more_pill.visible:
		_more_label.text = "%d more below" % hidden
		_more_pill.reset_size()
		_more_pill.position = Vector2(WELL_INSET + (w - _more_pill.size.x) * 0.5,
			_well.size.y - _more_pill.size.y * 0.5)

func _build_tabs() -> void:
	for c in _tab_row.get_children():
		c.queue_free()
	_tabs.clear()
	_tab_ids.clear()
	var tabs := _hook_tabs()
	if tabs.is_empty():
		_tab_row.visible = false
		return
	_tab_row.visible = true
	# The [Q] / [R] glyphs around the tabs name keys a phone does not have; on mobile the tabs are
	# simply tapped.
	var show_keys := not MobileUI.is_mobile()
	var prev := KeyGlyph.new()
	prev.set_action("rotate_left")
	prev.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	prev.visible = show_keys
	_tab_row.add_child(prev)
	for i in tabs.size():
		var t: Array = tabs[i]
		_tab_ids.append(str(t[0]))
		var b := Button.new()
		b.text = str(t[1])
		b.theme_type_variation = "Tab"
		b.focus_mode = Control.FOCUS_NONE
		if MobileUI.is_mobile():
			b.custom_minimum_size = Vector2(MobileUI.MIN_TOUCH * 1.3, MobileUI.MIN_TOUCH)
		b.pressed.connect(func() -> void: set_tab(i))
		_tab_row.add_child(b)
		_tabs.append(b)
	var next := KeyGlyph.new()
	next.set_action("rotate_right")
	next.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	next.visible = show_keys
	_tab_row.add_child(next)
	_update_tab_visuals()

## The keyboard hint strip is DESKTOP-ONLY (R2.10) - every entry in it is a key glyph. On mobile
## the header's close button replaces the one hint that mattered ("Esc Close"), and `_measure_layout`
## gives the freed height back to the grid.
func _build_hints() -> void:
	for c in _hints.get_children():
		c.queue_free()
	if MobileUI.is_mobile():
		_hints.visible = false
		return
	for h in _hook_hints():
		var pair := HBoxContainer.new()
		pair.add_theme_constant_override("separation", 6)
		# h[0] is one action name or an Array of them (e.g. [Q][R] Switch tab).
		var actions: Array = h[0] if h[0] is Array else [h[0]]
		for a in actions:
			var g := KeyGlyph.new()
			g.set_action(str(a))
			g.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			pair.add_child(g)
		var l := UIStyle.make_label(str(h[1]), "Hint")
		pair.add_child(l)
		_hints.add_child(pair)

# ----------------------------------------------------------------------------- open / close
## Opens the panel (idempotent). Subclasses wrap this with their own open() signature.
func open_panel() -> void:
	if is_open:
		refresh()
		return
	is_open = true
	visible = true
	_cooldown = 0.2
	_repeat.reset()
	_nav_state = NavState.GRID
	_apply_layout()
	EventBus.ui_modal_opened.emit(_modal_name)
	UIStyle.play_open()
	_backdrop.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(_backdrop, "modulate:a", 1.0, 0.22)
	UIStyle.pop_in(_panel)
	refresh()

## Closes the panel and emits closed.
func close_panel() -> void:
	if not is_open:
		return
	is_open = false
	EventBus.ui_modal_closed.emit(_modal_name)
	UIStyle.play_close()
	var t := create_tween()
	t.tween_property(_backdrop, "modulate:a", 0.0, 0.18)
	var p := UIStyle.pop_out(_panel)
	p.chain().tween_callback(func() -> void:
		if not is_open:
			visible = false)
	closed.emit()

func current_tab_id() -> String:
	return _tab_ids[_tab] if _tab >= 0 and _tab < _tab_ids.size() else ""

## Switches tab (wraps) and rebuilds the grid.
func set_tab(i: int) -> void:
	if _tab_ids.is_empty():
		return
	var ni := posmod(i, _tab_ids.size())
	if ni != _tab:
		UIStyle.play_tick()
	_tab = ni
	_update_tab_visuals()
	_selected = 0
	_nav_state = NavState.GRID
	_scroll.scroll_vertical = 0
	refresh()

func set_tab_by_id(id: String) -> void:
	var i := _tab_ids.find(id)
	set_tab(i if i >= 0 else 0)

func _update_tab_visuals() -> void:
	for i in _tabs.size():
		_tabs[i].theme_type_variation = "TabActive" if i == _tab else "Tab"

## Re-measures for the current window and moves every fixed-position block. Connected to the
## viewport's size_changed so the panel stays row-exact when the game is resized mid-session.
func _apply_layout() -> void:
	if _panel == null:
		return
	_measure_layout()
	UIStyle.center_control(_panel, _panel_size, _safe_centre_offset())
	var header := _panel.get_node_or_null("Header") as Control
	if header != null:
		header.size = Vector2(_panel_size.x - MARGIN * 2.0, _header_h())
	_well.position = Vector2(MARGIN, _body_y())
	_well.size = Vector2(_grid_w, _body_h)
	_grid.columns = _columns
	_details.position = Vector2(MARGIN + _grid_w + 18.0, _body_y())
	_details.size = Vector2(_panel_size.x - MARGIN * 2.0 - _grid_w - 18.0, _details_h)
	_hints.position = Vector2(MARGIN, _panel_size.y - HINT_H - 22.0)
	_hints.size = Vector2(_panel_size.x - MARGIN * 2.0, HINT_H)
	if is_open:
		_snap_scroll_to(_selected, true)
	_update_scroll_affordance()

## Scrolls in WHOLE ROWS so the well never rests on a partial card. `instant` skips the tween
## (used when the panel opens or the window is resized).
func _snap_scroll_to(index: int, instant: bool = false) -> void:
	if _scroll == null or _entries.is_empty():
		return
	var pitch := _row_pitch()
	var vis := _visible_rows()
	var rows := _total_rows()
	var row: int = maxi(0, index) / _columns
	var first := _first_visible_row()
	first = clampi(first, row - vis + 1, row)
	first = clampi(first, 0, maxi(0, rows - vis))
	var target := int(round(float(first) * pitch))
	if _scroll_tween != null and _scroll_tween.is_valid():
		_scroll_tween.kill()
	if instant or absi(target - _scroll.scroll_vertical) < 2:
		_scroll.scroll_vertical = target
		_update_scroll_affordance()
		return
	_scroll_tween = create_tween()
	_scroll_tween.tween_property(_scroll, "scroll_vertical", target, SCROLL_TWEEN) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _queue_refresh() -> void:
	if not is_open or _refresh_queued:
		return
	_refresh_queued = true
	call_deferred("_deferred_refresh")

func _deferred_refresh() -> void:
	_refresh_queued = false
	if is_open:
		refresh()

## Rebuilds the grid from _hook_entries and re-selects.
func refresh() -> void:
	_entries = _hook_entries(current_tab_id())
	for i in _entries.size():
		var card: ItemCard
		if i < _cards.size():
			card = _cards[i]
		else:
			card = ItemCard.new()
			card.grid_index = i
			card.pressed.connect(_on_card_pressed.bind(card))
			card.focus_entered.connect(_on_card_focus.bind(card))
			_grid.add_child(card)
			_cards.append(card)
		card.grid_index = i
		card.visible = true
		card.set_selected(false)
		var e := _entries[i]
		card.set_item(e["def"], int(e.get("count", 1)))
		_hook_decorate_card(card, e)
	for i in range(_entries.size(), _cards.size()):
		_cards[i].visible = false
	_empty_box.visible = _entries.is_empty()
	if _entries.is_empty():
		_selected = -1
		_nav_state = NavState.GRID
		_show_details(-1)
		_update_scroll_affordance()
		return
	_selected = clampi(_selected, 0, _entries.size() - 1)
	_select(_selected)
	_update_scroll_affordance()

# ----------------------------------------------------------------------------- selection / details
func _select(i: int) -> void:
	if i < 0 or i >= _entries.size():
		return
	if _selected >= 0 and _selected < _cards.size():
		_cards[_selected].set_selected(false)
	_selected = i
	var card := _cards[i]
	_snap_scroll_to(i)
	if _nav_state == NavState.GRID:
		UIFocus.focus(card)
	else:
		card.set_selected(true)
	_show_details(i)

func _show_details(i: int) -> void:
	var has := i >= 0 and i < _entries.size()
	_details_box.visible = has
	_details_empty.visible = not has
	for b in _action_buttons:
		b.queue_free()
	_action_buttons.clear()
	if not has:
		return
	var e := _entries[i]
	var def: Dictionary = e["def"]
	_detail_glyph.set_def(def)
	_detail_name.text = str(def.get("name", UIStyle.pretty_id(str(e["id"]))))
	var rarity := str(def.get("rarity", "common"))
	_detail_tag_label.text = rarity.capitalize()
	var tag_color: Color = UIStyle.RARITY_COLORS.get(rarity, UIStyle.NAME_BLUE)
	_detail_tag.add_theme_stylebox_override("panel", UIStyle.make_pill_style(tag_color, tag_color.darkened(0.15), 0, 0, 12.0, 2.0))
	_detail_desc.text = str(def.get("desc", ""))
	for c in _detail_extra.get_children():
		c.queue_free()
	_hook_fill_extra(_detail_extra, e)
	var actions := _hook_actions(e)
	# (buttons are added below; `_fit_details` runs after them)
	for a in actions:
		var ad: Dictionary = a
		var b := UIStyle.make_button(str(ad.get("label", "")), "PillPrimary" if bool(ad.get("primary", false)) else "Pill")
		b.size_flags_horizontal = Control.SIZE_FILL
		if MobileUI.is_mobile():
			b.custom_minimum_size = Vector2(0.0, MobileUI.MIN_TOUCH)
		if bool(ad.get("disabled", false)):
			b.disabled = true
			b.focus_mode = Control.FOCUS_NONE
		var aid := str(ad.get("id", ""))
		b.pressed.connect(func() -> void: _do_action(aid))
		b.focus_entered.connect(func() -> void: _on_action_focus(b))
		_actions_box.add_child(b)
		_action_buttons.append(b)
	_fit_details()


## MOBILE: keeps the details column inside its own box.
##
## The mobile Theme is 1.2x and every action button is a thumb-sized 88 px, so on a SHORT column -
## a narrow viewport running `--ui=mobile`, or a phone with a big safe-area inset - the stack
## overflowed and the last button was drawn off the bottom of the panel. Rather than hand-tune a
## second set of constants per viewport, the column is measured and the two least important
## minimums (the description, then the swatch) give the room back. Nothing is ever clipped.
func _fit_details() -> void:
	if not MobileUI.is_mobile() or _details_box == null:
		return
	_detail_desc.custom_minimum_size.y = DETAIL_DESC_MOBILE
	_detail_glyph.custom_minimum_size = Vector2(DETAIL_GLYPH_MOBILE, DETAIL_GLYPH_MOBILE)
	# The "Inset" stylebox carries an 18 px content margin on each side.
	var budget := _details_h - 40.0
	var over := _details_box.get_combined_minimum_size().y - budget
	if over <= 0.0:
		return
	var take := minf(over, DETAIL_DESC_MOBILE)
	_detail_desc.custom_minimum_size.y = DETAIL_DESC_MOBILE - take
	over = _details_box.get_combined_minimum_size().y - budget
	if over <= 0.0:
		return
	_detail_glyph.custom_minimum_size = Vector2.ONE * maxf(DETAIL_GLYPH_MOBILE_MIN,
		DETAIL_GLYPH_MOBILE - over)

func _on_card_focus(card: ItemCard) -> void:
	if not is_open:
		return
	if _nav_state == NavState.ACTIONS:
		_leave_actions(false)
	if card.grid_index != _selected:
		_select(card.grid_index)

func _on_card_pressed(card: ItemCard) -> void:
	if not is_open:
		return
	if card.grid_index != _selected:
		_select(card.grid_index)
	_enter_actions()

func _on_action_focus(b: Button) -> void:
	var idx := _action_buttons.find(b)
	if idx >= 0:
		_action_index = idx
		if _nav_state != NavState.ACTIONS:
			_nav_state = NavState.ACTIONS
			if _selected >= 0 and _selected < _cards.size():
				_cards[_selected].set_selected(true)

func _enter_actions() -> void:
	if _selected < 0 or _selected >= _cards.size():
		return
	var first := _first_enabled_action()
	if first < 0:
		_cards[_selected].wobble()
		UIStyle.play_cancel()
		return
	_nav_state = NavState.ACTIONS
	_action_index = first
	_cards[_selected].set_selected(true)
	UIStyle.play_confirm()
	UIFocus.focus(_action_buttons[first])

## Index of the first action button the player can actually press, or -1 when there is none.
func _first_enabled_action() -> int:
	for i in _action_buttons.size():
		if not _action_buttons[i].disabled:
			return i
	return -1

## Next selectable action in `step` direction, skipping disabled buttons.
func _next_enabled_action(from: int, step: int) -> int:
	var i := from
	for _n in _action_buttons.size():
		i = UIFocus.list_move(i, _action_buttons.size(), step)
		if i < 0:
			return from
		if not _action_buttons[i].disabled:
			return i
	return from

func _leave_actions(refocus: bool = true) -> void:
	_nav_state = NavState.GRID
	if _selected >= 0 and _selected < _cards.size():
		_cards[_selected].set_selected(false)
		if refocus:
			UIFocus.focus(_cards[_selected])

func _do_action(action_id: String) -> void:
	if _selected < 0 or _selected >= _entries.size():
		return
	_hook_action(_entries[_selected], action_id)

func selected_entry() -> Dictionary:
	return _entries[_selected] if _selected >= 0 and _selected < _entries.size() else {}

# ----------------------------------------------------------------------------- input
func _process(delta: float) -> void:
	if not is_open or _confirm.is_open():
		return
	_cooldown -= delta
	if _cooldown > 0.0:
		return
	var step := _repeat.poll(delta)
	match _nav_state:
		NavState.GRID:
			if step != Vector2i.ZERO and not _entries.is_empty():
				var ni := UIFocus.grid_move(_selected, _entries.size(), _columns, step)
				if ni != _selected:
					_select(ni)
			if UIFocus.prev_tab_pressed():
				set_tab(_tab - 1)
			elif UIFocus.next_tab_pressed():
				set_tab(_tab + 1)
			if UIFocus.accept_pressed():
				if _entries.is_empty():
					UIStyle.play_cancel()
				else:
					_enter_actions()
			elif UIFocus.cancel_pressed():
				close_panel()
		NavState.ACTIONS:
			_action_index = clampi(_action_index, 0, maxi(0, _action_buttons.size() - 1))
			if step.y != 0 and not _action_buttons.is_empty():
				_action_index = _next_enabled_action(_action_index, step.y)
				UIFocus.focus(_action_buttons[_action_index])
			elif step.x < 0:
				_leave_actions()
			if UIFocus.accept_pressed() and not _action_buttons.is_empty() \
					and not _action_buttons[_action_index].disabled:
				_action_buttons[_action_index].pressed.emit()
			elif UIFocus.cancel_pressed():
				UIStyle.play_cancel()
				_leave_actions()

func _input(event: InputEvent) -> void:
	if is_open:
		UIFocus.consume_nav_event(self, event)

# ----------------------------------------------------------------------------- test hooks
## Taps a grid card / an action button / a tab / the mobile close button the way a FINGER does -
## a real InputEventMouseButton at the control's own centre, which is exactly what Godot's
## touch-to-mouse emulation delivers on a phone. Used by tests/director/ui_mobile_*.json to prove
## the panels are usable with no keyboard and no mouse.
func debug_tap_card(i: int) -> void:
	if i >= 0 and i < _cards.size() and _cards[i].visible:
		MobileUI.synth_tap(_cards[i].get_global_rect().get_center())


func debug_tap_action(i: int) -> void:
	if i >= 0 and i < _action_buttons.size():
		MobileUI.synth_tap(_action_buttons[i].get_global_rect().get_center())


func debug_tap_tab(i: int) -> void:
	if i >= 0 and i < _tabs.size():
		MobileUI.synth_tap(_tabs[i].get_global_rect().get_center())


func debug_tap_close() -> void:
	if _close_btn != null:
		MobileUI.synth_tap(_close_btn.get_global_rect().get_center())


## One-line state dump for a timeline to assert against.
func debug_report(tag: String = "") -> void:
	print("PANEL %s open=%s mobile=%s cols=%d rows_vis=%d entries=%d panel=%.0fx%.0f card=%.0fx%.0f sel=%d" % [
		tag, str(is_open), str(MobileUI.is_mobile()), _columns, _visible_rows(), _entries.size(),
		_panel_size.x, _panel_size.y, ItemCard.card_size().x, ItemCard.card_size().y, _selected])


# ----------------------------------------------------------------------------- helpers
## Catalog definition with a friendly fallback for unregistered ids.
## The fallback is never a grey swatch: ItemGlyph infers a category and a warm colour from the id
## keywords ("deco_moon_lamp" -> lights, "deco_crater_bench" -> furniture, "deco_star_flag" -> signs),
## so an item that lands before its catalog entry still reads as itself.
static func def_for(id: String) -> Dictionary:
	var d := Catalog.get_item(id)
	if d.is_empty():
		var kind := "decoration" if id.begins_with("deco_") else "collectible"
		if id.begins_with("suit_") or id.begins_with("hat_") or id.begins_with("pack_"):
			kind = "clothing"
		d = {"id": id, "name": UIStyle.pretty_id(id), "kind": kind,
			"category": ItemGlyph.category_for_id(id), "rarity": "common",
			"price": 0, "desc": "", "icon_color": ItemGlyph.fallback_color(id)}
	return d
