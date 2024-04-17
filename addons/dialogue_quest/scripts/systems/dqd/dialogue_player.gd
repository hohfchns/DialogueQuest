extends Node
class_name DQDialoguePlayer

class SectionHandler:
	var section_class: GDScript
	var callback: Callable
	func _init(section_class: GDScript, callback: Callable):
		self.section_class = section_class
		self.callback = callback

var section_handlers: Array[SectionHandler] = [
	SectionHandler.new(DQDqdParser.DqdSection.SectionSay, _handle_say),
	SectionHandler.new(DQDqdParser.DqdSection.SectionRaiseDQSignal, _handle_signal),
	SectionHandler.new(DQDqdParser.DqdSection.SectionEvaluateCall, _handle_call),
	SectionHandler.new(DQDqdParser.DqdSection.SectionFlag, _handle_flag),
	SectionHandler.new(DQDqdParser.DqdSection.SectionChoice, _handle_choice),
	SectionHandler.new(DQDqdParser.DqdSection.SectionExit, _handle_exit)
]

@export
var settings: DQDialoguePlayerSettings

@export
var dialogue_box: DQDialogueBox : set = set_dialogue_box, get = get_dialogue_box
@export
var choice_menu: DQChoiceMenu : set = set_choice_menu, get = get_choice_menu

var autoplaying: bool = false

var _lock: bool = false
var _stop_requested: bool = false

var _correct_branch: int = 0
var _current_branch: int = 0

func _ready() -> void:
	DialogueQuest.Inputs.accept_released.connect(accept)
	if settings.autoplay_enabled and settings.autoplay_on_start:
		autoplaying = true

func play(dialogue_path: String) -> void:
	if _lock:
		var s := "DialogueQuest | Player | Cannot run multiple dialogue instances per player."
		DialogueQuest.error.emit(s)
		assert(false, s)
		return
	
	_lock = true
	_stop_requested = false
	await _play(dialogue_path)
	_lock = false

func stop() -> void:
	if _lock:
		_stop_requested = true

func _wait_for_input() -> void:
	if settings.autoplay_enabled and autoplaying:
		await dialogue_box.all_text_shown
		get_tree().create_timer(settings.autoplay_delay_sec).timeout.connect(accept)
		
	await dialogue_box.proceed

func _play(dialogue_path: String) -> void:
	var parsed := DQDqdParser.parse_from_file(dialogue_path)
	if not parsed.size():
		return
	
	_correct_branch = 0
	
	dialogue_box.show()
	DialogueQuest.Signals.dialogue_started.emit()
	
	for section in parsed:
		if _stop_requested:
			break
		
		section.solve_flags()

		if section is DQDqdParser.DqdSection.SectionBranch:
			_handle_branch(section)
		
		if _correct_branch != _current_branch:
			continue
		
		for handler in section_handlers:
			if is_instance_of(section, handler.section_class):
				await handler.callback.call(section)
	
	dialogue_box.hide()
	DialogueQuest.Signals.dialogue_ended.emit()

func set_dialogue_box(value: DQDialogueBox) -> void:
	dialogue_box = value

func get_dialogue_box() -> DQDialogueBox:
	return dialogue_box

func set_choice_menu(value: DQChoiceMenu) -> void:
	choice_menu = value

func get_choice_menu() -> DQChoiceMenu:
	return choice_menu

func accept() -> void:
	if dialogue_box.visible:
		dialogue_box.accept()

func _handle_branch(section: DQDqdParser.DqdSection.SectionBranch) -> void:
	if section.type == DQDqdParser.DqdSection.SectionBranch.Type.END:
		_current_branch -= 1
		_correct_branch = min(_current_branch, _correct_branch)
		return
	
	if _correct_branch != _current_branch:
		_current_branch += 1
		return
	
	match section.type:
		DQDqdParser.DqdSection.SectionBranch.Type.CHOICE:
			if DialogueQuest.Flags.choice_made(section.expression):
				_correct_branch += 1
				DialogueQuest.Flags.confirm_choice(section.expression)
		DQDqdParser.DqdSection.SectionBranch.Type.FLAG:
			if DialogueQuest.Flags.is_raised(section.expression):
				_correct_branch += 1
		DQDqdParser.DqdSection.SectionBranch.Type.NO_FLAG:
			if not DialogueQuest.Flags.is_raised(section.expression):
				_correct_branch += 1
		DQDqdParser.DqdSection.SectionBranch.Type.EVALUATE:
			var res: Variant = DQScriptingHelper.evaluate_expression(section.expression, DialogueQuest)
			var correct = false
			if res is DQScriptingHelper.Error:
				if settings.run_expressions_as_script:
					if DQScriptingHelper.evaluate_gdscript(section.expression):
						correct = true
			else:
				if res:
					correct = true
			
			if correct:
				_correct_branch += 1
	
	_current_branch += 1

func _handle_say(section: DQDqdParser.DqdSection.SectionSay) -> void:
	if not section.texts.size():
		return
	
	var chara: DQCharacter = section.character
	if chara:
		dialogue_box.set_name_text(chara.character_name)
		dialogue_box.set_name_color(chara.color)
		dialogue_box.set_portrait_image(chara.portrait)
		dialogue_box.set_text_theme(chara.custom_theme_text)
		dialogue_box.set_name_theme(chara.custom_theme_name)
	else:
		dialogue_box.set_name_text("")
		dialogue_box.set_portrait_image(null)
		dialogue_box.set_text_theme(null)
		dialogue_box.set_name_theme(null)
		dialogue_box.start_progressing()

	dialogue_box.set_text(section.texts[0])
	dialogue_box.start_progressing()
	var texts := PackedStringArray(section.texts.slice(1))
	if texts.size() == 1:
		if DQScriptingHelper.remove_whitespace(texts[0]).is_empty():
			await dialogue_box.all_text_shown
			return
	await _wait_for_input()
	if not texts.size():
		return
	for i in texts.size():
		var text: String = texts[i]
		var prev_len = dialogue_box.text.length()
		dialogue_box.text += text
		dialogue_box.start_progressing(prev_len)
		if i == texts.size() - 2 or (texts.size() - 2) < 0:
			if DQScriptingHelper.remove_whitespace(texts[texts.size() - 1]).is_empty():
				await dialogue_box.all_text_shown
				break
		await _wait_for_input()

func _handle_signal(section: DQDqdParser.DqdSection.SectionRaiseDQSignal) -> void:
	DialogueQuest.Signals.dialogue_signal.emit(section.params)

func _handle_call(section: DQDqdParser.DqdSection.SectionEvaluateCall) -> void:
	section.expression.execute([], DialogueQuest)
	if section.expression.has_execute_failed() and settings.run_expressions_as_script:
		printerr("Executing expression failed, running as script...")
		section.run_as_script()

func _handle_flag(section: DQDqdParser.DqdSection.SectionFlag) -> void:
	section.raise()

func _handle_choice(section: DQDqdParser.DqdSection.SectionChoice) -> void:
	choice_menu.choices = section.choices
	choice_menu.show()
	var choice_made: String = await choice_menu.choice_made
	choice_menu.hide()
	DialogueQuest.Flags.make_choice(choice_made)

func _handle_exit(section: DQDqdParser.DqdSection.SectionExit) -> void:
	stop()
