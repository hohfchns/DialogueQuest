@tool
extends Control
class_name DQDialogueBox

## Emitted when all characters are visible
signal all_text_shown
## Emitted when the visible characters is changed
signal text_shown(characters: int)
signal proceed
signal settings_changed(new_settings: DQDialogueBoxSettings)

signal auto_toggle_requested
signal skip_toggle_requested

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

var paused: bool = false

@onready
var _name: Label = %Name
@onready
var _text: RichTextLabel = %DialogueText
@onready
var _portrait: TextureRect = %Portrait
@onready
var _auto_button: Button = %AutoButton : get = get_auto_button
@onready
var _skip_button: Button = %SkipButton : get = get_skip_button
@onready
var _bobbing_marker: DQBobbingMarker = %BobbingMarker

var _letters_time_debt: float = 0.0

func _ready() -> void:
	if portrait_image:
		_portrait.texture = portrait_image
	
	settings_changed.connect(_on_settings_changed)
	_on_settings_changed(settings)
	
	_auto_button.mouse_entered.connect(_auto_button_mouse_entered)
	_auto_button.mouse_exited.connect(_auto_button_mouse_exited)
	_auto_button.pressed.connect(_on_auto_pressed)
	
	_skip_button.mouse_entered.connect(_skip_button_mouse_entered)
	_skip_button.mouse_exited.connect(_skip_button_mouse_exited)
	_skip_button.pressed.connect(_on_skip_pressed)
	
	all_text_shown.connect(_on_all_text_shown)
	proceed.connect(_on_proceed)

func _process(delta: float) -> void:
	if _text.visible_characters == -1:
		return
	if _text.visible_characters >= _text.text.length():
		finish()
		return
	
	if paused:
		return
	
	_letters_time_debt += delta
	
	while _letters_time_debt >= 1.0 / settings.letters_per_second:
		_text.visible_characters = min(_text.visible_characters + 1, _text.text.length())
		_letters_time_debt -= (1.0 / settings.letters_per_second)
		text_shown.emit(_text.visible_characters)

func accept() -> void:
	if _text.visible_characters == -1:
		proceed.emit()
		paused = false
	else:
		finish()

func finish() -> void:
	_text.visible_characters = -1
	_letters_time_debt = 0
	all_text_shown.emit()

func is_finished() -> bool:
	return _text.visible_characters == -1

func start_progressing(from_character: int = 0) -> void:
	set_visible_characters(from_character)

func pause() -> void:
	paused = true

func resume() -> void:
	paused = false

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

func get_auto_button() -> Button:
	return _auto_button

func set_auto_button_active(on: bool) -> void:
	if on:
		_auto_button.theme_type_variation = ""
	else:
		_auto_button.theme_type_variation = "ButtonActivated"

func get_skip_button() -> Button:
	return _skip_button

func set_skip_button_active(on: bool) -> void:
	if on:
		_skip_button.theme_type_variation = ""
	else:
		_skip_button.theme_type_variation = "ButtonActivated"

func _on_settings_changed(new_settings: DQDialogueBoxSettings) -> void:
	layout_direction = new_settings.layout_direction_box
	_name.layout_direction = new_settings.layout_direction_name
	_name.text_direction = new_settings.text_direction_name
	_text.layout_direction = new_settings.layout_direction_text
	_text.text_direction = new_settings.text_direction_text

func _auto_button_mouse_entered() -> void:
	DialogueQuest.Inputs.ignore_next_press()

func _auto_button_mouse_exited() -> void:
	DialogueQuest.Inputs.forget_ignore()

func _on_auto_pressed() -> void:
	auto_toggle_requested.emit()
	_auto_button.release_focus()

func _skip_button_mouse_entered() -> void:
	DialogueQuest.Inputs.ignore_next_press()

func _skip_button_mouse_exited() -> void:
	DialogueQuest.Inputs.forget_ignore()

func _on_skip_pressed() -> void:
	skip_toggle_requested.emit()
	_skip_button.release_focus()

func _on_all_text_shown() -> void:
	if settings.text_finished_marker_enabled:
		_bobbing_marker.icon_visible = true

func _on_proceed() -> void:
	if settings.text_finished_marker_enabled:
		_bobbing_marker.icon_visible = false
