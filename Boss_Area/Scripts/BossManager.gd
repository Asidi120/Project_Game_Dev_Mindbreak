extends Node

var boss_path
var current_totem
var current_rune_name
var current_rune_light_name

var boss_data = {
	"DungeonFirst": {
		"boss": preload("uid://dmi0vi77ntxfa"),
		"totem": preload("uid://daw6rsfw5vdjg"),
		"name_totembar_light": "RuneLight",
		"name_totembar":"Rune1"
	},
	"DungeonSecond": {
		"boss": preload("uid://cv7444xo418vm"),
		"totem": preload("uid://blxaed8jswxyw"),
		"name_totembar_light": "RuneLight2",
		"name_totembar":"Rune2"
	},
	"DungeonThird": {
		"boss": preload("uid://y8rspm1g8yk5"),
		"totem": preload("uid://cwruc27pbbcdh"),
		"name_totembar_light": "RuneLight3",
		"name_totembar":"Rune3"
	}
}

func _ready():
	for dungeon in get_tree().get_nodes_in_group("Dungeon"):
		dungeon.boss_door_entered.connect(_on_boss_door_entered)

func _on_boss_door_entered(dungeon_name: String):
	if boss_data.has(dungeon_name):
		boss_path = boss_data[dungeon_name]["boss"]
		current_totem = boss_data[dungeon_name]["totem"]
		current_rune_name = boss_data[dungeon_name]["name_totembar"]
		current_rune_light_name = boss_data[dungeon_name]["name_totembar_light"]

	await get_tree().process_frame

	var boss_area = get_tree().get_first_node_in_group("BossArea")
	if boss_area:
		boss_area.spawn_boss()
