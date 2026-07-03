extends Node



const MAX_ANIMALS    := 100
const SPAWN_INTERVAL := 120.0  
const SPAWN_COUNT    := 2
const START_COUNT    := 50
const TILE_SIZE      := 16

const MAX_MONSTERS   := 70
const MONSTER_NIGHT_COUNT := 40 

@export var animal_scenes: Array[PackedScene] = [
	preload("res://Animals/Fox/Fox.tscn"),
	preload("res://Animals/Boar/Boar.tscn"),
	preload("res://Animals/Deer/Deer.tscn"),
	preload("res://Animals/Grouse/Grouse.tscn"),
	preload("res://Animals/Hare/Hare.tscn"),
]
@export var monster_scenes: Array[PackedScene] = [
	preload("res://Enemies/IceGolem/IceGolem.tscn"),
	preload("res://Enemies/Spirit_Wolf/EvilWolf.tscn"),
	preload("res://Enemies/BringerOfDeath/BringerOfDeath.tscn"),
]

const VALID_TERRAINS := [2, 3, 4]  

var spawn_timer: float = 0.0
var animals_node: Node2D = null
var world_ref: Node = null

var was_night: bool = false  


func _ready() -> void:
	add_to_group("animal_spawner")
	world_ref = get_tree().current_scene
	animals_node = world_ref.get_node_or_null("Objects")
	if animals_node == null:
		animals_node = world_ref

	await get_tree().create_timer(1.0).timeout
	_spawn_batch_animals(START_COUNT)


func _process(delta: float) -> void:
	# Zwierzęta co 2 minuty
	spawn_timer += delta
	if spawn_timer >= SPAWN_INTERVAL:
		spawn_timer = 0.0
		_spawn_batch_animals(SPAWN_COUNT)

	# Potwory — tylko raz na początku nocy
	var is_night := _is_night()
	if is_night and not was_night:
		_spawn_monsters_night()
	was_night = is_night


func _is_night() -> bool:
	var clock := get_tree().get_first_node_in_group("Clock")
	if clock == null:
		return false
	var day_counter := clock.get_node_or_null("day_counter")
	if day_counter == null:
		return false
	var h: int = day_counter.hours
	return h >= 22 or h < 6


func _spawn_monsters_night() -> void:
	if monster_scenes.is_empty():
		push_warning("AnimalSpawner: brak scen potworów!")
		return

	var current := get_tree().get_nodes_in_group("Enemies").size()
	var to_spawn := mini(MONSTER_NIGHT_COUNT, MAX_MONSTERS - current)

	for _i in range(to_spawn):
		var pos := _find_valid_position()
		if pos == Vector2.ZERO:
			continue
		var scene := monster_scenes[randi() % monster_scenes.size()]
		var monster: Node2D = scene.instantiate()
		animals_node.add_child(monster)
		monster.global_position = pos
	print("Noc: spawnowano %d potworów" % to_spawn)


func _spawn_batch_animals(count: int) -> void:
	if animal_scenes.is_empty():
		return
	var current := get_tree().get_nodes_in_group("Enemies").size()
	var to_spawn := mini(count, MAX_ANIMALS - current)
	for _i in range(to_spawn):
		var pos := _find_valid_position()
		if pos == Vector2.ZERO:
			continue
		var scene := animal_scenes[randi() % animal_scenes.size()]
		var animal: Node2D = scene.instantiate()
		animals_node.add_child(animal)
		animal.global_position = pos


func _find_valid_position() -> Vector2:
	for _attempt in range(100):
		var tx := randi_range(40, 460)
		var ty := randi_range(40, 460)
		if world_ref.has_method("_get_terrain"):
			var terrain: int = world_ref._get_terrain(tx, ty)
			if terrain in VALID_TERRAINS:
				var player := get_tree().get_first_node_in_group("player")
				
				var world_pos := Vector2(tx * TILE_SIZE + TILE_SIZE / 2,
										ty * TILE_SIZE + TILE_SIZE / 2)
				if player and player.global_position.distance_to(world_pos) < 200:
					continue
				return world_pos
	return Vector2.ZERO
