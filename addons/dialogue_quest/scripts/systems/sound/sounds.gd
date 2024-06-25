extends Node
class_name DQSounds

func play_sound(sound_name: String, bus: StringName = &"Master", volume: float = 0.0) -> void:
	var sound_file: String = DQFilesystemHelper.find_sound_file(sound_name, DQProjectSettings.get_data_dir())
	
	if AudioServer.get_bus_index(bus) == -1:
		var s := "DialogueQuest | Sounds | Audio channel `%s` does not exist." % bus
		DialogueQuest.error.emit(s)
		assert(false, s)
	
	if sound_file.is_empty():
		var s := "DialogueQuest | Sounds | Sound `%s` was not found." % sound_name
		DialogueQuest.error.emit(s)
		assert(false, s)
	
	var sfx := load(sound_file) as AudioStream
	if sfx == null:
		var s := "DialogueQuest | Sounds | Sound `%s` at path `%s` is not a valid sound file." % [sound_name, sound_file]
		DialogueQuest.error.emit(s)
		assert(false, s)
	
	var player := AudioStreamPlayer.new()
	add_child(player)
	player.stream = sfx
	player.volume_db = volume
	player.bus = bus
	player.finished.connect(_sound_ended.bind(player), CONNECT_ONE_SHOT)
	player.play()

func _sound_ended(player: AudioStreamPlayer) -> void:
	remove_child(player)
	player.queue_free()

