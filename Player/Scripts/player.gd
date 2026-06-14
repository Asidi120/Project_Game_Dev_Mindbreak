class_name Player extends CharacterBody2D

var death_panel: Control
var clock: Control  
var hp_bar: TextureProgressBar
var damage_flash: ColorRect
signal hp_changed(current_hp, max_hp)
signal stamina_usage(current_stamina, max_stamina)
signal hunger_changed(current_hunger,max_hunger)
@onready var attack_hitbox: Area2D = $AttackHitbox
var is_attacking = false

var move_speed = 100
var direction = Vector2.ZERO
var items_in_range = []
var current_hp = 200
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
var spawn_point=Vector2.ZERO
var already_hit = []

var inventory = []
const MAX_STACK = 2
const MAX_SLOT = 24

# Inventory UI — szukane przez grupę żeby działało w każdej scenie
var inventory_ui = null

@onready var sounds: Node2D = $Sounds
var fasteq_ui = null
@onready var anim = $AnimationPlayer

# Warstwy sprite'a
@onready var sprite:          Sprite2D = $Layers/LayerBody
@onready var layer_body:      Sprite2D = $Layers/LayerBody
@onready var layer_hair:      Sprite2D = $Layers/LayerHair
@onready var layer_clothes:   Sprite2D = $Layers/LayerClothes

enum State { IDLE, MOVE, ATTACK, DEAD, STUNNED }
var state: State = State.IDLE

# STATUS EFFECTS
var is_stunned = false
var is_slowed = false
var is_poisoned = false
var is_buffed = false

var slow_multiplier = 0.5
var buff_multiplier = 1.5
var poison_damage = 2

@onready var held_item = $Hand/HeldItem
var inventory_system = null

var facing_direction := Vector2.DOWN


func _ready() -> void:
	await get_tree().process_frame
	add_to_group("player")
	add_to_group("Players")
	inventory_system = get_tree().get_first_node_in_group("inventory_ui")

	# HUD
	var hud = get_tree().get_first_node_in_group("hud")
	if hud:
		death_panel = hud.get_node_or_null("DeathPanel")
		clock       = hud.get_node_or_null("Clock")
		hp_bar      = hud.get_node_or_null("PlayerBar/hp_bar")
		damage_flash  = hud.get_node_or_null("ColorRect")
		if hp_bar:
			hp_bar.set_target(self)

	# Inventory UI
	inventory_ui = get_tree().get_first_node_in_group("inventory")
	fasteq_ui = get_tree().get_first_node_in_group("fasteq")
	
	attack_hitbox.monitoring = false
	spawn_point = global_position

	for i in range(MAX_SLOT):
		inventory.append(null)

	apply_appearance()

func _physics_process(delta):
	update_hunger(delta)

	match state:
		State.IDLE:
			get_input()
			move_player(delta)
			if velocity != Vector2.ZERO:
				state = State.MOVE
		State.MOVE:
			get_input()
			move_player(delta)
			if velocity == Vector2.ZERO:
				state = State.IDLE
		State.ATTACK:
			velocity = Vector2.ZERO
		State.STUNNED:
			velocity = Vector2.ZERO
		State.DEAD:
			return

	update_animation()

	if Input.is_action_just_pressed("attack") and not is_attacking and state != State.STUNNED:
		attack()

func update_held_item():
	if inventory_system == null:
		return

	var index = inventory_system.selected_fasteq_index

	if index < 0 or index >= inventory_system.current_inventory.size():
		held_item.visible = false
		return

	var item = inventory_system.current_inventory[index]

	if item == null:
		held_item.visible = false
		return

	held_item.visible = true
	held_item.texture = item["texture"]
	held_item.z_index = 10
	held_item.size = Vector2(15, 15)
	held_item.custom_minimum_size = Vector2(10, 10)
	held_item.position = Vector2(-10, -10)
	held_item.scale = Vector2.ONE

	held_item.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	held_item.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	#jedzenie trzymanego itema
	if Input.is_action_just_pressed("eat")and item["item_type"] == "food":
		if eating(item):
			print("Znikaaaaa")
			inventory_system.current_inventory[index] = null
			inventory_system.refresh_all()


func eating(item):
	#jeśli ewkipunek niewidoczny
	var czy_zjedzone = false
	if not inventory_system.inventory_visible:
		if item["hunger_points"] <= max_hunger:
			if current_hunger == max_hunger:
				print("Nie można zjeść. Jesteś najedzony!")
				return
			elif item["hunger_points"] + current_hunger >= max_hunger:
				current_hunger = max_hunger
				print("Najadłeś się")
			else:
				print("Zjadłeś")
				current_hunger += item["hunger_points"]
		czy_zjedzone = true
		return czy_zjedzone

#wyrzucanie przyciskiem Q jesli jest selected w inventory lub scroll na fast eq
func throw():
	if Input.is_action_just_pressed("throw"):
		if inventory_system == null:
			return

		var index := -1

		if inventory_system.inventory_visible:
			index = inventory_system.selected_slot_index
		else:
			index = inventory_system.selected_fasteq_index

		if index == -1:
			return

		if index < 0 or index >= inventory_system.current_inventory.size():
			return

		var item = inventory_system.current_inventory[index]

		if item == null:
			return

		print(index)
		print(inventory_system.current_inventory[index])
		print(facing_direction)
		var item_scene = load(item["scene_path"])
		var dropped_item = item_scene.instantiate()

		get_tree().current_scene.add_child(dropped_item)
		dropped_item.global_position = global_position + facing_direction * 20
		
		#usuniecie z ekwipunka 
		if item["amount"] > 1:
			item["amount"] -= 1
		else:
			inventory_system.current_inventory[index] = null

		inventory_system.refresh_all()
	
	
func attack():
	state = State.ATTACK
	is_attacking = true
	attack_hitbox.monitoring = true
	sounds.play_sound("attack")
	await get_tree().create_timer(0.2).timeout
	attack_hitbox.monitoring = false
	is_attacking = false
	already_hit = []
	state = State.IDLE

func apply_stun(duration: float):
	if state == State.DEAD:
		return
	state = State.STUNNED
	is_stunned = true
	velocity = Vector2.ZERO
	await get_tree().create_timer(duration).timeout
	is_stunned = false
	state = State.IDLE

func apply_slow(duration: float, multiplier: float = 0.5):
	is_slowed = true
	slow_multiplier = multiplier
	await get_tree().create_timer(duration).timeout
	is_slowed = false
	slow_multiplier = 1.0

func apply_poison(duration: float):
	if is_poisoned:
		return
	is_poisoned = true
	var time = 0.0
	while time < duration:
		await get_tree().create_timer(1.0).timeout
		take_damage(poison_damage)
		time += 1.0
	is_poisoned = false

func apply_buff(duration: float, multiplier: float = 1.5):
	is_buffed = true
	buff_multiplier = multiplier
	await get_tree().create_timer(duration).timeout
	is_buffed = false
	buff_multiplier = 1.0

func take_damage(amount):
	current_hp -= amount
	current_hp = clamp(current_hp, 0, max_hp)
	emit_signal("hp_changed", current_hp, max_hp)
	print("Player hp:", current_hp)
	if current_hp <= 0:
		die()
	else:
		show_damage_flash()
		sounds.play_sound("hurt")

func show_damage_flash():
	
	if damage_flash == null:
		return
	damage_flash.visible=true
	damage_flash.modulate.a = 0

	var tween = create_tween()
	tween.tween_property(damage_flash, "modulate:a", 0.6, 0.05)
	tween.tween_property(damage_flash, "modulate:a", 0.0, 0.15)

func heal(amount):
	current_hp += amount
	current_hp = clamp(current_hp, 0, max_hp)
	emit_signal("hp_changed", current_hp, max_hp)

func die():
	if state == State.DEAD:
		return
	state = State.DEAD
	sounds.play_sound("dead")
	print("player died")
	if death_panel:
		death_panel.visible = true
	get_tree().paused = true

func update_hunger(delta):
	var interval = hunger_interval_normal
	if Input.get_action_strength("sprint") > 0:
		interval = hunger_interval_sprint
	hunger_timer += delta
	if hunger_timer >= interval:
		hunger_timer = 0
		current_hunger -= 1
		if current_hunger < 1:
			current_hunger = 0
			take_damage(5)
		current_hunger = clamp(current_hunger, 0, max_hunger)
		emit_signal("hunger_changed", current_hunger, max_hunger)

func get_input():
	direction = Vector2.ZERO
	direction.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	direction.y = Input.get_action_strength("down") - Input.get_action_strength("up")
	direction = direction.normalized()

func move_player(delta):
	var final_speed = move_speed
	if is_slowed:
		final_speed *= slow_multiplier
	if is_buffed:
		final_speed *= buff_multiplier

	if Input.get_action_strength("sprint") > 0:
		current_stamina -= 15 * delta
		if current_stamina < 10 or current_hunger <= 1:
			velocity = direction * final_speed
		else:
			velocity = direction * (final_speed + 100)
			was_sprinting = true
	else:
		velocity = direction * final_speed
		if was_sprinting:
			was_sprinting = false
			stamina_recovery()
		if !in_stamina_recovery:
			current_stamina += 30 * delta

	current_stamina = clamp(current_stamina, 0, max_stamina)
	emit_signal("stamina_usage", current_stamina, max_stamina)
	move_and_slide()

	if velocity.length() > 0 and !is_attacking and !is_stunned:
			sounds.play_sound("walk")
	else:
		sounds.stop_walk()

func stamina_recovery():
	if recovery_started:
		return
	recovery_started = true
	in_stamina_recovery = true
	await get_tree().create_timer(stamina_recovery_timer).timeout
	in_stamina_recovery = false
	recovery_started = false

func update_animation():
	update_attack_hitbox()
	if velocity == Vector2.ZERO:
		play_anim("idle")
		return
	if abs(velocity.x) > abs(velocity.y):
		if velocity.x > 0:
			facing_direction = Vector2.RIGHT
		else:
			facing_direction = Vector2.LEFT
			
		play_anim("walk_side")
		update_flip()
	else:
		if velocity.y > 0:
			facing_direction = Vector2.DOWN
			play_anim("walk_down")
		else:
			facing_direction = Vector2.UP
			play_anim("walk_up")

func play_anim(anim_name):
	if anim.current_animation != anim_name:
		anim.play(anim_name)

func update_flip():
	var flipped: bool = velocity.x < 0
	layer_body.flip_h    = flipped
	layer_hair.flip_h    = flipped
	layer_clothes.flip_h = flipped
	
func update_attack_hitbox():
	var flipped: bool = velocity.x < 0
	if state!=State.ATTACK:
		if velocity.y > 0 or state==State.IDLE:
			attack_hitbox.position = Vector2(-7, 13)
		elif velocity.y< 0:
			attack_hitbox.position = Vector2(-7, -11)
		elif flipped:
			attack_hitbox.position = Vector2(-16, 0)
		else:
			attack_hitbox.position = Vector2(0, 0)

func _process(_delta):
	update_held_item()
	throw()
	if Input.is_action_just_pressed("pick_up") and items_in_range.size() > 0:
		var item = items_in_range[0]
		var item_picked_up = item.collect()
		if not item_picked_up:
			return
		var added = false

		for i in range(inventory.size() - 1, -1, -1):
			if inventory[i] != null:
				var item_data = inventory[i]
				if item_data["item_id"] == item_picked_up["item_id"] and item_data["amount"] < MAX_STACK:
					item_data["amount"] += 1
					added = true
					break

		if not added:
			for i in range(inventory.size()):
				if inventory[i] == null:
					item_picked_up["amount"] = 1
					inventory[i] = item_picked_up
					added = true
					break
		if fasteq_ui:
			fasteq_ui.refresh(inventory)		
			
		if inventory_ui:
				inventory_ui.refresh(inventory)
		print(inventory)

func add_item(item):
	items_in_range.append(item)

func remove_item(item):
	items_in_range.erase(item)

# ─────────────────────────────────────────────
#  Wygląd postaci z pliku save
# ─────────────────────────────────────────────
func apply_appearance() -> void:
	if not FileAccess.file_exists("user://player_data.json"):
		return
	var f    := FileAccess.open("user://player_data.json", FileAccess.READ)
	var data  = JSON.parse_string(f.get_as_text())
	f.close()
	if not data is Dictionary:
		return

	var skin_colors := [
		Color(1.00, 0.85, 0.70),
		Color(0.87, 0.68, 0.50),
		Color(0.67, 0.45, 0.28),
		Color(0.45, 0.28, 0.14),
		Color(0.25, 0.15, 0.07),
	]
	var hair_colors := [
		Color(0.10, 0.07, 0.04),
		Color(0.35, 0.20, 0.08),
		Color(0.72, 0.52, 0.18),
		Color(0.75, 0.20, 0.08),
		Color(0.85, 0.85, 0.85),
		Color(0.50, 0.10, 0.70),
		Color(0.10, 0.40, 0.85),
	]

	var si: int = clampi(data.get("skin_index", 0), 0, skin_colors.size() - 1)
	var hi: int = clampi(data.get("hair_color",  0), 0, hair_colors.size() - 1)

	layer_body.modulate = skin_colors[si]
	layer_hair.modulate = hair_colors[hi]
