class_name DevMenu
extends Control
## HIDDEN developer tools (added 2026-09-12, at the user's request: "it would be good to have a
## hidden developer tools option ... let me skip to portions of the game for testing, so i dont have
## to play through to see the end cutscenes or mini games").
##
## OPENED ONLY BY A HIDDEN GESTURE (pause_menu.gd `_on_title_gui_input`): five taps on the SETTINGS
## title within 2 seconds, while the Settings page is open. There is no button for it anywhere, no
## line in the main pause list, and no keyboard/gamepad path — the gesture reads a raw pointer/touch
## press on one Label, which carries no focus and never sees `UIFocus.accept_pressed()`. It stays in
## the shipped build on purpose (the user wants it on her phone), and it is hidden, not disabled.
##
## EVERY ROW EDITS LIVE GAME STATE, IMMEDIATELY, THROUGH THE SAME PUBLIC SIGNALS/METHODS THE REAL
## GAME USES (GameState's own fields and methods, EventBus signals) — never private helpers on
## another system. Nothing here writes the save file; the player still saves the normal way (the
## pause menu's own "Save Game").
##
## PHASE 2 GUARD. `src/projects/**` and `src/campaign/part_celebration.*` are not in every build
## (docs/BUILD_PLAN.md). This file never types a variable as `ProjectSystem`, so it still PARSES
## with those files removed; every call into that system goes through `ResourceLoader.exists()` +
## `load(path).call(...)`, the same trick `src/world/world.gd` already uses for the same reason. The
## part-celebration row is likewise gated on `ResourceLoader.exists()` before it does anything, and
## the row that needs a specific node (the celebration only exists on "home") checks for the node at
## press time and says so instead of failing silently.
##
## ROW-DEFINITION DATA. `_rebuild_rows()` is the only place that lists what is in the menu; every
## row is built by one of a handful of small helpers (`_add_action_row`, `_add_stepper_row`,
## `_add_toggle_row`, `_add_currency_row`, `_add_project_block`). A future row (the mini-games in
## CORE_LOOP.md don't exist yet) is one more call in that list, not a hand-built Control tree.

signal closed

const PANEL_WIDTH := 520.0
## MOBILE (matches pause_menu.gd's own R2.10 reasoning): wider, because the mobile Theme pads every
## pill to a thumb-sized target and this menu's rows are busier than the settings page's.
const PANEL_WIDTH_MOBILE := 720.0
const BODY_HEIGHT := 460.0
const MODAL_NAME := "dev_menu"
const NODE_NAME := "DevMenu"

## Phase 2 files. Guarded with ResourceLoader.exists() everywhere they are used; never referenced
## as a static type.
const PROJECT_SYSTEM_PATH := "res://src/projects/project_system.gd"
const PART_CELEBRATION_SCENE := "res://src/campaign/part_celebration.tscn"
const CRASH_INTRO_SCRIPT := "res://src/onboarding/crash_intro.gd"

var is_open := false

var _backdrop: ColorRect
var _panel: PanelContainer
var _scroll: ScrollContainer
var _list: VBoxContainer
var _close_button: Button
var _repeat := UIFocus.NavRepeat.new()
var _cooldown := 0.0
## The pause menu to reopen when this closes (JournalPanel's own pattern). Duck-typed, not typed
## PauseMenu, for the same class-cycle reason journal_panel.gd gives.
var _reopen_pause: Node
var _paused_tree := false

## Live-value controls this menu keeps in sync with GameState, refreshed on open and after every
## action (`_refresh_values`).
var _parts_seg: SegmentedControl
var _day_label: Label
var _scrap_label: Label
var _stardust_label: Label
var _campaign_toggle: ToggleSwitch
var _story_toggle: ToggleSwitch
## npc_id -> the status Label in that neighbour's project block.
var _project_labels: Dictionary = {}

## Guards a crash-intro replay already in flight so a second tap merges into a toast instead of
## spawning a second shot fighting the first for the same rocket and camera.
var _crash_busy := false


# ============================================================================= entry point
## Opens the dev menu over `source` (the pause menu, mid-Settings). Mirrors
## `JournalPanel.open_over`: closes the pause menu the same frame (the tree never actually resumes
## between the two), and reopens it when this closes normally.
static func open_over(source: Node) -> DevMenu:
	if source == null or not source.is_inside_tree():
		return null
	var host: Node = source.get_tree().root.get_node_or_null("World/HUD")
	if host == null:
		host = source.get_parent()
	if host == null:
		host = source.get_tree().current_scene
	if host == null:
		return null
	var menu := host.get_node_or_null(NODE_NAME) as DevMenu
	if menu == null:
		menu = DevMenu.new()
		menu.name = NODE_NAME
		host.add_child(menu)
	if menu.is_open:
		return menu
	if _is_open_pause_menu(source):
		menu._reopen_pause = source
		source.call("close")
	menu.open(true)
	return menu


static func _is_open_pause_menu(n: Node) -> bool:
	return n != null and n.has_method("open") and n.has_method("close") \
		and "is_open" in n and bool(n.get("is_open"))


# ============================================================================= build
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
	_panel.custom_minimum_size = Vector2(_panel_width(), 0.0)
	add_child(_panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	_panel.add_child(box)
	box.add_child(UIStyle.make_label("Developer Menu", "Title", HORIZONTAL_ALIGNMENT_CENTER))
	var warn := UIStyle.make_label(
		"Edits the live game right now. It does not save by itself — save from Pause as usual.",
		"Soft", HORIZONTAL_ALIGNMENT_CENTER)
	warn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(warn)

	var well := PanelContainer.new()
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

	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(footer)
	_close_button = UIStyle.make_button("Back", "PillPrimary", MobileUI.pick(180.0, 260.0))
	if MobileUI.is_mobile():
		_close_button.custom_minimum_size.y = MobileUI.MIN_TOUCH
	_close_button.pressed.connect(close)
	footer.add_child(_close_button)

	_rebuild_rows()


func _panel_width() -> float:
	return MobileUI.pick(PANEL_WIDTH, PANEL_WIDTH_MOBILE)


# ============================================================================= open / close
func open(pause_tree: bool = true) -> void:
	if is_open:
		return
	is_open = true
	visible = true
	_cooldown = 0.2
	_repeat.reset()
	_refresh_values()
	_paused_tree = pause_tree
	if pause_tree:
		get_tree().paused = true
	EventBus.ui_modal_opened.emit(MODAL_NAME)
	UIStyle.play_open()
	_backdrop.modulate.a = 0.0
	create_tween().tween_property(_backdrop, "modulate:a", 1.0, 0.18)
	# DEFERRED, not called directly: on a freshly-built menu (this frame's `_build()` just added
	# ~30 rows) the container chain's minimum size has not settled yet — measured once as a real
	# bug, not a theory: `_panel.reset_size()` called in the same frame content was added sized the
	# panel to its *pre-layout* combined minimum (2479px tall on a 720px-tall viewport, rendering as
	# a giant empty rectangle with every row pushed off screen) even though `well`/`_scroll` already
	# reported the correct, small minimum a moment later in the same function. Same fix pause_menu.gd
	# already uses for the identical class of bug (`_open_settings`/`_close_settings` both
	# `call_deferred("_relayout")` after a visibility change, for the same reason).
	call_deferred("_after_open_layout")


func _after_open_layout() -> void:
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
		# The gesture only exists on the Settings page, so land back where the player actually was
		# instead of PauseMenu.open()'s own default (the main Paused list) — measured without this:
		# the reopened menu showed the Settings TITLE (never reset by `open()`) over the MAIN list's
		# buttons, a confusing hybrid.
		if pause.has_method("_open_settings"):
			pause.call("_open_settings")


## Used by rows that leave gameplay entirely (a planet jump, a cutscene): closes this menu WITHOUT
## reopening the pause menu behind it, so the player lands back in the game, not in a menu stack.
func _close_all_menus() -> void:
	_reopen_pause = null
	close()


func _relayout() -> void:
	_panel.reset_size()
	var sa := MobileUI.safe_area()
	_panel.position = (size - _panel.size) * 0.5 + Vector2((sa.x - sa.z) * 0.5, (sa.y - sa.w) * 0.5)


# ============================================================================= rows
func _rebuild_rows() -> void:
	for c in _list.get_children():
		c.queue_free()
	_project_labels.clear()
	_parts_seg = null
	_day_label = null
	_scrap_label = null
	_stardust_label = null
	_campaign_toggle = null
	_story_toggle = null

	_add_section("Go to planet — the pad's own loader, no flight")
	for pid: String in GameState.PLANET_IDS:
		_add_action_row(Journal.planet_name(pid), func() -> void: _jump_to(pid), "Go")

	_add_section("Rocket parts — drives the finish and the picker's range")
	var parts_row := _row("Parts fitted")
	_parts_seg = SegmentedControl.new()
	var labels := PackedStringArray()
	for i in (CampaignData.PARTS.size() + 1):
		labels.append(str(i))
	_parts_seg.setup(labels, GameState.rocket_part_count())
	_parts_seg.selected.connect(func(i: int) -> void: _set_rocket_parts(i))
	_parts_seg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parts_row.add_child(_parts_seg)

	_add_section("In-game day — gates one project step per neighbour per day")
	var day_row := _row("Day")
	_day_label = UIStyle.make_label("", "")
	_day_label.custom_minimum_size = Vector2(MobileUI.pick(70.0, 90.0), 0.0)
	_day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	day_row.add_child(_day_label)
	day_row.add_child(_small_button("-1", func() -> void: _add_day(-1)))
	day_row.add_child(_small_button("+1", func() -> void: _add_day(1)))
	day_row.add_child(_small_button("+7", func() -> void: _add_day(7)))

	_add_section("Currency")
	_scrap_label = _add_currency_row("Scrap",
		func(n: int) -> void: GameState.add_scrap(n),
		func() -> void: GameState.spend_scrap(GameState.scrap))
	_stardust_label = _add_currency_row("Stardust",
		func(n: int) -> void: GameState.add_stardust(n),
		func() -> void: GameState.spend_stardust(GameState.stardust))

	_add_section("Campaign gates")
	var camp_row := _row("Campaign active")
	_campaign_toggle = ToggleSwitch.new()
	_campaign_toggle.toggled.connect(func(on: bool) -> void: _set_campaign_active(on))
	camp_row.add_child(_campaign_toggle)
	var story_row := _row("Story finished")
	_story_toggle = ToggleSwitch.new()
	_story_toggle.toggled.connect(func(on: bool) -> void: _set_story_done(on))
	story_row.add_child(_story_toggle)

	_add_section("Cutscenes")
	_add_action_row("Replay the crash intro", _replay_crash, "Play")
	if ResourceLoader.exists(PART_CELEBRATION_SCENE):
		_add_action_row("Play a part celebration", _play_celebration, "Play")
	else:
		_add_note("Part celebration: not in this build.")

	if ResourceLoader.exists(PROJECT_SYSTEM_PATH):
		_add_section("Neighbour projects — start, advance, finish, give the part")
		for p: Dictionary in CampaignData.PARTS:
			_add_project_block(str(p.get("npc", "")))
	else:
		_add_note("Neighbour projects: not in this build yet.")

	_add_section("More")
	_add_note("More rows land here as new systems ship (the CORE_LOOP mini-games don't exist yet).")


func _add_section(text: String) -> void:
	if _list.get_child_count() > 0:
		_list.add_child(HSeparator.new())
	_list.add_child(UIStyle.make_label(text.to_upper(), "Hint"))


func _add_note(text: String) -> void:
	var l := UIStyle.make_label(text, "Small")
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_list.add_child(l)


func _row(label_text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var l := UIStyle.make_label(label_text, "")
	l.custom_minimum_size = Vector2(MobileUI.pick(150.0, 190.0), 0.0)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(l)
	_list.add_child(row)
	return row


func _touch_button(text: String, variation: String = "Pill") -> Button:
	var b := UIStyle.make_button(text, variation)
	if MobileUI.is_mobile():
		b.custom_minimum_size = Vector2(0.0, MobileUI.MIN_TOUCH)
	return b


## A compact stepper button (-1/+1/+7 etc.) — not stretched, so several fit on one row.
func _small_button(text: String, cb: Callable) -> Button:
	var b := _touch_button(text)
	b.custom_minimum_size.x = maxf(b.custom_minimum_size.x, MobileUI.pick(56.0, 72.0))
	b.pressed.connect(func() -> void:
		cb.call()
		_refresh_values())
	return b


func _add_action_row(label_text: String, cb: Callable, button_text: String = "Go") -> Button:
	var row := _row(label_text)
	var b := _touch_button(button_text)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.pressed.connect(cb)
	row.add_child(b)
	return b


func _add_currency_row(label_text: String, add_cb: Callable, clear_cb: Callable) -> Label:
	var row := _row(label_text)
	var val := UIStyle.make_label("", "")
	val.custom_minimum_size = Vector2(MobileUI.pick(70.0, 90.0), 0.0)
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(val)
	row.add_child(_small_button("+10", func() -> void: add_cb.call(10)))
	row.add_child(_small_button("+50", func() -> void: add_cb.call(50)))
	row.add_child(_small_button("Clear", func() -> void: clear_cb.call()))
	return val


func _add_project_block(npc_id: String) -> void:
	if npc_id == "":
		return
	var block := VBoxContainer.new()
	block.add_theme_constant_override("separation", 4)
	_list.add_child(block)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	block.add_child(head)
	var name_label := UIStyle.make_label(_npc_name(npc_id), "")
	name_label.custom_minimum_size = Vector2(MobileUI.pick(150.0, 190.0), 0.0)
	head.add_child(name_label)
	var status := UIStyle.make_label("", "Small")
	status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(status)
	_project_labels[npc_id] = status
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	block.add_child(buttons)
	var adv := _touch_button("Start / Advance")
	adv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	adv.pressed.connect(func() -> void: _advance_project(npc_id))
	buttons.add_child(adv)
	var fin := _touch_button("Finish + give part")
	fin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fin.pressed.connect(func() -> void: _finish_project(npc_id))
	buttons.add_child(fin)
	var reset := _touch_button("Reset")
	reset.pressed.connect(func() -> void: _reset_project(npc_id))
	buttons.add_child(reset)


# ============================================================================= value refresh
func _refresh_values() -> void:
	if _parts_seg != null:
		_parts_seg.index = clampi(GameState.rocket_part_count(), 0, CampaignData.PARTS.size())
	if _day_label != null:
		_day_label.text = str(GameState.day_count)
	if _scrap_label != null:
		_scrap_label.text = str(GameState.scrap)
	if _stardust_label != null:
		_stardust_label.text = str(GameState.stardust)
	if _campaign_toggle != null:
		_campaign_toggle.on = GameState.campaign_active
	if _story_toggle != null:
		_story_toggle.on = GameState.story_done
	for npc_id: String in _project_labels:
		(_project_labels[npc_id] as Label).text = _project_status_text(npc_id)


func _project_status_text(npc_id: String) -> String:
	if not ResourceLoader.exists(PROJECT_SYSTEM_PATH):
		return ""
	var d: Variant = load(PROJECT_SYSTEM_PATH).call("definition_for", npc_id)
	if typeof(d) != TYPE_DICTIONARY or (d as Dictionary).is_empty():
		return "no project"
	var st: Variant = GameState.projects.get(npc_id, {})
	if typeof(st) != TYPE_DICTIONARY or (st as Dictionary).is_empty():
		return "not started"
	var std: Dictionary = st
	if bool(std.get("done", false)):
		return "done, part given"
	var steps: Array = (d as Dictionary).get("steps", [])
	return "step %d of %d" % [int(std.get("step", 0)), steps.size()]


# ============================================================================= actions: planets
func _jump_to(planet_id: String) -> void:
	if SceneRouter.is_busy():
		EventBus.toast_requested.emit("Already travelling — try again in a moment.", "warn")
		return
	_close_all_menus()
	SceneRouter.go_to_planet(planet_id)


# ============================================================================= actions: rocket parts
## Directly sets GameState.rocket_parts (fit_rocket_part only appends, so it cannot unfit) and emits
## the same signal both `fit_rocket_part` and `GameState.from_dict` emit — the one thing
## RocketModel.refresh_finish() and PadDestinationPicker listen for.
func _set_rocket_parts(n: int) -> void:
	n = clampi(n, 0, CampaignData.PARTS.size())
	var ids: Array = []
	for i in n:
		ids.append(CampaignData.PARTS[i].get("id", ""))
	GameState.rocket_parts = ids
	EventBus.rocket_parts_changed.emit(GameState.rocket_parts.size())
	EventBus.toast_requested.emit("Rocket parts: %d/%d" % [n, CampaignData.PARTS.size()], "star")


# ============================================================================= actions: day
func _add_day(delta: int) -> void:
	GameState.day_count = maxi(1, GameState.day_count + delta)
	EventBus.toast_requested.emit("Day %d" % GameState.day_count, "check")


# ============================================================================= actions: gates
func _set_campaign_active(on: bool) -> void:
	GameState.campaign_active = on
	EventBus.campaign_changed.emit()
	EventBus.toast_requested.emit("Campaign active: %s" % str(on), "star")


func _set_story_done(on: bool) -> void:
	GameState.story_done = on
	EventBus.campaign_changed.emit()
	EventBus.toast_requested.emit("Story finished: %s" % str(on), "star")


# ============================================================================= actions: cutscenes
## Instantiates CrashIntro directly rather than going through IntroDirector, so it never touches
## GameState.flags (IntroDirector._start_crash sets FLAG_CRASH; this does not) and can run again on
## the same save without the intro thinking it already happened. CrashIntro finds /root/World by
## absolute path itself (see its own header), so it works added anywhere in the tree — it bails out
## cleanly with a warning and `finished.emit(false)` if a piece it needs (Planet/Rocket/Player/
## CameraRig/Environment) is missing, which is why this is still guarded rather than assumed safe.
func _replay_crash() -> void:
	if _crash_busy:
		EventBus.toast_requested.emit("Crash intro is already playing.", "warn")
		return
	if not ResourceLoader.exists(CRASH_INTRO_SCRIPT):
		EventBus.toast_requested.emit("Crash intro: not in this build.", "warn")
		return
	var world := get_tree().root.get_node_or_null("World")
	if world == null:
		EventBus.toast_requested.emit("Fly into the game first — there's no world loaded.", "warn")
		return
	_crash_busy = true
	_close_all_menus()
	var crash: Node = load(CRASH_INTRO_SCRIPT).new()
	crash.name = "DevCrashIntro"
	crash.finished.connect(func(_skipped: bool) -> void:
		_crash_busy = false
		if is_instance_valid(crash):
			crash.queue_free())
	get_tree().root.add_child(crash)


## Fires the SAME public signal the build bench fires when it fits a part
## (`EventBus.rocket_part_fitted`, "starts the celebration" per event_bus.gd's own comment) rather
## than reaching into part_celebration.gd. The scene is home-only (src/world/world.gd), so this
## checks for the live node, not just the file, before doing anything.
func _play_celebration() -> void:
	if not ResourceLoader.exists(PART_CELEBRATION_SCENE):
		EventBus.toast_requested.emit("Part celebration: not in this build.", "warn")
		return
	var node := get_tree().root.get_node_or_null("World/PartCelebration")
	if node == null:
		EventBus.toast_requested.emit("Go to Home first — the celebration only runs there.", "warn")
		return
	_close_all_menus()
	EventBus.rocket_part_fitted.emit(str(CampaignData.PARTS[0].get("id", "part_zorp")))


# ============================================================================= actions: projects
## These write GameState.projects[npc_id] in exactly the shape project_system.gd's own header
## documents ("SAVED STATE") and call only GameState's public methods and EventBus's public
## signals — the same three effects `_start`/`_complete`/`_hand_over_part` have, without needing a
## live NPC and DialogueRunner to drive the real conversation. `project_system.gd` is never edited
## and never referenced by class name; every read of it goes through `ResourceLoader.exists()` +
## `load(path).call(...)`.
func _npc_name(npc_id: String) -> String:
	return str(NpcData.get_data(npc_id).get("display_name", npc_id.capitalize()))


func _project_definition(npc_id: String) -> Dictionary:
	if not ResourceLoader.exists(PROJECT_SYSTEM_PATH):
		return {}
	var d: Variant = load(PROJECT_SYSTEM_PATH).call("definition_for", npc_id)
	return d if typeof(d) == TYPE_DICTIONARY else {}


func _advance_project(npc_id: String) -> void:
	var d := _project_definition(npc_id)
	if d.is_empty():
		EventBus.toast_requested.emit("%s has no project in this build." % _npc_name(npc_id), "warn")
		return
	var st: Dictionary = GameState.projects.get(npc_id, {})
	if st.is_empty():
		GameState.projects[npc_id] = {"step": 0, "asked": false, "found": [], "markers": {},
			"days": [], "done": false, "started_day": GameState.day_count}
		EventBus.toast_requested.emit("%s's project started." % _npc_name(npc_id), "star")
	elif bool(st.get("done", false)):
		EventBus.toast_requested.emit("%s's project is already finished." % _npc_name(npc_id), "warn")
		_refresh_values()
		return
	else:
		var steps: Array = d.get("steps", [])
		var i := int(st.get("step", 0))
		var days: Array = st.get("days", [])
		days.append(GameState.day_count)
		st["days"] = days
		st["step"] = i + 1
		st["asked"] = false
		GameState.projects[npc_id] = st
		GameState.project_step_day[npc_id] = GameState.day_count
		GameState.add_friendship(npc_id, int((steps[i] as Dictionary).get("friendship", 5)) if i < steps.size() else 5)
		EventBus.project_step_completed.emit(npc_id, i)
		if i + 1 >= steps.size():
			_give_part(npc_id, d)
		else:
			EventBus.toast_requested.emit("%s: step %d of %d done." % [_npc_name(npc_id), i + 1, steps.size()], "check")
	EventBus.campaign_changed.emit()
	_refresh_values()


func _finish_project(npc_id: String) -> void:
	var d := _project_definition(npc_id)
	if d.is_empty():
		EventBus.toast_requested.emit("%s has no project in this build." % _npc_name(npc_id), "warn")
		return
	var st: Dictionary = GameState.projects.get(npc_id, {})
	if bool(st.get("done", false)):
		EventBus.toast_requested.emit("%s already gave you their part." % _npc_name(npc_id), "warn")
		return
	if st.is_empty():
		st = {"step": 0, "asked": false, "found": [], "markers": {}, "days": [],
			"done": false, "started_day": GameState.day_count}
	_give_part(npc_id, d, st)
	EventBus.campaign_changed.emit()
	_refresh_values()


## Shared tail of `_advance_project` (reaching the last step) and `_finish_project` (skip straight
## to the end): marks the project done and hands the part into the bag exactly as
## `_hand_over_part` does — `GameState.add_item` + `EventBus.project_completed` — guarded so a
## second call (a stray double-tap on "Finish") can never hand out two parts.
func _give_part(npc_id: String, d: Dictionary, st_in: Dictionary = {}) -> void:
	var st: Dictionary = st_in if not st_in.is_empty() else GameState.projects.get(npc_id, {})
	if bool(st.get("done", false)):
		return
	var steps: Array = d.get("steps", [])
	st["step"] = steps.size()
	st["asked"] = false
	st["done"] = true
	if not st.has("started_day"):
		st["started_day"] = GameState.day_count
	GameState.projects[npc_id] = st
	var part_id := str(d.get("part", ""))
	if part_id == "":
		return
	GameState.add_item(part_id)
	EventBus.project_completed.emit(npc_id, part_id)
	EventBus.toast_requested.emit("You got the %s!" % str(d.get("part_name", part_id)), "star")


func _reset_project(npc_id: String) -> void:
	GameState.projects.erase(npc_id)
	GameState.project_step_day.erase(npc_id)
	EventBus.campaign_changed.emit()
	EventBus.toast_requested.emit("%s's project reset." % _npc_name(npc_id), "warn")
	_refresh_values()


# ============================================================================= input
func _process(delta: float) -> void:
	if not is_open:
		return
	_cooldown -= delta
	if _cooldown > 0.0:
		return
	var step := _repeat.poll(delta)
	if step.y != 0:
		_scroll.scroll_vertical += int(34.0 * float(step.y))
	if UIFocus.cancel_pressed():
		UIStyle.play_cancel()
		close()


func _input(event: InputEvent) -> void:
	if is_open:
		UIFocus.consume_nav_event(self, event)


## Test hooks below, same evidence standard as pause_menu.gd's `debug_tap_ui_mode`: a REAL
## InputEventMouseButton through `MobileUI.synth_tap` / `Input.parse_input_event`, not
## `Input.action_press` (sends no InputEvent) and not calling a row's handler function directly.
## They find a row by the exact text of its own leading label, so a Director probe taps the same
## pixel a finger would rather than reaching into the script.
func _row_by_label(label_text: String) -> HBoxContainer:
	for c in _list.get_children():
		if c is HBoxContainer and c.get_child_count() > 0 and c.get_child(0) is Label \
				and (c.get_child(0) as Label).text == label_text:
			return c
	return null


func _button_in(row: Control, button_text: String) -> Button:
	if row == null:
		return null
	for c in row.get_children():
		if c is Button and (c as Button).text == button_text:
			return c
	return null


## `control`'s position relative to `_list`, by walking the parent chain and summing local
## `.position` — NOT `control.get_global_rect()`. Measured: immediately after a caller sets
## `_scroll.scroll_vertical` to bring a control into view, that control's global rect (and its
## ancestors' `.position`, which a ScrollContainer offsets by the negative scroll amount) still
## reflects the PRE-scroll layout for one frame, so a tap computed from it can land hundreds of
## pixels off on a long list — first caught here with "Campaign active"/"Story finished" (below the
## fold on a ~30-row list) silently missing every time while shallower rows worked.
func _list_relative_position(control: Control) -> Vector2:
	var pos := Vector2.ZERO
	var node: Control = control
	while node != null and node != _list and node != self:
		pos += node.position
		node = node.get_parent() as Control
	return pos


## Scrolls `control` to the middle of the visible well and returns the (clamped) scroll offset
## actually used, so a caller computes the tap position from THIS value rather than re-reading
## `_scroll.scroll_vertical` — same one-frame staleness as above.
func _scroll_into_view(control: Control) -> int:
	var pos := _list_relative_position(control)
	var target: float = pos.y + control.size.y * 0.5 - _scroll.size.y * 0.5
	target = clampf(target, 0.0, maxf(0.0, _list.size.y - _scroll.size.y))
	_scroll.scroll_vertical = int(target)
	return _scroll.scroll_vertical


## Real tap (`MobileUI.synth_tap`) at `local_point` in `control`'s own local space: scrolls the
## control into view first, then computes the screen position from `_list_relative_position` and
## `_scroll`'s own (scroll-stable) global rect — never from `control.get_global_rect()`.
func _tap_point(control: Control, local_point: Vector2) -> void:
	var target_v := _scroll_into_view(control)
	var pos := _list_relative_position(control)
	var p := _scroll.get_global_rect().position + Vector2(pos.x, pos.y - float(target_v)) + local_point
	MobileUI.synth_tap(p)


## Real tap at `control`'s own centre.
func _tap_control(control: Control) -> void:
	_tap_point(control, control.size * 0.5)


## Taps the button with `button_text` on the row whose label reads `label_text` — covers every
## planet row ("Go"), the day stepper ("-1"/"+1"/"+7"), both currency rows ("+10"/"+50"/"Clear")
## and both cutscene rows ("Play").
func debug_tap_row_button(label_text: String, button_text: String) -> bool:
	var b := _button_in(_row_by_label(label_text), button_text)
	if b == null:
		return false
	_tap_control(b)
	return true


## Taps the ToggleSwitch on the row whose label reads `label_text` ("Campaign active" / "Story
## finished").
func debug_tap_gate(label_text: String) -> bool:
	var row := _row_by_label(label_text)
	if row == null:
		return false
	for c in row.get_children():
		if c is ToggleSwitch:
			_tap_control(c as ToggleSwitch)
			return true
	return false


## Taps segment `i` (0..CampaignData.PARTS.size()) of the rocket-parts SegmentedControl, the same
## shape as pause_menu.gd's `debug_tap_ui_mode`.
func debug_tap_parts(i: int) -> bool:
	if _parts_seg == null or i < 0 or i >= _parts_seg.options.size():
		return false
	_tap_point(_parts_seg, _parts_seg._segment_rect(i).get_center())
	return true


## Taps "Start / Advance", "Finish + give part" or "Reset" on `npc_id`'s project block, matched by
## its own name label (a project block has no single row-leading label, so `_row_by_label` does not
## reach it). Real tap, same as every other `debug_tap_*` here.
func debug_tap_project_button(npc_id: String, button_text: String) -> bool:
	var want := _npc_name(npc_id)
	for block in _list.get_children():
		if not (block is VBoxContainer) or block.get_child_count() < 2:
			continue
		var head := block.get_child(0)
		if not (head is HBoxContainer) or head.get_child_count() == 0 or not (head.get_child(0) is Label):
			continue
		if (head.get_child(0) as Label).text != want:
			continue
		var buttons := block.get_child(1)
		var b := _button_in(buttons as Control, button_text)
		if b == null:
			return false
		_tap_control(b)
		return true
	return false


## One-line state dump for a Director probe to assert against.
func debug_report(tag: String = "") -> void:
	print("DEVMENU %s open=%s parts=%d day=%d scrap=%d stardust=%d campaign=%s story_done=%s" % [
		tag, str(is_open), GameState.rocket_part_count(), GameState.day_count, GameState.scrap,
		GameState.stardust, str(GameState.campaign_active), str(GameState.story_done)])


## Diagnostic only (prints, changes nothing): CampaignData.planet_in_range for every planet, so a
## Director probe can show the picker's range actually followed a rocket-parts change without
## walking to the pad and opening the real picker.
func debug_range_report(tag: String = "") -> void:
	var bits: Array = []
	for pid: String in GameState.PLANET_IDS:
		bits.append("%s=%s(need %d)" % [pid, str(CampaignData.planet_in_range(pid)), CampaignData.parts_needed_for(pid)])
	print("DEVMENU_RANGE %s gates_on=%s parts=%d %s" % [
		tag, str(CampaignData.gates_on()), GameState.rocket_part_count(), " ".join(bits)])
