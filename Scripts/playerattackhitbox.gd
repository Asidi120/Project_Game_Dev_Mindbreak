extends Node

@onready var player: Player = $".."

# wartosc zadawaego damage wrogom
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
	
func update_durability():
	if player.inventory_system == null:
		return 
	
	var index = player.inventory_system.selected_fasteq_index
	var inventory = player.inventory_system.current_inventory
	
	if index < 0 or index >= inventory.size():
		return 
	
	var item = inventory[index]
	
	if item == null:
		return 

		#tutaj update durability miecza
	if item["item_type"] == "sword":	
		item["item_durability"] -= 1
		print(item["item_durability"])
		
		#usuwanie przedmiotu jesli durability ponizej zera
		if item["item_durability"] <= 0:
			inventory[index] = null
			player.inventory_system.refresh_all()
			return
		
	return 
		
func _on_area_entered(area: Area2D) -> void:
	var damage = dealt_damage()
	var enemy = area.get_parent()
	if enemy in player.already_hit:
		return

	if enemy.is_in_group("Enemies") and enemy.has_method("take_damage"):
		player.already_hit.append(enemy)
		update_durability()
		print("taking dmg", damage)
		enemy.take_damage(damage) 
