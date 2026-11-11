extends Node
class_name DQRegressionTests

const DIALOGUE_BOX: PackedScene = preload("res://addons/dialogue_quest/prefabs/ui/dialogue/components/dialogue_box/dialogue_box.tscn")
const CHOICE_MENU: PackedScene = preload("res://addons/dialogue_quest/prefabs/ui/dialogue/components/choice_menu/choice_menu.tscn")

var _player: DQDialoguePlayer
var _ended: Array[String] = []
var _failures: int = 0

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	var box := DIALOGUE_BOX.instantiate() as DQDialogueBox
	var menu := CHOICE_MENU.instantiate() as DQChoiceMenu
	add_child(box)
	add_child(menu)
	_player = DQDialoguePlayer.new()
	_player.settings = DQDialoguePlayerSettings.new()
	_player.dialogue_box = box
	_player.choice_menu = menu
	add_child(_player)
	DialogueQuest.Signals.dialogue_ended.connect(_on_dialogue_ended)
	_check(await _test_lifecycle(), "Lifecycle tests must complete")
	_check(_test_validation(), "Validation tests must complete")
	print("DialogueQuest regression tests: %s failure(s)" % _failures)
	get_tree().quit(1 if _failures else 0)

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error(message)

func _test_lifecycle() -> bool:
	_player.play_sections(DQDqdParser.parse_from_text("say || Waiting | More"), "stop_text")
	_player.stop()
	_check(_player.current_dialogue.is_empty(), "Stopping text must clear the current dialogue")
	_check(not _player.dialogue_box.visible, "Stopping must hide the dialogue box")
	_check(_ended.count("stop_text") == 1, "Stopping must finish once")
	_player.play_sections(DQDqdParser.parse_from_text("choice | A | B"), "stop_choice")
	_player.stop()
	_check(not _player.choice_menu.visible, "Stopping must hide the choice menu")
	_check(_ended.count("stop_choice") == 1, "Stopping a choice must finish once")
	_player.play_sections(DQDqdParser.parse_from_text("say || Revealing |"), "stop_reveal")
	_player.stop()
	_check(_ended.count("stop_reveal") == 1, "Stopping must release text-reveal waits")
	_player.play_sections(DQDqdParser.parse_from_text("exit |"), "chain_first")
	_check(_player.current_dialogue == "chain_second", "Completion handlers must be able to start dialogue")
	_player.stop()
	_player.settings.autoplay_delay_sec = 0.05
	_player.autoplaying = true
	_player.play_sections(DQDqdParser.parse_from_text("say | Old"), "old_timer")
	_player.dialogue_box.finish()
	_player.stop()
	_player.autoplaying = false
	_player.play_sections(DQDqdParser.parse_from_text("say | New"), "new_timer")
	_player.dialogue_box.finish()
	await get_tree().create_timer(0.1).timeout
	_check(_player.current_dialogue == "new_timer", "Old timers must not advance a new dialogue")
	_player.stop()
	_player.play_sections(DQDqdParser.parse_from_text("say | Toggle"), "toggle_timer")
	_player.dialogue_box.finish()
	_player.autoplaying = true
	_player.autoplaying = false
	await get_tree().create_timer(0.1).timeout
	_check(_player.current_dialogue == "toggle_timer", "Disabling autoplay must cancel its timer")
	_player.stop()
	return true

func _on_dialogue_ended(dialogue_id: String) -> void:
	_ended.append(dialogue_id)
	if dialogue_id == "chain_first":
		_player.play_sections(DQDqdParser.parse_from_text("say | Next"), "chain_second")

func _test_validation() -> bool:
	var result := DQDqdParser.validate_from_text("flag | typo | score\nbranch | end\nbranch | flag | score\nunknown | value", "example.dqd")
	_check(result.errors.size() == 4, "Validation must collect independent syntax and branch errors")
	_check(result.errors[0].source_line == 1 and result.errors[0].source_path == "example.dqd", "Diagnostics must retain their source")
	_check(not DQDqdParser.validate_from_file("res://missing_dialogue.dqd").is_valid(), "Missing files must return diagnostics")
	_check(not DQDqdParser.validate_from_text("branch | typo | score").is_valid(), "Unknown branches must return diagnostics")
	_check(not DQDqdParser.validate_from_text("flag | raise | score | extra").is_valid(), "Extra flag arguments must be rejected")
	_check(not DQDqdParser.validate_from_text("exit | extra").is_valid(), "Extra exit arguments must be rejected")
	_check(DQDqdParser.validate_from_text("branch | flag | score\nsay | Hello\nbranch | end").is_valid(), "Balanced branches must validate")
	for path in DQFilesystemHelper.get_all_files("res://dialogue_quest/dialogues", true, ["dqd"]):
		_check(DQDqdParser.validate_from_file(path).is_valid(), "Existing dialogue must validate: %s" % path)
	return true
