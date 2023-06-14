extends Node

var martial_class_list = [] 
var mystic_class_list = []

# Called when the node enters the scene tree for the first time.
func _ready():
	var parser = XMLParser.new()
	parser.open("res://data/class_list.xml")
	while parser.read() != ERR_FILE_EOF:
		if parser.get_node_name() == "class":
			if parser.get_named_attribute_value_safe("name") == null:
				print("ERR>Invalid class name")
				continue
			var class_load = load("res://classes/" + parser.get_named_attribute_value_safe("name") + ".tres")
			if class_load == null:
				print("ERR>Class not found")
				continue
			match parser.get_named_attribute_value_safe("type"):
				"martial":
					martial_class_list.append(class_load)
				"mystic":
					mystic_class_list.append(class_load)
				_:
					print("ERR>Invalid class type")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _get_full_class_list(mode):
	var full_list = martial_class_list.duplicate()
	full_list.append_array(mystic_class_list.duplicate())
	return full_list
