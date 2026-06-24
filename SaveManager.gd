extends Node

## SaveManager.gd — AUTOLOAD (nazwa: SaveManager)
## Jeden plik zapisu: user://save.json

const SAVE_PATH := "user://save.json"


func save_exists() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save(data: Dictionary) -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))
		f.close()
		print("Gra zapisana.")
	else:
		push_warning("SaveManager: nie udało się zapisać!")


func load_save() -> Dictionary:
	if not save_exists():
		return {}
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not f:
		return {}
	var text := f.get_as_text()
	f.close()
	var data = JSON.parse_string(text)
	if data is Dictionary:
		return data
	return {}


func delete_save() -> void:
	if save_exists():
		DirAccess.remove_absolute(SAVE_PATH)
		print("Zapis usunięty.")
