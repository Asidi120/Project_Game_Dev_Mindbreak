extends StaticBody2D
var player_in_range := false
var inventory_system = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	inventory_system = get_tree().get_first_node_in_group("inventory_ui")
	if put_meat_into_bonfire():
		print("meat putttttttttttttttt")

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
	
func put_meat_into_bonfire() -> bool:
	var if_meat_put := false
	if player_in_range and Input.is_action_just_pressed("cook") and has_raw_meat_in_hand():
		print("coooooooooook")
		
		var index = inventory_system.selected_fasteq_index
		var item = inventory_system.current_inventory[index]
		
		#usuniecie z ekwipunka 
		if item["amount"] > 1:
			item["amount"] -= 1
		else:
			inventory_system.current_inventory[index] = null

		inventory_system.refresh_all()
		if_meat_put = true
		
	return if_meat_put
		
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_in_range = true #player w obrębie struktury


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_in_range = false #player poza strukturą
