extends Control

## settings_menu.gd — podłącz do root węzła sceny ustawień

@onready var music_toggle: CheckButton = $VBox/MusicRow/MusicToggle
@onready var volume_slider: HSlider    = $VBox/VolumeRow/VolumeSlider
@onready var back_button: Button       = $VBox/BackButton


func _ready() -> void:
	music_toggle.button_pressed = MusicManager.music_enabled
	volume_slider.value         = MusicManager.music_volume
	volume_slider.min_value     = 0.0
	volume_slider.max_value     = 1.0
	volume_slider.step          = 0.01

	music_toggle.toggled.connect(_on_music_toggled)
	volume_slider.value_changed.connect(_on_volume_changed)
	back_button.pressed.connect(_on_back_pressed)


func _on_music_toggled(enabled: bool) -> void:
	MusicManager.set_music_enabled(enabled)


func _on_volume_changed(value: float) -> void:
	MusicManager.set_volume(value)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://Menu/control.tscn")
