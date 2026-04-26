extends Panel

@onready var icon: TextureRect = $TextureRect
@onready var amount_label: Label = $Label
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func set_item(texture: Texture2D, amount: int) -> void: #ustawia teksturke i ilosc (label)
	icon.texture = texture
	amount_label.text = str(amount)
