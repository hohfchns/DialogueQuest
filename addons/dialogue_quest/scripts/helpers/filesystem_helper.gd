extends Node
class_name DQFilesystemHelper

static func get_all_files(path: String, file_ext := "", full_paths := true, files: PackedStringArray = []) -> PackedStringArray:
	var dir = DirAccess.open(path)
	if not dir:
		printerr(DirAccess.get_open_error())
		return []
	
	dir.list_dir_begin()
	
	var file_name = dir.get_next()
	
	while file_name != "":
		if dir.current_is_dir():
			files = get_all_files(dir.get_current_dir().path_join(file_name), file_ext, full_paths, files)
		else:
			if file_ext and file_name.get_extension() != file_ext:
				file_name = dir.get_next()
				continue
 			
			if full_paths:
				files.append(dir.get_current_dir().path_join(file_name))
			else:
				files.append(file_name)
		
		file_name = dir.get_next()
	
	return files
