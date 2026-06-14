extends Item
class_name Tool

@export var tool_power := 1.0

func collect():
	var item = super.collect()
	item["tool_power"] = tool_power

	return item
	
