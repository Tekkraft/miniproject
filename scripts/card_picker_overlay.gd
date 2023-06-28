extends Control

var card_offerings = []
var card = preload("res://scenes/card.tscn")
var card_list_overlay = preload("res://scenes/card_list_overlay.tscn")

signal overlay_closed

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _setup():
	var possible_cards = []
	possible_cards.append_array(RunHandler.martial_class.class_pool_cards)
	possible_cards.append_array(RunHandler.mystic_class.class_pool_cards)
	for i in 3:
		if possible_cards.size() <= 0:
			break
		var selected_card = possible_cards.pick_random()
		possible_cards.remove_at(possible_cards.find(selected_card))
		card_offerings.append(selected_card)
	
	for i in card_offerings.size():
		var new_card = card.instantiate()
		new_card.name = "Card_" + str(i)
		new_card._setup(card_offerings[i])
		get_node("CardSelectPanel/CardDock" + str(i)).add_child(new_card)

func _setup_custom(possible_cards : Array):
	for i in 3:
		if possible_cards.size() <= 0:
			break
		var selected_card = possible_cards.pick_random()
		possible_cards.remove_at(possible_cards.find(selected_card))
		card_offerings.append(selected_card)
	
	for i in card_offerings.size():
		var new_card = card.instantiate()
		new_card.name = "Card_" + str(i)
		new_card._setup(card_offerings[i])
		get_node("CardSelectPanel/CardDock" + str(i)).add_child(new_card)

func _on_select_card(index):
	if card_offerings.size() <= index:
		_on_close_overlay()
	else:
		RunHandler.current_deck.append(card_offerings[index])
		_on_close_overlay()

func _on_close_overlay():
	emit_signal("overlay_closed")
	get_parent().remove_child(self)
	self.queue_free()

func _on_view_deck_button_pressed():
	var list = card_list_overlay.instantiate()
	list._setup()
	for card_data in RunHandler.current_deck:
		list._add_card(card_data)
	get_node("/root/").add_child(list)
