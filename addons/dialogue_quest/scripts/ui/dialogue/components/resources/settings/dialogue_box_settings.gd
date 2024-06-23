extends Resource
class_name DQDialogueBoxSettings

@export_group("Components")
@export
var text_finished_marker_enabled: bool = true

@export_group("Text")
@export
var letters_per_second: float

@export_group("Layout Direction", "layout_direction_")
@export
var layout_direction_box: Control.LayoutDirection
@export
var layout_direction_name: Control.LayoutDirection = Control.LAYOUT_DIRECTION_RTL
@export
var layout_direction_text: Control.LayoutDirection
@export_group("Text Direction", "text_direction_")
@export
var text_direction_name: Control.TextDirection
@export
var text_direction_text: Control.TextDirection
