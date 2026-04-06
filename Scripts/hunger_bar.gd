extends TextureProgressBar

@onready var player = %Player

var target_hunger: float = 0

func _ready():
	player.hunger_changed.connect(update_bar)
	update_bar(player.current_hunger, player.max_hunger)
	value = player.current_hunger
	target_hunger = player.current_hunger

func update_bar(current_hunger, max_hunger):
	max_value = max_hunger
	target_hunger = current_hunger

func _process(delta):
	value = lerp(value, target_hunger, 8 * delta)
	if abs(value - target_hunger) < 0.5:
		value = target_hunger
