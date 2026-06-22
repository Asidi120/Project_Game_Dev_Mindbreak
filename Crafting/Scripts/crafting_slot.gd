extends TextureRect
class_name CraftingSlot

signal craft_pressed(recipe)

@onready var ingredient_1_icon: TextureRect = $Ingredient1/Icon
@onready var ingredient_1_amount: Label = $Ingredient1/AmountLabel

@onready var ingredient_2_icon: TextureRect = $Ingredient2/Icon
@onready var ingredient_2_amount: Label = $Ingredient2/AmountLabel

@onready var result_icon: TextureRect = $Result/Icon

var recipe: Dictionary = {}
var can_make := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

	# żeby dzieci nie blokowały kliknięcia w cały panel
	$Ingredient1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Ingredient1/Icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Ingredient1/AmountLabel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	$Ingredient2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Ingredient2/Icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Ingredient2/AmountLabel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	$Result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Result/Icon.mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_recipe(new_recipe: Dictionary, new_can_make: bool) -> void:
	recipe = new_recipe
	can_make = new_can_make

	var requirements = recipe["requirements"]

	ingredient_1_icon.texture = requirements[0]["texture"]
	ingredient_1_amount.text = "x" + str(requirements[0]["needed_amount"])

	ingredient_2_icon.texture = requirements[1]["texture"]
	ingredient_2_amount.text = "x" + str(requirements[1]["needed_amount"])

	result_icon.texture = recipe["result_texture"]

	if can_make:
		modulate = Color(1, 1, 1)
	else:
		modulate = Color(0.521, 0.521, 0.521, 1.0)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if can_make:
				craft_pressed.emit(recipe)
			else:
				print("Brakuje składników")
