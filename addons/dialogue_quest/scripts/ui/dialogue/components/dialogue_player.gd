extends Node
class_name DQDialoguePlayer

@export
var settings: DQDialoguePlayerSettings

@export
var dialogue_box: DQDialogueBox : set = set_dialogue_box, get = get_dialogue_box

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
	
	for p in parsed:
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
	
	dialogue_box.hide()
	DialogueQuest.Signals.dialogue_ended.emit()

func set_dialogue_box(value: DQDialogueBox) -> void:
	dialogue_box = value

func get_dialogue_box() -> DQDialogueBox:
	return dialogue_box

func accept() -> void:
	if dialogue_box.visible:
		dialogue_box.accept()


