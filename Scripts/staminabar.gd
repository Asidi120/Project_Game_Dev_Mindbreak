extends TextureProgressBar

@onready var player = %Player
@onready var stamina_bar: TextureProgressBar = $CanvasLayer/stamina_bar

var target_stamina:float=0

func _ready():
	player.stamina_usage.connect(update_bar)
	update_bar(player.current_stamina, player.max_stamina)
	value=player.current_stamina
	target_stamina=player.current_stamina
	#hp_label.text=str(int(target_stamina))+"/"+str(int(player.max_hp))

func update_bar(current_stamina, max_stamina):
	target_stamina = current_stamina  # ustawiamy cel zamiast ustawiać od razu ilosc hp
	#stamina_bar.text=str(int(target_stamina))+"/"+str(int(max_stamina))

func _process(delta):
	# płynne przejście hp w pasku do target_hp
	value = lerp(value, target_stamina, 16*delta)
	if abs(value - target_stamina) < 0.5:
		value = target_stamina
