extends Button

@onready var player: Player

func _on_pressed() -> void:
	player=get_tree().get_first_node_in_group("Players")
	get_tree().change_scene_to_file("res://Boss_Area/BossArea.tscn")
	visible=false
