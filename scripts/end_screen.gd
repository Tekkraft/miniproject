extends Control

var card_list_overlay = preload("res://scenes/card_list_overlay.tscn")

var relic = preload("res://scenes/relic.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _setup(successful):
	if successful:
		get_node("TitlePanel/EndingTitle").text = "Victorious!"
	else:
		get_node("TitlePanel/EndingTitle").text = "Vanquished..."
	
	for relic_instance in RunHandler.current_relics:
		var new_relic = relic.instantiate() as Node2D
		new_relic.name = "Relic_" + str(get_node("RelicArea").get_child_count())
		new_relic._setup(relic_instance, 0)
		get_node("RelicArea").add_child(new_relic)
		new_relic.add_to_group("RelicInstance")
		new_relic.position.x = (get_node("RelicArea").get_child_count() - 1) * ((64 + 24) * new_relic.scale.x + 16)


func _on_deck_button_pressed():
	var list = card_list_overlay.instantiate()
	list._setup()
	for card_data in RunHandler.current_deck:
		list._add_card(card_data)
	get_node("/root/").add_child(list)

func _on_menu_button_pressed():
	SceneHandler._load_menu()
