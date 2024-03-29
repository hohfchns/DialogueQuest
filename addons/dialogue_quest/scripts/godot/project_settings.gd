extends Node
class_name DQProjectSettings

const PROJECT_PROPERTIES_CATEGORY := &"dialogue_quest"
const PROJECT_PROPERTY_ID_DATA_DIR := &"data_directory"
const PROJECT_PROPERTY_HINT_DATA_DIR := &"Where DialogueQuest will store and look for characters, settings, etc."

static func prepare() -> void:
	var data_dir_setting := get_data_dir_setting()
	
	if not ProjectSettings.has_setting(data_dir_setting):
		ProjectSettings.set_setting(data_dir_setting, DialogueQuest.Settings.DEFAULT_PROJECT_LOCAL_DIR)
	
	var property_info = {
		"name": data_dir_setting,
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_DIR
	}
	
	ProjectSettings.add_property_info(property_info)
	
	var es := EditorInterface.get_editor_settings()
	var cur_extensions: String = es.get_setting("docks/filesystem/textfile_extensions")
	var ext := DQFilesDefines.DIALOGUE_FILE_EXTENSION
	if not ext in cur_extensions:
		es.set_setting("docks/filesystem/textfile_extensions", "%s,%s" % [cur_extensions, ext])

static func get_data_dir_setting() -> StringName:
	return PROJECT_PROPERTIES_CATEGORY.path_join(PROJECT_PROPERTY_ID_DATA_DIR)

static func get_data_dir() -> StringName:
	return ProjectSettings.get_setting(get_data_dir_setting())

