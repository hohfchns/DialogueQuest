@tool
extends EditorPlugin

const ADDON_DIR := &"res://addons/dialogue_quest"

const DQ_INTERFACE_AUTOLOAD_NAME := &"DialogueQuest"
const DQ_INTERFACE_SCRIPT := &"res://addons/dialogue_quest/scripts/dialogue_quest_interface.gd"

func _enter_tree() -> void:
	add_autoload_singleton(DQ_INTERFACE_AUTOLOAD_NAME, DQ_INTERFACE_SCRIPT)
	
	DQProjectSettings.prepare()

func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	pass
