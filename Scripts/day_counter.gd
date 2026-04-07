extends Label

@onready var clock: TextureRect = $"../clock"
@onready var clock_overlay: TextureRect = $"../clock_overlay"

var time := 720.0  # time in game (seconds) first day starts at 12 pm
var target_alpha := 0.0 #alpha clock overlay
var hours:int=0
var minutes:int= 0
var days:int=0

func _process(delta):
	time_passage(delta)
	clock_texture_update(delta)
	
func time_passage(delta):
	time += 10*delta  # acceleration of time (1 second = 10 minutes in game)
	hours = int(time / 60) % 24
	minutes = int(time) % 60
	days=time/1440
	
func skip_to_morning():
	var target_time = 6 * 60 # 6:00 morning = 360 minutes
	var current_time = int(time) % 1440
	
	var diff = target_time - current_time
	
	if diff <= 0:
		diff += 1440  # next day
		
	time += diff

func clock_texture_update(delta): #update of clock texture and smoth update between night clock and day clock
	if hours==3 or hours == 15:
		clock.texture=preload("uid://33yuyr2hx8wk")
	elif hours==6 or hours == 18:
		clock.texture=preload("uid://bkbxawns7uy0j")
	elif hours==9 or hours == 21:
		clock.texture=preload("uid://blo5nejsuhou2")
	elif hours==0 or hours == 12:
		clock.texture=preload("uid://c1w1adrgxc7pf")
	var is_night = hours >= 22 or hours < 6
	if is_night:
		target_alpha = 0.6  # how dark it should be
	else:
		target_alpha = 0.0 # clock is getting lighter
	var current_alpha = clock_overlay.modulate.a
	clock_overlay.modulate.a = lerp(current_alpha, target_alpha, 3 * delta)
	
	#label under clock
	text = "Day "+"%d"%days+"\n%02d:%02d"%[hours,minutes] #days spent in the game
