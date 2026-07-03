extends ScrollContainer

@onready var history: ScrollContainer = $"../History"
@onready var click: AudioStreamPlayer = $"../click"
@onready var label: Label = $VBoxContainer/Label
@onready var color_rect: ColorRect = $"../ColorRect"

var is_open := false

func _input(event):
	if event.is_action_pressed("Instruction"):
		_toggle_instructions()

func _toggle_instructions():
	print("TOGGLE CALLED")
	is_open = !is_open
	visible = is_open
	color_rect.visible=is_open
	get_tree().paused=is_open
	if history:
		history.queue_free()
	print("visible:", visible)
	click.stop()
