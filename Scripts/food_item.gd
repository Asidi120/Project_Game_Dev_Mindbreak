extends Item
class_name FoodItem
@export var health_amount = 20

func eat(current_hunger):
	current_hunger += health_amount
	
