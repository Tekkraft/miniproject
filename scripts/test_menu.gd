extends Control

@export var fights : Array[Encounter]

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_fight_button_pressed(fight_id):
	SceneHandler._load_battle(fights[fight_id])
