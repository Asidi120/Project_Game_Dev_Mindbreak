extends Button

@onready var player: Player = $"../../../BleakYellowGrass/level/Player"
@onready var death_panel: Control = $".."
var stamina_bar: TextureProgressBar
var hunger_bar: TextureProgressBar
var hp_bar: TextureProgressBar
var hp_label: Label
var playerbar

func _ready() -> void:
	playerbar = get_tree().get_first_node_in_group("PlayerBar")
	stamina_bar = playerbar.get_node_or_null("stamina_bar")
	hunger_bar = playerbar.get_node_or_null("hunger_bar")
	hp_bar = playerbar.get_node_or_null("hp_bar")
	hp_label = playerbar.get_node_or_null("hp_label")

func _on_pressed() -> void:
	player.current_hp=player.max_hp
	player.current_hunger=player.max_hunger
	player.current_stamina=player.max_stamina
	player.global_position = player.spawn_point
	hunger_bar.update_bar(player.current_hunger,player.max_hunger)
	stamina_bar.update_bar(player.current_stamina,player.max_stamina)
	hp_bar.update_bar(player.current_hp,player.max_hp)
	get_tree().paused=false
	death_panel.visible=false
