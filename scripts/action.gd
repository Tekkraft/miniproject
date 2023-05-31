extends Resource

class_name Action

enum ActionType {ATTACK, SHIELD, BUFF, DEBUFF}

var attack_icon = preload("res://sprites/intents/EnemyIntentAttack.png")
var shield_icon = preload("res://sprites/intents/EnemyIntentShield.png")
var buff_icon = preload("res://sprites/intents/EnemyIntentBuff.png")
var debuff_icon = preload("res://sprites/intents/EnemyIntentDebuff.png")

@export var action_name : String
@export var action_type : ActionType
@export var action_effects : PackedStringArray

func _get_action_icon():
	match action_type:
		ActionType.ATTACK:
			return attack_icon
		ActionType.SHIELD:
			return shield_icon
		ActionType.BUFF:
			return buff_icon
		ActionType.DEBUFF:
			return debuff_icon
		_:
			print("ERR>Invalid Action Type")
			return attack_icon

func _parse_effects():
	var return_array = []
	var parser = RegEx.new()
	parser.compile("^(?<action>\\w+)-(?<value>\\w+)(?:\\+(?<modifiers>[\\w:,]+))?$")
	for effect in action_effects:
		var result = parser.search(effect)
		if result:
			return_array.append(ActionEffect.new(result.get_string("action"), result.get_string("value"), result.get_string("modifiers")))
		else:
			print("ERR>Invalid action effect: " + effect)
	return return_array

func _get_action_display_value():
	if action_type == ActionType.ATTACK:
		return _calculate_damage()
	else:
		return "0"

func _calculate_damage():
	var effect_array = _parse_effects()
	var damage_elements = []
	var damage_string = ""
	for effect in effect_array:
		if effect.action == "damage":
			if damage_elements.size() == 0:
				damage_elements.append(str(effect.value))
				continue
			var previous = damage_elements[damage_elements.size() - 1]
			var previous_split = previous.split("*")
			if previous_split[0] == str(effect.value):
				if previous_split.size() == 1:
					damage_elements[damage_elements.size() - 1] = previous_split[0] + "*2"
					continue
				damage_elements[damage_elements.size() - 1] = previous_split[0] + "*" + str(int(previous_split[1]) + 1)
			else:
				damage_elements.append(str(effect.value))
	damage_string = damage_elements[0]
	for i in damage_elements.size() - 1:
		damage_string += "+" + damage_elements[i + 1]
	return damage_string


class ActionEffect:
	var action : String
	var value : String
	var modifier : String
	
	func _init(action : String, value : String, modifier : String):
		self.action = action
		self.value = value
		self.modifier = modifier
