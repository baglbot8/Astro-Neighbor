extends Node3D
## Main gameplay scene. Assembles the current planet from GameState.current_planet_id.
## Node layout (fixed — other systems and the Director rely on these paths):
##   /root/World
##     Planet         (Planet)            built from res://src/planet/data/<id>.tres
##     Environment    (Node3D)            sky, sun, fog, day/night  -> res://src/world/environment.tscn
##     Player         (Player)            res://src/player/player.tscn
##     CameraRig      (Node3D)            res://src/player/camera_rig.tscn
##     NPCs           (Node3D)            children named by npc id, res://src/characters/npcs/<id>.tscn
##     Buildings      (Node3D)            hub buildings, res://src/hub/buildings/<id>.tscn
##     Decorations    (Node3D)            placed decorations (DecorationManager) res://src/decorations/decoration_manager.tscn
##     TrashField     (Node3D)            home-planet junk (TrashSystem, no-op elsewhere) res://src/planet/trash_system.tscn
##     Rocket         (Node3D)            landing pad + rocket, res://src/rocket/rocket_pad.tscn
##     HUD            (CanvasLayer)       res://src/ui/hud/hud.tscn
## Each optional piece is loaded only if its scene exists, so the world runs while pieces are still being built.

const PLANET_SCENE := "res://src/planet/planet.tscn"
const ENV_SCENE := "res://src/world/environment.tscn"
const PLAYER_SCENE := "res://src/player/player.tscn"
const CAMERA_SCENE := "res://src/player/camera_rig.tscn"
const DECO_MANAGER_SCENE := "res://src/decorations/decoration_manager.tscn"
const TRASH_SYSTEM_SCENE := "res://src/planet/trash_system.tscn"
const ROCKET_PAD_SCENE := "res://src/rocket/rocket_pad.tscn"
const HUD_SCENE := "res://src/ui/hud/hud.tscn"
## Phase 2 (docs/BUILD_PLAN.md, builder F): the build bench at the crash site on home. Added by the
## lead ahead of Phase 2 so F owns only its own files; _spawn_optional skips it until the scene exists.
const BUILD_BENCH_SCENE := "res://src/projects/build_bench.tscn"
## Phase 2 builder N: the short cutscene when a rocket part is fitted (it listens for
## EventBus.rocket_part_fitted). Home only - the bench and the rocket are both at the crash site.
const PART_CELEBRATION_SCENE := "res://src/campaign/part_celebration.tscn"
const NPC_DIR := "res://src/characters/npcs/"
const BUILDING_DIR := "res://src/hub/buildings/"

var planet: Planet
var player: Node3D
var camera_rig: Node3D
var planet_data: PlanetData

func _ready() -> void:
	name = "World"
	var pid := GameState.current_planet_id
	var data_path := "res://src/planet/data/%s.tres" % pid
	if ResourceLoader.exists(data_path):
		planet_data = load(data_path)
	else:
		push_warning("World: no PlanetData for '%s', using defaults" % pid)
		planet_data = PlanetData.new()
		planet_data.id = pid

	_spawn_planet()
	_spawn_optional(ENV_SCENE, "Environment")
	_spawn_player()
	_spawn_optional(CAMERA_SCENE, "CameraRig")
	_spawn_npcs()
	_spawn_buildings()
	_spawn_optional(ROCKET_PAD_SCENE, "Rocket")
	_spawn_optional(DECO_MANAGER_SCENE, "Decorations")
	_spawn_optional(TRASH_SYSTEM_SCENE, "TrashField")
	if pid == "home":
		_spawn_optional(BUILD_BENCH_SCENE, "BuildBench")
		_spawn_optional(PART_CELEBRATION_SCENE, "PartCelebration")
	_spawn_optional(HUD_SCENE, "HUD")
	_spawn_optional("res://src/onboarding/onboarding.tscn", "Onboarding")  # ADDED BY THE ONBOARDING BUILDER

	if planet_data.music_track != "":
		AudioManager.play_music(planet_data.music_track)
	EventBus.planet_loaded.emit(pid)

func _spawn_planet() -> void:
	if ResourceLoader.exists(PLANET_SCENE):
		planet = load(PLANET_SCENE).instantiate()
	else:
		planet = Planet.new()
	planet.name = "Planet"
	planet.data = planet_data
	add_child(planet)

func _spawn_player() -> void:
	if not ResourceLoader.exists(PLAYER_SCENE):
		return
	player = load(PLAYER_SCENE).instantiate()
	player.name = "Player"
	add_child(player)
	if player is PlanetBody:
		player.planet = planet
		var spawn_at_pad: bool = GameState.flag("spawn_at_pad") and GameState.previous_planet_id != ""
		var dir: Vector3 = planet_data.pad_dir if spawn_at_pad else planet_data.spawn_dir
		if spawn_at_pad:
			# Step off the pad a little so we don't spawn inside the rocket.
			var side := dir.normalized().cross(Vector3.UP)
			if side.length_squared() < 0.01:
				side = Vector3.RIGHT
			dir = (dir.normalized() + side.normalized() * (3.2 / planet_data.radius)).normalized()
		player.place_on_planet(dir.normalized())
	EventBus.player_spawned.emit(player)

func _spawn_optional(path: String, node_name: String) -> Node:
	if not ResourceLoader.exists(path):
		return null
	var n: Node = load(path).instantiate()
	n.name = node_name
	add_child(n)
	return n

func _spawn_npcs() -> void:
	var root := Node3D.new()
	root.name = "NPCs"
	add_child(root)
	for npc_id in planet_data.npcs:
		var p := NPC_DIR + npc_id + ".tscn"
		if not ResourceLoader.exists(p):
			push_warning("World: missing npc scene " + p)
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
			push_warning("World: missing building scene " + p)
			continue
		var n: Node = load(p).instantiate()
		n.name = bid
		root.add_child(n)
		if n.has_method("attach_to_planet"):
			n.attach_to_planet(planet)
