extends Node
## Regression test: TrashSystem must (1) turn "3 real hours since anyone checked home" into a capped
## pile of trash, (2) actually spawn one TrashPiece node per GameState.trash_home entry, and (3)
## cleaning a piece must remove it from both the scene and GameState, and raise the planet score.

func _ready() -> void:
	GameState.reset_new_game()
	GameState.current_planet_id = "home"
	GameState.trash_last_check_unix = Time.get_unix_time_from_system() - 3.0 * 3600.0

	var planet: Planet = load("res://src/planet/planet.tscn").instantiate()
	planet.data = load("res://src/planet/data/home.tres")
	add_child(planet)
	await get_tree().process_frame

	var trash: TrashSystem = load("res://src/planet/trash_system.tscn").instantiate()
	add_child(trash)
	await get_tree().process_frame

	var bad: Array = []
	if GameState.trash_home.size() != TrashSystem.MAX_TRASH:
		bad.append("expected %d pieces after 3h away, got %d" % [TrashSystem.MAX_TRASH, GameState.trash_home.size()])
	var nodes := trash.get_children()
	if nodes.size() != GameState.trash_home.size():
		bad.append("spawned %d nodes for %d GameState entries" % [nodes.size(), GameState.trash_home.size()])

	var score_before := PlanetScore.compute("home")

	if not nodes.is_empty():
		var piece: TrashPiece = nodes[0]
		var cleaned_id := piece.trash_id
		piece.interact(null)
		await get_tree().create_timer(0.5).timeout
		var still_there := false
		for e in GameState.trash_home:
			if str(e.get("id", "")) == cleaned_id:
				still_there = true
		if still_there:
			bad.append("cleaned piece is still in GameState.trash_home")
		if GameState.trash_home.size() != TrashSystem.MAX_TRASH - 1:
			bad.append("trash_home size after cleanup is %d, expected %d" % [GameState.trash_home.size(), TrashSystem.MAX_TRASH - 1])
		if is_instance_valid(piece):
			bad.append("cleaned piece node was not freed")

	# Score itself can floor at 0 either side of one cleanup (10 pieces of trash alone is already a
	# -50 penalty with nothing placed to offset it), so assert on the penalty component directly
	# rather than the clamped total.
	var score_after := PlanetScore.compute("home")
	if not (float(score_after["trash_penalty"]) < float(score_before["trash_penalty"])):
		bad.append("trash_penalty did not drop after cleanup (%.1f -> %.1f)" %
			[float(score_before["trash_penalty"]), float(score_after["trash_penalty"])])

	if bad.is_empty():
		print("TRASHPROBE PASS pieces=%d score_before=%.1f score_after=%.1f" %
			[TrashSystem.MAX_TRASH, float(score_before["score"]), float(score_after["score"])])
		get_tree().quit(0)
	else:
		print("TRASHPROBE FAIL " + str(bad))
		get_tree().quit(1)
