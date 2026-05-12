extends Panel

signal slot_clicked(slot)

var item_data = null
var selected := false
var slot_index = -1

@onready var icon: TextureRect = $TextureRect
@onready var amount_label: Label = $Label

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

func set_item(data: Dictionary) -> void:
	item_data = data
	icon.texture = data["texture"]
	amount_label.text = str(data["amount"])
	icon.position = Vector2(7, 7)

func clear_item():
	item_data = null
	icon.texture = null
	amount_label.text = ""

func set_selected(value: bool) -> void:
	selected = value
	if selected:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.0, 0.0, 0.0, 0.235)
		style.border_color = Color.BLACK
		style.set_border_width_all(5)
		add_theme_stylebox_override("panel", style)
	else:
		var style_clear = StyleBoxEmpty.new()
		add_theme_stylebox_override("panel", style_clear)

# ─────────────────────────────────────────────
#  Drag & Drop
# ─────────────────────────────────────────────
func _get_drag_data(_at_position: Vector2):
	if item_data == null:
		return null

	# Podgląd podczas przeciągania
	var preview := TextureRect.new()
	preview.texture     = item_data["texture"]
	preview.custom_minimum_size = Vector2(32, 32)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	set_drag_preview(preview)

	return { "slot": self, "data": item_data }

func _can_drop_data(_at_position: Vector2, data) -> bool:
	return data is Dictionary and data.has("slot")

func _drop_data(_at_position: Vector2, data) -> void:
	var from_slot = data["slot"]
	if from_slot == self:
		return
	# Szukaj inventory w górę drzewa
	var inventory = get_tree().get_first_node_in_group("inventory")
	if inventory:
		inventory.swap_slots(from_slot.slot_index, slot_index)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			slot_clicked.emit(self)
