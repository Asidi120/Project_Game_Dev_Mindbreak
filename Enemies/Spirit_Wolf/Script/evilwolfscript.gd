class_name EvilWolf extends CharacterBody2D

signal hp_changed(current_hp, max_hp)
signal died

enum State { PATROL, CHASE, ATTACK, HIT, DEAD }

var in_dmg_area=false #can hit wolf - temporarly
var is_taking_damage = false
var is_dead = false

# --- STATS ---
@export var max_hp: int = 100
var current_hp: int

@export var speed: float = 80
@export var attack_range: float = 30
@export var attack_cooldown: float = 1.2

var lose_target_delay = 0.5
var losing_target = false
var patrol_wait_time: float = 2

# STATE
var state: State = State.PATROL
var target: CharacterBody2D = null
var can_attack: bool = true

# PATROL
var patrol_points: Array = []
var patrol_index: int = 0
var patrol_origin: Vector2

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hp_bar = $Hp_bar

func _ready():
	current_hp = max_hp
	patrol_origin = global_position
	
	if "target" in hp_bar:
		hp_bar.set_target(self)
	print("Wolf HP:", current_hp)
	for p in get_tree().get_nodes_in_group("PatrolPoints"):
		patrol_points.append(p)

func _physics_process(delta):
	if state == State.DEAD or state == State.HIT:
		move_and_slide()
		return

	match state:
		State.PATROL:
			patrol()
		State.CHASE:
			chase()
		State.ATTACK:
			velocity = Vector2.ZERO

	move_and_slide()
	update_animation()
	if in_dmg_area and Input.is_action_just_pressed("attack"):
		take_damage(5)

# AI
func patrol():
	if patrol_points.is_empty():
		velocity = Vector2.ZERO
		return

	var point = patrol_points[patrol_index]
	var distance = global_position.distance_to(point.global_position)
	
	if distance < 20:
		patrol_index = (patrol_index + 1) % patrol_points.size()
		velocity = Vector2.ZERO
		return
		
	velocity = (point.global_position - global_position).normalized() * speed

func chase():
	if target == null:
		state = State.PATROL
		return

	var distance = global_position.distance_to(target.global_position)

	if distance > attack_range:
		velocity = (target.global_position - global_position).normalized() * speed
	else:
		start_attack()

func start_attack():
	if not can_attack:
		return

	state = State.ATTACK
	can_attack = false
	velocity = Vector2.ZERO

	sprite.play("attack")

	if target and target.has_method("take_damage"):
		target.take_damage(10)

	await sprite.animation_finished

	state = State.CHASE
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

# DAMAGE SYSTEM
func take_damage(amount: int):
	if state == State.DEAD:
		return

	current_hp -= amount
	current_hp = clamp(current_hp, 0, max_hp)

	emit_signal("hp_changed", current_hp, max_hp)

	if current_hp <= 0:
		die()
	else:
		enter_hit_state()
		
func enter_hit_state():
	state = State.HIT

	velocity = Vector2.ZERO
	sprite.play("dmg_taken")

	await sprite.animation_finished

	state = State.CHASE

func play_damage_anim():
	if is_dead:
		return

	is_taking_damage = true

	sprite.play("dmg_taken")
	await sprite.animation_finished

	is_taking_damage = false

# DEATH

func die():
	if state == State.DEAD:
		return

	state = State.DEAD

	target = null
	velocity = Vector2.ZERO

	emit_signal("died")

	sprite.play("death")
	await sprite.animation_finished

	queue_free()

# ANIMATIONS
func update_animation():
	if is_dead:
		return

	if is_taking_damage:
		return

	if state == State.ATTACK:
		return

	if velocity.length() < 1:
		play_anim("idle")
	else:
		play_anim("walk")

	update_flip()

func play_anim(name: String):
	if sprite.animation != name:
		sprite.play(name)

func update_flip():
	if velocity.x < 0:
		sprite.flip_h = false
	elif velocity.x > 0:
		sprite.flip_h = true

# DETECTION

func _on_follow_area_body_entered(body):
	if body.is_in_group("Players"):
		target = body
		state = State.CHASE

func _on_follow_area_body_exited(body):
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

# HITBOX (odbieranie dmg)

#func _on_hurtbox_area_entered(area):
	#if area.has_method("get_damage"):
		#take_damage(area.get_damage())

#temporarly cause it shouldnt be in wolf script
func _on_hitbox_body_exited(body: Node2D) -> void:
	if body.is_in_group("Players"):
		in_dmg_area=false
		print("area entered")


func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("Players"):
		in_dmg_area=true
		print("area exited")
