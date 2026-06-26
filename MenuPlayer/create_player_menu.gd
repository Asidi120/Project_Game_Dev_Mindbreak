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
	Color(0.25, 0.15, 0.07),
	Color(0.092, 0.054, 0.001, 1.0),]

const HAIR_COLORS := [
	Color(0.1,  0.07, 0.04), 
	Color(0.35, 0.20, 0.08),   
	Color(0.72, 0.52, 0.18),   
	Color(0.845, 0.726, 0.116, 1.0),   
	Color(0.85, 0.85, 0.85),   
	Color(0.651, 0.097, 0.167, 1.0),    
	Color(0.601, 0.174, 0.79, 1.0), 
	Color(0.321, 0.371, 0.809, 1.0),
	Color(0.286, 0.671, 0.192, 1.0),]

const HAIR_TEXTURES := [
	"res://MenuPlayer/Hair/hair_0.png",
	"res://MenuPlayer/Hair/hair_2.png",
]

const CLOTHES_TEXTURES := [
	"res://MenuPlayer/Clothes/char_a_pONE2_1out_fstr_v01.png",
	"res://MenuPlayer/Clothes/char_a_pONE2_1out_pfpn_v05.png",
	"res://MenuPlayer/Clothes/char_a_pONE2_1out_undi_v01.png",
	"res://MenuPlayer/Clothes/char_a_pONE2_1out_fstr_v04.png",
	"res://MenuPlayer/Clothes/char_a_pONE2_1out_pfpn_v01.png",
]

@onready var world_name_edit:   LineEdit = $VBox/WorldNameEdit
@onready var player_name_edit:  LineEdit = $VBox/PlayerNameEdit
@onready var preview_skin:      Sprite2D = $PreviewPanel/PreviewContainer/LayerSkin
@onready var preview_hair:      Sprite2D = $PreviewPanel/PreviewContainer/LayerHair
@onready var preview_clothes:   Sprite2D = $PreviewPanel/PreviewContainer/LayerClothes
@onready var skin_label:        Label    = $VBox/SkinRow/SkinLabel
@onready var hair_style_label:  Label    = $VBox/HairStyleRow/HairStyleLabel
@onready var hair_color_label:  Label    = $VBox/HairColorRow/HairColorLabel
@onready var clothes_label:     Label    = $VBox/ClothesRow/ClothesLabel
@onready var error_label:       Label    = $ErrorLabel
@onready var create_btn:        Button   = $CreateButton

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
	skin_label.text = "Skin %d / %d" % [player_data.skin_index + 1, SKIN_COLORS.size()]

	# Styl włosów
	var hair_path: String = HAIR_TEXTURES[player_data.hair_index]
	if ResourceLoader.exists(hair_path):
		preview_hair.texture = load(hair_path)
	hair_style_label.text = "Style %d / %d" % [player_data.hair_index + 1, HAIR_TEXTURES.size()]

	# Kolor włosów — tylko na preview_hair, nie na labelu
	preview_hair.modulate = HAIR_COLORS[player_data.hair_color]
	hair_color_label.modulate = Color.WHITE
	hair_color_label.text = "Color %d / %d" % [player_data.hair_color + 1, HAIR_COLORS.size()]

	# Ubranie
	var clothes_path: String = CLOTHES_TEXTURES[player_data.clothes_index]
	if ResourceLoader.exists(clothes_path):
		preview_clothes.texture = load(clothes_path)
	clothes_label.text = "Outfit %d / %d" % [player_data.clothes_index + 1, CLOTHES_TEXTURES.size()]

const LOADING_SCREEN = preload("uid://ba3c0jg2tqp2f")

func _on_create_button_pressed() -> void:
	error_label.text = ""

	var world_name: String = world_name_edit.text.strip_edges()
	var player_name: String = player_name_edit.text.strip_edges()

	if world_name.is_empty():
		error_label.text = "⚠ Name your world!"
		return
	if player_name.is_empty():
		error_label.text = "⚠ Nickname is empty!"
		return
	if world_name.length() > 24:
		error_label.text = "⚠ World name has limit of 24 characters."
		return
	if player_name.length() > 20:
		error_label.text = "⚠ Nickname has limit of 20 characters."
		return

	player_data.world_name = world_name
	player_data.player_name = player_name
	player_data.world_seed = randi()

	SaveManager.delete_save()
	_save_player_data()

	var loading = LOADING_SCREEN.instantiate()
	get_tree().root.add_child(loading)

	await get_tree().process_frame

	get_tree().change_scene_to_file("res://Player/word.tscn")

func _save_player_data() -> void:
	var save_file := FileAccess.open("user://player_data.json", FileAccess.WRITE)
	if save_file:
		save_file.store_string(JSON.stringify(player_data))
		save_file.close()
	else:
		error_label.text = "⚠ Error in saving data!"

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Menu/control.tscn")
