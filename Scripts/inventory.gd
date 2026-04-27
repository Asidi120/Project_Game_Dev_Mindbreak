extends Control

var selected_slot = null

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
	for child in grid.get_children():
		child.queue_free()

	for item_data in player_inventory:
		var slot = slot_scene.instantiate()
		grid.add_child(slot)
		slot.set_item(item_data)
		slot.slot_clicked.connect(_on_slot_clicked)

func _on_slot_clicked(slot):
	#var change := false
	if selected_slot == slot: #jeśli ten sam to odznaczamy
		slot.set_selected(false)
		selected_slot = null
	else:
		if selected_slot != null: #jeśli inny to go odznacz
			selected_slot.set_selected(false)
			var previous_slot = selected_slot.item_data
			selected_slot.set_item(slot.item_data)
			slot.set_item(previous_slot)
		
		selected_slot = slot #zaznaczamy nowy
		selected_slot.set_selected(true)
		
func clear_selection():
	if selected_slot != null:
		selected_slot.set_selected(false)
		selected_slot = null
