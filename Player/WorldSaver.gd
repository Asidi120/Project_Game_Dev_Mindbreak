extends Node

@export var autosave_interval: float = 60.0
var autosave_timer: float = 0.0


func _process(delta: float) -> void:
	autosave_timer += delta
	if autosave_timer >= autosave_interval:
		autosave_timer = 0.0
		save_game()


func save_game() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return

	var player_data := {}
	if FileAccess.file_exists("user://player_data.json"):
		var f := FileAccess.open("user://player_data.json", FileAccess.READ)
		var parsed = JSON.parse_string(f.get_as_text())
		f.close()
		if parsed is Dictionary:
			player_data = parsed

	var inventory_system = get_tree().get_first_node_in_group("inventory_ui")
	var inv: Array = []
	if inventory_system:
		for item in inventory_system.current_inventory:
			if item == null:
				inv.append(null)
			else:
				inv.append({
					"item_id":           item.get("item_id", ""),
					"item_type":         item.get("item_type", ""),
					"scene_path":        item.get("scene_path", ""),
					"amount":            int(item.get("amount", 1)),
					"hunger_points":     int(item.get("hunger_points", 0)),
					"item_durability":   int(item.get("item_durability", 999)),
					"power":             int(item.get("power", 0)),
					"tool_power":        float(item.get("tool_power", 0)),
					"position_of_power": int(item.get("position_of_power", 0)),
				})

	var house := get_tree().get_first_node_in_group("house")
	var house_pos := Vector2.ZERO
	if house:
		house_pos = house.global_position

	var clock := get_tree().get_first_node_in_group("Clock")
	var game_time: float = 720.0
	if clock:
		var dc = clock.get_node_or_null("day_counter")
		if dc:
			game_time = dc.time

	var save_data := {
		"world_name":    player_data.get("world_name", "Świat"),
		"player_name":   player_data.get("player_name", "Gracz"),
		"world_seed":    int(player_data.get("world_seed", 0)),
		"skin_index":    int(player_data.get("skin_index", 0)),
		"hair_index":    int(player_data.get("hair_index", 0)),
		"hair_color":    int(player_data.get("hair_color", 0)),
		"clothes_index": int(player_data.get("clothes_index", 0)),
		"hp":            int(player.current_hp),
		"hunger":        int(player.current_hunger),
		"stamina":       int(player.current_stamina),
		"pos_x":         player.global_position.x,
		"pos_y":         player.global_position.y,
		"game_time":     game_time,
		"inventory":     inv,
		"world_state":   WorldStateManager.scene_states,
		"history_played": SceneTransition.history_played
	}
	SaveManager.save(save_data)
