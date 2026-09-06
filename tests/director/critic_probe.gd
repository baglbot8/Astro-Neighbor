extends Node
## Critic probe: injected into /root/World by a Director "call" step
## ({"call": {"node": "/root/World", "method": "_spawn_optional", "args": ["res://tests/director/critic_probe.tscn", "Probe"]}}).
## Prints EventBus modal balance, tree pause state, player position, save file state, and hooks UI signals.

var _hud: Node
var _player: Node3D

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_hud = get_node_or_null("/root/World/HUD")
	_player = get_node_or_null("/root/World/Player") as Node3D
	if _hud != null:
		var inv: Node = _hud.get_node_or_null("Inventory")
		if inv != null and inv.has_signal("item_chosen"):
			inv.connect("item_chosen", func(id: String, action: String) -> void: print("PROBE item_chosen id=%s action=%s" % [id, action]))
		if inv != null and inv.has_signal("closed"):
			inv.connect("closed", func() -> void: print("PROBE inventory closed"))
		var pm: Node = _hud.get_node_or_null("PauseMenu")
		if pm != null and pm.has_signal("closed"):
			pm.connect("closed", func() -> void: print("PROBE pause closed"))
		var db: Node = _hud.get_node_or_null("DialogueBox")
		if db != null and db.has_signal("choice_made"):
			db.connect("choice_made", func(i: int) -> void: print("PROBE choice_made %d" % i))
	EventBus.ui_modal_opened.connect(func(n: String) -> void: print("PROBE modal_opened %s count=%d" % [n, EventBus._modal_count]))
	EventBus.ui_modal_closed.connect(func(n: String) -> void: print("PROBE modal_closed %s count=%d" % [n, EventBus._modal_count]))
	EventBus.game_saved.connect(func() -> void: print("PROBE game_saved signal"))
	print("PROBE ready hud=%s player=%s" % [_hud != null, _player != null])
	report("ready")

## Prints a one-line status snapshot.
func report(tag: String = "") -> void:
	var pos := Vector3.ZERO
	if _player != null:
		pos = _player.global_position
	var save_path := "user://astro_neighbor_save.json"
	var mtime := 0
	if FileAccess.file_exists(save_path):
		mtime = FileAccess.get_modified_time(save_path)
	var input_enabled: Variant = _player.get("input_enabled") if _player != null else null
	print("PROBE report[%s] modal_count=%d is_modal_open=%s paused=%s player_pos=%s input_enabled=%s music=%s save_mtime=%d" % [
		tag, EventBus._modal_count, EventBus.is_modal_open(), get_tree().paused, pos, str(input_enabled),
		str(GameState.settings.get("music_volume")), mtime])

## Starts a dialogue choice and prints the awaited result (expect -1 after cancel).
func start_choice() -> void:
	if _hud == null:
		return
	var db: Node = _hud.get_node_or_null("DialogueBox")
	if db == null:
		return
	var r: int = await db.show_choice("Probe question?", ["Alpha", "Beta"])
	print("PROBE show_choice returned %d" % r)

## Starts a lines dialogue and prints when `finished` resolves.
func start_lines() -> void:
	if _hud == null:
		return
	var db: Node = _hud.get_node_or_null("DialogueBox")
	if db == null:
		return
	await db.show_lines("Probe", ["Line one.", "Line two."], "robot")
	print("PROBE show_lines finished")
