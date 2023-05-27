extends Node

var main_ui = preload("res://scenes/main_ui.tscn")
var battle_map = preload("res://scenes/battle_map.tscn")
var battle_handler = preload("res://scenes/battle_handler.tscn")
var unit = preload("res://scenes/unit.tscn")
var card = preload("res://scenes/card.tscn")
var test_res = preload("res://enemies/test_enemy/test_enemy.tres")

var map_position = Vector2(800, 320)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _test():
	_load_battle()

func _load_battle():
	var root_node = get_tree().root
	
	var ui = main_ui.instantiate() as Control
	var map = battle_map.instantiate() as Node2D
	var handler = battle_handler.instantiate() as Node
	
	root_node.add_child(ui)
	root_node.add_child(map)
	root_node.add_child(handler)
	get_tree().set_current_scene(map)
	
	map.position = map_position

func _load_enemies():
	var coords_list = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2)]
	
	for i in 4:
		get_tree().root.get_node("BattleHandler")._create_enemy(test_res, coords_list.pick_random())

func _load_cards():
	var handler = get_node("../BattleHandler")
	var tmpres : Resource
	for i in 3:
		tmpres = load("res://cards/warrior_cards/warrior_01_attack.tres")
		handler._create_card(tmpres)
	for i in 3:
		tmpres = load("res://cards/warrior_cards/warrior_02_defend.tres")
		handler._create_card(tmpres)
	for i in 2:
		tmpres = load("res://cards/elementalist_cards/elementalist_01_fireblast.tres")
		handler._create_card(tmpres)
	for i in 2:
		tmpres = load("res://cards/elementalist_cards/elementalist_02_thunderbolt.tres")
		handler._create_card(tmpres)
	for i in 2:
		tmpres = load("res://cards/elementalist_cards/elementalist_03_iceburst.tres")
		handler._create_card(tmpres)
	for i in 6:
		handler._draw_card()
