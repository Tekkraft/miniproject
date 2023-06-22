extends Node

var card_pool = []
var card_deck = []
var card_hand = []
var card_discard = []
var card_exile = []
var enemy_map = [[null, null, null],[null, null, null],[null, null, null]]
var unit = preload("res://scenes/unit.tscn")
var card = preload("res://scenes/card.tscn")
var card_list_overlay = preload("res://scenes/card_list_overlay.tscn")

var max_energy = 3
var current_energy = 3

var current_turn = 0

var mouse_in_dead_zone = false

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var all_enemies = []
	for list in enemy_map:
		for enemy in list:
			if enemy != null:
				all_enemies.append(enemy)
	if all_enemies.size() == 0:
		RunHandler.current_hp = get_node("../BattleMap/Player").current_hp
		SceneHandler._load_after_battle()

func _setup(encounter_data : Encounter):
	get_node("/root/MainUI/EnergyMeter/EnergyLabel").text = str(current_energy) + "/" + str(max_energy)
	
	get_node("../MainUI/CardArea/DeadZone").connect("mouse_entered", _dead_zone_entered)
	get_node("../MainUI/CardArea/DeadZone").connect("mouse_exited", _dead_zone_exited)
	
	var unit_list = encounter_data._get_position_dictionary()
	for coord in unit_list:
		_create_enemy(unit_list[coord], coord)
	
	var all_enemies = []
	for list in enemy_map:
		for enemy in list:
			if enemy != null:
				all_enemies.append(enemy)
	
	var hostile_enemies = []
	for enemy in all_enemies:
		if enemy.current_hostility:
			hostile_enemies.append(enemy)
	while hostile_enemies.size() > ceili(all_enemies.size() / 2.0):
		var flip_enemy = hostile_enemies.pick_random()
		flip_enemy.current_hostility = false
		hostile_enemies.remove_at(hostile_enemies.find(flip_enemy))
	
	for enemy in all_enemies:
		enemy._generate_intent()
	
	get_node("../BattleMap/Player")._setup()
	
	get_node("../MainUI/EndTurnButton").connect("pressed", _end_player_turn)
	get_node("../MainUI/DeckButton").connect("pressed", _display_card_deck)
	get_node("../MainUI/DiscardButton").connect("pressed", _display_card_discard)
	get_node("../MainUI/ExileButton").connect("pressed", _display_card_exile)
	
	for card in RunHandler.current_deck:
		_create_card(card)
	_start_player_turn()

func _create_enemy(enemy_data : Unit, position : Vector2i):
	if enemy_map[position.x][position.y] == null:
		var new_enemy = unit.instantiate()
		var map_tile = get_node("../BattleMap/Tile_" + _vector2i_to_str(position))
		map_tile.add_child(new_enemy)
		new_enemy._setup(enemy_data, position)
		enemy_map[position.x][position.y] = new_enemy
		new_enemy.position.y -= 4
		for status in enemy_data.starting_statuses:
			new_enemy._create_status(status, 1)

func _remove_enemy(enemy):
	var position = enemy.current_location
	var removed = enemy_map[position.x][position.y] as Node2D
	if removed == null:
		return
	removed.get_parent().remove_child(removed)
	removed.queue_free()
	enemy_map[position.x][position.y] = null

func _vector2i_to_str(vector : Vector2i):
	return str(vector.x) + "_" + str(vector.y)

func _activate_card(source):
	pass

func _play_card(source):
	var map = get_node("../BattleMap")
	var data = source.card_data
	var effects = data._parse_effects()
	var return_data = []
	if mouse_in_dead_zone:
		return
	if current_energy < data.card_cost:
		return
	if data.card_targeting_type == Card.CardTargetingType.FREE:
		current_energy -= data.card_cost
		return_data.append_array(_activate_effects(map.get_node("Player"), effects, map.get_node("Player")))
	else:
		var tile = map._get_active_tile()
		if tile == null:
			return
		var enemy = enemy_map[tile.x][tile.y]
		if not _check_validity(data, tile):
			return
		#ONLY RUN IF ALL VALID
		current_energy -= data.card_cost
		match data.card_aoe:
			Card.CardAOE.SINGLE:
				return_data.append_array(_activate_effects(map.get_node("Player"), effects, enemy))
			Card.CardAOE.CROSS:
				if enemy != null:
					return_data.append_array(_activate_effects(map.get_node("Player"), effects, enemy))
				var tile_shift = tile + Vector2i(0,-1)
				if tile_shift.y >= 0:
					if enemy_map[tile_shift.x][tile_shift.y] != null:
						return_data.append_array(_activate_effects(map.get_node("Player"), effects, enemy_map[tile_shift.x][tile_shift.y]))
				tile_shift = tile + Vector2i(0,1)
				if tile_shift.y < enemy_map[0].size():
					if enemy_map[tile_shift.x][tile_shift.y] != null:
						return_data.append_array(_activate_effects(map.get_node("Player"), effects, enemy_map[tile_shift.x][tile_shift.y]))
				tile_shift = tile + Vector2i(-1,0)
				if tile_shift.x >= 0:
					if enemy_map[tile_shift.x][tile_shift.y] != null:
						return_data.append_array(_activate_effects(map.get_node("Player"), effects, enemy_map[tile_shift.x][tile_shift.y]))
				tile_shift = tile + Vector2i(1,0)
				if tile_shift.x < enemy_map.size():
					if enemy_map[tile_shift.x][tile_shift.y] != null:
						return_data.append_array(_activate_effects(map.get_node("Player"), effects, enemy_map[tile_shift.x][tile_shift.y]))
			Card.CardAOE.ROW:
				for i in enemy_map.size():
					if enemy_map[i][tile.y] != null:
						return_data.append_array(_activate_effects(map.get_node("Player"), effects, enemy_map[i][tile.y]))
			Card.CardAOE.RANK:
				for i in enemy_map[tile.x].size():
					if enemy_map[tile.x][i] != null:
						return_data.append_array(_activate_effects(map.get_node("Player"), effects, enemy_map[tile.x][i]))
			Card.CardAOE.ALL:
				for row in enemy_map:
					for target in row:
						if target != null:
							return_data.append_array(_activate_effects(map.get_node("Player"), effects, target))
			Card.CardAOE.CUSTOM:
				pass
	
	var discard = true
	for value in return_data:
		if value[0] == "exhaust_self":
			discard = false
	
	if discard:
		_discard_card(source)
	else:
		_exile_card(source)
	
	get_node("/root/MainUI/EnergyMeter/EnergyLabel").text = str(current_energy) + "/" + str(max_energy)
	if card_hand.size() <= 0:
		_end_player_turn()

func _check_validity(card_data, target_location):
	var enemy = enemy_map[target_location.x][target_location.y]
	if enemy == null && card_data.card_targeting != Card.CardTargeting.TILE:
		return false
	if _melee_invalid(card_data, target_location):
		return false
	return true

func _melee_invalid(card_data, target_location):
	if card_data.card_targeting != Card.CardTargeting.MELEE:
		return false
	for i in target_location.x:
		if enemy_map[i][target_location.y] != null:
			return true
	return false

func _create_card(card_res : Card):
	var new_card = card.instantiate()
	new_card.name = "Card_" + str(card_pool.size())
	new_card._setup(card_res)
	card_pool.append(new_card)
	card_deck.append(new_card)
	new_card.connect("card_activated", _activate_card)
	new_card.connect("card_released", _play_card)
	_shuffle_deck()

func _draw_card():
	if card_deck.size() <= 0:
		_resuffle_discard()
	if card_deck.size() <= 0 && card_discard.size() <= 0:
		return
	var drawn = card_deck.pop_front()
	card_hand.append(drawn)
	get_node("/root/MainUI/CardArea").add_child(drawn)
	drawn.position = Vector2(0, 0)
	_realign_cards()

func _discard_card(card):
	var index = card_hand.find(card)
	if index == -1:
		return
	card_discard.append(card)
	card_hand.remove_at(index)
	get_node("/root/MainUI/CardArea").remove_child(card)
	_realign_cards()

func _exile_card(card):
	var index = card_hand.find(card)
	if index == -1:
		return
	card_exile.append(card)
	card_hand.remove_at(index)
	get_node("/root/MainUI/CardArea").remove_child(card)
	_realign_cards()

func _return_card(card):
	var index = card_hand.find(card)
	if index == -1:
		return
	card_deck.append(card)
	card_hand.remove_at(index)
	get_node("/root/MainUI/CardArea").remove_child(card)
	_shuffle_deck()
	_realign_cards()

func _shuffle_deck():
	card_deck.shuffle()

func _resuffle_discard():
	card_deck.append_array(card_discard)
	card_discard.clear()
	_shuffle_deck()

func _discard_hand():
	for i in card_hand.size():
		_discard_card(card_hand[0])

func _draw_hand():
	for i in 6:
		_draw_card()

func _realign_cards():
	var width = 1328
	var target_margin = 8
	var card_scale = 1.5
	var card_width = int(128 * card_scale)
	var margin = 8
	if width >= 16 + 16 + (card_width + target_margin) * card_hand.size() + card_width:
		margin = 8
	else:
		var test_margin = target_margin - 1
		while width >= 16 + 16 + (card_width + test_margin) * card_hand.size() + card_width:
			test_margin -= 1
		margin = test_margin
	
	for i in card_hand.size():
		card_hand[i].position.x =  (i - card_hand.size() / 2.0) * (card_width + margin) + (card_width / 2) + 16

func _activate_effects(origin, effects, target):
	var target_dead = false
	if not true:
		return [["activation", 0]]
	var activation_return = [["activation", 1]]
	for effect in effects:
		var modifiers = effect.modifier
		var modifiers_array = modifiers.split(",")
		var modifiers_dictionary = {}
		for element in modifiers_array:
			if element == null or element == "":
				continue
			var element_array = element.split(":")
			if element_array.size() < 2:
				print("ERR>Invalid modifier construction")
				continue
			modifiers_dictionary[element_array[0]] = element_array[1]
		match effect.action:
			"damage":
				if target_dead:
					continue
				var base_damage = int(effect.value)
				var modified_damage = base_damage
				var crit_mod = 1
				for status in origin.get_node("Status").get_children():
					var status_data = status.status_data
					if status_data.status_activation == Status.ActivationCondition.ON_ATTACKING:
						var returns = _activate_status_effects(status, status_data._parse_effects(), origin)
						for value in returns:
							match value[0]:
								"critical":
									crit_mod += value[1]
								"phys_atk":
									modified_damage += value[1]
						if status_data.status_tick_down == Status.TickDown.WHEN_ACTIVATED and returns[0][1] == 1:
							status._decrement_counter(1)
				modified_damage *= crit_mod
				modified_damage = max(0, modified_damage)
				var dead = target._take_damage(modified_damage)
				if dead:
					if target.name == "Player":
						SceneHandler._load_menu()
						return
					_remove_enemy(target)
					target_dead = true
			"shield":
				if modifiers_dictionary.has("target") and modifiers_dictionary["target"] == "self":
					origin._gain_shield(int(effect.value))
				else:
					if target_dead:
						continue
					target._gain_shield(int(effect.value))
			"heal":
				if target_dead:
					continue
				target._restore_health(int(effect.value))
			"draw":
				for i in effect.value:
					_draw_card()
			"status":
				if not modifiers_dictionary.has("id"):
					print("ERR>No id modifier.")
					continue
				var status_data = load("res://statuses/" + modifiers_dictionary["id"] + ".tres")
				if status_data == null:
					print("ERR>No such status.")
					continue
				
				if modifiers_dictionary.has("target") and modifiers_dictionary["target"] == "self":
					origin._create_status(status_data, int(effect.value))
				else:
					if target_dead:
						continue
					target._create_status(status_data, int(effect.value))
			"exhaust_self":
				activation_return.append(["exhaust_self", int(effect.value)])
	
	for status in origin.get_node("Status").get_children():
		status.activated = false
	
	return activation_return

func _end_player_turn():
	_discard_hand()
	_start_enemy_turn()

func _start_enemy_turn():
	var all_enemies = []
	for list in enemy_map:
		for enemy in list:
			if enemy != null:
				all_enemies.append(enemy)
	
	for enemy in all_enemies:
		enemy._clear_shields()
	
	_activate_enemies()
	_end_enemy_turn()

func _end_enemy_turn():
	var all_enemies = []
	for list in enemy_map:
		for enemy in list:
			if enemy != null:
				all_enemies.append(enemy)
	
	var hostile_enemies = []
	for enemy in all_enemies:
		if enemy.current_hostility:
			hostile_enemies.append(enemy)
	while hostile_enemies.size() > ceili(all_enemies.size() / 2.0):
		var flip_enemy = hostile_enemies.pick_random()
		flip_enemy.current_hostility = false
		hostile_enemies.remove_at(hostile_enemies.find(flip_enemy))
	
	for enemy in all_enemies:
		enemy._generate_intent()
	_start_player_turn()

func _start_player_turn():
	get_node("../BattleMap/Player")._clear_shields()
	_draw_hand()
	current_turn += 1
	current_energy = max_energy
	get_node("/root/MainUI/EnergyMeter/EnergyLabel").text = str(current_energy) + "/" + str(max_energy)

func _activate_enemies():
	var all_enemies = []
	for list in enemy_map:
		for enemy in list:
			if enemy != null:
				all_enemies.append(enemy)
	
	for enemy in all_enemies:
		for status in enemy.get_node("Status").get_children():
			var status_data = status.status_data
			if status_data.status_activation == Status.ActivationCondition.TURN_START:
				var returns = _activate_status_effects(status, status_data._parse_effects(), enemy)
				if status_data.status_tick_down == Status.TickDown.WHEN_ACTIVATED and returns[0][1] == 1:
					status._decrement_counter(1)
			if status_data.status_tick_down == Status.TickDown.TURN_START:
				status._decrement_counter(1)
		
		var action = enemy.current_intent as Action
		match action.action_type:
			Action.ActionType.ATTACK, Action.ActionType.DEBUFF:
				_activate_effects(enemy, action._parse_effects(), get_node("../BattleMap/Player"))
			Action.ActionType.SHIELD, Action.ActionType.BUFF, Action.ActionType.RELOAD, Action.ActionType.CANCELED:
				_activate_effects(enemy, action._parse_effects(), enemy)
			_:
				print("ERR>Invalid Action Type: " + str(action.action_type))
	
	for enemy in all_enemies:
		for status in enemy.get_node("Status").get_children():
			var status_data = status.status_data
			if status_data.status_activation == Status.ActivationCondition.TURN_END:
				var returns = _activate_status_effects(status, status_data._parse_effects(), enemy)
				if status_data.status_tick_down == Status.TickDown.WHEN_ACTIVATED and returns[0][1] == 1:
					status._decrement_counter(1)
			if status_data.status_tick_down == Status.TickDown.TURN_END:
				status._decrement_counter(1)

func _activate_status_effects(status, effects, target):
	if status.activated:
		return [["activation", 0]]
	status.activated = true
	if not _validate_status_condition(status):
		return [["activation", 0]]
	var activation_return = [["activation", 1]]
	for effect in effects:
		var modifiers = effect.modifier
		var modifiers_array = modifiers.split(",")
		var modifiers_dictionary = {}
		for element in modifiers_array:
			if element == null or element == "":
				continue
			var element_array = element.split(":")
			if element_array.size() < 2:
				print("ERR>Invalid modifier construction")
				continue
			modifiers_dictionary[element_array[0]] = element_array[1]
		match effect.action:
			"damage":
				var dead = target._take_damage(int(effect.value))
				if dead:
					if target.name == "Player":
						SceneHandler._load_menu()
						return
					_remove_enemy(target)
			"stack_damage":
				var dead = target._take_damage(status.status_counter)
				if dead:
					if target.name == "Player":
						SceneHandler._load_menu()
						return
					_remove_enemy(target)
			"critical":
				activation_return.append(["critical", status.status_counter])
			"clear":
				var clear_val : int
				match effect.value:
					"all":
						clear_val = status.status_counter
					_:
						clear_val = int(effect.value)
				if not status == null:
					status._decrement_counter(clear_val)
			"status":
				if not modifiers_dictionary.has("id"):
					print("ERR>No id modifier.")
					continue
				var status_data = load("res://statuses/" + modifiers_dictionary["id"] + ".tres")
				if status_data == null:
					print("ERR>No such status.")
					continue
				target._create_status(status_data, int(effect.value))
			"dodge":
				activation_return.append(["dodge", effect.value])
			"phys_atk":
				var damage_modifier = int(effect.value) * status.status_counter
				if not modifiers_dictionary.has("mod"):
					print("ERR>No mod modifier.")
					continue
				match modifiers_dictionary["mod"]:
					"neg":
						damage_modifier *= -1
				activation_return.append(["phys_atk", damage_modifier])
			"phys_def":
				var damage_modifier = int(effect.value) * status.status_counter
				if not modifiers_dictionary.has("mod"):
					print("ERR>No mod modifier.")
					continue
				match modifiers_dictionary["mod"]:
					"neg":
						damage_modifier *= -1
				activation_return.append(["phys_def", damage_modifier])
			"cancel_intent":
				if target.is_in_group("Player"):
					print("ERR>Player stun not implemented.")
					continue
				target._cancel_intent()
				status._decrement_counter(status.status_counter)
			"power_through":
				activation_return.append(["power_through", int(effect.value)])
	
	return activation_return

func _validate_status_condition(status):
	var triggers = status.status_data._parse_triggers()
	for condition in triggers:
		var modifiers = condition.modifier
		var modifiers_array = modifiers.split(",")
		var modifiers_dictionary = {}
		for element in modifiers_array:
			if element == null or element == "":
				continue
			var element_array = element.split(":")
			if element_array.size() < 2:
				print("ERR>Invalid modifier construction")
				continue
			modifiers_dictionary[element_array[0]] = element_array[1]
		match condition.action:
			"counter":
				if status.status_counter < int(condition.value):
					return false
	return true

func _validate_status_condition_context(status, context):
	var triggers = status.status_data._parse_triggers()
	for condition in triggers:
		var modifiers = condition.modifier
		var modifiers_array = modifiers.split(",")
		var modifiers_dictionary = {}
		for element in modifiers_array:
			if element == null or element == "":
				continue
			var element_array = element.split(":")
			if element_array.size() < 2:
				print("ERR>Invalid modifier construction")
				continue
			modifiers_dictionary[element_array[0]] = element_array[1]
		match condition.action:
			"status_flag":
				if not modifiers_dictionary.has("flag"):
					print("ERR>No flag modifier.")
					continue
				for flag in context.status_flags:
					if flag == modifiers_dictionary["flag"]:
						return true
	return false

func _display_card_list(card_list):
	var list = card_list_overlay.instantiate()
	list._setup()
	for card_object in card_list:
		list._add_card(card_object.card_data)
	get_node("/root/").add_child(list)

func _display_card_deck():
	var copy = card_deck.duplicate()
	copy.shuffle()
	_display_card_list(copy)

func _display_card_discard():
	_display_card_list(card_discard)

func _display_card_exile():
	_display_card_list(card_exile)

func _dead_zone_entered():
	mouse_in_dead_zone = true

func _dead_zone_exited():
	mouse_in_dead_zone = false
