extends Control

var selected_slot = null
var MAX_SLOT = 18
const MAX_STACK = 3
var current_inventory: Array
@onready var grid: GridContainer = $Panel/GridContainer
var slot_scene = preload("res://Scenes/item_slot.tscn")

func _ready() -> void:
	visible = false

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("inventory"):
		visible = !visible
		if not visible:
			clear_selection()

func refresh(player_inventory: Array) -> void:
	current_inventory = player_inventory
	for child in grid.get_children():
		child.queue_free()
	for i in range(MAX_SLOT):
		var slot = slot_scene.instantiate()
		grid.add_child(slot)
		slot.slot_index = i
		if player_inventory[i] != null:
			slot.set_item(player_inventory[i])
		else:
			slot.clear_item()
		slot.slot_clicked.connect(_on_slot_clicked)


#  Zamiana slotów — wywoływana przez drag & drop

func swap_slots(from_index: int, to_index: int) -> void:
	if from_index == to_index:
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
			refresh(current_inventory)
			return

	# Zwykła zamiana
	current_inventory[from_index] = b
	current_inventory[to_index]   = a
	refresh(current_inventory)


#  Kliknięcie (stary system — zostaje jako backup)

func _on_slot_clicked(slot) -> void:
	var czy_dodanie_do_stacka = false

	if selected_slot == slot:
		slot.set_selected(false)
		selected_slot = null
		return

	if selected_slot != null:
		var a = selected_slot.slot_index
		var b = slot.slot_index

		if slot.item_data != null and selected_slot.item_data != null:
			if selected_slot.item_data["item_id"] == slot.item_data["item_id"]:
				if slot.item_data["amount"] < MAX_STACK:
					var ile_do_stacka = MAX_STACK - slot.item_data["amount"]
					current_inventory[a]["amount"] -= ile_do_stacka
					current_inventory[b]["amount"] += ile_do_stacka
					if current_inventory[a]["amount"] == 0:
						current_inventory[a] = null
					czy_dodanie_do_stacka = true

		if not czy_dodanie_do_stacka:
			var temp = current_inventory[a]
			current_inventory[a] = current_inventory[b]
			current_inventory[b] = temp

		refresh(current_inventory)
		selected_slot = null
		return

	selected_slot = slot
	selected_slot.set_selected(true)

func clear_selection() -> void:
	if selected_slot != null:
		selected_slot.set_selected(false)
		selected_slot = null
