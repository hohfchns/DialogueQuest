@tool
extends Resource
class_name DQCharacter

@export
var color: Color
@export
var portrait: Texture2D

@export_group("Character", "character_")
@export
var character_id: String
@export
var character_name: String

@export_group("Custom Theming", "custom_theme_")
@export
var custom_theme_name: Theme = null
@export
var custom_theme_text: Theme = null

static func find_by_id(name: String) -> DQCharacter:
	return DialogueQuest.CharacterDB.get_character_from_id(name)

static func from_serialized(character_id: String, data: Dictionary) -> DQCharacter:
	var character := DQCharacter.new()
	var with_id := data.duplicate()
	with_id["id"] = character_id
	if character.deserialize(with_id) != OK:
		return null
	return character

## Returns a Dictionary with String keys: id, name, color, and optional portrait/theme paths.
func serialize() -> Dictionary:
	var ret := {}
	
	ret["color"] = color.to_html(true)
	ret["name"] = character_name
	ret["id"] = character_id
	if portrait:
		ret["portrait"] = portrait.resource_path
	if custom_theme_name:
		ret["theme_name"] = custom_theme_name.resource_path
	if custom_theme_text:
		ret["theme_text"] = custom_theme_text.resource_path
	
	return ret

static func is_valid_character_id(value: String) -> bool:
	return not value.is_empty() and value.is_valid_filename() and value == value.strip_edges() and not value.ends_with(".")

## Returns an empty [String] on success, otherwise a description of the invalid field.
static func validate_serialized(data: Variant) -> String:
	if not data is Dictionary:
		return "Character data must be a Dictionary"
	for key in ["id", "name", "color"]:
		if not data.has(key) or not data[key] is String:
			return "Character field `%s` must be a String" % key
	if not is_valid_character_id(data["id"]):
		return "Character ID must be a non-empty filename without path separators"
	if not Color.html_is_valid(data["color"]):
		return "Character color must be an HTML color"
	for key in ["portrait", "theme_name", "theme_text"]:
		if data.has(key) and not data[key] is String:
			return "Character field `%s` must be a resource path" % key
	return ""

## Applies validated character data. Returns [OK] on success.
func deserialize(from: Dictionary) -> Error:
	var problem := validate_serialized(from)
	if not problem.is_empty():
		DialogueQuest.error.emit("DialogueQuest | Character | %s" % problem)
		return ERR_INVALID_DATA
	color = Color.from_string(from["color"], Color.WHITE)
	character_name = from["name"]
	character_id = from["id"]
	portrait = _load_optional_resource(from.get("portrait", "")) as Texture2D
	custom_theme_name = _load_optional_resource(from.get("theme_name", "")) as Theme
	custom_theme_text = _load_optional_resource(from.get("theme_text", "")) as Theme
	return OK

static func _load_optional_resource(path: String) -> Resource:
	if path.is_empty():
		return null
	if not ResourceLoader.exists(path):
		DialogueQuest.info.emit("DialogueQuest | Character | Optional resource `%s` is unavailable in this project" % path)
		return null
	return load(path)

func serialize_to_file(filepath: String, rename_ext: bool = true) -> Error:
	if rename_ext:
		var ext := filepath.get_extension()
		if ext != "dqc":
			if ext:
				filepath = filepath.get_basename()
			filepath += ".dqc"

	var data := serialize()
	var problem := validate_serialized(data)
	if not problem.is_empty():
		DialogueQuest.error.emit("DialogueQuest | Character | %s" % problem)
		return ERR_INVALID_DATA
	var temporary_path := filepath + ".tmp"
	if FileAccess.file_exists(temporary_path):
		return _file_error(temporary_path, ERR_ALREADY_EXISTS)
	var f := FileAccess.open(temporary_path, FileAccess.WRITE)
	if not f:
		return _file_error(filepath, FileAccess.get_open_error())
	f.store_string(var_to_str(data))
	f.flush()
	var err := f.get_error()
	f.close()
	return _finish_write(temporary_path, filepath, err)

func deserialize_from_file(filepath: String, save_to_resource: String = "") -> Error:
	var f := FileAccess.open(filepath, FileAccess.READ)
	if not f:
		return _file_error(filepath, FileAccess.get_open_error())
	var contents := f.get_as_text()
	f.close()
	var data: Variant = str_to_var(contents)
	var problem := validate_serialized(data)
	if not problem.is_empty():
		DialogueQuest.error.emit("DialogueQuest | Character | `%s` | %s" % [filepath, problem])
		return ERR_INVALID_DATA
	var err := deserialize(data)
	if err != OK:
		return err
	if save_to_resource.is_empty():
		return OK
	var temporary_path := save_to_resource.get_basename() + ".tmp." + save_to_resource.get_extension()
	if FileAccess.file_exists(temporary_path):
		return _file_error(temporary_path, ERR_ALREADY_EXISTS)
	err = ResourceSaver.save(self, temporary_path)
	return _finish_write(temporary_path, save_to_resource, err)

static func _finish_write(temporary_path: String, filepath: String, error: Error) -> Error:
	if error == OK:
		error = DirAccess.rename_absolute(temporary_path, filepath)
	if error != OK:
		if FileAccess.file_exists(temporary_path):
			DirAccess.remove_absolute(temporary_path)
		return _file_error(filepath, error)
	if filepath.get_extension() in ["tres", "res"] and ResourceLoader.has_cached(filepath):
		ResourceLoader.load(filepath, "", ResourceLoader.CACHE_MODE_REPLACE)
	return OK

static func _file_error(filepath: String, error: Error) -> Error:
	DialogueQuest.error.emit("DialogueQuest | Character | File operation failed at `%s` | Error code %d" % [filepath, error])
	return error

