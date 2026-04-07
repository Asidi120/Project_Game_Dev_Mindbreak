extends Node2D

@onready var day_counter: Label = $"../CanvasLayer/day_counter"
@onready var day_night_overlay: CanvasModulate = $"../DayNightOverlay"
@onready var click_e_to_sleep: Label = $ClickEToSleep
@onready var cant_sleep_label: Label = $CantSleepLabel

var can_sleep:=false
var target_color=Color(1,1,1,1)
var sleeping = false
var sleep_timer = 0.0 
var label_timer=1.5
var showing_label = false

func _process(delta: float) -> void:
	if can_sleep:
		if (day_counter.hours>=22 or day_counter.hours<6):
			if Input.is_action_just_pressed("action (open door, sleep etc.)"):
				sleeping = true
				sleep_timer = 0.0
		else:
			if Input.is_action_just_pressed("action (open door, sleep etc.)") and not showing_label:
				show_cant_sleep()
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

func show_cant_sleep(): #showing label that you cant sleep with animation and fading
	showing_label = true
	cant_sleep_label.visible = true
	cant_sleep_label.modulate.a = 1.0
	
	var start_pos = cant_sleep_label.position
	var duration = 1.0
	var t = 0.0
	
	while t < duration:
		await get_tree().process_frame
		t += get_process_delta_time()
		# 
		cant_sleep_label.position.y = start_pos.y - 30 * (t / duration)
		# fading
		cant_sleep_label.modulate.a = 1.0 - (t / duration)
	# reset
	cant_sleep_label.visible = false
	cant_sleep_label.position = start_pos
	showing_label = false

func _on_sleeping_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("Players"):
		can_sleep=false

func _on_sleeping_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Players"):
		can_sleep=true

func _on_showing_click_label_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Players"):
		click_e_to_sleep.visible=true

func _on_showing_click_label_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("Players"):
		click_e_to_sleep.visible=false
