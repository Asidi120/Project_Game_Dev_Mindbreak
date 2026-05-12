class_name Player extends CharacterBody2D

var death_panel: Control
var clock: Control  
var hp_bar: TextureProgressBar
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
const MAX_STACK = 2 #maksymalna ilość w stacku
const MAX_SLOT = 18

#odwołanie do node ekwipunka ZMIENIĆ JEŚLI SIĘ PRZEENIESIE !!!!
@onready var inventory_ui = get_tree().current_scene.get_node("CanvasLayer/Control/CenterContainer/Inventory")

@onready var anim = $AnimationPlayer

# Warstwy sprite'a — sprite wskazuje na LayerBody żeby flip_h działał na wszystkich
@onready var sprite:          Sprite2D = $Layers/LayerBody
@onready var layer_body:      Sprite2D = $Layers/LayerBody
@onready var layer_hair:      Sprite2D = $Layers/LayerHair
@onready var layer_clothes:   Sprite2D = $Layers/LayerClothes

func _ready() -> void:
	var hud = get_tree().get_first_node_in_group("hud")
	if hud:
		death_panel = hud.get_node("DeathPanel")
		clock       = hud.get_node("Clock")
		hp_bar      = hud.get_node("PlayerBar/hp_bar")

@onready var sprite = $Sprite2D

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

func _ready():
	hp_bar.set_target(self)
	attack_hitbox.monitoring=false
	
	for i in range(MAX_SLOT):
		inventory.append(null)
	
func _physics_process(delta):
	if inventory_ui.visible: #blokuje playera jeśli ekwipunek otwarty
		return
	get_input()
	move_player(delta)
	update_animation()
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

func attack():
	state = State.ATTACK
	is_attacking = true
	attack_hitbox.monitoring = true
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
	print("Player hp:",current_hp)
	if current_hp<=0:
		die()

func heal(amount):
	current_hp += amount
	current_hp = clamp(current_hp, 0, max_hp)
	emit_signal("hp_changed", current_hp, max_hp)

func die():
	if state == State.DEAD:
		return
		
	state = State.DEAD
	print("player died")
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

func stamina_recovery():
	if recovery_started:
		return
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

func play_anim(anim_name):
	if anim.current_animation != anim_name:
		anim.play(anim_name)

func update_flip():
	# Flip na wszystkich warstwach jednocześnie
	var flipped: bool = velocity.x < 0
	layer_body.flip_h    = flipped
	layer_hair.flip_h    = flipped
	layer_clothes.flip_h = flipped

#func _process(delta):
	##Zbieranie itemów i dodawanie ich do ekwipunka wraz z ich ilością
	#if Input.is_action_just_pressed("pick_up") and items_in_range.size() > 0:
		#var item = items_in_range[0]  # bierze pierwszy
		#var item_picked_up = item.collect()
		#var amount = 0
		#var found = false
		#for i in range(inventory.size() - 1, -1, -1): #sprawdza liste od tyłu
			#if inventory[i] != null:
				#var item_data = inventory[i]
				#if item_data["item_id"] == item_picked_up["item_id"]: #jeśli znaleziono i mniej niż maxslot to dodaje amount
					#found = true
					#amount = item_data["amount"]
					#if amount < MAX_STACK:
						#item_data["amount"] += 1
					#break
		#if not found or amount == MAX_STACK: #jeśli nie znaleiono lub przekroczy max stack to nowy dodaje
			#for i in range(inventory.size()):
				#if inventory[i] == null:
					#inventory[i]={
						#"item_id": item_picked_up["item_id"],
						#"amount": 1,
						#"texture": item_picked_up["texture"]
					#}
					#break
		#
		#inventory_ui.refresh(inventory) #wywołanie odświeżenia ekwipunka z inventory
		#print(inventory)
func _process(delta):
	if Input.is_action_just_pressed("pick_up") and items_in_range.size() > 0:
		var item = items_in_range[0]
		var item_picked_up = item.collect()
		var added = false

		# 1. Spróbuj dodać do istniejącego stacka, który NIE jest pełny
		for i in range(inventory.size() - 1, -1, -1):
			if inventory[i] != null:
				var item_data = inventory[i]

				if item_data["item_id"] == item_picked_up["item_id"] and item_data["amount"] < MAX_STACK:
					item_data["amount"] += 1
					added = true
					break

		# 2. Jeśli nie udało się dodać do stacka, dodaj do pustego slota
		if not added:
			for i in range(inventory.size()):
				if inventory[i] == null:
					inventory[i] = {
						"item_id": item_picked_up["item_id"],
						"amount": 1,
						"texture": item_picked_up["texture"]
					}
					added = true
					break

		inventory_ui.refresh(inventory)
		print(inventory)


		
func add_item(item): #dodaje item do listy itemów w zasięgu
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
		Color(1.00, 0.85, 0.70),  # jasna
		Color(0.87, 0.68, 0.50),  # pszeniczna
		Color(0.67, 0.45, 0.28),  # oliwkowa
		Color(0.45, 0.28, 0.14),  # ciemna
		Color(0.25, 0.15, 0.07),  # bardzo ciemna
	]
	var hair_colors := [
		Color(0.10, 0.07, 0.04),  # czarne
		Color(0.35, 0.20, 0.08),  # brązowe
		Color(0.72, 0.52, 0.18),  # blond
		Color(0.75, 0.20, 0.08),  # rude
		Color(0.85, 0.85, 0.85),  # siwe
		Color(0.50, 0.10, 0.70),  # fioletowe
		Color(0.10, 0.40, 0.85),  # niebieskie
	]

	var si: int = clampi(data.get("skin_index", 0), 0, skin_colors.size() - 1)
	var hi: int = clampi(data.get("hair_color",  0), 0, hair_colors.size() - 1)

	layer_body.modulate  = skin_colors[si]
	layer_hair.modulate  = hair_colors[hi]
	# layer_clothes i layer_hat możesz też modulować gdy będziesz miał kolory ubrań
