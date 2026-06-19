extends Item
class_name Sword

@export var power := 1.0

func collect():
	var item = super.collect()
	item["power"] = power
	return item
	
