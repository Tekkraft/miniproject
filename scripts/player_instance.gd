extends Sprite2D

var max_hp = 64
var current_hp = 64

var current_shield = 0

signal player_died

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _setup():
	pass

func _take_damage(damage : int):
	if damage < current_shield:
		current_shield -= damage
		return false
	var effective_damage = damage - current_shield
	current_shield = 0
	current_hp -= effective_damage
	get_node("HealthBar").max_value = max_hp
	get_node("HealthBar").value = current_hp
	if current_hp <= 0:
		emit_signal("player_died")
		return true 
	else:
		return false

func _gain_shield(amount: int):
	current_shield += amount

