extends Node
class_name DQFilesystemHelper

static func get_all_files(path: String, file_ext := "", full_paths := true) -> PackedStringArray:
	return _get_all_files(path, file_ext, full_paths)

static func get_all_files(path: String, full_paths := true, file_exts: PackedStringArray = []) -> PackedStringArray:
	return _get_all_files(path, full_paths, file_exts)

static func _get_all_files(path: String, full_paths: bool, file_exts: PackedStringArray, files: PackedStringArray = []) -> PackedStringArray:
	var dir = DirAccess.open(path)
	if not dir:
		printerr(DirAccess.get_open_error())
		return []
	
	dir.list_dir_begin()
	
	var file_name = dir.get_next()
	
	while file_name != "":
		if dir.current_is_dir():
			files = _get_all_files(dir.get_current_dir().path_join(file_name), full_paths, file_exts, files)
		else:
			if file_exts.size():
				var found := false
				for ext in file_exts:
					if file_name.get_extension() == ext:
						found = true
						break

				if not found:
					file_name = dir.get_next()
					continue

			if full_paths:
				files.append(dir.get_current_dir().path_join(file_name))
			else:
				files.append(file_name)
		
		file_name = dir.get_next()
	
	return files
