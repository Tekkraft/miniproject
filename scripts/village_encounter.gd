extends Encounter

class_name VillageEncounter

@export var village_name : String
@export_multiline var village_description : String
@export var available_rest_points : int
@export var random_village_name = true

var random_village_name_front = ["Red", "Green", "Gray", "Silver", "River", "Winter", "Summer"]
var random_village_name_back = ["wall", "fort", "brook", "field", "ton", "ville", "home"]

func _get_village_name():
	if random_village_name:
		return random_village_name_front.pick_random() + random_village_name_back.pick_random()
	else:
		return village_name
