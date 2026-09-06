extends Node3D
## Decorating sandbox: the home planet, the real player + camera + HUD + environment, and the
## DecorationManager, assembled with the same node names as src/world/world.tscn (root "World") so
## tests/director/deco_flow.json drives it exactly like the shipping game.
##
##   godot --path . res://showcase/decorate_flow.tscn -- --skip-title
##   tools/capture.sh showcase/decorate_flow.tscn deco_flow 420 tests/director/deco_flow.json
##
## Flags: `--keep` keeps the current save state instead of starting a fresh bag,
## `--time=H` sets the clock (the Director understands this too),
## `--probe` prints how much of the planet is placeable and finds a roomy clearing for the timeline,
## `--save-test` places three decorations, saves, wipes GameState, loads and rebuilds the decoration
## layer from scratch, then reports the position error (the persistence round trip).

const PLANET_SCENE := "res://src/planet/planet.tscn"
const PLANET_DATA := "res://src/planet/data/home.tres"
const ENV_SCENE := "res://src/world/environment.tscn"
const PLAYER_SCENE := "res://src/player/player.tscn"
const CAMERA_SCENE := "res://src/player/camera_rig.tscn"
const DECO_SCENE := "res://src/decorations/decoration_manager.tscn"
const HUD_SCENE := "res://src/ui/hud/hud.tscn"

## A bag with enough variety to exercise the grid, the tabs and repeat placements.
const TEST_BAG := {
	"deco_crater_bench": 2,
	"deco_moon_lamp": 2,
	"deco_star_flag": 2,
	"deco_string_lights": 2,
	"deco_ufo_planter": 2,
	"deco_robot_statue": 2,
	"deco_meteor_rock": 2,
	"stardust_shard": 3,
}

var planet: Planet
var player: Node3D


func _ready() -> void:
	name = "World"
	var keep := false
	for a in OS.get_cmdline_user_args():
		if a == "--keep":
			keep = true
	GameState.current_planet_id = "home"
	if not keep:
		GameState.reset_new_game()
		for id in TEST_BAG:
			GameState.inventory[id] = int(TEST_BAG[id])
		GameState.stardust = 640
	_spawn_planet()
	_spawn_optional(ENV_SCENE, "Environment")
	_spawn_player()
	_spawn_optional(CAMERA_SCENE, "CameraRig")
	_spawn_optional(DECO_SCENE, "Decorations")
	_spawn_optional(HUD_SCENE, "HUD")
	EventBus.planet_loaded.emit("home")
	for a in OS.get_cmdline_user_args():
		if a == "--probe":
			_probe.call_deferred()
		elif a == "--save-test":
			_save_round_trip.call_deferred()


## Prints how much of the planet is actually placeable and why the rest is not (`--probe`).
func _probe() -> void:
	var mgr := get_node_or_null("Decorations") as DecorationManager
	if mgr == null:
		return
	var counts := {"": 0, "water": 0, "shore": 0, "slope": 0, "reserved": 0, "prop": 0, "crowded": 0, "npc": 0}
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	for i in 2000:
		var d := Vector3(rng.randfn(), rng.randfn(), rng.randfn()).normalized()
		var reason := mgr.spot_block_reason(d, 0.8)
		counts[reason] = int(counts.get(reason, 0)) + 1
	print("PROBE free=%d water=%d shore=%d slope=%d reserved=%d prop=%d crowded=%d npc=%d of 2000" % [counts[""], counts["water"], counts["shore"], counts["slope"], counts["reserved"], counts["prop"], counts["crowded"], counts["npc"]])
	if player:
		var ahead: Vector3 = player.global_position + player.surface_forward() * PlacementController.FORWARD_DIST
		print("PROBE spawn-forward spot: '%s'" % mgr.spot_block_reason(planet.dir_of(ahead), 0.95))
	# Find a roomy, level clearing: free for a 0.95 m footprint here and 3 m out in every direction.
	var spawn_dir: Vector3 = planet.data.spawn_dir.normalized()
	var best := Vector3.ZERO
	var best_score := -1.0
	for i in 4000:
		var d := Vector3(rng.randfn(), rng.randfn(), rng.randfn()).normalized()
		if mgr.spot_block_reason(d, 1.1) != "":
			continue
		var t1 := d.cross(Vector3.UP).normalized()
		var t2 := d.cross(t1).normalized()
		var ok := true
		var flat := 0.0
		for ring in [2.5, 4.0, 5.5, 6.8]:
			for k in 10:
				var a := TAU * float(k) / 10.0
				var ang: float = float(ring) / planet.radius
				var nd := (d * cos(ang) + (t1 * cos(a) + t2 * sin(a)) * sin(ang)).normalized()
				if mgr.spot_block_reason(nd, 1.1) != "":
					ok = false
					break
				flat += absf(planet.height_at(nd) - planet.height_at(d))
			if not ok:
				break
		if not ok:
			continue
		# prefer clearings close to the spawn (short walk) and level
		var score := 10.0 - flat - absf(planet.surface_distance(d, spawn_dir) - 9.0) * 0.35
		if score > best_score:
			best_score = score
			best = d
	print("PROBE clearing dir = [%.4f, %.4f, %.4f]  score=%.2f  dist_from_spawn=%.1f m" % [best.x, best.y, best.z, best_score, planet.surface_distance(best, spawn_dir)])


func _spawn_planet() -> void:
	planet = load(PLANET_SCENE).instantiate()
	planet.name = "Planet"
	planet.data = load(PLANET_DATA)
	add_child(planet)


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


func _spawn_optional(path: String, node_name: String) -> Node:
	if not ResourceLoader.exists(path):
		push_warning("decorate_flow: missing %s" % path)
		return null
	var n: Node = load(path).instantiate()
	n.name = node_name
	add_child(n)
	return n


## Places three decorations, saves, wipes GameState, loads, rebuilds the Decorations node from
## scratch and checks all three came back in exactly the same place (`--save-test`).
func _save_round_trip() -> void:
	await get_tree().process_frame
	var mgr := get_node_or_null("Decorations") as DecorationManager
	if mgr == null:
		print("SAVETEST FAIL: no Decorations node")
		return
	var base: Vector3 = Vector3(0.7581, 0.6086, -0.2343).normalized()
	var t1 := base.cross(Vector3.UP).normalized()
	var t2 := base.cross(t1).normalized()
	var want: Array = []
	var ids: Array = []
	var trio := ["deco_moon_lamp", "deco_star_flag", "deco_meteor_rock"]
	for i in 3:
		var ang := 3.4 / planet.radius
		var a := TAU * float(i) / 3.0
		var d := (base * cos(ang) + (t1 * cos(a) + t2 * sin(a)) * sin(ang)).normalized()
		if not mgr.is_spot_free(d, DecorationManager.footprint_for(trio[i])):
			print("SAVETEST FAIL: spot %d blocked (%s)" % [i, mgr.spot_block_reason(d, 0.8)])
			return
		var id := mgr.place(trio[i], d, float(i) * 0.5)
		ids.append(id)
		want.append(mgr.get_instances().back()["node"].global_transform)
	print("SAVETEST placed %d: %s" % [mgr.get_instances().size(), str(ids)])
	if not SaveManager.save_game():
		print("SAVETEST FAIL: save_game() returned false")
		return
	GameState.reset_new_game()
	var wiped: int = (GameState.placed_decorations.get("home", []) as Array).size()
	if not SaveManager.load_game():
		print("SAVETEST FAIL: load_game() returned false")
		return
	var restored_records: int = (GameState.placed_decorations.get("home", []) as Array).size()
	# rebuild the world's decoration layer from scratch, exactly like changing planets
	mgr.free()
	var fresh: Node = load(DECO_SCENE).instantiate()
	fresh.name = "Decorations"
	add_child(fresh)
	await get_tree().process_frame
	var mgr2 := fresh as DecorationManager
	var got: Array = mgr2.get_instances()
	var ok := got.size() == 3 and wiped == 0 and restored_records == 3
	var max_err := 0.0
	for i in got.size():
		var node: Node3D = got[i]["node"]
		var best := INF
		for w in want:
			best = minf(best, node.global_position.distance_to((w as Transform3D).origin))
		max_err = maxf(max_err, best)
	if max_err > 0.001:
		ok = false
	print("SAVETEST wiped=%d records_after_load=%d respawned=%d max_pos_error=%.6f m -> %s" % [wiped, restored_records, got.size(), max_err, "PASS" if ok else "FAIL"])
	SaveManager.delete_save()
