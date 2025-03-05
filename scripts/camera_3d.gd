extends Camera3D

@export var target: Node3D  # Assign Player in the editor
var is_following: bool = true

func _process(delta):
	if GameManager.game_state == GameManager.GameStates.ADVENTURE and target:
		var follow_speed = 5.0
		global_position = global_position.lerp(target.global_position + Vector3(0, 1.5, 2), follow_speed * delta)
