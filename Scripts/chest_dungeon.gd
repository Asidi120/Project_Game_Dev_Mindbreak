extends Chest
class_name ChestDungeon

var paths:= []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()

	paths = ["res://Scenes/Items/diamond_ore.tscn", "res://Scenes/Items/iron_ore.tscn"]
	generate_random_items()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	super._process(delta)

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
	
func generate_random_items():
	var number_of_items = randi_range(1, 5) #od 1 do 5 rzeczy w skrzynkach
	for i in range(number_of_items):
		var random_item_path_index = randi_range(0, paths.size()-1)
		#print(paths[random_item_path_index])
		var random_item = create_item_data_from_scene(paths[random_item_path_index])
		print(random_item)
		chest_inventory.append(random_item)
