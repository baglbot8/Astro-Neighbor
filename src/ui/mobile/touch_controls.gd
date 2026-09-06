class_name TouchControls
extends Control
## The whole mobile gameplay control scheme (docs/STYLE_GUIDE.md R2.10), as one HUD child.
##
##   * a FLOATING left thumbstick - analogue, so a small push walks and a full push runs; there is
##     no run button (see `TouchStick`),
##   * a right ACTION CLUSTER - one large context button whose label follows
##     `EventBus.interact_prompt_changed` (Talk / Enter / Place / Pick up / Fly), with Jump and
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
## `move_*` with an analogue strength plus `run`, the buttons hold `interact` / `jump` / `boost`,
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
var _jump: TouchButton
var _boost: TouchButton
var _rot_l: TouchButton
var _rot_r: TouchButton
var _place_cancel: TouchButton
var _bag: TouchButton
var _journal: TouchButton
var _pause: TouchButton
## name -> TouchButton, for hit testing and for the timeline hooks.
var _buttons: Dictionary = {}

## id -> {"role": String, "pos": Vector2}
var _pointers: Dictionary = {}
## True once a real InputEventScreenTouch has arrived; the mouse fallback switches off for good.
var _saw_touch := false

## Drag pixels gathered this frame, handed to `CameraRig.add_look_px` in `_process` (one call per
## frame, so two fingers moving in the same frame cannot double-apply the sensitivity).
var _cam_drag := Vector2.ZERO
## Finger separation at the last pinch sample, or -1 when not pinching.
var _pinch_ref := -1.0
## Metres of zoom gathered this frame, handed to `CameraRig.add_zoom`.
var _pinch_zoom := 0.0

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
	_jump = _make_button("jump", MobileUI.SAT_R, MobileUI.SAT_HIT_R,
		UIStyle.CREAM, UIStyle.CREAM_EDGE, ["jump"])
	_jump.glyph = TouchButton.Glyph.JUMP
	_jump.label = "Jump"
	_jump.font_size = 15
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
	_jump.centre = pc + Vector2(0.0, -arc)
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
	var mobile := MobileUI.is_mobile()
	set_process(mobile)
	set_process_input(mobile)
	if not mobile:
		_release_everything()
	visible = mobile and not EventBus.is_modal_open()
	if mobile:
		_layout()


func _on_modal_changed() -> void:
	var want := MobileUI.is_mobile() and not EventBus.is_modal_open()
	if want == visible:
		return
	if not want:
		_release_everything()
	visible = want


## Lets go of every action this node can hold. Called whenever the controls leave the screen, so a
## modal can never open with the astronaut still walking or the thruster still lit.
func _release_everything() -> void:
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


# ----------------------------------------------------------------------------- pointer routing
func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		_saw_touch = true
		if t.pressed:
			if _pointer_down(t.index, t.position):
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
	if _saw_touch or Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			if _pointer_down(-1, mb.position):
				get_viewport().set_input_as_handled()
		else:
			_pointer_up(-1)
	elif event is InputEventMouseMotion:
		_pointer_move(-1, (event as InputEventMouseMotion).position)


## Claims a new pointer. Returns true when this node took it.
## Refuses while the controls are off screen, so the timeline hooks can never do something a
## finger could not - a modal is up and the controls are hidden, so nothing is touchable.
func _pointer_down(id: int, pos: Vector2) -> bool:
	if not visible:
		return false
	_wake()
	for bid in _buttons:
		var b: TouchButton = _buttons[bid]
		if b.contains(pos):
			_pointers[id] = {"role": "btn:" + str(bid), "pos": pos}
			b.press()
			return true
	if _stick.zone.has_point(pos) and not _stick.active:
		_pointers[id] = {"role": "stick", "pos": pos}
		_stick.begin(pos)
		return true
	if _in_camera_zone(pos):
		_pointers[id] = {"role": "cam", "pos": pos}
		_update_pinch_ref()
		return true
	return false


func _pointer_move(id: int, pos: Vector2) -> void:
	if not _pointers.has(id):
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
		_pointer_down(DEBUG_ID_BASE + id, Vector2(x, y))
	else:
		_pointer_up(DEBUG_ID_BASE + id)


func debug_drag(id: int, x: float, y: float) -> void:
	_pointer_move(DEBUG_ID_BASE + id, Vector2(x, y))


## Puts a finger on the CENTRE of a named widget ("primary", "jump", "boost", "bag", "journal",
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
	if player != null and player.has_method("get_tangent_velocity"):
		speed = (player.call("get_tangent_velocity") as Vector3).length()
	var sa := MobileUI.safe_area()
	print("TOUCH %s mobile=%s vis=%s modals=%s push=%.2f move=%.3f run=%s speed=%.2f dist=%.2f prompt='%s' | alpha layer=%.2f stick=%.2f primary=%.2f jump=%.2f chrome=%.2f | safe=(%.0f,%.0f,%.0f,%.0f)" % [
		tag, str(MobileUI.is_mobile()), str(visible), str(EventBus.open_modals()), _stick.push,
		Input.get_vector("move_left", "move_right", "move_forward", "move_back").length(),
		str(Input.is_action_pressed("run")), speed, dist, _prompt,
		_layer_alpha, _stick.modulate.a, _primary.modulate.a, _jump.modulate.a, _bag.modulate.a,
		sa.x, sa.y, sa.z, sa.w])
