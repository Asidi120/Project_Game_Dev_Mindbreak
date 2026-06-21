extends Node

var boss_path

func _ready():
	for dungeon in get_tree().get_nodes_in_group("Dungeon"):
		dungeon.boss_door_entered.connect(_on_boss_door_entered)
	
func _on_boss_door_entered(dungeon_name: String):
	match dungeon_name:
		"DungeonFirst":
			boss_path=preload("uid://dmi0vi77ntxfa")
		"DungeonSecond":
			boss_path=preload("uid://cv7444xo418vm")
		"DungeonThird":
			boss_path=preload("uid://y8rspm1g8yk5")
	await get_tree().process_frame
	var boss_area = get_tree().get_first_node_in_group("BossArea")
	if boss_area:
		boss_area.spawn_boss()
