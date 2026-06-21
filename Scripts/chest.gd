extends StaticBody2D
class_name Chest

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

@export var chest_size := 18

var chest_inventory: Array = []

var chest_in_range = null
var is_open := false

var player_in_range = null

@onready var area_2d: Area2D = $Area2D

func _ready() -> void:
	chest_inventory.resize(chest_size)
	chest_inventory.fill(null)
	
	area_2d.body_entered.connect(_on_area_2d_body_entered)
	area_2d.body_exited.connect(_on_area_2d_body_exited)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if chest_in_range and Input.is_action_just_pressed("open_chest"):
		if not is_open:
			open_chest()
		else:
			close_chest()

func open_chest():
	print("skrzynka otwarta")
	is_open = true
	animated_sprite.play("open_chest")
	
	if player_in_range != null:
		player_in_range.state = player_in_range.State.STUNNED
	
	var inventory_ui = get_inventory_ui()
	if inventory_ui != null:
		inventory_ui.open_chest_ui(self)

func close_chest():
	print("skrzynka zamknieta")
	is_open = false
	animated_sprite.play("close_chest")
	
	if player_in_range != null:
		player_in_range.state = player_in_range.State.IDLE
		
	var inventory_ui = get_inventory_ui()
	if inventory_ui != null:
		inventory_ui.close_chest_ui()
	
func get_inventory_ui():
	for ui in get_tree().get_nodes_in_group("inventory_ui"):
		if ui.name == "Inventory":
			return ui

	return null
			
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		chest_in_range = self
		player_in_range = body


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		chest_in_range = null
		player_in_range = null
