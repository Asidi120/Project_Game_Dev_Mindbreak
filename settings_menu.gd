extends Control


var in_game: bool = false

@onready var music_toggle:    CheckButton = $VBox/MusicRow/MusicToggle
@onready var volume_slider:   HSlider     = $VBox/VolumeRow/VolumeSlider
@onready var back_button:     Button      = $VBox/BackButton
@onready var save_button:     Button      = $VBox/Save
@onready var exit_button:     Button      = $VBox/Exit
@onready var sounds_toggle: CheckButton = $VBox/SoundsRow/SoundsToggle
@onready var sounds_volume_slider: HSlider = $VBox/VolumeRow2/SoundsVolumeSlider


func _ready() -> void:
	volume_slider.min_value = 0.0
	volume_slider.max_value = 1.0
	volume_slider.step = 0.01
	volume_slider.value = MusicManager.music_volume

	music_toggle.button_pressed = MusicManager.music_enabled

	sounds_volume_slider.min_value = 0.0
	sounds_volume_slider.max_value = 1.0
	sounds_volume_slider.step = 0.01
	sounds_volume_slider.value = MusicManager.sounds_volume

	sounds_toggle.button_pressed = MusicManager.sounds_enabled

	music_toggle.toggled.connect(_on_music_toggled)
	volume_slider.value_changed.connect(_on_volume_changed)

	sounds_toggle.toggled.connect(_on_sounds_toggled)
	sounds_volume_slider.value_changed.connect(_on_sounds_volume_changed)

	back_button.pressed.connect(_on_back_pressed)
	save_button.pressed.connect(_on_save_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

	save_button.visible = in_game
	exit_button.visible = in_game


func _on_sounds_toggled(enabled: bool) -> void:
	MusicManager.set_sounds_enabled(enabled)


func _on_sounds_volume_changed(value: float) -> void:
	MusicManager.set_sounds_volume(value)

func _unhandled_input(event: InputEvent) -> void:
	if in_game and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_on_back_pressed()


func _on_music_toggled(enabled: bool) -> void:
	MusicManager.set_music_enabled(enabled)


func _on_volume_changed(value: float) -> void:
	MusicManager.set_volume(value)


func _on_back_pressed() -> void:
	if in_game:
		# Wróć do gry
		get_tree().paused = false
		queue_free()
	else:
		get_tree().change_scene_to_file("res://Menu/control.tscn")


func _on_save_pressed() -> void:
	print("Save pressed!")
	get_tree().paused = false
	await get_tree().process_frame
	var saver := get_tree().get_first_node_in_group("world_saver")
	print("Saver znaleziony: ", saver)
	if saver and saver.has_method("save_game"):
		saver.save_game()
		print("Gra zapisana!")
	get_tree().paused = true


func _on_exit_pressed() -> void:
	get_tree().quit()
