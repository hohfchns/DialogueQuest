extends Node
class_name DQInterface

signal error(message: String)

var _signals := DQSignals.new()
var _flags := DQFlags.new()
var _inputs := DQInputs.new()
var _settings := DQMainSettings.new()
var _character_db := DQCharacterDB.new()

var Signals: DQSignals :
	set(value):
		pass
	get:
		return _signals

var Flags: DQFlags:
	set(value):
		pass
	get:
		return _flags

var Settings: DQMainSettings :
	set(value):
		pass
	get:
		return _settings

var CharacterDB: DQCharacterDB :
	set(value):
		pass
	get:
		return _character_db

var Inputs : DQInputs:
	set(value):
		pass
	get:
		return _inputs

func _ready() -> void:
	add_child(_signals)
	add_child(_flags)
	add_child(_inputs)
	add_child(_settings)
	add_child(_character_db)
