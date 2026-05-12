extends Control

var player_data := {
	"world_name":   "",
	"player_name":  "",
	"skin_index":   0,
	"hair_index":   0,
	"hair_color":   0,
	"clothes_index":0,
	"world_seed":   0
}

const SKIN_COLORS := [
	Color(1.00, 0.85, 0.70),   
	Color(0.87, 0.68, 0.50),   
	Color(0.67, 0.45, 0.28),   
	Color(0.45, 0.28, 0.14),   
	Color(0.25, 0.15, 0.07),]

const HAIR_COLORS := [
	Color(0.1,  0.07, 0.04), 
	Color(0.35, 0.20, 0.08),   
	Color(0.72, 0.52, 0.18),   
	Color(0.75, 0.20, 0.08),   
	Color(0.85, 0.85, 0.85),   
	Color(0.5,  0.1,  0.7),    
	Color(0.1,  0.4,  0.85), ]

const HAIR_TEXTURES := [
	"res://MenuPlayer/Hair/hair_0.png",
	"res://MenuPlayer/Hair/hair_1.png",
	"res://MenuPlayer/Hair/hair_2.png",
]

const CLOTHES_TEXTURES := [
	"res://MenuPlayer/Clothes/char_a_pONE2_1",
	"res://MenuPlayer/Clothes/char_a_pONE2_1out_pfpn_v05.png",
	"res://MenuPlayer/Clothes/char_a_pONE2_1out_undi_v01.png",
]

@onready var world_name_edit:   LineEdit    = $VBox/WorldNameEdit
@onready var player_name_edit:  LineEdit    = $VBox/PlayerNameEdit
@onready var preview_skin:      Sprite2D   = $PreviewPanel/PreviewContainer/LayerSkin
@onready var preview_hair:      Sprite2D = $PreviewPanel/PreviewContainer/LayerHair
@onready var preview_clothes:   Sprite2D = $PreviewPanel/PreviewContainer/LayerClothes
@onready var skin_label:        Label       = $VBox/SkinRow/SkinLabel
@onready var hair_style_label:  Label       = $VBox/HairStyleRow/HairStyleLabel
@onready var hair_color_label:  Label       = $VBox/HairColorRow/HairColorLabel
@onready var clothes_label:     Label       = $VBox/ClothesRow/ClothesLabel
@onready var error_label:       Label       = $ErrorLabel
@onready var create_btn:        Button      = $CreateButton

func _ready() -> void:
	error_label.text = ""
	_refresh_preview()

func _on_skin_prev_pressed() -> void:
	player_data.skin_index = wrapi(player_data.skin_index - 1, 0, SKIN_COLORS.size())
	_refresh_preview()

func _on_skin_next_pressed() -> void:
	player_data.skin_index = wrapi(player_data.skin_index + 1, 0, SKIN_COLORS.size())
	_refresh_preview()

func _on_hair_style_prev_pressed() -> void:
	player_data.hair_index = wrapi(player_data.hair_index - 1, 0, HAIR_TEXTURES.size())
	_refresh_preview()

func _on_hair_style_next_pressed() -> void:
	player_data.hair_index = wrapi(player_data.hair_index + 1, 0, HAIR_TEXTURES.size())
	_refresh_preview()

func _on_hair_color_prev_pressed() -> void:
	player_data.hair_color = wrapi(player_data.hair_color - 1, 0, HAIR_COLORS.size())
	_refresh_preview()

func _on_hair_color_next_pressed() -> void:
	player_data.hair_color = wrapi(player_data.hair_color + 1, 0, HAIR_COLORS.size())
	_refresh_preview()

func _on_clothes_prev_pressed() -> void:
	player_data.clothes_index = wrapi(player_data.clothes_index - 1, 0, CLOTHES_TEXTURES.size())
	_refresh_preview()

func _on_clothes_next_pressed() -> void:
	player_data.clothes_index = wrapi(player_data.clothes_index + 1, 0, CLOTHES_TEXTURES.size())
	_refresh_preview()

func _refresh_preview() -> void:
	# Skóra
	preview_skin.modulate = SKIN_COLORS[player_data.skin_index]
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
	get_tree().change_scene_to_file("res://Player/word.tscn")

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
