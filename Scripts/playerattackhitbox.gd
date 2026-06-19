extends Node

@onready var player: Player = $".."

func dealt_damage():
	var damage = 10
	if player.inventory_system == null:
		return damage
	
	var index = player.inventory_system.selected_fasteq_index
	var inventory = player.inventory_system.current_inventory
	
	if index < 0 or index >= inventory.size():
		return damage
	
	var item = inventory[index]
	
	if item == null:
		return damage
	
	if item.has("power"):
		damage += item["power"]
		
	return damage
		
func _on_area_entered(area: Area2D) -> void:
	var damage = dealt_damage()
	var enemy = area.get_parent()
	if enemy in player.already_hit:
		return

	if enemy.is_in_group("Enemies") and enemy.has_method("take_damage"):
		player.already_hit.append(enemy)
		print("taking dmg", damage)
		enemy.take_damage(damage) #tuuuuuuuuuuuu
