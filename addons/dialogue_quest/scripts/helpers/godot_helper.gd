extends Node
class_name DQGodotHelper

static func is_final_build() -> bool:
	return OS.has_feature("template") or OS.has_feature("release")
