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
var _cdb_refresh_button: Button = %CDBRefresh
@onready
var _cdb_choose_folder_dialog: FileDialog = %CDBChooseFolderDialog
@onready
var _cdb_choose_files_dialog: FileDialog = %CDBChooseFilesDialog

var _selected: Array[int] = []

var _import_files: PackedStringArray = []

func _ready() -> void:
	if not DialogueQuest.is_node_ready():
		await DialogueQuest.ready
	
	DialogueQuest.CharacterDB.character_registry_changed.connect(_on_character_registry_changed)
	
	DialogueQuest.error.connect(_on_error)
	DialogueQuest.info.connect(_on_info)
	
	_cdb_export_button.pressed.connect(_on_export)
	_cdb_import_button.pressed.connect(_on_import)
	_cdb_select_all_button.pressed.connect(_on_select_all)
	_cdb_deselect_all_button.pressed.connect(_on_deselect_all)
	_cdb_refresh_button.pressed.connect(_on_refresh_character_db)
	
	_refresh_character_db_entries()

func _refresh_character_db_entries() -> void:
	DialogueQuest.CharacterDB._find_characters_in_project()

func _on_character_registry_changed() -> void:
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

func _on_refresh_character_db() -> void:
	_refresh_character_db_entries()

func _on_toggle(on: bool, idx: int) -> void:
	if on:
		if not idx in _selected:
			_selected.append(idx)
	else:
		_selected.erase(idx)

func _on_export_confirmed(dir: String) -> void:
	var characters: Array[DQCharacter] = []
	for idx in _selected:
		var entry := _cdb_entries_container.get_children()[idx] as DQEditorCharacterEntry
		if not entry:
			_error("DialogueQuest | Editor | CharacterDB | Export | Internal error: Bad indexing")
			return
		
		var character := entry.get_character()
		if not character:
			_error("DialogueQuest | Editor | CharacterDB | Export | Internal error: Character resource not found")
			continue
		
		characters.append(character)
	
	var export_count := DQCharacterDBMigrator.export_characters(characters, dir)

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
	
	var import_count := DQCharacterDBMigrator.import_characters(_import_files, dir)
	if import_count > 0:
		_refresh_character_db_entries()

func _error(message: String) -> void:
	DialogueQuest.error.emit(message)

func _info(message: String) -> void:
	DialogueQuest.info.emit(message)

func _on_error(message: String) -> void:
	_error_dialog.dialog_text = message
	_error_dialog.popup()
	printerr(message)

func _on_info(message: String) -> void:
	_info_dialog.dialog_text = message
	_info_dialog.popup()
	print(message)
