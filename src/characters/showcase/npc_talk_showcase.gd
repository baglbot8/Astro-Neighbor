extends Node3D
## showcase/npc_talk.tscn — a self-contained slice of the real game for reviewing conversations:
## Zorp's planet, Zorp, the player, the camera rig, the HUD (dialogue box) and the environment.
##
## The root is named "World" so /root/World/HUD/DialogueBox and the Director's node paths resolve
## exactly as they do in src/world/world.tscn.
##
##   tools/capture.sh showcase/npc_talk.tscn npc_talk 320 tests/director/npc_talk.json
## User args: --planet=<id> (default zorp) · --npc=<id> (default the planet's first neighbour)

const PLANET_SCENE := "res://src/planet/planet.tscn"
const ENV_SCENE := "res://src/world/environment.tscn"
const PLAYER_SCENE := "res://src/player/player.tscn"
const CAMERA_SCENE := "res://src/player/camera_rig.tscn"
const HUD_SCENE := "res://src/ui/hud/hud.tscn"
const NPC_DIR := "res://src/characters/npcs/"
const DEFAULT_PLANET := "zorp"

var planet: Planet
var player: Node3D


func _ready() -> void:
	name = "World"
	var planet_id := DEFAULT_PLANET
	var npc_override := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--planet="):
			planet_id = a.substr(9)
		elif a.begins_with("--npc="):
			npc_override = a.substr(6)
	GameState.current_planet_id = planet_id

	var data := _load_planet_data(planet_id)
	_spawn_planet(data)
	_spawn_optional(ENV_SCENE, "Environment")
	_spawn_player(data)
	_spawn_optional(CAMERA_SCENE, "CameraRig")
	_spawn_npcs(data, npc_override)
	_spawn_optional(HUD_SCENE, "HUD")
	EventBus.planet_loaded.emit(planet_id)


func _load_planet_data(planet_id: String) -> PlanetData:
	var path := "res://src/planet/data/%s.tres" % planet_id
	if ResourceLoader.exists(path):
		return load(path) as PlanetData
	var d := PlanetData.new()
	d.id = planet_id
	return d


func _spawn_planet(data: PlanetData) -> void:
	if ResourceLoader.exists(PLANET_SCENE):
		planet = load(PLANET_SCENE).instantiate()
	else:
		planet = Planet.new()
	planet.name = "Planet"
	planet.data = data
	add_child(planet)


func _spawn_player(data: PlanetData) -> void:
	if not ResourceLoader.exists(PLAYER_SCENE):
		return
	player = load(PLAYER_SCENE).instantiate()
	player.name = "Player"
	add_child(player)
	if player is PlanetBody:
		(player as PlanetBody).planet = planet
		(player as PlanetBody).place_on_planet(data.spawn_dir.normalized())
	EventBus.player_spawned.emit(player)


func _spawn_npcs(data: PlanetData, npc_override: String) -> void:
	var root := Node3D.new()
	root.name = "NPCs"
	add_child(root)
	var ids: Array = []
	if npc_override != "":
		ids = [npc_override]
	else:
		for n in data.npcs:
			ids.append(String(n))
	if ids.is_empty():
		ids = ["zorp"]
	for npc_id: String in ids:
		var path := NPC_DIR + npc_id + ".tscn"
		if not ResourceLoader.exists(path):
			continue
		var n: Node = load(path).instantiate()
		n.name = npc_id
		root.add_child(n)
		if n is PlanetBody:
			(n as PlanetBody).planet = planet


func _spawn_optional(path: String, node_name: String) -> Node:
	if not ResourceLoader.exists(path):
		return null
	var n: Node = load(path).instantiate()
	n.name = node_name
	add_child(n)
	return n
