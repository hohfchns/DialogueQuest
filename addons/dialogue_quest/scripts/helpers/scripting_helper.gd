extends Node
class_name DQScriptingHelper

## Class for non-ambigous error checking (checking failure by `result is [DQScriptingHelper.Error]`)
class Error:
	pass

static func remove_whitespace(from: String) -> String:
	return from.replace(" ", "").replace("\n", "").replace("\r", "").replace("	", "")

static func trim_whitespace(from: String) -> String:
	return \
	from.trim_prefix(" ").trim_prefix("\n").trim_prefix("\r").trim_prefix("	")\
	.trim_suffix(" ").trim_suffix("\n").trim_suffix("\r").trim_suffix("	")

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

