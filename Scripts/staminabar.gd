extends TextureProgressBar

var player: Player
var target_stamina: float = 0

func _ready():
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	if player:
		player.stamina_usage.connect(update_bar)
		update_bar(player.current_stamina, player.max_stamina)
		value = player.current_stamina
		target_stamina = player.current_stamina

func update_bar(current_stamina, max_stamina):
	target_stamina = current_stamina

func _process(delta):
	value = lerp(value, target_stamina, 16 * delta)
	if abs(value - target_stamina) < 0.5:
		value = target_stamina
