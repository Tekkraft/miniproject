extends Resource

class_name Relic

enum TurnCondition {NONE, ON_TURN_START, ON_TURN_END}
enum StatusCondition {NONE, ON_STATUS_INCREASED, ON_NEW_STATUS, ON_STATUS_UP}
enum CombatCondition {NONE, ON_ATTACKED, ON_ATTACKING}
enum CardCondition {NONE, ON_CARD_DRAW, ON_CARD_PLAYED, ON_CARD_DISCARD, ON_CARD_EXHAUST}
enum EncounterCondition {NONE, ON_ENTER_COMBAT, ON_EXIT_COMBAT, ON_ENTER_VILLAGE, ON_EXIT_VILLAGE}
enum ActivationClass {TURN_CONDITION, STATUS_CONDITON, COMBAT_CONDITON, CARD_CONDITION, ENCOUNTER_CONDITION}

@export var relic_name : String
@export var relic_icon : Texture2D
@export var relic_activation_class : ActivationClass
@export var relic_turn_condition: TurnCondition
@export var relic_status_condition: StatusCondition
@export var relic_combat_condition: CombatCondition
@export var relic_card_condition: CardCondition
@export var relic_encounter_condition: EncounterCondition
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
