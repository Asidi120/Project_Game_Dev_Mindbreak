extends Node2D

# ─────────────────────────────────────────────
#  Ustawienia świata
# ─────────────────────────────────────────────
const WORLD_WIDTH  := 200   # kafelki w poziomie
const WORLD_HEIGHT := 200   # kafelki w pionie
const TILE_SIZE    := 16    # rozmiar kafelka w pikselach

# Progi biome (szum 0.0 – 1.0)
const OCEAN_MAX    := 0.30
const BEACH_MAX    := 0.38
const PLAINS_MAX   := 0.55
const FOREST_MAX   := 0.70
const MOUNTAIN_MAX := 0.85
# powyżej 0.85 → śnieg

# ID kafelków w TileSet (kolumna w atlasie, licząc od 0)
const TILE_OCEAN    := Vector2i(0, 0)
const TILE_BEACH    := Vector2i(1, 0)
const TILE_PLAINS   := Vector2i(2, 0)
const TILE_FOREST   := Vector2i(3, 0)
const TILE_MOUNTAIN := Vector2i(4, 0)
const TILE_SNOW     := Vector2i(5, 0)

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
var world_seed:  int    = 0
var world_name:  String = "Świat"

# ─────────────────────────────────────────────
#  Szumy
# ─────────────────────────────────────────────
var noise_height := FastNoiseLite.new()
var noise_detail := FastNoiseLite.new()

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

# ─────────────────────────────────────────────
func _generate() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = world_seed

	for y in range(WORLD_HEIGHT):
		for x in range(WORLD_WIDTH):
			var h     := _norm(noise_height.get_noise_2d(x, y))
			var atlas := _biome_tile(h)
			tile_map.set_cell(Vector2i(x, y), 0, atlas)
			_try_object(x, y, h, rng)

		# odświeżaj UI co 10 rzędów
		if y % 10 == 0:
			loading_label.text = "Generowanie… %d%%" % int(float(y) / WORLD_HEIGHT * 100)
			await get_tree().process_frame

	# Ustaw gracza na bezpiecznym miejscu
	player.global_position = _find_spawn(rng)
	loading_label.visible  = false
	print("Świat \"%s\" gotowy! Seed: %d" % [world_name, world_seed])

# ─────────────────────────────────────────────
func _biome_tile(h: float) -> Vector2i:
	if h < OCEAN_MAX:    return TILE_OCEAN
	if h < BEACH_MAX:    return TILE_BEACH
	if h < PLAINS_MAX:   return TILE_PLAINS
	if h < FOREST_MAX:   return TILE_FOREST
	if h < MOUNTAIN_MAX: return TILE_MOUNTAIN
	return TILE_SNOW

# ─────────────────────────────────────────────
#  Obiekty — na razie proste ColorRect jako placeholder
#  Zamień na swoje sceny gdy będziesz miał grafiki
# ─────────────────────────────────────────────
func _try_object(x: int, y: int, h: float, rng: RandomNumberGenerator) -> void:
	# Tylko na lądzie
	if h < BEACH_MAX or h > MOUNTAIN_MAX:
		return

	var d := _norm(noise_detail.get_noise_2d(x * 2.3, y * 2.3))

	# Las — dużo drzew
	if h > PLAINS_MAX and h < FOREST_MAX:
		if d < 0.12:
			_place_rect(x, y, Color(0.15, 0.35, 0.10), Vector2(6, 10))  # drzewo
		elif d < 0.16:
			_place_rect(x, y, Color(0.45, 0.30, 0.15), Vector2(8, 6))   # krzak

	# Równiny — rzadkie drzewa i skały
	elif h > BEACH_MAX and h < PLAINS_MAX:
		if d < 0.04:
			_place_rect(x, y, Color(0.15, 0.35, 0.10), Vector2(6, 10))  # drzewo
		elif d < 0.07:
			_place_rect(x, y, Color(0.55, 0.55, 0.55), Vector2(8, 7))   # skała

	# Góry — dużo skał
	elif h > FOREST_MAX and h < MOUNTAIN_MAX:
		if d < 0.15:
			_place_rect(x, y, Color(0.55, 0.55, 0.55), Vector2(10, 8))  # skała

func _place_rect(tx: int, ty: int, color: Color, size: Vector2) -> void:
	var r        := ColorRect.new()
	r.color       = color
	r.size        = size
	r.position    = Vector2(tx * TILE_SIZE + (TILE_SIZE - size.x) / 2,
							ty * TILE_SIZE + TILE_SIZE - size.y)
	r.z_index     = ty   # sortowanie głębokości
	objects.add_child(r)

# ─────────────────────────────────────────────
func _find_spawn(rng: RandomNumberGenerator) -> Vector2:
	# Szukaj bezpiecznego miejsca na równinach
	for _i in range(500):
		var x := rng.randi_range(10, WORLD_WIDTH  - 10)
		var y := rng.randi_range(10, WORLD_HEIGHT - 10)
		var h := _norm(noise_height.get_noise_2d(x, y))
		if h > BEACH_MAX and h < PLAINS_MAX:
			return Vector2(x * TILE_SIZE + TILE_SIZE / 2,
						   y * TILE_SIZE + TILE_SIZE / 2)
	# Fallback — środek świata
	return Vector2(WORLD_WIDTH * TILE_SIZE / 2, WORLD_HEIGHT * TILE_SIZE / 2)

# ─────────────────────────────────────────────
func _norm(v: float) -> float:
	return (v + 1.0) * 0.5
