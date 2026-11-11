extends Node
class_name DQDialoguePlayer

signal playback_cancelled

class PlaybackWait:
	signal completed
	var value: Variant = null

	func complete(result: Variant = null) -> void:
		value = result
		completed.emit()

	func cancel() -> void:
		completed.emit()

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
var settings: DQDialoguePlayerSettings = DQDialoguePlayerSettings.new()

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
		if autoplaying and skipping:
			skipping = false
		_update_advance_timer()

var skipping: bool = false :
	set(value):
		skipping = value
		if dialogue_box:
			dialogue_box.set_skip_button_active(skipping)
		if skipping and autoplaying:
			autoplaying = false
		_update_advance_timer()

## The current playing dialogue ID.
var current_dialogue: String = ""

var _lock: bool = false
var _run_id: int = 0
var _waiting_for_input: bool = false
var _advance_timer := Timer.new()
var _pause_timer := Timer.new()

var _correct_branch: int = 0
var _current_branch: int = 0

class TextEffect:
	var tag: StringName
	var value: float
	var start_index: int
	var end_index: int = -1

class PreparedText:
	var text: String = ""
	var effects: Array[TextEffect] = []

var _current_effects: Array[TextEffect] = []
var _last_pause_index: int = -1

func _ready() -> void:
	_advance_timer.one_shot = true
	_pause_timer.one_shot = true
	add_child(_advance_timer)
	add_child(_pause_timer)
	_advance_timer.timeout.connect(accept)
	_pause_timer.timeout.connect(_on_pause_timeout)
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
	_run_id += 1
	_play(sections, dialogue_id, _run_id)

func stop() -> void:
	if _lock:
		_finish_playback()

func _finish_playback() -> void:
	var dialogue_id := current_dialogue
	_lock = false
	_run_id += 1
	_waiting_for_input = false
	_advance_timer.stop()
	_pause_timer.stop()
	if settings.skip_stop_on_dialogue_end:
		skipping = false
	dialogue_box.resume()
	dialogue_box.hide()
	choice_menu.hide()
	_current_effects.clear()
	current_dialogue = ""
	playback_cancelled.emit()
	DialogueQuest.Signals.dialogue_ended.emit(dialogue_id)

## Returns the signal's first argument, or [null] when cancelled.
func _wait_for_signal(source: Signal) -> Variant:
	var pending := PlaybackWait.new()
	source.connect(pending.complete)
	playback_cancelled.connect(pending.cancel)
	await pending.completed
	source.disconnect(pending.complete)
	playback_cancelled.disconnect(pending.cancel)
	return pending.value

func _wait_for_input() -> void:
	var run_id := _run_id
	_waiting_for_input = true
	_update_advance_timer()
	await _wait_for_signal(dialogue_box.proceed)
	if run_id != _run_id:
		return
	_waiting_for_input = false
	_advance_timer.stop()

func _update_advance_timer() -> void:
	if not _advance_timer.is_inside_tree():
		return
	_advance_timer.stop()
	if not _lock or not _waiting_for_input:
		return
	if skipping:
		if settings.skip_speed <= 0:
			var s := "DialogueQuest | Player | Skip speed must be positive"
			DialogueQuest.error.emit(s)
			assert(false, s)
			return
		if not dialogue_box.is_finished():
			dialogue_box.finish()
		_advance_timer.start(1.0 / settings.skip_speed)
	elif autoplaying and dialogue_box.is_finished():
		if not is_finite(settings.autoplay_delay_sec) or settings.autoplay_delay_sec < 0.0:
			var s := "DialogueQuest | Player | Autoplay delay must be a non-negative finite number"
			DialogueQuest.error.emit(s)
			assert(false, s)
			return
		_advance_timer.start(maxf(settings.autoplay_delay_sec, 0.001))

func _play(sections: Array[DQDqdParser.DqdSection], dialogue_id: String, run_id: int) -> void:
	_correct_branch = 0
	_current_branch = 0
	
	dialogue_box.show()
	current_dialogue = dialogue_id
	DialogueQuest.Signals.dialogue_started.emit(current_dialogue)
	
	for source in sections:
		if run_id != _run_id:
			return
		
		var section := source.copy_for_playback()
		section.solve_flags()

		if section is DQDqdParser.DqdSection.SectionBranch:
			_handle_branch(section)
		
		if _correct_branch != _current_branch:
			continue
		
		for handler in section_handlers:
			if run_id != _run_id:
				return
			if is_instance_of(section, handler.section_class):
				await handler.callback.call(section)
	
	if run_id == _run_id:
		_finish_playback()

func set_dialogue_box(value: DQDialogueBox) -> void:
	if dialogue_box:
		dialogue_box.text_shown.disconnect(_on_text_shown)
		dialogue_box.all_text_shown.disconnect(_update_advance_timer)
	
	dialogue_box = value
	
	dialogue_box.text_shown.connect(_on_text_shown)
	dialogue_box.all_text_shown.connect(_update_advance_timer)

func get_dialogue_box() -> DQDialogueBox:
	return dialogue_box

func set_choice_menu(value: DQChoiceMenu) -> void:
	choice_menu = value

func get_choice_menu() -> DQChoiceMenu:
	return choice_menu

func accept() -> void:
	if dialogue_box and dialogue_box.visible:
		dialogue_box.accept()

func _prepare_text(text: String) -> PreparedText:
	var result := PreparedText.new()
	var regex := RegEx.create_from_string(r"\[(?<closing>/)?(?<tag>[a-zA-Z_][a-zA-Z_0-9]*)(?:=(?<value>[^\]]*))?\]")
	var last_index := 0
	for found in regex.search_all(text):
		var tag := StringName(found.get_string("tag"))
		if not tag in custom_bbcodes:
			continue
		result.text += text.substr(last_index, found.get_start() - last_index)
		last_index = found.get_end()
		if not found.get_string("closing").is_empty():
			for i in range(result.effects.size() - 1, -1, -1):
				var effect := result.effects[i]
				if effect.tag == tag and effect.end_index == -1:
					effect.end_index = result.text.length()
					break
			continue
		var value := found.get_string("value")
		if not value.is_valid_float() or not is_finite(value.to_float()) or value.to_float() < 0.0 or (tag == &"speed" and value.to_float() == 0.0):
			var s := "DialogueQuest | Player | Invalid value '%s' for text effect '%s'" % [value, tag]
			DialogueQuest.error.emit(s)
			assert(false, s)
			return null
		var effect := TextEffect.new()
		effect.tag = tag
		effect.value = value.to_float()
		effect.start_index = result.text.length()
		result.effects.append(effect)
	result.text += text.substr(last_index)
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	for effect in result.effects:
		if effect.end_index == -1:
			effect.end_index = result.text.length()
		label.text = result.text.substr(0, effect.start_index)
		effect.start_index = label.get_total_character_count()
		label.text = result.text.substr(0, effect.end_index)
		effect.end_index = label.get_total_character_count()
	label.free()
	return result

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
			var choices := section.expressions
			var success := false
			for c in choices:
				if DialogueQuest.Flags.choice_made(c):
					success = true
				DialogueQuest.Flags.confirm_choice(c)
			if success:
				_correct_branch += 1
		DQDqdParser.DqdSection.SectionBranch.Type.FLAG:
			for flag in section.expressions:
				if DialogueQuest.Flags.is_raised(flag):
					_correct_branch += 1
					break
		DQDqdParser.DqdSection.SectionBranch.Type.NO_FLAG:
			var result: bool = true
			for flag in section.expressions:
				if DialogueQuest.Flags.is_raised(flag):
					result = false
					break
			if result:
				_correct_branch += 1
		DQDqdParser.DqdSection.SectionBranch.Type.FLAGS:
			var result: bool = true
			for flag in section.expressions:
				if not DialogueQuest.Flags.is_raised(flag):
					result = false
					break
			if result:
				_correct_branch += 1
		DQDqdParser.DqdSection.SectionBranch.Type.FLAG_GREATER:
			var flag_name := section.expressions[0]
			var value_str = section.expressions[1]
			if not value_str.is_valid_float():
				var s := "DialogueQuest | DialoguePlayer | flag comparison operator provided bad value (non-number) %s" % value_str
				DialogueQuest.error.emit(s)
				assert(false, s)
				stop()
				return
			var value := float(value_str)
			var flag_value = DialogueQuest.Flags.get_flag(flag_name)
			if flag_value == null:
				flag_value = 0
			if flag_value > value:
				_correct_branch += 1
		DQDqdParser.DqdSection.SectionBranch.Type.FLAG_GREATER_EQUAL:
			var flag_name := section.expressions[0]
			var value_str := section.expressions[1]
			if not value_str.is_valid_float():
				var s := "DialogueQuest | DialoguePlayer | flag comparison operator provided bad value (non-number) %s" % value_str
				DialogueQuest.error.emit(s)
				assert(false, s)
				stop()
				return
			var value := float(value_str)
			var flag_value = DialogueQuest.Flags.get_flag(flag_name)
			if flag_value == null:
				flag_value = 0
			if flag_value >= value:
				_correct_branch += 1
		DQDqdParser.DqdSection.SectionBranch.Type.FLAG_LESSER:
			var flag_name := section.expressions[0]
			var value_str := section.expressions[1]
			if not value_str.is_valid_float():
				var s := "DialogueQuest | DialoguePlayer | flag comparison operator provided bad value (non-number) %s" % value_str
				DialogueQuest.error.emit(s)
				assert(false, s)
				stop()
				return
			var value := float(value_str)
			var flag_value = DialogueQuest.Flags.get_flag(flag_name)
			if flag_value == null:
				flag_value = 0
			if flag_value < value:
				_correct_branch += 1
		DQDqdParser.DqdSection.SectionBranch.Type.FLAG_LESSER_EQUAL:
			var flag_name := section.expressions[0]
			var value_str := section.expressions[1]
			if not value_str.is_valid_float():
				var s := "DialogueQuest | DialoguePlayer | flag comparison operator provided bad value (non-number) %s" % value_str
				DialogueQuest.error.emit(s)
				assert(false, s)
				stop()
				return
			var value := float(value_str)
			var flag_value = DialogueQuest.Flags.get_flag(flag_name)
			if flag_value == null:
				flag_value = 0
			if flag_value <= value:
				_correct_branch += 1
		DQDqdParser.DqdSection.SectionBranch.Type.FLAG_EQUAL:
			var flag_name := section.expressions[0]
			var value_str := section.expressions[1]
			
			var value = DQScriptingHelper.expression_to_value(DQScriptingHelper.trim_whitespace(value_str), true)
			if value is DQScriptingHelper.Error:
				var s := "DialogueQuest | DialoguePlayer | flag comparison operator provided bad value (can't convert to an expression) `%s`" % value_str
				DialogueQuest.error.emit(s)
				assert(false, s)
				stop()
				return
			
			var flag_value = DialogueQuest.Flags.get_flag(flag_name)
			if flag_value == null:
				flag_value = 0
			if flag_value == value:
				_correct_branch += 1
		DQDqdParser.DqdSection.SectionBranch.Type.FLAG_NOT_EQUAL:
			var flag_name := section.expressions[0]
			var value_str := section.expressions[1]
			
			var value = DQScriptingHelper.expression_to_value(DQScriptingHelper.trim_whitespace(value_str), true)
			if value is DQScriptingHelper.Error:
				var s := "DialogueQuest | DialoguePlayer | flag comparison operator provided bad value (can't convert to an expression) `%s`" % value_str
				DialogueQuest.error.emit(s)
				assert(false, s)
				stop()
				return
			
			var flag_value = DialogueQuest.Flags.get_flag(flag_name)
			if flag_value == null:
				flag_value = 0
			if flag_value != value:
				_correct_branch += 1
		DQDqdParser.DqdSection.SectionBranch.Type.EVALUATE:
			var res: Variant = DQScriptingHelper.evaluate_expression(section.expression, DialogueQuest)
			if res is DQScriptingHelper.Error and settings.run_expressions_as_script:
				res = DQScriptingHelper.evaluate_gdscript(section.expression)
			if res is DQScriptingHelper.Error:
				var s := "DialogueQuest | Player | Failed to evaluate branch `%s`" % section.expression
				DialogueQuest.error.emit(s)
				assert(false, s)
				stop()
				return
			if res:
				_correct_branch += 1
	
	_current_branch += 1

func _handle_say(section: DQDqdParser.DqdSection.SectionSay) -> void:
	var run_id := _run_id
	_pause_timer.stop()
	dialogue_box.resume()
	_last_pause_index = -1
	_current_effects.clear()
	var chara := section.character
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

	var source_text := ""
	for i in section.texts.size():
		source_text += section.texts[i]
		var prepared := _prepare_text(source_text)
		if not prepared:
			stop()
			return
		_current_effects = prepared.effects
		var previous_count := dialogue_box.get_total_character_count() if i > 0 else 0
		dialogue_box.set_text(prepared.text)
		_pause_timer.stop()
		dialogue_box.resume()
		dialogue_box.start_progressing(previous_count)
		var auto_continue := i == section.texts.size() - 2 and section.texts[-1].strip_edges().is_empty()
		if auto_continue:
			if skipping:
				dialogue_box.finish()
			elif not dialogue_box.is_finished():
				await _wait_for_signal(dialogue_box.all_text_shown)
			return
		await _wait_for_input()
		if run_id != _run_id:
			return

func _handle_signal(section: DQDqdParser.DqdSection.SectionRaiseDQSignal) -> void:
	DialogueQuest.Signals.dialogue_signal.emit(section.params)

func _handle_call(section: DQDqdParser.DqdSection.SectionEvaluateCall) -> void:
	section.expression.execute([], DialogueQuest, false)
	if not section.expression.has_execute_failed():
		return
	if settings.run_expressions_as_script and not section.run_as_script() is DQScriptingHelper.Error:
		return
	var s := "DialogueQuest | Player | Failed to execute call `%s`" % section.expression_string
	DialogueQuest.error.emit(s)
	assert(false, s)
	stop()

func _handle_flag(section: DQDqdParser.DqdSection.SectionFlag) -> void:
	section.raise()

func _handle_choice(section: DQDqdParser.DqdSection.SectionChoice) -> void:
	var run_id := _run_id
	if not settings.skip_after_choices:
		skipping = false
	choice_menu.choices = section.choices
	choice_menu.show()
	var choice_made: Variant = await _wait_for_signal(choice_menu.choice_made)
	if run_id != _run_id:
		return
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
	dialogue_box.letters_per_second = dialogue_box.settings.letters_per_second
	var pause_seconds := 0.0
	for effect in _current_effects:
		if effect.tag == &"speed" and effect.start_index <= characters and characters < effect.end_index:
			dialogue_box.letters_per_second = effect.value
		elif effect.tag == &"pause" and effect.start_index == characters and characters > _last_pause_index:
			pause_seconds += effect.value
	if pause_seconds > 0.0:
		_last_pause_index = characters
		dialogue_box.pause()
		_pause_timer.start(pause_seconds)

func _on_pause_timeout() -> void:
	dialogue_box.resume()

func _on_auto_toggle_requested() -> void:
	autoplaying = !autoplaying

func _on_skip_toggle_requested() -> void:
	skipping = !skipping
