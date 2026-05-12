extends Node

# =============================================
# GAME DATA - Autoload Singleton
# Mindbreak - globalne dane gry
# =============================================
# Dodaj do projektu jako Autoload:
#   Project > Project Settings > Autoload
#   Path: res://scripts/game_data.gd
#   Name: GameData
# =============================================

# Dane aktualnego gracza
var player: Dictionary = {}

# Dane świata (seed, biomy itp.)
var world_seed: int = 0
var world_generated: bool = false

# Ustawienia gry
var settings: Dictionary = {
	"music_volume": 0.8,
	"sfx_volume": 1.0,
	"fullscreen": false
}

func set_player_data(data: Dictionary) -> void:
	player = data
	print("Gracz zapisany: %s (%s)" % [data.get("name", "?"), data.get("class", "?")])

func has_player() -> bool:
	return not player.is_empty()

func new_world_seed() -> int:
	world_seed = randi()
	world_generated = false
	return world_seed

func reset() -> void:
	player = {}
	world_seed = 0
	world_generated = false
