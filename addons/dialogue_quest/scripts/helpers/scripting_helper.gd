extends Node
class_name DQScriptingHelper

## Class for non-ambigous error checking (checking failure by `result is [DQScriptingHelper.Error]`)
class Error:
	pass

const WHITESPACE_CHARACTERS: PackedStringArray = [" ", "\n", "\r", "	"]

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

static func run_pure_gdscript(code: String) -> Variant:
	var script = GDScript.new()
	script.set_source_code("func eval():" + code)
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

