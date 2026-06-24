extends StaticBody2D
var player_in_range := false
@export var hits_needed := 4.0 #ilosc potrzebnych uderzen
@export var object_id := ""
@export var object_type := ""
@export var position_of_power_needed := 0
var hits := 0.0
@onready var tree_hit: AudioStreamPlayer2D = $TreeHit
@export var scene: PackedScene #instancja sceny struktury
@export var scene2: PackedScene

var inventory_system = null

func update_hits():
	if inventory_system == null:
		return

	var index = inventory_system.selected_fasteq_index
	
	if index < 0 or index >= inventory_system.current_inventory.size():
		return

	var item = inventory_system.current_inventory[index]
	
	#jesli nie ma nic w raczce mozna niszczyc tree i bush
	if item == null and (object_type == "tree" or object_type == "bush"):
		hits += 1
	
	if item == null:
		return

	# niszczenie tree majac axe
	if item["item_type"] == "axe" and object_type == "tree":
		hits += item["tool_power"]
		if tree_hit:
			tree_hit.play()
		item["item_durability"] -= 1
	# niszczenie boulder majac pickaxe
	elif item["item_type"] == "pickaxe" and object_type == "boulder":
		hits += item["tool_power"]
		item["item_durability"] -= 1
	# niszczenie tree i bush majac jakikolwiek inny przedmiot
	elif object_type == "tree" or object_type == "bush":
		hits += 1	
		
	
	
	#nodes
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
