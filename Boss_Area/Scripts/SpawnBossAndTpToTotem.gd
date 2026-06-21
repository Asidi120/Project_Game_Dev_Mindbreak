extends Node2D

var spawn_point=Vector2(75,-95)

var boss_alive=true

func spawn_boss():
	var boss_scene = BossManager.boss_path
	var boss = boss_scene.instantiate()
	add_child(boss)
	boss.global_position=spawn_point
	boss_alive=true
	for bosses in get_tree().get_nodes_in_group("Boss"):
		bosses.died.connect(boss_died)

func boss_died():
	boss_alive=false
	totem_dungeon_tp()

func totem_dungeon_tp():
	if Input.is_action_just_pressed("action (open door, sleep etc.)"):
			get_tree().change_scene_to_file("res://Scenes/TotemDungeon.tscn")
