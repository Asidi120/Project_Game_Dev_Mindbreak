extends Control

var selected_slot = null
var MAX_SLOT = 18

var current_inventory: Array

@onready var grid: GridContainer = $Panel/GridContainer
var slot_scene = preload("res://Scenes/item_slot.tscn") #sciezka do item slot
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void: #pojawianie się ewkipunku na E
	if Input.is_action_just_pressed("inventory"):
		visible = !visible
		if not visible:
			clear_selection() #zaznaczenie odklikuje sie po wyłączeniu ekwipunka


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

#func _on_slot_clicked(slot, player_inventory: Array):
	##var change := false
	##if selected_slot.item_data != null:
	#
		#if selected_slot == slot: #jeśli ten sam to odznaczamy
			#slot.set_selected(false)
			#selected_slot = null
		#else:
			#if selected_slot != null: #jeśli inny to go odznacz
				#selected_slot.set_selected(false)
				#
				##zamiana przedmiotów
				#if slot.item_data == null:
					#var previous_slot = selected_slot.item_data
					#selected_slot.clear_item() 
					#slot.set_item(previous_slot)
				#
				#else:
					#var previous_slot = selected_slot.item_data
					#selected_slot.set_item(slot.item_data)
					#slot.set_item(previous_slot)
			#
			#selected_slot = slot #zaznaczamy nowy
			#selected_slot.set_selected(true)
func _on_slot_clicked(slot):
	if selected_slot == slot: #jeśli ten sam to odznaczamy
		slot.set_selected(false)
		selected_slot = null
		return

	if selected_slot != null:
		var a = selected_slot.slot_index
		var b = slot.slot_index

		var temp = current_inventory[a]
		current_inventory[a] = current_inventory[b]
		current_inventory[b] = temp

		refresh(current_inventory)
		selected_slot = null
		return

	selected_slot = slot
	selected_slot.set_selected(true)
		
func clear_selection():
	if selected_slot != null:
		selected_slot.set_selected(false)
		selected_slot = null
