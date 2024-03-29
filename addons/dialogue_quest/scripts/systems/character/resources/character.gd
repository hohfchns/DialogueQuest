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
	
	return ret
