extends Encounter

class_name CombatEncounter

@export var units : Array[Unit]
@export var positions : Array[Vector2i]
@export var custom_icon : Texture2D

func _get_position_dictionary():
	var return_dictionary = {}
	for i in mini(positions.size(), units.size()):
		return_dictionary[positions[i]] = units[i]
	return return_dictionary 
