class_name SimSave
extends RefCounted

const PATH := "user://harbor_sim.json"


static func write(game: HarborGame) -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(game.to_dict()))


static func read() -> Dictionary:
	if not FileAccess.file_exists(PATH):
		return {}
	var txt := FileAccess.get_file_as_string(PATH)
	var data = JSON.parse_string(txt)
	if typeof(data) != TYPE_DICTIONARY:
		return {}
	return data


static func clear() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(PATH)
