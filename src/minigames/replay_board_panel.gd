extends Control
## THE GAME BOARD'S LIST: one row per game the board offers, each with Play.
## Opened by replay_board.gd when the player uses the board on the Commons (read that header first).
##
## A modal like every other panel: it announces itself with EventBus.ui_modal_opened / _closed (so the
## player, the touch controls and the HUD all stand down), it does not pause the tree (the shops do
## not either), and it closes on Close, on cancel (Esc, pad B), and when a game is picked.
##
## PHONE FIRST (docs/STYLE_GUIDE.md R2.10). The logical phone viewport is 1560x720, which is 390 points
## tall on an iPhone, so 1 logical px is about 0.54 pt: the game's name is the "Header" type (34 px on
## the mobile theme, about 18 pt), the world line the body size (26 px, about 14 pt), and every button
## is at least MobileUI.MIN_TOUCH (88 px, 8.7 mm) tall. There is no key hint on a phone; Close sits in
## the header, where ItemGridPanel puts its own.
##
## KEYBOARD AND CONTROLLER: the same polled navigation every Astro Neighbor menu uses (UIFocus): up /
## down (and left / right) move through the Play buttons and Close, accept presses the focused one,
## cancel closes. `consume_nav_event` keeps the GUI's own focus navigation from moving twice. A short
## cooldown after opening swallows the very press that opened the board.
##
## THE LIST OPENS AT ITS TOP (round 2). It used to open on its LAST rows with the focused Play out of
## sight (critic, round 1: scroll 260 of 260 on the phone, 133 of 133 on the desktop, every open). The
## cause, measured: the first Play was focused in the frame the list was built, when the scroll box
## was still 0 px tall and the rows unsorted (the first Play at y 585 of the list), so the scroll the
## engine worked out (follow_focus 695 px, then ensure_control_visible 1390) was clamped to the bottom
## a frame later. Now the first Play is focused without scrolling, the list is put at the top once the
## layout is real (`_settle_scroll`), and only keyboard and pad moves after that scroll the list.
## A list that scrolls also LOOKS like one: part of the next row always shows under the last whole one
## (`_relayout`), and the scroll bar is a visible slate pill, not the default hairline.
##
## A DRAG SCROLLS FROM ANY ROW (fix round 1). On a phone only 2.5 of 5 rows show, and a drag that
## began on a row moved the list 0 px (a drag from the gap between rows moved it): each row was a
## PanelContainer, whose default mouse filter STOP kept the press from ever reaching the scroll box.
## The rows and their containers now PASS it on; only the Play buttons stop it, so a tap on Play
## still plays. MEASURED at 1560x720 --ui=mobile, five rows, emulated drags of 100 px (screen touch
## events, and mouse events with touch emulation): from a row's name, its world line, its left margin,
## its top edge, the gap before its Play and the gap between rows, the list moved 100 px under the
## finger (103-147 px once it coasted); before this change all of them moved it 0 px but the gap
## between rows. A drag that starts on Play moves nothing and plays nothing; a tap on Play plays.
##
## WORDS (docs/STYLE_GUIDE.md "Writing", <= 60 characters): nothing here names a key or a finger, so
## the same strings are right on both front ends.

signal play_requested(key: String)
signal closed

const MODAL_NAME := "replay_board"
const PANEL_W := 660.0
const PANEL_W_MOBILE := 940.0
## Tallest the list may grow before it scrolls. `_relayout` trims it so a sliver of the next row shows.
const LIST_MAX_H := 372.0
const LIST_MAX_H_MOBILE := 400.0
## When less than this share of the next row would show under the tallest list, the list is cut half
## a row shorter instead, so the rows below are plainly there.
const MIN_PEEK := 0.3
## The scroll bar's width: the phone's is wide enough to see at arm's length and to drag with a thumb.
const SCROLL_BAR_W := 10.0
const SCROLL_BAR_W_MOBILE := 16.0
const OPEN_COOLDOWN := 0.22

const TEXT_TITLE := "Game board"
const TEXT_SUB := "Pick a game. Your rocket flies you to its world."
const TEXT_EMPTY := "No games on the board yet."

var is_open := false

var _backdrop: ColorRect
var _panel: PanelContainer
var _scroll: ScrollContainer
var _list: VBoxContainer
var _locked_label: Label
var _close_button: Button
var _buttons: Array[Button] = []
var _index := 0
## False from the moment the list is built until its layout has been sorted (see `_settle_scroll`).
var _settled := false
var _cooldown := 0.0
var _repeat := UIFocus.NavRepeat.new()
var _close_tween: Tween


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_backdrop = ColorRect.new()
	_backdrop.name = "Backdrop"
	_backdrop.color = UIStyle.BACKDROP
	_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_backdrop)
	get_viewport().size_changed.connect(func() -> void:
		if is_open:
			_relayout())


# ============================================================================= open / close
## `list` is replay_board.gd `entries()`; `quiet_line` is the one soft line under it ("" for none).
func open(list: Array, quiet_line: String) -> void:
	if is_open:
		return
	if _close_tween != null and _close_tween.is_valid():
		_close_tween.kill()
	_build(list, quiet_line)
	is_open = true
	visible = true
	_cooldown = OPEN_COOLDOWN
	_repeat.reset()
	EventBus.ui_modal_opened.emit(MODAL_NAME)
	UIStyle.play_open()
	_backdrop.modulate.a = 0.0
	create_tween().tween_property(_backdrop, "modulate:a", 1.0, 0.2)
	# Deferred for the reason dev_menu.gd gives: a container tree built this frame has not settled
	# its minimum size yet, and sizing the panel now would size it to a stale layout.
	_panel.modulate.a = 0.0
	call_deferred("_after_open_layout")


func _after_open_layout() -> void:
	if not is_open:
		return
	_relayout()
	UIStyle.pop_in(_panel)
	_settled = false
	_set_index(0)   # focus only: see "THE LIST OPENS AT ITS TOP"
	_settle_scroll()


## Waits for the scroll box to get its real height (one frame, measured), then puts the list at its
## top and lets keyboard and pad moves scroll it from there on.
func _settle_scroll() -> void:
	var sc := _scroll
	if sc == null:
		_settled = true
		return
	for i in 10:
		await get_tree().process_frame
		if not is_open or sc != _scroll or not is_instance_valid(sc):
			return
		if sc.size.y > 0.0:
			break
	sc.scroll_vertical = 0
	_settled = true


func close() -> void:
	if not is_open:
		return
	is_open = false
	EventBus.ui_modal_closed.emit(MODAL_NAME)
	UIStyle.play_close()
	create_tween().tween_property(_backdrop, "modulate:a", 0.0, 0.16)
	_close_tween = UIStyle.pop_out(_panel, 0.16)
	_close_tween.chain().tween_callback(func() -> void:
		if not is_open:
			visible = false)
	closed.emit()


# ============================================================================= build
func _build(list: Array, quiet_line: String) -> void:
	if _panel != null:
		_panel.queue_free()
	_buttons.clear()
	var mobile := MobileUI.is_mobile()

	_panel = PanelContainer.new()
	_panel.name = "Panel"
	_panel.theme_type_variation = "ModalContainer"
	_panel.custom_minimum_size = Vector2(MobileUI.pick(PANEL_W, PANEL_W_MOBILE), 0.0)
	add_child(_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	_panel.add_child(box)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	box.add_child(header)
	var title := UIStyle.make_label(TEXT_TITLE, "Title")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	_close_button = UIStyle.make_button("Close", "Pill")
	_close_button.name = "Close"
	_close_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if mobile:
		_close_button.custom_minimum_size = Vector2(MobileUI.MIN_TOUCH * 1.6, MobileUI.MIN_TOUCH)
	_close_button.pressed.connect(close)
	_close_button.focus_entered.connect(func() -> void: _index = _buttons.find(_close_button))
	if mobile:
		header.add_child(_close_button)

	if not list.is_empty():
		var sub := _soft_label(TEXT_SUB, HORIZONTAL_ALIGNMENT_LEFT)
		box.add_child(sub)
		_scroll = ScrollContainer.new()
		_scroll.name = "Scroll"
		_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		# Off: `_set_index` scrolls to the keyboard / pad focus itself, and only once the layout is real.
		_scroll.follow_focus = false
		_style_scroll_bar(_scroll.get_v_scroll_bar())
		box.add_child(_scroll)
		_list = VBoxContainer.new()
		_list.name = "Rows"
		_list.add_theme_constant_override("separation", 10)
		_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_scroll.add_child(_list)
		for e: Variant in list:
			if e is Dictionary:
				_add_row(e as Dictionary)
	else:
		_scroll = null
		_list = null

	var quiet := quiet_line
	if quiet == "" and list.is_empty():
		quiet = TEXT_EMPTY
	_locked_label = _soft_label(quiet, HORIZONTAL_ALIGNMENT_CENTER)
	_locked_label.name = "Locked"
	_locked_label.visible = quiet != ""
	if list.is_empty():
		# The line alone: give it room so the panel does not read as broken.
		_locked_label.custom_minimum_size.y = MobileUI.pick(90.0, 120.0)
	box.add_child(_locked_label)

	if not mobile:
		var footer := HBoxContainer.new()
		footer.add_theme_constant_override("separation", 18)
		box.add_child(footer)
		for pair: Array in [["interact", "Play"], ["cancel", "Close"]]:
			var hint := HBoxContainer.new()
			hint.add_theme_constant_override("separation", 6)
			var g := KeyGlyph.new()
			g.set_action(str(pair[0]))
			g.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			hint.add_child(g)
			hint.add_child(UIStyle.make_label(str(pair[1]), "Hint"))
			footer.add_child(hint)
		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		footer.add_child(spacer)
		footer.add_child(_close_button)
	_buttons.append(_close_button)


## A finger that lands anywhere on a row but its Play button must scroll the list (see "A DRAG
## SCROLLS FROM ANY ROW"), so every container in the row PASSES pointer events on to the scroll box
## and the labels ignore them (UIStyle.make_label). Only Play keeps STOP, a Button's default.
func _add_row(e: Dictionary) -> void:
	var mobile := MobileUI.is_mobile()
	var row := PanelContainer.new()
	row.name = "Row_" + str(e.get("key", "")).replace(":", "_")
	row.theme_type_variation = "Inset"
	# A PanelContainer defaults to STOP, which ate every drag that began on a row (round 2 critic: 0 px).
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	_list.add_child(row)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	h.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(h)
	var words := VBoxContainer.new()
	words.add_theme_constant_override("separation", -2)
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	words.mouse_filter = Control.MOUSE_FILTER_PASS
	h.add_child(words)
	var name_label := UIStyle.make_label(str(e.get("title", "")), "Header")
	name_label.name = "Name"
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	words.add_child(name_label)
	var world := _soft_label(str(e.get("world", "")), HORIZONTAL_ALIGNMENT_LEFT)
	world.name = "World"
	words.add_child(world)
	var play := UIStyle.make_button("Play", "PillPrimary", MobileUI.pick(132.0, 196.0))
	play.name = "Play"
	play.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if mobile:
		play.custom_minimum_size.y = MobileUI.MIN_TOUCH
	var key := str(e.get("key", ""))
	play.pressed.connect(func() -> void: _on_play(key))
	var at := _buttons.size()
	play.focus_entered.connect(func() -> void: _index = at)
	h.add_child(play)
	_buttons.append(play)


## A slate pill on a faint track, in the panel's own soft text colour.
func _style_scroll_bar(bar: VScrollBar) -> void:
	var w := MobileUI.pick(SCROLL_BAR_W, SCROLL_BAR_W_MOBILE)
	var track := StyleBoxFlat.new()
	track.bg_color = Color(UIStyle.TEXT_SOFT, 0.16)
	track.set_corner_radius_all(UIStyle.RADIUS_PILL)
	track.content_margin_left = w * 0.5
	track.content_margin_right = w * 0.5
	bar.add_theme_stylebox_override("scroll", track)
	bar.add_theme_stylebox_override("scroll_focus", track)
	for state: String in ["grabber", "grabber_highlight", "grabber_pressed"]:
		var grab := StyleBoxFlat.new()
		grab.bg_color = UIStyle.TEXT_SOFT if state == "grabber" else UIStyle.TEXT_BROWN
		grab.set_corner_radius_all(UIStyle.RADIUS_PILL)
		grab.content_margin_left = w * 0.5
		grab.content_margin_right = w * 0.5
		bar.add_theme_stylebox_override(state, grab)
	bar.custom_minimum_size.x = w


## A body-size line in the soft slate: quiet, but big enough to read at arm's length on a phone
## ("Soft" itself is the small size).
func _soft_label(text: String, align: HorizontalAlignment) -> Label:
	var l := UIStyle.make_label(text, "", align)
	l.add_theme_color_override("font_color", UIStyle.TEXT_SOFT)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


func _relayout() -> void:
	if _panel == null:
		return
	if _scroll != null and _list != null:
		var want := _list.get_combined_minimum_size().y
		var cap := MobileUI.pick(LIST_MAX_H, LIST_MAX_H_MOBILE)
		if want > cap and _list.get_child_count() > 0:
			# A list that scrolls shows part of its next row: at 400 px the phone's 124 px rows would
			# end flush with the box and the rows below would look like they are not there.
			var step := (_list.get_child(0) as Control).get_combined_minimum_size().y \
				+ float(_list.get_theme_constant("separation"))
			if step > 1.0 and fmod(cap + float(_list.get_theme_constant("separation")), step) / step < MIN_PEEK:
				cap -= step * 0.5
		_scroll.custom_minimum_size.y = minf(want, cap)
	_panel.reset_size()
	var sa := MobileUI.safe_area()
	_panel.position = (size - _panel.size) * 0.5 + Vector2((sa.x - sa.z) * 0.5, (sa.y - sa.w) * 0.5)
	UIStyle.center_pivot(_panel)


# ============================================================================= input
func _on_play(key: String) -> void:
	if not is_open:
		return
	play_requested.emit(key)


func _set_index(i: int) -> void:
	if _buttons.is_empty():
		return
	_index = clampi(i, 0, _buttons.size() - 1)
	var b := _buttons[_index]
	UIFocus.focus(b)
	if _settled and _scroll != null and b != _close_button:
		# The whole row, not just its button: the game's name is what the player is choosing by, and a
		# button-only scroll left the Play's rim a pixel under the edge (measured, desktop, five rows).
		var row := b.get_parent().get_parent() as Control
		_scroll.ensure_control_visible(row if row != null and _list != null and _list.is_ancestor_of(row) else b)


func _process(delta: float) -> void:
	if not is_open:
		return
	_cooldown -= delta
	if _cooldown > 0.0:
		return
	var step := _repeat.poll(delta)
	var move := step.y if step.y != 0 else step.x
	if move != 0 and not _buttons.is_empty():
		_set_index(posmod(_index + move, _buttons.size()))
	if UIFocus.accept_pressed():
		if _index >= 0 and _index < _buttons.size():
			_buttons[_index].pressed.emit()
	elif UIFocus.cancel_pressed():
		UIStyle.play_cancel()
		close()


func _input(event: InputEvent) -> void:
	if is_open:
		UIFocus.consume_nav_event(self, event)


# ============================================================================= QA
## A REAL press through the input pipeline (MobileUI.synth_tap), on the drawn centre of row `i`'s
## Play button, or of Close with i = -1 - the pixel a finger would touch.
func debug_tap(i: int) -> bool:
	var b: Button = _close_button if i < 0 else (_buttons[i] if i < _buttons.size() - 1 else null)
	if b == null or not b.is_visible_in_tree():
		return false
	if _scroll != null and b != _close_button:
		_scroll.ensure_control_visible(b)
		await get_tree().process_frame
		await get_tree().process_frame
	MobileUI.synth_tap(b.get_global_rect().get_center())
	return true


func debug_layout() -> String:
	var rows := PackedStringArray()
	for b: Button in _buttons:
		rows.append("%s@%s" % [b.text, str(b.get_global_rect())])
	var texts := PackedStringArray()
	if _list != null:
		for r: Node in _list.get_children():
			var n := r.find_child("Name", true, false) as Label
			var w := r.find_child("World", true, false) as Label
			if n != null:
				texts.append("%s | %s | name_px=%d" % [n.text, w.text if w != null else "",
					n.get_theme_font_size("font_size")])
	return "panel=%s scroll=%s locked=%s(%s) buttons=[%s] rows=[%s]" % [
		str(_panel.get_global_rect()) if _panel != null else "none",
		str(_scroll.get_global_rect()) if _scroll != null else "none",
		str(_locked_label.visible) if _locked_label != null else "?",
		_locked_label.text if _locked_label != null else "", ", ".join(rows), "; ".join(texts)]
