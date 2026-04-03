extends Area2D
var player_in_range := false

@export var item_id := ""
@export var item_name := ""


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(_on_body_entered) #automatycznie dla każdego itema będzie wykrywać bez konieczności podpinania
	body_exited.connect(_on_body_exited)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if player_in_range and Input.is_action_just_pressed("pick_up"): #jesli player w zasiegu i nacisniete F item zostaje zebrany
		queue_free() #item znika po wejściu w niego
		print("+1 ", item_name)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_in_range = true

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_in_range = false
