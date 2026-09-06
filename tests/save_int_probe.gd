extends Node
## Regression test: save/load must not leave integer counts as JSON floats.
func _ready() -> void:
	GameState.reset_new_game()
	GameState.add_item("deco_moon_lamp", 2)
	GameState.npc_data("zorp")["friendship"] = 4
	GameState.favors["f1"] = {"count": 3, "progress": 1, "reward_stardust": 90}
	SaveManager.save_game()
	GameState.reset_new_game()
	SaveManager.load_game()
	var bad: Array = []
	if typeof(GameState.inventory.get("deco_moon_lamp")) != TYPE_INT:
		bad.append("inventory count is %s" % type_string(typeof(GameState.inventory.get("deco_moon_lamp"))))
	if typeof(GameState.npcs["zorp"]["friendship"]) != TYPE_INT:
		bad.append("npc friendship is float")
	if typeof(GameState.favors["f1"]["count"]) != TYPE_INT:
		bad.append("favor count is float")
	if bad.is_empty():
		print("SAVEINT PASS  inventory=%s friendship=%s favor=%s" % [
			GameState.inventory.get("deco_moon_lamp"), GameState.npcs["zorp"]["friendship"],
			GameState.favors["f1"]["count"]])
		get_tree().quit(0)
	else:
		print("SAVEINT FAIL  " + str(bad))
		get_tree().quit(1)
