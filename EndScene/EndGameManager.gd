extends Node

func _ready():
	var endbutton = get_tree().get_first_node_in_group("EndGameButton")
	if endbutton:
		endbutton.pressed.connect(go_to_end_scene)

func go_to_end_scene():
	get_tree().change_scene_to_file("res://EndScene/Endscene.tscn")
