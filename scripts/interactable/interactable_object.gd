class_name Interactable
extends Area3D

signal interacted

@export var obj_name: String = "NONAME"
@export var texture: Texture2D:
	set(value):
		var sprite = get_node_or_null("Sprite3D")
		if sprite: sprite.texture = value

func interact(_player_scene):
	interacted.emit(self)

func _on_body_entered(body):
	if body is Player:
		body._interaction_entered(self)

func _on_body_exited(body):
	if body is Player:
		body._interaction_exited(self)
