class_name Player extends CharacterBody2D

var move_speed = 100
var direction = Vector2.ZERO

@onready var anim = $AnimationPlayer
@onready var sprite = $Sprite2D

func _physics_process(delta):

	get_input()
	move_player()
	update_animation()


func get_input():

	direction = Vector2.ZERO
	direction.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	direction.y = Input.get_action_strength("down") - Input.get_action_strength("up")
	direction = direction.normalized()


func move_player():
	if Input.get_action_strength("sprint"):
		velocity=direction*(move_speed+100)
	else:
		velocity = direction * move_speed
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
