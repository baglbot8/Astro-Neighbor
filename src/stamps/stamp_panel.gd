extends Control
## THE STAMPS VIEW (docs/DAILY_STAMPS_SPEC.md 2): today's five tasks with their ticks, this week's
## stamps (Monday to Sunday) and the prize as a silhouette. One cream modal, built in code under the
## HUD's CanvasLayer the way JournalPanel is (src/ui/journal/journal_panel.gd).
##
##   load("res://src/stamps/stamp_panel.gd").open_over(any_node_in_the_world)
##
## Opened from the HUD's stamp chip (src/stamps/stamp_chip.gd) and from Norm's "Show me".
## Cozy rules: nothing here counts down; the only word about time is "New card tomorrow".

signal closed

const StampCard := preload("res://src/stamps/stamp_card.gd")
const StampArt := preload("res://src/stamps/stamp_art.gd")
const LINES_PATH := "res://src/campaign/norm_lines.gd"
const PANEL_WIDTH := 800.0
const PANEL_WIDTH_MOBILE := 1010.0
const MODAL_NAME := "stamps"
const NODE_NAME := "StampPanel"
const DAY_LETTERS: Array[String] = ["M", "T", "W", "T", "F", "S", "S"]
## A dark, flat prize: every colour of the glyph multiplied down to one navy shape.
const SILHOUETTE := Color(0.13, 0.15, 0.24)

var is_open := false

var _backdrop: ColorRect
var _panel: PanelContainer
var _subtitle: Label
var _count: Label
var _tasks_box: VBoxContainer
var _week_box: HBoxContainer
var _week_label: Label
var _prize_box: HBoxContainer
var _note: Label
var _close_button: Button
var _cooldown := 0.0


static func open_over(source: Node) -> Control:
	if source == null or not source.is_inside_tree():
		return null
	var host: Node = source.get_tree().root.get_node_or_null("World/HUD")
	if host == null:
		host = source.get_tree().current_scene
	if host == null:
		return null
	var panel := host.get_node_or_null(NODE_NAME) as Control
	if panel == null:
		panel = (load("res://src/stamps/stamp_panel.gd") as GDScript).new()
		panel.name = NODE_NAME
		host.add_child(panel)
	panel.call("open")
	return panel


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if theme == null:
		theme = UIStyle.theme()
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
	_panel.custom_minimum_size = Vector2(MobileUI.pick(PANEL_WIDTH, PANEL_WIDTH_MOBILE), 0.0)
	add_child(_panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	_panel.add_child(box)

	# ---- head: the stamp, the title, today's count
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	box.add_child(head)
	head.add_child(StampArt.make("mark", 44.0))
	var titles := VBoxContainer.new()
	titles.add_theme_constant_override("separation", -2)
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(titles)
	titles.add_child(UIStyle.make_label("Norm's Stamp Card", "Title"))
	_subtitle = UIStyle.make_label("", "Soft")
	titles.add_child(_subtitle)
	_count = UIStyle.make_label("", "Header")
	_count.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(_count)

	# ---- body: today's tasks on the left, the week and the prize on the right
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 16)
	box.add_child(body)

	var well := PanelContainer.new()
	well.theme_type_variation = "Inset"
	well.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(well)
	_tasks_box = VBoxContainer.new()
	_tasks_box.add_theme_constant_override("separation", int(MobileUI.pick(12.0, 14.0)))
	well.add_child(_tasks_box)

	var side := VBoxContainer.new()
	side.add_theme_constant_override("separation", 8)
	body.add_child(side)
	side.add_child(UIStyle.make_label("THIS WEEK", "Hint"))
	_week_box = HBoxContainer.new()
	_week_box.add_theme_constant_override("separation", 6)
	side.add_child(_week_box)
	_week_label = UIStyle.make_label("", "Small")
	side.add_child(_week_label)
	var prize_card := PanelContainer.new()
	prize_card.theme_type_variation = "Card"
	prize_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side.add_child(prize_card)
	_prize_box = HBoxContainer.new()
	_prize_box.add_theme_constant_override("separation", 14)
	prize_card.add_child(_prize_box)

	# ---- foot: Norm's note, and the way out
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 20)
	box.add_child(footer)
	_note = UIStyle.make_label("", "Soft")
	_note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_note.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_note.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	footer.add_child(_note)
	_close_button = UIStyle.make_button("Back", "PillPrimary", MobileUI.pick(180.0, 240.0))
	if MobileUI.is_mobile():
		_close_button.custom_minimum_size.y = MobileUI.MIN_TOUCH
	_close_button.pressed.connect(close)
	footer.add_child(_close_button)


func open() -> void:
	if is_open:
		refresh()
		return
	is_open = true
	visible = true
	_cooldown = 0.2
	refresh()
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
	EventBus.ui_modal_closed.emit(MODAL_NAME)
	UIStyle.play_close()
	create_tween().tween_property(_backdrop, "modulate:a", 0.0, 0.14)
	var t := UIStyle.pop_out(_panel)
	t.chain().tween_callback(func() -> void:
		if not is_open:
			visible = false)
	closed.emit()


func _relayout() -> void:
	_panel.reset_size()
	var sa := MobileUI.safe_area()
	_panel.position = (size - _panel.size) * 0.5 + Vector2((sa.x - sa.z) * 0.5, (sa.y - sa.w) * 0.5)


# ============================================================================= content
func refresh() -> void:
	for box: Node in [_tasks_box, _week_box, _prize_box]:
		for c in box.get_children():
			box.remove_child(c)
			c.queue_free()
	StampCard.roll()
	var lines: Variant = load(LINES_PATH) if ResourceLoader.exists(LINES_PATH) else null
	var day := StampCard.day_number(StampCard.today())
	if not StampCard.is_on():
		_subtitle.text = "A card of little things to do each day."
		_count.text = ""
		var off := UIStyle.make_label(str(_const(lines, "STAMP_VIEW_OFF", "Find Norm on the Commons for your card.")), "")
		off.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		off.custom_minimum_size = Vector2(MobileUI.pick(320.0, 420.0), MobileUI.pick(220.0, 260.0))
		_tasks_box.add_child(off)
	else:
		var done := StampCard.done_count()
		if StampCard.stamped_today():
			_subtitle.text = "Stamped! New card tomorrow."
		else:
			_subtitle.text = "Do any %d today for a stamp. New card tomorrow." % StampCard.NEED
		_count.text = "%d / %d" % [mini(done, StampCard.NEED), StampCard.NEED]
		for t: Variant in StampCard.tasks():
			if t is Dictionary:
				_tasks_box.add_child(_task_row(t as Dictionary))
	_build_week()
	_build_prize()
	_note.text = str(lines.call("stamp_view_note", day)) if lines is GDScript and (lines as GDScript).has_method("stamp_view_note") else ""
	if is_open:
		_relayout.call_deferred()


func _task_row(t: Dictionary) -> Control:
	var id := str(t.get("id", ""))
	var done := StampCard.task_done(t)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.add_child(StampArt.make("tick", MobileUI.pick(30.0, 38.0), done))
	var label := UIStyle.make_label(StampCard.text(id), "")
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if done:
		label.add_theme_color_override("font_color", UIStyle.TEXT_SOFT)
	row.add_child(label)
	if StampCard.goal(id) > 1:
		var n := UIStyle.make_label("%d/%d" % [StampCard.task_n(t), StampCard.goal(id)], "Small")
		n.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(n)
	return row


func _build_week() -> void:
	var today := StampCard.today()
	var monday := StampCard.day_number(StampCard.week_start(today))
	var stamps := StampCard.week_stamps() if StampCard.is_on() else []
	var px := MobileUI.pick(42.0, 48.0)
	for i in 7:
		var date := StampCard.date_of(monday + i)
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", -2)
		# Each press sits a little differently, fixed by the date so it does not jump on refresh.
		var tilt := -0.5 + 0.2 * float(posmod(hash(date), 6))
		col.add_child(StampArt.make("stamp", px, stamps.has(date), date == today, tilt))
		var letter := UIStyle.make_label(DAY_LETTERS[i], "Hint", HORIZONTAL_ALIGNMENT_CENTER)
		col.add_child(letter)
		_week_box.add_child(col)
	var n := stamps.size()
	if n >= StampCard.WEEK_NEED:
		_week_label.text = "%d stamps. This week's prize is won!" % n
	else:
		_week_label.text = "%d of %d stamps for the prize" % [n, StampCard.WEEK_NEED]


func _build_prize() -> void:
	var owed := StampCard.owed()
	var id := StampCard.week_prize()
	var px := MobileUI.pick(64.0, 76.0)
	if id != "":
		var glyph := ItemGlyph.new()
		glyph.custom_minimum_size = Vector2(px, px)
		glyph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		glyph.set_def(Catalog.get_item(id))
		glyph.rounded_bg = false
		glyph.modulate = SILHOUETTE
		_prize_box.add_child(glyph)
	else:
		var q := UIStyle.make_label("?", "Title", HORIZONTAL_ALIGNMENT_CENTER)
		q.custom_minimum_size = Vector2(px, px)
		q.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		q.add_theme_color_override("font_color", SILHOUETTE)
		_prize_box.add_child(q)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_prize_box.add_child(col)
	# This week's prize already won and collected: the silhouette is the next one.
	var next_week := StampCard.week_won() and owed <= 0
	col.add_child(UIStyle.make_label("NEXT WEEK'S PRIZE" if next_week else "THIS WEEK'S PRIZE", "Hint"))
	var what := "Ready! See Norm on the Commons." if owed > 0 else "A mystery from Norm's home." if id != "" else "Your pick of Norm's things."
	var l := UIStyle.make_label(what, "Small")
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(MobileUI.pick(190.0, 230.0), 0.0)
	col.add_child(l)


static func _const(lines: Variant, key: String, fallback: Variant) -> Variant:
	if lines is GDScript:
		var m: Dictionary = (lines as GDScript).get_script_constant_map()
		if m.has(key):
			return m[key]
	return fallback


# ============================================================================= input
func _process(delta: float) -> void:
	if not is_open:
		return
	_cooldown -= delta
	if _cooldown > 0.0:
		return
	if UIFocus.accept_pressed() or UIFocus.cancel_pressed():
		if UIFocus.cancel_pressed():
			UIStyle.play_cancel()
		close()


func _input(event: InputEvent) -> void:
	if is_open:
		UIFocus.consume_nav_event(self, event)
