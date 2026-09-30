class_name HomeAlbumCamera
extends CanvasLayer
## THE HOME PLANET'S OWN CAMERA (docs/STORY_HOME_SPEC.md 8.1, builder HOMEALBUM 2026-09-27).
##
## "On the player's own home planet the camera is always available." No safari, no life or event
## system, no film limit, no subject to focus on and no score - a tap of the shutter always saves a
## photo (or asks which old one to throw away once the album is full; see HomeAlbumStore).
##
## Spawned once by world.gd (see the hook there) and lives for the whole visit to Home; it decides
## for itself when it may show (`_apply_visibility`), the same shape sky_journal.gd's own button
## uses for `_in_world`. Two states:
##   IDLE    just the round "Camera" button, bottom-right.
##   AIMING  first person (CameraRig.set_first_person, reused from the planet safari - see
##           camera_rig.gd's own header), Shutter + Done. Movement is NOT locked: there is nothing
##           to focus on, so unlike a safari's "camera up" there is no reason to plant the player's
##           feet - they can walk around while framing a shot.
##
## CAPTURE: the same technique PlanetSafari._take_photo (planet_safari.gd) already uses to pull a
## clean frame from the live viewport - the canvas_cull_mask trick (so the 2D HUD is not baked into
## the photo), one `RenderingServer.frame_post_draw` wait, then `Viewport.get_texture().get_image()`
## - reused here because that is the one place this project already knows how to do it right, not
## reinvented. What is NOT reused: PlanetSafari's subjects, events, scoring, focus-hold or film
## count - none of that exists on the home planet (spec 8.1: "no life/event system").
##
## SELF-TIMER (docs/JUNGLE_PLANET_SPEC.md 6.1 "Tripod", builder HOMECAM 2026-09-30). Only with
## `flags.tripod_owned`: a third button, "Timer", beside Shutter. It freezes the lens exactly where the
## first-person view was, drops a small procedural tripod there, and hands the player back the ordinary
## third-person camera so they can walk into the shot. "Walk into the shot!" then 3-2-1
## (TIMER_WALK_SEC + 3 s); at zero a temporary Camera3D at the frozen lens becomes current for one
## frame, the same `_capture_frame` pulls it (astronaut drawn - the third-person cull mask), and the
## view returns to first person with Shutter/Timer/Done as before. Cancel, Done, or any modal ends it
## and removes the tripod. The countdown runs on `_process` (PROCESS_MODE_PAUSABLE), so pause holds it.
##
## SYNTHETIC NOTE, spelled out because it matters for anyone testing this headlessly: on
## `DisplayServer.get_name() == "headless"` (see `_capture_frame`) there is no real GPU frame to
## read, exactly the case planet_safari.gd's own `_take_photo` already carries a branch for. This
## file's headless branch manufactures a small solid-colour Image instead, purely so a headless
## probe can exercise the STORE and the UI end to end. It proves neither that a real phone frame
## encodes correctly nor that a finger can reach these buttons - only a windowed capture does that.

const THUMB_W := HomeAlbumStore.THUMB_W
const BTN_H := 84.0
const EDGE := 26.0
const C_TEXT := Color("#2c2f42")
const C_CREAM := Color("#e9eaf1")

var world: Node
var player: Node3D
var rig: CameraRig

var _in_aim := false
var _capturing := false
var _pending_image: Image

var _root: Control
var _idle_btn: Button
var _aim_box: VBoxContainer
var _count_lbl: Label
var _picker_backdrop: Control
var _timer_btn: Button

# Self-timer state (see the SELF-TIMER header block).
const TIMER_WALK_SEC := 2.0
const TIMER_COUNT := 3
const F_TRIPOD := "tripod_owned"
var _timer_on := false
var _timer_left := 0.0
var _timer_xform := Transform3D.IDENTITY
var _timer_fov := 45.0
var _tripod: Node3D
var _timer_cam: Camera3D
var _timer_box: VBoxContainer
var _timer_num: Label
var _timer_hint: Label
## True while the album-full picker holds its own EventBus modal (PICKER_MODAL). Kept as a flag so
## every open is closed exactly once, whichever path closes the picker.
var _picker_modal_held := false

## The picker counts as a modal like every other full-screen panel: `ui_modal_opened` hides
## TouchControls (touch_controls.gd `_sync_state`), freezes the Player and frees the mouse, so a drag
## across the picker can no longer start the movement stick or a camera drag underneath it.
const PICKER_MODAL := "home_album_picker"


## Called from world.gd on the home planet only. Adds and returns the node.
static func attach(w: Node) -> HomeAlbumCamera:
	var c := HomeAlbumCamera.new()
	c.name = "HomeAlbumCamera"
	w.add_child(c)
	return c


func _ready() -> void:
	layer = 41  # under SkyJournal's 42 (sky_journal.gd), above the ordinary HUD chrome
	process_mode = Node.PROCESS_MODE_PAUSABLE
	world = get_parent()
	player = world.get_node_or_null("Player") as Node3D
	rig = world.get_node_or_null("CameraRig") as CameraRig
	_build_ui()
	set_process(true)


func _process(delta: float) -> void:
	_apply_visibility()
	if _timer_on:
		_tick_timer(delta)


func _exit_tree() -> void:
	if _in_aim:
		_end_aim()


## THE BUTTON (and the whole aiming flow) ONLY EXISTS ON HOME, and steps aside for anything already
## using the same PhotoMode gate the rest of the HUD reads (a planet safari elsewhere would not be
## running while we are on Home, but a future life system or the finale might reuse this node's
## planet one day - reading `PhotoMode.planet_id` rather than just `.active` keeps this button from
## ever fighting another photo mode for the screen).
func _apply_visibility() -> void:
	if _root == null:
		return
	var can_show := GameState.current_planet_id == "home" and not _other_modal_open() \
		and not GameState.flag("rocket_arriving") \
		and (not PhotoMode.active or PhotoMode.planet_id == "home")
	_idle_btn.visible = can_show and not _in_aim
	if not can_show and _in_aim:
		_end_aim()


## Any open modal except the picker's own - the picker must not end the aim it belongs to.
func _other_modal_open() -> bool:
	if not EventBus.is_modal_open():
		return false
	var counts: Dictionary = EventBus.modal_counts()
	var ours := int(counts.get(PICKER_MODAL, 0)) if _picker_modal_held else 0
	return EventBus.modal_total() > ours


# ======================================================================================== UI BUILD
func _build_ui() -> void:
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = UIStyle.theme()
	add_child(_root)

	_idle_btn = _pill_button("Camera", _begin_aim)
	_idle_btn.name = "CameraButton"
	_idle_btn.custom_minimum_size = Vector2(150, BTN_H)
	_idle_btn.visible = false
	_root.add_child(_idle_btn)
	_place_idle_button()
	MobileUI.on_mode_changed(func(_m: bool) -> void: _place_idle_button())
	get_viewport().size_changed.connect(_place_idle_button)

	_aim_box = VBoxContainer.new()
	_aim_box.name = "AimBox"
	_aim_box.visible = false
	_aim_box.add_theme_constant_override("separation", 10)
	_aim_box.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_aim_box.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_aim_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_aim_box.position -= Vector2(EDGE, EDGE)
	_root.add_child(_aim_box)

	_count_lbl = _label("")
	_count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_aim_box.add_child(_count_lbl)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	_aim_box.add_child(row)
	row.add_child(_pill_button("Shutter", _on_shutter_pressed))
	_timer_btn = _pill_button("Timer", _begin_self_timer)
	_timer_btn.name = "TimerButton"
	_timer_btn.visible = false
	row.add_child(_timer_btn)
	row.add_child(_pill_button("Done", _end_aim))

	# The countdown, top centre: clear of the movement stick (bottom-left), the look-drag zone and
	# the primary cluster (bottom-right), and of the HUD icon row (top-left).
	_timer_box = VBoxContainer.new()
	_timer_box.name = "TimerBox"
	_timer_box.visible = false
	_timer_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_timer_box.add_theme_constant_override("separation", 6)
	_timer_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_timer_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_timer_box.position.y += 28.0
	_timer_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_timer_box)
	_timer_hint = _label("Walk into the shot!")
	_timer_hint.autowrap_mode = TextServer.AUTOWRAP_OFF
	_timer_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer_hint.add_theme_font_size_override("font_size", 24)
	_timer_hint.add_theme_color_override("font_outline_color", Color("#1b1e2e"))
	_timer_hint.add_theme_constant_override("outline_size", 8)
	_timer_box.add_child(_timer_hint)
	_timer_num = _label("")
	_timer_num.autowrap_mode = TextServer.AUTOWRAP_OFF
	_timer_num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer_num.add_theme_font_size_override("font_size", 72)
	_timer_num.add_theme_color_override("font_outline_color", Color("#1b1e2e"))
	_timer_num.add_theme_constant_override("outline_size", 12)
	_timer_box.add_child(_timer_num)
	var cancel := _pill_button("Cancel timer", _cancel_self_timer)
	cancel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_timer_box.add_child(cancel)


## Round 2 fix (critic FAIL): bottom-right put this button ON TOP of TouchControls' whole primary
## cluster (touch_controls.gd _apply_layout: PRIMARY_HIT_R 78 centred at (right-78, bottom-78), plus
## Emote/Fly above it), and `TouchControls._input` claims a tap there BEFORE this Button's own
## `_gui_input` ever runs (`_pointer_down`'s `contains()` check, then `set_input_as_handled()`) - a
## real touch, and a synthetic ScreenTouch at the button's own centre, both landed on
## role=btn:primary. Bottom-right is *also* inside `_in_camera_zone` (x >= half width, y past
## `CAM_ZONE_TOP`), which claims a look-drag on anything not a recognised button, so there was no
## empty spot left in that corner at all.
##
## Fix: on mobile, sit this button in the same row as TouchControls' own bag/journal/pause HUD
## icons (same `hy` math as touch_controls.gd's `_apply_layout`), just past `_pause`'s hit circle -
## left of the x >= size.x*0.5 line `_in_camera_zone` tests, and well above the movement stick's
## zone (which only starts at `top + (vp.y-top) * STICK_ZONE_TOP`). None of TouchControls' claimed
## regions reach here, so the tap falls through to this Button unclaimed. Desktop (no TouchControls
## visible there) keeps the original bottom-right corner.
func _place_idle_button() -> void:
	if _idle_btn == null:
		return
	if MobileUI.is_mobile():
		_idle_btn.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		var sa := MobileUI.safe_area()
		var left := sa.x + MobileUI.EDGE
		var top := sa.y + MobileUI.EDGE
		var hud_row_y := top + 62.0 + MobileUI.HUD_BTN_HIT_R          # touch_controls.gd's `hy`
		var pause_right := left + MobileUI.HUD_BTN_HIT_R * 6.0 + 16.0  # touch_controls.gd's `_pause.centre.x` + its hit radius
		_idle_btn.position = Vector2(pause_right + 24.0, hud_row_y - BTN_H * 0.5)
	else:
		_idle_btn.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
		_idle_btn.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		_idle_btn.grow_vertical = Control.GROW_DIRECTION_BEGIN
		_idle_btn.position -= Vector2(EDGE, EDGE)


func _label(t: String) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_override("font", UIStyle.ui_font())
	l.add_theme_font_size_override("font_size", 18)
	l.add_theme_color_override("font_color", C_CREAM)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD
	return l


func _pill_button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 58)
	b.add_theme_font_override("font", UIStyle.ui_font())
	b.add_theme_font_size_override("font_size", 20)
	b.add_theme_color_override("font_color", C_TEXT)
	b.add_theme_color_override("font_hover_color", C_TEXT)
	b.add_theme_color_override("font_pressed_color", C_TEXT)
	b.add_theme_stylebox_override("normal", UIStyle.make_pill_style(C_CREAM))
	b.add_theme_stylebox_override("hover", UIStyle.make_pill_style(Color("#f6f7fb")))
	b.add_theme_stylebox_override("pressed", UIStyle.make_pill_style(Color("#d5d8e4")))
	b.pressed.connect(cb)
	return b


func _update_count_label() -> void:
	if _count_lbl != null:
		_count_lbl.text = "Home Album: %d/%d" % [HomeAlbumStore.count(), HomeAlbumStore.MAX_PHOTOS]


# ======================================================================================== AIMING
func _begin_aim() -> void:
	if _in_aim or player == null or not is_instance_valid(rig):
		return
	_in_aim = true
	PhotoMode.begin("home")
	rig.set_first_person(true)
	rig.set_fov_deg(45.0)
	_idle_btn.visible = false
	_aim_box.visible = true
	_timer_btn.visible = GameState.flag(F_TRIPOD)
	_update_count_label()


func _end_aim() -> void:
	if not _in_aim:
		return
	_in_aim = false
	_cancel_self_timer_state()
	_close_picker()
	_pending_image = null
	if is_instance_valid(rig):
		rig.set_first_person(false)
	PhotoMode.end()
	_aim_box.visible = false


# ======================================================================================== THE SHOT
func _on_shutter_pressed() -> void:
	if _capturing or not _in_aim:
		return
	_capturing = true
	var img := await _capture_frame()
	_capturing = false
	if not _in_aim:
		return   # Done was pressed while the frame was mid-capture.
	_handle_captured(img)


func _handle_captured(img: Image) -> void:
	if img == null:
		EventBus.toast_requested.emit("Couldn't take that photo.", "warn")
		return
	if HomeAlbumStore.is_full():
		_pending_image = img
		_open_full_picker()
		return
	_save_and_announce(img)


## Pulls one frame from the live viewport with no 2D on it - PlanetSafari._take_photo's own
## technique (planet_safari.gd), reused verbatim rather than re-derived. See the header for what a
## headless run does instead and why that is not proof of a real photograph.
func _capture_frame(cam_override: Camera3D = null) -> Image:
	var cam := cam_override
	if cam == null:
		cam = rig.get_view_camera() if is_instance_valid(rig) else null
	if cam == null:
		return null
	var vp := get_viewport()
	var headless := DisplayServer.get_name() == "headless"
	var saved_mask := vp.canvas_cull_mask
	vp.canvas_cull_mask = 0
	if not headless:
		await RenderingServer.frame_post_draw
	var img: Image = null
	if headless:
		img = Image.create(64, 36, false, Image.FORMAT_RGB8)
		img.fill(Color(0.3, 0.5, 0.8))
	else:
		img = vp.get_texture().get_image()
	vp.canvas_cull_mask = saved_mask
	AudioManager.play_sfx("place", -2.0)
	if img != null and img.get_width() > THUMB_W:
		var h := maxi(1, int(round(float(img.get_height()) * THUMB_W / float(img.get_width()))))
		img.resize(THUMB_W, h, Image.INTERPOLATE_BILINEAR)
	if img != null and img.get_format() != Image.FORMAT_RGB8:
		img.convert(Image.FORMAT_RGB8)
	return img


func _save_and_announce(img: Image) -> void:
	var id := HomeAlbumStore.add_photo(img)
	if id == "":
		EventBus.toast_requested.emit("Couldn't save that photo.", "warn")
		return
	EventBus.toast_requested.emit(
		"Saved to your Home Album (%d/%d)." % [HomeAlbumStore.count(), HomeAlbumStore.MAX_PHOTOS], "check")
	_update_count_label()


# ======================================================================================== SELF-TIMER
func _begin_self_timer() -> void:
	if not _in_aim or _timer_on or _capturing or not GameState.flag(F_TRIPOD):
		return
	if player == null or not is_instance_valid(rig):
		return
	var cam := rig.get_view_camera()
	if cam == null:
		return
	_timer_xform = cam.global_transform
	_timer_fov = cam.fov
	_spawn_tripod()
	rig.set_first_person(false)
	_aim_box.visible = false
	_timer_box.visible = true
	_timer_on = true
	_timer_left = TIMER_WALK_SEC + float(TIMER_COUNT)
	_update_timer_label()
	AudioManager.play_sfx("place", -6.0)


func _tick_timer(delta: float) -> void:
	var before := ceili(_timer_left)
	_timer_left -= delta
	_update_timer_label()
	if ceili(_timer_left) != before and _timer_left > 0.0 and _timer_left <= float(TIMER_COUNT):
		AudioManager.play_sfx("place", -12.0)   # one soft tick per number
	if _timer_left <= 0.0:
		_timer_on = false
		_fire_self_timer()


func _update_timer_label() -> void:
	if _timer_left > float(TIMER_COUNT):
		_timer_num.text = ""
		_timer_hint.text = "Walk into the shot!"
	else:
		_timer_num.text = str(maxi(1, ceili(_timer_left)))
		_timer_hint.text = "Smile!"


func _fire_self_timer() -> void:
	if not _in_aim or _capturing:
		_cancel_self_timer_state()
		return
	_capturing = true
	var img: Image = null
	var world3d := world as Node
	if world3d != null:
		_timer_cam = Camera3D.new()
		_timer_cam.name = "HomeAlbumTimerCam"
		world3d.add_child(_timer_cam)
		var src := rig.get_camera() if is_instance_valid(rig) else null
		_timer_cam.global_transform = _timer_xform
		_timer_cam.fov = _timer_fov
		if src != null:
			_timer_cam.cull_mask = src.cull_mask   # third person again: the astronaut is drawn
			_timer_cam.near = src.near
			_timer_cam.far = src.far
			_timer_cam.environment = src.environment
			_timer_cam.attributes = src.attributes
		_timer_cam.current = true
		if is_instance_valid(_tripod):
			_tripod.visible = false   # the lens sits inside its head
		if DisplayServer.get_name() != "headless":
			await get_tree().process_frame   # let the switch settle before the frame we read
		img = await _capture_frame(_timer_cam)
	_capturing = false
	_cancel_self_timer_state()
	if not _in_aim:
		return
	# Back to the viewfinder, exactly as before the timer.
	rig.set_first_person(true)
	rig.set_fov_deg(45.0)
	_aim_box.visible = true
	_handle_captured(img)


func _cancel_self_timer() -> void:
	if not _timer_on:
		return
	_cancel_self_timer_state()
	if _in_aim and is_instance_valid(rig):
		rig.set_first_person(true)
		rig.set_fov_deg(45.0)
		_aim_box.visible = true


## Tears down everything the timer made (tripod, temporary lens, countdown) and gives the view back to
## the rig's own camera. Safe to call in any state.
func _cancel_self_timer_state() -> void:
	_timer_on = false
	if is_instance_valid(_timer_cam):
		_timer_cam.current = false
		_timer_cam.queue_free()
	_timer_cam = null
	if is_instance_valid(rig) and rig.get_camera() != null:
		rig.get_camera().current = true
	if is_instance_valid(_tripod):
		_tripod.queue_free()
	_tripod = null
	if _timer_box != null:
		_timer_box.visible = false


## A small procedural tripod standing on the ground under the frozen lens: three legs splayed from the
## head down to the ground around the player's feet, and a camera body with its lens looking the way
## the shot looks. No collision - it is a marker of where the camera is, not an obstacle.
func _spawn_tripod() -> void:
	if is_instance_valid(_tripod):
		_tripod.queue_free()
	var feet := player.global_position
	var head := _timer_xform.origin
	var up := (head - feet).normalized()
	if up.length_squared() < 0.5:
		up = Vector3.UP
	var look := -_timer_xform.basis.z
	var fwd := (look - up * look.dot(up))
	fwd = fwd.normalized() if fwd.length_squared() > 1e-6 else up.cross(Vector3.RIGHT).normalized()
	var right := fwd.cross(up).normalized()
	var height := maxf(0.4, (head - feet).length() - 0.06)
	var top := feet + up * height

	var t := Node3D.new()
	t.name = "HomeAlbumTripod"
	world.add_child(t)
	_tripod = t

	var leg_mat := StandardMaterial3D.new()
	leg_mat.albedo_color = Color("#3a3f55")
	leg_mat.roughness = 0.75
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = Color("#2c2f42")
	body_mat.roughness = 0.6
	var trim_mat := StandardMaterial3D.new()
	trim_mat.albedo_color = Color("#e9eaf1")
	trim_mat.roughness = 0.5

	const SPREAD := 0.32
	for i in 3:
		var a := TAU * float(i) / 3.0 + PI   # one leg straight behind the lens
		var foot := feet + (fwd * cos(a) + right * sin(a)) * SPREAD
		var hip := top - up * 0.05
		var leg_dir := hip - foot
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.018
		cyl.bottom_radius = 0.024
		cyl.height = leg_dir.length()
		cyl.radial_segments = 8
		cyl.rings = 1
		var mi := MeshInstance3D.new()
		mi.mesh = cyl
		mi.material_override = leg_mat
		t.add_child(mi)
		var y := leg_dir.normalized()
		var x := y.cross(up)
		x = x.normalized() if x.length_squared() > 1e-6 else right
		var z := x.cross(y).normalized()
		mi.global_transform = Transform3D(Basis(x, y, z), (foot + hip) * 0.5)

	# Head: a small plate, then the camera body facing the shot, its lens toward `fwd`.
	var basis := Basis(right, up, -fwd)
	var plate := MeshInstance3D.new()
	var pm := CylinderMesh.new()
	pm.top_radius = 0.06
	pm.bottom_radius = 0.07
	pm.height = 0.05
	pm.radial_segments = 12
	plate.mesh = pm
	plate.material_override = leg_mat
	t.add_child(plate)
	plate.global_transform = Transform3D(basis, top - up * 0.03)

	var body := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.24, 0.15, 0.12)
	body.mesh = bm
	body.material_override = body_mat
	t.add_child(body)
	body.global_transform = Transform3D(basis, top + up * 0.075)

	var lens := MeshInstance3D.new()
	var lm := CylinderMesh.new()
	lm.top_radius = 0.045
	lm.bottom_radius = 0.05
	lm.height = 0.08
	lm.radial_segments = 14
	lens.mesh = lm
	lens.material_override = trim_mat
	t.add_child(lens)
	# Cylinder axis is local Y: turn it to point along `fwd`.
	lens.global_transform = Transform3D(Basis(right, fwd, up), top + up * 0.075 + fwd * 0.09)


# ======================================================================================== ALBUM FULL
## Spec 8.1: "When full, the player picks an old photo to throw away before the new one saves (or
## cancels)." `_pending_image` is not saved until a slot is freed.
func _open_full_picker() -> void:
	_close_picker()
	var backdrop := ColorRect.new()
	backdrop.name = "FullPickerBackdrop"
	backdrop.color = Color(0.05, 0.06, 0.12, 0.6)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(backdrop)
	_picker_backdrop = backdrop
	if not _picker_modal_held:
		_picker_modal_held = true
		EventBus.ui_modal_opened.emit(PICKER_MODAL)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIStyle.make_panel_style(C_CREAM, 24))
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	# Round 2 fix (critic FAIL): PRESET_CENTER anchors both edges to the screen's centre point but
	# leaves the default GROW_DIRECTION_END, so as the VBoxContainer's children (header, scroll,
	# Cancel row) push the panel past its zero starting size, only the RIGHT and BOTTOM edges move -
	# the top-left corner stays pinned to the centre. On a phone that put Cancel at y=823 on a
	# 720-tall screen, unreachable. GROW_DIRECTION_BOTH keeps the panel centred as it grows instead.
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	backdrop.add_child(panel)

	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(560, 0)
	col.add_theme_constant_override("separation", 12)
	panel.add_child(col)

	var head := _label("Your Home Album is full (%d). Pick one to throw away." % HomeAlbumStore.MAX_PHOTOS)
	head.add_theme_color_override("font_color", C_TEXT)
	col.add_child(head)

	var scroll := ScrollContainer.new()
	# Belt-and-braces alongside GROW_DIRECTION_BOTH above: even centred, a screen shorter than the
	# panel's natural height (360 scroll + header + Cancel row + panel padding) would still crop
	# top and bottom equally. Shrink the scroll first so the whole panel is guaranteed to fit with
	# margin, on the shortest side the project ships (both representative phones are 720 logical
	# px tall - docs/... mobile_ui.gd's own dp-math header). CHROME_H is the header (up to 2 lines)
	# + Cancel row + panel content margins (20 px x2, UIStyle.make_panel_style's default `margin`)
	# + the VBox's own separation, measured generously so this never has to be exact.
	const CHROME_H := 150.0
	const OUTER_MARGIN := 48.0  # breathing room kept clear above and below the panel
	var vp_h := get_viewport().get_visible_rect().size.y
	scroll.custom_minimum_size = Vector2(0, clampf(vp_h - CHROME_H - OUTER_MARGIN, 140.0, 360.0))
	col.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(grid)
	for rec: Dictionary in HomeAlbumStore.list():
		grid.add_child(_picker_cell(rec))

	var row := HBoxContainer.new()
	col.add_child(row)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	row.add_child(_pill_button("Cancel", func():
		_pending_image = null
		_close_picker()))


func _picker_cell(rec: Dictionary) -> Control:
	var id := str(rec.get("id", ""))
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(150, 0)
	box.add_theme_constant_override("separation", 6)
	var img := HomeAlbumStore.decode_image(rec)
	var tex_rect := TextureRect.new()
	tex_rect.custom_minimum_size = Vector2(150, 100)
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	if img != null:
		tex_rect.texture = ImageTexture.create_from_image(img)
	box.add_child(tex_rect)
	var day_lbl := _label("Day %d" % int(rec.get("day", 0)))
	day_lbl.add_theme_color_override("font_color", C_TEXT)
	day_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(day_lbl)
	box.add_child(_pill_button("Throw away", func(): _on_pick_throw(id)))
	return box


func _on_pick_throw(id: String) -> void:
	HomeAlbumStore.delete_photo(id)
	var img := _pending_image
	_pending_image = null
	_close_picker()
	if img != null:
		_save_and_announce(img)


func _close_picker() -> void:
	if is_instance_valid(_picker_backdrop):
		_picker_backdrop.queue_free()
	_picker_backdrop = null
	if _picker_modal_held:
		_picker_modal_held = false
		EventBus.ui_modal_closed.emit(PICKER_MODAL)


# ======================================================================================== DEBUG (probes)
## A headless run has no finger to tap these buttons with - these call the same private handlers a
## real tap reaches, exactly the shape sky_journal.gd's own `debug_*` hooks and
## safari_layer.gd's `debug_choice_tap` already use for this project's automated checks.
func debug_begin() -> void:
	_begin_aim()


func debug_shutter() -> void:
	await _on_shutter_pressed()


func debug_end() -> void:
	_end_aim()


## TEST ONLY: grants the Tripod and every filter (JUNGLE_PLANET_SPEC 6.1 flag names) - a probe sets
## the flags itself rather than buying them from Moss.
func debug_grant_goods() -> void:
	GameState.flags[F_TRIPOD] = true
	GameState.flags[HomeAlbumFilters.F_OWNED] = HomeAlbumFilters.IDS.duplicate()
	if _in_aim:
		_timer_btn.visible = true


func debug_self_timer() -> void:
	_begin_self_timer()


func debug_timer_state() -> void:
	print("HOMECAM_TIMER on=%s left=%.2f tripod=%s cam_current=%s num='%s' hint='%s'" % [
		str(_timer_on), _timer_left, str(is_instance_valid(_tripod)),
		str(get_viewport().get_camera_3d().name if get_viewport().get_camera_3d() else "none"),
		_timer_num.text, _timer_hint.text])
	if is_instance_valid(_tripod) and player != null:
		var cam := get_viewport().get_camera_3d()
		var kids: Array = []
		for k in _tripod.get_children():
			kids.append("%s vis=%s" % [str((k as Node3D).global_position.snapped(Vector3.ONE * 0.01)), str((k as Node3D).is_visible_in_tree())])
		print("HOMECAM_TRIPOD at=%s player=%s dist=%.2f cam=%s on_screen=%s kids=%s" % [
			str(_timer_xform.origin), str(player.global_position), player.global_position.distance_to(_timer_xform.origin),
			str(cam.global_position) if cam else "-",
			str(cam.unproject_position(_timer_xform.origin)) if cam else "-", str(kids)])


## TEST ONLY: writes the newest album photo, as stored (no filter), to `path` as a PNG.
func debug_export_last(path: String) -> void:
	var recs := HomeAlbumStore.list()
	if recs.is_empty():
		print("HOMECAM_EXPORT none")
		return
	var img := HomeAlbumStore.decode_image(recs[recs.size() - 1])
	var err := img.save_png(path) if img != null else ERR_INVALID_DATA
	print("HOMECAM_EXPORT %s %s %s" % [path, error_string(err), str(img.get_size()) if img else "-"])


## TEST ONLY: copies the newest photo `n` times (so one shot can be shown in every filter) and gives
## the photos, oldest first, the filters in `filters` ("" = none).
func debug_copy_last_and_filter(n: int, filters: Array) -> void:
	var recs := HomeAlbumStore.list()
	if recs.is_empty():
		return
	var img := HomeAlbumStore.decode_image(recs[recs.size() - 1])
	for i in n:
		if img != null:
			HomeAlbumStore.add_photo(img)
	recs = HomeAlbumStore.list()
	for i in mini(filters.size(), recs.size()):
		HomeAlbumStore.set_filter(str(recs[i].get("id", "")), str(filters[i]))


func debug_clear_album() -> void:
	HomeAlbumStore.clear_all()


func debug_save() -> void:
	print("HOMECAM_SAVE ok=%s" % str(SaveManager.save_game()))


func debug_load() -> void:
	print("HOMECAM_LOAD ok=%s" % str(SaveManager.load_game()))


func debug_scramble_filters() -> void:
	for r: Dictionary in HomeAlbumStore.list():
		HomeAlbumStore.set_filter(str(r.get("id", "")), "")


func debug_is_aiming() -> bool:
	return _in_aim


func debug_picker_open() -> bool:
	return is_instance_valid(_picker_backdrop)


func debug_pick_throw(id: String) -> void:
	_on_pick_throw(id)


func debug_cancel_picker() -> void:
	_pending_image = null
	_close_picker()


## TEST ONLY - mirrors PlanetSafari's own `debug_fake_print` (planet_safari.gd): fills the album
## straight from HomeAlbumStore with up to `n` synthetic photos, bypassing the aiming UI entirely,
## so a probe can reach "album full" without pressing the shutter 25 times. Stops at MAX_PHOTOS.
## Returns how many were actually added.
func debug_fill_with(n: int) -> int:
	var added := 0
	while added < n and not HomeAlbumStore.is_full():
		var img := Image.create(8, 8, false, Image.FORMAT_RGB8)
		img.fill(Color(0.2, 0.6, 0.3))
		if HomeAlbumStore.add_photo(img) == "":
			break
		added += 1
	return added


## TEST ONLY. One line to a Director log / headless console: the whole state a probe needs to
## check, so no return value has to travel back through Director's fire-and-forget "call" op.
func debug_dump() -> void:
	var ids: Array = []
	for r: Dictionary in HomeAlbumStore.list():
		ids.append(str(r.get("id", "")))
	var filters: Array = []
	for r: Dictionary in HomeAlbumStore.list():
		filters.append(HomeAlbumStore.get_filter(r))
	print("HOMEALBUM_PROBE count=%d full=%s aiming=%s picker=%s ids=%s filters=%s" % [
		ids.size(), str(HomeAlbumStore.is_full()), str(_in_aim), str(is_instance_valid(_picker_backdrop)), str(ids),
		str(filters)])
