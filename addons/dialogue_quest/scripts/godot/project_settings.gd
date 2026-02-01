extends Node
class_name DQProjectSettings

const PROJECT_PROPERTIES_CATEGORY := &"dialogue_quest"
const PROJECT_PROPERTY_ID_DATA_DIR := &"data_directory"
const PROJECT_PROPERTY_HINT_DATA_DIR := &"Where DialogueQuest will store and look for characters, settings, etc."
const PROJECT_PROPERTY_ID_SAY_BY_NAME := &"say_by_name"
const PROJECT_PROPERTY_HINT_SAY_BY_NAME := &"If enabled, the 'say' statement will be optional, and will automatically be used if the statment is a valid character ID."

static func prepare() -> void:
	var data_dir_setting := get_data_dir_setting()
	var say_by_name_setting := get_say_by_name_setting()
	
	if not ProjectSettings.has_setting(data_dir_setting):
		ProjectSettings.set_setting(data_dir_setting, DialogueQuest.Settings.DEFAULT_PROJECT_LOCAL_DIR)
	if not ProjectSettings.has_setting(say_by_name_setting):
		ProjectSettings.set_setting(say_by_name_setting, true)
	
	var property_info_data_dir = {
		"name": data_dir_setting,
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_DIR
	}
	var property_info_say_by_name = {
		"name": say_by_name_setting,
		"type": TYPE_BOOL
	}
	
	ProjectSettings.add_property_info(property_info_data_dir)
	ProjectSettings.add_property_info(property_info_say_by_name)
	
	if DQGodotHelper.is_final_build():
		return

	var editor_interface = Engine.get_singleton(&"EditorInterface")
	var es = editor_interface.get_editor_settings()
	var cur_extensions: String = es.get_setting("docks/filesystem/textfile_extensions")
	var ext := DQFilesDefines.DIALOGUE_FILE_EXTENSION
	if not ext in cur_extensions:
		es.set_setting("docks/filesystem/textfile_extensions", "%s,%s" % [cur_extensions, ext])

static func get_data_dir_setting() -> StringName:
	return PROJECT_PROPERTIES_CATEGORY.path_join(PROJECT_PROPERTY_ID_DATA_DIR)

static func get_data_dir() -> StringName:
	return ProjectSettings.get_setting(get_data_dir_setting())

static func get_say_by_name_setting() -> StringName:
	return PROJECT_PROPERTIES_CATEGORY.path_join(PROJECT_PROPERTY_ID_SAY_BY_NAME)

static func get_say_by_name() -> bool:
	return ProjectSettings.get_setting(get_say_by_name_setting())
