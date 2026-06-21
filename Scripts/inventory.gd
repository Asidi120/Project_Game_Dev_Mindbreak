extends Control

static var selected_slot = null
static var selected_storage := ""

const MAX_SLOT = 18
const INVENTORY_SLOTS = 18
const FASTEQ_SLOTS = 6
const MAX_STACK = 12

static var current_inventory: Array = []
static var inventory_visible = false

@onready var grid: GridContainer = $Panel/GridContainer
@onready var background: TextureRect = $Panel

@onready var chest_panel: Control = get_node_or_null("ChestPanel")
@onready var chest_grid: GridContainer = get_node_or_null("ChestPanel/GridContainer")

var opened_chest = null

var slot_scene = preload("res://Scenes/item_slot.tscn")

var slot_offset := 0
static var selected_fasteq_index := 0
static var selected_slot_index := -1

var inventory_default_position: Vector2
var inventory_chest_position : Vector2


func _ready() -> void:
	if self.name == "Inventory":
		visible = false
		inventory_default_position = position
		inventory_chest_position = Vector2(position.x, 305)
		if chest_panel != null:
			chest_panel.visible = false

	if self.name == "FastEq":
		visible = true
		update_fasteq_selection()


func _process(_delta: float) -> void:
	if self.name == "Inventory":
		if Input.is_action_just_pressed("inventory"):
			toggle_inventory()
			
	if self.name == "FastEq":
		handle_fasteq_scroll()
		handle_fasteq_keys()

func handle_fasteq_keys() -> void:
	
	if Input.is_action_just_pressed("1"):
		selected_fasteq_index = 0
		
	if Input.is_action_just_pressed("2"):
		selected_fasteq_index = 1
		
	if Input.is_action_just_pressed("3"):
		selected_fasteq_index = 2
		
	if Input.is_action_just_pressed("4"):
		selected_fasteq_index = 3
		
	if Input.is_action_just_pressed("5"):
		selected_fasteq_index = 4
		
	if Input.is_action_just_pressed("6"):
		selected_fasteq_index = 5
		
#zmiana wybranego slota scrollem
func handle_fasteq_scroll() -> void:
	if Input.is_action_just_pressed("scroll_up"):
		selected_fasteq_index -= 1

	if Input.is_action_just_pressed("scroll_down"):
		selected_fasteq_index += 1
		

	selected_fasteq_index = wrapi(selected_fasteq_index, 0, FASTEQ_SLOTS)

	update_fasteq_selection()

#podswietlenie wybranego slota	
func update_fasteq_selection() -> void:
	if self.name != "FastEq":
		return

	for child in grid.get_children():
		child.set_selected(false)

	if grid.get_child_count() > selected_fasteq_index:
		var slot = grid.get_child(selected_fasteq_index)
		slot.set_selected(true)
		

func toggle_inventory() -> void:
	visible = !visible
	inventory_visible = visible

	var fasteq = get_fasteq_ui()

	if fasteq != null:
		fasteq.visible = !visible

	if not visible:
		clear_selection()

func open_chest_ui(chest) -> void:
	if self.name != "Inventory":
		return

	opened_chest = chest
	visible = true
	inventory_visible = true
	
	position = inventory_chest_position

	var fasteq = get_fasteq_ui()
	if fasteq != null:
		fasteq.visible = false

	if chest_panel != null:
		chest_panel.visible = true

	clear_all_selections()
	refresh_all()
	refresh_chest_ui()
	
func close_chest_ui() -> void:
	if self.name != "Inventory":
		return

	opened_chest = null
	inventory_visible = false
	
	position = inventory_default_position

	if chest_panel != null:
		chest_panel.visible = false

	visible = false

	var fasteq = get_fasteq_ui()
	if fasteq != null:
		fasteq.visible = true

	clear_all_selections()
	refresh_all()
	
func refresh_chest_ui() -> void:
	if self.name != "Inventory":
		return

	if chest_grid == null:
		return

	for child in chest_grid.get_children():
		child.queue_free()

	if opened_chest == null:
		return

	for i in range(opened_chest.chest_inventory.size()):
		var slot = slot_scene.instantiate()
		chest_grid.add_child(slot)

		slot.slot_index = i

		if opened_chest.chest_inventory[i] != null:
			slot.set_item(opened_chest.chest_inventory[i])
		else:
			slot.clear_item()

		slot.slot_clicked.connect(_on_chest_slot_clicked)
func add_item_to_storage(storage: Array, item_data: Dictionary) -> bool:
	var moved := false

	for i in range(storage.size()):
		if storage[i] != null:
			if storage[i]["item_id"] == item_data["item_id"] and storage[i]["amount"] < MAX_STACK:
				var space = MAX_STACK - storage[i]["amount"]
				var transfer = min(space, item_data["amount"])

				storage[i]["amount"] += transfer
				item_data["amount"] -= transfer
				moved = true

				if item_data["amount"] <= 0:
					return true

	for i in range(storage.size()):
		if storage[i] == null:
			storage[i] = item_data.duplicate(true)
			item_data["amount"] = 0
			return true

	return moved

func move_inventory_item_to_chest(index: int) -> void:
	if opened_chest == null:
		return

	if index < 0 or index >= current_inventory.size():
		return

	var item = current_inventory[index]

	if item == null:
		return

	add_item_to_storage(opened_chest.chest_inventory, item)

	if item["amount"] <= 0:
		current_inventory[index] = null

	refresh_all()
	refresh_chest_ui()
	
func move_chest_item_to_inventory(index: int) -> void:
	if opened_chest == null:
		return

	if index < 0 or index >= opened_chest.chest_inventory.size():
		return

	var item = opened_chest.chest_inventory[index]

	if item == null:
		return

	add_item_to_storage(current_inventory, item)

	if item["amount"] <= 0:
		opened_chest.chest_inventory[index] = null

	refresh_all()
	refresh_chest_ui()
	
func get_fasteq_ui():
	for ui in get_tree().get_nodes_in_group("inventory_ui"):
		if ui.name == "FastEq":
			return ui

	return null


func refresh_all() -> void:
	for ui in get_tree().get_nodes_in_group("inventory_ui"):
		ui.refresh(current_inventory)


func refresh(player_inventory: Array) -> void:
	var slots_to_show := 0

	if self.name == "Inventory":
		slots_to_show = INVENTORY_SLOTS
		slot_offset = 0

	if self.name == "FastEq":
		slots_to_show = FASTEQ_SLOTS
		slot_offset = 0

	current_inventory = player_inventory

	for child in grid.get_children():
		child.queue_free()

	for i in range(slots_to_show):
		var slot = slot_scene.instantiate()
		grid.add_child(slot)

		var real_index = i + slot_offset
		slot.slot_index = real_index

		if real_index < player_inventory.size() and player_inventory[real_index] != null:
			slot.set_item(player_inventory[real_index])
		else:
			slot.clear_item()
			
		if self.name == "Inventory":
			slot.slot_clicked.connect(_on_slot_clicked)


func swap_slots(from_index: int, to_index: int) -> void:
	if from_index == to_index:
		return

	if from_index < 0 or from_index >= current_inventory.size():
		return

	if to_index < 0 or to_index >= current_inventory.size():
		return

	var a = current_inventory[from_index]
	var b = current_inventory[to_index]

	if b == null:
		current_inventory[to_index] = a
		current_inventory[from_index] = null
		refresh_all()
		return

	if a != null and b != null and a["item_id"] == b["item_id"]:
		var space = MAX_STACK - b["amount"]

		if space > 0:
			var transfer = min(space, a["amount"])
			current_inventory[to_index]["amount"] += transfer
			current_inventory[from_index]["amount"] -= transfer

			if current_inventory[from_index]["amount"] <= 0:
				current_inventory[from_index] = null

			refresh_all()
			return

	current_inventory[from_index] = b
	current_inventory[to_index] = a

	refresh_all()
func swap_slots_in_storage(storage: Array, from_index: int, to_index: int) -> void:
	if from_index == to_index:
		return

	if from_index < 0 or from_index >= storage.size():
		return

	if to_index < 0 or to_index >= storage.size():
		return

	var a = storage[from_index]
	var b = storage[to_index]

	if a == null:
		return

	if b == null:
		storage[to_index] = a
		storage[from_index] = null
		return

	if a["item_id"] == b["item_id"]:
		var space = MAX_STACK - b["amount"]

		if space > 0:
			var transfer = min(space, a["amount"])
			b["amount"] += transfer
			a["amount"] -= transfer

			if a["amount"] <= 0:
				storage[from_index] = null

			return

	storage[from_index] = b
	storage[to_index] = a


func move_between_storages(from_storage: Array, from_index: int, to_storage: Array, to_index: int) -> void:
	if from_index < 0 or from_index >= from_storage.size():
		return

	if to_index < 0 or to_index >= to_storage.size():
		return

	var a = from_storage[from_index]
	var b = to_storage[to_index]

	if a == null:
		return

	if b == null:
		to_storage[to_index] = a
		from_storage[from_index] = null
		return

	if a["item_id"] == b["item_id"]:
		var space = MAX_STACK - b["amount"]

		if space > 0:
			var transfer = min(space, a["amount"])
			b["amount"] += transfer
			a["amount"] -= transfer

			if a["amount"] <= 0:
				from_storage[from_index] = null

			return

	from_storage[from_index] = b
	to_storage[to_index] = a


func handle_storage_click(slot, storage_name: String, storage: Array) -> void:
	if selected_slot == slot:
		clear_all_selections()
		return

	if selected_slot != null:
		var from_storage: Array

		if selected_storage == "inventory":
			from_storage = current_inventory
		elif selected_storage == "chest":
			if opened_chest == null:
				clear_all_selections()
				return

			from_storage = opened_chest.chest_inventory
		else:
			clear_all_selections()
			return

		if selected_storage == storage_name:
			swap_slots_in_storage(storage, selected_slot.slot_index, slot.slot_index)
		else:
			move_between_storages(from_storage, selected_slot.slot_index, storage, slot.slot_index)

		clear_all_selections()
		refresh_all()
		refresh_chest_ui()
		return

	if slot.slot_index < 0 or slot.slot_index >= storage.size():
		return

	if storage[slot.slot_index] == null:
		return

	clear_all_selections()
	selected_slot = slot
	selected_slot_index = slot.slot_index
	selected_storage = storage_name
	selected_slot.set_selected(true)
	
func _on_chest_slot_clicked(slot) -> void:
	if opened_chest == null:
		return

	handle_storage_click(slot, "chest", opened_chest.chest_inventory)

func _on_slot_clicked(slot) -> void:
	if opened_chest != null:
		handle_storage_click(slot, "inventory", current_inventory)
		return

	if selected_slot == slot:
		clear_all_selections()
		return

	if selected_slot != null:
		swap_slots(selected_slot.slot_index, slot.slot_index)
		clear_all_selections()
		return

	clear_all_selections()
	selected_slot = slot
	selected_slot_index = slot.slot_index
	selected_storage = "inventory"
	selected_slot.set_selected(true)


func clear_selection() -> void:
	if selected_slot != null:
		selected_slot.set_selected(false)
		selected_slot = null
		selected_slot_index = -1
		selected_storage = ""


func clear_all_selections() -> void:
	for ui in get_tree().get_nodes_in_group("inventory_ui"):
		for child in ui.grid.get_children():
			child.set_selected(false)

	if chest_grid != null:
		for child in chest_grid.get_children():
			child.set_selected(false)

	selected_slot = null
	selected_slot_index = -1
	selected_storage = ""
