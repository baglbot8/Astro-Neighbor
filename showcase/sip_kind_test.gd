extends Node
## PROBE: SafariIntro.kind_for_data under every kind of setting value (a corrupted save must play the default).
func _ready() -> void:
	var w: Object = load("res://src/planet_safari/worlds/zorp.gd").new()
	var data: Dictionary = w.call("intro_data")
	if w is Node:
		(w as Node).free()
	for v: Variant in ["zzz", 1, null, "", "off", "a", "b", "c", "C", 2.5, [1]]:
		GameState.settings[SafariIntro.SETTING] = v
		print("KIND setting=%s (%s) -> \"%s\"" % [str(v), type_string(typeof(v)), SafariIntro.kind_for_data(data)])
	GameState.settings.erase(SafariIntro.SETTING)
	print("KIND setting=<unset> -> \"%s\"" % SafariIntro.kind_for_data(data))
	get_tree().quit()
