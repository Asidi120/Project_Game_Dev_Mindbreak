extends Area2D
class_name Item
var player_in_range := false

@export var item_id := ""
@export var item_name := ""
#var texture = get_icon()
@export var item_type := ""

@onready var sprite_2d: Sprite2D = $Sprite2D

func get_icon() -> Texture2D:
	if sprite_2d.region_enabled:
		var atlas_texture = AtlasTexture.new()
		atlas_texture.atlas = sprite_2d.texture
		atlas_texture.region = sprite_2d.region_rect
		return atlas_texture
	else:
		return sprite_2d.texture




# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(_on_body_entered) #automatycznie dla każdego itema będzie wykrywać bez konieczności podpinania
	body_exited.connect(_on_body_exited)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#if player_in_range and Input.is_action_just_pressed("pick_up"): #jesli player w zasiegu i nacisniete F item zostaje zebrany
		#queue_free() #item znika po wejściu w niego
		#print("+1 ", item_name)
		pass

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		body.add_item(self) #wywołuje add item z playera

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		body.remove_item(self) #wywołuje remove item z playera
		
func collect():
	var item = {
		"item_id" : item_id,
		"texture": get_icon(),
		"item_type": item_type,
		"scene_path": scene_file_path
	}
	print("+1 ", item_name)
	queue_free()
	return item
