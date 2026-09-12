class_name TouchControls
extends Control
## The whole mobile gameplay control scheme (docs/STYLE_GUIDE.md R2.10), as one HUD child.
##
##   * a FLOATING left thumbstick - analogue, so a small push walks and a full push runs; there is
##     no run button (see `TouchStick`),
##   * a right ACTION CLUSTER - one large context button whose label follows
##     `EventBus.interact_prompt_changed` (Talk / Enter / Place / Pick up / Fly), with Emote and
##     Boost satellites, plus rotate / cancel while a decoration is being placed,
##   * CAMERA BY DRAG anywhere on the open right-hand side, and PINCH TO ZOOM,
##   * small round HUD buttons for the bag, the favours journal and pause, because the keyboard
##     hint strip is desktop-only on mobile.
##
## Everything is TRANSLUCENT on purpose - idle 0.45, 0.88 while actually touched, sinking to 0.24
## after IDLE_FADE_DELAY seconds of nothing - so the planet stays appreciable through the controls.
## Panels you have to READ (top bar, dialogue, shops) stay opaque; this rule is only about controls.
##
## ---------------------------------------------------------------------------------------------
## HOW IT REACHES THE REST OF THE GAME
## Only through the ordinary input actions. Nothing in `src/player/**` changes: the stick writes
## `move_*` with an analogue strength plus `run`, the buttons hold `interact` / `emote` / `boost`,
## the camera drag writes `camera_left/right/up/down` (the rig turns those into a rate), and pinch
## sends `zoom_in` / `zoom_out`. That is also why this file may not be replaced by direct calls
## into `CameraRig` - the rig is another builder's file and is being edited concurrently.
##
## THE CAMERA IS THE ONE EXCEPTION, and it is not a hack: the player builder added a public touch
## API to `CameraRig` for exactly this - `add_look_px(Vector2)` for a drag, `add_zoom(metres)` for a
## pinch, and `is_look_input_allowed()` so an overlay can hide rather than draw a dead control.
## Those calls only accumulate; the rig drains them in its own `_handle_input` alongside the mouse
## and the stick, so a drag can never fight the auto-recentre or the emote orbit. The rig also owns
## the MOBILE FRAMING (8.6 m at 34 deg, zoom range 5-13 m, vs 7.4 m at 28 deg on desktop) off
## `Platform.is_mobile()`, so this file deliberately does NOT try to set a distance of its own.
##
## ---------------------------------------------------------------------------------------------
## POINTERS, AND WHY BOTH TOUCH AND MOUSE ARE ACCEPTED
## Real fingers arrive as `InputEventScreenTouch` / `InputEventScreenDrag`, and multi-touch is a
## requirement (steer and jump at once, two fingers to pinch), so those are the primary path.
## A desktop reviewer running `--ui=mobile` has no touchscreen, so the MOUSE drives a single
## pointer as a fallback - but only while no real touch has ever been seen and the OS cursor is
## visible, so it can never double up with the emulated mouse a phone generates from a touch, and
## can never fight `CameraRig`'s captured-cursor mouse look.
##
## A DIRECTOR TIMELINE CANNOT DELIVER EITHER: `Input.action_press` sets action state but emits no
## InputEvent. So the timeline hooks below (`debug_touch`, `debug_drag`, `debug_widget`,
## `debug_pinch`) push through the SAME `_pointer_*` routing and the SAME hit tests that a finger
## does - they are not a private shortcut past the widgets.

## Pointer ids the debug hooks use, kept well clear of real finger indices.
const DEBUG_ID_BASE := 100

## Metres of follow distance per pixel of pinch. The mobile zoom range is 5-13 m (8 m of span), so
## at 0.014 a ~570 px spread crosses the whole range - about a full comfortable two-thumb pinch.
const PINCH_M_PER_PX := 0.014

## Prompts that mean "there is nothing to interact with"; the context button dims but stays put, so
## the cluster never jumps around under the thumb.
const IDLE_PRIMARY_LABEL := "—"

var _stick: TouchStick
var _primary: TouchButton
var _emote: TouchButton
var _boost: TouchButton
var _rot_l: TouchButton
var _rot_r: TouchButton
var _place_cancel: TouchButton
var _bag: TouchButton
var _journal: TouchButton
var _pause: TouchButton
## name -> TouchButton, for hit testing and for the timeline hooks.
var _buttons: Dictionary = {}

## id -> {"role": String, "pos": Vector2, "t": int}. `"t"` is `Time.get_ticks_msec()` at claim time
## and is TEMPORARY diag only (see `_entry`); nothing in the routing reads it.
var _pointers: Dictionary = {}
## True once a real InputEventScreenTouch has arrived; the mouse fallback switches off for good.
var _saw_touch := false

## `--no-adopt` (after "--") turns OFF the late-pointer adoption in `_adopt_late_pointer` and puts
## the stuck-after-landing bug back exactly as the player reported it. Same purpose as
## `CameraRig`'s `--fade-off` / `--fade-thin`: the before/after pair for this fix can be re-captured
## from ONE timeline at any time, so "the joystick was dead after a landing" stays a measurement
## anyone can repeat rather than a claim about a build that no longer exists.
##
## Measured with tests/director round-trip timing (home -> zorp -> bolt -> hub -> home), a drag
## delivered with no preceding touch-down over the stick zone:
##   --no-adopt : pointers=0  stick_active=false  push=0.00  move=0.000  speed=0.00  travel=0.00 m
##   default    : pointers=1  stick_active=true   push=1.00  move=1.000  speed=7.00  travel=4.99 m
## Cached at _ready rather than read per event: `_pointer_move` runs once per finger per frame.
var _adopt_off := false

## Drag pixels gathered this frame, handed to `CameraRig.add_look_px` in `_process` (one call per
## frame, so two fingers moving in the same frame cannot double-apply the sensitivity).
var _cam_drag := Vector2.ZERO
## Finger separation at the last pinch sample, or -1 when not pinching.
var _pinch_ref := -1.0
## Metres of zoom gathered this frame, handed to `CameraRig.add_zoom`.
var _pinch_zoom := 0.0

# ----------------------------------------------------------------------------- diag counters
## *** TEMPORARY INSTRUMENTATION, paired with `src/ui/mobile/touch_diag.gd`. Remove both together
## once the stuck-after-start/landing cause is known. ***
##
## These count what happens INSIDE `_input`, which is the one path no measurement in this project
## has ever observed: `Input.action_press` emits no InputEvent and `debug_touch` / `debug_drag`
## call `_pointer_down` / `_pointer_move` directly, so four rounds of fixes have shipped without a
## single reading from the code a real finger actually runs through. `_n_dropped` is counted BEFORE
## the `if not visible` gate on purpose — "no touch event ever arrived" and "touch events arrive
## and are thrown away" are different faults with the same symptom.
var _n_touch := 0
var _n_drag := 0
var _n_mouse := 0
var _n_dropped := 0
var _n_adopt := 0
## Where the last pointer-down landed, what role it resolved to, and whether it was claimed at all.
var _last_down_pos := Vector2.ZERO
var _last_down_role := "-"
var _last_down_ok := false
var _last_down_ms := -1

var _layer_alpha := MobileUI.ALPHA_IDLE
var _idle_timer := 0.0
var _placement := false
var _prompt := ""
var _rig: Node

@onready var _hud: Node = get_parent()


func _ready() -> void:
	# ALWAYS, like the HUD: the controls must release their held actions even if something pauses
	# the tree while a finger is down.
	process_mode = Node.PROCESS_MODE_ALWAYS
	name = "TouchControls"
	_adopt_off = OS.get_cmdline_user_args().has("--no-adopt")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	_apply_mode()
	MobileUI.on_mode_changed(_on_mode_changed)
	EventBus.interact_prompt_changed.connect(_on_prompt_changed)
	EventBus.placement_mode_changed.connect(_on_placement_changed)
	EventBus.planet_loaded.connect(_on_planet_loaded)
	EventBus.ui_modal_opened.connect(func(_n: String) -> void: _on_modal_changed())
	EventBus.ui_modal_closed.connect(func(_n: String) -> void: _on_modal_changed())
	get_viewport().size_changed.connect(_layout)
	resized.connect(_layout)
	call_deferred("_layout")


# ----------------------------------------------------------------------------- build
func _build() -> void:
	_stick = TouchStick.new()
	_stick.name = "Stick"
	add_child(_stick)

	_primary = _make_button("primary", MobileUI.PRIMARY_R, MobileUI.PRIMARY_HIT_R,
		UIStyle.YELLOW, UIStyle.YELLOW_EDGE, ["interact"])
	_primary.font_size = 26
	# Replaces the old Jump satellite (2026-09-12, user request: "jump and fly are basically the
	# same button since flying is a jump if you tap it" - see the Fly comment below, which already
	# made every tap on Fly a jump). One tap here presses "emote", exactly like the keyboard's C:
	# `Player.EMOTE_CYCLE` (player.gd:123) advances wave -> happy -> dance one step per press-edge.
	# `TouchButton.Glyph` has no EMOTE case and lives in another builder's file this round, so the
	# icon is a small overlay child (`_add_emote_glyph` below) drawn directly by this file instead
	# of a new enum case - same ink colour, same "painted, not photographic" language as the other
	# glyphs, without editing a file outside this build's brief.
	_emote = _make_button("emote", MobileUI.SAT_R, MobileUI.SAT_HIT_R,
		UIStyle.CREAM, UIStyle.CREAM_EDGE, ["emote"])
	_emote.label = "Emote"
	_emote.font_size = 15
	_add_emote_glyph(_emote)
	# Boost holds BOTH actions, because the keyboard's boost IS the space bar: a tap is a jump and
	# only a hold lights the thruster (Player.BOOST_GROUND_DELAY). Pressing only `boost` would fly,
	# but it would not be "exactly as holding the key does".
	_boost = _make_button("boost", MobileUI.SAT_R, MobileUI.SAT_HIT_R,
		UIStyle.CREAM, UIStyle.CREAM_EDGE, ["boost", "jump"])
	_boost.glyph = TouchButton.Glyph.BOOST
	_boost.label = "Fly"
	_boost.font_size = 15

	_rot_l = _make_button("rotate_l", MobileUI.SAT_R, MobileUI.SAT_HIT_R,
		UIStyle.CREAM, UIStyle.CREAM_EDGE, ["rotate_left"])
	_rot_l.glyph = TouchButton.Glyph.ROTATE_L
	_rot_r = _make_button("rotate_r", MobileUI.SAT_R, MobileUI.SAT_HIT_R,
		UIStyle.CREAM, UIStyle.CREAM_EDGE, ["rotate_right"])
	_rot_r.glyph = TouchButton.Glyph.ROTATE_R
	_place_cancel = _make_button("place_cancel", MobileUI.SAT_R, MobileUI.SAT_HIT_R,
		UIStyle.CREAM, UIStyle.CREAM_EDGE, ["cancel"])
	_place_cancel.glyph = TouchButton.Glyph.CLOSE
	# Placement-only row: hidden until `EventBus.placement_mode_changed` says a ghost is out.
	for b in [_rot_l, _rot_r, _place_cancel]:
		b.visible = false

	# ---- HUD buttons. These replace the keyboard hint strip's "bag" / "favours" entries, which is
	# the whole point: the strip itself is desktop-only now (see hud.gd).
	_bag = _make_button("bag", MobileUI.HUD_BTN_R, MobileUI.HUD_BTN_HIT_R,
		UIStyle.CREAM, UIStyle.CREAM_EDGE, [])
	_bag.glyph = TouchButton.Glyph.BAG
	_bag.tapped.connect(_open_bag)
	_journal = _make_button("journal", MobileUI.HUD_BTN_R, MobileUI.HUD_BTN_HIT_R,
		UIStyle.CREAM, UIStyle.CREAM_EDGE, [])
	_journal.glyph = TouchButton.Glyph.JOURNAL
	_journal.tapped.connect(_open_journal)
	_pause = _make_button("pause", MobileUI.HUD_BTN_R, MobileUI.HUD_BTN_HIT_R,
		UIStyle.CREAM, UIStyle.CREAM_EDGE, [])
	_pause.glyph = TouchButton.Glyph.PAUSE
	_pause.tapped.connect(_open_pause)
	for b in [_bag, _journal, _pause]:
		b.chrome = true
	_on_prompt_changed("")


func _make_button(id: String, r: float, hit: float, fill: Color, edge: Color,
		actions: PackedStringArray) -> TouchButton:
	var b := TouchButton.new()
	b.name = id.capitalize()
	b.radius = r
	b.hit_radius = hit
	b.fill = fill
	b.edge = edge
	b.actions = actions
	add_child(b)
	_buttons[id] = b
	return b


## Draws the Emote button's icon as a plain child Control rather than a new `TouchButton.Glyph`
## case - `touch_button.gd` is another builder's file this round and stays untouched. A five-point
## star, the same "filled shape + stroked outline" recipe `TouchButton._draw_flame` already uses
## for Boost, in the amber accent (STYLE_GUIDE) rather than Boost's orange so the two read as
## different controls at a glance. Sits well above the button's own centred label (`glyph` stays
## `NONE` on this button, so `TouchButton._draw` centres "Emote" there instead of pushing it to the
## rim the way it does for a button WITH a glyph) - see `EmoteGlyph._draw` for the measured offset.
func _add_emote_glyph(owner_btn: TouchButton) -> void:
	var g := EmoteGlyph.new()
	g.name = "Glyph"
	g.icon_radius = owner_btn.radius * 0.40
	owner_btn.add_child(g)


## Inline rather than its own file for the same reason as `_add_emote_glyph` above: everything this
## build touches has to stay inside `touch_controls.gd` / `hud.gd`.
class EmoteGlyph:
	extends Control
	var icon_radius := 18.0
	## Measured against a live capture at 1560x720 / --ui=mobile: the button's centred "Emote"
	## label (font 15) sits roughly from button-centre-5 to +11, so the star's lowest point is
	## pulled up to button-centre-8 - clear of the text with room to spare - by lifting the star's
	## own centre `icon_radius * 1.5` above the button centre.
	const LIFT_FACTOR := 1.5

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	func _draw() -> void:
		var c := size * 0.5 - Vector2(0.0, icon_radius * LIFT_FACTOR)
		var outer := icon_radius
		var inner := icon_radius * 0.42
		var pts := PackedVector2Array()
		for i in 10:
			var ang := deg_to_rad(-90.0) + float(i) * deg_to_rad(36.0)
			var rr := outer if i % 2 == 0 else inner
			pts.append(c + Vector2(cos(ang), sin(ang)) * rr)
		draw_colored_polygon(pts, Color(UIStyle.YELLOW, 0.9))
		var closed := pts.duplicate()
		closed.append(pts[0])
		draw_polyline(closed, UIStyle.TEXT_BROWN, 2.5, true)


# ----------------------------------------------------------------------------- layout
func _layout() -> void:
	if _stick == null:
		return
	var vp := size
	var sa := MobileUI.safe_area()
	var left := sa.x + MobileUI.EDGE
	var right := vp.x - sa.z - MobileUI.EDGE
	var top := sa.y + MobileUI.EDGE
	var bottom := vp.y - sa.w - MobileUI.EDGE

	_stick.zone = Rect2(Vector2(left, top + (vp.y - top) * MobileUI.STICK_ZONE_TOP),
		Vector2(vp.x * MobileUI.STICK_ZONE_W - left, bottom - top - (vp.y - top) * MobileUI.STICK_ZONE_TOP))
	_stick.queue_redraw()

	var pc := Vector2(right - MobileUI.PRIMARY_HIT_R, bottom - MobileUI.PRIMARY_HIT_R)
	_primary.centre = pc
	# Satellites sit on an arc in the upper-left quadrant of the primary, far enough apart that
	# their (larger) hit circles never overlap: 66 + 44 + 26 = 136 between centres vs 78 + 54 = 132.
	var arc := MobileUI.PRIMARY_R + MobileUI.SAT_R + 26.0
	_emote.centre = pc + Vector2(0.0, -arc)
	_boost.centre = pc + Vector2(-arc * 0.86, -arc * 0.50)
	# Placement row, clear above the cluster so nothing lands under the thumbs.
	var prow := pc.y - arc - MobileUI.SAT_R * 2.0 - 26.0
	_rot_r.centre = Vector2(pc.x, prow)
	_rot_l.centre = Vector2(pc.x - MobileUI.SAT_R * 2.0 - 26.0, prow)
	_place_cancel.centre = Vector2(pc.x - (MobileUI.SAT_R * 2.0 + 26.0) * 2.0, prow)

	# HUD row: top-left, under the stardust pill. Left side on purpose - the right-hand side is
	# camera drag, and the bottom belongs to the thumbs.
	var hy := top + 62.0 + MobileUI.HUD_BTN_HIT_R
	var hx := left + MobileUI.HUD_BTN_HIT_R
	var step := MobileUI.HUD_BTN_HIT_R * 2.0 + 8.0
	_bag.centre = Vector2(hx, hy)
	_journal.centre = Vector2(hx + step, hy)
	_pause.centre = Vector2(hx + step * 2.0, hy)


## True when `p` may start a camera drag: the open right-hand side, below the HUD row, and not on
## any visible button.
func _in_camera_zone(p: Vector2) -> bool:
	if p.x < size.x * 0.5 or p.y < size.y * MobileUI.CAM_ZONE_TOP:
		return false
	for id in _buttons:
		var b: TouchButton = _buttons[id]
		if b.contains(p):
			return false
	return true


# ----------------------------------------------------------------------------- mode / modals
func _on_mode_changed(_mobile: bool) -> void:
	_apply_mode()


func _apply_mode() -> void:
	_sync_state()
	if MobileUI.is_mobile():
		_layout()


## Reached from `ui_modal_opened` / `ui_modal_closed`, and — since this round — from
## `EventBus.reset_modals()`, which replays one `ui_modal_closed` per modal it clears so that this
## runs. Before that replay existed, a reset on a scene change left `visible` false with
## `EventBus.is_modal_open()` already false: a joystick that was not on screen at all, with nothing
## open to explain it, until the player opened and closed the pause menu. MEASURED, `--ui=mobile`,
## `ui_modal_opened("cutscene")` then `reset_modals()`: `vis=N modal=0` for the rest of the run and
## the overlay reading `STUCK: controls hidden, no modal open`; with the replay, `vis=Y` on the next
## frame. Nothing here had to change for that — `_sync_state` recomputes from the gate, which is the
## point of it.
func _on_modal_changed() -> void:
	_sync_state()


## THE ONLY WRITER OF `visible`, `set_process` AND `set_process_input` IN THIS FILE. That is the
## whole point of the function, and it replaced a real latent bug rather than a hypothetical one:
##
## `_apply_mode()` used to be the only caller of `set_process_input(mobile)`, and
## `_on_modal_changed()` set `visible` and NOTHING ELSE. So the two could disagree. If
## `MobileUI.is_mobile()` were ever false at the moment `_apply_mode()` ran — `Platform._detect()`
## resolves the web case through `JavaScriptBridge.eval` and falls back to
## `DisplayServer.is_touchscreen_available()` when the eval returns null, and neither is guaranteed
## to have settled the way a later `mode_changed` will — then input processing went OFF, and any
## later modal close called `_on_modal_changed()`, which turned the controls VISIBLE again without
## ever putting processing back. The result is a joystick you can SEE and cannot USE, which is
## exactly what the player has been reporting. `_input` and `_process` both gate on `visible`, so
## nothing else in the file would have noticed.
##
## The second half of the same bug shape was `_on_modal_changed`'s early-out, `if want == visible:
## return`. An early-out that skips a needed state RESTORE behaves identically to never having
## written the state: with `visible` already true and processing off, that line returned before it
## could have helped. There is no early-out here for that reason — the cost is two `set_process*`
## calls and one `visible` assignment on a signal that fires when a menu opens, a handful of times
## a minute.
##
## NOT FIXED WITH A TIMER. A `_apply_mode()` on a timeout would hide the divergence instead of
## removing it, and would have made the readout in `touch_diag.gd` useless — the overlay's
## "input processing off while mobile" verdict now means "a second writer of `visible` has
## appeared", which is a thing worth being told.
##
## Note which state tracks which condition, because they are deliberately different:
##   * processing tracks `mobile` ALONE, so the node keeps receiving events while a modal is up
##     (`_input` drops them itself, and counts them — see `_n_dropped`),
##   * `visible` tracks mobile AND no modal, which is what actually hides the controls.
## The invariant a test can assert is therefore `is_processing_input() == MobileUI.is_mobile()`,
## with no exceptions and no ordering in which it can fail.
func _sync_state() -> void:
	var mobile := MobileUI.is_mobile()
	var want := mobile and not EventBus.is_modal_open()
	set_process(mobile)
	set_process_input(mobile)
	# Unconditional, not "only on the visible -> hidden edge": letting go of a held action can
	# never be wrong, and making it conditional is how the early-out above got there.
	if not want:
		_release_everything()
	visible = want


## Lets go of every action this node can hold. Called whenever the controls leave the screen, so a
## modal can never open with the astronaut still walking or the thruster still lit.
func _release_everything() -> void:
	# `_sync_state` now calls this unconditionally whenever the controls are not wanted, including
	# paths that can run before `_build()` has made the widgets in a future edit.
	if _stick == null:
		_pointers.clear()
		return
	_pointers.clear()
	_stick.end()
	for id in _buttons:
		var b: TouchButton = _buttons[id]
		b.release()
	_cam_drag = Vector2.ZERO
	_pinch_zoom = 0.0
	_pinch_ref = -1.0


# ----------------------------------------------------------------------------- events
func _on_prompt_changed(text: String) -> void:
	_prompt = MobileUI.clean_prompt(text)
	if _primary == null:
		return
	_primary.label = _prompt if _prompt != "" else IDLE_PRIMARY_LABEL
	_primary.dimmed = _prompt == ""
	_primary.queue_redraw()


func _on_placement_changed(active: bool) -> void:
	_placement = active
	for b in [_rot_l, _rot_r, _place_cancel]:
		if b != null:
			b.visible = active
			if not active:
				b.release()
	if _bag != null:
		_bag.dimmed = active


func _on_planet_loaded(_id: String) -> void:
	_rig = null
	# LET GO OF EVERYTHING. A finger that was down when the rocket left — or any pointer state
	# that survived the scene swap — left `_stick.active` true, and `_pointer_down` refuses the
	# stick while it is active. Every later touch on the stick then fell through to the camera,
	# so after landing the joystick only panned the view and the astronaut would not move.
	# Reported from a real iPhone after the first flight.
	_release_everything()
	_layout()


# ----------------------------------------------------------------------------- pointer routing
func _input(event: InputEvent) -> void:
	# TEMPORARY DIAG (touch_diag.gd): counted BEFORE the visibility gate, so the readout can tell
	# "the touch path never reaches this node" apart from "it reaches it and is discarded".
	var pointer_event := false
	if event is InputEventScreenTouch:
		_n_touch += 1
		pointer_event = true
	elif event is InputEventScreenDrag:
		_n_drag += 1
		pointer_event = true
	elif event is InputEventMouseButton or event is InputEventMouseMotion:
		_n_mouse += 1
		pointer_event = true
	# A SCREEN EVENT PROVES A TOUCHSCREEN EVEN WHILE THE CONTROLS ARE HIDDEN. This used to be learned
	# only below the visibility gate, so every touch made during the intro dialogue or a cutscene
	# was dropped WITHOUT teaching it - and the first event to reach the node once the controls
	# reappeared could be the emulated mouse copy of the very tap that dismissed the modal.
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		_saw_touch = true
	if not visible:
		if pointer_event:
			_n_dropped += 1
		return
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		_saw_touch = true
		if t.pressed:
			if _pointer_down(t.index, t.position, true):
				get_viewport().set_input_as_handled()
		else:
			_pointer_up(t.index)
		return
	if event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		_saw_touch = true
		_pointer_move(d.index, d.position)
		return
	# Mouse fallback for a desktop reviewer running --ui=mobile. Disabled the moment a real touch
	# appears (a phone emulates a mouse from finger 0 and would double up), and never while the
	# cursor is captured, which is CameraRig's mouse look owning the pointer.
	#
	# *** THE JAMMED JOYSTICK, reported five times: "the joystick doesnt react when i touch it" while
	# jump, fly and the camera all worked, and "when I click pause, the favors, or the bag, i can
	# move again." *** Godot emulates a mouse from touch, so every tap on a phone arrives TWICE: a
	# ScreenTouch and a MouseButton copy. `_saw_touch` was learned lazily, so the copy of the tap
	# that closed the intro could reach this branch first, claim the stick as pointer -1, and then
	# its release was dropped here once `_saw_touch` flipped true. `_stick.active` stayed true with
	# nothing ever able to end it, `_pointer_down` refused every later stick touch, and only
	# `_release_everything()` - which every modal open runs - cleared it. That is the workaround.
	# A touchscreen device never needs this fallback; it exists for `--ui=mobile` on a desktop.
	if _saw_touch or DisplayServer.is_touchscreen_available() \
			or Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			if _pointer_down(-1, mb.position, true):
				get_viewport().set_input_as_handled()
		else:
			_pointer_up(-1)
	elif event is InputEventMouseMotion:
		_pointer_move(-1, (event as InputEventMouseMotion).position)


## Claims a new pointer. Returns true when this node took it.
## Refuses while the controls are off screen, so the timeline hooks can never do something a
## finger could not - a modal is up and the controls are hidden, so nothing is touchable.
## `fresh` is true only for a genuine press (a ScreenTouch or mouse button going DOWN), never for a
## drag adopted late by `_adopt_late_pointer`.
func _pointer_down(id: int, pos: Vector2, fresh := false) -> bool:
	# TEMPORARY DIAG (touch_diag.gd): remember every attempt, refusals included, so the readout can
	# say WHERE the last finger landed and WHAT role the hit tests gave it.
	_last_down_pos = pos
	_last_down_ms = Time.get_ticks_msec()
	_last_down_role = "refused"
	_last_down_ok = false
	if not visible:
		_last_down_role = "hidden"
		return false
	_wake()
	for bid in _buttons:
		var b: TouchButton = _buttons[bid]
		if b.contains(pos):
			_pointers[id] = _entry("btn:" + str(bid), pos)
			b.press()
			_last_down_role = "btn:" + str(bid)
			_last_down_ok = true
			return true
	# A FRESH PRESS ON THE STICK ALWAYS WINS. It used to be first-touch-wins with no way back:
	# while `_stick.active` was true every new press was refused, so ANY path that lost a stick
	# owner's release - the emulated-mouse ghost in `_input`, a release swallowed during a scene
	# swap, anything not yet found - jammed the joystick until a modal happened to run
	# `_release_everything()`. Taking over on a fresh press makes that deadlock structurally
	# impossible whatever the cause. The cost is that a second finger landing in the stick zone
	# steals it from the first, which nobody does on purpose: the stick is one thumb's job.
	# A late-adopted drag (`fresh` false) still cannot steal a live stick.
	if _stick.zone.has_point(pos) and (fresh or not _stick.active):
		if _stick.active:
			_drop_stick_owner()
		_pointers[id] = _entry("stick", pos)
		_stick.begin(pos)
		_last_down_role = "stick"
		_last_down_ok = true
		return true
	if _in_camera_zone(pos):
		_pointers[id] = _entry("cam", pos)
		_update_pinch_ref()
		_last_down_role = "cam"
		_last_down_ok = true
		return true
	return false


## Forgets whichever pointer holds the stick and releases it. `keys()` is a copy, so erasing while
## walking it is safe.
func _drop_stick_owner() -> void:
	for pid in _pointers.keys():
		if str(_pointers[pid]["role"]) == "stick":
			_pointers.erase(pid)
	_stick.end()


## One `_pointers` row. `"t"` is TEMPORARY DIAG (touch_diag.gd): a pointer's AGE is what separates a
## thumb the player is still using from a ghost left behind by a scene swap, and nothing else in
## the file reads it.
func _entry(role: String, pos: Vector2) -> Dictionary:
	return {"role": role, "pos": pos, "t": Time.get_ticks_msec()}


func _pointer_move(id: int, pos: Vector2) -> void:
	if not _pointers.has(id):
		if not _adopt_off:
			_adopt_late_pointer(id, pos)
		return
	_wake()
	var p: Dictionary = _pointers[id]
	var prev: Vector2 = p["pos"]
	p["pos"] = pos
	var role := str(p["role"])
	if role == "stick":
		_stick.drag(pos)
	elif role == "cam":
		if _cam_pointers().size() >= 2:
			_update_pinch()
		else:
			_cam_drag += pos - prev
	elif role.begins_with("btn:"):
		# A finger that slides right off a button lets go, the way a real button behaves.
		var b: TouchButton = _buttons.get(role.substr(4))
		if b != null and not b.contains(pos):
			b.release()
			_pointers.erase(id)


## THE FINGER THAT WAS ALREADY ON THE GLASS. The player's report, three playtests running:
## *"when I landed on the first planet, I couldnt move anymore, the move joystick just moved the
## camera"*, *"coming out of a spaceship on new planet still doesnt let me move"*, and the decisive
## one: *"I can move again by hitting pause and resume."*
##
## WHY A DRAG CAN ARRIVE WITH NO POINTER. `_pointers` is keyed by touch index, and the ONLY thing
## that ever adds a key is `_pointer_down`. Two ordinary events wipe the table under a finger that
## is still pressed:
##   * `_release_everything()` on `ui_modal_opened` — and the landing cutscene is a modal
##     (`RocketPad._begin_cutscene` emits `ui_modal_opened("cutscene")`),
##   * a planet load, which builds a BRAND NEW TouchControls whose table starts empty.
## Both happen with the player's left thumb resting on the stick, because they were steering toward
## the pad a second earlier. `_input` also returns early while the controls are hidden, so the
## touch-DOWN that would re-register that finger is never seen either — it already happened.
##
## From then on the finger is a ghost: `_pointer_move` and `_pointer_up` both used to `return` on
## `if not _pointers.has(id)`, so dragging it did nothing at all and lifting it did nothing at all.
## The stick was drawn, un-owned and untouchable, for the rest of that finger's life. Only lifting
## and re-planting the thumb produced a fresh touch-down — which is EXACTLY what pause-then-resume
## forces the player to do, and why their workaround worked. That is the strongest evidence there
## is that the pointer table, and not any gameplay gate, is what was broken: measured immediately
## after landing, `paused=false modal=false input_enabled=true phys=true` on all four planets.
##
## THE FIX: treat the first drag from an unknown id as its missing touch-down. `_pointer_down`
## refuses everything while `visible` is false, so this cannot resurrect a finger during a cutscene;
## it can only act once the controls are back on screen, which is the moment the player expects the
## stick to work again. The stick's origin becomes the CURRENT finger position, so adoption starts
## at zero push and the astronaut does not lurch — the thumb is where it is, and the stick re-homes
## under it rather than snapping it somewhere.
##
## *** BUTTONS ARE EXCLUDED, DELIBERATELY. *** A resting thumb becoming a synthetic touch-down must
## never be able to FIRE something. If the drag is over Emote, Boost, the context button (Talk /
## Enter / Fly), the bag, the journal or pause, adoption is refused outright and the finger stays a
## ghost until it is lifted — a dead control is a far smaller bug than a rocket launched by a thumb
## the player never pressed with. Only the two CONTINUOUS, self-cancelling roles can be adopted:
## the stick (which starts at zero) and the camera drag (which starts at zero). This was raised by
## the adversarial cross-check and it is the one hard rule in this function.
##
## RUN cannot be excluded separately, and saying so plainly: there is no run button in this game.
## `TouchStick` derives run from stick push > 0.60 (touch_stick.gd:9-11, :137), so the only way to
## keep an adopted stick from ever running would be to abandon the fix. What makes that safe is
## that adoption itself fires nothing — the stick re-homes under the finger, so push is 0.00 at the
## instant of adoption (measured) and run only appears once the player deliberately drags past 60%
## of stick travel, exactly as it would after an ordinary touch-down.
##
## Measured, four late drags with no touch-down (`--ui=mobile`, 1280x720, Compatibility):
##   over the context button (1184,624) -> pointers=0, primary alpha 0.45 (i.e. NOT pressed: a
##                                         pressed button paints at ALPHA_ACTIVE 0.88)
##   over Emote (1184,488)              -> pointers=0, emote alpha 0.45 (re-measured 2026-09-12
##                                         when Emote took this slot over from Jump - same spot,
##                                         same result, the exclusion loop is button-name-agnostic)
##   in the camera zone (940,500)       -> pointers=1, role "cam"
##   in the stick zone (240,500)        -> pointers=1, role "stick", push 0.96, move 0.962
## The two that must do nothing do nothing; the two that must work, work.
##
## The larger variant considered and NOT shipped: tracking a `_dead` set of ids that were cleared
## while still held, so only those specific ids could be adopted. It is strictly more state to keep
## correct across scene loads (where the node itself is new and the set would start empty anyway —
## i.e. it would not even cover the landing case, which is the reported bug), and the button
## exclusion above already removes the only dangerous outcome. If a case turns up that this cannot
## reach, that is the next thing to try.
func _adopt_late_pointer(id: int, pos: Vector2) -> void:
	# *** THE MOUSE IS NOT A FINGER. *** The desktop fallback in `_input` calls
	# `_pointer_move(-1, event.position)` on EVERY `InputEventMouseMotion`, with no button held —
	# a mouse reports where the cursor is whether or not it is pressed, which a touchscreen never
	# does. Without this line a reviewer running `--ui=mobile` who merely MOVED the cursor across
	# the stick zone adopted the stick and walked the astronaut: measured
	# `TOUCHPTR mouse_hover_stick pointers=2 [.., -1:stick@(240,500)] stick_active=true`, then
	# hovering on to (240,380) gave `push=1.00 move=1.000 run=true speed=4.50`, no button ever
	# pressed. That never reaches an iPhone, but `--ui=mobile` on this desktop is how every piece
	# of mobile UI in this project is reviewed and captured, so a stray cursor would silently walk
	# the astronaut out of frame in future timelines and screenshots. Caught by the critic on the
	# first attempt at this fix.
	# The mouse keeps its ordinary path: `InputEventMouseButton` still goes through `_pointer_down`,
	# which registers id -1 properly, and once it is in `_pointers` this function is never reached
	# for it. Only ids >= 0 — real `InputEventScreenTouch` / `InputEventScreenDrag` indices, and the
	# timeline hooks that stand in for them — can be adopted late.
	if id < 0:
		return
	if not visible:
		return
	for bid in _buttons:
		var b: TouchButton = _buttons[bid]
		if b.contains(pos):
			return
	# Can now only resolve to "stick" or "cam" inside `_pointer_down`, both of which begin at rest.
	if _pointer_down(id, pos):
		_n_adopt += 1  # TEMPORARY DIAG (touch_diag.gd)


func _pointer_up(id: int) -> void:
	if not _pointers.has(id):
		return
	_wake()
	var role := str(_pointers[id]["role"])
	_pointers.erase(id)
	if role == "stick":
		_stick.end()
	elif role == "cam":
		_pinch_ref = -1.0
		if _cam_pointers().size() >= 2:
			_update_pinch_ref()
	elif role.begins_with("btn:"):
		var b: TouchButton = _buttons.get(role.substr(4))
		if b != null:
			b.release()


func _cam_pointers() -> Array[Vector2]:
	var out: Array[Vector2] = []
	for id in _pointers:
		if str(_pointers[id]["role"]) == "cam":
			out.append(_pointers[id]["pos"] as Vector2)
	return out


func _update_pinch_ref() -> void:
	var pts := _cam_pointers()
	_pinch_ref = pts[0].distance_to(pts[1]) if pts.size() >= 2 else -1.0


## Two fingers on the camera side: the change in separation becomes a continuous zoom in metres.
## Spreading the fingers apart pulls the world closer (a negative distance delta).
func _update_pinch() -> void:
	var pts := _cam_pointers()
	if pts.size() < 2:
		return
	var d := pts[0].distance_to(pts[1])
	if _pinch_ref < 0.0:
		_pinch_ref = d
		return
	_pinch_zoom -= (d - _pinch_ref) * PINCH_M_PER_PX
	_pinch_ref = d
	# A pinch is not an orbit: drop whatever the two fingers gathered while spreading.
	_cam_drag = Vector2.ZERO


## `/root/World/CameraRig`, cached. Re-looked-up after every planet load.
func _camera_rig() -> Node:
	if is_instance_valid(_rig):
		return _rig
	_rig = get_tree().root.get_node_or_null("World/CameraRig")
	return _rig


# ----------------------------------------------------------------------------- per-frame
func _process(delta: float) -> void:
	if not visible:
		return
	_drive_camera()
	_fade(delta)


## Hands this frame's drag and pinch to the rig's public touch API. One call each, whatever
## happened during the frame, because the rig applies sensitivity and inversion per call.
func _drive_camera() -> void:
	if _cam_drag == Vector2.ZERO and is_zero_approx(_pinch_zoom):
		return
	var rig := _camera_rig()
	if rig == null:
		_cam_drag = Vector2.ZERO
		_pinch_zoom = 0.0
		return
	if _cam_drag != Vector2.ZERO and rig.has_method("add_look_px"):
		rig.call("add_look_px", _cam_drag)
	if not is_zero_approx(_pinch_zoom) and rig.has_method("add_zoom"):
		rig.call("add_zoom", _pinch_zoom)
	_cam_drag = Vector2.ZERO
	_pinch_zoom = 0.0


## Any touch at all wakes the controls back to their idle opacity.
func _wake() -> void:
	_idle_timer = 0.0


func _fade(delta: float) -> void:
	var touched := not _pointers.is_empty()
	if touched:
		_idle_timer = 0.0
	else:
		_idle_timer += delta
	var idle := _idle_timer < MobileUI.IDLE_FADE_DELAY
	var want: float = MobileUI.ALPHA_IDLE if idle else MobileUI.ALPHA_DIM
	var rate: float = MobileUI.ALPHA_RATE_UP if want > _layer_alpha else MobileUI.ALPHA_RATE_DOWN
	_layer_alpha = move_toward(_layer_alpha, want, delta * rate)
	var chrome_a: float = MobileUI.ALPHA_CHROME if idle else MobileUI.ALPHA_CHROME_DIM
	_stick.modulate.a = MobileUI.ALPHA_ACTIVE if _stick.active else _layer_alpha
	for id in _buttons:
		var b: TouchButton = _buttons[id]
		var rest: float = chrome_a if b.chrome else _layer_alpha
		b.modulate.a = MobileUI.ALPHA_ACTIVE if b.down else rest


# ----------------------------------------------------------------------------- HUD actions
func _open_bag() -> void:
	if _placement or EventBus.is_modal_open():
		return
	var inv: Object = _hud.get("inventory")
	if inv != null:
		inv.call("open", "all")


func _open_journal() -> void:
	if _placement or EventBus.is_modal_open():
		return
	JournalPanel.open_over(self)


func _open_pause() -> void:
	if EventBus.is_modal_open():
		return
	var pm: Object = _hud.get("pause_menu")
	if pm != null:
		pm.call("open")


# ----------------------------------------------------------------------------- timeline hooks
## A Director timeline drives the game with `Input.action_press`, which emits NO InputEvent, so it
## cannot deliver a touch. These push through the same `_pointer_*` routing and the same hit tests
## a finger does. Usage from tests/director/*.json:
##   {"call": {"node": "/root/World/HUD/TouchControls", "method": "debug_widget",
##             "args": ["primary", true]}}
##   {"call": {"node": "/root/World/HUD/TouchControls", "method": "debug_touch",
##             "args": [0, 240.0, 560.0, true]}}
func debug_touch(id: int, x: float, y: float, pressed: bool) -> void:
	if pressed:
		_pointer_down(DEBUG_ID_BASE + id, Vector2(x, y), true)
	else:
		_pointer_up(DEBUG_ID_BASE + id)


func debug_drag(id: int, x: float, y: float) -> void:
	_pointer_move(DEBUG_ID_BASE + id, Vector2(x, y))


## Puts a finger on the CENTRE of a named widget ("primary", "emote", "boost", "bag", "journal",
## "pause", "rotate_l", "rotate_r", "place_cancel") and lifts it again on the next call.
func debug_widget(id: String, pressed: bool) -> void:
	var b: TouchButton = _buttons.get(id)
	if b == null:
		push_warning("TouchControls.debug_widget: no widget '%s'" % id)
		return
	if pressed:
		_pointer_down(DEBUG_ID_BASE + 90, b.centre)
	else:
		_pointer_up(DEBUG_ID_BASE + 90)


## Pushes the stick from its resting home by a fraction of full travel, in screen direction
## (dx, dy) - (0,-1) is "straight ahead". Call with `hold` false to let go.
func debug_stick(dx: float, dy: float, amount: float, hold: bool = true) -> void:
	var home := _stick.home_position()
	if not hold:
		_pointer_up(DEBUG_ID_BASE + 91)
		return
	if not _pointers.has(DEBUG_ID_BASE + 91):
		_pointer_down(DEBUG_ID_BASE + 91, home)
	var d := Vector2(dx, dy)
	if d.length() > 0.0:
		d = d.normalized()
	_pointer_move(DEBUG_ID_BASE + 91, home + d * MobileUI.STICK_TRAVEL * clampf(amount, 0.0, 1.0))


## THE DESKTOP MOUSE, THROUGH `_input` ITSELF, and it is not the same test as `debug_touch`.
##
## `debug_touch` / `debug_drag` / `debug_stick` call `_pointer_down` / `_pointer_move` directly with
## a DEBUG_ID_BASE id, i.e. a POSITIVE id, which is what a real finger has. The desktop `--ui=mobile`
## fallback is the opposite case: `_input` calls `_pointer_move(-1, ...)` for every
## `InputEventMouseMotion`, with no button held, because a mouse reports where the cursor is whether
## or not it is pressed. `_adopt_late_pointer` refuses ids below zero for exactly that reason (a
## reviewer who merely moved the cursor over the stick zone used to walk the astronaut: measured
## `pointers=2 [.., -1:stick@(240,500)] stick_active=true`, then `push=1.00 move=1.000 run=true
## speed=4.50`, no button ever pressed). These two hooks let a timeline re-measure that guard.
##
## They synthesise REAL events through `Input.parse_input_event`, so the whole chain runs — `_input`,
## the `_saw_touch` / `mouse_mode` gate, the mouse branch, `_pointer_move`, `_adopt_late_pointer` —
## rather than the middle of it. Position is authored in VIEWPORT coordinates and mapped with the
## root's final transform, for the reason spelled out on `MobileUI.synth_tap`: `push_input` applies
## the inverse stretch transform, so an event authored in the logical space lands a third of the way
## up and to the left of where it was aimed.
func debug_mouse_hover(x: float, y: float) -> void:
	var ev := InputEventMouseMotion.new()
	ev.position = _window_pos(Vector2(x, y))
	ev.global_position = ev.position
	Input.parse_input_event(ev)


## Left mouse button at a viewport position. `pressed` false lifts it.
func debug_mouse_button(x: float, y: float, pressed: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	ev.position = _window_pos(Vector2(x, y))
	ev.global_position = ev.position
	ev.pressed = pressed
	Input.parse_input_event(ev)


func _window_pos(pos: Vector2) -> Vector2:
	var vp := get_viewport()
	return pos if vp == null else vp.get_final_transform() * pos


## Two fingers on the camera side, spread or pinched by `px`.
func debug_pinch(px: float) -> void:
	var c := Vector2(size.x * 0.75, size.y * 0.55)
	var a := DEBUG_ID_BASE + 92
	var b := DEBUG_ID_BASE + 93
	if not _pointers.has(a):
		_pointer_down(a, c + Vector2(-60.0, 0.0))
		_pointer_down(b, c + Vector2(60.0, 0.0))
		return
	_pointer_move(a, c + Vector2(-60.0 - px * 0.5, 0.0))
	_pointer_move(b, c + Vector2(60.0 + px * 0.5, 0.0))


func debug_pinch_end() -> void:
	_pointer_up(DEBUG_ID_BASE + 92)
	_pointer_up(DEBUG_ID_BASE + 93)


## One-line state dump for a timeline to assert against (goes to the Director log via stdout).
func debug_report(tag: String = "") -> void:
	var rig := _camera_rig()
	var dist := float(rig.call("get_zoom_distance")) if rig != null and rig.has_method("get_zoom_distance") else -1.0
	var player := get_tree().get_first_node_in_group("player")
	var speed := 0.0
	var ground := -1.0
	var anim := "?"
	if player != null and player.has_method("get_tangent_velocity"):
		speed = (player.call("get_tangent_velocity") as Vector3).length()
	# TEMPORARY, ADDED FOR THE 2026-09-12 EMOTE-BUTTON PROOF: `get_ground_height` and
	# `AstronautModel.get_state` are both pre-existing public getters (player.gd, astronaut_model.gd)
	# - nothing in `src/player/**` changed to add this line - it just gives a Director timeline a way
	# to measure the Fly button's tap-jumps / hold-flies split and the emote cycle as NUMBERS, not
	# only as screenshots.
	if player != null and player.has_method("get_ground_height"):
		ground = float(player.call("get_ground_height"))
	if player != null and player.has_method("get_model"):
		var model: Object = player.call("get_model")
		if model != null and model.has_method("get_state"):
			anim = str(model.call("get_state"))
	var sa := MobileUI.safe_area()
	print("TOUCH %s mobile=%s vis=%s modals=%s push=%.2f move=%.3f run=%s speed=%.2f ground=%.3f anim=%s dist=%.2f prompt='%s' | alpha layer=%.2f stick=%.2f primary=%.2f emote=%.2f chrome=%.2f | safe=(%.0f,%.0f,%.0f,%.0f)" % [
		tag, str(MobileUI.is_mobile()), str(visible), str(EventBus.open_modals()), _stick.push,
		Input.get_vector("move_left", "move_right", "move_forward", "move_back").length(),
		str(Input.is_action_pressed("run")), speed, ground, anim, dist, _prompt,
		_layer_alpha, _stick.modulate.a, _primary.modulate.a, _emote.modulate.a, _bag.modulate.a,
		sa.x, sa.y, sa.z, sa.w])


## POINTER TABLE DUMP, for the stuck-after-landing investigation.
##
## `debug_report` above answers "is the control drawn and is an action pressed". It cannot answer
## the question the landing bug actually turns on, which is whether the finger currently on the
## glass has an ENTRY in `_pointers` at all - because a pointer with no entry is invisible to
## `_pointer_move` and `_pointer_up` (both `return` on `if not _pointers.has(id)`), and a stick that
## no finger can claim looks exactly like a stick that works.
##
## Prints one line per live pointer plus the stick's own state, so a timeline can show the table
## before and after a modal (the landing cutscene is one) and before and after a pause/resume.
func debug_pointers(tag: String = "") -> void:
	var rows: Array[String] = []
	for id in _pointers:
		var p: Dictionary = _pointers[id]
		rows.append("%s:%s@(%.0f,%.0f)" % [str(id), str(p["role"]), (p["pos"] as Vector2).x, (p["pos"] as Vector2).y])
	print("TOUCHPTR %s vis=%s pointers=%d [%s] stick_active=%s stick_push=%.2f cam_drag=(%.1f,%.1f)" % [
		tag, str(visible), _pointers.size(), ", ".join(rows),
		str(_stick.active), _stick.push, _cam_drag.x, _cam_drag.y])


# ----------------------------------------------------------------------------- diag state
## *** TEMPORARY INSTRUMENTATION, paired with `src/ui/mobile/touch_diag.gd`. Remove both together. ***
##
## EVERY FIELD IN HERE EXISTS TO RULE OUT A DIFFERENT CAUSE of "I can't move until I pause and
## resume", which has now been reported five times and survived four fixes. This is the single
## source: the on-screen overlay and `debug_diag` below both format THIS dictionary, so a scripted
## run cannot measure one set of fields while the player photographs another.
func diag_state() -> Dictionary:
	var tree := get_tree()
	var player: Node = tree.get_first_node_in_group("player") if tree != null else null
	var now := Time.get_ticks_msec()
	var ptrs: Array = []
	for id in _pointers:
		var p: Dictionary = _pointers[id]
		ptrs.append({
			"id": int(id), "role": str(p["role"]), "pos": p["pos"] as Vector2,
			"age": float(now - int(p.get("t", now))) * 0.001})
	var counts: Dictionary = EventBus.modal_counts()
	var summed := 0
	for k in counts:
		summed += int(counts[k])
	var rst: Dictionary = EventBus.modal_reset_info()
	var speed := 0.0
	if player != null and player.has_method("get_tangent_velocity"):
		speed = (player.call("get_tangent_velocity") as Vector3).length()
	return {
		"mobile": MobileUI.is_mobile(),
		"visible": visible,
		"in_tree": is_visible_in_tree(),
		"proc": is_processing(),
		"proc_in": is_processing_input(),
		"modal_total": EventBus.modal_total(),
		"modal_counts": counts,
		"modal_names_sum": summed,
		"reset_count": int(rst.get("count", 0)),
		"reset_names": str(rst.get("names", "")),
		"reset_age": float(rst.get("age", -1.0)),
		"pointers": ptrs,
		"stick_active": _stick != null and _stick.active,
		"stick_push": _stick.push if _stick != null else 0.0,
		"stick_zone": _stick.zone if _stick != null else Rect2(),
		"size": size,
		"move_vec": Input.get_vector("move_left", "move_right", "move_forward", "move_back"),
		"run": Input.is_action_pressed("run"),
		"paused": tree != null and tree.paused,
		"player_found": player != null,
		"input_enabled": player != null and bool(player.get("input_enabled")),
		"phys": player != null and player.is_physics_processing(),
		"pproc": player != null and player.is_processing(),
		"speed": speed,
		"n_touch": _n_touch, "n_drag": _n_drag, "n_mouse": _n_mouse,
		"n_dropped": _n_dropped, "n_adopt": _n_adopt, "saw_touch": _saw_touch,
		"adopt_off": _adopt_off,
		"last_down_role": _last_down_role,
		"last_down_pos": _last_down_pos,
		"last_down_ok": _last_down_ok,
		"last_down_age": -1.0 if _last_down_ms < 0 else float(now - _last_down_ms) * 0.001,
	}


## Prints EXACTLY the text `TouchDiag` draws on screen, one line per row plus the verdict, so a
## Director run and the player's screenshot are the same measurement. TEMPORARY.
func debug_diag(tag: String = "") -> void:
	var s := diag_state()
	for l in TouchDiag.lines(s):
		print("DIAG %s | %s" % [tag, l])
	print("DIAG %s | VERDICT: %s" % [tag, TouchDiag.verdict(s)])


## FAULT INJECTION for the overlay's own tests. TEMPORARY, and the only reason it is a method on
## the shipping class is that a Director timeline can reach nothing else. Each name breaks exactly
## one thing, so the verdict line can be checked against a KNOWN fault instead of a guess:
##   zone_empty    - collapse the stick zone (a stale layout: the ring is drawn where the zone is
##                   not, so a thumb on it falls through to the camera role)
##   stick_active  - stick active with no owning pointer (the pre-fix landing bug)
##   cam_in_stick  - pin a "cam" pointer inside the stick zone
##   age           - back-date every live pointer by `amount` seconds (ghost detection)
##   paused        - pause the tree without opening a modal
func debug_force(what: String, amount: float = 0.0) -> void:
	match what:
		"zone_empty":
			_stick.zone = Rect2(_stick.zone.position, Vector2.ZERO)
		"stick_active":
			_pointers.clear()
			_stick.active = true
		"cam_in_stick":
			_pointers[DEBUG_ID_BASE + 95] = _entry("cam", _stick.home_position())
		"age":
			for id in _pointers:
				(_pointers[id] as Dictionary)["t"] = Time.get_ticks_msec() - int(amount * 1000.0)
		"paused":
			get_tree().paused = amount > 0.0
		_:
			push_warning("TouchControls.debug_force: unknown fault '%s'" % what)
