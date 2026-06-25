extends Item
class_name Food

@export var hunger_points := 10

#napidanie collect z item by dodac hunger_points
func collect():
	var item = super.collect()

	item["hunger_points"] = hunger_points
	
	return item
	
