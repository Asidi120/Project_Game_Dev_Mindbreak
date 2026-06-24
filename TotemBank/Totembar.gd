extends Control
var i
func _ready():
	i=0
	update_runes()

func update_runes():
	for rune_name in BossManager.unlocked_runes.keys():
		if BossManager.unlocked_runes[rune_name]:

			var rune = find_child(rune_name, true, false)
			if rune:
				rune.visible = true
				i+=1
			var light_name = BossManager.rune_lights[rune_name]
			var light = find_child(light_name, true, false)

			if light:
				light.visible = true
	if i==3:
		var endbutton=get_tree().get_first_node_in_group("EndGameButton")
		endbutton.visible=true
