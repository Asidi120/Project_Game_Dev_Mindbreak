extends Node

var return_scene:    String  = ""
var return_position: Vector2 = Vector2.ZERO
var spawn_name:      String  = "SpawnPoint"
var player_node:     Node    = null
var force_return_position: Vector2 = Vector2.ZERO

var saved_hp:        int   = 200
var saved_hunger:    int   = 150
var saved_stamina:   int   = 100
var saved_inventory: Array = []
var saved_game_time: float = 720.0


func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)


func _on_node_added(node: Node) -> void:
	if node == null or not is_instance_valid(node):
		return
	if node != get_tree().current_scene:
		return
	_place_player()


func _place_player() -> void:
	if player_node == null or not is_instance_valid(player_node):
		return

	await get_tree().process_frame
	await get_tree().process_frame

	var current := get_tree().current_scene
	if current == null:
		return



	for existing in get_tree().get_nodes_in_group("player"):
		if existing != player_node and is_instance_valid(existing):
			existing.get_parent().remove_child(existing)

	if current.scene_file_path == return_scene and return_position != Vector2.ZERO:
		player_node.global_position = return_position
	else:
		var marker := current.find_child(spawn_name, true, false)
		if marker:
			player_node.global_position = marker.global_position
		else:
			push_warning("SceneTransition: brak '%s'" % spawn_name)

	remove_child(player_node)
	current.add_child(player_node)
	player_node.z_index = 10
	player_node.visible = true
	player_node.set_physics_process(true)
	player_node.set_process(true)

	if player_node.has_method("reinitialize"):
		player_node.reinitialize()

	player_node = null


func travel(player: Node, target_scene: String, to_spawn: String) -> void:
	if player.has_method("save_state"):
		player.save_state()

	WorldStateManager.save_scene(get_tree().current_scene.scene_file_path)

	return_position = player.global_position
	return_scene    = get_tree().current_scene.scene_file_path
	spawn_name      = to_spawn
	player_node     = player

	player.get_parent().remove_child(player)
	add_child(player)
	player.visible = false
	player.set_physics_process(false)
	player.set_process(false)

	get_tree().change_scene_to_file(target_scene)


func travel_back(player: Node) -> void:
	print("travel_back: zapisuję ", get_tree().current_scene.scene_file_path)
	print("world_items w scenie: ", get_tree().get_nodes_in_group("world_item").size())
	if player.has_method("save_state"):
		player.save_state()
	WorldStateManager.save_scene(get_tree().current_scene.scene_file_path)
	print("po save: ", WorldStateManager.scene_states.keys())

	WorldStateManager.save_scene(get_tree().current_scene.scene_file_path)

	player_node = player
	spawn_name  = ""

	player.get_parent().remove_child(player)
	add_child(player)
	player.visible = false
	player.set_physics_process(false)
	player.set_process(false)

	get_tree().change_scene_to_file(return_scene)


func change_scene_with_save(target_scene: String):
	var player = get_tree().get_first_node_in_group("Players")

	if player and player.has_method("save_state"):
		player.save_state()

	saved_hp = player.current_hp
	saved_hunger = player.current_hunger
	saved_stamina = player.current_stamina

	if player.inventory_system:
		saved_inventory = player.inventory_system.current_inventory.duplicate(true)

	WorldStateManager.save_scene(get_tree().current_scene.scene_file_path)

	get_tree().change_scene_to_file(target_scene)
