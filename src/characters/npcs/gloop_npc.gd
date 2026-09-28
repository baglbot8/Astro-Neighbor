class_name GloopNPC
extends NPC
## Gloop, the neighbour at the print table (sky-watching spike, 2026-09-20).
##
## A thin subclass, and only for three things the base NPC cannot do for a character that has no
## entry in `npc_data.gd` (a shared file this spike deliberately does not touch):
##
##   1. HOME. `_resolve_home_dir()` reads npc_data for everyone else; Gloop's spot is handed in by
##      the print table when it spawns this node (`spike_home`), and the wander radius is 0 — a
##      stallholder stands at the stall.
##   2. TALKING. `Conversation.run` is entirely npc_data-driven and would produce an empty box, so
##      pressing on Gloop runs the table's own four-step flow instead. Pressing on Gloop and
##      pressing on the table therefore do exactly the same thing, which is the point: one tap.
##   3. THE "!". The favour system has nothing to say about a neighbour it does not know, so the
##      marker is driven by the loop: prints in the satchel, or coins waiting on the table.

## Unit direction on the planet where Gloop stands. Set by `print_table.gd` before `add_child`.
var spike_home: Vector3 = Vector3.UP
## The table this neighbour works at. Set by `print_table.gd`.
var spike_table: Node = null


func _ready() -> void:
	npc_id = "gloop"
	display_name = GloopLines.NAME
	voice_profile = GloopLines.VOICE
	accent_color = GloopLines.ACCENT
	# A stallholder does not wander. Gloop shuffles in place and that is all.
	wander_radius_m = 0.0
	walk_speed = 1.2
	super._ready()


## Gloop's home is wherever the table put it, never npc_data's (there is no entry).
func _resolve_home_dir() -> Vector3:
	return spike_home.normalized()


## One press on Gloop = one press on the table. Guarded by the table's own `_busy`.
func start_conversation(player: Player) -> void:
	if _conversation_running:
		return
	if spike_table == null or not is_instance_valid(spike_table):
		return
	_conversation_running = true
	set_talking(true)
	face_player(true)
	await spike_table.call("run_flow", player)
	set_talking(false)
	_has_face_target = false
	_conversation_running = false
	_refresh_marker()


## The table calls this while a flow runs, so Gloop looks at the player and talks instead of
## standing there idling through its own payout.
func attend(player: Node3D) -> void:
	set_talking(true)
	if player != null:
		face_toward_point(player.global_position)
	if _model != null:
		_model.set_state("talk")


func release() -> void:
	set_talking(false)
	_has_face_target = false
	if _model != null:
		_model.set_state("idle")
	_refresh_marker()


## The "!" means "the loop has a step for you here": prints to hand in, or coins to collect.
func _refresh_marker() -> void:
	if _marker == null:
		return
	_marker.visible = not _talking and (PrintBag.payout_ready() or PrintBag.bag_count() > 0)
