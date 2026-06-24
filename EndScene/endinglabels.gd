extends Label

@onready var click: AudioStreamPlayer = $"../../../click"
@onready var scroll := $"../.."
@onready var sb = $"../../".get_v_scroll_bar()

@export_multiline var full_text := ""
@export var speed := 0.07

func scroll_to_bottom():
	scroll.call_deferred("set", "scroll_vertical", scroll.get_v_scroll_bar().max_value)

func _ready():
	text = ""
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sb.modulate.a = 0
	sb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	for c in full_text:
		scroll_to_bottom()
		text += c
		await get_tree().create_timer(speed).timeout
	click.stop()
	await get_tree().create_timer(1.0).timeout
	text=""
	full_text="THANK YOU FOR PLAYING \nCreated by:\nAgnieszka Mozol\nWeronika Skoworn\nJakub Grabowski"
	click.play()
	for c in full_text:
		scroll_to_bottom()
		text += c
		await get_tree().create_timer(speed).timeout
	click.stop()
		
