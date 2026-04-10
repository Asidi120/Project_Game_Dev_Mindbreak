extends Node

@onready var revive_button: Button = $ReviveButton
@onready var come_back_menu_button: Button = $ComeBackMenuButton
@onready var quit_button: Button = $QuitButton

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	_on_visibility_changed()

func _on_visibility_changed() -> void:
	#get_tree().paused = true
	pass
