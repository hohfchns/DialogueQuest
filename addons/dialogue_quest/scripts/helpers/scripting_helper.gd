extends Node
class_name DQScriptingHelper

## Class for non-ambigous error checking (checking failure by `result is [DQScriptingHelper.Error]`)
class Error:
	pass

const SYMBOL_MAP: Dictionary = {
	"\\n": "\n",
	"	": "    ",
	"\\r": "\r"
}

const WHITESPACE_CHARACTERS: PackedStringArray = [" ", "\n", "\r", "	"]

const RESERVED_CHARACTERS: PackedStringArray = [
	"!", "@", "#", "$", "%", "^", "&", "*", "-",
	"+", "=", "{", "}", "[", "]", "|", "\\", ":",
	";", "'", "\"", "<", ">", ", ", ".", "/", "?",
	"~", "(", ")", "`"
]

const RESERVED_WORDS: PackedStringArray = [
	"func", "class", "extends", "self", "if", "elif", "else", "while", "for",
	"in", "break", "continue", "return", "match", "switch", "case", "const",
	"var", "onready", "tool", "export", "signal", "preload", "assert", "yield",
	"do", "class_name", "extends", "is", "as", "true", "false", "or", "and", "not",
	"null"
]

static func replace_with_escape(from: String, what: String, with: String, escape: String) -> String:
	var found_idx := from.find(what)
	
	var new_str := ""
	var last_idx := 0
	while true:
		found_idx = from.find(what, last_idx)
		if found_idx == -1:
			break
		
		if found_idx == 0:
			new_str = with + from.substr(what.length())
			last_idx = found_idx + what.length()
			continue

		if from[found_idx - 1] == escape:
			new_str += from.substr(last_idx, found_idx - last_idx - 1)
			new_str += what
			last_idx = found_idx + what.length()
			continue
		
		new_str += from.substr(last_idx, found_idx - last_idx)
		new_str += with
		last_idx = found_idx + what.length()
	
	new_str += from.substr(last_idx)

	return new_str

static func solve_symbols(from: String, allow_escape: bool = true) -> String:
	var s := from
	for symbol in SYMBOL_MAP.keys():
		if allow_escape:
			s = replace_with_escape(s, symbol, SYMBOL_MAP[symbol], "\\")
		else:
			s = s.replace(symbol, SYMBOL_MAP[symbol])
	return s

static func remove_whitespace(from: String) -> String:
	var s := from
	for c in WHITESPACE_CHARACTERS:
		s = s.replace(c, "")
	return s

static func remove_whitespace_array(from: PackedStringArray) -> PackedStringArray:
	for i in range(from.size()):
		from[i] = remove_whitespace(from[i])
	return from

static func trim_whitespace(from: String) -> String:
	return trim_whitespace_suffix(trim_whitespace_prefix(from))

static func trim_whitespace_prefix(from: String) -> String:
	var s := from
	for c in WHITESPACE_CHARACTERS:
		s = s.trim_prefix(c)
	return s

static func trim_whitespace_suffix(from: String) -> String:
	var s := from
	for c in WHITESPACE_CHARACTERS:
		s = s.trim_suffix(c)
	return s

static func trim_extension(from: String) -> String:
	return from.replace("." + from.get_extension(), "")

static func get_base_filename(of: String) -> String:
	return trim_extension(of.get_file())

static func evaluate_gdscript(code: String) -> Variant:
	return run_pure_gdscript(code, true)

static func run_pure_gdscript(code: String, evaluate: bool = false) -> Variant:
	var script = GDScript.new()
	if evaluate:
		script.set_source_code("func eval():\n    return " + code)
	else:
		script.set_source_code("func eval():\n    " + code)
	script.reload()
	var ref = RefCounted.new()
	ref.set_script(script)
	return ref.eval()

static func evaluate_expression(expression: String, base_instance: Object = null) -> Variant:
	var exp := Expression.new()
	exp.parse(expression)
	var res: Variant = exp.execute([], base_instance)
	if exp.has_execute_failed():
		return Error.new()
	return res

## Takes `expression` and converts non-reserved and non-numeric words into quoted strings for evaluation.
## If `whole` is set to `false` (default), the returned string will contain parantheses around each words, otherwise it will be per the whole expression.
static func stringify_expression(expression: String, whole: bool = false) -> String:
	var new_str: String = ""
	var words: PackedStringArray = [expression]
	if " " in expression:
		words = expression.split(" ")

	var is_whole_string: bool = false
	var string_state: bool = false

	for word in words:
		var added_characters := 0
		for c in word:
			if c == '"':
				string_state = !string_state
				new_str += '"'
				added_characters += 1
			else:
				if string_state:
					new_str += c
					added_characters += 1
		
		if added_characters == word.length():
			new_str += " "
			continue
		
		if string_state:
			continue
		
		if word.is_valid_float():
			new_str += word + " "
			continue
		if word in RESERVED_WORDS:
			new_str += word + " "
			continue

		var has_reserved_character := false
		for c in word.split():
			if c in RESERVED_CHARACTERS:
				has_reserved_character = true
				break
		if has_reserved_character:
			new_str += word + " "
			continue

		if whole:
			new_str += '%s ' % word
		else:
			new_str += '"%s" ' % word
		
		is_whole_string = true
	
	if whole and is_whole_string:
		return '"%s"' % trim_whitespace(new_str)
	
	return trim_whitespace(new_str)

## Applies `stringify_expression` and converts it to a Variant
## To check the error, use `result is DQScriptingHelper.Error`, as `null` is a vaslid return value
static func expression_to_value(expression: String, whole: bool = false) -> Variant:
	var stringified = DQScriptingHelper.stringify_expression(expression, whole)
	if stringified == "null":
		return null
	
	var as_var := str_to_var(stringified)
	if as_var == null:
		return Error.new()
	
	return as_var

## Takes `expressions` and returns string connected by a conditional `operator` of all of them
## If `stringify` is true, will apply the `stringify_expression` method to each
## expression in `expressions`
static func connect_expressions(expressions: PackedStringArray, operator: String = "and", stringify: bool = false) -> String:
	assert(expressions.size())
	if expressions.size() == 1:
		return expressions[0]

	var str := ""
	var i := 0
	for e in expressions.slice(0, -1):
		if stringify:
			e = stringify_expression(e)
		str += "(%s) %s " % [e, operator]
	str += "(%s)" % expressions[-1]

	print(str)
	return str
