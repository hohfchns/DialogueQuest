extends Node
class_name DQFlags

## [Dictionary] of the format: flag([String]) : value([Variant]) }
var flag_registry: Dictionary = {}

func get_flag(flag: String) -> Variant:
	if flag in flag_registry:
		return flag
	
	return null

func set_flag(flag: String, value: Variant) -> void:
	flag_registry[flag] = value
	pass

func get_bool(flag: String) -> bool:
	var f := get_flag(flag) as bool
	if f == null:
		return false
	return f

func is_raised(flag: String) -> bool:
	var f := get_flag(flag)
	if f == null:
		return false
	
	# Use native compare operator
	return true if f else false

func raise_flag(flag: String) -> void:
	flag_registry[flag] = true
	pass

func increment_flag(flag: String, by := 1) -> void:
	if not flag in flag_registry:
		flag_registry[flag] = 0
	flag_registry[flag] += by
	pass

func decrement_flag(flag: String, by := 1) -> void:
	if not flag in flag_registry:
		flag_registry[flag] = 0
	flag_registry[flag] -= by
	pass

func delete_flag(flag: String) -> void:
	flag_registry.erase(flag)
	pass


func _input(event: InputEvent) -> void:
	pass
