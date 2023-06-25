extends Resource

class_name Relic

@export var relic_name : String
@export var relic_icon : Texture2D
@export var relic_activation_class : LanguageHandler.ActivationClass
@export var relic_turn_condition: LanguageHandler.TurnCondition
@export var relic_status_condition: LanguageHandler.StatusCondition
@export var relic_combat_condition: LanguageHandler.CombatCondition
@export var relic_card_condition: LanguageHandler.CardCondition
@export var relic_encounter_condition: LanguageHandler.EncounterCondition
@export var relic_triggers : PackedStringArray
@export var relic_effects : PackedStringArray
@export_multiline var relic_description : String

func _parse_triggers():
	var return_array = []
	var parser = RegEx.new()
	parser.compile("^(?<action>\\w+)-(?<value>\\w+)(?:\\+(?<modifiers>[\\w:,]+))?$")
	for effect in relic_triggers:
		var result = parser.search(effect)
		if result:
			return_array.append(RelicCondition.new(result.get_string("action"), result.get_string("value"), result.get_string("modifiers")))
		else:
			print("ERR>Invalid status effect: " + effect)
	return return_array

func _parse_effects():
	var return_array = []
	var parser = RegEx.new()
	parser.compile("^(?<action>\\w+)-(?<value>\\w+)(?:\\+(?<modifiers>[\\w:,]+))?$")
	for effect in relic_effects:
		var result = parser.search(effect)
		if result:
			return_array.append(RelicEffect.new(result.get_string("action"), result.get_string("value"), result.get_string("modifiers")))
		else:
			print("ERR>Invalid status effect: " + effect)
	return return_array

class RelicEffect:
	var action : String
	var value : String
	var modifier : String
	
	func _init(action : String, value : String, modifier : String):
		self.action = action
		self.value = value
		self.modifier = modifier

class RelicCondition:
	var action : String
	var value : String
	var modifier : String
	
	func _init(action : String, value : String, modifier : String):
		self.action = action
		self.value = value
		self.modifier = modifier
