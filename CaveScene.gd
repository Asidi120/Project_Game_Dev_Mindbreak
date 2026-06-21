extends Node2D

func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	print("CaveScene: restore dla ", scene_file_path)
	print("CaveScene: stan ", WorldStateManager.scene_states)
	WorldStateManager.restore_scene(scene_file_path)
