extends Resource

class_name EventOption

@export var option_name : String
@export_multiline var option_description : String
@export var option_conditions : PackedStringArray
@export var option_effects : PackedStringArray


func _parse_triggers():
	var return_array = []
	var parser = RegEx.new()
	parser.compile("^(?<action>\\w+)-(?<value>\\w+)(?:\\+(?<modifiers>[\\w:,]+))?$")
	for effect in option_conditions:
		var result = parser.search(effect)
		if result:
			return_array.append(EventCondition.new(result.get_string("action"), result.get_string("value"), result.get_string("modifiers")))
		else:
			print("ERR>Invalid event trigger: " + effect)
	return return_array

func _parse_effects():
	var return_array = []
	var parser = RegEx.new()
	parser.compile("^(?<action>\\w+)-(?<value>\\w+)(?:\\+(?<modifiers>[\\w:,]+))?$")
	for effect in option_effects:
		var result = parser.search(effect)
		if result:
			return_array.append(EventEffect.new(result.get_string("action"), result.get_string("value"), result.get_string("modifiers")))
		else:
			print("ERR>Invalid event effect: " + effect)
	return return_array

class EventEffect:
	var action : String
	var value : String
	var modifier : String
	
	func _init(action : String, value : String, modifier : String):
		self.action = action
		self.value = value
		self.modifier = modifier

class EventCondition:
	var action : String
	var value : String
	var modifier : String
	
	func _init(action : String, value : String, modifier : String):
		self.action = action
		self.value = value
		self.modifier = modifier
