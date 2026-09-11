extends Node
## Proves THE DIRECTOR RULE (BUILD_PLAN.md): campaign gates are OFF whenever a Director timeline
## runs, unless the timeline opts in with "--campaign" (director.gd `campaign_opt_in()`). Autoloads
## run their _ready() before the main scene's, so by the time this node's _ready() fires, Director
## has already parsed "--new-game"/"--campaign"/"--director=" from the command line.
##
## Run twice, same trivial `--director=` timeline (an empty JSON array is enough to make
## Director.is_active() true), comparing the printed line:
##   godot --headless --path . res://tests/campaign_director_probe.tscn -- --new-game --campaign \
##         "--director=<abs path>" --quit-at=2      # expect gates_on=true
##   godot --headless --path . res://tests/campaign_director_probe.tscn -- --new-game \
##         "--director=<abs path>" --quit-at=2      # expect gates_on=false (no --campaign)
func _ready() -> void:
	print("DIRECTORPROBE director_active=%s campaign_opt_in=%s campaign_active=%s story_done=%s gates_on=%s fen_in_range=%s finish_stage=%d" % [
		Director.is_active(), Director.campaign_opt_in(), GameState.campaign_active, GameState.story_done,
		CampaignData.gates_on(), CampaignData.planet_in_range("fen"), CampaignData.finish_stage()])
	get_tree().quit(0)
