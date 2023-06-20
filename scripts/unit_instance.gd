extends Node2D

var unit_data : Unit
var current_hp = -1
var current_shield = 0

signal unit_died

var current_location : Vector2i

var current_intent : Action
var current_hostility : bool

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
	var modified_damage = damage
	
	var dodge = false
	#STANDARD STATUS LANGUAGE
	for status in get_node("Status").get_children():
		var status_data = status.status_data
		if status_data.status_activation == Status.ActivationCondition.ON_ATTACKED:
			var returns = get_node("/root/BattleHandler")._activate_status_effects(status, status_data._parse_effects(), self)
			for value in returns:
				match value[0]:
					"dodge":
						dodge = true
					"phys_def":
						modified_damage -= value[1]
			if status_data.status_tick_down == Status.TickDown.WHEN_ACTIVATED and returns[0][1] == 1:
				status._decrement_counter(1)
	
	if dodge:
		modified_damage = 0
	modified_damage = max(0, modified_damage)
	if modified_damage < current_shield:
		current_shield -= modified_damage
		_update_health_label()
		return false
	var effective_damage = modified_damage - current_shield
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
	var power_through_status = []
	var power_through_damage = []
	for status_node in get_node("Status").get_children():
		if status_node.is_in_group("StatusInstance"):
			if status_node.status_data == status_data:
				status_node._increment_counter(counter)
				#STANDARD STATUS LANGUAGE
				for status in get_node("Status").get_children():
					var check_status_data = status.status_data
					if check_status_data.status_activation == Status.ActivationCondition.ON_STATUS_INCREASED or check_status_data.status_activation == Status.ActivationCondition.ON_STATUS_UP:
						var returns = get_node("/root/BattleHandler")._activate_status_effects(status, check_status_data._parse_effects(), self)
						for value in returns:
							match value[0]:
								"power_through":
									power_through_status.append(status)
									power_through_damage.append(value[1])
						if status_data.status_tick_down == Status.TickDown.WHEN_ACTIVATED and returns[0][1] == 1:
							status._decrement_counter(1)
				return
	
	for status in get_node("Status").get_children():
		var check_status_data = status.status_data
		if check_status_data.status_activation == Status.ActivationCondition.ON_NEW_STATUS or check_status_data.status_activation == Status.ActivationCondition.ON_STATUS_UP:
			var returns = get_node("/root/BattleHandler")._activate_status_effects(status, check_status_data._parse_effects(), self)
			for value in returns:
				match value[0]:
					"power_through":
						power_through_status.append(status)
						power_through_damage.append(value[1])
			if status_data.status_tick_down == Status.TickDown.WHEN_ACTIVATED and returns[0][1] == 1:
				status._decrement_counter(1)
	
	for i in power_through_status.size():
		var status = power_through_status[i]
		var activated = get_node("/root/BattleHandler")._validate_status_condition_context(status, status_data)
		if activated:
			_take_damage(power_through_damage[i])
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
