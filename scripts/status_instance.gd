extends Node2D

var status_data : Status
var status_counter : int

var hover_resource = preload("res://scenes/tooltip_hover.tscn")

var activated = false

var queued_increment = 0
var queued_decrement = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _setup(status_data : Status, status_counter : int):
	self.status_data = status_data
	self.status_counter = status_counter
	get_node("StatusIcon").texture = status_data.status_icon
	get_node("StatusCounter").text = str(status_counter)

func _increment_counter(value : int):
	status_counter += value
	get_node("StatusCounter").text = str(status_counter)

func _decrement_counter(value : int):
	status_counter -= value
	get_node("StatusCounter").text = str(status_counter)
	if status_counter <= 0:
		var parent = self.get_parent()
		parent.remove_child(self)
		parent.get_parent()._realign_statuses()
		self.queue_free()

func _queue_decrement_counter(value : int):
	queued_decrement += value

func _queue_increment_counter(value : int):
	queued_increment += value

func _trigger_queue():
	_increment_counter(queued_increment)
	queued_increment = 0
	_decrement_counter(queued_decrement)
	queued_decrement = 0

func _on_status_hover_mouse_entered():
	var tooltip = hover_resource.instantiate() as Node2D
	tooltip.get_node("TooltipTitle").text = status_data.status_name
	tooltip.get_node("TooltipDescription").text = status_data.status_description
	get_node("Hover").add_child(tooltip)
	tooltip.position += Vector2(128,64) * 1.1

func _on_status_hover_mouse_exited():
	for node in get_node("Hover").get_children():
		get_node("Hover").remove_child(node)
		node.queue_free()
