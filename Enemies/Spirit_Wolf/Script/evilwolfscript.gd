class_name EvilWolf extends CharacterBody2D

enum State { PATROL, CHASE }

var state = State.PATROL
var speed: float = 80
var target: CharacterBody2D = null

var attack_recovery_time: float = 0.7
var in_attack_recovery = false

var patrol_origin: Vector2
var patrol_points = []
var patrol_index = 0
var patrol_wait_time: float = 2

var lose_target_delay = 0.5
var losing_target = false

var attack_range: float = 30
var attack_cooldown: float = 1.2
var can_attack = true

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	patrol_origin = global_position
	patrol_points = []
	for p in get_tree().get_nodes_in_group("PatrolPoints"):
		patrol_points.append(p)

func _physics_process(delta):
	if in_attack_recovery:
		move_and_slide()
		return
	match state:
		State.PATROL:
			patrol()
		State.CHASE:
			chase()
	move_and_slide()
	chasing_anim()

func patrol():
	if patrol_points.is_empty():
		velocity = Vector2.ZERO
		return
	var point = patrol_points[patrol_index]
	var distance = global_position.distance_to(point.global_position)
	if distance < 20:
		velocity = Vector2.ZERO
		patrol_index = (patrol_index + 1) % patrol_points.size()
		return
	var direction = (point.global_position - global_position).normalized()
	velocity = direction * speed

func chase():
	if target == null:
		velocity = Vector2.ZERO
		return
	var distance = global_position.distance_to(target.global_position)
	if distance > attack_range:
		var direction = (target.global_position - global_position).normalized()
		velocity = direction * speed
	else:
		velocity = Vector2.ZERO
		try_attack()

func try_attack():
	if not can_attack or in_attack_recovery:
		return
	can_attack = false
	in_attack_recovery = true
	velocity = Vector2.ZERO
	animated_sprite_2d.play("attack")
	print("Attack!")
	attack_recovery()
	attack_cooldown_timer()

func attack_recovery():
	await get_tree().create_timer(attack_recovery_time).timeout
	in_attack_recovery = false

func attack_cooldown_timer():
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func _on_follow_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Players"):
		target = body
		state = State.CHASE
		losing_target = false
		print("CHASE")


func _on_follow_area_body_exited(body: Node2D) -> void:
	if body == target:
		start_losing_target()

func start_losing_target():
	losing_target = true
	await get_tree().create_timer(lose_target_delay).timeout
	if losing_target:
		target = null
		state = State.PATROL
		await get_tree().create_timer(patrol_wait_time).timeout
		shift_patrol_points()
		print("BACK TO PATROL")

func shift_patrol_points():
	var offset = global_position - patrol_origin
	for p in patrol_points:
		p.global_position += offset
	patrol_origin = global_position

func chasing_anim():
	if animated_sprite_2d.animation == "attack":
		return
	if velocity.length() < 1:
		play_anim("idle")
	else:
		play_anim("walk")
		
	update_flip()

func play_anim(name):
	if animated_sprite_2d.animation != name:
		animated_sprite_2d.play(name)

func update_flip():
	if velocity.x < 0:
		animated_sprite_2d.flip_h = false
	elif velocity.x > 0:
		animated_sprite_2d.flip_h = true

func _on_animated_sprite_2d_animation_finished():
	if animated_sprite_2d.animation == "attack":
		animated_sprite_2d.play("idle")
