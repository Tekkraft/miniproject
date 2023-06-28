extends Control

var card_picker_overlay = preload("res://scenes/card_picker_overlay.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _setup():
	var card_picker = card_picker_overlay.instantiate()
	card_picker._setup()
	card_picker.connect("overlay_closed", _close_to_run)
	get_node("/root/").add_child(card_picker)

func _close_to_run():
	SceneHandler._load_run()
