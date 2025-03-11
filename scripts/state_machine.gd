extends Node

var current_state: GameManager.CharStates = GameManager.CharStates.IDLE
var chase_target = null

@onready var parent = get_parent()  # Assumes it's on the character
@onready var navigation_agent: NavigationAgent3D = $"../NavigationAgent3D"

func _process(_delta):
	if chase_target != null and current_state == GameManager.CharStates.MOVING:
		if navigation_agent.target_position != chase_target.global_position:
			navigation_agent.set_target_position(chase_target.global_position)

func change_state(new_state: GameManager.CharStates):
	if current_state == new_state:return
	if current_state == GameManager.CharStates.MOVING: chase_target = null
	current_state = new_state

func move_to(target: Vector3):
	if current_state == GameManager.CharStates.DEAD: return
	if current_state == GameManager.CharStates.BUSY: return
	change_state(GameManager.CharStates.MOVING)
	navigation_agent.set_target_position(target)
	
func chase(target):
	chase_target = target
	move_to(target.global_position)
