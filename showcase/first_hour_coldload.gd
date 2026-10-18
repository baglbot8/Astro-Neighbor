extends Node
## COLD-LOAD PROBE for src/campaign/first_hour.gd: proves the game itself loads the FirstHour class
## (and its planet_loaded hook) before the Commons finishes building, on a mid-errand save. This file
## deliberately never names the class - it sets plain GameState flags by string - so nothing here can
## load it early. Inert unless `--fh-cold` is given (tools/check.sh runs every showcase scene).
##   godot --headless --path <copy> --quit-after 3000 res://showcase/first_hour_coldload.tscn -- --fh-cold

var persistent := false


func _ready() -> void:
	if not OS.get_cmdline_user_args().has("--fh-cold"):
		return
	if not persistent:
		var p: Node = load("res://showcase/first_hour_coldload.gd").new()
		p.persistent = true
		get_tree().root.add_child.call_deferred(p)
		GameState.reset_new_game()
		GameState.previous_planet_id = "home"
		GameState.current_planet_id = "hub"
		for f: String in ["intro_crash_done", "intro_greeted", "intro_done", "fh_started", "fh_pop_asked", "met_mayor_orbit"]:
			GameState.set_flag(f)
		get_tree().change_scene_to_file.call_deferred("res://src/world/world.tscn")
		return
	await get_tree().create_timer(4.0).timeout
	var fh := get_tree().root.get_node_or_null("World/FirstHour")
	var bit := fh.get_node_or_null("PopsPatchBit") if fh != null else null
	print("FHCOLD node=%s bit=%s" % [str(fh != null), str(bit != null)])
	get_tree().quit(0 if bit != null else 1)
