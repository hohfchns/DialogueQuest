extends Node
class_name DQRegressionTests

class CustomSection extends DQDqdParser.DqdSection:
	var values: Array = [["${name}"]]

	func solve_flags() -> void:
		values[0][0] = DQDqdParser.solve_flags(values[0][0])

const DIALOGUE_BOX: PackedScene = preload("res://addons/dialogue_quest/prefabs/ui/dialogue/components/dialogue_box/dialogue_box.tscn")
const CHOICE_MENU: PackedScene = preload("res://addons/dialogue_quest/prefabs/ui/dialogue/components/choice_menu/choice_menu.tscn")

var _player: DQDialoguePlayer
var _ended: Array[String] = []
var _failures: int = 0
var _test_directory: String = "res://.godot/dialogue_quest_tests"

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
	_check(_test_replay(), "Replay tests must complete")
	_check(_test_settings(), "Settings tests must complete")
	_check(_test_character_exchange(), "Character exchange tests must complete")
	_check(_test_first_found(), "Lookup tests must complete")
	_check(await _test_text_effects(), "Text effect tests must complete")
	_check(_test_zero_increment(), "Zero increment tests must complete")
	_check(await _test_examples(), "Example playback tests must complete")
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

func _test_replay() -> bool:
	var sections := DQDqdParser.parse_from_text("say | [speed=1]Hello ${name}")
	var original := (sections[0] as DQDqdParser.DqdSection.SectionSay).texts[0]
	var default_speed := _player.dialogue_box.settings.letters_per_second
	DialogueQuest.Flags.set_flag("name", "First")
	_player.play_sections(sections, "replay_first")
	_check(_player.dialogue_box.text == "Hello First", "First playback must resolve flags")
	_player.dialogue_box.text_shown.emit(1)
	_check(_player.dialogue_box.letters_per_second == 1.0, "Speed effects must change runtime speed")
	_check(_player.dialogue_box.settings.letters_per_second == default_speed, "Speed effects must preserve settings")
	_player.stop()
	DialogueQuest.Flags.set_flag("name", "Second")
	_player.play_sections(sections, "replay_second")
	_check(_player.dialogue_box.text == "Hello Second", "Replay must use current flags")
	_check((sections[0] as DQDqdParser.DqdSection.SectionSay).texts[0] == original, "Playback must preserve source text and effects")
	_player.stop()
	var call_section := DQDqdParser.parse_from_text("call | print(1)")[0] as DQDqdParser.DqdSection.SectionEvaluateCall
	var copy := call_section.copy_for_playback() as DQDqdParser.DqdSection.SectionEvaluateCall
	_check(copy.expression != call_section.expression, "Playback expressions must not be shared")
	var custom := CustomSection.new()
	var custom_copy := custom.copy_for_playback() as CustomSection
	custom_copy.solve_flags()
	_check(custom_copy.values[0][0] == "Second", "Custom solve_flags hooks must still work")
	_check(custom.values[0][0] == "${name}", "Nested custom section arrays must remain unchanged")
	return true

func _test_settings() -> bool:
	var setting_name := DQProjectSettings.get_say_by_name_setting()
	var original := DQProjectSettings.get_say_by_name()
	ProjectSettings.set_setting(setting_name, not original)
	var settings := DQMainSettings.new()
	add_child(settings)
	_check(settings.data_directory == DQProjectSettings.get_data_dir(), "Settings must use the configured directory")
	_check(settings.say_by_name == DQProjectSettings.get_say_by_name(), "Settings must use the configured shorthand option")
	ProjectSettings.set_setting(setting_name, original)
	settings.data_directory = "res://examples"
	_check(settings.get_settings().get_value("files", "data_dir") == "res://examples", "Settings snapshots must include runtime overrides")
	settings.queue_free()
	return true

func _test_character_exchange() -> bool:
	DirAccess.make_dir_recursive_absolute(_test_directory)
	var character := DQCharacter.new()
	character.character_id = "test_character"
	character.character_name = "Original"
	character.color = Color.CORNFLOWER_BLUE
	var path := _test_directory.path_join("test_character.dqc")
	var resource_path := _test_directory.path_join("test_character.tres")
	_check(character.serialize_to_file(path) == OK, "Character export must succeed")
	var imported := DQCharacter.new()
	_check(imported.deserialize_from_file(path, resource_path) == OK, "Character import must succeed")
	_check(imported.character_name == "Original", "Character metadata must round-trip")
	var cached := load(resource_path) as DQCharacter
	character.character_name = "Updated"
	_check(character.serialize_to_file(path) == OK, "Export must replace an existing file")
	_check(imported.deserialize_from_file(path, resource_path) == OK, "Import must replace an existing resource")
	_check(cached.character_name == "Updated", "Reimporting must refresh cached characters")
	var saved := ResourceLoader.load(resource_path, "", ResourceLoader.CACHE_MODE_IGNORE) as DQCharacter
	_check(saved.character_name == "Updated", "The saved resource must contain the update")
	var original_file := FileAccess.get_file_as_string(resource_path)
	var invalid := FileAccess.open(path, FileAccess.WRITE)
	invalid.store_string(var_to_str({"name": "Invalid"}))
	invalid.close()
	_check(imported.deserialize_from_file(path, resource_path) == ERR_INVALID_DATA, "Malformed imports must fail")
	_check(imported.character_name == "Updated", "Malformed imports must not change existing data")
	_check(FileAccess.get_file_as_string(resource_path) == original_file, "Malformed imports must preserve the destination")
	_check(DQCharacterDBMigrator.import_characters([path], _test_directory) == 0, "Failed imports must not count an existing destination as success")
	character.character_id = "../outside"
	_check(character.serialize_to_file(path) == ERR_INVALID_DATA, "Character IDs must not contain paths")
	character.character_id = "test_character"
	_check(character.serialize_to_file(path) == OK, "Valid exports must recover after failure")
	_check(character.serialize_to_file(_test_directory.path_join("missing/character.dqc")) != OK, "Unwritable destinations must report failure")
	var invalid_character := DQCharacter.new()
	invalid_character.character_id = "../invalid"
	_check(DQCharacterDBMigrator.export_characters([character, invalid_character], _test_directory) == 1, "Exports must count only successful writes")
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(resource_path)
	return true

func _test_first_found() -> bool:
	var original_directory: String = DialogueQuest.Settings.data_directory
	var directory := _test_directory.path_join("lookup")
	for folder in ["a", "b"]:
		DirAccess.make_dir_recursive_absolute(directory.path_join(folder))
		var file := FileAccess.open(directory.path_join(folder).path_join("duplicate.dqd"), FileAccess.WRITE)
		file.store_string("say | %s" % folder)
		file.close()
		var character := DQCharacter.new()
		character.character_id = "duplicate"
		character.character_name = folder
		ResourceSaver.save(character, directory.path_join(folder).path_join("character.tres"))
	DialogueQuest.Settings.data_directory = directory
	var files := DQFilesystemHelper.get_all_files(directory, true, ["dqd"])
	var result := DQDqdParser.validate_from_file("duplicate")
	_check(result.is_valid() and result.sections[0].source_path == files[0], "Short names must select the first discovered dialogue")
	var characters := DQFilesystemHelper.get_all_files(directory, true, ["tres"])
	_check(DialogueQuest.CharacterDB.get_character_from_id("duplicate").resource_path == characters[0], "Duplicate character IDs must keep the first discovered resource")
	_check(not DQDqdParser.validate_from_file(directory.path_join("missing/duplicate.dqd")).is_valid(), "Explicit missing paths must not select unrelated files")
	DialogueQuest.Settings.data_directory = original_directory
	for path in files + characters:
		DirAccess.remove_absolute(path)
	return true

func _test_text_effects() -> bool:
	_check(DQDialogueBoxSettings.new().letters_per_second > 0.0, "New settings must have a usable speed")
	_player.play_sections(DQDqdParser.parse_from_text("say | [b]Hi[/b]"), "rich_text")
	_check(_player.dialogue_box.get_total_character_count() == 2, "Character counts must exclude markup")
	await get_tree().create_timer(0.2).timeout
	_check(_player.dialogue_box.is_finished(), "Markup must not add invisible typing delays")
	_player.stop()
	_player.play_sections(DQDqdParser.parse_from_text("say | [b]A[/b][pause=0.1][speed=5]B[/speed]C"), "mixed_effects")
	_player.dialogue_box.text_shown.emit(1)
	_check(_player.dialogue_box.paused, "Pauses must use displayed character positions")
	_check(_player.dialogue_box.letters_per_second == 5.0, "Speed effects must ignore other markup")
	_player.dialogue_box.text_shown.emit(2)
	_check(_player.dialogue_box.letters_per_second == _player.dialogue_box.settings.letters_per_second, "Closing a speed span must restore the default")
	_player.stop()
	_player.play_sections(DQDqdParser.parse_from_text("say | [pause=0.1]Start"), "initial_pause")
	_check(_player.dialogue_box.paused, "Effects at character zero must run before revealing text")
	_player.stop()
	_player.play_sections(DQDqdParser.parse_from_text("say || [b]Hi[/b]|[pause=0.1]there"), "split_effects")
	_player.dialogue_box.finish()
	_player.accept()
	_check(_player.dialogue_box.paused, "Split text must resume at the displayed character offset")
	_player.stop()
	return true

func _test_zero_increment() -> bool:
	_player.play_sections(DQDqdParser.parse_from_text("flag | set | 10 | score\nflag | inc | 0 | score"), "zero_increment")
	_check(DialogueQuest.Flags.get_flag("score") == 10, "An explicit zero increment must not change the flag")
	_player.play_sections(DQDqdParser.parse_from_text("flag | set | 10 | score\nflag | dec | 0 | score"), "zero_decrement")
	_check(DialogueQuest.Flags.get_flag("score") == 10, "An explicit zero decrement must not change the flag")
	return true

func _test_examples() -> bool:
	_player.settings.run_expressions_as_script = true
	for path in DQFilesystemHelper.get_all_files("res://dialogue_quest/dialogues/tests", true, ["dqd"]):
		DialogueQuest.Flags.flag_registry.clear()
		_player.play(path)
		var frames := 0
		while not _player.current_dialogue.is_empty() and frames < 500:
			_check(not "ERROR" in _player.dialogue_box.text, "Example entered a failing branch: %s" % path)
			if _player.choice_menu.visible:
				_player.choice_menu.choice_made.emit(_player.choice_menu.choices[0])
			else:
				_player.accept()
			frames += 1
			await get_tree().process_frame
		_check(_player.current_dialogue.is_empty(), "Example must complete: %s" % path)
		if path.ends_with("test_call_and_signal.dqd"):
			_check(DialogueQuest.Flags.is_raised("test_call_flag"), "Call examples must run their flag changes")
		if path.ends_with("test_flag.dqd"):
			_check(DialogueQuest.Flags.get_flag("dec_negative") == -5, "Flag examples must produce the expected result")
		_player.stop()
	_player.settings.run_expressions_as_script = false
	return true
