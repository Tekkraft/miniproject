extends Control

var card_list_overlay = preload("res://scenes/card_list_overlay.tscn")
var card_picker_overlay = preload("res://scenes/card_picker_overlay.tscn")

var max_rest_points : int
var rest_points : int

signal selection_finished(card_data)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	get_node("RestPointPanel/RestPointCounter").text = str(rest_points) + "/" + str(max_rest_points)
	
	#Button Checks
	if rest_points <= 0:
		get_node("ActionPanel/RestPanel/ActionButton").disabled = true
		get_node("ActionPanel/StudyPanel/ActionButton").disabled = true
		get_node("ActionPanel/StrategizePanel/ActionButton").disabled = true
		get_node("ActionPanel/UpgradePanel/ActionButton").disabled = true
		return
	
	if RunHandler.current_hp >= RunHandler.max_hp:
		get_node("ActionPanel/RestPanel/ActionButton").disabled = true
	if RunHandler.current_hp < RunHandler.max_hp:
		get_node("ActionPanel/RestPanel/ActionButton").disabled = false
	

func _setup(encounter_data : VillageEncounter):
	self.max_rest_points = encounter_data.available_rest_points
	self.rest_points = encounter_data.available_rest_points
	get_node("DescriptionPanel/VillageName").text = encounter_data._get_village_name()
	get_node("DescriptionPanel/VillageDescription").text = encounter_data.village_description

func _on_view_deck_button_pressed():
	var list = card_list_overlay.instantiate()
	list._setup()
	for card_data in RunHandler.current_deck:
		list._add_card(card_data)
	get_node("/root/").add_child(list)

func _on_exit_to_run():
	SceneHandler._load_run()

func _rest_action():
	if rest_points < 1:
		get_node("ActionPanel/RestPanel/ActionButton").disabled = true
		return
	
	rest_points -= 1
	#Restore 10% max hp
	RunHandler._direct_hp_heal(RunHandler.max_hp * 0.1)

func _study_action():
	if rest_points < 1:
		get_node("ActionPanel/StudyPanel/ActionButton").disabled = true
		return
	
	rest_points -= 1
	
	var card_picker = card_picker_overlay.instantiate()
	card_picker._setup()
	card_picker.connect("overlay_closed", _card_selection_blank)
	get_node("/root/").add_child(card_picker)
	await selection_finished


func _strategize_action():
	if rest_points < 1:
		get_node("ActionPanel/StrategizePanel/ActionButton").disabled = true
		return
	
	rest_points -= 1
	
	var list = card_list_overlay.instantiate()
	list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	list._setup()
	for card_data in RunHandler.current_deck:
		var new_card = list._add_card(card_data)
		new_card.connect("card_activated", _card_selection)
	get_node("/root/").add_child(list)
	var result = await selection_finished
	list._remove_overlay()
	
	RunHandler.current_deck.remove_at(RunHandler.current_deck.find(result))

func _upgrade_action():
	if rest_points < 1:
		get_node("ActionPanel/UpgradePanel/ActionButton").disabled = true
		return
	
	rest_points -= 1

func _card_selection(card):
	emit_signal("selection_finished", card.card_data)

func _card_selection_blank():
	emit_signal("selection_finished", null)
