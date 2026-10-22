class_name JournalPanel
extends Control
## The favour log — "what did I agree to, and where do I find it?".
##
## One cream modal listing every active favour: who asked, what they want, how far along you are,
## and **where the thing actually is**. The last line is the point: Zorp asks for Stardust Shards
## and Stardust Shards do not grow on Zorp, so the row says "Found on Little Orbit, Starport Plaza"
## and the errand becomes a reason to fly home instead of a mystery.
##
## Opened from the pause menu's "Favours" entry:
##
##   JournalPanel.open_over(pause_menu)      # closes the pause menu, reopens it on the way back
##   JournalPanel.open_over(town_hall)       # or from anywhere else — a bulletin board, an NPC
##
## Rows come from `Journal.entries()` (src/onboarding/journal.gd). With no favours the panel turns
## into a little field guide of what grows where, so it is useful on day one too.
##
## SETS PAGE (docs/SETS_SPEC.md 5): a second tab. One card per furniture set (src/decorations/deco_sets.gd):
## who it belongs to, n/6, every piece ticked when ever collected and greyed when not, the bonus as "???"
## until earned, the matching outfit, and one line saying where pieces come from. `open_over(src, "sets")`
## opens straight onto it; the left/right keys (or a tap on the tab) switch pages.

signal closed

const DecoSets := preload("res://src/decorations/deco_sets.gd")
const PAGE_FAVOURS := "favours"
const PAGE_SETS := "sets"
## SETS_SPEC 5: touch targets of at least 48 dp. Desktop 48 px at 1280x720; mobile uses MobileUI.MIN_TOUCH.
const TAB_MIN_H := 48.0
const TICK := 20.0

const PANEL_WIDTH := 760.0
## MOBILE (R2.10): a wider panel, because the mobile Theme sets every string 1.2x and the favour
## rows are already two columns wide.
const PANEL_WIDTH_MOBILE := 980.0
const BODY_HEIGHT := 450.0
const CARD_GLYPH := 54.0
const BAR_H := 12.0
const SCROLL_STEP := 34.0
## Field-guide row: icon size and the width reserved for the material's name.
const GUIDE_GLYPH := 34.0
const GUIDE_NAME_W := 190.0
const MODAL_NAME := "journal"
const NODE_NAME := "JournalPanel"

var is_open := false

var _backdrop: ColorRect
var _panel: PanelContainer
var _subtitle: Label
var _scroll: ScrollContainer
var _well: PanelContainer
var _list: VBoxContainer
var _close_button: Button
var _repeat := UIFocus.NavRepeat.new()
var _cooldown := 0.0
## The pause menu to reopen when the log closes. Typed Node, NOT PauseMenu: pause_menu.gd refers to
## JournalPanel, and naming PauseMenu back would make a class_name cycle that leaves BOTH scripts
## (and, oddly, ItemGlyph) invalid at runtime. Duck-typed instead.
var _reopen_pause: Node
var _paused_tree := false
var page := PAGE_FAVOURS
var _title: Label
var _tab_favours: Button
var _tab_sets: Button


# ============================================================================= entry point
## Opens the log over `source`. When `source` is the pause menu it is closed first and reopened
## when the log closes, so "Favours" reads as a sub-page rather than a second stacked menu.
static func open_over(source: Node, start_page: String = PAGE_FAVOURS) -> JournalPanel:
	if source == null or not source.is_inside_tree():
		return null
	# Always live under the HUD's CanvasLayer when there is one. A caller such as a Town Hall
	# bulletin board is a Node3D, and a Control parented to a Node3D never draws.
	var host: Node = source.get_tree().root.get_node_or_null("World/HUD")
	if host == null:
		host = source.get_parent()
	if host == null:
		host = source.get_tree().current_scene
	var panel := host.get_node_or_null(NODE_NAME) as JournalPanel
	if panel == null:
		panel = JournalPanel.new()
		panel.name = NODE_NAME
		host.add_child(panel)
	if panel.is_open:
		return panel
	panel.page = start_page
	if _is_open_pause_menu(source):
		panel._reopen_pause = source
		# Same frame, so the tree never actually resumes between the two menus.
		source.call("close")
		panel.open(true)
	else:
		panel.open(false)
	return panel


## True when `n` is a pause menu that is currently up. Duck-typed for the reason above.
static func _is_open_pause_menu(n: Node) -> bool:
	return n != null and n.has_method("open") and n.has_method("close") \
		and "is_open" in n and bool(n.get("is_open"))


# ============================================================================= build
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# The panel is created in code under the HUD's CanvasLayer, which does not carry a theme (every
	# other HUD child sets its own — see src/ui/hud/hud.tscn). Without this the cream panels, pills
	# and cards fall back to Godot's dark default.
	if theme == null:
		theme = UIStyle.theme()
	# MOBILE (R2.10): bigger type and thumb-sized buttons. Applied before `_build` so every
	# minimum size is measured at the size it is drawn.
	MobileUI.apply_theme(self)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_build()


func _build() -> void:
	_backdrop = ColorRect.new()
	_backdrop.color = UIStyle.BACKDROP
	_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_backdrop)

	_panel = PanelContainer.new()
	_panel.name = "Panel"
	_panel.theme_type_variation = "ModalContainer"
	_panel.custom_minimum_size = Vector2(_panel_width(), 0.0)
	add_child(_panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	_panel.add_child(box)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	box.add_child(head)
	var star := StarIcon.new()
	star.icon_size = 34.0
	star.twinkle = true
	star.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(star)
	var titles := VBoxContainer.new()
	titles.add_theme_constant_override("separation", -6)
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(titles)
	_title = UIStyle.make_label("Favours", "Title")
	titles.add_child(_title)
	_subtitle = UIStyle.make_label("", "Soft")
	titles.add_child(_subtitle)
	# The two pages, as tabs at the right of the header (no extra height for the list).
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	tabs.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(tabs)
	_tab_favours = _make_tab("Favours", PAGE_FAVOURS)
	tabs.add_child(_tab_favours)
	_tab_sets = _make_tab("Sets", PAGE_SETS)
	tabs.add_child(_tab_sets)

	var well := PanelContainer.new()
	_well = well
	well.theme_type_variation = "Inset"
	well.custom_minimum_size = Vector2(0.0, BODY_HEIGHT)
	box.add_child(well)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.follow_focus = true
	well.add_child(_scroll)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 10)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_list)

	# One footer row: the scroll hint on the left of the Back pill, so the list gets the height back.
	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_theme_constant_override("separation", 20)
	box.add_child(footer)
	# The "W/S scroll" glyph is a KEYBOARD hint and is desktop-only (R2.10). On a phone the list is
	# dragged - Godot's ScrollContainer handles InputEventScreenDrag itself - and the pill below is
	# the way out.
	if not MobileUI.is_mobile():
		var pair := HBoxContainer.new()
		pair.add_theme_constant_override("separation", 6)
		var g := KeyGlyph.new()
		g.set_text("LS" if Input.get_connected_joypads().size() > 0 else "W/S")
		g.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		pair.add_child(g)
		pair.add_child(UIStyle.make_label("scroll", "Hint"))
		footer.add_child(pair)
	_close_button = UIStyle.make_button("Back", "PillPrimary", MobileUI.pick(180.0, 260.0))
	# 48 dp minimum on desktop too (SETS_SPEC 5); the pill measured 46 px tall at 1280x720 before.
	_close_button.custom_minimum_size.y = MobileUI.pick(TAB_MIN_H, MobileUI.MIN_TOUCH)
	_close_button.pressed.connect(close)
	footer.add_child(_close_button)


func _make_tab(text: String, which: String) -> Button:
	var b := UIStyle.make_button(text, "Tab", MobileUI.pick(120.0, 190.0))
	b.custom_minimum_size.y = MobileUI.pick(TAB_MIN_H, MobileUI.MIN_TOUCH)
	b.pressed.connect(func() -> void: show_page(which))
	return b


## Switches page (and rebuilds it). Public so a caller or a test can land on the Sets page.
func show_page(which: String) -> void:
	if which != PAGE_SETS:
		which = PAGE_FAVOURS
	if which != page:
		UIStyle.play_tick()
	page = which
	if is_open:
		refresh()
		_scroll.scroll_vertical = 0
		_relayout()


# ============================================================================= open / close
## Shows the log. `pause_tree` freezes the world behind it (true when it came from the pause menu).
func open(pause_tree: bool = false) -> void:
	if is_open:
		return
	is_open = true
	visible = true
	_cooldown = 0.2
	_repeat.reset()
	refresh()
	_paused_tree = pause_tree
	if pause_tree:
		get_tree().paused = true
	EventBus.ui_modal_opened.emit(MODAL_NAME)
	UIStyle.play_open()
	_backdrop.modulate.a = 0.0
	create_tween().tween_property(_backdrop, "modulate:a", 1.0, 0.18)
	_relayout()
	UIStyle.pop_in(_panel)
	UIFocus.focus(_close_button)


func close() -> void:
	if not is_open:
		return
	is_open = false
	if _paused_tree:
		get_tree().paused = false
		_paused_tree = false
	EventBus.ui_modal_closed.emit(MODAL_NAME)
	UIStyle.play_close()
	create_tween().tween_property(_backdrop, "modulate:a", 0.0, 0.14)
	var t := UIStyle.pop_out(_panel)
	t.chain().tween_callback(func() -> void:
		if not is_open:
			visible = false)
	closed.emit()
	if _reopen_pause != null and is_instance_valid(_reopen_pause):
		var pause := _reopen_pause
		_reopen_pause = null
		pause.call("open")


## Panel width for the current front end.
func _panel_width() -> float:
	return MobileUI.pick(PANEL_WIDTH, PANEL_WIDTH_MOBILE)


func _relayout() -> void:
	# The header's 48 dp tabs (88 px on a phone) made the panel 11 px taller than a 2340x1080 phone's 720 px
	# view (measured 2026-10-21). The list well gives the height back so the whole panel always fits.
	_well.custom_minimum_size.y = BODY_HEIGHT
	_panel.reset_size()
	var sa0 := MobileUI.safe_area()
	var room := size.y - sa0.y - sa0.w - 16.0
	if room > 0.0 and _panel.size.y > room:
		_well.custom_minimum_size.y = maxf(200.0, BODY_HEIGHT - (_panel.size.y - room))
	_panel.reset_size()
	# Centred inside the SAFE rectangle, not the raw viewport (see Platform.safe_area_insets).
	var sa := MobileUI.safe_area()
	_panel.position = (size - _panel.size) * 0.5 + Vector2((sa.x - sa.z) * 0.5, (sa.y - sa.w) * 0.5)


# ============================================================================= content
## Rebuilds the current page. Called on every open and on a tab switch.
func refresh() -> void:
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()
	var on_sets := page == PAGE_SETS
	_tab_favours.theme_type_variation = "Tab" if on_sets else "TabActive"
	_tab_sets.theme_type_variation = "TabActive" if on_sets else "Tab"
	_title.text = "Sets" if on_sets else "Favours"
	if on_sets:
		_build_sets_page()
		return
	var rows := Journal.entries()
	var ready := Journal.ready_count()
	if rows.is_empty():
		_subtitle.text = "Nothing promised yet."
		_build_field_guide()
		return
	if rows.size() == 1:
		_subtitle.text = "One favour on the go."
	else:
		_subtitle.text = "%d favours on the go." % rows.size()
	if ready > 0:
		_subtitle.text += "  %d ready to hand in!" % ready
	for r: Dictionary in rows:
		_list.add_child(_make_card(r))


func _make_card(row: Dictionary) -> Control:
	var card := PanelContainer.new()
	card.theme_type_variation = "Card"
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 16)
	card.add_child(body)

	var glyph := ItemGlyph.new()
	glyph.custom_minimum_size = Vector2(CARD_GLYPH, CARD_GLYPH)
	glyph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	glyph.set_item_id(str(row.get("item", "")))
	body.add_child(glyph)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(col)

	# --- who asked, and what for
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	col.add_child(head)
	head.add_child(_name_pill(str(row.get("who", "")), row.get("accent", UIStyle.NAME_BLUE)))
	var title := UIStyle.make_label(str(row.get("title", "")), "")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(title)
	if bool(row.get("ready", false)):
		var badge := PanelContainer.new()
		badge.theme_type_variation = "Badge"
		badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		badge.add_child(UIStyle.make_label("READY", "Badge"))
		head.add_child(badge)

	# --- progress
	var prog := HBoxContainer.new()
	prog.add_theme_constant_override("separation", 10)
	col.add_child(prog)
	prog.add_child(_make_bar(float(row.get("ratio", 0.0)), bool(row.get("ready", false))))
	var count_label := UIStyle.make_label(str(row.get("progress_text", "")), "Small")
	count_label.custom_minimum_size = Vector2(120.0, 0.0)
	prog.add_child(count_label)

	# --- where to find it (the line the critic said was missing)
	var where := UIStyle.make_label(Journal.next_step(row), "Small")
	where.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	where.custom_minimum_size = Vector2(_panel_width() - 220.0, 0.0)
	col.add_child(where)
	return card


func _name_pill(text: String, accent: Color) -> PanelContainer:
	var pill := PanelContainer.new()
	pill.add_theme_stylebox_override("panel",
		UIStyle.make_pill_style(accent, accent.darkened(0.2), 0, 0, 14.0, 2.0))
	pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.add_child(UIStyle.make_label(text, "Badge"))
	return pill


func _make_bar(ratio: float, ready: bool) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.min_value = 0.0
	bar.max_value = 1.0
	bar.value = clampf(ratio, 0.0, 1.0)
	bar.custom_minimum_size = Vector2(240.0, BAR_H)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(UIStyle.TEXT_BROWN, 0.20)
	bg.set_corner_radius_all(int(BAR_H * 0.5))
	var fill := StyleBoxFlat.new()
	fill.bg_color = UIStyle.GREEN_EDGE if ready else UIStyle.YELLOW
	fill.set_corner_radius_all(int(BAR_H * 0.5))
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	return bar


## Day-one view: no favours yet, so show what grows where instead of an empty box.
func _build_field_guide() -> void:
	var intro := UIStyle.make_label("Say hello to a neighbour — they always need a hand.", "")
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_list.add_child(intro)
	_list.add_child(UIStyle.make_label("WHAT GROWS WHERE", "Hint"))
	# One line per material, in their own tight column, so all four fit without scrolling:
	# [icon] Name .... where it grows.
	var guide := VBoxContainer.new()
	guide.add_theme_constant_override("separation", 6)
	guide.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_child(guide)
	for g: Dictionary in Journal.field_guide():
		var card := PanelContainer.new()
		card.theme_type_variation = "Card"
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		card.add_child(row)
		var glyph := ItemGlyph.new()
		glyph.custom_minimum_size = Vector2(GUIDE_GLYPH, GUIDE_GLYPH)
		glyph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		glyph.set_item_id(str(g.get("item", "")))
		row.add_child(glyph)
		var label := UIStyle.make_label(str(g.get("name", "")), "Small")
		label.custom_minimum_size = Vector2(GUIDE_NAME_W, 0.0)
		row.add_child(label)
		var places := UIStyle.make_label(str(g.get("planets", "")), "Hint")
		places.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		places.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		row.add_child(places)
		guide.add_child(card)


# ============================================================================= sets page
func _build_sets_page() -> void:
	var sets: Array = DecoSets.all_sets()
	var done := 0
	var bonus_sets := 0
	var pieces := 0
	for st: Dictionary in sets:
		var sid := str(st["id"])
		pieces += DecoSets.collected_count(sid)
		if str(st.get("bonus", "")) != "":
			bonus_sets += 1
			if DecoSets.bonus_earned(sid):
				done += 1
	_subtitle.text = "%d %s collected · %d of %d neighbour sets complete" % [pieces, "piece" if pieces == 1 else "pieces", done, bonus_sets]
	for st: Dictionary in sets:
		_list.add_child(_make_set_card(st))


func _make_set_card(st: Dictionary) -> Control:
	var sid := str(st["id"])
	var have := DecoSets.collected_count(sid)
	var total := DecoSets.piece_total(sid)
	var card := PanelContainer.new()
	card.theme_type_variation = "Card"
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	card.add_child(col)

	# --- whose set, its name, n/6
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	col.add_child(head)
	head.add_child(_name_pill(str(st.get("giver", "")), _set_accent(st)))
	var title := UIStyle.make_label(str(st.get("name", sid)), "")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	head.add_child(title)
	var complete := total > 0 and have >= total
	var bar := _make_bar(float(have) / float(maxi(1, total)), complete)
	bar.custom_minimum_size.x = MobileUI.pick(150.0, 190.0)
	head.add_child(bar)
	var count := UIStyle.make_label("%d/%d" % [have, total], "Header")
	count.custom_minimum_size = Vector2(MobileUI.pick(64.0, 84.0), 0.0)
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(count)

	# --- every piece: ticked when ever collected, greyed when not; then the bonus, then the outfit
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 14)
	flow.add_theme_constant_override("v_separation", 2)
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(flow)
	var names: Dictionary = st.get("names", {})
	for pid: String in st.get("pieces", []):
		flow.add_child(_chip(str(names.get(pid, UIStyle.pretty_id(pid))), GameState.is_collected(pid)))
	var bonus := str(st.get("bonus", ""))
	if bonus != "":
		var earned := DecoSets.bonus_earned(sid)
		flow.add_child(_chip("Bonus: " + (str(st.get("bonus_name", "")) if earned else "???"), earned, true))
	var outfit: Array = st.get("outfit", [])
	if not outfit.is_empty():
		var bits: PackedStringArray = []
		for cid: String in outfit:
			var d: Dictionary = Catalog.get_item(cid)
			bits.append(str(d.get("name", UIStyle.pretty_id(cid))) + (" (got it)" if GameState.is_collected(cid) else ""))
		var ol := UIStyle.make_label("Outfit: " + ", ".join(bits) + " · Suit-Up", "Hint")
		ol.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ol.custom_minimum_size = Vector2(_panel_width() - 120.0, 0.0)
		col.add_child(ol)

	# --- where the pieces come from
	var where := UIStyle.make_label(str(st.get("where", "")), "Small")
	where.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	where.custom_minimum_size = Vector2(_panel_width() - 120.0, 0.0)
	where.add_theme_color_override("font_color", UIStyle.NAME_BLUE)
	col.add_child(where)
	return card


func _set_accent(st: Dictionary) -> Color:
	var npc := str(st.get("neighbour", ""))
	if npc != "":
		var a := str(NpcData.get_data(npc).get("accent", ""))
		if a != "":
			return Color(a)
	return UIStyle.NAME_BLUE


## One piece: a tick (or an empty ring) and its name, greyed when not collected.
func _chip(text: String, got: bool, star := false) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var t := SetTick.new()
	t.on = got
	t.star = star
	t.custom_minimum_size = Vector2(TICK, TICK) * MobileUI.pick(1.0, 1.2)
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(t)
	var l := UIStyle.make_label(text, "Small")
	if not got:
		l.add_theme_color_override("font_color", Color(UIStyle.TEXT_SOFT, 0.85))
	row.add_child(l)
	return row


## The tick drawn by hand: Baloo 2 is not guaranteed to carry a check-mark glyph.
class SetTick extends Control:
	var on := false
	var star := false

	func _draw() -> void:
		var r := minf(size.x, size.y) * 0.5
		var c := size * 0.5
		if on:
			draw_circle(c, r, UIStyle.YELLOW if star else UIStyle.GREEN_EDGE)
			var pts := PackedVector2Array([c + Vector2(-0.48, 0.02) * r, c + Vector2(-0.14, 0.38) * r,
				c + Vector2(0.50, -0.34) * r])
			draw_polyline(pts, UIStyle.WHITE, maxf(2.0, r * 0.28), true)
		else:
			draw_arc(c, r - 1.5, 0.0, TAU, 24, Color(UIStyle.TEXT_SOFT, 0.7), 2.0, true)
			if star:
				draw_string(UIStyle.font(), c + Vector2(-r * 0.32, r * 0.42), "?", HORIZONTAL_ALIGNMENT_LEFT,
					-1, int(r * 1.3), Color(UIStyle.TEXT_SOFT, 0.9))


# ============================================================================= input
func _process(delta: float) -> void:
	if not is_open:
		return
	_cooldown -= delta
	if _cooldown > 0.0:
		return
	var step := _repeat.poll(delta)
	if step.y != 0:
		_scroll.scroll_vertical += int(SCROLL_STEP * float(step.y))
	if step.x != 0:
		show_page(PAGE_SETS if step.x > 0 else PAGE_FAVOURS)
	if UIFocus.accept_pressed() or UIFocus.cancel_pressed():
		if UIFocus.cancel_pressed():
			UIStyle.play_cancel()
		close()


func _input(event: InputEvent) -> void:
	if is_open:
		UIFocus.consume_nav_event(self, event)
