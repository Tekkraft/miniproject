extends Node

enum TurnCondition {NONE, ON_TURN_START, ON_TURN_END}
enum StatusCondition {NONE, ON_STATUS_INCREASED, ON_NEW_STATUS, ON_STATUS_UP, PRE_STATUS_UP}
enum CombatCondition {NONE, ON_ATTACKED, ON_ATTACKING, ON_DAMAGE_EFFECT, ON_TAKE_DAMAGE_EFFECT}
enum CardCondition {NONE, ON_CARD_DRAW, ON_CARD_PLAYED, ON_CARD_DISCARD, ON_CARD_EXHAUST}
enum EncounterCondition {NONE, ON_ENTER_COMBAT, ON_EXIT_COMBAT, ON_ENTER_VILLAGE, ON_EXIT_VILLAGE}
enum ActivationClass {TURN_CONDITION, STATUS_CONDITON, COMBAT_CONDITON, CARD_CONDITION, ENCOUNTER_CONDITION}

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
