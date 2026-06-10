extends Control

static var selected_slot = null

const MAX_SLOT = 18
const INVENTORY_SLOTS = 18
const FASTEQ_SLOTS = 6
const MAX_STACK = 3

static var current_inventory: Array = []
static var inventory_visible = false

@onready var grid: GridContainer = $Panel/GridContainer
@onready var background: TextureRect = $Panel

var slot_scene = preload("res://Scenes/item_slot.tscn")

var slot_offset := 0
static var selected_fasteq_index := 0
static var selected_slot_index := -1


func _ready() -> void:
	if self.name == "Inventory":
		visible = false

	if self.name == "FastEq":
		visible = true
		update_fasteq_selection()


func _process(_delta: float) -> void:
	if self.name == "Inventory":
		if Input.is_action_just_pressed("inventory"):
			toggle_inventory()
			
	if self.name == "FastEq":
		handle_fasteq_scroll()

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


func _on_slot_clicked(slot) -> void:
	if selected_slot == slot:
		clear_all_selections()
		return

	if selected_slot != null:
		swap_slots(selected_slot.slot_index, slot.slot_index)
		clear_all_selections()
		return

	clear_all_selections()
	selected_slot = slot
	selected_slot_index = slot.slot_index #ustawienie indeksu wybranego slota
	selected_slot.set_selected(true)


func clear_selection() -> void:
	if selected_slot != null:
		selected_slot.set_selected(false)
		selected_slot = null
		selected_slot_index = -1


func clear_all_selections() -> void:
	for ui in get_tree().get_nodes_in_group("inventory_ui"):
		for child in ui.grid.get_children():
			child.set_selected(false)

	selected_slot = null
	selected_slot_index = -1
