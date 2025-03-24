extends Area3D
class_name Equipable

signal equipped

@export var resource: Item:
	set(value):
		resource = value
		var sprite = get_node_or_null("Sprite3D")
		if sprite: sprite.texture = value.texture
	
var obj_name: String:
	get(): return resource.obj_name

func interact(player_scene):
	player_scene.equip(resource)
	equipped.emit()
	queue_free()

func _on_body_entered(body):
	if body is Player:
		body._interaction_entered(self)

func _on_body_exited(body):
	if body is Player:
		body._interaction_exited(self)
