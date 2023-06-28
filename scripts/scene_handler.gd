extends Node

var main_ui = preload("res://scenes/main_ui.tscn")
var battle_map = preload("res://scenes/battle_map.tscn")
var battle_handler = preload("res://scenes/battle_handler.tscn")
var path_handler = preload("res://scenes/path_menu.tscn")
var after_battle_handler = preload("res://scenes/after_battle_menu.tscn")
var main_menu = preload("res://scenes/run_start_menu.tscn")
var event_menu = preload("res://scenes/event_menu.tscn")
var chest_menu = preload("res://scenes/chest_menu.tscn")
var village_menu = preload("res://scenes/village_menu.tscn")
var end_screen = preload("res://scenes/end_screen.tscn")

var map_position = Vector2(850, 372)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _load_end(successful : bool):
	call_deferred("_load_end_deferred", successful)

func _load_end_deferred(successful : bool):
	var root_node = get_tree().root
	
	var end = end_screen.instantiate() as Control

	_clear_root()
	
	root_node.add_child(end)
	get_tree().set_current_scene(end)
	end._setup(successful)

func _load_village(village_data : VillageEncounter):
	call_deferred("_load_village_deferred", village_data)

func _load_village_deferred(village_data : VillageEncounter):
	var root_node = get_tree().root
	
	var village = village_menu.instantiate() as Control

	_clear_root()
	
	root_node.add_child(village)
	get_tree().set_current_scene(village)
	village._setup(village_data)

func _load_chest(chest_data : ChestEncounter):
	call_deferred("_load_chest_deferred", chest_data)

func _load_chest_deferred(chest_data : ChestEncounter):
	var root_node = get_tree().root
	
	var chest = chest_menu.instantiate() as Control

	_clear_root()
	
	var new_relic = RunHandler._get_random_relic()
	
	root_node.add_child(chest)
	get_tree().set_current_scene(chest)
	chest._setup(new_relic)

func _load_event(event_data : EventEncounter):
	call_deferred("_load_event_deferred", event_data)

func _load_event_deferred(event_data : EventEncounter):
	var root_node = get_tree().root
	
	var event = event_menu.instantiate() as Control

	_clear_root()
	
	root_node.add_child(event)
	get_tree().set_current_scene(event)
	event._setup(event_data)

func _load_menu():
	call_deferred("_load_menu_deferred")

func _load_menu_deferred():
	var root_node = get_tree().root
	
	var menu = main_menu.instantiate() as Control

	_clear_root()
	
	root_node.add_child(menu)
	get_tree().set_current_scene(menu)

func _load_after_battle():
	call_deferred("_load_after_battle_deferred")

func _load_after_battle_deferred():
	var root_node = get_tree().root
	
	var post_battle = after_battle_handler.instantiate() as Control

	_clear_root()
	
	root_node.add_child(post_battle)
	get_tree().set_current_scene(post_battle)
	
	post_battle._setup()

func _load_run():
	call_deferred("_load_run_deferred")

func _load_run_deferred():
	var root_node = get_tree().root
	
	RunHandler._advance_encounters()
	
	var path = path_handler.instantiate() as Control
	var encounter_list = RunHandler._get_encounter_list()
	path._setup([encounter_list.pick_random(), encounter_list.pick_random(), encounter_list.pick_random()])
	
	_clear_root()

	root_node.add_child(path)
	get_tree().set_current_scene(path)

func _load_battle(fight : Encounter):
	call_deferred("_load_battle_deferred", fight)

func _load_battle_deferred(fight : Encounter):
	var root_node = get_tree().root
	
	var ui = main_ui.instantiate() as Control
	var map = battle_map.instantiate() as Node2D
	var handler = battle_handler.instantiate() as Node
	
	_clear_root()
	
	root_node.add_child(ui)
	root_node.add_child(map)
	root_node.add_child(handler)
	get_tree().set_current_scene(map)
	
	map.position = map_position
	
	_setup_battle(fight)

func _setup_battle(fight : Encounter):
	var handler = get_node("../BattleHandler")
	handler._setup(fight)

func _clear_root():
	for node in get_tree().root.get_children():
		match node.name:
			"SceneHandler", "DataHandler", "RunHandler":
				pass
			_:
				get_tree().root.remove_child(node)
