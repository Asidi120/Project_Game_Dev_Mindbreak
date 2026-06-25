extends Node


const SETTINGS_SCENE := preload("res://settings_menu.tscn")
var settings_instance: Control = null


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if settings_instance == null or not is_instance_valid(settings_instance):
			_open_settings()


func _open_settings() -> void:
	get_tree().paused = true
	settings_instance = SETTINGS_SCENE.instantiate()
	settings_instance.in_game = true
	settings_instance.process_mode = Node.PROCESS_MODE_ALWAYS  # ← dodaj
	var canvas := CanvasLayer.new()
	canvas.layer = 20
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS  # ← dodaj
	get_tree().current_scene.add_child(canvas)
	canvas.add_child(settings_instance)
