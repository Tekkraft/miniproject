extends Node2D

var start_position

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var line = get_node("MainLine")
	line.clear_points()
	line.add_point(Vector2.ZERO)
	line.add_point(get_viewport().get_mouse_position() - start_position)

func _setup(start_position : Vector2):
	scale = Vector2(1/get_parent().scale.x, 1/get_parent().scale.y)
	self.start_position = start_position
