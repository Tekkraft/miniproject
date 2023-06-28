extends Control

var event_data : EventEncounter

var decision_node = preload("res://scenes/decision_node.tscn")
var card_list_overlay = preload("res://scenes/card_list_overlay.tscn")
var card_picker_overlay = preload("res://scenes/card_picker_overlay.tscn")

var offset = 16
var height = 64

signal selection_finished(data)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _setup(event_data : EventEncounter):
	self.event_data = event_data
	get_node("DescriptionPanel/EventTitle").text = event_data.event_name
	get_node("DescriptionPanel/EventDescription").text = event_data.event_content
	for i in event_data.event_options.size():
		var option = event_data.event_options[i]
		var new_option = decision_node.instantiate()
		get_node("DecisionPanel").add_child(new_option)
		var option_button = new_option.get_node("DecisionButton")
		option_button.text = option.option_name + ": " + option.option_description
		option_button.connect("pressed", _on_decision_button_pressed.bind(i))
		new_option.position.x = 16
		new_option.position.y = 16 + 64 * i
		var button_valid = _validate_event_conditions(option)
		if not button_valid:
			option_button.disabled = true

func _on_decision_button_pressed(index):
	var action = event_data.event_options[index]
	await _execute_event_effect(action)
	SceneHandler._load_run()

func _validate_event_conditions(event : EventOption):
	var conditions = event._parse_triggers()
	for condition in conditions:
		var modifier_dictionary = _modifier_dictionary_from_string(condition.modifier)
		match condition.action:
			"health":
				if modifier_dictionary.has("special"):
					match modifier_dictionary["special"]:
						"not_full":
							if RunHandler.current_hp == RunHandler.max_hp:
								return false
				else:
					print("WRN>Health condition not fully implemented")
			"has_relic":
				if not modifier_dictionary.has("id"):
					print("ERR>No id modifier.")
					continue
				var relic = load("res://relics/" + modifier_dictionary["id"] + ".tres")
				if modifier_dictionary.has("mod"):
					if modifier_dictionary["mod"] == "false":
						if RunHandler.current_relics.has(relic):
							return false
						else:
							continue
				if not RunHandler.current_relics.has(relic):
					return false
			"has_card":
				if not modifier_dictionary.has("id"):
					print("ERR>No id modifier.")
					continue
				if not modifier_dictionary.has("class"):
					print("ERR>No class modifier.")
					continue
				var card
				if modifier_dictionary["class"] == "null":
					card = load("res://cards/" + modifier_dictionary["id"] + ".tres")
				else:
					card = load("res://cards/" + modifier_dictionary["class"] + "_cards/" + modifier_dictionary["id"] + ".tres")
				if modifier_dictionary.has("mode"):
					if modifier_dictionary["mode"] == "or":
						if RunHandler.current_deck.has(card):
							return true
				if not RunHandler.current_deck.has(card):
					return false
			_:
				pass
	return true

func _execute_event_effect(action):
	var storage = {}
	var effects = action._parse_effects()
	for effect in effects:
		var modifier_dictionary = _modifier_dictionary_from_string(effect.modifier)
		match effect.action:
			"heal":
				RunHandler._direct_hp_heal(int(effect.value))
			"max_hp":
				var hp_value = int(effect.value)
				if not modifier_dictionary.has("mod"):
					print("ERR>No mod modifier.")
					continue
				match modifier_dictionary["mod"]:
					"neg":
						hp_value *= -1
				RunHandler._max_hp_increase(hp_value)
			"new_relic":
				if not modifier_dictionary.has("id"):
					print("ERR>No id modifier.")
					continue
				var relic = load("res://relics/" + modifier_dictionary["id"] + ".tres")
				RunHandler.current_relics.append(relic)
			"new_card":
				if not modifier_dictionary.has("id") and not modifier_dictionary.has("class"):
					print("ERR>No id or class modifier.")
					continue
				if modifier_dictionary.has("id") and not modifier_dictionary.has("class"):
					print("ERR>Id modifier without class modifier.")
					continue
				if modifier_dictionary.has("id"):
					var card = load("res://cards/" + modifier_dictionary["class"] + "_cards/" + modifier_dictionary["id"] + ".tres")
					RunHandler.current_deck.append(card)
				else:
					var available_cards = []
					match modifier_dictionary["class"]:
						"arcanist":
							var target_class = load("res://classes/arcanist.tres")
							available_cards.append_array(target_class.class_pool_cards)
							available_cards.append_array(target_class.class_start_cards)
						"duelist":
							var target_class = load("res://classes/duelist.tres")
							available_cards.append_array(target_class.class_pool_cards)
							available_cards.append_array(target_class.class_start_cards)
						"elementalist":
							var target_class = load("res://classes/elementalist.tres")
							available_cards.append_array(target_class.class_pool_cards)
							available_cards.append_array(target_class.class_start_cards)
						"warrior":
							var target_class = load("res://classes/warrior.tres")
							available_cards.append_array(target_class.class_pool_cards)
							available_cards.append_array(target_class.class_start_cards)
						"different":
							var available_classes = DataHandler._get_full_class_list() as Array
							available_classes.remove_at(available_classes.find(RunHandler.martial_class))
							available_classes.remove_at(available_classes.find(RunHandler.mystic_class))
							
							for sub_class in available_classes:
								available_cards.append_array(sub_class.class_pool_cards)
								available_cards.append_array(sub_class.class_start_cards)
					
					var card_picker = card_picker_overlay.instantiate()
					card_picker._setup_custom(available_cards)
					card_picker.connect("overlay_closed", _card_selection_blank)
					get_node("/root/").add_child(card_picker)
					await selection_finished
			"replace":
				if not modifier_dictionary.has("target") and not modifier_dictionary.has("target_class"):
					print("ERR>No target modifier.")
					continue
				if not modifier_dictionary.has("target"):
					print("ERR>No target modifier.")
					continue
				if not modifier_dictionary.has("id") and not modifier_dictionary.has("var"):
					print("ERR>No id or var modifier.")
					continue
				if modifier_dictionary.has("id") and not modifier_dictionary.has("class"):
					print("ERR>Id modifier without class modifier.")
					continue
				
				var target_card
				if modifier_dictionary.has("id"):
					load("res://cards/" + modifier_dictionary["class"] + "_cards/" + modifier_dictionary["id"] + ".tres")
				else:
					if not storage.has(modifier_dictionary["var"]):
						print("ERR>Variable not found.")
						continue
					target_card = storage[modifier_dictionary["var"]]
				
				var find_target
				if modifier_dictionary["target_class"] == "null":
					find_target = load("res://cards/" + modifier_dictionary["target"] + ".tres")
				else:
					find_target = load("res://cards/" + modifier_dictionary["target_class"] + "_cards/" + modifier_dictionary["target"] + ".tres")
				
				#In case replacement and selection are the same
				if target_card == find_target:
					continue
				
				while RunHandler.current_deck.find(find_target) != -1:
					RunHandler.current_deck.remove_at(RunHandler.current_deck.find(find_target))
					RunHandler.current_deck.append(target_card)
			"select":
				var list = card_list_overlay.instantiate()
				list.mouse_filter = Control.MOUSE_FILTER_IGNORE
				list._setup()
				for card_data in RunHandler.current_deck:
					var new_card = list._add_card(card_data)
					new_card.connect("card_activated", _card_selection)
				get_node("/root/").add_child(list)
				var result = await selection_finished
				if modifier_dictionary.has("store"):
					storage[modifier_dictionary["store"]] = result
				list._remove_overlay()
			_:
				pass

func _card_selection(card):
	emit_signal("selection_finished", card.card_data)

func _card_selection_blank():
	emit_signal("selection_finished", null)

func _modifier_dictionary_from_string(modifier_string : String):
	var modifiers_array = modifier_string.split(",")
	var modifiers_dictionary = {}
	for element in modifiers_array:
		if element == null or element == "":
			continue
		var element_array = element.split(":")
		if element_array.size() < 2:
			print("ERR>Invalid modifier construction")
			continue
		modifiers_dictionary[element_array[0]] = element_array[1]
	return modifiers_dictionary

func _display_card_list(card_list):
	var list = card_list_overlay.instantiate()
	list._setup()
	for card_data in card_list:
		list._add_card(card_data)
	get_node("/root/").add_child(list)

func _display_card_deck():
	_display_card_list(RunHandler.current_deck)
