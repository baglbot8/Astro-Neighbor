extends Node
## Saves/loads GameState to user://astro_neighbor_save.json.

const SAVE_PATH := "user://astro_neighbor_save.json"

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_game() -> bool:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_error("SaveManager: cannot open save file for writing: %s" % FileAccess.get_open_error())
		return false
	f.store_string(JSON.stringify(GameState.to_dict(), "\t"))
	f.close()
	EventBus.game_saved.emit()
	return true

func load_game() -> bool:
	if not has_save():
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("SaveManager: save file corrupt")
		return false
	GameState.from_dict(parsed)
	EventBus.game_loaded.emit()
	return true

func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
