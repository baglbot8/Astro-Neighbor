class_name PauseMenu
extends Control
## Pause overlay: Resume / Save Game / Settings / Quit to Title. Pauses the tree while open.
## Settings: music + sfx sliders (GameState.settings + AudioManager.apply_settings), a mouse-look
## sensitivity slider, and the camera invert X / invert Y toggles.
## `cancel` closes (or backs out of settings). Emits EventBus.ui_modal_opened("pause") / closed.
##
## HIDDEN DEVELOPER MENU (added 2026-09-12, user request). Five taps on the SETTINGS title within
## DEV_GESTURE_WINDOW seconds open `src/ui/pause/dev_menu.gd`'s DevMenu — see `_on_title_gui_input`.
## No button, no line in the main list, no hint anywhere: this is the only trigger.

signal closed

const PANEL_WIDTH := 460.0
## MOBILE (R2.10): a wider panel, because the mobile Theme sets type 1.2x and pads every pill to a
## thumb-sized target - at 460 the "Quit to Title" label wrapped.
const PANEL_WIDTH_MOBILE := 660.0
## The three-way UI-mode control (R2.10: "so the user can force either on any machine").
const UI_MODES: Array[String] = ["auto", "desktop", "mobile"]
const UI_MODE_LABELS: Array[String] = ["Auto", "Computer", "Phone"]
## Mouse-look sensitivity range behind the 0..1 "Look speed" slider. 1.0 (the GameState default)
## lands at slider 0.40, so the out-of-the-box feel sits a little left of centre with headroom both
## ways.
const SENS_MIN := 0.20
const SENS_MAX := 2.20
## HIDDEN DEVELOPER MENU gesture: this many presses on the Settings title within this many seconds.
const DEV_GESTURE_TAPS := 5
const DEV_GESTURE_WINDOW := 2.0

var is_open := false

var _backdrop: ColorRect
var _panel: PanelContainer
var _title: Label
var _subtitle: Label
var _main_box: VBoxContainer
var _settings_box: VBoxContainer
var _main_items: Array[Control] = []
var _settings_items: Array[Control] = []
var _index := 0
var _in_settings := false
var _repeat := UIFocus.NavRepeat.new()
var _cooldown := 0.0
var _music: PillSlider
var _sfx: PillSlider
var _invert: ToggleSwitch
var _invert_y: ToggleSwitch
var _look: PillSlider
var _ui_mode: SegmentedControl
## The keyboard hint strip at the foot of the menu - desktop only (R2.10), and it has to follow a
## RUNTIME switch, not just the mode the menu was built in.
var _hints_row: HBoxContainer
## HIDDEN DEVELOPER MENU gesture state (see `_on_title_gui_input`).
var _dev_tap_count := 0
var _dev_tap_last := 0.0

func _ready() -> void:
	MobileUI.apply_theme(self)
	MobileUI.on_mode_changed(_on_platform_mode_changed)
	process_mode = Node.PROCESS_MODE_ALWAYS
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
	box.add_theme_constant_override("separation", 14)
	_panel.add_child(box)
	_title = UIStyle.make_label("Paused", "Title", HORIZONTAL_ALIGNMENT_CENTER)
	# HIDDEN DEVELOPER MENU: this Label is not normally clickable (STOP so gui_input actually
	# reaches it); `_on_title_gui_input` below only ever does anything while `_in_settings` is true,
	# so the "Paused" screen's title is inert.
	_title.mouse_filter = Control.MOUSE_FILTER_STOP
	_title.gui_input.connect(_on_title_gui_input)
	box.add_child(_title)
	_subtitle = UIStyle.make_label("Take a breather.", "Soft", HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(_subtitle)
	_main_box = VBoxContainer.new()
	_main_box.add_theme_constant_override("separation", 10)
	box.add_child(_main_box)
	_settings_box = VBoxContainer.new()
	_settings_box.add_theme_constant_override("separation", 14)
	_settings_box.visible = false
	box.add_child(_settings_box)
	# main buttons
	# ADDED BY THE ONBOARDING BUILDER: the "Favours" entry (the quest log). It opens
	# src/ui/journal/journal_panel.gd, which closes this menu and reopens it on the way back.
	var defs := [["Resume", _resume, "PillPrimary"], ["Favours", _open_journal, "Pill"], ["Save Game", _save, "Pill"], ["Settings", _open_settings, "Pill"], ["Quit to Title", _quit_to_title, "Pill"]]
	for d in defs:
		var b := UIStyle.make_button(str(d[0]), str(d[2]))
		b.size_flags_horizontal = Control.SIZE_FILL
		if MobileUI.is_mobile():
			b.custom_minimum_size = Vector2(0.0, MobileUI.MIN_TOUCH)
		var cb: Callable = d[1]
		b.pressed.connect(func() -> void: cb.call())
		b.focus_entered.connect(func() -> void: _index = _main_items.find(b))
		_main_box.add_child(b)
		_main_items.append(b)
	# settings rows
	_music = PillSlider.new()
	_music.value = float(GameState.settings.get("music_volume", 0.8))
	_music.value_changed.connect(func(v: float) -> void:
		GameState.settings["music_volume"] = v
		AudioManager.apply_settings())
	_settings_items.append(_add_setting_row("Music", _music))
	_sfx = PillSlider.new()
	_sfx.value = float(GameState.settings.get("sfx_volume", 1.0))
	_sfx.value_changed.connect(func(v: float) -> void:
		GameState.settings["sfx_volume"] = v
		AudioManager.apply_settings())
	_settings_items.append(_add_setting_row("Sounds", _sfx))
	# ADDED BY THE PLAYER BUILDER alongside mouse look (src/player/camera_rig.gd). Three rows, all
	# built with this file's own helpers so nothing else here changes: the sensitivity slider is
	# 0..1 on screen and maps to SENS_MIN..SENS_MAX for GameState, and the two toggles are the X/Y
	# pair the rig reads. The player's complaint was *"I can't control the camera well"*, so the
	# controls that fix it have to be reachable from the pause menu.
	_look = PillSlider.new()
	_look.value = _sens_to_slider(float(GameState.settings.get("mouse_sensitivity", 1.0)))
	_look.value_changed.connect(func(v: float) -> void:
		GameState.settings["mouse_sensitivity"] = _slider_to_sens(v))
	_settings_items.append(_add_setting_row("Look speed", _look))
	_invert = ToggleSwitch.new()
	_invert.on = bool(GameState.settings.get("camera_invert_x", false))
	_invert.toggled.connect(func(on: bool) -> void: GameState.settings["camera_invert_x"] = on)
	_settings_items.append(_add_setting_row("Invert camera", _invert))
	_invert_y = ToggleSwitch.new()
	_invert_y.on = bool(GameState.settings.get("camera_invert_y", false))
	_invert_y.toggled.connect(func(on: bool) -> void: GameState.settings["camera_invert_y"] = on)
	_settings_items.append(_add_setting_row("Invert vertical", _invert_y))
	# ADDED BY THE MOBILE UI BUILDER for R2.10. The game ships two front ends and the layout nobody
	# is sitting in front of never gets checked, so the player (and any reviewer on any machine)
	# can force either. Writes GameState.settings["ui_mode"] through `Platform.set_ui_mode`, which
	# re-runs detection for "Auto" and emits `mode_changed` so the HUD, the panels and the camera
	# rig all re-lay-out without a restart.
	_ui_mode = SegmentedControl.new()
	_ui_mode.setup(PackedStringArray(UI_MODE_LABELS), maxi(0, UI_MODES.find(Platform.ui_mode_setting())))
	_ui_mode.selected.connect(func(i: int) -> void: _set_ui_mode(UI_MODES[i]))
	_settings_items.append(_add_setting_row("Controls", _ui_mode))
	var back := UIStyle.make_button("Back", "PillPrimary")
	back.size_flags_horizontal = Control.SIZE_FILL
	if MobileUI.is_mobile():
		back.custom_minimum_size = Vector2(0.0, MobileUI.MIN_TOUCH)
	back.pressed.connect(_close_settings)
	back.focus_entered.connect(func() -> void: _index = _settings_items.find(back))
	_settings_box.add_child(back)
	_settings_items.append(back)
	# hint strip - keyboard glyphs, so desktop only (R2.10)
	var hints := HBoxContainer.new()
	hints.alignment = BoxContainer.ALIGNMENT_CENTER
	hints.add_theme_constant_override("separation", 20)
	hints.visible = not MobileUI.is_mobile()
	_hints_row = hints
	box.add_child(hints)
	for h in [["interact", "Select"], ["cancel", "Back"]]:
		var pair := HBoxContainer.new()
		pair.add_theme_constant_override("separation", 6)
		var g := KeyGlyph.new()
		g.set_action(str(h[0]))
		g.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		pair.add_child(g)
		pair.add_child(UIStyle.make_label(str(h[1]), "Hint"))
		hints.add_child(pair)

## HIDDEN DEVELOPER MENU. Five presses on the SETTINGS title within DEV_GESTURE_WINDOW seconds open
## DevMenu (src/ui/pause/dev_menu.gd). Gated on `_in_settings` so it can only ever fire on the
## Settings page, never on "Paused"; a real pointer/touch press is required (a Label has no focus,
## so `UIFocus.accept_pressed()` — the keyboard/gamepad "activate" path — never reaches it, and
## `Input.action_press()` sends no InputEvent at all, so no scripted action-press can trip this
## either). Nothing on screen hints this exists.
func _on_title_gui_input(event: InputEvent) -> void:
	if not _in_settings:
		return
	var pressed := (event is InputEventMouseButton and (event as InputEventMouseButton).pressed
			and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT) \
		or (event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed)
	if not pressed:
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - _dev_tap_last > DEV_GESTURE_WINDOW:
		_dev_tap_count = 0
	_dev_tap_last = now
	_dev_tap_count += 1
	if _dev_tap_count >= DEV_GESTURE_TAPS:
		_dev_tap_count = 0
		DevMenu.open_over(self)


## Test hook, same shape as `debug_tap_ui_mode`: DEV_GESTURE_TAPS real taps (`MobileUI.synth_tap` —
## an actual InputEventMouseButton through `Input.parse_input_event`, NOT `Input.action_press`,
## which sends no InputEvent at all) on the Settings title's own rect, so a Director probe can
## reproduce the hidden gesture the way a finger would. No-op outside Settings, same as a player's
## stray tap there would be.
func debug_tap_dev_gesture() -> void:
	if not _in_settings:
		return
	var pos := _title.get_global_rect().get_center()
	for i in DEV_GESTURE_TAPS:
		MobileUI.synth_tap(pos)


## Test-only NEGATIVE CONTROL: the same DEV_GESTURE_TAPS real taps on the title's own rect as
## `debug_tap_dev_gesture`, but WITHOUT that function's `_in_settings` guard at the call site — so a
## probe can prove the identical `_on_title_gui_input` handler runs (and correctly does nothing)
## when the title reads "Paused" rather than skip the whole test because the gesture is gated out
## one level up.
func debug_tap_title_raw() -> void:
	var pos := _title.get_global_rect().get_center()
	for i in DEV_GESTURE_TAPS:
		MobileUI.synth_tap(pos)


func _set_ui_mode(mode: String) -> void:
	if Platform.ui_mode_setting() == mode:
		return
	Platform.set_ui_mode(mode)
	_refresh_ui_mode()
	var live := "phone layout" if Platform.is_mobile() else "computer layout"
	EventBus.toast_requested.emit("Controls: %s" % live, "star")


func _refresh_ui_mode() -> void:
	if _ui_mode != null:
		_ui_mode.index = maxi(0, UI_MODES.find(Platform.ui_mode_setting()))


## A runtime front-end switch changes every font size and every pill's padding, so the panel has to
## be re-themed and re-measured rather than just repainted.
func _on_platform_mode_changed(_mobile: bool) -> void:
	MobileUI.apply_theme(self)
	if theme == null and not MobileUI.is_mobile():
		theme = UIStyle.theme()
	_panel.custom_minimum_size = Vector2(MobileUI.pick(PANEL_WIDTH, PANEL_WIDTH_MOBILE), 0.0)
	var touch_h: float = MobileUI.MIN_TOUCH if MobileUI.is_mobile() else 0.0
	for b in _main_items:
		b.custom_minimum_size = Vector2(0.0, touch_h)
	for c in _settings_items:
		if c is Button:
			c.custom_minimum_size = Vector2(0.0, touch_h)
	for c in [_music, _sfx, _look, _invert, _invert_y, _ui_mode]:
		if c != null and c.has_method("refresh_platform"):
			c.call("refresh_platform")
	if _hints_row != null:
		_hints_row.visible = not MobileUI.is_mobile()
	_refresh_ui_mode()
	if is_open:
		call_deferred("_relayout")


## Test hook: taps segment `i` of the UI-mode control (0 Auto / 1 Computer / 2 Phone) the way a
## finger or a mouse does. A Director timeline can only press actions, and this control is driven
## by position, so tests/director/ui_mode_switch.json goes through here.
func debug_tap_ui_mode(i: int) -> void:
	if _ui_mode == null or i < 0 or i >= UI_MODES.size():
		return
	MobileUI.synth_tap(_ui_mode.get_global_rect().position
		+ _ui_mode._segment_rect(i).get_center())


## One-line state dump for a timeline to assert against.
func debug_report(tag: String = "") -> void:
	print("PAUSE %s open=%s in_settings=%s ui_mode=%s live=%s panel_w=%.0f" % [
		tag, str(is_open), str(_in_settings), Platform.ui_mode_setting(), Platform.mode_name(),
		_panel.size.x])


static func _slider_to_sens(v: float) -> float:
	return SENS_MIN + clampf(v, 0.0, 1.0) * (SENS_MAX - SENS_MIN)


static func _sens_to_slider(s: float) -> float:
	return clampf((s - SENS_MIN) / (SENS_MAX - SENS_MIN), 0.0, 1.0)


func _add_setting_row(label: String, control: Control) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var l := UIStyle.make_label(label, "")
	l.custom_minimum_size = Vector2(MobileUI.pick(150.0, 190.0), 0.0)
	row.add_child(l)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	control.focus_entered.connect(func() -> void: _index = _settings_items.find(control))
	row.add_child(control)
	_settings_box.add_child(row)
	return control

# ----------------------------------------------------------------------------- open / close
## Opens the menu and pauses the tree.
func open() -> void:
	if is_open:
		return
	is_open = true
	visible = true
	_in_settings = false
	_main_box.visible = true
	_settings_box.visible = false
	_index = 0
	_cooldown = 0.2
	_repeat.reset()
	_music.value = float(GameState.settings.get("music_volume", 0.8))
	_sfx.value = float(GameState.settings.get("sfx_volume", 1.0))
	_invert.on = bool(GameState.settings.get("camera_invert_x", false))
	_invert_y.on = bool(GameState.settings.get("camera_invert_y", false))
	_look.value = _sens_to_slider(float(GameState.settings.get("mouse_sensitivity", 1.0)))
	_refresh_ui_mode()
	get_tree().paused = true
	EventBus.ui_modal_opened.emit("pause")
	UIStyle.play_open()
	_backdrop.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(_backdrop, "modulate:a", 1.0, 0.2)
	_relayout()
	UIStyle.pop_in(_panel)
	_focus_current()

## Closes the menu and unpauses.
func close() -> void:
	if not is_open:
		return
	is_open = false
	get_tree().paused = false
	EventBus.ui_modal_closed.emit("pause")
	UIStyle.play_close()
	var t := create_tween()
	t.tween_property(_backdrop, "modulate:a", 0.0, 0.16)
	var p := UIStyle.pop_out(_panel)
	p.chain().tween_callback(func() -> void:
		if not is_open:
			visible = false)
	closed.emit()

func _relayout() -> void:
	_panel.reset_size()
	# Centred inside the SAFE rectangle, not the raw viewport: a landscape notch makes the usable
	# area off-centre and a plain centre would put the panel edge under it.
	var sa := MobileUI.safe_area()
	_panel.position = (size - _panel.size) * 0.5 + Vector2((sa.x - sa.z) * 0.5, (sa.y - sa.w) * 0.5)

func _items() -> Array[Control]:
	return _settings_items if _in_settings else _main_items

func _focus_current() -> void:
	var items := _items()
	if items.is_empty():
		return
	_index = clampi(_index, 0, items.size() - 1)
	UIFocus.focus(items[_index])

# ----------------------------------------------------------------------------- actions
func _resume() -> void:
	close()

func _save() -> void:
	if SaveManager.save_game():
		EventBus.toast_requested.emit("Saved!", "check")
		UIStyle.play_sfx("ui_buy")
	else:
		EventBus.toast_requested.emit("Couldn't save.", "warn")

## ADDED BY THE ONBOARDING BUILDER. The log takes over as a sub-page: this menu closes (same frame,
## so the tree never resumes) and JournalPanel reopens it when the player backs out.
func _open_journal() -> void:
	JournalPanel.open_over(self)


func _open_settings() -> void:
	_in_settings = true
	_dev_tap_count = 0
	_main_box.visible = false
	_settings_box.visible = true
	_index = 0
	_title.text = "Settings"
	_subtitle.text = "Music, sounds and camera."
	call_deferred("_relayout")
	_focus_current()

func _close_settings() -> void:
	_in_settings = false
	_dev_tap_count = 0
	_settings_box.visible = false
	_main_box.visible = true
	# 3, not 2, since the onboarding builder's "Favours" entry sits above "Settings".
	_index = 3
	_title.text = "Paused"
	_subtitle.text = "Take a breather."
	call_deferred("_relayout")
	_focus_current()

func _quit_to_title() -> void:
	close()
	SceneRouter.go_to_title()

# ----------------------------------------------------------------------------- input
func _process(delta: float) -> void:
	if not is_open:
		return
	_cooldown -= delta
	if _cooldown > 0.0:
		return
	var items := _items()
	var step := _repeat.poll(delta)
	if step.y != 0 and not items.is_empty():
		_index = UIFocus.list_move(_index, items.size(), step.y)
		_focus_current()
	elif step.x != 0 and not items.is_empty():
		var c := items[_index]
		if c.has_method("adjust"):
			c.call("adjust", step.x)
	if UIFocus.accept_pressed() and not items.is_empty():
		var c := items[_index]
		if c is Button:
			(c as Button).pressed.emit()
		elif c.has_method("activate"):
			c.call("activate")
	elif UIFocus.cancel_pressed():
		if _in_settings:
			_close_settings()
			UIStyle.play_cancel()
		else:
			close()
	elif Input.is_action_just_pressed("pause") and not _in_settings:
		close()

func _input(event: InputEvent) -> void:
	if is_open:
		UIFocus.consume_nav_event(self, event)
