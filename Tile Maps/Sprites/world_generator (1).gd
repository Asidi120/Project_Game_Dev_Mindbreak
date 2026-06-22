extends Node2D

const WORLD_WIDTH  := 500
const WORLD_HEIGHT := 500
const TILE_SIZE    := 16

const OCEAN_MAX := 0.20
const BEACH_MAX := 0.28
const GRASS_MAX := 0.39   

const TERRAIN_WATER    := 0
const TERRAIN_BEACH    := 1
const TERRAIN_GRASS    := 2
const TERRAIN_FOREST   := 3
const TERRAIN_MOUNTAIN := 4

const BIOME_COUNTS := {
	TERRAIN_MOUNTAIN: 5,
	TERRAIN_FOREST:   12,
	TERRAIN_GRASS:    18,
}

const SCENE_FLOWER1   := preload("res://Scenes/Flowers/flower1.tscn")
const SCENE_FLOWER2   := preload("res://Scenes/Flowers/flower2.tscn")
const SCENE_FLOWER3   := preload("res://Scenes/Flowers/flower3.tscn")
const SCENE_FLOWER4   := preload("res://Scenes/Flowers/flower4.tscn")
const SCENE_FLOWER5   := preload("res://Scenes/Flowers/flower5.tscn")
const SCENE_SEASHELL1 := preload("res://Scenes/Items/seashell_1.tscn")
const SCENE_SEASHELL2 := preload("res://Scenes/Items/seashell_2.tscn")
const SCENE_TREE      := preload("res://Scenes/StaticStructures/tree.tscn")
const SCENE_BOULDER   := preload("res://Scenes/StaticStructures/boulder.tscn")

@export var cave_scene_path: String = "res://cave.tscn"
@export var house_scene_path: String = "res://house.tscn"

@onready var tile_map:      TileMapLayer = $TileMapLayer
@onready var objects:       Node2D       = $Objects
@onready var player:        Node2D       = $Player
@onready var loading_label: Label        = $UI/LoadingLabel


var world_seed: int    = 0
var world_name: String = "Świat"


var noise_height  := FastNoiseLite.new()
var noise_warp    := FastNoiseLite.new()
var noise_warp2   := FastNoiseLite.new()
var noise_temp    := FastNoiseLite.new()
var noise_cluster := FastNoiseLite.new()
var noise_scatter := FastNoiseLite.new()

var biome_points:  Array = []
var terrain_cells := {}

var mountain_tiles: Array[Vector2i] = []
var cave_world_pos: Vector2 = Vector2.ZERO


func _ready() -> void:
	_load_save()
	_setup_noise()
	loading_label.text = "Generowanie świata \"%s\"…" % world_name
	call_deferred("_generate")


func _load_save() -> void:
	if not FileAccess.file_exists("user://player_data.json"):
		world_seed = randi()
		return
	var f    := FileAccess.open("user://player_data.json", FileAccess.READ)
	var data  = JSON.parse_string(f.get_as_text())
	f.close()
	if data is Dictionary:
		world_seed = data.get("world_seed", randi())
		world_name = data.get("world_name", "Świat")


func _setup_noise() -> void:
	noise_height.noise_type      = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise_height.seed            = world_seed
	noise_height.frequency       = 0.0025
	noise_height.fractal_octaves = 6

	noise_warp.noise_type  = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise_warp.seed        = world_seed + 42
	noise_warp.frequency   = 0.008

	noise_warp2.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise_warp2.seed       = world_seed + 84
	noise_warp2.frequency  = 0.015

	noise_temp.noise_type      = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise_temp.seed            = world_seed + 3333
	noise_temp.frequency       = 0.004
	noise_temp.fractal_octaves = 3

	noise_cluster.noise_type      = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise_cluster.seed            = world_seed + 777
	noise_cluster.frequency       = 0.04
	noise_cluster.fractal_octaves = 2

	noise_scatter.noise_type = FastNoiseLite.TYPE_VALUE
	noise_scatter.seed       = world_seed + 1337
	noise_scatter.frequency  = 0.25


func _generate_biome_points(rng: RandomNumberGenerator) -> void:
	biome_points.clear()
	var margin := 60
	var land_w  := WORLD_WIDTH  - margin * 2
	var land_h  := WORLD_HEIGHT - margin * 2
	var order   := [TERRAIN_GRASS, TERRAIN_FOREST, TERRAIN_MOUNTAIN]

	for biome in order:
		var count: int = BIOME_COUNTS[biome]
		for _i in range(count):
			var placed   := false
			var attempts := 0
			while not placed and attempts < 150:
				attempts += 1
				var px  := rng.randi_range(margin, margin + land_w)
				var py  := rng.randi_range(margin, margin + land_h)
				var pos := Vector2(px, py)
				if _is_valid_position(pos, biome):
					biome_points.append({"pos": pos, "biome": biome})
					placed = true
			if not placed:
				var px := rng.randi_range(margin, margin + land_w)
				var py := rng.randi_range(margin, margin + land_h)
				biome_points.append({"pos": Vector2(px, py), "biome": biome})


func _is_valid_position(pos: Vector2, biome: int) -> bool:
	var min_same := 140.0
	for p in biome_points:
		var dist: float = pos.distance_to(p["pos"])
		if p["biome"] == biome and dist < min_same:
			return false
	return true


func _get_land_biome(x: int, y: int) -> int:
	if biome_points.is_empty():
		return TERRAIN_GRASS

	var wx1 := noise_warp.get_noise_2d(x,       y)        * 28.0
	var wy1 := noise_warp.get_noise_2d(x + 300, y)        * 28.0
	var wx2 := noise_warp2.get_noise_2d(x,       y + 300) * 14.0
	var wy2 := noise_warp2.get_noise_2d(x + 600, y)       * 14.0
	var sp  := Vector2(x + wx1 + wx2, y + wy1 + wy2)

	var best_dist  := INF
	var best_biome := TERRAIN_GRASS
	for p in biome_points:
		var d: float = sp.distance_to(p["pos"])
		if d < best_dist:
			best_dist  = d
			best_biome = p["biome"]

	if best_biome != TERRAIN_MOUNTAIN:
		var temp := _norm(noise_temp.get_noise_2d(x, y))
		if best_biome == TERRAIN_GRASS and temp < 0.22:
			best_biome = TERRAIN_FOREST
		elif best_biome == TERRAIN_FOREST and temp > 0.78:
			best_biome = TERRAIN_GRASS

	return best_biome


func _island_gradient(x: int, y: int) -> float:
	var cx := WORLD_WIDTH  / 2.0
	var cy := WORLD_HEIGHT / 2.0
	var dx: float = abs(x - cx) / cx
	var dy: float = abs(y - cy) / cy
	var dist := sqrt(dx * dx + dy * dy) / sqrt(2.0)
	return lerp(0.35, -0.60, smoothstep(0.35, 0.78, dist))


func _get_terrain(x: int, y: int) -> int:
	var h := _norm(noise_height.get_noise_2d(x, y)) + _island_gradient(x, y)
	h = clamp(h, 0.0, 1.0)
	if h < OCEAN_MAX:
		return TERRAIN_WATER
	if h < BEACH_MAX:
		return TERRAIN_BEACH
	if h < GRASS_MAX:
		return TERRAIN_GRASS
	return _get_land_biome(x, y)


func _generate() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = world_seed

	loading_label.text = "Tworzenie biomów…"
	await get_tree().process_frame
	_generate_biome_points(rng)

	for t in [TERRAIN_WATER, TERRAIN_BEACH, TERRAIN_GRASS, TERRAIN_FOREST, TERRAIN_MOUNTAIN]:
		terrain_cells[t] = []

	mountain_tiles.clear()

	for y in range(WORLD_HEIGHT):
		for x in range(WORLD_WIDTH):
			var terrain := _get_terrain(x, y)
			terrain_cells[terrain].append(Vector2i(x, y))
			if terrain == TERRAIN_MOUNTAIN:
				mountain_tiles.append(Vector2i(x, y))
			_try_object(x, y, terrain, rng)

		if y % 20 == 0:
			loading_label.text = ".... %d%%" % int(float(y) / WORLD_HEIGHT * 100)
			await get_tree().process_frame

	loading_label.text = "………………"
	await get_tree().process_frame

	for t in [TERRAIN_WATER, TERRAIN_BEACH, TERRAIN_GRASS, TERRAIN_FOREST, TERRAIN_MOUNTAIN]:
		if terrain_cells[t].size() > 0:
			tile_map.set_cells_terrain_connect(terrain_cells[t], 0, t, false)
		await get_tree().process_frame

	_spawn_cave(rng)

	player.global_position = _find_spawn(rng)
	_spawn_house(player.global_position)
	loading_label.visible  = false
	WorldStateManager.restore_scene(get_tree().current_scene.scene_file_path)
	print("Świat \"%s\" gotowy! Seed: %d" % [world_name, world_seed])


func _spawn_cave(rng: RandomNumberGenerator) -> void:
	if mountain_tiles.is_empty():
		push_warning("Brak kafelków gór — jaskinia nie zostanie umieszczona")
		return

	if not ResourceLoader.exists(cave_scene_path):
		push_warning("Brak sceny jaskini: %s" % cave_scene_path)
		return

	var idx:  int      = rng.randi_range(0, mountain_tiles.size() - 1)
	var tile: Vector2i = mountain_tiles[idx]

	var cave_scene := load(cave_scene_path)
	var cave: Node2D = cave_scene.instantiate()
	cave.position = Vector2(
		tile.x * TILE_SIZE + TILE_SIZE / 2,
		tile.y * TILE_SIZE + TILE_SIZE / 2
	)
	objects.add_child(cave)
	cave_world_pos = cave.position
	print("Jaskinia: kafelek %s, pozycja %s" % [tile, cave.position])

func _spawn_house(spawn_pos: Vector2) -> void:
	if not ResourceLoader.exists(house_scene_path):
		push_warning("Brak sceny domku: %s" % house_scene_path)
		return
	var house_scene := load(house_scene_path)
	var house: Node2D = house_scene.instantiate()
	house.position = spawn_pos + Vector2(TILE_SIZE * 4, 0)
	objects.add_child(house)
	print("Domek: pozycja %s" % house.position)
	


func _try_object(x: int, y: int, terrain: int, rng: RandomNumberGenerator) -> void:
	var cluster := _norm(noise_cluster.get_noise_2d(x, y))
	var scatter := _norm(noise_scatter.get_noise_2d(x, y))
	var density := cluster * scatter

	match terrain:
		TERRAIN_BEACH:
			if density > 0.88:
				_spawn_scene(SCENE_BOULDER, x, y)
			elif density < 0.04:
				var scene = SCENE_SEASHELL1 if rng.randi() % 2 == 0 else SCENE_SEASHELL2
				_spawn_scene(scene, x, y)
		TERRAIN_GRASS:
			if density > 0.72:
				var flowers = [SCENE_FLOWER1, SCENE_FLOWER2, SCENE_FLOWER3, SCENE_FLOWER4, SCENE_FLOWER5]
				_spawn_scene(flowers[rng.randi() % flowers.size()], x, y)
			elif density > 0.66 and density < 0.685:
				_spawn_scene(SCENE_TREE, x, y)
			elif density > 0.60 and density < 0.615:
				_spawn_scene(SCENE_BOULDER, x, y)
		TERRAIN_FOREST:
			if density > 0.55:
				_spawn_scene(SCENE_TREE, x, y)
			elif density > 0.46 and density < 0.52:
				var flowers = [SCENE_FLOWER1, SCENE_FLOWER2, SCENE_FLOWER3, SCENE_FLOWER4, SCENE_FLOWER5]
				_spawn_scene(flowers[rng.randi() % flowers.size()], x, y)
		TERRAIN_MOUNTAIN:
			if density > 0.50:
				_spawn_scene(SCENE_BOULDER, x, y)


func _spawn_scene(scene: PackedScene, tx: int, ty: int) -> void:
	var obj := scene.instantiate()
	obj.position = Vector2(
		tx * TILE_SIZE + TILE_SIZE / 2,
		ty * TILE_SIZE + TILE_SIZE / 2
	)
	obj.z_index = ty
	objects.add_child(obj)


func _find_spawn(rng: RandomNumberGenerator) -> Vector2:
	for _i in range(1000):
		var x := rng.randi_range(60, WORLD_WIDTH  - 60)
		var y := rng.randi_range(60, WORLD_HEIGHT - 60)
		var t := _get_terrain(x, y)
		if t == TERRAIN_GRASS:
			return Vector2(x * TILE_SIZE + TILE_SIZE / 2,
						   y * TILE_SIZE + TILE_SIZE / 2)
	return Vector2(WORLD_WIDTH * TILE_SIZE / 2, WORLD_HEIGHT * TILE_SIZE / 2)
	
func _find_spawn_cave(rng: RandomNumberGenerator) -> Vector2:
	if cave_world_pos != Vector2.ZERO:
		return cave_world_pos + Vector2(0, 32)
	return Vector2(WORLD_WIDTH * TILE_SIZE / 2, WORLD_HEIGHT * TILE_SIZE / 2)



func _norm(v: float) -> float:
	return (v + 1.0) * 0.5
