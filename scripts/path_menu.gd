extends Control

var combat_icon = preload("res://sprites/encounters/EncounterIconCombat.png")
var elite_icon = preload("res://sprites/encounters/EncounterIconElite.png")
var chest_icon = preload("res://sprites/encounters/EncounterIconChest.png")

var encounters = []

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _setup(encounter_list):
	encounters = encounter_list
	for i in encounters.size():
		var location_name = "Location" + str(i)
		match encounters[i].encounter_type:
			Encounter.EncounterType.COMBAT:
				get_node("RoutePanel/" + location_name + "Image").texture = combat_icon
			Encounter.EncounterType.ELITE:
				get_node("RoutePanel/" + location_name + "Image").texture = elite_icon
			Encounter.EncounterType.CHEST:
				get_node("RoutePanel/" + location_name + "Image").texture = chest_icon
			Encounter.EncounterType.BOSS:
				get_node("RoutePanel/" + location_name + "Image").texture = (encounters[i] as CombatEncounter).custom_icon
				

func _on_location_selected(location_index):
	SceneHandler._load_battle(encounters[location_index])
