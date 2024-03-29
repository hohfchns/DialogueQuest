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

## Defines a section of the parsed text
## This class is just a base class, meant to be inherited
class DqdSection:
	class SectionSay extends DqdSection:
		var character: DQCharacter
		var text: String
	
	class SectionRaiseDQSignal extends DqdSection:
		var params: Array
	
	class SectionEvaluateCall extends DqdSection:
		var expression_string: String
		var expression: Expression
		
		func run_as_script():
			var script = GDScript.new()
			script.set_source_code("func eval():" + expression_string)
			script.reload()
			var ref = RefCounted.new()
			ref.set_script(script)
			return ref.eval()

static func _remove_whitespace(from: String) -> String:
	return from.replace(" ", "").replace("\n", "").replace("\r", "").replace("	", "")

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
		var no_whitespace := _remove_whitespace(line)
		if no_whitespace.is_empty() or no_whitespace.begins_with("// "):
			continue
		var pipeline: PackedStringArray = line.split("|")
		assert(pipeline.size() and "|" in no_whitespace, "DialogQuest | Dqd | Parser | Parse error at line %d | No statements" % line_num)
		for pipe in pipeline:
			match _remove_whitespace(pipe):
				"say":
					var parsed = _parse_say(pipeline)
					if not parsed is DqdSection.SectionSay:
						assert(false, parsed.formatted(line_num))
					
					ret.append(parsed)
				"signal":
					var parsed = _parse_signal(pipeline)
					if not parsed is DqdSection.SectionRaiseDQSignal:
						assert(false, parsed.formatted(line_num))
					
					ret.append(parsed)
				"call":
					var parsed = _parse_call(pipeline)
					if not parsed is DqdSection.SectionEvaluateCall:
						assert(false, parsed.formatted(line_num))
					
					ret.append(parsed)
	
	return ret

## The parser for say statements.
## 
## On success, return [Array(DqdSection.SectionSay)].
## On failure will return [DqdError].
static func _parse_say(pipeline: PackedStringArray):
	
	if pipeline.size() <= 1:
		var err := DqdError.new()
		err.text = "DialogQuest | Dqd | Parser | Parse error at line {line} | Cannot parse say statement | Wrong number of arguments (correct -> 1/2, found 0)"
		return err
	elif pipeline.size() >= 4:
		var err := DqdError.new()
		err.text = "DialogQuest | Dqd | Parser | Parse error at line {line} | Cannot parse say statement | Wrong number of arguments (correct -> 1/2, found > 2)"
		return err
	
	var say := DqdSection.SectionSay.new()
	say.character = null
	say.text = ""
	
	if pipeline.size() == 2:
		say.text = pipeline[1]
		return say
	
	if pipeline.size() == 3:
		var character_id: String = pipeline[1]
		say.character = DQCharacter.find_by_id(_remove_whitespace(character_id))
		
		if say.character == null:
			var err := DqdError.new()
			err.text = "DialogQuest | Dqd | Parser | Parse error at line {line} | Cannot parse say statement | Character `{character}` not found".format({"character": character_id})
			return err
		
		say.text = pipeline[2].trim_prefix(" ")
		return say
	
	var err := DqdError.new()
	err.text = "DialogQuest | Dqd | Parser | Parse error at line {line} | Cannot parse say statement | Unknown Error"
	return err

## The parser for signal statements.
## 
## On success, return [Array(DqdSection.SectionRaiseDQSignal)].
## On failure will return [DqdError].
static func _parse_signal(pipeline: PackedStringArray):
	if pipeline.size() <= 1:
		var err := DqdError.new()
		err.text = "DialogQuest | Dqd | Parser | Parse error at line {line} | Cannot parse signal statement | Wrong number of arguments (correct -> 1+, found 0)"
		return err
	
	var args: Array = []
	for p in pipeline.slice(1):
		var as_var := str_to_var(_remove_whitespace(p))
		if as_var == null:
			var err := DqdError.new()
			err.text = "DialogQuest | Dqd | Parser | Parse error at line {line} | Cannot parse signal statement | String `%s` could not be parsed into a GDScript variable." % p
			return err
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
		var err := DqdError.new()
		err.text = "DialogQuest | Dqd | Parser | Parse error at line {line} | Cannot parse call statement | Wrong number of arguments (correct -> 1, found 0)"
		return err
	elif pipeline.size() >= 3:
		var err := DqdError.new()
		err.text = "DialogQuest | Dqd | Parser | Parse error at line {line} | Cannot parse call statement | Wrong number of arguments (correct -> 1, found > 1)"
		return err
	
	var expression_str := pipeline[1]
	var expression := Expression.new()
	var exp_err := expression.parse(expression_str)
	if exp_err != OK:
		var err := DqdError.new()
		err.text = "DialogQuest | Dqd | Parser | Parse error at line {line} | Cannot parse call statement | Call expression `%s` failed to parse" % expression_str
		return err
	
	var ret := DqdSection.SectionEvaluateCall.new()
	ret.expression_string = expression_str
	ret.expression = expression
	return ret
