extends "res://scripts/interactable/interactable_object.gd"

@onready var sprite_1 = $Sprite3D
@onready var sprite_2 = $Sprite3D2
@onready var collision_shape = $CollisionShape3D

func _ready():
	obj_name = "Trash"
	sprite_1.texture.region.position.x = (randi() % 4) * 64
	sprite_2.texture.region.position.x = (randi() % 4) * 64
	
	sprite_1.rotation.z = randf_range(0, TAU)
	sprite_2.rotation.z = randf_range(0, TAU)
	
	var extents = collision_shape.shape.size * 0.5
	sprite_2.global_position.x = collision_shape.global_position.x 
	sprite_2.global_position.x += randf_range(-extents.x, extents.x)
	sprite_2.global_position.z = collision_shape.global_position.z 
	sprite_2.global_position.z += randf_range(-extents.z, extents.z)

func interact(_player_scene):
	queue_free()
