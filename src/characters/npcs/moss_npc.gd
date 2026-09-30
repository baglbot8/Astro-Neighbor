class_name MossNPC
extends NPC
## MOSS, the swamp-folk shopkeeper of The Tangle (docs/JUNGLE_PLANET_SPEC.md 3, builder J3).
##
## NOT A NEIGHBOUR, and built the way Gloop is (gloop_npc.gd) so that nothing neighbour-shaped can
## reach it:
##   * NO npc_data.gd ENTRY. `NpcData.ids()` is what the favour system walks to pick a delivery target
##     (favor_system.gd `_delivery_target`), so an entry would let a favour send the player to a locked
##     planet to hand a gift to a shopkeeper. No entry also means no friendship tier lines, no
##     visitor, no finale seat and no project can ever name Moss.
##   * NO Conversation.run. That flow is favours, projects, friendship rolls and small talk; pressing on
##     Moss runs the stall's own flow instead (MossStall.run_flow): a greeting, the shelf, and - once a
##     day - the jungle safari offer through the same PlanetSafari hook every neighbour's talk uses.
##   * NO "!". There is never anything to hand in.
##   * HOME is wherever the stall put Moss, and Moss does not wander: a stallholder stands at the stall.

## Unit direction on the planet where Moss stands. Set by moss_stall.gd before `add_child`.
var stall_home: Vector3 = Vector3.UP
## The stall Moss keeps. Set by moss_stall.gd.
var stall: Node = null


func _ready() -> void:
	npc_id = "moss"
	display_name = MossLines.NAME
	voice_profile = MossLines.VOICE
	accent_color = MossLines.ACCENT
	wander_radius_m = 0.0
	walk_speed = 1.0
	super._ready()
	# MOSS2 (2026-09-30): wander_radius_m 0 did NOT keep Moss home - NPC._pick_wander_target walks at
	# least 1.4 m (`maxf(wander_radius_m, 1.6)`), and a portrait run caught him 1.5 m away behind the
	# reed bundle. A stallholder stands at the stall, so wandering is switched off outright.
	wander_enabled(false)


func _resolve_home_dir() -> Vector3:
	return stall_home.normalized()


## One press on Moss = one press on the stall.
func start_conversation(player: Player) -> void:
	if _conversation_running:
		return
	if stall == null or not is_instance_valid(stall):
		return
	_conversation_running = true
	set_talking(true)
	face_player(true)
	await stall.call("run_flow", player)
	set_talking(false)
	_has_face_target = false
	_conversation_running = false
	_refresh_marker()


## The stall calls this while its flow runs, so Moss looks at the player and talks.
func attend(player: Node3D) -> void:
	set_talking(true)
	if player != null:
		face_toward_point(player.global_position)


func release() -> void:
	set_talking(false)
	_has_face_target = false
	_refresh_marker()


## Never a "!": nothing is ever owed to or by a shopkeeper.
func _refresh_marker() -> void:
	if _marker != null:
		_marker.visible = false
