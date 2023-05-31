extends Node

var card_pool = []
var card_deck = []
var card_hand = []
var card_discard = []
var card_exile = []
var enemy_map = [[null, null, null],[null, null, null],[null, null, null]]
var unit = preload("res://scenes/unit.tscn")
var card = preload("res://scenes/card.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _setup():
	get_node("../MainUI/EndTurnButton").connect("pressed", _end_turn)
	_start_turn()

func _create_enemy(enemy_data : Unit, position : Vector2i):
	if enemy_map[position.x][position.y] == null:
		var new_enemy = unit.instantiate()
		var map_tile = get_node("../BattleMap/Tile_" + _vector2i_to_str(position))
		map_tile.add_child(new_enemy)
		new_enemy._setup(enemy_data, position)
		enemy_map[position.x][position.y] = new_enemy
		new_enemy._generate_intent()

func _remove_enemy(enemy):
	var position = enemy.current_location
	var removed = enemy_map[position.x][position.y] as Node2D
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
	if source.card_data.card_targeting_type == Card.CardTargetingType.FREE:
		_activate_effects(effects, map.get_node("Player"))
	else:
		var tile = map._get_active_tile()
		if tile == null:
			return
		var enemy = enemy_map[tile.x][tile.y]
		if not _check_validity(data, tile):
			return
		match data.card_aoe:
			Card.CardAOE.SINGLE:
				_activate_effects(effects, enemy)
			Card.CardAOE.CROSS:
				if enemy != null:
					_activate_effects(effects, enemy)
				var tile_shift = tile + Vector2i(0,-1)
				if tile_shift.y >= 0:
					if enemy_map[tile_shift.x][tile_shift.y] != null:
						_activate_effects(effects, enemy_map[tile_shift.x][tile_shift.y])
				tile_shift = tile + Vector2i(0,1)
				if tile_shift.y < enemy_map[0].size():
					if enemy_map[tile_shift.x][tile_shift.y] != null:
						_activate_effects(effects, enemy_map[tile_shift.x][tile_shift.y])
				tile_shift = tile + Vector2i(-1,0)
				if tile_shift.x >= 0:
					if enemy_map[tile_shift.x][tile_shift.y] != null:
						_activate_effects(effects, enemy_map[tile_shift.x][tile_shift.y])
				tile_shift = tile + Vector2i(1,0)
				if tile_shift.x < enemy_map.size():
					if enemy_map[tile_shift.x][tile_shift.y] != null:
						_activate_effects(effects, enemy_map[tile_shift.x][tile_shift.y])
			Card.CardAOE.ROW:
				for i in enemy_map[tile.x].size():
					if enemy_map[tile.x][i] != null:
						_activate_effects(effects, enemy_map[tile.x][i])
			Card.CardAOE.RANK:
				for i in enemy_map.size():
					if enemy_map[i][tile.y] != null:
						_activate_effects(effects, enemy_map[i][tile.y])
			Card.CardAOE.ALL:
				for row in enemy_map:
					for target in row:
						if target != null:
							_activate_effects(effects, target)
			Card.CardAOE.CUSTOM:
				pass
	_discard_card(source)
	if card_hand.size() <= 0:
		_end_turn()

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
	get_tree().root.add_child(drawn)
	drawn.position = Vector2(250 + card_hand.size() * 200, 800)

func _discard_card(card):
	var index = card_hand.find(card)
	if index == -1:
		return
	card_discard.append(card)
	card_hand.remove_at(index)
	get_tree().root.remove_child(card)

func _exile_card(card):
	var index = card_hand.find(card)
	if index == -1:
		return
	card_exile.append(card)
	card_hand.remove_at(index)
	get_tree().root.remove_child(card)

func _return_card(card):
	var index = card_hand.find(card)
	if index == -1:
		return
	card_deck.append(card)
	card_hand.remove_at(index)
	get_tree().root.remove_child(card)
	_shuffle_deck()

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

func _activate_effects(effects, target):
	for effect in effects:
		match effect.action:
			"damage":
				var dead = target._take_damage(int(effect.value))
				if dead:
					if target.name == "Player":
						get_tree().quit()
						return
					_remove_enemy(target)
			"shield":
				target._gain_shield(int(effect.value))

func _end_turn():
	_discard_hand()
	_activate_enemies()
	_start_turn()

func _start_turn():
	var all_enemies = []
	for list in enemy_map:
		for enemy in list:
			if enemy != null:
				all_enemies.append(enemy)
	for enemy in all_enemies:
		enemy._generate_intent()
	_draw_hand()



func _activate_enemies():
	var all_enemies = []
	for list in enemy_map:
		for enemy in list:
			if enemy != null:
				all_enemies.append(enemy)
	for enemy in all_enemies:
		var action = enemy.current_intent as Action
		match action.action_type:
			Action.ActionType.ATTACK, Action.ActionType.DEBUFF:
				_activate_effects(action._parse_effects(), get_node("../BattleMap/Player"))
			Action.ActionType.SHIELD, Action.ActionType.BUFF:
				_activate_effects(action._parse_effects(), enemy)
			_:
				print("ERR>Invalid Action Type: " + action.action_type)
