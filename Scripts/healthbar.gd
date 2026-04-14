extends TextureProgressBar

var target: Node

@onready var hp_label: Label = $"../hp_label"

var target_hp: float = 0

func set_target(t):
	target = t
	await get_tree().process_frame # game needs time to build itself for code to work
	if target.has_signal("hp_changed"):
		target.hp_changed.connect(update_bar)
	update_bar(target.current_hp, target.max_hp)
	value = target.current_hp
	target_hp = target.current_hp
	if hp_label:
		hp_label.text = str(int(target_hp)) + "/" + str(int(target.max_hp))

func update_bar(current_hp, max_hp):
	max_value = max_hp
	target_hp = current_hp
	if hp_label:
		hp_label.text = str(int(target_hp)) + "/" + str(int(max_hp))

func _process(delta):
	value = lerp(value, target_hp, 16 * delta)
	if abs(value - target_hp) < 0.5:
		value = target_hp
