extends Item
class_name Food

@export var hunger_points := 10

#napidanie collect z item by dodac hunger_points
func collect():
	var item = super.collect()

	item["hunger_points"] = hunger_points

	return item
	
#func eat(current_hunger, max_hunger):
	#if hunger_points <= max_hunger:
		#if current_hunger == max_hunger:
			#print("Nie można zjeść. Jesteś najedzony!")
		#elif hunger_points + current_hunger >= max_hunger:
			#print("Najadłeś się")
		#else:
			#print("Zjadłeś")
