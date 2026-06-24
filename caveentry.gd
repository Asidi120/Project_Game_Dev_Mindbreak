extends Area2D

@export var cave_scene: String = "res://cave1.tscn"
@export var spawn_name: String = "SpawnPoint"

var player_inside: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	if player_inside and Input.is_action_just_pressed("interact"):
		var player := get_tree().get_first_node_in_group("player")
		if player:
			SceneTransition.travel(player, cave_scene, spawn_name)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_inside = true


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_inside = false
