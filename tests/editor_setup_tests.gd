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
	plugin.call(&"add_default_dialogue")
	_check(edited.get_child_count() == 1, "The helper must add one CanvasLayer")
	var layer := edited.get_child(0) as CanvasLayer
	_check(layer != null and layer.owner == edited, "The layer must belong to the edited scene")
	_check(layer.get_child_count() == 3, "The helper must add all three components")
	var player: Node = null
	for child in layer.get_children():
		_check(child.owner == edited, "Components must be saved as editable scene instances")
		if child.name == &"DialoguePlayer":
			player = child
	_check(player != null, "The player must exist")
	var box := player.get("dialogue_box") as Control
	_check(box != null and player.get("choice_menu") != null, "The player must reference the generated UI")
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

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error(message)
