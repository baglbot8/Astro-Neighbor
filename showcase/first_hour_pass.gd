extends Node
## FULL SCRIPTED PASS of the first hour (docs/INTRO_SPEC.md 7; src/campaign/first_hour.gd), in the real
## world scene: a new campaign game standing on the Commons after the radio call, through the
## Professor's first meeting, the three errands, the patch, and the parcel handed to Zorp with his
## project starting afterwards. A test harness, not gameplay. Inert unless `--fh-mode=pass` is given
## (tools/check.sh runs every showcase scene; it does nothing there).
##
##   # headless logic pass (one Godot, about 40 s)
##   godot --headless --path <copy> --quit-after 6000 res://showcase/first_hour_pass.tscn -- --fh-mode=pass
##   # windowed, with frames of the picker, Pop's bit, the fitting and Zorp's delivery
##   godot --path <copy> --rendering-method gl_compatibility --resolution 1280x720 --always-on-top \
##     --position 100,100 --max-fps 30 --quit-after 9000 res://showcase/first_hour_pass.tscn -- \
##     --fh-mode=pass --fh-out=/abs/dir [--ui=mobile] [--fh-task-open]
##
## `--fh-task-open` opens the Professor's photo task before the pass, the state an older build's radio
## call leaves (B2 removes that call); the pass must behave the same.
##
## SYNTHESISED, DISCLOSED: walking is replaced by `Player.dev_teleport` next to each target (the same safe
## surface snap a spawn uses); talks and pickups are started with an `interact` InputEventAction through
## Input.parse_input_event (a real InputEvent through the input pipeline, no hardware, no finger);
## dialogue boxes are advanced with DialogueBox.debug_tap (the Director's tap hook); the flight to Zorp is
## SceneRouter.go_to_planet (no rocket cutscene). Play time is ESTIMATED from the measured surface
## distances of each leg at the player's run speed plus a reading time per box, not timed by a person.

const READ_S_PER_BOX := 3.0
const TAP_S := 0.12
const SAVE_STATE := {}

var mode := ""
var out_dir := ""
var task_open := false
var persistent := false
var _fail := 0
var _checks := 0
var _boxes := 0
var _walk_m := 0.0
var _seen_lines: Array[String] = []
var _toasts: Array[String] = []
var _last_dir := Vector3.ZERO
var _direct := 0


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--fh-mode="):
			mode = a.substr(10)
		elif a.begins_with("--fh-out="):
			out_dir = a.substr(9)
		elif a == "--fh-task-open":
			task_open = true
	if mode != "pass" and mode != "reload" and mode != "bitview":
		return
	if not persistent:
		var p: Node = load("res://showcase/first_hour_pass.gd").new()
		p.persistent = true
		p.name = "FirstHourPass"
		get_tree().root.add_child.call_deferred(p)
		_setup_state()
		get_tree().change_scene_to_file.call_deferred("res://src/world/world.tscn")
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	if out_dir != "":
		DirAccess.make_dir_recursive_absolute(out_dir)
	EventBus.toast_requested.connect(func(text: String, _icon: String) -> void:
		_toasts.append(text)
		print("FHPASS TOAST %s" % text))
	get_tree().create_timer(240.0).timeout.connect(func() -> void:
		print("FHPASS WATCHDOG quit")
		get_tree().quit(3))
	_run.call_deferred()


## A new campaign game that has had its crash and radio call and hopped to the Commons.
func _setup_state() -> void:
	GameState.reset_new_game()
	GameState.previous_planet_id = "home"
	GameState.current_planet_id = "hub"
	for f: String in ["intro_crash_done", "intro_greeted", "intro_done"]:
		GameState.set_flag(f)
	GameState.time_of_day = 10.0
	if task_open:
		ProfessorAsk.open_task()
	if mode == "bitview":
		for f: String in [FirstHour.STARTED_FLAG, "fh_pop_asked", "met_mayor_orbit", "met_pop"]:
			GameState.set_flag(f)
	if mode == "reload":
		# A save made mid-errand, loaded by a fresh process: sent out, Pip and Pop asked, Pop's bit
		# not found yet, Pip 1 of 4 scrap - the world must rebuild both on load with no talk first.
		for f: String in [FirstHour.STARTED_FLAG, "fh_pip_asked", "fh_pop_asked", "met_mayor_orbit"]:
			GameState.set_flag(f)
		GameState.flags[FirstHour.PIP_SCRAP_FLAG] = 1.0  # JSON-loaded ints come back as floats


func _ok(cond: bool, what: String) -> void:
	_checks += 1
	if cond:
		print("FHPASS ok   %s" % what)
	else:
		_fail += 1
		print("FHPASS FAIL %s" % what)


func _run() -> void:
	await _wait_world("hub")
	if mode == "bitview":
		await _bitview()
		return
	if mode == "reload":
		var fh := get_tree().root.get_node_or_null("World/FirstHour")
		_ok(fh != null, "reload: FirstHour node built on load with no talk")
		_ok(fh != null and fh.get_node_or_null("PopsPatchBit") != null, "reload: Pop's bit is on the ground")
		var extra := 0
		for n: Node in get_tree().get_nodes_in_group("collectibles"):
			if str(n.name).begins_with("Collectible_fh_pip_"):
				extra += 1
		_ok(extra == FirstHour.PIP_SCRAP - 1 + 1, "reload: %d extra scrap near Pip (needed 3 + 1)" % extra)
		_ok(FirstHour.pip_scrap() == 1, "reload: Pip's count read back from a float (%d)" % FirstHour.pip_scrap())
		print("FHPASS RESULT checks=%d fail=%d" % [_checks, _fail])
		get_tree().quit(1 if _fail > 0 else 0)
		return
	print("FHPASS armed renderer=%s size=%s task_open_at_start=%s" % [RenderingServer.get_current_rendering_method(),
		str(get_viewport().get_visible_rect().size), str(ProfessorAsk.is_open())])
	var t0 := Time.get_ticks_msec()
	_ok(CampaignData.gates_on(), "gates on (new campaign game)")
	_ok(not CampaignData.planet_in_range("zorp") and not CampaignData.planet_in_range("bolt")
		and CampaignData.planet_in_range("hub"), "start: zorp and bolt shut, hub open")
	await _picker("picker_gated", true)

	# --- the Professor's first meeting: he sends you out
	await _talk("mayor_orbit", "prof_meet", [9])
	_ok(GameState.flag(FirstHour.STARTED_FLAG), "the Professor sent the player to the residents")
	_ok(_seen("That crackly voice on the radio? That was me!") and _seen("Mind the boxes. Everyone's packing to leave."),
		"his first-meeting lines played")
	_ok(_seen("Now then, %s. About that poor ship of yours." % GameState.player_style.get("name", "Astro")),
		"his dispatch uses the player's name")

	# --- Pip: sweep scrap
	await _talk("pip", "pip_ask", [])
	var scrap_before := GameState.scrap
	var swept := 0
	for i in 12:
		if FirstHour.task_met("pip"):
			break
		var c := _nearest_scrap()
		if c == null:
			break
		await _go_to(c.global_position, 0.6)
		await _interact_with(c, "scrap")
		swept += 1
	_ok(FirstHour.task_met("pip"), "Pip's scrap swept (%d pickups, scrap %d -> %d)" % [swept, scrap_before, GameState.scrap])
	await _talk("pip", "pip_done", [])
	_ok(GameState.flag("fh_pip_bit"), "Pip handed over her bit")

	# --- Pop: find his bit near the event space
	await _talk("pop", "pop_ask", [])
	var fh := get_tree().root.get_node_or_null("World/FirstHour")
	var bit: Node3D = fh.get_node_or_null("PopsPatchBit") if fh != null else null
	_ok(bit != null, "Pop's bit is on the ground")
	await _talk("pop", "pop_nudge1", [])
	await _talk("pop", "pop_nudge2", [])
	_ok(_seen("Over by the music, I think. My feelers say so.") and _seen("By the big speakers, I think! Near the dance floor."),
		"Pop's first and second nudges differ")
	if bit != null:
		var planet := _planet()
		print("FHPASS pop bit %.1f m from Pop's shop, %.1f m from the event space" % [
			planet.surface_distance(planet.dir_of(bit.global_position), planet.building_dir("deco_store")),
			planet.surface_distance(planet.dir_of(bit.global_position), planet.building_dir("event_space"))])
		await _go_to(bit.global_position, 3.5)
		await _wait(0.8)
		await _capture("pop_bit_on_ground")
		await _go_to(bit.global_position, 0.8)
		await _interact_with(bit, "pop_bit")
	_ok(GameState.flag(FirstHour.POP_FOUND_FLAG), "Pop's bit picked up")
	await _talk("pop", "pop_done", [])
	_ok(GameState.flag("fh_pop_bit"), "Pop handed over his bit")

	# --- Stella: measure the rocket
	await _talk("stella", "stella_ask", [])
	_ok(not GameState.flag(FirstHour.STELLA_MEASURED_FLAG), "not measured before walking to the rocket")
	var pad := _planet().pad_transform().origin
	await _go_to(pad, 3.0)
	await _wait(0.8)
	_ok(GameState.flag(FirstHour.STELLA_MEASURED_FLAG), "rocket measured at the pad")
	await _talk("stella", "stella_done", [])
	_ok(GameState.flag("fh_stella_bit"), "Stella handed over her bit")
	_ok(FirstHour.bits() == 3, "three bits")

	# --- the Professor fits the patch
	var parts := GameState.rocket_part_count()
	var finish := CampaignData.finish_stage()
	await _talk("mayor_orbit", "prof_fit", [1, 2, 4])
	_ok(GameState.flag(FirstHour.PATCH_FLAG), "patch fitted")
	_ok(GameState.rocket_part_count() == parts and parts == 0, "rocket_part_count unchanged (%d)" % GameState.rocket_part_count())
	_ok(CampaignData.finish_stage() == finish and finish == 0, "finish stage still rusty (%d)" % CampaignData.finish_stage())
	_ok(ProfessorAsk.is_open(), "his photo task is open")
	_ok(FirstHour.parcel_held(), "carrying the parcel")
	var player := _player()
	_ok(player != null and str(player.call("get_carry_item")) == FirstHour.PARCEL_CARRY_ID, "the parcel is in the astronaut's hands")
	_ok(_seen("A photographer? Splendid!") and _seen("Help them, and they will help fix your ship."), "photographer lines played")
	_ok(_seen("First, a parcel for Zorp. His rivers are dimming."), "parcel line played")
	_ok(CampaignData.planet_in_range("zorp") and CampaignData.planet_in_range("bolt") and CampaignData.planet_in_range("hub"),
		"after the patch: zorp, bolt, hub open")
	await _picker("picker_open", false)
	await _talk("mayor_orbit", "prof_reminder", [])
	_ok(_seen("Zorp's glow bulbs! His rivers are waiting."), "the Professor reminds you of the parcel")
	var game_ms := Time.get_ticks_msec() - t0

	# --- fly to Zorp (synthesised: no rocket cutscene) and hand over the parcel
	SceneRouter.go_to_planet("zorp")
	await _wait_world("zorp")
	await _wait(1.0)
	_ok(get_tree().root.get_node_or_null("World/FirstHour") != null, "FirstHour node rebuilt on Zorp (parcel held)")
	player = _player()
	_ok(player != null and str(player.call("get_carry_item")) == FirstHour.PARCEL_CARRY_ID, "still carrying the parcel on Zorp")
	_ok(not GameState.projects.has("zorp"), "Zorp's project not started before the talk")
	await _talk("zorp", "zorp_parcel", [3, 4])
	_ok(GameState.flag(FirstHour.PARCEL_DONE_FLAG) and not FirstHour.parcel_held(), "parcel delivered")
	_ok(_seen("Glow bulbs! Thank you for carrying them so far!"), "Zorp's delivery lines played")
	_ok(_seen("Oh no, oh no! My rivers are going dark!"), "Zorp's own project intro followed in the same talk")
	_ok(GameState.projects.has("zorp") and bool((GameState.projects["zorp"] as Dictionary).get("asked", false)),
		"Zorp's project started and step 0 asked: %s" % str(GameState.projects.get("zorp", {})))
	player = _player()
	_ok(player != null and str(player.call("get_carry_item")) == "", "hands empty after delivery")

	# --- regression: his photo task still pays out (a kept neighbour photo, set through the journal's
	# saved blob - SYNTHESISED: no safari was played), back on the Commons
	GameState.flags["planet_journal"] = {"friends": {"zorp": {"grade": "Fair"}}, "records": {}}
	var dust := GameState.stardust
	SceneRouter.go_to_planet("hub")
	await _wait_world("hub")
	_ok(not FirstHour.handles("mayor_orbit") and ProfessorAsk.handles("mayor_orbit"), "back on the Commons: his photo task owns his talk")
	await _talk("mayor_orbit", "prof_photo", [1])
	_ok(GameState.flag(ProfessorAsk.DONE_FLAG) and not ProfessorAsk.is_open(), "photo task closed")
	_ok(GameState.stardust == dust + ProfessorAsk.PROFESSOR_PAY, "paid %d stardust (%d -> %d)" % [ProfessorAsk.PROFESSOR_PAY, dust, GameState.stardust])
	_ok(_seen("One last look at home, so nothing gets left behind."), "the new reason line played")

	var est_s := _boxes * READ_S_PER_BOX + _walk_m / Player.RUN_SPEED
	print("FHPASS boxes=%d walked_m=%.0f est_play_s=%.0f (boxes x %.1f s + walk at %.1f m/s) harness_ms=%d" % [
		_boxes, _walk_m, est_s, READ_S_PER_BOX, Player.RUN_SPEED, game_ms])
	print("FHPASS direct_interact_fallbacks=%d" % _direct)
	print("FHPASS RESULT checks=%d fail=%d" % [_checks, _fail])
	get_tree().quit(1 if _fail > 0 else 0)


## ROUND 2 proof frames: Pop's bit seen from beside Pop (facing the stage) and from the stage front
## (the dance floor, facing Pop's shop), with the gameplay camera reseated behind the player.
func _bitview() -> void:
	var planet := _planet()
	var fh := get_tree().root.get_node_or_null("World/FirstHour")
	var bit: Node3D = fh.get_node_or_null("PopsPatchBit") if fh != null else null
	_ok(bit != null, "bitview: Pop's bit is on the ground")
	if bit == null:
		get_tree().quit(1)
		return
	var stage: Node3D = null
	for n: Node in get_tree().root.find_children("*", "Node3D", true, false):
		if str(n.get("building_id")) == "event_space":
			stage = n as Node3D
	var floor_pt := stage.to_global(Vector3(0.0, 0.0, -4.15))
	var pop := _npc("pop")
	var bd := planet.dir_of(bit.global_position)
	print("FHPASS bit: %.1f m from Pop (live), %.1f m from the dance-floor centre, %.1f m from the stage centre, %.1f m from Pop's shop, %.1f m from the pad" % [
		planet.surface_distance(bd, planet.dir_of(pop.global_position)),
		planet.surface_distance(bd, planet.dir_of(floor_pt)),
		planet.surface_distance(bd, planet.building_dir("event_space")),
		planet.surface_distance(bd, planet.building_dir("deco_store")),
		planet.surface_distance(bd, planet.data.pad_dir.normalized())])
	if OS.get_cmdline_user_args().has("--fh-diag"):
		var sd := planet.building_dir("event_space")
		var shop := planet.building_dir("deco_store")
		for side in [-3.0, 0.0, 3.0]:
			for t in range(4, 13):
				var d := planet.step_dir(sd, shop, float(t))
				if side != 0.0:
					var tang := sd.cross(shop).normalized()
					d = (d + tang * (side / planet.radius)).normalized()
				print("FHDIAG side=%+.0f t=%2d zone='%s' prop=%.1f floor=%.1f shop=%.1f pop=%.1f free=%s" % [side, t,
					planet.reserved_zone_at(d), planet.nearest_prop_distance(d),
					planet.surface_distance(d, planet.dir_of(floor_pt)), planet.surface_distance(d, shop),
					planet.surface_distance(d, planet.dir_of(pop.global_position)), str(planet.call("_is_free", d, 0.9))])
	pop.call("wander_enabled", false)
	await _wait(4.0)  # let the arrival banner and toasts clear
	# 1 m from Pop toward the bit (standing at Pop), and on the dance floor's centre - each facing the bit.
	var behind_pop := planet.surface_point(planet.step_dir(planet.dir_of(pop.global_position), bd, 1.0))
	await _view_from(behind_pop, bit.global_position, 0.0, "bitview_from_pop")
	await _view_from(floor_pt, bit.global_position, 0.0, "bitview_from_stage_front")
	print("FHPASS RESULT checks=%d fail=%d" % [_checks, _fail])
	get_tree().quit(1 if _fail > 0 else 0)


func _view_from(at: Vector3, look_at_pt: Vector3, side_m: float, tag: String) -> void:
	var planet := _planet()
	var p := _player()
	var d := planet.dir_of(at)
	if side_m > 0.0:
		d = planet.step_dir(d, planet.dir_of(look_at_pt), side_m)
	p.call("dev_teleport", planet.surface_point(d))
	await get_tree().physics_frame
	p.call("face_toward", look_at_pt)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var rig := get_tree().root.get_node_or_null("World/CameraRig")
	if rig != null and rig.has_method("reseat_behind_player"):
		rig.call("reseat_behind_player")
	await _wait(1.5)
	var cam := get_viewport().get_camera_3d()
	var bit: Node3D = get_tree().root.get_node_or_null("World/FirstHour/PopsPatchBit")
	if cam != null and bit != null:
		var on := not cam.is_position_behind(bit.global_position) and get_viewport().get_visible_rect().has_point(cam.unproject_position(bit.global_position))
		print("FHPASS %s: bit in frame=%s at %s, %.1f m from the player" % [tag, str(on),
			str(cam.unproject_position(bit.global_position)), p.global_position.distance_to(bit.global_position)])
		_ok(on, "%s: bit inside the camera frame" % tag)
	await _capture(tag)


# ===================================================================================== helpers
func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _wait_world(pid: String) -> void:
	for i in 600:
		var w := get_tree().root.get_node_or_null("World")
		if w != null and _planet() != null and _player() != null and GameState.current_planet_id == pid:
			break
		await get_tree().process_frame
	await _wait(1.5)


func _planet() -> Planet:
	return get_tree().get_first_node_in_group("planet") as Planet


func _player() -> Node3D:
	return get_tree().get_first_node_in_group("player") as Node3D


func _npc(id: String) -> Node3D:
	for n: Node in get_tree().get_nodes_in_group("npc"):
		if str(n.get("npc_id")) == id:
			return n as Node3D
	return null


func _seen(line: String) -> bool:
	return _seen_lines.has(line)


func _press(action: String) -> void:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = true
	Input.parse_input_event(e)
	await get_tree().physics_frame
	await get_tree().process_frame
	var r := InputEventAction.new()
	r.action = action
	r.pressed = false
	Input.parse_input_event(r)
	await get_tree().process_frame


## A real `interact` action; if the target did not react (seen in windowed runs, where the press is
## not picked up - headless runs take it), the target's own interact() is called instead, and logged.
func _interact_with(target: Node, tag: String) -> void:
	await _press("interact")
	await _wait(0.4)
	if is_instance_valid(target) and target is Interactable and (target as Interactable).enabled \
			and not (target as Interactable).is_queued_for_deletion():
		_direct += 1
		print("FHPASS note %s: interact press not taken; calling interact() directly" % tag)
		(target as Interactable).interact(_player())
		await _wait(0.4)


## Teleports the player to `stand_off` metres short of `target` (along the surface from where they
## are), facing it, and adds the surface distance to the walking total.
func _go_to(target: Vector3, stand_off: float) -> void:
	var p := _player()
	var planet := _planet()
	var from_dir := planet.dir_of(p.global_position)
	var to_dir := planet.dir_of(target)
	var dist := planet.surface_distance(from_dir, to_dir)
	var stand := to_dir if dist <= stand_off else planet.step_dir(to_dir, from_dir, stand_off)
	_walk_m += maxf(0.0, dist - stand_off)
	p.call("dev_teleport", planet.surface_point(stand))
	await get_tree().physics_frame
	if p.has_method("face_toward"):
		p.call("face_toward", target)
	await get_tree().physics_frame
	await get_tree().physics_frame


func _nearest_scrap() -> Node3D:
	var p := _player()
	var best: Node3D = null
	var best_d := INF
	for n: Node in get_tree().get_nodes_in_group("collectibles"):
		if str(n.get("kind")) != "scrap" or not bool(n.get("enabled")):
			continue
		var d := (n as Node3D).global_position.distance_to(p.global_position)
		if d < best_d:
			best = n as Node3D
			best_d = d
	return best


## One whole talk, started with a real `interact` action next to the neighbour, advanced box by box.
## `capture_at`: box indices (0-based, this talk) to save a frame of once the line has typed.
func _talk(id: String, tag: String, capture_at: Array) -> void:
	var npc := _npc(id)
	if npc == null:
		_ok(false, "%s: neighbour %s found" % [tag, id])
		return
	await _go_to(npc.global_position, 1.6)
	var runner := DialogueRunner.get_or_create(self)
	print("FHPASS %s start: runner_active=%s modal=%s target=%s" % [tag, str(runner.is_active()),
		str(EventBus.is_modal_open()), str(_player().call("get_interact_target"))])
	var target: Node = _player().call("get_interact_target")
	if target != null and npc.is_ancestor_of(target):
		await _press("interact")
		await _wait(0.3)
	else:
		# Pip and Pop stand 2.8 m apart, so a teleport can land nearer the other one; a player would
		# turn to the one they mean. Started directly then, and said so.
		print("FHPASS note %s: nearest talk target is not %s (%s)" % [tag, id, str(target)])
	if not runner.is_active():
		print("FHPASS note %s: interact did not start the talk (target=%s); starting it directly" % [tag,
			str(_player().call("get_interact_target"))])
		npc.call("start_conversation", _player())
		await _wait(0.3)
	var box: Node = runner.call("_ensure_box")
	var idx := 0
	var last_key := ""
	var idle := 0.0
	for i in 2000:
		await _wait(TAP_S)
		if box == null:
			box = runner.call("_ensure_box")
			if box == null and not runner.is_active():
				idle += TAP_S
				if idle > 1.0:
					print("FHPASS note %s: no dialogue box and no talk" % tag)
					break
			continue
		var state := int(box.get("_state"))
		if state == 1:  # LINES
			idle = 0.0
			if bool(box.get("_typing")):
				box.call("debug_tap")
				continue
			var lines: PackedStringArray = box.get("_lines")
			var li := int(box.get("_line_index"))
			var key := "%d:%s" % [li, lines[li] if li < lines.size() else ""]
			if key != last_key and li < lines.size():
				last_key = key
				_seen_lines.append(lines[li])
				print("FHPASS %s box %d [%d] %s" % [tag, idx, lines[li].length(), lines[li].replace("\n", " / ")])
				if capture_at.has(idx):
					await _wait(0.4)
					await _capture("%s_%d" % [tag, idx])
				idx += 1
				_boxes += 1
			box.call("debug_tap")
		elif state == 2:  # CHOICE
			print("FHPASS %s CHOICE shown: %s - taking option 0" % [tag, str(box.get("_options"))])
			box.call("debug_tap")
		else:
			if not runner.is_active():
				idle += TAP_S
				if idle > 0.6:
					break
	await _wait(0.4)


## Opens the rocket pad's destination card with a real `interact` next to the pad, captures it and
## checks the zorp/bolt tiles, then closes it with `cancel`.
func _picker(tag: String, expect_locked: bool) -> void:
	var planet := _planet()
	await _go_to(planet.pad_transform().origin, 2.0)
	await _press("interact")
	await _wait(1.2)
	var picker := _find_picker()
	if picker == null:
		var t: Node = _player().call("get_interact_target")
		if t is Interactable:
			_direct += 1
			print("FHPASS note %s: interact press not taken; calling the pad's interact() directly" % tag)
			(t as Interactable).interact(_player())
			await _wait(1.2)
			picker = _find_picker()
	_ok(picker != null, "%s: destination card opened" % tag)
	if picker == null:
		return
	var opts: Array = picker.get("_options")
	var locked: Array = picker.get("_locked")
	var labels: Array = picker.get("_pill_labels")
	for i in opts.size():
		var lab := labels[i] as Label
		print("FHPASS %s tile %s locked=%s pill='%s' pill_w=%.0f label_min_w=%.0f lines=%d" % [tag, opts[i], str(locked[i]),
			lab.text, lab.size.x, lab.custom_minimum_size.x, lab.get_line_count()])
		if str(opts[i]) in ["zorp", "bolt"]:
			_ok(bool(locked[i]) == expect_locked, "%s: %s locked=%s" % [tag, opts[i], str(expect_locked)])
			if expect_locked:
				_ok(lab.text == PadDestinationPicker.PATCH_TEXT and lab.get_line_count() == 1,
					"%s: %s pill says '%s' on one line" % [tag, opts[i], lab.text])
	await _capture(tag)
	await _press("cancel")
	await _wait(0.8)
	if is_instance_valid(picker) and not bool(picker.get("_closing")):
		picker.call("_cancel")
		await _wait(0.8)


func _find_picker() -> Node:
	for n: Node in get_tree().root.find_children("*", "CanvasLayer", true, false):
		if n is PadDestinationPicker and not bool(n.get("_closing")):
			return n
	return null


func _capture(tag: String) -> void:
	if out_dir == "" or DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := out_dir.path_join("%s.png" % tag)
	img.save_png(path)
	print("FHPASS capture %s" % path)
