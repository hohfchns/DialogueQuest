extends Node
class_name DQInputs

const ACTION_ACCEPT := &"dq_accept"

signal accept_pressed
signal accept_released

func _ready() -> void:
	if not InputMap.has_action(ACTION_ACCEPT):
		InputMap.add_action(ACTION_ACCEPT)
		var event = InputEventKey.new()
		event.keycode = KEY_ENTER
		InputMap.action_add_event(ACTION_ACCEPT, event)
		event = InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event(ACTION_ACCEPT, event)

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed(ACTION_ACCEPT):
		accept_pressed.emit()
	elif Input.is_action_just_released(ACTION_ACCEPT):
		accept_released.emit()
