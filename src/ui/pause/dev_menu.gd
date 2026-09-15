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
## the shipped build on purpose (the user wants it on their phone), and it is hidden, not disabled.
##
## PHASE 5 REBUILD (docs/PHASE5_SPEC.md, docs/BUILD_PLAN.md Phase 5, DEV builder). Replaces the old
## single 30-row scrolling list with six tabs (Status, Story, Friends, Games, World, Perf), each with
## collapsible sections, per the phase5 inputs' `dev_audit.md` proposal and `dev_gaps.md`'s fixes to
## it. EVERY ROW STILL EDITS LIVE GAME STATE THROUGH THE SAME PUBLIC SIGNALS/METHODS THE REAL GAME
## USES — nothing here writes the save file except the one row that says so ("Save game now").
##
## A SINGLE HOOK PATTERN CARRIES EVERY CROSS-BUILDER ROW: `_hook_target(path, method,
## get_or_create)` resolves either a static call on an unlinked script or an instance call on a live
## singleton, and returns null when the file or method is missing — `_hook_row()` then builds the row
## either active or greyed out with "needs <file>: <method>", so this menu opens and works correctly
## whether K, HOOKS, HEAT-WEB, HEAT-LOAD, M1, M2, L1, L2, K2 or G have landed yet or not (BUILD_PLAN's
## own order has this builder's build starting before any of them). `_hook_target`'s two dispatch
## paths are a MEASURED fact, not a guess: `tests/director/dev_hook_probe.gd` shows
## `GDScript.has_method()` is true for a STATIC function on an unlinked script and false for an
## instance one — so a static hook (finale_state.gd, visitor_system.gd's `dev_force_visit`) is called
## straight on the loaded script, and an instance hook (ProjectSystem's `dev_set_step`,
## FavorSystem's `dev_offer_and_accept`) goes through a named "get or create" static first.
##
## PHASE 2/3/4 GUARD, unchanged from before Phase 5: this file never types a variable as
## ProjectSystem, FavorSystem, VisitorSystem, MinigameSystem or ReplayBoard — every call into an
## optional system goes through `ResourceLoader.exists()` + `load(path).call(...)`, so it still
## PARSES with those files removed. The same `_hook_target` used for Phase 5's new cross-builder
## hooks does exactly this for the older optional systems too — one mechanism, not two.
##
## ROW-DEFINITION DATA. `_build_tabs()` is the only place that lists what is in the menu; a tab's
## content is built ONCE per DevMenu instance (a fresh instance per world — see `open_over`), inside
## a numbered `_build_<tab>_tab()` method, using the small row helpers below (`_row`,
## `_add_action_row`, `_hook_row`, `_section`, ...) — never a hand-built Control tree.
##
## UI STATE SURVIVES A PLANET JUMP THROUGH ENGINE META (`UI_STATE_META`, the same idiom
## replay_board.gd's own `DEV_SHOW_ALL_META` already uses for exactly this reason: a plain script var
## would be lost the moment this Control is freed and rebuilt fresh on the next world). It remembers
## the selected tab and which sections are open; the SCROLL position per tab is restored deferred
## plus one process_frame on open — the exact fix already proven below for tap coordinates
## (`_tap_point`'s own comment): a fresh `scroll_vertical` write has not propagated to container
## `.position` values on the same frame it is set.

signal closed

const PANEL_WIDTH := 560.0
## MOBILE (matches pause_menu.gd's own R2.10 reasoning): wider, because the mobile Theme pads every
## pill to a thumb-sized target and this menu's rows are busier than the settings page's.
const PANEL_WIDTH_MOBILE := 740.0
const BODY_HEIGHT := 420.0
const BODY_HEIGHT_MOBILE := 480.0
const MODAL_NAME := "dev_menu"
const NODE_NAME := "DevMenu"
## Engine meta key for the remembered tab / open sections / per-tab scroll (dev_audit.md section 3,
## "Safety": "Engine meta `astro_dev_menu_ui` remembers ... It survives a planet jump, like
## DEV_SHOW_ALL_META").
const UI_STATE_META := "astro_dev_menu_ui"

## Phase 2 files. Guarded with ResourceLoader.exists() everywhere they are used; never referenced
## as a static type.
const PROJECT_SYSTEM_PATH := "res://src/projects/project_system.gd"
const PART_CELEBRATION_SCENE := "res://src/campaign/part_celebration.tscn"
const CRASH_INTRO_SCRIPT := "res://src/onboarding/crash_intro.gd"
## Phase 3 mini-games (docs/CORE_LOOP.md "Mini-games instead of fetch trips"). Same guard: the path
## is checked before it is loaded, and MinigameSystem is never named as a static type here.
const MINIGAME_SYSTEM_PATH := "res://src/minigames/minigame_system.gd"
## One row per kind in MinigameSystem.GAMES. A kind whose script is not in this build still gets its
## row; pressing it says "not built yet" (`_play_minigame`). Phase 3 added guide, hunt and call
## (docs/CORE_LOOP.md "More mini-games, one per neighbour").
const MINIGAME_NAMES := {
	"catch": "Catch the runaways", "rings": "Ring run",
	"guide": "Guide them home", "hunt": "Signal hunt", "call": "Call and response",
}
## Phase 3 file. Guarded like everything else this menu reaches into — never a static preload, so
## this file keeps parsing in a build with `src/minigames/**` removed.
const CATCH_GAME_PATH := "res://src/minigames/catch_game.gd"
## Fallback count for a kind missing from MINIGAME_DEV_COUNTS.
const MINIGAME_DEV_COUNT := 5
## How many of each a dev round asks for. catch 5 is Bolt's own step (src/projects/data/bolt.gd), and
## rings stays at the 5 hoops this menu has always asked for. guide 5, hunt 3 and call 3 follow
## docs/CORE_LOOP.md: "Find three" for the hunt, and a call-and-response that grows by one per round.
## KEPT EXACTLY (replay_board.gd's `_add_dev_entries` reads this by reflection — see this file's own
## header — never renamed or removed even though this menu's own layout changed completely).
const MINIGAME_DEV_COUNTS := {"catch": 5, "rings": 5, "guide": 5, "hunt": 3, "call": 3}
## The world each kind belongs to in the story (CORE_LOOP's one-game-per-neighbour table). Read by the
## game board's dev "show every game" switch for a game no project uses yet. KEPT EXACTLY, same reason.
const MINIGAME_HOMES := {"catch": "bolt", "rings": "zorp", "guide": "fen", "hunt": "grig", "call": "vela"}
## Phase 3a builder BOARD. Guarded like everything else here.
const REPLAY_BOARD_PATH := "res://src/minigames/replay_board.gd"
## Phase 4 builder H: friends visiting your crash site. By path only, so this file parses without it.
const VISITOR_SYSTEM_PATH := "res://src/campaign/visitor_system.gd"
## Phase 4 favours. By path only, same reason.
const FAVOR_SYSTEM_PATH := "res://src/favors/favor_system.gd"
## Onboarding. By path only — HOOKS adds `dev_replay_call` this phase; the file itself has shipped
## since Phase 1, but this menu never assumes any particular method on it exists.
const INTRO_DIRECTOR_PATH := "res://src/onboarding/intro_director.gd"
## Phase 5 K builder's contract, docs/PHASE5_SPEC.md §10 "Debug API" — every method name below is
## quoted verbatim from that section.
const FINALE_STATE_PATH := "res://src/campaign/finale_state.gd"

## HOOKS's four Phase 5 files (docs/BUILD_PLAN.md), reached the same guarded way as everything else.
## `player.gd`/`camera_rig.gd` are core files always present — the guard here is on the METHOD
## (`dev_teleport`, `dev_mark_met`, ...), not the file, exactly like `_hook_target`'s own doc explains.
const PLAYER_SCRIPT_PATH := "res://src/player/player.gd"

const FINALE_ROWS: Array[Dictionary] = [
	{"label": "Reset before the finale", "method": "debug_reset_before_finale", "confirm": ""},
	{"label": "The Professor's call", "method": "debug_start_call", "confirm": ""},
	{"label": "Go to the meeting", "method": "debug_start_meeting", "confirm": ""},
	{"label": "Show the choice", "method": "debug_start_choice", "confirm": ""},
	{"label": "Fly into the asteroid", "method": "debug_start_sendoff", "confirm": ""},
	{"label": "Get the new ship", "method": "debug_start_gift", "confirm": ""},
	{"label": "Jump to after the story", "method": "debug_after_story",
		"confirm": "Jump straight to after the story? All parts, every project done, story finished, and the new ship."},
]

const TAB_NAMES := ["Status", "Story", "Friends", "Games", "World", "Perf"]

var is_open := false

var _backdrop: ColorRect
var _panel: PanelContainer
var _close_button: Button
var _result_label: Label
var _repeat := UIFocus.NavRepeat.new()
var _cooldown := 0.0
## The pause menu to reopen when this closes (JournalPanel's own pattern). Duck-typed, not typed
## PauseMenu, for the same class-cycle reason journal_panel.gd gives.
var _reopen_pause: Node
var _paused_tree := false
var _confirm: ConfirmPopup

## ------------------------------------------------------------------------- tabs
var _tab_bar: GridContainer
var _tab_buttons: Dictionary = {} # tab name -> Button
var _tab_scrolls: Dictionary = {} # tab name -> ScrollContainer
var _tab_lists: Dictionary = {} # tab name -> VBoxContainer (the tab's own row list)
var _current_tab: String = "Status"
## {tab_name: {section_key: bool}} — restored from / written to Engine meta.
var _section_state: Dictionary = {}

## Live-value controls this menu keeps in sync with GameState, refreshed on open, on tab switch and
## after every action (`_refresh_values`).
var _parts_seg: SegmentedControl
var _finish_seg: SegmentedControl
var _day_label: Label
var _scrap_label: Label
var _stardust_label: Label
var _campaign_toggle: ToggleSwitch
var _story_toggle: ToggleSwitch
var _board_all_toggle: ToggleSwitch
var _status_label: Label
var _status_t := 0.0
## npc_id -> the status Label in that neighbour's Friends block.
var _project_labels: Dictionary = {}
## npc_id -> the "would offer today?" Label in the Favours section.
var _favor_labels: Dictionary = {}

## ------------------------------------------------------------------------- Perf tab controls
var _perf_overlay_toggle: ToggleSwitch
var _perf_scale_seg: SegmentedControl
var _perf_particles_toggle: ToggleSwitch
var _perf_omni_toggle: ToggleSwitch
var _perf_neighbours_toggle: ToggleSwitch
var _perf_burn_toggle: ToggleSwitch
var _perf_saver_row_note: Label
var _perf_shadows_row_note: Label
var _perf_warmup_row_note: Label

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
	_load_ui_state()
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
	box.add_theme_constant_override("separation", 8)
	_panel.add_child(box)
	box.add_child(UIStyle.make_label("Developer Menu", "Title", HORIZONTAL_ALIGNMENT_CENTER))
	var warn := UIStyle.make_label("Nothing here saves — Pause still has the real Save Game.",
		"Soft", HORIZONTAL_ALIGNMENT_CENTER)
	warn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(warn)

	_build_tab_bar(box)

	for tab_name: String in TAB_NAMES:
		var well := PanelContainer.new()
		well.name = tab_name + "Well"
		well.theme_type_variation = "Inset"
		well.custom_minimum_size = Vector2(0.0, _body_height())
		well.visible = (tab_name == _current_tab)
		box.add_child(well)
		var scroll := ScrollContainer.new()
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.follow_focus = true
		well.add_child(scroll)
		var list := VBoxContainer.new()
		list.add_theme_constant_override("separation", 8)
		list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.add_child(list)
		_tab_scrolls[tab_name] = scroll
		_tab_lists[tab_name] = list

	_result_label = UIStyle.make_label("Ready.", "Small", HORIZONTAL_ALIGNMENT_CENTER)
	_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_result_label)

	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(footer)
	_close_button = UIStyle.make_button("Back", "PillPrimary", MobileUI.pick(180.0, 260.0))
	if MobileUI.is_mobile():
		_close_button.custom_minimum_size.y = MobileUI.MIN_TOUCH
	_close_button.pressed.connect(close)
	footer.add_child(_close_button)

	_confirm = ConfirmPopup.new()
	_confirm.name = "Confirm"
	add_child(_confirm)

	_build_status_tab(_tab_lists["Status"])
	_build_story_tab(_tab_lists["Story"])
	_build_friends_tab(_tab_lists["Friends"])
	_build_games_tab(_tab_lists["Games"])
	_build_world_tab(_tab_lists["World"])
	_build_perf_tab(_tab_lists["Perf"])

	_apply_tab_visuals()


func _panel_width() -> float:
	return MobileUI.pick(PANEL_WIDTH, PANEL_WIDTH_MOBILE)


func _body_height() -> float:
	return MobileUI.pick(BODY_HEIGHT, BODY_HEIGHT_MOBILE)


# ============================================================================= tab bar
## 2x3 on a phone (dev_audit.md section 3: "A 6-tab bar (a SegmentedControl, in two rows of 3 on a
## phone)"); a GridContainer with 3 columns gives that shape on any width without special-casing it.
func _build_tab_bar(parent: VBoxContainer) -> void:
	_tab_bar = GridContainer.new()
	_tab_bar.columns = 3
	_tab_bar.add_theme_constant_override("h_separation", 6)
	_tab_bar.add_theme_constant_override("v_separation", 6)
	parent.add_child(_tab_bar)
	for tab_name: String in TAB_NAMES:
		var b := UIStyle.make_button(tab_name, "Pill")
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if MobileUI.is_mobile():
			b.custom_minimum_size.y = MobileUI.MIN_TOUCH
		b.pressed.connect(func() -> void: _select_tab(tab_name))
		_tab_bar.add_child(b)
		_tab_buttons[tab_name] = b


func _select_tab(tab_name: String) -> void:
	if not TAB_NAMES.has(tab_name):
		return
	_current_tab = tab_name
	for t: String in TAB_NAMES:
		(_tab_scrolls[t].get_parent() as Control).visible = (t == tab_name)
	_apply_tab_visuals()
	_save_ui_state()
	_refresh_values()


func _apply_tab_visuals() -> void:
	for t: String in TAB_NAMES:
		var b: Button = _tab_buttons[t]
		b.theme_type_variation = "PillPrimary" if t == _current_tab else "Pill"


# ============================================================================= collapsible sections
## Appends a collapsible section to `tab_name`'s list and returns its (initially maybe-hidden) body
## container — every row builder below takes that body as its `parent`. Only the first section a tab
## ever builds starts open by default (dev_audit.md: "Only the first section starts open"); after
## that, the remembered Engine-meta state wins.
func _section(tab_name: String, key: String, title: String) -> VBoxContainer:
	var list: VBoxContainer = _tab_lists[tab_name]
	var default_open := list.get_child_count() == 0
	var open := bool((_section_state.get(tab_name, {}) as Dictionary).get(key, default_open))
	if list.get_child_count() > 0:
		list.add_child(HSeparator.new())
	var header := UIStyle.make_button(_section_glyph(open) + " " + title, "Pill")
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.alignment = HORIZONTAL_ALIGNMENT_LEFT
	if MobileUI.is_mobile():
		header.custom_minimum_size.y = MobileUI.MIN_TOUCH
	header.set_meta("section_key", key)
	list.add_child(header)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	body.visible = open
	list.add_child(body)
	header.pressed.connect(func() -> void:
		var now_open := not body.visible
		body.visible = now_open
		header.text = _section_glyph(now_open) + " " + title
		_set_section_open(tab_name, key, now_open)
		if now_open:
			call_deferred("_scroll_header_into_view", tab_name, header))
	return body


func _section_glyph(open: bool) -> String:
	return "v" if open else ">"


func _set_section_open(tab_name: String, key: String, open: bool) -> void:
	if not _section_state.has(tab_name):
		_section_state[tab_name] = {}
	(_section_state[tab_name] as Dictionary)[key] = open
	_save_ui_state()


## `ScrollContainer.ensure_control_visible()` — Godot's own, engine-native version of "scroll this
## into view" — rather than this file's own hand-rolled position math (see `_tap_point`'s own
## comment for why: that math read a genuinely stale value here, one real miss confirmed by
## `tests/director/dev_menu_probe.gd`).
func _scroll_header_into_view(tab_name: String, header: Control) -> void:
	await get_tree().process_frame
	var scroll: ScrollContainer = _tab_scrolls[tab_name]
	scroll.ensure_control_visible(header)


# ============================================================================= UI-state persistence
func _load_ui_state() -> void:
	if not Engine.has_meta(UI_STATE_META):
		return
	var st: Variant = Engine.get_meta(UI_STATE_META)
	if typeof(st) != TYPE_DICTIONARY:
		return
	var d: Dictionary = st
	var tab := str(d.get("tab", "Status"))
	if TAB_NAMES.has(tab):
		_current_tab = tab
	var sections: Variant = d.get("sections", {})
	_section_state = sections if sections is Dictionary else {}


func _save_ui_state() -> void:
	var scrolls := {}
	for t: String in TAB_NAMES:
		if _tab_scrolls.has(t):
			scrolls[t] = (_tab_scrolls[t] as ScrollContainer).scroll_vertical
	Engine.set_meta(UI_STATE_META, {"tab": _current_tab, "sections": _section_state, "scroll": scrolls})


# ============================================================================= open / close
func open(pause_tree: bool = true) -> void:
	if is_open:
		return
	is_open = true
	visible = true
	_cooldown = 0.2
	_repeat.reset()
	_apply_tab_visuals()
	for t: String in TAB_NAMES:
		(_tab_scrolls[t].get_parent() as Control).visible = (t == _current_tab)
	_refresh_values()
	_paused_tree = pause_tree
	if pause_tree:
		get_tree().paused = true
	EventBus.ui_modal_opened.emit(MODAL_NAME)
	UIStyle.play_open()
	_backdrop.modulate.a = 0.0
	create_tween().tween_property(_backdrop, "modulate:a", 1.0, 0.18)
	# DEFERRED, not called directly — see the file header's own note (item 49's stale-layout class of
	# bug): a freshly-built panel's minimum size has not settled on the same frame content was added.
	call_deferred("_after_open_layout")


func _after_open_layout() -> void:
	_relayout()
	UIStyle.pop_in(_panel)
	UIFocus.focus(_close_button)
	_restore_scroll()


## Scroll restore is its OWN deferred-plus-one-frame step, not folded into `_after_open_layout`
## (which itself already runs `call_deferred`) — MEASURED, not assumed: `_relayout()`'s
## `_panel.reset_size()` on the same call still leaves the Inset wells at their pre-layout size for
## one more process_frame (the identical class of bug this file's `_tap_point` comment already
## documents for tap coordinates), so a scroll value set before that frame lands against the wrong
## clamp range and silently gets clamped back to 0.
func _restore_scroll() -> void:
	await get_tree().process_frame
	if not Engine.has_meta(UI_STATE_META):
		return
	var st: Variant = Engine.get_meta(UI_STATE_META)
	if typeof(st) != TYPE_DICTIONARY:
		return
	var scrolls: Variant = (st as Dictionary).get("scroll", {})
	if scrolls is Dictionary:
		for t: String in (scrolls as Dictionary):
			if _tab_scrolls.has(t):
				(_tab_scrolls[t] as ScrollContainer).scroll_vertical = int((scrolls as Dictionary)[t])


func close() -> void:
	if not is_open:
		return
	is_open = false
	_save_ui_state()
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


# ============================================================================= shared row helpers
func _row(parent: VBoxContainer, label_text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var l := UIStyle.make_label(label_text, "")
	l.custom_minimum_size = Vector2(MobileUI.pick(150.0, 190.0), 0.0)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(l)
	parent.add_child(row)
	return row


func _add_note(parent: VBoxContainer, text: String) -> Label:
	var l := UIStyle.make_label(text, "Small")
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(l)
	return l


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


func _add_action_row(parent: VBoxContainer, label_text: String, cb: Callable, button_text: String = "Go") -> Button:
	var row := _row(parent, label_text)
	var b := _touch_button(button_text)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.pressed.connect(cb)
	row.add_child(b)
	return b


func _add_currency_row(parent: VBoxContainer, label_text: String, add_cb: Callable, clear_cb: Callable) -> Label:
	var row := _row(parent, label_text)
	var val := UIStyle.make_label("", "")
	val.custom_minimum_size = Vector2(MobileUI.pick(70.0, 90.0), 0.0)
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(val)
	row.add_child(_small_button("+10", func() -> void: add_cb.call(10)))
	row.add_child(_small_button("+50", func() -> void: add_cb.call(50)))
	row.add_child(_small_button("Clear", func() -> void: clear_cb.call()))
	return val


func _set_result(text: String) -> void:
	if _result_label != null:
		_result_label.text = text


func _finish_action(text: String, icon: String = "star") -> void:
	_set_result(text)
	EventBus.toast_requested.emit(text, icon)
	_refresh_values()


## Cancel-default confirm (dev_audit.md: "Destructive rows ask first ... with Cancel the default").
func _confirm_ask(text: String) -> bool:
	return await _confirm.ask(text, "Do it", "Cancel", -1, false)


# ============================================================================= the hook mechanism
## Resolves a cross-builder hook: a static call (`script.call(method, args)`) when `method` exists as
## a static function on the UNLINKED script (measured true for statics, false for instance methods —
## see this file's own header and `tests/director/dev_hook_probe.gd`), otherwise an instance call
## reached through `get_or_create_method` (e.g. "get_or_create", "find") when the file exists but the
## static check fails. Returns the callable target (script or instance) or null when the row should
## grey out.
func _hook_target(path: String, method: String, get_or_create_method: String = "") -> Variant:
	if not ResourceLoader.exists(path):
		return null
	var script := load(path) as GDScript
	if script == null:
		return null
	if script.has_method(method):
		return script
	if get_or_create_method == "":
		return null
	if not script.has_method(get_or_create_method):
		return null
	var inst: Variant = script.call(get_or_create_method)
	if inst is Object and (inst as Object).has_method(method):
		return inst
	return null


func _hook_available(path: String, method: String, get_or_create_method: String = "") -> bool:
	return _hook_target(path, method, get_or_create_method) != null


## Builds an active row that calls the hook, or (when missing) a single grey note row reading
## "<label> — needs <file>: <method>" (dev_audit.md's exact phrasing). `args` may be a plain Array
## (fixed arguments) or a Callable returning an Array (computed at press time). Non-empty
## `confirm_text` asks first, Cancel-default. The hook's return value becomes the result/toast text
## when it is a String; otherwise a generic "<label>: done." — most Phase 5 hooks are documented to
## "return toast text" (docs/PHASE5_SPEC.md §10), so this is the common case, not a fallback guess.
func _hook_row(parent: VBoxContainer, label_text: String, path: String, method: String,
		args: Variant = [], get_or_create_method: String = "", button_text: String = "Go",
		confirm_text: String = "", leaves_gameplay: bool = false) -> void:
	if not _hook_available(path, method, get_or_create_method):
		_add_note(parent, "%s — needs %s: %s" % [label_text, path.get_file(), method])
		return
	_add_action_row(parent, label_text, func() -> void:
		if confirm_text != "" and not await _confirm_ask(confirm_text):
			return
		var target: Variant = _hook_target(path, method, get_or_create_method)
		if target == null:
			_finish_action("%s: not available right now." % label_text, "warn")
			return
		var call_args: Array = args.call() if args is Callable else (args as Array)
		if leaves_gameplay:
			_close_all_menus()
		var result: Variant = target.callv(method, call_args)
		var text: String = result if result is String and (result as String) != "" \
			else "%s: done." % label_text
		if leaves_gameplay:
			EventBus.toast_requested.emit(text, "star")
		else:
			_finish_action(text), button_text)


# ============================================================================= STATUS tab
func _build_status_tab(list: VBoxContainer) -> void:
	var body := _section("Status", "live", "Live state (refreshes twice a second)")
	_status_label = UIStyle.make_label("", "Small")
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(_status_label)
	_add_action_row(body, "Reload this world", func() -> void:
		if SceneRouter.is_busy():
			EventBus.toast_requested.emit("Already travelling — try again in a moment.", "warn")
			return
		var pid := GameState.current_planet_id
		_close_all_menus()
		SceneRouter.go_to_planet(pid), "Reload")


func _status_text() -> String:
	var lines := PackedStringArray()
	lines.append("Planet: %s   Day %d, %.1fh" % [GameState.current_planet_id, GameState.day_count, GameState.time_of_day])
	lines.append("Parts %d/%d   finish stage %d   gates_on=%s" %
		[GameState.rocket_part_count(), CampaignData.PARTS.size(), CampaignData.finish_stage(), str(CampaignData.gates_on())])
	lines.append("campaign_active=%s  story_done=%s" % [str(GameState.campaign_active), str(GameState.story_done)])
	lines.append("intro: crash=%s greeted=%s done=%s" %
		[str(GameState.flag("intro_crash_done")), str(GameState.flag("intro_greeted")), str(GameState.flag("intro_done"))])
	if ResourceLoader.exists(VISITOR_SYSTEM_PATH):
		var rec: Variant = load(VISITOR_SYSTEM_PATH).call("record")
		if rec is Dictionary and not (rec as Dictionary).is_empty():
			lines.append("visit today: %s" % str((rec as Dictionary).get("npc", "-")))
	if ResourceLoader.exists(FAVOR_SYSTEM_PATH):
		var sys: Variant = load(FAVOR_SYSTEM_PATH).call("get_or_create")
		if sys is Node:
			var favs: Array = (sys as Node).call("active_favors_summary")
			for line: String in favs:
				lines.append("favour: " + line)
	if ResourceLoader.exists(PROJECT_SYSTEM_PATH):
		var psys: Variant = load(PROJECT_SYSTEM_PATH).call("get_or_create")
		if psys is Node:
			var proj: Array = (psys as Node).call("summary")
			for line: String in proj:
				lines.append("project: " + line)
	if ResourceLoader.exists(MINIGAME_SYSTEM_PATH):
		var ms: Variant = load(MINIGAME_SYSTEM_PATH).call("find")
		if ms is Node and bool((ms as Node).call("is_running")):
			var prog: Vector2i = (ms as Node).call("progress")
			lines.append("mini-game: %s owner=%s (%d/%d)" %
				[str((ms as Node).call("running_kind")), str((ms as Node).call("running_owner")), prog.x, prog.y])
	return "\n".join(lines)


# ============================================================================= STORY tab
func _build_story_tab(list: VBoxContainer) -> void:
	var start := _section("Story", "start", "Start")
	_add_action_row(start, "Fresh campaign (crash + call)", func() -> void:
		var msg := "Wipes decorations, friendships, favours, wardrobe, settings, your planet's " \
			+ "name and the day count, then starts a brand-new crash + call. This is NOT just " \
			+ "\"resets the campaign\" — it is everything on this save."
		if not await _confirm_ask(msg):
			return
		_close_all_menus()
		GameState.reset_new_game()
		SceneRouter.start_game()
		EventBus.toast_requested.emit("Fresh campaign started.", "star"), "Do it")
	_hook_row(start, "Radio call only", INTRO_DIRECTOR_PATH, "dev_replay_call", [], "", "Play")
	_hook_row(start, "Reset first-day hints", INTRO_DIRECTOR_PATH, "dev_reset_hints", [], "", "Reset",
		"Reset every first-day hint and re-arm the early tutorial beats?")

	var crash_call := _section("Story", "crash_call", "Crash + call (keeps your save)")
	_add_note(crash_call, "Campaign only. Plays the crash, then the radio call, without touching decorations, friendships or settings.")
	_add_action_row(crash_call, "Play crash + call", func() -> void:
		if not CampaignData.gates_on():
			EventBus.toast_requested.emit("Needs the campaign active and the story not finished.", "warn")
			return
		if not await _confirm_ask("Replay the crash and the radio call on THIS save?"):
			return
		GameState.flags.erase("intro_crash_done")
		GameState.flags.erase("intro_greeted")
		GameState.flags.erase("intro_done")
		GameState.current_planet_id = "home"
		GameState.previous_planet_id = ""
		_close_all_menus()
		SceneRouter.start_game()
		EventBus.toast_requested.emit("Crash + call armed — landing on home now.", "star"), "Play")

	var rocket := _section("Story", "rocket", "Rocket")
	var parts_row := _row(rocket, "Parts fitted")
	_parts_seg = SegmentedControl.new()
	var labels := PackedStringArray()
	for i in (CampaignData.PARTS.size() + 1):
		labels.append(str(i))
	_parts_seg.setup(labels, GameState.rocket_part_count())
	_parts_seg.selected.connect(func(i: int) -> void: _set_rocket_parts(i))
	_parts_seg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parts_row.add_child(_parts_seg)
	_add_action_row(rocket, "Fit next part + celebrate", _fit_next_part, "Fit")
	var finish_row := _row(rocket, "Preview finish 0-5")
	_finish_seg = SegmentedControl.new()
	var flabels := PackedStringArray()
	for i in 6:
		flabels.append(str(i))
	_finish_seg.setup(flabels, 0)
	_finish_seg.selected.connect(func(i: int) -> void: _preview_finish(i))
	_finish_seg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	finish_row.add_child(_finish_seg)
	_add_action_row(rocket, "Real finish (from parts fitted)", _real_finish, "Refresh")
	_add_action_row(rocket, "Parts into bag + 50 scrap", _stage_bench, "Stage")

	var gates := _section("Story", "gates", "Gates")
	var camp_row := _row(gates, "Campaign active")
	_campaign_toggle = ToggleSwitch.new()
	_campaign_toggle.toggled.connect(func(on: bool) -> void: _set_campaign_active(on))
	camp_row.add_child(_campaign_toggle)
	var story_row := _row(gates, "Story finished")
	_story_toggle = ToggleSwitch.new()
	_story_toggle.toggled.connect(func(on: bool) -> void: _set_story_done(on))
	story_row.add_child(_story_toggle)
	_add_note(gates, "Off under a Director run without --campaign.")

	var cutscenes := _section("Story", "cutscenes", "Cutscenes")
	_add_action_row(cutscenes, "Replay the crash intro", _replay_crash, "Play")
	if ResourceLoader.exists(PART_CELEBRATION_SCENE):
		_add_action_row(cutscenes, "Play a part celebration", _play_celebration, "Play")
	else:
		_add_note(cutscenes, "Part celebration: not in this build.")

	var finale := _section("Story", "finale", "Finale (docs/PHASE5_SPEC.md §10)")
	for row: Dictionary in FINALE_ROWS:
		_hook_row(finale, str(row["label"]), FINALE_STATE_PATH, str(row["method"]), [], "",
			"Go", str(row["confirm"]), true)


func _fit_next_part() -> void:
	var n := GameState.rocket_part_count()
	if n >= CampaignData.PARTS.size():
		_finish_action("All parts are already fitted.", "warn")
		return
	if get_tree().root.get_node_or_null("World/PartCelebration") == null \
			and ResourceLoader.exists(PART_CELEBRATION_SCENE):
		_finish_action("Go to Home first — the celebration only runs there.", "warn")
		return
	var part: Dictionary = CampaignData.PARTS[n]
	var part_id := str(part.get("id", ""))
	# shop_panel.gd:485-486's own path: fit the part, then fire the exact signal a real bench fit
	# fires, so part_celebration.gd's `_from_stage` sees a real change (part_celebration flaw 1).
	GameState.fit_rocket_part(part_id)
	EventBus.rocket_part_fitted.emit(part_id)
	_finish_action("Fitted the %s." % str(part.get("name", part_id)))


func _preview_finish(stage: int) -> void:
	var rocket := get_tree().root.get_node_or_null("World/Rocket")
	if rocket == null or not rocket.has_method("set_finish_stage"):
		_finish_action("No rocket on this world to preview.", "warn")
		return
	rocket.call("set_finish_stage", stage)
	_finish_action("Previewing finish stage %d." % stage)


func _real_finish() -> void:
	var rocket := get_tree().root.get_node_or_null("World/Rocket")
	if rocket == null or not rocket.has_method("refresh_finish"):
		_finish_action("No rocket on this world.", "warn")
		return
	rocket.call("refresh_finish")
	_finish_action("Refreshed the rocket's real finish.")


## For testing a real fit at the bench: puts every part not yet fitted into the bag, plus 50 scrap.
func _stage_bench() -> void:
	var added := 0
	for p: Dictionary in CampaignData.PARTS:
		var part_id := str(p.get("id", ""))
		if not GameState.rocket_parts.has(part_id):
			GameState.add_item(part_id)
			added += 1
	GameState.add_scrap(50)
	_finish_action("Bagged %d part(s) + 50 scrap for the bench." % added)


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
	_finish_action("Rocket parts: %d/%d" % [n, CampaignData.PARTS.size()])


# ============================================================================= actions: gates
func _set_campaign_active(on: bool) -> void:
	GameState.campaign_active = on
	EventBus.campaign_changed.emit()
	_finish_action("Campaign active: %s" % str(on))


func _set_story_done(on: bool) -> void:
	GameState.story_done = on
	EventBus.campaign_changed.emit()
	_finish_action("Story finished: %s" % str(on))


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


# ============================================================================= FRIENDS tab
func _build_friends_tab(list: VBoxContainer) -> void:
	if not ResourceLoader.exists(PROJECT_SYSTEM_PATH):
		var body := _section("Friends", "none", "Neighbour projects")
		_add_note(body, "Not in this build yet.")
	else:
		for p: Dictionary in CampaignData.PARTS:
			var npc_id := str(p.get("npc", ""))
			var body := _section("Friends", "npc_" + npc_id, _npc_name(npc_id))
			_add_project_block(body, npc_id)

	var favours := _section("Friends", "favours", "Favours")
	if not ResourceLoader.exists(FAVOR_SYSTEM_PATH):
		_add_note(favours, "Not in this build yet.")
	else:
		for p: Dictionary in CampaignData.PARTS:
			var npc_id: String = str(p.get("npc", ""))
			_add_favor_block(favours, npc_id)

	var visitors := _section("Friends", "visitors", "Visitors at your crash site — today only")
	if ResourceLoader.exists(VISITOR_SYSTEM_PATH):
		for p: Dictionary in CampaignData.PARTS:
			var visit_npc := str(p.get("npc", ""))
			if visit_npc != "":
				_add_action_row(visitors, "Visitor today: %s" % _npc_name(visit_npc),
					func() -> void: _force_visitor(visit_npc), "Go")
		_add_action_row(visitors, "Clear today's visit", _clear_visitor, "Clear")
		_hook_row(visitors, "Meet request", VISITOR_SYSTEM_PATH, "dev_mark_met", [], "", "Meet")
		_add_note(visitors, "Tap a visitor again to switch their game to a gift. To re-roll: Clear, then reload this world (Status tab).")
	else:
		_add_note(visitors, "Not in this build yet.")


func _add_project_block(parent: VBoxContainer, npc_id: String) -> void:
	var status := UIStyle.make_label("", "Small")
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(status)
	_project_labels[npc_id] = status

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	parent.add_child(buttons)
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

	var step_row := _row(parent, "Set up step")
	var step_seg := SegmentedControl.new()
	step_seg.setup(PackedStringArray(["1", "2", "3"]), 0)
	step_seg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	step_row.add_child(step_seg)
	var step_btn := _touch_button("Go")
	step_btn.pressed.connect(func() -> void:
		# The segmented labels are the PLAYER-FACING "1/2/3" (dev_audit.md's own wording); ProjectSystem
		# .dev_set_step's `i` is 0-based (its own header: `clampi(i, 0, steps.size() - 1)`, and its
		# result string prints `target + 1` to get back to "step 1/2/3") — so row "2" must pass 1, not 2.
		# Phase 5 DEVF fix (2026-09-14): round 1 passed the label straight through, one-indexing every
		# project a row past what it showed (row "2" set the step actually labelled "3").
		_dev_set_step(npc_id, int(step_seg.options[step_seg.index]) - 1)
		_refresh_values())
	step_row.add_child(step_btn)
	if not _hook_available(PROJECT_SYSTEM_PATH, "dev_set_step", "get_or_create"):
		step_btn.disabled = true
		_add_note(parent, "Set up step — needs project_system.gd: dev_set_step")

	_add_action_row(parent, "Unlock today's step", func() -> void:
		GameState.project_step_day.erase(npc_id)
		_finish_action("%s's step is unlocked for today." % _npc_name(npc_id)), "Unlock")
	_hook_row(parent, "Meet this step", PROJECT_SYSTEM_PATH, "dev_meet_step", [npc_id], "get_or_create", "Meet")
	_add_action_row(parent, "Take me there", func() -> void: _take_me_to_step(npc_id), "Go")

	var teleport_ok := _hook_available(PLAYER_SCRIPT_PATH, "dev_teleport")
	_add_action_row(parent, "To marker 1", func() -> void: _teleport_to_marker(npc_id), "Go") \
		.disabled = not teleport_ok
	if not teleport_ok:
		_add_note(parent, "To marker / place spot — needs player.gd: dev_teleport")
	else:
		_add_action_row(parent, "To place spot", func() -> void: _teleport_to_place_spot(npc_id), "Go")


func _dev_set_step(npc_id: String, step_number: int) -> void:
	var target: Variant = _hook_target(PROJECT_SYSTEM_PATH, "dev_set_step", "get_or_create")
	if target == null:
		_finish_action("Set up step: not available right now.", "warn")
		return
	var result: Variant = target.call("dev_set_step", npc_id, step_number)
	_finish_action(result if result is String and result != "" else "%s: step %d set up." % [_npc_name(npc_id), step_number])


func _take_me_to_step(npc_id: String) -> void:
	var d := _project_definition(npc_id)
	if d.is_empty():
		EventBus.toast_requested.emit("%s has no project in this build." % _npc_name(npc_id), "warn")
		return
	var st: Dictionary = GameState.projects.get(npc_id, {})
	var i := int(st.get("step", 0))
	var steps: Array = d.get("steps", [])
	var default_planet := str(NpcData.get_data(npc_id).get("planet", npc_id))
	var planet := default_planet
	if i < steps.size():
		planet = str((steps[i] as Dictionary).get("planet", default_planet))
	_jump_to(planet)


func _teleport_to_marker(npc_id: String) -> void:
	_teleport_via_project(npc_id, "marker_positions", "marker")


func _teleport_to_place_spot(npc_id: String) -> void:
	_teleport_via_project(npc_id, "place_spot_position", "place spot")


func _teleport_via_project(npc_id: String, method: String, kind_word: String) -> void:
	var player := _player_node()
	if player == null or not player.has_method("dev_teleport"):
		_finish_action("No player on this world to teleport.", "warn")
		return
	if not ResourceLoader.exists(PROJECT_SYSTEM_PATH):
		_finish_action("Neighbour projects: not in this build.", "warn")
		return
	var psys: Variant = load(PROJECT_SYSTEM_PATH).call("get_or_create")
	if not (psys is Node) or not (psys as Node).has_method(method):
		_finish_action("Not available right now.", "warn")
		return
	var pos: Variant = (psys as Node).call(method, npc_id)
	var dir: Vector3
	if pos is Array:
		if (pos as Array).is_empty():
			_finish_action("%s has no %s right now." % [_npc_name(npc_id), kind_word], "warn")
			return
		dir = (pos as Array)[0]
	elif pos is Vector3:
		dir = pos
	else:
		_finish_action("%s has no %s right now." % [_npc_name(npc_id), kind_word], "warn")
		return
	player.call("dev_teleport", dir)
	_finish_action("Teleported to %s's %s." % [_npc_name(npc_id), kind_word])


func _player_node() -> Node:
	return get_tree().get_first_node_in_group("player")


# ============================================================================= FRIENDS: favours
func _add_favor_block(parent: VBoxContainer, npc_id: String) -> void:
	var head := _row(parent, _npc_name(npc_id))
	var status := UIStyle.make_label("", "Small")
	status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(status)
	_favor_labels[npc_id] = status

	var kind_seg := SegmentedControl.new()
	kind_seg.setup(PackedStringArray(["fetch", "bring", "deliver", "play"]), 0)
	var kind_row := _row(parent, "Kind")
	kind_row.add_child(kind_seg)

	var offer_available := _hook_available(FAVOR_SYSTEM_PATH, "dev_offer_and_accept", "get_or_create")
	var offer_btn := _add_action_row(parent, "Favour now", func() -> void:
		_dev_offer_favor(npc_id, kind_seg.options[kind_seg.index]), "Offer")
	offer_btn.disabled = not offer_available
	if not offer_available:
		_add_note(parent, "Favour now — needs favor_system.gd: dev_offer_and_accept")
	_hook_row(parent, "Complete favour", FAVOR_SYSTEM_PATH, "dev_complete_active", [npc_id], "get_or_create", "Complete")
	_add_action_row(parent, "Clear favour-day lock", func() -> void:
		GameState.npc_data(npc_id)["last_favor_day"] = 0
		_finish_action("%s's favour-day lock is cleared." % _npc_name(npc_id)), "Clear")


func _dev_offer_favor(npc_id: String, kind: String) -> void:
	var target: Variant = _hook_target(FAVOR_SYSTEM_PATH, "dev_offer_and_accept", "get_or_create")
	if target == null:
		_finish_action("Favour now: not available right now.", "warn")
		return
	var result: Variant = target.call("dev_offer_and_accept", npc_id, kind)
	_finish_action("%s: %s favour offered." % [_npc_name(npc_id), kind])


func _favor_check_text(npc_id: String) -> String:
	if not ResourceLoader.exists(FAVOR_SYSTEM_PATH):
		return ""
	var sys: Variant = load(FAVOR_SYSTEM_PATH).call("get_or_create")
	if not (sys is Node) or not (sys as Node).has_method("can_offer"):
		return ""
	return "would offer today: %s" % str(bool((sys as Node).call("can_offer", npc_id)))


# ============================================================================= actions: visitors
func _force_visitor(npc_id: String) -> void:
	if not ResourceLoader.exists(VISITOR_SYSTEM_PATH):
		EventBus.toast_requested.emit("Visitors: not in this build.", "warn")
		return
	_finish_action(str(load(VISITOR_SYSTEM_PATH).call("dev_force_visit", npc_id)))


func _clear_visitor() -> void:
	if not ResourceLoader.exists(VISITOR_SYSTEM_PATH):
		EventBus.toast_requested.emit("Visitors: not in this build.", "warn")
		return
	_finish_action(str(load(VISITOR_SYSTEM_PATH).call("dev_clear_today")))


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
		_finish_action("%s's project started." % _npc_name(npc_id))
		return
	elif bool(st.get("done", false)):
		_finish_action("%s's project is already finished." % _npc_name(npc_id), "warn")
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
			_finish_action("%s: step %d of %d done." % [_npc_name(npc_id), i + 1, steps.size()])
	EventBus.campaign_changed.emit()
	_refresh_values()


func _finish_project(npc_id: String) -> void:
	var d := _project_definition(npc_id)
	if d.is_empty():
		EventBus.toast_requested.emit("%s has no project in this build." % _npc_name(npc_id), "warn")
		return
	var st: Dictionary = GameState.projects.get(npc_id, {})
	if bool(st.get("done", false)):
		_finish_action("%s already gave you their part." % _npc_name(npc_id), "warn")
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
	_finish_action("You got the %s!" % str(d.get("part_name", part_id)))


func _reset_project(npc_id: String) -> void:
	GameState.projects.erase(npc_id)
	GameState.project_step_day.erase(npc_id)
	EventBus.campaign_changed.emit()
	_finish_action("%s's project reset." % _npc_name(npc_id), "warn")


# ============================================================================= GAMES tab
func _build_games_tab(list: VBoxContainer) -> void:
	var play := _section("Games", "play", "Play here")
	if ResourceLoader.exists(MINIGAME_SYSTEM_PATH):
		for kind: String in MINIGAME_NAMES:
			_add_action_row(play, "Play: %s" % str(MINIGAME_NAMES[kind]).to_lower(),
				func() -> void: _play_minigame(kind), "Play")
	else:
		_add_note(play, "Not in this build yet.")

	var replay := _section("Games", "replay", "Replay trip — the real launch, landing, pay and fly-back")
	if ResourceLoader.exists(REPLAY_BOARD_PATH):
		for kind: String in MINIGAME_NAMES:
			_add_action_row(replay, "Replay trip: %s" % str(MINIGAME_NAMES[kind]).to_lower(),
				func() -> void: _replay_kind(kind), "Go")
	else:
		_add_note(replay, "Game board: not in this build yet.")

	var other := _section("Games", "other", "Running game")
	_add_action_row(other, "Win now (fakes the finish)", _win_minigame_now, "Win")
	_add_action_row(other, "Stop game", _stop_minigame, "Stop")

	var board := _section("Games", "board", "Game board on the Commons — for testing, not saved")
	if ResourceLoader.exists(REPLAY_BOARD_PATH):
		var board_row := _row(board, "Board lists all")
		_board_all_toggle = ToggleSwitch.new()
		_board_all_toggle.toggled.connect(func(on: bool) -> void: _set_board_show_all(on))
		board_row.add_child(_board_all_toggle)
		_add_note(board, "On: every game with a script is on the board, locked or not — stand-ins show as \"dev:<game>\".")
		_add_action_row(board, "Open board", _open_board, "Open")
		_add_action_row(board, "Reset today's replay pay", func() -> void:
			if not await _confirm_ask("Clear every \"already paid today\" flag for the game board?"):
				return
			var n := 0
			for k: String in GameState.flags.keys().duplicate():
				if k.begins_with("replay_paid_day:"):
					GameState.flags.erase(k)
					n += 1
			_finish_action("Cleared %d replay-pay flag(s)." % n), "Reset")
	else:
		_add_note(board, "Not in this build yet.")


## `catch_game.gd`'s own `PLANET_DEFAULT_FLAVOUR` table, read LIVE rather than copied — this file no
## longer keeps its own copy of that map. `ResourceLoader.exists` + `load` + `get_script_constant_map()`,
## never `preload`, so this file keeps parsing without `src/minigames/**` — falls back to "bolt" in
## that case, and for a planet the table doesn't list, the same default every per-planet flavour
## lookup in this project uses.
func _minigame_flavour_for(planet_id: String) -> String:
	if ResourceLoader.exists(CATCH_GAME_PATH):
		var script := load(CATCH_GAME_PATH) as GDScript
		var table: Variant = script.get_script_constant_map().get("PLANET_DEFAULT_FLAVOUR", {}) \
			if script != null else {}
		if table is Dictionary:
			return str((table as Dictionary).get(planet_id, "bolt"))
	return "bolt"


## Starts a mini-game on the CURRENT world through MinigameSystem's own public `start()`, with no
## project behind it - the point of the row is that the user can try one on their phone without
## playing a neighbour's project first. The owner is "dev:<kind>", which is deliberately NOT the
## project system's "project:" prefix, so its own refresh can never cancel this one.
func _play_minigame(kind: String) -> void:
	var pretty := str(MINIGAME_NAMES.get(kind, kind.capitalize()))
	if not ResourceLoader.exists(MINIGAME_SYSTEM_PATH):
		EventBus.toast_requested.emit("Mini-games: not in this build.", "warn")
		return
	var script: Variant = load(MINIGAME_SYSTEM_PATH)
	if not bool(script.call("has_game", kind)):
		EventBus.toast_requested.emit("%s: not built yet." % pretty, "warn")
		return
	var sys: Variant = script.call("get_or_create")
	if not (sys is Node):
		EventBus.toast_requested.emit("Fly into the game first — there's no world loaded.", "warn")
		return
	_close_all_menus()
	var ok: Variant = (sys as Node).call("start", kind, {
		"owner": "dev:" + kind,
		"count": int(MINIGAME_DEV_COUNTS.get(kind, MINIGAME_DEV_COUNT)),
		"flavour": _minigame_flavour_for(GameState.current_planet_id),
	})
	if not bool(ok):
		EventBus.toast_requested.emit("%s could not start here." % pretty, "warn")


func _win_minigame_now() -> void:
	if not ResourceLoader.exists(MINIGAME_SYSTEM_PATH):
		_finish_action("Mini-games: not in this build.", "warn")
		return
	var ms: Variant = load(MINIGAME_SYSTEM_PATH).call("find")
	if not (ms is Node) or not bool((ms as Node).call("is_running")):
		_finish_action("No mini-game is running.", "warn")
		return
	(ms as Node).call("report_finished", true)
	_finish_action("Reported a win (this is faked — it does not prove the real finish detection).")


func _stop_minigame() -> void:
	if not ResourceLoader.exists(MINIGAME_SYSTEM_PATH):
		_finish_action("Mini-games: not in this build.", "warn")
		return
	var ms: Variant = load(MINIGAME_SYSTEM_PATH).call("find")
	if not (ms is Node) or not bool((ms as Node).call("is_running")):
		_finish_action("No mini-game is running.", "warn")
		return
	(ms as Node).call("stop", "dev")
	_finish_action("Stopped the running mini-game.")


## The game board's testing switch (src/minigames/replay_board.gd `set_dev_show_all`): every game with
## a script is listed, locked or not. A runtime switch - it is kept on Engine, never in the save.
func _set_board_show_all(on: bool) -> void:
	if not ResourceLoader.exists(REPLAY_BOARD_PATH):
		EventBus.toast_requested.emit("Game board: not in this build.", "warn")
		return
	load(REPLAY_BOARD_PATH).call("set_dev_show_all", on)
	_finish_action("Board lists all games: %s" % ("on" if on else "off"))


func _replay_board_instance() -> Node:
	if not ResourceLoader.exists(REPLAY_BOARD_PATH):
		return null
	var world := get_tree().root.get_node_or_null("World")
	if world == null:
		return null
	var node: Variant = load(REPLAY_BOARD_PATH).call("attach", world)
	return node if node is Node else null


func _replay_kind(kind: String) -> void:
	var board := _replay_board_instance()
	if board == null:
		_finish_action("Game board: not available on this world.", "warn")
		return
	var entries: Array = load(REPLAY_BOARD_PATH).call("entries")
	var key := ""
	for e: Dictionary in entries:
		if str(e.get("game", "")) == kind:
			key = str(e.get("key", ""))
			break
	if key == "":
		_finish_action("%s isn't on the board yet — turn on \"Board lists all\" first." % kind, "warn")
		return
	_dev_replay_play(board, key)


## `ReplayBoard.play()` refuses while ANY modal is open (`EventBus.is_modal_open()`), and this menu
## itself is one — so the trip is deferred until THIS menu's own `ui_modal_closed("dev_menu")` fires,
## exactly the ordering dev_audit.md's "Safety" section spells out for a row that needs the world calm.
func _dev_replay_play(board: Node, key: String) -> void:
	_close_all_menus()
	await _await_modal_closed(MODAL_NAME)
	if not is_instance_valid(board):
		return
	board.call_deferred("play", key)


func _open_board() -> void:
	var board := _replay_board_instance()
	if board == null or not board.has_method("open_panel"):
		_finish_action("Game board: not available on this world.", "warn")
		return
	_close_all_menus()
	await _await_modal_closed(MODAL_NAME)
	if is_instance_valid(board):
		board.call_deferred("open_panel")


func _await_modal_closed(modal_name: String) -> void:
	while true:
		var closed_name: String = await EventBus.ui_modal_closed
		if closed_name == modal_name:
			return


# ============================================================================= WORLD tab
func _build_world_tab(list: VBoxContainer) -> void:
	var planets := _section("World", "planets", "Go to planet — the pad's own loader, no flight")
	for pid: String in GameState.PLANET_IDS:
		_add_action_row(planets, Journal.planet_name(pid), func() -> void: _jump_to(pid), "Go")

	var time_sec := _section("World", "time", "Time and clock")
	var time_row := _row(time_sec, "Time")
	for pair in [["Dawn 6", 6.0], ["Noon 12", 12.0], ["Dusk 19", 19.0], ["Night 22", 22.0]]:
		var h: float = pair[1]
		time_row.add_child(_small_button(str(pair[0]), func() -> void: _set_time(h)))
	var clock_row := _row(time_sec, "Clock speed")
	for pair in [["Stop", 0.0], ["1x", 1.0], ["10x", 10.0], ["60x", 60.0]]:
		var s: float = pair[1]
		clock_row.add_child(_small_button(str(pair[0]), func() -> void: _set_time_scale(s)))
	_add_action_row(time_sec, "To 23:58 (watch the day roll over)", func() -> void: _set_time(23.97), "Go")

	var day_sec := _section("World", "day", "In-game day")
	_add_note(day_sec, "Gates one project step per neighbour per day. Visitors and favours re-read it on the NEXT landing, not right away.")
	var day_row := _row(day_sec, "Day")
	_day_label = UIStyle.make_label("", "")
	_day_label.custom_minimum_size = Vector2(MobileUI.pick(70.0, 90.0), 0.0)
	_day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	day_row.add_child(_day_label)
	day_row.add_child(_small_button("-1", func() -> void: _add_day(-1)))
	day_row.add_child(_small_button("+1", func() -> void: _add_day(1)))
	day_row.add_child(_small_button("+7", func() -> void: _add_day(7)))

	var currency := _section("World", "currency", "Currency")
	_scrap_label = _add_currency_row(currency, "Scrap",
		func(n: int) -> void: GameState.add_scrap(n),
		func() -> void: GameState.spend_scrap(GameState.scrap))
	_stardust_label = _add_currency_row(currency, "Stardust",
		func(n: int) -> void: GameState.add_stardust(n),
		func() -> void: GameState.spend_stardust(GameState.stardust))

	var places := _section("World", "places", "Places")
	_add_action_row(places, "To Town Hall door", func() -> void: _go_to_building_dir("hub", "town_hall", "Town Hall door"), "Go")
	_add_action_row(places, "To mailbox", func() -> void: _go_to_building_dir("home", "player_home", "mailbox"), "Go")
	_add_action_row(places, "Unread the letter", func() -> void:
		GameState.set_flag("mail_day1_read", false)
		_finish_action("The mailbox letter will show again."), "Reset")

	var save_sec := _section("World", "save", "Save")
	_add_action_row(save_sec, "Save game now (writes the save)", func() -> void:
		if not await _confirm_ask("Write the real save file right now?"):
			return
		var ok := SaveManager.save_game()
		_finish_action("Saved." if ok else "Save failed.", "star" if ok else "warn"), "Save")


func _set_time(hour: float) -> void:
	var env := get_node_or_null("/root/World/Environment")
	if env == null or not env.has_method("set_time"):
		_finish_action("No world Environment to set the time on.", "warn")
		return
	env.call("set_time", hour)
	GameState.time_of_day = hour
	_finish_action("Time set to %.1fh." % hour)


func _set_time_scale(scale: float) -> void:
	var env := get_node_or_null("/root/World/Environment")
	if env == null or not ("time_scale" in env):
		_finish_action("No world Environment to set the clock speed on.", "warn")
		return
	env.set("time_scale", scale)
	_finish_action("Clock speed: %sx." % ("stopped" if scale == 0.0 else str(scale)))


func _add_day(delta: int) -> void:
	GameState.day_count = maxi(1, GameState.day_count + delta)
	_finish_action("Day %d" % GameState.day_count, "check")


func _go_to_building_dir(planet_id: String, building_id: String, label: String) -> void:
	var player := _player_node()
	var teleport_ok := player != null and player.has_method("dev_teleport")
	if GameState.current_planet_id != planet_id:
		_close_all_menus()
		SceneRouter.go_to_planet(planet_id)
		EventBus.toast_requested.emit(
			"Landing on the way — open the dev menu again once you're there to step to the %s." % label, "star")
		return
	if not teleport_ok:
		_finish_action("To %s — needs player.gd: dev_teleport" % label, "warn")
		return
	var planet := get_tree().get_first_node_in_group("planet")
	if planet == null or not planet.has_method("building_dir"):
		_finish_action("No planet here to find the %s on." % label, "warn")
		return
	var dir: Vector3 = planet.call("building_dir", building_id)
	if dir == Vector3.ZERO:
		_finish_action("This planet has no %s." % label, "warn")
		return
	player.call("dev_teleport", dir)
	_finish_action("Teleported to the %s." % label)


# ============================================================================= actions: planets
func _jump_to(planet_id: String) -> void:
	if SceneRouter.is_busy():
		EventBus.toast_requested.emit("Already travelling — try again in a moment.", "warn")
		return
	_close_all_menus()
	SceneRouter.go_to_planet(planet_id)


# ============================================================================= PERF tab
func _build_perf_tab(list: VBoxContainer) -> void:
	var overlay_sec := _section("Perf", "overlay", "Overlay")
	var ov_row := _row(overlay_sec, "Show performance overlay")
	_perf_overlay_toggle = ToggleSwitch.new()
	_perf_overlay_toggle.toggled.connect(func(on: bool) -> void:
		PerfOverlay.get_or_create().set_visible_ui(on)
		_finish_action("Overlay: %s" % ("on" if on else "off")))
	ov_row.add_child(_perf_overlay_toggle)
	_add_note(overlay_sec, "FPS, frame/CPU ms, draws, heat proxy (draws/s, 3D Mpx/s) and the build stamp. Updates twice a second — not a per-frame cost.")

	var toggles := _section("Perf", "toggles", "Toggles — re-apply on a planet load, never saved")
	var scale_row := _row(toggles, "3D scale")
	_perf_scale_seg = SegmentedControl.new()
	_perf_scale_seg.setup(PackedStringArray(["0.5", "0.625", "0.75", "1.0"]), 2)
	_perf_scale_seg.selected.connect(func(i: int) -> void:
		var v := float(_perf_scale_seg.options[i])
		PerfOverlay.get_or_create().set_scale_3d(v)
		_finish_action("3D scale: %.3f" % v))
	scale_row.add_child(_perf_scale_seg)

	var particles_row := _row(toggles, "GPU particles off")
	_perf_particles_toggle = ToggleSwitch.new()
	_perf_particles_toggle.toggled.connect(func(on: bool) -> void:
		PerfOverlay.get_or_create().set_particles_off(on)
		_finish_action("GPU particles: %s" % ("off" if on else "on")))
	particles_row.add_child(_perf_particles_toggle)

	var omni_row := _row(toggles, "Omni lights off")
	_perf_omni_toggle = ToggleSwitch.new()
	_perf_omni_toggle.toggled.connect(func(on: bool) -> void:
		PerfOverlay.get_or_create().set_omni_off(on)
		_finish_action("Omni lights: %s" % ("off" if on else "on")))
	omni_row.add_child(_perf_omni_toggle)

	var neighbours_row := _row(toggles, "Neighbours off")
	_perf_neighbours_toggle = ToggleSwitch.new()
	_perf_neighbours_toggle.toggled.connect(func(on: bool) -> void:
		PerfOverlay.get_or_create().set_neighbours_off(on)
		_finish_action("Neighbours: %s" % ("off" if on else "on")))
	neighbours_row.add_child(_perf_neighbours_toggle)

	_add_note(toggles, "Ground normal/flat — needs a debug uniform on grass_planet.gdshader / plaza_tiles.gdshader (heat item 3's own fix does not add one this phase — not yet buildable).")

	var shadows_row := _row(toggles, "Shadows (desktop)")
	_perf_shadows_row_note = UIStyle.make_label("", "Small")
	shadows_row.add_child(_perf_shadows_row_note)
	var shadows_btn := _small_button("Toggle", func() -> void:
		var ov := PerfOverlay.get_or_create()
		var text := ov.set_shadows_off(not ov._shadows_off_wanted)
		_set_result("Shadows: %s" % text))
	shadows_row.add_child(shadows_btn)

	var saver_row := _row(toggles, "Draw saver (web)")
	_perf_saver_row_note = UIStyle.make_label("", "Small")
	saver_row.add_child(_perf_saver_row_note)
	var saver_btn := _small_button("Toggle", func() -> void:
		var ov := PerfOverlay.get_or_create()
		var text := ov.set_saver(not ov._saver_wanted)
		_set_result("Draw saver: %s" % text))
	saver_row.add_child(saver_btn)

	var warmup_row := _row(toggles, "Load warm-up")
	_perf_warmup_row_note = UIStyle.make_label("", "Small")
	warmup_row.add_child(_perf_warmup_row_note)
	var warmup_btn := _small_button("Toggle", func() -> void:
		var ov := PerfOverlay.get_or_create()
		var text := ov.set_warmup(not ov._warmup_on)
		_set_result("Warm-up: %s" % text))
	warmup_row.add_child(warmup_btn)
	_add_note(toggles, "Kept across reloads (its own dev-settings file) — the only Perf toggle that is.")

	var burn_row := _row(toggles, "Burn 8 ms/frame (control)")
	_perf_burn_toggle = ToggleSwitch.new()
	_perf_burn_toggle.toggled.connect(func(on: bool) -> void:
		PerfOverlay.get_or_create().set_burn(on)
		_finish_action("Burn control: %s" % ("on" if on else "off")))
	burn_row.add_child(_perf_burn_toggle)
	_add_note(toggles, "A known synthetic 8 ms/frame load — busy%/frame-ms should jump sharply, or the meter is broken.")


# ============================================================================= value refresh
func _refresh_values() -> void:
	if _status_label != null and _current_tab == "Status":
		_status_label.text = _status_text()
	if _parts_seg != null:
		_parts_seg.index = clampi(GameState.rocket_part_count(), 0, CampaignData.PARTS.size())
	if _day_label != null:
		_day_label.text = str(GameState.day_count)
	if _scrap_label != null:
		_scrap_label.text = str(GameState.scrap)
	if _stardust_label != null:
		_stardust_label.text = str(GameState.stardust)
	# BLOCKED, not a plain assignment (docs/OPEN_ISSUES.md item 49): ToggleSwitch has no
	# set_pressed_no_signal — its `on` setter always emits `toggled` itself, and this sync runs on
	# every open/refresh, so without the block a hand tap's own toast would fire twice.
	if _campaign_toggle != null:
		_campaign_toggle.set_block_signals(true)
		_campaign_toggle.on = GameState.campaign_active
		_campaign_toggle.set_block_signals(false)
	if _story_toggle != null:
		_story_toggle.set_block_signals(true)
		_story_toggle.on = GameState.story_done
		_story_toggle.set_block_signals(false)
	if _board_all_toggle != null and ResourceLoader.exists(REPLAY_BOARD_PATH):
		_board_all_toggle.set_block_signals(true)
		_board_all_toggle.on = bool(load(REPLAY_BOARD_PATH).call("dev_show_all"))
		_board_all_toggle.set_block_signals(false)
	for npc_id: String in _project_labels:
		(_project_labels[npc_id] as Label).text = _project_status_text(npc_id)
	for npc_id: String in _favor_labels:
		(_favor_labels[npc_id] as Label).text = _favor_check_text(npc_id)
	_refresh_perf_controls()


func _refresh_perf_controls() -> void:
	var ov := PerfOverlay.find()
	if ov == null:
		return
	if _perf_overlay_toggle != null:
		_perf_overlay_toggle.set_block_signals(true)
		_perf_overlay_toggle.on = ov.is_visible_ui()
		_perf_overlay_toggle.set_block_signals(false)
	if _perf_particles_toggle != null:
		_perf_particles_toggle.set_block_signals(true)
		_perf_particles_toggle.on = ov.particles_off()
		_perf_particles_toggle.set_block_signals(false)
	if _perf_omni_toggle != null:
		_perf_omni_toggle.set_block_signals(true)
		_perf_omni_toggle.on = ov.omni_off()
		_perf_omni_toggle.set_block_signals(false)
	if _perf_neighbours_toggle != null:
		_perf_neighbours_toggle.set_block_signals(true)
		_perf_neighbours_toggle.on = ov.neighbours_off()
		_perf_neighbours_toggle.set_block_signals(false)
	if _perf_burn_toggle != null:
		_perf_burn_toggle.set_block_signals(true)
		_perf_burn_toggle.on = ov.burn_on()
		_perf_burn_toggle.set_block_signals(false)
	if _perf_shadows_row_note != null:
		_perf_shadows_row_note.text = ov.shadows_status()
	if _perf_saver_row_note != null:
		_perf_saver_row_note.text = ov.saver_status()
	if _perf_warmup_row_note != null:
		var rep := ov.warmup_last_report()
		var extra := (" (%s)" % str(rep.get("reason", ""))) if not rep.is_empty() else ""
		_perf_warmup_row_note.text = ov.warmup_status() + extra


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


# ============================================================================= input
func _process(delta: float) -> void:
	if not is_open:
		return
	_cooldown -= delta
	if _cooldown > 0.0:
		return
	_status_t += delta
	if _status_t >= 0.5:
		_status_t = 0.0
		if _current_tab == "Status" and _status_label != null:
			_status_label.text = _status_text()
	var scroll: ScrollContainer = _tab_scrolls.get(_current_tab)
	var step := _repeat.poll(delta)
	if step.y != 0 and scroll != null:
		scroll.scroll_vertical += int(34.0 * float(step.y))
	if UIFocus.cancel_pressed():
		UIStyle.play_cancel()
		close()


func _input(event: InputEvent) -> void:
	if is_open:
		UIFocus.consume_nav_event(self, event)


## ============================================================================ test hooks below,
## same evidence standard as pause_menu.gd's `debug_tap_ui_mode`: a REAL InputEventMouseButton
## through `MobileUI.synth_tap` / `Input.parse_input_event`, not `Input.action_press` (sends no
## InputEvent) and not calling a row's handler function directly. They find controls by the exact
## text of their own label/header, so a Director probe taps the same pixel a finger would.
func debug_tap_tab(tab_name: String) -> bool:
	var b: Button = _tab_buttons.get(tab_name)
	if b == null:
		return false
	MobileUI.synth_tap(b.get_global_rect().get_center())
	return true


## Taps the collapsible section header whose title CONTAINS `title_part`, in the CURRENTLY selected
## tab (`debug_tap_tab` first). Returns false if that tab's own header text can't be found.
func debug_tap_section(title_part: String) -> bool:
	var list: VBoxContainer = _tab_lists.get(_current_tab)
	if list == null:
		return false
	for c in list.get_children():
		if c is Button and str((c as Button).text).findn(title_part) >= 0:
			return await _tap_control(c as Button)
	return false


func _nearest_scroll(control: Control) -> ScrollContainer:
	var node: Node = control
	while node != null:
		if node is ScrollContainer:
			return node as ScrollContainer
		node = node.get_parent()
	return null


## Real tap (`MobileUI.synth_tap`) at `local_point` in `control`'s own local space: scrolls the
## control into view with Godot's OWN `ScrollContainer.ensure_control_visible()`, awaits two
## settling `process_frame`s, then reads `control.get_global_rect()` fresh for the actual tap
## position.
##
## MEASURED, not the original design: an earlier version hand-computed both the scroll target and
## the tap position by walking accumulated `.position` values up the parent chain. That hand
## computation was demonstrably wrong: `tests/director/dev_menu_probe.gd` caught a real miss on a
## header several sections down a freshly-reopened tab — right after `scroll_vertical` was written,
## the ScrollContainer's own content child had NOT yet repositioned (`list.position` still reflected
## the PREVIOUS scroll value, confirmed by printing it), so a position rebuilt from that stale value
## put the computed tap on the TAB BAR instead of the intended row. `ensure_control_visible` plus a
## settle wait, then a fresh `get_global_rect()` read, sidesteps re-deriving any of that by hand.
##
## REFUSES a control that is not `is_visible_in_tree()` (a row inside a still-collapsed section)
## rather than tapping anyway — a real finger could not hit an invisible row either, so a caller
## must open the section first (`debug_tap_section`), exactly as a player would.
func _tap_point(control: Control, local_point: Vector2) -> bool:
	if control == null or not control.is_visible_in_tree():
		return false
	var scroll := _nearest_scroll(control)
	if scroll != null:
		scroll.ensure_control_visible(control)
	# TWO settling frames — measured (tests/director/dev_menu_probe.gd): one frame alone still read
	# a ScrollContainer content position from before `ensure_control_visible`'s own scroll took
	# effect on at least one nested case (a row several sections down a tab opened the same run).
	# `Engine.get_main_loop() as SceneTree`, NOT `self.get_tree()` (Phase 5 DEVF critic round 2,
	# 2026-09-14): a long real-tap regression run (tests/director/dev_menu_probe.gd, ~10 rows deep)
	# hit `tools/check.sh`'s own `--quit-at=3` (Director.gd counts SIMULATED time — summed `delta` —
	# so a slow/contended host reaches 3.0s in far fewer real frames than a fast one) while this
	# coroutine sat suspended here; `self.get_tree()` then threw "Parameter 'data.tree' is null" even
	# though `is_instance_valid(self)` and, in every direct probe, `is_inside_tree()` still read true
	# right up to the crash — the two disagree for a moment during a Director-forced quit, so
	# `is_inside_tree()` guards alone did not close it (measured: still crashed with those guards in
	# place). `PerfOverlay.find()` / `MinigameSystem.get_or_create()` already use the SceneTree from
	# `Engine.get_main_loop()` rather than a specific node's own `get_tree()` for exactly this
	# robustness; same fix here. Root cause is Director.gd's quit-at plus that long legacy probe's
	# frame budget, not this file's tap logic — a real player's tap never races an automated quit.
	var loop := Engine.get_main_loop() as SceneTree
	if loop == null:
		return false
	await loop.process_frame
	await loop.process_frame
	if not is_instance_valid(control) or not control.is_visible_in_tree():
		return false
	var p := control.get_global_rect().position + local_point
	MobileUI.synth_tap(p)
	# One more settle frame AFTER the tap — measured (tests/director/dev_menu_probe.gd): a tap that
	# opens a section toggles `body.visible` as part of handling this same synthetic input event,
	# but the newly-visible content one level down (e.g. a SegmentedControl inside that body) is not
	# yet laid out by the time this coroutine would otherwise return — a caller acting on it in the
	# very next line (no frame in between) missed it. Every caller of `_tap_control`/`_tap_point`
	# gets this for free rather than each having to remember its own extra `await`.
	loop = Engine.get_main_loop() as SceneTree
	if loop != null:
		await loop.process_frame
	return true


## Real tap at `control`'s own (post-scroll, drawn) centre. False (no tap sent) if `control` is
## hidden — see `_tap_point`'s own comment.
func _tap_control(control: Control) -> bool:
	return await _tap_point(control, control.size * 0.5)


func _row_by_label(label_text: String) -> HBoxContainer:
	var list: VBoxContainer = _tab_lists.get(_current_tab)
	if list == null:
		return null
	return _find_row_by_label(list, label_text)


func _find_row_by_label(root: Node, label_text: String) -> HBoxContainer:
	for c in root.get_children():
		if c is HBoxContainer and c.get_child_count() > 0 and c.get_child(0) is Label \
				and (c.get_child(0) as Label).text == label_text:
			return c
		if c.get_child_count() > 0:
			var found := _find_row_by_label(c, label_text)
			if found != null:
				return found
	return null


func _button_in(row: Control, button_text: String) -> Button:
	if row == null:
		return null
	for c in row.get_children():
		if c is Button and (c as Button).text == button_text:
			return c
	return null


## Taps the button with `button_text` on the row whose label reads `label_text`, anywhere inside the
## currently selected tab's (open) sections.
func debug_tap_row_button(label_text: String, button_text: String) -> bool:
	var b := _button_in(_row_by_label(label_text), button_text)
	if b == null:
		return false
	return await _tap_control(b)


## Taps the ToggleSwitch on the row whose label reads `label_text`.
func debug_tap_gate(label_text: String) -> bool:
	var row := _row_by_label(label_text)
	if row == null:
		return false
	for c in row.get_children():
		if c is ToggleSwitch:
			return await _tap_control(c as ToggleSwitch)
	return false


## Taps segment `i` (0..CampaignData.PARTS.size()) of the rocket-parts SegmentedControl on the
## Story tab.
func debug_tap_parts(i: int) -> bool:
	if _parts_seg == null or i < 0 or i >= _parts_seg.options.size():
		return false
	return await _tap_point(_parts_seg, _parts_seg._segment_rect(i).get_center())


## Taps "Start / Advance", "Finish + give part" or "Reset" on `npc_id`'s Friends block, matched by
## its own status label having just been rebuilt under that neighbour's section — found by walking
## the Friends tab list for the button row that is the very next sibling after that npc's
## `_project_labels` entry.
func debug_tap_project_button(npc_id: String, button_text: String) -> bool:
	var status: Label = _project_labels.get(npc_id)
	if status == null:
		return false
	var parent := status.get_parent()
	var idx := status.get_index()
	if idx + 1 >= parent.get_child_count():
		return false
	var buttons := parent.get_child(idx + 1)
	var b := _button_in(buttons as Control, button_text)
	if b == null:
		return false
	return await _tap_control(b)


## One-line state dump for a Director probe to assert against.
func debug_report(tag: String = "") -> void:
	print("DEVMENU %s open=%s tab=%s parts=%d day=%d scrap=%d stardust=%d campaign=%s story_done=%s" % [
		tag, str(is_open), _current_tab, GameState.rocket_part_count(), GameState.day_count, GameState.scrap,
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
