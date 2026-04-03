extends StaticBody2D
var player_in_range := false
var hits_needed := 4
var hits := 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if player_in_range and Input.is_action_just_pressed("attack"): #jesli player w zasiegu i uderzy
		hits += 1
		print("Uderzenie: ", hits)

		if hits >= hits_needed: #jesli player przekroczy ilosc uderzen
			print("drzewo zniszczone")
			queue_free()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_in_range = true #player w drzewie


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_in_range = false #player poza drzewem
