class_name DialogueRunner
extends Node
## Thin, awaitable wrapper around the UI builder's DialogueBox (ARCHITECTURE §6). It owns everything
## a conversation needs besides the words: who faces whom, the camera push-in, freezing the player,
## and the EventBus dialogue signals.
##
##   var dlg := DialogueRunner.get_or_create(self)
##   dlg.begin(npc, player)
##   await dlg.say(npc, ["Hi!", "Nice planet."])
##   var yes: int = await dlg.ask(npc, "Help me?", ["Sure!", "Maybe later"])
##   dlg.finish()
##
## `say`/`ask` call `begin` themselves if a conversation is not open yet, so a one-liner works too.
## The box is found via the group "dialogue_box", then /root/World/HUD/DialogueBox; if neither exists
## (isolated showcase scenes) the runner instances dialogue_box.tscn into its own CanvasLayer.

const BOX_SCENE := "res://src/ui/dialogue/dialogue_box.tscn"
const BOX_PATH := "/root/World/HUD/DialogueBox"
const RUNNER_NAME := "DialogueRunner"
const FOCUS_TIME := 0.55
const RELEASE_TIME := 0.5
## How far above the ground the camera aims when framing the pair (head height of a 1.4 m villager).
const FOCUS_LIFT := 0.48
## How far PAST the neighbour the focus point is thrown, as a multiple of the player-to-NPC distance.
## `CameraRig` aims at the midpoint of the player and this point and then lerps 75 % of the way to it,
## so a plain `focus = npc` framed a spot only 22 % of the way from the player to the neighbour — the
## neighbour ended up off to the side and far away (head = 11 % of frame height; Rosie is 28 %).
## 2.6 puts the aim point on the neighbour's head instead.
const FOCUS_REACH := 2.6
## Dialogue FOV. `CameraRig` cannot be told to dolly closer (it only takes a focus point), and its
## own push-in is a fixed 0.78x, so the rest of the push-in is done on the camera it hands out.
## 45 -> 30 deg is a 1.5x magnification; with the aim fix the neighbour's head goes from 11 % of
## frame height to 27 %, against 28 % for Rosie in reference/AC Reference 4.
const FOCUS_FOV := 30.0
const DEFAULT_FOV := 45.0
## While talking, the neighbour turns this far from the player toward the camera, so we always see a
## three-quarter FRONT view. AC villagers do the same; without it you talk to the back of their head.
const FACE_CAMERA_BIAS := 0.5

var _box: DialogueBox
var _own_layer: CanvasLayer
var _speaker_id: String = ""
var _player: Node3D
var _npc: Node3D
var _active := false
var _fov_tween: Tween
var _saved_fov: float = DEFAULT_FOV


## Finds (or creates) the shared runner. It lives next to the HUD under /root/World when that exists.
static func get_or_create(context: Node) -> DialogueRunner:
	var tree := context.get_tree()
	if tree == null:
		return null
	var host: Node = tree.root.get_node_or_null("World")
	if host == null:
		host = tree.current_scene
	if host == null:
		host = tree.root
	var existing := host.get_node_or_null(RUNNER_NAME)
	if existing is DialogueRunner:
		return existing as DialogueRunner
	var runner := DialogueRunner.new()
	runner.name = RUNNER_NAME
	host.add_child(runner)
	return runner


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false)


## True while a conversation is open.
func is_active() -> bool:
	return _active


# ============================================================================= framing
## Opens a conversation: both parties turn to face each other, the camera pushes in, input freezes.
func begin(npc: Node3D, player: Node3D = null) -> void:
	if _active:
		return
	_active = true
	_npc = npc
	_player = player if player != null else _find_player()
	_speaker_id = _npc_id(npc)
	if _player != null and npc != null:
		if _player.has_method("face_toward"):
			_player.call("face_toward", npc.global_position)
		if "input_enabled" in _player:
			_player.set("input_enabled", false)
		if _player.has_method("set_talking"):
			_player.call("set_talking", true)
	var rig := _camera_rig()
	if rig != null and rig.has_method("focus_on"):
		rig.call("focus_on", _focus_point(), FOCUS_TIME)
	_push_in(FOCUS_FOV, FOCUS_TIME)
	set_process(true)
	EventBus.dialogue_started.emit(_speaker_id)


## Closes the conversation: camera releases, the player gets control back.
func finish() -> void:
	if not _active:
		return
	_active = false
	set_process(false)
	_push_in(_saved_fov, RELEASE_TIME)
	var rig := _camera_rig()
	if rig != null and rig.has_method("release_focus"):
		rig.call("release_focus", RELEASE_TIME)
	if _player != null and is_instance_valid(_player):
		if _player.has_method("set_talking"):
			_player.call("set_talking", false)
		if "input_enabled" in _player:
			_player.set("input_enabled", true)
	EventBus.dialogue_finished.emit(_speaker_id)
	_speaker_id = ""
	_npc = null
	_player = null


## Point the camera frames. Thrown FOCUS_REACH past the neighbour along the player-to-NPC line,
## because `CameraRig` halves it against the player's own position and then blends only 75 % of the
## way — see FOCUS_REACH. Net effect: the aim lands on the neighbour's head, with the player at the
## edge of frame and the box underneath, like reference/AC Reference 4 (Rosie).
func _focus_point() -> Vector3:
	if _npc == null or not is_instance_valid(_npc):
		return Vector3.ZERO
	var up := _npc_up()
	if _player == null or not is_instance_valid(_player):
		return _npc.global_position + up * FOCUS_LIFT
	var to_npc := _npc.global_position - _player.global_position
	return _player.global_position + to_npc * FOCUS_REACH + up * FOCUS_LIFT


func _npc_up() -> Vector3:
	if _npc is PlanetBody and (_npc as PlanetBody).planet != null:
		return (_npc as PlanetBody).planet.up_at(_npc.global_position)
	return Vector3.UP


## Re-aims every frame while the box is open — the focus point used to be sampled once in `begin()`,
## so the camera kept staring at a stale spot if anybody moved — and keeps the neighbour turned
## toward the camera so the player never talks to the back of their head.
func _process(_delta: float) -> void:
	if not _active or _npc == null or not is_instance_valid(_npc):
		return
	var rig := _camera_rig()
	if rig != null and rig.has_method("focus_on"):
		rig.call("focus_on", _focus_point(), 0.12)
	_turn_npc_to_camera()


## The neighbour faces a point blended between the player and the camera, so whatever framing the
## rig picks, we see a three-quarter FRONT view of them.
func _turn_npc_to_camera() -> void:
	if _player == null or not is_instance_valid(_player) or not _npc.has_method("face_toward_point"):
		return
	var target := _player.global_position
	var cam := _camera()
	if cam != null:
		target = target.lerp(cam.global_position, FACE_CAMERA_BIAS)
	_npc.call("face_toward_point", target)


## Tweens the gameplay camera's FOV (CameraRig sets it once in `_ready` and never touches it again,
## so this is safe and always restored in `finish()`).
func _push_in(fov: float, duration: float) -> void:
	var cam := _camera()
	if cam == null:
		return
	if _fov_tween:
		_fov_tween.kill()
	if is_equal_approx(fov, FOCUS_FOV):
		_saved_fov = cam.fov
	_fov_tween = create_tween()
	_fov_tween.tween_property(cam, "fov", fov, maxf(duration, 0.01)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _camera() -> Camera3D:
	var rig := _camera_rig()
	if rig != null and rig.has_method("get_camera"):
		return rig.call("get_camera") as Camera3D
	var vp := get_viewport()
	return vp.get_camera_3d() if vp != null else null


# ============================================================================= speaking
## Shows lines spoken by `npc` and waits for the player to advance past the last one.
func say(npc: Node3D, lines: Array) -> void:
	if lines.is_empty():
		return
	if not _active:
		begin(npc)
	var box := _ensure_box()
	if box == null:
		return
	if npc != null and npc.has_method("face_player"):
		npc.call("face_player")
	await box.show_lines(_display_name(npc), lines, _voice(npc), _accent(npc))


## Asks a question with 2-4 options. Returns the chosen index, or -1 if cancelled.
## When the box is already open (the usual case, right after `say`) the speaker's name tag stays up.
func ask(npc: Node3D, prompt: String, options: Array) -> int:
	if not _active:
		begin(npc)
	var box := _ensure_box()
	if box == null:
		return -1
	if not box.is_open():
		# nothing on screen yet: show the prompt as a line first so the name tag is correct
		await box.show_lines(_display_name(npc), [prompt], _voice(npc), _accent(npc))
		return await box.show_choice("", options)
	return await box.show_choice(prompt, options)


## Narration with no speaker (system messages, "You handed over 3 Gear Bits.").
func narrate(lines: Array) -> void:
	if lines.is_empty():
		return
	var box := _ensure_box()
	if box == null:
		return
	await box.show_lines("", lines, "astro", Color("#5b7cff"))


# ============================================================================= lookups
func _ensure_box() -> DialogueBox:
	if _box != null and is_instance_valid(_box):
		return _box
	var found := get_tree().get_first_node_in_group("dialogue_box")
	if found == null:
		found = get_tree().root.get_node_or_null(BOX_PATH)
	if found is DialogueBox:
		_box = found as DialogueBox
		return _box
	if not ResourceLoader.exists(BOX_SCENE):
		push_warning("DialogueRunner: no DialogueBox and %s is missing" % BOX_SCENE)
		return null
	_own_layer = CanvasLayer.new()
	_own_layer.name = "DialogueLayer"
	_own_layer.layer = 10
	add_child(_own_layer)
	var inst: Node = load(BOX_SCENE).instantiate()
	_own_layer.add_child(inst)
	_box = inst as DialogueBox
	return _box


func _find_player() -> Node3D:
	var p := get_tree().get_first_node_in_group("player")
	return p as Node3D


func _camera_rig() -> Node:
	var cam := get_tree().get_first_node_in_group("camera_rig")
	if cam != null:
		return cam
	var world := get_tree().root.get_node_or_null("World")
	if world != null:
		return world.get_node_or_null("CameraRig")
	return null


static func _npc_id(npc: Node) -> String:
	if npc == null:
		return ""
	if "npc_id" in npc and str(npc.get("npc_id")) != "":
		return str(npc.get("npc_id"))
	return String(npc.name)


static func _display_name(npc: Node) -> String:
	if npc == null:
		return ""
	if "display_name" in npc and str(npc.get("display_name")) != "":
		return str(npc.get("display_name"))
	return String(npc.name)


static func _voice(npc: Node) -> String:
	if npc == null:
		return "astro"
	if "voice_profile" in npc and str(npc.get("voice_profile")) != "":
		return str(npc.get("voice_profile"))
	return "astro"


static func _accent(npc: Node) -> Color:
	if npc == null:
		return Color("#5b7cff")
	if "accent_color" in npc:
		var c: Variant = npc.get("accent_color")
		if c is Color:
			return c
	return Color("#5b7cff")
