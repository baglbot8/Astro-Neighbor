extends Node3D
## Standalone review rig for the rocket pad (showcase/rocket_pad.tscn).
##
## Builds the same node layout world.gd does — /root/World/{Planet, Environment, Player, CameraRig,
## Rocket, HUD} — from one PlanetData, so the pad, the boarding cutscene and the Director timeline
## behave exactly as they do in the real game without needing the title screen or a save file.
##
## IMPORTANT: by default the player is placed **exactly where world.gd would spawn them** — at
## `PlanetData.spawn_dir` with `forward_hint = Vector3.FORWARD` — because the previous version
## staged them 9 m from the pad already facing it, which flattered the pad's discoverability and
## hid the fact that a real new player spawns ~122 deg away from it. Set `start_offset_m` > 0 only
## for deliberate close-up framing shots, and say so.
##
## CLI flags (OS user args, after `--`):
##   --planet=<id>   which planet to stand on
##   --near          stage the player 9 m from the pad, facing it (framing shots only)
##   --tris          print the rocket's triangle count vs the ARCHITECTURE §10 2k prop budget
##   --launch=<id>   stage the player at the pad and launch for <id> after `launch_delay`, skipping
##                   the walk and the destination card. For tuning the CLIMB in isolation; the real
##                   journey timelines still start from the untouched spawn point.
##   --card          stage the player at the pad and open the "Where to?" destination card, so it can
##                   be reviewed on any planet under real gameplay lighting
##                   (showcase/rocket_destination_card.tscn). The card is the one piece of the rocket
##                   a player reads rather than watches, so it gets its own scene.

const PLANET_SCENE := "res://src/planet/planet.tscn"
const ENV_SCENE := "res://src/world/environment.tscn"
const PLAYER_SCENE := "res://src/player/player.tscn"
const CAMERA_SCENE := "res://src/player/camera_rig.tscn"
const HUD_SCENE := "res://src/ui/hud/hud.tscn"
const PAD_SCENE := "res://src/rocket/rocket_pad.tscn"

## Which planet to stand on.
@export var planet_id: String = "home"
## Hour of the in-game day the showcase freezes at (-1 keeps the clock running).
@export var hour: float = 10.5
## 0 = the real spawn point (default, representative). > 0 stages the player that many metres from
## the pad along the pad->spawn great circle, already facing it — framing shots only.
@export var start_offset_m: float = 0.0
## Non-empty: fly to this planet automatically (climb-tuning rig, see --launch above).
@export var launch_dest: String = ""
@export var launch_delay: float = 0.8
## Stage the player on the pad and open the destination card (see --card above).
@export var open_card: bool = false

var planet: Planet
var player: Player


func _ready() -> void:
	name = "World"
	_parse_args()
	GameState.current_planet_id = planet_id
	var data: PlanetData = load("res://src/planet/data/%s.tres" % planet_id)
	planet = load(PLANET_SCENE).instantiate() as Planet
	planet.name = "Planet"
	planet.data = data
	add_child(planet)

	var env: Node3D = load(ENV_SCENE).instantiate()
	env.name = "Environment"
	add_child(env)

	player = load(PLAYER_SCENE).instantiate() as Player
	player.name = "Player"
	add_child(player)
	player.planet = planet
	if start_offset_m > 0.0:
		var start := _staged_dir(data)
		var toward_pad := data.pad_dir.normalized() - start * data.pad_dir.normalized().dot(start)
		player.place_on_planet(start, toward_pad.normalized() if toward_pad.length_squared() > 0.001 else Vector3.FORWARD)
	else:
		# Exactly what world.gd::_spawn_player does for a new game.
		player.place_on_planet(data.spawn_dir.normalized())
	EventBus.player_spawned.emit(player)

	var rig: Node3D = load(CAMERA_SCENE).instantiate()
	rig.name = "CameraRig"
	add_child(rig)

	var pad: Node3D = load(PAD_SCENE).instantiate()
	pad.name = "Rocket"
	add_child(pad)

	var hud: CanvasLayer = load(HUD_SCENE).instantiate()
	hud.name = "HUD"
	add_child(hud)

	if hour >= 0.0 and env.has_method("set_time"):
		env.set_time(hour)
		env.time_scale = 0.0
	EventBus.planet_loaded.emit(planet_id)
	if _want_tris:
		call_deferred("_report_tris", pad)
	if launch_dest != "":
		_auto_launch(pad)
	elif open_card:
		_auto_card(pad)


## Climb-tuning shortcut: drop the astronaut on the pad and start the journey, so a capture is all
## climb and no walking. Deliberately NOT what the journey timelines do — those have to start from
## the real spawn point to keep proving the pad is findable.
func _auto_launch(pad: Node) -> void:
	player.place_on_planet(planet.data.pad_dir.normalized())
	await get_tree().create_timer(launch_delay).timeout
	if not is_inside_tree():
		return
	pad.call("launch_to", launch_dest, player)


## Opens the "Where to?" card from the pad, exactly as pressing E on it does.
func _auto_card(pad: Node) -> void:
	player.place_on_planet(planet.data.pad_dir.normalized())
	await get_tree().create_timer(launch_delay).timeout
	if not is_inside_tree():
		return
	pad.call("_on_interacted", player)


var _want_tris := false


func _parse_args() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--planet="):
			planet_id = a.substr(9)
		elif a == "--near":
			start_offset_m = 9.0
		elif a == "--tris":
			_want_tris = true
		elif a.begins_with("--launch="):
			launch_dest = a.substr(9)
		elif a == "--card":
			open_card = true


## Prints the shipped triangle count of the rocket and the whole pad against the §10 budget.
func _report_tris(pad: Node) -> void:
	var model := pad.get("rocket") as RocketModel
	if model == null:
		return
	var hull := model.triangle_count(false)
	var with_fx := model.triangle_count(true)
	print("[tris] RocketModel hull=%d  hull+flame_fx=%d  (ARCHITECTURE §10 prop budget 2000)" % [hull, with_fx])
	print("[tris] whole pad (deck, mast, sign, trail, rocket) = %d" % _count(pad))


static func _count(root: Node) -> int:
	var total := 0
	for c in root.get_children():
		if c is MultiMeshInstance3D:
			var mmi := c as MultiMeshInstance3D
			total += RocketModel.mesh_triangles(mmi.multimesh.mesh) * mmi.multimesh.instance_count
		elif c is MeshInstance3D:
			total += RocketModel.mesh_triangles((c as MeshInstance3D).mesh)
		total += _count(c)
	return total


## Staged framing position: `start_offset_m` back from the pad along the pad->spawn great circle.
func _staged_dir(data: PlanetData) -> Vector3:
	var pad_dir := data.pad_dir.normalized()
	var spawn_dir := data.spawn_dir.normalized()
	var total := planet.surface_distance(pad_dir, spawn_dir)
	if total < 0.01:
		return spawn_dir
	return planet.step_dir(pad_dir, spawn_dir, minf(start_offset_m, total))
