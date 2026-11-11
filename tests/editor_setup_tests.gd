extends SceneTree
class_name DQEditorSetupTests

var _failures: int = 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	await create_timer(1.0).timeout
	while EditorInterface.get_resource_filesystem().is_scanning():
		await process_frame
	var source := Node2D.new()
	source.name = &"SetupTest"
	var scene := PackedScene.new()
	_check(scene.pack(source) == OK, "The test scene must pack")
	_check(ResourceSaver.save(scene, "res://.godot/editor_setup_source.tscn") == OK, "The test scene must save")
	source.free()
	EditorInterface.open_scene_from_path("res://.godot/editor_setup_source.tscn")
	await process_frame
	var edited := EditorInterface.get_edited_scene_root()
	_check(edited != null, "The test scene must open")
	var plugin: EditorPlugin = null
	for node in root.find_children("*", "EditorPlugin", true, false):
		var script := node.get_script() as GDScript
		if script and script.resource_path == "res://addons/dialogue_quest/dialogue_quest.gd":
			plugin = node as EditorPlugin
	_check(plugin != null, "The addon must be enabled")
	if not plugin or not edited:
		quit(1)
		return
	await _test_validation()
	plugin.call(&"add_default_dialogue")
	_check(edited.get_child_count() == 1, "The helper must add one CanvasLayer")
	var layer := edited.get_child(0) as CanvasLayer
	_check(layer != null and layer.owner == edited, "The layer must belong to the edited scene")
	_check(layer.get_child_count() == 3, "The helper must add all three components")
	var player: Node = null
	for child in layer.get_children():
		_check(child.owner == edited, "Components must be saved as editable scene instances")
		if child is CanvasItem:
			_check(child.visible, "Generated UI components must be visible in the editor")
		if child.name == &"DialoguePlayer":
			player = child
	_check(player != null, "The player must exist")
	var box := player.get("dialogue_box") as Control
	_check(box != null and player.get("choice_menu") != null, "The player must reference the generated UI")
	_check(not String(box.get("text")).is_empty() and not String(box.get("name_text")).is_empty(), "The editor preview must retain default text and name")
	_check(box.get("portrait_image") != null, "The editor preview must retain its default portrait")
	var player_settings := player.get("settings") as Resource
	var box_settings := box.get("settings") as Resource
	_check(player_settings.resource_path.is_empty(), "Player settings must be independent of addon defaults")
	_check(box_settings.resource_path.is_empty(), "Box settings must be independent of addon defaults")
	var manager := plugin.get_undo_redo()
	var history := manager.get_history_undo_redo(manager.get_object_history_id(edited))
	history.undo()
	_check(edited.get_child_count() == 0, "Undo must remove the generated setup")
	history.redo()
	_check(edited.get_child_count() == 1 and layer.owner == edited, "Redo must restore the setup and ownership")
	_check(scene.pack(edited) == OK, "The generated setup must pack")
	_check(ResourceSaver.save(scene, "res://.godot/editor_setup_saved.tscn") == OK, "The generated setup must save")
	history.undo()
	print("DialogueQuest editor tests: %d failure(s)" % _failures)
	quit(_failures)

func _test_validation() -> void:
	EditorInterface.get_base_control().get_window().size = Vector2i(1280, 720)
	var file_dialog: EditorFileDialog = null
	for node in EditorInterface.get_base_control().find_children("*", "EditorFileDialog", true, false):
		var dialog := node as EditorFileDialog
		if dialog.title == "Validate Dialogue":
			file_dialog = dialog
	_check(file_dialog != null, "The editor validation file dialog must exist")
	if not file_dialog:
		return
	file_dialog.current_path = "res://dialogue_quest/dialogues/basic_example.dqd"
	file_dialog.popup_centered(Vector2i(800, 400))
	file_dialog.get_ok_button().pressed.emit()
	await process_frame
	await process_frame
	var result_dialog: AcceptDialog = null
	for node in EditorInterface.get_base_control().find_children("*", "AcceptDialog", true, false):
		var dialog := node as AcceptDialog
		if dialog.title == "Dialogue Validation Succeeded":
			result_dialog = dialog
	_check(result_dialog != null, "Validation must open its result dialog")
	if not result_dialog:
		return
	_check(not file_dialog.visible and result_dialog.visible, "The success message must remain visible after the file dialog closes")
	_check(result_dialog.dialog_text.begins_with("Validation successful.") and result_dialog.dialog_text.contains("res://dialogue_quest/dialogues/basic_example.dqd"), "The success message must identify the validated file")
	result_dialog.hide()
	var path := "res://.godot/editor_invalid.dqd"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("say | Valid\nunknown | Invalid\nbranch | end")
	file.close()
	file_dialog.file_selected.emit(path)
	_check(result_dialog.title == "Dialogue Validation Failed", "Invalid dialogue must replace the success result")
	_check(result_dialog.dialog_text.contains(path + ":2") and result_dialog.dialog_text.contains("unknown"), "The editor must report invalid statements with their source line")
	_check(result_dialog.dialog_text.contains(path + ":3") and result_dialog.dialog_text.contains("Unmatched branch end"), "The editor must validate branch structure")
	result_dialog.hide()

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error(message)
