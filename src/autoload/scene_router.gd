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
	if path == WORLD_SCENE:
		_prebuild_current_planet()
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	# The new scene may have installed something that pauses again before we finish fading in.
	if get_tree().paused:
		get_tree().paused = false
	await fade_in(0.6)
	_busy = false

## Safety net for every path into the world, not only a rocket arrival: warms Planet's static
## geometry cache for GameState.current_planet_id here, after the fade-out has finished and before
## `change_scene_to_file` builds the scene. Unlike a title-screen prebuild (removed, see
## title_screen.gd), this is safe: it runs AFTER a Continue/New Game has already called
## `SaveManager.load_game()` / `GameState.reset_new_game()`, so it bakes against the real
## GameState, not an empty one.
## BE HONEST ABOUT WHAT THIS BUYS: it does not shrink the total work of a first visit. Measured
## with the geometry cache cold, prebuild + world build costs about the same as a plain world build
## alone (hub: 413.8ms alone vs. 245.7ms prebuild + 156.2ms world = 401.9ms combined) - both halves
## run behind the same solid fade, so this MOVES the cost out of `world.gd::_ready()` rather than
## removing it. What it genuinely buys: `Planet.prebuild` is idempotent, so a rocket arrival that
## already prebuilt during its cruise (src/rocket/journey_state.gd prewarm_destination) pays
## nothing extra here; the geometry cache is left warm afterward, so a second load of the same
## planet in one session is about 2.4x faster (hub 385ms -> 161ms); and every entry point into the
## world now gets that warm-cache path, not only rocket arrivals.
## Calls `Planet.prebuild` through a dynamically loaded script reference, NOT the `Planet` class_name
## symbol directly. Measured: writing `Planet.prebuild(...)` here made this AUTOLOAD's script resolve
## the whole Planet class (68 KB) at parse time for every scene in the project, not just world
## entries, and that early/forced load leaked resources at process exit in
## `showcase/characters_lineup.tscn` - a scene that never runs this function and has nothing to do
## with SceneRouter. Independently re-measured: 331 leaked ObjectDB instances, 29 resources still in
## use, and 64 RIDs across 4 RendererDummy types. Bisected: a `Planet.prebuild` reference in
## title_screen.gd (a plain scene script, not an autoload) does not leak, and a stub with no
## `Planet` symbol at all does not either - so the dynamic call below is the fix, not a workaround
## for something else. Do not "simplify" this back to `Planet.prebuild(data)`.
func _prebuild_current_planet() -> void:
	var pid := GameState.current_planet_id
	var data_path := "res://src/planet/data/%s.tres" % pid
	if not ResourceLoader.exists(data_path):
		return
	var data: Resource = ResourceLoader.load(data_path)
	if data == null:
		return
	var planet_script: GDScript = load("res://src/planet/planet.gd")
	planet_script.call("prebuild", data)

func fade_out(duration: float) -> void:
	var t := create_tween()
	t.tween_property(_fade, "color:a", 1.0, duration).set_trans(Tween.TRANS_SINE)
	await t.finished

func fade_in(duration: float) -> void:
	var t := create_tween()
	t.tween_property(_fade, "color:a", 0.0, duration).set_trans(Tween.TRANS_SINE)
	await t.finished
