extends TextureProgressBar

@onready var player = %Player
@onready var hp_label: Label = $"../hp_label"

var target_hp:float=0

func _ready():
	player.hp_changed.connect(update_bar)
	update_bar(player.current_hp, player.max_hp)
	value=player.current_hp
	target_hp=player.current_hp
	hp_label.text=str(int(target_hp))+"/"+str(int(player.max_hp))

func update_bar(current_hp, max_hp):
	max_value = max_hp
	target_hp = current_hp  # ustawiamy cel zamiast ustawiać od razu ilosc hp
	hp_label.text=str(int(target_hp))+"/"+str(int(max_hp))

func _process(delta):
	# płynne przejście hp w pasku do target_hp
	value = lerp(value, target_hp, 16*delta)
	if abs(value - target_hp) < 0.5:
		value = target_hp
