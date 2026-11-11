@tool
extends EditorPlugin
class_name DQEditorPlugin

const ADDON_DIR := &"res://addons/dialogue_quest"

const DQ_INTERFACE_AUTOLOAD_NAME := &"DialogueQuest"
const DQ_INTERFACE_SCRIPT := &"res://addons/dialogue_quest/scripts/dialogue_quest_interface.gd"

const DQ_PANEL = preload("res://addons/dialogue_quest/prefabs/ui/editor/dialogue_quest_menu.tscn")

var main_panel_instance: Control = null
var _validation_file_dialog := EditorFileDialog.new()
var _validation_result_dialog := AcceptDialog.new()

func _enter_tree() -> void:
	add_autoload_singleton(DQ_INTERFACE_AUTOLOAD_NAME, DQ_INTERFACE_SCRIPT)
	
	DQProjectSettings.prepare()

	main_panel_instance = DQ_PANEL.instantiate()
	main_screen_changed.connect(_on_main_screen_changed)
	EditorInterface.get_editor_main_screen().add_child(main_panel_instance)
	_make_visible(false)
	_validation_file_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	_validation_file_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	_validation_file_dialog.filters = PackedStringArray(["*.dqd ; DialogueQuest dialogue"])
	_validation_file_dialog.title = "Validate Dialogue"
	_validation_file_dialog.file_selected.connect(_validate_dialogue)
	EditorInterface.get_base_control().add_child(_validation_file_dialog)
	EditorInterface.get_base_control().add_child(_validation_result_dialog)
	add_tool_menu_item("Validate DialogueQuest Dialogue", _show_validation_dialog)

func _exit_tree() -> void:
	remove_tool_menu_item("Validate DialogueQuest Dialogue")
	_validation_file_dialog.queue_free()
	_validation_result_dialog.queue_free()
	if main_panel_instance:
		main_panel_instance.queue_free()

func _make_visible(visible: bool) -> void:
	if main_panel_instance:
		main_panel_instance.visible = visible

func _has_main_screen() -> bool:
	return true

func _get_plugin_name() -> String:
	return "DialogueQuest"

func _on_main_screen_changed(screen_name: String) -> void:
	if screen_name == _get_plugin_name():
		var dq = Engine.get_singleton(&"DialogueQuest")
		if not dq:
			return
		
		if not dq.is_node_ready():
			await dq.ready
		
		main_panel_instance._refresh_character_db_entries()

func _show_validation_dialog() -> void:
	_validation_file_dialog.popup_centered_ratio()

func _validate_dialogue(path: String) -> void:
	var result := DQDqdParser.validate_from_file(path)
	var messages: PackedStringArray = []
	for error in result.errors:
		messages.append(error.formatted())
	_validation_result_dialog.title = "Dialogue Validation"
	_validation_result_dialog.dialog_text = "No errors found in %s" % path if result.is_valid() else "\n".join(messages)
	_validation_result_dialog.popup_centered(Vector2i(800, 400))
