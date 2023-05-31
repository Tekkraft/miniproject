extends Resource

class_name ActionProfile

@export var action_list : Array[Action]

func _get_new_action():
	return action_list.pick_random()
