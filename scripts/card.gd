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

var self_targeting = preload("res://sprites/targeting_icons/CardTargetingSelf.png")
var all_targeting = preload("res://sprites/targeting_icons/CardTargetingAll.png")
var aoe_targeting = preload("res://sprites/targeting_icons/CardTargetingAOE.png")
var melee_targeting = preload("res://sprites/targeting_icons/CardTargetingMelee.png")
var ranged_targeting = preload("res://sprites/targeting_icons/CardTargetingRanged.png")
var row_targeting = preload("res://sprites/targeting_icons/CardTargetingRowAny.png")
var rank_targeting = preload("res://sprites/targeting_icons/CardTargetingRankAny.png")
var front_rank_targeting = preload("res://sprites/targeting_icons/CardTargetingMeleeRank.png")

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

func _get_targeting_icon():
	if card_targeting_type == CardTargetingType.FREE:
		return self_targeting
	match card_targeting:
		CardTargeting.MELEE:
			if card_aoe == CardAOE.RANK:
				return front_rank_targeting
			else:
				return melee_targeting
		CardTargeting.TARGET, CardTargeting.TILE:
			match card_aoe:
				CardAOE.SINGLE:
					return ranged_targeting
				CardAOE.CROSS:
					return aoe_targeting
				CardAOE.ROW:
					return row_targeting
				CardAOE.RANK:
					return rank_targeting
				CardAOE.ALL:
					return all_targeting

func _get_targeting_text():
	if card_targeting_type == CardTargetingType.FREE:
		return "Self"
	match card_targeting:
		CardTargeting.MELEE:
			if card_aoe == CardAOE.RANK:
				return "Front Rank"
			else:
				return "Melee"
		CardTargeting.TARGET, CardTargeting.TILE:
			match card_aoe:
				CardAOE.SINGLE:
					return "Ranged"
				CardAOE.CROSS:
					return "Cross AOE"
				CardAOE.ROW:
					return "Any Row"
				CardAOE.RANK:
					return "Any Rank"
				CardAOE.ALL:
					return "All Enemies"

class CardEffect:
	var action : String
	var value : String
	var modifier : String
	
	func _init(action : String, value : String, modifier : String):
		self.action = action
		self.value = value
		self.modifier = modifier
