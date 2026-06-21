extends Node

var saved_items: Dictionary = {}


func save_scene_items(scene_path: String) -> void:
	var items_data: Array = []
	var all_items := get_tree().get_nodes_in_group("world_item")
	for item in all_items:
		if not is_instance_valid(item):
			continue
		items_data.append({
			"scene_path": item.scene_file_path,
			"item_id":    item.item_id,
			"item_type":  item.item_type,
			"position":   { "x": item.global_position.x, "y": item.global_position.y }
		})
	saved_items[scene_path] = items_data
	print("CaveItemManager: zapisano %d itemów dla %s" % [items_data.size(), scene_path])


func restore_scene_items(scene_path: String) -> void:
	if not saved_items.has(scene_path):
		return
	var items_data: Array = saved_items[scene_path]
	var current_scene := get_tree().current_scene
	for data in items_data:
		if not ResourceLoader.exists(data["scene_path"]):
			push_warning("CaveItemManager: brak sceny %s" % data["scene_path"])
			continue
		var item_scene := load(data["scene_path"])
		var item: Node = item_scene.instantiate()
		current_scene.add_child(item)
		item.global_position = Vector2(data["position"]["x"], data["position"]["y"])
	print("CaveItemManager: przywrócono %d itemów dla %s" % [items_data.size(), scene_path])
