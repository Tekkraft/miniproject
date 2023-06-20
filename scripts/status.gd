extends Resource

class_name Status

enum StatusType {BUFF, DEBUFF, SPECIAL}
enum TickDown {TURN_START, TURN_END, WHEN_ACTIVATED, NEVER}
enum ActivationCondition {TURN_START, TURN_END, ON_STATUS_INCREASED, ON_NEW_STATUS, ON_STATUS_UP, ON_ATTACKED, ON_ATTACKING}

@export var status_name : String
@export var status_icon : Texture2D
@export var status_class : StatusType
@export var status_activation : ActivationCondition
@export var status_triggers : PackedStringArray
@export var status_effects : PackedStringArray
@export var status_tick_down : TickDown
@export var status_flags : PackedStringArray
@export_multiline var status_description : String

func _parse_triggers():
	var return_array = []
	var parser = RegEx.new()
	parser.compile("^(?<action>\\w+)-(?<value>\\w+)(?:\\+(?<modifiers>[\\w:,]+))?$")
	for effect in status_triggers:
		var result = parser.search(effect)
		if result:
			return_array.append(StatusCondition.new(result.get_string("action"), result.get_string("value"), result.get_string("modifiers")))
		else:
			print("ERR>Invalid status effect: " + effect)
	return return_array

func _parse_effects():
	var return_array = []
	var parser = RegEx.new()
	parser.compile("^(?<action>\\w+)-(?<value>\\w+)(?:\\+(?<modifiers>[\\w:,]+))?$")
	for effect in status_effects:
		var result = parser.search(effect)
		if result:
			return_array.append(StatusEffect.new(result.get_string("action"), result.get_string("value"), result.get_string("modifiers")))
		else:
			print("ERR>Invalid status effect: " + effect)
	return return_array

class StatusEffect:
	var action : String
	var value : String
	var modifier : String
	
	func _init(action : String, value : String, modifier : String):
		self.action = action
		self.value = value
		self.modifier = modifier

class StatusCondition:
	var action : String
	var value : String
	var modifier : String
	
	func _init(action : String, value : String, modifier : String):
		self.action = action
		self.value = value
		self.modifier = modifier
