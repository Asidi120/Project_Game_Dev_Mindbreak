extends Control

static var selected_slot = null
var MAX_SLOT = 24
const MAX_STACK = 3
var current_inventory: Array
@onready var grid: GridContainer = $Panel/GridContainer
var slot_scene = preload("res://Scenes/item_slot.tscn")

var slot_offset := 0
var linked_ui = []

func _ready() -> void:
	if self.name == "Inventory":
		visible = false
	await get_tree().process_frame
	linked_ui = get_tree().get_nodes_in_group("inventory_ui") #połączone fast eq i inventory

func _process(_delta: float) -> void:
	if self.name == "Inventory":
		if Input.is_action_just_pressed("inventory"):
			visible = !visible
			if not visible:
				clear_selection()
				
func refresh_all() -> void:
	for ui in get_tree().get_nodes_in_group("inventory_ui"):
		ui.refresh(current_inventory)
		
func refresh(player_inventory: Array) -> void:
	if self.name == "Inventory":
		MAX_SLOT = 18
		slot_offset = 6

	if self.name == "FastEq":
		MAX_SLOT = 6
		slot_offset = 0

	current_inventory = player_inventory

	for child in grid.get_children():
		child.queue_free()

	for i in range(MAX_SLOT):
		var slot = slot_scene.instantiate()
		grid.add_child(slot)

		var real_index = i + slot_offset
		slot.slot_index = real_index

		if real_index < player_inventory.size() and player_inventory[real_index] != null:
			slot.set_item(player_inventory[real_index])
		else:
			slot.clear_item()

		slot.slot_clicked.connect(_on_slot_clicked)


#  Zamiana slotów — wywoływana przez drag & drop

func swap_slots(from_index: int, to_index: int) -> void:
	if from_index == to_index:
		return
	
	if from_index < 0 or from_index >= current_inventory.size():
		return

	if to_index < 0 or to_index >= current_inventory.size():
		return

	var a = current_inventory[from_index]
	var b = current_inventory[to_index]

	# Spróbuj połączyć stacki jeśli ten sam item
	if a != null and b != null and a["item_id"] == b["item_id"]:
		var space = MAX_STACK - b["amount"]
		if space > 0:
			var transfer = min(space, a["amount"])
			current_inventory[to_index]["amount"]   += transfer
			current_inventory[from_index]["amount"] -= transfer
			if current_inventory[from_index]["amount"] <= 0:
				current_inventory[from_index] = null
			refresh_all()
			return

	# Zwykła zamiana
	current_inventory[from_index] = b
	current_inventory[to_index]   = a
	refresh_all()


#  Kliknięcie (stary system — zostaje jako backup)

func _on_slot_clicked(slot) -> void:
	if selected_slot == slot:
		slot.set_selected(false)
		selected_slot = null
		return

	if selected_slot != null:
		var a = selected_slot.slot_index
		var b = slot.slot_index

		if a < 0 or a >= current_inventory.size():
			selected_slot = null
			return

		if b < 0 or b >= current_inventory.size():
			selected_slot = null
			return

		var item_a = current_inventory[a]
		var item_b = current_inventory[b]

		# stackowanie
		if item_a != null and item_b != null and item_a["item_id"] == item_b["item_id"]:
			var space = MAX_STACK - item_b["amount"]

			if space > 0:
				var transfer = min(space, item_a["amount"])

				current_inventory[b]["amount"] += transfer
				current_inventory[a]["amount"] -= transfer

				if current_inventory[a]["amount"] <= 0:
					current_inventory[a] = null
			else:
				current_inventory[a] = item_b
				current_inventory[b] = item_a
		else:
			# zwykła zamiana
			current_inventory[a] = item_b
			current_inventory[b] = item_a

		selected_slot.set_selected(false)
		selected_slot = null
		refresh_all()
		return

	selected_slot = slot
	selected_slot.set_selected(true)

func clear_selection() -> void:
	if selected_slot != null:
		selected_slot.set_selected(false)
		selected_slot = null

func clear_all_selections() -> void:
	for ui in get_tree().get_nodes_in_group("inventory_ui"):
		for child in ui.grid.get_children():
			child.set_selected(false)

	selected_slot = null
