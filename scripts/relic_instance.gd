extends Node2D

var relic_data : Relic
var relic_counter : int

var hover_resource = preload("res://scenes/tooltip_hover.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _setup(relic_data : Relic, relic_counter : int):
	self.relic_data = relic_data
	self.relic_counter = relic_counter
	get_node("StatusIcon").texture = relic_data.status_icon
	get_node("StatusCounter").text = str(relic_counter)

func _increment_counter(value : int):
	relic_counter += value
	get_node("StatusCounter").text = str(relic_counter)

func _decrement_counter(value : int):
	relic_counter -= value
	get_node("StatusCounter").text = str(relic_counter)
	if relic_counter <= 0:
		var parent = self.get_parent()
		parent.remove_child(self)
		parent.get_parent()._realign_statuses()
		self.queue_free()

func _on_relic_hover_mouse_entered():
	var tooltip = hover_resource.instantiate() as Node2D
	tooltip.get_node("TooltipTitle").text = relic_data.status_name
	tooltip.get_node("TooltipDescription").text = relic_data.status_description
	get_node("Hover").add_child(tooltip)
	tooltip.position += Vector2(128,64) * 1.1

func _on_relic_hover_mouse_exited():
	for node in get_node("Hover").get_children():
		get_node("Hover").remove_child(node)
		node.queue_free()
