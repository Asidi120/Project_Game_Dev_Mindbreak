extends Item
class_name Tool

@export var tool_power := 1.0
@export var position_of_power := 0
var item_durability := 100

func collect():
	var item = super.collect()
	item["tool_power"] = tool_power
	item["position_of_power"] = position_of_power
	item["item_durability"] = item_durability
	return item
	
