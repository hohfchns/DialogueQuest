extends Control

@onready
var _player: DQDialoguePlayer = $DialoguePlayer

func _ready() -> void:
	var dialogue_path := "basic_example"
	_player.play(dialogue_path)
	
	DialogueQuest.Signals.dialogue_signal.connect(_on_dialogue_signal)

func _on_dialogue_signal(params: Array) -> void:
	print("Got dialogue params: %s" % str(params))

