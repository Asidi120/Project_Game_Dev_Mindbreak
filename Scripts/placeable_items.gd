extends Item
class_name PlaceableItem

@export var place_scene_path := ""

func collect():
	var item = super.collect()
	item["place_scene_path"] = place_scene_path
	return item
