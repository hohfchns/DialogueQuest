@tool
extends Control

const CHARACTER_ENTRY_SCENE: PackedScene = preload("res://addons/dialogue_quest/prefabs/ui/editor/character_entry.tscn")

@onready
var _error_dialog: ConfirmationDialog = %ErrorDialog
@onready
var _info_dialog: ConfirmationDialog = %InfoDialog

@onready
var _cdb_entries_container: Container = %CDBEntries
@onready
var _cdb_export_button: Button = %CDBExport
@onready
var _cdb_import_button: Button = %CDBImport
@onready
var _cdb_select_all_button: Button = %CDBSelectAll
@onready
var _cdb_deselect_all_button: Button = %CDBDeselectAll
@onready
var _cdb_choose_folder_dialog: FileDialog = %CDBChooseFolderDialog
@onready
var _cdb_choose_files_dialog: FileDialog = %CDBChooseFilesDialog

var _selected: Array[int] = []

var _import_files: PackedStringArray = []

func _ready() -> void:
	await DialogueQuest.ready
	
	_cdb_export_button.pressed.connect(_on_export)
	_cdb_import_button.pressed.connect(_on_import)
	_cdb_select_all_button.pressed.connect(_on_select_all)
	_cdb_deselect_all_button.pressed.connect(_on_deselect_all)
	
	_refresh_character_db_entries()

func _refresh_character_db_entries() -> void:
	for c in _cdb_entries_container.get_children():
		_cdb_entries_container.remove_child(c)
		c.queue_free()
	
	var registry := DialogueQuest.CharacterDB.get_character_registry()
	var i := 0
	for character in registry.values():
		var entry := CHARACTER_ENTRY_SCENE.instantiate() as DQEditorCharacterEntry
		entry.ready.connect(
			func():
				entry.checkbox.toggled.connect(self._on_toggle.bind(i))
		)
		_cdb_entries_container.add_child(entry)
		entry.fill(character)
		i += 1

func _on_export() -> void:
	_cdb_choose_folder_dialog.root_subfolder = "res://"
	_cdb_choose_folder_dialog.title = "Open a Directory for exporting"
	_cdb_choose_folder_dialog.filters = ["*.dqc"]
	_cdb_choose_folder_dialog.dir_selected.connect(_on_export_confirmed, CONNECT_ONE_SHOT)
	_cdb_choose_folder_dialog.popup()

func _on_import() -> void:
	_import_files.clear()
	_cdb_choose_files_dialog.root_subfolder = "user://"
	_cdb_choose_files_dialog.title = "Import Character File(s)"
	_cdb_choose_files_dialog.filters = ["*.dqc"]
	_cdb_choose_files_dialog.files_selected.connect(_on_import_confirmed, CONNECT_ONE_SHOT)
	_cdb_choose_files_dialog.popup()

func _on_select_all() -> void:
	_selected.clear()
	var i := 0
	for entry in _cdb_entries_container.get_children():
		entry = entry as DQEditorCharacterEntry
		if entry:
			entry.checkbox.set_pressed_no_signal(true)
			_selected.append(i)
		i += 1

func _on_deselect_all() -> void:
	_selected.clear()
	for entry in _cdb_entries_container.get_children():
		entry = entry as DQEditorCharacterEntry
		if not entry:
			continue
		entry.checkbox.set_pressed_no_signal(false)

func _on_toggle(on: bool, idx: int) -> void:
	if on:
		if not idx in _selected:
			_selected.append(idx)
	else:
		_selected.erase(idx)

func _on_export_confirmed(dir: String) -> void:
	if not DirAccess.dir_exists_absolute(dir):
		_error("DialogueQuest | Editor | CharacterDB | Export | Directory does not exist at '%s'" % dir)
		return
	
	var access := DirAccess.open(dir)
	if not access:
		_error("DialogueQuest | Editor | CharacterDB | Export | Could not open directory at '%s' | Error code: %s" % [dir, access.get_open_error()])
		return
	
	var export_count := 0
	for idx in _selected:
		var entry := _cdb_entries_container.get_children()[idx] as DQEditorCharacterEntry
		if not entry:
			_error("DialogueQuest | Editor | CharacterDB | Export | Internal error: Bad indexing")
			return
		
		var character := entry.get_character()
		if not character:
			_error("DialogueQuest | Editor | CharacterDB | Export | Internal error: Character resource not found")
		var path := "%s/%s.dqc" % [dir, character.character_id]
		character.serialize_to_file(path)
		export_count += 1
	
	var s := "DialogueQuest | Editor | CharacterDB | Export | Export finished successfully. Exported %s character" % export_count
	if export_count != 1:
		s += "s"
	s += "."
	
	_info(s)

func _on_import_confirmed(files: PackedStringArray) -> void:
	_import_files = files
	_cdb_choose_folder_dialog.root_subfolder = DQProjectSettings.get_data_dir()
	_cdb_choose_folder_dialog.title = "Open directory to place imported resources."
	_cdb_choose_folder_dialog.filters = ["*.tres"]
	_cdb_choose_folder_dialog.dir_selected.connect(_on_import_directory_confirmed, CONNECT_ONE_SHOT)
	_cdb_choose_folder_dialog.popup()

func _on_import_directory_confirmed(dir: String) -> void:
	if not DirAccess.dir_exists_absolute(dir):
		_error("DialogueQuest | Editor | CharacterDB | Import | Directory does not exist at '%s'" % dir)
		return
	
	var d_access := DirAccess.open(dir)
	if not d_access:
		_error("DialogueQuest | Editor | CharacterDB | Import | Could not open directory at '%s' | Error code: %s" % [dir, d_access.get_open_error()])
		return
	
	var import_count := 0
	for f in _import_files:
		if not FileAccess.file_exists(f):
			_error("DialogueQuest | Editor | CharacterDB | Import | File does not exist at '%s'" % f)
			return
		
		var access := FileAccess.open(f, FileAccess.READ)
		if not access:
			_error("DialogueQuest | Editor | CharacterDB | Import | Could not open file for reading at '%s' | Error code: %s" % [f, access.get_open_error()])
			return
		
		var character := DQCharacter.new()
		var save_path := "%s/%s.tres" % [dir, f.get_basename().get_file()]
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
		_refresh_character_db_entries()
	
	_info(s)

func _error(message: String) -> void:
	_error_dialog.dialog_text = message
	_error_dialog.popup()
	printerr(message)

func _info(message: String) -> void:
	_info_dialog.dialog_text = message
	_info_dialog.popup()
	print(message)
