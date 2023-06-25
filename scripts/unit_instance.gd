extends Node2D

var unit_data : Unit
var current_hp = -1
var current_shield = 0

signal unit_died

var current_location : Vector2i

var current_intent : Action
var current_hostility : bool

var hover_resource = preload("res://scenes/tooltip_hover.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _setup(base_unit : Unit, location : Vector2i):
	unit_data = base_unit
	current_hp = unit_data.hp
	current_shield = 0
	current_location = location
	current_hostility = unit_data.starting_hostility
	get_node("UnitSprite").texture = unit_data.sprite
	get_node("HealthBar").max_value = unit_data.hp
	_update_health_label()

func _take_damage(damage : int):
	if damage < current_shield:
		current_shield -= damage
		_update_health_label()
		return false
	var effective_damage = damage - current_shield
	current_shield = 0
	current_hp -= effective_damage
	_update_health_label()
	if current_hp <= 0:
		emit_signal("unit_died")
		return true
	else:
		return false

func _restore_health(amount: int):
	current_hp += amount
	current_hp = min(current_hp, unit_data.hp)
	_update_health_label()

func _gain_shield(amount: int):
	current_shield += amount
	_update_health_label()

func _generate_intent():
	current_intent = unit_data.actions._get_new_action(current_hostility)
	get_node("Intent/IntentIcon").texture = current_intent._get_action_icon()
	get_node("Intent/IntentAmount").text = current_intent._get_action_display_value()
	current_hostility = not current_hostility

func _create_status(status_data : Status, counter):
	for status_node in get_node("Status").get_children():
		if status_node.is_in_group("StatusInstance"):
			if status_node.status_data == status_data:
				status_node._increment_counter(counter)
				return
	
	var new_status = load("res://scenes/status.tscn").instantiate()
	new_status._setup(status_data, counter)
	new_status.add_to_group("StatusInstance")
	get_node("Status").add_child(new_status)
	new_status.position = Vector2(10 * get_node("Status").get_child_count() + 4, 2)
	_realign_statuses()

func _realign_statuses():
	var children = get_node("Status").get_children()
	for i in get_node("Status").get_child_count():
		children[i].position = Vector2(10 * i + 4, 2)

func _clear_shields():
	current_shield = 0
	_update_health_label()

func _update_health_label():
	get_node("HealthBar").value = current_hp
	var health_label = str(current_hp) + "/" + str(unit_data.hp)
	if current_shield > 0:
		health_label += " + " + str(current_shield)
	get_node("HealthBar/HealthLabel").text = health_label

func _cancel_intent():
	current_intent = load("res://enemies/basic_actions/canceled.tres")

func _on_intent_area_mouse_entered():
	var tooltip = hover_resource.instantiate() as Node2D
	tooltip.get_node("TooltipTitle").text = current_intent.action_name
	tooltip.get_node("TooltipDescription").text = ""
	get_node("Intent/Hover").add_child(tooltip)
	tooltip.position += Vector2(128,64) * 1.1

func _on_intent_area_mouse_exited():
	for node in get_node("Intent/Hover").get_children():
		get_node("Intent/Hover").remove_child(node)
		node.queue_free()
