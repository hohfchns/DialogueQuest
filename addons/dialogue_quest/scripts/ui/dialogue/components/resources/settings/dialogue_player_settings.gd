@tool
extends Resource
class_name DQDialoguePlayerSettings

@export_group("Autoplay", "autoplay_")
@export
var autoplay_enabled: bool = false :
	set(value):
		autoplay_enabled = value
		notify_property_list_changed()

@export
var autoplay_delay_sec: float = 0.5

@export
var autoplay_on_start: bool = true

@export_group("Skipping", "skip_")
@export
var skip_enabled: bool = false :
	set(value):
		skip_enabled = value
		notify_property_list_changed()

## How many paragraphs to skip per seconds
@export
var skip_speed: int = 5

@export
var skip_after_choices: bool = false

@export_group("Experimental")
## If enabled, call statements will create a script and run it if the expression evaluation has failed
@export
var run_expressions_as_script: bool = false

func _validate_property(property: Dictionary) -> void:
	if property.name != "autoplay_enabled" and property.name.begins_with("autoplay_"):
		if not autoplay_enabled:
			property.usage = PROPERTY_USAGE_NO_EDITOR
	elif property.name != "skip_enabled" and property.name.begins_with("skip_"):
		if not skip_enabled:
			property.usage = PROPERTY_USAGE_NO_EDITOR
