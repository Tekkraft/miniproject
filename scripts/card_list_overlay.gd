extends Control

var display_cards = []
var card = preload("res://scenes/card.tscn")

var card_size = Vector2(128, 192)
var card_scale = 1.5

var cards_per_row = 1
var spacing = 16
var padding = 16

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _setup():
	var box = get_node("ScrollContainer/SizeBox") as Control
	var width = box.custom_minimum_size.x
	var card_width = card_size.x * card_scale
	var true_width = width - padding * 2
	cards_per_row = int(int(true_width) / int(card_width + spacing))
	var differential = int(true_width) % int(card_width + spacing)
	spacing += float(differential) / float(cards_per_row)

func _add_card(card_data):
	var new_card = card.instantiate()
	get_node("ScrollContainer/SizeBox").add_child(new_card)
	new_card._setup(card_data)
	var row_index = display_cards.size() % cards_per_row
	var level_index = floori(display_cards.size() / cards_per_row)
	new_card.position.x = (row_index * card_size.x * card_scale) + (row_index * spacing) + padding + (card_size.x * card_scale / 2)
	new_card.position.y = (level_index * card_size.y * card_scale) + (level_index * spacing) + padding + (card_size.y * card_scale / 2)
	display_cards.append(new_card)
	#(new_card as Node2D).z_index = 4
	
	var box = get_node("ScrollContainer/SizeBox") as Control
	var height = box.custom_minimum_size.y
	if height < (level_index * card_size.y * card_scale) + (level_index * spacing) + padding + (card_size.y * card_scale / 2):
		box.custom_minimum_size.y = ((level_index + 1) * card_size.y * card_scale) + (level_index * spacing) + (padding * 2)
	
	return new_card

func _remove_overlay():
	get_parent().remove_child(self)
	self.queue_free()


func _on_close_button_pressed():
	_remove_overlay()
