extends Panel

signal slot_clicked(slot)

var item_data = null
var selected := false
@onready var icon: TextureRect = $TextureRect
@onready var amount_label: Label = $Label
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func set_item(data: Dictionary) -> void: #ustawia teksturke i ilosc (label)
	item_data = data
	icon.texture = data["texture"]
	amount_label.text = str(data["amount"])
	icon.position = Vector2(7, 7)
	
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			slot_clicked.emit(self)

func set_selected(value: bool) -> void:
	selected = value

	if selected: #rysowanie obramowania
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.0, 0.0, 0.0, 0.235)
		style.border_color = Color.BLACK
		style.set_border_width_all(5)
		add_theme_stylebox_override("panel", style)
	else:
		var style_clear = StyleBoxEmpty.new()
		add_theme_stylebox_override("panel", style_clear)
