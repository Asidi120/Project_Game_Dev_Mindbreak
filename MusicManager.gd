extends Node

var music_enabled: bool = true
var music_volume: float = 0.5
var player: AudioStreamPlayer = null


func _ready() -> void:
	player = AudioStreamPlayer.new()
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(player)
	_load_settings()
	player.stream = load("res://Music/music.mp3")
	player.volume_db = linear_to_db(music_volume)
	if music_enabled:
		player.play()


func set_music_enabled(enabled: bool) -> void:
	music_enabled = enabled
	if enabled:
		if not player.playing:
			player.play()
	else:
		player.stop()
	_save_settings()


func set_volume(value: float) -> void:
	music_volume = clamp(value, 0.0, 1.0)
	player.volume_db = linear_to_db(music_volume)
	_save_settings()


func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "music_enabled", music_enabled)
	config.set_value("audio", "music_volume", music_volume)
	config.save("user://settings.cfg")


func _load_settings() -> void:
	var config := ConfigFile.new()
	var err = config.load("user://settings.cfg")
	print("Load settings error: ", err)
	if err == OK:
		music_enabled = config.get_value("audio", "music_enabled", true)
		music_volume  = config.get_value("audio", "music_volume", 0.5)
		print("Wczytano: enabled=", music_enabled, " volume=", music_volume)
