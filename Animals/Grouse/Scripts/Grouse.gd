extends CharacterBody2D

signal hp_changed(current_hp, max_hp)
signal died

enum State {IDLE, WANDER, FLEE, HIT, DEAD }

var player_in_hitbox=false # atak playera w zasiegu hiboxa
var facing := ""

# --- STATS ---
@export var max_hp: int = 50
var current_hp: int

@export var speed: float = 80
@export var flee_speed: float=100

var lose_target_delay = 0.5
var losing_target = false
var wander_wait_time: float = 2

var wander_direction: Vector2 = Vector2.ZERO
var wander_timer: float = 0.0

@export var wander_change_time := 2.0

# STATE
var state: State = State.WANDER
var target: CharacterBody2D = null

@onready var sprite: AnimatedSprite2D = $Visual/AnimatedSprite2D
@onready var hp_bar = $Hp_bar
@onready var visual: Node2D = $Visual
@onready var flee_area: Area2D = $Flee_Area

@export var scene: PackedScene #instancja sceny struktury
@export var scene2: PackedScene

func _ready():
	current_hp = max_hp
	add_to_group("Enemies")
	if "target" in hp_bar:
		hp_bar.set_target(self)
	print("IceGolem HP:", current_hp)
	randomize()
	
func _physics_process(delta):
	if state == State.DEAD:
		move_and_slide()
		return
	if target == null:
		var bodies = flee_area.get_overlapping_bodies()
		for b in bodies:
			if b.is_in_group("Players"):
				target = b
				state = State.FLEE
	match state:
		State.IDLE:
			velocity=Vector2.ZERO
		State.WANDER:
			wander()
		State.FLEE:
			flee()
		State.HIT:
			velocity = Vector2.ZERO
	update_animation()
	move_and_slide()

# AI
func wander():
	wander_timer -= get_physics_process_delta_time()

	if wander_timer <= 0:
		wander_timer = randf_range(1.5, 3.5)

		if randf() < 0.3:
			wander_direction = Vector2.ZERO
		else:
			wander_direction = Vector2(
				randf_range(-1.0, 1.0),
				randf_range(-1.0, 1.0)
			).normalized()

	velocity = wander_direction * speed
	
func flee():
	if target == null:
		state = State.WANDER
		return

	var dir = global_position - target.global_position
	velocity = dir.normalized() * flee_speed
# DAMAGE SYSTEM
func take_damage(amount: int):
	if state == State.DEAD:
		return
	current_hp -= amount
	current_hp = clamp(current_hp, 0, max_hp)
	if current_hp<max_hp:
		hp_bar.visible=true
	emit_signal("hp_changed", current_hp, max_hp)
	if current_hp <= 0:
		die()
		return
	enter_hit_state()
	
# HIT
func enter_hit_state():
	if state == State.DEAD:
		return
	state = State.HIT
	velocity = Vector2.ZERO
	sprite.play("hurt" + facing)
	await sprite.animation_finished
	if state == State.DEAD:
		return
	state = State.FLEE if target else State.WANDER
		
# DEATH
func die():
	if state == State.DEAD:
		return
	state = State.DEAD
	target = null
	velocity = Vector2.ZERO
	emit_signal("died")
	sprite.play("death" + facing)
	await sprite.animation_finished
	queue_free()
	drop_item()

# ANIMATIONS
func update_animation():
	if state == State.DEAD:
		return
	if state == State.HIT:
		return
	update_flip()
	
	if velocity.length() > 5:
		facing = get_direction()
	match state:
		State.WANDER:
			if velocity.length() < 5:
				play_anim("idle" + facing)
			else:
				play_anim("walk" + facing)
		State.IDLE:
			play_anim("idle" + facing)
		State.FLEE:
			if velocity.length() < 5:
				play_anim("idle" + facing)
			else:
				play_anim("run" + facing)
	update_flip()

func play_anim(name: String):
	if sprite.animation != name:
		sprite.play(name)

func update_flip():
	if velocity.x < 0:
		visual.scale.x = -1
	elif velocity.x > 0:
		visual.scale.x = 1

func get_direction() -> String:
	if abs(velocity.x) > abs(velocity.y):
		return "_side"
	if velocity.y < 0:
		return "_back"
	return ""

func _on_flee_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Players"):
		target = body
		losing_target = false
		state = State.FLEE

func _on_flee_area_body_exited(body: Node2D) -> void:
	if body == target:
		start_losing_target()
		
func start_losing_target():
	losing_target = true
	await get_tree().create_timer(lose_target_delay).timeout
	if losing_target:
		target = null
		state = State.WANDER
		await get_tree().create_timer(wander_wait_time).timeout
		print("BACK TO WANDER")

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("Players"):
		player_in_hitbox = true

func _on_hitbox_body_exited(body: Node2D) -> void:
	if body.is_in_group("Players"):
		player_in_hitbox = false

func drop_item():
	if scene:
		var item = scene.instantiate()
		get_parent().add_child(item)
		item.global_position = global_position + Vector2(0, 20)
		
	if scene2:
		var item2 = scene2.instantiate()
		get_parent().add_child(item2)
		item2.global_position = global_position + Vector2(10, 35)
