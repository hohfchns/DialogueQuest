@tool
extends EditorPlugin
class_name DQEditorPlugin

const ADDON_DIR := &"res://addons/dialogue_quest"

const DQ_INTERFACE_AUTOLOAD_NAME := &"DialogueQuest"
const DQ_INTERFACE_SCRIPT := &"res://addons/dialogue_quest/scripts/dialogue_quest_interface.gd"

const DQ_PANEL = preload("res://addons/dialogue_quest/prefabs/ui/editor/dialogue_quest_menu.tscn")
const DQ_PLAYER: PackedScene = preload("res://addons/dialogue_quest/prefabs/systems/dqd/dialogue_player.tscn")
const DQ_BOX: PackedScene = preload("res://addons/dialogue_quest/prefabs/ui/dialogue/components/dialogue_box/dialogue_box.tscn")
const DQ_CHOICES: PackedScene = preload("res://addons/dialogue_quest/prefabs/ui/dialogue/components/choice_menu/choice_menu.tscn")

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
	add_tool_menu_item("Add DialogueQuest UI", add_default_dialogue)

func _exit_tree() -> void:
	remove_tool_menu_item("Validate DialogueQuest Dialogue")
	remove_tool_menu_item("Add DialogueQuest UI")
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
		if not DialogueQuest.is_node_ready():
			await DialogueQuest.ready
		DialogueQuest.CharacterDB.refresh()

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

## Adds the default components to the current scene as one undoable editor action.
func add_default_dialogue() -> void:
	var scene_root := EditorInterface.get_edited_scene_root()
	if not scene_root:
		_validation_result_dialog.title = "Add DialogueQuest UI"
		_validation_result_dialog.dialog_text = "Create or open a scene before adding dialogue components."
		_validation_result_dialog.popup_centered()
		return
	var layer := CanvasLayer.new()
	layer.name = &"DialogueQuestUI"
	var box := DQ_BOX.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE) as DQDialogueBox
	var choices := DQ_CHOICES.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE) as DQChoiceMenu
	var player := DQ_PLAYER.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE) as DQDialoguePlayer
	box.settings = box.settings.duplicate(true) as DQDialogueBoxSettings
	player.settings = player.settings.duplicate(true) as DQDialoguePlayerSettings
	box.text = ""
	box.name_text = ""
	box.portrait_image = null
	box.hide()
	layer.add_child(box)
	layer.add_child(choices)
	layer.add_child(player)
	player.dialogue_box = box
	player.choice_menu = choices
	var undo_redo := get_undo_redo()
	undo_redo.create_action("Add DialogueQuest UI", UndoRedo.MERGE_DISABLE, scene_root)
	undo_redo.add_do_method(scene_root, &"add_child", layer, true)
	undo_redo.add_do_property(layer, &"owner", scene_root)
	for child in layer.get_children():
		undo_redo.add_do_property(child, &"owner", scene_root)
	undo_redo.add_do_method(EditorInterface.get_selection(), &"clear")
	undo_redo.add_do_method(EditorInterface.get_selection(), &"add_node", layer)
	undo_redo.add_undo_method(scene_root, &"remove_child", layer)
	undo_redo.add_do_reference(layer)
	undo_redo.commit_action()
