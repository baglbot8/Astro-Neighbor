class_name CaveVisit
extends PlanetSafari
## A VISIT TO THE CAVE (docs/STORY_HOME_SPEC.md 9.3 and 9.4; builder CAVE, reworked by CAVE2 2026-09-28).
##
## The planet safari (planet_safari.gd, read-only for this builder) as a short outing: THREE MINUTES
## (PlanetSafari.DURATION, the safari's own sun-dial shows it), FILM photos, ONE VISIT A DAY (CaveStore),
## no pay, no review, no tips. What it keeps, unchanged and inherited: first-person walking, the Camera /
## Walk / shutter / zoom controls (SafariLayer, here CaveLayer), the focus ring and hold-to-focus, the
## scoring and grades (SafariPhotoScorer, SafariScoring.planet_grade) and the warm-up behind the fade.
##
## FLOW: the entrance (cave_entrance.gd) calls `request_enter`; a second try the same day is refused
## with a kind line. Fade to black, the day is spent (a reload cannot buy a second visit), the cave is
## built (CaveWorld) far below the planet and the player is put at its landing, fade in. Each photo is
## filed at once to the scrapbook's Cave pages (CaveStore: best photo per subject). When the clock runs
## out: "Time to head back up!" and a fade back to the entrance. "Leave" (the corner button) asks once
## and does the same, early. No lantern (9.4): the cave is lit by its own
## glowing crystals (warm brown stone, teal crystals since CAVE3, 9.5).
##
## Subject keys are "cave:<id>". `planet_id` is "cave" while inside, so PhotoMode.planet_id is "cave":
## the home album's camera button (it only shows for "home") and the rest of the HUD step aside.
## GameState.current_planet_id stays "home".

const CAVE_ID := "cave"
const NODE_NAME_CAVE := "CaveVisit"
## About a dozen photos a visit (9.4) - as many as there are pages, so the route decides what you get.
const FILM := 12
const TIME_UP_SEC := 2.6
const REFUSE_LINE := "You've explored the cave today. It'll be waiting for you tomorrow!"

var _new_pages := 0
var _timed_out := false
## THE CAVE'S OWN LOOK (C4 2026-09-28, the user: the cave "reads hazy and milky"). The cave is unshaded
## vertex colour, its light already baked in (cave_world.gd header), so the only right post-process is
## none: an identity. The world's Environment (environment.gd, rewritten every frame for the planet
## surface) ran every cave pixel through ACES (tonemap_white 6), its grade LUT (blacks lifted to
## 0.02-0.05, whites capped at 0.945) and a contrast/saturation adjustment - measured in the cave
## (probe, gl_compatibility, 2556x1179): ACES alone lifted the chamber's mean luma 0.708 -> 0.771 while
## halving its mean saturation 0.063 -> 0.036; the grade/adjustment took it to 0.776 / 0.032. That is
## the grey veil. Fog, glow and depth of field were measured to change nothing down here (the cave's
## materials already skip fog; glow is off on phones). So while the visit runs the view camera gets
## this Environment - linear tonemap at exposure 1, no fog, glow, grade or adjustment - and plain
## camera attributes: what is drawn is exactly the authored sRGB colour. Camera3D.environment
## overrides the WorldEnvironment without touching it, so environment.gd's per-frame writes go on
## landing on the planet's own Environment and nothing has to be undone but the two properties.
var _cam: Camera3D
var _cam_env_prev: Environment
var _cam_attr_prev: CameraAttributes
var _cam_set := false
## U1CAVE (9.29, the user saw a planet tip card - "Follow the arrows to the rocket pad..." - inside the
## cave): no HUD tip cards for the whole visit. The game's one hint channel (HintChannel) is PAUSED, so a
## queued hint neither shows nor ages nor is spent down here and comes when you are back on the planet;
## and the HUD's toast stack is hidden, so any other card sent meanwhile is not drawn over the cave.
var _hint_ch: Node
var _hint_mode_prev := Node.PROCESS_MODE_INHERIT
var _toasts: CanvasItem
var _tips_hidden := false


## The entrance's "Go in". Null when something else already runs (a safari, the cave) or no world.
static func request_enter(tree: SceneTree) -> CaveVisit:
	if PlanetSafari.current != null or tree == null or not GameState.story_done:
		return null
	var w := tree.root.get_node_or_null("World")
	if w == null:
		return null
	if CaveStore.visited_today():
		EventBus.toast_requested.emit(REFUSE_LINE, "star")
		print("[CaveVisit] refused: already visited on day %d" % GameState.day_count)
		return null
	var s := CaveVisit.new()
	s.name = NODE_NAME_CAVE
	w.add_child(s)
	return s


func _ready() -> void:
	PlanetSafari.current = self
	_debug = OS.get_cmdline_user_args().has("--safari-debug")
	world = get_parent()
	planet = world.get_node_or_null("Planet") as Planet
	player = world.get_node_or_null("Player") as Player
	rig = world.get_node_or_null("CameraRig") as CameraRig
	planet_id = CAVE_ID
	layer = CaveLayer.new()
	layer.safari = self
	add_child(layer)
	photo_taken.connect(_on_photo)
	_run()


func _run() -> void:
	while EventBus.is_modal_open() or _dialogue_active():
		await get_tree().process_frame
	if planet == null or player == null or rig == null:
		push_warning("CaveVisit: world pieces missing; no cave.")
		_restored = true
		queue_free()
		return
	tips_on = false
	day = GameState.day_count
	# Spend today's visit NOW, at the start, so a quit or reload mid-visit cannot buy a second one.
	CaveStore.mark_visit()
	if SaveManager.has_method("autosave_allowed") and SaveManager.autosave_allowed():
		SaveManager.save_game()
	is_night = false
	_saved_xform = player.global_transform
	player.set_move_locked(true)
	phase = Phase.FADE_IN
	await layer.fade_to(1.0, FADE_SEC)
	if not is_instance_valid(player):
		return
	_begin_behind_black()
	await _warm_up()
	layer.show_awake_ui(true)
	await layer.fade_to(0.0, FADE_SEC)
	player.set_move_locked(false)
	phase = Phase.AWAKE
	elapsed = 0.0
	layer.banner("Three minutes down here. Which way will you go?", 4.5)
	get_tree().create_timer(5.0).timeout.connect(func() -> void:
		if is_instance_valid(layer) and phase == Phase.AWAKE:
			layer.intro_hint(false))
	_log("cave: in, start=%s" % str(player.global_position))


func _begin_behind_black() -> void:
	PhotoMode.begin(CAVE_ID)
	film_start = FILM
	film_left = FILM
	focus_m = 4.0
	focus_target_m = focus_m
	is_rare_day = false
	var cw := CaveWorld.new()
	cw.name = "Content"
	cw.safari = self
	_content = cw
	add_child(_content)
	_content.build(self)
	_use_cave_look(true)
	_hide_hud_tips(true)
	_place_start()
	rig.reseat_behind_player()
	rig.set_first_person(true)
	_set_start_pitch()
	rig.set_fov_deg(PHOTO_MODE_OFF_FOV)
	player.set_safari_walk(true)
	_make_puff_material()


## On: the view camera draws the cave through the identity look above (before the warm-up, so any
## shader variant it needs compiles behind the black). Off: the camera's own two properties go back.
func _use_cave_look(on: bool) -> void:
	if on:
		_cam = rig.get_view_camera() if is_instance_valid(rig) else null
		if _cam == null or _cam_set:
			return
		_cam_env_prev = _cam.environment
		_cam_attr_prev = _cam.attributes
		var env := Environment.new()
		env.background_mode = Environment.BG_COLOR
		env.background_color = CaveWorld.backstop_colour()
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color.WHITE
		env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
		env.tonemap_exposure = 1.0
		env.fog_enabled = false
		env.volumetric_fog_enabled = false
		env.glow_enabled = false
		env.ssao_enabled = false
		env.adjustment_enabled = false
		var attr := CameraAttributesPractical.new()
		attr.auto_exposure_enabled = false
		attr.exposure_multiplier = 1.0
		attr.dof_blur_far_enabled = false
		attr.dof_blur_near_enabled = false
		_cam.environment = env
		_cam.attributes = attr
		_cam_set = true
	elif _cam_set:
		_cam_set = false
		if is_instance_valid(_cam):
			_cam.environment = _cam_env_prev
			_cam.attributes = _cam_attr_prev


## On: the hint channel paused and the HUD's toast stack hidden (see `_tips_hidden`). Off: both back as
## they were. Safe to call twice either way.
func _hide_hud_tips(on: bool) -> void:
	if on:
		if _tips_hidden:
			return
		_tips_hidden = true
		_hint_ch = HintChannel.get_or_create()
		if is_instance_valid(_hint_ch):
			_hint_mode_prev = _hint_ch.process_mode
			_hint_ch.process_mode = Node.PROCESS_MODE_DISABLED
		var hud := world.get_node_or_null("HUD") if is_instance_valid(world) else null
		_toasts = hud.get("toasts") as CanvasItem if hud != null and "toasts" in hud else null
		if is_instance_valid(_toasts):
			_toasts.visible = false
	elif _tips_hidden:
		_tips_hidden = false
		if is_instance_valid(_hint_ch):
			_hint_ch.process_mode = _hint_mode_prev
		if is_instance_valid(_toasts):
			_toasts.visible = true
		_hint_ch = null
		_toasts = null


## Leaving by any path (the fade back up, the clock, a quit): the planet's look comes back first.
func _restore(teleport: bool) -> void:
	_use_cave_look(false)
	_hide_hud_tips(false)
	super._restore(teleport)


## Photo, focus and sight rays pass through the pool's rim wall: it is there to stop your feet, not
## your lens (cave_world.gd _build_pool_room).
func _exclude() -> Array[RID]:
	var ex := super._exclude()
	var cw := _content as CaveWorld
	if cw != null and is_instance_valid(cw.pool_body):
		ex.append(cw.pool_body.get_rid())
	return ex


## At the cave's landing. Not `Player.dev_teleport`: that snaps to the planet's surface.
func _place_start() -> void:
	var xf: Transform3D = (_content as CaveWorld).start_xform()
	player.global_transform = xf
	player.up = xf.basis.y
	player.up_direction = xf.basis.y
	player.velocity = Vector3.ZERO
	start_dir = planet.dir_of(xf.origin)
	start_fwd = -xf.basis.z


## The safari's frame loop without a schedule; at DURATION, back up to the entrance.
func _process(delta: float) -> void:
	if phase != Phase.AWAKE:
		return
	_max_frame_ms = maxf(_max_frame_ms, delta * 1000.0)
	elapsed += delta
	_mark_woke()
	if _content != null:
		_content.tick(elapsed, delta)
	_update_camera_mode(delta)
	if elapsed >= DURATION:
		_log("cave: time up at t=%.1f photos=%d new_pages=%d" % [elapsed, _photos.size(), _new_pages])
		_timed_out = true
		_go_to_sleep()


func request_end() -> void:
	if phase != Phase.AWAKE or _end_pending:
		return
	_end_pending = true
	holding = false
	layer.cancel_pointers()
	EventBus.ui_modal_opened.emit(END_MODAL)
	get_tree().paused = true
	var confirmed: bool = await layer.show_choice_card("Climb back up to your planet?", "Leave", "Stay")
	if is_inside_tree():
		get_tree().paused = false
	EventBus.ui_modal_closed.emit(END_MODAL)
	_end_pending = false
	if phase != Phase.AWAKE:
		return
	if confirmed:
		_log("cave: leaving at t=%.1f photos=%d new_pages=%d" % [elapsed, _photos.size(), _new_pages])
		_go_to_sleep()


## Out of film: head up now, or keep exploring (the chest and the views are still worth the walk).
func _offer_film_out() -> void:
	if _film_out_offered or phase != Phase.AWAKE or film_left > 0:
		return
	_film_out_offered = true
	while phase == Phase.AWAKE and (capturing or _end_pending):
		await get_tree().process_frame
	if phase != Phase.AWAKE:
		return
	await get_tree().create_timer(0.45).timeout
	if phase != Phase.AWAKE or not is_inside_tree() or get_tree().paused or EventBus.is_modal_open():
		return
	holding = false
	layer.cancel_pointers()
	EventBus.ui_modal_opened.emit(FILM_OUT_MODAL)
	get_tree().paused = true
	var up_now: bool = await layer.show_choice_card("Out of film! Head back up, or keep exploring?",
		"Head up", "Keep exploring")
	if is_inside_tree():
		get_tree().paused = false
	EventBus.ui_modal_closed.emit(FILM_OUT_MODAL)
	if phase == Phase.AWAKE and up_now:
		_log("cave: film out, heading up at t=%.1f" % elapsed)
		_go_to_sleep()


## Leaving: straight to black and back to the entrance. No puffs, no review, nothing to pay. When the
## clock ran out (`_timed_out`), a gentle line first, the view held still a moment.
func _go_to_sleep() -> void:
	holding = false
	if camera_up:
		set_camera_up(false)
	phase = Phase.FADE_OUT
	player.set_move_locked(true)
	if _timed_out:
		layer.banner("Time to head back up! The crystals will be here tomorrow.", TIME_UP_SEC + 1.0)
		await get_tree().create_timer(TIME_UP_SEC).timeout
		if not is_instance_valid(player):
			return
	await layer.fade_to(1.0, FADE_SEC)
	_restore(true)
	layer.show_awake_ui(false)
	await get_tree().process_frame
	await layer.fade_to(0.0, FADE_SEC)
	phase = Phase.DONE
	_log("cave: out, max_frame_ms=%.1f" % _max_frame_ms)
	queue_free()


## Every photo goes straight to its Cave page (the best one is kept) with a short note.
func _on_photo(photo: Dictionary) -> void:
	var res := CaveStore.offer_photo(photo)
	var nm := str(photo.get("subject_name", ""))
	var grade := str(photo.get("grade", ""))
	match res:
		"new":
			_new_pages += 1
			announce("New Cave page: %s! (%s)" % [nm, grade], 2.6)
		"better":
			announce("Better photo: %s! (%s)" % [nm, grade], 2.6)
		"kept":
			announce("Nice! Your Cave page keeps its better one.", 2.2)
	_log("cave photo: %s grade=%s -> %s (filled %d/%d)" % [str(photo.get("subject_key", "")), grade, res,
		CaveStore.filled_count(), CaveStore.ROSTER.size()])


func _log(msg: String) -> void:
	print("[CaveVisit] " + msg)


func content() -> CaveWorld:
	return _content as CaveWorld
