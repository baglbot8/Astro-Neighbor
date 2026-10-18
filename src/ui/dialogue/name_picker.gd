class_name NamePicker
extends Control
## THE NAME PICKER (docs/INTRO_SPEC.md 1.7 and 6): the Professor asks "What shall I call you, pilot?"
## over the radio and the player picks a name from a grid. Picked, never typed, so the phone keyboard
## is never in play.
##
## API (awaitable, like SkipConfirm):
##   var who: String = await NamePicker.pick(host)
## `host` is any Node in the tree; a CanvasLayer is added under it and freed again once answered. The
## pick is written to `GameState.player_style["name"]` (player_home.gd `_who()` and the Day-1 mail read
## it) and returned. Dialogue has no name token: callers format their line with `%s`.
## If the host leaves the tree before an answer, nothing is written and the current name comes back.
##
## INPUT: tap or click a name, then the confirm pill ("I'm Juno!"). Keyboard / gamepad: arrows, WASD
## or the stick move the focus round the grid and down to the confirm pill; accept on a name picks it
## and moves the focus to the pill; accept there confirms. Cancel does nothing - a name is needed.
## The press that advanced the Professor's question can never pick or confirm: everything is ignored
## for ARM_SECONDS after the picker opens.
##
## SIZES: every pill is at least MIN_PILL_H tall on the phone, i.e. MobileUI.MIN_TOUCH (88 logical px =
## 55 dp, above the 48 dp floor - see MobileUI's dp math); the whole panel is ~1000 x 430 logical px,
## which fits both the 1561 x 720 phone canvas and the 1280 x 720 desktop one with room to spare.

signal answered(picked_name: String)

const NAMES: PackedStringArray = ["Astro", "Juno", "Pebble", "Mochi", "Skye", "Pixel", "Sprout", "Ember"]
const DEFAULT_NAME := "Astro"
const COLUMNS := 4
## Over the HUD and the dialogue box (10), under CrashIntro's captions (95), SceneRouter's fade (100)
## and SkipConfirm (150).
const LAYER := 90
## Same reasoning as ConfirmPopup's 0.18 s cooldown and DialogueBox.INPUT_COOLDOWN, longer because a
## tap train on the Professor's box must not land on a name: about two taps of a fast tapper.
const ARM_SECONDS := 0.35
const PILL_W_DESKTOP := 196.0
const PILL_W_MOBILE := 230.0
const PILL_H_DESKTOP := 64.0
const MIN_PILL_H := MobileUI.MIN_TOUCH
const GAP := 14.0

## Hosts with a picker open, so a second `pick()` on the same host is refused instead of stacked.
static var _open_for: Array[Node] = []

var _backdrop: ColorRect
var _panel: PanelContainer
var _title: Label
var _grid: GridContainer
var _buttons: Array[Button] = []
var _confirm: Button
var _open := false
var _chosen := -1
## Focus index: 0..NAMES.size()-1 are the names, NAMES.size() is the confirm pill.
var _index := 0
var _arm := 0.0
var _repeat := UIFocus.NavRepeat.new()
## On the phone the focus ring is hidden until the first key or pad input (the lead, 2026-10-18): a ring
## on "Astro" when the grid opens read as "Astro is already picked". Focus itself still moves as always.
var _ring_shown := true


## Opens the picker under `host`, waits, writes the pick to GameState and returns it.
static func pick(host: Node, prompt: String = "Pick your name") -> String:
	var current := str(GameState.player_style.get("name", DEFAULT_NAME))
	if host == null or not is_instance_valid(host) or not host.is_inside_tree():
		return current
	_prune()
	if _open_for.has(host):
		return current
	_open_for.append(host)
	var layer := CanvasLayer.new()
	layer.name = "NamePickerLayer"
	layer.layer = LAYER
	host.add_child(layer)
	var root := Control.new()
	root.name = "NamePickerRoot"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UIStyle.theme()
	layer.add_child(root)
	MobileUI.apply_theme(root)
	var picker := NamePicker.new()
	picker.name = "NamePicker"
	root.add_child(picker)
	# Freed while open (quit to title): close the modal we opened and answer "" so the await resumes.
	layer.tree_exiting.connect(func() -> void:
		if is_instance_valid(picker) and picker.is_open():
			picker._close("")
	)
	var got: String = await picker.ask(prompt)
	_open_for.erase(host)
	if is_instance_valid(layer):
		# Let the pop-out finish (0.18 s), then go.
		var tree := layer.get_tree()
		if tree != null:
			tree.create_timer(0.25).timeout.connect(func() -> void:
				if is_instance_valid(layer):
					layer.queue_free())
		else:
			layer.queue_free()
	if got == "":
		return current
	GameState.player_style["name"] = got
	return got


static func is_open_for(host: Node = null) -> bool:
	_prune()
	return not _open_for.is_empty() if host == null else _open_for.has(host)


static func _prune() -> void:
	var i := _open_for.size() - 1
	while i >= 0:
		if not is_instance_valid(_open_for[i]):
			_open_for.remove_at(i)
		i -= 1


# ============================================================================= building
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_backdrop = ColorRect.new()
	_backdrop.color = Color(UIStyle.BACKDROP, 0.35)
	_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_backdrop)
	_panel = PanelContainer.new()
	_panel.theme_type_variation = "ModalContainer"
	add_child(_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	_panel.add_child(box)
	_title = UIStyle.make_label("", "Header", HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(_title)
	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override("h_separation", int(GAP))
	_grid.add_theme_constant_override("v_separation", int(GAP))
	box.add_child(_grid)
	var mobile := MobileUI.is_mobile()
	var pill := Vector2(PILL_W_MOBILE if mobile else PILL_W_DESKTOP, MIN_PILL_H if mobile else PILL_H_DESKTOP)
	for i in NAMES.size():
		var b := UIStyle.make_button(NAMES[i], "Pill", pill.x)
		b.custom_minimum_size = pill
		b.name = "Name_%s" % NAMES[i]
		b.pressed.connect(func() -> void: _on_name_pressed(i))
		b.focus_entered.connect(func() -> void: _index = i)
		_grid.add_child(b)
		_buttons.append(b)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(row)
	_confirm = UIStyle.make_button("Pick a name", "PillPrimary", pill.x * 1.6)
	_confirm.name = "Confirm"
	_confirm.custom_minimum_size = Vector2(pill.x * 1.6, pill.y)
	_confirm.pressed.connect(_on_confirm_pressed)
	_confirm.focus_entered.connect(func() -> void: _index = NAMES.size())
	row.add_child(_confirm)
	_refresh_confirm()
	resized.connect(_centre_panel)


func is_open() -> bool:
	return _open


## Shows the grid and waits. Returns the confirmed name, or "" if it was torn down unanswered.
func ask(prompt: String) -> String:
	_title.text = prompt
	_chosen = -1
	_refresh_selection()
	_open = true
	_arm = ARM_SECONDS
	_repeat.reset()
	visible = true
	EventBus.ui_modal_opened.emit("name_picker")
	_backdrop.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(_backdrop, "modulate:a", 1.0, 0.18)
	_panel.reset_size()
	_centre_panel()
	UIStyle.pop_in(_panel)
	_set_ring(not MobileUI.is_mobile())
	_index = 0
	_focus_index()
	var got: String = await answered
	return got


func _centre_panel() -> void:
	if _panel == null:
		return
	_panel.reset_size()
	_panel.position = ((size - _panel.size) * 0.5).floor()
	_panel.pivot_offset = _panel.size * 0.5


# ============================================================================= choosing
func _on_name_pressed(i: int) -> void:
	if not _open or _arm > 0.0:
		return
	_choose(i)


func _on_confirm_pressed() -> void:
	if not _open or _arm > 0.0 or _chosen < 0:
		return
	_close(NAMES[_chosen])


func _choose(i: int) -> void:
	_chosen = i
	_refresh_selection()
	UIStyle.bump(_buttons[i], 1.08, 0.3)
	_index = NAMES.size()
	_focus_index()


## The picked name wears the blue name-tag pill; the confirm pill says who you will be.
func _refresh_selection() -> void:
	for i in _buttons.size():
		_buttons[i].theme_type_variation = "PillBlue" if i == _chosen else "Pill"
	_refresh_confirm()


func _refresh_confirm() -> void:
	if _confirm == null:
		return
	var ok := _chosen >= 0
	_confirm.disabled = not ok
	_confirm.focus_mode = Control.FOCUS_ALL if ok else Control.FOCUS_NONE
	_confirm.text = ("I'm %s!" % NAMES[_chosen]) if ok else "Pick a name"


func _close(result: String) -> void:
	if not _open:
		return
	_open = false
	EventBus.ui_modal_closed.emit("name_picker")
	if result != "":
		UIStyle.play_confirm()
	if is_inside_tree():
		var t := create_tween()
		t.tween_property(_backdrop, "modulate:a", 0.0, 0.16)
		var p := UIStyle.pop_out(_panel, 0.16)
		p.chain().tween_callback(func() -> void: visible = false)
	answered.emit(result)


# ============================================================================= keyboard / gamepad
## Shows or hides the focus ring on every pill (an empty "focus" stylebox hides it).
func _set_ring(on: bool) -> void:
	if on == _ring_shown:
		return
	_ring_shown = on
	var pills: Array[Button] = _buttons.duplicate()
	pills.append(_confirm)
	for b in pills:
		if on:
			b.remove_theme_stylebox_override("focus")
		else:
			b.add_theme_stylebox_override("focus", UIStyle.make_empty_style())


func _focus_index() -> void:
	if _index >= NAMES.size():
		if _confirm.focus_mode != Control.FOCUS_NONE:
			_confirm.grab_focus()
			return
		_index = clampi(_chosen, 0, NAMES.size() - 1)
	_buttons[_index].grab_focus()


func _move(dir: Vector2i) -> void:
	var n := NAMES.size()
	if _index >= n:
		# From the confirm pill, up goes back to the picked name (or the bottom row).
		if dir.y < 0:
			_index = _chosen if _chosen >= 0 else n - COLUMNS
		_focus_index()
		return
	var row := floori(float(_index) / float(COLUMNS))
	var last_row := floori(float(n - 1) / float(COLUMNS))
	if dir.y > 0 and row == last_row:
		if _chosen >= 0:
			_index = n
		_focus_index()
		return
	_index = UIFocus.grid_move(_index, n, COLUMNS, dir)
	_focus_index()


func _process(delta: float) -> void:
	if not _open:
		return
	if _arm > 0.0:
		_arm -= delta
		_repeat.poll(delta)
		return
	var step := _repeat.poll(delta)
	if not _ring_shown and (step != Vector2i.ZERO or UIFocus.accept_pressed()):
		_set_ring(true)
	if step != Vector2i.ZERO:
		# One axis at a time, vertical first (a diagonal stick reads as up/down).
		_move(Vector2i(0, step.y) if step.y != 0 else Vector2i(step.x, 0))
	if UIFocus.accept_pressed():
		if _index >= NAMES.size():
			_on_confirm_pressed()
		else:
			_choose(_index)


func _input(event: InputEvent) -> void:
	if not _open:
		return
	if not _ring_shown and (event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion):
		_set_ring(true)
	UIFocus.consume_nav_event(self, event)


# ============================================================================= test hooks
## SYNTHESISED input for a Director timeline or the showcase: taps the centre of a name pill (or the
## confirm pill, `which` = "confirm") through `MobileUI.synth_tap`, the path a finger's emulated mouse
## event takes. Not a real finger.
func debug_tap(which: String) -> void:
	var b: Button = _confirm if which == "confirm" else null
	for i in NAMES.size():
		if NAMES[i] == which:
			b = _buttons[i]
	if b == null:
		print("NAMEPICKER TAP %s: no such pill" % which)
		return
	var c := b.get_global_rect().get_center()
	print("NAMEPICKER TAP %s at %s size %s" % [which, str(c), str(b.size)])
	MobileUI.synth_tap(c)


## One line for a timeline to assert on: open, chosen, focus, the rects (in the 720-tall canvas).
func debug_report(tag: String) -> void:
	var focus := "none"
	var f := get_viewport().gui_get_focus_owner()
	if f != null:
		focus = f.name
	var smallest := Vector2(INF, INF)
	for b in _buttons:
		smallest = Vector2(minf(smallest.x, b.size.x), minf(smallest.y, b.size.y))
	print("NAMEPICKER REPORT %s open=%s ring=%s chosen=%s focus=%s panel=%s canvas=%s smallest_pill=%s confirm=%s mobile=%s name=%s" % [
		tag, str(_open), str(_ring_shown), NAMES[_chosen] if _chosen >= 0 else "-", focus, str(_panel.get_global_rect()),
		str(get_viewport_rect().size), str(smallest), str(_confirm.size), str(MobileUI.is_mobile()),
		str(GameState.player_style.get("name", ""))])
