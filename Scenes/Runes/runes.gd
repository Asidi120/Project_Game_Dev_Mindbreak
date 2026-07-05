extends Area2D
class_name Rune
var player_in_range := false
var totembar
@onready var click_to_open_label: Label = $ClickToOpenLabel

var rune_map = {}

func _ready():
	var bar = get_tree().get_first_node_in_group("TotemBar")

	for child in bar.get_children():
		rune_map[child.name] = child

func _process(_delta: float) -> void:
	if player_in_range:
		if Input.is_action_just_pressed("action (open door, sleep etc.)"):
			queue_free()
			unlock_rune()
			SceneTransition.change_scene_with_save("res://Player/word.tscn")

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Players"):
		player_in_range=true
		click_to_open_label.visible=true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Players"):
		player_in_range=false
		click_to_open_label.visible=false

func unlock_rune():
	BossManager.unlocked_runes[BossManager.current_rune_name] = true

	var rune = get_tree().get_first_node_in_group("TotemBar").find_child(
		BossManager.current_rune_name, true, false
	)

	var rune_light = get_tree().get_first_node_in_group("TotemBar").find_child(
		BossManager.current_rune_light_name, true, false
	)

	if rune:
		rune.visible = true

	if rune_light:
		rune_light.visible = true
