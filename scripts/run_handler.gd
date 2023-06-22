extends Node

var current_deck = []

var current_relics = []

var current_hp = 100

var martial_class : CharacterClass
var mystic_class : CharacterClass

var current_encounter_count = 0
var encounters_to_boss = 8

var encounter_0 = preload("res://encounters/combat_encounters/rat_swarm.tres")
var encounter_1 = preload("res://encounters/combat_encounters/bandit_0.tres")
var encounter_2 = preload("res://encounters/combat_encounters/bandit_1.tres")

var elite_encounter_0 = preload("res://encounters/combat_encounters/bandit_elite_0.tres")

var boss_encounter_0 = preload("res://encounters/boss_encounters/black_knight.tres")

var early_encounters = [encounter_0, encounter_1, encounter_2]
var mid_encounters = [encounter_0, encounter_0, encounter_0, elite_encounter_0]
var late_encounters = [encounter_1, encounter_2, elite_encounter_0]
var boss_encounters = [boss_encounter_0]

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _setup_encounters():
	current_encounter_count = 1
	encounters_to_boss = 8

func _get_encounter_list():
	if current_encounter_count >= encounters_to_boss:
		return boss_encounters
	elif current_encounter_count < 3:
		return early_encounters
	elif current_encounter_count < encounters_to_boss - 3:
		return mid_encounters
	else:
		return late_encounters

func _advance_encounters():
	current_encounter_count += 1
