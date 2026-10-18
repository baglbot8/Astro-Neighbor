extends Node
## NAME PICKER SHOWCASE + INPUT PROOF (docs/INTRO_SPEC.md 6). Opens `NamePicker.pick` three times over
## a navy backdrop and drives each with a different SYNTHESISED input path, printing what came back:
##   1. keyboard  real InputEventKey arrows/Enter through Input.parse_input_event (an Enter sent the
##                instant it opens must be ignored - the arm window), Right, Right, Down... picks Pebble.
##   2. gamepad   InputEventJoypadButton d-pad + A: picks Sprout.
##   3. tap       MobileUI.synth_tap on the Juno pill, then on the confirm pill: picks Juno.
## Synthesised, all of it: no real keyboard, pad or finger is involved.
##   godot --path . --resolution 2556x1179 res://showcase/name_picker.tscn -- --ui=mobile --np-shot=/abs/dir
## `--np-shot=<dir>` (windowed runs only) saves a PNG of each picker with a name chosen.

var _shot_dir := ""


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--np-shot="):
			_shot_dir = a.substr(10)
	var bg := ColorRect.new()
	bg.color = UIStyle.NAVY
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var layer := CanvasLayer.new()
	layer.layer = -1
	add_child(layer)
	layer.add_child(bg)
	_run.call_deferred()


func _run() -> void:
	GameState.player_style["name"] = "Astro"
	var results: PackedStringArray = []
	# 1. keyboard
	_drive_keys.call_deferred()
	results.append(await NamePicker.pick(self))
	await _wait(0.4)
	# 2. gamepad
	_drive_pad.call_deferred()
	results.append(await NamePicker.pick(self))
	await _wait(0.4)
	# 3. tap
	_drive_tap.call_deferred()
	results.append(await NamePicker.pick(self))
	var want := PackedStringArray(["Pebble", "Sprout", "Juno"])
	var ok := results == want
	print("NAMEPICKER RESULT got=%s want=%s stored=%s %s" % [str(results), str(want),
		str(GameState.player_style.get("name", "")), "PASS" if ok else "FAIL"])
	if not ok:
		push_error("NAMEPICKER: wrong picks %s" % str(results))
	await _wait(0.3)
	get_tree().quit(0 if ok else 1)


func _picker() -> NamePicker:
	return find_child("NamePicker", true, false) as NamePicker


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _key(code: Key) -> void:
	for pressed in [true, false]:
		var ev := InputEventKey.new()
		ev.keycode = code
		ev.physical_keycode = code
		ev.pressed = pressed
		Input.parse_input_event(ev)
		await get_tree().process_frame
		await get_tree().process_frame


func _pad(button: JoyButton) -> void:
	for pressed in [true, false]:
		var ev := InputEventJoypadButton.new()
		ev.button_index = button
		ev.pressed = pressed
		Input.parse_input_event(ev)
		await get_tree().process_frame
		await get_tree().process_frame


func _drive_keys() -> void:
	await get_tree().process_frame
	# Inside the arm window: must do nothing.
	await _key(KEY_ENTER)
	_picker().debug_report("keys_after_early_enter")
	await _wait(0.5)
	await _key(KEY_RIGHT)
	await _key(KEY_RIGHT)
	_picker().debug_report("keys_on_pebble")
	await _key(KEY_ENTER)
	_picker().debug_report("keys_chosen")
	await _shot("keys")
	await _wait(0.3)
	await _key(KEY_ENTER)


func _drive_pad() -> void:
	await _wait(0.6)
	await _pad(JOY_BUTTON_DPAD_DOWN)
	await _pad(JOY_BUTTON_DPAD_RIGHT)
	await _pad(JOY_BUTTON_DPAD_RIGHT)
	_picker().debug_report("pad_on_sprout")
	await _pad(JOY_BUTTON_A)
	_picker().debug_report("pad_chosen")
	await _shot("pad")
	await _wait(0.3)
	await _pad(JOY_BUTTON_A)


func _drive_tap() -> void:
	await _wait(0.6)
	_picker().debug_tap("confirm")
	await _wait(0.2)
	_picker().debug_report("tap_confirm_before_pick")
	_picker().debug_tap("Juno")
	await _wait(0.3)
	_picker().debug_report("tap_chosen")
	await _shot("tap")
	_picker().debug_tap("confirm")


func _shot(tag: String) -> void:
	if _shot_dir == "" or DisplayServer.get_name() == "headless":
		return
	await _wait(0.35)
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(_shot_dir)
	var path := _shot_dir.path_join("name_picker_%s_%dx%d.png" % [tag, img.get_width(), img.get_height()])
	img.save_png(path)
	print("NAMEPICKER SHOT %s" % path)
