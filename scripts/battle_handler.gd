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
var relic = preload("res://scenes/relic.tscn")

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

	for relic in RunHandler.current_relics:
		_create_relic(relic)

	_start_player_turn()


func _create_card(card_res : Card):
	var new_card = card.instantiate()
	new_card.name = "Card_" + str(card_pool.size())
	new_card._setup(card_res)
	card_pool.append(new_card)
	card_deck.append(new_card)
	new_card.connect("card_activated", _activate_card)
	new_card.connect("card_released", _play_card)
	new_card.add_to_group("CardInstance")
	_shuffle_deck()

func _create_relic(relic_res : Relic):
	var new_relic = relic.instantiate() as Node2D
	new_relic.name = "Relic_" + str(get_node("../MainUI/RelicArea").get_child_count())
	new_relic._setup(relic_res, 0)
	get_node("../MainUI/RelicArea").add_child(new_relic)
	new_relic.add_to_group("RelicInstance")
	new_relic.position.y = (get_node("../MainUI/RelicArea").get_child_count() - 1) * ((64 + 24) * new_relic.scale.x + 16)

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
	var player = map.get_node("Player")
	var return_data = []
	var targets = []
	if mouse_in_dead_zone:
		return
	if current_energy < data.card_cost:
		return
	if data.card_targeting_type == Card.CardTargetingType.FREE:
		current_energy -= data.card_cost
		targets = [player]
		#return_data.append_array(_activate_effects(player, effects, player))
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
				targets = [enemy]
				#return_data.append_array(_activate_effects(map.get_node("Player"), effects, enemy))
			Card.CardAOE.CROSS:
				if enemy != null:
					targets.append(enemy)
					#return_data.append_array(_activate_effects(map.get_node("Player"), effects, enemy))
				var tile_shift = tile + Vector2i(0,-1)
				if tile_shift.y >= 0:
					if enemy_map[tile_shift.x][tile_shift.y] != null:
						targets.append(enemy_map[tile_shift.x][tile_shift.y])
						#return_data.append_array(_activate_effects(map.get_node("Player"), effects, enemy_map[tile_shift.x][tile_shift.y]))
				tile_shift = tile + Vector2i(0,1)
				if tile_shift.y < enemy_map[0].size():
					if enemy_map[tile_shift.x][tile_shift.y] != null:
						targets.append(enemy_map[tile_shift.x][tile_shift.y])
						#return_data.append_array(_activate_effects(map.get_node("Player"), effects, enemy_map[tile_shift.x][tile_shift.y]))
				tile_shift = tile + Vector2i(-1,0)
				if tile_shift.x >= 0:
					if enemy_map[tile_shift.x][tile_shift.y] != null:
						targets.append(enemy_map[tile_shift.x][tile_shift.y])
						#return_data.append_array(_activate_effects(map.get_node("Player"), effects, enemy_map[tile_shift.x][tile_shift.y]))
				tile_shift = tile + Vector2i(1,0)
				if tile_shift.x < enemy_map.size():
					if enemy_map[tile_shift.x][tile_shift.y] != null:
						targets.append(enemy_map[tile_shift.x][tile_shift.y])
						#return_data.append_array(_activate_effects(map.get_node("Player"), effects, enemy_map[tile_shift.x][tile_shift.y]))
			Card.CardAOE.ROW:
				for i in enemy_map.size():
					if enemy_map[i][tile.y] != null:
						targets.append(enemy_map[i][tile.y])
						#return_data.append_array(_activate_effects(map.get_node("Player"), effects, enemy_map[i][tile.y]))
			Card.CardAOE.RANK:
				for i in enemy_map[tile.x].size():
					if enemy_map[tile.x][i] != null:
						targets.append(enemy_map[tile.x][i])
						#return_data.append_array(_activate_effects(map.get_node("Player"), effects, enemy_map[tile.x][i]))
			Card.CardAOE.ALL:
				for row in enemy_map:
					for target in row:
						if target != null:
							targets.append(target)
							#return_data.append_array(_activate_effects(map.get_node("Player"), effects, target))
			Card.CardAOE.CUSTOM:
				pass
	
	_execute_actions(player, targets, effects)
	
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
					if status_data.status_activation == LanguageHandler.CombatCondition.ON_ATTACKING:
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
		#for status in enemy.get_node("Status").get_children():
		#	var status_data = status.status_data
		#	if status_data.status_activation == LanguageHandler.TurnCondition.ON_TURN_START:
		#		var returns = _activate_status_effects(status, status_data._parse_effects(), enemy)
		#		if status_data.status_tick_down == Status.TickDown.WHEN_ACTIVATED and returns[0][1] == 1:
		#			status._decrement_counter(1)
		#	if status_data.status_tick_down == Status.TickDown.TURN_START:
		#		status._decrement_counter(1)
		
		var targets = []
		
		var action = enemy.current_intent as Action
		match action.action_type:
			Action.ActionType.ATTACK, Action.ActionType.DEBUFF:
				targets.append(get_node("../BattleMap/Player"))
				#_activate_effects(enemy, action._parse_effects(), get_node("../BattleMap/Player"))
			Action.ActionType.SHIELD, Action.ActionType.BUFF, Action.ActionType.RELOAD, Action.ActionType.CANCELED:
				targets.append(enemy)
				#_activate_effects(enemy, action._parse_effects(), enemy)
			_:
				print("ERR>Invalid Action Type: " + str(action.action_type))
		
		_execute_actions(enemy, targets, action._parse_effects())
	
	#for enemy in all_enemies:
	#	for status in enemy.get_node("Status").get_children():
	#		var status_data = status.status_data
	#		if status_data.status_activation == LanguageHandler.TurnCondition.ON_TURN_END:
	#			var returns = _activate_status_effects(status, status_data._parse_effects(), enemy)
	#			if status_data.status_tick_down == Status.TickDown.WHEN_ACTIVATED and returns[0][1] == 1:
	#				status._decrement_counter(1)
	#		if status_data.status_tick_down == Status.TickDown.TURN_END:
	#			status._decrement_counter(1)

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

#Reworked combat flow:
# Calculate offensive relics
# Calculate offensive statuses
# Save, activate, and transmit
# Calculate defensive relics
# Calculate defensive statuses
# Save, activate, and transmit
# Calculate card effects
# Calculate resolution relics
# Calculate resolution statuses 

func _execute_actions(attacker, targets, effects):
	var execution_returns = {}
	var converted_effects = []
	for sub_effect in effects:
		var new_effect = BattleEffect.new()
		new_effect._init_from_typed(sub_effect, null)
		converted_effects.append(new_effect)
	var attacker_pre_effects = _generate_attacker_effects(attacker)
	#Attacker self-effects
	var attacker_returns = _execute_effects(attacker, attacker, attacker_pre_effects, {})
	var attacker_execution_returns = attacker_returns[0]
	var attacker_carry_returns = attacker_returns[1]
	execution_returns.merge(attacker_execution_returns)
	for target in targets:
		var defender_pre_effects = _generate_defender_effects(target)
		#Defender effects
		var defender_returns = _execute_effects(target, target, defender_pre_effects, {})
		var defender_execution_returns = defender_returns[0]
		execution_returns.merge(defender_execution_returns)
		var defender_carry_returns = defender_returns[1]
		#Card effects
		var merged_returns = attacker_carry_returns.duplicate()
		merged_returns.merge(defender_carry_returns)
		var card_returns = _execute_effects(attacker, target, converted_effects, merged_returns)
		#Resolution effects
		#NONE YET

func _generate_attacker_effects(unit):
	var attacker_effects = []
	var relic_data = _generate_relic_effects(LanguageHandler.ActivationClass.COMBAT_CONDITON, LanguageHandler.CombatCondition.ON_ATTACKING)
	var status_data = _generate_status_effects(unit, LanguageHandler.ActivationClass.COMBAT_CONDITON, LanguageHandler.CombatCondition.ON_ATTACKING)
	attacker_effects.append_array(relic_data[0])
	attacker_effects.append_array(status_data[0])
	return attacker_effects

func _generate_defender_effects(unit):
	var defender_effects = []
	var relic_data = _generate_relic_effects(LanguageHandler.ActivationClass.COMBAT_CONDITON, LanguageHandler.CombatCondition.ON_ATTACKED)
	var status_data = _generate_status_effects(unit, LanguageHandler.ActivationClass.COMBAT_CONDITON, LanguageHandler.CombatCondition.ON_ATTACKED)
	defender_effects.append_array(relic_data[0])
	defender_effects.append_array(status_data[0])
	return defender_effects

#Execution Returns : Things the unit executing the main effect needs to know.
#Carry Returns : Things the unit taking the main effect needs to know, such as critical.
func _execute_effects(origin, target, effects_list, carry_data):
	var execution_returns = {}
	var carry_returns = {}
	var target_dead = false
	for effect in effects_list:
		match effect.action:
			"damage":
				if target_dead:
					continue
				var base_damage = int(effect.value)
				var modified_damage = base_damage
				var crit_mod = 1
				#CRITICAL AND DAMAGE UP/DOWN
				if carry_data.has("critical"):
					crit_mod += carry_data["critical"]
					carry_data.erase("critical")
				if carry_data.has("phys_atk"):
					modified_damage += carry_data["phys_atk"]
				modified_damage *= crit_mod
				
				if carry_data.has("dodge"):
					if carry_data["dodge"] > 0:
						modified_damage = 0
						carry_data["dodge"] -= 1
				if carry_data.has("phys_def"):
					modified_damage -= carry_data["phys_def"]
				
				modified_damage = max(0, modified_damage)
				var dead = target._take_damage(modified_damage)
				if dead:
					if target.name == "Player":
						SceneHandler._load_menu()
						return
					_remove_enemy(target)
					target_dead = true
			"shield":
				if effect.modifiers.has("target") and effect.modifiers["target"] == "self":
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
				if not effect.modifiers.has("id"):
					print("ERR>No id modifier.")
					continue
				var status_data = load("res://statuses/" + effect.modifiers["id"] + ".tres")
				if status_data == null:
					print("ERR>No such status.")
					continue
				
				#On Status Up execution
				var on_status_effects = []
				var pre_status_effects = []
				if target.name == "Player":
					var relic_data = _generate_relic_effects(LanguageHandler.ActivationClass.STATUS_CONDITON, LanguageHandler.StatusCondition.ON_STATUS_UP)
					on_status_effects.append_array(relic_data[0])
					var pre_relic_data = _generate_relic_effects(LanguageHandler.ActivationClass.STATUS_CONDITON, LanguageHandler.StatusCondition.PRE_STATUS_UP)
					pre_status_effects.append_array(pre_relic_data[0])
				
				if effect.modifiers.has("target") and effect.modifiers["target"] == "self":
					var pre_status_data = _generate_status_effects(origin, LanguageHandler.ActivationClass.STATUS_CONDITON, LanguageHandler.StatusCondition.PRE_STATUS_UP)
					pre_status_effects.append_array(pre_status_data[0])
					
					#Activate all pre-status effects
					var pre_status_returns = _execute_effects(origin, origin, pre_status_effects, {"status" : status_data})
					var pre_status_execution_returns = pre_status_returns[0]
					var pre_status_carry_returns = pre_status_returns[1]
					
					if pre_status_carry_returns.has("power_through"):
						var dead = target._take_damage(pre_status_carry_returns["power_through"])
						if dead:
							if target.name == "Player":
								SceneHandler._load_menu()
								return
							_remove_enemy(target)
							target_dead = true
						continue
					origin._create_status(status_data, int(effect.value))
					
					#Execute all after-status effects
					var on_status_data = _generate_status_effects(origin, LanguageHandler.ActivationClass.STATUS_CONDITON, LanguageHandler.StatusCondition.ON_STATUS_UP)
					on_status_effects.append_array(on_status_data[0])
					
					#Activate tickdown effects for statuses
					for on_status in on_status_data[1]:
						var subdata = on_status.status_data
						if subdata.status_tick_down == Status.TickDown.WHEN_ACTIVATED:
							_tick_down_status(subdata, on_status)
					
					var status_returns = _execute_effects(origin, origin, on_status_effects, {"status" : status_data})
					var status_execution_returns = status_returns[0]
					var status_carry_returns = status_returns[1]
				
				else:
					if target_dead:
						continue
					
					var on_status_data = _generate_status_effects(target, LanguageHandler.ActivationClass.STATUS_CONDITON, LanguageHandler.StatusCondition.ON_STATUS_UP)
					on_status_effects.append_array(on_status_data[0])
					
					var status_returns = _execute_effects(target, target, on_status_effects, {"status" : status_data})
					var status_execution_returns = status_returns[0]
					var status_carry_returns = status_returns[1]
					
					if status_carry_returns.has("power_through"):
						var dead = target._take_damage(status_carry_returns["power_through"])
						if dead:
							if target.name == "Player":
								SceneHandler._load_menu()
								return
							_remove_enemy(target)
							target_dead = true
						continue
					target._create_status(status_data, int(effect.value))
					
					#Activate tickdown effects for statuses
					for on_status in on_status_data[1]:
						var subdata = on_status.status_data
						if subdata.status_tick_down == Status.TickDown.WHEN_ACTIVATED:
							_tick_down_status(subdata, on_status)
			"exhaust_self":
				if execution_returns.has("exhaust_self"):
					execution_returns["exhaust_self"] += effect.value
				else:
					execution_returns["exhaust_self"] = effect.value
			"stack_damage":
				var dead = target._take_damage(effect.reference.status_counter)
				if dead:
					if target.name == "Player":
						SceneHandler._load_menu()
						return
					_remove_enemy(target)
			"critical":
				if carry_returns.has("critical"):
					carry_returns["critical"] += effect.reference.status_counter
				else:
					carry_returns["critical"] = effect.reference.status_counter
			"dodge":
				if carry_returns.has("dodge"):
					carry_returns["dodge"] += effect.value
				else:
					carry_returns["dodge"] = effect.value
			"phys_atk":
				var damage_modifier = int(effect.value) * effect.reference.status_counter
				if not effect.modifiers.has("mod"):
					print("ERR>No mod modifier.")
					continue
				match effect.modifiers["mod"]:
					"neg":
						damage_modifier *= -1
				if carry_returns.has("phys_atk"):
					carry_returns["phys_atk"] += damage_modifier
				else:
					carry_returns["phys_atk"] = damage_modifier
			"phys_def":
				var damage_modifier = int(effect.value) * effect.reference.status_counter
				if not effect.modifiers.has("mod"):
					print("ERR>No mod modifier.")
					continue
				match effect.modifiers["mod"]:
					"neg":
						damage_modifier *= -1
				if carry_returns.has("phys_def"):
					carry_returns["phys_def"] += damage_modifier
				else:
					carry_returns["phys_def"] = damage_modifier
			"cancel_intent":
				if target.is_in_group("Player"):
					print("ERR>Player stun not implemented.")
					continue
				target._cancel_intent()
				effect.reference._decrement_counter(effect.reference.status_counter)
			"power_through":
				if not carry_data.has("status"):
					continue
				if not _validate_triggers(target, null, carry_data["status"]):
					continue
				
				#Only best power_through effect applies
				if carry_returns.has("power_through"):
					if int(effect.value) < carry_returns["power_through"]:
						carry_returns["power_through"] = int(effect.value)
				else:
					carry_returns["power_through"] = int(effect.value)
	return [execution_returns, carry_returns]

func _generate_relic_effects(context_group : LanguageHandler.ActivationClass, context):
	var effects = []
	var relics = []
	for relic_item in get_node("../MainUI/RelicArea").get_children():
		var relic_data = relic_item.relic_data as Relic
		if not _validate_triggers(relic_data, relic_item, null):
			continue
		var relic_effect = null
		if relic_data.relic_activation_class == context_group:
			match relic_data.relic_activation_class:
				LanguageHandler.ActivationClass.TURN_CONDITION:
					if relic_data.relic_turn_condition == context:
						relic_effect = relic_data._parse_effects()
						relics.append(relic_item)
				LanguageHandler.ActivationClass.CARD_CONDITION:
					if relic_data.relic_card_condition == context:
						relic_effect = relic_data._parse_effects()
						relics.append(relic_item)
				LanguageHandler.ActivationClass.COMBAT_CONDITON:
					if relic_data.relic_combat_condition == context:
						relic_effect = relic_data._parse_effects()
						relics.append(relic_item)
				LanguageHandler.ActivationClass.ENCOUNTER_CONDITION:
					if relic_data.relic_encounter_condition == context:
						relic_effect = relic_data._parse_effects()
						relics.append(relic_item)
				LanguageHandler.ActivationClass.STATUS_CONDITON:
					if relic_data.relic_status_condition == context:
						relic_effect = relic_data._parse_effects()
						relics.append(relic_item)
		if relic_effect != null:
			for sub_effect in relic_effect:
				var new_effect = BattleEffect.new()
				new_effect._init_from_typed(relic_effect, relic_item)
				effects.append(new_effect)
	return [effects, relics]

func _generate_status_effects(origin, context_group : LanguageHandler.ActivationClass, context):
	var effects = []
	var statuses = []
	for status_item in origin.get_node("Status").get_children():
		var status_data = status_item.status_data as Status
		if not _validate_triggers(status_data, status_item, null):
			continue
		var status_effect = null
		if status_data.status_activation_class == context_group:
			match status_data.status_activation_class:
				LanguageHandler.ActivationClass.TURN_CONDITION:
					if status_data.status_turn_condition == context:
						status_effect = status_data._parse_effects()
						statuses.append(status_item)
				LanguageHandler.ActivationClass.CARD_CONDITION:
					if status_data.status_card_condition == context:
						status_effect = status_data._parse_effects()
						statuses.append(status_item)
				LanguageHandler.ActivationClass.COMBAT_CONDITON:
					if status_data.status_combat_condition == context:
						status_effect = status_data._parse_effects()
						statuses.append(status_item)
				LanguageHandler.ActivationClass.ENCOUNTER_CONDITION:
					if status_data.status_encounter_condition == context:
						status_effect = status_data._parse_effects()
						statuses.append(status_item)
				LanguageHandler.ActivationClass.STATUS_CONDITON:
					if status_data.status_status_condition == context:
						status_effect = status_data._parse_effects()
						statuses.append(status_item)
		if status_effect != null:
			for sub_effect in status_effect:
				var new_effect = BattleEffect.new()
				new_effect._init_from_typed(sub_effect, status_item)
				effects.append(new_effect)
	return [effects, statuses]

#NOTE : status_flag trigger requires specific context
func _validate_triggers(target, object, context):
	var triggers = target._parse_triggers()
	for condition in triggers:
		var modifiers_dictionary = _modifier_dictionary_from_string(condition.modifier)
		match condition.action:
			"status_flag":
				if not modifiers_dictionary.has("flag"):
					print("ERR>No flag modifier.")
					continue
				if not (context.status_flags as Array).has(modifiers_dictionary["flag"]):
					return false
			"counter":
				if object.is_in_group("StatusInstance"):
					if object.status_counter < int(condition.value):
						return false
				if object.is_in_group("RelicInstance"):
					if object.relic_counter < int(condition.value):
						return false
			"turn_count":
				if current_turn > int(condition.value):
					return false
	return true

func _tick_down_status(status_data : Status, status_object):
	if status_data.status_tick_down_instant:
		match status_data.status_tick_down_amount:
			Status.TickDownAmount.VALUE:
				status_object._decrement_counter(status_data.status_tick_down_value)
			Status.TickDownAmount.ALL:
				status_object._decrement_counter(status_object.status_counter)
			Status.TickDownAmount.NONE:
				status_object._decrement_counter(0)
	else:
		match status_data.status_tick_down_amount:
			Status.TickDownAmount.VALUE:
				status_object._queue_decrement_counter(status_data.status_tick_down_value)
			Status.TickDownAmount.ALL:
				status_object._queue_decrement_counter(status_object.status_counter)
			Status.TickDownAmount.NONE:
				status_object._queue_decrement_counter(0)

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

class BattleEffect:
	var action : String
	var value : int
	var modifiers : Dictionary
	var reference
	
	func _init_from_values(action, value, modifiers, reference):
		self.action = action
		self.value = value
		self.modifiers = modifiers
		self.reference = reference
	
	func _init_from_typed(alternate_effect, reference):
		self.action = alternate_effect.action
		self.value = alternate_effect.value
		var modifiers_array = alternate_effect.modifier.split(",")
		var modifiers_dictionary = {}
		for element in modifiers_array:
			if element == null or element == "":
				continue
			var element_array = element.split(":")
			if element_array.size() < 2:
				print("ERR>Invalid modifier construction")
				continue
			modifiers_dictionary[element_array[0]] = element_array[1]
		self.modifiers = modifiers_dictionary
		self.reference = reference
	
	func _to_string():
		return "action: " + action + "\n" + "value: " + str(value) + "\n" + "modifiers: " + str(modifiers) + "\n" + "reference: " + str(reference)
