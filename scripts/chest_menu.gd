extends Control

var relic_object = preload("res://scenes/relic.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _setup(relic):
	if relic == null:
		return
	
	var new_relic = relic_object.instantiate()
	new_relic._setup(relic, 0)
	get_node("RelicArea").add_child(new_relic)

func _exit_menu():
	SceneHandler._load_run()
