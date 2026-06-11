extends StaticBody2D
var player_in_range := false
@export var hits_needed := 4 #ilosc potrzebnych uderzen
@export var object_id := ""
@export var object_type := ""
var hits := 0

@export var scene: PackedScene #instancja sceny struktury
@export var scene2: PackedScene

var inventory_system = null

func update_hits():
	if inventory_system == null:
		return

	var index = inventory_system.selected_fasteq_index

	if index < 0 or index >= inventory_system.current_inventory.size():
		hits += 1
		return

	var item = inventory_system.current_inventory[index]

	if item == null:
		hits += 1
		return

	if item["item_type"] == "axe" and object_type == "tree":
		hits += item["tool_power"]
	else:
		hits += 1
	
func _ready() -> void:
	inventory_system = get_tree().get_first_node_in_group("inventory_ui")
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if player_in_range and Input.is_action_just_pressed("attack"): #jesli player w zasiegu i uderzy
		update_hits()
		print("Uderzenie: ", hits)

		if hits >= hits_needed: #jesli player przekroczy ilosc uderzen
			print(object_id, " destroyed")
			queue_free() #struktura znika
			drop_item()
			
func drop_item():
	if scene:
		var item = scene.instantiate()
		get_parent().add_child(item)
		item.global_position = global_position + Vector2(0, 20)
		
	if scene2:
		var item2 = scene2.instantiate()
		get_parent().add_child(item2)
		item2.global_position = global_position + Vector2(10, 35)

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_in_range = true #player w obrębie struktury

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_in_range = false #player poza strukturą
