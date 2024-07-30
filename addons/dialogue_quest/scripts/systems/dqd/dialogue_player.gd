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
	SectionHandler.new(DQDqdParser.DqdSection.SectionExit, _handle_exit),
	SectionHandler.new(DQDqdParser.DqdSection.SectionPlaySound, _handle_sound)
]

@export
var settings: DQDialoguePlayerSettings

@export
var dialogue_box: DQDialogueBox : set = set_dialogue_box, get = get_dialogue_box
@export
var choice_menu: DQChoiceMenu : set = set_choice_menu, get = get_choice_menu
@export
var custom_bbcodes: Array[String] = ["speed", "pause"]

var autoplaying: bool = false :
	set(value):
		autoplaying = value
		if dialogue_box:
			dialogue_box.set_auto_button_active(autoplaying)
			_wait_for_input()
		if autoplaying and skipping:
			skipping = false

var skipping: bool = false :
	set(value):
		skipping = value
		if dialogue_box:
			dialogue_box.set_skip_button_active(skipping)
			_wait_for_input()
		if skipping and autoplaying:
			autoplaying = false

## The current playing dialogue ID.
var current_dialogue: String = ""

var _lock: bool = false
var _stop_requested: bool = false

var _correct_branch: int = 0
var _current_branch: int = 0

var _dialogue_box_default_speed: int

## Dictionary of bbcode_type([String]): bbcodes([Array]([Dictionary]))
var _current_bbcodes: Dictionary = {}

func _ready() -> void:
	DialogueQuest.Inputs.accept_released.connect(accept)
	
	if not dialogue_box:
		return
	
	if not dialogue_box.is_node_ready():
		await dialogue_box.ready
	
	if not choice_menu.is_node_ready():
		await choice_menu.ready
	
	if settings.autoplay_enabled:
		dialogue_box.auto_toggle_requested.connect(_on_auto_toggle_requested)
		dialogue_box.get_auto_button().show()
		
		if settings.autoplay_on_start:
			autoplaying = true
	else:
		dialogue_box.get_auto_button().hide()
	
	if settings.skip_enabled:
		dialogue_box.skip_toggle_requested.connect(_on_skip_toggle_requested)
		dialogue_box.get_skip_button().show()
	else:
		dialogue_box.get_skip_button().hide()

func play(dialogue_path: String) -> void:
	var parsed := DQDqdParser.parse_from_file(dialogue_path)
	if not parsed.size():
		return

	play_sections(parsed, dialogue_path)

## Starts the dialogue, playing `sections`.
## It is recommended to provide `dialogue_id` with the `.dqd` file path / name.
func play_sections(sections: Array[DQDqdParser.DqdSection], dialogue_id: String="") -> void:
	if _lock:
		var s := "DialogueQuest | Player | Cannot run multiple dialogue instances per player."
		DialogueQuest.error.emit(s)
		assert(false, s)
		return
	
	_lock = true
	_stop_requested = false
	await _play(sections, dialogue_id)
	_lock = false

func stop() -> void:
	if _lock:
		_stop_requested = true

func _wait_for_input() -> void:
	if autoplaying:
		if not dialogue_box.is_finished():
			await dialogue_box.all_text_shown
		get_tree().create_timer(settings.autoplay_delay_sec).timeout.connect(accept)
	elif skipping:
		while not dialogue_box.is_finished():
			accept()
		get_tree().create_timer(1.0 / settings.skip_speed).timeout.connect(accept)
	
	await dialogue_box.proceed

func _play(sections: Array[DQDqdParser.DqdSection], dialogue_id: String="") -> void:
	_correct_branch = 0
	_current_branch = 0
	
	dialogue_box.show()
	current_dialogue = dialogue_id
	DialogueQuest.Signals.dialogue_started.emit(current_dialogue)
	
	for section in sections:
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
	
	if settings.skip_stop_on_dialogue_end:
		skipping = false
	dialogue_box.hide()
	DialogueQuest.Signals.dialogue_ended.emit(current_dialogue)
	current_dialogue = ""

func set_dialogue_box(value: DQDialogueBox) -> void:
	if dialogue_box:
		dialogue_box.text_shown.disconnect(_on_text_shown)
	
	dialogue_box = value
	
	_dialogue_box_default_speed = dialogue_box.settings.letters_per_second
	
	dialogue_box.text_shown.connect(_on_text_shown)

func get_dialogue_box() -> DQDialogueBox:
	return dialogue_box

func set_choice_menu(value: DQChoiceMenu) -> void:
	choice_menu = value

func get_choice_menu() -> DQChoiceMenu:
	return choice_menu

func accept() -> void:
	if dialogue_box and dialogue_box.visible:
		dialogue_box.accept()

## Returns an array consisting of dictionaries with three variables:
## `value` - The value of the bbcode
## `content` - The text within the bbcode
## `final` - `text` with the bbcode removed
## `start_index` - The index in `final` where `content` begins
## `end_index` - The index in `final` where `content` ends
func _extract_bbcode(text: String, tag: String, is_numeral: bool = true) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var pattern := "\\[%s=(?<%s>\\d+\\.?\\d*)\\](?<content>.*)" % [tag, tag]
	var regex := RegEx.new()
	regex.compile(pattern)
	
	var t := text
	var res := regex.search(t)
	
	while res != null:
		var value := res.get_string(tag)
		if not value:
			continue
		
		var d := {}
		
		if is_numeral:
			if not value.is_valid_float():
				var s := "DialogueQuest | DialoguePlayer | %s tag provided bad value (non-number)" % tag
				DialogueQuest.error.emit(s)
				assert(false, s)
			d[tag] = value.to_float()
		else:
			d[tag] = value
		
		var content := res.get_string("content")
		var end_index = content.find("[/%s]" % tag)
		if end_index != -1:
			content = content.substr(0, end_index)
		
		d["content"] = content
		
		var regex_start_index = res.get_start()
		var regex_end_index: int
		
		if end_index == -1:
			regex_end_index = res.get_end()
		else:
			regex_end_index = res.get_start("content") + end_index + len("[/%s]" % tag)
		
		d["final"] = t.substr(0, regex_start_index) + content + t.substr(regex_end_index)
		var start_length: int = res.get_start("content") - regex_start_index
		d["start_index"] = res.get_start("content") - start_length
		d["end_index"] = d["start_index"] + len(content)
		
		out.append(d)
		
		t = d["final"]
		res = regex.search(t)
	
	return out

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
	
	_current_bbcodes = {}
	
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
	
	for bbcode_type in custom_bbcodes:
		var t := section.texts[0]
		var bbcodes := _extract_bbcode(t, bbcode_type)
		for bb_res in bbcodes:
			section.texts[0] = bb_res["final"]
		
		_current_bbcodes[bbcode_type] = bbcodes
	
	dialogue_box.set_text(section.texts[0])
	
	dialogue_box.start_progressing()
	
	var texts := PackedStringArray(section.texts.slice(1))
	if texts.size() == 1:
		if DQScriptingHelper.remove_whitespace(texts[0]).is_empty():
			if not skipping:
				await dialogue_box.all_text_shown
			return
	await _wait_for_input()
	if not texts.size():
		return
	for i in texts.size():
		var prev_len = dialogue_box.text.length()
		
		for bbcode_type in custom_bbcodes:
			var bbcodes := _extract_bbcode(texts[i], bbcode_type)
			
			for bb_res in bbcodes:
				texts[i] = bb_res["final"]
				bb_res["start_index"] += prev_len
				bb_res["end_index"] += prev_len
			
			_current_bbcodes[bbcode_type] = bbcodes
		
		var text: String = texts[i]
		
		dialogue_box.text += text
		dialogue_box.start_progressing(prev_len)
		if i == texts.size() - 2 or (texts.size() - 2) < 0:
			if DQScriptingHelper.remove_whitespace(texts[texts.size() - 1]).is_empty():
				if not skipping:
					await dialogue_box.all_text_shown
				break
		await _wait_for_input()

func _handle_signal(section: DQDqdParser.DqdSection.SectionRaiseDQSignal) -> void:
	DialogueQuest.Signals.dialogue_signal.emit(section.params)

func _handle_call(section: DQDqdParser.DqdSection.SectionEvaluateCall) -> void:
	section.expression.execute([], DialogueQuest)
	if section.expression.has_execute_failed() and settings.run_expressions_as_script:
		section.run_as_script()

func _handle_flag(section: DQDqdParser.DqdSection.SectionFlag) -> void:
	section.raise()

func _handle_choice(section: DQDqdParser.DqdSection.SectionChoice) -> void:
	if not settings.skip_after_choices:
		skipping = false
	choice_menu.choices = section.choices
	choice_menu.show()
	var choice_made: String = await choice_menu.choice_made
	choice_menu.hide()
	DialogueQuest.Flags.make_choice(choice_made)

func _handle_exit(section: DQDqdParser.DqdSection.SectionExit) -> void:
	stop()

func _handle_sound(section: DQDqdParser.DqdSection.SectionPlaySound) -> void:
	var bus := &"Master"
	
	if not section.channel.is_empty():
		bus = section.channel

	DialogueQuest.Sounds.play_sound(section.sound_file, bus, section.volume)

func _on_text_shown(characters: int) -> void:
	dialogue_box.settings.letters_per_second = _dialogue_box_default_speed
	if "speed" in _current_bbcodes:
		for bbcode in _current_bbcodes["speed"]:
			var content_start: int = bbcode["start_index"]
			var content_end: int = bbcode["end_index"]
			if content_start <= characters and characters <= content_end:
				dialogue_box.settings.letters_per_second = bbcode["speed"]
	
	if "pause" in _current_bbcodes:
		for bbcode in _current_bbcodes["pause"]:
			var index: int = bbcode["start_index"]
			if characters == index:
				dialogue_box.pause()
				await get_tree().create_timer(bbcode["pause"]).timeout
				dialogue_box.resume()

func _on_auto_toggle_requested() -> void:
	autoplaying = !autoplaying

func _on_skip_toggle_requested() -> void:
	skipping = !skipping
