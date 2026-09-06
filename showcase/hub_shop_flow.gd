extends Node3D
## Playable Starport Plaza sandbox: the hub planet, the real player + camera + HUD + environment and
## all four hub buildings, assembled with the same node names as src/world/world.gd (root "World")
## so tests/director/hub_shop_flow.json drives it exactly like the shipping game.
##
##   godot --path . res://showcase/hub_shop_flow.tscn -- --skip-title
##   tools/capture.sh showcase/hub_shop_flow.tscn hub_flow 560 tests/director/hub_shop_flow.json
##   tools/capture.sh src/world/world.tscn hub_world 560 tests/director/hub_shop_flow.json --new-game --planet=hub
##
## Flags: `--keep` keeps the current save state instead of a fresh purse, `--time=H` sets the clock.

const PLANET_SCENE := "res://src/planet/planet.tscn"
const PLANET_DATA := "res://src/planet/data/hub.tres"
const ENV_SCENE := "res://src/world/environment.tscn"
const PLAYER_SCENE := "res://src/player/player.tscn"
const CAMERA_SCENE := "res://src/player/camera_rig.tscn"
const HUD_SCENE := "res://src/ui/hud/hud.tscn"
const BUILDING_DIR := "res://src/hub/buildings/"

## Enough stardust to actually shop, and a couple of sellable items for the Sell tab.
const TEST_STARDUST := 1600
const TEST_BAG := {"deco_moon_lamp": 2, "deco_star_flag": 1, "stardust_shard": 3}

var planet: Planet
var player: Node3D


func _ready() -> void:
	name = "World"
	var keep := false
	for a in OS.get_cmdline_user_args():
		if a == "--keep":
			keep = true
	GameState.current_planet_id = "hub"
	if not keep:
		GameState.reset_new_game()
		GameState.current_planet_id = "hub"
		GameState.stardust = TEST_STARDUST
		for id: String in TEST_BAG:
			GameState.inventory[id] = int(TEST_BAG[id])

	planet = load(PLANET_SCENE).instantiate()
	planet.name = "Planet"
	planet.data = load(PLANET_DATA)
	add_child(planet)

	_spawn_optional(ENV_SCENE, "Environment")
	_spawn_player()
	_spawn_optional(CAMERA_SCENE, "CameraRig")
	_spawn_buildings()
	_spawn_optional(HUD_SCENE, "HUD")

	AudioManager.play_music(planet.data.music_track)
	EventBus.planet_loaded.emit("hub")


func _spawn_player() -> void:
	if not ResourceLoader.exists(PLAYER_SCENE):
		return
	player = load(PLAYER_SCENE).instantiate()
	player.name = "Player"
	add_child(player)
	if player is PlanetBody:
		player.planet = planet
		player.place_on_planet(planet.data.spawn_dir.normalized())
	EventBus.player_spawned.emit(player)


func _spawn_buildings() -> void:
	var root := Node3D.new()
	root.name = "Buildings"
	add_child(root)
	for bid in planet.data.buildings:
		var p := BUILDING_DIR + bid + ".tscn"
		if not ResourceLoader.exists(p):
			push_warning("hub_shop_flow: missing %s" % p)
			continue
		var n: Node = load(p).instantiate()
		n.name = bid
		root.add_child(n)
		if n.has_method("attach_to_planet"):
			n.attach_to_planet(planet)


func _spawn_optional(path: String, node_name: String) -> Node:
	if not ResourceLoader.exists(path):
		push_warning("hub_shop_flow: missing %s" % path)
		return null
	var n: Node = load(path).instantiate()
	n.name = node_name
	add_child(n)
	return n
