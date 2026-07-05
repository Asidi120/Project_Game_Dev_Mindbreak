extends Area2D
class_name Item
var player_in_range := false
@export var item_id := ""
@export var item_name := ""
@export var item_type := ""
@onready var sprite_2d: Node = $Sprite2D

func get_icon() -> Texture2D:
	if sprite_2d is AnimatedSprite2D:
		var anim_sprite := sprite_2d as AnimatedSprite2D
		var frames := anim_sprite.sprite_frames
		var anim := anim_sprite.animation

		if frames and frames.has_animation(anim):
			return frames.get_frame_texture(anim, anim_sprite.frame)

		return null

	elif sprite_2d is Sprite2D:
		var s := sprite_2d as Sprite2D

		if s.region_enabled:
			var atlas_texture = AtlasTexture.new()
			atlas_texture.atlas = s.texture
			atlas_texture.region = s.region_rect
			return atlas_texture
		else:
			return s.texture

	return null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	add_to_group("world_item")

func _process(_delta: float) -> void:
	pass

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		body.add_item(self)

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		body.remove_item(self)

func collect():
	var item = {
		"item_id" : item_id,
		"texture": get_icon(),
		"item_type": item_type,
		"scene_path": scene_file_path
	}
	print("+1 ", item_name)
	WorldStateManager.mark_removed(get_tree().current_scene.scene_file_path, global_position)
	WorldStateManager.remove_dropped_item(get_tree().current_scene.scene_file_path, global_position)
	queue_free()
	return item


func _on_area_2d_body_entered(body: Node2D) -> void:
	pass # Replace with function body.


func _on_area_2d_body_exited(body: Node2D) -> void:
	pass # Replace with function body.
