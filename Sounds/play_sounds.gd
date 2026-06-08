extends Node
@onready var walk: AudioStreamPlayer2D = $Walk
@onready var attack: AudioStreamPlayer2D = $Attack
@onready var hurt: AudioStreamPlayer2D = $Hurt
@onready var dead: AudioStreamPlayer2D = $Dead
@onready var player: Player = $".."

func play_sound(sound: String):
	match sound:
		"walk":
			if !walk.playing:
				walk.play()
		"attack":
			attack.play()
		"hurt":
			if player.current_hp!=player.max_hp:
				hurt.play()
		"dead":
			dead.play()
			
func stop_walk():
	walk.stop()
