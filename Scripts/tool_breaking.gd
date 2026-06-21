extends Item
class_name Tool

@export var tool_power := 1.0
@export var position_of_power := 0

func collect():
	var item = super.collect()
	item["tool_power"] = tool_power
	item["position_of_power"] = position_of_power
	return item
	
