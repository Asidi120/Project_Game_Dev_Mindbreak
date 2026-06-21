class_name BringerOfDeathDungeonBoss extends CharacterBody2D

signal hp_changed(current_hp, max_hp)
signal died

enum State { PATROL, CHASE, ATTACK, RANGED_ATTACK, HIT, DEAD }

var is_taking_damage = false
var is_dead = false
var player_in_attack_range = false
var player_in_spell_range = false
var player_in_hitbox = false
var regen_buffer := 0.0

@export var start_facing_left := true
var facing_left := true

# --- STATS ---
@export var max_hp: int = 500
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

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D # Dodane dla optymalizacji ruchu
@onready var sprite: AnimatedSprite2D = $Visual/AnimatedSprite2D
@onready var hp_bar = $Hp_bar
@onready var visual: Node2D = $Visual
@onready var normal_attack_area: Area2D = $Normal_attack_Area
@onready var points_container: Node2D = $"../PatrolPionts"
@onready var follow_area: Area2D = $Follow_Area
@export var spell_scene: PackedScene = preload("res://Enemies/BringerOfDeath/spelldungeon.tscn")

func _ready():
	# Inicjalizacja kierunku (bazowo patrzy w lewo)
	facing_left = start_facing_left
	apply_flip()

	current_hp = max_hp
	patrol_origin = global_position
	add_to_group("Enemies")
	
	if "target" in hp_bar:
		hp_bar.set_target(self)
	print("BringerOfDeath HP:", current_hp)
	for p in points_container.get_children():
		patrol_points.append(p)

func _physics_process(delta):
	if state == State.DEAD:
		move_and_slide()
		return
		
	# Bezpieczna zmiana stanu na CHASE - blokowana, jeśli postać wykonuje inną akcję
	if state != State.ATTACK and state != State.RANGED_ATTACK and state != State.HIT:
		if target == null:
			var bodies = follow_area.get_overlapping_bodies()
			for b in bodies:
				if b.is_in_group("Players"):
					target = b
					if can_see_target():
						state = State.CHASE
		elif can_see_target():
			state = State.CHASE

	match state:
		State.PATROL:
			patrol()
		State.CHASE:
			chase()
		State.ATTACK, State.RANGED_ATTACK, State.HIT:
			velocity = Vector2.ZERO
	move_and_slide()
	update_animation()
	regenerate_hp(delta)

func regenerate_hp(delta):
	if state == State.DEAD:
		return
	regen_buffer += 5.0 * delta
	if regen_buffer >= 1.0:
		var heal := int(regen_buffer)
		current_hp = min(current_hp + heal, max_hp)
		regen_buffer -= heal
		emit_signal("hp_changed", current_hp, max_hp)

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

	if player_in_attack_range:
		velocity = Vector2.ZERO
		start_attack()
	elif player_in_spell_range:
		velocity = Vector2.ZERO
		cast_spell()
	else:
		nav_agent.target_position = target.global_position
		var next_pos = nav_agent.get_next_path_position()
		velocity = (next_pos - global_position).normalized() * speed

func start_attack():
	if not can_attack or state == State.ATTACK or state == State.HIT:
		return

	state = State.ATTACK
	can_attack = false
	velocity = Vector2.ZERO
	sprite.play("attack")
	
	await get_tree().create_timer(1).timeout
	if state != State.ATTACK: 
		return
	
	if target and player_in_attack_range and target.has_method("take_damage"):
		target.take_damage(10)
		
	await sprite.animation_finished
	
	if state == State.ATTACK:
		state = State.CHASE
	can_attack = true

func cast_spell():
	if not can_attack or state == State.RANGED_ATTACK or state == State.HIT or player_in_attack_range:
		return

	state = State.RANGED_ATTACK
	can_attack = false
	velocity = Vector2.ZERO
	sprite.play("cast")
	
	await get_tree().create_timer(0.1).timeout
	if state != State.RANGED_ATTACK: return
	
	var spell = spell_scene.instantiate()
	get_tree().current_scene.add_child(spell)
	spell.global_position = global_position
	if spell.has_method("init"):
		spell.init(target)
		
	await sprite.animation_finished
	
	if state == State.RANGED_ATTACK:
		state = State.CHASE
		
	await get_tree().create_timer(0.5).timeout # Cooldown dla czaru
	can_attack = true

# DAMAGE SYSTEM
func take_damage(amount: int):
	if state == State.DEAD:
		return

	current_hp -= amount
	current_hp = clamp(current_hp, 0, max_hp)
	print("BringerOfDeath hp: ", current_hp)
	emit_signal("hp_changed", current_hp, max_hp)

	if current_hp <= 0:
		die()
	else:
		enter_hit_state()
		
func enter_hit_state():
	if state == State.DEAD:
		return
	state = State.HIT
	velocity = Vector2.ZERO
	sprite.play("hurt")
	await sprite.animation_finished
	if state == State.HIT:
		state = State.CHASE
	can_attack=true

# DEATH
func die():
	if state == State.DEAD:
		return
	state = State.DEAD
	is_dead = true
	target = null
	velocity = Vector2.ZERO
	emit_signal("died")
	sprite.play("death")
	await sprite.animation_finished
	queue_free()

# ANIMATIONS
func update_animation():
	if is_dead or state == State.DEAD:
		return
	if is_taking_damage:
		return
	if state == State.ATTACK or state == State.RANGED_ATTACK or state == State.HIT:
		return
		
	if velocity.length() < 1:
		play_anim("idle")
	else:
		play_anim("walk")
	update_flip()

func play_anim(name: String):
	if sprite.animation != name:
		sprite.play(name)

# Dostosowanie do oryginalnej grafiki skierowanej w LEWO
func update_flip():
	if velocity.x > 0:
		facing_left = false  # Idzie w prawo
	elif velocity.x < 0:
		facing_left = true   # Idzie w lewo
	elif target:
		facing_left = target.global_position.x < global_position.x # Patrzy w stronę gracza
	else:
		facing_left = start_facing_left # Reset po zatrzymaniu na patrolu

	apply_flip()

func apply_flip():
	if facing_left:
		visual.scale.x = 1          # 1 oznacza domyślny wygląd (w lewo)
		normal_attack_area.position.x = 0
	else:
		visual.scale.x = -1         # -1 odbija postać w prawo
		normal_attack_area.position.x = 85
		
# DETECTION
func _on_follow_area_body_entered(body):
	if body.is_in_group("Players"):
		target = body
		losing_target = false
		if can_see_target() and state != State.ATTACK and state != State.RANGED_ATTACK and state != State.HIT:
			state = State.CHASE
		can_attack = true

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
		if state == State.PATROL:
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

func _on_spell_range_body_entered(body: Node2D) -> void:
	if body.is_in_group("Players"):
		player_in_spell_range = true

func _on_spell_range_body_exited(body: Node2D) -> void:
	if body.is_in_group("Players"):
		player_in_spell_range = false

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("Players"):
		player_in_hitbox = true

func _on_hitbox_body_exited(body: Node2D) -> void:
	if body.is_in_group("Players"):
		player_in_hitbox = false

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
