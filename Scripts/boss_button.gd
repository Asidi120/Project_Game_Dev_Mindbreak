extends Button

@onready var player: Player = $"Player"
@onready var boss_area: Node2D = $"BossArea"


func _on_pressed() -> void:
	player=get_tree().get_first_node_in_group("Players")
	#boss_area=get_tree().get_first_node_in_group("BossArea")
	#boss_area.visible=true
	player.global_position=Vector2(350,350)
	visible=false
