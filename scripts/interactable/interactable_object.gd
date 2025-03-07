class_name Interactable
extends Area3D

var obj_name: String = "NONAME"

func interact(_player_scene):
	queue_free()

func _on_body_entered(body):
	if body is Player:
		body._interaction_entered(self)

func _on_body_exited(body):
	if body is Player:
		body._interaction_exited(self)
