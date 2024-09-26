@tool
extends EditorPlugin

const ADDON_DIR := &"res://addons/dialogue_quest"

const DQ_INTERFACE_AUTOLOAD_NAME := &"DialogueQuest"
const DQ_INTERFACE_SCRIPT := &"res://addons/dialogue_quest/scripts/dialogue_quest_interface.gd"

const DQ_PANEL = preload("res://addons/dialogue_quest/prefabs/ui/editor/dialogue_quest_menu.tscn")

var main_panel_instance: Control = null

func _enter_tree() -> void:
	add_autoload_singleton(DQ_INTERFACE_AUTOLOAD_NAME, DQ_INTERFACE_SCRIPT)
	
	DQProjectSettings.prepare()

	main_panel_instance = DQ_PANEL.instantiate()
	main_screen_changed.connect(_on_main_screen_changed)
	EditorInterface.get_editor_main_screen().add_child(main_panel_instance)
	_make_visible(false)

func _exit_tree() -> void:
	if main_panel_instance:
		main_panel_instance.queue_free()

func _make_visible(visible):
	if main_panel_instance:
		main_panel_instance.visible = visible

func _has_main_screen():
	return true

func _get_plugin_name():
	return "DialogueQuest"

func _on_main_screen_changed(screen_name: String) -> void:
	if screen_name == _get_plugin_name():
		var dq = Engine.get_singleton(&"DialogueQuest")
		if not dq:
			return
		
		if not dq.is_node_ready():
			await dq.ready
		
		main_panel_instance._refresh_character_db_entries()
