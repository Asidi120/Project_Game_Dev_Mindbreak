extends Button

func _on_pressed() -> void:
	icon = preload("res://MenuIcon/new_game_click.png")
	await get_tree().create_timer(0.2).timeout
	icon = preload("res://MenuIcon/new_game.png")

	get_tree().change_scene_to_file("res://MenuPlayer/create_player_menu.tscn")
