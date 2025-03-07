class_name DelayedInteractable
extends Interactable

var is_interacting = false

func interact(_player_scene):
	is_interacting = true

func complete_interaction():
	is_interacting = false
	queue_free()
	
func _input(event):
	if is_interacting and event.is_action_released("Interact"):
		is_interacting = false
