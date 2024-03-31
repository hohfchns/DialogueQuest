@tool
extends Control
class_name DQDialogueBox

signal all_text_shown
signal proceed
signal settings_changed(new_settings: DQDialogueBoxSettings)

@export
var settings: DQDialogueBoxSettings :
	set(value):
		settings = value
		settings_changed.emit(value)

@export_multiline
var text: String : set = set_text, get = get_text
@export
var name_text: String : set = set_name_text, get = get_name_text
@export
var portrait_image: Texture2D : set = set_portrait_image, get = get_portrait_image

@onready
var _name: Label = %Name
@onready
var _text: RichTextLabel = %DialogueText
@onready
var _portrait: TextureRect = %Portrait

var _letters_time_debt: float = 0.0

func _ready() -> void:
	if portrait_image:
		_portrait.texture = portrait_image
	
	settings_changed.connect(_on_settings_changed)
	_on_settings_changed(settings)

func _process(delta: float) -> void:
	if _text.visible_characters == -1:
		return
	if _text.visible_characters == _text.text.length():
		finish()
		return
	
	_letters_time_debt += delta
	
	while _letters_time_debt >= 1.0 / settings.letters_per_second:
		_text.visible_characters = min(_text.visible_characters + 1, _text.text.length())
		_letters_time_debt -= (1.0 / settings.letters_per_second)

func accept() -> void:
	if _text.visible_characters == -1:
		proceed.emit()
	else:
		finish()

func finish() -> void:
	_text.visible_characters = -1
	_letters_time_debt = 0
	all_text_shown.emit()

func start_progressing() -> void:
	set_visible_characters(0)

func set_text(value: String) -> void:
	text = value
	if not _text:
		await ready
	_text.text = value

func get_text() -> String:
	return _text.text

func set_name_text(value: String) -> void:
	name_text = value
	if not _name:
		await ready
	_name.text = value

func get_name_text() -> String:
	return _name.text

func set_text_theme(value: Theme) -> void:
	_text.theme = value

func get_text_theme() -> Theme:
	return _text.theme

func set_name_theme(value: Theme) -> void:
	_name.theme = value

func get_name_theme() -> Theme:
	return _name.theme

func get_portrait() -> TextureRect:
	return _portrait

func show_portrait() -> void:
	_portrait.show()

func hide_portrait() -> void:
	_portrait.hide()

func set_portrait_image(value: Texture2D) -> void:
	if not is_node_ready():
		portrait_image = value
		return
	
	_portrait.texture = value

func get_portrait_image() -> Texture2D:
	if not is_node_ready():
		return portrait_image
	
	return _portrait.texture

func set_visible_characters(value: int) -> void:
	_text.visible_characters = value

func set_text_color(value: Color) -> void:
	_text.add_theme_color_override("font_color", value)

func set_name_color(value: Color) -> void:
	_name.add_theme_color_override("font_color", value)

func _on_settings_changed(new_settings: DQDialogueBoxSettings) -> void:
	layout_direction = new_settings.layout_direction_box
	_name.layout_direction = new_settings.layout_direction_name
	_name.text_direction = new_settings.text_direction_name
	_text.layout_direction = new_settings.layout_direction_text
	_text.text_direction = new_settings.text_direction_text
