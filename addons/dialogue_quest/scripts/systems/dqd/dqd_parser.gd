extends Node
## This is a class for parsing .dqd (Dialogue Quest Dialogue) files
class_name DQDqdParser

class DqdError:
	var text: String
	func formatted(line: int) -> String:
		var t := text
		if "line" in text:
			t = text.format({"line": line})
		return t
	
	func _init(from_text: String) -> void:
		text = from_text

## Defines a section of the parsed text
## This class is an abstract class, and is to be inherited
class DqdSection extends Resource:
	## Handler for the ${flag} syntax, should be implemented by the section
	func solve_flags() -> void:
		pass
	
	class SectionSay extends DqdSection:
		var character: DQCharacter
		var texts: PackedStringArray
		
		func solve_flags() -> void:
			for i in texts.size():
				texts[i] = DQDqdParser.solve_flags(texts[i])
	
	class SectionRaiseDQSignal extends DqdSection:
		var params: Array
		
		func solve_flags() -> void:
			var new_params: Array
			for p in params:
				if p is String:
					new_params.append(DQDqdParser.solve_flags(p))
				elif p is StringName:
					new_params.append(StringName(DQDqdParser.solve_flags(p)))
				else:
					new_params.append(p)
			params = new_params
	
	class SectionEvaluateCall extends DqdSection:
		var expression_string: String
		var expression: Expression
		
		func run_as_script() -> Variant:
			return DQScriptingHelper.run_pure_gdscript(expression_string)
		
		func solve_flags() -> void:
			var solved := DQDqdParser.solve_flags(expression_string)
			if solved != expression_string:
				expression_string = solved
				expression.parse(expression_string)
	
	class SectionFlag extends DqdSection:
		enum Type {
			RAISE,
			INCREMENT,
			DECREMENT,
			SET,
			DELETE
		}
		
		var type: Type
		var flag: String
		var value: Variant = null
		
		func raise() -> void:
			match type:
				Type.RAISE:
					DialogueQuest.Flags.raise_flag(flag)
				Type.INCREMENT:
					if value:
						DialogueQuest.Flags.increment_flag(flag, value)
					else:
						DialogueQuest.Flags.increment_flag(flag)
				Type.DECREMENT:
					if value:
						DialogueQuest.Flags.decrement_flag(flag, value)
					else:
						DialogueQuest.Flags.decrement_flag(flag)
				Type.SET:
					DialogueQuest.Flags.set_flag(flag, value)
				Type.DELETE:
					DialogueQuest.Flags.delete_flag(flag)
	
	class SectionChoice extends DqdSection:
		var choices: PackedStringArray
		
		func solve_flags() -> void:
			var new_choices: Array
			for c in choices:
				new_choices.append(DQDqdParser.solve_flags(c))
			choices = new_choices
	
	class SectionBranch extends DqdSection:
		enum Type {
			CHOICE,
			EVALUATE,
			FLAG,
			NO_FLAG,
			END
		}
		
		var type: Type = Type.END
		var expression: String = ""
		
		func solve_flags() -> void:
			expression = DQDqdParser.solve_flags(expression)

## Defines a keyword that can be parsed in a dqd.
class Statement:
	var section_type: StringName :
		set(value):
			assert(ClassDB.is_parent_class(value, "DqdSection"), "Statemnt section_type must be a subclass of DqdSection.")
			section_type = value
	var keyword: StringName
	var parse_function: Callable
	func _init(keyword_: String, _parse_function: Callable, _section_type: StringName):
		keyword = keyword_
		parse_function = _parse_function

static var statements: Array[Statement] = [
	Statement.new("say", DQDqdParser._parse_say, "DqdParser.DqdSection.SectionSay"),
	Statement.new("signal", DQDqdParser._parse_signal, "DqdParser.DqdSection.SectionRaiseDQSignal"),
	Statement.new("call", DQDqdParser._parse_call, "DqdParser.DqdSection.SectionEvaluateCall"),
	Statement.new("flag", DQDqdParser._parse_flag, "DqdParser.DqdSection.SectionFlag"),
	Statement.new("choice", DQDqdParser._parse_choice, "DqdParser.DqdSection.SectionChoice"),
	Statement.new("branch", DQDqdParser._parse_branch, "DqdParser.DqdSection.SectionBranch")
]

static func parse_from_file(filepath: String) -> Array[DqdSection]:
	if not FileAccess.file_exists(filepath):
		var dq_dir := DialogueQuest.Settings.data_directory
		var all_dqd := DQFilesystemHelper.get_all_files(dq_dir, "dqd")
		for f in all_dqd:
			var req_name := filepath.get_basename().get_file()
			var f_name := f.get_basename().get_file()
			
			if req_name == f_name:
				filepath = f
	
	var f := FileAccess.open(filepath, FileAccess.READ)
	if f == null:
		var err := FileAccess.get_open_error()
		var s := "DialogueQuest | Dqd | File at path `%s` was not found or could not be opened | Error code %d" % [filepath, err]
		DialogueQuest.error.emit(s)
		assert(false, s)

	return parse_from_text(f.get_as_text(true))

static func parse_from_text(text: String) -> Array[DqdSection]:
	var ret: Array[DqdSection]
	
	var line_num: int = 0
	for line in text.split("\n"):
		line_num += 1
		var no_whitespace := DQScriptingHelper.remove_whitespace(line)
		if no_whitespace.is_empty() or no_whitespace.begins_with("//"):
			continue
		var pipeline: PackedStringArray = line.split("|")
		
		var has_statements := pipeline.size() and "|" in no_whitespace
		if not has_statements:
			var s := "DialogQuest | Dqd | Parser | Parse error at line %d | No statements" % line_num
			DialogueQuest.error.emit(s)
			assert(false, s)
		
		var parsed = null

		for statement in statements:
			if statement.keyword == DQScriptingHelper.remove_whitespace(pipeline[0]):
				parsed = statement.parse_function.call(pipeline)
					
		if parsed is DqdError:
			var s: String = parsed.formatted(line_num)
			DialogueQuest.error.emit(s)
			assert(false, s)
		elif parsed != null:
			ret.append(parsed)
	
	return ret

static func solve_flags(in_string: String) -> String:
	var regex := RegEx.create_from_string(r"\${(.*?)}")
	var found := regex.search_all(in_string)
	if found.size():
		var flag_syntax := found[0].strings[0]
		var flag_name := found[0].strings[1]
		var flag_value := DialogueQuest.Flags.get_flag(flag_name)
		if flag_value == null:
			flag_value = "null"
		return in_string.replace(flag_syntax, str(flag_value))
	else:
		return in_string

## On success will return [DqdSection.SectionSay].
## kOn failure will return [DqdError].
static func _parse_say(pipeline: PackedStringArray):
	if pipeline.size() <= 1:
		return DqdError.new("DialogQuest | Dqd | Parser | Parse error at line {line} | Cannot parse say statement | Wrong number of arguments (correct -> 1/2, found 0)")
	# elif pipeline.size() >= 4:
	# 	return DqdError.new("DialogQuest | Dqd | Parser | Parse error at line {line} | Cannot parse say statement | Wrong number of arguments (correct -> 1/2, found > 2)")
	
	var say := DqdSection.SectionSay.new()
	say.character = null
	say.texts = []
	
	if pipeline.size() == 2:
		say.texts.append(DQScriptingHelper.trim_whitespace_prefix(pipeline[1]))
		return say
	
	var character_id: String = pipeline[1]
	if not DQScriptingHelper.remove_whitespace(character_id).is_empty():
		say.character = DQCharacter.find_by_id(DQScriptingHelper.remove_whitespace(character_id))
		if say.character == null:
			return DqdError.new("DialogQuest | Dqd | Parser | Parse error at line {line} | Cannot parse say statement | Character `{character}` not found".format({"character": character_id}))
	
	for p in pipeline.slice(2):
		say.texts.append(DQScriptingHelper.trim_whitespace_prefix(p))

	return say
	
	return DqdError.new("DialogQuest | Dqd | Parser | Parse error at line {line} | Cannot parse say statement | Unknown Error")

## On success will return [DqdSection.SectionRaiseDQSignal].
## On failure will return [DqdError].
static func _parse_signal(pipeline: PackedStringArray):
	if pipeline.size() <= 1:
		return DqdError.new("DialogQuest | Dqd | Parser | Parse error at line {line} | Cannot parse signal statement | Wrong number of arguments (correct -> 1+, found 0)")
	
	var args: Array = []
	for p in pipeline.slice(1):
		var as_var := str_to_var(DQScriptingHelper.remove_whitespace(p))
		if as_var == null:
			return DqdError.new("DialogQuest | Dqd | Parser | Parse error at line {line} | Cannot parse signal statement | String `%s` could not be parsed into a GDScript variable." % p)
		args.append(as_var)
	
	var sec := DqdSection.SectionRaiseDQSignal.new()
	sec.params = args
	return sec

## On success will return [DqdSection.SectionEvaluateCall].
## On failure will return [DqdError].
static func _parse_call(pipeline: PackedStringArray):
	if pipeline.size() <= 1:
		return DqdError.new("DialogQuest | Dqd | Parser | Parse error at line {line} | Cannot parse call statement | Wrong number of arguments (correct -> 1, found 0)")
	elif pipeline.size() >= 3:
		return DqdError.new("DialogQuest | Dqd | Parser | Parse error at line {line} | Cannot parse call statement | Wrong number of arguments (correct -> 1, found > 1)")
	
	var expression_str := pipeline[1]
	var expression := Expression.new()
	var exp_err := expression.parse(expression_str)
	if exp_err != OK:
		return DqdError.new("DialogQuest | Dqd | Parser | Parse error at line {line} | Cannot parse call statement | Call expression `%s` failed to parse" % expression_str)
	
	var ret := DqdSection.SectionEvaluateCall.new()
	ret.expression_string = expression_str
	ret.expression = expression
	return ret

## On success will return [DqdSection.SectionFlag].
## On failure will return [DqdError].
static func _parse_flag(pipeline: PackedStringArray):
	if pipeline.size() <= 2:
		return DqdError.new("DialogQuest | Dqd | Parser | Parse error at line {line} | Cannot parse flag statement | Wrong number of arguments (correct -> 2+, found 0)")
	
	var section := DqdSection.SectionFlag.new()
	match DQScriptingHelper.remove_whitespace(pipeline[1]):
		"raise":
			section.type = DqdSection.SectionFlag.Type.RAISE
			section.flag = DQScriptingHelper.remove_whitespace(pipeline[2])
			section.value = true
		"inc":
			if pipeline.size() <= 3:
				section.value = null
				section.flag = DQScriptingHelper.remove_whitespace(pipeline[2])
			else:
				var num_str := DQScriptingHelper.remove_whitespace(pipeline[2])
				if not num_str.is_valid_int():
					return DqdError.new("DialogQuest | Dqd | Parser | Parse error at line {line} | Cannot parse flag inc statement | Argument `%s` is not a valid integer numer" % num_str)
				section.value = int(num_str)
				section.flag = DQScriptingHelper.remove_whitespace(pipeline[3])
			section.type = DqdSection.SectionFlag.Type.INCREMENT
		"dec":
			if pipeline.size() <= 3:
				section.value = null
				section.flag = DQScriptingHelper.remove_whitespace(pipeline[2])
			else:
				var num_str := DQScriptingHelper.remove_whitespace(pipeline[2])
				if not num_str.is_valid_int():
					return DqdError.new("DialogQuest | Dqd | Parser | Parse error at line {line} | Cannot parse flag dec statement | Argument `%s` is not a valid integer numer" % num_str)
				section.value = int(num_str)
				section.flag = DQScriptingHelper.remove_whitespace(pipeline[3])
			section.type = DqdSection.SectionFlag.Type.DECREMENT
		"set":
			if pipeline.size() <= 3:
				return DqdError.new("DialogQuest | Dqd | Parser | Parse error at line {line} | Cannot parse flag set statement | Wrong number of arguments (correct -> 3, found %d)" % (pipeline.size() - 1))
			section.type = DqdSection.SectionFlag.Type.SET
			var var_str := DQScriptingHelper.remove_whitespace(pipeline[2])
			section.value = str_to_var(var_str)
			if section.value == null:
				return DqdError.new("DialogQuest | Dqd | Parser | Parse error at line {line} | Cannot parse flag set statement | Argument `%s` is not a valid GDScript value" % var_str) 
			section.flag = DQScriptingHelper.remove_whitespace(pipeline[3])
		"delete":
			section.type = DqdSection.SectionFlag.Type.DELETE
			section.flag = DQScriptingHelper.remove_whitespace(pipeline[2])
	
	return section

## On success will return [DqdSection.SectionChoice].
## On failure will return [DqdError].
static func _parse_choice(pipeline: PackedStringArray):
	if pipeline.size() <= 2:
		return DqdError.new("DialogQuest | Dqd | Parser | Parse error at line {line} | Cannot parse choice statement | Wrong number of arguments (correct -> 2+, found 0)")
	
	var section := DqdSection.SectionChoice.new()
	var choices: PackedStringArray = []
	for c in pipeline.slice(1):
		choices.append(DQScriptingHelper.trim_whitespace(c))
	section.choices = choices
	return section

## On success will return [DqdSection.SectionBranch].
## On failure will return [DqdError].
static func _parse_branch(pipeline: PackedStringArray):
	var section := DqdSection.SectionBranch.new()
	if pipeline.size() <= 1:
		return DqdError.new("DialogQuest | Dqd | Parser | Parse error at line {line} | Cannot parse branch statement | Wrong number of arguments (correct -> 1/2, found 0)")
	
	if pipeline.size() >= 4:
		return DqdError.new("DialogQuest | Dqd | Parser | Parse error at line {line} | Cannot parse branch statement | Wrong number of arguments (correct -> 2, found 3+)")
	
	match DQScriptingHelper.remove_whitespace(pipeline[1]):
		"end":
			section.type = DqdSection.SectionBranch.Type.END
		"choice":
			section.type = DqdSection.SectionBranch.Type.CHOICE
			section.expression = DQScriptingHelper.trim_whitespace(pipeline[2])
		"flag":
			section.type = DqdSection.SectionBranch.Type.FLAG
			section.expression = DQScriptingHelper.remove_whitespace(pipeline[2])
		"no_flag":
			section.type = DqdSection.SectionBranch.Type.NO_FLAG
			section.expression = DQScriptingHelper.remove_whitespace(pipeline[2])
		"evaluate":
			section.type = DqdSection.SectionBranch.Type.EVALUATE
			section.expression = DQScriptingHelper.trim_whitespace(pipeline[2])
	
	return section
