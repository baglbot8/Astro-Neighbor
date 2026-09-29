class_name MeteorSurvey
extends RefCounted
## THE METEOR SURVEY (docs/STORY_HOME_SPEC.md 9.2). Lead-written stub: the contract between the finale and
## the survey level. Builder METEOR filled in `run` (the level is meteor_survey_level.gd); builder FINALE4
## only calls it.

## Emitted-free contract: `await MeteorSurvey.run(get_tree())` returns when the player has marked all five
## weak points (retries included; there is no way to fail or quit). The finale continues after it. It fades
## out, plays the level, fades back in and returns with the game where it was: the player back where they
## stood in third person, the hub's nodes shown and running again, the clock back at the hour it was held
## at. Never saved in the scrapbook, pays nothing, writes nothing to GameState.
##
## THE CALLER'S SIDE: call it from the World scene (it needs /root/World with its Player, CameraRig and
## Environment) with NO modal open and no talk running - the player walks and looks only while
## EventBus.is_modal_open() is false. Close a cutscene modal before the call and reopen it after. The
## player's `input_enabled` and move lock are put back to the values the survey found.
static func run(tree: SceneTree) -> void:
	var w := tree.root.get_node_or_null("World")
	if w == null:
		push_warning("MeteorSurvey.run: no /root/World; nothing to run.")
		await tree.process_frame
		return
	if EventBus.is_modal_open():
		push_warning("MeteorSurvey.run: a modal is open (%s); the player cannot walk until it closes." %
			str(EventBus.open_modals()))
	var lvl := MeteorSurveyLevel.new()
	lvl.name = "MeteorSurvey"
	w.add_child(lvl)
	await lvl.survey_done
