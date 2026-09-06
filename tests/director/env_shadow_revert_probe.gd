extends Node
## Proves the head/helmet cast-shadow workarounds can be reverted now that the soft-shadow
## penumbra dithering is fixed (docs/OPEN_ISSUES.md issue 1).
##
## Injected by a Director "call" step
## ({"call": {"node": "/root/World", "method": "_spawn_optional",
##            "args": ["res://tests/director/env_shadow_revert_probe.tscn", "ShadowRevert"]}}).
##
## Turns every cast_shadow back ON at RUNTIME instead of editing the player and character builders'
## files, so this test never touches src/player/ or src/characters/. Emissive face decals and the
## fake blob shadow stay off — those are not the workaround.

## Node names whose shadow must stay off: face decals, the visor glass/streak, the blob shadow.
const KEEP_OFF := ["Glass", "Streak", "Logo", "BlobShadow", "Shadow", "Face", "Eye", "Mouth",
	"Brow", "Blush", "Pupil", "Nose"]

var _restored := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("ENVREVERT probe ready (call revert_all to drop the workarounds)")


## Drops both cast-shadow workarounds: the NPC head-shadow cheat and the astronaut's helmet shell.
## The Director calls this (or not) so the same timeline can capture a control and a revert.
func revert_all() -> void:
	for npc: Node in get_tree().get_nodes_in_group("npc"):
		_flip_chibi(npc)
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		_restore(player)
	print("ENVREVERT cast_shadow restored on %d meshes" % _restored)


## Teleports the first wandering NPC to a spot just beside the player and freezes it, so a close-up
## capture is guaranteed to contain a neighbour's head instead of an empty plaza.
func bring_npc_close() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	var npcs := get_tree().get_nodes_in_group("npc")
	if player == null or npcs.is_empty():
		print("ENVREVERT no npc to move (player=%s npcs=%d)" % [player != null, npcs.size()])
		return
	var npc := npcs[0] as Node3D
	if npc.has_method("wander_enabled"):
		npc.call("wander_enabled", false)
	var planet: Node = player.get("planet")
	if planet == null or not npc.has_method("teleport_to_dir"):
		print("ENVREVERT cannot teleport npc")
		return
	var dir: Vector3 = player.global_position.normalized()
	var side := dir.cross(Vector3.UP).normalized()
	if side.length_squared() < 0.01:
		side = dir.cross(Vector3.RIGHT).normalized()
	npc.call("teleport_to_dir", (dir + side * 0.09).normalized())
	print("ENVREVERT moved %s next to the player" % npc.name)


## Calls ChibiModel.set_head_shadow_cheat(false) wherever the character builder exposed it.
func _flip_chibi(root: Node) -> void:
	if root.has_method("set_head_shadow_cheat"):
		root.call("set_head_shadow_cheat", false)
		print("ENVREVERT head_shadow_cheat off on %s" % root.name)
	for c: Node in root.get_children():
		_flip_chibi(c)


## Recursively re-enables cast_shadow, skipping the decals and the fake blob shadow.
func _restore(root: Node) -> void:
	if root is GeometryInstance3D:
		var skip := false
		for k in KEEP_OFF:
			if root.name.contains(k):
				skip = true
				break
		if not skip and (root as GeometryInstance3D).cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
			(root as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			_restored += 1
			print("ENVREVERT   + %s" % root.name)
	for c: Node in root.get_children():
		_restore(c)
