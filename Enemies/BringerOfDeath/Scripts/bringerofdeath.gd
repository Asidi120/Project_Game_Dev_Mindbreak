class_name BringerOfDeath extends CharacterBody2D

signal hp_changed(current_hp, max_hp)
signal died

enum State { PATROL, CHASE, ATTACK, HIT, DEAD }

var is_taking_damage = false
var is_dead = false
var player_in_attack_range=false

# --- STATS ---
@export var max_hp: int = 100
var current_hp: int

@export var speed: float = 80
@export var attack_range: float = 100
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

@onready var sprite: AnimatedSprite2D = $Visual/AnimatedSprite2D
@onready var hp_bar = $Hp_bar
@onready var visual: Node2D = $Visual
@onready var normal_attack_area: Area2D = $Normal_attack_Area
@onready var points_container: Node2D = $"../PatrolPionts"
@onready var follow_area: Area2D = $Follow_Area

func _ready():
	current_hp = max_hp
	patrol_origin = global_position
	add_to_group("Enemies")
	
	if "target" in hp_bar:
		hp_bar.set_target(self)
	print("BrinderOFDeath HP:", current_hp)
	for p in points_container.get_children():
		patrol_points.append(p)

func _physics_process(delta):
	if state == State.DEAD or state == State.HIT or state == State.ATTACK:
		move_and_slide()
		return
	if target == null:
		var bodies = follow_area.get_overlapping_bodies()
		for b in bodies:
			if b.is_in_group("Players"):
				target = b
				state = State.CHASE

	match state:
		State.PATROL:
			patrol()
		State.CHASE:
			chase()
		State.ATTACK:
			velocity = Vector2.ZERO

	move_and_slide()
	update_animation()

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
	if player_in_attack_range:
		velocity = Vector2.ZERO
		start_attack()
	else:
		velocity = (target.global_position - global_position).normalized() * speed

func start_attack():
	if not can_attack or state == State.DEAD:
		return

	state = State.ATTACK
	can_attack = false
	velocity = Vector2.ZERO
	sprite.play("attack")
	await get_tree().create_timer(1).timeout
	if target and player_in_attack_range and target.has_method("take_damage"):
		target.take_damage(10)
	await sprite.animation_finished

	state = State.CHASE
	#await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

# DAMAGE SYSTEM
func take_damage(amount: int):
	if state == State.DEAD:
		return

	current_hp -= amount
	current_hp = clamp(current_hp, 0, max_hp)
	print("Wolf hp: ",current_hp)
	emit_signal("hp_changed", current_hp, max_hp)

	if current_hp <= 0:
		die()
	else:
		enter_hit_state()
		
func enter_hit_state():
	state = State.HIT
	velocity = Vector2.ZERO
	sprite.play("hurt")
	await sprite.animation_finished
	state = State.CHASE

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
		visual.scale.x = 1
		normal_attack_area.position.x=0
	elif velocity.x > 0:
		normal_attack_area.position.x=85
		visual.scale.x = -1

# DETECTION

func _on_follow_area_body_entered(body):
	if body.is_in_group("Players"):
		target = body
		losing_target = false
		state = State.CHASE
		can_attack=true

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

func _on_normal_attack_area_body_entered(body):
	if body.is_in_group("Players"):
		player_in_attack_range = true

func _on_normal_attack_area_body_exited(body):
	if body.is_in_group("Players"):
		player_in_attack_range = false
