class_name Player extends CharacterBody2D

@onready var death_panel: Control = $"../../../CanvasLayer/DeathPanel"
@onready var clock: Control = $"../../../CanvasLayer/Clock"
@onready var hp_bar: TextureProgressBar = $"../../../CanvasLayer/PlayerBar/hp_bar"
signal hp_changed(current_hp, max_hp)
signal stamina_usage(current_stamina, max_stamina)
signal hunger_changed(current_hunger,max_hunger)
@onready var attack_hitbox: Area2D = $AttackHitbox
var is_attacking = false

var move_speed = 100
var direction = Vector2.ZERO
var items_in_range = [] #przechowuje itemy w zasięgu gracza
var current_hp = 200 # aktualne hp gracza
var max_hp = 200 
var max_stamina=100
var current_stamina=100
var stamina_recovery_timer:float=0.7
var was_sprinting:bool=true
var recovery_started:bool=false
var in_stamina_recovery=true
var current_hunger=150
var max_hunger=150
var hunger_timer:float= 0.0
var hunger_interval_normal:float= 2.0
var hunger_interval_sprint:float= 0.5
var spawn_point=global_position
var already_hit = []

@onready var anim = $AnimationPlayer
@onready var sprite = $Sprite2D
func _ready():
	hp_bar.set_target(self)
	attack_hitbox.monitoring=false
	
func _physics_process(delta):
	get_input()
	move_player(delta)
	update_animation()
	update_hunger(delta)
	if Input.is_action_just_pressed("attack") and not is_attacking:
		attack()

func attack():
	is_attacking = true
	#sprite.play("attack")
	attack_hitbox.monitoring = true  # włącz hitbox
	await get_tree().create_timer(0.2).timeout  # czas uderzenia
	attack_hitbox.monitoring = false
	#await sprite.animation_finished
	is_attacking = false
	already_hit=[]

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
	death_panel.visible=true
	get_tree().paused=true

func update_hunger(delta):
	var interval = hunger_interval_normal
	if Input.get_action_strength("sprint") > 0:
		interval = hunger_interval_sprint
	hunger_timer += delta
	if hunger_timer >= interval:
		hunger_timer = 0
		current_hunger -= 1
		if current_hunger<1:
			current_hunger=0
			take_damage(5)
		current_hunger = clamp(current_hunger, 0, max_hunger)
		emit_signal("hunger_changed", current_hunger, max_hunger)

func get_input():
	direction = Vector2.ZERO
	direction.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	direction.y = Input.get_action_strength("down") - Input.get_action_strength("up")
	direction = direction.normalized()

func move_player(delta):
	if Input.get_action_strength("sprint") > 0:
		current_stamina -= 15 * delta
		if current_stamina<10 or current_hunger<=1:
			velocity = direction * move_speed
		else:
			velocity = direction*(move_speed+100)
			was_sprinting=true
	else:
		velocity = direction * move_speed
		if was_sprinting:
			was_sprinting=false
			stamina_recovery()
		if !in_stamina_recovery:
			current_stamina += 30 * delta
	current_stamina = clamp(current_stamina, 0, max_stamina)
	emit_signal("stamina_usage", current_stamina, max_stamina)
	move_and_slide()

func stamina_recovery():
	if recovery_started:
		return  # już działa timer
	recovery_started = true
	in_stamina_recovery = true
	await get_tree().create_timer(stamina_recovery_timer).timeout
	in_stamina_recovery = false
	recovery_started = false

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
