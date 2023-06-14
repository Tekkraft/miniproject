extends Control

var selected_martial : CharacterClass
var selected_mystic : CharacterClass

# Called when the node enters the scene tree for the first time.
func _ready():
	for item in DataHandler.martial_class_list:
		get_node("MartialClassSelect").add_item(item.class_name_var)
	for item in DataHandler.mystic_class_list:
		get_node("MysticClassSelect").add_item(item.class_name_var)
	get_node("CharacterInfoPanel/MartialClassName").text = "Please select a Martial Class"
	get_node("CharacterInfoPanel/MartialClassDescription").text = ""
	get_node("CharacterInfoPanel/MysticClassName").text = "Please select a Mystic Class"
	get_node("CharacterInfoPanel/MysticClassDescription").text = ""

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_martial_class_selected(index):
	selected_martial = DataHandler.martial_class_list[index]
	get_node("CharacterInfoPanel/MartialClassName").text = selected_martial.class_name_var
	get_node("CharacterInfoPanel/MartialClassDescription").text = selected_martial.class_description

func _on_mystic_class_selected(index):
	selected_mystic = DataHandler.mystic_class_list[index]
	get_node("CharacterInfoPanel/MysticClassName").text = selected_mystic.class_name_var
	get_node("CharacterInfoPanel/MysticClassDescription").text = selected_mystic.class_description

func _on_depart_button_pressed():
	if selected_martial == null or selected_mystic == null:
		return
	var deck = []
	var basic_attack = load("res://cards/basic_attack.tres")
	var basic_shield = load("res://cards/basic_shield.tres")
	for i in 3:
		deck.append(basic_attack)
	for i in 3:
		deck.append(basic_shield)
	for card in selected_martial.class_start_cards:
		for i in 2:
			deck.append(card)
	for card in selected_mystic.class_start_cards:
		for i in 2:
			deck.append(card)
	RunHandler.current_deck = deck.duplicate()
	RunHandler.current_hp = 100
	RunHandler.martial_class = selected_martial
	RunHandler.mystic_class = selected_mystic
	RunHandler._setup_encounters()
	SceneHandler._load_run()
