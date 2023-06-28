extends Node

var martial_class_list = [] 
var mystic_class_list = []

var relic_0 = preload("res://relics/steel_sword.tres")
var relic_1 = preload("res://relics/steel_armor.tres")
var relic_2 = preload("res://relics/crystal_staff.tres")
var relic_3 = preload("res://relics/warding_robe.tres")
var relic_4 = preload("res://relics/azure_censer.tres")
var relic_5 = preload("res://relics/circlet_wisdom.tres")
var relic_6 = preload("res://relics/mending_bangle.tres")
var relic_7 = preload("res://relics/burning_bracer.tres")
#Travel gear goes here
#var relic_8 = preload("res://relics/steel_sword.tres")

var encounter_0 = preload("res://encounters/combat_encounters/rat_swarm.tres")
var encounter_1 = preload("res://encounters/combat_encounters/bandit_0.tres")
var encounter_2 = preload("res://encounters/combat_encounters/bandit_1.tres")

var elite_encounter_0 = preload("res://encounters/elite_encounters/bandit_elite_0.tres")

var boss_encounter_0 = preload("res://encounters/boss_encounters/black_knight.tres")

var chest_encounter_0 = preload("res://encounters/chest_encounters/chest_0.tres")

var village_encounter_0 = preload("res://encounters/village_encounters/village_0.tres")

var pre_boss_encounter_0 = preload("res://encounters/village_encounters/boss_village_black_knight.tres")

var event_encounter_0 = preload("res://encounters/event_encounters/healer.tres")
var event_encounter_1 = preload("res://encounters/event_encounters/trainer.tres")
var event_encounter_2 = preload("res://encounters/event_encounters/spirit.tres")
var event_encounter_3 = preload("res://encounters/event_encounters/shard.tres")

var general_relic_pool = [relic_0, relic_1, relic_2, relic_3, relic_4, relic_5, relic_6, relic_7]

var opening_encounters = [encounter_0, encounter_1, encounter_2]
var early_encounters = [encounter_0, encounter_1, encounter_2, event_encounter_0]
var mid_encounters = [encounter_0, encounter_0, encounter_0, elite_encounter_0, chest_encounter_0, village_encounter_0, event_encounter_0, event_encounter_1, event_encounter_2, event_encounter_3]
var late_encounters = [encounter_1, encounter_2, elite_encounter_0, chest_encounter_0, village_encounter_0, event_encounter_0, event_encounter_1, event_encounter_2, event_encounter_3]
var pre_boss_encounters = [pre_boss_encounter_0]
var boss_encounters = [boss_encounter_0]

# Called when the node enters the scene tree for the first time.
func _ready():
	var parser = XMLParser.new()
	parser.open("res://data/class_list.xml")
	while parser.read() != ERR_FILE_EOF:
		if parser.get_node_name() == "class":
			if parser.get_named_attribute_value_safe("name") == null:
				print("ERR>Invalid class name")
				continue
			var class_load = load("res://classes/" + parser.get_named_attribute_value_safe("name") + ".tres")
			if class_load == null:
				print("ERR>Class not found")
				continue
			match parser.get_named_attribute_value_safe("type"):
				"martial":
					martial_class_list.append(class_load)
				"mystic":
					mystic_class_list.append(class_load)
				_:
					print("ERR>Invalid class type")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _get_full_class_list():
	var full_list = martial_class_list.duplicate()
	full_list.append_array(mystic_class_list.duplicate())
	return full_list
