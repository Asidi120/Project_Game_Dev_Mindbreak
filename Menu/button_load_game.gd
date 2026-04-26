extends Button

func _on_pressed() -> void:
	icon = preload("res://MenuIcon/Load_Pressed.png")
	await get_tree().create_timer(0.2).timeout
	icon = preload("res://MenuIcon/Load_Not-Pressed.png")
