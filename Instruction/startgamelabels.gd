extends Label

@onready var click: AudioStreamPlayer = $"../../../click"
@onready var scroll: ScrollContainer = $"../.."
@onready var sb: VScrollBar = scroll.get_v_scroll_bar()

@export_multiline var full_text := ""
@export var speed := 0.05

func _ready():
	text = ""
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	sb.modulate.a = 0
	sb.mouse_filter = Control.MOUSE_FILTER_IGNORE

	click.play()

	await _type_text()

	click.stop()


func _type_text() -> void:
	for c in full_text:
		text += c

		_scroll_to_bottom()

		await get_tree().create_timer(speed).timeout


func _scroll_to_bottom():
	scroll.call_deferred("set", "scroll_vertical", sb.max_value)
