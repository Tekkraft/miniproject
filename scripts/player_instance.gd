extends Sprite2D

var max_hp = 100
var current_hp : int

var current_shield = 0

signal player_died

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _setup():
	current_hp = RunHandler.current_hp
	max_hp = RunHandler.max_hp
	get_node("HealthBar").max_value = max_hp
	_update_health_label()
	get_node("MartialSprite").texture = RunHandler.martial_class.class_texture
	get_node("MysticSprite").texture = RunHandler.mystic_class.class_texture

func _take_damage(damage : int):
	if damage < current_shield:
		current_shield -= damage
		_update_health_label()
		return false
	var effective_damage = damage - current_shield
	current_shield = 0
	current_hp -= effective_damage
	get_node("HealthBar").max_value = max_hp
	_update_health_label()
	if current_hp <= 0:
		emit_signal("player_died")
		return true 
	else:
		return false

func _restore_health(amount: int):
	current_hp += amount
	current_hp = min(current_hp, max_hp)
	_update_health_label()

func _gain_shield(amount: int):
	current_shield += amount
	_update_health_label()

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
	var health_label = str(current_hp) + "/" + str(max_hp)
	if current_shield > 0:
		health_label += " + " + str(current_shield)
	get_node("HealthBar/HealthLabel").text = health_label

