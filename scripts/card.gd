extends Resource

class_name Card

@export var card_name : String
@export var card_sprite : Texture2D
@export_multiline var card_description : String
@export var card_effects : Array[String]

func _parse_effects():
	var parser = RegEx.new()
	parser.compile("^(?<action>\\w+)-(?<value>\\w+)(?:\\+(?<modifier>\\w+))?$")
	var result = parser.search("damage-10+magic")
	if result:
		print(result.get_string("action"))
		print(result.get_string("value"))
		print(result.get_string("modifier"))
