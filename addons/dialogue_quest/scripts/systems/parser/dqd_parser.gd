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
## This class is just a base class, meant to be inherited
class DqdSection:
	## Handler for the ${flag} syntax, should be implemented by the section
	## See 
	func solve_flags() -> void:
		pass
	
	class SectionSay extends DqdSection:
		var character: DQCharacter
		var text: String
		
		func solve_flags() -> void:
			text = DQDqdParser.solve_flags(text)
	
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
			END
		}
		
		var type: Type = Type.END
		var expression: String = ""
		
		func solve_flags() -> void:
			expression = DQDqdParser.solve_flags(expression)

static func parse_from_file(filepath: String) -> Array[DqdSection]:
	if not FileAccess.file_exists(filepath):
		var dq_dir := DQProjectSettings.get_data_dir()
		var all_dqd := DQFilesystemHelper.get_all_files(dq_dir, "dqd")
		for f in all_dqd:
			var req_name := filepath.get_basename().get_file()
			var f_name := f.get_basename().get_file()
			
			if req_name == f_name:
				filepath = f
	
	var f := FileAccess.open(filepath, FileAccess.READ)
	if f == null:
		var err := FileAccess.get_open_error()
		assert(false, "DialogueQuest | Dqd | File at path `%s` was not found or could not be opened | Error code %d" % [filepath, err])

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
		assert(pipeline.size() and "|" in no_whitespace, "DialogQuest | Dqd | Parser | Parse error at line %d | No statements" % line_num)
		
		var parsed = null
		match DQScriptingHelper.remove_whitespace(pipeline[0]):
			"say":
				parsed = _parse_say(pipeline)
			"signal":
				parsed = _parse_signal(pipeline)
			"call":
				parsed = _parse_call(pipeline)
			"flag":
				parsed = _parse_flag(pipeline)
			"choice":
				parsed = _parse_choice(pipeline)
			"branch":
				parsed = _parse_branch(pipeline)
		
		if parsed is DqdError:
			assert(false, parsed.formatted(line_num))
		else:
			ret.append(parsed)
	
	return ret

static func solve_flags(in_string: String) -> String:
	var regex := RegEx.create_from_string(r"\${(.*?)}")
	var found := regex.search_all(in_string)
	if found.size():
		var flag_syntax := found[0].strings[0]
		var flag_name := found[0].strings[1]
		var flag_value := DialogueQuest.Flags.get_flag(flag_name)
		assert(flag_value != null, "DialogQuest | Dqd | Parser | Could not find flag %s" % flag_syntax)
		return in_string.replace(flag_syntax, str(flag_value))
	else:
		return in_string

## The parser for say statements.
## 
## On success, return [Array(DqdSection.SectionSay)].
## On failure will return [DqdError].
static func _parse_say(pipeline: PackedStringArray):
	if pipeline.size() <= 1:
		return DqdError.new("DialogQuest | Dqd | Parser | Parse error at line {line} | Cannot parse say statement | Wrong number of arguments (correct -> 1/2, found 0)")
	elif pipeline.size() >= 4:
		return DqdError.new("DialogQuest | Dqd | Parser | Parse error at line {line} | Cannot parse say statement | Wrong number of arguments (correct -> 1/2, found > 2)")
	
	var say := DqdSection.SectionSay.new()
	say.character = null
	say.text = ""
	
	if pipeline.size() == 2:
		say.text = pipeline[1]
		return say
	
	if pipeline.size() == 3:
		var character_id: String = pipeline[1]
		say.character = DQCharacter.find_by_id(DQScriptingHelper.remove_whitespace(character_id))
		
		if say.character == null:
			return DqdError.new("DialogQuest | Dqd | Parser | Parse error at line {line} | Cannot parse say statement | Character `{character}` not found".format({"character": character_id}))
		
		say.text = pipeline[2].trim_prefix(" ")
		return say
	
	return DqdError.new("DialogQuest | Dqd | Parser | Parse error at line {line} | Cannot parse say statement | Unknown Error")

## The parser for signal statements.
## 
## On success, return [Array(DqdSection.SectionRaiseDQSignal)].
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

## The parser for call statements.
## 
## On success, return [Array(DqdSection.SectionEvaluateCall)].
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

## The parser for call statements.
## 
## On success, return [Array(DqdSection.SectionFlag)].
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

## On success, return [Array(DqdSection.SectionChoice)].
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

## On success, return [Array(DqdSection.SectionBranch)].
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
		"evaluate":
			section.type = DqdSection.SectionBranch.Type.EVALUATE
			section.expression = DQScriptingHelper.trim_whitespace(pipeline[2])
	
	return section
