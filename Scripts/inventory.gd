extends Control

@onready var grid: GridContainer = $Panel/GridContainer
var slot_scene = preload("res://Scenes/item_slot.tscn") #sciezka do item slot
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void: #pojawianie się ewkipunku na E
	if Input.is_action_just_pressed("inventory"):
		visible = !visible

func refresh(inventory: Dictionary) -> void: #odświeżanie ekwipunka
	for child in grid.get_children():
		child.queue_free()

	for item_id in inventory.keys():
		var item_data = inventory[item_id]

		var slot = slot_scene.instantiate()
		grid.add_child(slot)

		slot.set_item(item_data["texture"], item_data["amount"])
