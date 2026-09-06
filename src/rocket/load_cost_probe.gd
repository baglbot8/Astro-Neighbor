extends Node3D
## Test rig, not part of the game. Answers ONE question: where do the ~400-850 ms of
## `src/world/world.gd::_ready()` go?
##
## That single frame is the whole of the rocket journey's arrival freeze (measured 668 ms landing on
## Zorp, 854 ms on the hub) and world.gd belongs to the orchestrator, so this reproduces its build
## order piece by piece in a scene the rocket builder owns and times each step. The root is named
## "World" and sits at /root/World precisely so every piece resolves the node paths it expects.
##
## Inert unless `--loadcost` is passed, so `tools/check.sh` can run it like any other showcase:
##   godot --path . res://showcase/rocket_loadcost.tscn -- --loadcost --planet=zorp --quit-at=6

const PLANET_SCENE := "res://src/planet/planet.tscn"
const ENV_SCENE := "res://src/world/environment.tscn"
const PLAYER_SCENE := "res://src/player/player.tscn"
const CAMERA_SCENE := "res://src/player/camera_rig.tscn"
const DECO_MANAGER_SCENE := "res://src/decorations/decoration_manager.tscn"
const TRASH_SYSTEM_SCENE := "res://src/planet/trash_system.tscn"
const ROCKET_PAD_SCENE := "res://src/rocket/rocket_pad.tscn"
const HUD_SCENE := "res://src/ui/hud/hud.tscn"
const ONBOARDING_SCENE := "res://src/onboarding/onboarding.tscn"
const NPC_DIR := "res://src/characters/npcs/"
const BUILDING_DIR := "res://src/hub/buildings/"

var planet: Node3D
var planet_data: PlanetData
var _t := 0
var _total := 0.0


func _ready() -> void:
	name = "World"
	if not OS.get_cmdline_user_args().has("--loadcost"):
		return
	var pid := GameState.current_planet_id
	var data_path := "res://src/planet/data/%s.tres" % pid
	planet_data = load(data_path) if ResourceLoader.exists(data_path) else PlanetData.new()
	_build_all(pid, "COLD")
	# The journey's arrival is WARM for everything except the destination's own geometry: the player,
	# the pad, the HUD and every shader were already resident in the world we just left. A second
	# build with the caches hot is therefore the honest model of the arrival stall.
	await get_tree().process_frame
	for c in get_children():
		remove_child(c)
		c.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	_build_all(pid, "WARM")


func _build_all(pid: String, tag: String) -> void:
	_total = 0.0
	print("LOADCOST %s planet=%s ---------------------------------" % [tag, pid])
	_t = Time.get_ticks_usec()
	_spawn_planet()
	_lap("planet")
	_spawn(ENV_SCENE, "Environment")
	_lap("environment")
	_spawn_player()
	_lap("player")
	_spawn(CAMERA_SCENE, "CameraRig")
	_lap("camera_rig")
	_spawn_npcs()
	_lap("npcs")
	_spawn_buildings()
	_lap("buildings")
	_spawn(ROCKET_PAD_SCENE, "Rocket")
	_lap("rocket_pad")
	_spawn(DECO_MANAGER_SCENE, "Decorations")
	_lap("decorations")
	_spawn(TRASH_SYSTEM_SCENE, "TrashField")
	_lap("trash")
	_spawn(HUD_SCENE, "HUD")
	_lap("hud")
	_spawn(ONBOARDING_SCENE, "Onboarding")
	_lap("onboarding")
	print("LOADCOST %-14s %8.1f ms" % ["TOTAL", _total])
	EventBus.planet_loaded.emit(pid)


func _lap(what: String) -> void:
	var now := Time.get_ticks_usec()
	var ms := float(now - _t) / 1000.0
	_total += ms
	_t = now
	print("LOADCOST %-14s %8.1f ms" % [what, ms])


func _spawn(path: String, node_name: String) -> Node:
	if not ResourceLoader.exists(path):
		return null
	var t0 := Time.get_ticks_usec()
	var packed: PackedScene = load(path)
	var t1 := Time.get_ticks_usec()
	var n: Node = packed.instantiate()
	n.name = node_name
	add_child(n)
	print("LOADCOST   %-12s resload=%6.1f  build=%6.1f ms" % [node_name,
		(t1 - t0) / 1000.0, (Time.get_ticks_usec() - t1) / 1000.0])
	return n


func _spawn_planet() -> void:
	planet = load(PLANET_SCENE).instantiate()
	planet.name = "Planet"
	planet.set("data", planet_data)
	add_child(planet)


func _spawn_player() -> void:
	var p: Node = load(PLAYER_SCENE).instantiate()
	p.name = "Player"
	add_child(p)
	if p is PlanetBody:
		p.planet = planet
		p.place_on_planet(planet_data.spawn_dir.normalized())


func _spawn_npcs() -> void:
	var root := Node3D.new()
	root.name = "NPCs"
	add_child(root)
	for npc_id in planet_data.npcs:
		var p := NPC_DIR + npc_id + ".tscn"
		if not ResourceLoader.exists(p):
			continue
		var n: Node = load(p).instantiate()
		n.name = npc_id
		root.add_child(n)
		if n is PlanetBody:
			n.planet = planet


func _spawn_buildings() -> void:
	var root := Node3D.new()
	root.name = "Buildings"
	add_child(root)
	for bid in planet_data.buildings:
		var p := BUILDING_DIR + bid + ".tscn"
		if not ResourceLoader.exists(p):
			continue
		var n: Node = load(p).instantiate()
		n.name = bid
		root.add_child(n)
		if n.has_method("attach_to_planet"):
			n.attach_to_planet(planet)
