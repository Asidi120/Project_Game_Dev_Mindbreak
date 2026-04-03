extends StaticBody2D
var player_in_range = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if player_in_range and Input.is_action_just_pressed("pick_up"):
		queue_free() #drewno znika po wejściu w niego
		print("+1 drewna")


func _on_area_2d_body_entered(body: Node2D) -> void:
	player_in_range = true
	


func _on_area_2d_body_shape_exited(body_rid: RID, body: Node2D, body_shape_index: int, local_shape_index: int) -> void:
	player_in_range = false
