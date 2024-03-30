extends Control
class_name DQChoiceMenu

signal choice_made(choice: String)

var choices: PackedStringArray = [] : set = set_choices, get = get_choices

@onready
var _buttons_container: Container = %ButtonsContainer

func _ready() -> void:
	hide()

func set_choices(value: PackedStringArray) -> void:
	choices = value
	if not _buttons_container:
		await ready
	
	for n in _buttons_container.get_children():
		_buttons_container.remove_child(n)
		n.queue_free()
	for c in choices:
		var btn = Button.new()
		btn.name = c
		btn.text = c
		btn.pressed.connect(_emit_choice_made.bind(c))
		_buttons_container.add_child(btn)

func get_choices() -> PackedStringArray:
	return choices


func _emit_choice_made(choice: String) -> void:
	choice_made.emit(choice)
