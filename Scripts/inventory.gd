extends Control

var selected_slot = null
var MAX_SLOT = 18
const MAX_STACK = 3 #maksymalna ilość w stacku

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
	#branie rzeczy z ekwipunka
	if Input.is_action_just_pressed("pick_up"):
		pick_from_inventory()


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

func _on_slot_clicked(slot):
	var czy_dodanie_do_stacka = false
	if selected_slot == slot: #jeśli ten sam to odznaczamy
		slot.set_selected(false)
		selected_slot = null
		return

	if selected_slot != null:
		var a = selected_slot.slot_index
		var b = slot.slot_index

		var temp = current_inventory[a]
		
		#ręczne dodawanie do stacka jeśli jest miejsce 
		if slot.item_data != null and selected_slot.item_data != null:
			if selected_slot.item_data["item_id"] == slot.item_data["item_id"]:
				if slot.item_data["amount"] < MAX_STACK:
					var ile_do_stacka = MAX_STACK - slot.item_data["amount"]
					current_inventory[a]["amount"] -= ile_do_stacka
					current_inventory[b]["amount"] += ile_do_stacka
					
					if current_inventory[a]["amount"] == 0:
						current_inventory[a] = null
						print("esfesfse")
					czy_dodanie_do_stacka = true
		if not czy_dodanie_do_stacka:
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
		
func drop_item(slot):
	var item_data = slot.item_data
	var item_id = item_data["item_id"]
	
	print("DROP item_id: ", item_id)

	var scene = load("res://Scenes/Items/" + item_id + ".tscn")
	

	if scene == null:
		print("Brak sceny dla itemu: ", item_id)
		return

	var item_instance = scene.instantiate()
	get_tree().current_scene.add_child(item_instance)
	item_instance.global_position = Vector2(10, 10)
	
func pick_from_inventory():
	if selected_slot != null and selected_slot.item_data != null:
			print("wybrano item")
			drop_item(selected_slot)
