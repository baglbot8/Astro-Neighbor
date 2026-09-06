extends Node
## Reproduces the reported soft-lock: play an emote in the same frame as a landing.
var _p: Node = null
var _t := 0.0
var _fired := false
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
func _physics_process(delta: float) -> void:
	_t += delta
	if _p == null:
		_p = get_tree().get_first_node_in_group("player")
		return
	if not _fired and _t > 1.5:
		_fired = true
		_p.do_jump()
		print("PROBE jumped")
	if _fired and _t > 2.2 and _t < 2.25:
		_p.play_emote("happy")
		_p._model.set_state("land")   # exactly the collision the critic described
		print("PROBE emote+land collided")
	if _t > 8.0:
		var stuck: bool = _p.get("_emote") != ""
		print("PROBE result: _emote=%s stuck=%s" % [str(_p.get("_emote")), stuck])
		get_tree().quit(1 if stuck else 0)
