extends Node2D

# ─────────────────────────────────────────────
#  Stałe generatora
# ─────────────────────────────────────────────
const TILE_SIZE        := 16          # piksele
const CHUNK_SIZE       := 16          # kafelki na chunk
const WORLD_WIDTH      := 200         # chunki w poziomie
const WORLD_HEIGHT     := 200         # chunki w pionie

const TREE_CHANCE      := 0.06        # 6% szansa drzewa na kafelek
const ROCK_CHANCE      := 0.03        # 3% szansa skały
const FLOWER_CHANCE    := 0.04        # 4% kwiatki

# Progi biome (wartość szumu 0.0–1.0)
const BIOME_OCEAN      := 0.30
const BIOME_BEACH      := 0.37
const BIOME_PLAINS     := 0.55
const BIOME_FOREST     := 0.70
const BIOME_MOUNTAIN   := 0.85
# powyżej 0.85 → śnieg / szczyty

enum Biome { OCEAN, BEACH, PLAINS, FOREST, MOUNTAIN, SNOW }

# ─────────────────────────────────────────────
#  Dane gracza wczytane z pliku save
# ─────────────────────────────────────────────
var world_seed:   int    = 0
var world_name:   String = "Świat"
var player_name:  String = "Gracz"

# ─────────────────────────────────────────────
#  Node refs — dopasuj do swojej sceny world.tscn
# ─────────────────────────────────────────────
@onready var tile_map:      TileMap   = $TileMap        # Twoja TileMap
@onready var objects_layer: Node2D    = $Objects        # Node2D na drzewa/skały
@onready var player_node:   Node2D    = $Player         # Twój Player
@onready var loading_label: Label     = $UI/LoadingLabel

# ─────────────────────────────────────────────
#  Szumy
# ─────────────────────────────────────────────
var noise_height := FastNoiseLite.new()
var noise_temp   := FastNoiseLite.new()
var noise_detail := FastNoiseLite.new()

# ─────────────────────────────────────────────
#  ID kafelków w TileMap — dostosuj do swojego Atlas
#  Format: [atlas_id, Vector2i(kolumna, rząd)]
# ─────────────────────────────────────────────
const TILES := {
	Biome.OCEAN:    [0, Vector2i(0, 0)],
	Biome.BEACH:    [0, Vector2i(1, 0)],
	Biome.PLAINS:   [0, Vector2i(2, 0)],
	Biome.FOREST:   [0, Vector2i(3, 0)],
	Biome.MOUNTAIN: [0, Vector2i(4, 0)],
	Biome.SNOW:     [0, Vector2i(5, 0)],
}

# ─────────────────────────────────────────────
#  Sceny obiektów — zastąp własnymi
# ─────────────────────────────────────────────
const TREE_SCENES := [
	"res://Objects/tree_oak.tscn",
	"res://Objects/tree_pine.tscn",
]
const ROCK_SCENES := [
	"res://Objects/rock_small.tscn",
	"res://Objects/rock_large.tscn",
]
const FLOWER_SCENES := [
	"res://Objects/flower_red.tscn",
	"res://Objects/flower_yellow.tscn",
]

# ─────────────────────────────────────────────
func _ready() -> void:
	_load_player_data()
	_setup_noise()
	loading_label.text = "Generowanie świata \"%s\"…" % world_name
	# Użyj call_deferred żeby UI zdążyło się odświeżyć
	call_deferred("_generate_world")

# ─────────────────────────────────────────────
#  Wczytaj dane postaci
# ─────────────────────────────────────────────
func _load_player_data() -> void:
	if not FileAccess.file_exists("user://player_data.json"):
		push_warning("WorldGenerator: brak pliku player_data.json, używam domyślnych.")
		return
	var f := FileAccess.open("user://player_data.json", FileAccess.READ)
	var txt := f.get_as_text()
	f.close()
	var data = JSON.parse_string(txt)
	if data is Dictionary:
		world_seed  = data.get("world_seed",  randi())
		world_name  = data.get("world_name",  "Świat")
		player_name = data.get("player_name", "Gracz")
		# Tutaj możesz też wczytać wygląd i zastosować go do sprite'a gracza

# ─────────────────────────────────────────────
#  Konfiguracja szumów
# ─────────────────────────────────────────────
func _setup_noise() -> void:
	# Główny szum wysokości (biomy)
	noise_height.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise_height.seed       = world_seed
	noise_height.frequency  = 0.003
	noise_height.fractal_octaves = 5

	# Szum temperatury (dla wariantu biome)
	noise_temp.noise_type = FastNoiseLite.TYPE_PERLIN
	noise_temp.seed       = world_seed + 1337
	noise_temp.frequency  = 0.005

	# Drobny szum do rozmieszczania obiektów
	noise_detail.noise_type = FastNoiseLite.TYPE_VALUE
	noise_detail.seed       = world_seed + 42
	noise_detail.frequency  = 0.1

# ─────────────────────────────────────────────
#  Główna generacja
# ─────────────────────────────────────────────
func _generate_world() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = world_seed

	var half_w := (WORLD_WIDTH  * CHUNK_SIZE) / 2
	var half_h := (WORLD_HEIGHT * CHUNK_SIZE) / 2

	for cy in range(WORLD_HEIGHT):
		for cx in range(WORLD_WIDTH):
			_generate_chunk(cx, cy, rng)
		# Małe oddechy żeby nie zamrozić gry przy dużych światach
		if cy % 10 == 0:
			await get_tree().process_frame

	# Ustaw gracza na środku
	var spawn := Vector2(half_w * TILE_SIZE, half_h * TILE_SIZE)
	player_node.global_position = _find_safe_spawn(spawn, rng)

	loading_label.visible = false
	print("Świat \"%s\" wygenerowany! Seed: %d" % [world_name, world_seed])

# ─────────────────────────────────────────────
#  Generacja jednego chunku
# ─────────────────────────────────────────────
func _generate_chunk(cx: int, cy: int, rng: RandomNumberGenerator) -> void:
	for ty in range(CHUNK_SIZE):
		for tx in range(CHUNK_SIZE):
			var wx := cx * CHUNK_SIZE + tx
			var wy := cy * CHUNK_SIZE + ty

			var h  := _normalized(noise_height.get_noise_2d(wx, wy))
			var t  := _normalized(noise_temp.get_noise_2d(wx, wy))
			var biome := _get_biome(h, t)

			# Postaw kafelek
			var tile_info: Array = TILES[biome]
			tile_map.set_cell(0, Vector2i(wx, wy), tile_info[0], tile_info[1])

			# Obiekty tylko na lądzie
			if biome in [Biome.PLAINS, Biome.FOREST, Biome.MOUNTAIN]:
				_try_place_object(wx, wy, biome, rng)

# ─────────────────────────────────────────────
#  Wyznaczanie biomu
# ─────────────────────────────────────────────
func _get_biome(height: float, temp: float) -> Biome:
	if height < BIOME_OCEAN:
		return Biome.OCEAN
	if height < BIOME_BEACH:
		return Biome.BEACH
	if height < BIOME_PLAINS:
		return Biome.PLAINS
	if height < BIOME_FOREST:
		# Zimno → bory iglaste (Forest), ciepło → lasy liściaste (Forest też, możesz rozróżnić)
		return Biome.FOREST
	if height < BIOME_MOUNTAIN:
		return Biome.MOUNTAIN
	return Biome.SNOW

# ─────────────────────────────────────────────
#  Rozmieszczanie obiektów
# ─────────────────────────────────────────────
func _try_place_object(wx: int, wy: int, biome: Biome, rng: RandomNumberGenerator) -> void:
	# Używamy szumu zamiast czysto losowego – obiekty tworzą naturalne skupiska
	var d := _normalized(noise_detail.get_noise_2d(wx * 3.7, wy * 3.7))

	var scene_path: String = ""

	match biome:
		Biome.FOREST:
			if d < TREE_CHANCE * 3.0:          # więcej drzew w lesie
				scene_path = TREE_SCENES[rng.randi() % TREE_SCENES.size()]
			elif d < TREE_CHANCE * 3.0 + FLOWER_CHANCE:
				scene_path = FLOWER_SCENES[rng.randi() % FLOWER_SCENES.size()]
		Biome.PLAINS:
			if d < TREE_CHANCE:
				scene_path = TREE_SCENES[0]    # tylko dąb na równinach
			elif d < TREE_CHANCE + ROCK_CHANCE:
				scene_path = ROCK_SCENES[rng.randi() % ROCK_SCENES.size()]
			elif d < TREE_CHANCE + ROCK_CHANCE + FLOWER_CHANCE:
				scene_path = FLOWER_SCENES[rng.randi() % FLOWER_SCENES.size()]
		Biome.MOUNTAIN:
			if d < ROCK_CHANCE * 2.5:          # dużo skał w górach
				scene_path = ROCK_SCENES[rng.randi() % ROCK_SCENES.size()]

	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		return

	var packed: PackedScene = load(scene_path)
	var obj: Node2D         = packed.instantiate()
	obj.position = Vector2(wx * TILE_SIZE, wy * TILE_SIZE)
	objects_layer.add_child(obj)

# ─────────────────────────────────────────────
#  Znajdź bezpieczny spawn (nie w wodzie)
# ─────────────────────────────────────────────
func _find_safe_spawn(start: Vector2, rng: RandomNumberGenerator) -> Vector2:
	var tile_pos := Vector2i(int(start.x / TILE_SIZE), int(start.y / TILE_SIZE))
	for radius in range(0, 100):
		for dx in range(-radius, radius + 1):
			for dy in range(-radius, radius + 1):
				if abs(dx) != radius and abs(dy) != radius:
					continue
				var check := tile_pos + Vector2i(dx, dy)
				var h := _normalized(noise_height.get_noise_2d(check.x, check.y))
				if h >= BIOME_BEACH and h < BIOME_MOUNTAIN:
					return Vector2(check.x * TILE_SIZE, check.y * TILE_SIZE)
	return start   # fallback

# ─────────────────────────────────────────────
#  Helper: szum z [-1,1] → [0,1]
# ─────────────────────────────────────────────
func _normalized(v: float) -> float:
	return (v + 1.0) * 0.5
