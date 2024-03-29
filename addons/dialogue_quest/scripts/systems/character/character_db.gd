extends Node
class_name DQCharacterDB

## A Dictionary of format { character_id([String]) : character_data([DQCharacter]) }
## Generated at runtime
var _character_registry: Dictionary = {}

var character_registry: Dictionary = _character_registry : get = get_character_registry

func _ready() -> void:
	_find_characters_in_project()

func _find_characters_in_project() -> void:
	var dq_dir := DQProjectSettings.get_data_dir()
	var resources := DQFilesystemHelper.get_all_files(dq_dir, "tres")
	for res in resources:
		var character := load(res) as DQCharacter
		if not character:
			continue
		
		_character_registry[character.character_id] = character

func get_character_from_id(character_id: String) -> DQCharacter:
	if character_id not in _character_registry:
		return null
	
	return _character_registry[character_id]

## Provides a shallow copy of the registry.
func get_character_registry() -> Dictionary:
	return _character_registry.duplicate()

