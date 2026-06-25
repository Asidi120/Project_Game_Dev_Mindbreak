extends StaticBody2D

var player_in_range := false
@export var hits_needed := 4.0
@export var object_id := ""
@export var object_type := ""
@export var position_of_power_needed := 0
var hits := 0.0
@onready var tree_hit: AudioStreamPlayer2D = $TreeHit
@export var scene: PackedScene
@export var scene2: PackedScene
var inventory_system = null


func _ready() -> void:
	add_to_group("world_item")
	call_deferred("_init_inventory")


func _init_inventory() -> void:
	inventory_system = get_tree().get_first_node_in_group("inventory_ui")


func update_hits():
	if inventory_system == null:
		return
	var index = inventory_system.selected_fasteq_index

	if index < 0 or index >= inventory_system.current_inventory.size():
		return
	var item = inventory_system.current_inventory[index]

	if item == null and (object_type == "tree" or object_type == "bush"):
		hits += 1

	if item == null:
		return

	if item["item_type"] == "axe" and object_type == "tree":
		hits += item["tool_power"]
		if tree_hit:
			tree_hit.play()
		item["item_durability"] -= 1
	elif item["item_type"] == "pickaxe" and object_type == "boulder":
		hits += item["tool_power"]
		item["item_durability"] -= 1
	elif object_type == "tree" or object_type == "bush":
		hits += 1

	var list_of_nodes = ["iron", "copper", "gold", "diamond"]
	if object_type in list_of_nodes and item["item_type"] == "pickaxe":
		if item["position_of_power"] >= position_of_power_needed:
			hits += item["tool_power"]
			item["item_durability"] -= 1

	if item is Tool:
		if item["item_durability"] <= 0:
			inventory_system.current_inventory[index] = null
			inventory_system.refresh_all()
			return


func _process(_delta: float) -> void:
	if player_in_range and Input.is_action_just_pressed("attack"):
		update_hits()
		print("Uderzenie: ", hits)
		if hits >= hits_needed:
			print(object_id, " destroyed")
			WorldStateManager.mark_removed(
				get_tree().current_scene.scene_file_path,
				global_position
			)
			drop_item()
			queue_free()


func drop_item():
	if scene:
		var item = scene.instantiate()
		get_parent().add_child(item)
		item.global_position = global_position + Vector2(0, 20)
		WorldStateManager.save_dropped_item(
			get_tree().current_scene.scene_file_path,
			scene.resource_path,
			"",
			"",
			item.global_position
		)
	if scene2:
		var item2 = scene2.instantiate()
		get_parent().add_child(item2)
		item2.global_position = global_position + Vector2(10, 35)
		WorldStateManager.save_dropped_item(
			get_tree().current_scene.scene_file_path,
			scene2.resource_path,
			"",
			"",
			item2.global_position
		)


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_in_range = true


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_in_range = false
