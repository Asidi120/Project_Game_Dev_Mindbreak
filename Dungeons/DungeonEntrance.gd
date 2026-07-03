extends Node2D

@export var dungeon_id := 1
@onready var click_to_open_label: Label = $ClickToOpenLabel

var player_in_door_area := false

var dungeon_paths = {
	1: "res://Dungeons/DungeonFirst/DungeonFirst.tscn",
	2: "res://Dungeons/DungeonSecond/DungeonSecond.tscn",
	3: "res://Dungeons/DungeonThird/DungeonThird.tscn"
}

func _ready():
	click_to_open_label.visible = false

func _process(delta):
	if player_in_door_area:
		if Input.is_action_just_pressed("action (open door, sleep etc.)"):
			print("DUNGEON ID =", dungeon_id)

			if dungeon_paths.has(dungeon_id):
				SceneTransition.change_scene_with_save(dungeon_paths[dungeon_id])
			else:
				print("Brak ścieżki dla dungeon_id:", dungeon_id)

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Players") or body.is_in_group("player"):
		player_in_door_area = true
		click_to_open_label.visible = true

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("Players") or body.is_in_group("player"):
		player_in_door_area = false
		click_to_open_label.visible = false
