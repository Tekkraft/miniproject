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
	if card_hand.size() <= 0:
		_draw_hand()
	pass

func _create_enemy(enemy_data : Unit, position : Vector2i):
	if enemy_map[position.x][position.y] == null:
		var new_enemy = unit.instantiate()
		var map_tile = get_node("../BattleMap/Tile_" + _vector2i_to_str(position))
		map_tile.add_child(new_enemy)
		new_enemy._setup(enemy_data)
		enemy_map[position.x][position.y] = new_enemy

func _remove_enemy(position : Vector2i):
	var removed = enemy_map[position.x][position.y] as Node2D
	removed.get_parent().remove_child(removed)
	removed. queue_free()
	enemy_map[position.x][position.y] = null

func _vector2i_to_str(vector : Vector2i):
	return str(vector.x) + "_" + str(vector.y)

func _activate_card(source):
	pass

func _play_card(source):
	source.card_data._parse_effects()
	var map = get_node("../BattleMap")
	var tile = map._get_active_tile()
	if tile == null:
		return
	var enemy = enemy_map[tile.x][tile.y]
	if enemy == null:
		return
	var dead = enemy._take_damage(randi_range(10, 25))
	if dead:
		_remove_enemy(tile)
	_discard_card(source)

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
	drawn.position = Vector2(450 + card_hand.size() * 200, 800)

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
	pass

func _draw_hand():
	for i in 6:
		_draw_card()

