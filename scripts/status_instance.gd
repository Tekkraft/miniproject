extends Node2D

var status_data : Status
var status_counter : int

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
		self.get_parent().remove_child(self)
		self.queue_free()
