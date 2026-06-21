class_name EvilWolfDungeonBoss extends CharacterBody2D

signal hp_changed(current_hp, max_hp)
signal died

enum State { PATROL, CHASE, SEARCH, ATTACK, HIT, DEAD }

var is_taking_damage = false
var is_dead = false
@export var start_facing_right := false
var facing_right := false

# --- STATS ---
@export var max_hp: int = 100
var current_hp: int

@export var speed: float = 80
@export var attack_range: float = 30
@export var attack_cooldown: float = 1.2

var lose_target_delay = 3
var losing_target = false
var patrol_wait_time: float = 2
var regen_buffer := 0.0

# STATE
var state: State = State.PATROL
var target: CharacterBody2D = null
var can_attack: bool = true
var last_seen_position: Vector2

# PATROL
var patrol_points: Array = []
var patrol_index: int = 0
var patrol_origin: Vector2


@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var sprite: AnimatedSprite2D = $Visual/AnimatedSprite2D
@onready var hp_bar = $Hp_bar
@onready var points_container: Node2D = $"../PatrolPoints"
@onready var attack_area: Area2D = $Attack_Area
@onready var visual: Node2D = $Visual


func _ready():
	facing_right = start_facing_right

	if facing_right:
		visual.scale.x = -1
		attack_area.position.x = 35
	else:
		visual.scale.x = 1
		attack_area.position.x = 0
	current_hp = max_hp
	patrol_origin = global_position
	add_to_group("Enemies")
	
	if "target" in hp_bar:
		hp_bar.set_target(self)
	print("Wolf HP:", current_hp)
	for p in points_container.get_children():
		patrol_points.append(p)

func _physics_process(delta):
	if state == State.DEAD or state == State.HIT:
		move_and_slide()
		return
	if state!=State.ATTACK and target and can_see_target():
		state = State.CHASE

	match state:
		State.PATROL:
			patrol()

		State.CHASE:
			chase()

		State.SEARCH:
			search()

		State.ATTACK:
			velocity = Vector2.ZERO

	move_and_slide()
	update_animation()

func regenerate_hp(delta):
	if state == State.DEAD:
		return
	regen_buffer += 5.0 * delta
	if regen_buffer >= 1.0:
		var heal := int(regen_buffer)
		current_hp = min(current_hp + heal, max_hp)
		regen_buffer -= heal
		emit_signal("hp_changed", current_hp, max_hp)

func search():
	velocity = (last_seen_position - global_position).normalized() * speed

	if global_position.distance_to(last_seen_position) < 10:
		velocity = Vector2.ZERO
		target = null
		state = State.PATROL

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
		
	nav_agent.target_position = point.global_position
	var next_pos = nav_agent.get_next_path_position()
	velocity = (next_pos - global_position).normalized() * speed

func chase():
	if target == null:
		state = State.PATROL
		return
	print("Can see:", can_see_target())
	if can_see_target():
		last_seen_position = target.global_position
		
		var distance = global_position.distance_to(target.global_position)

		if distance > attack_range:
			nav_agent.target_position = target.global_position
			var next_pos = nav_agent.get_next_path_position()
			velocity = (next_pos - global_position).normalized() * speed
		else:
			start_attack()

	else:
		state = State.SEARCH

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
	print("Wolf hp: ",current_hp)
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
	if velocity.x > 0:
		facing_right = true
	elif velocity.x < 0:
		facing_right = false
	elif target:
		facing_right = target.global_position.x > global_position.x
	else:
		facing_right = start_facing_right
	if facing_right:
		visual.scale.x = -1
		attack_area.position.x = 35
	else:
		visual.scale.x = 1
		attack_area.position.x = 0

# DETECTION

func _on_follow_area_body_entered(body):
	if body.is_in_group("Players"):
		target = body
		losing_target=false
		if can_see_target():
			last_seen_position = body.global_position
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
		print("BACK TO PATROL")



func can_see_target() -> bool:
	if target == null:
		return false
		
	var space = get_world_2d().direct_space_state

	var query = PhysicsRayQueryParameters2D.create(
		global_position,
		target.global_position
	)

	query.exclude = [self]

	var result = space.intersect_ray(query)

	if result.is_empty():
		return true

	return result.collider == target
