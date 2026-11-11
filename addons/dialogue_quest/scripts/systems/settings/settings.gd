extends Node
## Settings shared by all DialogueQuest systems through the [DialogueQuest] autoload.
class_name DQMainSettings

signal data_directory_changed(new_directory: String)

const DEFAULT_PROJECT_LOCAL_DIR := &"res://dialogue_quest/"
const SETTINGS_FILE_DIR := &"res://"
const SETTINGS_FILE_NAME := &".dialogue_quest_settings.conf"

var data_directory: String = DEFAULT_PROJECT_LOCAL_DIR:
	set(value):
		if data_directory == value:
			return
		data_directory = value
		data_directory_changed.emit(value)

var say_by_name: bool = true

func _ready() -> void:
	_prepare()

func _prepare() -> void:
	var legacy := ConfigFile.new()
	var settings_path := SETTINGS_FILE_DIR.path_join(SETTINGS_FILE_NAME)
	var has_data_dir := ProjectSettings.has_setting(DQProjectSettings.get_data_dir_setting())
	var has_say_by_name := ProjectSettings.has_setting(DQProjectSettings.get_say_by_name_setting())
	if (not has_data_dir or not has_say_by_name) and FileAccess.file_exists(settings_path):
		var err := legacy.load(settings_path)
		if err != OK:
			var s := "DialogueQuest | Settings | Failed to load legacy configuration | Error code %d" % err
			DialogueQuest.error.emit(s)
			assert(false, s)
			return

	data_directory = DQProjectSettings.get_data_dir() if has_data_dir else legacy.get_value("files", "data_dir", DEFAULT_PROJECT_LOCAL_DIR)
	say_by_name = DQProjectSettings.get_say_by_name() if has_say_by_name else legacy.get_value("parser", "say_by_name", true)
	if Engine.is_editor_hint() and not DirAccess.dir_exists_absolute(data_directory):
		var err := DirAccess.make_dir_recursive_absolute(data_directory)
		if err != OK:
			var s := "DialogueQuest | Settings | Failed to create data directory '%s' | Error code %d" % [data_directory, err]
			DialogueQuest.error.emit(s)
			assert(false, s)
			return

## Returns a snapshot of the effective settings in the legacy [ConfigFile] format.
func get_settings() -> ConfigFile:
	var settings := ConfigFile.new()
	settings.set_value("files", "data_dir", data_directory)
	settings.set_value("parser", "say_by_name", say_by_name)
	return settings
