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

var encounter_data : Encounter

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#Check if player has won
	var all_enemies = _get_all_enemies()
	
	if all_enemies.size() <= 0:
		_activate_external_effects(get_node("../BattleMap/Player"), LanguageHandler.ActivationClass.ENCOUNTER_CONDITION, LanguageHandler.EncounterCondition.ON_EXIT_COMBAT)
		RunHandler.current_hp = get_node("../BattleMap/Player").current_hp
		if encounter_data.encounter_type == Encounter.EncounterType.ELITE:
			SceneHandler._load_chest(load("res://encounters/chest_encounters/elite_chest_0.tres"))
			return
		if encounter_data.encounter_type == Encounter.EncounterType.BOSS:
			SceneHandler._load_end(true)
			return
		SceneHandler._load_after_battle()

func _setup(encounter_data : Encounter):
	self.encounter_data = encounter_data
	get_node("/root/MainUI/EnergyMeter/EnergyLabel").text = str(current_energy) + "/" + str(max_energy)
	
	get_node("../MainUI/CardArea/DeadZone").connect("mouse_entered", _dead_zone_entered)
	get_node("../MainUI/CardArea/DeadZone").connect("mouse_exited", _dead_zone_exited)
	
	var unit_list = encounter_data._get_position_dictionary()
	for coord in unit_list:
		_create_enemy(unit_list[coord], coord)
	
	var all_enemies = _get_all_enemies()
	
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
	
	_activate_external_effects(get_node("../BattleMap/Player"), LanguageHandler.ActivationClass.ENCOUNTER_CONDITION, LanguageHandler.EncounterCondition.ON_ENTER_COMBAT)
	
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

func _create_card_floating(card_res : Card):
	var new_card = card.instantiate()
	new_card.name = "Card_" + str(card_pool.size())
	new_card._setup(card_res)
	card_pool.append(new_card)
	new_card.connect("card_activated", _activate_card)
	new_card.connect("card_released", _play_card)
	new_card.add_to_group("CardInstance")
	return new_card

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
	var targets = []
	if mouse_in_dead_zone:
		return
	if current_energy < data.card_cost:
		return
	if data.card_targeting_type == Card.CardTargetingType.FREE:
		current_energy -= data.card_cost
		targets = [player]
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
			Card.CardAOE.CROSS:
				if enemy != null:
					targets.append(enemy)
				var tile_shift = tile + Vector2i(0,-1)
				if tile_shift.y >= 0:
					if enemy_map[tile_shift.x][tile_shift.y] != null:
						targets.append(enemy_map[tile_shift.x][tile_shift.y])
				tile_shift = tile + Vector2i(0,1)
				if tile_shift.y < enemy_map[0].size():
					if enemy_map[tile_shift.x][tile_shift.y] != null:
						targets.append(enemy_map[tile_shift.x][tile_shift.y])
				tile_shift = tile + Vector2i(-1,0)
				if tile_shift.x >= 0:
					if enemy_map[tile_shift.x][tile_shift.y] != null:
						targets.append(enemy_map[tile_shift.x][tile_shift.y])
				tile_shift = tile + Vector2i(1,0)
				if tile_shift.x < enemy_map.size():
					if enemy_map[tile_shift.x][tile_shift.y] != null:
						targets.append(enemy_map[tile_shift.x][tile_shift.y])
			Card.CardAOE.ROW:
				for i in enemy_map.size():
					if enemy_map[i][tile.y] != null:
						targets.append(enemy_map[i][tile.y])
			Card.CardAOE.RANK:
				for i in enemy_map[tile.x].size():
					if enemy_map[tile.x][i] != null:
						targets.append(enemy_map[tile.x][i])
			Card.CardAOE.ALL:
				for row in enemy_map:
					for target in row:
						if target != null:
							targets.append(target)
			Card.CardAOE.CUSTOM:
				pass
	
	var card_returns = _execute_actions(player, targets, effects)
	
	_activate_external_effects(get_node("../BattleMap/Player"), LanguageHandler.ActivationClass.CARD_CONDITION, LanguageHandler.CardCondition.ON_CARD_PLAYED)

	#Card effect resolution
	var discard = true
	if card_returns.has("exhaust_self"):
		discard = false
	
	if discard:
		_play_remove_card(source)
	else:
		_exile_card(source)
	
	#Force exile
	if card_returns.has("exile"):
		pass
	if card_returns.has("exile_random_hand"):
		for i in card_returns["exile_random_hand"]:
			if card_hand.size() <= 0:
				break
			var exile_target = card_hand.pick_random()
			_exile_card(exile_target)
	
	#Force discard
	if card_returns.has("discard"):
		pass
	
	get_node("/root/MainUI/EnergyMeter/EnergyLabel").text = str(current_energy) + "/" + str(max_energy)
	if card_hand.size() <= 0:
		#_end_player_turn()
		pass

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
	_activate_external_effects(get_node("../BattleMap/Player"), LanguageHandler.ActivationClass.CARD_CONDITION, LanguageHandler.CardCondition.ON_CARD_DRAW)

func _play_remove_card(card):
	var index = card_hand.find(card)
	if index == -1:
		return
	card_discard.append(card)
	card_hand.remove_at(index)
	get_node("/root/MainUI/CardArea").remove_child(card)
	_realign_cards()

func _discard_card(card):
	var index = card_hand.find(card)
	if index == -1:
		return
	card_discard.append(card)
	card_hand.remove_at(index)
	get_node("/root/MainUI/CardArea").remove_child(card)
	_realign_cards()
	_activate_external_effects(get_node("../BattleMap/Player"), LanguageHandler.ActivationClass.CARD_CONDITION, LanguageHandler.CardCondition.ON_CARD_DISCARD)

func _exile_card(card):
	var index = card_hand.find(card)
	if index == -1:
		return
	card_exile.append(card)
	card_hand.remove_at(index)
	get_node("/root/MainUI/CardArea").remove_child(card)
	_realign_cards()
	_activate_external_effects(get_node("../BattleMap/Player"), LanguageHandler.ActivationClass.CARD_CONDITION, LanguageHandler.CardCondition.ON_CARD_EXHAUST)

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

func _get_all_enemies():
	var all_enemies = []
	for list in enemy_map:
		for enemy in list:
			if enemy != null:
				all_enemies.append(enemy)
	
	return all_enemies

func _end_player_turn():
	var player = get_node("../BattleMap/Player")
	_activate_external_effects(player, LanguageHandler.ActivationClass.TURN_CONDITION, LanguageHandler.TurnCondition.ON_TURN_END)
	_discard_hand()
	_start_enemy_turn()

func _start_enemy_turn():
	var all_enemies = _get_all_enemies()
	
	for enemy in all_enemies:
		enemy._clear_shields()
		_activate_external_effects(enemy, LanguageHandler.ActivationClass.TURN_CONDITION, LanguageHandler.TurnCondition.ON_TURN_START)
	
	_activate_enemies()
	_end_enemy_turn()

func _end_enemy_turn():
	var all_enemies = _get_all_enemies()
	
	for enemy in all_enemies:
		_activate_external_effects(enemy, LanguageHandler.ActivationClass.TURN_CONDITION, LanguageHandler.TurnCondition.ON_TURN_END)
	
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
	#Normal start of turn effects
	var player = get_node("../BattleMap/Player")
	player._clear_shields()
	_draw_hand()
	current_turn += 1
	current_energy = max_energy
	get_node("/root/MainUI/EnergyMeter/EnergyLabel").text = str(current_energy) + "/" + str(max_energy)
	
	_activate_external_effects(player, LanguageHandler.ActivationClass.TURN_CONDITION, LanguageHandler.TurnCondition.ON_TURN_START)

func _activate_enemies():
	var all_enemies = _get_all_enemies()
	
	for enemy in all_enemies:
		var targets = []
		
		var action = enemy.current_intent as Action
		match action.action_type:
			Action.ActionType.ATTACK, Action.ActionType.DEBUFF:
				targets.append(get_node("../BattleMap/Player"))
			Action.ActionType.SHIELD, Action.ActionType.BUFF, Action.ActionType.RELOAD, Action.ActionType.CANCELED:
				targets.append(enemy)
			_:
				print("ERR>Invalid Action Type: " + str(action.action_type))
		
		_execute_actions(enemy, targets, action._parse_effects())

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
		if target == null: 
			continue
		var defender_pre_effects = _generate_defender_effects(target)
		#Defender effects
		var defender_returns = _execute_effects(target, target, defender_pre_effects, {})
		var defender_execution_returns = defender_returns[0]
		var defender_carry_returns = defender_returns[1]
		execution_returns.merge(defender_execution_returns)
		#Card effects
		var merged_returns = attacker_carry_returns.duplicate()
		merged_returns.merge(defender_carry_returns)
		var card_returns = _execute_effects(attacker, target, converted_effects, merged_returns)
		var card_execution_returns = card_returns[0]
		var card_carry_returns = card_returns[1]
		execution_returns.merge(card_execution_returns)
		
		#Resolution effects
		#Trigger all queued status ticks
		for status in target.get_node("Status").get_children():
			status._trigger_queue()
	
	#Player resolution effects
	#Trigger all queued status for player
	for status in attacker.get_node("Status").get_children():
		status._trigger_queue()
	
	return execution_returns

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
				#Special case: all_enemies modifier
				if effect.modifiers.has("target"):
					if effect.modifiers["target"] == "all_enemies":
						var damage_effect = BattleEffect.new()
						damage_effect._init_from_values("damage", int(effect.value), {}, null)
						_execute_actions(origin, _get_all_enemies(), [damage_effect])
						continue
				
				if not effect.modifiers.has("type"):
					print("ERR>No type modifier.")
					continue
				
				if target_dead:
					continue
				
				#Microvalidation Step
				if not _micro_validation(effect, target):
					continue
				
				var base_damage = int(effect.value)
				var modified_damage = base_damage
				var crit_mod = 1
				
				#On Damage Effect execution
				var on_damage_effects = []
				if target.name == "Player":
					var relic_data = _generate_relic_effects(LanguageHandler.ActivationClass.COMBAT_CONDITON, LanguageHandler.CombatCondition.ON_DAMAGE_EFFECT)
					on_damage_effects.append_array(relic_data[0])
				
				var on_damage_data = _generate_status_effects(origin, LanguageHandler.ActivationClass.COMBAT_CONDITON, LanguageHandler.CombatCondition.ON_DAMAGE_EFFECT)
				on_damage_effects.append_array(on_damage_data[0])
				
				#Activate tickdown effects for statuses
				for on_status in on_damage_data[1]:
					var subdata = on_status.status_data
					if subdata.status_tick_down == Status.TickDown.WHEN_ACTIVATED:
						_tick_down_status(subdata, on_status)
				
				var damage_returns = _execute_effects(origin, origin, on_damage_effects, {})
				var damage_execution_returns = damage_returns[0]
				var damage_carry_returns = damage_returns[1]
				
				#On Take Damage Effect execution
				var take_damage_effects = []
				if target.name == "Player":
					var relic_data = _generate_relic_effects(LanguageHandler.ActivationClass.COMBAT_CONDITON, LanguageHandler.CombatCondition.ON_TAKE_DAMAGE_EFFECT)
					take_damage_effects.append_array(relic_data[0])
				
				var take_damage_data = _generate_status_effects(target, LanguageHandler.ActivationClass.COMBAT_CONDITON, LanguageHandler.CombatCondition.ON_TAKE_DAMAGE_EFFECT)
				take_damage_effects.append_array(take_damage_data[0])
				
				#Activate tickdown effects for statuses
				for on_status in take_damage_data[1]:
					var subdata = on_status.status_data
					if subdata.status_tick_down == Status.TickDown.WHEN_ACTIVATED:
						_tick_down_status(subdata, on_status)
				
				var take_damage_returns = _execute_effects(origin, origin, take_damage_effects, {})
				var take_damage_execution_returns = take_damage_returns[0]
				var take_damage_carry_returns = take_damage_returns[1]
				
				var carry_list = carry_data.duplicate()
				
				carry_list.merge(damage_carry_returns)
				carry_list.merge(take_damage_carry_returns)
				
				#TODO: Make crits physical only
				#CRITICAL AND DAMAGE UP/DOWN
				if carry_list.has("critical"):
					crit_mod += carry_list["critical"]
				
				#Physical/Magic Split
				match effect.modifiers["type"]:
					"phys":
						if carry_list.has("phys_atk"):
							modified_damage += carry_list["phys_atk"]
						modified_damage *= crit_mod
						if carry_list.has("phys_def"):
							modified_damage -= carry_list["phys_def"]
					"mag":
						if carry_list.has("mag_atk"):
							modified_damage += carry_list["mag_atk"]
						modified_damage *= crit_mod
						if carry_list.has("mag_def"):
							modified_damage -= carry_list["mag_def"]
					_:
						print("ERR> Unrecognized damage type.")
						continue
				
				if carry_list.has("dodge"):
					modified_damage = 0
				
				modified_damage = max(0, modified_damage)
				var dead = target._take_damage(modified_damage)
				if dead:
					if target.name == "Player":
						return _player_dead()
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
				
				#Microvalidation Step
				if not _micro_validation(effect, target):
					continue
				
				#On Status Up execution
				var on_status_effects = []
				var pre_status_effects = []
				if target.name == "Player":
					var relic_data = _generate_relic_effects(LanguageHandler.ActivationClass.STATUS_CONDITON, LanguageHandler.StatusCondition.ON_STATUS_UP)
					on_status_effects.append_array(relic_data[0])
					var pre_relic_data = _generate_relic_effects(LanguageHandler.ActivationClass.STATUS_CONDITON, LanguageHandler.StatusCondition.PRE_STATUS_UP)
					pre_status_effects.append_array(pre_relic_data[0])
				
				var sub_target
				if effect.modifiers.has("target") and effect.modifiers["target"] == "self":
					sub_target = origin
				else:
					if target_dead:
						continue
					sub_target = target
				
				var pre_status_data = _generate_status_effects(sub_target, LanguageHandler.ActivationClass.STATUS_CONDITON, LanguageHandler.StatusCondition.PRE_STATUS_UP)
				pre_status_effects.append_array(pre_status_data[0])
				
				#Activate tickdown effects for statuses
				for pre_status in pre_status_data[1]:
					var subdata = pre_status.status_data
					if subdata.status_tick_down == Status.TickDown.WHEN_ACTIVATED:
						_tick_down_status(subdata, pre_status)
				
				#Activate all pre-status effects
				var pre_status_returns = _execute_effects(sub_target, sub_target, pre_status_effects, {"status" : status_data})
				var pre_status_execution_returns = pre_status_returns[0]
				var pre_status_carry_returns = pre_status_returns[1]
				
				if pre_status_carry_returns.has("power_through"):
					var dead = target._take_damage(pre_status_carry_returns["power_through"])
					if dead:
						if target.name == "Player":
							return _player_dead()
						_remove_enemy(target)
						target_dead = true
					continue
				sub_target._create_status(status_data, int(effect.value))
				
				#Execute all after-status effects
				var on_status_data = _generate_status_effects(sub_target, LanguageHandler.ActivationClass.STATUS_CONDITON, LanguageHandler.StatusCondition.ON_STATUS_UP)
				on_status_effects.append_array(on_status_data[0])
				
				#Activate tickdown effects for statuses
				for on_status in on_status_data[1]:
					var subdata = on_status.status_data
					if subdata.status_tick_down == Status.TickDown.WHEN_ACTIVATED:
						_tick_down_status(subdata, on_status)
				
				var status_returns = _execute_effects(sub_target, sub_target, on_status_effects, {"status" : status_data})
				var status_execution_returns = status_returns[0]
				var status_carry_returns = status_returns[1]
				
			"exhaust_self":
				if execution_returns.has("exhaust_self"):
					execution_returns["exhaust_self"] += effect.value
				else:
					execution_returns["exhaust_self"] = effect.value
			"stack_damage":
				var dead = target._take_damage(effect.reference.status_counter)
				if dead:
					if target.name == "Player":
						return _player_dead()
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
			"mag_atk":
				var damage_modifier = int(effect.value) * effect.reference.status_counter
				if not effect.modifiers.has("mod"):
					print("ERR>No mod modifier.")
					continue
				match effect.modifiers["mod"]:
					"neg":
						damage_modifier *= -1
				if carry_returns.has("mag_atk"):
					carry_returns["mag_atk"] += damage_modifier
				else:
					carry_returns["mag_atk"] = damage_modifier
			"mag_def":
				var damage_modifier = int(effect.value) * effect.reference.status_counter
				if not effect.modifiers.has("mod"):
					print("ERR>No mod modifier.")
					continue
				match effect.modifiers["mod"]:
					"neg":
						damage_modifier *= -1
				if carry_returns.has("mag_def"):
					carry_returns["mag_def"] += damage_modifier
				else:
					carry_returns["mag_def"] = damage_modifier
			"cancel_intent":
				if target.is_in_group("Player"):
					print("ERR>Player stun not implemented.")
					continue
				target._cancel_intent()
			"power_through":
				if not carry_data.has("status"):
					continue
				if not _validate_triggers(effect.reference.status_data, effect.reference, carry_data["status"]):
					continue
				
				#Only best power_through effect applies
				if carry_returns.has("power_through"):
					if int(effect.value) < carry_returns["power_through"]:
						carry_returns["power_through"] = int(effect.value)
				else:
					carry_returns["power_through"] = int(effect.value)
			"cleanse":
				var statuses = target.get_node("Status").get_children()
				if not effect.modifiers.has("type"):
					print("ERR>No type modifier.")
					continue
				for status in statuses:
					match effect.modifiers["type"]:
						"buff":
							if status.status_data.status_class == Status.StatusType.BUFF:
								status._decrement_counter(status.status_counter)
						"debuff":
							if status.status_data.status_class == Status.StatusType.DEBUFF:
								status._decrement_counter(status.status_counter)
						_:
							print("ERR>Invalid cleanse type.")
							break
			"new_card":
				var new_card
				if not effect.modifiers.has("location"):
					print("ERR>No location modifier.")
					continue
				if not effect.modifiers.has("id") and not effect.modifiers.has("class"):
					print("ERR>No id or class modifier.")
					continue
				if effect.modifiers.has("id") and not effect.modifiers.has("class"):
					print("ERR>Id modifier without class modifier.")
					continue
				if effect.modifiers.has("class"):
					new_card = load("res://cards/" + effect.modifiers["class"] + "_cards/" + effect.modifiers["id"] + ".tres")
				else:
					new_card = load("res://cards/" + effect.modifiers["id"] + ".tres")
				
				var card_object = _create_card_floating(new_card)
				
				match effect.modifiers["location"]:
					"hand":
						card_hand.append(card_object)
						get_node("/root/MainUI/CardArea").add_child(card_object)
						card_object.position = Vector2(0, 0)
						_realign_cards()
					_:
						print("ERR>Invalid cleanse type.")
						break
			"exile":
				var exile_mode = "exile"
				match effect.modifiers["mode"]:
					"random_hand":
						exile_mode = "exile_random_hand"
					_:
						print("ERR>Invalid exile mode.")
						break
				if execution_returns.has(exile_mode):
					execution_returns[exile_mode] += effect.value
				else:
					execution_returns[exile_mode] = effect.value
	return [execution_returns, carry_returns]

func _micro_validation(effect, target):
	if effect.modifiers.has("has_status"):
		var status_valid = false
		var statuses = target.get_node("Status").get_children()
		var target_status = load("res://statuses/" + effect.modifiers["has_status"] +".tres")
		for status in statuses:
			if status.status_data == target_status:
				status_valid = true
				break
		if not status_valid:
			return false
	return true

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
				new_effect._init_from_typed(sub_effect, relic_item)
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
				if context == null:
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

func _player_dead():
	SceneHandler._load_end(false)
	return [{},{}]


func _activate_external_effects(target, activation_context : LanguageHandler.ActivationClass, context):
	#Generate all relevant effects
	var all_effects = []
	if target.name == "Player":
		var relic_data = _generate_relic_effects(activation_context, context)
		all_effects.append_array(relic_data[0])
	var status_data = _generate_status_effects(target, activation_context, context)
	all_effects.append_array(status_data[0])
	
	#Activate tickdown effects for statuses
	for on_status in status_data[1]:
		var subdata = on_status.status_data
		if subdata.status_tick_down == Status.TickDown.WHEN_ACTIVATED:
			_tick_down_status(subdata, on_status)
	
	return _execute_effects(target, target, all_effects, {})

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
