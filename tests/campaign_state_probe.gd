extends Node
## Regression test for Builder A's "Stranded" campaign contract (BUILD_PLAN.md Phase 1):
## GameState's new campaign fields + CampaignData's gate logic. Standalone, no Director needed -
## THE DIRECTOR RULE itself is covered separately by campaign_director_probe.gd, which needs an
## actual `--director=` timeline to make `Director.is_active()` true.
##   godot --headless --path . res://tests/campaign_state_probe.tscn -- --quit-at=5
func _ready() -> void:
	var bad: Array = []

	# 1. THE TRAP: reset_new_game() calls from_dict({}) first, which alone would read as "story
	# finished" (see from_dict's campaign_active/story_done defaults) - a brand new game must come
	# out of reset_new_game() with the gates back ON.
	GameState.reset_new_game()
	_check(bad, "new game gates_on", CampaignData.gates_on(), true)
	_check(bad, "new game campaign_active", GameState.campaign_active, true)
	_check(bad, "new game story_done", GameState.story_done, false)
	_check(bad, "new game scrap", GameState.scrap, GameState.STARTING_SCRAP)
	_check(bad, "new game home in range", CampaignData.planet_in_range("home"), true)
	_check(bad, "new game zorp in range", CampaignData.planet_in_range("zorp"), true)
	_check(bad, "new game fen in range", CampaignData.planet_in_range("fen"), false)
	_check(bad, "new game finish_stage", CampaignData.finish_stage(), 0)

	# 2. Fitting two parts opens tier 2 (fen, grig) but not tier 3 (vela) yet.
	GameState.fit_rocket_part("part_zorp")
	GameState.fit_rocket_part("part_bolt")
	_check(bad, "2 parts count", GameState.rocket_part_count(), 2)
	_check(bad, "2 parts fen in range", CampaignData.planet_in_range("fen"), true)
	_check(bad, "2 parts grig in range", CampaignData.planet_in_range("grig"), true)
	_check(bad, "2 parts vela in range", CampaignData.planet_in_range("vela"), false)
	_check(bad, "2 parts finish_stage", CampaignData.finish_stage(), 2)
	# Fitting the same part twice must not double-count (BUILDER A contract: "appends if new").
	_check(bad, "refit same part returns false", GameState.fit_rocket_part("part_zorp"), false)
	_check(bad, "refit same part count unchanged", GameState.rocket_part_count(), 2)

	# 3. Save and reload: every new field must survive the JSON round trip.
	GameState.add_scrap(7)
	var scrap_before: int = GameState.scrap
	var parts_before: Array = GameState.rocket_parts.duplicate()
	GameState.project_step_day["bolt"] = 3
	SaveManager.save_game()
	GameState.reset_new_game()  # scramble state so the reload below is a real test, not a no-op
	SaveManager.load_game()
	_check(bad, "reload scrap", GameState.scrap, scrap_before)
	_check(bad, "reload rocket_parts", GameState.rocket_parts, parts_before)
	_check(bad, "reload campaign_active", GameState.campaign_active, true)
	_check(bad, "reload story_done", GameState.story_done, false)
	_check(bad, "reload project_step_day", int(GameState.project_step_day.get("bolt", -1)), 3)
	_check(bad, "reload fen still in range", CampaignData.planet_in_range("fen"), true)

	# 4. A dictionary with NO campaign fields (every save made before today) loads as "story
	# finished": no gates, every planet open, today's clean-white finish_stage.
	GameState.from_dict({})
	_check(bad, "old-save story_done", GameState.story_done, true)
	_check(bad, "old-save campaign_active", GameState.campaign_active, false)
	_check(bad, "old-save gates_on", CampaignData.gates_on(), false)
	_check(bad, "old-save vela in range", CampaignData.planet_in_range("vela"), true)
	_check(bad, "old-save home in range", CampaignData.planet_in_range("home"), true)
	_check(bad, "old-save finish_stage", CampaignData.finish_stage(), 4)

	if bad.is_empty():
		print("CAMPAIGNSTATE PASS")
		get_tree().quit(0)
	else:
		print("CAMPAIGNSTATE FAIL " + str(bad))
		get_tree().quit(1)

func _check(bad: Array, label: String, got, want) -> void:
	if got != want:
		bad.append("%s: got %s want %s" % [label, str(got), str(want)])
