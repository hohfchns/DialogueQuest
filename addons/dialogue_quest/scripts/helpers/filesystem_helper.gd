extends Node
class_name DQFilesystemHelper

const SOUND_FILE_FORMATS: PackedStringArray = [ "wav", "ogg", "mp3" ]

static func get_all_files(path: String, full_paths := true, file_exts: PackedStringArray = [], trim_suffixes: PackedStringArray = []) -> PackedStringArray:
	return _get_all_files(path, full_paths, file_exts, trim_suffixes)

static func _get_all_files(path: String, full_paths: bool, file_exts: PackedStringArray, trim_suffixes: PackedStringArray, files: PackedStringArray = []) -> PackedStringArray:
	var dir = DirAccess.open(path)
	if not dir:
		printerr(DirAccess.get_open_error())
		return []
	
	dir.list_dir_begin()
	
	var file_name = dir.get_next()
	
	while file_name != "":
		if dir.current_is_dir():
			files = _get_all_files(dir.get_current_dir().path_join(file_name), full_paths, file_exts, trim_suffixes, files)
		else:
			for suffix in trim_suffixes:
				if file_name.ends_with(suffix):
					file_name = file_name.trim_suffix(suffix)
					break
			
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

static func find_sound_file(file: String, in_dir: String="") -> String:
	if FileAccess.file_exists(file):
		return file
	elif FileAccess.file_exists(in_dir.path_join(file)):
		return in_dir.path_join(file)
	elif in_dir.is_empty():
		return ""
	
	var suffixes: PackedStringArray = [".remap"]
	if DQGodotHelper.is_final_build():
		suffixes.append(".import")
	var all_files := get_all_files(in_dir, true, SOUND_FILE_FORMATS, suffixes)
	
	for f in all_files:
		var full_filename := f.get_file()
		var base_filename := DQScriptingHelper.get_base_filename(f)
		
		if full_filename == file or base_filename == file:
			return f

	return ""


