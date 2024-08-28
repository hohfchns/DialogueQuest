@tool
extends Node
class_name DQCharacterDBMigrator

static func export_characters_from_resource_file(files: PackedStringArray, save_dir: String) -> void:
	var characters: Array[DQCharacter] = []
	
	for f in files:
		if f.get_extension() != "tres":
			_error("DialogueQuest | DQCharacterDBMigrator | export_characters_from_resource_file | Wrong usage: All files must be resource files (`.tres`)")
			return
	
	for f in files:
		if not FileAccess.file_exists(f):
			_error("DialogueQuest | DQCharacterDBMigrator | export_characters_from_resource_file | File not found at `%s`" % f)
			return
		
		var chara := load(f) as DQCharacter
		if not chara:
			continue
		
		characters.append(chara)
	
	export_characters(characters, save_dir)

static func export_character_db(save_dir: String) -> int:
	var characters: Array[DQCharacter] = []
	for chara in DialogueQuest.CharacterDB.get_character_registry().values():
		chara = chara as DQCharacter
		if not chara:
			continue
		
		characters.append(chara)
	
	return export_characters(characters, save_dir)

## Export the following characters to `.dqc` files, which can then be imported with `import_characters`
## Returns the amount of characters that were successfully exported, or -1 on failure
## A return of less then `characters.size()` means an error happened along the way.
static func export_characters(characters: Array[DQCharacter], save_dir: String) -> int:
	if not DirAccess.dir_exists_absolute(save_dir):
		_error("DialogueQuest | CharacterDBMigrator | export_characters | Directory does not exist at '%s'" % save_dir)
		return -1
	
	var access := DirAccess.open(save_dir)
	if not access:
		_error("DialogueQuest | CharacterDBMigrator | export_characters | Could not open directory at '%s' | Error code: %s" % [save_dir, access.get_open_error()])
		return -1
	
	var export_count := 0
	for chara in characters:
		if not chara:
			_error("DialogueQuest | CharacterDBMigrator | export_characters | Internal error: Character resource not found")
			continue
		var path := "%s/%s.dqc" % [save_dir, chara.character_id]
		chara.serialize_to_file(path)
		export_count += 1
	
	var total_requested: int = characters.size()
	if export_count != total_requested:
		_error("DialogueQuest | CharacterDBMigrator | export_characters | Export finished with partial success. Exported %s out of %s characters." % [export_count, total_requested])
		return export_count
	
	var s := "DialogueQuest | CharacterDBMigrator | export_characters | Export finished successfully. Exported %s character" % export_count
	if export_count != 1:
		s += "s"
	s += "."
	
	_info(s)
	
	return export_count

## Import the following `.dqc` files as DQCharacter's
## Returns the amount of characters that were successfully imported, or -1 on failure
static func import_characters(character_files: PackedStringArray, save_dir: String) -> int:
	var import_count := 0
	if not DirAccess.dir_exists_absolute(save_dir):
		_error("DialogueQuest | Editor | CharacterDB | Import | Save directory does not exist at '%s'" % save_dir)
		return -1
	
	var missing_files: PackedStringArray = []
	for f in character_files:
		if not FileAccess.file_exists(f):
			missing_files.append(f)
	
	if missing_files.size():
		_error("DialogueQuest | Editor | CharacterDB | Import | Could not find %s files: '%s'" % [missing_files.size(), missing_files])
		return -1
	
	for f in character_files:
		var access := FileAccess.open(f, FileAccess.READ)
		if not access:
			_error("DialogueQuest | Editor | CharacterDB | Import | Could not open file for reading at '%s' | Error code: %s" % [f, access.get_open_error()])
			continue
		
		var character := DQCharacter.new()
		var save_path := "%s/%s.tres" % [save_dir, f.get_basename().get_file()]
		character.deserialize_from_file(f, save_path)
		
		if not FileAccess.file_exists(save_path):
			_error("DialogueQuest | Editor | CharacterDB | Import | Internal Error: Saving resource file went wrong." % [f, access.get_open_error()])
		
		import_count += 1
	
	var s := "DialogueQuest | Editor | CharacterDB | Import | Import finished successfully. Imported %s character" % import_count
	if import_count != 1:
		s += "s"
	s += "."
	
	if import_count > 0:
		DialogueQuest.CharacterDB._find_characters_in_project()
	
	_info(s)
	
	return import_count

static func _error(message: String) -> void:
	DialogueQuest.error.emit(message)

static func _info(message: String) -> void:
	DialogueQuest.info.emit(message)
