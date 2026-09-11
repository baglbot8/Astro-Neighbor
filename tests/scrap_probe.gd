extends Node
## THROWAWAY verification probe for BUILD_PLAN Phase 1 "D: scrap and economy" - not part of the
## shipped game. Loads the real world scene under the real GameState/Director autoloads (so
## --new-game / --campaign / --planet= behave exactly as they do in real play), waits for the
## planet's collectibles to spawn, and prints each one's kind + global_position (and the direction
## from planet center, which is what Player.teleport_to_dir expects) so a Director timeline can
## teleport straight to a real spawn point instead of guessing where to walk.
##
##   godot --headless --path . res://tests/scrap_probe.tscn -- --new-game --campaign --planet=home --quit-at=3

func _ready() -> void:
	var world: Node = load("res://src/world/world.tscn").instantiate()
	add_child(world)
	await get_tree().create_timer(1.5).timeout
	var planet := get_tree().get_first_node_in_group("planet") as Node3D
	for c in get_tree().get_nodes_in_group("collectibles"):
		var pos: Vector3 = c.global_position
		var dir := (pos - planet.global_position).normalized() if planet else Vector3.ZERO
		print("SCRAPPROBE name=%s kind=%s pos=%s dir=%s" % [c.name, c.kind, pos, dir])
	for t in get_tree().get_nodes_in_group("trash_pieces"):
		var tpos: Vector3 = t.global_position
		var tdir := (tpos - planet.global_position).normalized() if planet else Vector3.ZERO
		print("SCRAPPROBE name=%s trash pos=%s dir=%s" % [t.name, tpos, tdir])
	print("SCRAPPROBE stardust=%d scrap=%d" % [GameState.stardust, GameState.scrap])
	get_tree().quit(0)
