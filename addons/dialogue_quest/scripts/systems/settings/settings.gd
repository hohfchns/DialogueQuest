extends Node
## Singleton class for managing settings, registries, etc.
## Singleton classes are managed by the [DialogueQuest] ([DQInterface]) autoload.
class_name DQMainSettings

signal data_directory_changed(new_directory: String)

const DEFAULT_PROJECT_LOCAL_DIR := &"res://dialogue_quest/"
const SETTINGS_FILE_DIR := &"res://"
const SETTINGS_FILE_NAME := &".dialogue_quest_settings.conf"

var data_directory: String = "" :
	set(value):
		data_directory = value
		data_directory_changed.emit(value)

func _ready() -> void:
	_prepare()

func _prepare() -> void:
	var settings_path := SETTINGS_FILE_DIR.path_join(SETTINGS_FILE_NAME)
	
	if DQGodotHelper.is_final_build():
		var settings := get_settings()
		data_directory = settings.get_value("files", "data_dir")
		return
	
	var project_settings_path := DQProjectSettings.get_data_dir()
	if not FileAccess.file_exists(project_settings_path):
		DirAccess.make_dir_absolute(project_settings_path)
		
		var settings_f: ConfigFile = null
		if FileAccess.file_exists(settings_path):
			settings_f = get_settings()
		else:
			settings_f = ConfigFile.new()
		settings_f.set_value("files", "data_dir", DQProjectSettings.get_data_dir())
		var err := settings_f.save(settings_path)
		
		if err != OK:
			var s := "DialogueQuest | Settings | Failed to save configuration file"
			DialogueQuest.error.emit(s)
			assert(false, s)
		data_directory = DQProjectSettings.get_data_dir()

func get_settings() -> ConfigFile:
	var settings_f := ConfigFile.new()
	var err := settings_f.load(SETTINGS_FILE_DIR.path_join(SETTINGS_FILE_NAME))
	if err != OK:
		var s := "DialogueQuest | Settings | Failed to save configuration file"
		DialogueQuest.error.emit(s)
		assert(false, s)
	return settings_f

