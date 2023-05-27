extends Node2D

var unit_data : Unit
var current_hp

signal unit_died

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _setup(base_unit : Unit):
	unit_data = base_unit
	current_hp = unit_data.hp
	get_node("UnitSprite").texture = unit_data.sprite

func _take_damage(damage : int):
	print(str(current_hp) + "-" + str(damage))
	current_hp -= damage
	if current_hp <= 0:
		emit_signal("unit_died")
		return true
	else:
		return false
