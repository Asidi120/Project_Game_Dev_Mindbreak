class_name Player extends CharacterBody2D

signal hp_changed(current_hp, max_hp)
signal stamina_usage(current_stamina, max_stamina)

var move_speed = 100
var direction = Vector2.ZERO
var items_in_range = [] #przechowuje itemy w zasięgu gracza
var current_hp = 200 # aktualne hp gracza
var max_hp = 200 
var max_stamina=100
var current_stamina=100

@onready var anim = $AnimationPlayer
@onready var sprite = $Sprite2D

func _physics_process(delta):
	get_input()
	move_player(delta)
	update_animation()

func take_damage(amount):
	current_hp -= amount
	current_hp = clamp(current_hp, 0, max_hp)
	emit_signal("hp_changed", current_hp, max_hp)
	if current_hp<=0:
		die()

func heal(amount):
	current_hp+=amount
	current_hp = clamp(current_hp, 0, max_hp)
	emit_signal("hp_changed", current_hp, max_hp)

func die():
	print("player died")

func get_input():
	direction = Vector2.ZERO
	direction.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	direction.y = Input.get_action_strength("down") - Input.get_action_strength("up")
	direction = direction.normalized()

func move_player(delta):
	if Input.get_action_strength("sprint") > 0 and current_stamina>10:
		velocity = direction*(move_speed+100)
		current_stamina -= 5 * delta
	else:
		velocity = direction * move_speed
		current_stamina += 30 * delta
	current_stamina = clamp(current_stamina, 0, max_stamina)
	emit_signal("stamina_usage", current_stamina, max_stamina)
	move_and_slide()

func update_animation():
	if velocity == Vector2.ZERO:
		play_anim("idle")
		return
	if abs(velocity.x) > abs(velocity.y):
		play_anim("walk_side")
		update_flip()
	else:
		if velocity.y > 0:
			play_anim("walk_down")
		else:
			play_anim("walk_up")

func play_anim(name):

	if anim.current_animation != name:
		anim.play(name)


func update_flip():

	if velocity.x < 0:
		sprite.flip_h = true
	elif velocity.x > 0:
		sprite.flip_h = false
		
func _process(delta):
	if Input.is_action_just_pressed("pick_up") and items_in_range.size() > 0:
		var item = items_in_range[0]  # bierze pierwszy
		item.collect()
		
func add_item(item): #dodaje item do listy itemów w zasięgu
	items_in_range.append(item)

func remove_item(item): #usuwa item z listy zasięgu
	items_in_range.erase(item)
	
