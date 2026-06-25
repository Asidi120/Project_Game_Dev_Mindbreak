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

const SCENE_FLOWER1      := preload("res://Scenes/Flowers/flower1.tscn")
const SCENE_FLOWER2      := preload("res://Scenes/Flowers/flower2.tscn")
const SCENE_FLOWER3      := preload("res://Scenes/Flowers/flower3.tscn")
const SCENE_FLOWER4      := preload("res://Scenes/Flowers/flower4.tscn")
const SCENE_FLOWER5      := preload("res://Scenes/Flowers/flower5.tscn")
const SCENE_SEASHELL1    := preload("res://Scenes/Items/seashell_1.tscn")
const SCENE_SEASHELL2    := preload("res://Scenes/Items/seashell_2.tscn")
const SCENE_TREE         := preload("res://Scenes/StaticStructures/tree.tscn")
const SCENE_TREE_SPRUCE  := preload("res://Scenes/StaticStructures/tree_spruce.tscn")
const SCENE_BOULDER      := preload("res://Scenes/StaticStructures/boulder.tscn")
const SCENE_BUSH         := preload("res://Scenes/StaticStructures/bush.tscn")
const SCENE_BUSH2        := preload("res://Scenes/StaticStructures/bush_2.tscn")
const SCENE_COPPER       := preload("res://Scenes/StaticStructures/copper_node.tscn")
const SCENE_IRON         := preload("res://Scenes/StaticStructures/iron_node.tscn")
const SCENE_GOLD         := preload("res://Scenes/StaticStructures/gold_node.tscn")
const SCENE_DIAMOND      := preload("res://Scenes/StaticStructures/diamond_node.tscn")

@export var cave_scene_path:  String = "res://cave.tscn"
@export var house_scene_path: String = "res://house.tscn"

@onready var tile_map:      TileMapLayer = $TileMapLayer
@onready var objects:       Node2D       = $Objects
@onready var player:        Node2D       = $Objects/Player
@onready var loading_label: Label        = $UI/LoadingLabel

var world_seed: int    = 0
var world_name: String = "Świat"

var noise_height  := FastNoiseLite.new()
var noise_warp    := FastNoiseLite.new()
var noise_warp2   := FastNoiseLite.new()
var noise_temp    := FastNoiseLite.new()
var noise_cluster := FastNoiseLite.new()
var noise_scatter := FastNoiseLite.new()
var noise_rare    := FastNoiseLite.new()

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

	# Szum klastrów — tworzy naturalne skupiska obiektów
	noise_cluster.noise_type      = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise_cluster.seed            = world_seed + 777
	noise_cluster.frequency       = 0.15
	noise_cluster.fractal_octaves = 2

	# Szum rozproszenia — małe lokalne różnice (zapobiega rzędom)
	noise_scatter.noise_type = FastNoiseLite.TYPE_VALUE
	noise_scatter.seed       = world_seed + 1337
	noise_scatter.frequency  = 0.35

	# Szum rzadkich obiektów (rudy, diamenty)
	noise_rare.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise_rare.seed       = world_seed + 5555
	noise_rare.frequency  = 0.25


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

	# Oblicz pozycję domku przed generacją żeby wykluczyć obszar wokół niego
	house_pos = _find_spawn_for_house()

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
	_spawn_house()

	player.global_position = _find_spawn_for_house() + Vector2(0, 50)

	if SceneTransition.return_scene == "res://Player/word.tscn" and SceneTransition.return_position != Vector2.ZERO:
		player.global_position = SceneTransition.return_position
		SceneTransition.return_position = Vector2.ZERO
		SceneTransition.return_scene = ""

	if SceneTransition.saved_hp != 200 or SceneTransition.saved_inventory.size() > 0:
		player.reinitialize()

	loading_label.visible = false
	WorldStateManager.restore_scene(get_tree().current_scene.scene_file_path)
	var saver := get_tree().get_first_node_in_group("world_saver")
	if saver and saver.has_method("save_game"):
		saver.save_game()
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
	cave_pos = cave.position
	print("Jaskinia: kafelek %s, pozycja %s" % [tile, cave.position])


func _find_spawn_for_house() -> Vector2:
	var rng_house := RandomNumberGenerator.new()
	rng_house.seed = world_seed + 9999
	for _i in range(1000):
		var x := rng_house.randi_range(60, WORLD_WIDTH - 60)
		var y := rng_house.randi_range(60, WORLD_HEIGHT - 60)
		var t := _get_terrain(x, y)
		if t == TERRAIN_GRASS or t == TERRAIN_FOREST:
			return Vector2(x * TILE_SIZE + TILE_SIZE / 2,
						   y * TILE_SIZE + TILE_SIZE / 2)
	return Vector2(WORLD_WIDTH * TILE_SIZE / 2, WORLD_HEIGHT * TILE_SIZE / 2)


func _spawn_house() -> void:
	if not ResourceLoader.exists(house_scene_path):
		push_warning("Brak sceny domku: %s" % house_scene_path)
		return
	var house_scene := load(house_scene_path)
	var house: Node2D = house_scene.instantiate()
	house.position = _find_spawn_for_house()
	objects.add_child(house)
	house_pos = house.position
	print("Domek: pozycja %s" % house.position)


var house_pos: Vector2 = Vector2.ZERO
var cave_pos:  Vector2 = Vector2.ZERO

func _try_object(x: int, y: int, terrain: int, rng: RandomNumberGenerator) -> void:
	# Nie stawiaj nic zbyt blisko domku lub jaskini
	var world_pos := Vector2(x * TILE_SIZE + TILE_SIZE / 2, y * TILE_SIZE + TILE_SIZE / 2)
	if house_pos != Vector2.ZERO and world_pos.distance_to(house_pos) < 80:
		return
	if cave_pos != Vector2.ZERO and world_pos.distance_to(cave_pos) < 80:
		return

	var cluster := _norm(noise_cluster.get_noise_2d(float(x), float(y)))
	var scatter := _norm(noise_scatter.get_noise_2d(float(x) * 2.3, float(y) * 2.3))
	var rare    := _norm(noise_rare.get_noise_2d(float(x), float(y)))

	match terrain:
		TERRAIN_BEACH:
			# Muszle — od czasu do czasu
			if cluster > 0.45 and cluster < 0.48 and scatter > 0.45 and scatter < 0.55:
				var scene = SCENE_SEASHELL1 if rng.randi() % 2 == 0 else SCENE_SEASHELL2
				_spawn_scene(scene, x, y)
			# Skały na plaży — rzadko
			elif cluster > 0.80 and cluster < 0.82 and scatter > 0.80 and scatter < 0.82:
				_spawn_scene(SCENE_BOULDER, x, y)

		TERRAIN_GRASS:
			# Kwiaty
			if cluster > 0.55 and cluster < 0.58 and scatter > 0.60 and scatter < 0.75:
				var flowers = [SCENE_FLOWER1, SCENE_FLOWER2, SCENE_FLOWER3, SCENE_FLOWER4, SCENE_FLOWER5]
				_spawn_scene(flowers[rng.randi() % flowers.size()], x, y)
			# Krzaki — trochę mniej
			elif cluster > 0.64 and cluster < 0.67 and scatter > 0.60 and scatter < 0.68:
				var bush = SCENE_BUSH if rng.randi() % 2 == 0 else SCENE_BUSH2
				_spawn_scene(bush, x, y)
			# Drzewa — trochę częściej
			elif cluster > 0.70 and cluster < 0.75 and scatter > 0.70 and scatter < 0.75:
				_spawn_scene(SCENE_TREE, x, y)
			# Skały — trochę częściej
			elif cluster > 0.82 and cluster < 0.86 and scatter > 0.82 and scatter < 0.86:
				_spawn_scene(SCENE_BOULDER, x, y)

		TERRAIN_FOREST:
			# Drzewa — więcej, szerszy zakres
			if cluster > 0.40 and cluster < 0.48 and scatter > 0.40 and scatter < 0.48:
				var tree = SCENE_TREE if rng.randi() % 2 == 0 else SCENE_TREE_SPRUCE
				_spawn_scene(tree, x, y)
			# Kwiaty
			elif cluster > 0.60 and cluster < 0.63 and scatter > 0.68 and scatter < 0.72:
				var flowers = [SCENE_FLOWER1, SCENE_FLOWER2, SCENE_FLOWER3, SCENE_FLOWER4, SCENE_FLOWER5]
				_spawn_scene(flowers[rng.randi() % flowers.size()], x, y)
			# Krzaki
			elif cluster > 0.72 and cluster < 0.74 and scatter > 0.55 and scatter < 0.58:
				var bush = SCENE_BUSH if rng.randi() % 2 == 0 else SCENE_BUSH2
				_spawn_scene(bush, x, y)

		TERRAIN_MOUNTAIN:
			# Skały — odrobinę mniej
			if cluster > 0.52 and cluster < 0.57 and scatter > 0.52 and scatter < 0.57:
				_spawn_scene(SCENE_BOULDER, x, y)
			# Jodły
			elif cluster > 0.62 and cluster < 0.66 and scatter > 0.62 and scatter < 0.66:
				_spawn_scene(SCENE_TREE_SPRUCE, x, y)
			# Copper — najczęstszy
			elif rare > 0.72 and rare < 0.724:
				_spawn_scene(SCENE_COPPER, x, y)
			# Iron — rzadszy
			elif rare > 0.80 and rare < 0.803:
				_spawn_scene(SCENE_IRON, x, y)
			# Gold — rzadki
			elif rare > 0.87 and rare < 0.872:
				_spawn_scene(SCENE_GOLD, x, y)
			# Diamond — bardzo rzadki
			elif rare > 0.93 and rare < 0.932:
				_spawn_scene(SCENE_DIAMOND, x, y)


func _spawn_scene(scene: PackedScene, tx: int, ty: int) -> void:
	var obj := scene.instantiate()
	obj.position = Vector2(
		tx * TILE_SIZE + TILE_SIZE / 2,
		ty * TILE_SIZE + TILE_SIZE / 2
	)
	#obj.z_index = ty
	objects.add_child(obj)


func _find_spawn(rng: RandomNumberGenerator) -> Vector2:
	for _i in range(1000):
		var x := rng.randi_range(60, WORLD_WIDTH - 60)
		var y := rng.randi_range(60, WORLD_HEIGHT - 60)
		var t := _get_terrain(x, y)
		if t == TERRAIN_GRASS:
			return Vector2(x * TILE_SIZE + TILE_SIZE / 2,
						   y * TILE_SIZE + TILE_SIZE / 2)
	return Vector2(WORLD_WIDTH * TILE_SIZE / 2, WORLD_HEIGHT * TILE_SIZE / 2)


func _find_spawn_cave(_rng: RandomNumberGenerator) -> Vector2:
	if cave_world_pos != Vector2.ZERO:
		return cave_world_pos + Vector2(0, 32)
	return Vector2(WORLD_WIDTH * TILE_SIZE / 2, WORLD_HEIGHT * TILE_SIZE / 2)


func _norm(v: float) -> float:
	return (v + 1.0) * 0.5
