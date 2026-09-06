class_name TrashSystem
extends Node3D
## Space junk that piles up on the HOME planet while nobody visits it (docs/ARCHITECTURE.md §11).
## `/root/World/TrashField`, spawned by world.gd only when a scene exists at TRASH_SYSTEM_SCENE.
## A no-op node on every planet except home — trash only ever lives at home.
##
## Real-time pacing: every time the world loads home, this checks how many real seconds passed since
## GameState.trash_last_check_unix and drops one new piece per SECONDS_PER_TRASH, capped at MAX_TRASH.
## That is the whole simulation — there is no per-frame timer, so trash only ever appears to have
## piled up "since you last looked", exactly like Animal Crossing's weeds.

const SECONDS_PER_TRASH := 900.0   # 15 real minutes away from home = 1 new piece
const MAX_TRASH := 10
const CLEARANCE_M := 0.6

var planet: Planet
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	if GameState.current_planet_id != "home":
		return   # trash only exists at home; every other planet stays untouched
	planet = get_tree().get_first_node_in_group("planet")
	if planet == null:
		return
	_rng.randomize()
	_catch_up()
	_rebuild()


## Adds however many pieces should have landed since the last time anyone checked, then resets the
## clock. Silently stops early if the planet runs out of free spots (crowded home) rather than error.
func _catch_up() -> void:
	var now := Time.get_unix_time_from_system()
	var elapsed := maxf(0.0, now - GameState.trash_last_check_unix)
	GameState.trash_last_check_unix = now
	var room := MAX_TRASH - GameState.trash_home.size()
	var new_count := mini(room, int(floor(elapsed / SECONDS_PER_TRASH)))
	for i in new_count:
		var dir := planet.find_free_dir(_rng, CLEARANCE_M, 40, true)
		if dir == Vector3.ZERO:
			break
		var kind: String = TrashPiece.KINDS[_rng.randi_range(0, TrashPiece.KINDS.size() - 1)]
		GameState.add_trash("trash_%d_%d" % [int(now), i], dir, kind)


func _rebuild() -> void:
	for c in get_children():
		c.queue_free()
	for entry in GameState.trash_home:
		_spawn(entry)


func _spawn(entry: Dictionary) -> void:
	var dir: Vector3 = GameState.vec3_from_array(entry.get("dir", [0.0, 1.0, 0.0])).normalized()
	var piece := TrashPiece.new()
	piece.setup(str(entry.get("kind", "can")), str(entry.get("id", "")))
	add_child(piece)
	piece.transform = planet.surface_transform(dir, Vector3.FORWARD)
