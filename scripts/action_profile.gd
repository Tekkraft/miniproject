extends Resource

class_name ActionProfile

@export var action_list : Array[Action]
@export var passive_action_list : Array[Action]

func _get_new_action(hostile):
	if hostile:
		return action_list.pick_random()
	else:
		return passive_action_list.pick_random()
