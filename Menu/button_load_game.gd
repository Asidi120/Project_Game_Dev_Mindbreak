extends Button

func _ready() -> void:
	disabled = not SaveManager.save_exists()


func _on_pressed() -> void:
	if not SaveManager.save_exists():
		return

	var data: Dictionary = SaveManager.load_save()
	if data.is_empty():
		return

	# Zapisz dane postaci do player_data.json
	var player_data := {
		"world_name":    data.get("world_name", "Świat"),
		"player_name":   data.get("player_name", "Gracz"),
		"world_seed":    data.get("world_seed", 0),
		"skin_index":    data.get("skin_index", 0),
		"hair_index":    data.get("hair_index", 0),
		"hair_color":    data.get("hair_color", 0),
		"clothes_index": data.get("clothes_index", 0),
	}
	var f := FileAccess.open("user://player_data.json", FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(player_data))
		f.close()

	# Przekaż stan gracza
	if data.has("hp"):
		SceneTransition.saved_hp      = int(data["hp"])
		SceneTransition.saved_hunger  = int(data["hunger"])
		SceneTransition.saved_stamina = int(data["stamina"])

	# Odtwórz inventory z teksturami
	if data.has("inventory"):
		var restored_inventory: Array = []
		for item_data in data["inventory"]:
			if item_data == null:
				restored_inventory.append(null)
				continue

			var scene_path: String = item_data.get("scene_path", "")
			var texture = null

			if scene_path != "" and ResourceLoader.exists(scene_path):
				var item_scene: PackedScene = load(scene_path)
				var temp_item: Node = item_scene.instantiate()
				# Dodaj do drzewa żeby Sprite2D był dostępny
				add_child(temp_item)
				await get_tree().process_frame
				if temp_item.has_method("get_icon"):
					texture = temp_item.get_icon()
				temp_item.queue_free()

			restored_inventory.append({
				"item_id":       item_data.get("item_id", ""),
				"item_type":     item_data.get("item_type", ""),
				"scene_path":    scene_path,
				"amount":        item_data.get("amount", 1),
				"hunger_points": item_data.get("hunger_points", 0),
				"texture":       texture,
			})
		SceneTransition.saved_inventory = restored_inventory

	# Wczytaj stan świata
	if data.has("world_state"):
		WorldStateManager.scene_states = data["world_state"]
		
		
	if data.has("pos_x"):
		SceneTransition.return_position = Vector2(float(data["pos_x"]), float(data["pos_y"]))
		SceneTransition.return_scene = "res://Player/word.tscn"
	get_tree().change_scene_to_file("res://Player/word.tscn")
