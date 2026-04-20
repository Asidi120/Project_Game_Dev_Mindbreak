extends Node

@onready var player: Player = $".."

func _on_area_entered(area: Area2D) -> void:
	var enemy = area.get_parent()
	if enemy in player.already_hit:
		return

	if enemy.is_in_group("Enemies") and enemy.has_method("take_damage"):
		player.already_hit.append(enemy)
		print("taking dmg")
		enemy.take_damage(10)
