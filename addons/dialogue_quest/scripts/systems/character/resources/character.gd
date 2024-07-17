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
	
	character.character_id = character_id
	character.character_name = data["name"]
	character.color = Color.from_string(data["color"], Color.WHITE)
	
	return character

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

func deserialize(from: Dictionary) -> void:
	color = Color.from_string(from["color"], Color("white"))
	character_name = from["name"]
	character_id = from["id"]
	
	if "portrait" in from:
		var loaded_portrait := load(from["portrait"]) as Texture2D
		if loaded_portrait:
			portrait = loaded_portrait
	if "theme_name" in from:
		var loaded_theme_name := load(from["theme_name"]) as Theme
		if loaded_theme_name:
			custom_theme_name = loaded_theme_name
	if "theme_text" in from:
		var loaded_theme_text := load(from["theme_text"]) as Theme
		if loaded_theme_text:
			custom_theme_text = loaded_theme_text

func serialize_to_file(filepath: String, rename_ext: bool = true) -> void:
	if rename_ext:
		var ext := filepath.get_extension()
		if ext != "dqc":
			if ext:
				filepath = filepath.get_basename()
			filepath += ".dqc"

	var data := serialize()
	var f := FileAccess.open(filepath, FileAccess.WRITE)
	assert(f, "DialogueQuest | DQCharacter | serialize_to_file | Could not open file `%s` for writing, file error: " % [filepath, f.get_open_error()])
	
	var as_str := var_to_str(data)
	f.store_string(as_str)

func deserialize_from_file(filepath: String, save_to_resource: String = "") -> void:
	var f := FileAccess.open(filepath, FileAccess.READ)
	assert(f, "DialogueQuest | DQCharacter | deserialize_from_file | Could not open file `%s` for reading, file error: " % [filepath, f.get_open_error()])
	
	var contents := f.get_as_text()
	var as_dict := str_to_var(contents)
	deserialize(as_dict)
	
	if save_to_resource.is_empty():
		return
	
	ResourceSaver.save(self, save_to_resource)

