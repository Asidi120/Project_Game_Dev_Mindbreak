extends CanvasModulate

var clock
var day_counter

var target_color = Color(1, 1, 1)  # day deafault
func _ready() -> void:
	clock = get_tree().get_first_node_in_group("Clock")
	day_counter = clock.get_node_or_null("day_counter")

func _process(delta: float) -> void:
	if day_counter.hours >= 20 and day_counter.hours < 22:
		target_color = Color(0.901, 0.622, 0.443, 1.0)  # dusk 
	elif day_counter.hours >= 22 or day_counter.hours < 6:
		target_color = Color(0.2, 0.2, 0.4)  # night
	elif day_counter.hours >= 6 and day_counter.hours < 8:
		target_color = Color(0.901, 0.622, 0.443, 1.0)  # dawn
	else:
		target_color = Color(1, 1, 1)        # day
	color = color.lerp(target_color, 0.5 * delta)
