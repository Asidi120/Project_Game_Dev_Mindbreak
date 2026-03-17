extends Node2D
class_name EvilWolf

var player_in_area: bool = false
var attack_cooldown: float = 1.0
var can_attack: bool = true

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	print("Wolf is here")
	
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Players"):
		player_in_area = true
		try_attack()

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("Players"):
		player_in_area = false

func try_attack() -> void:
	if player_in_area and can_attack:
		can_attack = false
		animated_sprite_2d.play("attack")
		print("Attack!")
		
		await get_tree().create_timer(attack_cooldown).timeout
		can_attack = true

		if player_in_area:
			try_attack()

func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite_2d.animation == "attack":
		animated_sprite_2d.play("idle")
