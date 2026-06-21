extends Control

const MAX_STACK := 12

@onready var recipes_container: GridContainer = $Background/ScrollContainer/RecipesContainer

var crafting_slot_scene = preload("res://Crafting/Scenes/crafting_slot.tscn")

var inventory_system = null
var texture_cache := {}


var recipes := [
	#AXES
	{
		"result_scene": "res://Scenes/Tools/axe_wood.tscn",
		"result_id": "axe_wood",
		"result_amount": 1,
		"requirements": [
			{
				"item_id": "stick",
				"needed_amount": 4,
				"scene_path": "res://Scenes/Items/stick.tscn"
			},
			{
				"item_id": "wood",
				"needed_amount": 3,
				"scene_path": "res://Scenes/Items/wood.tscn"
			}
		]
	},
	{
		"result_scene": "res://Scenes/Tools/axe_stone.tscn",
		"result_id": "axe_stone",
		"result_amount": 1,
		"requirements": [
			{
				"item_id": "stick",
				"needed_amount": 4,
				"scene_path": "res://Scenes/Items/stick.tscn"
			},
			{
				"item_id": "stone",
				"needed_amount": 3,
				"scene_path": "res://Scenes/Items/stone.tscn"
			}
		]
	},
	{
		"result_scene": "res://Scenes/Tools/axe_iron.tscn",
		"result_id": "axe_iron",
		"result_amount": 1,
		"requirements": [
			{
				"item_id": "stick",
				"needed_amount": 4,
				"scene_path": "res://Scenes/Items/stick.tscn"
			},
			{
				"item_id": "iron_ore",
				"needed_amount": 3,
				"scene_path": "res://Scenes/Items/iron_ore.tscn"
			}
		]
	},
]


func _ready() -> void:
	visible = false
	inventory_system = get_inventory_ui()
	refresh_recipes()


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("crafting"):
		toggle_crafting()


func toggle_crafting() -> void:
	visible = !visible

	if visible:
		inventory_system = get_inventory_ui()
		refresh_recipes()


func get_inventory_ui():
	for ui in get_tree().get_nodes_in_group("inventory_ui"):
		if ui.name == "Inventory":
			return ui

	return null


func refresh_recipes() -> void:
	if inventory_system == null:
		inventory_system = get_inventory_ui()

	if inventory_system == null:
		print("Nie znaleziono Inventory UI")
		return

	for child in recipes_container.get_children():
		child.queue_free()

	for recipe in recipes:
		prepare_recipe_textures(recipe)

		var crafting_slot = crafting_slot_scene.instantiate()
		recipes_container.add_child(crafting_slot)

		crafting_slot.custom_minimum_size = Vector2(260, 100)

		var can_make = can_craft(recipe)

		crafting_slot.set_recipe(recipe, can_make)
		crafting_slot.craft_pressed.connect(_on_recipe_craft_pressed)


func prepare_recipe_textures(recipe: Dictionary) -> void:
	for requirement in recipe["requirements"]:
		requirement["texture"] = get_texture_from_scene(requirement["scene_path"])

	recipe["result_texture"] = get_texture_from_scene(recipe["result_scene"])


func get_texture_from_scene(scene_path: String) -> Texture2D:
	if texture_cache.has(scene_path):
		return texture_cache[scene_path]

	var item_scene = load(scene_path)

	if item_scene == null:
		push_error("Nie udało się wczytać sceny: " + scene_path)
		return null

	var item_instance = item_scene.instantiate()

	if item_instance is CanvasItem:
		item_instance.visible = false

	if item_instance is Area2D:
		item_instance.monitoring = false
		item_instance.monitorable = false

	add_child(item_instance)

	var texture: Texture2D = null

	if item_instance.has_method("get_icon"):
		texture = item_instance.get_icon()
	else:
		push_error("Item nie ma funkcji get_icon(): " + scene_path)

	item_instance.queue_free()

	texture_cache[scene_path] = texture
	return texture


func get_item_count(item_id: String) -> int:
	var count := 0

	for item in inventory_system.current_inventory:
		if item == null:
			continue

		if item["item_id"] == item_id:
			count += item["amount"]

	return count


func can_craft(recipe: Dictionary) -> bool:
	for requirement in recipe["requirements"]:
		var item_id = requirement["item_id"]
		var needed_amount = requirement["needed_amount"]

		if get_item_count(item_id) < needed_amount:
			return false

	if not can_add_result_to_inventory(recipe):
		return false

	return true


func can_add_result_to_inventory(recipe: Dictionary) -> bool:
	var result_id = recipe["result_id"]

	for item in inventory_system.current_inventory:
		if item == null:
			return true

		if item["item_id"] == result_id and item["amount"] < MAX_STACK:
			return true

	return false


func _on_recipe_craft_pressed(recipe: Dictionary) -> void:
	craft(recipe)


func craft(recipe: Dictionary) -> void:
	if not can_craft(recipe):
		print("Nie można stworzyć tego itemu")
		return

	var crafted_item = create_item_data_from_scene(recipe["result_scene"], recipe["result_amount"])

	if crafted_item.is_empty():
		return

	remove_recipe_items(recipe)

	var added = add_item_to_inventory(crafted_item)

	if not added:
		print("Brak miejsca w ekwipunku")
		return

	inventory_system.refresh_all()
	refresh_recipes()


func remove_recipe_items(recipe: Dictionary) -> void:
	for requirement in recipe["requirements"]:
		remove_items(requirement["item_id"], requirement["needed_amount"])


func remove_items(item_id: String, amount: int) -> void:
	var amount_left := amount

	for i in range(inventory_system.current_inventory.size()):
		var item = inventory_system.current_inventory[i]

		if item == null:
			continue

		if item["item_id"] != item_id:
			continue

		if item["amount"] > amount_left:
			item["amount"] -= amount_left
			return
		else:
			amount_left -= item["amount"]
			inventory_system.current_inventory[i] = null

		if amount_left <= 0:
			return


func create_item_data_from_scene(scene_path: String, amount: int = 1) -> Dictionary:
	var item_scene = load(scene_path)

	if item_scene == null:
		push_error("Nie udało się wczytać sceny: " + scene_path)
		return {}

	var item_instance = item_scene.instantiate()

	if item_instance is CanvasItem:
		item_instance.visible = false

	if item_instance is Area2D:
		item_instance.monitoring = false
		item_instance.monitorable = false

	add_child(item_instance)

	var item_data = {
		"item_id": item_instance.item_id,
		"texture": item_instance.get_icon(),
		"item_type": item_instance.item_type,
		"scene_path": scene_path,
		"amount": amount
	}

	if item_instance is Food:
		item_data["hunger_points"] = item_instance.hunger_points

	item_instance.queue_free()

	return item_data


func add_item_to_inventory(item_data: Dictionary) -> bool:
	for i in range(inventory_system.current_inventory.size()):
		var item = inventory_system.current_inventory[i]

		if item == null:
			continue

		if item["item_id"] == item_data["item_id"] and item["amount"] < MAX_STACK:
			var space = MAX_STACK - item["amount"]
			var transfer = min(space, item_data["amount"])

			item["amount"] += transfer
			item_data["amount"] -= transfer

			if item_data["amount"] <= 0:
				return true

	for i in range(inventory_system.current_inventory.size()):
		if inventory_system.current_inventory[i] == null:
			inventory_system.current_inventory[i] = item_data.duplicate(true)
			return true

	return false
