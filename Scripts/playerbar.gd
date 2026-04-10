extends Node

@onready var stamina_bar: TextureProgressBar = $stamina_bar
@onready var hunger_bar: TextureProgressBar = $hunger_bar
@onready var hp_bar: TextureProgressBar = $hp_bar
@onready var hp_label: Label = $hp_label

func reset():
	hunger_bar.update_bar(hunger_bar.current_hunger,hunger_bar.max_hunger)
	stamina_bar.update_bar(stamina_bar.current_stamina,stamina_bar.max_stamina)
	hp_bar.update_bar(hp_bar.current_hp,hp_bar.max_hp)
	
