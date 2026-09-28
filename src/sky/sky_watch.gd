class_name SkyWatch
extends CanvasLayer
## SPIKE ROUND 2 (2026-09-20, scratch only). The moment at the eyepiece: read the forecast, plant
## the scope, HUNT for the sight, track it while the sky turns, and pull a plate.
##
## Add it to any world and it finds the Environment (for the clock) and the Player (for where the
## scope goes) by itself:
##     var w := SkyWatch.new()
##     add_child(w)
##
## WHAT ROUND 1 GOT WRONG, and what this does instead. An Opus reviewer played a whole night and
## said "the sky half is a 6-second minigame wearing a 20-minute night":
##
## 1. IT WAS OVER IN 4.6-6.9 s AND NEVER FAILED. Now a watch is a hunt, a track and a plate:
##      FIND   the sight is NOT centred. It sits MISS_MIN..MISS_MAX field radii off the forecast's
##             aim, in a direction fixed by the event id, so you sweep to it. 5-12 s.
##      TRACK  the plate needs EXPOSURE_NEED seconds of PERFECT quality, and fills at the rate of
##             whatever quality you are actually holding. A careful watcher fills it in ~16 s; a
##             sloppy one takes twice that and may run out of sky.
##      PULL   from MIN_TAKE onward you may close the shutter early and keep a grainier plate.
##    Target engagement 20-40 s per sight, and the numbers measured in `showcase/sky_bench.gd`.
##
## 2. IT NEVER FOUGHT BACK. Three things move the sight now and only one of them repeats:
##      SIDEREAL  a CONSTANT creep, SIDEREAL field radii a second, in one direction, forever. You
##                can never park the scope. This is what makes tracking a verb.
##      SEEING    two slow sine layers per axis, as before.
##      GUSTS     a spring-damper kicked every GUST_GAP_MIN..MAX seconds. Thin air, and your own
##                breath on the eyepiece. Harder on a rarer sight, which is low and faint.
##
## 3. FAILING IS POSSIBLE, two ways: lose the sight for SPOIL_SEC seconds and the plate fogs, or
##    reach the end of WINDOW_SEC with less than MIN_TAKE on the plate and it drifted out of reach.
##    A ruined plate makes NO print.
##
## 4. THE WORLD DOES NOT GO BLACK. Round 1 drew an opaque scrim and a full-screen eyepiece, so you
##    never felt like you were standing anywhere. Now the watch camera drops to the eye cup of the
##    real telescope, the eyepiece is a ROUND hole about 62% of the screen height, and your own
##    planet, the scope and the horizon stay on screen around it.
##
## 5. SHARPNESS IS THE PRIZE. Rarity is the coin (Gloop prices a COPY on it and you keep the
##    original). Sharpness sets the grade, fills the journal's best-per-sight, and is what you give
##    a neighbour for their wall. See sky_print.gd.
##
## SYNTHETIC HOOKS for captures (`debug_*`) push the SAME numbers the fingers do, but they are NOT
## proof a real finger works - CLAUDE.md, "Say what is synthesised".

## BOOK round (2026-09-21): THE TRIPOD AND THE SHIP LOOK THROUGH THE SAME GLASS.
## This used to preload `sky_eyepiece.gdshader`, which draws THREE shapes: aurora curtains, a
## comet, a ringed disc. The forecast now hands it SafariCatalog sights - lantern-fish, a dead
## mail hulk, a pool holding the whole sun - and there is no honest way to draw a school of eels
## with a curtain. `safari_eyepiece.gdshader` is the same job done for the flight, with the SIX
## shapes the catalog actually names, and `safari_shapes.gd` carries the twelve knobs per sight
## that make 51 pictures instead of 6. So the standing scope borrows the flight's glass.
##
## FOUR UNIFORMS TURN A COCKPIT WINDOW BACK INTO A TUBE, and none of them is a new parameter:
##   aspect 1.0 + corner 1.0   the rounded box collapses to a UNIT CIRCLE (its own maths: with
##                             hb = (1,1) - (1,1) = 0, the distance is length(|p|) - 1)
##   dest_r / home_r 0.0       no worlds in the field; you are standing on one, not flying past two
##   flow_from (0,0), run 0    no lane shear: the tripod is not moving, which is the whole point
## Nothing about scoring moved. `s0_pos` is in the same field units the old `aim` was.
const EYE_SHADER := preload("res://src/sky/safari_eyepiece.gdshader")

enum St { IDLE, FORECAST, WAITING, WATCH, PRINT, RUINED, PRINTS }

# ---------------------------------------------------------------- the skill model, all in one place
## Half the eyepiece's field of view, in degrees. Field radius 1.0 = this far off the tube's axis.
const FIELD_HALF_DEG := 8.5
## THE SIGHT IS WHERE THE FORECAST SAYS IT IS. The scope is what is pointed somewhere else: it is
## parked this many DEGREES off the sight when you bend to it, so you sweep the tube toward "high in
## the north" to find it. The brief: "do not hand the player a centred target".
const PARK_OFF_MIN := 13.5
const PARK_OFF_MAX := 18.5
## Field radii the scope can be swung from the forecast aim. Has to cover MISS_MAX plus a whole
## window of sidereal creep, or a careful player runs out of travel and fails for no reason.
const AIM_CLAMP := 5.6
## Drag gain: dragging across the eyepiece's radius swings the scope this many field radii.
const AIM_GAIN := 1.15
## The sky turns, always, in one direction. Field radii per second.
const SIDEREAL := 0.050
## Gusts: a spring-damper kicked at random intervals. Thin air and your own breath.
const GUST_GAP_MIN := 2.2
const GUST_GAP_MAX := 4.6
const GUST_STIFF := 26.0
const GUST_DAMP := 5.2
## Field radius inside which centring scores 1.0, and the radius at which it scores 0.
const CENTRE_R := 0.16
const EDGE_R := 0.40
## Focus error at which sharpness reaches 0. The knob runs 0..1, so this is an 18% band.
const FOCUS_TOL := 0.18
## Below this instantaneous quality the plate does not expose at all and you start LOSING it.
const Q_FLOOR := 0.22
## Seconds of PERFECT quality that fill the plate. Kept as HOLD_SEC too because the round-1
## showcases (aim_cal, sky_autopilot) read that name.
const EXPOSURE_NEED := 20.0
const HOLD_SEC := EXPOSURE_NEED
## Real seconds of sky before the sight is out of reach.
const WINDOW_SEC := 62.0
## The plate is worth pulling from here on.
const MIN_TAKE := 0.35
## Continuous-ish seconds of losing it before the plate fogs. Recovers at RECOVER_RATE while you
## are holding it again, so one bad gust is survivable and six seconds of flailing is not.
const SPOIL_SEC := 6.0
const RECOVER_RATE := 1.6
## A short exposure is grainy. sharpness = mean quality x (this floor + the rest x exposure).
const SHORT_FLOOR := 0.55
## Seconds left in the window at which the overlay starts shouting.
const WARN_SEC := 14.0
## "Wait" no longer fast-forwards the night (round-1 finding 3). It runs at this, and stops dead the
## moment the sky goes dark - you can skip a boring afternoon, never the night the game is about.
const WAIT_TIME_SCALE := 8.0

const C_CREAM := Color("#e9eaf1")
const C_TEXT := Color("#2c2f42")
const C_SOFT := Color("#6d7288")
const C_NAVY := Color("#1b1f33")
const C_GOOD := Color("#6fc47f")
const C_WARN := Color("#f0a64a")
const C_BAD := Color("#e8646f")
const C_DUST := Color("#ffe27a")

signal print_made(p: SkyPrint)
signal watch_failed(event_id: String, reason: String)

var prints: Array[SkyPrint] = []

## Set by the driver (or found at /root/SkyJournal). Anything with `record(p: SkyPrint) -> Dictionary`.
## See the header note in `_record()` for the shape this expects back.
var journal: Object = null

var _state: int = St.IDLE
var _forecast: Array = []
var _forecast_day := -1
var _event: Dictionary = {}
var _env: Node = null
var _player: Node3D = null
var _scope: Telescope = null
var _frozen: Array[Node] = []

# --- watch state
var _t := 0.0
var _aim := Vector2.ZERO          # how far the scope has been swung, in field radii
var _sight := Vector2.ZERO        # where the sight sits in the field right now
var _focus := 0.5
var _focus_opt := 0.5
var _sharp := 0.0
var _centred := 0.0
var _q := 0.0
var _hold := 0.0                  # seconds of PERFECT exposure on the plate so far
var _q_sum := 0.0
var _q_time := 0.0
var _lost := 0.0
var _acquired := false
var _acquire_t := 0.0
var _drift_seed := 0.0
var _finishing := false
var _fail_reason := ""
var _miss := Vector2.ZERO         # the sight's fixed offset from the forecast aim, in field radii
var _sid := Vector2.ZERO          # unit direction of the sidereal creep
var _wob := Vector2.ZERO
var _wob_v := Vector2.ZERO
var _gust_t := 0.0
var _gust_mag := 1.2
var _rng := RandomNumberGenerator.new()
var _base_az := 90.0          # where the tube is PARKED (degrees)
var _base_el := 20.0
var _sight_az := 90.0         # where the forecast says the sight is (degrees)
var _sight_el := 20.0

# --- the watch camera (finding 5: the world must not go black). Exported-ish so a camera sweep can
# move it without editing the file; the shipped numbers are the defaults.
## Picked by sweeping eleven placements and LOOKING at the frames (shots/cam*, 2026-09-20): this is
## the one where the tube, the tripod, the astronaut, the ground and the horizon are all readable at
## night and none of them sits under the eyepiece.
var cam_back := 1.15
var cam_up := 0.36
var cam_side := 1.05
var cam_yaw := 2.00
var cam_pitch := 0.50
var eye_cx := 0.470
var _cam: Camera3D = null
var _prev_cam: Camera3D = null

# --- pointer routing (mirrors touch_controls.gd: real touches win, the mouse is the fallback)
var _touch_seen := false
var _zones: Dictionary = {}

# --- nodes
var _root: Control
var _bar: HBoxContainer
var _clock_lbl: Label
var _panel: PanelContainer
var _eye_root: Control
var _dim: ColorRect
var _eye: ColorRect
var _eye_mat: ShaderMaterial
var _overlay: Overlay
var _shutter: Button
var _giveup: Button
var _wait_lbl: Label
var _wait_root: Control
var _card: PanelContainer
var _card_dim: ColorRect
var _prev_vp: SubViewport
var _prev_rect: ColorRect


func _ready() -> void:
	layer = 40
	name = "SkyWatch"
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_build_preview_viewport()
	set_process(true)
	_refresh_forecast()


# ------------------------------------------------------------------ world hookups
func _env_node() -> Node:
	if is_instance_valid(_env):
		return _env
	_env = get_node_or_null("/root/World/Environment")
	if _env == null:
		var w := get_tree().get_first_node_in_group("planet")
		if w != null and w.get_parent() != null:
			_env = w.get_parent().get_node_or_null("Environment")
	return _env


func _player_node() -> Node3D:
	if is_instance_valid(_player):
		return _player
	_player = get_tree().get_first_node_in_group("player") as Node3D
	return _player


func hour() -> float:
	var e := _env_node()
	if e != null and e.has_method("get_hour"):
		return float(e.call("get_hour"))
	return fposmod(GameState.time_of_day, 24.0)


func day() -> int:
	return GameState.day_count


# ------------------------------------------------------------------ forecast
func _refresh_forecast() -> void:
	var d := day()
	if d != _forecast_day:
		_forecast_day = d
		_forecast = SkyEvents.forecast_for_day(d)


## Today's sights. Another system (Gloop's table, the journal) can read this directly.
func forecast() -> Array:
	_refresh_forecast()
	return _forecast


## The sight that is up right now, or {} if the sky has nothing on.
func current_event() -> Dictionary:
	var h := hour()
	for ev in forecast():
		if SkyEvents.in_window(ev, h):
			return ev
	return {}


# ------------------------------------------------------------------ UI build
func _build_ui() -> void:
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = UIStyle.theme()
	add_child(_root)

	# --- bottom-left buttons + clock
	var wrap := MarginContainer.new()
	wrap.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_theme_constant_override("margin_left", 28)
	wrap.add_theme_constant_override("margin_bottom", 28)
	wrap.grow_horizontal = Control.GROW_DIRECTION_END
	wrap.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_root.add_child(wrap)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	wrap.add_child(col)

	_clock_lbl = Label.new()
	_clock_lbl.add_theme_font_override("font", UIStyle.ui_font())
	_clock_lbl.add_theme_font_size_override("font_size", 22)
	_clock_lbl.add_theme_color_override("font_color", C_CREAM)
	_clock_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	_clock_lbl.add_theme_constant_override("shadow_offset_y", 2)
	col.add_child(_clock_lbl)

	_bar = HBoxContainer.new()
	_bar.add_theme_constant_override("separation", 12)
	col.add_child(_bar)
	_bar.add_child(_mk_button("Forecast  [1]", _on_forecast))
	_bar.add_child(_mk_button("Set up scope  [2]", _on_setup))
	_bar.add_child(_mk_button("Prints  [3]", _on_prints))

	# --- forecast / prints panel
	_panel = PanelContainer.new()
	_panel.name = "Panel"
	_panel.visible = false
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_panel.add_theme_stylebox_override("panel", UIStyle.make_panel_style(C_CREAM, 26))
	_root.add_child(_panel)

	# --- eyepiece
	_eye_root = Control.new()
	_eye_root.name = "Eyepiece"
	_eye_root.visible = false
	_eye_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_eye_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_eye_root.gui_input.connect(_on_eye_input)
	_root.add_child(_eye_root)

	# A TINT, not a scrim. Round 1 painted this nearly opaque and the planet vanished.
	_dim = ColorRect.new()
	_dim.color = Color(0.010, 0.013, 0.028, 0.34)
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_eye_root.add_child(_dim)

	_eye = ColorRect.new()
	_eye.name = "Field"
	_eye.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_eye_mat = ShaderMaterial.new()
	_eye_mat.shader = EYE_SHADER
	_tube_uniforms(_eye_mat, 1.0)
	_eye.material = _eye_mat
	_eye_root.add_child(_eye)

	_overlay = Overlay.new()
	_overlay.watch = self
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_eye_root.add_child(_overlay)

	# Buttons LAST so they sit on top of the drag surface and eat their own taps.
	_shutter = _mk_button("Close the shutter", _on_shutter)
	_shutter.visible = false
	_eye_root.add_child(_shutter)
	_giveup = _mk_button("Stand up", _on_close)
	_eye_root.add_child(_giveup)

	# --- waiting scrim
	_wait_root = Control.new()
	_wait_root.visible = false
	_wait_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_wait_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(_wait_root)
	var wscrim := ColorRect.new()
	wscrim.color = Color(0.02, 0.025, 0.05, 0.72)
	wscrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wscrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wait_root.add_child(wscrim)
	_wait_lbl = Label.new()
	_wait_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_wait_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_wait_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_wait_lbl.add_theme_font_override("font", UIStyle.ui_font())
	_wait_lbl.add_theme_font_size_override("font_size", 34)
	_wait_lbl.add_theme_color_override("font_color", C_CREAM)
	_wait_root.add_child(_wait_lbl)

	# --- print / ruined card
	_card = PanelContainer.new()
	_card.visible = false
	_card.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_card.grow_vertical = Control.GROW_DIRECTION_BOTH
	_card_dim = ColorRect.new()
	_card_dim.color = Color(0.010, 0.013, 0.028, 0.45)
	_card_dim.visible = false
	_card_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_card_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(_card_dim)

	_card.add_theme_stylebox_override("panel", UIStyle.make_panel_style(C_CREAM, 26))
	_root.add_child(_card)


func _mk_button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 64)
	b.add_theme_font_override("font", UIStyle.ui_font())
	b.add_theme_font_size_override("font_size", 22)
	b.add_theme_color_override("font_color", C_TEXT)
	b.add_theme_color_override("font_hover_color", C_TEXT)
	b.add_theme_color_override("font_pressed_color", C_TEXT)
	b.add_theme_stylebox_override("normal", UIStyle.make_pill_style(C_CREAM))
	b.add_theme_stylebox_override("hover", UIStyle.make_pill_style(Color("#f6f7fb")))
	b.add_theme_stylebox_override("pressed", UIStyle.make_pill_style(Color("#d5d8e4")))
	b.add_theme_constant_override("h_separation", 10)
	b.pressed.connect(cb)
	return b


func _build_preview_viewport() -> void:
	_prev_vp = SubViewport.new()
	_prev_vp.size = Vector2i(256, 256)
	_prev_vp.transparent_bg = false
	_prev_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_prev_vp.disable_3d = true
	add_child(_prev_vp)
	_prev_rect = ColorRect.new()
	_prev_rect.size = Vector2(256, 256)
	var m := ShaderMaterial.new()
	m.shader = EYE_SHADER
	# corner 0.22, the same rounded square `safari_haul.gd` renders a flight's print into, so a page
	# filled from the ground and a page filled from the ship hold the same shape of photograph.
	_tube_uniforms(m, 0.22)
	_prev_rect.material = m
	_prev_vp.add_child(_prev_rect)


# ------------------------------------------------------------------ state
func _set_state(s: int) -> void:
	_state = s
	_bar.get_parent().visible = s == St.IDLE
	_panel.visible = s == St.FORECAST or s == St.PRINTS
	_eye_root.visible = s == St.WATCH
	_wait_root.visible = s == St.WAITING
	_card.visible = s == St.PRINT or s == St.RUINED
	_card_dim.visible = _card.visible
	if s == St.WATCH:
		_freeze_world(true)
		_open_camera()
	elif s == St.PRINT or s == St.RUINED:
		# The card stays AT THE SCOPE: the watch camera keeps looking at the telescope on your
		# planet, the world is still frozen and the game's HUD is still away, so the print is the
		# only new thing on screen. Round 1 dropped you back to the wide gameplay view here.
		pass
	else:
		_close_camera()
		_freeze_world(false)


## Stops the player and the camera rig, and hides the game's own HUD, so the stick and the buttons
## underneath cannot fight the eyepiece for the same finger. The world keeps RENDERING - that is the
## whole point of round 2.
func _freeze_world(on: bool) -> void:
	if on:
		if not _frozen.is_empty():
			return
		for path in ["/root/World/Player", "/root/World/CameraRig"]:
			var n := get_node_or_null(path)
			if n != null:
				n.process_mode = Node.PROCESS_MODE_DISABLED
				_frozen.append(n)
		_hide_world_ui(true)
	else:
		for n in _frozen:
			if is_instance_valid(n):
				n.process_mode = Node.PROCESS_MODE_INHERIT
		_frozen.clear()
		_hide_world_ui(false)


## Every CanvasLayer the world owns - the HUD, the mobile stick, the marker pills - goes away while
## you are at the eyepiece. Round 1 only hid the node called "HUD", and a "Rocket 10 m" marker sat
## across the eyepiece in the first capture of round 2.
var _hidden_ui: Array[CanvasLayer] = []


func _hide_world_ui(on: bool) -> void:
	if on:
		var w := get_node_or_null("/root/World")
		if w == null:
			return
		_collect_layers(w)
	else:
		for n in _hidden_ui:
			if is_instance_valid(n):
				n.visible = true
		_hidden_ui.clear()


## Recursive: the rocket pad's "Rocket 10 m" pip is a CanvasLayer nested under the PAD, so walking
## only World's direct children left it sitting across the eyepiece (round-2 capture 2).
func _collect_layers(n: Node) -> void:
	for c in n.get_children():
		if c is CanvasLayer:
			if c != self and (c as CanvasLayer).visible:
				(c as CanvasLayer).visible = false
				_hidden_ui.append(c as CanvasLayer)
		else:
			_collect_layers(c)


# ------------------------------------------------------- the watch camera (finding 5)
## Drops the view to the eye cup of the real telescope. It is placed ONCE, from the forecast's aim,
## and then held still: the scope swings inside the frame while you drag, which is what tells you
## the thing on the ground and the thing in the eyepiece are the same thing. A camera that followed
## the swing would just be a gimbal and would make the planet slide about.
func _open_camera() -> void:
	if not is_instance_valid(_scope):
		return
	if _cam == null or not is_instance_valid(_cam):
		_cam = Camera3D.new()
		_cam.name = "SkyWatchCam"
		_cam.fov = 64.0
		_cam.near = 0.04
		get_tree().root.add_child(_cam)
	_prev_cam = get_viewport().get_camera_3d()
	var up := _scope.local_up()
	var eye := _scope.eye_point()
	var fwd := _scope.tube_forward()
	var fwd_flat := (fwd - up * up.dot(fwd))
	if fwd_flat.length_squared() < 0.0001:
		fwd_flat = Vector3.FORWARD
	fwd_flat = fwd_flat.normalized()
	var side := up.cross(fwd_flat).normalized()
	# Behind the eye cup, a little above it, and a little to the side the player is standing on, so
	# the barrel runs across the lower corner of the frame instead of down the middle of it.
	var pos := eye - fwd_flat * cam_back + up * cam_up + side * cam_side
	# Look PAST the hood and only slightly up: the horizon then sits in the lower third, which is
	# what makes it read as "standing on a small world" rather than "pointed at the ceiling".
	var target := eye + fwd_flat * 3.0 + side * cam_yaw + up * cam_pitch
	_cam.look_at_from_position(pos, target, up)
	_cam.current = true


func _close_camera() -> void:
	if _cam != null and is_instance_valid(_cam):
		_cam.current = false
	if _prev_cam != null and is_instance_valid(_prev_cam):
		_prev_cam.current = true
	_prev_cam = null


# ------------------------------------------------------------------ buttons
func _on_forecast() -> void:
	_fill_forecast_panel()
	_set_state(St.FORECAST)


func _on_prints() -> void:
	_fill_prints_panel()
	_set_state(St.PRINTS)


func _on_setup() -> void:
	var ev := current_event()
	if ev.is_empty():
		_fill_forecast_panel()
		_set_state(St.FORECAST)
		return
	start_watch(ev)


func _on_close() -> void:
	_set_state(St.IDLE)


func _on_shutter() -> void:
	if _state == St.WATCH and not _finishing and _expo_frac() >= MIN_TAKE:
		_finishing = true
		_finish_watch()


# ------------------------------------------------------------------ forecast panel
func _fill_forecast_panel() -> void:
	## MERGE (reviewer, round 2): the PLAN builder owns this panel now (src/sky/sky_plan.gd).
	## It shows real minutes to each sight and has NO "Wait" button, so nothing skips the clock.
	SkyPlan.fill_panel(self, _panel, _on_close)


func _forecast_row(ev: Dictionary, h: float) -> Control:
	var row := PanelContainer.new()
	var up := SkyEvents.in_window(ev, h)
	var here := str(ev.get("world", "")) == GameState.current_planet_id
	var tint := Color("#e2f0e2") if up else Color("#e3e5ee")
	row.add_theme_stylebox_override("panel", UIStyle.make_panel_style(tint, 18))
	var mm := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		mm.add_theme_constant_override("margin_" + side, 14)
	row.add_child(mm)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)
	mm.add_child(hb)

	var txt := VBoxContainer.new()
	txt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	txt.add_theme_constant_override("separation", 2)
	hb.add_child(txt)
	txt.add_child(_body(str(ev["title"])))
	var tag := "MORNING" if SkyEvents.is_morning(ev) else "NIGHT"
	txt.add_child(_small("%s  %s  ·  %s  ·  %s" % [
		tag, SkyEvents.window_text(ev), str(ev["where"]), SkyEvents.rarity_name(int(ev["rarity"]))]))
	# Finding 4: say what the trip is worth BEFORE the trip, not on the card afterwards.
	if here:
		txt.add_child(_small("You are on %s. A Gallery print is possible." % str(ev["world"]).capitalize()))
	else:
		txt.add_child(_small("From here it caps at %d%%. Go to %s for a Gallery." % [
			int(round(SkyPrint.OFF_WORLD_CAP * 100.0)), str(ev["world"]).capitalize()]))

	if up:
		hb.add_child(_mk_button("Watch now", func(): start_watch(ev)))
	else:
		var wait_h := SkyEvents.hours_until(ev, h)
		hb.add_child(_mk_button("Wait %.1f h" % wait_h, func(): _start_wait(ev)))
	return row


func _fill_prints_panel() -> void:
	for c in _panel.get_children():
		c.queue_free()
	var m := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 26)
	_panel.add_child(m)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	col.custom_minimum_size = Vector2(720, 0)
	m.add_child(col)
	col.add_child(_head("Prints in the satchel: %d" % prints.size()))
	if prints.is_empty():
		col.add_child(_small("None yet. Set up the scope on something that is up."))
	var strip := HBoxContainer.new()
	strip.add_theme_constant_override("separation", 12)
	col.add_child(strip)
	for i in mini(prints.size(), 6):
		var p: SkyPrint = prints[prints.size() - 1 - i]
		var cell := VBoxContainer.new()
		cell.add_theme_constant_override("separation", 4)
		strip.add_child(cell)
		cell.add_child(_thumb(p, 104))
		cell.add_child(_small("%s  %s" % [p.grade, p.sharpness_text()]))
	var foot := HBoxContainer.new()
	foot.alignment = BoxContainer.ALIGNMENT_END
	col.add_child(foot)
	foot.add_child(_mk_button("Close", _on_close))


func _thumb(p: SkyPrint, px: int) -> Control:
	var tr := TextureRect.new()
	tr.custom_minimum_size = Vector2(px, px)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	if p.preview != null:
		tr.texture = ImageTexture.create_from_image(p.preview)
	return tr


func _head(t: String) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_override("font", UIStyle.ui_font())
	l.add_theme_font_size_override("font_size", 30)
	l.add_theme_color_override("font_color", C_TEXT)
	return l


func _body(t: String) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_override("font", UIStyle.ui_font())
	l.add_theme_font_size_override("font_size", 22)
	l.add_theme_color_override("font_color", C_TEXT)
	return l


func _small(t: String) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_override("font", UIStyle.ui_font())
	l.add_theme_font_size_override("font_size", 17)
	l.add_theme_color_override("font_color", C_SOFT)
	return l


# ------------------------------------------------------------------ waiting
var _wait_ev: Dictionary = {}
var _wait_prev_scale := 1.0


## ROUND-1 FINDING 3: this button ran the clock at 220x, so the player could skip the very night the
## game is about. It now runs at 8x and STOPS THE INSTANT THE SKY GOES DARK. You can pass a boring
## afternoon; you cannot pass a night.
func _start_wait(ev: Dictionary) -> void:
	var e := _env_node()
	if e == null:
		return
	_wait_ev = ev
	_wait_prev_scale = float(e.get("time_scale"))
	e.set("time_scale", WAIT_TIME_SCALE)
	_set_state(St.WAITING)


func _end_wait(and_watch: bool) -> void:
	var e := _env_node()
	if e != null:
		e.set("time_scale", _wait_prev_scale)
	var ev := _wait_ev
	_wait_ev = {}
	if and_watch and not ev.is_empty():
		start_watch(ev)
	else:
		_set_state(St.IDLE)


func _night_factor() -> float:
	var e := _env_node()
	if e != null and e.has_method("get_night_factor"):
		return clampf(float(e.call("get_night_factor")), 0.0, 1.0)
	return 0.0


func _tick_wait() -> void:
	if _wait_ev.is_empty():
		_end_wait(false)
		return
	_wait_lbl.text = "Waiting for %s\n%s" % [str(_wait_ev["title"]), SkyEvents.clock_text(hour())]
	if SkyEvents.in_window(_wait_ev, hour()):
		_end_wait(true)
		return
	if _night_factor() > 0.5:
		_wait_lbl.text = "Night. Go and look."
		_end_wait(false)


# ------------------------------------------------------------------ the watch
## Plants the scope and opens the eyepiece on `ev`. Public so a probe or a neighbour can start it.
func start_watch(ev: Dictionary) -> void:
	_event = ev
	_sight_az = float(ev.get("az_deg", 90.0))
	_sight_el = float(ev.get("elev_deg", 25.0))
	_t = 0.0
	_aim = Vector2.ZERO
	_focus = 0.5
	_hold = 0.0
	_q_sum = 0.0
	_q_time = 0.0
	_lost = 0.0
	_acquired = false
	_acquire_t = 0.0
	_finishing = false
	_fail_reason = ""
	_wob = Vector2.ZERO
	_wob_v = Vector2.ZERO
	_zones.clear()

	# Everything random about a watch is seeded off the event and the day, so a critic re-running
	# the capture gets the same hunt.
	var key := str(ev.get("id", "x")) + "|" + str(day())
	_rng.seed = hash(key)
	_drift_seed = float(absi(hash(key) % 1000)) * 0.017
	# WHERE THE TUBE IS PARKED. The sight stays at the forecast's az / elev; the scope starts this
	# far off it, so the dial on the left and the forecast's words are a real map to sweep by.
	var park := park_for(ev)
	_base_az = park.x
	_base_el = park.y
	# Field offset when the scope is at the park: the sight is (park - sight) degrees away.
	_miss = Vector2(_base_az - _sight_az, _base_el - _sight_el) / FIELD_HALF_DEG
	_plant_scope(ev)
	# The sky turns one way tonight. Mostly sideways, so the scope does not run out of elevation.
	var sa := _rng.randf() * TAU
	_sid = Vector2(cos(sa), sin(sa) * 0.35).normalized()
	# A rarer sight is lower and fainter, so the air moves it more.
	_gust_mag = 1.05 + 0.34 * float(clampi(int(ev.get("rarity", 1)), 1, 3))
	_gust_t = _rng.randf_range(0.8, 2.0)

	_apply_subject(_eye_mat, ev, 0.0, Vector2.ZERO)
	_eye_mat.set_shader_parameter("seed", 1.0 + _drift_seed)
	_set_state(St.WATCH)
	_update_watch(0.0)


## Where the tube is left standing for `ev`: PARK_OFF degrees off the sight, in a direction fixed by
## the event id and the day. Deterministic, so the scope you walk up to is already parked where the
## hunt will start, and a critic re-running the capture gets the same sweep.
static func park_for(ev: Dictionary) -> Vector2:
	var r := RandomNumberGenerator.new()
	r.seed = hash(str(ev.get("id", "x")) + "|" + str(GameState.day_count))
	var a := r.randf() * TAU
	var dist := r.randf_range(PARK_OFF_MIN, PARK_OFF_MAX)
	return Vector2(
		float(ev.get("az_deg", 90.0)) + cos(a) * dist,
		clampf(float(ev.get("elev_deg", 25.0)) + sin(a) * 0.75 * dist, 7.0, 68.0))


func _plant_scope(ev: Dictionary) -> void:
	var pl := _player_node()
	if pl == null:
		return
	var parent := pl.get_parent()
	if parent == null:
		return
	if not is_instance_valid(_scope):
		_scope = Telescope.new()
		_scope.name = "SpikeTelescope"
		parent.add_child(_scope)
	var pos := pl.global_position
	var up := pos.normalized() if pos.length_squared() > 0.001 else Vector3.UP
	var east := Vector3.RIGHT - up * up.dot(Vector3.RIGHT)
	if east.length_squared() < 0.001:
		east = Vector3.FORWARD - up * up.dot(Vector3.FORWARD)
	east = east.normalized()
	# To the player's RIGHT AS THE GAMEPLAY CAMERA SEES IT, so the scope is always in shot and never
	# between the camera and the player's head. Read BEFORE the watch camera takes over.
	var fwd := _cam_forward(up)
	var side := fwd.cross(up).normalized() if fwd != Vector3.ZERO else up.cross(east).normalized()
	# DROP IT ONTO THE GROUND. The planet is displaced terrain, not a smooth radius-16 ball, so a
	# pure tangent offset from the player's feet buried the whole scope in a hillside and left two
	# leg tips showing (first capture round, 2026-09-20). Raycast instead.
	var spot := _ground_under(pos + side * 1.5, up)
	_scope.scale = Vector3.ONE * 1.3
	_scope.plant(spot, up, east, _base_az, _base_el)


## Where the ground is under `p`, found by dropping a ray along -up. Falls back to `p` itself when
## nothing is hit (no collider, a showcase with no physics).
func _ground_under(p: Vector3, up: Vector3) -> Vector3:
	var space := get_viewport().world_3d.direct_space_state
	if space == null:
		return p
	var q := PhysicsRayQueryParameters3D.create(p + up * 3.0, p - up * 3.0)
	q.collide_with_areas = false
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		return p
	return hit["position"] as Vector3


## Flat direction the gameplay camera is facing, in the local tangent plane.
func _cam_forward(up: Vector3) -> Vector3:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return Vector3.ZERO
	var f := -cam.global_transform.basis.z
	f = f - up * up.dot(f)
	return f.normalized() if f.length_squared() > 0.0001 else Vector3.ZERO


# ------------------------------------------------------------- what moves the sight
## Where the sight sits relative to the scope's ORIGINAL aim, in field radii, at time `t`. The
## wobble is stateful (a kicked spring) so it is not in here; see `_step_wobble`.
func _drift(t: float) -> Vector2:
	var s := _drift_seed
	var seeing := Vector2(
		0.20 * sin(t * 0.61 + s) + 0.11 * sin(t * 1.13 + s * 2.1),
		0.15 * sin(t * 0.47 + s * 1.7) + 0.09 * sin(t * 0.89 + s * 0.6))
	return _miss + _sid * (SIDEREAL * t) + seeing


## Gusts and breath. A gust is an impulse on a spring-damper: it snaps the sight off centre and then
## settles over about a second. Breath never stops.
func _step_wobble(delta: float) -> void:
	_gust_t -= delta
	if _gust_t <= 0.0:
		_gust_t = _rng.randf_range(GUST_GAP_MIN, GUST_GAP_MAX)
		var a := _rng.randf() * TAU
		_wob_v += Vector2(cos(a), sin(a)) * _gust_mag * _rng.randf_range(0.7, 1.3)
	_wob_v += (-_wob * GUST_STIFF - _wob_v * GUST_DAMP) * delta
	_wob += _wob_v * delta


func _breath(t: float) -> Vector2:
	return Vector2(0.030 * sin(t * 1.9 + _drift_seed), 0.022 * sin(t * 1.37 + _drift_seed * 2.0))


func _focus_target(t: float) -> float:
	# The tube cools all night, so the sharp point WALKS. Slow and small: you re-touch the knob
	# every eight seconds or so, you do not chase it.
	var s := _drift_seed
	return clampf(0.5 + 0.22 * sin(t * 0.16 + s) + 0.07 * sin(t * 0.51 + s * 1.7), 0.02, 0.98)


## az 0 is local east and az grows toward north, so this is the 45-degree sector the tube is in.
static func compass(az: float) -> String:
	const PTS := ["E", "NE", "N", "NW", "W", "SW", "S", "SE"]
	return PTS[int(round(fposmod(az, 360.0) / 45.0)) % 8]


static func height_word(el: float) -> String:
	if el < 14.0:
		return "low"
	if el < 34.0:
		return "half-way up"
	return "high"


func _expo_frac() -> float:
	return clampf(_hold / EXPOSURE_NEED, 0.0, 1.0)


func _time_left() -> float:
	return maxf(WINDOW_SEC - _t, 0.0)


func _process(delta: float) -> void:
	if _state == St.IDLE:
		_clock_lbl.text = "%s   day %d   %s" % [
			SkyEvents.clock_text(hour()), day(), _sky_note()]
		# The telescope is a thing standing on your planet, not a menu that appears. Plant it as
		# soon as there is something up, parked where the hunt will start.
		if not is_instance_valid(_scope):
			var up_ev := current_event()
			if not up_ev.is_empty():
				var pk := park_for(up_ev)
				_base_az = pk.x
				_base_el = pk.y
				_plant_scope(up_ev)
	elif _state == St.WAITING:
		_tick_wait()
	elif _state == St.WATCH:
		_read_keys(delta)
		_update_watch(delta)


func _sky_note() -> String:
	var ev := current_event()
	if ev.is_empty():
		return SkyEvents.plan_line(day(), hour(), GameState.current_planet_id)
	if SkyEvents.can_print_here(ev, GameState.current_planet_id):
		return "UP NOW: %s" % str(ev["title"])
	return "%s · %s" % [str(ev["title"]), SkyEvents.short_here(ev, GameState.current_planet_id)]


func _read_keys(delta: float) -> void:
	# Desktop fallback so the spike is playable without a touch screen.
	var a := Vector2.ZERO
	if Input.is_key_pressed(KEY_LEFT):
		a.x -= 1.0
	if Input.is_key_pressed(KEY_RIGHT):
		a.x += 1.0
	if Input.is_key_pressed(KEY_UP):
		a.y -= 1.0
	if Input.is_key_pressed(KEY_DOWN):
		a.y += 1.0
	if a != Vector2.ZERO:
		_aim = (_aim + a * delta * 1.30).limit_length(AIM_CLAMP)
	var f := 0.0
	if Input.is_key_pressed(KEY_Q):
		f -= 1.0
	if Input.is_key_pressed(KEY_E):
		f += 1.0
	if f != 0.0:
		_focus = clampf(_focus + f * delta * 0.42, 0.0, 1.0)


func _update_watch(delta: float) -> void:
	_t += delta
	_layout_eye()
	_step_wobble(delta)
	_sight = _drift(_t) + _wob + _breath(_t) - _aim
	_focus_opt = _focus_target(_t)

	# The real scope turns with you. This is the whole reason the world stays on screen.
	if is_instance_valid(_scope):
		_scope.swing(_base_az - _aim.x * FIELD_HALF_DEG, _base_el - _aim.y * FIELD_HALF_DEG)

	var err_pos := _sight.length()
	_centred = clampf(1.0 - (err_pos - CENTRE_R) / (EDGE_R - CENTRE_R), 0.0, 1.0)
	_sharp = clampf(1.0 - absf(_focus - _focus_opt) / FOCUS_TOL, 0.0, 1.0)
	_q = _centred * _sharp

	if not _acquired and err_pos < 0.85:
		_acquired = true
		_acquire_t = _t

	if _acquired:
		# Averaged over EVERY second after you first found it, not only the good ones. A watcher who
		# keeps losing it is measured losing it.
		_q_sum += _q * delta
		_q_time += delta

	if _q >= Q_FLOOR:
		_hold += delta * _q
		_lost = maxf(0.0, _lost - delta * RECOVER_RATE)
	elif _acquired:
		# You can only LOSE something you have found. Before that the window is the only pressure -
		# the first build fogged the plate three seconds into the hunt, which was nonsense.
		# Out of the field entirely costs twice as fast as merely soft or off-centre.
		_lost += delta * (2.0 if err_pos > 1.0 else 1.0)
		_hold = maxf(0.0, _hold - delta * 0.30)

	_eye_mat.set_shader_parameter("t", _t)
	_eye_mat.set_shader_parameter("s0_pos", _sight)
	_eye_mat.set_shader_parameter("s0_blur", clampf(1.0 - _sharp, 0.0, 1.0))
	_eye_mat.set_shader_parameter("warm", clampf(_sharp, 0.0, 1.0))
	_eye_mat.set_shader_parameter("sky_light", _sky_light())
	_layout_buttons()
	_overlay.queue_redraw()

	if _finishing:
		return
	if _hold >= EXPOSURE_NEED:
		_finishing = true
		_finish_watch()
	elif _lost >= SPOIL_SEC:
		_finishing = true
		_fail("You lost it. The plate fogged.")
	elif _t >= WINDOW_SEC:
		if _expo_frac() >= MIN_TAKE:
			_finishing = true
			_finish_watch()
		else:
			_finishing = true
			_fail("It drifted out of reach.")


## How much daylight is leaking into the field. 0 in the dead of night; at dawn the sky lifts a
## little and the stars drop to STAR_DAY_SCALE, which is R2.1 - the stars never actually go out.
func _sky_light() -> float:
	return clampf(1.0 - _night_factor(), 0.0, 1.0)


func _layout_eye() -> void:
	var vs := _root.size
	# 62% of the screen HEIGHT, capped on width so an ultra-wide phone frame does not fill up. The
	# rest of the screen is the player's own planet, which is the point.
	var d: float = minf(vs.y * 0.545, vs.x * 0.38)
	_eye.size = Vector2(d, d)
	_eye.position = Vector2(vs.x * eye_cx - d * 0.5, vs.y * 0.360 - d * 0.5)


func _layout_buttons() -> void:
	var vs := _root.size
	var er := eye_rect()
	var takeable := _expo_frac() >= MIN_TAKE and not _finishing
	_shutter.visible = takeable
	_shutter.text = "Close the shutter  (%d%%)" % int(round(_expo_frac() * 100.0))
	_shutter.size = Vector2(330.0, 62.0)
	_shutter.position = Vector2(er.position.x + er.size.x * 0.5 - 165.0,
		minf(er.position.y + er.size.y + 18.0, vs.y - 80.0))
	_giveup.size = Vector2(150.0, 54.0)
	_giveup.position = Vector2(vs.x - 150.0 - 28.0, 22.0)


func eye_rect() -> Rect2:
	return Rect2(_eye.position, _eye.size)


## The focus slider's screen rectangle (right edge). Public so the overlay draws exactly the strip
## the input code tests against - one source of truth, no second constant to drift.
func focus_rect() -> Rect2:
	var vs := _root.size
	var w: float = clampf(vs.x * 0.055, 86.0, 150.0)
	var h: float = vs.y * 0.56
	return Rect2(vs.x - w - 40.0, (vs.y - h) * 0.5 + 24.0, w, h)


# ------------------------------------------------------------------ finishing
func _fail(reason: String) -> void:
	_fail_reason = reason
	print("SKYWATCH ruined: %s | %s  t=%.1fs expo=%d%% meanq=%.2f" % [
		str(_event.get("title", "")), reason, _t, int(round(_expo_frac() * 100.0)), _mean_q()])
	watch_failed.emit(str(_event.get("id", "")), reason)
	_fill_ruined_card(reason)
	_set_state(St.RUINED)


func _mean_q() -> float:
	return _q_sum / maxf(_q_time, 0.0001)


func _finish_watch() -> void:
	var mean := _mean_q()
	var frac := _expo_frac()
	# A plate pulled early is grainier. One rule, applied once, no second knob anywhere.
	var held := mean * (SHORT_FLOOR + (1.0 - SHORT_FLOOR) * frac)
	var on_world := str(_event.get("world", "")) == GameState.current_planet_id
	var p := SkyPrint.make(_event, held, on_world, day(), hour(), frac, _t)
	p.preview = await _render_preview(_event, p.sharpness, frac)
	prints.append(p)
	var jr := _record(p)
	print("SKYWATCH print: %s (on_world=%s meanq=%.2f t=%.1fs)" % [p.summary(), str(on_world), mean, _t])
	print_made.emit(p)
	_fill_card(p, jr)
	_set_state(St.PRINT)


## THE JOURNAL SEAM. Anything with `record(p: SkyPrint) -> Dictionary` can be hung on `journal`, or
## put at /root/SkyJournal as an autoload. The dictionary it hands back is shown on the print card;
## every key is optional:
##   "is_best": bool     this beat your best shot of this sight
##   "best": float       0..1, the sharpness now stored for this sight
##   "seen": int         how many different sights the journal holds
##   "total": int        how many sights there are to find
##   "line": String      one line under 60 chars to print instead of the built-in one
func _record(p: SkyPrint) -> Dictionary:
	if journal == null or not is_instance_valid(journal):
		var n := get_node_or_null("/root/SkyJournal")
		if n != null:
			journal = n
	if journal != null and is_instance_valid(journal) and journal.has_method("record"):
		var r: Variant = journal.call("record", p)
		if r is Dictionary:
			return r
	return {}


## THE TUBE. Everything about the flight's glass that a standing scope is not, turned off once:
## no lane shear, no ship heading, no two worlds in the field, and the cockpit's rounded window
## collapsed to a circle (corner 1.0) or to the print's rounded square (corner 0.22).
##
## WHAT IS HONESTLY DIFFERENT AND NOT TURNED OFF: the dust flecks. `flow_from` is parked far
## outside the field so the flow takes its flat branch, and `run` is 0, so they do not move - they
## read as fine dust in the tube rather than as a lane whipping past. It is a real, small visual
## import from the flight's glass, and it is here rather than hidden in a diff.
func _tube_uniforms(m: ShaderMaterial, corner: float) -> void:
	m.set_shader_parameter("aspect", 1.0)
	m.set_shader_parameter("corner", corner)
	m.set_shader_parameter("field_deg", FIELD_HALF_DEG)
	m.set_shader_parameter("field_half", deg_to_rad(FIELD_HALF_DEG))
	m.set_shader_parameter("look", Vector2.ZERO)
	m.set_shader_parameter("run", 0.0)
	m.set_shader_parameter("swim", 0.0)
	m.set_shader_parameter("flash", 0.0)
	m.set_shader_parameter("warm", 0.0)
	# THE DUST, ALMOST ALL OF IT GONE, WITHOUT TOUCHING THE SHADER. The flight's glass streams dust
	# out of the ship's heading; a tripod is not moving and must not. `run` 0 already freezes it,
	# but the flecks were still there, and TWO OBVIOUSLY-WRONG PICTURES were measured before this
	# value (both captured, both in this round's frames):
	#   flow_from far away  -> the FLAT branch, rate 1.0 across the whole field: diagonal dashes
	#                          everywhere, like drizzle down the tube.
	#   flow_from at zero   -> the POLAR branch degenerate: a radial starburst blooming out of the
	#                          middle of the field. A warp-speed effect on a standing telescope.
	# Just inside the polar threshold (|flow_from| 3.68 < 3.6..5.0) keeps the polar branch AND puts
	# its vanishing point outside the glass, where its cells - polar in (angle, log radius) - are
	# enormous in field space: about six of them touch the field at all, so what is left is a few
	# specks at the rim. Arithmetic off the shader's own parametrisation, not a tuned gain.
	m.set_shader_parameter("flow_from", Vector2(2.6, 2.6))
	m.set_shader_parameter("dest_pos", Vector2(40.0, 40.0))
	m.set_shader_parameter("dest_r", 0.0)
	m.set_shader_parameter("home_pos", Vector2(40.0, 40.0))
	m.set_shader_parameter("home_r", 0.0)
	m.set_shader_parameter("n_subj", 1)
	m.set_shader_parameter("s1_pos", Vector2(9.0, 9.0))
	m.set_shader_parameter("s2_pos", Vector2(9.0, 9.0))


## ONE SUBJECT IN SLOT 0, drawn the way the catalog says it is drawn. `SafariShapes.apply` is the
## same call `safari_run.gd` makes for a sight in the glass, so a lantern-fish at the tripod and a
## lantern-fish out of the porthole are the same picture.
##
## THE MOMENT IS 0.0 AND THAT IS NOT AN OVERSIGHT. A moment is something a sight is caught DOING
## as it goes past the ship; a tripod print has never had one (sky_print.gd's `moment` is "" for
## every one of them). The shape stays closed.
func _apply_subject(m: ShaderMaterial, ev: Dictionary, blur: float, pos: Vector2) -> void:
	m.set_shader_parameter("n_subj", 1)
	var cat := SafariCatalog.by_id(str(ev.get("id", "")))
	if not cat.is_empty():
		SafariShapes.apply(m, 0, cat, pos, blur, 0.0)
	else:
		# Not a catalog sight (a showcase pushing a made-up subject). Bare branch, no knobs.
		m.set_shader_parameter("s0_kind", int(ev.get("kind", 0)))
		m.set_shader_parameter("s0_pos", pos)
		m.set_shader_parameter("s0_blur", blur)
		m.set_shader_parameter("s0_scale", float(ev.get("scale", 1.0)))
		m.set_shader_parameter("s0_moment", 0.0)
		m.set_shader_parameter("s0_seed", 1.0 + _drift_seed)
		m.set_shader_parameter("s0_a", Color(str(ev.get("tint_a", "#ffffff"))))
		m.set_shader_parameter("s0_b", Color(str(ev.get("tint_b", "#ffffff"))))
	m.set_shader_parameter("s1_pos", Vector2(9.0, 9.0))
	m.set_shader_parameter("s2_pos", Vector2(9.0, 9.0))


## Renders the print with the REAL eyepiece shader at the sharpness actually held, so a soft print
## looks soft and a short exposure looks grainy. 256x256 offscreen, one frame, mode 1 (a photograph:
## no tube rim and no round hole).
func _render_preview(ev: Dictionary, sharp: float, frac: float) -> Image:
	# HEADLESS HAS NO RENDERER. `get_texture().get_image()` on a dummy driver returns nothing and
	# the frame_post_draw await NEVER ARRIVES - which meant `_finish_watch` hung forever and a
	# headless watch produced no print, no signal and no journal page at all. safari_haul.gd has
	# carried this guard since the wire round; the tripod did not, and the first headless run of
	# this round's probe is what found it. SAY WHAT IS SYNTHETIC: a headless print has a null
	# preview and its page falls back to the silhouette art; the pictures need a windowed run.
	if DisplayServer.get_name() == "headless":
		return null
	var m: ShaderMaterial = _prev_rect.material
	_apply_subject(m, ev, clampf(1.0 - sharp, 0.0, 1.0) * 0.75, Vector2.ZERO)
	m.set_shader_parameter("seed", 1.0 + _drift_seed)
	m.set_shader_parameter("t", _t)
	# A short exposure used to get read noise from the old shader's `grain`, which the flight's
	# glass does not have. It gets a DIMMER, softer plate instead - the same thing a half-filled
	# plate really is - so nothing here is a new knob either.
	m.set_shader_parameter("warm", clampf(frac, 0.0, 1.0))
	m.set_shader_parameter("sky_light", _sky_light())
	_prev_vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	return _prev_vp.get_texture().get_image()


func _card_shell() -> VBoxContainer:
	for c in _card.get_children():
		c.queue_free()
	var m := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 26)
	_card.add_child(m)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	m.add_child(col)
	return col


func _fill_card(p: SkyPrint, jr: Dictionary) -> void:
	var col := _card_shell()
	col.add_child(_head("%s print  ·  %s" % [p.grade, p.sharpness_text()]))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	col.add_child(row)
	row.add_child(_thumb(p, 224))
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 4)
	info.custom_minimum_size = Vector2(430, 0)
	row.add_child(info)
	info.add_child(_body(p.title))
	info.add_child(_small("Sharpness %s   ·   exposure %d%%   ·   %.0f s at the eyepiece" % [
		p.sharpness_text(), int(round(p.exposure * 100.0)), p.seconds]))
	info.add_child(_small("Rarity %d (%s) - that is what a copy is worth." % [
		p.rarity, SkyEvents.rarity_name(p.rarity)]))
	# THE JOURNAL LINE. Sharpness is the prize, so this is the line that should land.
	if jr.has("line"):
		info.add_child(_body(str(jr["line"])))
	elif jr.has("is_best"):
		if bool(jr["is_best"]):
			info.add_child(_body("Your best shot of this sight. Journal updated."))
		else:
			info.add_child(_small("Your best of this sight is still %d%%." % int(round(
				float(jr.get("best", 0.0)) * 100.0))))
	else:
		info.add_child(_small("The journal keeps your best shot of each sight."))
	if not p.on_world:
		info.add_child(_small("Capped at %d%%: you were not on %s." % [
			int(round(SkyPrint.OFF_WORLD_CAP * 100.0)), p.world.capitalize()]))
	info.add_child(_small("Gloop sells COPIES. The print stays yours."))
	var foot := HBoxContainer.new()
	foot.alignment = BoxContainer.ALIGNMENT_END
	foot.add_theme_constant_override("separation", 12)
	col.add_child(foot)
	foot.add_child(_mk_button("Keep it", _on_close))


func _fill_ruined_card(reason: String) -> void:
	var col := _card_shell()
	col.add_child(_head("Plate ruined"))
	col.add_child(_body(reason))
	col.add_child(_small("%s  ·  %.0f s at the eyepiece  ·  plate %d%% full" % [
		str(_event.get("title", "")), _t, int(round(_expo_frac() * 100.0))]))
	if not _acquired:
		col.add_child(_small("You never found it. It was %s." % str(_event.get("where", ""))))
	else:
		col.add_child(_small("Nothing to keep. The sight is still up - try again."))
	var foot := HBoxContainer.new()
	foot.alignment = BoxContainer.ALIGNMENT_END
	foot.add_theme_constant_override("separation", 12)
	col.add_child(foot)
	var ev := _event
	if SkyEvents.in_window(ev, hour()):
		foot.add_child(_mk_button("Try again", func(): start_watch(ev)))
	foot.add_child(_mk_button("Stand up", _on_close))


# ------------------------------------------------------------------ input
func _on_eye_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_touch_seen = true
		var t := event as InputEventScreenTouch
		if t.pressed:
			_press(t.index, t.position)
		else:
			_zones.erase(t.index)
		_eye_root.accept_event()
	elif event is InputEventScreenDrag:
		_touch_seen = true
		var d := event as InputEventScreenDrag
		_move(d.index, d.position, d.relative)
		_eye_root.accept_event()
	elif not _touch_seen and event is InputEventMouseButton:
		var b := event as InputEventMouseButton
		if b.button_index == MOUSE_BUTTON_LEFT:
			if b.pressed:
				_press(-1, b.position)
			else:
				_zones.erase(-1)
			_eye_root.accept_event()
	elif not _touch_seen and event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if _zones.has(-1):
			_move(-1, mm.position, mm.relative)
			_eye_root.accept_event()


func _press(index: int, pos: Vector2) -> void:
	if focus_rect().has_point(pos):
		_zones[index] = "focus"
		_set_focus_from(pos)
	else:
		_zones[index] = "aim"


func _move(index: int, pos: Vector2, rel: Vector2) -> void:
	var zone: String = str(_zones.get(index, ""))
	if zone == "":
		_press(index, pos)
		zone = str(_zones.get(index, "aim"))
	if zone == "focus":
		_set_focus_from(pos)
	else:
		var r: float = maxf(_eye.size.x * 0.5, 1.0)
		_aim = (_aim - rel / r * AIM_GAIN).limit_length(AIM_CLAMP)


func _set_focus_from(pos: Vector2) -> void:
	var fr := focus_rect()
	_focus = clampf(1.0 - (pos.y - fr.position.y) / maxf(fr.size.y, 1.0), 0.0, 1.0)


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.is_pressed() or event.is_echo():
		return
	var k := (event as InputEventKey).keycode
	if _state == St.IDLE:
		if k == KEY_1:
			_on_forecast()
		elif k == KEY_2:
			_on_setup()
		elif k == KEY_3:
			_on_prints()
	elif _state == St.WATCH and k == KEY_SPACE:
		_on_shutter()
	elif k == KEY_ESCAPE:
		if _state == St.WAITING:
			_end_wait(false)
		else:
			_set_state(St.IDLE)


# ------------------------------------------------------------------ synthetic hooks (captures)
# These push the same numbers a finger would, through the same fields. They do NOT go through real
# input, so nothing here proves a real finger works (CLAUDE.md, "Say what is synthesised").
func debug_open(index: int) -> void:
	var f := forecast()
	var ev: Dictionary = f[clampi(index, 0, f.size() - 1)]
	var e := _env_node()
	if e != null and e.has_method("set_time"):
		var a := float(ev["hour_start"])
		var b := float(ev["hour_end"])
		var mid := a + fposmod(b - a, 24.0) * 0.6
		e.call("set_time", fposmod(mid, 24.0))
	start_watch(ev)


func debug_aim(x: float, y: float) -> void:
	_aim = Vector2(x, y).limit_length(AIM_CLAMP)


func debug_focus(v: float) -> void:
	_focus = clampf(v, 0.0, 1.0)


## Snaps the scope onto the sight and the knob onto the optimum - the "perfect hold" a capture of
## the sight itself needs. Synthetic.
func debug_lock() -> void:
	_aim = (_aim + _sight).limit_length(AIM_CLAMP)
	_focus = _focus_target(_t)
	_update_watch(0.0)


## Puts the sight exactly `dx, dy` field radii off centre and the knob exactly `ferr` from the
## optimum, whatever the drift and the gusts happen to be doing. Synthetic, for repeatable captures.
func debug_offset(dx: float, dy: float, ferr: float) -> void:
	_aim = (_aim + _sight - Vector2(dx, dy)).limit_length(AIM_CLAMP)
	_focus = clampf(_focus_target(_t) + ferr, 0.0, 1.0)
	_update_watch(0.0)


func debug_show_forecast() -> void:
	_on_forecast()


func debug_show_prints() -> void:
	_on_prints()


func debug_finish() -> void:
	if _state != St.WATCH or _finishing:
		return
	_finishing = true
	_q_sum = maxf(_q_sum, _q * 0.5)
	_q_time = maxf(_q_time, 0.5)
	_hold = maxf(_hold, EXPOSURE_NEED * MIN_TAKE)
	_finish_watch()


func debug_hold(frac: float) -> void:
	_hold = clampf(frac, 0.0, 1.0) * EXPOSURE_NEED


func debug_spoil() -> void:
	_lost = SPOIL_SEC


func debug_push_touch(x: float, y: float, pressed: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = 0
	e.position = get_viewport().get_screen_transform() * Vector2(x, y)
	e.pressed = pressed
	Input.parse_input_event(e)


func debug_push_drag(x: float, y: float, dx: float, dy: float) -> void:
	var e := InputEventScreenDrag.new()
	e.index = 0
	var xf := get_viewport().get_screen_transform()
	e.position = xf * Vector2(x, y)
	e.relative = xf.basis_xform(Vector2(dx, dy))
	Input.parse_input_event(e)


func debug_push_touch2(x: float, y: float, pressed: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = 1
	e.position = get_viewport().get_screen_transform() * Vector2(x, y)
	e.pressed = pressed
	Input.parse_input_event(e)


func debug_push_drag2(x: float, y: float, dx: float, dy: float) -> void:
	var e := InputEventScreenDrag.new()
	e.index = 1
	var xf := get_viewport().get_screen_transform()
	e.position = xf * Vector2(x, y)
	e.relative = xf.basis_xform(Vector2(dx, dy))
	Input.parse_input_event(e)


func debug_report(tag: String) -> void:
	print("SKYWATCH %s: t=%.1f state=%d acq=%s sight=(%.2f,%.2f) |s|=%.2f aim=(%.2f,%.2f) focus=%.2f opt=%.2f sharp=%.2f centred=%.2f q=%.2f expo=%d%% lost=%.1f az=%.1f el=%.1f" % [
		tag, _t, _state, str(_acquired), _sight.x, _sight.y, _sight.length(), _aim.x, _aim.y,
		_focus, _focus_opt, _sharp, _centred, _q, int(round(_expo_frac() * 100.0)), _lost,
		_base_az - _aim.x * FIELD_HALF_DEG, _base_el - _aim.y * FIELD_HALF_DEG])


func debug_rects() -> void:
	print("SKYWATCH rects: eye=%s focus=%s shutter=%s" % [
		str(eye_rect()), str(focus_rect()), str(Rect2(_shutter.position, _shutter.size))])


func debug_wait(index: int) -> void:
	var f := forecast()
	_start_wait(f[clampi(index, 0, f.size() - 1)])


func debug_close() -> void:
	_set_state(St.IDLE)


func debug_state() -> int:
	return _state


func debug_sight_len() -> float:
	return _sight.length()


func debug_miss() -> Vector2:
	return _miss


## Open the Nth forecast sight WITHOUT moving the clock, so a capture can see what the eyepiece
## looks like at the hour the run is actually at.
func start_watch_index(i: int) -> void:
	var f := forecast()
	start_watch(f[clampi(i, 0, f.size() - 1)])


# ------------------------------------------------------------------ the eyepiece overlay
## The tube's barrel, the reticle, the exposure and window arcs, the focus knob and the hunt cues.
class Overlay extends Control:
	var watch: SkyWatch

	func _draw() -> void:
		if watch == null:
			return
		var font: Font = UIStyle.ui_font()
		var er := watch.eye_rect()
		var c := er.position + er.size * 0.5
		var R := er.size.x * 0.5
		var ok: bool = watch._centred > 0.999
		var frac: float = watch._expo_frac()
		var lost_frac: float = clampf(watch._lost / SkyWatch.SPOIL_SEC, 0.0, 1.0)
		var left: float = watch._time_left()

		# THE BARREL. A thick dark annulus fading outward, so the round view reads as the end of a
		# tube instead of a decal floating over the planet. Drawn as rings, not a shader, because it
		# has to sit over the 3D world and under the text.
		for i in 14:
			var f := float(i) / 13.0
			var rad: float = R * (1.005 + f * 0.30)
			var a: float = 0.80 * (1.0 - f) * (1.0 - f)
			draw_arc(c, rad, 0.0, TAU, 96, Color(0.020, 0.026, 0.050, a), R * 0.030, true)
		draw_arc(c, R * 1.012, 0.0, TAU, 96, Color(0.52, 0.56, 0.72, 0.60), 3.0, true)

		# RETICLE: four corner ticks and a faint ring, so it never sits on top of the sight.
		var rr: float = R * SkyWatch.CENTRE_R
		var rcol: Color = SkyWatch.C_GOOD if ok else Color(0.85, 0.87, 0.95, 0.30)
		draw_arc(c, rr, 0.0, TAU, 48, Color(rcol.r, rcol.g, rcol.b, 0.5 if ok else 0.22), 2.0, true)
		var arm: float = rr * 0.42
		for i in 4:
			var a2: float = PI * 0.25 + TAU * float(i) / 4.0
			var d := Vector2(cos(a2), sin(a2))
			var t1 := Vector2(-d.y, d.x)
			var corner: Vector2 = c + d * rr * 1.06
			draw_line(corner, corner - d * arm * 0.55 + t1 * arm * 0.5, rcol, 3.0, true)
			draw_line(corner, corner - d * arm * 0.55 - t1 * arm * 0.5, rcol, 3.0, true)

		# EXPOSURE ARC, clockwise from the top: how full the plate is.
		var mcol: Color = SkyWatch.C_GOOD if watch._q >= SkyWatch.Q_FLOOR else SkyWatch.C_WARN
		draw_arc(c, R * 1.10, -PI * 0.5, -PI * 0.5 + TAU, 96, Color(1, 1, 1, 0.10), 10.0, true)
		if frac > 0.002:
			draw_arc(c, R * 1.10, -PI * 0.5, -PI * 0.5 + TAU * frac, 96, mcol, 10.0, true)
		# the mark you may pull the plate from
		var ma: float = -PI * 0.5 + TAU * SkyWatch.MIN_TAKE
		draw_line(c + Vector2(cos(ma), sin(ma)) * R * 1.055,
			c + Vector2(cos(ma), sin(ma)) * R * 1.145, Color(1, 1, 1, 0.55), 3.0, true)

		# WINDOW ARC, thinner and outside it: how much sky is left. Anticlockwise, so it visibly
		# closes toward the exposure arc.
		var wf: float = clampf(left / SkyWatch.WINDOW_SEC, 0.0, 1.0)
		var wcol: Color = SkyWatch.C_BAD if left < SkyWatch.WARN_SEC else Color(0.62, 0.68, 0.86, 0.75)
		draw_arc(c, R * 1.17, -PI * 0.5, -PI * 0.5 - TAU * wf, 96, wcol, 5.0, true)

		# LOSING IT: a red arc creeping round the inside of the tube.
		if lost_frac > 0.01:
			draw_arc(c, R * 0.965, -PI * 0.5, -PI * 0.5 + TAU * lost_frac, 96,
				Color(SkyWatch.C_BAD.r, SkyWatch.C_BAD.g, SkyWatch.C_BAD.b, 0.85), 7.0, true)

		# HUNT CUE. No arrow until you are close: the forecast's words and the scope's own dial are
		# what you hunt with. Inside 1.8 radii a coarse chevron appears on the rim.
		var slen: float = watch._sight.length()
		if slen > 0.95:
			if slen < 1.8:
				var dir: Vector2 = watch._sight.normalized()
				var tip: Vector2 = c + dir * R * 0.90
				var pr: Vector2 = Vector2(-dir.y, dir.x) * R * 0.055
				draw_line(tip - dir * R * 0.085 + pr, tip, SkyWatch.C_DUST, 4.0, true)
				draw_line(tip - dir * R * 0.085 - pr, tip, SkyWatch.C_DUST, 4.0, true)
			draw_string(font, Vector2(er.position.x, er.position.y + er.size.y * 0.5 - 8.0),
				"NOTHING IN THE FIELD", HORIZONTAL_ALIGNMENT_CENTER, er.size.x, 24,
				Color(0.86, 0.88, 0.96, 0.75))

		# ---- left margin: what you are looking at, and how well
		var lw: float = maxf(er.position.x - 60.0, 240.0)
		var lx := 36.0
		var ly: float = maxf(er.position.y + 6.0, 30.0)
		draw_string(font, Vector2(lx, ly), str(watch._event.get("title", "")),
			HORIZONTAL_ALIGNMENT_LEFT, lw, 26, SkyWatch.C_CREAM)
		draw_string(font, Vector2(lx, ly + 28.0), "%s  ·  %s  ·  %s" % [
				SkyEvents.kind_label(watch._event),
				SkyEvents.rarity_name(int(watch._event.get("rarity", 1))),
				str(watch._event.get("where", ""))],
			HORIZONTAL_ALIGNMENT_LEFT, lw, 18, SkyWatch.C_SOFT.lightened(0.30))
		# THE DIAL. Where the tube is actually pointing, in the words the forecast uses, so sweeping
		# to "high in the north" is something you can do on purpose instead of by luck.
		var daz: float = watch._base_az - watch._aim.x * SkyWatch.FIELD_HALF_DEG
		var del: float = watch._base_el - watch._aim.y * SkyWatch.FIELD_HALF_DEG
		draw_string(font, Vector2(lx, ly + 54.0), "SCOPE  %s %d°  ·  %s %d°" % [
				SkyWatch.compass(daz), int(round(daz)),
				SkyWatch.height_word(del), int(round(del))],
			HORIZONTAL_ALIGNMENT_LEFT, lw, 19, SkyWatch.C_DUST)

		var scol: Color = SkyWatch.C_GOOD if watch._sharp > 0.85 else (
			SkyWatch.C_WARN if watch._sharp > 0.35 else SkyWatch.C_BAD)
		var mw: float = minf(lw, 300.0)
		draw_string(font, Vector2(lx, ly + 96.0), "SHARPNESS  %d%%" % int(round(watch._sharp * 100.0)),
			HORIZONTAL_ALIGNMENT_LEFT, lw, 23, scol)
		_meter(Rect2(lx, ly + 108.0, mw, 12.0), watch._sharp, scol)
		draw_string(font, Vector2(lx, ly + 150.0), "CENTRED" if ok else "OFF CENTRE",
			HORIZONTAL_ALIGNMENT_LEFT, lw, 23, SkyWatch.C_GOOD if ok else SkyWatch.C_WARN)
		_meter(Rect2(lx, ly + 162.0, mw, 12.0), watch._centred,
			SkyWatch.C_GOOD if ok else SkyWatch.C_WARN)
		draw_string(font, Vector2(lx, ly + 204.0), "PLATE  %d%%   ·   %ds of sky left" % [
				int(round(frac * 100.0)), int(ceil(left))],
			HORIZONTAL_ALIGNMENT_LEFT, lw, 23, mcol if left > SkyWatch.WARN_SEC else SkyWatch.C_BAD)
		_meter(Rect2(lx, ly + 216.0, mw, 12.0), frac, mcol)

		if lost_frac > 0.25:
			draw_string(font, Vector2(lx, ly + 258.0), "LOSING IT",
				HORIZONTAL_ALIGNMENT_LEFT, lw, 23, SkyWatch.C_BAD)
		elif left < SkyWatch.WARN_SEC:
			draw_string(font, Vector2(lx, ly + 258.0), "The sky is turning.",
				HORIZONTAL_ALIGNMENT_LEFT, lw, 23, SkyWatch.C_BAD)

		# ---- right margin: the focus knob. It shows WHERE THE KNOB IS, never where the
		# optimum is - the picture going soft is the only clue, which is the whole game.
		var fr: Rect2 = watch.focus_rect()
		draw_rect(fr, Color(0.10, 0.12, 0.20, 0.72), true)
		draw_rect(fr, Color(0.55, 0.58, 0.74, 0.7), false, 2.0)
		for i in 9:
			var ty: float = fr.position.y + fr.size.y * float(i) / 8.0
			draw_line(Vector2(fr.position.x + 6.0, ty), Vector2(fr.position.x + 18.0, ty),
				Color(0.62, 0.66, 0.82, 0.45), 2.0)
		var ky: float = fr.position.y + (1.0 - watch._focus) * fr.size.y
		draw_rect(Rect2(fr.position.x - 8.0, ky - 15.0, fr.size.x + 16.0, 30.0), scol, true)
		draw_rect(Rect2(fr.position.x - 8.0, ky - 15.0, fr.size.x + 16.0, 30.0),
			Color(0, 0, 0, 0.35), false, 2.0)
		draw_string(font, Vector2(fr.position.x - 20.0, fr.position.y - 16.0), "FOCUS",
			HORIZONTAL_ALIGNMENT_CENTER, fr.size.x + 40.0, 20, Color(0.85, 0.87, 0.95))

		# ---- bottom hint
		draw_string(font, Vector2(0.0, size.y - 14.0),
			"drag to sweep  ·  slide FOCUS  ·  arrows aim, Q / E focus, Space pulls the plate",
			HORIZONTAL_ALIGNMENT_CENTER, size.x, 18, SkyWatch.C_SOFT.lightened(0.2))

	func _meter(r: Rect2, v: float, col: Color) -> void:
		draw_rect(r, Color(1, 1, 1, 0.10), true)
		draw_rect(Rect2(r.position, Vector2(r.size.x * clampf(v, 0.0, 1.0), r.size.y)), col, true)
