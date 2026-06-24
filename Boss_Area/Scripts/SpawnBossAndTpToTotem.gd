extends Node2D

var spawn_point = Vector2(75, -95)
@onready var killed_boss: Label = $HUD/KilledBoss

var boss_alive = true

func spawn_boss():
	print("=== SPAWN_BOSS START ===")
	print("current_dungeon_name =", BossManager.current_dungeon_name)
	print("current_rune_name =", BossManager.current_rune_name)
	print("unlocked_runes =", BossManager.unlocked_runes)

	var rune_name = BossManager.current_rune_name

	if rune_name == null:
		print("ERROR: rune_name == null")
		return

	if BossManager.unlocked_runes.get(rune_name, false):
		print("Boss już pokonany, nie spawnuję")
		killed_boss.visible=true
		await get_tree().create_timer(3.0).timeout
		SceneTransition.change_scene_with_save("res://Player/word.tscn")
		return

	var boss_scene = BossManager.boss_path

	print("boss_path =", boss_scene)

	if boss_scene == null:
		print("ERROR: boss_scene == null")
		return

	print("Instantiating boss...")
	var boss = boss_scene.instantiate()

	if boss == null:
		print("ERROR: instantiate() zwrócił null")
		return

	add_child(boss)
	boss.global_position = spawn_point

	print("Boss spawned:", boss.name)
	print("Boss position:", boss.global_position)

	for bosses in get_tree().get_nodes_in_group("Boss"):
		print("Found boss in group:", bosses.name)

		if not bosses.died.is_connected(boss_died):
			print("Connecting died signal:", bosses.name)
			bosses.died.connect(boss_died)

	print("=== SPAWN_BOSS END ===")


func boss_died():
	print("=== BOSS DIED ===")
	print("current_dungeon_name =", BossManager.current_dungeon_name)

	BossManager.defeated_bosses[BossManager.current_dungeon_name] = true

	print("defeated_bosses =", BossManager.defeated_bosses)

	totem_dungeon_tp()


func totem_dungeon_tp():
	print("=== TOTEM TP ===")
	print("Loading TotemDungeon")

	SceneTransition.change_scene_with_save("res://Scenes/TotemDungeon.tscn")
