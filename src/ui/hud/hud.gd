class_name Hud
extends CanvasLayer
## In-game HUD (ARCHITECTURE §6): stardust counter (top-left), clock (top-right), planet-name banner,
## interact prompt pill (bottom-center), toast stack (bottom-right), control hints (bottom-left), and the
## modal screens as named children: DialogueBox, Inventory, ShopPanel, PauseMenu.
## Opens the bag on `inventory` (Decorations tab on `decorate`) and the pause menu on `pause` when no
## other modal is open. process_mode is ALWAYS so the pause menu keeps working while the tree is paused.
##
## While a modal is open the world-facing chrome (stardust pill, clock, hints, banner and the stardust
## floaters) fades away — a modal panel is nearly full-screen at 1280x720 and used to cut those pills in
## half — and the toast stack moves out of the way (see ToastSpot).
##
## Two layers of chrome. `Chrome` holds everything that hides under a modal; `WorldChrome`, inside it,
## holds only the pills you read while playing (stardust, clock, jet fuel, control hints, floaters) and
## is ALSO taken away while the rocket flies its arrival descent (`GameState.flag("rocket_arriving")`),
## so the landing is uninterrupted. The arrival banner sits in `Chrome` but outside `WorldChrome`,
## because it is HELD during the descent and played in full at touchdown instead.
##
## `pause` is deliberately allowed through during placement mode and during a conversation — see
## `_has_blocking_modal`. This project has shipped three soft-locks; the pause menu is the escape hatch.

# --- planet arrival banner ---
const BANNER_SLIDE := 0.55
const BANNER_HOLD := 2.5
const BANNER_FADE := 0.4
## Y the banner rests at, and how far it drifts back up while fading out.
const BANNER_TOP := 84.0
const BANNER_RISE := 30.0
## While GameState.flag("rocket_arriving") is set, the arrival banner is HELD rather than played,
## and released at touchdown (see _on_planet_loaded). This is the safety net in case the flag is
## never cleared - the banner plays anyway after this many seconds.
const BANNER_PENDING_MAX := 25.0

## Jetpack fuel pill: sits just above the control hints in the bottom-left (player builder, R2.8).
const JET_PILL_LIFT := 40.0
const JET_BAR_W := 92.0
const JET_BAR_H := 10.0
const HINTS_LIFETIME := 6.0
const MAX_TOASTS := 4
## Stack size while the toasts are parked in the top-right corner (keeps them clear of a choice box).
const MAX_TOASTS_PARKED := 2
const TOAST_GAP := 8.0
## Seconds between two held toasts when the stack is flushed after a modal closes.
const TOAST_FLUSH_STAGGER := 0.14
## Fast exit for a live toast when a panel modal takes over the frame (beats the panel's pop-in).
const TOAST_HIDE_FAST := 0.1
const EDGE := 24.0
## Scrap pill (BUILD_PLAN Phase 1 "D: scrap and economy"): a FIXED offset to the right of the
## stardust pill rather than a width measured off it at runtime - a label's text (and so its pill's
## size) can still be mid-resize when the next line of code reads it, and a structural HUD position
## must never race that. Sized for stardust up to 4 digits at the "Header" font (icon 30 + text +
## HudPill padding) with headroom; checked against captures at desktop 1280x720 and
## `--ui=mobile` 1560x720 (both pills share the same MOBILE_PILL_SCALE, so one constant covers both).
const SCRAP_PILL_OFFSET_X := 132.0
## The interact prompt floats this far above the bottom edge (clear of the control hints).
const PROMPT_BOTTOM := 92.0
## Fade used when the HUD chrome tucks away under a modal.
const CHROME_FADE := 0.18
## Stardust floater: where it starts beside the pill and how far it drifts up.
## The rise is bounded so the "+72" / "-90" label never leaves the top of the frame.
const FLOAT_START_Y := 20.0
const FLOAT_RISE := 34.0

## Where the toast stack currently lives.
## CORNER = bottom-right (no modal). PARKED = top-right, under the (hidden) clock, while only an
## overlay modal such as the dialogue box is up. HELD = a full-screen panel covers the frame, so
## toasts are queued and flushed when it closes; they must never land on a button or the speech panel.
enum ToastSpot { CORNER, PARKED, HELD }

## Modal names that leave most of the screen free. Everything else is treated as a full-screen panel.
const OVERLAY_MODALS: PackedStringArray = ["dialogue"]

# --- placement "why not here?" pill (integration critic, blocking #2) ---
## DecorationManager.spot_block_reason() has always known exactly why a spot is refused; nothing
## showed the player. The ghost just turned red, so the first creative thing the game offers could
## fail four times in a row with no explanation. These are its return values in plain words.
const BLOCK_REASONS := {
	"reserved": "That spot's reserved",
	"slope": "Ground's too steep here",
	"prop": "Something's in the way",
	"crowded": "Too close to another item",
	"npc": "Someone's standing there",
	"water": "That's in the water",
	"shore": "Too close to the water",
	"no_planet": "",
}
const BLOCK_REASON_FALLBACK := "Can't put it here"
## Metres above the ghost's base that the pill floats.
const BLOCK_PILL_LIFT := 1.15
## Fade speed of the pill, in alpha per second (in / out).
const BLOCK_PILL_FADE := Vector2(9.0, 5.0)
## Speed the world-facing pills fade out for (and back in after) a rocket landing.
const ARRIVAL_HOLD_FADE := 3.2

# --- mobile chrome (R2.10) ---
## The stardust and clock pills are drawn at this scale on a phone. R2.10 asks that they "shrink
## into the safe area at the top", and the mobile Theme scales type UP for the full-screen panels,
## so the chrome deliberately keeps the desktop Theme and is scaled down here instead.
const MOBILE_PILL_SCALE := 0.86
## Interact prompt, measured down from the safe-area top on mobile.
const MOBILE_PROMPT_TOP := 6.0
## Jet-fuel pill, measured down from the safe-area top on mobile - clear below the touch HUD row
## (2 x MobileUI.HUD_BTN_HIT_R plus the pill above it).
const MOBILE_JET_TOP := 162.0
## Extra room left at the top of the mobile toast stack for the clock pill it parks under.
const MOBILE_TOAST_TOP := 56.0

@onready var root: Control = $Root
@onready var dialogue_box: DialogueBox = $DialogueBox
@onready var inventory: InventoryPanel = $Inventory
@onready var shop_panel: ShopPanel = $ShopPanel
@onready var pause_menu: PauseMenu = $PauseMenu
@onready var toasts: VBoxContainer = $Toasts

var _chrome: Control
## Sub-layer of _chrome holding the pills you read while playing (stardust, clock, jet fuel, hints,
## stardust floaters). Separate from the arrival banner so the rocket-arrival hold can take one
## without the other.
var _world_chrome: Control
var _chrome_shown := true
var _chrome_tween: Tween
var _stardust_pill: PanelContainer
var _stardust_label: Label
var _stardust_star: StarIcon
## Scrap counter beside the stardust one (BUILD_PLAN Phase 1 "D"), same HudPill style.
var _scrap_pill: PanelContainer
var _scrap_label: Label
var _scrap_icon: ScrapIcon
var _float_layer: Control
var _clock_pill: PanelContainer
var _clock_label: Label
var _banner: PanelContainer
var _banner_sub: Label
var _banner_name: Label
var _banner_tween: Tween
## Arrival banner held back until the rocket touches down (see _on_planet_loaded).
var _banner_pending := false
var _banner_pending_timer := 0.0
var _prompt: PanelContainer
var _prompt_label: Label
var _prompt_text := ""
var _hints: PanelContainer
var _hints_timer := HINTS_LIFETIME
# ---- jetpack fuel readout (player builder, R2.8)
var _jet_pill: PanelContainer
var _jet_bar: ProgressBar
var _jet_fill_box: StyleBoxFlat
var _placement_active := false
# ---- placement blocked-reason pill
var _block_pill: PanelContainer
var _block_label: Label
var _block_alpha := 0.0
var _deco_mgr: Node
var _open_modals: Dictionary = {}
var _toast_spot: ToastSpot = ToastSpot.CORNER
var _pending_toasts: Array = []
var _flush_timer := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chrome = Control.new()
	_chrome.name = "Chrome"
	_chrome.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_chrome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_chrome)
	# Everything inside WorldChrome is "the pills you read while playing". It is a separate layer
	# from the arrival banner because the rocket-arrival hold (see `_update_arrival_hold`) must take
	# the pills away WITHOUT taking the banner with them.
	_world_chrome = Control.new()
	_world_chrome.name = "WorldChrome"
	_world_chrome.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_world_chrome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chrome.add_child(_world_chrome)
	_build_stardust()
	_build_scrap()
	_build_clock()
	_build_banner()
	_build_prompt()
	_build_jet_fuel()
	_build_hints()
	_build_block_pill()
	_float_layer = Control.new()
	_float_layer.name = "Floaters"
	_float_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_float_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_world_chrome.add_child(_float_layer)
	_layout_toasts()
	root.resized.connect(_layout_toasts)
	# MOBILE (R2.10). The chrome deliberately keeps the DESKTOP theme - the mobile theme scales type
	# UP for the full-screen panels, and the pills are meant to shrink, not grow. Only the modal
	# panels take the mobile theme, each in its own _ready.
	_apply_platform_layout()
	MobileUI.on_mode_changed(func(_m: bool) -> void:
		# The hint strip has to be REBUILT, not just re-shown: it is empty on mobile, so a switch
		# back to the computer layout would otherwise leave an empty pill in the corner.
		for c in _hints.get_children():
			c.queue_free()
		_hints_timer = HINTS_LIFETIME
		_hints.modulate.a = 1.0
		_build_hints_row()
		_apply_platform_layout())
	root.resized.connect(_apply_platform_layout)

	EventBus.stardust_changed.connect(_on_stardust_changed)
	EventBus.scrap_changed.connect(_on_scrap_changed)
	EventBus.time_of_day_changed.connect(_on_time_changed)
	EventBus.planet_loaded.connect(_on_planet_loaded)
	EventBus.interact_prompt_changed.connect(_on_prompt_changed)
	EventBus.toast_requested.connect(_on_toast)
	EventBus.ui_modal_opened.connect(_on_modal_opened)
	EventBus.ui_modal_closed.connect(_on_modal_closed)
	EventBus.placement_mode_changed.connect(func(active: bool) -> void: _placement_active = active)
	_stardust_label.text = str(GameState.stardust)
	_scrap_label.text = str(GameState.scrap)
	_on_time_changed(GameState.time_of_day)

	# *** TEMPORARY INSTRUMENTATION — REMOVE WITH src/ui/mobile/touch_diag.gd. ***
	# On-screen touch/input state readout for the "I can't move until I pause and resume" report
	# (five playtests, four failed fixes, and no measurement has ever observed the real touch event
	# path). Added as a SIBLING of TouchControls under this CanvasLayer, and last so it draws on
	# top: if the fault turns out to be a stuck modal, TouchControls is hidden and a child of it
	# would be hidden with it. It draws only on the mobile front end, and `--no-diag` (or
	# `TouchDiag.ENABLED = false`) removes it entirely.
	if TouchDiag.wanted():
		add_child(TouchDiag.new())

# ----------------------------------------------------------------------------- build
func _build_stardust() -> void:
	_stardust_pill = PanelContainer.new()
	_stardust_pill.name = "Stardust"
	_stardust_pill.theme_type_variation = "HudPill"
	_stardust_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stardust_pill.position = Vector2(EDGE, EDGE - 4.0)
	_world_chrome.add_child(_stardust_pill)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stardust_pill.add_child(row)
	_stardust_star = StarIcon.new()
	_stardust_star.icon_size = 30.0
	row.add_child(_stardust_star)
	_stardust_label = UIStyle.make_label("0", "Header")
	row.add_child(_stardust_label)

## Scrap counter (BUILD_PLAN Phase 1 "D"). Same HudPill panel and "Header" label as the stardust
## pill beside it; positioned in `_apply_platform_layout` (SCRAP_PILL_OFFSET_X), not here, since it
## has to track the stardust pill's own position/scale as those change with the platform.
func _build_scrap() -> void:
	_scrap_pill = PanelContainer.new()
	_scrap_pill.name = "Scrap"
	_scrap_pill.theme_type_variation = "HudPill"
	_scrap_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_world_chrome.add_child(_scrap_pill)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scrap_pill.add_child(row)
	_scrap_icon = ScrapIcon.new()
	_scrap_icon.icon_size = 28.0
	row.add_child(_scrap_icon)
	_scrap_label = UIStyle.make_label("0", "Header")
	row.add_child(_scrap_label)

func _build_clock() -> void:
	_clock_pill = PanelContainer.new()
	_clock_pill.name = "Clock"
	_clock_pill.theme_type_variation = "HudPill"
	_clock_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_clock_pill.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_clock_pill.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_clock_pill.offset_right = -EDGE
	_clock_pill.offset_top = EDGE
	_world_chrome.add_child(_clock_pill)
	_clock_label = UIStyle.make_label("9:30 AM · Day 1", "Small")
	_clock_pill.add_child(_clock_label)

func _build_banner() -> void:
	_banner = PanelContainer.new()
	_banner.name = "PlanetBanner"
	_banner.theme_type_variation = "Banner"
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_banner.visible = false
	_chrome.add_child(_banner)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", -4)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.add_child(box)
	_banner_sub = UIStyle.make_label("Now arriving at", "Soft", HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(_banner_sub)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(row)
	var s1 := StarIcon.new()
	s1.icon_size = 30.0
	s1.twinkle = true
	s1.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(s1)
	_banner_name = UIStyle.make_label("Little Orbit", "Title", HORIZONTAL_ALIGNMENT_CENTER)
	row.add_child(_banner_name)
	var s2 := StarIcon.new()
	s2.icon_size = 30.0
	s2.twinkle = true
	s2.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(s2)

func _build_prompt() -> void:
	_prompt = PanelContainer.new()
	_prompt.name = "InteractPrompt"
	_prompt.theme_type_variation = "HudPill"
	_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_prompt.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_prompt.offset_bottom = -PROMPT_BOTTOM
	_prompt.visible = false
	root.add_child(_prompt)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt.add_child(row)
	var key := KeyGlyph.new()
	key.set_action("interact")
	key.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	# There is no E key on a phone, and the context button already carries the verb - so on mobile
	# the pill is just the word, moved to the top of the screen by `_apply_platform_layout`.
	key.visible = not MobileUI.is_mobile()
	row.add_child(key)
	_prompt_label = UIStyle.make_label("Talk", "")
	row.add_child(_prompt_label)

# ------------------------------------------------------------------- placement "why not here?" pill
## A small blush-coloured pill that floats just above the placement ghost and says, in plain words,
## why the spot is refused. It lives on `root` (not in `_chrome`) for the same reason the interact
## prompt does: placement mode is gameplay, and the pill must stay up while the ghost is out.
func _build_block_pill() -> void:
	_block_pill = PanelContainer.new()
	_block_pill.name = "PlacementBlocked"
	_block_pill.theme_type_variation = "HudPill"
	_block_pill.add_theme_stylebox_override("panel",
		UIStyle.make_pill_style(Color("#f6ded8"), UIStyle.RED, 3, 6, 16.0, 5.0))
	_block_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_block_pill.visible = false
	_block_pill.modulate.a = 0.0
	root.add_child(_block_pill)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_block_pill.add_child(row)
	var icon := Toast.SymbolIcon.new()
	icon.kind = "warn"
	icon.custom_minimum_size = Vector2(22.0, 22.0)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)
	_block_label = UIStyle.make_label("", "Small")
	row.add_child(_block_label)

## `/root/World/Decorations`, cached. Read-only: the HUD never edits the decoration domain.
func _deco_manager() -> Node:
	if is_instance_valid(_deco_mgr):
		return _deco_mgr
	_deco_mgr = get_tree().root.get_node_or_null("World/Decorations")
	return _deco_mgr

## Why the ghost's current spot is refused ("" = it is fine, or we are not placing).
## Prefers a `blocked_reason()` on the PlacementController when the decoration builder adds one
## (see the report); until then it asks the manager directly with the ghost's own dir + footprint,
## which is the same call the controller makes for its red tint, so the two can never disagree.
func _placement_block_reason() -> String:
	var mgr := _deco_manager()
	if mgr == null:
		return ""
	var pc: Object = mgr.get("placement")
	if pc == null or not pc.has_method("is_active") or not bool(pc.call("is_active")):
		return ""
	if pc.has_method("blocked_reason"):
		return str(pc.call("blocked_reason"))
	var d: Variant = pc.get("_dir")
	if not (d is Vector3):
		return ""
	var fp: Variant = pc.get("_footprint")
	return str(mgr.call("spot_block_reason", d as Vector3, float(fp) if fp != null else 0.7, ""))

## Screen position for the pill: pinned just above the ghost, clamped into the frame. Falls back to
## a spot above the interact prompt when the ghost is off-camera.
func _block_pill_position() -> Vector2:
	var vp := root.size
	var fallback := Vector2((vp.x - _block_pill.size.x) * 0.5,
		vp.y - PROMPT_BOTTOM - _prompt.size.y - 46.0)
	var mgr := _deco_manager()
	if mgr == null:
		return fallback
	var pc := mgr.get("placement") as Node
	var ghost := pc.get_node_or_null("Ghost") as Node3D if pc != null else null
	var cam := get_viewport().get_camera_3d()
	if ghost == null or cam == null:
		return fallback
	var world_pos := ghost.global_position + ghost.global_transform.basis.y * BLOCK_PILL_LIFT
	if cam.is_position_behind(world_pos):
		return fallback
	var p := cam.unproject_position(world_pos) - Vector2(_block_pill.size.x * 0.5, _block_pill.size.y + 10.0)
	p.x = clampf(p.x, 16.0, maxf(16.0, vp.x - _block_pill.size.x - 16.0))
	p.y = clampf(p.y, 16.0, maxf(16.0, vp.y - _block_pill.size.y - 140.0))
	return p

func _update_placement_hint(delta: float) -> void:
	if _block_pill == null:
		return
	var reason := "" if EventBus.is_modal_open() else _placement_block_reason()
	var text := str(BLOCK_REASONS.get(reason, BLOCK_REASON_FALLBACK)) if reason != "" else ""
	var want := text != ""
	if want:
		if _block_label.text != text:
			_block_label.text = text
			_block_pill.reset_size()
			UIStyle.bump(_block_pill, 1.1, 0.3)
		_block_pill.position = _block_pill_position()
	_block_alpha = move_toward(_block_alpha, 1.0 if want else 0.0,
		delta * (BLOCK_PILL_FADE.x if want else BLOCK_PILL_FADE.y))
	_block_pill.modulate.a = _block_alpha
	_block_pill.visible = _block_alpha > 0.01

## Holds the world-facing pills out of the frame while the rocket flies its arrival descent, the
## same way the arrival banner is parked (OPEN_ISSUES #8). The flag is set in rocket_pad.gd's
## _prepare_arrival and cleared at touchdown, so this is polled rather than signalled.
func _update_arrival_hold(delta: float) -> void:
	if _world_chrome == null:
		return
	var want := 0.0 if GameState.flag("rocket_arriving") else 1.0
	if is_equal_approx(_world_chrome.modulate.a, want):
		return
	_world_chrome.modulate.a = move_toward(_world_chrome.modulate.a, want, delta * ARRIVAL_HOLD_FADE)
	_world_chrome.visible = _world_chrome.modulate.a > 0.01

# ----------------------------------------------------------------------------- jetpack fuel
## ADDED BY THE PLAYER BUILDER for docs/STYLE_GUIDE.md R2.8 ("a small fuel budget with a clear HUD
## read so it feels like a resource rather than free flight"). This function, `_update_jet_fuel`,
## the three `_jet_*` members, the `_build_jet_fuel()` call in `_ready`, the one line in `_process`
## and the "boost" entry in the control hints are the whole of the change to this file.
##
## It polls `Player.get_boost_fuel()` rather than listening to a signal: the value changes every
## physics frame while flying, so a signal would be one emission per frame for a bar that is only
## on screen while it is not full.
func _build_jet_fuel() -> void:
	_jet_pill = PanelContainer.new()
	_jet_pill.name = "JetFuel"
	_jet_pill.theme_type_variation = "HudPillSoft"
	_jet_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_jet_pill.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_jet_pill.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_jet_pill.offset_left = EDGE
	_jet_pill.offset_bottom = -EDGE - JET_PILL_LIFT
	_jet_pill.modulate.a = 0.0
	_jet_pill.visible = false
	_world_chrome.add_child(_jet_pill)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_jet_pill.add_child(row)
	row.add_child(UIStyle.make_label("JET", "Hint"))
	_jet_bar = ProgressBar.new()
	_jet_bar.show_percentage = false
	_jet_bar.min_value = 0.0
	_jet_bar.max_value = 1.0
	_jet_bar.value = 1.0
	_jet_bar.custom_minimum_size = Vector2(JET_BAR_W, JET_BAR_H)
	_jet_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_jet_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(UIStyle.TEXT_BROWN, 0.22)
	bg.set_corner_radius_all(int(JET_BAR_H * 0.5))
	var fill := StyleBoxFlat.new()
	fill.bg_color = UIStyle.YELLOW
	fill.set_corner_radius_all(int(JET_BAR_H * 0.5))
	_jet_bar.add_theme_stylebox_override("background", bg)
	_jet_bar.add_theme_stylebox_override("fill", fill)
	_jet_fill_box = fill
	row.add_child(_jet_bar)


## Shows the pill whenever the tank is not full (i.e. while flying and while it refills), and fades
## it out once it is topped up again, so it never sits on screen during ordinary walking.
func _update_jet_fuel(delta: float) -> void:
	if _jet_pill == null:
		return
	var player := get_tree().get_first_node_in_group("player")
	if player == null or not player.has_method("get_boost_fuel"):
		return
	var fuel: float = player.call("get_boost_fuel")
	_jet_bar.value = fuel
	# Amber while burning down, back to the stardust yellow when it is healthy again; red when the
	# tank is nearly dry, which is the read that tells you to get your feet down.
	_jet_fill_box.bg_color = UIStyle.RED if fuel < 0.2 else (UIStyle.ORANGE if fuel < 0.55 else UIStyle.YELLOW)
	var want := fuel < 0.999 and not EventBus.is_modal_open()
	_jet_pill.visible = want or _jet_pill.modulate.a > 0.01
	_jet_pill.modulate.a = move_toward(_jet_pill.modulate.a, 1.0 if want else 0.0, delta * (8.0 if want else 2.2))


func _build_hints() -> void:
	_hints = PanelContainer.new()
	_hints.name = "ControlHints"
	_hints.theme_type_variation = "HudPillSoft"
	_hints.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hints.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_hints.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_hints.offset_left = EDGE
	_hints.offset_bottom = -EDGE + 4.0
	_world_chrome.add_child(_hints)
	# THE KEYBOARD HINT STRIP IS DESKTOP-ONLY (R2.10). It drew right across the bottom of the mobile
	# mock, which is exactly the "UI taking too much space" the user objected to - and every glyph
	# in it names a key a phone does not have. The node is still created (a lot of this file reads
	# `_hints`), it is simply never populated and never shown; TouchControls carries the bag,
	# journal and pause affordances instead.
	#
	# CHECKED FOR THE 2026-09-12 EMOTE-BUTTON CHANGE (the touch Jump satellite became Emote): this
	# whole row is skipped below on mobile before `pairs` is ever built, so there was never a phone
	# hint mentioning "Jump" to correct - `_build_hints_row`'s `pairs` list stays keyboard-only,
	# unaffected by what TouchControls now draws.
	_build_hints_row()


## The strip's contents (empty on mobile). Split out so a runtime UI-mode switch can rebuild it.
func _build_hints_row() -> void:
	if MobileUI.is_mobile():
		_hints.visible = false
		_hints_timer = 0.0
		return
	_hints.visible = true
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hints.add_child(row)
	var gamepad := Input.get_connected_joypads().size() > 0
	# "boost" shares the jump key, so labelling it "boost" next to "jump" reads as two verbs on one
	# key with no explanation (integration critic). "hold to fly" says what it actually does.
	# "journal" is the favours log on J - it needs to be discoverable or nobody finds it.
	# ADDED BY THE PLAYER BUILDER with mouse look (src/player/camera_rig.gd). The player's report was
	# *"I can't control the camera well I dont think"* - and until now the hint strip listed every
	# verb in the game EXCEPT how to move the camera, so even the keys that did work were invisible.
	# "look" sits straight after "move" because that is the pair a player reads first.
	var pairs := [["move", "move"], ["camera_right", "look"], ["jump", "jump"], ["boost", "hold to fly"], ["interact", "talk"], ["decorate", "decorate"], ["inventory", "bag"], ["journal", "favours"]]
	for i in pairs.size():
		var p: Array = pairs[i]
		var pair := HBoxContainer.new()
		pair.add_theme_constant_override("separation", 5)
		pair.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var g := KeyGlyph.new()
		g.font_size = 13
		if str(p[0]) == "move":
			g.set_text("LS" if gamepad else "WASD")
		elif str(p[0]) == "camera_right":
			# The mouse is the real camera control on a keyboard; the H/L/K/M keys are the fallback
			# and would be a misleading thing to advertise first.
			g.set_text("RS" if gamepad else "Mouse")
		else:
			g.set_action(str(p[0]))
		g.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		pair.add_child(g)
		pair.add_child(UIStyle.make_label(str(p[1]), "Hint"))
		row.add_child(pair)
		if i < pairs.size() - 1:
			row.add_child(UIStyle.make_label("·", "Hint"))

# ----------------------------------------------------------------------------- mobile layout (R2.10)
## Moves and shrinks the world-facing chrome for whichever front end is running. Called on ready,
## on `Platform.mode_changed` and on resize, so a runtime UI-mode switch (pause -> Settings -> UI
## mode) re-lays-out immediately rather than needing a reload.
##
## The mobile rules, all from R2.10:
##   * stardust and clock SHRINK into the safe area at the top,
##   * the interact prompt moves from bottom-centre (dead under the right thumb, and duplicated by
##     the context button's own label) to top-centre,
##   * the jetpack pill leaves the bottom-left, which is the movement stick's corner,
##   * toasts park top-right under the clock instead of bottom-right under the action cluster,
##   * nothing sits inside `Platform.safe_area_insets()`.
func _apply_platform_layout() -> void:
	if _stardust_pill == null:
		return
	var mobile := MobileUI.is_mobile()
	var sa := MobileUI.safe_area()
	var edge: float = MobileUI.EDGE if mobile else EDGE
	var scale: float = MOBILE_PILL_SCALE if mobile else 1.0

	_stardust_pill.scale = Vector2(scale, scale)
	_stardust_pill.pivot_offset = Vector2.ZERO
	_stardust_pill.position = Vector2(sa.x + edge, sa.y + (edge if mobile else EDGE - 4.0))

	# Same row as the stardust pill, SCRAP_PILL_OFFSET_X to its right - see that constant for why
	# this is a fixed offset and not a width read off `_stardust_pill` at runtime.
	_scrap_pill.scale = Vector2(scale, scale)
	_scrap_pill.pivot_offset = Vector2.ZERO
	_scrap_pill.position = Vector2(sa.x + edge + SCRAP_PILL_OFFSET_X, sa.y + (edge if mobile else EDGE - 4.0))

	_clock_pill.scale = Vector2(scale, scale)
	_clock_pill.pivot_offset = Vector2(_clock_pill.size.x, 0.0)
	_clock_pill.offset_right = -(sa.z + edge)
	_clock_pill.offset_top = sa.y + edge

	if mobile:
		_prompt.set_anchors_preset(Control.PRESET_CENTER_TOP)
		_prompt.grow_horizontal = Control.GROW_DIRECTION_BOTH
		_prompt.grow_vertical = Control.GROW_DIRECTION_END
		_prompt.offset_top = sa.y + edge + MOBILE_PROMPT_TOP
		_prompt.offset_bottom = _prompt.offset_top
		_jet_pill.set_anchors_preset(Control.PRESET_TOP_LEFT)
		_jet_pill.grow_vertical = Control.GROW_DIRECTION_END
		_jet_pill.offset_left = sa.x + edge
		_jet_pill.offset_top = sa.y + edge + MOBILE_JET_TOP
		_jet_pill.offset_bottom = _jet_pill.offset_top
	else:
		_prompt.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
		_prompt.grow_horizontal = Control.GROW_DIRECTION_BOTH
		_prompt.grow_vertical = Control.GROW_DIRECTION_BEGIN
		_prompt.offset_bottom = -PROMPT_BOTTOM
		_prompt.offset_top = _prompt.offset_bottom
		_jet_pill.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
		_jet_pill.grow_vertical = Control.GROW_DIRECTION_BEGIN
		_jet_pill.offset_left = EDGE
		_jet_pill.offset_bottom = -EDGE - JET_PILL_LIFT
		_jet_pill.offset_top = _jet_pill.offset_bottom
	_layout_toasts()


# ----------------------------------------------------------------------------- chrome
## Fades the world-facing HUD chrome in / out. Driven by the modal count, so nested modals
## (dialogue -> shop -> confirm) only restore it once the last one has closed.
func _set_chrome_shown(want: bool) -> void:
	if _chrome == null or want == _chrome_shown:
		return
	_chrome_shown = want
	if _chrome_tween != null and _chrome_tween.is_valid():
		_chrome_tween.kill()
	if want:
		_chrome.visible = true
	_chrome_tween = create_tween()
	_chrome_tween.tween_property(_chrome, "modulate:a", 1.0 if want else 0.0, CHROME_FADE) \
		.set_trans(Tween.TRANS_SINE)
	if not want:
		_chrome_tween.tween_callback(func() -> void:
			if not _chrome_shown:
				_chrome.visible = false)

# ----------------------------------------------------------------------------- toasts
## Toast placement for the currently open modals (see ToastSpot).
func _wanted_toast_spot() -> ToastSpot:
	var overlay := false
	for modal_name in _open_modals:
		if int(_open_modals[modal_name]) <= 0:
			continue
		if OVERLAY_MODALS.has(str(modal_name)):
			overlay = true
		else:
			return ToastSpot.HELD
	return ToastSpot.PARKED if overlay else ToastSpot.CORNER

func _apply_toast_spot() -> void:
	var want := _wanted_toast_spot()
	if want == _toast_spot:
		return
	_toast_spot = want
	_layout_toasts()
	if want == ToastSpot.HELD:
		# A panel is about to cover the frame: slide any live toast away instead of letting it sit
		# on top of the panel's buttons.
		for c in toasts.get_children():
			if c is Toast:
				(c as Toast).dismiss(TOAST_HIDE_FAST)
	else:
		_flush_timer = 0.0

func _layout_toasts() -> void:
	var slots := MAX_TOASTS_PARKED if _toast_spot == ToastSpot.PARKED else MAX_TOASTS
	var stack_h := (Toast.HEIGHT + TOAST_GAP) * float(slots)
	# MOBILE (R2.10): "toasts must not sit under the thumbs". The bottom-right corner is the action
	# cluster, so the stack lives top-right for good, tucked under the clock and inside the safe area.
	if MobileUI.is_mobile():
		var sa := MobileUI.safe_area()
		toasts.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		toasts.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		toasts.grow_vertical = Control.GROW_DIRECTION_END
		toasts.offset_right = -(sa.z + MobileUI.EDGE)
		toasts.offset_left = toasts.offset_right - Toast.WIDTH
		toasts.offset_top = sa.y + MobileUI.EDGE + MOBILE_TOAST_TOP
		toasts.offset_bottom = toasts.offset_top + stack_h
		toasts.alignment = BoxContainer.ALIGNMENT_BEGIN
		toasts.add_theme_constant_override("separation", int(TOAST_GAP))
		toasts.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return
	if _toast_spot == ToastSpot.PARKED:
		toasts.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		toasts.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		toasts.grow_vertical = Control.GROW_DIRECTION_END
		toasts.offset_right = -EDGE
		toasts.offset_left = -EDGE - Toast.WIDTH
		toasts.offset_top = EDGE
		toasts.offset_bottom = EDGE + stack_h
		toasts.alignment = BoxContainer.ALIGNMENT_BEGIN
	else:
		toasts.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
		toasts.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		toasts.grow_vertical = Control.GROW_DIRECTION_BEGIN
		toasts.offset_right = -EDGE
		toasts.offset_bottom = -EDGE
		toasts.offset_left = -EDGE - Toast.WIDTH
		toasts.offset_top = -EDGE - stack_h
		toasts.alignment = BoxContainer.ALIGNMENT_END
	toasts.add_theme_constant_override("separation", int(TOAST_GAP))
	toasts.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _spawn_toast(text: String, icon: String) -> void:
	var t := Toast.new()
	toasts.add_child(t)
	t.setup(text, icon)
	UIStyle.play_sfx("ui_open", -6.0)
	var live: Array[Toast] = []
	for c in toasts.get_children():
		if c is Toast:
			live.append(c)
	var slots := MAX_TOASTS_PARKED if _toast_spot == ToastSpot.PARKED else MAX_TOASTS
	while live.size() > slots:
		var old: Toast = live.pop_front()
		old.dismiss()

# ----------------------------------------------------------------------------- events
func _on_modal_opened(modal_name: String) -> void:
	_open_modals[modal_name] = int(_open_modals.get(modal_name, 0)) + 1
	_set_chrome_shown(false)
	_apply_toast_spot()
	_refresh_prompt_visibility()

func _on_modal_closed(modal_name: String) -> void:
	var left := maxi(0, int(_open_modals.get(modal_name, 0)) - 1)
	if left == 0:
		_open_modals.erase(modal_name)
	else:
		_open_modals[modal_name] = left
	_set_chrome_shown(not EventBus.is_modal_open())
	_apply_toast_spot()
	_refresh_prompt_visibility()

func _on_stardust_changed(amount: int, delta: int) -> void:
	_stardust_label.text = str(amount)
	UIStyle.bump(_stardust_pill, 1.18)
	_stardust_star.spin_once()
	if delta == 0:
		return
	var f := UIStyle.make_label(("+%d" if delta > 0 else "%d") % delta, "Header")
	f.add_theme_color_override("font_color", UIStyle.GREEN_EDGE if delta > 0 else UIStyle.ORANGE)
	f.add_theme_color_override("font_outline_color", UIStyle.WHITE)
	f.add_theme_constant_override("outline_size", 6)
	f.position = _stardust_pill.position + Vector2(_stardust_pill.size.x + 10.0, FLOAT_START_Y)
	_float_layer.add_child(f)
	f.pivot_offset = Vector2(0.0, 16.0)
	f.scale = Vector2(0.6, 0.6)
	var t := create_tween().set_parallel(true)
	t.tween_property(f, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(f, "position:y", f.position.y - FLOAT_RISE, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(f, "modulate:a", 0.0, 0.5).set_delay(0.5)
	t.chain().tween_callback(f.queue_free)

## Mirrors `_on_stardust_changed` for the scrap pill (BUILD_PLAN Phase 1 "D") - same bump + floater
## feedback, so the two currencies read as one family of counters.
func _on_scrap_changed(amount: int, delta: int) -> void:
	_scrap_label.text = str(amount)
	UIStyle.bump(_scrap_pill, 1.18)
	if delta == 0:
		return
	var f := UIStyle.make_label(("+%d" if delta > 0 else "%d") % delta, "Header")
	f.add_theme_color_override("font_color", UIStyle.GREEN_EDGE if delta > 0 else UIStyle.ORANGE)
	f.add_theme_color_override("font_outline_color", UIStyle.WHITE)
	f.add_theme_constant_override("outline_size", 6)
	f.position = _scrap_pill.position + Vector2(_scrap_pill.size.x + 10.0, FLOAT_START_Y)
	_float_layer.add_child(f)
	f.pivot_offset = Vector2(0.0, 16.0)
	f.scale = Vector2(0.6, 0.6)
	var t := create_tween().set_parallel(true)
	t.tween_property(f, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(f, "position:y", f.position.y - FLOAT_RISE, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(f, "modulate:a", 0.0, 0.5).set_delay(0.5)
	t.chain().tween_callback(f.queue_free)

func _on_time_changed(hour: float) -> void:
	_clock_label.text = "%s · Day %d" % [UIStyle.format_clock(hour), GameState.day_count]

## Resolves the display name of a planet id (home = GameState.home_planet_name, else PlanetData.display_name).
static func planet_display_name(planet_id: String) -> String:
	if planet_id == "home":
		return GameState.home_planet_name
	var path := "res://src/planet/data/%s.tres" % planet_id
	if ResourceLoader.exists(path):
		var data: Resource = load(path)
		if data != null and data.get("display_name") != null:
			return str(data.get("display_name"))
	return planet_id.capitalize()

func _on_planet_loaded(planet_id: String) -> void:
	_banner_name.text = planet_display_name(planet_id)
	_banner_sub.text = "Welcome home to" if planet_id == "home" else "Now arriving at"
	# The rocket sets `rocket_arriving` while it flies the arrival descent, which starts at the same
	# instant as this banner and in the same part of the screen. The banner used to sit on top of the
	# descending rocket; parking it small in the corner (OPEN_ISSUES #8) kept it off the rocket but,
	# because the rocket also opens a "cutscene" modal that fades the whole chrome layer out, it was
	# then never actually SEEN. So hold it instead and play it in full at touchdown, where "Now
	# arriving at Zorp" is the beat it was written for. `_process` starts it when the flag clears.
	if GameState.flag("rocket_arriving"):
		_banner_pending = true
		_banner_pending_timer = BANNER_PENDING_MAX
		_banner.visible = false
		return
	_banner_pending = false
	_play_banner()

## Slides the arrival banner in, holds it, and fades it out.
func _play_banner() -> void:
	_banner.reset_size()
	if _banner_tween != null and _banner_tween.is_valid():
		_banner_tween.kill()
	_banner.visible = true
	_banner.modulate.a = 1.0
	_banner.pivot_offset = _banner.size * 0.5
	_banner.scale = Vector2.ONE
	_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_banner.offset_left = -_banner.size.x * 0.5
	_banner.offset_top = -_banner.size.y - 40.0
	# Strictly sequential: slide in, HOLD, then fade. (set_parallel(true) used to attach the fade to the
	# interval step, so the banner faded away during the hold and was gone well before BANNER_HOLD.)
	_banner_tween = create_tween()
	_banner_tween.tween_property(_banner, "offset_top", BANNER_TOP, BANNER_SLIDE) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_banner_tween.tween_interval(BANNER_HOLD)
	_banner_tween.tween_property(_banner, "modulate:a", 0.0, BANNER_FADE).set_trans(Tween.TRANS_SINE)
	_banner_tween.parallel().tween_property(_banner, "offset_top", BANNER_TOP - BANNER_RISE, BANNER_FADE) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_banner_tween.chain().tween_callback(func() -> void: _banner.visible = false)

func _on_prompt_changed(text: String) -> void:
	# On mobile the trailing key hint ("Place - Q/R turn") is dropped: there is no Q or R, and the
	# touch cluster puts real rotate buttons on screen instead (MobileUI.clean_prompt).
	_prompt_text = MobileUI.clean_prompt(text)
	_prompt_label.text = _prompt_text
	_refresh_prompt_visibility()

func _refresh_prompt_visibility() -> void:
	var want := _prompt_text != "" and not EventBus.is_modal_open()
	# MOBILE: the prompt lives at TOP-centre (the bottom belongs to the thumbs), which is also where
	# the arrival banner plays. The banner wins for its ~3.5 s - the context button in the action
	# cluster is already showing the same verb, so nothing is actually lost.
	if want and MobileUI.is_mobile() and _banner != null and _banner.visible:
		want = false
	if want and not _prompt.visible:
		_prompt.reset_size()
		_prompt.pivot_offset = Vector2(_prompt.size.x * 0.5, _prompt.size.y)
		UIStyle.pop_in(_prompt, 0.22, 0.8)
	elif not want and _prompt.visible:
		UIStyle.pop_out(_prompt, 0.14, 0.85)
	_hints.visible = _hints_timer > 0.0 and not EventBus.is_modal_open()

func _on_toast(text: String, icon: String) -> void:
	if _toast_spot == ToastSpot.HELD:
		# Never queue the same line twice behind a panel.
		for pending in _pending_toasts:
			if str(pending[0]) == text:
				return
		_pending_toasts.append([text, icon])
		while _pending_toasts.size() > MAX_TOASTS:
			_pending_toasts.pop_front()
		return
	# Damping (integration critic): if the SAME line is already on screen, refresh it instead of
	# stacking a second copy. Two different pickups still get two toasts; a nag that fires again
	# while its own toast is still up cannot pile up. The rocket's "follow the arrows" hint repeats
	# on a timer that outlives one toast, so its real fix belongs to the rocket builder - this only
	# guarantees the stack never shows duplicates.
	for c in toasts.get_children():
		var t := c as Toast
		if t != null and not t.is_dismissing() and t.text() == text:
			t.refresh()
			return
	_spawn_toast(text, icon)

## Adds a toast directly (same as EventBus.toast_requested).
func toast(text: String, icon: String = "") -> void:
	_on_toast(text, icon)

# ----------------------------------------------------------------------------- process
func _process(delta: float) -> void:
	_update_jet_fuel(delta)
	_update_arrival_hold(delta)
	_update_placement_hint(delta)
	# The mobile prompt shares the top of the screen with the arrival banner, so its visibility has
	# to follow the banner going away as well as the prompt text changing.
	if MobileUI.is_mobile() and _prompt_text != "" and _prompt.visible == _banner.visible:
		_refresh_prompt_visibility()
	if _banner_pending:
		_banner_pending_timer -= delta
		if _banner_pending_timer <= 0.0 or not GameState.flag("rocket_arriving"):
			_banner_pending = false
			_play_banner()
	if not _pending_toasts.is_empty() and _toast_spot != ToastSpot.HELD:
		_flush_timer -= delta
		if _flush_timer <= 0.0:
			_flush_timer = TOAST_FLUSH_STAGGER
			var pair: Array = _pending_toasts.pop_front()
			_spawn_toast(str(pair[0]), str(pair[1]))
	if _hints_timer > 0.0:
		_hints_timer -= delta
		if _hints_timer <= 0.0:
			var t := create_tween()
			t.tween_property(_hints, "modulate:a", 0.0, 0.8)
			t.tween_callback(func() -> void: _hints.visible = false)
	if get_tree().paused and not pause_menu.is_open:
		return
	if SceneRouter.is_busy():
		return
	# Pause must work even while placing a decoration or holding a conversation - it is the player's
	# escape hatch, and trapping them with no way to reach Save or Quit is exactly the kind of
	# soft-lock this project has already been bitten by three times. An OVERLAY modal (the speech
	# box) leaves most of the screen free and does not own the `pause` key, so it lets `pause`
	# through; a full-screen panel (bag / shop / the pause menu itself) handles its own keys and
	# blocks it. The bag and the decorate key stay blocked during placement and dialogue, because
	# opening them there is genuinely ambiguous.
	var blocking := _has_blocking_modal()
	if not blocking and Input.is_action_just_pressed("pause"):
		pause_menu.open()
		return
	if blocking or _placement_active:
		return
	if Input.is_action_just_pressed("inventory"):
		inventory.open("all")
	elif Input.is_action_just_pressed("decorate"):
		inventory.open("decorations")

## True when a modal that owns the whole frame (or the keyboard) is up. Overlay modals - currently
## just the speech box - are deliberately NOT blocking, so `pause` still opens over them.
func _has_blocking_modal() -> bool:
	for modal_name in EventBus.open_modals():
		if not OVERLAY_MODALS.has(str(modal_name)):
			return true
	return false

# ----------------------------------------------------------------------------- scrap icon
## Small procedural scrap icon for the HUD pill (BUILD_PLAN Phase 1 "D"): a bent hull plate with a
## bolt, drawn with the exact metal/rust colors of the scrap pickup's own mesh (collectible.gd) and
## of the space-trash piece it comes from (trash_piece.gd `_build_scrap`) - the counter, the pickup
## and the litter it replaces all read as one material. Deliberately grey, not a new saturated hue:
## STYLE_GUIDE "UI — Moonstone" keeps amber as "the ONE accent" (reserved for stardust).
## Nested here (as Toast.SymbolIcon is nested in toast.gd) since only this file needs it.
class ScrapIcon extends Control:
	const METAL := Color("#8a8496")
	const METAL_EDGE := Color("#65607a")
	const RUST := Color("#c2703f")
	@export var icon_size: float = 28.0:
		set(v):
			icon_size = v
			custom_minimum_size = Vector2(v, v)
			queue_redraw()

	func _ready() -> void:
		custom_minimum_size = Vector2(icon_size, icon_size)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := size * 0.5
		var s := minf(size.x, size.y) * 0.5
		# An irregular quad tilted like the plate in trash_piece.gd's `_build_scrap`, not a clean
		# rectangle - a scrap of hull plating, not a UI swatch.
		var plate := PackedVector2Array([
			c + Vector2(-s * 0.85, -s * 0.12),
			c + Vector2(s * 0.32, -s * 0.65),
			c + Vector2(s * 0.85, s * 0.32),
			c + Vector2(-s * 0.48, s * 0.70),
		])
		draw_colored_polygon(plate, METAL)
		var closed := plate.duplicate()
		closed.append(plate[0])
		draw_polyline(closed, METAL_EDGE, maxf(1.2, s * 0.08), true)
		# The bolt sticking through it, same as the ground pickup.
		UIDraw.circle(self, c + Vector2(s * 0.30, -s * 0.22), s * 0.26, RUST)
		UIDraw.circle(self, c + Vector2(s * 0.30, -s * 0.22), s * 0.11, METAL_EDGE)
