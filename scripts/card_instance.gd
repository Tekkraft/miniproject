extends Node2D

var target_line = preload("res://scenes/targeting_line.tscn")

var start_position : Vector2
var hovered : bool
var active : bool
var card_data : Card

signal card_activated(source)
signal card_released(source)

# Called when the node enters the scene tree for the first time.
func _ready():
	start_position = position
	active = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _setup(card_data : Card):
	self.card_data = card_data
	get_node("CardTitle").text = card_data.card_name 
	get_node("CardDescription").text = card_data.card_description 
	get_node("CardArt").texture = card_data.card_sprite

func _input(event):
	if event is InputEventMouseButton:
		if event.is_action_pressed("action_select") && hovered:
			var new_line = target_line.instantiate()
			add_child(new_line)
			new_line._setup(global_position)
			active = true
			emit_signal("card_activated", self)
		elif event.is_action_released("action_select") && active:
			emit_signal("card_released", self)
			_reset_card()

func _on_card_area_mouse_entered():
	hovered = true
	start_position = position

func _on_card_area_mouse_exited():
	hovered = false

func _reset_card():
	hovered = false
	active = false
	position = start_position
	var remove = get_node_or_null("TargetingLine")
	if remove != null:
		remove_child(remove)
		remove.queue_free()
