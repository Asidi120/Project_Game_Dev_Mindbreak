extends StaticBody2D


@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
var chest_in_range = null
var is_open := false

func _ready() -> void:
	pass # Replace with function body.


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

func close_chest():
	print("skrzynka zamknieta")
	is_open = false
	animated_sprite.play("close_chest")
			
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		chest_in_range = self


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		chest_in_range = null
