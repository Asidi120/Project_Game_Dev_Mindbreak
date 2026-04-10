extends Button

@onready var player: Player = $"../../../BleakYellowGrass/level/Player"
@onready var death_panel: Control = $".."

func _process(delta: float) -> void:
	pass

func _on_pressed() -> void:
	player.current_hp=player.max_hp
	player.current_hunger=player.max_hunger
	player.current_stamina=player.max_stamina
	player.global_position = player.spawn_point
	get_tree().paused=false
	death_panel.visible=false
