extends Camera3D

@export var target: Node3D  # Assign Player in the editor
var is_following: bool = true

var max_bounds: Vector2 = Vector2.ZERO
var min_bounds: Vector2 = Vector2.ZERO

func bound_camera(max_b: Vector2, min_b: Vector2):
	max_bounds = max_b
	min_bounds = min_b
	
func _process(delta):
	if GameManager.game_state == GameManager.GameStates.ADVENTURE and target:
		var follow_speed = 5.0
		global_position = global_position.lerp(target.global_position + Vector3(0, 1.5, 2), follow_speed * delta)
	if max_bounds and min_bounds:
		global_position.x = clamp(global_position.x, min_bounds.x, max_bounds.x)
		global_position.z = clamp(global_position.z, min_bounds.y, max_bounds.y)
		
