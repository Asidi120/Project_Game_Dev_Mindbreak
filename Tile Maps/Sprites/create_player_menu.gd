extends Control

# ─────────────────────────────────────────────
#  Dane postaci — zapisywane do pliku save
# ─────────────────────────────────────────────
var player_data := {
	"world_name":   "",
	"player_name":  "",
	"skin_index":   0,
	"hair_index":   0,
	"hair_color":   0,
	"clothes_index":0,
	"hat_index":    0,
	"world_seed":   0
}

# ─────────────────────────────────────────────
#  Opcje wyglądu — dodaj własne tekstury/kolory
# ─────────────────────────────────────────────
const SKIN_COLORS := [
	Color(1.00, 0.85, 0.70),   # jasna
	Color(0.87, 0.68, 0.50),   # pszeniczna
	Color(0.67, 0.45, 0.28),   # oliwkowa
	Color(0.45, 0.28, 0.14),   # ciemna
	Color(0.25, 0.15, 0.07),   # bardzo ciemna
]

const HAIR_COLORS := [
	Color(0.1,  0.07, 0.04),   # czarne
	Color(0.35, 0.20, 0.08),   # brązowe
	Color(0.72, 0.52, 0.18),   # blond
	Color(0.75, 0.20, 0.08),   # rude
	Color(0.85, 0.85, 0.85),   # siwe / białe
	Color(0.5,  0.1,  0.7),    # fioletowe
	Color(0.1,  0.4,  0.85),   # niebieskie
]

# Ścieżki do tekstur warstw — dostosuj do swojego projektu
const HAIR_TEXTURES := [
	"res://Player/Appearance/Hair/hair_0.png",
	"res://Player/Appearance/Hair/hair_1.png",
	"res://Player/Appearance/Hair/hair_2.png",
]

const CLOTHES_TEXTURES := [
	"res://Player/Appearance/Clothes/clothes_0.png",
	"res://Player/Appearance/Clothes/clothes_1.png",
	"res://Player/Appearance/Clothes/clothes_2.png",
]

const HAT_TEXTURES := [
	"",                                              # brak kapelusza
	"res://Player/Appearance/Hats/hat_0.png",
	"res://Player/Appearance/Hats/hat_1.png",
]

# ─────────────────────────────────────────────
#  Node refs (uzupełnione przez @onready)
# ─────────────────────────────────────────────
@onready var world_name_edit:   LineEdit    = $VBox/WorldNameEdit
@onready var player_name_edit:  LineEdit    = $VBox/PlayerNameEdit
@onready var preview_skin:      ColorRect   = $PreviewPanel/PreviewContainer/LayerSkin
@onready var preview_hair:      TextureRect = $PreviewPanel/PreviewContainer/LayerHair
@onready var preview_clothes:   TextureRect = $PreviewPanel/PreviewContainer/LayerClothes
@onready var preview_hat:       TextureRect = $PreviewPanel/PreviewContainer/LayerHat
@onready var skin_label:        Label       = $VBox/SkinRow/SkinLabel
@onready var hair_style_label:  Label       = $VBox/HairStyleRow/HairStyleLabel
@onready var hair_color_label:  Label       = $VBox/HairColorRow/HairColorLabel
@onready var clothes_label:     Label       = $VBox/ClothesRow/ClothesLabel
@onready var hat_label:         Label       = $VBox/HatRow/HatLabel
@onready var error_label:       Label       = $ErrorLabel
@onready var create_btn:        Button      = $CreateButton

func _ready() -> void:
	error_label.text = ""
	_refresh_preview()

# ─────────────────────────────────────────────
#  Nawigacja — kolory skóry
# ─────────────────────────────────────────────
func _on_skin_prev_pressed() -> void:
	player_data.skin_index = wrapi(player_data.skin_index - 1, 0, SKIN_COLORS.size())
	_refresh_preview()

func _on_skin_next_pressed() -> void:
	player_data.skin_index = wrapi(player_data.skin_index + 1, 0, SKIN_COLORS.size())
	_refresh_preview()

# ─────────────────────────────────────────────
#  Nawigacja — styl włosów
# ─────────────────────────────────────────────
func _on_hair_style_prev_pressed() -> void:
	player_data.hair_index = wrapi(player_data.hair_index - 1, 0, HAIR_TEXTURES.size())
	_refresh_preview()

func _on_hair_style_next_pressed() -> void:
	player_data.hair_index = wrapi(player_data.hair_index + 1, 0, HAIR_TEXTURES.size())
	_refresh_preview()

# ─────────────────────────────────────────────
#  Nawigacja — kolor włosów
# ─────────────────────────────────────────────
func _on_hair_color_prev_pressed() -> void:
	player_data.hair_color = wrapi(player_data.hair_color - 1, 0, HAIR_COLORS.size())
	_refresh_preview()

func _on_hair_color_next_pressed() -> void:
	player_data.hair_color = wrapi(player_data.hair_color + 1, 0, HAIR_COLORS.size())
	_refresh_preview()

# ─────────────────────────────────────────────
#  Nawigacja — ubranie
# ─────────────────────────────────────────────
func _on_clothes_prev_pressed() -> void:
	player_data.clothes_index = wrapi(player_data.clothes_index - 1, 0, CLOTHES_TEXTURES.size())
	_refresh_preview()

func _on_clothes_next_pressed() -> void:
	player_data.clothes_index = wrapi(player_data.clothes_index + 1, 0, CLOTHES_TEXTURES.size())
	_refresh_preview()

# ─────────────────────────────────────────────
#  Nawigacja — kapelusze
# ─────────────────────────────────────────────
func _on_hat_prev_pressed() -> void:
	player_data.hat_index = wrapi(player_data.hat_index - 1, 0, HAT_TEXTURES.size())
	_refresh_preview()

func _on_hat_next_pressed() -> void:
	player_data.hat_index = wrapi(player_data.hat_index + 1, 0, HAT_TEXTURES.size())
	_refresh_preview()

# ─────────────────────────────────────────────
#  Odświeżanie podglądu
# ─────────────────────────────────────────────
func _refresh_preview() -> void:
	# Skóra
	preview_skin.color = SKIN_COLORS[player_data.skin_index]
	skin_label.text    = "Skin %d / %d" % [player_data.skin_index + 1, SKIN_COLORS.size()]

	# Włosy — styl
	var hair_path: String = HAIR_TEXTURES[player_data.hair_index]
	if ResourceLoader.exists(hair_path):
		preview_hair.texture = load(hair_path)
	preview_hair.modulate = HAIR_COLORS[player_data.hair_color]
	hair_style_label.text = "Style %d / %d" % [player_data.hair_index + 1, HAIR_TEXTURES.size()]

	# Kolor włosów
	hair_color_label.modulate = HAIR_COLORS[player_data.hair_color]
	hair_color_label.text     = "Color %d / %d" % [player_data.hair_color + 1, HAIR_COLORS.size()]

	# Ubranie
	var clothes_path: String = CLOTHES_TEXTURES[player_data.clothes_index]
	if ResourceLoader.exists(clothes_path):
		preview_clothes.texture = load(clothes_path)
	clothes_label.text = "Outfit %d / %d" % [player_data.clothes_index + 1, CLOTHES_TEXTURES.size()]

	# Kapelusz
	var hat_path: String = HAT_TEXTURES[player_data.hat_index]
	if hat_path == "":
		preview_hat.texture = null
		hat_label.text = "No hat"
	else:
		if ResourceLoader.exists(hat_path):
			preview_hat.texture = load(hat_path)
		hat_label.text = "Hat %d / %d" % [player_data.hat_index, HAT_TEXTURES.size() - 1]

# ─────────────────────────────────────────────
#  Przycisk "Stwórz Świat"
# ─────────────────────────────────────────────
func _on_create_button_pressed() -> void:
	error_label.text = ""

	# Walidacja
	var world_name: String  = world_name_edit.text.strip_edges()
	var player_name: String = player_name_edit.text.strip_edges()

	if world_name.is_empty():
		error_label.text = "⚠ Podaj nazwę świata!"
		return
	if player_name.is_empty():
		error_label.text = "⚠ Podaj nazwę gracza!"
		return
	if world_name.length() > 24:
		error_label.text = "⚠ Nazwa świata max 24 znaki."
		return
	if player_name.length() > 20:
		error_label.text = "⚠ Nazwa gracza max 20 znaków."
		return

	# Zapisz dane
	player_data.world_name  = world_name
	player_data.player_name = player_name
	player_data.world_seed  = randi()   # losowy seed świata

	_save_player_data()

	# Przejście do sceny gry / generatora świata
	get_tree().change_scene_to_file("res://world.tscn")

# ─────────────────────────────────────────────
#  Zapis do pliku
# ─────────────────────────────────────────────
func _save_player_data() -> void:
	var save_file := FileAccess.open("user://player_data.json", FileAccess.WRITE)
	if save_file:
		save_file.store_string(JSON.stringify(player_data))
		save_file.close()

# ─────────────────────────────────────────────
#  Przycisk "Wstecz"
# ─────────────────────────────────────────────
func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Menu/control.tscn")
