extends Node
## Scene transitions with a soft fade. Owns the fade overlay.
## go_to_planet("zorp") -> fades, sets GameState.current_planet_id, loads world.tscn.
## go_to_space("home") -> loads the rocket travel scene.

const WORLD_SCENE := "res://src/world/world.tscn"
const SPACE_SCENE := "res://src/rocket/space_travel.tscn"
const TITLE_SCENE := "res://src/ui/title/title_screen.tscn"

var _fade: ColorRect
var _busy := false

func _ready() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color(0.05, 0.04, 0.12, 0.0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_fade)
	# The fade must keep animating even if something pauses the tree mid-transition, otherwise
	# `_transition_to` deadlocks waiting on a tween that will never finish.
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	process_mode = Node.PROCESS_MODE_ALWAYS

func is_busy() -> bool:
	return _busy

func go_to_planet(planet_id: String, spawn_at_pad: bool = true) -> void:
	if _busy:
		return
	GameState.previous_planet_id = GameState.current_planet_id
	GameState.current_planet_id = planet_id
	GameState.set_flag("spawn_at_pad", spawn_at_pad)
	await _transition_to(WORLD_SCENE)
	EventBus.travel_finished.emit(planet_id)

func go_to_space(from_planet_id: String) -> void:
	if _busy:
		return
	GameState.previous_planet_id = from_planet_id
	EventBus.planet_leave_requested.emit(from_planet_id)
	await _transition_to(SPACE_SCENE)

func go_to_title() -> void:
	await _transition_to(TITLE_SCENE)

func start_game() -> void:
	await _transition_to(WORLD_SCENE)

func _transition_to(path: String) -> void:
	# A scene change while the tree is paused is unrecoverable: the fade tween never advances, so
	# this coroutine never resumes, `_busy` stays true forever, the player is left with input
	# disabled under a permanent dark scrim, and nothing can unpause because the pause menu died
	# with the old scene. A critic forced this with a probe and could not find a player-reachable
	# trigger, but it is two lines to make impossible, so it is made impossible.
	if get_tree().paused:
		push_warning("SceneRouter: tree was paused at a scene change; force-unpausing.")
		get_tree().paused = false
	_busy = true
	await fade_out(0.45)
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	# The new scene may have installed something that pauses again before we finish fading in.
	if get_tree().paused:
		get_tree().paused = false
	await fade_in(0.6)
	_busy = false

func fade_out(duration: float) -> void:
	var t := create_tween()
	t.tween_property(_fade, "color:a", 1.0, duration).set_trans(Tween.TRANS_SINE)
	await t.finished

func fade_in(duration: float) -> void:
	var t := create_tween()
	t.tween_property(_fade, "color:a", 0.0, duration).set_trans(Tween.TRANS_SINE)
	await t.finished
