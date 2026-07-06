extends Node

var music_enabled: bool = true
var music_volume: float = 0.5

var sounds_enabled: bool = true
var sounds_volume: float = 0.5

var player: AudioStreamPlayer = null

func _ready() -> void:
	player = AudioStreamPlayer.new()
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(player)

	get_tree().node_added.connect(_on_node_added)

	_load_settings()

	player.stream = load("res://Music/music2.mp3")
	player.volume_db = linear_to_db(music_volume)

	if music_enabled:
		player.play()

	_apply_sound_settings()


func _on_node_added(node: Node) -> void:
	if node.is_in_group("Sounds"):
		if node is AudioStreamPlayer or node is AudioStreamPlayer2D:
			if !sounds_enabled:
				node.volume_db = linear_to_db(0.0)
			else:
				node.volume_db = linear_to_db(sounds_volume)


func set_music_enabled(enabled: bool) -> void:
	music_enabled = enabled

	if enabled:
		if !player.playing:
			player.play()
	else:
		player.stop()

	_save_settings()


func set_volume(value: float) -> void:
	music_volume = clamp(value, 0.0, 1.0)
	player.volume_db = linear_to_db(music_volume)
	_save_settings()


func set_sounds_enabled(enabled: bool) -> void:
	sounds_enabled = enabled

	for sound in get_tree().get_nodes_in_group("Sounds"):
		if sound is AudioStreamPlayer or sound is AudioStreamPlayer2D:
			if !sounds_enabled:
				sound.volume_db = linear_to_db(0.0)
			else:
				sound.volume_db = linear_to_db(sounds_volume)

	_save_settings()


func set_sounds_volume(value: float) -> void:
	sounds_volume = clamp(value, 0.0, 1.0)

	for sound in get_tree().get_nodes_in_group("Sounds"):
		if sound is AudioStreamPlayer or sound is AudioStreamPlayer2D:
			if !sounds_enabled:
				sound.volume_db = linear_to_db(0.0)
			else:
				sound.volume_db = linear_to_db(sounds_volume)

	_save_settings()


func _apply_sound_settings() -> void:
	for sound in get_tree().get_nodes_in_group("Sounds"):
		if sound is AudioStreamPlayer or sound is AudioStreamPlayer2D:
			if !sounds_enabled:
				sound.volume_db = linear_to_db(0.0)
			else:
				sound.volume_db = linear_to_db(sounds_volume)


func _save_settings() -> void:
	var config := ConfigFile.new()

	config.set_value("audio", "music_enabled", music_enabled)
	config.set_value("audio", "music_volume", music_volume)

	config.set_value("sounds", "sounds_enabled", sounds_enabled)
	config.set_value("sounds", "sounds_volume", sounds_volume)

	config.save("user://settings.cfg")


func _load_settings() -> void:
	var config := ConfigFile.new()

	if config.load("user://settings.cfg") == OK:
		music_enabled = config.get_value("audio", "music_enabled", true)
		music_volume = config.get_value("audio", "music_volume", 0.5)

		sounds_enabled = config.get_value("sounds", "sounds_enabled", true)
		sounds_volume = config.get_value("sounds", "sounds_volume", 0.5)
