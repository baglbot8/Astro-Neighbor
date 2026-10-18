extends Node
## COOL MODE probe (2026-10-18): does the player's "Cool mode" choice survive a save round trip, an
## old save with no key, a New Game, and the dev menu's saver switch? Headless is fine (no drawing is
## measured here). Not shipped (showcase/cool_mode_*). Touches only in-memory GameState: it never calls
## SaveManager, so no save file is read or written.
##
## Usage: godot --headless --path <copy> --quit-after 600 res://showcase/cool_mode_persist.tscn -- --draw-saver
## (Without --draw-saver DrawGate is inactive; the bookkeeping is the same and is still checked.)
## Prints one "COOLPERSIST PASS|FAIL <what>" line per check and a "COOLPERSIST done pass=N fail=M" summary.

var _pass := 0
var _fail := 0


func _ready() -> void:
	_run.call_deferred()


func _check(ok: bool, what: String) -> void:
	if ok:
		_pass += 1
	else:
		_fail += 1
	print("COOLPERSIST %s %s" % ["PASS" if ok else "FAIL", what])


func _g() -> Node:
	return get_tree().root.get_node("DrawGate")


func _cool() -> bool:
	return bool(_g().call("cool_mode"))


func _saver() -> bool:
	return bool(_g().call("saver_on"))


static func _save_with(settings: Variant) -> Dictionary:
	var d := {"current_planet_id": "home", "day_count": 3}
	if settings != null:
		d["settings"] = settings
	return d


func _run() -> void:
	var g := _g()
	var fps_before := Engine.max_fps
	print("COOLPERSIST start active=%s max_fps=%d" % [str(g.call("cool_mode_available")), fps_before])
	# 1. Defaults.
	_check(GameState.settings.has("cool_mode") and GameState.settings["cool_mode"] == false,
		"default settings carry cool_mode=false")
	_check(not _cool() and not _saver(), "default: cool_mode off, saver off")
	# 2. Boot-time load (player has not touched the switch this session): the save supplies the choice.
	GameState.from_dict(_save_with({"music_volume": 0.5, "cool_mode": true}))
	_check(_cool() and _saver(), "boot load of a save with cool_mode=true turns it on")
	# 3. Old save, no key: the live choice survives instead of reverting to off.
	GameState.from_dict(_save_with({"music_volume": 0.4}))
	_check(_cool() and GameState.settings.get("cool_mode") == true,
		"old save without the key keeps the live choice (on) and writes it into the new dict")
	# 3b. Very old save with no settings at all.
	GameState.from_dict(_save_with(null))
	_check(_cool(), "save with no settings dictionary keeps cool_mode on")
	# 4. A save that says off, before any player choice: the save wins.
	GameState.from_dict(_save_with({"cool_mode": false}))
	_check(not _cool() and not _saver(), "boot load of a save with cool_mode=false turns it off")
	GameState.from_dict(_save_with({}))
	_check(not _cool() and GameState.settings.get("cool_mode") == false, "then an old save keeps it off")
	# 5. The player flips the switch on. PerfOverlay's planet-load re-assert (set_saver(false), its
	# default) must not undo it.
	g.call("set_cool_mode", true)
	_check(_cool() and _saver() and GameState.settings["cool_mode"] == true, "set_cool_mode(true) applies at once")
	g.call("set_saver", false)
	_check(_saver() and str(g.call("saver_source")) == "setting",
		"PerfOverlay re-assert set_saver(false) is ignored while cool mode is on")
	# 6. After a player choice, a save that says off does NOT override the device preference.
	GameState.from_dict(_save_with({"cool_mode": false, "music_volume": 0.3}))
	_check(_cool() and GameState.settings["cool_mode"] == true and is_equal_approx(float(GameState.settings["music_volume"]), 0.3),
		"after a player choice, loading a save keeps cool_mode on (other settings still load)")
	# 7. to_dict -> JSON text -> from_dict round trip.
	var text := JSON.stringify(GameState.to_dict())
	var parsed: Dictionary = JSON.parse_string(text)
	_check(parsed["settings"].get("cool_mode") == true, "to_dict writes cool_mode=true into the save text")
	GameState.from_dict(parsed)
	_check(_cool() and typeof(GameState.settings["cool_mode"]) == TYPE_BOOL, "JSON round trip reads back true (a bool)")
	# 8. New Game keeps it (reset_new_game's from_dict({}) keeps the live settings dictionary).
	var before: Dictionary = GameState.settings
	GameState.reset_new_game()
	_check(is_same(before, GameState.settings) and _cool() and _saver(), "New Game keeps cool_mode on (same settings dict)")
	GameState.from_dict({})
	_check(_cool(), "from_dict({}) keeps cool_mode on")
	# 9. Player turns it off; New Game keeps off.
	g.call("set_cool_mode", false)
	GameState.reset_new_game()
	_check(not _cool() and not _saver(), "off survives New Game too")
	# 10. Dev override: wins until the setting changes, never sticks.
	g.call("set_saver", true)
	_check(_saver() and str(g.call("saver_source")) == "dev override", "dev set_saver(true) overrides cool_mode off")
	g.call("set_saver", true)
	_check(_saver(), "repeat set_saver(true) (planet-load re-assert) keeps the override")
	g.call("set_cool_mode", true)
	_check(_saver() and str(g.call("saver_source")) == "setting", "a setting change ends the dev override")
	g.call("set_cool_mode", false)
	_check(not _saver(), "setting off now rules: saver off although the dev's last request was on")
	g.call("set_saver", false)
	_check(not _saver() and str(g.call("saver_source")) == "setting", "dev off == setting off clears, no override left")
	g.call("set_saver", true)
	g.call("set_saver", false)
	_check(not _saver() and str(g.call("saver_source")) == "setting", "dev on then off: back to the setting")
	# 11. Rapid flips: 200 alternations end exactly where the last one says.
	for i in 200:
		g.call("set_cool_mode", i % 2 == 0)
		if i % 7 == 0:
			g.call("set_saver", i % 3 == 0)
	g.call("set_cool_mode", true)
	_check(_cool() and GameState.settings["cool_mode"] == true, "200 mixed flips end on the last setting")
	# 11b. Junk values from a hand-edited or corrupted save read as OFF, with no script error.
	for junk in ["yes", 1, null]:
		GameState.settings["cool_mode"] = junk
		_check(not _cool() and not _saver(), "cool_mode=%s (%s) reads as off" % [str(junk), type_string(typeof(junk))])
		await get_tree().process_frame
	GameState.settings["cool_mode"] = true
	_check(_cool(), "a real true after junk turns it back on")
	# 12. A tick later (the per-tick sync, on an active gate) nothing drifts.
	await get_tree().process_frame
	await get_tree().process_frame
	_check(_cool() == true, "state holds across process ticks")
	if bool(g.call("cool_mode_available")):
		_check(str(g.call("mode")) in ["saver", "normal"], "mode() reports saver/normal with cool mode on (got %s)" % str(g.call("mode")))
	g.call("set_cool_mode", false)
	_check(Engine.max_fps == fps_before, "Engine.max_fps untouched (%d)" % Engine.max_fps)
	print("COOLPERSIST done pass=%d fail=%d" % [_pass, _fail])
	get_tree().quit()
