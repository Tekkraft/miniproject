extends Resource

class_name Card

enum CardTargetingType {SELECT, FREE}
enum CardTargeting {MELEE, TARGET, TILE}
enum CardAOE {SINGLE, CROSS, ROW, RANK, ALL, CUSTOM}
enum CardSkillType {MARTIAL, MYSTIC}
enum CardActionType {ATTACK, DEFENSE, SUPPORT, ABILITY}

@export var card_name : String
@export var card_cost : int
@export var card_sprite : Texture2D
@export_multiline var card_description : String
@export var card_effects : PackedStringArray
@export var card_targeting_type : CardTargetingType
@export var card_targeting : CardTargeting
@export var card_aoe : CardAOE
@export var card_targeting_modifier : String
@export var card_skill_type : CardSkillType
@export var card_action_type : CardActionType

func _parse_effects():
	var return_array = []
	var parser = RegEx.new()
	parser.compile("^(?<action>\\w+)-(?<value>\\w+)(?:\\+(?<modifiers>[\\w:,]+))?$")
	for effect in card_effects:
		var result = parser.search(effect)
		if result:
			return_array.append(CardEffect.new(result.get_string("action"), result.get_string("value"), result.get_string("modifiers")))
		else:
			print("ERR>Invalid card effect: " + effect)
	return return_array

class CardEffect:
	var action : String
	var value : String
	var modifier : String
	
	func _init(action : String, value : String, modifier : String):
		self.action = action
		self.value = value
		self.modifier = modifier
