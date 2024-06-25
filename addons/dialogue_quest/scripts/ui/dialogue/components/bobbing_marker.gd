@tool
extends Control
class_name DQBobbingMarker

enum {
	DIR_UP = 1,
	DIR_DOWN = -1
}

@onready
var icon: TextureRect = %Icon

@export
var settings: DQBobbingMarkerSettings

@export
var icon_visible: bool:
	set(value):
		if not icon:
			await ready
		icon.visible = value
	get:
		if not icon:
			return false
		return icon.visible

@export
var stop_flag: bool = false
@export
var start_flag: bool = false

func _ready():
	if stop_flag:
		stop_flag = false
		return
	icon.position.y = 0
	_tween_up()

func _process(delta):
	if start_flag:
		start_flag = false
		stop_flag = false
		_tween_up()

func _tween_up() -> void:
	if stop_flag:
		stop_flag = false
		return
	
	if not is_inside_tree():
		return
	
	get_tree().create_tween().tween_property(
		icon,
		"position:y",
		-settings.max_up,
		1.0 / settings.speed
	) \
	.set_ease(Tween.EASE_OUT) \
	.finished.connect(_tween_down, CONNECT_ONE_SHOT)

func _tween_down() -> void:
	if stop_flag:
		stop_flag = false
		return
	
	if not is_inside_tree():
		return
	
	get_tree().create_tween().tween_property(
		icon,
		"position:y",
		settings.max_down,
		1.0 / settings.speed
	) \
	.set_ease(Tween.EASE_OUT) \
	.finished.connect(_tween_up, CONNECT_ONE_SHOT)

