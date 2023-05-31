extends Node2D

var unit_data : Unit
var current_hp = -1
var current_shield = 0

signal unit_died

var current_location : Vector2i

var current_intent : Action

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
	get_node("UnitSprite").texture = unit_data.sprite
	get_node("HealthBar").max_value = unit_data.hp
	get_node("HealthBar").value = current_hp

func _take_damage(damage : int):
	if damage < current_shield:
		current_shield -= damage
		return false
	var effective_damage = damage - current_shield
	current_shield = 0
	current_hp -= effective_damage
	get_node("HealthBar").value = current_hp
	if current_hp <= 0:
		emit_signal("unit_died")
		return true
	else:
		return false

func _gain_shield(amount: int):
	current_shield += amount

func _generate_intent():
	current_intent = unit_data.actions._get_new_action()
	get_node("Intent/IntentIcon").texture = current_intent._get_action_icon()
	get_node("Intent/IntentAmount").text = current_intent._get_action_display_value()
