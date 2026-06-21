extends Node2D
@onready var open_door: TileMapLayer = $BossDoor/openDoor
@onready var cant_open_label: Label = $Labels/CantOpenLabel
@onready var click_to_open_label: Label = $Labels/ClickToOpenLabel
@onready var notification: Label = $Labels/Notification

signal boss_door_entered(dungeon_name: String)

@export var numberofmonsters:int=9

var can_open=false
var player_in_door_area = false
var showing_label = false
var can_exit=true

func _ready():
	for monster in get_tree().get_nodes_in_group("Enemies"):
		monster.died.connect(monster_died)
	open_door.visible=false
	can_open=true

func _process(delta):
	var door_screen_pos = open_door.get_global_transform_with_canvas().origin

	cant_open_label.position = door_screen_pos + Vector2(-210, -200)
	click_to_open_label.position = door_screen_pos + Vector2(-210, -180)
	if can_exit:
		if Input.is_action_just_pressed("action (open door, sleep etc.)"):
			get_tree().change_scene_to_file("res://Player/word.tscn")
	if player_in_door_area:
		if can_open:
			click_to_open_label.visible = true

			if Input.is_action_just_pressed("action (open door, sleep etc.)"):
				emit_signal("boss_door_entered", get_tree().current_scene.name)
				get_tree().change_scene_to_file("res://Boss_Area/BossArea.tscn")
		else:
			click_to_open_label.visible = false

			if Input.is_action_just_pressed("action (open door, sleep etc.)") and not showing_label:
				show_cant_open()
	else:
		click_to_open_label.visible = false

func show_notification():
	notification.visible = true
	await get_tree().create_timer(3.0).timeout
	notification.visible = false

func show_cant_open():
	showing_label = true
	cant_open_label.visible = true
	cant_open_label.modulate.a = 1.0

	var start_pos = cant_open_label.position
	var duration = 1.0
	var t = 0.0

	while t < duration:
		await get_tree().process_frame
		t += get_process_delta_time()

		cant_open_label.position.y = start_pos.y - 30 * (t / duration)
		cant_open_label.modulate.a = 1.0 - (t / duration)

	cant_open_label.visible = false
	cant_open_label.position = start_pos
	showing_label = false

func monster_died():
	numberofmonsters -= 1
	print("Number of monsters:", numberofmonsters)
	if numberofmonsters <= 0:
		opendoor()

func opendoor():
	open_door.visible=true
	can_open=true
	show_notification()

func _on_boss_door_body_entered(body):
	if body.is_in_group("Players"):
		player_in_door_area = true

func _on_boss_door_body_exited(body):
	if body.is_in_group("Players"):
		player_in_door_area = false
		click_to_open_label.visible = false


func _on_exit_body_entered(body: Node2D) -> void:
	if body.is_in_group("Players"):
		can_exit=true

func _on_exit_body_exited(body: Node2D) -> void:
	if body.is_in_group("Players"):
		can_exit=false
