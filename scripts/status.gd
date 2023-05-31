extends Resource

class_name Status

enum StatusType {BUFF, DEBUFF, SPECIAL}

@export var status_name : String
@export var status_icon : Texture2D
@export var status_class : StatusType
