extends Node2D

@onready var click_to_open_label: Label = $ClickToOpenLabel

var player_in_door_area = false

var door_to_dungeon = {
	"Dungeon1Entrance": "DungeonFirst",
	"Dungeon1Entrance2": "DungeonSecond",
	"Dungeon1Entrance3": "DungeonThird"
}

var dungeon_paths = {
	"DungeonFirst": "res://Dungeons/DungeonFirst/DungeonFirst.tscn",
	"DungeonSecond": "res://Dungeons/DungeonSecond/DungeonSecond.tscn",
	"DungeonThird": "res://Dungeons/DungeonThird/DungeonThird.tscn"
}

func _process(delta):
	if player_in_door_area:
		if Input.is_action_just_pressed("action (open door, sleep etc.)"):
			var door_name = name
			print("DOOR NAME =", name)
			if door_to_dungeon.has(door_name):
				var dungeon_key = door_to_dungeon[door_name]
				SceneTransition.change_scene_with_save(dungeon_paths[dungeon_key])
			
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Players"):
		player_in_door_area = true
		click_to_open_label.visible = true

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("Players"):
		player_in_door_area = false
		click_to_open_label.visible = false
