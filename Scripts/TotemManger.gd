extends Node

func _ready():
	spawn_totem()

func spawn_totem():
	if BossManager.current_totem == null:
		return

	var totem = BossManager.current_totem.instantiate()
	add_child(totem)
	print("totem sie zespawnil",totem)
	totem.global_position = Vector2(0,-142) # pozycja totemu
