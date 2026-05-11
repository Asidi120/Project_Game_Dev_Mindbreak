extends Resource
class_name CharacterAppearance

# =============================================
# WYGLĄD POSTACI - Resource
# Zapisz jako: res://resources/character_appearance.gd
# =============================================

@export var skin_color: Color = Color("#F5C5A3")
@export var hair_style: int = 0       # 0-5 style włosów
@export var hair_color: Color = Color("#3B2314")
@export var eye_color: Color = Color("#3B82F6")
@export var outfit_style: int = 0     # 0-4 stroje
@export var outfit_color: Color = Color("#4A5568")
@export var outfit_color2: Color = Color("#718096")  # akcesorium/detal
@export var has_beard: bool = false
@export var beard_color: Color = Color("#3B2314")
@export var accessory: int = 0        # 0=brak, 1=opaska, 2=kapelusz, 3=korona, 4=helm

func duplicate_appearance() -> CharacterAppearance:
	var copy = CharacterAppearance.new()
	copy.skin_color = skin_color
	copy.hair_style = hair_style
	copy.hair_color = hair_color
	copy.eye_color = eye_color
	copy.outfit_style = outfit_style
	copy.outfit_color = outfit_color
	copy.outfit_color2 = outfit_color2
	copy.has_beard = has_beard
	copy.beard_color = beard_color
	copy.accessory = accessory
	return copy
