extends Node
class_name DQDialoguePlayer

@export
var settings: DQDialoguePlayerSettings

@export
var dialogue_box: DQDialogueBox : set = set_dialogue_box, get = get_dialogue_box
@export
var choice_menu: DQChoiceMenu : set = set_choice_menu, get = get_choice_menu

var autoplaying: bool = false

func _ready() -> void:
	DialogueQuest.Inputs.accept_released.connect(accept)
	if settings.autoplay_enabled and settings.autoplay_on_start:
		autoplaying = true

func play(dialogue_path: String) -> void:
	var parsed := DQDqdParser.parse_from_file(dialogue_path)
	if not parsed.size():
		return
	
	dialogue_box.show()
	DialogueQuest.Signals.dialogue_started.emit()
	
	var correct_branch: bool = true
	for p in parsed:
		p.solve_flags()
		
		if p as DQDqdParser.DqdSection.SectionBranch != null:
			p = p as DQDqdParser.DqdSection.SectionBranch
			match p.type:
				DQDqdParser.DqdSection.SectionBranch.Type.END:
					correct_branch = true
				DQDqdParser.DqdSection.SectionBranch.Type.CHOICE:
					if DialogueQuest.Flags.choice_made(p.expression):
						correct_branch = true
						DialogueQuest.Flags.confirm_choice(p.expression)
					else:
						correct_branch = false
				DQDqdParser.DqdSection.SectionBranch.Type.FLAG:
					correct_branch = DialogueQuest.Flags.is_raised(p.expression)
				DQDqdParser.DqdSection.SectionBranch.Type.NO_FLAG:
					correct_branch = not DialogueQuest.Flags.is_raised(p.expression)
				DQDqdParser.DqdSection.SectionBranch.Type.EVALUATE:
					var res: Variant = DQScriptingHelper.evaluate_expression(p.expression, DialogueQuest)
					correct_branch = false
					if res is DQScriptingHelper.Error:
						if settings.run_expressions_as_script:
							if DQScriptingHelper.run_pure_gdscript(p.expression):
								correct_branch = true
					else:
						if res:
							correct_branch = true
		
		if not correct_branch:
			continue
		
		if p as DQDqdParser.DqdSection.SectionSay != null:
			p = p as DQDqdParser.DqdSection.SectionSay
			
			var chara: DQCharacter = p.character
			if chara:
				dialogue_box.set_name_text(chara.character_name)
				dialogue_box.set_text(p.text)
				dialogue_box.set_name_color(chara.color)
				dialogue_box.set_portrait_image(chara.portrait)
				dialogue_box.set_text_theme(chara.custom_theme_text)
				dialogue_box.set_name_theme(chara.custom_theme_name)
				dialogue_box.start_progressing()
			else:
				dialogue_box.set_name_text("")
				dialogue_box.set_text(p.text)
				dialogue_box.set_portrait_image(null)
				dialogue_box.set_text_theme(null)
				dialogue_box.set_name_theme(null)
				dialogue_box.start_progressing()
			
			if settings.autoplay_enabled and autoplaying:
				await dialogue_box.all_text_shown
				get_tree().create_timer(settings.autoplay_delay_sec).timeout.connect(accept)
			
			await dialogue_box.proceed
		elif p as DQDqdParser.DqdSection.SectionRaiseDQSignal != null:
			p = p as DQDqdParser.DqdSection.SectionRaiseDQSignal
			DialogueQuest.Signals.dialogue_signal.emit(p.params)
		elif p as DQDqdParser.DqdSection.SectionEvaluateCall != null:
			p = p as DQDqdParser.DqdSection.SectionEvaluateCall
			p.expression.execute([], DialogueQuest)
			if p.expression.has_execute_failed() and settings.run_expressions_as_script:
				printerr("Executing expression failed, running as script...")
				p.run_as_script()
		elif p as DQDqdParser.DqdSection.SectionFlag != null:
			p = p as DQDqdParser.DqdSection.SectionFlag
			p.raise()
		elif p as DQDqdParser.DqdSection.SectionChoice != null:
			p = p as DQDqdParser.DqdSection.SectionChoice
			choice_menu.choices = p.choices
			choice_menu.show()
			var choice_made: String = await choice_menu.choice_made
			choice_menu.hide()
			DialogueQuest.Flags.make_choice(choice_made)
	
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


