class_name SafariLayer
extends CanvasLayer
## THE SAFARI'S OWN SCREEN LAYER (docs/PLANET_SAFARI_SPEC.md 5.2, 5.3; builder P3). Everything the
## player sees and touches during a planet safari that is not the world: the Camera button, the
## shutter, the Walk button, the zoom slider, the viewfinder, the film counter, the sun-dial, the
## black fade, the shutter flash, a line of text, and - until builder P5's review exists - a plain
## list of the photos at the end.
##
## Owned by PlanetSafari (its child), so it is gone when the safari is. The game's own HUD and phone
## buttons step aside through PhotoMode (builder P2); the stick and drag-to-look stay theirs.
##
## TOUCH ORDER. TouchControls claims every touch on the right half of the screen for drag-to-look in
## its `_input`. `_input` runs in REVERSE tree order, and this layer lives under /root/World/
## PlanetSafari, added after /root/World/HUD, so it sees each touch first: a touch on one of these
## controls is claimed and marked handled here and never becomes a camera drag. Everything else
## passes through untouched.
##
## SIZES are in the GUI's logical pixels. On the phone the GUI is a keep-height stretch of a 720-high
## canvas (a 1179-px-high iPhone draws 1 logical px as 1.64 device px), so the smallest text here, 18,
## is 29 device px - over the 22 the brief sets. The big buttons reuse MobileUI's own radii (the
## primary button's 66/78 and a satellite's 44/54), at the primary button's own spot, which P2's gate
## has emptied.

const LAYER := 30
const FADE_LAYER := 99

const TEXT_MIN := 18
const TEXT_BODY := 22
const SLIDER_W := 72.0
## The zoom control's backing pill, narrower than its 72 px touch strip.
const TRACK_W := 50.0
## The knob travels this far inside each end of the strip, leaving room for the "+" and "-": the glyphs
## sit 2..18 px in from the ends and the 24 px knob stops 22 px in, so neither is ever covered
## (at 26 the knob hid the "+" when zoomed in and the "-" when wide - seen on the phone frame).
const KNOB_INSET := 46.0
const DIAL_R := 44.0
## The viewfinder's focus ring, in the GUI's logical pixels (the same units as the scorer's frame).
## It is ALSO the focus area: whatever the ring touches is what the lens focuses on
## (SafariPhotoScorer.centre_ray_focus), so what the player sees is exactly what focuses.
const AF_RING_R := 26.0

## THE END BUTTON (docs/PLANET_SAFARI_SPEC.md 17.2.1, the user: "We should have an End Safari button
## (somewhere out of the way so its not accidentally clicked)"). A small pill in the TOP-RIGHT corner,
## clear of the shutter/Walk cluster and the zoom slider (both bottom/right-middle): a tap alone never
## ends the safari, it only opens the confirm card (PlanetSafari.request_end).
const END_W := 84.0
const END_H := 40.0

var safari: PlanetSafari

var _root: Control
var _ui: _Drawer
var _flash: ColorRect
var _fade_layer: CanvasLayer
var _fade: ColorRect
var _banner: PanelContainer
var _banner_label: Label
var _banner_left := 0.0
var _review: Control

# Layout (logical px), rebuilt each frame from the viewport and the safe area.
var main_c := Vector2.ZERO
var main_r := MobileUI.PRIMARY_R
var main_hit := MobileUI.PRIMARY_HIT_R
var alt_c := Vector2.ZERO
var alt_r := MobileUI.SAT_R
var alt_hit := MobileUI.SAT_HIT_R
var slider_rect := Rect2()
var dial_c := Vector2.ZERO
var film_pos := Vector2.ZERO
var frame_size := Vector2.ZERO
## The End button's hit rect, top-right corner (see END_W/END_H).
var end_rect := Rect2()
## THE HOVER BUTTON (builder HOVER; PlanetSafari.hover_enabled): a satellite-sized round button on the
## bottom row, just LEFT of the Camera/shutter button - never over it, and clear of the Walk button (above
## the shutter) and the zoom slider (right edge). Its rim is the fuel meter: the arc is the tank.
var hover_c := Vector2.ZERO
var hover_r := MobileUI.SAT_R
var hover_hit := MobileUI.SAT_HIT_R

## pointer id -> role ("raise", "shutter", "lower", "slider")
var _pointers: Dictionary = {}
var _saw_touch := false
## For a test report: where the last press landed and what it did.
var last_press := {}


func _ready() -> void:
	layer = LAYER
	name = "SafariLayer"
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_ui = _Drawer.new()
	_ui.owner_layer = self
	_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_ui)
	_flash = ColorRect.new()
	_flash.color = Color(1, 1, 1, 0)
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash)
	_build_banner()
	_fade_layer = CanvasLayer.new()
	_fade_layer.layer = FADE_LAYER
	add_child(_fade_layer)
	_fade = ColorRect.new()
	_fade.color = Color(UIStyle.NAVY, 0.0)
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_layer.add_child(_fade)
	_root.visible = false


func _build_banner() -> void:
	_banner = PanelContainer.new()
	_banner.add_theme_stylebox_override("panel", UIStyle.make_pill_style(Color(UIStyle.NAVY, 0.72), Color(UIStyle.CREAM, 0.5), 2))
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner_label = Label.new()
	_banner_label.add_theme_font_override("font", UIStyle.ui_font())
	_banner_label.add_theme_font_size_override("font_size", TEXT_BODY)
	_banner_label.add_theme_color_override("font_color", UIStyle.CREAM)
	_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_child(_banner_label)
	_banner.visible = false
	add_child(_banner)


# ======================================================================================== PUBLIC
func fade_to(alpha: float, secs: float) -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", alpha, maxf(secs, 0.01))
	await tw.finished


func flash() -> void:
	_flash.color = Color(1, 1, 1, 0.85)
	var tw := create_tween()
	tw.tween_property(_flash, "color:a", 0.0, 0.32).set_ease(Tween.EASE_OUT)


func show_awake_ui(on: bool) -> void:
	_root.visible = on
	if not on:
		_pointers.clear()


func banner(text: String, secs: float) -> void:
	_banner_label.text = text
	_banner.visible = true
	_banner_left = secs
	_banner.reset_size()


## `first_step_only`: the first planet safari (spec 15.4) - only how to raise the camera; the rest is
## taught by the three pauses, each when its moment comes, so nothing long is said up front.
func intro_hint(first_step_only: bool = false) -> void:
	if first_step_only:
		banner("Tap Camera to raise it." if MobileUI.is_mobile() else "Right-click or Q to raise the camera.", 4.0)
	elif MobileUI.is_mobile():
		banner("Tap Camera to raise it. Hold the shutter for a sharper photo.", 4.5)
	else:
		banner("Right-click or Q: camera. Click: photo, hold for sharper. Wheel: zoom.", 5.0)


## Drops every button this layer is holding (a pause is about to swallow their releases).
func cancel_pointers() -> void:
	_pointers.clear()


# ======================================================================================== THE TIP CARD
## THE FIRST SAFARI'S PAUSE CARD (spec 15.4; PlanetSafari._show_tip pauses the tree around it). Short:
## a "Tip n of 3" line, the one lesson (two lines at most), "Got it" and "Skip tips". Tapping anywhere
## off the card is "Got it" too, and so is Enter/Space; Esc is "Skip tips". NOT the shutter key (F) or a
## click on the shutter spot: a player still pressing the shutter must not wave the card away unread. Inputs in the first
## TIP_ARM_SEC are ignored, so the very tap that raised the camera cannot dismiss it. Its own CanvasLayer
## runs PROCESS_MODE_ALWAYS - everything else is paused. Awaitable: returns true for "Skip tips".
signal tip_closed(skip_all: bool)
const TIP_ARM_SEC := 0.4
const TIP_LAYER := 70
var _tip_layer: CanvasLayer
var _tip_root: Control
var _tip_ok: Button
var _tip_skip: Button
var _tip_open_ms := 0


func show_tip(text: String, n: int, total: int) -> bool:
	_close_tip_nodes()
	# A banner would sit frozen behind the card (its timer is paused with the tree): take it down.
	_banner.visible = false
	_tip_layer = CanvasLayer.new()
	_tip_layer.layer = TIP_LAYER
	_tip_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_tip_layer)
	_tip_root = Control.new()
	_tip_root.name = "SafariTip"
	_tip_root.process_mode = Node.PROCESS_MODE_ALWAYS
	_tip_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tip_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_tip_root.theme = UIStyle.theme()
	MobileUI.apply_theme(_tip_root)
	_tip_layer.add_child(_tip_root)
	var dim := ColorRect.new()
	dim.color = Color(UIStyle.NAVY, 0.28)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tip_root.add_child(dim)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIStyle.make_panel_style())
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_tip_root.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	panel.add_child(col)
	var head := _label("Tip %d of %d" % [n, total], TEXT_MIN, UIStyle.TEXT_SOFT)
	head.autowrap_mode = TextServer.AUTOWRAP_OFF
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(head)
	var body := _label(text, TEXT_BODY + 4, UIStyle.TEXT_BROWN)
	# Two short lines with their own "\n": no autowrap, so the card's minimum size is exact on its first
	# frame (an autowrapped label measured before layout is one word wide and many lines tall).
	body.autowrap_mode = TextServer.AUTOWRAP_OFF
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(body)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	col.add_child(row)
	_tip_skip = UIStyle.make_button("Skip tips", "Pill", 150.0)
	_tip_ok = UIStyle.make_button("Got it", "PillPrimary", 170.0)
	if MobileUI.is_mobile():
		_tip_skip.custom_minimum_size.y = MobileUI.MIN_TOUCH
		_tip_ok.custom_minimum_size.y = MobileUI.MIN_TOUCH
	row.add_child(_tip_skip)
	row.add_child(_tip_ok)
	_tip_ok.pressed.connect(func() -> void: _tip_answer(false))
	_tip_skip.pressed.connect(func() -> void: _tip_answer(true))
	_tip_root.gui_input.connect(_on_tip_backdrop_input)
	var ok_btn := _tip_ok
	ok_btn.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventKey and _tip_key(e as InputEventKey) and is_instance_valid(ok_btn):
			ok_btn.accept_event())
	# The desktop's mouse look lets the cursor go when a modal opens (PlanetSafari emits one first);
	# made sure of here, since the rig that would do it is paused.
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# Low in the frame, centred, so the view it is about stays in sight. Placed again after one frame,
	# once the containers have settled (the tree is paused, but frames still run).
	panel.modulate.a = 0.0
	_place_tip_panel(panel)
	get_tree().process_frame.connect(func() -> void:
		if is_instance_valid(panel):
			_place_tip_panel(panel)
			panel.modulate.a = 1.0, CONNECT_ONE_SHOT)
	_tip_open_ms = Time.get_ticks_msec()
	_tip_ok.grab_focus.call_deferred()
	UIStyle.play_open()
	var skip_all: bool = await tip_closed
	_close_tip_nodes()
	return skip_all


func _place_tip_panel(panel: PanelContainer) -> void:
	var vp := get_viewport().get_visible_rect().size
	var sa := MobileUI.safe_area()
	panel.custom_minimum_size = Vector2(minf(460.0, vp.x - sa.x - sa.z - 32.0), 0.0)
	panel.reset_size()
	panel.position = Vector2((vp.x - panel.size.x) * 0.5, vp.y - sa.w - panel.size.y - 28.0)


func tip_showing() -> bool:
	return _tip_root != null and is_instance_valid(_tip_root)


func _tip_armed() -> bool:
	return Time.get_ticks_msec() - _tip_open_ms >= int(TIP_ARM_SEC * 1000.0)


func _tip_answer(skip_all: bool) -> void:
	if not tip_showing() or not _tip_armed():
		return
	UIStyle.play_close()
	tip_closed.emit(skip_all)


## 17.1 rule 1: a tap INSIDE THE SHUTTER'S HIT CIRCLE does nothing at all while the card is up - not
## even "Got it" - so a reflex shutter tap cannot wave a lesson away unread. Measured the gap this
## fixes: before this guard, the tip's own full-screen backdrop caught a shutter-spot tap first and
## dismissed the card on it (a UIG probe run showed the film untouched, as expected, but the card
## still closed on the very tap the header says it must not). A tap anywhere else still closes it.
func _on_tip_backdrop_input(event: InputEvent) -> void:
	var pos := Vector2.ZERO
	var pressed := false
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		pressed = true
		pos = (event as InputEventMouseButton).position
	elif event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		pressed = true
		pos = (event as InputEventScreenTouch).position
	if not pressed:
		return
	_tip_root.accept_event()
	if pos.distance_to(main_c) <= main_hit:
		return
	_tip_answer(false)


## Keys while the card is up. This layer's own `_input` is paused with the tree, so the keys reach the
## card through its focused "Got it" button (Enter/Space press it as ui_accept; this adds Esc).
func _tip_key(k: InputEventKey) -> bool:
	if not tip_showing() or not k.pressed or k.echo:
		return false
	if k.physical_keycode == KEY_ESCAPE:
		_tip_answer(true)
		return true
	if k.physical_keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
		_tip_answer(false)
		return true
	return false


func _close_tip_nodes() -> void:
	if _tip_layer != null and is_instance_valid(_tip_layer):
		_tip_layer.queue_free()
	_tip_layer = null
	_tip_root = null
	_tip_ok = null
	_tip_skip = null


## Test hook: a REAL tap (MobileUI.synth_tap - an InputEventMouseButton through the input pipeline, not
## a signal emit) on "Got it" (`which` "ok"), "Skip tips" ("skip") or the dimmed backdrop ("off").
## Returns false when no card is up.
func debug_tip_tap(which: String) -> bool:
	if not tip_showing():
		return false
	var sa := MobileUI.safe_area()
	var pos := Vector2(sa.x + 8.0, sa.y + 8.0) if which == "off" else \
		(_tip_skip if which == "skip" else _tip_ok).get_global_rect().get_center()
	MobileUI.synth_tap(pos)
	return true


# ======================================================================================== THE CHOICE CARD
## A GENERIC two-button question, same pausing mechanism as the tip card above (its own
## PROCESS_MODE_ALWAYS layer, the rest of the tree frozen) - so a shutter tap behind it does nothing,
## exactly as rule 1 requires of the tip card (17.1). Used for the End-safari confirm and the
## out-of-film card (17.2.1); PlanetSafari owns what each one asks and does with the answer. No arm
## delay: unlike the tip card, nothing opens this on the same tap that could also land on a button
## inside it (End button and card live in different corners; PlanetSafari defers a whole frame after
## the last plate before offering the film-out card). Returns true for `primary_text`, false for
## `secondary_text`; the dimmed backdrop always answers `secondary_text` (the safe, non-ending choice).
signal choice_closed(primary: bool)
const CHOICE_LAYER := 71
var _choice_layer: CanvasLayer
var _choice_root: Control
var _choice_primary: Button
var _choice_secondary: Button


func show_choice_card(text: String, primary_text: String, secondary_text: String) -> bool:
	_close_choice_nodes()
	_banner.visible = false
	_choice_layer = CanvasLayer.new()
	_choice_layer.layer = CHOICE_LAYER
	_choice_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_choice_layer)
	_choice_root = Control.new()
	_choice_root.name = "SafariChoice"
	_choice_root.process_mode = Node.PROCESS_MODE_ALWAYS
	_choice_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_choice_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_choice_root.theme = UIStyle.theme()
	MobileUI.apply_theme(_choice_root)
	_choice_layer.add_child(_choice_root)
	var dim := ColorRect.new()
	dim.color = Color(UIStyle.NAVY, 0.28)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_choice_root.add_child(dim)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIStyle.make_panel_style())
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_choice_root.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	panel.add_child(col)
	var body := _label(text, TEXT_BODY + 4, UIStyle.TEXT_BROWN)
	body.autowrap_mode = TextServer.AUTOWRAP_OFF
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(body)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	col.add_child(row)
	_choice_secondary = UIStyle.make_button(secondary_text, "Pill", 170.0)
	_choice_primary = UIStyle.make_button(primary_text, "PillPrimary", 170.0)
	if MobileUI.is_mobile():
		_choice_secondary.custom_minimum_size.y = MobileUI.MIN_TOUCH
		_choice_primary.custom_minimum_size.y = MobileUI.MIN_TOUCH
	row.add_child(_choice_secondary)
	row.add_child(_choice_primary)
	_choice_primary.pressed.connect(func() -> void: _choice_answer(true))
	_choice_secondary.pressed.connect(func() -> void: _choice_answer(false))
	_choice_root.gui_input.connect(_on_choice_backdrop_input)
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	panel.modulate.a = 0.0
	_place_tip_panel(panel)
	get_tree().process_frame.connect(func() -> void:
		if is_instance_valid(panel):
			_place_tip_panel(panel)
			panel.modulate.a = 1.0, CONNECT_ONE_SHOT)
	_choice_secondary.grab_focus.call_deferred()
	UIStyle.play_open()
	var primary: bool = await choice_closed
	_close_choice_nodes()
	return primary


func choice_showing() -> bool:
	return _choice_root != null and is_instance_valid(_choice_root)


func _choice_answer(primary: bool) -> void:
	if not choice_showing():
		return
	UIStyle.play_close() if not primary else UIStyle.play_confirm()
	choice_closed.emit(primary)


func _on_choice_backdrop_input(event: InputEvent) -> void:
	var pressed := (event is InputEventMouseButton and (event as InputEventMouseButton).pressed) \
		or (event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed)
	if pressed:
		_choice_root.accept_event()
		_choice_answer(false)   # the backdrop is always the safe, non-ending answer


func _close_choice_nodes() -> void:
	if _choice_layer != null and is_instance_valid(_choice_layer):
		_choice_layer.queue_free()
	_choice_layer = null
	_choice_root = null
	_choice_primary = null
	_choice_secondary = null


## Test hook: a REAL tap on the choice card's primary (`which` "primary"), secondary ("secondary") or
## the dimmed backdrop ("off"). Returns false when no card is up.
func debug_choice_tap(which: String) -> bool:
	if not choice_showing():
		return false
	var sa := MobileUI.safe_area()
	var pos := Vector2(sa.x + 8.0, sa.y + 8.0) if which == "off" else \
		(_choice_primary if which == "primary" else _choice_secondary).get_global_rect().get_center()
	MobileUI.synth_tap(pos)
	return true


## Test hook: a REAL tap on the End button (MobileUI.synth_tap), exactly what a finger would do.
func debug_tap_end() -> void:
	MobileUI.synth_tap(end_rect.get_center())


# ======================================================================================== FRAME
func _process(delta: float) -> void:
	_layout()
	if _banner.visible:
		_banner_left -= delta
		if _banner_left <= 0.0:
			_banner.visible = false
		_banner.position = Vector2((frame_size.x - _banner.size.x) * 0.5, MobileUI.safe_area().y + 18.0)
	if _root.visible:
		_ui.queue_redraw()


func _layout() -> void:
	var vp := get_viewport().get_visible_rect().size
	frame_size = vp
	var sa := MobileUI.safe_area()
	var left := sa.x + MobileUI.EDGE
	var right := vp.x - sa.z - MobileUI.EDGE
	var top := sa.y + MobileUI.EDGE
	var bottom := vp.y - sa.w - MobileUI.EDGE
	main_c = Vector2(right - main_hit, bottom - main_hit)
	alt_c = main_c + Vector2(0.0, -(main_r + alt_r + 26.0))
	# Bottom-aligned with the shutter, one gap to its left: the two hit circles are 4 px apart.
	hover_c = main_c + Vector2(-(main_hit + hover_hit + 4.0), main_r - hover_r)
	end_rect = Rect2(Vector2(right - END_W, top), Vector2(END_W, END_H))
	# The zoom's own "Zoom" label pill sits just above the slider (see _draw_slider): pushed down by
	# the End button's height + a gap, so neither ever overlaps it.
	var s_top := end_rect.end.y + 10.0 + 78.0
	var s_bot := alt_c.y - alt_hit - 18.0
	slider_rect = Rect2(Vector2(right - SLIDER_W, s_top), Vector2(SLIDER_W, maxf(s_bot - s_top, 40.0)))
	dial_c = Vector2(left + DIAL_R + 8.0, top + DIAL_R + 6.0)
	# Under the dial, top-left (the phone's bag/journal/pause row, which PhotoMode has emptied): the
	# viewfinder's corners and the zoom slider keep the right-hand side.
	film_pos = Vector2(left, top + DIAL_R * 2.0 + 30.0)


# ======================================================================================== INPUT
func _input(event: InputEvent) -> void:
	if safari == null or not _root.visible or safari.phase != PlanetSafari.Phase.AWAKE:
		return
	if event is InputEventScreenTouch:
		_saw_touch = true
		var t := event as InputEventScreenTouch
		if t.pressed:
			if _press(t.index, t.position):
				get_viewport().set_input_as_handled()
		elif _pointers.has(t.index):
			_release(t.index)
			get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		if _pointers.has(d.index):
			_drag(d.index, d.position)
			get_viewport().set_input_as_handled()
		return
	if event is InputEventKey:
		var k := event as InputEventKey
		if k.echo:
			return
		if k.physical_keycode == KEY_Q and k.pressed:
			safari.set_camera_up(not safari.camera_up)
			get_viewport().set_input_as_handled()
		elif k.physical_keycode == KEY_V and safari.hover_enabled:
			if k.pressed:
				safari.hover_press()
			get_viewport().set_input_as_handled()
		elif k.physical_keycode == KEY_F:
			if k.pressed:
				safari.shutter_down()
			else:
				safari.shutter_up()
			get_viewport().set_input_as_handled()
		return
	# The mouse. Every finger also arrives as an emulated mouse copy (device DEVICE_ID_EMULATION),
	# sometimes BEFORE its touch: ignore every copy by its device, and every mouse event at all once
	# a real touchscreen has shown itself. Measured: without the device test, the first tap on the
	# Camera button of a --ui=mobile window raised the camera (mouse copy) and then fired the shutter
	# (the touch itself), spending a plate.
	if event.device == InputEvent.DEVICE_ID_EMULATION:
		return
	if MobileUI.is_mobile() and (_saw_touch or DisplayServer.is_touchscreen_available()):
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		var captured := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
		if mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			safari.set_camera_up(not safari.camera_up)
			get_viewport().set_input_as_handled()
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			if captured:
				if safari.camera_up:
					if mb.pressed:
						safari.shutter_down()
					else:
						safari.shutter_up()
					get_viewport().set_input_as_handled()
			elif mb.pressed:
				if _press(-1, mb.position):
					get_viewport().set_input_as_handled()
			elif _pointers.has(-1):
				_release(-1)
				get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _pointers.has(-1):
		_drag(-1, (event as InputEventMouseMotion).position)


func _press(id: int, pos: Vector2) -> bool:
	var role := ""
	if end_rect.grow(6.0).has_point(pos):
		role = "end"
		safari.request_end()
	elif safari.hover_enabled and pos.distance_to(hover_c) <= hover_hit:
		role = "hover"
		safari.hover_press()
	elif pos.distance_to(main_c) <= main_hit:
		if safari.camera_up:
			role = "shutter"
			safari.shutter_down()
		else:
			role = "raise"
			safari.set_camera_up(true)
	elif safari.camera_up and pos.distance_to(alt_c) <= alt_hit:
		role = "lower"
		safari.set_camera_up(false)
	elif safari.camera_up and slider_rect.grow(6.0).has_point(pos):
		role = "slider"
		_slide_to(pos)
	last_press = {"id": id, "pos": pos, "role": role if role != "" else "-", "ms": Time.get_ticks_msec()}
	if role == "":
		return false
	_pointers[id] = role
	return true


func _release(id: int) -> void:
	var role := str(_pointers.get(id, ""))
	_pointers.erase(id)
	if role == "shutter":
		safari.shutter_up()


func _drag(id: int, pos: Vector2) -> void:
	if str(_pointers.get(id, "")) == "slider":
		_slide_to(pos)


## Top of the slider = fully zoomed in (12 deg), bottom = wide (45 deg). Linear in the lens's
## magnification (tan of the half angle), so equal slides are equal steps of "how much closer".
func _slide_to(pos: Vector2) -> void:
	var y0 := slider_rect.position.y + KNOB_INSET
	var y1 := slider_rect.end.y - KNOB_INSET
	var f := clampf((pos.y - y0) / maxf(y1 - y0, 1.0), 0.0, 1.0)
	safari.set_zoom_fov(fov_for_fraction(f))


static func fov_for_fraction(f: float) -> float:
	var t_in := tan(deg_to_rad(CameraRig.FP_FOV_MIN) * 0.5)
	var t_out := tan(deg_to_rad(CameraRig.FP_FOV_DEFAULT) * 0.5)
	return rad_to_deg(2.0 * atan(lerpf(t_in, t_out, clampf(f, 0.0, 1.0))))


static func fraction_for_fov(fov: float) -> float:
	var t_in := tan(deg_to_rad(CameraRig.FP_FOV_MIN) * 0.5)
	var t_out := tan(deg_to_rad(CameraRig.FP_FOV_DEFAULT) * 0.5)
	return clampf((tan(deg_to_rad(fov) * 0.5) - t_in) / (t_out - t_in), 0.0, 1.0)


# ======================================================================================== PLAIN REVIEW
## A plain list of the photos, until builder P5's review screen exists. Awaitable: returns when the
## player taps Done. Names only what was photographed; says how many others woke up.
func show_plain_review(session: Dictionary) -> void:
	var modal := "planet_safari_review"
	_review = Control.new()
	_review.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_review.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_review)
	_review.theme = UIStyle.theme()
	MobileUI.apply_theme(_review)
	var dim := ColorRect.new()
	dim.color = UIStyle.BACKDROP
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_review.add_child(dim)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIStyle.make_panel_style())
	var vp := get_viewport().get_visible_rect().size
	panel.position = vp * 0.06
	panel.size = vp * 0.88
	_review.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	panel.add_child(col)
	var photos: Array = session.get("photos", [])
	col.add_child(_label("Your photos (%d)" % photos.size(), UIStyle.SIZE_HEADER, UIStyle.TEXT_BROWN))
	var missed := int(session.get("missed_count", 0))
	if missed > 0:
		var word := "thing" if missed == 1 else "things"
		col.add_child(_label("%d %s woke up that you never saw." % [missed, word], TEXT_BODY, UIStyle.TEXT_SOFT))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	var flow := HFlowContainer.new()
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flow.add_theme_constant_override("h_separation", 14)
	flow.add_theme_constant_override("v_separation", 14)
	scroll.add_child(flow)
	for p: Dictionary in photos:
		flow.add_child(_photo_card(p))
	if photos.is_empty():
		flow.add_child(_label("No photos this time.", TEXT_BODY, UIStyle.TEXT_SOFT))
	var done := UIStyle.make_button("Done", "PillPrimary", 180.0)
	done.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(done)
	EventBus.ui_modal_opened.emit(modal)
	await done.pressed
	EventBus.ui_modal_closed.emit(modal)
	_review.queue_free()
	_review = null


func _photo_card(p: Dictionary) -> Control:
	var card := VBoxContainer.new()
	card.custom_minimum_size = Vector2(260, 0)
	var img: Variant = p.get("image")
	if img is Image:
		var tr := TextureRect.new()
		tr.texture = ImageTexture.create_from_image(img)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.custom_minimum_size = Vector2(260, 260.0 * float((img as Image).get_height()) / float(maxi((img as Image).get_width(), 1)))
		card.add_child(tr)
	var name_s := str(p.get("subject_name", ""))
	card.add_child(_label(name_s if name_s != "" else "Just the view", TEXT_BODY, UIStyle.TEXT_BROWN))
	var sc: Dictionary = p.get("scores", {})
	if name_s != "":
		var nums := "centred %d  size %d  focus %d" % [int(sc.get("centred", 0)), int(sc.get("size", 0)),
			int(sc.get("focus", 0))]
		# Facing only for a subject with a front (spec 11.1): no front, no facing number at all.
		if sc.has("facing"):
			nums += "  facing %d" % int(sc["facing"])
		card.add_child(_label(nums + "  rarity %d" % int(sc.get("rarity", 0)), TEXT_MIN, UIStyle.TEXT_SOFT))
		card.add_child(_label("%s - %d stardust" % [str(p.get("grade", "")), int(p.get("price", 0))], TEXT_MIN, UIStyle.TEXT_SOFT))
	return card


func _label(t: String, size: int, colour: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_override("font", UIStyle.ui_font())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", colour)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


## Test hook: presses Done on the plain review, if it is up.
func debug_close_review() -> void:
	if _review == null:
		return
	for b in _review.find_children("*", "Button", true, false):
		(b as Button).pressed.emit()
		return


# ======================================================================================== DRAWING
class _Drawer:
	extends Control
	var owner_layer: SafariLayer

	func _draw() -> void:
		var L := owner_layer
		var s := L.safari
		if s == null:
			return
		var font := UIStyle.ui_font()
		if s.camera_up:
			_draw_viewfinder(L, s)
		_draw_dial(L, s, font)
		_draw_film(L, s, font)
		_draw_end(L, font)
		if s.hover_enabled:
			_draw_hover(L, s, font)
		if s.camera_up:
			_draw_shutter(L, s, font)
			_draw_round(L.alt_c, L.alt_r, UIStyle.CREAM, UIStyle.CREAM_EDGE, 0.85)
			_text_centred(font, "Walk", L.alt_c + Vector2(0, 7), 20, UIStyle.TEXT_BROWN)
			_draw_slider(L, s, font)
			_draw_nudge(L, s, font)
		else:
			_draw_round(L.main_c, L.main_r, UIStyle.CREAM, UIStyle.CREAM_EDGE, 0.85)
			_draw_camera_glyph(L.main_c + Vector2(0, -10), UIStyle.TEXT_BROWN)
			_text_centred(font, "Camera", L.main_c + Vector2(0, 38), 20, UIStyle.TEXT_BROWN)

	func _draw_round(c: Vector2, r: float, fill: Color, edge: Color, a: float) -> void:
		draw_circle(c, r, Color(fill, a))
		draw_arc(c, r, 0.0, TAU, 48, Color(edge, a), 3.0, true)

	func _text_centred(font: Font, t: String, c: Vector2, size: int, col: Color) -> void:
		var w := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		draw_string(font, Vector2(c.x - w * 0.5, c.y), t, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)

	func _draw_camera_glyph(c: Vector2, col: Color) -> void:
		var body := Rect2(c + Vector2(-22, -13), Vector2(44, 28))
		draw_rect(body, col, false, 3.0)
		draw_rect(Rect2(c + Vector2(-9, -19), Vector2(18, 6)), col, true)
		draw_arc(c + Vector2(0, 1), 9.0, 0.0, TAU, 24, col, 3.0, true)

	func _draw_shutter(L: SafariLayer, s: PlanetSafari, font: Font) -> void:
		var out := s.film_left <= 0
		var ring := UIStyle.NAVY
		if s.holding:
			ring = UIStyle.GREEN if s.focus_settled() else UIStyle.YELLOW
		draw_circle(L.main_c, L.main_r, Color(UIStyle.WHITE, 0.45 if out else 0.9))
		draw_arc(L.main_c, L.main_r - 3.0, 0.0, TAU, 56, Color(ring, 0.9), 6.0, true)
		draw_circle(L.main_c, L.main_r * 0.62, Color(UIStyle.CREAM_DEEP, 0.5 if out else 0.95))
		if out:
			_text_centred(font, "No film", L.main_c + Vector2(0, 7), 20, UIStyle.TEXT_SOFT)

	## THE ZOOM CONTROL (R3, spec 11.1: "the zoom control itself is plainly visible when the camera is up"
	## - the user never found it). A navy pill behind the whole track, so it reads on a bright sky as well
	## as on the dark ground; a "+" at the zoomed-in top and a "-" at the wide bottom; "Zoom" on its own
	## pill above; the knob shows the magnification.
	func _draw_slider(L: SafariLayer, s: PlanetSafari, font: Font) -> void:
		var r := L.slider_rect
		var x := r.position.x + r.size.x * 0.5
		var back := Rect2(Vector2(x - SafariLayer.TRACK_W * 0.5, r.position.y - 6.0),
			Vector2(SafariLayer.TRACK_W, r.size.y + 12.0))
		draw_style_box(UIStyle.make_pill_style(Color(UIStyle.NAVY, 0.62), Color(UIStyle.CREAM, 0.55), 2), back)
		var y_top := r.position.y + SafariLayer.KNOB_INSET
		var y_bot := r.end.y - SafariLayer.KNOB_INSET
		draw_line(Vector2(x, y_top), Vector2(x, y_bot), Color(UIStyle.CREAM, 0.85), 4.0, true)
		# + (zoomed in, top) and - (wide, bottom)
		var pc := Vector2(x, r.position.y + 10.0)
		draw_line(pc + Vector2(-8, 0), pc + Vector2(8, 0), UIStyle.CREAM, 3.0, true)
		draw_line(pc + Vector2(0, -8), pc + Vector2(0, 8), UIStyle.CREAM, 3.0, true)
		var mc := Vector2(x, r.end.y - 10.0)
		draw_line(mc + Vector2(-8, 0), mc + Vector2(8, 0), UIStyle.CREAM, 3.0, true)
		var f := SafariLayer.fraction_for_fov(s.camera_fov)
		var ky := lerpf(y_top, y_bot, f)
		_draw_round(Vector2(x, ky), 24.0, UIStyle.CREAM, UIStyle.CREAM_EDGE, 0.97)
		var mag := tan(deg_to_rad(CameraRig.FP_FOV_DEFAULT) * 0.5) / tan(deg_to_rad(s.camera_fov) * 0.5)
		_text_centred(font, "x%.1f" % mag, Vector2(x, ky + 6), TEXT_MIN_I, UIStyle.TEXT_BROWN)
		var lw := font.get_string_size("Zoom", HORIZONTAL_ALIGNMENT_LEFT, -1, TEXT_MIN_I).x
		var lab := Rect2(Vector2(x - lw * 0.5 - 12.0, back.position.y - 36.0), Vector2(lw + 24.0, 30.0))
		draw_style_box(UIStyle.make_pill_style(Color(UIStyle.NAVY, 0.62), Color(UIStyle.CREAM, 0.55), 2), lab)
		_text_centred(font, "Zoom", Vector2(x, lab.position.y + 22.0), TEXT_MIN_I, UIStyle.CREAM)

	## THE ZOOM NUDGE (spec 11.1): one gentle line on a pill just left of the zoom control, level with its
	## knob, with a small arrow pointing at it. Shown only while PlanetSafari.zoom_nudge says so.
	func _draw_nudge(L: SafariLayer, s: PlanetSafari, font: Font) -> void:
		if s.zoom_nudge == "":
			return
		var r := L.slider_rect
		var x := r.position.x + r.size.x * 0.5
		var y_top := r.position.y + SafariLayer.KNOB_INSET
		var y_bot := r.end.y - SafariLayer.KNOB_INSET
		var ky := lerpf(y_top, y_bot, SafariLayer.fraction_for_fov(s.camera_fov))
		var size := SafariLayer.TEXT_BODY
		var w := font.get_string_size(s.zoom_nudge, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		var right := x - SafariLayer.TRACK_W * 0.5 - 18.0
		var box := Rect2(Vector2(right - w - 32.0, ky - 22.0), Vector2(w + 32.0, 44.0))
		draw_style_box(UIStyle.make_pill_style(Color(UIStyle.NAVY, 0.78), Color(UIStyle.YELLOW, 0.9), 2), box)
		draw_string(font, Vector2(box.position.x + 16.0, box.position.y + 30.0), s.zoom_nudge,
			HORIZONTAL_ALIGNMENT_LEFT, -1, size, UIStyle.CREAM)
		var tip := Vector2(right + 12.0, ky)
		draw_colored_polygon(PackedVector2Array([tip, Vector2(right, ky - 9.0), Vector2(right, ky + 9.0)]),
			Color(UIStyle.YELLOW, 0.9))

	const TEXT_MIN_I := 18

	func _draw_viewfinder(L: SafariLayer, s: PlanetSafari) -> void:
		var sz := L.frame_size
		# Inset past the sun-dial and film pill (left, ~9 % of a phone's width) and short of the zoom
		# slider (right), so no corner is drawn over a control.
		var inset := Vector2(sz.x * 0.11, sz.y * 0.07)
		var a := inset
		var b := sz - inset
		var arm := 46.0
		var col := Color(UIStyle.CREAM, 0.85)
		for corner in [Vector2(a.x, a.y), Vector2(b.x, a.y), Vector2(a.x, b.y), Vector2(b.x, b.y)]:
			var dx := arm if corner.x == a.x else -arm
			var dy := arm if corner.y == a.y else -arm
			draw_line(corner, corner + Vector2(dx, 0), col, 4.0, true)
			draw_line(corner, corner + Vector2(0, dy), col, 4.0, true)
		var c := sz * 0.5
		if s.holding:
			var err := absf(log(s.focus_m / maxf(s.focus_target_m, 0.1)) / log(2.0))
			var half := 22.0 + clampf(err, 0.0, 1.0) * 40.0
			var fc := UIStyle.GREEN if s.focus_settled() else UIStyle.YELLOW
			for sx in [-1.0, 1.0]:
				for sy in [-1.0, 1.0]:
					var p := c + Vector2(sx * half, sy * half)
					draw_line(p, p + Vector2(-sx * 12.0, 0), fc, 3.0, true)
					draw_line(p, p + Vector2(0, -sy * 12.0), fc, 3.0, true)
		else:
			draw_arc(c, SafariLayer.AF_RING_R, 0.0, TAU, 40, col, 2.0, true)
			draw_line(c + Vector2(-8, 0), c + Vector2(8, 0), col, 2.0, true)
			draw_line(c + Vector2(0, -8), c + Vector2(0, 8), col, 2.0, true)

	## A small sun (or moon) crossing a half-dial from rise to set as the three minutes pass. No numbers.
	func _draw_dial(L: SafariLayer, s: PlanetSafari, font: Font) -> void:
		var c := L.dial_c + Vector2(0, SafariLayer.DIAL_R * 0.55)
		var r := SafariLayer.DIAL_R
		var frac := clampf(s.elapsed / PlanetSafari.DURATION, 0.0, 1.0)
		# the sky half-disc and the ground line
		draw_arc(c, r, PI, TAU, 40, Color(UIStyle.CREAM, 0.45), 6.0, true)
		draw_arc(c, r, PI, PI + PI * frac, 40, Color(UIStyle.YELLOW if not s.is_night else UIStyle.CREAM, 0.95), 6.0, true)
		draw_line(c + Vector2(-r - 12.0, 0), c + Vector2(r + 12.0, 0), Color(UIStyle.CREAM, 0.8), 3.0, true)
		var ang := PI + PI * frac
		var body := c + Vector2(cos(ang), sin(ang)) * r
		if s.is_night:
			draw_circle(body, 11.0, UIStyle.CREAM)
			draw_circle(body + Vector2(5, -3), 9.0, Color(UIStyle.NAVY, 0.9))
		else:
			draw_circle(body, 11.0, UIStyle.STARDUST)
			draw_arc(body, 11.0, 0.0, TAU, 20, UIStyle.STARDUST_EDGE, 2.0, true)

	func _draw_film(L: SafariLayer, s: PlanetSafari, font: Font) -> void:
		var t := "Film %d" % s.film_left
		var size := 22
		var w := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		var box := Rect2(Vector2(L.film_pos.x, L.film_pos.y - 24.0), Vector2(w + 28.0, 36.0))
		draw_style_box(UIStyle.make_pill_style(Color(UIStyle.NAVY, 0.6), Color(UIStyle.CREAM, 0.5), 2), box)
		draw_string(font, Vector2(box.position.x + 14.0, box.position.y + 26.0), t, HORIZONTAL_ALIGNMENT_LEFT, -1, size, UIStyle.CREAM if s.film_left > 0 else UIStyle.RED)

	## THE HOVER BUTTON: an up-chevron and "Hover" on a cream disc (warm yellow while hovering); its rim is
	## the fuel meter - a full ring on a full tank, draining clockwise from the top, red while too low to
	## light. On a desktop the key, "V", sits under the word.
	func _draw_hover(L: SafariLayer, s: PlanetSafari, font: Font) -> void:
		var p := s.player
		var fuel := p.get_hover_fuel() if is_instance_valid(p) else 1.0
		var on := is_instance_valid(p) and p.is_hovering()
		var low := not on and fuel < Player.HOVER_RESTART_FUEL
		var c := L.hover_c
		var r := L.hover_r
		_draw_round(c, r, UIStyle.YELLOW if on else UIStyle.CREAM, UIStyle.CREAM_EDGE, 0.9 if on else 0.85)
		draw_arc(c, r + 7.0, 0.0, TAU, 48, Color(UIStyle.NAVY, 0.55), 7.0, true)
		if fuel > 0.005:
			var col := UIStyle.RED if low else (UIStyle.STARDUST if on else UIStyle.CREAM)
			draw_arc(c, r + 7.0, -PI * 0.5, -PI * 0.5 + TAU * fuel, 48, col, 5.0, true)
		var ink := Color(UIStyle.TEXT_BROWN, 0.5 if low else 1.0)
		var g := c + Vector2(0, -14)
		draw_polyline(PackedVector2Array([g + Vector2(-11, 6), g + Vector2(0, -5), g + Vector2(11, 6)]), ink, 4.0, true)
		_text_centred(font, "Hover", c + Vector2(0, 15), 19, ink)
		if not MobileUI.is_mobile():
			_text_centred(font, "V", c + Vector2(0, 34), 16, Color(UIStyle.TEXT_SOFT, 0.9))

	## THE END BUTTON (top-right corner, always shown - camera up or down). A single tap only opens
	## the confirm card (PlanetSafari.request_end); it never ends the safari by itself.
	func _draw_end(L: SafariLayer, font: Font) -> void:
		var r := L.end_rect
		draw_style_box(UIStyle.make_pill_style(Color(UIStyle.NAVY, 0.6), Color(UIStyle.CREAM, 0.5), 2), r)
		_text_centred(font, "End", r.get_center() + Vector2(0, 7), 20, UIStyle.CREAM)
