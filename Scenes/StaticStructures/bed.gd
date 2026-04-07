extends Node2D

@onready var day_counter: Label = $"../CanvasLayer/day_counter"
@onready var day_night_overlay: CanvasModulate = $"../DayNightOverlay"

var can_sleep:=false
var target_color=Color(1,1,1,1)
var sleeping = false
var sleep_timer = 0.0 

func _process(delta: float) -> void:
	if can_sleep and (day_counter.hours>=22 or day_counter.hours<6) and Input.is_action_just_pressed("action (open door, sleep etc.)"):
		sleeping=true
		sleep_timer = 0.0
	if sleeping:
		sleeping_in_action(delta)

func sleeping_in_action(delta):
	# fade do czerni
	var target = Color(0, 0, 0, 1)
	day_night_overlay.color = day_night_overlay.color.lerp(target, 3 * delta)
	
	# licznik czasu
	sleep_timer += delta
	
	# po 2 sekundach
	if sleep_timer >= 1.0:
		day_counter.skip_to_morning()
		sleeping = false


func _on_sleeping_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("Players"):
		can_sleep=false

func _on_sleeping_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Players"):
		can_sleep=true
