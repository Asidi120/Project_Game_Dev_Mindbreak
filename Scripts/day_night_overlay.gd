extends CanvasModulate

@onready var day_counter: Label = $"../CanvasLayer/day_counter"

var target_color = Color(1, 1, 1)  # day deafault
	
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
