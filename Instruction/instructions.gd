extends ScrollContainer

@onready var history: ScrollContainer = $"../History"
@onready var click: AudioStreamPlayer = $"../click"
@onready var label: Label = $VBoxContainer/Label
@onready var color_rect: ColorRect = $"../ColorRect"
@onready var instruction: Control = $".."

var is_open := false

func _input(event):
	if event.is_action_pressed("Instruction"):
		_toggle_instructions()
		SceneTransition.history_played=true

func _toggle_instructions():
	print("TOGGLE CALLED")
	is_open = !is_open
	visible = is_open
	instruction.visible= is_open
	instruction.mouse_filter= Control.MOUSE_FILTER_STOP if is_open else Control.MOUSE_FILTER_IGNORE
	print("Mouse filter: ",mouse_filter)
	color_rect.visible=is_open
	get_tree().paused=is_open
	if history:
		history.queue_free()
	print("visible:", visible)
	click.stop()
