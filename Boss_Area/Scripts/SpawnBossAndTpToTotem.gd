extends Node2D

var spawn_point=Vector2(75,-95)

var boss_alive=true

func spawn_boss():
	var boss_scene = BossManager.boss_path
	var boss = boss_scene.instantiate()
	add_child(boss)
	boss.global_position = spawn_point
	print("Spawned boss:", boss.name)
	for bosses in get_tree().get_nodes_in_group("Boss"):
		print("Connecting:", bosses.name)
		if not bosses.died.is_connected(boss_died):
			bosses.died.connect(boss_died)

func boss_died():
	boss_alive=false
	print("boss died")
	totem_dungeon_tp()

func totem_dungeon_tp():
	print("totemdungeontp")
	get_tree().change_scene_to_file("res://Scenes/TotemDungeon.tscn")
