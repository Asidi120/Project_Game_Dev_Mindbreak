extends Area2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

var damage: int = 10
var player_in_attack_range=false
var target=null

func init(t):
	target = t
	adjust_position()
	spell_casting()

func _on_body_entered(body):
	if body.is_in_group("Players"):
		player_in_attack_range=true
		target=body

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Players"):
		player_in_attack_range=false

func spell_casting():
	animated_sprite_2d.play("default")
	await get_tree().create_timer(1).timeout
	if target and player_in_attack_range and target.has_method("take_damage"):
		target.take_damage(damage)
	await animated_sprite_2d.animation_finished
	queue_free()
	
func adjust_position():
	var prediction_time = 0.5
	if target.velocity.length() < 10:
		prediction_time = 0.0  # stoi → nie przewiduj
	global_position = target.global_position + target.velocity * prediction_time
