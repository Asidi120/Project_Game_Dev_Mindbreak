extends Node

var scene_states: Dictionary = {}


func save_scene(scene_path: String) -> void:
	var removed_positions: Array = []
	if scene_states.has(scene_path):
		removed_positions = scene_states[scene_path].get("removed_positions", [])
	# Zachowaj tylko dropped items (nie skanuj world_item bo to robi save_dropped_item)
	var items: Array = []
	if scene_states.has(scene_path):
		items = scene_states[scene_path].get("items", [])
	scene_states[scene_path] = {
		"removed_positions": removed_positions,
		"items": items,
	}


func restore_scene(scene_path: String) -> void:
	if not scene_states.has(scene_path):
		return

	await get_tree().process_frame

	var state: Dictionary = scene_states[scene_path]
	var removed_positions: Array = state.get("removed_positions", [])

	# Usuń zebrane/zniszczone obiekty
	for node in get_tree().get_nodes_in_group("world_item"):
		if not is_instance_valid(node):
			continue
		for pos in removed_positions:
			if node.global_position.distance_to(pos) < 4.0:
				node.queue_free()
				break

	# Przywróć wyrzucone itemy
	await get_tree().process_frame
	var current := get_tree().current_scene
	for data in state.get("items", []):
		if not ResourceLoader.exists(data["scene_path"]):
			continue
		var item_scene := load(data["scene_path"])
		var item: Node = item_scene.instantiate()
		current.add_child(item)
		item.global_position = Vector2(data["x"], data["y"])


func mark_removed(scene_path: String, world_position: Vector2) -> void:
	if not scene_states.has(scene_path):
		scene_states[scene_path] = { "removed_positions": [], "items": [] }
	scene_states[scene_path]["removed_positions"].append(world_position)


func save_dropped_item(scene_path: String, item_scene_path: String, item_id: String, item_type: String, pos: Vector2) -> void:
	if not scene_states.has(scene_path):
		scene_states[scene_path] = { "removed_positions": [], "items": [] }
	scene_states[scene_path]["items"].append({
		"scene_path": item_scene_path,
		"item_id":    item_id,
		"item_type":  item_type,
		"x": pos.x,
		"y": pos.y,
	})
	print("Zapisano wyrzucony item: %s w %s" % [item_id, scene_path])


func remove_dropped_item(scene_path: String, pos: Vector2) -> void:
	if not scene_states.has(scene_path):
		return
	var items: Array = scene_states[scene_path].get("items", [])
	for i in range(items.size() - 1, -1, -1):
		var item_pos := Vector2(items[i]["x"], items[i]["y"])
		if item_pos.distance_to(pos) < 4.0:
			items.remove_at(i)
			break
