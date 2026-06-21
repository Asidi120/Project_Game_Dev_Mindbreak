extends Node2D
@onready var click_to_open_label: Label = $Labels/ClickToOpenLabel
var player_in_door_area = false

func _process(delta):
	if player_in_door_area:
		if Input.is_action_just_pressed("action (open door, sleep etc.)"):
			get_tree().change_scene_to_file("res://Dungeons/DungeonFirst/DungeonFirst.tscn")

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Players"):
		player_in_door_area=true
		click_to_open_label.visible=true

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("Players"):
		player_in_door_area=false
		click_to_open_label.visible=false
