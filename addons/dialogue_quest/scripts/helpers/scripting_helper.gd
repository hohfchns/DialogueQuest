extends Node
class_name DQScriptingHelper

## Class for non-ambigous error checking (checking failure by `result is [DQScriptingHelper.Error]`)
class Error:
	pass

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
	"do", "class_name", "extends", "is", "as", "true", "false", "or", "and"
]

static func remove_whitespace(from: String) -> String:
	var s := from
	for c in WHITESPACE_CHARACTERS:
		s = s.replace(c, "")
	return s

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
static func stringify_expression(expression: String) -> String:
	var new_str: String = ""
	var words: PackedStringArray = [expression]
	if " " in expression:
		words = expression.split(" ")

	for word in words:
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

		new_str += "\"%s\"" % word + " "

	return trim_whitespace(new_str)
