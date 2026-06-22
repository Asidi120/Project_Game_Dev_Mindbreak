extends Item
class_name Sword

@export var power := 1.0
var item_durability := 100

func collect():
	var item = super.collect()
	item["power"] = power
	item["item_durability"] = item_durability
	return item
	
