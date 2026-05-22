extends Node2D

# ─────────────────────────────────────────────
#  Ustawienia świata
# ─────────────────────────────────────────────
const WORLD_WIDTH  := 200
const WORLD_HEIGHT := 200
const TILE_SIZE    := 16

# Progi biomów (szum 0.0 – 1.0)
const OCEAN_MAX    := 0.30
const BEACH_MAX    := 0.33
const PLAINS_MAX   := 0.55
const FOREST_MAX   := 0.70
const MOUNTAIN_MAX := 0.85

# ID terenów w Terrain Set 0
const TERRAIN_WATER    := 0
const TERRAIN_BEACH    := 1
const TERRAIN_GRASS    := 2
const TERRAIN_MOUNTAIN := 3

# ─────────────────────────────────────────────
#  Sceny obiektów
# ─────────────────────────────────────────────
const SCENE_FLOWER1   := preload("res://Scenes/Flowers/flower1.tscn")
const SCENE_FLOWER2   := preload("res://Scenes/Flowers/flower2.tscn")
const SCENE_FLOWER3   := preload("res://Scenes/Flowers/flower3.tscn")
const SCENE_FLOWER4   := preload("res://Scenes/Flowers/flower4.tscn")
const SCENE_FLOWER5   := preload("res://Scenes/Flowers/flower5.tscn")
const SCENE_SEASHELL1 := preload("res://Scenes/Items/seashell_1.tscn")
const SCENE_SEASHELL2 := preload("res://Scenes/Items/seashell_2.tscn")
const SCENE_WOOD      := preload("res://Scenes/StaticStructures/tree.tscn")
const SCENE_STONE     := preload("res://Scenes/StaticStructures/boulder.tscn")

# ─────────────────────────────────────────────
#  Node refs
# ─────────────────────────────────────────────
@onready var tile_map:      TileMapLayer = $TileMapLayer
@onready var objects:       Node2D       = $Objects
@onready var player:        Node2D       = $Player
@onready var loading_label: Label        = $UI/LoadingLabel

# ─────────────────────────────────────────────
#  Dane z pliku save
# ─────────────────────────────────────────────
var world_seed: int    = 0
var world_name: String = "Świat"

# ─────────────────────────────────────────────
#  Szumy
# ─────────────────────────────────────────────
var noise_height := FastNoiseLite.new()
var noise_detail := FastNoiseLite.new()
var noise_object := FastNoiseLite.new()

var terrain_cells := {}

func _ready() -> void:
	_load_save()
	_setup_noise()
	loading_label.text = "Generowanie świata \"%s\"…" % world_name
	call_deferred("_generate")

# ─────────────────────────────────────────────
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

# ─────────────────────────────────────────────
func _setup_noise() -> void:
	noise_height.noise_type      = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise_height.seed            = world_seed
	noise_height.frequency       = 0.004
	noise_height.fractal_octaves = 5

	noise_detail.noise_type = FastNoiseLite.TYPE_VALUE
	noise_detail.seed       = world_seed + 99
	noise_detail.frequency  = 0.15

	noise_object.noise_type = FastNoiseLite.TYPE_VALUE
	noise_object.seed       = world_seed + 777
	noise_object.frequency  = 0.2

# ─────────────────────────────────────────────
func _generate() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = world_seed

	for t in [TERRAIN_WATER, TERRAIN_BEACH, TERRAIN_GRASS, TERRAIN_MOUNTAIN]:
		terrain_cells[t] = []

	for y in range(WORLD_HEIGHT):
		for x in range(WORLD_WIDTH):
			var h       := _norm(noise_height.get_noise_2d(x, y))
			var terrain := _biome_terrain(h)
			terrain_cells[terrain].append(Vector2i(x, y))
			_try_object(x, y, h, rng)

		if y % 10 == 0:
			loading_label.text = "Generowanie… %d%%" % int(float(y) / WORLD_HEIGHT * 100)
			await get_tree().process_frame

	loading_label.text = "Łączenie biomów…"
	await get_tree().process_frame

	for terrain_id in terrain_cells:
		if terrain_cells[terrain_id].size() > 0:
			tile_map.set_cells_terrain_connect(
				terrain_cells[terrain_id],
				0,
				terrain_id,
				false
			)
		await get_tree().process_frame

	player.global_position = _find_spawn(rng)
	loading_label.visible  = false
	print("Świat \"%s\" gotowy! Seed: %d" % [world_name, world_seed])

# ─────────────────────────────────────────────
func _biome_terrain(h: float) -> int:
	if h < OCEAN_MAX:    return TERRAIN_WATER
	if h < BEACH_MAX:    return TERRAIN_BEACH
	if h < PLAINS_MAX:   return TERRAIN_GRASS
	if h < FOREST_MAX:   return TERRAIN_GRASS
	if h < MOUNTAIN_MAX: return TERRAIN_MOUNTAIN
	return TERRAIN_MOUNTAIN

# ─────────────────────────────────────────────
#  Spawning obiektów
# ─────────────────────────────────────────────
func _try_object(x: int, y: int, h: float, rng: RandomNumberGenerator) -> void:
	var d := _norm(noise_object.get_noise_2d(x, y))

	# ── PLAŻA — muszle ──────────────────────────
	if h >= OCEAN_MAX and h < BEACH_MAX:
		if d < 0.10:
			var scene = SCENE_SEASHELL1 if rng.randi() % 2 == 0 else SCENE_SEASHELL2
			_spawn_scene(scene, x, y)

	# ── RÓWNINY — kwiaty, drewno, kamienie ──────
	elif h >= BEACH_MAX and h < PLAINS_MAX:
		if d < 0.12:
			# Losowy kwiatek spośród 5
			var flowers = [SCENE_FLOWER1, SCENE_FLOWER2, SCENE_FLOWER3, SCENE_FLOWER4, SCENE_FLOWER5]
			_spawn_scene(flowers[rng.randi() % flowers.size()], x, y)
		elif d < 0.15:
			_spawn_scene(SCENE_WOOD, x, y)
		elif d < 0.17:
			_spawn_scene(SCENE_STONE, x, y)

	# ── LAS — dużo drewna i kwiatów ─────────────
	elif h >= PLAINS_MAX and h < FOREST_MAX:
		if d < 0.15:
			_spawn_scene(SCENE_WOOD, x, y)
		elif d < 0.19:
			var flowers = [SCENE_FLOWER1, SCENE_FLOWER2, SCENE_FLOWER3, SCENE_FLOWER4, SCENE_FLOWER5]
			_spawn_scene(flowers[rng.randi() % flowers.size()], x, y)

	# ── GÓRY — kamienie ─────────────────────────
	elif h >= FOREST_MAX and h < MOUNTAIN_MAX:
		if d < 0.12:
			_spawn_scene(SCENE_STONE, x, y)

func _spawn_scene(scene: PackedScene, tx: int, ty: int) -> void:
	var obj := scene.instantiate()
	obj.position = Vector2(
		tx * TILE_SIZE + TILE_SIZE / 2,
		ty * TILE_SIZE + TILE_SIZE / 2
	)
	obj.z_index = ty
	objects.add_child(obj)

# ─────────────────────────────────────────────
func _find_spawn(rng: RandomNumberGenerator) -> Vector2:
	for _i in range(500):
		var x := rng.randi_range(10, WORLD_WIDTH  - 10)
		var y := rng.randi_range(10, WORLD_HEIGHT - 10)
		var h := _norm(noise_height.get_noise_2d(x, y))
		if h > BEACH_MAX and h < PLAINS_MAX:
			return Vector2(x * TILE_SIZE + TILE_SIZE / 2,
						   y * TILE_SIZE + TILE_SIZE / 2)
	return Vector2(WORLD_WIDTH * TILE_SIZE / 2, WORLD_HEIGHT * TILE_SIZE / 2)

# ─────────────────────────────────────────────
func _norm(v: float) -> float:
	return (v + 1.0) * 0.5
