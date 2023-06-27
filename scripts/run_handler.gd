extends Node

var current_deck = []

var current_relics = []

var current_hp = 100
var max_hp = 100

var martial_class : CharacterClass
var mystic_class : CharacterClass

var current_encounter_count = 0
var encounters_to_boss = 10
var bounding_encounter_threshold = 3

var relic_pool = []

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _setup_encounters():
	current_encounter_count = 1
	encounters_to_boss = 8

func _get_random_relic():
	if relic_pool.size() <= 0:
		return
	
	var new_relic = relic_pool.pick_random()
	relic_pool.remove_at(relic_pool.find(new_relic))
	current_relics.append(new_relic)

func _get_encounter_list():
	if current_encounter_count >= encounters_to_boss:
		return DataHandler.boss_encounters
	elif current_encounter_count < bounding_encounter_threshold:
		return DataHandler.early_encounters
	elif current_encounter_count < encounters_to_boss - bounding_encounter_threshold:
		return DataHandler.mid_encounters
	else:
		return DataHandler.late_encounters

func _advance_encounters():
	current_encounter_count += 1

func _setup_hp(value : int):
	current_hp = value
	max_hp = value

func _setup_relics():
	current_relics = []
	relic_pool = DataHandler.general_relic_pool.duplicate()
