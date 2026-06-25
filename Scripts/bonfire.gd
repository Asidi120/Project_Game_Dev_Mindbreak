extends StaticBody2D
var player_in_range := false
var inventory_system = null

const MAX_STACK = 12

var meat_ids_list := []
var ore_ids_list := []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	inventory_system = get_tree().get_first_node_in_group("inventory_ui")
	if put_meat_into_bonfire():
		var cooked_meat_id = meat_ids_list.pop_front()
		var path = "res://Scenes/Food/meat_cooked_" + cooked_meat_id + ".tscn"
		await get_tree().create_timer(4.0).timeout
		print("meat putttttttttttttttt")
		get_cooked_meat(path)
	
	if put_ore_into_bonfire():
		var ore_id = ore_ids_list.pop_front()
		var path = "res://Scenes/Items/" + ore_id + "_bar.tscn"
		await get_tree().create_timer(4.0).timeout
		print("ore putttttttttttttttt")
		get_cooked_meat(path)
	
	if put_egg_into_bonfire():
		var path = "res://Scenes/Food/fried_egg.tscn"
		await get_tree().create_timer(4.0).timeout
		print("egg putttttttttttttttt")
		get_cooked_meat(path)

func has_egg_in_hand() -> bool:
	var egg_held := false
	
	if inventory_system == null:
		return egg_held

	var index = inventory_system.selected_fasteq_index
	
	if index < 0 or index >= inventory_system.current_inventory.size():
		return egg_held

	var item = inventory_system.current_inventory[index]
	
	if item == null:
		return egg_held
	
	if item["item_type"] == "egg":
		egg_held = true
	
	return egg_held
	
func has_raw_meat_in_hand() -> bool:
	var raw_meat_held := false
	
	if inventory_system == null:
		return raw_meat_held

	var index = inventory_system.selected_fasteq_index
	
	if index < 0 or index >= inventory_system.current_inventory.size():
		return raw_meat_held

	var item = inventory_system.current_inventory[index]
	
	if item == null:
		return raw_meat_held
	
	if item["item_type"] == "meat_raw":
		raw_meat_held = true
	
	return raw_meat_held
	
func has_ore_in_hand() -> bool:
	var ore_held := false
	
	if inventory_system == null:
		return ore_held

	var index = inventory_system.selected_fasteq_index
	
	if index < 0 or index >= inventory_system.current_inventory.size():
		return ore_held

	var item = inventory_system.current_inventory[index]
	
	if item == null:
		return ore_held
	
	if item["item_type"] == "ore":
		ore_held = true
	
	return ore_held

func put_egg_into_bonfire() -> bool:
	var if_egg_put := false
	if player_in_range and Input.is_action_just_pressed("cook") and has_egg_in_hand():
		print("coooooooooook")
		
		var index = inventory_system.selected_fasteq_index
		var item = inventory_system.current_inventory[index]
		
		#var meat_id = item["item_id"].split("_")[-1]
		#meat_ids_list.append(meat_id)
		#print(meat_ids_list)
		
		#usuniecie z ekwipunka 
		if item["amount"] > 1:
			item["amount"] -= 1
		else:
			inventory_system.current_inventory[index] = null

		inventory_system.refresh_all()
		if_egg_put = true
		
	return if_egg_put
	
func put_meat_into_bonfire() -> bool:
	var if_meat_put := false
	if player_in_range and Input.is_action_just_pressed("cook") and has_raw_meat_in_hand():
		print("coooooooooook")
		
		var index = inventory_system.selected_fasteq_index
		var item = inventory_system.current_inventory[index]
		
		var meat_id = item["item_id"].split("_")[-1]
		meat_ids_list.append(meat_id)
		print(meat_ids_list)
		
		#usuniecie z ekwipunka 
		if item["amount"] > 1:
			item["amount"] -= 1
		else:
			inventory_system.current_inventory[index] = null

		inventory_system.refresh_all()
		if_meat_put = true
		
	return if_meat_put
	
func put_ore_into_bonfire() -> bool:
	var if_ore_put := false
	if player_in_range and Input.is_action_just_pressed("cook") and has_ore_in_hand():
		print("oreeeeeeeeeeee")
		
		var index = inventory_system.selected_fasteq_index
		var item = inventory_system.current_inventory[index]
		
		var ore_material = item["item_id"].split("_")[0]
		ore_ids_list.append(ore_material)
		print(ore_ids_list)
		
		#usuniecie z ekwipunka 
		if item["amount"] > 1:
			item["amount"] -= 1
		else:
			inventory_system.current_inventory[index] = null

		inventory_system.refresh_all()
		if_ore_put = true
		
	return if_ore_put

func create_item_data_from_scene(scene_path: String) -> Dictionary:
	var item_scene = load(scene_path)

	if item_scene == null:
		push_error("Nie udało się wczytać sceny: " + scene_path)
		return {}

	var item_instance = item_scene.instantiate()

	# żeby nie pojawił się fizycznie ani nie wykrywał gracza
	item_instance.visible = false
	item_instance.monitoring = false
	item_instance.monitorable = false

	# dodajemy chwilowo do drzewa, bo wtedy zadziała @onready sprite_2d
	add_child(item_instance)

	var item_data = {
		"item_id": item_instance.item_id,
		"texture": item_instance.get_icon(),
		"item_type": item_instance.item_type,
		"scene_path": scene_path,
		"amount": 1
	}

	if item_instance is Food:
		item_data["hunger_points"] = item_instance.hunger_points

	item_instance.free()

	return item_data
	
func get_cooked_meat(path):
	
	var cooked_meat = create_item_data_from_scene(path)
	var added = false
	var inventory = inventory_system.current_inventory

	for i in range(inventory.size() - 1, -1, -1):
		if inventory[i] != null:
			var item_data = inventory[i]
			if item_data["item_id"] == cooked_meat["item_id"] and cooked_meat["amount"] < MAX_STACK:
				item_data["amount"] += 1
				added = true
				break

	if not added:
		for i in range(inventory.size()):
			if inventory[i] == null:
				cooked_meat["amount"] = 1
				inventory[i] = cooked_meat
				added = true
				break
	inventory_system.refresh_all()
		
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_in_range = true #player w obrębie struktury


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_in_range = false #player poza strukturą
