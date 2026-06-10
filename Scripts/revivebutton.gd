extends Button

var player: Player
var death_panel: Control
var stamina_bar: TextureProgressBar
var hunger_bar: TextureProgressBar
var hp_bar: TextureProgressBar
var hp_label: Label
var playerbar

func _ready() -> void:
	await get_tree().process_frame
	player      = get_tree().get_first_node_in_group("player")
	death_panel = get_parent()
	playerbar   = get_tree().get_first_node_in_group("PlayerBar")
	if playerbar:
		stamina_bar = playerbar.get_node_or_null("stamina_bar")
		hunger_bar  = playerbar.get_node_or_null("hunger_bar")
		hp_bar      = playerbar.get_node_or_null("hp_bar")
		hp_label    = playerbar.get_node_or_null("hp_label")

func _on_pressed() -> void:
	if not player:
		return
	player.state=player.State.IDLE
	player.current_hp      = player.max_hp
	player.current_hunger  = player.max_hunger
	player.current_stamina = player.max_stamina
	player.global_position = player.spawn_point
	player.state           = player.State.IDLE
	if hunger_bar:  hunger_bar.update_bar(player.current_hunger, player.max_hunger)
	if stamina_bar: stamina_bar.update_bar(player.current_stamina, player.max_stamina)
	if hp_bar:      hp_bar.update_bar(player.max_hp, player.max_hp)
	get_tree().paused   = false
	death_panel.visible = false
