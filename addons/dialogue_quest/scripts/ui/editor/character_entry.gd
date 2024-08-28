@tool
extends Control
class_name DQEditorCharacterEntry

@onready
var checkbox: CheckBox = %CheckBox
@onready
var _portrait: TextureRect = %Portrait
@onready
var _name: RichTextLabel = %Name
@onready
var _id: RichTextLabel = %ID
@onready
var _color: RichTextLabel = %Color

var _character: DQCharacter = null

func fill(character: DQCharacter) -> void:
	if not is_node_ready():
		await ready
	
	_character = character
	
	_portrait.texture = character.portrait
	var html_color := character.color.to_html()
	_name.text = "[color=%s]%s" % [html_color, character.character_name]
	_name.theme = character.custom_theme_name
	_id.text = character.character_id
	_color.text = "[color=%s]%s" % [html_color, html_color]

func get_character() -> DQCharacter:
	return _character
