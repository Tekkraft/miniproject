extends Node2D

var active_tile

# Called when the node enters the scene tree for the first time.
func _ready():
	active_tile = null

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _get_active_tile():
	return active_tile

func _on_tile_area_mouse_entered(tile_coord : Vector2i):
	active_tile = tile_coord

func _on_tile_area_mouse_exited(tile_coord : Vector2i):
	if active_tile != null:
		if active_tile == tile_coord:
			active_tile = null
