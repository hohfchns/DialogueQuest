extends Node
## Singleton class for managing settings, registries, etc.
## Singleton classes are managed by the [DialogueQuest] ([DQInterface]) autoload.
class_name DQMainSettings

const DEFAULT_PROJECT_LOCAL_DIR := &"res://dialogue_quest/"

func _ready() -> void:
	_prepare()

func _get_project_local_dir() -> StringName:
	return DQProjectSettings.get_data_dir()

func _prepare() -> void:
	if not DirAccess.dir_exists_absolute(_get_project_local_dir()):
		DirAccess.make_dir_absolute(_get_project_local_dir())
		DirAccess.make_dir_absolute(_get_project_local_dir().path_join("dialogues"))


