extends Control

@onready
var _player: DQDialoguePlayer = $DialoguePlayer

func _ready() -> void:
	DialogueQuest.Signals.dialogue_signal.connect(_on_dialogue_signal)
	
	_player.play("test_call_and_signal")
	await get_tree().create_timer(0.5).timeout
	_player.play("test_say")
	await DialogueQuest.Signals.dialogue_ended
	await get_tree().create_timer(0.5).timeout
	_player.play("test_flag")
	await DialogueQuest.Signals.dialogue_ended
	await get_tree().create_timer(0.5).timeout
	_player.play("test_branch_and_choice")
	await DialogueQuest.Signals.dialogue_ended
	await get_tree().create_timer(0.5).timeout
	_player.play("test_evaluate")

func _on_dialogue_signal(params: Array) -> void:
	print("Got dialogue params: %s" % str(params))
